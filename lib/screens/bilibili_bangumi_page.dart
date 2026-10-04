                                         
  
                                                        
                                                  
                                                                
                                                       
                                                       
                                     
                                              
                          
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:naviflash/widgets/app_tooltip.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        Clipboard,
        ClipboardData,
        HapticFeedback,
        SystemChrome,
        SystemUiMode,
        SystemUiOverlay;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/screens/bilibili_comments_page.dart';
import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/screens/pay_coins_page.dart';
import 'package:naviflash/screens/player.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_bangumi_service.dart';
import 'package:naviflash/services/bilibili_favorite_service.dart';
import 'package:naviflash/services/bilibili_interaction_service.dart';
import 'package:naviflash/services/bilibili_video_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/play_history_service.dart';
import 'package:naviflash/services/playback_focus.dart';
import 'package:naviflash/services/playlist_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/danmaku/danmaku_controller.dart';
import 'package:naviflash/widgets/danmaku/danmaku_fetcher.dart';
import 'package:naviflash/widgets/danmaku/danmaku_model.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/ios_zoom_hero.dart';
import 'package:naviflash/widgets/hero_gesture_curve.dart';
import 'package:naviflash/widgets/navi_spring_physics.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/ugc_rich_text.dart';
import 'package:naviflash/screens/bilibili_pgc_review_page.dart';
import 'package:naviflash/widgets/zoom_hero_exit.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

                                     
                                               
                                           
void openBilibiliBangumi(
  BuildContext context, {
  required int seasonId,
  String? initialTitle,
  String? initialCover,
  String? heroTag,
  Duration? initialPosition,
}) {
                                        
  FocusManager.instance.primaryFocus?.unfocus();
                                 
  unawaited(PlaybackFocus.instance.pauseAll());
  final page = BilibiliBangumiPage(
    seasonId: seasonId,
    initialTitle: initialTitle,
    initialCover: initialCover,
    heroTag: heroTag,
    initialPosition: initialPosition,
  );
  Navigator.of(
    context,
  ).push(heroTransitionRoute(heroZoom: heroTag != null, page: page));
}

                                                         
String? bilibiliBangumiFromUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final host = uri.host.toLowerCase();
  if (!host.contains('bilibili.com')) return null;
  final segs = uri.pathSegments;
  for (final seg in segs) {
    final m = RegExp(r'^ss([0-9]+)$').firstMatch(seg);
    if (m != null) return m.group(1);
  }
  return null;
}

                                                                         
const double _tabBarHeight = 45.0;

                                                          
const double _kPlayerCollapsedHeight = 45.0;

class BilibiliBangumiPage extends StatefulWidget
    implements ImmersivePageMarker {
                         
  final int seasonId;
  final String? initialTitle;
  final String? initialCover;

                                              
  final String? heroTag;

                                        
  final Duration? initialPosition;

  const BilibiliBangumiPage({
    super.key,
    required this.seasonId,
    this.initialTitle,
    this.initialCover,
    this.heroTag,
    this.initialPosition,
  });

  @override
  State<BilibiliBangumiPage> createState() => _BilibiliBangumiPageState();
}

