                                      
  
                                                 
  
                               
                                              
                                          
                         
                                    
                                 
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UgcSelectionArea extends StatelessWidget {
  const UgcSelectionArea({super.key, required this.child});

  final Widget child;

  static bool get enabled {
    if (kIsWeb) return true;
    return defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android;
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return SelectionArea(child: child);
  }
}
