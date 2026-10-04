                                   
  
                                           
                        
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';
import 'package:share_plus/share_plus.dart';
import '../services/log_service.dart';
import '../widgets/expressive_app_bar.dart';
import '../widgets/morph_card.dart';
import '../widgets/page_background.dart';
import '../l10n/app_localizations.dart';

class _LogFile {
  final String name;
  final String path;
  final int size;
  final DateTime modified;
  const _LogFile({
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
  });

  String get sizeLabel {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class LogViewerPage extends StatefulWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const LogViewerPage({super.key, this.isSplitView = false, this.onBack});

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  List<_LogFile> _errorFiles = [];
  List<_LogFile> _mpvFiles = [];
  bool _loading = true;

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    _errorFiles = await _listLogs(LogService.errorDir);
    _mpvFiles = await _listLogs(LogService.mpvDir);
    if (mounted) setState(() => _loading = false);
  }

  Future<List<_LogFile>> _listLogs(Directory? dir) async {
    if (dir == null || !await dir.exists()) return [];
    try {
      final files = <_LogFile>[];
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        try {
          final stat = await entity.stat();
          files.add(
            _LogFile(
              name: entity.uri.pathSegments.last,
              path: entity.path,
              size: stat.size,
              modified: stat.modified,
            ),
          );
        } catch (_) {}
      }
      files.sort((a, b) => b.modified.compareTo(a.modified));
      return files;
    } catch (_) {
      return [];
    }
  }

                                 
  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logClearTitle),
        content: Text(l10n.logClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.logClearAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    var deleted = 0;
    for (final dir in [LogService.errorDir, LogService.mpvDir]) {
      if (dir == null || !await dir.exists()) continue;
      try {
        await for (final entity in dir.list()) {
          if (entity is File) {
            try {
              await entity.delete();
              deleted++;
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
    await _refresh();
    if (!mounted) return;
    showAppToast(context, l10n.logDeletedCount(deleted));
  }

                                 
  Future<void> _viewLog(_LogFile file) async {
    final content = await _readContent(file.path);
    if (!mounted) return;
    showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final l10n = AppLocalizations.of(ctx);
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: FrostedSheet(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              color: Colors.transparent,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            file.name,
                            style: Theme.of(ctx).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.logCopyContent,
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: content),
                            );
                            if (ctx.mounted) {
                              showAppToast(ctx, l10n.scanCopiedToClipboard);
                            }
                          },
                        ),
                        IconButton(
                          tooltip: l10n.logShare,
                          icon: const Icon(Icons.share_rounded),
                          onPressed: () {
                            SharePlus.instance.share(
                              ShareParams(
                                files: [XFile(file.path)],
                                text: file.name,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: l10n.logDeleteThis,
                          icon: Icon(Icons.delete_outline, color: cs.error),
                          onPressed: () async {
                            try {
                              final f = File(file.path);
                              if (await f.exists()) await f.delete();
                            } catch (_) {}
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            await _refresh();
                          },
                        ),
                        IconButton(
                          tooltip: l10n.scanClose,
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: content.isEmpty
                        ? Center(
                            child: Text(
                              l10n.logEmptyContent,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: SelectableText(
                              content,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                height: 1.4,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String> _readContent(String path) async {
    try {
      final f = File(path);
      if (!await f.exists()) return '';
      return await f.readAsString();
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
        body: Stack(
          children: [
            PageBackground(baseColor: colorScheme.surfaceContainer),
            CustomScrollView(
              physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),                                                  
              slivers: [
                ExpressiveSliverAppBar(
                  title: l10n.logTitle,
                  expandedHeight: 152,
                  leading: widget.isSplitView
                      ? null
                      : MorphIconButton(
                          tooltip: l10n.logBackTooltip,
                          icon: Icons.arrow_back,
                          onTap: _handleBack,
                        ),
                  actions: [
                    MorphIconButton(
                      tooltip: l10n.logRefresh,
                      icon: Icons.refresh_rounded,
                      onTap: _refresh,
                    ),
                    MorphIconButton(
                      tooltip: l10n.logClearAll,
                      icon: Icons.delete_sweep_outlined,
                      onTap: _clearAll,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Text(
                      l10n.logStorageLocation(LogService.baseDirLabel),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionTitle(context, l10n.logErrorSection),
                        const SizedBox(height: 12),
                        _buildFileList(
                          context,
                          _errorFiles,
                          l10n.logNoErrorLogs,
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionTitle(context, l10n.logMpvSection),
                        const SizedBox(height: 12),
                        _buildFileList(context, _mpvFiles, l10n.logNoMpvLogs),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ],
        ),
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

  Widget _buildFileList(
    BuildContext context,
    List<_LogFile> files,
    String emptyText,
  ) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return MorphItem(
        selected: false,
        isFirst: true,
        isLast: true,
        interactive: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).logReadingLogs,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }
    if (files.isEmpty) {
      return MorphItem(
        selected: false,
        isFirst: true,
        isLast: true,
        interactive: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(emptyText, style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      );
    }
    return Column(
      children: buildMorphSegmentedList(
        files.map((f) {
          return MorphRowItem(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Icon(
                Icons.description_outlined,
                size: 26,
                color: cs.onSurfaceVariant,
              ),
              title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${f.sizeLabel} · ${_formatTime(f.modified)}',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
              ),
              onTap: () => _viewLog(f),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}
