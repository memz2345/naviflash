                                           
  
                            
                                       
                              
                                 
                                               
                                                
                          
                                                                     
                                                 
                                                              
                                                
                                                 
                                                 
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    hide GlassBottomBarTab;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_dynamics_page.dart';
import 'package:naviflash/services/bilibili_dynamics_service.dart'
    show BiliDynTab;
import 'package:naviflash/screens/bilibili_bangumi_index_page.dart';
import 'package:naviflash/services/bilibili_bangumi_service.dart';
import 'package:naviflash/screens/bilibili_bangumi_timeline_page.dart';
import 'package:naviflash/screens/bilibili_bangumi_page.dart';
import 'package:naviflash/screens/bilibili_bangumi_watching_page.dart';
import 'package:naviflash/widgets/app_tooltip.dart';
import 'package:naviflash/widgets/underline_tab_row.dart';
import 'package:naviflash/screens/bilibili_popular_list_page.dart';
import 'package:naviflash/screens/bilibili_region_categories_page.dart';
import 'package:naviflash/screens/bilibili_search_page.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/screens/bilibili_shorts_page.dart';
import 'package:naviflash/screens/bilibili_mine_page.dart';
import 'package:naviflash/screens/message_center_page.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_hot_service.dart';
import 'package:naviflash/services/bilibili_recommend_service.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:naviflash/services/bilibili_translate_api.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/link_utils.dart';
import 'package:naviflash/services/memory_pressure_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/liquid_glass_bar_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/app_drawer.dart';
import 'package:naviflash/widgets/back_top_fab.dart';
import 'package:naviflash/widgets/bottom_nav_settings_dialog.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/glass_bottom_bar.dart';
import 'package:naviflash/widgets/feed_loading_overlay.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/lazy_cover_image.dart';
import 'package:naviflash/widgets/side_bar_menu_button.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/live_tag_feed.dart';
import 'package:naviflash/widgets/long_press_glass_tab_switcher.dart';
import 'package:naviflash/widgets/message_center_entry.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/metro_tile.dart';
import 'package:naviflash/widgets/cover_menu_sheet.dart';
import 'package:naviflash/widgets/ugc_selection_area.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/navi_oval_tab_row.dart';
import 'package:naviflash/widgets/navi_spring_physics.dart';
import 'package:naviflash/widgets/page_loading.dart';
import 'package:naviflash/widgets/video_card.dart';

                                  
class _TabState<T> {
  List<T> items = [];
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  String? error;

                                                  
  int page = 0;

                                        
                                             
  final Set<String> freshKeys = {};

                                         
  int prevCols = 0;
  int prevCount = 0;
  String? prevFirstKey;
  final Map<int, Offset> itemTranslations = {};
}

                                                  
                                 
@visibleForTesting
String tabNavKey(int tab) => switch (tab) {
  _BilibiliRecommendPageState.kDynamicsTabIndex => 'dynamics',
  _BilibiliRecommendPageState.kShortsTabIndex => 'shorts',
  _BilibiliRecommendPageState.kMessagesTabIndex => 'messages',
  _BilibiliRecommendPageState.kMineTabIndex => 'mine',
  _ => 'home',
};

                                              
                                  
   
                                           
                                                       
                                                   
                                                
                             
                                             
   
                                                 
                                              
                                                        
                              
                              
@visibleForTesting
int navIndexInOrder(List<String> order, String key) {
  if (order.isEmpty) return 0;
  final i = order.indexOf(key);
  if (i >= 0) return i;
  final all = SettingsService.kAllBottomNavIds;
  final base = all.indexOf(key);
  if (base < 0) return 0;
                             
  for (var d = 1; d < all.length; d++) {
    for (final candidate in <int>[base - d, base + d]) {
      if (candidate < 0 || candidate >= all.length) continue;
      final j = order.indexOf(all[candidate]);
      if (j >= 0) return j;
    }
  }
  return 0;
}

@visibleForTesting
int navSwitchDirection(List<String> order, int fromTab, int toTab) {
  if (fromTab == toTab) return 0;
  final a = navIndexInOrder(order, tabNavKey(fromTab));
  final b = navIndexInOrder(order, tabNavKey(toTab));
  return b.compareTo(a);
}

                                                    
const int kTabCount = 8;

                                     
   
                                                
                  
@visibleForTesting
bool tabReachable(List<String> order, int tab) {
  final key = tabNavKey(tab);
  if (!SettingsService.kAllBottomNavIds.contains(key)) return true;
  return order.contains(key);
}

                        
@visibleForTesting
bool canSwipeForward(List<String> order, int current) {
  for (var i = current + 1; i < kTabCount; i++) {
    if (tabReachable(order, i)) return true;
  }
  return false;
}

                        
@visibleForTesting
bool canSwipeBackward(List<String> order, int current) {
  for (var i = current - 1; i >= 0; i--) {
    if (tabReachable(order, i)) return true;
  }
  return false;
}

                                                            
                         
   
                                         
                  
   
                                                  
                                                                 
class _HiddenTabsBlockedPhysics extends NaviTabBarViewScrollPhysics {
  const _HiddenTabsBlockedPhysics({
    required this.canGoNext,
    required this.canGoPrev,
    super.parent,
  });

                         
  final bool canGoNext;
  final bool canGoPrev;

  @override
  _HiddenTabsBlockedPhysics applyTo(ScrollPhysics? ancestor) =>
      _HiddenTabsBlockedPhysics(
        canGoNext: canGoNext,
        canGoPrev: canGoPrev,
        parent: buildParent(ancestor),
      );

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
                                
    if (offset > 0 && !canGoNext) return 0;
    if (offset < 0 && !canGoPrev) return 0;
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    if (!canGoNext && !canGoPrev) return false;
    return super.shouldAcceptUserOffset(position);
  }
}

class BilibiliRecommendPage extends StatefulWidget {
                                       
                       
  final bool embeddedInShell;

  const BilibiliRecommendPage({super.key, this.embeddedInShell = false});

                                                    
                                                    
  static final GlobalKey navKey = GlobalKey();

                                        
                                              
  static bool switchNavSection(String id) {
    final state = navKey.currentState;
    if (state is! _BilibiliRecommendPageState) return false;
    return state.switchToNavId(id);
  }

                                       
  static final ValueNotifier<bool> _gridMode = ValueNotifier(true);
  static bool _gridLoaded = false;

  static ValueNotifier<bool> get gridModeNotifier => _gridMode;

  @override
  State<BilibiliRecommendPage> createState() => _BilibiliRecommendPageState();
}

