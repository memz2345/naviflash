                                         
  
                                                            
                                               
                                 
                                             
  
                                   
                                                                 
                                                    
                                                                    
                                                     
  
                                                       
                                                                     
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

class SmtcWindowsService {
  SmtcWindowsService._() {
    if (isSupported) {
      _channel.setMethodCallHandler(_handleNativeCall);
    }
  }

  static final SmtcWindowsService instance = SmtcWindowsService._();

  static const _channel = MethodChannel('com.memz2345.navi.flash/smtc');

                      
  static bool get isSupported => Platform.isWindows;

                                   
  static const seekDelta = Duration(seconds: 20);

                                                  
  void Function()? onPlay;
  void Function()? onPause;
  void Function()? onPlayPause;
  void Function()? onNext;
  void Function()? onPrevious;

                           
  void Function(Duration delta)? onSeekBy;

                                      
  bool _active = false;
  bool get isActive => _active;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onButtonPressed') {
      final args = call.arguments;
      final action = args is Map ? args['action'] as String? : null;
      _dispatch(action);
    }
    return null;
  }

  void _dispatch(String? action) {
    switch (action) {
      case 'play':
        onPlay?.call();
        break;
      case 'pause':
        onPause?.call();
        break;
      case 'playPause':
        onPlayPause?.call();
        break;
      case 'next':
        onNext?.call();
        break;
      case 'previous':
        onPrevious?.call();
        break;
      case 'rewind':
        onSeekBy?.call(-seekDelta);
        break;
      case 'fastForward':
        onSeekBy?.call(seekDelta);
        break;
    }
  }

  Future<void> _invoke(String method, [Map<String, dynamic>? args]) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod(method, args);
    } catch (_) {
                             
    }
  }

                               
  Future<void> activate({
    required String title,
    String? artist,
    String? artUri,
    required bool playing,
    required int positionMs,
    required int durationMs,
  }) async {
    _active = true;
    await _invoke('activate', {
      'title': title,
      'artist': artist ?? '',
      'artUri': artUri ?? '',
      'playing': playing,
      'positionMs': positionMs,
      'durationMs': durationMs,
    });
  }

                          
  Future<void> updateMetadata({
    required String title,
    String? artist,
    String? artUri,
  }) async {
    await _invoke('updateMetadata', {
      'title': title,
      'artist': artist ?? '',
      'artUri': artUri ?? '',
    });
  }

                                                 
  Future<void> updatePlaybackState(bool playing) async {
    await _invoke('updatePlaybackState', {'playing': playing});
  }

                                  
  Future<void> updatePosition(int positionMs, int durationMs) async {
    await _invoke('updatePosition', {
      'positionMs': positionMs,
      'durationMs': durationMs,
    });
  }

                               
  Future<void> deactivate() async {
    _active = false;
    await _invoke('deactivate');
  }
}
