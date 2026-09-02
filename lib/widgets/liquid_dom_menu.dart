import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../services/settings_service.dart';
import 'liquid_glass.dart';

typedef LiquidDomMenuBuilder =
    Widget Function(BuildContext context, VoidCallback close);

/// Shows a context menu using the animation model from liquid-dom's MenuDemo.
///
/// Position, size, corner radius, content scale, blur and opacity are animated
/// independently. The shared glass layer keeps the small origin blob and menu
/// body visually fused while the menu travels to its final position.
VoidCallback showLiquidDomMenu(
  BuildContext context, {
  required Offset globalPosition,
  required LiquidDomMenuBuilder builder,
  required double menuWidth,
  required double menuHeight,
  double menuRadius = 18.0,

  /// 触发按钮尺寸。非空时 [globalPosition] 视为按钮**左上角**，启用
  /// 「角对齐」定位：菜单顶部对齐按钮顶部，水平方向默认菜单左上角
  /// 对齐按钮左上角（向右展开）；越界则菜单右上角对齐按钮右上角
  /// （向左展开）；垂直越界则菜单底部对齐按钮底部（向上展开）。
  /// 关闭态小圆点以按钮中心为圆心。为 null 时退回原逻辑（origin 为
  /// 中心点，小圆点以 origin 为圆心）。
  Size? originSize,

  /// 菜单打开动画开始时回调（动画进行中，触发按钮应保持可见）。
  VoidCallback? onOpened,

  /// 菜单打开动画**结束并稳定后**回调（此时菜单已完全覆盖触发按钮，
  /// 可安全隐藏触发按钮本体，避免其图标在动画过程中突然消失）。
  VoidCallback? onOpenedComplete,

  /// 菜单关闭动画**开始**时回调（让触发按钮图标随玻璃回缩重新出现）。
  VoidCallback? onCloseStarted,

  /// 菜单关闭并从 Overlay 移除后回调（用于恢复触发按钮）。
  VoidCallback? onClosed,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final overlayBox = overlay.context.findRenderObject() as RenderBox?;
  final origin = overlayBox == null
      ? globalPosition
      : overlayBox.globalToLocal(globalPosition);
  final screenSize = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);
  // 安全区内可用尺寸，避免菜单贴边或被手势条/刘海遮挡，关闭动画回缩时也不越界
  final safeWidth = screenSize.width - padding.left - padding.right;
  final safeHeight = screenSize.height - padding.top - padding.bottom;
  final targetSize = Size(
    math.min(menuWidth, math.max(40.0, safeWidth - 20.0)),
    math.min(menuHeight, math.max(40.0, safeHeight - 20.0)),
  );

  // 定位：originSize 非空 → 角对齐；否则退回「origin 为中心」原逻辑
  var targetLeft = origin.dx;
  var targetTop = origin.dy;
  if (originSize != null) {
    // origin 视为按钮左上角：菜单顶部 = 按钮顶部
    if (targetLeft + targetSize.width > screenSize.width - padding.right) {
      // 向右展开越界 → 向左展开：菜单右上角 = 按钮右上角
      targetLeft = origin.dx + originSize.width - targetSize.width;
    }
    if (targetTop + targetSize.height > screenSize.height - padding.bottom) {
      // 向下展开越界 → 向上展开：菜单底部 = 按钮底部
      targetTop = origin.dy + originSize.height - targetSize.height;
    }
  } else {
    if (targetLeft + targetSize.width > screenSize.width - padding.right) {
      targetLeft -= targetSize.width;
    }
    if (targetTop + targetSize.height > screenSize.height - padding.bottom) {
      targetTop -= targetSize.height;
    }
  }
  final minLeft = padding.left + 10.0;
  final minTop = padding.top + 10.0;
  final maxLeft = math.max(minLeft, screenSize.width - targetSize.width - padding.right - 10.0);
  final maxTop = math.max(minTop, screenSize.height - targetSize.height - padding.bottom - 10.0);
  targetLeft = targetLeft.clamp(minLeft, maxLeft).toDouble();
  targetTop = targetTop.clamp(minTop, maxTop).toDouble();

  late final OverlayEntry entry;
  final menuKey = GlobalKey<_LiquidDomMenuState>();
  entry = OverlayEntry(
    builder: (_) => Positioned.fill(
      child: _LiquidDomMenu(
        key: menuKey,
        origin: origin,
        originSize: originSize,
        targetRect: Rect.fromLTWH(
          targetLeft,
          targetTop,
          targetSize.width,
          targetSize.height,
        ),
        menuRadius: menuRadius,
        builder: builder,
        onOpened: onOpened,
        onOpenedComplete: onOpenedComplete,
        onCloseStarted: onCloseStarted,
        onClosed: () {
          if (entry.mounted) entry.remove();
          onClosed?.call();
        },
      ),
    ),
  );
  overlay.insert(entry);
  return () => menuKey.currentState?._close();
}

