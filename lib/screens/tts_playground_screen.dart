                                         
  
                                           
                                   
                                         
import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:naviflash/services/lnative_bridge.dart';
import 'package:naviflash/services/liquid_glass_bar_service.dart';
import 'package:naviflash/services/tts_audio_cache_service.dart';
import 'package:naviflash/services/tts_export_native.dart';
import 'package:naviflash/services/tts_export_service.dart';
import 'package:naviflash/services/tts_model_service.dart';
import 'package:naviflash/services/tts_speech_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/glass_bottom_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class TtsPlaygroundScreen extends StatefulWidget {
  const TtsPlaygroundScreen({super.key});

  @override
  State<TtsPlaygroundScreen> createState() => _TtsPlaygroundScreenState();
}

class _TtsPlaygroundScreenState extends State<TtsPlaygroundScreen>
    with RouteAware {
  static const String _playId = 'tts_playground';

                               
                                           
                        
  bool _isTopRoute = true;
  bool _nativeBarShown = false;
  String? _nativeBarKey;
  int? _nativeBarIndex;
  ModalRoute<dynamic>? _nativeBarRoute;

                                  
  int _barIndex = 0;

  final _controller = TextEditingController(
    text: '这是一段朗读测试，用来验证语音合成的速度和缓存效果。',
  );

  TtsModelState? _modelState;
  ({int count, int bytes})? _cacheStats;

                                         
  TtsExportFormat _exportFormat = TtsExportFormat.silk;
  bool _tencentCompat = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    LiquidGlassBarService.bindTabSelected(_onBarTabSelected);
    _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _nativeBarRoute) {
      if (_nativeBarRoute != null) {
        liquidGlassBarRouteObserver.unsubscribe(this);
      }
      _nativeBarRoute = route;
      liquidGlassBarRouteObserver.subscribe(this, route);
      _isTopRoute = route.isCurrent;
    }
  }

  @override
  void didPushNext() {
    _isTopRoute = false;
    _hideNativeBar();
  }

  @override
  void didPopNext() {
    _isTopRoute = true;
    if (mounted) setState(() {});
  }

  void _hideNativeBar() {
    if (!_nativeBarShown) return;
    _nativeBarShown = false;
    _nativeBarKey = null;
    _nativeBarIndex = null;
    debugPrint('[glassbar] hide（朗读游乐场被盖住 / 销毁）');
    unawaited(LiquidGlassBarService.hide());
  }

  @override
  void dispose() {
    liquidGlassBarRouteObserver.unsubscribe(this);
    _nativeBarRoute = null;
    LiquidGlassBarService.unbindTabSelected(_onBarTabSelected);
    if (LiquidGlassBarService.ownsVisibleBar(_onBarTabSelected)) {
      unawaited(LiquidGlassBarService.hide());
    }
    _controller.dispose();
    super.dispose();
  }

                                              
                      
                                              

  static const _barShare = 1;
  static const _barSave = 2;
  static const _barClear = 3;

  List<GlassBottomBarTab> _barTabs() {
    final svc = TtsSpeechService.instance;
    final playing = svc.isActive(_playId) && _busy;
    return [
      GlassBottomBarTab(
        label: playing ? '停止' : '朗读',
        icon: playing ? Icons.stop_rounded : Icons.volume_up_rounded,
        selectedIcon: playing ? Icons.stop_rounded : Icons.volume_up_rounded,
      ),
      const GlassBottomBarTab(
        label: '分享',
        icon: Icons.ios_share_outlined,
        selectedIcon: Icons.ios_share,
      ),
      const GlassBottomBarTab(
        label: '保存',
        icon: Icons.download_outlined,
        selectedIcon: Icons.download_rounded,
      ),
      const GlassBottomBarTab(
        label: '清缓存',
        icon: Icons.cleaning_services_outlined,
        selectedIcon: Icons.cleaning_services_rounded,
      ),
    ];
  }

                                      
  void _onBarTabSelected(int index) {
    if (!mounted) return;
    setState(() => _barIndex = index);
    switch (index) {
      case _barShare:
        unawaited(_exportShare());
        break;
      case _barSave:
        unawaited(_exportSave());
        break;
      case _barClear:
        unawaited(_clearCache());
        break;
      default:
                               
        final svc = TtsSpeechService.instance;
        if (_busy && svc.isActive(_playId)) {
          svc.stop();
        } else {
          unawaited(_speak());
        }
        break;
    }
  }

  Widget _buildBottomBar(List<GlassBottomBarTab> tabs) {
    final useNative = LiquidGlassBarService.canUseNative;
                                       
    _syncNativeBar(visible: useNative, tabs: tabs);
    if (useNative) {
      return SizedBox(height: LiquidGlassBarService.slotHeight(context));
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: AppBottomBar(
          tabs: tabs,
          selectedIndex: _barIndex.clamp(0, tabs.length - 1).toInt(),
          onTabSelected: _onBarTabSelected,
        ),
      ),
    );
  }

  void _syncNativeBar({
    required bool visible,
    required List<GlassBottomBarTab> tabs,
  }) {
    if (!visible || !_isTopRoute || tabs.isEmpty) {
      _hideNativeBar();
      return;
    }
    LiquidGlassBarService.refresh();
    final index = _barIndex.clamp(0, tabs.length - 1).toInt();
    final size = MediaQuery.sizeOf(context);
    final key =
        '${tabs.length}|${tabs.map((t) => t.label).join(',')}|'
        '${size.width.round()}x${size.height.round()}';
    if (_nativeBarShown && _nativeBarKey == key && _nativeBarIndex == index) {
      return;
    }
    final needShow = !_nativeBarShown || _nativeBarKey != key;
    _nativeBarKey = key;
    _nativeBarIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (needShow) {
        final ok = await LiquidGlassBarService.show(
          context: context,
          tabs: [
            for (var i = 0; i < tabs.length; i++)
              LiquidGlassBarTab(
                id: 'tts_$i',
                label: tabs[i].label,
                icon: tabs[i].icon,
                selectedIcon: tabs[i].selectedIcon,
              ),
          ],
          index: index,
          accent: Theme.of(context).colorScheme.primary,
        );
        if (!ok) {
          LiquidGlassBarService.enabled = false;
          if (mounted) setState(() {});
          return;
        }
        _nativeBarShown = true;
      } else {
        await LiquidGlassBarService.updateIndex(index);
      }
      await LiquidGlassBarService.refresh(force: true);
    });
  }

  Future<void> _refresh() async {
    final state = await TtsModelService.state();
    final stats = await TtsAudioCacheService.stats();
    if (!mounted) return;
    setState(() {
      _modelState = state;
      _cacheStats = stats;
    });
  }

  bool get _busy =>
      TtsSpeechService.instance.status != TtsSpeechStatus.idle;

  Future<void> _speak() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      showAppToast(context, '请输入要朗读的文字', error: true);
      return;
    }
    try {
      await TtsSpeechService.instance.speak(_playId, text);
    } on TtsModelException catch (e) {
      if (mounted) showAppToast(context, e.message, error: true);
    } catch (e) {
      if (mounted) showAppToast(context, '朗读失败：$e', error: true);
    }
    await _refresh();
  }

  Future<void> _clearCache() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空朗读缓存'),
        content: const Text('删除所有已合成的朗读音频？下次朗读需要重新合成。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final removed = await TtsAudioCacheService.clearAll();
    await _refresh();
    if (mounted) showAppToast(context, '已清空 $removed 条缓存音频');
  }

                                     
  File? get _exportableWav {
    final path = TtsSpeechService.instance.lastWavPath;
    if (path == null) return null;
    final f = File(path);
    return f.existsSync() ? f : null;
  }

                               
  Future<({File file, String name})?> _prepareExport() async {
    final wav = _exportableWav;
    if (wav == null) {
      showAppToast(context, '还没有可导出的音频，请先点一次朗读', error: true);
      return null;
    }
    setState(() => _exporting = true);
    try {
      final bytes = await TtsExportService.encodeWavFile(
        wav: wav,
        format: _exportFormat,
        tencent: _tencentCompat,
      );
      final name = TtsExportService.fileNameFor(_exportFormat);
      final file = await TtsExportService.stageForShare(bytes, name);
      return (file: file, name: name);
    } on TtsExportUnsupportedException catch (e) {
      if (mounted) showAppToast(context, '$e', error: true);
      return null;
    } catch (e) {
      if (mounted) showAppToast(context, '导出失败：$e', error: true);
      return null;
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportShare() async {
    final prepared = await _prepareExport();
    if (prepared == null || !mounted) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(prepared.file.path, mimeType: _exportFormat.mime)],
          fileNameOverrides: [prepared.name],
        ),
      );
    } catch (e) {
      if (mounted) showAppToast(context, '调起分享失败：$e', error: true);
    }
  }

  Future<void> _exportSave() async {
                                          
    if (Platform.isAndroid) {
      final android = await DeviceInfoPlugin().androidInfo;
      if (android.version.sdkInt <= 28) {
        final st = await Permission.storage.request();
        if (!st.isGranted) {
          if (mounted) showAppToast(context, '未授予存储权限，无法保存', error: true);
          return;
        }
      }
    }
    final prepared = await _prepareExport();
    if (prepared == null || !mounted) return;
    final saved = await NativeBridge.saveFileToDownloads(
      sourcePath: prepared.file.path,
      fileName: prepared.name,
      mime: _exportFormat.mime,
    );
    if (!mounted) return;
    if (saved != null) {
      showAppToast(context, '已保存到 $saved');
    } else {
      showAppToast(context, '保存失败，可改用「分享」发送', error: true);
    }
  }

  Widget _buildExportCard(ColorScheme cs) {
    final wav = _exportableWav;
    final supported = TtsExportService.isSupported;
    final interactive = wav != null && supported && !_exporting;
    final over60s = (TtsSpeechService.instance.lastInfo?.audioDuration
            .inSeconds ??
        0) > 60;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.ios_share_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                const Text('导出音频',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            if (!supported)
              Text(
                'MP3 / SILK 编码依赖随包原生库，目前仅支持 Android。',
                style: TextStyle(fontSize: 12, color: cs.error),
              )
            else if (wav == null)
              Text(
                '点一次「朗读」后，可把最近一次合成的音频导出为 MP3 或'
                '微信/QQ 使用的 SILK（.silk / .slk 内容相同，仅扩展名不同）。',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              )
            else ...[
              SegmentedButton<TtsExportFormat>(
                segments: const [
                  ButtonSegment(
                      value: TtsExportFormat.mp3, label: Text('MP3')),
                  ButtonSegment(
                      value: TtsExportFormat.silk, label: Text('SILK')),
                  ButtonSegment(
                      value: TtsExportFormat.slk, label: Text('SLK')),
                ],
                selected: {_exportFormat},
                showSelectedIcon: false,
                onSelectionChanged: interactive
                    ? (s) => setState(() => _exportFormat = s.first)
                    : null,
              ),
              if (_exportFormat.isSilk) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _tencentCompat,
                  onChanged: interactive
                      ? (v) => setState(() => _tencentCompat = v)
                      : null,
                  title: const Text('微信/QQ 兼容（-tencent）'),
                  subtitle: const Text(
                    '文件头加 0x02、不写尾包，微信/QQ 按腾讯 SILK v3 识别',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                if (over60s)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '提示：微信语音消息建议 ≤60 秒；本条更长，发送到微信时'
                      '会以文件形式存在。',
                      style: TextStyle(fontSize: 11, color: cs.error),
                    ),
                  ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: interactive ? _exportShare : null,
                    icon: _exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_exporting ? '编码中…' : '分享 / 发送'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: interactive ? _exportSave : null,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('保存到下载'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusText(TtsSpeechStatus s) {
    switch (s) {
      case TtsSpeechStatus.idle:
        return '空闲';
      case TtsSpeechStatus.preparing:
        return '准备中（首次加载引擎可能要几十秒）';
      case TtsSpeechStatus.synthesizing:
        return '正在合成…';
      case TtsSpeechStatus.playing:
        return '播放中（再点一次停止）';
    }
  }

  String _fmtMillis(int ms) {
    if (ms <= 0) return '0ms';
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(2)}s';
  }

  String _fmtBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final svc = TtsSpeechService.instance;
    final mine = svc.isActive(_playId);
    final info = svc.lastInfo;

    return Scaffold(
      appBar: AppBar(title: const Text('朗读游乐场')),
                                         
                                       
      bottomNavigationBar: _buildBottomBar(_barTabs()),
      body: ListenableBuilder(
        listenable: svc,
        builder: (context, _) {
          final busy = _busy;
          final stats = _cacheStats;
          return ListView(
                                   
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              TextField(
                controller: _controller,
                minLines: 4,
                maxLines: 10,
                enabled: !busy,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '要朗读的文字',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: busy
                        ? (mine ? () => svc.stop() : null)
                        : _speak,
                    icon: Icon(mine && busy
                        ? Icons.stop_rounded
                        : Icons.volume_up_rounded),
                    label: Text(mine && busy ? '停止' : '朗读'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _statusText(svc.status),
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _ResultCard(
                info: info,
                fmtMillis: _fmtMillis,
              ),
              const SizedBox(height: 24),
              _buildExportCard(cs),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storage_rounded,
                              size: 20, color: cs.primary),
                          const SizedBox(width: 8),
                          const Text('合成音频缓存',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          TextButton(
                            onPressed:
                                (stats == null || stats.count == 0)
                                    ? null
                                    : _clearCache,
                            child: const Text('清空'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stats == null
                            ? '统计中…'
                            : '${stats.count} 条 · ${_fmtBytes(stats.bytes)}'
                            '（同文本 + 同音色重复朗读直接复用，最多保留 '
                            '${TtsAudioCacheService.maxEntries} 条）',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _modelState == TtsModelState.installed
                            ? '模型已就绪；缓存命中时无需启动引擎。'
                            : '模型未安装时，只有已有缓存的句子能播放。',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final TtsSpeechInfo? info;
  final String Function(int) fmtMillis;

  const _ResultCard({required this.info, required this.fmtMillis});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final info = this.info;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                const Text('本次结果',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (info != null)
                  _Chip(
                    label: info.fromCache ? '缓存命中' : '新合成',
                    color: info.fromCache ? Colors.teal : cs.primary,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (info == null)
              Text(
                '还没有合成记录。点「朗读」试试，然后再点一次同一句话，'
                '第二次会直接命中缓存。',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              )
            else ...[
              _kv('字符数', '${info.charCount}'),
              _kv('等待耗时', fmtMillis(info.synthElapsed.inMilliseconds)),
              _kv('音频时长', fmtMillis(info.audioDuration.inMilliseconds)),
              _kv(
                '合成速度',
                info.fromCache
                    ? '∞（未跑模型）'
                    : 'RTS ${info.rts.toStringAsFixed(3)}'
                        '（1 秒合成产出 ${info.rts.toStringAsFixed(2)} 秒音频）',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white54)),
            ),
            Expanded(
              child: Text(v, style: const TextStyle(fontSize: 12.5)),
            ),
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }
}
