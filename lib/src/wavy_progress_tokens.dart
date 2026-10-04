                                                                    
  
                              
                                                                                   
                                               
                                                 
                              
                            
                                
                                               
                                                 
                                                  

import 'dart:math' as math;

import 'package:flutter/material.dart';

                                                                        
   
                                                                       
class WavyProgressTokens {
  const WavyProgressTokens._();

                                                                                
                                  
                                                                                

                                              
  static const double linearActiveThickness = 4.0;

                                  
  static const double linearTrackThickness = 4.0;

                                                     
  static const double linearTrackActiveSpace = 4.0;

                                                                  
  static const double linearStopSize = 4.0;

                                                   
  static const double linearDeterminateWavelength = 40.0;

                                                      
  static const double linearIndeterminateWavelength = 20.0;

                                                                                
  static const double linearContainerHeight = 10.0;

                                                                              
  static const double linearContainerWidth = 240.0;

                                                                                
                                    
                                                                                

                                              
  static const double circularActiveThickness = 4.0;

                                  
  static const double circularTrackThickness = 4.0;

                                                     
  static const double circularTrackActiveSpace = 4.0;

                                                                    
  static const double circularWavelength = 15.0;

                                                  
  static const double circularContainerSize = 48.0;

                                                             
  static const double circularSize = 40.0;

                                                                     
  static const int minCircularVertexCount = 5;

                                                                                
                                   
                                                                                

                                                                   
  static const int amplitudeAnimationDuration = 500;

                                                                               
  static const int minAnimationDuration = 50;

                                           
  static const Cubic easingLinear = Cubic(0.0, 0.0, 1.0, 1.0);

                                             
  static const Cubic easingStandard = Cubic(0.2, 0.0, 0.0, 1.0);

                                                         
  static const Cubic easingEmphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

                                                         
  static const Cubic easingEmphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

                                                                              
                                                                              
  static const Cubic easingKeyframeDefault = Cubic(0.4, 0.0, 0.2, 1.0);

                                                                                
                                                    
                                                                                

                                                       
  static const int linearAnimationDuration = 1750;

  static const int firstLineHeadDelay = 0;
  static const int firstLineHeadDuration = 1000;
  static const int firstLineTailDelay = 250;
  static const int firstLineTailDuration = 1000;
  static const int secondLineHeadDelay = 650;
  static const int secondLineHeadDuration = 850;
  static const int secondLineTailDelay = 900;
  static const int secondLineTailDuration = 850;

                                                                                
                                                      
                                                                                

                                                      
  static const int circularAnimationProgressDuration = 6000;

                                                
  static const int circularAdditionalRotationDuration = 300;

                                                      
  static const int circularAdditionalRotationDelay = 1500;

  static const double circularIndeterminateMinProgress = 0.1;
  static const double circularIndeterminateMaxProgress = 0.87;
  static const double circularAdditionalRotationDegreesTarget = 360.0;
  static const double circularGlobalRotationDegreesTarget = 1080.0;

                                                                                
             
                                                                                

                                                       
     
                                                                          
                                                                           
  static double defaultAmplitude(double progress) =>
      (progress <= 0.1 || progress >= 0.95) ? 0.0 : 1.0;

                                                                                
                                       
                                                                                

                                                               
     
                                                                                 
                                                                                
                                                                     
  static double linearIndeterminateFraction(
    double t,
    int delayMs,
    int durationMs,
  ) {
    final double ms = t * linearAnimationDuration;
    if (ms <= delayMs) return 0.0;
    final int end = delayMs + durationMs;
    if (ms >= end) return 1.0;
    return easingEmphasizedAccelerate.transform((ms - delayMs) / durationMs);
  }

                                                                          
                                     
  static double circularGlobalRotation(double t) =>
      t * circularGlobalRotationDegreesTarget;

                                                              
     
                                                                                
                                                                         
                                       
     
                                                                                
                                                                          
                                       
  static double circularAdditionalRotation(double t) {
    final double ms = t * circularAnimationProgressDuration;
    for (int i = 0; i < 4; i++) {
      final double jumpStart =
          i * circularAdditionalRotationDelay.toDouble();
      final double jumpEnd = jumpStart + circularAdditionalRotationDuration;
      if (ms < jumpEnd) {
        final double local =
            ((ms - jumpStart) / circularAdditionalRotationDuration).clamp(0.0, 1.0);
        return (i * 90.0) + 90.0 * easingKeyframeDefault.transform(local);
      }
    }
    return circularAdditionalRotationDegreesTarget;
  }

                                                                              
     
                                                                        
                                                                           
                                                                                 
                                                                          
  static int circularVertexCount({
    required double size,
    required double strokeWidth,
    required double wavelength,
  }) {
    final double radius = size / 2.0 - strokeWidth / 2.0;
    return math.max(
      minCircularVertexCount,
      (2 * math.pi * radius / wavelength).round(),
    );
  }

                                                                              
                                                                   
  static double circularSweep(double t) {
    final double ms = t * circularAnimationProgressDuration;
    final double half = circularAnimationProgressDuration / 2.0;
    if (ms < half) {
      return circularIndeterminateMinProgress +
          (circularIndeterminateMaxProgress - circularIndeterminateMinProgress) *
              easingKeyframeDefault.transform((ms / half).clamp(0.0, 1.0));
    }
    return circularIndeterminateMaxProgress -
        (circularIndeterminateMaxProgress - circularIndeterminateMinProgress) *
            easingStandard.transform(((ms - half) / half).clamp(0.0, 1.0));
  }
}
