// lib/widgets/liquid_glass.dart
//
// 统一液态玻璃表面，基于 liquid_glass_widgets 包实现：
//   - 高级渲染开启且当前平台支持 Impeller 时使用 premium 液态玻璃；
//   - 其他情况使用新包的 minimal BackdropFilter 降级路径；
//   - ownLayer=false 时加入上层 LiquidGlassLayer，共享设置与纹理；
//   - stretch 保留项目原有的拖拽缩放手感，菜单本身使用新包的玻璃表面。
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:naviflash/services/settings_service.dart';

LiquidGlassSettings buildNaviGlassSettings({
  double? blur,
  double? thickness,
  double? lightIntensity,
  double? tintOpacity,
  double? saturation,
  double? refractiveIndex,
  double? ambientStrength,
  double? lightAngle,
  double? chromaticAberration,
  double? ambientRim,
  double? fresnelStrength,
  double? glowIntensity,
  double? shadowElevation,
  GlassSpecularSharpness? specularSharpness,
}) {
  return LiquidGlassSettings(
    glassColor: Color.from(
      alpha: tintOpacity ?? SettingsService.liquidGlassTintOpacity,
      red: 1,
      green: 1,
      blue: 1,
    ),
    thickness: thickness ?? SettingsService.liquidGlassThickness,
    blur: blur ?? SettingsService.liquidGlassBlur,
    lightAngle: lightAngle ?? SettingsService.liquidGlassLightAngle,
    lightIntensity: lightIntensity ?? SettingsService.liquidGlassLightIntensity,
    ambientStrength:
        ambientStrength ?? SettingsService.liquidGlassAmbientStrength,
    refractiveIndex:
        refractiveIndex ?? SettingsService.liquidGlassRefractiveIndex,
    saturation: saturation ?? SettingsService.liquidGlassSaturation,
    chromaticAberration:
        chromaticAberration ?? SettingsService.liquidGlassChromaticAberration,
    ambientRim: ambientRim ?? 0,
    fresnelStrength: fresnelStrength ?? 1.0,
    glowIntensity: glowIntensity ?? 0.75,
    shadowElevation: shadowElevation ?? 1.0,
    specularSharpness: specularSharpness ?? GlassSpecularSharpness.medium,
  );
}

bool get naviGlassAdvanced =>
    SettingsService.fragmentRenderingEnabled &&
    ui.ImageFilter.isShaderFilterSupported;

class NaviGlass extends StatelessWidget {
  const NaviGlass({
    super.key,
    required this.radius,
    required this.child,
    this.circle = false,
    this.blur,
    this.thickness,
    this.lightIntensity,
    this.tintOpacity,
    this.saturation,
    this.refractiveIndex,
    this.ambientStrength,
    this.lightAngle,
    this.chromaticAberration,
    this.ownLayer = true,
    this.stretch = 0.0,
    this.interactionScale = 1.05,
    this.glassify = false,
    this.glassifySettings,
  });

  /// 圆角半径（circle 为 true 时忽略）。
  final double radius;

  /// 玻璃表面之上的内容。
  final Widget child;

  /// 使用正圆形（胶囊按钮 / 头像等）。
  final bool circle;

  /// 背景模糊强度（null = 跟随全局液态玻璃调校）。
  final double? blur;

  /// 玻璃厚度（折射强度，仅真实 LiquidGlass 生效；
  /// null = 跟随全局液态玻璃调校）。
  final double? thickness;

  /// 高光强度（null = 跟随全局液态玻璃调校）。
  final double? lightIntensity;

  /// 玻璃着色强度（白色 tint 的 alpha，0 = 纯透明；
  /// null = 跟随全局液态玻璃调校）。
  final double? tintOpacity;

  /// 透过玻璃的背景饱和度（1.0 = 无变化；null = 跟随全局）。
  final double? saturation;

  /// 折射率（1.0 = 无折射，~1.5 = 真实玻璃；null = 跟随全局）。
  final double? refractiveIndex;

  /// 环境光强度（null = 跟随全局）。
  final double? ambientStrength;

  /// 高光光源方向（弧度；null = 跟随全局）。
  final double? lightAngle;

  /// 色差 / 色散（null = 跟随全局）。
  final double? chromaticAberration;

  /// 是否自建 LiquidGlassLayer。
  ///
  /// 为 false 时要求上层已存在 [LiquidGlassLayer]（共享其设置与纹理，
  /// 此时 radius/blur 等参数不生效）。
  final bool ownLayer;

  /// 拖拽挤压拉伸强度（0 = 关闭，约 0.4-0.5 效果自然）。
  final double stretch;

  /// 交互时整体缩放（1.0 = 不缩放，默认 1.05）。
  final double interactionScale;

