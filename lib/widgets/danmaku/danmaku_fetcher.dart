import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:protobuf/protobuf.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'danmaku_model.dart';

// ───────────────────────────────
//  结果 / 视频信息模型
// ───────────────────────────────
class DanmakuFetchResult {
  final bool success;
  final String? error;
  final List<DanmakuItem> items;
  final String? cid;
  final bool fromCache;
    final String? source;     //  NEW: 用户原始输入（BV 或 CID）
  final String? sourceType; //  NEW: 'bv' | 'cid'

  const DanmakuFetchResult({
    required this.success,
    this.error,
    required this.items,
    this.cid,
    this.fromCache = false,
        this.source,      //  NEW
    this.sourceType,  //  NEW
  });
}

class VideoPageInfo {
  final String cid;
  final int duration;
  final String title;

  VideoPageInfo({required this.cid, required this.duration, required this.title});
}

// ───────────────────────────────
//   NEW: 弹幕本地缓存管理
// ───────────────────────────────
class DanmakuCacheManager {
  static const String cacheDirName = 'danmaku_cache';
  static const int _maxCacheFiles = 50; // 最多缓存 50 个视频的弹幕

  /// 获取缓存目录（公开：云同步用）
  static Future<Directory> get cacheDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$cacheDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 根据 BV/CID 生成唯一缓存文件名（公开：云同步用）
  static String cacheKey(String source) {
    return md5.convert(utf8.encode(source.trim().toUpperCase())).toString();
  }

  /// 列出所有缓存文件（公开：云同步用）
  static Future<List<File>> listCachedFiles() async {
    try {
      final dir = await cacheDir;
      if (!await dir.exists()) return [];
      return dir.listSync().whereType<File>().toList();
    } catch (_) {
      return [];
    }
  }

  /// 获取缓存文件路径
  static Future<File> _cacheFile(String source) async {
    final dir = await cacheDir;
    return File('${dir.path}/${cacheKey(source)}.json');
  }

  /// 检查缓存是否存在
  static Future<bool> hasCache(String source) async {
    if (source.trim().isEmpty) return false;
    final file = await _cacheFile(source);
    return file.exists();
  }

  /// 从缓存加载弹幕
  static Future<List<DanmakuItem>?> loadFromCache(String source) async {
    try {
      final file = await _cacheFile(source);
      if (!await file.exists()) return null;

      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List;
      final items = list
          .map((e) => DanmakuItem.fromJson(e as Map<String, dynamic>))
          .toList();

      if (items.isEmpty) return null;
      debugPrint('[DanmakuCache] 命中缓存: $source → ${items.length} 条');
      return items;
    } catch (e) {
      debugPrint('[DanmakuCache] 读取缓存失败: $e');
      return null;
    }
  }

  /// 保存弹幕到缓存
  static Future<void> saveToCache(String source, List<DanmakuItem> items) async {
    try {
      final file = await _cacheFile(source);
      final data = jsonEncode(items.map((i) => i.toJson()).toList());
      await file.writeAsString(data);
      debugPrint('[DanmakuCache] 已缓存: $source → ${items.length} 条');

      // 清理过期缓存（保留最新的 _maxCacheFiles 个）
      await _evictOldEntries();
    } catch (e) {
      debugPrint('[DanmakuCache] 写入缓存失败: $e');
    }
  }

