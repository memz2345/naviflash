// lib/widgets/frosted_route.dart
//
// iOS 风格转场路由：
//   - 转场期间「背景全部模糊」：底层旧页面用 BackdropFilter 模糊，
//     正在滑入的新页面用 ImageFiltered 模糊（两者共用同一渐变 sigma 曲线），
//     只有 Navigator 最上层的 Hero 飞行元素保持清晰；
//   - 模糊程度随转场进度渐变：开始快速升起 → 中段保持 → 结束平滑归零，
//     转场结束后模糊层被移除，页面恢复清晰、无残留渲染开销；
//   - 入场页面从右侧滑入，与 Hero 飞行共用同一 animation，时序天然对齐。
//
// 性能说明：sigma 随动画逐帧变化（渐变模糊更自然），每次变化会重光栅化
// 背景层；转场时长约 500ms、且结束即移除模糊层，整体开销可控。
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:naviflash/services/settings_service.dart';

/// 统一 Hero 转场路由工厂：
/// - 设置开启「Hero 转场背景模糊」→ [FrostedHeroRoute]（iOS 风格）
/// - 设置关闭 → 与引入该特性之前完全一致的 [MaterialPageRoute]
///   （平台默认转场 + 经典封面 Hero，无任何模糊/滑动）
Route<T> heroTransitionRoute<T>({
  required Widget page,
  bool heroZoom = false,
  RouteSettings? settings,
}) {
  if (!SettingsService.heroTransitionBlurEnabled) {
    return MaterialPageRoute<T>(settings: settings, builder: (_) => page);
  }
  return FrostedHeroRoute<T>(
    page: page,
    heroZoom: heroZoom,
    settings: settings,
  );
}

class FrostedHeroRoute<T> extends PageRouteBuilder<T> {
  /// 被覆盖页面（底层路由）的 iOS 景深缩放进度（0 = 原状，1 = 完全收缩）。
  ///
  /// PageRouteBuilder 类型的路由不会驱动下方路由的 `secondaryAnimation`
  /// （实测始终停留在 0），因此由本路由在转场期间主动驱动此值，
  /// 供被覆盖页（如搜索页）监听实现「页面向中心缩小」的 iOS 效果。
  static final ValueNotifier<double> backdropProgress = ValueNotifier(0);

  // ── 静态进度驱动：同一时刻只有最上层 FrostedHeroRoute 在转场，
  //    由它独占驱动 backdropProgress。路由生命周期负责抢占，
  //    transitionsBuilder 只作为动画尚未安装时的兜底。 ──
  static Animation<double>? _activeAnimation;
  static AnimationStatusListener? _activeStatusListener;

  // 只有从已完成的入场转场返回时，Hero 才需要一帧完整背景来测量
  // 卡片终点。入场尚未完成就被打断时，背景必须保持当前比例连续恢复。
  static bool _capturePopTargetFrame = false;

  /// 返回转场开始时是否需要保持背景完整一帧。
  static bool get capturePopTargetFrame => _capturePopTargetFrame;

  /// 当前驱动 backdropProgress 的路由动画。
  ///
  /// 供被覆盖页判断「本页是否就是驱动该进度的整页路由」：
  /// - 整页路由（FrostedHeroRoute）自身入场飞行 / 自身弹栈期间
  ///   不叠加背景缩放（避免双重形变）；
  /// - 而被覆盖页在「上方整页路由弹栈」期间 isCurrent 已被框架提前
  ///   置 true（didPopNext 在 pop 起始即派发），需要此信号配合
  ///   backdropProgress > 0 才能识别「正在被返回的整页路由覆盖」，
  ///   从而让背景在返回转场中持续缩放。
  static Animation<double>? get activeAnimation => _activeAnimation;

  /// 动画 tick（transientCallbacks 阶段）回调：更新共享进度。
  ///
  /// 必须在动画阶段更新 notifier——此时把下游监听方（被覆盖页的
  /// AnimatedBuilder）标记为脏是合法的；若在 transitionsBuilder 的
  /// build 阶段直接改 notifier，会触发「setState during build」异常。
  static void _onProgressTick() {
    final animation = _activeAnimation;
    if (animation == null) return;
    final progress = animation.value.clamp(0.0, 1.0);
    if (progress > 0.001) {
      if (backdropProgress.value != progress) {
        backdropProgress.value = progress;
      }
    } else if (backdropProgress.value != 0) {
      backdropProgress.value = 0;
    }
  }

  /// 转场结束（完成 / 路由被移除）时归零：
  /// - completed 归零：避免最上层路由的 animation 停在 1.0 产生残留值，
  ///   污染下一段转场（被覆盖页会瞬间跳到收缩态再展开）；被覆盖页保持
  ///   收缩仅需发生在转场进行中，完成后即可恢复。
  /// - dismissed 归零：兜底，避免残留缩放状态。
  static void _onProgressStatus(AnimationStatus status) {
    if ((status == AnimationStatus.dismissed ||
            status == AnimationStatus.completed) &&
        backdropProgress.value != 0) {
      backdropProgress.value = 0;
    }
    if (status == AnimationStatus.dismissed ||
        status == AnimationStatus.completed) {
      _capturePopTargetFrame = false;
    }
  }

