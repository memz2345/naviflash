                                          
  
                                   
                                                       
                                         
                                                            
                                        
import 'package:flutter/material.dart';

import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/widgets/navi_oval_tab_row.dart';
import 'package:naviflash/services/bilibili_dynamics_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/widgets/app_drawer.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/dynamic_card.dart';
import 'package:naviflash/widgets/dynamic_waterfall.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/msg_feed_common.dart';
import 'package:naviflash/screens/dynamic_publish_page.dart';
import 'package:naviflash/widgets/page_loading.dart';

class BilibiliDynamicsPage extends StatefulWidget {
                                 
  final bool embeddedInShell;

                                         
  final bool drawerMode;

                                                  
                     
  final TabController? controller;

                                          
                                      
  final bool showOwnTopBar;

                                               
                                               
                                       
                                     
  final Widget? topInsetSliver;

                                                        
                                           
                                        
  final double? refreshDisplacement;

  const BilibiliDynamicsPage({
    super.key,
    this.embeddedInShell = false,
    this.drawerMode = false,
    this.controller,
    this.showOwnTopBar = true,
    this.topInsetSliver,
    this.refreshDisplacement,
  });

  @override
  State<BilibiliDynamicsPage> createState() => _BilibiliDynamicsPageState();
}

class _BilibiliDynamicsPageState extends State<BilibiliDynamicsPage>
    with TickerProviderStateMixin {
  static const List<BiliDynTab> _tabs = BiliDynTab.values;

  late final TabController _tab =
      widget.controller ?? TabController(length: _tabs.length, vsync: this);

                                            
  bool get _ownsController => widget.controller == null;

                           
  late final Set<int> _visited = {_tab.index};

                       
  int _reloadTick = 0;

  Future<void> _openPublish() async {
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DynamicPublishPage()),
    );
    if (published == true && mounted) {
      setState(() => _reloadTick++);
    }
  }

  @override
  void initState() {
    super.initState();
    _tab.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tab.removeListener(_onTabChanged);
    if (_ownsController) _tab.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tab.indexIsChanging) return;
    if (_visited.add(_tab.index)) setState(() {});
  }

  String _label(AppLocalizations l10n, BiliDynTab tab) => switch (tab) {
    BiliDynTab.all => l10n.dynamicsTabAll,
    BiliDynTab.video => l10n.dynamicsTabVideo,
    BiliDynTab.pgc => l10n.dynamicsTabPgc,
    BiliDynTab.article => l10n.dynamicsTabArticle,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
                                                    
    final drawerStyle = widget.drawerMode && !widget.embeddedInShell;
                                          
                                         
                             
    final ownBarInset =
        (drawerStyle ? kMsgTopBarHeight : 0.0) +
        (widget.showOwnTopBar ? 44.0 : 0.0);
    final topInsetSliver =
        widget.topInsetSliver ??
        (widget.showOwnTopBar
            ? SliverToBoxAdapter(child: SizedBox(height: ownBarInset))
            : null);
    final feed = TabBarView(
      controller: _tab,
      children: [
        for (var i = 0; i < _tabs.length; i++)
          _visited.contains(i)
              ? _DynFeedView(
                  tab: _tabs[i],
                  reloadTick: _reloadTick,
                  topInsetSliver: topInsetSliver,
                  refreshDisplacement: widget.refreshDisplacement,
                  refreshEdgeOffset: widget.showOwnTopBar ? ownBarInset : null,
                )
              : const SizedBox.shrink(),
      ],
    );
    if (!widget.showOwnTopBar) {
                                         
      return feed;
    }
    return MsgPageScaffold(
      title: l10n.dynamicsTitle,
                                          
                                             
      hideTitle: !drawerStyle,
      showBack: !widget.embeddedInShell,
      backdropScale: !widget.embeddedInShell,
                                 
      drawer: widget.drawerMode && !widget.embeddedInShell
          ? const AppDrawer(currentPage: 'dynamics')
          : null,
      bottomHeight: 44,
                                                     
                                         
      bottom: NaviOvalTabRow(
        labels: [for (final t in _tabs) _label(l10n, t)],
        selectedIndex: _tab.index,
        onTap: (index) {
          if (index != _tab.index) _tab.animateTo(index);
        },
        height: 44,
      ),
                                     
      actions: !BilibiliDynamicsService.canUse
          ? const []
          : drawerStyle
              ? [
                  LiquidGlassMenuButton(
                    icon: Icons.more_vert,
                    tooltip: '更多',
                    transparent: true,
                    actions: [
                      GlassMenuAction(
                        icon: Icons.edit_outlined,
                        text: '发布动态',
                        onTap: _openPublish,
                      ),
                    ],
                  ),
                ]
              : [
                  MorphIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: '发布动态',
                    transparent: true,
                    onTap: _openPublish,
                  ),
                ],
                                      
      floatingActionButton: BilibiliDynamicsService.canUse && !widget.embeddedInShell
          ? FloatingActionButton(
              tooltip: '发布动态',
              onPressed: _openPublish,
              child: const Icon(Icons.edit_outlined),
            )
          : null,
      child: feed,
    );
  }
}

                   
class _DynFeedView extends StatefulWidget {
  final BiliDynTab tab;

                                    
  final int reloadTick;

                                              
  final Widget? topInsetSliver;

                                 
  final double? refreshDisplacement;

                                     
  final double? refreshEdgeOffset;

