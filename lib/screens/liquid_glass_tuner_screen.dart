// lib/screens/liquid_glass_tuner_screen.dart
//
// 液态玻璃调校页：实时预览 + 滑块调节 LiquidGlassSettings 全部材质参数。
//   - 滑块改动即时生效：本地状态驱动预览玻璃，同时写入 SettingsService
//     （全局应用：NaviGlass 未显式传参时读取 SettingsService 静态镜像）；
//   - 预览区：彩色渐变背景 + 圆形 / 圆角方形 / 胶囊玻璃 + （Impeller 下）
//     两个融合玻璃，直观展示折射、模糊、着色、高光等效果；
//   - 非 Impeller 平台（Windows/Linux/Web）自动展示 FakeGlass 降级预览，
//     并提示厚度/折射率/饱和度等参数仅移动端生效。
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../services/settings_service.dart';
import '../widgets/widgets.dart';
import '../widgets/page_background.dart';
import '../widgets/liquid_glass.dart';
import '../l10n/app_localizations.dart';

class LiquidGlassTunerScreen extends StatefulWidget {
  const LiquidGlassTunerScreen({super.key});

  @override
  State<LiquidGlassTunerScreen> createState() => _LiquidGlassTunerScreenState();
}

class _LiquidGlassTunerScreenState extends State<LiquidGlassTunerScreen> {
  late double _thickness;
  late double _blur;
  late double _tintOpacity;
  late double _saturation;
  late double _refractiveIndex;
  late double _lightIntensity;
  late double _ambientStrength;
  late double _lightAngleDeg;
  late double _chromaticAberration;

