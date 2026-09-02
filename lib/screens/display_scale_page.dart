// lib/screens/display_scale_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/widgets.dart';
import '../widgets/page_background.dart';

class DisplayScalePage extends StatefulWidget {
  const DisplayScalePage({super.key});

  @override
  State<DisplayScalePage> createState() => _DisplayScalePageState();
}

class _DisplayScalePageState extends State<DisplayScalePage> {
  late double _scale;

  static const double _minScale = 0.50;
  static const double _maxScale = 2.00;
  static const double _step = 0.05;

  static const List<_ScalePreset> _presets = [
    _ScalePreset(label: '50%', value: 0.50),
    _ScalePreset(label: '75%', value: 0.75),
    _ScalePreset(label: '100%', value: 1.00),
    _ScalePreset(label: '125%', value: 1.25),
    _ScalePreset(label: '150%', value: 1.50),
    _ScalePreset(label: '200%', value: 2.00),
  ];

  /// 静态示例内容（纯展示）：仅用于预览文字 / 布局缩放效果，
  /// 不依赖任何聊天 / 连接数据。
  static const List<({String title, String subtitle, IconData icon})>
      _sampleItems = [
    (
      title: '视频标题示例',
      subtitle: '视频简介文字示例：用于预览界面文字随缩放比例的变化。',
      icon: Icons.play_circle_outline,
    ),
    (
      title: '示例合集 · 播放列表',
      subtitle: '第 3 集 / 共 12 集 · 连载中 · 双语字幕',
      icon: Icons.video_library_outlined,
    ),
    (
      title: '简介文字示例',
      subtitle: '较长的简介文字会自动换行或省略，方便检查缩放后的排版效果。',
      icon: Icons.closed_caption_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scale = context.read<SettingsService>().displayScale;
  }

  void _applyScale(double value) {
    final clamped = value.clamp(_minScale, _maxScale);
    setState(() => _scale = clamped);
    context.read<SettingsService>().setDisplayScale(clamped);
  }

  void _resetToDefault() => _applyScale(1.0);

  String _scaleDescription(AppLocalizations l10n) {
    if (_scale < 0.75) return l10n.displayScaleCompact;
    if (_scale < 1.0) return l10n.displayScaleSmall;
    if (_scale == 1.0) return l10n.displayScaleDefault;
    if (_scale <= 1.25) return l10n.displayScaleLarge;
    if (_scale <= 1.5) return l10n.displayScaleLargeFont;
    return l10n.displayScaleHuge;
  }

  String _scaleHint(double v, AppLocalizations l10n) {
    if (v <= 0.50) return l10n.displayScaleMin;
    if (v <= 0.75) return l10n.displayScaleCompactBig;
    if (v <= 1.00) return l10n.displayScaleSystemDefault;
    if (v <= 1.25) return l10n.displayScaleLarge;
    if (v <= 1.50) return l10n.displayScaleLargeFontShort;
    return l10n.displayScaleHuge;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer),
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              ExpressiveSliverAppBar(
                title: l10n.displayScaleTitle,
                leading: MorphIconButton(
                  icon: Icons.arrow_back,
                  tooltip: l10n.commonBackTooltip,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: MorphIconButton(
                      icon: Icons.restart_alt,
                      tooltip: l10n.displayScaleReset,
                      onTap: _resetToDefault,
                    ),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ===== 预览 Hero 卡 =====
                    _buildPreviewCard(cs, theme.textTheme),

                    const SizedBox(height: 24),

                    _buildSectionTitle(context, l10n.displayScaleFineTune),
                    const SizedBox(height: 12),

                    MorphItem(
                      selected: false,
                      isFirst: true,
                      isLast: true,
                      interactive: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.zoom_in,
                                  size: 20,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Slider(
                                    value: _scale,
                                    min: _minScale,
                                    max: _maxScale,
                                    divisions: ((_maxScale - _minScale) / _step)
                                        .round(),
                                    label: '${(_scale * 100).round()}%',
                                    activeColor: cs.primary,
                                    inactiveColor: cs.surfaceContainerHighest,
                                    onChanged: _applyScale,
                                  ),
                                ),
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    '${(_scale * 100).round()}%',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '50%',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '200%',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    _buildSectionTitle(context, l10n.displayScalePresets),
                    const SizedBox(height: 12),

                    ...buildMorphSegmentedList(
                      _presets.map((p) {
                        final isSelected = (_scale - p.value).abs() < 0.001;
                        return MorphRowItem(
                          interactive: true,
                          child: InkWell(
                            onTap: () => _applyScale(p.value),
                            borderRadius: BorderRadius.circular(
                              kItemPressedRadius,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? cs.primaryContainer
                                          : cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(
                                        kItemRadius,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'A',
                                        style: TextStyle(
                                          fontSize: 12 + p.value * 6,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? cs.onPrimaryContainer
                                              : cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.label,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _scaleHint(p.value, l10n),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedOpacity(
                                    opacity: isSelected ? 1 : 0,
                                    duration: kMorphDuration,
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 22,
                                      color: cs.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    ...buildMorphSegmentedList([
                      MorphRowItem(
                        interactive: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.displayScaleNote,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(ColorScheme cs, TextTheme textTheme) {
    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(kGroupRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 上半：主色背景 + 缩放数字 ──
          Container(
            color: cs.primary,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(_scale)),
              child: Column(
                children: [
                  AnimatedDefaultTextStyle(
                    duration: kMorphDuration,
                    curve: kMorphCurve,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimary,
                      height: 1.1,
                    ),
                    child: Text('${(_scale * 100).round()}%'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _scaleDescription(l10n),
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 下半：静态示例内容预览（纯展示，不可点击） ──
          Container(
            color: cs.surfaceBright,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(_scale)),
              child: Column(
                children: _sampleItems
                    .map((s) => _buildSampleTile(s, cs, textTheme))
                    .toList(),
              ),
            ),
          ),

          // ── 底栏：参数信息 ──
          Container(
            color: cs.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'textScaler: ${_scale.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: cs.primary.withOpacity(0.6),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 预览列表项（纯静态展示） =================
  Widget _buildSampleTile(
    ({String title, String subtitle, IconData icon}) sample,
    ColorScheme cs,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.primaryContainer,
            radius: 22,
            child: Icon(sample.icon, size: 22, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sample.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sample.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: cs.onSurfaceVariant.withOpacity(0.4),
          ),
        ],
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
}

class _ScalePreset {
  final String label;
  final double value;
  const _ScalePreset({required this.label, required this.value});
}
