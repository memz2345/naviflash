                                               
  
                           
                                       
                                                   
                             
                                                
                                       
                                                      
                                           
                         
  
                                                        
                                              
          
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'package:naviflash/services/playback_focus.dart';
import 'package:naviflash/services/windows_power_service.dart';

class EfficiencyModeAutomation with WidgetsBindingObserver {
  EfficiencyModeAutomation._();

  static final EfficiencyModeAutomation instance = EfficiencyModeAutomation._();

                       
     
                                      
  static Duration get backgroundDelay => debugBackgroundDelay;
  static Duration debugBackgroundDelay = const Duration(minutes: 3);

                                          
  static Duration get recheckInterval => debugRecheckInterval;
  static Duration debugRecheckInterval = const Duration(seconds: 30);

  bool _started = false;
  bool _enabled = false;
  bool _backgrounded = false;

                                                
                                          
                
  bool _delayElapsed = false;

                                           
  bool _applied = false;

  Timer? _delayTimer;
  Timer? _recheckTimer;

                               
  @visibleForTesting
  static void debugReset() {
    final i = instance;
    i._delayTimer?.cancel();
    i._recheckTimer?.cancel();
    i._delayTimer = null;
    i._recheckTimer = null;
    i._started = false;
    i._enabled = false;
    i._backgrounded = false;
    i._delayElapsed = false;
    i._applied = false;
    WidgetsBinding.instance.removeObserver(i);
  }

                      
  @visibleForTesting
  static bool get debugApplied => instance._applied;

                    
  @visibleForTesting
  static bool get debugBackgrounded => instance._backgrounded;

                                  
  Future<void> start({required bool enabled}) async {
    if (!_started) {
      _started = true;
      _enabled = enabled;
                                           
                                                    
      _backgrounded = false;
      _delayElapsed = false;
      WidgetsBinding.instance.addObserver(this);
      await _apply(false, reason: 'startup');
      return;
    }
    await updateEnabled(enabled);
  }

                           
  Future<void> updateEnabled(bool enabled) async {
    _enabled = enabled;
    if (!_started) return;
                                   
    await _evaluate(reason: 'pref');
  }

                                   

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    final behind = state != AppLifecycleState.resumed;
    if (behind == _backgrounded) return;
    if (behind) {
      _enterBackground();
    } else {
      _exitBackground();
    }
  }

                                     
                          
  void _enterBackground() {
    _backgrounded = true;
    _delayElapsed = false;
    _delayTimer?.cancel();
    _recheckTimer?.cancel();
    _delayTimer = Timer(backgroundDelay, () {
      _delayElapsed = true;
      unawaited(_evaluate(reason: 'delayElapsed'));
    });
    _recheckTimer = Timer.periodic(recheckInterval, (_) => _evaluate());
  }

                           
  void _exitBackground() {
    _backgrounded = false;
    _delayElapsed = false;
    _delayTimer?.cancel();
    _delayTimer = null;
    _recheckTimer?.cancel();
    _recheckTimer = null;
    unawaited(_apply(false, reason: 'foreground'));
  }

  Future<void> _evaluate({String reason = 'recheck'}) async {
    if (!_started) return;
    final want = _enabled &&
        _backgrounded &&
        _delayElapsed &&
        !PlaybackFocus.instance.anyPlaying;
    await _apply(want, reason: reason);
  }

  Future<void> _apply(bool want, {required String reason}) async {
    if (want == _applied) return;
    _applied = want;
    if (!WindowsPowerService.isPlatformSupported) return;
    final snap = await WindowsPowerService.setEfficiencyMode(want);
    if (snap.active != want) {
                                          
                           
      _applied = !want;
      if (!WindowsPowerService.isTestOverrideActive) {
        debugPrint('⚠️ 效率模式未生效: ${snap.describe}');
      }
    }
    unawaited(_log(want, snap, reason));
  }

                                                
  Future<void> _log(
    bool want,
    WindowsPowerSnapshot snap,
    String reason,
  ) async {
    if (!Platform.isWindows) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/navi_power.log');
      await file.writeAsString(
        '${DateTime.now().toIso8601String()} '
        'mode=${want ? 'efficiency' : 'normal'} reason=$reason '
        '${snap.describe}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('⚠️ 写效率模式日志失败: $e');
    }
  }
}
