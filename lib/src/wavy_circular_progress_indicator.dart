                                                   
  
                              
                                                                                   
                                
                            
                                                 
                                                  

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_new_shapes/material_new_shapes.dart' hide Cubic;

import 'wavy_progress_tokens.dart';

                                                                               
                                               
   
                                                                             
                                                                           
                                                                               
                      
   
                   
           
                                                
       
               
   
                                                                           
                
class CircularWavyProgressIndicator extends StatefulWidget {
                                                             
  const CircularWavyProgressIndicator({
    super.key,
    required this.progress,
    this.amplitude,
    this.color,
    this.trackColor,
    this.strokeCap = StrokeCap.round,
    this.strokeWidth = WavyProgressTokens.circularActiveThickness,
    this.trackStrokeWidth = WavyProgressTokens.circularTrackThickness,
    this.gapSize = WavyProgressTokens.circularTrackActiveSpace,
    this.wavelength = WavyProgressTokens.circularWavelength,
    double? waveSpeed,
    this.size = WavyProgressTokens.circularContainerSize,
    this.semanticsLabel,
    this.semanticsValue,
  })  : waveSpeed = waveSpeed ?? wavelength,
        amplitudeValue = 1.0,
        indeterminate = false;

                                                                
  const CircularWavyProgressIndicator.indeterminate({
    super.key,
    this.color,
    this.trackColor,
    this.strokeCap = StrokeCap.round,
    this.strokeWidth = WavyProgressTokens.circularActiveThickness,
    this.trackStrokeWidth = WavyProgressTokens.circularTrackThickness,
    this.gapSize = WavyProgressTokens.circularTrackActiveSpace,
    this.amplitudeValue = 1.0,
    this.wavelength = WavyProgressTokens.circularWavelength,
    double? waveSpeed,
    this.size = WavyProgressTokens.circularContainerSize,
    this.semanticsLabel,
  })  : progress = null,
        amplitude = null,
        semanticsValue = null,
        waveSpeed = waveSpeed ?? wavelength,
        indeterminate = true;

                                                                              
                                                                         
     
                                            
  final double? progress;

                                                                      
     
                                                                             
                                            
  final double Function(double progress)? amplitude;

                                                                     
  final double amplitudeValue;

                                        
  final Color? color;

                             
  final Color? trackColor;

                                                          
  final StrokeCap strokeCap;

                                            
  final double strokeWidth;

                                 
  final double trackStrokeWidth;

                                                         
  final double gapSize;

                                                                              
                                      
  final double wavelength;

                                                                              
                                                             
  final double waveSpeed;

                                                               
  final double size;

                                                     
  final String? semanticsLabel;

                                                     
  final String? semanticsValue;

                                                        
  final bool indeterminate;

  @override
  State<CircularWavyProgressIndicator> createState() =>
      _CircularWavyProgressIndicatorState();
}

