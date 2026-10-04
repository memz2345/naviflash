                                                 
  
                              
                                                                                   
                                
                                               
                                                  

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'wavy_progress_tokens.dart';

                                                                             
                               
   
                                                                          
                                                                         
             
   
                   
           
                                              
       
               
   
                                                                         
                
class LinearWavyProgressIndicator extends StatefulWidget {
                                                           
     
                                                
  const LinearWavyProgressIndicator({
    super.key,
    required this.progress,
    this.amplitude,
    this.color,
    this.trackColor,
    this.strokeCap = StrokeCap.round,
    this.strokeWidth = WavyProgressTokens.linearActiveThickness,
    this.trackStrokeWidth = WavyProgressTokens.linearTrackThickness,
    this.gapSize = WavyProgressTokens.linearTrackActiveSpace,
    this.stopSize = WavyProgressTokens.linearStopSize,
    this.wavelength = WavyProgressTokens.linearDeterminateWavelength,
    double? waveSpeed,
    this.width = WavyProgressTokens.linearContainerWidth,
    this.height = WavyProgressTokens.linearContainerHeight,
    this.semanticsLabel,
    this.semanticsValue,
  })  : waveSpeed = waveSpeed ?? wavelength,
        amplitudeValue = 1.0,
        indeterminate = false;

                                                              
  const LinearWavyProgressIndicator.indeterminate({
    super.key,
    this.color,
    this.trackColor,
    this.strokeCap = StrokeCap.round,
    this.strokeWidth = WavyProgressTokens.linearActiveThickness,
    this.trackStrokeWidth = WavyProgressTokens.linearTrackThickness,
    this.gapSize = WavyProgressTokens.linearTrackActiveSpace,
    this.amplitudeValue = 1.0,
    this.wavelength = WavyProgressTokens.linearIndeterminateWavelength,
    double? waveSpeed,
    this.width = WavyProgressTokens.linearContainerWidth,
    this.height = WavyProgressTokens.linearContainerHeight,
    this.semanticsLabel,
  })  : progress = null,
        amplitude = null,
        stopSize = 0.0,
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

                                                                          
                  
  final double stopSize;

                                                                             
           
  final double wavelength;

                                                                              
                                                             
  final double waveSpeed;

                                 
  final double width;

                                                                            
                                                     
  final double height;

                                                     
  final String? semanticsLabel;

                                                     
  final String? semanticsValue;

                                                        
  final bool indeterminate;

  @override
  State<LinearWavyProgressIndicator> createState() =>
      _LinearWavyProgressIndicatorState();
}