class _BilibiliRecommendPageState extends State<BilibiliRecommendPage>
    with TickerProviderStateMixin, RouteAware {
                                                         
                           
  static const double kVideoCardTargetWidth = 200.0;
  static const int kVideoCardMinColumns = 2;
  static const int kVideoCardMaxColumns = 8;

  late final AnimationController _gridRowAnimCtrl;

  static final _TabState<BiliRecommendItem> _rcmd = _TabState();
  static final _TabState<BiliRecommendItem> _hot = _TabState();
  static final _TabState<BiliBangumiItem> _bangumi = _TabState();

                                                   
                          
  final GlobalKey<LiveTagFeedState> _liveFeedKey =
      GlobalKey<LiveTagFeedState>();

                                                    
                     
  static List<BiliBangumiBannerItem> _bangumiBanners = [];

                                                
  static List<BiliBangumiRankItem> _bangumiRankItems = [];

                                             
  static List<BiliBangumiContinueItem> _bangumiContinueItems = [];
  static bool _bangumiContinueLoaded = false;

                                         
  List<BiliTimelineDay> _timeline = const [];
  bool _timelineLoaded = false;
  bool _timelineLoading = false;

                            
  int _timelineDayIndex = 0;

                                      
  final PageController _timelinePageCtrl = PageController();

                   
  static List<String> _hotwords = [];
  static bool _hotwordsLoaded = false;

                                                              
                                                       
  static List<BiliHotEntrance> _hotEntrances = [];
  static bool _hotEntrancesLoaded = false;

                                            
                                
  static const List<int> _kBangumiCarouselWeights = [1, 7, 1];

                                      
                             
  final CarouselController _bangumiCarouselCtrl = CarouselController();
  Timer? _bangumiCarouselTimer;

                                      
  double _bangumiCarouselStep = 0;

                                  
  final GlobalKey _bangumiCarouselKey = GlobalKey();

                                    
  Timer? _bangumiBannerRefreshTimer;
  bool _bangumiBannerLoading = false;

                                         
                                                     
                        
  static const int kRcmdBannerCount = 5;
  List<BiliRecommendItem> _rcmdBanners = [];
  final CarouselController _rcmdCarouselCtrl = CarouselController();
  Timer? _rcmdCarouselTimer;
  double _rcmdCarouselStep = 0;

  final ScrollController _rcmdScroll = ScrollController();
  final ScrollController _hotScroll = ScrollController();
  final ScrollController _bangumiScroll = ScrollController();

                                      
  BiliRecommendSource _source = BiliRecommendSource.web;

                              
  late final TabController _tabController;

                                           
                                       
                                  
                                                
  final List<GlobalKey<RefreshIndicatorState>> _feedRefreshKeys = List.generate(
    4,
    (_) => GlobalKey<RefreshIndicatorState>(),
  );

                                               
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

                                   
                                     
  final GlobalKey _searchBarKey = GlobalKey();

                                       
                                       
                  
  final GlobalKey _bottomBarKey = GlobalKey();

                                          
  final GlobalKey<BilibiliShortsPageState> _shortsKey = GlobalKey();

                                         
                                               
                                    
                        
  static const List<int> _kOvalTabs = [0, 1, 2, 3];

                                            
                                             
  static const List<String> _kTabLabels = [
    '直播',
    '推荐',
    '热门',
    '番剧',
    '动态',
    '短视频',
    '消息',
    '我的',
  ];

                                 
  static const int kDynamicsTabIndex = 4;

                                   
  static const int kShortsTabIndex = 5;

                                  
  static const int kMessagesTabIndex = 6;

                                
  static const int kMineTabIndex = 7;

                                                   
                                 
  static const Map<String, int> kNavItemTabIndex = {
    'home': 1,
    'shorts': kShortsTabIndex,
    'dynamics': kDynamicsTabIndex,
    'messages': kMessagesTabIndex,
    'mine': kMineTabIndex,
  };

                                
  final Map<String, String> _titleOverrides = {};

                          
  final Set<String> _showOriginalTitles = {};

  bool _gridMode = true;

                                       
                                   
  final _fabVisibility = BackTopFabVisibility();

                                             
                                                        
                                          
  bool _atTop = true;

                                             
     
                                                 
                                                        
                                              
                                              
             
  late final AnimationController _drawerProgress;

                                                 
                                    
  late final TabController _dynamicsTabCtrl;

                                                      
                                   
  int _homeTabIndex = 1;

                                      
                                              
     
                                              
  int? _rcmdSavedTipAt;

                                          
  bool _hotSearchExpanded = false;

                                                                     
                                                                            
                                      
  late final SettingsService _settings;

  @override
  void initState() {
    super.initState();
                                          
                
    LiquidGlassBarService.bindTabSelected(_onNativeBottomBarTap);
                                           
    _navPushCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(_onNavPushTick);
    _settings = context.read<SettingsService>();
    _source = _settings.recommendSource;
                                  
    final navOrder = _settings.bottomNavOrder;
    final initialIndex =
        kNavItemTabIndex[navOrder.isNotEmpty ? navOrder.first : 'home'] ?? 1;
    _tabController = TabController(
      length: kTabCount,
      initialIndex: initialIndex,
      vsync: this,
    )..addListener(_onTabChanged);
    _gridRowAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
                                                  
    _drawerProgress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 246),
    );
    _dynamicsTabCtrl = TabController(
      length: BiliDynTab.values.length,
      vsync: this,
    )..addListener(_onDynamicsTabChanged);
    _loadGridState();
    BilibiliRecommendPage._gridMode.addListener(_onGridModeChanged);
    _rcmdScroll.addListener(() => _onScroll(_rcmdScroll, _loadRcmdMore));
    _hotScroll.addListener(() => _onScroll(_hotScroll, _loadHotMore));
    _bangumiScroll.addListener(
      () => _onScroll(_bangumiScroll, _loadBangumiMore),
    );
                              
    _settings.addListener(_onSettingsChanged);
                                                   
    MemoryPressureService.tick.addListener(_onMemoryPressure);
                                
    if (_rcmd.items.isEmpty) {
      _loadRcmd(forceRefresh: true);
    } else {
      _translateTitles(_rcmd.items);
    }
                                         
    _startBangumiBannerRefresh();
  }

  @override
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null || route == _nativeBarRoute) return;
    if (_nativeBarRoute != null) {
      liquidGlassBarRouteObserver.unsubscribe(this);
    }
    _nativeBarRoute = route;
    liquidGlassBarRouteObserver.subscribe(this, route);
                                  
      
                                      
                                                                    
                                                  
                                                       
                                          
                               
    _isTopRoute = route.isCurrent;
  }

                  
     
                                                      
                                                 
                                                        
                             
  bool _isTopRoute = true;

                                         
  @override
  void didPushNext() {
    _isTopRoute = false;
    _hideNativeBottomBar();
  }

                             
  @override
  void didPopNext() {
    _isTopRoute = true;
    if (mounted) setState(() {});
  }

                       
     
                                                     
                                                        
                                           
                                              
  void _hideNativeBottomBar() {
    if (!_nativeBarShown) return;
    _nativeBarShown = false;
    _nativeBarOrderKey = null;
    _nativeBarIndex = null;
    debugPrint('[glassbar] hide（首页被盖住 / 销毁）');
    unawaited(LiquidGlassBarService.hide());
  }

  @override
  void dispose() {
    liquidGlassBarRouteObserver.unsubscribe(this);
    _nativeBarRoute = null;
                                    
                                          
                                              
                                              
                                                      
                         
    LiquidGlassBarService.unbindTabSelected(_onNativeBottomBarTap);
    _navPushCtrl.dispose();
    if (LiquidGlassBarService.ownsVisibleBar(_onNativeBottomBarTap)) {
      unawaited(LiquidGlassBarService.hide());
    }
    _bangumiCarouselTimer?.cancel();
    _bangumiBannerRefreshTimer?.cancel();
    _rcmdCarouselTimer?.cancel();
    _bangumiCarouselCtrl.dispose();
    _timelinePageCtrl.dispose();
    _rcmdCarouselCtrl.dispose();
    _tabController.dispose();
    BilibiliRecommendPage._gridMode.removeListener(_onGridModeChanged);
    _settings.removeListener(_onSettingsChanged);
    MemoryPressureService.tick.removeListener(_onMemoryPressure);
    _rcmdScroll.dispose();
    _hotScroll.dispose();
    _bangumiScroll.dispose();
    _gridRowAnimCtrl.dispose();
    _drawerProgress.dispose();
    _dynamicsTabCtrl.dispose();
    _homeSearchProgress.dispose();
    super.dispose();
  }

                                                  
                                                    
                                              
                                 
  void _onMemoryPressure() {
    if (!mounted) return;
    final current = _tabController.index;
    void trim<T>(_TabState<T> data, int tabIndex) {
      if (tabIndex == current) return;
      if (data.items.length > 100) {
        data.items.removeRange(0, data.items.length - 100);
      }
      data.itemTranslations.clear();
    }

                                                     
    trim(_rcmd, 1);
    trim(_hot, 2);
    trim(_bangumi, 3);
  }

                         
  void _onDynamicsTabChanged() {
    if (mounted && _tabController.index == kDynamicsTabIndex) setState(() {});
  }

                               
  String _dynTabLabel(AppLocalizations l10n, BiliDynTab tab) => switch (tab) {
    BiliDynTab.all => l10n.dynamicsTabAll,
    BiliDynTab.video => l10n.dynamicsTabVideo,
    BiliDynTab.pgc => l10n.dynamicsTabPgc,
    BiliDynTab.article => l10n.dynamicsTabArticle,
  };

                                         
                                               
  bool switchToNavId(String id) {
    final idx = id == 'home' ? _homeTabIndex : kNavItemTabIndex[id];
    if (idx == null) return false;
    if (idx == _tabController.index) return true;
    final physical = idx.compareTo(_tabController.index);
    final dir = navSwitchDirection(
      _settings.bottomNavOrder,
      _tabController.index,
      idx,
    );
    if (dir != 0 && dir == physical) {
      _tabController.animateTo(idx);
    } else {
                                              
      _startNavPush(idx, dir == 0 ? physical : dir);
    }
    return true;
  }

  void _onTabChanged() {
    final i = _tabController.index;
                                              
                                          
    _atTop = true;
                                           
                                         
    if (i <= 3) {
      _homeTabIndex = i;
    }
                                
    if (i == kShortsTabIndex) {
      _shortsKey.currentState?.resumePlayback();
    } else {
      _shortsKey.currentState?.pausePlayback();
    }
    if (i == 3) {
                                            
      _startBangumiCarouselAutoPlay();
                                 
      if (!_timelineLoaded && !_timelineLoading) _loadTimeline();
    } else if (i == 1) {
                            
      _startRcmdCarouselAutoPlay();
    }
    if (mounted) setState(() {});
  }

                                  
     
                                              
                                                         
                                      
                                                
                                                                
                          
  void _syncShortsPlayback() {
    final state = _shortsKey.currentState;
    if (state == null) return;
    final shouldPlay = _tabController.index == kShortsTabIndex;
    if (state.playbackActivated == shouldPlay) return;
    if (shouldPlay) {
      state.resumePlayback();
    } else {
      state.pausePlayback();
    }
  }

                                    
                                        
                                                  
                                      
                                        
                              
  final ValueNotifier<double> _homeSearchProgress = ValueNotifier<double>(0.0);

                                       
                                              
  bool _homeSearchCollapsed = false;

                                  
  static const double kSearchBarCollapseDistance = 120.0;

  void _onFabScrollDirection(ScrollNotification n) {
    if (n is! ScrollUpdateNotification) return;
    if (n.metrics.axis != Axis.vertical) return;
    final delta = n.scrollDelta ?? 0;
    if (delta == 0 || !mounted) return;
                                            
                                                   
                                           
                               
    unawaited(LiquidGlassBarService.refresh(scrollDelta: delta));
    var needSetState = _fabVisibility.update(delta);
    if (_updateHomeSearchProgress(n, delta)) needSetState = true;
                                         
    final atTop = n.metrics.pixels <= 0.5;
    if (atTop != _atTop) {
      _atTop = atTop;
      needSetState = true;
    }
    if (needSetState) setState(() {});
  }

                                                     
                                        
  bool _updateHomeSearchProgress(ScrollNotification n, double delta) {
    if (!_showHomeSearchBar) return false;
    var p = _homeSearchProgress.value + delta / kSearchBarCollapseDistance;
                   
    if (n.metrics.pixels <= 0) p = 0.0;
    p = p.clamp(0.0, 1.0);
    if ((p - _homeSearchProgress.value).abs() > 0.0005) {
      _homeSearchProgress.value = p;
    }
                                   
    final collapsed = _homeSearchCollapsed ? p > 0.35 : p > 0.65;
    if (collapsed == _homeSearchCollapsed) return false;
    _homeSearchCollapsed = collapsed;
    return true;
  }

                                
  void _scrollCurrentTabToTop() {
    final index = _tabController.index;
    if (index == 0) {
      _liveFeedKey.currentState?.scrollToTop();
      return;
    }
                               
    if (index == kDynamicsTabIndex || index >= kMessagesTabIndex) return;
    final sc = switch (index) {
      1 => _rcmdScroll,
      2 => _hotScroll,
      _ => _bangumiScroll,
    };
    if (sc.hasClients && sc.offset > 0) {
      sc.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

                                           
  void _onTabTap(int index) {
                                     
                                       
    if (index == kDynamicsTabIndex || index >= kMessagesTabIndex) {
      if (_tabController.index != index) _switchTabTo(index);
      return;
    }
    if (_tabController.index == index) {
      if (index == 0) {
                                                  
        final live = _liveFeedKey.currentState;
        if (live != null) {
          live.scrollToTop();
          live.refresh();
          return;
        }
      }
      final sc = switch (index) {
        1 => _rcmdScroll,
        2 => _hotScroll,
        _ => _bangumiScroll,
      };
      if (sc.hasClients && sc.offset > 0) {
        sc.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
                                     
      _refreshCurrentFeed(index);
    } else {
      _switchTabTo(index);
    }
  }

                                        
                         
           
     
                                             
                                                         
                                                  
                                   
  void _switchTabTo(int index) {
    if (index == _tabController.index) return;
    final dir = navSwitchDirection(
      _settings.bottomNavOrder,
      _tabController.index,
      index,
    );
    final physical = index.compareTo(_tabController.index);
                                                
                      
    if (dir != 0 && dir == physical) {
      _tabController.animateTo(index);
      return;
    }
                                                
                                         
                    
                                           
    _startNavPush(index, dir == 0 ? physical : dir);
  }

                      
                                                    
     
                                                              
                                             
                                                     
  late final AnimationController _navPushCtrl;

                                  
  int _navPushDir = 1;

                   
  int? _navPushTarget;

                                    
  bool _navPushSwitched = false;

  void _onNavPushTick() {
    if (_navPushSwitched) {
      if (_navPushCtrl.isCompleted) {
        _navPushTarget = null;
        _navPushSwitched = false;
      }
      return;
    }
                                    
    if (_navPushCtrl.value >= 0.5) {
      final target = _navPushTarget;
      _navPushSwitched = true;
      if (target != null && mounted) {
        setState(() => _tabController.index = target);
      }
    }
  }

                                     
     
                                           
                                   
  void _startNavPush(int index, int dir) {
    if (dir == 0) {
      _tabController.index = index;
      return;
    }
    _navPushDir = dir;
    _navPushTarget = index;
    _navPushSwitched = false;
    _navPushCtrl.value = 1.0;
    if (mounted) {
      setState(() => _tabController.index = index);
    } else {
      _tabController.index = index;
    }
    _navPushCtrl.animateTo(0, curve: Curves.easeOutCubic);
  }

                                               
     
                                                         
     
                                                        
                                                          
                                                             
                                                        
                                                          
                                               
                                                
  Widget _navPushWrap(Widget child) => AnimatedBuilder(
    animation: _navPushCtrl,
    builder: (context, child) {
      final v = _navPushCtrl.value;
      final width = MediaQuery.sizeOf(context).width;
      return Transform.translate(
        offset: Offset(_navPushDir * v * width, 0),
        child: child,
      );
    },
    child: child,
  );

                                          
                                                            
                                                             
  void _refreshCurrentFeed(int index) {
    final state = _feedRefreshKeys[index].currentState;
    if (state != null) {
      state.show();
      return;
    }
    _forceLoadTab(index);
  }

                                            
  void _forceLoadTab(int index) {
    switch (index) {
      case 1:
        _loadRcmd(forceRefresh: true);
      case 2:
        _loadHot(forceRefresh: true);
      case 0:
                                    
        _liveFeedKey.currentState?.refresh();
      default:
        _loadBangumi(forceRefresh: true);
    }
  }

                                              
                               
                                              

                                    
  void _openSideMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _loadGridState() async {
    if (BilibiliRecommendPage._gridLoaded) {
      _gridMode = BilibiliRecommendPage._gridMode.value;
      return;
    }
    BilibiliRecommendPage._gridLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    BilibiliRecommendPage._gridMode.value =
        prefs.getBool('bili_recommend_grid_mode') ?? true;
    _gridMode = BilibiliRecommendPage._gridMode.value;
  }

  void _onGridModeChanged() {
    if (!mounted) return;
    setState(() => _gridMode = BilibiliRecommendPage._gridMode.value);
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final source = context.read<SettingsService>().recommendSource;
    if (source == _source) return;
    _source = source;
    _loadRcmd(forceRefresh: true);
  }

  void _onScroll(ScrollController controller, VoidCallback loadMore) {
    if (!controller.hasClients) return;
    final pos = controller.position;
                                        
                                   
                                  
    unawaited(LiquidGlassBarService.refresh());
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      loadMore();
    }
  }

                                              
          
                                              

                          
     
                                                    
                                             
                                 
  Future<void> _loadVideoTab(
    _TabState<BiliRecommendItem> data,
    Future<BiliRecommendResult<BiliRecommendItem>> Function(int page) fetcher, {
    bool forceRefresh = false,
    bool viaRefresh = false,
  }) async {
    if (!forceRefresh && (data.loading || data.loadingMore)) return;
    setState(() {
      if (forceRefresh) {
                   
                                            
                                          
                                  
        data.loading = data.items.isEmpty && !viaRefresh;
        data.loadingMore = false;
        data.error = null;
      } else {
        data.loadingMore = true;
      }
    });
    final result = await fetcher(data.page);
    if (!mounted) return;
    switch (result) {
      case BiliRecommendOk(:final items):
                                   
                          
                                          
                                           
                                                           
                                                       
        final seen = <String>{};
        final deduped = items
            .where((v) => v.bvid.isNotEmpty && seen.add(v.bvid))
            .toList();
        setState(() {
          if (forceRefresh) {
            final wasEmpty = data.items.isEmpty;
            if (data == _rcmd &&
                !wasEmpty &&
                SettingsService.rcmdKeepLastData) {
                                         
                                                
                                           
              final freshBvids = deduped.map((v) => v.bvid).toSet();
              var old = data.items
                  .where((v) => !freshBvids.contains(v.bvid))
                  .toList(growable: false);
                                                      
              if (old.length > 200) {
                old = old.take(50).toList(growable: false);
              }
              data.items = [...deduped, ...old];
                                               
              _rcmdSavedTipAt =
                  (SettingsService.rcmdSavedPositionTip && old.isNotEmpty)
                  ? deduped.length
                  : null;
            } else {
              data.items = deduped;
              if (data == _rcmd) _rcmdSavedTipAt = null;
            }
                                       
                                     
            data.freshKeys.clear();
            if (wasEmpty) {
              data.freshKeys.addAll(deduped.map((v) => v.bvid));
            }
          } else {
            final existing = data.items.map((v) => v.bvid).toSet();
            final fresh = deduped
                .where((v) => !existing.contains(v.bvid))
                .toList();
            data.items = [...data.items, ...fresh];
          }
          data.page += 1;
          data.hasMore = deduped.isNotEmpty;
          data.loading = false;
          data.loadingMore = false;
          data.error = null;
        });
                                              
                                          
        if (data == _rcmd && forceRefresh && deduped.isNotEmpty) {
          final banners = deduped.take(kRcmdBannerCount).toList();
          setState(() => _rcmdBanners = banners);
          _startRcmdCarouselAutoPlay();
        }
        _translateTitles(data.items);
        if (forceRefresh && deduped.isNotEmpty) {
                                               
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() => data.freshKeys.clear());
            }
          });
        }
      case BiliRecommendError(:final detail):
        setState(() {
          data.loading = false;
          data.loadingMore = false;
          if (forceRefresh || data.items.isEmpty) {
            data.error = detail;
          }
        });
    }
  }

                                         
  Widget _rcmdSavedTip(ColorScheme cs, AppLocalizations l10n) {
    final color = cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Divider(height: 1, color: color.withValues(alpha: 0.4)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(Icons.history, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  l10n.rcmdSavedPositionTipText,
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
          ),
          Expanded(
            child: Divider(height: 1, color: color.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

                      
  Future<void> _loadRcmd({bool forceRefresh = false, bool viaRefresh = false}) {
    return _loadVideoTab(
      _rcmd,
      (page) => BilibiliRecommendService.fetch(source: _source, freshIdx: page),
      forceRefresh: forceRefresh,
      viaRefresh: viaRefresh,
    );
  }

  void _loadRcmdMore() {
    if (_rcmd.loading || _rcmd.loadingMore || !_rcmd.hasMore) return;
    _loadRcmd();
  }

             
  Future<void> _loadHot({bool forceRefresh = false, bool viaRefresh = false}) {
    if (forceRefresh) {
                                    
      _hotwordsLoaded = false;
      _hotEntrancesLoaded = false;
    }
                                        
                                                
    _loadHotEntrances();
    _loadHotwords();
    return _loadVideoTab(
      _hot,
      (page) => BilibiliRecommendService.fetchPopular(pn: page + 1),
      forceRefresh: forceRefresh,
      viaRefresh: viaRefresh,
    );
  }

                                    
  Future<void> _loadHotwords() async {
    if (_hotwordsLoaded) return;
    final words = await BilibiliRecommendService.fetchHotwords();
    if (!mounted || words.isEmpty) return;
    setState(() {
      _hotwords = words;
      _hotwordsLoaded = true;
    });
  }

  void _loadHotMore() {
    if (_hot.loading || _hot.loadingMore || !_hot.hasMore) return;
    _loadHot();
  }

             
  Future<void> _loadBangumi({
    bool forceRefresh = false,
    bool viaRefresh = false,
  }) async {
    final data = _bangumi;
    if (!forceRefresh && (data.loading || data.loadingMore)) return;
    setState(() {
      if (forceRefresh) {
        data.loading = data.items.isEmpty && !viaRefresh;
        data.loadingMore = false;
        data.error = null;
      } else {
        data.loadingMore = true;
      }
    });
    final result = await BilibiliRecommendService.fetchBangumi(
      page: data.page + 1,
    );
    if (!mounted) return;
    switch (result) {
      case BiliRecommendOk(:final items):
                                               
                               
        final seen = <String>{};
        final deduped = items
            .where((v) => seen.add(v.seasonId.toString()))
            .toList();
        setState(() {
          if (forceRefresh) {
                                      
                                             
            final wasEmpty = data.items.isEmpty;
            data.items = deduped;
            data.freshKeys.clear();
            if (wasEmpty) {
              data.freshKeys.addAll(deduped.map((v) => v.seasonId.toString()));
            }
          } else {
            final existing = data.items
                .map((v) => v.seasonId.toString())
                .toSet();
            final fresh = deduped
                .where((v) => !existing.contains(v.seasonId.toString()))
                .toList();
            data.items = [...data.items, ...fresh];
          }
          data.page += 1;
          data.hasMore = deduped.isNotEmpty;
          data.loading = false;
          data.loadingMore = false;
          data.error = null;
        });
                                                          
                     
        if (data.page == 1 && deduped.isNotEmpty) {
          _loadBangumiChannel();
          _loadBangumiContinue();
        }
        if (forceRefresh && deduped.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() => data.freshKeys.clear());
            }
          });
        }
      case BiliRecommendError(:final detail):
        setState(() {
          data.loading = false;
          data.loadingMore = false;
          if (forceRefresh || data.items.isEmpty) {
            data.error = detail;
          }
        });
    }
  }

  void _loadBangumiMore() {
    if (_bangumi.loading || _bangumi.loadingMore || !_bangumi.hasMore) return;
    _loadBangumi();
  }

                             
  Future<void> _translateTitles(List<BiliRecommendItem> items) async {
    if (items.isEmpty) return;
    final translate = BilibiliTranslateService.instance;
    if (!translate.enabled) return;
    final list = <({String bvid, String title})>[];
    final overrides = <String, String>{};
    for (final v in items) {
      if (v.bvid.isEmpty || v.title.isEmpty) continue;
      final cached = BilibiliTitleCache.translatedTitle(v.bvid);
      if (cached != null) {
        overrides[v.bvid] = cached;
      } else {
        list.add((bvid: v.bvid, title: v.title));
      }
    }
    if (overrides.isNotEmpty && mounted) {
      setState(() => _titleOverrides.addAll(overrides));
    }
    if (list.isEmpty) return;
    final remote = await BilibiliTranslateApi.translateTitles(list);
    if (!mounted || remote.isEmpty) return;
    BilibiliTitleCache.rememberAll(remote);
    setState(() => _titleOverrides.addAll(remote));
  }

                                              
             
                                              

                                  
  String _titleFor(BiliRecommendItem item) {
    if (_showOriginalTitles.contains(item.bvid)) return item.title;
    final local = _titleOverrides[item.bvid];
    if (local != null && local.isNotEmpty) return local;
    return BilibiliTitleCache.displayTitle(item.bvid, item.title);
  }

  void _open(BiliRecommendItem item) {
                                             
                                        
    FocusManager.instance.primaryFocus?.unfocus();
    openBilibiliVideo(
      context,
      bvid: item.bvid,
      initialTitle: _titleFor(item),
      initialCover: item.cover,
      heroTag: 'bili_video_${item.bvid}',
    );
  }

  void _openBangumi(BiliBangumiItem item) {
    FocusManager.instance.primaryFocus?.unfocus();
    openBilibiliBangumi(
      context,
      seasonId: item.seasonId,
      initialTitle: item.title,
      initialCover: item.cover,
      heroTag: 'bili_bangumi_${item.seasonId}',
    );
  }

                                      
  Future<void> _loadBangumiChannel() async {
    if (_bangumiBannerLoading) return;
    _bangumiBannerLoading = true;
    final result = await BilibiliRecommendService.fetchBangumiChannel();
    _bangumiBannerLoading = false;
    if (!mounted) return;
    if (result.banners.isEmpty && result.ranks.isEmpty) return;
    setState(() {
      if (result.banners.isNotEmpty) _bangumiBanners = result.banners;
      if (result.ranks.isNotEmpty) _bangumiRankItems = result.ranks;
    });
    if (result.banners.isNotEmpty) _startBangumiCarouselAutoPlay();
  }

                                
                       
  Future<void> _loadBangumiContinue() async {
    if (_bangumiContinueLoaded) return;
    final account = BilibiliAccountService.instance;
    if (!account.isLoggedIn) return;
    if (account.cookieHeaderFor(BiliCookieScope.video) == null) return;
    final items = await BilibiliRecommendService.fetchBangumiContinue();
    if (!mounted || items.isEmpty) return;
    setState(() {
      _bangumiContinueItems = items;
      _bangumiContinueLoaded = true;
    });
  }

                                         
                                  
  void _startBangumiBannerRefresh() {
    _bangumiBannerRefreshTimer?.cancel();
    _bangumiBannerRefreshTimer = Timer.periodic(const Duration(seconds: 10), (
      _,
    ) {
      if (!mounted) return;
      if (_tabController.index != 3) return;           
      if (!_isBangumiCarouselOnScreen()) return;           
      _loadBangumiChannel();
    });
  }

                                              
                   
  bool _isBangumiCarouselOnScreen() {
    final ctx = _bangumiCarouselKey.currentContext;
    if (ctx == null) return false;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return false;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final screen = MediaQuery.sizeOf(ctx);
    return rect.bottom > 0 && rect.top < screen.height;
  }

                           
                                             
  void _startBangumiCarouselAutoPlay() {
    _bangumiCarouselTimer?.cancel();
    _bangumiCarouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_tabController.index != 3) return;                 
      if (_bangumiBanners.length < 2) return;
      if (!_bangumiCarouselCtrl.hasClients) return;          
      final pos = _bangumiCarouselCtrl.position;
      final step = _bangumiCarouselStep;
      if (step <= 0) return;
                                                           
                               
      if (pos.maxScrollExtent.isFinite &&
          pos.pixels + step >= pos.maxScrollExtent - 1) {
        pos.jumpTo(0);
      }
      _bangumiCarouselCtrl.animateTo(
        pos.pixels + step,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

                             
                                          
  void _startRcmdCarouselAutoPlay() {
    _rcmdCarouselTimer?.cancel();
    _rcmdCarouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_tabController.index != 1) return;                 
      if (_rcmdBanners.length < 2) return;
      if (!_rcmdCarouselCtrl.hasClients) return;
      final pos = _rcmdCarouselCtrl.position;
      final step = _rcmdCarouselStep;
      if (step <= 0) return;
      if (pos.maxScrollExtent.isFinite &&
          pos.pixels + step >= pos.maxScrollExtent - 1) {
        pos.jumpTo(0);
      }
      _rcmdCarouselCtrl.animateTo(
        pos.pixels + step,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

                                                      
                                                     
                           
  Widget _buildRcmdCarousel(ColorScheme cs, AppLocalizations l10n) {
    final banners = _rcmdBanners;
    if (banners.length < 2) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;
    final viewport = width - 32;
    final weights = _kBangumiCarouselWeights;
    final sum = weights[0] + weights[1] + weights[2];
    final middleExtent = viewport * weights[1] / sum;
    final height = middleExtent * 9 / 16;
    _rcmdCarouselStep = viewport * weights[0] / sum;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SizedBox(
        height: height,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
                                
            if (n is ScrollStartNotification && n.dragDetails != null) {
              _rcmdCarouselTimer?.cancel();
            } else if (n is ScrollEndNotification) {
              _startRcmdCarouselAutoPlay();
            }
            return false;
          },
          child: CarouselView.weighted(
            controller: _rcmdCarouselCtrl,
            flexWeights: weights,
            itemSnapping: true,
            consumeMaxWeight: false,
            infinite: true,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            itemClipBehavior: Clip.antiAlias,
            onTap: (i) => _openRcmdBanner(banners[i % banners.length]),
            children: [for (final item in banners) _rcmdCarouselCard(cs, item)],
          ),
        ),
      ),
    );
  }

                                          
                                   
  Widget _rcmdCarouselCard(ColorScheme cs, BiliRecommendItem item) {
    final cover = item.cover.startsWith('//')
        ? 'https:${item.cover}'
        : item.cover;
    final hq = cover.isEmpty ? '' : '$cover@640w_400h_1c.webp';
    final card = Stack(
      fit: StackFit.expand,
      children: [
        _coverImage(hq, aspect: 16 / 9),
                 
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.62),
              ],
            ),
          ),
        ),
                         
        Positioned(
          left: 14,
          right: 14,
          bottom: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titleFor(item),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
                ),
              ),
              const SizedBox(height: 3),
                                               
                                                         
              Row(
                children: [
                  if (item.view > 0)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                          Flexible(
                            child: Text(
                              _fmtCount(item.view),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  if (item.duration > 0)
                    Flexible(
                      child: Text(
                        _fmtDur(item.duration),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    return Hero(
      transitionOnUserGestures: true,
      tag: 'bili_rcmd_banner_${item.bvid}',
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
      child: card,
    );
  }

                               
                                
  void _openRcmdBanner(BiliRecommendItem item) {
    FocusManager.instance.primaryFocus?.unfocus();
    openBilibiliVideo(
      context,
      bvid: item.bvid,
      initialTitle: _titleFor(item),
      initialCover: item.cover,
      heroTag: 'bili_rcmd_banner_${item.bvid}',
    );
  }

                          
                                             
                             
  void _openBangumiBanner(BiliBangumiBannerItem item) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (item.seasonId > 0) {
      openBilibiliBangumi(
        context,
        seasonId: item.seasonId,
        initialTitle: item.title,
        initialCover: item.cover,
        heroTag: 'bili_bangumi_banner_${item.seasonId}',
      );
    } else if (item.url.isNotEmpty) {
      final normalized = item.url.startsWith('//')
          ? 'https:${item.url}'
          : item.url;
      Navigator.of(context).push(
        heroTransitionRoute(
          heroZoom: false,
          page: BrowserPage(
            initialUrl: normalized,
            title: AppLocalizations.of(context).chatBrowserTitle,
          ),
        ),
      );
    }
  }

  void _showLongPressMenu(BiliRecommendItem item) {
    showVideoBottomSheet(
      context,
      bvid: item.bvid,
      title: item.title,
      cover: item.cover,
      author: item.ownerName,
      showOriginal: _showOriginalTitles.contains(item.bvid),
      onToggleOriginal: (show) => _setShowOriginal(item.bvid, show),
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
      showOriginal: _showOriginalTitles.contains(item.bvid),
      onToggleOriginal: (show) => _setShowOriginal(item.bvid, show),
    );
  }

  void _setShowOriginal(String bvid, bool show) {
    setState(() {
      if (show) {
        _showOriginalTitles.add(bvid);
      } else {
        _showOriginalTitles.remove(bvid);
      }
    });
  }

                        
  void _showBangumiMenu(BiliBangumiItem item, Offset globalPosition) {
    showGlassDropdownMenu(
      context,
      actions: [
        GlassMenuAction(
          icon: Icons.play_circle_outline,
          text: '应用内播放',
          onTap: () => _openBangumi(item),
        ),
        GlassMenuAction(
          icon: Icons.tag_outlined,
          text: '复制SS号',
          onTap: () => _copyText('ss${item.seasonId}'),
        ),
        GlassMenuAction(
          icon: Icons.link,
          text: '复制番剧链接',
          onTap: () => _copyText(
            'https://www.bilibili.com/bangumi/play/ss${item.seasonId}',
          ),
        ),
      ],
      globalPosition: globalPosition,
      menuWidth: 200,
    );
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) showAppToast(context, '已复制 $text');
  }

                                              
        
                                              

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isPortraitBottomBar =
        !widget.embeddedInShell &&
        MediaQuery.of(context).orientation == Orientation.portrait;
                                            
                                               
    final showBottomBar = isPortraitBottomBar;
                                             
                                                           
                                      
    final tabIndex = _tabController.index;
    final currentFeed = switch (tabIndex) {
      1 => _rcmd,
      2 => _hot,
      3 => _bangumi,
      _ => null,
    };
    final feedError =
        currentFeed != null &&
        currentFeed.error != null &&
        currentFeed.items.isEmpty;
                                       
    final useM3BottomBar = context.watch<SettingsService>().useM3BottomBar;
                                                     
                                                             
                                         
           
                               
    _syncShortsPlayback();
    _syncNativeBottomBar(
      visible:
          showBottomBar && LiquidGlassBarService.canUseNative && !_drawerOpen,
      order: context.watch<SettingsService>().bottomNavOrder,
      currentKey: switch (_tabController.index) {
        kDynamicsTabIndex => 'dynamics',
        kShortsTabIndex => 'shorts',
        kMessagesTabIndex => 'messages',
        kMineTabIndex => 'mine',
        _ => 'home',
      },
    );
    final scaffold = Scaffold(
      key: _scaffoldKey,
                                                         
      drawer: widget.embeddedInShell
          ? null
          : AppDrawer(currentPage: tabNavKey(tabIndex)),
                                              
                                   
      onDrawerChanged: (opened) {
        _drawerOpen = opened;
        SideBarDrawerState.setOpen(opened);
        if (opened) {
          _drawerProgress.forward();
                                             
          _hideNativeBottomBar();
        } else {
          _drawerProgress.reverse();
                                         
          Future.delayed(const Duration(milliseconds: 280), () {
            if (mounted && !_drawerOpen) setState(() {});
          });
        }
      },
                                                  
      extendBody: showBottomBar,
      bottomNavigationBar: showBottomBar
          ? (LiquidGlassBarService.canUseNative
                ? _buildNativeBottomBarSlot()
                : SafeArea(
                    top: false,
                                                     
                                     
                    bottom: useM3BottomBar,
                    child: Padding(
                      padding: useM3BottomBar
                          ? EdgeInsets.zero
                          : const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: _buildBottomNav(cs, l10n),
                    ),
                  ))
          : null,
      backgroundColor: widget.embeddedInShell
          ? Colors.transparent
          : cs.surfaceContainer,
                                         
                                        
                                     
      floatingActionButton:
          (tabIndex == 0 ||
              tabIndex == kDynamicsTabIndex ||
              tabIndex == kShortsTabIndex ||
              tabIndex >= kMessagesTabIndex)
          ? null
          : Padding(
                                              
                                   
              padding: EdgeInsets.only(
                bottom: isPortraitBottomBar
                    ? LiquidGlassBarService.barHeight +
                          LiquidGlassBarService.bottomGap
                    : 0,
              ),
              child: feedError
                  ? LoadRetryPill(onRetry: () => _forceLoadTab(tabIndex))
                  : BackTopFab(
                      extended: _fabVisibility.extended,
                                                   
                                               
                      atTop: _atTop,
                      onTap: _scrollCurrentTabToTop,
                                                
                      onRefresh: () => _refreshCurrentFeed(tabIndex),
                    ),
            ),
      body: Stack(
        children: [
                                             
          PageBackground(baseColor: cs.surfaceContainer, contentStyle: true),
          SafeArea(
                                                 
                                                      
            bottom: !showBottomBar,
                                               
                                                       
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                _onFabScrollDirection(n);
                return false;
              },
              child: Stack(
                children: [
                                            
                  Positioned.fill(
                                                                       
                    child: _navPushWrap(
                      naviTabBarView(
                        controller: _tabController,
                                                                 
                        physics: _HiddenTabsBlockedPhysics(
                          canGoNext: canSwipeForward(
                            _settings.bottomNavOrder,
                            tabIndex,
                          ),
                          canGoPrev: canSwipeBackward(
                            _settings.bottomNavOrder,
                            tabIndex,
                          ),
                        ),
                                                                 
                                                            
                        children: [
                          _tabWithHeroMode(
                            0,
                            _LazyKeepAliveTab(
                                                                
                                                           
                                                                 
                              child: LiveTagFeed(
                                key: _liveFeedKey,
                                headerInset: _topBarHeight,
                                gridMaxColumns: 8,
                              ),
                            ),
                          ),
                          _tabWithHeroMode(
                            1,
                            _LazyKeepAliveTab(
                              onFirstBuild: null,
                              child: _buildVideoFeed(
                                cs,
                                l10n,
                                _rcmd,
                                _rcmdScroll,
                                refreshKey: _feedRefreshKeys[1],
                                load: _loadRcmd,
                                keyOf: (v) => v.bvid,
                                gridCard: _gridCard,
                                listCard: _listCard,
                                header: _rcmdBanners.length >= 2
                                    ? _buildRcmdCarousel(cs, l10n)
                                    : null,
                              ),
                            ),
                          ),
                          _tabWithHeroMode(
                            2,
                            _LazyKeepAliveTab(
                              onFirstBuild: _loadHot,
                              child: _buildVideoFeed(
                                cs,
                                l10n,
                                _hot,
                                _hotScroll,
                                refreshKey: _feedRefreshKeys[2],
                                load: _loadHot,
                                keyOf: (v) => v.bvid,
                                gridCard: _gridCard,
                                listCard: _listCard,
                                header: _buildHotHeader(cs, l10n),
                              ),
                            ),
                          ),
                          _tabWithHeroMode(
                            3,
                            _LazyKeepAliveTab(
                              onFirstBuild: _loadBangumi,
                              child: _buildBangumiFeed(cs, l10n),
                            ),
                          ),
                                                           
                                                        
                                                       
                                                          
                                                       
                          _tabWithHeroMode(
                            kDynamicsTabIndex,
                            _LazyKeepAliveTab(
                              child: BilibiliDynamicsPage(
                                embeddedInShell: true,
                                showOwnTopBar: false,
                                controller: _dynamicsTabCtrl,
                                topInsetSliver: SliverToBoxAdapter(
                                  child: ValueListenableBuilder<double>(
                                    valueListenable: _homeSearchProgress,
                                    builder: (context, p, _) => SizedBox(
                                      height:
                                          kTabBarHeight +
                                          (_showHomeSearchBar
                                              ? kHomeSearchBarHeight * (1 - p)
                                              : 0),
                                    ),
                                  ),
                                ),
                                                    
                                                             
                                refreshDisplacement:
                                    kTabBarHeight +
                                    10 -
                                    40.0 +
                                    context
                                        .watch<SettingsService>()
                                        .refreshDisplacement,
                              ),
                            ),
                          ),
                                                        
                                              
                          _tabWithHeroMode(
                            kShortsTabIndex,
                            _LazyKeepAliveTab(
                              child: BilibiliShortsPage(
                                key: _shortsKey,
                                embeddedInShell: true,
                              ),
                            ),
                          ),
                                                         
                                                       
                                                      
                                                           
                          _tabWithHeroMode(
                            kMessagesTabIndex,
                            _LazyKeepAliveTab(
                              child: MessageCenterPage(
                                embeddedInShell: true,
                                topBarLeading: widget.embeddedInShell
                                    ? null
                                    : SideBarEntryButton(
                                        onTap: _openSideMenu,
                                        menuRotation: _drawerProgress,
                                      ),
                              ),
                            ),
                          ),
                                                          
                          _tabWithHeroMode(
                            kMineTabIndex,
                            _LazyKeepAliveTab(
                              child: BilibiliMinePage(
                                embeddedInShell: true,
                                                         
                                                           
                                topBarLeading: widget.embeddedInShell
                                    ? null
                                    : SideBarEntryButton(
                                        onTap: _openSideMenu,
                                        menuRotation: _drawerProgress,
                                      ),
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
          ),
                                                 
                                                
                             
                                               
                                              
          if (tabIndex != kShortsTabIndex &&
              tabIndex != kMessagesTabIndex &&
              tabIndex != kMineTabIndex)
            Align(
              alignment: Alignment.topCenter,
              child: _buildTabBar(cs, l10n),
            ),
        ],
      ),
    );
                                                 
                                               
                                           
                                   
                                                   
    return widget.embeddedInShell
        ? scaffold
        : PopScope(
                                                 
                                                
                                        
            canPop: tabIndex <= 3,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop || !mounted) return;
              _switchTabTo(_homeTabIndex);
            },
            child: IosBackdropScale(child: scaffold),
          );
  }

                         
  static const double kTabBarHeight = 56.0;

                                             
  static const double kHomeSearchBarHeight = 52.0;

                                               
                                           
                                        
                                
                                                              
                                     
                             
     
                                                      
                                        

  String? _nativeBarOrderKey;
  int? _nativeBarIndex;
  bool _nativeBarShown = false;
  ModalRoute<dynamic>? _nativeBarRoute;

                                                 
                                     
  bool _drawerOpen = false;

                                       
                                                       
                                                
  Widget _buildNativeBottomBarSlot() =>
      SizedBox(height: LiquidGlassBarService.slotHeight(context));

                           
     
                                                  
                                             
                      
     
                                                      
                                             
                                               
  void _syncNativeBottomBar({
    required bool visible,
    required List<String> order,
    required String currentKey,
  }) {
                                                      
                                        
                                             
                                      
    if (!visible || !_isTopRoute) {
      _hideNativeBottomBar();
      return;
    }
    LiquidGlassBarService.refresh();
                                                  
                                          
    final index = navIndexInOrder(order, currentKey);
                                              
                                         
    final size = MediaQuery.sizeOf(context);
    final key =
        '${order.join(',')}|${size.width.round()}x${size.height.round()}';
    if (_nativeBarShown &&
        _nativeBarOrderKey == key &&
        _nativeBarIndex == index) {
      return;
    }
    final needShow = !_nativeBarShown || _nativeBarOrderKey != key;
    _nativeBarOrderKey = key;
    _nativeBarIndex = index;
    final l10n = AppLocalizations.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
                                              
      if (_drawerOpen) {
        _hideNativeBottomBar();
        return;
      }
      if (needShow) {
        final ok = await LiquidGlassBarService.show(
          context: context,
          tabs: [
            for (final id in order)
              LiquidGlassBarTab(
                id: id,
                label: _navItemTab(id, l10n).label,
                icon: _navItemTab(id, l10n).icon,
                selectedIcon: _navItemTab(id, l10n).selectedIcon,
              ),
          ],
          index: index < 0 ? 0 : index,
          height: LiquidGlassBarService.barHeight,
          accent: Theme.of(context).colorScheme.primary,
        );
        if (!ok) {
                                             
          LiquidGlassBarService.enabled = false;
          if (mounted) setState(() {});
          return;
        }
        _nativeBarShown = true;
      } else {
        await LiquidGlassBarService.updateIndex(index < 0 ? 0 : index);
      }
      await LiquidGlassBarService.refresh(force: true);
    });
  }

                                                 
     
                                      
                                          
  void _onNativeBottomBarTap(int index) {
    final order = context.read<SettingsService>().bottomNavOrder;
    if (index < 0 || index >= order.length) return;
    final id = order[index];
    if (id == 'shorts') {
      if (_tabController.index == kShortsTabIndex) {
        _shortsKey.currentState?.refreshViaIndicator();
      } else {
        _openShorts();
      }
      return;
    }
    _onTabTap(id == 'home' ? _homeTabIndex : (kNavItemTabIndex[id] ?? 1));
  }

  Widget _buildBottomNav(ColorScheme cs, AppLocalizations l10n) {
    final settings = context.watch<SettingsService>();
                                     
    final order = settings.bottomNavOrder;
    final searchOn = settings.bottomBarSearch;

                                               
                                                      
                                                  
    final currentKey = switch (_tabController.index) {
      kDynamicsTabIndex => 'dynamics',
      kShortsTabIndex => 'shorts',
      kMessagesTabIndex => 'messages',
      kMineTabIndex => 'mine',
      _ => 'home',
    };
    return AppBottomBar(
      key: _bottomBarKey,
      tabs: [for (final id in order) _navItemTab(id, l10n)],
      selectedIndex: navIndexInOrder(order, currentKey),
      onTabSelected: (index) {
        if (index < 0 || index >= order.length) return;
        final id = order[index];
                                              
        if (id == 'shorts') {
          if (_tabController.index == kShortsTabIndex) {
            _shortsKey.currentState?.refreshViaIndicator();
          } else {
            _openShorts();
          }
          return;
        }
                                               
                         
        _onTabTap(id == 'home' ? _homeTabIndex : (kNavItemTabIndex[id] ?? 1));
      },
                                                
      onLongPress: () => showBottomNavSettingsDialog(context),
                                     
      extraButton: searchOn
          ? GlassTabBarExtraButton(
              icon: const Icon(Icons.search, size: 22),
              label: l10n.drawerBilibiliSearch,
              onTap: () => _openSearchPage(fromBottomBar: true),
              size: 56,
            )
          : null,
                                       
      optionalTab: searchOn
          ? GlassBottomBarTab(
              label: l10n.drawerBilibiliSearch,
              icon: Icons.search_outlined,
              selectedIcon: Icons.search,
            )
          : null,
      onOptionalTab: () => _openSearchPage(fromBottomBar: true),
    );
  }

                       
  GlassBottomBarTab _navItemTab(String id, AppLocalizations l10n) {
                                    
    return navItemTab(id, l10n);
  }

                                                     
                              
                                           
                                                       
  void _openShorts() {
                                                 
                                           
    _switchTabTo(kShortsTabIndex);
  }

  void _openSearchPage({bool fromBottomBar = false}) {
                                         
                                    
    Rect? begin;
    var radius = 19.0;
    if (fromBottomBar) {
      final box =
          _bottomBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.attached) {
        final r = box.localToGlobal(Offset.zero) & box.size;
                                                 
                      
        const d = 56.0;
        begin = Rect.fromLTWH(r.right - d, r.center.dy - d / 2, d, d);
        radius = d / 2;
      }
    } else {
      final box =
          _searchBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.attached) {
        begin = box.localToGlobal(Offset.zero) & box.size;
      }
    }
    Navigator.of(context).push(
      FrostedHeroRoute(
        page: const BilibiliSearchPage(),
        beginRect: begin,
        beginRadius: radius,
                                    
        childZoom: true,
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs, AppLocalizations l10n) {
    final isPortrait =
        !widget.embeddedInShell &&
        MediaQuery.orientationOf(context) == Orientation.portrait;
    return FrostedPanel(
      opacity: 0.75,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                                                
                                  
            if (isPortrait) _buildHomeSearchRow(l10n),
            SizedBox(
              height: kTabBarHeight,
              child: Row(
                children: [
                  if (!widget.embeddedInShell && !isPortrait) ...[
                                                    
                                                                   
                    const SizedBox(width: 12),
                                                   
                                                    
                    Builder(
                      builder: (ctx) {
                                                              
                                                                
                                                           
                                                        
                                                          
                        final route = ModalRoute.of(ctx);
                        final drawerInternal =
                            route?.willHandlePopInternally ?? false;
                        return Navigator.canPop(ctx) && !drawerInternal
                            ? _RoundIconButton(
                                icon: Icons.arrow_back,
                                tooltip: l10n.homeBack,
                                onTap: () => Navigator.of(ctx).maybePop(),
                              )
                            : SideBarEntryButton(
                                onTap: _openSideMenu,
                                menuRotation: _drawerProgress,
                              );
                      },
                    ),
                    const SizedBox(width: 4),
                  ] else if (isPortrait)
                                                  
                                                       
                                   
                    const SizedBox(width: 48),
                                               
                                                                 
                  Expanded(
                                                
                                                            
                    child: _tabController.index == kDynamicsTabIndex
                        ? NaviOvalTabRow(
                            labels: [
                              for (final t in BiliDynTab.values)
                                _dynTabLabel(l10n, t),
                            ],
                            selectedIndex: _dynamicsTabCtrl.index,
                            onTap: (index) {
                              if (index != _dynamicsTabCtrl.index) {
                                _dynamicsTabCtrl.animateTo(index);
                              }
                            },
                            height: kTabBarHeight,
                          )
                        : Center(
                                                                
                            child: LongPressGlassTabSwitcher(
                              selectedIndex: _tabController.index,
                              onIndexChanged: (index) {
                                if (index != _tabController.index) {
                                  _tabController.animateTo(index);
                                }
                              },
                              tabs: [
                                for (final i in _kOvalTabs)
                                  GlassTab(label: _ovalTabLabel(i, l10n)),
                              ],
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (final i in _kOvalTabs)
                                      _buildOvalTab(i, cs, l10n),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                                                 
                                   
                  if (isPortrait) _buildRegionEntry(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

                                           
     
                                              
                                      
                               
  Widget _buildHomeSearchRow(AppLocalizations l10n) {
    return ValueListenableBuilder<double>(
      valueListenable: _homeSearchProgress,
      builder: (context, p, child) {
        return SizedBox(
          height: kHomeSearchBarHeight * (1 - p),
          child: ClipRect(
            child: Opacity(
              opacity: 1 - p,
              child: Transform.translate(
                offset: Offset(0, -kHomeSearchBarHeight * p),
                child: child,
              ),
            ),
          ),
        );
      },
                              
      child: SizedBox(
        height: kHomeSearchBarHeight,
        child: Row(
          children: [
            const SizedBox(width: 12),
            SideBarEntryButton(
              onTap: _openSideMenu,
              menuRotation: _drawerProgress,
            ),
            const SizedBox(width: 10),
            Expanded(
                                            
              child: ValueListenableBuilder<double>(
                valueListenable: FrostedHeroRoute.backdropProgress,
                builder: (context, p, child) => Opacity(
                  opacity: (1 - p * 1.6).clamp(0.0, 1.0),
                  child: child,
                ),
                child: KeyedSubtree(
                  key: _searchBarKey,
                  child: _HomeSearchBar(
                                            
                    hint: '',
                    onTap: _openSearchPage,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
                          
            const MessageCenterIconEntry(),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

                                       
  Widget _buildRegionEntry() {
    return MorphIconButton(
      icon: Icons.grid_view_outlined,
      iconSize: 22,
      tooltip: '分区',
      transparent: true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BilibiliRegionCategoriesPage()),
      ),
    );
  }

                           
  bool get _showHomeSearchBar =>
      !widget.embeddedInShell &&
      MediaQuery.orientationOf(context) == Orientation.portrait;

                                       
             
  double get _topBarHeight =>
      kTabBarHeight +
      (_showHomeSearchBar && !_homeSearchCollapsed ? kHomeSearchBarHeight : 0);

                                           
  Widget _buildOvalTab(int index, ColorScheme cs, AppLocalizations l10n) {
    final selected = _tabController.index == index;
    final label = _ovalTabLabel(index, l10n);
    return InkWell(
      onTap: () => _onTabTap(index),
      customBorder: const StadiumBorder(),
      splashColor: cs.primary.withValues(alpha: 0.12),
      highlightColor: cs.primary.withValues(alpha: 0.08),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
                                               
                                                
          SizedBox(
            height: 19,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.0,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
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

                                 
  String _ovalTabLabel(int index, AppLocalizations l10n) {
    return switch (index) {
                                    
      1 => l10n.drawerRecommend,
      2 => l10n.recommendTabHot,
      3 => l10n.recommendTabBangumi,
      _ => _kTabLabels[index],
    };
  }

                                                 
     
                                                        
                                        
                                  
                                                                         
                             
  Widget _tabWithHeroMode(int index, Widget child) {
    return HeroMode(enabled: _tabController.index == index, child: child);
  }

                                                 
     
                                           
                                     
  Widget _buildVideoFeed<T>(
    ColorScheme cs,
    AppLocalizations l10n,
    _TabState<T> data,
    ScrollController controller, {
    required GlobalKey<RefreshIndicatorState> refreshKey,
    required Future<void> Function({bool forceRefresh, bool viaRefresh}) load,
    required String Function(T) keyOf,
    required Widget Function(ColorScheme cs, T item) gridCard,
    required Widget Function(ColorScheme cs, T item) listCard,
    Widget? header,
  }) {
    final items = data.items;
                                          
    final int? tipAt = data == _rcmd ? _rcmdSavedTipAt : null;
    return UgcSelectionArea(
      child: AppRefreshIndicator(
        refreshIndicatorKey: refreshKey,
        onRefresh: () => load(forceRefresh: true, viaRefresh: true),
        color: cs.primary,
                                                   
                                                      
                                            
        edgeOffset: context.watch<SettingsService>().refreshEdgeOffset,
        displacement:
            _topBarHeight +
            10 -
            40.0 +
            context.watch<SettingsService>().refreshDisplacement,
        child: Stack(
          children: [
            CustomScrollView(
              controller: controller,
              physics: data.loading
                  ? const NeverScrollableScrollPhysics()
                  : const AppRefreshScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
              slivers: [
                                                
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _homeSearchProgress,
                    builder: (context, p, _) => SizedBox(
                      height:
                          kTabBarHeight +
                          (_showHomeSearchBar
                              ? kHomeSearchBarHeight * (1 - p)
                              : 0),
                    ),
                  ),
                ),
                                                    
                if (header != null) SliverToBoxAdapter(child: header),
                                             
                                                         
                if (shouldShowFullScreenLoading(
                  loading: data.loading,
                  isEmpty: items.isEmpty,
                ))
                  const PageLoadingSliver()
                else if (data.error != null && items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _errorView(cs, l10n),
                  )
                else if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        l10n.recommendEmpty,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else if (!_gridMode)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Column(
                        children: [
                          for (int i = 0; i < items.length; i++) ...[
                            if (tipAt == i) _rcmdSavedTip(cs, l10n),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _FreshSlideIn(
                                isFresh: data.freshKeys.contains(
                                  keyOf(items[i]),
                                ),
                                child: listCard(cs, items[i]),
                              ),
                            ),
                          ],
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
                          data,
                          items,
                          keyOf,
                          columns,
                          items.length,
                          cellW,
                          cellH,
                        );
                                                                  
                        SliverGrid gridRange(int start, int end) => SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.78,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final index = start + i;
                              final item = items[index];
                              return ListenableBuilder(
                                listenable: _gridRowAnimCtrl,
                                builder: (context, _) {
                                  final t = Curves.easeInOut.transform(
                                    _gridRowAnimCtrl.value,
                                  );
                                  final delta = data.itemTranslations[index];
                                  Widget card = _FreshSlideIn(
                                    isFresh: data.freshKeys.contains(
                                      keyOf(item),
                                    ),
                                    child: gridCard(cs, item),
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
                                                          
                            childCount: end - start,
                            addAutomaticKeepAlives: false,
                          ),
                        );
                                                  
                                                             
                        if (tipAt != null &&
                            tipAt > 0 &&
                            tipAt < items.length) {
                          return SliverMainAxisGroup(
                            slivers: [
                              gridRange(0, tipAt),
                              SliverToBoxAdapter(
                                child: _rcmdSavedTip(cs, l10n),
                              ),
                              gridRange(tipAt, items.length),
                            ],
                          );
                        }
                        return gridRange(0, items.length);
                      },
                    ),
                  ),
                                                
                SliverToBoxAdapter(
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).padding.bottom +
                        (!widget.embeddedInShell &&
                                MediaQuery.of(context).orientation ==
                                    Orientation.portrait
                            ? 76
                            : 72),
                  ),
                ),
              ],
            ),
            FeedLoadingOverlay(
              loadingMore: data.loadingMore,
              hasMore: data.hasMore,
              bottomOffset: _feedOverlayBottom(context),
            ),
          ],
        ),
      ),
    );
  }

                                          
                                                      
  double _feedOverlayBottom(BuildContext context) {
    final hasBottomBar =
        !widget.embeddedInShell &&
        MediaQuery.of(context).orientation == Orientation.portrait;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return (hasBottomBar ? 60 : 0) + safeBottom + 16;
  }

                             
                                                                         
                                   
                                    
                                   
  static const List<({String title, IconData icon, BiliPopularListKind kind})>
  _kHotEntranceFallback = [
    (
      title: '排行榜',
      icon: Icons.leaderboard_rounded,
      kind: BiliPopularListKind.ranking,
    ),
    (
      title: '每周必看',
      icon: Icons.calendar_view_week_rounded,
      kind: BiliPopularListKind.weekly,
    ),
    (
      title: '入站必刷',
      icon: Icons.auto_awesome_rounded,
      kind: BiliPopularListKind.precious,
    ),
  ];

                                      
                
  Widget _buildHotHeader(ColorScheme cs, AppLocalizations l10n) {
    final entrances = _hotEntrances;
    final useCloud = entrances.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                     
          if (useCloud)
                                           
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entrances.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _hotEntryCloud(cs, entrances[i]),
              ),
            )
          else
                               
            Row(
              children: [
                for (final e in _kHotEntranceFallback) ...[
                  if (e != _kHotEntranceFallback.first)
                    const SizedBox(width: 10),
                  Expanded(
                    child: _hotEntry(
                      cs,
                      icon: e.icon,
                      text: e.title,
                      onTap: () => _openPopularList(e.kind),
                    ),
                  ),
                ],
              ],
            ),
                                               
          if (_hotwords.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() {
                _hotSearchExpanded = !_hotSearchExpanded;
              }),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '相关搜索',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _hotSearchExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (_hotSearchExpanded) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final word in _hotwords)
                    ActionChip(
                      label: Text(word),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                BilibiliSearchPage(initialKeyword: word),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

                                    
                              
  Future<void> _loadHotEntrances() async {
    if (_hotEntrancesLoaded) return;
    final items = await BilibiliHotService.fetchHotEntrances();
    if (!mounted || items.isEmpty) return;
    setState(() {
      _hotEntrances = items;
      _hotEntrancesLoaded = true;
    });
  }

                                         
  Widget _hotEntryCloud(ColorScheme cs, BiliHotEntrance entrance) {
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    final iconUrl = entrance.icon.startsWith('//')
        ? 'https:${entrance.icon}'
        : entrance.icon;
    return SizedBox(
      width: 72,
      child: Material(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openHotEntrance(entrance),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: Image(
                      image: CachedImageProvider(iconUrl, headers: headers),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  entrance.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

                                       
                             
  void _openHotEntrance(BiliHotEntrance entrance) {
    final uri = entrance.uri;
    if (uri.startsWith('bilibili://rank')) {
      _openPopularList(BiliPopularListKind.ranking);
    } else if (entrance.title == '每周必看') {
      _openPopularList(BiliPopularListKind.weekly);
    } else if (entrance.title == '入站必刷') {
      _openPopularList(BiliPopularListKind.precious);
    } else if (uri.isNotEmpty) {
      openLinkInBuiltInBrowser(context, url: uri, confirm: false);
    }
  }

                                                       
                                               
                                         
  Widget _hotEntry(
    ColorScheme cs, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, size: 24, color: cs.primary),
              const SizedBox(height: 4),
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

                              
  void _openPopularList(BiliPopularListKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BilibiliPopularListPage(kind: kind)),
    );
  }

                               
  Widget _buildBangumiFeed(ColorScheme cs, AppLocalizations l10n) {
    final data = _bangumi;
    final items = data.items;
    return UgcSelectionArea(
      child: AppRefreshIndicator(
        refreshIndicatorKey: _feedRefreshKeys[3],
        onRefresh: () => _loadBangumi(forceRefresh: true, viaRefresh: true),
        color: cs.primary,
                                                   
                                                 
        edgeOffset: context.watch<SettingsService>().refreshEdgeOffset,
        displacement:
            _topBarHeight +
            10 -
            40.0 +
            context.watch<SettingsService>().refreshDisplacement,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _bangumiScroll,
              physics: data.loading
                  ? const NeverScrollableScrollPhysics()
                  : const AppRefreshScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
              slivers: [
                                                
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _homeSearchProgress,
                    builder: (context, p, _) => SizedBox(
                      height:
                          kTabBarHeight +
                          (_showHomeSearchBar
                              ? kHomeSearchBarHeight * (1 - p)
                              : 0),
                    ),
                  ),
                ),
                                               
                SliverToBoxAdapter(child: _bangumiEntryRow(cs)),
                                             
                                                         
                if (shouldShowFullScreenLoading(
                  loading: data.loading,
                  isEmpty: items.isEmpty,
                ))
                  const PageLoadingSliver()
                else if (data.error != null && items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _errorView(cs, l10n),
                  )
                else if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        l10n.recommendEmpty,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else ...[
                                                              
                                                      
                  SliverToBoxAdapter(
                    child: _bangumiBanners.isEmpty
                        ? SizedBox(key: _bangumiCarouselKey, height: 0)
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                            child: _bangumiCarousel(cs, _bangumiBanners),
                          ),
                  ),
                                
                  if (_bangumiRankItems.isNotEmpty)
                    SliverToBoxAdapter(child: _buildBangumiRank(cs, l10n)),
                                           
                                                 
                  SliverToBoxAdapter(child: _buildBangumiTimeline(cs)),
                                  
                  if (_bangumiContinueItems.isNotEmpty)
                    SliverToBoxAdapter(child: _buildBangumiContinue(cs, l10n)),
                  if (!_gridMode)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Column(
                          children: [
                            for (final item in items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _FreshSlideIn(
                                  isFresh: data.freshKeys.contains(
                                    item.seasonId.toString(),
                                  ),
                                  child: _bangumiListCard(cs, item),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          final columns = (width / 160).floor().clamp(
                            kVideoCardMinColumns,
                            6,
                          );
                          final cardW = (width - (columns - 1) * 12) / columns;
                          final cellW = cardW + 12;
                                                          
                          final cellH = cardW * 4 / 3 + 84 + 12;
                          _checkGridLayoutChange(
                            data,
                            items,
                            (v) => v.seasonId.toString(),
                            columns,
                            items.length,
                            cellW,
                            cellH,
                          );
                          return SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: cardW / cellH,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final item = items[i];
                                return ListenableBuilder(
                                  listenable: _gridRowAnimCtrl,
                                  builder: (context, _) {
                                    final t = Curves.easeInOut.transform(
                                      _gridRowAnimCtrl.value,
                                    );
                                    final delta = data.itemTranslations[i];
                                    Widget card = _FreshSlideIn(
                                      isFresh: data.freshKeys.contains(
                                        item.seasonId.toString(),
                                      ),
                                      child: _bangumiGridCard(cs, item),
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
                                                            
                              childCount: items.length,
                              addAutomaticKeepAlives: false,
                            ),
                          );
                        },
                      ),
                    ),
                ],
                                                
                SliverToBoxAdapter(
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).padding.bottom +
                        (!widget.embeddedInShell &&
                                MediaQuery.of(context).orientation ==
                                    Orientation.portrait
                            ? 76
                            : 72),
                  ),
                ),
              ],
            ),
            FeedLoadingOverlay(
              loadingMore: data.loadingMore,
              hasMore: data.hasMore,
              bottomOffset: _feedOverlayBottom(context),
            ),
          ],
        ),
      ),
    );
  }

                                             
                                               
                                             

                               
     
                             
  Future<void> _loadTimeline() async {
    setState(() => _timelineLoading = true);
    final days = await BilibiliBangumiService.fetchTimeline();
    if (!mounted) return;
    final todayIdx = days.indexWhere((d) => d.isToday);
    final target = todayIdx < 0 ? 0 : todayIdx;
    setState(() {
      _timelineLoading = false;
      _timelineLoaded = true;
      _timeline = days;
      _timelineDayIndex = target;
    });
                                                          
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_timelinePageCtrl.hasClients) return;
      if (_timelinePageCtrl.page?.round() != target) {
        _timelinePageCtrl.jumpToPage(target);
      }
    });
  }

  static const List<String> _timelineWeekNames = [
    '',
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

                                             
  Widget _buildBangumiTimeline(ColorScheme cs) {
    if (_timeline.isEmpty) {
      if (!_timelineLoading) return const SizedBox.shrink();
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final idx = _timelineDayIndex.clamp(0, _timeline.length - 1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: Row(
              children: [
                Text(
                  '追番时间表',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                _sectionMoreArrow(
                  tooltip: '查看完整时间表',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BilibiliBangumiTimelinePage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
                               
          UnderlineTabRow(
            labels: [
              for (final d in _timeline)
                d.isToday
                    ? '${d.date} 今天'
                    : '${d.date} ${_timelineWeekNames[d.dayOfWeek.clamp(1, 7)]}',
            ],
            selectedIndex: idx,
            onSelected: (i) {
              if (i == _timelineDayIndex) return;
              setState(() => _timelineDayIndex = i);
              if (_timelinePageCtrl.hasClients) {
                _timelinePageCtrl.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              }
            },
            height: 44,
            fontSize: 13.5,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 206,
                                            
                                    
            child: PageView.builder(
              controller: _timelinePageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _timeline.length,
              onPageChanged: (i) {
                if (i != _timelineDayIndex) {
                  setState(() => _timelineDayIndex = i);
                }
              },
              itemBuilder: (context, pageIndex) {
                final d = _timeline[pageIndex];
                if (d.episodes.isEmpty) {
                  return Center(
                    child: Text(
                      '当天没有更新',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: d.episodes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) =>
                      _TimelineCard(item: d.episodes[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

                                        
  Widget _sectionMoreArrow({
    required VoidCallback onTap,
    required String tooltip,
  }) {
    final cs = Theme.of(context).colorScheme;
    return AppTooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

                                        
                               
  Widget _bangumiEntryRow(ColorScheme cs) {
    void openIndex() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BilibiliBangumiIndexPage()),
      );
    }

    void openWatching() {
      if (!BilibiliAccountService.instance.isLoggedIn) {
        showAppToast(context, '登录后可查看追番进度');
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BilibiliBangumiWatchingPage()),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _bangumiEntryButton(
              cs,
              icon: Icons.grid_view_outlined,
              label: '番剧索引',
              onTap: openIndex,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _bangumiEntryButton(
              cs,
              icon: Icons.visibility_outlined,
              label: '正在追',
              onTap: openWatching,
            ),
          ),
        ],
      ),
    );
  }

                                           
  Widget _bangumiEntryButton(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: cs.primary),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

                                                    
                                               
                        
  Widget _bangumiCarousel(ColorScheme cs, List<BiliBangumiBannerItem> banners) {
    if (banners.isEmpty) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;
    final viewport = width - 32;
    final weights = _kBangumiCarouselWeights;
    final sum = weights[0] + weights[1] + weights[2];
                                
    final middleExtent = viewport * weights[1] / sum;
    final height = middleExtent * 9 / 16;
    _bangumiCarouselStep = viewport * weights[0] / sum;
    return SizedBox(
      key: _bangumiCarouselKey,
      height: height,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
                              
          if (n is ScrollStartNotification && n.dragDetails != null) {
            _bangumiCarouselTimer?.cancel();
          } else if (n is ScrollEndNotification) {
            _startBangumiCarouselAutoPlay();
          }
          return false;
        },
        child: CarouselView.weighted(
          controller: _bangumiCarouselCtrl,
          flexWeights: weights,
          itemSnapping: true,
          consumeMaxWeight: false,
          infinite: true,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(
                                               
            borderRadius: BorderRadius.circular(28),
          ),
          itemClipBehavior: Clip.antiAlias,
          onTap: (i) => _openBangumiBanner(banners[i % banners.length]),
          children: [
            for (final item in banners) _bangumiCarouselCard(cs, item),
          ],
        ),
      ),
    );
  }

                                           
  Widget _buildBangumiRank(ColorScheme cs, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '热门榜单',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              _sectionMoreArrow(
                tooltip: '查看全部番剧',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BilibiliBangumiIndexPage(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _bangumiRankItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final item = _bangumiRankItems[i];
                return GestureDetector(
                  onTap: () =>
                      _openBangumiSimple(item.seasonId, item.title, item.cover),
                  child: SizedBox(
                    width: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                    
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _coverImage(
                                item.cover,
                                width: 100,
                                height: 132,
                              ),
                            ),
                            Positioned(
                              left: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: i == 0
                                      ? const Color(0xFFFB7299)
                                      : Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (item.newEpShow.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.newEpShow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

                                       
                  
  Widget _buildBangumiContinue(ColorScheme cs, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '继续观看',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _bangumiContinueItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final item = _bangumiContinueItems[i];
                return GestureDetector(
                  onTap: () =>
                      _openBangumiSimple(item.seasonId, item.title, item.cover),
                  child: SizedBox(
                    width: 132,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                     
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 132,
                            height: 132,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _coverImage(item.cover, aspect: 1),
                                             
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: 3,
                                    color: Colors.white24,
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: (item.progressPercent / 100)
                                          .clamp(0.0, 1.0),
                                      child: const ColoredBox(
                                        color: Color(0xFFFB7299),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                        if (item.desc.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.3,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

                                           
  void _openBangumiSimple(int seasonId, String title, String cover) {
    FocusManager.instance.primaryFocus?.unfocus();
    openBilibiliBangumi(
      context,
      seasonId: seasonId,
      initialTitle: title,
      initialCover: cover,
    );
  }

                         
                                        
                                              
                                            
  Widget _bangumiCarouselCard(ColorScheme cs, BiliBangumiBannerItem item) {
    final hasBg = item.bgImg.isNotEmpty;
    final hasCoverText = item.cover.isNotEmpty;
    final card = LayoutBuilder(
      builder: (context, constraints) {
        final titleHeight = constraints.maxHeight * 0.275;
        return Stack(
          fit: StackFit.expand,
          children: [
                                         
            _coverImage(hasBg ? item.bgImg : item.cover, aspect: 16 / 9),
                     
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.62),
                  ],
                ),
              ),
            ),
                                          
            if (hasCoverText && hasBg)
              Positioned(
                left: 12,
                right: 12,
                bottom: 25,
                child: _bannerTitleOverlay(item.cover, titleHeight),
              ),
                                            
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasCoverText && item.title.isNotEmpty)
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 6),
                        ],
                      ),
                    ),
                  if (item.subTitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
                                                       
                                           
    if (item.seasonId <= 0) return card;
    return Hero(
      transitionOnUserGestures: true,
      tag: 'bili_bangumi_banner_${item.seasonId}',
      child: card,
    );
  }

                                               
                             
  Widget _bannerTitleOverlay(String url, double height) {
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    final normalized = url.startsWith('//') ? 'https:$url' : url;
    return Center(
      child: SizedBox(
        height: height,
        child: Image(
          image: CachedImageProvider(normalized, headers: headers),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

                               
  void _checkGridLayoutChange<T>(
    _TabState<T> data,
    List<T> items,
    String Function(T) keyOf,
    int cols,
    int count,
    double cellW,
    double cellH,
  ) {
    if (items.isEmpty) return;
    if (data.prevCols == 0) {
      data.prevCols = cols;
      data.prevCount = count;
      data.prevFirstKey = keyOf(items[0]);
      return;
    }
    if (data.prevCols == cols && data.prevCount == count) return;
    if (count == 0 || data.prevCount == 0) {
      data.prevCols = cols;
      data.prevCount = count;
      data.prevFirstKey = keyOf(items[0]);
      return;
    }

    final oldCols = data.prevCols;
    final newCols = cols;
    final minCount = data.prevCount < count ? data.prevCount : count;
    final newFirstKey = keyOf(items[0]);

                       
    if (data.prevFirstKey != null && data.prevFirstKey != newFirstKey) {
      data.itemTranslations.clear();
      data.prevCols = cols;
      data.prevCount = count;
      data.prevFirstKey = newFirstKey;
      return;
    }

    data.itemTranslations.clear();
    bool anyMoved = false;
    for (int i = 0; i < minCount; i++) {
      final oldRow = i ~/ oldCols;
      final oldCol = i % oldCols;
      final newRow = i ~/ newCols;
      final newCol = i % newCols;
      if (oldRow != newRow || oldCol != newCol) {
        anyMoved = true;
        data.itemTranslations[i] = Offset(
          (oldCol - newCol) * cellW,
          (oldRow - newRow) * cellH,
        );
      }
    }

    data.prevCols = cols;
    data.prevCount = count;
    data.prevFirstKey = newFirstKey;

    if (anyMoved) {
                                                  
                                                         
                                                             
                           
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _gridRowAnimCtrl.reset();
        _gridRowAnimCtrl.forward();
      });
    }
  }

                                                       
                                                            

  Widget _errorView(ColorScheme cs, AppLocalizations l10n) {
    return Center(
      child: Text(
        _lastError ?? l10n.biliLoadFailed,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
    );
  }

  String? get _lastError => BilibiliRecommendService.lastErrorDetail;

                                              
        
                                              

                            
                                                       
                                     
  Widget _gridCard(ColorScheme cs, BiliRecommendItem item) {
    return VideoCardV(
      data: VideoCardData(
        cover: item.cover,
        title: _titleFor(item),
        heroTag: 'bili_video_${item.bvid}',
        view: item.view,
        danmaku: item.danmaku,
        duration: item.duration,
        reason: item.rcmdReason,
        ownerName: item.ownerName,
        pubdate: item.pubdate,
      ),
      onTap: () => _open(item),
      onLongPress: () => _showLongPressMenu(item),
      onSecondaryTap: (pos) => _showContextMenu(item, pos),
    );
  }

                                                        
  Widget _listCard(ColorScheme cs, BiliRecommendItem item) {
    return VideoCardH(
      data: VideoCardData(
        cover: item.cover,
        title: _titleFor(item),
        heroTag: 'bili_video_${item.bvid}',
        view: item.view,
        danmaku: item.danmaku,
        duration: item.duration,
        reason: item.rcmdReason,
        ownerName: item.ownerName,
        pubdate: item.pubdate,
      ),
      onTap: () => _open(item),
      onLongPress: () => _showLongPressMenu(item),
      onSecondaryTap: (pos) => _showContextMenu(item, pos),
    );
  }

                                    
                                  
  void _showBangumiLongPressMenu(BiliBangumiItem item) {
    final subtitle = [
      if (item.indexShow.isNotEmpty) item.indexShow,
      if (item.score.isNotEmpty) '${item.score} 分',
    ].join(' · ');
    showCoverMenuBottomSheet(
      context,
      cover: item.cover,
      title: item.title,
      subtitle: subtitle,
      heroTag: 'bili_bangumi_${item.seasonId}',
      actions: [
        (
          icon: Icons.play_circle_outline,
          text: '应用内播放',
          onTap: () {
            Navigator.of(context).pop();
            _openBangumi(item);
          },
        ),
        (
          icon: Icons.tag_outlined,
          text: '复制SS号',
          onTap: () {
            Navigator.of(context).pop();
            _copyText('ss${item.seasonId}');
          },
        ),
        (
          icon: Icons.link,
          text: '复制番剧链接',
          onTap: () {
            Navigator.of(context).pop();
            _copyText(
              'https://www.bilibili.com/bangumi/play/ss${item.seasonId}',
            );
          },
        ),
      ],
    );
  }

                                                       
                                                  
                                           
  Widget _bangumiGridCard(ColorScheme cs, BiliBangumiItem item) {
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
          headers: NetworkSettingsService.instance.apiHeaders.isEmpty
              ? null
              : NetworkSettingsService.instance.apiHeaders,
          fit: BoxFit.cover,
          aspect: 3 / 4,
          maxDimension: 480,
        ),
      ),
      onTap: () => _openBangumi(item),
      onLongPress: () => _showBangumiLongPressMenu(item),
      onSecondaryTap: (pos) => _showBangumiMenu(item, pos),
    );
  }

                                                   
                                            
                               
  Widget _bangumiListCard(ColorScheme cs, BiliBangumiItem item) {
    final glassOn = SettingsService.videoCardGlassEnabled;
    Widget thumb = _coverImage(item.cover, width: 100, height: 133);
                                                 
                            
    if (!SettingsService.heroTransitionBlurEnabled) {
      thumb = Hero(
        transitionOnUserGestures: true,
        tag: 'bili_bangumi_${item.seasonId}',
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: thumb,
      );
    }
    final card = Material(
                                   
                                
      color: glassOn ? Colors.transparent : cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onLongPress: () => _showBangumiLongPressMenu(item),
        child: InkWell(
          onTap: () => _openBangumi(item),
          onSecondaryTapDown: (d) => _showBangumiMenu(item, d.globalPosition),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                thumb,
                const SizedBox(width: 12),
                Expanded(
                  child: videoCardInfoGlass(
                    context,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                        if (item.score.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '评分 ${item.score}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: cs.primary),
                          ),
                        ],
                        if (item.indexShow.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.indexShow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (item.badge.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: cs.errorContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.badge,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onErrorContainer,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
                                             
                     
    if (SettingsService.heroTransitionBlurEnabled) {
      return MetroTileInteraction(
        onTapStart: (_, __) {},
        showBorder: false,
        child: Hero(
          transitionOnUserGestures: true,
          tag: 'bili_bangumi_${item.seasonId}',
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
    return width != null && height != null
        ? SizedBox(width: width, height: height, child: img)
        : AspectRatio(aspectRatio: aspect, child: img);
  }

  String _fmtCount(int n) {
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
}

                                                
                          
class _LazyKeepAliveTab extends StatefulWidget {
  final Future<void> Function()? onFirstBuild;
  final Widget child;

  const _LazyKeepAliveTab({this.onFirstBuild, required this.child});

  @override
  State<_LazyKeepAliveTab> createState() => _LazyKeepAliveTabState();
}

class _LazyKeepAliveTabState extends State<_LazyKeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
                                   
                                             
                                                     
    final load = widget.onFirstBuild;
    if (load != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => load());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

                                
                     
                                          
                                   
              
                                       
class _HomeSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback onTap;

  const _HomeSearchBar({required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 38,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

                                             
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppTooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 22),
        color: cs.onSurface,
        onPressed: onTap,
      ),
    );
  }
}

                                           
                                    
class _FreshSlideIn extends StatefulWidget {
  final bool isFresh;
  final Widget child;

  const _FreshSlideIn({required this.isFresh, required this.child});

  @override
  State<_FreshSlideIn> createState() => _FreshSlideInState();
}

class _FreshSlideInState extends State<_FreshSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    if (widget.isFresh) {
                           
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isFresh) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: FractionalTranslation(translation: _slide.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

                                           
                         
                                           

                                          
class _TimelineCard extends StatelessWidget {
  final BiliTimelineEpisode item;

  const _TimelineCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 108,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: item.seasonId > 0
            ? () => openBilibiliBangumi(
                context,
                seasonId: item.seasonId,
                initialTitle: item.title,
                initialCover: item.cover,
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.cover.isEmpty
                        ? Container(color: cs.surfaceContainerHighest)
                        : Image(
                            image: CachedImageProvider(item.cover),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: cs.surfaceContainerHighest),
                          ),
                    if (item.pubTime.isNotEmpty)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.66),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            item.pubTime,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (item.follow == 1)
                      Positioned(
                        left: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            '已追番',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            if (item.pubIndex.isNotEmpty)
              Text(
                item.pubIndex,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
