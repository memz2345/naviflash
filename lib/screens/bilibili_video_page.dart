// lib/screens/bilibili_video_page.dart
//
// B 站视频播放页（应用内，参考 PiliPlus lib/pages/video 的交互）：
//   - 顶部 16:9 内嵌播放器（点击画面显示 OSD 控制层）：播放/暂停、进度、
//     分P、弹幕、全屏；顶栏 OSD 提供倍速 / 字幕 / 画质菜单
//   - 高能进度条：/x/player/v2 的 view_points 片段按 type 着色叠加在进度条上
//   - 「正在看」人数：/x/player/online/total，内嵌顶栏展示
//   - 倍速：0.5x ~ 2.0x（media_kit setRate，切分P/换画质后保持）
//   - B 站字幕：解析 playurl data.subtitle，拉取 JSON 转 SRT 后挂载
//     （参考 PiliPlus lib/utils/subtitle_utils.dart 的 json2Srt）
//   - 互动（参考 PiliPlus lib/http/video.dart 的 like/coin/triple/relation）：
//     点赞（长按一键三连）/ 投币（1 或 2 枚 + 同时点赞）/ 收藏 / 三连 / 分享，
//     UP 关注按钮；未登录或未开启「携带 Cookie 请求」时引导登录。
//   - 响应式布局（横竖屏判断与 SplitSettingsScreen 一致：width >= 768）：
//     * 宽屏（横屏）：左 = 播放器 + 操作区（UP/关注/标题/统计/动作栏/分P/简介），
//       右 = 独立面板，Tab 切换「相关视频」/「评论」
//     * 紧凑（竖屏）：上 = 播放器，下方 Tab：
//       左 tab「简介」= 操作区(作为 header) + 推荐视频一起滚动；右 tab「评论」
//   - 推荐视频 / 评论均为独立 page（bilibili_related_videos_page.dart /
//     bilibili_comments_page.dart），两种布局复用，支持下拉刷新与失败重试
//   - 全屏按钮 → 进入现有全屏播放器（MpvPlayerPage，带回进度/画质/高能进度条）
import 'dart:async';
import 'dart:io' show Platform, HttpClient;
import 'dart:math' as math;
import 'dart:typed_data' show Uint8List;

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
import 'package:naviflash/services/link_utils.dart';
import 'package:naviflash/services/bv_av.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/play_history_service.dart';
import 'package:naviflash/services/watch_history_service.dart';
import 'package:naviflash/services/playlist_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/services/video_cache_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/bili_note_list_sheet.dart';
import 'package:naviflash/widgets/danmaku/danmaku_controller.dart';
import 'package:naviflash/widgets/danmaku/danmaku_fetcher.dart';
import 'package:naviflash/widgets/danmaku/danmaku_list_sheet.dart';
import 'package:naviflash/widgets/danmaku/danmaku_model.dart';
import 'package:naviflash/widgets/danmaku/danmaku_send_sheet.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/comment/comment_composer.dart';
import 'package:naviflash/widgets/comment/comment_composer_fab.dart';
import 'package:naviflash/screens/note_editor_page.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/screens/pay_coins_page.dart';

/// 打开 B 站视频播放页（兼容 BV / av / 完整链接）。
/// 默认（搜索页/收藏/空间等入口）：iOS 风格毛玻璃转场 + 整页 Hero 放大，
/// 横竖屏一致（背景渐变模糊，播放页与封面保持清晰）；
/// [wideClassic] 为 true（视频页推荐视频入口）且宽屏时：标准
/// MaterialPageRoute + 封面 Hero 飞行，不使用毛玻璃模糊。
void openBilibiliVideo(
  BuildContext context, {
  required String bvid,
  String? initialTitle,
  String? initialCover,
  String? heroTag,
  Duration? initialPosition,
  bool wideClassic = false,
}) {
  // 推入视频页前收起虚拟键盘并清除焦点：否则返回时 FocusManager 会
  // 恢复被覆盖页的原焦点（如搜索框），键盘会再次弹出
  FocusManager.instance.primaryFocus?.unfocus();
  final wide = MediaQuery.sizeOf(context).width >= 768;
  final page = BilibiliVideoPage(
    bvid: bvid,
    initialTitle: initialTitle,
    initialCover: initialCover,
    heroTag: heroTag,
    initialPosition: initialPosition,
    wideClassic: wideClassic,
  );
  Navigator.of(context).push(
    wide && wideClassic
        // 宽屏 + 推荐视频入口：标准 Hero 动画引入封面（不要毛玻璃模糊）
        ? MaterialPageRoute(builder: (_) => page)
        // 其余：iOS 开 App 式整页放大（页面清晰、只模糊旧页面）
        : heroTransitionRoute(heroZoom: heroTag != null, page: page),
  );
}

/// 从 URL 中解析 BV 号；非视频链接返回 null。
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

/// 在本应用内打开 B 站链接（评论区蓝链 / 评论长按菜单链接复用）：
/// - bilibili.com/.../BVxxx 直接解析跳视频页
/// - b23.tv 短链先 HTTP 跟随重定向拿真实 URL 再解析 BV
/// - 非 B 站视频链接回退内置浏览器
Future<void> openBiliLinkInApp(
  BuildContext context, {
  required String url,
  bool confirm = false,
}) async {
  final normalized = normalizeLink(url);
  if (normalized.isEmpty) return;
  var bvid = bilibiliBvidFromUrl(normalized);
  // b23.tv 短链：HTTP 跟随重定向拿真实 URL 再解析 BV
  if (bvid == null) {
    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.host.contains('b23.tv')) {
      final resolved = await _resolveB23ShortLink(normalized);
      if (resolved != null) bvid = bilibiliBvidFromUrl(resolved);
    }
  }
  if (!context.mounted) return;
  if (bvid != null) {
    openBilibiliVideo(context, bvid: bvid);
    return;
  }
  // 非 B 站视频链接：回退内置浏览器
  await openLinkInBuiltInBrowser(context, url: normalized, confirm: confirm);
}

/// 跟随 b23.tv 短链重定向，返回最终真实 URL；失败返回 null。
Future<String?> _resolveB23ShortLink(String url) async {
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

/// 从 B 站视频链接解析空降时间点（?t=秒 或 ?t=1h2m3s）；无时间点返回 null。
Duration? bilibiliTimeFromUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final t = uri.queryParameters['t'];
  if (t == null || t.isEmpty) return null;
  // 纯秒数：?t=123 / ?t=123.5
  final secs = double.tryParse(t);
  if (secs != null && secs > 0) {
    return Duration(milliseconds: (secs * 1000).round());
  }
  // h/m/s 格式：1h2m3s / 2m3s / 3s
  int part(String unit) {
    final m = RegExp('(\\d+)$unit').firstMatch(t);
    return m == null ? 0 : int.tryParse(m.group(1)!) ?? 0;
  }

  final total = part('h') * 3600 + part('m') * 60 + part('s');
  if (total > 0) return Duration(seconds: total);
  return null;
}

/// Tab 栏高度（与 PiliPlus lib/pages/video/view.dart buildTabBar 一致：45）。
const double _tabBarHeight = 45.0;

/// 整页 Hero 的时序曲线：进出都平滑加速、减速；使用同一条曲线也能让
/// push 中途被 pop 时复用的飞行保持速度连续。
const Curve _videoHeroCurve = Curves.easeInOutCubic;

/// 窄屏下播放器折叠后的标题栏高度（与 tab 栏同高，参考 PiliPlus kToolbarHeight）。
const double _kPlayerCollapsedHeight = 56.0;

/// 监听宽屏内嵌评论 Navigator 的路由进出，维护 [_replyPageOpen]。
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

class BilibiliVideoPage extends StatefulWidget {
  final String bvid;
  final String? initialTitle;
  final String? initialCover;

  /// 封面 Hero 动画 tag（从卡片进入时传，与卡片封面 Hero 匹配）。
  final String? heroTag;

  /// 空降时间点（扫码/链接 ?t= 解析）：打开后直接跳到该进度，忽略本地播放历史。
  final Duration? initialPosition;

  /// 宽屏经典模式：推荐视频入口在宽屏下使用标准封面 Hero 转场
  /// （无整页 Hero 放大、无毛玻璃模糊）；**仅宽屏生效** ——
  /// 竖屏推荐视频与搜索页等入口一样保留 iOS 整页放大 + 模糊动画。
  final bool wideClassic;

  const BilibiliVideoPage({
    super.key,
    required this.bvid,
    this.initialTitle,
    this.initialCover,
    this.heroTag,
    this.initialPosition,
    this.wideClassic = false,
  });
  @override
  State<BilibiliVideoPage> createState() => _BilibiliVideoPageState();
}

