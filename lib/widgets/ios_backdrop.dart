// lib/widgets/ios_backdrop.dart
//
// iOS 风格背景景深：上层路由压栈时本页所有元素向页面中心缩小
// （模拟 iOS 打开 App 时底层页面后撤的景深），同时渐隐 + 圆角，
// 与 FrostedHeroRoute 的 Hero 卡片飞行同时进行；返回时反向恢复。
// 仅在开启「Hero 转场背景模糊」时生效，非线性 easeOutCubic（快收缓停）。
//
// 进度来源：
// - [ModalRoute.secondaryAnimation]：普通 MaterialPageRoute 压栈时可用；
// - [FrostedHeroRoute.backdropProgress]：毛玻璃路由（PageRouteBuilder）
//   不会驱动 secondaryAnimation（实测恒为 0），由其转场期间主动驱动。
// 两者取较大值，保证任意入口推入页面时本效果都生效。
//
// 当前最上层路由（isCurrent）不缩放：入场飞行期间页面本身正在放大，
// 若再叠加背景缩放会双重形变；等更上层的路由压栈后才生效。
// 注意：isCurrent 判定放在 builder 内做「有界计算」，不能切换子树结构
// （return child ↔ AnimatedBuilder）——结构切换会让 child 重新 inflate，
// 导致页面滚动位置/状态丢失、Hero 源卡片被重建而丢失转场动画。
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_push_transition.dart';

/// 全局「弹出层（菜单 / 弹窗 / 投币页等非整页路由）是否打开」计数守卫。
/// 打开弹出层期间抑制下层页面的 iOS 景深缩放 —— 整页路由转场期间
/// Overlay 会把条目 opaque 置为 false（转场结束才恢复 true），因此无法
/// 用 TickerMode 等信号区分「被整页覆盖」和「被弹出层覆盖」，
/// 由各弹出层入口显式置位（[open]/[close]，计数器保证嵌套与异常安全）。
class PopupOverlayGuard {
  static final ValueNotifier<int> active = ValueNotifier(0);

  static void open() => active.value++;

  static void close() => active.value = active.value > 0 ? active.value - 1 : 0;
}

/// 本页自带「iOS 景深缩放」旧页面退场动画。为避免与全局 iOS 风格 push
/// 转场（ios_push_transition.dart）的旧页面左移 + 模糊叠加，State 挂载
/// 时把所在路由注册到 [CustomSecondaryTransitionRoutes]，全局转场检测
/// 到即让位（详见该文件头注释）。
class IosBackdropScale extends StatefulWidget {
  final Widget child;

  const IosBackdropScale({super.key, required this.child});

  @override
  State<IosBackdropScale> createState() => _IosBackdropScaleState();
}

