                                       
  
                                                 
                                              
                                       
                                                          
                                            
                                                   
                                                       
                                                             
                                                                       
                                                    
                                          
                                                         
                                                     
                                   
                               
                                                       
                                                             
                                                      
                                                    
import 'dart:async';
import 'dart:io' show Platform, HttpClient;
import 'dart:math' as math;
import 'dart:typed_data' show Uint8List;

import 'package:naviflash/widgets/app_tooltip.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        Clipboard,
        ClipboardData,
                                   
        DeviceOrientation,
        HapticFeedback,
                                            
        PredictiveBackEvent,
        SystemChrome,
        SystemUiMode,
        SystemUiOverlay;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/screens/bilibili_comments_page.dart';
import 'package:naviflash/screens/bilibili_music_page.dart';
import 'package:naviflash/screens/bilibili_topic_page.dart';
import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/screens/bilibili_related_videos_page.dart';
import 'package:naviflash/screens/bilibili_search_page.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/screens/player.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_favorite_service.dart';
import 'package:naviflash/services/bilibili_interaction_service.dart';
import 'package:naviflash/services/bilibili_translate_api.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:naviflash/services/bilibili_video_service.dart';
import 'package:naviflash/services/bilibili_watch_later_service.dart';
import 'package:naviflash/services/player_audio_service.dart';
import 'package:naviflash/services/super_resolution_service.dart';
import 'package:naviflash/services/link_utils.dart';
import 'package:naviflash/services/bv_av.dart';
import 'package:naviflash/services/bilibili_music_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/play_history_service.dart';
import 'package:naviflash/services/watch_history_service.dart';
import 'package:naviflash/services/playlist_service.dart';
import 'package:naviflash/services/native_menu_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/services/taskbar_progress_service.dart';
import 'package:naviflash/services/video_cache_service.dart';
import 'package:naviflash/services/manual_video_cache.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/bili_note_list_sheet.dart';
import 'package:naviflash/widgets/danmaku/danmaku_controller.dart';
import 'package:naviflash/widgets/danmaku/danmaku_fetcher.dart';
import 'package:naviflash/widgets/danmaku/danmaku_list_sheet.dart';
import 'package:naviflash/widgets/danmaku/danmaku_settings_panel.dart';
import 'package:naviflash/widgets/danmaku/danmaku_model.dart';
import 'package:naviflash/widgets/danmaku/danmaku_send_sheet.dart';
import 'package:naviflash/widgets/hero_gesture_curve.dart';
import 'package:naviflash/widgets/comment/comment_composer.dart';
import 'package:naviflash/widgets/comment/comment_composer_fab.dart';
import 'package:naviflash/widgets/ugc_rich_text.dart';
import 'package:naviflash/widgets/ai_conclusion_sheet.dart';
import 'package:naviflash/screens/note_editor_page.dart';
import 'package:naviflash/screens/bilibili_audio_page.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/more_menu_sheet.dart';
import 'package:naviflash/widgets/video/horizontal_member_panel.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/ios_zoom_hero.dart';
import 'package:naviflash/widgets/navi_spring_physics.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/ugc_selection_area.dart';
import 'package:naviflash/screens/pay_coins_page.dart';
import 'package:naviflash/widgets/zoom_hero_exit.dart';
import 'package:naviflash/main.dart' show globalNavigatorKey;
import 'package:naviflash/services/playback_focus.dart';

                                                 
                                         
                                       
         
   
                                       
                                        
                                        
                      
Route<dynamic>? _lastVideoOpenRoute;

                                                    
                                           
                                                  
                    
bool _videoOpenGuard = false;

                                    
void _releaseVideoOpenGuard(Route<dynamic> route) {
  if (!identical(_lastVideoOpenRoute, route)) return;
  _lastVideoOpenRoute = null;
  _videoOpenGuard = false;
}

                       
                                              
                                   
                                                         
                       
                                              
void _watchVideoRouteLifecycle(Route<dynamic> route) {
  if (route is! TransitionRoute) {
    unawaited(route.popped.then((_) => _releaseVideoOpenGuard(route)));
    return;
  }
  var attached = false;

                                                  
  void tryAttach() {
    if (attached) return;
    final animation = route.animation;
    if (animation == null) return;
    attached = true;

    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.forward) return;
                                                        
      animation.removeStatusListener(onStatus);
      _releaseVideoOpenGuard(route);
    }

    animation.addStatusListener(onStatus);
                                                
                
    if (animation.status == AnimationStatus.completed) {
      animation.removeStatusListener(onStatus);
      _releaseVideoOpenGuard(route);
    }
  }

                                                          
                                                
                                             
  WidgetsBinding.instance.addPostFrameCallback((_) => tryAttach());
  unawaited(route.popped.then((_) => _releaseVideoOpenGuard(route)));
  unawaited(route.completed.then((_) => _releaseVideoOpenGuard(route)));
}

                                           
class _PendingVideoOpen {
  _PendingVideoOpen({
    required this.bvid,
    this.initialTitle,
    this.initialCover,
    this.heroTag,
    this.initialPosition,
    this.wideClassic = false,
    this.commentRootId,
    this.commentSecondaryId,
    this.initialCid,
    this.initialPage,
  });

  final String bvid;
  final String? initialTitle;
  final String? initialCover;
  final String? heroTag;
  final Duration? initialPosition;
  final bool wideClassic;
  final int? commentRootId;
  final int? commentSecondaryId;

                                              
  final int? initialCid;

                                       
  final int? initialPage;
}

                                   
                                              
                             
                                          
                                            
void openBilibiliVideo(
  BuildContext context, {
  required String bvid,
  String? initialTitle,
  String? initialCover,
  String? heroTag,
  Duration? initialPosition,
  bool wideClassic = false,
  int? commentRootId,
  int? commentSecondaryId,
  int? initialCid,
  int? initialPage,
}) {
                                           
                             
  FocusManager.instance.primaryFocus?.unfocus();

  final request = _PendingVideoOpen(
    bvid: bvid,
    initialTitle: initialTitle,
    initialCover: initialCover,
    heroTag: heroTag,
    initialPosition: initialPosition,
    wideClassic: wideClassic,
    commentRootId: commentRootId,
    commentSecondaryId: commentSecondaryId,
    initialCid: initialCid,
    initialPage: initialPage,
  );

                                    
                                     
  if (_videoOpenGuard) return;
  _pushVideoPage(context, request);
}

                                                  
                      
bool _pushVideoPage(BuildContext? context, _PendingVideoOpen r) {
  final ctx = context ?? globalNavigatorKey.currentContext;
  if (ctx == null) return false;
  final navigator = Navigator.maybeOf(ctx);
  if (navigator == null) return false;
                                       
                          
  unawaited(PlaybackFocus.instance.pauseAll());
  final wide = MediaQuery.sizeOf(ctx).width >= 768;
  final page = BilibiliVideoPage(
    bvid: r.bvid,
    initialTitle: r.initialTitle,
    initialCover: r.initialCover,
    heroTag: r.heroTag,
    initialPosition: r.initialPosition,
    wideClassic: r.wideClassic,
    commentRootId: r.commentRootId,
    commentSecondaryId: r.commentSecondaryId,
    initialCid: r.initialCid,
    initialPage: r.initialPage,
  );
  final Route<dynamic> route = wide && r.wideClassic
                                            
      ? MaterialPageRoute(builder: (_) => page)
                                        
      : heroTransitionRoute(heroZoom: r.heroTag != null, page: page);
                                              
                                                       
  _lastVideoOpenRoute = route;
  _videoOpenGuard = true;
                                                
  unawaited(navigator.push(route));
  _watchVideoRouteLifecycle(route);
  return true;
}

                                
String? bilibiliBvidFromUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final host = uri.host.toLowerCase();
  if (!host.contains('bilibili.com') && !host.contains('b23.tv')) return null;
  final segs = uri.pathSegments;
  for (final seg in segs) {
    if (RegExp(r'^(BV|bv)[0-9A-Za-z]{10}$').hasMatch(seg)) return seg;
  }
  return null;
}

                                      
                                     
                                         
                      
Future<void> openBiliLinkInApp(
  BuildContext context, {
  required String url,
  bool confirm = false,
}) async {
  final normalized = normalizeLink(url);
  if (normalized.isEmpty) return;
  var bvid = bilibiliBvidFromUrl(normalized);
                                       
  if (bvid == null) {
    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.host.contains('b23.tv')) {
      final resolved = await resolveB23ShortLink(normalized);
      if (resolved != null) bvid = bilibiliBvidFromUrl(resolved);
    }
  }
  if (!context.mounted) return;
  if (bvid != null) {
    openBilibiliVideo(context, bvid: bvid);
    return;
  }
                      
  await openLinkInBuiltInBrowser(context, url: normalized, confirm: confirm);
}

                                         
Future<String?> resolveB23ShortLink(String url) async {
  HttpClient? client;
  try {
    client = HttpClient();
    final req = await client.getUrl(Uri.parse(url));
    final resp = await req.close().timeout(const Duration(seconds: 8));
    final locs = resp.redirects;
    final resolved = locs.isNotEmpty ? locs.last.location.toString() : null;
    await resp.drain<void>();
    return resolved;
  } catch (_) {
    return null;
  } finally {
    client?.close(force: true);
  }
}

                                                   
Duration? bilibiliTimeFromUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final t = uri.queryParameters['t'];
  if (t == null || t.isEmpty) return null;
                          
  final secs = double.tryParse(t);
  if (secs != null && secs > 0) {
    return Duration(milliseconds: (secs * 1000).round());
  }
                                
  int part(String unit) {
    final m = RegExp('(\\d+)$unit').firstMatch(t);
    return m == null ? 0 : int.tryParse(m.group(1)!) ?? 0;
  }

  final total = part('h') * 3600 + part('m') * 60 + part('s');
  if (total > 0) return Duration(seconds: total);
  return null;
}

                                                                    
const double _tabBarHeight = 45.0;

                                       
                              
const Curve _videoHeroCurve = Curves.easeInOutCubic;

                                                          
const double _kPlayerCollapsedHeight = 56.0;

                                                 
class _VideoCommentsNavObserver extends NavigatorObserver {
  final VoidCallback onChange;
  _VideoCommentsNavObserver(this.onChange);
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChange();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChange();
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChange();
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      onChange();
}

class BilibiliVideoPage extends StatefulWidget implements ImmersivePageMarker {
  final String bvid;
  final String? initialTitle;
  final String? initialCover;

                                            
  final String? heroTag;

                                              
  final Duration? initialPosition;

                                     
                                       
                                        
  final bool wideClassic;

                                                                   
  final int? commentRootId;

                                                 
  final int? commentSecondaryId;

                                                      
              
  final int? initialCid;

                                                  
                                 
  final int? initialPage;

                              
     
                                  
                                                             
                                    
                                                                
                                                  
  final bool startFullscreen;

  const BilibiliVideoPage({
    super.key,
    required this.bvid,
    this.initialTitle,
    this.initialCover,
    this.heroTag,
    this.initialPosition,
    this.wideClassic = false,
    this.commentRootId,
    this.commentSecondaryId,
    this.initialCid,
    this.initialPage,
    this.startFullscreen = false,
  });
  @override
  State<BilibiliVideoPage> createState() => _BilibiliVideoPageState();
}

