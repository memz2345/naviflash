                                  
  
                         
  
                       
                                                        
                                     
                                                     
  
                       
                                                   
                                                   
                                                       
                                                  
                                                                     
                                              
                                               
                                          
                                                  
                                
  
                                      
                                    
             
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

         
enum StorageSlot {
                    
  autoCache,

                       
  video,

                             
  models,
}

                                          
class StorageCandidate {
           
  final String path;

                               
  final String label;

                          
  final String? detail;

                    
  final int? freeBytes;

                   
  final int? totalBytes;

                          
  final bool writable;

  const StorageCandidate({
    required this.path,
    required this.label,
    this.detail,
    this.freeBytes,
    this.totalBytes,
    this.writable = true,
  });

  @override
  String toString() => 'StorageCandidate($path, $label)';
}

              
class StoragePathInfo {
  final String path;
  final bool exists;
  final bool writable;
  final int? freeBytes;
  final int? totalBytes;

  const StoragePathInfo({
    required this.path,
    required this.exists,
    required this.writable,
    this.freeBytes,
    this.totalBytes,
  });

  bool get usable => writable;
}

abstract final class StoragePaths {
                          
                                                 
  static const MethodChannel _channel = MethodChannel(
    'com.memz2345.navi.flash/storage_locations',
  );

                            
                                                                  
  static String autoCachePath = '';
  static String videoPath = '';
  static String modelsPath = '';

                                        
  static void applyFromPrefs({
    required String autoCache,
    required String video,
    required String models,
  }) {
    autoCachePath = autoCache.trim();
    videoPath = video.trim();
    modelsPath = models.trim();
  }

  static String customFor(StorageSlot slot) => switch (slot) {
    StorageSlot.autoCache => autoCachePath,
    StorageSlot.video => videoPath,
    StorageSlot.models => modelsPath,
  };

                    
  static bool get _isIos => !kIsWeb && Platform.isIOS;

                    
     
                                                        
  static bool canCustomize(StorageSlot slot) {
    if (kIsWeb) return false;
    if (_isIos) return false;
    if (slot == StorageSlot.autoCache && Platform.isAndroid) return false;
    return true;
  }

                                         
  static bool get usesNativeCandidates => !kIsWeb && Platform.isAndroid;

                     
  static bool get usesFreePicker =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

                                              
          
                                              

                                     
  static Future<Directory> rootFor(StorageSlot slot) async {
    final custom = customFor(slot);
    if (custom.isNotEmpty && canCustomize(slot)) {
      final dir = await _ensureWritable(Directory(custom));
      if (dir != null) return dir;
    }
    return defaultRootFor(slot);
  }

              
  static Future<Directory> defaultRootFor(StorageSlot slot) async {
    if (slot == StorageSlot.models) {
      return _ensure(await getApplicationSupportDirectory());
    }
    return _ensure(await _defaultCacheRoot());
  }

                                   
     
                                   
                    
