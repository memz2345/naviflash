                                       
  
                                           
                                  
  
                                           
                                                    
                                        
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tts_export_native.dart';

                                     
enum TtsExportFormat {
  mp3('MP3', 'mp3', 'audio/mpeg'),
  silk('SILK', 'silk', 'audio/silk'),
  slk('SLK', 'slk', 'audio/silk');

  final String label;
  final String ext;
  final String mime;

  const TtsExportFormat(this.label, this.ext, this.mime);

  bool get isSilk => this != TtsExportFormat.mp3;
}

class TtsExportException implements Exception {
  final String message;
  TtsExportException(this.message);

  @override
  String toString() => message;
}

                        
class TtsPcmData {
  final Int16List samples;
  final int sampleRate;

  const TtsPcmData(this.samples, this.sampleRate);

  int get durationMillis =>
      (samples.length / sampleRate * 1000).round();
}

class TtsExportService {
  TtsExportService._();

                                                        
                
  static const List<int> _silkRates = [8000, 12000, 16000, 24000, 48000];

  static bool get isSupported => TtsExportNative.instance.isSupported;

                                     
  static Future<Uint8List> encodeWavFile({
    required File wav,
    required TtsExportFormat format,
    required bool tencent,
  }) async {
    if (!isSupported) throw TtsExportUnsupportedException();
    if (!wav.existsSync()) {
      throw TtsExportException('音频文件不存在（可能已被缓存淘汰），请重新朗读');
    }
    final raw = await wav.readAsBytes();

                                         
    return Isolate.run(() {
      final pcm = parseWav(raw);
      final native = TtsExportNative.instance;
      switch (format) {
        case TtsExportFormat.mp3:
          return native.encodeMp3(pcm.samples, pcm.sampleRate);
        case TtsExportFormat.silk:
        case TtsExportFormat.slk:
          if (!_silkRates.contains(pcm.sampleRate)) {
            throw TtsExportException(
              'SILK 不支持 ${pcm.sampleRate}Hz 采样率（需 8/12/16/24/48k）',
            );
          }
          return native.encodeSilk(
            pcm.samples,
            pcm.sampleRate,
            tencent: tencent,
          );
      }
    });
  }

                                      
  static String fileNameFor(TtsExportFormat format, {DateTime? at}) {
    final t = at ?? DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${t.year}${two(t.month)}${two(t.day)}_'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}';
    return '朗读_$stamp.${format.ext}';
  }

                                            
  static Future<File> stageForShare(
    Uint8List bytes,
    String fileName,
  ) async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory(p.join(tmp.path, 'tts_export'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final f = File(p.join(dir.path, fileName));
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

                                                 
                                                     
  static TtsPcmData parseWav(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    bool asciiAt(int off, String s) {
      if (off + s.length > bytes.length) return false;
      for (var i = 0; i < s.length; i++) {
        if (bytes[off + i] != s.codeUnitAt(i)) return false;
      }
      return true;
    }

    if (bytes.length < 12 ||
        !asciiAt(0, 'RIFF') ||
        !asciiAt(8, 'WAVE')) {
      throw TtsExportException('不是有效的 WAV 文件（缺 RIFF/WAVE 标识）');
    }

    int? audioFormat;
    int? channels;
    int? sampleRate;
    int? bitsPerSample;
    Uint8List? pcmBytes;

    var pos = 12;
    while (pos + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes.sublist(pos, pos + 4));
      final size = bd.getUint32(pos + 4, Endian.little);
      final body = pos + 8;
      if (body + size > bytes.length) {
                                                 
        if (pcmBytes != null && audioFormat != null) break;
        throw TtsExportException('WAV chunk 越界：$id');
      }
      if (id == 'fmt ' && size >= 16) {
        audioFormat = bd.getUint16(body, Endian.little);
        channels = bd.getUint16(body + 2, Endian.little);
        sampleRate = bd.getUint32(body + 4, Endian.little);
        bitsPerSample = bd.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        pcmBytes = Uint8List.sublistView(bytes, body, body + size);
      }
                                        
      if (pcmBytes != null && audioFormat != null) break;
      pos = body + size + (size.isOdd ? 1 : 0);             
    }

    if (audioFormat == null ||
        channels == null ||
        sampleRate == null ||
        bitsPerSample == null) {
      throw TtsExportException('WAV 缺少 fmt 块');
    }
    if (audioFormat != 1) {
      throw TtsExportException('仅支持 PCM WAV（format=$audioFormat）');
    }
    if (channels != 1) {
      throw TtsExportException('仅支持单声道 WAV（channels=$channels）');
    }
    if (bitsPerSample != 16) {
      throw TtsExportException('仅支持 16bit WAV（bits=$bitsPerSample）');
    }
    if (pcmBytes == null || pcmBytes.isEmpty) {
      throw TtsExportException('WAV 没有音频数据');
    }
                           
    final sampleCount = pcmBytes.length ~/ 2;
    final view = ByteData.sublistView(
      pcmBytes,
      0,
      sampleCount * 2,
    );
    final samples = Int16List(sampleCount);
    for (var i = 0; i < sampleCount; i++) {
      samples[i] = view.getInt16(i * 2, Endian.little);
    }
    return TtsPcmData(samples, sampleRate);
  }
}
