import 'dart:async';

import 'package:flutter/widgets.dart';

/// 一个「动画是否正在进行」的判定条件。
///
/// [notifier] 每次通知时重新求值 [busy]；返回 true 表示动画仍在跑，
/// 页面应继续显示加载指示器。
///
/// 例：tab 切换动画 —— [TabController] 内部是 unbounded 控制器，
/// `isCompleted` 语义不可靠，需改用 [TabController.indexIsChanging]：
/// ```dart
/// GateCondition(_tabController, () => _tabController.indexIsChanging)
/// ```
class GateCondition {
  const GateCondition(this.notifier, this.busy);

  /// 条件变化源（[TabController] / [AnimationController] / [ValueNotifier] 等）。
  final Listenable notifier;

  /// true = 动画正在进行，内容暂不显示。
  final ValueGetter<bool> busy;
}

/// 页面内容「延迟显示」门控。
///
/// **背景**：内容页（长列表 / 大网格）若在页面转场动画（路由 push、tab 切换）
/// 进行中完成加载，会在动画途中插入一次重型 build，肉眼可见掉帧卡顿。
///
/// **约定**：只要还有被监听的动画未结束，页面就继续显示加载指示器；
/// 全部结束后才一次性显示内容。
///
/// **用法**：页面在开始加载时 [arm]，build 时用 [isGated] 决定是否继续显示
/// 加载指示器。
/// ```dart
/// _gate = ContentRevealGate(onUnlock: () => setState(() {}))
///   ..arm(context, conditions: [
///     GateCondition(_tabController, () => _tabController.indexIsChanging),
///   ]);
/// // build：if (loading || (_gate?.isGated ?? false)) → 加载指示器
/// ```
///
/// 门控是一次性的（latch）：解锁后 [isGated] 恒为 false，
/// 因此下拉刷新、加载更多等后续操作不受影响。
class ContentRevealGate {
  ContentRevealGate({
    required this.onUnlock,
    this.fallbackTimeout = const Duration(milliseconds: 1500),
  });

  /// 所有动画结束后回调（整个生命周期至多触发一次）。
  final VoidCallback onUnlock;

  /// 兜底超时：动画因异常迟迟不 completed（或反向播放）时强制放行，
  /// 避免永久卡在加载指示器。
  final Duration fallbackTimeout;

  bool _unlocked = false;

  /// [arm] 之后、首帧绑定评估完成之前：一律保守地视为「动画进行中」，
  /// 避免「arm → 同步 setState（数据秒回/命中缓存）」这一帧漏过门控。
  bool _pending = false;

  bool _started = false;
  bool _disposed = false;
  Timer? _fallback;
  final List<_GateWatch> _watches = <_GateWatch>[];

  /// true = 动画仍在进行，内容应继续显示加载指示器。
  bool get isGated => _pending || !_unlocked;

  /// true = 动画已全部结束，内容可以显示。
  bool get isUnlocked => _unlocked;

  /// 启动门控（每个实例只能启动一次，重复调用忽略）。
  ///
  /// - [waitForRouteAnimation]：等待当前路由的转场动画（[ModalRoute.animation]）
  ///   播放完成。
  /// - [conditions]：额外等待的动画条件，如 tab 切换。
  ///
  /// 绑定统一延迟到首帧之后：[arm] 常在 initState / 加载起点被调用，
  /// 此时建立 InheritedWidget 依赖不安全。
  void arm(
    BuildContext context, {
    bool waitForRouteAnimation = true,
    List<GateCondition> conditions = const <GateCondition>[],
  }) {
    if (_disposed || _started) return;
    _started = true;
    _pending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !context.mounted) return;
      if (waitForRouteAnimation) {
        _watchAnimation(ModalRoute.of(context)?.animation);
      }
      for (final condition in conditions) {
        _watches.add(
          _GateWatch(
            busy: condition.busy,
            attach: () {
              condition.notifier.addListener(_evaluate);
              return () => condition.notifier.removeListener(_evaluate);
            },
          ),
        );
      }
      for (final watch in _watches) {
        watch.detach = watch.attach();
      }
      _pending = false;
      _evaluate();
    });
  }

  /// 等待 [anim] 播放完成（[Animation.isCompleted]）后放行；null 时忽略。
  void _watchAnimation(Animation<double>? anim) {
    if (anim == null) return;
    _watches.add(
      _GateWatch(
        busy: () => !anim.isCompleted,
        attach: () {
          void onStatus(AnimationStatus status) {
            if (status == AnimationStatus.completed) _evaluate();
          }
          anim.addStatusListener(onStatus);
          return () => anim.removeStatusListener(onStatus);
        },
      ),
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _fallback?.cancel();
    _fallback = null;
    _unbind();
    _watches.clear();
  }

  void _evaluate() {
    if (_disposed || _unlocked) return;
    if (_watches.any((watch) => watch.busy())) {
      // 仍有动画在跑：起兜底定时器，防止动画异常时永久 loading。
      _fallback ??= Timer(fallbackTimeout, _unlock);
      return;
    }
    _unlock();
  }

  void _unlock() {
    if (_disposed || _unlocked) return;
    _unlocked = true;
    _fallback?.cancel();
    _fallback = null;
    _unbind();
    onUnlock();
  }

  void _unbind() {
    for (final watch in _watches) {
      watch.detach?.call();
      watch.detach = null;
    }
  }
}

/// 单个被监听的动画 / 条件。
class _GateWatch {
  _GateWatch({required this.busy, required this.attach});

  /// 该动画是否仍在进行。
  final ValueGetter<bool> busy;

  /// 挂载监听，返回解绑函数。
  final ValueGetter<VoidCallback> attach;

  /// [ContentRevealGate.arm] 后写入，解锁后清空。
  VoidCallback? detach;
}
