// lib/screens/player.dart
// 全屏播放器：手势/截图/弹幕/字幕/倍速/选集等；可选接入 B 站清晰度切换
// （传入 playUrlInfo 时显示画质菜单）与高能进度条（viewPoints）。
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/liquid_dom_menu.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:media_kit/media_kit.dart' hide Playlist;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:naviflash/main.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/danmaku/danmaku_input_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:gal/gal.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/services/player_settings_service.dart';
import 'package:naviflash/services/play_history_service.dart';
import 'package:naviflash/services/watch_history_service.dart';
import 'package:naviflash/services/playlist_service.dart';
import 'package:naviflash/services/notification_service.dart';
import 'package:naviflash/services/super_resolution_service.dart';
import 'package:naviflash/services/sponsor_block_service.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/bilibili_video_service.dart';
import 'package:naviflash/services/bv_av.dart';
import 'package:naviflash/services/log_service.dart';
import 'package:naviflash/widgets/view_point_progress.dart';
import 'package:naviflash/widgets/webdav_file_picker.dart';
import 'package:naviflash/widgets/subtitle_controller.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/src/enums.dart';
import 'package:file_picker/file_picker.dart';
import 'package:naviflash/widgets/danmaku/danmaku_controller.dart';
import 'package:naviflash/widgets/danmaku/danmaku_smart_mask.dart';
import 'package:naviflash/widgets/danmaku/danmaku_view.dart';
import 'package:naviflash/widgets/danmaku/danmaku_parser.dart';
import 'package:naviflash/widgets/danmaku/danmaku_settings_panel.dart';
import 'package:naviflash/widgets/danmaku/danmaku_settings_sheet.dart';
import 'package:naviflash/widgets/danmaku/danmaku_list_sheet.dart';
import 'package:naviflash/widgets/bili_note_list_sheet.dart';
import 'package:naviflash/screens/note_editor_page.dart';
import 'package:naviflash/widgets/danmaku/danmaku_fetcher.dart';
import 'package:naviflash/widgets/playlist_episode_panel.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/screens/dlna_cast_page.dart';
import 'package:window_manager/window_manager.dart';

enum EndBehavior { pause, loop, exit }

/// 的视频播放页，也可作为全屏播放页）。
enum PlayerPageMode {
  /// 视频播放页：16:9 内嵌播放器（紧凑控制条 + 全屏按钮）。
  videoPage,

  /// 全屏播放页：铺满屏幕的沉浸式播放器。
  fullscreen,
}

String _endBehaviorToString(EndBehavior b) {
  switch (b) {
    case EndBehavior.pause:
      return 'pause';
    case EndBehavior.loop:
      return 'loop';
    case EndBehavior.exit:
      return 'exit';
  }
}

EndBehavior _stringToEndBehavior(String s) {
  switch (s) {
    case 'loop':
      return EndBehavior.loop;
    case 'exit':
      return EndBehavior.exit;
    default:
      return EndBehavior.pause;
  }
}

const double kFakeStatusBarHeight = 28.0;

class MpvPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String? heroTag;
  final Map<String, String>? httpHeaders;
  final String? subtitleUrl;
  final String? subtitleName;
  final Duration? initialPosition;
  final String? title;

  /// 系统媒体通知的 artist（B 站源传 UP 主名字）；
  /// 为空时使用默认文案（playerArtistVideo）。
  final String? artist;

  final String? danmakuSource;
  final String? danmakuType;

//  播放列表支持
  final Playlist? playlist;
  final int initialEpisodeIndex;

  /// 是否记录播放历史（外部「打开方式」播放的内容为 false）
  final bool recordHistory;

  /// 退出播放页时回调最终进度（供内嵌播放器/上一级页面同步进度）。
  final ValueChanged<Duration>? onExit;

  /// 可选：B 站 playurl（含全部 DASH 流与画质列表），传入后全屏可切换清晰度
  /// （切换无需重新请求，用 buildPlayableUrl 直接换流）。
  final BiliPlayUrl? playUrlInfo;

  /// 初始清晰度（与 [playUrlInfo] 一起传入）。
  final int? initialQualityQn;

  /// 可选：高能进度条片段（data.view_points）。
  final List<BiliViewPoint>? viewPoints;

  /// 双模式：默认全屏播放页；传 [PlayerPageMode.videoPage] 时作为 16:9
  /// 内嵌视频播放页使用（详情页内嵌 / 可独立使用）。
  final PlayerPageMode mode;

  /// 视频播放页点「全屏」时回调（宿主页面切换布局/跳转全屏路由）。
  /// 为空时自动 push 一个全屏 [MpvPlayerPage]（进度自动续播）。
  final VoidCallback? onFullscreenRequested;

  /// 全屏模式点「返回」时回调（用于同一播放器实例内切换回视频播放页）。
  /// 为空时按路由回退处理（Navigator.pop）。
  final VoidCallback? onExitFullscreenRequested;

  /// 播放进度变化回调（宿主页面同步进度，如弹幕输入栏 / 全屏续播）。
  final ValueChanged<Duration>? onPositionChanged;

  /// 播放列表模式切换分P回调（宿主页面同步分P选中态）。
  final ValueChanged<int>? onEpisodeChanged;

  /// 切换画质回调（宿主页面同步当前画质）。
  final ValueChanged<int>? onQualityChanged;

  /// 弹幕加载完成回调（条数），宿主页面据此展示「已装填 N 条弹幕」。
  final ValueChanged<int>? onDanmakuCountChanged;

  /// 共享弹幕控制器：宿主页面传入后与本播放器共用同一个控制器
  /// （发送弹幕上屏、条数统计等）。
  final DanmakuController? danmakuController;

  /// 是否自动开始播放；false 时显示封面等待用户点击（视频播放页使用）。
  final bool autoPlay;

  /// 封面图地址（autoPlay=false 时展示，点击后开始播放）。
  final String? coverUrl;

  /// 系统媒体播放器缩略图地址（封面，网络 URL 或 file://）。为空时不设封面。
  final String? artUri;

  /// B 站视频 BV 号（仅 B 站源传入，用于右键「复制空降链接」）。
  final String? bilibiliBvid;

  /// 稳定播放历史 ID（如 B 站 bvid+cid）。为空时按 [videoUrl] 生成。
  /// 保证同一视频跨会话 / 跨 CDN 主机也能匹配到同一历史记录，并可据此恢复进度。
  final String? historyId;

  /// 控制条显示状态变化回调（宿主页面据此隐藏/显示暂停悬浮按钮等）。
  final ValueChanged<bool>? onControlsVisibilityChanged;

  const MpvPlayerPage({
    super.key,
    required this.videoUrl,
    this.heroTag,
    this.httpHeaders,
    this.subtitleUrl,
    this.subtitleName,
    this.initialPosition,
    this.title,
    this.artist,
    this.danmakuSource,
    this.danmakuType,
    this.playlist,
    this.initialEpisodeIndex = 0,
    this.recordHistory = true,
    this.onExit,
    this.playUrlInfo,
    this.initialQualityQn,
    this.viewPoints,
    this.mode = PlayerPageMode.fullscreen,
    this.onFullscreenRequested,
    this.onExitFullscreenRequested,
    this.onPositionChanged,
    this.onEpisodeChanged,
    this.onQualityChanged,
    this.onDanmakuCountChanged,
    this.danmakuController,
    this.autoPlay = true,
    this.coverUrl,
    this.artUri,
    this.bilibiliBvid,
    this.historyId,
    this.onControlsVisibilityChanged,
  });

  @override
  State<MpvPlayerPage> createState() => MpvPlayerPageState();
}

class MpvPlayerPageState extends State<MpvPlayerPage>
    with WidgetsBindingObserver {
  late final Player player;
  late final VideoController controller;

  bool get _isFullscreen => widget.mode == PlayerPageMode.fullscreen;

///  是否已进入销毁流程：置位后所有异步播放器回调都应立即返回，
  ///    避免退出页面时与 `player.dispose()` 竞态抛 `[Player] has been disposed`。
  bool _disposed = false;

  /// 进入页即记录历史（用户需求：不再等播放才记录），仅一次
  bool _enterHistoryRecorded = false;

  /// 是否 B 站源（传入了 playUrlInfo）：禁用本地/WebDAV 字幕设置，
  bool get _isBiliSource => widget.playUrlInfo != null;

  /// 系统媒体通知 artist：B 站源用 UP 主名字，其余用默认文案。
  String get _mediaArtist => widget.artist ?? L10n.current.playerArtistVideo;

//  播放页窗口等比例锁定（仅桌面平台生效）
  bool _keepWindowAspectRatio = false;
  double _windowAspectRatio = 0.0;
  bool _isCorrectingWindowSize = false;
  Size? _lastAcceptedWindowSize;

  static bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  BoxFit currentFit = BoxFit.contain;
  bool isDragging = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double currentRate = 1.0;
  bool isLongPressing = false;
  double previousRate = 1.0;
  bool _showControls = true;

  /// 控制条是否显示（设为 getter/setter 以便在变化时通知宿主页面）。
  bool get showControls => _showControls;
  set showControls(bool value) {
    if (_showControls == value) return;
    _showControls = value;
    widget.onControlsVisibilityChanged?.call(value);
  }

  Timer? _hideTimer;
  Duration dragPosition = Duration.zero;
  bool isFlipX = false;
  bool isFlipY = false;
  final FocusNode _focusNode = FocusNode();
  Timer? _keyHoldTimer;

//  播放历史定时保存（播放中每 15s 写一次本地历史，防止退出/杀进程丢进度）
  Timer? _historySaveTimer;

  bool _seekGestureActive = false;
  double _gestureStartX = 0;
  double _gestureStartY = 0;

  static const _pipChannel = MethodChannel('com.memz2345.navi.flash/pip');
  static const _brightnessChannel = MethodChannel(
    'com.memz2345.navi.flash/brightness',
  );

  EndBehavior endBehavior = EndBehavior.pause;
  bool isFinished = false;

  final GlobalKey _repaintKey = GlobalKey();
  final GlobalKey _danmakuRepaintKey = GlobalKey();
  File? _screenshotFile;
  bool _showScreenshotPreview = false;
  Timer? _screenshotTimer;

  IconData? _doubleTapIcon;
  Timer? _doubleTapTimer;

  String _videoTitle = '';
  String? _thumbnailPath;
//  当前实际播放的资源地址（WebDAV/播放列表切换时更新），投屏用
  String _currentSourceUrl = '';

  double _currentBrightness = 0.5;
  double _currentVolume = 100.0;
  bool _isAdjustingBrightness = false;
  bool _isAdjustingVolume = false;
  double _adjustmentProgress = 0.0;

  double _scale = 1.0;
  double _baseScale = 1.0;
  double _rotation = 0.0;
  double _baseRotation = 0.0;
  bool _isScaling = false;

  bool get _isTransformed =>
      _scale != 1.0 || (_rotation % (2 * math.pi)).abs() > 0.01;

  bool _showSettingsPanel = false;
  bool _showSubtitlePanel = false;
  bool _orientationLocked = false;

  double _subFontSize = 48.0;
  Color _subColor = Colors.white;
  Color _subBgColor = const Color(0x80000000);

  String? _lastPlayerError;
  Duration _bufferPosition = Duration.zero;
  bool _isBuffering = false;

  /// 往回拖进度条（目标在已缓冲/已解码范围内）后，短暂抑制 seek 触发的
  /// buffering 闪烁：mpv 对该类 seek 不会真正重新缓冲，只是上报一次
  /// buffering=true，直接忽略可避免误显示「加载中」动画。窗口过期后恢复正常。
  DateTime? _bufferingSuppressUntil;
  double _networkSpeedBps = 0.0;
  Timer? _speedCalcTimer;
  int _lastCacheUsedBytes = 0;
  DateTime _lastSpeedCalcTime = DateTime.now();

  int _lastTapTimestamp = 0;
  static const int _doubleTapThresholdMs = 300;

  // ─── 详细媒体信息 ───
  String _videoCodec = '';
  String _audioCodec = '';
  int _videoBitrate = 0;
  double _containerFps = 0.0;
  String _hwdecCurrent = '';
  Timer? _statsTimer;

  // ─── 弹幕相关 ───
  late final DanmakuController _danmakuController;
  late final bool _ownsDanmakuController;
  bool _showDanmakuPanel = false;
  bool _danmakuLoaded = false;
  String _danmakuFileName = '';
  StreamSubscription? _danmakuPlayingSub;
  StreamSubscription? _danmakuPositionSub;

  // ── 智能防遮挡：取帧 → u2netp 推理 → 弹幕遮罩 ──
  Timer? _smartMaskTimer;
  DanmakuSmartMaskService? _smartMaskService;
  bool _smartMaskBusy = false;
  String? _activeDanmakuSource;
  String? _activeDanmakuType;

  // ─── 双模式（视频播放页 / 全屏页） ───
  /// 是否已开始播放（autoPlay=false 时等待用户点击封面）。
  bool _started = false;

  // ─── B 站字幕 / 首选解码格式 ───
  String _decodeFormat = 'auto';
  List<BiliSubtitle> _biliSubtitles = const [];
  BiliSubtitle? _activeBiliSubtitle;
  bool _biliSubtitleLoading = false;

  // ─── 播放列表相关 ───
  Playlist? _activePlaylist;
  int _currentEpisodeIndex = 0;
  bool _showEpisodePanel = false;

  // ─── B 站清晰度 / CDN 源 / 高能进度条 ───
  int _currentQn = 0;

  /// 当前 CDN 源下标：0 = baseUrl，1..n = backupUrls[n-1]。
  /// 播放卡顿 / 源无法访问时可在右上角「换源」菜单切换备用 CDN。
  int _sourceIndex = 0;

  /// 当前 CDN 源手动指定域名（预设镜像表换源时非空；backup 源时为 null）。
  String? _sourceHost;
  List<BiliViewPoint> _viewPoints = const [];

  // ─── 跳过片头/片尾（SponsorBlock） ───
  List<SponsorSegment> _sponsorSegments = [];
  SponsorSegment? _activeSkipSegment;
  Timer? _skipPromptTimer;
  bool get _showSkipPrompt =>
      _activeSkipSegment != null &&
      (_playerSettingsService?.skipIntroOutro ?? false);

  bool get _isPlaylistMode =>
      _activePlaylist != null && _activePlaylist!.items.length > 1;

//  FIX: 缓存 PlayHistoryService 引用
  PlayHistoryService? _historyService;
  PlayerSettingsService? _playerSettingsService;
//  观看历史足迹服务 + 全局设置（无痕模式判断）
  WatchHistoryService? _watchHistoryService;
  SettingsService? _settingsService;

//  mpv 日志订阅
  StreamSubscription? _mpvLogSub;

  /// 把设置里的细度字符串映射为 media_kit 的 MPVLogLevel。
  static MPVLogLevel _mpvLogLevelOf(String level) => switch (level) {
    'error' => MPVLogLevel.error,
    'info' => MPVLogLevel.info,
    'v' => MPVLogLevel.v,
    'debug' => MPVLogLevel.debug,
    'trace' => MPVLogLevel.trace,
    _ => MPVLogLevel.warn,
  };

  void _resetTransform() {
    setState(() {
      _scale = 1.0;
      _rotation = 0.0;
    });
  }

  String _extractTitleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segments.isNotEmpty) {
          return Uri.decodeComponent(segments.last);
        }
        return uri.host;
      }
    } catch (_) {}
    return path.basename(url);
  }

  // Windows 原生统计对话框：注册 getStats 回调，供原生定时拉取最新统计实时刷新。
  static const MethodChannel _statsChannel =
      MethodChannel('com.memz2345.navi.flash/stats_dialog');

  Future<dynamic> _handleStatsMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'getStats':
        if (!mounted) return <List<String>>[];
        return _statsEntries().map((e) => [e.$1, e.$2]).toList();
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // 注册原生统计对话框的实时数据回调（仅 Windows 原生对话框会调用）。
    _statsChannel.setMethodCallHandler(_handleStatsMethodCall);
    WidgetsBinding.instance.addObserver(this);

//  系统媒体控件「上一集 / 下一集」回调：
    //    Windows 控制中心 SMTC、任务栏缩略图工具栏按钮，以及 Android
    //    通知栏的上一首/下一首按钮，都会经 audioHandler 走到这里。
    audioHandler
      ..onSkipToNext = _playNextEpisode
      ..onSkipToPrevious = _playPrevEpisode;

    _videoTitle = widget.title ?? _extractTitleFromUrl(widget.videoUrl);
    _currentSourceUrl = widget.videoUrl;

//  播放列表初始化
    _activePlaylist = widget.playlist;
    _currentEpisodeIndex = widget.initialEpisodeIndex;

//  B 站清晰度 / 高能进度条初始化
    _currentQn = widget.initialQualityQn ?? widget.playUrlInfo?.quality ?? 0;
    _viewPoints = widget.viewPoints ?? const [];

//  非全屏内嵌播放器：首帧后主动获取键盘焦点，保证快捷键立即可用
    //   （仅靠 KeyboardListener autofocus 在页面层级较深时可能不生效）
    if (!_isFullscreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
      });
    }

//  弹幕控制器：支持宿主页面共享（发送弹幕上屏 / 条数统计）。
    // 仅在自行创建时负责 dispose，避免与宿主页面双重释放。
    _ownsDanmakuController = widget.danmakuController == null;
    _danmakuController = widget.danmakuController ?? DanmakuController();
//  自行创建的控制器：恢复持久化的弹幕设置（共享控制器由宿主恢复）。
    if (_ownsDanmakuController) {
      _danmakuController.restoreSettings();
    }
    _danmakuController.isFullscreen = _isFullscreen;

//  B 站字幕列表（playurl 下发，多为 AI 字幕）
    _biliSubtitles = widget.playUrlInfo?.subtitles ?? const [];

//  读取播放器设置（此处 MultiProvider 已就绪，可直接 read）
    final playerSettings = context.read<PlayerSettingsService>();
    final enableMpvLog = playerSettings.enableMpvLog;
    _decodeFormat = playerSettings.preferredDecodeFormat;

    player = Player(
      configuration: PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024,
//  mpv 日志开关：开启时按所选细度采集，关闭时保持 warn
        logLevel: enableMpvLog
            ? _mpvLogLevelOf(playerSettings.mpvLogLevel)
            : MPVLogLevel.warn,
      ),
    );
    controller = VideoController(player);

