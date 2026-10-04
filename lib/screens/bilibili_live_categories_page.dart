                                                 
  
                                                   
                                                        
                                               
                                                
                                        
                                                                   
import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_live_room_page.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/src/content_reveal_gate.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/back_top_fab.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/lazy_cover_image.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/navi_spring_physics.dart';
import 'package:naviflash/widgets/underline_tab_row.dart';
import 'package:naviflash/widgets/video_card.dart';
import 'package:naviflash/widgets/page_loading.dart';

                                    
const double _kTopBarHeight = 56.0;

                                       
const double _kTabBarHeight = 48.0;

class BilibiliLiveCategoriesPage extends StatefulWidget {
                          
  final int initialParentId;

  const BilibiliLiveCategoriesPage({super.key, this.initialParentId = 0});

  @override
  State<BilibiliLiveCategoriesPage> createState() =>
      _BilibiliLiveCategoriesPageState();
}

class _BilibiliLiveCategoriesPageState
    extends State<BilibiliLiveCategoriesPage>
    with SingleTickerProviderStateMixin {
  static const double kCollapseThreshold = 120.0;

  List<LiveAreaGroup> _groups = [];
  String? _error;
  bool _loading = true;

                                               
                                   
                                   
  TabController? _tabController;

                               
  int get _selectedIndex => _tabController?.index ?? 0;

  bool _topCollapsed = false;

                                      
                               
  ContentRevealGate? _revealGate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _tabController = null;
    _revealGate?.dispose();
    _revealGate = null;
    super.dispose();
  }

                                 
                             
  void _armRevealGate() {
    _revealGate?.dispose();
    _revealGate = ContentRevealGate(
                                         
      onUnlock: () {
        if (mounted) setState(() {});
      },
    )..arm(context);
  }

                                    
  bool get _isContentGated => _revealGate?.isGated ?? false;

  double get _effectiveTopBarHeight =>
      _topCollapsed ? _kTabBarHeight : _kTopBarHeight + _kTabBarHeight;

  void _onScrollNotification(ScrollNotification n) {
    if (n is! ScrollUpdateNotification) return;
    final delta = n.scrollDelta ?? 0;
    var collapsed = _topCollapsed;
    if (delta > 0 && n.metrics.extentBefore > kCollapseThreshold) {
      collapsed = true;
    } else if (delta < 0 || n.metrics.extentBefore < 1) {
      collapsed = false;
    }
    if (collapsed != _topCollapsed) {
      setState(() => _topCollapsed = collapsed);
    }
  }

                                    
  void _selectGroup(int index) {
    final ctrl = _tabController;
    if (ctrl == null ||
        index == ctrl.index ||
        index < 0 ||
        index >= _groups.length) {
      return;
    }
    ctrl.animateTo(index);
  }

                                                     
  void _onTabChanged() {
    final ctrl = _tabController;
    if (ctrl == null || !mounted) return;
    setState(() {
      if (!ctrl.indexIsChanging) _topCollapsed = false;
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
                                      
    _armRevealGate();
    final result = await BilibiliLiveService.fetchAreaList();
    if (!mounted) return;
    switch (result) {
      case LiveOk<LiveAreaGroup>(:final items):
                                          
                           
        items.sort((a, b) => a.id.compareTo(b.id));
        if (items.isEmpty) {
                                                         
          _tabController?.dispose();
          _tabController = null;
          setState(() {
            _groups = items;
            _loading = false;
          });
          return;
        }
        var initialIndex = 0;
        if (widget.initialParentId > 0) {
          final i = items.indexWhere((g) => g.id == widget.initialParentId);
          if (i >= 0) initialIndex = i;
        }
                                             
                                 
        _tabController?.dispose();
        _tabController = TabController(
          length: items.length,
          initialIndex: initialIndex.clamp(0, items.length - 1),
          vsync: this,
        )..addListener(_onTabChanged);
        setState(() {
          _groups = items;
          _loading = false;
        });
      case LiveError<LiveAreaGroup>(:final detail):
        setState(() {
          _loading = false;
          _error = detail;
        });
    }
  }

                               
                                      
                                
  Future<void> _refresh() async {
    if (_groups.isEmpty) return;
    final prevId =
        _groups[_selectedIndex.clamp(0, _groups.length - 1)].id;
    final result = await BilibiliLiveService.fetchAreaList();
    if (!mounted) return;
    switch (result) {
      case LiveOk<LiveAreaGroup>(:final items):
        items.sort((a, b) => a.id.compareTo(b.id));
        if (_sameAreas(_groups, items)) return;
        final newIndex = items.indexWhere((g) => g.id == prevId);
        if (items.length == _groups.length && _tabController != null) {
          setState(() => _groups = items);
                                          
          if (newIndex >= 0 && newIndex != _tabController!.index) {
            _tabController!.index = newIndex;
          }
        } else {
          _tabController?.dispose();
          _tabController = TabController(
            length: items.length,
            initialIndex: (newIndex >= 0 ? newIndex : 0).clamp(
              0,
              items.length - 1,
            ),
            vsync: this,
          )..addListener(_onTabChanged);
          setState(() => _groups = items);
        }
      case LiveError<LiveAreaGroup>():
        break;
    }
  }

                                        
  bool _sameAreas(List<LiveAreaGroup> a, List<LiveAreaGroup> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].name != b[i].name) return false;
      final ac = a[i].children;
      final bc = b[i].children;
      if (ac.length != bc.length) return false;
      for (var j = 0; j < ac.length; j++) {
        if (ac[j].id != bc[j].id ||
            ac[j].name != bc[j].name ||
            ac[j].pic != bc[j].pic) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final body = (_loading || _isContentGated)
        ? Column(
            children: [
              SizedBox(height: _effectiveTopBarHeight),
              const Expanded(
                child: Center(child: LoadingIndicatorM3E()),
              ),
            ],
          )
        : _error != null
        ? Column(
            children: [
              SizedBox(height: _effectiveTopBarHeight),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                          onPressed: _load, child: const Text('重试')),
                    ],
                  ),
                ),
              ),
            ],
          )
        : _tabController == null
        ? Column(
                                                      
            children: [
              SizedBox(height: _effectiveTopBarHeight),
              Expanded(
                child: Center(
                  child: Text(
                    '暂无分区',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          )
        : AppRefreshIndicator(
            onRefresh: _refresh,
            color: cs.primary,
            edgeOffset: 0,
                                       
                                              
            displacement: _kTopBarHeight + _kTabBarHeight + 10,
            child: naviTabBarView(
                                                 
                                   
            controller: _tabController!,
            children: [
              for (var i = 0; i < _groups.length; i++)
                NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    _onScrollNotification(n);
                    return false;
                  },
                                                       
                                                        
                  child: CustomScrollView(
                    physics: const AppRefreshScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          height: _effectiveTopBarHeight,
                        ),
                      ),
                      ..._areaSlivers(cs, i),
                    ],
                  ),
                  ),
              ],
            ),
          );

                                  
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: Stack(
        children: [
                                             
          PageBackground(
            baseColor: cs.surfaceContainer,
            contentStyle: true,
          ),
          SafeArea(
            child: Stack(
              children: [
            Positioned.fill(
              child: body,
            ),
            Align(
              alignment: Alignment.topCenter,
              child: _buildTopBar(cs),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

                                               
  List<Widget> _areaSlivers(ColorScheme cs, int groupIndex) {
    final group = _groups[groupIndex];
    if (group.children.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              '该分区下暂时没有子分类',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 96,
            mainAxisSpacing: 18,
            crossAxisSpacing: 8,
            mainAxisExtent: 78,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => _AreaIconItem(
              area: group.children[i],
              parentName: group.name,
            ),
            childCount: group.children.length,
          ),
        ),
      ),
    ];
  }

                                            
  Widget _buildTopBar(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return FrostedPanel(
      opacity: 0.75,
      blurSigma: 12,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _topCollapsed ? 0.0 : 1.0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return ClipRect(
                  child: Align(
                    heightFactor: value,
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                );
              },
              child: SizedBox(
                height: _kTopBarHeight,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    MorphIconButton(
                      icon: Icons.arrow_back,
                      tooltip: l10n.homeBack,
                      onTap: () => Navigator.of(context).pop(),
                      frosted: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '直播分类',
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
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: _kTabBarHeight,
              child: ScrollableTabRow(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: [
                  for (var i = 0; i < _groups.length; i++)
                    _buildGroupTab(_groups[i], i, cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

                                                 
  Widget _buildGroupTab(LiveAreaGroup group, int index, ColorScheme cs) {
    final selected = index == _selectedIndex;
    return InkWell(
      onTap: () => _selectGroup(index),
      customBorder: const StadiumBorder(),
      splashColor: cs.primary.withValues(alpha: 0.12),
      highlightColor: cs.primary.withValues(alpha: 0.08),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Text(
              group.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: 3,
            width: selected ? 24 : 0,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

                                           
                           
                                           

class _AreaIconItem extends StatelessWidget {
  final LiveAreaItem area;
  final String parentName;

  const _AreaIconItem({required this.area, required this.parentName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;

    final icon = area.isAll || area.pic.isEmpty
        ? Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.apps,
              size: 22,
              color: cs.primary,
            ),
          )
        : ClipOval(
            child: Image(
              image: CachedImageProvider(area.pic, headers: headers),
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 46,
                height: 46,
                color: cs.primaryContainer.withValues(alpha: 0.45),
                child: Icon(Icons.apps, size: 22, color: cs.primary),
              ),
            ),
          );

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BilibiliLiveCategoryRoomsPage(
            parentAreaId: area.parentId > 0 ? area.parentId : area.id,
            areaId: area.id,
            parentName: parentName,
            areaName: area.name,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 5),
          Text(
            area.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

                                           
                                               
                                 
                                           

                                        
enum _CategorySort { recommend, online, liveTime }

class BilibiliLiveCategoryRoomsPage extends StatefulWidget {
  final int parentAreaId;
  final int areaId;
  final String parentName;
  final String areaName;

  const BilibiliLiveCategoryRoomsPage({
    super.key,
    required this.parentAreaId,
    required this.areaId,
    required this.parentName,
    required this.areaName,
  });

  @override
  State<BilibiliLiveCategoryRoomsPage> createState() =>
      _BilibiliLiveCategoryRoomsPageState();
}

class _BilibiliLiveCategoryRoomsPageState
    extends State<BilibiliLiveCategoryRoomsPage> {
  static const double kVideoCardTargetWidth = 200.0;
  static const int kVideoCardMinColumns = 2;
  static const int kVideoCardMaxColumns = 8;
  static const String kGridPrefsKey = 'bili_live_category_grid';
  static const double kCollapseThreshold = 120.0;

  static const List<(_CategorySort, String, String)> _sorts = [
    (_CategorySort.recommend, '推荐', BilibiliLiveService.sortDefault),
    (_CategorySort.online, '人气', BilibiliLiveService.sortOnline),
    (_CategorySort.liveTime, '最新开播', BilibiliLiveService.sortLiveTime),
  ];

  _CategorySort _sort = _CategorySort.recommend;

  List<LiveRoomItem> _items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

                                   
  bool _gridMode = true;

  bool _topCollapsed = false;

                                       
                                             
  final _fabVisibility = BackTopFabVisibility();

  late final ScrollController _scroll = ScrollController();

                                      
                               
  ContentRevealGate? _revealGate;

  String get _title => widget.areaId == 0 || widget.areaName == '全部'
      ? widget.parentName
      : widget.areaName;

  String get _sortValue => _sorts
      .firstWhere((s) => s.$1 == _sort, orElse: () => _sorts.first)
      .$3;

  double get _effectiveTopBarHeight =>
      _topCollapsed ? _kTabBarHeight : _kTopBarHeight + _kTabBarHeight;

                                    
  bool get _isContentGated => _revealGate?.isGated ?? false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScrollPosition);
    _loadGridMode();
    _load(forceRefresh: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _revealGate?.dispose();
    _revealGate = null;
    super.dispose();
  }

  Future<void> _loadGridMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(kGridPrefsKey);
    if (saved != null && mounted) {
      setState(() => _gridMode = saved);
    }
  }

                   
  void _scrollToTop() {
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

                                 
                             
  void _armRevealGate() {
    _revealGate?.dispose();
    _revealGate = ContentRevealGate(
                                         
      onUnlock: () {
        if (mounted) setState(() {});
      },
    )..arm(context);
  }

  void _onScrollPosition() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) _loadMore();
  }

  void _onScrollNotification(ScrollNotification n) {
    if (n is! ScrollUpdateNotification) return;
    final delta = n.scrollDelta ?? 0;
    var collapsed = _topCollapsed;
    if (delta > 0 && n.metrics.extentBefore > kCollapseThreshold) {
      collapsed = true;
    } else if (delta < 0 || n.metrics.extentBefore < 1) {
      collapsed = false;
    }
    final labelChanged = _fabVisibility.update(delta);
    if ((collapsed != _topCollapsed || labelChanged) && mounted) {
      setState(() => _topCollapsed = collapsed);
    }
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!forceRefresh && (_loading || _loadingMore)) return;
    if (!mounted) return;
    if (forceRefresh) {
                                          
                                          
                                                   
      final showFullscreen = _items.isEmpty;
      if (showFullscreen) _armRevealGate();
      setState(() {
        _loading = showFullscreen;
        _loadingMore = false;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    final targetPage = forceRefresh ? 1 : _page + 1;
    final result = await BilibiliLiveService.fetchAreaRooms(
      parentAreaId: widget.parentAreaId,
      areaId: widget.areaId,
      sortType: _sortValue,
      page: targetPage,
    );
    if (!mounted) return;
    switch (result) {
      case LiveOk<LiveRoomItem>(:final items, :final hasMore):
                                     
        final seen = <int>{
          if (!forceRefresh) for (final it in _items) it.roomId,
        };
        final fresh = items.where((it) => seen.add(it.roomId)).toList();
        setState(() {
          if (forceRefresh) {
            _items = fresh;
            _page = 1;
          } else {
            _items = [..._items, ...fresh];
            _page = targetPage;
          }
          _hasMore = hasMore;
          _loading = false;
          _loadingMore = false;
          _error = null;
        });
      case LiveError<LiveRoomItem>(:final detail):
        setState(() {
          _loading = false;
          _loadingMore = false;
                                   
          if (forceRefresh || _items.isEmpty) _error = detail;
          if (!forceRefresh) _hasMore = false;
        });
    }
  }

  void _loadMore() {
    if (_loading || _loadingMore || !_hasMore || _error != null) return;
    _load();
  }

  void _selectSort(_CategorySort sort) {
    if (sort == _sort) return;
    setState(() {
      _sort = sort;
      _topCollapsed = false;
      _hasMore = true;
    });
    _load(forceRefresh: true);
  }

  void _openRoom(LiveRoomItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BilibiliLiveRoomPage(
          roomId: item.roomId,
          title: item.title,
          uname: item.uname,
          face: item.face,
          cover: item.cover,
        ),
      ),
    );
  }

                           
  void _openInBrowser(LiveRoomItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrowserPage(
          initialUrl: item.url,
          title: item.title.isEmpty ? '直播间' : item.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scaffold = Scaffold(
      backgroundColor: cs.surfaceContainer,
                                        
                                          
      floatingActionButton: _error != null && _items.isEmpty
          ? LoadRetryPill(onRetry: () => _load(forceRefresh: true))
          : BackTopFab(
              extended: _fabVisibility.extended,
              onTap: _scrollToTop,
            ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildBody(cs),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: _buildTopBar(cs),
            ),
          ],
        ),
      ),
    );
    return IosBackdropScale(child: scaffold);
  }

                                                
  Widget _buildTopBar(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return FrostedPanel(
      opacity: 0.75,
      blurSigma: 12,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _topCollapsed ? 0.0 : 1.0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return ClipRect(
                  child: Align(
                    heightFactor: value,
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                );
              },
              child: SizedBox(
                height: _kTopBarHeight,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    MorphIconButton(
                      icon: Icons.arrow_back,
                      tooltip: l10n.homeBack,
                      onTap: () => Navigator.of(context).pop(),
                      frosted: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _title,
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
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
                                             
            UnderlineTabRow(
              labels: [for (final s in _sorts) s.$2],
              selectedIndex: _sorts.indexWhere((s) => s.$1 == _sort),
              onSelected: (i) => _selectSort(_sorts[i].$1),
              height: _kTabBarHeight,
            ),
          ],
        ),
      ),
    );
  }

                                               


  Widget _buildBody(ColorScheme cs) {
                                      
                                             
                                     
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _items.isEmpty,
    ) ||
        _isContentGated) {
      return Column(
        children: [
          SizedBox(height: _effectiveTopBarHeight),
          const Expanded(child: PageLoadingIndicator()),
        ],
      );
    }
    if (_error != null && _items.isEmpty) {
      return Column(
        children: [
          SizedBox(height: _effectiveTopBarHeight),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
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
          SizedBox(height: _effectiveTopBarHeight),
          Expanded(
            child: Center(
              child: Text(
                '这个分类现在没人开播',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ],
      );
    }
                                                   
                                    
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        _onScrollNotification(n);
        return false;
      },
      child: AppRefreshIndicator(
        onRefresh: () {
          if (_topCollapsed) setState(() => _topCollapsed = false);
          return _load(forceRefresh: true);
        },
        color: cs.primary,
        edgeOffset: 0,
                                   
                                          
        displacement: _kTopBarHeight + _kTabBarHeight + 10,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AppRefreshScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
                                         
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                height: _effectiveTopBarHeight,
              ),
            ),
            if (!_gridMode)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Column(
                    children: [
                      for (final item in _items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _LiveListCard(
                            item: item,
                            onTap: () => _openRoom(item),
                            onLongPress: () => _openInBrowser(item),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _items[index];
                          return _LiveGridCard(
                            item: item,
                            onTap: () => _openRoom(item),
                            onLongPress: () => _openInBrowser(item),
                          );
                        },
                        childCount: _items.length,
                      ),
                    );
                  },
                ),
              ),
            if (_loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 72,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

                                           
                                                            
                                           

                                   
                                  
class _LiveGridCard extends StatelessWidget {
  final LiveRoomItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _LiveGridCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return VideoCardV(
      data: _liveCardData(item),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

                                               
                     
class _LiveListCard extends StatelessWidget {
  final LiveRoomItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _LiveListCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return VideoCardH(
      data: _liveCardData(item, withAreaBadge: false),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

                          
                            
                            
                                  
VideoCardData _liveCardData(LiveRoomItem item, {bool withAreaBadge = true}) {
  final areaText =
      item.areaName.isNotEmpty ? item.areaName : item.parentAreaName;
  return VideoCardData(
    cover: item.cover,
    title: item.title.isEmpty ? '未命名直播间' : item.title,
    coverWidget: _liveCover(item.cover),
    viewText: _liveOnlineText(item),
    durationText: withAreaBadge ? areaText : null,
    ownerName: item.uname.isEmpty ? '未知主播' : item.uname,
    subtitleTrailing: const _LiveNowBadge(),
  );
}

                                 
class _LiveNowBadge extends StatelessWidget {
  const _LiveNowBadge();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
          ),
          child: SizedBox(width: 6, height: 6),
        ),
        SizedBox(width: 4),
        Text(
          '直播中',
          style: TextStyle(fontSize: 11, color: Colors.redAccent),
        ),
      ],
    );
  }
}

                     

                                        
Widget _liveCover(String url) {
  final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
      ? null
      : NetworkSettingsService.instance.apiHeaders;
  return LazyCoverImage(
    url,
    headers: headers,
    fit: BoxFit.cover,
    maxDimension: 480,
  );
}

String _liveOnlineText(LiveRoomItem item) {
  if (item.onlineText.isNotEmpty) return item.onlineText;
  return _fmtLiveCount(item.online);
}

String _fmtLiveCount(int n) {
  if (n >= 100000000) return '${(n / 100000000).toStringAsFixed(1)} 亿';
  if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)} 万';
  return '$n';
}
