                                           
  
                                           
                                                                   
                                                            
                                              
                                                 
                                                     
                                                   
                                             
                                           
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as win;

class WebviewCookieService {
  WebviewCookieService._();

                                                      
  static win.WebviewController? windowsController;

                                                     
  static void registerWindowsController(win.WebviewController? controller) {
    windowsController = controller;
  }

                       
                                            
  static Future<bool> clearAllCookies() async {
    try {
      if (Platform.isWindows) {
        var cleared = false;
                                                            
        final controller = windowsController;
        if (controller != null) {
          await controller.clearCookies();
          cleared = true;
        }
                                                
        final dir = _windowsDataDir();
        if (dir != null && dir.existsSync()) {
          for (final name in ['Network', 'Local Storage', 'Session Storage']) {
            final sub = Directory('${dir.path}\\$name');
            if (sub.existsSync()) {
              try {
                sub.deleteSync(recursive: true);
                cleared = true;
              } catch (e) {
                                      
                debugPrint('[WebviewCookie] 删除 $name 失败: $e');
              }
            }
          }
                                          
          for (final entity in dir.listSync(recursive: true)) {
            if (entity is File &&
                entity.path.toLowerCase().contains('cookie')) {
              try {
                entity.deleteSync();
                cleared = true;
              } catch (_) {}
            }
          }
        }
        return cleared;
      }
                                                               
      await WebViewCookieManager().clearCookies();
      return true;
    } catch (e) {
      debugPrint('[WebviewCookie] 清空 Cookie 失败: $e');
      return false;
    }
  }

                         
                                                           
                                                        
                             
  static Directory? _windowsDataDir() {
    try {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData == null || localAppData.isEmpty) return null;
      final root = Directory('$localAppData\\flutter_webview_windows');
      if (!root.existsSync()) return null;

      final exe = File(Platform.resolvedExecutable).uri.pathSegments.last;
      final stem = exe.toLowerCase().endsWith('.exe')
          ? exe.substring(0, exe.length - 4)
          : exe;
      final exact = Directory('${root.path}\\$stem');
      if (exact.existsSync()) return exact;

      final dirs = root.listSync().whereType<Directory>().toList()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return dirs.isEmpty ? null : dirs.first;
    } catch (e) {
      debugPrint('[WebviewCookie] 定位用户数据目录失败: $e');
      return null;
    }
  }
}
