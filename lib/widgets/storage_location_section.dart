                                            
  
                                          
  
                    
                      
                                                  
                                                
                                                       
                                         
                                  
                      
  
                                                    
             
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/native_menu_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/services/storage_paths.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/more_menu_sheet.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';
import 'package:provider/provider.dart';

                     
class _SlotSpec {
  final StorageSlot slot;
  final IconData icon;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) desc;
  final Future<void> Function(String) apply;
  final String Function(SettingsService) current;

  const _SlotSpec({
    required this.slot,
    required this.icon,
    required this.title,
    required this.desc,
    required this.apply,
    required this.current,
  });
}

class StorageLocationSection extends StatefulWidget {
                                         
  final List<StorageSlot> slots;

                                   
  final bool showTitle;

  const StorageLocationSection({
    super.key,
    this.slots = StorageSlot.values,
    this.showTitle = true,
  });

  @override
  State<StorageLocationSection> createState() => _StorageLocationSectionState();
}

class _StorageLocationSectionState extends State<StorageLocationSection> {
                           
  final Map<StorageSlot, String> _resolved = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final map = <StorageSlot, String>{};
    for (final slot in widget.slots) {
      map[slot] = (await StoragePaths.rootFor(slot)).path;
    }
    if (!mounted) return;
    setState(() {
      _resolved
        ..clear()
        ..addAll(map);
      _loading = false;
    });
  }

  List<_SlotSpec> _specs(BuildContext context) {
    final settings = context.read<SettingsService>();
    return [
      if (widget.slots.contains(StorageSlot.autoCache))
        _SlotSpec(
        slot: StorageSlot.autoCache,
        icon: Icons.auto_mode_outlined,
        title: (l) => l.storageLocationAutoCache,
        desc: (l) => l.storageLocationAutoCacheDesc,
        apply: settings.setAutoCachePath,
        current: (s) => s.autoCachePath,
      ),
      if (widget.slots.contains(StorageSlot.video))
        _SlotSpec(
          slot: StorageSlot.video,
          icon: Icons.download_for_offline_outlined,
          title: (l) => l.storageLocationVideo,
          desc: (l) => l.storageLocationVideoDesc,
          apply: settings.setVideoDownloadPath,
          current: (s) => s.videoDownloadPath,
        ),
      if (widget.slots.contains(StorageSlot.models))
        _SlotSpec(
          slot: StorageSlot.models,
          icon: Icons.memory_outlined,
          title: (l) => l.storageLocationModels,
          desc: (l) => l.storageLocationModelsDesc,
          apply: settings.setModelDownloadPath,
          current: (s) => s.modelDownloadPath,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final specs = _specs(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showTitle) ...[
          Text(
            l10n.storageLocationSection,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...buildMorphSegmentedList([
          for (final spec in specs)
            MorphRowItem(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Icon(spec.icon, size: 26, color: cs.primary),
                title: Text(
                  spec.title(l10n),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _subtitle(spec, l10n),
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                enabled: StoragePaths.canCustomize(spec.slot),
                onTap: StoragePaths.canCustomize(spec.slot)
                    ? () => _openPicker(spec)
                    : null,
              ),
            ),
        ]),
        if (StoragePaths.usesNativeCandidates) ...[
          const SizedBox(height: 8),
          Text(
            l10n.storageLocationAndroidHint,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: cs.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          l10n.storageLocationKeepOld,
          style: TextStyle(
            fontSize: 11,
            height: 1.4,
            color: cs.onSurfaceVariant.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  String _subtitle(_SlotSpec spec, AppLocalizations l10n) {
    if (!StoragePaths.canCustomize(spec.slot)) {
      return '${_pathOf(spec)} · ${l10n.storageLocationUnsupported}';
    }
    final custom = spec.current(context.read<SettingsService>());
    final path = _pathOf(spec);
    return custom.isEmpty
        ? '$path · ${l10n.storageLocationDefault}'
        : l10n.storageLocationCurrent(path);
  }

  String _pathOf(_SlotSpec spec) =>
      _loading ? '…' : (_resolved[spec.slot] ?? '…');

                                              
          
                                              

  Future<void> _openPicker(_SlotSpec spec) async {
    final l10n = AppLocalizations.of(context);
    final hasCustom = spec.current(context.read<SettingsService>()).isNotEmpty;

    Future<void> reset() async {
      await spec.apply('');
      await _load();
      if (!mounted) return;
      showAppToast(context, l10n.storageLocationResetDone);
    }

    Future<void> pick() async {
      final chosen = StoragePaths.usesNativeCandidates
          ? await _pickFromAndroidCandidates(spec)
          : await FilePicker.platform.getDirectoryPath(
              dialogTitle: l10n.storageLocationPick,
            );
      if (chosen == null || chosen.isEmpty || !mounted) return;

      final info = await StoragePaths.info(chosen);
      if (info == null || !info.writable) {
        if (!mounted) return;
        showAppToast(context, l10n.storageLocationNotWritable);
        return;
      }
      await spec.apply(chosen);
      await _load();
      if (!mounted) return;
      showAppToast(context, l10n.storageLocationSetDone(chosen));
    }

    final nativeOk = await tryShowNativeMenuSheet(
      context,
      title: spec.title(l10n),
      items: [
        NativeMenuItem(
          text: l10n.storageLocationPick,
          icon: Icons.folder_open_outlined,
          onTap: pick,
        ),
        if (hasCustom)
          NativeMenuItem(
            text: l10n.storageLocationReset,
            icon: Icons.restore_outlined,
            onTap: reset,
          ),
      ],
    );
    if (nativeOk || !mounted) return;

    final action = await showAppBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  spec.title(l10n),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: Text(l10n.storageLocationPick),
              onTap: () => Navigator.pop(ctx, 'pick'),
            ),
            if (hasCustom)
              ListTile(
                leading: const Icon(Icons.restore_outlined),
                title: Text(l10n.storageLocationReset),
                onTap: () => Navigator.pop(ctx, 'reset'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    if (action == 'reset') {
      await reset();
      return;
    }

    await pick();
  }

                                            
  Future<String?> _pickFromAndroidCandidates(_SlotSpec spec) async {
    final l10n = AppLocalizations.of(context);
    final candidates = await StoragePaths.candidates(spec.slot);
    if (!mounted) return null;
    if (candidates.isEmpty) {
      showAppToast(context, l10n.storageLocationUnsupported);
      return null;
    }

    return showAppBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (ctx, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.storageLocationPick,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: candidates.length,
                itemBuilder: (ctx, i) {
                  final c = candidates[i];
                  final free = c.freeBytes == null
                      ? null
                      : l10n.storageLocationFree(_formatSize(c.freeBytes!));
                  return ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(c.label),
                    subtitle: Text(
                      [c.detail, free].whereType<String>().join(' · '),
                      style: const TextStyle(fontSize: 12),
                    ),
                    enabled: c.writable,
                    trailing: IconButton(
                      icon: const Icon(Icons.create_new_folder_outlined),
                      tooltip: l10n.storageLocationNewFolder,
                      onPressed: c.writable
                          ? () async {
                              final sub = await _createSubfolder(c.path);
                              if (sub != null && ctx.mounted) {
                                Navigator.pop(ctx, sub);
                              }
                            }
                          : null,
                    ),
                    onTap: c.writable ? () => Navigator.pop(ctx, c.path) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

                      
  Future<String?> _createSubfolder(String parent) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.storageLocationNewFolder),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.storageLocationFolderName,
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return null;
    final sub = await StoragePaths.createSubdirectory(parent, name);
    if (sub == null && mounted) {
      showAppToast(context, l10n.storageLocationCreateFailed);
    }
    return sub;
  }

  static String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}
