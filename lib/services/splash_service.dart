                                   
  
                                         
                                                   
                                            
  
                                                                               
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class SplashService {
  static const MethodChannel _channel =
      MethodChannel('com.memz2345.navi.flash/splash');

                          
  static bool get isSupported => Platform.isAndroid;

                             
  static Future<bool> hasBackground() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('hasBackground') ?? false;
    } catch (e) {
      debugPrint('[Splash] hasBackground 查询失败: $e');
      return false;
    }
  }

                                                
                        
  static Future<bool> setBackground(String sourcePath) async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('setBackground', {
            'path': sourcePath,
          }) ??
          false;
    } catch (e) {
      debugPrint('[Splash] 设置背景失败: $e');
      return false;
    }
  }

                      
  static Future<bool> clearBackground() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('clearBackground') ?? false;
    } catch (e) {
      debugPrint('[Splash] 清除背景失败: $e');
      return false;
    }
  }
}
