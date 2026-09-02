// lib/screens/language_settings_screen.dart
//
// 语言设置页：
//   1. 应用语言：切换 App 界面语言（跟随系统 / 简体中文 / English），
//      同时把 B 站翻译目标语言同步为匹配项（zh→zh-CN，en→en-US）。
//   2. B 站 AI 翻译目标语言（可单独选，不跟随界面语言）。
//   3. 启用 AI 翻译开关。
// 开启 AI 翻译后由 NetworkSettingsService.apiHeaders 把翻译头
// （x-bili-locale-bin / x-bili-metadata-bin / x-bili-device-bin / buvid）
// 合并到所有 B 站请求，返回目标语言内容。
// 使用 ExpressiveSliverAppBar + morph_card 分段卡片布局。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_locale_service.dart';
import '../services/bilibili_translate_service.dart';
import '../services/settings_service.dart';
import '../widgets/widgets.dart';
import '../widgets/page_background.dart';
import '../l10n/app_localizations.dart';

class LanguageSettingsScreen extends StatelessWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const LanguageSettingsScreen({
    super.key,
    this.isSplitView = false,
    this.onBack,
  });

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else {
      Navigator.of(context).pop();
    }
  }

  /// 选择应用界面语言：写入应用内偏好并同步 Android 13+ 系统级
  /// 「按应用设置语言」，同时把 B 站翻译目标语言同步为匹配项。
  void _onChangeAppLanguage(
    SettingsService settings,
    BilibiliTranslateService translate,
    String? code,
  ) {
    AppLocaleService.applyInAppChoice(code);
    if (code == null) return;
    // code 即 BCP-47 标签，与 BiliTranslateLanguage.code 一致
    for (final l in BiliTranslateLanguage.values) {
      if (l.code == code) {
        translate.setLanguage(l);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final service = context.watch<BilibiliTranslateService>();
    final settings = context.watch<SettingsService>();
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: onBack == null,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
        body: Stack(
          children: [
            PageBackground(baseColor: colorScheme.surfaceContainer),
            CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                ExpressiveSliverAppBar(
                  title: l10n.settingsLanguage,
                  expandedHeight: 120,
                  leading: isSplitView
                      ? null
                      : MorphIconButton(
                          tooltip: l10n.netBackTooltip,
                          icon: Icons.arrow_back,
                          onTap: () => _handleBack(context),
                        ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── 应用语言（同时驱动界面语言与 B 站翻译目标） ──
                        _buildSectionTitle(
                          context,
                          l10n.appLangSection,
                        ),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          for (final opt
                              in [
                                (label: l10n.appLangFollowSystem, code: 'system'),
                                (label: l10n.langZhCn, code: 'zh-CN'),
                                (label: l10n.langZhTw, code: 'zh-TW'),
                                (label: l10n.langZhHk, code: 'zh-HK'),
                                (label: l10n.langEnUs, code: 'en-US'),
                              ])
                            MorphRowItem(
                              child: RadioListTile<String>(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                title: Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontWeight:
                                        (settings.appLocaleCode ?? 'system') ==
                                                opt.code
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                value: opt.code,
                                groupValue: settings.appLocaleCode ?? 'system',
                                activeColor: colorScheme.primary,
                                onChanged: (value) {
                                  if (value == null) return;
                                  HapticFeedback.lightImpact();
                                  _onChangeAppLanguage(
                                    settings,
                                    service,
                                    value == 'system' ? null : value,
                                  );
                                },
                              ),
                            ),
                        ]),
                        const SizedBox(height: 32),

                        _buildSectionTitle(
                          context,
                          l10n.biliLangSection,
                        ),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          for (final lang in BiliTranslateLanguage.values)
                            MorphRowItem(
                              child: RadioListTile<BiliTranslateLanguage>(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                title: Text(
                                  _languageLabel(l10n, lang),
                                  style: TextStyle(
                                    fontWeight:
                                        service.language == lang
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  lang.code,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                value: lang,
                                groupValue: service.language,
                                activeColor: colorScheme.primary,
                                onChanged: (value) {
                                  if (value != null) {
                                    HapticFeedback.lightImpact();
                                    service.setLanguage(value);
                                  }
                                },
                              ),
                            ),
                        ]),
                        const SizedBox(height: 32),

                        // ── AI 翻译 ──
                        _buildSectionTitle(context, l10n.biliAiSection),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          MorphRowItem(
                            flashKey: 'ai_translate',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.auto_awesome_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.biliAiTranslateEnable),
                              subtitle: Text(
                                service.enabled
                                    ? l10n.biliAiTranslateOnDesc
                                    : l10n.biliAiTranslateOffDesc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: service.enabled,
                              onChanged: (value) {
                                HapticFeedback.lightImpact();
                                service.setEnabled(value);
                              },
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _languageLabel(
    AppLocalizations l10n,
    BiliTranslateLanguage lang,
  ) {
    switch (lang.code) {
      case 'zh-CN':
        return l10n.langZhCn;
      case 'zh-HK':
        return l10n.langZhHk;
      case 'zh-TW':
        return l10n.langZhTw;
      case 'en-US':
        return l10n.langEnUs;
      case 'ja-JP':
        return l10n.langJaJp;
      case 'ko-KR':
        return l10n.langKoKr;
      default:
        return lang.code;
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}