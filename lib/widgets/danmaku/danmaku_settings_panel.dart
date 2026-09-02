import 'package:flutter/material.dart';
import 'danmaku_controller.dart';
import '../../l10n/app_localizations.dart';

class DanmakuSettingsPanel extends StatefulWidget {
  final DanmakuController controller;
  final VoidCallback onClose;
  final VoidCallback? onLoadFile;
  final VoidCallback? onFetchOnline;

  const DanmakuSettingsPanel({
    super.key,
    required this.controller,
    required this.onClose,
    this.onLoadFile,
    this.onFetchOnline,
  });

  @override
  State<DanmakuSettingsPanel> createState() => _DanmakuSettingsPanelState();
}

class _DanmakuSettingsPanelState extends State<DanmakuSettingsPanel> {
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

  DanmakuController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _syncFromController();
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
          // ── 标题栏 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.subtitles, color: Colors.blueAccent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      l10n.danmakuSettingsTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),

          // ── 内容区 ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ━━━ 数据源 ━━━
                  _buildSectionHeader(l10n.danmakuDataSource),
                  _buildLoadButtons(),
                  const SizedBox(height: 4),
                  _buildDanmakuInfo(),

                  const Divider(color: Colors.white12, height: 24),

                  // ━━━ 总开关 ━━━
                  _buildSectionHeader(l10n.danmakuDisplayControl),
                  SwitchListTile(
                    title: Text(l10n.danmakuEnable,
                        style: const TextStyle(color: Colors.white, fontSize: 14)),
                    value: _enabled,
                    activeColor: Colors.blueAccent,
                    dense: true,
                    onChanged: (v) => setState(() {
                      _enabled = v;
                      _apply();
                    }),
                  ),
                  SwitchListTile(
                    title: Text(l10n.danmakuSmartMask,
                        style: const TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text(l10n.danmakuSmartMaskDesc,
                        style:
                            const TextStyle(color: Colors.white54, fontSize: 11)),
                    value: _smartMask,
                    activeColor: Colors.blueAccent,
                    dense: true,
                    onChanged: (v) => setState(() {
                      _smartMask = v;
                      _apply();
                    }),
                  ),

                  const Divider(color: Colors.white12, height: 24),

                  _buildSectionHeader(l10n.danmakuCloudFilter),
                  _buildCloudFilterRow(l10n),

                  const Divider(color: Colors.white12, height: 24),

                  // ━━━ 类型过滤 ━━━
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

                  const Divider(color: Colors.white12, height: 24),

                  // ━━━ 参数调节 ━━━
                  _buildSectionHeader(l10n.danmakuParameters),

                  // 速度
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

                  // 透明度
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

                  // 字体大小（非全屏）
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

                  // 全屏字体大小
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

                  // 字体粗细
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

                  // 描边粗细
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

                  // 显示区域
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

                  // 弹幕行高
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

                  // 滚动弹幕时长
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

                  // 静态弹幕时长
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

                  // 行数
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

                  const Divider(color: Colors.white12, height: 24),

                  // ━━━ 其他 ━━━
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

                  // ━━━ 快捷操作 ━━━
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

  // ─── 智能云屏蔽（下拉菜单，0~11 级）───
  Widget _buildCloudFilterRow(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Colors.white54, size: 20),
          const SizedBox(width: 8),
          Text(
            l10n.danmakuCloudFilter,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: DropdownButton<int>(
              value: _danmakuWeight,
              dropdownColor: const Color(0xFF2A2A2C),
              underline: const SizedBox.shrink(),
              iconEnabledColor: Colors.white70,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              items: [
                for (var level = 0; level <= 11; level++)
                  DropdownMenuItem(
                    value: level,
                    child: Text(
                      level == 0
                          ? l10n.danmakuCloudFilterOff
                          : l10n.danmakuCloudFilterLevel(level),
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

  // ─── 数据源按钮 ───
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
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
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

  // ─── 当前弹幕信息 ───
  Widget _buildDanmakuInfo() {
    final l10n = AppLocalizations.of(context);
    final count = _ctrl.itemCount;
    if (count == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          l10n.danmakuNotLoaded,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white38, size: 14),
          const SizedBox(width: 6),
          Text(
            l10n.danmakuLoadedCount(count),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─── 分区标题 ───
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ─── 类型开关行 ───
  Widget _buildTypeSwitch({
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    Color activeColor = Colors.blueAccent,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.white54, size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11))
          : null,
      value: value,
      activeColor: activeColor,
      dense: true,
      onChanged: onChanged,
    );
  }

  // ─── 滑块行 ───
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
              Icon(icon, color: Colors.white54, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
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
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: Colors.blueAccent.withOpacity(0.15),
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

  // ─── 快捷操作 Chip ───
  Widget _buildChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: Colors.white70),
      label: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      backgroundColor: Colors.white10,
      side: const BorderSide(color: Colors.white24),
      onPressed: onTap,
    );
  }
}