class _LinearWavyProgressIndicatorState
    extends State<LinearWavyProgressIndicator> with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _amplitudeController;
  AnimationController? _indeterminateController;

  double _amplitudeFrom = 0.0;
  double _amplitudeTarget = 0.0;
  double _amplitude = 0.0;

  final _LinearProgressDrawingCache _cache = _LinearProgressDrawingCache();

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: _waveDuration(widget.wavelength, widget.waveSpeed),
    );
    if (_waveDurationMs(widget.wavelength, widget.waveSpeed) > 0) {
      _waveController.repeat();
    }

    _amplitudeController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: WavyProgressTokens.amplitudeAnimationDuration,
      ),
    );

    if (widget.indeterminate) {
      _indeterminateController = AnimationController(
        vsync: this,
        duration: const Duration(
          milliseconds: WavyProgressTokens.linearAnimationDuration,
        ),
      )..repeat();
    }

                                                                       
    _amplitude = _targetAmplitude;
    _amplitudeFrom = _amplitude;
    _amplitudeTarget = _amplitude;
  }

  @override
  void didUpdateWidget(LinearWavyProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int durationMs = _waveDurationMs(widget.wavelength, widget.waveSpeed);
    if (widget.wavelength != oldWidget.wavelength ||
        widget.waveSpeed != oldWidget.waveSpeed) {
                                                                                
      final double from = _waveController.value;
      _waveController.duration = _waveDuration(widget.wavelength, widget.waveSpeed);
      if (durationMs > 0) {
        _waveController.repeat();
        _waveController.value = from;
      } else {
        _waveController.stop();
        _waveController.value = 0.0;
      }
    }

    if (widget.indeterminate != oldWidget.indeterminate) {
      if (widget.indeterminate) {
        _indeterminateController ??= AnimationController(
          vsync: this,
          duration: const Duration(
            milliseconds: WavyProgressTokens.linearAnimationDuration,
          ),
        )..repeat();
      } else {
        _indeterminateController?.dispose();
        _indeterminateController = null;
      }
    }

    _syncAmplitude();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _amplitudeController.dispose();
    _indeterminateController?.dispose();
    super.dispose();
  }

  double get _targetAmplitude {
    if (widget.indeterminate) {
      return widget.amplitudeValue.clamp(0.0, 1.0);
    }
    final double progress = widget.progress!.clamp(0.0, 1.0);
    final double Function(double)? amplitude = widget.amplitude;
    final double target =
        amplitude == null ? WavyProgressTokens.defaultAmplitude(progress) : amplitude(progress);
    return target.clamp(0.0, 1.0);
  }

                                                                              
                                                                           
  void _syncAmplitude() {
    final double target = _targetAmplitude;
    if (target == _amplitudeTarget) return;

    _amplitudeFrom = _amplitude;
    _amplitudeTarget = target;
    _amplitudeController
      ..duration = const Duration(
        milliseconds: WavyProgressTokens.amplitudeAnimationDuration,
      )
      ..forward(from: 0.0);
  }

  static int _waveDurationMs(double wavelength, double waveSpeed) {
    if (wavelength <= 0 || waveSpeed <= 0) return 0;
    return ((wavelength / waveSpeed) * 1000)
        .round()
        .clamp(WavyProgressTokens.minAnimationDuration, 1 << 30);
  }

  static Duration _waveDuration(double wavelength, double waveSpeed) =>
      Duration(milliseconds: _waveDurationMs(wavelength, waveSpeed));

  void _updateAmplitude() {
    final double t = _amplitudeController.value;
    final Cubic easing = _amplitudeFrom < _amplitudeTarget
        ? WavyProgressTokens.easingStandard
        : WavyProgressTokens.easingEmphasizedAccelerate;
    _amplitude =
        _amplitudeFrom + (_amplitudeTarget - _amplitudeFrom) * easing.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final ProgressIndicatorThemeData indicatorTheme =
        ProgressIndicatorTheme.of(context);
    final Color color = widget.color ??
        indicatorTheme.color ??
        Theme.of(context).colorScheme.primary;
    final Color trackColor = widget.trackColor ??
        indicatorTheme.linearTrackColor ??
        Theme.of(context).colorScheme.secondaryContainer;

    return Semantics(
      label: widget.semanticsLabel,
      value: widget.semanticsValue,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              _waveController,
              _amplitudeController,
              if (_indeterminateController != null) _indeterminateController!,
            ]),
            builder: (BuildContext context, Widget? child) {
              _updateAmplitude();
              final double t = _indeterminateController?.value ?? 0.0;
              final List<double> fractions;
              if (widget.indeterminate) {
                fractions = <double>[
                  WavyProgressTokens.linearIndeterminateFraction(
                    t,
                    WavyProgressTokens.firstLineTailDelay,
                    WavyProgressTokens.firstLineTailDuration,
                  ),
                  WavyProgressTokens.linearIndeterminateFraction(
                    t,
                    WavyProgressTokens.firstLineHeadDelay,
                    WavyProgressTokens.firstLineHeadDuration,
                  ),
                  WavyProgressTokens.linearIndeterminateFraction(
                    t,
                    WavyProgressTokens.secondLineTailDelay,
                    WavyProgressTokens.secondLineTailDuration,
                  ),
                  WavyProgressTokens.linearIndeterminateFraction(
                    t,
                    WavyProgressTokens.secondLineHeadDelay,
                    WavyProgressTokens.secondLineHeadDuration,
                  ),
                ];
              } else {
                fractions = <double>[0.0, widget.progress!.clamp(0.0, 1.0)];
              }

              return CustomPaint(
                painter: _LinearWavyPainter(
                  cache: _cache,
                  progressFractions: fractions,
                  amplitude: _amplitude,
                  waveOffset: _amplitude > 0.0 ? _waveController.value : 0.0,
                  wavelength: widget.wavelength,
                  gapSize: widget.gapSize,
                  strokeWidth: widget.strokeWidth,
                  trackStrokeWidth: widget.trackStrokeWidth,
                  strokeCap: widget.strokeCap,
                  color: color,
                  trackColor: trackColor,
                  stopSize: widget.indeterminate ? null : widget.stopSize,
                  textDirection: Directionality.of(context),
                ),
                size: Size(widget.width, widget.height),
              );
            },
          ),
        ),
      ),
    );
  }
}

                                            
class _LinearWavyPainter extends CustomPainter {
  _LinearWavyPainter({
    required _LinearProgressDrawingCache cache,
    required this.progressFractions,
    required this.amplitude,
    required this.waveOffset,
    required this.wavelength,
    required this.gapSize,
    required this.strokeWidth,
    required this.trackStrokeWidth,
    required this.strokeCap,
    required this.color,
    required this.trackColor,
    required this.stopSize,
    required this.textDirection,
  }) : _cache = cache;

