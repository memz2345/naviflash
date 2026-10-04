                                        
  
                                               
                                     
                                                          
                                   
  
                                           
                                                    
                  
                                          
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppShortcutBridge {
  static const _channel = MethodChannel('com.memz2345.navi.flash/action');

                                                             
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

                     
    try {
      final raw = await _channel.invokeMethod('consumePendingAction');
      if (raw is String && raw.isNotEmpty) onAction?.call(raw);
    } catch (e) {
      debugPrint('⚠️ 读取快捷入口启动参数失败: $e');
    }
  }
}