class _BilibiliVideoPageState extends State<BilibiliVideoPage>
    with TickerProviderStateMixin {
  // 内嵌播放器（视频播放页模式）句柄：分P切换 / 全屏时控制
  final GlobalKey<MpvPlayerPageState> _playerKey =
      GlobalKey<MpvPlayerPageState>();

  /// 退出前的播放器卸载锁：防止在卸载期间重复触发 / 过早 pop。
  bool _exitUnloadLock = false;
  // 宽屏右侧评论区面板的嵌套导航：回复页作为独立 push 仅在面板内展示，
  // 返回键关闭回复页而不销毁整个播放器
  final GlobalKey<NavigatorState> _commentsNavKey = GlobalKey<NavigatorState>();
  // 视频页统一「发评论」FAB 发评论成功后 +1，驱动评论页刷新第一页。
  final ValueNotifier<int> _commentPostedTick = ValueNotifier(0);
  // 宽屏内嵌评论 Navigator 是否打开了回复详情页（此时隐藏父 FAB，避免
  // 与回复详情页自身的「发回复」FAB 重叠）。由 _commentsNavObserver 维护。
  bool _replyPageOpen = false;
  late final NavigatorObserver _commentsNavObserver = _VideoCommentsNavObserver(
    _onCommentsNavChanged,
  );
  void _onCommentsNavChanged() {
    final canPop = _commentsNavKey.currentState?.canPop() ?? false;
    if (canPop != _replyPageOpen) {
      _replyPageOpen = canPop;
      if (mounted) setState(() {});
    }
  }

  final DanmakuController _danmaku = DanmakuController();
  // 长按赞一键三连动画（参考 PiliPlus TripleMixin：1200ms 前进 / 400ms 回退）
  late final AnimationController _tripleController;
  Timer? _tripleTimer; // 长按判定计时（255ms 内松开 = 普通点赞）
  // ✅ 点击折叠标题栏续播时：从当前折叠值平滑展开回完整 16:9 播放器的动画
  late final AnimationController _expandController;
  double _expandStartCollapse = 0; // 展开动画起始的折叠值
  BiliVideoDetail? _detail;
  BiliPlayUrl? _playUrl;
  String? _error;
  bool _loading = true;
  bool _loadingPlayUrl = false;

  // ── 离线视频流缓存（播放地址 + 起始分P定位，供后台下载） ──
  /// 本次实际开始播放的分P（首次解析成功那页），后台下载只针对它。
  int _startedPageIndex = -1;

  /// 本次解析出的可播放地址（edl:// 或 durl 直链）。
  String? _startedUrl;

  /// 本页是否已尝试过后台缓存（成功后不再重复尝试/请求）。
  bool _offlineCacheAttempted = false;

  // UP 主粉丝数 / 投稿数：view 接口的 owner 不含这些字段（恒为 0），
  // 详情加载后异步用 card 接口补充（见 _loadOwnerStats）。
  int _ownerFans = 0;
  int _ownerVideos = 0;
  bool _started = false; // 是否已开始播放（渲染内嵌视频播放页）
  bool _fullscreen = false; // 全屏只是位置/尺寸变化：共用同一个播放器实例
  // 整页 Hero（iOS 开 App 放大）是否包裹页面：入场飞行期间为 true，
  // 转场完成后移除（解除对内层 Hero 的嵌套限制，相关视频卡片可独立飞行）；
  // 返回时由 PopScope 拦截先重新包裹再 pop，保证返回也有整页缩回动画。
  bool _zoomHeroActive = true;
  // 播放器是否正在播放（暂停时右下角显示「小电视」播放按钮）
  bool _isPlaying = false;
  // 是否至少播放过一次（用于避免初始加载中误显示暂停按钮）
  bool _seenPlaying = false;
  StreamSubscription<bool>? _playingSub;
  // 内嵌播放器 OSD 控制条是否可见（可见时不叠加暂停按钮，避免遮挡）
  bool _controlsVisible = false;
  // 封面「小电视」播放按钮：等 Hero 飞入（路由过渡）结束后再显示
  bool _showPlayButton = false;
  Animation<double>? _routeAnimation;
  AnimationStatusListener? _routeAnimListener;
  // 窄屏模式：向下滚动内容时播放器折叠到标题栏（参考 PiliPlus）
  // 用 ValueNotifier 驱动，避免滚动时整页重复重建
  final ValueNotifier<double> _collapseNotifier = ValueNotifier(0);
  double _playerHeight = 0; // 当前 16:9 播放器高度（供滚动处理器使用）
  // 当前分P / 画质
  int _pageIndex = 0;
  int _currentQn = 0; // 0 = 服务端默认
  // 播放器状态（由内嵌播放器 onPositionChanged 同步）
  Duration _position = Duration.zero;
  // 当前播放地址 / 全屏播放列表
  String _currentUrl = '';
  Playlist? _fullPlaylist;
  String _videoTitle = '';
  // AI 翻译后的简介（未翻译时为空，渲染层回退到原文）
  String _translatedDesc = '';
  // 「查看原文」原地切换：true 时简介直接展示原文（不弹窗）
  bool _descShowOriginal = false;
  // 标题「查看原文」原地切换：true 时标题直接展示原文（不弹窗）
  bool _titleShowOriginal = false;
  // 互动状态（点赞/点踩/投币/收藏/关注）
  late int _likeCount;
  late int _coinCount;
  late int _favCount;
  bool _hasLiked = false;
  bool _hasDisliked = false;
  bool _hasFaved = false;
  int _coinGiven = 0; // 当前账号已投币数（0/1/2）
  bool _hasFollowed = false;
  bool _interacting = false; // 防止互动连点
  bool _coinWithLike = true; // 投币时是否同时点赞
  // 高能进度条
  List<BiliViewPoint> _viewPoints = [];
  // 正在看的人数
  int _onlineCount = 0;
  Timer? _onlineTimer; // 定时刷新「正在看」人数
  // 视频标签（紧凑模式点标题展开后展示）
  List<BiliVideoTag> _tags = const [];
  // 紧凑模式下「简介 + 标签」是否展开（宽屏始终展示，不参与此状态）
  bool _introExpanded = false;
  // 弹幕输入框
  final TextEditingController _dmInputController = TextEditingController();

  // ── 手动缓存状态（参考 PiliPlus 离线缓存按钮）
  bool _cacheChecking = false;
  bool _isCached = false;
  bool _isCaching = false;

  static const Map<String, String> _mediaHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  /// 与 SplitSettingsScreen 一致的横竖屏判断。
  bool get _isWideScreen => MediaQuery.of(context).size.width >= 768;

  /// 是否使用整页 Hero（iOS 开 App 放大）：开启模糊 + 有封面 tag，
  /// 且不是「宽屏 + 推荐视频经典入口」。
  /// wideClassic 仅在宽屏生效：竖屏推荐视频同样保留整页放大 + 模糊。
  bool get _usesZoomHero =>
      widget.heroTag != null &&
      SettingsService.heroTransitionBlurEnabled &&
      !(widget.wideClassic && _isWideScreen);

  /// 整页 Hero 包裹期间禁用内层 Hero（避免「Hero 嵌套 Hero」断言）：
  /// 与相关视频页的 heroTagsDisabled 同一机制 —— 直接不包 Hero，
  /// 而不是 HeroMode（HeroMode 只禁飞行、不阻止嵌套断言）。
  bool get _zoomHeroBlocksInnerHeroes => _usesZoomHero && _zoomHeroActive;

  @override
  void initState() {
    super.initState();
    _videoTitle = widget.initialTitle ?? '';
    // 恢复持久化的弹幕设置（共享给内嵌/全屏播放器）
    _danmaku.restoreSettings();
    // 三连动画：前进到完成时执行三连 API；松开中途回退则不触发。
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
    // ✅ 展开动画：把折叠值从起始值平滑驱动到 0（完整 16:9）
    _expandController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 320),
        )..addListener(() {
          final t = Curves.easeOutCubic.transform(_expandController.value);
          _collapseNotifier.value = _expandStartCollapse * (1 - t);
        });
    _loadDetail();
    // 封面小电视按钮：Hero 飞入动画（与路由过渡同步）结束后再显示。
    // 无路由动画（heroTag 为空）时立即显示。
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
            // 入场飞行结束：移除整页 Hero，解除内层 Hero 嵌套限制
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
    // 退出页面时恢复系统状态栏（若仍处于全屏）
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
    final detail = await BilibiliVideoService.fetchDetail(widget.bvid);
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
    // ✅ 恢复播放进度（本地播放历史）：多分P时恢复最近看过的分P及进度；
    //    带空降时间点（扫码/链接 ?t=）时优先，忽略本地历史
    if (widget.initialPosition != null) {
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
    // 不自动播放：只展示封面，点击封面后由 _startPlayback() 解析并播放。
    _loadRelation();
    // 未播放也展示「正在看」人数 / UP 粉丝数投稿数。
    _loadOwnerStats();
    _loadTags();
    _loadOnlineCount();
    _checkCached();
    // ✅ 进入视频页即记录观看历史（用户需求：不再等播放才记录）
    //    无痕模式时跳过；force=true 允许 0 进度也入历史。
    _recordWatchHistoryOnEnter(detail);
    // AI 翻译标题/简介（异步，翻译完成后刷新标题显示）
    _translateDetail(detail);
  }

  /// AI 翻译视频标题与简介并刷新显示（静默失败，不影响原标题）。
  Future<void> _translateDetail(BiliVideoDetail detail) async {
    try {
      final translate = context.read<BilibiliTranslateService>();
      if (!translate.enabled) return;
      // 优先用全局缓存：bvid 翻译过一次就直接显示，不再重复请求
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
      // 翻译失败时保持原标题
    }
  }

  /// 从本地播放历史恢复进度：
  ///   - 用稳定 ID `bili_{bvid}_{cid}` 匹配（见 PlayHistoryService.saveProgress）
  ///   - 多分P时取 savedAt 最新的一条，恢复对应分P及进度
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

  /// 补充拉取视频标签（紧凑模式点标题展开后展示）。
  Future<void> _loadTags() async {
    final detail = _detail;
    if (detail == null) return;
    final tags = await BilibiliVideoService.fetchVideoTags(
      bvid: detail.bvid,
      aid: detail.aid,
    );
    if (!mounted || tags.isEmpty) return;
    setState(() => _tags = tags);
  }

  /// 补充拉取 UP 主粉丝数 / 投稿数（view 接口不含，card 接口补充并缓存）。
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

  /// 拉取当前账号对本视频的点赞/点踩/投币/收藏/关注状态（未登录则跳过）。
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

  // ─── 互动操作 ───

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    showAppToast(context, msg, error: error);
  }

  /// 确保可互动（登录 + 开启「携带 Cookie 请求」+「互动操作」范围）；
  /// 不满足时提示并返回 false。
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
        // 登录成功后刷新互动状态
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

  /// 点赞 / 取消点赞。
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
        if (target) _hasDisliked = false; // 点赞与点踩互斥
        _likeCount = (_likeCount + (target ? 1 : -1)).clamp(0, 0x7fffffff);
      });
      _toast(target ? '已点赞' : '已取消点赞');
    } else {
      _toast('点赞失败：${result.message}', error: true);
    }
  }

  /// 点踩 / 取消点踩（参考 PiliPlus VideoHttp.dislikeVideo）。
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
          // 点踩与点赞互斥：取消点赞并回退计数
          _hasLiked = false;
          _likeCount = (_likeCount - 1).clamp(0, 0x7fffffff);
        }
      });
      _toast(target ? '已点踩' : '已取消点踩');
    } else {
      _toast('点踩失败：${result.message}', error: true);
    }
  }

  /// 一键三连（点赞 + 投币 + 收藏）。
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

  // ─── 长按赞三连手势（参考 PiliPlus TripleMixin） ───

  /// 是否已完成三连。
  bool get _hasTriple => _hasLiked && _coinGiven > 0 && _hasFaved;

  /// 按下赞：255ms 后判定为长按 → 开始三连动画（震动反馈）。
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

  /// 松开赞：若在长按判定前松开 → 普通点赞/取消点赞；
  /// 若三连动画进行中松开 → 回退动画（不触发三连）。
  void _onLikeTapUp(TapUpDetails _) {
    if (_tripleTimer != null) {
      _tripleTimer!.cancel();
      _tripleTimer = null;
      _toggleLike();
    } else if (_tripleController.isAnimating) {
      _tripleController.reverse();
    }
  }

  /// 手势取消：同样只回退动画，不触发三连。
  void _onLikeTapCancel() {
    if (_tripleTimer != null) {
      _tripleTimer!.cancel();
      _tripleTimer = null;
    } else if (_tripleController.isAnimating) {
      _tripleController.reverse();
    }
  }

  /// 打开投币页（移植自 PiliPlus PayCoinsPage：2233 马里奥 / 枪娘投币动画，
  /// 1 枚 / 2 枚金币可选，点击 / 上滑投币）。
  /// 未登录也可打开，点击 2233 投币时才提示登录。
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

  /// 投币页回调：先校验登录（未登录提示），再执行投币 API 并更新计数。
  Future<void> _doPayCoin(int multiply, bool withLike, num? coins) async {
    final detail = _detail;
    if (detail == null || _interacting) return;
    // 点击 2233 才校验登录：未登录 / 未开启携带 Cookie 时提示
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

  /// 收藏 / 取消收藏（快速收藏到默认/第一个收藏夹）。
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
    // 收藏：找默认/第一个收藏夹
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

  /// 关注 / 取消关注 UP 主。
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

  // ─── 分享：下拉菜单（参考 PiliPlus） ───

  /// 当前视频的分享链接。
  String? get _shareUrl {
    final detail = _detail;
    if (detail == null) return null;
    return 'https://www.bilibili.com/video/${detail.bvid}';
  }

  /// 带当前播放时间的分享链接（空降参数 ?t=秒；未开始播放则不带）。
  String? get _shareUrlWithTime {
    final base = _shareUrl;
    if (base == null) return null;
    if (_started && _position.inMilliseconds > 0) {
      final sec = (_position.inMilliseconds / 1000).round();
      return '$base?t=$sec';
    }
    return base;
  }

  /// 复制视频链接（带当前播放时间，可空降）到剪贴板。
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

  /// 在内置浏览器打开此视频链接（其他 app 打开 = 应用内浏览器）。
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

  /// 调起系统分享面板分享视频链接。
  void _shareVideo() {
    final url = _shareUrl;
    if (url == null) return;
    SharePlus.instance.share(
      ShareParams(text: url, subject: _videoTitle.isEmpty ? null : _videoTitle),
    );
  }

  /// 分享：与视频卡片长按菜单同款的毛玻璃底部菜单（参考 PiliPlus）：
  /// 封面预览 + 复制链接 / 浏览器打开 / 分享。
  void _openShareMenu() {
    showFrostedActionSheet(
      context,
      cover: _detail?.pic,
      title: _videoTitle,
      subtitle: _detail?.ownerName,
      actions: [
        GlassMenuAction(
          icon: Icons.copy_rounded,
          // 带当前播放时间：播放中显示「复制空降链接（m:ss）」
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
      ],
    );
  }

  /// 点击封面后开始播放：解析当前分P的播放地址并渲染内嵌视频播放页
  /// （MpvPlayerPage 视频播放页模式，负责播放/弹幕/字幕/画质/解码格式）。
  Future<void> _startPlayback() async {
    // ✅ 已开始 / 正在解析时不重复进入：修复反复点击会并发进入多个解析流程、
    //    互相抢 setState，表现为「要点几遍才播放」。
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
    // 首次解析后同步服务端默认画质
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
    // ✅ 离线视频流缓存：命中本地文件直接播放（不再从 CDN 拉流），
    //    未命中则用远端地址并在观看数秒后后台下载（见 _cacheCurrentStreamIfWatched）
    final localUrl = await VideoStreamCache.localPlayableUrl(
      detail.bvid,
      page.cid,
    );
    if (!mounted) return;
    final effectiveUrl = localUrl ?? url;
    // 生成全屏播放列表：所有分P（懒解析失败的分P跳过）。
    // 其余分P并行解析（先全部发出请求再收集），多P视频不再逐个串行
    // 请求拖慢首P启动；整段解析期间 _loadingPlayUrl 保持 true，封面
    // 一直显示加载中，避免用户以为没点到而反复点击。
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
    // 请求已在上面全部发出（并发），这里只是依次取结果：
    // 总耗时 ≈ 最慢的一个请求，而非各请求之和。
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
    // 订阅播放器播放状态：暂停时右下角显示「小电视」播放按钮
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final st = _playerKey.currentState;
      if (st == null) return;
      _playingSub?.cancel();
      _playingSub = st.player.stream.playing.listen((playing) {
        if (!mounted) return;
        if (playing) _seenPlaying = true;
        // ✅ 播放中不显示折叠顶栏：自动展开回完整 16:9 播放器。
        //    展开动画进行中时由动画驱动折叠值到 0，避免瞬间跳变。
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

  /// 观看数秒后，把本次开始播放的分P媒体流后台下载到本地（离线缓存）：
  /// 下次打开同一视频直接从本地播放、不再从 CDN 拉取。
  /// 已缓存 / 已尝试过 / 开关关闭时自动跳过（不打断播放）。
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
    if (await VideoStreamCache.lookup(detail.bvid, page.cid) != null) return;
    if (url.startsWith('edl://')) {
      final parsed = VideoStreamCache.parseEdl(url);
      if (parsed == null) return;
      await VideoStreamCache.cacheDash(
        bvid: detail.bvid,
        cid: page.cid,
        videoUrl: parsed.a,
        audioUrl: parsed.b,
        qn: play.quality,
        // 记录封面：供「已缓存视频」页展示封面 / iOS 缩回动画
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

  /// 检查当前分P是否已缓存（用于动作栏“缓存”按钮状态，参考 PiliPlus 下载状态）
  Future<void> _checkCached() async {
    final detail = _detail;
    if (detail == null || detail.pages.isEmpty) return;
    final cid = detail.pages[_pageIndex].cid;
    if (VideoStreamCache.isDownloading(detail.bvid, cid)) {
      if (mounted)
        setState(() {
          _isCaching = true;
          _isCached = false;
        });
      return;
    }
    setState(() => _cacheChecking = true);
    final entry = await VideoStreamCache.lookup(detail.bvid, cid);
    if (!mounted) return;
    setState(() {
      _cacheChecking = false;
      _isCached = entry != null;
      _isCaching = VideoStreamCache.isDownloading(detail.bvid, cid);
    });
  }

  /// 手动缓存当前分P（参考 PiliPlus DownloadService.createDownload）
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
    // 若已开始播放，直接复用已解析地址
    String? url = _startedUrl;
    int cid = detail.pages[_pageIndex].cid;
    int qn = _currentQn != 0 ? _currentQn : (_playUrl?.quality ?? 0);
    String cover = detail.pic;
    // 未开始播放：先解析当前分P
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
      // 保存供后续自动缓存判断
      _playUrl = play;
      _startedUrl = url;
      _startedPageIndex = _pageIndex;
    }
    setState(() => _isCaching = true);
    showAppToast(context, L10n.current.cacheToastSuccess);
    try {
      if (url.startsWith('edl://')) {
        final parsed = VideoStreamCache.parseEdl(url);
        if (parsed == null) throw '解析 edl 失败';
        await VideoStreamCache.cacheDash(
          bvid: detail.bvid,
          cid: cid,
          videoUrl: parsed.a,
          audioUrl: parsed.b,
          qn: qn,
          cover: cover,
        );
      } else {
        await VideoStreamCache.cacheDurl(
          bvid: detail.bvid,
          cid: cid,
          url: url,
          qn: qn,
          cover: cover,
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

  /// 进入视频页即记录观看历史（force 允许 0 进度），保留已有进度仅刷新时间
  Future<void> _recordWatchHistoryOnEnter(BiliVideoDetail detail) async {
    try {
      final settings = context.read<SettingsService>();
      if (settings.incognitoMode) return;
      final wh = context.read<WatchHistoryService>();
      final cid = detail.pages.isNotEmpty
          ? detail.pages[_pageIndex.clamp(0, detail.pages.length - 1)].cid
          : null;
      // 已有记录则保留其进度/时长，仅刷新 watchedAt/标题/封面
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

  /// 暂停态「小电视」播放按钮：圆形 ripple + 白色 play 图标（[btnSize] 含 padding）。
  Widget _buildTvButton(double btnSize) {
    final iconSize = btnSize - 24; // 两侧各 12 padding
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

  /// 弹幕开关：切换是否显示弹幕（B 站原版 dm_on / dm_off 图标）。
  void _toggleDanmaku() {
    setState(() => _danmaku.enabled = !_danmaku.enabled);
    // 立即通知弹幕视图重绘，暂停时也能即时生效
    _danmaku.onNeedRepaint?.call();
    _danmaku.persistSettings();
  }

  /// 拉取高能进度条片段（看点/高能段），用于进度条着色。
  Future<void> _loadViewPoints(int aid, int cid) async {
    final points = await BilibiliVideoService.fetchViewPoints(
      aid: aid,
      cid: cid,
    );
    if (!mounted) return;
    setState(() => _viewPoints = points);
  }

  // ─── 分P（内嵌播放器自行处理分P切换） ───
  void _switchPage(int index) {
    final detail = _detail;
    if (detail == null || index < 0 || index >= detail.pages.length) return;
    if (index == _pageIndex) return;
    setState(() {
      _pageIndex = index;
      _position = Duration.zero;
    });
    _checkCached();
    // 切分P也视为进入新视频，立即记录历史
    _recordWatchHistoryOnEnter(detail);
    if (_started) {
      _playerKey.currentState?.switchEpisode(index);
    }
  }

  // ─── 窄屏播放器折叠到标题栏（参考 PiliPlus） ───

  /// 给定折叠像素数，计算窄屏下是否已完全折叠为标题栏。
  bool _isCoverCollapsed(double collapsePx) {
    if (_isWideScreen) return false;
    final maxCollapse = math.max(0.0, _playerHeight - _kPlayerCollapsedHeight);
    return maxCollapse > 0 && collapsePx >= maxCollapse - 1;
  }

  /// 监听内容区域滚动，驱动播放器折叠（0 = 完整 16:9，最大 = 标题栏高度）。
  /// 视频播放中不折叠（与 PiliPlus 一致），暂停/未播放时才可折叠到标题栏。
  bool _onCompactScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is! ScrollUpdateNotification && n is! ScrollEndNotification) {
      return false;
    }
    // ✅ 用户滚动时打断展开动画，改由滚动直接控制折叠值
    if (_expandController.isAnimating) {
      _expandController.stop();
    }
    final maxCollapse = math.max(0.0, _playerHeight - _kPlayerCollapsedHeight);
    // 播放中保持完整，不收缩（若之前已折叠则先展开）
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

  // ─── 控制条已移交内嵌播放器（MpvPlayerPage 视频播放页模式） ───

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

  /// 秒数格式化为 m:ss / h:mm:ss（复制空降链接菜单项展示用）。
  String _fmtSec(int sec) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    if (h > 0) return '$h:${two(m)}:${two(s)}';
    return '$m:${two(s)}';
  }

  // ─── 全屏：位置/尺寸变化，复用同一个 MpvPlayerPage 实例（不新建路由/播放器） ───
  void _setFullscreen(bool value) {
    if (mounted) {
      setState(() => _fullscreen = value);
    }
    // Android 全屏时隐藏系统状态栏（沉浸），退出后恢复
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

  /// 拉取「正在看」人数（弹幕栏展示，每 30s 自动刷新）。
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
    // 内嵌播放器宽度：宽屏为左栏宽度，紧凑为全屏宽
    final playerWidth = isWide ? (w - rightWidth) : w;
    final playerHeight = playerWidth * 9 / 16;
    _playerHeight = playerHeight;
    // 非全屏时播放器与内容顶部对齐（状态栏下方）；全屏时铺满整个屏幕
    final playerTop = _fullscreen ? 0.0 : MediaQuery.of(context).padding.top;

    // 共享播放器实例：全屏只是位置/尺寸变化（同一 State / 同一 Player）。
    // 窄屏滚动折叠时复用同一实例，仅裁剪可见区域，避免播放器整体重排。
    final playerWidget = MpvPlayerPage(
      key: _playerKey,
      mode: _fullscreen ? PlayerPageMode.fullscreen : PlayerPageMode.videoPage,
      videoUrl: _currentUrl,
      title: _pageTitle(),
      // 系统媒体通知 artist = UP 主名字
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
      // 共享弹幕控制器：发送弹幕上屏 / 「已装填」条数统计
      danmakuController: _danmaku,
      playUrlInfo: _playUrl,
      initialQualityQn: _currentQn > 0 ? _currentQn : null,
      viewPoints: _viewPoints,
      // 系统媒体播放器缩略图 = 视频封面（真正播放时才展示）
      artUri: _detail?.pic,
      // 右键「复制空降链接」用的 BV 号
      bilibiliBvid: _detail?.bvid,
      // 稳定播放历史 ID（bvid+cid），保证跨会话匹配/恢复进度
      historyId: _currentHistoryId,
      onPositionChanged: (p) {
        _position = p;
        // ✅ 观看数秒后后台下载当前视频到本地（离线缓存，下次秒开不再拉流）
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
    );

    Widget page = Scaffold(
      // 播放器/页面背景与其它 widget 使用同一主题色（不再黑色）
      backgroundColor: cs.surfaceContainerLow,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 页面内容（全屏时离屏但保留状态；顶部预留播放器区域）
          Offstage(
            offstage: _fullscreen,
            child: SafeArea(
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
                // 窄屏：顶部保留，底部随折叠裁掉
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
                      // 折叠时仍按完整 16:9 高度布局播放器，只裁剪露出顶部
                      maxHeight: playerHeight,
                      child: playerWidget,
                    ),
                  ),
                );
              },
            ),
          // 折叠时标题栏随折叠进度渐显，最终遮住收缩后的视频
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
                    // ✅ 与搜索栏一致的毛玻璃（FrostedSearchHeader 同款：
                    // surface 半透明 + 高斯模糊；原 opacity 0.9 近乎不透明，
                    // 模糊几乎看不见）
                    child: FrostedPanel(
                      blurSigma: 10,
                      opacity: 0.75,
                      child: _buildCollapsedBarContent(),
                    ),
                  ),
                );
              },
            ),

          // 暂停时整块区域可点击继续播放（与封面一致的交互）。
          // 仅在 OSD 控制条隐藏时生效，且始终让出顶部标题栏区域（返回
          // 按钮），折叠越深越透明。
          // ✅ 用 translucent GestureDetector 而非 Material+InkWell：
          //    InkWell 会拦截全部指针事件，导致暂停时播放器的双指缩放 /
          //    Ctrl+滚轮缩放失效；translucent 命中继续传递给下层播放器
          //    手势层（单击仍由本层竞技获胜触发续播）。
          if (_started && !_isPlaying && _seenPlaying && !_controlsVisible)
            ValueListenableBuilder<double>(
              valueListenable: _collapseNotifier,
              builder: (context, collapsePx, _) {
                // 全屏：暂停时整屏可点击续播
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
                // ✅ 未折叠时点击层铺满整个暂停画面（含顶部），修复顶部
                //    「少一截」无法点击续播的问题；折叠时才让出毛玻璃顶栏
                //    区域（该区域自带返回/展开手势）。
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
          // 暂停态顶部也显示返回按钮（与封面/折叠标题栏同款、同位置），
          // 折叠越深越透明（折叠标题栏自带的返回钮渐显接管）。
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
          // 暂停时右下角「小电视」播放按钮 + ripple（与封面/暂停页面同款）。
          // 位置随折叠收缩到视频右下角；折叠越深越透明（标题栏渐显盖住视频）。
          // OSD 控制条可见 / 全屏时上移，避免压住底部控制条；OSD 可见时同样显示。
          if (_started && !_isPlaying && _seenPlaying)
            ValueListenableBuilder<double>(
              valueListenable: _collapseNotifier,
              builder: (context, collapsePx, _) {
                const btnSize = 60.0;
                // 全屏：视频铺满整个屏幕，按钮固定在右下角并上移避开控制条
                if (_fullscreen) {
                  // ✅ 全屏 OSD 控制条隐藏时，小电视贴回真正的右下角；
                  //    OSD 显示时上移 90 避开底部控制条（与内嵌分支的
                  //    bottomInset = _controlsVisible ? 90 : 16 保持一致）。
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
                // OSD 控制条可见时上移，避免压住底部控制条
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

    // 整页 Hero：iOS 开 App 式放大到全屏（搜索卡片 → 视频播放页）。
    // 仅竖屏 + 开启模糊时使用；入场飞行结束后移除（_zoomHeroActive），
    // 解除对内层 Hero 的嵌套限制（相关视频卡片可独立飞行）；
    // 返回时由 PopScope 拦截先重新包裹再 pop。
    if (_usesZoomHero && _zoomHeroActive) {
      page = Hero(
        tag: widget.heroTag!,
        curve: _videoHeroCurve,
        reverseCurve: _videoHeroCurve,
        flightShuttleBuilder:
            (flightContext, animation, direction, fromContext, toContext) {
              final isPop = direction == HeroFlightDirection.pop;
              final target = isPop ? fromContext : toContext;
              final heroWidget = target.widget as Hero;
              // 运动过程保留卡片圆角（与搜索卡片 12px 圆角一致）
              const flightRadius = 12.0;
              // 卡片飞行期间新内容渐显（前段快速淡入，到站前全不透明）
              final fadeIn = CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
              );
              return AnimatedBuilder(
                animation: fadeIn,
                builder: (context, _) {
                  // Hero 在 push 中途被 pop 时会复用原来的 shuttle，
                  // direction 仍是 push；用真实动画状态识别反向飞行，
                  // 保持当前画面连续且不在返回末尾淡出。
                  final returning =
                      isPop || animation.status == AnimationStatus.reverse;
                  // 页面始终按目标尺寸布局（避免飞行期间小矩形硬布局
                  // 导致 RenderFlex overflow），再用 FittedBox 缩放到
                  // 当前飞行矩形，呈现 iOS 开 App 式的整页放大效果。
                  final screen = MediaQuery.sizeOf(context);
                  final Widget flying;
                  if (isPop) {
                    // 返回：渲染目标卡片 Hero 本体（封面缩略图 / 网格封面，
                    // 见来源页 Hero 只包封面），按飞行矩形自然布局——封面
                    // 精确缩回卡片图片位置，保留图片自身圆角。
                    flying = (toContext.widget as Hero).child;
                  } else {
                    // 进入：按当前卡片比例裁剪整页内容，而不是把整页
                    // 压缩塞进卡片，保持 iOS 卡片放大时的视觉重心。
                    // FittedBox 自身裁掉 cover 的溢出，内层 ClipRRect
                    // 保留内容圆角，外层 ClipRRect 保证飞行边界圆润。
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
                  // 返回时保持不透明：fadeIn 随弹栈动画反向归零，若沿用
                  // 0.35 + 0.65*fadeIn，缩回结尾会淡到 0.35，飞行结束
                  // 露出真实卡片时会有明显的透明度跳变。
                  return Opacity(
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
      // 全屏时系统返回键先退出全屏，再返回上级；
      // 播放中先暂停播放器（_unloadPlayerForExit）再 pop——
      // 否则转场/Hero 飞行期间同步销毁活跃视频纹理，动画会消失/黑屏；
      // 整页 Hero 已移除时先重新包裹（恢复返回缩回动画）再 pop；
      // _exitUnloadLock 期间继续拦截返回，避免暂停流程中二次 pop。
      // 整页 Hero 包裹期间整棵子树里不能再出现任何 Hero：头像/封面/相关
      // 视频卡片/评论区头像均已按 _zoomHeroBlocksInnerHeroes 禁用。
      canPop:
          !_fullscreen &&
          !_exitUnloadLock &&
          !_isPlayerPlaying &&
          (!_usesZoomHero || _zoomHeroActive),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_fullscreen && mounted) {
          _setFullscreen(false);
          return;
        }
        // ✅ 宽屏右侧评论区面板的嵌套导航还有可返回的页面（评论详情/回复页）
        //    时，返回键由内层 NavigatorPopHandler 消费：只关闭回复页，
        //    不再卸载播放器 / 销毁整个播放页。
        if ((_commentsNavKey.currentState?.canPop() ?? false)) return;
        // 播放中 / 整页 Hero 已移除：先暂停播放器、重新包裹 Hero 再 pop
        // （_unloadPlayerForExit 内部有锁防重入）。
        _unloadPlayerForExit();
      },
      // iOS 景深：上层再压栈（相关视频 / 空间 / 浏览器等）时，
      // 本页向中心缩小 + 渐隐 + 圆角（与搜索页同款），返回时反向恢复
      child: IosBackdropScale(child: page),
    );
  }

  /// 内嵌播放器是否正在输出画面（播放中）。
  /// 返回时必须先暂停/卸载再 pop，否则路由转场 / Hero 飞行期间
  /// 同步销毁活跃视频纹理，动画会消失 / 视频瞬间黑屏。
  bool get _isPlayerPlaying =>
      _started && (_playerKey.currentState?.player.state.playing ?? false);

  /// 退出播放页：先暂停正在输出的播放器，再 pop。
  ///
  /// 暂停（而非卸载/等帧）后播放器不再输出画面，路由转场 / Hero 缩回
  /// 动画期间销毁的是已静止的纹理，不会打断动画；暂停带超时兜底，
  /// media_kit pause 挂起/慢时也不能阻塞退出。
  ///
  /// 播放中返回同样覆盖非整页 Hero 入口（宽屏经典 / 关闭模糊）：
  /// 此前这些入口 canPop 恒为 true 直接 pop，播放器在转场期间被销毁，
  /// 返回动画同样会消失。
  Future<void> _unloadPlayerForExit() async {
    if (_exitUnloadLock) return;
    _exitUnloadLock = true;
    // ① 先暂停正在输出的播放器（带超时兜底，绝不阻塞退出）
    final st = _playerKey.currentState;
    if (st != null && st.player.state.playing) {
      try {
        await st.player.pause().timeout(
          const Duration(milliseconds: 600),
          onTimeout: () {},
        );
      } catch (_) {
        // 暂停失败不阻塞退出
      }
    }
    if (!mounted) return;
    // ② 整页 Hero 模式：重新包裹 Hero 供返回缩回动画。Hero 飞行在
    //    弹栈首帧渲染结束后才扫描 from/to Hero，此时 setState 已生效。
    if (_usesZoomHero && !_zoomHeroActive) {
      setState(() => _zoomHeroActive = true);
    }
    _exitUnloadLock = false;
    Navigator.of(context).pop();
  }

  // ─── 弹幕输入栏（参考 bilibili「发个友善的弹幕见证当下」+ 正在看人数） ───
  /// 弹幕输入栏：可直接输入弹幕；左侧「正在看 + 已装填」文字，无图标。
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
          // 正在看 + 已装填弹幕（放前面，纯文字；窄屏弹性截断防溢出）
          if (info.isNotEmpty)
            Flexible(
              flex: 2,
              child: Text(
                info,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          if (info.isNotEmpty) const SizedBox(width: 10),
          // 弹幕开关（B 站原版 dm_on / dm_off 图标，位于信息与输入框之间）
          _buildDanmakuToggleIcon(),
          if (info.isNotEmpty) const SizedBox(width: 10),
          // 样式化发送面板入口（模式/字号/颜色，参考 PiliPlus 发弹幕面板）
          Tooltip(
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
          // 直接输入弹幕
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
          // 发送（文字按钮，无图标）
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

  /// 弹幕开关图标按钮（B 站原版 dm_on / dm_off，弹幕栏与 tab 行共用）。
  /// 对齐 PiliPlus：启用时 secondary、禁用时 outline（原 navi 用 primary/0.5 灰）。
  Widget _buildDanmakuToggleIcon() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: _danmaku.enabled ? l10n.danmakuDisable : l10n.danmakuToggleOn,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _toggleDanmaku,
        child: Padding(
          padding: const EdgeInsets.all(3),
          // 官方 dm_on/dm_off 图标 viewBox 带负坐标（0 -110 1024 900），
          // flutter_svg 直接渲染会上下颠倒，旋转 180° 修正朝向；
          // 在此基础上再水平镜像，与 B 站原版图标朝向一致
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

  /// 从输入框直接发送弹幕（快速发送：滚动/白色/标准字号）。
  Future<void> _sendDanmakuFromInput() async {
    final msg = _dmInputController.text.trim();
    _dmInputController.clear();
    await _sendDanmaku(msg);
  }

  /// 打开 PiliPlus 风格「发弹幕」面板（模式/字号/颜色/实时预览）；
  /// 面板点「发送」后才真正调 API（参考 PiliPlus）。
  Future<void> _openDanmakuComposer() async {
    final detail = _detail;
    if (detail == null) return;
    if (!await _ensureCanInteract()) return;
    if (!mounted) return;
    final style = await showDanmakuSendSheet(
      context,
      initialText: _dmInputController.text.trim(),
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

  /// 发送一条弹幕（登录校验 → /x/v2/dm/post → 立即上屏）。
  /// [mode]：1 滚动 / 4 底部 / 5 顶部；[color] 十进制颜色；[fontSize] 18/25/36。
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
    // 发送成功后立即上屏（带所选模式/颜色/字号）
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

  // ═══════════ 宽屏（横屏）：左 播放器+操作区 | 右 相关视频/评论 ═══════════
  Widget _buildWideLayout(ColorScheme cs) {
    final rightWidth = (MediaQuery.of(context).size.width * 0.34).clamp(
      320.0,
      480.0,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 左侧较大区域：播放器（外层 Stack 共享实例覆盖）+ 弹幕栏 + 操作区 ──
        Expanded(
          child: Column(
            children: [
              AspectRatio(aspectRatio: 16 / 9, child: _buildPlayerArea()),
              // 弹幕输入栏 + 正在看人数（视频控件下方、作者上方）
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
          color: cs.outlineVariant.withOpacity(0.5),
        ),
        // ── 右侧面板：相关视频 / 评论（独立 page） ──
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
                        // ── 内容区（滚动，被上方毛玻璃 tab 栏遮挡） ──
                        Positioned.fill(
                          child: TabBarView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: _tabBarHeight,
                                ),
                                child: BilibiliRelatedVideosPage(
                                  bvid: _detail!.bvid,
                                  // 整页 Hero 包裹期间禁用卡片 Hero（避免嵌套）
                                  heroTagsDisabled:
                                      _usesZoomHero && _zoomHeroActive,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: _tabBarHeight,
                                ),
                                // 宽屏：评论区面板内嵌一个 Navigator，回复页作为独立
                                // push 仅在面板内展示，返回键关闭回复页而不销毁播放器；
                                // 全屏时面板隐藏，不拦截返回（交给外层退出全屏）
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
                                            oid: _detail!.aid,
                                            upMid: _detail!.ownerMid,
                                            commentPostedTick:
                                                _commentPostedTick,
                                            episodeTitle: _detail!.title,
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
                        // ── 毛玻璃 tab 栏 ──
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: _tabBarHeight,
                          child: _buildTabRow([
                            AppLocalizations.of(context).videoTabRelated,
                            AppLocalizations.of(
                              context,
                            ).videoTabCommentsCount(_detail!.reply),
                          ]),
                        ),
                        // ── 视频页统一悬浮按钮（评论 tab = 发评论 / 相关视频 tab = 单列·多列）──
                        Positioned(
                          right: 16,
                          bottom: 16,
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

  // ═══════════ 紧凑（竖屏）：上 播放器（外层 Stack 共享实例覆盖），下 tab ═══════════
  Widget _buildCompactLayout(ColorScheme cs) {
    final detail = _detail;
    final w = MediaQuery.of(context).size.width;
    final playerHeight = w * 9 / 16;
    return Column(
      children: [
        // 向下滚动内容时播放器折叠到标题栏（占位高度与外层共享播放器同步）
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
                          // ── 内容区（滚动，被上方毛玻璃 tab 栏遮挡） ──
                          Positioned.fill(
                            child: TabBarView(
                              children: [
                                // 左 tab：操作区作为 header + 推荐视频一起滚动
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: _tabBarHeight,
                                  ),
                                  child: BilibiliRelatedVideosPage(
                                    bvid: detail.bvid,
                                    // 整页 Hero 包裹期间禁用卡片 Hero（避免嵌套）
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
                                // 右 tab：评论
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: _tabBarHeight,
                                  ),
                                  child: BilibiliCommentsPage(
                                    oid: detail.aid,
                                    upMid: detail.ownerMid,
                                    episodeTitle: detail.title,
                                    heroTagsDisabled:
                                        _zoomHeroBlocksInnerHeroes,
                                    currentProgress: _commentsPanelProgress,
                                    captureFrame: _commentsPanelCaptureFrame,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ── 毛玻璃 tab 栏（搜索页同款模糊）
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
                          // ── 视频页统一悬浮按钮 ──
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: Builder(
                              builder: (ctx) => _buildSharedFab(ctx),
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

  // ── 视频页统一悬浮按钮：评论 tab = 发评论（Hero 飞到发送）；相关视频 tab = 单列/多列切换 ──
  Widget _buildSharedFab(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tc = DefaultTabController.of(context);
    final replyOpen = _replyPageOpen;
    return AnimatedBuilder(
      animation: tc,
      builder: (context, _) {
        final onComments = tc.index == 1;
        if (onComments) {
          // 宽屏内嵌 Navigator 打开回复详情页时隐藏，避免与「发回复」FAB 重叠。
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

  /// 视频页统一「发评论」FAB：打开评论发送面板（一级评论，支持图片/进度/截图）；
  /// heroTag 与面板「发送」按钮共用 → Hero 飞接；发送成功后 +1 刷新信号。
  Future<void> _openCommentComposer() async {
    if (_detail == null) return;
    final result = await showCommentComposer(
      context,
      oid: _detail!.aid,
      currentProgress: _commentsPanelProgress,
      captureFrame: _commentsPanelCaptureFrame,
      heroTag: kVideoPageCommentHeroTag,
    );
    if (result.sent) _commentPostedTick.value++;
  }

  // ═══════════ tab 行 + 发弹幕 / 弹幕开关 ═══════════
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

  // ── Tab 栏：与 PiliPlus lib/pages/video/view.dart buildTabBar 完全一致 ──
  //    高度 45、底部细线、左侧 ConstrainedBox(96*tabs.length) TabBar、右侧
  //    「发弹幕」TextButton + 弹幕开关 IconButton，整体视觉与交互对齐 PiliPlus。
  Widget _buildTabRow(
    List<String> tabs, {
    bool needIndicator = true,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    // PiliPlus：单 tab 或 needIndicator==false 时无指示器、文字用 onSurface
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
          // 与 PiliPlus 一致：点击 tab 时若非切换中，则回顶对应列表
          void animToTop() {
            if (onTap != null) {
              onTap();
              return;
            }
            // 默认：尝试将当前 PrimaryScrollController 回顶；
            // 相关视频/评论页本身也支持 Bouncing + RefreshIndicator，
            // 这里仅作为与 PiliPlus 对齐的占位，保持行为一致
          }

          if (flag) {
            animToTop();
          } else {
            // TabController.indexIsChanging 由 DefaultTabController 内部处理，
            // 此处简化为直接触发回顶，与 PiliPlus 非切换时回顶一致
            animToTop();
          }
        },
        tabs: tabs
            .map(
              (t) => Tooltip(
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
            // 右侧：发弹幕 + 弹幕开关（PiliPlus 原版）；横屏已在播放器下方有独立弹幕输入栏 _buildDanmakuBar，故横屏 tab 中隐藏
            if (_detail != null && !_isWideScreen) ...[
              Tooltip(
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
              Tooltip(
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

  // ═════════════════════════════════════════
  //  操作区内容（横屏左栏 ListView / 竖屏 header 共用）
  // ═════════════════════════════════════════
  List<Widget> _buildInfoContent() {
    final detail = _detail!;
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    // 是否有「简介 / 标签」内容可展示。
    final hasIntro = detail.desc.isNotEmpty || _tags.isNotEmpty;
    return [
      // ── UP 主 + 关注按钮 ──
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
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
                // 头像 Hero：与 BilibiliUserSpacePage 头部头像同 tag，
                // 点击跳转时圆形头像飞入个人主页。
                // 整页 Hero 包裹期间不包（避免 Hero 嵌套 Hero 断言）。
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
                // 关注按钮（已接入关注接口，显示关注/已关注状态）
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _hasFollowed
                          ? cs.surfaceContainerHighest
                          : cs.primary.withOpacity(0.18),
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
      // ── 标题：紧凑模式点击标题展开/收起「简介 + 标签」，宽屏始终展示 ──
      _buildTitle(cs, detail),
      const SizedBox(height: 8),
      // ── 统计 ──
      _buildStats(cs),
      // ── 简介 + 标签（紧凑模式，与 PiliPlus 一致）：点标题展开后插在统计与
      //    动作栏之间，展开时把操作区（动作栏）和推荐视频向下推 ──
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
      // ── 动作栏：点赞/点踩/投币/收藏/再看/分享 ──
      _buildActions(cs, detail),
      const Divider(height: 24),
      // ── 分P 列表 ──
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
      // ── 简介 + 标签：宽屏始终展示（保持在分P列表之后） ──
      if (_isWideScreen && hasIntro) ...[
        const Divider(height: 24),
        ..._introBlocks(cs, detail),
      ],
    ];
  }

  /// 简介 + 视频标签区块（不含外层间距 / 分隔线，供紧凑 / 宽屏布局复用）。
  /// 参考 PiliPlus：简介文字下方直接跟视频标签，无独立的「简介 / 标签」小标题。
  List<Widget> _introBlocks(ColorScheme cs, BiliVideoDetail detail) {
    return [
      if (detail.desc.isNotEmpty) ...[
        SelectableText(
          // ✅ 查看原文：直接在卡片内原地替换译文为原文（不弹窗），
          //    菜单项再点「查看译文」切回。
          _descShowOriginal || _translatedDesc.isEmpty
              ? detail.desc
              : _translatedDesc,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: cs.onSurfaceVariant,
          ),
          // ✅ 文本选择菜单加「查看原文」（仅当简介已翻译时），
          // 点击原地替换译文/原文，不再弹窗展示。
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final t in _tags) _tagChip(cs, t)],
        ),
    ];
  }

  /// 视频标题：宽屏为纯文本；紧凑模式可点击展开/收起简介与标签。
  /// 长按 / 右键：复制标题 + 已翻译时「查看原文/查看译文」原地切换（同简介）。
  Widget _buildTitle(ColorScheme cs, BiliVideoDetail detail) {
    // 优先展示 AI 翻译后的标题（译文就绪后 _videoTitle 被更新）；
    // 「查看原文」原地切换后展示原标题。
    final translated = _videoTitle.isNotEmpty && _videoTitle != detail.title;
    final displayTitle = _titleShowOriginal
        ? detail.title
        : (_videoTitle.isNotEmpty ? _videoTitle : detail.title);
    final title = GestureDetector(
      // ✅ 长按 / 右键复制标题（同简介逻辑：菜单里「查看原文」原地切换，不弹窗）
      onLongPress: () => _showTitleMenu(translated),
      onSecondaryTapDown: (details) =>
          _showTitleContextMenu(translated, details.globalPosition),
      child: Text(
        displayTitle,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
    );
    if (_isWideScreen) return title;
    return InkWell(
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
  }

  /// 长按标题：毛玻璃底部菜单（复制标题 + 查看原文/查看译文原地切换）。
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

  /// 右键标题：毛玻璃浮层菜单（复制标题 + 查看原文/查看译文原地切换）。
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

  /// 复制标题：已翻译时复制当前展示的标题（原文或译文），否则复制原文。
  void _copyTitle() {
    final detail = _detail;
    if (detail == null) return;
    final text = _titleShowOriginal
        ? detail.title
        : (_videoTitle.isNotEmpty ? _videoTitle : detail.title);
    Clipboard.setData(ClipboardData(text: text));
    _toast('已复制标题');
  }

  /// 视频标签 chip（参考 PiliPlus _buildTags）：
  ///   - bgm 标签去掉「发现」前缀，显示为「♫ BGM：xxx」
  ///   - topic 标签显示为「#xxx」
  ///   - 其余标签原样显示；点击统一跳转搜索该关键词。
  Widget _tagChip(ColorScheme cs, BiliVideoTag tag) {
    final label = switch (tag.type) {
      'bgm' => tag.name.replaceFirst('发现', '♫ BGM：'),
      'topic' => '#${tag.name}',
      _ => tag.name,
    };
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // tag 只是跳转锚点：不写入搜索历史（recordInitialKeyword: false）
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

  // ─── 动作栏：点赞/点踩/投币/收藏/分享（参考 PiliPlus 交互，均带状态反馈） ───
  /// B 站官方图标（从 bilibili.com 视频页提取的 SVG，色随 currentColor）。
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
    // ✅ 每个按钮用 Expanded 均分宽度，icon/label 在按钮内居中，
    // 文字中心对齐到统一网格，避免「按钮宽随 label 长度变 → 文字不齐」。
    return Row(
      children: [
        // 赞：长按一键三连（255ms 后开始三连动画，赞抖动，币/收藏出进度圈）
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
        // 点踩：使用点赞图标倒过来（参考 PiliPlus），点赞/点踩互斥
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
        // 分享：毛玻璃底部菜单（与视频卡片长按菜单同款，参考 PiliPlus）
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

    // 三连动画：币 / 收藏图标外围的进度圈（参考 PiliPlus Arc）
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

    // 三连动画：赞抖动（水平小幅往复抖动）
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

    // ✅ 统一图标区域高度：币/收藏带进度圈 Stack 是 28px，其余按钮图标是
    //    20px，不固定高度会导致 5 个按钮下方的文字不在同一条线上
    //    （币/收藏的文字会低 8px）。统一为 28x28 居中后文字基线对齐。
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
      child = Tooltip(message: tooltip, child: child);
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: child,
    );
  }

  // ─── 播放器区域 ───
  /// 未开始播放时展示封面 + 加载/错误提示；已开始播放后由外层 Stack 的共享
  /// MpvPlayerPage 实例覆盖（此处仅占位，保证页面布局高度正确）。
  /// 窄屏下监听折叠进度：完全折叠时封面退化为标题栏。
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
            // 加载中
            if (!collapsed && (_loading || _loadingPlayUrl))
              const Center(child: LoadingIndicatorM3E()),
            // 错误提示 + 重试（详情 / 解析播放地址失败时）
            if (!collapsed && _error != null && !_loading && !_loadingPlayUrl)
              Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // 错误文本换行后整体可能超出播放器区域，
                  // 用 scaleDown 适配，避免 RenderFlex overflow
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
    // 单 P：优先已翻译标题（_videoTitle 会被 AI 翻译更新）
    return _videoTitle.isNotEmpty ? _videoTitle : detail.title;
  }

  /// 稳定播放历史 ID：`bili_{bvid}_{当前分P cid}`，供播放器保存/恢复进度。
  /// （edl:// 直链的 CDN 主机 / 签名会变化，不能用作历史 ID，见
  ///  PlayHistoryService.saveProgress 的 id 参数。）
  String? get _currentHistoryId {
    final detail = _detail;
    if (detail == null || detail.pages.isEmpty) return null;
    return 'bili_${detail.bvid}_${detail.pages[_pageIndex].cid}';
  }

  /// 顶栏返回按钮：与搜索页一致的毛玻璃圆钮（frosted: true）。
  /// 封面层 / 折叠标题栏共用，保证两个位置的样式与间距完全一致。
  Widget _buildBackButton() {
    final l10n = AppLocalizations.of(context);
    return MorphIconButton(
      icon: Icons.arrow_back,
      tooltip: l10n.commonBackTooltip,
      // 用 maybePop 走 PopScope：整页 Hero 已移除时先重新包裹再 pop，
      // 与系统返回键/鼠标侧键一致，保证返回缩回卡片的动画正常触发
      onTap: () => Navigator.of(context).maybePop(),
      frosted: true,
    );
  }

  /// 折叠态标题栏内容（返回 + ⋮ 更多，供毛玻璃栏复用）。
  Widget _buildCollapsedBarContent() {
    return SizedBox(
      height: _kPlayerCollapsedHeight,
      child: GestureDetector(
        // ✅ 点击折叠顶栏：展开视频播放器并立即播放（参考 PiliPlus）
        behavior: HitTestBehavior.translucent,
        onTap: _expandAndPlay,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _buildBackButton(),
              const Spacer(),
              // ✅ 折叠态右上角 ⋮ 更多（弹幕列表 / 查看笔记 / 写笔记），
              // 与非全屏播放器顶栏一致（液态玻璃菜单）。
              _buildCollapsedMoreMenu(),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 折叠态顶栏的 ⋮ 更多菜单（液态玻璃，MorphIconButton 风格与返回钮一致）。
  /// 内容对齐非全屏播放器顶栏：弹幕列表 / 查看笔记 / 写笔记；
  /// 详情未加载且无弹幕时无可用项，隐藏按钮。
  Widget _buildCollapsedMoreMenu() {
    final hasBvid = (_detail?.bvid ?? '').isNotEmpty;
    final showDanmakuList = _danmaku.itemCount > 0;
    if (!hasBvid && !showDanmakuList) return const SizedBox.shrink();
    return LiquidGlassMenuButton(
      icon: Icons.more_vert,
      tooltip: L10n.current.playerMoreTooltip,
      menuWidth: 220,
      actions: [
        if (showDanmakuList)
          GlassMenuAction(
            icon: Icons.format_list_bulleted_outlined,
            text: L10n.current.playerDanmakuList,
            onTap: _showCollapsedDanmakuList,
          ),
        if (hasBvid)
          GlassMenuAction(
            icon: _cacheChecking
                ? Icons.hourglass_top_outlined
                : _isCached
                ? Icons.download_done_rounded
                : _isCaching
                ? Icons.downloading_rounded
                : Icons.download_rounded,
            text: _cacheChecking
                ? '检查中'
                : _isCached
                ? L10n.current.cacheActionCached
                : _isCaching
                ? L10n.current.cacheActionCaching
                : L10n.current.cacheActionDownload,
            onTap: _manualCache,
          ),
        if (hasBvid)
          GlassMenuAction(
            icon: Icons.article_outlined,
            text: L10n.current.playerViewNotes,
            onTap: _showCollapsedVideoNotes,
          ),
        if (hasBvid)
          GlassMenuAction(
            icon: Icons.edit_note,
            text: L10n.current.playerWriteNote,
            onTap: _writeCollapsedVideoNote,
          ),
      ],
    );
  }

  /// 顶部右上角更多菜单（常驻，含缓存入口，操作区已移除缓存按钮）
  Widget _buildTopMoreMenu() {
    final hasBvid = (_detail?.bvid ?? '').isNotEmpty;
    if (!hasBvid) return const SizedBox.shrink();
    return LiquidGlassMenuButton(
      icon: Icons.more_vert,
      tooltip: L10n.current.playerMoreTooltip,
      menuWidth: 220,
      // 与封面返回钮同款毛玻璃材质（frosted:true）→ 不再是不透明实底
      frosted: true,
      actions: [
        GlassMenuAction(
          icon: _cacheChecking
              ? Icons.hourglass_top_outlined
              : _isCached
              ? Icons.download_done_rounded
              : _isCaching
              ? Icons.downloading_rounded
              : Icons.download_rounded,
          text: _cacheChecking
              ? '检查中'
              : _isCached
              ? L10n.current.cacheActionCached
              : _isCaching
              ? L10n.current.cacheActionCaching
              : L10n.current.cacheActionDownload,
          onTap: _manualCache,
        ),
        GlassMenuAction(
          icon: Icons.article_outlined,
          text: L10n.current.playerViewNotes,
          onTap: _showCollapsedVideoNotes,
        ),
        GlassMenuAction(
          icon: Icons.edit_note,
          text: L10n.current.playerWriteNote,
          onTap: _writeCollapsedVideoNote,
        ),
      ],
    );
  }

  /// 折叠态「弹幕列表」：点击跳转进度用共享播放器实例。
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

  /// 折叠态「查看笔记」。
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

  /// 折叠态「写笔记」（未登录也可写，仅存草稿）。
  void _writeCollapsedVideoNote() {
    final bvid = _detail?.bvid;
    if (bvid == null || bvid.isEmpty) return;
    final aid = BvAv.decode(bvid);
    if (aid == null || aid <= 0) return;
    showNoteEditorPage(context, bvid: bvid, aid: aid, videoTitle: _pageTitle());
  }

  /// 评论区面板「视频进度」：共享播放器实例的当前进度（秒）。
  /// 播放器未就绪（未开始播放）返回 null → 面板按 00:00 处理。
  double? _commentsPanelProgress() {
    final st = _playerKey.currentState;
    if (st == null || !_started) return null;
    return st.player.state.position.inMilliseconds / 1000.0;
  }

  /// 评论区面板「视频截图」：取当前播放器画面（含可选弹幕合成）。
  Future<Uint8List?> _commentsPanelCaptureFrame() async {
    final st = _playerKey.currentState;
    if (st == null) return null;
    return st.captureCurrentFrame();
  }

  /// 点击折叠顶栏：先展开回完整 16:9 播放器，再立即播放；
  /// 未开始播放（封面折叠态）则先开始播放。
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

  /// 平滑展开动画：把折叠值从当前值驱动到 0（完整 16:9 播放器）。
  void _startExpandAnimation() {
    final current = _collapseNotifier.value;
    if (current <= 0) return; // 已展开，无需动画
    _expandStartCollapse = current;
    _expandController
      ..reset()
      ..forward();
  }

  /// 窄屏折叠态毛玻璃标题栏（完整覆盖：播放前的封面折叠时使用，
  /// 与搜索栏一致的毛玻璃观感，参考 ExpressiveSliverAppBar 折叠态模糊）。
  Widget _buildCollapsedFrostedBar() {
    return FrostedPanel(
      blurSigma: 10,
      opacity: 0.75,
      child: _buildCollapsedBarContent(),
    );
  }

  /// 纯封面图（无播放按钮/返回按钮等浮层）。
  /// 供返回转场 shuttle 使用：缩回卡片时只渲染图片部分，
  /// 配合外层 FittedBox(BoxFit.cover) 保持宽高比、按需裁剪，
  /// 而不是把内容压缩进飞行矩形。
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
      ),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(child: fallbackIcon),
    );
  }

  /// 播放前的封面层：Hero 动画 + 封面图 + 右下角播放按钮，点击开始播放（带 ripple）。
  /// 窄屏下完全折叠（[collapsed]）时退化为毛玻璃标题栏（返回 + 标题）。
  Widget _buildCover({bool collapsed = false}) {
    final heroTag = widget.heroTag;
    final cs = Theme.of(context).colorScheme;

    final coverImage = _buildCoverImage();

    // 窄屏折叠为毛玻璃标题栏：保留封面作模糊底，毛玻璃栏覆盖其上。
    // （只返回毛玻璃栏时背面是纯色页面背景，BackdropFilter 没有可模糊的
    //  内容，看起来就没有毛玻璃效果；参考已播放态折叠栏覆盖在视频上）
    if (collapsed) {
      return Stack(
        fit: StackFit.expand,
        children: [coverImage, _buildCollapsedFrostedBar()],
      );
    }

    Widget coverWidget = coverImage;
    // 经典模式（关闭「Hero 转场背景模糊」或宽屏推荐视频入口）：封面 Hero
    // 与来源卡片封面同 tag，点击时经典封面飞入（同样非线性飞行）；
    // wideClassic 仅在宽屏生效，竖屏推荐视频仍走整页 Hero 放大。
    // 整页 Hero 包裹期间不包（避免 Hero 嵌套 Hero 断言）。
    if (heroTag != null &&
        !_zoomHeroBlocksInnerHeroes &&
        (!SettingsService.heroTransitionBlurEnabled ||
            (widget.wideClassic && _isWideScreen))) {
      coverWidget = Hero(
        tag: heroTag,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: coverWidget,
      );
    }

    // 点击封面开始播放：整层 Material + InkWell 提供水波纹
    return ColoredBox(
      // 播放器区域与其它 widget 同主题色，去掉黑色背景
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
          // 右下角「小电视」播放按钮：Hero 飞入结束后才显示，完全透明无背景
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
          // 顶部返回按钮（播放前也能返回）——与折叠标题栏同款毛玻璃圆钮、
          // 同位置（外层 SafeArea 已避开状态栏，这里不再叠加 SafeArea）
          Positioned(
            top: 0,
            left: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
              child: _buildBackButton(),
            ),
          ),
          // 右上角「更多」(三个点)：未播放 / 显示封面时也展示，与播放态顶栏
          // 的更多菜单一致（缓存 / 弹幕列表 / 笔记），保证封面态可操作。
          // 用固定 40×40 预留位：bvid 未加载时 _buildTopMoreMenu 返回空，
          // 这里仍占住右上角，避免 bvid 到达时三点「凭空出现 / 位置跳动」。
          Positioned(
            top: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
              child: SizedBox(
                width: 40,
                height: 40,
                child: _buildTopMoreMenu(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 信息区部件 ───
  Widget _faceFallback(ColorScheme cs) {
    return Container(
      width: 40,
      height: 40,
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.person, color: cs.onSurfaceVariant, size: 24),
    );
  }

  Widget _buildStats(ColorScheme cs) {
    // 非宽屏（紧凑）模式：播放量 / 弹幕 / 发布时间 / 正在看人数
    // （参考 bilibili 视频详情页的信息行）。
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

/// 三连进度圈（移植自 PiliPlus custom_arc.dart）：从顶部开始、
/// 顺时针/逆时针随 [progress] 增长的圆弧，progress=0 时不绘制。
class _TripleArc extends StatelessWidget {
  final double progress; // 可为负（负为逆时针）
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
