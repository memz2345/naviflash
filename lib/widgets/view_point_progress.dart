// lib/widgets/view_point_progress.dart
//
// segment_progress_bar.dart 思路，绘制在播放器进度条轨道上）：
//   - 输入：BiliViewPoint 列表 + 视频总时长，按 from/to 归一化为 0~1 比例
//   - 绘制：按 type 着色的小圆角条，叠在 Slider 轨道上（水平缩进 = 拇指半径，
//     垂直居中 = 轨道中心），并忽略指针不阻挡拖拽
import 'package:flutter/material.dart';
import 'package:naviflash/services/bilibili_video_service.dart';

/// 归一化后的高能片段（start/end ∈ [0,1]，相对进度条总宽度）。
class ViewPointSegment {
  final double start;
  final double end;
  final Color color;

  const ViewPointSegment({
    required this.start,
    required this.end,
    required this.color,
  });
}

/// 根据 type 选色（B 站官方配色近似：看点绿 / 高能粉 / 高能片段橙）。
Color viewPointColor(int type) {
  switch (type) {
    case 1:
      return const Color(0xFF52C41A);
    case 2:
      return const Color(0xFFFB7299);
    case 3:
      return const Color(0xFFFF7043);
    default:
      return const Color(0xFFFB7299);
  }
}

/// 把高能片段列表按总时长归一化为 0~1 比例。
/// [duration] 为视频总时长；时长未知（<=0）时返回空。
List<ViewPointSegment> buildViewPointSegments(
  List<BiliViewPoint> points,
  Duration duration,
) {
  if (points.isEmpty || duration.inMilliseconds <= 0) return const [];
  final total = duration.inMilliseconds / 1000.0;
  return points.map((p) {
    final start = (p.from / total).clamp(0.0, 1.0);
    final end = (p.to / total).clamp(0.0, 1.0);
    if (end <= start) return null;
    return ViewPointSegment(
      start: start,
      end: end,
      color: viewPointColor(p.type),
    );
  }).whereType<ViewPointSegment>().toList();
}

/// 叠加在播放器进度条上的高能片段层（忽略指针，纯展示）。
class ViewPointProgressOverlay extends StatelessWidget {
  final List<ViewPointSegment> segments;

  /// 与 SliderThemeData.trackHeight 一致（嵌入式 3，全屏 4）。
  final double trackHeight;

  /// 与 SliderThemeData 拇指半径一致（用于计算轨道水平缩进）。
  final double thumbRadius;

  const ViewPointProgressOverlay({
    super.key,
    this.segments = const [],
    this.trackHeight = 3,
    this.thumbRadius = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: _ViewPointPainter(
          segments: segments,
          trackHeight: trackHeight,
          thumbRadius: thumbRadius,
        ),
      ),
    );
  }
}

class _ViewPointPainter extends CustomPainter {
  final List<ViewPointSegment> segments;
  final double trackHeight;
  final double thumbRadius;

  _ViewPointPainter({
    required this.segments,
    required this.trackHeight,
    required this.thumbRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;
    final left = thumbRadius;
    final right = size.width - thumbRadius;
    final trackWidth = right - left;
    if (trackWidth <= 0) return;
    final centerY = size.height / 2;
    final top = centerY - trackHeight / 2;
    final radius = Radius.circular(trackHeight / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    for (final seg in segments) {
      final x0 = left + seg.start * trackWidth;
      final x1 = left + seg.end * trackWidth;
      if (x1 - x0 < 0.5) continue;
      paint.color = seg.color.withValues(alpha: 0.9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x0, top, x1 - x0, trackHeight),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ViewPointPainter oldDelegate) {
    if (oldDelegate.trackHeight != trackHeight ||
        oldDelegate.thumbRadius != thumbRadius) {
      return true;
    }
    final a = oldDelegate.segments;
    final b = segments;
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if (a[i].start != b[i].start ||
          a[i].end != b[i].end ||
          a[i].color != b[i].color) {
        return true;
      }
    }
    return false;
  }
}