  final _LinearProgressDrawingCache _cache;

                                                                                
                                     
  final List<double> progressFractions;

                                      
  final double amplitude;

                                             
  final double waveOffset;

                                              
  final double wavelength;

                                                                            
  final double gapSize;

  final double strokeWidth;
  final double trackStrokeWidth;
  final StrokeCap strokeCap;
  final Color color;
  final Color trackColor;

                                         
  final double? stopSize;

  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    _cache.updatePaths(
      size: size,
      wavelength: wavelength,
      progressFractions: progressFractions,
      amplitude: amplitude,
      waveOffset: amplitude > 0.0 ? waveOffset : 0.0,
      gapSize: gapSize,
      strokeWidth: strokeWidth,
      trackStrokeWidth: trackStrokeWidth,
      strokeCap: strokeCap,
    );

    canvas.save();
    if (textDirection == TextDirection.rtl) {
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(math.pi);
      canvas.translate(-size.width / 2, -size.height / 2);
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
    for (final Path path in _cache.progressPaths) {
      canvas.drawPath(path, progressPaint);
    }

    final double? stopSize = this.stopSize;
    if (stopSize != null && stopSize > 0.0) {
      _drawStopIndicator(canvas, size, stopSize);
    }

    canvas.restore();
  }

                                                                               
                                                                        
