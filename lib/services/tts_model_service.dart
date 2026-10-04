                                      
  
                                    
  
                                                         
                                      
  
                                                                 
                               
  
                                                    
                                           
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:naviflash/services/model_download_service.dart';
import 'package:naviflash/services/storage_paths.dart';
import 'package:path/path.dart' as p;

          
enum TtsMirror {
                          
  official,

                                 
  hfMirror,

             
  custom,
}

             
class TtsModelFile {
                                 
  final String rel;

                                   
  final int bytes;

  const TtsModelFile(this.rel, this.bytes);

  String get name => rel.split('/').last;
}

                    
class TtsModelVariant {
                        
  final String id;

                        
  final String repo;

                           
  final String subDir;

          
  final String label;

                                   
  final bool supportsCloning;

  final List<TtsModelFile> files;

  const TtsModelVariant({
    required this.id,
    required this.repo,
    required this.subDir,
    required this.label,
    required this.supportsCloning,
    required this.files,
  });

  int get totalBytes =>
      files.fold<int>(0, (sum, f) => sum + f.bytes);
}

                                         
   
                                                    
                                                             
                                          
                                                
   
                                                             
                                                       
                                                    
         
   
                                                                         
                        
                                              
const TtsModelVariant kQwen3Tts17BBase = TtsModelVariant(
  id: 'qwen3-1.7b-base',
  repo: 'ggml-org/Qwen3-TTS-12Hz-1.7B-Base-GGUF',
  subDir: '',
  label: 'Qwen3-TTS 1.7B',
  supportsCloning: true,
  files: [
    TtsModelFile('Qwen3-TTS-12Hz-1.7B-Base-Q4_K_M.gguf', 1035993088),
    TtsModelFile('mmproj-Qwen3-TTS-12Hz-1.7B-Base-Q8_0.gguf', 446376857),
  ],
);

              
const List<TtsModelVariant> kTtsModelVariants = [kQwen3Tts17BBase];

         
enum TtsModelState {
                  
  notInstalled,

                              
  partial,

        
  installed,
}

class TtsModelService {
  TtsModelService._();

  static final http.Client _client = http.Client();

              
  static TtsModelVariant variant = kQwen3Tts17BBase;

                                                   
  static TtsMirror mirror = TtsMirror.hfMirror;

                                          
  static String? customBaseUrl;

  static const String _officialPrefix = 'https://huggingface.co/';
  static const String _hfMirrorPrefix = 'https://hf-mirror.com/';

                      
  static String get baseUrl {
    final prefix = switch (mirror) {
      TtsMirror.official => _officialPrefix,
      TtsMirror.hfMirror => _hfMirrorPrefix,
      TtsMirror.custom => (customBaseUrl ?? '').trim(),
    };
    final base = prefix.isEmpty ? _hfMirrorPrefix : prefix;
    final withSlash = base.endsWith('/') ? base : '$base/';
    final head = '$withSlash${variant.repo}/resolve/main/';
    final sub = variant.subDir.trim();
    if (sub.isEmpty) return head;
    final clean = sub.replaceAll(RegExp(r'^/|/$'), '');
    return '$head$clean/';
  }

                     
     
                                           
                                             
                                                            
               
  static bool get isPlatformSupported => true;

