                                        
  
              
                                                          
                                                  
                                            
                                    
                                                        
                                      
                                              
                        
                                                    
                                      
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:naviflash/services/cache_dirs.dart';
import 'package:naviflash/services/network_settings_service.dart';

abstract final class VideoJsonCache {
  static const String dirName = 'video_json_cache';

                           
  static const int _maxFiles = 400;

                               
                                                       
  static bool disabled = false;

  static Future<Directory> get _dir async {
    final appDir = await AppCacheDirs.root();
    final dir = Directory('${appDir.path}/$dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

                                                                 
  static String cacheKey(String key) =>
      md5.convert(utf8.encode(key.trim())).toString();

  static Future<File> _file(String key) async {
    final dir = await _dir;
    return File('${dir.path}/${cacheKey(key)}.json');
  }

                               
  static Future<void> save(String key, Map<String, dynamic> json) async {
    if (disabled) return;
    try {
      final file = await _file(key);
      await file.writeAsString(
        jsonEncode({'ts': DateTime.now().millisecondsSinceEpoch, 'data': json}),
        flush: true,
      );
      await _evictIfOverMax();
    } catch (e) {
      debugPrint('[VideoJsonCache] 写入缓存失败: $e');
    }
  }

                                                   
  static Future<Map<String, dynamic>?> load(
    String key, {
    required Duration ttl,
    bool allowStale = false,
  }) async {
    if (disabled) return null;
    try {
      final file = await _file(key);
      if (!await file.exists()) return null;
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map<String, dynamic>) return null;
      final ts = (raw['ts'] as num?)?.toInt() ?? 0;
      final data = raw['data'];
      if (data is! Map<String, dynamic>) return null;
      final fresh =
          DateTime.now().millisecondsSinceEpoch - ts < ttl.inMilliseconds;
      if (!fresh && !allowStale) {
                                  
        return null;
      }
      return data;
    } catch (e) {
      debugPrint('[VideoJsonCache] 读取缓存失败: $e');
      return null;
    }
  }

  static Future<int> totalSize() async {
    try {
      final dir = await _dir;
      if (!await dir.exists()) return 0;
      var total = 0;
      await for (final e in dir.list()) {
        if (e is File) total += await e.length().catchError((_) => 0);
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> count() async {
    try {
      final dir = await _dir;
      if (!await dir.exists()) return 0;
      var c = 0;
      await for (final e in dir.list()) {
        if (e is File) c++;
      }
      return c;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> clearAll() async {
    try {
      final dir = await _dir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  static Future<void> _evictIfOverMax() async {
    try {
      final dir = await _dir;
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();
      if (files.length <= _maxFiles) return;
      files.sort(
        (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),
      );
      for (final f in files.take(files.length - _maxFiles)) {
        await f.delete();
      }
    } catch (_) {}
  }
}

                                            
           
                                            

                                       
class VideoStreamCacheEntry {
  final String bvid;
  final int cid;
  final int qn;

                                           
  final String cover;

                                        
  final String kind;
  final String? videoFile;
  final String? audioFile;
  final String? streamFile;
  final int bytes;
  final DateTime savedAt;

  const VideoStreamCacheEntry({
    required this.bvid,
    required this.cid,
    required this.qn,
    this.cover = '',
    required this.kind,
    this.videoFile,
    this.audioFile,
    this.streamFile,
    required this.bytes,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'bvid': bvid,
    'cid': cid,
    'qn': qn,
    'cover': cover,
    'kind': kind,
    'videoFile': videoFile,
    'audioFile': audioFile,
    'streamFile': streamFile,
    'bytes': bytes,
    'savedAt': savedAt.millisecondsSinceEpoch,
  };

  factory VideoStreamCacheEntry.fromJson(Map<String, dynamic> json) {
    return VideoStreamCacheEntry(
      bvid: (json['bvid'] as String?) ?? '',
      cid: (json['cid'] as num?)?.toInt() ?? 0,
      qn: (json['qn'] as num?)?.toInt() ?? 0,
      cover: (json['cover'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? 'durl',
      videoFile: json['videoFile'] as String?,
      audioFile: json['audioFile'] as String?,
      streamFile: json['streamFile'] as String?,
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      savedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['savedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  bool get isDash => kind == 'dash';
}

abstract final class VideoStreamCache {
  static const String cacheDirName = 'video_cache';

                                  
  static const int maxBytes = 2 * 1024 * 1024 * 1024;

                               
  static final Map<String, Future<void>> _pending = {};

  static List<String> get pendingKeys => _pending.keys.toList(growable: false);
  static int get pendingCount => _pending.length;
  static bool isDownloading(String bvid, int cid) =>
      _pending.containsKey(keyOf(bvid, cid));
  static bool isDownloadingKey(String key) => _pending.containsKey(key);

                                        
  static final ValueNotifier<int> queueVersion = ValueNotifier(0);
  static void _bumpQueueVersion() => queueVersion.value++;

                                   
  static const Duration downloadAfterPlayed = Duration(seconds: 8);

                                          
  static const Map<String, String> _mediaHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  static String keyOf(String bvid, int cid) => '${bvid.trim()}_$cid';

  static Future<Directory> _dirFor(String key) async {
    final appDir = await AppCacheDirs.root();
    final dir = Directory('${appDir.path}/$cacheDirName/$key');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> _fileIn(String key, String name) async {
    final dir = await _dirFor(key);
    return File('${dir.path}/$name');
  }

                              
  static Future<VideoStreamCacheEntry?> lookup(String bvid, int cid) async {
    final key = keyOf(bvid, cid);
    try {
      final info = await _fileIn(key, 'info.json');
      if (!await info.exists()) return null;
      final raw = jsonDecode(await info.readAsString());
      if (raw is! Map<String, dynamic>) return null;
      final entry = VideoStreamCacheEntry.fromJson(raw);
                  
      if (entry.isDash) {
        if (entry.videoFile == null || entry.audioFile == null) return null;
        final v = await _fileIn(key, entry.videoFile!);
        final a = await _fileIn(key, entry.audioFile!);
        if (!await v.exists() || !await a.exists()) return null;
      } else {
        if (entry.streamFile == null) return null;
        final f = await _fileIn(key, entry.streamFile!);
        if (!await f.exists()) return null;
      }
      return entry;
    } catch (_) {
      return null;
    }
  }

                                                 
                                   
  static Future<String?> localPlayableUrl(String bvid, int cid) async {
    final entry = await lookup(bvid, cid);
    if (entry == null) return null;
    return entry.isDash ? _buildLocalEdl(entry) : _buildLocalFileUrl(entry);
  }

  static Future<String?> _buildLocalEdl(VideoStreamCacheEntry entry) async {
    final key = keyOf(entry.bvid, entry.cid);
    final v = await _fileIn(key, entry.videoFile!);
    final a = await _fileIn(key, entry.audioFile!);
    if (!await v.exists() || !await a.exists()) return null;
    final vUrl = Uri.file(v.path).toString();
    final aUrl = Uri.file(a.path).toString();
    return 'edl://'
        '!no_clip;!no_chapters;'
        '%${utf8.encode(vUrl).length}%$vUrl;'
        '!new_stream;!no_clip;!no_chapters;'
        '%${utf8.encode(aUrl).length}%$aUrl';
  }

  static Future<String?> _buildLocalFileUrl(VideoStreamCacheEntry entry) async {
    final key = keyOf(entry.bvid, entry.cid);
    final f = await _fileIn(key, entry.streamFile!);
    if (!await f.exists()) return null;
    return Uri.file(f.path).toString();
  }

                                                 
                                             
  static ({String a, String b})? parseEdl(String edl) {
    if (!edl.startsWith('edl://')) return null;
    final results = <String>[];
    var i = 'edl://'.length;
    final text = edl;
    while (i < text.length && results.length < 2) {
      final pct = text.indexOf('%', i);
      if (pct < 0) break;
      final lenStart = pct + 1;
      final pct2 = text.indexOf('%', lenStart);
      if (pct2 < 0) break;
      final len = int.tryParse(text.substring(lenStart, pct2));
      if (len == null || len <= 0) break;
      final urlStart = pct2 + 1;
      if (urlStart + len > text.length) break;
      results.add(text.substring(urlStart, urlStart + len));
      i = urlStart + len;
    }
    if (results.length < 2) return null;
    return (a: results[0], b: results[1]);
  }

                            
  static Future<void> cacheDash({
    required String bvid,
    required int cid,
    required String videoUrl,
    required String audioUrl,
    int qn = 0,
    String cover = '',
  }) async {
    final key = keyOf(bvid, cid);
    final pending = _pending[key];
    if (pending != null) return pending;
    final future = _cacheDashImpl(
      bvid: bvid,
      cid: cid,
      key: key,
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      qn: qn,
      cover: cover,
    );
    _pending[key] = future;
    _bumpQueueVersion();
    future.whenComplete(() {
      _pending.remove(key);
      _bumpQueueVersion();
    });
    return future;
  }

  static Future<void> _cacheDashImpl({
    required String bvid,
    required int cid,
    required String key,
    required String videoUrl,
    required String audioUrl,
    required int qn,
    required String cover,
  }) async {
    try {
      if (await _alreadyCached(key)) return;
      final dir = await _dirFor(key);
      const videoFile = 'video.mp4';
      const audioFile = 'audio.m4a';
      final vOk = await _download(videoUrl, File('${dir.path}/$videoFile'));
      if (!vOk) return;
      final aOk = await _download(audioUrl, File('${dir.path}/$audioFile'));
                                       
      if (!aOk) {
        try {
          await File('${dir.path}/$videoFile').delete();
        } catch (_) {}
        return;
      }
      var bytes = 0;
      try {
        bytes = await File('${dir.path}/$videoFile').length();
        bytes += await File('${dir.path}/$audioFile').length();
      } catch (_) {}
      await _writeInfo(
        key,
        VideoStreamCacheEntry(
          bvid: bvid,
          cid: cid,
          qn: qn,
          cover: cover,
          kind: 'dash',
          videoFile: videoFile,
          audioFile: audioFile,
          bytes: bytes,
          savedAt: DateTime.now(),
        ),
      );
      await _evictIfOverCap();
    } catch (e) {
      debugPrint('[VideoStreamCache] DASH 缓存失败: $e');
    }
  }

                             
  static Future<void> cacheDurl({
    required String bvid,
    required int cid,
    required String url,
    int qn = 0,
    String cover = '',
  }) async {
    final key = keyOf(bvid, cid);
    final pending = _pending[key];
    if (pending != null) return pending;
    final future = _cacheDurlImpl(
      bvid: bvid,
      cid: cid,
      key: key,
      url: url,
      qn: qn,
      cover: cover,
    );
    _pending[key] = future;
    _bumpQueueVersion();
    future.whenComplete(() {
      _pending.remove(key);
      _bumpQueueVersion();
    });
    return future;
  }

  static Future<void> _cacheDurlImpl({
    required String bvid,
    required int cid,
    required String key,
    required String url,
    required int qn,
    required String cover,
  }) async {
    try {
      if (await _alreadyCached(key)) return;
      final dir = await _dirFor(key);
      String ext;
      final lower = url.toLowerCase();
      if (lower.contains('.flv')) {
        ext = 'flv';
      } else {
        ext = 'mp4';
      }
      final streamFile = 'stream.$ext';
      final ok = await _download(url, File('${dir.path}/$streamFile'));
      if (!ok) return;
      var bytes = 0;
      try {
        bytes = await File('${dir.path}/$streamFile').length();
      } catch (_) {}
      await _writeInfo(
        key,
        VideoStreamCacheEntry(
          bvid: bvid,
          cid: cid,
          qn: qn,
          cover: cover,
          kind: 'durl',
          streamFile: streamFile,
          bytes: bytes,
          savedAt: DateTime.now(),
        ),
      );
      await _evictIfOverCap();
    } catch (e) {
      debugPrint('[VideoStreamCache] durl 缓存失败: $e');
    }
  }

  static Future<bool> _alreadyCached(String key) async {
    final info = await _fileIn(key, 'info.json');
    return await info.exists();
  }

  static Future<void> _writeInfo(
    String key,
    VideoStreamCacheEntry entry,
  ) async {
    final info = await _fileIn(key, 'info.json');
    await info.writeAsString(jsonEncode(entry.toJson()), flush: true);
  }

                                         
  static Future<bool> _download(String url, File file) async {
    try {
      final uri = Uri.parse(url);
                                                     
      final client = await NetworkSettingsService.instance.getApiClient();
      final req = http.Request('GET', uri)..headers.addAll(_mediaHeaders);
      final resp = await client.send(req).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        debugPrint('[VideoStreamCache] 下载失败 HTTP ${resp.statusCode}: $url');
        await resp.stream.drain<void>();
        try {
          await file.delete();
        } catch (_) {}
        return false;
      }
      final sink = file.openWrite();
      try {
        await resp.stream.pipe(sink);
      } finally {
        try {
          await sink.flush();
        } catch (_) {}
        await sink.close();
      }
      return true;
    } catch (e) {
      debugPrint('[VideoStreamCache] 下载异常: $e');
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
      return false;
    }
  }

                                              
                   
                                              

  static Future<int> totalSize() async {
    try {
      final appDir = await AppCacheDirs.root();
      final dir = Directory('${appDir.path}/$cacheDirName');
      if (!await dir.exists()) return 0;
      var total = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
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
      final appDir = await AppCacheDirs.root();
      final dir = Directory('${appDir.path}/$cacheDirName');
      if (!await dir.exists()) return 0;
      return _countEntries(dir);
    } catch (_) {
      return 0;
    }
  }

                                      
  static Future<List<VideoStreamCacheEntry>> listEntries() async {
    try {
      final appDir = await AppCacheDirs.root();
      final dir = Directory('${appDir.path}/$cacheDirName');
      if (!await dir.exists()) return const [];
      final result = <VideoStreamCacheEntry>[];
      await for (final e in dir.list()) {
        if (e is! Directory) continue;
        try {
          final info = File('${e.path}/info.json');
          if (!await info.exists()) continue;
          final raw = jsonDecode(await info.readAsString());
          if (raw is! Map<String, dynamic>) continue;
          final entry = VideoStreamCacheEntry.fromJson(raw);
                               
          if (entry.isDash) {
            if (entry.videoFile == null || entry.audioFile == null) continue;
          } else if (entry.streamFile == null) {
            continue;
          }
          result.add(entry);
        } catch (_) {}
      }
      result.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return result;
    } catch (_) {
      return const [];
    }
  }

                                      
  static Future<void> deleteEntry(VideoStreamCacheEntry entry) async {
    try {
      final appDir = await AppCacheDirs.root();
      final dir = Directory(
        '${appDir.path}/$cacheDirName/${keyOf(entry.bvid, entry.cid)}',
      );
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  static Future<void> deleteByBvid(String bvid) async {
    try {
      final entries = await listEntries();
      for (final e in entries.where((e) => e.bvid == bvid)) {
        await deleteEntry(e);
      }
    } catch (_) {}
  }

                     
  static Future<Map<String, List<VideoStreamCacheEntry>>> groupedByBvid() async {
    final entries = await listEntries();
    final map = <String, List<VideoStreamCacheEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.bvid, () => []).add(e);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.cid.compareTo(b.cid));
    }
    return map;
  }

  static int _countEntries(Directory dir) {
    var c = 0;
    try {
      for (final e in dir.listSync()) {
        if (e is Directory) {
          if (File('${e.path}/info.json').existsSync()) c++;
        }
      }
    } catch (_) {}
    return c;
  }

  static Future<void> clearAll() async {
    try {
      final appDir = await AppCacheDirs.root();
      final dir = Directory('${appDir.path}/$cacheDirName');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

                                    
  static Future<void> _evictIfOverCap() async {
    try {
      final appDir = await AppCacheDirs.root();
      final dir = Directory('${appDir.path}/$cacheDirName');
      if (!await dir.exists()) return;
      var total = 0;
      final entries = <Directory>[];
      await for (final e in dir.list()) {
        if (e is! Directory) continue;
        entries.add(e);
        total += await _dirSize(e);
      }
      if (total <= maxBytes) return;
      entries.sort((a, b) => _dirAge(a).compareTo(_dirAge(b)));
      for (final e in entries) {
        if (total <= maxBytes) break;
        final sz = await _dirSize(e);
        try {
          await e.delete(recursive: true);
          total -= sz;
        } catch (_) {}
      }
    } catch (_) {}
  }

  static DateTime _dirAge(Directory d) {
    try {
      final info = File('${d.path}/info.json');
      if (info.existsSync()) return info.lastModifiedSync();
    } catch (_) {}
    return d.existsSync() ? d.statSync().modified : DateTime.now();
  }

  static Future<int> _dirSize(Directory d) async {
    var sz = 0;
    try {
      await for (final e in d.list(recursive: true)) {
        if (e is File) sz += e.lengthSync();
      }
    } catch (_) {}
    return sz;
  }
}
