                                            
  
                                    
  
                                 
                                                
  
                                                      
                                      
                                     
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InteractionBarService {
  static const _channel =
      MethodChannel('com.memz2345.navi.flash/interaction_bar');

  static bool get isSupported => Platform.isAndroid;

                                    
  static const refreshThrottle = Duration(milliseconds: 250);
  static DateTime? _lastRefresh;

                                      
  static Future<void> refresh({bool force = false}) async {
    if (!isSupported) return;
    final now = DateTime.now();
    if (!force &&
        _lastRefresh != null &&
        now.difference(_lastRefresh!) < refreshThrottle) {
      return;
    }
    _lastRefresh = now;
    try {
      await _channel.invokeMethod<void>('refresh');
    } on PlatformException catch (_) {
                        
    } on MissingPluginException {
                 
    }
  }

  bool _handlerInstalled = false;

                             
  void setHandlers({
    VoidCallback? onWriteComment,
    VoidCallback? onCommentsTap,
    VoidCallback? onLike,
    VoidCallback? onFavorite,
    VoidCallback? onForward,
  }) {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onWriteComment':
          onWriteComment?.call();
        case 'onCommentsTap':
          onCommentsTap?.call();
        case 'onLike':
          onLike?.call();
        case 'onFavorite':
          onFavorite?.call();
        case 'onForward':
          onForward?.call();
      }
    });
  }

                  
  Future<void> show({
    required ColorScheme colorScheme,
    required String writeLabel,
    required int commentCount,
    required int likeCount,
    required int favoriteCount,
    required int forwardCount,
    required bool liked,
    required bool favorite,
  }) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('show', <String, dynamic>{
        'writeLabel': writeLabel,
        'commentCount': commentCount,
        'likeCount': likeCount,
        'favoriteCount': favoriteCount,
        'forwardCount': forwardCount,
        'liked': liked,
        'favorite': favorite,
        'colors': <String, dynamic>{
          'primary': colorScheme.primary.toARGB32(),
          'onSurface': colorScheme.onSurface.toARGB32(),
          'surface': colorScheme.surface.toARGB32(),
          'surfaceContainer': colorScheme.surfaceContainer.toARGB32(),
          'surfaceContainerHigh': colorScheme.surfaceContainerHigh.toARGB32(),
          'onSurfaceVariant': colorScheme.onSurfaceVariant.toARGB32(),
          'outline': colorScheme.outline.toARGB32(),
          'dark': colorScheme.brightness == Brightness.dark,
        },
      });
    } on PlatformException catch (e) {
      debugPrint('⚠️ 互动底栏 show 失败: $e');
    } on MissingPluginException {
                 
    }
  }

  Future<void> hide() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('hide');
    } on PlatformException catch (e) {
      debugPrint('⚠️ 互动底栏 hide 失败: $e');
    } on MissingPluginException {
                  
    }
  }
}
