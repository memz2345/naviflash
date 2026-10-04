                                            
  
                           
  
                                                      
                                                     
                                      
              
  
                                                      
                               
  
                                           
                                
                                                             
                                                        
                                          
                                                                      
                                                                           
import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:naviflash/services/storage_paths.dart';
import 'package:onnxruntime_v2/onnxruntime_v2.dart' show OrtLibrary;
import 'package:path/path.dart' as p;

                              
const String kDefaultOnnxBaseUrl =
    'https://github.com/memz2345/naviflash/releases/download/onnx-v1/';

                 
const String kOnnxModelFileName = 'u2netp.onnx';

         
enum OnnxDepState {
                             
  unsupported,

                  
  notInstalled,

         
  installed,
}

class OnnxDependencyService {
  OnnxDependencyService._();

  static final http.Client _client = http.Client();

                            
                                              
  static String? customBaseUrl;

  static String get baseUrl {
    final c = customBaseUrl?.trim();
    if (c != null && c.isNotEmpty) {
      return c.endsWith('/') ? c : '$c/';
    }
    return kDefaultOnnxBaseUrl;
  }

                                 
     
                                        
                           
  static String? get runtimeFileName {
    if (Platform.isWindows) return 'onnxruntime.dll';
    if (Platform.isLinux) return 'libonnxruntime.so.1.22.0';
    if (Platform.isMacOS) return 'libonnxruntime.1.22.0.dylib';
    if (Platform.isAndroid) {
      final abi = ffi.Abi.current();
      if (abi == ffi.Abi.androidArm64) return 'libonnxruntime_arm64-v8a.so';
      if (abi == ffi.Abi.androidArm) return 'libonnxruntime_armeabi-v7a.so';
      if (abi == ffi.Abi.androidX64) return 'libonnxruntime_x86_64.so';
      if (abi == ffi.Abi.androidIA32) return 'libonnxruntime_x86.so';
      return null;
    }
                                             
    return null;
  }

