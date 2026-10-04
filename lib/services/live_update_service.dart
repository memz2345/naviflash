                                        
  
                                   
                                          
                                                             
                                        
                         
                                                                                    
  
                              
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class LiveUpdateService {
  static const MethodChannel _channel =
      MethodChannel('com.memz2345.navi.flash/live_update');

  static bool? _supported;

                                         
                                                   
  static Future<bool> isSupported() async {
    if (!Platform.isAndroid) return false;
    final cached = _supported;
    if (cached != null) return cached;
    try {
      final v = await _channel.invokeMethod<bool>('isSupported');
      _supported = v ?? false;
      return _supported!;
    } catch (e) {
      debugPrint('[LiveUpdate] isSupported 查询失败: $e');
      return false;
    }
  }

                                             
                                            
  static Future<void> start(
    int id,
    String title, {
    String? text,
    Uint8List? coverBytes,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('start', {
        'id': id,
        'title': title,
        'text': text,
        'cover': coverBytes,
      });
    } catch (e) {
      debugPrint('[LiveUpdate] start 失败: $e');
    }
  }

                                                           
                    
  static Future<void> update(
    int id, {
    required int progress,
    String? text,
    bool indeterminate = false,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('update', {
        'id': id,
        'progress': progress.clamp(0, 100),
        'text': text,
        'indeterminate': indeterminate,
      });
    } catch (e) {
      debugPrint('[LiveUpdate] update 失败: $e');
    }
  }

                                 
  static Future<void> finish(int id, {String? title, String? text}) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('finish', {
        'id': id,
        'title': title,
        'text': text,
      });
    } catch (e) {
      debugPrint('[LiveUpdate] finish 失败: $e');
    }
  }

                               
  static Future<void> fail(int id, {String? title, String? text}) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('fail', {
        'id': id,
        'title': title,
        'text': text,
      });
    } catch (e) {
      debugPrint('[LiveUpdate] fail 失败: $e');
    }
  }

             
  static Future<void> cancel(int id) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('cancel', {'id': id});
    } catch (e) {
      debugPrint('[LiveUpdate] cancel 失败: $e');
    }
  }
}