class _IosBackdropScaleState extends State<IosBackdropScale> {
  PageRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final pageRoute = route is PageRoute<dynamic> ? route : null;
    if (!identical(pageRoute, _route)) {
      if (_route != null) CustomSecondaryTransitionRoutes.unregister(_route!);
      _route = pageRoute;
      if (_route != null) CustomSecondaryTransitionRoutes.register(_route!);
    }
  }

  @override
  void dispose() {
    if (_route != null) CustomSecondaryTransitionRoutes.unregister(_route!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (!SettingsService.heroTransitionBlurEnabled) return child;
    final route = ModalRoute.of(context);
    final secondary = route?.secondaryAnimation;
    return AnimatedBuilder(
      animation: Listenable.merge([
        if (secondary != null) secondary,
        FrostedHeroRoute.backdropProgress,
        PopupOverlayGuard.active,
      ]),
      child: child,
      builder: (context, child) {
        // 本路由仍是当前最上层：入场飞行 / 正常展示期间不缩放。
        // 「被整页路由覆盖」判定（整页覆盖时不受弹出层守卫影响，
        // 即使守卫异常残留，退出整页路由的背景缩放也照常工作）：
        // - backdropProgress > 0：整页路由（FrostedHeroRoute）转场进行中
        //   （只有整页路由才会驱动它，弹出层不会）；
        // - TickerMode 被禁用：整页路由转场结束后条目 opaque=true，
        //   Overlay 会禁用下方页面的 TickerMode（弹出层不会）。
        final pageCovered =
            FrostedHeroRoute.backdropProgress.value > 0 ||
            !TickerMode.valuesOf(context).enabled;
        // 上方整页路由正在转场（推入或弹出）：整页路由推入时靠
        // secondaryAnimation / backdropProgress，弹出时靠 backdropProgress。
        // 普通路由（MaterialPageRoute）推入会驱动本页 secondaryAnimation，
        // 而 PageRouteBuilder（FrostedHeroRoute）不会，须靠 backdropProgress。
        final someoneTransitioningAbove =
            FrostedHeroRoute.backdropProgress.value > 0.001 ||
            (secondary?.value ?? 0) > 0.001;
        // 本页自身是否为驱动 backdropProgress 的整页路由：
        // 其入场飞行 / 自身弹栈期间不叠加缩放，避免双重形变。
        final activeAnim = FrostedHeroRoute.activeAnimation;
        final isSelfDriver =
            route != null &&
            activeAnim != null &&
            identical(route.animation, activeAnim);
        // 注意：弹栈起始时框架会立刻把本页 isCurrent 置 true
        // （didPopNext 在 pop 起始即派发），此时「本页已恢复为当前页」
        // 并不可靠——上方的整页路由仍在转场、背景收缩仍应持续到结束。
        // 因此用「有人正在上方转场且不是本页自身」豁免 isCurrent 判定，
        // 保证退出（返回）时背景仍有与进入对称的景深缩放。
        final covered =
            route != null &&
            (pageCovered || PopupOverlayGuard.active.value == 0) &&
            (!route.isCurrent || (someoneTransitioningAbove && !isSelfDriver));
        // 弹栈（reverse）期间恢复 iOS 景深回落动画（0.90 → 1.0）。
        // 仅在完整入场后返回时，才让「弹栈首帧」（driving > 0.95）保持
        // 背景 1.0：
        // - Hero 飞行在弹栈第一帧渲染结束后才测量目标矩形
        //   （_HeroFlightManifest 捕获 toHeroLocation，尺寸只捕获一次），
        //   若此刻背景已缩到 0.90，测到的卡片尺寸偏小，飞行终点与卡片
        //   真实位置不一致，缩回动画结尾会产生可见位移/跳动；
        // - 首帧过后（driving ≤ 0.95）恢复缩放：从 1.0 瞬间回到覆盖态
        //   比例（被弹出路由仍基本不透明，不可见），随后平滑放大回
        //   1.0，退出时景深效果与进入对称；
        // - 中途打断时不抑制，背景从当前比例平滑过渡，避免先闪回完整尺寸
        //   再重新缩小。
        final coveringReversing =
            (secondary?.status == AnimationStatus.reverse) ||
            (activeAnim != null &&
                activeAnim.status == AnimationStatus.reverse);
        final double driving = math.max(
          secondary?.value ?? 0,
          FrostedHeroRoute.backdropProgress.value,
        );
        // 普通 MaterialPageRoute 只有 secondaryAnimation，没有
        // FrostedHeroRoute 的静态标记，仍保留它原本的首帧保护；只有
        // FrostedHeroRoute 自己正在反向且明确不是完整 pop 时才跳过保护。
        final frostedTransitionReversing =
            FrostedHeroRoute.backdropProgress.value > 0.001 ||
            (activeAnim != null &&
                activeAnim.status == AnimationStatus.reverse);
        final captureFrame =
            coveringReversing &&
            (FrostedHeroRoute.capturePopTargetFrame ||
                !frostedTransitionReversing) &&
            driving > 0.95;
        final raw = captureFrame ? 0.0 : (covered ? driving : 0.0);
        final t = Curves.easeOutCubic.transform(raw.clamp(0.0, 1.0));
        // 卡片飞行期间背景（含卡片）整体渐隐为半透明（1 → 0.40），
        // 突出正在放大的新页面；退出（返回）时随 t 回落到 1 恢复清晰。
        return Opacity(
          opacity: (1 - 0.60 * t).clamp(0.0, 1.0),
          child: Transform.scale(
            // 1 → 0.90：向页面中心收缩（iOS 开 App 同款景深）
            scale: 1 - 0.10 * t,
            alignment: Alignment.center,
            child: ClipRRect(
              // 收缩同时出现圆角（0 → 16px），更像 iOS 页面后撤的卡片
              borderRadius: BorderRadius.circular(16 * t),
              // 圆角为 0（页面正常展示 / 转场静止期，绝大多数时间）时
              // 降级为 hardEdge：矩形裁剪无需抗锯齿，省掉一层抗锯齿
              // 裁剪 —— 本组件常驻在每个主页面的根节点，长列表滚动时
              // 这笔开销是白付的；有圆角时保留 antiAlias 保证边缘平滑。
              // 只改 clipBehavior（RenderObject 属性），不切换子树结构，
              // 不会重建页面 State。
              clipBehavior: t > 0.001 ? Clip.antiAlias : Clip.hardEdge,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
