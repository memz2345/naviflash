                                            
  
                                                                      
                                                              
                                                  
                                     
                                                     
                                                                                    
                                                                   
                                                           
                                                        
                                                      
                                                
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_audio_zone_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart' show WbiSign;
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

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim()) ?? 0;
  return 0;
}

                                              
                                           
List<dynamic>? _asList(dynamic v) => v is List ? v : null;

                                       
String _stripHtml(String s) {
  if (s.isEmpty) return s;
  return s.replaceAll(RegExp(r'<[^>]+>'), '');
}

                                                         
                                                       
                                    
List<({String text, bool highlight})> _parseTitleEm(
  String raw, {
  String fallbackKeyword = '',
}) {
  final segments = <({String text, bool highlight})>[];
  final emReg = RegExp(r'<em[^>]*>(.*?)</em>', dotAll: true);
  var last = 0;
  for (final m in emReg.allMatches(raw)) {
    if (m.start > last) {
      segments.add((text: raw.substring(last, m.start), highlight: false));
    }
    segments.add((text: _stripHtml(m.group(1) ?? ''), highlight: true));
    last = m.end;
  }
  if (last < raw.length) {
    segments.add((text: raw.substring(last), highlight: false));
  }
  if (segments.isEmpty) {
    segments.add((text: _stripHtml(raw), highlight: false));
  }
  final hasHighlight = segments.any((s) => s.highlight);
  if (!hasHighlight && fallbackKeyword.isNotEmpty) {
    return _highlightPlain(_stripHtml(raw), fallbackKeyword);
  }
  return segments;
}

                  
List<({String text, bool highlight})> _highlightPlain(
  String text,
  String keyword,
) {
  final segments = <({String text, bool highlight})>[];
  if (keyword.isEmpty) {
    segments.add((text: text, highlight: false));
    return segments;
  }
  final lower = text.toLowerCase();
  final kw = keyword.toLowerCase();
  var last = 0;
  var idx = lower.indexOf(kw);
  while (idx != -1) {
    if (idx > last) {
      segments.add((text: text.substring(last, idx), highlight: false));
    }
    segments.add((text: text.substring(idx, idx + kw.length), highlight: true));
    last = idx + kw.length;
    idx = lower.indexOf(kw, last);
  }
  if (last < text.length) {
    segments.add((text: text.substring(last), highlight: false));
  }
  if (segments.isEmpty) {
    segments.add((text: text, highlight: false));
  }
  return segments;
}

String _normalizeUrl(String url) {
  if (url.startsWith('//')) return 'https:$url';
  return url;
}

String _formatCount(int n) {
  final unit = L10n.current.tenThousandUnit;
  final usesK = unit == 'K';
  if (n >= (usesK ? 1000 : 10000)) {
    final v = n / (usesK ? 1000 : 10000);
    return '${v.toStringAsFixed(v >= 100 ? 0 : 1)}$unit';
  }
  return '$n';
}

                                            
        
                                            

enum BiliSearchType {
  video('video'),
  mediaBangumi('media_bangumi'),
  mediaFt('media_ft'),
  liveRoom('live_room'),
  biliUser('bili_user'),
  article('article'),
                                                     
                                                       
  audio('audio');

  const BiliSearchType(this.code);

  final String code;

  String get label => switch (this) {
    BiliSearchType.video => L10n.current.searchTypeVideo,
    BiliSearchType.mediaBangumi => L10n.current.searchTypeBangumi,
    BiliSearchType.mediaFt => L10n.current.searchTypeFt,
    BiliSearchType.liveRoom => L10n.current.searchTypeLive,
    BiliSearchType.biliUser => L10n.current.searchTypeUser,
    BiliSearchType.article => L10n.current.searchTypeArticle,
                                          
    BiliSearchType.audio => '音频',
  };
}

                                            
               
                                            

class BiliSearchItem {
  final BiliSearchType type;

                                        
  final int mid;

                                    
  final List<({String text, bool highlight})> titleSegments;

                  
  final String cover;

                                    
  final String subtitle;

                                        
  final String meta;

                               
  final String badge;

                
  final String duration;

               
  final String actionUrl;

             
  final String desc;

                                      
  final int play;

                            
  final int danmaku;

                                      
                                   
