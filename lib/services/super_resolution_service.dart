                                             
                                                       
                  
                          
                                                                          
                                                                         
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:media_kit/media_kit.dart' show NativePlayer;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class SuperResolutionService {
  SuperResolutionService._();

  static const String modeDisable = 'disable';
  static const String modeEfficiency = 'efficiency';
  static const String modeQuality = 'quality';

                   
  static const List<String> qualityShaders = [
    'Anime4K_Clamp_Highlights.glsl',
    'Anime4K_Restore_CNN_VL.glsl',
    'Anime4K_Upscale_CNN_x2_VL.glsl',
    'Anime4K_AutoDownscalePre_x2.glsl',
    'Anime4K_AutoDownscalePre_x4.glsl',
    'Anime4K_Upscale_CNN_x2_M.glsl',
  ];

                    
  static const List<String> efficiencyShaders = [
    'Anime4K_Clamp_Highlights.glsl',
    'Anime4K_Restore_CNN_M.glsl',
    'Anime4K_Restore_CNN_S.glsl',
    'Anime4K_Upscale_CNN_x2_M.glsl',
    'Anime4K_AutoDownscalePre_x2.glsl',
    'Anime4K_AutoDownscalePre_x4.glsl',
    'Anime4K_Upscale_CNN_x2_S.glsl',
  ];

  static bool _shadersReady = false;
  static String? _shadersDir;

                                                         
  static Future<String> ensureShadersCopied() async {
    if (_shadersReady && _shadersDir != null) return _shadersDir!;

    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory(path.join(appSupport.path, 'anime_shaders'));

    final shaderNames = <String>{
      ...qualityShaders,
      ...efficiencyShaders,
    };

    try {
      await dir.create(recursive: true);
      for (final name in shaderNames) {
        final target = File(path.join(dir.path, name));
        if (target.existsSync()) continue;
        try {
          final data = await rootBundle.load('assets/anime4k_shaders/$name');
          await target.writeAsBytes(data.buffer.asUint8List(), flush: true);
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ 复制着色器失败 ($name): $e');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 创建着色器目录失败: $e');
    }

    _shadersDir = dir.path;
    _shadersReady = true;
    return dir.path;
  }

                                                        
  static String buildShadersPath(String mode) {
    final List<String> shaders = switch (mode) {
      modeQuality => qualityShaders,
      modeEfficiency => efficiencyShaders,
      _ => const [],
    };
    if (shaders.isEmpty || _shadersDir == null) return '';
    return shaders
        .map((s) => path.join(_shadersDir!, s))
        .join(Platform.isWindows ? ';' : ':');
  }

                        
  static Future<void> apply(NativePlayer platform, String mode) async {
    try {
      if (mode == modeDisable) {
        await platform.setProperty('glsl-shaders', '');
        return;
      }
      if (_shadersDir == null) {
        await ensureShadersCopied();
      }
      final value = buildShadersPath(mode);
      if (value.isEmpty) return;
      await platform.setProperty('glsl-shaders', value);
      if (kDebugMode) debugPrint('✅ 已应用超分辨率着色器: $mode');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 应用超分辨率着色器失败: $e');
    }
  }
}
