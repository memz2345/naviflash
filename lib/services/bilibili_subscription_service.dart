                                                  
  
                                        
                                                   
                                              
                                                        
                                                               
                       
                                       
                                                      
                                                                 
                                              
                                                   
                                        
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

                                           
      
                                           

                                           
                                                
class BiliSubItem {
  final int id;

                                  
  final int type;
  final String title;
  final String cover;
  final String intro;
  final String upName;
  final int upMid;

                            
  final int mediaCount;

                                   
  final int viewCount;

                                      
  final int state;

                        
  final int mtime;

  const BiliSubItem({
    required this.id,
    required this.type,
    required this.title,
    required this.cover,
    required this.intro,
    required this.upName,
    required this.upMid,
    required this.mediaCount,
    required this.viewCount,
    required this.state,
    required this.mtime,
  });

  bool get isFavFolder => type == 11;
  bool get isInvalid => state == 1;
  String get typeLabel => isFavFolder ? '收藏夹' : '合集';

  static BiliSubItem fromJson(Map<String, dynamic> json) {
    final upper = _asMap(json['upper']) ?? const <String, dynamic>{};
    final cntInfo = _asMap(json['cnt_info']) ?? const <String, dynamic>{};
    return BiliSubItem(
      id: _toInt(json['id']),
      type: _toInt(json['type']),
      title: _toStr(json['title']),
      cover: _fixCover(_toStr(json['cover'])),
      intro: _toStr(json['intro']),
      upName: _toStr(upper['name']),
      upMid: _toInt(upper['mid']),
      mediaCount: _toInt(json['media_count']),
      viewCount: _toInt(json['view_count'] ?? cntInfo['play']),
      state: _toInt(json['state']),
      mtime: _toInt(json['mtime']),
    );
  }
}

                                                  
class BiliSubVideo {
  final int id;
  final String bvid;
  final String title;
  final String cover;

               
  final int duration;

                      
  final int pubtime;

                          
  final int play;

  const BiliSubVideo({
    required this.id,
    required this.bvid,
    required this.title,
    required this.cover,
    required this.duration,
    required this.pubtime,
    required this.play,
  });

  static BiliSubVideo fromJson(Map<String, dynamic> json) {
    final cntInfo = _asMap(json['cnt_info']) ?? const <String, dynamic>{};
    return BiliSubVideo(
      id: _toInt(json['id']),
      bvid: _toStr(json['bvid']),
      title: _toStr(json['title']),
      cover: _fixCover(_toStr(json['cover'])),
      duration: _toInt(json['duration']),
      pubtime: _toInt(json['pubtime']),
      play: _toInt(cntInfo['play']),
    );
  }
}

                                           
      
                                           

abstract final class BilibiliSubscriptionService {
  static const String _apiBase = 'https://api.bilibili.com';
  static const String _listApi =
      '$_apiBase/x/v3/fav/folder/collected/list';        
  static const String _seasonApi = '$_apiBase/x/space/fav/season/list';        

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

                                   
                        
  static bool get isLoggedIn => BilibiliAccountService.instance.isLoggedIn;

                                                
  static Map<String, String> _headers() {
    final raw = BilibiliAccountService.instance.rawCookie;
    return {
      ..._defaultHeaders,
      if (raw.isNotEmpty) 'Cookie': raw,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

                                                    
                                          
  static int _accountMid() {
    final cached = BilibiliAccountService.instance.mid;
    if (cached > 0) return cached;
    final raw = BilibiliAccountService.instance.rawCookie;
    final m = RegExp('(?:^|;\\s*)DedeUserID=([^;]+)').firstMatch(raw);
    return m == null ? 0 : (int.tryParse(m.group(1) ?? '') ?? 0);
  }

                                 
                                           
                          
  static Future<({List<BiliSubItem> items, bool hasMore, String? err})>
  fetchList({int pn = 1, int ps = 20}) async {
    if (!isLoggedIn) {
      return (items: const <BiliSubItem>[], hasMore: false, err: '还没有登录，登录后才能查看订阅');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final uri = Uri.parse(_listApi).replace(
        queryParameters: {
          'up_mid': _accountMid().toString(),
          'ps': ps.toString(),
          'pn': pn.toString(),
          'platform': 'web',
        },
      );
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (items: const <BiliSubItem>[], hasMore: false, err: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return (items: const <BiliSubItem>[], hasMore: false, err: '返回内容不是 JSON 对象');
      }
      final code = _toInt(json['code']);
      if (code != 0) {
        final msg = _toStr(json['message'] ?? json['msg']);
        return (
          items: const <BiliSubItem>[],
          hasMore: false,
          err: msg.isEmpty ? '接口返回 $code' : msg,
        );
      }
      final data = _asMap(json['data']) ?? const <String, dynamic>{};
      final rawList = data['list'];
      final items = <BiliSubItem>[];
      if (rawList is List) {
        for (final e in rawList.whereType<Map<String, dynamic>>()) {
          final item = BiliSubItem.fromJson(e);
          if (item.id > 0) items.add(item);
        }
      }
      final hm = data['has_more'];
      final hasMore = hm is bool ? hm : items.length >= ps;
      return (items: items, hasMore: hasMore, err: null);
    } catch (e) {
      debugPrint('[Subscription] 订阅列表获取失败: $e');
      return (
        items: const <BiliSubItem>[],
        hasMore: false,
        err: '网络异常：${e.runtimeType}',
      );
    }
  }

                                           
                                                       
  static Future<({BiliSubItem? info, List<BiliSubVideo> videos, String? err})>
  fetchSeasonVideos({required int seasonId, int pn = 1, int ps = 20}) async {
    if (!isLoggedIn) {
      return (info: null, videos: const <BiliSubVideo>[], err: '还没有登录，登录后才能查看订阅');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final uri = Uri.parse(_seasonApi).replace(
        queryParameters: {
          'season_id': seasonId.toString(),
          'ps': ps.toString(),
          'pn': pn.toString(),
        },
      );
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (info: null, videos: const <BiliSubVideo>[], err: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return (info: null, videos: const <BiliSubVideo>[], err: '返回内容不是 JSON 对象');
      }
      final code = _toInt(json['code']);
      if (code != 0) {
        final msg = _toStr(json['message'] ?? json['msg']);
        return (
          info: null,
          videos: const <BiliSubVideo>[],
          err: msg.isEmpty ? '接口返回 $code' : msg,
        );
      }
      final data = _asMap(json['data']) ?? const <String, dynamic>{};
      final infoJson = _asMap(data['info']);
      final info = infoJson == null ? null : BiliSubItem.fromJson(infoJson);
      final videos = <BiliSubVideo>[];
      final medias = data['medias'];
      if (medias is List) {
        for (final e in medias.whereType<Map<String, dynamic>>()) {
          final v = BiliSubVideo.fromJson(e);
                                             
          if (v.bvid.isNotEmpty) videos.add(v);
        }
      }
      return (info: info, videos: videos, err: null);
    } catch (e) {
      debugPrint('[Subscription] 合集内容获取失败: $e');
      return (
        info: null,
        videos: const <BiliSubVideo>[],
        err: '网络异常：${e.runtimeType}',
      );
    }
  }
}