  bool get _advanced =>
      SettingsService.fragmentRenderingEnabled &&
      ui.ImageFilter.isShaderFilterSupported;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsService>();
    _thickness = s.liquidGlassThicknessValue;
    _blur = s.liquidGlassBlurValue;
    _tintOpacity = s.liquidGlassTintOpacityValue;
    _saturation = s.liquidGlassSaturationValue;
    _refractiveIndex = s.liquidGlassRefractiveIndexValue;
    _lightIntensity = s.liquidGlassLightIntensityValue;
    _ambientStrength = s.liquidGlassAmbientStrengthValue;
    _lightAngleDeg = s.liquidGlassLightAngleValue * 180 / math.pi;
    _chromaticAberration = s.liquidGlassChromaticAberrationValue;
  }

  /// 预览用 LiquidGlassSettings（与 NaviGlass 全局读取同源参数）。
  LiquidGlassSettings get _previewSettings => LiquidGlassSettings(
    glassColor: Color.from(alpha: _tintOpacity, red: 1, green: 1, blue: 1),
    thickness: _thickness,
    blur: _blur,
    lightAngle: _lightAngleDeg * math.pi / 180,
    lightIntensity: _lightIntensity,
    ambientStrength: _ambientStrength,
    refractiveIndex: _refractiveIndex,
    saturation: _saturation,
    chromaticAberration: _chromaticAberration,
  );

  void _apply(void Function() mutate, void Function() persist) {
    setState(mutate);
    persist();
  }

  Future<void> _persist() =>
      context.read<SettingsService>().setLiquidGlassTuning(
        thickness: _thickness,
        blur: _blur,
        tintOpacity: _tintOpacity,
        saturation: _saturation,
        refractiveIndex: _refractiveIndex,
        lightIntensity: _lightIntensity,
        ambientStrength: _ambientStrength,
        lightAngle: _lightAngleDeg * math.pi / 180,
        chromaticAberration: _chromaticAberration,
      );

  void _resetToDefault() {
    _apply(() {
      _thickness = 20.0;
      _blur = 10.0;
      _tintOpacity = 0.0;
      _saturation = 1.0;
      _refractiveIndex = 1.3;
      _lightIntensity = 0.0;
      _ambientStrength = 0.0;
      _lightAngleDeg = 90.0;
      _chromaticAberration = 0.02;
    }, _persist);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                title: l10n.displayLiquidGlassTuner,
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
                      tooltip: l10n.lgTunerReset,
                      onTap: _resetToDefault,
                    ),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionTitle(context, l10n.lgTunerPreview),
                    const SizedBox(height: 12),
                    _buildPreview(cs, l10n),

                    if (!_advanced) ...[
                      const SizedBox(height: 12),
                      _buildFallbackNote(cs, l10n),
                    ],

                    const SizedBox(height: 24),

                    _buildSectionTitle(context, l10n.lgTunerSectionMaterial),
                    const SizedBox(height: 12),
                    _buildSlider(
                      icon: Icons.layers_outlined,
                      label: l10n.lgTunerThickness,
                      value: _thickness,
                      min: 0,
                      max: 50,
                      divisions: 50,
                      valueText: _thickness.round().toString(),
                      onChanged: (v) => _apply(() => _thickness = v, _persist),
                    ),
                    _buildSlider(
                      icon: Icons.blur_on_outlined,
                      label: l10n.lgTunerBlur,
                      value: _blur,
                      min: 0,
                      max: 40,
                      divisions: 40,
                      valueText: _blur.round().toString(),
                      onChanged: (v) => _apply(() => _blur = v, _persist),
                    ),
                    _buildSlider(
                      icon: Icons.opacity_outlined,
                      label: l10n.lgTunerTint,
                      value: _tintOpacity,
                      min: 0,
                      max: 1,
                      divisions: 100,
                      valueText: '${(_tintOpacity * 100).round()}%',
                      onChanged: (v) =>
                          _apply(() => _tintOpacity = v, _persist),
                    ),
                    _buildSlider(
                      icon: Icons.color_lens_outlined,
                      label: l10n.lgTunerSaturation,
                      value: _saturation,
                      min: 0.4,
                      max: 2.0,
                      divisions: 32,
                      valueText: _saturation.toStringAsFixed(2),
                      onChanged: (v) => _apply(() => _saturation = v, _persist),
                    ),
                    _buildSlider(
                      icon: Icons.wb_iridescent_outlined,
                      label: l10n.lgTunerRefractiveIndex,
                      value: _refractiveIndex,
                      min: 1.0,
                      max: 1.6,
                      divisions: 60,
                      valueText: _refractiveIndex.toStringAsFixed(2),
                      onChanged: (v) =>
                          _apply(() => _refractiveIndex = v, _persist),
                    ),
                    _buildSlider(
                      icon: Icons.highlight_outlined,
                      label: l10n.lgTunerLightIntensity,
                      value: _lightIntensity,
                      min: 0,
                      max: 2.0,
                      divisions: 40,
                      valueText: _lightIntensity.toStringAsFixed(2),
                      onChanged: (v) =>
                          _apply(() => _lightIntensity = v, _persist),
                    ),
                    _buildSlider(
                      icon: Icons.light_mode_outlined,
                      label: l10n.lgTunerAmbient,
                      value: _ambientStrength,
                      min: 0,
                      max: 1.0,
                      divisions: 40,
                      valueText: _ambientStrength.toStringAsFixed(2),
                      onChanged: (v) =>
                          _apply(() => _ambientStrength = v, _persist),
                    ),
                    _buildSlider(
                      icon: Icons.explore_outlined,
                      label: l10n.lgTunerLightAngle,
                      value: _lightAngleDeg,
                      min: 0,
                      max: 360,
                      divisions: 72,
                      valueText: '${_lightAngleDeg.round()}°',
                      onChanged: (v) =>
                          _apply(() => _lightAngleDeg = v, _persist),
                    ),
                    _buildSlider(
                      icon: Icons.waves_outlined,
                      label: l10n.lgTunerAberration,
                      value: _chromaticAberration,
                      min: 0,
                      max: 0.1,
                      divisions: 50,
                      valueText: _chromaticAberration.toStringAsFixed(3),
                      onChanged: (v) =>
                          _apply(() => _chromaticAberration = v, _persist),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceBright,
                        borderRadius: BorderRadius.circular(kGroupRadius),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 18, color: cs.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.lgTunerNote,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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


  Widget _buildPreview(ColorScheme cs, AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(kGroupRadius),
      child: Container(
        height: 260,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E88E5),
              Color(0xFF7C4DFF),
              Color(0xFF00BCD4),
              Color(0xFFEC407A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── 背景色块（玻璃折射 / 模糊的素材） ──
            Positioned(
              top: -40,
              left: -30,
              child: _glowBall(120, const Color(0xFFFFC107)),
            ),
            Positioned(
              top: 30,
              right: -50,
              child: _glowBall(150, const Color(0xFF4CAF50)),
            ),
            Positioned(
              bottom: -50,
              right: 60,
              child: _glowBall(130, const Color(0xFF03A9F4)),
            ),
            Positioned(
              top: 12,
              left: 16,
              child: Text(
                'Liquid Glass',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),

            // ── 融合玻璃组（仅 Impeller 展示真实融合） ──
            if (_advanced)
              Positioned(
                top: 84,
                left: 24,
                child: LiquidGlassLayer(
                  settings: _previewSettings,
                  child: LiquidGlassBlendGroup(
                    blend: 24,
                    child: SizedBox(
                      width: 108,
                      height: 60,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 2,
                            child: AdaptiveGlass.grouped(
                              shape: const LiquidOval(),
                              quality: GlassQuality.premium,
                              child: const SizedBox.square(dimension: 56),
                            ),
                          ),
                          Positioned(
                            left: 48,
                            top: 2,
                            child: AdaptiveGlass.grouped(
                              shape: const LiquidOval(),
                              quality: GlassQuality.premium,
                              child: const SizedBox.square(dimension: 56),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── 圆形按钮 ──
            Positioned(
              bottom: 20,
              left: 20,
              child: NaviGlass(
                radius: 32,
                circle: true,
                blur: _blur,
                thickness: _thickness,
                lightIntensity: _lightIntensity,
                tintOpacity: _tintOpacity,
                saturation: _saturation,
                refractiveIndex: _refractiveIndex,
                ambientStrength: _ambientStrength,
                lightAngle: _lightAngleDeg * math.pi / 180,
                chromaticAberration: _chromaticAberration,
                child: SizedBox.square(
                  dimension: 64,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // ── 圆角方形 ──
            Positioned(
              bottom: 20,
              left: 110,
              child: NaviGlass(
                radius: 22,
                blur: _blur,
                thickness: _thickness,
                lightIntensity: _lightIntensity,
                tintOpacity: _tintOpacity,
                saturation: _saturation,
                refractiveIndex: _refractiveIndex,
                ambientStrength: _ambientStrength,
                lightAngle: _lightAngleDeg * math.pi / 180,
                chromaticAberration: _chromaticAberration,
                child: SizedBox.square(
                  dimension: 96,
                  child: Center(
                    child: Text(
                      'Aa',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── 胶囊 ──
            Positioned(
              top: 96,
              right: 20,
              child: NaviGlass(
                radius: 26,
                blur: _blur,
                thickness: _thickness,
                lightIntensity: _lightIntensity,
                tintOpacity: _tintOpacity,
                saturation: _saturation,
                refractiveIndex: _refractiveIndex,
                ambientStrength: _ambientStrength,
                lightAngle: _lightAngleDeg * math.pi / 180,
                chromaticAberration: _chromaticAberration,
                child: SizedBox(
                  width: 168,
                  height: 52,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Capsule',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowBall(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _buildFallbackNote(ColorScheme cs, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(kItemRadius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: cs.onTertiaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.lgTunerFallbackNote,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: cs.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSlider({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueText,
    required ValueChanged<double> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: kCardGap),
      child: MorphItem(
        selected: false,
        isFirst: false,
        isLast: false,
        interactive: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 22, color: cs.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          valueText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: value.clamp(min, max),
                      min: min,
                      max: max,
                      divisions: divisions,
                      activeColor: cs.primary,
                      inactiveColor: cs.surfaceContainerHighest,
                      onChanged: onChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
}