class _CircularWavyProgressIndicatorState
    extends State<CircularWavyProgressIndicator> with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _amplitudeController;
  late final AnimationController _cycleController;

  double _amplitudeFrom = 0.0;
  double _amplitudeTarget = 0.0;
  double _amplitude = 0.0;

  final _CircularProgressDrawingCache _cache = _CircularProgressDrawingCache();

                                                                               
                                         
  bool _requiresMorph = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController.unbounded(vsync: this);
    _amplitudeController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: WavyProgressTokens.amplitudeAnimationDuration,
      ),
    );
    _cycleController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: WavyProgressTokens.circularAnimationProgressDuration,
      ),
    )..repeat();

    _amplitude = _targetAmplitude;
    _amplitudeFrom = _amplitude;
    _amplitudeTarget = _amplitude;
  }

  @override
  void didUpdateWidget(CircularWavyProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAmplitude();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _amplitudeController.dispose();
    _cycleController.dispose();
    super.dispose();
  }

  double get _targetAmplitude {
    if (widget.indeterminate) {
      return widget.amplitudeValue.clamp(0.0, 1.0);
    }
    final double progress = widget.progress!.clamp(0.0, 1.0);
    final double Function(double)? amplitude = widget.amplitude;
    final double target = amplitude == null
        ? WavyProgressTokens.defaultAmplitude(progress)
        : amplitude(progress);
    return target.clamp(0.0, 1.0);
  }

  void _syncAmplitude() {
    final double target = _targetAmplitude;
    if (target == _amplitudeTarget) return;

    _amplitudeFrom = _amplitude;
    _amplitudeTarget = target;
    _requiresMorph = true;
    _amplitudeController.forward(from: 0.0);
  }

  void _updateAmplitude() {
    final double t = _amplitudeController.value;
    final Curve easing = _amplitudeFrom < _amplitudeTarget
        ? WavyProgressTokens.easingStandard
        : WavyProgressTokens.easingEmphasizedAccelerate;
    _amplitude =
        _amplitudeFrom + (_amplitudeTarget - _amplitudeFrom) * easing.transform(t);
  }

                                                                             
                                                                       
  int _waveDurationMs(int vertexCount) {
    if (widget.wavelength <= 0 || widget.waveSpeed <= 0 || vertexCount <= 0) {
      return 0;
    }
    return ((widget.wavelength / widget.waveSpeed) * 1000 * vertexCount)
        .round()
        .clamp(WavyProgressTokens.minAnimationDuration, 1 << 30);
  }

                                                            
  int _appliedWaveDurationMs = 0;

                                                                        
     
                                                                          
                          
  void _syncWaveAnimation(int durationMs) {
    if (durationMs == _appliedWaveDurationMs) return;
    _appliedWaveDurationMs = durationMs;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (durationMs > 0) {
                                                                         
                               
        _waveController.repeat(
          min: 0.0,
          max: 1.0,
          period: Duration(milliseconds: durationMs),
        );
      } else {
        _waveController.stop();
        _waveController.value = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ProgressIndicatorThemeData indicatorTheme =
        ProgressIndicatorTheme.of(context);
    final Color color = widget.color ??
        indicatorTheme.color ??
        Theme.of(context).colorScheme.primary;
    final Color trackColor = widget.trackColor ??
        indicatorTheme.circularTrackColor ??
        Theme.of(context).colorScheme.secondaryContainer;

    return Semantics(
      label: widget.semanticsLabel,
      value: widget.semanticsValue,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            _waveController,
            _amplitudeController,
            _cycleController,
          ]),
          builder: (BuildContext context, Widget? child) {
            _updateAmplitude();

            final double t = _cycleController.value;
            final double startProgress = 0.0;
            final double endProgress = widget.indeterminate
                ? WavyProgressTokens.circularSweep(t)
                : widget.progress!.clamp(0.0, 1.0);
            final bool enableMotion = widget.waveSpeed > 0.0 &&
                (widget.indeterminate ? _amplitude > 0.0 : true);

            final double rotationDegrees = widget.indeterminate
                ? WavyProgressTokens.circularGlobalRotation(t) +
                    WavyProgressTokens.circularAdditionalRotation(t) +
                    90.0
                : 0.0;

                                                                              
                                                                               
                                     
            _syncWaveAnimation(_waveDurationMs(
              WavyProgressTokens.circularVertexCount(
                size: widget.size,
                strokeWidth: widget.strokeWidth,
                wavelength: widget.wavelength,
              ),
            ));

            final _CircularProgressDrawingCache cache = _cache;
            return CustomPaint(
              painter: _CircularWavyPainter(
                cache: cache,
                startProgress: startProgress,
                endProgress: endProgress,
                amplitude: _amplitude,
                waveOffset: enableMotion && _amplitude > 0.0
                    ? _waveController.value
                    : 0.0,
                enableProgressMotion: enableMotion,
                wavelength: widget.wavelength,
                gapSize: widget.gapSize,
                strokeWidth: widget.strokeWidth,
                trackStrokeWidth: widget.trackStrokeWidth,
                strokeCap: widget.strokeCap,
                color: color,
                trackColor: trackColor,
                requiresMorph: widget.indeterminate
                    ? _amplitude > 0.0 && _amplitude < 1.0
                    : _requiresMorph,
                rotationDegrees: rotationDegrees,
              ),
              size: Size(widget.size, widget.size),
            );
          },
        ),
      ),
    );
  }

}

                                              
class _CircularWavyPainter extends CustomPainter {
  _CircularWavyPainter({
    required _CircularProgressDrawingCache cache,
    required this.startProgress,
    required this.endProgress,
    required this.amplitude,
    required this.waveOffset,
    required this.enableProgressMotion,
    required this.wavelength,
    required this.gapSize,
    required this.strokeWidth,
    required this.trackStrokeWidth,
    required this.strokeCap,
    required this.color,
    required this.trackColor,
    required this.requiresMorph,
    required this.rotationDegrees,
  }) : _cache = cache;

