                                        
  
                                       
                             
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/link_utils.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/liquid_dom_menu.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/glass_menu_style.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/ugc_selection_area.dart';

                    
                                                   
void showCommentTextMenu(
  BuildContext context, {
  required String copyText,
  Offset? globalPosition,
}) {
                                              
                                     
                                           
  if (globalPosition != null &&
      _nativeSelectionOwns(context, globalPosition)) {
    return;
  }
  final colorScheme = Theme.of(context).colorScheme;
  final screenSize = MediaQuery.of(context).size;
  final l10n = AppLocalizations.of(context);
  const menuWidth = 200.0;
  final link = firstLink(copyText);
  final itemCount = 2 + (link != null ? 1 : 0);
  final menuHeight = itemCount * 46.0 + 16;

  final items = [
    if (link != null)
      _GlassMenuData(
        icon: Icons.open_in_browser,
        text: l10n.scanOpenInBrowser,
        onTap: () => openBiliLinkInApp(context, url: link),
      ),
    _GlassMenuData(
      icon: Icons.copy,
      text: l10n.commentMenuCopy,
      onTap: () => copyCommentText(context, copyText),
    ),
    _GlassMenuData(
      icon: Icons.select_all,
      text: l10n.commentMenuSelectText,
      onTap: () => _showSelectableCommentDialog(context, copyText),
    ),
  ];
  showLiquidDomMenu(
    context,
    globalPosition:
        globalPosition ?? Offset(screenSize.width / 2, screenSize.height / 2),
    menuWidth: menuWidth,
    menuHeight: menuHeight,
    builder: (_, close) =>
        _GlassCommentMenu(colorScheme: colorScheme, items: items, close: close),
  );
}

                                              
bool _nativeSelectionOwns(BuildContext context, Offset globalPosition) {
  if (!UgcSelectionArea.enabled) return false;
  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(
    result,
    globalPosition,
    View.of(context).viewId,
  );
  for (final entry in result.path) {
    if (entry.target is RenderParagraph) return true;
  }
  return false;
}

                            
Future<void> copyCommentText(BuildContext context, String content) async {
  await Clipboard.setData(ClipboardData(text: content));
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  showAppToast(context, l10n.scanCopiedToClipboard);
}

                                      
                                    
void showCommentActionsSheet(BuildContext context, {required String copyText}) {
  final l10n = AppLocalizations.of(context);
  final link = firstLink(copyText);
  showFrostedActionSheet(
    context,
    actions: [
                          
      if (link != null)
        GlassMenuAction(
          icon: Icons.open_in_browser,
          text: l10n.scanOpenInBrowser,
          onTap: () => openBiliLinkInApp(context, url: link),
        ),
      GlassMenuAction(
        icon: Icons.copy,
        text: l10n.commentMenuCopy,
        onTap: () => copyCommentText(context, copyText),
      ),
      GlassMenuAction(
        icon: Icons.select_all,
        text: l10n.commentMenuSelectText,
        onTap: () => _showSelectableCommentDialog(context, copyText),
      ),
    ],
  );
}

                                      
void _showSelectableCommentDialog(BuildContext context, String content) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;
      final l10n = AppLocalizations.of(dialogContext);
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          child: StretchableNaviGlass(
            radius: 20.0,
            blur: 14.0,
            stretch: 0.3,
            child: Material(
              color: Colors.transparent,
              type: MaterialType.transparency,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.commentDialogTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.of(dialogContext).size.height * 0.4,
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          content.isEmpty ? l10n.commentDialogEmpty : content,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(l10n.scanClose),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _GlassMenuData {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _GlassMenuData({
    required this.icon,
    required this.text,
    required this.onTap,
  });
}

class _GlassCommentMenu extends StatelessWidget {
  final ColorScheme colorScheme;
  final List<_GlassMenuData> items;
  final VoidCallback close;

  const _GlassCommentMenu({
    required this.colorScheme,
    required this.items,
    required this.close,
  });

  @override
  Widget build(BuildContext context) {
    return GlassMenu(
      colorScheme: colorScheme,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      children: [
        for (final item in items)
          GlassMenuRow(
            colorScheme: colorScheme,
            icon: item.icon,
            label: item.text,
            onTap: () {
              close();
              item.onTap();
            },
          ),
      ],
    );
  }
}
