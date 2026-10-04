                                            
  
                                         
                                                 
                                                        
                                                  
                                                
                                                           
             
                                                
                                                              
                                             
                                      
import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';
import 'dart:async';
import '../l10n/l10n_helper.dart';
import 'smtc_windows_service.dart';

class MediaKitAudioHandler extends BaseAudioHandler {
  MediaKitAudioHandler() {
    _wireSmtc();
  }

  Player? _player;
  StreamSubscription? _durationSub;
  StreamSubscription? _playingSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _bufferingSub;

  String? _title;
  String? _artist;
  Uri? _artUri;
  bool _activated = false;

                         
     
                                                       
                                                                     
                                                           
                                                                   
                                            
                                             
                               
     
                                                     
                                    
                                                      
                                                 
                             
  DateTime _lastSessionPositionPushAt =
      DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _sessionPositionPushInterval = Duration(seconds: 1);

                                            
                                   
  void Function()? onSkipToNext;

                           
  void Function()? onSkipToPrevious;

                                
  static final SmtcWindowsService _smtc = SmtcWindowsService.instance;
  bool _smtcActive = false;
  DateTime _lastSmtcPositionAt =
      DateTime.fromMillisecondsSinceEpoch(0);

                                   
  void _wireSmtc() {
    if (!SmtcWindowsService.isSupported) return;
    _smtc.onPlay = () => _player?.play();
    _smtc.onPause = () => _player?.pause();
    _smtc.onPlayPause = _playOrPause;
    _smtc.onPrevious = () => onSkipToPrevious?.call();
    _smtc.onNext = () => onSkipToNext?.call();
    _smtc.onSeekBy = _seekBy;
  }

  void _playOrPause() {
    final player = _player;
    if (player == null) return;
    if (player.state.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

                                                  
  void _seekBy(Duration delta) {
    final player = _player;
    if (player == null) return;
    var target = player.state.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    final duration = player.state.duration;
    if (duration > Duration.zero && target > duration) target = duration;
    player.seek(target);
  }

                                  
                                 
  void attachPlayer(Player player,
      {String? title, String? artist, String? artUri}) {
    if (_player == player) {
      _title = title ?? _title;
      _artist = artist ?? _artist;
      if (artUri != null) _artUri = _normalizeArtUri(artUri);
      if (_activated) _updateMediaItem();
      if (_smtcActive) _pushSmtcMetadata();
      return;
    }
    _disposeSubscriptions();
    _player = player;
    _title = title;
    _artist = artist;
    _artUri = artUri == null ? null : _normalizeArtUri(artUri);
    _activated = false;
    _durationSub = player.stream.duration.listen((_) {
      if (_activated) _updateMediaItem();
      if (_smtcActive) _pushSmtcTimeline();
    });
    _playingSub = player.stream.playing.listen(_onPlaying);
    _bufferingSub = player.stream.buffering.listen(_onBuffering);
    _positionSub = player.stream.position.listen((pos) {
      _throttledSessionPosition(pos);
      _throttledSmtcPosition(pos);
    });
    if (player.state.playing) _onPlaying(true);
  }

                                                   
  static Uri? _normalizeArtUri(String artUri) {
    final trimmed = artUri.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (trimmed.startsWith('//')) return Uri.parse('https:$trimmed');
    if (uri.scheme == 'http') return uri.replace(scheme: 'https');
    return uri;
  }

  void _onPlaying(bool playing) {
    if (playing) {
      final player = _player;
      if (player == null) return;
      if (!_activated) {
                           
        if (!player.state.buffering) _activate();
      } else {
                                         
                                               
                                       
        playbackState.add(playbackState.value.copyWith(
          playing: true,
          processingState: player.state.buffering
              ? AudioProcessingState.buffering
              : AudioProcessingState.ready,
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.skipToNext,
          ],
          systemActions: const {MediaAction.seek},
          updatePosition: player.state.position,
          speed: player.state.rate,
        ));
      }
    } else {
      final player = _player;
      if (player != null && player.state.completed) {
                                     
        _deactivate();
      } else if (_activated && player != null) {
                                                  
                                                              
                                         
        playbackState.add(playbackState.value.copyWith(
          playing: false,
          processingState: AudioProcessingState.ready,
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.play,
            MediaControl.skipToNext,
          ],
          systemActions: const {MediaAction.seek},
          updatePosition: player.state.position,
          speed: 1.0,
        ));
      }
    }
    _smtcSetPlaying(playing);
  }

  void _onBuffering(bool buffering) {
    if (!buffering && !_activated && (_player?.state.playing ?? false)) {
      _activate();
    }
  }

