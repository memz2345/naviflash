                                      
  
                  
                                
                       
                                                                
                                       
                                                           
                                            
                
                                   
                           
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EdgeScrollHaptic extends StatelessWidget {
  final Widget child;

                     
  static const double _velocityThreshold = 900;

                                              
  static const double _deltaThreshold = 16;

  static DateTime _lastHaptic = DateTime.fromMillisecondsSinceEpoch(0);

  const EdgeScrollHaptic({super.key, required this.child});

  static void _fire() {
    final now = DateTime.now();
    if (now.difference(_lastHaptic) < const Duration(milliseconds: 250)) {
      return;
    }
    _lastHaptic = now;
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is OverscrollNotification) {
          if (n.velocity.abs() >= _velocityThreshold) _fire();
          return false;
        }
        if (n is ScrollUpdateNotification) {
          final m = n.metrics;
          final delta = n.scrollDelta ?? 0;
          if (delta.abs() < _deltaThreshold) return false;
                                    
          final atBottom = m.pixels >= m.maxScrollExtent - 0.5 && delta > 0;
          final atTop = m.pixels <= m.minScrollExtent + 0.5 && delta < 0;
          if (atBottom || atTop) _fire();
        }
        return false;
      },
      child: child,
    );
  }
}
