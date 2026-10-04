                                             
  
                     
  
                                                 
                                                          
                                            
                                                                           
  
      
                                                                            
                                                           
                                       
  
                                             
  
                                           
                                                      
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

            
class LiquidGlassBarTab {
  final String id;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;

  const LiquidGlassBarTab({
    required this.id,
    required this.label,
    required this.icon,
    this.selectedIcon,
  });
}

                                 
   
                                                     
                         
final RouteObserver<ModalRoute<void>> liquidGlassBarRouteObserver =
    RouteObserver<ModalRoute<void>>();

class LiquidGlassBarService {
  LiquidGlassBarService._();

  static const MethodChannel _channel = MethodChannel(
    'com.memz2345.navi.flash/liquid_bar',
  );

                                    
  static bool enabled = true;

                                                 
     
                                                              
                                                    
                                      
  static const double barHeight = 64;

                        
     
                                                          
                                       
                                          
  static const double bottomGap = 12;

                                     
  static double slotHeight(BuildContext context) =>
      barHeight + bottomGap + MediaQuery.paddingOf(context).bottom;

                         
     
                                                    
                                                  
                                                   
                                
                                                             
                                    
  static final List<void Function(int index)> _tabSelectedStack =
      <void Function(int index)>[];

                    
  static void Function(int index)? get onTabSelected =>
      _tabSelectedStack.isEmpty ? null : _tabSelectedStack.last;

                                             
  static bool get hasTabSelectedOwner => _tabSelectedStack.isNotEmpty;

                        
  static void bindTabSelected(void Function(int index) callback) {
    _tabSelectedStack.remove(callback);
    _tabSelectedStack.add(callback);
  }

                      
  static void unbindTabSelected(void Function(int index) callback) {
    _tabSelectedStack.remove(callback);
  }

                                  
                                    
  @visibleForTesting
  static void debugReset() {
    _tabSelectedStack.clear();
    _visibleOwner = null;
    enabled = true;
    debugForceNative = false;
    _lastRefresh = null;
    _pendingScrollDelta = 0;
  }

                
     
                                              
                                       
                                                   
                                               
  static const Duration refreshThrottle = Duration(milliseconds: 80);

                              
     
                                               
                        
  static double _pendingScrollDelta = 0;

  static bool _handlerInstalled = false;
  static DateTime? _lastRefresh;

                                   
  static bool get _platformSupported => debugForceNative || Platform.isAndroid;

                
  static bool get canUseNative => enabled && _platformSupported;

                                                                
                    
  @visibleForTesting
  static bool debugForceNative = false;

                                           
     
                                       
                                                      
                                                
                                      
     
                                                 
                
  static bool ownsVisibleBar(void Function(int index) callback) =>
      _visibleOwner == callback;

                       
  static void Function(int index)? _visibleOwner;

  static void _ensureHandler() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler(_handleCall);
  }

                                         
  static Future<bool> show({
    required BuildContext context,
    required List<LiquidGlassBarTab> tabs,
    required int index,
    double height = barHeight,
    Color? accent,
  }) async {
    if (!canUseNative || tabs.isEmpty) return false;
    _ensureHandler();
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    try {
      final ok = await _channel.invokeMethod<bool>('showBar', {
        'tabs': [
          for (final t in tabs)
            {
              'id': t.id,
              'label': t.label,
              'iconCodePoint': t.icon.codePoint,
              'iconFontFamily': t.icon.fontFamily,
              'selectedIconCodePoint': t.selectedIcon?.codePoint,
            },
        ],
        'index': index,
        'height': height,
        'bottomInset': bottomInset,
        'dark': Theme.of(context).brightness == Brightness.dark,
        'accent': accent?.toARGB32(),
      });
                                            
      if (ok == true) _visibleOwner = onTabSelected;
      return ok == true;
    } catch (_) {
      return false;
    }
  }

                        
  static Future<void> updateIndex(int index) async {
    if (!canUseNative) return;
    try {
      await _channel.invokeMethod<void>('updateIndex', {'index': index});
    } catch (_) {}
  }

                                     
     
                                                 
                                                                  
                                             
                                        
                          
  static Future<void> refresh({bool force = false, double scrollDelta = 0}) async {
    if (!canUseNative) return;
    _pendingScrollDelta += scrollDelta;
    final now = DateTime.now();
    if (!force &&
        _lastRefresh != null &&
        now.difference(_lastRefresh!) < refreshThrottle) {
      return;
    }
    _lastRefresh = now;
    final delta = _pendingScrollDelta;
    _pendingScrollDelta = 0;
    try {
      await _channel.invokeMethod<void>('refresh', {'scrollDelta': delta});
    } catch (_) {}
  }

                                
     
                                                  
                                                    
                            
  static Future<void> hide() async {
    _visibleOwner = null;
    if (!_platformSupported) return;
    try {
      await _channel.invokeMethod<void>('hideBar');
    } catch (_) {}
  }

  static Future<dynamic> _handleCall(MethodCall call) async {
    if (call.method == 'onTabSelected') {
      final args = call.arguments;
      final index = args is Map ? (args['index'] as num?)?.toInt() : null;
      if (index != null) onTabSelected?.call(index);
    }
    return null;
  }
}
