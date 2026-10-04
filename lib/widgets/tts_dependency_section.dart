                                          
  
                                    
                 
  
                                             
                           
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/tts_playground_screen.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/services/tts_backend_policy.dart';
import 'package:naviflash/services/tts_engine.dart';
import 'package:naviflash/services/tts_download_service.dart';
import 'package:naviflash/services/tts_model_service.dart';
import 'package:naviflash/services/tts_native_log.dart';
import 'package:naviflash/services/tts_voice_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

class TtsDependencySection extends StatefulWidget {
  const TtsDependencySection({super.key, this.autoStart = false});

                                    
                                  
  final bool autoStart;

  @override
  State<TtsDependencySection> createState() => _TtsDependencySectionState();
}

class _TtsDependencySectionState extends State<TtsDependencySection> {
  TtsModelState _state = TtsModelState.notInstalled;
  int _bytes = -1;
                                        
                                           
  bool _working = false;
  List<TtsVoice> _voices = const [];

                                
  String? _selectedVoiceId;

                                
  TtsHardwareInfo? _hardware;

                         
  bool _lastRunning = false;

  TtsEngineManager get _engine => TtsEngineManager.instance;

  @override
  void initState() {
    super.initState();
                                
    TtsDownloadService.instance.addListener(_onDownloadChanged);
    _refresh().then((_) {
      if (!mounted || !widget.autoStart) return;
      if (_state == TtsModelState.installed || _working) return;
      _download();
    });
    TtsBackendPolicy.hardware().then((h) {
      if (mounted) setState(() => _hardware = h);
    });
  }

  @override
  void dispose() {
    TtsDownloadService.instance.removeListener(_onDownloadChanged);
    super.dispose();
  }

                                
  void _onDownloadChanged() {
    if (!mounted) return;
    final dl = TtsDownloadService.instance;
    final wasRunning = _lastRunning;
    _lastRunning = dl.isRunning;
    setState(() {});
    if (wasRunning && !dl.isRunning) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    final st = await TtsModelService.state();
    final bytes = await TtsModelService.installedBytes();
    final voices = await TtsVoiceService.loadAll();
    final selected = await TtsVoiceService.selectedId();
    if (!mounted) return;
    setState(() {
      _state = st;
      _bytes = bytes;
      _voices = voices;
      _selectedVoiceId = selected;
    });
  }

                                
  String _voiceSummary(AppLocalizations l10n) {
    if (_voices.isEmpty) return l10n.ttsVoEmpty;
    final id = _selectedVoiceId;
    if (id == null) return l10n.ttsVoDefault;
    for (final v in _voices) {
      if (v.id == id) return v.name;
    }
    return l10n.ttsVoDefault;
  }

  String _formatSize(int bytes) {
    if (bytes < 0) return '…';
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  Future<void> _download() async {
                                      
    await TtsDownloadService.instance.start();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final dl = TtsDownloadService.instance;
    final err = dl.error;
    if (err != null) {
      showAppToast(context, l10n.ttsFailed(err), error: true);
    } else if (dl.justFinished) {
      showAppToast(context, l10n.ttsInstallDone);
    }
    await _refresh();
  }

  Future<void> _uninstall() async {
    if (_working) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.ttsUninstallTitle),
        content: Text(
          l10n.ttsUninstallConfirm(_formatSize(_bytes < 0 ? 0 : _bytes)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.ttsUninstall),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _working = true);
                               
    await _engine.release();
    await TtsModelService.uninstall();
    if (!mounted) return;
    setState(() => _working = false);
    await _refresh();
    if (!mounted) return;
    showAppToast(context, l10n.ttsUninstalled);
  }

