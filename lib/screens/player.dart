                          
                                         
                                              
import 'dart:async';
import 'dart:convert';
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
import 'package:naviflash/widgets/more_menu_sheet.dart';
import 'package:naviflash/widgets/seek_time_picker_dialog.dart';
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
import 'package:naviflash/services/native_menu_service.dart';
import 'package:naviflash/services/player_settings_service.dart';
import 'package:naviflash/services/taskbar_progress_service.dart';
import 'package:naviflash/services/play_history_service.dart';
import 'package:naviflash/services/watch_history_service.dart';
import 'package:naviflash/services/playlist_service.dart';
import 'package:naviflash/services/notification_service.dart';
import 'package:naviflash/services/super_resolution_service.dart';
import 'package:naviflash/services/sponsor_block_service.dart';
import 'package:naviflash/services/player_audio_service.dart';
import 'package:naviflash/services/mini_player_service.dart';
import 'package:naviflash/services/playback_focus.dart';
import 'package:naviflash/services/videoshot_service.dart';
import 'package:naviflash/services/video_clip_service.dart';
import 'package:naviflash/services/motion_photo_service.dart';
import 'package:naviflash/services/live_update_service.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/bilibili_video_service.dart';
import 'package:naviflash/services/bilibili_interactive_service.dart';
import 'package:naviflash/services/bilibili_bangumi_service.dart';
import 'package:naviflash/services/bilibili_cheese_service.dart'
    show BilibiliCheeseService;
import 'package:naviflash/services/bv_av.dart';
import 'package:naviflash/services/log_service.dart';
import 'package:naviflash/widgets/view_point_progress.dart';
import 'package:naviflash/widgets/webdav_file_picker.dart';
import 'package:naviflash/widgets/subtitle_controller.dart';
import 'package:naviflash/widgets/screenshot_dialog.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/src/enums.dart';
import 'package:naviflash/src/window_aspect_math.dart';
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
import 'package:naviflash/widgets/player/player_keyboard_shortcuts.dart';
import 'package:naviflash/widgets/player/seek_preview.dart';
import 'package:naviflash/widgets/player/cdn_speed_dialog.dart';
import 'package:naviflash/widgets/playlist_episode_panel.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/services/sleep_timer_service.dart';
import 'package:naviflash/screens/dlna_cast_page.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';
import 'package:window_manager/window_manager.dart';

enum EndBehavior { pause, loop, exit }

                      
enum PlayerPageMode {
                                     
  videoPage,

                        
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

                                                  
                                                      
                                         
   
                                                          
@visibleForTesting
bool shouldClearStuckBuffering({
  required bool isBuffering,
  required bool playing,
  required bool completed,
  required Duration? previous,
  required Duration current,
}) =>
    isBuffering &&
    playing &&
    !completed &&
    previous != null &&
    current - previous > const Duration(milliseconds: 250);

class MpvPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String? heroTag;
  final Map<String, String>? httpHeaders;
  final String? subtitleUrl;
  final String? subtitleName;
  final Duration? initialPosition;
  final String? title;

                                   
                                   
  final String? artist;

  final String? danmakuSource;
  final String? danmakuType;

            
  final Playlist? playlist;
  final int initialEpisodeIndex;

                                    
  final bool recordHistory;

                                     
  final ValueChanged<Duration>? onExit;

                                                 
                                         
  final BiliPlayUrl? playUrlInfo;

                                                   
     
                                                              
                                       
  final List<BiliSubtitle> biliSubtitles;

                                  
  final int? initialQualityQn;

                                   
  final List<BiliViewPoint>? viewPoints;

                                                       
                               
  final PlayerPageMode mode;

                                     
                                              
  final VoidCallback? onFullscreenRequested;

                                       
                                
  final VoidCallback? onExitFullscreenRequested;

                                       
  final ValueChanged<Duration>? onPositionChanged;

                                
  final ValueChanged<int>? onEpisodeChanged;

                         
  final ValueChanged<int>? onQualityChanged;

                                       
  final ValueChanged<int>? onDanmakuCountChanged;

                                  
                     
  final DanmakuController? danmakuController;

                                          
  final bool autoPlay;

                                        
  final String? coverUrl;

                                                
  final String? artUri;

                                        
  final String? bilibiliBvid;

                                                   
                                               
  final String? historyId;

                                      
  final ValueChanged<bool>? onControlsVisibilityChanged;

                                     
  final ValueChanged<bool>? onOnlyPlayAudioChanged;

                                      
                                            
  final VoidCallback? onMoreMenuRequested;

                                       
                                      
  final VoidCallback? onListenPageRequested;

                                                           
                                              
                                                      
  final bool isInteractiveVideo;

                                         
                  
  final ValueChanged<int>? onInteractiveNodeChanged;

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
    this.biliSubtitles = const [],
    this.initialQualityQn,
    this.viewPoints,
    this.isInteractiveVideo = false,
    this.onInteractiveNodeChanged,
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
    this.onOnlyPlayAudioChanged,
    this.onMoreMenuRequested,
    this.onListenPageRequested,
  });

  @override
  State<MpvPlayerPage> createState() => MpvPlayerPageState();
}

