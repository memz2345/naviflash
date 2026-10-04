                                      
  
                                     
                                         
                                                  
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/page_background.dart';
import '../widgets/tts_dependency_section.dart';
import '../widgets/widgets.dart';

class TtsInstallScreen extends StatelessWidget {
  const TtsInstallScreen({super.key, this.isSplitView = false, this.onBack});

  final bool isSplitView;
  final VoidCallback? onBack;

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
              physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                ExpressiveSliverAppBar(
                  title: l10n.ttsInstallPageTitle,
                  expandedHeight: 152,
                  leading: isSplitView
                      ? null
                      : MorphIconButton(
                          tooltip: l10n.commonBackTooltip,
                          icon: Icons.arrow_back,
                          onTap: () => _handleBack(context),
                        ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 40),
                                          
                  sliver: SliverToBoxAdapter(
                    child: TtsDependencySection(autoStart: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
