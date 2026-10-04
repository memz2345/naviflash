                                              
  
                                             
                                                                      
                                                  
                                      
                                                             
                                                      
                                              
                                                            
                                                          
                                                   
  
                                      
                                                          
                 
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import '../l10n/l10n_helper.dart';

                                            
      
                                            

Map<String, dynamic>? _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

int _toInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}

String _normalizeUrl(String url) {
  if (url.isEmpty) return url;
  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('http://')) return 'https://${url.substring(7)}';
  return url;
}

          
class BiliFavFolder {
  final int id;            
  final String title;
  final String cover;
  final int mediaCount;
  final int attr;           
  final bool isPublic;
  final int favState;                           

  const BiliFavFolder({
    required this.id,
    required this.title,
    required this.cover,
    required this.mediaCount,
    required this.attr,
    required this.isPublic,
    required this.favState,
  });

  factory BiliFavFolder.fromJson(Map<String, dynamic> json) {
    final attr = _toInt(json['attr']);
    return BiliFavFolder(
      id: _toInt(json['id']),
      title: (json['title'] as String?) ?? '',
      cover: _normalizeUrl((json['cover'] as String?) ?? ''),
      mediaCount: _toInt(json['media_count']),
      attr: attr,
                                 
      isPublic: (attr & 1) == 0,
      favState: _toInt(json['fav_state']),
    );
  }

                                                
                                                        
  bool get isDefault => (attr & 2) == 0;
}

              
class BiliFavVideo {
  final int aid;
  final int type;                              
  final String bvid;
  final String title;
  final String cover;
  final String upper;
  final int duration;     
  final int favTime;         
  final int play;
  final int danmaku;
  final int attr;                                 

  const BiliFavVideo({
    required this.aid,
    required this.type,
    required this.bvid,
    required this.title,
    required this.cover,
    required this.upper,
    required this.duration,
    required this.favTime,
    required this.play,
    required this.danmaku,
    required this.attr,
  });

                                      
  bool get isUnavailable => attr != 0;

                                               
  String? get typeLabel => switch (type) {
    2 => null,
    12 => '音频',
    21 => '合集',
    _ => null,
  };

  String get url => bvid.isNotEmpty
      ? 'https://www.bilibili.com/video/$bvid'
      : 'https://www.bilibili.com/video/av$aid';

