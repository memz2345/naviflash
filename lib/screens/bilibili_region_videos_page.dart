                                               
  
           
                            
                                           
                                             
                                        
                                                             
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/back_top_fab.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bilibili_recommend_service.dart';
import 'package:naviflash/services/bilibili_region_service.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/ugc_selection_area.dart';
import 'package:naviflash/widgets/video_card.dart';
import 'package:naviflash/widgets/page_loading.dart';

         
enum _RegionSort { latest, rank }

class BilibiliRegionVideosPage extends StatefulWidget {
  final BiliRegion region;

  const BilibiliRegionVideosPage({super.key, required this.region});

  @override
  State<BilibiliRegionVideosPage> createState() =>
      _BilibiliRegionVideosPageState();
}

class _BilibiliRegionVideosPageState extends State<BilibiliRegionVideosPage> {
  static const double kTopBarHeight = 56.0;
  static const double kSortBarHeight = 44.0;
  static const double kVideoCardTargetWidth = 200.0;
  static const int kVideoCardMinColumns = 2;
  static const int kVideoCardMaxColumns = 8;

                                       
  static const String _gridPrefsKey = 'bili_region_grid_mode';

  final ScrollController _scroll = ScrollController();
  _RegionSort _sort = _RegionSort.latest;

  List<BiliRecommendItem> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;

                                         
                                                
