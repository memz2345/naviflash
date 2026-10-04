import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/screens/bilibili_dm_block_page.dart';
import 'package:naviflash/services/bilibili_dm_block_service.dart';
import 'package:naviflash/widgets/app_tooltip.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';
import 'danmaku_controller.dart';
import 'danmaku_fetcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/onnx_dependency_service.dart';
import '../../widgets/app_toast.dart';

Future<void> showDanmakuSettingsSheet(
  BuildContext context,
  DanmakuController controller, {
  VoidCallback? onLoadFile,
  VoidCallback? onFetchOnline,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DanmakuSettingsSheet(
      controller: controller,
      onLoadFile: onLoadFile,
      onFetchOnline: onFetchOnline,
    ),
  );
}

class DanmakuSettingsSheet extends StatefulWidget {
  final DanmakuController controller;
  final VoidCallback? onLoadFile;
  final VoidCallback? onFetchOnline;

  const DanmakuSettingsSheet({
    super.key,
    required this.controller,
    this.onLoadFile,
    this.onFetchOnline,
  });

  @override
  State<DanmakuSettingsSheet> createState() => _DanmakuSettingsSheetState();
}

class _DanmakuSettingsSheetState extends State<DanmakuSettingsSheet> {
  late double _speed;
  late double _opacity;
  late double _fontSizeScale;
  late double _fontSizeScaleFS;
  late double _fontWeight;
  late double _strokeWidth;
  late double _showArea;
  late double _lineHeightScale;
  late double _scrollDuration;
  late double _staticDuration;
  late int _maxLines;
  late int _danmakuWeight;
  late bool _enabled;
  late bool _showScroll;
  late bool _showTop;
  late bool _showBottom;
  late bool _showAdvanced;
  late bool _massiveMode;
  late bool _static2Scroll;
  late bool _blockColorful;
  late bool _smartMask;

                                                       
  bool _dmBlockRules = true;

                                               
  bool _mergeDanmaku = false;

                        
  Timer? _persistDebounce;

  DanmakuController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _syncFromController();
                                             
    OnnxDependencyService.refreshInstalled();
                       
    BilibiliDmBlockService.ensureLoaded().then((_) {
      if (mounted) {
        setState(() => _dmBlockRules = BilibiliDmBlockService.rulesEnabled);
      }
    });
                       
