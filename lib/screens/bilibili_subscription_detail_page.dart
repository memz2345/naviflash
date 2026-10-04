                                                     
  
                                               
                                           
                                        
                                                    
                                                             
                                                 
                                                      
                                                
import 'package:flutter/material.dart';
import 'package:naviflash/widgets/standard_list_page.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bilibili_subscription_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/video_card.dart';
import 'package:naviflash/widgets/page_loading.dart';

                              
String _fmtCount(int n) {
  if (n >= 100000000) {
    return '${(n / 100000000).toStringAsFixed(1)}亿';
  }
  if (n >= 10000) {
    final v = (n / 10000).toStringAsFixed(1);
    return '${v.endsWith('.0') ? v.substring(0, v.length - 2) : v}万';
  }
  return '$n';
}

                                    
String _fmtPubtime(int ts) {
  if (ts <= 0) return '';
  final t = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  return '${t.year}/${t.month}/${t.day}';
}

                                     
String _fmtDuration(int sec) {
  if (sec <= 0) return '';
  final h = sec ~/ 3600;
  final m = (sec % 3600) ~/ 60;
  final s = sec % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  if (h > 0) return '$h:${two(m)}:${two(s)}';
  return '$m:${two(s)}';
}

class BilibiliSubscriptionDetailPage extends StatefulWidget {
  final int seasonId;

                                     
                             
  final BiliSubItem? info;

  const BilibiliSubscriptionDetailPage({
    super.key,
    required this.seasonId,
    this.info,
  });

  @override
  State<BilibiliSubscriptionDetailPage> createState() =>
      _BilibiliSubscriptionDetailPageState();
}