  const _DynFeedView({
    required this.tab,
    this.reloadTick = 0,
    this.topInsetSliver,
    this.refreshDisplacement,
    this.refreshEdgeOffset,
  });

  @override
  State<_DynFeedView> createState() => _DynFeedViewState();
}

class _DynFeedViewState extends State<_DynFeedView>
    with AutomaticKeepAliveClientMixin {
  final List<BiliDynamicDetail> _items = [];
  final ScrollController _scroll = ScrollController();
  String? _offset;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void didUpdateWidget(covariant _DynFeedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadTick != widget.reloadTick) {
      _offset = null;
      _hasMore = true;
      _load();
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) _loadMore();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    final page = await BilibiliDynamicsService.fetchFeed(tab: widget.tab);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = page.err;
      _offset = page.offset;
      _hasMore = page.hasMore;
      if (page.err == null) {
        _items
          ..clear()
          ..addAll(page.items);
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading || _error != null) return;
    final offset = _offset;
    if (offset == null || offset.isEmpty) return;
    setState(() => _loadingMore = true);
    final page = await BilibiliDynamicsService.fetchFeed(
      tab: widget.tab,
      offset: offset,
    );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (page.err != null) {
        _hasMore = false;
        return;
      }
      final seen = _items.map((e) => e.idStr).toSet();
      final fresh = page.items
          .where((e) => !seen.contains(e.idStr))
          .toList(growable: false);
      if (fresh.isEmpty) {
        _hasMore = false;
        return;
      }
      _items.addAll(fresh);
      _offset = page.offset;
      _hasMore = page.hasMore;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    if (!BilibiliDynamicsService.canUse) {
      return MsgLoginPrompt(
        icon: Icons.dynamic_feed_outlined,
        title: l10n.dynamicsLoginPrompt,
      );
    }
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _items.isEmpty,
    )) {
      return const PageLoadingIndicator();
    }
    if (_error != null && _items.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: LoadRetryPill(onRetry: _load),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return MsgEmptyView(
        icon: Icons.dynamic_feed_outlined,
        title: l10n.dynamicsEmpty,
      );
    }
    return AppRefreshIndicator(
      onRefresh: _load,
      displacement: widget.refreshDisplacement,
      edgeOffset: widget.refreshEdgeOffset,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AppRefreshScrollPhysics(),
        slivers: [
                                        
                                           
          if (widget.topInsetSliver != null) widget.topInsetSliver!,
                                                      
                                
          DynamicWaterfallSliver(
            items: _items,
            itemKey: (item) => ValueKey<String>(item.idStr),
            itemBuilder: (context, item) => DynamicCard(item: item),
          ),
          if (_loadingMore || !_hasMore)
            dynamicWaterfallTail(
              loadingMore: _loadingMore,
              hasMore: _hasMore,
              noMoreText: l10n.msgNoMore,
              color: cs.onSurfaceVariant,
            ),
                                 
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + 72,
            ),
          ),
        ],
      ),
    );
  }
}
