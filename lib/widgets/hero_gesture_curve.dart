                                      
  
                                            
  
                                                          
                                                                                              
                                              
                                                             
                                                  
  
                                       
                                      
                                    
  
                                          
                                                      
                                                              
               
  
                                                       
  
                                                                
                                                                                     
import 'package:flutter/widgets.dart';

class HeroGestureCurve extends InheritedWidget {
  const HeroGestureCurve({
    super.key,
    required this.linear,
    required super.child,
  });

                                    
  final bool linear;

                                           
                                    
  static Curve? curveOrNull(BuildContext context) {
    final HeroGestureCurve? scope =
        context.dependOnInheritedWidgetOfExactType<HeroGestureCurve>();
    if (scope == null || !scope.linear) return null;
    return Curves.linear;
  }

  @override
  bool updateShouldNotify(HeroGestureCurve oldWidget) =>
      oldWidget.linear != linear;
}
