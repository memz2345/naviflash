                                   
  
                                                     
                                                         
                                                
  
                                                  
                                                      
                                                
// ignore_for_file: non_constant_identifier_names, library_private_types_in_public_api, unnecessary_library_name, depend_on_referenced_packages
@ffi.DefaultAsset('package:llamadart/llamadart')
library tts_native_log;

import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

typedef _LogCbNative = ffi.Void Function(
  ffi.Int32 level,
  ffi.Pointer<ffi.Char> text,
  ffi.Pointer<ffi.Void> userData,
);
typedef _LogSetNative = ffi.Void Function(
  ffi.Pointer<ffi.NativeFunction<_LogCbNative>>,
  ffi.Pointer<ffi.Void>,
);

                                                                
                                                   
@ffi.Native<_LogSetNative>()
external void ggml_log_set(
  ffi.Pointer<ffi.NativeFunction<_LogCbNative>> logCallback,
  ffi.Pointer<ffi.Void> userData,
);

                                                             
                                              
typedef _SetLogLevelNative = ffi.Void Function(ffi.Int32);
@ffi.Native<_SetLogLevelNative>()
external void llama_dart_set_log_level(int level);

                                                               
                                        
@ffi.Native<_LogSetNative>()
external void llama_log_set(
  ffi.Pointer<ffi.NativeFunction<_LogCbNative>> logCallback,
  ffi.Pointer<ffi.Void> userData,
);



                                                       
class TtsNativeLog {
  TtsNativeLog._();

  static ffi.NativeCallable<_LogCbNative>? _callable;
  static bool _installed = false;

                                
  static int totalCalls = 0;

                                              
                                    
  static final List<String> recent = [];

  static bool _isRelevant(String m) {
    final s = m.toLowerCase();
    return s.contains('ggml-hex') ||
        s.contains('hexagon') ||
        s.contains('htp') ||
        s.contains('cdsp') ||
        s.contains('load_tensors') ||
        s.contains('using device') ||
        s.contains('assigned to device') ||
        s.contains('offload') ||
        s.contains('backend') ||
        s.contains('device buffer') ||
        s.contains('model buffer size') ||
        s.contains('rpcmem') ||
        s.contains('error') ||
        s.contains('abort') ||
        s.contains('failed');
  }

  static void _onLog(
    int level,
    ffi.Pointer<ffi.Char> text,
    ffi.Pointer<ffi.Void> userData,
  ) {
    if (text == ffi.nullptr) return;
    totalCalls++;
    final msg = text.cast<Utf8>().toDartString().trimRight();
    debugPrint('[ggml] $msg');
    if (_isRelevant(msg)) {
      recent.add(msg);
      if (recent.length > 200) recent.removeAt(0);
    }
  }

                      
  static void install() {
    _installed = true;
    rearm();
  }

                            
     
                                              
                                                           
                                                  
                                                   
  static void rearm() {
    try {
      _callable ??= ffi.NativeCallable<_LogCbNative>.listener(_onLog);
                                                                   
                                                          
                                                            
                    
      llama_dart_set_log_level(kReleaseMode ? 3 : 1);
      ggml_log_set(_callable!.nativeFunction, ffi.nullptr);
      llama_log_set(_callable!.nativeFunction, ffi.nullptr);
      debugPrint('[TtsNativeLog] ggml/llama 原生日志回调已注册');
    } catch (e) {
      debugPrint('[TtsNativeLog] 注册失败（不影响功能）：$e');
    }
  }
}
