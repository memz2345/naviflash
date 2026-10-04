                                         
  
                                  
                      
  
                                              
                                           
                                      
                                    
                          
  
                                                      
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'package:naviflash/services/settings_service.dart';

class WindowStateService with WindowListener {
  WindowStateService._();

  static final WindowStateService instance = WindowStateService._();

                                             
  static const String kWidth = 'windowWidth';
  static const String kHeight = 'windowHeight';
  static const String kMaximized = 'windowMaximized';

                          
  static const double kDefaultWidth = 1024.0;
  static const double kDefaultHeight = 768.0;

  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  SettingsService? _settings;
  Timer? _debounce;
  bool _attached = false;

                           
  static Future<({double width, double height, bool maximized})>
  loadStartupState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (
        width: prefs.getDouble(kWidth) ?? kDefaultWidth,
        height: prefs.getDouble(kHeight) ?? kDefaultHeight,
        maximized: prefs.getBool(kMaximized) ?? false,
      );
    } catch (_) {
      return (
        width: kDefaultWidth,
        height: kDefaultHeight,
        maximized: false,
      );
    }
  }

                            
  void attach(SettingsService settings) {
    if (_attached || !isDesktop) return;
    _attached = true;
    _settings = settings;
    windowManager.addListener(this);
  }

  @override
  void onWindowResize() {
    if (!isDesktop) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _persist);
  }

  @override
  void onWindowMaximize() => _persist();

  @override
  void onWindowUnmaximize() => _persist();

  @override
  void onWindowClose() {
                                     
    _debounce?.cancel();
    _persist();
  }

  @override
  void onWindowRestore() => _persist();

  Future<void> _persist() async {
    if (!isDesktop) return;
    try {
      final maximized = await windowManager.isMaximized();
      final fullscreen = await windowManager.isFullScreen();
      final minimized = await windowManager.isMinimized();
      final prefs = await SharedPreferences.getInstance();
                              
      if (!fullscreen) {
        await prefs.setBool(kMaximized, maximized);
      }
                                       
      if (maximized || fullscreen || minimized) return;
      final size = await windowManager.getSize();
      final w = size.width;
      final h = size.height;
                                         
      if (w < 400 || h < 300) return;
      await prefs.setDouble(kWidth, w);
      await prefs.setDouble(kHeight, h);
                                         
      _settings?.syncWindowSizeFromSystem(w, h);
    } catch (e) {
      if (kDebugMode) debugPrint('[WindowState] 保存窗口状态失败: $e');
    }
  }
}
