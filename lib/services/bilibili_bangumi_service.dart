                                             
  
                                               
                                                      
                                                                
                                                                   
                 
                                           
                                                      
                                                 
                                          

import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_video_service.dart'
    show BiliPlayUrl, BilibiliVideoService;
import 'package:naviflash/services/network_settings_service.dart';

                                            
                        
                                            

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

String _toStr(dynamic v) => v?.toString() ?? '';

         
class BiliBangumiEpisode {
  final int aid;                  
  final String bvid;
  final int cid;             
  final int epId;                
  final String title;       
  final String longTitle;           
  final String cover;
  final int durationMs;
  final String badge;               
  final int badgeType;                      

  const BiliBangumiEpisode({
    required this.aid,
    required this.bvid,
    required this.cid,
    required this.epId,
    required this.title,
    required this.longTitle,
    required this.cover,
    required this.durationMs,
    required this.badge,
    required this.badgeType,
  });

  String get displayTitle => longTitle.isNotEmpty ? longTitle : title;

  factory BiliBangumiEpisode.fromJson(Map<String, dynamic> json) {
    return BiliBangumiEpisode(
      aid: _toInt(json['aid']),
      bvid: _toStr(json['bvid']),
      cid: _toInt(json['cid']),
      epId: _toInt(json['id']),
      title: _toStr(json['title']),
      longTitle: _toStr(json['long_title']),
      cover: _toStr(json['cover']),
      durationMs: _toInt(json['duration']),
      badge: _toStr(json['badge']),
      badgeType: _toInt(json['badge_type']),
    );
  }
}

                  
class BiliBangumiStat {
  final int views;
  final int danmakus;
  final int follow;
  final int coins;
  final int likes;
  final int favorite;               

  const BiliBangumiStat({
    required this.views,
    required this.danmakus,
    required this.follow,
    required this.coins,
    required this.likes,
    this.favorite = 0,
  });

  factory BiliBangumiStat.fromJson(Map<String, dynamic> json) =>
      BiliBangumiStat(
        views: _toInt(json['views']),
        danmakus: _toInt(json['danmakus']),
        follow: _toInt(json['follow']),
        coins: _toInt(json['coins']),
        likes: _toInt(json['likes']),
        favorite: _toInt(json['favorite']),
      );
}

                                       
class BiliBangumiDetail {
  final int seasonId;
  final int mediaId;
  final String title;
  final String subtitle;
  final String seasonTitle;
  final String evaluate;      
  final String cover;
  final String link;
  final int type;                                                    
  final String badge;
  final double ratingScore;
  final int ratingCount;
  final BiliBangumiStat stat;
  final List<BiliBangumiEpisode> episodes;
  final List<String> styles;        
  final String staff;              
  final String actors;      
  final int newEpId;                        
  final String newEpDesc;            
  final int pubTime;                          
  final bool followed;                           
  final int followStatus;                      
  final int lastEpId;                                         
  final int lastTimeMs;                                  

  const BiliBangumiDetail({
    required this.seasonId,
    required this.mediaId,
    required this.title,
    required this.subtitle,
    required this.seasonTitle,
    required this.evaluate,
    required this.cover,
    required this.link,
    required this.type,
    required this.badge,
    required this.ratingScore,
    required this.ratingCount,
    required this.stat,
    required this.episodes,
    required this.styles,
    required this.staff,
    required this.actors,
    required this.newEpId,
    required this.newEpDesc,
    required this.pubTime,
    required this.followed,
    required this.followStatus,
    required this.lastEpId,
    required this.lastTimeMs,
  });

                          
  String get typeName => switch (type) {
    2 => '电影',
    3 => '纪录片',
    4 => '国创',
    5 => '电视剧',
    6 => '漫画',
    7 => '综艺',
    _ => '番剧',
  };

