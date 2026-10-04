                                         
                                                             
                                                                  
                                         
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'settings_service.dart';

class DisplayModeService {
                                    
  static Future<void> restorePreferred(SettingsService settings) async {
    if (!Platform.isAndroid) return;
    final saved = settings.displayMode;
    if (saved == null || saved.isEmpty) return;
    try {
      final modes = await FlutterDisplayMode.supported;
      for (final mode in modes) {
        if (mode.toString() == saved) {
          await FlutterDisplayMode.setPreferredMode(mode);
          if (kDebugMode) debugPrint('✅ 已恢复屏幕帧率: $saved');
          return;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 恢复屏幕帧率失败: $e');
    }
  }

                                                                 
                                   
  static String labelOf(String? saved, {required String autoText}) {
    if (saved == null || saved.isEmpty) return autoText;
    if (saved == DisplayMode.auto.toString()) return autoText;
    final match = RegExp(r'(\d+)x(\d+) @ (\d+)Hz').firstMatch(saved);
    if (match == null) return autoText;
    return '${match.group(1)}×${match.group(2)} @ ${match.group(3)}Hz';
  }
}
