// lib/screens/bilibili_live_room_page.dart
//
// 直播间页（参考 PiliPlus live_room 重做）：
//   - 播放：getRoomPlayInfo（WBI 签名）候选线路自动回退，支持清晰度 /
//     线路（CDN·编码）手动切换，播放失败自动重取地址
//   - 弹幕：B 站直播 WS 协议（弹幕 / 进场 / 礼物 / 上舰 / SuperChat /
//     人气心跳），视频上覆盖滚动弹幕（复用视频弹幕引擎与设置面板），
//     侧边 / 底部聊天面板可发弹幕、点赞连击、发表情
//   - 房间：关注 / 取关主播、观看数实时更新、高能观众数、开播时长
//   - 布局：宽屏左视频右聊天；窄屏视频 + 信息卡 + 聊天；全屏为
//     点按呼出控制条 + SuperChat 浮卡
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_interaction_service.dart';
import 'package:naviflash/services/bilibili_live_danmaku_service.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/danmaku/danmaku_controller.dart';
import 'package:naviflash/widgets/danmaku/danmaku_model.dart';
import 'package:naviflash/widgets/danmaku/danmaku_settings_sheet.dart';
import 'package:naviflash/widgets/danmaku/danmaku_view.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart' show FrostedSheet;
import 'package:naviflash/widgets/liquid_dom_menu.dart';
import 'package:naviflash/widgets/live_chat_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'browser_page.dart';

/// 直播流请求头（与 B 站网页端一致，部分 CDN 校验 Referer / UA）。
const Map<String, String> _mediaHeaders = {
  'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Referer': 'https://live.bilibili.com/',
};

/// 弹幕覆盖层开关的本地记忆键。
const String _overlayDanmakuPref = 'live_danmaku_overlay_v1';

/// 全屏控制条自动隐藏延时。
const Duration _autoHideDelay = Duration(seconds: 4);

class BilibiliLiveRoomPage extends StatefulWidget {
  /// 房间号（长号或短号，进入后由接口换成长号）。
  final int roomId;

  /// 卡片带来的初始占位信息（详情接口返回前先展示）。
  final String title;
  final String uname;
  final String face;
  final String cover;

  const BilibiliLiveRoomPage({
    super.key,
    required this.roomId,
    this.title = '',
    this.uname = '',
    this.face = '',
    this.cover = '',
  });

  @override
  State<BilibiliLiveRoomPage> createState() => _BilibiliLiveRoomPageState();
}

class _BilibiliLiveRoomPageState extends State<BilibiliLiveRoomPage> {
  late final Player _player;
  late final VideoController _controller;

  /// 弹幕覆盖层引擎（与视频弹幕共用设置与渲染组件）。
  late final DanmakuController _danmaku;

  LiveRoomDetail? _detail;

  /// ROOM_CHANGE 推送的新标题（覆盖详情里的标题）。
  String? _titleOverride;

  /// 当前清晰度（0 = 跟随服务端默认档）。
  int _qn = 0;

  /// 本轮取回的候选线路与正在尝试的下标。
  List<LiveStreamOption> _candidates = [];
  int _candidateIndex = 0;

  /// 取地址失败后是否已经自动重取过一次（防死循环）。
  bool _refetched = false;

  bool _fetchingPlay = false;
  bool _buffering = true;
  bool _playing = false;
  bool _muted = false;
  bool _isPortrait = false;
  bool _fullscreen = false;
  bool _disposed = false;
  String? _error;

  /// 服务端回报的可选清晰度列表。
  List<int> _acceptQn = [];

  // ── 弹幕连接 ──
  BilibiliLiveDanmakuClient? _dmClient;
  StreamSubscription<LiveDanmuEvent>? _dmSub;
  bool _showDanmaku = true;

  /// 初始 SuperChat（聊天面板展示用）。
  List<LiveSuperChatMsg> _scList = [];

  /// 全屏时底部浮出的最新 SC。
  LiveSuperChatMsg? _fsSC;
  Timer? _fsSCTimer;

  // ── 房间实时数据 ──
  int _popularity = 0;
  String _watchedText = '';
  int _onlineRank = 0;
  Timer? _liveTimeTicker;

  // ── 关注 ──
  bool? _following;
  int _fans = -1;
  bool _followBusy = false;

  // ── 全屏控制条自动隐藏 ──
  bool _controlsVisible = true;
  Timer? _hideTimer;

  /// 聊天面板在窗口 / 全屏两种布局间移动，靠 GlobalKey 保活状态。
  final GlobalKey _chatKey = GlobalKey();

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _bufferSub;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<bool>? _completedSub;

  LiveRoomDetail get _info {
    return _detail ??
        LiveRoomDetail(
          roomId: widget.roomId,
          uid: 0,
          title: widget.title,
          cover: widget.cover,
          keyframe: '',
          uname: widget.uname,
          face: widget.face,
          liveStatus: 1,
          liveStartTime: 0,
          watchedText: '',
          fansNum: -1,
          areaName: '',
          parentAreaName: '',
        );
  }

  String get _displayTitle {
    final t = _titleOverride ?? _info.title;
    return t;
  }

