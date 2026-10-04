                                            
  
         
                                                
                                               
                                    
                   
                                                    
                                                                        
                        
                                                 
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

                                         
                                    
  void _onChangeAppLanguage(
    SettingsService settings,
    BilibiliTranslateService translate,
    String? code,
  ) {
    AppLocaleService.applyInAppChoice(code);
    if (code == null) return;
                                                       
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
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
        body: Stack(
          children: [
            PageBackground(baseColor: colorScheme.surfaceContainer),
            CustomScrollView(
              physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),                                                  
              slivers: [
                ExpressiveSliverAppBar(
                  title: l10n.settingsLanguage,
                  expandedHeight: 152,
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
                              child: RadioGroup<String>(
                                groupValue: settings.appLocaleCode ?? 'system',
                                onChanged: (value) {
                                  if (value == null) return;
                                  HapticFeedback.lightImpact();
                                  _onChangeAppLanguage(
                                    settings,
                                    service,
                                    value == 'system' ? null : value,
                                  );
                                },
                                child: RadioListTile<String>(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  title: Text(
                                    opt.label,
                                    style: TextStyle(
                                      fontWeight:
                                          (settings.appLocaleCode ??
                                                      'system') ==
                                                  opt.code
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                  ),
                                  value: opt.code,
                                  activeColor: colorScheme.primary,
                                ),
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
                              child: RadioGroup<BiliTranslateLanguage>(
                                groupValue: service.language,
                                onChanged: (value) {
                                  if (value != null) {
                                    HapticFeedback.lightImpact();
                                    service.setLanguage(value);
                                  }
                                },
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
                                  activeColor: colorScheme.primary,
                                ),
                              ),
                            ),
                        ]),
                        const SizedBox(height: 32),

                                      
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