// lib/services/app_shortcut_bridge.dart
//
// Android / iOS 桌面「长按图标」快捷入口（App Shortcuts）桥接：
//   应用内统一动作串与 Windows JumpList 保持一致：
//     search（B站搜索） / offline（离线视频·我的缓存） / recommend（推荐主页）
//   以及 video:<bvid>（预留，供动态最近条目使用）。
//
// 原生协议（通道 com.memz2345.navi.flash/action）：
//   - 冷启动：原生先暂存快捷动作，Dart 注册后调用 consumePendingAction
//     取回（取一次即清除）。
//   - 热启动（应用已在运行）：原生直接向 Dart 推送 onAction。
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppShortcutBridge {
  static const _channel = MethodChannel('com.memz2345.navi.flash/action');

  /// 处理收到的动作（search / offline / recommend / video:<bvid>）。
  void Function(String action)? onAction;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAction') {
        final action = call.arguments;
        if (action is String && action.isNotEmpty) onAction?.call(action);
      }
    });

    // 冷启动暂存的动作：主动取一次
    try {
      final raw = await _channel.invokeMethod('consumePendingAction');
      if (raw is String && raw.isNotEmpty) onAction?.call(raw);
    } catch (e) {
      debugPrint('⚠️ 读取快捷入口启动参数失败: $e');
    }
  }
}