  static void _claimProgress(Animation<double> animation) {
    if (identical(_activeAnimation, animation)) return;

    final oldAnimation = _activeAnimation;
    final oldStatusListener = _activeStatusListener;
    oldAnimation?.removeListener(_onProgressTick);
    if (oldAnimation != null && oldStatusListener != null) {
      oldAnimation.removeStatusListener(oldStatusListener);
    }

    _activeAnimation = animation;
    animation.addListener(_onProgressTick);

    // 旧路由的动画结束时不能清掉新路由的进度。
    late final AnimationStatusListener statusListener;
    statusListener = (status) {
      if (identical(_activeAnimation, animation)) {
        _onProgressStatus(status);
      }
    };
    _activeStatusListener = statusListener;
    animation.addStatusListener(statusListener);
  }

  static void _attachProgress(Animation<double> animation) {
    if (identical(_activeAnimation, animation)) return;
    // 被覆盖的旧路由会因 secondaryAnimation 重建并重新走
    // transitionsBuilder。只要当前动画仍在进行，就保持最上层路由的
    // 独占权；新路由会在 didPush/didPop 中先主动抢占。
    final active = _activeAnimation;
    if (active != null &&
        (active.status == AnimationStatus.forward ||
            active.status == AnimationStatus.reverse)) {
      return;
    }
    _claimProgress(animation);
  }

  FrostedHeroRoute({
    required Widget page,
    double blurSigma = 12.0,

    /// 转场时长（正向/反向一致）。Hero 飞行共用本路由动画，
    /// 因此调慢这里 = 整页放大/缩回卡片的飞行同时变慢。
    Duration transitionDuration = const Duration(milliseconds: 500),

    /// iOS 开 App 风格：整个 Hero（如整张卡片）自行放大到全屏，
    /// 入场页面不模糊、不滑动，只对底层旧页面做渐变模糊。
    bool heroZoom = false,
    RouteSettings? settings,
  }) : super(
         settings: settings,
         transitionDuration: transitionDuration,
         reverseTransitionDuration: transitionDuration,
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // 只挂一次监听：动画 tick 阶段驱动 backdropProgress，
           // 避免在 build 阶段修改 notifier（会打脏被覆盖页的
           // AnimatedBuilder，触发 setState during build）。
           _attachProgress(animation);
           // 模糊强度渐变曲线：0 → 峰值(保持) → 0。
           // 反向（返回）时随 animation 自动镜像，同样平滑。
           final sigmaTween = TweenSequence<double>([
             TweenSequenceItem(
               tween: Tween(
                 begin: 0.0,
                 end: 1.0,
               ).chain(CurveTween(curve: Curves.easeOut)),
               weight: 25,
             ),
             TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
             TweenSequenceItem(
               tween: Tween(
                 begin: 1.0,
                 end: 0.0,
               ).chain(CurveTween(curve: Curves.easeIn)),
               weight: 40,
             ),
           ]);
           return AnimatedBuilder(
             animation: animation,
             builder: (context, _) {
               final sigma = blurSigma * sigmaTween.evaluate(animation);
               return Stack(
                 fit: StackFit.expand,
                 children: [
                   // 旧页面模糊层：只模糊其下方（旧页面），不影响上层
                   if (sigma > 0.5)
                     IgnorePointer(
                       child: BackdropFilter(
                         filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                         child: const SizedBox.expand(),
                       ),
                     ),
                   if (heroZoom)
                     // iOS 开 App 风格：页面的所有几何变化都交给 Hero。
                     // 不在路由层叠加反向平移，否则打断返回时会让 Hero
                     // 的起点和目标卡片在同一帧发生两次位移。
                     child
                   else
                     // 常规模式：入场页面淡入 + 滑入；滑入期间自身同样
                     // 处于渐变模糊中，到站后 sigma 归零自动恢复清晰
                     FadeTransition(
                       opacity: CurvedAnimation(
                         parent: animation,
                         curve: Curves.easeOutCubic,
                       ),
                       child: SlideTransition(
                         position:
                             Tween<Offset>(
                               begin: const Offset(1, 0),
                               end: Offset.zero,
                             ).animate(
                               CurvedAnimation(
                                 parent: animation,
                                 curve: Curves.easeOutCubic,
                                 reverseCurve: Curves.easeInCubic,
                               ),
                             ),
                         child: sigma > 0.5
                             ? ImageFiltered(
                                 imageFilter: ImageFilter.blur(
                                   sigmaX: sigma,
                                   sigmaY: sigma,
                                 ),
                                 child: child,
                               )
                             : child,
                       ),
                     ),
                 ],
               );
             },
           );
         },
       );

  @override
  TickerFuture didPush() {
    _capturePopTargetFrame = false;
    final result = super.didPush();
    final routeAnimation = animation;
    if (routeAnimation != null) _claimProgress(routeAnimation);
    return result;
  }

  @override
  bool didPop(T? result) {
    // pop 可能发生在 push 尚未完成时，必须立刻把同一个动画的反向进度
    // 交给背景层，不能等到下一次 transitionsBuilder 重建才接管。
    final routeAnimation = animation;
    _capturePopTargetFrame =
        routeAnimation?.status == AnimationStatus.completed;
    if (routeAnimation != null) _claimProgress(routeAnimation);
    return super.didPop(result);
  }
}
