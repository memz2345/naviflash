// lib/services/display_mode_service.dart
// 屏幕帧率（Display Mode）服务：封装 flutter_displaymode（仅 Android 生效）。
// 原理：通过 WindowManager.LayoutParams.preferredDisplayModeId 设置偏好帧率，
//       该偏好是窗口属性，系统不会持久保存，因此启动时需要重新应用一次。
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'settings_service.dart';

class DisplayModeService {
  /// 启动时恢复上次保存的屏幕帧率偏好（仅 Android 生效）
  static Future<void> restorePreferred(SettingsService settings) async {
    if (!Platform.isAndroid) return;
    final saved = settings.displayMode;
    if (saved == null || saved.isEmpty) return;
    try {
      final modes = await FlutterDisplayMode.supported;
      for (final mode in modes) {
        if (mode.toString() == saved) {
          await FlutterDisplayMode.setPreferredMode(mode);
          if (kDebugMode) debugPrint('✅ 已恢复屏幕帧率: $saved');
          return;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 恢复屏幕帧率失败: $e');
    }
  }

  /// 把保存的 DisplayMode.toString() 解析成可读标签（如 "1080×2400 @ 120Hz"）。
  /// 无法解析或为空时返回 [autoText]（即「自动」）。
  static String labelOf(String? saved, {required String autoText}) {
    if (saved == null || saved.isEmpty) return autoText;
    if (saved == DisplayMode.auto.toString()) return autoText;
    final match = RegExp(r'(\d+)x(\d+) @ (\d+)Hz').firstMatch(saved);
    if (match == null) return autoText;
    return '${match.group(1)}×${match.group(2)} @ ${match.group(3)}Hz';
  }
}