class MpvPlayerPageState extends State<MpvPlayerPage>
    with WidgetsBindingObserver
    implements PlaybackAudioSource {
  late final Player player;
  late final VideoController controller;

  bool get _isFullscreen => widget.mode == PlayerPageMode.fullscreen;

                                    
                                                                      
  bool _disposed = false;

                                 
  bool _enterHistoryRecorded = false;

                                                
  bool get _isBiliSource => widget.playUrlInfo != null;

                                         
  String get _mediaArtist => widget.artist ?? L10n.current.playerArtistVideo;

                         
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

                      
                                                         
                                              
                                                     
                             
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier<Duration>(
    Duration.zero,
  );
  final ValueNotifier<Duration> _bufferNotifier = ValueNotifier<Duration>(
    Duration.zero,
  );

                                           
                                                    
                      
  void _setPlaybackPosition(Duration d) {
    position = d;
    _positionNotifier.value = d;
  }

                                        
  void _setBufferPosition(Duration d) {
    _bufferPosition = d;
    _bufferNotifier.value = d;
  }

  double currentRate = 1.0;
  bool isLongPressing = false;
  double previousRate = 1.0;
  bool _showControls = true;

                                             
  bool get showControls => _showControls;
  set showControls(bool value) {
    if (_showControls == value) return;
    _showControls = value;
    widget.onControlsVisibilityChanged?.call(value);
  }

  Timer? _hideTimer;

                            
  Timer? _wheelVolumeTimer;
  Duration dragPosition = Duration.zero;
  bool isFlipX = false;
  bool isFlipY = false;

                                  
                                                             
                                          
  bool onlyPlayAudio = false;

  final FocusNode _focusNode = FocusNode();
  Timer? _keyHoldTimer;

                                            
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

  String _videoTitle = '';
  String? _thumbnailPath;
                                       
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

                         
  double _subPadL = PlayerSettingsService.defaultSubtitlePadL;
  double _subPadR = PlayerSettingsService.defaultSubtitlePadR;
  double _subPadB = PlayerSettingsService.defaultSubtitlePadB;
  bool _subDragEnabled = false;
  bool _subtitleDragging = false;
  double _subDragStartL = 0;
  double _subDragStartR = 0;
  double _subDragStartB = 0;
  Offset _subDragOffset = Offset.zero;
  bool _subtitleBilingual = false;

                             
  int _subtitleSecondSeq = 0;

  String? _lastPlayerError;
  Duration _bufferPosition = Duration.zero;
  bool _isBuffering = false;

                                                
                                                 
                                 
  Duration? _bufferingWatchdogPos;

                                          
                                               
                                                 
  DateTime? _bufferingSuppressUntil;

                                             
  final Object _taskbarBufferingToken = Object();

                                  
  final Object _taskbarOpenToken = Object();

  double _networkSpeedBps = 0.0;
  Timer? _speedCalcTimer;

  int _lastTapTimestamp = 0;
  static const int _doubleTapThresholdMs = 300;

                   
  String _videoCodec = '';
  String _audioCodec = '';
  int _videoBitrate = 0;
  double _containerFps = 0.0;
  String _hwdecCurrent = '';
  Timer? _statsTimer;

                 
  late final DanmakuController _danmakuController;
  late final bool _ownsDanmakuController;
  bool _showDanmakuPanel = false;
  bool _danmakuLoaded = false;
  StreamSubscription? _danmakuPlayingSub;
  StreamSubscription? _danmakuPositionSub;

                                      
  Timer? _smartMaskTimer;
  DanmakuSmartMaskService? _smartMaskService;
  bool _smartMaskBusy = false;
  String? _activeDanmakuSource;
  String? _activeDanmakuType;

                                         
                                            
  int _danmakuRequestSeq = 0;

                            
     
                                      
                                      
                  
  bool _streamReady = false;

                                                 
  bool _danmakuPendingLoad = false;

                                  
  int _streamReadySeq = 0;

                                                
                                                            
  late final int _mountedEpisodeIndex = widget.initialEpisodeIndex;

                             
                                        
  bool _started = false;

                           
  String _decodeFormat = 'auto';
  List<BiliSubtitle> _biliSubtitles = const [];
  BiliSubtitle? _activeBiliSubtitle;
  bool _biliSubtitleLoading = false;

                   
  Playlist? _activePlaylist;
  int _currentEpisodeIndex = 0;
  bool _showEpisodePanel = false;

                                   
  int _currentQn = 0;

                                                        
                                     
                              
  int _currentAudioId = 0;

                                                    
                                       
  int _sourceIndex = 0;

                                                 
  String? _sourceHost;
  List<BiliViewPoint> _viewPoints = const [];

                             
                                                          
  int _interactiveGraphVersion = 0;

                                         
                                                      
                                   
  int? _currentInteractiveCid;

                                          
  BiliInteractiveNode? _interactiveNode;

                                    
                                 
  List<_InteractiveStep> _interactivePath = const [];

                                              
  List<BiliInteractiveChoice> _interactiveChoices = const [];

                                      
  bool _interactiveSwitching = false;

                                            
  String? _interactiveBvid;

                                       
  final Map<int, BiliInteractiveNode> _interactiveNodeCache = {};

                           
  int _interactiveReqSeq = 0;

                                              
  List<SponsorSegment> _sponsorSegments = [];
  SponsorSegment? _activeSkipSegment;
  Timer? _skipPromptTimer;
  bool get _showSkipPrompt =>
      _activeSkipSegment != null &&
      (_playerSettingsService?.skipIntroOutro ?? false);

                                   
  VideoShotData? _videoShot;
  bool _previewLoading = false;
  int _previewIndex = 0;
  bool _showSeekPreviewOverlay = false;

                                           
  bool _isDesktopPip = false;
  Rect? _lastWindowBounds;

                                    
  bool _pgcClipsEnabled = false;

  bool get _isPlaylistMode =>
      _activePlaylist != null && _activePlaylist!.items.length > 1;

                                   
  PlayHistoryService? _historyService;
  PlayerSettingsService? _playerSettingsService;
                             
  WatchHistoryService? _watchHistoryService;
  SettingsService? _settingsService;

              
  StreamSubscription? _mpvLogSub;

                                            
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

                                                    
  static const MethodChannel _statsChannel = MethodChannel(
    'com.memz2345.navi.flash/stats_dialog',
  );

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
                                            
    _statsChannel.setMethodCallHandler(_handleStatsMethodCall);
    WidgetsBinding.instance.addObserver(this);

                            
                                                  
                                              
    audioHandler
      ..onSkipToNext = _playNextEpisode
      ..onSkipToPrevious = _playPrevEpisode;

                                            
    SleepTimerService.instance.bindPauseTarget(this, () {
      if (!_disposed) player.pause();
    });

    _videoTitle = widget.title ?? _extractTitleFromUrl(widget.videoUrl);
    _currentSourceUrl = widget.videoUrl;

               
    _activePlaylist = widget.playlist;
    _currentEpisodeIndex = widget.initialEpisodeIndex;

                         
    _currentQn = widget.initialQualityQn ?? widget.playUrlInfo?.quality ?? 0;
    _viewPoints = widget.viewPoints ?? const [];
                                       
    _interactiveBvid = (widget.bilibiliBvid?.isNotEmpty ?? false)
        ? widget.bilibiliBvid
        : null;

                                      
                                                      
    if (!_isFullscreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
      });
    }

                                      
                                     
    _ownsDanmakuController = widget.danmakuController == null;
    _danmakuController = widget.danmakuController ?? DanmakuController();
                                        
    if (_ownsDanmakuController) {
      _danmakuController.restoreSettings();
    }
    _danmakuController.isFullscreen = _isFullscreen;

                                                
                                         
    _biliSubtitles = widget.biliSubtitles.isNotEmpty
        ? widget.biliSubtitles
        : (widget.playUrlInfo?.subtitles ?? const []);

                                              
    final playerSettings = context.read<PlayerSettingsService>();
    final enableMpvLog = playerSettings.enableMpvLog;
    _decodeFormat = playerSettings.preferredDecodeFormat;
                                       
    _currentAudioId = playerSettings.defaultAudioQualityId;
                                                     
    _subDragEnabled = playerSettings.subtitleDragEnabled;
    _subtitleBilingual = playerSettings.subtitleBilingual;
    _subPadL = playerSettings.subtitlePadL;
    _subPadR = playerSettings.subtitlePadR;
    _subPadB = playerSettings.subtitlePadB;

    player = Player(
      configuration: PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024,
                                          
        logLevel: enableMpvLog
            ? _mpvLogLevelOf(playerSettings.mpvLogLevel)
            : MPVLogLevel.warn,
      ),
    );
    controller = VideoController(player);
                                     
                         
    PlaybackFocus.instance.register(this);

                                          
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
                                                          
                                           
        if (_isRecoverableMpvError(error)) return;
                                         
        if (player.state.playing) return;
        if (_lastPlayerError == null) {
          setState(() => _lastPlayerError = error);
        }
      }
    });

    final settings = Provider.of<SettingsService>(context, listen: false);
    currentRate = settings.playerDefaultRate;
    endBehavior = _stringToEndBehavior(settings.playerEndBehavior);

                                   
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
                                                  
      if (widget.autoPlay) {
                                   
        await TaskbarProgress.track<void>(
          _taskbarOpenToken,
          () => _openMedia(
            _initialOpenUrl(),
            headers: widget.httpHeaders,
            subtitleUrl: widget.subtitleUrl,
            subtitleHeaders: widget.httpHeaders,
          ),
        );
        if (_disposed || !mounted) return;
        if (mounted) setState(() => _started = true);

               
        final resumeAt = _effectiveInitialPosition;
        if (resumeAt != null) {
          Duration? readyDuration;
                                          
                            
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

                                         
        _maybeQuerySponsorBlock();
                                    
        _maybeInitInteractive();
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
                                             
                                      
      if (!isDragging && mounted) _setPlaybackPosition(pos);
      widget.onPositionChanged?.call(pos);
    });

    player.stream.duration.listen((dur) {
      if (mounted) setState(() => duration = dur);
                                    
      if (dur > Duration.zero) _markStreamReady();
                                           
      if (!_orientationLocked) {
        _applyAutoOrientation();
      }
    });

                                          
    player.stream.width.listen((_) {
      if (!_orientationLocked) _applyAutoOrientation();
    });
    player.stream.height.listen((_) {
      if (!_orientationLocked) _applyAutoOrientation();
    });

    player.stream.buffer.listen((buf) {
      if (mounted) _setBufferPosition(buf);
    });

                                           
                                                         
    _historySaveTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted || !player.state.playing) return;
      final posMs = position.inMilliseconds;
      _saveHistoryNow(widget.historyId);
      if (posMs > 3000) _reportBiliProgressIfNeeded(posMs);
    });

    player.stream.buffering.listen((buffering) {
      if (!mounted) return;
      var effective = buffering;
      if (buffering) {
        final until = _bufferingSuppressUntil;
        if (until != null) {
          if (DateTime.now().isBefore(until)) {
                                            
            effective = false;
          } else {
            _bufferingSuppressUntil = null;
          }
        }
      }
      _setBuffering(effective);
    });

    _speedCalcTimer = Timer.periodic(const Duration(milliseconds: 800), (
      _,
    ) async {
      if (_disposed || !mounted) return;
                                                     
                                               
                                                     
      if (_isBuffering && player.state.playing && !player.state.completed) {
        final pos = player.state.position;
        final prev = _bufferingWatchdogPos;
        if (shouldClearStuckBuffering(
          isBuffering: _isBuffering,
          playing: player.state.playing,
          completed: player.state.completed,
          previous: prev,
          current: pos,
        )) {
          _setBuffering(false);
        }
        _bufferingWatchdogPos = pos;
      } else {
        _bufferingWatchdogPos = null;
      }
      try {
        final platform = player.platform;
                                             
                                    
        if (platform is NativePlayer &&
            (_isBuffering || _playerStatsVisible())) {
          final speedStr = await platform.getProperty('cache-speed');
          final speed = double.tryParse(speedStr) ?? 0.0;
          if (!_disposed && mounted) setState(() => _networkSpeedBps = speed);
        }
      } catch (_) {}
    });

    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_disposed || !mounted) return;
                                            
      if (!_playerStatsVisible()) return;
      await _refreshStatsOnce();
    });

                       
    player.stream.completed.listen((completed) {
      if (!_disposed && completed && mounted) {
                                         
                                                     
        if (SleepTimerService.instance.consumeStopAfterCurrent()) {
          setState(() {
            isFinished = true;
            showControls = true;
          });
          return;
        }
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

                       
    _danmakuPlayingSub = player.stream.playing.listen((playing) {
      if (playing) {
        _danmakuController.play();
                               
        unawaited(PlaybackFocus.instance.acquire(this));
      } else {
        _danmakuController.pause();
      }
    });

    _danmakuPositionSub = player.stream.position.listen((pos) {
                                    
      if (!_danmakuLoaded || !_streamReady) return;
      final posSec = pos.inMilliseconds / 1000.0;
      final diff = (posSec - _danmakuController.currentTime).abs();
      if (diff > 2.0) {
        _danmakuController.seekTo(posSec);
      } else {
        _danmakuController.syncTime(posSec);
      }
    });

                    
    player.stream.position.listen(_onSkipCheck);

                                        
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
                                      
    if (!_enterHistoryRecorded) {
      _enterHistoryRecorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _recordPlayHistoryOnEnter();
      });
    }
  }

                                    
  Future<void> _recordPlayHistoryOnEnter() async {
    if (!widget.recordHistory) return;
    if (_settingsService?.incognitoMode ?? false) return;
                             
    try {
      final posMs = _effectiveInitialPosition?.inMilliseconds ?? 0;
                               
      final existing = _historyService?.findById(
        widget.historyId ?? PlayHistoryService.generateId(widget.videoUrl),
      );
      final usePos = existing?.positionMs ?? posMs;
      final useDur = existing?.durationMs ?? 0;
                                     
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
                                                                 
                                         
    try {
      final bvid = widget.bilibiliBvid;
      if (bvid != null && bvid.isNotEmpty) {
        final wh = _watchHistoryService;
        if (wh == null) return;
        final cid = int.tryParse(
          _activeDanmakuSource ?? widget.danmakuSource ?? '',
        );
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
                                     
    if (oldWidget.mode != widget.mode) {
      if (mounted) setState(() => showControls = true);
      _resetHideTimer();
                                      
      if (Platform.isAndroid) {
        if (widget.mode == PlayerPageMode.fullscreen) {
          _applyAutoOrientation();
        } else {
          SystemChrome.setPreferredOrientations(DeviceOrientation.values);
          _orientationLocked = false;
        }
      }
    }
                                           
                                        
    if (oldWidget.viewPoints != widget.viewPoints) {
      _viewPoints = widget.viewPoints ?? const [];
    }
                                                  
                                          
    if (!identical(oldWidget.playUrlInfo, widget.playUrlInfo)) {
      _clearSponsorBlock();
      if (widget.autoPlay && _started) {
        _maybeQuerySponsorBlock();
      }
    }
                                      
    if (oldWidget.mode != widget.mode && !_isFullscreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
      });
    }
                                           
                                          
    if (!identical(oldWidget.biliSubtitles, widget.biliSubtitles)) {
      final next = widget.biliSubtitles;
      _biliSubtitles = next;
      final active = _activeBiliSubtitle;
      if (active != null && !next.any((s) => s.lan == active.lan)) {
        _activeBiliSubtitle = null;
        player.setSubtitleTrack(SubtitleTrack.no());
      }
    }
                                         
                                                           
                       
    if (widget.danmakuSource != oldWidget.danmakuSource &&
        (widget.danmakuSource?.isNotEmpty ?? false) &&
        widget.danmakuSource != _activeDanmakuSource) {
      _danmakuRequestSeq++;
      _danmakuController.setItems([]);
      _danmakuLoaded = false;
      _videoShot = null;
      _autoLoadDanmakuIfEnabled();
    }
  }

                              
                                    
                   
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
                        
  }

  void _onPlayerSettingsChanged() {
    final platform = player.platform;
    if (platform is! NativePlayer) return;
    final ps = _playerSettingsService;
    if (ps == null) return;
    platform
        .setProperty('hwdec', ps.hwdecEnabled ? ps.hwdecMode : 'no')
        .catchError((_) {});
    platform.setProperty('video-sync', ps.videoSync).catchError((_) {});
                                 
    PlayerAudioService.apply(platform, ps.audioNormalization);
                                       
    SuperResolutionService.apply(platform, ps.superResolutionMode);
    _syncWindowAspectLock();
  }

                       

                        
  Future<void> _syncWindowAspectLock() async {
    final ps = _playerSettingsService;
    if (ps == null || !_isDesktop || !_isFullscreen) return;
    if (ps.keepWindowAspectRatio && !_keepWindowAspectRatio) {
      await _setupWindowAspectLock();
    } else if (!ps.keepWindowAspectRatio && _keepWindowAspectRatio) {
      await _releaseWindowAspectLock();
    }
  }

                         
                                                 
  Future<void> _setupWindowAspectLock() async {
    if (_keepWindowAspectRatio || !_isDesktop) return;
    final ps = _playerSettingsService;
    if (ps == null || !ps.keepWindowAspectRatio) return;
    try {
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isEmpty) return;
      final client = viewClientSize(views.first);
      if (client.width < 1 || client.height < 1) return;
      _windowAspectRatio = client.width / client.height;
      _lastAcceptedWindowSize = client;
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

                            
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
                                    
    if (_isDesktopPip) return;
    if (!_isDesktop || !_keepWindowAspectRatio || _windowAspectRatio <= 0) {
      return;
    }
    _enforceWindowAspectRatio();
  }

  Future<void> _enforceWindowAspectRatio() async {
    if (_isDesktopPip) return;
    if (_isCorrectingWindowSize) return;
    try {
      if (await windowManager.isMaximized() ||
          await windowManager.isFullScreen()) {
        return;
      }
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isEmpty) return;
      final view = views.first;
                                                    
                                       
                                        
                                        
      final client = viewClientSize(view);
      if (client.width < 1 || client.height < 1) return;

      final ratio = _windowAspectRatio;
      final prev = _lastAcceptedWindowSize;
      final dw = prev == null ? 1.0 : (client.width - prev.width).abs();
      final dh = prev == null ? 1.0 : (client.height - prev.height).abs();

                                   
      var corrected = dw > dh
          ? Size(client.width, client.width / ratio)
          : Size(client.height * ratio, client.height);

                                          
      final outer = await windowManager.getSize();
      final chrome = windowChrome(outer, client);
      if (corrected.width + chrome.width < 400) {
        final w = math.max(1.0, 400 - chrome.width);
        corrected = Size(w, w / ratio);
      }
      if (corrected.height + chrome.height < 300) {
        final h = math.max(1.0, 300 - chrome.height);
        corrected = Size(h * ratio, h);
      }

      if ((corrected.width - client.width).abs() < 1 &&
          (corrected.height - client.height).abs() < 1) {
        _lastAcceptedWindowSize = client;
        return;
      }

      _isCorrectingWindowSize = true;
      await windowManager.setSize(
        Size(corrected.width + chrome.width, corrected.height + chrome.height),
      );
      _isCorrectingWindowSize = false;
      _lastAcceptedWindowSize = corrected;
    } catch (e) {
      _isCorrectingWindowSize = false;
      if (kDebugMode) debugPrint('⚠️ 窗口等比例修正失败: $e');
    }
  }

                                  
  void _markStreamReady() {
    if (_streamReady) return;
    _streamReady = true;
    if (_danmakuPendingLoad) {
      _danmakuPendingLoad = false;
      unawaited(_autoLoadDanmakuIfEnabled());
    }
  }

                                          
                             
  Future<void> _streamReadyFallback(int seq) async {
    for (int i = 0; i < 80; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_disposed || !mounted || _streamReadySeq != seq) return;
      if (_streamReady) return;
    }
    if (_disposed || !mounted || _streamReadySeq != seq) return;
    _markStreamReady();
  }

  Future<void> _autoLoadDanmakuIfEnabled() async {
    final ps = _playerSettingsService;
    if (ps == null || !ps.loadDanmakuOnResume) return;
    final seq = ++_danmakuRequestSeq;

                                        
    String? source;
    String? type;
    if (_isPlaylistMode && _activePlaylist != null) {
      final item = _playlistItemFor(_currentEpisodeIndex);
      if (item?.danmakuSource?.isNotEmpty ?? false) {
        source = item!.danmakuSource;
        type = item.danmakuType ?? 'cid';
      }
    }
    source ??= widget.danmakuSource;
    type ??= widget.danmakuType;
                                                  
                        
    if (_currentInteractiveCid != null && _currentInteractiveCid! > 0) {
      source = _currentInteractiveCid.toString();
      type = 'cid';
    }
    if (source == null || source.isEmpty) return;
                                       
                                        
                                  
                                        
    if (!_streamReady) {
      _danmakuPendingLoad = true;
      debugPrint('⏳ 流未就绪，弹幕延迟加载: source=$source');
      return;
    }
    debugPrint('🔄 自动加载弹幕: source=$source, type=$type');
    try {
      final result = await DanmakuSegFetcher.fetch(
        input: source,
        inputType: type ?? 'bv',
      );
                                          
      if (!mounted || seq != _danmakuRequestSeq) return;
      if (result.success && result.items.isNotEmpty) {
        _danmakuController.setItems(result.items);
        _danmakuController.seekTo(position.inMilliseconds / 1000.0);
        if (player.state.playing) {
          _danmakuController.play();
        }
        setState(() {
          _danmakuLoaded = true;
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

                                  
                                 
  Future<void> _maybeQuerySponsorBlock() async {
    final ps = _playerSettingsService;
    if (ps == null || !ps.skipIntroOutro) return;
                                                    
                                   
    _loadPgcClips();
    if (_sponsorSegments.isNotEmpty) return;

                                                        
                                                 
    String? bvid = widget.bilibiliBvid;
    final cid = _videoshotCid;
    if (bvid == null || bvid.isEmpty) {
      String? source;
      String? type;
      if (_isPlaylistMode && _activePlaylist != null) {
        final item = _playlistItemFor(_currentEpisodeIndex);
        if (item?.danmakuSource?.isNotEmpty ?? false) {
          source = item!.danmakuSource;
          type = item.danmakuType ?? 'cid';
        }
      }
      source ??= _activeDanmakuSource ?? widget.danmakuSource;
      type ??= _activeDanmakuType ?? widget.danmakuType;
      if (source != null && source.isNotEmpty && type == 'bv') {
        bvid = source;
      }
    }
    if (bvid == null || bvid.isEmpty) return;
    if (!RegExp(r'^(BV|bv)[0-9A-Za-z]+$').hasMatch(bvid.trim())) return;

    final segments = await SponsorBlockService.fetchForVideo(
      bvid: bvid,
      cid: cid > 0 ? cid : null,
    );
    if (!mounted || segments == null || _disposed) return;
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

                                                
  void _loadPgcClips() {
    final ps = _playerSettingsService;
    if (ps == null) return;
    if (ps.pgcSkipMode == 'off' || !ps.skipIntroOutro) return;
    final clips = widget.playUrlInfo?.clipSegments ?? const [];
    if (clips.isEmpty) return;
    _pgcClipsEnabled = true;
    _applyPgcClips(clips);
  }

                              
  void _applyPgcClips(List<BiliClipSegment> clips) {
    final segs =
        clips
            .map(
              (c) => SponsorSegment(
                category: c.isOutro ? 'outro' : 'intro',
                startMs: c.startSec * 1000,
                endMs: c.endSec * 1000,
                uuid: 'pgc_${c.type}_${c.startSec}',
                fromPgc: true,
              ),
            )
            .toList()
          ..sort((a, b) => a.startMs.compareTo(b.startMs));
    if (mounted && !_disposed) {
      setState(() => _sponsorSegments = segs);
    } else {
      _sponsorSegments = segs;
    }
  }

                                             
  Future<void> _reloadPgcClipsForEpisode(PlaylistItem item) async {
    if (!_pgcClipsEnabled) return;
    final cid = int.tryParse(item.danmakuSource ?? '') ?? 0;
    if (cid <= 0) return;
    final listId = _activePlaylist?.id ?? '';
    if (!listId.startsWith('bili_ss_')) return;
    final seasonId = int.tryParse(listId.substring('bili_ss_'.length)) ?? 0;
    if (seasonId <= 0) return;
    final epId = item.id.startsWith('bili_ep_')
        ? int.tryParse(item.id.substring('bili_ep_'.length)) ?? 0
        : 0;
    try {
      final play = await BilibiliBangumiService.fetchPlayUrl(
        seasonId: seasonId,
        bvid: '',
        cid: cid,
        epId: epId,
      );
      if (_disposed || !mounted) return;
      final clips = play?.clipSegments ?? const [];
      if (clips.isEmpty) return;
      _applyPgcClips(clips);
    } catch (e) {
      debugPrint('⚠️ 重新拉取番剧跳过片段失败: $e');
    }
  }

                                        
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
                                         
        final mode = _playerSettingsService?.pgcSkipMode ?? 'button';
        if (seg.fromPgc && mode == 'auto') {
          seg.skipped = true;
          player.seek(Duration(milliseconds: seg.endMs));
          if (!player.state.playing) player.play();
          if (mounted) {
            showAppToast(context, seg.category == 'outro' ? '已跳过片尾' : '已跳过片头');
          }
          return;
        }
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

                                                               

  int get _videoshotCid =>
      int.tryParse(_activeDanmakuSource ?? widget.danmakuSource ?? '') ?? 0;

                                   
  Future<void> _ensureVideoshot() async {
    if (_videoShot != null || _previewLoading) return;
    final bvid = widget.bilibiliBvid ?? '';
    final cid = _videoshotCid;
    if (bvid.isEmpty || cid <= 0) return;
    _previewLoading = true;
    try {
      final data = await VideoshotService.fetch(bvid: bvid, cid: cid);
      if (data != null && mounted && !_disposed) _videoShot = data;
    } finally {
      _previewLoading = false;
    }
  }

                                   
  void _updateSeekPreview(Duration pos) {
    if (!(_playerSettingsService?.showSeekPreview ?? false)) return;
    final data = _videoShot;
    if (data == null) {
      _ensureVideoshot();
      return;
    }
    final sec = pos.inSeconds;
    var idx = data.index.where((t) => t <= sec).length - 2;
    if (idx < 0) idx = 0;
    if (idx >= data.index.length) idx = data.index.length - 1;
    if (!mounted || _disposed) return;
    setState(() {
      _previewIndex = idx;
      _showSeekPreviewOverlay = true;
    });
  }

  void _hideSeekPreview() {
    if (!_showSeekPreviewOverlay || !mounted) return;
    setState(() => _showSeekPreviewOverlay = false);
  }

                              
  Widget _buildSeekPreviewOverlay() {
    final data = _videoShot;
    if (!_showSeekPreviewOverlay || data == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BiliSeekPreview(data: data, index: _previewIndex),
    );
  }

                                                   

                                
  Future<void> _applySavedAudioDevice() async {
    final ps = _playerSettingsService;
    if (ps == null || ps.audioOutputDevice.isEmpty) return;
    try {
      var devices = player.state.audioDevices;
      if (devices.isEmpty) {
        devices = await player.stream.audioDevices
            .firstWhere((list) => list.isNotEmpty)
            .timeout(const Duration(seconds: 5));
      }
      for (final d in devices) {
        if (d.name == ps.audioOutputDevice) {
          await player.setAudioDevice(d);
          return;
        }
      }
    } catch (_) {
                        
    }
  }

                                         
  Future<void> _showAudioDeviceMenu() async {
    var devices = player.state.audioDevices;
    if (devices.isEmpty) {
      try {
        devices = await player.stream.audioDevices
            .firstWhere((list) => list.isNotEmpty)
            .timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
    if (!mounted || devices.isEmpty) {
      if (mounted) showAppToast(context, '没有检测到可用的音频输出设备');
      return;
    }
    final ps = _playerSettingsService;
    final current = ps?.audioOutputDevice ?? '';
                                                
                                   
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      title: '音频输出设备',
      items: [
        NativeMenuItem(
          text: '自动',
          icon: Icons.auto_awesome,
          checked: current.isEmpty,
          onTap: () => unawaited(_applyAudioDevice(AudioDevice.auto())),
        ),
        for (final d in devices)
          NativeMenuItem(
            text: d.description.isEmpty ? d.name : d.description,
            subtitle: d.description.isEmpty ? null : d.name,
            icon: Icons.speaker_outlined,
            checked: d.name == current,
            onTap: () => unawaited(_applyAudioDevice(d)),
          ),
      ],
    );
    if (nativeOk || !mounted) return;
    final picked = await showAppBottomSheet<AudioDevice>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                '音频输出设备',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, size: 20),
              title: const Text('自动', style: TextStyle(fontSize: 14)),
              trailing: current.isEmpty
                  ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
                  : null,
              onTap: () => Navigator.of(ctx).pop(AudioDevice.auto()),
            ),
            for (final d in devices)
              ListTile(
                leading: const Icon(Icons.speaker_outlined, size: 20),
                title: Text(
                  d.description.isEmpty ? d.name : d.description,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: d.description.isEmpty
                    ? null
                    : Text(d.name, style: const TextStyle(fontSize: 11)),
                trailing: d.name == current
                    ? const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.blueAccent,
                      )
                    : null,
                onTap: () => Navigator.of(ctx).pop(d),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await _applyAudioDevice(picked);
  }

                               
  Future<void> _applyAudioDevice(AudioDevice device) async {
    try {
      await player.setAudioDevice(device);
      await _playerSettingsService?.setAudioOutputDevice(
        device.name == 'auto' ? '' : device.name,
      );
      if (mounted) {
        showAppToast(
          context,
          device.name == 'auto'
              ? '已恢复自动输出'
              : '已切换音频输出：${device.description.isEmpty ? device.name : device.description}',
        );
      }
    } catch (e) {
      if (mounted) showAppToast(context, '切换失败：$e', error: true);
    }
  }

                                                
  Future<void> _showAudioNormalizationMenu() async {
    final ps = _playerSettingsService;
    if (ps == null) return;
    final current = ps.audioNormalization;
    const modes = [
      PlayerAudioService.modeDisable,
      PlayerAudioService.modeDynaudnorm,
      PlayerAudioService.modeLoudnorm,
    ];
                                                
                                   
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      title: '音量均衡',
      items: [
        for (final m in modes)
          NativeMenuItem(
            text: PlayerAudioService.label(m),
            icon: m == PlayerAudioService.modeDisable
                ? Icons.volume_off_outlined
                : Icons.graphic_eq,
            checked: m == current,
            onTap: () async {
              await ps.setAudioNormalization(m);
              if (mounted) {
                showAppToast(context, '已切换音量均衡：${PlayerAudioService.label(m)}');
              }
            },
          ),
      ],
    );
    if (nativeOk || !mounted) return;
    final picked = await showAppBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                '音量均衡',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            for (final m in modes)
              ListTile(
                leading: Icon(
                  m == PlayerAudioService.modeDisable
                      ? Icons.volume_off_outlined
                      : Icons.graphic_eq,
                  size: 20,
                ),
                title: Text(
                  PlayerAudioService.label(m),
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: m == current
                    ? const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.blueAccent,
                      )
                    : null,
                onTap: () => Navigator.of(ctx).pop(m),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await ps.setAudioNormalization(picked);
    if (mounted) {
      showAppToast(context, '已切换音量均衡：${PlayerAudioService.label(picked)}');
    }
  }

                                                   

  Future<void> _enterPiP() async {
    if (_isDesktop) {
      await _toggleDesktopPip();
      return;
    }
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

  Future<void> _toggleDesktopPip() async {
    if (_isDesktopPip) {
      await _exitDesktopPip();
    } else {
      await _enterDesktopPip();
    }
  }

                                              
  Future<void> _enterDesktopPip() async {
    if (!_isDesktop || _isDesktopPip) return;
    try {
      _lastWindowBounds = await windowManager.getBounds();
      final vw = player.state.width ?? 0;
      final vh = player.state.height ?? 0;
      final w = vw > 0 ? vw : 16;
      final h = vh > 0 ? vh : 9;
      final Size size = h > w
          ? Size(240, 240.0 * h / w)
          : Size(240.0 * w / h, 240);
      try {
        await windowManager.setAspectRatio(w / h);
      } catch (_) {}
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setMinimumSize(size);
      await windowManager.setSize(size);
      if (mounted) {
        setState(() => _isDesktopPip = true);
        showAppToast(context, '已进入画中画（返回键 / 再点一次退出）');
      }
    } catch (e) {
      debugPrint('⚠️ 进入桌面画中画失败: $e');
    }
  }

  Future<void> _exitDesktopPip() async {
    if (!_isDesktopPip) return;
    try {
      try {
        await windowManager.setAspectRatio(0);
      } catch (_) {}
      try {
        await windowManager.setMinimumSize(const Size(400, 300));
      } catch (_) {}
      final bounds = _lastWindowBounds;
      if (bounds != null) {
        await windowManager.setBounds(bounds);
      }
      await windowManager.setAlwaysOnTop(false);
    } catch (e) {
      debugPrint('⚠️ 退出桌面画中画失败: $e');
    }
    _lastWindowBounds = null;
    if (mounted) setState(() => _isDesktopPip = false);
  }

                                                           

             
  bool _recording = false;

                         
  bool _recordProcessing = false;

                                            
  Future<void>? _gifBgTask;

                                          
  static const int _gifLiveUpdateId = 4802;

                         
  Duration _recordStart = Duration.zero;

                      
  Duration _recordElapsed = Duration.zero;

                     
  Timer? _recordTimer;

                
  Timer? _recordTick;

  String get _recordFormatLabel =>
      (_playerSettingsService?.recordFormat ?? 'gif') == 'gif' ? 'GIF' : '动态照片';

  void _toggleRecording() {
    if (_recordProcessing) return;
    if (_recording) {
      _stopRecordingAndSave(auto: false);
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    if (_disposed || !_started) return;
    final ps = _playerSettingsService;
    if (ps == null) return;
    final maxSec = ps.recordMaxSeconds.clamp(2, 60);
    _recordTimer?.cancel();
    _recordTick?.cancel();
    setState(() {
      _recording = true;
      _recordStart = position;
      _recordElapsed = Duration.zero;
    });
    _recordTimer = Timer(Duration(seconds: maxSec), () {
      if (mounted && _recording) {
        showAppToast(context, '已达到最长 ${maxSec}s，自动保存');
        _stopRecordingAndSave(auto: true);
      }
    });
    _recordTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_recording) return;
      setState(() => _recordElapsed += const Duration(seconds: 1));
    });
    showAppToast(context, '开始录制 $_recordFormatLabel（最长 ${maxSec}s，再点一次保存）');
  }

                                  
  void _cancelRecording() {
    _recordTimer?.cancel();
    _recordTimer = null;
    _recordTick?.cancel();
    _recordTick = null;
    if (_recording && mounted) {
      setState(() {
        _recording = false;
        _recordElapsed = Duration.zero;
      });
    } else {
      _recording = false;
    }
  }

                                            
  Future<void> _stopRecordingAndSave({required bool auto}) async {
    if (!_recording || _recordProcessing) return;
    final ps = _playerSettingsService;
    if (ps == null) return;
    final start = _recordStart;
                                                  
    final maxEnd = start + Duration(seconds: ps.recordMaxSeconds.clamp(2, 60));
    var end = position;
    if (end > maxEnd) end = maxEnd;
    _recordTimer?.cancel();
    _recordTimer = null;
    _recordTick?.cancel();
    _recordTick = null;
    setState(() {
      _recording = false;
      _recordProcessing = true;
    });
    if (end - start < const Duration(milliseconds: 600)) {
      if (mounted) {
        showAppToast(context, '录制时间太短，已取消', error: true);
        setState(() => _recordProcessing = false);
      }
      return;
    }

    final isGif = ps.recordFormat == 'gif';
                                                             
                                    
                                  
    if (isGif && Platform.isAndroid) {
      final task = _processGifWithLiveUpdate(
        start: start,
        end: end,
        fps: ps.recordFps.toDouble(),
        width: ps.recordWidth,
      );
      _gifBgTask = task.then((_) {}, onError: (_) {});
      unawaited(_gifBgTask!.whenComplete(() => _gifBgTask = null));
      return;
    }
    final wasPlaying = player.state.playing;
    await player.pause();
    final progress = ValueNotifier<double>(0);
    if (!mounted) return;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(isGif ? '正在生成 GIF' : '正在生成动态照片'),
            content: ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (_, v, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: v),
                  const SizedBox(height: 12),
                  Text(
                    '${(v * 100).toStringAsFixed(0)}%'
                    '（${isGif ? '抓帧 + 编码' : '转码 + 合成'}，请稍候）',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    var ok = false;
    var albumOk = false;
    var savedPath = '';
    try {
      if (isGif) {
        final bytes = await VideoClipService.captureGif(
          player: player,
          startSec: start.inMilliseconds / 1000.0,
          endSec: end.inMilliseconds / 1000.0,
          fps: ps.recordFps.toDouble(),
          width: ps.recordWidth,
          onProgress: (v) => progress.value = v,
        );
        if (bytes != null) {
          final dir = await getTemporaryDirectory();
          final file = File(
            '${dir.path}/navi_clip_${DateTime.now().millisecondsSinceEpoch}.gif',
          );
          await file.writeAsBytes(bytes, flush: true);
          savedPath = file.path;
          ok = true;
          albumOk = await _saveToGallery(file.path, video: false);
        }
      } else {
        final url = _currentSourceUrl;
        if (url.isEmpty) throw StateError('没有可用的媒体地址');
                                           
        final item = _isPlaylistMode
            ? _playlistItemFor(_currentEpisodeIndex)
            : null;
        final headers = item?.headers ?? widget.httpHeaders;
        final dir = await getTemporaryDirectory();
        final stamp = DateTime.now().millisecondsSinceEpoch;
        final mp4Path = '${dir.path}/navi_clip_$stamp.mp4';
        final mp4 = await VideoClipService.transcodeMp4(
          player: player,
          url: item?.authenticatedUrl ?? url,
          outFile: mp4Path,
          startSec: start.inMilliseconds / 1000.0,
          endSec: end.inMilliseconds / 1000.0,
          headers: headers,
          onProgress: (v) => progress.value = v * 0.9,
        );
        if (mp4 != null) {
          if (Platform.isAndroid || Platform.isIOS) {
                                       
            final cover = await VideoClipService.captureCoverJpeg(
              player: player,
              atSec: start.inMilliseconds / 1000.0,
            );
            if (cover != null) {
              progress.value = 0.95;
              final mp4Bytes = await File(mp4).readAsBytes();
              final photo = MotionPhotoService.build(
                jpeg: cover,
                mp4: mp4Bytes,
              );
              if (photo != null) {
                final photoPath = '${dir.path}/navi_clip_$stamp.jpg';
                await File(photoPath).writeAsBytes(photo, flush: true);
                savedPath = photoPath;
                ok = true;
                albumOk = await _saveToGallery(photoPath, video: false);
              }
            }
          } else {
                           
            savedPath = mp4;
            ok = true;
            albumOk = await _saveToGallery(mp4, video: true);
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ 录制保存失败: $e');
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
                                    
      try {
        if (!isGif) {
          await player.seek(end);
          if (mounted) setState(() => _setPlaybackPosition(end));
        }
        if (wasPlaying && mounted) player.play();
      } catch (_) {}
      if (mounted) setState(() => _recordProcessing = false);
    }
    if (!mounted) return;
    if (!ok || savedPath.isEmpty) {
      showAppToast(
        context,
        isGif ? 'GIF 生成失败' : '动态照片生成失败（可能是播放器缺少 H.264 编码器）',
        error: true,
      );
    } else if (albumOk) {
      showAppToast(context, isGif ? 'GIF 已保存到相册' : '动态照片已保存到相册');
    } else {
      showAppToast(context, '已保存：$savedPath');
    }
  }

                                             
                                            
  Future<void> _processGifWithLiveUpdate({
    required Duration start,
    required Duration end,
    required double fps,
    required int width,
  }) async {
    const title = '正在生成 GIF';
    const phase = '抓帧 + 编码';
    await LiveUpdateService.start(_gifLiveUpdateId, title, text: '$phase…');
    var lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
    var lastPercent = -1;
    var ok = false;
    var albumOk = false;
    var savedPath = '';
    try {
      final bytes = await VideoClipService.captureGif(
        player: player,
        startSec: start.inMilliseconds / 1000.0,
        endSec: end.inMilliseconds / 1000.0,
        fps: fps,
        width: width,
        onProgress: (v) {
          final now = DateTime.now();
          final percent = (v * 100).round();
                                                 
                                         
          if (percent == lastPercent) return;
          if (percent < 100 &&
              now.difference(lastNotify) < const Duration(milliseconds: 800)) {
            return;
          }
          lastNotify = now;
          lastPercent = percent;
          LiveUpdateService.update(
            _gifLiveUpdateId,
            progress: percent,
            text: '$phase $percent%',
          );
        },
      );
      if (bytes != null) {
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/navi_clip_${DateTime.now().millisecondsSinceEpoch}.gif',
        );
        await file.writeAsBytes(bytes, flush: true);
        savedPath = file.path;
        ok = true;
        albumOk = await _saveToGallery(file.path, video: false);
      }
    } catch (e) {
      debugPrint('⚠️ 后台生成 GIF 失败: $e');
    } finally {
      if (mounted) setState(() => _recordProcessing = false);
    }
    if (ok && albumOk) {
      await LiveUpdateService.finish(
        _gifLiveUpdateId,
        title: title,
        text: 'GIF 已保存到相册',
      );
      if (mounted) showAppToast(context, 'GIF 已保存到相册');
    } else if (ok) {
      await LiveUpdateService.finish(
        _gifLiveUpdateId,
        title: title,
        text: '已保存：$savedPath',
      );
      if (mounted) showAppToast(context, '已保存：$savedPath');
    } else {
      await LiveUpdateService.fail(
        _gifLiveUpdateId,
        title: title,
        text: 'GIF 生成失败',
      );
      if (mounted) showAppToast(context, 'GIF 生成失败', error: true);
    }
  }

                                           
  Future<bool> _saveToGallery(String path, {required bool video}) async {
    try {
      if (video) {
        await Gal.putVideo(path);
      } else {
        await Gal.putImage(path);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

                                                   

                         
  String? _speedTestUrlFor(_SourceEntry entry) {
    final info = widget.playUrlInfo;
    if (info == null) return null;
    final v = BilibiliVideoService.pickVideoStream(
      info,
      quality: _currentQn,
      preferCodecs: _codecPrefixes(_decodeFormat),
    );
    if (v == null) return null;
    if (entry.host != null && entry.host!.isNotEmpty) {
      final base = v.baseUrl.isNotEmpty
          ? v.baseUrl
          : (v.allUrls.isNotEmpty ? v.allUrls.first : '');
      if (base.isEmpty) return null;
      try {
        return Uri.parse(base).replace(host: entry.host!).toString();
      } catch (_) {
        return null;
      }
    }
    final urls = v.allUrls.toList();
    return entry.index < urls.length ? urls[entry.index] : null;
  }

                         
  Future<void> _runCdnSpeedTest() async {
    final entries = _sourceEntries();
    final byUrl = <String, _SourceEntry>{};
    final candidates = <CdnCandidate>[];
    for (final e in entries) {
      final url = _speedTestUrlFor(e);
      if (url != null && url.isNotEmpty) {
        byUrl.putIfAbsent(url, () => e);
        candidates.add(CdnCandidate(label: e.label, url: url));
      }
    }
    if (candidates.isEmpty || !mounted) return;
    final picked = await showCdnSpeedTestDialog(
      context,
      candidates: candidates,
      headers: widget.httpHeaders,
      currentLabel: _currentSourceLabel,
    );
    if (picked == null || !mounted) return;
    final entry = byUrl[picked.url];
    if (entry != null) await _switchSource(entry);
  }

                      

                                               
                                     
                                         
  PlaylistItem? _playlistItemFor(int index) {
    final items = _activePlaylist?.items;
    if (items == null) return null;
    for (final it in items) {
      if (it.index == index) return it;
    }
    return null;
  }

  Future<void> _switchToEpisode(int index) async {
    if (_activePlaylist == null) return;
    if (index < 0) return;
    final item = _playlistItemFor(index);
    if (item == null) {
      debugPrint('⚠️ switchEpisode: 第${index + 1}集未解析成功，无法切换');
      return;
    }

                                                    
                                  
    _saveHistoryNow(widget.historyId);

    setState(() {
      _currentEpisodeIndex = index;
      _videoTitle = item.title;
      isFinished = false;
      _setPlaybackPosition(Duration.zero);
      duration = Duration.zero;
      _setBufferPosition(Duration.zero);
      _lastPlayerError = null;
      _showEpisodePanel = false;
      _orientationLocked = false;
                                           
      _activeBiliSubtitle = null;
    });
    _setBuffering(false);
    widget.onEpisodeChanged?.call(index);

                      
    _clearSponsorBlock();
                        
    if (_recording) {
      _cancelRecording();
      if (mounted) showAppToast(context, '切换分集，录制已取消');
    }
    _videoShot = null;
                                       
    unawaited(_reloadPgcClipsForEpisode(item));

                                          
                                                  
    _danmakuRequestSeq++;
    _danmakuController.setItems([]);
    _danmakuController.pause();
    _danmakuLoaded = false;
    _activeDanmakuSource = null;
    _activeDanmakuType = null;

    await player.stop();
    await _openMedia(
      item.url,
      headers: item.headers,
      subtitleUrl: item.subtitleUrl,
      subtitleHeaders: item.headers,
    );
    if (_disposed || !mounted) return;

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
                                    
    final reverse = _settingsService?.playlistReversePlay ?? false;
    final next = _nextExistingEpisode(reverse ? -1 : 1);
    if (next != null) {
      _switchToEpisode(next);
    } else {
               
      setState(() {
        isFinished = true;
        showControls = true;
      });
    }
  }

  void _playPrevEpisode() {
    if (!_isPlaylistMode) return;
                         
    final reverse = _settingsService?.playlistReversePlay ?? false;
    final prev = _nextExistingEpisode(reverse ? 1 : -1);
    if (prev != null) {
      _switchToEpisode(prev);
    }
  }

                                              
                                       
                               
  int? _nextExistingEpisode(int step) {
    final items = _activePlaylist?.items;
    if (items == null || items.isEmpty) return null;
    final indexes = items.map((e) => e.index).toList()..sort();
    if (step > 0) {
      for (final i in indexes) {
        if (i > _currentEpisodeIndex) return i;
      }
    } else {
      for (final i in indexes.reversed) {
        if (i < _currentEpisodeIndex) return i;
      }
    }
    return null;
  }

                        

                              
  Future<void> switchEpisode(int index) => _switchToEpisode(index);

                             
                                                 
                           
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

                                                 
  PlayerSettingsService? _readPlayerSettings() {
    try {
      return context.read<PlayerSettingsService>();
    } catch (_) {
      return null;
    }
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
                                                        
                                               
                                                           
                                            
    await set('demuxer-max-bytes', '32MiB');
    await set('demuxer-max-back-bytes', '16MiB');
                                  
    await set('demuxer-readahead-secs', '5');
    await set('network-timeout', '30');

    final ps = _playerSettingsService ?? _readPlayerSettings();
    if (ps != null) {
      await set('hwdec', ps.hwdecEnabled ? ps.hwdecMode : 'no');
      await set('video-sync', ps.videoSync);
                                            
      await PlayerAudioService.apply(platform, ps.audioNormalization);
    }

                                    
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
                                                           
      _streamReady = false;
      final readySeq = ++_streamReadySeq;
      final hasEmbeddedAuth = _urlHasEmbeddedAuth(url);
      final effectiveHeaders = hasEmbeddedAuth ? null : headers;
      debugPrint('🎬 open: $url  (embeddedAuth=$hasEmbeddedAuth)');
      await player.open(Media(url, httpHeaders: effectiveHeaders));
      debugPrint('✅ open 完成, duration=${player.state.duration}');
      if (player.state.duration > Duration.zero) {
        _markStreamReady();
      } else {
        unawaited(_streamReadyFallback(readySeq));
      }
                                             
      if (onlyPlayAudio) await _applyOnlyPlayAudio();
                                        
      unawaited(_applySavedAudioDevice());

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

                                     
     
                                                 
                                   
  Future<void> setOnlyPlayAudio(bool value) async {
    if (onlyPlayAudio == value) return;
    onlyPlayAudio = value;
    if (mounted) setState(() {});
    widget.onOnlyPlayAudioChanged?.call(value);
    await _applyOnlyPlayAudio();
  }

                       
     
              
                                            
                                                          
                          
  Future<void> _applyOnlyPlayAudio() async {
    final platform = player.platform;
    if (platform is! NativePlayer) return;
    final v = onlyPlayAudio ? 'no' : 'auto';
    for (final key in const ['vid', 'file-local-options/vid']) {
      try {
        await platform.setProperty(key, v);
      } catch (e) {
        debugPrint('⚠️ setProperty($key) 失败: $e');
      }
    }
  }

  bool _urlHasEmbeddedAuth(String url) {
    try {
      return Uri.parse(url).userInfo.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

                                                                   
                                   
    
                                                     
                                      
                                                                   

                              
  bool get isFullscreenMode => _isFullscreen;

                                       
  EndBehavior get currentEndBehavior => endBehavior;

                             
  void openDanmakuSettings() => _toggleDanmakuSettings();

                            
  void openSubtitleSettings() {
    if (!mounted) return;
    setState(() {
      _showSubtitlePanel = true;
      _showSettingsPanel = false;
      _showDanmakuPanel = false;
      _showEpisodePanel = false;
    });
  }

                                
                                                             
                                                                            
                      
  void showPlaybackStats() => _openStatsDialog();

                                     
  Future<void> _openStatsDialog() async {
    if (Platform.isWindows || Platform.isAndroid) {
                                                 
                                         
                                               
                         
      if (Platform.isAndroid) _ensurePlayerStatsOn();
                                
      await _refreshStatsOnce();
      unawaited(_showStatsNativeDialog());
      return;
    }
    _togglePlayerStats();
  }

                                       
                      
  Future<void> _refreshStatsOnce() async {
    final platform = player.platform;
    if (platform is! NativePlayer) return;
    try {
      final vCodec = await platform.getProperty('video-codec');
      final aCodec = await platform.getProperty('audio-codec');
      final bitrateStr = await platform.getProperty('video-bitrate');
      final fpsStr = await platform.getProperty('container-fps');
      final hwdec = await platform.getProperty('hwdec-current');
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
  }

                                       
                                    
  bool _playerStatsVisible() {
    if (!mounted) return false;
    try {
      return context.read<SettingsService>().showPlayerStats;
    } catch (_) {
      return false;
    }
  }

                                             
  void _ensurePlayerStatsOn() {
    if (!mounted) return;
    try {
      final settings = context.read<SettingsService>();
      if (!settings.showPlayerStats) settings.setShowPlayerStats(true);
    } catch (_) {
                                   
    }
  }

                 
  void toggleFlipX() {
    if (!mounted) return;
    setState(() => isFlipX = !isFlipX);
  }

                 
  void toggleFlipY() {
    if (!mounted) return;
    setState(() => isFlipY = !isFlipY);
  }

  bool get currentFlipX => isFlipX;

  bool get currentFlipY => isFlipY;

                                       
  Future<void> showAudioNormalizationMenu() => _showAudioNormalizationMenu();

               
  Future<void> showAudioDeviceMenu() => _showAudioDeviceMenu();

                               
  void showSourceMenu() => _showSourceSubMenu();

                                     
     
                                                
                                      
  Future<void> captureScreenshot() async {
    final pngBytes = await captureCurrentFrame();
    if (!mounted) return;
    if (pngBytes == null) {
      showAppToast(context, L10n.current.playerScreenshotFailed('capture'));
      return;
    }
    await ScreenshotDialog.show(context, pngBytes);
  }

                                            
  Future<void> cycleEndBehavior() async {
    if (!mounted) return;
    final next = switch (endBehavior) {
      EndBehavior.pause => EndBehavior.loop,
      EndBehavior.loop => EndBehavior.exit,
      EndBehavior.exit => EndBehavior.pause,
    };
    setState(() => endBehavior = next);
    try {
      await context.read<SettingsService>().setPlayerEndBehavior(
        _endBehaviorToString(next),
      );
    } catch (_) {
                                              
    }
  }

                                               
  Future<void> showSuperResolutionMenu() async {
    if (!mounted) return;
    final l10n = L10n.current;
    final settings = context.read<PlayerSettingsService>();
    final current = settings.superResolutionMode;
                                                
                                   
    const modes = [
      SuperResolutionService.modeDisable,
      SuperResolutionService.modeEfficiency,
      SuperResolutionService.modeQuality,
    ];
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      title: l10n.superResolutionTitle,
      items: [
        for (final mode in modes)
          NativeMenuItem(
            text: switch (mode) {
              SuperResolutionService.modeEfficiency =>
                l10n.superResolutionEfficiency,
              SuperResolutionService.modeQuality => l10n.superResolutionQuality,
              _ => l10n.superResolutionOff,
            },
            icon: Icons.high_quality_outlined,
            checked: mode == current,
            onTap: () async {
              if (mode == current) return;
              await applySuperResolution(mode);
            },
          ),
      ],
    );
    if (nativeOk || !mounted) return;
    final picked = await showAppBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in [
              SuperResolutionService.modeDisable,
              SuperResolutionService.modeEfficiency,
              SuperResolutionService.modeQuality,
            ])
              ListTile(
                dense: true,
                title: Text(switch (mode) {
                  SuperResolutionService.modeEfficiency =>
                    l10n.superResolutionEfficiency,
                  SuperResolutionService.modeQuality =>
                    l10n.superResolutionQuality,
                  _ => l10n.superResolutionOff,
                }, style: const TextStyle(fontSize: 14)),
                trailing: mode == current
                    ? const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.blueAccent,
                      )
                    : null,
                onTap: () => Navigator.of(ctx).pop(mode),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == current) return;
    await applySuperResolution(picked);
  }

                                              

                                                
                                              
                                                   
  final ValueNotifier<int> _uiRevision = ValueNotifier<int>(0);

  void _bumpUiRevision() {
    if (!mounted) return;
    _uiRevision.value++;
  }

                                         
  Widget buildSubtitleSettingsBody() => ValueListenableBuilder<int>(
    valueListenable: _uiRevision,
    builder: (context, _, __) => _buildSubtitleSettingsBody(embedded: true),
  );

                            
  Widget buildAudioDeviceBody() {
    return _AudioDevicePanel(
      player: player,
      current: _playerSettingsService?.audioOutputDevice ?? '',
      onPick: (device) => unawaited(_applyAudioDevice(device)),
    );
  }

                                         
  static const List<String> audioNormalizationModes = [
    PlayerAudioService.modeDisable,
    PlayerAudioService.modeDynaudnorm,
    PlayerAudioService.modeLoudnorm,
  ];

  String get audioNormalizationValue =>
      _playerSettingsService?.audioNormalization ??
      PlayerAudioService.modeDisable;

                             
  Future<void> applyAudioNormalization(String mode) async {
    final ps = _playerSettingsService;
    if (ps == null) return;
    await ps.setAudioNormalization(mode);
    final platform = player.platform;
    if (platform is NativePlayer) {
      await PlayerAudioService.apply(platform, mode);
    }
  }

                           
  static const List<String> superResolutionModes = [
    SuperResolutionService.modeDisable,
    SuperResolutionService.modeEfficiency,
    SuperResolutionService.modeQuality,
  ];

  String get superResolutionValue =>
      _playerSettingsService?.superResolutionMode ??
      SuperResolutionService.modeDisable;

                          
  Future<void> applySuperResolution(String mode) async {
    final ps = _playerSettingsService;
    if (ps == null) return;
    await ps.setSuperResolutionMode(mode);
    final platform = player.platform;
    if (platform is NativePlayer) {
      await SuperResolutionService.apply(platform, mode);
    }
  }

                           
  List<({String label, bool selected})> get sourceOptions => [
    for (final e in _sourceEntries())
      (
        label: e.label,
        selected: e.index == _sourceIndex && e.host == _sourceHost,
      ),
  ];

                                          
  Future<void> selectSourceAt(int index) async {
    final entries = _sourceEntries();
    if (index < 0 || index >= entries.length) return;
    await _switchSource(entries[index]);
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
      _setPlaybackPosition(Duration.zero);
      duration = Duration.zero;
      _setBufferPosition(Duration.zero);
      _lastPlayerError = null;
      _orientationLocked = false;
    });
    _setBuffering(false);

                      
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

                                             
     
                                                           
                                        
  void _goHome() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

                    

  Future<void> _openDlnaCast() async {
    final url = _currentSourceUrl;
    if (url.isEmpty) return;

                                                  
    final isHttp = url.startsWith('http://') || url.startsWith('https://');
    final isLocal = !isHttp && File(url).existsSync();

    final displayTitle = _videoTitle;

                            
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

                                                
    if (mounted && wasPlaying) {
      player.play();
    }
  }

                   

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
    });

                                
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
                                         
      if (_isFullscreen &&
          settings.autoPiPOnBackground &&
          Platform.isAndroid &&
          player.state.playing) {
        _enterPiP();
      }
    }
  }

  Future<void> _generateThumbnail() async {
    await _generateThumbnailForUrl(widget.videoUrl);
  }

                                
  bool _isLocalVideoPath(String url) {
    try {
      final uri = Uri.parse(url);
      final scheme = uri.scheme.toLowerCase();
                                               
      if (scheme == 'file') return true;
      if (scheme.isNotEmpty && scheme.length > 1) return false;
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _generateThumbnailForUrl(String url) async {
                                                 
                                                 
                                   
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
                                    
    widget.onExit?.call(position);
    super.deactivate();
  }

                                                                  
     
                                                  
                                                                          
                                                            
                                                           
                                        
                                                     
     
                                                 
                                               
                               
  @override
  void activate() {
    _disposed = false;
    super.activate();
  }

  @override
  void dispose() {
    _uiRevision.dispose();
                            
    if (_isDesktopPip) {
      unawaited(_exitDesktopPip());
    }
    PlaybackFocus.instance.unregister(this);
    SleepTimerService.instance.unbindPauseTarget(this);
    _wheelVolumeTimer?.cancel();
                                          
    TaskbarProgress.end(_taskbarBufferingToken);
    TaskbarProgress.end(_taskbarOpenToken);
    _playerSettingsService?.removeListener(_onPlayerSettingsChanged);
    _releaseWindowAspectLock();
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _keyHoldTimer?.cancel();
    _recordTimer?.cancel();
    _recordTick?.cancel();
    _historySaveTimer?.cancel();
    _screenshotTimer?.cancel();
    _speedCalcTimer?.cancel();
    _statsTimer?.cancel();
    _skipPromptTimer?.cancel();
    _danmakuPlayingSub?.cancel();
    _danmakuPositionSub?.cancel();
    _mpvLogSub?.cancel();
                                 
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

                                            
    audioHandler
      ..onSkipToNext = null
      ..onSkipToPrevious = null;
    audioHandler.stop();
                                                    
                           
    final gifTask = _gifBgTask;
    if (gifTask != null) {
      unawaited(gifTask.whenComplete(() => player.dispose()));
    } else {
      player.dispose();
    }
    _statsChannel.setMethodCallHandler(null);
    _positionNotifier.dispose();
    _bufferNotifier.dispose();
    super.dispose();
  }

  void _saveProgressOnExit() {
                              
    if (!widget.recordHistory) {
      debugPrint('🚫 外部打开的视频，跳过播放历史记录');
      return;
    }
                                  
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
                                              
      _reportBiliProgressIfNeeded(posMs);
      debugPrint('💾 保存进度: pos=${posMs}ms, dur=${durMs}ms, title=$_videoTitle');
      _saveHistoryNow(widget.historyId);
                                       
      _recordWatchHistory(posMs, durMs);
    }
  }

                                            
                                        
  void _setBuffering(bool value) {
    if (_isBuffering == value) return;
    if (!mounted) return;
                                         
    if (value) _bufferingWatchdogPos = null;
    setState(() => _isBuffering = value);
    if (value) {
      TaskbarProgress.begin(_taskbarBufferingToken);
    } else {
      TaskbarProgress.end(_taskbarBufferingToken);
    }
  }

                                         
                                                         
  void _saveHistoryNow(String? historyId) {
                              
    if (!widget.recordHistory) return;
                      
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

                                         
                                                      
  void _reportBiliProgressIfNeeded(int posMs) {
                        
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

                                
                                                 
  void _recordWatchHistory(int posMs, int durMs) {
    final wh = _watchHistoryService;
    if (wh == null) return;
    final bvid = widget.bilibiliBvid;
    if (bvid == null || bvid.isEmpty) return;
    final aid = BvAv.decode(bvid);
    final cid = int.tryParse(
      _activeDanmakuSource ?? widget.danmakuSource ?? '',
    );
    wh.record(
      WatchHistoryEntry(
        bvid: bvid,
        aid: aid,
        cid: cid,
        title: _videoTitle,
        coverUrl: widget.coverUrl ?? _thumbnailPath,
        upperName: widget.artist,
        positionMs: posMs,
        durationMs: durMs,
        watchedAt: DateTime.now(),
      ),
    );
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

                          
  void _togglePlayPause() {
    if (player.state.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  void _handleTap() {
                                
                                       
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
                                
    if (player.state.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  void _changeRate(double rate) {
    setState(() {
      currentRate = rate;
      player.setRate(rate);
    });
  }

                                             
                                   
                                         
  Future<void> _switchQuality(int qn) async {
    if (qn == _currentQn) return;
                                                 
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
    final url = await _resolveQualityUrl(
      qn,
      audioId: _currentAudioId > 0 ? _currentAudioId : null,
    );
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
              
    if (resume > Duration.zero) {
      await _seekToReady(resume);
    }
    if (_disposed || !mounted) return;
    player.setRate(currentRate);
    if (wasPlaying) player.play();
    _resetHideTimer();
  }

                  
                                                   
                   
                                               
                      
     
                                                                     
                            
  Future<String?> _resolveQualityUrl(int qn, {int? audioId}) async {
    final preferCodecs = _codecPrefixes(_decodeFormat);
                                                     
                                                              
                                       
                                                 
                          
    final onInteractiveStartNode =
        _currentInteractiveCid == null ||
        _currentInteractiveCid.toString() == (widget.danmakuSource ?? '');
    if (_currentEpisodeIndex == _mountedEpisodeIndex &&
        widget.playUrlInfo != null &&
        onInteractiveStartNode) {
      return BilibiliVideoService.buildPlayableUrl(
        widget.playUrlInfo!,
        quality: qn,
        preferCodecs: preferCodecs,
        sourceIndex: _sourceIndex,
        sourceHost: _sourceHost,
        audioId: audioId,
      );
    }
    final item = _playlistItemFor(_currentEpisodeIndex);
    final cid =
        _currentInteractiveCid ?? int.tryParse(item?.danmakuSource ?? '');
    final id = _activePlaylist?.id ?? '';
    String? bvid;
    if (id.startsWith('bili_')) {
      final bv = id.substring(5);
      if (bv.isNotEmpty) bvid = bv;
    }
    bvid ??= _interactiveBvid ?? widget.bilibiliBvid;
    if (bvid == null || cid == null) {
                                                           
                                               
      return _resolveCheeseQualityUrl(qn, audioId: audioId);
    }
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
            audioId: audioId,
          );
  }

                                      
                                                           
                                                  
  Future<String?> _resolveCheeseQualityUrl(int qn, {int? audioId}) async {
    final listId = _activePlaylist?.id ?? '';
    if (!listId.startsWith('cheese_ss_')) return null;
    final seasonId = int.tryParse(listId.substring('cheese_ss_'.length)) ?? 0;
    if (seasonId <= 0) return null;
    final item = _playlistItemFor(_currentEpisodeIndex);
    final itemId = item?.id ?? '';
    final epId = itemId.startsWith('cheese_ep_')
        ? int.tryParse(itemId.substring('cheese_ep_'.length)) ?? 0
        : 0;
    if (epId <= 0) return null;
    final r = await BilibiliCheeseService.fetchPlayUrl(
      seasonId: seasonId,
      epId: epId,
      cid: int.tryParse(item?.danmakuSource ?? '') ?? 0,
      qn: qn,
    );
    if (r == null) return null;
    return BilibiliVideoService.buildPlayableUrl(
      r.playUrl,
      quality: qn,
      sourceIndex: _sourceIndex,
      sourceHost: _sourceHost,
      audioId: audioId,
    );
  }

                                            
                                           
                   
  String _initialOpenUrl() {
    final info = widget.playUrlInfo;
    final saved = _currentAudioId;
    if (info == null || saved <= 0) return widget.videoUrl;
    if (info.allAudioStreams.length < 2) return widget.videoUrl;
    final exists = info.allAudioStreams.any((s) => s.id == saved);
    if (!exists) return widget.videoUrl;
    final rebuilt = BilibiliVideoService.buildPlayableUrl(
      info,
      quality: _currentQn > 0 ? _currentQn : null,
      audioId: saved,
    );
    return rebuilt ?? widget.videoUrl;
  }

                                              

                                
  List<BiliDashStream> get _audioTracks =>
      widget.playUrlInfo?.allAudioStreams ?? const [];

                             
  String get _currentAudioShortLabel {
    if (_currentAudioId <= 0) return '音质';
    final tracks = _audioTracks;
    for (var i = 0; i < tracks.length; i++) {
      if (tracks[i].id == _currentAudioId) {
        return BilibiliVideoService.audioQualityShortLabel(
          tracks[i].id,
          bandwidth: tracks[i].bandwidth,
          index: i,
        );
      }
    }
    return '音质';
  }

                                   
  Widget _buildAudioMenu() {
    if (_audioTracks.length < 2) return const SizedBox.shrink();
    return LiquidGlassMenuButton(
      icon: Icons.music_note_outlined,
      iconColor: Colors.white,
      useMorphStyle: false,
      iconSize: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      tooltip: '音质',
      menuWidth: 230,
      customChild: Text(
        _currentAudioShortLabel,
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: _audioMenuActions(),
    );
  }

                                       
  List<GlassMenuAction> _audioMenuActions() {
    final tracks = _audioTracks;
    if (tracks.length < 2) return const [];
    final best = tracks.reduce((a, b) => a.bandwidth > b.bandwidth ? a : b);
    return [
      GlassMenuAction(
        icon: Icons.auto_awesome_outlined,
        text: '自动（最高码率）',
        trailing: _currentAudioId <= 0
            ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
            : null,
        onTap: () => _switchAudioQuality(0),
      ),
      for (var i = 0; i < tracks.length; i++)
        GlassMenuAction(
          icon: Icons.music_note_outlined,
          text: BilibiliVideoService.audioQualityLabel(
            tracks[i].id,
            bandwidth: tracks[i].bandwidth,
            index: i,
          ),
          trailing:
              _currentAudioId == tracks[i].id ||
                  (_currentAudioId <= 0 && tracks[i].id == best.id)
              ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
              : null,
          onTap: () => _switchAudioQuality(tracks[i].id),
        ),
    ];
  }

                                      
                                     
  Future<void> _switchAudioQuality(int id) async {
    if (id == _currentAudioId) return;
    final ps = _playerSettingsService ?? _readPlayerSettings();
    if (!_started) {
                                                
      setState(() => _currentAudioId = id);
      ps?.setDefaultAudioQualityId(id);
      _resetHideTimer();
      return;
    }
    final url = await _resolveQualityUrl(_currentQn, audioId: id);
    if (url == null) {
      if (mounted) showAppToast(context, '切换音质失败', error: true);
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
    setState(() => _currentAudioId = id);
    ps?.setDefaultAudioQualityId(id);
    if (resume > Duration.zero) await _seekToReady(resume);
    if (_disposed || !mounted) return;
    player.setRate(currentRate);
    if (wasPlaying) player.play();
    _resetHideTimer();
  }

                                                  

                              
  bool get _interactiveChoicesVisible =>
      _interactiveChoices.isNotEmpty && !_interactiveSwitching;

                                               
  Future<void> _maybeInitInteractive() async {
    if (!widget.isInteractiveVideo || !_isBiliSource) return;
    final bvid = _interactiveBvid;
    if (bvid == null || bvid.isEmpty) return;
    final cid =
        _currentInteractiveCid ?? int.tryParse(widget.danmakuSource ?? '') ?? 0;
    final aid = BvAv.decode(bvid) ?? 0;
    final seq = ++_interactiveReqSeq;
    final graph = await BilibiliInteractiveService.fetchGraphVersion(
      aid: aid,
      cid: cid,
    );
    if (_disposed || !mounted || seq != _interactiveReqSeq) return;
    if (graph.graphVersion <= 0) {
      debugPrint('[Interactive] 剧情图版本获取失败: ${graph.err}');
      return;
    }
    _interactiveGraphVersion = graph.graphVersion;
    await _loadInteractiveNode(edgeId: 0, pushPath: false, seq: seq);
  }

                                   
                                                   
  Future<void> _loadInteractiveNode({
    required int edgeId,
    required bool pushPath,
    required int seq,
    String? chosenOption,
  }) async {
    final bvid = _interactiveBvid;
    if (bvid == null || _interactiveGraphVersion <= 0) return;
                      
    var node = _interactiveNodeCache[edgeId];
    if (node == null) {
      final res = await BilibiliInteractiveService.fetchEdge(
        bvid: bvid,
        graphVersion: _interactiveGraphVersion,
        edgeId: edgeId,
      );
      if (_disposed || !mounted || seq != _interactiveReqSeq) return;
      node = res.node;
      if (node == null) {
        if (mounted) {
          showAppToast(context, '互动节点获取失败：${res.err ?? '未知错误'}', error: true);
        }
        return;
      }
      _interactiveNodeCache[edgeId] = node;
    }
                        
    if (pushPath && _interactiveNode != null) {
      _interactivePath = [
        ..._interactivePath,
        _InteractiveStep(
          edgeId: _interactiveNode!.edgeId,
          cid: _currentInteractiveCid ?? _interactiveNode!.cid,
          title: _interactiveNode!.title,
          chosenOption: chosenOption ?? '',
        ),
      ];
    }
    final question = node.activeQuestion;
    setState(() {
      _interactiveNode = node;
      _interactiveChoices = question?.choices ?? const [];
    });
                                            
    if (question != null && question.pauseVideo && player.state.playing) {
      await player.pause();
    }
    _resetHideTimer();
  }

                                       
  Future<void> _chooseInteractiveChoice(BiliInteractiveChoice choice) async {
    if (_interactiveSwitching || _disposed) return;
    final targetCid = choice.cid;
    if (targetCid <= 0 || choice.id <= 0) return;
    setState(() {
      _interactiveSwitching = true;
      _interactiveChoices = const [];
    });
    final ok = await _switchInteractiveCid(targetCid);
    if (!ok || _disposed || !mounted) {
      if (mounted) {
        setState(() => _interactiveSwitching = false);
      }
      return;
    }
    widget.onInteractiveNodeChanged?.call(targetCid);
    if (mounted) {
      showAppToast(context, '已选择：${choice.option}');
    }
    final seq = _interactiveReqSeq;
    await _loadInteractiveNode(
      edgeId: choice.id,
      pushPath: true,
      seq: seq,
      chosenOption: choice.option,
    );
    if (_disposed || !mounted) return;
    setState(() => _interactiveSwitching = false);
  }

                                        
  Future<void> _backToPreviousInteractiveNode() async {
    if (_interactiveSwitching || _interactivePath.isEmpty) return;
    final step = _interactivePath.last;
    setState(() {
      _interactiveSwitching = true;
      _interactiveChoices = const [];
      _interactivePath = _interactivePath.sublist(
        0,
        _interactivePath.length - 1,
      );
    });
    final ok = await _switchInteractiveCid(step.cid);
    if (!ok || _disposed || !mounted) {
      if (mounted) setState(() => _interactiveSwitching = false);
      return;
    }
    widget.onInteractiveNodeChanged?.call(step.cid);
    final seq = _interactiveReqSeq;
    await _loadInteractiveNode(edgeId: step.edgeId, pushPath: false, seq: seq);
    if (_disposed || !mounted) return;
    setState(() => _interactiveSwitching = false);
  }

                                   
  void reshowInteractiveChoices() {
    final question = _interactiveNode?.activeQuestion;
    if (question == null) return;
    setState(() => _interactiveChoices = question.choices);
                                     
    if (question.pauseVideo && player.state.playing) {
      unawaited(player.pause());
    }
  }

                                                
                         
  Future<bool> _switchInteractiveCid(int cid) async {
    final bvid = _interactiveBvid ?? widget.bilibiliBvid;
    if (bvid == null || bvid.isEmpty) return false;
    final play = await BilibiliVideoService.fetchPlayUrl(
      bvid: bvid,
      cid: cid,
      qn: _currentQn,
    );
    if (play == null || _disposed || !mounted) return false;
    final url = BilibiliVideoService.buildPlayableUrl(
      play,
      quality: _currentQn > 0 ? _currentQn : null,
      preferCodecs: _codecPrefixes(_decodeFormat),
      sourceIndex: _sourceIndex,
      sourceHost: _sourceHost,
      audioId: _currentAudioId > 0 ? _currentAudioId : null,
    );
    if (url == null) return false;
                                                
    setState(() {
      _currentInteractiveCid = cid;
      isFinished = false;
      _setPlaybackPosition(Duration.zero);
      duration = Duration.zero;
      _setBufferPosition(Duration.zero);
      _lastPlayerError = null;
      _activeBiliSubtitle = null;
      _videoShot = null;
    });
    _clearSponsorBlock();
                                      
    _danmakuRequestSeq++;
    _danmakuController.setItems([]);
    _danmakuController.pause();
    _danmakuLoaded = false;
    _activeDanmakuSource = null;
    _activeDanmakuType = null;
    _streamReady = false;
    await player.stop();
    await _openMedia(
      url,
      headers: widget.httpHeaders,
      subtitleUrl: widget.subtitleUrl,
      subtitleHeaders: widget.httpHeaders,
    );
    if (_disposed || !mounted) return true;
    _autoLoadDanmakuIfEnabled();
    player.setRate(currentRate);
    _generateThumbnailForUrl(url);
    return true;
  }

                                              
  Widget _buildInteractiveChoiceCard() {
    final node = _interactiveNode;
    final cs = Theme.of(context).colorScheme;
    return Positioned(
      left: 0,
      right: 0,
      bottom: _isFullscreen ? 96 : 64,
      child: Center(
        child: Container(
          width: math.min(MediaQuery.sizeOf(context).width * 0.86, 460),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                               
              Row(
                children: [
                  Icon(Icons.alt_route, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      node == null || node.title.isEmpty
                          ? '互动视频 · 请选择'
                          : '互动视频 · ${node.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (_interactivePath.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '路径：${_interactivePath.map((s) => s.chosenOption.isEmpty ? s.title : s.chosenOption).join(' → ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
              const SizedBox(height: 10),
                     
              for (final choice in _interactiveChoices) ...[
                Material(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _chooseInteractiveChoice(choice),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              choice.option,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
                              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed:
                        _interactivePath.isEmpty ||
                            (node?.noBacktracking ?? false)
                        ? null
                        : _backToPreviousInteractiveNode,
                    icon: const Icon(Icons.undo, size: 15),
                    label: const Text('返回上一节点', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: node == null ? null : reshowInteractiveChoices,
                    icon: const Icon(Icons.refresh, size: 15),
                    label: const Text('重新选择', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

                                     
  Future<void> initializeInteractive() => _maybeInitInteractive();

                                          
  Future<void> _setDecodeFormat(String fmt) async {
    if (fmt == _decodeFormat || !_started) return;
    setState(() => _decodeFormat = fmt);
    final playerSettings = _playerSettingsService;
    if (playerSettings != null && playerSettings.preferredDecodeFormat != fmt) {
      playerSettings.setPreferredDecodeFormat(fmt);
    }
    final wasPlaying = player.state.playing;
    final resume = position;
    final url = await _resolveQualityUrl(
      _currentQn,
      audioId: _currentAudioId > 0 ? _currentAudioId : null,
    );
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

                              
     
                                        
                                       
  Future<void> _selectBiliSubtitle(BiliSubtitle? sub) async {
    if (sub == null) {
      setState(() => _activeBiliSubtitle = null);
      player.setSubtitleTrack(SubtitleTrack.no());
      _resetHideTimer();
      return;
    }
    setState(() => _biliSubtitleLoading = true);
    final seq = ++_subtitleSecondSeq;
    String? path;
    if (_subtitleBilingual) {
      path = await _loadBilingualSubtitle(sub, seq);
    } else {
      path = await BilibiliVideoService.fetchSubtitleSrt(sub.url);
    }
    if (!mounted || seq != _subtitleSecondSeq) return;
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

                                            
  Future<String?> _loadBilingualSubtitle(BiliSubtitle sub, int seq) async {
    final primary = await BilibiliVideoService.fetchSubtitleCues(sub.url);
    if (!mounted || seq != _subtitleSecondSeq) return null;
    if (primary == null || primary.isEmpty) {
                                    
      return BilibiliVideoService.fetchSubtitleSrt(sub.url);
    }
    final second = _pickSecondSubtitle(sub);
    String? path;
    if (second != null && second.url != sub.url) {
      final secondCues = await BilibiliVideoService.fetchSubtitleCues(
        second.url,
      );
      if (!mounted || seq != _subtitleSecondSeq) return null;
      if (secondCues != null && secondCues.isNotEmpty) {
        final srt = BilibiliVideoService.buildBilingualSrt(
          primary: primary,
          second: secondCues,
        );
        path = await BilibiliVideoService.writeSrtToTemp(srt);
        if (path != null && mounted) {
          showAppToast(
            context,
            AppLocalizations.of(context).playerSubtitleBilingualOn(
              sub.lanDoc.isEmpty ? sub.lan : sub.lanDoc,
              second.lanDoc.isEmpty ? second.lan : second.lanDoc,
            ),
          );
          return path;
        }
      }
    } else {
                                   
      if (mounted) {
        showAppToast(
          context,
          AppLocalizations.of(context).playerSubtitleBilingualUnavailable,
        );
      }
    }
                        
    return BilibiliVideoService.fetchSubtitleSrt(sub.url);
  }

                                        
                                   
  BiliSubtitle? _pickSecondSubtitle(BiliSubtitle primary) {
    final others = _biliSubtitles
        .where((s) => s.lan != primary.lan && s.url.isNotEmpty)
        .toList();
    if (others.isEmpty) return null;
    final pref = _playerSettingsService?.subtitleTranslateLang ?? 'en-US';
    final prefLower = pref.toLowerCase();
                          
    for (final s in others) {
      if (s.lan.toLowerCase() == prefLower) return s;
    }
                       
    final prefLang = prefLower.split('-').first;
    for (final s in others) {
      if (s.lan.toLowerCase().split('-').first == prefLang) return s;
    }
    return others.first;
  }

                          
  Future<void> _toggleSubtitleBilingual() async {
    setState(() => _subtitleBilingual = !_subtitleBilingual);
    await _playerSettingsService?.setSubtitleBilingual(_subtitleBilingual);
    if (_activeBiliSubtitle != null) {
                           
      _selectBiliSubtitle(_activeBiliSubtitle);
    }
  }

                                           
     
                                                      
                                    
  Future<void> _downloadAllSubtitles() async {
    final l10n = L10n.current;
    final subs = _biliSubtitles;
    if (subs.isEmpty) {
      showAppToast(context, l10n.subtitleDownloadNone);
      return;
    }
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.subtitleDownloadPickDir,
    );
    if (dir == null || dir.isEmpty || !mounted) return;

    setState(() => _biliSubtitleLoading = true);
    final base = widget.bilibiliBvid ?? 'subtitle';
    var ok = 0;
    for (final s in subs) {
      final srt = await BilibiliVideoService.fetchSubtitleSrtText(s.url);
      if (!mounted) return;
      if (srt == null) continue;
      try {
        final name = _safeFileName('${base}_${s.lan}.srt');
        await File(path.join(dir, name)).writeAsString(srt, encoding: utf8);
        ok++;
      } catch (e) {
        debugPrint('[Player] 写字幕文件失败: $e');
      }
    }
    if (!mounted) return;
    setState(() => _biliSubtitleLoading = false);
    showAppToast(
      context,
      ok > 0
          ? l10n.subtitleDownloadDone('$ok', dir)
          : l10n.subtitleDownloadAllFailed,
      error: ok == 0,
    );
  }

                                               
  static String _safeFileName(String name) =>
      name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

                     
  Future<void> _toggleSubtitleDrag() async {
    setState(() {
      _subDragEnabled = !_subDragEnabled;
      if (!_subDragEnabled) _subtitleDragging = false;
    });
                                    
    _bumpUiRevision();
    await _playerSettingsService?.setSubtitleDragEnabled(_subDragEnabled);
    if (!mounted) return;
    if (_subDragEnabled) {
      showAppToast(context, L10n.current.playerSubtitleDragOn);
    } else {
      showAppToast(context, L10n.current.playerSubtitleDragOff);
    }
  }

                 
  Future<void> _resetSubtitlePosition() async {
    setState(() {
      _subPadL = PlayerSettingsService.defaultSubtitlePadL;
      _subPadR = PlayerSettingsService.defaultSubtitlePadR;
      _subPadB = PlayerSettingsService.defaultSubtitlePadB;
    });
    _bumpUiRevision();
    await _playerSettingsService?.setSubtitlePadding(
      left: _subPadL,
      right: _subPadR,
      bottom: _subPadB,
    );
    if (!mounted) return;
    showAppToast(context, L10n.current.playerSubtitlePositionReset);
  }

                                 
  Future<void> _pickSubtitleSecondLang() async {
                             
    final langs = <BiliSubtitle>[
      for (final s in _biliSubtitles)
        if (s.lan.isNotEmpty) s,
    ];
    if (langs.isEmpty) return;
    final current = _playerSettingsService?.subtitleTranslateLang ?? 'en-US';
    final picked = await showDialog<BiliSubtitle>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppLocalizations.of(ctx).playerSubtitleSecondLang),
        children: [
          for (final s in langs)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(s),
              child: Row(
                children: [
                  Icon(
                    s.lan.toLowerCase() == current.toLowerCase()
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(s.lanDoc.isEmpty ? s.lan : s.lanDoc),
                  const SizedBox(width: 8),
                  Text(
                    s.lan,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    await _playerSettingsService?.setSubtitleTranslateLang(picked.lan);
    if (_activeBiliSubtitle != null && _subtitleBilingual) {
      _selectBiliSubtitle(_activeBiliSubtitle);
    }
  }

                           
  void _startSubtitleDrag() {
    setState(() {
      _subtitleDragging = true;
      _subDragStartL = _subPadL;
      _subDragStartR = _subPadR;
      _subDragStartB = _subPadB;
      _subDragOffset = Offset.zero;
    });
  }

                                             
                               
  void _updateSubtitleDrag(Offset delta) {
    if (!_subtitleDragging) return;
    setState(() {
      _subDragOffset += delta;
      _subPadL = (_subDragStartL - _subDragOffset.dx).clamp(0.0, 400.0);
      _subPadR = (_subDragStartR + _subDragOffset.dx).clamp(0.0, 400.0);
      _subPadB = (_subDragStartB - _subDragOffset.dy).clamp(0.0, 320.0);
    });
  }

                   
  Future<void> _endSubtitleDrag() async {
    if (!_subtitleDragging) return;
    setState(() => _subtitleDragging = false);
    await _playerSettingsService?.setSubtitlePadding(
      left: _subPadL,
      right: _subPadR,
      bottom: _subPadB,
    );
    if (mounted) {
      showAppToast(context, L10n.current.playerSubtitlePositionSaved);
    }
    _resetHideTimer();
  }

                                       
  Future<void> _startPlaybackFromCover() async {
    if (_started) return;
    await TaskbarProgress.track<void>(
      _taskbarOpenToken,
      () => _openMedia(
        _initialOpenUrl(),
        headers: widget.httpHeaders,
        subtitleUrl: widget.subtitleUrl,
        subtitleHeaders: widget.httpHeaders,
      ),
    );
    if (!mounted) return;
    setState(() => _started = true);
                                      
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
    _maybeInitInteractive();
    _resetHideTimer();
  }

                                       
                                                  
                                      
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
      case 'mini':
        _enterMiniPlayer();
        break;
      case 'settings':
        setState(() => _showSettingsPanel = true);
        break;
    }
  }

                                        
                                
                                        
  void _enterMiniPlayer() {
    final url = _currentSourceUrl.isNotEmpty
        ? _currentSourceUrl
        : widget.videoUrl;
    if (url.isEmpty) return;

    Rect? origin;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }

    MiniPlayerService.instance.enter(
      MiniPlayerData(
        videoUrl: url,
        title: widget.title ?? '',
        bvid: widget.bilibiliBvid,
        cover: widget.coverUrl,
        ownerName: widget.artist,
        httpHeaders: widget.httpHeaders,
        position: player.state.position,
        duration: player.state.duration,
      ),
      origin: origin,
    );

    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  void _seek(double ratio) {
    final ms = (ratio * duration.inMilliseconds).toInt().clamp(
      0,
      duration.inMilliseconds,
    );
    final target = Duration(milliseconds: ms);
                                        
                                               
                                   
    if (target <= player.state.position) {
      _bufferingSuppressUntil = DateTime.now().add(
        const Duration(milliseconds: 800),
      );
      _setBuffering(false);
    }
    player.seek(target);
  }

                                
                                       
                            
  void _seekToAbsolute(Duration target) {
    if (duration <= Duration.zero) return;
    var ms = target.inMilliseconds.clamp(0, duration.inMilliseconds);
    final real = Duration(milliseconds: ms);
    if (real <= player.state.position) {
      _bufferingSuppressUntil = DateTime.now().add(
        const Duration(milliseconds: 800),
      );
      _setBuffering(false);
    }
    player.seek(real);
    if (_danmakuLoaded) {
      _danmakuController.seekTo(real.inMilliseconds / 1000.0);
    }
    setState(() {
      _setPlaybackPosition(real);
      _resetHideTimer();
    });
  }

                                  
  Future<void> _showSeekTimeDialog() async {
    if (duration <= Duration.zero) return;
    final result = await showSeekTimePickerDialog(
      context,
      duration: duration,
      initial: player.state.position,
    );
    if (result == null || !mounted) return;
    _seekToAbsolute(result);
  }

                         
  void _startHorizontalSeek() {
    if (duration.inMilliseconds <= 0) return;
    setState(() {
      _seekGestureActive = true;
      isDragging = true;
      dragPosition = position;
    });
  }

                                
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
                                               
      _setPlaybackPosition(dragPosition);
    });
    _updateSeekPreview(dragPosition);
  }

                     
  void _endHorizontalSeek() {
    if (!_seekGestureActive) return;
    final ratio = duration.inMilliseconds > 0
        ? (dragPosition.inMilliseconds / duration.inMilliseconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;
    _hideSeekPreview();
    _seek(ratio);
    if (_danmakuLoaded) {
      _danmakuController.seekTo(dragPosition.inMilliseconds / 1000.0);
    }
    setState(() {
      _seekGestureActive = false;
      isDragging = false;
      _setPlaybackPosition(dragPosition);
      _resetHideTimer();
    });
  }

                                     
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

                                    
                                        
  Future<Uint8List?> captureCurrentFrame() async {
    try {
      final playerSettings = context.read<PlayerSettingsService>();
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final boundaryCtx = _repaintKey.currentContext;
      if (boundaryCtx == null) return null;
      final boundary = boundaryCtx.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

                                     
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
              Expanded(child: _buildSubtitleSettingsBody()),
            ],
          ),
        ),
      ),
    );
  }

                         
                                
  Widget _buildSubtitleSettingsBody({bool embedded = false}) {
    return SingleChildScrollView(
      child: SubtitlePanel(
        player: player,
        embedded: embedded,
        fontSize: _subFontSize,
        fontColor: _subColor,
        bgColor: _subBgColor,
        dragEnabled: _subDragEnabled,
        onDragChanged: () => _toggleSubtitleDrag(),
        onResetPosition: () => _resetSubtitlePosition(),
        onFontSizeChanged: (v) => setState(() {
          _subFontSize = v;
          _bumpUiRevision();
        }),
        onFontColorChanged: (c) => setState(() {
          _subColor = c;
          _bumpUiRevision();
        }),
        onBgColorChanged: (c) => setState(() {
          _subBgColor = c;
          _bumpUiRevision();
        }),
      ),
    );
  }

  Widget _buildSettingsPanel(SettingsService settings) {
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
                      activeThumbColor: Colors.blue,
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
                      activeThumbColor: Colors.blue,
                      onChanged: (val) => setState(() => isFlipY = val),
                    ),
                                               
                    SwitchListTile(
                      title: Text(
                        L10n.current.playerOnlyPlayAudio,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        L10n.current.playerOnlyPlayAudioDesc,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      value: onlyPlayAudio,
                      activeThumbColor: Colors.blue,
                      onChanged: (val) => setOnlyPlayAudio(val),
                    ),
                                                    
                                         
                                                 
                                     
                    ListTile(
                      leading: const Icon(
                        Icons.speaker_outlined,
                        color: Colors.white70,
                      ),
                      title: const Text(
                        '音频输出设备',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      subtitle: Text(
                        _playerSettingsService?.audioOutputDevice.isEmpty ??
                                true
                            ? '当前：自动'
                            : '当前：${_playerSettingsService!.audioOutputDevice}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      onTap: _showAudioDeviceMenu,
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.surround_sound_outlined,
                        color: Colors.white70,
                      ),
                      title: const Text(
                        '音量均衡',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      subtitle: Text(
                        PlayerAudioService.label(
                          _playerSettingsService?.audioNormalization ??
                              PlayerAudioService.modeDisable,
                        ),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      onTap: _showAudioNormalizationMenu,
                    ),
                    if (_started)
                      ListTile(
                        leading: Icon(
                          _recording
                              ? Icons.stop_circle
                              : Icons.videocam_outlined,
                          color: _recording ? Colors.redAccent : Colors.white70,
                        ),
                        title: Text(
                          _recording ? '停止录制并保存' : '开始录制',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          _recording
                              ? '已录 ${_format(_recordElapsed)} / '
                                    '最长 ${_playerSettingsService?.recordMaxSeconds ?? 10}s'
                              : '录 $_recordFormatLabel（参数见偏好设置）',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        onTap: _recordProcessing ? null : _toggleRecording,
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

                                    
  void _showDanmakuList() {
    showDanmakuListSheet(
      context,
      _danmakuController,
      onSeek: (seconds) =>
          player.seek(Duration(milliseconds: (seconds * 1000).round())),
      currentPosition: () => player.state.position.inMilliseconds / 1000.0,
    );
  }

                                  
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

                      
  void _writeVideoNote() {
    final bvid = widget.bilibiliBvid;
    if (bvid == null || bvid.isEmpty) return;
    final aid = BvAv.decode(bvid);
    if (aid == null || aid <= 0) return;
    showNoteEditorPage(context, bvid: bvid, aid: aid, videoTitle: widget.title);
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
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.6),
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

                                   
                  
  Widget _buildListenOnlyHint() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.headphones_rounded, size: 40, color: Colors.white70),
          const SizedBox(height: 10),
          Text(
            L10n.current.playerOnlyPlayAudio,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBufferingIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
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
                color: Colors.white.withValues(alpha: 0.7),
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
            color: Colors.black.withValues(alpha: 0.72),
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

                                
  Widget _buildVideoLayer() {
    Widget videoLayer = RepaintBoundary(
      key: _repaintKey,
      child: Video(
        controller: controller,
                                                 
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
                                                  
                                                      
          padding: EdgeInsets.fromLTRB(_subPadL, 0, _subPadR, _subPadB),
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

                                                       
                                            
  String get _currentQualityLabel {
    final info = widget.playUrlInfo;
    if (info == null || info.qualities.isEmpty) return '';
    for (final q in info.qualities) {
      if (q.qn == _currentQn) return q.label;
    }
    return info.qualities.first.label;
  }

                                            
                                       
  String get _currentQualityShortLabel {
    final full = _currentQualityLabel.trim();
    if (full.isEmpty) return full;
    final head = full.split(RegExp(r'\s+')).first.trim();
    return head.isEmpty ? full : head;
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 6),
      tooltip: L10n.current.playerQuality,
      menuWidth: 220,
      customChild: Text(
        _currentQualityShortLabel,
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: _qualityMenuActions(),
    );
  }

                                   
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
              ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
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

                                       
  String get _currentSourceLabel {
    for (final e in _sourceEntries()) {
      if (e.index == _sourceIndex && e.host == _sourceHost) return e.label;
    }
    return '';
  }

             
                                                
                                                         
                           
                                                   
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

                                          
                                             
                                               
  void _showSourceSubMenu([Offset? anchor]) {
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    final entries = _sourceEntries();
    if (entries.isEmpty) return;
    _showPlatformMenu(
      scrollable: true,
      position: anchor ?? Offset(size.width - 16, 60),
      menuWidth: 240,
      items: [
        for (final e in entries)
          NativeMenuItem(
            text: e.label,
            icon: Icons.dns_outlined,
            checked: e.index == _sourceIndex && e.host == _sourceHost,
            onTap: () => _switchSource(e),
          ),
      ],
      actions: [
        for (final e in entries)
          GlassMenuAction(
            icon: Icons.dns_outlined,
            text: e.label,
            trailing: e.index == _sourceIndex && e.host == _sourceHost
                ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
                : null,
            onTap: () => _switchSource(e),
          ),
      ],
    );
  }

                                         
  Future<void> _switchSource(_SourceEntry entry) async {
    if (!_started) return;
    if (entry.index == _sourceIndex && entry.host == _sourceHost) return;
    setState(() {
      _sourceIndex = entry.index;
      _sourceHost = entry.host;
    });
    final wasPlaying = player.state.playing;
    final resume = position;
    final url = await _resolveQualityUrl(
      _currentQn,
      audioId: _currentAudioId > 0 ? _currentAudioId : null,
    );
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

                                       
                           
     
                                                  
                                                        
  void _showRateSubMenu() {
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    const rates = [0.5, 1.0, 1.25, 1.5, 2.0];
    void pick(double rate) {
      _changeRate(rate);
      context.read<SettingsService>().setPlayerDefaultRate(rate);
    }

    _showPlatformMenu(
      position: Offset(size.width - 16, 60),
      menuWidth: 200,
      items: [
        for (final rate in rates)
          NativeMenuItem(
            text: '${rate}x',
            icon: Icons.speed,
            checked: currentRate == rate,
            onTap: () => pick(rate),
          ),
      ],
      actions: [
        for (final rate in rates)
          GlassMenuAction(
            icon: Icons.speed,
            text: '${rate}x',
            trailing: currentRate == rate
                ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
                : null,
            onTap: () => pick(rate),
          ),
      ],
    );
  }

                                    
                                      
  String _sleepTimerMenuLabel() {
    final st = SleepTimerService.instance;
    final l10n = L10n.current;
    if (st.stopAfterCurrentArmed) {
      return '$l10n.sleepTimer · $l10n.sleepTimerStopAfterCurrentShort';
    }
    if (st.isCountdownActive) {
      return '$l10n.sleepTimer · ${SleepTimerService.formatRemaining(st.remaining)}';
    }
    return l10n.sleepTimer;
  }

                                            
                                               
  void _showSleepTimerMenu() {
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    final st = SleepTimerService.instance;
    final l10n = L10n.current;

    void toast(String msg) {
      if (mounted) showAppToast(context, msg);
    }

    void startCountdown(int minutes) {
      st.startCountdown(Duration(minutes: minutes));
      toast(
        '$l10n.sleepTimerArmedToast · '
        '${SleepTimerService.formatRemaining(st.remaining)}',
      );
    }

    Future<void> pickCustomMinutes() async {
      final controller = TextEditingController();
      final value = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.sleepTimerCustomDialogTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.sleepTimerCustomHint,
              suffixText: l10n.sleepTimerCustomUnit,
            ),
            onSubmitted: (v) => Navigator.of(dialogContext).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(L10n.current.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(L10n.current.confirm),
            ),
          ],
        ),
      );
      if (value == null || !mounted) return;
      final minutes = int.tryParse(value.trim());
      if (minutes == null || minutes <= 0) {
        toast(l10n.sleepTimerInvalidNumber);
        return;
      }
      startCountdown(minutes);
    }

    void armStopAfterCurrent() {
      st.armStopAfterCurrent();
      toast(l10n.sleepTimerStopAfterCurrentArmedToast);
    }

    void cancelTimer() {
      st.cancel();
      toast(l10n.sleepTimerCancelledToast);
    }

    final countdownMinutes = const [15, 30, 60, 90];
    final items = <NativeMenuItem>[
      for (final m in countdownMinutes)
        NativeMenuItem(
          text: l10n.sleepTimerMinutes(m),
          icon: Icons.timer_outlined,
          onTap: () => startCountdown(m),
        ),
      NativeMenuItem(
        text: l10n.sleepTimerCustom,
        icon: Icons.edit_outlined,
        onTap: pickCustomMinutes,
      ),
      NativeMenuItem(
        text: l10n.sleepTimerStopAfterCurrent,
        icon: Icons.skip_next_outlined,
        checked: st.stopAfterCurrentArmed,
        onTap: armStopAfterCurrent,
      ),
      if (st.isActive)
        NativeMenuItem(
          text: l10n.sleepTimerCancel,
          icon: Icons.timer_off_outlined,
          onTap: cancelTimer,
        ),
    ];
    final actions = <GlassMenuAction>[
      for (final m in countdownMinutes)
        GlassMenuAction(
          icon: Icons.timer_outlined,
          text: l10n.sleepTimerMinutes(m),
          onTap: () => startCountdown(m),
        ),
      GlassMenuAction(
        icon: Icons.edit_outlined,
        text: l10n.sleepTimerCustom,
        onTap: pickCustomMinutes,
      ),
      GlassMenuAction(
        icon: Icons.skip_next_outlined,
        text: l10n.sleepTimerStopAfterCurrent,
        trailing: st.stopAfterCurrentArmed
            ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
            : null,
        onTap: armStopAfterCurrent,
      ),
      if (st.isActive)
        GlassMenuAction(
          icon: Icons.timer_off_outlined,
          text: l10n.sleepTimerCancel,
          onTap: cancelTimer,
        ),
    ];
    _showPlatformMenu(
      position: Offset(size.width - 16, 60),
      menuWidth: 220,
      items: items,
      actions: actions,
    );
  }

                                                 
                                                    
  Future<void> _showPlatformMenu({
    required Offset position,
    required double menuWidth,
    required List<NativeMenuItem> items,
    required List<GlassMenuAction> actions,
    bool scrollable = false,
  }) async {
    final ok = await NativeMenuService.showMenu(
      context,
      items: items,
      position: position,
      width: menuWidth,
    );
    if (ok || !mounted) return;
    showGlassDropdownMenu(
      context,
                                  
      preferNative: false,
      scrollable: scrollable,
      actions: actions,
      globalPosition: position,
      menuWidth: menuWidth,
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
                ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
                : null,
            onTap: () => _setDecodeFormat(fmt),
          ),
      ],
    );
  }

                                         
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
              ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
              : null,
          onTap: () => _selectBiliSubtitle(null),
        ),
        for (final s in _biliSubtitles)
          GlassMenuAction(
            icon: Icons.subtitles_outlined,
            text: s.lanDoc.isEmpty ? s.lan : s.lanDoc,
            trailing: _activeBiliSubtitle?.lan == s.lan
                ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
                : null,
            onTap: () => _selectBiliSubtitle(s),
          ),
        GlassMenuAction(
          icon: _subtitleBilingual ? Icons.translate : Icons.translate_outlined,
          text: L10n.current.playerSubtitleBilingual,
          isEnabled: _biliSubtitles.length > 1,
          trailing: _subtitleBilingual
              ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
              : null,
          onTap: _biliSubtitles.length > 1
              ? () => _toggleSubtitleBilingual()
              : () {},
        ),
        GlassMenuAction(
          icon: Icons.language,
          text:
              '${L10n.current.playerSubtitleSecondLang}: ${_playerSettingsService?.subtitleTranslateLang ?? 'en-US'}',
          onTap: () => _pickSubtitleSecondLang(),
        ),
                               
        GlassMenuAction(
          icon: Icons.download_outlined,
          text: L10n.current.subtitleDownloadAll,
          onTap: () => unawaited(_downloadAllSubtitles()),
        ),
        GlassMenuAction(
          icon: _subDragEnabled
              ? Icons.drag_indicator
              : Icons.drag_indicator_outlined,
          text: L10n.current.playerSubtitleDrag,
          trailing: _subDragEnabled
              ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
              : null,
          onTap: () => _toggleSubtitleDrag(),
        ),
        GlassMenuAction(
          icon: Icons.restart_alt,
          text: L10n.current.playerSubtitlePositionReset,
          onTap: () => _resetSubtitlePosition(),
        ),
      ],
    );
  }

                                          

                                                
                                                    
                                                    
                                                         
                                               
                                     
  Widget _liveProgress(
    Widget Function(double progress, double bufferProgress) builder,
  ) {
    return ListenableBuilder(
      listenable: Listenable.merge([_positionNotifier, _bufferNotifier]),
      builder: (context, _) {
        final totalMs = duration.inMilliseconds;
        final progress = totalMs > 0
            ? (_positionNotifier.value.inMilliseconds / totalMs).clamp(0.0, 1.0)
            : 0.0;
        final bufferProgress = totalMs > 0
            ? (_bufferNotifier.value.inMilliseconds / totalMs).clamp(0.0, 1.0)
            : 0.0;
        return builder(progress, bufferProgress);
      },
    );
  }

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
                                                
          cacheWidth: 1440,
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
                                                 
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleTap,
                                              
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
                                                
                  onVerticalDragStart: _subDragEnabled
                      ? (_) {
                          if (isLongPressing ||
                              _showSettingsPanel ||
                              _showSubtitlePanel ||
                              _showDanmakuPanel ||
                              _showEpisodePanel) {
                            return;
                          }
                          _startSubtitleDrag();
                        }
                      : null,
                  onVerticalDragUpdate: _subDragEnabled
                      ? (d) {
                          if (_subtitleDragging) _updateSubtitleDrag(d.delta);
                        }
                      : null,
                  onVerticalDragEnd: _subDragEnabled
                      ? (_) => _endSubtitleDrag()
                      : null,
                ),
              ),
                                            
                               
              if (_subDragEnabled)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _subtitleDragging
                        ? Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.only(top: topInset + 6),
                              child: _SubtitleDragHint(
                                text: L10n.current.playerSubtitleDragging,
                              ),
                            ),
                          )
                        : (showControls
                              ? Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: topInset + 6),
                                    child: _SubtitleDragHint(
                                      subtle: true,
                                      text: L10n.current.playerSubtitleDragHint,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink()),
                  ),
                ),
                    
              if (_danmakuLoaded && _started)
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      key: _danmakuRepaintKey,
                      child: DanmakuView(controller: _danmakuController),
                    ),
                  ),
                ),
                    
              if (coverLayer != null) coverLayer,
                      
              if (_isBuffering && !isFinished && _started)
                Positioned.fill(
                  child: IgnorePointer(child: _buildBufferingIndicator()),
                ),
                                           
              if (onlyPlayAudio && _started && !_isBuffering)
                Positioned.fill(
                  child: IgnorePointer(child: _buildListenOnlyHint()),
                ),
                     
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
                    
              AnimatedOpacity(
                opacity: showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !showControls,
                  child: Stack(
                    children: [
                             
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
                                                       
                                                    
                                                       
                                                  
                                                 
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: Row(
                          children: [
                                                     
                                                 
                            MorphIconButton(
                              icon: Icons.arrow_back,
                              tooltip: L10n.current.playerBackTooltip,
                              iconColor: Colors.white,
                              transparent: true,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 6),
                                                            
                            MorphIconButton(
                              icon: Icons.home_outlined,
                              tooltip: l10n.bottomNavItemHome,
                              iconColor: Colors.white,
                              transparent: true,
                              onTap: _goHome,
                            ),
                            const Expanded(child: SizedBox.shrink()),
                                                      
                                                       
                                                
                            MorphIconButton(
                              icon: Icons.headphones_outlined,
                              iconColor: Colors.white,
                              tooltip: L10n.current.playerListenPage,
                              transparent: true,
                              onTap:
                                  widget.onListenPageRequested ??
                                  () => unawaited(setOnlyPlayAudio(true)),
                            ),
                            const SizedBox(width: 6),
                                                     
                            MorphIconButton(
                              icon: Icons.tv_outlined,
                              tooltip: L10n.current.playerCast,
                              iconColor: Colors.white,
                              transparent: true,
                              onTap: () => _openDlnaCast(),
                            ),
                            const SizedBox(width: 6),
                                                        
                                                         
                                                   
                            LiquidGlassMenuButton(
                              icon: Icons.more_vert,
                              useMorphStyle: true,
                              transparent: true,
                              iconColor: Colors.white,
                              menuWidth: 220,
                              overrideOnTap: widget.onMoreMenuRequested,
                              actions: [
                                                          
                                                           
                                if (widget.playUrlInfo != null &&
                                    widget.playUrlInfo!.qualities.isNotEmpty)
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
                                                    
                                if (widget.playUrlInfo != null &&
                                    widget.playUrlInfo!.qualities.isNotEmpty)
                                  GlassMenuAction(
                                    icon: Icons.speed,
                                    text: 'CDN 测速',
                                    onTap: _runCdnSpeedTest,
                                  ),
                                               
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
                                                      
                                                      
                                                    
                                GlassMenuAction(
                                  icon: Icons.timer_outlined,
                                  text: _sleepTimerMenuLabel(),
                                  onTap: _showSleepTimerMenu,
                                ),
                                if (_danmakuLoaded)
                                  GlassMenuAction(
                                    icon: Icons.format_list_bulleted_outlined,
                                    text: L10n.current.playerDanmakuList,
                                    onTap: _showDanmakuList,
                                  ),
                                                       
                                                        
                                if (_danmakuLoaded)
                                  GlassMenuAction(
                                    icon: Icons.tune,
                                    text: L10n.current.playerDanmakuSettings,
                                    onTap: _toggleDanmakuSettings,
                                  ),
                                if (_isBiliSource &&
                                    (widget.bilibiliBvid?.isNotEmpty ?? false))
                                  GlassMenuAction(
                                    icon: Icons.article_outlined,
                                    text: L10n.current.playerViewNotes,
                                    onTap: _showVideoNotes,
                                  ),
                                                          
                                if (_isBiliSource &&
                                    (widget.bilibiliBvid?.isNotEmpty ?? false))
                                  GlassMenuAction(
                                    icon: Icons.edit_note,
                                    text: L10n.current.playerWriteNote,
                                    onTap: _writeVideoNote,
                                  ),
                                                                 
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
                                     
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 4,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_showSeekPreviewOverlay)
                              _buildSeekPreviewOverlay(),
                                                                 
                            _liveProgress(
                              (progress, bufferProgress) => SizedBox(
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
                                        onChangeStart: (val) {
                                          setState(() {
                                            isDragging = true;
                                            dragPosition = Duration(
                                              milliseconds:
                                                  (val *
                                                          duration
                                                              .inMilliseconds)
                                                      .toInt(),
                                            );
                                            _setPlaybackPosition(dragPosition);
                                          });
                                          _updateSeekPreview(dragPosition);
                                        },
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
                                            _setPlaybackPosition(dragPosition);
                                          });
                                          _updateSeekPreview(dragPosition);
                                        },
                                        onChangeEnd: (val) {
                                          _hideSeekPreview();
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
                                        trackHeight: 3,
                                        thumbRadius: 5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                                                                  
                                                            
                                                                          
                                                                   
                                                      
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                                  
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _AnimatedPlayPauseButton(
                                      player: player,
                                      iconSize: 26,
                                      color: Colors.white,
                                      onTap: _togglePlayPause,
                                    ),
                                                              
                                                                     
                                                          
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: _showSeekTimeDialog,
                                                                     
                                                        
                                      child: ValueListenableBuilder<Duration>(
                                        valueListenable: _positionNotifier,
                                        builder: (_, livePos, __) => Text(
                                          _format(livePos),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
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
                                  ],
                                ),
                                                          
                                                                
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (widget.playUrlInfo != null)
                                          _buildQualityMenu(),
                                                            
                                        if (widget.playUrlInfo != null &&
                                            widget
                                                .playUrlInfo!
                                                .allAudioStreams
                                                .isNotEmpty &&
                                            widget
                                                    .playUrlInfo!
                                                    .allAudioStreams
                                                    .length >
                                                1)
                                          _buildAudioMenu(),
                                        if (_biliSubtitles.isNotEmpty &&
                                            _started)
                                          _buildBiliSubtitleMenu(),
                                        if (_availableDecodeFormats()
                                                .isNotEmpty &&
                                            _started)
                                          _buildDecodeFormatMenu(),
                                        if (_danmakuLoaded)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.subtitles_outlined,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            tooltip: L10n
                                                .current
                                                .playerDanmakuSettings,
                                                                     
                                                                   
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: _toggleDanmakuSettings,
                                          ),
                                                       
                                        IconButton(
                                          icon: const Icon(
                                            Icons.fullscreen,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                          tooltip:
                                              L10n.current.playerFullscreen,
                                          visualDensity: VisualDensity.compact,
                                          onPressed: _requestFullscreen,
                                        ),
                                      ],
                                    ),
                                  ),
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
                                            
              if (_interactiveChoicesVisible) _buildInteractiveChoiceCard(),
                     
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
                            
              if (_showSubtitlePanel) _buildSubtitlePanel(),
                       
              if (_showSettingsPanel) _buildSettingsPanel(settings),
                     
              if (_showDanmakuPanel) _buildDanmakuPanel(),
                                                   
              if (settings.showPlayerStats && !Platform.isWindows)
                _buildStatsOverlay(),
                              
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
                                        
              Positioned(
                left: 0,
                top: 0,
                child: PlayerKeyboardShortcuts(
                  focusScopeNode: _focusNode,
                  actions: _buildShortcutActions(),
                  longPressActions: _buildShortcutLongPress(),
                  isBlocked: _shortcutsBlocked,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

                                             
                             
  void _onPlayerKeyEvent(KeyEvent event, PlayerSettingsService playerSettings) {
    if (isDragging) return;
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (!playerSettings.enableLongPressSpeed) return;
        final allowInImmersive =
            playerSettings.longPressInImmersive || showControls;
        if (!allowInImmersive) return;
        _keyHoldTimer ??= Timer(const Duration(milliseconds: 500), () {
          if (mounted && !isLongPressing) {
            setState(() {
              isLongPressing = true;
              previousRate = currentRate;
              player.setRate(2.0);
            });
          }
        });
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

                                                        
    
                                                        
                                              
                                             
                                  
                                           

                             
  double _volumeBeforeMute = 100.0;

                       
  bool _shortcutsBlocked() {
    if (isDragging || _seekGestureActive || isLongPressing) return true;
    if (_showSettingsPanel ||
        _showSubtitlePanel ||
        _showDanmakuPanel ||
        _showEpisodePanel) {
      return true;
    }
    if (_showScreenshotPreview) return true;
    return false;
  }

  Map<String, PlayerShortcutAction> _buildShortcutActions() =>
      <String, PlayerShortcutAction>{
        'playorpause': _togglePlayPause,
        'forward': _shortcutForwardDown,
        'rewind': _shortcutRewind,
        'next': _playNextEpisode,
        'prev': _playPrevEpisode,
        'volumeup': () => _shortcutVolume(5),
        'volumedown': () => _shortcutVolume(-5),
        'togglemute': _shortcutToggleMute,
        'fullscreen': _shortcutToggleFullscreen,
        'exitfullscreen': _shortcutExitFullscreen,
        'toggledanmaku': _shortcutToggleDanmaku,
        'screenshot': _takeScreenshot,
        'skip': _skipActiveSegment,
        'speed1': () => _shortcutSetRate(1.0),
        'speed2': () => _shortcutSetRate(2.0),
        'speed3': () => _shortcutSetRate(3.0),
        'speedup': () => _shortcutSetRate(currentRate + 0.25),
        'speeddown': () => _shortcutSetRate(currentRate - 0.25),
      };

  Map<String, PlayerLongPressShortcutActions> _buildShortcutLongPress() =>
      <String, PlayerLongPressShortcutActions>{
                                               
                                       
        'forward': PlayerLongPressShortcutActions(
          onRepeat: () {},
          onRelease: _shortcutForwardUp,
        ),
      };

                                 
  void _shortcutForwardDown() {
    final ps = _playerSettingsService;
    if (ps != null && !ps.enableLongPressSpeed) return;
    if (isDragging || _seekGestureActive) return;
    final allowInImmersive = (ps?.longPressInImmersive ?? true) || showControls;
    if (!allowInImmersive) return;
    if (_keyHoldTimer != null) return;
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

                                            
  void _shortcutForwardUp() {
    _keyHoldTimer?.cancel();
    _keyHoldTimer = null;
    if (!mounted) return;
    if (isLongPressing) {
      setState(() {
        isLongPressing = false;
        player.setRate(previousRate);
      });
    } else {
      _shortcutSeekBy(const Duration(seconds: 10));
    }
  }

  void _shortcutRewind() => _shortcutSeekBy(const Duration(seconds: -10));

  void _shortcutSeekBy(Duration offset) {
    var target = position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (target > duration) target = duration;
    player.seek(target);
    _resetHideTimer();
  }

  void _shortcutSetRate(double rate) {
    _changeRate(rate.clamp(0.25, 4.0));
    _toastPlayer('${currentRate.toStringAsFixed(2)}x');
  }

                                       
  @override
  bool get isPlaying => player.state.playing;

  @override
  Future<void> pause() => player.pause();

  void _shortcutVolume(double delta) {
    final current = player.state.volume > 0
        ? player.state.volume
        : _currentVolume;
    _shortcutApplyVolume(current + delta);
  }

  void _shortcutApplyVolume(double value) {
    final v = value.clamp(0.0, 100.0);
    player.setVolume(v);
    if (mounted) {
      setState(() => _currentVolume = v);
    } else {
      _currentVolume = v;
    }
    _toastPlayer(v <= 0 ? '已静音' : '音量 ${v.round()}%');
  }

  void _shortcutToggleMute() {
    final current = player.state.volume > 0
        ? player.state.volume
        : _currentVolume;
    if (current > 0) {
      _volumeBeforeMute = current;
      _shortcutApplyVolume(0);
    } else {
      _shortcutApplyVolume(_volumeBeforeMute <= 0 ? 100 : _volumeBeforeMute);
    }
  }

                                             
                                     
                  
  void _wheelAdjustVolume(double scrollDy) {
    if (_disposed) return;
                                       
    if (_showSettingsPanel ||
        _showSubtitlePanel ||
        _showDanmakuPanel ||
        _showEpisodePanel) {
      return;
    }
    final step = (-scrollDy * 0.05).clamp(-10.0, 10.0);
    final current = player.state.volume > 0
        ? player.state.volume
        : _currentVolume;
    final v = (current + step).clamp(0.0, 100.0);
    if (v == current) return;
    player.setVolume(v);
    _currentVolume = v;
    setState(() {
      _isAdjustingVolume = true;
      _adjustmentProgress = v;
    });
    _wheelVolumeTimer?.cancel();
    _wheelVolumeTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _isAdjustingVolume = false);
    });
    _resetHideTimer();
  }

  void _shortcutToggleFullscreen() {
    if (_isFullscreen) {
      _shortcutExitFullscreen();
    } else {
      _requestFullscreen();
    }
  }

                                        
  void _shortcutExitFullscreen() {
    if (!_isFullscreen) return;
    _handleBack();
  }

  void _shortcutToggleDanmaku() {
    final c = _danmakuController;
    c.enabled = !c.enabled;
    c.persistSettings();
    if (mounted) setState(() {});
    _toastPlayer(c.enabled ? '弹幕已开启' : '弹幕已关闭');
  }

                                       
                  
  void _handleBack() {
                      
    if (_recording) {
      _cancelRecording();
      showAppToast(context, '录制已取消');
    }
                       
    if (_isDesktopPip) {
      unawaited(_exitDesktopPip());
      return;
    }
    final exitFullscreen = widget.onExitFullscreenRequested;
    if (exitFullscreen != null) {
      exitFullscreen();
      return;
    }
    Navigator.of(context).pop();
  }

                    

                            
  bool get _isBiliVideo =>
      _isBiliSource ||
      (widget.bilibiliBvid != null && widget.bilibiliBvid!.isNotEmpty);

                                    
                                           
  void _showPlayerContextMenu(Offset globalPosition) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    const menuWidth = 220.0;
                                                         
                   
    final items = _playerMenuItems(closeMenu: () {});
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
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                                                         
                                                    
          _openStatsDialog();
        },
      ),
                                                      
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

                                 
  void _togglePlayerStats() {
    final settings = context.read<SettingsService>();
    settings.setShowPlayerStats(!settings.showPlayerStats);
  }

                                       
                                        
  Future<void> _showStatsNativeDialog() async {
    final l10n = L10n.current;
    final entries = _statsEntries();
    try {
      await _statsChannel.invokeMethod<void>('showStats', {
        'title': l10n.playerStats,
        'entries': entries.map((e) => [e.$1, e.$2]).toList(),
                                         
                                              
        'copyLabel': l10n.commonCopy,
        'closeLabel': l10n.commonClose,
      });
    } catch (e) {
                                             
                                                   
      if (mounted && !Platform.isWindows) {
        context.read<SettingsService>().setShowPlayerStats(true);
      }
    }
  }

                                           
     
                                                       
                                      
                                                    
                                                        
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
                                 
                                       
      for (var i = 0; i < 3; i++) {
        await WidgetsBinding.instance.endOfFrame;
      }
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isEmpty) return;
      final view = views.first;
      final client = viewClientSize(view);
      if (client.width < 1 || client.height < 1) return;
      final outer = await windowManager.getSize();
      if (outer.width < 1 || outer.height < 1) return;
      final chrome = windowChrome(outer, client);
                                   
      final screen = displayLogicalSize(view.display);

      final target = alignWindowOuterSize(
        client: client,
        ratio: ratio,
        screen: screen,
        chrome: chrome,
      );
      final targetClient = Size(
        target.width - chrome.width,
        target.height - chrome.height,
      );
      if ((targetClient.width - client.width).abs() < 1 &&
          (targetClient.height - client.height).abs() < 1) {
        _windowAspectRatio = ratio;
        _lastAcceptedWindowSize = client;
        if (mounted) _toastPlayer(L10n.current.playerAlignAspectRatioDone);
        return;
      }

      _isCorrectingWindowSize = true;
      await windowManager.setSize(target);
      _isCorrectingWindowSize = false;
                                  
                                                   
      _windowAspectRatio = ratio;
      _lastAcceptedWindowSize = targetClient;
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

    await showAppBottomSheet<void>(
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

                                   
                                  
  List<(String, String)> _statsEntries() {
    final l10n = L10n.current;
    final w = player.state.width ?? 0;
    final h = player.state.height ?? 0;
    final resolution = (w > 0 && h > 0) ? '$w×$h' : '—';
    final fpsText = _containerFps > 0
        ? '${_containerFps.toStringAsFixed(2)} fps'
        : '—';
    final bitrateText = _formatBitrate(_videoBitrate);
    final hwdecText = (_hwdecCurrent.isEmpty || _hwdecCurrent == 'no')
        ? l10n.playerHwdecSoftware
        : l10n.playerHwdecHardware(_hwdecCurrent);
    final st = player.state.track.subtitle;
    final subOn = st.id != SubtitleTrack.no().id;

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
      (l10n.playerStatSubtitle, subOn ? l10n.playerOn : l10n.playerOff),
      (l10n.playerStatDanmaku, _danmakuLoaded ? l10n.playerOn : l10n.playerOff),
      (l10n.playerStatDownload, _formatSpeed(_networkSpeedBps)),
      (l10n.playerStatSource, sourceText),
      (l10n.playerStatPosition, _fmtSec(position.inMilliseconds ~/ 1000)),
      (l10n.playerStatDuration, _fmtSec(duration.inMilliseconds ~/ 1000)),
    ];
  }

                                          
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
              bilibiliBvid: widget.bilibiliBvid,
              historyId: widget.historyId,
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
      videoLayer = Hero(
        transitionOnUserGestures: true,
        tag: widget.heroTag!,
        child: videoLayer,
      );
    }

                                
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
              } else if (event.scrollDelta.dy != 0) {
                                        
                _wheelAdjustVolume(event.scrollDelta.dy);
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
                                             
                                     
                    if (_subDragEnabled && details.pointerCount == 1) {
                      _startSubtitleDrag();
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
                    if (_subtitleDragging) {
                      _updateSubtitleDrag(details.focalPointDelta);
                      return;
                    }
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
                                                      
                    final cumDx = details.localFocalPoint.dx - _gestureStartX;
                    final cumDy = details.localFocalPoint.dy - _gestureStartY;
                    if (cumDx.abs() < 8 && cumDy.abs() < 8) return;
                    if (cumDx.abs() > 3 * cumDy.abs()) {
                      _startHorizontalSeek();
                      _updateHorizontalSeek(cumDx);
                      return;
                    }
                    if (cumDy.abs() > 3 * cumDx.abs()) {
                                                  
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
                    if (_subtitleDragging) {
                      _endSubtitleDrag();
                      return;
                    }
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

                                           
                                                   
                if (_subDragEnabled)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _subtitleDragging
                          ? Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: EdgeInsets.only(top: topInset + 12),
                                child: _SubtitleDragHint(
                                  text: L10n.current.playerSubtitleDragging,
                                ),
                              ),
                            )
                          : (showControls
                                ? Align(
                                    alignment: Alignment.topCenter,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: topInset + 12,
                                      ),
                                      child: _SubtitleDragHint(
                                        subtle: true,
                                        text:
                                            L10n.current.playerSubtitleDragHint,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink()),
                    ),
                  ),

                              
                if (_danmakuLoaded)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        key: _danmakuRepaintKey,
                        child: DanmakuView(controller: _danmakuController),
                      ),
                    ),
                  ),

                        
                if (_isBuffering && !isFinished)
                  Positioned.fill(
                    child: IgnorePointer(child: _buildBufferingIndicator()),
                  ),

                                   
                if (onlyPlayAudio && _started && !_isBuffering)
                  Positioned.fill(
                    child: IgnorePointer(child: _buildListenOnlyHint()),
                  ),

                       
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
                                  : (_adjustmentProgress <= 0
                                        ? Icons.volume_off
                                        : Icons.volume_up),
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

                           
                if (settings.showPlayerStats && !Platform.isWindows)
                  _buildStatsOverlay(),

                                         
                if (_showSkipPrompt)
                  Positioned(left: 16, bottom: 108, child: _buildSkipPrompt()),

                         
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
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.orangeAccent.withValues(alpha: 0.6),
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

                                              
                if (_interactiveChoicesVisible) _buildInteractiveChoiceCard(),

                       
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

                                     
                if (_recording)
                  Positioned(
                    top: topInset + 16,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.62),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'REC ${_format(_recordElapsed)} / '
                                '${_playerSettingsService?.recordMaxSeconds ?? 10}s'
                                ' · 点击停止按钮保存',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                      
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

                                                       
                                                       
                        Positioned(
                                                        
                                                       
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

                                  
                        Positioned(
                          top: topInset + 10,
                          right: 16,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                                        
                                                           
                              if (_started && _recordProcessing)
                                const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else if (_started)
                                IconButton(
                                  icon: Icon(
                                    _recording
                                        ? Icons.stop_circle
                                        : Icons.videocam_outlined,
                                    color: _recording
                                        ? Colors.redAccent
                                        : Colors.white,
                                    size: 26,
                                  ),
                                  tooltip: _recording ? '停止并保存' : '开始录制',
                                  onPressed: _toggleRecording,
                                ),
                              if (playerSettings.enableScreenshot)
                                IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  tooltip: '截图',
                                  onPressed: _takeScreenshot,
                                ),
                                                 
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
                                                                     
                              LiquidGlassMenuButton(
                                icon: Icons.more_vert,
                                iconColor: Colors.white,
                                useMorphStyle: false,
                                iconSize: 26,
                                tooltip: '更多',
                                menuWidth: 220,
                                overrideOnTap: widget.onMoreMenuRequested,
                                actions: [
                                                              
                                  if (widget.playUrlInfo != null &&
                                      widget.playUrlInfo!.qualities.isNotEmpty)
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
                                  if (widget.playUrlInfo != null &&
                                      widget.playUrlInfo!.qualities.isNotEmpty)
                                    GlassMenuAction(
                                      icon: Icons.speed,
                                      text: 'CDN 测速',
                                      onTap: _runCdnSpeedTest,
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
                                                                
                                  if (!kIsWeb &&
                                      (Platform.isAndroid || _isDesktop))
                                    GlassMenuAction(
                                      icon: Icons.picture_in_picture_alt,
                                      text: '画中画',
                                      onTap: () => _handleMoreMenu('pip'),
                                    ),
                                                           
                                  GlassMenuAction(
                                    icon: Icons.picture_in_picture,
                                    text: '迷你浮窗',
                                    onTap: () => _handleMoreMenu('mini'),
                                  ),
                                                           
                                  GlassMenuAction(
                                    icon: Icons.speaker_outlined,
                                    text: '音频输出设备',
                                    onTap: _showAudioDeviceMenu,
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

                                
                        Positioned(
                          bottom: 24,
                          left: 16,
                          right: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_showSeekPreviewOverlay)
                                _buildSeekPreviewOverlay(),
                                                                   
                              _liveProgress(
                                (progress, bufferProgress) => SizedBox(
                                  height: 20,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
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
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                enabledThumbRadius: 6,
                                              ),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                                overlayRadius: 14,
                                              ),
                                          activeTrackColor: Colors.blueAccent,
                                          inactiveTrackColor:
                                              Colors.transparent,
                                        ),
                                        child: Slider(
                                          value: progress.clamp(0.0, 1.0),
                                          onChangeStart: (val) {
                                            setState(() {
                                              isDragging = true;
                                              dragPosition = Duration(
                                                milliseconds:
                                                    (val *
                                                            duration
                                                                .inMilliseconds)
                                                        .toInt(),
                                              );
                                              _setPlaybackPosition(
                                                dragPosition,
                                              );
                                            });
                                            _updateSeekPreview(dragPosition);
                                          },
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
                                              _setPlaybackPosition(
                                                dragPosition,
                                              );
                                            });
                                            _updateSeekPreview(dragPosition);
                                          },
                                          onChangeEnd: (val) {
                                            _hideSeekPreview();
                                            _seek(val);
                                            if (_danmakuLoaded) {
                                              final targetSec =
                                                  (val *
                                                          duration
                                                              .inMilliseconds)
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
                                        ),          
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
                                                              
                                        GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: _showSeekTimeDialog,
                                                                      
                                                              
                                          child:
                                              ValueListenableBuilder<Duration>(
                                                valueListenable:
                                                    _positionNotifier,
                                                builder: (_, livePos, __) =>
                                                    Text(
                                                      _format(livePos),
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                    ),
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
                                                
                                        if (_isPlaylistMode) ...[
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent
                                                  .withValues(alpha: 0.3),
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
                                                                   
                                                               
                                        if (widget.playUrlInfo != null &&
                                            widget
                                                .playUrlInfo!
                                                .qualities
                                                .isNotEmpty)
                                          _buildQualityMenu(),
                                                             
                                        if (widget.playUrlInfo != null &&
                                            widget
                                                    .playUrlInfo!
                                                    .allAudioStreams
                                                    .length >
                                                1)
                                          _buildAudioMenu(),
                                        if (_biliSubtitles.isNotEmpty)
                                          _buildBiliSubtitleMenu(),
                                                  
                                        if (_availableDecodeFormats()
                                            .isNotEmpty)
                                          _buildDecodeFormatMenu(),
                                                                 
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
                                                  settings.setPlayerDefaultRate(
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
                                          tooltip: _endBehaviorLabel(
                                            endBehavior,
                                          ),
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

                       
                _buildSettingsPanel(settings),

                       
                _buildSubtitlePanel(),

                       
                _buildDanmakuPanel(),

                          
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

                                          
                Positioned(
                  left: 0,
                  top: 0,
                  child: PlayerKeyboardShortcuts(
                    focusScopeNode: _focusNode,
                    actions: _buildShortcutActions(),
                    longPressActions: _buildShortcutLongPress(),
                    isBlocked: _shortcutsBlocked,
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
        if (mounted) {
          setState(() => _isCharging = state == BatteryState.charging);
        }
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

                                            
                                                      
                                            

                                                                   
                                                           
              
class _SourceEntry {
  final String label;
  final int index;
  final String? host;

  const _SourceEntry({required this.label, required this.index, this.host});
}

                                      
                                                   
class _InteractiveStep {
  final int edgeId;
  final int cid;
  final String title;
  final String chosenOption;

  const _InteractiveStep({
    required this.edgeId,
    required this.cid,
    required this.title,
    required this.chosenOption,
  });
}

                                             
                                                     
                                           
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

                               
class _SubtitleDragHint extends StatelessWidget {
  final String text;
  final bool subtle;
  const _SubtitleDragHint({required this.text, this.subtle = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: subtle ? 0.55 : 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.drag_indicator, size: 15, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

                                   
class _AudioDevicePanel extends StatefulWidget {
  const _AudioDevicePanel({
    required this.player,
    required this.current,
    required this.onPick,
  });

  final Player player;

                        
  final String current;
  final ValueChanged<AudioDevice> onPick;

  @override
  State<_AudioDevicePanel> createState() => _AudioDevicePanelState();
}

class _AudioDevicePanelState extends State<_AudioDevicePanel> {
  List<AudioDevice> _devices = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    var devices = widget.player.state.audioDevices;
    if (devices.isEmpty) {
      try {
        devices = await widget.player.stream.audioDevices
            .firstWhere((list) => list.isNotEmpty)
            .timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_devices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('没有检测到可用的音频输出设备', style: TextStyle(fontSize: 13)),
        ),
      );
    }
    return ListView(
      children: [
        ListTile(
          dense: true,
          leading: const Icon(Icons.auto_awesome, size: 20),
          title: const Text('自动', style: TextStyle(fontSize: 14)),
          trailing: widget.current.isEmpty
              ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
              : null,
          onTap: () => widget.onPick(AudioDevice.auto()),
        ),
        for (final d in _devices)
          ListTile(
            dense: true,
            leading: const Icon(Icons.speaker_outlined, size: 20),
            title: Text(
              d.description.isEmpty ? d.name : d.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: d.description.isEmpty
                ? null
                : Text(d.name, style: const TextStyle(fontSize: 11)),
            trailing: d.name == widget.current
                ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
                : null,
            onTap: () => widget.onPick(d),
          ),
      ],
    );
  }
}
