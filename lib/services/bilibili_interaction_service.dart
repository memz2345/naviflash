                                                 
  
                                   
                                                               
                                                      
                                          
                                                   
                                                                  
                                 
                                               
  
                                  
                                                           
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/network_settings_service.dart';

                                            
                   
                                            

class BiliVideoRelation {
            
  final bool like;

            
  final bool dislike;

                            
  final int coin;

            
  final bool favorite;

                 
  final bool attention;

  const BiliVideoRelation({
    required this.like,
    required this.dislike,
    required this.coin,
    required this.favorite,
    required this.attention,
  });

  factory BiliVideoRelation.fromJson(Map<String, dynamic> json) {
    return BiliVideoRelation(
      like: _asBool(json['like']),
      dislike: _asBool(json['dislike']),
      coin: _toInt(json['coin']).clamp(0, 2),
      favorite: _asBool(json['favorite']),
      attention: _asBool(json['attention']),
    );
  }
}

                    
class BiliTripleResult {
  final bool like;
  final bool coin;
  final bool fav;

                   
  final int multiply;

  const BiliTripleResult({
    required this.like,
    required this.coin,
    required this.fav,
    required this.multiply,
  });

  factory BiliTripleResult.fromJson(Map<String, dynamic> json) {
    return BiliTripleResult(
      like: _asBool(json['like']),
      coin: _asBool(json['coin']),
      fav: _asBool(json['fav']),
      multiply: _toInt(json['multiply']).clamp(1, 2),
    );
  }
}

                                            
      
                                            

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

bool _asBool(dynamic v) => v == true || v == 1 || v == '1';

                                            
      
                                            

