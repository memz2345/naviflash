// lib/services/super_resolution_service.dart
//   通过 mpv 的 glsl-shaders 属性加载 Anime4K 着色器，在 GPU 渲染时实时
//   修复 / 放大画面。模式：
//     - disable    ：清除着色器
//     - efficiency ：低性能开销组合（Anime4K_Restore_CNN_M/S + Upscale_CNN_x2_M/S）
//     - quality    ：最佳画质组合（Anime4K_Restore_CNN_VL + Upscale_CNN_x2_VL 等）
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

  /// 画质（最佳效果）着色器组合
  static const List<String> qualityShaders = [
    'Anime4K_Clamp_Highlights.glsl',
    'Anime4K_Restore_CNN_VL.glsl',
    'Anime4K_Upscale_CNN_x2_VL.glsl',
    'Anime4K_AutoDownscalePre_x2.glsl',
    'Anime4K_AutoDownscalePre_x4.glsl',
    'Anime4K_Upscale_CNN_x2_M.glsl',
  ];

  /// 效率（低性能开销）着色器组合
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

  /// 将 assets/shaders 中的 Anime4K 着色器复制到可写目录（仅首次 / 目录缺失时）
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

  /// 按平台分隔符拼接着色器绝对路径（mpv 列表属性分隔符：Windows 用 ';'，其余用 ':'）
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

  /// 向播放器应用 / 清除超分辨率着色器
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
