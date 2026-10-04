                                       
  
                           
                                                       
                                       
                                    
                                        
                                         
                                                 
  
                                                         
                               
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:naviflash/services/live_update_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/storage_paths.dart';
import 'package:naviflash/services/video_cache_service.dart';

                                 
class _CacheJob {
  final String key;
  final String bvid;
  final int cid;
  final String kind;                   
  final String? videoUrl;
  final String? audioUrl;
  final String? durlUrl;
  final int qn;
  final String cover;
  final String title;
  final Completer<void> completer = Completer<void>();

  _CacheJob({
    required this.key,
    required this.bvid,
    required this.cid,
    required this.kind,
    this.videoUrl,
    this.audioUrl,
    this.durlUrl,
    required this.qn,
    required this.cover,
    required this.title,
  });
}

abstract final class ManualVideoCache {
                                     
  static const String cacheDirName = 'manual_video_cache';

                                    
  static const int _notificationId = 4801;

                                             
  static final Map<String, Future<void>> _pending = {};

                
  static final List<_CacheJob> _queue = [];
  static bool _processing = false;

  static int get pendingCount => _pending.length;
  static bool isDownloading(String bvid, int cid) =>
      _pending.containsKey(keyOf(bvid, cid));
  static bool isDownloadingKey(String key) => _pending.containsKey(key);

                                     
  static bool anyDownloading(String bvid, int cid) =>
      isDownloading(bvid, cid) || VideoStreamCache.isDownloading(bvid, cid);
  static int get allPendingCount =>
      _pending.length + VideoStreamCache.pendingCount;

  static String keyOf(String bvid, int cid) => '${bvid.trim()}_$cid';

                            
  static bool get _isEn => Platform.localeName.toLowerCase().startsWith('en');
  static String get _tVideo => _isEn ? 'Video track' : '视频轨';
  static String get _tAudio => _isEn ? 'Audio track' : '音频轨';
  static String get _tPrepare => _isEn ? 'Preparing…' : '准备下载…';
  static String get _tDone => _isEn ? 'Download complete' : '下载完成';
  static String get _tFailed => _isEn ? 'Download failed' : '下载失败';
  static String get _tQueued => _isEn ? 'Queued' : '排队中';

  static String _trimTitle(String title) =>
      title.length > 40 ? '${title.substring(0, 40)}…' : title;

                                              
                          
                                              

  static Future<void> cacheDash({
    required String bvid,
    required int cid,
    required String videoUrl,
    required String audioUrl,
    int qn = 0,
    String cover = '',
    required String title,
  }) {
    return _enqueue(_CacheJob(
      key: keyOf(bvid, cid),
      bvid: bvid,
      cid: cid,
      kind: 'dash',
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      qn: qn,
      cover: cover,
      title: title,
    ));
  }

  static Future<void> cacheDurl({
    required String bvid,
    required int cid,
    required String url,
    int qn = 0,
    String cover = '',
    required String title,
  }) {
    return _enqueue(_CacheJob(
      key: keyOf(bvid, cid),
      bvid: bvid,
      cid: cid,
      kind: 'durl',
      durlUrl: url,
      qn: qn,
      cover: cover,
      title: title,
    ));
  }

  static Future<void> _enqueue(_CacheJob job) {
    final existing = _pending[job.key];
    if (existing != null) return existing;
    _pending[job.key] = job.completer.future;
    _queue.add(job);
    VideoStreamCache.queueVersion.value++;
    _ensureProcessing();
    return job.completer.future;
  }

                                 
  static Future<void> _ensureProcessing() async {
    if (_processing) return;
    _processing = true;
    try {
      while (_queue.isNotEmpty) {
        final job = _queue.removeAt(0);
        await _runJob(job);
      }
    } finally {
      _processing = false;
    }
  }

