                                       
  
                                
                                                                     
                                          
                                                           
                                                                 
                                                
                                                 
                             
  
                                                       
                                                   
                                             
import 'package:flutter/material.dart';

import '../services/settings_service.dart';

                                                   
   
                                                        
                                                        
                      
class NaviTabBarViewScrollPhysics extends ClampingScrollPhysics {
  const NaviTabBarViewScrollPhysics({super.parent});

  @override
  NaviTabBarViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return NaviTabBarViewScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => SettingsService.naviSpringDescription;
}

                                                          
   
                   
                                                                    
                                                 
                                             
                                                             
                                               
                                    
Widget naviTabBarView({
  required List<Widget> children,
  TabController? controller,
  ScrollPhysics? physics,
}) {
  return TabBarView(
    controller: controller,
    physics: physics ?? const NaviTabBarViewScrollPhysics(),
    children: children,
  );
}
