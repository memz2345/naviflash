                                             
  
                                                                       
                                                                
                                                                
                                                                     
                                                  
                                                                    
                                                                       
                                                                                 
                                                                     
                                                                   
                                                  
                                                  
                                                      
                                             
                                                           
                                      
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'bilibili_account_service.dart';
import 'bilibili_api_helpers.dart';
import 'bilibili_user_space_service.dart';
import 'network_settings_service.dart';
import 'watch_history_service.dart';

                                           
          
                                           

int _toInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}

String _toStr(dynamic v) => v?.toString() ?? '';

String _fixCover(String url) {
  final t = url.trim();
  if (t.isEmpty) return '';
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  if (t.startsWith('//')) return 'https:$t';
  return 'https://$t';
}

                                           
      
                                           

                                               
class BiliCloudHistoryItem {
  final String bvid;

                            
  final int? aid;
  final int? cid;
  final int? epid;
  final String title;
  final String cover;
  final String upperName;

                   
  final int viewedAtSec;

                                    
  final int progressSec;

               
  final int durationSec;

  bool get finished => progressSec < 0;

  const BiliCloudHistoryItem({
    required this.bvid,
    this.aid,
    this.cid,
    this.epid,
    required this.title,
    required this.cover,
    required this.upperName,
    required this.viewedAtSec,
    required this.progressSec,
    required this.durationSec,
  });

  factory BiliCloudHistoryItem.fromJson(Map<String, dynamic> json) {
    final history = (json['history'] as Map<String, dynamic>?) ?? const {};
                                           
    final part = _toStr(history['part']).trim();
    var title = _toStr(json['title']).trim();
    if (title.isEmpty) title = part;
    return BiliCloudHistoryItem(
      bvid: _toStr(history['bvid']),
      aid: history['oid'] is num ? (history['oid'] as num).toInt() : null,
      cid: history['cid'] is num && (history['cid'] as num).toInt() != 0
          ? (history['cid'] as num).toInt()
          : null,
      epid: history['epid'] is num && (history['epid'] as num).toInt() != 0
          ? (history['epid'] as num).toInt()
          : null,
      title: title,
      cover: _fixCover(_toStr(json['cover'])),
      upperName: _toStr(json['author_name']),
      viewedAtSec: _toInt(json['view_at']),
      progressSec: _toInt(json['progress']),
      durationSec: _toInt(json['duration']),
    );
  }

                                                                    
  WatchHistoryEntry toWatchHistoryEntry() {
    final durMs = durationSec > 0 ? durationSec * 1000 : 0;
                                              
                                                
                             
    final posMs = progressSec < 0 ? durMs : progressSec * 1000;
    return WatchHistoryEntry(
      bvid: bvid,
      aid: aid,
      cid: cid,
      epid: epid,
      title: title,
      coverUrl: cover.isEmpty ? null : cover,
      upperName: upperName.isEmpty ? null : upperName,
      positionMs: posMs,
      durationMs: durMs,
      watchedAt: DateTime.fromMillisecondsSinceEpoch(viewedAtSec * 1000),
      finished: finished,
    );
  }
}

             
class BiliCloudHistoryPage {
  final List<BiliCloudHistoryItem> items;

                             
  final bool hasMore;

                             
  final int nextMax;

                                 
  final int nextViewAt;

                                
  final int code;

                      
  final String? err;

  const BiliCloudHistoryPage({
    required this.items,
    required this.hasMore,
    required this.nextMax,
    required this.nextViewAt,
    required this.code,
    this.err,
  });
}

                                           
      
                                           

abstract final class BilibiliHistoryService {
  static const String _api =
      'https://api.bilibili.com/x/web-interface/history/cursor';

                                                               
                                                  
                                                                      
  static const String _deleteApi = 'https://api.bilibili.com/x/v2/history/delete';

                                        
  static const String _clearApi = 'https://api.bilibili.com/x/v2/history/clear';

  static const Map<String, String> _webHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

                                       
                              
  static bool get canUse =>
      BilibiliAccountService.instance.cookieHeaderFor(BiliCookieScope.video) !=
      null;