  int _mainPn = 1;
  String? _error;

                          
  bool _gridMode = true;

                                       
  final _fabVisibility = BackTopFabVisibility();

                                    
  final GlobalKey<BackTopFabState> _fabKey = GlobalKey();

                                     
                                     
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();

                              
  bool _atTop = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadGridMode();
    _load(forceRefresh: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadGridMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_gridPrefsKey);
    if (saved != null && mounted) {
      setState(() => _gridMode = saved);
    }
  }

  Future<void> _toggleGridMode() async {
    setState(() => _gridMode = !_gridMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gridPrefsKey, _gridMode);
  }

  void _scrollToTop() {
    if (!_scroll.hasClients || _scroll.offset <= 0) return;
                                           
    final ms = (300 + _scroll.offset / 20).clamp(300.0, 1200.0).round();
    final duration = Duration(milliseconds: ms);
                        
    _fabKey.currentState?.startFlight(duration);
    _scroll.animateTo(0, duration: duration, curve: Curves.easeOut);
  }

                                     
                               
  void _userReload() {
    final state = _refreshKey.currentState;
    if (state == null) {
      _load(forceRefresh: true);
      return;
    }
    state.show();
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
      if (forceRefresh) {
                              
        _loading = _items.isEmpty;
        _loadingMore = false;
      } else {
                                            
        _loadingMore = true;
      }
      _error = null;
    });
    final rid = widget.region.tid;
    final isSubRegion = BilibiliRegionService.parentOf(rid) != null;

                                              
                                                     
    if (isSubRegion && _sort == _RegionSort.latest) {
      final page = await BilibiliRegionService.fetchSubRegionLatest(
        rid: rid,
        mainPn: forceRefresh ? 1 : _mainPn,
      );
      if (!mounted) return;
      setState(() {
        if (page.isError) {
          _loading = false;
          _loadingMore = false;
          if (forceRefresh || _items.isEmpty) {
            _error = page.error;
          }
          return;
        }
        final fresh = forceRefresh
            ? page.items
            : page.items
                  .where((v) => _items.every((e) => e.bvid != v.bvid))
                  .toList();
        _items = forceRefresh ? fresh : [..._items, ...fresh];
        _mainPn = page.nextMainPn;
        _hasMore = !page.exhausted;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
      return;
    }

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
          _hasMore = _sort == _RegionSort.latest && items.isNotEmpty;
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
                                                          
                                            
                      
    _load();
  }

  void _switchSort(_RegionSort sort) {
    if (_sort == sort) return;
    setState(() {
      _sort = sort;
      _items = [];
      _hasMore = true;
      _mainPn = 1;
    });
    _load(forceRefresh: true);
  }

  void _open(BiliRecommendItem item) {
    FocusManager.instance.primaryFocus?.unfocus();
    openBilibiliVideo(
      context,
      bvid: item.bvid,
      initialTitle: item.title,
      initialCover: item.cover,
      heroTag: 'bili_video_${item.bvid}',
    );
  }

  void _showLongPressMenu(BiliRecommendItem item) {
    showVideoBottomSheet(
      context,
      bvid: item.bvid,
      title: item.title,
      cover: item.cover,
      author: item.ownerName,
    );
  }

  void _showContextMenu(BiliRecommendItem item, Offset globalPosition) {
    showVideoContextMenu(
      context,
      bvid: item.bvid,
      title: item.title,
      cover: item.cover,
      author: item.ownerName,
      globalPosition: globalPosition,
    );
  }

  VideoCardData _videoCardData(BiliRecommendItem item) => VideoCardData(
    cover: item.cover,
    title: item.title,
    heroTag: 'bili_video_${item.bvid}',
    view: item.view,
    danmaku: item.danmaku,
    duration: item.duration,
    reason: item.rcmdReason,
    ownerName: item.ownerName,
    pubdate: item.pubdate,
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scaffold = Scaffold(
      backgroundColor: cs.surfaceContainer,
                                         
                          
      floatingActionButton: (_error != null && _items.isEmpty)
          ? LoadRetryPill(onRetry: () => _load(forceRefresh: true))
          : BackTopFab(
              key: _fabKey,
              extended: _fabVisibility.extended,
              atTop: _atTop,
              onTap: _scrollToTop,
              onRefresh: _userReload,
            ),
      body: Stack(
        children: [
                                             
          PageBackground(baseColor: cs.surfaceContainer, contentStyle: true),
          SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: _buildBody(cs)),
                Align(alignment: Alignment.topCenter, child: _buildTopBar(cs)),
              ],
            ),
          ),
        ],
      ),
    );
    return IosBackdropScale(child: scaffold);
  }

                                         
                                    
  Widget _buildTopBar(ColorScheme cs) {
    return FrostedPanel(
      opacity: 0.75,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: kTopBarHeight,
            child: Row(
              children: [
                const SizedBox(width: 8),
                MorphIconButton(
                  icon: Icons.arrow_back,
                  tooltip: L10n.current.commonBackTooltip,
                  onTap: () => Navigator.of(context).pop(),
                  frosted: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.region.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                MorphIconButton(
                  icon: _gridMode
                      ? Icons.grid_view_rounded
                      : Icons.view_agenda_rounded,
                  tooltip: _gridMode ? '切换单列' : '切换网格',
                  onTap: _toggleGridMode,
                  frosted: true,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          SizedBox(
            height: kSortBarHeight,
            child: Row(
              children: [
                const SizedBox(width: 16),
                _sortChip(cs, _RegionSort.latest, '最新'),
                const SizedBox(width: 8),
                _sortChip(cs, _RegionSort.rank, '排行榜'),
              ],
            ),
          ),
        ],
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
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  double get _topBarHeight => kTopBarHeight + kSortBarHeight;

  Widget _buildBody(ColorScheme cs) {
                                    
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _items.isEmpty,
    )) {
      return Column(
        children: [
          SizedBox(height: _topBarHeight),
          const Expanded(child: PageLoadingIndicator()),
        ],
      );
    }
    if (_error != null && _items.isEmpty) {
      return Column(
        children: [
          SizedBox(height: _topBarHeight),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return Column(
        children: [
          SizedBox(height: _topBarHeight),
          Expanded(
            child: Center(
              child: Text(
                '暂无内容',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ],
      );
    }
                                                   
                                 
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollUpdateNotification) {
          if (_fabVisibility.update(n.scrollDelta ?? 0) && mounted) {
            setState(() {});
          }
                                         
          final atTop = n.metrics.pixels <= 0.5;
          if (atTop != _atTop && mounted) {
            setState(() => _atTop = atTop);
          }
        }
        return false;
      },
      child: UgcSelectionArea(
        child: AppRefreshIndicator(
          refreshIndicatorKey: _refreshKey,
          onRefresh: () => _load(forceRefresh: true),
          color: cs.primary,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AppRefreshScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
                     
              SliverToBoxAdapter(child: SizedBox(height: _topBarHeight)),
              if (!_gridMode)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Column(
                      children: [
                        for (final item in _items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: VideoCardH(
                              data: _videoCardData(item),
                              onTap: () => _open(item),
                              onLongPress: () => _showLongPressMenu(item),
                              onSecondaryTap: (pos) =>
                                  _showContextMenu(item, pos),
                            ),
                          ),
                        _buildFooter(cs),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      final columns = (width / kVideoCardTargetWidth)
                          .floor()
                          .clamp(kVideoCardMinColumns, kVideoCardMaxColumns);
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = _items[index];
                          return VideoCardV(
                            data: _videoCardData(item),
                            onTap: () => _open(item),
                            onLongPress: () => _showLongPressMenu(item),
                            onSecondaryTap: (pos) =>
                                _showContextMenu(item, pos),
                          );
                        }, childCount: _items.length),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(child: _buildFooter(cs)),
              ],
                               
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 72,
                ),
              ),
            ],
          ),
        ),
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
