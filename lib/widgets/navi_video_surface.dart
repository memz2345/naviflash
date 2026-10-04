import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' hide Playlist;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:naviflash/services/player_audio_service.dart';
import 'package:naviflash/services/player_settings_service.dart';
import 'package:naviflash/services/playback_focus.dart';
import 'package:naviflash/services/sleep_timer_service.dart';
import 'package:naviflash/services/super_resolution_service.dart';

           
   
                                            
                                  
                                  
                                  
   
                                          
                                                    
class NaviVideoSurface extends StatefulWidget {
  const NaviVideoSurface({
    super.key,
    required this.videoUrl,
    this.httpHeaders,
    this.initialPosition,
    this.autoPlay = true,
    this.looping = false,
    this.fit = BoxFit.contain,
    this.playerSettings,
    this.onReady,
    this.onEnded,
    this.onPositionChanged,
    this.onDurationChanged,
    this.onError,
  });

                                     
  final String videoUrl;

                                      
  final Map<String, String>? httpHeaders;

                        
  final Duration? initialPosition;

  final bool autoPlay;

                   
  final bool looping;

  final BoxFit fit;

                                     
  final PlayerSettingsService? playerSettings;

  final VoidCallback? onReady;
  final VoidCallback? onEnded;
  final ValueChanged<Duration>? onPositionChanged;
  final ValueChanged<Duration>? onDurationChanged;
  final ValueChanged<String>? onError;

  @override
  State<NaviVideoSurface> createState() => NaviVideoSurfaceState();
}

class NaviVideoSurfaceState extends State<NaviVideoSurface>
    implements PlaybackAudioSource {
  late final Player player;
  late final VideoController controller;

  bool _disposed = false;
  bool _ready = false;
  final List<StreamSubscription<dynamic>> _subs = [];

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

                                          
                                               
  double _rate = 1.0;

                             
  Duration get position => _position;

                      
  Duration get duration => _duration;

                                  
  double get aspectRatio {
    final w = player.state.width ?? 0;
    final h = player.state.height ?? 0;
    if (w <= 0 || h <= 0) return 0;
    return w / h;
  }

                    
     
                              
                          
  bool get isLandscapeVideo => aspectRatio > 1.0;

              
  bool get isReady => _ready;

  Player get mediaPlayer => player;
  VideoController get videoController => controller;

  @override
  void initState() {
    super.initState();
    player = Player(
                                                       
                                            
                                      
      configuration: const PlayerConfiguration(bufferSize: 16 * 1024 * 1024),
    );
    controller = VideoController(player);
    PlaybackFocus.instance.register(this);
                                        
    SleepTimerService.instance.bindPauseTarget(this, () {
      if (!_disposed) player.pause();
    });
    _bindStreams();
    unawaited(_configurePlayer());
    if (widget.looping) {
      unawaited(player.setPlaylistMode(PlaylistMode.loop));
    }
    if (widget.autoPlay) {
      unawaited(open());
    }
  }

  void _bindStreams() {
    _subs.add(
      player.stream.position.listen((p) {
        if (_disposed) return;
        _position = p;
        widget.onPositionChanged?.call(p);
      }),
    );
    _subs.add(
      player.stream.duration.listen((d) {
        if (_disposed) return;
        _duration = d;
        widget.onDurationChanged?.call(d);
      }),
    );
    _subs.add(
      player.stream.playing.listen((playing) {
        if (_disposed || !playing) return;
                                         
                                     
        unawaited(PlaybackFocus.instance.acquire(this));
        if (_ready) return;
        _ready = true;
        widget.onReady?.call();
        if (mounted) setState(() {});
      }),
    );
    _subs.add(
      player.stream.error.listen((e) {
        if (_disposed || e.isEmpty) return;
        debugPrint('❌ NaviVideoSurface mpv 错误: $e');
        widget.onError?.call(e);
      }),
    );
    _subs.add(
      player.stream.completed.listen((done) {
        if (_disposed || !done) return;
                                                     
        if (!widget.looping) widget.onEnded?.call();
      }),
    );
  }

                                                          
  Future<void> _configurePlayer() async {
    final platform = player.platform;
    if (platform is! NativePlayer) return;

    Future<void> set(String key, String value) async {
      try {
        await platform.setProperty(key, value);
      } catch (e) {
        debugPrint('⚠️ NaviVideoSurface setProperty($key) 失败: $e');
      }
    }

    await set(
      'stream-lavf-o',
      'reconnect=1,reconnect_at_eof=1,reconnect_streamed=1,reconnect_delay_max=5',
    );
                                                        
                                                    
                                    
    await set('demuxer-max-bytes', '16MiB');
    await set('demuxer-max-back-bytes', '4MiB');
    await set('demuxer-readahead-secs', '5');
    await set('network-timeout', '30');

    final ps = widget.playerSettings;
    if (ps != null) {
      await set('hwdec', ps.hwdecEnabled ? ps.hwdecMode : 'no');
      await set('video-sync', ps.videoSync);
      await PlayerAudioService.apply(platform, ps.audioNormalization);
      if (ps.superResolutionMode != 'disable') {
        await SuperResolutionService.apply(platform, ps.superResolutionMode);
      }
    }
  }

                                               
                                                 
                            
  @override
  void didUpdateWidget(covariant NaviVideoSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl &&
        widget.videoUrl.isNotEmpty &&
        !_disposed) {
      _ready = false;
      unawaited(open());
    }
  }

                                       
  @override
  bool get isPlaying => player.state.playing;

                                  
  Future<void> open() async {
    try {
      _ready = false;
      await player.open(
        Media(widget.videoUrl, httpHeaders: widget.httpHeaders),
      );
      if (_disposed) return;
      final start = widget.initialPosition;
      if (start != null && start > Duration.zero) {
        await _seekWhenReady(start);
      }
                                        
      if (_rate != 1.0) {
        await player.setRate(_rate);
      }
    } catch (e) {
      debugPrint('❌ NaviVideoSurface open 异常: $e');
      widget.onError?.call('$e');
    }
  }

                                   
  Future<void> _seekWhenReady(Duration target) async {
    for (var i = 0; i < 30; i++) {
      if (_disposed) return;
      if (player.state.duration > Duration.zero) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (_disposed) return;
    try {
      await player.seek(target);
    } catch (e) {
      debugPrint('⚠️ NaviVideoSurface seek 失败: $e');
    }
  }

  Future<void> play() => player.play();
  @override
  Future<void> pause() => player.pause();
  Future<void> togglePlay() => player.playOrPause();
  Future<void> seek(Duration target) => player.seek(target);

                                      
  Future<void> setRate(double rate) async {
    _rate = rate;
    if (_disposed) return;
    try {
      await player.setRate(rate);
    } catch (e) {
      debugPrint('⚠️ NaviVideoSurface setRate 失败: $e');
    }
  }

                     
  double get rate => _rate;

  @override
  void dispose() {
    _disposed = true;
    PlaybackFocus.instance.unregister(this);
    SleepTimerService.instance.unbindPauseTarget(this);
    for (final s in _subs) {
      s.cancel();
    }
                                               
                                          
    unawaited(player.pause());
    unawaited(player.dispose().catchError((_) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: controller,
      fit: widget.fit,
      fill: Colors.black,
      controls: NoVideoControls,
    );
  }
}