  final int id;

                                                  
  final String bvid;

                                                   
                                             
  final int seasonId;

                                
                                             
  final int roomId;

  const BiliSearchItem({
    required this.type,
    required this.mid,
    required this.titleSegments,
    required this.cover,
    required this.subtitle,
    required this.meta,
    required this.badge,
    required this.duration,
    required this.actionUrl,
    required this.desc,
    this.play = 0,
    this.danmaku = 0,
    this.id = 0,
    this.bvid = '',
    this.seasonId = 0,
    this.roomId = 0,
  });
}

           
class BiliSearchPage {
  final List<BiliSearchItem> items;
  final int numResults;
  final int page;
  final int pageSize;

  const BiliSearchPage({
    required this.items,
    required this.numResults,
    required this.page,
    required this.pageSize,
  });
}

                                            
           
                                            

class BiliSearchSuggest {
  final String keyword;                  
  final String display;                       

  const BiliSearchSuggest({required this.keyword, required this.display});
}

                                            
                 
                                            

                         
class BiliHotSearchItem {
  final String keyword;                  
  final String? icon;                       
  final bool showLiveIcon;               
  final String? recommendReason;                     

  const BiliHotSearchItem({
    required this.keyword,
    this.icon,
    this.showLiveIcon = false,
    this.recommendReason,
  });
}

                 
sealed class BiliHotSearchResult {}

class BiliHotSearchOk extends BiliHotSearchResult {
  final List<BiliHotSearchItem> items;

                                         
               
  final int topCount;
  BiliHotSearchOk({required this.items, this.topCount = 0});
}

class BiliHotSearchFail extends BiliHotSearchResult {
  final String detail;
  BiliHotSearchFail(this.detail);
}

                                            
                   
                                            

sealed class BiliSearchResult {}

           
class BiliSearchOk extends BiliSearchResult {
  final BiliSearchPage page;
  BiliSearchOk(this.page);
}

                                      
                                                            
class BiliSearchCaptcha extends BiliSearchResult {
  final String vVoucher;
  BiliSearchCaptcha(this.vVoucher);
}

                              
class BiliSearchError extends BiliSearchResult {
  final String detail;
  BiliSearchError(this.detail);
}

                                            
      
                                            

