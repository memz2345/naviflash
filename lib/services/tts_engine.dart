                               
  
                       
  
        
                                          
                                                           
                                 
                                            
                                            
                                        
                                                  
                    
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/tts_backend_llamadart.dart';
import 'package:naviflash/services/tts_backend_policy.dart';
import 'package:naviflash/services/tts_live_update.dart';
import 'package:naviflash/services/tts_model_service.dart';

         
enum TtsEngineStatus {
                        
  idle,

         
  loading,

        
  ready,

          
  error,
}

           
class TtsRequest {
             
  final String text;

                                   
  final String? voicePath;

                                 
  final String? voiceTranscript;

                                                                        
  final String language;

                 
  final double speed;

  const TtsRequest({
    required this.text,
    this.voicePath,
    this.voiceTranscript,
    this.language = 'zh',
    this.speed = 1.0,
  });
}

                   
class TtsResult {
  final Float32List samples;

                            
  final int sampleRate;

  const TtsResult(this.samples, this.sampleRate);

  Duration get duration => Duration(
      microseconds: (samples.length / sampleRate * 1000000).round());
}

class TtsEngineException implements Exception {
  final String message;
  TtsEngineException(this.message);

  @override
  String toString() => message;
}

                  
   
                                                   
                                       
abstract class TtsInferenceBackend {
                                  
  Future<void> load(String modelDir);

             
  Future<TtsResult> synthesize(TtsRequest request);

                 
  Future<void> dispose();
}

                   
   
                                  
                                                        
class PendingTtsBackend implements TtsInferenceBackend {
  String? _modelDir;

  @override
  Future<void> load(String modelDir) async {
    _modelDir = modelDir;
  }

  @override
  Future<TtsResult> synthesize(TtsRequest request) async {
    throw TtsEngineException(
      '推理运行时尚未接入（模型目录：${_modelDir ?? "未加载"}）',
    );
  }

  @override
  Future<void> dispose() async {
    _modelDir = null;
  }
}

                      
abstract class TtsEngine {
  TtsInferenceBackend get backend;

  Future<void> load();

  Future<TtsResult> synthesize(TtsRequest request);

  Future<void> unload();
}

                                                            
             
class Qwen3TtsEngine implements TtsEngine {
  Qwen3TtsEngine({TtsInferenceBackend? backend})
      : backend = backend ?? LlamadartTtsBackend();

  @override
  final TtsInferenceBackend backend;

  bool _loaded = false;

  @override
  Future<void> load() async {
    final dir = await TtsModelService.readyModelDir();
    if (dir == null) {
      throw TtsEngineException('模型未下载或下载不完整');
    }
    await backend.load(dir);
    _loaded = true;
  }

  @override
  Future<TtsResult> synthesize(TtsRequest request) async {
    if (!_loaded) {
      await load();
    }
    return backend.synthesize(request);
  }

  @override
  Future<void> unload() async {
    await backend.dispose();
    _loaded = false;
  }
}

              
   
                                    
                                      
class TtsEngineManager extends ChangeNotifier {
  TtsEngineManager._();

  static final TtsEngineManager instance = TtsEngineManager._();

                                         
  Duration idleTimeout = const Duration(minutes: 5);

  TtsEngineStatus _status = TtsEngineStatus.idle;
  String? _errorMessage;
  TtsEngine? _engine;

                                                
  TtsInferenceBackend? _backendOverride;
  Future<void>? _loadFuture;
  Timer? _idleTimer;

  TtsEngineStatus get status => _status;

  String? get errorMessage => _errorMessage;

  bool get isReady => _status == TtsEngineStatus.ready;

  bool get isLoading => _status == TtsEngineStatus.loading;

                                               
                                
  ResolvedTtsDevice? get activeDevice {
    final backend = _engine?.backend;
    return backend is LlamadartTtsBackend ? backend.activeDevice : null;
  }

                             
                                      
  void registerBackend(TtsInferenceBackend? backend) {
    _backendOverride = backend;
    final wasLoaded = _status == TtsEngineStatus.ready;
    final old = _engine;
    _engine = null;
    _loadFuture = null;
    if (old != null) {
      unawaited(old.unload().catchError((_) {}));
    }
    _setStatus(TtsEngineStatus.idle);
    if (wasLoaded) {
      unawaited(ensureLoaded().catchError((_) {}));
    }
  }

                                          
  Future<void> ensureLoaded() {
    if (_status == TtsEngineStatus.ready && _engine != null) {
      _pokeIdleTimer();
      return Future<void>.value();
    }
    final pending = _loadFuture;
    if (pending != null) return pending;

                                     
    _pauseIdleTimer();
    _setStatus(TtsEngineStatus.loading);
    final future = _doLoad();
    _loadFuture = future;
    return future;
  }

  Future<void> _doLoad() async {
    try {
                                           
      final engine = _engine ??= Qwen3TtsEngine(
        backend: _backendOverride ?? LlamadartTtsBackend(),
      );
      await engine.load();
      _errorMessage = null;
      _setStatus(TtsEngineStatus.ready);
      _pokeIdleTimer();
    } catch (e) {
      _errorMessage = e is TtsEngineException ? e.message : '$e';
      _setStatus(TtsEngineStatus.error);
                                  
      final broken = _engine;
      _engine = null;
      if (broken != null) {
        unawaited(broken.unload().catchError((_) {}));
      }
      rethrow;
    } finally {
      _loadFuture = null;
    }
  }

                        
     
                                          
                                        
  Future<TtsResult> speak(
    String text, {
    String? voicePath,
    String? voiceTranscript,
    String language = 'zh',
    double speed = 1.0,
  }) async {
    _pauseIdleTimer();
                                           
                                                    
    await TtsLiveUpdate.synthesizeStart(text);
    try {
      await ensureLoaded();
      await TtsLiveUpdate.synthesizing(text);
      final engine = _engine;
      if (engine == null) {
        throw TtsEngineException('引擎未就绪');
      }
      final result = await engine.synthesize(
        TtsRequest(
          text: text,
          voicePath: voicePath,
          voiceTranscript: voiceTranscript,
          language: language,
          speed: speed,
        ),
      );
      await TtsLiveUpdate.synthesizeDone(result.duration);
      return result;
    } catch (e) {
      await TtsLiveUpdate.synthesizeFail(e);
      rethrow;
    } finally {
                       
      _pokeIdleTimer();
    }
  }

                          
  Future<void> release() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    final engine = _engine;
    _engine = null;
    _loadFuture = null;
    if (engine != null) {
      await engine.unload();
    }
    _setStatus(TtsEngineStatus.idle);
  }

                                     
                              
  void _pauseIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  void _pokeIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
    if (idleTimeout <= Duration.zero) return;
    _idleTimer = Timer(idleTimeout, () {
      if (_status == TtsEngineStatus.ready) {
        unawaited(release());
      }
    });
  }

  void _setStatus(TtsEngineStatus s) {
    if (_status == s) return;
    _status = s;
    notifyListeners();
  }
}
