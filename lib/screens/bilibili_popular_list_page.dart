                                              
  
                                      
                                            
                                                    
                                                            
                                            
                                                      
import 'package:flutter/material.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/back_top_fab.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bilibili_recommend_service.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/ugc_selection_area.dart';
import 'package:naviflash/widgets/video_card.dart';
import 'package:naviflash/widgets/page_loading.dart';

         
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

                        
  List<({int number, String title})> _weeklySeries = [];
  int _weeklyNumber = 0;
  bool _weeklyExpanded = false;
  final Map<int, GlobalKey> _weeklyTabKeys = {};

             
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

                     
  late final ScrollController _scroll = ScrollController();

                                       
                                                   
                
  final _fabVisibility = BackTopFabVisibility();

                                    
  final GlobalKey<BackTopFabState> _fabKey = GlobalKey();

                                     
                                     
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();

                              
  bool _atTop = true;

  double get _effectiveTopBarHeight => _hasWeeklyTabs
      ? (_topCollapsed ? kTabBarHeight : kTopBarHeight + kTabBarHeight)
      : kTopBarHeight;

  void _onScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return;
    final metrics = notification.metrics;
    final delta = notification.scrollDelta ?? 0;
                                        
    if (_fabVisibility.update(delta) && mounted) {
      setState(() {});
    }
                                   
    final atTop = metrics.pixels <= 0.5;
    if (atTop != _atTop && mounted) {
      setState(() => _atTop = atTop);
    }
    if (_weeklyExpanded) {
      setState(() => _weeklyExpanded = false);
      return;
    }
    if (!_hasWeeklyTabs) return;
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
      _load();
      return;
    }
    state.show();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _gridRowAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
                                       
      _loading = _items.isEmpty;
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
                       
          _weeklyNumber = series.first.number;
        });
        final r = await BilibiliRecommendService.fetchWeeklyOne(_weeklyNumber);
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
    final currentIndex = _weeklySeries.indexWhere(
      (s) => s.number == _weeklyNumber,
    );
    if (currentIndex == -1) return;
    if (velocity < 0) {
                      
      if (currentIndex + 1 < _weeklySeries.length) {
        HapticFeedback.lightImpact();
        _selectWeekly(_weeklySeries[currentIndex + 1].number);
      }
    } else {
                      
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
                                    
                                      
      floatingActionButton: _error != null
          ? LoadRetryPill(onRetry: _load)
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
                Positioned.fill(child: _buildBody(cs, l10n)),
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
        ],
      ),
    );
    return IosBackdropScale(child: scaffold);
  }

  Widget _buildTopBar(ColorScheme cs, AppLocalizations l10n) {
                                                            
                    
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

  Widget _buildWeeklyTab(({int number, String title}) s, ColorScheme cs) {
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
                                      
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _items.isEmpty,
    )) {
      return Column(
        children: [
          SizedBox(height: _effectiveTopBarHeight),
          const Expanded(child: PageLoadingIndicator()),
        ],
      );
    }
    if (_error != null) {
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
                                                              
                                 
                                              
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        _onScroll(n);
        return false;
      },
      child: UgcSelectionArea(
        child: AppRefreshIndicator(
          refreshIndicatorKey: _refreshKey,
          onRefresh: () {
            if (_topCollapsed) setState(() => _topCollapsed = false);
            return _load();
          },
          color: cs.primary,
          child: GestureDetector(
            onHorizontalDragEnd: _hasWeeklyTabs ? _onHorizontalSwipe : null,
            behavior: HitTestBehavior.translucent,
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
                        _checkGridLayoutChange(
                          columns,
                          _items.length,
                          cellW,
                          cellH,
                        );
                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.78,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = _items[index];
                            return ListenableBuilder(
                              listenable: _gridRowAnimCtrl,
                              builder: (context, _) {
                                final t = Curves.easeInOut.transform(
                                  _gridRowAnimCtrl.value,
                                );
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
                          }, childCount: _items.length),
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
      ),
    );
  }
}

                                                         
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
    return VideoCardV(
      data: _videoCardData(item),
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
    );
  }
}

                                           
                        
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
    return VideoCardH(
      data: _videoCardData(item),
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      statsTrailing: item.duration > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                formatCardDuration(item.duration),
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
            )
          : null,
    );
  }
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
