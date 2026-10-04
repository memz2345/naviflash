                                      
  
                                   
                                           
                                           
                                     
  
                                     
                                       
                  
import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/storage_paths.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/onnx_dependency_section.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/storage_location_section.dart';
import 'package:naviflash/widgets/tts_dependency_section.dart';

class AiSettingsScreen extends StatelessWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const AiSettingsScreen({super.key, this.isSplitView = false, this.onBack});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainerLow),
          ScrollConfiguration(
            behavior: const MaterialScrollBehavior(),
            child: CustomScrollView(
              slivers: [
                ExpressiveSliverAppBar(
                  title: l10n.settingsAi,
                  expandedHeight: 152,
                  leading: isSplitView
                      ? null
                      : MorphIconButton(
                          tooltip: l10n.startScreenGoBack,
                          icon: Icons.arrow_back,
                          onTap: onBack ?? () => Navigator.of(context).pop(),
                        ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.settingsAiSub,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 24),
                                                            
                        const OnnxDependencySection(),
                        const SizedBox(height: 24),
                                                     
                                                
                        const TtsDependencySection(),
                        const SizedBox(height: 24),
                        _buildSectionTitle(context, l10n.storageLocationModels),
                        const SizedBox(height: 12),
                                                     
                        const StorageLocationSection(
                          slots: [StorageSlot.models],
                          showTitle: false,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
