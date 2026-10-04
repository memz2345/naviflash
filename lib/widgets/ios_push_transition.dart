                                       
  
                                                         
                            
                                          
                                                     
                                              
                                                  
                                                  
  
                     
                                                         
                                                         
                                                                
                                                      
                                              
                                                 
                                                          
                                      
                        
                                                
                                                  
                                      
                            
  
                      
                                                                    
                                                              
                                    
                                      
                                                    
                                                       
                                            
  
      
                                                         
                                              
                
                                       
                                           
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/hero_gesture_curve.dart';
import 'package:naviflash/widgets/predictive_back_detector.dart';

                                      
const double kIosPushDimOpacity = 0.40;

                       
   
                                   
                                                  
                                           
const Duration kIosPushCornerHold = Duration.zero;

                                 
                                       
const int _cornerCollapseMs = 480;

                                        
const int _cornerRestoreMs = 320;

                       
   
                                                  
                                   
                                                            
               
   
                                                    
                                           
                                   
                                                   
                                               
class CustomSecondaryTransitionRoutes {
  CustomSecondaryTransitionRoutes._();

  static final Set<PageRoute<dynamic>> _routes = <PageRoute<dynamic>>{};

  static void register(PageRoute<dynamic> route) => _routes.add(route);

  static void unregister(PageRoute<dynamic> route) => _routes.remove(route);

  static bool contains(PageRoute<dynamic> route) => _routes.contains(route);
}

                                            
                                                              
class IosPushPageTransitionsBuilder extends PageTransitionsBuilder {
  const IosPushPageTransitionsBuilder({
                           
    this.cornerRadius = 26.0,

                              
    this.dimOpacity = kIosPushDimOpacity,

                     
    this.underneathFraction = 0.30,

                               
    this.transitionMs = 420,

                                          
                                   
    this.predictiveBack = true,
  });

  final double cornerRadius;
  final double dimOpacity;
  final double underneathFraction;
  final int transitionMs;
  final bool predictiveBack;

  @override
  Duration get transitionDuration => Duration(milliseconds: transitionMs);

  @override
  Duration get reverseTransitionDuration =>
      Duration(milliseconds: transitionMs);

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    Widget build(bool popGestureInProgress) => _IosPushPageTransition(
          route: route,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          cornerRadius: cornerRadius,
          dimOpacity: dimOpacity,
          underneathFraction: underneathFraction,
          popGestureInProgress: popGestureInProgress,
          child: child,
        );

                                          
    if (!predictiveBack || route == null) return build(false);

    return PredictiveBackGestureDetector(
      route: route,
      builder: (context, popGestureInProgress) => HeroGestureCurve(
        linear: popGestureInProgress,
        child: build(popGestureInProgress),
      ),
    );
  }
}

                                      
const Curve _transitionCurve = Curves.easeInOutCubicEmphasized;

class _IosPushPageTransition extends StatefulWidget {
  const _IosPushPageTransition({
    required this.route,
    required this.animation,
    required this.secondaryAnimation,
    required this.cornerRadius,
    required this.dimOpacity,
    required this.underneathFraction,
    required this.popGestureInProgress,
    required this.child,
  });

  final PageRoute<dynamic>? route;

                                           
  final Animation<double> animation;

                                
  final Animation<double> secondaryAnimation;

  final double cornerRadius;
  final double dimOpacity;
  final double underneathFraction;

                                    
                             
  final bool popGestureInProgress;

  final Widget child;

  @override
  State<_IosPushPageTransition> createState() =>
      _IosPushPageTransitionState();
}

class _IosPushPageTransitionState extends State<_IosPushPageTransition>
    with SingleTickerProviderStateMixin {
                                     
                                              
  final GlobalKey _pageKey = GlobalKey();

                             
     
                                    
                                                                    
  late final AnimationController _cornerCtrl;

                                               
  Timer? _cornerTimer;

  AnimationStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _cornerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _cornerCollapseMs),
      value: 1.0,
    );
    widget.animation.addStatusListener(_onAnimationStatus);
    _applyStatus(widget.animation.status);
  }

  @override
  void didUpdateWidget(covariant _IosPushPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeStatusListener(_onAnimationStatus);
      widget.animation.addStatusListener(_onAnimationStatus);
      _lastStatus = null;
      _applyStatus(widget.animation.status);
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onAnimationStatus);
    _cornerTimer?.cancel();
    _cornerCtrl.dispose();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == _lastStatus) return;
    _lastStatus = status;
    _applyStatus(status);
  }

                    
                                        
                                                       
                               
                                         
  void _applyStatus(AnimationStatus status) {
    _cornerTimer?.cancel();
    switch (status) {
      case AnimationStatus.forward:
                                    
        _cornerCtrl.value = 1.0;
        break;
      case AnimationStatus.reverse:
                                          
        if (_cornerCtrl.value < 1.0) {
          _cornerCtrl.animateTo(
            1.0,
            duration: const Duration(milliseconds: _cornerRestoreMs),
            curve: Curves.easeOutCubic,
          );
        }
        break;
      case AnimationStatus.completed:
                                                    
                                               
        if (kIosPushCornerHold <= Duration.zero) {
          _collapseCorner();
        } else {
          _cornerTimer = Timer(kIosPushCornerHold, () {
            if (mounted) _collapseCorner();
          });
        }
        break;
      case AnimationStatus.dismissed:
        _cornerCtrl.value = 1.0;
        break;
    }
  }

                    
     
                                            
                             
  void _collapseCorner() {
    _cornerCtrl.animateTo(
      0.0,
      duration: const Duration(milliseconds: _cornerCollapseMs),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
                                         
                                 
    double curve(double v, Curve c) =>
        widget.popGestureInProgress ? v : c.transform(v);

                                         
                                                      
                                                             
                                            
    final Widget entering = AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _cornerCtrl]),
      child: widget.child,
      builder: (context, child) {
        final double a = widget.animation.value.clamp(0.0, 1.0).toDouble();
        final double t = curve(a, _transitionCurve);
                                                 
                                                     
                                                 
                                            
        final radius = widget.cornerRadius * _cornerCtrl.value;
        return FractionalTranslation(
          translation: Offset(1 - t, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
                                                 
                                          
                                    
                                                        
                            
            clipBehavior: radius > 0.001 ? Clip.antiAlias : Clip.hardEdge,
            child: child,
          ),
        );
      },
    );

                                                   
                                               
                                        
    final route = widget.route;
    final bool hasCustomSecondary = route != null &&
        CustomSecondaryTransitionRoutes.contains(route) &&
        SettingsService.heroTransitionBlurEnabled;
    if (hasCustomSecondary) {
      return KeyedSubtree(key: _pageKey, child: entering);
    }

                                               
                                          
                                             
                                   
    return AnimatedBuilder(
      animation: widget.secondaryAnimation,
      child: KeyedSubtree(key: _pageKey, child: entering),
      builder: (context, child) {
        final raw = widget.secondaryAnimation.value
            .clamp(0.0, 1.0)
            .toDouble();
        final t = curve(raw, _transitionCurve);
                                                    
                                          
        final dim =
            widget.dimOpacity * curve(raw, Curves.easeOutCubic);
        return FractionalTranslation(
          translation: Offset(-widget.underneathFraction * t, 0),
          child: Stack(
            children: <Widget>[
              child!,
              if (dim > 0.001)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(color: Color.fromRGBO(0, 0, 0, dim)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