  bool get _loggedIn => BilibiliAccountService.instance.isLoggedIn;

  @override
  void initState() {
    super.initState();
    debugPrint('[AutoTest] LiveRoom initState start');
    _player = Player();
    debugPrint('[AutoTest] player created');
    // 关掉 mpv 原生 OSD（调音量等操作会弹出 "Volume: 100%" 之类的浮层）
    final platform = _player.platform;
    if (platform is NativePlayer) {
      unawaited(platform.setProperty('osd-level', '0'));
    }
    _controller = VideoController(_player);
    _danmaku = DanmakuController()
      ..restoreSettings().then((_) {
        // 直播覆盖层只受自己的开关控制，不继承视频弹幕的启停档位
        _danmaku.enabled = true;
        _danmaku.danmakuWeight = 0;
        if (_playing) _danmaku.play();
      });
    _loadOverlayPref();
    _playingSub = _player.stream.playing.listen((v) {
      if (_disposed) return;
      setState(() {
        _playing = v;
        if (v) _error = null;
      });
      v ? _danmaku.play() : _danmaku.pause();
    });
    _bufferSub = _player.stream.buffering.listen((v) {
      if (_disposed) return;
      setState(() => _buffering = v);
    });
    _errorSub = _player.stream.error.listen((_) => _onPlaybackError());
    _completedSub = _player.stream.completed.listen((completed) {
      // 直播流不应「播完」，一般意味着断流：自动重取地址续播
      if (completed && !_disposed) _reloadPlay(resetCandidates: true);
    });
    _init();
  }

  @override
  void dispose() {
    _disposed = true;
    _playingSub?.cancel();
    _bufferSub?.cancel();
    _errorSub?.cancel();
    _completedSub?.cancel();
    _dmSub?.cancel();
    _dmClient?.dispose();
    _liveTimeTicker?.cancel();
    _fsSCTimer?.cancel();
    _hideTimer?.cancel();
    _danmaku.dispose();
    _player.dispose();
    if (_fullscreen) _setSystemFullscreen(false);
    super.dispose();
  }

