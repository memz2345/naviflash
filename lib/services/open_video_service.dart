                                       
                         
                                        
                                       
                                                       
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

             
class OpenVideoRequest {
  final String path;           
  final String? name;             
  const OpenVideoRequest({required this.path, this.name});
}

class OpenVideoService {
  OpenVideoService._();

  static const MethodChannel _channel =
      MethodChannel('com.memz2345.navi.flash/open_video');

  static void Function(OpenVideoRequest request)? _onVideoIntent;

                              
  static Future<OpenVideoRequest?> consumePending() async {
    try {
      final data = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('consumePendingVideo');
      if (data == null) return null;
      final path = data['path'] as String?;
      if (path == null || path.isEmpty) return null;
      return OpenVideoRequest(
        path: path,
        name: data['name'] as String?,
      );
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('consumePendingVideo 失败: ${e.message}');
      return null;
    } on MissingPluginException {
                     
      return null;
    }
  }

                                   
  static void setOnVideoIntent(void Function(OpenVideoRequest) listener) {
    _onVideoIntent = listener;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onVideoIntent') {
        final args = call.arguments as Map<dynamic, dynamic>?;
        final path = args?['path'] as String?;
        if (path == null || path.isEmpty || _onVideoIntent == null) return;
        if (!File(path).existsSync()) return;
        _onVideoIntent!(
          OpenVideoRequest(path: path, name: args?['name'] as String?),
        );
      }
    });
  }

                                                           
                                                       
                                    
                               

                                   
                                             
  static Future<bool> registerFileAssociations({bool asDefault = false}) async {
    try {
      final ok = await _channel.invokeMethod<bool>(
        'registerFileAssociations',
        <String, dynamic>{'asDefault': asDefault},
      );
      return ok ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('注册文件关联失败: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

                                    
  static Future<bool> unregisterFileAssociations() async {
    try {
      final ok = await _channel
          .invokeMethod<bool>('unregisterFileAssociations');
      return ok ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('注销文件关联失败: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

                         
  static Future<bool> isFileAssociationRegistered() async {
    try {
      final ok = await _channel
          .invokeMethod<bool>('isFileAssociationRegistered');
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

                               
  static Future<bool> openPaths(List<String> paths) async {
    if (paths.isEmpty) return false;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'openPaths',
        paths,
      );
      return ok ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('打开视频失败: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

                                           
  static Future<void> finishExternalSession() async {
    try {
      await _channel.invokeMethod<void>('finishExternalSession');
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('finishExternalSession 失败: ${e.message}');
    } on MissingPluginException {
                     
    }
  }
}
