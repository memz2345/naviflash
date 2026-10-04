                                          
  
                                                  
                                                                                    
                              
  
                                        
                                           
                                                              
                                                  
                                                            
                                                      
                                   
                                                
                                                  
                                                       
                                                  
                                                    
  
        
                                                                  
                                              
                                                             
                                              
                                                                     
                                                                  
                                         
  
                                
                                               
                                                 
                                                               
                                                        
                                                                 
                                              
library;

import 'dart:async' show Completer;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show clampDouble, kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:naviflash/widgets/navi_overscroll.dart';
import 'package:flutter/rendering.dart'
    show BoxHitTestResult, BoxParentData, ClipRectLayer, RenderBox;

                                               
const double kIndicatorSize = 49.0;

                                                               
const double _kDragSizeFactorLimit = 1.5;

                       
const Duration _kIndicatorSnapDuration = Duration(milliseconds: 150);

                      
const Duration _kIndicatorScaleDuration = Duration(milliseconds: 200);

                                                               
                                                     
bool get _isDarwin => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

                                             
                                                              
enum PlusRefreshStatus {
            
  drag,

                    
  snap,

              
  refresh,

                   
  done,

                   
  canceled,
}

                       
   
                                                      
                                        
class PlusRefreshIndicator extends RefreshIndicator {
                  
     
                                                     
                                                   
                                      
  const PlusRefreshIndicator({
    super.key,
    required super.onRefresh,
    super.color,
    super.backgroundColor,
    super.displacement,
    super.edgeOffset,
    super.notificationPredicate,
    super.triggerMode,
    super.strokeWidth,
    super.elevation,
    this.onArmed,
    required super.child,
  });

                                                   
                          
  final VoidCallback? onArmed;

  @override
  RefreshIndicatorState createState() => PlusRefreshIndicatorState();
}

                                   
   
                                         
                                                                          
                                 
class PlusRefreshIndicatorState extends RefreshIndicatorState {
  late AnimationController _plusPositionController;
  late AnimationController _plusScaleController;
  late Animation<double> _plusPositionFactor;
  late Animation<double> _plusScaleFactor;
  late Animation<double> _plusValue;
  late Animation<Color?> _plusValueColor;

  PlusRefreshStatus? _status;
  late Future<void> _plusPendingRefreshFuture;
  double? _dragOffset;
  late Color _effectiveValueColor;

                               
  bool _armNotified = false;

  static final Animatable<double> _threeQuarterTween = Tween<double>(
    begin: 0.0,
    end: 0.75,
  );

  static final Animatable<double> _kDragSizeFactorLimitTween = Tween<double>(
    begin: 0.0,
    end: _kDragSizeFactorLimit,
  );

  static final Animatable<double> _oneToZeroTween = Tween<double>(
    begin: 1.0,
    end: 0.0,
  );

                                   
     
                                           
  double get _refreshDragExtent =>
      (widget.displacement + kIndicatorSize) * _kDragSizeFactorLimit;

  @override
  void initState() {
    super.initState();
    _plusPositionController = AnimationController(vsync: this);
    _plusPositionFactor = _plusPositionController.drive(
      _kDragSizeFactorLimitTween,
    );

                                       
    _plusValue = _plusPositionController.drive(_threeQuarterTween);

    _plusScaleController = AnimationController(vsync: this);
    _plusScaleFactor = _plusScaleController.drive(_oneToZeroTween);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupValueColor();
  }

