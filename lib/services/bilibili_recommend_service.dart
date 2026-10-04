                                               
  
                          
                                                                                                                                
                                                    
                                                                                                                                      
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_blacklist_service.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart' show WbiSign;
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/utils/recommend_filter.dart';

                                                                                                                  

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

String _toStr(dynamic v) => v?.toString() ?? '';

                                   
int _parseCountText(String s) {
  final t = s.trim();
  if (t.isEmpty || t == '-') return 0;
  final m = RegExp(r'^([\d.]+)\s*(千|万|亿?)').firstMatch(t);
  if (m == null) return int.tryParse(t) ?? 0;
  final num = double.tryParse(m.group(1) ?? '') ?? 0;
  final unit = switch (m.group(2)) {
    '千' => 1000,
    '万' => 10000,
    '亿' => 100000000,
    _ => 1,
  };
  return (num * unit).round();
}

                                                                                  
                                           

class BiliRecommendItem {
  final String bvid;
  final int aid;
  final int cid;
  final String title;
  final String cover;
  final int duration;    
  final int pubdate;         
  final String ownerName;
  final int ownerMid;

                                                      
  final String ownerFace;

                               
  final bool isFollowed;
  final int view;
  final int danmaku;
  final int like;

                                 
  final String rcmdReason;

                                                          
  final String tname;

  const BiliRecommendItem({
    required this.bvid,
    required this.aid,
    required this.cid,
    required this.title,
    required this.cover,
    required this.duration,
    required this.pubdate,
    required this.ownerName,
    required this.ownerMid,
    this.ownerFace = '',
    this.isFollowed = false,
    required this.view,
    required this.danmaku,
    required this.like,
    required this.rcmdReason,
    this.tname = '',
  });
}

                                                                                                                     

class BiliBangumiItem {
  final int seasonId;
  final String title;
  final String cover;
  final String badge;                        
  final String indexShow;                                     
  final String score;                 

  const BiliBangumiItem({
    required this.seasonId,
    required this.title,
    required this.cover,
    required this.badge,
    required this.indexShow,
    required this.score,
  });
}

                                               
class BiliBangumiIndexPage {
  final List<BiliBangumiItem> items;
  final bool hasNext;

  const BiliBangumiIndexPage({required this.items, required this.hasNext});
}

                                        
class BiliBangumiConditionField {
                                         
  final String field;

                     
  final String name;
  final List<BiliBangumiConditionValue> values;

  const BiliBangumiConditionField({
    required this.field,
    required this.name,
    required this.values,
  });
}

                                          
               
class BiliBangumiConditionValue {
  final String keyword;
  final String name;

  const BiliBangumiConditionValue({required this.keyword, required this.name});
}

                                  
                                             
                                             
class BiliBangumiCondition {
  final List<BiliBangumiConditionField> order;
  final List<BiliBangumiConditionField> filters;

  const BiliBangumiCondition({required this.order, required this.filters});
}

                                                     
                                                                                  
class BiliBangumiBannerItem {
  final int seasonId;
  final int seasonType;
  final String title;
  final String subTitle;
  final String cover;               
  final String bgImg;
  final String url;          

  const BiliBangumiBannerItem({
    required this.seasonId,
    required this.seasonType,
    required this.title,
    required this.subTitle,
    required this.cover,
    required this.bgImg,
    required this.url,
  });
}

                                                  
class BiliBangumiRankItem {
  final int seasonId;
  final String title;
  final String cover;
  final String subTitle;
  final String newEpShow;            
  final String url;

  const BiliBangumiRankItem({
    required this.seasonId,
    required this.title,
    required this.cover,
    required this.subTitle,
    required this.newEpShow,
    required this.url,
  });
}

                                                  
                                                        
class BiliBangumiContinueItem {
  final int seasonId;
  final String title;
  final String cover;
  final String desc;
  final int progressPercent;
  final String newEpShow;
  final String url;

  const BiliBangumiContinueItem({
    required this.seasonId,
    required this.title,
    required this.cover,
    required this.desc,
    required this.progressPercent,
    required this.newEpShow,
    required this.url,
  });
}

                                                     
                                           

