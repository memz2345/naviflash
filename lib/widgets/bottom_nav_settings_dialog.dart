                                              
  
                                       
                                      
                                
                               
                      
                                              
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/src/custom_icons.dart';
import 'package:naviflash/widgets/app_toast.dart';

                                          
Future<void> showBottomNavSettingsDialog(BuildContext context) async {
  SettingsService? settings;
  try {
    settings = context.read<SettingsService>();
  } catch (_) {
    return;
  }
  final l10n = AppLocalizations.of(context);

  var order = List<String>.of(settings.bottomNavOrder);
  var searchOn = settings.bottomBarSearch;
  var useM3 = settings.useM3BottomBar;

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(l10n.bottomNavSettingsTitle),
          contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          content: SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      l10n.bottomNavSettingsSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                                           
                  for (final id in SettingsService.kAllBottomNavIds)
                    bottomNavSettingRow(
                      ctx,
                      id: id,
                      l10n: l10n,
                      order: order,
                      onChanged: (next) => setDialogState(() => order = next),
                    ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: Icon(
                      Icons.search_outlined,
                      color: cs.onSurfaceVariant,
                    ),
                    title: Text(l10n.prefBottomBarSearch),
                    value: searchOn,
                    onChanged: (v) => setDialogState(() => searchOn = v),
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: Icon(
                      Icons.dock_outlined,
                      color: cs.onSurfaceVariant,
                    ),
                    title: Text(l10n.prefUseM3BottomBar),
                    value: useM3,
                    onChanged: (v) => setDialogState(() => useM3 = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => setDialogState(() {
                order = List.of(SettingsService.kDefaultBottomNavOrder);
                searchOn = true;
                useM3 = false;
              }),
              child: Text(l10n.bottomNavSettingsReset),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.commonOk),
            ),
          ],
        );
      },
    ),
  );
  if (saved != true) return;
  await settings.setBottomNavOrder(order);
  await settings.setBottomBarSearch(searchOn);
  await settings.setUseM3BottomBar(useM3);
}

                            
                            
   
                                  
Widget bottomNavSettingRow(
  BuildContext context, {
  required String id,
  required AppLocalizations l10n,
  required List<String> order,
  required ValueChanged<List<String>> onChanged,
}) {
  final cs = Theme.of(context).colorScheme;
  final visible = order.contains(id);
  final index = order.indexOf(id);
  final label = switch (id) {
    'dynamics' => l10n.bottomNavItemDynamics,
    'live' => l10n.bottomNavItemLive,
    'shorts' => l10n.shortsTitle,
    'messages' => l10n.drawerMessages,
    'mine' => l10n.drawerMine,
    _ => l10n.bottomNavItemHome,
  };
  final icon = switch (id) {
    'dynamics' => CustomIcons.motion_photos_on_outlined,
    'live' => Icons.live_tv_outlined,
    'shorts' => Icons.smart_display_outlined,
    'messages' => Icons.forum_outlined,
    'mine' => Icons.person_outline,
    _ => Icons.home_outlined,
  };
  return Row(
    children: [
      Checkbox(
        value: visible,
        onChanged: (v) {
          final next = List<String>.of(order);
          if (v == true) {
            next.add(id);
          } else {
            if (next.length <= 1) {
              showAppToast(context, l10n.bottomNavSettingsKeepOne);
              return;
            }
            next.remove(id);
          }
          onChanged(next);
        },
      ),
      Icon(icon, size: 20, color: visible ? cs.primary : cs.onSurfaceVariant),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: visible ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
      ),
      if (visible) ...[
                      
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: index == 0 ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ),
        IconButton(
          onPressed: index > 0
              ? () {
                  final next = List<String>.of(order);
                  next.insert(index - 1, next.removeAt(index));
                  onChanged(next);
                }
              : null,
          tooltip: l10n.bottomNavMoveUp,
          icon: const Icon(Icons.keyboard_arrow_up, size: 20),
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          onPressed: index < order.length - 1
              ? () {
                  final next = List<String>.of(order);
                  next.insert(index + 1, next.removeAt(index));
                  onChanged(next);
                }
              : null,
          tooltip: l10n.bottomNavMoveDown,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          visualDensity: VisualDensity.compact,
        ),
      ],
    ],
  );
}
