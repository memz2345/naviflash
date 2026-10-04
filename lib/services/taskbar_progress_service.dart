                                             
  
                                      
                                
                       
  
      
                              
                                           
                                                             
  
                                
                                                           
  
        
                                           
                                    
                                         
                                                 
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

                                        
                                                  
enum TaskbarProgressMode {
           
  none,

                    
  indeterminate,

                 
  determinate,

             
  paused,

            
  error,
}

class TaskbarProgress {
  TaskbarProgress._();

  static const MethodChannel _channel =
      MethodChannel('com.memz2345.navi.flash/taskbar');

                                
  static const Duration _showDelay = Duration(milliseconds: 300);

  static final Set<Object> _busy = <Object>{};
  static Timer? _showTimer;
  static bool _available = true;

                                     
  static bool get supported => Platform.isWindows && _available;

                                        
  static void begin(Object token) {
    if (!supported) return;
    final wasIdle = _busy.isEmpty;
    _busy.add(token);
    if (!wasIdle) return;
    _showTimer?.cancel();
    _showTimer = Timer(_showDelay, () {
      _showTimer = null;
      if (_busy.isEmpty) return;
      set(TaskbarProgressMode.indeterminate);
    });
  }

                           
  static void end(Object token) {
    if (!_busy.remove(token)) return;
    if (_busy.isNotEmpty) return;
    _showTimer?.cancel();
    _showTimer = null;
    set(TaskbarProgressMode.none);
  }

                        
                                                                              
  static void set(TaskbarProgressMode mode, {int value = 0}) {
    if (!supported) return;
    _channel
        .invokeMethod<void>('setProgress', <String, dynamic>{
          'mode': mode.index,
          'value': value.clamp(0, 100),
        })
        .catchError((Object e) {
      if (e is MissingPluginException) {
                                                  
        _available = false;
      } else if (kDebugMode) {
        debugPrint('任务栏进度设置失败: $e');
      }
    });
  }

                                    
  static Future<T> track<T>(Object token, Future<T> Function() action) async {
    begin(token);
    try {
      return await action();
    } finally {
      end(token);
    }
  }

                          
  static void reset() {
    _busy.clear();
    _showTimer?.cancel();
    _showTimer = null;
    set(TaskbarProgressMode.none);
  }
}
