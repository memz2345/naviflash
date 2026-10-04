import 'package:flutter/material.dart';
import 'package:naviflash/screens/bilibili_dm_block_page.dart';
import 'package:naviflash/services/bilibili_dm_block_service.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'danmaku_controller.dart';
import 'danmaku_fetcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/onnx_dependency_service.dart';
import '../../widgets/app_toast.dart';

class DanmakuSettingsPanel extends StatefulWidget {
  final DanmakuController controller;
  final VoidCallback onClose;
  final VoidCallback? onLoadFile;
  final VoidCallback? onFetchOnline;

                                  
                                  
     
                                     
                    
  final bool embedded;

  const DanmakuSettingsPanel({
    super.key,
    required this.controller,
    required this.onClose,
    this.onLoadFile,
    this.onFetchOnline,
    this.embedded = false,
  });

  @override
  State<DanmakuSettingsPanel> createState() => _DanmakuSettingsPanelState();
}

class _DanmakuSettingsPanelState extends State<DanmakuSettingsPanel> {

                
    
                                    
                                             
  bool get _themed => widget.embedded;
  ColorScheme get _cs => Theme.of(context).colorScheme;

                
  Color get _fg => _themed ? _cs.onSurface : Colors.white;

                  
  Color get _fgMuted => _themed ? _cs.onSurfaceVariant : Colors.white70;

              
  Color get _fgFaint =>
      _themed ? _cs.onSurfaceVariant.withValues(alpha: 0.75) : Colors.white38;

          
  Color get _line => _themed ? _cs.outlineVariant : Colors.white24;

                    
  Color get _lineFaint =>
      _themed ? _cs.outlineVariant.withValues(alpha: 0.6) : Colors.white12;

                     
  Color get _fill =>
      _themed ? _cs.surfaceContainerHighest : Colors.white10;

         
  Color get _border => _themed ? _cs.outlineVariant : Colors.white30;

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
  void didUpdateWidget(DanmakuSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _syncFromController();
    }
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
  }

  void _recomputeTracks() {
    if (_ctrl.screenWidth > 0 && _ctrl.screenHeight > 0) {
      _ctrl.setSize(_ctrl.screenWidth, _ctrl.screenHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                                   
          if (!widget.embedded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.subtitles,
                        color: Colors.blueAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.danmakuSettingsTitle,
                        style: TextStyle(
                          color: _fg,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _fgMuted),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Divider(color: _line, height: 1),
          ],

                      
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                
                  _buildSectionHeader(l10n.danmakuDataSource),
                  _buildLoadButtons(),
                  const SizedBox(height: 4),
                  _buildDanmakuInfo(),

                  Divider(color: _lineFaint, height: 24),

                                
                  _buildSectionHeader(l10n.danmakuDisplayControl),
                  SwitchListTile(
                    title: Text(l10n.danmakuEnable,
                        style: TextStyle(color: _fg, fontSize: 14)),
                    value: _enabled,
                    activeThumbColor: Colors.blueAccent,
                    dense: true,
                    onChanged: (v) => setState(() {
                      _enabled = v;
                      _apply();
                    }),
                  ),
                  SwitchListTile(
                    title: Text(l10n.danmakuSmartMask,
                        style: TextStyle(color: _fg, fontSize: 14)),
                    subtitle: Text(l10n.danmakuSmartMaskDesc,
                        style:
                            TextStyle(color: _fgMuted, fontSize: 11)),
                    value: _smartMask,
                    activeThumbColor: Colors.blueAccent,
                    dense: true,
                    onChanged: (v) => setState(() {
                      if (v && !_ensureSmartMaskDep()) return;
                      _smartMask = v;
                      _apply();
                    }),
                  ),

                  Divider(color: _lineFaint, height: 24),

                  _buildSectionHeader(l10n.danmakuCloudFilter),
                  _buildCloudFilterRow(l10n),
                  _buildDmBlockRulesRow(),

                  Divider(color: _lineFaint, height: 24),

                                 
                  _buildSectionHeader(l10n.danmakuTypeFilter),
                  _buildTypeSwitch(
                    icon: Icons.arrow_forward,
                    label: l10n.danmakuTypeScroll,
                    value: _showScroll,
                    onChanged: (v) => setState(() {
                      _showScroll = v;
                      _apply();
                    }),
                  ),
                  _buildTypeSwitch(
                    icon: Icons.vertical_align_top,
                    label: l10n.danmakuTypeTop,
                    value: _showTop,
                    onChanged: (v) => setState(() {
                      _showTop = v;
                      _apply();
                    }),
                  ),
                  _buildTypeSwitch(
                    icon: Icons.vertical_align_bottom,
                    label: l10n.danmakuTypeBottom,
                    value: _showBottom,
                    onChanged: (v) => setState(() {
                      _showBottom = v;
                      _apply();
                    }),
                  ),
                  _buildTypeSwitch(
                    icon: Icons.animation,
                    label: l10n.danmakuTypeAdvanced,
                    subtitle: l10n.danmakuAdvancedSubtitle,
                    value: _showAdvanced,
                    activeColor: Colors.orangeAccent,
                    onChanged: (v) => setState(() {
                      _showAdvanced = v;
                      if (!v) {
                        _ctrl.activeBasDanmakus.clear();
                      }
                      _apply();
                    }),
                  ),
                  _buildTypeSwitch(
                    icon: Icons.palette_outlined,
                    label: l10n.danmakuBlockColorful,
                    value: _blockColorful,
                    onChanged: (v) => setState(() {
                      _blockColorful = v;
                      _apply();
                    }),
                  ),

                  Divider(color: _lineFaint, height: 24),

                                 
                  _buildSectionHeader(l10n.danmakuParameters),

                       
                  _buildSlider(
                    icon: Icons.speed,
                    label: l10n.danmakuScrollSpeed,
                    value: _speed,
                    min: 0.2,
                    max: 3.0,
                    divisions: 14,
                    format: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) => setState(() {
                      _speed = v;
                      _apply();
                    }),
                  ),

                        
                  _buildSlider(
                    icon: Icons.opacity,
                    label: l10n.danmakuOpacity,
                    value: _opacity,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    format: (v) => '${(v * 100).toInt()}%',
                    onChanged: (v) => setState(() {
                      _opacity = v;
                      _apply();
                    }),
                  ),

                              
                  _buildSlider(
                    icon: Icons.format_size,
                    label: l10n.danmakuFontSize,
                    value: _fontSizeScale,
                    min: 0.5,
                    max: 2.5,
                    divisions: 20,
                    format: (v) => '${(v * 100).toInt()}%',
                    onChanged: (v) => setState(() {
                      _fontSizeScale = v;
                      _apply();
                      _recomputeTracks();
                    }),
                  ),

                           
                  _buildSlider(
                    icon: Icons.fullscreen,
                    label: l10n.danmakuFontSizeFS,
                    value: _fontSizeScaleFS,
                    min: 0.5,
                    max: 2.5,
                    divisions: 20,
                    format: (v) => '${(v * 100).toInt()}%',
                    onChanged: (v) => setState(() {
                      _fontSizeScaleFS = v;
                      _apply();
                      if (_ctrl.isFullscreen) _recomputeTracks();
                    }),
                  ),

                         
                  _buildSlider(
                    icon: Icons.format_bold,
                    label: l10n.danmakuFontWeight,
                    value: _fontWeight,
                    min: 0,
                    max: 8,
                    divisions: 8,
                    format: (v) => '${v.round()}',
                    onChanged: (v) => setState(() {
                      _fontWeight = v;
                      _apply();
                    }),
                  ),

                         
                  _buildSlider(
                    icon: Icons.border_color,
                    label: l10n.danmakuStrokeWidth,
                    value: _strokeWidth,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    format: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() {
                      _strokeWidth = v;
                      _apply();
                    }),
                  ),

                         
                  _buildSlider(
                    icon: Icons.vertical_split,
                    label: l10n.danmakuShowArea,
                    value: _showArea,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    format: (v) => '${(v * 100).toInt()}%',
                    onChanged: (v) => setState(() {
                      _showArea = v;
                      _apply();
                      _recomputeTracks();
                    }),
                  ),

                         
                  _buildSlider(
                    icon: Icons.format_line_spacing,
                    label: l10n.danmakuLineHeight,
                    value: _lineHeightScale,
                    min: 1.0,
                    max: 3.0,
                    divisions: 20,
                    format: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() {
                      _lineHeightScale = v;
                      _apply();
                      _recomputeTracks();
                    }),
                  ),

                           
                  _buildSlider(
                    icon: Icons.timelapse,
                    label: l10n.danmakuScrollDuration,
                    value: _scrollDuration,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    format: (v) => l10n.danmakuSeconds(v.toInt()),
                    onChanged: (v) => setState(() {
                      _scrollDuration = v;
                      _apply();
                    }),
                  ),

                           
                  _buildSlider(
                    icon: Icons.pause_circle_outline,
                    label: l10n.danmakuStaticDuration,
                    value: _staticDuration,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    format: (v) => l10n.danmakuSeconds(v.toInt()),
                    onChanged: (v) => setState(() {
                      _staticDuration = v;
                      _apply();
                    }),
                  ),

                       
                  _buildSlider(
                    icon: Icons.view_agenda_outlined,
                    label: l10n.danmakuMaxLines,
                    value: _maxLines.toDouble(),
                    min: 3,
                    max: 24,
                    divisions: 21,
                    format: (v) => l10n.danmakuLinesCount(v.toInt()),
                    onChanged: (v) => setState(() {
                      _maxLines = v.toInt();
                      _ctrl.lineHeight =
                          _ctrl.screenHeight > 0 ? _ctrl.screenHeight / _maxLines : 32.0;
                      _apply();
                    }),
                  ),

                  Divider(color: _lineFaint, height: 24),

                               
                  _buildSectionHeader(l10n.danmakuOthers),
                  _buildTypeSwitch(
                    icon: Icons.density_medium,
                    label: l10n.danmakuMassiveMode,
                    value: _massiveMode,
                    onChanged: (v) => setState(() {
                      _massiveMode = v;
                      _apply();
                      _recomputeTracks();
                    }),
                  ),
                  _buildTypeSwitch(
                    icon: Icons.swap_horiz,
                    label: l10n.danmakuStatic2Scroll,
                    value: _static2Scroll,
                    onChanged: (v) => setState(() {
                      _static2Scroll = v;
                      _apply();
                    }),
                  ),

                  const SizedBox(height: 16),

                                 
                  _buildSectionHeader(l10n.danmakuQuickActions),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChip(
                          label: l10n.danmakuResetParams,
                          icon: Icons.restore,
                          onTap: () {
                            setState(() {
                              _speed = 1.0;
                              _opacity = 1.0;
                              _fontSizeScale = 1.0;
                              _fontSizeScaleFS = 1.2;
                              _fontWeight = 6.0;
                              _strokeWidth = 2.0;
                              _showArea = 1.0;
                              _lineHeightScale = 1.6;
                              _scrollDuration = 7.0;
                              _staticDuration = 4.0;
                              _maxLines = 12;
                              _danmakuWeight = 0;
                              _enabled = true;
                              _showScroll = true;
                              _showTop = true;
                              _showBottom = true;
                              _showAdvanced = false;
                              _massiveMode = false;
                              _static2Scroll = false;
                              _blockColorful = false;
                              _ctrl.activeBasDanmakus.clear();
                              _ctrl.lineHeight = _ctrl.screenHeight > 0
                                  ? _ctrl.screenHeight / 12
                                  : 32.0;
                              _apply();
                              _recomputeTracks();
                            });
                          },
                        ),
                        _buildChip(
                          label: l10n.danmakuClearDanmaku,
                          icon: Icons.delete_sweep,
                          onTap: () {
                            _ctrl.reset();
                            _ctrl.onNeedRepaint?.call();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

                                 
  Widget _buildDmBlockRulesRow() {
    return Column(
      children: [
        SwitchListTile(
          secondary: Icon(Icons.block, color: _fgMuted, size: 20),
          title: Text('云屏蔽词过滤', style: TextStyle(color: _fg, fontSize: 14)),
          subtitle: Text(
            '按账号屏蔽词 / 正则 / 用户过滤拉取的弹幕',
            style: TextStyle(color: _fgMuted, fontSize: 11),
          ),
          value: _dmBlockRules,
          activeThumbColor: Colors.blueAccent,
          dense: true,
          onChanged: (v) {
            setState(() => _dmBlockRules = v);
            BilibiliDmBlockService.setRulesEnabled(v);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.merge, color: _fgMuted, size: 20),
          title: Text('合并弹幕', style: TextStyle(color: _fg, fontSize: 14)),
          subtitle: Text(
            '合并一段时间内获取到的相同弹幕',
            style: TextStyle(color: _fgMuted, fontSize: 11),
          ),
          value: _mergeDanmaku,
          activeThumbColor: Colors.blueAccent,
          dense: true,
          onChanged: (v) {
            setState(() => _mergeDanmaku = v);
            DanmakuSegFetcher.setMergeDanmakuEnabled(v);
          },
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _openBlockManager,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.tune, color: _fgMuted, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '屏蔽管理',
                    style: TextStyle(color: _fg, fontSize: 14),
                  ),
                ),
                Icon(Icons.chevron_right, color: _fgMuted, size: 20),
              ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: _fgMuted, size: 20),
          const SizedBox(width: 8),
          Text(
            l10n.danmakuCloudFilter,
            style: TextStyle(color: _fg, fontSize: 14),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _fill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _line),
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
                        color: _fg,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _danmakuWeight = v;
                  _apply();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

                  
  Widget _buildLoadButtons() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          if (widget.onLoadFile != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.folder_open, size: 18),
                label: Text(l10n.danmakuLoadLocalXml),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _fg,
                  side: BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: widget.onLoadFile,
              ),
            ),
          const SizedBox(height: 8),
          if (widget.onFetchOnline != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.cloud_download, size: 18),
                label: Text(l10n.danmakuFetchOnline),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
    final count = _ctrl.itemCount;
    if (count == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          l10n.danmakuNotLoaded,
          style: TextStyle(color: _fgFaint, fontSize: 12),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: _fgFaint, size: 14),
          const SizedBox(width: 6),
          Text(
            l10n.danmakuLoadedCount(count),
            style: TextStyle(color: _fgMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

                 
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          color: _fgFaint,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

                  
  Widget _buildTypeSwitch({
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    Color activeColor = Colors.blueAccent,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: _fgMuted, size: 20),
      title: Text(label, style: TextStyle(color: _fg, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: _fgFaint, fontSize: 11))
          : null,
      value: value,
      activeThumbColor: activeColor,
      dense: true,
      onChanged: onChanged,
    );
  }

                
  Widget _buildSlider({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) format,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _fgMuted, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: _fg, fontSize: 13)),
              const Spacer(),
              Text(
                format(value),
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: Colors.blueAccent,
              inactiveTrackColor: _lineFaint,
              thumbColor: _fg,
              overlayColor: Colors.blueAccent.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

                      
  Widget _buildChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: _fgMuted),
      label: Text(label, style: TextStyle(color: _fgMuted, fontSize: 12)),
      backgroundColor: _fill,
      side: BorderSide(color: _line),
      onPressed: onTap,
    );
  }
}
