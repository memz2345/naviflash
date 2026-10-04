                                            
  
                                       
                                                                    
                                                                     
                                                         
                                                      
                                                                
                                                                    
                                                        
                                                                
                                          
                                                                
                                                                        
                                                    
                                             
                                                                     
                                               
                                                           
                                                                      
                                                         
                                                            
                                                            
                                                        
                                                                      
                                                 
                                                    
                                        

import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart'
    show WbiSign;
import 'package:naviflash/services/bilibili_video_service.dart'
    show BiliPlayUrl;
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/network_settings_service.dart';

                                            
                                                  
                                            

                                                                
class CheeseEpisode {
  final int epId;                      
  final int aid;                   
  final int cid;                     
  final String title;
  final String subtitle;                 
  final String cover;
  final int durationSec;     
  final int index;             
  final bool playable;                                
  final String label;               
  final String previewToast;                    
  final int play;       
  final bool watched;

  const CheeseEpisode({
    required this.epId,
    required this.aid,
    required this.cid,
    required this.title,
    required this.subtitle,
    required this.cover,
    required this.durationSec,
    required this.index,
    required this.playable,
    required this.label,
    required this.previewToast,
    required this.play,
    required this.watched,
  });

  factory CheeseEpisode.fromJson(Map<String, dynamic> json) {
    return CheeseEpisode(
      epId: biliToInt(json['id'] ?? json['ep_id']),
      aid: biliToInt(json['aid']),
      cid: biliToInt(json['cid']),
      title: biliAsStr(json['title']),
      subtitle: biliAsStr(json['subtitle']),
      cover: biliNormalizeUrl(biliAsStr(json['cover'])),
      durationSec: biliToInt(json['duration']),
      index: biliToInt(json['index']),
      playable: json['playable'] is bool
          ? json['playable'] as bool
          : biliToInt(json['playable']) != 0,
      label: biliAsStr(json['label']),
      previewToast: biliAsStr(json['preview_toast']),
      play: biliToInt(json['play']),
      watched: json['watched'] == true || biliToInt(json['watched']) == 1,
    );
  }
}

                          
class CheeseUpInfo {
  final int mid;
  final String name;
  final String avatar;
  final String brief;
  final int follower;

  const CheeseUpInfo({
    required this.mid,
    required this.name,
    required this.avatar,
    required this.brief,
    required this.follower,
  });

  factory CheeseUpInfo.fromJson(Map<String, dynamic> json) {
    return CheeseUpInfo(
      mid: biliToInt(json['mid']),
      name: biliAsStr(json['uname'] ?? json['nickname']),
      avatar: biliNormalizeUrl(biliAsStr(json['avatar'])),
      brief: biliAsStr(json['brief']),
      follower: biliToInt(json['follower']),
    );
  }
}

                                
class CheeseUserStatus {
  final bool payed;       
  final bool favored;       
  final bool isExpired;
  final String expiryContent;          

                                                        
  final int lastEpId;
  final int lastTimeSec;

  const CheeseUserStatus({
    required this.payed,
    required this.favored,
    required this.isExpired,
    required this.expiryContent,
    required this.lastEpId,
    required this.lastTimeSec,
  });

  factory CheeseUserStatus.fromJson(Map<String, dynamic> json) {
    final progress = biliAsMap(json['progress']) ?? const <String, dynamic>{};
    return CheeseUserStatus(
      payed: biliToInt(json['payed']) == 1,
      favored: biliToInt(json['favored']) == 1,
      isExpired: json['is_expired'] == true,
      expiryContent: biliAsStr(
        json['user_expiry_content'] ?? json['expiry_info_content'],
      ),
      lastEpId: biliToInt(progress['last_ep_id']),
      lastTimeSec: biliToInt(progress['last_time']),
    );
  }
}

                       
class CheesePayment {
  final int price;
  final String priceFormat;
  final String priceUnit;        
  final String payShade;                      

  const CheesePayment({
    required this.price,
    required this.priceFormat,
    required this.priceUnit,
    required this.payShade,
  });

  String get displayPrice =>
      priceFormat.isEmpty ? '$price' : '$priceFormat $priceUnit'.trim();

  factory CheesePayment.fromJson(Map<String, dynamic> json) {
    return CheesePayment(
      price: biliToInt(json['price']),
      priceFormat: biliAsStr(json['price_format'] ?? json['desc']),
      priceUnit: biliAsStr(json['price_unit']),
      payShade: biliAsStr(json['pay_shade']),
    );
  }
}

                                      
class CheeseSeason {
  final int seasonId;
  final String title;
  final String subtitle;
  final String cover;
  final int epCount;
  final int playCount;
  final CheeseUpInfo? up;
  final CheeseUserStatus userStatus;
  final CheesePayment? payment;
  final String briefContent;                     
  final List<CheeseEpisode> episodes;

                                             
                               