class _BilibiliVideoPageState extends State<BilibiliVideoPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
                                  
  final GlobalKey<MpvPlayerPageState> _playerKey =
      GlobalKey<MpvPlayerPageState>();

                                      
  bool _exitUnloadLock = false;
                                         
                      
  final GlobalKey<NavigatorState> _commentsNavKey = GlobalKey<NavigatorState>();
                                        
  final ValueNotifier<int> _commentPostedTick = ValueNotifier(0);
                                             
                                                     
  bool _replyPageOpen = false;
  late final NavigatorObserver _commentsNavObserver = _VideoCommentsNavObserver(
    _onCommentsNavChanged,
  );

                                                     
                                      
  late final TabController _mediaTab;
  void _onCommentsNavChanged() {
    final canPop = _commentsNavKey.currentState?.canPop() ?? false;
    if (canPop != _replyPageOpen) {
      _replyPageOpen = canPop;
      if (mounted) setState(() {});
    }
  }

  final DanmakuController _danmaku = DanmakuController();
                                                            
  late final AnimationController _tripleController;
  Timer? _tripleTimer;                            
                                           
  late final AnimationController _expandController;
  double _expandStartCollapse = 0;              
  BiliVideoDetail? _detail;
  BiliPlayUrl? _playUrl;

                                      
                                             
     
                                                             
                             
  List<BiliSubtitle> _biliSubtitles = const [];

                                    
  int _subtitleCid = 0;

  String? _error;
  bool _loading = true;
  bool _loadingPlayUrl = false;

                                       
                                     
  int _startedPageIndex = -1;

                                    
  String? _startedUrl;

                                 
  bool _offlineCacheAttempted = false;

                                              
  int get _initialTabIndex => (widget.commentRootId ?? 0) > 0 ? 1 : 0;

                                               
                                           
  int _ownerFans = 0;
  int _ownerVideos = 0;
  bool _started = false;                      
  bool _fullscreen =
      false;                                                                        
                                           
                                             
  bool _zoomHeroActive = true;
                                 
  bool _isPlaying = false;
                                
  bool _seenPlaying = false;
  StreamSubscription<bool>? _playingSub;
                                       
  bool _controlsVisible = false;
                                                
  bool _onlyPlayAudio = false;
                                        
                                      
  bool _moreMenuOpen = false;
                                       
  bool _memberPanelOpen = false;
                                             
                                                             
  late final AnimationController _memberPanelCtrl;
                          
  bool _memberBackOwned = false;
                                 
  String? _morePageKey;
                              
  late final AnimationController _moreMenuCtrl;
                                 
  late final AnimationController _moreNavCtrl;
                        
  bool _moreBackOwned = false;
                            
  BiliBgmDetail? _bgm;
  String? _bgmMusicId;
                                      
  bool _showPlayButton = false;
  Animation<double>? _routeAnimation;
  AnimationStatusListener? _routeAnimListener;
                                       
                                   
  final ValueNotifier<double> _collapseNotifier = ValueNotifier(0);
  double _playerHeight = 0;                           
              
  int _pageIndex = 0;
  int _currentQn = 0;             
                                       
  Duration _position = Duration.zero;
                    
  String _currentUrl = '';
  Playlist? _fullPlaylist;
  String _videoTitle = '';
                               
  String _translatedDesc = '';
                                   
  bool _descShowOriginal = false;
                                     
  bool _titleShowOriginal = false;
                         
  late int _likeCount;
  late int _coinCount;
  late int _favCount;
  bool _hasLiked = false;
  bool _hasDisliked = false;
  bool _hasFaved = false;
  int _coinGiven = 0;                   
  bool _hasFollowed = false;
  bool _interacting = false;          
  bool _coinWithLike = true;             
          
  List<BiliViewPoint> _viewPoints = [];
           
  int _onlineCount = 0;
  Timer? _onlineTimer;               
                       
  List<BiliVideoTag> _tags = const [];

                                     
  Map<String, String> _translatedTags = const {};
                                      
  bool _introExpanded = false;
          
  final TextEditingController _dmInputController = TextEditingController();

                                  
  bool _cacheChecking = false;
  bool _isCached = false;
  bool _isCaching = false;

  static const Map<String, String> _mediaHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

                                     
                                       
                     
  bool get _isWideScreen =>
      MediaQuery.of(context).size.width >= 768 ||
      MediaQuery.of(context).orientation == Orientation.landscape;

                                               
                         
                                             
  bool get _usesZoomHero =>
      widget.heroTag != null &&
      SettingsService.heroTransitionBlurEnabled &&
      !(widget.wideClassic && _isWideScreen);

                                                
                                                 
                                          
  bool get _zoomHeroBlocksInnerHeroes => _usesZoomHero && _zoomHeroActive;

                                      
  bool _wasPlayingBeforeDrag = false;

                                       
     
                                                     
                                                   
                                    
                                                               
  late final ZoomHeroBackDrag _backDrag = ZoomHeroBackDrag(
                                                          
                                    
                                     
                              
    canDrag: () =>
        !_fullscreen &&
        !_exitUnloadLock &&
        !(_commentsNavKey.currentState?.canPop() ?? false),
    setHeroWrapped: (wrapped) {
                                                 
      if (!_usesZoomHero || _zoomHeroActive == wrapped) return;
      setState(() => _zoomHeroActive = wrapped);
    },
                                             
                            
                                                          
                        
    onDragStart: () {
      _wasPlayingBeforeDrag = _isPlayerPlaying;
      if (_wasPlayingBeforeDrag) {
        unawaited(_playerKey.currentState?.player.pause());
      }
    },
    onDragCancel: () {
      if (!_wasPlayingBeforeDrag) return;
      _wasPlayingBeforeDrag = false;
      unawaited(_playerKey.currentState?.player.play());
    },
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backDrag.attach(context);
  }

  @override
  void initState() {
    super.initState();
                                          
                                                                    
                                                      
                                                        
    _fullscreen = widget.startFullscreen;
                                           
                                                 
                                                                 
    _memberPanelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _moreMenuCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _moreNavCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
                                                 
    WidgetsBinding.instance.addObserver(this);
    _videoTitle = widget.initialTitle ?? '';
                                    
    _mediaTab = TabController(
      length: 2,
      vsync: this,
      initialIndex: _initialTabIndex,
    );
                              
    _danmaku.restoreSettings();
                                      
    _tripleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      reverseDuration: const Duration(milliseconds: 400),
    );
    _tripleController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _tripleController.reset();
        _doTriple();
      }
    });
                                      
    _expandController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 320),
        )..addListener(() {
          final t = Curves.easeOutCubic.transform(_expandController.value);
          _collapseNotifier.value = _expandStartCollapse * (1 - t);
        });
    _loadDetail();
                                        
                              
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _routeAnimation = ModalRoute.of(context)?.animation;
      final anim = _routeAnimation;
      if (anim == null || anim.isCompleted) {
        setState(() {
          _showPlayButton = true;
          _zoomHeroActive = false;
        });
        return;
      }
      _routeAnimListener = (status) {
        if (status == AnimationStatus.completed && mounted) {
          _routeAnimation?.removeStatusListener(_routeAnimListener!);
          _routeAnimListener = null;
          setState(() {
            _showPlayButton = true;
                                              
            _zoomHeroActive = false;
          });
        }
      };
      anim.addStatusListener(_routeAnimListener!);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
                                    
    unawaited(NativeMenuService.hideMenu());
    _memberPanelCtrl.dispose();
    _moreMenuCtrl.dispose();
    _moreNavCtrl.dispose();
    _backDrag.detach();
    if (_routeAnimListener != null) {
      _routeAnimation?.removeStatusListener(_routeAnimListener!);
      _routeAnimListener = null;
    }
                           
    if (_fullscreen && (Platform.isAndroid || Platform.isIOS)) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
    }
                                         
                                    
    if (widget.startFullscreen && (Platform.isAndroid || Platform.isIOS)) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    _onlineTimer?.cancel();
    _playingSub?.cancel();
    _tripleTimer?.cancel();
    _tripleController.dispose();
    _expandController.dispose();
    _dmInputController.dispose();
    _danmaku.dispose();
    _collapseNotifier.dispose();
    _mediaTab.dispose();
    super.dispose();
  }

                            
  final Object _taskbarLoadingToken = Object();

  Future<void> _loadDetail() async {
    TaskbarProgress.begin(_taskbarLoadingToken);
    try {
      await _loadDetailImpl();
    } finally {
      TaskbarProgress.end(_taskbarLoadingToken);
    }
  }

  Future<void> _loadDetailImpl() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final detail = await BilibiliVideoService.fetchDetail(widget.bvid);
    if (!mounted) return;
    if (!mounted) return;
    if (detail == null) {
      setState(() {
        _loading = false;
        _error =
            BilibiliVideoService.lastErrorDetail ??
            AppLocalizations.of(context).biliLoadFailed;
      });
      return;
    }
                                                    
                                    
                                          
    final forcedPart = _resolveInitialPartIndex(detail);
    if (forcedPart != null) {
      _pageIndex = forcedPart;
      _position = widget.initialPosition ?? Duration.zero;
    } else if (widget.initialPosition != null) {
      _position = widget.initialPosition!;
    } else {
      _restoreProgressFromHistory(detail);
    }

    setState(() {
      _detail = detail;
      _videoTitle = detail.title;
      _loading = false;
      _likeCount = detail.like;
      _coinCount = detail.coin;
      _favCount = detail.favorite;
      _ownerFans = detail.ownerFans;
      _ownerVideos = detail.ownerVideos;
    });
                                                 
    _loadRelation();
                                 
    _loadOwnerStats();
    _loadTags();
    _loadOnlineCount();
    _checkCached();
                                    
                                         
    _recordWatchHistoryOnEnter(detail);
                                             
                                          
                                                   
                                                        
                                          
    if (widget.startFullscreen) {
      unawaited(_startPlayback());
    }
                                 
    _translateDetail(detail);
  }

                                                   
  int? _resolveInitialPartIndex(BiliVideoDetail detail) {
    if (detail.pages.isEmpty) return null;
    final cid = widget.initialCid;
    if (cid != null) {
      final i = detail.pages.indexWhere((p) => p.cid == cid);
      if (i >= 0) return i;
    }
    final page = widget.initialPage;
    if (page != null && page >= 0 && page < detail.pages.length) return page;
    return null;
  }

                                     
  Future<void> _translateDetail(BiliVideoDetail detail) async {
    try {
      final translate = context.read<BilibiliTranslateService>();
      if (!translate.enabled) return;
                                       
      final cached = BilibiliTitleCache.translatedTitle(detail.bvid);
      if (cached != null && mounted && cached != detail.title) {
        setState(() => _videoTitle = cached);
      }
      final res = await BilibiliTranslateApi.translateVideoTitle(
        aid: detail.aid,
        title: detail.title,
        desc: detail.desc,
      );
      if (!mounted || res == null) return;
      final newTitle = res.title.isNotEmpty ? res.title : res.originalTitle;
      final newDesc = res.desc.isNotEmpty ? res.desc : res.originalDesc;
      BilibiliTitleCache.remember(detail.bvid, detail.title, newTitle);
      if (newTitle != detail.title || newDesc != detail.desc) {
        setState(() {
          if (newTitle.isNotEmpty) _videoTitle = newTitle;
          if (newDesc.isNotEmpty) _translatedDesc = newDesc;
        });
      }
    } catch (_) {
                   
    }
  }

                  
                                                                          
                                       
  void _restoreProgressFromHistory(BiliVideoDetail detail) {
    if (detail.pages.isEmpty) return;
    try {
      final history = context.read<PlayHistoryService>();
      final prefix = 'bili_${detail.bvid}_';
      final records = history.findByIdPrefix(prefix);
      if (records.isEmpty) return;
      records.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      final best = records.first;
      final cidStr = best.id.substring(prefix.length);
      final cid = int.tryParse(cidStr);
      if (cid != null) {
        final idx = detail.pages.indexWhere((p) => p.cid == cid);
        if (idx >= 0) _pageIndex = idx;
      }
      if (best.positionMs > 3000) {
        _position = Duration(milliseconds: best.positionMs);
      }
    } catch (e) {
      debugPrint('⚠️ 恢复播放进度失败: $e');
    }
  }

                                        
  Future<void> _loadTags() async {
    final detail = _detail;
    if (detail == null) return;
    final tags = await BilibiliVideoService.fetchVideoTags(
      bvid: detail.bvid,
      aid: detail.aid,
    );
    if (!mounted || tags.isEmpty) return;
    setState(() => _tags = tags);
                                           
    unawaited(_loadBgmEntry(tags));
                                  
    try {
      final translate = context.read<BilibiliTranslateService>();
      if (!translate.enabled) return;
      final map = await BilibiliTranslateApi.translateVideoTags(
        aid: detail.aid,
        tags: [for (final t in tags) t.name],
      );
      if (!mounted || map.isEmpty) return;
      setState(() => _translatedTags = map);
    } catch (_) {}
  }

                                                 
                                  
  Future<void> _loadBgmEntry(List<BiliVideoTag> tags) async {
    BiliVideoTag? bgm;
    for (final t in tags) {
      if (t.type == 'bgm' && t.musicId.isNotEmpty) {
        bgm = t;
        break;
      }
    }
    if (bgm == null) return;
    if (_bgmMusicId == bgm.musicId) return;
    _bgmMusicId = bgm.musicId;
    final detail = await BilibiliMusicService.fetchDetail(bgm.musicId);
    if (!mounted || detail == null) return;
    setState(() => _bgm = detail);
  }

                                            
  Widget _buildBgmEntry(ColorScheme cs) {
    final bgm = _bgm!;
    final l10n = AppLocalizations.of(context);
    final cover = bgm.cover.isNotEmpty ? bgm.cover : (_detail?.pic ?? '');
    final left = <String>[
      if (bgm.artistText.isNotEmpty) bgm.artistText,
      if (bgm.relationCount > 0) l10n.videoBgmUsedCount('${bgm.relationCount}'),
    ].join(' · ');
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BilibiliMusicPage(musicId: bgm.musicId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: cover.isEmpty
                    ? Container(
                        width: 46,
                        height: 46,
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 22,
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : Image(
                        image: CachedImageProvider(
                          cover,
                          headers:
                              NetworkSettingsService.instance.apiHeaders.isEmpty
                              ? null
                              : NetworkSettingsService.instance.apiHeaders,
                                                    
                          cacheWidth: 144,
                        ),
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 46,
                          height: 46,
                          color: cs.surfaceContainerHighest,
                          child: Icon(
                            Icons.music_note_rounded,
                            size: 22,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.audiotrack_rounded,
                          size: 12,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'BGM',
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bgm.title.isEmpty ? 'BGM' : bgm.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    if (left.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

                                              
     
                                                       
                                                          
                 
  Future<void> _loadSubtitles({required int cid}) async {
    final detail = _detail;
    if (detail == null || cid <= 0) return;
    _subtitleCid = cid;
    final list = await BilibiliVideoService.fetchSubtitles(
      bvid: detail.bvid,
      aid: detail.aid,
      cid: cid,
    );
    if (!mounted || _subtitleCid != cid) return;              
    if (list.isEmpty && _biliSubtitles.isEmpty) return;           
    setState(() => _biliSubtitles = list);
  }

                                                 
  Future<void> _loadOwnerStats() async {
    final detail = _detail;
    if (detail == null) return;
    final stats = await BilibiliVideoService.fetchOwnerStats(detail.ownerMid);
    if (!mounted || stats == null) return;
    if (stats.$1 == _ownerFans && stats.$2 == _ownerVideos) return;
    setState(() {
      _ownerFans = stats.$1;
      _ownerVideos = stats.$2;
    });
  }

                                          
  Future<void> _loadRelation() async {
    final detail = _detail;
    if (detail == null) return;
    if (BilibiliAccountService.instance.cookieHeaderFor(
          BiliCookieScope.interactions,
        ) ==
        null) {
      return;
    }
    final relation = await BilibiliInteractionService.fetchVideoRelation(
      aid: detail.aid,
      bvid: detail.bvid,
    );
    if (!mounted || relation == null) return;
    setState(() {
      _hasLiked = relation.like;
      _hasDisliked = relation.dislike;
      _hasFaved = relation.favorite;
      _coinGiven = relation.coin;
      _hasFollowed = relation.attention;
    });
  }

                 

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    showAppToast(context, msg, error: error);
  }

                                            
                      
  Future<bool> _ensureCanInteract() async {
    final account = BilibiliAccountService.instance;
    if (account.cookieHeaderFor(BiliCookieScope.interactions) != null) {
      return true;
    }
    if (!account.isLoggedIn) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context).biliDialogNeedLogin),
          content: Text(AppLocalizations.of(context).biliDialogInteractDesc),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(context).commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppLocalizations.of(context).biliGoLogin),
            ),
          ],
        ),
      );
      if (go == true && mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BilibiliLoginScreen()));
      }
      if (mounted) {
                      
        await _loadRelation();
      }
      return BilibiliAccountService.instance.cookieHeaderFor(
            BiliCookieScope.interactions,
          ) !=
          null;
    }
    _toast(AppLocalizations.of(context).biliCookieScopeHint, error: true);
    return false;
  }

                
  Future<void> _toggleLike() async {
    if (_interacting) return;
    final detail = _detail;
    if (detail == null) return;
    if (!await _ensureCanInteract()) return;
    final target = !_hasLiked;
    setState(() => _interacting = true);
    final result = await BilibiliInteractionService.likeVideo(
      aid: detail.aid,
      like: target,
    );
    if (!mounted) return;
    setState(() => _interacting = false);
    if (result.ok) {
      setState(() {
        _hasLiked = target;
        if (target) _hasDisliked = false;           
        _likeCount = (_likeCount + (target ? 1 : -1)).clamp(0, 0x7fffffff);
      });
      _toast(target ? '已点赞' : '已取消点赞');
    } else {
      _toast('点赞失败：${result.message}', error: true);
    }
  }

                                                    
  Future<void> _toggleDislike() async {
    if (_interacting) return;
    final detail = _detail;
    if (detail == null) return;
    if (!await _ensureCanInteract()) return;
    final target = !_hasDisliked;
    setState(() => _interacting = true);
    final result = await BilibiliInteractionService.dislikeVideo(
      aid: detail.aid,
      dislike: target,
    );
    if (!mounted) return;
    setState(() => _interacting = false);
    if (result.ok) {
      setState(() {
        _hasDisliked = target;
        if (target && _hasLiked) {
                              
          _hasLiked = false;
          _likeCount = (_likeCount - 1).clamp(0, 0x7fffffff);
        }
      });
      _toast(target ? '已点踩' : '已取消点踩');
    } else {
      _toast('点踩失败：${result.message}', error: true);
    }
  }

                         
  Future<void> _doTriple() async {
    if (_interacting) return;
    final detail = _detail;
    if (detail == null) return;
    if (_hasLiked && _coinGiven > 0 && _hasFaved) {
      _toast('已完成三连');
      return;
    }
    if (!await _ensureCanInteract()) return;
    setState(() => _interacting = true);
    final result = await BilibiliInteractionService.tripleLike(aid: detail.aid);
    if (!mounted) return;
    setState(() => _interacting = false);
    if (result.ok) {
      final triple = result.data;
      setState(() {
        if (triple == null || triple.like) {
          if (!_hasLiked) _likeCount++;
          _hasLiked = true;
        }
        if (triple == null || triple.coin) {
          final coins = triple?.multiply ?? 1;
          _coinGiven += coins;
          _coinCount += coins;
        }
        if (triple == null || triple.fav) {
          if (!_hasFaved) _favCount++;
          _hasFaved = true;
        }
      });
      _toast('三连成功');
    } else {
      _toast('三连失败：${result.message}', error: true);
    }
  }

                                             

              
  bool get _hasTriple => _hasLiked && _coinGiven > 0 && _hasFaved;

                                      
  void _onLikeTapDown(TapDownDetails _) {
    if (_interacting) return;
    if (_hasTriple) {
      _toast('已完成三连');
      return;
    }
    _tripleTimer ??= Timer(const Duration(milliseconds: 255), () {
      _tripleTimer = null;
      if (!mounted) return;
      HapticFeedback.lightImpact();
      _tripleController.forward();
    });
  }

                                
                               
  void _onLikeTapUp(TapUpDetails _) {
    if (_tripleTimer != null) {
      _tripleTimer!.cancel();
      _tripleTimer = null;
      _toggleLike();
    } else if (_tripleController.isAnimating) {
      _tripleController.reverse();
    }
  }

                         
  void _onLikeTapCancel() {
    if (_tripleTimer != null) {
      _tripleTimer!.cancel();
      _tripleTimer = null;
    } else if (_tripleController.isAnimating) {
      _tripleController.reverse();
    }
  }

                                                        
                               
                               
  Future<void> _openCoinDialog() async {
    if (_interacting) return;
    final detail = _detail;
    if (detail == null) return;
    final coins = await BilibiliInteractionService.fetchMyCoins();
    if (!mounted) return;
    final remaining = (2 - _coinGiven).clamp(0, 2);
    if (remaining <= 0) {
      _toast('已达投币上限');
      return;
    }
    await PayCoinsPage.toPayCoinsPage(
      context,
      onPayCoin: (coin, withLike) => _doPayCoin(coin, withLike, coins),
      hasCoin: _coinGiven >= 1,
      hasCopyright: true,
      coins: coins,
      coinWithLike: _coinWithLike,
    );
  }

                                         
  Future<void> _doPayCoin(int multiply, bool withLike, num? coins) async {
    final detail = _detail;
    if (detail == null || _interacting) return;
                                           
    if (!await _ensureCanInteract()) return;
    if (coins != null && coins < multiply) {
      _toast('硬币不足', error: true);
      return;
    }
    _coinWithLike = withLike;
    setState(() => _interacting = true);
    final result = await BilibiliInteractionService.coinVideo(
      aid: detail.aid,
      multiply: multiply,
      selectLike: withLike,
    );
    if (!mounted) return;
    setState(() => _interacting = false);
    if (result.ok) {
      setState(() {
        _coinGiven += multiply;
        _coinCount += multiply;
        if (withLike && !_hasLiked) {
          _hasLiked = true;
          _likeCount++;
        }
      });
      _toast('投币成功');
    } else {
      _toast('投币失败：${result.message}', error: true);
    }
  }

                                
  Future<void> _toggleFav() async {
    if (_interacting) return;
    final detail = _detail;
    if (detail == null) return;
    if (!await _ensureCanInteract()) return;
    setState(() => _interacting = true);
    if (_hasFaved) {
      final result = await BilibiliInteractionService.unfavoriteAll(
        aid: detail.aid,
      );
      if (!mounted) return;
      setState(() => _interacting = false);
      if (result.ok) {
        setState(() {
          _hasFaved = false;
          _favCount = (_favCount - 1).clamp(0, 0x7fffffff);
        });
        _toast('已取消收藏');
      } else {
        _toast('取消收藏失败：${result.message}', error: true);
      }
      return;
    }
                    
    final folders = await BilibiliFavoriteService.fetchFolders(
      mid: BilibiliInteractionService.accountMid,
      rid: detail.aid,
      type: 2,
    );
    if (!mounted) return;
    if (folders == null) {
      setState(() => _interacting = false);
      _toast('获取收藏夹失败，请先在收藏夹页面创建', error: true);
      return;
    }
    var folder =
        folders.where((f) => f.favState == 0).firstOrNull ??
        folders.firstOrNull;
    if (folder == null) {
      setState(() => _interacting = false);
      _toast('请先在收藏夹页面创建收藏夹', error: true);
      return;
    }
    final result = await BilibiliFavoriteService.addVideoToFavorites(
      aid: detail.aid,
      addIds: [folder.id],
    );
    if (!mounted) return;
    setState(() => _interacting = false);
    if (result.ok) {
      setState(() {
        _hasFaved = true;
        _favCount++;
      });
      _toast('收藏成功');
    } else {
      _toast('收藏失败：${result.message}', error: true);
    }
  }

                     
  Future<void> _toggleFollow() async {
    if (_interacting) return;
    final detail = _detail;
    if (detail == null) return;
    if (!await _ensureCanInteract()) return;
    final target = !_hasFollowed;
    setState(() => _interacting = true);
    final result = await BilibiliInteractionService.followUser(
      mid: detail.ownerMid,
      act: target ? 1 : 2,
    );
    if (!mounted) return;
    setState(() => _interacting = false);
    if (result.ok) {
      setState(() => _hasFollowed = target);
      _toast(target ? '已关注' : '已取消关注');
    } else {
      _toast('操作失败：${result.message}', error: true);
    }
  }

                                 

                
  String? get _shareUrl {
    final detail = _detail;
    if (detail == null) return null;
    return 'https://www.bilibili.com/video/${detail.bvid}';
  }

                                       
  String? get _shareUrlWithTime {
    final base = _shareUrl;
    if (base == null) return null;
    if (_started && _position.inMilliseconds > 0) {
      final sec = (_position.inMilliseconds / 1000).round();
      return '$base?t=$sec';
    }
    return base;
  }

                              
  Future<void> _copyShareLink() async {
    final url = _shareUrlWithTime;
    if (url == null) return;
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      _toast(L10n.current.playerCopyLinkDone(url));
    } catch (e) {
      debugPrint('❌ 复制链接失败: $e');
      _toast('复制失败：$e', error: true);
    }
  }

                                        
  void _openShareInBrowser() {
    final url = _shareUrl;
    if (url == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrowserPage(
          initialUrl: url,
          title: _videoTitle.isEmpty
              ? AppLocalizations.of(context).browserLinkPageTitle
              : _videoTitle,
        ),
      ),
    );
  }

                     
  void _shareVideo() {
    final url = _shareUrl;
    if (url == null) return;
    SharePlus.instance.share(
      ShareParams(text: url, subject: _videoTitle.isEmpty ? null : _videoTitle),
    );
  }

                                          
                               
  void _openShareMenu() {
    showFrostedActionSheet(
      context,
      cover: _detail?.pic,
      title: _videoTitle,
      subtitle: _detail?.ownerName,
      actions: [
        GlassMenuAction(
          icon: Icons.copy_rounded,
                                        
          text: _started && _position.inMilliseconds > 0
              ? L10n.current.playerCopyLinkAt(
                  _fmtSec(_position.inMilliseconds ~/ 1000),
                )
              : L10n.current.playerCopyLink,
          onTap: _copyShareLink,
        ),
        GlassMenuAction(
          icon: Icons.public,
          text: L10n.current.articleOpenBrowser,
          onTap: _openShareInBrowser,
        ),
        GlassMenuAction(
          icon: Icons.share_outlined,
          text: L10n.current.articleShare,
          onTap: _shareVideo,
        ),
        GlassMenuAction(
          icon: Icons.auto_awesome,
          text: 'AI 总结',
          onTap: _showAiSummary,
        ),
      ],
    );
  }

                                         
  Future<void> _showAiSummary() async {
    final detail = _detail;
    if (detail == null || detail.bvid.isEmpty) return;
    final page = detail.pages.isEmpty ? null : detail.pages[_pageIndex];
    final cid = page?.cid ?? 0;
    if (cid <= 0) return;
    if (!BilibiliAccountService.instance.isLoggedIn) {
      showAppToast(context, '请先登录后再使用 AI 总结');
      return;
    }
    showAppToast(context, '正在获取 AI 总结…');
    final res = await BilibiliVideoService.fetchAiConclusion(
      bvid: detail.bvid,
      cid: cid,
      upMid: detail.ownerMid,
    );
    if (!mounted) return;
    if (res.data == null) {
      showAppToast(
        context,
        res.message.isNotEmpty ? res.message : '当前视频暂不支持 AI 总结',
        error: true,
      );
      return;
    }
    await showAiConclusionSheet(context, data: res.data!, onSeek: _seekFromUgc);
  }

                                     
                                                 
                                      
                              
  void _seekFromUgc(Duration position) {
    final state = _playerKey.currentState;
    if (state == null) {
      _position = position;
      _startPlayback();
      return;
    }
    state.player.seek(position);
    if (!state.player.state.playing) state.player.play();
  }

  Future<void> _startPlayback() async {
                                            
                                    
    if (_started || _loadingPlayUrl) return;
    final detail = _detail;
    if (detail == null || detail.pages.isEmpty) return;
    final page = detail.pages[_pageIndex];
    setState(() {
      _loadingPlayUrl = true;
      _error = null;
    });
    final play = await BilibiliVideoService.fetchPlayUrl(
      bvid: detail.bvid,
      cid: page.cid,
      qn: _currentQn,
    );
    if (!mounted) return;
    if (play == null) {
      setState(() {
        _loadingPlayUrl = false;
        _error = BilibiliVideoService.lastErrorDetail ?? '解析播放地址失败';
      });
      return;
    }
    _playUrl = play;
                                                 
    unawaited(_loadSubtitles(cid: page.cid));
                     
    if (_currentQn == 0 && play.quality > 0) {
      _currentQn = play.quality;
    }
    final url = BilibiliVideoService.buildPlayableUrl(play);
    if (!mounted) return;
    if (url == null) {
      setState(() {
        _loadingPlayUrl = false;
        _error = '无可用播放地址';
      });
      return;
    }
    _startedPageIndex = _pageIndex;
    _startedUrl = url;
    _offlineCacheAttempted = false;
                                        
                                                               
                                                          
    final localUrl = await ManualVideoCache.localPlayableUrlAny(
      detail.bvid,
      page.cid,
    );
    if (!mounted) return;
    final effectiveUrl = localUrl ?? url;
                                 
                                      
                                                 
                              
    final urls = <int, String?>{_pageIndex: effectiveUrl};
    final pending = <int, Future<BiliPlayUrl?>>{};
    for (var i = 0; i < detail.pages.length; i++) {
      if (i == _pageIndex) continue;
      final p = detail.pages[i];
      pending[i] = BilibiliVideoService.fetchPlayUrl(
        bvid: detail.bvid,
        cid: p.cid,
        qn: _currentQn,
      );
    }
                                
                             
    for (final e in pending.entries) {
      final pu = await e.value;
      if (pu == null) continue;
      final u = BilibiliVideoService.buildPlayableUrl(pu);
      if (u != null) urls[e.key] = u;
    }
    if (!mounted) return;
    final items = <PlaylistItem>[];
    for (var i = 0; i < detail.pages.length; i++) {
      final u = urls[i];
      if (u == null) continue;
      final p = detail.pages[i];
      items.add(
        PlaylistItem(
          id: 'bili_${p.cid}',
          url: u,
          title: p.part.isNotEmpty ? p.part : 'P${p.page}',
          index: i,
          danmakuSource: p.cid.toString(),
          danmakuType: 'cid',
        ),
      );
    }
    setState(() {
      _currentUrl = effectiveUrl;
      _fullPlaylist = items.isEmpty
          ? null
          : Playlist(
              id: 'bili_${detail.bvid}',
              name: detail.title,
              items: items,
            );
      _error = null;
      _loadingPlayUrl = false;
      _started = true;
    });
    _loadViewPoints(detail.aid, page.cid);
    _loadOnlineCount();
                                  
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final st = _playerKey.currentState;
      if (st == null) return;
      _playingSub?.cancel();
      _playingSub = st.player.stream.playing.listen((playing) {
        if (!mounted) return;
        if (playing) _seenPlaying = true;
                                         
                                         
        if (playing &&
            _collapseNotifier.value != 0 &&
            !_expandController.isAnimating) {
          _collapseNotifier.value = 0;
        }
        if (playing != _isPlaying) setState(() => _isPlaying = playing);
      });
      if (st.player.state.playing) _seenPlaying = true;
      if (st.player.state.playing != _isPlaying) {
        setState(() => _isPlaying = st.player.state.playing);
      }
      if (st.showControls != _controlsVisible) {
        setState(() => _controlsVisible = st.showControls);
      }
    });
  }

                        
  void _resumeFromPause() {
    _playerKey.currentState?.player.play();
  }

                                       
                                 
                                    
  Future<void> _cacheCurrentStreamIfWatched(Duration position) async {
    if (_offlineCacheAttempted ||
        position < VideoStreamCache.downloadAfterPlayed) {
      return;
    }
    if (!SettingsService.autoOfflineCacheEnabled) return;
    final detail = _detail;
    final play = _playUrl;
    final url = _startedUrl;
    if (detail == null || play == null || url == null) return;
    final pageIndex = _startedPageIndex;
    if (pageIndex < 0 || pageIndex >= detail.pages.length) return;
    final page = detail.pages[pageIndex];
    _offlineCacheAttempted = true;
                                  
    if (await ManualVideoCache.isCachedAny(detail.bvid, page.cid)) return;
    if (url.startsWith('edl://')) {
      final parsed = VideoStreamCache.parseEdl(url);
      if (parsed == null) return;
      await VideoStreamCache.cacheDash(
        bvid: detail.bvid,
        cid: page.cid,
        videoUrl: parsed.a,
        audioUrl: parsed.b,
        qn: play.quality,
                                        
        cover: detail.pic,
      );
    } else {
      await VideoStreamCache.cacheDurl(
        bvid: detail.bvid,
        cid: page.cid,
        url: url,
        qn: play.quality,
        cover: detail.pic,
      );
    }
    if (mounted) _checkCached();
  }

                                                 
  Future<void> _checkCached() async {
    final detail = _detail;
    if (detail == null || detail.pages.isEmpty) return;
    final cid = detail.pages[_pageIndex].cid;
    if (ManualVideoCache.anyDownloading(detail.bvid, cid)) {
      if (mounted) {
        setState(() {
          _isCaching = true;
          _isCached = false;
        });
      }
      return;
    }
    setState(() => _cacheChecking = true);
    final cached = await ManualVideoCache.isCachedAny(detail.bvid, cid);
    if (!mounted) return;
    setState(() {
      _cacheChecking = false;
      _isCached = cached;
      _isCaching = ManualVideoCache.anyDownloading(detail.bvid, cid);
    });
  }

                                                          
  Future<void> _manualCache() async {
    final detail = _detail;
    if (detail == null) return;
    if (detail.pages.isEmpty) return;
    if (_isCached) {
      showAppToast(context, L10n.current.cacheToastCached);
      return;
    }
    if (_isCaching) {
      showAppToast(context, L10n.current.cacheActionCaching);
      return;
    }
                       
    String? url = _startedUrl;
    int cid = detail.pages[_pageIndex].cid;
    int qn = _currentQn != 0 ? _currentQn : (_playUrl?.quality ?? 0);
    String cover = detail.pic;
                    
    if (url == null || _startedPageIndex != _pageIndex) {
      setState(() => _isCaching = true);
      final play = await BilibiliVideoService.fetchPlayUrl(
        bvid: detail.bvid,
        cid: cid,
        qn: qn,
      );
      if (!mounted) return;
      if (play == null) {
        setState(() => _isCaching = false);
        showAppToast(
          context,
          L10n.current.cacheToastFailed(
            BilibiliVideoService.lastErrorDetail ?? '解析失败',
          ),
          error: true,
        );
        return;
      }
      url = BilibiliVideoService.buildPlayableUrl(play);
      if (url == null) {
        setState(() => _isCaching = false);
        showAppToast(
          context,
          L10n.current.cacheToastFailed('无播放地址'),
          error: true,
        );
        return;
      }
                    
      _playUrl = play;
      _startedUrl = url;
      _startedPageIndex = _pageIndex;
    }
    setState(() => _isCaching = true);
    showAppToast(context, L10n.current.cacheToastSuccess);
                             
    final partName = detail.pages[_pageIndex].part;
    final noteTitle = partName.isNotEmpty && partName != detail.title
        ? '${detail.title} · $partName'
        : detail.title;
    try {
      if (url.startsWith('edl://')) {
        final parsed = VideoStreamCache.parseEdl(url);
        if (parsed == null) throw '解析 edl 失败';
                                                        
        await ManualVideoCache.cacheDash(
          bvid: detail.bvid,
          cid: cid,
          videoUrl: parsed.a,
          audioUrl: parsed.b,
          qn: qn,
          cover: cover,
          title: noteTitle,
        );
      } else {
        await ManualVideoCache.cacheDurl(
          bvid: detail.bvid,
          cid: cid,
          url: url,
          qn: qn,
          cover: cover,
          title: noteTitle,
        );
      }
      if (!mounted) return;
      setState(() {
        _isCaching = false;
        _isCached = true;
      });
      showAppToast(context, L10n.current.cacheToastSuccess);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCaching = false);
      showAppToast(
        context,
        L10n.current.cacheToastFailed(e.toString()),
        error: true,
      );
    }
  }

                                             
  Future<void> _recordWatchHistoryOnEnter(BiliVideoDetail detail) async {
    try {
      final settings = context.read<SettingsService>();
      if (settings.incognitoMode) return;
      final wh = context.read<WatchHistoryService>();
      final cid = detail.pages.isNotEmpty
          ? detail.pages[_pageIndex.clamp(0, detail.pages.length - 1)].cid
          : null;
                                          
      WatchHistoryEntry? existing;
      if (cid != null) {
        final key = '${detail.bvid}:$cid';
        try {
          existing = wh.entries.firstWhere((e) => e.key == key);
        } catch (_) {
          existing = wh.findByBvid(detail.bvid);
        }
      } else {
        existing = wh.findByBvid(detail.bvid);
      }
      final entry = WatchHistoryEntry(
        bvid: detail.bvid,
        aid: detail.aid,
        cid: cid,
        title: detail.title,
        coverUrl: detail.pic,
        upperName: detail.ownerName,
        positionMs: existing?.positionMs ?? 0,
        durationMs: existing?.durationMs ?? 0,
        watchedAt: DateTime.now(),
        finished: existing?.finished ?? false,
      );
      await wh.record(entry, force: true);
    } catch (e) {
      debugPrint('⚠️ 进入页记录历史失败: $e');
    }
  }

                                                               
  Widget _buildTvButton(double btnSize) {
    final iconSize = btnSize - 24;                  
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _resumeFromPause,
        splashColor: Colors.white.withValues(alpha: 0.25),
        highlightColor: Colors.white.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SvgPicture.asset(
            'assets/bili_icons/play.svg',
            width: iconSize,
            height: iconSize,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

                                             
  void _toggleDanmaku() {
    setState(() => _danmaku.enabled = !_danmaku.enabled);
                           
    _danmaku.onNeedRepaint?.call();
    _danmaku.persistSettings();
  }

                                
  Future<void> _loadViewPoints(int aid, int cid) async {
    final points = await BilibiliVideoService.fetchViewPoints(
      aid: aid,
      cid: cid,
    );
    if (!mounted) return;
    setState(() => _viewPoints = points);
  }

                              
  void _switchPage(int index) {
    final detail = _detail;
    if (detail == null || index < 0 || index >= detail.pages.length) return;
    if (index == _pageIndex) return;
    setState(() {
      _pageIndex = index;
      _position = Duration.zero;
                                        
      _biliSubtitles = const [];
    });
                                       
    unawaited(_loadSubtitles(cid: detail.pages[index].cid));
    _checkCached();
                         
    _recordWatchHistoryOnEnter(detail);
    if (_started) {
      _playerKey.currentState?.switchEpisode(index);
    }
  }

                                     

                               
  bool _isCoverCollapsed(double collapsePx) {
    if (_isWideScreen) return false;
    final maxCollapse = math.max(0.0, _playerHeight - _kPlayerCollapsedHeight);
    return maxCollapse > 0 && collapsePx >= maxCollapse - 1;
  }

                                               
                                              
  bool _onCompactScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is! ScrollUpdateNotification && n is! ScrollEndNotification) {
      return false;
    }
                                
    if (_expandController.isAnimating) {
      _expandController.stop();
    }
    final maxCollapse = math.max(0.0, _playerHeight - _kPlayerCollapsedHeight);
                              
    if (_started && (_playerKey.currentState?.player.state.playing ?? false)) {
      if (_collapseNotifier.value != 0) {
        _collapseNotifier.value = 0;
      }
      return false;
    }
    final target = n.metrics.pixels.clamp(0.0, maxCollapse);
    if ((target - _collapseNotifier.value).abs() > 0.5) {
      _collapseNotifier.value = target;
    }
    return false;
  }

                                               

  String _fmtCount(int n) {
    if (n >= 100000000) return '${(n / 100000000).toStringAsFixed(1)}亿';
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}万';
    return '$n';
  }

  String _fmtDate(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

                                          
  String _fmtSec(int sec) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    if (h > 0) return '$h:${two(m)}:${two(s)}';
    return '$m:${two(s)}';
  }

                                                         
  void _setFullscreen(bool value) {
    if (mounted) {
      setState(() => _fullscreen = value);
    }
                                   
    if (Platform.isAndroid || Platform.isIOS) {
      if (value) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
        );
      }
    }
  }

                                  
  Future<void> _loadOnlineCount() async {
    _onlineTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadOnlineCount(),
    );
    final detail = _detail;
    if (detail == null) return;
    final page = detail.pages[_pageIndex];
    final total = await BilibiliVideoService.fetchOnlineTotal(
      aid: detail.aid,
      bvid: detail.bvid,
      cid: page.cid,
    );
    if (!mounted || total <= 0) return;
    setState(() => _onlineCount = total);
  }

                                              
              
                                              
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final rightWidth = (w * 0.34).clamp(320.0, 480.0);
    final isWide = _isWideScreen;
                             
    final playerWidth = isWide ? (w - rightWidth) : w;
    final playerHeight = playerWidth * 9 / 16;
    _playerHeight = playerHeight;
                                      
    final playerTop = _fullscreen ? 0.0 : MediaQuery.of(context).padding.top;

                                                 
                                       
    final playerWidget = MpvPlayerPage(
      key: _playerKey,
      mode: _fullscreen ? PlayerPageMode.fullscreen : PlayerPageMode.videoPage,
      videoUrl: _currentUrl,
      title: _pageTitle(),
                               
      artist: _detail?.ownerName,
      httpHeaders: _mediaHeaders,
      danmakuSource:
          ((_detail?.pages.isNotEmpty ?? false)
                  ? _detail!.pages[_pageIndex].cid
                  : 0)
              .toString(),
      danmakuType: 'cid',
      playlist: _fullPlaylist,
      initialEpisodeIndex: _pageIndex,
      initialPosition: _position,
                                   
      danmakuController: _danmaku,
      playUrlInfo: _playUrl,
                                                   
      biliSubtitles: _biliSubtitles,
      initialQualityQn: _currentQn > 0 ? _currentQn : null,
      viewPoints: _viewPoints,
                                            
      isInteractiveVideo: (_detail?.isSteinGate ?? false),
                                    
      artUri: _detail?.pic,
                          
      bilibiliBvid: _detail?.bvid,
                                         
      historyId: _currentHistoryId,
      onPositionChanged: (p) {
        _position = p;
                                            
        _cacheCurrentStreamIfWatched(p);
      },
      onQualityChanged: (qn) => _currentQn = qn,
      onEpisodeChanged: (i) => setState(() => _pageIndex = i),
      onDanmakuCountChanged: (_) => setState(() {}),
      onFullscreenRequested: () => _setFullscreen(true),
      onExitFullscreenRequested: () => _setFullscreen(false),
      onControlsVisibilityChanged: (v) {
        if (mounted && _controlsVisible != v) {
          setState(() => _controlsVisible = v);
        }
      },
                                    
      onOnlyPlayAudioChanged: (v) {
        if (mounted && _onlyPlayAudio != v) {
          setState(() => _onlyPlayAudio = v);
        }
      },
                                       
                                       
                                       
      onListenPageRequested: _fullscreen
          ? null
          : () => unawaited(_openAudioPage()),
      onMoreMenuRequested: _fullscreen ? null : _toggleMoreMenu,
    );

    Widget page = Scaffold(
                                         
      backgroundColor: cs.surfaceContainerLow,
      body: Stack(
        fit: StackFit.expand,
        children: [
                                       
          Offstage(
            offstage: _fullscreen,
            child: SafeArea(
              child: isWide ? _buildWideLayout(cs) : _buildCompactLayout(cs),
            ),
          ),
                                              
                                        
          if (_started)
            ValueListenableBuilder<double>(
              valueListenable: _collapseNotifier,
              builder: (context, collapsePx, _) {
                final isFS = _fullscreen;
                final top = isFS ? 0.0 : playerTop;
                final width = isFS ? w : playerWidth;
                if (isFS || isWide) {
                  return Positioned(
                    left: 0,
                    top: top,
                    width: width,
                    height: isFS ? h : playerHeight,
                    child: playerWidget,
                  );
                }
                                  
                final maxCollapse = math.max(
                  0.0,
                  playerHeight - _kPlayerCollapsedHeight,
                );
                final effectiveCollapse = collapsePx.clamp(0.0, maxCollapse);
                final visibleHeight = playerHeight - effectiveCollapse;
                return Positioned(
                  left: 0,
                  top: top,
                  width: playerWidth,
                  height: visibleHeight,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                                                     
                      maxHeight: playerHeight,
                      child: playerWidget,
                    ),
                  ),
                );
              },
            ),
                                     
          if (_started && !_fullscreen && !isWide)
            ValueListenableBuilder<double>(
              valueListenable: _collapseNotifier,
              builder: (context, collapsePx, _) {
                final maxCollapse = math.max(
                  0.0,
                  playerHeight - _kPlayerCollapsedHeight,
                );
                if (maxCollapse <= 0) return const SizedBox.shrink();
                final effectiveCollapse = collapsePx.clamp(0.0, maxCollapse);
                if (effectiveCollapse <= 0) return const SizedBox.shrink();
                final ratio = (effectiveCollapse / maxCollapse).clamp(0.0, 1.0);
                return Positioned(
                  left: 0,
                  top: playerTop,
                  width: playerWidth,
                  height: _kPlayerCollapsedHeight,
                  child: Opacity(
                    opacity: ratio,
                                                           
                                                              
                               
                    child: FrostedPanel(
                      blurSigma: 10,
                      opacity: 0.75,
                      child: _buildCollapsedBarContent(),
                    ),
                  ),
                );
              },
            ),

                                      
                                            
                         
                                                                 
                                                 
                                                    
                                    
          if (_started && !_isPlaying && _seenPlaying && !_controlsVisible)
            ValueListenableBuilder<double>(
              valueListenable: _collapseNotifier,
              builder: (context, collapsePx, _) {
                                
                if (_fullscreen) {
                  return Positioned(
                    left: 0,
                    top: 0,
                    width: w,
                    height: h,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _resumeFromPause,
                      child: const SizedBox.expand(),
                    ),
                  );
                }
                final maxCollapse = math.max(
                  0.0,
                  playerHeight - _kPlayerCollapsedHeight,
                );
                final effectiveCollapse = isWide
                    ? 0.0
                    : collapsePx.clamp(0.0, maxCollapse);
                final ratio = maxCollapse > 0
                    ? (effectiveCollapse / maxCollapse).clamp(0.0, 1.0)
                    : 0.0;
                final visibleHeight = playerHeight - effectiveCollapse;
                                              
                                                
                                       
                final barShown = effectiveCollapse > 0;
                final layerHeight = math.max(
                  0.0,
                  visibleHeight - (barShown ? _kPlayerCollapsedHeight : 0.0),
                );
                if (layerHeight <= 0) return const SizedBox.shrink();
                return Positioned(
                  left: 0,
                  top: barShown
                      ? playerTop + _kPlayerCollapsedHeight
                      : playerTop,
                  width: playerWidth,
                  height: layerHeight,
                  child: Opacity(
                    opacity: (1 - ratio).clamp(0.0, 1.0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _resumeFromPause,
                      child: const SizedBox.expand(),
                    ),
                  ),
                );
              },
            ),
                                         
                                          
                                            
                        
          if (_started &&
              !_fullscreen &&
              !_isPlaying &&
              _seenPlaying &&
              !_controlsVisible)
            ValueListenableBuilder<double>(
              valueListenable: _collapseNotifier,
              builder: (context, collapsePx, _) {
                final maxCollapse = math.max(
                  0.0,
                  playerHeight - _kPlayerCollapsedHeight,
                );
                final effectiveCollapse = isWide
                    ? 0.0
                    : collapsePx.clamp(0.0, maxCollapse);
                final ratio = maxCollapse > 0
                    ? (effectiveCollapse / maxCollapse).clamp(0.0, 1.0)
                    : 0.0;
                return Positioned(
                  left: 8,
                  top: playerTop + 8,
                  child: Opacity(
                    opacity: (1 - ratio).clamp(0.0, 1.0),
                    child: _buildBackButton(transparent: true),
                  ),
                );
              },
            ),
                                                  
                                              
                                                     
          if (_started && !_isPlaying && _seenPlaying)
            ValueListenableBuilder<double>(
              valueListenable: _collapseNotifier,
              builder: (context, collapsePx, _) {
                const btnSize = 60.0;
                                               
                if (_fullscreen) {
                                                 
                                                   
                                                                       
                  final fullscreenBottom = _controlsVisible ? 90.0 : 16.0;
                  return Positioned(
                    left: w - btnSize - 16,
                    top: h - btnSize - fullscreenBottom,
                    child: _buildTvButton(btnSize),
                  );
                }
                final maxCollapse = math.max(
                  0.0,
                  playerHeight - _kPlayerCollapsedHeight,
                );
                final effectiveCollapse = isWide
                    ? 0.0
                    : collapsePx.clamp(0.0, maxCollapse);
                final ratio = maxCollapse > 0
                    ? (effectiveCollapse / maxCollapse).clamp(0.0, 1.0)
                    : 0.0;
                final visibleHeight = playerHeight - effectiveCollapse;
                                         
                final bottomInset = _controlsVisible ? 90.0 : 16.0;
                return Positioned(
                  left: playerWidth - btnSize - 16,
                  top: playerTop + visibleHeight - btnSize - bottomInset,
                  child: Opacity(
                    opacity: (1 - ratio).clamp(0.0, 1.0),
                    child: _buildTvButton(btnSize),
                  ),
                );
              },
            ),
                                          
          if (_moreMenuOpen && !_fullscreen) _buildMoreMenuPanel(cs),
        ],
      ),
    );

                                                     
                                               
                                           
                                                          
                                                      
    if (_usesZoomHero) {
      page = KeyedSubtree(key: _backDrag.bodyKey, child: page);
    }

                                              
                                                
                                     
                                  
    if (_usesZoomHero && _zoomHeroActive) {
                                        
                                            
                                                  
      final Curve? gestureCurve = HeroGestureCurve.curveOrNull(context);
      page = Hero(
        transitionOnUserGestures: true,
        tag: widget.heroTag!,
        curve: gestureCurve ?? _videoHeroCurve,
        reverseCurve: gestureCurve ?? _videoHeroCurve,
                                          
                                       
        placeholderBuilder: _backDrag.placeholder,
                                                            
                                                      
                                                           
                                                 
                                               
        flightShuttleBuilder:
            (flightContext, animation, direction, fromContext, toContext) {
              final isPop = direction == HeroFlightDirection.pop;
              final target = isPop ? fromContext : toContext;
              final heroWidget = target.widget as Hero;
                                            
              const flightRadius = 12.0;
                                            
              final fadeIn = CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
              );
              return AnimatedBuilder(
                animation: fadeIn,
                builder: (context, _) {
                                                         
                                                     
                                       
                  final returning =
                      isPop || animation.status == AnimationStatus.reverse;
                                             
                                                             
                                                  
                  final screen = MediaQuery.sizeOf(context);
                  final Widget flying;
                  if (isPop) {
                                                      
                                                    
                                           
                    flying = (toContext.widget as Hero).child;
                  } else {
                                              
                                                
                                                            
                                                    
                    flying = ClipRRect(
                      borderRadius: BorderRadius.circular(flightRadius),
                      clipBehavior: Clip.antiAlias,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(flightRadius),
                          child: SizedBox(
                            width: screen.width,
                            height: screen.height,
                            child: heroWidget.child,
                          ),
                        ),
                      ),
                    );
                  }
                                                  
                                                         
                                       
                  return Opacity(
                    opacity: returning ? 1.0 : 0.35 + 0.65 * fadeIn.value,
                    child: flying,
                  );
                },
              );
            },
        child: ZoomHeroScope(
                                             
                                         
          active: _zoomHeroBlocksInnerHeroes,
          child: HeroMode(enabled: false, child: page),
        ),
      );
    }

    return PopScope(
                             
                                               
                                           
                                          
                                                
                                               
                                                     
      canPop:
          !_moreMenuOpen &&
          !_memberPanelOpen &&
          !_fullscreen &&
          !_exitUnloadLock &&
          !_isPlayerPlaying &&
          (!_usesZoomHero || _zoomHeroActive),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
                                        
        if (_moreMenuOpen) {
          unawaited(_closeMoreMenu());
          return;
        }
        if (_memberPanelOpen) {
          _closeMemberPanel();
          return;
        }
        if (_fullscreen && mounted) {
          _setFullscreen(false);
          return;
        }
                                             
                                                     
                                
        if ((_commentsNavKey.currentState?.canPop() ?? false)) return;
                                                   
                                          
        _unloadPlayerForExit();
      },
                                         
                                          
      child: IosBackdropScale(child: page),
    );
  }

                         
                                         
                                
  bool get _isPlayerPlaying =>
      _started && (_playerKey.currentState?.player.state.playing ?? false);

                                   
     
                                     
                                                       
                                              
                                          
                                          
     
                                        
                                                           
     
                                            
                                       
  Future<void> _unloadPlayerForExit() async {
    if (_exitUnloadLock) return;
    _exitUnloadLock = true;
                                  
    final st = _playerKey.currentState;
    if (st != null && st.player.state.playing) {
      try {
        await st.player.pause().timeout(
          const Duration(milliseconds: 600),
          onTimeout: () {},
        );
      } catch (_) {
                    
      }
    }
    if (!mounted) return;

                                            
                                                   
    final plan = planZoomHeroExit(
      playerMounted: _started,
      usesZoomHero: _usesZoomHero,
      zoomHeroActive: _zoomHeroActive,
    );
    popRouteAfterRebuild(
      context: context,
      onBeforePop: () => _exitUnloadLock = false,
      rebuild: plan.isEmpty
          ? null
          : () => setState(() {
              if (plan.unmountPlayer) _started = false;
              if (plan.rewrapHero) _zoomHeroActive = true;
            }),
    );
  }

                                                   
                                        
  Widget _buildDanmakuBar(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final info = [
      if (_onlineCount > 0) l10n.danmakuWatching('$_onlineCount'),
      if (_danmaku.itemCount > 0)
        l10n.danmakuLoadedBar('${_danmaku.itemCount}'),
    ].join(',');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
                                 
                                                           
                                                       
                                          
                                               
          if (info.isNotEmpty)
            Text(
              info,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          if (info.isNotEmpty) const SizedBox(width: 10),
                                                     
          _buildDanmakuToggleIcon(),
          if (info.isNotEmpty) const SizedBox(width: 10),
                                                  
          AppTooltip(
            message: l10n.danmakuSendTitle,
            waitDuration: const Duration(milliseconds: 400),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _openDanmakuComposer,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(
                  Icons.palette_outlined,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
                   
          Expanded(
            child: TextField(
              controller: _dmInputController,
              textInputAction: TextInputAction.send,
              maxLength: 100,
              onSubmitted: (_) => _sendDanmakuFromInput(),
              style: TextStyle(fontSize: 13, color: cs.onSurface),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                hintText: l10n.danmakuInputHint,
                hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                filled: true,
                fillColor: cs.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
                         
          TextButton(
            onPressed: _sendDanmakuFromInput,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: Text(
              l10n.rcSend,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

                                                  
                                                                    
  Widget _buildDanmakuToggleIcon() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return AppTooltip(
      message: _danmaku.enabled ? l10n.danmakuDisable : l10n.danmakuToggleOn,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _toggleDanmaku,
        child: Padding(
          padding: const EdgeInsets.all(3),
                                                              
                                                
                                     
          child: Transform.flip(
            flipX: true,
            child: Transform.rotate(
              angle: math.pi,
              child: SvgPicture.asset(
                _danmaku.enabled
                    ? 'assets/bili_icons/dm_on.svg'
                    : 'assets/bili_icons/dm_off.svg',
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  _danmaku.enabled ? cs.secondary : cs.outline,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

                                  
  Future<void> _sendDanmakuFromInput() async {
    final msg = _dmInputController.text.trim();
    _dmInputController.clear();
    await _sendDanmaku(msg);
  }

                                           
                                    
  Future<void> _openDanmakuComposer() async {
    final detail = _detail;
    if (detail == null) return;
    if (!await _ensureCanInteract()) return;
    if (!mounted) return;
    final style = await showDanmakuSendSheet(
      context,
      initialText: _dmInputController.text.trim(),
                 
      aid: detail.aid,
    );
    if (!mounted || style == null) return;
    _dmInputController.clear();
    await _sendDanmaku(
      style.msg,
      mode: style.mode,
      color: style.color,
      fontSize: style.fontSize,
    );
  }

                                          
                                                                  
  Future<void> _sendDanmaku(
    String msg, {
    int mode = 1,
    int color = 0xFFFFFF,
    int fontSize = 25,
  }) async {
    final detail = _detail;
    if (detail == null) return;
    if (msg.isEmpty) {
      _toast(AppLocalizations.of(context).danmakuToastEmpty, error: true);
      return;
    }
    if (!await _ensureCanInteract()) return;
    final page = detail.pages[_pageIndex];
    final result = await DanmakuSegFetcher.sendDanmaku(
      oid: detail.aid.toString(),
      cid: page.cid.toString(),
      msg: msg,
      progress: _position.inMilliseconds,
      mode: mode,
      color: color,
      fontSize: fontSize,
    );
    if (!mounted) return;
    if (!result.ok) {
      _toast(
        AppLocalizations.of(context).danmakuToastSendFail(result.message),
        error: true,
      );
      return;
    }
                             
    _danmaku.addItem(
      DanmakuItem(
        time: _position.inMilliseconds / 1000.0,
        mode: switch (mode) {
          5 => DanmakuMode.top,
          4 => DanmakuMode.bottom,
          _ => DanmakuMode.scrollRightToLeft,
        },
        fontSize: fontSize.toDouble(),
        color: Color(0xFF000000 | (color & 0xFFFFFF)),
        content: msg,
      ),
    );
    if (mounted) setState(() {});
    _toast(AppLocalizations.of(context).danmakuToastSent);
  }

                                                         
  Widget _buildWideLayout(ColorScheme cs) {
    final rightWidth = (MediaQuery.of(context).size.width * 0.34).clamp(
      320.0,
      480.0,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                                                       
        Expanded(
          child: Column(
            children: [
              AspectRatio(aspectRatio: 16 / 9, child: _buildPlayerArea()),
                                           
              if (_detail != null) _buildDanmakuBar(cs),
              Expanded(
                child: Container(
                  color: cs.surfaceContainerLow,
                  child: _detail == null
                      ? _detailPlaceholder(cs)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: _buildInfoContent(),
                        ),
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
                                        
        SizedBox(
          width: rightWidth,
          child: Container(
            color: cs.surfaceContainerLow,
            child: _detail == null
                ? _detailPlaceholder(cs)
                : _buildWideRightPanel(cs),
          ),
        ),
      ],
    );
  }

                                             
  Widget _buildWideRightPanel(ColorScheme cs) {
    return Stack(
      children: [
        Positioned.fill(child: _buildWideMediaPanel(cs)),
        if (_memberPanelOpen)
          Positioned.fill(
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _memberPanelCtrl,
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    ),
                  ),
              child: HorizontalMemberPanel(
                mid: _detail!.ownerMid,
                name: _detail!.ownerName,
                face: _detail!.ownerFace,
                focusBvid: _detail!.bvid,
                onClose: _closeMemberPanel,
                onPickVideo: (bvid) {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => BilibiliVideoPage(bvid: bvid),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

                                          
  Widget _buildWideMediaPanel(ColorScheme cs) {
    return Stack(
      children: [
                                       
        Positioned.fill(
          child: naviTabBarView(
            controller: _mediaTab,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: _tabBarHeight),
                child: BilibiliRelatedVideosPage(
                  bvid: _detail!.bvid,
                                                
                  heroTagsDisabled: _usesZoomHero && _zoomHeroActive,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: _tabBarHeight),
                                                 
                                                
                                          
                child: NavigatorPopHandler(
                  enabled: !_fullscreen,
                  onPopWithResult: (result) =>
                      _commentsNavKey.currentState?.maybePop(),
                  child: Navigator(
                    key: _commentsNavKey,
                    observers: [_commentsNavObserver],
                    onGenerateRoute: (settings) => MaterialPageRoute<void>(
                      settings: settings,
                      builder: (_) => BilibiliCommentsPage(
                        oid: _detail!.aid,
                        upMid: _detail!.ownerMid,
                        jumpRpid: widget.commentRootId,
                        jumpSubRpid: widget.commentSecondaryId,
                        commentPostedTick: _commentPostedTick,
                        episodeTitle: _detail!.title,
                        heroTagsDisabled: _zoomHeroBlocksInnerHeroes,
                        currentProgress: _commentsPanelProgress,
                        captureFrame: _commentsPanelCaptureFrame,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
                          
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _tabBarHeight,
          child: _buildTabRow([
            AppLocalizations.of(context).videoTabRelated,
            AppLocalizations.of(context).videoTabCommentsCount(_detail!.reply),
          ]),
        ),
                                                          
        Positioned(
          right: 16,
          bottom: 16,
          child: Builder(builder: (ctx) => _buildSharedFab(ctx)),
        ),
      ],
    );
  }

                          
  void _openMemberPanel() {
    if (_memberPanelOpen) return;
    setState(() => _memberPanelOpen = true);
    _memberPanelCtrl.forward(from: 0);
  }

                                     
  Future<void> _closeMemberPanel() async {
    if (!_memberPanelOpen) return;
    await _memberPanelCtrl.reverse();
    if (!mounted) return;
    setState(() => _memberPanelOpen = false);
  }

                                              
    
                               
                                                      
                                                      
                                           
                                   
  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
                                     
    if (backEvent.isButtonEvent) return false;
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
                       
    if (_memberPanelOpen) {
      _memberBackOwned = true;
      _memberPanelCtrl.value = 1 - backEvent.progress;
      return true;
    }
                                           
    if (_moreMenuOpen) {
      _moreBackOwned = true;
      _moreBackCtrl.value = 1 - backEvent.progress;
      return true;
    }
    return false;
  }

                               
  AnimationController get _moreBackCtrl =>
      _morePageKey != null ? _moreNavCtrl : _moreMenuCtrl;

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (_moreBackOwned) {
      _moreBackCtrl.value = 1 - backEvent.progress;
      return;
    }
    if (!_memberBackOwned) return;
    _memberPanelCtrl.value = 1 - backEvent.progress;
  }

  @override
  void handleCommitBackGesture() {
    if (_moreBackOwned) {
      _moreBackOwned = false;
                                        
      if (_morePageKey != null) {
        unawaited(_popMorePage());
      } else {
        unawaited(_closeMoreMenu());
      }
      return;
    }
    if (!_memberBackOwned) return;
    _memberBackOwned = false;
    unawaited(_closeMemberPanel());
  }

  @override
  void handleCancelBackGesture() {
    if (_moreBackOwned) {
      _moreBackOwned = false;
      _moreBackCtrl.animateTo(
        1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (!_memberBackOwned) return;
    _memberBackOwned = false;
    _memberPanelCtrl.animateTo(
      1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

                                                                
  Widget _buildCompactLayout(ColorScheme cs) {
    final detail = _detail;
    final w = MediaQuery.of(context).size.width;
    final playerHeight = w * 9 / 16;
    return Column(
      children: [
                                           
        ValueListenableBuilder<double>(
          valueListenable: _collapseNotifier,
          builder: (context, collapsePx, _) {
            final effectiveCollapse = collapsePx.clamp(
              0.0,
              math.max(0.0, playerHeight - _kPlayerCollapsedHeight),
            );
            return SizedBox(
              width: double.infinity,
              height: playerHeight - effectiveCollapse,
              child: _buildPlayerArea(),
            );
          },
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onCompactScroll,
            child: Container(
              color: cs.surfaceContainerLow,
              child: detail == null
                  ? _detailPlaceholder(cs)
                  : Stack(
                      children: [
                                                       
                        Positioned.fill(
                          child: naviTabBarView(
                            controller: _mediaTab,
                            children: [
                                                              
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: _tabBarHeight,
                                ),
                                child: BilibiliRelatedVideosPage(
                                  bvid: detail.bvid,
                                                                
                                  heroTagsDisabled:
                                      _usesZoomHero && _zoomHeroActive,
                                  header: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      12,
                                      16,
                                      4,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: _buildInfoContent(),
                                    ),
                                  ),
                                ),
                              ),
                                         
                                                            
                                                                
                                                         
                                                 
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: _tabBarHeight,
                                ),
                                child: NavigatorPopHandler(
                                  enabled: !_fullscreen,
                                  onPopWithResult: (result) =>
                                      _commentsNavKey.currentState?.maybePop(),
                                  child: Navigator(
                                    key: _commentsNavKey,
                                    observers: [_commentsNavObserver],
                                    onGenerateRoute: (settings) =>
                                        MaterialPageRoute<void>(
                                          settings: settings,
                                          builder: (_) => BilibiliCommentsPage(
                                            oid: detail.aid,
                                            upMid: detail.ownerMid,
                                            jumpRpid: widget.commentRootId,
                                            jumpSubRpid:
                                                widget.commentSecondaryId,
                                            commentPostedTick:
                                                _commentPostedTick,
                                            episodeTitle: detail.title,
                                            heroTagsDisabled:
                                                _zoomHeroBlocksInnerHeroes,
                                            currentProgress:
                                                _commentsPanelProgress,
                                            captureFrame:
                                                _commentsPanelCaptureFrame,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                                                
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: _tabBarHeight,
                          child: _buildTabRow([
                            AppLocalizations.of(context).videoTabIntro,
                            AppLocalizations.of(
                              context,
                            ).videoTabCommentsCount(detail.reply),
                          ]),
                        ),
                                          
                        Positioned(
                          right: 16,
                                                       
                          bottom: MediaQuery.paddingOf(context).bottom + 16,
                          child: Builder(
                            builder: (ctx) => _buildSharedFab(ctx),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

                                                               
  Widget _buildSharedFab(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tc = _mediaTab;
    final replyOpen = _replyPageOpen;
    return AnimatedBuilder(
      animation: tc,
      builder: (context, _) {
        final onComments = tc.index == 1;
        if (onComments) {
                                                      
          if (replyOpen) return const SizedBox.shrink();
          return CommentComposerFab(
            heroTag: kVideoPageCommentHeroTag,
            icon: Icons.edit_outlined,
            label: l10n.commentComposerFabLabel,
            labelVisible: true,
            onPressed: _openCommentComposer,
          );
        }
        return ValueListenableBuilder<bool>(
          valueListenable: BilibiliRelatedVideosPage.gridModeNotifier,
          builder: (context, grid, _) {
            return CommentComposerFab(
              icon: grid ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
              label: grid ? l10n.searchSwitchSingleCol : l10n.searchSwitchMulti,
              labelVisible: true,
              onPressed: BilibiliRelatedVideosPage.toggleGridMode,
            );
          },
        );
      },
    );
  }

                                              
                                                  
  Future<void> _openCommentComposer() async {
    if (_detail == null) return;
    final result = await showCommentComposer(
      context,
      oid: _detail!.aid,
      currentProgress: _commentsPanelProgress,
      captureFrame: _commentsPanelCaptureFrame,
      heroTag: kVideoPageCommentHeroTag,
      sourceTitle: _detail!.title,
      sourceId: _detail!.bvid,
    );
    if (result.sent) _commentPostedTick.value++;
  }

                                               
                                                  
  Widget _detailPlaceholder(ColorScheme cs) {
    if (_error != null && !_loading) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
                                          
          PositionedRetryFab(
            onRetry: _loadDetail,
            bottomOffset: MediaQuery.paddingOf(context).bottom + 16,
          ),
        ],
      );
    }
    return const Center(child: LoadingIndicatorM3E());
  }

                                                                      
                                                              
                                                             
  Widget _buildTabRow(
    List<String> tabs, {
    bool needIndicator = true,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
                                                                
    final flag = !needIndicator || tabs.length == 1;

    Widget tabBar() {
      return TabBar(
        controller: _mediaTab,
        padding: EdgeInsets.zero,
        dividerHeight: 0,
        labelPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        indicator: flag ? const BoxDecoration() : null,
        labelColor: flag ? cs.onSurface : null,
        labelStyle:
            TabBarTheme.of(context).labelStyle?.copyWith(fontSize: 13) ??
            const TextStyle(fontSize: 13),
        onTap: (value) {
                                                
          void animToTop() {
            if (onTap != null) {
              onTap();
              return;
            }
                                                   
                                                         
                                           
          }

          if (flag) {
            animToTop();
          } else {
                                                                         
                                              
            animToTop();
          }
        },
        tabs: tabs
            .map(
              (t) => AppTooltip(
                message: t,
                child: Tab(
                  child: Text(
                    t,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            )
            .toList(),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: SizedBox(
        height: _tabBarHeight,
        child: Row(
          children: [
            if (tabs.isEmpty)
              const Spacer()
            else
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 96.0 * tabs.length),
                    child: tabBar(),
                  ),
                ),
              ),
                                                                                        
            if (_detail != null && !_isWideScreen) ...[
              AppTooltip(
                message: '发弹幕',
                child: SizedBox(
                  height: 32,
                  child: TextButton(
                    style: const ButtonStyle(
                      padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    ),
                    onPressed: _openDanmakuComposer,
                    child: Text(
                      '发弹幕',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              AppTooltip(
                message: _danmaku.enabled ? '关闭弹幕' : '开启弹幕',
                child: SizedBox.square(
                  dimension: 38,
                  child: IconButton(
                    onPressed: _toggleDanmaku,
                    icon: Transform.flip(
                      flipX: true,
                      child: Transform.rotate(
                        angle: math.pi,
                        child: SvgPicture.asset(
                          _danmaku.enabled
                              ? 'assets/bili_icons/dm_on.svg'
                              : 'assets/bili_icons/dm_off.svg',
                          width: 22,
                          height: 22,
                          colorFilter: ColorFilter.mode(
                            _danmaku.enabled ? cs.secondary : cs.outline,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ],
        ),
      ),
    );
  }

                                              
                                         
                                              
  List<Widget> _buildInfoContent() {
    final detail = _detail!;
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
                         
    final hasIntro = detail.desc.isNotEmpty || _tags.isNotEmpty;
    return [
                          
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
                                             
                                                   
            if (_isWideScreen) {
              _openMemberPanel();
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BilibiliUserSpacePage(
                  mid: detail.ownerMid,
                  focusBvid: detail.bvid,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                                                             
                                   
                                                      
                () {
                  final avatar = ClipOval(
                    child: detail.ownerFace.isNotEmpty
                        ? Image(
                            image: CachedImageProvider(
                              detail.ownerFace,
                              headers:
                                  NetworkSettingsService
                                      .instance
                                      .apiHeaders
                                      .isEmpty
                                  ? null
                                  : NetworkSettingsService.instance.apiHeaders,
                                                        
                              cacheWidth: 192,
                            ),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _faceFallback(cs),
                          )
                        : _faceFallback(cs),
                  );
                  return _zoomHeroBlocksInnerHeroes
                      ? avatar
                      : Hero(
                          transitionOnUserGestures: true,
                          tag: 'bili_space_avatar_${detail.ownerMid}',
                          child: avatar,
                        );
                }(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.ownerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFB7299),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_fmtCount(_ownerFans)}粉丝 · ${_fmtCount(_ownerVideos)}视频',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                                           
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _hasFollowed
                          ? cs.surfaceContainerHighest
                          : cs.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _toggleFollow,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        child: Text(
                          _hasFollowed
                              ? AppLocalizations.of(context).videoFollowedLabel
                              : AppLocalizations.of(context).videoFollowLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _hasFollowed
                                ? cs.onSurfaceVariant
                                : cs.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
                                                 
                                         
      if (_bgm != null) _buildBgmEntry(cs),
      if (_bgm != null) const SizedBox(height: 12),
                                               
      _buildTitle(cs, detail),
      const SizedBox(height: 8),
                 
      _buildStats(cs),
                                                   
                                         
      if (!_isWideScreen && hasIntro)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _introExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _introBlocks(cs, detail),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      const SizedBox(height: 12),
                                    
      _buildActions(cs, detail),
      const Divider(height: 24),
                    
      if (detail.pages.length > 1) ...[
        Text(
          l10n.playerEpisodeSelect,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < detail.pages.length; i++) _pageChip(cs, i),
          ],
        ),
        const SizedBox(height: 16),
      ],
                                        
      if (_isWideScreen && hasIntro) ...[
        const Divider(height: 24),
        ..._introBlocks(cs, detail),
      ],
    ];
  }

                                             
                                                 
  List<Widget> _introBlocks(ColorScheme cs, BiliVideoDetail detail) {
    return [
      if (detail.desc.isNotEmpty) ...[
        SelectableText.rich(
                                         
                              
                                                      
          TextSpan(
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: cs.onSurfaceVariant,
            ),
            children: buildUgcSpans(
              text: _descShowOriginal || _translatedDesc.isEmpty
                  ? detail.desc
                  : _translatedDesc,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: cs.onSurfaceVariant,
              ),
              context: context,
              onSeek: _seekFromUgc,
              maxSeekable: detail.duration > 0
                  ? Duration(seconds: detail.duration)
                  : null,
            ),
          ),
                                       
                                
          contextMenuBuilder: (context, state) {
            final items = <ContextMenuButtonItem>[
              ContextMenuButtonItem(
                label: '复制',
                onPressed: () {
                  state.copySelection(SelectionChangedCause.toolbar);
                  state.hideToolbar();
                },
              ),
              if (_translatedDesc.isNotEmpty && detail.desc.isNotEmpty)
                ContextMenuButtonItem(
                  label: _descShowOriginal ? '查看译文' : '查看原文',
                  onPressed: () {
                    state.hideToolbar();
                    setState(() => _descShowOriginal = !_descShowOriginal);
                  },
                ),
            ];
            return AdaptiveTextSelectionToolbar.buttonItems(
              buttonItems: items,
              anchors: state.contextMenuAnchors,
            );
          },
        ),
        if (_tags.isNotEmpty) const SizedBox(height: 14),
      ],
      if (_tags.isNotEmpty)
        Builder(
          builder: (context) {
                                            
            final seen = <String>{};
            final chips = <Widget>[];
            for (final t in _tags) {
              final chip = _tagChip(cs, t);
              final label = (chip.key as ValueKey<String>).value;
              if (seen.add(label)) chips.add(chip);
            }
            return Wrap(spacing: 8, runSpacing: 8, children: chips);
          },
        ),
    ];
  }

                                    
                                                
                                               
                                                     
                                        
  Widget _buildTitle(ColorScheme cs, BiliVideoDetail detail) {
                                             
                        
    final translated = _videoTitle.isNotEmpty && _videoTitle != detail.title;
    final displayTitle = _titleShowOriginal
        ? detail.title
        : (_videoTitle.isNotEmpty ? _videoTitle : detail.title);
    final text = Text(
      displayTitle,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    );
    final Widget title;
    if (UgcSelectionArea.enabled) {
      title = SelectionArea(
        contextMenuBuilder: (_, selectableRegionState) =>
            _titleSelectionMenu(selectableRegionState, translated),
        child: text,
      );
    } else {
                                       
      title = GestureDetector(
        onLongPress: () => _showTitleMenu(translated),
        onSecondaryTapDown: (details) =>
            _showTitleContextMenu(translated, details.globalPosition),
        child: text,
      );
    }
    if (_isWideScreen) return title;
    final row = InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _introExpanded = !_introExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: title),
            const SizedBox(width: 6),
            Icon(
              _introExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
    if (UgcSelectionArea.enabled) {
                                               
      return SelectionArea(
        contextMenuBuilder: (_, selectableRegionState) =>
            _titleSelectionMenu(selectableRegionState, translated),
        child: row,
      );
    }
    return row;
  }

                                                 
                                       
  AdaptiveTextSelectionToolbar _titleSelectionMenu(
    SelectableRegionState state,
    bool translated,
  ) {
    final items = <ContextMenuButtonItem>[
      ContextMenuButtonItem(
        label: '复制',
        onPressed: () {
                                                    
          // ignore: deprecated_member_use
          state.copySelection(SelectionChangedCause.toolbar);
          state.hideToolbar();
        },
      ),
      if (translated)
        ContextMenuButtonItem(
          label: _titleShowOriginal ? '查看译文' : '查看原文',
          onPressed: () {
            state.hideToolbar();
            setState(() => _titleShowOriginal = !_titleShowOriginal);
          },
        ),
    ];
    return AdaptiveTextSelectionToolbar.buttonItems(
      buttonItems: items,
      anchors: state.contextMenuAnchors,
    );
  }

                                         
  void _showTitleMenu(bool translated) {
    showFrostedActionSheet(
      context,
      actions: [
        GlassMenuAction(
          icon: Icons.copy_rounded,
          text: '复制标题',
          onTap: _copyTitle,
        ),
        if (translated)
          GlassMenuAction(
            icon: Icons.translate_outlined,
            text: _titleShowOriginal ? '查看译文' : '查看原文',
            onTap: () =>
                setState(() => _titleShowOriginal = !_titleShowOriginal),
          ),
      ],
    );
  }

                                         
  void _showTitleContextMenu(bool translated, Offset globalPosition) {
    showGlassDropdownMenu(
      context,
      globalPosition: globalPosition,
      menuWidth: 200,
      actions: [
        GlassMenuAction(
          icon: Icons.copy_rounded,
          text: '复制标题',
          onTap: _copyTitle,
        ),
        if (translated)
          GlassMenuAction(
            icon: Icons.translate_outlined,
            text: _titleShowOriginal ? '查看译文' : '查看原文',
            onTap: () =>
                setState(() => _titleShowOriginal = !_titleShowOriginal),
          ),
      ],
    );
  }

                                       
  void _copyTitle() {
    final detail = _detail;
    if (detail == null) return;
    final text = _titleShowOriginal
        ? detail.title
        : (_videoTitle.isNotEmpty ? _videoTitle : detail.title);
    Clipboard.setData(ClipboardData(text: text));
    _toast('已复制标题');
  }

                                        
                                       
                           
                                
  Widget _tagChip(ColorScheme cs, BiliVideoTag tag) {
                                             
    final name = _translatedTags[tag.name] ?? tag.name;
    final label = switch (tag.type) {
      'bgm' => name.replaceFirst('发现', '♫ BGM：'),
      'topic' => '#$name',
      _ => name,
    };
    return Material(
      key: ValueKey<String>(label),
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
                                          
                                          
                                        
          if (tag.type == 'bgm' && tag.musicId.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BilibiliMusicPage(musicId: tag.musicId),
              ),
            );
            return;
          }
          if (tag.type == 'topic' && tag.id > 0) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BilibiliTopicPage(topicId: tag.id, name: name),
              ),
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BilibiliSearchPage(
                initialKeyword: tag.name,
                recordInitialKeyword: false,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

                                                      
                                                         
  Widget _biliIcon(String name, {double size = 20, Color? color}) {
    return SvgPicture.asset(
      'assets/bili_icons/$name',
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  Widget _buildActions(ColorScheme cs, BiliVideoDetail detail) {
                                               
                                             
    return Row(
      children: [
                                               
        Expanded(
          child: _interactBtn(
            cs,
            icon: _biliIcon(
              'like.svg',
              size: 20,
              color: _hasLiked ? cs.primary : cs.onSurfaceVariant,
            ),
            iconColor: _hasLiked ? cs.primary : cs.onSurfaceVariant,
            label: _fmtCount(_likeCount),
            tooltip: _hasLiked
                ? AppLocalizations.of(context).videoUnlikeTooltip
                : AppLocalizations.of(context).videoLikeTooltip,
            active: _hasLiked,
            showTooltip: false,
            shakeAnimation: _tripleController,
            onTapDown: _onLikeTapDown,
            onTapUp: _onLikeTapUp,
            onTapCancel: _onLikeTapCancel,
          ),
        ),
                                            
        Expanded(
          child: _interactBtn(
            cs,
            icon: Transform.flip(
              flipY: true,
              child: _biliIcon(
                'like.svg',
                size: 20,
                color: _hasDisliked ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
            iconColor: _hasDisliked ? cs.primary : cs.onSurfaceVariant,
            label: '点踩',
            tooltip: _hasDisliked ? '取消点踩' : '点踩',
            active: _hasDisliked,
            onTap: _toggleDislike,
          ),
        ),
        Expanded(
          child: _interactBtn(
            cs,
            icon: _biliIcon(
              'coin.svg',
              size: 20,
              color: _coinGiven > 0 ? cs.primary : cs.onSurfaceVariant,
            ),
            iconColor: _coinGiven > 0 ? cs.primary : cs.onSurfaceVariant,
            label: _fmtCount(_coinCount),
            tooltip: AppLocalizations.of(context).videoCoinTooltip,
            active: _coinGiven > 0,
            arcProgress: _tripleController,
            onTap: _openCoinDialog,
          ),
        ),
        Expanded(
          child: _interactBtn(
            cs,
            icon: _biliIcon(
              'fav.svg',
              size: 20,
              color: _hasFaved ? cs.primary : cs.onSurfaceVariant,
            ),
            iconColor: _hasFaved ? cs.primary : cs.onSurfaceVariant,
            label: _fmtCount(_favCount),
            tooltip: _hasFaved
                ? AppLocalizations.of(context).videoUnfavTooltip
                : AppLocalizations.of(context).videoFavTooltip,
            active: _hasFaved,
            arcProgress: _tripleController,
            onTap: _toggleFav,
          ),
        ),
                                              
        Expanded(
          child: _interactBtn(
            cs,
            icon: _biliIcon('share.svg', size: 20, color: cs.onSurfaceVariant),
            iconColor: cs.onSurfaceVariant,
            label: _fmtCount(detail.share),
            tooltip: AppLocalizations.of(context).videoShareLabel,
            onTap: _openShareMenu,
          ),
        ),
      ],
    );
  }

  Widget _interactBtn(
    ColorScheme cs, {
    required Widget icon,
    required String label,
    required String tooltip,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Color? iconColor,
    bool active = false,
    bool showTooltip = true,
    GestureTapDownCallback? onTapDown,
    GestureTapUpCallback? onTapUp,
    GestureTapCancelCallback? onTapCancel,
    Animation<double>? arcProgress,
    Animation<double>? shakeAnimation,
  }) {
    final fg = iconColor ?? (active ? cs.primary : cs.onSurfaceVariant);

                                           
    if (arcProgress != null) {
      icon = AnimatedBuilder(
        animation: arcProgress,
        builder: (context, child) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _TripleArc(progress: -arcProgress.value, color: cs.primary),
              child!,
            ],
          );
        },
        child: icon,
      );
    }

                         
    if (shakeAnimation != null) {
      icon = AnimatedBuilder(
        animation: shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(math.sin(shakeAnimation.value * math.pi * 8) * 3, 0),
            child: child,
          );
        },
        child: icon,
      );
    }

                                               
                                         
                                              
    icon = SizedBox(width: 28, height: 28, child: Center(child: icon));

    Widget child = InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      onLongPress: onLongPress,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: fg,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
    if (showTooltip) {
      child = AppTooltip(message: tooltip, child: child);
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: child,
    );
  }

                  
                                              
                                           
                              
  Widget _buildPlayerArea() {
    final l10n = AppLocalizations.of(context);
    if (_started) return const SizedBox.expand();
    return ValueListenableBuilder<double>(
      valueListenable: _collapseNotifier,
      builder: (context, collapsePx, _) {
        final collapsed = _isCoverCollapsed(collapsePx);
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildCover(collapsed: collapsed),
                  
            if (!collapsed && (_loading || _loadingPlayUrl))
              const Center(child: LoadingIndicatorM3E()),
                                        
            if (!collapsed && _error != null && !_loading && !_loadingPlayUrl)
              Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                                        
                                                          
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade400,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.scanRetry),
                          onPressed: _startPlayback,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _pageTitle() {
    final detail = _detail;
    if (detail == null) return _videoTitle;
    if (detail.pages.length > 1) {
      final p = detail.pages[_pageIndex];
      return p.part.isNotEmpty ? p.part : 'P${p.page}';
    }
                                          
    return _videoTitle.isNotEmpty ? _videoTitle : detail.title;
  }

                                                     
                                            
                                                
  String? get _currentHistoryId {
    final detail = _detail;
    if (detail == null || detail.pages.isEmpty) return null;
    return 'bili_${detail.bvid}_${detail.pages[_pageIndex].cid}';
  }

                                           
                                                     
                                                             
                                     
                                  
  Widget _buildBackButton({bool transparent = false}) {
    final l10n = AppLocalizations.of(context);
    return MorphIconButton(
      icon: Icons.arrow_back,
      tooltip: l10n.commonBackTooltip,
                                                      
                                      
      onTap: () => Navigator.of(context).maybePop(),
      transparent: transparent,
      frosted: !transparent,
      iconColor: transparent ? Colors.white : null,
    );
  }

                                  
  Widget _buildCollapsedBarContent() {
    return SizedBox(
      height: _kPlayerCollapsedHeight,
      child: GestureDetector(
                                             
        behavior: HitTestBehavior.translucent,
        onTap: _expandAndPlay,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _buildBackButton(),
              const Spacer(),
                                                  
                                     
              _buildCollapsedMoreMenu(),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

                                                   
                                     
                          
  Widget _buildCollapsedMoreMenu() {
    final hasBvid = (_detail?.bvid ?? '').isNotEmpty;
    final showDanmakuList = _danmaku.itemCount > 0;
    if (!hasBvid && !showDanmakuList) return const SizedBox.shrink();
                                     
    return MorphIconButton(
      icon: Icons.more_vert,
      tooltip: L10n.current.playerMoreTooltip,
      frosted: true,
      onTap: _toggleMoreMenu,
    );
  }

                                     
                                                        
  Widget _buildTopMoreMenu({bool transparent = false}) {
    final hasBvid = (_detail?.bvid ?? '').isNotEmpty;
    if (!hasBvid) return const SizedBox.shrink();
                                     
                                         
    return MorphIconButton(
      icon: Icons.more_vert,
      tooltip: L10n.current.playerMoreTooltip,
      transparent: transparent,
      frosted: !transparent,
      iconColor: transparent ? Colors.white : null,
      onTap: _toggleMoreMenu,
    );
  }

                                        

                                  
  List<MoreMenuAction> _moreMenuActions() {
    final l10n = AppLocalizations.of(context);
    final hasBvid = (_detail?.bvid ?? '').isNotEmpty;
    final showDanmakuList = _danmaku.itemCount > 0;
    final cacheIcon = _cacheChecking
        ? Icons.hourglass_top_outlined
        : _isCached
        ? Icons.download_done_rounded
        : _isCaching
        ? Icons.downloading_rounded
        : Icons.download_rounded;
    final cacheText = _cacheChecking
        ? '检查中'
        : _isCached
        ? l10n.cacheActionCached
        : _isCaching
        ? l10n.cacheActionCaching
        : l10n.cacheActionDownload;
                                    
    final st = _playerKey.currentState;
    final check = const Icon(Icons.check, size: 18, color: Colors.blueAccent);
    return [
      if (showDanmakuList)
        MoreMenuAction(
          icon: Icons.format_list_bulleted_outlined,
          label: l10n.playerDanmakuList,
          onTap: _showCollapsedDanmakuList,
          pageKey: 'danmakuList',
        ),
      if (hasBvid) ...[
        MoreMenuAction(
          icon: Icons.watch_later_outlined,
          label: l10n.videoMenuWatchLater,
          onTap: () => unawaited(_addToWatchLater()),
        ),
        MoreMenuAction(
          icon: Icons.headphones_rounded,
          label: l10n.playerListenPage,
          onTap: () => unawaited(_openAudioPage()),
        ),
        MoreMenuAction(
          icon: cacheIcon,
          label: cacheText,
          onTap: () => unawaited(_manualCache()),
        ),
        MoreMenuAction(
          icon: Icons.article_outlined,
          label: l10n.playerViewNotes,
          onTap: _showCollapsedVideoNotes,
          pageKey: 'notes',
        ),
        MoreMenuAction(
          icon: Icons.edit_note,
          label: l10n.playerWriteNote,
          onTap: _writeCollapsedVideoNote,
        ),
        MoreMenuAction(
          icon: Icons.copy_outlined,
          label: l10n.playerCopyLink,
          onTap: () => unawaited(_copyShareLink()),
        ),
        MoreMenuAction(
          icon: Icons.ios_share_outlined,
          label: l10n.videoShareLabel,
          onTap: _openShareMenu,
        ),
        MoreMenuAction(
          icon: Icons.refresh_outlined,
          label: l10n.videoMenuReload,
          onTap: () => unawaited(_loadDetail()),
        ),
        MoreMenuAction(
          icon: _onlyPlayAudio
              ? Icons.headphones_rounded
              : Icons.headphones_outlined,
          label: l10n.playerOnlyPlayAudioInline,
          onTap: () => unawaited(_toggleOnlyPlayAudio()),
                                 
          closeAfter: false,
          trailing: _onlyPlayAudio ? check : null,
        ),
      ],
                                                         
      if (st != null) ...[
        MoreMenuAction(
          icon: Icons.tune_rounded,
          label: l10n.playerDanmakuSettings,
          onTap: st.openDanmakuSettings,
          pageKey: 'danmakuSettings',
        ),
        MoreMenuAction(
          icon: Icons.subtitles_outlined,
          label: l10n.playerSubtitleSettings,
          onTap: st.openSubtitleSettings,
          pageKey: 'subtitleSettings',
        ),
        MoreMenuAction(
          icon: Icons.image_outlined,
          label: l10n.playerMenuScreenshot,
          onTap: () => unawaited(st.captureScreenshot()),
        ),
        MoreMenuAction(
          icon: Icons.graphic_eq_outlined,
          label: l10n.playerMenuAudioNorm,
          onTap: () => unawaited(st.showAudioNormalizationMenu()),
          pageKey: 'audioNormalization',
        ),
        MoreMenuAction(
          icon: Icons.speaker_group_outlined,
          label: l10n.playerMenuAudioDevice,
          onTap: () => unawaited(st.showAudioDeviceMenu()),
          pageKey: 'audioDevice',
        ),
        MoreMenuAction(
          icon: Icons.dns_outlined,
          label: l10n.playerMenuSource,
          onTap: st.showSourceMenu,
          pageKey: 'source',
        ),
        MoreMenuAction(
          icon: Icons.high_quality_outlined,
          label: l10n.superResolutionTitle,
          onTap: () => unawaited(st.showSuperResolutionMenu()),
          pageKey: 'superResolution',
        ),
        MoreMenuAction(
          icon: Icons.info_outline,
          label: l10n.playerMenuStats,
          onTap: st.showPlaybackStats,
        ),
        MoreMenuAction(
          icon: Icons.flip,
          label: l10n.playerFlipHorizontal,
          onTap: st.toggleFlipX,
          closeAfter: false,
          trailing: st.currentFlipX ? check : null,
        ),
        MoreMenuAction(
          icon: Icons.flip_camera_android_outlined,
          label: l10n.playerFlipVertical,
          onTap: st.toggleFlipY,
          closeAfter: false,
          trailing: st.currentFlipY ? check : null,
        ),
        MoreMenuAction(
          icon: Icons.repeat,
          label: l10n.playerMenuEndBehavior,
          subtitle: switch (st.currentEndBehavior) {
            EndBehavior.loop => l10n.playerEndLoop,
            EndBehavior.exit => l10n.playerEndExit,
            EndBehavior.pause => l10n.playerEndPause,
          },
          onTap: () => unawaited(st.cycleEndBehavior()),
          closeAfter: false,
        ),
      ],
    ];
  }

                                       
  Future<void> _addToWatchLater() async {
    final detail = _detail;
    if (detail == null) return;
    final r = await BilibiliWatchLaterService.add(
      aid: detail.aid,
      bvid: detail.bvid,
    );
    if (!mounted) return;
    _toast(r.message, error: !r.ok);
  }

               
     
                                           
                                                   
                 
  void _toggleMoreMenu() {
    if (_moreMenuOpen) {
      unawaited(_closeMoreMenu());
      return;
    }
                                                  
    if (!_isWideScreen) {
      unawaited(
        showMoreMenuSheet(
          context: context,
          title: AppLocalizations.of(context).videoMorePanelTitle,
          actions: _moreMenuActions(),
                                          
          actionsProvider: _moreMenuActions,
        ),
      );
      return;
    }
    _openMoreMenu();
  }

  void _openMoreMenu() {
    if (_moreMenuOpen) return;
    setState(() {
      _moreMenuOpen = true;
      _morePageKey = null;
      _moreNavCtrl.value = 0;
    });
    _moreMenuCtrl.forward(from: 0);
  }

  Future<void> _closeMoreMenu() async {
    if (!_moreMenuOpen) return;
    await _moreMenuCtrl.reverse();
    if (!mounted) return;
    setState(() {
      _moreMenuOpen = false;
      _morePageKey = null;
      _moreNavCtrl.value = 0;
    });
  }

                                        
  void _pushMorePage(String key) {
    if (_morePageKey == key) return;
    setState(() => _morePageKey = key);
    _moreNavCtrl.forward(from: 0);
  }

                          
  Future<void> _popMorePage() async {
    if (_morePageKey == null) return;
    await _moreNavCtrl.reverse();
    if (!mounted) return;
    setState(() => _morePageKey = null);
  }

                                           
     
                                          
                                               
                                           
  Widget _buildMoreMenuPanel(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final rightWidth = (media.size.width * 0.34).clamp(320.0, 480.0);
    return Stack(
      children: [
                        
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => unawaited(_closeMoreMenu()),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          width: rightWidth,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: _moreMenuCtrl,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  ),
                ),
            child: _buildMoreMenuCard(cs, l10n, media.size.height),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreMenuCard(
    ColorScheme cs,
    AppLocalizations l10n,
    double maxHeight,
  ) {
    return Material(
      color: cs.surfaceContainerHigh,
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight.clamp(120.0, double.infinity),
        ),
        child: AnimatedBuilder(
          animation: _moreNavCtrl,
          builder: (context, _) {
            final v = _moreNavCtrl.value;
            final pageKey = _morePageKey;
            return Stack(
              children: [
                                                     
                                                     
                if (v < 1)
                  Positioned.fill(
                    child: FractionalTranslation(
                      translation: Offset(-0.2 * v, 0),
                      child: Opacity(
                        opacity: (1 - 0.7 * v).clamp(0.0, 1.0),
                        child: _buildMoreMenuRoot(cs, l10n),
                      ),
                    ),
                  ),
                                  
                if (pageKey != null)
                  Positioned.fill(
                    child: FractionalTranslation(
                      translation: Offset(1 - v, 0),
                      child: _buildMoreSubPage(cs, l10n, pageKey),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

               
  Widget _buildMoreMenuRoot(ColorScheme cs, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMorePanelHeader(cs, title: l10n.videoMorePanelTitle),
        const Divider(height: 1),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final a in _moreMenuActions())
                  MoreMenuItem(
                    icon: a.icon,
                    label: a.label,
                    subtitle: a.subtitle,
                    trailing: a.trailing,
                    onTap: () {
                                             
                      if (a.opensPage) {
                        _pushMorePage(a.pageKey!);
                        return;
                      }
                      if (a.closeAfter) unawaited(_closeMoreMenu());
                      a.onTap();
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

                                          
     
                                                    
                                     
                                                                
  Widget _buildMoreSubPage(ColorScheme cs, AppLocalizations l10n, String key) {
    final body = _buildMorePageBody(key);
    return Material(
      color: cs.surfaceContainerHigh,
      child: Column(
        children: [
          _buildMorePanelHeader(
            cs,
            title: _morePageTitle(l10n, key),
            onBack: () => unawaited(_popMorePage()),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.6)),
          Expanded(
            child:
                body ??
                Center(
                  child: Text(
                    l10n.loadFailed,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ),
          ),
        ],
      ),
    );
  }

                                       
  Widget _buildMorePanelHeader(
    ColorScheme cs, {
    required String title,
    VoidCallback? onBack,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        children: [
          if (onBack != null)
            MorphIconButton(
              icon: Icons.arrow_back,
              iconSize: 20,
              tooltip: L10n.current.commonBackTooltip,
              transparent: true,
              onTap: onBack,
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.more_vert,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: L10n.current.commonClose,
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => unawaited(_closeMoreMenu()),
          ),
        ],
      ),
    );
  }

  String _morePageTitle(AppLocalizations l10n, String key) => switch (key) {
    'danmakuSettings' => l10n.playerDanmakuSettings,
    'danmakuList' => l10n.playerDanmakuList,
    'notes' => l10n.playerViewNotes,
    'subtitleSettings' => l10n.playerSubtitleSettings,
    'audioNormalization' => l10n.playerMenuAudioNorm,
    'audioDevice' => l10n.playerMenuAudioDevice,
    'source' => l10n.playerMenuSource,
    'superResolution' => l10n.superResolutionTitle,
    _ => l10n.videoMorePanelTitle,
  };

                                         
  Widget? _buildMorePageBody(String key) {
    final st = _playerKey.currentState;
    final detail = _detail;
    switch (key) {
      case 'danmakuSettings':
        return DanmakuSettingsPanel(
          controller: _danmaku,
          onClose: () => unawaited(_popMorePage()),
                                 
          embedded: true,
        );
      case 'danmakuList':
        return DanmakuListSheet(
          controller: _danmaku,
          onClose: () => unawaited(_popMorePage()),
          onSeek: (seconds) => _playerKey.currentState?.player.seek(
            Duration(milliseconds: (seconds * 1000).round()),
          ),
          currentPosition: () =>
              (_playerKey.currentState?.player.state.position.inMilliseconds ??
                  0) /
              1000.0,
        );
      case 'notes':
        if (detail == null) return null;
        return BiliNoteListSheet(
          aid: detail.aid,
          bvid: detail.bvid,
          videoTitle: detail.title,
        );
      case 'subtitleSettings':
        return st?.buildSubtitleSettingsBody();
      case 'audioDevice':
        return st?.buildAudioDeviceBody();
      case 'audioNormalization':
        if (st == null) return null;
        return _buildOptionList(
          options: [
            for (final m in MpvPlayerPageState.audioNormalizationModes)
              (
                label: PlayerAudioService.label(m),
                selected: st.audioNormalizationValue == m,
              ),
          ],
          onPick: (i) => st.applyAudioNormalization(
            MpvPlayerPageState.audioNormalizationModes[i],
          ),
        );
      case 'superResolution':
        if (st == null) return null;
        final l10n = AppLocalizations.of(context);
        final modes = MpvPlayerPageState.superResolutionModes;
        return _buildOptionList(
          options: [
            for (final m in modes)
              (
                label: switch (m) {
                  SuperResolutionService.modeEfficiency =>
                    l10n.superResolutionEfficiency,
                  SuperResolutionService.modeQuality =>
                    l10n.superResolutionQuality,
                  _ => l10n.superResolutionOff,
                },
                selected: st.superResolutionValue == m,
              ),
          ],
          onPick: (i) => st.applySuperResolution(modes[i]),
        );
      case 'source':
        if (st == null) return null;
        return _buildOptionList(
          options: st.sourceOptions,
          onPick: (i) => st.selectSourceAt(i),
        );
    }
    return null;
  }

                               
  Widget _buildOptionList({
    required List<({String label, bool selected})> options,
    required Future<void> Function(int index) onPick,
  }) {
    if (options.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noContent,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: options.length,
      itemBuilder: (context, i) {
        final o = options[i];
        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: Text(
            o.label,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: o.selected
              ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
              : null,
          onTap: () async {
            await onPick(i);
            if (mounted) setState(() {});
          },
        );
      },
    );
  }

                                              
                             
  Future<void> _openAudioPage() async {
    final detail = _detail;
    if (detail == null || detail.pages.isEmpty) return;
    final st = _playerKey.currentState;
                                       
                                              
    final resumeAt = st?.player.state.position;
    final resumeTotal = st?.player.state.duration;
    await st?.player.pause();
    if (!mounted) return;
    final episodes = <AudioEpisode>[
      for (final p in detail.pages)
        AudioEpisode(
          cid: p.cid,
          title: p.part.isNotEmpty ? p.part : 'P${p.page}',
        ),
    ];
    final resumed = await Navigator.of(context).push<Duration>(
      MaterialPageRoute<Duration>(
        builder: (_) => BilibiliAudioPage(
          bvid: detail.bvid,
          title: detail.title,
          cover: detail.pic,
          episodes: episodes,
          initialIndex: _pageIndex.clamp(0, episodes.length - 1),
          initialPosition: resumeAt,
          initialDuration: resumeTotal,
          ownerName: detail.ownerName,
          ownerMid: detail.ownerMid,
          ownerFace: detail.ownerFace,
        ),
      ),
    );
                                    
    if (!mounted || resumed == null || resumed <= Duration.zero) return;
    final back = _playerKey.currentState;
    if (back == null) return;
    await back.player.seek(resumed);
  }

                          
                           
  Future<void> _toggleOnlyPlayAudio() async {
    if (!_started) {
      await _startPlayback();
                                             
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        if (_playerKey.currentState != null) break;
      }
    }
    final st = _playerKey.currentState;
    if (st == null) return;
    await st.setOnlyPlayAudio(!_onlyPlayAudio);
  }

                               
  void _showCollapsedDanmakuList() {
    final st = _playerKey.currentState;
    if (st == null) return;
    showDanmakuListSheet(
      context,
      _danmaku,
      onSeek: (seconds) =>
          st.player.seek(Duration(milliseconds: (seconds * 1000).round())),
      currentPosition: () => st.player.state.position.inMilliseconds / 1000.0,
    );
  }

                
  void _showCollapsedVideoNotes() {
    final bvid = _detail?.bvid;
    if (bvid == null || bvid.isEmpty) return;
    final aid = BvAv.decode(bvid);
    if (aid == null || aid <= 0) return;
    showBiliNoteListSheet(
      context,
      aid: aid,
      bvid: bvid,
      videoTitle: _pageTitle(),
    );
  }

                            
  void _writeCollapsedVideoNote() {
    final bvid = _detail?.bvid;
    if (bvid == null || bvid.isEmpty) return;
    final aid = BvAv.decode(bvid);
    if (aid == null || aid <= 0) return;
    showNoteEditorPage(context, bvid: bvid, aid: aid, videoTitle: _pageTitle());
  }

                                  
                                          
  double? _commentsPanelProgress() {
    final st = _playerKey.currentState;
    if (st == null || !_started) return null;
    return st.player.state.position.inMilliseconds / 1000.0;
  }

                                    
  Future<Uint8List?> _commentsPanelCaptureFrame() async {
    final st = _playerKey.currentState;
    if (st == null) return null;
    return st.captureCurrentFrame();
  }

                                   
                         
  void _expandAndPlay() {
    _startExpandAnimation();
    if (!_started) {
      _startPlayback();
      return;
    }
    final st = _playerKey.currentState;
    if (st == null) return;
    if (st.player.state.playing) return;
    st.player.play();
  }

                                        
  void _startExpandAnimation() {
    final current = _collapseNotifier.value;
    if (current <= 0) return;            
    _expandStartCollapse = current;
    _expandController
      ..reset()
      ..forward();
  }

                                   
                                                    
  Widget _buildCollapsedFrostedBar() {
    return FrostedPanel(
      blurSigma: 10,
      opacity: 0.75,
      child: _buildCollapsedBarContent(),
    );
  }

                          
                                    
                                              
                    
  Widget _buildCoverImage() {
    final detail = _detail;
    final cover = detail?.pic ?? widget.initialCover ?? '';
    final cs = Theme.of(context).colorScheme;

    final fallbackIcon = Icon(
      Icons.movie_outlined,
      color: cs.onSurfaceVariant.withValues(alpha: 0.45),
      size: 56,
    );

    if (cover.isEmpty) return Center(child: fallbackIcon);
    return Image(
      image: CachedImageProvider(
        cover,
        headers: NetworkSettingsService.instance.apiHeaders.isEmpty
            ? null
            : NetworkSettingsService.instance.apiHeaders,
                                  
        cacheWidth: 640,
      ),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(child: fallbackIcon),
    );
  }

                                                       
                                              
  Widget _buildCover({bool collapsed = false}) {
    final heroTag = widget.heroTag;
    final cs = Theme.of(context).colorScheme;

    final coverImage = _buildCoverImage();

                                     
                                               
                                       
    if (collapsed) {
      return Stack(
        fit: StackFit.expand,
        children: [coverImage, _buildCollapsedFrostedBar()],
      );
    }

    Widget coverWidget = coverImage;
                                             
                                       
                                             
                                          
    if (heroTag != null &&
        !_zoomHeroBlocksInnerHeroes &&
        (!SettingsService.heroTransitionBlurEnabled ||
            (widget.wideClassic && _isWideScreen))) {
      coverWidget = Hero(
        transitionOnUserGestures: true,
        tag: heroTag,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: coverWidget,
      );
    }

                                           
    return ColoredBox(
                                    
      color: cs.surfaceContainerLow,
      child: Stack(
        fit: StackFit.expand,
        children: [
          coverWidget,
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _startPlayback,
              splashColor: cs.primary.withValues(alpha: 0.10),
              highlightColor: cs.primary.withValues(alpha: 0.06),
              child: const SizedBox.expand(),
            ),
          ),
                                               
          if (_showPlayButton)
            Positioned(
              right: 16,
              bottom: 16,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _startPlayback,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SvgPicture.asset(
                      'assets/bili_icons/play.svg',
                      width: 32,
                      height: 32,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
                                           
                                                    
          Positioned(
            top: 0,
            left: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
              child: _buildBackButton(transparent: true),
            ),
          ),
                                               
                                              
                                                           
                                                 
          Positioned(
            top: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
              child: SizedBox(
                width: 40,
                height: 40,
                child: _buildTopMoreMenu(transparent: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

                  
  Widget _faceFallback(ColorScheme cs) {
    return Container(
      width: 40,
      height: 40,
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.person, color: cs.onSurfaceVariant, size: 24),
    );
  }

  Widget _buildStats(ColorScheme cs) {
                                        
                               
    if (!_isWideScreen) {
      return Row(
        children: [
          _stat(cs, Icons.play_arrow_rounded, _fmtCount(_detail!.view)),
          _stat(cs, Icons.subtitles_outlined, _fmtCount(_detail!.danmaku)),
          _stat(cs, Icons.schedule, _fmtDate(_detail!.pubdate)),
          const Spacer(),
          if (_onlineCount > 0)
            _stat(
              cs,
              Icons.visibility_outlined,
              AppLocalizations.of(
                context,
              ).videoStatWatching(_fmtCount(_onlineCount)),
            ),
        ],
      );
    }
    return Row(
      children: [
        _stat(cs, Icons.play_arrow_rounded, _fmtCount(_detail!.view)),
        _stat(cs, Icons.subtitles_outlined, _fmtCount(_detail!.danmaku)),
        _stat(cs, Icons.thumb_up_alt_outlined, _fmtCount(_likeCount)),
        _stat(cs, Icons.video_collection_outlined, '${_detail!.pages.length}P'),
        const Spacer(),
        Text(
          _fmtDate(_detail!.pubdate),
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _stat(ColorScheme cs, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageChip(ColorScheme cs, int index) {
    final detail = _detail!;
    final page = detail.pages[index];
    final selected = index == _pageIndex;
    return Material(
      color: selected ? cs.primary : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _switchPage(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            page.part.isNotEmpty ? page.part : 'P${page.page}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

                                              
                                              
class _TripleArc extends StatelessWidget {
  final double progress;              
  final Color color;

  const _TripleArc({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        painter: _TripleArcPainter(progress: progress, color: color),
      ),
    );
  }
}

class _TripleArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _TripleArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final radius = size.width / 2;
    final rect = Rect.fromCircle(
      center: Offset(radius, radius),
      radius: radius - 1,
    );
    canvas.drawArc(rect, -math.pi / 2, progress * 2 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant _TripleArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
