                                            
  
                  
  
                                          
                                            
                                                    
  
                                       
                                    
                                
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:naviflash/services/tts_model_service.dart';
import 'package:path/path.dart' as p;

class TtsAudioCacheEntry {
  final File file;

  const TtsAudioCacheEntry(this.file);

  String get fileName => file.path;

  int get sizeBytes => file.existsSync() ? file.lengthSync() : 0;
}

class TtsAudioCacheService {
  TtsAudioCacheService._();

                                       
  static const int cacheVersion = 1;

                                    
                                               
  static const int maxEntries = 500;

  static Future<Directory> get _cacheDir async {
    final root = await TtsModelService.ttsRoot;
    final dir = Directory(p.join(root.path, 'audio_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

                                           
  static String _voiceToken(String? voicePath) {
    if (voicePath == null || voicePath.isEmpty) return 'default';
    return p.basename(voicePath);
  }

                        
  static String keyFor(
    String cleanedText, {
    String? voicePath,
    String language = 'zh',
    double speed = 1.0,
  }) {
    final material = 'v$cacheVersion\n'
        'voice=${_voiceToken(voicePath)}\n'
        'lang=$language\n'
        'speed=${speed.toStringAsFixed(3)}\n'
        'text=$cleanedText';
    return sha1.convert(material.codeUnits).toString();
  }

  static Future<File> _fileForKey(String key) async {
    final dir = await _cacheDir;
    return File(p.join(dir.path, '$key.wav'));
  }

                                       
  static Future<File?> lookup(
    String cleanedText, {
    String? voicePath,
    String language = 'zh',
    double speed = 1.0,
  }) async {
    final file = await _fileForKey(keyFor(
      cleanedText,
      voicePath: voicePath,
      language: language,
      speed: speed,
    ));
    if (!await file.exists()) return null;
                                              
    try {
      await file.setLastModified(DateTime.now());
    } catch (_) {}
    return file;
  }

                                
  static Future<File> store(
    String cleanedText,
    List<int> wavBytes, {
    String? voicePath,
    String language = 'zh',
    double speed = 1.0,
  }) async {
    final file = await _fileForKey(keyFor(
      cleanedText,
      voicePath: voicePath,
      language: language,
      speed: speed,
    ));
    await file.writeAsBytes(wavBytes, flush: true);
    unawaitedPrune();
    return file;
  }

                               
  static void unawaitedPrune() {
    Future(() async {
      try {
        await prune(maxEntries);
      } catch (_) {}
    });
  }

                                 
  static Future<int> prune(int keep) async {
    final dir = await _cacheDir;
    final files = await dir
        .list()
        .where((e) => e is File && p.extension(e.path).toLowerCase() == '.wav')
        .cast<File>()
        .toList();
    if (files.length <= keep) return 0;
    files.sort((a, b) =>
        b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    var removed = 0;
    for (final f in files.skip(keep)) {
      try {
        await f.delete();
        removed++;
      } catch (_) {}
    }
    return removed;
  }

                     
  static Future<({int count, int bytes})> stats() async {
    final dir = await _cacheDir;
    var count = 0;
    var bytes = 0;
    try {
      await for (final e in dir.list()) {
        if (e is File && p.extension(e.path).toLowerCase() == '.wav') {
          count++;
          bytes += await e.length();
        }
      }
    } catch (_) {}
    return (count: count, bytes: bytes);
  }

                    
  static Future<int> clearAll() async {
    final dir = await _cacheDir;
    var removed = 0;
    try {
      await for (final e in dir.list()) {
        if (e is File && p.extension(e.path).toLowerCase() == '.wav') {
          try {
            await e.delete();
            removed++;
          } catch (_) {}
        }
      }
    } catch (_) {}
    return removed;
  }
}