  final bool episodesHasNext;

                                                       
  final int episodesPageSize;

  const CheeseSeason({
    required this.seasonId,
    required this.title,
    required this.subtitle,
    required this.cover,
    required this.epCount,
    required this.playCount,
    required this.up,
    required this.userStatus,
    required this.payment,
    required this.briefContent,
    required this.episodes,
    required this.episodesHasNext,
    this.episodesPageSize = 0,
  });

  factory CheeseSeason.fromJson(Map<String, dynamic> json) {
    final page = biliAsMap(json['episode_page']) ?? const <String, dynamic>{};
    final stat = biliAsMap(json['stat']) ?? const <String, dynamic>{};
    final brief = biliAsMap(json['brief']) ?? const <String, dynamic>{};
    return CheeseSeason(
      seasonId: biliToInt(json['season_id']),
      title: biliAsStr(json['title']),
      subtitle: biliAsStr(json['subtitle']),
      cover: biliNormalizeUrl(biliAsStr(json['cover'])),
      epCount: biliToInt(json['ep_count']),
      playCount: biliToInt(stat['play']),
      up: biliAsMap(json['up_info']) == null
          ? null
          : CheeseUpInfo.fromJson(json['up_info']),
      userStatus: CheeseUserStatus.fromJson(
        biliAsMap(json['user_status']) ?? const <String, dynamic>{},
      ),
      payment: biliAsMap(json['payment']) == null
          ? null
          : CheesePayment.fromJson(json['payment']),
      briefContent: biliAsStr(brief['content']),
      episodes: biliAsList<Map<String, dynamic>>(
        json['episodes'],
      ).map(CheeseEpisode.fromJson).toList(),
      episodesHasNext: page['next'] == true,
      episodesPageSize: biliToInt(page['size']),
    );
  }
}

                                                   
class CheeseCourseItem {
  final int seasonId;
  final String title;
  final String subtitle;
  final String cover;
  final int epCount;
  final String statusText;           
  final int play;

  const CheeseCourseItem({
    required this.seasonId,
    required this.title,
    required this.subtitle,
    required this.cover,
    required this.epCount,
    required this.statusText,
    required this.play,
  });

  factory CheeseCourseItem.fromJson(Map<String, dynamic> json) {
    return CheeseCourseItem(
      seasonId: biliToInt(json['season_id']),
      title: biliAsStr(json['title']),
      subtitle: biliAsStr(json['subtitle']),
      cover: biliNormalizeUrl(biliAsStr(json['cover'])),
      epCount: biliToInt(json['ep_count']),
      statusText: biliAsStr(json['status']),
      play: biliToInt(json['play']),
    );
  }
}

                                        
class CheeseUpowerLevel {
  final int privilegeType;
  final String name;
  final int memberTotal;
  final int price;

  const CheeseUpowerLevel({
    required this.privilegeType,
    required this.name,
    required this.memberTotal,
    required this.price,
  });

  factory CheeseUpowerLevel.fromJson(Map<String, dynamic> json) {
    return CheeseUpowerLevel(
      privilegeType: biliToInt(json['privilege_type']),
      name: biliAsStr(json['name']),
      memberTotal: biliToInt(json['member_total']),
      price: biliToInt(json['price']),
    );
  }
}

                            
class CheeseUpowerRankEntry {
  final int mid;
  final String nickname;
  final String avatar;
  final int rank;
  final int day;          

  const CheeseUpowerRankEntry({
    required this.mid,
    required this.nickname,
    required this.avatar,
    required this.rank,
    required this.day,
  });

  factory CheeseUpowerRankEntry.fromJson(Map<String, dynamic> json) {
    return CheeseUpowerRankEntry(
      mid: biliToInt(json['mid']),
      nickname: biliAsStr(json['nickname']),
      avatar: biliNormalizeUrl(biliAsStr(json['avatar'])),
      rank: biliToInt(json['rank']),
      day: biliToInt(json['day']),
    );
  }
}

                                             
class CheeseUpowerRank {
  final List<CheeseUpowerRankEntry> entries;
  final List<CheeseUpowerLevel> levels;
  final int memberTotal;

  const CheeseUpowerRank({
    required this.entries,
    required this.levels,
    required this.memberTotal,
  });

  factory CheeseUpowerRank.fromJson(Map<String, dynamic> json) {
    return CheeseUpowerRank(
      entries: biliAsList<Map<String, dynamic>>(
        json['rank_info'],
      ).map(CheeseUpowerRankEntry.fromJson).toList(),
      levels: biliAsList<Map<String, dynamic>>(
        json['level_info'],
      ).map(CheeseUpowerLevel.fromJson).toList(),
      memberTotal: biliToInt(json['member_total']),
    );
  }
}

                                            
      
                                            