  static Map<String, String> _headers() {
    final cookie = BilibiliAccountService.instance
        .cookieHeaderFor(BiliCookieScope.video)
        ?['Cookie'];
    return {
      ..._webHeaders,
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

                                     
                                                                         
                             
  static Future<BiliCloudHistoryPage> fetchPage({
    int max = 0,
    int viewAt = 0,
    int ps = 20,
  }) async {
    if (!canUse) {
      return const BiliCloudHistoryPage(
        items: [],
        hasMore: false,
        nextMax: 0,
        nextViewAt: 0,
        code: -101,
        err: '尚未登录 B 站账号',
      );
    }
    try {
      final params = await WbiSign.sign({
        'type': 'archive',                               
        'ps': ps.toString(),
        'business': '',
        'max': max.toString(),
        'view_at': viewAt.toString(),
      });
      final uri = Uri.parse(_api).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return BiliCloudHistoryPage(
          items: const [],
          hasMore: false,
          nextMax: 0,
          nextViewAt: 0,
          code: resp.statusCode,
          err: 'HTTP ${resp.statusCode}',
        );
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return const BiliCloudHistoryPage(
          items: [],
          hasMore: false,
          nextMax: 0,
          nextViewAt: 0,
          code: -1,
          err: '返回内容不是 JSON 对象',
        );
      }
      final code = _toInt(json['code']);
      if (code != 0) {
        return BiliCloudHistoryPage(
          items: const [],
          hasMore: false,
          nextMax: 0,
          nextViewAt: 0,
          code: code,
          err: _toStr(json['message']).isEmpty
              ? 'code $code'
              : _toStr(json['message']),
        );
      }
      final data = (json['data'] as Map<String, dynamic>?) ?? const {};
      final rawList = (data['list'] as List?) ?? const [];
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(BiliCloudHistoryItem.fromJson)
          .where((e) => e.bvid.isNotEmpty)                      
          .toList();

                                       
                                                                       
      var nextMax = 0;
      var nextViewAt = 0;
      final cursor = data['cursor'];
      if (cursor is Map<String, dynamic>) {
        nextMax = _toInt(cursor['max']);
        nextViewAt = _toInt(cursor['view_at']);
      }
      if (items.isNotEmpty && (nextMax == 0 || nextViewAt == 0)) {
                                              
        final last = rawList.isNotEmpty && rawList.last is Map<String, dynamic>
            ? rawList.last as Map<String, dynamic>
            : null;
        final lastHistory =
            (last?['history'] as Map<String, dynamic>?) ?? const {};
        if (nextMax == 0) nextMax = _toInt(lastHistory['oid']);
        if (nextViewAt == 0) nextViewAt = _toInt(last?['view_at']);
      }
                                                 
      final hasMoreRaw = data['has_more'];
      final hasMore =
          hasMoreRaw == true || (_toInt(hasMoreRaw) == 1 && items.isNotEmpty);

      return BiliCloudHistoryPage(
        items: items,
        hasMore: hasMore,
        nextMax: nextMax,
        nextViewAt: nextViewAt,
        code: 0,
      );
    } catch (e) {
      debugPrint('[BiliHistory] 拉取云端观看历史失败: $e');
      return const BiliCloudHistoryPage(
        items: [],
        hasMore: false,
        nextMax: 0,
        nextViewAt: 0,
        code: -1,
        err: '网络请求失败',
      );
    }
  }

                                             
                                          
                                             

                                                           
                                                           
                                                 
  static String buildKid(String business, int oid) => '${business}_$oid';

                                           
                                       
  static String joinKids(Iterable<String> kids) =>
      kids.where((k) => k.trim().isNotEmpty).toSet().join(',');

                                                      
  static bool get _canWrite =>
      BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.interactions,
      ) !=
      null;

  static Map<String, String> _writeHeaders() {
    final cookie = BilibiliAccountService.instance
        .cookieHeaderFor(BiliCookieScope.interactions)
        ?['Cookie'];
    return {
      ..._webHeaders,
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  static String _csrf() => biliExtractCsrf(BilibiliAccountService.instance.rawCookie);

                 
                                                                    
  static Future<({bool ok, String message})> deleteItem(String kid) =>
      deleteItems([kid]);

                                    
  static Future<({bool ok, String message})> deleteItems(
    Iterable<String> kids,
  ) async {
    final kidParam = joinKids(kids);
    if (kidParam.isEmpty) {
      return (ok: false, message: '没有可删除的云端记录');
    }
    if (!_canWrite) {
      return (ok: false, message: '还没有登录，登录后才能删除云端记录');
    }
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    return _post(_deleteApi, {
      'kid': kidParam,
      'jsonp': 'jsonp',
      'csrf': csrf,
    });
  }

                               
  static Future<({bool ok, String message})> clearAll() async {
    if (!_canWrite) {
      return (ok: false, message: '还没有登录，登录后才能清空云端记录');
    }
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    return _post(_clearApi, {
      'jsonp': 'jsonp',
      'csrf': csrf,
    });
  }

                                                          
  static Future<({bool ok, String message})> _post(
    String url,
    Map<String, String> fields,
  ) async {
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(url),
            headers: {
              ..._writeHeaders(),
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: fields,
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return (ok: false, message: '返回内容不是 JSON 对象');
      }
      final code = biliToInt(json['code']);
      if (code != 0) {
        final msg = biliAsStr(json['message'] ?? json['msg']);
        return (ok: false, message: msg.isEmpty ? '接口返回 $code' : msg);
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[BiliHistory] 请求失败: $e');
      return (ok: false, message: '网络异常：${e.runtimeType}');
    }
  }
}
