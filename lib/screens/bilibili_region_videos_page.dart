// lib/screens/bilibili_region_videos_page.dart
//
// 分区视频列表页：
//   - 顶部标题 + 排序切换（最新 / 排行榜）
//   - 最新：x/web-interface/newlist 分页 + 触底加载
//   - 排行：x/web-interface/ranking/v2（单页，分区过滤）
//   - 网格卡片与热门列表页同款（封面 Hero + 标题 + 播放数）
import 'package:flutter/material.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bilibili_recommend_service.dart';
import 'package:naviflash/services/bilibili_region_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';

/// 排序方式。
enum _RegionSort { latest, rank }

class BilibiliRegionVideosPage extends StatefulWidget {
  final BiliRegion region;

  const BilibiliRegionVideosPage({super.key, required this.region});

  @override
  State<BilibiliRegionVideosPage> createState() =>
      _BilibiliRegionVideosPageState();
}

class _BilibiliRegionVideosPageState extends State<BilibiliRegionVideosPage> {
  final ScrollController _scroll = ScrollController();
  _RegionSort _sort = _RegionSort.latest;

  List<BiliRecommendItem> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(forceRefresh: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!forceRefresh && (_loading || _loadingMore)) return;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
    });
    final rid = widget.region.tid;
    final BiliRecommendResult<BiliRecommendItem> result;
    if (_sort == _RegionSort.latest) {
      result = await BilibiliRegionService.fetchRegionLatest(
        rid: rid,
        pn: forceRefresh ? 1 : _page + 1,
      );
    } else {
      result = await BilibiliRegionService.fetchRegionRank(rid: rid);
    }
    if (!mounted) return;
    switch (result) {
      case BiliRecommendOk(:final items):
        setState(() {
          if (forceRefresh || _sort == _RegionSort.rank) {
            _items = items;
            _page = 1;
          } else {
            _items = [..._items, ...items];
            _page += 1;
          }
          _hasMore =
              _sort == _RegionSort.latest && items.isNotEmpty;
          _loading = false;
          _loadingMore = false;
          _error = null;
        });
      case BiliRecommendError(:final detail):
        setState(() {
          _loading = false;
          _loadingMore = false;
          if (forceRefresh || _items.isEmpty) {
            _error = detail;
          }
        });
    }
  }

  void _loadMore() {
    if (_sort != _RegionSort.latest) return;
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    _load();
  }

  void _switchSort(_RegionSort sort) {
    if (_sort == sort) return;
    setState(() {
      _sort = sort;
      _items = [];
      _hasMore = true;
    });
    _load(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        title: Text(widget.region.name),
        backgroundColor: cs.surfaceContainer,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 排序切换
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: Row(
                children: [
                  _sortChip(cs, _RegionSort.latest, '最新'),
                  const SizedBox(width: 8),
                  _sortChip(cs, _RegionSort.rank, '排行榜'),
                ],
              ),
            ),
            Expanded(child: _buildBody(cs)),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(ColorScheme cs, _RegionSort sort, String label) {
    final selected = _sort == sort;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _switchSort(sort),
      showCheckmark: false,
      selectedColor: cs.primaryContainer.withValues(alpha: 0.5),
      backgroundColor: cs.surfaceBright,
      side: BorderSide.none,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        color: selected ? cs.primary : cs.onSurfaceVariant,
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          // 加载失败重试：右下角 Extended FAB（重新加载）
          PositionedRetryFab(onRetry: () => _load(forceRefresh: true)),
        ],
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          '暂无内容',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      color: cs.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = (width / 200).floor().clamp(2, 4);
          final cardW = (width - (columns - 1) * 12 - 32) / columns;
          return GridView.builder(
            controller: _scroll,
            physics: _loading
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: cardW / (cardW / 0.625 + 52),
            ),
            itemCount: _items.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= _items.length) {
                return _buildFooter(cs);
              }
              return _VideoCard(item: _items[i]);
            },
          );
        },
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    if (_loadingMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// 视频卡片：封面（Hero 只包封面背景图）+ 标题 + 播放数。
class _VideoCard extends StatelessWidget {
  final BiliRecommendItem item;

  const _VideoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    final cover = item.cover.isEmpty
        ? Container(
            color: Colors.grey.shade800,
            child: const Center(
              child: Icon(Icons.movie_outlined, color: Colors.white24),
            ),
          )
        : Image(
            image: CachedImageProvider(item.cover, headers: headers),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade800,
              child: const Center(
                child: Icon(Icons.movie_outlined, color: Colors.white24),
              ),
            ),
          );
    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openBilibiliVideo(
          context,
          bvid: item.bvid,
          initialTitle: item.title,
          initialCover: item.cover,
          heroTag: 'bili_video_${item.bvid}',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 整页 Hero（iOS 整卡放大）模式：封面不单独包 Hero（整卡 Hero
            // 在卡片最外层）；经典模式保持封面 Hero（只包封面图）。
            SettingsService.heroTransitionBlurEnabled
                ? AspectRatio(aspectRatio: 16 / 10, child: cover)
                : Hero(
                    tag: 'bili_video_${item.bvid}',
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                    child: AspectRatio(aspectRatio: 16 / 10, child: cover),
                  ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmtCount(item.view),
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
          ],
        ),
      ),
    );
    // 整页 Hero（iOS 整卡放大）模式：Hero 包整个卡片；经典模式封面
    // Hero 已由封面区提供。
    if (SettingsService.heroTransitionBlurEnabled) {
      return Hero(
        tag: 'bili_video_${item.bvid}',
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: card,
      );
    }
    return card;
  }

  String _fmtCount(int n) {
    if (n >= 100000000) {
      return '${(n / 100000000).toStringAsFixed(1)} 亿';
    }
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)} 万';
    return '$n';
  }
}