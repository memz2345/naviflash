// lib/services/jump_list_service.dart
//
// Windows 端 JumpList 支持（NaviFlash 无聊天，跳转目标为内容导航）：
//   - 「任务」区（系统 Tasks / AddUserTasks）：搜索 / 离线视频 / 推荐，
//     由原生 C++ 固定生成，参数 --flash-action=search|offline|recommend。
//   - 「最近观看」自定义类别：最近观看的 5 条视频（由 Dart 下发）。
//     启动参数 --flash-action=video:<bvid>。
//
// 原生协议（通道 com.memz2345.navi.flash/jumplist）：
//   Dart → 原生：setJumpList(List<{name, action}>) / clearJumpList /
//                consumeLaunchArgs()（返回并清除 JumpList 点击启动的动作）
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 一条 JumpList「最近观看」条目。
class JumpListItem {
  final String name;
  final String action;

  const JumpListItem({required this.name, required this.action});

  Map<String, dynamic> toMap() => {'name': name, 'action': action};
}

class JumpListService {
  static final JumpListService _instance = JumpListService._internal();
  factory JumpListService() => _instance;
  JumpListService._internal();

  static const _channel = MethodChannel('com.memz2345.navi.flash/jumplist');

  /// 收到来自原生（主实例）热推送的 JumpList 动作（单实例跳转模式：
  /// 点击任务栏 JumpList 项时，若已有实例在运行，原生把动作转发给本实例）。
  void Function(String action)? onAction;

  bool _initialized = false;

  /// 注册原生热推送入口（仅 Windows；须在 [consumeLaunchAction] 前调用，
  /// 避免冷启动动作先于 handler 到达而丢失）。
  Future<void> init() async {
    if (!Platform.isWindows || _initialized) return;
    _initialized = true;
    try {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onAction') {
          final action = call.arguments;
          if (action is String && action.isNotEmpty) {
            debugPrint('🔗 Jump List 热推送动作: $action');
            onAction?.call(action);
          }
        }
      });
    } catch (e) {
      debugPrint('⚠️ 注册 Jump List 热推送失败: $e');
    }
  }

  /// 由 JumpList 点击启动时要执行的动作（仅在 Windows 冷启动场景，取一次）。
  Future<String?> consumeLaunchAction() async {
    if (!Platform.isWindows) return null;
    try {
      final raw = await _channel.invokeMethod('consumeLaunchArgs');
      if (raw is Map) {
        final action = raw['action'];
        if (action is String && action.isNotEmpty) return action;
      }
    } catch (e) {
      debugPrint('⚠️ 读取 Jump List 启动参数失败: $e');
    }
    return null;
  }

  /// 更新「最近观看」条目（原生会自动补上固定的任务区）。
  Future<void> updateRecentVideos(List<JumpListItem> items) async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod(
        'setJumpList',
        items.take(5).map((c) => c.toMap()).toList(),
      );
      debugPrint('✅ Jump List 最近观看已更新 (${items.length} 条)');
    } catch (e) {
      debugPrint('❌ Jump List 更新失败: $e');
    }
  }

  Future<void> clearJumpList() async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod('clearJumpList');
    } catch (_) {}
  }
}
