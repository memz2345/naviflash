                                        
  
                                                           
                                        
                                          
                                    
                                                  
                                                            
  
                                      
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

class SleepTimerService extends ChangeNotifier {
  static final SleepTimerService instance = SleepTimerService._();
  SleepTimerService._();

                                    
  @visibleForTesting
  SleepTimerService.test();

                                  
  final Map<Object, VoidCallback> _pauseTargets = {};

                          
  Timer? _uiTick;

                           
  Timer? _fireTimer;
  DateTime? _deadline;

  bool _stopAfterCurrentArmed = false;
  bool _disposed = false;

                                                
  bool exitAppOnEnd = false;

               
  bool get isCountdownActive => _deadline != null;

                     
  bool get stopAfterCurrentArmed => _stopAfterCurrentArmed;

              
  bool get isActive => _deadline != null || _stopAfterCurrentArmed;

                                           
  Duration get remaining {
    final d = _deadline;
    if (d == null) return Duration.zero;
    final r = d.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

                              
  static String formatRemaining(Duration r) {
    final h = r.inHours;
    final m = r.inMinutes % 60;
    final s = r.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

                              
  void bindPauseTarget(Object owner, VoidCallback pause) {
    _pauseTargets[owner] = pause;
  }

                                   
  void unbindPauseTarget(Object owner) {
    _pauseTargets.remove(owner);
  }

                 
  void startCountdown(Duration duration) {
    if (_disposed || duration <= Duration.zero) return;
    _stopAfterCurrentArmed = false;
    _deadline = DateTime.now().add(duration);
    _fireTimer?.cancel();
    _fireTimer = Timer(duration, _fire);
    _uiTick ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (_deadline != null) notifyListeners();
    });
    notifyListeners();
  }

                             
  void armStopAfterCurrent() {
    if (_disposed) return;
    _stopAfterCurrentArmed = true;
    _deadline = null;
    _cancelTimers();
    notifyListeners();
  }

             
  void cancel() {
    if (_deadline == null && !_stopAfterCurrentArmed) return;
    _deadline = null;
    _stopAfterCurrentArmed = false;
    _cancelTimers();
    notifyListeners();
  }

                                    
                                              
  bool consumeStopAfterCurrent() {
    if (!_stopAfterCurrentArmed) return false;
    _stopAfterCurrentArmed = false;
    _pauseAll();
    notifyListeners();
    return true;
  }

  void _cancelTimers() {
    _fireTimer?.cancel();
    _fireTimer = null;
    _uiTick?.cancel();
    _uiTick = null;
  }

  void _pauseAll() {
    for (final pause in List<VoidCallback>.of(_pauseTargets.values)) {
      try {
        pause();
      } catch (_) {}
    }
  }

  Future<void> _fire() async {
    if (_disposed) return;
    _deadline = null;
    _cancelTimers();
    _pauseAll();
    notifyListeners();
    if (exitAppOnEnd &&
        !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        await windowManager.destroy();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimers();
    _pauseTargets.clear();
    super.dispose();
  }
}
