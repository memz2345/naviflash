// lib/services/bilibili_bangumi_service.dart
//
// lib/http/search.dart 的 pgcInfo 实现，按本项目风格精简）：
//   - 番剧详情：pgc/view/web/season（标题/简介/评分/统计/剧集列表/追番状态，
//   - 播放地址：pgc/player/web/v2/playurl（DASH 分轨 + FLV/MP4 durl 兜底，
//     result.video_info 与 UGC playurl data 结构一致，复用 BiliPlayUrl 解析；
//     无需 WBI 签名）
//   - 追番状态：pgc/view/web/season/user/status
//   - 追番/取消追番：pgc/web/follow/add / pgc/web/follow/del
// 请求方式与视频服务一致：复用 NetworkSettingsService 客户端与请求头；
// Cookie 遵循「携带 Cookie 请求」开关（番剧范围 + 互动范围）。

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_video_service.dart' show BiliPlayUrl;
import 'package:naviflash/services/network_settings_service.dart';

// ═════════════════════════════════════════
//  安全解析工具（字段类型不稳定，统一兜底）
// ═════════════════════════════════════════

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

/// 番剧单集。
class BiliBangumiEpisode {
  final int aid; // 分集 aid（评论 oid）
  final String bvid;
  final int cid; // 弹幕/播放 cid
  final int epId; // 分集 id（ep_id）
  final String title; // 第1话
  final String longTitle; // 第1话 xxx
  final String cover;
  final int durationMs;
  final String badge; // 会员 / 免费 等角标
  final int badgeType; // 0 预告 / 1 会员 / 2 免费

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

/// 番剧统计（stat 字段）。
class BiliBangumiStat {
  final int views;
  final int danmakus;
  final int follow;
  final int coins;
  final int likes;
  final int favorite; // 部分接口下发，无则 0

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

/// 番剧详情（pgc/view/web/season 的 result）。
class BiliBangumiDetail {
  final int seasonId;
  final int mediaId;
  final String title;
  final String subtitle;
  final String seasonTitle;
  final String evaluate; // 简介
  final String cover;
  final String link;
  final int type; // 1 番剧 / 2 电影 / 3 纪录片 / 4 国创 / 5 电视剧 / 6 漫画 / 7 综艺
  final String badge;
  final double ratingScore;
  final int ratingCount;
  final BiliBangumiStat stat;
  final List<BiliBangumiEpisode> episodes;
  final List<String> styles; // 风格标签
  final String staff; // 制作人员（换行分隔）
  final String actors; // 声优
  final int newEpId; // 最新话 ep_id（new_ep.id）
  final String newEpDesc; // 更新至第 x 话
  final int pubTime; // 上映时间（publish.pub_time）
  final bool followed; // user_status.follow == 1
  final int followStatus; // 1 想看 / 2 在看 / 3 看过
  final int lastEpId; // user_status.progress.last_ep_id（续播定位）
  final int lastTimeMs; // user_status.progress.last_time

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

  /// 类型名（番剧 / 国创 / 电影 …）。
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
    // main_section + sections（多季/多章时才有）按顺序去重合并（含预告/会员集）
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

  /// 上映时间：num 按 unix 秒处理；String（如 2022-10-30 00:30:00）解析后
  /// 转成 unix 秒，保证界面统一格式化。
  static int _parsePubTime(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String && v.trim().isNotEmpty) {
      final dt = DateTime.tryParse(v.trim().replaceFirst(' ', 'T'));
      if (dt != null) return dt.millisecondsSinceEpoch ~/ 1000;
    }
    return 0;
  }
}

/// pgcLikeCoinFav）。
class BiliBangumiEpisodeRelation {
  final bool liked;
  final bool favored;
  final int coinNumber; // 当前账号已投币数

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

// ═════════════════════════════════════════
//  服务
// ═════════════════════════════════════════

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

  /// 最近一次失败的具体原因（供界面展示，便于诊断），成功时清空。
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

  /// 拼装请求 Cookie：登录 Cookie 遵循「携带 Cookie 请求」开关
  /// （scope = season 番剧范围）。
  static Map<String, String> _seasonHeaders(int seasonId) {
    final referer = 'https://www.bilibili.com/bangumi/play/ss$seasonId';
    return {
      ..._headers(referer: referer),
      ...?BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.season,
      ),
    };
  }

  /// 按 SS 号拉取番剧详情（标题/评分/统计/剧集/追番状态）。
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
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
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

  /// 解析番剧播放地址（result.video_info 与 UGC playurl data 结构一致，
  /// 复用 BiliPlayUrl 解析；qn 为 0 时使用服务端默认档位）。
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
      final uri = Uri.parse(_playUrlApi).replace(
        queryParameters: {
          'cid': cid.toString(),
          if (bvid.isNotEmpty) 'bvid': bvid,
          if (epId > 0) 'ep_id': epId.toString(),
          'qn': (qn > 0 ? qn : 64).toString(),
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
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
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

  /// 追番状态（1 想看 / 2 在看 / 3 看过；未追番返回 0）。
  /// 需要登录且开启「携带 Cookie 请求」，否则返回 null。
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
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;
      return _toInt(_asMap(json['result'])?['follow_status']);
    } catch (e) {
      debugPrint('[BiliBangumi] 拉取追番状态异常: $e');
      return null;
    }
  }

  /// 追番 / 取消追番（需要登录 + 互动范围 Cookie + bili_jct）。
  static Future<({bool ok, String message})> setFollow({
    required int seasonId,
    required bool follow,
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
            body: {'season_id': seasonId.toString(), 'csrf': csrf},
          )
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        return (ok: false, message: '${json['message']}');
      }
      return (ok: true, message: _toStr(json['result']?['toast']));
    } catch (e) {
      debugPrint('[BiliBangumi] 追番操作异常: $e');
      return (ok: false, message: '$e');
    }
  }

  /// 拉取当前账号对单集的点赞/投币/收藏状态（未登录返回 null）。
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
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
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
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        return (ok: false, message: '${json['message']}');
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[BiliBangumi] 三连异常: $e');
      return (ok: false, message: '$e');
    }
  }
}
