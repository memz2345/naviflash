// lib/services/media_kit_audio_handler.dart
//
// 系统媒体播放器（通知 / Windows SMTC / 锁屏媒体控制）集成：
//   - attachPlayer 只登记播放器与元数据，是否真正激活媒体会话由播放状态决定：
//     只有「实际开始播放且非缓冲」时才显示（mediaItem + 活跃 playbackState）；
//     暂停 / 停止即隐藏，恢复播放再显示——避免「没播放就弹出系统媒体播放器」。
//   - 支持封面 artUri（网络 URL 或 file://），激活时作为缩略图展示。
//   - Windows：audio_service 无原生实现，改由 SmtcWindowsService 镜像状态到
//     系统媒体控件（控制中心卡片 + 任务栏缩略图工具栏）。SMTC 会话在暂停时
//     保留卡片（Paused 态），仅 stop/退出播放页时注销。
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

  /// 系统媒体控件「下一集」回调（Windows SMTC / 任务栏缩略图按钮、
  /// Android 通知栏下一首按钮均会触发），由播放页注入。
  void Function()? onSkipToNext;

  /// 系统媒体控件「上一集」回调，由播放页注入。
  void Function()? onSkipToPrevious;

  // ---- Windows SMTC 镜像状态 ----
  static final SmtcWindowsService _smtc = SmtcWindowsService.instance;
  bool _smtcActive = false;
  DateTime _lastSmtcPositionAt =
      DateTime.fromMillisecondsSinceEpoch(0);

  /// 注入 SMTC 按钮回调（仅 Windows 真正生效）。
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

  /// 回退 / 快进（Duration 为负=回退），夹在 [0, duration] 区间。
  void _seekBy(Duration delta) {
    final player = _player;
    if (player == null) return;
    var target = player.state.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    final duration = player.state.duration;
    if (duration > Duration.zero && target > duration) target = duration;
    player.seek(target);
  }

  /// 绑定播放器并更新元数据。同一播放器重复调用只刷新元数据，
  /// 不会重建订阅；是否激活系统媒体会话始终由播放状态驱动。
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
      if (_activated) {
        playbackState.add(playbackState.value.copyWith(updatePosition: pos));
      }
      _throttledSmtcPosition(pos);
    });
    if (player.state.playing) _onPlaying(true);
  }

  /// 封面地址规范化：`//` 补 https，http 升 https，保证跨平台可取缩略图。
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
      // 首次真正播放且非缓冲时才激活会话
      if (!_activated && !(_player?.state.buffering ?? false)) {
        _activate();
      }
    } else {
      _deactivate();
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
    ));
  }

  /// 隐藏系统媒体播放器（未播放时不应占用系统媒体会话）。
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

  // ---- Windows SMTC 镜像 ----

  String get _smtcTitle => _title ?? L10n.current.nowPlayingVideo;

  /// 播放状态变化 → 激活 / 更新 SMTC（暂停时保留卡片为 Paused 态）。
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

  /// 元数据变化（切集 / 换清晰度 / 复用播放器重新 attach）→ 刷新卡片。
  void _pushSmtcMetadata() {
    if (!SmtcWindowsService.isSupported || !_smtcActive) return;
    _smtc.updateMetadata(
      title: _smtcTitle,
      artist: _artist,
      artUri: _artUri?.toString(),
    );
  }

  /// 时长变化 → 刷新时间轴。
  void _pushSmtcTimeline() {
    if (!SmtcWindowsService.isSupported || !_smtcActive) return;
    _smtc.updatePosition(
      _player?.state.position.inMilliseconds ?? 0,
      _player?.state.duration.inMilliseconds ?? 0,
    );
  }

  /// 进度流节流（~1s）→ 控制中心时间轴。
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
  Future<void> seek(Duration position) async => _player?.seek(position);

  @override
  Future<void> skipToNext() async => onSkipToNext?.call();

  @override
  Future<void> skipToPrevious() async => onSkipToPrevious?.call();

  @override
  Future<void> stop() async {
    _disposeSubscriptions();
    _activated = false;
//  注销 Windows SMTC 会话（关闭控制中心卡片 + 隐藏任务栏按钮）
    if (_smtcActive) {
      _smtcActive = false;
      await _smtc.deactivate();
    }
//  先摘除播放器引用，再停止：退出播放页时 `player.dispose()` 与本方法
    //    的 `stop()` 并发，可能竞态抛 `[Player] has been disposed`，这里吞掉并
    //    置空引用，保证后续系统媒体控制不会触碰已释放的播放器。
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
