                                          
  
                                                           
                                                              
                                                            
                                                  
                                
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/page_loading.dart';
import 'package:naviflash/widgets/search_video_menu.dart';

class FollowTagManagePage extends StatefulWidget {
  const FollowTagManagePage({super.key});

  @override
  State<FollowTagManagePage> createState() => _FollowTagManagePageState();
}

class _FollowTagManagePageState extends State<FollowTagManagePage> {
  final List<BiliFollowTag> _tags = [];
  bool _loading = true;
  String? _error;

                                            
  int? _busyTag;
  bool _creating = false;

  bool get _isZh => Localizations.localeOf(context).languageCode == 'zh';

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
    final tags = await BilibiliUserSpaceService.fetchFollowTags();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (tags == null) {
        _error = _isZh ? '分组加载失败，请检查登录状态' : 'Failed to load tags';
        return;
      }
      _tags
        ..clear()
        ..addAll(tags);
    });
  }

  Future<void> _create() async {
    final name = await _showNameDialog(
      title: _isZh ? '新建分组' : 'New group',
      initial: '',
    );
    if (name == null || name.isEmpty || !mounted) return;
    setState(() => _creating = true);
    final ok = await BilibiliUserSpaceService.createFollowTag(name);
    if (!mounted) return;
    setState(() => _creating = false);
    if (!ok) {
      showAppToast(
        context,
        _isZh ? '新建失败，请稍后重试' : 'Failed to create',
        error: true,
      );
      return;
    }
    await _load();
  }

  Future<void> _rename(BiliFollowTag tag) async {
    final name = await _showNameDialog(
      title: _isZh ? '重命名分组' : 'Rename group',
      initial: tag.name,
    );
    if (name == null || name.isEmpty || name == tag.name || !mounted) return;
    setState(() => _busyTag = tag.tagid);
    final ok = await BilibiliUserSpaceService.renameFollowTag(tag.tagid, name);
    if (!mounted) return;
    setState(() => _busyTag = null);
    if (!ok) {
      showAppToast(
        context,
        _isZh ? '重命名失败' : 'Failed to rename',
        error: true,
      );
      return;
    }
    final i = _tags.indexWhere((e) => e.tagid == tag.tagid);
    if (i >= 0) {
      setState(() => _tags[i] = BiliFollowTag(
        tagid: tag.tagid,
        name: name,
        count: tag.count,
      ));
    }
  }

  Future<void> _delete(BiliFollowTag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _isZh ? '删除分组「${tag.name}」？' : 'Delete "${tag.name}"?',
          style: const TextStyle(fontSize: 16),
        ),
        content: Text(
          _isZh
              ? '组内 UP 主不会取关，会移到默认分组。'
              : 'Members stay followed, they just move to the default group.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyTag = tag.tagid);
    final ok = await BilibiliUserSpaceService.deleteFollowTag(tag.tagid);
    if (!mounted) return;
    setState(() => _busyTag = null);
    if (!ok) {
      showAppToast(
        context,
        _isZh ? '删除失败' : 'Failed to delete',
        error: true,
      );
      return;
    }
    setState(() => _tags.removeWhere((e) => e.tagid == tag.tagid));
  }

                                 
                                                            
  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final tag = _tags.removeAt(oldIndex);
    _tags.insert(newIndex, tag);
    setState(() {});
    final ok = await BilibiliUserSpaceService.sortFollowTags(
      _tags.map((e) => e.tagid).toList(),
    );
    if (!mounted) return;
    if (!ok) {
      showAppToast(
        context,
        _isZh ? '排序保存失败' : 'Failed to save order',
        error: true,
      );
    }
  }

  Future<String?> _showNameDialog({
    required String title,
    required String initial,
  }) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 12,
          decoration: InputDecoration(
            hintText: _isZh ? '分组名称' : 'Group name',
            isDense: true,
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(AppLocalizations.of(ctx).commonOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
        backgroundColor: cs.surfaceContainerLow,
        appBar: AppBar(
          backgroundColor: cs.surfaceContainerLow,
          scrolledUnderElevation: 0,
          title: Text(_isZh ? '管理分组' : 'Manage groups'),
          actions: [
            IconButton(
              tooltip: _isZh ? '新建分组' : 'New group',
              onPressed: _creating ? null : _create,
              icon: _creating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
            ),
          ],
        ),
        body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _tags.isEmpty,
    )) {
      return const PageLoadingIndicator();
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _load,
                child: Text(AppLocalizations.of(context).commonRetry),
              ),
            ],
          ),
        ),
      );
    }
    if (_tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: 44,
              color: cs.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 12),
            Text(
              _isZh ? '还没有自定义分组' : 'No custom groups yet',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    return ReorderableListView.builder(
      padding: EdgeInsets.only(
        top: 6,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      itemCount: _tags.length,
      onReorderItem: _onReorder,
      itemBuilder: (context, index) {
        final tag = _tags[index];
        final busy = _busyTag == tag.tagid;
        return ListTile(
          key: ValueKey<int>(tag.tagid),
          leading: Icon(Icons.drag_indicator, size: 20, color: cs.outline),
          title: Text(
            tag.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14.5, color: cs.onSurface),
          ),
          subtitle: tag.count > 0
              ? Text(
                  '${tag.count}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                )
              : null,
          trailing: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : LiquidGlassMenuButton(
                  icon: Icons.more_vert,
                  tooltip: '',
                  useMorphStyle: false,
                  size: 36,
                  menuWidth: 180,
                  actions: [
                    GlassMenuAction(
                      icon: Icons.edit_outlined,
                      text: _isZh ? '重命名' : 'Rename',
                      onTap: () => _rename(tag),
                    ),
                    GlassMenuAction(
                      icon: Icons.delete_outline,
                      text: _isZh ? '删除' : 'Delete',
                      isDestructive: true,
                      onTap: () => _delete(tag),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
