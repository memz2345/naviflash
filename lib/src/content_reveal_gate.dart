import 'dart:async';

import 'package:flutter/widgets.dart';

                      
   
                                                
                 
   
                                                    
                                                            
           
                                                                       
       
class GateCondition {
  const GateCondition(this.notifier, this.busy);

                                                                         
  final Listenable notifier;

                           
  final ValueGetter<bool> busy;
}

                 
   
                                                 
                                        
   
                                      
                  
   
                                                     
          
           
                                                              
                                  
                                                                            
         
                                                              
       
   
                                          
                         
class ContentRevealGate {
  ContentRevealGate({
    required this.onUnlock,
    this.fallbackTimeout = const Duration(milliseconds: 1500),
  });

                              
  final VoidCallback onUnlock;

                                          
                  
  final Duration fallbackTimeout;

  bool _unlocked = false;

                                         
                                              
  bool _pending = false;

  bool _started = false;
  bool _disposed = false;
  Timer? _fallback;
  final List<_GateWatch> _watches = <_GateWatch>[];

                                 
  bool get isGated => _pending || !_unlocked;

                            
  bool get isUnlocked => _unlocked;

                              
     
                                                                   
             
                                        
     
                                               
                                 
  void arm(
    BuildContext context, {
    bool waitForRouteAnimation = true,
    List<GateCondition> conditions = const <GateCondition>[],
  }) {
    if (_disposed || _started) return;
    _started = true;
    _pending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !context.mounted) return;
      if (waitForRouteAnimation) {
        _watchAnimation(ModalRoute.of(context)?.animation);
      }
      for (final condition in conditions) {
        _watches.add(
          _GateWatch(
            busy: condition.busy,
            attach: () {
              condition.notifier.addListener(_evaluate);
              return () => condition.notifier.removeListener(_evaluate);
            },
          ),
        );
      }
      for (final watch in _watches) {
        watch.detach = watch.attach();
      }
      _pending = false;
      _evaluate();
    });
  }

                                                          
  void _watchAnimation(Animation<double>? anim) {
    if (anim == null) return;
    _watches.add(
      _GateWatch(
        busy: () => !anim.isCompleted,
        attach: () {
          void onStatus(AnimationStatus status) {
            if (status == AnimationStatus.completed) _evaluate();
          }
          anim.addStatusListener(onStatus);
          return () => anim.removeStatusListener(onStatus);
        },
      ),
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _fallback?.cancel();
    _fallback = null;
    _unbind();
    _watches.clear();
  }

  void _evaluate() {
    if (_disposed || _unlocked) return;
    if (_watches.any((watch) => watch.busy())) {
                                         
      _fallback ??= Timer(fallbackTimeout, _unlock);
      return;
    }
    _unlock();
  }

  void _unlock() {
    if (_disposed || _unlocked) return;
    _unlocked = true;
    _fallback?.cancel();
    _fallback = null;
    _unbind();
    onUnlock();
  }

  void _unbind() {
    for (final watch in _watches) {
      watch.detach?.call();
      watch.detach = null;
    }
  }
}

                  
class _GateWatch {
  _GateWatch({required this.busy, required this.attach});

                
  final ValueGetter<bool> busy;

                  
  final ValueGetter<VoidCallback> attach;

                                        
  VoidCallback? detach;
}
