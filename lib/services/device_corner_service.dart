                                          
  
                                
  
                                                 
                                           
                                    
                 
  
              
                                                               
                                                                         
                                                             
                               
  
                                               
                         
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'settings_service.dart';

abstract final class DeviceCornerService {
  static const MethodChannel _channel = MethodChannel(
    'com.memz2345.navi.flash/device_corners',
  );

                                
  static const double kMaxAutoRadius = 64.0;

                                                 
  static double _detected = 0;

                                                 
                                             
  static String _source = 'none';

  static double get detected => _detected;

                                    
  static bool get hasDeviceValue => _detected > 0;

  static String get source => _source;

                                                       
  @visibleForTesting
  static bool debugForceSupported = false;

  static bool get _supported =>
      debugForceSupported || Platform.isAndroid || Platform.isIOS;

                                             
             
     
                            
  static Future<void> load() async {
    if (!_supported) {
      _detected = 0;
      _source = 'none';
      return;
    }
    try {
      final Map<Object?, Object?>? reply =
          await _channel.invokeMethod<Map<Object?, Object?>>('getCornerRadius');
      final num? radius = reply?['radiusDp'] as num?;
      _detected = (radius?.toDouble() ?? 0).clamp(0.0, kMaxAutoRadius);
      _source = (reply?['source'] as String?) ?? 'none';
                                                
                                                  
      debugPrint('📐 设备屏幕圆角: $_detected dp (来源 $_source)');
    } on MissingPluginException {
      _detected = 0;
      _source = 'none';
    } on PlatformException catch (e) {
      _detected = 0;
      _source = 'none';
      debugPrint('⚠️ 读取设备屏幕圆角失败: ${e.message}');
    }
  }

                  
     
                                                  
  static double resolve({required bool auto, required double manual}) {
    if (!auto || _detected <= 0) return manual;
    return _detected.clamp(0.0, kMaxAutoRadius);
  }

                    
  static double resolveFor(SettingsService settings) => resolve(
    auto: settings.iosPushTransitionCornerAuto,
    manual: settings.iosPushTransitionCornerRadius,
  );

                         
  @visibleForTesting
  static void debugSetDetected(double value, {String source = 'test'}) {
    _detected = value;
    _source = value > 0 ? source : 'none';
  }
}
