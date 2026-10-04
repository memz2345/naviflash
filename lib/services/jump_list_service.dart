                                      
  
                                                  
                                                     
                                                               
                                          
                                        
  
                                             
                                                                  
                                                             
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

                        
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

                                          
                                              
  void Function(String action)? onAction;

  bool _initialized = false;

                                                       
                               
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