  factory BiliBangumiDetail.fromJson(Map<String, dynamic> json) {
                                                        
    final episodes = <BiliBangumiEpisode>[];
    final seen = <int>{};
    void collect(dynamic section) {
      final m = _asMap(section);
      final list = m?['episodes'];
      if (list is! List) return;
      for (final e in list) {
        final em = _asMap(e);
        if (em == null) continue;
        final id = _toInt(em['id']);
        if (id == 0 || seen.contains(id)) continue;
        seen.add(id);
        episodes.add(BiliBangumiEpisode.fromJson(em));
      }
    }

    final topEpisodes = json['episodes'];
    if (topEpisodes is List) {
      for (final e in topEpisodes) {
        final em = _asMap(e);
        if (em == null) continue;
        final id = _toInt(em['id']);
        if (id == 0 || seen.contains(id)) continue;
        seen.add(id);
        episodes.add(BiliBangumiEpisode.fromJson(em));
      }
    }
    final mainSection = _asMap(json['main_section']);
    if (mainSection != null) collect(mainSection);
    final sections = json['sections'];
    if (sections is List) {
      for (final s in sections) {
        collect(s);
      }
    }

    final rating = _asMap(json['rating']) ?? const {};
    final statJson = _asMap(json['stat']) ?? const {};
    final userStatus = _asMap(json['user_status']) ?? const {};
    final progress = _asMap(userStatus['progress']) ?? const {};
    final newEp = _asMap(json['new_ep']) ?? const {};
    final publish = _asMap(json['publish']) ?? const {};
    final styleList = json['styles'] is List
        ? (json['styles'] as List)
              .whereType<Map<String, dynamic>>()
              .map((s) => _toStr(s['name']))
              .where((s) => s.isNotEmpty)
              .toList()
        : const <String>[];

    return BiliBangumiDetail(
      seasonId: _toInt(json['season_id']),
      mediaId: _toInt(json['media_id']),
      title: _toStr(json['title']),
      subtitle: _toStr(json['subtitle']),
      seasonTitle: _toStr(json['season_title']),
      evaluate: _toStr(json['evaluate']),
      cover: _toStr(json['cover']),
      link: _toStr(json['link']),
      type: _toInt(json['type']),
      badge: _toStr(json['badge']),
      ratingScore: _toDouble(rating['score']),
      ratingCount: _toInt(rating['count']),
      stat: BiliBangumiStat.fromJson(statJson),
      episodes: episodes,
      styles: styleList,
      staff: _toStr(json['staff']),
      actors: _toStr(json['actors']),
      newEpId: _toInt(newEp['id']),
      newEpDesc: _toStr(newEp['desc']),
      pubTime: _parsePubTime(publish['pub_time']),
      followed: _toInt(userStatus['follow']) == 1,
      followStatus: _toInt(userStatus['follow_status']),
      lastEpId: _toInt(progress['last_ep_id']),
      lastTimeMs: _toInt(progress['last_time']),
    );
  }

                                                          
                          
  static int _parsePubTime(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String && v.trim().isNotEmpty) {
      final dt = DateTime.tryParse(v.trim().replaceFirst(' ', 'T'));
      if (dt != null) return dt.millisecondsSinceEpoch ~/ 1000;
    }
    return 0;
  }
}

                    
class BiliBangumiEpisodeRelation {
  final bool liked;
  final bool favored;
  final int coinNumber;            

  const BiliBangumiEpisodeRelation({
    required this.liked,
    required this.favored,
    required this.coinNumber,
  });

  factory BiliBangumiEpisodeRelation.fromJson(Map<String, dynamic> json) {
    return BiliBangumiEpisodeRelation(
      liked: _toInt(json['like']) == 1,
      favored: _toInt(json['favorite']) == 1,
      coinNumber: _toInt(json['coin_number']),
    );
  }
}

                                            
      
                                            

abstract final class BilibiliBangumiService {
  static const String _seasonApi =
      'https://api.bilibili.com/pgc/view/web/season';
  static const String _playUrlApi =
      'https://api.bilibili.com/pgc/player/web/v2/playurl';
  static const String _seasonStatusApi =
      'https://api.bilibili.com/pgc/view/web/season/user/status';
  static const String _followAddApi =
      'https://api.bilibili.com/pgc/web/follow/add';
  static const String _followDelApi =
      'https://api.bilibili.com/pgc/web/follow/del';
  static const String _episodeCommunityApi =
      'https://api.bilibili.com/pgc/season/episode/community';
  static const String _pgcTripleApi =
      'https://api.bilibili.com/pgc/season/episode/like/triple';

  static const String _defaultUA =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

                                    
  static String? lastErrorDetail;

