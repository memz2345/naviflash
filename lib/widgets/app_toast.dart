// lib/widgets/app_toast.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:naviflash/services/lnative_bridge.dart';

/// 全局统一「纯提示」入口：
/// - Android：走平台原生 Toast（MethodChannel `com.memz2345.navi.flash/toast`）
/// - 其他平台：回退为 floating SnackBar（统一样式，桌面端限制宽度）
///
/// 需要操作按钮（如「点击操作按钮进入账户设置」）的提示不要用本函数，
/// 请继续直接使用 SnackBar + SnackBarAction。
void showAppToast(BuildContext context, String message, {bool error = false}) {
  if (Platform.isAndroid) {
    NativeBridge.showToast(message);
    return;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final cs = Theme.of(context).colorScheme;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? cs.error : cs.inverseSurface,
        duration: const Duration(seconds: 2),
        width:
            Platform.isWindows || Platform.isLinux || Platform.isMacOS
                ? 400.0
                : null,
      ),
    );
}
