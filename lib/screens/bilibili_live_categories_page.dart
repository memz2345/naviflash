// lib/screens/bilibili_live_categories_page.dart
//
// 直播分类页（参考 PiliPlus live_area / live_area_detail）：
//   - BilibiliLiveCategoriesPage：一级分区 TabBar + 二级分区图标宫格
//   - BilibiliLiveCategoryRoomsPage：某分类下的直播间列表
// UI 与每周必看（BilibiliPopularListPage）同款：毛玻璃悬浮顶栏 +
// 期数式 oval 排序 tab + 网格/单列切换 FAB + 同款卡片。
// 数据来源见 services/bilibili_live_service.dart（分区树 / second/getList）。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_live_room_page.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/src/content_reveal_gate.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/MetroTile.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/lazy_cover_image.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 毛玻璃顶栏高度（与每周必看 kTopBarHeight 一致）。
const double _kTopBarHeight = 56.0;

/// 排序 tab 栏高度（与每周必看 kTabBarHeight 一致）。
const double _kTabBarHeight = 48.0;

class BilibiliLiveCategoriesPage extends StatefulWidget {
  /// 进入时定位到的父分区（0 表示第一个）。
  final int initialParentId;

  const BilibiliLiveCategoriesPage({super.key, this.initialParentId = 0});

  @override
  State<BilibiliLiveCategoriesPage> createState() =>
      _BilibiliLiveCategoriesPageState();
}

