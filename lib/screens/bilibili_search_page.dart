                                        
  
                                                   
                                    
                                     
                                          
                             
                                             
                                
                                  
                          
                                                  
                                                                  
                                             
                                    
import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/screens/article_page.dart';
import 'package:naviflash/screens/bilibili_audio_song_page.dart';
import 'package:naviflash/screens/bilibili_bangumi_page.dart';
import 'package:naviflash/screens/bilibili_hot_search_page.dart';
import 'package:naviflash/screens/bilibili_live_room_page.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/screens/geetest_dialog.dart';
import 'package:naviflash/services/bilibili_search_history.dart';
import 'package:naviflash/services/bilibili_audio_zone_service.dart'
    show AudioZoneSong;
import 'package:naviflash/services/bilibili_search_service.dart';
import 'package:naviflash/widgets/app_tooltip.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/services/bilibili_search_cache.dart';
import 'package:naviflash/services/bilibili_translate_api.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/taskbar_progress_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/navi_oval_tab_row.dart';
import 'package:naviflash/widgets/lazy_cover_image.dart';
import 'package:naviflash/widgets/metro_tile.dart';
import 'package:naviflash/widgets/widgets.dart';
import 'package:naviflash/widgets/ugc_selection_area.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'browser_page.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/navi_spring_physics.dart';
import 'package:naviflash/widgets/video_card.dart';
import 'package:naviflash/widgets/page_loading.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

                                            
              
                                            

                                        
const double kSearchBarHeight = 60.0;

              
const double kSearchTabBarHeight = 48.0;

                                            
                                            

                                       
const List<String> kPubTimeOptions = ['不限', '最近一天', '最近一周', '最近半年'];

                                                   
const List<String> kDurationOptions = [
  '全部时长',
  '0-10分钟',
  '10-30分钟',
  '30-60分钟',
  '60分钟+',
];

                        
const List<({String label, int tids})> kZoneOptions = [
  (label: '全部', tids: 0),
  (label: '动画', tids: 1),
  (label: '番剧', tids: 13),
  (label: '国创', tids: 167),
  (label: '音乐', tids: 3),
  (label: '舞蹈', tids: 129),
  (label: '游戏', tids: 4),
  (label: '知识', tids: 36),
  (label: '科技', tids: 188),
  (label: '运动', tids: 234),
  (label: '汽车', tids: 223),
  (label: '生活', tids: 160),
  (label: '美食', tids: 221),
  (label: '动物', tids: 217),
  (label: '鬼畜', tids: 119),
  (label: '时尚', tids: 115),
  (label: '资讯', tids: 202),
  (label: '娱乐', tids: 5),
  (label: '影视', tids: 181),
  (label: '记录', tids: 177),
  (label: '电影', tids: 23),
  (label: '电视', tids: 11),
];

             
class _FilterState {
  int pubTime = 0;                            
  int duration = 0;                       
  int zone = 0;                

                                            
  int? customBegin;
  int? customEnd;

  bool antiFuzzy = false;                              

                                       
  bool keywordFilter = false;

                         
  int get activeCount =>
      (pubTime != 0 ? 1 : 0) +
      ((customBegin != null || customEnd != null) ? 1 : 0) +
      (duration != 0 ? 1 : 0) +
      (zone != 0 ? 1 : 0) +
      (antiFuzzy ? 1 : 0) +
      (keywordFilter ? 1 : 0);
}

                
class _TypeData {
  final List<BiliSearchItem> items = [];
  int numResults = 0;
  int page = 0;
  bool loaded = false;
  bool loading = false;
  bool loadingMore = false;

                                         
                                             
  bool refreshing = false;
  bool hasMore = true;
  String? error;

                                       
  final Set<int> freshInsertIds = {};

  void reset() {
    items.clear();
    numResults = 0;
    page = 0;
    loaded = false;
    loading = false;
    loadingMore = false;
    refreshing = false;
    hasMore = true;
    error = null;
    freshInsertIds.clear();
  }
}

class BilibiliSearchPage extends StatefulWidget {
  final String initialKeyword;

                                          
                                               
                             
  final bool recordInitialKeyword;

                                         
                           
  final bool embeddedInShell;

  const BilibiliSearchPage({
    super.key,
    this.initialKeyword = '',
    this.recordInitialKeyword = true,
    this.embeddedInShell = false,
  });

  @override
  State<BilibiliSearchPage> createState() => _BilibiliSearchPageState();
}