  static bool get isPlatformSupported => runtimeFileName != null;

                                  
  static Future<Directory> get _dir async {
    final base = await StoragePaths.rootFor(StorageSlot.models);
    final dir = Directory(p.join(base.path, 'onnx'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

                                    
  static Future<List<Directory>> _candidateDirs() async {
    final roots = await StoragePaths.readRootsFor(StorageSlot.models);
    final out = <Directory>[];
    final seen = <String>{};
    for (final r in roots) {
      final path = p.normalize(p.join(r.path, 'onnx'));
      if (seen.add(path)) out.add(Directory(path));
    }
    return out;
  }

  static Future<File> _runtimeFile() async {
    final name = runtimeFileName;
    if (name == null) throw UnsupportedError('当前平台不支持智能防遮挡');
    return File(p.join((await _dir).path, name));
  }

  static Future<File> _modelFile() async =>
      File(p.join((await _dir).path, kOnnxModelFileName));

                          
  static Future<int> installedBytes() async {
    if (!isPlatformSupported) return 0;
    var total = 0;
    for (final dir in await _candidateDirs()) {
      for (final name in [runtimeFileName!, kOnnxModelFileName]) {
        final f = File(p.join(dir.path, name));
        if (await f.exists()) {
          total += await f.length().catchError((_) => 0);
        }
      }
    }
    return total;
  }

                                     
                                                  
  static bool installedCached = false;

                                 
  static Future<bool> refreshInstalled() async {
    installedCached = await state() == OnnxDepState.installed;
    return installedCached;
  }

  static Future<OnnxDepState> state() async {
    if (!isPlatformSupported) return OnnxDepState.unsupported;
    final rtPath = await runtimeFilePath();
    final mdPath = await modelPath();
    if (rtPath == null || mdPath == null) return OnnxDepState.notInstalled;
    final rtOk = await File(rtPath).length().catchError((_) => 0) > 1024 * 1024;
    final mdOk = await File(mdPath).length().catchError((_) => 0) > 1024 * 1024;
    return (rtOk && mdOk) ? OnnxDepState.installed : OnnxDepState.notInstalled;
  }

                                    
  static Future<String?> modelPath() async {
    if (!isPlatformSupported) return null;
    for (final dir in await _candidateDirs()) {
      final f = File(p.join(dir.path, kOnnxModelFileName));
      if (await f.exists()) return f.path;
    }
    return null;
  }

                                     
  static Future<String?> runtimeFilePath() async {
    if (!isPlatformSupported) return null;
    final name = runtimeFileName;
    if (name == null) return null;
    for (final dir in await _candidateDirs()) {
      final f = File(p.join(dir.path, name));
      if (await f.exists()) return f.path;
    }
    return null;
  }

                                
                                       
  static Future<void> applyRuntimePath() async {
    if (!isPlatformSupported) {
      OrtLibrary.path = null;
      return;
    }
    OrtLibrary.path = await runtimeFilePath();
  }

              
     
                                                
                                             
  static Future<void> install({
    void Function(int received, int total)? onProgress,
  }) async {
    if (!isPlatformSupported) {
      throw OnnxDownloadException('当前平台不支持智能防遮挡（需要可加载的动态库）');
    }
    final targets = <File>[await _runtimeFile(), await _modelFile()];
    final todo = <File>[];
    for (final f in targets) {
      if (await f.exists()) {
                                        
        if (await f.length().catchError((_) => 0) > 1024 * 1024) continue;
        await f.delete().catchError((_) => f);
      }
      todo.add(f);
    }
    if (todo.isEmpty) {
      await applyRuntimePath();
      installedCached = true;
      return;
    }

    final base = baseUrl;
    for (final f in todo) {
      final url = Uri.parse(base + p.basename(f.path));
      await _download(url, f, onProgress: onProgress);
    }

                                 
    final rt = await _runtimeFile();
    try {
      ffi.DynamicLibrary.open(rt.path);
    } catch (e) {
      await rt.delete().catchError((_) => rt);
      throw OnnxDownloadException('运行库无法加载，可能下载不完整或架构不匹配：$e');
    }
    final md = await _modelFile();
    if (await md.length().catchError((_) => 0) < 1024 * 1024) {
      throw OnnxDownloadException('模型文件不完整，请重新下载');
    }
    await applyRuntimePath();
    installedCached = true;
  }

                                         
                     
  static Future<void> uninstall() async {
    OrtLibrary.path = null;
    if (!isPlatformSupported) return;
    for (final dir in await _candidateDirs()) {
      if (await dir.exists()) {
        await dir.delete(recursive: true).catchError((_) => dir);
      }
    }
    installedCached = false;
  }

  static Future<void> _download(
    Uri url,
    File target, {
    void Function(int received, int total)? onProgress,
  }) async {
    late final http.StreamedResponse resp;
    try {
      final req = http.Request('GET', url)..followRedirects = true;
      resp = await _client.send(req).timeout(const Duration(seconds: 30));
    } catch (e) {
      throw OnnxDownloadException('连接下载源失败：$e');
    }
    if (resp.statusCode != 200) {
      throw OnnxDownloadException(
          '下载失败：HTTP ${resp.statusCode}（${p.basename(target.path)}）');
    }
    final total = resp.contentLength ?? 0;
    final tmp = File('${target.path}.part');
    IOSink? sink;
    var received = 0;
    try {
      sink = tmp.openWrite();
      await resp.stream.timeout(const Duration(minutes: 10)).forEach((chunk) {
        sink!.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      });
      await sink.flush();
      await sink.close();
      sink = null;
      if (total > 0 && received != total) {
        throw OnnxDownloadException('下载被中断（$received/$total 字节）');
      }
                                             
      if (await target.exists()) {
        await target.delete();
      }
      await tmp.rename(target.path);
    } on OnnxDownloadException {
      rethrow;
    } catch (e) {
      throw OnnxDownloadException('下载失败：$e');
    } finally {
      if (sink != null) {
        await sink.close().catchError((_) {});
      }
      if (await tmp.exists()) {
        await tmp.delete().catchError((_) => tmp);
      }
    }
    debugPrint('[OnnxDep] 已下载 ${p.basename(target.path)} → ${target.path}');
  }
}

class OnnxDownloadException implements Exception {
  final String message;
  OnnxDownloadException(this.message);

  @override
  String toString() => message;
}
