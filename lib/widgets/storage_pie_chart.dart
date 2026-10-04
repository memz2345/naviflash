                                     
  
                            
  
                                         
                                    
                               
  
                                       
                                                             
                                 
                                              
                                                        
                                                          
                                      
import 'dart:math' as math;

import 'package:flutter/material.dart';

               
class StorageSlice {
  final String label;

                        
  final int bytes;

  final Color color;

  const StorageSlice({
    required this.label,
    required this.bytes,
    required this.color,
  });
}

                                            
                                           
                   
class StoragePieChart extends StatefulWidget {
                    
  final List<StorageSlice> slices;

                            
  final String totalLabel;

                 
  final String emptyLabel;

                              
  final double legendFlex;

  const StoragePieChart({
    super.key,
    required this.slices,
    required this.totalLabel,
    required this.emptyLabel,
    this.legendFlex = 0.55,
  });

  @override
  State<StoragePieChart> createState() => _StoragePieChartState();
}

class _StoragePieChartState extends State<StoragePieChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  int? _selected;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _anim = CurvedAnimation(
      parent: _ctrl,
      curve: const Cubic(0.2, 0.0, 0.0, 1.0),                         
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant StoragePieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
                             
    if (oldWidget.slices.length != widget.slices.length ||
        oldWidget.totalLabel != widget.totalLabel) {
      _ctrl
        ..value = 0
        ..forward();
    }
    if (_selected != null && _selected! >= widget.slices.length) {
      _selected = null;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _total =>
      widget.slices.fold<int>(0, (sum, s) => sum + (s.bytes > 0 ? s.bytes : 0));

  void _toggle(int index) {
    setState(() => _selected = _selected == index ? null : index);
  }

                    
  static double _thicknessFor(double size) {
    if (size >= 190) return 24;
    if (size >= 150) return 22;
    return 18;
  }

                                  
  int? _hitTest(Offset local, Size size, int total) {
    if (total <= 0) return null;
    final center = size.center(Offset.zero);
    final thickness = _thicknessFor(size.shortestSide);
    final labelSpace = _labelSpaceFor(size.shortestSide);
    final outer = size.shortestSide / 2 - labelSpace;
    final inner = outer - thickness - 8;               
    final d = (local - center).distance;
    if (d < inner || d > outer) return null;

                  
    var angle = math.atan2(local.dx - center.dx, -(local.dy - center.dy));
    if (angle < 0) angle += 2 * math.pi;
    var start = 0.0;
    for (var i = 0; i < widget.slices.length; i++) {
      final bytes = widget.slices[i].bytes;
      if (bytes <= 0) continue;
      final sweep = (bytes / total) * 2 * math.pi;
      if (angle >= start && angle < start + sweep) return i;
      start += sweep;
    }
    return null;
  }

                                 
  static double _labelSpaceFor(double size) => size >= 180 ? 26.0 : 0.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = _total;
    final hasData = total > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
                                              
                                             
        final wide = constraints.maxWidth >= 420;
        final chart = _buildChart(context, cs, total, hasData);
        final legend = _buildLegend(context, cs, total);

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: chart),
              const SizedBox(height: 16),
              legend,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: constraints.maxWidth * (1 - widget.legendFlex),
              child: Center(child: chart),
            ),
            const SizedBox(width: 12),
            Expanded(child: legend),
          ],
        );
      },
    );
  }

  Widget _buildChart(
    BuildContext context,
    ColorScheme cs,
    int total,
    bool hasData,
  ) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = math.min(210.0, c.maxWidth);
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        return AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: hasData
                  ? (d) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null) return;
                      final local = box.globalToLocal(d.globalPosition);
                      final index = _hitTest(local, Size(size, size), total);
                      if (index != null) _toggle(index);
                    }
                  : null,
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(size, size),
                      painter: _DonutPainter(
                        slices: widget.slices,
                        total: total,
                        progress: _anim.value,
                        selected: _selected,
                        trackColor: cs.surfaceContainerHighest.withValues(
                          alpha: 0.55,
                        ),
                        thickness: _thicknessFor(size),
                        labelSpace: _labelSpaceFor(size),
                        textScale: textScale,
                        labelBackdrop: cs.surface,
                      ),
                    ),
                    _buildCenter(context, cs, total, hasData),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCenter(
    BuildContext context,
    ColorScheme cs,
    int total,
    bool hasData,
  ) {
    final textTheme = Theme.of(context).textTheme;
    if (!hasData) {
      return SizedBox(
        width: 108,
        child: Text(
          widget.emptyLabel,
          textAlign: TextAlign.center,
          style: textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }
    final selected = _selected;
    final slice = selected == null ? null : widget.slices[selected];
    final bytes = slice?.bytes ?? total;
    final caption = slice?.label ?? widget.totalLabel;
    final percent = slice == null
        ? null
        : (total == 0 ? 0 : (slice.bytes / total * 100).round());
                              
    final accent = slice?.color ?? cs.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatBytes(bytes),
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 92,
          child: Text(
            percent == null ? caption : '$caption · $percent%',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: slice == null
                  ? cs.onSurfaceVariant
                  : accent.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context, ColorScheme cs, int total) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.slices.length; i++)
          _LegendRow(
            slice: widget.slices[i],
            total: total,
            selected: _selected == i,
            textTheme: textTheme,
            colorScheme: cs,
            onTap: widget.slices[i].bytes > 0 ? () => _toggle(i) : null,
          ),
      ],
    );
  }

                                    
  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const gb = 1024 * 1024 * 1024;
    const mb = 1024 * 1024;
    const kb = 1024;
    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(2)} GB';
    if (bytes >= mb) {
      final v = bytes / mb;
      return '${v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(1)} MB';
    }
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

                                 
  static String _shortBytes(int bytes) {
    const gb = 1024 * 1024 * 1024;
    const mb = 1024 * 1024;
    const kb = 1024;
    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(0)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(0)} KB';
    return '$bytes B';
  }
}

