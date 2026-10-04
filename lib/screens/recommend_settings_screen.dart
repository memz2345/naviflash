                                             
  
                                                                          
             
                     
                               
                                         
                                         
  
                                                                
                                      
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/bilibili_blacklist_service.dart';
import '../services/settings_service.dart';
import '../services/ugc_filter_service.dart';
import 'bilibili_blacklist_page.dart';
import 'ugc_filter_settings_screen.dart'
    show UgcFilterScopeScreen;
import '../widgets/page_background.dart';
import '../widgets/widgets.dart';

class RecommendSettingsScreen extends StatefulWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const RecommendSettingsScreen({
    super.key,
    this.isSplitView = false,
    this.onBack,
  });

  @override
  State<RecommendSettingsScreen> createState() => _RecommendSettingsScreenState();
}

class _RecommendSettingsScreenState extends State<RecommendSettingsScreen> {
  @override
  void initState() {
    super.initState();
                                 
    UgcFilterService.instance.addListener(_onUgcFilterChanged);
                                    
    BilibiliBlacklistService.instance.addListener(_onUgcFilterChanged);
    BilibiliBlacklistService.instance.ensureLoaded();
  }

  @override
  void dispose() {
    UgcFilterService.instance.removeListener(_onUgcFilterChanged);
    BilibiliBlacklistService.instance.removeListener(_onUgcFilterChanged);
    super.dispose();
  }

  void _onUgcFilterChanged() {
    if (mounted) setState(() {});
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsService>();
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
        body: Stack(
          children: [
            PageBackground(baseColor: colorScheme.surfaceContainer),
            CustomScrollView(
              physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                ExpressiveSliverAppBar(
                  title: l10n.settingsRecommend,
                  expandedHeight: 152,
                  leading: widget.isSplitView
                      ? null
                      : MorphIconButton(
                          tooltip: l10n.commonBackTooltip,
                          icon: Icons.arrow_back,
                          onTap: _handleBack,
                        ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                                    
                        _sectionTitle(context, l10n.rcmdSectionSource),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          MorphRowItem(
                            flashKey: 'rcmd_use_app_source',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.model_training_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.rcmdUseAppSource),
                              subtitle: Text(
                                l10n.rcmdUseAppSourceSub,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value:
                                  settings.recommendSource ==
                                  BiliRecommendSource.app,
                              onChanged: (value) {
                                HapticFeedback.lightImpact();
                                settings.setRecommendSource(
                                  value
                                      ? BiliRecommendSource.app
                                      : BiliRecommendSource.web,
                                );
                              },
                            ),
                          ),
                                                             
                          MorphRowItem(
                            flashKey: 'rcmd_guest_mode',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.privacy_tip_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: const Text('游客模式'),
                              subtitle: Text(
                                '推荐请求不携带 Cookie，仅对首页推荐生效',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.recommendGuestMode,
                              onChanged: (value) {
                                HapticFeedback.lightImpact();
                                settings.setRecommendGuestMode(value);
                              },
                            ),
                          ),
                        ]),
                        const SizedBox(height: 24),

                                      
                        _sectionTitle(context, l10n.rcmdSectionBehavior),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          MorphRowItem(
                            flashKey: 'rcmd_keep_last',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.refresh,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.rcmdKeepLastData),
                              subtitle: Text(
                                l10n.rcmdKeepLastDataSub,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.enableSaveLastData,
                              onChanged: (value) {
                                HapticFeedback.lightImpact();
                                settings.setEnableSaveLastData(value);
                              },
                            ),
                          ),
                          MorphRowItem(
                            flashKey: 'rcmd_saved_tip',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.tips_and_updates_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.rcmdSavedPositionTip),
                              subtitle: Text(
                                l10n.rcmdSavedPositionTipSub,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.savedRcmdTip,
                              onChanged: settings.enableSaveLastData
                                  ? (value) {
                                      HapticFeedback.lightImpact();
                                      settings.setSavedRcmdTip(value);
                                    }
                                  : null,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 24),

                                    
                        _sectionTitle(context, l10n.rcmdSectionFilter),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          _selectTile<int>(
                            context,
                            flashKey: 'rcmd_min_like_ratio',
                            icon: Icons.thumb_up_outlined,
                            title: l10n.rcmdMinLikeRatio,
                            subtitle: l10n.rcmdMinLikeRatioSub,
                            value: settings.minLikeRatioForRecommend,
                            options: const [0, 1, 2, 3, 4],
                            labelOf: (v) =>
                                v == 0 ? l10n.rcmdNoFilter : '$v%',
                            onChanged: (v) =>
                                settings.setMinLikeRatioForRecommend(v),
                          ),
                          _selectTile<int>(
                            context,
                            flashKey: 'rcmd_min_duration',
                            icon: Icons.timer_outlined,
                            title: l10n.rcmdMinDuration,
                            subtitle: l10n.rcmdMinDurationSub,
                            value: settings.minDurationForRcmd,
                            options: const [0, 30, 60, 90, 120],
                            labelOf: (v) =>
                                v == 0 ? l10n.rcmdNoFilter : '$v s',
                            onChanged: (v) =>
                                settings.setMinDurationForRcmd(v),
                          ),
                          _selectTile<int>(
                            context,
                            flashKey: 'rcmd_min_play',
                            icon: Icons.play_circle_outline,
                            title: l10n.rcmdMinPlay,
                            subtitle: l10n.rcmdMinPlaySub,
                            value: settings.minPlayForRcmd,
                            options: const [0, 50, 100, 500, 1000],
                            labelOf: (v) =>
                                v == 0 ? l10n.rcmdNoFilter : '$v',
                            onChanged: (v) => settings.setMinPlayForRcmd(v),
                          ),
                                                            
                                                         
                          _scopeEntryTile(
                            context,
                            flashKey: 'rcmd_ban_word',
                            icon: Icons.filter_alt_outlined,
                            title: l10n.rcmdBanWord,
                            subtitle: l10n.rcmdBanWordSub,
                            scope: UgcFilterScope.recommend,
                          ),
                          _scopeEntryTile(
                            context,
                            flashKey: 'rcmd_ban_zone',
                            icon: Icons.category_outlined,
                            title: l10n.rcmdBanZone,
                            subtitle: l10n.rcmdBanZoneSub,
                            scope: UgcFilterScope.zone,
                          ),
                          MorphRowItem(
                            flashKey: 'rcmd_exempt_followed',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.favorite_border_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.rcmdExemptFollowed),
                              subtitle: Text(
                                l10n.rcmdExemptFollowedSub,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.exemptFilterForFollowed,
                              onChanged: (value) {
                                HapticFeedback.lightImpact();
                                settings.setExemptFilterForFollowed(value);
                              },
                            ),
                          ),
                          MorphRowItem(
                            flashKey: 'rcmd_filter_related',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.explore_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.rcmdFilterRelated),
                              subtitle: Text(
                                l10n.rcmdFilterRelatedSub,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.applyFilterToRelatedVideos,
                              onChanged: (value) {
                                HapticFeedback.lightImpact();
                                settings.setApplyFilterToRelatedVideos(value);
                              },
                            ),
                          ),
                                                          
