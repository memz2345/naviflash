                                            
  
                                                     
  
          
                                                        
                                                     
                                                           
                                                            
                                         
  
         
                                              
                                     
                                                                      
                                                             
                                                
                                                                     
                                                            
                                                     
                                      
  
                                                     
                                            
  
                                      
                                                                  
                                            
                                           
                                                       
                                                     
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PredictiveBackEvent;

                                                       
   
                                                                     
                                                  
                                      
   
                                                   
                                                                        
                                                              
                                           
                                   
class PredictiveBackHook {
  const PredictiveBackHook({
    required this.allow,
    required this.prepare,
    required this.restore,
  });

                                           
  final bool Function() allow;

                               
     
                                                     
                                                     
                   
  final VoidCallback prepare;

                                         
     
                                                    
                                        
  final VoidCallback restore;

  static final Map<ModalRoute<dynamic>, PredictiveBackHook> _hooks =
      <ModalRoute<dynamic>, PredictiveBackHook>{};

  static void register(ModalRoute<dynamic> route, PredictiveBackHook hook) =>
      _hooks[route] = hook;

  static void unregister(ModalRoute<dynamic> route) => _hooks.remove(route);

  static PredictiveBackHook? of(ModalRoute<dynamic> route) => _hooks[route];
}

class PredictiveBackGestureDetector extends StatefulWidget {
  const PredictiveBackGestureDetector({
    super.key,
    required this.route,
    required this.builder,
  });

             
     
                                             
                                                          
                                                          
                                                           
  final ModalRoute<dynamic> route;

                                                   
  final Widget Function(BuildContext context, bool popGestureInProgress)
      builder;

                                             
     
                                                     
                                                                  
                                                                
                                                            
                                   
     
                                                        
                                          
     
                                                               
             
  static AnimationController? controllerOf(ModalRoute<dynamic> route) {
    Animation<double>? animation = route.animation;
    if (animation is ProxyAnimation) animation = animation.parent;
    return animation is AnimationController ? animation : null;
  }

  @override
  State<PredictiveBackGestureDetector> createState() =>
      _PredictiveBackGestureDetectorState();
}

class _PredictiveBackGestureDetectorState
    extends State<PredictiveBackGestureDetector> with WidgetsBindingObserver {
                                          
                    
     
                                                               
                                                      
                                                     
                                           
     
                                                             
                                             
  bool get _enabled =>
      widget.route.isCurrent &&
      (widget.route.popGestureEnabled || _hookAllows());

  PredictiveBackHook? get _hook => PredictiveBackHook.of(widget.route);

                                                     
     
                                                                    
                                              
                                
  bool _hookAllows() {
    final hook = _hook;
    if (hook == null) return false;
    final ModalRoute<dynamic> route = widget.route;
    if (route.isFirst) return false;
    if (route.willHandlePopInternally) return false;
                                        
    if (route.animation?.isCompleted != true) return false;
    if (route.popGestureInProgress) return false;
    return hook.allow();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _removeRestoreListener();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

                                       
  double _latestProgress = 0;

                                  
  bool _pendingStart = false;

                                  
     
                                                                   
                                                                                  
                                                                
                                                              
                         
  bool _routeGestureStarted = false;

                                                  
  bool _prepared = false;

                                     
  bool _restorePending = false;

  ValueNotifier<bool>? _gestureNotifier;
  VoidCallback? _restoreListener;

                                 
                                                                
  bool get _active => _pendingStart || widget.route.popGestureInProgress;

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
                                
    if (!_enabled || backEvent.isButtonEvent) return false;
                                             
    _latestProgress = 1 - backEvent.progress;

                                            
                                                             
                                        
    _hook?.prepare();
    _prepared = true;

    if (mounted) setState(() => _pendingStart = true);

                                                         
                                                      
                                        
                                  
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.route.isCurrent) {
                                   
        widget.route.handleStartBackGesture(progress: _latestProgress);
        _routeGestureStarted = true;
      }
      setState(() => _pendingStart = false);
    });
    return true;
  }

                                                  
  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
                                                    
                                                              
    _latestProgress = 1 - backEvent.progress;
    widget.route.handleUpdateBackGestureProgress(progress: _latestProgress);
  }

  @override
  void handleCommitBackGesture() {
    _cancelPendingRestore();
                        
    _prepared = false;
    if (!_routeGestureStarted) return;
    _routeGestureStarted = false;

    final ModalRoute<dynamic> route = widget.route;
                                         
    final AnimationController? controller =
        PredictiveBackGestureDetector.controllerOf(route);
    final double resumeFrom = controller?.value ?? _latestProgress;

    route.handleCommitBackGesture();

                                                                       
                                                                        
                                                        
      
                                                                
      
                                                
                                            
                                                    
      
                                          
                                                
                                             
                                         
    if (controller != null &&
        controller.isAnimating &&
        resumeFrom > 0 &&
        resumeFrom < 1) {
      controller.reverse(from: resumeFrom);
    }
  }

  @override
  void handleCancelBackGesture() {
    if (_routeGestureStarted) {
      _routeGestureStarted = false;
      widget.route.handleCancelBackGesture();
    }
    if (_prepared) _scheduleRestore();
  }

                                                        
                                                                      
     
                                                                        
                                                                
                                               
  void _scheduleRestore() {
    if (_restorePending) return;
    _restorePending = true;

    final ValueNotifier<bool>? notifier =
        widget.route.navigator?.userGestureInProgressNotifier;
    if (notifier == null || !notifier.value) {
      _restoreAfterFrame();
      return;
    }
                                              
                                       
    late final VoidCallback listener;
    listener = () {
      if (notifier.value) return;                   
      _removeRestoreListener();
      _restoreAfterFrame();
    };
    _gestureNotifier = notifier;
    _restoreListener = listener;
    notifier.addListener(listener);
  }

  void _restoreAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restorePending = false;
      if (!mounted || !_prepared) return;
      _prepared = false;
      _hook?.restore();
    });
  }

  void _cancelPendingRestore() {
    _removeRestoreListener();
    _restorePending = false;
  }

  void _removeRestoreListener() {
    final notifier = _gestureNotifier;
    final listener = _restoreListener;
    if (notifier != null && listener != null) {
      notifier.removeListener(listener);
    }
    _gestureNotifier = null;
    _restoreListener = null;
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _active);
}
