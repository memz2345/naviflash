                                            
                                                      
                              
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/network_settings_service.dart';

          
class SeasonEpisode {
  final int epId;                
  final int cid;          
  final int aid;
  final String title;           
  final String longTitle;
  final int duration;     

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
                                   
              ...?BilibiliAccountService.instance
                  .cookieHeaderFor(BiliCookieScope.season),
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;

      final result = json['result'];
      return parseResult(result);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 获取番剧剧集失败: $e');
      return null;
    }
  }

                                                        
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
