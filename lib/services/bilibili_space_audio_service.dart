                                                 
  
                                                                         
                                                       
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/paged_result.dart';

class BilibiliSpaceAudioService {
  static String? lastErrorDetail;

  static Future<PagedResult<BiliSpaceAudioItem>> fetch({
    required int mid,
    int pn = 1,
    int ps = 20,
  }) async {
    try {
      final params = <String, String>{
        'pn': pn.toString(),
        'ps': ps.toString(),
        'order': '1',
        'uid': mid.toString(),
        'web_location': '333.1387',
      };
      final uri = Uri.parse(
        'https://api.bilibili.com/audio/music-service/web/song/upper',
      ).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final cookie = biliLoginCookie(BiliCookieScope.userSpace);
      final headers = {...NetworkSettingsService.instance.apiHeaders};
      if (cookie != null) headers['Cookie'] = cookie;
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map || (json['code'] != 0 && json['code'] != 200)) {
        throw Exception('code=${json['code']} ${json['message']}');
      }
      final data = biliAsMap(json['data']) ?? {};
      final total = biliToInt(data['totalSize']);
      final list = biliAsList<dynamic>(data['data']);
      final items = list
          .map((e) => BiliSpaceAudioItem.fromJson(biliAsMap(e) ?? {}))
          .toList();
      final hasMore = items.length >= ps && (total == 0 || pn * ps < total);
      return PagedResult(items, hasMore);
    } catch (e) {
      lastErrorDetail = e.toString();
      rethrow;
    }
  }
}

class BiliSpaceAudioItem {
  final int id;
  final int uid;
  final String title;
  final String cover;
  final int aid;
  final String bvid;
  final int cid;
  final int ctime;
  final int play;
  final int comment;

  const BiliSpaceAudioItem({
    required this.id,
    required this.uid,
    required this.title,
    required this.cover,
    required this.aid,
    required this.bvid,
    required this.cid,
    required this.ctime,
    required this.play,
    required this.comment,
  });

  factory BiliSpaceAudioItem.fromJson(Map<String, dynamic> json) {
    final stat = biliAsMap(json['statistic']) ?? {};
    return BiliSpaceAudioItem(
      id: biliToInt(json['id']),
      uid: biliToInt(json['uid']),
      title: biliAsStr(json['title']),
      cover: biliNormalizeUrl(biliAsStr(json['cover'])),
      aid: biliToInt(json['aid']),
      bvid: biliAsStr(json['bvid']),
      cid: biliToInt(json['cid']),
      ctime: biliToInt(json['ctime']),
      play: biliToInt(stat['play']),
      comment: biliToInt(stat['comment']),
    );
  }

  String get webUrl => 'https://www.bilibili.com/audio/au$aid';
}