class _BilibiliLiveCategoriesPageState
    extends State<BilibiliLiveCategoriesPage> {
  static const double kCollapseThreshold = 120.0;

  List<LiveAreaGroup> _groups = [];
  String? _error;
  bool _loading = true;

  /// 当前选中的一级分区下标（顶栏 oval tab 手动维护，与每周必看期数同款，
  /// 不再用 TabBar/TabBarView）。
  int _selectedIndex = 0;

  bool _topCollapsed = false;

  /// 内容延迟显示门控：分区宫格在转场动画途中一次上屏会把动画顶掉帧，
  /// 故动画未结束前即便数据已就绪也继续显示加载指示器。
  ContentRevealGate? _revealGate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _revealGate?.dispose();
    _revealGate = null;
    super.dispose();
  }

  /// 起一个内容显示门控：路由转场动画结束后才允许显示内容。
  /// 详见 [ContentRevealGate]。
  void _armRevealGate() {
    _revealGate?.dispose();
    _revealGate = ContentRevealGate(
      // 门控解锁后自身的 isGated 已翻转，这里只需触发一次重建。
      onUnlock: () {
        if (mounted) setState(() {});
      },
    )..arm(context);
  }

  /// 内容是否仍需显示加载指示器（= 动画未结束，先压着不上屏）。
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
    if (index == _selectedIndex || index < 0 || index >= _groups.length) {
      return;
    }
    setState(() {
      _selectedIndex = index;
      _topCollapsed = false;
    });
  }

  /// 每周必看同款：宫格上左右滑动切换一级分区。
  void _onHorizontalSwipe(DragEndDetails details) {
    if (_loading || _groups.isEmpty) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300) return;
    if (velocity < 0) {
      // 左滑 -> 下一个分区
      if (_selectedIndex + 1 < _groups.length) {
        HapticFeedback.lightImpact();
        _selectGroup(_selectedIndex + 1);
      }
    } else {
      // 右滑 -> 上一个分区
      if (_selectedIndex - 1 >= 0) {
        HapticFeedback.lightImpact();
        _selectGroup(_selectedIndex - 1);
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // 动画进行中先不上屏：加载完成后若动画未结束，仍显示加载指示器。
    _armRevealGate();
    final result = await BilibiliLiveService.fetchAreaList();
    if (!mounted) return;
    switch (result) {
      case LiveOk<LiveAreaGroup>(:final items):
        // 服务端返回顺序不固定，ID 升序后「一起看」等聚合分区排后面，
        // 常用的娱乐 / 手游等大分区靠前
        items.sort((a, b) => a.id.compareTo(b.id));
        var initialIndex = 0;
        if (widget.initialParentId > 0) {
          final i = items.indexWhere((g) => g.id == widget.initialParentId);
          if (i >= 0) initialIndex = i;
        }
        setState(() {
          _groups = items;
          _selectedIndex = initialIndex.clamp(0, items.length - 1);
          _loading = false;
        });
      case LiveError<LiveAreaGroup>(:final detail):
        setState(() {
          _loading = false;
          _error = detail;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final body = (_loading || _isContentGated)
        ? Column(
            children: [
              SizedBox(height: _effectiveTopBarHeight),
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
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
        : NotificationListener<ScrollNotification>(
            onNotification: (n) {
              _onScrollNotification(n);
              return false;
            },
            child: GestureDetector(
              onHorizontalDragEnd: _onHorizontalSwipe,
              behavior: HitTestBehavior.translucent,
              // 全屏滚动 + 内部 Sliver 占位：宫格内容从毛玻璃顶栏下透过，
              // 顶栏的 BackdropFilter 才有东西可模糊（每周必看同款）。
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(
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
                  ..._areaSlivers(cs),
                ],
              ),
            ),
          );

    // 每周必看同款：毛玻璃悬浮顶栏 + 内容从顶栏下方透出。
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: SafeArea(
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
    );
  }

  /// 当前选中一级分区的二级宫格 sliver（与每周必看一样全屏滚动）。
  List<Widget> _areaSlivers(ColorScheme cs) {
    if (_groups.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
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
      ];
    }
    final group = _groups[_selectedIndex.clamp(0, _groups.length - 1)];
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

  /// 每周必看同款双行顶栏：标题行（滚动折叠）+ 一级分区 oval tab 行。
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

  /// 一级分区 tab：每周必看期数 tab 同款（Stadium 水波 + 下划线指示）。
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

// ════════════════════════════════════════
//  二级分区图标入口（宫格单元，点击进分类房间页）
// ════════════════════════════════════════

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

// ════════════════════════════════════════
//  分类下的直播间列表（每周必看同款 UI：毛玻璃悬浮顶栏 + 排序 oval tab +
//  网格/单列切换 + 同款卡片 + 下拉刷新 + 触底翻页）
// ════════════════════════════════════════

/// 排序方式（对应 second/getList 的 sort_type）。
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

  /// 多列 / 单列（与每周必看同款 FAB 切换，落盘记忆）。
  bool _gridMode = true;

  bool _topCollapsed = false;

  late final ScrollController _scroll = ScrollController();

  /// 内容延迟显示门控：大量卡片在转场动画途中一次上屏会把动画顶掉帧，
  /// 故动画未结束前即便数据已就绪也继续显示加载指示器。
  ContentRevealGate? _revealGate;

  String get _title => widget.areaId == 0 || widget.areaName == '全部'
      ? widget.parentName
      : widget.areaName;

  String get _sortValue => _sorts
      .firstWhere((s) => s.$1 == _sort, orElse: () => _sorts.first)
      .$3;

  double get _effectiveTopBarHeight =>
      _topCollapsed ? _kTabBarHeight : _kTopBarHeight + _kTabBarHeight;

  /// 内容是否仍需显示加载指示器（= 动画未结束，先压着不上屏）。
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

  void _toggleGridMode() {
    setState(() => _gridMode = !_gridMode);
    SharedPreferences.getInstance()
        .then((p) => p.setBool(kGridPrefsKey, _gridMode));
  }

  /// 起一个内容显示门控：路由转场动画结束后才允许显示内容。
  /// 详见 [ContentRevealGate]。
  void _armRevealGate() {
    _revealGate?.dispose();
    _revealGate = ContentRevealGate(
      // 门控解锁后自身的 isGated 已翻转，这里只需触发一次重建。
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
    if (collapsed != _topCollapsed) {
      setState(() => _topCollapsed = collapsed);
    }
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!forceRefresh && (_loading || _loadingMore)) return;
    if (!mounted) return;
    if (forceRefresh) {
      // 动画进行中先不上屏：加载完成后若动画未结束，仍显示加载指示器。
      _armRevealGate();
      setState(() {
        _loading = true;
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
        // 后端偶发回传重复房间，按 roomId 去重后再追加
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
          // 加载更多失败只静默结束，避免整页被错误态替换
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

  /// 长按兜底：播放页不可用时仍可在浏览器观看。
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
    final l10n = AppLocalizations.of(context);
    final scaffold = Scaffold(
      backgroundColor: cs.surfaceContainer,
      floatingActionButton: FloatingActionButton(
        tooltip: _gridMode
            ? l10n.searchSwitchSingleCol
            : l10n.searchSwitchMulti,
        onPressed: _toggleGridMode,
        child: Icon(
          _gridMode ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
        ),
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

  /// 每周必看同款双行顶栏：标题行（滚动折叠）+ 排序 oval tab 行（始终保留）。
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
            SizedBox(
              height: _kTabBarHeight,
              child: ScrollableTabRow(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: [
                  for (final s in _sorts) _buildSortTab(s, cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 排序 tab：每周必看期数 tab 同款（Stadium 水波 + 下划线指示）。
  Widget _buildSortTab(
    (_CategorySort, String, String) s,
    ColorScheme cs,
  ) {
    final selected = _sort == s.$1;
    return InkWell(
      onTap: () => _selectSort(s.$1),
      customBorder: const StadiumBorder(),
      splashColor: cs.primary.withValues(alpha: 0.12),
      highlightColor: cs.primary.withValues(alpha: 0.08),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Text(
              s.$2,
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

  Widget _buildBody(ColorScheme cs) {
    // 加载 / 错误 / 空状态：同样留出顶栏高度，避免被毛玻璃遮挡
    // [_isContentGated]：数据已就绪但动画未结束，继续压着不上屏。
    if (_loading || _isContentGated) {
      return Column(
        children: [
          SizedBox(height: _effectiveTopBarHeight),
          const Expanded(child: Center(child: LoadingIndicatorM3E())),
        ],
      );
    }
    if (_error != null && _items.isEmpty) {
      return Column(
        children: [
          SizedBox(height: _effectiveTopBarHeight),
          Expanded(
            child: Stack(
              children: [
                Center(
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
                // 加载失败重试：右下角 Extended FAB（重新加载）
                PositionedRetryFab(
                  onRetry: () => _load(forceRefresh: true),
                  bottomOffset: MediaQuery.paddingOf(context).bottom + 16,
                ),
              ],
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
    // 正常列表：CustomScrollView 铺满，通过首个 Sliver 占位让内容初始
    // 位置位于毛玻璃下方，滚动时会从毛玻璃下透过（每周必看同款）
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        _onScrollNotification(n);
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () {
          if (_topCollapsed) setState(() => _topCollapsed = false);
          return _load(forceRefresh: true);
        },
        color: cs.primary,
        child: CustomScrollView(
          controller: _scroll,
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // 顶栏占位：高度与 FrostedPanel 折叠同步
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

// ════════════════════════════════════════
//  直播卡片（每周必看 _PopularGridCard / _PopularListCard 同款 chrome）
// ════════════════════════════════════════

/// 网格卡片：封面 Hero 位改为直播封面（16:10 + 渐变 + 左下人气 +
/// 右上分区）+ 双行标题 + 主播 + 直播中。
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
    final cs = Theme.of(context).colorScheme;
    final areaText =
        item.areaName.isNotEmpty ? item.areaName : item.parentAreaName;
    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _liveCover(item.cover),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 6,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        Text(
                          _liveOnlineText(item),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (areaText.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          areaText,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? '未命名直播间' : item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.uname.isEmpty ? '未知主播' : item.uname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '直播中',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
  }
}

/// 单列卡片：每周必看 _PopularListCard 同款（148x84 缩略图 +
/// 右侧标题/主播/人气行）。
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
    final cs = Theme.of(context).colorScheme;
    final areaText =
        item.areaName.isNotEmpty ? item.areaName : item.parentAreaName;
    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 148,
                  height: 84,
                  child: _liveCover(item.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title.isEmpty ? '未命名直播间' : item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.uname.isEmpty ? '未知主播' : item.uname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        Text(
                          _liveOnlineText(item),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (areaText.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Icon(
                            Icons.place_outlined,
                            size: 13,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              areaText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '直播中',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
  }
}

// ── 直播卡片 helpers ──

/// 直播封面（可视区门控 + ≤480 缩略图，避免滚动时全尺寸解码尖峰）。
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