  @override
  void didUpdateWidget(covariant RefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      _setupValueColor();
    }
  }

  @override
  void dispose() {
    _plusPositionController.dispose();
    _plusScaleController.dispose();
    super.dispose();
  }

  void _setupValueColor() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    _effectiveValueColor = widget.color ?? colorScheme.primary;
    final Color color = _effectiveValueColor;
    if (color.a == 0) {
                         
      _plusValueColor = AlwaysStoppedAnimation<Color>(color);
    } else {
                                                 
                                 
      _plusValueColor = _plusPositionController.drive(
        ColorTween(begin: color.withValues(alpha: 0), end: color).chain(
          CurveTween(curve: const Interval(0.0, 1.0 / _kDragSizeFactorLimit)),
        ),
      );
    }
  }

  bool _shouldStart(ScrollNotification notification) {
                                                    
                                  
                                                 
                                                   
                                 
    return ((notification is ScrollStartNotification &&
                notification.dragDetails != null) ||
            (notification is ScrollUpdateNotification &&
                notification.dragDetails != null &&
                widget.triggerMode == RefreshIndicatorTriggerMode.anywhere)) &&
        notification.metrics.axisDirection == AxisDirection.down &&
        notification.metrics.extentBefore == 0.0 &&
        _status == null &&
        _start();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification)) {
      return false;
    }
    if (_shouldStart(notification)) {
      setState(() {
        _status = PlusRefreshStatus.drag;
      });
      return false;
    }
    if (notification is ScrollUpdateNotification) {
      if (_status == PlusRefreshStatus.drag) {
        _dragOffset = _dragOffset! - notification.scrollDelta!;
        _checkDragOffset();

        if (notification.dragDetails == null &&
            _plusValueColor.value!.a == _effectiveValueColor.a) {
                                                    
          _show();
        }
      }
    } else if (notification is OverscrollNotification) {
      if (_status == PlusRefreshStatus.drag) {
                                                    
                   
        _dragOffset = _dragOffset! - notification.overscroll;
        _checkDragOffset();
      }
    } else if (notification is ScrollEndNotification) {
      switch (_status) {
        case PlusRefreshStatus.drag:
          if (_plusValueColor.value!.a == _effectiveValueColor.a) {
                              
            _show();
          } else {
            _dismiss(PlusRefreshStatus.canceled);
          }
        case PlusRefreshStatus.canceled:
        case PlusRefreshStatus.done:
        case PlusRefreshStatus.refresh:
        case PlusRefreshStatus.snap:
        case null:
                       
          break;
      }
    }
    return false;
  }

  bool _handleIndicatorNotification(
    OverscrollIndicatorNotification notification,
  ) {
    if (notification.depth != 0 || !notification.leading) {
      return false;
    }
                                    
    if (_status == PlusRefreshStatus.drag) {
      notification.disallowIndicator();
      return true;
    }
    return false;
  }

  bool _start() {
    assert(_status == null);
    assert(_dragOffset == null);
    _dragOffset = 0.0;
    _armNotified = false;
    _plusScaleController.value = 0.0;
    _plusPositionController.value = 0.0;
    return true;
  }

  void _checkDragOffset() {
    assert(_status == PlusRefreshStatus.drag);
    final double newValue = clampDouble(
      _dragOffset! / _refreshDragExtent,
      0.0,
      1.0,
    );
    _plusPositionController.value = newValue;           
                                                         
                                              
    final bool armed = _plusValueColor.value!.a == _effectiveValueColor.a;
    if (armed && !_armNotified) {
      _armNotified = true;
      (widget as PlusRefreshIndicator).onArmed?.call();
    } else if (!armed && _armNotified) {
      _armNotified = false;
    }
  }

                                                
  Future<void> _dismiss(PlusRefreshStatus newMode) async {
    await Future<void>.value();
    assert(
      newMode == PlusRefreshStatus.canceled ||
          newMode == PlusRefreshStatus.done,
    );
    setState(() {
      _status = newMode;
    });
    switch (_status!) {
      case PlusRefreshStatus.done:
                             
        await _plusScaleController.animateTo(
          1.0,
          duration: _kIndicatorScaleDuration,
        );
      case PlusRefreshStatus.canceled:
                  
        await _plusPositionController.animateTo(
          0.0,
          duration: _kIndicatorScaleDuration,
        );
      case PlusRefreshStatus.drag:
      case PlusRefreshStatus.refresh:
      case PlusRefreshStatus.snap:
        assert(false);
    }
    if (mounted && _status == newMode) {
      _dragOffset = null;
      setState(() {
        _status = null;
      });
    }
  }

  void _show() {
    assert(_status != PlusRefreshStatus.refresh);
    assert(_status != PlusRefreshStatus.snap);
    final Completer<void> completer = Completer<void>();
    _plusPendingRefreshFuture = completer.future;
    _status = PlusRefreshStatus.snap;
    _plusPositionController
        .animateTo(
                                                                      
          1.0 / _kDragSizeFactorLimit,
          duration: _kIndicatorSnapDuration,
        )
        .whenComplete(() {
          if (mounted && _status == PlusRefreshStatus.snap) {
            setState(() {
                           
              _status = PlusRefreshStatus.refresh;
            });

            widget.onRefresh().whenComplete(() {
              if (mounted && _status == PlusRefreshStatus.refresh) {
                completer.complete();
                _dismiss(PlusRefreshStatus.done);
              }
            });
          }
        });
  }

                              
     
                                            
                        
  @override
  Future<void> show({bool atTop = true}) {
    if (_status != PlusRefreshStatus.refresh &&
        _status != PlusRefreshStatus.snap) {
      if (_status == null) {
        _start();
      }
      _show();
    }
    return _plusPendingRefreshFuture;
  }

                                               
                                          
  bool _onDrag(double offset) {
    if (_plusPositionController.value > 0.0 &&
        _status == PlusRefreshStatus.drag) {
      _dragOffset = _dragOffset! + offset;
      _checkDragOffset();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    Widget child = NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: _handleIndicatorNotification,
        child: widget.child,
      ),
    );
    assert(() {
      if (_status == null) {
        assert(_dragOffset == null);
      } else {
        assert(_dragOffset != null);
      }
      return true;
    }());

    final bool showIndeterminateIndicator =
        _status == PlusRefreshStatus.refresh ||
        _status == PlusRefreshStatus.done;

                                                
                    
    child = RefreshLayout(
      body: child,
      scale: _plusScaleFactor,
      position: _plusPositionFactor,
      displacement: widget.displacement,
      edgeOffset: widget.edgeOffset,
      indicator: _status == null
          ? null
          : AnimatedBuilder(
              animation: _plusPositionController,
              builder: (context, child) => RefreshProgressIndicator(
                value: showIndeterminateIndicator ? null : _plusValue.value,
                valueColor: _plusValueColor,
                backgroundColor: widget.backgroundColor,
                strokeWidth: widget.strokeWidth,
                elevation: widget.elevation,
              ),
            ),
    );

                                                        
                                                                 
                                                       
    if (_isDarwin) {
      return child;
    }
    return ScrollConfiguration(
      behavior: RefreshScrollBehavior(
        scrollPhysics: RefreshScrollPhysics(
          parent: const RangeMaintainingScrollPhysics(),
          onDrag: _onDrag,
        ),
      ),
      child: child,
    );
  }
}

                                       
enum RefreshType { indicator, body }

                                                 
                                                