abstract final class BilibiliSearchService {
  static const String _searchApi =
      'https://api.bilibili.com/x/web-interface/wbi/search/type';
  static const String _suggestApi =
      'https://s.search.bilibili.com/main/suggest';
  static const String _gaiaRegisterApi =
      'https://api.bilibili.com/x/gaia-vgate/v1/register';
  static const String _gaiaValidateApi =
      'https://api.bilibili.com/x/gaia-vgate/v1/validate';
  static const String _spiApi =
      'https://api.bilibili.com/x/frontend/finger/spi';

                              
  static String? lastErrorDetail;

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://search.bilibili.com',
  };

                             

  static String? _spiBuvid3;
  static String? _spiBuvid4;

  static Future<void> _ensureDeviceFp() async {
    if (_spiBuvid3 != null) return;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(_spiApi), headers: _defaultHeaders)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return;
      final data = _asMap(json['data']);
      if (data == null) return;
      final b3 = (data['b_3'] as String?) ?? '';
      if (b3.isNotEmpty) {
        _spiBuvid3 = b3;
        _spiBuvid4 = (data['b_4'] as String?) ?? '';
      }
    } catch (e) {
      debugPrint('[Search] 获取设备指纹失败: $e');
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

  static String _genBLsid() {
    const chars = '0123456789abcdef';
    final r = Random();
    String hex(int n) =>
        List.generate(n, (_) => chars[r.nextInt(chars.length)]).join();
    return '${hex(16)}_${hex(8)}';
  }

  static Future<String> _buildCookie() async {
    await _ensureDeviceFp();
    final parts = <String>[
      'buvid3=${_spiBuvid3 ?? _genBuvid3()}',
      if (_spiBuvid4?.isNotEmpty ?? false) 'buvid4=$_spiBuvid4',
      'b_nut=${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
      'b_lsid=${_genBLsid()}',
    ];
    final accountCookie = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.search,
    )?['Cookie'];
    if (accountCookie != null && accountCookie.isNotEmpty) {
      parts.insert(0, accountCookie);
    }
    return parts.join('; ');
  }

  static Future<Map<String, String>> _buildHeaders({
    required String keyword,
    String? gaiaVtoken,
  }) async {
    final cookie = await _buildCookie();
    final merged = <String>[
      cookie,
      if (gaiaVtoken != null && gaiaVtoken.isNotEmpty)
        'x-bili-gaia-vtoken=$gaiaVtoken',
    ].join('; ');
    return {
      ..._defaultHeaders,
      'Referer':
          'https://search.bilibili.com/video?keyword=${Uri.encodeComponent(keyword)}',
      'Origin': 'https://search.bilibili.com',
      'Cookie': merged,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

               

                                                        
                                                                   
                                                 
                                                    
                     
  static Future<BiliSearchResult> searchByType({
    required BiliSearchType type,
    required String keyword,
    int page = 1,
    int pageSize = 20,
    String? gaiaVtoken,
    int? duration,
    int? tids,
    int? pubBegin,
    int? pubEnd,
  }) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      lastErrorDetail = L10n.current.searchKeywordEmpty;
      return BiliSearchError(L10n.current.searchKeywordEmpty);
    }
                                             
                                          
    if (type == BiliSearchType.audio) {
      return _searchAudioZone(trimmed);
    }
    try {
      final params = await WbiSign.sign({
        'search_type': type.code,
        'keyword': trimmed,
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'platform': 'pc',
        'web_location': '1430654',
        if (duration != null && duration > 0) 'duration': duration.toString(),
        if (tids != null && tids > 0) 'tids': tids.toString(),
        if (pubBegin != null) 'pubtime_begin_s': pubBegin.toString(),
        if (pubEnd != null) 'pubtime_end_s': pubEnd.toString(),
      });
      final uri = Uri.parse(_searchApi).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final headers = await _buildHeaders(
        keyword: trimmed,
        gaiaVtoken: gaiaVtoken,
      );
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = L10n.current.biliHttpError(resp.statusCode);
        debugPrint('[Search] HTTP ${resp.statusCode}');
        return BiliSearchError(L10n.current.biliHttpError(resp.statusCode));
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        lastErrorDetail = L10n.current.searchBadResponse;
        return BiliSearchError(L10n.current.searchBadResponse);
      }
      final code = json['code'];
      if (code != 0 && code != 200) {
                     
        lastErrorDetail = 'code=$code ${json['message']}';
        debugPrint('[Search] code=$code ${json['message']}');
        return BiliSearchError(
          code == -412
              ? L10n.current.biliRiskBlocked
              : '${json['message'] ?? L10n.current.searchFailed}',
        );
      }
      final data = _asMap(json['data']);
      if (data == null) {
        lastErrorDetail = L10n.current.biliResponseNoData;
        return BiliSearchError(L10n.current.biliResponseNoData);
      }
      final vVoucher = (data['v_voucher'] as String?) ?? '';
      if (vVoucher.isNotEmpty) {
        debugPrint('[Search] 触发风控，需要验证码验证');
        return BiliSearchCaptcha(vVoucher);
      }
      final result = _asList(data['result']) ?? const [];
      final items = result
          .whereType<Map<String, dynamic>>()
          .map((e) => _parseItem(type, e, trimmed))
          .where((e) => e != null)
          .cast<BiliSearchItem>()
          .toList();
      lastErrorDetail = null;
      return BiliSearchOk(
        BiliSearchPage(
          items: items,
          numResults: _toInt(data['numResults']),
          page: page,
          pageSize: pageSize,
        ),
      );
    } catch (e) {
      lastErrorDetail = L10n.current.commentException('$e');
      debugPrint('[Search] 搜索异常: $e');
      return BiliSearchError(L10n.current.commentException('$e'));
    }
  }

                                         
                                      
  static Future<BiliSearchResult> _searchAudioZone(String keyword) async {
    final res = await BilibiliAudioZoneService.searchCatalog(keyword);
    final songs = res.songs;
    if (res.err != null && songs.isEmpty) {
      lastErrorDetail = res.err;
      debugPrint('[Search] 音频目录检索失败: ${res.err}');
      return BiliSearchError(res.err!);
    }
    lastErrorDetail = null;
    final items = songs
        .map(
          (s) => BiliSearchItem(
            type: BiliSearchType.audio,
            mid: 0,
            id: s.id,
            titleSegments: _parseTitleEm(s.title, fallbackKeyword: keyword),
            cover: s.cover,
            subtitle: s.author,
            meta: s.play > 0 ? '${_formatCount(s.play)} 次播放' : '音频',
            badge: '音频',
            duration: s.duration > 0
                ? '${s.duration ~/ 60}:${(s.duration % 60).toString().padLeft(2, '0')}'
                : '',
            actionUrl: s.webUrl,
            desc: s.intro,
            play: s.play,
          ),
        )
        .toList();
    return BiliSearchOk(
      BiliSearchPage(
        items: items,
        numResults: items.length,
                                                          
                                                              
                              
        page: 1,
        pageSize: items.length + 1,
      ),
    );
  }

                                       
                                
  static BiliSearchItem? _parseItem(
    BiliSearchType type,
    Map<String, dynamic> json,
    String keyword,
  ) {
    switch (type) {
      case BiliSearchType.video:
        final bvid = (json['bvid'] as String?) ?? '';
        final badge = switch (json['type']) {
          'ketang' => L10n.current.searchBadgeCourse,
          'live_room' => L10n.current.searchBadgeLive,
          _ =>
            _toInt(json['is_union_video']) == 1
                ? L10n.current.searchBadgeCoop
                : '',
        };
        return BiliSearchItem(
          type: type,
          mid: _toInt(json['mid']),
          titleSegments: _parseTitleEm(
            (json['title'] as String?) ?? '',
            fallbackKeyword: keyword,
          ),
          cover: (json['pic'] as String?) ?? '',
          subtitle: (json['author'] as String?) ?? '',
          meta: L10n.current.searchVideoMeta(
            _formatCount(_toInt(json['play'])),
            _formatCount(_toInt(json['video_review'])),
          ),
          badge: badge,
          duration: (json['duration'] as String?) ?? '',
          actionUrl: 'https://www.bilibili.com/video/$bvid',
          desc: (json['description'] as String?) ?? '',
          play: _toInt(json['play']),
          danmaku: _toInt(json['video_review']),
          bvid: bvid,
        );
      case BiliSearchType.mediaBangumi:
      case BiliSearchType.mediaFt:
        final seasonId = _toInt(json['season_id']);
        final score = _toDouble(_asMap(json['media_score'])?['score']);
                                                          
        final areas = switch (json['areas']) {
          final String s => s,
          final List l =>
            l
                .whereType<Map<String, dynamic>>()
                .map((a) => (a['name'] as String?) ?? '')
                .where((s) => s.isNotEmpty)
                .join(' · '),
          _ => '',
        };
        final parts = <String>[
          (json['season_type_name'] as String?) ?? '',
          areas,
        ].where((s) => s.isNotEmpty);
        return BiliSearchItem(
          type: type,
          mid: 0,
          titleSegments: _parseTitleEm(
            (json['title'] as String?) ?? '',
            fallbackKeyword: keyword,
          ),
          cover: (json['cover'] as String?) ?? '',
          subtitle: parts.join(' · '),
          meta: score > 0
              ? L10n.current.searchScore(
                  score.toStringAsFixed(score >= 10 ? 0 : 1),
                )
              : '',
          badge: (json['button_text'] as String?) ?? '',
          duration: (json['index_show'] as String?) ?? '',
          actionUrl: 'https://www.bilibili.com/bangumi/play/ss$seasonId',
          desc: (json['desc'] as String?) ?? '',
          seasonId: seasonId,
        );
      case BiliSearchType.liveRoom:
        final roomId = _toInt(json['roomid']);
        final cover = ((json['cover'] as String?) ?? '').isNotEmpty
            ? (json['cover'] as String?)!
            : ((json['uface'] as String?) ?? '');
        return BiliSearchItem(
          type: type,
          mid: _toInt(json['uid']),
          titleSegments: _parseTitleEm(
            (json['title'] as String?) ?? '',
            fallbackKeyword: keyword,
          ),
          cover: _normalizeUrl(cover),
          subtitle: (json['uname'] as String?) ?? '',
          meta: L10n.current.searchOnline(_formatCount(_toInt(json['online']))),
          badge: (json['cate_name'] as String?) ?? '',
          duration: '',
          actionUrl: 'https://live.bilibili.com/$roomId',
          desc: '',
          roomId: roomId,
        );
      case BiliSearchType.biliUser:
        final mid = _toInt(json['mid']);
        return BiliSearchItem(
          type: type,
          mid: mid,
          titleSegments: _parseTitleEm(
            (json['uname'] as String?) ?? '',
            fallbackKeyword: keyword,
          ),
          cover: (json['upic'] as String?) ?? '',
          subtitle: (json['usign'] as String?) ?? '',
          meta: L10n.current.searchUserMeta(
            _formatCount(_toInt(json['fans'])),
            _formatCount(_toInt(json['videos'])),
          ),
          badge: _toInt(json['is_live']) == 1
              ? L10n.current.searchBadgeLiveNow
              : '',
          duration: '',
          actionUrl: 'https://space.bilibili.com/$mid',
          desc: '',
        );
      case BiliSearchType.article:
        final id = _toInt(json['id']);
        final images = _asList(json['image_urls']) ?? const [];
        return BiliSearchItem(
          type: type,
          mid: _toInt(json['mid']),
          titleSegments: _parseTitleEm(
            (json['title'] as String?) ?? '',
            fallbackKeyword: keyword,
          ),
          cover: images.isNotEmpty ? '${images.first}' : '',
          subtitle: (json['category_name'] as String?) ?? '',
          meta: L10n.current.searchArticleMeta(
            _formatCount(_toInt(json['view'])),
            _formatCount(_toInt(json['reply'])),
          ),
          badge: '',
          duration: '',
          actionUrl: 'https://www.bilibili.com/read/cv$id',
          desc: (json['desc'] as String?) ?? '',
          id: id,
        );
      case BiliSearchType.audio:
                                                        
                             
        return null;
    }
  }

               

                                                              
                  
  static Future<List<BiliSearchSuggest>> searchSuggest(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return const [];
    try {
      final uri = Uri.parse(_suggestApi).replace(
        queryParameters: {
          'term': trimmed,
          'main_ver': 'v1',
          'highlight': trimmed,
          'jsonp': 'jsonp',
        },
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final headers = await _buildHeaders(keyword: trimmed);
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return const [];
                                                   
      var body = utf8.decode(resp.bodyBytes).trim();
      if (body.startsWith('jsonp(') ||
          body.startsWith('callback(') ||
          (body.startsWith('(') && body.endsWith(')'))) {
        final start = body.indexOf('(') + 1;
        final end = body.lastIndexOf(')');
        if (start > 0 && end > start) {
          body = body.substring(start, end);
        }
      }
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic> || json['code'] != 0) {
        return const [];
      }
      final result = _asMap(json['result']);
      final tag = _asList(result?['tag']) ?? const [];
      return tag
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => BiliSearchSuggest(
                                               
              keyword:
                  (((e['term'] as String?) ?? (e['value'] as String?)) ?? '')
                      .trim(),
              display: _stripHtml((e['name'] as String?) ?? ''),
            ),
          )
          .where((s) => s.keyword.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[Search] 获取搜索建议失败: $e');
      return const [];
    }
  }

                     

  static const String _trendingApi =
      'https://api.bilibili.com/x/v2/search/trending/ranking';
  static const String _searchRcmdApi =
      'https://app.bilibili.com/x/v2/search/recommend';

                                      
                                     
  static const Duration _hotCacheTtl = Duration(seconds: 60);

  static List<BiliHotSearchItem>? _trendingCache;
  static int _trendingTopCount = 0;
  static DateTime? _trendingCacheAt;

  static List<BiliHotSearchItem>? _rcmdCache;
  static DateTime? _rcmdCacheAt;

  static bool _hotCacheValid(DateTime? at) =>
      at != null && DateTime.now().difference(at) < _hotCacheTtl;

                                        
     
                                                  
                         
                                  
                                                         
  static Future<BiliHotSearchResult> searchTrending({
    int limit = 30,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _hotCacheValid(_trendingCacheAt) &&
        _trendingCache != null) {
      final items = _trendingCache!;
      return BiliHotSearchOk(
        items: items.take(limit).toList(),
        topCount: _trendingTopCount,
      );
    }
    try {
      final uri = Uri.parse(_trendingApi).replace(
        queryParameters: {'limit': '30'},
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final headers = await _buildHeaders(keyword: '');
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) {
        return BiliHotSearchFail(L10n.current.biliHttpError(resp.statusCode));
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return BiliHotSearchFail(L10n.current.searchBadResponse);
      }
      if (json['code'] != 0) {
        return BiliHotSearchFail(
          '${json['message'] ?? L10n.current.searchFailed}',
        );
      }
      final data = _asMap(json['data']);
      final top = _parseHotSearchList(data?['top_list']);
      final list = _parseHotSearchList(data?['list']);
      final merged = <BiliHotSearchItem>[...top, ...list];
      _trendingCache = merged;
      _trendingTopCount = top.length;
      _trendingCacheAt = DateTime.now();
      return BiliHotSearchOk(
        items: merged.take(limit).toList(),
        topCount: top.length,
      );
    } catch (e) {
      debugPrint('[Search] 获取热搜榜失败: $e');
      return BiliHotSearchFail('$e');
    }
  }

                                                   
                                          
  static Future<BiliHotSearchResult> searchRcmd({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _hotCacheValid(_rcmdCacheAt) && _rcmdCache != null) {
      return BiliHotSearchOk(items: _rcmdCache!);
    }
    try {
      final uri = Uri.parse(_searchRcmdApi).replace(
        queryParameters: {
          'build': '8430300',
          'channel': 'master',
          'version': '8.43.0',
          'c_locale': 'zh_CN',
          'mobi_app': 'android',
          'platform': 'android',
          's_locale': 'zh_CN',
          'from': '2',
        },
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
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) {
        return BiliHotSearchFail(L10n.current.biliHttpError(resp.statusCode));
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return BiliHotSearchFail(L10n.current.searchBadResponse);
      }
      if (json['code'] != 0) {
        return BiliHotSearchFail(
          '${json['message'] ?? L10n.current.searchFailed}',
        );
      }
      final list = _parseHotSearchList(_asMap(json['data'])?['list']);
      _rcmdCache = list;
      _rcmdCacheAt = DateTime.now();
      return BiliHotSearchOk(items: list);
    } catch (e) {
      debugPrint('[Search] 获取搜索发现失败: $e');
      return BiliHotSearchFail('$e');
    }
  }

                 

  static const String _pageHeaderApi =
      'https://api.bilibili.com/x/web-show/page/header';

  static String? _pageHeaderCache;
  static DateTime? _pageHeaderCacheAt;

                                                
     
                                                
                                                        
                                     
  static Future<String?> fetchPageHeader({
    int resourceId = 142,
    bool forceRefresh = false,
  }) async {
    final cached = _pageHeaderCache;
    final at = _pageHeaderCacheAt;
    if (!forceRefresh &&
        cached != null &&
        at != null &&
        DateTime.now().difference(at) < const Duration(minutes: 30)) {
      return cached;
    }
    try {
      final uri = Uri.parse(
        _pageHeaderApi,
      ).replace(queryParameters: {'resource_id': '$resourceId'});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            uri,
            headers: {
              ..._defaultHeaders,
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return cached;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> || json['code'] != 0) return cached;
      final data = _asMap(json['data']);
      final pic =
          ((data?['pic'] as String?) ?? (data?['litpic'] as String?) ?? '')
              .trim();
      if (pic.isEmpty) return cached;
      final url = pic.startsWith('//') ? 'https:$pic' : pic;
      _pageHeaderCache = url;
      _pageHeaderCacheAt = DateTime.now();
      return url;
    } catch (e) {
      debugPrint('[Search] 获取页面头图失败: $e');
      return cached;
    }
  }

                                  
                                              
  static List<BiliHotSearchItem> _parseHotSearchList(dynamic v) {
    if (v is! List) return const [];
    return v
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => BiliHotSearchItem(
            keyword: ((e['keyword'] as String?) ?? '').trim(),
            icon: (e['icon'] as String?)?.trim().isEmpty ?? true
                ? null
                : (e['icon'] as String?),
            showLiveIcon: (e['show_live_icon'] as bool?) ?? false,
            recommendReason: (e['recommend_reason'] as String?)?.replaceFirst(
              '·',
              ' ',
            ),
          ),
        )
        .where((e) => e.keyword.isNotEmpty)
        .toList();
  }

                           

                                                     
                                          
  static Future<({String token, String gt, String challenge})?>
  gaiaVgateRegister(String vVoucher) async {
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final cookie = await _buildCookie();
      final accountCookie = BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.search,
      )?['Cookie'];
      final merged = accountCookie != null && accountCookie.isNotEmpty
          ? '$accountCookie; $cookie'
          : cookie;
      final resp = await client
          .post(
            Uri.parse(_gaiaRegisterApi),
            headers: {
              ..._defaultHeaders,
              'Content-Type': 'application/x-www-form-urlencoded',
              'Cookie': merged,
              ...NetworkSettingsService.instance.apiHeaders,
            },
            body: {'v_voucher': vVoucher},
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'gaia register HTTP ${resp.statusCode}';
        return null;
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail =
            'gaia register code=${json['code']} ${json['message']}';
        debugPrint('[Search] gaia register ${json['message']}');
        return null;
      }
      final data = _asMap(json['data']);
      final geetest = _asMap(data?['geetest']);
      final token = (data?['token'] as String?) ?? '';
      final gt = (geetest?['gt'] as String?) ?? '';
      final challenge = (geetest?['challenge'] as String?) ?? '';
      if (token.isEmpty || gt.isEmpty || challenge.isEmpty) {
        lastErrorDetail = L10n.current.searchGaiaParamMissing;
        return null;
      }
      return (token: token, gt: gt, challenge: challenge);
    } catch (e) {
      lastErrorDetail = L10n.current.searchGaiaRegisterError('$e');
      debugPrint('[Search] gaia register 异常: $e');
      return null;
    }
  }

                                                  
                           
  static Future<String?> gaiaVgateValidate({
    required String token,
    required String challenge,
    required String validate,
    required String seccode,
  }) async {
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final cookie = await _buildCookie();
      final accountCookie = BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.search,
      )?['Cookie'];
      final merged = accountCookie != null && accountCookie.isNotEmpty
          ? '$accountCookie; $cookie'
          : cookie;
      final resp = await client
          .post(
            Uri.parse(_gaiaValidateApi),
            headers: {
              ..._defaultHeaders,
              'Content-Type': 'application/x-www-form-urlencoded',
              'Cookie': merged,
              ...NetworkSettingsService.instance.apiHeaders,
            },
            body: {
              'challenge': challenge,
              'seccode': seccode,
              'token': token,
              'validate': validate,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'gaia validate HTTP ${resp.statusCode}';
        return null;
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail =
            'gaia validate code=${json['code']} ${json['message']}';
        debugPrint('[Search] gaia validate ${json['message']}');
        return null;
      }
      final data = _asMap(json['data']);
      final isValid = _toInt(data?['is_valid']);
      final griskId = (data?['grisk_id'] as String?) ?? '';
      if (isValid != 1 || griskId.isEmpty) {
        lastErrorDetail = L10n.current.searchGaiaValidateFailed(isValid);
        return null;
      }
      lastErrorDetail = null;
      return griskId;
    } catch (e) {
      lastErrorDetail = L10n.current.searchGaiaValidateError('$e');
      debugPrint('[Search] gaia validate 异常: $e');
      return null;
    }
  }

             

                                  
  static String coverUrl(String url) {
    if (url.isEmpty) return '';
    return '${_normalizeUrl(url)}@320w_200h_1c.webp';
  }

                                     
                                             
  static String bangumiCoverUrl(String url) {
    if (url.isEmpty) return '';
    return '${_normalizeUrl(url)}@480w_640h_1c.webp';
  }

                     
  static String avatarUrl(String url, {int size = 96}) {
    if (url.isEmpty) return '';
    return '${_normalizeUrl(url)}@${size}w_${size}h_1c.webp';
  }
}