  static void applyMirror(TtsMirror m, String customUrl) {
    mirror = m;
    customBaseUrl = customUrl.trim().isEmpty ? null : customUrl.trim();
  }

                                        
  static Future<Directory> get ttsRoot async {
    final base = await StoragePaths.rootFor(StorageSlot.models);
    final dir = Directory(p.join(base.path, 'tts'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

                                
  static Future<Directory> modelDir([TtsModelVariant? v]) async {
    final root = await ttsRoot;
    final dir = Directory(p.join(root.path, (v ?? variant).id));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

                                    
     
                                      
  static Future<List<Directory>> _candidateModelDirs([
    TtsModelVariant? v,
  ]) async {
    final roots = await StoragePaths.readRootsFor(StorageSlot.models);
    final id = (v ?? variant).id;
    final out = <Directory>[];
    final seen = <String>{};
    for (final r in roots) {
      final path = p.normalize(p.join(r.path, 'tts', id));
      if (seen.add(path)) out.add(Directory(path));
    }
    return out;
  }

  static Future<File> _file(TtsModelFile f) async =>
      File(p.join((await modelDir()).path, f.rel));

                                       
  static bool _isComplete(int actual, int expected) {
    if (actual <= 0) return false;
    if (expected <= 8 * 1024) return true;                    
    return actual >= (expected * 0.98).floor();
  }

                        
  static Future<int> installedBytes() async {
    var total = 0;
    for (final dir in await _candidateModelDirs()) {
      for (final f in variant.files) {
        final file = File(p.join(dir.path, f.rel));
        if (await file.exists()) {
          total += await file.length().catchError((_) => 0);
        }
      }
    }
    return total;
  }

  static Future<TtsModelState> state() async {
    var best = TtsModelState.notInstalled;
    for (final dir in await _candidateModelDirs()) {
      var missing = 0;
      var present = 0;
      for (final f in variant.files) {
        final file = File(p.join(dir.path, f.rel));
        if (!await file.exists()) {
          missing++;
          continue;
        }
        final len = await file.length().catchError((_) => 0);
        if (_isComplete(len, f.bytes)) {
          present++;
        } else {
          missing++;
        }
      }
      final st = missing == 0
          ? TtsModelState.installed
          : (present > 0 ? TtsModelState.partial : TtsModelState.notInstalled);
      if (st.index > best.index) best = st;
      if (best == TtsModelState.installed) break;
    }
    return best;
  }

                                         
  static Future<String?> readyModelDir() async {
    for (final dir in await _candidateModelDirs()) {
      if (await _stateAt(dir) == TtsModelState.installed) return dir.path;
    }
    return null;
  }

  static Future<TtsModelState> _stateAt(Directory dir) async {
    var missing = 0;
    var present = 0;
    for (final f in variant.files) {
      final file = File(p.join(dir.path, f.rel));
      if (!await file.exists()) {
        missing++;
        continue;
      }
      final len = await file.length().catchError((_) => 0);
      if (_isComplete(len, f.bytes)) {
        present++;
      } else {
        missing++;
      }
    }
    if (missing == 0) return TtsModelState.installed;
    if (present > 0) return TtsModelState.partial;
    return TtsModelState.notInstalled;
  }

                                 
     
                                         
                        
  static Future<List<ModelDownloadFile>> pendingDownloadFiles() async {
    final dir = await modelDir();
    final base = baseUrl;
    final out = <ModelDownloadFile>[];
    for (final f in variant.files) {
      final file = File(p.join(dir.path, f.rel));
      final len = await _lengthOf(file);
      if (len > 0 && _isComplete(len, f.bytes)) continue;
      out.add(
        ModelDownloadFile(
          url: '$base${f.rel}',
          path: file.path,
          bytes: f.bytes,
          name: f.name,
        ),
      );
    }
    return out;
  }

                          
     
                                            
                                               
                                     
     
                                          
                                                                          
  static Future<void> install({
    void Function(int received, int total, String currentName)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    if (!isPlatformSupported) {
      throw TtsModelException('当前平台不支持 AI 朗读');
    }

                                    
    final freed = await cleanupOrphans();
    if (freed > 0) {
      debugPrint('[TtsModel] 清理无用断点文件 ${(freed / 1024 / 1024).round()}MB');
    }

                               
    var doneBytes = 0;
    final todo = <(TtsModelFile, int)>[];
    for (final f in variant.files) {
      final file = await _file(f);
      final tmp = File('${file.path}.part');
      final len = await _lengthOf(file);

                               
      if (len > 0 && _isComplete(len, f.bytes)) {
        doneBytes += len;
        await _deleteQuietly(tmp);
        continue;
      }

                                         
      var start = await _lengthOf(tmp);
      if (start == 0 && len > 0) {
        if (await _renameQuietly(file, tmp)) start = len;
      }
                           
      if (start > f.bytes) {
        await _deleteQuietly(tmp);
        start = 0;
      }
      todo.add((f, start));
    }

    final total = variant.totalBytes;
    final base = baseUrl;
    for (final (f, start) in todo) {
      if (shouldCancel?.call() ?? false) throw const TtsModelCancelled();
      final target = await _file(f);
      await target.parent.create(recursive: true);
      final url = Uri.parse('$base${f.rel}');
      await _download(
        url,
        target,
        start: start,
        onProgress: (received, _) {
          onProgress?.call(doneBytes + received, total, f.name);
        },
        shouldCancel: shouldCancel,
      );
      doneBytes += f.bytes;
    }

           
    if (await state() != TtsModelState.installed) {
      throw TtsModelException('部分文件校验失败，请重新下载');
    }
    await pruneLegacyVariants();
  }

                        
     
                                            
                               
  static Future<int> pruneLegacyVariants() async {
    final root = await ttsRoot;
    final keep = kTtsModelVariants.map((v) => v.id).toSet();
    var removed = 0;
    await for (final entity in root.list()) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (keep.contains(name) || name == 'voices') continue;
      await entity.delete(recursive: true).catchError((_) => entity);
      removed++;
    }
    return removed;
  }

                                 
  static Future<void> uninstall() async {
    for (final dir in await _candidateModelDirs()) {
      if (await dir.exists()) {
        await dir.delete(recursive: true).catchError((_) => dir);
      }
    }
  }

                        
     
                                           
                                                   
                                                
                                   
  static Future<void> _download(
    Uri url,
    File target, {
    int start = 0,
    void Function(int received, int total)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final tmp = File('${target.path}.part');
    var offset = start;

    late final http.StreamedResponse resp;
    try {
      final req = http.Request('GET', url)..followRedirects = true;
      if (offset > 0) req.headers['Range'] = 'bytes=$offset-';
                         
      resp = await _client.send(req).timeout(const Duration(seconds: 60));
    } catch (e) {
      throw TtsModelException('连接下载源失败：$e（已保留断点，可继续）');
    }

                                           
    var totalFull = 0;
    if (resp.statusCode == 206) {
      final cr = resp.headers['content-range'] ?? '';
      final m = RegExp(r'/(\d+)\s*$').firstMatch(cr);
      totalFull =
          int.tryParse(m?.group(1) ?? '') ??
          (offset + (resp.contentLength ?? 0));
    } else if (resp.statusCode == 200) {
      if (offset > 0) {
                                        
        debugPrint('[TtsModel] 下载源不支持断点，重新下载 ${p.basename(target.path)}');
        offset = 0;
      }
      totalFull = resp.contentLength ?? 0;
    } else {
      throw TtsModelException(
        '下载失败：HTTP ${resp.statusCode}（${p.basename(target.path)}）',
      );
    }

    IOSink? sink;
    var received = 0;
    try {
      sink = tmp.openWrite(
        mode: offset > 0 ? FileMode.append : FileMode.write,
      );
                          
      await resp.stream.timeout(const Duration(minutes: 30)).forEach((chunk) {
        if (shouldCancel?.call() ?? false) throw const TtsModelCancelled();
        sink!.add(chunk);
        received += chunk.length;
        onProgress?.call(offset + received, totalFull);
      });
      await sink.flush();
      await sink.close();
      sink = null;

      final onDisk = await _lengthOf(tmp);
      if (totalFull > 0 && onDisk < totalFull) {
        throw TtsModelException(
          '下载中断（$onDisk/$totalFull 字节），已保留断点，可继续',
        );
      }
                                             
      if (await target.exists()) {
        await target.delete();
      }
      await tmp.rename(target.path);
    } on TtsModelCancelled {
      rethrow;
    } on TtsModelException {
      rethrow;
    } catch (e) {
      throw TtsModelException('下载失败：$e（已保留断点，可继续）');
    } finally {
      if (sink != null) {
        await sink.close().catchError((_) {});
      }
                                                      
    }
    debugPrint('[TtsModel] 已下载 ${p.basename(target.path)}');
  }

                                   
                                     
                        
                              
                      
  @visibleForTesting
  static bool partIsUseless({
    required int partLen,
    required int targetLen,
    required int? expected,
  }) {
    if (expected == null) return true;
    if (_isComplete(targetLen, expected)) return true;
    return partLen > expected;
  }

                         
  static Future<int> _lengthOf(File f) async {
    if (!await f.exists()) return 0;
    return f.length().catchError((_) => 0);
  }

  static Future<void> _deleteQuietly(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

                                 
  static Future<bool> _renameQuietly(File from, File to) async {
    try {
      await from.rename(to.path);
      return true;
    } catch (_) {
      return false;
    }
  }

                                               
                         
     
                                       
  static Future<int> cleanupOrphans() async {
    var freed = 0;
    final dir = await modelDir();
    if (!await dir.exists()) return 0;

    final known = <String, int>{};
    for (final f in variant.files) {
      known[p.basename(f.rel)] = f.bytes;
    }

    await for (final entity in dir.list(recursive: true)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (!name.endsWith('.part')) continue;
      final target = name.substring(0, name.length - '.part'.length);
      final expected = known[target];
      final len = await _lengthOf(entity);
                                       
      final targetFile = File(entity.path.substring(0, entity.path.length - 5));
      final targetLen = await _lengthOf(targetFile);
      if (!partIsUseless(
        partLen: len,
        targetLen: targetLen,
        expected: expected,
      )) {
        continue;
      }
      await _deleteQuietly(entity);
      freed += len;
    }
    return freed;
  }
}

                                            
class TtsModelCancelled implements Exception {
  const TtsModelCancelled();

  @override
  String toString() => '已取消（断点已保留）';
}

class TtsModelException implements Exception {
  final String message;
  TtsModelException(this.message);

  @override
  String toString() => message;
}
