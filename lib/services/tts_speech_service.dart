                                       
  
                                                     
                                                
  
                                                 
                                  
  
                                   
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:naviflash/services/tts_audio_cache_service.dart';
import 'package:naviflash/services/tts_engine.dart';
import 'package:naviflash/services/tts_model_service.dart';
import 'package:naviflash/services/tts_voice_service.dart';

         
enum TtsSpeechStatus {
        
  idle,

                               
  preparing,

                 
  synthesizing,

         
  playing,
}

class TtsSpeechService extends ChangeNotifier {
  TtsSpeechService._();

  static final TtsSpeechService instance = TtsSpeechService._();

  TtsSpeechStatus _status = TtsSpeechStatus.idle;

                                                 
  String? _activeId;

  Player? _player;
  StreamSubscription<bool>? _completedSub;

                                         
  TtsSpeechInfo? lastInfo;

                                                 
                                             
  String? lastWavPath;

  TtsSpeechStatus get status => _status;

  String? get activeId => _activeId;

  bool get isIdle => _status == TtsSpeechStatus.idle;

  bool isActive(String id) => _activeId == id && !isIdle;

             
     
                                    
                                                               
  Future<void> speak(
    String id,
    String text, {
    String? voicePath,
    String language = 'zh',
  }) async {
    if (_activeId == id && !isIdle) {
      await stop();
      return;
    }
                                       
                                                     
    final cleaned = stripEmoticonTags(text.trim());
    if (cleaned.isEmpty) return;

                                              
    final effectiveVoice =
        voicePath ?? await TtsVoiceService.selectedVoicePath();

    await stop();
    _activeId = id;
    _setStatus(TtsSpeechStatus.preparing);

    try {
      final sw = Stopwatch()..start();
      File wavFile;
      bool fromCache;
      int audioMillis;

                                             
                                 
      final cached = await TtsAudioCacheService.lookup(
        cleaned,
        voicePath: effectiveVoice,
        language: language,
      );
      if (cached != null) {
        wavFile = cached;
        fromCache = true;
        audioMillis = await _readWavDurationMillis(cached);
        debugPrint('[TtsSpeech] $id 缓存命中，直接播放 ${cached.path}');
      } else {
                              
        final state = await TtsModelService.state();
        if (state != TtsModelState.installed) {
          throw TtsModelException('模型未下载或下载不完整');
        }

        debugPrint('[TtsSpeech] $id 开始合成 ${cleaned.length} 字'
            '${effectiveVoice == null ? "（默认音色）" : "（克隆音色）"}');
        _setStatus(TtsSpeechStatus.synthesizing);
        final result = await TtsEngineManager.instance.speak(
          cleaned,
          voicePath: effectiveVoice,
          language: language,
        );
        if (_activeId != id) {
          debugPrint('[TtsSpeech] $id 合成完成但已被取消');
          return;
        }
        debugPrint(
            '[TtsSpeech] $id 合成完成：${result.samples.length} 采样 '
            '/ ${result.sampleRate}Hz / ${result.duration.inSeconds}s');

        final wav = _encodeWav(result.samples, result.sampleRate);
                                   
        wavFile = await TtsAudioCacheService.store(
          cleaned,
          wav,
          voicePath: effectiveVoice,
          language: language,
        );
        fromCache = false;
        audioMillis = result.duration.inMilliseconds;
      }
      sw.stop();

      lastWavPath = wavFile.path;
      lastInfo = TtsSpeechInfo(
        charCount: cleaned.length,
        synthElapsed: sw.elapsed,
        audioDuration: Duration(milliseconds: audioMillis),
        fromCache: fromCache,
        at: DateTime.now(),
      );

      final player = _player ??= Player();
      _completedSub?.cancel();
      _completedSub = player.stream.completed.listen((done) {
        if (done) _resetToIdle(id);
      });
                                                      
                         
      await player
          .open(Media(Uri.file(wavFile.path).toString()), play: true);
      _setStatus(TtsSpeechStatus.playing);
      debugPrint('[TtsSpeech] $id 开始播放（${wavFile.lengthSync()} 字节，'
          '耗时 ${sw.elapsed.inMilliseconds}ms，缓存=$fromCache）');
    } catch (e) {
      _activeId = null;
      _setStatus(TtsSpeechStatus.idle);
      rethrow;
    }
  }

             
  Future<void> stop() async {
    _activeId = null;
    if (_status != TtsSpeechStatus.idle) {
      _setStatus(TtsSpeechStatus.idle);
    }
    final player = _player;
    if (player != null) {
      await player.stop().catchError((_) {});
    }
                                          
  }

  void _resetToIdle(String id) {
    if (_activeId != id) return;
    _activeId = null;
    _setStatus(TtsSpeechStatus.idle);
  }

  void _setStatus(TtsSpeechStatus s) {
    if (_status == s) return;
    _status = s;
    notifyListeners();
  }

                        
  Future<void> disposePlayer() async {
    _completedSub?.cancel();
    _completedSub = null;
    final player = _player;
    _player = null;
    if (player != null) {
      await player.dispose().catchError((_) {});
    }
  }

                                                    
                        
  Future<int> _readWavDurationMillis(File file) async {
    try {
      final raf = await file.open();
      final header = await raf.read(44);
      await raf.close();
      if (header.length < 44) return 0;
      final bd = ByteData.sublistView(Uint8List.fromList(header));
      final sampleRate = bd.getUint32(24, Endian.little);
      final dataSize = bd.getUint32(40, Endian.little);
      if (sampleRate == 0) return 0;
      return (dataSize / 2 / sampleRate * 1000).round();
    } catch (_) {
      return 0;
    }
  }

                           
     
                                
                                    
  static String stripEmoticonTags(String text) =>
      text.replaceAll(RegExp(r'\[[^\[\]]{1,8}\]'), '');

                                  
  static Uint8List _encodeWav(Float32List samples, int sampleRate) {
    const headerSize = 44;
    final dataSize = samples.length * 2;
    final bytes = Uint8List(headerSize + dataSize);
    final bd = ByteData.view(bytes.buffer);

    void writeAscii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        bytes[offset + i] = s.codeUnitAt(i);
      }
    }

    writeAscii(0, 'RIFF');
    bd.setUint32(4, 36 + dataSize, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);                
    bd.setUint16(20, 1, Endian.little);       
    bd.setUint16(22, 1, Endian.little);       
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);            
    bd.setUint16(32, 2, Endian.little);              
    bd.setUint16(34, 16, Endian.little);                 
    writeAscii(36, 'data');
    bd.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < samples.length; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      bd.setInt16(headerSize + i * 2, (clamped * 32767).round(), Endian.little);
    }
    return bytes;
  }
}

                                       
class TtsSpeechInfo {
                         
  final int charCount;

                                      
  final Duration synthElapsed;

              
  final Duration audioDuration;

                          
  final bool fromCache;

  final DateTime at;

  const TtsSpeechInfo({
    required this.charCount,
    required this.synthElapsed,
    required this.audioDuration,
    required this.fromCache,
    required this.at,
  });

                                   
  double get rts => synthElapsed.inMilliseconds == 0
      ? 0
      : audioDuration.inMilliseconds / synthElapsed.inMilliseconds;
}
