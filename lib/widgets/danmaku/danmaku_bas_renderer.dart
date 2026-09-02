import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'danmaku_bas_model.dart';

/// BAS 高级弹幕 Canvas 渲染器
/// 负责根据当前视频时间，计算每个 BAS 元素的插值状态并绘制
class DanmakuBasRenderer {
  /// 绘制所有活跃的 BAS 弹幕
  static void paint(
    Canvas canvas,
    Size size,
    List<BasDanmaku> activeBasList,
    double currentTime,
    double globalOpacity,
    double fontSizeScale,
  ) {
    for (final bas in activeBasList) {
      if (bas.finished) continue;
      final elapsed = currentTime - bas.startTime;
      if (elapsed < 0 || elapsed > bas.totalDuration) continue;

      for (final el in bas.elements) {
        _paintElement(canvas, size, el, elapsed, globalOpacity, fontSizeScale);
      }
    }
  }

  static void _paintElement(
    Canvas canvas,
    Size size,
    BasElement el,
    double elapsed,
    double globalOpacity,
    double fontSizeScale,
  ) {
    // 尚未到 delay 或已超过 duration → 不绘制
    final localT = elapsed - el.delay;
    if (localT < 0 || localT > el.duration) return;

    // ── 计算当前属性（插值）──
    final pos = _interpolatePosition(el, localT, size);
    final alpha = _interpolateAlpha(el, localT);
    final scale = _interpolateScale(el, localT);
    final rotate = _interpolateRotate(el, localT);

    final finalAlpha = (alpha * el.alpha * globalOpacity).clamp(0.0, 1.0);
    if (finalAlpha <= 0.01) return;

    final fs = el.fontSize * fontSizeScale;
    final color = el.color.withOpacity(
      (el.color.opacity * finalAlpha).clamp(0.0, 1.0),
    );

    // ── 构建 TextPainter ──
    final textPainter = TextPainter(
      text: TextSpan(
        text: el.text,
        style: TextStyle(
          fontSize: fs,
          color: color,
          fontWeight: el.bold ? FontWeight.bold : FontWeight.normal,
          fontStyle: el.italic ? FontStyle.italic : FontStyle.normal,
          shadows: const [
            Shadow(blurRadius: 3, color: Colors.black87, offset: Offset(1, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: size.width * 3);

    final textW = textPainter.width;
    final textH = textPainter.height;

    // ── Canvas 变换 ──
    canvas.save();

    // 平移到元素中心
    final cx = pos.dx;
    final cy = pos.dy;
    canvas.translate(cx, cy);

    // 旋转
    if (rotate.abs() > 0.001) {
      canvas.rotate(rotate);
    }

    // 缩放
    if ((scale - 1.0).abs() > 0.001) {
      canvas.scale(scale, scale);
    }

    // 绘制（以中心为锚点）
    textPainter.paint(canvas, Offset(-textW / 2, -textH / 2));

    canvas.restore();
    textPainter.dispose();
  }

  // ─── 插值计算 ───

  static Offset _interpolatePosition(BasElement el, double t, Size size) {
    double baseX = el.isNormalized ? el.x * size.width : el.x;
    double baseY = el.isNormalized ? el.y * size.height : el.y;

    if (el.move.isEmpty) return Offset(baseX, baseY);

    // 在关键帧之间线性插值
    final frames = el.move;
    if (frames.length == 1) {
      final f = frames[0];
      final fx = el.isNormalized ? f.x * size.width : f.x;
      final fy = el.isNormalized ? f.y * size.height : f.y;
      return Offset(fx, fy);
    }

    // 找到 t 所在的区间
    if (t <= frames.first.t) {
      final f = frames.first;
      return Offset(
        el.isNormalized ? f.x * size.width : f.x,
        el.isNormalized ? f.y * size.height : f.y,
      );
    }
    if (t >= frames.last.t) {
      final f = frames.last;
      return Offset(
        el.isNormalized ? f.x * size.width : f.x,
        el.isNormalized ? f.y * size.height : f.y,
      );
    }

    for (int i = 0; i < frames.length - 1; i++) {
      final a = frames[i];
      final b = frames[i + 1];
      if (t >= a.t && t <= b.t) {
        final ratio = (b.t - a.t) > 0 ? (t - a.t) / (b.t - a.t) : 0.0;
        final lx = _lerp(a.x, b.x, ratio);
        final ly = _lerp(a.y, b.y, ratio);
        return Offset(
          el.isNormalized ? lx * size.width : lx,
          el.isNormalized ? ly * size.height : ly,
        );
      }
    }

    return Offset(baseX, baseY);
  }

  static double _interpolateAlpha(BasElement el, double t) {
    if (el.alphaFrames.isEmpty) return el.alpha;
    return _interpolateFrames(el.alphaFrames, t, (f) => f.alpha, el.alpha);
  }

  static double _interpolateScale(BasElement el, double t) {
    if (el.scaleFrames.isEmpty) return 1.0;
    return _interpolateFrames(el.scaleFrames, t, (f) => f.scale, 1.0);
  }

  static double _interpolateRotate(BasElement el, double t) {
    if (el.rotateFrames.isEmpty) return 0.0;
    return _interpolateFrames(el.rotateFrames, t, (f) => f.rotate, 0.0);
  }

  static double _interpolateFrames(
    List<BasKeyframe> frames,
    double t,
    double Function(BasKeyframe) getter,
    double fallback,
  ) {
    if (frames.isEmpty) return fallback;
    if (frames.length == 1) return getter(frames[0]);
    if (t <= frames.first.t) return getter(frames.first);
    if (t >= frames.last.t) return getter(frames.last);

    for (int i = 0; i < frames.length - 1; i++) {
      final a = frames[i];
      final b = frames[i + 1];
      if (t >= a.t && t <= b.t) {
        final ratio = (b.t - a.t) > 0 ? (t - a.t) / (b.t - a.t) : 0.0;
        return _lerp(getter(a), getter(b), ratio);
      }
    }
    return fallback;
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}