class _BilibiliSubscriptionDetailPageState
    extends State<BilibiliSubscriptionDetailPage> {
  static const int _pageSize = 20;

  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  BiliSubItem? _info;
  final List<BiliSubVideo> _videos = [];
  int _page = 1;
  bool _hasMore = true;

                                   
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _info = widget.info;
    _load();
  }

                         
  Future<void> _load() async {
    setState(() {
      _loading = _videos.isEmpty;
      _error = null;
    });
    final result = await BilibiliSubscriptionService.fetchSeasonVideos(
      seasonId: widget.seasonId,
      pn: 1,
      ps: _pageSize,
    );
    if (!mounted) return;
    _applyPage(result, reset: true);
    setState(() => _loading = false);
  }

                                           
                      
  Future<void> _refresh() async {
    final result = await BilibiliSubscriptionService.fetchSeasonVideos(
      seasonId: widget.seasonId,
      pn: 1,
      ps: _pageSize,
    );
    if (!mounted) return;
    if (result.err != null && _videos.isNotEmpty) {
      showAppToast(context, '刷新失败：${result.err}', error: true);
      return;
    }
    _applyPage(result, reset: true);
    setState(() {});
  }

                                    
  void _showRefreshIndicator() {
    _refreshKey.currentState?.show();
  }

              
  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || _error != null) return;
    setState(() => _loadingMore = true);
    final result = await BilibiliSubscriptionService.fetchSeasonVideos(
      seasonId: widget.seasonId,
      pn: _page + 1,
      ps: _pageSize,
    );
    if (!mounted) return;
    if (result.err == null) {
      _applyPage(result, reset: false);
    }
    setState(() => _loadingMore = false);
  }

                                        
                             
  void _applyPage(
    ({BiliSubItem? info, List<BiliSubVideo> videos, String? err}) result, {
    required bool reset,
  }) {
    if (result.err != null) {
      setState(() {
        _error = result.err;
        if (reset) _hasMore = false;
      });
      return;
    }
    setState(() {
      _error = null;
      if (result.info != null) _info = result.info;
      if (reset) _videos.clear();
      final known = _videos.map((e) => e.id).toSet();
      _videos.addAll(result.videos.where((e) => !known.contains(e.id)));
      if (reset) {
        _page = 1;
      } else {
        _page += 1;
      }
                                                
                                   
      final total = _info?.mediaCount ?? 0;
      _hasMore = total > 0
          ? _videos.length < total
          : result.videos.isNotEmpty;
    });
  }

  void _openVideo(BiliSubVideo video) {
    if (video.bvid.isEmpty) return;
    openBilibiliVideo(
      context,
      bvid: video.bvid,
      initialTitle: video.title,
      initialCover: video.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return StandardListScaffold(
      topBar: StandardListTopBar(
        title: _info?.title.isNotEmpty == true ? _info!.title : '订阅合集',
        showBack: true,
        actions: [
          if (_videos.isNotEmpty)
            MorphIconButton(
              icon: Icons.refresh_rounded,
              tooltip: '刷新',
              onTap: _showRefreshIndicator,
              frosted: true,
            ),
        ],
      ),
                                      
      floatingActionButton: _error != null && _videos.isEmpty && !_loading
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 8,
              ),
              child: LoadRetryPill(onRetry: _showRefreshIndicator),
            )
          : null,
      body: AppRefreshIndicator(
        refreshIndicatorKey: _refreshKey,
        color: cs.primary,
        onRefresh: _refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
              _loadMore();
            }
            return false;
          },
          child: CustomScrollView(
            physics: _loading
                ? const NeverScrollableScrollPhysics()
                : const AppRefreshScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
            slivers: [
                            topBarSpaceSliver(kStdTopBarHeight),
                                                         
              if (_info != null)
                SliverToBoxAdapter(child: _buildHeader(cs, _info!)),
              ..._buildContentSlivers(cs),
            ],
          ),
        ),
      ),
    );
  }

                                                   
  Widget _buildHeader(ColorScheme cs, BiliSubItem info) {
    final meta = <String>[
      if (info.mediaCount > 0) '共 ${info.mediaCount} 条视频',
      if (info.viewCount > 0) '${_fmtCount(info.viewCount)} 次播放',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Material(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 148,
                  height: 93,
                  child: info.cover.isNotEmpty
                      ? Image(
                          image: CachedImageProvider(
                            info.cover,
                            headers:
                                NetworkSettingsService
                                        .instance.apiHeaders.isEmpty
                                ? null
                                : NetworkSettingsService.instance.apiHeaders,
                          ),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: cs.surfaceContainerHighest,
                          ),
                        )
                      : Container(
                          color: cs.surfaceContainerHighest,
                          child: Icon(
                            Icons.video_library_outlined,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 93,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title.isEmpty ? '（无标题）' : info.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (info.upName.isNotEmpty)
                        Text(
                          info.upName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 2),
                      if (meta.isNotEmpty)
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContentSlivers(ColorScheme cs) {
                 
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _videos.isEmpty,
    )) {
      return const [PageLoadingSliver()];
    }
                
    if (_error != null && _videos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 56,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ];
    }
               
    if (_videos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.movie_outlined,
                  size: 56,
                  color: cs.onSurface.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 12),
                const Text('合集里还没有视频'),
              ],
            ),
          ),
        ),
      ];
    }
                               
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SubVideoCard(
                video: _videos[index],
                onTap: () => _openVideo(_videos[index]),
              ),
            ),
            childCount: _videos.length,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: _loadingMore
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(
                    _hasMore ? '上滑加载更多' : '已全部加载',
                    style: TextStyle(fontSize: 12, color: cs.outline),
                  ),
          ),
        ),
      ),
      const _DetailBottomSpacer(),
    ];
  }
}

                           
class _DetailBottomSpacer extends StatelessWidget {
  const _DetailBottomSpacer();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: MediaQuery.of(context).padding.bottom + 88,
      ),
    );
  }
}

                            
                                      
                                  
class _SubVideoCard extends StatelessWidget {
  final BiliSubVideo video;
  final VoidCallback onTap;

  const _SubVideoCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return VideoCardH(
      data: VideoCardData(
        cover: video.cover,
        title: video.title.isEmpty ? '（无标题）' : video.title,
        view: video.play,
        subtitle: _metaOf(),
      ),
      onTap: onTap,
                                     
      statsTrailing: video.duration > 0
          ? Text(
              _fmtDuration(video.duration),
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            )
          : null,
    );
  }

                                   
  String _metaOf() {
    return <String>[
      if (video.play > 0) '${_fmtCount(video.play)} 播放',
      if (video.pubtime > 0) _fmtPubtime(video.pubtime),
    ].join(' · ');
  }
}
