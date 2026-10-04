import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/screens/bilibili_comments_page.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bilibili_interaction_service.dart';
import 'package:naviflash/services/bilibili_recommend_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/bilibili_video_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/player_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/fav_folder_picker.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/glass_bottom_bar.dart';
import 'package:naviflash/widgets/more_menu_sheet.dart';
import 'package:naviflash/widgets/navi_video_surface.dart';
import 'package:naviflash/widgets/page_loading.dart';
import 'package:naviflash/widgets/pendant_avatar.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/danmaku/danmaku_controller.dart';
import 'package:naviflash/widgets/danmaku/danmaku_fetcher.dart';
import 'package:naviflash/widgets/danmaku/danmaku_model.dart';
import 'package:naviflash/widgets/danmaku/danmaku_send_sheet.dart';
import 'package:naviflash/widgets/danmaku/danmaku_view.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart' show MorphIconButton;
import 'package:flutter_svg/flutter_svg.dart';

                     
   
                                          
                                      
                         
   
                                       
                  
class BilibiliShortsPage extends StatefulWidget {
  const BilibiliShortsPage({
    super.key,
    this.onNavTabSelected,
    this.embeddedInShell = false,
    this.bottomBarInset,
  });

                                                      
                                   
  final void Function(String id)? onNavTabSelected;

                                             
                                               
  final bool embeddedInShell;

                         
     
                                                       
                                                                     
                                         
                                   
  final double? bottomBarInset;

  @override
  State<BilibiliShortsPage> createState() => BilibiliShortsPageState();
}

