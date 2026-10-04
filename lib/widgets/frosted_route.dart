                                 
  
              
                                     
                                         
                                       
                                      
               
                                                
  
                                                    
                                              
                                               
                                         
                                            
import 'package:flutter/material.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/hero_gesture_curve.dart';
import 'package:naviflash/widgets/predictive_back_detector.dart';

                   
                                                   
                                              
                                   
   
                                                   
                                             
                                        
                                               
Route<T> heroTransitionRoute<T>({
  required Widget page,
  bool heroZoom = false,
  RouteSettings? settings,
}) {
  if (!SettingsService.heroTransitionBlurEnabled) {
    return MaterialPageRoute<T>(settings: settings, builder: (_) => page);
  }
  return FrostedHeroRoute<T>(
    page: page,
    heroZoom: heroZoom,
    blurSigma: heroZoom ? 12.0 : 0.0,
    settings: settings,
  );
}

                                
   
                                             
            
   
                                                     
                                                   
                                            
   
                                            
                                        
                                             
          
   
                                          
                                                     
                            
abstract interface class ImmersivePageMarker {}

                               
   
                                                                 
                                                     
                                                         
                                                         
class ImmersiveRouteDepth {
  ImmersiveRouteDepth._();

  static final ValueNotifier<int> active = ValueNotifier<int>(0);

  static void add() => active.value++;

  static void remove() {
    if (active.value > 0) active.value--;
  }

                          
  @visibleForTesting
  static void reset() => active.value = 0;
}

                                                
                                                             
   
                                                    
                                                               
                                                             
mixin _ImmersiveDepthCounted<T> on PageRoute<T> {
                                            
  Widget get immersivePage;

                                                              
  bool _depthCounted = false;

  void _claimImmersiveDepth() {
    if (immersivePage is ImmersivePageMarker && !_depthCounted) {
      _depthCounted = true;
      ImmersiveRouteDepth.add();
    }
  }

                             
  void _releaseImmersiveDepth() {
    if (_depthCounted) {
      _depthCounted = false;
      ImmersiveRouteDepth.remove();
    }
  }
}

                                                     
                                  
                                                  
                            
   
                                              
class ImmersiveMaterialPageRoute<T> extends MaterialPageRoute<T>
    with _ImmersiveDepthCounted<T> {
  ImmersiveMaterialPageRoute({required Widget page, super.settings})
    : _page = page,
      super(builder: (_) => page);

  final Widget _page;

  @override
  Widget get immersivePage => _page;

  @override
  TickerFuture didPush() {
    _claimImmersiveDepth();
    return super.didPush();
  }

  @override
  void dispose() {
    _releaseImmersiveDepth();
    super.dispose();
  }
}