class _BilibiliSearchPageState extends State<BilibiliSearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _keywordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _suggestDebounce;
  late final TabController _tabController;

  String _activeKeyword = '';           
  String? _gaiaVtoken;                           
  bool _captchaRunning = false;

                                          
                                 
  bool _skipNextRecord = false;

                                      
  final Map<String, String> _videoTitleOverrides = {};

                       
  final _FilterState _filters = _FilterState();

                                           
  static final int _antiFuzzyBegin =
      DateTime(2009, 6, 26).millisecondsSinceEpoch ~/ 1000;

  final Map<BiliSearchType, _TypeData> _data = {};

                                      
  final Map<BiliSearchType, ScrollController> _scrollControllers = {};

                                         
                                      
  final Map<BiliSearchType, GlobalKey<RefreshIndicatorState>>
  _resultRefreshKeys = {};

                                        
  bool _gridMode = true;

                
  void _toggleGridMode() {
    setState(() => _gridMode = !_gridMode);
  }

         
  List<BiliSearchSuggest> _suggests = [];

  final Map<BiliSearchType, List<String>> _histories = {};

                                             
  List<BiliHotSearchItem> _trendingItems = const [];
  bool _trendingLoading = true;
  String? _trendingError;

  List<BiliHotSearchItem> _rcmdItems = const [];
  bool _rcmdLoading = true;
  String? _rcmdError;

                         
  Future<void> _loadTrending({bool forceRefresh = false}) async {
    if (forceRefresh && mounted) {
      setState(() {
        _trendingLoading = true;
        _trendingError = null;
      });
    }
    final res = await BilibiliSearchService.searchTrending(
      limit: 10,
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;
    setState(() {
      _trendingLoading = false;
      switch (res) {
        case BiliHotSearchOk(:final items):
          _trendingItems = items;
          _trendingError = null;
        case BiliHotSearchFail(:final detail):
          _trendingError = detail;
      }
    });
  }

                                    
  Future<void> _loadRcmd({bool forceRefresh = false}) async {
    if (forceRefresh && mounted) {
      setState(() {
        _rcmdLoading = true;
        _rcmdError = null;
      });
    }
    final res = await BilibiliSearchService.searchRcmd(
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;
    setState(() {
      _rcmdLoading = false;
      switch (res) {
        case BiliHotSearchOk(:final items):
          _rcmdItems = items;
          _rcmdError = null;
        case BiliHotSearchFail(:final detail):
          _rcmdError = detail;
      }
    });
  }

                     
  void _openHotSearchPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BilibiliHotSearchPage()));
  }

                                 
  void _recordHistory(BiliSearchType type, String keyword) {
    final term = keyword.trim();
    if (term.isEmpty) return;
    final list = (_histories[type] ?? []).toList()
      ..remove(term)
      ..insert(0, term);
    setState(
      () => _histories[type] = list
          .take(BilibiliSearchHistory.maxLength)
          .toList(),
    );
    BilibiliSearchHistory.persist(type, _histories[type]!);
  }

                               
  void _onHistoryTap(String keyword) {
    _suggestDebounce?.cancel();
    _keywordController.text = keyword;
    setState(() => _suggests = []);
    _submitSearch();
  }

                       
  void _onHistoryLongPress(String keyword) {
    final type = _currentType;
    final list = (_histories[type] ?? []).toList()..remove(keyword);
    setState(() => _histories[type] = list);
    BilibiliSearchHistory.persist(type, list);
  }

                       
  void _clearHistory() {
    final type = _currentType;
    final l10n = AppLocalizations.of(context);
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.searchHistoryClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.searchHistoryClear),
          ),
        ],
      ),
    ).then((ok) {
      if (ok != true || !mounted) return;
      setState(() => _histories[type] = []);
      BilibiliSearchHistory.clear(type);
    });
  }

                                       

                                      
                                  
                                         
  final ValueNotifier<double> _topProgress = ValueNotifier<double>(0.0);

                  
  static const double kCollapseScrollDistance = 120.0;

                               
                                        
  void _onResultsScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return;
    final metrics = notification.metrics;
    final delta = notification.scrollDelta ?? 0;
    if (delta == 0) return;
    var p = _topProgress.value + delta / kCollapseScrollDistance;
                   
    if (metrics.pixels <= 0) p = 0.0;
    p = p.clamp(0.0, 1.0);
    if ((p - _topProgress.value).abs() > 0.0005) {
      _topProgress.value = p;
    }
  }

  BiliSearchType get _currentType =>
      BiliSearchType.values[_tabController.index];

  @override
  void initState() {
    super.initState();
    _keywordController.text = widget.initialKeyword;
    for (final type in BiliSearchType.values) {
      _data[type] = _TypeData();
      _scrollControllers[type] = ScrollController();
      _resultRefreshKeys[type] = GlobalKey<RefreshIndicatorState>();
    }
    _tabController = TabController(
      length: BiliSearchType.values.length,
      vsync: this,
    )..addListener(_onTabChanged);
                               
    _keywordController.addListener(() {
      if (mounted) setState(() {});
    });
    if (widget.initialKeyword.isNotEmpty) {
                              
      if (!widget.recordInitialKeyword) {
        _skipNextRecord = true;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _submitSearch());
    }
                  
    _loadHistories();
  }

                                      
                         
  bool _trendingRequested = false;
  bool _rcmdRequested = false;

                                       
                                                           
  static bool _readSwitch(
    BuildContext context,
    bool Function(SettingsService s) read,
    bool fallback,
  ) {
    try {
      return read(context.watch<SettingsService>());
    } catch (_) {
      return fallback;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bool trendingOn = SettingsService.searchTrendingEnabledStatic;
    bool rcmdOn = SettingsService.searchRcmdEnabledStatic;
    try {
      final s = context.read<SettingsService>();
      trendingOn = s.searchTrendingEnabled;
      rcmdOn = s.searchRcmdEnabled;
    } catch (_) {
                                 
    }
    if (trendingOn && !_trendingRequested) {
      _trendingRequested = true;
      _loadTrending();
    }
    if (rcmdOn && !_rcmdRequested) {
      _rcmdRequested = true;
      _loadRcmd();
    }
  }

  Future<void> _loadHistories() async {
    for (final type in BiliSearchType.values) {
      _histories[type] = await BilibiliSearchHistory.load(type);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _suggestDebounce?.cancel();
    _tabController.dispose();
    _focusNode.dispose();
    _keywordController.dispose();
    for (final c in _scrollControllers.values) {
      c.dispose();
    }
    _topProgress.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
                                               
                                            
    final type = _currentType;
    _ensureLoaded(type);
    setState(() {});
  }

                         
  void _onKeywordChanged(String value) {
    _suggestDebounce?.cancel();
    final term = value.trim();
    if (term.isEmpty) {
      setState(() => _suggests = []);
      return;
    }
    _suggestDebounce = Timer(const Duration(milliseconds: 200), () async {
      final list = await BilibiliSearchService.searchSuggest(term);
      if (!mounted) return;
                     
      if (_keywordController.text.trim() != term) return;
      setState(() => _suggests = list);
    });
  }

                       
  void _onSuggestTap(BiliSearchSuggest suggest) {
    _suggestDebounce?.cancel();
    _keywordController.text = suggest.keyword;
    setState(() => _suggests = []);
    _submitSearch();
  }

                                    
                                      
              
  void _onClearKeyword() {
    _suggestDebounce?.cancel();
    if (_activeKeyword.isNotEmpty) {
      _resetToHomeState();
      return;
    }
    _keywordController.clear();
    setState(() => _suggests = []);
    _focusNode.requestFocus();
  }

                                   
                                  
  void _resetToHomeState() {
    _suggestDebounce?.cancel();
    setState(() {
      _activeKeyword = '';
      _suggests = [];
      _keywordController.clear();
      _topProgress.value = 0.0;
      for (final data in _data.values) {
        data.reset();
      }
    });
    _focusNode.requestFocus();
  }

                           
  Future<void> _submitSearch() async {
    final keyword = _keywordController.text.trim();
    if (keyword.isEmpty) return;
    _suggestDebounce?.cancel();
    setState(() => _suggests = []);
    FocusScope.of(context).unfocus();
    setState(() {
      _activeKeyword = keyword;
      _topProgress.value = 0.0;
      _videoTitleOverrides.clear();
      for (final data in _data.values) {
        data.reset();
      }
    });
    _ensureLoaded(_currentType);
                                   
    final sc = _scrollControllers[_currentType];
    if (sc != null && sc.hasClients) sc.jumpTo(0);
                                       
    if (_skipNextRecord) {
      _skipNextRecord = false;
    } else {
      _recordHistory(_currentType, keyword);
    }
  }

  void _ensureLoaded(BiliSearchType type) {
    if (_activeKeyword.isEmpty) return;
    final data = _data[type]!;
    if (data.loading || data.loadingMore) return;
    if (!data.loaded) {
      _loadType(type, refresh: true);
    }
  }

                                            
                              
                                                                    
                                                
  static String _itemKey(BiliSearchItem e) {
    if (e.bvid.isNotEmpty) return '${e.type.code}:bvid:${e.bvid}';
    if (e.type == BiliSearchType.biliUser && e.mid > 0) {
      return '${e.type.code}:mid:${e.mid}';
    }
    if (e.id > 0) return '${e.type.code}:id:${e.id}';
    return '${e.type.code}:url:${e.actionUrl}';
  }

               
                                                      
                                
                                              
                                                    
                                 
  Future<void> _loadType(
    BiliSearchType type, {
    bool refresh = false,
    bool keepItems = false,
    bool reloadFirst = false,
  }) {
    return TaskbarProgress.track<void>(
      Object(),
      () => _loadTypeImpl(
        type,
        refresh: refresh,
        keepItems: keepItems,
        reloadFirst: reloadFirst,
      ),
    );
  }

  Future<void> _loadTypeImpl(
    BiliSearchType type, {
    bool refresh = false,
    bool keepItems = false,
    bool reloadFirst = false,
  }) async {
    if (_activeKeyword.isEmpty) return;
    final data = _data[type]!;
    if (data.loading || data.loadingMore || data.refreshing) return;

    final keyword = _activeKeyword;
                                         
    if (refresh && !keepItems) {
      final cached = await BilibiliSearchCache.load(
        BilibiliSearchCache.keyFor(
          keyword: keyword,
          type: type,
          filterKey: _searchFilterKey(),
        ),
      );
      if (cached != null && mounted && keyword == _activeKeyword) {
        setState(() {
          data.items
            ..clear()
            ..addAll(cached.items);
          data.numResults = cached.numResults;
          data.page = cached.page;
          data.hasMore = cached.hasMore;
          data.loading = false;
          data.loadingMore = false;
          data.error = null;
          data.loaded = true;
        });
        if (type == BiliSearchType.video) _translateVideoTitles(type);
        return;
      }
    }
    if (refresh) {
      if (keepItems) {
                                             
                                             
                                           
        data.refreshing = true;
      } else if (reloadFirst) {
                                       
                                                
        data.refreshing = true;
        data.error = null;
      } else {
        data.reset();
        data.loading = true;
      }
    } else {
      data.loadingMore = true;
    }
    setState(() {});

    final nextPage = refresh && !keepItems ? 1 : data.page + 1;
    final filter = _videoFilterParams(type);
    final result = await BilibiliSearchService.searchByType(
      type: type,
      keyword: keyword,
      page: nextPage,
      gaiaVtoken: _gaiaVtoken,
      duration: filter.duration,
      tids: filter.tids,
      pubBegin: filter.pubBegin,
      pubEnd: filter.pubEnd,
    );
    if (!mounted) return;
                                             
    if (keyword != _activeKeyword) {
      data.refreshing = false;
      return;
    }

    switch (result) {
      case BiliSearchOk(:final page):
                                               
                                            
                                                    
                              
        final filtered =
            (type == BiliSearchType.video &&
                _filters.keywordFilter &&
                keyword.isNotEmpty)
            ? page.items
                  .where(
                    (e) => _titleHasAnyKeywordChar(
                      e.titleSegments.map((s) => s.text).join(),
                      keyword,
                    ),
                  )
                  .toList()
            : page.items;
        setState(() {
          if (keepItems) {
                                              
            final existingIds = data.items.map((e) => e.id).toSet();
            final freshItems = filtered
                .where((e) => !existingIds.contains(e.id))
                .toList();
            if (freshItems.isNotEmpty) {
                                   
              data.items.insertAll(0, freshItems);
                             
              for (final e in freshItems) {
                data.freshInsertIds.add(e.id);
              }
                                                          
              Future.delayed(const Duration(milliseconds: 700), () {
                if (mounted) {
                  setState(() => data.freshInsertIds.clear());
                }
              });
                                               
              _showRefreshToast(type);
            } else {
              _showSnack(AppLocalizations.of(context).searchNoNewContent);
            }
            data.numResults = page.numResults;
            data.page = page.page;
          } else if (reloadFirst) {
                                      
            data.items
              ..clear()
              ..addAll(filtered);
            data.numResults = page.numResults;
            data.page = page.page;
          } else {
                                          
                                            
                                                                 
            final seen = data.items.map(_itemKey).toSet();
            data.items.addAll(filtered.where((e) => seen.add(_itemKey(e))));
            data.numResults = page.numResults;
            data.page = page.page;
          }
          data.hasMore =
              page.items.isNotEmpty && page.items.length >= page.pageSize;
          data.error = null;
          data.loading = false;
          data.loadingMore = false;
          data.refreshing = false;
          data.loaded = true;
        });
                                       
        if (type == BiliSearchType.video) {
          _translateVideoTitles(type);
        }
                                       
        if (refresh && !keepItems) {
          await BilibiliSearchCache.save(
            BilibiliSearchCache.keyFor(
              keyword: keyword,
              type: type,
              filterKey: _searchFilterKey(),
            ),
            BiliSearchCacheEntry(
              items: List.of(data.items),
              numResults: data.numResults,
              page: data.page,
              hasMore: data.hasMore,
              savedAt: DateTime.now(),
            ),
          );
        }
      case BiliSearchCaptcha(:final vVoucher):
        data.loading = false;
        data.loadingMore = false;
        data.refreshing = false;
        setState(() {});
        await _handleCaptcha(vVoucher, type);
      case BiliSearchError(:final detail):
        setState(() {
          data.error = detail;
          data.loading = false;
          data.loadingMore = false;
          data.refreshing = false;
          data.loaded = true;
        });
        _showSnack(detail);
    }
  }

                                           
                                       
                                         
  Future<void> _translateVideoTitles(BiliSearchType type) async {
    if (type != BiliSearchType.video) return;
    final translate = BilibiliTranslateService.instance;
    if (!translate.enabled) return;
    final data = _data[type];
    if (data == null || data.items.isEmpty) return;
    final list = <({String bvid, String title})>[];
    final overrides = <String, String>{};
    final seen = <String>{};
    for (final e in data.items) {
      if (e.type != BiliSearchType.video || e.bvid.isEmpty) continue;
      if (!seen.add(e.bvid)) continue;
      final t = e.titleSegments.map((s) => s.text).join();
      if (t.isEmpty) continue;
      final cached = BilibiliTitleCache.translatedTitle(e.bvid);
      if (cached != null) {
        overrides[e.bvid] = cached;
      } else {
        list.add((bvid: e.bvid, title: t));
      }
    }
    if (overrides.isNotEmpty && mounted) {
      setState(() => _videoTitleOverrides.addAll(overrides));
    }
    if (list.isEmpty) return;
    final remote = await BilibiliTranslateApi.translateTitles(list);
    if (!mounted || remote.isEmpty) return;
    BilibiliTitleCache.rememberAll(remote);
                          
    final current = _data[type];
    if (current == null || current.items.isEmpty) return;
    if (_activeKeyword.isEmpty) return;
    setState(() {
      _videoTitleOverrides.addAll(remote);
    });
  }

  void _loadMore(BiliSearchType type) {
    final data = _data[type];
    if (data == null ||
        data.loading ||
        data.loadingMore ||
        data.refreshing ||
        !data.hasMore) {
      return;
    }
    _loadType(type);
  }

  void _retry(BiliSearchType type) {
    _loadType(type, refresh: true);
  }

               

                                         
                           
  void _applyVideoFilters(_FilterState filters) {
    final changed =
        _filters.pubTime != filters.pubTime ||
        _filters.duration != filters.duration ||
        _filters.zone != filters.zone ||
        _filters.antiFuzzy != filters.antiFuzzy ||
        _filters.keywordFilter != filters.keywordFilter ||
        _filters.customBegin != filters.customBegin ||
        _filters.customEnd != filters.customEnd;
    if (!changed) return;
    _filters.pubTime = filters.pubTime;
    _filters.duration = filters.duration;
    _filters.zone = filters.zone;
    _filters.antiFuzzy = filters.antiFuzzy;
    _filters.keywordFilter = filters.keywordFilter;
    _filters.customBegin = filters.customBegin;
    _filters.customEnd = filters.customEnd;
                                       
    _loadType(BiliSearchType.video, refresh: true, reloadFirst: true);
    setState(() {});
  }

                         
  ({int? duration, int? tids, int? pubBegin, int? pubEnd}) _videoFilterParams(
    BiliSearchType type,
  ) {
    if (type != BiliSearchType.video) {
      return (duration: null, tids: null, pubBegin: null, pubEnd: null);
    }
                                                     
    const durationMap = [null, 1, 2, 3, 3];
    final duration = _filters.duration > 0
        ? durationMap[_filters.duration]
        : null;
    final tids = _filters.zone > 0 ? _filters.zone : null;
                         
    int? pubBegin;
    int? pubEnd;
    if (_filters.customBegin != null || _filters.customEnd != null) {
      pubBegin = _filters.customBegin;
      pubEnd = _filters.customEnd;
    } else {
      final now = DateTime.now();
      switch (_filters.pubTime) {
        case 1:        
          pubBegin =
              DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/
              1000;
        case 2:        
          pubBegin =
              DateTime(
                now.year,
                now.month,
                now.day - 6,
              ).millisecondsSinceEpoch ~/
              1000;
        case 3:        
          pubBegin =
              DateTime(
                now.year,
                now.month,
                now.day - 179,
              ).millisecondsSinceEpoch ~/
              1000;
      }
    }
                                  
    if (_filters.antiFuzzy) {
      if (pubBegin == null || pubBegin < _antiFuzzyBegin) {
        pubBegin = _antiFuzzyBegin;
      }
    }
    return (duration: duration, tids: tids, pubBegin: pubBegin, pubEnd: pubEnd);
  }

                                    
  String _searchFilterKey() {
    if (_filters.pubTime == 0 &&
        _filters.duration == 0 &&
        _filters.zone == 0 &&
        !_filters.antiFuzzy &&
        !_filters.keywordFilter &&
        _filters.customBegin == null &&
        _filters.customEnd == null) {
      return '';
    }
    return 'd${_filters.duration}z${_filters.zone}'
        'p${_filters.pubTime}${_filters.antiFuzzy ? 1 : 0}'
        'k${_filters.keywordFilter ? 1 : 0}'
        '${_filters.customBegin ?? ''}-${_filters.customEnd ?? ''}';
  }

                                              
                                         
  bool _titleHasAnyKeywordChar(String title, String keyword) {
    if (keyword.isEmpty) return true;
    for (final c in keyword.characters) {
      if (c.trim().isEmpty) continue;             
      if (title.contains(c)) return true;
    }
    return false;
  }

                                                         
  Future<void> _handleCaptcha(String vVoucher, BiliSearchType type) async {
    if (_captchaRunning) return;
    _captchaRunning = true;
    try {
      final registered = await BilibiliSearchService.gaiaVgateRegister(
        vVoucher,
      );
      if (!mounted) return;
      if (registered == null) {
        setState(() {
          _data[type]!.error =
              BilibiliSearchService.lastErrorDetail ??
              AppLocalizations.of(context).searchCaptchaInitFailed;
        });
        return;
      }
                                                   
      final geetest = await showGeetestDialog(
        context: context,
        gt: registered.gt,
        challenge: registered.challenge,
      );
      if (!mounted) return;
      if (geetest == null) {
        setState(() {
          _data[type]!.error = AppLocalizations.of(
            context,
          ).searchCaptchaIncomplete;
        });
        return;
      }
      final griskId = await BilibiliSearchService.gaiaVgateValidate(
        token: registered.token,
        challenge: geetest['geetest_challenge'] ?? '',
        validate: geetest['geetest_validate'] ?? '',
        seccode: geetest['geetest_seccode'] ?? '',
      );
      if (!mounted) return;
      if (griskId == null || griskId.isEmpty) {
        setState(() {
          _data[type]!.error =
              BilibiliSearchService.lastErrorDetail ??
              AppLocalizations.of(context).searchCaptchaValidateFailed;
        });
        _showSnack(
          AppLocalizations.of(context).searchCaptchaValidateFailedRetry,
        );
        return;
      }
      _gaiaVtoken = griskId;
      _showSnack(AppLocalizations.of(context).searchCaptchaPassed);
      await _loadType(type);
    } finally {
      _captchaRunning = false;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    showAppToast(context, message, error: true);
  }

                                     
  void _showRefreshToast(BiliSearchType type) {
    if (!mounted) return;
    final message = AppLocalizations.of(context).searchNewContentRefreshed;
    showAppToast(context, '${type.label} · $message');
  }

                                      
                                      
  void _handleBack() {
    if (_activeKeyword.isNotEmpty) {
      _resetToKeywordState();
    } else {
      Navigator.of(context).pop();
    }
  }

                                         
                          
  void _resetToKeywordState() {
    _suggestDebounce?.cancel();
    setState(() {
      _activeKeyword = '';
      _suggests = [];
      _topProgress.value = 0.0;
      for (final data in _data.values) {
        data.reset();
      }
    });
    _focusNode.requestFocus();
  }

                                          
        
                                          

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
                                      
    final trendingOn = _readSwitch(
      context,
      (s) => s.searchTrendingEnabled,
      SettingsService.searchTrendingEnabledStatic,
    );
    final rcmdOn = _readSwitch(
      context,
      (s) => s.searchRcmdEnabled,
      SettingsService.searchRcmdEnabledStatic,
    );
    final scaffold = Scaffold(
      backgroundColor: widget.embeddedInShell
          ? Colors.transparent
          : cs.surfaceContainer,
      body: Stack(
        children: [
                                             
          PageBackground(baseColor: cs.surfaceContainer, contentStyle: true),
          SafeArea(
            child: Stack(
              children: [
                                                  
                Positioned.fill(
                  child: naviTabBarView(
                    controller: _tabController,
                    children: [
                      for (final type in BiliSearchType.values)
                        _TypeResultsView(
                          type: type,
                          keyword: _activeKeyword,
                          data: _data[type]!,
                          filters: _filters,
                          refreshKey: _resultRefreshKeys[type],
                          onLoadMore: () => _loadMore(type),
                          onRetry: () => _retry(type),
                          onApplyFilters: _applyVideoFilters,
                          onScroll: _onResultsScroll,
                          onRefresh: () =>
                              _loadType(type, refresh: true, keepItems: true),
                          scrollController: _scrollControllers[type]!,
                          topBarProgress: _topProgress,
                          gridMode: _gridMode,
                          onToggleGrid: _toggleGridMode,
                          history: _histories[type] ?? const [],
                          onHistoryTap: _onHistoryTap,
                          onHistoryLongPress: _onHistoryLongPress,
                          onHistoryClear: _clearHistory,
                          videoTitleOverrides: _videoTitleOverrides,
                          showTrending: trendingOn,
                          trendingItems: _trendingItems,
                          trendingLoading: _trendingLoading,
                          trendingError: _trendingError,
                          onRefreshTrending: () =>
                              _loadTrending(forceRefresh: true),
                          showRcmd: rcmdOn,
                          rcmdItems: _rcmdItems,
                          rcmdLoading: _rcmdLoading,
                          rcmdError: _rcmdError,
                          onRefreshRcmd: () => _loadRcmd(forceRefresh: true),
                          onOpenHotRank: _openHotSearchPage,
                        ),
                    ],
                  ),
                ),
                                                    
                                           
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ValueListenableBuilder<double>(
                    valueListenable: _topProgress,
                    builder: (context, p, child) => SizedBox(
                                                                                             
                      height:
                          kSearchTabBarHeight +
                          2.4 +
                          kSearchBarHeight * (1 - p),
                      child: child,
                    ),
                    child: FrostedSearchHeader(
                      progressListenable: _topProgress,
                      tabBarHeight: kSearchTabBarHeight,
                      searchBar: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                        child: Row(
                          children: [
                            if (!widget.embeddedInShell) ...[
                              MorphIconButton(
                                icon: Icons.arrow_back,
                                tooltip: l10n.homeBack,
                                onTap: _handleBack,
                                frosted: true,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                                                           
                              child: FrostedPanel(
                                color: cs.surfaceContainerHigh.withValues(
                                  alpha: 0.45,
                                ),
                                borderRadius: BorderRadius.circular(
                                  kGroupRadius,
                                ),
                                child: TextField(
                                  controller: _keywordController,
                                  focusNode: _focusNode,
                                  autofocus: widget.initialKeyword.isEmpty,
                                  textInputAction: TextInputAction.search,
                                  onChanged: _onKeywordChanged,
                                  onSubmitted: (_) => _submitSearch(),
                                  decoration: InputDecoration(
                                                            
                                    hintText: '',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon:
                                        _keywordController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: _onClearKeyword,
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        kGroupRadius,
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                                                                    
                      tabRow: NaviOvalTabRow(
                        labels: [
                          for (final type in BiliSearchType.values)
                            _searchTabLabel(type),
                        ],
                        selectedIndex: _tabController.index,
                        onTap: _onSearchTabTap,
                        glassTabs: _buildGlassTabConfigs(),
                        height: kSearchTabBarHeight,
                      ),
                    ),
                  ),
                ),
                                        
                if (_suggests.isNotEmpty) _buildSuggestPanel(cs),
              ],
            ),
          ),
        ],
      ),
    );
                                    
                                       
    return PopScope(
      canPop: widget.embeddedInShell || _activeKeyword.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || widget.embeddedInShell) return;
        _resetToKeywordState();
      },
                                                     
      child: widget.embeddedInShell
          ? scaffold
          : IosBackdropScale(child: scaffold),
    );
  }

                                                     
                          
  List<GlassTab> _buildGlassTabConfigs() {
    return [
      for (final type in BiliSearchType.values)
        GlassTab(label: _searchTabLabel(type)),
    ];
  }

                                          
  void _onSearchTabTap(int targetIndex) {
    final type = BiliSearchType.values[targetIndex];
    if (_tabController.index == targetIndex) {
      final sc = _scrollControllers[type];
      if (sc != null && sc.hasClients && sc.offset > 0) {
        sc.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
                                             
                                         
      if (_activeKeyword.isNotEmpty) {
        final state = _resultRefreshKeys[type]?.currentState;
        if (state != null) {
          state.show();
          return;
        }
      }
      _loadType(type, refresh: true, keepItems: true);
    } else {
      _tabController.animateTo(targetIndex);
    }
  }

  String _searchTabLabel(BiliSearchType type) {
    final data = _data[type];
    final count = data?.numResults ?? 0;
    return data != null && count > 0
        ? '${type.label} ${_formatCount(count)}'
        : type.label;
  }

                                    
                              
                                     
  Widget _buildSuggestPanel(ColorScheme cs) {
    return Positioned(
      top: 56,
      left: 20,
      right: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
                                           
                                 
          final maxHeight = (constraints.maxHeight - 4).clamp(
            0.0,
            double.infinity,
          );
          return Material(
            color: cs.surfaceContainer,
            elevation: 6,
            borderRadius: BorderRadius.circular(kGroupRadius),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                physics: const AppRefreshScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: buildMorphSegmentedList([
                    for (final suggest in _suggests)
                      MorphRowItem(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          leading: Icon(
                            Icons.search,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                          title: Text(
                            suggest.display,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Icon(
                            Icons.north_west,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                          onTap: () => _onSuggestTap(suggest),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 10000) {
      final w = n / 10000;
      return '${w.toStringAsFixed(w >= 100 ? 0 : 1)}${L10n.current.tenThousandUnit}';
    }
    return '$n';
  }
}

                                            
               
                                            

class _TypeResultsView extends StatefulWidget {
  final BiliSearchType type;
  final String keyword;                   
  final _TypeData data;
  final _FilterState filters;

                                              
                               
  final GlobalKey<RefreshIndicatorState>? refreshKey;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

                             
  final void Function(_FilterState filters) onApplyFilters;

                           
  final void Function(ScrollNotification notification) onScroll;

                                   
  final Future<void> Function() onRefresh;

                                 
  final ScrollController scrollController;

                                         
                
  final ValueListenable<double> topBarProgress;

                                 
  final bool gridMode;

                
  final VoidCallback onToggleGrid;

                              
  final List<String> history;

                 
  final ValueChanged<String> onHistoryTap;

                 
  final ValueChanged<String> onHistoryLongPress;

                 
  final VoidCallback onHistoryClear;

                                      
                          
  final Map<String, String> videoTitleOverrides;

                                     
                               

                                                  
  final bool showTrending;
  final List<BiliHotSearchItem> trendingItems;
  final bool trendingLoading;
  final String? trendingError;

            
  final VoidCallback onRefreshTrending;

                                       
  final bool showRcmd;
  final List<BiliHotSearchItem> rcmdItems;
  final bool rcmdLoading;
  final String? rcmdError;

             
  final VoidCallback onRefreshRcmd;

                     
  final VoidCallback onOpenHotRank;

  const _TypeResultsView({
    required this.type,
    required this.keyword,
    required this.data,
    required this.filters,
    this.refreshKey,
    required this.onLoadMore,
    required this.onRetry,
    required this.onApplyFilters,
    required this.onScroll,
    required this.onRefresh,
    required this.scrollController,
    required this.topBarProgress,
    required this.gridMode,
    required this.onToggleGrid,
    required this.history,
    required this.onHistoryTap,
    required this.onHistoryLongPress,
    required this.onHistoryClear,
    this.videoTitleOverrides = const {},
    this.showTrending = true,
    this.trendingItems = const [],
    this.trendingLoading = false,
    this.trendingError,
    required this.onRefreshTrending,
    this.showRcmd = true,
    this.rcmdItems = const [],
    this.rcmdLoading = false,
    this.rcmdError,
    required this.onRefreshRcmd,
    required this.onOpenHotRank,
  });

  @override
  State<_TypeResultsView> createState() => _TypeResultsViewState();
}

class _TypeResultsViewState extends State<_TypeResultsView>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

                                                         
                                  
  static const double kVideoCardTargetWidth = 200.0;
  static const int kVideoCardMinColumns = 2;
  static const int kVideoCardMaxColumns = 8;

                                        
  int _prevGridCols = 0;
  int _prevItemCount = 0;
  int? _prevFirstItemId;
  late final AnimationController _gridRowAnimCtrl;
  final Map<int, Offset> _itemTranslations = {};

                                           
                         
  final Set<String> _showOriginalTitles = {};

                                      
  void _setShowOriginal(String bvid, bool show) {
    setState(() {
      if (show) {
        _showOriginalTitles.add(bvid);
      } else {
        _showOriginalTitles.remove(bvid);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _gridRowAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _gridRowAnimCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _itemTranslations.clear();
      }
    });
  }

  @override
  void didUpdateWidget(_TypeResultsView oldWidget) {
    super.didUpdateWidget(oldWidget);
                                     
    if (oldWidget.gridMode != widget.gridMode) {
      _prevGridCols = 0;
      _prevItemCount = 0;
      _prevFirstItemId = null;
      _itemTranslations.clear();
    }
  }

  @override
  void dispose() {
    _gridRowAnimCtrl.dispose();
    super.dispose();
  }

                       
  void _checkGridLayoutChange(int cols, int count, double cellW, double cellH) {
    if (_prevGridCols == 0) {
      _prevGridCols = cols;
      _prevItemCount = count;
      if (count > 0) _prevFirstItemId = widget.data.items[0].id;
      return;
    }
    if (_prevGridCols == cols && _prevItemCount == count) return;
    if (count == 0 || _prevItemCount == 0) {
      _prevGridCols = cols;
      _prevItemCount = count;
      if (count > 0) _prevFirstItemId = widget.data.items[0].id;
      return;
    }

    final oldCols = _prevGridCols;
    final newCols = cols;
    final minCount = _prevItemCount < count ? _prevItemCount : count;
    final newFirstId = widget.data.items[0].id;

                         
    if (_prevFirstItemId != null && _prevFirstItemId != newFirstId) {
      _itemTranslations.clear();
      _prevGridCols = cols;
      _prevItemCount = count;
      _prevFirstItemId = newFirstId;
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

    _prevGridCols = cols;
    _prevItemCount = count;
    _prevFirstItemId = newFirstId;

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
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final data = widget.data;

    if (widget.keyword.isEmpty) {
                                             
      return _buildDiscoveryView(cs);
    }
                                         
                                            
    if (!data.loaded ||
        shouldShowFullScreenLoading(
          loading: data.loading,
          isEmpty: data.items.isEmpty,
        )) {
      return const PageLoadingIndicator();
    }
         
    if (data.error != null && data.items.isEmpty) {
      return _buildError(cs);
    }
          
    if (data.items.isEmpty) return _buildNoResult(cs);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        widget.onScroll(notification);
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 300) {
          widget.onLoadMore();
        }
        return false;
      },
      child: UgcSelectionArea(
        child: AppRefreshIndicator(
          refreshIndicatorKey: widget.refreshKey,
          triggerMode: RefreshIndicatorTriggerMode.onEdge,
          edgeOffset: 0,
                                                
                                            
          displacement: kSearchBarHeight + kSearchTabBarHeight + 12,
          onRefresh: widget.onRefresh,
          color: Theme.of(context).colorScheme.primary,
          child: CustomScrollView(
            controller: widget.scrollController,
            physics: data.loading
                ? const NeverScrollableScrollPhysics()
                : const AppRefreshScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
            slivers: [
                                             
              SliverToBoxAdapter(
                child: ValueListenableBuilder<double>(
                  valueListenable: widget.topBarProgress,
                  builder: (context, p, _) => SizedBox(
                    height:
                        kSearchTabBarHeight + 2.4 + kSearchBarHeight * (1 - p),
                  ),
                ),
              ),
                                      
              if (widget.type == BiliSearchType.video) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _buildFilterButton(cs),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 4)),
              ],
                           
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.numResults > 0
                              ? l10n.searchResultsCount(
                                  widget.type.label,
                                  _formatCount(data.numResults),
                                )
                              : widget.type.label,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.primary,
                              ),
                        ),
                      ),
                                                        
                      if (widget.type == BiliSearchType.article ||
                          widget.type == BiliSearchType.mediaBangumi)
                        AppTooltip(
                          message: widget.gridMode
                              ? l10n.searchSwitchSingleCol
                              : l10n.searchSwitchMulti,
                          child: Material(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(kGroupRadius),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                widget.onToggleGrid();
                                _prevGridCols = 0;
                                _prevItemCount = 0;
                                _prevFirstItemId = null;
                                _itemTranslations.clear();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.gridMode
                                          ? Icons.grid_view_rounded
                                          : Icons.view_agenda_outlined,
                                      size: 15,
                                      color: widget.gridMode
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      widget.gridMode
                                          ? l10n.searchLayoutMulti
                                          : l10n.searchLayoutSingle,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: widget.gridMode
                                            ? FontWeight.w600
                                            : null,
                                        color: widget.gridMode
                                            ? cs.primary
                                            : cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
                                                     
              if (widget.type == BiliSearchType.video)
                if (widget.gridMode)
                  _buildVideoGrid(cs)
                else
                  _buildListSliver(cs)
              else if (widget.type == BiliSearchType.mediaBangumi)
                if (widget.gridMode)
                  _buildBangumiGrid(cs)
                else
                  _buildListSliver(cs)
              else if (widget.type == BiliSearchType.article)
                if (widget.gridMode)
                  _buildArticleGrid(cs)
                else
                  _buildListSliver(cs)
              else
                _buildListSliver(cs),
              SliverToBoxAdapter(child: _buildFooter(cs)),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

                                   
                                          
  Widget _buildListSliver(ColorScheme cs) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in widget.data.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FreshSlideIn(
                  isFresh: widget.data.freshInsertIds.contains(item.id),
                  child: MorphItem(
                    selected: false,
                    isFirst: true,
                    isLast: true,
                    interactive: true,
                    child: _buildCard(
                      cs,
                      item,
                                                 
                      translatedTitle: _showOriginalTitles.contains(item.bvid)
                          ? null
                          : widget.videoTitleOverrides[item.bvid],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

                           
  Widget _buildVideoGrid(ColorScheme cs) {
    final data = widget.data;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = (width / kVideoCardTargetWidth).floor().clamp(
            kVideoCardMinColumns,
            kVideoCardMaxColumns,
          );
          final cardW = (width - (columns - 1) * 12) / columns;
          final cellW = cardW + 12;
          final cellH = cardW / 0.78 + 12;
          _checkGridLayoutChange(columns, data.items.length, cellW, cellH);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = data.items[index];
                return ListenableBuilder(
                  listenable: _gridRowAnimCtrl,
                  builder: (context, _) {
                    final t = Curves.easeInOut.transform(
                      _gridRowAnimCtrl.value,
                    );
                    final delta = _itemTranslations[index];
                    Widget card = _FreshSlideIn(
                      isFresh: data.freshInsertIds.contains(item.id),
                      child: _VideoGridCard(
                        item: item,
                                                   
                        translatedTitle: _showOriginalTitles.contains(item.bvid)
                            ? null
                            : widget.videoTitleOverrides[item.bvid],
                        showOriginal: _showOriginalTitles.contains(item.bvid),
                        onToggleOriginal: (show) =>
                            _setShowOriginal(item.bvid, show),
                        onTap: () => _openItem(item),
                      ),
                    );
                    if (delta != null && t < 1.0) {
                      card = Transform.translate(
                        offset: Offset(delta.dx * (1 - t), delta.dy * (1 - t)),
                        child: card,
                      );
                    }
                    return card;
                  },
                );
              },
                                               
              childCount: data.items.length,
              addAutomaticKeepAlives: false,
            ),
          );
        },
      ),
    );
  }

                                         
  Widget _buildArticleGrid(ColorScheme cs) {
    final data = widget.data;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = (width / kVideoCardTargetWidth).floor().clamp(
            kVideoCardMinColumns,
            kVideoCardMaxColumns,
          );
          final cardW = (width - (columns - 1) * 12) / columns;
          final cellW = cardW + 12;
          final cellH = cardW / 0.72 + 12;
          _checkGridLayoutChange(columns, data.items.length, cellW, cellH);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = data.items[index];
                return ListenableBuilder(
                  listenable: _gridRowAnimCtrl,
                  builder: (context, _) {
                    final t = Curves.easeInOut.transform(
                      _gridRowAnimCtrl.value,
                    );
                    final delta = _itemTranslations[index];
                    Widget card = _FreshSlideIn(
                      isFresh: data.freshInsertIds.contains(item.id),
                      child: _ArticleGridCard(
                        item: item,
                        onTap: () => _openItem(item),
                      ),
                    );
                    if (delta != null && t < 1.0) {
                      card = Transform.translate(
                        offset: Offset(delta.dx * (1 - t), delta.dy * (1 - t)),
                        child: card,
                      );
                    }
                    return card;
                  },
                );
              },
                                               
              childCount: data.items.length,
              addAutomaticKeepAlives: false,
            ),
          );
        },
      ),
    );
  }

                    
  Widget _buildBangumiGrid(ColorScheme cs) {
    final data = widget.data;
                                              
                                                       
                                           
            
    const double textAreaH = 84.0;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = (width / kVideoCardTargetWidth).floor().clamp(
            kVideoCardMinColumns,
            kVideoCardMaxColumns,
          );
          final cardW = (width - (columns - 1) * 12) / columns;
          final cellW = cardW + 12;
          final cellH = cardW / 0.75 + textAreaH + 12;
          _checkGridLayoutChange(columns, data.items.length, cellW, cellH);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: cardW / (cardW / 0.75 + textAreaH),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = data.items[index];
                return ListenableBuilder(
                  listenable: _gridRowAnimCtrl,
                  builder: (context, _) {
                    final t = Curves.easeInOut.transform(
                      _gridRowAnimCtrl.value,
                    );
                    final delta = _itemTranslations[index];
                    Widget card = _FreshSlideIn(
                      isFresh: data.freshInsertIds.contains(item.id),
                      child: _BangumiGridCard(
                        item: item,
                        onTap: () => _openItem(item),
                      ),
                    );
                    if (delta != null && t < 1.0) {
                      card = Transform.translate(
                        offset: Offset(delta.dx * (1 - t), delta.dy * (1 - t)),
                        child: card,
                      );
                    }
                    return card;
                  },
                );
              },
                                               
              childCount: data.items.length,
              addAutomaticKeepAlives: false,
            ),
          );
        },
      ),
    );
  }

                                      
                                     
                                     
  void _openItem(BiliSearchItem item) {
                              
                                   
    FocusManager.instance.primaryFocus?.unfocus();
    if (item.type == BiliSearchType.biliUser && item.mid > 0) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BilibiliUserSpacePage(mid: item.mid)),
      );
    } else if (item.type == BiliSearchType.liveRoom && item.roomId > 0) {
                        
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BilibiliLiveRoomPage(
            roomId: item.roomId,
            title: item.titleSegments.map((s) => s.text).join(),
            uname: item.subtitle,
            cover: item.cover,
          ),
        ),
      );
    } else if (item.type == BiliSearchType.article && item.id > 0) {
                                              
                                    
                                      
      Navigator.of(context).push(
        heroTransitionRoute(
          heroZoom: true,
          page: ArticlePage(
            cvid: item.id,
            initialTitle: item.titleSegments.map((s) => s.text).join(),
            heroTag: 'article_entry_${item.id}',
            coverUrl: item.cover,
          ),
        ),
      );
    } else if (item.type == BiliSearchType.audio && item.id > 0) {
                                        
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BilibiliAudioSongPage(
            queue: [
              AudioZoneSong(
                id: item.id,
                title: item.titleSegments.map((s) => s.text).join(),
                author: item.subtitle,
                cover: item.cover,
                duration: 0,
                play: item.play,
                intro: item.desc,
                uploader: '',
                avid: 0,
                bvid: '',
              ),
            ],
          ),
        ),
      );
    } else if (item.type == BiliSearchType.video && item.bvid.isNotEmpty) {
      openBilibiliVideo(
        context,
        bvid: item.bvid,
        initialTitle: item.titleSegments.map((s) => s.text).join(),
        initialCover: BilibiliSearchService.coverUrl(item.cover),
        heroTag: 'bili_video_${item.bvid}',
      );
    } else if ((item.type == BiliSearchType.mediaBangumi ||
            item.type == BiliSearchType.mediaFt) &&
        item.seasonId > 0) {
                                             
      openBilibiliBangumi(
        context,
        seasonId: item.seasonId,
        initialTitle: item.titleSegments.map((s) => s.text).join(),
        initialCover: BilibiliSearchService.bangumiCoverUrl(item.cover),
        heroTag: 'bili_bangumi_${item.seasonId}',
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BrowserPage(
            initialUrl: item.actionUrl,
            title: item.titleSegments.map((s) => s.text).join(),
          ),
        ),
      );
    }
  }

                                     
                                 
  Widget _buildFilterButton(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final count = widget.filters.activeCount;
    return Row(
      children: [
        AppTooltip(
          message: l10n.searchVideoFilter,
          child: Material(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(kGroupRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _openFilterPanel,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune,
                      size: 16,
                      color: count > 0 ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      count > 0
                          ? l10n.searchFilterWithCount(count)
                          : l10n.searchFilter,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: count > 0 ? FontWeight.w600 : null,
                        color: count > 0 ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
                                             
        AppTooltip(
          message: widget.gridMode
              ? l10n.searchSwitchSingleCol
              : l10n.searchSwitchMulti,
          child: Material(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(kGroupRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                widget.onToggleGrid();
                _prevGridCols = 0;
                _prevItemCount = 0;
                _prevFirstItemId = null;
                _itemTranslations.clear();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.gridMode
                          ? Icons.grid_view_rounded
                          : Icons.view_agenda_outlined,
                      size: 16,
                      color: widget.gridMode ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.gridMode
                          ? l10n.searchLayoutMulti
                          : l10n.searchLayoutSingle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: widget.gridMode ? FontWeight.w600 : null,
                        color: widget.gridMode
                            ? cs.primary
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

                                       
                                       
                                       
  void _openFilterPanel() {
    final cs = Theme.of(context).colorScheme;
    final filters = widget.filters;
                         
    var draftPubTime = filters.pubTime;
    var draftDuration = filters.duration;
    var draftZone = filters.zone;
    var draftAntiFuzzy = filters.antiFuzzy;
    var draftKeywordFilter = filters.keywordFilter;
    var draftBegin = filters.customBegin;
    var draftEnd = filters.customEnd;
                                      
    PopupOverlayGuard.open();
    showAppBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final l10n = AppLocalizations.of(sheetContext);
            Widget sectionTitle(String title) => Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );

                                                            
                                             
                                                
            Widget filterDropdown({
              required String label,
              required List<GlassMenuAction> actions,
            }) {
              return Builder(
                builder: (btnContext) => Material(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(kGroupRadius),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      final box = btnContext.findRenderObject() as RenderBox;
                      if (!box.attached) return;
                      showGlassDropdownMenu(
                        btnContext,
                        actions: actions,
                        globalPosition: box.localToGlobal(Offset.zero),
                        originSize: box.size,
                        menuWidth: 200,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

                     
            String fmtDate(int? ts) {
              if (ts == null) return l10n.searchFilterAny;
              final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
              return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
                  '${dt.day.toString().padLeft(2, '0')}';
            }

            Future<void> pickDate({required bool isBegin}) async {
              final current = isBegin ? draftBegin : draftEnd;
              final other = isBegin ? draftEnd : draftBegin;
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: sheetContext,
                initialDate: current != null
                    ? DateTime.fromMillisecondsSinceEpoch(current * 1000)
                    : (isBegin && other != null
                          ? DateTime.fromMillisecondsSinceEpoch(other * 1000)
                          : now),
                firstDate: isBegin
                    ? DateTime(2009, 6, 26)
                    : (draftBegin != null
                          ? DateTime.fromMillisecondsSinceEpoch(
                              draftBegin! * 1000,
                            )
                          : DateTime(2009, 6, 26)),
                lastDate: isBegin
                    ? (other != null
                          ? DateTime.fromMillisecondsSinceEpoch(other * 1000)
                          : now)
                    : now,
                helpText: isBegin
                    ? l10n.searchPickStartDate
                    : l10n.searchPickEndDate,
              );
              if (picked == null) return;
              final ts =
                  DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    isBegin ? 0 : 23,
                    isBegin ? 0 : 59,
                    isBegin ? 0 : 59,
                  ).millisecondsSinceEpoch ~/
                  1000;
              draftBegin = isBegin ? ts : draftBegin;
              draftEnd = isBegin ? draftEnd : ts;
              setSheetState(() {});              
            }

                                      
            void apply() {
              widget.onApplyFilters(
                _FilterState()
                  ..pubTime = draftPubTime
                  ..duration = draftDuration
                  ..zone = draftZone
                  ..antiFuzzy = draftAntiFuzzy
                  ..keywordFilter = draftKeywordFilter
                  ..customBegin = draftBegin
                  ..customEnd = draftEnd,
              );
              Navigator.pop(sheetContext);
            }

                      
            void reset() {
              draftPubTime = 0;
              draftDuration = 0;
              draftZone = 0;
              draftAntiFuzzy = false;
              draftKeywordFilter = false;
              draftBegin = null;
              draftEnd = null;
              setSheetState(() {});
            }

            return GlassMenuSurface(
              radius: 24.0,
              blur: 12.0,
              stretch: 0.3,
              legacyClipRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              legacyDecoration: BoxDecoration(
                color: cs.surfaceContainerLow.withValues(alpha: 0.75),
              ),
              content: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  24 + MediaQuery.viewPaddingOf(sheetContext).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.searchVideoFilter,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                                           
                    sectionTitle(l10n.searchPubTimeSection),
                    filterDropdown(
                      label: _pubTimeLabel(draftPubTime, l10n),
                      actions: [
                        for (var i = 0; i < kPubTimeOptions.length; i++)
                          GlassMenuAction(
                            icon: Icons.schedule,
                            text: _pubTimeLabel(i, l10n),
                            trailing:
                                (draftPubTime == i &&
                                    draftBegin == null &&
                                    draftEnd == null)
                                ? Icon(Icons.check, size: 18, color: cs.primary)
                                : null,
                            onTap: () {
                              draftPubTime = i;
                              draftBegin = null;
                              draftEnd = null;
                              setSheetState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _DateButton(
                            label: l10n.searchDateBegin,
                            value: fmtDate(draftBegin),
                            active: draftBegin != null,
                            cs: cs,
                            onTap: () => pickDate(isBegin: true),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            l10n.searchDateTo,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          child: _DateButton(
                            label: l10n.searchDateEnd,
                            value: fmtDate(draftEnd),
                            active: draftEnd != null,
                            cs: cs,
                            onTap: () => pickDate(isBegin: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                                           
                    sectionTitle(l10n.searchDurationSection),
                    filterDropdown(
                      label: _durationLabel(draftDuration, l10n),
                      actions: [
                        for (var i = 0; i < kDurationOptions.length; i++)
                          GlassMenuAction(
                            icon: Icons.timelapse,
                            text: _durationLabel(i, l10n),
                            trailing: draftDuration == i
                                ? Icon(Icons.check, size: 18, color: cs.primary)
                                : null,
                            onTap: () {
                              draftDuration = i;
                              setSheetState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                                                      
                    sectionTitle(l10n.searchZoneSection),
                    filterDropdown(
                      label: _zoneLabel(draftZone, l10n),
                      actions: [
                        for (final zone in kZoneOptions)
                          GlassMenuAction(
                            icon: Icons.category_outlined,
                            text: _zoneLabel(zone.tids, l10n),
                            trailing: draftZone == zone.tids
                                ? Icon(Icons.check, size: 18, color: cs.primary)
                                : null,
                            onTap: () {
                              draftZone = zone.tids;
                              setSheetState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                                  
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.searchAntiFuzzy,
                        style: const TextStyle(fontSize: 15),
                      ),
                      subtitle: Text(
                        l10n.searchAntiFuzzyHint,
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: draftAntiFuzzy,
                      onChanged: (v) {
                        draftAntiFuzzy = v;
                        setSheetState(() {});             
                      },
                    ),
                                                      
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '仅限标题含搜索词的视频',
                        style: const TextStyle(fontSize: 15),
                      ),
                      subtitle: Text(
                        '开启后仅保留标题确实包含搜索词任一字符的视频，'
                        '排除 B 站大数据推荐污染，结果可能较少',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: draftKeywordFilter,
                      onChanged: (v) {
                        draftKeywordFilter = v;
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: reset,
                            child: Text(l10n.searchFilterReset),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: apply,
                            child: Text(l10n.commonOk),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(PopupOverlayGuard.close);
  }

  Widget _buildCard(
    ColorScheme cs,
    BiliSearchItem item, {
    String? translatedTitle,
  }) {
    final isVideo = item.type == BiliSearchType.video && item.bvid.isNotEmpty;
    final hasTranslation =
        translatedTitle != null && translatedTitle.isNotEmpty;
                                      
                                                    
                                                             
                                            
                                     
    final heroTag = isVideo
        ? 'bili_video_${item.bvid}'
        : item.type == BiliSearchType.article && item.id > 0
        ? 'article_entry_${item.id}'
        : (item.type == BiliSearchType.mediaBangumi ||
                  item.type == BiliSearchType.mediaFt) &&
              item.seasonId > 0
        ? 'bili_bangumi_${item.seasonId}'
        : null;
                                               
                                            
                                                          
                                               
                       
    final useZoomHero =
        heroTag != null && SettingsService.heroTransitionBlurEnabled;
    final leading = heroTag != null && !useZoomHero
        ? Hero(
            transitionOnUserGestures: true,
            tag: heroTag,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
            child: _ItemThumb(item: item),
          )
        : _ItemThumb(item: item);
    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: leading,
      title: hasTranslation
          ? Text(
              translatedTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            )
          : Text.rich(
              TextSpan(
                children: [
                  for (final seg in item.titleSegments)
                    TextSpan(
                      text: seg.text,
                      style: seg.highlight
                          ? TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            )
                          : null,
                    ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          [item.subtitle, item.meta].where((s) => s.isNotEmpty).join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
      onTap: () => _openItem(item),
      onLongPress: isVideo
          ? () => showVideoBottomSheet(
              context,
              bvid: item.bvid,
              title: item.titleSegments.map((s) => s.text).join(),
              cover: BilibiliSearchService.coverUrl(item.cover),
              author: item.subtitle,
              showOriginal: _showOriginalTitles.contains(item.bvid),
              onToggleOriginal: (show) => _setShowOriginal(item.bvid, show),
            )
          : null,
    );
                                                                 
    final card = GestureDetector(
      onSecondaryTapDown: isVideo
          ? (details) => showVideoContextMenu(
              context,
              bvid: item.bvid,
              title: item.titleSegments.map((s) => s.text).join(),
              cover: BilibiliSearchService.coverUrl(item.cover),
              author: item.subtitle,
              globalPosition: details.globalPosition,
              showOriginal: _showOriginalTitles.contains(item.bvid),
              onToggleOriginal: (show) => _setShowOriginal(item.bvid, show),
            )
          : null,
      child: tile,
    );
                                      
                                         
    final interactive = MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
                                               
                                           
    if (useZoomHero) {
      return Hero(
        transitionOnUserGestures: true,
        tag: heroTag,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: interactive,
      );
    }
    return interactive;
  }

  Widget _buildFooter(ColorScheme cs) {
    final data = widget.data;
    if (data.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: LoadingIndicatorM3E()),
      );
    }
    if (!data.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            AppLocalizations.of(context).searchAllLoaded,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }

  Widget _buildHint(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.manage_search_rounded,
            size: 56,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.searchKeywordHint,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.searchPressToSearch,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

                                    
                                     
  Widget _buildDiscoveryView(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        widget.onScroll(notification);
        return false;
      },
      child: CustomScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: AppRefreshScrollPhysics(),
        ),
        slivers: [
                             
          SliverToBoxAdapter(
            child: ValueListenableBuilder<double>(
              valueListenable: widget.topBarProgress,
              builder: (context, p, _) => SizedBox(
                height: kSearchTabBarHeight + kSearchBarHeight * (1 - p),
              ),
            ),
          ),
                                     
          if (widget.showTrending)
            _buildHotSection(
              cs,
              l10n,
              title: l10n.searchTrendingTitle,
              items: widget.trendingItems,
              loading: widget.trendingLoading,
              error: widget.trendingError,
              onRefresh: widget.onRefreshTrending,
              showFullList: true,
            ),
                            
          if (widget.showRcmd)
            _buildHotSection(
              cs,
              l10n,
              title: l10n.searchDiscoveryTitle,
              items: widget.rcmdItems,
              loading: widget.rcmdLoading,
              error: widget.rcmdError,
              onRefresh: widget.onRefreshRcmd,
            ),
                                     
          if (widget.history.isNotEmpty)
            _historySliver(cs, l10n)
          else
            _hintSliver(cs, l10n),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ),
        ],
      ),
    );
  }

                                            
  Widget _buildHotSection(
    ColorScheme cs,
    AppLocalizations l10n, {
    required String title,
    required List<BiliHotSearchItem> items,
    required bool loading,
    String? error,
    required VoidCallback onRefresh,
    bool showFullList = false,
  }) {
    final compact = TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      foregroundColor: cs.outline,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.whatshot_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (showFullList)
                  TextButton.icon(
                    onPressed: widget.onOpenHotRank,
                    style: compact,
                    icon: Icon(
                      Icons.keyboard_arrow_right,
                      size: 16,
                      color: cs.outline,
                    ),
                    label: Text(
                      l10n.searchTrendingFullList,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                IconButton(
                  onPressed: onRefresh,
                  tooltip: l10n.refreshAction,
                  icon: Icon(
                    Icons.refresh_outlined,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            if (error != null && items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        error,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onRefresh,
                      style: compact,
                      child: Text(
                        l10n.refreshAction,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else if (items.isEmpty)
              loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: SizedBox(
                        height: 28,
                        child: Center(child: LoadingIndicatorM3E()),
                      ),
                    )
                  : const SizedBox.shrink()
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 30,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) => _buildHotWordTile(cs, items[i]),
              ),
          ],
        ),
      ),
    );
  }

                                     
  Widget _buildHotWordTile(ColorScheme cs, BiliHotSearchItem item) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => widget.onHistoryTap(item.keyword),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 8, 0),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  item.keyword,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (item.icon != null && item.icon!.isNotEmpty) ...[
                const SizedBox(width: 4),
                Image.network(
                  item.icon!,
                  height: 15,
                  headers: NetworkSettingsService.instance.apiHeaders,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ] else if (item.showLiveIcon) ...[
                const SizedBox(width: 4),
                const _LiveBadge(),
              ] else if (item.recommendReason != null &&
                  item.recommendReason!.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  item.recommendReason!,
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

                                   
  Widget _historySliver(ColorScheme cs, AppLocalizations l10n) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.type.label} · ${l10n.searchHistoryTitle}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onHistoryClear,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: cs.onSurfaceVariant,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(
                    l10n.searchHistoryClear,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in widget.history) _buildHistoryChip(cs, item),
              ],
            ),
          ],
        ),
      ),
    );
  }

                            
  Widget _hintSliver(ColorScheme cs, AppLocalizations l10n) {
    return SliverToBoxAdapter(
      child: SizedBox(height: 220, child: _buildHint(cs)),
    );
  }

                             
  Widget _buildHistoryChip(ColorScheme cs, String word) {
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onHistoryTap(word),
        onLongPress: () => widget.onHistoryLongPress(word),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            word,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResult(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.searchNoResultInType(widget.keyword, widget.type.label),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final detail = widget.data.error;
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.searchFailed,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              if (detail != null && detail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
                                        
        PositionedRetryFab(
          onRetry: widget.onRetry,
          bottomOffset: MediaQuery.paddingOf(context).bottom + 16,
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 10000) {
      final w = n / 10000;
      return '${w.toStringAsFixed(w >= 100 ? 0 : 1)}${L10n.current.tenThousandUnit}';
    }
    return '$n';
  }

  String _pubTimeLabel(int i, AppLocalizations l10n) {
    switch (i) {
      case 0:
        return l10n.searchFilterAny;
      case 1:
        return l10n.searchFilterLastDay;
      case 2:
        return l10n.searchFilterLastWeek;
      case 3:
        return l10n.searchFilterHalfYear;
    }
    return l10n.searchFilterAny;
  }

  String _durationLabel(int i, AppLocalizations l10n) {
    switch (i) {
      case 0:
        return l10n.searchFilterAllDuration;
      case 1:
        return l10n.searchFilterDur0to10;
      case 2:
        return l10n.searchFilterDur10to30;
      case 3:
        return l10n.searchFilterDur30to60;
      case 4:
        return l10n.searchFilterDur60plus;
    }
    return l10n.searchFilterAllDuration;
  }

  String _zoneLabel(int tids, AppLocalizations l10n) {
    switch (tids) {
      case 0:
        return l10n.searchZoneAll;
      case 1:
        return l10n.searchZoneAnime;
      case 13:
        return l10n.searchTypeBangumi;
      case 167:
        return l10n.searchZoneGuochuang;
      case 3:
        return l10n.searchZoneMusic;
      case 129:
        return l10n.searchZoneDance;
      case 4:
        return l10n.searchZoneGame;
      case 36:
        return l10n.searchZoneKnowledge;
      case 188:
        return l10n.searchZoneTech;
      case 234:
        return l10n.searchZoneSports;
      case 223:
        return l10n.searchZoneCar;
      case 160:
        return l10n.searchZoneLife;
      case 221:
        return l10n.searchZoneFood;
      case 217:
        return l10n.searchZoneAnimal;
      case 119:
        return l10n.searchZoneKichiku;
      case 115:
        return l10n.searchZoneFashion;
      case 202:
        return l10n.searchZoneInfo;
      case 5:
        return l10n.searchZoneEnt;
      case 181:
        return l10n.searchTypeFt;
      case 177:
        return l10n.searchZoneDoc;
      case 23:
        return l10n.searchZoneFilm;
      case 11:
        return l10n.searchZoneTv;
    }
    return l10n.searchZoneAll;
  }
}

                                            
                                         
                                            

class _ItemThumb extends StatelessWidget {
  final BiliSearchItem item;
  const _ItemThumb({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = item.type == BiliSearchType.biliUser;

    final fallback = Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        isUser ? Icons.person_outline : Icons.videocam_outlined,
        size: 24,
        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );

    final image = item.cover.isNotEmpty
        ? (isUser
              ? Image(
                  image: CachedImageProvider(
                    BilibiliSearchService.avatarUrl(item.cover),
                    headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                        ? null
                        : NetworkSettingsService.instance.apiHeaders,
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallback,
                )
              : Image(
                  image: CachedImageProvider(
                    BilibiliSearchService.coverUrl(item.cover),
                    headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                        ? null
                        : NetworkSettingsService.instance.apiHeaders,
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallback,
                ))
        : fallback;

    final thumb = SizedBox(
      width: isUser ? 52 : 96,
      height: isUser ? 52 : 60,
      child: image,
    );

    if (isUser) {
                                                                   
                          
      return Hero(
        transitionOnUserGestures: true,
        tag: 'bili_space_avatar_${item.mid}',
        child: ClipOval(child: thumb),
      );
    }

    final thumbCard = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          thumb,
                     
          if (item.duration.isNotEmpty)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  item.duration,
                  style: const TextStyle(fontSize: 9, color: Colors.white),
                ),
              ),
            ),
                   
          if (item.badge.isNotEmpty)
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFB7299),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  item.badge,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

                                                             
                         
    return thumbCard;
  }
}

                                            
                                            

class _VideoGridCard extends StatelessWidget {
  final BiliSearchItem item;
  final VoidCallback? onTap;

                                 
  final String? translatedTitle;

                              
  final bool showOriginal;

                                              
  final ValueChanged<bool>? onToggleOriginal;

  const _VideoGridCard({
    required this.item,
    this.translatedTitle,
    this.onTap,
    this.showOriginal = false,
    this.onToggleOriginal,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return VideoCardV(
      data: VideoCardData(
        cover: BilibiliSearchService.coverUrl(item.cover),
        title: item.titleSegments.map((s) => s.text).join(),
                                        
        titleSpan: (translatedTitle != null && translatedTitle!.isNotEmpty)
            ? null
            : TextSpan(
                children: [
                  for (final seg in item.titleSegments)
                    TextSpan(
                      text: seg.text,
                      style: seg.highlight
                          ? TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            )
                          : null,
                    ),
                ],
              ),
        heroTag: item.bvid.isNotEmpty ? 'bili_video_${item.bvid}' : null,
        view: item.play,
        danmaku: item.danmaku,
                                    
        durationText: item.duration,
        badge: item.badge,
        subtitle: item.subtitle,
      ),
      onTap: onTap,
      onLongPress: item.bvid.isNotEmpty
          ? () => showVideoBottomSheet(
              context,
              bvid: item.bvid,
              title: item.titleSegments.map((s) => s.text).join(),
              cover: BilibiliSearchService.coverUrl(item.cover),
              author: item.subtitle,
              showOriginal: showOriginal,
              onToggleOriginal: onToggleOriginal,
            )
          : null,
      onSecondaryTap: item.bvid.isNotEmpty
          ? (pos) => showVideoContextMenu(
              context,
              bvid: item.bvid,
              title: item.titleSegments.map((s) => s.text).join(),
              cover: BilibiliSearchService.coverUrl(item.cover),
              author: item.subtitle,
              globalPosition: pos,
              showOriginal: showOriginal,
              onToggleOriginal: onToggleOriginal,
            )
          : null,
    );
  }
}

                                            
                     
                                            

class _DateButton extends StatelessWidget {
  final String label;           
  final String value;          
  final bool active;         
  final ColorScheme cs;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.active,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kItemPressedRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? cs.secondaryContainer : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(kItemPressedRadius),
          border: Border.all(
            color: active
                ? cs.secondary.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 16,
              color: active ? cs.onSecondaryContainer : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : null,
                  color: active ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
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

                                            
                
                                            

class _ArticleGridCard extends StatelessWidget {
  final BiliSearchItem item;
  final VoidCallback? onTap;

  const _ArticleGridCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                       
            AspectRatio(
              aspectRatio: 16 / 10,
              child: item.cover.isNotEmpty
                  ? Image(
                      image: CachedImageProvider(
                        BilibiliSearchService.coverUrl(item.cover),
                        headers:
                            NetworkSettingsService.instance.apiHeaders.isEmpty
                            ? null
                            : NetworkSettingsService.instance.apiHeaders,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackCover(cs),
                    )
                  : _fallbackCover(cs),
            ),
                                 
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          for (final seg in item.titleSegments)
                            TextSpan(
                              text: seg.text,
                              style: seg.highlight
                                  ? TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                    )
                                  : null,
                            ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (item.meta.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
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
                                  
                                                   
                                   
                                       
    final interactive = MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
    return Hero(
      transitionOnUserGestures: true,
      tag: 'article_entry_${item.id}',
      child: interactive,
    );
  }

  Widget _fallbackCover(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.article_outlined,
        size: 32,
        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }
}

                                            
                                            

class _BangumiGridCard extends StatelessWidget {
  final BiliSearchItem item;
  final VoidCallback? onTap;

  const _BangumiGridCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
                                               
                                               
                                 
    final title = item.titleSegments.map((s) => s.text).join();
    return VideoCardV(
      data: VideoCardData(
        cover: BilibiliSearchService.bangumiCoverUrl(item.cover),
        title: title,
                                     
        titleSpan: TextSpan(
          children: [
            for (final seg in item.titleSegments)
              TextSpan(
                text: seg.text,
                style: seg.highlight
                    ? TextStyle(color: cs.primary, fontWeight: FontWeight.w700)
                    : null,
              ),
          ],
        ),
        heroTag: item.seasonId > 0 ? 'bili_bangumi_${item.seasonId}' : null,
                                
        coverAspect: 3 / 4,
        badge: item.badge.isNotEmpty ? item.badge : null,
                                       
        reason: item.meta.isNotEmpty ? item.meta : null,
                                
        durationText: item.duration.isNotEmpty ? item.duration : null,
        subtitle: item.subtitle,
                                         
                         
        coverWidget: LazyCoverImage(
          BilibiliSearchService.bangumiCoverUrl(item.cover),
          headers: NetworkSettingsService.instance.apiHeaders.isEmpty
              ? null
              : NetworkSettingsService.instance.apiHeaders,
          fit: BoxFit.cover,
          aspect: 3 / 4,
          maxDimension: 480,
        ),
      ),
      onTap: onTap,
    );
  }
}

                                      
                
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFfb7299),
        borderRadius: BorderRadius.circular(2),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          fontSize: 9,
          height: 1.1,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