class BilibiliShortsPageState extends State<BilibiliShortsPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
                                      
     
                                                              
     
                                                              
                                                              
                                                           
     
                                    
                                                                       
                                                                                                
                                                       
                                                   
                                    
     
                                                      
                                                      
                                                      
                                    
     
                                                    
  double get _bottomBarReserve => widget.bottomBarInset ?? 0;

  static const Map<String, String> _mediaHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  final PageController _pageCtrl = PageController();

                                        
                                            
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

                     
  bool _refreshing = false;

  final List<BiliRecommendItem> _items = [];
  final List<String?> _urls = [];
  final Set<int> _resolving = {};

                                                         
                                                    
                                               
                          
  final GlobalKey<NaviVideoSurfaceState> _surfaceKey =
      GlobalKey<NaviVideoSurfaceState>();
  final Set<String> _liked = {};
  final Set<String> _disliked = {};
  final Set<String> _likeBusy = {};
  final Map<String, int> _likeCount = {};

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  int _freshIdx = 0;
  int _current = 0;
  bool _commentsOpen = false;

                                     
  double _commentsExtent = 0.62;

                               
  static const Duration _videoShiftDuration = Duration(milliseconds: 280);
  static const Curve _videoShiftCurve = Curves.easeOutCubic;

                                           
     
                                                
                                           
     
                                                        
                                                          
                                                                              
  late final AnimationController _commentsBackCtrl;

                                                     
  bool _commentsBackOwned = false;

                                    
  BiliUserSpaceCard? _upCard;
  int _upCardMid = 0;

                  
  int _onlineCount = 0;

                                 
  final Map<int, bool> _followedOverride = {};
  final Set<int> _followBusy = {};

                              
  final DanmakuController _danmaku = DanmakuController();
  bool _danmakuLoaded = false;

                          
  int _danmakuCid = 0;

                                             
  bool _paused = false;

                 
                       
  bool _speedHeld = false;

                          
  bool _speedLocked = false;

                      
  bool _speedDidLock = false;

                                   
  bool _speedCancelGesture = false;

                       
  Timer? _speedCancelFlashTimer;
  bool _speedCancelFlash = false;

                
  static const double _edgeSpeedRate = 2.0;

                 
  static const double _edgeSpeedZoneWidth = 44.0;

                      
  static const double _speedLockDragDp = 56.0;

                 
  final List<_LikeBurstToken> _likeBursts = [];
  int _likeBurstSeq = 0;

  @override
  void initState() {
    super.initState();
                                                       
    _commentsBackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(_onBackProgressTick);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load(refresh: true));
    unawaited(_danmaku.restoreSettings());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speedCancelFlashTimer?.cancel();
    _commentsBackCtrl.dispose();
    _danmaku.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

                    
     
                                                     
                                        
              
                                                       
                                                         
                                      
                                                       
                                        
                                      
                                               
  bool _activated = false;

                                                      
  bool get playbackActivated => _activated;

                                    
  void pausePlayback() {
    _activated = false;
    unawaited(_surfaceKey.currentState?.pause());
    _danmaku.pause();
  }

                                   
  void resumePlayback() {
    _activated = true;
                                        
                                                
    if (_commentsOpen || _paused) return;
    _danmaku.play();
    unawaited(_startPlayback());
  }

                                                        
  Future<void> _startPlayback() async {
    final surface = _surfaceKey.currentState;
    if (surface == null) return;
    if (surface.isReady) {
      await surface.play();
      return;
    }
                              
    await surface.open();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
                                  
    final surface = _surfaceKey.currentState;
    if (surface == null) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(surface.pause());
    } else if (state == AppLifecycleState.resumed) {
                                               
                                                 
      if (!_activated || _paused) return;
      unawaited(surface.play());
    }
  }

  void _onBackProgressTick() {
    if (mounted) setState(() {});
  }

                                      
  void _closeComments() {
    if (!_commentsOpen) return;
    _commentsBackCtrl.value = 0;
    setState(() {
      _commentsOpen = false;
      _commentsExtent = 0.62;
    });
  }

                            
    
                                   
                                                      
                                         
                                      
                                           
                       
  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
                                     
    if (backEvent.isButtonEvent) {
      debugPrint('[Shorts] backGesture: 按键事件，交回系统');
      return false;
    }
    if (!_commentsOpen || !mounted) {
      debugPrint('[Shorts] backGesture: 评论未展开，交回系统（正常弹栈）');
      return false;
    }
                                     
                                         
                            
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      debugPrint('[Shorts] backGesture: 本页非栈顶，不接管');
      return false;
    }
    _commentsBackOwned = true;
    _commentsBackCtrl.value = backEvent.progress;
    debugPrint('[Shorts] backGesture: 已接管，进度=${backEvent.progress}');
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (!_commentsBackOwned) return;
    _commentsBackCtrl.value = backEvent.progress;
  }

  @override
  void handleCommitBackGesture() {
    if (!_commentsBackOwned) return;
    _commentsBackOwned = false;
    _closeComments();
  }

  @override
  void handleCancelBackGesture() {
    if (!_commentsBackOwned) return;
    _commentsBackOwned = false;
                     
    _commentsBackCtrl.animateBack(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

                                            
  void _syncUrlSlots() {
    while (_urls.length < _items.length) {
      _urls.add(null);
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loadingMore) return;
    if (!refresh && !_hasMore) return;

    setState(() {
      if (refresh) {
        _loading = _items.isEmpty;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });

    final source = context.read<SettingsService>().recommendSource;
    final freshIdx = _freshIdx;
    BiliRecommendResult<BiliRecommendItem> result;
    try {
      result = await BilibiliRecommendService.fetch(
        source: source,
        freshIdx: freshIdx,
      );
    } catch (e) {
      result = BiliRecommendError<BiliRecommendItem>('$e');
    }
    if (!mounted) return;

    setState(() {
      _loading = false;
      _loadingMore = false;
      switch (result) {
        case BiliRecommendOk<BiliRecommendItem>(:final items):
          if (items.isEmpty) {
            _hasMore = false;
            break;
          }
          final seen = _items.map((e) => e.bvid).toSet();
          for (final item in items) {
            if (item.bvid.isEmpty || !seen.add(item.bvid)) continue;
            _items.add(item);
          }
          _syncUrlSlots();
          _freshIdx = freshIdx + 1;
        case BiliRecommendError<BiliRecommendItem>(:final detail):
          _error = detail;
          _hasMore = false;
      }
    });

    unawaited(_prefetch(_current));
  }

                                           
                                    
     
                                       
                                     
  void refreshViaIndicator() {
    if (_items.isEmpty) {
      unawaited(_load(refresh: true));
      return;
    }
    _refreshKey.currentState?.show();
  }

                                                
                                             
                  
  Future<void> _refreshFeed() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final source = context.read<SettingsService>().recommendSource;
      final BiliRecommendResult<BiliRecommendItem> result;
      try {
        result = await BilibiliRecommendService.fetch(
          source: source,
          freshIdx: 0,
        );
      } catch (e) {
        if (mounted) showAppToast(context, '$e', error: true);
        return;
      }
      if (!mounted) return;
      switch (result) {
        case BiliRecommendOk<BiliRecommendItem>(:final items):
          final seen = <String>{};
          final fresh = items
              .where(
                (v) => v.bvid.isNotEmpty && seen.add(v.bvid),
              )
              .toList(growable: false);
          if (fresh.isEmpty) {
            showAppToast(context, '暂时没有新的短视频');
            return;
          }
                                                        
                                             
                         
          unawaited(_surfaceKey.currentState?.pause());
                                
          _resetSpeed();
          if (_pageCtrl.hasClients &&
              (_pageCtrl.page?.round() ?? _current) != 0) {
            _pageCtrl.jumpToPage(0);
          }
          setState(() {
            _items
              ..clear()
              ..addAll(fresh);
            _urls
              ..clear()
              ..addAll(List<String?>.filled(fresh.length, null));
            _resolving.clear();
            _freshIdx = 1;
            _hasMore = true;
            _error = null;
            _loading = false;
            _loadingMore = false;
            _current = 0;
            _commentsOpen = false;
            _commentsExtent = 0.62;
            _paused = false;
                                                 
            _danmakuCid = 0;
            _danmakuLoaded = false;
            _danmaku.setItems(const []);
            _upCard = null;
            _upCardMid = 0;
            _onlineCount = 0;
          });
          unawaited(_prefetch(0));
        case BiliRecommendError<BiliRecommendItem>(:final detail):
          if (mounted) showAppToast(context, detail, error: true);
      }
    } finally {
      _refreshing = false;
    }
  }

                                
  Future<void> _prefetch(int index) async {
    for (var i = index; i <= index + 1; i++) {
      if (i < 0 || i >= _items.length) continue;
      if ((i < _urls.length && _urls[i] != null) ||
          _resolving.contains(i)) {
        continue;
      }
      _resolving.add(i);
      String? url;
      try {
        final play = await BilibiliVideoService.fetchPlayUrl(
          bvid: _items[i].bvid,
          cid: _items[i].cid,
        );
        if (play != null) {
          url = BilibiliVideoService.buildPlayableUrl(play);
        }
      } catch (_) {
        url = null;
      }
      _resolving.remove(i);
      if (!mounted) return;
      setState(() {
        while (_urls.length <= i) {
          _urls.add(null);
        }
        _urls[i] = url;
      });
                                         
      if (i == _current && url != null && url.isNotEmpty) {
        unawaited(_loadDanmaku(_items[i]));
        unawaited(_loadUpInfo(_items[i]));
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _current = index;
      _commentsOpen = false;
      _commentsExtent = 0.62;
                               
      _paused = false;
                                            
      _resetSpeed();
    });
    unawaited(_prefetch(index));
    if (index < _items.length) {
      unawaited(_loadDanmaku(_items[index]));
      unawaited(_loadUpInfo(_items[index]));
    }
    if (_items.isNotEmpty && index >= _items.length - 3) {
      unawaited(_load());
    }
  }

                                                            
    
             
                                               
                                             
                                   
    
                                                                 
                                       
                                     

                                               
  void _resetSpeed() {
    _speedHeld = false;
    _speedLocked = false;
    _speedDidLock = false;
    _speedCancelGesture = false;
    _speedCancelFlash = false;
    _speedCancelFlashTimer?.cancel();
    _speedCancelFlashTimer = null;
    unawaited(_surfaceKey.currentState?.setRate(1.0));
  }

  void _onEdgeLongPressStart() {
    if (!mounted) return;
                      
    if (_speedLocked) {
      _speedCancelGesture = true;
      _speedLocked = false;
      unawaited(_surfaceKey.currentState?.setRate(1.0));
      HapticFeedback.mediumImpact();
      _speedCancelFlashTimer?.cancel();
      setState(() {
        _speedHeld = false;
        _speedCancelFlash = true;
      });
      _speedCancelFlashTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _speedCancelFlash = false);
      });
      return;
    }
    _speedCancelGesture = false;
    _speedDidLock = false;
    _speedHeld = true;
    unawaited(_surfaceKey.currentState?.setRate(_edgeSpeedRate));
    setState(() {});
  }

  void _onEdgeLongPressMove(LongPressMoveUpdateDetails d) {
    if (!_speedHeld || _speedDidLock) return;
                                                      
    if (d.localOffsetFromOrigin.dy >= _speedLockDragDp) {
      _speedDidLock = true;
      _speedLocked = true;
      HapticFeedback.mediumImpact();
      setState(() {});
    }
  }

  void _onEdgeLongPressEnd() {
                           
    if (_speedCancelGesture) {
      _speedCancelGesture = false;
      return;
    }
    if (!_speedHeld) return;
    _speedHeld = false;
                          
    if (!_speedDidLock) {
      _speedLocked = false;
      unawaited(_surfaceKey.currentState?.setRate(1.0));
    }
    _speedDidLock = false;
    if (mounted) setState(() {});
  }

  void _onEdgeLongPressCancel() {
                                          
    if (_speedCancelGesture) {
      _speedCancelGesture = false;
      return;
    }
    _speedHeld = false;
    if (!_speedDidLock) {
      _speedLocked = false;
      unawaited(_surfaceKey.currentState?.setRate(1.0));
    }
    _speedDidLock = false;
    if (mounted) setState(() {});
  }

                                                           

                                           
  void _onSingleTap() {
    if (_commentsOpen) {
      _closeComments();
      return;
    }
    _togglePlay();
  }

                                     
  void _togglePlay() {
    final state = _surfaceKey.currentState;
    if (state == null) return;
    final willPause = state.isPlaying;
    unawaited(state.togglePlay());
    if (willPause) {
      _danmaku.pause();
    } else {
      _danmaku.play();
    }
    setState(() => _paused = willPause);
  }

                                          
  void _onDoubleTapLike(BiliRecommendItem item, Offset localPosition) {
    if (!_liked.contains(item.bvid)) {
      unawaited(_toggleLike(item));
    }
    final token = _LikeBurstToken(++_likeBurstSeq, localPosition);
    _likeBursts.add(token);
    setState(() {});
                                     
    Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_likeBursts.remove(token)) setState(() {});
    });
  }

  bool _isFollowed(BiliRecommendItem item) =>
      _followedOverride[item.ownerMid] ?? item.isFollowed;

                                       
     
                                        
  Future<void> _loadUpInfo(BiliRecommendItem item) async {
    final mid = item.ownerMid;
    if (mid <= 0) return;
    if (_upCardMid != mid) {
      _upCardMid = mid;
      if (mounted) {
        setState(() {
          _upCard = null;
          _onlineCount = 0;
        });
      }
    }
    final card = await BilibiliUserSpaceService.fetchUserCard(mid: mid);
    if (!mounted || _upCardMid != mid) return;
    if (card != null) setState(() => _upCard = card);

    final total = await BilibiliVideoService.fetchOnlineTotal(
      aid: item.aid,
      bvid: item.bvid,
      cid: item.cid,
    );
    if (!mounted || _upCardMid != mid) return;
    setState(() => _onlineCount = total);
  }

                              
  Future<void> _toggleFollow(BiliRecommendItem item) async {
    final mid = item.ownerMid;
    if (mid <= 0 || _followBusy.contains(mid)) return;
    final followed = _isFollowed(item);
    _followBusy.add(mid);
    final res = await BilibiliInteractionService.followUser(
      mid: mid,
      act: followed ? 2 : 1,
    );
    _followBusy.remove(mid);
    if (!mounted) return;
    if (!res.ok) {
      showAppToast(context, res.message, error: true);
      return;
    }
    setState(() => _followedOverride[mid] = !followed);
  }

                   
     
                                             
                                 
  Future<void> _loadDanmaku(BiliRecommendItem item) async {
    if (item.cid <= 0 || _danmakuCid == item.cid) return;
    _danmakuCid = item.cid;
    if (_danmakuLoaded) setState(() => _danmakuLoaded = false);
    final result = await DanmakuSegFetcher.fetch(
      input: item.bvid,
      inputType: 'bv',
    );
    if (!mounted || _danmakuCid != item.cid) return;
    if (!result.success || result.items.isEmpty) return;
    _danmaku.setItems(result.items);
    final pos = _surfaceKey.currentState?.position ?? Duration.zero;
    _danmaku.seekTo(pos.inMilliseconds / 1000.0);
    if (_surfaceKey.currentState?.isPlaying ?? false) {
      _danmaku.play();
    }
    setState(() => _danmakuLoaded = true);
  }

                             
  void _onVideoPosition(Duration pos) {
    if (!_danmakuLoaded) return;
    final sec = pos.inMilliseconds / 1000.0;
    if ((sec - _danmaku.currentTime).abs() > 2.0) {
      _danmaku.seekTo(sec);
    } else {
      _danmaku.syncTime(sec);
    }
  }

                                 
  void _toggleDanmakuEnabled() {
    setState(() => _danmaku.enabled = !_danmaku.enabled);
    _danmaku.onNeedRepaint?.call();
    _danmaku.persistSettings();
  }

                                  
  Future<void> _sendShortsDanmaku(BiliRecommendItem item) async {
    if (item.cid <= 0) return;
    final style = await showDanmakuSendSheet(
      context,
                                     
                       
      bottomPadding: _bottomBarReserve,
                 
      aid: item.aid,
    );
    if (style == null || !mounted) return;
    final posMs =
        (_surfaceKey.currentState?.position ?? Duration.zero).inMilliseconds;
    final res = await DanmakuSegFetcher.sendDanmaku(
      oid: item.aid.toString(),
      cid: item.cid.toString(),
      msg: style.msg,
      progress: posMs,
      mode: style.mode,
      color: style.color,
      fontSize: style.fontSize,
    );
    if (!mounted) return;
    if (!res.ok) {
      showAppToast(context, res.message, error: true);
      return;
    }
    showAppToast(context, '弹幕已发送');
    if (!_danmaku.enabled) {
      _danmaku.enabled = true;
      _danmaku.onNeedRepaint?.call();
    }
    _danmaku.addItem(
      DanmakuItem(
        time: posMs / 1000.0,
        mode: style.mode == 5
            ? DanmakuMode.top
            : style.mode == 4
            ? DanmakuMode.bottom
            : DanmakuMode.scrollRightToLeft,
        fontSize: style.fontSize.toDouble(),
        color: Color(0xFF000000 | (style.color & 0xFFFFFF)),
        content: style.msg,
      ),
    );
    setState(() {});
  }

                                                  
  Future<void> _showMoreMenu(BiliRecommendItem item) async {
    await showMoreMenuSheet(
      context: context,
      title: '更多',
      actions: [
        MoreMenuAction(
          icon: Icons.visibility_off_outlined,
          label: '不感兴趣',
          onTap: () => _hideItem(item),
        ),
        MoreMenuAction(
          icon: Icons.link,
          label: '复制链接',
          onTap: () => unawaited(_copyLink(item)),
        ),
        MoreMenuAction(
          icon: Icons.info_outline,
          label: '查看详情',
          onTap: () => _openVideoPage(item),
        ),
        MoreMenuAction(
          icon: Icons.refresh,
          label: '刷新列表',
                                             
          onTap: refreshViaIndicator,
        ),
      ],
    );
  }

                             
  void _hideItem(BiliRecommendItem item) {
    final idx = _items.indexWhere((e) => e.bvid == item.bvid);
    if (idx < 0) return;
    setState(() {
      _items.removeAt(idx);
      if (idx < _urls.length) _urls.removeAt(idx);
      if (_current >= _items.length && _current > 0) {
        _current = _items.length - 1;
      }
    });
    showAppToast(context, '已减少此类推荐');
  }

              
     
                                                        
                                          
  Future<void> _exitFullscreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

                                                        
     
                                                      
                                         
                                         
     
                                                                
                                                       
                                   
     
                               
  void _enterFullscreen(BiliRecommendItem item) => _openVideoPage(
    item,
    startFullscreen: true,
    position: _surfaceKey.currentState?.position,
  );

  Future<void> _toggleLike(BiliRecommendItem item) async {
    if (_likeBusy.contains(item.bvid)) return;
    final liked = _liked.contains(item.bvid);
    _likeBusy.add(item.bvid);
    final res = await BilibiliInteractionService.likeVideo(
      aid: item.aid,
      like: !liked,
    );
    _likeBusy.remove(item.bvid);
    if (!mounted) return;
    if (!res.ok) {
      showAppToast(context, res.message, error: true);
      return;
    }
    setState(() {
      if (liked) {
        _liked.remove(item.bvid);
        _likeCount[item.bvid] = (_likeCount[item.bvid] ?? item.like) - 1;
      } else {
        _liked.add(item.bvid);
        _likeCount[item.bvid] = (_likeCount[item.bvid] ?? item.like) + 1;
      }
    });
  }

                                  
  Future<void> _toggleDislike(BiliRecommendItem item) async {
    if (_likeBusy.contains(item.bvid)) return;
    final disliked = _disliked.contains(item.bvid);
    _likeBusy.add(item.bvid);
    final res = await BilibiliInteractionService.dislikeVideo(
      aid: item.aid,
      dislike: !disliked,
    );
    _likeBusy.remove(item.bvid);
    if (!mounted) return;
    if (!res.ok) {
      showAppToast(context, res.message, error: true);
      return;
    }
    setState(() {
      if (disliked) {
        _disliked.remove(item.bvid);
      } else {
        _disliked.add(item.bvid);
      }
    });
  }

  Future<void> _copyLink(BiliRecommendItem item) async {
    await Clipboard.setData(
      ClipboardData(text: 'https://www.bilibili.com/video/${item.bvid}'),
    );
    if (!mounted) return;
    showAppToast(context, '链接已复制');
  }

             
                                                    
                                         
                                 
                            
  void _openVideoPage(
    BiliRecommendItem item, {
    bool startFullscreen = false,
    Duration? position,
  }) {
                                     
    unawaited(_surfaceKey.currentState?.pause());
    Navigator.of(context)
        .push<void>(
                                                   
          ImmersiveMaterialPageRoute<void>(
            page: BilibiliVideoPage(
              bvid: item.bvid,
              initialTitle: item.title,
              initialCover: item.cover,
              initialPosition: position,
              startFullscreen: startFullscreen,
            ),
          ),
        )
        .then((_) {
                                                  
          if (mounted && _activated && !_paused) {
            unawaited(_startPlayback());
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        Positioned.fill(child: _buildBody()),
        Positioned(left: 4, top: 8, child: _buildTopBar()),
      ],
    );
    return PopScope(
                                       
      canPop: !_commentsOpen,
      onPopInvokedWithResult: (didPop, _) {
        debugPrint('[Shorts] PopScope: didPop=$didPop commentsOpen=$_commentsOpen');
        if (didPop) return;
        _closeComments();
      },
      child: widget.embeddedInShell
                                    
          ? ColoredBox(color: Colors.black, child: content)
          : Scaffold(
              backgroundColor: Colors.black,
                                               
              extendBody: true,
              bottomNavigationBar: _buildNavBar(),
              body: content,
            ),
    );
  }

                                   
     
                                     
                         
  Widget _buildNavBar() {
    List<String> order;
    bool useM3 = false;
    try {
      final settings = context.watch<SettingsService>();
      order = settings.bottomNavOrder;
      useM3 = settings.useM3BottomBar;
    } on ProviderNotFoundException {
      order = const ['home', 'shorts', 'dynamics', 'live'];
    }
    if (order.isEmpty) order = const ['home', 'shorts', 'dynamics', 'live'];
    final l10n = L10n.current;
    return DecoratedBox(
                                        
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35)),
      child: SafeArea(
        top: false,
                                        
        bottom: !useM3,
        child: Padding(
          padding: useM3
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: AppBottomBar(
            tabs: [for (final id in order) navItemTab(id, l10n)],
            selectedIndex: order.indexOf('shorts'),
            onTabSelected: (index) {
              if (index < 0 || index >= order.length) return;
              final id = order[index];
                                              
              if (id == 'shorts') {
                refreshViaIndicator();
                return;
              }
              final cb = widget.onNavTabSelected;
              if (cb != null) {
                cb(id);
                return;
              }
              Navigator.of(context).maybePop();
            },
          ),
        ),
      ),
    );
  }

                                 
  Widget _buildTopBar() {
    final count = _onlineCount;
    return SafeArea(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
                                       
          if (!widget.embeddedInShell) _buildBackButton(),
          if (count > 0) ...[
            if (!widget.embeddedInShell) const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people_alt_outlined,
                    size: 15,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    L10n.current.danmakuWatching('$count'),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackButton() {
                                       
    return MorphIconButton(
      icon: Icons.arrow_back_rounded,
      iconColor: Colors.white,
      tooltip: L10n.current.commonBackTooltip,
      frosted: true,
      onTap: () => Navigator.of(context).maybePop(),
    );
  }

  Widget _buildBody() {
                                                                
                                              
                                                       
                                            
    return AppRefreshIndicator(
      refreshIndicatorKey: _refreshKey,
      onRefresh: _refreshFeed,
      color: Colors.white,
                                             
      edgeOffset: MediaQuery.paddingOf(context).top + 8,
      displacement: 40,
      notificationPredicate: (_) => false,
      child: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _items.isEmpty,
    )) {
      return const PageLoadingIndicator(colorOverride: Colors.white);
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _error ?? L10n.current.shortsEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return PageView.builder(
      controller: _pageCtrl,
      scrollDirection: Axis.vertical,
                                      
                                             
      physics: _commentsOpen
          ? const NeverScrollableScrollPhysics()
          : null,
      onPageChanged: _onPageChanged,
      itemCount: _items.length,
      itemBuilder: (context, index) => landscape
          ? _buildLandscapeItem(index)
          : _buildPortraitItem(index),
    );
  }

                                          
  Widget _buildPortraitItem(int index) {
    final item = _items[index];
    final media = MediaQuery.of(context);
    final screenH = media.size.height;
    final bottomInset = media.padding.bottom;
    final isCurrent = index == _current;
    final commentsOpen = _commentsOpen && isCurrent;
                                          
                           
    final shrinkVideo =
        commentsOpen && (_surfaceKey.currentState?.isLandscapeVideo ?? false);
                                     
    final backProgress = _commentsBackCtrl.value;
    final effectiveExtent = _commentsExtent * (1 - backProgress);
    final videoH = shrinkVideo
        ? (screenH * (1 - effectiveExtent)).clamp(140.0, screenH)
        : screenH;
                             
    final actionBottom = commentsOpen
        ? screenH * effectiveExtent + 12
        : bottomInset + 132 + _bottomBarReserve;
                                     
    final gesturing = _commentsBackOwned || _commentsBackCtrl.isAnimating;
    final shiftDuration = gesturing ? Duration.zero : _videoShiftDuration;

                                 
                                            
    const danmakuSafeTop = 52.0;
    final danmakuSafeBottom = 164.0 + _bottomBarReserve;
    final danmakuTop = media.padding.top + danmakuSafeTop;
    final danmakuHeight = (videoH - danmakuTop - bottomInset - danmakuSafeBottom)
        .clamp(50.0, videoH);
    return Stack(
      fit: StackFit.expand,
      children: [
                                         
        AnimatedPositioned(
          duration: shiftDuration,
          curve: _videoShiftCurve,
          top: 0,
          left: 0,
          right: 0,
          height: videoH,
          child: _buildVideo(index, item),
        ),
                             
        if (isCurrent && _danmakuLoaded)
          AnimatedPositioned(
            duration: shiftDuration,
            curve: _videoShiftCurve,
            top: danmakuTop,
            left: 0,
            right: 0,
            height: danmakuHeight,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: DanmakuView(controller: _danmaku),
              ),
            ),
          ),
                                       
                                                 
                                                
        if (isCurrent) ..._buildEdgeSpeedZones(),
                                 
                                
        AnimatedPositioned(
          duration: shiftDuration,
          curve: _videoShiftCurve,
          top: 0,
          left: 0,
          right: 0,
          height: videoH,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _onSingleTap,
            onDoubleTapDown: (d) =>
                _onDoubleTapLike(item, d.localPosition),
          ),
        ),
                      
        if (isCurrent && _likeBursts.isNotEmpty)
          Positioned.fill(child: _buildLikeBursts()),
                                 
        if (isCurrent) _buildSpeedOverlay(media.padding.top),
                                        
        if (isCurrent && _paused)
          AnimatedPositioned(
            duration: shiftDuration,
            curve: _videoShiftCurve,
            top: 0,
            left: 0,
            right: 0,
            height: videoH,
            child: Center(child: _buildPauseBadge()),
          ),
        Positioned(
          right: 10,
          bottom: actionBottom,
          child: _buildActionBar(item),
        ),
        if (!commentsOpen)
          Positioned(
            left: 16,
            right: 84,
            bottom: bottomInset + 60 + _bottomBarReserve,
            child: _buildMeta(item),
          ),
                
        Positioned(
          top: media.padding.top + 8,
          right: 12,
          child: _buildMoreButton(item),
        ),
        if (!commentsOpen)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 8 + _bottomBarReserve,
            child: _buildBottomBar(item),
          ),
        if (commentsOpen) _buildCommentsSheet(item),
      ],
    );
  }

                                                
  List<Widget> _buildEdgeSpeedZones() {
    Widget zone() => GestureDetector(
      behavior: HitTestBehavior.opaque,
                                                  
                                             
      onLongPressStart: (_) => _onEdgeLongPressStart(),
      onLongPressMoveUpdate: _onEdgeLongPressMove,
      onLongPressEnd: (_) => _onEdgeLongPressEnd(),
      onLongPressCancel: _onEdgeLongPressCancel,
    );
    return [
      Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        width: _edgeSpeedZoneWidth,
        child: zone(),
      ),
      Positioned(
        top: 0,
        bottom: 0,
        right: 0,
        width: _edgeSpeedZoneWidth,
        child: zone(),
      ),
    ];
  }

                                          
  Widget _buildSpeedOverlay(double topInset) {
    if (_speedHeld) {
      final lockedNow = _speedDidLock;
      return Positioned(
        top: topInset + 72,
        left: 0,
        right: 0,
        child: Center(
          child: _SpeedPill(
            icon: lockedNow ? Icons.lock_clock : Icons.fast_forward_rounded,
            text: lockedNow ? '已锁定 ${_edgeSpeedRate}x' : '倍速播放中',
            hint: lockedNow ? '松手保持倍速' : '下拉锁定倍速',
          ),
        ),
      );
    }
    if (_speedCancelFlash) {
      return Positioned(
        top: topInset + 72,
        left: 0,
        right: 0,
        child: Center(
          child: _SpeedPill(
            icon: Icons.play_arrow_rounded,
            text: '已取消倍速',
            hint: null,
          ),
        ),
      );
    }
    if (_speedLocked) {
                               
      return Positioned(
        top: topInset + 56,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.fast_forward_rounded,
                  size: 15,
                  color: Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  '${_edgeSpeedRate}x 已锁定 · 长按边缘取消',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

                                       
  Widget _buildLikeBursts() {
    return IgnorePointer(
      child: Stack(
        children: [
          for (final t in _likeBursts)
            Positioned(
              left: t.position.dx - 45,
              top: t.position.dy - 45,
              width: 90,
              height: 90,
              child: _LikeBurst(key: ValueKey(t.id)),
            ),
        ],
      ),
    );
  }

                           
  Widget _buildLandscapeItem(int index) {
    final item = _items[index];
    final commentsWidth = (MediaQuery.sizeOf(context).width * 0.34)
        .clamp(280.0, 420.0);
    return Row(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildVideo(index, item),
              if (index == _current && _danmakuLoaded)
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: DanmakuView(controller: _danmaku),
                    ),
                  ),
                ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                                      
                  onTap: index == _current ? _onSingleTap : null,
                  onDoubleTapDown: index == _current
                      ? (d) => _onDoubleTapLike(item, d.localPosition)
                      : null,
                ),
              ),
              if (index == _current && _likeBursts.isNotEmpty)
                Positioned.fill(child: _buildLikeBursts()),
              if (index == _current && _paused)
                Center(child: _buildPauseBadge()),
              Positioned(
                right: 10,
                bottom: 20 + _bottomBarReserve,
                child: _buildActionBar(item),
              ),
                                             
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                right: 12,
                child: Row(
                  children: [
                    _CircleIconButton(
                      onTap: () => unawaited(_exitFullscreen()),
                      icon: Icons.fullscreen_exit,
                    ),
                    const SizedBox(width: 8),
                    _CircleIconButton(
                      onTap: () => unawaited(_showMoreMenu(item)),
                      icon: Icons.more_vert,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 56,
                right: 12,
                bottom: 20 + _bottomBarReserve,
                child: _buildMeta(item),
              ),
            ],
          ),
        ),
        Container(
          width: commentsWidth,
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            left: false,
            child: _buildComments(item),
          ),
        ),
      ],
    );
  }

  Widget _buildVideo(int index, BiliRecommendItem item) {
                                      
    if (index != _current) return _buildCover(item);

    final url = index < _urls.length ? _urls[index] : null;
    final resolving = _resolving.contains(index);
    if (url == null || url.isEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildCover(item),
          if (url == null && resolving)
            const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: LoadingIndicatorM3E(color: Colors.white),
              ),
            ),
        ],
      );
    }
                                                 
                                                   
    return NaviVideoSurface(
      key: _surfaceKey,
      videoUrl: url,
      httpHeaders: _mediaHeaders,
                                                  
                                          
                                                            
      autoPlay: _activated,
      looping: true,
      fit: BoxFit.contain,
      playerSettings: context.read<PlayerSettingsService>(),
      onPositionChanged: _onVideoPosition,
    );
  }

  Widget _buildCover(BiliRecommendItem item) {
    if (item.cover.isEmpty) return const ColoredBox(color: Colors.black);
    return Image(
      image: CachedImageProvider(item.cover),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
    );
  }

                                    
     
                                          
                             
  Widget _buildActionBar(BiliRecommendItem item) {
    final liked = _liked.contains(item.bvid);
    final disliked = _disliked.contains(item.bvid);
    final likeCount = _likeCount[item.bvid] ?? item.like;
    const activeColor = Color(0xFFFB7299);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          onTap: () => unawaited(_toggleLike(item)),
          label: _formatCount(likeCount),
          child: _biliIcon(
            'like.svg',
            size: 32,
            color: liked ? activeColor : Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _ActionButton(
          onTap: () => setState(() => _commentsOpen = !_commentsOpen),
          label: _formatCount(item.danmaku),
          child: _biliIcon('dm.svg', size: 29, color: Colors.white),
        ),
        const SizedBox(height: 16),
        _ActionButton(
          onTap: () => unawaited(_toggleDislike(item)),
          label: '踩',
          child: Transform.flip(
            flipY: true,
            child: _biliIcon(
              'like.svg',
              size: 32,
              color: disliked ? activeColor : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ActionButton(
          onTap: () => unawaited(
            showFavFolderPicker(context, aid: item.aid, title: item.title),
          ),
          label: '收藏',
          child: _biliIcon('fav.svg', size: 32, color: Colors.white),
        ),
        const SizedBox(height: 16),
        _ActionButton(
          onTap: () => unawaited(_copyLink(item)),
          label: '分享',
          child: _biliIcon('share.svg', size: 30, color: Colors.white),
        ),
      ],
    );
  }

                                              
  Widget _buildMeta(BiliRecommendItem item) {
    final card = _upCard;
    final face = (card != null && card.face.isNotEmpty)
        ? card.face
        : item.ownerFace;
    final fans = card?.fans ?? 0;
    final followed = _isFollowed(item);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
                                                 
            PendantAvatar(
              size: 44,
              avatarUrl: face,
              pendantUrl: card?.pendantImage,
              fallback: const Icon(
                Icons.person,
                color: Colors.white38,
                size: 24,
              ),
              onTap: () => _openVideoPage(item),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFB7299),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildFollowButton(item, followed),
                    ],
                  ),
                  if (fans > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${_formatCount(fans)}粉丝',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _openVideoPage(item),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      ],
    );
  }

                               
  Widget _buildFollowButton(BiliRecommendItem item, bool followed) {
    return GestureDetector(
      onTap: () => unawaited(_toggleFollow(item)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: followed ? Colors.white24 : const Color(0xFFFB7299),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!followed) ...[
              const Icon(Icons.add, size: 13, color: Colors.white),
              const SizedBox(width: 2),
            ],
            Text(
              followed ? '已关注' : '关注',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

                                  
     
                                       
  Widget _buildCommentsSheet(BiliRecommendItem item) {
    final cs = Theme.of(context).colorScheme;
    final screenH = MediaQuery.sizeOf(context).height;
    final maxH = (screenH - _bottomBarReserve).clamp(180.0, screenH);
    final height = (screenH * _commentsExtent).clamp(180.0, maxH);
    return Positioned(
      left: 0,
      right: 0,
                                      
      bottom: _bottomBarReserve,
      height: height,
                               
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1, end: 0),
        duration: _videoShiftDuration,
        curve: _videoShiftCurve,
        builder: (context, t, child) => Transform.translate(
                                                  
          offset: Offset(0, (t + _commentsBackCtrl.value) * height),
          child: child,
        ),
        child: Material(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (d) {
                setState(() {
                  _commentsExtent =
                      (_commentsExtent - d.delta.dy / screenH).clamp(0.3, 1.0);
                });
              },
              onVerticalDragEnd: (d) {
                final v = d.velocity.pixelsPerSecond.dy;
                if (v > 900 || _commentsExtent < 0.38) {
                  setState(() {
                    _commentsOpen = false;
                    _commentsExtent = 0.62;
                  });
                } else if (v < -600) {
                  setState(() => _commentsExtent = 1.0);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 6, 4),
                    child: Row(
                      children: [
                        Text(
                          '评论',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Spacer(),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _closeComments,
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildComments(item)),
          ],
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

                                          
  Widget _buildPauseBadge() {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _togglePlay,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: _biliIcon('play.svg', size: 32, color: Colors.white),
        ),
      ),
    );
  }

                 
  Widget _buildMoreButton(BiliRecommendItem item) {
    return _CircleIconButton(
      onTap: () => unawaited(_showMoreMenu(item)),
      icon: Icons.more_vert,
    );
  }

                                            
  Widget _buildBottomBar(BiliRecommendItem item) {
    final dmOn = _danmaku.enabled;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(_sendShortsDanmaku(item)),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: const Text(
                  '发弹幕',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _BarIconButton(
            onTap: _toggleDanmakuEnabled,
            active: dmOn,
            child: _biliIcon(
              dmOn ? 'dm_on.svg' : 'dm_off.svg',
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          _BarIconButton(
            onTap: () => _enterFullscreen(item),
            child: const Icon(Icons.fullscreen, size: 26, color: Colors.white),
          ),
          const SizedBox(width: 10),
          _BarIconButton(
            onTap: () => _openVideoPage(item),
            child: const Icon(
              Icons.article_outlined,
              size: 23,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComments(BiliRecommendItem item) {
    return BilibiliCommentsPage(
      key: ValueKey<String>('shorts_comments_${item.aid}'),
      oid: item.aid,
      upMid: item.ownerMid,
      episodeTitle: item.title,
      heroTagsDisabled: true,
    );
  }

  static String _formatCount(int value) {
    if (value <= 0) return '0';
    if (value >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(1)}亿';
    }
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}万';
    }
    return '$value';
  }
}

                     
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.onTap, required this.icon});

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

                                            
class _BarIconButton extends StatelessWidget {
  const _BarIconButton({
    required this.onTap,
    required this.child,
    this.active = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: 3),
          Container(
            width: 16,
            height: 2,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

                                              
class _LikeBurstToken {
  _LikeBurstToken(this.id, this.position);
  final int id;
  final Offset position;
}

                                           
class _LikeBurst extends StatefulWidget {
  const _LikeBurst({super.key});

  @override
  State<_LikeBurst> createState() => _LikeBurstState();
}

class _LikeBurstState extends State<_LikeBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
                                                     
                                  
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
                                                
        final scale = t < 0.25
            ? Curves.easeOutBack.transform(t / 0.25) * 1.15
            : 1.15 - 0.12 * ((t - 0.25) / 0.75);
        final opacity = t < 0.55 ? 1.0 : (1.0 - (t - 0.55) / 0.45).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, -26 * t),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: const Icon(
                Icons.favorite,
                color: Color(0xFFFB7299),
                size: 82,
                shadows: [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

                               
class _SpeedPill extends StatelessWidget {
  const _SpeedPill({required this.icon, required this.text, this.hint});

  final IconData icon;
  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 34),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

               
                                     
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.child,
    required this.onTap,
    this.label,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          if (label != null) ...[
            const SizedBox(height: 3),
            Text(
              label!,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