class _LegendRow extends StatelessWidget {
  final StorageSlice slice;
  final int total;
  final bool selected;
  final TextTheme textTheme;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  const _LegendRow({
    required this.slice,
    required this.total,
    required this.selected,
    required this.textTheme,
    required this.colorScheme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total <= 0 || slice.bytes <= 0
        ? 0
        : (slice.bytes / total * 100).round();
    final dim = slice.bytes <= 0;
                            
    final accent = dim ? colorScheme.outline : slice.color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.7)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                slice.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: dim ? colorScheme.outline : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _StoragePieChartState._formatBytes(slice.bytes),
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 38,
              child: Text(
                '$percent%',
                textAlign: TextAlign.right,
                style: textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

                                        
                                           
class _DonutPainter extends CustomPainter {
  final List<StorageSlice> slices;
  final int total;
  final double progress;
  final int? selected;
  final Color trackColor;
  final double thickness;

                          
  final double labelSpace;

                  
  final double textScale;

                                      
  final Color labelBackdrop;

  const _DonutPainter({
    required this.slices,
    required this.total,
    required this.progress,
    required this.selected,
    required this.trackColor,
    required this.thickness,
    required this.labelSpace,
    required this.textScale,
    required this.labelBackdrop,
  });

  static const _gap = 0.035;            

                                  
  static const _minLabelSweep = 0.30;         

                        
  static const _minTwoLineSweep = 0.62;         

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxExpand = 4.0;
    final radius =
        size.shortestSide / 2 - thickness / 2 - labelSpace - maxExpand - 2;
    final sweep0 = -math.pi / 2;

                   
    if (total <= 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..color = trackColor,
      );
      return;
    }

    var start = sweep0;
    final fullCircle = slices.where((s) => s.bytes > 0).length == 1;
    for (var i = 0; i < slices.length; i++) {
      final bytes = slices[i].bytes;
      if (bytes <= 0) continue;
      final sweep = (bytes / total) * 2 * math.pi * progress;
      if (sweep <= 0) continue;
      final isSelected = selected == i;
      final r = radius + (isSelected ? maxExpand : 0);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness + (isSelected ? 6 : 0)
        ..strokeCap = StrokeCap.butt
        ..color = slices[i].color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        start,
        fullCircle ? sweep : math.max(sweep - _gap, 0.001),
        false,
        paint,
      );
      start += sweep;
    }

                                 
    if (labelSpace > 0 && progress > 0.85) {
      _drawArcLabels(canvas, center, radius, sweep0);
    }
  }

  void _drawArcLabels(Canvas canvas, Offset center, double radius,
      double sweep0) {
    var start = sweep0;
    for (var i = 0; i < slices.length; i++) {
      final bytes = slices[i].bytes;
      if (bytes <= 0) continue;
      final sweep = (bytes / total) * 2 * math.pi;
      start += sweep;
      if (sweep < _minLabelSweep) continue;

      final percent = (bytes / total * 100).round();
      final text = sweep >= _minTwoLineSweep
          ? '$percent%\n${_StoragePieChartState._shortBytes(bytes)}'
          : '$percent%';
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 11 * textScale,
            fontWeight: FontWeight.w600,
            height: 1.15,
            color: slices[i].color,
                                      
            shadows: [
              Shadow(
                color: labelBackdrop.withValues(alpha: 0.95),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      final mid = start - sweep / 2;
      final r = radius + thickness / 2 + 13;
      final pos = center + Offset(math.cos(mid) * r, math.sin(mid) * r);
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.total != total ||
      old.progress != progress ||
      old.selected != selected ||
      old.trackColor != trackColor ||
      old.thickness != thickness ||
      old.labelSpace != labelSpace ||
      old.textScale != textScale ||
      old.labelBackdrop != labelBackdrop ||
      old.slices != slices;
}
