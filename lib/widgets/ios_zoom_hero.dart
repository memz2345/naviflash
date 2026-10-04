                                 
  
                                                   
  
                                                
                                                       
                                      
             
  
      
                                                         
                                              
                                        
                                                
                                        
                                                  
                                     
                                               
                                         
  
                                                       
                                                 
                                                    
import 'package:flutter/material.dart';

                            
const double kZoomHeroFlightRadius = 12.0;

                                                    
Widget iosZoomHeroFlightShuttle({
  required Animation<double> animation,
  required HeroFlightDirection direction,
  required BuildContext fromContext,
  required BuildContext toContext,
  double flightRadius = kZoomHeroFlightRadius,
}) {
  final isPop = direction == HeroFlightDirection.pop;
  final target = isPop ? fromContext : toContext;
  final heroWidget = target.widget as Hero;
                                
  final fadeIn = CurvedAnimation(
    parent: animation,
    curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
  );
  return AnimatedBuilder(
    animation: fadeIn,
    builder: (context, _) {
                                                         
                                         
              
      final returning =
          isPop || animation.status == AnimationStatus.reverse;
      final screen = MediaQuery.sizeOf(context);
      final Widget flying = ClipRRect(
        borderRadius: BorderRadius.circular(flightRadius),
        clipBehavior: Clip.antiAlias,
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: returning ? Alignment.topCenter : Alignment.center,
          clipBehavior: Clip.hardEdge,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(flightRadius),
            child: SizedBox(
              width: screen.width,
              height: screen.height,
              child: heroWidget.child,
            ),
          ),
        ),
      );
      return Opacity(
        opacity: returning ? 1.0 : 0.35 + 0.65 * fadeIn.value,
        child: flying,
      );
    },
  );
}

                                                      
                                      
                                        
                                               
                                        
                                 
   
                                             
                                               
Widget imageZoomHeroFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromContext,
  BuildContext toContext,
) {
  final isPop = direction == HeroFlightDirection.pop;
  final fadeIn = CurvedAnimation(
    parent: animation,
    curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
  );
  return AnimatedBuilder(
    animation: fadeIn,
    builder: (context, _) {
                                                         
                                     
      final returning = isPop || animation.status == AnimationStatus.reverse;
      final Widget flying;
      if (isPop) {
        flying = (toContext.widget as Hero).child;
      } else {
        final screen = MediaQuery.sizeOf(context);
        final heroWidget = toContext.widget as Hero;
        flying = ClipRRect(
          borderRadius: BorderRadius.circular(kZoomHeroFlightRadius),
          clipBehavior: Clip.antiAlias,
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(kZoomHeroFlightRadius),
              child: SizedBox(
                width: screen.width,
                height: screen.height,
                child: heroWidget.child,
              ),
            ),
          ),
        );
      }
      return Opacity(
        opacity: returning ? 1.0 : 0.35 + 0.65 * fadeIn.value,
        child: flying,
      );
    },
  );
}

                                            
                                          
                                      
                                                                     
                        
class ZoomHeroScope extends InheritedWidget {
  const ZoomHeroScope({
    super.key,
    required this.active,
    required super.child,
  });

                                           
  final bool active;

                                              
  static bool activeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ZoomHeroScope>()?.active ??
      false;

  @override
  bool updateShouldNotify(ZoomHeroScope oldWidget) =>
      oldWidget.active != active;
}
