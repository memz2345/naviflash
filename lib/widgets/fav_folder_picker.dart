                                     
  
                          
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_favorite_service.dart';
import 'package:naviflash/services/native_menu_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/more_menu_sheet.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

                  
                                     
   
                                            
                                                             
                                         
Future<void> showFavFolderPicker(
  BuildContext context, {
  required int aid,
  required String title,
}) async {
  if (Platform.isAndroid && NativeMenuService.enabled) {
    final nativeOk = await _tryNativePicker(context, aid: aid, title: title);
    if (nativeOk || !context.mounted) return;
  }
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FavFolderPicker(aid: aid, title: title),
  );
}

                                         
                                               
Future<bool> _tryNativePicker(
  BuildContext context, {
  required int aid,
  required String title,
}) async {
  final sheetTitle =
      title.isEmpty ? '加入 B 站收藏夹' : '加入 B 站收藏夹 · $title';
  final loaded = await BilibiliFavoriteService.fetchFolders(rid: aid, type: 2);
  if (loaded == null || loaded.isEmpty || !context.mounted) return false;
  var folders = loaded;
  final originalIds = folders
      .where((f) => f.favState == 1)
      .map((f) => f.id)
      .toSet();

  while (true) {
    var done = false;
    var create = false;

    List<NativeMenuItem> build() => [
      for (final folder in folders)
        NativeMenuItem(
          text: folder.title,
          subtitle:
              '${folder.mediaCount} 个内容 · ${folder.isPublic ? '公开' : '私密'}',
          icon: folder.isPublic ? Icons.folder_outlined : Icons.lock_outline,
          checked: folder.favState == 1,
          closeAfter: false,
          onTap: () => _toggleFolder(folders, folder),
        ),
      NativeMenuItem(
        text: '新建收藏夹',
        icon: Icons.create_new_folder_outlined,
        onTap: () => create = true,
      ),
      NativeMenuItem(
        text: '完成',
        icon: Icons.check,
        onTap: () => done = true,
      ),
    ];

    final shown = await tryShowNativeMenuSheet(
      context,
      title: sheetTitle,
      items: build(),
      refreshProvider: build,
    );
    if (!shown || !context.mounted) return shown;
    if (done) {
      await _submitChanges(
        context,
        aid: aid,
        folders: folders,
        originalIds: originalIds,
      );
      return true;
    }
    if (!create) return true;

    final newId = await _createFolderAndGetId(context);
    if (!context.mounted) return true;
    if (newId == null) continue;                 
    final fresh = await BilibiliFavoriteService.fetchFolders(rid: aid, type: 2);
    if (fresh == null || fresh.isEmpty || !context.mounted) return true;
    final idx = fresh.indexWhere((f) => f.id == newId);
    if (idx >= 0) fresh[idx] = _withFavState(fresh[idx], 1);
    folders = fresh;
  }
}

                                                            
void _toggleFolder(List<BiliFavFolder> folders, BiliFavFolder folder) {
  final idx = folders.indexWhere((f) => f.id == folder.id);
  if (idx < 0) return;
  final cur = folders[idx];
  folders[idx] = _withFavState(cur, cur.favState == 1 ? 0 : 1);
}

BiliFavFolder _withFavState(BiliFavFolder f, int favState) => BiliFavFolder(
  id: f.id,
  title: f.title,
  cover: f.cover,
  mediaCount: f.mediaCount,
  attr: f.attr,
  isPublic: f.isPublic,
  favState: favState,
);

                                       
Future<void> _submitChanges(
  BuildContext context, {
  required int aid,
  required List<BiliFavFolder> folders,
  required Set<int> originalIds,
}) async {
  final nowChecked = folders
      .where((f) => f.favState == 1)
      .map((f) => f.id)
      .toSet();
  final addIds = nowChecked.difference(originalIds).toList();
  final delIds = originalIds.difference(nowChecked).toList();
  if (addIds.isEmpty && delIds.isEmpty) return;
  final result = await BilibiliFavoriteService.addVideoToFavorites(
    aid: aid,
    addIds: addIds,
    delIds: delIds,
  );
  if (!context.mounted) return;
  showAppToast(
    context,
    result.ok ? '已加入 B 站收藏夹' : '操作失败：${result.message}',
  );
}

                                    
Future<String?> _promptFolderName(BuildContext context) async {
  final controller = TextEditingController();
  final created = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('新建收藏夹'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 20,
        decoration: const InputDecoration(
          hintText: '收藏夹名称',
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(AppLocalizations.of(ctx).commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim().isNotEmpty),
          child: const Text('创建'),
        ),
      ],
    ),
  );
  if (created != true) return null;
  final name = controller.text.trim();
  return name.isEmpty ? null : name;
}

                                    
Future<int?> _createFolderAndGetId(BuildContext context) async {
  final name = await _promptFolderName(context);
  if (name == null || !context.mounted) return null;
  final result = await BilibiliFavoriteService.createFolder(title: name);
  if (!context.mounted) return null;
  if (!result.ok) {
    showAppToast(context, '创建失败：${result.message}');
    return null;
  }
  return result.mediaId;
}

