                                               
  
                                           
                                  
                                                         
                                                
                                                    
                        
                                                          
                                       
                                                          
                        
                                               
                                                                
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_bangumi_page.dart';
import 'package:naviflash/screens/bilibili_bangumi_timeline_page.dart';
import 'package:naviflash/src/content_reveal_gate.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/services/bilibili_recommend_service.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/back_top_fab.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/lazy_cover_image.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/navi_spring_physics.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/video_card.dart';

                      
const double _kTopBarHeight = 56.0;

                            
const double _kTabBarHeight = 48.0;

class BilibiliBangumiIndexPage extends StatefulWidget {
  const BilibiliBangumiIndexPage({super.key});

  @override
  State<BilibiliBangumiIndexPage> createState() =>
      _BilibiliBangumiIndexPageState();
}

class _BilibiliBangumiIndexPageState extends State<BilibiliBangumiIndexPage>
    with SingleTickerProviderStateMixin {
  static const double kCollapseThreshold = 120.0;

                                        
  static const List<(int, String)> _seasonTypes = [(1, '番剧'), (4, '国创')];

  late final TabController _tabController;

                                            
  final List<GlobalKey<_BangumiIndexTabState>> _tabKeys = [
    GlobalKey<_BangumiIndexTabState>(),
    GlobalKey<_BangumiIndexTabState>(),
  ];

  bool _topCollapsed = false;

  _BangumiIndexTabState? get _currentTab {
    if (_tabKeys.length <= _tabController.index) return null;
    return _tabKeys[_tabController.index].currentState;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _seasonTypes.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

                                    
                               
  bool _onTabScroll(ScrollNotification n) {
    if (n is! ScrollUpdateNotification) return false;
    final delta = n.scrollDelta ?? 0;
    var collapsed = _topCollapsed;
    if (delta > 0 && n.metrics.extentBefore > kCollapseThreshold) {
      collapsed = true;
    } else if (delta < 0 || n.metrics.extentBefore < 1) {
      collapsed = false;
    }
    if (collapsed != _topCollapsed && mounted) {
      setState(() => _topCollapsed = collapsed);
    }
    return false;
  }

                                             
  void _onTabChanged() {
    final ctrl = _tabController;
    if (ctrl.indexIsChanging) return;
    if (!mounted) return;
    setState(() => _topCollapsed = false);
  }

  double get _effectiveTopBarHeight =>
      _topCollapsed ? _kTabBarHeight : _kTopBarHeight + _kTabBarHeight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final current = _currentTab;
    final scaffold = Scaffold(
      backgroundColor: cs.surfaceContainer,
      floatingActionButton: current?.fab,
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
                  child: naviTabBarView(
                                                
                                                      
                    controller: _tabController,
                    children: [
                      for (var i = 0; i < _seasonTypes.length; i++)
                        _BangumiIndexTab(
                          key: _tabKeys[i],
                          seasonType: _seasonTypes[i].$1,
                          topBarHeight: () => _effectiveTopBarHeight,
                          onScrollNotification: _onTabScroll,
                        ),
                    ],
                  ),
                ),
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
    final l10n = AppLocalizations.of(context);
    return FrostedPanel(
      opacity: 0.75,
      blurSigma: 12,
                                                
      color: cs.surface,
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
                      iconColor: Colors.white,
                      frosted: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '番剧索引',
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
                      icon: Icons.calendar_month_outlined,
                      tooltip: '追番时间表',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const BilibiliBangumiTimelinePage(),
                        ),
                      ),
                      iconColor: cs.onSurface,
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
                  for (var i = 0; i < _seasonTypes.length; i++)
                    _buildTypeTab(_seasonTypes[i].$1, _seasonTypes[i].$2, i, cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

                                                   
  Widget _buildTypeTab(int type, String label, int index, ColorScheme cs) {
    final selected = _tabController.index == index;
    return InkWell(
      onTap: () => _tabController.animateTo(index),
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
}

                                       
                                                             
                      
class _BangumiIndexTab extends StatefulWidget {
  const _BangumiIndexTab({
    super.key,
    required this.seasonType,
    required this.topBarHeight,
    required this.onScrollNotification,
  });

                                 
  final int seasonType;

                                       
  final double Function() topBarHeight;

                                            
  final bool Function(ScrollNotification notification) onScrollNotification;

  @override
  State<_BangumiIndexTab> createState() => _BangumiIndexTabState();
}

class _BangumiIndexTabState extends State<_BangumiIndexTab>
    with AutomaticKeepAliveClientMixin {
                                              
  BiliBangumiCondition? _condition;

                                       
  String? _condError;

                                                
                          
  final Map<String, String> _params = {};

                 
  List<BiliBangumiItem> _items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

                                              
  final _fabVisibility = BackTopFabVisibility();

  late final ScrollController _scroll = ScrollController();

                                    
                               
  ContentRevealGate? _revealGate;

  bool get _isContentGated => _revealGate?.isGated ?? false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScrollPosition);
    _loadCondition();
  }

  @override
  void dispose() {
    _scroll.dispose();
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

  void _onScrollPosition() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) _loadMore();
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

             

                               
                                                             
                                                 
                           
  Map<String, String> _displayLocaleHeaders() {
    final settings = context.read<SettingsService>();
    return context
        .read<BilibiliTranslateService>()
        .headersForDisplayLocale(settings.appLocaleCode);
  }

                            
                                  
  Future<void> _loadCondition() async {
    setState(() {
      _loading = true;
      _condError = null;
      _error = null;
      _items = [];
      _page = 1;
      _hasMore = true;
    });
    _armRevealGate();
    final condition = await BilibiliRecommendService.fetchBangumiCondition(
      seasonType: widget.seasonType,
      displayLocaleHeaders: _displayLocaleHeaders(),
    );
    if (!mounted) return;
    if (condition == null) {
      setState(() {
        _loading = false;
        _condError = BilibiliRecommendService.lastErrorDetail ?? '加载失败，请重试';
      });
      return;
    }
    _params
      ..clear()
      ..['order'] = condition.order.isNotEmpty
          ? condition.order.first.field
          : '3';
    for (final f in condition.filters) {
      if (f.values.isNotEmpty) _params[f.field] = f.values.first.keyword;
    }
    setState(() => _condition = condition);
    _load(forceRefresh: true);
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
    final result = await BilibiliRecommendService.fetchBangumiIndex(
      page: targetPage,
      seasonType: widget.seasonType,
      filters: Map<String, String>.of(_params),
      displayLocaleHeaders: _displayLocaleHeaders(),
    );
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _loading = false;
        _loadingMore = false;
                                 
        if (forceRefresh || _items.isEmpty) {
          _error = BilibiliRecommendService.lastErrorDetail ?? '加载失败，请重试';
        }
        if (!forceRefresh) _hasMore = false;
      });
      return;
    }
                                       
    final seen = <int>{
      if (!forceRefresh)
        for (final it in _items) it.seasonId,
    };
    final fresh = result.items.where((it) => seen.add(it.seasonId)).toList();
    setState(() {
      if (forceRefresh) {
        _items = fresh;
        _page = 1;
      } else {
        _items = [..._items, ...fresh];
        _page = targetPage;
      }
      _hasMore = result.hasNext && fresh.isNotEmpty;
      _loading = false;
      _loadingMore = false;
      _error = null;
    });
  }

  void _loadMore() {
    if (_loading || _loadingMore || !_hasMore || _error != null) return;
    _load();
  }

                                 
  void _select(String field, String value) {
    if (_params[field] == value) return;
    setState(() => _params[field] = value);
    _load(forceRefresh: true);
  }

  void _openItem(BiliBangumiItem item) {
    FocusManager.instance.primaryFocus?.unfocus();
    openBilibiliBangumi(
      context,
      seasonId: item.seasonId,
      initialTitle: item.title,
      initialCover: item.cover,
      heroTag: 'bili_bangumi_${item.seasonId}',
    );
  }

                   

                                                
  Widget? get fab {
    if (_condError != null) return null;
    if (_error != null && _items.isEmpty) {
      return LoadRetryPill(onRetry: () => _load(forceRefresh: true));
    }
    return BackTopFab(extended: _fabVisibility.extended, onTap: _scrollToTop);
  }

             

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    return _buildBody(cs);
  }

  Widget _buildBody(ColorScheme cs) {
                                     
                                               
    if (_loading || _isContentGated) {
      return _centeredState(child: const LoadingIndicatorM3E());
    }
    if (_condError != null) {
      return _centeredState(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _condError!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _loadCondition,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (_error != null && _items.isEmpty) {
      return _centeredState(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return _centeredState(
        child: Text(
          '没有找到符合条件的番剧',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      );
    }
                                                   
                                 
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
                                         
        if (n.metrics.axis != Axis.vertical) return false;
        if (n is! ScrollUpdateNotification) return false;
                                       
        final delta = n.scrollDelta ?? 0;
        if (_fabVisibility.update(delta) && mounted) setState(() {});
        widget.onScrollNotification(n);
        return false;
      },
      child: AppRefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        color: cs.primary,
                                   
                           
                                                
                                             
        edgeOffset: context.watch<SettingsService>().refreshEdgeOffset,
        displacement: _kTabBarHeight +
            _kTabBarHeight +
            10 -
            40.0 +
            context.watch<SettingsService>().refreshDisplacement,
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
                height: widget.topBarHeight(),
              ),
            ),
                                         
            if (_condition != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_condition!.order.isNotEmpty)
                        _filterRow(
                          _condition!.order.first.field,
                          isOrder: true,
                        ),
                      for (final f in _condition!.filters)
                        if (f.values.isNotEmpty) _filterRow(f.field),
                    ],
                  ),
                ),
              ),
                                              
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final columns = (width / 150).floor().clamp(2, 6);
                  final cardW = (width - (columns - 1) * 12) / columns;
                                                  
                  final cellH = cardW * 4 / 3 + 84 + 12;
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: cardW / cellH,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _IndexCard(
                        item: _items[i],
                        onTap: () => _openItem(_items[i]),
                      ),
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

                            
  Widget _centeredState({required Widget child}) {
    return Column(
      children: [
        SizedBox(height: widget.topBarHeight()),
        Expanded(child: Center(child: child)),
      ],
    );
  }

                   
                                              
                                             
  Widget _filterRow(String field, {bool isOrder = false}) {
    final List<(String, String)> options;
    if (isOrder) {
      options = [for (final o in _condition!.order) (o.field, o.name)];
    } else {
      final f = _condition!.filters.firstWhere((e) => e.field == field);
      options = [
        for (final v in f.values)
          (v.keyword, v.name.isEmpty ? v.keyword : v.name),
      ];
    }
    final paramKey = isOrder ? 'order' : field;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (value, label) = options[i];
          final selected = _params[paramKey] == value;
          return Material(
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.14)
                : Theme.of(context).colorScheme.surfaceBright,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _select(paramKey, value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IndexCard extends StatelessWidget {
  final BiliBangumiItem item;
  final VoidCallback onTap;

  const _IndexCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    return VideoCardV(
      data: VideoCardData(
        cover: item.cover,
        title: item.title,
                                 
        heroTag: 'bili_bangumi_${item.seasonId}',
                                
        coverAspect: 3 / 4,
        badge: item.badge.isNotEmpty ? item.badge : null,
        reason: item.score.isNotEmpty ? '评分 ${item.score}' : null,
        subtitle: item.indexShow,
                                         
                         
        coverWidget: LazyCoverImage(
          item.cover,
          headers: headers,
          fit: BoxFit.cover,
          aspect: 3 / 4,
          maxDimension: 480,
        ),
      ),
      onTap: onTap,
    );
  }
}