  Future<void> _loadOverlayPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed) return;
      setState(() {
        _showDanmaku = prefs.getBool(_overlayDanmakuPref) ?? true;
      });
    } catch (_) {}
  }

  Future<void> _toggleOverlayDanmaku(bool value) async {
    setState(() => _showDanmaku = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_overlayDanmakuPref, value);
    } catch (_) {}
  }

  Future<void> _init() async {
    // 进房上报（历史记录），尽力而为
    BilibiliLiveService.reportRoomEntry(widget.roomId);
    _loadDetail();
    await _reloadPlay(resetCandidates: true);
  }

  /// 房间信息（失败不打断播放，仅静默保留卡片占位数据）。
  Future<void> _loadDetail() async {
    final (:detail, :err) = await BilibiliLiveService.fetchRoomDetail(
      widget.roomId,
    );
    if (_disposed || detail == null) {
      if (err != null) debugPrint('[LiveRoom] 房间信息获取失败：$err');
      return;
    }
    setState(() {
      _detail = detail;
      _watchedText = detail.watchedText;
      // 详情确认未开播时停掉播放尝试，避免一直转圈
      if (!detail.isLiving && _fetchingPlay) _error ??= '当前直播间未开播';
    });
    _loadFollowState(detail.uid);
    _startLiveTimeTicker();
  }

  /// 主播关注状态 / 粉丝数（登录态才有意义）。
  Future<void> _loadFollowState(int uid) async {
    if (uid <= 0 || !_loggedIn) return;
    final card = await BilibiliLiveService.fetchAnchorCard(uid);
    if (_disposed || card == null) return;
    setState(() {
      _following = card.following;
      _fans = card.fans;
    });
  }

  /// 开播时长每 30s 刷新一次。
  void _startLiveTimeTicker() {
    if ((_detail?.isLiving ?? false) && _liveTimeTicker == null) {
      _liveTimeTicker = Timer.periodic(
        const Duration(seconds: 30),
        (_) {
          if (mounted && !_disposed) setState(() {});
        },
      );
    }
  }

  /// 取播放地址并开播（[resetCandidates] 清空上次的候选线路）。
  Future<void> _reloadPlay({bool resetCandidates = false}) async {
    if (_disposed || _fetchingPlay) return;
    setState(() {
      _fetchingPlay = true;
      if (resetCandidates) {
        _candidates = [];
        _candidateIndex = 0;
        _refetched = false;
      }
    });
    final (:info, :err) = await BilibiliLiveService.fetchPlayInfo(
      widget.roomId,
      qn: _qn,
    );
    debugPrint('[AutoTest] playinfo fetched ok=${info != null} err=$err');
    if (_disposed) return;

    if (info == null) {
      setState(() {
        _fetchingPlay = false;
        // 已经在播就只弹提示，不覆盖画面
        if (_candidates.isEmpty || !_playing) _error = err;
      });
      return;
    }
    if (info.liveStatus != 1) {
      setState(() {
        _fetchingPlay = false;
        _error = '当前直播间未开播';
      });
      return;
    }
    _candidates = info.streams;
    _candidateIndex = 0;
    // 注意：错误触发的自动重取（resetCandidates=false）不重置 _refetched，
    // 否则「报错→重取→再报错」会绕过兜底无限循环
    _isPortrait = info.isPortrait;
    _acceptQn = info.acceptQn;
    setState(() {
      _fetchingPlay = false;
      _error = null;
      _buffering = true;
    });
    _connectDanmaku(info.roomId);
    _openCurrent();
  }

  /// 接入弹幕流（同一房间只建一次连接，断线由客户端自动重连）。
  void _connectDanmaku(int realRoomId) {
    if (_dmClient != null || _disposed) return;
    final client = BilibiliLiveDanmakuClient(
      roomId: realRoomId,
      selfUid: BilibiliAccountService.instance.mid,
    );
    _dmClient = client;
    _dmSub = client.events.listen(_onDanmuEvent);
    // 让聊天面板立刻拿到真实事件流（否则要等下一次 setState）
    setState(() {});
    client.start();
    BilibiliLiveService.fetchSuperChat(realRoomId).then((list) {
      if (_disposed || list.isEmpty) return;
      setState(() => _scList = list);
    });
  }

  /// 弹幕事件分发：覆盖层只吃弹幕，其余进聊天面板与房间状态。
  void _onDanmuEvent(LiveDanmuEvent e) {
    if (_disposed) return;
    switch (e) {
      case LiveDmEvent dm:
        // 暂停时不喂弹幕，避免恢复后弹幕扎堆涌出
        if (_showDanmaku && _playing && dm.text.isNotEmpty) {
          _danmaku.addItem(
            DanmakuItem(
              time: 0,
              mode: DanmakuMode.scrollRightToLeft,
              fontSize: 25,
              color: dm.color,
              content: dm.text,
            ),
          );
        }
      case LiveWatchedEvent w:
        setState(() => _watchedText = w.textLarge);
      case LiveOnlineRankEvent r:
        setState(() => _onlineRank = r.count);
      case LiveRoomChangeEvent c:
        setState(() => _titleOverride = c.title);
      case LivePopularityEvent p:
        setState(() => _popularity = p.count);
      case LiveSuperChatEvent sc:
        final msg = LiveSuperChatMsg.fromData({
          'id': sc.id,
          'uid': sc.uid,
          'price': sc.price,
          'message': sc.message,
          'background_color': sc.topColor.toARGB32() & 0xFFFFFF,
          'background_bottom_color': sc.bottomColor.toARGB32() & 0xFFFFFF,
          'end_time': sc.endTime,
          'user_info': {'uname': sc.uname, 'face': sc.face},
        });
        if (msg == null) break;
        setState(() {
          _scList = [msg, ..._scList.take(30)];
          if (_fullscreen) _fsSC = msg;
        });
        if (_fullscreen) {
          _fsSCTimer?.cancel();
          _fsSCTimer = Timer(const Duration(seconds: 10), () {
            if (mounted && !_disposed) setState(() => _fsSC = null);
          });
        }
      case LiveSuperChatDeleteEvent del:
        if (_scList.any((s) => del.ids.contains(s.id)) ||
            _fsSC != null && del.ids.contains(_fsSC!.id)) {
          setState(() {
            _scList.removeWhere((s) => del.ids.contains(s.id));
            if (_fsSC != null && del.ids.contains(_fsSC!.id)) _fsSC = null;
          });
        }
      case LiveStatusEvent s:
        if (!s.living && mounted && !_disposed) {
          showAppToast(context, '主播已下播', error: true);
        }
      default:
        break;
    }
  }

  void _openCurrent() {
    if (_disposed || _candidates.isEmpty) return;
    if (_candidateIndex >= _candidates.length) {
      _onPlaybackError();
      return;
    }
    final option = _candidates[_candidateIndex];
    _player.open(
      Media(option.url, httpHeaders: _mediaHeaders),
      // 直播从 0 开始，不展示进度条
      play: true,
    );
  }

  /// 播放报错：优先切同档的下一条线路，取不到就整体重取地址。
  Future<void> _onPlaybackError() async {
    if (_disposed) return;
    if (_candidateIndex + 1 < _candidates.length) {
      _candidateIndex++;
      _openCurrent();
      return;
    }
    if (!_refetched) {
      _refetched = true;
      _candidates = [];
      _candidateIndex = 0;
      await _reloadPlay();
      return;
    }
    if (mounted) {
      setState(() {
        _error = _error ?? '播放失败，请重试';
      });
    }
  }

  Future<void> _switchQn(int qn) async {
    if (qn == _qn) return;
    setState(() {
      _qn = qn;
      _candidates = [];
      _candidateIndex = 0;
      _refetched = false;
    });
    await _reloadPlay();
  }

  /// 手动切线路（同清晰度内换 CDN / 编码）。
  void _switchLine(int index) {
    if (index < 0 || index >= _candidates.length || index == _candidateIndex) {
      return;
    }
    setState(() {
      _candidateIndex = index;
      _refetched = false;
      _buffering = true;
    });
    _openCurrent();
  }

  /// 线路选择面板（按当前清晰度优先排列）。
  Future<void> _showLineSheet() async {
    if (_candidates.isEmpty) return;
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: cs.surfaceContainerHigh,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                '播放线路（${BilibiliLiveService.qualityLabel(_currentQn)}）',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            for (var i = 0; i < _candidates.length; i++)
              ListTile(
                dense: true,
                leading: Icon(
                  i == _candidateIndex
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20,
                  color: i == _candidateIndex ? cs.primary : cs.onSurfaceVariant,
                ),
                title: Text(
                  '${_candidates[i].formatName} · ${_candidates[i].codecName} · 线路${i + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    color: i == _candidateIndex ? cs.primary : cs.onSurface,
                    fontWeight: i == _candidateIndex
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  _hostLabel(_candidates[i].url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  if (_candidates[i].qn > 0 && _candidates[i].qn != _qn) {
                    _switchQn(_candidates[i].qn);
                  } else {
                    _switchLine(i);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  String _hostLabel(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    return host.isEmpty ? url : host;
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _player.setVolume(_muted ? 0 : 100);
  }

  Future<void> _toggleFollow() async {
    final uid = _detail?.uid ?? 0;
    if (uid <= 0 || _followBusy) return;
    if (!_loggedIn) {
      _openLogin();
      return;
    }
    final target = !(_following ?? false);
    setState(() => _followBusy = true);
    final r = await BilibiliInteractionService.followUser(
      mid: uid,
      act: target ? 1 : 2,
    );
    if (_disposed) return;
    setState(() => _followBusy = false);
    if (r.ok) {
      setState(() {
        _following = target;
        if (_fans > 0) _fans += target ? 1 : -1;
      });
      if (mounted) showAppToast(context, target ? '关注成功' : '已取消关注');
    } else if (mounted) {
      showAppToast(context, r.message, error: true);
    }
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BilibiliLoginScreen()),
    );
  }

  void _copyLink() {
    Clipboard.setData(
      ClipboardData(text: 'https://live.bilibili.com/${_info.roomId}'),
    );
    if (mounted) showAppToast(context, '已复制直播间链接');
  }

  // ── 全屏（桌面走 windowManager，移动端走 SystemChrome 沉浸式 + 横屏）──

  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  Future<void> _setSystemFullscreen(bool value) async {
    if (_isDesktop) {
      await windowManager.setFullScreen(value);
      return;
    }
    if (value) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }

  Future<void> _toggleFullscreen() async {
    final next = !_fullscreen;
    _hideTimer?.cancel();
    if (next) {
      _controlsVisible = true;
      _scheduleAutoHide();
    } else {
      _controlsVisible = true;
    }
    await _setSystemFullscreen(next);
    if (!mounted || _disposed) return;
    setState(() => _fullscreen = next);
  }

  void _onVideoTap() {
    if (!_fullscreen) return;
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleAutoHide();
  }

  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_autoHideDelay, () {
      if (mounted && !_disposed && _fullscreen && _controlsVisible) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // PiliPlus 同款：直播间整页强制深色主题（背景图上文字才有可读性）
    final outerTheme = Theme.of(context);
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFB7299),
          brightness: Brightness.dark,
        ),
        fontFamily: outerTheme.textTheme.bodyMedium?.fontFamily,
      ),
      child: Builder(builder: _buildPage),
    );
  }

  Widget _buildPage(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_fullscreen) {
      final chatPanel = _buildChatPanel();
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onVideoTap,
              child: _buildPlayerArea(),
            ),
            if (_controlsVisible) ...[
              _buildFullscreenTopBar(cs),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildControlBar(cs, fullscreen: true),
              ),
            ],
            // 全屏时聊天面板挂到画面外保活，退出全屏聊天记录不丢
            Positioned.fill(
              child: IgnorePointer(
                child: Offstage(child: chatPanel),
              ),
            ),
            if (_fsSC != null) _buildFsSuperChat(cs),
          ],
        ),
      );
    }

    final chatPanel = _buildChatPanel();
    final body = SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          if (wide) {
            // 宽屏：左视频右聊天（PiliPlus 横屏布局），聊天侧半透明衬底
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildPlayerArea()),
                Container(
                  width: 360,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer.withValues(alpha: 0.85),
                    border: Border(
                      left: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  child: chatPanel,
                ),
              ],
            );
          }
          // 窄屏：视频 + 信息卡 + 聊天
          return Column(
            children: [
              _buildPlayerArea(aspectBounded: true),
              _buildInfoCard(cs),
              Expanded(child: chatPanel),
            ],
          );
        },
      ),
    );

    // PiliPlus 同款：房间背景图铺满整页，Scaffold 透明垫在上面
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: _buildRoomBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(cs),
          body: body,
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme cs) {
    final info = _info;
    final face = info.face.isNotEmpty ? info.face : widget.face;
    return AppBar(
      // 背景图从 AppBar 底下透出来
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: face.isEmpty
                ? Container(
                    width: 32,
                    height: 32,
                    color: cs.surfaceContainerHighest,
                    child: Icon(
                      Icons.person,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  )
                : Image(
                    image: CachedImageProvider(
                      face,
                      headers: NetworkSettingsService
                              .instance.apiHeaders.isEmpty
                          ? null
                          : NetworkSettingsService.instance.apiHeaders,
                    ),
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 32,
                      height: 32,
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        info.uname.isNotEmpty ? info.uname : '直播间',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    if (_loggedIn && (info.uid > 0)) ...[
                      const SizedBox(width: 10),
                      _followButton(cs),
                    ],
                  ],
                ),
                Text(
                  _appBarMeta(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: '刷新',
          onPressed: () {
            _loadDetail();
            _reloadPlay(resetCandidates: true);
          },
        ),
        IconButton(
          icon: const Icon(Icons.copy_outlined),
          tooltip: '复制链接',
          onPressed: _copyLink,
        ),
        IconButton(
          icon: const Icon(Icons.open_in_browser),
          tooltip: '在浏览器打开',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BrowserPage(
                initialUrl: 'https://live.bilibili.com/${_info.roomId}',
                title: _displayTitle.isEmpty ? '直播间' : _displayTitle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _followButton(ColorScheme cs) {
    final following = _following ?? false;
    return SizedBox(
      height: 26,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: following
              ? cs.surfaceContainerHighest
              : cs.primary.withValues(alpha: 0.9),
          foregroundColor: following ? cs.onSurfaceVariant : cs.onPrimary,
          textStyle: const TextStyle(fontSize: 12),
        ),
        onPressed: _followBusy ? null : _toggleFollow,
        child: _followBusy
            ? SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(following ? '已关注' : '关注'),
      ),
    );
  }

  String _appBarMeta() {
    final parts = <String>[];
    if (_watchedText.isNotEmpty) {
      parts.add(_watchedText);
    } else if (_popularity > 0) {
      parts.add('${_fmtCount(_popularity)}人气');
    }
    if (_onlineRank > 0) parts.add('高能 ${_fmtCount(_onlineRank)}');
    final liveTime = _liveTimeText();
    if (liveTime != null) parts.add(liveTime);
    if (_fans > 0) parts.add('${_fmtCount(_fans)}粉丝');
    if (parts.isEmpty) return '房间号 ${_info.roomId}';
    return parts.join(' · ');
  }

  String? _liveTimeText() {
    final start = _detail?.liveStartTime ?? 0;
    if (start <= 0 || !(_detail?.isLiving ?? false)) return null;
    final now = DateTime.now();
    final started = DateTime.fromMillisecondsSinceEpoch(start * 1000);
    var minutes = now.difference(started).inMinutes;
    if (minutes < 1) return '刚刚开播';
    if (minutes < 60) return '已开播 $minutes 分钟';
    final h = minutes ~/ 60;
    minutes %= 60;
    return minutes == 0 ? '已开播 $h 小时' : '已开播 $h 小时 $minutes 分';
  }

  String _fmtCount(int v) {
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(1)}万';
    return v.toString();
  }

  // ════════════════════════════════════════
  //  播放器区域（视频 + 弹幕覆盖层 + 状态覆盖 + 控制条）
  // ════════════════════════════════════════

  Widget _buildPlayerArea({bool aspectBounded = false}) {
    final cs = Theme.of(context).colorScheme;
    final aspect = _isPortrait ? 9.0 / 16.0 : 16.0 / 9.0;

    Widget area = GestureDetector(
      behavior: HitTestBehavior.opaque,
      // 右键菜单：色彩调节 / 播放信息 / 对齐宽高比（视频播放页同款）
      onSecondaryTapDown: (d) => _showLiveContextMenu(d.globalPosition),
      child: Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 视频层（错误 / 未开播时不渲染，露出底下的占位）
          if (_error == null && _candidates.isNotEmpty)
            Video(controller: _controller, fit: BoxFit.contain),

          // 未开播 / 风控等占位（带封面底图）
          if (_error != null || _candidates.isEmpty) _buildPlaceholder(cs),

          // 弹幕覆盖层
          if (_error == null && _candidates.isNotEmpty)
            Visibility(
              visible: _showDanmaku,
              maintainState: true,
              maintainAnimation: true,
              child: IgnorePointer(
                child: DanmakuView(controller: _danmaku),
              ),
            ),

          // 加载中
          if (_error == null && (_fetchingPlay || _buffering))
            const Center(
              child: SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white70,
                ),
              ),
            ),

          // 底部控制条（必须 Positioned，否则会被 StackFit.expand 撑满全屏）
          if (_error == null && _candidates.isNotEmpty && !_fullscreen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildControlBar(cs, fullscreen: false),
            ),

          // 左上 LIVE 徽标 + 人气
          if (_error == null && (_playing || _buffering))
            Positioned(left: 10, top: 10, child: _liveBadge()),
        ],
      ),
      ),
    );

    if (aspectBounded && !_fullscreen) {
      area = AspectRatio(aspectRatio: aspect, child: area);
    }
    return area;
  }

  /// 错误 / 未开播占位：封面做底，配文案与重试。
  Widget _buildPlaceholder(ColorScheme cs) {
    final cover = _info.keyframe.isNotEmpty ? _info.keyframe : _info.cover;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (cover.isNotEmpty)
          Image(
            image: CachedImageProvider(
              cover,
              headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                  ? null
                  : NetworkSettingsService.instance.apiHeaders,
            ),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        Container(color: Colors.black.withValues(alpha: 0.55)),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _error == null || _error!.contains('未开播')
                    ? Icons.nightlight_outlined
                    : Icons.error_outline,
                size: 40,
                color: Colors.white70,
              ),
              const SizedBox(height: 10),
              Text(
                _error ?? '正在获取直播地址…',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                FilledButton.tonal(
                  onPressed: () => _reloadPlay(resetCandidates: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('重试'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 底部控制条：静音 / 弹幕开关 / 弹幕设置 / 线路 / 清晰度 / 全屏。
  /// （直播流不能暂停，不放播放/暂停键）
  Widget _buildControlBar(ColorScheme cs, {required bool fullscreen}) {
    final barColor = Colors.white.withValues(alpha: 0.9);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.55),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 2),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _muted ? Icons.volume_off : Icons.volume_up,
              color: barColor,
              size: 20,
            ),
            tooltip: _muted ? '取消静音' : '静音',
            onPressed: _toggleMute,
          ),
          const Spacer(),
          // 弹幕开关（全屏时输入条不在场，这里兜底）
          IconButton(
            icon: Icon(
              _showDanmaku ? Icons.subtitles : Icons.subtitles_off_outlined,
              color: barColor,
              size: 20,
            ),
            tooltip: _showDanmaku ? '关闭弹幕' : '开启弹幕',
            onPressed: () => _toggleOverlayDanmaku(!_showDanmaku),
          ),
          IconButton(
            icon: Icon(Icons.tune, color: barColor, size: 20),
            tooltip: '弹幕设置',
            onPressed: () => showDanmakuSettingsSheet(context, _danmaku),
          ),
          IconButton(
            icon: Icon(Icons.route, color: barColor, size: 20),
            tooltip: '切换线路',
            onPressed: _showLineSheet,
          ),
          // 画质菜单
          if (_candidates.isNotEmpty)
            PopupMenuButton<int>(
              tooltip: '切换清晰度',
              color: cs.surfaceContainerHigh,
              onSelected: _switchQn,
              itemBuilder: (_) {
                final options = _currentAcceptQn();
                return [
                  for (final qn in options)
                    PopupMenuItem(
                      value: qn,
                      height: 40,
                      child: Row(
                        children: [
                          if (qn == _currentQn)
                            Icon(Icons.check, size: 16, color: cs.primary)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 4),
                          Text(
                            BilibiliLiveService.qualityLabel(qn),
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  qn == _currentQn ? cs.primary : cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                ];
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: Text(
                  BilibiliLiveService.qualityLabel(_currentQn),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: barColor,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: barColor,
            ),
            tooltip: fullscreen ? '退出全屏' : '全屏',
            onPressed: _toggleFullscreen,
          ),
        ],
      ),
    );
  }

  /// 全屏顶栏：返回 + 标题 + 观看/人气。
  Widget _buildFullscreenTopBar(ColorScheme cs) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 18),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: '退出全屏',
              onPressed: _toggleFullscreen,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayTitle.isEmpty ? '直播间' : _displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _appBarMeta(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 全屏时底部左侧浮出的 SuperChat 卡片。
  Widget _buildFsSuperChat(ColorScheme cs) {
    final sc = _fsSC!;
    return Positioned(
      left: 16,
      bottom: 64,
      width: 300,
      child: GestureDetector(
        onTap: () {
          _fsSCTimer?.cancel();
          setState(() => _fsSC = null);
        },
        child: Container(
          decoration: BoxDecoration(
            color: sc.bottomColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sc.topColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        sc.uname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '¥${_fmtPrice(sc.price)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  sc.message,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtPrice(num price) {
    if (price == price.roundToDouble()) return price.toInt().toString();
    return price.toString();
  }

  Widget _liveBadge() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFB7299),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 10,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        if (_popularity > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${_fmtCount(_popularity)}人气',
              style: const TextStyle(
                fontSize: 10,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ════════════════════════════════════════
  //  右键菜单（视频播放页同款：毛玻璃菜单 + 圆形收放动画）
  // ════════════════════════════════════════

  void _showLiveContextMenu(Offset globalPosition) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    const menuWidth = 220.0;
    final items = <_LiveMenuData>[
      _LiveMenuData(Icons.tune, L10n.current.playerColorAdjust, () {
        _showColorAdjustPanel();
      }),
      _LiveMenuData(Icons.info_outline, L10n.current.playerStats, () {
        _showStatsDialog();
      }),
      // 桌面端：把窗口比例对齐到视频，消除黑边
      if (_isDesktop)
        _LiveMenuData(Icons.aspect_ratio, L10n.current.playerAlignAspectRatio,
            () {
          _alignWindowToVideoAspectRatio();
        }),
      _LiveMenuData(Icons.copy_rounded, '复制直播间链接', _copyLink),
    ];
    final menuHeight = items.length * 44.0 + (items.length - 1) * 1.0 + 12.0;

    showLiquidDomMenu(
      context,
      globalPosition: globalPosition,
      menuWidth: menuWidth,
      menuHeight: menuHeight,
      menuRadius: 18.0,
      originSize: null,
      builder: (menuContext, close) {
        return Material(
          color: Colors.transparent,
          child: Container(
            width: menuWidth,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color:
                          colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        close();
                        items[i].onTap();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              items[i].icon,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              items[i].text,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// 色彩调节（mpv 属性：亮度 / 对比度 / 饱和度 / 色相 / 伽马）。
  Future<void> _showColorAdjustPanel() async {
    final platform = _player.platform;
    if (platform is! NativePlayer) {
      if (mounted) {
        showAppToast(context, L10n.current.playerColorUnavailable, error: true);
      }
      return;
    }
    const keys = ['brightness', 'contrast', 'saturation', 'hue', 'gamma'];
    final values = <String, double>{};
    for (final k in keys) {
      try {
        final v = await platform.getProperty(k);
        values[k] = double.tryParse(v) ?? 0.0;
      } catch (_) {
        values[k] = 0.0;
      }
    }
    if (!mounted) return;

    final labels = <String, String>{
      'brightness': L10n.current.playerColorBrightness,
      'contrast': L10n.current.playerColorContrast,
      'saturation': L10n.current.playerColorSaturation,
      'hue': L10n.current.playerColorHue,
      'gamma': L10n.current.playerColorGamma,
    };

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FrostedSheet(
        child: StatefulBuilder(
          builder: (ctx, setSheetState) {
            void apply(String key, double v) {
              values[key] = v;
              platform.setProperty(key, '${v.round()}');
              setSheetState(() {});
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          L10n.current.playerColorAdjust,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            for (final k in keys) {
                              values[k] = 0.0;
                              platform.setProperty(k, '0');
                            }
                            setSheetState(() {});
                          },
                          child: Text(L10n.current.playerColorReset),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    for (final k in keys) ...[
                      Row(
                        children: [
                          SizedBox(
                            width: 52,
                            child: Text(
                              labels[k]!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: values[k]!,
                              min: -100,
                              max: 100,
                              onChanged: (v) => apply(k, v),
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: Text(
                              '${values[k]!.round()}',
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 播放信息弹窗（打开时实时取 mpv 属性）。
  Future<void> _showStatsDialog() async {
    final entries = await _collectStats();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, size: 18),
            const SizedBox(width: 8),
            Text(
              L10n.current.playerStats,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (k, v) in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text(
                          k,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(v, style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<String?> _mpvProp(String name) async {
    final p = _player.platform;
    if (p is! NativePlayer) return null;
    try {
      return await p.getProperty(name);
    } catch (_) {
      return null;
    }
  }

  Future<List<(String, String)>> _collectStats() async {
    final l10n = L10n.current;
    final w = _player.state.width ?? 0;
    final h = _player.state.height ?? 0;
    final videoCodec = (await _mpvProp('video-codec')) ?? '';
    final audioCodec = (await _mpvProp('audio-codec-name')) ?? '';
    final fps =
        double.tryParse((await _mpvProp('container-fps')) ?? '') ?? 0;
    // mpv 的 video-bitrate 单位是 kbps，cache-speed 单位是 B/s
    final bitrateKbps =
        double.tryParse((await _mpvProp('video-bitrate')) ?? '') ?? 0;
    final cacheSpeed =
        double.tryParse((await _mpvProp('cache-speed')) ?? '') ?? 0;
    final hwdec = (await _mpvProp('hwdec-current')) ?? '';
    var line = '—';
    if (_candidateIndex < _candidates.length) {
      line = '${_candidates[_candidateIndex].formatName}'
          '·${_candidates[_candidateIndex].codecName} · '
          '${_hostLabel(_candidates[_candidateIndex].url)}';
    }
    return [
      (l10n.playerStatResolution, (w > 0 && h > 0) ? '$w×$h' : '—'),
      (l10n.playerStatVideoCodec, videoCodec.isEmpty ? '—' : videoCodec),
      (l10n.playerStatAudioCodec, audioCodec.isEmpty ? '—' : audioCodec),
      (l10n.playerStatBitrate, _fmtBitrate(bitrateKbps * 1000)),
      (l10n.playerStatFps, fps > 0 ? '${fps.toStringAsFixed(2)} fps' : '—'),
      (
        l10n.playerStatDecode,
        (hwdec.isEmpty || hwdec == 'no')
            ? l10n.playerHwdecSoftware
            : l10n.playerHwdecHardware(hwdec)
      ),
      ('清晰度', BilibiliLiveService.qualityLabel(_currentQn)),
      ('线路', line),
      ('网络', _fmtBitrate(cacheSpeed * 8)),
      ('音量', _muted ? '已静音' : '${_player.state.volume.round()}%'),
    ];
  }

  String _fmtBitrate(double bitsPerSec) {
    if (bitsPerSec <= 0) return '—';
    if (bitsPerSec < 1000) return '${bitsPerSec.round()} bps';
    if (bitsPerSec < 1000 * 1000) {
      return '${(bitsPerSec / 1000).toStringAsFixed(0)} Kbps';
    }
    return '${(bitsPerSec / (1000 * 1000)).toStringAsFixed(2)} Mbps';
  }

  /// 右键「对齐宽高比」：把窗口尺寸比例调整为与视频一致（消除黑边），仅桌面端。
  Future<void> _alignWindowToVideoAspectRatio() async {
    if (!_isDesktop) return;
    final vw = _player.state.width;
    final vh = _player.state.height;
    if (vw == null || vh == null || vw <= 0 || vh <= 0) {
      if (mounted) {
        showAppToast(
          context,
          L10n.current.playerAlignAspectRatioFailed,
          error: true,
        );
      }
      return;
    }
    final ratio = vw / vh;
    try {
      if (await windowManager.isMaximized()) await windowManager.unmaximize();
      if (await windowManager.isFullScreen()) {
        await windowManager.setFullScreen(false);
        if (mounted && !_disposed) setState(() => _fullscreen = false);
      }
      final size = await windowManager.getSize();
      if (size.width < 1 || size.height < 1) return;

      // 屏幕尺寸（逻辑像素）
      var screen = size;
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isNotEmpty) {
        final view = views.first;
        screen = view.physicalSize / view.devicePixelRatio;
      }

      // 以当前窗口高度为基准，宽度按视频比例补齐；超屏则改以屏幕宽度为基准
      var corrected = Size(size.height * ratio, size.height);
      if (corrected.width > screen.width || corrected.height > screen.height) {
        corrected = Size(screen.width, screen.width / ratio);
      }
      // 最小尺寸保护（与主窗口 400×300 一致）
      if (corrected.width < 400) corrected = Size(400, 400 / ratio);
      if (corrected.height < 300) corrected = Size(300 * ratio, 300);
      // 再次收进屏幕边界
      if (corrected.width > screen.width) {
        corrected = Size(screen.width, screen.width / ratio);
      }
      if (corrected.height > screen.height) {
        corrected = Size(screen.height * ratio, screen.height);
      }

      await windowManager.setSize(corrected);
      if (mounted) {
        showAppToast(context, L10n.current.playerAlignAspectRatioDone);
      }
    } catch (e) {
      debugPrint('[LiveRoom] 对齐宽高比失败: $e');
      if (mounted) {
        showAppToast(
          context,
          L10n.current.playerAlignAspectRatioFailed,
          error: true,
        );
      }
    }
  }

  // ════════════════════════════════════════
  //  房间背景（PiliPlus 同款：app_background 60% 透明度铺满整页）
  // ════════════════════════════════════════

  Widget _buildRoomBackground() {
    final bg = _info.appBackground;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF0E0C18)),
        Opacity(
          opacity: 0.6,
          child: bg.isNotEmpty
              ? Image(
                  image: CachedImageProvider(
                    bg,
                    headers:
                        NetworkSettingsService.instance.apiHeaders.isEmpty
                            ? null
                            : NetworkSettingsService.instance.apiHeaders,
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _bgGradient(),
                )
              : _bgGradient(),
        ),
      ],
    );
  }

  /// 没有房间背景图时的兜底（B 站直播间同款深紫色调）。
  Widget _bgGradient() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF3B2158),
            Color(0xFF221539),
            Color(0xFF0E0C18),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  //  聊天面板
  // ════════════════════════════════════════

  Widget _buildChatPanel() {
    return LiveChatPanel(
      key: _chatKey,
      events: _dmClient?.events ?? const Stream<LiveDanmuEvent>.empty(),
      initialSuperChats: _scList,
      loggedIn: _loggedIn,
      showOverlayDanmaku: _showDanmaku,
      onToggleOverlayDanmaku: _toggleOverlayDanmaku,
      onRequireLogin: _openLogin,
      onSend: (msg) =>
          BilibiliLiveService.sendDanmu(_info.roomId, msg),
      onLike: (count) => BilibiliLiveService.likeReport(
        clickTime: count,
        roomId: _info.roomId,
        anchorId: (_detail?.uid ?? 0) > 0 ? _detail!.uid : null,
      ),
      onLoadEmotes: () => BilibiliLiveService.fetchEmoticons(_info.roomId),
    );
  }

  // ════════════════════════════════════════
  //  房间信息卡（窄屏布局）
  // ════════════════════════════════════════

  Widget _buildInfoCard(ColorScheme cs) {
    final info = _info;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            info.title.isEmpty ? '未命名直播间' : _displayTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _appBarMeta(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          if (info.areaName.isNotEmpty || info.parentAreaName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (info.parentAreaName.isNotEmpty)
                  _tag(info.parentAreaName, cs),
                if (info.areaName.isNotEmpty) _tag(info.areaName, cs),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tag(String text, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }

  /// 当前生效清晰度：优先取服务端回报，取不到用期望值。
  int get _currentQn {
    for (final c in _candidates) {
      if (c.qn > 0) return c.qn;
    }
    return _qn;
  }

  /// 可选清晰度：以服务端 accept_qn 为准；缺失时把当前档位补进去保证菜单可用。
  List<int> _currentAcceptQn() {
    final set = <int>{..._acceptQn};
    if (set.isEmpty) set.add(_currentQn);
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }
}

/// 直播间右键菜单单项。
class _LiveMenuData {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _LiveMenuData(this.icon, this.text, this.onTap);
}
