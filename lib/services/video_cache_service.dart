// lib/services/video_cache_service.dart
//
// 视频缓存机制（新增）：
//   1. VideoJsonCache —— 视频详情 / 播放地址（playurl）的持久 JSON 缓存：
//      - 详情/播放地址首次拉取后落盘到应用私有目录（video_json_cache），
//        TTL 内直接读本地返回、不再请求接口；网络失败/数据异常时回退缓存
//        （即使过期）保证可看；设置页「清理缓存」可一键清除。
//   2. VideoStreamCache —— 播放过的视频流的自动离线缓存（video_cache）：
//      - 播放开始后（观看几秒）后台把当前视频的媒体流下载到本地，
//        容量上限（默认 2GB）+ LRU 淘汰；下次打开同一视频直接从本地文件
//        播放，不再从 CDN 拉取。
//      - DASH：分别下载视频轨 + 音频轨两个文件，按 mpv edl:// 语法再拼回；
//      - durl：下载单个 FLV/MP4 文件，直接本地播放。
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';

abstract final class VideoJsonCache {
  static const String dirName = 'video_json_cache';

  /// 最多缓存文件数，超出后按写入时间淘汰最旧。
  static const int _maxFiles = 400;

  /// 测试/特殊场景开关：置为 true 时跳过磁盘缓存
  /// （读取恒 miss、写入 no-op），与 ArticleCache.disabled 同款约定。
  static bool disabled = false;

  static Future<Directory> get _dir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// key（如 'detail_BVxxxx' / 'play_BVxxxx_1234_80'）→ 缓存文件名（md5）。
  static String cacheKey(String key) =>
      md5.convert(utf8.encode(key.trim())).toString();

  static Future<File> _file(String key) async {
    final dir = await _dir;
    return File('${dir.path}/${cacheKey(key)}.json');
  }

  /// 保存原始 JSON（含时间戳用于 TTL 判断）。
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

  /// 读取缓存；TTL 内命中返回，过期需 [allowStale] 才返回（网络失败回退用）。
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
        // 过期且不允许回退：不删除，留给网络失败时回退用
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

// ═════════════════════════════════════════
//  离线视频流缓存
// ═════════════════════════════════════════

/// 一条离线视频缓存记录（info.json 元数据，与媒体文件同目录）。
class VideoStreamCacheEntry {
  final String bvid;
  final int cid;
  final int qn;

  /// 视频封面图 URL（供「已缓存视频」页展示封面并用作 iOS 缩回动画）。
  final String cover;

  /// 'dash'（视频轨+音频轨两个文件）或 'durl'（单个文件）。
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

  /// 缓存容量上限（字节，默认 2GB；可通过修改此值调整）。
  static const int maxBytes = 2 * 1024 * 1024 * 1024;

  /// 后台下载并发去重：key → 下载 Future。
  static final Map<String, Future<void>> _pending = {};

  static List<String> get pendingKeys => _pending.keys.toList(growable: false);
  static int get pendingCount => _pending.length;
  static bool isDownloading(String bvid, int cid) =>
      _pending.containsKey(keyOf(bvid, cid));
  static bool isDownloadingKey(String key) => _pending.containsKey(key);

  /// 这里提供一个全局 ValueNotifier，下载开始/结束时递增。
  static final ValueNotifier<int> queueVersion = ValueNotifier(0);
  static void _bumpQueueVersion() => queueVersion.value++;

  /// 观看几秒以上才触发后台下载（避免误开/点一下就退的场景）。
  static const Duration downloadAfterPlayed = Duration(seconds: 8);

  /// 从 CDN 下载时携带的媒体请求头（B 站防盗链要求 Referer）。
  static const Map<String, String> _mediaHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  static String keyOf(String bvid, int cid) => '${bvid.trim()}_$cid';

  static Future<Directory> _dirFor(String key) async {
    final appDir = await getApplicationDocumentsDirectory();
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

  /// 读取某视频的离线缓存记录；不存在返回 null。
  static Future<VideoStreamCacheEntry?> lookup(String bvid, int cid) async {
    final key = keyOf(bvid, cid);
    try {
      final info = await _fileIn(key, 'info.json');
      if (!await info.exists()) return null;
      final raw = jsonDecode(await info.readAsString());
      if (raw is! Map<String, dynamic>) return null;
      final entry = VideoStreamCacheEntry.fromJson(raw);
      // 校验媒体文件仍存在
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

  /// 命中缓存时返回可直接交给播放器的本地 URL（file:// 或本地 edl://），
  /// 未命中返回 null（调用方使用远端地址并安排后台下载）。
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

  /// 解析 mpv edl:// 字符串，取出两条 URL（DASH 视频轨 + 音频轨）。
  /// `%len%url` 语法中 url 是精确 len 字节（可能含 `;`）。
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

  /// DASH：后台下载视频轨 + 音频轨到本地。
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
      // 音频失败：删掉视频，整体视为失败（保持无缓存状态，下次重试）
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

  /// durl：后台下载单个 FLV/MP4 文件。
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

  /// 流式下载 URL 到 [file]（边下边写盘，避免整文件驻留内存）。
  static Future<bool> _download(String url, File file) async {
    try {
      final uri = Uri.parse(url);
      // 同款客户端：走 NetworkSettingsService 的网络模式（镜像/代理等）
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

  // ═════════════════════════════════════════
  //  统计 / 清理 / LRU
  // ═════════════════════════════════════════

  static Future<int> totalSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
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
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/$cacheDirName');
      if (!await dir.exists()) return 0;
      return _countEntries(dir);
    } catch (_) {
      return 0;
    }
  }

  /// 列出全部离线缓存视频（按保存时间倒序，供「已缓存视频」查看页）。
  static Future<List<VideoStreamCacheEntry>> listEntries() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
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
          // 校验媒体文件仍存在，避免展示残缺缓存
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

  /// 删除单条离线缓存（整目录，含 info.json 与媒体文件）。
  static Future<void> deleteEntry(VideoStreamCacheEntry entry) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
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

  /// 展示“××个视频”的合集卡片。
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
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/$cacheDirName');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// 容量上限淘汰：总大小超限时，从最早保存的记录开始整目录删除。
  static Future<void> _evictIfOverCap() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
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