  void _drawStopIndicator(Canvas canvas, Size size, double maxStopSize) {
    double stopIndicatorSize = math.min(trackStrokeWidth, maxStopSize);
                                                                               
    final double indicatorXOffset = stopIndicatorSize == trackStrokeWidth
        ? 0.0
        : trackStrokeWidth / 4.0;

    double indicatorX = size.width - stopIndicatorSize - indicatorXOffset;
    final double progressX =
        size.width * progressFractions[1] + _cache.currentStrokeCapWidth;
    if (indicatorX <= progressX) {
      stopIndicatorSize = math.max(0.0, stopIndicatorSize - (progressX - indicatorX));
      indicatorX = progressX;
    }

    if (stopIndicatorSize <= 0.0) return;

    final Paint paint = Paint()..color = color;
    if (strokeCap == StrokeCap.round) {
      canvas.drawCircle(
        Offset(indicatorX + stopIndicatorSize / 2.0, size.height / 2.0),
        stopIndicatorSize / 2.0,
        paint,
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(
          indicatorX,
          (size.height - stopIndicatorSize) / 2.0,
          stopIndicatorSize,
          stopIndicatorSize,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LinearWavyPainter oldDelegate) =>
      oldDelegate.progressFractions != progressFractions ||
      oldDelegate.amplitude != amplitude ||
      oldDelegate.waveOffset != waveOffset ||
      oldDelegate.wavelength != wavelength ||
      oldDelegate.gapSize != gapSize ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.trackStrokeWidth != trackStrokeWidth ||
      oldDelegate.strokeCap != strokeCap ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.stopSize != stopSize ||
      oldDelegate.textDirection != textDirection;
}

                                                                              
                        
   
                                         
class _LinearProgressDrawingCache {
  double _currentWavelength = -1.0;
  double _currentAmplitude = -1.0;
  Size? _currentSize;
  List<double>? _currentProgressFractions;
  double _currentGapSize = 0.0;
  double _currentWaveOffset = -1.0;
  double _currentStrokeWidth = 0.0;
  double _currentTrackStrokeWidth = 0.0;
  StrokeCap _currentStrokeCap = StrokeCap.round;

                                                                               
                                                                              
                             
  double _progressPathScale = 1.0;

  final Path fullProgressPath = Path();
  final Path trackPath = Path();
  List<Path> _progressPaths = const <Path>[];

  ui.PathMetric? _pathMetric;
  double _pathLength = 0.0;

                                                                 
  double currentStrokeCapWidth = 0.0;

                                                  
  List<Path> get progressPaths => _progressPaths;

  void updatePaths({
    required Size size,
    required double wavelength,
    required List<double> progressFractions,
    required double amplitude,
    required double waveOffset,
    required double gapSize,
    required double strokeWidth,
    required double trackStrokeWidth,
    required StrokeCap strokeCap,
  }) {
    if (_currentProgressFractions == null) {
      _currentProgressFractions = List<double>.filled(progressFractions.length, 0.0);
      _progressPaths =
          List<Path>.generate(progressFractions.length ~/ 2, (_) => Path());
    }
    final bool pathsUpdates = _updateFullPaths(
      size: size,
      wavelength: wavelength,
      amplitude: amplitude,
      gapSize: gapSize,
      strokeWidth: strokeWidth,
      trackStrokeWidth: trackStrokeWidth,
      strokeCap: strokeCap,
    );
    _updateDrawPaths(
      forceUpdate: pathsUpdates,
      progressFractions: progressFractions,
      amplitude: amplitude,
      waveOffset: waveOffset,
    );
  }

                                                                             
                                
  bool _updateFullPaths({
    required Size size,
    required double wavelength,
    required double amplitude,
    required double gapSize,
    required double strokeWidth,
    required double trackStrokeWidth,
    required StrokeCap strokeCap,
  }) {
    if (_currentSize == size &&
        _currentWavelength == wavelength &&
        _currentStrokeWidth == strokeWidth &&
        _currentTrackStrokeWidth == trackStrokeWidth &&
        _currentStrokeCap == strokeCap &&
        _currentGapSize == gapSize &&
                                                                             
                                                                         
        ((_currentAmplitude != 0.0 && amplitude != 0.0) ||
            (_currentAmplitude == 0.0 && amplitude == 0.0))) {
      return false;
    }

    final double height = size.height;
    final double width = size.width;

    currentStrokeCapWidth = (strokeCap == StrokeCap.butt || height > width)
        ? 0.0
        : math.max(strokeWidth / 2.0, trackStrokeWidth / 2.0);

    fullProgressPath.reset();
    fullProgressPath.moveTo(0.0, 0.0);

    if (amplitude == 0.0) {
                                                                
      fullProgressPath.lineTo(width, 0.0);
    } else {
      final double halfWavelength = wavelength / 2.0;
      double anchorX = halfWavelength;
      const double anchorY = 0.0;
      double controlX = halfWavelength / 2.0;
                                                                               
                                                                              
                                                                               
                                                                          
      double controlY = height - strokeWidth;

                                                                          
                                                 
      final double widthWithExtraPhase = width + wavelength * 2.0;
      while (anchorX <= widthWithExtraPhase) {
        fullProgressPath.quadraticBezierTo(controlX, controlY, anchorX, anchorY);
        anchorX += halfWavelength;
        controlX += halfWavelength;
        controlY *= -1.0;
      }
    }

    _translatePath(fullProgressPath, 0.0, height / 2.0);

                                                                           
    _pathMetric = null;
    for (final ui.PathMetric metric
        in fullProgressPath.computeMetrics(forceClosed: false)) {
      _pathMetric = metric;
      break;
    }
    _pathLength = _pathMetric?.length ?? 0.0;
    _progressPathScale = _pathLength / (fullProgressPath.getBounds().width + 1e-8);

    _currentSize = size;
    _currentWavelength = wavelength;
    _currentStrokeWidth = strokeWidth;
    _currentTrackStrokeWidth = trackStrokeWidth;
    _currentStrokeCap = strokeCap;
    _currentGapSize = gapSize;
                                                                               
    return true;
  }

                                                                             
                                             
  void _updateDrawPaths({
    required bool forceUpdate,
    required List<double> progressFractions,
    required double amplitude,
    required double waveOffset,
  }) {
    assert(_currentSize != null, 'updatePaths must be called first');
    final Size size = _currentSize!;

    if (!forceUpdate &&
        _listEquals(_currentProgressFractions!, progressFractions) &&
        _currentAmplitude == amplitude &&
        _currentWaveOffset == waveOffset) {
      return;
    }

    final double width = size.width;
    final double halfHeight = size.height / 2.0;

    double adjustedTrackGapSize = _currentGapSize;

                                                                         
                                                                            
                 
    bool activeIndicatorVisible = false;

                                                                            
                           
    double nextEndTrackOffset = width - currentStrokeCapWidth;
    trackPath.reset();
    trackPath.moveTo(nextEndTrackOffset, halfHeight);

    for (int i = 0; i < _progressPaths.length; i++) {
      _progressPaths[i].reset();

      final double startFraction = progressFractions[i * 2];
      final double endFraction = progressFractions[i * 2 + 1];

      final double barTail = startFraction * width;
      final double barHead = endFraction * width;

      if (i == 0) {
                                                                              
                                                          
        adjustedTrackGapSize = barHead < currentStrokeCapWidth
            ? 0.0
            : math.min(barHead - currentStrokeCapWidth, _currentGapSize);
        activeIndicatorVisible = barHead >= currentStrokeCapWidth;
      }

                                          
      final double adjustedBarHead =
          barHead.clamp(currentStrokeCapWidth, width - currentStrokeCapWidth);
      final double adjustedBarTail =
          barTail.clamp(currentStrokeCapWidth, width - currentStrokeCapWidth);

      if ((endFraction - startFraction).abs() > 0.0) {
                                             
        final double waveShift = amplitude != 0.0 ? waveOffset * _currentWavelength : 0.0;
        final Path segment = _segment(
          (adjustedBarTail + waveShift) * _progressPathScale,
          (adjustedBarHead + waveShift) * _progressPathScale,
        );

                                                                         
                                                                              
                                                                    
                                                                                
                                      
        final Matrix4 matrix = Matrix4.translationValues(
          waveShift > 0.0 ? -waveShift : 0.0,
          (1.0 - amplitude) * halfHeight,
          0.0,
        )..multiply(Matrix4.diagonal3Values(
            1.0,
            amplitude == 1.0 ? 1.0 : amplitude,
            1.0,
          ));
        _progressPaths[i] = segment.transform(matrix.storage);
      }

      final double adaptiveTrackSpacing = activeIndicatorVisible
          ? adjustedTrackGapSize + currentStrokeCapWidth * 2.0
          : adjustedTrackGapSize;
      if (nextEndTrackOffset > adjustedBarHead + adaptiveTrackSpacing) {
        trackPath.lineTo(
          math.max(currentStrokeCapWidth, adjustedBarHead + adaptiveTrackSpacing),
          halfHeight,
        );
      }

      if (barHead > barTail) {
        nextEndTrackOffset =
            math.max(currentStrokeCapWidth, adjustedBarTail - adaptiveTrackSpacing);
        trackPath.moveTo(nextEndTrackOffset, halfHeight);
      }
    }

                                                                        
    if (nextEndTrackOffset > currentStrokeCapWidth) {
      trackPath.lineTo(currentStrokeCapWidth, halfHeight);
    }

    for (int i = 0; i < progressFractions.length; i++) {
      _currentProgressFractions![i] = progressFractions[i];
    }
    _currentAmplitude = amplitude;
    _currentWaveOffset = waveOffset;
  }

                                                          
                               
  Path _segment(double startDistance, double stopDistance) {
    final ui.PathMetric? metric = _pathMetric;
    if (metric == null || stopDistance <= startDistance) return Path();
    return metric.extractPath(startDistance, stopDistance);
  }

  static void _translatePath(Path path, double dx, double dy) {
    final Path shifted = path.shift(Offset(dx, dy));
    path.reset();
    path.addPath(shifted, Offset.zero);
  }

  static bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
