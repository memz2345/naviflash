                                           
  
                             
  
                                                                
                                                       
                                      
                              
  
                                                        
                      
  
                                                       
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

                
class ModelDownloadFile {
           
  final String url;

                                             
  final String path;

                              
  final int bytes;

                 
  final String name;

  const ModelDownloadFile({
    required this.url,
    required this.path,
    required this.bytes,
    required this.name,
  });

  Map<String, Object?> toMap() => {
    'url': url,
    'path': path,
    'bytes': bytes,
    'name': name,
  };
}

                
class ModelDownloadStatus {
  final bool running;
  final int received;
  final int total;
  final String name;

  const ModelDownloadStatus({
    required this.running,
    required this.received,
    required this.total,
    required this.name,
  });
}

abstract final class ModelDownloadService {
  static const MethodChannel _channel = MethodChannel(
    'com.memz2345.navi.flash/model_download',
  );

  static bool _attached = false;

                        
  static bool get supported => !kIsWeb && Platform.isAndroid;

                                                  
  static void Function(int received, int total, int percent, String name)?
  onProgress;

                       
  static void Function(List<String> paths)? onComplete;

                           
  static void Function(String message)? onError;

               
  static void Function()? onCanceled;

                                           
  static void attach() {
    if (_attached || !supported) return;
    _attached = true;
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static Future<dynamic> _handleNativeCall(MethodCall call) async {
    final args = call.arguments;
    final map = args is Map ? args.cast<String, Object?>() : <String, Object?>{};
    switch (call.method) {
      case 'onProgress':
        onProgress?.call(
          _asInt(map['received']),
          _asInt(map['total']),
          _asInt(map['percent']),
          map['name'] as String? ?? '',
        );
        break;
      case 'onComplete':
        final raw = map['paths'];
        onComplete?.call(
          raw is List ? raw.map((e) => '$e').toList() : const <String>[],
        );
        break;
      case 'onError':
        onError?.call(map['message'] as String? ?? '下载失败');
        break;
      case 'onCanceled':
        onCanceled?.call();
        break;
      default:
        break;
    }
    return null;
  }

                                                
  static Future<bool> start({
    required String title,
    required List<ModelDownloadFile> files,
  }) async {
    if (!supported || files.isEmpty) return false;
    attach();
    try {
      await _channel.invokeMethod<bool>('start', {
        'title': title,
        'files': files.map((f) => f.toMap()).toList(growable: false),
      });
      return true;
    } catch (e) {
      debugPrint('[ModelDownload] 启动原生下载失败: $e');
      return false;
    }
  }

                                     
  static Future<void> cancel() async {
    if (!supported) return;
    try {
      await _channel.invokeMethod('cancel');
    } catch (e) {
      debugPrint('[ModelDownload] 取消失败: $e');
    }
  }

                                  
  static Future<ModelDownloadStatus?> status() async {
    if (!supported) return null;
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>('status');
      if (raw == null) return null;
      final map = raw.cast<String, Object?>();
      return ModelDownloadStatus(
        running: map['running'] as bool? ?? false,
        received: _asInt(map['received']),
        total: _asInt(map['total']),
        name: map['name'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  static int _asInt(Object? v) => switch (v) {
    final int i => i,
    final num n => n.toInt(),
    _ => 0,
  };
}
