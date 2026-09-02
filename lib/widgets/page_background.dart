// lib/widgets/page_background.dart
//
// 页面背景图系统：供 expressive_app_bar 布局的页面使用。
// 在页面 body 的 Stack 底部放一个 PageBackground，内容层压在其上。
//
//   - 开启「显示页面背景图」且已设置图片时：先铺主题底色（保证内容
//     可读性与原本观感一致），再叠加裁剪后的背景图（按强度调整不透明度、
//     可选高斯模糊，BoxFit.cover 铺满）；
//   - 关闭 / 未设置时：返回空，页面保持原有 Scaffold 背景（完全不变）。
//
// 用法：
// ```dart
// body: Stack(
//   children: [
//     PageBackground(baseColor: cs.surfaceContainer),
//     CustomScrollView(...),
//   ],
// ),
// ```
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:provider/provider.dart';

class PageBackground extends StatelessWidget {
  /// 背景图下方的主题底色（通常与页面原 Scaffold 背景一致，
  /// 避免开启背景后页面底色突变）；null 时只画背景图本身，
  /// 透出下层内容（供 main.dart 全局层使用）。
  final Color? baseColor;

  const PageBackground({super.key, this.baseColor});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final path = settings.pageBackgroundPath;
    if (!settings.pageBackgroundEnabled ||
        path == null ||
        path.isEmpty ||
        !File(path).existsSync()) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    final opacity = settings.pageBackgroundOpacity.clamp(0.0, 1.0);
    final blur = settings.pageBackgroundBlur.clamp(0.0, 24.0);

    // 背景图（cover 铺满 + 强度 + 可选模糊）
    Widget image = Opacity(
      opacity: opacity,
      child: blur > 0.5
          ? ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: _image(path),
            )
          : _image(path),
    );

    if (baseColor == null) return image;
    return ColoredBox(
      color: baseColor ?? cs.surfaceContainer,
      child: Stack(fit: StackFit.expand, children: [image]),
    );
  }

  Widget _image(String path) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
