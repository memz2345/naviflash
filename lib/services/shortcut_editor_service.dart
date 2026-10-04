                                            
  
                                                  
                                                 
                            
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShortcutEditorService {
  static const _channel =
      MethodChannel('com.memz2345.navi.flash/shortcut_editor');

  static bool get isSupported => Platform.isAndroid;

                                  
  Future<void> open(ColorScheme colorScheme) async {
    if (!isSupported) return;
    final brightness = colorScheme.brightness == Brightness.dark;
    try {
      await _channel.invokeMethod<void>('open', <String, dynamic>{
        'colors': <String, dynamic>{
          'primary': colorScheme.primary.toARGB32(),
          'onSurface': colorScheme.onSurface.toARGB32(),
          'surface': colorScheme.surface.toARGB32(),
          'surfaceContainer': colorScheme.surfaceContainer.toARGB32(),
          'surfaceContainerHigh': colorScheme.surfaceContainerHigh.toARGB32(),
          'onSurfaceVariant': colorScheme.onSurfaceVariant.toARGB32(),
          'outline': colorScheme.outline.toARGB32(),
          'dark': brightness,
        },
      });
    } on PlatformException catch (e) {
      debugPrint('⚠️ 打开快捷菜单编辑页失败: $e');
    } on MissingPluginException {
                          
    }
  }
}
