// lib/services/image_cache_service.dart
//
// 图片下载缓存：评论配图/头像等原图首次下载后落盘到应用私有缓存目录
// （<应用文档目录>/image_cache），后续点击直接读本地文件，避免重复下载；
// 设置页「清理缓存」可一键清除（与弹幕缓存一起）。
// 提供三级图片加载：Flutter ImageCache 内存 → 本服务磁盘缓存 → 网络。
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';

abstract final class ImageCacheService {
  static const String _cacheDirName = 'image_cache';

  /// 图片缓存容量上限（字节，默认 300MB）。超出后按最后修改时间淘汰最旧，
  /// 避免缓存无限膨胀（设置页「清理缓存」可手动一键清除）。
  static const int maxCacheBytes = 300 * 1024 * 1024;

  /// 缓存目录（应用私有文档目录下，不跟随系统清理）。
  static Future<Directory> get cacheDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_cacheDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// URL → 缓存文件名（md5，文件内容不可预测）。
  static String cacheKey(String url) =>
      md5.convert(utf8.encode(url.trim())).toString();

  static Future<File> _cacheFile(String url) async {
    final dir = await cacheDir;
    return File('${dir.path}/${cacheKey(url)}.img');
  }

  /// 命中缓存返回文件，未命中返回 null。
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

  /// 保存到缓存（已存在则直接返回，避免覆盖）。
  static Future<File> save(String url, Uint8List bytes) async {
    final file = await _cacheFile(url);
    if (await file.exists()) return file;
    await file.writeAsBytes(bytes, flush: true);
    // 记录来源 URL 边车（<md5>.url）：供「已缓存图片」页透明展示来源
    await _writeUrlSidecar(url);
    // 落盘后触发容量上限淘汰（LRU）
    await _evictIfOverCap();
    return file;
  }

  /// 写入来源 URL 边车文件（与 .img 同前缀的 .url），供缓存查看页展示。
  static Future<void> _writeUrlSidecar(String url) async {
    try {
      final dir = await cacheDir;
      final f = File('${dir.path}/${cacheKey(url)}.url');
      await f.writeAsString(url, flush: true);
    } catch (_) {}
  }

  /// 容量上限淘汰：总大小超限时从最旧文件开始删除，直到不超过上限。
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
          // 连带删除来源 URL 边车
          if (f.path.endsWith('.img')) {
            final side = File('${f.path.substring(0, f.path.length - 4)}.url');
            if (await side.exists()) await side.delete();
          }
          total -= sz;
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// 缓存总大小（字节，仅统计 .img 图片本体，不含 URL 边车）。
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

  /// 缓存文件数量（仅 .img，不含 URL 边车）。
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

  /// 列出全部已缓存图片（按最近缓存时间倒序）。
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

  /// 删除单个已缓存图片（连同其 URL 边车）。
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

  /// 清空所有图片缓存，返回删除的图片（.img）数量（URL 边车一并删除）。
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

  // ═════════════════════════════════════════
  //  三级加载：磁盘 → 网络（含并发去重）
  // ═════════════════════════════════════════

  /// 进行中的下载（URL → Future），同一 URL 并发请求共享同一个下载，
  /// 避免评论区等长列表同时加载同一张图时重复请求。
  static final Map<String, Future<Uint8List?>> _pendingFetch = {};

  /// 拉取图片字节：先读磁盘缓存，未命中再走网络下载并落盘。
  /// 供 [CachedImageProvider] / 评论大图查看共用；[headers] 为可选请求头
  /// （为空时自动带 NetworkSettingsService 的 apiHeaders）。
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
      // ① 磁盘缓存命中：直接读本地文件
      final cached = await load(url);
      if (cached != null) {
        final bytes = await _readFile(cached);
        if (bytes != null) return bytes;
      }
      // ② 未命中：走共享网络客户端下载
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(url), headers: headers ?? _apiHeaders())
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return null;
      final bytes = resp.bodyBytes;
      // ③ 落盘缓存，下次直接读本地
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

/// 一条已缓存图片记录（供「已缓存图片」查看页透明展示）。
class ImageCacheEntry {
  final File file;
  final String url; // 来源 URL（边车记录；旧缓存可能为空）
  final int size;
  final DateTime modified;

  const ImageCacheEntry({
    required this.file,
    required this.url,
    required this.size,
    required this.modified,
  });
}
