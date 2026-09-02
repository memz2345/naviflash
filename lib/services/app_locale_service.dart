// lib/services/app_locale_service.dart
//
//  Android 13+ (API 33) 「按应用设置语言」双向同步：
//
//   系统页改语言（不用进应用）：
//     用户在「系统设置 → 应用 → 应用信息 → 语言」选择语言后，
//     原生端 onConfigurationChanged 推送变更 → 本服务把标签镜像写入
//     SettingsService.appLocaleCode → MaterialApp.locale 跟随刷新；
//     应用在前台时即时生效，冷启动时启动同步保证一致。
//
//   应用内改语言：
//     语言设置页选择 → [applyInAppChoice] 同时写应用内偏好与系统
//     LocaleManager，两边始终一致，系统页会显示当前选择。
//
//   Android 13 以下：getSystemAppLocales 返回 null，
//   自动退化为仅应用内偏好（SharedPreferences），行为与旧版本相同。
//
//   首次升级迁移：系统级为空而应用内已有偏好（旧版本用户的选择）时，
//   启动一次性把偏好推送到系统级，避免清掉用户此前的语言选择。
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'lnative_bridge.dart';
import 'settings_service.dart';

class AppLocaleService with WidgetsBindingObserver {
  AppLocaleService._();

  static final AppLocaleService instance = AppLocaleService._();

  SettingsService? _settings;

  /// 在 main() 里 SettingsService.initialize() 之后调用一次。
  static Future<void> attach(SettingsService settings) async {
    final s = instance;
    s._settings = settings;
    if (!Platform.isAndroid) return;
    WidgetsBinding.instance.addObserver(s);
    NativeBridge.setOnAppLocalesChangedListener(s._onSystemLocalesChanged);
    await s._syncFromSystem(migrate: true);
  }

  /// 应用内语言选择入口：同时写应用内偏好与（Android 13+）系统级设置。
  /// [code] 为 BCP-47 标签（'zh-CN' / 'zh-TW' / 'zh-HK' / 'en-US'），
  /// 传 null 表示「跟随系统」。
  static Future<void> applyInAppChoice(String? code) async {
    final settings = instance._settings;
    if (settings == null) {
      debugPrint('AppLocaleService 尚未 attach，忽略语言选择: $code');
      return;
    }
    await settings.setAppLocaleCode(code);
    if (Platform.isAndroid) {
      await NativeBridge.setSystemAppLocale(code);
    }
  }

  /// 用户回到前台时重新对齐（系统页改语言时 Activity 可能只收到延迟的配置更新）。
  Future<void> resync() => _syncFromSystem(migrate: false);

  void _onSystemLocalesChanged(List<String> tags) {
    // 空列表 = 用户在系统页选了「跟随系统」→ 也要同步清掉应用内偏好，
    // 因此走完整 _syncFromSystem 而不是只处理非空标签
    resync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resync();
    }
  }

  /// 与系统级语言对齐。[migrate] 为 true 时（仅启动首次）允许把旧版
  /// 应用内偏好推送到系统级；之后系统级永远是权威来源，
  /// 系统级为空即视为用户选择了「跟随系统」。
  Future<void> _syncFromSystem({required bool migrate}) async {
    final settings = _settings;
    if (settings == null) return;
    final tags = await NativeBridge.getSystemAppLocales();
    if (tags == null) return; // 系统不支持（Android < 13）
    if (tags.isEmpty) {
      final code = settings.appLocaleCode;
      if (code == null) return;
      if (migrate) {
        // 旧版本用户已选过语言，但系统级还是空 → 迁移，尊重历史选择
        await NativeBridge.setSystemAppLocale(code);
      } else {
        // 用户明确在系统页选了「跟随系统」
        await settings.setAppLocaleCode(null);
      }
      return;
    }
    _applySystemTags(tags);
  }

  Future<void> _applySystemTags(List<String> tags) async {
    final settings = _settings;
    if (settings == null || tags.isEmpty) return;
    final normalized = normalizeLocaleTag(tags.first);
    if (settings.appLocaleCode != normalized) {
      await settings.setAppLocaleCode(normalized);
    }
  }

  /// 规范化语言标签：系统页只会给出 locales_config 里声明的 4 种，
  /// 这里把未带地区的 zh/en 补全，未知标签原样保留（由 MaterialApp 兜底解析）。
  static String normalizeLocaleTag(String tag) {
    final parts = tag.replaceAll('_', '-').split('-');
    final lang = parts.isNotEmpty ? parts[0].toLowerCase() : '';
    final region = parts.length > 1 ? parts[1].toUpperCase() : null;
    if (lang == 'zh') {
      return switch (region) {
        'TW' => 'zh-TW',
        'HK' => 'zh-HK',
        _ => 'zh-CN',
      };
    }
    if (lang == 'en') return 'en-US';
    return tag;
  }
}