class _LiquidDomMenu extends StatefulWidget {
  const _LiquidDomMenu({
    required this.origin,
    required this.targetRect,
    required this.menuRadius,
    required this.builder,
    required this.onClosed,
    this.originSize,
    this.onOpened,
    this.onOpenedComplete,
    this.onCloseStarted,
    super.key,
  });

  final Offset origin;
  final Size? originSize;
  final Rect targetRect;
  final double menuRadius;
  final LiquidDomMenuBuilder builder;
  final VoidCallback onClosed;
  final VoidCallback? onOpened;
  final VoidCallback? onOpenedComplete;
  final VoidCallback? onCloseStarted;

  @override
  State<_LiquidDomMenu> createState() => _LiquidDomMenuState();
}

class _LiquidDomMenuState extends State<_LiquidDomMenu>
    with TickerProviderStateMixin {
  static const _closedSize = 40.0;
  static const _closedRadius = 130.0;
  static const _closedContentBlur = 8.0;
  static const _closedContentScale = 2.0;

  /// 折射 pop 峰值增量（相对全局玻璃设置）：折射率瞬时 +0.5、厚度 +24，
  /// 模拟 liquid-dom 打开时 contentIor 1→1.5 / contentDepth 0→80 的弹跳。
  static const double _popIorDelta = 0.5;
  static const double _popThicknessDelta = 24.0;

  late final AnimationController _left;
  late final AnimationController _top;
  late final AnimationController _width;
  late final AnimationController _height;
  late final AnimationController _radius;
  late final AnimationController _contentOpacity;
  late final AnimationController _contentBlur;
  late final AnimationController _contentScale;

  /// 打开时的「折射 pop」脉冲（0→1→0）：瞬时抬高折射率与厚度，
  /// 让内容像被玻璃折射弹一下（对应 liquid-dom 打开时的 contentIor /
  /// contentDepth 脉冲）。只作用于菜单主体玻璃，不影响小圆点锚点。
  late final AnimationController _refractionPop;

  late final double _closedLeft;
  late final double _closedTop;
  bool _closing = false;
  bool _closeFinished = false;
  bool _openCompleted = false;

  @override
  void initState() {
    super.initState();
    // originSize 非空：origin 视为按钮左上角，关闭态小圆点以按钮中心为圆心；
    // 否则 origin 视为锚点中心，小圆点以 origin 为圆心（兼容旧调用）。
    final anchorCenter = widget.originSize != null
        ? Offset(
            widget.origin.dx + widget.originSize!.width / 2,
            widget.origin.dy + widget.originSize!.height / 2,
          )
        : widget.origin;
    _closedLeft = anchorCenter.dx - _closedSize / 2;
    _closedTop = anchorCenter.dy - _closedSize / 2;

    _left = _controller(_closedLeft);
    _top = _controller(_closedTop);
    _width = _controller(_closedSize);
    _height = _controller(_closedSize);
    _radius = _controller(_closedRadius);
    _contentOpacity = _controller(0.0);
    _contentBlur = _controller(_closedContentBlur);
    _contentScale = _controller(_closedContentScale);
    _refractionPop = AnimationController(vsync: this, value: 0.0);
    _refractionPop.addListener(_onTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open();
    });
  }

  AnimationController _controller(double value) {
    final controller = AnimationController.unbounded(vsync: this, value: value);
    controller.addListener(_onTick);
    return controller;
  }

  void _onTick() {
    if (!mounted) return;
    setState(() {});
    if (!_closing && !_openCompleted && _isOpenSettled) {
      _openCompleted = true;
      widget.onOpenedComplete?.call();
    }
    if (_closing && !_closeFinished && _isCloseSettled) {
      _closeFinished = true;
      widget.onClosed();
    }
  }

  void _open() {
    _closing = false;
    _closeFinished = false;
    _openCompleted = false;
    // 通知触发按钮：菜单已开始打开，动画进行中应保持图标可见
    widget.onOpened?.call();

    _springTo(
      _left,
      widget.targetRect.left,
      stiffness: 144,
      damping: 14,
      velocity: 2400,
    );
    _springTo(
      _top,
      widget.targetRect.top,
      stiffness: 144,
      damping: 14,
      velocity: 2400,
    );
    _easeTo(
      _width,
      widget.targetRect.width,
      duration: const Duration(milliseconds: 300),
      curve: const Cubic(0.8, 0.3, 0.5, 0.8),
    );
    _easeTo(
      _height,
      widget.targetRect.height,
      duration: const Duration(milliseconds: 300),
      curve: const Cubic(0.8, 0.3, 0.5, 0.8),
    );
    _easeTo(
      _radius,
      widget.menuRadius,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
    );
    _springTo(_contentOpacity, 1.0, stiffness: 137, damping: 20);
    _easeTo(
      _contentBlur,
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _easeTo(
      _contentScale,
      1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    // 折射 pop：菜单展开到位的同时触发一次折射/厚度脉冲。
    _fireRefractionPop();
  }

  /// 打开时触发一次折射 pop：折射率与厚度先冲到峰值再回落到基线，
  /// 形成内容「被玻璃折射弹一下」的观感。仅持续约 460ms。
  void _fireRefractionPop() {
    _refractionPop.stop();
    _refractionPop.value = 0.0;
    _refractionPop
        .animateTo(
          1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
        )
        .whenComplete(() {
      if (!mounted) return;
      _refractionPop.animateTo(
        0.0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    });
  }

  void _close() {
    if (_closing || _closeFinished) return;
    _closing = true;
    // 通知触发按钮：关闭动画开始，让图标随玻璃回缩重新出现
    widget.onCloseStarted?.call();
    // 关闭圆心 = 触发点（originSize 模式下为按钮中心；右键/无 originSize 时
    // 为 origin 即鼠标位置）。菜单体边缩到 0 边回缩到圆心，同时淡出，
    // 避免「缩到 40 小圆点停顿再消失」的不自然感。
    final cx = _closedLeft + _closedSize / 2;
    final cy = _closedTop + _closedSize / 2;
    _springTo(_left, cx, stiffness: 130, damping: 18);
    _springTo(_top, cy, stiffness: 130, damping: 18);
    _easeTo(
      _width,
      0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    _easeTo(
      _height,
      0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    _easeTo(
      _radius,
      0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    _springTo(_contentOpacity, 0.0, stiffness: 137, damping: 20);
    _easeTo(
      _contentBlur,
      _closedContentBlur,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
    _easeTo(
      _contentScale,
      _closedContentScale,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  void _springTo(
    AnimationController controller,
    double target, {
    required double stiffness,
    required double damping,
    double velocity = 0,
  }) {
    controller.stop();
    final delta = target - controller.value;
    final initialVelocity = velocity == 0 || delta == 0
        ? 0.0
        : velocity.abs() * delta.sign;
    controller.animateWith(
      SpringSimulation(
        SpringDescription(mass: 1.0, stiffness: stiffness, damping: damping),
        controller.value,
        target,
        initialVelocity,
      ),
    );
  }

  void _easeTo(
    AnimationController controller,
    double target, {
    required Duration duration,
    required Curve curve,
  }) {
    controller.stop();
    controller.animateTo(target, duration: duration, curve: curve);
  }

  bool _settled(AnimationController controller, double target) {
    return (controller.value - target).abs() < 0.6 &&
        controller.velocity.abs() < 1.5;
  }

  bool get _isCloseSettled {
    final cx = _closedLeft + _closedSize / 2;
    final cy = _closedTop + _closedSize / 2;
    return _settled(_left, cx) &&
        _settled(_top, cy) &&
        _settled(_contentOpacity, 0.0);
  }

  /// 打开动画是否已稳定（位置/尺寸/内容透明度均到达目标值）。
  bool get _isOpenSettled =>
      _settled(_left, widget.targetRect.left) &&
      _settled(_top, widget.targetRect.top) &&
      _settled(_width, widget.targetRect.width) &&
      _settled(_height, widget.targetRect.height) &&
      _settled(_contentOpacity, 1.0);

  @override
  void dispose() {
    _left.dispose();
    _top.dispose();
    _width.dispose();
    _height.dispose();
    _radius.dispose();
    _contentOpacity.dispose();
    _contentBlur.dispose();
    _contentScale.dispose();
    _refractionPop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = _width.value.clamp(1.0, widget.targetRect.width).toDouble();
    final height = _height.value
        .clamp(1.0, widget.targetRect.height)
        .toDouble();
    final sizeT = _progress(_width.value, _closedSize, widget.targetRect.width);
    final positionT = _positionProgress;
    final anchorScale =
        _closing ? 0.0 : (1.0 - sizeT / 0.4).clamp(0.0, 1.0);
    final separation = (positionT - sizeT).abs();
    final blend = (separation * 150.0).clamp(0.0, 28.0).toDouble();
    final radius = _radius.value
        .clamp(0.0, math.min(width, height) / 2)
        .toDouble();
    final opacity = _contentOpacity.value.clamp(0.0, 1.0).toDouble();
    final blur = _contentBlur.value.clamp(0.0, double.infinity).toDouble();
    final contentScale = _contentScale.value.clamp(0.5, 2.5).toDouble();
    final settings = buildNaviGlassSettings();
    // 折射 pop：把脉冲叠加到菜单主体的折射率/厚度上（不影响小圆点锚点）。
    final pop = _refractionPop.value;
    final menuSettings = buildNaviGlassSettings(
      refractiveIndex:
          (settings.refractiveIndex + _popIorDelta * pop).clamp(1.0, 2.5),
      thickness: (settings.thickness + _popThicknessDelta * pop).clamp(0.0, 240.0),
    );
    final useLegacySurface = SettingsService.liquidGlassMenusDisabled;
    final quality = naviGlassAdvanced && !useLegacySurface
        ? GlassQuality.premium
        : GlassQuality.minimal;

    final anchorSurface = useLegacySurface
        ? GlassMenuSurface(
            radius: _closedSize / 2,
            blur: settings.blur,
            stretch: 0,
            legacyClipRadius: BorderRadius.circular(_closedSize / 2),
            legacyDecoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(_closedSize / 2),
            ),
            content: const SizedBox.expand(),
          )
        : GlassContainer(
            useOwnLayer: false,
            width: _closedSize,
            height: _closedSize,
            shape: const LiquidOval(),
            settings: settings,
            quality: quality,
            child: const SizedBox.expand(),
          );
    final menuContent = Transform.scale(
      scale: contentScale,
      alignment: Alignment.center,
      child: SizedBox(
        width: widget.targetRect.width,
        height: widget.targetRect.height,
        child: Opacity(
          opacity: opacity,
          child: blur > 0.01
              ? ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: widget.builder(context, _close),
                )
              : widget.builder(context, _close),
        ),
      ),
    );
    final bodySurface = useLegacySurface
        ? GlassMenuSurface(
            radius: radius,
            blur: settings.blur,
            stretch: 0,
            legacyClipRadius: BorderRadius.circular(radius),
            legacyDecoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(radius),
            ),
            content: menuContent,
          )
        : GlassContainer(
            useOwnLayer: false,
            width: width,
            height: height,
            shape: LiquidRoundedSuperellipse(borderRadius: radius),
            settings: menuSettings,
            quality: quality,
            clipBehavior: Clip.antiAlias,
            child: menuContent,
          );

    final glassStack = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: _closedLeft,
          top: _closedTop,
          width: _closedSize,
          height: _closedSize,
          child: Transform.scale(scale: anchorScale, child: anchorSurface),
        ),
        Positioned(
          left: _left.value,
          top: _top.value,
          width: width,
          height: height,
          child: IgnorePointer(ignoring: opacity < 0.8, child: bodySurface),
        ),
      ],
    );
    final groupedStack = quality == GlassQuality.premium
        ? LiquidGlassBlendGroup(blend: blend, child: glassStack)
        : glassStack;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (opacity > 0.01 || !_closing)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
              onSecondaryTap: _close,
              onPanDown: (_) => _close(),
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
        Positioned.fill(
          child: AdaptiveLiquidGlassLayer(
            settings: settings,
            quality: quality,
            blendAmount: blend,
            child: groupedStack,
          ),
        ),
      ],
    );
  }

  double get _positionProgress {
    final x = _progress(_left.value, _closedLeft, widget.targetRect.left);
    final y = _progress(_top.value, _closedTop, widget.targetRect.top);
    return (x + y) / 2;
  }

  double _progress(double value, double start, double end) {
    if ((end - start).abs() < 0.001) return 1.0;
    return ((value - start) / (end - start)).clamp(0.0, 1.0).toDouble();
  }
}