  void _activate() {
    if (_activated) return;
    final player = _player;
    if (player == null) return;
    _activated = true;
    _lastSessionPositionPushAt = DateTime.now();
    _updateMediaItem();
    playbackState.add(PlaybackState(
      playing: player.state.playing,
      processingState: AudioProcessingState.ready,
      controls: [
        MediaControl.skipToPrevious,
        player.state.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      updatePosition: player.state.position,
      speed: player.state.playing ? player.state.rate : 1.0,
    ));
  }

                             
     
                                                        
                                            
                      
  void _throttledSessionPosition(Duration pos) {
    if (!_activated) return;
    final now = DateTime.now();
    if (now.difference(_lastSessionPositionPushAt) <
        _sessionPositionPushInterval) {
      return;
    }
    _lastSessionPositionPushAt = now;
    final player = _player;
    playbackState.add(playbackState.value.copyWith(
      updatePosition: pos,
      speed: (player?.state.playing ?? false) ? player!.state.rate : 1.0,
    ));
  }

                                          
  void _pushSessionPositionNow() {
    final player = _player;
    if (!_activated || player == null) return;
    _lastSessionPositionPushAt = DateTime.now();
    playbackState.add(playbackState.value.copyWith(
      updatePosition: player.state.position,
      speed: player.state.playing ? player.state.rate : 1.0,
    ));
  }

                                
  void _deactivate() {
    if (!_activated) return;
    _activated = false;
    mediaItem.add(null);
    playbackState.add(PlaybackState(
      playing: false,
      processingState: AudioProcessingState.idle,
      controls: const [],
      systemActions: const {},
    ));
  }

  void _updateMediaItem() {
    if (_player == null) return;
    final media = _player!.state.playlist.medias.firstOrNull;
    mediaItem.add(MediaItem(
      id: media?.uri ?? DateTime.now().toString(),
      title: _title ?? L10n.current.nowPlayingVideo,
      artist: _artist,
      artUri: _artUri,
      duration: _player!.state.duration,
    ));
  }

                              

  String get _smtcTitle => _title ?? L10n.current.nowPlayingVideo;

                                               
  void _smtcSetPlaying(bool playing) {
    if (!SmtcWindowsService.isSupported) return;
    if (playing) {
      if (!_smtcActive) {
        _smtcActive = true;
        _smtc.activate(
          title: _smtcTitle,
          artist: _artist,
          artUri: _artUri?.toString(),
          playing: true,
          positionMs: _player?.state.position.inMilliseconds ?? 0,
          durationMs: _player?.state.duration.inMilliseconds ?? 0,
        );
      } else {
        _smtc.updatePlaybackState(true);
      }
    } else if (_smtcActive) {
      _smtc.updatePlaybackState(false);
    }
  }

                                              
  void _pushSmtcMetadata() {
    if (!SmtcWindowsService.isSupported || !_smtcActive) return;
    _smtc.updateMetadata(
      title: _smtcTitle,
      artist: _artist,
      artUri: _artUri?.toString(),
    );
  }

                   
  void _pushSmtcTimeline() {
    if (!SmtcWindowsService.isSupported || !_smtcActive) return;
    _smtc.updatePosition(
      _player?.state.position.inMilliseconds ?? 0,
      _player?.state.duration.inMilliseconds ?? 0,
    );
  }

                          
  void _throttledSmtcPosition(Duration pos) {
    if (!SmtcWindowsService.isSupported || !_smtcActive) return;
    final now = DateTime.now();
    if (now.difference(_lastSmtcPositionAt) < const Duration(seconds: 1)) {
      return;
    }
    _lastSmtcPositionAt = now;
    _smtc.updatePosition(
      pos.inMilliseconds,
      _player?.state.duration.inMilliseconds ?? 0,
    );
  }

  void _disposeSubscriptions() {
    _durationSub?.cancel();
    _playingSub?.cancel();
    _positionSub?.cancel();
    _bufferingSub?.cancel();
  }

  @override
  Future<void> play() async => _player?.play();

  @override
  Future<void> pause() async => _player?.pause();

  @override
  Future<void> seek(Duration position) async {
    final player = _player;
    if (player == null) return;
    await player.seek(position);
                                       
    _pushSessionPositionNow();
  }

  @override
  Future<void> skipToNext() async => onSkipToNext?.call();

  @override
  Future<void> skipToPrevious() async => onSkipToPrevious?.call();

  @override
  Future<void> stop() async {
    _disposeSubscriptions();
    _activated = false;
                                          
    if (_smtcActive) {
      _smtcActive = false;
      await _smtc.deactivate();
    }
                                               
                                                                
                                     
    final player = _player;
    _player = null;
    if (player != null) {
      try {
        await player.stop();
      } catch (_) {}
    }
    await super.stop();
  }
}