  static Future<void> _runJob(_CacheJob job) async {
    final noteTitle = _trimTitle(job.title);
    try {
                             
      if (await _alreadyCached(job.key)) {
        return;
      }
                             
      final coverBytes =
          job.cover.isNotEmpty ? await _fetchCover(job.cover) : null;
      final remaining = _queue.length;
      await LiveUpdateService.start(
        _notificationId,
        noteTitle,
        text: remaining > 0 ? '$_tPrepare · $_tQueued $remaining' : _tPrepare,
        coverBytes: coverBytes,
      );

      final bool ok;
      if (job.kind == 'dash') {
        ok = await _runDash(job);
      } else {
        ok = await _runDurl(job);
      }

      if (ok) {
        if (_queue.isEmpty) {
                              
          await LiveUpdateService.finish(
            _notificationId,
            title: noteTitle,
            text: _tDone,
          );
        }
                                                  
                        
      } else {
        await LiveUpdateService.fail(
          _notificationId,
          title: noteTitle,
          text: _tFailed,
        );
                                       
                                       
        if (_queue.isNotEmpty) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      debugPrint('[ManualVideoCache] 任务异常: $e');
      await LiveUpdateService.fail(
        _notificationId,
        title: noteTitle,
        text: _tFailed,
      );
      if (_queue.isNotEmpty) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    } finally {
      _pending.remove(job.key);
      VideoStreamCache.queueVersion.value++;
      if (!job.completer.isCompleted) job.completer.complete();
    }
  }

  static Future<bool> _runDash(_CacheJob job) async {
    final dir = await _dirFor(job.key);
    const videoFile = 'video.mp4';
    const audioFile = 'audio.m4a';

    final vOk = await _downloadWithProgress(
      job.videoUrl!,
      File('${dir.path}/$videoFile'),
      onProgress: progressReporter(0, 50, _tVideo),
    );
    if (!vOk) return false;

    final aOk = await _downloadWithProgress(
      job.audioUrl!,
      File('${dir.path}/$audioFile'),
      onProgress: progressReporter(50, 50, _tAudio),
    );
    if (!aOk) {
      try {
        await File('${dir.path}/$videoFile').delete();
      } catch (_) {}
      return false;
    }

    var bytes = 0;
    try {
      bytes = await File('${dir.path}/$videoFile').length();
      bytes += await File('${dir.path}/$audioFile').length();
    } catch (_) {}
    await _writeInfo(
      job.key,
      VideoStreamCacheEntry(
        bvid: job.bvid,
        cid: job.cid,
        qn: job.qn,
        cover: job.cover,
        kind: 'dash',
        videoFile: videoFile,
        audioFile: audioFile,
        bytes: bytes,
        savedAt: DateTime.now(),
      ),
    );
    return true;
  }

  static Future<bool> _runDurl(_CacheJob job) async {
    final dir = await _dirFor(job.key);
    final ext = job.durlUrl!.toLowerCase().contains('.flv') ? 'flv' : 'mp4';
    final streamFile = 'stream.$ext';
    final ok = await _downloadWithProgress(
      job.durlUrl!,
      File('${dir.path}/$streamFile'),
      onProgress: progressReporter(0, 100, null),
    );
    if (!ok) return false;
    var bytes = 0;
    try {
      bytes = await File('${dir.path}/$streamFile').length();
    } catch (_) {}
    await _writeInfo(
      job.key,
      VideoStreamCacheEntry(
        bvid: job.bvid,
        cid: job.cid,
        qn: job.qn,
        cover: job.cover,
        kind: 'durl',
        streamFile: streamFile,
        bytes: bytes,
        savedAt: DateTime.now(),
      ),
    );
    return true;
  }

                                 
                                                 
                                   
  static void Function(int received, int total) progressReporter(
    int base,
    int span,
    String? phase,
  ) {
    var lastPercent = -1;
    return (int received, int total) {
      if (total <= 0) {
        LiveUpdateService.update(_notificationId,
            progress: base, text: phase, indeterminate: true);
        return;
      }
      final percent =
          (base + (received / total * span).clamp(0, span)).round();
      if (lastPercent == percent) return;
      lastPercent = percent;
      final sizeText = phase == null
          ? '$percent% · ${_mb(received)}/${_mb(total)}'
          : '$phase $percent% · ${_mb(received)}';
      LiveUpdateService.update(_notificationId,
          progress: percent, text: sizeText, indeterminate: false);
    };
  }

  static String _mb(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    return '${bytes}B';
  }

                                              
  static Future<Uint8List?> _fetchCover(String url) async {
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client.get(
        Uri.parse(url),
        headers: const {'Referer': 'https://www.bilibili.com'},
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        return resp.bodyBytes;
      }
    } catch (e) {
      debugPrint('[ManualVideoCache] 封面下载失败: $e');
    }
    return null;
  }

                                              
                 
                                              

                                      
  static Future<Directory> _writeRoot() =>
      StoragePaths.rootFor(StorageSlot.video);

                                 
                                       