class _FavFolderPicker extends StatefulWidget {
  final int aid;
  final String title;

  const _FavFolderPicker({required this.aid, required this.title});

  @override
  State<_FavFolderPicker> createState() => _FavFolderPickerState();
}

class _FavFolderPickerState extends State<_FavFolderPicker> {
  List<BiliFavFolder>? _folders;
  bool _loading = true;
  String? _error;
  bool _submitting = false;

                                
  late final Set<int> _originalIds = _folders == null
      ? <int>{}
      : _folders!
          .where((f) => f.favState == 1)
          .map((f) => f.id)
          .toSet();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final folders = await BilibiliFavoriteService.fetchFolders(
      rid: widget.aid,
      type: 2,
    );
    if (!mounted) return;
    if (folders == null) {
      setState(() {
        _loading = false;
        _error = BilibiliFavoriteService.lastErrorDetail ?? '加载失败';
      });
      return;
    }
    setState(() {
      _folders = folders;
      _loading = false;
    });
  }

  void _toggle(BiliFavFolder folder, bool checked) {
    setState(() {
      final list = _folders!;
      final idx = list.indexWhere((f) => f.id == folder.id);
      if (idx >= 0) {
        list[idx] = BiliFavFolder(
          id: folder.id,
          title: folder.title,
          cover: folder.cover,
          mediaCount: folder.mediaCount,
          attr: folder.attr,
          isPublic: folder.isPublic,
          favState: checked ? 1 : 0,
        );
      }
    });
  }

  Future<void> _submit() async {
    final folders = _folders;
    if (folders == null || _submitting) return;
    final nowChecked = folders
        .where((f) => f.favState == 1)
        .map((f) => f.id)
        .toSet();
    final addIds = nowChecked.difference(_originalIds).toList();
    final delIds = _originalIds.difference(nowChecked).toList();
    if (addIds.isEmpty && delIds.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _submitting = true);
    final result = await BilibiliFavoriteService.addVideoToFavorites(
      aid: widget.aid,
      addIds: addIds,
      delIds: delIds,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    showAppToast(
      context,
      result.ok ? '已加入 B 站收藏夹' : '操作失败：${result.message}',
    );
  }

  Future<void> _createFolder() async {
    final name = await _promptFolderName(context);
    if (name == null || !mounted) return;
    final result = await BilibiliFavoriteService.createFolder(title: name);
    if (!mounted) return;
    if (!result.ok) {
      showAppToast(context, '创建失败：${result.message}');
      return;
    }
    await _load();
    if (!mounted) return;
    final folders = _folders;
    if (folders != null) {
      final idx = folders.indexWhere((f) => f.id == result.mediaId);
      if (idx >= 0) {
        _toggle(folders[idx], true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
              child: Row(
                children: [
                  Icon(Icons.bookmark_add_outlined, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '加入 B 站收藏夹',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        if (widget.title.isNotEmpty)
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(
                      _submitting ? '处理中…' : '完成',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _createFolder,
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                label: const Text('新建收藏夹'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(height: 8),
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
            Icon(Icons.cloud_off_outlined, size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
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
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }
    final folders = _folders ?? [];
    if (folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 10),
            Text(
              '还没有收藏夹，先新建一个吧',
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
        return MorphItem(
          selected: false,
          isFirst: true,
          isLast: true,
          interactive: true,
          child: CheckboxListTile(
            value: folder.favState == 1,
            onChanged: _submitting
                ? null
                : (v) => _toggle(folder, v ?? false),
            title: Text(
              folder.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${folder.mediaCount} 个内容 · ${folder.isPublic ? '公开' : '私密'}',
              style: const TextStyle(fontSize: 12),
            ),
            secondary: Icon(
              folder.isPublic
                  ? Icons.folder_outlined
                  : Icons.lock_outline,
              size: 26,
              color: cs.onSurfaceVariant,
            ),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
        );
      },
    );
  }
}