sealed class BiliRecommendResult<T> {}

                
class BiliRecommendOk<T> extends BiliRecommendResult<T> {
  final List<T> items;
  BiliRecommendOk(this.items);
}

                              
class BiliRecommendError<T> extends BiliRecommendResult<T> {
  final String detail;
  BiliRecommendError(this.detail);
}

                                                   
                                           

abstract final class BilibiliRecommendService {
  static const String _webApi =
      'https://api.bilibili.com/x/web-interface/wbi/index/top/feed/rcmd';
  static const String _appApi = 'https://app.bilibili.com/x/v2/feed/index';
  static const String _spiApi =
      'https://api.bilibili.com/x/frontend/finger/spi';

                                
  static String? lastErrorDetail;

  static const Map<String, String> _webHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

                                      
  static const String _appUA =
      'Mozilla/5.0 BiliDroid/2.0.1 (bbcallen@gmail.com) os/android '
      'model/android_hd mobi_app/android_hd build/2001100 channel/master '
      'innerVer/2001100 osVer/15 network/2';

                                                  

  static String? _fpBuvid3;
  static String? _fpBuvid4;

  static Future<void> _ensureDeviceFp() async {
    if (_fpBuvid3 != null) return;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(_spiApi), headers: _webHeaders)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return;
      final data = _asMap(json['data']);
      if (data == null) return;
      final b3 = (data['b_3'] as String?) ?? '';
      if (b3.isNotEmpty) {
        _fpBuvid3 = b3;
        _fpBuvid4 = (data['b_4'] as String?) ?? '';
      }
    } catch (e) {
      debugPrint('[Recommend] 获取设��指纹失败: $e');
    }
  }

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

                                                       
  static Future<String> _buildWebCookie() async {
    await _ensureDeviceFp();
    final parts = <String>[
      'buvid3=${_fpBuvid3 ?? _genBuvid3()}',
      if (_fpBuvid4?.isNotEmpty ?? false) 'buvid4=$_fpBuvid4',
      'b_nut=${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
    ];
    final accountCookie = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.video,
    )?['Cookie'];
    if (accountCookie != null && accountCookie.isNotEmpty) {
      parts.insert(0, accountCookie);
    }
    return parts.join('; ');
  }

  static Future<Map<String, String>> _buildWebHeaders({
    Map<String, String>? overrideLocaleHeaders,
  }) async {
    final headers = <String, String>{
      ..._webHeaders,
      'Cookie': await _buildWebCookie(),
      ...NetworkSettingsService.instance.apiHeaders,
    };
    if (overrideLocaleHeaders != null) {
                                                
                                      
      for (final key in BilibiliTranslateService.translateHeaderKeys) {
        headers.remove(key);
      }
      headers.addAll(overrideLocaleHeaders);
    }
    return headers;
  }

                        

                                                                                                      
  static Future<BiliRecommendResult<BiliRecommendItem>> fetchWeb({
    required int freshIdx,
    int ps = 20,
  }) async {
    try {
                                        
      await BilibiliBlacklistService.instance.ensureLoaded();
      final params = await WbiSign.sign({
        'version': '1',
        'feed_version': 'V8',
        'homepage_ver': '1',
        'ps': ps.toString(),
        'fresh_idx': freshIdx.toString(),
        'brush': freshIdx.toString(),
        'fresh_type': '4',
        'web_location': '1430650',
      });
      final uri = Uri.parse(_webApi).replace(queryParameters: params);
      final headers = await _buildWebHeaders();
      if (SettingsService.rcmdGuestMode) {
                                                
                                  
        headers.remove('Cookie');
      }
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[Recommend] web HTTP ${resp.statusCode}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint('[Recommend] web code=${json['code']} ${json['message']}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final data = _asMap(json['data']);
      final rawList = data?['item'];
      if (rawList is! List) {
        lastErrorDetail = '数据为空';
        return BiliRecommendError(lastErrorDetail!);
      }
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .where((e) => e['goto'] == 'av')                   
          .map(_parseWebItem)
          .where((v) => v != null)
          .cast<BiliRecommendItem>()
                                               
          .where(
            (v) => !RecommendFilter.filterItem(
              title: v.title,
              duration: v.duration,
              like: v.like,
              view: v.view,
              isFollowed: v.isFollowed,
            ),
          )
                                   
          .where((v) => !RecommendFilter.filterOwnerMid(v.ownerMid))
          .toList();
      lastErrorDetail = null;
      return BiliRecommendOk(items);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Recommend] web 推荐异常: $e');
      return BiliRecommendError(lastErrorDetail!);
    }
  }

  static BiliRecommendItem? _parseWebItem(Map<String, dynamic> json) {
    final owner = _asMap(json['owner']) ?? const <String, dynamic>{};
    final stat = _asMap(json['stat']) ?? const <String, dynamic>{};
    final reason = _asMap(json['rcmd_reason']);
    final bvid = _toStr(json['bvid']);
    if (bvid.isEmpty) return null;
    return BiliRecommendItem(
      bvid: bvid,
      aid: _toInt(json['id']),
      cid: _toInt(json['cid']),
      title: _toStr(json['title']),
      cover: _toStr(json['pic']),
      duration: _toInt(json['duration']),
      pubdate: _toInt(json['pubdate']),
      ownerName: _toStr(owner['name']),
      ownerMid: _toInt(owner['mid']),
      ownerFace: _toStr(owner['face']),
      isFollowed: json['is_followed'] == true,
      view: _toInt(stat['view']),
      danmaku: _toInt(stat['danmaku']),
      like: _toInt(stat['like']),
      rcmdReason: _toStr(reason?['content']),
      tname: _toStr(json['tname']),
    );
  }

                        

                                                                                                                                                   
  static Future<BiliRecommendResult<BiliRecommendItem>> fetchApp({
    required int freshIdx,
  }) async {
    try {
      await BilibiliBlacklistService.instance.ensureLoaded();
      await _ensureDeviceFp();
      final buvid = _fpBuvid3 ?? _genBuvid3();
      final cookieParts = <String>[
        'buvid3=$buvid',
        if (_fpBuvid4?.isNotEmpty ?? false) 'buvid4=$_fpBuvid4',
      ];
      final accountCookie = BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.video,
      )?['Cookie'];
      if (accountCookie != null && accountCookie.isNotEmpty) {
        cookieParts.insert(0, accountCookie);
      }
      final query = {
        'build': '2001100',
        'c_locale': 'zh_CN',
        'channel': 'master',
        'column': '4',
        'device': 'pad',
        'device_name': 'android',
        'device_type': '0',
        'disable_rcmd': '0',
        'flush': '5',
        'fnval': '976',
        'fnver': '0',
        'force_host': '2',            
        'fourk': '1',
        'guidance': '0',
        'https_url_req': '0',
        'idx': freshIdx.toString(),
        'mobi_app': 'android_hd',
        'network': 'wifi',
        'platform': 'android',
        'player_net': '1',
        'pull': freshIdx == 0 ? 'true' : 'false',
        'qn': '32',
        'recsys_mode': '0',
        's_locale': 'zh_CN',
        'splash_id': '',
        'statistics':
            '{"appId":5,"platform":3,"version":"2.0.1","abtest":""}',
        'voice_balance': '0',
      };
      final uri = Uri.parse(_appApi).replace(queryParameters: query);
      final headers = <String, String>{
        'User-Agent': _appUA,
        'Cookie': cookieParts.join('; '),
        'buvid': buvid,
        'fp_local': '1' * 64,
        'fp_remote': '1' * 64,
        'session_id': '11111111',
        'env': 'prod',
        'app-key': 'android_hd',
        'x-bili-trace-id': '11111111111111111111111111111111:1111111111111111:0:0',
        'x-bili-aurora-eid': '',
        'x-bili-aurora-zone': '',
        'bili-http-engine': 'cronet',
        ...NetworkSettingsService.instance.apiHeaders,
      };
      if (SettingsService.rcmdGuestMode) {
                                                      
        headers.remove('Cookie');
      }
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[Recommend] app HTTP ${resp.statusCode}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint('[Recommend] app code=${json['code']} ${json['message']}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final data = _asMap(json['data']);
      final rawList = data?['items'];
      if (rawList is! List) {
        lastErrorDetail = '数据为空';
        return BiliRecommendError(lastErrorDetail!);
      }
      final items = rawList
          .whereType<Map<String, dynamic>>()
                               
          .where(
            (e) =>
                e['card_goto'] != 'ad_av' &&
                e['card_goto'] != 'ad_web_s' &&
                _asMap(e['ad_info']) == null &&
                _toInt(e['can_play']) == 1 &&
                e['goto'] == 'av',
          )
                                         
          .where(
            (e) => !RecommendFilter.filterZone(
              _toStr(_asMap(e['args'])?['tname']),
            ),
          )
          .map(_parseAppItem)
          .where((v) => v != null)
          .cast<BiliRecommendItem>()
                                               
          .where(
            (v) => !RecommendFilter.filterItem(
              title: v.title,
              duration: v.duration,
              like: v.like,
              view: v.view,
              isFollowed: v.isFollowed,
            ),
          )
                                   
          .where((v) => !RecommendFilter.filterOwnerMid(v.ownerMid))
          .toList();
      lastErrorDetail = null;
      return BiliRecommendOk(items);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Recommend] app 推荐异常: $e');
      return BiliRecommendError(lastErrorDetail!);
    }
  }

  static BiliRecommendItem? _parseAppItem(Map<String, dynamic> json) {
    final playerArgs = _asMap(json['player_args']) ?? const <String, dynamic>{};
    final args = _asMap(json['args']) ?? const <String, dynamic>{};
    final aid = _toInt(json['param']) > 0
        ? _toInt(json['param'])
        : _toInt(playerArgs['aid']);
    final bvid = _toStr(json['bvid']);
    if (bvid.isEmpty && aid <= 0) return null;
    final title = _toStr(json['title']);
    if (title.isEmpty) return null;
    var like = _toInt(json['like']);
                                                    
    final rcmdReason = _toStr(json['rcmd_reason']);
    if (like == 0 && rcmdReason.contains('赞')) {
      like = _parseCountText(rcmdReason.replaceAll('赞', ''));
    }
    return BiliRecommendItem(
      bvid: bvid,
      aid: aid,
      cid: _toInt(playerArgs['cid']),
      title: title,
      cover: _toStr(json['cover']),
      duration: _toInt(playerArgs['duration']),
      pubdate: _toInt(json['pubdate']),
      ownerName: _toStr(args['up_name']),
      ownerMid: _toInt(args['up_id']),
      ownerFace: _toStr(args['up_face']),
      view: _parseCountText(_toStr(json['cover_left_text_1'])),
      danmaku: _parseCountText(_toStr(json['cover_left_text_2'])),
      like: like,
      rcmdReason: rcmdReason,
      tname: _toStr(args['tname']),
    );
  }

                         
  static Future<BiliRecommendResult<BiliRecommendItem>> fetch({
    required BiliRecommendSource source,
    required int freshIdx,
    int ps = 20,
  }) {
    return switch (source) {
      BiliRecommendSource.web => fetchWeb(freshIdx: freshIdx, ps: ps),
      BiliRecommendSource.app => fetchApp(freshIdx: freshIdx),
    };
  }

                   

                                                      
  static Future<BiliRecommendResult<BiliRecommendItem>> fetchPopular({
    required int pn,
    int ps = 20,
  }) async {
    try {
      await BilibiliBlacklistService.instance.ensureLoaded();
      final uri = Uri.parse('https://api.bilibili.com/x/web-interface/popular')
          .replace(queryParameters: {'pn': pn.toString(), 'ps': ps.toString()});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildWebHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[Recommend] popular HTTP ${resp.statusCode}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint('[Recommend] popular code=${json['code']} ${json['message']}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final data = _asMap(json['data']);
      final rawList = data?['list'];
      if (rawList is! List) {
        lastErrorDetail = '数据为空';
        return BiliRecommendError(lastErrorDetail!);
      }
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(_parseWebItem)
          .where((v) => v != null)
          .cast<BiliRecommendItem>()
                                                        
                    
          .where(
            (v) =>
                !RecommendFilter.filterHot(
                  title: v.title,
                  like: v.like,
                  view: v.view,
                ) &&
                !RecommendFilter.filterZone(v.tname) &&
                !RecommendFilter.filterOwnerMid(v.ownerMid),
          )
          .toList();
      lastErrorDetail = null;
      return BiliRecommendOk(items);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Recommend] popular 异常: $e');
      return BiliRecommendError(lastErrorDetail!);
    }
  }

                   

                                                                    
                                              
                                          

                                                    
  static Future<BiliRecommendResult<BiliRecommendItem>> fetchRanking() async {
    return _fetchVideoList(
      'https://api.bilibili.com/x/web-interface/ranking/v2',
      const {'rid': '0', 'type': 'all'},
      tag: 'ranking',
    );
  }

                                             
  static Future<BiliRecommendResult<BiliRecommendItem>> fetchPrecious() async {
    return _fetchVideoList(
      'https://api.bilibili.com/x/web-interface/popular/precious',
      const {'page_size': '10', 'pn': '1'},
      tag: 'precious',
    );
  }

                                
  static Future<List<({int number, String title})>> fetchWeeklySeries() async {
    try {
      final uri = Uri.parse(
        'https://api.bilibili.com/x/web-interface/popular/series/list',
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildWebHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return const [];
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return const [];
      final data = _asMap(json['data']);
      final rawList = data?['list'];
      if (rawList is! List) return const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => (
              number: _toInt(e['number']),
              title: _toStr(e['title']),
            ),
          )
          .where((e) => e.number > 0)
          .toList();
    } catch (e) {
      debugPrint('[Recommend] weekly series 异常: $e');
      return const [];
    }
  }

                                         
  static Future<BiliRecommendResult<BiliRecommendItem>> fetchWeeklyOne(
    int number,
  ) async {
    final params = await WbiSign.sign({'number': number.toString()});
    return _fetchVideoList(
      'https://api.bilibili.com/x/web-interface/popular/series/one',
      params,
      tag: 'weekly',
    );
  }

                                                        
  static Future<List<String>> fetchHotwords() async {
    try {
      final uri = Uri.parse(
        'https://s.search.bilibili.com/main/hotword',
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildWebHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return const [];
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return const [];
      final rawList = json['list'];
      if (rawList is! List) return const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => _toStr(e['keyword']))
          .where((s) => s.isNotEmpty)
          .take(10)
          .toList();
    } catch (e) {
      debugPrint('[Recommend] hotword 异常: $e');
      return const [];
    }
  }

                                   
                                                
  static Future<BiliRecommendResult<BiliRecommendItem>> _fetchVideoList(
    String api,
    Map<String, String> params, {
    required String tag,
  }) async {
    try {
      await BilibiliBlacklistService.instance.ensureLoaded();
      final uri = Uri.parse(api).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildWebHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[Recommend] $tag HTTP ${resp.statusCode}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint('[Recommend] $tag code=${json['code']} ${json['message']}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final data = _asMap(json['data']);
      final rawList = data?['list'];
      if (rawList is! List) {
        lastErrorDetail = '数据为空';
        return BiliRecommendError(lastErrorDetail!);
      }
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(_parseWebItem)
          .where((v) => v != null)
          .cast<BiliRecommendItem>()
                                                        
                    
          .where(
            (v) =>
                !RecommendFilter.filterHot(
                  title: v.title,
                  like: v.like,
                  view: v.view,
                ) &&
                !RecommendFilter.filterZone(v.tname) &&
                !RecommendFilter.filterOwnerMid(v.ownerMid),
          )
          .toList();
      lastErrorDetail = null;
      return BiliRecommendOk(items);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Recommend] $tag 异常: $e');
      return BiliRecommendError(lastErrorDetail!);
    }
  }

  static Future<BiliRecommendResult<BiliBangumiItem>> fetchBangumi({
    required int page,
    int ps = 20,
  }) async {
    final result = await fetchBangumiIndex(page: page, ps: ps);
    if (result == null) {
      return BiliRecommendError(lastErrorDetail ?? '加载失败');
    }
    return BiliRecommendOk(result.items);
  }

                                           
                                                        
                                                        
                                 
     
                                                      
                                              
                                         
  static Future<BiliBangumiIndexPage?> fetchBangumiIndex({
    required int page,
    int ps = 20,
    int seasonType = 1,
    Map<String, String> filters = const {},
    Map<String, String>? displayLocaleHeaders,
  }) async {
    try {
      final params = <String, String>{
        'st': '1',
        'order': '3',
        'season_version': '-1',
        'spoken_language_type': '-1',
        'area': '-1',
        'is_finish': '-1',
        'copyright': '-1',
        'season_status': '-1',
        'season_month': '-1',
        'year': '-1',
        'style_id': '-1',
        'sort': '0',
        'season_type': seasonType.toString(),
        'type': '1',
        'page': page.toString(),
        'pagesize': ps.toString(),
      };
      params.addAll(filters);
      final uri = Uri.parse('https://api.bilibili.com/pgc/season/index/result')
          .replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            uri,
            headers: await _buildWebHeaders(
              overrideLocaleHeaders: displayLocaleHeaders,
            ),
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[Recommend] bangumi HTTP ${resp.statusCode}');
        return null;
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint('[Recommend] bangumi code=${json['code']} ${json['message']}');
        return null;
      }
      final data = _asMap(json['data']);
      final rawList = data?['list'];
      if (rawList is! List) {
        lastErrorDetail = '数据为空';
        return null;
      }
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(_parseBangumiItem)
          .where((v) => v != null)
          .cast<BiliBangumiItem>()
          .toList();
      lastErrorDetail = null;
      return BiliBangumiIndexPage(
        items: items,
        hasNext: _toInt(data?['has_next']) == 1,
      );
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Recommend] bangumi 异常: $e');
      return null;
    }
  }

                                                
                                            
     
                                                            
                                  
  static Future<BiliBangumiCondition?> fetchBangumiCondition({
    int seasonType = 1,
    Map<String, String>? displayLocaleHeaders,
  }) async {
    try {
      final uri =
          Uri.parse('https://api.bilibili.com/pgc/season/index/condition')
              .replace(
                queryParameters: {
                  'season_type': seasonType.toString(),
                  'type': '0',
                },
              );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            uri,
            headers: await _buildWebHeaders(
              overrideLocaleHeaders: displayLocaleHeaders,
            ),
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[Recommend] condition HTTP ${resp.statusCode}');
        return null;
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint(
          '[Recommend] condition code=${json['code']} ${json['message']}',
        );
        return null;
      }
      final data = _asMap(json['data']);
      if (data == null) {
        lastErrorDetail = '数据为空';
        return null;
      }
      List<BiliBangumiConditionField> parseFields(List<dynamic>? raw) {
        final out = <BiliBangumiConditionField>[];
        for (final e in raw ?? const []) {
          final m = _asMap(e);
          if (m == null) continue;
          final field = _toStr(m['field']);
          if (field.isEmpty) continue;
          final values = <BiliBangumiConditionValue>[];
          for (final v in m['values'] as List<dynamic>? ?? const []) {
            final vm = _asMap(v);
            if (vm == null) continue;
            values.add(
              BiliBangumiConditionValue(
                keyword: _toStr(vm['keyword']),
                name: _toStr(vm['name']),
              ),
            );
          }
          out.add(
            BiliBangumiConditionField(
              field: field,
              name: _toStr(m['name']),
              values: values,
            ),
          );
        }
        return out;
      }

      lastErrorDetail = null;
      return BiliBangumiCondition(
        order: parseFields(data['order'] as List<dynamic>?),
        filters: parseFields(data['filter'] as List<dynamic>?),
      );
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Recommend] condition 异常: $e');
      return null;
    }
  }

  static BiliBangumiItem? _parseBangumiItem(Map<String, dynamic> json) {
    final seasonId = _toInt(json['season_id']);
    if (seasonId <= 0) return null;
    final title = _toStr(json['title']);
    if (title.isEmpty) return null;
    return BiliBangumiItem(
      seasonId: seasonId,
      title: title,
      cover: _toStr(json['cover']),
      badge: _toStr(json['badge']),
      indexShow: _toStr(json['index_show']),
      score: _toStr(json['order']),
    );
  }

                                                               
                                                
                                                  
  static Future<
      ({List<BiliBangumiBannerItem> banners, List<BiliBangumiRankItem> ranks})>
      fetchBangumiChannel() async {
    try {
      final uri = Uri.parse('https://api.bilibili.com/pgc/page/channel')
          .replace(
            queryParameters: {
              'page_name': 'bangumi_tab',
              'cursor': '',
              'extra': '',
            },
          );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildWebHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return (banners: <BiliBangumiBannerItem>[], ranks: <BiliBangumiRankItem>[]);
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return (banners: <BiliBangumiBannerItem>[], ranks: <BiliBangumiRankItem>[]);
      final data = _asMap(json['data']);
      final modules = data?['modules'];
      if (modules is! List) return (banners: <BiliBangumiBannerItem>[], ranks: <BiliBangumiRankItem>[]);
      var banners = <BiliBangumiBannerItem>[];
      var ranks = <BiliBangumiRankItem>[];
      for (final m in modules) {
        final module = _asMap(m);
        if (module == null) continue;
        final moduleData = _asMap(module['module_data']);
        final items = moduleData?['items'];
        switch (_toStr(module['type'])) {
          case 'BANNER':
            if (items is List) {
              banners = items
                  .whereType<Map<String, dynamic>>()
                  .map(_parseBangumiBannerItem)
                  .where((v) => v != null)
                  .cast<BiliBangumiBannerItem>()
                  .toList();
            }
          case 'RANK':
            if (items is List && ranks.isEmpty) {
              for (final it in items) {
                final item = _asMap(it);
                final subs = item?['sub_items'];
                if (subs is! List) continue;
                for (final s in subs) {
                  final sm = _asMap(s);
                  if (sm == null) continue;
                  final seasonId = _toInt(sm['season_id']);
                  if (seasonId <= 0) continue;
                  ranks.add(
                    BiliBangumiRankItem(
                      seasonId: seasonId,
                      title: _toStr(sm['title']),
                      cover: _toStr(sm['cover']),
                      subTitle: _toStr(sm['sub_title']),
                      newEpShow: _toStr(
                        _asMap(sm['new_ep'])?['index_show'],
                      ),
                      url: _toStr(sm['url']),
                    ),
                  );
                }
              }
            }
        }
      }
      return (banners: banners, ranks: ranks);
    } catch (e) {
      debugPrint('[Recommend] bangumi channel 异常: $e');
      return (banners: <BiliBangumiBannerItem>[], ranks: <BiliBangumiRankItem>[]);
    }
  }

  static BiliBangumiBannerItem? _parseBangumiBannerItem(
    Map<String, dynamic> json,
  ) {
    final cover = _toStr(json['cover']);
    if (cover.isEmpty) return null;
    return BiliBangumiBannerItem(
      seasonId: _toInt(json['season_id']),
      seasonType: _toInt(json['season_type']),
      title: _toStr(json['title']),
      subTitle: _toStr(json['sub_title']),
      cover: cover,
      bgImg: _toStr(json['bg_img']),
      url: _toStr(json['url']),
    );
  }

                                                         
                                                                  
                                               
  static Future<List<BiliBangumiContinueItem>> fetchBangumiContinue() async {
    final accountCookie = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.video,
    )?['Cookie'];
    if (accountCookie == null || accountCookie.isEmpty) return const [];
    try {
      final uri = Uri.parse('https://api.bilibili.com/pgc/page/guess/bangumi')
          .replace(
            queryParameters: {
              'page_no': '1',
              'page_size': '10',
            },
          );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildWebHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return const [];
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return const [];
      final data = _asMap(json['data']);
      final modules = data?['modules'];
      if (modules is! List) return const [];
      for (final m in modules) {
        final module = _asMap(m);
        if (module == null || _toStr(module['type']) != 'recent_watch') {
          continue;
        }
        final items = module['items'];
        if (items is! List) return const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map(_parseContinueItem)
            .where((v) => v != null)
            .cast<BiliBangumiContinueItem>()
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('[Recommend] bangumi continue 异常: $e');
      return const [];
    }
  }

  static BiliBangumiContinueItem? _parseContinueItem(
    Map<String, dynamic> json,
  ) {
    final seasonId = _toInt(json['season_id']);
    if (seasonId <= 0) return null;
    final title = _toStr(json['title']);
    if (title.isEmpty) return null;
    return BiliBangumiContinueItem(
      seasonId: seasonId,
      title: title,
      cover: _toStr(json['cover']),
      desc: _toStr(json['desc']),
      progressPercent: _toInt(json['progress_percent']),
      newEpShow: _toStr(_asMap(json['new_ep'])?['index_show']),
      url: _toStr(json['url']),
    );
  }

                                
  static String coverUrl(String url) {
    if (url.isEmpty) return '';
    final normalized = url.startsWith('//') ? 'https:$url' : url;
    return '$normalized@320w_200h_1c.webp';
  }
}
