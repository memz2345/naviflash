                                            
  
                            
                                          
            

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:naviflash/widgets/app_toast.dart';
import '../services/oss_license_service.dart';
import '../widgets/expressive_app_bar.dart';
import '../widgets/morph_card.dart';
import '../widgets/page_background.dart';
import '../l10n/app_localizations.dart';

class OssPackageLicensePage extends StatelessWidget {
  final OssPackage package;

  const OssPackageLicensePage({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final count = package.licenses.length;

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
                title: package.name,
                expandedHeight: 152,
                leading: MorphIconButton(
                  tooltip: l10n.ossBackTooltip,
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).pop(),
                ),
                actions: [
                  MorphIconButton(
                    tooltip: l10n.ossCopyFullText,
                    icon: Icons.copy_rounded,
                    onTap: () => _copyAll(context, l10n),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList.builder(
                  itemCount: count,
                  itemBuilder: (context, index) => Padding(
                                                     
                                                           
                                  
                    padding: EdgeInsets.only(
                      bottom: index == count - 1 ? 0 : kCardGap,
                    ),
                    child: _buildLicenseCard(context, cs, l10n, index, count),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyAll(BuildContext context, AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: package.fullText));
    if (!context.mounted) return;
    showAppToast(context, l10n.ossLicenseCopied);
  }

               
  Widget _buildLicenseCard(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    int index,
    int count,
  ) {
    final paragraphs = package.licenses[index];
    final multi = count > 1;

    return MorphItem(
      selected: false,
      isFirst: index == 0,
      isLast: index == count - 1,
      interactive: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (multi) ...[
              Text(
                l10n.ossLicenseIndex(index + 1, count),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
            ],
            for (final paragraph in paragraphs)
              Padding(
                padding: EdgeInsets.only(
                  left: paragraph.indent * 16.0,
                  top: 5,
                  bottom: 5,
                ),
                child: SelectableText(
                  paragraph.text,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.6,
                    color: cs.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
