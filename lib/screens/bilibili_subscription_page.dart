                                              
  
                                        
                                          
                                              
                                          
                                                        
                         
                                            
                                           
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/screens/bilibili_favorites_page.dart';
import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/screens/bilibili_subscription_detail_page.dart';
import 'package:naviflash/services/bilibili_favorite_service.dart';
import 'package:naviflash/services/bilibili_subscription_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/app_drawer.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/frosted_page_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/page_loading.dart';
import 'package:naviflash/widgets/side_bar_menu_button.dart';

                             
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

                                    
String _fmtUpdatedAt(int ts) {
  if (ts <= 0) return '';
  final t = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  final now = DateTime.now();
  if (t.year == now.year) return '${t.month}/${t.day} 更新';
  return '${t.year}/${t.month}/${t.day} 更新';
}

class BilibiliSubscriptionPage extends StatefulWidget {
                                         
  final bool drawerMode;

  const BilibiliSubscriptionPage({super.key, this.drawerMode = false});

  @override
  State<BilibiliSubscriptionPage> createState() =>
      _BilibiliSubscriptionPageState();
}

class _BilibiliSubscriptionPageState extends State<BilibiliSubscriptionPage> {
  static const int _pageSize = 20;

  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  final List<BiliSubItem> _items = [];
  int _page = 1;
  bool _hasMore = true;

                                   
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

                         
  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    final (:items, hasMore: more, :err) = await BilibiliSubscriptionService
        .fetchList(pn: 1, ps: _pageSize);
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(items);
      _page = 1;
      _hasMore = more;
      _loading = false;
      _error = err;
    });
  }

                                           
                                        
  Future<void> _refresh() async {
    final (:items, hasMore: more, :err) = await BilibiliSubscriptionService
        .fetchList(pn: 1, ps: _pageSize);
    if (!mounted) return;
    if (err != null && _items.isNotEmpty) {
      showAppToast(context, '刷新失败：$err', error: true);
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(items);
      _page = 1;
      _hasMore = more;
      _loading = false;
      _error = err;
    });
  }

                                    
  void _showRefreshIndicator() {
    _refreshKey.currentState?.show();
  }

              
  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || _error != null) return;
    setState(() => _loadingMore = true);
    final (:items, hasMore: more, :err) = await BilibiliSubscriptionService
        .fetchList(pn: _page + 1, ps: _pageSize);
    if (!mounted) return;
    setState(() {
      if (err == null) {
        final known = _items.map((e) => e.id).toSet();
        _items.addAll(items.where((e) => !known.contains(e.id)));
        _page += 1;
        _hasMore = more;
      }
      _loadingMore = false;
    });
  }

  void _openItem(BuildContext ctx, BiliSubItem item) {
    HapticFeedback.lightImpact();
    if (item.isInvalid) {
                                    
      showAppToast(ctx, '该${item.typeLabel}已失效，无法查看', error: true);
      return;
    }
    if (item.isFavFolder) {
                                                  
      Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (_) => BilibiliFavFolderPage(
            folder: BiliFavFolder(
              id: item.id,
              title: item.title,
              cover: item.cover,
              mediaCount: item.mediaCount,
              attr: 0,
              isPublic: true,
              favState: 0,
            ),
          ),
        ),
      );
      return;
    }
                                  
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) =>
            BilibiliSubscriptionDetailPage(seasonId: item.id, info: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
                                           
    final scaffold = Scaffold(
      backgroundColor: cs.surfaceContainer,
                                    
      drawer: widget.drawerMode
          ? const AppDrawer(currentPage: 'subscribe')
          : null,
                                    
      onDrawerChanged: SideBarDrawerState.setOpen,
                                      
      floatingActionButton: _error != null && _items.isEmpty && !_loading
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 8,
              ),
              child: LoadRetryPill(onRetry: _showRefreshIndicator),
            )
          : null,
      body: Stack(
        children: [
                                    
          PageBackground(baseColor: cs.surfaceContainer, contentStyle: true),
          SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AppRefreshIndicator(
                    refreshIndicatorKey: _refreshKey,
                    color: cs.primary,
                    displacement: kFrostedPageBarHeight + 10,
                    onRefresh: _refresh,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >=
                            n.metrics.maxScrollExtent - 300) {
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
                                             
                          const SliverToBoxAdapter(
                            child: SizedBox(height: kFrostedPageBarHeight),
                          ),
                          ..._buildContentSlivers(cs),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: FrostedPageBar(
                    title: '我的订阅',
                    drawerMode: widget.drawerMode,
                    actions: [
                      if (_items.isNotEmpty)
                        MorphIconButton(
                          icon: Icons.refresh_rounded,
                          tooltip: '刷新',
                          onTap: _showRefreshIndicator,
                          transparent: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
                                          
    return IosBackdropScale(child: scaffold);
  }

  List<Widget> _buildContentSlivers(ColorScheme cs) {
                              
    if (!BilibiliSubscriptionService.isLoggedIn) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _LoginGate(),
        ),
      ];
    }
                 
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _items.isEmpty,
    )) {
      return const [PageLoadingSliver()];
    }
                
    if (_error != null && _items.isEmpty) {
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
               
    if (_items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.subscriptions_outlined,
                  size: 56,
                  color: cs.onSurface.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 12),
                const Text('还没有订阅的合集'),
                const SizedBox(height: 4),
                Text(
                  '在合集 / 收藏夹页可以订阅，订阅后在这里查看更新',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }
                             
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SubCard(
                item: _items[index],
                onTap: () => _openItem(context, _items[index]),
              ),
            ),
            childCount: _items.length,
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
      const _BottomSpacer(),
    ];
  }
}

                                 
class _LoginGate extends StatelessWidget {
  const _LoginGate();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 64,
            color: cs.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 14),
          const Text('需要登录 B 站账号'),
          const SizedBox(height: 4),
          Text(
            '登录后可以查看订阅的合集与收藏夹',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BilibiliLoginScreen()),
              );
            },
            icon: const Icon(Icons.login, size: 18),
            label: const Text('去登录'),
          ),
        ],
      ),
    );
  }
}

                           
class _BottomSpacer extends StatelessWidget {
  const _BottomSpacer();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: MediaQuery.of(context).padding.bottom + 88,
      ),
    );
  }
}

                                   
                                            