abstract final class BilibiliInteractionService {
  static const String _relationApi =
      'https://api.bilibili.com/x/web-interface/archive/relation';
  static const String _likeApi =
      'https://api.bilibili.com/x/web-interface/archive/like';
  static const String _coinApi =
      'https://api.bilibili.com/x/web-interface/coin/add';
  static const String _tripleApi =
      'https://api.bilibili.com/x/web-interface/archive/like/triple';
  static const String _unfavAllApi =
      'https://api.bilibili.com/x/v3/fav/resource/unfav-all';
  static const String _relationModApi =
      'https://api.bilibili.com/x/relation/modify';
  static const String _reportMemberApi =
      'https://space.bilibili.com/ajax/report/add';
  static const String _navApi = 'https://api.bilibili.com/x/web-interface/nav';
                                                               
                                   
  static const String _dislikeApi =
      'https://app.bilibili.com/x/v2/view/dislike';

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

                      
  static String? lastErrorDetail;

                                          
  static bool get canInteract =>
      BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.interactions,
      ) !=
      null;

                                        
  static final String _buvid3 = _genBuvid3();

  static String _genBuvid3() {
    final r = Random();
    String hex(int n) =>
        List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    final uuid =
        '${hex(8)}-${hex(4)}-4${hex(3)}-'
                '${'89ab'[r.nextInt(4)]}${hex(3)}-${hex(12)}'
            .toUpperCase();
    return '$uuid${r.nextInt(100000).toString().padLeft(5, '0')}infoc';
  }

                                        
  static Map<String, String> _headers() {
    final cookieHeader = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.interactions,
    );
    final cookie = cookieHeader?['Cookie'] ?? '';
    return {
      ..._defaultHeaders,
      if (cookie.isNotEmpty) 'Cookie': '$cookie; buvid3=$_buvid3',
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

  static String _csrf() {
    final raw = BilibiliAccountService.instance.rawCookie;
    final m = RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(raw);
    return m?.group(1) ?? '';
  }

                                  
                                       
  static Future<BiliVideoRelation?> fetchVideoRelation({
    required int aid,
    required String bvid,
  }) async {
    if (!canInteract) return null;
    try {
      final uri = Uri.parse(
        _relationApi,
      ).replace(queryParameters: {'aid': aid.toString(), 'bvid': bvid});
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
        debugPrint('[BiliInteract] relation code=${json['code']}');
        return null;
      }
      final data = _asMap(json['data']);
      lastErrorDetail = null;
      if (data == null) return null;
      return BiliVideoRelation.fromJson(data);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[BiliInteract] 拉取互动状态异常: $e');
      return null;
    }
  }

                
                                    
  static Future<({bool ok, String message})> likeVideo({
    required int aid,
    required bool like,
  }) async {
    final csrf = _csrf();
    if (!canInteract) {
      return (ok: false, message: _notLoggedInMsg());
    }
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_likeApi),
            headers: {
              ..._headers(),
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'aid': aid.toString(),
                                     
              'like': like ? '1' : '2',
              'csrf': csrf,
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
      debugPrint('[BiliInteract] 点赞异常: $e');
      return (ok: false, message: '$e');
    }
  }

         
                                                 
  static Future<({bool ok, String message})> coinVideo({
    required int aid,
    required int multiply,
    bool selectLike = false,
  }) async {
    final csrf = _csrf();
    if (!canInteract) {
      return (ok: false, message: _notLoggedInMsg());
    }
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_coinApi),
            headers: {
              ..._headers(),
              'Origin': 'https://www.bilibili.com',
              'Referer': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'aid': aid.toString(),
              'multiply': multiply.toString(),
              'select_like': selectLike ? '1' : '0',
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (resp.statusCode != 200 || json['code'] != 0) {
        final code = json['code'];
        var message = resp.statusCode != 200
            ? 'HTTP ${resp.statusCode}'
            : '${json['message']}';
        if (code == 34005 || code == 34006) {
          message = '硬币不足';
        } else if (code == -403) {
          message = '已超过投币上限';
        }
        return (ok: false, message: message);
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[BiliInteract] 投币异常: $e');
      return (ok: false, message: '$e');
    }
  }

                         
  static Future<({bool ok, String message, BiliTripleResult? data})>
  tripleLike({required int aid}) async {
    final csrf = _csrf();
    if (!canInteract) {
      return (ok: false, message: _notLoggedInMsg(), data: null);
    }
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录', data: null);
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_tripleApi),
            headers: {
              ..._headers(),
              'Origin': 'https://www.bilibili.com',
              'Referer': 'https://www.bilibili.com/video/$aid',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'aid': aid.toString(),
              'eab_x': '2',
              'ramval': '0',
              'source': 'web_normal',
              'ga': '1',
              'csrf': csrf,
              'spmid': '333.788.0.0',
              'statistics': '{"appId":100,"platform":5}',
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
          data: null,
        );
      }
      final data = _asMap(json['data']);
      return (
        ok: true,
        message: '',
        data: data == null ? null : BiliTripleResult.fromJson(data),
      );
    } catch (e) {
      debugPrint('[BiliInteract] 三连异常: $e');
      return (ok: false, message: '$e', data: null);
    }
  }

                     
  static Future<({bool ok, String message})> unfavoriteAll({
    required int aid,
  }) async {
    final csrf = _csrf();
    if (!canInteract) {
      return (ok: false, message: _notLoggedInMsg());
    }
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_unfavAllApi),
            headers: {
              ..._headers(),
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'rid': aid.toString(), 'type': '2', 'csrf': csrf},
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
      debugPrint('[BiliInteract] 取消收藏异常: $e');
      return (ok: false, message: '$e');
    }
  }

                     
                            
  static Future<({bool ok, String message})> followUser({
    required int mid,
    required int act,
  }) => _relationModify(mid: mid, act: act);

                                                     
  static Future<({bool ok, String message})> blockUser({
    required int mid,
    required bool block,
  }) => _relationModify(mid: mid, act: block ? 5 : 6);

  static Future<({bool ok, String message})> _relationModify({
    required int mid,
    required int act,
  }) async {
    final csrf = _csrf();
    if (!canInteract) {
      return (ok: false, message: _notLoggedInMsg());
    }
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_relationModApi),
            headers: {
              ..._headers(),
              'Origin': 'https://space.bilibili.com',
              'Referer': 'https://space.bilibili.com/$mid',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'fid': mid.toString(),
              'act': act.toString(),
              're_src': '11',
              'csrf': csrf,
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
      debugPrint('[BiliInteract] 关系操作异常: $e');
      return (ok: false, message: '$e');
    }
  }

                                  
                                                           
  static Future<({bool ok, String message})> reportMember({
    required int mid,
    required List<int> reasons,
    int? reasonV2,
  }) async {
    final csrf = _csrf();
    if (!canInteract) {
      return (ok: false, message: _notLoggedInMsg());
    }
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录');
    }
    if (reasons.isEmpty) {
      return (ok: false, message: '请选择举报内容');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_reportMemberApi),
            headers: {
              ..._headers(),
              'Origin': 'https://space.bilibili.com',
              'Referer': 'https://space.bilibili.com/$mid',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'mid': mid.toString(),
              'reason': reasons.join(','),
              if (reasonV2 != null) 'reason_v2': reasonV2.toString(),
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (resp.statusCode != 200 || json['status'] != true) {
        final message = json['message'] ?? json['msg'];
        return (
          ok: false,
          message: message is String && message.isNotEmpty
              ? message
              : 'HTTP ${resp.statusCode}',
        );
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[BiliInteract] 举报异常: $e');
      return (ok: false, message: '$e');
    }
  }

                                       
                                                 
                                                     
  static Future<({bool ok, String message})> dislikeVideo({
    required int aid,
    required bool dislike,
  }) async {
    final csrf = _csrf();
    if (!canInteract) {
      return (ok: false, message: _notLoggedInMsg());
    }
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_dislikeApi),
            headers: {
              ..._headers(),
              'Origin': 'https://app.bilibili.com',
              'Referer': 'https://app.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'aid': aid.toString(),
              'dislike': dislike ? '0' : '1',
              'csrf': csrf,
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
      debugPrint('[BiliInteract] 点踩异常: $e');
      return (ok: false, message: '$e');
    }
  }

                                  
  static Future<int?> fetchMyCoins() async {
    if (!canInteract) return null;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(_navApi), headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;
      final money = _asMap(json['data'])?['money'];
      if (money is num) return money.toInt();
      if (money is String) return int.tryParse(money);
      return null;
    } catch (e) {
      debugPrint('[BiliInteract] 拉取硬币余额异常: $e');
      return null;
    }
  }

                          
  static int get accountMid => _accountMid();

  static String _notLoggedInMsg() {
    final account = BilibiliAccountService.instance;
    if (!account.isLoggedIn) return '请先登录 B 站账号';
    return '请在网络设置中开启「携带 Cookie 请求」';
  }
}
