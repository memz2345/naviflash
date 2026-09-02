// lib/services/webview_cookie_service.dart
//
// 内置浏览器（BrowserPage 的 webview）Cookie 清理服务：
//   - Windows（webview_windows / WebView2）：Cookie 按 WebView2 用户数据目录
//     （%LOCALAPPDATA%\flutter_webview_windows\<exe名>）环境级共享。
//     优先用存活控制器实例调用 clearCookies 清除；无论浏览器是否打开，
//     都再兜底删除用户数据目录中的 Cookie 存储文件（Network / Local
//     Storage / Session Storage 等），保证退出登录时残留登录态真正清掉。
//   - Android / iOS / macOS（webview_flutter）：直接用全局
//     WebViewCookieManager().clearCookies()。
// 用途：退出 B 站账号时可选同步清空浏览器 Cookie，防止网页端登录态残留。
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as win;

class WebviewCookieService {
  WebviewCookieService._();

  /// Windows 端当前存活的 WebView 控制器（由 BrowserPage 注册/注销）。
  static win.WebviewController? windowsController;

  /// 注册/注销 Windows WebView 控制器（BrowserPage 生命周期内调用）。
  static void registerWindowsController(win.WebviewController? controller) {
    windowsController = controller;
  }

  /// 清空内置浏览器全部 Cookie。
  /// 返回 true 表示已执行清理；false 表示没有可清理的内容或清理失败。
  static Future<bool> clearAllCookies() async {
    try {
      if (Platform.isWindows) {
        var cleared = false;
        // ① 浏览器实例存活时，直接用 WebView2 API 清除当前 profile 的 Cookie
        final controller = windowsController;
        if (controller != null) {
          await controller.clearCookies();
          cleared = true;
        }
        // ② 兜底：删除用户数据目录中的 Cookie 存储（浏览器已关闭时也生效）
        final dir = _windowsDataDir();
        if (dir != null && dir.existsSync()) {
          for (final name in ['Network', 'Local Storage', 'Session Storage']) {
            final sub = Directory('${dir.path}\\$name');
            if (sub.existsSync()) {
              try {
                sub.deleteSync(recursive: true);
                cleared = true;
              } catch (e) {
                // 浏览器实例仍存活时文件可能被锁定，忽略
                debugPrint('[WebviewCookie] 删除 $name 失败: $e');
              }
            }
          }
          // 兜底：删除目录下所有 Cookies* 文件（旧版结构等）
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
      // Android / iOS / macOS：webview_flutter 全局 CookieManager
      await WebViewCookieManager().clearCookies();
      return true;
    } catch (e) {
      debugPrint('[WebviewCookie] 清空 Cookie 失败: $e');
      return false;
    }
  }

  /// 定位 WebView2 用户数据目录：
  /// %LOCALAPPDATA%\flutter_webview_windows\<exe 文件名去掉扩展名>
  /// （与 webview_windows 原生 GetDefaultDataDirectory 一致）。
  /// 目录不存在时回退到该根目录下最近修改的子目录。
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
