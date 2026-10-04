                                   
  
                                          
                                                     
                                                        
  
                                   

import 'package:flutter/material.dart';

import 'package:naviflash/services/native_menu_service.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

              
class MoreMenuAction {
  const MoreMenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,

                                
    this.subtitle,

                                            
                                                           
    this.pageKey,

                                             
    this.closeAfter = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? subtitle;
  final String? pageKey;
  final bool closeAfter;

                                  
  bool get opensPage => pageKey != null;
}

                           
class MoreMenuItem extends StatelessWidget {
  const MoreMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.subtitle,
    this.onTap,
    this.dense = true,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: dense,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 22, color: cs.onSurfaceVariant),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

               
   
                                                     
   
                                                                 
                                                            
                                                            
                        
Future<void> showMoreMenuSheet({
  required BuildContext context,
  required List<MoreMenuAction> actions,
  String? title,
  List<MoreMenuAction> Function()? actionsProvider,
}) async {
                                                  
  if (_allNativeMappable(actions)) {
    final nativeOk = await NativeMenuService.showMoreSheet(
      context,
      title: title ?? '',
      items: [for (final a in actions) _nativeItemOf(a)],
      refreshProvider: actionsProvider == null
          ? null
          : () => [for (final a in actionsProvider()) _nativeItemOf(a)],
    );
    if (nativeOk) return;
  }
  if (!context.mounted) return;
  return _showFlutterMoreMenuSheet(
    context: context,
    actions: actions,
    title: title,
  );
}

                             
NativeMenuItem _nativeItemOf(MoreMenuAction a) {
                                                  
  final trailing = a.trailing;
  return NativeMenuItem(
    text: a.label,
    subtitle: a.subtitle,
    icon: a.icon,
    checked: trailing is Icon && trailing.icon == Icons.check,
    closeAfter: a.closeAfter,
    onTap: a.onTap,
  );
}

                                               
bool _allNativeMappable(List<MoreMenuAction> actions) =>
    actions.every((a) => a.trailing == null || a.trailing is Icon);

                                          
   
                                              
                                                         
                         
Future<bool> tryShowNativeMenuSheet(
  BuildContext context, {
  required List<NativeMenuItem> items,
  String title = '',
  List<NativeMenuItem> Function()? refreshProvider,
}) {
  if (items.isEmpty) return Future.value(false);
  return NativeMenuService.showMoreSheet(
    context,
    title: title,
    items: items,
    refreshProvider: refreshProvider,
  );
}

Future<void> _showFlutterMoreMenuSheet({
  required BuildContext context,
  required List<MoreMenuAction> actions,
  String? title,
}) {
  return showAppBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    isScrollControlled: true,
    builder: (sheetCtx) {
      final l10nTitle = title;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (l10nTitle != null) _SheetHeader(title: l10nTitle),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final a in actions)
                      MoreMenuItem(
                        icon: a.icon,
                        label: a.label,
                        trailing: a.trailing,
                        subtitle: a.subtitle,
                        onTap: () {
                          if (a.closeAfter) Navigator.of(sheetCtx).pop();
                          a.onTap();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 6, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
