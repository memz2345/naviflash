                                         
  
                             
                                              
                                                  
                                                        
  
                                                 
                                          
                                                 
                                  
  
                                       
                                         
                                                    
                               
                                                 
                                 
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/services/taskbar_progress_service.dart';
import 'package:naviflash/widgets/navi_overscroll.dart';
import 'package:naviflash/widgets/plus_refresh_indicator.dart'
    show PlusRefreshIndicator;

                        
                                                           
                                    
                                              
                                                    
class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  const _MouseDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.unknown,
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

class AppRefreshIndicator extends StatelessWidget {
  final RefreshCallback onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;

                                     
                                    
                   
  final double? displacement;

                                       
                                             
  final double? edgeOffset;

  final ScrollNotificationPredicate? notificationPredicate;

                                                      
  final RefreshIndicatorTriggerMode? triggerMode;

                                          
                                                                
                                                         
                                        
     
                                                          
                                                                     
                  
  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;

  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.displacement,
    this.edgeOffset,
    this.notificationPredicate,
    this.triggerMode,
    this.refreshIndicatorKey,
  });

  @override
  Widget build(BuildContext context) {
                                                         
                                             
                                      
    SettingsService? settings;
    try {
      settings = Provider.of<SettingsService>(context);
    } on ProviderNotFoundException {
      settings = null;
    }
    return ScrollConfiguration(
                                   
      behavior: const _MouseDragScrollBehavior(),
      child: PlusRefreshIndicator(
                             
        key: refreshIndicatorKey,
                                               
        onRefresh: () => TaskbarProgress.track<void>(Object(), onRefresh),
        displacement: displacement ?? settings?.refreshDisplacement ?? 40.0,
        edgeOffset: edgeOffset ?? settings?.refreshEdgeOffset ?? 0.0,
        color: color,
        backgroundColor: backgroundColor,
        notificationPredicate:
            notificationPredicate ?? defaultScrollNotificationPredicate,
        triggerMode: triggerMode ?? RefreshIndicatorTriggerMode.onEdge,
                                                      
                                          
        onArmed: () => HapticFeedback.mediumImpact(),
        child: child,
      ),
    );
  }
}

                                                                    
   
                        
                                         
                                                     
                
   
                                                      
                                                     
class AppRefreshScrollPhysics extends ClampingScrollPhysics {
  const AppRefreshScrollPhysics({super.parent});

  @override
  AppRefreshScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      AppRefreshScrollPhysics(parent: buildParent(ancestor));
}