  /// 保留旧调用参数。新包不公开原 renderer 的 Glassify API，因此该参数
  /// 不改变内容，仅用于兼容项目内已有的构造调用。
  final bool glassify;

  /// 旧 Glassify 设置，当前由表面设置统一承载。
  final LiquidGlassSettings? glassifySettings;

  LiquidGlassSettings buildSettings() => buildNaviGlassSettings(
    blur: blur,
    thickness: thickness,
    lightIntensity: lightIntensity,
    tintOpacity: tintOpacity,
    saturation: saturation,
    refractiveIndex: refractiveIndex,
    ambientStrength: ambientStrength,
    lightAngle: lightAngle,
    chromaticAberration: chromaticAberration,
  );

  LiquidGlassSettings buildGlassifySettings() =>
      glassifySettings ?? buildSettings();

  @override
  Widget build(BuildContext context) {
    final settings = buildSettings();
    final shape = circle
        ? const LiquidOval()
        : LiquidRoundedSuperellipse(borderRadius: radius);
    AdaptiveGlass surface(Widget content) => AdaptiveGlass(
      shape: shape,
      settings: settings,
      quality: naviGlassAdvanced ? GlassQuality.premium : GlassQuality.minimal,
      useOwnLayer: ownLayer,
      isInteractive: stretch > 0,
      clipExpansion: stretch > 0 ? const EdgeInsets.all(16) : EdgeInsets.zero,
      child: content,
    );
    if (stretch > 0) {
      return GlassShellStretch(
        stretch: stretch,
        interactionScale: interactionScale,
        shell: surface(const SizedBox.expand()),
        content: child,
      );
    }
    return surface(child);
  }
}

/// 果冻拉伸容器：在菜单内任意位置向某一方向拖拽（超过轻微滑动阈值）
/// 即可让整个菜单（玻璃外壳 + 内容）做体积守恒的挤压拉伸，松手弹性回弹。
///
/// - 用原始指针事件监听整个区域（不参与手势竞技场，
///   不影响内容上的点击 / 滚动 / 拖拽关闭）；
/// - 仅点击（无位移）不会触发任何形变，避免点击菜单项时菜单晃动。
class GlassShellStretch extends StatefulWidget {
  const GlassShellStretch({
    super.key,
    required this.stretch,
    required this.shell,
    required this.content,
    this.interactionScale = 1.05,
  });

  /// 拖拽拉伸强度（0 = 关闭）。
  final double stretch;

  /// 玻璃外壳。
  final Widget shell;

  /// 菜单内容（在玻璃之上）。
  final Widget content;

  /// 按下并拖动时的整体缩放。
  final double interactionScale;

  @override
  State<GlassShellStretch> createState() => _GlassShellStretchState();
}