  static Future<List<Directory>> readRootsFor(StorageSlot slot) async {
    final main = await rootFor(slot);
    final fallback = await defaultRootFor(slot);
    if (_samePath(main.path, fallback.path)) return [main];
    return [main, fallback];
  }

                           
  static Future<Directory?> _ensureWritable(Directory dir) async {
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
                                           
      final probe = File(p.join(dir.path, '.naviflash_write_probe'));
      await probe.writeAsString('1', flush: true);
      await probe.delete();
      return dir;
    } catch (_) {
      return null;
    }
  }

  static Future<Directory> _ensure(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static bool _samePath(String a, String b) {
    final na = p.normalize(a).replaceAll(r'\', '/');
    final nb = p.normalize(b).replaceAll(r'\', '/');
    return na == nb ||
        na.endsWith('/') && nb.startsWith(na) ||
        nb.endsWith('/') && na.startsWith(nb);
  }

                                         

  static Future<void>? _migrating;

                                 
  static const List<String> legacyCacheNames = [
    'video_json_cache',
    'video_cache',
    'image_cache',
    'danmaku_cache',
    'article_cache',
    'dynamic_detail_cache',
  ];

  static Future<Directory> _defaultCacheRoot() async {
    _migrating ??= _migrateLegacyCache();
    await _migrating;
    return _ensure(await _resolveCacheRoot());
  }

  static Future<Directory> _resolveCacheRoot() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final ext = await getExternalCacheDirectories();
        if (ext != null && ext.isNotEmpty) return ext.first;
      } catch (_) {}
    }
    return getTemporaryDirectory();
  }

                           
  static Future<void> _migrateLegacyCache() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final targetBase = await _resolveCacheRoot();
      await _ensure(targetBase);
      for (final name in legacyCacheNames) {
        final old = Directory('${docs.path}/$name');
        if (!await old.exists()) continue;
        final target = Directory('${targetBase.path}/$name');
        try {
          if (await target.exists()) {
                                         
            await old.delete(recursive: true);
            continue;
          }
          try {
            await old.rename(target.path);
          } catch (_) {
                                           
            await old.delete(recursive: true);
          }
          debugPrint('[StoragePaths] 已迁移缓存目录: $name');
        } catch (e) {
          debugPrint('[StoragePaths] 迁移 $name 失败: $e');
        }
      }
    } catch (e) {
      debugPrint('[StoragePaths] 缓存迁移初始化失败: $e');
    }
  }

                                              
                          
                                              

                                               
                            
  static Future<List<StorageCandidate>> candidates(StorageSlot slot) async {
    if (!usesNativeCandidates) return const [];
    try {
      final raw = await _channel.invokeMethod<List<Object?>>(
        'listCandidates',
        {'slot': slot.name},
      );
      if (raw == null) return const [];
      final out = <StorageCandidate>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final map = item.cast<String, Object?>();
        final path = map['path'] as String?;
        if (path == null || path.isEmpty) continue;
        out.add(
          StorageCandidate(
            path: path,
            label: map['label'] as String? ?? p.basename(path),
            detail: map['detail'] as String?,
            freeBytes: _asInt(map['freeBytes']),
            totalBytes: _asInt(map['totalBytes']),
            writable: map['writable'] as bool? ?? true,
          ),
        );
      }
      return out;
    } catch (e) {
      debugPrint('[StoragePaths] 候选目录列举失败: $e');
      return const [];
    }
  }

                                  
  static Future<StoragePathInfo?> info(String path) async {
    final dir = Directory(path);
    bool exists;
    try {
      exists = await dir.exists();
    } catch (_) {
      return null;
    }
    var writable = false;
    if (exists) {
      final probe = File(p.join(path, '.naviflash_write_probe'));
      try {
        await probe.writeAsString('1', flush: true);
        await probe.delete();
        writable = true;
      } catch (_) {}
    } else {
      try {
        await dir.create(recursive: true);
        await dir.delete();
        writable = true;
      } catch (_) {}
    }
    int? free;
    int? total;
    if (usesNativeCandidates) {
      try {
        final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
          'pathInfo',
          {'path': path},
        );
        if (raw != null) {
          final map = raw.cast<String, Object?>();
          free = _asInt(map['freeBytes']);
          total = _asInt(map['totalBytes']);
        }
      } catch (_) {}
    }
    return StoragePathInfo(
      path: path,
      exists: exists,
      writable: writable,
      freeBytes: free,
      totalBytes: total,
    );
  }

                                          
     
                                        
                            
  static Future<String?> createSubdirectory(
    String parent,
    String name,
  ) async {
    final clean = name
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '_')
        .trim();
    if (clean.isEmpty || clean == '.' || clean == '..') return null;
    final dir = Directory(p.join(parent, clean));
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    } catch (_) {
      return null;
    }
  }

  static int? _asInt(Object? v) => switch (v) {
    final int i => i,
    final num n => n.toInt(),
    _ => null,
  };
}
