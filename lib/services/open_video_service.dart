// lib/services/open_video_service.dart
// 安卓「用其他应用打开视频 → 本应用播放」：
//   - 冷启动：consumePendingVideo() 领取暂存的视频
//   - 热启动（App 已在运行）：onVideoIntent 事件推送
// 注意：通过这种方式打开的内容不会写入播放历史（由 player 的 recordHistory 控制）。
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 外部打开的视频请求
class OpenVideoRequest {
  final String path; // 本地可播放路径
  final String? name; // 显示名称（文件名）
  const OpenVideoRequest({required this.path, this.name});
}

class OpenVideoService {
  OpenVideoService._();

  static const MethodChannel _channel =
      MethodChannel('com.memz2345.navi.flash/open_video');

  static void Function(OpenVideoRequest request)? _onVideoIntent;

  /// 领取冷启动时外部传入的视频（无则返回 null）
  static Future<OpenVideoRequest?> consumePending() async {
    try {
      final data = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('consumePendingVideo');
      if (data == null) return null;
      final path = data['path'] as String?;
      if (path == null || path.isEmpty) return null;
      return OpenVideoRequest(
        path: path,
        name: data['name'] as String?,
      );
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('consumePendingVideo 失败: ${e.message}');
      return null;
    } on MissingPluginException {
      // 非 Android 平台
      return null;
    }
  }

  /// 注册热启动事件回调（App 运行中收到新的打开请求时触发）
  static void setOnVideoIntent(void Function(OpenVideoRequest) listener) {
    _onVideoIntent = listener;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onVideoIntent') {
        final args = call.arguments as Map<dynamic, dynamic>?;
        final path = args?['path'] as String?;
        if (path == null || path.isEmpty || _onVideoIntent == null) return;
        if (!File(path).existsSync()) return;
        _onVideoIntent!(
          OpenVideoRequest(path: path, name: args?['name'] as String?),
        );
      }
    });
  }

  /// 外部视频播放完毕：结束当前任务，返回调用方应用（仅 Android 生效）
  static Future<void> finishExternalSession() async {
    try {
      await _channel.invokeMethod<void>('finishExternalSession');
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('finishExternalSession 失败: ${e.message}');
    } on MissingPluginException {
      // 非 Android 平台
    }
  }
}
