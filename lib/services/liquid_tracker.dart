import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

                              
class LiquidTracker {
  final AnimationController _scaleXCtrl;
  final AnimationController _scaleYCtrl;
  final AnimationController _rotXCtrl;
  final AnimationController _rotYCtrl;

                         
  late final Animation<double> scaleX;
  late final Animation<double> scaleY;
  late final Animation<double> rotX;
  late final Animation<double> rotY;

  final SpringDescription _spring = const SpringDescription(
    mass: 1,
    stiffness: 180,
                                                   
                                
    damping: 15.27,                       
  );

  final SpringDescription _rotSpring = const SpringDescription(
    mass: 1,
    stiffness: 180,
    damping: 21.21,                      
  );

  LiquidTracker(TickerProvider vsync)
      : _scaleXCtrl = AnimationController(vsync: vsync),
        _scaleYCtrl = AnimationController(vsync: vsync),
        _rotXCtrl = AnimationController(vsync: vsync),
        _rotYCtrl = AnimationController(vsync: vsync) {
                               
    scaleX = _scaleXCtrl;
    scaleY = _scaleYCtrl;
    rotX = _rotXCtrl;
    rotY = _rotYCtrl;

                   
    _scaleXCtrl.value = 1.0;
    _scaleYCtrl.value = 1.0;
    _rotXCtrl.value = 0.0;
    _rotYCtrl.value = 0.0;
  }

  void dispose() {
    _scaleXCtrl.dispose();
    _scaleYCtrl.dispose();
    _rotXCtrl.dispose();
    _rotYCtrl.dispose();
  }

                          
                                                                               
  void applyPanUpdate(Offset delta) {
                                
    final scaleTargets = _getLiquidScale(delta.dx, delta.dy);
    _animateScaleTo(scaleTargets.dx, scaleTargets.dy);
  }

                          
  void resetToRest() {
    _animateScaleTo(1.0, 1.0);
    animateTilt(0.0, 0.0);
  }

                        
  void animateScale(double scale) {
    _animateScaleTo(scale, scale);
  }

                           
  void animateTilt(double rotXValue, double rotYValue) {
    _rotXCtrl.animateWith(
      SpringSimulation(_rotSpring, _rotXCtrl.value, rotXValue, 0),
    );
    _rotYCtrl.animateWith(
      SpringSimulation(_rotSpring, _rotYCtrl.value, rotYValue, 0),
    );
  }

  void _animateScaleTo(double sx, double sy) {
    _scaleXCtrl.animateWith(
      SpringSimulation(_spring, _scaleXCtrl.value, sx, 0),
    );
    _scaleYCtrl.animateWith(
      SpringSimulation(_spring, _scaleYCtrl.value, sy, 0),
    );
  }

                            
  Offset _getLiquidScale(double dx, double dy) {
    final absDx = dx.abs();
    final absDy = dy.abs();
    const factor = 0.5;        

    double scaleX, scaleY;
    if (absDx > absDy) {
                         
      scaleX = 1.0 + absDx * factor;
      scaleY = 1.0 - absDx * factor * 0.5;
    } else {
                         
      scaleX = 1.0 - absDy * factor * 0.5;
      scaleY = 1.0 + absDy * factor;
    }

    return Offset(
      clampDouble(scaleX, 0.6, 1.4),
      clampDouble(scaleY, 0.6, 1.4),
    );
  }
}