  Future<void> _pickMirror() async {
    final l10n = AppLocalizations.of(context);
                                                       
    var selected = SettingsService.ttsMirrorStatic;
    final controller =
        TextEditingController(text: SettingsService.ttsCustomUrlStatic);

    final result = await showDialog<TtsMirror>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n.ttsSourceTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.ttsSourceDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                RadioGroup<TtsMirror>(
                  groupValue: selected,
                  onChanged: (TtsMirror? v) {
                    if (v != null) setLocal(() => selected = v);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final m in TtsMirror.values)
                        RadioListTile<TtsMirror>(
                          value: m,
                          title: Text(_mirrorLabel(l10n, m)),
                        ),
                    ],
                  ),
                ),
                if (selected == TtsMirror.custom)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'https://example.com/',
                        isDense: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    await SettingsService.applyTtsMirrorGlobal(result, controller.text);
    if (!mounted) return;
    setState(() {});
    showAppToast(context, l10n.ttsSourceSaved);
  }

  String _mirrorLabel(AppLocalizations l10n, TtsMirror m) => switch (m) {
        TtsMirror.official => l10n.ttsMirrorOfficial,
        TtsMirror.hfMirror => l10n.ttsMirrorChina,
        TtsMirror.custom => l10n.ttsMirrorCustom,
      };

                 
  String _deviceLabel(
    AppLocalizations l10n,
    TtsInferenceDevicePreference device,
  ) =>
      switch (device) {
        TtsInferenceDevicePreference.auto => l10n.ttsBackendAuto,
        TtsInferenceDevicePreference.npu => l10n.ttsBackendNpu,
        TtsInferenceDevicePreference.gpu => l10n.ttsBackendGpu,
        TtsInferenceDevicePreference.cpu => l10n.ttsBackendCpu,
      };

                            
  String _deviceDesc(
    AppLocalizations l10n,
    TtsInferenceDevicePreference device,
  ) {
    final hw = _hardware;
    switch (device) {
      case TtsInferenceDevicePreference.auto:
                                                 
        if (hw != null &&
            hw.isQualcommAndroid &&
            !TtsBackendPolicy.bundledNpuRuntime) {
          return l10n.ttsBackendNpuRuntimeMissing;
        }
        return l10n.ttsBackendAutoDesc;
      case TtsInferenceDevicePreference.npu:
        if (hw == null || !hw.isQualcommAndroid) {
          return l10n.ttsBackendNpuHardwareUnsupported;
        }
        return TtsBackendPolicy.bundledNpuRuntime
            ? l10n.ttsBackendNpuDesc
            : l10n.ttsBackendNpuRuntimeMissing;
      case TtsInferenceDevicePreference.gpu:
        return l10n.ttsBackendGpuDesc;
      case TtsInferenceDevicePreference.cpu:
        return l10n.ttsBackendCpuDesc;
    }
  }

                              
  String _backendSummary(AppLocalizations l10n) {
    final pref = SettingsService.ttsInferenceDeviceStatic;
    final label = _deviceLabel(l10n, pref);
    final hw = _hardware;
    final wantsNpu = pref == TtsInferenceDevicePreference.npu ||
        (pref == TtsInferenceDevicePreference.auto &&
            hw != null &&
            hw.isQualcommAndroid);
    if (wantsNpu && !TtsBackendPolicy.bundledNpuRuntime) {
      return '$label · ${l10n.ttsBackendNpuRuntimeMissing}';
    }
    return label;
  }

  Future<void> _pickBackend() async {
    final l10n = AppLocalizations.of(context);
    var selected = SettingsService.ttsInferenceDeviceStatic;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n.ttsBackendTitle),
          content: SingleChildScrollView(
            child: RadioGroup<TtsInferenceDevicePreference>(
              groupValue: selected,
              onChanged: (v) {
                if (v != null) setLocal(() => selected = v);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final d in TtsInferenceDevicePreference.values)
                    RadioListTile<TtsInferenceDevicePreference>(
                      value: d,
                      title: Text(_deviceLabel(l10n, d)),
                      subtitle: Text(
                        _deviceDesc(l10n, d),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showNativeLog();
              },
              child: const Text('原生日志'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );

    if (selected == SettingsService.ttsInferenceDeviceStatic || !mounted) {
      return;
    }
    await SettingsService.setTtsInferenceDeviceGlobal(selected);
                                    
    if (_engine.isReady) {
      await _engine.release();
    }
    if (mounted) setState(() {});
  }

                                                
                                                  
  void _showNativeLog() {
    final lines = TtsNativeLog.recent;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '原生日志（回调 ${TtsNativeLog.totalCalls} 次，相关 ${lines.length} 行）',
          style: const TextStyle(fontSize: 15),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              lines.isEmpty
                  ? '（空）释放引擎后重新朗读一次再看。\n'
                      '若回调次数为 0，说明 ggml 日志未走到 llama_log_set。'
                  : lines.join('\n'),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                height: 1.3,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickVoice() async {
    final l10n = AppLocalizations.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      dialogTitle: l10n.ttsPickAudioTitle,
    );
    if (!mounted) return;
    final files = result?.files ?? const <PlatformFile>[];
    final path = files.isEmpty ? null : files.first.path;
    if (path == null) return;
    try {
      await TtsVoiceService.importFile(path);
      if (!mounted) return;
      showAppToast(context, l10n.ttsVoAdded);
    } on TtsVoiceException catch (e) {
      if (!mounted) return;
      showAppToast(context, l10n.ttsVoPickFailed(e.message), error: true);
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, l10n.ttsVoPickFailed('$e'), error: true);
    }
    await _refresh();
  }

  Future<void> _confirmDeleteVoice(TtsVoice voice) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.ttsVoDeleteTitle),
        content: Text(l10n.ttsVoDeleteConfirm(voice.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.ttsUninstall),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await TtsVoiceService.delete(voice.id);
    await _refresh();
    if (!mounted) return;
    showAppToast(context, l10n.ttsVoDeleted);
  }

  Future<void> _showVoices() async {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
                                
    var selected = await TtsVoiceService.selectedId();
    if (!mounted) return;

    await showAppBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> choose(String? id) async {
            await TtsVoiceService.setSelectedId(id);
            if (!ctx.mounted) return;
            setSheetState(() => selected = id);
                             
            if (mounted) setState(() {});
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.ttsVoTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.ttsVoDesc,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _pickVoice();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.ttsVoPick),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _voiceRow(
                        l10n: l10n,
                        cs: cs,
                        title: l10n.ttsVoDefault,
                        subtitle: null,
                        active: selected == null,
                        onTap: () => choose(null),
                      ),
                      for (final v in _voices)
                        _voiceRow(
                          l10n: l10n,
                          cs: cs,
                          title: v.name,
                          subtitle: _formatVoiceTime(v.createdAt),
                          active: selected == v.id,
                          onTap: () => choose(v.id),
                          onDelete: () {
                            Navigator.pop(ctx);
                            _confirmDeleteVoice(v);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

                           
  Widget _voiceRow({
    required AppLocalizations l10n,
    required ColorScheme cs,
    required String title,
    required String? subtitle,
    required bool active,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        active ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: active ? cs.primary : cs.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
      trailing: onDelete == null
          ? null
          : IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              tooltip: l10n.ttsUninstall,
              onPressed: onDelete,
            ),
    );
  }

  String _formatVoiceTime(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String _statusText(AppLocalizations l10n) {
    final dl = TtsDownloadService.instance;
    if (dl.isRunning && dl.progress != null) {
      final percent = '${(dl.progress! * 100).round()}%';
      return dl.currentFile.isEmpty
          ? l10n.ttsDownloading(percent)
          : l10n.ttsDownloadingFile(percent, dl.currentFile);
    }
    if (dl.isRunning || _working) return l10n.ttsSizeCounting;
    return switch (_state) {
      TtsModelState.installed => l10n.ttsInstalled(_formatSize(_bytes)),
      TtsModelState.partial => l10n.ttsPartial,
      TtsModelState.notInstalled =>
        '${l10n.ttsNotInstalled} · ${_formatSize(TtsModelService.variant.totalBytes)}',
    };
  }

  String _engineStatusText(AppLocalizations l10n) {
    switch (_engine.status) {
      case TtsEngineStatus.idle:
        return l10n.ttsEngineIdle;
      case TtsEngineStatus.loading:
        return l10n.ttsEngineLoading;
      case TtsEngineStatus.ready:
                                              
        final active = _engine.activeDevice;
        if (active == null) return l10n.ttsEngineReady;
        return l10n.ttsEngineReadyOn(_deviceLabel(l10n, active.effective));
      case TtsEngineStatus.error:
        return _engine.errorMessage ?? l10n.ttsEngineIdle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final installed = _state == TtsModelState.installed;
    final supported = TtsModelService.isPlatformSupported;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.ttsSection,
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
                    ? Icons.record_voice_over
                    : Icons.record_voice_over_outlined,
                size: 26,
                color: cs.primary,
              ),
              title: Text(
                l10n.ttsModelLabel,
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
                    supported ? _statusText(l10n) : l10n.ttsUnsupported,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  if (TtsDownloadService.instance.isRunning) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: TtsDownloadService.instance.progress,
                        minHeight: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ],
              ),
              trailing: !supported
                  ? null
                  : (TtsDownloadService.instance.isRunning
                                                  
                        ? TextButton(
                            onPressed: TtsDownloadService.instance.cancel,
                            child: Text(l10n.ttsDownloadCancel),
                          )
                        : TextButton(
                            onPressed: _working
                                ? null
                                : (installed ? _uninstall : _download),
                            child: Text(
                              installed
                                  ? l10n.ttsUninstall
                                  : (_state == TtsModelState.partial
                                        ? l10n.ttsResume
                                        : l10n.ttsDownload),
                            ),
                          )),
            ),
          ),
                
          if (supported)
          MorphRowItem(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(Icons.link, size: 26, color: cs.primary),
              title: Text(
                l10n.ttsSourceTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _mirrorLabel(l10n, SettingsService.ttsMirrorStatic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              onTap: _working ? null : _pickMirror,
            ),
          ),
                                                
          if (supported)
          MorphRowItem(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(Icons.developer_board, size: 26, color: cs.primary),
              title: Text(
                l10n.ttsBackendTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _backendSummary(l10n),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              onTap: _working ? null : _pickBackend,
            ),
          ),
                              
          if (supported)
          MorphRowItem(
            child: AnimatedBuilder(
              animation: _engine,
              builder: (ctx, _) => ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Icon(Icons.memory_outlined, size: 26, color: cs.primary),
                title: Text(
                  l10n.ttsSection,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _engineStatusText(l10n),
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                trailing: _engine.isReady
                    ? TextButton(
                        onPressed: () => _engine.release(),
                        child: Text(l10n.ttsEngineUnload),
                      )
                    : null,
              ),
            ),
          ),
               
          if (supported)
          MorphRowItem(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(Icons.graphic_eq, size: 26, color: cs.primary),
              title: Text(
                l10n.ttsVoTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _voiceSummary(l10n),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              onTap: _showVoices,
            ),
          ),
                                      
          MorphRowItem(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(Icons.science_outlined,
                  size: 26, color: cs.primary),
              title: const Text(
                '朗读游乐场',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '输入文字试朗读，查看耗时；合成结果自动缓存',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              trailing:
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TtsPlaygroundScreen(),
                  ),
                );
              },
            ),
          ),
        ]),
      ],
    );
  }
}