abstract final class BilibiliCheeseService {
  static const String _apiBase = 'https://api.bilibili.com';
  static const String _seasonApi = '$_apiBase/pugv/view/web/season';
  static const String _epListApi = '$_apiBase/pugv/view/web/ep/list';
  static const String _playUrlApi = '$_apiBase/pugv/player/web/playurl';
  static const String _userCoursesApi = '$_apiBase/pugv/app/web/season/page';
  static const String _upowerRankApi =
      '$_apiBase/x/upower/up/member/rank/v2';

  static const String _defaultUA =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

                                    
  static String? lastErrorDetail;

  static Map<String, String> _headers({required String referer}) {
    final cookie = biliLoginCookie(BiliCookieScope.video);
    return {
      'User-Agent': _defaultUA,
      'Referer': referer,
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

                                         
  static bool get hasLoginCookie =>
      (biliLoginCookie(BiliCookieScope.video) ?? '').isNotEmpty;

  static Future<Map<String, dynamic>?> _getJson(
    Uri uri,
    Map<String, String> headers,
    String tag,
  ) async {
    final client = await NetworkSettingsService.instance.getApiClient();
    final resp = await client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      lastErrorDetail = 'HTTP ${resp.statusCode}';
      debugPrint('[$tag] HTTP ${resp.statusCode}');
      return null;
    }
    final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
    if (json is! Map<String, dynamic>) {
      lastErrorDetail = '返回内容不是 JSON 对象';
      return null;
    }
    final code = biliToInt(json['code']);
    if (code != 0) {
      final msg = biliAsStr(json['message'] ?? json['msg']);
      lastErrorDetail = msg.isEmpty ? '接口返回 $code' : msg;
      debugPrint('[$tag] code=$code $msg');
      return null;
    }
    return json;
  }

                                            
                                                 
                                          
  static Future<CheeseSeason?> fetchSeason({
    required int seasonId,
    int? epId,
  }) async {
    if (seasonId <= 0) {
      lastErrorDetail = 'season_id 为空';
      return null;
    }
    try {
      final uri = Uri.parse(_seasonApi).replace(
        queryParameters: {
          'season_id': seasonId.toString(),
          if (epId != null && epId > 0) 'ep_id': epId.toString(),
        },
      );
      final json = await _getJson(uri, _cheeseHeaders(seasonId), 'BiliCheese');
      if (json == null) return null;
      final data = biliAsMap(json['data']);
      if (data == null) {
        lastErrorDetail = '课程不存在';
        return null;
      }
      final season = CheeseSeason.fromJson(data);
      if (!season.episodesHasNext) {
        lastErrorDetail = null;
        return season;
      }
                                            
                                                      
                                   
      final pageSize = season.episodesPageSize > 0 ? season.episodesPageSize : 20;
      final merged = <int, CheeseEpisode>{
        for (final e in season.episodes) e.epId: e,
      };
      for (var pn = 2; pn <= 21; pn++) {
        final page = await fetchEpisodes(
          seasonId: seasonId,
          pn: pn,
          ps: pageSize,
        );
        if (page == null || page.items.isEmpty) break;
        for (final e in page.items) {
          merged[e.epId] = e;
        }
        if (!page.hasNext) break;
      }
      lastErrorDetail = null;
      return CheeseSeason(
        seasonId: season.seasonId,
        title: season.title,
        subtitle: season.subtitle,
        cover: season.cover,
        epCount: season.epCount,
        playCount: season.playCount,
        up: season.up,
        userStatus: season.userStatus,
        payment: season.payment,
        briefContent: season.briefContent,
        episodes: merged.values.toList(),
        episodesHasNext: false,
      );
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[BiliCheese] 拉取课程详情异常: $e');
      return null;
    }
  }

                                
  static Map<String, String> _cheeseHeaders(int seasonId, {int? epId}) {
    final referer = 'https://www.bilibili.com/cheese/play/'
        '${epId != null && epId > 0 ? 'ep$epId' : 'ss$seasonId'}';
    return _headers(referer: referer);
  }

                                    
  static Future<({List<CheeseEpisode> items, bool hasNext})?> fetchEpisodes({
    required int seasonId,
    int pn = 1,
    int ps = 20,
  }) async {
    try {
      final uri = Uri.parse(_epListApi).replace(
        queryParameters: {
          'season_id': seasonId.toString(),
          'pn': pn.toString(),
          'ps': ps.toString(),
        },
      );
      final json = await _getJson(uri, _cheeseHeaders(seasonId), 'BiliCheese');
      if (json == null) return null;
      final data = biliAsMap(json['data']);
      if (data == null) return null;
      final page = biliAsMap(data['page']) ?? const <String, dynamic>{};
      return (
        items: biliAsList<Map<String, dynamic>>(
          data['items'],
        ).map(CheeseEpisode.fromJson).toList(),
        hasNext: page['next'] == true,
      );
    } catch (e) {
      debugPrint('[BiliCheese] 拉取分集列表异常: $e');
      return null;
    }
  }

                                      
                                                            
                                          
                                         
  static ({BiliPlayUrl playUrl, int resumeMs}) parsePlayurlData(
    Map<String, dynamic> data,
  ) {
    final map = Map<String, dynamic>.from(data);
    if (map['durl'] == null && map['durls'] is List) {
      map['durl'] = map['durls'];
    }
    final watch = biliAsMap(
      biliAsMap(
        biliAsMap(map['play_view_business_info'])?['user_status'],
      )?['watch_progress'],
    );
    var resumeMs = biliToInt(watch?['current_watch_progress']);
    final timelength = biliToInt(map['timelength']);
    if (timelength > 0 && resumeMs > timelength) resumeMs = 0;
    return (playUrl: BiliPlayUrl.fromJson(map), resumeMs: resumeMs);
  }

                                                          
                                    
  static Future<({BiliPlayUrl playUrl, int resumeMs})?> fetchPlayUrl({
    required int seasonId,
    required int epId,
    int aid = 0,
    int cid = 0,
    int qn = 0,
  }) async {
    if (seasonId <= 0 || epId <= 0) {
      lastErrorDetail = '参数不完整';
      return null;
    }
    try {
      final params = await WbiSign.sign({
        if (aid > 0) 'avid': aid.toString(),
        'season_id': seasonId.toString(),
        'ep_id': epId.toString(),
        if (cid > 0) 'cid': cid.toString(),
        'qn': (qn > 0 ? qn : 64).toString(),
                                        
        'fnval': '4048',
        'fnver': '0',
        'fourk': '1',
                                          
        'try_look': '1',
        'gaia_source': 'pre-load',
        'web_location': '1315873',
        'platform': 'web',
      });
      final uri = Uri.parse(_playUrlApi).replace(queryParameters: params);
      final json = await _getJson(
        uri,
        _cheeseHeaders(seasonId, epId: epId),
        'BiliCheese',
      );
      if (json == null) return null;
      final data = biliAsMap(json['data']);
      if (data == null) {
        lastErrorDetail ??= '播放地址为空';
        return null;
      }
      lastErrorDetail = null;
      return parsePlayurlData(data);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[BiliCheese] 解析播放地址异常: $e');
      return null;
    }
  }

                                                   
  static Future<({List<CheeseCourseItem> items, bool hasMore})?>
  fetchUserCourses({required int mid, int pn = 1}) async {
    if (mid <= 0) {
      lastErrorDetail = 'mid 为空';
      return null;
    }
    try {
      final uri = Uri.parse(_userCoursesApi).replace(
        queryParameters: {
          'pn': pn.toString(),
          'ps': '30',
          'mid': mid.toString(),
          'web_location': '333.1387',
        },
      );
      final json = await _getJson(
        uri,
        _headers(referer: 'https://space.bilibili.com/$mid/upload/cheese'),
        'BiliCheese',
      );
      if (json == null) return null;
      final data = biliAsMap(json['data']);
      if (data == null) return null;
      final page = biliAsMap(data['page']) ?? const <String, dynamic>{};
      final items = biliAsList<Map<String, dynamic>>(
        data['items'],
      ).map(CheeseCourseItem.fromJson).toList();
      return (items: items, hasMore: page['next'] == true);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[BiliCheese] 拉取课程列表异常: $e');
      return null;
    }
  }

                                              
                                      
  static Future<CheeseUpowerRank?> fetchUpowerRank({
    required int upMid,
    int pn = 1,
    int? privilegeType,
  }) async {
    if (upMid <= 0) {
      lastErrorDetail = 'up_mid 为空';
      return null;
    }
    try {
      final cookie = biliLoginCookie(BiliCookieScope.userSpace);
      final uri = Uri.parse(_upowerRankApi).replace(
        queryParameters: {
          'up_mid': upMid.toString(),
          'pn': pn.toString(),
          'ps': '100',
          if (privilegeType != null && privilegeType > 0)
            'privilege_type': privilegeType.toString(),
          'mobi_app': 'web',
          'web_location': '333.1196',
          if (cookie != null && cookie.isNotEmpty)
            'csrf': biliExtractCsrf(cookie),
        },
      );
      final json = await _getJson(
        uri,
        _headers(referer: 'https://space.bilibili.com/$upMid/'),
        'BiliUpower',
      );
      if (json == null) return null;
      final data = biliAsMap(json['data']);
      if (data == null) {
        lastErrorDetail ??= '充电榜为空';
        return null;
      }
      lastErrorDetail = null;
      return CheeseUpowerRank.fromJson(data);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[BiliUpower] 拉取充电榜异常: $e');
      return null;
    }
  }
}
