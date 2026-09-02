// lib/services/settings_search_controller.dart
//
// 设置搜索高亮控制器：搜索页选中结果后，通过静态 ValueNotifier 广播目标
// （页面路由 + 选项 flashKey），目标设置页对应的 MorphItem 收到后
// 自动滚动到可见位置并闪烁数下。
import 'package:flutter/foundation.dart';

/// 搜索跳转目标：目标页面 + 目标选项。
class SettingsSearchTarget {
  /// 单调递增令牌：同一选项重复搜索时每次都是新令牌，保证再次闪烁。
  final int token;

  /// 目标设置页路由（/display、/player、/network、/start-screen…）。
  final String pageRoute;

  /// 目标选项的 flashKey；为 null 时仅跳转页面，不闪烁。
  final String? optionKey;

  /// 页面标题（用于展示）。
  final String pageTitle;

  /// 选项名称（用于展示）。
  final String optionName;

  const SettingsSearchTarget({
    required this.token,
    required this.pageRoute,
    this.optionKey,
    required this.pageTitle,
    required this.optionName,
  });
}

/// 全局搜索高亮控制器（静态单例，无需注入）。
class SettingsSearchController {
  SettingsSearchController._();

  static final ValueNotifier<SettingsSearchTarget?> current =
      ValueNotifier(null);

  static int _seq = 0;

  /// 请求高亮：目标页面挂载后（或已挂载时）对应选项会闪烁。
  static void request({
    required String pageRoute,
    String? optionKey,
    required String pageTitle,
    required String optionName,
  }) {
    current.value = SettingsSearchTarget(
      token: ++_seq,
      pageRoute: pageRoute,
      optionKey: optionKey,
      pageTitle: pageTitle,
      optionName: optionName,
    );
  }

  /// 清除当前高亮目标。
  static void clear() => current.value = null;
}
