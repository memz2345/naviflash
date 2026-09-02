import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'danmaku_controller.dart';
import 'danmaku_model.dart';
import 'danmaku_bas_renderer.dart';

class DanmakuView extends StatefulWidget {
  final DanmakuController controller;

  const DanmakuView({super.key, required this.controller});

  @override
  State<DanmakuView> createState() => _DanmakuViewState();
}

class _DanmakuViewState extends State<DanmakuView> {
  @override
  void initState() {
    super.initState();
    widget.controller.onNeedRepaint = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void didUpdateWidget(DanmakuView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      widget.controller.onNeedRepaint = () {
        if (mounted) setState(() {});
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        widget.controller.setSize(constraints.maxWidth, constraints.maxHeight);
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _DanmakuPainter(widget.controller),
        );
      },
    );
  }
}

class _DanmakuPainter extends CustomPainter {
  final DanmakuController controller;

  _DanmakuPainter(this.controller);

  @override
  void paint(Canvas canvas, Size size) {
    if (!controller.enabled) return;

    // ─── 智能防遮挡 ───
    // 有主体遮罩时先把弹幕画进离屏层，再用遮罩 dstOut 挖掉主体区域，
    final mask = controller.smartMask ? controller.personMask : null;
    if (mask != null) {
      canvas.saveLayer(Offset.zero & size, Paint());
    }

    // ─── 普通弹幕绘制 ───
    final danmakus = controller.activeDanmakus;
    final lineHeight = controller.lineHeight;
    final usableHeight = controller.usableHeight;
    final fontWeight = FontWeight.values[
        controller.fontWeight.round().clamp(0, FontWeight.values.length - 1)];
    final strokeShadows = _strokeShadows(controller.strokeWidth);

    for (final dm in danmakus) {
      final item = dm.item;
      final mode = controller.effectiveMode(item);
      final fs = controller.effectiveFontSize;
      final color = item.color.withOpacity(
        (item.color.opacity * controller.opacity).clamp(0.0, 1.0),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: item.content,
          style: TextStyle(
            fontSize: fs,
            color: color,
            fontWeight: fontWeight,
            shadows: strokeShadows,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: size.width * 2);

      double x, y;
      switch (mode) {
        case DanmakuMode.scrollRightToLeft:
        case DanmakuMode.reverseScroll:
          x = dm.x;
          y = dm.track * lineHeight + (lineHeight - fs) / 2;
          break;
        case DanmakuMode.top:
          x = (size.width - textPainter.width) / 2;
          y = dm.track * lineHeight + (lineHeight - fs) / 2;
          break;
        case DanmakuMode.bottom:
          x = (size.width - textPainter.width) / 2;
          y = usableHeight - (dm.track + 1) * lineHeight + (lineHeight - fs) / 2;
          break;
        default:
          textPainter.dispose();
          continue;
      }

      // 裁剪超出屏幕的部分
      if (x + textPainter.width < 0 || x > size.width) {
        textPainter.dispose();
        continue;
      }

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, usableHeight));
      textPainter.paint(canvas, Offset(x, y));
      canvas.restore();
      textPainter.dispose();
    }

    // ─── BAS 高级弹幕绘制 ───
    if (controller.showAdvanced && controller.activeBasDanmakus.isNotEmpty) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, usableHeight));
      DanmakuBasRenderer.paint(
        canvas,
        size,
        controller.activeBasDanmakus,
        controller.currentTime,
        controller.opacity,
        controller.fontSizeScale,
      );
      canvas.restore();
    }

    // ─── 智能防遮挡：用主体遮罩挖掉弹幕（仅 alpha 通道参与 dstOut）───
    if (mask != null) {
      canvas.drawImageRect(
        mask,
        Rect.fromLTWH(
          0,
          0,
          mask.width.toDouble(),
          mask.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..blendMode = BlendMode.dstOut
          ..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    }
  }

  List<Shadow> _strokeShadows(double width) {
    if (width <= 0) return const [];
    const dirs = [
      Offset(-1, -1),
      Offset(0, -1),
      Offset(1, -1),
      Offset(1, 0),
      Offset(1, 1),
      Offset(0, 1),
      Offset(-1, 1),
      Offset(-1, 0),
    ];
    return [
      for (final d in dirs)
        Shadow(color: const Color(0xCC000000), blurRadius: 0, offset: d * width),
    ];
  }

  @override
  bool shouldRepaint(covariant _DanmakuPainter oldDelegate) => true;
}