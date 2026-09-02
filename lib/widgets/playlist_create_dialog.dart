import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/services/playlist_service.dart';
import 'package:naviflash/services/webdav_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/webdav_file_picker.dart';
import '../src/loading_indicator_m3e.dart';
import '../l10n/app_localizations.dart';

/// 创建/编辑播放列表对话框
class PlaylistCreateDialog extends StatefulWidget {
  final Playlist? existingPlaylist; // 编辑模式时传入

  const PlaylistCreateDialog({super.key, this.existingPlaylist});

  static Future<Playlist?> show(BuildContext context,
      {Playlist? existingPlaylist}) {
    return showDialog<Playlist>(
      context: context,
      builder: (_) => PlaylistCreateDialog(existingPlaylist: existingPlaylist),
    );
  }

  @override
  State<PlaylistCreateDialog> createState() => _PlaylistCreateDialogState();
}

class _PlaylistCreateDialogState extends State<PlaylistCreateDialog> {
  late TextEditingController _nameController;
  List<PlaylistItem> _items = [];
  bool _isSaving = false;

  bool get _isEditing => widget.existingPlaylist != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingPlaylist?.name ?? '',
    );
    if (_isEditing) {
      _items = List.from(widget.existingPlaylist!.items);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 从 WebDAV 多选导入
  Future<void> _importFromWebDav() async {
    final results = await WebDavFilePickerDialog.showMultiSelect(context);
    if (results == null || results.isEmpty || !mounted) return;

    final webdav = context.read<WebDavService>();
    final newItems = <PlaylistItem>[];

    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      newItems.add(PlaylistItem(
        id: PlaylistService.generateId(),
        url: webdav.getFileStreamUrl(r.path),
        title: r.name,
        index: _items.length + i,
        headers: webdav.getAuthHeaders(),
        authenticatedUrl: webdav.getAuthenticatedUrl(r.path),
      ));
    }

    setState(() => _items.addAll(newItems));

    if (mounted) {
      showAppToast(
        context,
        AppLocalizations.of(context).playlistImportAdded(newItems.length),
      );
    }
  }

  /// 手动添加单集（仅记录 URL，不拉取视频）
  Future<void> _addManualEntry() async {
    final urlController = TextEditingController();
    final titleController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).playlistAddEpisodeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx).playlistTitleLabel,
                hintText: AppLocalizations.of(ctx).playlistEpisodeHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx).playlistVideoUrlLabel,
                hintText: 'https://...',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(ctx).playlistAdd),
          ),
        ],
      ),
    );

    if (confirmed == true && urlController.text.trim().isNotEmpty) {
      final title = titleController.text.trim().isEmpty
          ? AppLocalizations.of(context)
              .playlistDetailEpisodeOf(_items.length + 1)
          : titleController.text.trim();

      setState(() {
        _items.add(PlaylistItem(
          id: PlaylistService.generateId(),
          url: urlController.text.trim(),
          title: title,
          index: _items.length,
        ));
      });
    }

    urlController.dispose();
    titleController.dispose();
  }

  /// 保存播放列表
  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showAppToast(context, AppLocalizations.of(context).playlistNameRequired);
      return;
    }
    if (_items.isEmpty) {
      showAppToast(context, AppLocalizations.of(context).playlistAtLeastOneVideo);
      return;
    }

    setState(() => _isSaving = true);

    final service = context.read<PlaylistService>();

    if (_isEditing) {
      final existing = widget.existingPlaylist!;
      // 更新现有播放列表
      await service.renamePlaylist(existing.id, name);
      // 直接替换 items（简化处理）
      final updated = Playlist(
        id: existing.id,
        name: name,
        items: _items,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
        currentIndex: existing.currentIndex,
        currentPositionMs: existing.currentPositionMs,
      );
      // 通过删除再创建来更新（或可扩展 service 方法）
      await service.deletePlaylist(existing.id);
      final result = await service.createPlaylist(name: name, items: _items);
      if (mounted) Navigator.of(context).pop(result);
    } else {
      final result = await service.createPlaylist(name: name, items: _items);
      if (mounted) Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        height: 560,
        child: Column(
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.queue_music, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    _isEditing ? l10n.playlistEditTitle : l10n.playlistCreateTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 名称输入
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.playlistNameLabel,
                  hintText: l10n.playlistNameHint,
                  prefixIcon: const Icon(Icons.title),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),

            // 操作按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.cloud_download, size: 18),
                    label: Text(l10n.playlistWebdavMulti),
                    onPressed: _importFromWebDav,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_link, size: 18),
                    label: Text(l10n.homeManualAdd),
                    onPressed: _addManualEntry,
                  ),
                  const Spacer(),
                  Text(
                    l10n.playlistItemsCount(_items.length),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),

            // 集数列表
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.movie_outlined,
                              size: 48, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                            l10n.playlistNoItems,
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.playlistImportHint,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _items.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _items.removeAt(oldIndex);
                          _items.insert(newIndex, item);
                          for (var i = 0; i < _items.length; i++) {
                            _items[i] = _items[i].copyWith(index: i);
                          }
                        });
                      },
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          key: ValueKey(item.id),
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color:
                                    theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            item.url.length > 60
                                ? '${item.url.substring(0, 60)}...'
                                : item.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 20, color: theme.colorScheme.error),
                            onPressed: () {
                              setState(() {
                                _items.removeAt(index);
                                for (var i = 0; i < _items.length; i++) {
                                  _items[i] =
                                      _items[i].copyWith(index: i);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 1),

            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: _isSaving
                        ? const LoadingIndicatorM3E(
                            constraints: BoxConstraints(
                              minWidth: 16,
                              maxWidth: 16,
                              minHeight: 16,
                              maxHeight: 16,
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(_isEditing ? l10n.playlistSaveChanges : l10n.commonCreate),
                    onPressed: _isSaving ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}