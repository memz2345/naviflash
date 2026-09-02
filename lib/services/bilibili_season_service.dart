// lib/services/bilibili_season_service.dart
// 番剧 SS 号（season_id）剧集信息：通过 pgc/web/season/section 获取
// 全部集数的名称与 cid，用于给播放列表逐集附加弹幕。
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/network_settings_service.dart';

/// 番剧单集信息
class SeasonEpisode {
  final int epId; // ep_id（分集 id）
  final int cid; // 弹幕 oid
  final int aid;
  final String title; // 第1话 xxx
  final String longTitle;
  final int duration; // 秒

  const SeasonEpisode({
    required this.epId,
    required this.cid,
    required this.aid,
    required this.title,
    required this.longTitle,
    required this.duration,
  });

  factory SeasonEpisode.fromJson(Map<String, dynamic> json) => SeasonEpisode(
        epId: (json['id'] as num?)?.toInt() ?? 0,
        cid: (json['cid'] as num?)?.toInt() ?? 0,
        aid: (json['aid'] as num?)?.toInt() ?? 0,
        title: (json['title'] as String?) ?? '',
        longTitle: (json['long_title'] as String?) ?? '',
        duration: (json['duration'] as num?)?.toInt() ?? 0,
      );

  String get displayTitle =>
      longTitle.isNotEmpty ? longTitle : title;
}

class BilibiliSeasonService {
  BilibiliSeasonService._();

  static const String _sectionApi =
      'https://api.bilibili.com/pgc/web/season/section';

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  /// 按 SS 号获取全部剧集（main_section + 各 sections，按顺序去重合并），
  /// 失败返回 null。
  static Future<List<SeasonEpisode>?> fetchSections(String ss) async {
    final trimmed = ss.trim();
    if (trimmed.isEmpty || !RegExp(r'^\d+$').hasMatch(trimmed)) return null;
    try {
      final uri = Uri.parse(_sectionApi)
          .replace(queryParameters: {'season_id': trimmed});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            uri,
            headers: {
              ..._headers,
//  用户登录且开启「携带 Cookie 请求」时附加 Cookie
              ...?BilibiliAccountService.instance
                  .cookieHeaderFor(BiliCookieScope.season),
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;

      final result = json['result'];
      return parseResult(result);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 获取番剧剧集失败: $e');
      return null;
    }
  }

  /// 解析接口返回的 result 字段（main_section + sections 按顺序去重合并）
  static List<SeasonEpisode>? parseResult(dynamic result) {
    if (result is! Map<String, dynamic>) return null;

    final episodes = <Map<String, dynamic>>[];
    final seen = <int>{};

    void collect(dynamic section) {
      if (section is! Map<String, dynamic>) return;
      final list = section['episodes'];
      if (list is! List) return;
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final id = (e['id'] as num?)?.toInt() ?? 0;
        if (id == 0 || seen.contains(id)) continue;
        seen.add(id);
        episodes.add(e);
      }
    }

    collect(result['main_section']);
    final sections = result['sections'];
    if (sections is List) {
      for (final s in sections) {
        collect(s);
      }
    }

    if (episodes.isEmpty) return null;
    return episodes
        .map(SeasonEpisode.fromJson)
        .where((e) => e.cid > 0)
        .toList();
  }
}
