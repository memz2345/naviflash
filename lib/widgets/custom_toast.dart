                                
                                                                      
                                                                    
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:naviflash/services/settings_service.dart';

                      
   
                                                 
                                                                         
                                       
                                          
                                          
                                           
   
                                                                         
                                        
class CustomToast extends StatelessWidget {
  const CustomToast(this.msg, {super.key, this.error = false});

  final String msg;

                                  
  final bool error;

                                                  
  static double get toastOpacity =>
      SettingsService.toastBgOpacityValue.clamp(0.05, 1.0);

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(20));

                        
  static const double _blurSigma = 10.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final backgroundColor =
        error ? colorScheme.errorContainer : colorScheme.primaryContainer;
    final foregroundColor =
        error ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer;
    final opacity = toastOpacity;

    if (!SettingsService.toastBgBlurEnabled) {
                                        
      return Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom + 30,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor.withValues(alpha: opacity),
          borderRadius: _radius,
        ),
        child: Text(msg, style: TextStyle(fontSize: 13, color: foregroundColor)),
      );
    }

                                            
                                                
                     
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom + 30,
      ),
      decoration: BoxDecoration(borderRadius: _radius),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: _blurSigma,
                  sigmaY: _blurSigma,
                ),
                child: _FrostedToastBackground(
                  baseColor: backgroundColor,
                  opacity: opacity,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
            child: Text(
              msg,
              style: TextStyle(fontSize: 13, color: foregroundColor),
            ),
          ),
        ],
      ),
    );
  }
}

                                       
                                                
                                
class _FrostedToastBackground extends StatelessWidget {
  final Color baseColor;
  final double opacity;

  const _FrostedToastBackground({
    required this.baseColor,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final base = baseColor.withValues(alpha: opacity);
    final lightSheen = Color.alphaBlend(Colors.white, base);
    final darkSheen = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.5),
      base,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: base,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.55),
          radius: 1.25,
          colors: [lightSheen.withValues(alpha: 0.55), base, darkSheen],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -34,
            top: -26,
            child: _Glow(color: lightSheen, strength: 0.8, size: 64),
          ),
          Positioned(
            right: -28,
            bottom: -30,
            child: _Glow(color: darkSheen, strength: 0.9, size: 62),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double strength;
  final double size;

  const _Glow({
    required this.color,
    required this.strength,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: strength),
            color.withValues(alpha: strength * 0.35),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
