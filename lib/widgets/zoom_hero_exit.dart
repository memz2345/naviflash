                                  
  
                                         
                                      
  
                 
                                                 
                                                     
                                        
                                         
                          
  
                                     
                                           
                 
  
                                                               
                                           
                                             
                                                     
                                              
                                
  
                                 
                                        
                                           
                                          
                                                               
                                                   
                   
import 'package:flutter/material.dart';
import 'package:naviflash/widgets/predictive_back_detector.dart';

                            
@immutable
class ZoomHeroExitPlan {
  const ZoomHeroExitPlan({
    required this.unmountPlayer,
    required this.rewrapHero,
  });

                          
  final bool unmountPlayer;

                                     
  final bool rewrapHero;

  bool get isEmpty => !unmountPlayer && !rewrapHero;

                                           
  bool get empty => isEmpty;
}

                       
   
                                                    
                                        
ZoomHeroExitPlan planZoomHeroExit({
  required bool playerMounted,
  required bool usesZoomHero,
  required bool zoomHeroActive,
}) {
  return ZoomHeroExitPlan(
    unmountPlayer: playerMounted,
    rewrapHero: usesZoomHero && !zoomHeroActive,
  );
}

                 
   
                                        
                                             
void popRouteAfterRebuild({
  required BuildContext context,
  required VoidCallback? rebuild,
  VoidCallback? onBeforePop,
}) {
  if (rebuild == null) {
    onBeforePop?.call();
    Navigator.of(context).pop();
    return;
  }
  rebuild();
  WidgetsBinding.instance.addPostFrameCallback((_) {
                                         
    onBeforePop?.call();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  });
}

                                                              
   
                                                              
                                       
                                                            
                                               
                                                          
                                                          
   
                                                    
                                                    
                                             
                                              
Widget zoomHeroDragPlaceholder({
  required bool keepAlive,
  required Size heroSize,
  required Widget child,
}) {
  if (!keepAlive) {
    return SizedBox(width: heroSize.width, height: heroSize.height);
  }
  return SizedBox(
    width: heroSize.width,
    height: heroSize.height,
    child: Offstage(child: TickerMode(enabled: false, child: child)),
  );
}

                                           
   
                                                     
                                                            
                                                           
                                                
                                           
                          
   
              
           
                                                             
                                  
                                 
                                               
                                                  
        
                                                                 
                                                                 
      
   
             
                                  
                                    
                                
     
   
             
                    
                         
                      
     
   
                       
                
                   
                                                
                                                               
         
      
       
   
                                                
                                                    
                                                           
                                                          
                                                    
class ZoomHeroBackDrag {
  ZoomHeroBackDrag({
    required this.canDrag,
    required this.setHeroWrapped,
    this.onDragStart,
    this.onDragCancel,
  });

                                             
                                              
                                                  
  final bool Function() canDrag;

                                                           
     
                                          
                                 
  final void Function(bool wrapped) setHeroWrapped;

                                   
     
                                              
  final VoidCallback? onDragStart;

                                        
  final VoidCallback? onDragCancel;

                   
  final GlobalKey bodyKey = GlobalKey();

  bool _preparing = false;

                             
     
                                                   
                                             
  bool get preparing => _preparing;

  ModalRoute<dynamic>? _route;

                                                                       
  Widget placeholder(BuildContext context, Size heroSize, Widget child) =>
      zoomHeroDragPlaceholder(
        keepAlive: _preparing,
        heroSize: heroSize,
        child: child,
      );

                                               
  void attach(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null || identical(route, _route)) return;
    detach();
    _route = route;
    PredictiveBackHook.register(
      route,
      PredictiveBackHook(
        allow: () => !_preparing && canDrag(),
        prepare: _prepare,
        restore: _restore,
      ),
    );
  }

                                             
  void detach() {
    final route = _route;
    if (route == null) return;
    _route = null;
    PredictiveBackHook.unregister(route);
  }

  void _prepare() {
    if (_preparing) return;
    _preparing = true;
    onDragStart?.call();
    setHeroWrapped(true);
  }

  void _restore() {
    if (!_preparing) return;
                                                        
                                                 
    _preparing = false;
    setHeroWrapped(false);
    onDragCancel?.call();
  }
}
