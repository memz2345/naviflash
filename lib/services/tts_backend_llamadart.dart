                                          
  
                                   
  
                                                           
                                                             
                                             
                            
  
                                                        
                                                    
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:llamadart/llamadart.dart' as llama;
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/services/tts_backend_policy.dart';
import 'package:naviflash/services/tts_engine.dart';
import 'package:naviflash/services/tts_native_log.dart';
import 'package:path/path.dart' as p;

                                           
class LlamadartTtsBackend implements TtsInferenceBackend {
  llama.LlamaEngine? _engine;
  llama.TextToSpeechEngine? _tts;

                                          
                                               
  ResolvedTtsDevice? activeDevice;

                                          
  static const String modelFileName =
      'Qwen3-TTS-12Hz-1.7B-Base-Q4_K_M.gguf';

                                     
  static const String projectorFileName =
      'mmproj-Qwen3-TTS-12Hz-1.7B-Base-Q8_0.gguf';

  @override
  Future<void> load(String modelDir) async {
    await dispose();

                                                
                                        
    TtsNativeLog.install();

                                    
                                              
    var resolved = await TtsBackendPolicy.resolve(
      SettingsService.ttsInferenceDeviceStatic,
    );

    Object? npuLoadError;
    try {
      await _loadOnce(modelDir, resolved);
    } catch (e) {
                                             
                                                        
                                              
                                 
      final usedHexagon =
          resolved.gpuBackend == llama.GpuBackend.hexagon;
      if (!usedHexagon) rethrow;
      npuLoadError = e;
      debugPrint('[TtsBackend] NPU 加载失败，回退 CPU 重试：$e');
      await dispose();
      resolved = ResolvedTtsDevice.cpuFallbackFrom(resolved);
      await _loadOnce(modelDir, resolved);
    }

    activeDevice = resolved;
    final caps = await _tts!.capabilities;
    final fallbackNote = resolved.fellBackFromNpu
        ? '（期望 NPU 不可用，已回退 '
            '${resolved.effective == TtsInferenceDevicePreference.gpu ? 'GPU' : 'CPU'}：'
            '${resolved.fallbackReason?.name}'
            '${npuLoadError != null ? '，NPU 报错：$npuLoadError' : ''}）'
        : '';
    debugPrint('[TtsBackend] 就绪：${caps.backendName} @ ${caps.sampleRateHz}Hz'
        ' · 克隆=${caps.supportsSpeakerReference} · '
        '偏好=${resolved.preference.name} 实际=${resolved.effective.name}'
        '$fallbackNote');
  }

                                                  
  Future<void> _loadOnce(String modelDir, ResolvedTtsDevice resolved) async {
    final engine = llama.LlamaEngine(llama.LlamaBackend());
                                                      
                                                      
    TtsNativeLog.rearm();
    try {
      await engine.loadModelSource(
        llama.ModelSource.path(p.join(modelDir, modelFileName)),
        modelParams: llama.ModelParams(
          preferredBackend: resolved.gpuBackend,
          gpuLayers: resolved.gpuLayers,
        ),
      );
      await engine.loadMultimodalProjectorSource(
        llama.ModelSource.path(p.join(modelDir, projectorFileName)),
      );

      final tts = llama.TextToSpeechEngine(
        engine,
        modelProfile: llama.TextToSpeechModelProfile.qwen3Tts,
      );
                                                    
      final caps = await tts.capabilities;
      if (!caps.isSupported) {
        throw TtsEngineException(
            caps.unsupportedReason ?? '当前运行时不支持 Qwen3-TTS 合成');
      }

      _engine = engine;
      _tts = tts;
    } catch (e) {
      await engine.dispose().catchError((_) {});
      if (e is TtsEngineException) rethrow;
      throw TtsEngineException('加载朗读引擎失败：$e');
    }
  }

  @override
  Future<TtsResult> synthesize(TtsRequest request) async {
    final tts = _tts;
    if (tts == null) {
      throw TtsEngineException('引擎未加载');
    }

    final task = await tts.synthesize(
      llama.TextToSpeechRequest(
        text: request.text,
        language: request.language,
        speakerReference: request.voicePath == null
            ? null
            : llama.SpeechAudioFileInput(request.voicePath!),
      ),
    );

    llama.TextToSpeechResult? result;
    await for (final event in task.events) {
      if (event is llama.TextToSpeechFinalEvent) {
        result = event.result;
        break;
      }
    }
    final done = result;
    if (done == null) {
      throw TtsEngineException('合成未返回结果');
    }
    return TtsResult(done.samples, done.sampleRateHz);
  }

  @override
  Future<void> dispose() async {
    final engine = _engine;
    _engine = null;
    _tts = null;
    activeDevice = null;
    if (engine != null) {
      await engine.dispose().catchError((_) {});
    }
  }
}