  factory BiliFavVideo.fromJson(Map<String, dynamic> json) {
    final upper = json['upper'];
    final upperName = upper is Map
        ? (upper['name'] as String?) ?? ''
        : (json['upper'] as String?) ?? '';
    final cnt = _asMap(json['cnt_info']);
    return BiliFavVideo(
      aid: _toInt(json['id']),
      type: _toInt(json['type']),
      bvid: (json['bvid'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      cover: _normalizeUrl((json['cover'] as String?) ?? ''),
      upper: upperName,
      duration: _toInt(json['duration']),
      favTime: _toInt(json['fav_time']),
      play: _toInt(cnt?['play']),
      danmaku: _toInt(cnt?['danmaku']),
      attr: _toInt(json['attr']),
    );
  }
}

            
class BiliFavVideoPage {
  final List<BiliFavVideo> videos;
  final bool hasMore;
  final int total;

  const BiliFavVideoPage({
    required this.videos,
    required this.hasMore,
    required this.total,
  });
}

                                            
      
                                            

abstract final class BilibiliFavoriteService {
  static const String _folderApi =
      'https://api.bilibili.com/x/v3/fav/folder/created/list-all';
  static const String _resourceApi =
      'https://api.bilibili.com/x/v3/fav/resource/list';
  static const String _batchApi =
      'https://api.bilibili.com/x/v3/fav/resource/batch-deal';
  static const String _addFolderApi =
      'https://api.bilibili.com/x/v3/fav/folder/add';

                                                   
  static const String _editFolderApi =
      'https://api.bilibili.com/x/v3/fav/folder/edit';

                                   
  static const String _delFolderApi =
      'https://api.bilibili.com/x/v3/fav/folder/del';

                                                        
  static const String _batchDelApi =
      'https://api.bilibili.com/x/v3/fav/resource/batch-del';

                      
  static String? lastErrorDetail;

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

                                            
  static bool get isLoggedIn => BilibiliAccountService.instance.isLoggedIn;

                          
  static int get mid => BilibiliAccountService.instance.mid;

                                             
  static Map<String, String> _headers() {
    final raw = BilibiliAccountService.instance.rawCookie;
    return {
      ..._defaultHeaders,
      if (raw.isNotEmpty) 'Cookie': raw,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  static String _csrf() {
    final raw = BilibiliAccountService.instance.rawCookie;
    final m = RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(raw);
    return m?.group(1) ?? '';
  }

                                                    
                              
  static int _accountMid() {
    final cached = BilibiliAccountService.instance.mid;
    if (cached > 0) return cached;
    final raw = BilibiliAccountService.instance.rawCookie;
    final m = RegExp('(?:^|;\\s*)DedeUserID=([^;]+)').firstMatch(raw);
    return m == null ? 0 : (int.tryParse(m.group(1) ?? '') ?? 0);
  }

              
                                                     
  static Future<List<BiliFavFolder>?> fetchFolders({
    int? mid,
    int? rid,
    int? type,
  }) async {
    try {
      if (!isLoggedIn) {
        lastErrorDetail = L10n.current.commentNotLoggedIn;
        return null;
      }
      final params = <String, String>{
        'up_mid': (mid ?? _accountMid()).toString(),
        if (rid != null) 'rid': rid.toString(),
        if (type != null) 'type': type.toString(),
      };
      final uri = Uri.parse(_folderApi).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        return null;
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint('[Fav] 收藏夹 code=${json['code']} ${json['message']}');
        return null;
      }
      final data = _asMap(json['data']);
      if (data == null) return null;
      lastErrorDetail = null;
      return (data['list'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BiliFavFolder.fromJson)
          .toList();
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Fav] 拉取收藏夹异常: $e');
      return null;
    }
  }

                  
     
                                                       
                                 
                                                              
  static Future<BiliFavVideoPage?> fetchFolderVideos({
    required int mediaId,
    int pn = 1,
    int ps = 20,
    String order = 'mtime',
    String keyword = '',
    int tid = 0,
  }) async {
    try {
      if (!isLoggedIn) {
        lastErrorDetail = L10n.current.commentNotLoggedIn;
        return null;
      }
      final uri = Uri.parse(_resourceApi).replace(
        queryParameters: {
          'media_id': mediaId.toString(),
          'pn': pn.toString(),
          'ps': ps.toString(),
          'keyword': keyword,
          'order': order,
          'type': '0',
          'tid': tid.toString(),
          'platform': 'web',
        },
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        return null;
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        return null;
      }
      final data = _asMap(json['data']);
      if (data == null) {
        lastErrorDetail = L10n.current.biliResponseNoData;
        return null;
      }
      lastErrorDetail = null;
      return BiliFavVideoPage(
        videos: (data['medias'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(BiliFavVideo.fromJson)
            .toList(),
        hasMore: (data['has_more'] as bool?) ?? false,
        total: _toInt(_asMap(data['info'])?['media_count']),
      );
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Fav] 拉取收藏夹内容异常: $e');
      return null;
    }
  }

                 
                                              
                       
  static Future<({bool ok, String message})> addVideoToFavorites({
    required int aid,
    required List<int> addIds,
    List<int> delIds = const [],
  }) async {
    final csrf = _csrf();
    if (!isLoggedIn) {
      return (ok: false, message: L10n.current.commentNotLoggedIn);
    }
    if (csrf.isEmpty) {
      return (ok: false, message: L10n.current.commentMissingJct);
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_batchApi),
            headers: {
              ..._headers(),
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'resources': '$aid:2',
              'add_media_ids': addIds.join(','),
              'del_media_ids': delIds.join(','),
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        return (
          ok: false,
          message: '${json['message']}',
        );
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[Fav] 加入收藏夹异常: $e');
      return (ok: false, message: '$e');
    }
  }

                                               
                                
  static Future<({bool ok, String message, int mediaId})> createFolder({
    required String title,
    bool isPublic = true,
  }) async {
    final csrf = _csrf();
    if (!isLoggedIn) {
      return (ok: false, message: L10n.current.commentNotLoggedIn, mediaId: 0);
    }
    if (csrf.isEmpty) {
      return (
        ok: false,
        message: L10n.current.commentMissingJct,
        mediaId: 0,
      );
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_addFolderApi),
            headers: {
              ..._headers(),
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'title': title,
              'intro': '',
              'privacy': isPublic ? '0' : '1',
              'cover': '',
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}', mediaId: 0);
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        return (ok: false, message: '${json['message']}', mediaId: 0);
      }
      final data = _asMap(json['data']);
      return (ok: true, message: '', mediaId: _toInt(data?['media_id']));
    } catch (e) {
      debugPrint('[Fav] 新建收藏夹异常: $e');
      return (ok: false, message: '$e', mediaId: 0);
    }
  }

                                              
                           
                                              

                                                
                                                   
                                                
  static String buildResourcesParam(Iterable<(int id, int type)> items) =>
      items.map((e) => '${e.$1}:${e.$2}').join(',');

                                
  static Map<String, String> buildFolderEditBody({
    required int mediaId,
    required String title,
    String intro = '',
    bool isPublic = true,
    String cover = '',
    required String csrf,
  }) =>
      {
        'media_id': mediaId.toString(),
        'title': title,
        'intro': intro,
        'privacy': isPublic ? '0' : '1',
        'cover': cover,
        'csrf': csrf,
      };

                                                        
                       
  static Future<({bool ok, String message})> renameFolder({
    required int mediaId,
    required String title,
    bool isPublic = true,
    String intro = '',
    String cover = '',
  }) async {
    final csrf = _csrf();
    if (!isLoggedIn) {
      return (ok: false, message: L10n.current.commentNotLoggedIn);
    }
    if (csrf.isEmpty) {
      return (ok: false, message: L10n.current.commentMissingJct);
    }
    return _postForm(
      _editFolderApi,
      buildFolderEditBody(
        mediaId: mediaId,
        title: title,
        intro: intro,
        isPublic: isPublic,
        cover: cover,
        csrf: csrf,
      ),
      tag: 'Fav',
      what: '重命名收藏夹',
    );
  }

                                                      
                       
  static Future<({bool ok, String message})> deleteFolder({
    required int mediaId,
  }) async {
    final csrf = _csrf();
    if (!isLoggedIn) {
      return (ok: false, message: L10n.current.commentNotLoggedIn);
    }
    if (csrf.isEmpty) {
      return (ok: false, message: L10n.current.commentMissingJct);
    }
    return _postForm(
      _delFolderApi,
      {
        'media_ids': mediaId.toString(),
        'platform': 'web',
        'csrf': csrf,
      },
      tag: 'Fav',
      what: '删除收藏夹',
    );
  }

                                          
                       
  static Future<({bool ok, String message})> batchDelVideos({
    required int mediaId,
    required List<BiliFavVideo> videos,
  }) async {
                                   
    if (videos.isEmpty) {
      return (ok: false, message: '没有选中的内容');
    }
    final csrf = _csrf();
    if (!isLoggedIn) {
      return (ok: false, message: L10n.current.commentNotLoggedIn);
    }
    if (csrf.isEmpty) {
      return (ok: false, message: L10n.current.commentMissingJct);
    }
    return _postForm(
      _batchDelApi,
      {
        'resources': buildResourcesParam(
          videos.map((v) => (v.aid, v.type)),
        ),
        'media_id': mediaId.toString(),
        'platform': 'web',
        'csrf': csrf,
      },
      tag: 'Fav',
      what: '批量取消收藏',
    );
  }

                                                   
  static Future<({bool ok, String message})> _postForm(
    String url,
    Map<String, String> fields, {
    required String tag,
    required String what,
  }) async {
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(url),
            headers: {
              ..._headers(),
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
      if (json['code'] != 0) {
        return (ok: false, message: '${json['message']}');
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[$tag] $what异常: $e');
      return (ok: false, message: '$e');
    }
  }
}
