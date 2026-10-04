import 'package:naviflash/utils/json_decode.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:naviflash/services/cache_dirs.dart';
import 'package:crypto/crypto.dart';
import 'package:protobuf/protobuf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_dm_block_service.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'danmaku_model.dart';

                                  
               
                                  
class DanmakuFetchResult {
  final bool success;
  final String? error;
  final List<DanmakuItem> items;
  final String? cid;
  final bool fromCache;
    final String? source;                              
  final String? sourceType;                      

  const DanmakuFetchResult({
    required this.success,
    this.error,
    required this.items,
    this.cid,
    this.fromCache = false,
        this.source,             
    this.sourceType,         
  });
}

class VideoPageInfo {
  final String cid;
  final int duration;
  final String title;

  VideoPageInfo({required this.cid, required this.duration, required this.title});
}

                                  
                  
                                  
class DanmakuCacheManager {
  static const String cacheDirName = 'danmaku_cache';
  static const int _maxCacheFiles = 50;                  

                     
  static Future<Directory> get cacheDir async {
    final appDir = await AppCacheDirs.root();
    final dir = Directory('${appDir.path}/$cacheDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

                                  
  static String cacheKey(String source) {
    return md5.convert(utf8.encode(source.trim().toUpperCase())).toString();
  }

                       
  static Future<List<File>> listCachedFiles() async {
    try {
      final dir = await cacheDir;
      if (!await dir.exists()) return [];
      return dir.listSync().whereType<File>().toList();
    } catch (_) {
      return [];
    }
  }

              
  static Future<File> _cacheFile(String source) async {
    final dir = await cacheDir;
    return File('${dir.path}/${cacheKey(source)}.json');
  }

              
  static Future<bool> hasCache(String source) async {
    if (source.trim().isEmpty) return false;
    final file = await _cacheFile(source);
    return file.exists();
  }

             
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

             
  static Future<void> saveToCache(String source, List<DanmakuItem> items) async {
    try {
      final file = await _cacheFile(source);
      final data = jsonEncode(items.map((i) => i.toJson()).toList());
      await file.writeAsString(data);
      debugPrint('[DanmakuCache] 已缓存: $source → ${items.length} 条');

                                       
      await _evictOldEntries();
    } catch (e) {
      debugPrint('[DanmakuCache] 写入缓存失败: $e');
    }
  }

            
  static Future<void> removeCache(String source) async {
    try {
      final file = await _cacheFile(source);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

              
  static Future<void> clearAll() async {
    try {
      final dir = await cacheDir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

               
  static Future<void> _evictOldEntries() async {
    try {
      final dir = await cacheDir;
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      if (files.length <= _maxCacheFiles) return;

                      
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
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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

                              
                             
                                                      
                                                           
                                          
  static (DanmakuItem, String) _parseDanmakuElem(List<int> bytes) {
    final reader = CodedBufferReader(bytes);
    int progress = 0;
    int mode = 1;
    int fontsize = 25;
    int color = 16777215;
    int weight = 0;
    String midHash = '';
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
        case 6:
          midHash = reader.readString();
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

    return (
      DanmakuItem.fromRaw(
        progressMs: progress,
        modeInt: mode,
        fontSizeInt: fontsize,
        colorInt: color,
        content: content,
        weight: weight,
      ),
      midHash,
    );
  }

                                 
  static List<(DanmakuItem, String)> _parseSegReply(List<int> bytes) {
    final reader = CodedBufferReader(bytes);
    final items = <(DanmakuItem, String)>[];

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

                    
  static Future<List<(DanmakuItem, String)>> _fetchSegment(
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

                       
                                                                   
                                       
                                                                   

                                   
  static bool _mergeDanmakuEnabled = false;
  static bool get mergeDanmakuEnabled => _mergeDanmakuEnabled;

  static Future<void> loadMergeDanmakuPref() async {
    final prefs = await SharedPreferences.getInstance();
    _mergeDanmakuEnabled = prefs.getBool('danmaku_merge_enabled') ?? false;
  }

  static Future<void> setMergeDanmakuEnabled(bool value) async {
    _mergeDanmakuEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('danmaku_merge_enabled', value);
  }

                                         
                                             
                               
  static List<DanmakuItem> mergeDanmakuItems(
    List<DanmakuItem> items, {
    int windowSec = 360,
  }) {
    final out = <DanmakuItem>[];
    final indexOfKey = <String, int>{};
    for (final item in items) {
      if (item.mode == DanmakuMode.advanced) {
        out.add(item);
        continue;
      }
      final window = item.time >= 0 ? item.time ~/ windowSec : 0;
      final key = '$window\u0000${item.content}';
      final existing = indexOfKey[key];
      if (existing == null) {
        indexOfKey[key] = out.length;
        out.add(item);
      } else {
        final first = out[existing];
        out[existing] = DanmakuItem(
          time: first.time,
          mode: first.mode,
          fontSize: first.fontSize,
          color: first.color,
          content: first.content,
          weight: first.weight,
          count: first.count + 1,
        );
      }
    }
    return out;
  }

  static Future<DanmakuFetchResult> fetch({
    required String input,
    required String inputType,
    int maxConcurrent = 5,
    bool forceRefresh = false,                   
  }) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return DanmakuFetchResult(
        success: false,
        error: L10n.current.danmakuInputEmpty,
        items: [],
      );
    }

                                                
    await loadMergeDanmakuPref();

                   
    if (!forceRefresh) {
      final cached = await DanmakuCacheManager.loadFromCache(trimmed);
      if (cached != null && cached.isNotEmpty) {
                                                 
        final filtered = await filterCachedItems(cached);
        final shown = mergeDanmakuEnabled
            ? mergeDanmakuItems(filtered)
            : filtered;
        return DanmakuFetchResult(
          success: true,
          items: shown,
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

    final parsed = <(DanmakuItem, String)>[];

    for (var i = 0; i < segmentCount; i += maxConcurrent) {
      final end =
          (i + maxConcurrent < segmentCount) ? i + maxConcurrent : segmentCount;
      final futures = List.generate(
        end - i,
        (j) => _fetchSegment(cid, i + j + 1),
      );
      final segments = await Future.wait(futures);
      for (final seg in segments) {
        parsed.addAll(seg);
      }
    }

    final allItems = [for (final e in parsed) e.$1];
    allItems.sort((a, b) => a.time.compareTo(b.time));

    if (allItems.isEmpty) {
      return DanmakuFetchResult(
        success: false,
        error: L10n.current.danmakuNoData(cid),
        items: [],
        cid: cid,
      );
    }

                                          
                                           
    await DanmakuCacheManager.saveToCache(trimmed, allItems);
                                        
    if (inputType == 'bv' && cid != trimmed) {
      await DanmakuCacheManager.saveToCache(cid, allItems);
    }

                            
    final blockedItems = await _applyCloudBlockRules(parsed);
                                    
    final shownItems = mergeDanmakuEnabled
        ? mergeDanmakuItems(blockedItems)
        : blockedItems;

    debugPrint(
      '[SegFetcher] 总计 ${allItems.length} 条弹幕'
      '${shownItems.length != allItems.length ? '，云屏蔽词过滤后 ${shownItems.length} 条' : ''}',
    );
    return DanmakuFetchResult(
      success: true,
      items: shownItems,
      cid: cid,
      fromCache: false,
        source: trimmed,          
  sourceType: inputType,    
    );
  }

                                         
                            
                                             
                                                                   
  static Future<List<DanmakuItem>> _applyCloudBlockRules(
    List<(DanmakuItem, String)> parsed,
  ) async {
    final rules = await BilibiliDmBlockService.rulesForDanmakuFiltering();
    if (rules.isEmpty) return [for (final e in parsed) e.$1];
    final out = <DanmakuItem>[];
    for (final (item, midHash) in parsed) {
      final blocked = BilibiliDmBlockService.isBlocked(
        BiliDmBlockItem(item.content, uidHash: midHash),
        rules,
      );
      if (!blocked) out.add(item);
    }
    return out;
  }

                             
                          
  static Future<List<DanmakuItem>> filterCachedItems(
    List<DanmakuItem> items,
  ) async {
    final rules = await BilibiliDmBlockService.rulesForDanmakuFiltering();
    if (rules.isEmpty) return items;
    return items
        .where(
          (it) => !BilibiliDmBlockService.isBlocked(
            BiliDmBlockItem(it.content),
            rules,
          ),
        )
        .toList();
  }

                                               
  static const String _dmPostApi = 'https://api.bilibili.com/x/v2/dm/post';

             
                                                              
                                                
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
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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