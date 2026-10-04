                                
  
                                  
                                        
                                              
                                               
  
        
                                                                
                                                                
                                                
                            
  
                                        
                               
                                              
                                                             
                                    
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_push_transition.dart';

                                         
                                       
                                                   
                                       
                                             
class PopupOverlayGuard {
  static final ValueNotifier<int> active = ValueNotifier(0);

  static void open() => active.value++;

  static void close() => active.value = active.value > 0 ? active.value - 1 : 0;
}

                                               
                                                        
                                                         

                                            
                                                     
                                                          
                         
   
                                     
                                                                     
                                           
                                                 
                                                  
class IosBackdropScale extends StatefulWidget {
  final Widget child;

  const IosBackdropScale({super.key, required this.child});

  @override
  State<IosBackdropScale> createState() => _IosBackdropScaleState();
}

class _IosBackdropScaleState extends State<IosBackdropScale> {
  PageRoute<dynamic>? _route;

                                                            
  bool _registered = false;

  @override
  void initState() {
    super.initState();
                                                      
                                                         
                                        
    ImmersiveRouteDepth.active.addListener(_syncSecondaryRegistration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final pageRoute = route is PageRoute<dynamic> ? route : null;
    if (identical(pageRoute, _route)) return;
                            
    if (_route != null) CustomSecondaryTransitionRoutes.unregister(_route!);
    _route = pageRoute;
    _registered = false;
    _syncSecondaryRegistration();
  }

                              
     
                                                      
                                              
                                          
  void _syncSecondaryRegistration() {
    final route = _route;
    final want = route != null && ImmersiveRouteDepth.active.value > 0;
    if (want == _registered) return;
    if (route == null) {
      _registered = false;
      return;
    }
    _registered = want;
    if (want) {
      CustomSecondaryTransitionRoutes.register(route);
    } else {
      CustomSecondaryTransitionRoutes.unregister(route);
    }
  }

  @override
  void dispose() {
    ImmersiveRouteDepth.active.removeListener(_syncSecondaryRegistration);
    if (_route != null) CustomSecondaryTransitionRoutes.unregister(_route!);
    _registered = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (!SettingsService.heroTransitionBlurEnabled) return child;
    final route = ModalRoute.of(context);
    final secondary = route?.secondaryAnimation;
    return AnimatedBuilder(
      animation: Listenable.merge([
        if (secondary != null) secondary,
        FrostedHeroRoute.backdropProgress,
        PopupOverlayGuard.active,
                                             
        ImmersiveRouteDepth.active,
      ]),
      child: child,
      builder: (context, child) {
                                       
                                      
                                      
                                                             
                                 
                                                    
                                                
        final pageCovered =
            FrostedHeroRoute.backdropProgress.value > 0 ||
            !TickerMode.valuesOf(context).enabled;
                                     
                                                                       
                                                             
                                                                      
        final someoneTransitioningAbove =
            FrostedHeroRoute.backdropProgress.value > 0.001 ||
            (secondary?.value ?? 0) > 0.001;
                                            
                                      
        final activeAnim = FrostedHeroRoute.activeAnimation;
        final isSelfDriver =
            route != null &&
            activeAnim != null &&
            identical(route.animation, activeAnim);
                                            
                                                 
                                         
                                               
                                   
                                                
                                                         
                                            
        final immersiveAbove = ImmersiveRouteDepth.active.value > 0;
        final covered =
            immersiveAbove &&
            route != null &&
            (pageCovered || PopupOverlayGuard.active.value == 0) &&
            (!route.isCurrent || (someoneTransitioningAbove && !isSelfDriver));
                                                  
                                                
                  
                                      
                                                             
                                            
                                      
                                                   
                                        
                              
                                           
                   
        final coveringReversing =
            (secondary?.status == AnimationStatus.reverse) ||
            (activeAnim != null &&
                activeAnim.status == AnimationStatus.reverse);
        final double driving = math.max(
          secondary?.value ?? 0,
          FrostedHeroRoute.backdropProgress.value,
        );
                                                        
                                                
                                                     
        final frostedTransitionReversing =
            FrostedHeroRoute.backdropProgress.value > 0.001 ||
            (activeAnim != null &&
                activeAnim.status == AnimationStatus.reverse);
        final captureFrame =
            coveringReversing &&
            (FrostedHeroRoute.capturePopTargetFrame ||
                !frostedTransitionReversing) &&
            driving > 0.95;
        final raw = captureFrame ? 0.0 : (covered ? driving : 0.0);
        final t = Curves.easeOutCubic.transform(raw.clamp(0.0, 1.0));
                                           
                                            
        return Opacity(
          opacity: (1 - 0.60 * t).clamp(0.0, 1.0),
          child: Transform.scale(
                                               
            scale: 1 - 0.10 * t,
            alignment: Alignment.center,
            child: ClipRRect(
                                                  
              borderRadius: BorderRadius.circular(16 * t),
                                              
                                               
                                             
                                                  
                                                          
                              
              clipBehavior: t > 0.001 ? Clip.antiAlias : Clip.hardEdge,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
