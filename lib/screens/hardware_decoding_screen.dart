                                            
                                          
                                           
                                 
                                  
                                                            
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:naviflash/services/hwdec_type.dart';
import 'package:naviflash/services/player_settings_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/l10n/app_localizations.dart';

class HardwareDecodingScreen extends StatefulWidget {
  const HardwareDecodingScreen({super.key});

  @override
  State<HardwareDecodingScreen> createState() => _HardwareDecodingScreenState();
}

class _HardwareDecodingScreenState extends State<HardwareDecodingScreen> {
                    
  List<HwDecType> _selectedOf(PlayerSettingsService settings) =>
      HwDecType.parse(settings.hwdecMode);

                                       
  Future<void> _toggle(
    HwDecType opt,
    PlayerSettingsService settings,
  ) async {
    final list = _selectedOf(settings);
    if (list.any((e) => e.hwdec == opt.hwdec)) {
      list.removeWhere((e) => e.hwdec == opt.hwdec);
      if (list.isEmpty) {
        showAppToast(
          context,
          AppLocalizations.of(context).hwdecEmptyWarning,
          error: true,
        );
        return;
      }
    } else {
      list.add(opt);
    }
    await settings.setHwdecMode(list.map((e) => e.hwdec).join(','));
  }

                         
  int? _orderOf(String value, PlayerSettingsService settings) {
    final list = _selectedOf(settings);
    final idx = list.indexWhere((e) => e.hwdec == value);
    return idx < 0 ? null : idx + 1;
  }

                        
  List<HwDecType> _optionsOf(PlayerSettingsService settings) =>
      settings.hwdecOnlySupported
          ? HwDecType.availableOnCurrentPlatform()
          : HwDecType.values;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
                                
    final settings = context.watch<PlayerSettingsService>();

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer),
          CustomScrollView(
            physics: const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              ExpressiveSliverAppBar(
                title: l10n.hwdecPageTitle,
                expandedHeight: 152,
                leading: MorphIconButton(
                  tooltip: l10n.homeBack,
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.hwdecHint,
                        style: TextStyle(color: cs.outline, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ...buildMorphSegmentedList([
                        MorphRowItem(
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            secondary: Icon(
                              Icons.flash_on_outlined,
                              size: 26,
                              color: cs.onSurfaceVariant,
                            ),
                            title: Text(l10n.hwdecEnabled),
                            subtitle: Text(
                              l10n.hwdecEnabledHint,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                            value: settings.hwdecEnabled,
                            onChanged: settings.setHwdecEnabled,
                          ),
                        ),
                        MorphRowItem(
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            secondary: Icon(
                              Icons.filter_alt_outlined,
                              size: 26,
                              color: cs.onSurfaceVariant,
                            ),
                            title: Text(l10n.hwdecOnlySupported),
                            subtitle: Text(
                              l10n.hwdecOnlySupportedHint,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                            value: settings.hwdecOnlySupported,
                            onChanged: settings.setHwdecOnlySupported,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      Text(
                        l10n.hwdecSelectedPrefix(
                          '${_selectedOf(settings).length}',
                        ),
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildOptionList(cs, l10n, settings),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionList(
    ColorScheme cs,
    AppLocalizations l10n,
    PlayerSettingsService settings,
  ) {
    final options = _optionsOf(settings);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      separatorBuilder: (_, __) => const SizedBox(height: kCardGap),
      itemBuilder: (context, index) {
        final opt = options[index];
        final order = _orderOf(opt.hwdec, settings);
        final isSelected = order != null;
        return MorphItem(
          selected: isSelected,
          isFirst: index == 0,
          isLast: index == options.length - 1,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: isSelected
                ? CircleAvatar(
                    radius: 13,
                    backgroundColor: cs.primary,
                    child: Text(
                      '$order',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Icon(
                    Icons.radio_button_unchecked,
                    color: cs.onSurfaceVariant,
                    size: 22,
                  ),
            title: Text(
              opt.hwdec,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              opt.desc,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              _toggle(opt, settings);
            },
          ),
        );
      },
    );
  }
}