  static Map<String, String> _headers({
    String referer = 'https://www.bilibili.com',
  }) {
    return {
      'User-Agent': _defaultUA,
      'Referer': referer,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

                                              
                            
  static Map<String, String> _seasonHeaders(int seasonId) {
    final referer = 'https://www.bilibili.com/bangumi/play/ss$seasonId';
    return {
      ..._headers(referer: referer),
      ...?BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.season,
      ),
    };
  }

                                     
  static Future<BiliBangumiDetail?> fetchSeason(int seasonId) async {
    if (seasonId <= 0) {
      lastErrorDetail = 'SS 号为空';
      return null;
    }
    try {
      final uri = Uri.parse(
        _seasonApi,
      ).replace(queryParameters: {'season_id': seasonId.toString()});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _seasonHeaders(seasonId))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[BiliBangumi] season HTTP ${resp.statusCode}');
        return null;
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint(
          '[BiliBangumi] season code=${json['code']} ${json['message']}',
        );
        return null;
      }
      final result = _asMap(json['result']);
      if (result == null) {
        lastErrorDetail = '番剧不存在';
        return null;
      }
      lastErrorDetail = null;
      return BiliBangumiDetail.fromJson(result);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[BiliBangumi] 拉取番剧详情异常: $e');
      return null;
    }
  }

                                                         
                                           
  static Future<BiliPlayUrl?> fetchPlayUrl({
    required int seasonId,
    required String bvid,
    required int cid,
    required int epId,
    int qn = 0,
  }) async {
    if (cid <= 0 || (bvid.isEmpty && epId <= 0)) {
      lastErrorDetail = '参数不完整';
      return null;
    }
    try {
                                                 
      int effectiveQn = qn;
      if (effectiveQn <= 0) {
        effectiveQn = await BilibiliVideoService.resolveDefaultQn();
      }
      final uri = Uri.parse(_playUrlApi).replace(
        queryParameters: {
          'cid': cid.toString(),
          if (bvid.isNotEmpty) 'bvid': bvid,
          if (epId > 0) 'ep_id': epId.toString(),
          'qn': (effectiveQn > 0 ? effectiveQn : 64).toString(),
          'fnval': '4048',
          'fnver': '0',
          'fourk': '1',
          'try_look': '1',
          'gaia_source': 'pre-load',
          'web_location': '1315873',
          'platform': 'web',
          'otype': 'json',
          'type': '',
          'voice_balance': '1',
        },
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _seasonHeaders(seasonId))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[BiliBangumi] playurl HTTP ${resp.statusCode}');
        return null;
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint(
          '[BiliBangumi] playurl code=${json['code']} ${json['message']}',
        );
        return null;
      }
      final videoInfo = _asMap(json['result'])?['video_info'];
      final info = _asMap(videoInfo);
      if (info == null) {
        lastErrorDetail = '播放地址为空';
        return null;
      }
      lastErrorDetail = null;
      return BiliPlayUrl.fromJson(info);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[BiliBangumi] 解析播放地址异常: $e');
      return null;
    }
  }

                                       
                                      
  static Future<int?> fetchSeasonStatus(int seasonId) async {
    if (BilibiliAccountService.instance.cookieHeaderFor(
          BiliCookieScope.season,
        ) ==
        null) {
      return null;
    }
    try {
      final uri = Uri.parse(
        _seasonStatusApi,
      ).replace(queryParameters: {'season_id': seasonId.toString()});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _seasonHeaders(seasonId))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;
      return _toInt(_asMap(json['result'])?['follow_status']);
    } catch (e) {
      debugPrint('[BiliBangumi] 拉取追番状态异常: $e');
      return null;
    }
  }

                                               
                                                    
                               
  static Future<({bool ok, String message})> setFollow({
    required int seasonId,
    required bool follow,
    int? status,
  }) async {
    final cookieHeader = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.interactions,
    );
    if (cookieHeader == null) {
      return (ok: false, message: '请先登录并开启「携带 Cookie 请求」');
    }
    final rawCookie = cookieHeader['Cookie'] ?? '';
    final csrf =
        RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(rawCookie)?.group(1) ??
        '';
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(follow ? _followAddApi : _followDelApi),
            headers: {
              ..._seasonHeaders(seasonId),
              ...cookieHeader,
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'season_id': seasonId.toString(),
              if (follow && status != null) 'status': status.toString(),
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        return (ok: false, message: '${json['message']}');
      }
      return (ok: true, message: _toStr(json['result']?['toast']));
    } catch (e) {
      debugPrint('[BiliBangumi] 追番操作异常: $e');
      return (ok: false, message: '$e');
    }
  }

                                       
  static Future<BiliBangumiEpisodeRelation?> fetchEpisodeRelation(
    int epId,
  ) async {
    if (epId <= 0) return null;
    if (BilibiliAccountService.instance.cookieHeaderFor(
          BiliCookieScope.interactions,
        ) ==
        null) {
      return null;
    }
    try {
      final uri = Uri.parse(
        _episodeCommunityApi,
      ).replace(queryParameters: {'ep_id': epId.toString()});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            uri,
            headers: {
              ..._headers(),
              ...?BilibiliAccountService.instance.cookieHeaderFor(
                BiliCookieScope.interactions,
              ),
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;
      final data = _asMap(json['data']);
      if (data == null) return null;
      return BiliBangumiEpisodeRelation.fromJson(data);
    } catch (e) {
      debugPrint('[BiliBangumi] 拉取单集互动状态异常: $e');
      return null;
    }
  }

  static Future<({bool ok, String message})> triple(int epId) async {
    final cookieHeader = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.interactions,
    );
    if (cookieHeader == null) {
      return (ok: false, message: '请先登录并开启「携带 Cookie 请求」');
    }
    final rawCookie = cookieHeader['Cookie'] ?? '';
    final csrf =
        RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(rawCookie)?.group(1) ??
        '';
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_pgcTripleApi),
            headers: {
              ..._headers(
                referer: 'https://www.bilibili.com/bangumi/play/ep$epId',
              ),
              ...cookieHeader,
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'ep_id': epId.toString(), 'csrf': csrf},
          )
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        return (ok: false, message: '${json['message']}');
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[BiliBangumi] 三连异常: $e');
      return (ok: false, message: '$e');
    }
  }

                                              
                                              
                                              

  static const String _timelineApi = 'https://api.bilibili.com/pgc/web/timeline';
  static const String _reviewLongApi =
      'https://api.bilibili.com/pgc/review/long/list';
  static const String _reviewShortApi =
      'https://api.bilibili.com/pgc/review/short/list';
  static const String _reviewLikeApi =
      'https://api.bilibili.com/pgc/review/action/like';
  static const String _reviewDislikeApi =
      'https://api.bilibili.com/pgc/review/action/dislike';
  static const String _reviewPostApi =
      'https://api.bilibili.com/pgc/review/short/post';

                                                     
  static Future<List<BiliTimelineDay>> fetchTimeline() async {
    Future<List<BiliTimelineDay>> one(int type) async {
      try {
        final uri = Uri.parse(_timelineApi).replace(
          queryParameters: {
            'types': type.toString(),
            'before': '6',
            'after': '6',
          },
        );
        final client = await NetworkSettingsService.instance.getApiClient();
        final resp = await client
            .get(uri, headers: _headers())
            .timeout(const Duration(seconds: 15));
        if (resp.statusCode != 200) return const [];
        final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
        if (json is! Map<String, dynamic> || _toInt(json['code']) != 0) {
          return const [];
        }
        final result = json['result'];
        if (result is! List) return const [];
        return result
            .whereType<Map<String, dynamic>>()
            .map(BiliTimelineDay.fromJson)
            .toList();
      } catch (e) {
        debugPrint('[BiliBangumi] 拉取时间表失败: $e');
        return const [];
      }
    }

    final results = await Future.wait([one(1), one(4)]);
              
    final merged = <String, BiliTimelineDay>{};
    for (final list in results) {
      for (final day in list) {
        final existing = merged[day.date];
        if (existing == null) {
          merged[day.date] = day;
        } else {
          existing.episodes.addAll(day.episodes);
        }
      }
    }
    final days = merged.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return days;
  }

                                          
  static Future<BiliPgcReviews?> fetchReviews({
    required int mediaId,
    required bool long,
    int sort = 0,
    String cursor = '',
  }) async {
    if (mediaId <= 0) return null;
    try {
      final uri = Uri.parse(long ? _reviewLongApi : _reviewShortApi).replace(
        queryParameters: {
          'media_id': mediaId.toString(),
          'ps': '20',
          'sort': sort.toString(),
          if (cursor.isNotEmpty) 'cursor': cursor,
          'web_location': '666.19',
        },
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> || _toInt(json['code']) != 0) {
        return null;
      }
      final data = _asMap(json['data']);
      if (data == null) return null;
      final list = data['list'];
      return BiliPgcReviews(
        items: list is List
            ? list
                .whereType<Map<String, dynamic>>()
                .map(BiliPgcReview.fromJson)
                .toList()
            : const [],
        next: _toStr(data['next']),
        count: _toInt(data['count'] ?? data['total']),
      );
    } catch (e) {
      debugPrint('[BiliBangumi] 拉取点评失败: $e');
      return null;
    }
  }

                                         
  static Future<({bool ok, String message})> reviewAction({
    required int mediaId,
    required int reviewId,
    required bool like,
  }) async {
    final cookieHeader = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.interactions,
    );
    if (cookieHeader == null) {
      return (ok: false, message: '请先登录并开启「携带 Cookie 请求」');
    }
    final rawCookie = cookieHeader['Cookie'] ?? '';
    final csrf =
        RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(rawCookie)?.group(1) ??
        '';
    try {
      final resp = await (await NetworkSettingsService.instance.getApiClient())
          .post(
            Uri.parse(like ? _reviewLikeApi : _reviewDislikeApi),
            headers: {
              ..._headers(),
              ...cookieHeader,
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'media_id': mediaId.toString(),
              'review_type': '2',
              'review_id': reviewId.toString(),
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        return (ok: false, message: '${json['message']}');
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[BiliBangumi] 点评互动异常: $e');
      return (ok: false, message: '$e');
    }
  }

                                     
  static Future<({bool ok, String message})> postShortReview({
    required int mediaId,
    required int score,
    required String content,
  }) async {
    final cookieHeader = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.interactions,
    );
    if (cookieHeader == null) {
      return (ok: false, message: '请先登录并开启「携带 Cookie 请求」');
    }
    final rawCookie = cookieHeader['Cookie'] ?? '';
    final csrf =
        RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(rawCookie)?.group(1) ??
        '';
    try {
      final resp = await (await NetworkSettingsService.instance.getApiClient())
          .post(
            Uri.parse(_reviewPostApi),
            headers: {
              ..._headers(),
              ...cookieHeader,
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'media_id': mediaId.toString(),
              'score': (score * 2).clamp(2, 10).toString(),
              'content': content,
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        return (ok: false, message: '${json['message']}');
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[BiliBangumi] 发表短评异常: $e');
      return (ok: false, message: '$e');
    }
  }
}

                                            
               
                                            

          
class BiliTimelineEpisode {
  final int epId;
  final int seasonId;
  final String title;
  final String cover;
  final String pubIndex;            
  final String pubTime;
  final int follow;           

  const BiliTimelineEpisode({
    required this.epId,
    required this.seasonId,
    required this.title,
    required this.cover,
    required this.pubIndex,
    required this.pubTime,
    required this.follow,
  });

  factory BiliTimelineEpisode.fromJson(Map<String, dynamic> json) {
    return BiliTimelineEpisode(
      epId: _toInt(json['episode_id']),
      seasonId: _toInt(json['season_id']),
      title: _toStr(json['title']),
      cover: _toStr(json['cover']),
      pubIndex: _toStr(json['pub_index']),
      pubTime: _toStr(json['pub_time']),
      follow: _toInt(json['follow']),
    );
  }
}

          
class BiliTimelineDay {
  final String date;
  final int dayOfWeek;       
  final bool isToday;
  final List<BiliTimelineEpisode> episodes;

  BiliTimelineDay({
    required this.date,
    required this.dayOfWeek,
    required this.isToday,
    required this.episodes,
  });

  factory BiliTimelineDay.fromJson(Map<String, dynamic> json) {
    return BiliTimelineDay(
      date: _toStr(json['date']),
      dayOfWeek: _toInt(json['day_of_week']),
      isToday: _toInt(json['is_today']) == 1,
      episodes: (json['episodes'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(BiliTimelineEpisode.fromJson)
              .toList() ??
          <BiliTimelineEpisode>[],
    );
  }
}

             
class BiliPgcReview {
  final int reviewId;
  final int articleId;             
  final int authorMid;
  final String authorName;
  final String authorFace;
  final String title;
  final String content;
  final String pushTime;
  final int score;         
  final int likes;
  final bool liked;
  final bool disliked;

  const BiliPgcReview({
    required this.reviewId,
    required this.articleId,
    required this.authorMid,
    required this.authorName,
    required this.authorFace,
    required this.title,
    required this.content,
    required this.pushTime,
    required this.score,
    required this.likes,
    required this.liked,
    required this.disliked,
  });

  factory BiliPgcReview.fromJson(Map<String, dynamic> json) {
    final author = _asMap(json['author']) ?? const <String, dynamic>{};
    final stat = _asMap(json['stat']) ?? const <String, dynamic>{};
    return BiliPgcReview(
      reviewId: _toInt(json['review_id']),
      articleId: _toInt(json['article_id']),
      authorMid: _toInt(author['mid']),
      authorName: _toStr(author['uname']),
      authorFace: _toStr(author['avatar']),
      title: _toStr(json['title']),
      content: _toStr(json['content']),
      pushTime: _toStr(json['push_time_str']),
      score: ((_toInt(json['score'])) / 2).round(),
      likes: _toInt(stat['likes']),
      liked: _toInt(stat['liked']) == 1,
      disliked: _toInt(stat['disliked']) == 1,
    );
  }
}

class BiliPgcReviews {
  final List<BiliPgcReview> items;
  final String next;
  final int count;

  const BiliPgcReviews({
    required this.items,
    required this.next,
    required this.count,
  });
}
