                                            
  
                            
                                                 
                                  
  
                                                   
                                         
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_favorite_service.dart';
import 'package:naviflash/services/native_menu_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/more_menu_sheet.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

                       
   
                                 
                                     
   
                                                 
                                                
Future<BiliFavFolder?> showFavWidgetFolderPicker(BuildContext context) async {
  if (Platform.isAndroid && NativeMenuService.enabled) {
    final (handled, folder) = await _tryNativePick(context);
    if (handled || !context.mounted) return folder;
  }
  return showAppBottomSheet<BiliFavFolder>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FavWidgetFolderPicker(),
  );
}

                                
                                                            
Future<(bool, BiliFavFolder?)> _tryNativePick(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final folders = await BilibiliFavoriteService.fetchFolders();
  if (folders == null || folders.isEmpty || !context.mounted) {
    return (false, null);
  }
                                         
  final saved = SettingsService.favWidgetFolderIdStatic;
  final hasSaved = folders.any((f) => f.id == saved);
  final currentId = hasSaved ? saved : folders.first.id;
  BiliFavFolder? picked;
  final ok = await tryShowNativeMenuSheet(
    context,
    title: l10n.favWidgetPickTitle,
    items: [
      for (final folder in folders)
        NativeMenuItem(
          text: folder.title,
          subtitle:
              '${folder.mediaCount} 个内容 · ${folder.isPublic ? '公开' : '私密'}',
          icon: folder.isPublic ? Icons.folder_outlined : Icons.lock_outline,
          checked: folder.id == currentId,
          onTap: () => picked = folder,
        ),
    ],
  );
  return (ok, picked);
}

class _FavWidgetFolderPicker extends StatefulWidget {
  const _FavWidgetFolderPicker();

  @override
  State<_FavWidgetFolderPicker> createState() => _FavWidgetFolderPickerState();
}

class _FavWidgetFolderPickerState extends State<_FavWidgetFolderPicker> {
  List<BiliFavFolder>? _folders;
  bool _loading = true;
  String? _error;

                                
  int? _currentId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
                                          
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    final folders = await BilibiliFavoriteService.fetchFolders();
    if (!mounted) return;
    if (folders == null) {
      setState(() {
        _loading = false;
        _error =
            BilibiliFavoriteService.lastErrorDetail ?? l10n.commonRetry;
      });
      return;
    }
                                           
    final saved = SettingsService.favWidgetFolderIdStatic;
    final hasSaved = folders.any((f) => f.id == saved);
    setState(() {
      _folders = folders;
      _loading = false;
      _currentId = folders.isEmpty ? null : (hasSaved ? saved : folders.first.id);
    });
  }

  void _pick(BiliFavFolder folder) {
    Navigator.of(context).pop(folder);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return SafeArea(
      child: FrostedSheet(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          height: maxHeight,
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                     
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    Icon(Icons.widgets_outlined, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.favWidgetPickTitle,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            l10n.favWidgetPickHint,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              Expanded(child: _buildBody(cs)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) {
      return const Center(child: LoadingIndicatorM3E());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppLocalizations.of(context).commonRetry),
            ),
          ],
        ),
      );
    }
    final folders = _folders ?? const <BiliFavFolder>[];
    if (folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined,
                size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context).favWidgetPickHint,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: folders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final folder = folders[index];
        final selected = folder.id == _currentId;
        return MorphItem(
          selected: false,
          isFirst: true,
          isLast: true,
          interactive: true,
          child: ListTile(
            onTap: () => _pick(folder),
            leading: Icon(
              folder.isPublic ? Icons.folder_outlined : Icons.lock_outline,
              size: 26,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            title: Text(
              folder.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? cs.primary : null,
              ),
            ),
            subtitle: Text(
              '${folder.mediaCount} 个内容 · ${folder.isPublic ? '公开' : '私密'}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: selected
                ? Icon(Icons.check_circle, size: 22, color: cs.primary)
                : null,
          ),
        );
      },
    );
  }
}
