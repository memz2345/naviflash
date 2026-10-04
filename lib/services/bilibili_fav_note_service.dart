                                              
  
                                                          
                                                         
                               
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/paged_result.dart';

class BilibiliFavNoteService {
  static String? lastErrorDetail;

  static Future<PagedResult<BiliFavNoteItem>> fetchList({
    required bool isPublish,
    int pn = 1,
    int ps = 10,
  }) async {
    try {
      final cookie = biliLoginCookie(BiliCookieScope.interactions);
      if (cookie == null) throw Exception('未登录');
      final csrf = biliExtractCsrf(cookie);
      final url = isPublish
          ? 'https://api.bilibili.com/x/note/publish/list/user'
          : 'https://api.bilibili.com/x/note/list';
      final params = <String, String>{
        'pn': pn.toString(),
        'ps': ps.toString(),
        'csrf': csrf,
      };
      final uri = Uri.parse(url).replace(queryParameters: params);
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
      final list = biliAsList<dynamic>(data['list']);
      final items = list
          .map((e) => BiliFavNoteItem.fromJson(biliAsMap(e) ?? {}))
          .toList();
      final hasMore = items.length >= ps;
      return PagedResult(items, hasMore);
    } catch (e) {
      lastErrorDetail = e.toString();
      rethrow;
    }
  }

                                             
  static Future<bool> deleteNotes({
    required bool isPublish,
    required List<String> ids,
  }) async {
    try {
      final cookie = biliLoginCookie(BiliCookieScope.interactions);
      if (cookie == null) return false;
      final csrf = biliExtractCsrf(cookie);
      final url = isPublish
          ? 'https://api.bilibili.com/x/note/publish/del'
          : 'https://api.bilibili.com/x/note/del';
      final body = isPublish
          ? {'cvids': ids.join(','), 'csrf': csrf}
          : {'note_ids': ids.join(','), 'csrf': csrf};
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(url),
            headers: {
              ...NetworkSettingsService.instance.apiHeaders,
              'Cookie': cookie,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: body,
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

class BiliFavNoteItem {
  final String webUrl;
  final String title;
  final String summary;
  final String message;
  final String pic;
  final String cvid;
  final String noteId;

  const BiliFavNoteItem({
    required this.webUrl,
    required this.title,
    required this.summary,
    required this.message,
    required this.pic,
    required this.cvid,
    required this.noteId,
  });

  factory BiliFavNoteItem.fromJson(Map<String, dynamic> json) {
    final arc = biliAsMap(json['arc']) ?? {};
    return BiliFavNoteItem(
      webUrl: biliAsStr(json['web_url']),
      title: biliAsStr(json['title']),
      summary: biliAsStr(json['summary']),
      message: biliAsStr(json['message']),
      pic: biliNormalizeUrl(biliAsStr(arc['pic'])),
      cvid: biliAsStr(json['cvid']),
      noteId: biliAsStr(json['note_id']),
    );
  }
}
