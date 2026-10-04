                                          
  
                                                   
                                       
                                      
            
  
                                          
                                              
                                                          
                                                                                      
                                                           
  
                                               
                                     
                                                     
                 
  
                                                
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

             
class WindowsPowerSnapshot {
                                             
  final bool ok;

                    
  final bool queried;

                                    
  final bool active;

                                                     
                      
  final int controlMask;
  final int stateMask;

                          
  final int error;

                   
  final bool unsupported;

  const WindowsPowerSnapshot({
    this.ok = false,
    this.queried = false,
    this.active = false,
    this.controlMask = 0,
    this.stateMask = 0,
    this.error = 0,
    this.unsupported = false,
  });

  static const WindowsPowerSnapshot notSupported = WindowsPowerSnapshot(
    unsupported: true,
  );

                
  WindowsPowerSnapshot copyWith({bool? active}) => WindowsPowerSnapshot(
        ok: ok,
        queried: queried,
        active: active ?? this.active,
        controlMask: controlMask,
        stateMask: stateMask,
        error: error,
        unsupported: unsupported,
      );

  static WindowsPowerSnapshot fromMap(Map<Object?, Object?> map) =>
      WindowsPowerSnapshot(
        ok: map['ok'] == true,
        queried: map['queried'] == true,
        active: map['active'] == true,
        controlMask: (map['control'] as num?)?.toInt() ?? 0,
        stateMask: (map['state'] as num?)?.toInt() ?? 0,
        error: (map['error'] as num?)?.toInt() ?? 0,
      );

                          
  String get describe =>
      'ok=$ok queried=$queried active=$active '
      'control=0x${controlMask.toRadixString(16)} '
      'state=0x${stateMask.toRadixString(16)} err=$error';

  @override
  String toString() => 'WindowsPowerSnapshot($describe)';
}

abstract final class WindowsPowerService {
  static const MethodChannel _channel = MethodChannel(
    'com.memz2345.navi.flash/power',
  );

                                                               
                               
  @visibleForTesting
  static bool debugForceUnsupported = false;

                         
  @visibleForTesting
  static WindowsPowerSnapshot? debugSnapshotOverride;

                                    
  static bool get isTestOverrideActive => debugSnapshotOverride != null;

                     
  static WindowsPowerSnapshot? lastSnapshot;

  static bool get isPlatformSupported =>
      !kIsWeb && Platform.isWindows && !debugForceUnsupported;

                                   
  static Future<bool> isSupported() async {
    if (!isPlatformSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('⚠️ 效率模式支持检测失败: $e');
      return false;
    }
  }

                                 
  static Future<WindowsPowerSnapshot> query() async {
    final override = debugSnapshotOverride;
    if (override != null) return override;
    if (!isPlatformSupported) return WindowsPowerSnapshot.notSupported;
    try {
      final map = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getEfficiencyMode',
      );
      final snap = map == null
          ? const WindowsPowerSnapshot()
          : WindowsPowerSnapshot.fromMap(map);
      lastSnapshot = snap;
      return snap;
    } on MissingPluginException {
      return const WindowsPowerSnapshot(unsupported: true);
    } catch (e) {
      debugPrint('⚠️ 读取效率模式失败: $e');
      return const WindowsPowerSnapshot();
    }
  }

                 
  static Future<bool> isEfficiencyMode() async => (await query()).active;

                                         
                                                    
     
                                       
  static Future<WindowsPowerSnapshot> setEfficiencyMode(bool enabled) async {
    final override = debugSnapshotOverride;
    if (override != null) {
                                               
                                  
      return override.copyWith(active: enabled);
    }
    if (!isPlatformSupported) return WindowsPowerSnapshot.notSupported;
    try {
      final map = await _channel.invokeMethod<Map<Object?, Object?>>(
        'setEfficiencyMode',
        {'enabled': enabled},
      );
      final snap = map == null
          ? const WindowsPowerSnapshot()
          : WindowsPowerSnapshot.fromMap(map);
      lastSnapshot = snap;
      _syncKeeper(enabled && snap.active);
      return snap;
    } on MissingPluginException {
      return const WindowsPowerSnapshot(unsupported: true);
    } catch (e) {
      debugPrint('⚠️ 设置效率模式失败: $e');
      return const WindowsPowerSnapshot();
    }
  }

                                              
                        
                                              
    
                                      
                                                                          
                                             
                                                       
                                      
                                                        
                     
  static const Duration keeperInterval = Duration(seconds: 5);

  static Timer? _keeper;

                    
  @visibleForTesting
  static bool get debugKeeperActive => _keeper != null;

                                         
  @visibleForTesting
  static void debugStopKeeper() {
    _keeper?.cancel();
    _keeper = null;
  }

  static void _syncKeeper(bool enabled) {
    _keeper?.cancel();
    _keeper = null;
    if (!enabled || !isPlatformSupported || debugSnapshotOverride != null) {
      return;
    }
    _keeper = Timer.periodic(keeperInterval, (_) async {
                                     
                                         
      await _applyRaw(true);
    });
  }

                     
  static Future<WindowsPowerSnapshot> _applyRaw(bool enabled) async {
    if (!isPlatformSupported || debugSnapshotOverride != null) {
      return const WindowsPowerSnapshot();
    }
    try {
      final map = await _channel.invokeMethod<Map<Object?, Object?>>(
        'setEfficiencyMode',
        {'enabled': enabled},
      );
      final snap = map == null
          ? const WindowsPowerSnapshot()
          : WindowsPowerSnapshot.fromMap(map);
      lastSnapshot = snap;
      return snap;
    } catch (e) {
      debugPrint('⚠️ 效率模式守护重申失败: $e');
      return const WindowsPowerSnapshot();
    }
  }
}
