                                                 
  
                                                              
                                                                    
                                                    
                                                                      
                                                
                                                        
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'bilibili_account_service.dart';
import 'network_settings_service.dart';

                                           
          
                                           

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

Map<String, dynamic>? _asMap(dynamic v) =>
    v is Map<String, dynamic> ? v : null;

                                           
      
                                           

           
class WatchLaterItem {
  final int aid;
  final String bvid;

                                   
  final int cid;
  final String title;
  final String cover;
  final String upName;
  final String upFace;

               
  final int duration;

                        
  final int progress;

                      
  final int addAt;

  const WatchLaterItem({
    required this.aid,
    required this.bvid,
    required this.cid,
    required this.title,
    required this.cover,
    required this.upName,
    required this.upFace,
    required this.duration,
    required this.progress,
    required this.addAt,
  });
}

                                           
      
                                           

abstract final class BilibiliWatchLaterService {
  static const String _apiBase = 'https://api.bilibili.com';

  static const Map<String, String> _webHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  static Map<String, String> _headers(BiliCookieScope scope) {
    final cookie = BilibiliAccountService.instance.cookieHeaderFor(
      scope,
    )?['Cookie'];
    return {
      ..._webHeaders,
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  static String _csrf() {
    final raw = BilibiliAccountService.instance.rawCookie;
    return RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(raw)?.group(1) ??
        '';
  }

                             
  static bool get canUse =>
      BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.interactions,
      ) !=
      null;

                             
  static Future<({List<WatchLaterItem> items, String? err})> fetchList() async {
    if (!canUse) {
      return (items: const <WatchLaterItem>[], err: '还没有登录，登录后才能看稍后再看');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            Uri.parse('$_apiBase/x/v2/history/toview/web'),
            headers: _headers(BiliCookieScope.video),
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (items: const <WatchLaterItem>[], err: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return (items: const <WatchLaterItem>[], err: '返回内容不是 JSON 对象');
      }
      final code = _toInt(json['code']);
      if (code != 0) {
        return (
          items: const <WatchLaterItem>[],
          err: _toStr(json['message']).isEmpty
              ? '接口返回 $code'
              : _toStr(json['message']),
        );
      }
      final data = _asMap(json['data']) ?? const <String, dynamic>{};
      final list = data['list'];
      final items = <WatchLaterItem>[];
      if (list is List) {
        for (final e in list.whereType<Map<String, dynamic>>()) {
          final item = _parseItem(e);
          if (item != null) items.add(item);
        }
      }
      return (items: items, err: null);
    } catch (e) {
      debugPrint('[WatchLater] 列表获取失败: $e');
      return (items: const <WatchLaterItem>[], err: '网络异常：${e.runtimeType}');
    }
  }

  static WatchLaterItem? _parseItem(Map<String, dynamic> json) {
    final aid = _toInt(json['aid']);
    final bvid = _toStr(json['bvid']);
    if (aid <= 0 && bvid.isEmpty) return null;
    final upper = _asMap(json['upper']) ?? const <String, dynamic>{};
    return WatchLaterItem(
      aid: aid,
      bvid: bvid,
      cid: _toInt(json['cid']),
      title: _toStr(json['title']),
                                            
      cover: _fixCover(
        _toStr(json['pic']).isNotEmpty
            ? _toStr(json['pic'])
            : _toStr(json['cover'] ?? json['picture']),
      ),
      upName: _toStr(upper['name']),
      upFace: _fixCover(_toStr(upper['face'])),
      duration: _toInt(json['duration']),
      progress: _toInt(json['progress']),
      addAt: _toInt(json['add_at']),
    );
  }

                                
  static Future<({bool ok, String message})> add({
    required int aid,
    String bvid = '',
  }) async {
    if (!canUse) return (ok: false, message: '还没有登录，登录后才能添加');
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    return _post('$_apiBase/x/v2/history/toview/add', {
      'aid': aid.toString(),
      if (bvid.isNotEmpty) 'bvid': bvid,
      'csrf': csrf,
      'csrf_token': csrf,
    });
  }

              
  static Future<({bool ok, String message})> remove({
    required int aid,
    required String bvid,
  }) async {
    if (!canUse) return (ok: false, message: '还没有登录');
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    return _post('$_apiBase/x/v2/history/toview/v2/dels', {
      'viewed': 'false',
      'resources': jsonEncode([
        {'aid': aid, 'bvid': bvid},
      ]),
      'csrf': csrf,
      'csrf_token': csrf,
      'platform': 'pc',
    });
  }

                                           
  static Future<({bool ok, String message})> removeMany(
    List<WatchLaterItem> items,
  ) async {
    if (items.isEmpty) return (ok: true, message: '');
    if (!canUse) return (ok: false, message: '还没有登录');
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    return _post('$_apiBase/x/v2/history/toview/v2/dels', {
      'viewed': 'false',
      'resources': jsonEncode([
        for (final it in items)
          {'aid': it.aid, if (it.bvid.isNotEmpty) 'bvid': it.bvid},
      ]),
      'csrf': csrf,
      'csrf_token': csrf,
      'platform': 'pc',
    });
  }

             
  static Future<({bool ok, String message})> clearAll() async {
    if (!canUse) return (ok: false, message: '还没有登录');
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    return _post('$_apiBase/x/v2/history/toview/clear', {
      'viewed': 'false',
      'csrf': csrf,
      'csrf_token': csrf,
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
              ..._headers(BiliCookieScope.interactions),
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
      final code = _toInt(json['code']);
      if (code != 0) {
        final msg = _toStr(json['message'] ?? json['msg']);
        return (ok: false, message: msg.isEmpty ? '接口返回 $code' : msg);
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[WatchLater] 请求失败: $e');
      return (ok: false, message: '网络异常：${e.runtimeType}');
    }
  }
}