    DanmakuSegFetcher.loadMergeDanmakuPref().then((_) {
      if (mounted) {
        setState(() => _mergeDanmaku = DanmakuSegFetcher.mergeDanmakuEnabled);
      }
    });
  }

                                  
  bool _ensureSmartMaskDep() {
    if (OnnxDependencyService.installedCached) return true;
    showAppToast(context, AppLocalizations.of(context).onnxDepNeedInstall,
        error: true);
    return false;
  }

  @override
  void didUpdateWidget(DanmakuSettingsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _syncFromController();
    }
  }

  @override
  void dispose() {
    _persistDebounce?.cancel();
                   
    _ctrl.persistSettings();
    super.dispose();
  }

                                     
  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 600), () {
      _ctrl.persistSettings();
    });
  }

  void _syncFromController() {
    _speed = _ctrl.speed;
    _opacity = _ctrl.opacity;
    _fontSizeScale = _ctrl.fontSizeScale;
    _fontSizeScaleFS = _ctrl.fontSizeScaleFS;
    _fontWeight = _ctrl.fontWeight;
    _strokeWidth = _ctrl.strokeWidth;
    _showArea = _ctrl.showArea;
    _lineHeightScale = _ctrl.lineHeightScale;
    _scrollDuration = _ctrl.scrollDuration;
    _staticDuration = _ctrl.staticDuration;
    _maxLines = _ctrl.maxLines;
    _danmakuWeight = _ctrl.danmakuWeight;
    _enabled = _ctrl.enabled;
    _showScroll = _ctrl.showScroll;
    _showTop = _ctrl.showTop;
    _showBottom = _ctrl.showBottom;
    _showAdvanced = _ctrl.showAdvanced;
    _massiveMode = _ctrl.massiveMode;
    _static2Scroll = _ctrl.static2Scroll;
    _blockColorful = _ctrl.blockColorful;
    _smartMask = _ctrl.smartMask;
  }

  void _apply() {
    _ctrl.speed = _speed;
    _ctrl.opacity = _opacity;
    _ctrl.fontSizeScale = _fontSizeScale;
    _ctrl.fontSizeScaleFS = _fontSizeScaleFS;
    _ctrl.fontWeight = _fontWeight;
    _ctrl.strokeWidth = _strokeWidth;
    _ctrl.showArea = _showArea;
    _ctrl.lineHeightScale = _lineHeightScale;
    _ctrl.scrollDuration = _scrollDuration;
    _ctrl.staticDuration = _staticDuration;
    _ctrl.maxLines = _maxLines;
    _ctrl.danmakuWeight = _danmakuWeight;
    _ctrl.enabled = _enabled;
    _ctrl.showScroll = _showScroll;
    _ctrl.showTop = _showTop;
    _ctrl.showBottom = _showBottom;
    _ctrl.showAdvanced = _showAdvanced;
    _ctrl.massiveMode = _massiveMode;
    _ctrl.static2Scroll = _static2Scroll;
    _ctrl.blockColorful = _blockColorful;
    _ctrl.smartMask = _smartMask;
    _ctrl.onNeedRepaint?.call();
    _schedulePersist();
  }

  void _recomputeTracks() {
    if (_ctrl.screenWidth > 0 && _ctrl.screenHeight > 0) {
      _ctrl.setSize(_ctrl.screenWidth, _ctrl.screenHeight);
    }
  }

  void _setStateAnd(VoidCallback fn) {
    setState(fn);
    _apply();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GlassMenuSurface(
        radius: 12.0,
        blur: 12.0,
                                  
                             
        tintOpacity: 0.15,
        lightIntensity: 0.2,
        stretch: 0,
        legacyClipRadius: BorderRadius.circular(12),
        legacyDecoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: cs.primary,
                inactiveTrackColor: cs.surfaceContainerHighest,
                thumbColor: cs.primary,
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  SizedBox(
                    height: 45,
                    child: Center(
                      child: Text(
                        l10n.danmakuSettingsTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                              
                  _buildSectionHeader(l10n.danmakuDataSource),
                  _buildLoadButtons(),
                  const SizedBox(height: 2),
                  _buildDanmakuInfo(),
                  const SizedBox(height: 8),

                               
                  _buildSectionHeader(l10n.danmakuDisplayControl),
                  SwitchListTile(
                    title: Text(l10n.danmakuEnable),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    value: _enabled,
                    onChanged: (v) => _setStateAnd(() => _enabled = v),
                  ),
                  SwitchListTile(
                    title: Text(l10n.danmakuSmartMask),
                    subtitle: Text(
                      l10n.danmakuSmartMaskDesc,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    value: _smartMask,
                    onChanged: (v) => _setStateAnd(() {
                          if (v && !_ensureSmartMaskDep()) return;
                          _smartMask = v;
                        }),
                  ),
                  const SizedBox(height: 8),

                  _buildSectionHeader(l10n.danmakuCloudFilter),
                  _buildCloudFilterRow(l10n),
                  _buildDmBlockRulesRow(),
                  const SizedBox(height: 8),

                  _buildSectionHeader(l10n.danmakuTypeFilter),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        _buildToggleChip(
                          label: l10n.danmakuTypeScroll,
                          selected: _showScroll,
                          onTap: () =>
                              _setStateAnd(() => _showScroll = !_showScroll),
                        ),
                        _buildToggleChip(
                          label: l10n.danmakuTypeTop,
                          selected: _showTop,
                          onTap: () => _setStateAnd(() => _showTop = !_showTop),
                        ),
                        _buildToggleChip(
                          label: l10n.danmakuTypeBottom,
                          selected: _showBottom,
                          onTap: () =>
                              _setStateAnd(() => _showBottom = !_showBottom),
                        ),
                        _buildToggleChip(
                          label: l10n.danmakuBlockColorful,
                          selected: _blockColorful,
                          onTap: () => _setStateAnd(
                            () => _blockColorful = !_blockColorful,
                          ),
                        ),
                        _buildToggleChip(
                          label: l10n.danmakuTypeAdvanced,
                          selected: _showAdvanced,
                          onTap: () => _setStateAnd(() {
                            _showAdvanced = !_showAdvanced;
                            if (!_showAdvanced) {
                              _ctrl.activeBasDanmakus.clear();
                            }
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildSectionHeader(l10n.danmakuOthers),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        _buildToggleChip(
                          label: l10n.danmakuMassiveMode,
                          selected: _massiveMode,
                          onTap: () => _setStateAnd(() {
                            _massiveMode = !_massiveMode;
                            _recomputeTracks();
                          }),
                        ),
                        _buildToggleChip(
                          label: l10n.danmakuStatic2Scroll,
                          selected: _static2Scroll,
                          onTap: () => _setStateAnd(
                            () => _static2Scroll = !_static2Scroll,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildSectionHeader(l10n.danmakuParameters),

                  _buildSliderRow(
                    l10n,
                    label: l10n.danmakuScrollSpeed,
                    value: _speed,
                    min: 0.2,
                    max: 3.0,
                    divisions: 14,
                    display: '${_speed.toStringAsFixed(1)}x',
                    resetLabel: '1.0x',
                    onChanged: (v) => _setStateAnd(() => _speed = v),
                    onReset: () => _setStateAnd(() => _speed = 1.0),
                  ),
                  _buildSliderRow(
                    l10n,
                    label: l10n.danmakuOpacity,
                    value: _opacity,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    display: '${(_opacity * 100).toInt()}%',
                    resetLabel: '100%',
                    onChanged: (v) => _setStateAnd(() => _opacity = v),
                    onReset: () => _setStateAnd(() => _opacity = 1.0),
                  ),
                  _buildSliderRow(
                    l10n,
                    label: l10n.danmakuFontSize,
                    value: _fontSizeScale,
                    min: 0.5,
                    max: 2.5,
                    divisions: 20,
                    display: '${(_fontSizeScale * 100).toInt()}%',
                    resetLabel: '100%',
                    onChanged: (v) => _setStateAnd(() {
                      _fontSizeScale = v;
                      _recomputeTracks();
                    }),
                    onReset: () => _setStateAnd(() {
                      _fontSizeScale = 1.0;
                      _recomputeTracks();
                    }),
                  ),
                  _buildSliderRow(
                    l10n,
                    label: l10n.danmakuFontSizeFS,
                    value: _fontSizeScaleFS,
                    min: 0.5,
                    max: 2.5,
                    divisions: 20,
                    display: '${(_fontSizeScaleFS * 100).toInt()}%',
                    resetLabel: '120%',
                    onChanged: (v) => _setStateAnd(() {
                      _fontSizeScaleFS = v;
                      if (_ctrl.isFullscreen) _recomputeTracks();
                    }),
                    onReset: () => _setStateAnd(() {
                      _fontSizeScaleFS = 1.2;
                      if (_ctrl.isFullscreen) _recomputeTracks();
                    }),
                  ),
                  _buildSliderRow(
                    l10n,
                    label: l10n.danmakuFontWeight,
                    value: _fontWeight,
                    min: 0,
                    max: 8,
                    divisions: 8,
                    display: '${_fontWeight.round()}',
                    resetLabel: '6',
                    onChanged: (v) => _setStateAnd(() => _fontWeight = v),
                    onReset: () => _setStateAnd(() => _fontWeight = 6.0),
                  ),
                  _buildSliderRow(
                    l10n,
                    label: l10n.danmakuStrokeWidth,
                    value: _strokeWidth,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    display: _strokeWidth.toStringAsFixed(1),
                    resetLabel: '2.0',
                    onChanged: (v) => _setStateAnd(() => _strokeWidth = v),
                    onReset: () => _setStateAnd(() => _strokeWidth = 2.0),
                  ),
                  _buildSliderRow(
                    l10n,
                    label: l10n.danmakuShowArea,
                    value: _showArea,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    display: '${(_showArea * 100).toInt()}%',
                    resetLabel: '100%',
                    onChanged: (v) => _setStateAnd(() {
                      _showArea = v;
                      _recomputeTracks();
                    }),
                    onReset: () => _setStateAnd(() {
                      _showArea = 1.0;
                      _recomputeTracks();
                    }),
                  ),
                  _buildSliderRow(
                    l10n,
                    label: l10n.danmakuLineHeight,
                    value: _lineHeightScale,
                    min: 1.0,
                    max: 3.0,
                    divisions: 20,
                    display: _lineHeightScale.toStringAsFixed(1),
                    resetLabel: '1.6',
                    onChanged: (v) => _setStateAnd(() {
                      _lineHeightScale = v;
                      _recomputeTracks();
                    }),
                    onReset: () => _setStateAnd(() {
                      _lineHeightScale = 1.6;
                      _recomputeTracks();
                    }),
                  ),
                  _buildSliderRow(
                    l10n,
                    label: l10n.danmakuScrollDuration,
                    value: _scrollDuration,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    display: l10n.danmakuSeconds(_scrollDuration.toInt()),
                    resetLabel: l10n.danmakuSeconds(7),
                    onChanged: (v) => _setStateAnd(() => _scrollDuration = v),
                    onReset: () => _setStateAnd(() => _scrollDuration = 7.0),
                  ),
                  _buildSliderRow(
                    l10n,
                    label: l10n.danmakuStaticDuration,
                    value: _staticDuration,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    display: l10n.danmakuSeconds(_staticDuration.toInt()),
                    resetLabel: l10n.danmakuSeconds(4),
                    onChanged: (v) => _setStateAnd(() => _staticDuration = v),
                    onReset: () => _setStateAnd(() => _staticDuration = 4.0),
                  ),
                  _buildSliderRow(
                    l10n,
                    label: l10n.danmakuMaxLines,
                    value: _maxLines.toDouble(),
                    min: 3,
                    max: 24,
                    divisions: 21,
                    display: l10n.danmakuLinesCount(_maxLines),
                    resetLabel: l10n.danmakuLinesCount(12),
                    onChanged: (v) => _setStateAnd(() {
                      _maxLines = v.toInt();
                      _ctrl.lineHeight = _ctrl.screenHeight > 0
                          ? _ctrl.screenHeight / _maxLines
                          : 32.0;
                    }),
                    onReset: () => _setStateAnd(() {
                      _maxLines = 12;
                      _ctrl.lineHeight = _ctrl.screenHeight > 0
                          ? _ctrl.screenHeight / 12
                          : 32.0;
                    }),
                  ),

                               
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                    child: TextButton.icon(
                      onPressed: () {
                        _ctrl.reset();
                        _ctrl.onNeedRepaint?.call();
                      },
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: Text(l10n.danmakuClearDanmaku),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

                                 
  Widget _buildDmBlockRulesRow() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        SwitchListTile(
          title: Text(
            '云屏蔽词过滤',
            style: TextStyle(fontSize: 13, color: cs.onSurface),
          ),
          subtitle: Text(
            '按账号屏蔽词 / 正则 / 用户过滤拉取的弹幕',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          secondary: Icon(Icons.block, size: 18, color: cs.onSurfaceVariant),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          value: _dmBlockRules,
          onChanged: (v) {
            setState(() => _dmBlockRules = v);
            BilibiliDmBlockService.setRulesEnabled(v);
          },
        ),
        SwitchListTile(
          title: Text(
            '合并弹幕',
            style: TextStyle(fontSize: 13, color: cs.onSurface),
          ),
          subtitle: Text(
            '合并一段时间内获取到的相同弹幕',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          secondary: Icon(Icons.merge, size: 18, color: cs.onSurfaceVariant),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          value: _mergeDanmaku,
          onChanged: (v) {
            setState(() => _mergeDanmaku = v);
            DanmakuSegFetcher.setMergeDanmakuEnabled(v);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _openBlockManager,
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('屏蔽管理'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openBlockManager() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BilibiliDmBlockPage()),
    );
    if (!mounted) return;
                               
    setState(() => _dmBlockRules = BilibiliDmBlockService.rulesEnabled);
  }

                              
  Widget _buildCloudFilterRow(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            l10n.danmakuCloudFilter,
            style: TextStyle(fontSize: 13, color: cs.onSurface),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: MorphGlassDropdown<int>(
              value: _danmakuWeight,
              menuWidth: 160,
              items: [
                for (var level = 0; level <= 11; level++)
                  DropdownMenuItem(
                    value: level,
                    child: Text(
                      level == 0
                          ? l10n.danmakuCloudFilterOff
                          : l10n.danmakuCloudFilterLevel(level),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                _setStateAnd(() => _danmakuWeight = v);
              },
            ),
          ),
        ],
      ),
    );
  }

                  
  Widget _buildLoadButtons() {
    final l10n = AppLocalizations.of(context);
    if (widget.onLoadFile == null && widget.onFetchOnline == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          if (widget.onLoadFile != null)
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.folder_open, size: 16),
                label: Text(
                  l10n.danmakuLoadLocalXml,
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: widget.onLoadFile,
              ),
            ),
          if (widget.onLoadFile != null && widget.onFetchOnline != null)
            const SizedBox(width: 8),
          if (widget.onFetchOnline != null)
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.cloud_download, size: 16),
                label: Text(
                  l10n.danmakuFetchOnline,
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: widget.onFetchOnline,
              ),
            ),
        ],
      ),
    );
  }

                   
  Widget _buildDanmakuInfo() {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final count = _ctrl.itemCount;
    if (count == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Text(
          l10n.danmakuNotLoaded,
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 13, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            l10n.danmakuLoadedCount(count),
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

                 
  Widget _buildSectionHeader(String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 4, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow(
    AppLocalizations l10n, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required String resetLabel,
    required ValueChanged<double> onChanged,
    required VoidCallback onReset,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$label $display',
                    style: TextStyle(fontSize: 13, color: cs.onSurface),
                  ),
                ),
                AppTooltip(
                  message: l10n.danmakuResetTo(resetLabel),
                  child: IconButton(
                    icon: Icon(
                      Icons.refresh,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: onReset,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
