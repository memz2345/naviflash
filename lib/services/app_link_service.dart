                                     
  
                                     
  
                                                                
                                                        
                                   
                                                        
  
                                            
                                                            
  
                                                
import 'dart:io';

import 'package:flutter/services.dart';

abstract final class AppLinkService {
  static const MethodChannel _channel = MethodChannel(
    'com.memz2345.navi.flash/app_links',
  );

                                     
  static const List<String> supportedHosts = <String>[
    'bilibili.com',
    'b23.tv',
    'memz2345.top',
  ];

  static bool get isSupported => Platform.isAndroid;

                           
     
                                               
                  
  static Future<bool> openLinkVerifySettings() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('openLinkVerifySettings') ?? false;
    } catch (_) {
      return false;
    }
  }
}