                          MorphRowItem(
                            flashKey: 'rcmd_filter_blacklist',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.block_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: const Text('推荐屏蔽黑名单用户视频'),
                              subtitle: Text(
                                BilibiliBlacklistService.instance.canUse
                                    ? '黑名单缓存 ${BilibiliBlacklistService.instance.cachedCount} 人'
                                    : '登录后才会拉取黑名单',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: BilibiliBlacklistService
                                  .instance
                                  .isFilterRecommend,
                              onChanged: (value) {
                                HapticFeedback.lightImpact();
                                BilibiliBlacklistService.instance
                                    .setFilterRecommend(value);
                              },
                            ),
                          ),
                                            
                          MorphRowItem(
                            flashKey: 'rcmd_blacklist_entry',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.person_off_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: const Text('黑名单管理'),
                              subtitle: Text(
                                '查看已拉黑用户、取消拉黑',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const BilibiliBlacklistPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ]),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            l10n.rcmdFilterHint,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
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

                                        
  MorphRowItem _scopeEntryTile(
    BuildContext context, {
    required String flashKey,
    required IconData icon,
    required String title,
    required String subtitle,
    required UgcFilterScope scope,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return MorphRowItem(
      flashKey: flashKey,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: Icon(icon, size: 26, color: colorScheme.onSurfaceVariant),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.ugcFilterRulesCount(
                UgcFilterService.instance.countOf(scope),
              ),
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UgcFilterScopeScreen(scope: scope),
            ),
          );
        },
      ),
    );
  }

                     
  MorphRowItem _selectTile<T>(
    BuildContext context, {
    required String flashKey,
    required IconData icon,
    required String title,
    required String subtitle,
    required T value,
    required List<T> options,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return MorphRowItem(
      flashKey: flashKey,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: Icon(icon, size: 26, color: colorScheme.onSurfaceVariant),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        trailing: MorphGlassDropdown<T>(
          value: options.contains(value) ? value : options.first,
          items: [
            for (final o in options)
              DropdownMenuItem<T>(value: o, child: Text(labelOf(o))),
          ],
          onChanged: (v) {
            if (v == null) return;
            HapticFeedback.lightImpact();
            onChanged(v);
          },
        ),
      ),
    );
  }



  Widget _sectionTitle(BuildContext context, String title) => Text(
    title,
    textAlign: TextAlign.left,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}
