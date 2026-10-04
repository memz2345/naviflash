                                           
  
                                                      
                                  
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/paged_result.dart';

class BilibiliComicService {
  static String? lastErrorDetail;

  static Future<PagedResult<BiliComicItem>> fetch({
    required int mid,
    int pn = 1,
    int ps = 20,
  }) async {
    try {
      final params = <String, String>{
        'build': '8430300',
        'version': '8.43.0',
        'c_locale': 'zh_CN',
        'channel': 'master',
        'mobi_app': 'android',
        'platform': 'android',
        's_locale': 'zh_CN',
        'ps': ps.toString(),
        'pn': pn.toString(),
        'qn': '32',
        'vmid': mid.toString(),
      };
      final uri = Uri.parse('https://app.bilibili.com/x/v2/space/comic')
          .replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: NetworkSettingsService.instance.apiHeaders)
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map || (json['code'] != 0 && json['code'] != 200)) {
        throw Exception('code=${json['code']} ${json['message']}');
      }
      final data = biliAsMap(json['data']) ?? {};
      final list = biliAsList<dynamic>(data['item']);
      final items =
          list.map((e) => BiliComicItem.fromJson(biliAsMap(e) ?? {})).toList();
      final hasMore = data['has_next'] == true || data['has_next'] == 1;
      return PagedResult(items, hasMore);
    } catch (e) {
      lastErrorDetail = e.toString();
      rethrow;
    }
  }
}

class BiliComicItem {
  final String title;
  final String cover;
  final List<String> styles;
  final String label;
  final String param;

  const BiliComicItem({
    required this.title,
    required this.cover,
    required this.styles,
    required this.label,
    required this.param,
  });

  factory BiliComicItem.fromJson(Map<String, dynamic> json) => BiliComicItem(
        title: biliAsStr(json['title']),
        cover: biliNormalizeUrl(biliAsStr(json['cover'])),
        styles: biliAsList<String>(json['styles']),
        label: biliAsStr(json['label']),
        param: biliAsStr(json['param']),
      );

  String get webUrl => 'https://manga.bilibili.com/detail/mc$param';
}