  static Future<List<Directory>> _allRoots() =>
      StoragePaths.readRootsFor(StorageSlot.video);

  static Future<Directory> _dirFor(String key) async {
    final appDir = await _writeRoot();
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

  static Future<bool> _alreadyCached(String key) async {
    final info = await _fileIn(key, 'info.json');
    return info.exists();
  }

  static Future<void> _writeInfo(
    String key,
    VideoStreamCacheEntry entry,
  ) async {
    final info = await _fileIn(key, 'info.json');
    await info.writeAsString(jsonEncode(entry.toJson()), flush: true);
  }

  static const Map<String, String> _mediaHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

                                   
  static Future<bool> _downloadWithProgress(
    String url,
    File file, {
    required void Function(int received, int total) onProgress,
  }) async {
    try {
      final uri = Uri.parse(url);
      final client = await NetworkSettingsService.instance.getApiClient();
      final req = http.Request('GET', uri)..headers.addAll(_mediaHeaders);
      final resp = await client.send(req).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        debugPrint(
            '[ManualVideoCache] 下载失败 HTTP ${resp.statusCode}: $url');
        await resp.stream.drain<void>();
        try {
          await file.delete();
        } catch (_) {}
        return false;
      }
      final total = resp.contentLength ?? 0;
      var received = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in resp.stream) {
          received += chunk.length;
          sink.add(chunk);
          onProgress(received, total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      return true;
    } catch (e) {
      debugPrint('[ManualVideoCache] 下载异常: $e');
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
      return false;
    }
  }

                                              
                         
                                              

  static Future<VideoStreamCacheEntry?> lookup(String bvid, int cid) async {
    final key = keyOf(bvid, cid);
    return _lookupKey(key);
  }

  static Future<VideoStreamCacheEntry?> _lookupKey(String key) async {
                                   
    final primary = await _lookupKeyIn(await _writeRoot(), key);
    if (primary != null) return primary;
    for (final root in await _allRoots()) {
      final hit = await _lookupKeyIn(root, key);
      if (hit != null) return hit;
    }
    return null;
  }

  static Future<VideoStreamCacheEntry?> _lookupKeyIn(
    Directory root,
    String key,
  ) async {
    File fileIn(String name) => File('${root.path}/$cacheDirName/$key/$name');
    try {
      final info = fileIn('info.json');
      if (!await info.exists()) return null;
      final raw = jsonDecode(await info.readAsString());
      if (raw is! Map<String, dynamic>) return null;
      final entry = VideoStreamCacheEntry.fromJson(raw);
      if (entry.isDash) {
        if (entry.videoFile == null || entry.audioFile == null) return null;
        final v = fileIn(entry.videoFile!);
        final a = fileIn(entry.audioFile!);
        if (!await v.exists() || !await a.exists()) return null;
      } else {
        if (entry.streamFile == null) return null;
        final f = fileIn(entry.streamFile!);
        if (!await f.exists()) return null;
      }
      return entry;
    } catch (_) {
      return null;
    }
  }

                                   
  static Future<Directory?> _rootOfExistingKey(String key) async {
    for (final root in await _allRoots()) {
      final info = File('${root.path}/$cacheDirName/$key/info.json');
      if (await info.exists()) return root;
    }
    return null;
  }

  static Future<String?> localPlayableUrl(String bvid, int cid) async {
    final key = keyOf(bvid, cid);
    final entry = await _lookupKey(key);
    if (entry == null) return null;
    final root = await _rootOfExistingKey(key);
    if (root == null) return null;
    File fileIn(String name) => File('${root.path}/$cacheDirName/$key/$name');
    if (entry.isDash) {
      final v = fileIn(entry.videoFile!);
      final a = fileIn(entry.audioFile!);
      if (!await v.exists() || !await a.exists()) return null;
      final vUrl = Uri.file(v.path).toString();
      final aUrl = Uri.file(a.path).toString();
      return 'edl://'
          '!no_clip;!no_chapters;'
          '%${utf8.encode(vUrl).length}%$vUrl;'
          '!new_stream;!no_clip;!no_chapters;'
          '%${utf8.encode(aUrl).length}%$aUrl';
    }
    final f = fileIn(entry.streamFile!);
    if (!await f.exists()) return null;
    return Uri.file(f.path).toString();
  }

  static Future<List<VideoStreamCacheEntry>> listEntries() async {
    try {
      final result = <VideoStreamCacheEntry>[];
      final seen = <String>{};
      for (final appDir in await _allRoots()) {
        final dir = Directory('${appDir.path}/$cacheDirName');
        if (!await dir.exists()) continue;
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
                                          
            if (seen.add(keyOf(entry.bvid, entry.cid))) result.add(entry);
          } catch (_) {}
        }
      }
      result.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return result;
    } catch (_) {
      return const [];
    }
  }

  static Future<int> totalSize() async {
    try {
      var total = 0;
      for (final appDir in await _allRoots()) {
        final dir = Directory('${appDir.path}/$cacheDirName');
        if (!await dir.exists()) continue;
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            total += await entity.length().catchError((_) => 0);
          }
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> count() async => (await listEntries()).length;

  static Future<void> deleteEntry(VideoStreamCacheEntry entry) async {
    final key = keyOf(entry.bvid, entry.cid);
    for (final appDir in await _allRoots()) {
      try {
        final dir = Directory('${appDir.path}/$cacheDirName/$key');
        if (await dir.exists()) await dir.delete(recursive: true);
      } catch (_) {}
    }
  }

  static Future<void> deleteByBvid(String bvid) async {
    try {
      for (final e in (await listEntries()).where((e) => e.bvid == bvid)) {
        await deleteEntry(e);
      }
    } catch (_) {}
  }

  static Future<void> clearAll() async {
    for (final appDir in await _allRoots()) {
      try {
        final dir = Directory('${appDir.path}/$cacheDirName');
        if (await dir.exists()) await dir.delete(recursive: true);
      } catch (_) {}
    }
  }

                                              
                                                   
                         
                                              

                                  
  static Future<bool> isCachedAny(String bvid, int cid) async {
    if (await lookup(bvid, cid) != null) return true;
    if (await VideoStreamCache.lookup(bvid, cid) != null) return true;
    return false;
  }

                            
  static Future<String?> localPlayableUrlAny(String bvid, int cid) async {
    final manual = await localPlayableUrl(bvid, cid);
    if (manual != null) return manual;
    return VideoStreamCache.localPlayableUrl(bvid, cid);
  }

                         
  static Future<List<VideoStreamCacheEntry>> listAllEntries() async {
    final result = [
      ...await listEntries(),
      ...await VideoStreamCache.listEntries(),
    ];
    result.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return result;
  }

  static Future<int> totalAllSize() async =>
      await totalSize() + await VideoStreamCache.totalSize();

  static Future<int> totalAllCount() async =>
      await count() + await VideoStreamCache.count();

                      
  static Future<void> deleteEntryAny(VideoStreamCacheEntry entry) async {
    await deleteEntry(entry);
    await VideoStreamCache.deleteEntry(entry);
  }

  static Future<void> deleteByBvidAny(String bvid) async {
    await deleteByBvid(bvid);
    await VideoStreamCache.deleteByBvid(bvid);
  }

  static Future<void> clearAllBoth() async {
    await clearAll();
    await VideoStreamCache.clearAll();
  }
}
