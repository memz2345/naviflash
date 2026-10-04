                                   
  
                                        
                                                 
  
                                                        
                                                          
                                                   
             
                                        
                                          
                                                     
                            
  
      
          
               
                
                                                      
                             
       
     
      
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:provider/provider.dart';

class PageBackground extends StatelessWidget {
                                                
                                                   
             
  final Color? baseColor;

                                     
                                                       
                        
  final bool contentStyle;

  const PageBackground({super.key, this.baseColor, this.contentStyle = false});

  @override
  Widget build(BuildContext context) {
    final image = _imageLayer(context);
    if (baseColor == null) return image ?? const SizedBox.shrink();
                                              
                                          
                           
    return ColoredBox(
      color: baseColor!,
      child: Stack(fit: StackFit.expand, children: [if (image != null) image]),
    );
  }

                           
     
                                          
                                              
  Widget? _imageLayer(BuildContext context) {
                                                          
                                    
    SettingsService settings;
    try {
      settings = Provider.of<SettingsService>(context);
    } on ProviderNotFoundException {
      return null;
    }
                                           
    final path = contentStyle
        ? settings.contentPageBackgroundPath
        : settings.pageBackgroundPath;
    final enabled = contentStyle
        ? settings.contentPageBackgroundEnabled
        : settings.pageBackgroundEnabled;
    if (!enabled || path == null || path.isEmpty || !File(path).existsSync()) {
      return null;
    }
    final opacity = contentStyle
        ? settings.contentPageBackgroundOpacity.clamp(0.0, 1.0)
        : settings.pageBackgroundOpacity.clamp(0.0, 1.0);
    final blur = contentStyle
        ? settings.contentPageBackgroundBlur.clamp(0.0, 24.0)
        : settings.pageBackgroundBlur.clamp(0.0, 24.0);

                                                 
                                                   
    final mq = MediaQuery.maybeOf(context);
    final int decodeCap = mq == null
        ? 2560
        : (mq.size.longestSide * mq.devicePixelRatio).round().clamp(720, 2560);

                                
    return Opacity(
      opacity: opacity,
      child: blur > 0.5
          ? ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: _image(path, decodeCap),
            )
          : _image(path, decodeCap),
    );
  }

  Widget _image(String path, int cacheWidth) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