class RefreshLayout
    extends SlottedMultiChildRenderObjectWidget<RefreshType, RenderBox> {
            
  const RefreshLayout({
    super.key,
    required this.scale,
    required this.position,
    required this.displacement,
    required this.edgeOffset,
    required this.indicator,
    required this.body,
  });

                               
  final Animation<double> scale;

                                   
  final Animation<double> position;

                                                      
  final double displacement;

                    
  final double edgeOffset;

                         
  final Widget? indicator;

           
  final Widget body;

  @override
  Iterable<RefreshType> get slots => RefreshType.values;

  @override
  Widget? childForSlot(RefreshType slot) => switch (slot) {
    RefreshType.indicator => indicator,
    RefreshType.body => body,
  };

  @override
  RenderRefreshLayout createRenderObject(BuildContext context) {
    return RenderRefreshLayout(
      scale: scale,
      position: position,
      displacement: displacement,
      edgeOffset: edgeOffset,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderRefreshLayout renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject
      ..displacement = displacement
      ..edgeOffset = edgeOffset;
                                                
  }
}

                          
class RenderRefreshLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<RefreshType, RenderBox> {
  RenderRefreshLayout({
    required this.scale,
    required this.position,
    required double displacement,
    required double edgeOffset,
  }) : _displacement = displacement,
       _edgeOffset = edgeOffset {
    scale.addListener(_scaleListener);
    position.addListener(_positionListener);
  }

  final Animation<double> scale;

  final Animation<double> position;

  double _displacement;
  double get displacement => _displacement;
  set displacement(double value) {
    if (_displacement == value) return;
    _displacement = value;
    _layoutIndicator();
    markNeedsPaint();
  }

  double _edgeOffset;
  double get edgeOffset => _edgeOffset;
  set edgeOffset(double value) {
    if (_edgeOffset == value) return;
    _edgeOffset = value;
    _layoutIndicator();
    markNeedsPaint();
  }

  double _heightFactor = 0;
  double get heightFactor => _heightFactor;
  set heightFactor(double value) {
    if (_heightFactor == value) {
      return;
    }
    _heightFactor = value;
    _layoutIndicator();
    markNeedsPaint();
  }

  double _scaleFactor = 0;
  double get scaleFactor => _scaleFactor;
  set scaleFactor(double value) {
    if (_scaleFactor == value) {
      return;
    }
    _scaleFactor = value;
    _layoutIndicator();
    markNeedsPaint();
  }

  void _scaleListener() {
    scaleFactor = scale.value;
  }

  void _positionListener() {
    heightFactor = position.value;
  }

  @override
  void dispose() {
    scale.removeListener(_scaleListener);
    position.removeListener(_positionListener);
    super.dispose();
  }

  RenderBox? get indicator => childForSlot(RefreshType.indicator);
  RenderBox get body => childForSlot(RefreshType.body)!;

  @override
  void performLayout() {
    final constraints = this.constraints;
    final body = this.body;

                                                     
                                                     
    body.layout(constraints.loosen(), parentUsesSize: true);
    if (constraints.hasBoundedHeight && constraints.hasBoundedWidth) {
      size = constraints.biggest;
    } else {
      size = Size(
        constraints.hasBoundedWidth ? constraints.maxWidth : body.size.width,
        constraints.hasBoundedHeight ? constraints.maxHeight : body.size.height,
      );
    }
    setOffset(body, Offset.zero);

    _layoutIndicator();
  }

               
                                                  
                                                            
                                                    
  void _layoutIndicator() {
    final indicator = this.indicator;
    if (indicator == null) return;
    final scaleSize = kIndicatorSize * scaleFactor;
    indicator.layout(
      BoxConstraints.tightFor(width: scaleSize, height: scaleSize),
    );
    setOffset(
      indicator,
      Offset(
        (constraints.maxWidth - scaleSize) / 2,
        edgeOffset +
            (kIndicatorSize + displacement) * heightFactor -
            kIndicatorSize +
            (kIndicatorSize - scaleSize) / 2,
      ),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    void doPaint(RenderBox child) {
      context.paintChild(child, getOffset(child) + offset);
    }

    doPaint(body);
    final indicator = this.indicator;
    if (indicator != null && heightFactor > 0 && scaleFactor > 0) {
      final indicatorOffset = getOffset(indicator);
      if (indicatorOffset.dy > 0) {
                      
        context.paintChild(indicator, indicatorOffset + offset);
        layer = null;
      } else {
                                      
        layer = context.pushClipRect(
          needsCompositing,
          offset,
          Offset.zero & size,
          (context, offset) {
            context.paintChild(indicator, indicatorOffset + offset);
          },
          clipBehavior: Clip.hardEdge,
          oldLayer: layer as ClipRectLayer?,
        );
      }
    } else {
      layer = null;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final body = this.body;
    return result.addWithPaintOffset(
      offset: getOffset(body),
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return body.hitTest(result, position: transformed);
      },
    );
  }
}

                                    
                                                           

                                      
typedef OnDrag = bool Function(double offset);

                       
   
                                       
                                           
                                
mixin RefreshScrollPhysicsMixin on ScrollPhysics {
  OnDrag get onDrag;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (offset < 0.0 && onDrag(offset)) {
      return 0.0;
    }
    return parent?.applyPhysicsToUserOffset(position, offset) ?? offset;
  }
}

                                     
                                                   
                                               
class RefreshScrollBehavior extends MaterialScrollBehavior {
  const RefreshScrollBehavior({required this.scrollPhysics});

  final RefreshScrollPhysicsMixin scrollPhysics;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return scrollPhysics;
  }

                                                          
                                            
                                              
  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };

                                    
                                          
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
                                                     
    return buildNaviOverscrollIndicator(context, child, details);
  }
}

                         
   
                                                        
                                           
class RefreshScrollPhysics extends ClampingScrollPhysics
    with RefreshScrollPhysicsMixin {
  const RefreshScrollPhysics({super.parent, required this.onDrag});

  @override
  final OnDrag onDrag;

  @override
  RefreshScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return RefreshScrollPhysics(parent: buildParent(ancestor), onDrag: onDrag);
  }
}

                              
Offset getOffset(RenderBox child) {
  return (child.parentData as BoxParentData).offset;
}

                              
void setOffset(RenderBox child, Offset offset) {
  (child.parentData as BoxParentData).offset = offset;
}
