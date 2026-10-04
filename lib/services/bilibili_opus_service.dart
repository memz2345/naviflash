                                          
  
                                                                  
                                
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart' show WbiSign;
import 'package:naviflash/services/network_settings_service.dart';

class BilibiliOpusService {
  static String? lastErrorDetail;

  static Future<({
    List<BiliOpusItem> items,
    bool hasMore,
    String? nextOffset,
  })> fetch({
    required int mid,
    int page = 1,
    String? offset,
    String type = 'all',
  }) async {
    try {
      final params = <String, String>{
        'host_mid': mid.toString(),
        'page': page.toString(),
        'offset': offset ?? '',
        'type': type,
        'web_location': '333.1387',
      };
      final signed = await WbiSign.sign(params);
      final uri = Uri.parse(
        'https://api.bilibili.com/x/polymer/web-dynamic/v1/opus/feed/space',
      ).replace(queryParameters: signed);
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
      final list = biliAsList<dynamic>(data['items']);
      final items =
          list.map((e) => BiliOpusItem.fromJson(biliAsMap(e) ?? {})).toList();
      final hasMore = data['has_more'] == true;
      final next = biliAsStr(data['offset']);
      return (
        items: items,
        hasMore: hasMore,
        nextOffset: next.isEmpty ? null : next,
      );
    } catch (e) {
      lastErrorDetail = e.toString();
      rethrow;
    }
  }
}

class BiliOpusItem {
  final String content;
  final String opusId;
  final int like;
  final String cover;

  const BiliOpusItem({
    required this.content,
    required this.opusId,
    required this.like,
    required this.cover,
  });

  factory BiliOpusItem.fromJson(Map<String, dynamic> json) {
    final stat = biliAsMap(json['stat']) ?? {};
    final coverMap = biliAsMap(json['cover']) ?? {};
    return BiliOpusItem(
      content: biliAsStr(json['content']),
      opusId: biliAsStr(json['opus_id']),
      like: biliToInt(stat['like']),
      cover: biliNormalizeUrl(biliAsStr(coverMap['url'])),
    );
  }

  String get webUrl => 'https://www.bilibili.com/opus/$opusId';
}
