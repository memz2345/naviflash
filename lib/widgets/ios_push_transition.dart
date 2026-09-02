// lib/widgets/ios_push_transition.dart
//
// iOS 风格全局页面 push 转场（配置于 ThemeData.pageTransitionsTheme，
// 应用于所有 MaterialPageRoute）：
//   - 新页面：从右侧滑入，转场期间圆角渐变归零（无投影，更自然）；
//   - 旧页面：向左平移 30% + 黑色遮罩逐渐变暗（iOS 层级感），pop 时反向恢复；
//   - 曲线：M3 easeInOutCubicEmphasized（非线性，先加速后缓收）。
//
// 与已有自定义动画的共存（互不干扰）：
//   - FrostedHeroRoute / PageRouteBuilder（投币页、设置搜索跳转等）自带
//     transitionsBuilder，不经 PageTransitionsTheme，完全不受影响；
//   - MaterialPageRoute.canTransitionTo 对非 Material 路由返回 false：
//     被 FrostedHeroRoute 或半透明弹层（opaque:false）覆盖时，旧页面的
//     secondaryAnimation 不会被驱动，本转场的旧页面效果自然跳过；
//   - 根节点使用 [IosBackdropScale] 的页面（搜索页 / 视频页等）自带
//     「iOS 景深缩放」退场动画，会向 [CustomSecondaryTransitionRoutes]
//     注册所在路由；本转场检测到（且其效果处于开启状态）时跳过自身的
//     左移 + 压暗，避免双重退场动画。
//
// 性能：
//   - 旧页面压暗层是纯半透明色块（无 BackdropFilter / 无 ImageFiltered），
//     不触发 saveLayer、不重光栅化背景 —— 此前逐帧渐变模糊在长列表页上
//     掉帧明显，已移除；
//   - 被 opaque 路由完全遮挡后页面不再绘制，遮罩层同样零开销；
//   - 转场静止期（页面正常展示）只剩恒等平移 + 半径 0 圆角，开销可忽略。
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:naviflash/services/settings_service.dart';

/// iOS 风格 push 转场中，旧页面（上一级）遮罩的最大不透明度。
const double kIosPushDimOpacity = 0.40;

/// 「本路由已自带旧页面退场动画」注册表。
///
/// 页面根节点使用 [IosBackdropScale]（iOS 景深缩放）等自定义退场效果时，
/// 将所在路由注册到此表；[IosPushPageTransitionsBuilder] 检测到后跳过
/// 自身的旧页面动画（左移 + 压暗），避免两种退场效果叠加。
///
/// 注册由 IosBackdropScale 的 State 在 didChangeDependencies / dispose 中
/// 维护，路由弹栈后自动注销，无泄漏。
class CustomSecondaryTransitionRoutes {
  CustomSecondaryTransitionRoutes._();

  static final Set<PageRoute<dynamic>> _routes = <PageRoute<dynamic>>{};

  static void register(PageRoute<dynamic> route) => _routes.add(route);

  static void unregister(PageRoute<dynamic> route) => _routes.remove(route);

  static bool contains(PageRoute<dynamic> route) => _routes.contains(route);
}

/// iOS 风格 push 转场构建器（显示设置「iOS 风格页面切换」开启时配置于
/// ThemeData.pageTransitionsTheme；关闭时传 null 使用 Flutter 默认转场）。
class IosPushPageTransitionsBuilder extends PageTransitionsBuilder {
  const IosPushPageTransitionsBuilder({
    /// 新页面入场起始圆角（显示设置中可调）。
    this.cornerRadius = 26.0,

    /// 旧页面遮罩的最大不透明度（0 = 不压暗）。
    this.dimOpacity = kIosPushDimOpacity,

    /// 旧页面向左平移的屏宽比例。
    this.underneathFraction = 0.30,

    /// 转场时长（push / pop 一致，毫秒）。
    this.transitionMs = 420,
  });

  final double cornerRadius;
  final double dimOpacity;
  final double underneathFraction;
  final int transitionMs;

  @override
  Duration get transitionDuration => Duration(milliseconds: transitionMs);

  @override
  Duration get reverseTransitionDuration =>
      Duration(milliseconds: transitionMs);

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _IosPushPageTransition(
      route: route,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      cornerRadius: cornerRadius,
      dimOpacity: dimOpacity,
      underneathFraction: underneathFraction,
      child: child,
    );
  }
}

/// 转场曲线：M3 emphasized（非线性，与平台新式转场一致）。
const Curve _transitionCurve = Curves.easeInOutCubicEmphasized;

