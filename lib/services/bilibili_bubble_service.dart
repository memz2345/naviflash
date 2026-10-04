                                            
  
                                                        
                                              
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/network_settings_service.dart';

class BilibiliBubbleService {
  static String? lastErrorDetail;

  static Future<BiliBubblePageData?> fetch({
    required String tribeId,
    String? categoryId,
    String? sortType,
    int page = 1,
    int ps = 20,
  }) async {
    try {
      final params = <String, String>{
        'tribee_id': tribeId,
        if (categoryId != null) 'category_id': categoryId,
        if (sortType != null) 'sort_type': sortType,
        'page_size': ps.toString(),
        'page_num': page.toString(),
        'web_location': '333.40165',
      };
      final uri = Uri.parse('https://api.bilibili.com/x/tribee/v1/dyn/all')
          .replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final cookie = biliLoginCookie(BiliCookieScope.userSpace);
      final headers = {...NetworkSettingsService.instance.apiHeaders};
      if (cookie != null) headers['Cookie'] = cookie;
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map || (json['code'] != 0 && json['code'] != 200)) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        return null;
      }
      final data = biliAsMap(json['data']);
      if (data == null) return null;
      return BiliBubblePageData.fromJson(data);
    } catch (e) {
      lastErrorDetail = e.toString();
      return null;
    }
  }
}

class BiliBubblePageData {
  final String tribeName;
  final String tribeSubTitle;
  final String tribeFace;
  final String tribeSummary;
  final int count;
  final List<BiliBubbleDyn> dynList;
  final List<({String id, String name})> categories;
  final List<({String sortType, String text})> sortItems;
  final bool showSort;
  final String? curSortType;

  const BiliBubblePageData({
    required this.tribeName,
    required this.tribeSubTitle,
    required this.tribeFace,
    required this.tribeSummary,
    required this.count,
    required this.dynList,
    required this.categories,
    required this.sortItems,
    required this.showSort,
    required this.curSortType,
  });

  factory BiliBubblePageData.fromJson(Map<String, dynamic> json) {
    final baseInfo = biliAsMap(json['base_info']) ?? {};
    final tribeInfo = biliAsMap(baseInfo['tribee_info']) ?? {};
    final content = biliAsMap(json['content']) ?? {};
    final category = biliAsMap(json['category']) ?? {};
    final sortInfo = biliAsMap(json['sort_info']) ?? {};

    final dynListRaw = biliAsList<dynamic>(content['dyn_list']);
    final dynList =
        dynListRaw.map((e) => BiliBubbleDyn.fromJson(biliAsMap(e) ?? {})).toList();

    final catRaw = biliAsList<dynamic>(category['category_list']);
    final categories = catRaw.map((e) {
      final m = biliAsMap(e) ?? {};
      return (id: biliAsStr(m['id']), name: biliAsStr(m['name']));
    }).toList();

    final sortRaw = biliAsList<dynamic>(sortInfo['sort_items']);
    final sortItems = sortRaw.map((e) {
      final m = biliAsMap(e) ?? {};
      return (sortType: biliAsStr(m['sort_type']), text: biliAsStr(m['text']));
    }).toList();

    return BiliBubblePageData(
      tribeName: biliAsStr(tribeInfo['title']),
      tribeSubTitle: biliAsStr(tribeInfo['sub_title']),
      tribeFace: biliNormalizeUrl(biliAsStr(tribeInfo['face_url'])),
      tribeSummary: biliAsStr(tribeInfo['summary']),
      count: biliToInt(content['count']),
      dynList: dynList,
      categories: categories,
      sortItems: sortItems,
      showSort: sortInfo['show_sort'] == true,
      curSortType: biliAsStr(sortInfo['cur_sort_type']),
    );
  }
}

class BiliBubbleDyn {
  final String dynId;
  final String title;
  final String author;
  final String timeText;
  final int replyCount;
  final int viewStat;

  const BiliBubbleDyn({
    required this.dynId,
    required this.title,
    required this.author,
    required this.timeText,
    required this.replyCount,
    required this.viewStat,
  });

  factory BiliBubbleDyn.fromJson(Map<String, dynamic> json) {
    final meta = biliAsMap(json['meta']) ?? {};
    return BiliBubbleDyn(
      dynId: biliAsStr(json['dyn_id']),
      title: biliAsStr(json['title']),
      author: biliAsStr(meta['author']),
      timeText: biliAsStr(meta['time_text']),
      replyCount: biliToInt(meta['reply_count']),
      viewStat: biliToInt(meta['view_stat']),
    );
  }

  String get webUrl => 'https://www.bilibili.com/opus/$dynId';
}