class _BilibiliBangumiPageState extends State<BilibiliBangumiPage>
    with TickerProviderStateMixin {
                         
  final GlobalKey<MpvPlayerPageState> _playerKey =
      GlobalKey<MpvPlayerPageState>();
                                        
  final GlobalKey<NavigatorState> _commentsNavKey = GlobalKey<NavigatorState>();
  final DanmakuController _danmaku = DanmakuController();
                                            
  late final AnimationController _tripleController;
  Timer? _tripleTimer;
                                         
  late final AnimationController _expandController;
  double _expandStartCollapse = 0;

  BiliBangumiDetail? _detail;
  BiliPlayUrl? _playUrl;
  String? _error;
  bool _loading = true;
  bool _loadingPlayUrl = false;
  bool _started = false;
  bool _fullscreen = false;
                                          
  bool _zoomHeroActive = true;
  bool _isPlaying = false;
  bool _seenPlaying = false;
  StreamSubscription<bool>? _playingSub;
  bool _controlsVisible = false;
  bool _showPlayButton = false;
  Animation<double>? _routeAnimation;
  AnimationStatusListener? _routeAnimListener;
           
  final ValueNotifier<double> _collapseNotifier = ValueNotifier(0);
  double _playerHeight = 0;
              
  int _epIndex = 0;
  int _currentQn = 0;
  Duration _position = Duration.zero;
  String _currentUrl = '';
  Playlist? _fullPlaylist;
  String _videoTitle = '';
         
  late int _likeCount;
  late int _coinCount;
  late int _favCount;
  late int _followCount;
  bool _hasLiked = false;
  bool _hasFaved = false;
  int _coinGiven = 0;
  bool _hasFollowed = false;
  int _followStatus = 0;                                  
  bool _interacting = false;
  bool _coinWithLike = true;
                  
  List<BiliViewPoint> _viewPoints = [];
  int _onlineCount = 0;
  Timer? _onlineTimer;
          
  final TextEditingController _dmInputController = TextEditingController();

  static const Map<String, String> _mediaHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  bool get _isWideScreen => MediaQuery.of(context).size.width >= 768;

                                               
  bool get _usesZoomHero =>
      widget.heroTag != null && SettingsService.heroTransitionBlurEnabled;

                         
  bool get _isPlayerPlaying =>
      _started && (_playerKey.currentState?.player.state.playing ?? false);

                                      
  bool _wasPlayingBeforeDrag = false;

                                       
                                                                    
  late final ZoomHeroBackDrag _backDrag = ZoomHeroBackDrag(
                                                            
                                            
                                     
    canDrag: () =>
        !_fullscreen && !(_commentsNavKey.currentState?.canPop() ?? false),
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

  BiliBangumiEpisode? get _currentEp {
    final detail = _detail;
    if (detail == null || detail.episodes.isEmpty) return null;
    final idx = _epIndex.clamp(0, detail.episodes.length - 1);
    return detail.episodes[idx];
  }

  @override
  void initState() {
    super.initState();
    _videoTitle = widget.initialTitle ?? '';
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
    _onlineTimer?.cancel();
    _playingSub?.cancel();
    _tripleTimer?.cancel();
    _tripleController.dispose();
    _expandController.dispose();
    _dmInputController.dispose();
    _danmaku.dispose();
    _collapseNotifier.dispose();
    super.dispose();
  }

                                      
              
  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final detail = await BilibiliBangumiService.fetchSeason(widget.seasonId);
    if (!mounted) return;
    if (detail == null || detail.episodes.isEmpty) {
      setState(() {
        _loading = false;
        _error = BilibiliBangumiService.lastErrorDetail ?? '加载失败';
      });
      return;
    }
                                           
                                     
    var targetIdx = -1;
    if (widget.initialPosition != null) {
      _position = widget.initialPosition!;
    } else {
      final restored = _restoreProgressFromHistory(detail);
      if (restored != null) {
        targetIdx = restored.$1;
        _position = restored.$2;
      }
    }
    if (targetIdx < 0 && detail.lastEpId > 0) {
      targetIdx = detail.episodes.indexWhere((e) => e.epId == detail.lastEpId);
    }
    if (targetIdx < 0) {
                    
      targetIdx = detail.episodes.indexWhere((e) => !e.badge.contains('预告'));
      if (targetIdx < 0) targetIdx = 0;
    }

    setState(() {
      _detail = detail;
      _epIndex = targetIdx;
      _videoTitle = detail.title;
      _loading = false;
      _likeCount = detail.stat.likes;
      _coinCount = detail.stat.coins;
      _favCount = detail.stat.favorite;
      _followCount = detail.stat.follow;
      _hasFollowed = detail.followed;
      _followStatus = detail.followStatus;
    });
    _loadEpisodeRelation();
    _loadOnlineCount();
  }

                                             
  (int, Duration)? _restoreProgressFromHistory(BiliBangumiDetail detail) {
    try {
      final history = context.read<PlayHistoryService>();
      final records = history.findByIdPrefix('bili_ep_');
      if (records.isEmpty) return null;
      records.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      final best = records.first;
      final epIdStr = best.id.substring('bili_ep_'.length);
      final epId = int.tryParse(epIdStr);
      if (epId == null) return null;
      final idx = detail.episodes.indexWhere((e) => e.epId == epId);
      if (idx < 0) return null;
      final pos = best.positionMs > 3000
          ? Duration(milliseconds: best.positionMs)
          : Duration.zero;
      return (idx, pos);
    } catch (e) {
      debugPrint('⚠️ 恢复番剧播放进度失败: $e');
      return null;
    }
  }

                                   
  Future<void> _loadEpisodeRelation() async {
    final ep = _currentEp;
    if (ep == null) return;
    if (BilibiliAccountService.instance.cookieHeaderFor(
          BiliCookieScope.interactions,
        ) ==
        null) {
      return;
    }
    final relation = await BilibiliBangumiService.fetchEpisodeRelation(ep.epId);
    if (!mounted || relation == null) return;
    setState(() {
      _hasLiked = relation.liked;
      _hasFaved = relation.favored;
      _coinGiven = relation.coinNumber;
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
          title: const Text('需要登录'),
          content: const Text('追番 / 点赞 / 投币 / 三连等互动需要登录 B 站账号'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('去登录'),
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
        await _loadEpisodeRelation();
      }
      return BilibiliAccountService.instance.cookieHeaderFor(
            BiliCookieScope.interactions,
          ) !=
          null;
    }
    _toast('请在账号设置中开启「携带 Cookie 请求」与「互动操作」范围', error: true);
    return false;
  }

                
  Future<void> _toggleFollow() async {
    if (_hasFollowed) {
                                                   
      await _showFollowStatusSheet();
      return;
    }
    await _setFollow(true);
  }

                           
  Future<void> _setFollow(
    bool target, {
    int? status,
    String? successToast,
  }) async {
    if (_interacting) return;
    final detail = _detail;
    if (detail == null) return;
    if (!await _ensureCanInteract()) return;
    setState(() => _interacting = true);
    final result = await BilibiliBangumiService.setFollow(
      seasonId: detail.seasonId,
      follow: target,
      status: status,
    );
    if (!mounted) return;
    setState(() => _interacting = false);
    if (result.ok) {
      setState(() {
        _hasFollowed = target;
        if (target) {
          _followStatus = status ?? (_followStatus == 0 ? 2 : _followStatus);
        } else {
          _followStatus = 0;
        }
        _followCount = (_followCount + (target ? 1 : -1)).clamp(0, 0x7fffffff);
      });
      _toast(successToast ?? (target ? '追番成功' : '已取消追番'));
    } else {
      _toast('操作失败：${result.message}', error: true);
    }
  }

                                         
  Future<void> _showFollowStatusSheet() async {
    final detail = _detail;
    if (detail == null) return;
    const names = {1: '想看', 2: '在看', 3: '看过'};
    final picked = await showAppBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in names.entries)
              ListTile(
                leading: Icon(
                  _followStatus == entry.key
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(entry.value),
                onTap: () => Navigator.of(sheetContext).pop(entry.key),
              ),
            if (_hasFollowed)
              ListTile(
                leading: const Icon(Icons.person_remove_outlined),
                title: const Text('取消追番'),
                onTap: () => Navigator.of(sheetContext).pop(0),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    if (picked == 0) {
      await _setFollow(false);
    } else {
      await _setFollow(
        true,
        status: picked,
        successToast: '已标记为「${names[picked]}」',
      );
    }
  }

                                            
  Future<void> _toggleLike() async {
    if (_interacting) return;
    final ep = _currentEp;
    if (ep == null) return;
    if (!await _ensureCanInteract()) return;
    final target = !_hasLiked;
    setState(() => _interacting = true);
    final result = await BilibiliInteractionService.likeVideo(
      aid: ep.aid,
      like: target,
    );
    if (!mounted) return;
    setState(() => _interacting = false);
    if (result.ok) {
      setState(() {
        _hasLiked = target;
        _likeCount = (_likeCount + (target ? 1 : -1)).clamp(0, 0x7fffffff);
      });
      _toast(target ? '已点赞' : '已取消点赞');
    } else {
      _toast('点赞失败：${result.message}', error: true);
    }
  }

                                    
  Future<void> _doTriple() async {
    if (_interacting) return;
    final ep = _currentEp;
    if (ep == null) return;
    if (_hasLiked && _coinGiven > 0 && _hasFaved) {
      _toast('已完成三连');
      return;
    }
    if (!await _ensureCanInteract()) return;
    setState(() => _interacting = true);
    final result = await BilibiliBangumiService.triple(ep.epId);
    if (!mounted) return;
    setState(() => _interacting = false);
    if (result.ok) {
      setState(() {
        if (!_hasLiked) _likeCount++;
        _hasLiked = true;
        if (_coinGiven < 2) {
          _coinGiven += 1;
          _coinCount += 1;
        }
        if (!_hasFaved) _favCount++;
        _hasFaved = true;
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
    final ep = _currentEp;
    if (ep == null) return;
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
    final ep = _currentEp;
    if (ep == null || _interacting) return;
    if (!await _ensureCanInteract()) return;
    if (coins != null && coins < multiply) {
      _toast('硬币不足', error: true);
      return;
    }
    _coinWithLike = withLike;
    setState(() => _interacting = true);
    final result = await BilibiliInteractionService.coinVideo(
      aid: ep.aid,
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
    final ep = _currentEp;
    if (ep == null) return;
    if (!await _ensureCanInteract()) return;
    setState(() => _interacting = true);
    if (_hasFaved) {
      final result = await BilibiliInteractionService.unfavoriteAll(
        aid: ep.aid,
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
      rid: ep.aid,
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
      aid: ep.aid,
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

               

  String get _shareUrl {
    final detail = _detail;
    final ep = _currentEp;
    if (detail == null) return '';
    if (ep != null && ep.epId > 0) {
      return 'https://www.bilibili.com/bangumi/play/ep${ep.epId}';
    }
    return 'https://www.bilibili.com/bangumi/play/ss${detail.seasonId}';
  }

  void _openShareMenu() {
    showFrostedActionSheet(
      context,
      cover: _detail?.cover,
      title: _videoTitle,
      subtitle: _currentEp?.displayTitle,
      actions: [
        GlassMenuAction(
          icon: Icons.copy_rounded,
          text: L10n.current.playerCopyLink,
          onTap: () async {
            try {
              await Clipboard.setData(ClipboardData(text: _shareUrl));
              if (mounted) _toast(L10n.current.playerCopyLinkDone(_shareUrl));
            } catch (e) {
              debugPrint('❌ 复制链接失败: $e');
            }
          },
        ),
        GlassMenuAction(
          icon: Icons.public,
          text: L10n.current.articleOpenBrowser,
          onTap: () {
            final url = _shareUrl;
            if (url.isEmpty) return;
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
          },
        ),
        GlassMenuAction(
          icon: Icons.share_outlined,
          text: L10n.current.articleShare,
          onTap: () {
            final url = _shareUrl;
            if (url.isEmpty) return;
            SharePlus.instance.share(
              ShareParams(
                text: url,
                subject: _videoTitle.isEmpty ? null : _videoTitle,
              ),
            );
          },
        ),
      ],
    );
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
    if (_loadingPlayUrl) return;
    final detail = _detail;
    final ep = _currentEp;
    if (detail == null || ep == null || ep.cid <= 0) return;
    setState(() {
      _loadingPlayUrl = true;
      _error = null;
    });
    final play = await BilibiliBangumiService.fetchPlayUrl(
      seasonId: detail.seasonId,
      bvid: ep.bvid,
      cid: ep.cid,
      epId: ep.epId,
      qn: _currentQn,
    );
    if (!mounted) return;
    setState(() => _loadingPlayUrl = false);
    if (play == null) {
      setState(
        () => _error = BilibiliBangumiService.lastErrorDetail ?? '解析播放地址失败',
      );
      return;
    }
    _playUrl = play;
    if (_currentQn == 0 && play.quality > 0) {
      _currentQn = play.quality;
    }
    final url = BilibiliVideoService.buildPlayableUrl(play);
    if (url == null) {
      setState(() => _error = '无可用播放地址');
      return;
    }
                                
    final items = <PlaylistItem>[];
    for (var i = 0; i < detail.episodes.length; i++) {
      final e = detail.episodes[i];
      if (e.cid <= 0) continue;
      String? u;
      if (i == _epIndex) {
        u = url;
      } else {
        final pu = await BilibiliBangumiService.fetchPlayUrl(
          seasonId: detail.seasonId,
          bvid: e.bvid,
          cid: e.cid,
          epId: e.epId,
          qn: _currentQn,
        );
        u = pu == null ? null : BilibiliVideoService.buildPlayableUrl(pu);
      }
      if (u == null) continue;
      items.add(
        PlaylistItem(
          id: 'bili_ep_${e.epId}',
          url: u,
          title: e.displayTitle,
          index: i,
          danmakuSource: e.cid.toString(),
          danmakuType: 'cid',
          commentSource: e.aid.toString(),
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _currentUrl = url;
      _fullPlaylist = items.isEmpty
          ? null
          : Playlist(
              id: 'bili_ss_${detail.seasonId}',
              name: detail.title,
              items: items,
            );
      _error = null;
      _started = true;
    });
    _loadViewPoints(ep.aid, ep.cid);
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

                                 
  void _switchEpisode(int index) {
    final detail = _detail;
    if (detail == null || index < 0 || index >= detail.episodes.length) return;
    if (index == _epIndex) return;
    setState(() {
      _epIndex = index;
      _position = Duration.zero;
      _viewPoints = [];
    });
    if (_started) {
      _playerKey.currentState?.switchEpisode(index);
    }
                        
    _loadEpisodeRelation();
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
    final ep = _currentEp;
    if (ep == null) return;
    final total = await BilibiliVideoService.fetchOnlineTotal(
      aid: ep.aid,
      bvid: ep.bvid,
      cid: ep.cid,
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
      artist: _detail?.title,
      httpHeaders: _mediaHeaders,
      danmakuSource: (_currentEp?.cid ?? 0).toString(),
      danmakuType: 'cid',
      playlist: _fullPlaylist,
      initialEpisodeIndex: _epIndex,
      initialPosition: _position,
      danmakuController: _danmaku,
      playUrlInfo: _playUrl,
      initialQualityQn: _currentQn > 0 ? _currentQn : null,
      viewPoints: _viewPoints,
      artUri: _detail?.cover,
      bilibiliBvid: _currentEp?.bvid,
      historyId: _currentHistoryId,
      onPositionChanged: (p) => _position = p,
      onQualityChanged: (qn) => _currentQn = qn,
      onEpisodeChanged: (i) => setState(() => _epIndex = i),
      onDanmakuCountChanged: (_) => setState(() {}),
      onFullscreenRequested: () => _setFullscreen(true),
      onExitFullscreenRequested: () => _setFullscreen(false),
      onControlsVisibilityChanged: (v) {
        if (mounted && _controlsVisible != v) {
          setState(() => _controlsVisible = v);
        }
      },
    );

    Widget page = Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: Stack(
        fit: StackFit.expand,
        children: [
                             
          Offstage(
            offstage: _fullscreen,
            child: SafeArea(
              bottom: false,
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
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _resumeFromPause,
                        splashColor: cs.primary.withValues(alpha: 0.10),
                        highlightColor: cs.primary.withValues(alpha: 0.06),
                        child: const SizedBox.expand(),
                      ),
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
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _resumeFromPause,
                        splashColor: cs.primary.withValues(alpha: 0.10),
                        highlightColor: cs.primary.withValues(alpha: 0.06),
                        child: const SizedBox.expand(),
                      ),
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
                    child: _buildBackButton(),
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
                  return Positioned(
                    left: w - btnSize - 16,
                    top: h - btnSize - 90,
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
        ],
      ),
    );

                                              
    if (_usesZoomHero && _zoomHeroActive) {
                                                
      final Curve? gestureCurve = HeroGestureCurve.curveOrNull(context);
      page = Hero(
        transitionOnUserGestures: true,
        tag: widget.heroTag!,
        curve: gestureCurve ?? Curves.easeOutCubic,
        reverseCurve: gestureCurve ?? Curves.easeInCubic,
                                          
                                       
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
                                             
                                         
          active: _usesZoomHero && _zoomHeroActive,
          child: HeroMode(enabled: false, child: page),
        ),
      );
    }

    return PopScope(
      canPop: !_fullscreen && (!_usesZoomHero || _zoomHeroActive),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_fullscreen && mounted) {
          _setFullscreen(false);
          return;
        }
                                              
                                                          
        final plan = planZoomHeroExit(
          playerMounted: _started,
          usesZoomHero: _usesZoomHero,
          zoomHeroActive: _zoomHeroActive,
        );
        popRouteAfterRebuild(
          context: context,
          rebuild: plan.isEmpty
              ? null
              : () {
                  setState(() {
                                                    
                                                                 
                                           
                    if (plan.unmountPlayer) _started = false;
                    if (plan.rewrapHero) _zoomHeroActive = true;
                  });
                },
        );
      },
      child: IosBackdropScale(child: page),
    );
  }

                          
  Widget _buildDanmakuBar(ColorScheme cs) {
    final info = [
      if (_onlineCount > 0) '$_onlineCount人正在看',
      if (_danmaku.itemCount > 0) '已装填${_danmaku.itemCount}条弹幕',
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
          AppTooltip(
            message: _danmaku.enabled ? '关闭弹幕' : '开启弹幕',
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
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        _danmaku.enabled ? cs.onSurfaceVariant : cs.outline,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (info.isNotEmpty) const SizedBox(width: 10),
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
                hintText: '发个友善的弹幕见证当下',
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
              '发送',
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

  Future<void> _sendDanmakuFromInput() async {
    final msg = _dmInputController.text.trim();
    _dmInputController.clear();
    await _sendDanmaku(msg);
  }

                                          
  Future<void> _sendDanmaku(String msg) async {
    final ep = _currentEp;
    if (ep == null) return;
    if (msg.isEmpty) {
      _toast('弹幕内容不能为空', error: true);
      return;
    }
    if (!await _ensureCanInteract()) return;
    final result = await DanmakuSegFetcher.sendDanmaku(
      oid: ep.aid.toString(),
      cid: ep.cid.toString(),
      msg: msg,
      progress: _position.inMilliseconds,
    );
    if (!mounted) return;
    if (!result.ok) {
      _toast('发送失败：${result.message}', error: true);
      return;
    }
    _danmaku.addItem(
      DanmakuItem(
        time: _position.inMilliseconds / 1000.0,
        mode: DanmakuMode.scrollRightToLeft,
        fontSize: 25,
        color: const Color(0xFFFFFFFF),
        content: msg,
      ),
    );
    if (mounted) setState(() {});
    _toast('弹幕已发送');
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
                : DefaultTabController(
                    length: 2,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: naviTabBarView(
                            children: [
                                                 
                                                      
                                                                  
                                        
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: _tabBarHeight,
                                ),
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    24,
                                  ),
                                  itemCount: _detail!.episodes.length,
                                  itemBuilder: (_, i) =>
                                      _episodeListTile(cs, i),
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
                                    onGenerateRoute: (settings) =>
                                        MaterialPageRoute<void>(
                                          settings: settings,
                                          builder: (_) => _buildCommentsPage(),
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
                            '选集 ${_detail!.episodes.length}',
                            '评论',
                          ]),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsPage() {
    final ep = _currentEp;
    final detail = _detail;
    return BilibiliCommentsPage(
      oid: ep?.aid ?? 0,
      upMid: null,
      episodeTitle: detail?.title,
    );
  }

                         
  Widget _episodeListTile(ColorScheme cs, int index) {
    final detail = _detail!;
    final ep = detail.episodes[index];
    final selected = index == _epIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? cs.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _switchEpisode(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ep.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? cs.primary : cs.onSurface,
                    ),
                  ),
                ),
                if (ep.badge.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: ep.badgeType == 2
                          ? cs.primary.withValues(alpha: 0.15)
                          : const Color(0xFFFB7299).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ep.badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: ep.badgeType == 2
                            ? cs.primary
                            : const Color(0xFFFB7299),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
                  : DefaultTabController(
                      length: 2,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: naviTabBarView(
                              children: [
                                                    
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: _tabBarHeight,
                                  ),
                                  child: ListView(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      12,
                                      16,
                                      24,
                                    ),
                                    children: _buildInfoContent(),
                                  ),
                                ),
                                           
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: _tabBarHeight,
                                  ),
                                  child: _buildCommentsPage(),
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
                              '简介',
                              '评论 ${_fmtCount(_detail!.stat.danmakus)}',
                            ]),
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
                                                  
          if (onTap != null) {
            onTap();
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
          ],
        ),
      ),
    );
  }

                                              
                               
                                              
  List<Widget> _buildInfoContent() {
    final detail = _detail!;
    final cs = Theme.of(context).colorScheme;
    return [
                        
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              detail.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildFollowButton(cs),
        ],
      ),
      const SizedBox(height: 8),
                             
      _buildRatingRow(cs, detail),
      const SizedBox(height: 10),
                 
      _buildStats(cs),
                 
      SizedBox(height: detail.evaluate.isNotEmpty ? 14 : 2),
      if (detail.evaluate.isNotEmpty)
        SelectableText.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: cs.onSurfaceVariant,
            ),
            children: buildUgcSpans(
              text: detail.evaluate,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: cs.onSurfaceVariant,
              ),
              context: context,
              onSeek: _seekFromUgc,
            ),
          ),
        ),
                        
      if (detail.staff.isNotEmpty || detail.actors.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(
          [
            if (detail.staff.isNotEmpty) detail.staff,
            if (detail.actors.isNotEmpty) detail.actors,
          ].join('\n'),
          style: TextStyle(
            fontSize: 12.5,
            height: 1.5,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
      const SizedBox(height: 12),
                                     
      _buildActions(cs),
      const Divider(height: 24),
                 
      if (detail.episodes.length > 1) ...[
        Row(
          children: [
            Text(
              L10n.current.playerEpisodeSelect,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            if (detail.newEpDesc.isNotEmpty)
              Text(
                detail.newEpDesc,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < detail.episodes.length; i++)
              _episodeChip(cs, i),
          ],
        ),
        const SizedBox(height: 16),
      ],
    ];
  }

                                
  String get _followStatusLabel => switch (_followStatus) {
    1 => '想看',
    2 => '在看',
    3 => '看过',
    _ => '已追番',
  };

                                         
                                 
  Widget _buildFollowButton(ColorScheme cs) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: _hasFollowed
              ? cs.surfaceContainerHighest
              : const Color(0xFFFB7299),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _interacting ? null : _toggleFollow,
          onLongPress: _interacting ? null : _showFollowStatusSheet,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _hasFollowed ? Icons.check : Icons.add,
                  size: 14,
                  color: _hasFollowed ? cs.onSurfaceVariant : Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _hasFollowed ? _followStatusLabel : '追番',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _hasFollowed ? cs.onSurfaceVariant : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

                           
  Widget _buildRatingRow(ColorScheme cs, BiliBangumiDetail detail) {
    final parts = <String>[
      if (detail.typeName.isNotEmpty) detail.typeName,
      if (detail.badge.isNotEmpty) detail.badge,
    ];
    return Row(
      children: [
        if (detail.ratingScore > 0) ...[
          Text(
            detail.ratingScore.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFB7299),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            detail.ratingCount > 0 ? '${_fmtCount(detail.ratingCount)}人评分' : '',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
        ],
        if (parts.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              parts.join(' · '),
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ),
        if (detail.styles.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detail.styles.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStats(ColorScheme cs) {
    final detail = _detail!;
    return Row(
      children: [
        _stat(cs, Icons.play_arrow_rounded, _fmtCount(detail.stat.views)),
        _stat(cs, Icons.subtitles_outlined, _fmtCount(detail.stat.danmakus)),
        _stat(cs, Icons.star_outline_rounded, '${_fmtCount(_followCount)}追番'),
        if (detail.pubTime > 0)
          _stat(cs, Icons.schedule, _fmtDate(detail.pubTime)),
        const Spacer(),
        if (_onlineCount > 0)
          _stat(cs, Icons.visibility_outlined, '${_fmtCount(_onlineCount)}人在看'),
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

  Widget _buildActions(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _interactBtn(
          cs,
          icon: _biliIcon(
            'like.svg',
            size: 20,
            color: _hasLiked ? cs.primary : cs.onSurfaceVariant,
          ),
          iconColor: _hasLiked ? cs.primary : cs.onSurfaceVariant,
          label: _fmtCount(_likeCount),
          tooltip: _hasLiked ? '取消点赞' : '点赞（长按一键三连）',
          active: _hasLiked,
          showTooltip: false,
          shakeAnimation: _tripleController,
          onTapDown: _onLikeTapDown,
          onTapUp: _onLikeTapUp,
          onTapCancel: _onLikeTapCancel,
        ),
        _interactBtn(
          cs,
          icon: _biliIcon(
            'coin.svg',
            size: 20,
            color: _coinGiven > 0 ? cs.primary : cs.onSurfaceVariant,
          ),
          iconColor: _coinGiven > 0 ? cs.primary : cs.onSurfaceVariant,
          label: _fmtCount(_coinCount),
          tooltip: '投币',
          active: _coinGiven > 0,
          arcProgress: _tripleController,
          onTap: _openCoinDialog,
        ),
        _interactBtn(
          cs,
          icon: _biliIcon(
            'fav.svg',
            size: 20,
            color: _hasFaved ? cs.primary : cs.onSurfaceVariant,
          ),
          iconColor: _hasFaved ? cs.primary : cs.onSurfaceVariant,
          label: _fmtCount(_favCount),
          tooltip: _hasFaved ? '取消收藏' : '收藏',
          active: _hasFaved,
          arcProgress: _tripleController,
          onTap: _toggleFav,
        ),
        _interactBtn(
          cs,
          icon: _biliIcon('share.svg', size: 20, color: cs.onSurfaceVariant),
          iconColor: cs.onSurfaceVariant,
          label: '分享',
          tooltip: '分享',
          onTap: _openShareMenu,
        ),
        _interactBtn(
          cs,
          icon: Icon(
            Icons.rate_review_outlined,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
          iconColor: cs.onSurfaceVariant,
          label: '点评',
          tooltip: '番剧点评',
          onTap: _openPgcReviews,
        ),
      ],
    );
  }

                      
  void _openPgcReviews() {
    final detail = _detail;
    if (detail == null || detail.mediaId <= 0) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            BilibiliPgcReviewPage(mediaId: detail.mediaId, title: detail.title),
      ),
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

                                  
  Widget _episodeChip(ColorScheme cs, int index) {
    final detail = _detail!;
    final ep = detail.episodes[index];
    final selected = index == _epIndex;
    return Material(
      color: selected ? cs.primary : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _switchEpisode(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ep.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
              if (ep.badge.isNotEmpty) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: ep.badgeType == 2
                        ? cs.primary.withValues(alpha: 0.15)
                        : const Color(0xFFFB7299).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    ep.badge,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: ep.badgeType == 2
                          ? cs.primary
                          : const Color(0xFFFB7299),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
    final ep = _currentEp;
    if (detail == null) return _videoTitle;
    if (detail.episodes.length > 1 && ep != null) {
      return ep.displayTitle;
    }
    return detail.title;
  }

                                              
  String? get _currentHistoryId {
    final ep = _currentEp;
    if (ep == null || ep.epId <= 0) return null;
    return 'bili_ep_${ep.epId}';
  }

  Widget _buildBackButton() {
    final l10n = AppLocalizations.of(context);
    return MorphIconButton(
      icon: Icons.arrow_back,
      tooltip: l10n.commonBackTooltip,
      onTap: () => Navigator.of(context).maybePop(),
      frosted: true,
    );
  }

  Widget _buildCollapsedBarContent() {
    final cs = Theme.of(context).colorScheme;
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
              Icon(
                Icons.keyboard_arrow_up,
                color: cs.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
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
    final cover = detail?.cover ?? widget.initialCover ?? '';
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
                                             
                        
    if (heroTag != null && !SettingsService.heroTransitionBlurEnabled) {
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
              child: _buildBackButton(),
            ),
          ),
        ],
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