  /// 删除指定缓存
  static Future<void> removeCache(String source) async {
    try {
      final file = await _cacheFile(source);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// 清空所有弹幕缓存
  static Future<void> clearAll() async {
    try {
      final dir = await cacheDir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// 淘汰最旧的缓存文件
  static Future<void> _evictOldEntries() async {
    try {
      final dir = await cacheDir;
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      if (files.length <= _maxCacheFiles) return;

      // 按修改时间排序，删除最旧的
      files.sort((a, b) =>
          a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      final toDelete = files.length - _maxCacheFiles;
      for (int i = 0; i < toDelete; i++) {
        await files[i].delete();
      }
      debugPrint('[DanmakuCache] 已清理 $toDelete 个旧缓存');
    } catch (_) {}
  }
}

// ───────────────────────────────
//  纯 Dart 动态 Protobuf 解析 Fetcher（分段拉取 + 本地缓存）
// ───────────────────────────────
class DanmakuSegFetcher {
  static const String _pageListApi =
      'https://api.bilibili.com/x/player/pagelist';
  static const String _segApi =
      'https://api.bilibili.com/x/v2/dm/list/seg.so';

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  // ── 1. BV → CID + 时长 ──
  static Future<VideoPageInfo?> _fetchVideoInfo(String bv) async {
    try {
      final uri = Uri.parse(_pageListApi).replace(
        queryParameters: {'bvid': bv.trim()},
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            uri,
            headers: {
              ..._defaultHeaders,
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;

      final data = json['data'];
      if (data == null || data is! List || data.isEmpty) return null;

      return VideoPageInfo(
        cid: data[0]['cid'].toString(),
        duration: (data[0]['duration'] as num?)?.toInt() ?? 0,
        title: data[0]['part'] ?? '',
      );
    } catch (e) {
      debugPrint('[SegFetcher] 获取视频信息异常: $e');
      return null;
    }
  }

  // ── 2. 跳过未知字段 ──
  static void _skipField(CodedBufferReader reader, int wireType) {
    switch (wireType) {
      case WIRETYPE_VARINT:
        reader.readInt64();
        break;
      case WIRETYPE_FIXED64:
        reader.readFixed64();
        break;
      case WIRETYPE_LENGTH_DELIMITED:
        reader.readBytes();
        break;
      case WIRETYPE_FIXED32:
        reader.readFixed32();
        break;
      default:
        throw UnsupportedError('Unknown wire type: $wireType');
    }
  }

  // ── 3. 解析单个 DanmakuElem ──
  static DanmakuItem _parseDanmakuElem(List<int> bytes) {
    final reader = CodedBufferReader(bytes);
    int progress = 0;
    int mode = 1;
    int fontsize = 25;
    int color = 16777215;
    int weight = 0;
    String content = '';

    while (!reader.isAtEnd()) {
      final tag = reader.readTag();
      final fieldNumber = getTagFieldNumber(tag);
      final wireType = getTagWireType(tag);

      switch (fieldNumber) {
        case 2:
          progress = reader.readInt32();
          break;
        case 3:
          mode = reader.readInt32();
          break;
        case 4:
          fontsize = reader.readInt32();
          break;
        case 5:
          color = reader.readUint32();
          break;
        case 7:
          content = reader.readString();
          break;
        case 9:
          weight = reader.readInt32();
          break;
        default:
          _skipField(reader, wireType);
          break;
      }
    }

    return DanmakuItem.fromRaw(
      progressMs: progress,
      modeInt: mode,
      fontSizeInt: fontsize,
      colorInt: color,
      content: content,
      weight: weight,
    );
  }

  // ── 4. 解析 DmSegMobileReply ──
  static List<DanmakuItem> _parseSegReply(List<int> bytes) {
    final reader = CodedBufferReader(bytes);
    final items = <DanmakuItem>[];

    while (!reader.isAtEnd()) {
      final tag = reader.readTag();
      final fieldNumber = getTagFieldNumber(tag);
      final wireType = getTagWireType(tag);

      if (fieldNumber == 1 && wireType == WIRETYPE_LENGTH_DELIMITED) {
        final elemBytes = reader.readBytes();
        items.add(_parseDanmakuElem(elemBytes));
      } else {
        _skipField(reader, wireType);
      }
    }
    return items;
  }

  // ── 5. 拉取单个分段 ──
  static Future<List<DanmakuItem>> _fetchSegment(
    String cid,
    int segmentIndex,
  ) async {
    final uri = Uri.parse(_segApi).replace(queryParameters: {
      'type': '1',
      'oid': cid,
      'segment_index': segmentIndex.toString(),
    });

    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            uri,
            headers: {
              ..._defaultHeaders,
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        debugPrint('[SegFetcher] seg#$segmentIndex HTTP ${resp.statusCode}');
        return [];
      }

      final items = _parseSegReply(resp.bodyBytes);
      debugPrint('[SegFetcher] seg#$segmentIndex → ${items.length} 条');
      return items;
    } catch (e, st) {
      debugPrint('[SegFetcher] seg#$segmentIndex 异常: $e\n$st');
      return [];
    }
  }

// ── 6. 主入口（ 增加缓存逻辑）──
  static Future<DanmakuFetchResult> fetch({
    required String input,
    required String inputType,
    int maxConcurrent = 5,
    bool forceRefresh = false, //  NEW: 强制刷新，忽略缓存
  }) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return DanmakuFetchResult(
        success: false,
        error: L10n.current.danmakuInputEmpty,
        items: [],
      );
    }

//  NEW: 先尝试从本地缓存加载
    if (!forceRefresh) {
      final cached = await DanmakuCacheManager.loadFromCache(trimmed);
      if (cached != null && cached.isNotEmpty) {
        return DanmakuFetchResult(
          success: true,
          items: cached,
          cid: trimmed,
          fromCache: true,
            source: trimmed,
  sourceType: inputType,
        );
      }
    }

    late String cid;
    late int durationSec;

    if (inputType == 'bv') {
      final info = await _fetchVideoInfo(trimmed);
      if (info == null) {
        return DanmakuFetchResult(
          success: false,
          error: L10n.current.danmakuCidFetchFail,
          items: [],
        );
      }
      cid = info.cid;
      durationSec = info.duration;
    } else {
      cid = trimmed;
      durationSec = 0;
    }

    int segmentCount;
    if (durationSec > 0) {
      segmentCount = (durationSec / 360).ceil();
      if (segmentCount < 1) segmentCount = 1;
    } else {
      segmentCount = 10;
    }

    debugPrint('[SegFetcher] CID=$cid, 时长=${durationSec}s, 共$segmentCount段');

    final allItems = <DanmakuItem>[];

    for (var i = 0; i < segmentCount; i += maxConcurrent) {
      final end =
          (i + maxConcurrent < segmentCount) ? i + maxConcurrent : segmentCount;
      final futures = List.generate(
        end - i,
        (j) => _fetchSegment(cid, i + j + 1),
      );
      final segments = await Future.wait(futures);
      for (final seg in segments) {
        allItems.addAll(seg);
      }
    }

    allItems.sort((a, b) => a.time.compareTo(b.time));

    if (allItems.isEmpty) {
      return DanmakuFetchResult(
        success: false,
        error: L10n.current.danmakuNoData(cid),
        items: [],
        cid: cid,
      );
    }

//  NEW: 写入本地缓存（用原始输入作为 key，BV 和 CID 都能命中）
    await DanmakuCacheManager.saveToCache(trimmed, allItems);
    // 如果是 BV 模式，也用 CID 存一份，方便后续用 CID 查找
    if (inputType == 'bv' && cid != trimmed) {
      await DanmakuCacheManager.saveToCache(cid, allItems);
    }

    debugPrint('[SegFetcher] 总计 ${allItems.length} 条弹幕');
    return DanmakuFetchResult(
      success: true,
      items: allItems,
      cid: cid,
      fromCache: false,
        source: trimmed,        // 
  sourceType: inputType,  // 
    );
  }

  // ── 3. 发送弹幕（x/v2/dm/post，需登录 + bili_jct） ──
  static const String _dmPostApi = 'https://api.bilibili.com/x/v2/dm/post';

  /// 发送一条弹幕。
  /// [oid] 评论区 oid（视频为 aid）；[cid] 分P cid；[progress] 当前进度（毫秒）。
  /// 返回 (ok, message)；未登录/未开启携带 Cookie 时返回对应提示。
  static Future<({bool ok, String message})> sendDanmaku({
    required String oid,
    required String cid,
    required String msg,
    required int progress,
    int mode = 1,
    int color = 16777215,
    int fontSize = 25,
  }) async {
    final account = BilibiliAccountService.instance;
    final cookieHeader = account.cookieHeaderFor(BiliCookieScope.interactions);
    if (cookieHeader == null) {
      return (
        ok: false,
        message: account.isLoggedIn
            ? '请在账号设置中开启「携带 Cookie 请求」与「互动操作」范围'
            : '请先登录 B 站账号',
      );
    }
    final raw = account.rawCookie;
    final m = RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(raw);
    final csrf = m?.group(1) ?? '';
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_dmPostApi),
            headers: {
              ..._defaultHeaders,
              ...cookieHeader,
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'type': '1',
              'oid': oid,
              'cid': cid,
              'msg': msg,
              'progress': progress.toString(),
              'mode': mode.toString(),
              'color': color.toString(),
              'fontsize': fontSize.toString(),
              'pool': '0',
              'plat': '1',
              'csrf': csrf,
              'rnd': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          )
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (resp.statusCode != 200 || json['code'] != 0) {
        return (
          ok: false,
          message: resp.statusCode != 200
              ? 'HTTP ${resp.statusCode}'
              : '${json['message']}',
        );
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[SegFetcher] 发送弹幕异常: $e');
      return (ok: false, message: '$e');
    }
  }
}