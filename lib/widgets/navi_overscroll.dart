                                   
  
                      
                                             
                                      
                                                        
                                       
                 
                                                                
  
                                                        
                                                                         
                                           
import 'package:flutter/material.dart';

import 'package:naviflash/services/settings_service.dart';

                                   
bool naviOverscrollDisabled(BuildContext context) {
  final platform = Theme.of(context).platform;
  return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
}

                                 
bool naviUseGlowOverscroll() => SettingsService.videoCardGlassEnabled;

              
Widget buildNaviOverscrollIndicator(
  BuildContext context,
  Widget child,
  ScrollableDetails details,
) {
  if (naviOverscrollDisabled(context)) return child;
  if (naviUseGlowOverscroll()) {
                                     
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: Theme.of(context).colorScheme.primary,
      child: child,
    );
  }
  return StretchingOverscrollIndicator(
    axisDirection: details.direction,
    child: child,
  );
}