  final _CircularProgressDrawingCache _cache;

  final double startProgress;
  final double endProgress;

                                      
  final double amplitude;

                                             
  final double waveOffset;

                                                         
  final bool enableProgressMotion;

  final double wavelength;
  final double gapSize;
  final double strokeWidth;
  final double trackStrokeWidth;
  final StrokeCap strokeCap;
  final Color color;
  final Color trackColor;

                                                                               
                                              
  final bool requiresMorph;

                                                                
  final double rotationDegrees;

  @override
  void paint(Canvas canvas, Size size) {
    _cache.updatePaths(
      size: size,
      startProgress: startProgress,
      endProgress: endProgress,
      amplitude: amplitude,
      waveOffset: waveOffset,
      enableProgressMotion: enableProgressMotion,
      wavelength: wavelength,
      gapSize: gapSize,
      strokeWidth: strokeWidth,
      trackStrokeWidth: trackStrokeWidth,
      strokeCap: strokeCap,
      requiresMorph: requiresMorph,
    );

    canvas.save();
    if (rotationDegrees != 0.0) {
      final Offset center = size.center(Offset.zero);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotationDegrees * math.pi / 180.0);
      canvas.translate(-center.dx, -center.dy);
    }

    if (trackColor.a > 0.0) {
      final Paint trackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = trackColor
        ..strokeWidth = trackStrokeWidth
        ..strokeCap = strokeCap;
      canvas.drawPath(_cache.trackPath, trackPaint);
    }

    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeCap;
    canvas.drawPath(_cache.progressPath, progressPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CircularWavyPainter oldDelegate) =>
      oldDelegate.startProgress != startProgress ||
      oldDelegate.endProgress != endProgress ||
      oldDelegate.amplitude != amplitude ||
      oldDelegate.waveOffset != waveOffset ||
      oldDelegate.enableProgressMotion != enableProgressMotion ||
      oldDelegate.wavelength != wavelength ||
      oldDelegate.gapSize != gapSize ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.trackStrokeWidth != trackStrokeWidth ||
      oldDelegate.strokeCap != strokeCap ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.requiresMorph != requiresMorph ||
      oldDelegate.rotationDegrees != rotationDegrees;
}

                                                                           
                                      
   
                             
class _CircularShapes {
  Size? _currentSize;
  double _currentWavelength = -1.0;

  RoundedPolygon? _trackPolygon;
  RoundedPolygon? _activeIndicatorPolygon;
  Morph? _activeIndicatorMorph;

                                                                      
  int currentVertexCount = -1;

  void update({
    required Size size,
    required double wavelength,
    required double strokeWidth,
    required bool requiresMorph,
  }) {
    assert(wavelength > 0.0, 'Wavelength should be greater than zero');
    if (_currentSize == size && _currentWavelength == wavelength) {
      if (requiresMorph && _activeIndicatorMorph == null) {
        _activeIndicatorMorph =
            Morph(_trackPolygon!, _activeIndicatorPolygon!);
      }
      return;
    }

                                                                          
                                                                               
    final double radius = size.shortestSide / 2.0 - strokeWidth / 2.0;
    final int numVertices = math.max(
      WavyProgressTokens.minCircularVertexCount,
      (2 * math.pi * radius / wavelength).round(),
    );

    if (numVertices != currentVertexCount) {
                                                                            
                                                     
      _trackPolygon = RoundedPolygon.circle(numVertices: numVertices).normalized();
      _activeIndicatorPolygon = RoundedPolygon.star(
        numVerticesPerRadius: numVertices,
        innerRadius: 0.75,
        rounding: const CornerRounding(radius: 0.35, smoothing: 0.4),
        innerRounding: const CornerRounding(radius: 0.5),
      ).normalized();
      if (requiresMorph) {
        _activeIndicatorMorph =
            Morph(_trackPolygon!, _activeIndicatorPolygon!);
      }
    }

    _currentSize = size;
    _currentWavelength = wavelength;
    currentVertexCount = numVertices;
  }