class _IosPushPageTransition extends StatefulWidget {
  const _IosPushPageTransition({
    required this.route,
    required this.animation,
    required this.secondaryAnimation,
    required this.cornerRadius,
    required this.dimOpacity,
    required this.underneathFraction,
    required this.child,
  });

  final PageRoute<dynamic>? route;

  /// 本路由自身的入场动画（push 时 0 → 1，pop 时 1 → 0）。
  final Animation<double> animation;

  /// 上方路由压栈时驱动本页退场（被覆盖时 0 → 1）。
  final Animation<double> secondaryAnimation;

  final double cornerRadius;
  final double dimOpacity;
  final double underneathFraction;
  final Widget child;

  @override
  State<_IosPushPageTransition> createState() =>
      _IosPushPageTransitionState();
}

class _IosPushPageTransitionState extends State<_IosPushPageTransition> {
  /// 页面子树锚点：压暗层挂载 / 卸载、退场分支切换等结构变化时，
  /// 通过 GlobalKey 复用同一 Element，保住页面 State 不丢。
  final GlobalKey _pageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // ── 新页面入场：从右侧滑入 + 圆角渐变归零（无投影，更自然）──
    final Widget entering = SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: widget.animation, curve: _transitionCurve),
      ),
      child: AnimatedBuilder(
        animation: widget.animation,
        child: widget.child,
        builder: (context, child) {
          final double a =
              widget.animation.value.clamp(0.0, 1.0).toDouble();
          // 圆角进度：不再复用位移用的强前载曲线（easeInOutCubicEmphasized）。
          // 原写法下圆角随位移曲线在页面尚在屏外时便已归零，导致运动过程中
          // 看起来是直角。改为「前段几乎保持、临近就位才平滑归零」，使入场所见
          // 期间圆角始终有效（pop 反向时同样：离场页面在圆角到位后才变方）。
          final double radiusProgress = Curves.easeInCubic.transform(a);
          final radius =
              lerpDouble(widget.cornerRadius, 0.0, radiusProgress) ?? 0.0;
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            // 圆角归零（页面已就位 / 静止展示）时降级为 hardEdge：矩形
            // 裁剪无需抗锯齿，省掉一层抗锯齿裁剪。本转场构建器应用于
            // 所有页面，静止期是常态，这笔开销没必要付。
            // 只改 clipBehavior（RenderObject 属性），不切换子树结构，
            // 不会重建页面 State。
            clipBehavior: radius > 0.001 ? Clip.antiAlias : Clip.hardEdge,
            child: child,
          );
        },
      ),
    );

    // ── 本页自带旧页面退场动画（IosBackdropScale 景深缩放）→ 让位 ──
    // 仅在其效果处于开启状态时让位（关闭时 IosBackdropScale 自身直接
    // 返回原 child，本页退场无动画，由本转场接管左移 + 压暗）。
    final route = widget.route;
    final bool hasCustomSecondary = route != null &&
        CustomSecondaryTransitionRoutes.contains(route) &&
        SettingsService.heroTransitionBlurEnabled;
    if (hasCustomSecondary) {
      return KeyedSubtree(key: _pageKey, child: entering);
    }

    // ── 本页作为旧页面被覆盖：向左平移 + 黑色遮罩逐渐变暗（iOS 层级感）──
    // 平移与压暗共用同一进度：覆盖时左移并变暗，pop 恢复时同步滑回原位、
    // 遮罩淡出。遮罩是纯半透明色块：无滤镜、无 saveLayer，不重光栅化背景
    // （原先的渐变模糊逐帧重光栅化整页，长列表页上明显掉帧）。
    return AnimatedBuilder(
      animation: widget.secondaryAnimation,
      child: KeyedSubtree(key: _pageKey, child: entering),
      builder: (context, child) {
        final raw = widget.secondaryAnimation.value
            .clamp(0.0, 1.0)
            .toDouble();
        final t = _transitionCurve.transform(raw);
        // 压暗用 easeOutCubic：覆盖早期快速升到接近峰值（iOS 式快速失焦），
        // 恢复时随进度对称回落。
        final dim = widget.dimOpacity * Curves.easeOutCubic.transform(raw);
        return FractionalTranslation(
          translation: Offset(-widget.underneathFraction * t, 0),
          child: Stack(
            children: <Widget>[
              child!,
              if (dim > 0.001)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(color: Color.fromRGBO(0, 0, 0, dim)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
