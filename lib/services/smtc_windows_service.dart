// lib/services/smtc_windows_service.dart
//
// Windows 系统媒体控件桥接（原生实现在 windows/runner/smtc_controls.cpp）：
//   - SMTC：Win10/11 控制中心 / 音量浮层 / 蓝牙耳机等系统媒体卡片。
//   - 任务栏缩略图工具栏：鼠标悬停任务栏图标时预览窗下方的
//     上一集 / 回退20s / 播放暂停 / 快进20s / 下一集 五个按钮。
//
// 使用方式（仅 Windows 生效，其他平台全部 no-op）：
//   1. 设置按钮回调：instance.onPlay / onPause / onPlayPause / onNext /
//      onPrevious / onSeekBy（Duration，正负代表快进/回退秒数）。
//   2. 播放开始时 activate()，之后按需 updateMetadata / updatePlaybackState /
//      updatePosition（建议 1s 节流），退出播放页时 deactivate()。
//
// 原生按钮事件统一以 onButtonPressed {action} 回推到 Dart，action ∈
// play / pause / playPause / next / previous / rewind / fastForward。
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

class SmtcWindowsService {
  SmtcWindowsService._() {
    if (isSupported) {
      _channel.setMethodCallHandler(_handleNativeCall);
    }
  }

  static final SmtcWindowsService instance = SmtcWindowsService._();

  static const _channel = MethodChannel('com.memz2345.navi.flash/smtc');

  /// 仅 Windows 桌面端支持。
  static bool get isSupported => Platform.isWindows;

  /// 回退 / 快进的步长（与原生任务栏按钮提示文案保持一致）。
  static const seekDelta = Duration(seconds: 20);

  // ---- 按钮事件回调（由 MediaKitAudioHandler 统一注入） ----
  void Function()? onPlay;
  void Function()? onPause;
  void Function()? onPlayPause;
  void Function()? onNext;
  void Function()? onPrevious;

  /// Duration 为正=快进，为负=回退。
  void Function(Duration delta)? onSeekBy;

  /// 当前是否已激活（避免重复 activate / 位置更新浪费）。
  bool _active = false;
  bool get isActive => _active;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onButtonPressed') {
      final args = call.arguments;
      final action = args is Map ? args['action'] as String? : null;
      _dispatch(action);
    }
    return null;
  }

  void _dispatch(String? action) {
    switch (action) {
      case 'play':
        onPlay?.call();
        break;
      case 'pause':
        onPause?.call();
        break;
      case 'playPause':
        onPlayPause?.call();
        break;
      case 'next':
        onNext?.call();
        break;
      case 'previous':
        onPrevious?.call();
        break;
      case 'rewind':
        onSeekBy?.call(-seekDelta);
        break;
      case 'fastForward':
        onSeekBy?.call(seekDelta);
        break;
    }
  }

  Future<void> _invoke(String method, [Map<String, dynamic>? args]) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod(method, args);
    } catch (_) {
      // 原生端尚未更新 / 系统不支持时静默降级
    }
  }

  /// 激活媒体会话：显示控制中心卡片与任务栏缩略图按钮。
  Future<void> activate({
    required String title,
    String? artist,
    String? artUri,
    required bool playing,
    required int positionMs,
    required int durationMs,
  }) async {
    _active = true;
    await _invoke('activate', {
      'title': title,
      'artist': artist ?? '',
      'artUri': artUri ?? '',
      'playing': playing,
      'positionMs': positionMs,
      'durationMs': durationMs,
    });
  }

  /// 更新元数据（标题 / 作者 / 封面）。
  Future<void> updateMetadata({
    required String title,
    String? artist,
    String? artUri,
  }) async {
    await _invoke('updateMetadata', {
      'title': title,
      'artist': artist ?? '',
      'artUri': artUri ?? '',
    });
  }

  /// 更新播放状态（控制中心 Playing/Paused + 任务栏播放/暂停图标互换）。
  Future<void> updatePlaybackState(bool playing) async {
    await _invoke('updatePlaybackState', {'playing': playing});
  }

  /// 更新进度（控制中心媒体卡片时间轴，建议 ~1s 一次）。
  Future<void> updatePosition(int positionMs, int durationMs) async {
    await _invoke('updatePosition', {
      'positionMs': positionMs,
      'durationMs': durationMs,
    });
  }

  /// 注销会话：关闭控制中心卡片并隐藏任务栏缩略图按钮。
  Future<void> deactivate() async {
    _active = false;
    await _invoke('deactivate');
  }
}
