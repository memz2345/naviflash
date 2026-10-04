                                       
  
                                              
                                                        
                                                   
                              
import 'package:flutter/material.dart';
import 'package:naviflash/services/bilibili_video_service.dart';

                                          
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

                               
class ViewPointProgressOverlay extends StatelessWidget {
  final List<ViewPointSegment> segments;

                                                   
  final double trackHeight;

                                           
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
