import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// 液态交互追踪器 —— 根据手势位移产生弹性缩放与倾斜
class LiquidTracker {
  final AnimationController _scaleXCtrl;
  final AnimationController _scaleYCtrl;
  final AnimationController _rotXCtrl;
  final AnimationController _rotYCtrl;

  /// 四个动画的当前值（0.0 ~ 1.0）
  late final Animation<double> scaleX;
  late final Animation<double> scaleY;
  late final Animation<double> rotX;
  late final Animation<double> rotY;

  final SpringDescription _spring = const SpringDescription(
    mass: 1,
    stiffness: 180,
    // damping = 2 * dampingRatio * sqrt(stiffness)
    // 0.35 → 15.27, 0.5 → 21.21
    damping: 15.27, // dampingRatio = 0.35
  );

  final SpringDescription _rotSpring = const SpringDescription(
    mass: 1,
    stiffness: 180,
    damping: 21.21, // dampingRatio = 0.5
  );

  LiquidTracker(TickerProvider vsync)
      : _scaleXCtrl = AnimationController(vsync: vsync),
        _scaleYCtrl = AnimationController(vsync: vsync),
        _rotXCtrl = AnimationController(vsync: vsync),
        _rotYCtrl = AnimationController(vsync: vsync) {
    // 把控制器包装为可监听的 Animation 对象
    scaleX = _scaleXCtrl;
    scaleY = _scaleYCtrl;
    rotX = _rotXCtrl;
    rotY = _rotYCtrl;

    // 初始状态：无变形、无倾斜
    _scaleXCtrl.value = 1.0;
    _scaleYCtrl.value = 1.0;
    _rotXCtrl.value = 0.0;
    _rotYCtrl.value = 0.0;
  }

  void dispose() {
    _scaleXCtrl.dispose();
    _scaleYCtrl.dispose();
    _rotXCtrl.dispose();
    _rotYCtrl.dispose();
  }

  /// 处理移动手势 — 使用位移增量来驱动变形
  /// 通常从 GestureDetector.onPanUpdate 中调用：tracker.applyPanUpdate(details.delta)
  void applyPanUpdate(Offset delta) {
    // 使用 delta 的方向和大小模拟速度（幅度可调）
    final scaleTargets = _getLiquidScale(delta.dx, delta.dy);
    _animateScaleTo(scaleTargets.dx, scaleTargets.dy);
  }

  /// 手势结束 / 取消时调用，恢复到原始状态
  void resetToRest() {
    _animateScaleTo(1.0, 1.0);
    animateTilt(0.0, 0.0);
  }

  /// 手动设置统一缩放 (0.6~1.4)
  void animateScale(double scale) {
    _animateScaleTo(scale, scale);
  }

  /// 手动设置倾斜角度（建议范围 -10~10）
  void animateTilt(double rotXValue, double rotYValue) {
    _rotXCtrl.animateWith(
      SpringSimulation(_rotSpring, _rotXCtrl.value, rotXValue, 0),
    );
    _rotYCtrl.animateWith(
      SpringSimulation(_rotSpring, _rotYCtrl.value, rotYValue, 0),
    );
  }

  void _animateScaleTo(double sx, double sy) {
    _scaleXCtrl.animateWith(
      SpringSimulation(_spring, _scaleXCtrl.value, sx, 0),
    );
    _scaleYCtrl.animateWith(
      SpringSimulation(_spring, _scaleYCtrl.value, sy, 0),
    );
  }

  /// 与 Android 版逻辑一致的液态拉伸计算
  Offset _getLiquidScale(double dx, double dy) {
    final absDx = dx.abs();
    final absDy = dy.abs();
    const factor = 0.5; // 变形强度

    double scaleX, scaleY;
    if (absDx > absDy) {
      // 水平方向为主：拉伸 X，压缩 Y
      scaleX = 1.0 + absDx * factor;
      scaleY = 1.0 - absDx * factor * 0.5;
    } else {
      // 垂直方向为主：拉伸 Y，压缩 X
      scaleX = 1.0 - absDy * factor * 0.5;
      scaleY = 1.0 + absDy * factor;
    }

    return Offset(
      clampDouble(scaleX, 0.6, 1.4),
      clampDouble(scaleY, 0.6, 1.4),
    );
  }
}