class _GlassShellStretchState extends State<GlassShellStretch>
    with SingleTickerProviderStateMixin {
  /// 超过该位移（逻辑像素）才视为「拉伸拖拽」，过滤纯点击的微小抖动。
  static const double _dragSlop = 12.0;

  late final AnimationController _spring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  Animation<Offset>? _releaseAnim;
  Offset _drag = Offset.zero;
  bool _engaged = false;

  void _down(PointerDownEvent event) {
    _spring.stop();
    _releaseAnim = null;
    _drag = Offset.zero;
    if (_engaged) {
      setState(() => _engaged = false);
    }
  }

  void _move(PointerMoveEvent event) {
    _spring.stop();
    _releaseAnim = null;
    _drag += event.delta;
    if (!_engaged && _drag.distance > _dragSlop) {
      setState(() => _engaged = true);
    } else if (_engaged) {
      setState(() {});
    }
  }

  void _up(PointerEvent event) {
    if (_engaged && _drag != Offset.zero) {
      _releaseAnim = Tween<Offset>(
        begin: _drag,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _spring, curve: Curves.elasticOut));
      _spring.forward(from: 0);
    }
    _drag = Offset.zero;
    if (_engaged) {
      setState(() => _engaged = false);
    }
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spring,
      builder: (context, _) {
        final Offset drag = (_releaseAnim != null && _spring.isAnimating)
            ? _releaseAnim!.value
            : _drag;
        final resisted = Offset(
          _resist(drag.dx) * widget.stretch,
          _resist(drag.dy) * widget.stretch,
        );
        final dragScale =
            1.0 +
            (resisted.dx.abs() + resisted.dy.abs()).clamp(0.0, 80.0) / 800.0;
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: _up,
          onPointerCancel: _up,
          child: Transform.translate(
            offset: resisted,
            child: AnimatedScale(
              scale: (_engaged ? widget.interactionScale : 1.0) * dragScale,
              duration: const Duration(milliseconds: 350),
              curve: Curves.elasticOut,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Positioned.fill(child: widget.shell),
                  widget.content,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _resist(double value) {
    final sign = value < 0 ? -1.0 : 1.0;
    return sign * value.abs() / (1.0 + value.abs() * 0.08);
  }
}

/// 可拉伸的液态玻璃弹窗表面：玻璃作为外壳，内容在玻璃之上。
///
/// 仅在「高级玻璃渲染」开启时响应拉伸——在弹窗内任意位置向某一方向
/// 拖拽（超过轻微滑动阈值），整个弹窗做果冻挤压拉伸（同下拉菜单的
/// 拉伸逻辑），仅点击不会触发任何形变；设置关闭时退化为普通
/// [NaviGlass]。
class StretchableNaviGlass extends StatelessWidget {
  const StretchableNaviGlass({
    super.key,
    required this.radius,
    required this.child,
    this.circle = false,
    this.blur,
    this.thickness,
    this.lightIntensity,
    this.ownLayer = true,
    this.stretch = 0.35,
  });

  /// 圆角半径（circle 为 true 时忽略）。
  final double radius;

  /// 玻璃表面之上的内容（不参与正常点击形变）。
  final Widget child;

  /// 使用正圆形。
  final bool circle;

  /// 背景模糊强度（null = 跟随全局液态玻璃调校）。
  final double? blur;

  /// 玻璃厚度（折射强度，仅真实 LiquidGlass 生效；null = 跟随全局）。
  final double? thickness;

  /// 高光强度（null = 跟随全局）。
  final double? lightIntensity;

  /// 是否自建 LiquidGlassLayer。
  final bool ownLayer;

  /// 拖拽拉伸强度（0 = 关闭）。
  final double stretch;

  @override
  Widget build(BuildContext context) {
    final active = stretch > 0 && SettingsService.fragmentRenderingEnabled;
    final shell = NaviGlass(
      radius: radius,
      circle: circle,
      blur: blur,
      thickness: thickness,
      lightIntensity: lightIntensity,
      ownLayer: ownLayer,
      child: const SizedBox.expand(),
    );
    if (!active) {
      return NaviGlass(
        radius: radius,
        circle: circle,
        blur: blur,
        thickness: thickness,
        lightIntensity: lightIntensity,
        ownLayer: ownLayer,
        child: child,
      );
    }
    return GlassShellStretch(stretch: stretch, shell: shell, content: child);
  }
}

/// 下拉菜单玻璃外壳：默认液态玻璃（纯透明 + 外壳拉伸动画），
/// 设置「禁用液态玻璃菜单」开启后恢复传统毛玻璃样式
/// （[legacyDecoration] + [legacyClipRadius] 定义的 BackdropFilter 容器）。
/// 聊天页不使用本组件，不受该设置影响。
class GlassMenuSurface extends StatelessWidget {
  const GlassMenuSurface({
    super.key,
    required this.content,
    this.radius = 14.0,
    this.blur,
    this.tintOpacity,
    this.lightIntensity,
    this.stretch = 0.35,
    this.legacyDecoration,
    this.legacyClipRadius,
  });

  /// 菜单内容（不参与拉伸）。
  final Widget content;

  /// 液态玻璃圆角半径。
  final double radius;

  /// 背景模糊强度（null = 跟随全局液态玻璃调校）。
  final double? blur;

  /// 玻璃着色强度（白色 tint 的 alpha；null = 跟随全局，默认 0 纯透明）。
  ///
  /// 列表页等平坦背景上，纯折射玻璃没有细节可展示、看起来像不透明面板；
  /// 加一点着色（如 0.12）可让玻璃在任何背景上都有雾面质感。
  final double? tintOpacity;

  /// 高光强度（null = 跟随全局，默认 0）。
  final double? lightIntensity;

  /// 外壳拖拽拉伸强度（0 = 关闭）。
  final double stretch;

  /// 「禁用液态玻璃菜单」时使用的旧样式容器装饰（颜色/边框/阴影等）。
  final BoxDecoration? legacyDecoration;

  /// 「禁用液态玻璃菜单」时的外层圆角裁切（如仅顶部圆角）。
  final BorderRadius? legacyClipRadius;

  @override
  Widget build(BuildContext context) {
    if (SettingsService.liquidGlassMenusDisabled) {
      Widget legacy = Container(decoration: legacyDecoration, child: content);
      if (legacyClipRadius != null) {
        legacy = ClipRRect(borderRadius: legacyClipRadius!, child: legacy);
      }
      legacy = BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: blur ?? SettingsService.liquidGlassBlur,
          sigmaY: blur ?? SettingsService.liquidGlassBlur,
        ),
        child: legacy,
      );
      return legacy;
    }
    return GlassShellStretch(
      stretch: stretch,
      shell: NaviGlass(
        radius: radius,
        blur: blur,
        tintOpacity: tintOpacity,
        lightIntensity: lightIntensity,
        child: const SizedBox.expand(),
      ),
      content: content,
    );
  }
}