//  mpv 日志落盘（可选）：写入应用数据目录 mpv/ 下，按天分文件
    if (enableMpvLog) {
      _mpvLogSub = player.stream.log.listen((log) {
        LogService.mpv(log.level, '[${log.prefix}] ${log.text}');
      });
    }

    _configureMpvForHttpStream();

    player.stream.error.listen((error) {
      if (error.isNotEmpty) {
        debugPrint('❌ mpv 错误: $error');
        LogService.error('mpv 错误: $error');
        if (!mounted) return;
        // 可自动恢复的噪音错误（网络闪断 read failed / http error / 超时等）
        // 只记日志不打断播放——mpv 会自行重试，多数时候播放不受影响。
        if (_isRecoverableMpvError(error)) return;
        // 播放仍在进行 = 非致命（mpv 已恢复），同样不弹错误框。
        if (player.state.playing) return;
        if (_lastPlayerError == null) {
          setState(() => _lastPlayerError = error);
        }
      }
    });

    final settings = Provider.of<SettingsService>(context, listen: false);
    currentRate = settings.playerDefaultRate;
    endBehavior = _stringToEndBehavior(settings.playerEndBehavior);

//  仅全屏模式强制横屏沉浸；视频播放页模式跟随宿主页面方向
    if (Platform.isAndroid && _isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    () async {
      player.stream.error.listen((err) {
        if (err.isNotEmpty && mounted) {
          debugPrint('❌ mpv error: $err');
        }
      });

      await _configureMpvForHttpStream();
//  双模式：autoPlay=false（视频播放页）时先展示封面，点击后再打开媒体
      if (widget.autoPlay) {
        await _openMedia(
          widget.videoUrl,
          headers: widget.httpHeaders,
          subtitleUrl: widget.subtitleUrl,
          subtitleHeaders: widget.httpHeaders,
        );
        if (_disposed || !mounted) return;
        if (mounted) setState(() => _started = true);

        // 断点续播
        final resumeAt = _effectiveInitialPosition;
        if (resumeAt != null) {
          Duration? readyDuration;
//  修复：轮询间隔 100ms、最长 3 秒，避免慢速网络下
          //    长时间卡在「加载中」假死
          for (int i = 0; i < 30; i++) {
            await Future.delayed(const Duration(milliseconds: 100));
            if (_disposed || !mounted) return;
            if (player.state.duration > Duration.zero) {
              readyDuration = player.state.duration;
              break;
            }
          }
          if (_disposed || !mounted || readyDuration == null) return;

          final target = resumeAt;
          final clamped = target > readyDuration ? readyDuration : target;

          for (int i = 0; i < 20; i++) {
            await Future.delayed(const Duration(milliseconds: 100));
            if (_disposed || !mounted) return;
            if (!player.state.buffering) break;
          }
          if (_disposed || !mounted) return;

          player.seek(clamped);
          await Future.delayed(const Duration(milliseconds: 500));
          if (_disposed || !mounted) return;

          if (player.state.position.inMilliseconds < 1000 &&
              clamped.inMilliseconds > 3000) {
            debugPrint('⚠️ 首次 seek 未生效，重试...');
            player.seek(clamped);
            await Future.delayed(const Duration(milliseconds: 400));
            if (_disposed || !mounted) return;
          }

          if (mounted) {
            showAppToast(
              context,
              AppLocalizations.of(context).playerResumeFrom(_format(clamped)),
            );
          }
        }

        if (_disposed || !mounted) return;
        player.setRate(currentRate);
        audioHandler.attachPlayer(
          player,
          title: _videoTitle,
          artist: _mediaArtist,
          artUri: widget.artUri,
        );
        _generateThumbnail();
        _autoLoadDanmakuIfEnabled();

//  有 BV+CID 的视频尝试查询片头/片尾（无则静默跳过）
        _maybeQuerySponsorBlock();
      }

      if (Platform.isAndroid || Platform.isIOS) {
        try {
          final brightness = await _brightnessChannel.invokeMethod<double>(
            'getBrightness',
          );
          if (brightness != null && mounted) {
            _currentBrightness = brightness.clamp(0.0, 1.0);
          }
        } catch (_) {}
      }
    }();

    player.stream.position.listen((pos) {
      if (!isDragging && mounted) setState(() => position = pos);
      widget.onPositionChanged?.call(pos);
    });

    player.stream.duration.listen((dur) {
      if (mounted) setState(() => duration = dur);
//  自动方向（仅全屏）：按视频宽高比判断竖屏 / 横屏，无需手动切换。
      if (!_orientationLocked) {
        _applyAutoOrientation();
      }
    });

//  视频宽高就绪后也尝试自动方向（宽高可能晚于 duration 返回）
    player.stream.width.listen((_) {
      if (!_orientationLocked) _applyAutoOrientation();
    });
    player.stream.height.listen((_) {
      if (!_orientationLocked) _applyAutoOrientation();
    });

    player.stream.buffer.listen((buf) {
      if (mounted) setState(() => _bufferPosition = buf);
    });

//  播放历史定时保存：播放中每 15s 写一次本地历史（记录进度更可靠）；
    //  同时周期上报 B 站云端进度（参考 PiliPlus 每 15s heartbeat，登录才生效）
    _historySaveTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted || !player.state.playing) return;
      final posMs = position.inMilliseconds;
      _saveHistoryNow(widget.historyId);
      if (posMs > 3000) _reportBiliProgressIfNeeded(posMs);
    });

    player.stream.buffering.listen((buffering) {
      if (!mounted) return;
      if (buffering) {
        final until = _bufferingSuppressUntil;
        if (until != null) {
          if (DateTime.now().isBefore(until)) {
            // 往回拖 seek 的短暂缓冲上报：目标数据已在缓存内，忽略
            setState(() => _isBuffering = false);
            return;
          }
          _bufferingSuppressUntil = null;
        }
      }
      setState(() => _isBuffering = buffering);
    });

    _speedCalcTimer = Timer.periodic(const Duration(milliseconds: 800), (
      _,
    ) async {
      if (_disposed || !mounted) return;
      try {
        final platform = player.platform;
        if (platform is NativePlayer) {
          final speedStr = await platform.getProperty('cache-speed');
          final speed = double.tryParse(speedStr) ?? 0.0;
          if (!_disposed && mounted) setState(() => _networkSpeedBps = speed);
        }
      } catch (_) {}
    });

    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_disposed || !mounted) return;
      final platform = player.platform;
      if (platform is! NativePlayer) return;
      try {
        final vCodec = await platform.getProperty('video-codec') ?? '';
        final aCodec = await platform.getProperty('audio-codec') ?? '';
        final bitrateStr = await platform.getProperty('video-bitrate') ?? '0';
        final fpsStr = await platform.getProperty('container-fps') ?? '0';
        final hwdec = await platform.getProperty('hwdec-current') ?? '';
        if (!_disposed && mounted) {
          setState(() {
            _videoCodec = vCodec;
            _audioCodec = aCodec;
            _videoBitrate = int.tryParse(bitrateStr) ?? 0;
            _containerFps = double.tryParse(fpsStr) ?? 0.0;
            _hwdecCurrent = hwdec;
          });
        }
      } catch (_) {}
    });

//  修改：播放完成时支持自动下一集
    player.stream.completed.listen((completed) {
      if (!_disposed && completed && mounted) {
        if (_isPlaylistMode) {
          _playNextEpisode();
        } else if (endBehavior == EndBehavior.pause) {
          setState(() {
            isFinished = true;
            showControls = true;
          });
        } else if (endBehavior == EndBehavior.loop) {
          player.seek(Duration.zero);
          player.play();
        } else if (endBehavior == EndBehavior.exit) {
          Navigator.of(context).pop();
        }
      }
    });

    // ─── 弹幕与播放器同步 ───
    _danmakuPlayingSub = player.stream.playing.listen((playing) {
      if (playing) {
        _danmakuController.play();
      } else {
        _danmakuController.pause();
      }
    });

    _danmakuPositionSub = player.stream.position.listen((pos) {
      if (!_danmakuLoaded) return;
      final posSec = pos.inMilliseconds / 1000.0;
      final diff = (posSec - _danmakuController.currentTime).abs();
      if (diff > 2.0) {
        _danmakuController.seekTo(posSec);
      } else {
        _danmakuController.syncTime(posSec);
      }
    });

//  跳过片头/片尾：位置监听
    player.stream.position.listen(_onSkipCheck);

    // ─── 智能防遮挡：周期取帧推理主体遮罩（开关关闭时零开销）───
    _smartMaskTimer = Timer.periodic(
      const Duration(milliseconds: 400),
      (_) => _smartMaskTick(),
    );

    _resetHideTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _historyService ??= context.read<PlayHistoryService>();
    _watchHistoryService ??= context.read<WatchHistoryService>();
    _settingsService ??= context.read<SettingsService>();
    if (_playerSettingsService == null) {
      _playerSettingsService = context.read<PlayerSettingsService>();
      _playerSettingsService!.addListener(_onPlayerSettingsChanged);
      if (_isFullscreen) {
        _setupWindowAspectLock();
      }
    }