  Path getTrackPath(Path path) => _trackPolygon?.toPath(path: path) ?? path;

  Path getProgressPath({
    required double amplitude,
    required Path path,
    required bool repeatPath,
  }) {
    final Morph? morph = _activeIndicatorMorph;
    if (morph != null) {
      return morph.toPath(
        progress: amplitude,
        path: path,
        repeatPath: repeatPath,
                                                                  
        rotationPivotX: 0.5,
        rotationPivotY: 0.5,
      );
    }
    final RoundedPolygon? active = _activeIndicatorPolygon;
    if (amplitude == 1.0 && active != null) {
      return active.toPath(path: path, repeatPath: repeatPath);
    }
    return _trackPolygon?.toPath(path: path, repeatPath: repeatPath) ?? path;
  }
}

                                                                                
                        
   
                                           
class _CircularProgressDrawingCache {
  double _currentAmplitude = -1.0;
  double _currentWavelength = -1.0;
  Size? _currentSize;
  double _currentStartProgress = 0.0;
  double _currentEndProgress = 0.0;
  double _currentGapSize = 0.0;
  double _currentWaveOffset = -1.0;
  double _currentStrokeWidth = 0.0;
  double _currentTrackStrokeWidth = 0.0;
  StrokeCap _currentStrokeCap = StrokeCap.round;
  bool _currentProgressMotionEnabled = false;
  bool _currentRequiresMorph = false;

  double _progressPathLength = 0.0;
  double _trackPathLength = 0.0;

  final _CircularShapes _shapes = _CircularShapes();

  final Path fullProgressPath = Path();
  final Path fullTrackPath = Path();
  final Path progressPath = Path();
  final Path trackPath = Path();

  ui.PathMetric? _progressMetric;
  ui.PathMetric? _trackMetric;

                                                                 
  double currentStrokeCapWidth = 0.0;

                                                                  
  int get vertexCount => _shapes.currentVertexCount;

  void updatePaths({
    required Size size,
    required double startProgress,
    required double endProgress,
    required double amplitude,
    required double waveOffset,
    required bool enableProgressMotion,
    required double wavelength,
    required double gapSize,
    required double strokeWidth,
    required double trackStrokeWidth,
    required StrokeCap strokeCap,
    required bool requiresMorph,
  }) {
    final bool pathsUpdates = _updateFullPaths(
      size: size,
      amplitude: amplitude,
      wavelength: wavelength,
      gapSize: gapSize,
      strokeWidth: strokeWidth,
      trackStrokeWidth: trackStrokeWidth,
      strokeCap: strokeCap,
      enableProgressMotion: enableProgressMotion,
      requiresMorph: requiresMorph,
    );
    _updateDrawPaths(
      forceUpdate: pathsUpdates,
      startProgress: startProgress,
      endProgress: endProgress,
      waveOffset: waveOffset,
    );
  }