class _SubCard extends StatelessWidget {
  final BiliSubItem item;
  final VoidCallback onTap;

  const _SubCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final meta = <String>[
      '${item.mediaCount} 个内容',
      if (item.viewCount > 0) '${_fmtCount(item.viewCount)} 播放',
      if (item.mtime > 0) _fmtUpdatedAt(item.mtime),
    ].join(' · ');

    return Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item.cover.isNotEmpty)
                        Image(
                          image: CachedImageProvider(
                            item.cover,
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
                      else
                        Container(
                          color: cs.surfaceContainerHighest,
                          child: Icon(
                            Icons.video_library_outlined,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      Positioned(
                        left: 6,
                        top: 6,
                        child: _badge(
                          item.typeLabel,
                          color: cs.tertiaryContainer,
                          textColor: cs.onTertiaryContainer,
                        ),
                      ),
                      if (item.isInvalid)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black38,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.link_off_rounded,
                                  size: 22,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '已失效',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.white.withValues(alpha: 0.95),
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
              const SizedBox(width: 12),
                   
              Expanded(
                child: SizedBox(
                  height: 93,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.isEmpty ? '（无标题）' : item.title,
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
                      if (item.upName.isNotEmpty)
                        Text(
                          item.upName,
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
              SizedBox(
                width: 24,
                height: 93,
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, {Color? color, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9.5, color: textColor ?? Colors.white),
      ),
    );
  }
}