//  进入页即记录播放历史（force 允许 0 进度，用户需求）
    if (!_enterHistoryRecorded) {
      _enterHistoryRecorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _recordPlayHistoryOnEnter();
      });
    }
  }

  /// 进入播放页即记录：播放历史（0 进度）+ 观看历史（B 站）
  Future<void> _recordPlayHistoryOnEnter() async {
    if (!widget.recordHistory) return;
    if (_settingsService?.incognitoMode ?? false) return;
    // 播放历史：0 进度入历史，确保历史页立即可见
    try {
      final posMs = _effectiveInitialPosition?.inMilliseconds ?? 0;
      // 已有记录则保留其进度，仅刷新时间；无则用 0
      final existing = _historyService?.findById(
              widget.historyId ?? PlayHistoryService.generateId(widget.videoUrl));
      final usePos = existing?.positionMs ?? posMs;
      final useDur = existing?.durationMs ?? 0;
      // 若已有且进度>0，沿用；否则 0 进度 force 入库
      await _historyService?.saveProgress(
        id: widget.historyId,
        videoUrl: widget.videoUrl,
        title: _videoTitle,
        positionMs: usePos,
        durationMs: useDur,
        thumbnailPath: _thumbnailPath,
        httpHeaders: widget.httpHeaders,
        subtitleUrl: widget.subtitleUrl,
        danmakuSource: _activeDanmakuSource ?? widget.danmakuSource,
        danmakuType: _activeDanmakuType ?? widget.danmakuType,
        force: true,
      );
    } catch (e) {
      debugPrint('⚠️ 进入页记录播放历史失败: $e');
    }
    // B 站观看历史已在 BilibiliVideoPage._recordWatchHistoryOnEnter 完成，
    // 此处仅处理非 B 站或直接打开播放器的场景：若有 bvid 则补一条
    try {
      final bvid = widget.bilibiliBvid;
      if (bvid != null && bvid.isNotEmpty) {
        final wh = _watchHistoryService;
        if (wh == null) return;
        final cid = int.tryParse(_activeDanmakuSource ?? widget.danmakuSource ?? '');
        WatchHistoryEntry? existing;
        if (cid != null) {
          final key = '$bvid:$cid';
          try {
            existing = wh.entries.firstWhere((e) => e.key == key);
          } catch (_) {
            existing = wh.findByBvid(bvid);
          }
        } else {
          existing = wh.findByBvid(bvid);
        }
        final entry = WatchHistoryEntry(
          bvid: bvid,
          aid: null,
          cid: cid,
          title: _videoTitle,
          coverUrl: widget.coverUrl ?? _thumbnailPath,
          upperName: widget.artist,
          positionMs: existing?.positionMs ?? 0,
          durationMs: existing?.durationMs ?? 0,
          watchedAt: DateTime.now(),
          finished: existing?.finished ?? false,
        );
        await wh.record(entry, force: true);
      }
    } catch (e) {
      debugPrint('⚠️ 进入页记录观看历史失败: $e');
    }
  }

  @override
  void didUpdateWidget(covariant MpvPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
//  双模式切换（视频播放页 ↔ 全屏页，同一实例）时展示控制条
    if (oldWidget.mode != widget.mode) {
      if (mounted) setState(() => showControls = true);
      _resetHideTimer();
//  进入全屏：按视频宽高比自动横/竖屏；退出全屏：恢复原方向
      if (Platform.isAndroid) {
        if (widget.mode == PlayerPageMode.fullscreen) {
          _applyAutoOrientation();
        } else {
          SystemChrome.setPreferredOrientations(DeviceOrientation.values);
          _orientationLocked = false;
        }
      }
    }
//  高能进度条数据异步加载完成后同步到播放器（view_points 晚于
    //    播放器初始化到达时，initState 里的初值仍是空列表）
    if (oldWidget.viewPoints != widget.viewPoints) {
      _viewPoints = widget.viewPoints ?? const [];
    }
//  非全屏内嵌播放器：模式切换后重新获取键盘焦点，保证快捷键可用
    if (oldWidget.mode != widget.mode && !_isFullscreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
      });
    }
  }

  /// 按视频宽高比自动切换横 / 竖屏（仅全屏模式）：
  ///   - 竖屏视频在应用本身为横屏时保持横屏播放，不强制旋转；
  ///   - 横屏视频锁定横屏。
  void _applyAutoOrientation() {
    if (!Platform.isAndroid || !_isFullscreen) return;
    final w = player.state.width ?? 0;
    final h = player.state.height ?? 0;
    if (w <= 0 || h <= 0) return;
    _orientationLocked = true;
    final isPortrait = h > w;
    final view = WidgetsBinding.instance.platformDispatcher.views.isEmpty
        ? null
        : WidgetsBinding.instance.platformDispatcher.views.first;
    final windowPortrait =
        view != null && view.physicalSize.height > view.physicalSize.width;
    if (isPortrait && windowPortrait) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else if (!isPortrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    // 竖屏视频但应用为横屏：保持横屏播放
  }

  void _onPlayerSettingsChanged() {
    final platform = player.platform;
    if (platform is! NativePlayer) return;
    final ps = _playerSettingsService;
    if (ps == null) return;
    platform.setProperty('hwdec', ps.hwdecMode).catchError((_) {});
    platform.setProperty('video-sync', ps.videoSync).catchError((_) {});
//  超分辨率：设置变更时实时应用 / 清除 Anime4K 着色器
    SuperResolutionService.apply(platform, ps.superResolutionMode);
    _syncWindowAspectLock();
  }

// ───  窗口等比例拉伸锁定 ───

  /// 依据当前设置，启动或解除窗口比例锁定
  Future<void> _syncWindowAspectLock() async {
    final ps = _playerSettingsService;
    if (ps == null || !_isDesktop || !_isFullscreen) return;
    if (ps.keepWindowAspectRatio && !_keepWindowAspectRatio) {
      await _setupWindowAspectLock();
    } else if (!ps.keepWindowAspectRatio && _keepWindowAspectRatio) {
      await _releaseWindowAspectLock();
    }
  }

  /// 以进入播放页时窗口当前比例作为锁定比例
  Future<void> _setupWindowAspectLock() async {
    if (_keepWindowAspectRatio || !_isDesktop) return;
    final ps = _playerSettingsService;
    if (ps == null || !ps.keepWindowAspectRatio) return;
    try {
      final size = await windowManager.getSize();
      if (size.width < 1 || size.height < 1) return;
      _windowAspectRatio = size.width / size.height;
      _lastAcceptedWindowSize = size;
      _keepWindowAspectRatio = true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 播放页等比例锁定初始化失败: $e');
    }
  }

  Future<void> _releaseWindowAspectLock() async {
    _keepWindowAspectRatio = false;
    _windowAspectRatio = 0.0;
    _lastAcceptedWindowSize = null;
    _isCorrectingWindowSize = false;
  }

  /// 窗口尺寸变化（用户拖拽缩放）时按锁定比例修正
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!_isDesktop || !_keepWindowAspectRatio || _windowAspectRatio <= 0) {
      return;
    }
    _enforceWindowAspectRatio();
  }

  Future<void> _enforceWindowAspectRatio() async {
    if (_isCorrectingWindowSize) return;
    try {
      if (await windowManager.isMaximized() ||
          await windowManager.isFullScreen()) {
        return;
      }
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isEmpty) return;
      final view = views.first;
      final size = view.physicalSize / view.devicePixelRatio;
      if (size.width < 1 || size.height < 1) return;

      final ratio = _windowAspectRatio;
      final prev = _lastAcceptedWindowSize;
      final dw = prev == null ? 1.0 : (size.width - prev.width).abs();
      final dh = prev == null ? 1.0 : (size.height - prev.height).abs();

      // 以变化较大的轴为基准，另一轴按比例补齐
      var corrected = dw > dh
          ? Size(size.width, size.width / ratio)
          : Size(size.height * ratio, size.height);

      // 最小尺寸保护（与主窗口 400×300 一致）
      if (corrected.width < 400) corrected = Size(400, 400 / ratio);
      if (corrected.height < 300) corrected = Size(300 * ratio, 300);

      if ((corrected.width - size.width).abs() < 1 &&
          (corrected.height - size.height).abs() < 1) {
        _lastAcceptedWindowSize = size;
        return;
      }

      _isCorrectingWindowSize = true;
      await windowManager.setSize(corrected);
      _isCorrectingWindowSize = false;
      _lastAcceptedWindowSize = corrected;
    } catch (e) {
      _isCorrectingWindowSize = false;
      if (kDebugMode) debugPrint('⚠️ 窗口等比例修正失败: $e');
    }
  }

  Future<void> _autoLoadDanmakuIfEnabled() async {
    final ps = _playerSettingsService;
    if (ps == null || !ps.loadDanmakuOnResume) return;

//  播放列表模式：优先使用当前集自带的弹幕源（SS 导入后逐集附加）
    String? source;
    String? type;
    if (_isPlaylistMode && _activePlaylist != null) {
      final item = _activePlaylist!.items[_currentEpisodeIndex];
      if (item.danmakuSource != null && item.danmakuSource!.isNotEmpty) {
        source = item.danmakuSource;
        type = item.danmakuType ?? 'cid';
      }
    }
    source ??= widget.danmakuSource;
    type ??= widget.danmakuType;
    if (source == null || source.isEmpty) return;
    debugPrint('🔄 自动加载弹幕: source=$source, type=$type');
    try {
      final result = await DanmakuSegFetcher.fetch(
        input: source,
        inputType: type ?? 'bv',
      );
      if (!mounted) return;
      if (result.success && result.items.isNotEmpty) {
        _danmakuController.setItems(result.items);
        _danmakuController.seekTo(position.inMilliseconds / 1000.0);
        if (player.state.playing) {
          _danmakuController.play();
        }
        setState(() {
          _danmakuLoaded = true;
          _danmakuFileName = result.fromCache
              ? L10n.current.playerDanmakuCache(result.items.length)
              : L10n.current.playerDanmakuBilibili(result.items.length);
          _activeDanmakuSource = source;
          _activeDanmakuType = type ?? 'bv';
        });
        widget.onDanmakuCountChanged?.call(result.items.length);
        debugPrint(
          '✅ 自动弹幕加载完成: ${result.items.length} 条, fromCache=${result.fromCache}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ 自动弹幕加载失败: $e');
    }
  }


  /// 仅当视频有 BV（可解析 CID）时查询片头/片尾片段；
  /// 无 BV 或 CID 解析失败 → 静默跳过，不提示。
  Future<void> _maybeQuerySponsorBlock() async {
    final ps = _playerSettingsService;
    if (ps == null || !ps.skipIntroOutro) return;
    String? source;
    String? type;
    if (_isPlaylistMode && _activePlaylist != null) {
      final item = _activePlaylist!.items[_currentEpisodeIndex];
      if (item.danmakuSource != null && item.danmakuSource!.isNotEmpty) {
        source = item.danmakuSource;
        type = item.danmakuType ?? 'cid';
      }
    }
    source ??= _activeDanmakuSource ?? widget.danmakuSource;
    type ??= _activeDanmakuType ?? widget.danmakuType;
    if (source == null || source.isEmpty || type != 'bv') return;
    if (!RegExp(r'^(BV|bv)[0-9A-Za-z]+$').hasMatch(source.trim())) return;

    final segments = await SponsorBlockService.fetchForVideo(bvid: source);
    if (!mounted || segments == null) return;
    setState(() => _sponsorSegments = segments);
    if (kDebugMode) {
      debugPrint(
        '🎬 片头片尾片段 ${segments.length} 条: '
        '${segments.map((s) => '${s.category}[${s.startMs}~${s.endMs}]').join(', ')}',
      );
    }
  }

  void _clearSponsorBlock() {
    _skipPromptTimer?.cancel();
    _skipPromptTimer = null;
    _sponsorSegments = [];
    _activeSkipSegment = null;
  }

  /// 播放位置监听：进入片头/片尾片段时弹出「跳过」提示，5 秒后自动消失
  void _onSkipCheck(Duration pos) {
    final active = _activeSkipSegment;
    if (active != null) {
      final ms = pos.inMilliseconds;
      if (ms >= active.endMs || ms < active.startMs) {
        _skipPromptTimer?.cancel();
        _skipPromptTimer = null;
        if (mounted) setState(() => _activeSkipSegment = null);
      }
      return;
    }
    if (_sponsorSegments.isEmpty) return;
    final ms = pos.inMilliseconds;
    for (final seg in _sponsorSegments) {
      if (seg.skipped) continue;
      if (seg.startMs <= ms && ms < seg.endMs) {
        _skipPromptTimer?.cancel();
        _skipPromptTimer = Timer(const Duration(seconds: 5), () {
          _skipPromptTimer = null;
          if (mounted) setState(() => _activeSkipSegment = null);
        });
        setState(() => _activeSkipSegment = seg);
        break;
      }
    }
  }

  void _skipActiveSegment() {
    final seg = _activeSkipSegment;
    if (seg == null) return;
    _skipPromptTimer?.cancel();
    _skipPromptTimer = null;
    setState(() {
      _activeSkipSegment = null;
      seg.skipped = true;
    });
    player.seek(Duration(milliseconds: seg.endMs));
    if (!player.state.playing) player.play();
  }

  // ─── 播放列表：集数切换 ───

  Future<void> _switchToEpisode(int index) async {
    if (_activePlaylist == null) return;
    if (index < 0 || index >= _activePlaylist!.items.length) return;

//  切分P前先保存上一集播放进度（widget.historyId 此刻仍是上一集的 ID，
    //    宿主页面 rebuild 尚未执行，可放心使用）
    _saveHistoryNow(widget.historyId);

    final item = _activePlaylist!.items[index];

    setState(() {
      _currentEpisodeIndex = index;
      _videoTitle = item.title;
      isFinished = false;
      position = Duration.zero;
      duration = Duration.zero;
      _bufferPosition = Duration.zero;
      _isBuffering = false;
      _lastPlayerError = null;
      _showEpisodePanel = false;
      _orientationLocked = false;
//  切分P后 playurl 字幕不再对应当前集，自动关闭 B 站字幕
      _activeBiliSubtitle = null;
    });
    widget.onEpisodeChanged?.call(index);

//  切换分集后清空片头/片尾片段
    _clearSponsorBlock();

    await player.stop();
    await _openMedia(
      item.url,
      headers: item.headers,
      subtitleUrl: item.subtitleUrl,
      subtitleHeaders: item.headers,
    );
    if (_disposed || !mounted) return;

    _danmakuController.setItems([]);
    _danmakuController.pause();
    _danmakuLoaded = false;
    _activeDanmakuSource = null;
    _activeDanmakuType = null;
    _autoLoadDanmakuIfEnabled();

    if (_disposed || !mounted) return;
    player.setRate(currentRate);
    audioHandler.attachPlayer(
      player,
      title: item.title,
      artist: L10n.current.playerArtistPlaylist,
      artUri: widget.artUri,
    );
    _generateThumbnailForUrl(item.authenticatedUrl ?? item.url);

    // 保存播放列表进度
    try {
      final playlistService = context.read<PlaylistService>();
      await playlistService.updateProgress(
        playlistId: _activePlaylist!.id,
        episodeIndex: index,
        positionMs: 0,
      );
    } catch (_) {}

    _resetHideTimer();

    if (mounted) {
      showAppToast(
        context,
        AppLocalizations.of(context).playerNowPlaying(item.title),
      );
    }
  }

  void _playNextEpisode() {
    if (!_isPlaylistMode) return;
    if (_currentEpisodeIndex < _activePlaylist!.items.length - 1) {
      _switchToEpisode(_currentEpisodeIndex + 1);
    } else {
      // 最后一集播完
      setState(() {
        isFinished = true;
        showControls = true;
      });
    }
  }

  void _playPrevEpisode() {
    if (!_isPlaylistMode) return;
    if (_currentEpisodeIndex > 0) {
      _switchToEpisode(_currentEpisodeIndex - 1);
    }
  }

  // ─── 播放列表：集数切换结束 ───

  /// 供宿主页面（如视频播放页的分P 芯片）切换分P。
  Future<void> switchEpisode(int index) => _switchToEpisode(index);

  /// 是否可自动恢复的 mpv 错误（网络闪断类）：
  /// 项目已配置 lavf reconnect 自动重连，这类错误上报后 mpv 会自行恢复
  /// 播放，弹错误框只会打断观看。仅记日志即可。
  bool _isRecoverableMpvError(String error) {
    final e = error.toLowerCase();
    const patterns = [
      'read failed',
      'failed to read',
      'error reading',
      'http error',
      'http request failed',
      'http fetch error',
      'timed out',
      'timeout',
      'connection reset',
      'connection refused',
      'connection failed',
      'could not connect',
      'network is unreachable',
      'temporary failure',
      'eof',
      'end of file',
      'stream ended',
      'demux',
      'retry',
      'interrupted',
    ];
    return patterns.any(e.contains);
  }

  Future<void> _configureMpvForHttpStream() async {
    final platform = player.platform;
    if (platform is! NativePlayer) return;

    Future<void> set(String key, String value) async {
      try {
        await platform.setProperty(key, value);
      } catch (e) {
        debugPrint('⚠️ setProperty($key) 失败: $e');
      }
    }

    await set(
      'stream-lavf-o',
      'reconnect=1,reconnect_at_eof=1,reconnect_streamed=1,reconnect_delay_max=5',
    );
    await set('demuxer-max-bytes', '128MiB');
    await set('demuxer-max-back-bytes', '64MiB');
//  平滑播放：预读 5 秒数据，避免网络抖动导致频繁卡顿
    await set('demuxer-readahead-secs', '5');
    await set('network-timeout', '30');

    final ps = _playerSettingsService;
    if (ps != null) {
      await set('hwdec', ps.hwdecMode);
      await set('video-sync', ps.videoSync);
    }

//  超分辨率：进入播放页时按设置加载 Anime4K 着色器
    if (ps != null && ps.superResolutionMode != 'disable') {
      await SuperResolutionService.apply(platform, ps.superResolutionMode);
    }
  }

  Future<void> _openMedia(
    String url, {
    Map<String, String>? headers,
    String? subtitleUrl,
    Map<String, String>? subtitleHeaders,
  }) async {
    try {
      _currentSourceUrl = url;
      final hasEmbeddedAuth = _urlHasEmbeddedAuth(url);
      final effectiveHeaders = hasEmbeddedAuth ? null : headers;
      debugPrint('🎬 open: $url  (embeddedAuth=$hasEmbeddedAuth)');
      await player.open(Media(url, httpHeaders: effectiveHeaders));
      debugPrint('✅ open 完成, duration=${player.state.duration}');

      if (subtitleUrl != null && subtitleUrl.isNotEmpty) {
        await _loadExternalSubtitle(
          subtitleUrl,
          hasEmbeddedAuth ? null : subtitleHeaders,
        );
      }
    } catch (e) {
      debugPrint('❌ _openMedia 异常: $e');
    }
  }

  bool _urlHasEmbeddedAuth(String url) {
    try {
      return Uri.parse(url).userInfo.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadExternalSubtitle(
    String url,
    Map<String, String>? headers,
  ) async {
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            Uri.parse(url),
            headers: {
              ...?headers,
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return;

      final dir = await getTemporaryDirectory();
      String ext = 'srt';
      final qIdx = url.indexOf('?');
      final plain = qIdx >= 0 ? url.substring(0, qIdx) : url;
      final dot = plain.lastIndexOf('.');
      final slash = plain.lastIndexOf('/');
      if (dot > slash) {
        final e = plain.substring(dot + 1).toLowerCase();
        if (['srt', 'ass', 'ssa', 'vtt', 'sub'].contains(e)) ext = e;
      }

      final file = File(
        '${dir.path}/navi_sub_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await file.writeAsBytes(resp.bodyBytes);

      if (!mounted) return;
      player.setSubtitleTrack(
        SubtitleTrack.uri(
          file.path,
          title: L10n.current.playerWebdavSubtitle,
          language: 'webdav',
        ),
      );
    } catch (e) {
      debugPrint('字幕加载异常: $e');
    }
  }

  Future<void> _openFromWebDav() async {
    final result = await WebDavFilePickerDialog.show(context);
    if (result == null || !mounted) return;

    setState(() {
      _videoTitle = result.title;
      isFinished = false;
      position = Duration.zero;
      duration = Duration.zero;
      _bufferPosition = Duration.zero;
      _isBuffering = false;
      _lastPlayerError = null;
      _orientationLocked = false;
    });

//  切换来源后清空片头/片尾片段
    _clearSponsorBlock();

    await player.stop();
    await player.stop();
    await _openMedia(
      result.url,
      headers: result.headers,
      subtitleUrl: result.subtitleUrl,
      subtitleHeaders: result.headers,
    );
    if (!mounted) return;

    player.setRate(currentRate);
    audioHandler.attachPlayer(
      player,
      title: result.title,
      artist: L10n.current.playerArtistWebdav,
      artUri: widget.artUri,
    );
    _generateThumbnailForUrl(result.authenticatedUrl ?? result.url);
    _resetHideTimer();

    showAppToast(
      context,
      AppLocalizations.of(context).playerNowPlaying(result.title),
    );
  }

  // ─── DLNA 投屏 ───

  Future<void> _openDlnaCast() async {
    final url = _currentSourceUrl;
    if (url.isEmpty) return;

    // 本地文件：走 DlnaCastPage 的内置 HTTP 服务；http(s)：直接投
    final isHttp = url.startsWith('http://') || url.startsWith('https://');
    final isLocal = !isHttp && File(url).existsSync();

    final displayTitle = _videoTitle;

//  投屏期间暂停本地播放器，避免双端同时出声
    final wasPlaying = player.state.playing;
    if (wasPlaying) player.pause();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DlnaCastPage(
          videoUrl: url,
          title: displayTitle,
          isLocalFile: isLocal,
        ),
      ),
    );

//  返回播放器后：无投屏残留（页面 dispose 已停止服务/投屏），恢复本地播放
    if (mounted && wasPlaying) {
      player.play();
    }
  }

  // ─── 弹幕文件加载 ───

  Future<void> _loadDanmakuFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
    );
    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    final items = await DanmakuParser.parseFile(filePath);
    if (items.isEmpty) {
      if (mounted) {
        showAppToast(context, L10n.current.playerDanmakuNoData);
      }
      return;
    }

    _danmakuController.setItems(items);
    _danmakuController.seekTo(position.inMilliseconds / 1000.0);
    if (player.state.playing) {
      _danmakuController.play();
    }

    if (mounted) {
      setState(() {
        _danmakuLoaded = true;
        _danmakuFileName = result.files.single.name;
      });
      showAppToast(context, L10n.current.playerDanmakuLoaded(items.length));
    }
  }

  Future<void> _fetchDanmakuOnline() async {
    final result = await DanmakuInputDialog.show(context);
    if (result == null || !mounted) return;

    final items = result.items;
    if (items.isEmpty) return;

    _danmakuController.setItems(items);
    _danmakuController.seekTo(position.inMilliseconds / 1000.0);
    if (player.state.playing) {
      _danmakuController.play();
    }

    if (result.source != null) {
      _activeDanmakuSource = result.source;
      _activeDanmakuType = result.sourceType;
    }

    setState(() {
      _danmakuLoaded = true;
      _danmakuFileName = result.fromCache
          ? L10n.current.playerDanmakuCache(items.length)
          : L10n.current.playerDanmakuOnline(items.length);
    });

//  手动加载弹幕后若得到 BV，也尝试查询片头/片尾
    _maybeQuerySponsorBlock();

    showAppToast(
      context,
      result.fromCache
          ? L10n.current.playerDanmakuLoadedFromCache(items.length)
          : L10n.current.playerDanmakuLoadedOnline(items.length),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final settings = Provider.of<SettingsService>(context, listen: false);
//  仅全屏模式后台自动画中画
      if (_isFullscreen &&
          settings.autoPiPOnBackground &&
          player.state.playing) {
        _enterPiP();
      }
    }
  }

  Future<void> _generateThumbnail() async {
    await _generateThumbnailForUrl(widget.videoUrl);
  }

  /// 是否本地文件路径（远程 URL 返回 false）。
  bool _isLocalVideoPath(String url) {
    try {
      final uri = Uri.parse(url);
      final scheme = uri.scheme.toLowerCase();
      // file:// 或 http(s)/ftp 之外的未知协议 → 视为本地路径
      if (scheme == 'file') return true;
      if (scheme.isNotEmpty && scheme.length > 1) return false;
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _generateThumbnailForUrl(String url) async {
//  修复：仅本地文件生成封面。远程 URL（WebDAV / HTTP / B 站）用
    //   VideoThumbnail 会整段拉取视频流，与 mpv 抢占带宽和 CPU，
    //   导致「加载视频非常卡」；本地文件解码快，不影响播放。
    if (!_isLocalVideoPath(url)) return;
    try {
      final thumb = await VideoThumbnail.thumbnailFile(
        video: url,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
      );
      if (thumb != null && mounted) {
        setState(() => _thumbnailPath = thumb);
        audioHandler.attachPlayer(
          player,
          title: _videoTitle,
          artist: _mediaArtist,
          artUri: 'file://$thumb',
        );
      }
    } catch (e) {
      debugPrint('封面生成失败: $e');
    }
  }

  @override
  void deactivate() {
    _disposed = true;
    _saveProgressOnExit();
    // 退出时把最终进度回调给上一级页面（内嵌播放器据此同步进度）
    widget.onExit?.call(position);
    super.deactivate();
  }

  @override
  void dispose() {
    _playerSettingsService?.removeListener(_onPlayerSettingsChanged);
    _releaseWindowAspectLock();
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _keyHoldTimer?.cancel();
    _historySaveTimer?.cancel();
    _screenshotTimer?.cancel();
    _doubleTapTimer?.cancel();
    _speedCalcTimer?.cancel();
    _statsTimer?.cancel();
    _skipPromptTimer?.cancel();
    _danmakuPlayingSub?.cancel();
    _danmakuPositionSub?.cancel();
    _mpvLogSub?.cancel();
    // 智能防遮挡：停取帧、清遮罩、释放推理 isolate
    _smartMaskTimer?.cancel();
    _danmakuController.setPersonMask(null);
    _smartMaskService?.dispose();
    if (_ownsDanmakuController) {
      _danmakuController.dispose();
    }
    _focusNode.dispose();

    if (Platform.isAndroid && _isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
    }
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }

    if (Platform.isAndroid || Platform.isIOS) {
      _brightnessChannel.invokeMethod('resetBrightness');
    }

//  清除系统媒体控件的页面回调，避免 stop() 之后触发已销毁页面的方法
    audioHandler
      ..onSkipToNext = null
      ..onSkipToPrevious = null;
    audioHandler.stop();
    player.dispose();
    _statsChannel.setMethodCallHandler(null);
    super.dispose();
  }

  void _saveProgressOnExit() {
//  外部「打开方式」播放的内容不记录任何播放历史
    if (!widget.recordHistory) {
      debugPrint('🚫 外部打开的视频，跳过播放历史记录');
      return;
    }
//  无痕模式：不记录任何历史、不上报 B 站（用户需求）
    if (_settingsService?.incognitoMode ?? false) {
      debugPrint('🕵️ 无痕模式，跳过历史记录与 B 站上报');
      return;
    }

    final history = _historyService;
    if (history == null) {
      debugPrint('⚠️ PlayHistoryService 未缓存，跳过保存');
      return;
    }

    final posMs = position.inMilliseconds;
    final durMs = duration.inMilliseconds;

//  保存播放列表进度
    if (_isPlaylistMode && _activePlaylist != null) {
      try {
        final playlistService = context.read<PlaylistService>();
        playlistService.updateProgress(
          playlistId: _activePlaylist!.id,
          episodeIndex: _currentEpisodeIndex,
          positionMs: posMs,
        );
      } catch (_) {}
    }

    if (posMs > 3000 && durMs > 0) {
      //    本地播放历史始终保存（无 Cookie / 非 B 站视频走本地）。
      _reportBiliProgressIfNeeded(posMs);
      debugPrint('💾 保存进度: pos=${posMs}ms, dur=${durMs}ms, title=$_videoTitle');
      _saveHistoryNow(widget.historyId);
//  记录观看历史足迹（bvid + 退出时间，区别于进度恢复）
      _recordWatchHistory(posMs, durMs);
    }
  }

  /// 把当前播放进度写入本地播放历史（退出 / 切分P / 定时保存共用）。
  /// [historyId] 为稳定历史 ID（B站 bvid+cid）；为空时按 videoUrl 生成。
  void _saveHistoryNow(String? historyId) {
//  外部「打开方式」播放的内容不记录任何播放历史
    if (!widget.recordHistory) return;
//  无痕模式：不写入本地进度恢复
    if (_settingsService?.incognitoMode ?? false) return;
    final history = _historyService;
    if (history == null) return;
    final posMs = position.inMilliseconds;
    final durMs = duration.inMilliseconds;
    if (posMs <= 3000 || durMs <= 0) return;
    history.saveProgress(
      id: historyId,
      videoUrl: widget.videoUrl,
      title: _videoTitle,
      positionMs: posMs,
      durationMs: durMs,
      thumbnailPath: _thumbnailPath,
      httpHeaders: widget.httpHeaders,
      subtitleUrl: widget.subtitleUrl,
      danmakuSource: _activeDanmakuSource ?? widget.danmakuSource,
      danmakuType: _activeDanmakuType ?? widget.danmakuType,
    );
  }

  /// B 站视频且已登录（携带 Cookie）时，把当前进度上报到 B 站。
  /// 未登录 / 未携带 Cookie 时只走本地保存（见 _saveProgressOnExit）。
  void _reportBiliProgressIfNeeded(int posMs) {
//  无痕模式：不上报 B 站播放进度
    if (_settingsService?.incognitoMode ?? false) return;
    final bvid = widget.bilibiliBvid;
    if (bvid == null || bvid.isEmpty) return;
    final cid = int.tryParse(
      _activeDanmakuSource ?? widget.danmakuSource ?? '',
    );
    if (cid == null || cid <= 0) return;
    final aid = BvAv.decode(bvid);
    if (aid == null) return;
    BilibiliVideoService.reportProgress(
      bvid: bvid,
      aid: aid,
      cid: cid,
      position: Duration(milliseconds: posMs),
    );
  }

  /// 记录观看历史足迹（退出视频时调用，区别于进度恢复）。
  /// 仅 B 站视频（有 bvid）记录；非 B 站本地/WebDAV 视频走进度恢复即可。
  void _recordWatchHistory(int posMs, int durMs) {
    final wh = _watchHistoryService;
    if (wh == null) return;
    final bvid = widget.bilibiliBvid;
    if (bvid == null || bvid.isEmpty) return;
    final aid = BvAv.decode(bvid);
    final cid = int.tryParse(_activeDanmakuSource ?? widget.danmakuSource ?? '');
    wh.record(WatchHistoryEntry(
      bvid: bvid,
      aid: aid,
      cid: cid,
      title: _videoTitle,
      coverUrl: widget.coverUrl ?? _thumbnailPath,
      upperName: widget.artist,
      positionMs: posMs,
      durationMs: durMs,
      watchedAt: DateTime.now(),
    ));
  }

  void _toggleControls() {
    setState(() => showControls = !showControls);
    _resetHideTimer();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (showControls && !isFinished) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted &&
            !isDragging &&
            !isLongPressing &&
            !_isAdjustingBrightness &&
            !_isAdjustingVolume &&
            !_showSettingsPanel &&
            !_showSubtitlePanel &&
            !_showDanmakuPanel &&
            !_showEpisodePanel) {
          setState(() => showControls = false);
        }
      });
    }
  }

  /// 底部播放/暂停按钮：仅切换本地播放状态。
  void _togglePlayPause() {
    if (player.state.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  void _handleTap() {
//  非全屏内嵌播放器：点击视频区后把焦点还给播放器，
    //    保证「长按 D / → 倍速、方向键快进」等快捷键持续可用
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTapTimestamp < _doubleTapThresholdMs) {
      _lastTapTimestamp = 0;
      _handleDoubleTap();
    } else {
      _lastTapTimestamp = now;
      Future.delayed(const Duration(milliseconds: _doubleTapThresholdMs), () {
        if (_lastTapTimestamp == now && mounted) {
          _toggleControls();
        }
      });
    }
  }

  void _handleDoubleTap() {
    final isPlaying = player.state.playing;
    if (isPlaying) {
      player.pause();
      setState(() => _doubleTapIcon = Icons.pause);
    } else {
      player.play();
      setState(() => _doubleTapIcon = Icons.play_arrow);
    }
    _doubleTapTimer?.cancel();
    _doubleTapTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _doubleTapIcon = null);
    });
  }

  void _changeRate(double rate) {
    setState(() {
      currentRate = rate;
      player.setRate(rate);
    });
  }

  /// 切换清晰度：从已下发的 playurl（含全部 DASH 流）直接用新画质重建
  /// 播放地址并重开当前媒体，无需重新请求；保留播放进度与倍速。
  /// 处于非初始分P时（playurl 已不对应当前集），按当前集重新解析。
  Future<void> _switchQuality(int qn) async {
    if (qn == _currentQn) return;
//  先检查该画质是否可用（playurl 未下发对应 DASH 流 = 会员/未解锁）
    final info = widget.playUrlInfo;
    if (info != null && !info.isQualityAvailable(qn)) {
      if (mounted) {
        showAppToast(
          context,
          AppLocalizations.of(context).playerQualityLocked,
          error: true,
        );
      }
      return;
    }
    final url = await _resolveQualityUrl(qn);
    if (url == null) {
      if (mounted) {
        showAppToast(context, '切换画质失败', error: true);
      }
      return;
    }
    final wasPlaying = player.state.playing;
    final resume = position;
    await player.stop();
    await _openMedia(
      url,
      headers: widget.httpHeaders,
      subtitleUrl: widget.subtitleUrl,
      subtitleHeaders: widget.httpHeaders,
    );
    if (_disposed || !mounted) return;
    setState(() => _currentQn = qn);
    widget.onQualityChanged?.call(qn);
    // 恢复进度与倍速
    if (resume > Duration.zero) {
      await _seekToReady(resume);
    }
    if (_disposed || !mounted) return;
    player.setRate(currentRate);
    if (wasPlaying) player.play();
    _resetHideTimer();
  }

  /// 解析指定画质的播放地址。
  ///   - 当前集 == 初始集：直接用已下发的 playUrlInfo 换流（无网络请求）
  ///   - 其他分P：按当前集的 bvid/cid 重新拉取 playurl
  Future<String?> _resolveQualityUrl(int qn) async {
    final preferCodecs = _codecPrefixes(_decodeFormat);
    if (_currentEpisodeIndex == widget.initialEpisodeIndex &&
        widget.playUrlInfo != null) {
      return BilibiliVideoService.buildPlayableUrl(
        widget.playUrlInfo!,
        quality: qn,
        preferCodecs: preferCodecs,
        sourceIndex: _sourceIndex,
        sourceHost: _sourceHost,
      );
    }
    final item = _activePlaylist?.items[_currentEpisodeIndex];
    final cid = int.tryParse(item?.danmakuSource ?? '');
    final id = _activePlaylist?.id ?? '';
    String? bvid;
    if (id.startsWith('bili_')) {
      final bv = id.substring(5);
      if (bv.isNotEmpty) bvid = bv;
    }
    if (bvid == null || cid == null) return null;
    final play = await BilibiliVideoService.fetchPlayUrl(
      bvid: bvid,
      cid: cid,
      qn: qn,
    );
    return play == null
        ? null
        : BilibiliVideoService.buildPlayableUrl(
            play,
            quality: qn,
            preferCodecs: preferCodecs,
            sourceIndex: _sourceIndex,
            sourceHost: _sourceHost,
          );
  }

  /// 播放地址（同一画质下按编码偏好挑选 DASH 视频轨），保留进度与倍速。
  Future<void> _setDecodeFormat(String fmt) async {
    if (fmt == _decodeFormat || !_started) return;
    setState(() => _decodeFormat = fmt);
    final playerSettings = _playerSettingsService;
    if (playerSettings != null && playerSettings.preferredDecodeFormat != fmt) {
      playerSettings.setPreferredDecodeFormat(fmt);
    }
    final wasPlaying = player.state.playing;
    final resume = position;
    final url = await _resolveQualityUrl(_currentQn);
    if (url == null) {
      if (mounted) {
        showAppToast(
          context,
          L10n.current.playerDecodeFormatSwitchFailed,
          error: true,
        );
      }
      return;
    }
    await player.stop();
    await _openMedia(
      url,
      headers: widget.httpHeaders,
      subtitleUrl: widget.subtitleUrl,
      subtitleHeaders: widget.httpHeaders,
    );
    if (!mounted) return;
    if (resume > Duration.zero) await _seekToReady(resume);
    player.setRate(currentRate);
    if (wasPlaying) player.play();
    _resetHideTimer();
  }

  List<String>? _codecPrefixes(String fmt) {
    switch (fmt) {
      case 'avc':
        return const ['avc1'];
      case 'hevc':
        return const ['hev1', 'hvc1'];
      case 'av1':
        return const ['av01'];
      default:
        return null;
    }
  }

  String _decodeFormatLabel(String fmt) => switch (fmt) {
    'avc' => L10n.current.playerDecodeAvc,
    'hevc' => L10n.current.playerDecodeHevc,
    'av1' => L10n.current.playerDecodeAv1,
    _ => L10n.current.playerDecodeAuto,
  };

  /// 当前画质下可用的解码格式列表（从 playurl support_formats.codecs 提取，
  /// 映射到 AVC / HEVC / AV1；无法判断时返回空列表）。
  List<String> _availableDecodeFormats() {
    final info = widget.playUrlInfo;
    if (info == null) return const [];
    final codecs = info.codecsForQuality(_currentQn);
    if (codecs.isEmpty) return const [];
    final result = <String>[];
    const mapping = {
      'avc1': 'avc',
      'hev1': 'hevc',
      'hvc1': 'hevc',
      'av01': 'av1',
    };
    for (final c in codecs) {
      final lower = c.toLowerCase();
      for (final entry in mapping.entries) {
        if (lower.startsWith(entry.key) && !result.contains(entry.value)) {
          result.add(entry.value);
        }
      }
    }
    return result;
  }

  /// SRT 后挂载到播放器；null = 关闭字幕。
  Future<void> _selectBiliSubtitle(BiliSubtitle? sub) async {
    if (sub == null) {
      setState(() => _activeBiliSubtitle = null);
      player.setSubtitleTrack(SubtitleTrack.no());
      _resetHideTimer();
      return;
    }
    setState(() => _biliSubtitleLoading = true);
    final path = await BilibiliVideoService.fetchSubtitleSrt(sub.url);
    if (!mounted) return;
    setState(() => _biliSubtitleLoading = false);
    if (path == null) {
      showAppToast(
        context,
        AppLocalizations.of(context).playerSubtitleLoadFailed,
        error: true,
      );
      return;
    }
    setState(() => _activeBiliSubtitle = sub);
    player.setSubtitleTrack(
      SubtitleTrack.uri(path, title: sub.lanDoc, language: sub.lan),
    );
    _resetHideTimer();
  }

  /// 视频播放页模式：autoPlay=false 时点击封面开始播放。
  Future<void> _startPlaybackFromCover() async {
    if (_started) return;
    await _openMedia(
      widget.videoUrl,
      headers: widget.httpHeaders,
      subtitleUrl: widget.subtitleUrl,
      subtitleHeaders: widget.httpHeaders,
    );
    if (!mounted) return;
    setState(() => _started = true);
    // 断点续播（视频页封面模式）：宿主传入进度优先，否则本地历史兜底
    final resumeAt = _effectiveInitialPosition;
    if (resumeAt != null) {
      await _seekToReady(resumeAt);
      if (_disposed || !mounted) return;
    }
    player.setRate(currentRate);
    audioHandler.attachPlayer(
      player,
      title: _videoTitle,
      artist: _mediaArtist,
      artUri: widget.artUri,
    );
    _autoLoadDanmakuIfEnabled();
    _maybeQuerySponsorBlock();
    _resetHideTimer();
  }

  /// 有效初始进度：宿主传入（空降/历史页跳转）优先；否则 B 站视频按
  /// 稳定 historyId（bvid+cid）从本地播放历史兜底恢复 —— 保证从任何入口
  /// 点开同一视频都能智能续播（未登录也生效，无需专门去历史记录页）。
  Duration? get _effectiveInitialPosition {
    final fromWidget = widget.initialPosition;
    if (fromWidget != null && fromWidget > Duration.zero) {
      return fromWidget;
    }
    final hid = widget.historyId;
    if (hid != null && hid.isNotEmpty) {
      final rec = _historyService?.findById(hid);
      if (rec != null && rec.positionMs > 3000 && !rec.isFinished) {
        return Duration(milliseconds: rec.positionMs);
      }
    }
    return null;
  }

  /// 等待媒体就绪后 seek（进度恢复用，避免慢速网络下 seek 无效）。
  Future<void> _seekToReady(Duration target) async {
    if (target <= Duration.zero) return;
    Duration? ready;
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_disposed || !mounted) return;
      if (player.state.duration > Duration.zero) {
        ready = player.state.duration;
        break;
      }
    }
    if (_disposed || !mounted || ready == null) return;
    final clamped = target > ready ? ready : target;
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_disposed || !mounted) return;
      if (!player.state.buffering) break;
    }
    if (_disposed || !mounted) return;
    player.seek(clamped);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!_disposed &&
        mounted &&
        player.state.position.inMilliseconds < 1000 &&
        clamped.inMilliseconds > 3000) {
      player.seek(clamped);
    }
  }

  Future<void> _enterPiP() async {
    try {
      await _pipChannel.invokeMethod('enterPiP');
    } on PlatformException catch (e) {
      if (mounted) {
        showAppToast(
          context,
          AppLocalizations.of(context).playerPipFailed(e.message ?? ''),
        );
      }
    }
  }

  /// 处理顶栏「⋮ 更多」菜单项。
  void _handleMoreMenu(String action) {
    setState(() {
      _showSettingsPanel = false;
      _showSubtitlePanel = false;
      _showDanmakuPanel = false;
      _showEpisodePanel = false;
    });
    switch (action) {
      case 'rotate':
        setState(() => _rotation += math.pi / 2);
        break;
      case 'webdav':
        _openFromWebDav();
        break;
      case 'cast':
        _openDlnaCast();
        break;
      case 'pip':
        _enterPiP();
        break;
      case 'settings':
        setState(() => _showSettingsPanel = true);
        break;
    }
  }

  void _seek(double ratio) {
    final ms = (ratio * duration.inMilliseconds).toInt().clamp(
      0,
      duration.inMilliseconds,
    );
    final target = Duration(milliseconds: ms);
    // 往回拖（目标 ≤ 真实播放位置）：所需数据已在缓存/已解码范围内，
    // mpv 不会真正重新缓冲；抑制 seek 触发的短暂 buffering 上报，
    // 避免误显示加载动画（往前拖超出缓存仍需缓冲，不做抑制）。
    if (target <= player.state.position) {
      _bufferingSuppressUntil = DateTime.now().add(
        const Duration(milliseconds: 800),
      );
      if (mounted) setState(() => _isBuffering = false);
    }
    player.seek(target);
  }


  /// 开始横向滑动：记录起点、显示拖动指示。
  void _startHorizontalSeek() {
    if (duration.inMilliseconds <= 0) return;
    setState(() {
      _seekGestureActive = true;
      isDragging = true;
      dragPosition = position;
    });
  }

  /// 横向滑动中：按拖动距离占播放器宽度比例换算目标时长。
  void _updateHorizontalSeek(double dx) {
    final totalMs = duration.inMilliseconds;
    if (totalMs <= 0) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? MediaQuery.of(context).size.width;
    if (width <= 0) return;
    final deltaMs = (dx / width * totalMs).round();
    final target = (dragPosition.inMilliseconds + deltaMs).clamp(0, totalMs);
    setState(() {
      dragPosition = Duration(milliseconds: target);
//  让底部进度条拇指跟随滑动目标（isDragging 期间不会被播放流覆盖）
      position = dragPosition;
    });
  }

  /// 结束横向滑动：定位并同步弹幕。
  void _endHorizontalSeek() {
    if (!_seekGestureActive) return;
    final ratio = duration.inMilliseconds > 0
        ? (dragPosition.inMilliseconds / duration.inMilliseconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;
    _seek(ratio);
    if (_danmakuLoaded) {
      _danmakuController.seekTo(dragPosition.inMilliseconds / 1000.0);
    }
    setState(() {
      _seekGestureActive = false;
      isDragging = false;
      position = dragPosition;
      _resetHideTimer();
    });
  }


  /// 长按开始：立即 2x 播放，松开恢复（全屏 / 非全屏共用）。
  void _startLongPressSpeed(PlayerSettingsService playerSettings) {
    if (!playerSettings.enableLongPressSpeed) return;
    final allowInImmersive =
        playerSettings.longPressInImmersive || showControls;
    if (!isDragging && !_seekGestureActive && allowInImmersive) {
      setState(() {
        isLongPressing = true;
        previousRate = currentRate;
        player.setRate(2.0);
      });
    }
  }

  /// 长按结束：恢复长按前的倍速。
  void _endLongPressSpeed() {
    if (isLongPressing) {
      setState(() {
        isLongPressing = false;
        player.setRate(previousRate);
      });
    }
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec <= 0) return '0 KB/s';
    if (bytesPerSec < 1024) return '${bytesPerSec.toInt()} B/s';
    if (bytesPerSec < 1024 * 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  String _formatBitrate(int bitsPerSec) {
    if (bitsPerSec <= 0) return '—';
    if (bitsPerSec < 1000) return '$bitsPerSec bps';
    if (bitsPerSec < 1000 * 1000) {
      return '${(bitsPerSec / 1000).toStringAsFixed(0)} Kbps';
    }
    return '${(bitsPerSec / (1000 * 1000)).toStringAsFixed(2)} Mbps';
  }

  String _fitLabel(BoxFit fit) => switch (fit) {
    BoxFit.contain => L10n.current.playerFitAdapt,
    BoxFit.fill => L10n.current.playerFitStretch,
    BoxFit.cover => L10n.current.playerFitFill,
    _ => L10n.current.commonUnknown,
  };

  String _endBehaviorLabel(EndBehavior b) => switch (b) {
    EndBehavior.pause => L10n.current.playerEndPause,
    EndBehavior.loop => L10n.current.playerEndLoop,
    EndBehavior.exit => L10n.current.playerEndExit,
  };

  IconData _endBehaviorIcon(EndBehavior b) => switch (b) {
    EndBehavior.pause => Icons.pause_circle_outline,
    EndBehavior.loop => Icons.repeat,
    EndBehavior.exit => Icons.exit_to_app,
  };

  void _replay() {
    setState(() {
      isFinished = false;
    });
    player.seek(Duration.zero);
    player.play();
    _resetHideTimer();
  }

  void _resetScreenshotTimer() {
    _screenshotTimer?.cancel();
    _screenshotTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showScreenshotPreview = false);
    });
  }

  // ─── 智能防遮挡：取视频帧 → 后台 isolate 推理主体遮罩 ───
  // 每次取 320 宽的小图（模型输入 320×320），推理在常驻 isolate 中进行，
  // 不阻塞 UI；暂停/缓冲时冻结当前遮罩（保持最后状态，不重复推理）。
  Future<void> _smartMaskTick() async {
    if (_disposed || !_started || !_danmakuLoaded) return;
    if (!_danmakuController.enabled || !_danmakuController.smartMask) {
      if (_danmakuController.personMask != null) {
        _danmakuController.setPersonMask(null);
      }
      return;
    }
    if (!player.state.playing || _isBuffering || isFinished) return;
    if (_smartMaskBusy) return;

    final ctx = _repaintKey.currentContext;
    final ro = ctx?.findRenderObject();
    if (ro is! RenderRepaintBoundary || !ro.attached || ro.size.isEmpty) {
      return;
    }

    _smartMaskBusy = true;
    try {
      final ratio = 320.0 / ro.size.width;
      final frame = await ro.toImage(pixelRatio: ratio);
      final w = frame.width, h = frame.height;
      final data = await frame.toByteData(format: ui.ImageByteFormat.rawRgba);
      frame.dispose();
      if (data == null || w <= 0 || h <= 0 || _disposed) return;

      final svc = _smartMaskService ??= DanmakuSmartMaskService();
      if (svc.isBroken) {
        _danmakuController.setPersonMask(null);
        return;
      }
      final result = await svc.infer(data.buffer.asUint8List(), w, h);
      if (_disposed) return;
      // 推理期间用户可能已关掉开关
      if (!_danmakuController.smartMask) {
        _danmakuController.setPersonMask(null);
        return;
      }
      _danmakuController.setPersonMask(result?.image);
    } catch (e) {
      debugPrint('[SmartMask] 取帧/推理失败: $e');
    } finally {
      _smartMaskBusy = false;
    }
  }

  /// 捕获当前视频画面为 PNG 字节（可选叠加弹幕层）；供评论区
  /// 「视频截图」等外部功能复用（不落盘、不弹预览）。失败返回 null。
  Future<Uint8List?> captureCurrentFrame() async {
    try {
      final playerSettings = context.read<PlayerSettingsService>();
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final boundaryCtx = _repaintKey.currentContext;
      if (boundaryCtx == null) return null;
      final boundary =
          boundaryCtx.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      // 截图时显示弹幕：把当前弹幕层（透明背景）合成到视频画面上
      if (playerSettings.showDanmakuInScreenshot && _danmakuLoaded) {
        final danmakuRender = _danmakuRepaintKey.currentContext
            ?.findRenderObject();
        if (danmakuRender is RenderRepaintBoundary) {
          try {
            final danmakuImage = await danmakuRender.toImage(
              pixelRatio: pixelRatio,
            );
            if (danmakuImage.width > 0 && danmakuImage.height > 0) {
              final recorder = ui.PictureRecorder();
              final canvas = ui.Canvas(recorder);
              canvas.drawImage(image, ui.Offset.zero, ui.Paint());
              canvas.drawImageRect(
                danmakuImage,
                ui.Rect.fromLTWH(
                  0,
                  0,
                  danmakuImage.width.toDouble(),
                  danmakuImage.height.toDouble(),
                ),
                ui.Rect.fromLTWH(
                  0,
                  0,
                  image.width.toDouble(),
                  image.height.toDouble(),
                ),
                ui.Paint(),
              );
              final picture = recorder.endRecording();
              final composited = await picture.toImage(
                image.width,
                image.height,
              );
              image.dispose();
              image = composited;
            }
            danmakuImage.dispose();
          } catch (_) {
            // 弹幕合成失败时回退为纯视频截图
          }
        }
      }

      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();
      if (byteData == null) return null;
      return byteData.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _takeScreenshot() async {
    final pngBytes = await captureCurrentFrame();
    if (pngBytes == null) {
      if (mounted) {
        showAppToast(
          // ignore: use_build_context_synchronously
          context,
          L10n.current.playerScreenshotFailed('capture'),
        );
      }
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      setState(() {
        _screenshotFile = file;
        _showScreenshotPreview = true;
      });
      _resetScreenshotTimer();
    } catch (e) {
      if (mounted) {
        showAppToast(context, L10n.current.playerScreenshotFailed('$e'));
      }
    }
  }

  Future<void> _saveScreenshot() async {
    if (_screenshotFile != null) {
      try {
        await Gal.putImage(_screenshotFile!.path);
        if (mounted) {
          showAppToast(context, L10n.current.playerSavedToAlbum);
        }
        final fileName = _screenshotFile!.path.split('/').last;
        await NotificationService().showScreenshotNotification(
          imagePath: _screenshotFile!.path,
          message: L10n.current.playerScreenshotSavedToAlbum(fileName),
        );
      } catch (e) {
        if (mounted) {
          showAppToast(
            context,
            AppLocalizations.of(context).playerSaveFailed(e.toString()),
          );
        }
      }
    }
    _screenshotTimer?.cancel();
    if (mounted) setState(() => _showScreenshotPreview = false);
  }

  Widget _buildSubtitlePanel() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 0,
      bottom: 0,
      right: _showSubtitlePanel ? 0 : -320,
      width: 320,
      child: Material(
        color: Colors.black87,
        elevation: 8,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      L10n.current.playerSubtitleSettings,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () =>
                          setState(() => _showSubtitlePanel = false),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: SingleChildScrollView(
                  child: SubtitlePanel(
                    player: player,
                    fontSize: _subFontSize,
                    fontColor: _subColor,
                    bgColor: _subBgColor,
                    onFontSizeChanged: (v) => setState(() => _subFontSize = v),
                    onFontColorChanged: (c) => setState(() => _subColor = c),
                    onBgColorChanged: (c) => setState(() => _subBgColor = c),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(SettingsService settings) {
    final playerSettings = context.watch<PlayerSettingsService>();
    // 设置面板为常驻深色（black87），下拉菜单强制深色配色保证白字可读
    final panelMenuScheme = ColorScheme.fromSeed(
      seedColor: Theme.of(context).colorScheme.primary,
      brightness: Brightness.dark,
    );
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 0,
      bottom: 0,
      right: _showSettingsPanel ? 0 : -320,
      width: 320,
      child: Material(
        color: Colors.black87,
        elevation: 8,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      L10n.current.playerAdvancedSettings,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () =>
                          setState(() => _showSettingsPanel = false),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    SwitchListTile(
                      title: Text(
                        L10n.current.playerFlipHorizontal,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        L10n.current.playerFlipHorizontalDesc,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      value: isFlipX,
                      activeColor: Colors.blue,
                      onChanged: (val) => setState(() => isFlipX = val),
                    ),
                    SwitchListTile(
                      title: Text(
                        L10n.current.playerFlipVertical,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        L10n.current.playerFlipVerticalDesc,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      value: isFlipY,
                      activeColor: Colors.blue,
                      onChanged: (val) => setState(() => isFlipY = val),
                    ),
                    const Divider(color: Colors.white24),
                    SwitchListTile(
                      title: Text(
                        L10n.current.playerShowStats,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        L10n.current.playerShowStatsDesc,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      value: Platform.isWindows ? false : settings.showPlayerStats,
                      activeColor: Colors.blue,
                      onChanged: (val) {
                        if (Platform.isWindows) {
                          // Windows 上 OSD 浮层不渲染，改用原生 TaskDialog 显示统计信息
                          _showStatsNativeDialog();
                        } else {
                          settings.setShowPlayerStats(val);
                        }
                      },
                    ),
                    SwitchListTile(
                      title: Text(
                        L10n.current.playerAutoPip,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      value: settings.autoPiPOnBackground,
                      activeColor: Colors.blue,
                      onChanged: (val) => settings.setAutoPiPOnBackground(val),
                    ),
                    SwitchListTile(
                      title: Text(
                        L10n.current.playerLoadDanmakuOnResume,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        L10n.current.playerLoadDanmakuOnResumeDesc,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      value: playerSettings.loadDanmakuOnResume,
                      activeColor: Colors.blue,
                      onChanged: (val) =>
                          playerSettings.setLoadDanmakuOnResume(val),
                    ),
                    const Divider(color: Colors.white24),
                    ListTile(
                      title: Text(
                        L10n.current.playerDefaultRate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      trailing: MorphGlassDropdown<double>(
                        value: settings.playerDefaultRate,
                        menuColorScheme: panelMenuScheme,
                        items: [0.5, 1.0, 1.25, 1.5, 2.0, 3.0]
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(
                                  '${r}x',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            settings.setPlayerDefaultRate(val);
                            _changeRate(val);
                          }
                        },
                      ),
                    ),
                    ListTile(
                      title: Text(
                        L10n.current.playerDefaultEndBehavior,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      trailing: MorphGlassDropdown<String>(
                        value: settings.playerEndBehavior,
                        menuColorScheme: panelMenuScheme,
                        items: ['pause', 'loop', 'exit']
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(
                                  _endBehaviorLabel(_stringToEndBehavior(b)),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            settings.setPlayerEndBehavior(val);
                            setState(
                              () => endBehavior = _stringToEndBehavior(val),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDanmakuPanel() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 0,
      bottom: 0,
      right: _showDanmakuPanel ? 0 : -320,
      width: 320,
      child: Material(
        color: Colors.black87,
        elevation: 8,
        child: DanmakuSettingsPanel(
          controller: _danmakuController,
          onClose: () => setState(() => _showDanmakuPanel = false),
          onLoadFile: _loadDanmakuFile,
          onFetchOnline: _fetchDanmakuOnline,
        ),
      ),
    );
  }

  /// 弹幕设置入口：
  /// - 全屏：沿用侧边面板
  void _toggleDanmakuSettings() {
    if (_isFullscreen) {
      setState(() {
        _showDanmakuPanel = !_showDanmakuPanel;
        _showSubtitlePanel = false;
        _showSettingsPanel = false;
      });
      return;
    }
    showDanmakuSettingsSheet(
      context,
      _danmakuController,
      onLoadFile: _loadDanmakuFile,
      onFetchOnline: _fetchDanmakuOnline,
    );
  }

  /// 点击跳转到对应进度；仅非全屏（本菜单就只在非全屏顶栏出现）。
  void _showDanmakuList() {
    showDanmakuListSheet(
      context,
      _danmakuController,
      onSeek: (seconds) => player.seek(Duration(milliseconds: (seconds * 1000).round())),
      currentPosition: () =>
          player.state.position.inMilliseconds / 1000.0,
    );
  }

  /// 点击以专栏形式打开正文；仅 B 站 UGC 视频源可用。
  void _showVideoNotes() {
    final bvid = widget.bilibiliBvid;
    if (bvid == null || bvid.isEmpty) return;
    final aid = BvAv.decode(bvid);
    if (aid == null || aid <= 0) {
      showAppToast(context, L10n.current.playerNotesLoadFailed);
      return;
    }
    showBiliNoteListSheet(
      context,
      aid: aid,
      bvid: bvid,
      videoTitle: widget.title,
    );
  }

  /// 内容自动存本地草稿，仅不能发布。
  void _writeVideoNote() {
    final bvid = widget.bilibiliBvid;
    if (bvid == null || bvid.isEmpty) return;
    final aid = BvAv.decode(bvid);
    if (aid == null || aid <= 0) return;
    showNoteEditorPage(
      context,
      bvid: bvid,
      aid: aid,
      videoTitle: widget.title,
    );
  }

  Widget _buildSkipPrompt() {
    final l10n = AppLocalizations.of(context);
    final seg = _activeSkipSegment!;
    final label = seg.category == 'intro' ? l10n.skipIntro : l10n.skipOutro;
    return GestureDetector(
      onTap: _skipActiveSegment,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.cyanAccent.withOpacity(0.6),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fast_forward, size: 18, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBufferingIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.72),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingIndicatorM3E(
              variant: LoadingIndicatorM3EVariant.defaultStyle,
              constraints: BoxConstraints(
                minWidth: 64.0,
                minHeight: 64.0,
                maxWidth: 64.0,
                maxHeight: 64.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _formatSpeed(_networkSpeedBps),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              L10n.current.playerBuffering,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverlay() {
    return Positioned(
      top:
          (context.watch<PlayerSettingsService>().showFakeStatusBar
              ? kFakeStatusBarHeight
              : 0.0) +
          40,
      left: 16,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (label, value) in _statsEntries())
                _statsRow(label, value),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                height: 1.3,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 播放画面层（全屏 / 视频播放页共用） ───
  Widget _buildVideoLayer() {
    Widget videoLayer = RepaintBoundary(
      key: _repaintKey,
      child: Video(
        controller: controller,
//  退后台继续播放（media_kit_video 默认会在退后台时自动暂停）
        pauseUponEnteringBackgroundMode: false,
        fit: currentFit,
        width: double.infinity,
        height: double.infinity,
        controls: (state) => const SizedBox.shrink(),
        subtitleViewConfiguration: SubtitleViewConfiguration(
          visible: true,
          style: TextStyle(
            height: 1.4,
            fontSize: _subFontSize,
            color: _subColor,
            backgroundColor: _subBgColor,
            shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
      ),
    );
    videoLayer = Transform.flip(
      flipX: isFlipX,
      flipY: isFlipY,
      child: videoLayer,
    );
    videoLayer = Transform.rotate(
      angle: _rotation,
      child: Transform.scale(scale: _scale, child: videoLayer),
    );
    return videoLayer;
  }

  // ─── 画质菜单（检查可用性：playurl 未下发对应 DASH 流 = 锁定/会员画质） ───
  Widget _buildQualityMenu() {
    final info = widget.playUrlInfo;
    if (info == null || info.qualities.isEmpty) {
      return const SizedBox.shrink();
    }
    return LiquidGlassMenuButton(
      icon: Icons.high_quality_outlined,
      iconColor: Colors.white,
      useMorphStyle: false,
      iconSize: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tooltip: L10n.current.playerQuality,
      menuWidth: 220,
      actions: _qualityMenuActions(),
    );
  }

  /// 画质菜单项列表（底部画质按钮与右上角「换源」子菜单共用）。
  List<GlassMenuAction> _qualityMenuActions() {
    final info = widget.playUrlInfo;
    if (info == null || info.qualities.isEmpty) return const [];
    return [
      for (final q in info.qualities)
        GlassMenuAction(
          icon: Icons.high_quality_outlined,
          text: q.label,
          isEnabled: info.isQualityAvailable(q.qn),
          trailing: q.qn == _currentQn
              ? const Icon(
                  Icons.check,
                  size: 18,
                  color: Colors.blueAccent,
                )
              : (!info.isQualityAvailable(q.qn)
                  ? const Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: Colors.white24,
                    )
                  : null),
          onTap: () => _switchQuality(q.qn),
        ),
    ];
  }

  /// 当前 CDN 源标签（右上角「换源」菜单项旁显示，如「阿里云」）。
  String get _currentSourceLabel {
    for (final e in _sourceEntries()) {
      if (e.index == _sourceIndex && e.host == _sourceHost) return e.label;
    }
    return '';
  }

  /// 换源候选列表：
  ///  1. 接口下发的真实地址（baseUrl + backupUrls，大概率可用）；
  ///  2. 预设 B 站 CDN 镜像表（PiliPlus 同款：baseUrl 的 host 替换成镜像
  ///     域名，源多且覆盖各运营商/海外）。
  /// 同一源在真实段与镜像段都出现时（如 baseUrl 本身是 mirrorali）只列一次。
  List<_SourceEntry> _sourceEntries() {
    final info = widget.playUrlInfo;
    if (info == null) return const [];
    final v = BilibiliVideoService.pickVideoStream(
      info,
      quality: _currentQn,
      preferCodecs: _codecPrefixes(_decodeFormat),
    );
    if (v == null) return const [];
    final entries = <_SourceEntry>[];
    final seenHosts = <String>{};
    var i = 0;
    for (final u in v.allUrls) {
      if (u.isEmpty) continue;
      final host = _hostOf(u);
      if (host.isNotEmpty) seenHosts.add(host);
      entries.add(_SourceEntry(label: _cdnLabel(host, i), index: i));
      i++;
    }
    for (final m in kBiliCdnMirrors) {
      if (seenHosts.contains(m.host)) continue;
      entries.add(_SourceEntry(label: m.label, index: 0, host: m.host));
    }
    return entries;
  }

  /// CDN 名字：从 B 站镜像域名识别运营商，未知则退回「源N + host」。
  String _cdnLabel(String host, int index) {
    final h = host.toLowerCase();
    if (h.contains('mirrorali') || h.contains('ali')) return '阿里云';
    if (h.contains('akamaized') || h.contains('mirrorakam')) return 'Akamai';
    if (h.contains('mirrorcos') || h.contains('tencent')) return '腾讯云';
    if (h.contains('mirrorks')) return '快手云';
    if (h.contains('mirrorhw')) return '华为云';
    if (h.contains('mirrorws')) return '华数';
    if (h.isEmpty) return '源${index + 1}';
    final short = h.startsWith('upos-') ? h.substring(5) : h;
    return '源${index + 1} · $short';
  }

  String _hostOf(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return '';
    }
  }

  /// 右上角「换源」：列出当前视频全部 CDN 源（真实地址 + 预设镜像表，
  /// 长列表自动滚动），播放卡顿 / 源无法访问时切换备用 CDN，保留进度与倍速。
  /// [anchor] 可指定子菜单弹出位置（全屏「更多」菜单从底部弹出时传底部锚点）。
  void _showSourceSubMenu([Offset? anchor]) {
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    final entries = _sourceEntries();
    if (entries.isEmpty) return;
    showGlassDropdownMenu(
      context,
      scrollable: true,
      actions: [
        for (final e in entries)
          GlassMenuAction(
            icon: Icons.dns_outlined,
            text: e.label,
            trailing: e.index == _sourceIndex && e.host == _sourceHost
                ? const Icon(
                    Icons.check,
                    size: 18,
                    color: Colors.blueAccent,
                  )
                : null,
            onTap: () => _switchSource(e),
          ),
      ],
      globalPosition: anchor ?? Offset(size.width - 16, 60),
      menuWidth: 240,
      originSize: null,
    );
  }

  /// 切换 CDN 源：用新源重建播放地址并重开当前媒体（与切画质同套路）。
  Future<void> _switchSource(_SourceEntry entry) async {
    if (!_started) return;
    if (entry.index == _sourceIndex && entry.host == _sourceHost) return;
    setState(() {
      _sourceIndex = entry.index;
      _sourceHost = entry.host;
    });
    final wasPlaying = player.state.playing;
    final resume = position;
    final url = await _resolveQualityUrl(_currentQn);
    if (url == null) {
      if (mounted) showAppToast(context, '唔… 切换源失败', error: true);
      return;
    }
    await player.stop();
    await _openMedia(
      url,
      headers: widget.httpHeaders,
      subtitleUrl: widget.subtitleUrl,
      subtitleHeaders: widget.httpHeaders,
    );
    if (_disposed || !mounted) return;
    if (resume > Duration.zero) await _seekToReady(resume);
    if (_disposed || !mounted) return;
    player.setRate(currentRate);
    if (wasPlaying) player.play();
    _resetHideTimer();
    if (mounted) {
      showAppToast(context, '哦 已切到${entry.label}源');
    }
  }

  /// 右上角「倍速」：弹出倍速选择子菜单（与全屏底栏倍速按钮同一组速率，
  /// 选中项同步勾选，设置项持久化到默认倍速）。
  void _showRateSubMenu() {
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    showGlassDropdownMenu(
      context,
      actions: [
        for (final rate in const [0.5, 1.0, 1.25, 1.5, 2.0])
          GlassMenuAction(
            icon: Icons.speed,
            text: '${rate}x',
            trailing: currentRate == rate
                ? const Icon(
                    Icons.check,
                    size: 18,
                    color: Colors.blueAccent,
                  )
                : null,
            onTap: () {
              _changeRate(rate);
              context.read<SettingsService>().setPlayerDefaultRate(rate);
            },
          ),
      ],
      globalPosition: Offset(size.width - 16, 60),
      menuWidth: 200,
      originSize: null,
    );
  }

  Widget _buildDecodeFormatMenu() {
    final formats = _availableDecodeFormats();
    if (formats.isEmpty) return const SizedBox.shrink();
    return LiquidGlassMenuButton(
      icon: Icons.memory,
      iconColor: Colors.white,
      useMorphStyle: false,
      iconSize: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tooltip: L10n.current.playerDecodeFormat,
      menuWidth: 220,
      customChild: Text(
        _decodeFormat == 'auto'
            ? L10n.current.playerDecodeAutoShort
            : _decodeFormat.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        for (final fmt in ['auto', ...formats])
          GlassMenuAction(
            icon: Icons.memory,
            text: _decodeFormatLabel(fmt),
            trailing: fmt == _decodeFormat
                ? const Icon(
                    Icons.check,
                    size: 18,
                    color: Colors.blueAccent,
                  )
                : null,
            onTap: () => _setDecodeFormat(fmt),
          ),
      ],
    );
  }

  // ─── B 站字幕菜单（playurl 下发，多为 AI 字幕） ───
  Widget _buildBiliSubtitleMenu() {
    if (_biliSubtitles.isEmpty) return const SizedBox.shrink();
    return LiquidGlassMenuButton(
      icon: _activeBiliSubtitle != null
          ? Icons.closed_caption
          : Icons.closed_caption_outlined,
      iconColor: _activeBiliSubtitle != null ? Colors.blueAccent : Colors.white,
      useMorphStyle: false,
      iconSize: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tooltip: L10n.current.playerBiliSubtitle,
      menuWidth: 220,
      customChild: _biliSubtitleLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : null,
      actions: [
        GlassMenuAction(
          icon: Icons.closed_caption_disabled,
          text: '关闭字幕',
          trailing: _activeBiliSubtitle == null
              ? const Icon(
                  Icons.check,
                  size: 18,
                  color: Colors.blueAccent,
                )
              : null,
          onTap: () => _selectBiliSubtitle(null),
        ),
        for (final s in _biliSubtitles)
          GlassMenuAction(
            icon: Icons.subtitles_outlined,
            text: s.lanDoc.isEmpty ? s.lan : s.lanDoc,
            trailing: _activeBiliSubtitle?.lan == s.lan
                ? const Icon(
                    Icons.check,
                    size: 18,
                    color: Colors.blueAccent,
                  )
                : null,
            onTap: () => _selectBiliSubtitle(s),
          ),
      ],
    );
  }

  // ─── 双模式：视频播放页（16:9 内嵌播放器 + 紧凑控制条） ───
  Widget _buildPageMode(
    BuildContext context,
    SettingsService settings,
    PlayerSettingsService playerSettings,
    Widget videoLayer,
    double progress,
    double bufferProgress,
    double topInset,
  ) {
    final l10n = AppLocalizations.of(context);

    // 封面层（autoPlay=false 时展示，点击开始播放）
    Widget? coverLayer;
    if (!_started && widget.coverUrl != null) {
      Widget coverWidget;
      if (widget.coverUrl!.isEmpty) {
        coverWidget = const Center(
          child: Icon(Icons.movie_outlined, color: Colors.white24, size: 56),
        );
      } else {
        coverWidget = Image.network(
          widget.coverUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.movie_outlined, color: Colors.white24, size: 56),
          ),
        );
      }
      coverLayer = Positioned.fill(
        child: GestureDetector(
          onTap: _startPlaybackFromCover,
          child: Stack(
            fit: StackFit.expand,
            children: [
              coverWidget,
              // 播放按钮
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white70,
                  size: 64,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 非全屏（视频播放页内嵌）也支持键盘快捷键：长按 D / → 加速 2x、
    // 短按快进 10s（与全屏共用 _onPlayerKeyEvent）。
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) => _onPlayerKeyEvent(event, playerSettings),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Colors.black, child: videoLayer),
              // 点击切换控制条（双击播放/暂停）+ 长按倍速 + 横向滑动调进度
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleTap,
                  // 右键菜单：复制空降链接 / 色彩调节 / 统计信息
                  onSecondaryTapDown: (d) =>
                      _showPlayerContextMenu(d.globalPosition),
                  onLongPressStart: (_) => _startLongPressSpeed(playerSettings),
                  onLongPressEnd: (_) => _endLongPressSpeed(),
                  onLongPressCancel: _endLongPressSpeed,
                  onHorizontalDragStart: (_) {
                    if (isLongPressing) return;
                    if (_showSettingsPanel ||
                        _showSubtitlePanel ||
                        _showDanmakuPanel ||
                        _showEpisodePanel) {
                      return;
                    }
                    _startHorizontalSeek();
                  },
                  onHorizontalDragUpdate: (d) {
                    if (!_seekGestureActive) return;
                    _updateHorizontalSeek(d.delta.dx);
                  },
                  onHorizontalDragEnd: (_) => _endHorizontalSeek(),
                ),
              ),
              // 弹幕层
              if (_danmakuLoaded && _started)
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      key: _danmakuRepaintKey,
                      child: DanmakuView(controller: _danmakuController),
                    ),
                  ),
                ),
              // 封面层
              if (coverLayer != null) coverLayer,
              // 缓冲指示器
              if (_isBuffering && !isFinished && _started)
                Positioned.fill(
                  child: IgnorePointer(child: _buildBufferingIndicator()),
                ),
              // 错误提示
              if (_lastPlayerError != null)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade400),
                      ),
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
                            L10n.current.playerPlaybackError,
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _lastPlayerError!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.scanRetry),
                            onPressed: () {
                              setState(() => _lastPlayerError = null);
                              _openMedia(
                                widget.videoUrl,
                                headers: widget.httpHeaders,
                                subtitleUrl: widget.subtitleUrl,
                                subtitleHeaders: widget.httpHeaders,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // 控制层
              AnimatedOpacity(
                opacity: showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !showControls,
                  child: Stack(
                    children: [
                      // 顶部渐变
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 90,
                        child: IgnorePointer(
                          ignoring: true,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color.fromRGBO(0, 0, 0, 0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 底部渐变
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 110,
                        child: IgnorePointer(
                          ignoring: true,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  const Color.fromRGBO(0, 0, 0, 0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 顶部：返回 + （占位保持右侧按钮位置）+ 截图 / 更多。
                      // 内嵌视频播放页不显示标题（标题由宿主视频详情页展示），
                      // 仅全屏播放器才显示标题。返回按钮与封面层同位置（8, 8）。
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: Row(
                          children: [
                            // 返回按钮：与搜索页一致的毛玻璃圆钮
                            MorphIconButton(
                              icon: Icons.arrow_back,
                              tooltip: L10n.current.playerBackTooltip,
                              onTap: () => Navigator.of(context).pop(),
                              frosted: true,
                            ),
                            const Expanded(child: SizedBox.shrink()),
                            // 与 dm_on/dm_off 同款负坐标 viewBox，旋转 180° + 水平镜像修正朝向）
                            if (_danmakuLoaded)
                              IconButton(
                                icon: Transform.flip(
                                  flipX: true,
                                  child: Transform.rotate(
                                    angle: math.pi,
                                    child: SvgPicture.asset(
                                      'assets/bili_icons/dm_settings.svg',
                                      width: 20,
                                      height: 20,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                                tooltip: L10n.current.playerDanmakuSettings,
                                onPressed: _toggleDanmakuSettings,
                              ),
                            // ⋮ 更多（弹幕列表 / 查看笔记 / 字幕设置 /
                            // 高级设置 / 旋转 90°）液态玻璃 + liquid-dom
                            // 动画菜单；与返回同款毛玻璃圆钮。
                            LiquidGlassMenuButton(
                              icon: Icons.more_vert,
                              useMorphStyle: true,
                              frosted: true,
                              menuWidth: 220,
                              actions: [
                                // 换源：CDN 源切换（默认源播不动时切备用源，
                                // 如阿里云 / 腾讯云 / Akamai 等镜像）
                                if (widget.playUrlInfo != null &&
                                    widget
                                        .playUrlInfo!
                                        .qualities
                                        .isNotEmpty)
                                  GlassMenuAction(
                                    icon: Icons.dns_outlined,
                                    text: _currentSourceLabel.isEmpty
                                        ? '换源'
                                        : '换源 · $_currentSourceLabel',
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: Colors.white38,
                                    ),
                                    onTap: _showSourceSubMenu,
                                  ),
                                // 倍速：弹出速率选择子菜单
                                GlassMenuAction(
                                  icon: Icons.speed,
                                  text: '倍速 · ${currentRate}x',
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: Colors.white38,
                                  ),
                                  onTap: _showRateSubMenu,
                                ),
                                if (_danmakuLoaded)
                                  GlassMenuAction(
                                    icon: Icons.format_list_bulleted_outlined,
                                    text: L10n.current.playerDanmakuList,
                                    onTap: _showDanmakuList,
                                  ),
                                if (_isBiliSource &&
                                    (widget.bilibiliBvid?.isNotEmpty ??
                                        false))
                                  GlassMenuAction(
                                    icon: Icons.article_outlined,
                                    text: L10n.current.playerViewNotes,
                                    onTap: _showVideoNotes,
                                  ),
                                // 写笔记（仅 B 站源；未登录也可写，仅存草稿）
                                if (_isBiliSource &&
                                    (widget.bilibiliBvid?.isNotEmpty ??
                                        false))
                                  GlassMenuAction(
                                    icon: Icons.edit_note,
                                    text: L10n.current.playerWriteNote,
                                    onTap: _writeVideoNote,
                                  ),
                                // B 站源：禁用本地/WebDAV 字幕设置，改用 B 站字幕
                                if (!_isBiliSource)
                                  GlassMenuAction(
                                    icon: Icons.subtitles_outlined,
                                    text: L10n.current.playerSubtitleSettings,
                                    onTap: () => setState(() {
                                      _showSubtitlePanel = !_showSubtitlePanel;
                                      _showSettingsPanel = false;
                                      _showDanmakuPanel = false;
                                    }),
                                  ),
                                GlassMenuAction(
                                  icon: Icons.settings,
                                  text: L10n.current.playerAdvancedSettings,
                                  onTap: () => setState(() {
                                    _showSettingsPanel = !_showSettingsPanel;
                                    _showSubtitlePanel = false;
                                    _showDanmakuPanel = false;
                                  }),
                                ),
                                GlassMenuAction(
                                  icon: Icons.screen_rotation,
                                  text: L10n.current.playerRotate90,
                                  onTap: () =>
                                      setState(() => _rotation += math.pi / 2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 底部：进度条 + 控制行
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 4,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 20,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    left: 8,
                                    right: 8,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: bufferProgress,
                                        minHeight: 3,
                                        backgroundColor: Colors.white12,
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                              Colors.white38,
                                            ),
                                      ),
                                    ),
                                  ),
                                  SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 5,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 12,
                                          ),
                                      activeTrackColor: Colors.blueAccent,
                                      inactiveTrackColor: Colors.transparent,
                                    ),
                                    child: Slider(
                                      value: progress.clamp(0.0, 1.0),
                                      onChanged: (val) {
                                        setState(() {
                                          isDragging = true;
                                          dragPosition = Duration(
                                            milliseconds:
                                                (val * duration.inMilliseconds)
                                                    .toInt(),
                                          );
                                          position = dragPosition;
                                        });
                                      },
                                      onChangeEnd: (val) {
                                        _seek(val);
                                        if (_danmakuLoaded) {
                                          final targetSec =
                                              (val * duration.inMilliseconds)
                                                  .toInt() /
                                              1000.0;
                                          _danmakuController.seekTo(targetSec);
                                        }
                                        setState(() {
                                          isDragging = false;
                                          _resetHideTimer();
                                        });
                                      },
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: ViewPointProgressOverlay(
                                      segments: buildViewPointSegments(
                                        _viewPoints,
                                        duration,
                                      ),
                                      trackHeight: 3,
                                      thumbRadius: 5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _AnimatedPlayPauseButton(
                                  player: player,
                                  iconSize: 26,
                                  color: Colors.white,
                                  onTap: _togglePlayPause,
                                ),
                                Text(
                                  _format(position),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 2),
                                  child: Text(
                                    '/',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Text(
                                  _format(duration),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                const Spacer(),
                                if (widget.playUrlInfo != null)
                                  _buildQualityMenu(),
                                if (_biliSubtitles.isNotEmpty && _started)
                                  _buildBiliSubtitleMenu(),
                                if (_availableDecodeFormats().isNotEmpty &&
                                    _started)
                                  _buildDecodeFormatMenu(),
                                if (_danmakuLoaded)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.subtitles_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    tooltip: L10n.current.playerDanmakuSettings,
                                    onPressed: _toggleDanmakuSettings,
                                  ),
                                // 全屏按钮：双模式切换入口
                                IconButton(
                                  icon: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  tooltip: L10n.current.playerFullscreen,
                                  onPressed: _requestFullscreen,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 面板遮罩
              if (_showSettingsPanel || _showSubtitlePanel || _showDanmakuPanel)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _showSettingsPanel = false;
                      _showSubtitlePanel = false;
                      _showDanmakuPanel = false;
                    }),
                    child: Container(color: Colors.black45),
                  ),
                ),
              // 字幕面板（轨道/样式）
              if (_showSubtitlePanel) _buildSubtitlePanel(),
              // 高级设置面板
              if (_showSettingsPanel) _buildSettingsPanel(settings),
              // 弹幕面板
              if (_showDanmakuPanel) _buildDanmakuPanel(),
              // 统计信息浮层（与全屏一致，右键「统计信息」开关）
              if (settings.showPlayerStats && !Platform.isWindows) _buildStatsOverlay(),
              // 长按倍速提示（与全屏一致）
              if (isLongPressing)
                Positioned(
                  top: topInset + 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fast_forward, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            L10n.current.playerFastForwarding('2.0x'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // 拖动/横向滑动进度提示
              if (isDragging)
                Positioned(
                  top: topInset + 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _format(dragPosition),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 播放器键盘快捷键：长按 D / → 加速到 2x，松开恢复；短按快进 10s。
  /// 全屏与非全屏（视频播放页内嵌）共用同一套处理。
  void _onPlayerKeyEvent(KeyEvent event, PlayerSettingsService playerSettings) {
    if (isDragging) return;
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (!playerSettings.enableLongPressSpeed) return;
        final allowInImmersive =
            playerSettings.longPressInImmersive || showControls;
        if (!allowInImmersive) return;
        if (_keyHoldTimer == null) {
          _keyHoldTimer = Timer(const Duration(milliseconds: 500), () {
            if (mounted && !isLongPressing) {
              setState(() {
                isLongPressing = true;
                previousRate = currentRate;
                player.setRate(2.0);
              });
            }
          });
        }
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _keyHoldTimer?.cancel();
        _keyHoldTimer = null;
        if (mounted) {
          if (isLongPressing) {
            setState(() {
              isLongPressing = false;
              player.setRate(previousRate);
            });
          } else {
            final newPos = position + const Duration(seconds: 10);
            player.seek(newPos > duration ? duration : newPos);
            _resetHideTimer();
          }
        }
      }
    }
  }

  /// 全屏返回：同一播放器实例内（B 站视频页）退出全屏回到视频播放页；
  /// 独立全屏路由时正常回退。
  void _handleBack() {
    final exitFullscreen = widget.onExitFullscreenRequested;
    if (exitFullscreen != null) {
      exitFullscreen();
      return;
    }
    Navigator.of(context).pop();
  }

  // ─── 播放器右键菜单 ───

  /// 是否 B 站源（用于右键「复制空降链接」）。
  bool get _isBiliVideo =>
      _isBiliSource ||
      (widget.bilibiliBvid != null && widget.bilibiliBvid!.isNotEmpty);

  /// 弹出播放器右键菜单（改用 liquid-dom 菜单动画）。
  /// 右键触发：origin = 鼠标位置，关闭时圆形以鼠标位置为圆心缩小消失。
  void _showPlayerContextMenu(Offset globalPosition) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    const menuWidth = 220.0;
    // closeMenu 传空回调：关闭统一由 showLiquidDomMenu 的 close 负责，
    // 避免菜单项内部重复关闭。
    final items = _playerMenuItems(closeMenu: () {});
    final menuHeight = items.length * 44.0 + (items.length - 1) * 1.0 + 12.0;

    showLiquidDomMenu(
      context,
      globalPosition: globalPosition,
      menuWidth: menuWidth,
      menuHeight: menuHeight,
      menuRadius: 18.0,
      // originSize = null：右键无触发按钮，origin 视为锚点中心（=鼠标位置），
      // 关闭动画圆心即 origin = 鼠标指针位置（见 _close：圆心取 _closedLeft +
      // _closedSize/2 = anchorCenter.dx = origin.dx）。
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
                  _buildPlayerMenuItem(items[i], close, colorScheme),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// 右键菜单单项（透明 Material + InkWell ripple，玻璃背景由 liquid-dom 提供）。
  Widget _buildPlayerMenuItem(
    _GlassPlayerMenuData data,
    VoidCallback close,
    ColorScheme cs,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          close();
          data.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Icon(data.icon, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(
                data.text,
                style: TextStyle(fontSize: 14, color: cs.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 右键菜单项列表（与搜索视频菜单一致，closeMenu 关闭浮层）。
  List<_GlassPlayerMenuData> _playerMenuItems({
    required VoidCallback closeMenu,
  }) {
    final l10n = AppLocalizations.of(context);
    return [
      if (_isBiliVideo)
        _GlassPlayerMenuData(
          icon: Icons.timelapse,
          text: position.inMilliseconds > 0
              ? l10n.playerCopyLinkAt(_fmtSec(position.inMilliseconds ~/ 1000))
              : l10n.playerCopyLinkAt0,
          onTap: () {
            closeMenu();
            _copyBiliLink(withTime: true);
          },
        ),
      if (_isBiliVideo)
        _GlassPlayerMenuData(
          icon: Icons.link,
          text: l10n.playerCopyLink,
          onTap: () {
            closeMenu();
            _copyBiliLink(withTime: false);
          },
        ),
      _GlassPlayerMenuData(
        icon: Icons.tune,
        text: l10n.playerColorAdjust,
        onTap: () {
          closeMenu();
          _showColorAdjustPanel();
        },
      ),
      _GlassPlayerMenuData(
        icon: Icons.info_outline,
        text: l10n.playerStats,
        onTap: () {
          closeMenu();
          // Windows 上 OSD 统计浮层不渲染，改用原生 TaskDialog 显示（更符合平台逻辑）；
          // 其它平台沿用 OSD 浮层开关。
          if (Platform.isWindows) {
            _showStatsNativeDialog();
          } else {
            _togglePlayerStats();
          }
        },
      ),
      // 桌面端（Windows/macOS/Linux）全屏播放页：把窗口比例对齐到视频，消除黑边
      if (_isFullscreen && _isDesktop)
        _GlassPlayerMenuData(
          icon: Icons.aspect_ratio,
          text: l10n.playerAlignAspectRatio,
          onTap: () {
            closeMenu();
            _alignWindowToVideoAspectRatio();
          },
        ),
    ];
  }

  /// 直接打开 / 关闭播放器自带的统计信息浮层（已存在）。
  void _togglePlayerStats() {
    final settings = context.read<SettingsService>();
    settings.setShowPlayerStats(!settings.showPlayerStats);
  }

  /// Windows 上用原生 TaskDialog 显示播放统计信息。
  /// 原 OSD 浮层在 Windows 端不渲染，故改用平台原生对话框。
  Future<void> _showStatsNativeDialog() async {
    final l10n = L10n.current;
    final entries = _statsEntries();
    try {
      await _statsChannel.invokeMethod<void>('showStats', {
        'title': l10n.playerStats,
        'entries': entries.map((e) => [e.$1, e.$2]).toList(),
      });
    } catch (e) {
      // 非 Windows 平台上原生通道不可用，回退到 OSD 浮层开关；
      // Windows 平台 OSD 浮层本就不渲染，失败时不强制切换状态，避免留下无效状态。
      if (mounted && !Platform.isWindows) {
        context.read<SettingsService>().setShowPlayerStats(true);
      }
    }
  }

  /// 右键「对齐宽高比」：把窗口尺寸比例调整为与视频一致（消除黑边），仅桌面端。
  Future<void> _alignWindowToVideoAspectRatio() async {
    if (!_isDesktop) return;
    final vw = player.state.width;
    final vh = player.state.height;
    if (vw == null || vh == null || vw <= 0 || vh <= 0) {
      if (mounted) _toastPlayer(L10n.current.playerAlignAspectRatioFailed);
      return;
    }
    final ratio = vw / vh;
    try {
      if (await windowManager.isMaximized()) await windowManager.unmaximize();
      if (await windowManager.isFullScreen()) {
        await windowManager.setFullScreen(false);
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

      if ((corrected.width - size.width).abs() < 1 &&
          (corrected.height - size.height).abs() < 1) {
        if (mounted) _toastPlayer(L10n.current.playerAlignAspectRatioDone);
        return;
      }

      _isCorrectingWindowSize = true;
      await windowManager.setSize(corrected);
      _isCorrectingWindowSize = false;
      // 让已有的等比例锁定跟随视频比例，下次拖拽缩放时保持
      _windowAspectRatio = ratio;
      _lastAcceptedWindowSize = corrected;
      if (mounted) _toastPlayer(L10n.current.playerAlignAspectRatioDone);
    } catch (e) {
      _isCorrectingWindowSize = false;
      if (kDebugMode) debugPrint('⚠️ 对齐宽高比失败: $e');
      if (mounted) _toastPlayer(L10n.current.playerAlignAspectRatioFailed);
    }
  }

  String _fmtSec(int sec) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    if (h > 0) return '$h:${two(m)}:${two(s)}';
    return '$m:${two(s)}';
  }

  /// 复制 B 站链接（可带当前进度空降参数 ?t=秒）。
  Future<void> _copyBiliLink({required bool withTime}) async {
    final bvid = widget.bilibiliBvid;
    if (bvid == null || bvid.isEmpty) {
      _toastPlayer(L10n.current.playerCopyLinkNotBili);
      return;
    }
    var url = 'https://www.bilibili.com/video/$bvid';
    if (withTime && position.inMilliseconds > 0) {
      url += '?t=${(position.inMilliseconds / 1000).round()}';
    }
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      showAppToast(context, L10n.current.playerCopyLinkDone(url));
    } catch (e) {
      debugPrint('❌ 复制链接失败: $e');
    }
  }

  void _toastPlayer(String msg) {
    if (!mounted) return;
    showAppToast(context, msg);
  }

  Future<void> _showColorAdjustPanel() async {
    final platform = player.platform;
    if (platform is! NativePlayer) {
      _toastPlayer(L10n.current.playerColorUnavailable);
      return;
    }
    const keys = ['brightness', 'contrast', 'saturation', 'hue', 'gamma'];
    final values = <String, double>{};
    for (final k in keys) {
      try {
        final v = await platform.getProperty(k);
        values[k] = double.tryParse(v ?? '') ?? 0.0;
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

  /// 统计信息弹窗（复用 _statsEntries 的数据）。
  /// 统计条目列表（供 OSD 统计浮层与右键统计弹窗共用）。
  List<(String, String)> _statsEntries() {
    final l10n = L10n.current;
    final w = player.state.width ?? 0;
    final h = player.state.height ?? 0;
    final resolution = (w > 0 && h > 0) ? '${w}×${h}' : '—';
    final fpsText = _containerFps > 0
        ? '${_containerFps.toStringAsFixed(2)} fps'
        : '—';
    final bitrateText = _formatBitrate(_videoBitrate);
    final hwdecText = (_hwdecCurrent.isEmpty || _hwdecCurrent == 'no')
        ? l10n.playerHwdecSoftware
        : l10n.playerHwdecHardware(_hwdecCurrent);
    final _st = player.state.track.subtitle;
    final _subOn = _st != null && _st.id != SubtitleTrack.no().id;

    String sourceText = '—';
    try {
      final uri = Uri.parse(widget.videoUrl);
      sourceText = uri.host.isNotEmpty ? uri.host : l10n.playerSourceLocal;
    } catch (_) {
      sourceText = l10n.playerSourceLocal;
    }

    return [
      (l10n.playerStatResolution, resolution),
      (l10n.playerStatVideoCodec, _videoCodec.isNotEmpty ? _videoCodec : '—'),
      (l10n.playerStatAudioCodec, _audioCodec.isNotEmpty ? _audioCodec : '—'),
      (l10n.playerStatBitrate, bitrateText),
      (l10n.playerStatFps, fpsText),
      (l10n.playerStatDecode, hwdecText),
      (l10n.playerStatSubtitle, _subOn ? l10n.playerOn : l10n.playerOff),
      (l10n.playerStatDanmaku, _danmakuLoaded ? l10n.playerOn : l10n.playerOff),
      (l10n.playerStatDownload, _formatSpeed(_networkSpeedBps)),
      (l10n.playerStatSource, sourceText),
      (l10n.playerStatPosition, _fmtSec(position.inMilliseconds ~/ 1000)),
      (l10n.playerStatDuration, _fmtSec(duration.inMilliseconds ~/ 1000)),
    ];
  }

  /// 视频播放页点「全屏」：优先回调宿主页面，否则自动 push 全屏播放页。
  void _requestFullscreen() {
    final cb = widget.onFullscreenRequested;
    if (cb != null) {
      cb();
      return;
    }
    final url = _currentSourceUrl;
    if (url.isEmpty) return;
    final wasPlaying = player.state.playing;
    if (wasPlaying) player.pause();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => MpvPlayerPage(
              videoUrl: url,
              title: _videoTitle,
              httpHeaders: widget.httpHeaders,
              subtitleUrl: widget.subtitleUrl,
              subtitleName: widget.subtitleName,
              danmakuSource: widget.danmakuSource,
              danmakuType: widget.danmakuType,
              playlist: widget.playlist,
              initialEpisodeIndex: _currentEpisodeIndex,
              initialPosition: position,
              playUrlInfo: widget.playUrlInfo,
              initialQualityQn: _currentQn > 0 ? _currentQn : null,
              viewPoints: _viewPoints,
            ),
          ),
        )
        .then((_) {
          if (mounted && wasPlaying) {
            player.play();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final playerSettings = context.watch<PlayerSettingsService>();
//  顶部操作区偏移：隐藏状态栏时上移，不再预留 28px 空档
    final double topInset = playerSettings.showFakeStatusBar
        ? kFakeStatusBarHeight
        : 0.0;

    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;
    final bufferProgress = duration.inMilliseconds > 0
        ? (_bufferPosition.inMilliseconds / duration.inMilliseconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    var videoLayer = _buildVideoLayer();
    if (widget.heroTag != null) {
      videoLayer = Hero(tag: widget.heroTag!, child: videoLayer);
    }

//  双模式：视频播放页（内嵌 16:9）或全屏播放页
    if (!_isFullscreen) {
      return _buildPageMode(
        context,
        settings,
        playerSettings,
        videoLayer,
        progress,
        bufferProgress,
        topInset,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (KeyEvent event) =>
            _onPlayerKeyEvent(event, playerSettings),
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              final isCtrl =
                  HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed;
              if (isCtrl) {
                setState(() {
                  _scale = (_scale - event.scrollDelta.dy * 0.005).clamp(
                    0.5,
                    5.0,
                  );
                });
              }
            }
          },
          child: MouseRegion(
            onHover: (_) {
              if (!showControls) setState(() => showControls = true);
              _resetHideTimer();
            },
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _handleTap,
                  // 右键菜单：复制空降链接 / 色彩调节 / 统计信息
                  onSecondaryTapDown: (d) =>
                      _showPlayerContextMenu(d.globalPosition),
                  onLongPressStart: (_) => _startLongPressSpeed(playerSettings),
                  onLongPressEnd: (_) => _endLongPressSpeed(),
                  onLongPressCancel: _endLongPressSpeed,
                  onScaleStart: (details) {
                    if (isDragging ||
                        isLongPressing ||
                        _showSettingsPanel ||
                        _showSubtitlePanel ||
                        _showDanmakuPanel ||
                        _showEpisodePanel) {
                      return;
                    }
                    if (details.pointerCount > 1) {
                      _isScaling = true;
                      _baseScale = _scale;
                      _baseRotation = _rotation;
                    } else {
                      _isScaling = false;
                      _seekGestureActive = false;
                      _isAdjustingBrightness = false;
                      _isAdjustingVolume = false;
                      _gestureStartX = details.localFocalPoint.dx;
                      _gestureStartY = details.localFocalPoint.dy;
                    }
                  },
                  onScaleUpdate: (details) {
                    if (_isScaling) {
                      if (details.pointerCount > 1) {
                        setState(() {
                          _scale = (_baseScale * details.scale).clamp(0.5, 5.0);
                          _rotation = _baseRotation + details.rotation;
                        });
                      }
                      return;
                    }
                    if (_seekGestureActive) {
                      _updateHorizontalSeek(details.focalPointDelta.dx);
                      return;
                    }
                    if (_isAdjustingBrightness || _isAdjustingVolume) {
                      if (_isAdjustingBrightness) {
                        final delta = -details.focalPointDelta.dy / 300;
                        _adjustmentProgress = (_adjustmentProgress + delta)
                            .clamp(0.0, 1.0);
                        _brightnessChannel.invokeMethod(
                          'setBrightness',
                          _adjustmentProgress,
                        );
                      } else if (_isAdjustingVolume) {
                        final delta = -details.focalPointDelta.dy / 4;
                        _adjustmentProgress = (_adjustmentProgress + delta)
                            .clamp(0.0, 100.0);
                        player.setVolume(_adjustmentProgress);
                      }
                      setState(() {});
                      return;
                    }
                    // 尚未判定手势方向：按累计位移判定（dx > 3dy = 横向）
                    final cumDx = details.localFocalPoint.dx - _gestureStartX;
                    final cumDy = details.localFocalPoint.dy - _gestureStartY;
                    if (cumDx.abs() < 8 && cumDy.abs() < 8) return;
                    if (cumDx.abs() > 3 * cumDy.abs()) {
                      _startHorizontalSeek();
                      _updateHorizontalSeek(cumDx);
                      return;
                    }
                    if (cumDy.abs() > 3 * cumDx.abs()) {
                      // 纵向：左侧调亮度 / 右侧调音量（桌面左半屏禁用）
                      final width = MediaQuery.of(context).size.width;
                      if ((!Platform.isAndroid && !Platform.isIOS) &&
                          _gestureStartX < width / 2) {
                        return;
                      }
                      if (_gestureStartX < width / 2) {
                        _isAdjustingBrightness = true;
                        _adjustmentProgress = _currentBrightness;
                      } else {
                        _isAdjustingVolume = true;
                        _adjustmentProgress = _currentVolume;
                      }
                      setState(() {});
                    }
                  },
                  onScaleEnd: (details) {
                    if (_isScaling) {
                      _isScaling = false;
                    } else {
                      if (_seekGestureActive) {
                        _endHorizontalSeek();
                        return;
                      }
                      if (_isAdjustingBrightness) {
                        _currentBrightness = _adjustmentProgress;
                      }
                      if (_isAdjustingVolume) {
                        _currentVolume = _adjustmentProgress;
                      }
                      _isAdjustingBrightness = false;
                      _isAdjustingVolume = false;
                      setState(() {});
                      _resetHideTimer();
                    }
                  },
                  child: Center(child: videoLayer),
                ),

                // ─── 弹幕层 ───
                if (_danmakuLoaded)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        key: _danmakuRepaintKey,
                        child: DanmakuView(controller: _danmakuController),
                      ),
                    ),
                  ),

                // 缓冲指示器
                if (_isBuffering && !isFinished)
                  Positioned.fill(
                    child: IgnorePointer(child: _buildBufferingIndicator()),
                  ),

                // 错误提示
                if (_lastPlayerError != null)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade400),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade400,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              L10n.current.playerPlaybackError,
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _lastPlayerError!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: Text(L10n.current.scanRetry),
                              onPressed: () {
                                setState(() => _lastPlayerError = null);
                                _openMedia(
                                  widget.videoUrl,
                                  headers: widget.httpHeaders,
                                  subtitleUrl: widget.subtitleUrl,
                                  subtitleHeaders: widget.httpHeaders,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 亮度/音量调节
                if (_isAdjustingBrightness || _isAdjustingVolume)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isAdjustingBrightness
                                  ? Icons.brightness_6
                                  : Icons.volume_up,
                              color: Colors.white,
                              size: 36,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: 120,
                              height: 4,
                              child: LinearProgressIndicator(
                                value: _isAdjustingBrightness
                                    ? _adjustmentProgress
                                    : _adjustmentProgress / 100.0,
                                backgroundColor: Colors.white30,
                                valueColor: const AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isAdjustingBrightness
                                  ? '${(_adjustmentProgress * 100).toInt()}%'
                                  : '${_adjustmentProgress.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 双击图标
                if (_doubleTapIcon != null)
                  Positioned.fill(
                    child: Center(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _doubleTapIcon,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 播放完成
                if (isFinished)
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.replay,
                              color: Colors.white,
                              size: 64,
                            ),
                            onPressed: _replay,
                          ),
                          const Text(
                            'Re-Play!',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
//  播放列表模式：最后一集播完显示提示
                          if (_isPlaylistMode)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                L10n.current.playerAllEpisodesPlayed(
                                  _activePlaylist!.items.length,
                                ),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // 长按倍速提示
                if (isLongPressing)
                  Positioned(
                    top: topInset + 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fast_forward, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              L10n.current.playerFastForwarding('2.0x'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 拖动进度提示
                if (isDragging)
                  Positioned(
                    top: topInset + 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _format(dragPosition),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 截图预览
                if (_screenshotFile != null && playerSettings.enableScreenshot)
                  Positioned(
                    right: 16,
                    bottom: 120,
                    child: GestureDetector(
                      onTap: _saveScreenshot,
                      child: AnimatedOpacity(
                        opacity: _showScreenshotPreview ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          width: 80,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_screenshotFile!, fit: BoxFit.cover),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    color: Colors.black54,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      L10n.current.playerTapToSave,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 详细统计信息面板
                if (settings.showPlayerStats && !Platform.isWindows) _buildStatsOverlay(),

                // 跳过片头/片尾提示（仅 BV+CID 视频）
                if (_showSkipPrompt)
                  Positioned(left: 16, bottom: 108, child: _buildSkipPrompt()),

                // 还原屏幕按钮
                if (_isTransformed)
                  Positioned(
                    bottom: 108,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _resetTransform,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.72),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.orangeAccent.withOpacity(0.6),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 6),
                              Text(
                                L10n.current.playerResetScreen,
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 面板遮罩
                if (_showSettingsPanel ||
                    _showSubtitlePanel ||
                    _showDanmakuPanel ||
                    _showEpisodePanel)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _showSettingsPanel = false;
                        _showSubtitlePanel = false;
                        _showDanmakuPanel = false;
                        _showEpisodePanel = false;
                      }),
                      child: Container(color: Colors.black45),
                    ),
                  ),

                // 控制层
                AnimatedOpacity(
                  opacity: showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !showControls,
                    child: Stack(
                      children: [
                        if (playerSettings.showFakeStatusBar)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: const FakeStatusBar(),
                          ),

                        // 顶部渐变
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 150,
                          child: IgnorePointer(
                            ignoring: true,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color.fromRGBO(0, 0, 0, 0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 底部渐变
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 150,
                          child: IgnorePointer(
                            ignoring: true,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    const Color.fromRGBO(0, 0, 0, 0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 返回按钮 + 文件名（返回按钮与搜索页一致的毛玻璃圆钮；
                        // 位置与封面层/内嵌播放器同步：left 8、top 8）
                        Positioned(
                          // 顶部偏移：有伪状态栏时以其高度为基准；否则以真实状态栏
                          // 高度为基准（与非全屏播放页/投币页返回按钮位置同步）
                          top:
                              (playerSettings.showFakeStatusBar
                                  ? kFakeStatusBarHeight
                                  : MediaQuery.paddingOf(context).top) +
                              8,
                          left: 8,
                          right: 280,
                          child: Row(
                            children: [
                              MorphIconButton(
                                icon: Icons.arrow_back,
                                tooltip: L10n.current.playerBackTooltip,
                                onTap: _handleBack,
                                frosted: true,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _videoTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 顶部右侧按钮组
                        Positioned(
                          top: topInset + 10,
                          right: 16,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (playerSettings.enableScreenshot)
                                IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  onPressed: _takeScreenshot,
                                ),
//  选集按钮（仅播放列表模式显示）
                              if (_isPlaylistMode)
                                IconButton(
                                  icon: Icon(
                                    Icons.queue_music,
                                    color: _showEpisodePanel
                                        ? Colors.blueAccent
                                        : Colors.white,
                                    size: 26,
                                  ),
                                  tooltip: L10n.current.playerEpisodeSelect,
                                  onPressed: () => setState(() {
                                    _showEpisodePanel = !_showEpisodePanel;
                                    _showSettingsPanel = false;
                                    _showSubtitlePanel = false;
                                    _showDanmakuPanel = false;
                                  }),
                                ),
                              // ─── 弹幕按钮 ───
                              IconButton(
                                icon: Icon(
                                  _danmakuLoaded
                                      ? Icons.subtitles
                                      : Icons.subtitles_outlined,
                                  color: _danmakuLoaded
                                      ? Colors.blueAccent
                                      : Colors.white,
                                  size: 26,
                                ),
                                tooltip: L10n.current.playerDanmakuSettings,
                                onPressed: () => setState(() {
                                  _showDanmakuPanel = !_showDanmakuPanel;
                                  _showSettingsPanel = false;
                                  _showSubtitlePanel = false;
                                  _showEpisodePanel = false;
                                }),
                              ),
                              // ⋮ 更多菜单（收纳不常用功能，液态玻璃 + liquid-dom 动画）
                              LiquidGlassMenuButton(
                                icon: Icons.more_vert,
                                iconColor: Colors.white,
                                useMorphStyle: false,
                                iconSize: 26,
                                tooltip: '更多',
                                menuWidth: 220,
                                actions: [
                                  // 换源：B 站多 CDN 镜像切换（底部弹出源列表）
                                  if (widget.playUrlInfo != null &&
                                      widget
                                          .playUrlInfo!
                                          .qualities
                                          .isNotEmpty)
                                    GlassMenuAction(
                                      icon: Icons.dns_outlined,
                                      text: _currentSourceLabel.isEmpty
                                          ? '换源'
                                          : '换源 · $_currentSourceLabel',
                                      onTap: () {
                                        final s = MediaQuery.sizeOf(context);
                                        _showSourceSubMenu(
                                          Offset(s.width - 16, s.height - 140),
                                        );
                                      },
                                    ),
                                  GlassMenuAction(
                                    icon: Icons.screen_rotation,
                                    text: L10n.current.playerRotate90,
                                    onTap: () => _handleMoreMenu('rotate'),
                                  ),
                                  GlassMenuAction(
                                    icon: Icons.cloud_outlined,
                                    text: L10n.current.playerWebdavSource,
                                    onTap: () => _handleMoreMenu('webdav'),
                                  ),
                                  GlassMenuAction(
                                    icon: Icons.cast,
                                    text: L10n.current.playerCast,
                                    onTap: () => _handleMoreMenu('cast'),
                                  ),
                                  GlassMenuAction(
                                    icon: Icons.picture_in_picture_alt,
                                    text: '画中画',
                                    onTap: () => _handleMoreMenu('pip'),
                                  ),
                                  GlassMenuAction(
                                    icon: Icons.settings,
                                    text: L10n.current.playerAdvancedSettings,
                                    onTap: () => _handleMoreMenu('settings'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 底部控制栏
                        Positioned(
                          bottom: 24,
                          left: 16,
                          right: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 20,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: bufferProgress,
                                          minHeight: 4,
                                          backgroundColor: Colors.white12,
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                Colors.white38,
                                              ),
                                        ),
                                      ),
                                    ),
                                    SliderTheme(
                                      data: SliderThemeData(
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 14,
                                            ),
                                        activeTrackColor: Colors.blueAccent,
                                        inactiveTrackColor: Colors.transparent,
                                      ),
                                      child: Slider(
                                        value: progress.clamp(0.0, 1.0),
                                        onChanged: (val) {
                                          setState(() {
                                            isDragging = true;
                                            dragPosition = Duration(
                                              milliseconds:
                                                  (val *
                                                          duration
                                                              .inMilliseconds)
                                                      .toInt(),
                                            );
                                            position = dragPosition;
                                          });
                                        },
                                        onChangeEnd: (val) {
                                          _seek(val);
                                          if (_danmakuLoaded) {
                                            final targetSec =
                                                (val * duration.inMilliseconds)
                                                    .toInt() /
                                                1000.0;
                                            _danmakuController.seekTo(
                                              targetSec,
                                            );
                                          }
                                          setState(() {
                                            isDragging = false;
                                            _resetHideTimer();
                                          });
                                        },
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: ViewPointProgressOverlay(
                                        segments: buildViewPointSegments(
                                          _viewPoints,
                                          duration,
                                        ),
                                        trackHeight: 4,
                                        thumbRadius: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
//  上一集按钮
                                        if (_isPlaylistMode)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.skip_previous,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                            onPressed: _currentEpisodeIndex > 0
                                                ? _playPrevEpisode
                                                : null,
                                          ),
                                        _AnimatedPlayPauseButton(
                                          player: player,
                                          iconSize: 24,
                                          color: Colors.white,
                                          onTap: _togglePlayPause,
                                        ), //  下一集按钮
                                        if (_isPlaylistMode)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.skip_next,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                            onPressed:
                                                _currentEpisodeIndex <
                                                    _activePlaylist!
                                                            .items
                                                            .length -
                                                        1
                                                ? _playNextEpisode
                                                : null,
                                          ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _format(position),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            '/',
                                            style: TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _format(duration),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
//  集数指示
                                        if (_isPlaylistMode) ...[
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${_currentEpisodeIndex + 1}/${_activePlaylist!.items.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
//  清晰度（传入 playUrlInfo 时显示，
                                        //    含可用性检查：锁定/会员画质置灰）
                                        if (widget.playUrlInfo != null &&
                                            widget
                                                .playUrlInfo!
                                                .qualities
                                                .isNotEmpty)
                                          _buildQualityMenu(),
                                        if (_biliSubtitles.isNotEmpty)
                                          _buildBiliSubtitleMenu(),
//  首选解码格式
                                        if (_availableDecodeFormats()
                                            .isNotEmpty)
                                          _buildDecodeFormatMenu(),
//  字幕设置（B 站源禁用：改用 B 站字幕）
                                        if (!_isBiliSource)
                                          IconButton(
                                            icon: Icon(
                                              _showSubtitlePanel
                                                  ? Icons.subtitles
                                                  : Icons.subtitles_outlined,
                                              color: _showSubtitlePanel
                                                  ? Colors.blueAccent
                                                  : Colors.white,
                                              size: 22,
                                            ),
                                            tooltip: L10n
                                                .current
                                                .playerSubtitleSettings,
                                            onPressed: () => setState(() {
                                              _showSubtitlePanel =
                                                  !_showSubtitlePanel;
                                              _showSettingsPanel = false;
                                              _showDanmakuPanel = false;
                                              _showEpisodePanel = false;
                                            }),
                                          ),
                                        LiquidGlassMenuButton(
                                          icon: Icons.aspect_ratio,
                                          iconColor: Colors.white,
                                          useMorphStyle: false,
                                          menuWidth: 220,
                                          customChild: Text(
                                            _fitLabel(currentFit),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          actions: [
                                            for (final fit in [
                                              BoxFit.contain,
                                              BoxFit.fill,
                                              BoxFit.cover,
                                            ])
                                              GlassMenuAction(
                                                icon: Icons.aspect_ratio,
                                                text: _fitLabel(fit),
                                                trailing: currentFit == fit
                                                    ? const Icon(
                                                        Icons.check,
                                                        size: 18,
                                                        color: Colors.blue,
                                                      )
                                                    : null,
                                                onTap: () => setState(
                                                  () => currentFit = fit,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        LiquidGlassMenuButton(
                                          icon: Icons.speed,
                                          iconColor: Colors.white,
                                          useMorphStyle: false,
                                          iconSize: 24,
                                          menuWidth: 200,
                                          customChild: Text(
                                            '${currentRate}x',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          actions: [
                                            for (final rate in [
                                              0.5,
                                              1.0,
                                              1.25,
                                              1.5,
                                              2.0,
                                            ])
                                              GlassMenuAction(
                                                icon: Icons.speed,
                                                text: '${rate}x',
                                                trailing: currentRate == rate
                                                    ? const Icon(
                                                        Icons.check,
                                                        size: 18,
                                                        color: Colors.blue,
                                                      )
                                                    : null,
                                                onTap: () {
                                                  _changeRate(rate);
                                                  settings
                                                      .setPlayerDefaultRate(
                                                        rate,
                                                      );
                                                },
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        LiquidGlassMenuButton(
                                          icon: _endBehaviorIcon(endBehavior),
                                          iconColor: Colors.white,
                                          useMorphStyle: false,
                                          iconSize: 24,
                                          tooltip: _endBehaviorLabel(endBehavior),
                                          menuWidth: 220,
                                          actions: [
                                            for (final b in EndBehavior.values)
                                              GlassMenuAction(
                                                icon: _endBehaviorIcon(b),
                                                text: _endBehaviorLabel(b),
                                                trailing: endBehavior == b
                                                    ? const Icon(
                                                        Icons.check,
                                                        size: 18,
                                                        color: Colors.blue,
                                                      )
                                                    : null,
                                                onTap: () {
                                                  setState(
                                                    () => endBehavior = b,
                                                  );
                                                  settings.setPlayerEndBehavior(
                                                    _endBehaviorToString(b),
                                                  );
                                                },
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 设置面板
                _buildSettingsPanel(settings),

                // 字幕面板
                _buildSubtitlePanel(),

                // 弹幕面板
                _buildDanmakuPanel(),

//  集数选择面板
                if (_showEpisodePanel && _activePlaylist != null)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    top: 0,
                    bottom: 0,
                    right: _showEpisodePanel ? 0 : -320,
                    width: 320,
                    child: PlaylistEpisodePanel(
                      playlist: _activePlaylist!,
                      currentIndex: _currentEpisodeIndex,
                      onEpisodeSelected: _switchToEpisode,
                      onClose: () => setState(() => _showEpisodePanel = false),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FakeStatusBar extends StatefulWidget {
  const FakeStatusBar({super.key});

  @override
  State<FakeStatusBar> createState() => _FakeStatusBarState();
}

class _FakeStatusBarState extends State<FakeStatusBar> {
  String _time = '';
  String _networkIcon = 'wifi';
  int _batteryLevel = 100;
  bool _isCharging = false;
  Timer? _clockTimer;
  Timer? _batteryTimer;
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _batterySub;
  StreamSubscription? _networkSub;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTime(),
    );
    _initBattery();
    _initNetwork();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _time =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _initBattery() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      _batterySub = _battery.onBatteryStateChanged.listen((state) {
        if (mounted)
          setState(() => _isCharging = state == BatteryState.charging);
      });
      _batteryTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
        if (mounted) {
          setState(() async => _batteryLevel = await _battery.batteryLevel);
        }
      });
    } catch (_) {}
  }

  Future<void> _initNetwork() async {
    try {
      var result = await _connectivity.checkConnectivity();
      _updateNetwork(result);
      _networkSub = _connectivity.onConnectivityChanged.listen((result) {
        if (mounted) _updateNetwork(result);
      });
    } catch (_) {}
  }

  void _updateNetwork(dynamic result) {
    setState(() {
      bool isWifi = false;
      bool isMobile = false;
      if (result is List) {
        isWifi = result.contains(ConnectivityResult.wifi);
        isMobile = result.contains(ConnectivityResult.mobile);
      } else {
        isWifi = result == ConnectivityResult.wifi;
        isMobile = result == ConnectivityResult.mobile;
      }
      if (isWifi) {
        _networkIcon = 'wifi';
      } else if (isMobile) {
        _networkIcon = 'cellular';
      } else {
        _networkIcon = 'none';
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _batteryTimer?.cancel();
    _batterySub?.cancel();
    _networkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kFakeStatusBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          Row(
            children: [
              Icon(
                _networkIcon == 'wifi'
                    ? Icons.network_wifi
                    : _networkIcon == 'cellular'
                    ? Icons.signal_cellular_4_bar
                    : Icons.signal_wifi_off,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Icon(
                _isCharging
                    ? Icons.battery_charging_full
                    : _batteryLevel > 80
                    ? Icons.battery_full
                    : _batteryLevel > 50
                    ? Icons.battery_5_bar
                    : _batteryLevel > 20
                    ? Icons.battery_3_bar
                    : Icons.battery_1_bar,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '$_batteryLevel%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════
//  播放器右键菜单（与搜索视频卡片菜单同款：毛玻璃 + Material/InkWell ripple）
// ═════════════════════════════════════════

/// 换源候选：label 显示名；index 传给 [BilibiliVideoService.buildPlayableUrl]
/// 的 sourceIndex（0=baseUrl，1..n=backupUrls）；host 非空时替换地址域名
/// （预设镜像表换源）。
class _SourceEntry {
  final String label;
  final int index;
  final String? host;

  const _SourceEntry({required this.label, required this.index, this.host});
}

/// 播放/暂停切换按钮（参考 PiliPlus PlayOrPauseButton）：
/// 用 [AnimatedIcons.play_pause] 做 200ms 交叉动画，播放↔暂停图标
/// 平滑过渡，播放状态变化由 player.stream.playing 流驱动。
class _AnimatedPlayPauseButton extends StatefulWidget {
  final Player player;
  final double iconSize;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedPlayPauseButton({
    required this.player,
    required this.iconSize,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedPlayPauseButton> createState() =>
      _AnimatedPlayPauseButtonState();
}

class _AnimatedPlayPauseButtonState extends State<_AnimatedPlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  StreamSubscription<bool>? _playingSub;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: widget.player.state.playing ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
    );
    _playingSub = widget.player.stream.playing.listen((playing) {
      if (!mounted) return;
      if (playing) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.onTap,
      icon: AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: _controller,
        color: widget.color,
        size: widget.iconSize,
      ),
    );
  }
}

class _GlassPlayerMenuData {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _GlassPlayerMenuData({
    required this.icon,
    required this.text,
    required this.onTap,
  });
}

class _GlassPlayerMenu extends StatelessWidget {
  final bool isDark;
  final ColorScheme colorScheme;
  final List<_GlassPlayerMenuData> items;

  const _GlassPlayerMenu({
    required this.isDark,
    required this.colorScheme,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final menuBg = isDark
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.8)
        : colorScheme.surfaceContainerLow.withValues(alpha: 0.85);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: menuBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                _buildItem(items[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(_GlassPlayerMenuData data) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Icon(data.icon, size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(
                data.text,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