  bool _updateFullPaths({
    required Size size,
    required double amplitude,
    required double wavelength,
    required double gapSize,
    required double strokeWidth,
    required double trackStrokeWidth,
    required StrokeCap strokeCap,
    required bool enableProgressMotion,
    required bool requiresMorph,
  }) {
    if (_currentSize == size &&
        _currentAmplitude == amplitude &&
        _currentWavelength == wavelength &&
        _currentStrokeWidth == strokeWidth &&
        _currentTrackStrokeWidth == trackStrokeWidth &&
        _currentStrokeCap == strokeCap &&
        _currentGapSize == gapSize &&
        _currentProgressMotionEnabled == enableProgressMotion &&
        _currentRequiresMorph == requiresMorph) {
      return false;
    }

    final double height = size.height;
    final double width = size.width;

    currentStrokeCapWidth = (strokeCap == StrokeCap.butt || height > width)
        ? 0.0
        : math.max(strokeWidth / 2.0, trackStrokeWidth / 2.0);

    final Matrix4 scaleMatrix =
        Matrix4.diagonal3Values(width - strokeWidth, height - strokeWidth, 1.0);

    _shapes.update(
      size: size,
      wavelength: wavelength,
      strokeWidth: strokeWidth,
      requiresMorph: requiresMorph,
    );

                                                                            
                                                                           
                   
    fullProgressPath.reset();
    _shapes.getProgressPath(
      amplitude: amplitude,
      path: fullProgressPath,
      repeatPath: enableProgressMotion,
    );
    _processPath(fullProgressPath, size, scaleMatrix);
                                                                           
    _progressMetric = null;
    for (final ui.PathMetric metric
        in fullProgressPath.computeMetrics(forceClosed: true)) {
      _progressMetric = metric;
      break;
    }
    final double progressLength = _progressMetric?.length ?? 0.0;
    _progressPathLength =
        enableProgressMotion ? progressLength / 2.0 : progressLength;

    fullTrackPath.reset();
    _shapes.getTrackPath(fullTrackPath);
    _processPath(fullTrackPath, size, scaleMatrix);
    _trackMetric = null;
    for (final ui.PathMetric metric
        in fullTrackPath.computeMetrics(forceClosed: true)) {
      _trackMetric = metric;
      break;
    }
    _trackPathLength = _trackMetric?.length ?? 0.0;

    _currentSize = size;
    _currentAmplitude = amplitude;
    _currentWavelength = wavelength;
    _currentStrokeWidth = strokeWidth;
    _currentTrackStrokeWidth = trackStrokeWidth;
    _currentStrokeCap = strokeCap;
    _currentGapSize = gapSize;
    _currentProgressMotionEnabled = enableProgressMotion;
    _currentRequiresMorph = requiresMorph;
    return true;
  }

                                                            
  static void _processPath(Path path, Size size, Matrix4 scaleMatrix) {
    final Path scaled = path.transform(scaleMatrix.storage);
    final Rect bounds = scaled.getBounds();
    final Path centered = scaled.shift(size.center(Offset.zero) - bounds.center);
    path.reset();
    path.addPath(centered, Offset.zero);
  }

  void _updateDrawPaths({
    required bool forceUpdate,
    required double startProgress,
    required double endProgress,
    required double waveOffset,
  }) {
    assert(_currentSize != null, 'updatePaths must be called first');

    if (!forceUpdate &&
        _currentStartProgress == startProgress &&
        _currentEndProgress == endProgress &&
        _currentWaveOffset == waveOffset) {
      return;
    }

    trackPath.reset();
    progressPath.reset();

    final double pStart = startProgress * _progressPathLength;
    final double pStop = endProgress * _progressPathLength;

    final double trackGapSize = math.min(pStop, _currentGapSize);
    final double horizontalInsets = math.min(pStop, currentStrokeCapWidth);
    final double trackSpacing = horizontalInsets * 2.0 + trackGapSize;

    if (_currentProgressMotionEnabled) {
      final double coercedWaveOffset = waveOffset.clamp(0.0, 1.0);
      final double startStopShift = coercedWaveOffset * _progressPathLength;
      _copySegment(
        progressPath,
        _progressMetric,
        pStart + startStopShift,
        pStop + startStopShift,
      );

                                                                              
                                 
      final double offsetAngle = (coercedWaveOffset * 360.0) % 360.0;
      if (offsetAngle != 0.0) {
        final Offset center = fullProgressPath.getBounds().center;
        final Matrix4 rotation = Matrix4.translationValues(center.dx, center.dy, 0.0)
          ..multiply(Matrix4.rotationZ(-offsetAngle * math.pi / 180.0))
          ..multiply(Matrix4.translationValues(-center.dx, -center.dy, 0.0));
        final Path rotated = progressPath.transform(rotation.storage);
        progressPath.reset();
        progressPath.addPath(rotated, Offset.zero);
      }
    } else {
      _copySegment(progressPath, _progressMetric, pStart, pStop);
    }

    if (_trackPathLength > 0.0) {
      final double tStart = endProgress * _trackPathLength + trackSpacing;
      final double tStop = _trackPathLength - trackSpacing;
      _copySegment(trackPath, _trackMetric, tStart, tStop);
    }

    _currentStartProgress = startProgress;
    _currentEndProgress = endProgress;
    _currentWaveOffset = waveOffset;
  }

                                      
  static void _copySegment(
    Path destination,
    ui.PathMetric? metric,
    double startDistance,
    double stopDistance,
  ) {
    if (metric == null || stopDistance <= startDistance) return;
    final Path segment = metric.extractPath(startDistance, stopDistance);
    destination.addPath(segment, Offset.zero);
  }
}
