                                               
  
                                                             
                               
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/paged_result.dart';

class BilibiliFavTopicService {
  static String? lastErrorDetail;

  static Future<PagedResult<BiliFavTopicItem>> fetchList({
    int page = 1,
    int ps = 24,
  }) async {
    try {
      final cookie = biliLoginCookie(BiliCookieScope.interactions);
      if (cookie == null) throw Exception('未登录');
      final params = <String, String>{
        'page_size': ps.toString(),
        'page_num': page.toString(),
        'web_location': '333.1387',
      };
      final uri = Uri.parse('https://api.bilibili.com/x/topic/web/fav/list')
          .replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: {
            ...NetworkSettingsService.instance.apiHeaders,
            'Cookie': cookie,
          })
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map || (json['code'] != 0 && json['code'] != 200)) {
        throw Exception('code=${json['code']} ${json['message']}');
      }
      final data = biliAsMap(json['data']) ?? {};
      final topicList = biliAsMap(data['topic_list']) ?? {};
      final list = biliAsList<dynamic>(topicList['topic_items']);
      final items = list
          .map((e) => BiliFavTopicItem.fromJson(biliAsMap(e) ?? {}))
          .toList();
      final hasMore = items.length >= ps;
      return PagedResult(items, hasMore);
    } catch (e) {
      lastErrorDetail = e.toString();
      rethrow;
    }
  }

  static Future<bool> cancelFav({required int topicId}) async {
    try {
      final cookie = biliLoginCookie(BiliCookieScope.interactions);
      if (cookie == null) return false;
      final csrf = biliExtractCsrf(cookie);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse('https://api.bilibili.com/x/topic/fav/sub/cancel'),
            headers: {
              ...NetworkSettingsService.instance.apiHeaders,
              'Cookie': cookie,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'topic_id': topicId.toString(), 'csrf': csrf},
          )
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      return json is Map && (json['code'] == 0 || json['code'] == 200);
    } catch (e) {
      lastErrorDetail = e.toString();
      return false;
    }
  }
}

class BiliFavTopicItem {
  final int id;
  final String name;

  const BiliFavTopicItem({required this.id, required this.name});

  factory BiliFavTopicItem.fromJson(Map<String, dynamic> json) =>
      BiliFavTopicItem(id: biliToInt(json['id']), name: biliAsStr(json['name']));

  String get webUrl => 'https://www.bilibili.com/v/topic/$id';
}
