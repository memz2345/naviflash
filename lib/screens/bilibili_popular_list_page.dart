// lib/screens/bilibili_popular_list_page.dart
//
// 热门页顶部入口的通用视频列表页（排行榜 / 每周必看 / 入站必刷）：
//   - 排行榜：x/web-interface/ranking/v2（全站综合榜）
//   - 每周必看：x/web-interface/popular/series/list（期数）+
//     x/web-interface/popular/series/one（某期视频），顶部期数 chip 切换
//   - 入站必刷：x/web-interface/popular/precious
// 数据解析复用 BilibiliRecommendService（BiliRecommendItem）。
import 'package:flutter/material.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bilibili_recommend_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/MetroTile.dart';
import 'package:naviflash/widgets/search_video_menu.dart';

/// 列表类型。
enum BiliPopularListKind { ranking, weekly, precious }

class BilibiliPopularListPage extends StatefulWidget {
  final BiliPopularListKind kind;

  const BilibiliPopularListPage({super.key, required this.kind});

  @override
  State<BilibiliPopularListPage> createState() =>
      _BilibiliPopularListPageState();
}

class _BilibiliPopularListPageState extends State<BilibiliPopularListPage>
    with SingleTickerProviderStateMixin {
  static const double kTopBarHeight = 56.0;
  static const double kTabBarHeight = 48.0;
  static const double kVideoCardTargetWidth = 200.0;
  static const int kVideoCardMinColumns = 2;
  static const int kVideoCardMaxColumns = 8;

  List<BiliRecommendItem> _items = [];
  bool _loading = true;
  String? _error;

  /// 每周必看：期数列表 + 当前选中期。
  List<({int number, String title})> _weeklySeries = [];
  int _weeklyNumber = 0;
  bool _weeklyExpanded = false;
  final Map<int, GlobalKey> _weeklyTabKeys = {};

  /// 多列 / 单列
  bool _gridMode = true;
  late final AnimationController _gridRowAnimCtrl;
  int _prevCols = 0;
  int _prevCount = 0;
  String? _prevFirstBvid;
  final Map<int, Offset> _itemTranslations = {};

  bool get _hasWeeklyTabs =>
      widget.kind == BiliPopularListKind.weekly && _weeklySeries.isNotEmpty;

  bool _topCollapsed = false;
  static const double kCollapseThreshold = 120.0;

  double get _effectiveTopBarHeight => _hasWeeklyTabs
      ? (_topCollapsed ? kTabBarHeight : kTopBarHeight + kTabBarHeight)
      : kTopBarHeight;

  void _onScroll(ScrollNotification notification) {
    if (_weeklyExpanded) {
      if (notification is ScrollUpdateNotification) {
        setState(() => _weeklyExpanded = false);
      }
      return;
    }
    if (!_hasWeeklyTabs) return;
    if (notification is! ScrollUpdateNotification) return;
    final metrics = notification.metrics;
    final delta = notification.scrollDelta ?? 0;
    var collapsed = _topCollapsed;
    if (delta > 0 && metrics.extentBefore > kCollapseThreshold) {
      collapsed = true;
    } else if (delta < 0) {
      collapsed = false;
    } else if (metrics.extentBefore < 1) {
      collapsed = false;
    }
    if (collapsed != _topCollapsed) {
      setState(() => _topCollapsed = collapsed);
    }
  }

  @override
  void initState() {
    super.initState();
    _gridRowAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _loadGridMode();
    _load();
  }

  Future<void> _loadGridMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_gridPrefsKey);
    if (saved != null && mounted) {
      setState(() => _gridMode = saved);
    }
  }

  String get _gridPrefsKey => switch (widget.kind) {
        BiliPopularListKind.ranking => 'bili_popular_grid_ranking',
        BiliPopularListKind.weekly => 'bili_popular_grid_weekly',
        BiliPopularListKind.precious => 'bili_popular_grid_precious',
      };

  void _toggleGridMode() {
    setState(() => _gridMode = !_gridMode);
    SharedPreferences.getInstance()
        .then((p) => p.setBool(_gridPrefsKey, _gridMode));
    // 重置网格动画基线，避免跨模式位移错乱
    _prevCols = 0;
    _prevCount = 0;
    _prevFirstBvid = null;
    _itemTranslations.clear();
  }

  @override
  void dispose() {
    _gridRowAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    switch (widget.kind) {
      case BiliPopularListKind.ranking:
        final r = await BilibiliRecommendService.fetchRanking();
        _apply(r);
      case BiliPopularListKind.precious:
        final r = await BilibiliRecommendService.fetchPrecious();
        _apply(r);
      case BiliPopularListKind.weekly:
        final series = await BilibiliRecommendService.fetchWeeklySeries();
        if (!mounted) return;
        if (series.isEmpty) {
          setState(() {
            _loading = false;
            _error = '每周必看暂无数据';
          });
          return;
        }
        setState(() {
          _weeklySeries = series;
          // 列表第一项为最新一期
          _weeklyNumber = series.first.number;
        });
        final r = await BilibiliRecommendService.fetchWeeklyOne(
          _weeklyNumber,
        );
        _apply(r);
    }
  }

  void _apply(BiliRecommendResult<BiliRecommendItem> result) {
    if (!mounted) return;
    switch (result) {
      case BiliRecommendOk(:final items):
        setState(() {
          _items = items;
          _loading = false;
          _error = null;
        });
      case BiliRecommendError(:final detail):
        setState(() {
          _loading = false;
          _error = detail;
        });
    }
  }

  Future<void> _selectWeekly(int number) async {
    if (number == _weeklyNumber) return;
    setState(() {
      _weeklyNumber = number;
      _loading = true;
      _error = null;
      _items = [];
      _topCollapsed = false;
      _weeklyExpanded = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _weeklyTabKeys[number];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    });
    final r = await BilibiliRecommendService.fetchWeeklyOne(number);
    _apply(r);
  }

  void _onHorizontalSwipe(DragEndDetails details) {
    if (_loading || !_hasWeeklyTabs) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300) return;
    final currentIndex =
        _weeklySeries.indexWhere((s) => s.number == _weeklyNumber);
    if (currentIndex == -1) return;
    if (velocity < 0) {
      // 左滑 -> 下一期（更旧）
      if (currentIndex + 1 < _weeklySeries.length) {
        HapticFeedback.lightImpact();
        _selectWeekly(_weeklySeries[currentIndex + 1].number);
      }
    } else {
      // 右滑 -> 上一期（更新）
      if (currentIndex - 1 >= 0) {
        HapticFeedback.lightImpact();
        _selectWeekly(_weeklySeries[currentIndex - 1].number);
      }
    }
  }

  String get _title => switch (widget.kind) {
        BiliPopularListKind.ranking => '排行榜',
        BiliPopularListKind.weekly => '每周必看',
        BiliPopularListKind.precious => '入站必刷',
      };

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

  /// 检测网格布局变化并启动行平移动画（与推荐页/搜索页同款）。
  void _checkGridLayoutChange(int cols, int count, double cellW, double cellH) {
    if (count == 0) return;
    if (_prevCols == 0) {
      _prevCols = cols;
      _prevCount = count;
      _prevFirstBvid = _items.isNotEmpty ? _items[0].bvid : null;
      return;
    }
    if (_prevCols == cols && _prevCount == count) return;
    if (count == 0 || _prevCount == 0) {
      _prevCols = cols;
      _prevCount = count;
      _prevFirstBvid = _items.isNotEmpty ? _items[0].bvid : null;
      return;
    }
    final oldCols = _prevCols;
    final newCols = cols;
    final minCount = _prevCount < count ? _prevCount : count;
    final newFirst = _items.isNotEmpty ? _items[0].bvid : null;
    if (_prevFirstBvid != null && _prevFirstBvid != newFirst) {
      _itemTranslations.clear();
      _prevCols = cols;
      _prevCount = count;
      _prevFirstBvid = newFirst;
      return;
    }
    _itemTranslations.clear();
    bool anyMoved = false;
    for (int i = 0; i < minCount; i++) {
      final oldRow = i ~/ oldCols;
      final oldCol = i % oldCols;
      final newRow = i ~/ newCols;
      final newCol = i % newCols;
      if (oldRow != newRow || oldCol != newCol) {
        anyMoved = true;
        _itemTranslations[i] = Offset(
          (oldCol - newCol) * cellW,
          (oldRow - newRow) * cellH,
        );
      }
    }
    _prevCols = cols;
    _prevCount = count;
    _prevFirstBvid = newFirst;
    if (anyMoved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _gridRowAnimCtrl.reset();
        _gridRowAnimCtrl.forward();
      });
    }
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
              child: _buildBody(cs, l10n),
            ),
            if (_weeklyExpanded && _hasWeeklyTabs)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _weeklyExpanded = false),
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.topCenter,
              child: _buildTopBar(cs, l10n),
            ),
          ],
        ),
      ),
    );
    return IosBackdropScale(child: scaffold);
  }

  Widget _buildTopBar(ColorScheme cs, AppLocalizations l10n) {
    // 非每周必看：单行 56；每周必看：双行 56+48，与搜索页 kSearchTabBarHeight 一致
    // 标题左对齐（返回按钮右侧）
    if (!_hasWeeklyTabs) {
      return FrostedPanel(
        opacity: 0.75,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: kTopBarHeight,
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
      );
    }
    // 每周必看：扩大顶栏，期数 tab 与搜索页 oval tab 同款（Stadium ripple + 下划线指示）
    // 向下滚动时仅保留 tab，向上恢复 back；展开时与下拉网格一体无断层
    return FrostedPanel(
      opacity: 0.75,
      blurSigma: 12,
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(_weeklyExpanded ? 16 : 0),
      ),
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
                height: kTopBarHeight,
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
            // 期数横向 oval tab（搜索页同款，可横向滚动，始终保留）+ 右侧展开按钮
            ClipRect(
              child: SizedBox(
                height: kTabBarHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: ScrollableTabRow(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tabs: [
                          for (final s in _weeklySeries) _buildWeeklyTab(s, cs),
                        ],
                      ),
                    ),
                    _buildWeeklyExpandButton(cs),
                  ],
                ),
              ),
            ),
            // 展开的更多期数（一体式毛玻璃，无断层）
            ClipRect(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: _weeklyExpanded ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                builder: (context, value, child) => Align(
                  heightFactor: value,
                  alignment: Alignment.topCenter,
                  child: Opacity(opacity: value, child: child),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: cs.outlineVariant.withValues(alpha: 0.18),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                        child: Builder(
                          builder: (context) {
                            final filtered = _weeklySeries
                                .where((s) => s.number != _weeklyNumber)
                                .toList();
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.35,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) =>
                                  _buildWeeklyExpandedChip(filtered[i], cs),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTab(
    ({int number, String title}) s,
    ColorScheme cs,
  ) {
    final selected = s.number == _weeklyNumber;
    final label = s.title.isEmpty ? '第 ${s.number} 期' : s.title;
    final key = _weeklyTabKeys.putIfAbsent(s.number, () => GlobalKey());
    return InkWell(
      key: key,
      onTap: () => _selectWeekly(s.number),
      customBorder: const StadiumBorder(),
      splashColor: cs.primary.withValues(alpha: 0.12),
      highlightColor: cs.primary.withValues(alpha: 0.08),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Text(
              label,
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

  Widget _buildWeeklyExpandButton(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _weeklyExpanded = !_weeklyExpanded),
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: AnimatedRotation(
              turns: _weeklyExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyExpandedChip(
    ({int number, String title}) s,
    ColorScheme cs,
  ) {
    final selected = s.number == _weeklyNumber;
    final label = s.title.isEmpty ? '第 ${s.number} 期' : s.title;
    return Center(
      child: ChoiceChip(
        label: Text(label, textAlign: TextAlign.center),
        selected: selected,
        onSelected: (_) {
          setState(() => _weeklyExpanded = false);
          _selectWeekly(s.number);
        },
        showCheckmark: false,
        selectedColor: cs.primaryContainer,
        backgroundColor: cs.surfaceContainerHighest,
        side: BorderSide.none,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs, AppLocalizations l10n) {
    // 加载 / 错误 / 空状态：同样留出顶栏高度，避免被毛玻璃遮挡
    if (_loading) {
      return Column(
        children: [
          SizedBox(height: _effectiveTopBarHeight),
          const Expanded(child: Center(child: LoadingIndicatorM3E())),
        ],
      );
    }
    if (_error != null) {
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
                  onRetry: _load,
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
                '暂无内容',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ],
      );
    }
    // 正常列表：CustomScrollView 铺满 Positioned.fill，通过首个 Sliver 占位
    // 让内容初始位置位于毛玻璃下方，滚动时会从毛玻璃下透过
    // 每周必看时支持与搜索页同款的滚动折叠：向下滚仅保留 tab，向上恢复 back
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        _onScroll(n);
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () {
          if (_topCollapsed) setState(() => _topCollapsed = false);
          return _load();
        },
        color: cs.primary,
        child: GestureDetector(
          onHorizontalDragEnd: _hasWeeklyTabs ? _onHorizontalSwipe : null,
          behavior: HitTestBehavior.translucent,
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // 顶栏占位：动画高度与 FrostedPanel 折叠同步（搜索页同款 220ms）
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
                        child: _PopularListCard(
                          item: item,
                          onTap: () => _open(item),
                          onLongPress: () => _showLongPressMenu(item),
                          onSecondaryTap: (pos) =>
                              _showContextMenu(item, pos),
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
                  final cardW = (width - (columns - 1) * 12) / columns;
                  final cellW = cardW + 12;
                  final cellH = cardW / 0.78 + 12;
                  _checkGridLayoutChange(columns, _items.length, cellW, cellH);
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
                        return ListenableBuilder(
                          listenable: _gridRowAnimCtrl,
                          builder: (context, _) {
                            final t = Curves.easeInOut
                                .transform(_gridRowAnimCtrl.value);
                            final delta = _itemTranslations[index];
                            Widget card = _PopularGridCard(
                              item: item,
                              onTap: () => _open(item),
                              onLongPress: () => _showLongPressMenu(item),
                              onSecondaryTap: (pos) =>
                                  _showContextMenu(item, pos),
                            );
                            if (delta != null && t < 1.0) {
                              card = Transform.translate(
                                offset: Offset(
                                  delta.dx * (1 - t),
                                  delta.dy * (1 - t),
                                ),
                                child: card,
                              );
                            }
                            return card;
                          },
                        );
                      },
                      childCount: _items.length,
                    ),
                  );
                },
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
      ),
    );
  }
}

/// 网格卡片：和推荐页 / 搜索页同款（封面 Hero + 渐变 + 播放/时长 + 标题 + UP主/时间）
class _PopularGridCard extends StatelessWidget {
  final BiliRecommendItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<Offset> onSecondaryTap;

  const _PopularGridCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    required this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTapDown: (d) => onSecondaryTap(d.globalPosition),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 整页 Hero（iOS 整卡放大）模式：封面不单独包 Hero，
                  // 整卡 Hero 在 _PopularGridCard 返回处；经典模式保持
                  // 封面 Hero（只包封面图）。
                  SettingsService.heroTransitionBlurEnabled
                      ? _coverImage(item.cover)
                      : _coverImageWithHero(item.cover, item.bvid),
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
                  if (item.view > 0)
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
                            _fmtCount(item.view, context),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (item.duration > 0)
                    Positioned(
                      right: 6,
                      bottom: 6,
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
                          _fmtDur(item.duration),
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
                      item.title,
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
                    if (item.rcmdReason.isNotEmpty) ...[
                      Text(
                        item.rcmdReason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: cs.primary),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _subtitle(item, context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (item.danmaku > 0) ...[
                          Icon(
                            Icons.subtitles_outlined,
                            size: 12,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _fmtCount(item.danmaku, context),
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
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
    // 整页 Hero（iOS 整卡放大）模式：Hero 包整个卡片；经典模式封面
    // Hero 已由封面层提供。
    if (SettingsService.heroTransitionBlurEnabled) {
      return MetroTileInteraction(
        onTapStart: (_, __) {},
        showBorder: false,
        child: Hero(
          tag: 'bili_video_${item.bvid}',
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
          child: card,
        ),
      );
    }
    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
  }

  String _subtitle(BiliRecommendItem item, BuildContext context) {
    final ago = _fmtAgo(item.pubdate, context);
    if (ago.isEmpty) return item.ownerName;
    if (item.ownerName.isEmpty) return ago;
    return '$ago  ${item.ownerName}';
  }
}

/// 单列卡片：和推荐页 / 搜索页同款（Hero 缩略图 + 右侧标题/信息）
class _PopularListCard extends StatelessWidget {
  final BiliRecommendItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<Offset> onSecondaryTap;

  const _PopularListCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    required this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget thumb = _coverImage(item.cover, width: 148, height: 84);
    // 整页 Hero（iOS 整卡放大）模式：缩略图不单独包 Hero，整卡 Hero 在
    // 卡片最外层；经典模式保持缩略图 Hero。
    if (!SettingsService.heroTransitionBlurEnabled) {
      thumb = Hero(
        tag: 'bili_video_${item.bvid}',
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: thumb,
      );
    }
    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTapDown: (d) => onSecondaryTap(d.globalPosition),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              thumb,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    if (item.rcmdReason.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.rcmdReason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: cs.primary),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(item, context),
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
                          _fmtCount(item.view, context),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.subtitles_outlined,
                          size: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _fmtCount(item.danmaku, context),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        if (item.duration > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _fmtDur(item.duration),
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurfaceVariant,
                              ),
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
    // 整页 Hero（iOS 整卡放大）模式：Hero 包整个卡片；经典模式缩略图
    // Hero 已在卡片内层提供。
    if (SettingsService.heroTransitionBlurEnabled) {
      return MetroTileInteraction(
        onTapStart: (_, __) {},
        showBorder: false,
        child: Hero(
          tag: 'bili_video_${item.bvid}',
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
          child: card,
        ),
      );
    }
    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
  }

  String _subtitle(BiliRecommendItem item, BuildContext context) {
    final ago = _fmtAgo(item.pubdate, context);
    if (ago.isEmpty) return item.ownerName;
    if (item.ownerName.isEmpty) return ago;
    return '$ago  ${item.ownerName}';
  }
}

// ── 封面 helpers ──

Widget _coverImage(
  String url, {
  double? width,
  double? height,
  double aspect = 16 / 10,
}) {
  final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
      ? null
      : NetworkSettingsService.instance.apiHeaders;
  Widget img = url.isEmpty
      ? Container(
          color: Colors.grey.shade800,
          child: const Center(
            child: Icon(Icons.movie_outlined, color: Colors.white24),
          ),
        )
      : Image(
          image: CachedImageProvider(url, headers: headers),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade800,
            child: const Center(
              child: Icon(Icons.movie_outlined, color: Colors.white24),
            ),
          ),
        );
  final sized = width != null && height != null
      ? SizedBox(width: width, height: height, child: img)
      : AspectRatio(aspectRatio: aspect, child: img);
  // 单列缩略图保持圆角，与推荐页一致
  if (width != null && height != null) {
    return ClipRRect(borderRadius: BorderRadius.circular(8), child: sized);
  }
  return sized;
}

Widget _coverImageWithHero(String url, String bvid,
    {double? width, double? height, double aspect = 16 / 10}) {
  final img = _coverImage(url, width: width, height: height, aspect: aspect);
  return Hero(
    tag: 'bili_video_$bvid',
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
    child: img,
  );
}

String _fmtCount(int n, BuildContext context) {
  final l10n = AppLocalizations.of(context);
  if (n >= 100000000) {
    return l10n.countYi((n / 100000000).toStringAsFixed(1));
  }
  if (n >= 10000) return l10n.countWan((n / 10000).toStringAsFixed(1));
  return '$n';
}

String _fmtDur(int sec) {
  String two(int n) => n.toString().padLeft(2, '0');
  final m = sec ~/ 60;
  final s = sec % 60;
  return m >= 60 ? '${m ~/ 60}:${two(m % 60)}:${two(s)}' : '$m:${two(s)}';
}

String _fmtAgo(int ts, BuildContext context) {
  if (ts <= 0) return '';
  final l10n = AppLocalizations.of(context);
  final diff = DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(ts * 1000),
  );
  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
  if (diff.inDays < 30) return l10n.timeDaysAgo(diff.inDays);
  final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