class FrostedHeroRoute<T> extends PageRouteBuilder<T>
    with _ImmersiveDepthCounted<T> {
                                               
     
                                                          
                                    
                                       
  static final ValueNotifier<double> backdropProgress = ValueNotifier(0);

                                              
                                           
                                            
  static Animation<double>? _activeAnimation;
  static AnimationStatusListener? _activeStatusListener;

                                     
                                     
  static bool _capturePopTargetFrame = false;

                          
  static bool get capturePopTargetFrame => _capturePopTargetFrame;

                                  
     
                                
                                             
                        
                                           
                                              
                                                
                        
  static Animation<double>? get activeAnimation => _activeAnimation;

                                              
     
                                        
                                                      
                                                        
  static void _onProgressTick() {
    final animation = _activeAnimation;
    if (animation == null) return;
    final progress = animation.value.clamp(0.0, 1.0);
    if (progress > 0.001) {
      if (backdropProgress.value != progress) {
        backdropProgress.value = progress;
      }
    } else if (backdropProgress.value != 0) {
      backdropProgress.value = 0;
    }
  }

                          
                                                     
                                       
                             
                                 
  static void _onProgressStatus(AnimationStatus status) {
    if ((status == AnimationStatus.dismissed ||
            status == AnimationStatus.completed) &&
        backdropProgress.value != 0) {
      backdropProgress.value = 0;
    }
    if (status == AnimationStatus.dismissed ||
        status == AnimationStatus.completed) {
      _capturePopTargetFrame = false;
    }
  }

  static void _claimProgress(Animation<double> animation) {
    if (identical(_activeAnimation, animation)) return;

    final oldAnimation = _activeAnimation;
    final oldStatusListener = _activeStatusListener;
    oldAnimation?.removeListener(_onProgressTick);
    if (oldAnimation != null && oldStatusListener != null) {
      oldAnimation.removeStatusListener(oldStatusListener);
    }

    _activeAnimation = animation;
    animation.addListener(_onProgressTick);

                           
    late final AnimationStatusListener statusListener;
    statusListener = (status) {
      if (identical(_activeAnimation, animation)) {
        _onProgressStatus(status);
      }
    };
    _activeStatusListener = statusListener;
    animation.addStatusListener(statusListener);
  }

                      
     
                                     
                                                   
                                                          
                                                  
                                        
  static void _releaseProgress() {
    final oldAnimation = _activeAnimation;
    final oldStatusListener = _activeStatusListener;
    oldAnimation?.removeListener(_onProgressTick);
    if (oldAnimation != null && oldStatusListener != null) {
      oldAnimation.removeStatusListener(oldStatusListener);
    }
    _activeAnimation = null;
    _activeStatusListener = null;
    if (backdropProgress.value != 0) {
      backdropProgress.value = 0;
    }
  }

  static void _attachProgress(Animation<double> animation) {
    if (identical(_activeAnimation, animation)) return;
                                          
                                              
                                       
    final active = _activeAnimation;
    if (active != null &&
        (active.status == AnimationStatus.forward ||
            active.status == AnimationStatus.reverse)) {
      return;
    }
    _claimProgress(animation);
  }

                        
     
                                                   
                                                      
  final double _blurSigma;
  double get blurSigma => _blurSigma;

                                            
  final Widget _page;

  @override
  Widget get immersivePage => _page;

  FrostedHeroRoute({
    required Widget page,
    double blurSigma = 12.0,

                                     
                                  
    super.transitionDuration = const Duration(milliseconds: 500),

                                           
                                 
    bool heroZoom = false,

                                                
                                               
                                        
    bool childZoom = false,

                                        
                                            
                                         
                                               
    Rect? beginRect,

                                                   
    double beginRadius = 12.0,
    super.settings,
  }) : _blurSigma = blurSigma,
       _page = page,
       super(
         reverseTransitionDuration: transitionDuration,
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                   
                                              
                                                        
           _attachProgress(animation);

                                             
                                                         
                                 
             
                                                     
                                                     
                                                               
                                       
           var gesturing = false;

           Widget buildContent() {
                                        
                                             
             final sigmaTween = TweenSequence<double>([
               TweenSequenceItem(
                 tween: Tween(
                   begin: 0.0,
                   end: 1.0,
                 ).chain(CurveTween(curve: Curves.easeOut)),
                 weight: 25,
               ),
               TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
               TweenSequenceItem(
                 tween: Tween(
                   begin: 1.0,
                   end: 0.0,
                 ).chain(CurveTween(curve: Curves.easeIn)),
                 weight: 40,
               ),
             ]);
                                    
             Animation<double> eased(Curve curve, {Curve? reverseCurve}) {
               if (gesturing) return animation;
               return CurvedAnimation(
                 parent: animation,
                 curve: curve,
                 reverseCurve: reverseCurve,
               );
             }

             return AnimatedBuilder(
               animation: animation,
               builder: (context, _) {
                                                    
                                                      
                 final fog = blurSigma <= 0
                     ? 0.0
                     : sigmaTween.evaluate(animation);
                                                       
                                          
                 final oldPageDim = 0.40 * fog;
                                                    
                 final childFog = 0.30 * fog;
                 return Stack(
                   fit: StackFit.expand,
                   children: [
                                                      
                     if (oldPageDim > 0.003)
                       IgnorePointer(
                         child: ColoredBox(
                           color: Color.fromRGBO(0, 0, 0, oldPageDim),
                         ),
                       ),
                     if (heroZoom)
                                                         
                                                    
                                             
                       child
                     else if (beginRect != null)
                                                  
                                                   
                       Builder(
                         builder: (context) {
                           final size = MediaQuery.sizeOf(context);
                           final end = Offset.zero & size;
                           final raw = animation.value.clamp(0.0, 1.0);
                           final t = gesturing
                               ? raw
                               : Curves.easeOutCubic.transform(raw);
                           final rect = Rect.lerp(beginRect, end, t) ?? end;
                           return Positioned.fromRect(
                             rect: rect,
                             child: ClipRRect(
                               borderRadius: BorderRadius.circular(
                                 beginRadius * (1 - t),
                               ),
                               child: FittedBox(
                                 fit: BoxFit.fill,
                                 child: SizedBox(
                                   width: size.width,
                                   height: size.height,
                                   child: child,
                                 ),
                               ),
                             ),
                           );
                         },
                       )
                     else if (childZoom)
                                                         
                                                 
                       FadeTransition(
                         opacity: eased(Curves.easeOutCubic),
                         child: ScaleTransition(
                           scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                             eased(
                               Curves.easeOutCubic,
                               reverseCurve: Curves.easeInCubic,
                             ),
                           ),
                           child: childFog > 0.003
                               ? DecoratedBox(
                                                               
                                                
                                   decoration: BoxDecoration(
                                     color: Color.fromRGBO(0, 0, 0, childFog),
                                   ),
                                   child: child,
                                 )
                               : child,
                         ),
                       )
                     else
                                                   
                                                
                       FadeTransition(
                         opacity: eased(Curves.easeOutCubic),
                         child: SlideTransition(
                           position:
                               Tween<Offset>(
                                 begin: const Offset(1, 0),
                                 end: Offset.zero,
                               ).animate(
                                 eased(
                                   Curves.easeOutCubic,
                                   reverseCurve: Curves.easeInCubic,
                                 ),
                               ),
                           child: childFog > 0.003
                               ? DecoratedBox(
                                                               
                                                
                                   decoration: BoxDecoration(
                                     color: Color.fromRGBO(0, 0, 0, childFog),
                                   ),
                                   child: child,
                                 )
                               : child,
                         ),
                       ),
                   ],
                 );
               },
             );
           }

                                                 
                                                
                                                 
           final route = ModalRoute.of(context);
           if (route == null) return buildContent();
           return PredictiveBackGestureDetector(
             route: route,
             builder: (_, g) {
               gesturing = g;
                                                   
                                               
                                                 
               return HeroGestureCurve(linear: g, child: buildContent());
             },
           );
         },
       );

  @override
  TickerFuture didPush() {
    _capturePopTargetFrame = false;
                                         
                                                
    _claimImmersiveDepth();
    final result = super.didPush();
    final routeAnimation = animation;
    if (routeAnimation != null) _claimProgress(routeAnimation);
    return result;
  }

  @override
  bool didPop(T? result) {
                                           
                                              
    final routeAnimation = animation;
    _capturePopTargetFrame =
        routeAnimation?.status == AnimationStatus.completed;
    if (routeAnimation != null) _claimProgress(routeAnimation);
    return super.didPop(result);
  }

  @override
  void dispose() {
                                              
                    
    _releaseImmersiveDepth();
                                               
                                             
                                                        
                                      
    if (identical(_activeAnimation, animation)) {
      _capturePopTargetFrame = false;
      _releaseProgress();
    }
    super.dispose();
  }
}
