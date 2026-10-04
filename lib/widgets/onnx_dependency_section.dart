                                           
  
                                      
  
                                                                 
                                               
               
import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/onnx_dependency_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/morph_card.dart';

class OnnxDependencySection extends StatefulWidget {
  const OnnxDependencySection({super.key});

  @override
  State<OnnxDependencySection> createState() => _OnnxDependencySectionState();
}

class _OnnxDependencySectionState extends State<OnnxDependencySection> {
  OnnxDepState _state = OnnxDepState.notInstalled;
  int _bytes = -1;
  bool _working = false;
  double? _progress;                    

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final st = await OnnxDependencyService.state();
    final bytes = await OnnxDependencyService.installedBytes();
    if (!mounted) return;
    setState(() {
      _state = st;
      _bytes = bytes;
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 0) return '…';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  Future<void> _install() async {
    if (_working) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _working = true;
      _progress = 0;
    });
    try {
      await OnnxDependencyService.install(
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _progress = total > 0 ? (received / total).clamp(0.0, 1.0) : null;
          });
        },
      );
      if (!mounted) return;
      showAppToast(context, l10n.onnxDepInstallDone);
    } on OnnxDownloadException catch (e) {
      if (!mounted) return;
      showAppToast(context, l10n.onnxDepFailed(e.message), error: true);
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, l10n.onnxDepFailed('$e'), error: true);
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
          _progress = null;
        });
      }
      await _refresh();
    }
  }

  Future<void> _uninstall() async {
    if (_working) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.onnxDepUninstallTitle),
        content: Text(
          l10n.onnxDepUninstallConfirm(_formatSize(_bytes < 0 ? 0 : _bytes)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.onnxDepUninstall),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _working = true);
    await OnnxDependencyService.uninstall();
    if (!mounted) return;
    setState(() => _working = false);
    await _refresh();
    if (!mounted) return;
    showAppToast(context, l10n.onnxDepUninstalled);
  }

  Future<void> _editSource() async {
    final l10n = AppLocalizations.of(context);
                                                       
    final controller = TextEditingController(text: SettingsService.onnxDepBaseUrlStatic);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.onnxDepSourceTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
            hintText: kDefaultOnnxBaseUrl,
            helperText: l10n.onnxDepSourceDesc,
            helperMaxLines: 3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    await SettingsService.setOnnxDepBaseUrlGlobal(result);
    if (!mounted) return;
    setState(() {});
    showAppToast(context, l10n.onnxDepSourceSaved);
  }

  String _statusText(AppLocalizations l10n) {
    if (_state == OnnxDepState.unsupported) return l10n.onnxDepUnsupported;
    if (_working && _progress != null) {
      return l10n.onnxDepDownloading('${(_progress! * 100).round()}%');
    }
    if (_working) return l10n.onnxDepSizeCounting;
    if (_state == OnnxDepState.notInstalled) {
      return '${l10n.onnxDepNotInstalled} · ${l10n.onnxDepDesc}';
    }
    return l10n.onnxDepInstalled(_formatSize(_bytes));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final installed = _state == OnnxDepState.installed;
    final supported = _state != OnnxDepState.unsupported;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.onnxDepSection,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
        ),
        const SizedBox(height: 12),
        ...buildMorphSegmentedList([
          MorphRowItem(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(
                installed
                    ? Icons.auto_awesome
                    : Icons.auto_awesome_outlined,
                size: 26,
                color: cs.primary,
              ),
              title: Text(
                l10n.onnxDepSection,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    _statusText(l10n),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  if (_working) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ],
              ),
              trailing: !supported
                  ? null
                  : TextButton(
                      onPressed: _working
                          ? null
                          : (installed ? _uninstall : _install),
                      child: Text(
                        installed ? l10n.onnxDepUninstall : l10n.onnxDepDownload,
                      ),
                    ),
            ),
          ),
          if (supported)
            MorphRowItem(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Icon(Icons.link, size: 26, color: cs.primary),
                title: Text(
                  l10n.onnxDepSourceTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  SettingsService.onnxDepBaseUrlStatic.isEmpty
                      ? kDefaultOnnxBaseUrl
                      : SettingsService.onnxDepBaseUrlStatic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                onTap: _working ? null : _editSource,
              ),
            ),
        ]),
      ],
    );
  }
}
