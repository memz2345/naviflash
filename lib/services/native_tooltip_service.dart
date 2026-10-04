                                           
  
                                         
  
                                                          
                                                   
                                                                    
                                           
                     
  
                                             
                                                      
                                  
  
        
                                                                 
                      
                                               
  
                                                             
                                                     
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

class NativeTooltipService {
  NativeTooltipService._();

  static const MethodChannel _channel = MethodChannel(
    'com.memz2345.navi.flash/tooltip',
  );

                                               
  static bool enabled = true;

                      
     
                                                             
                              
  @visibleForTesting
  static bool debugForceNative = false;

                           
  static bool get useNative => enabled && (debugForceNative || Platform.isAndroid);

                
  static int _seq = 0;

                                      
     
                                           
                                              
                                          
                
  static int _visible = 0;

                                              
     
                                               
            
  static int show({
    required String text,
    required Rect anchor,
    required bool dark,
  }) {
    if (!useNative || text.isEmpty) return 0;
    final token = ++_seq;
    _visible = token;
    unawaited(
      _invoke('show', {
        'text': text,
        'x': anchor.left,
        'y': anchor.top,
        'w': anchor.width,
        'h': anchor.height,
        'dark': dark,
      }),
    );
    return token;
  }

                                                         
  static void hide(int? token) {
    if (!useNative || token == null || token == 0 || token != _visible) return;
    _visible = 0;
    unawaited(_invoke('hide'));
  }

  static Future<void> _invoke(String method, [Object? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } catch (_) {
                                           
                                      
    }
  }

                              
  @visibleForTesting
  static void resetForTest() {
    enabled = true;
    debugForceNative = false;
    _seq = 0;
    _visible = 0;
  }
}
