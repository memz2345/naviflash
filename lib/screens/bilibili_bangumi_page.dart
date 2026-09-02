// lib/screens/bilibili_bangumi_page.dart
//
// B 站番剧播放页（应用内，参考 PiliPlus lib/pages/video 的 PGC 详情实现）：
//   - 详情：pgc/view/web/season（标题/评分/简介/统计/剧集/追番状态）
//   - 播放：pgc/player/web/v2/playurl（DASH/durl，复用 BiliPlayUrl 解析）
//   - 剧集切换 + 弹幕（cid）+ 评论（oid = 分集 aid）+ 追番/点赞/投币/收藏/三连
//   - 本质是播放器页的变种：布局/折叠/全屏/弹幕栏与 bilibili_video_page 一致，
//     「相关视频」位置换成「选集」，「UP 主」位置换成「追番」。
//   - 转场：与视频页一致的 iOS 开 App 整页放大（开启「使用新版动画」时）；
//     关闭时回落到经典封面 Hero 飞行。
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

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
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// 打开 B 站番剧播放页（SS 号直达，搜索页/空间页等入口共用）。
/// 转场与视频页一致：开启「使用新版动画」→ iOS 开 App 整页放大（毛玻璃模糊）；
/// 关闭 → 经典 MaterialPageRoute + 封面 Hero 飞行。
void openBilibiliBangumi(
  BuildContext context, {
  required int seasonId,
  String? initialTitle,
  String? initialCover,
  String? heroTag,
  Duration? initialPosition,
}) {
  // 推入番剧页前收起虚拟键盘并清除焦点（与视频页一致，避免返回时键盘弹出）
  FocusManager.instance.primaryFocus?.unfocus();
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

/// 从 B 站番剧链接解析 SS 号（/bangumi/play/ss12345）；非番剧链接返回 null。
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

/// 毛玻璃 tab 栏高度。
const double _tabBarHeight = 56.0;

/// 窄屏下播放器折叠后的标题栏高度（与 tab 栏同高，参考 PiliPlus kToolbarHeight）。
const double _kPlayerCollapsedHeight = 56.0;

class BilibiliBangumiPage extends StatefulWidget {
  /// 番剧 SS 号（season_id）。
  final int seasonId;
  final String? initialTitle;
  final String? initialCover;

  /// 封面 Hero 动画 tag（从搜索卡片进入时传，与卡片封面 Hero 匹配）。
  final String? heroTag;

  /// 空降时间点（?t= 解析）：打开后直接跳到该进度，忽略本地播放历史。
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
  // 内嵌播放器句柄：剧集切换 / 全屏时控制
  final GlobalKey<MpvPlayerPageState> _playerKey =
      GlobalKey<MpvPlayerPageState>();
  // 宽屏右侧评论区面板的嵌套导航：回复页作为独立 push 仅在面板内展示
  final GlobalKey<NavigatorState> _commentsNavKey = GlobalKey<NavigatorState>();
  final DanmakuController _danmaku = DanmakuController();
  // 长按赞一键三连动画（与视频页一致的 1200ms 前进 / 400ms 回退）
  late final AnimationController _tripleController;
  Timer? _tripleTimer;
  // 点击折叠标题栏续播时：从当前折叠值平滑展开回完整 16:9 播放器的动画
  late final AnimationController _expandController;
  double _expandStartCollapse = 0;

  BiliBangumiDetail? _detail;
  BiliPlayUrl? _playUrl;
  String? _error;
  bool _loading = true;
  bool _loadingPlayUrl = false;
  bool _started = false;
  bool _fullscreen = false;
  // 整页 Hero（iOS 开 App 放大）是否包裹页面（与视频页同款逻辑）
  bool _zoomHeroActive = true;
  bool _isPlaying = false;
  bool _seenPlaying = false;
  StreamSubscription<bool>? _playingSub;
  bool _controlsVisible = false;
  bool _showPlayButton = false;
  Animation<double>? _routeAnimation;
  AnimationStatusListener? _routeAnimListener;
  // 窄屏滚动折叠
  final ValueNotifier<double> _collapseNotifier = ValueNotifier(0);
  double _playerHeight = 0;
  // 当前剧集 / 画质
  int _epIndex = 0;
  int _currentQn = 0;
  Duration _position = Duration.zero;
  String _currentUrl = '';
  Playlist? _fullPlaylist;
  String _videoTitle = '';
  // 互动状态
  late int _likeCount;
  late int _coinCount;
  late int _favCount;
  late int _followCount;
  bool _hasLiked = false;
  bool _hasFaved = false;
  int _coinGiven = 0;
  bool _hasFollowed = false;
  bool _interacting = false;
  bool _coinWithLike = true;
  // 高能进度条 / 正在看人数
  List<BiliViewPoint> _viewPoints = [];
  int _onlineCount = 0;
  Timer? _onlineTimer;
  // 弹幕输入框
  final TextEditingController _dmInputController = TextEditingController();

  static const Map<String, String> _mediaHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  bool get _isWideScreen => MediaQuery.of(context).size.width >= 768;

  /// 是否使用整页 Hero（iOS 开 App 放大）：开启模糊 + 有封面 tag。
  bool get _usesZoomHero =>
      widget.heroTag != null && SettingsService.heroTransitionBlurEnabled;

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
    // 封面小电视按钮：Hero 飞入动画结束后再显示（与视频页一致）
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

  /// 拉取番剧详情，并定位初始剧集（本地播放历史 > 站内追番进度 >
  /// 第一集非预告）。
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
    // 恢复播放进度：本地历史优先（稳定 ID bili_ep_{epId}），
    // 其次站内追番进度（user_status.progress）
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
      // 默认第一集（跳过预告）
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
    });
    _loadEpisodeRelation();
    _loadOnlineCount();
  }

  /// 从本地播放历史恢复剧集与进度（稳定 ID `bili_ep_{epId}`）。
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

  /// 拉取当前账号对单集的点赞/投币/收藏状态（未登录则跳过）。
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

  // ─── 互动操作 ───

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    showAppToast(context, msg, error: error);
  }

  /// 确保可互动（登录 + 开启「携带 Cookie 请求」+「互动操作」范围）。
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

  /// 追番 / 取消追番。
  Future<void> _toggleFollow() async {
    if (_interacting) return;
    final detail = _detail;
    if (detail == null) return;
    if (!await _ensureCanInteract()) return;
    final target = !_hasFollowed;
    setState(() => _interacting = true);
    final result = await BilibiliBangumiService.setFollow(
      seasonId: detail.seasonId,
      follow: target,
    );
    if (!mounted) return;
    setState(() => _interacting = false);
    if (result.ok) {
      setState(() {
        _hasFollowed = target;
        _followCount = (_followCount + (target ? 1 : -1)).clamp(0, 0x7fffffff);
      });
      _toast(target ? '追番成功' : '已取消追番');
    } else {
      _toast('操作失败：${result.message}', error: true);
    }
  }

  /// 点赞 / 取消点赞（番剧分集本身是普通稿件，走 archive/like）。
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

  /// 番剧一键三连（点赞 + 投币 + 收藏，pgc 专用接口）。
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

  // ─── 长按赞三连手势（与视频页一致） ───

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

  /// 打开投币页（2233 动画，与视频页共用）。
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

  /// 投币回调：先校验登录，再执行投币 API 并更新计数。
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

  /// 收藏 / 取消收藏（快速收藏到默认/第一个收藏夹，与视频页一致）。
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

  // ─── 分享 ───

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

  // ─── 播放 ───

  /// 点击封面后开始播放：解析当前分集的播放地址并渲染内嵌播放器。
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
    // 生成全屏播放列表：所有分集（懒解析失败的分集跳过）
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
    // 订阅播放器播放状态（与视频页一致）
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

  /// 暂停时点击右下角「小电视」恢复播放。
  void _resumeFromPause() {
    _playerKey.currentState?.player.play();
  }

  /// 暂停态「小电视」播放按钮（与视频页同款）。
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

  /// 弹幕开关（与视频页一致）。
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

  /// 切换剧集：更新索引、进度归零、内嵌播放器切换到对应集。
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
    // 单集互动状态按分集区分：切换后刷新
    _loadEpisodeRelation();
  }

  // ─── 窄屏播放器折叠到标题栏（与视频页一致） ───

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

  // ─── 全屏：位置/尺寸变化，复用同一个 MpvPlayerPage 实例 ───
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

  /// 拉取「正在看」人数（每 30s 自动刷新）。
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

  // ═════════════════════════════════════════
  //  构建：响应式布局
  // ═════════════════════════════════════════
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
          // 页面内容（全屏时离屏但保留状态）
          Offstage(
            offstage: _fullscreen,
            child: SafeArea(
              bottom: false,
              child: isWide ? _buildWideLayout(cs) : _buildCompactLayout(cs),
            ),
          ),
          // 共享播放器：宽屏 / 全屏保持原始 16:9 尺寸；窄屏滚动折叠时
          // 视频向上收缩（顶部保留、底部裁掉），收缩到标题栏高度。
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
          // 折叠时标题栏随折叠进度渐显（与视频页一致）
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
          // 暂停时整块区域可点击继续播放（与视频页一致）
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
          // 暂停态顶部返回按钮（与视频页一致）
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
          // 暂停时右下角「小电视」播放按钮（与视频页一致）
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

    // 整页 Hero：iOS 开 App 式放大到全屏（搜索卡片 → 番剧播放页）。
    if (_usesZoomHero && _zoomHeroActive) {
      page = Hero(
        tag: widget.heroTag!,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
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
                  // push 中途被 pop 时 Hero 会复用原 shuttle，direction
                  // 仍是 push；按真实状态识别反向飞行，保持画面连续。
                  final returning =
                      isPop || animation.status == AnimationStatus.reverse;
                  final screen = MediaQuery.sizeOf(context);
                  final Widget flying;
                  if (isPop) {
                    flying = (toContext.widget as Hero).child;
                  } else {
                    // 进入：按卡片比例裁剪整页内容，而不是压缩整页。
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
                    // 返回时保持卡片不透明，避免飞行结束前淡到 0.35
                    // 后与真实卡片切换产生闪烁。
                    opacity: returning ? 1.0 : 0.35 + 0.65 * fadeIn.value,
                    child: flying,
                  );
                },
              );
            },
        child: HeroMode(enabled: false, child: page),
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
        if (mounted && _usesZoomHero && !_zoomHeroActive) {
          setState(() {
            _zoomHeroActive = true;
            // ✅ 播放中返回：先卸载内嵌播放器、封面接管画面
            //    （与视频页一致：Hero 飞行时 from-hero 的 child 会被
            //    placeholder 顶替，正在渲染的 mpv 纹理中途销毁会打断
            //    转场动画；提前干净卸载保证缩回动画正常）。
            if (_started) _started = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
        }
      },
      child: IosBackdropScale(child: page),
    );
  }

  // ─── 弹幕输入栏（与视频页同款） ───
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
          Tooltip(
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

  /// 发送一条弹幕（登录校验 → /x/v2/dm/post → 立即上屏）。
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

  // ═══════════ 宽屏（横屏）：左 播放器+信息 | 右 选集/评论 ═══════════
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
                          child: TabBarView(
                            children: [
                              // 选集：宽屏右侧独立面板滚动查看
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
                                  children: [
                                    for (
                                      var i = 0;
                                      i < _detail!.episodes.length;
                                      i++
                                    )
                                      _episodeListTile(cs, i),
                                  ],
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

  /// 宽屏右侧选集列表项（标题 + 角标）。
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

  // ═══════════ 紧凑（竖屏）：上 播放器，下 tab ═══════════
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
                            child: TabBarView(
                              children: [
                                // 左 tab：信息 + 选集一起滚动
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
                                // 右 tab：评论
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

  /// 详情加载占位：加载中转圈；失败时显示错误（右下角 Extended FAB 重新加载）。
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
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 加载失败重试：右下角 Extended FAB（重新加载）
          PositionedRetryFab(
            onRetry: _loadDetail,
            bottomOffset: MediaQuery.paddingOf(context).bottom + 16,
          ),
        ],
      );
    }
    return const Center(child: LoadingIndicatorM3E());
  }

  Widget _buildTabRow(List<String> tabs) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FrostedPanel(
      opacity: 0.9,
      color: (isDark ? cs.surfaceContainerHigh : cs.surfaceContainer)
          .withValues(alpha: 0.82),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _tabBarHeight - 1,
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                    labelColor: cs.primary,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorColor: cs.primary,
                    indicatorWeight: 3,
                    tabs: tabs
                        .map((t) => Tab(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                child: Text(t),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════
  //  信息区内容（横屏左栏 / 竖屏简介 tab 共用）
  // ═════════════════════════════════════════
  List<Widget> _buildInfoContent() {
    final detail = _detail!;
    final cs = Theme.of(context).colorScheme;
    return [
      // ── 标题 + 追番按钮 ──
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
      // ── 评分 / 类型 / 更新状态 ──
      _buildRatingRow(cs, detail),
      const SizedBox(height: 10),
      // ── 统计 ──
      _buildStats(cs),
      // ── 简介 ──
      SizedBox(height: detail.evaluate.isNotEmpty ? 14 : 2),
      if (detail.evaluate.isNotEmpty)
        SelectableText(
          detail.evaluate,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: cs.onSurfaceVariant,
          ),
        ),
      // ── 制作人员 / 声优 ──
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
      // ── 动作栏：赞/投币/收藏/分享（追番在标题旁） ──
      _buildActions(cs),
      const Divider(height: 24),
      // ── 选集 ──
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

  /// 追番按钮：粉色胶囊（追番 / 已追番），与 B 站风格一致。
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
                  _hasFollowed ? '已追番' : '追番',
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

  /// 评分 + 类型 + 角标 + 风格标签行。
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

  // ─── 动作栏：赞/投币/收藏/分享（B 站官方图标） ───
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
      child = Tooltip(message: tooltip, child: child);
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: child,
    );
  }

  /// 选集 chip：当前集高亮；会员 / 免费角标跟随显示。
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

  // ─── 播放器区域 ───
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

  /// 稳定播放历史 ID：`bili_ep_{ep_id}`，供播放器保存/恢复进度。
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

  /// 纯封面图（无播放按钮/返回按钮等浮层），供返回转场 shuttle 使用。
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

  /// 播放前的封面层：Hero 动画 + 封面图 + 右下角播放按钮，点击开始播放。
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
    // 经典模式（关闭「使用新版动画」）：封面 Hero 与来源卡片封面同 tag，
    // 点击时经典封面飞入（与视频页一致）
    if (heroTag != null && !SettingsService.heroTransitionBlurEnabled) {
      coverWidget = Hero(
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

/// 三连进度圈（与视频页 _TripleArc 一致）：从顶部开始、顺时针/逆时针
/// 随 [progress] 增长的圆弧，progress=0 时不绘制。
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
