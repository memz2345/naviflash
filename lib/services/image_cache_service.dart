                                        
  
                                    
                                             
                           
                                                 
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:naviflash/services/cache_dirs.dart';
import 'package:naviflash/services/network_settings_service.dart';

abstract final class ImageCacheService {
  static const String _cacheDirName = 'image_cache';

                                           
                                 
  static const int maxCacheBytes = 300 * 1024 * 1024;

                                        
  static Future<Directory> get cacheDir async {
    final appDir = await AppCacheDirs.root();
    final dir = Directory('${appDir.path}/$_cacheDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

                                
  static String cacheKey(String url) =>
      md5.convert(utf8.encode(url.trim())).toString();

  static Future<File> _cacheFile(String url) async {
    final dir = await cacheDir;
    return File('${dir.path}/${cacheKey(url)}.img');
  }

                          
  static Future<File?> load(String url) async {
    if (url.trim().isEmpty) return null;
    try {
      final file = await _cacheFile(url);
      if (await file.exists()) return file;
      return null;
    } catch (_) {
      return null;
    }
  }

                                                 
                                               
                          
  static DateTime _lastEvictCheck = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _evictCheckInterval = Duration(seconds: 5);

                           
  static Future<File> save(String url, Uint8List bytes) async {
    final file = await _cacheFile(url);
    if (await file.exists()) return file;
    await file.writeAsBytes(bytes, flush: true);
                                             
    await _writeUrlSidecar(url);
                             
    final now = DateTime.now();
    if (now.difference(_lastEvictCheck) >= _evictCheckInterval) {
      _lastEvictCheck = now;
      await _evictIfOverCap();
    }
    return file;
  }

                                               
  static Future<void> _writeUrlSidecar(String url) async {
    try {
      final dir = await cacheDir;
      final f = File('${dir.path}/${cacheKey(url)}.url');
      await f.writeAsString(url, flush: true);
    } catch (_) {}
  }

                                     
  static Future<void> _evictIfOverCap() async {
    try {
      final dir = await cacheDir;
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.img'))
          .toList();
      var total = 0;
      for (final f in files) {
        total += await f.length().catchError((_) => 0);
      }
      if (total <= maxCacheBytes) return;
      files.sort(
        (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),
      );
      for (final f in files) {
        if (total <= maxCacheBytes) break;
        try {
          final sz = await f.length().catchError((_) => 0);
          await f.delete();
                          
          if (f.path.endsWith('.img')) {
            final side = File('${f.path.substring(0, f.path.length - 4)}.url');
            if (await side.exists()) await side.delete();
          }
          total -= sz;
        } catch (_) {}
      }
    } catch (_) {}
  }

                                        
  static Future<int> totalSize() async {
    try {
      final dir = await cacheDir;
      if (!await dir.exists()) return 0;
      var total = 0;
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.img')) {
          total += await entity.length().catchError((_) => 0);
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

                               
  static Future<int> count() async {
    try {
      final dir = await cacheDir;
      if (!await dir.exists()) return 0;
      var count = 0;
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.img')) count++;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

                           
  static Future<List<ImageCacheEntry>> listEntries() async {
    try {
      final dir = await cacheDir;
      if (!await dir.exists()) return const [];
      final entries = <ImageCacheEntry>[];
      await for (final entity in dir.list()) {
        if (entity is! File || !entity.path.endsWith('.img')) continue;
        final file = entity;
        final base = file.path.substring(0, file.path.length - 4);
        var url = '';
        try {
          final side = File('$base.url');
          if (await side.exists()) {
            url = (await side.readAsString()).trim();
          }
        } catch (_) {}
        var size = 0;
        var modified = DateTime.fromMillisecondsSinceEpoch(0);
        try {
          size = await file.length();
          modified = await file.lastModified();
        } catch (_) {}
        entries.add(
          ImageCacheEntry(file: file, url: url, size: size, modified: modified),
        );
      }
      entries.sort((a, b) => b.modified.compareTo(a.modified));
      return entries;
    } catch (_) {
      return const [];
    }
  }

                            
  static Future<void> deleteFile(File file) async {
    try {
      if (await file.exists()) await file.delete();
      if (file.path.endsWith('.img')) {
        final side = File(
          '${file.path.substring(0, file.path.length - 4)}.url',
        );
        if (await side.exists()) await side.delete();
      }
    } catch (_) {}
  }

                                           
  static Future<int> clearAll() async {
    try {
      final dir = await cacheDir;
      if (!await dir.exists()) return 0;
      var imgCount = 0;
      await for (final entity in dir.list()) {
        if (entity is File) {
          if (entity.path.endsWith('.img')) imgCount++;
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
      return imgCount;
    } catch (_) {
      return 0;
    }
  }

                                              
                         
                                              

                                              
                             
  static final Map<String, Future<Uint8List?>> _pendingFetch = {};

                                 
                                                         
                                                   
  static Future<Uint8List?> fetch(String url, {Map<String, String>? headers}) {
    final key = url.trim();
    if (key.isEmpty) return Future.value(null);
    final pending = _pendingFetch[key];
    if (pending != null) return pending;
    final future = _fetchImpl(key, headers);
    _pendingFetch[key] = future;
    future.whenComplete(() => _pendingFetch.remove(key));
    return future;
  }

  static Future<Uint8List?> _fetchImpl(
    String url,
    Map<String, String>? headers,
  ) async {
    try {
                         
      final cached = await load(url);
      if (cached != null) {
        final bytes = await _readFile(cached);
        if (bytes != null) return bytes;
      }
                         
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(url), headers: headers ?? _apiHeaders())
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return null;
      final bytes = resp.bodyBytes;
                       
      await save(url, bytes);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  static Map<String, String>? _apiHeaders() {
    try {
      final headers = NetworkSettingsService.instance.apiHeaders;
      return headers.isEmpty ? null : headers;
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _readFile(File file) async {
    try {
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }
}

                               
class ImageCacheEntry {
  final File file;
  final String url;                        
  final int size;
  final DateTime modified;

  const ImageCacheEntry({
    required this.file,
    required this.url,
    required this.size,
    required this.modified,
  });
}
