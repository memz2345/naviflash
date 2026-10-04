                                              
  
                                                          
                                                                    
                                                       
                                                                   
                                                                      
  
                                                    
                      
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'bilibili_account_service.dart';
import 'bilibili_user_space_service.dart';
import 'ugc_filter_service.dart';
import 'network_settings_service.dart';

                                           
      
                                           

                                       
enum BiliDynTab {
  all('all', '全部'),
  video('video', '投稿'),
  pgc('pgc', '番剧'),
  article('article', '专栏');

                 
  final String type;

                          
  final String label;

  const BiliDynTab(this.type, this.label);
}

         
class BiliDynFeedPage {
  final List<BiliDynamicDetail> items;
  final String? offset;
  final bool hasMore;
  final String? err;

  const BiliDynFeedPage({
    required this.items,
    this.offset,
    this.hasMore = false,
    this.err,
  });

  bool get hasError => err != null && err!.isNotEmpty;
}

                                           
      
                                           

abstract final class BilibiliDynamicsService {
  static const String _apiBase = 'https://api.bilibili.com';
  static const String _feedApi = '$_apiBase/x/polymer/web-dynamic/v1/feed/all';
  static const String _thumbApi = '$_apiBase/x/dynamic/thumbs';
  static const String _detailApi = '$_apiBase/x/polymer/web-dynamic/v1/detail';

                                      
  static const String _features = 'itemOpusStyle,listOnlyfans,onlyfansQaCard';

                                 
  static const BiliCookieScope _scope = BiliCookieScope.interactions;

  static const String _createApi = '$_apiBase/x/dynamic/feed/create/dyn';
  static const String _uploadApi = '$_apiBase/x/dynamic/feed/draw/upload_bfs';
  static const String _removeApi = '$_apiBase/x/dynamic/feed/operate/remove';
  static const String _setTopApi = '$_apiBase/x/dynamic/feed/space/set_top';
  static const String _rmTopApi = '$_apiBase/x/dynamic/feed/space/rm_top';

                           
                                           
  static const String _simpleActionApi =
      '$_apiBase/x/community/cosmo/interface/simple_action';

  static bool get canUse =>
      BilibiliAccountService.instance.cookieHeaderFor(_scope) != null;

  static Map<String, String> _headers() {
    final cookie = BilibiliAccountService.instance.cookieHeaderFor(
      _scope,
    )?['Cookie'];
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': 'https://t.bilibili.com',
      'Origin': 'https://t.bilibili.com',
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  static String _csrf() {
    final raw = BilibiliAccountService.instance.rawCookie;
    return RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(raw)?.group(1) ??
        '';
  }

                                         
  static Future<BiliDynFeedPage> fetchFeed({
    BiliDynTab tab = BiliDynTab.all,
    String? offset,
  }) async {
    if (!canUse) {
      return const BiliDynFeedPage(items: [], err: '还没有登录，登录后才能看关注动态');
    }
    try {
      final uri = Uri.parse(_feedApi).replace(
        queryParameters: {
          'type': tab.type,
          'features': _features,
          'timezone_offset': '-480',
          if (offset != null && offset.isNotEmpty) 'offset': offset,
        },
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return BiliDynFeedPage(items: const [], err: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return const BiliDynFeedPage(items: [], err: '返回内容不是 JSON');
      }
      final code = json['code'];
      if (code != 0) {
        final msg = '${json['message'] ?? ''}';
        return BiliDynFeedPage(
          items: const [],
          err: msg.isEmpty ? '接口返回 $code' : msg,
        );
      }
      final data = json['data'];
      if (data is! Map<String, dynamic>) {
        return const BiliDynFeedPage(items: [], err: '返回内容为空');
      }
      final rawItems = data['items'];
      final items = <BiliDynamicDetail>[];
      if (rawItems is List) {
        for (final e in rawItems.whereType<Map<String, dynamic>>()) {
          try {
            final detail = BiliDynamicDetail.fromJson(e);
                            
            if (detail.idStr.isEmpty) continue;
            if (detail.type == 'DYNAMIC_TYPE_LIVE_RCMD') continue;
                                                            
            if (UgcFilterService.instance.shouldFilter(
              UgcFilterScope.dyn,
              '${detail.text} ${detail.archiveTitle ?? ''}',
            )) {
              continue;
            }
            items.add(detail);
          } catch (err) {
            debugPrint('[Dynamics] 条目解析失败: $err');
          }
        }
      }
      final newOffset = '${data['offset'] ?? ''}';
      return BiliDynFeedPage(
        items: items,
        offset: newOffset.isEmpty ? null : newOffset,
        hasMore: data['has_more'] == true,
      );
    } catch (e) {
      debugPrint('[Dynamics] 拉取动态流失败: $e');
      return BiliDynFeedPage(items: const [], err: '网络异常：${e.runtimeType}');
    }
  }

                                
  static Future<Map<String, dynamic>?> fetchDetailRaw(String id) async {
    try {
      final uri = Uri.parse(_detailApi).replace(queryParameters: {'id': id});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> || json['code'] != 0) return null;
      final data = json['data'];
      if (data is! Map<String, dynamic>) return null;
      final item = data['item'];
      return item is Map<String, dynamic> ? item : null;
    } catch (e) {
      debugPrint('[Dynamics] 拉取动态详情失败: $e');
      return null;
    }
  }

                                           
  static Future<({bool ok, String message})> likeDynamic({
    required String idStr,
    required bool like,
  }) async {
    if (!canUse) return (ok: false, message: '还没有登录，登录后才能点赞');
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    try {
      final uri = Uri.parse(_thumbApi).replace(queryParameters: {'csrf': csrf});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            uri,
            headers: {
              ..._headers(),
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'dyn_id_str': idStr,
              'up': like ? '1' : '2',
              'spmid': '333.1365.0.0',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return (ok: false, message: '返回内容不是 JSON');
      }
      if (json['code'] != 0) {
        final msg = '${json['message'] ?? ''}';
        return (ok: false, message: msg.isEmpty ? '接口返回 ${json['code']}' : msg);
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[Dynamics] 点赞失败: $e');
      return (ok: false, message: '网络异常：${e.runtimeType}');
    }
  }

                                                      

                                                      
                                   
  static Future<({int width, int height, double size, String url})?>
      uploadImage(String path) async {
    if (!canUse) return null;
    final csrf = _csrf();
    if (csrf.isEmpty) return null;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final req = http.MultipartRequest('POST', Uri.parse(_uploadApi));
      req.headers.addAll(_headers());
      req.fields['category'] = 'daily';
      req.fields['biz'] = 'new_dyn';
      req.fields['csrf'] = csrf;
      req.files.add(await http.MultipartFile.fromPath('file_up', path));
      final streamed = await client
          .send(req)
          .timeout(const Duration(seconds: 60));
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> || json['code'] != 0) {
        debugPrint('[Dynamics] 图片上传失败: ${json['message']}');
        return null;
      }
      final data = json['data'];
      if (data is! Map<String, dynamic>) return null;
      final url = '${data['image_url'] ?? ''}';
      if (url.isEmpty) return null;
      return (
        width: (data['image_width'] as num?)?.toInt() ?? 0,
        height: (data['image_height'] as num?)?.toInt() ?? 0,
        size: (data['img_size'] as num?)?.toDouble() ?? 0,
        url: url,
      );
    } catch (e) {
      debugPrint('[Dynamics] 图片上传异常: $e');
      return null;
    }
  }

                                                
                           
     
                                                                
                                      
                 
  static List<Map<String, dynamic>> _buildContents(
    String text,
    List<({int mid, String name})> mentions,
  ) {
    final candidates = mentions.where((m) => m.name.isNotEmpty).toList();
    if (candidates.isEmpty) {
      return [
        {'raw_text': text, 'type': 1, 'biz_id': ''},
      ];
    }

    final nodes = <Map<String, dynamic>>[];
    final buffer = StringBuffer();
    var index = 0;

    void flushText() {
      if (buffer.isEmpty) return;
      nodes.add({'raw_text': buffer.toString(), 'type': 1, 'biz_id': ''});
      buffer.clear();
    }

    while (index < text.length) {
      var matched = false;
      if (text[index] == '@') {
        for (final mention in candidates) {
          final token = '@${mention.name}';
          if (text.startsWith(token, index)) {
            flushText();
            nodes.add({
              'raw_text': token,
              'type': 2,
              'biz_id': '${mention.mid}',
            });
            index += token.length;
            matched = true;
            break;
          }
        }
      }
      if (!matched) {
        buffer.write(text[index]);
        index++;
      }
    }
    flushText();

    if (nodes.isEmpty) {
      nodes.add({'raw_text': text, 'type': 1, 'biz_id': ''});
    }
    return nodes;
  }

  static Future<({bool ok, String message, String? dynId})> publishDynamic({
    required String text,
    List<({int width, int height, double size, String url})> images = const [],
    String? repostDynId,
                                             
    List<({int mid, String name})> mentions = const [],
                                                       
    ({int id, String name})? topic,
  }) async {
    if (!canUse) return (ok: false, message: '还没有登录，登录后才能发布动态', dynId: null);
    final csrf = _csrf();
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录', dynId: null);
    }
    final mid = BilibiliAccountService.instance.mid;
    try {
      final uri = Uri.parse(_createApi).replace(
        queryParameters: {
          'platform': 'web',
          'csrf': csrf,
          'x-bili-device-req-json': '{"platform": "web", "device": "pc"}',
          'x-bili-web-req-json': '{"spm_id": "333.999"}',
        },
      );
      final dynReq = <String, dynamic>{
        'content': {
          'contents': _buildContents(text, mentions),
        },
        'scene': repostDynId != null ? 4 : (images.isEmpty ? 1 : 2),
        'upload_id':
            '${repostDynId != null ? 0 : mid}_'
            '${DateTime.now().millisecondsSinceEpoch ~/ 1000}_'
            '${math.Random().nextInt(9000) + 1000}',
        'meta': {
          'app_meta': {'from': 'create.dynamic.web', 'mobi_app': 'web'},
        },
        if (topic != null && topic.id > 0 && topic.name.isNotEmpty)
          'topic': {
            'id': topic.id,
            'name': topic.name,
            'from_source': 'dyn.web.list',
            'from_topic_id': 0,
          },
        if (images.isNotEmpty)
          'pics': [
            for (final i in images)
              {
                'img_width': i.width,
                'img_height': i.height,
                'img_size': i.size,
                'img_src': i.url,
              },
          ],
      };
      final resp = await (await NetworkSettingsService.instance.getApiClient())
          .post(
            uri,
            headers: {
              ..._headers(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'dyn_req': dynReq,
              if (repostDynId != null)
                'web_repost_src': {'dyn_id_str': repostDynId},
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}', dynId: null);
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return (ok: false, message: '返回内容不是 JSON', dynId: null);
      }
      if (json['code'] != 0) {
        final msg = '${json['message'] ?? ''}';
        return (
          ok: false,
          message: msg.isEmpty ? '接口返回 ${json['code']}' : msg,
          dynId: null,
        );
      }
      final data = json['data'];
      final dynId = data is Map ? '${data['dyn_id'] ?? ''}' : '';
      return (ok: true, message: '', dynId: dynId.isEmpty ? null : dynId);
    } catch (e) {
      debugPrint('[Dynamics] 发布动态失败: $e');
      return (ok: false, message: '网络异常：${e.runtimeType}', dynId: null);
    }
  }

              
  static Future<({bool ok, String message})> removeDynamic(
    String idStr,
  ) async {
    if (!canUse) return (ok: false, message: '还没有登录');
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    return _postJson(
      Uri.parse(_removeApi).replace(
        queryParameters: {'platform': 'web', 'csrf': csrf},
      ),
      {'dyn_id_str': idStr},
    );
  }

                                      
  static Future<({bool ok, String message})> setTopDynamic({
    required String idStr,
    required bool top,
  }) async {
    if (!canUse) return (ok: false, message: '还没有登录');
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    return _postJson(
      Uri.parse(top ? _setTopApi : _rmTopApi)
          .replace(queryParameters: {'csrf': csrf}),
      {'dyn_str': idStr},
    );
  }

                                                                        

                                                        
                    
  static const String _topicTopApi =
      'https://app.bilibili.com/x/topic/web/details/top';
  static const String _topicFeedApi =
      '$_apiBase/x/polymer/web-dynamic/v1/feed/topic';
  static const String _topicFavApi = '$_apiBase/x/topic/fav/sub/add';
  static const String _topicUnfavApi = '$_apiBase/x/topic/fav/sub/cancel';

                                                   
  static const String _topicPubSearchApi =
      'https://app.bilibili.com/x/topic/pub/search';

                                       
     
                                    
  static Future<List<BiliTopicSearchItem>> searchTopic(
    String keyword, {
    int page = 1,
  }) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return const [];
    try {
      final uri = Uri.parse(_topicPubSearchApi).replace(queryParameters: {
        'keywords': kw,
        'content': '',
        if (page <= 1) ...{'page_size': 20, 'page_num': 1}
        else ...{'offset': 20 * (page - 1), 'page_size': 20},
        'web_location': '333.1365',
      });
      final resp = await (await NetworkSettingsService.instance.getApiClient())
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return const [];
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) return const [];
      if (json['code'] != 0) {
        debugPrint('[Dynamics] 话题搜索失败: ${json['message']}');
        return const [];
      }
      final data = json['data'];
      if (data is! Map<String, dynamic>) return const [];
      final list = data['topic_items'];
      if (list is! List) return const [];
      return [
        for (final e in list)
          if (e is Map<String, dynamic>) BiliTopicSearchItem.fromJson(e),
      ];
    } catch (e) {
      debugPrint('[Dynamics] 话题搜索异常: $e');
      return const [];
    }
  }

                                     
     
                                                  
                
  static Future<({BiliTopicDetails? details, String? err})>
      fetchTopicDetails(int topicId) async {
    if (topicId <= 0) return (details: null, err: '话题 id 无效');
    try {
      final uri = Uri.parse(
        _topicTopApi,
      ).replace(queryParameters: {'topic_id': '$topicId', 'source': 'Web'});
      final resp = await (await NetworkSettingsService.instance.getApiClient())
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (details: null, err: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) return (details: null, err: '返回内容不是 JSON');
      if (json['code'] != 0) {
        final msg = '${json['message'] ?? ''}';
        return (details: null, err: msg.isEmpty ? '接口返回 ${json['code']}' : msg);
      }
      final data = json['data'];
      if (data is! Map<String, dynamic>) return (details: null, err: '返回内容为空');
      final top = data['top_details'];
      if (top is! Map<String, dynamic>) return (details: null, err: '话题不存在');
      return (details: BiliTopicDetails.fromJson(top), err: null);
    } catch (e) {
      debugPrint('[Dynamics] 拉取话题详情失败: $e');
      return (details: null, err: '网络异常：${e.runtimeType}');
    }
  }

                                                   
     
                                              
                                          
                                                      
  static Future<BiliTopicFeedPage> fetchTopicFeed({
    required int topicId,
    int sortBy = 0,
    String? offset,
  }) async {
    if (topicId <= 0) {
      return const BiliTopicFeedPage(items: [], err: '话题 id 无效');
    }
    try {
      final uri = Uri.parse(_topicFeedApi).replace(
        queryParameters: {
          'topic_id': '$topicId',
          'sort_by': '$sortBy',
          if (offset != null && offset.isNotEmpty) 'offset': offset,
          'page_size': '20',
          'source': 'Web',
          'features': _features,
        },
      );
      final resp = await (await NetworkSettingsService.instance.getApiClient())
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return BiliTopicFeedPage(items: const [], err: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return const BiliTopicFeedPage(items: [], err: '返回内容不是 JSON');
      }
      if (json['code'] != 0) {
        final msg = '${json['message'] ?? ''}';
        return BiliTopicFeedPage(
          items: const [],
          err: msg.isEmpty ? '接口返回 ${json['code']}' : msg,
        );
      }
      final data = json['data'];
      if (data is! Map<String, dynamic>) {
        return const BiliTopicFeedPage(items: [], err: '返回内容为空');
      }
      final list = data['topic_card_list'];
      final rawItems = list is Map<String, dynamic> ? list['items'] : null;
      final items = <BiliDynamicDetail>[];
      if (rawItems is List) {
        for (final e in rawItems.whereType<Map<String, dynamic>>()) {
          final card = e['dynamic_card_item'];
          if (card is! Map<String, dynamic>) continue;
          try {
            final detail = BiliDynamicDetail.fromJson(card);
            if (detail.idStr.isEmpty) continue;
                                 
            if (UgcFilterService.instance.shouldFilter(
              UgcFilterScope.dyn,
              '${detail.text} ${detail.archiveTitle ?? ''}',
            )) {
              continue;
            }
            items.add(detail);
          } catch (err) {
            debugPrint('[Dynamics] 话题条目解析失败: $err');
          }
        }
      }
      final newOffset = list is Map<String, dynamic>
          ? '${list['offset'] ?? ''}'
          : '';
      final hasMore = list is Map<String, dynamic>
          ? list['has_more'] == true
          : false;
      final conf = list is Map<String, dynamic>
          ? list['topic_sort_by_conf']
          : null;
      final showSortBy = conf is Map<String, dynamic>
          ? (conf['show_sort_by'] as num?)?.toInt()
          : null;
      return BiliTopicFeedPage(
        items: items,
        offset: newOffset.isEmpty ? null : newOffset,
        hasMore: hasMore,
        sortBy: showSortBy ?? sortBy,
      );
    } catch (e) {
      debugPrint('[Dynamics] 拉取话题动态失败: $e');
      return BiliTopicFeedPage(items: const [], err: '网络异常：${e.runtimeType}');
    }
  }

                                              
  static Future<({bool ok, String message})> setTopicFav({
    required int topicId,
    required bool fav,
  }) async {
    if (!canUse) return (ok: false, message: '还没有登录');
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    return _postJson(
      Uri.parse(
        fav ? _topicFavApi : _topicUnfavApi,
      ).replace(queryParameters: {'csrf': csrf}),
      {'topic_id': topicId},
    );
  }

                             
  static Future<({bool ok, String message})> _postJson(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await (await NetworkSettingsService.instance.getApiClient())
          .post(
            uri,
            headers: {
              ..._headers(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return (ok: false, message: '返回内容不是 JSON');
      }
      if (json['code'] != 0) {
        final msg = '${json['message'] ?? ''}';
        return (ok: false, message: msg.isEmpty ? '接口返回 ${json['code']}' : msg);
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[Dynamics] 写操作失败: $e');
      return (ok: false, message: '网络异常：${e.runtimeType}');
    }
  }

                          
                                        
                                                                            
                                     
  static Future<({bool ok, String message})> favOpus({
    required String opusId,
    required bool fav,
  }) async {
    final csrf = _csrf();
    if (csrf.isEmpty) {
      return (ok: false, message: '还没有登录，登录后才能收藏');
    }
    final uri = Uri.parse(_simpleActionApi).replace(
      queryParameters: {'csrf': csrf},
    );
    return _postJson(uri, <String, dynamic>{
      'entity': <String, dynamic>{
        'object_id_str': opusId,
        'type': <String, dynamic>{'biz': 2},
      },
      'action': fav ? 3 : 4,
    });
  }
}

                                           
                                            
                                           

                                 
                                                      
class BiliTopicSearchItem {
  final int id;
  final String name;

                          
  final int view;
  final int discuss;

                                    
  final String statDesc;
  final String description;

  const BiliTopicSearchItem({
    required this.id,
    required this.name,
    this.view = 0,
    this.discuss = 0,
    this.statDesc = '',
    this.description = '',
  });

  factory BiliTopicSearchItem.fromJson(Map<String, dynamic> json) {
    int intOf(String key) => (json[key] as num?)?.toInt() ?? 0;
    return BiliTopicSearchItem(
      id: intOf('id'),
      name: (json['name'] as String?) ?? '',
      view: intOf('view'),
      discuss: intOf('discuss'),
      statDesc: (json['stat_desc'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
    );
  }
}

class BiliTopicDetails {
  final int id;
  final String name;

                                      
  final int view;
  final int discuss;
  final int fav;
  final int like;
  final String description;
  final bool isFav;
  final bool isLike;

  const BiliTopicDetails({
    required this.id,
    required this.name,
    this.view = 0,
    this.discuss = 0,
    this.fav = 0,
    this.like = 0,
    this.description = '',
    this.isFav = false,
    this.isLike = false,
  });

  factory BiliTopicDetails.fromJson(Map<String, dynamic> json) {
    final item = json['topic_item'];
    final map = item is Map<String, dynamic> ? item : json;
    int intOf(String key) => (map[key] as num?)?.toInt() ?? 0;
    return BiliTopicDetails(
      id: intOf('id'),
      name: '${map['name'] ?? ''}',
      view: intOf('view'),
      discuss: intOf('discuss'),
      fav: intOf('fav'),
      like: intOf('like'),
      description: '${map['description'] ?? ''}',
      isFav: map['is_fav'] == true,
      isLike: map['is_like'] == true,
    );
  }
}

            
class BiliTopicFeedPage {
  final List<BiliDynamicDetail> items;

                    
  final String? offset;
  final bool hasMore;

                             
  final int sortBy;

                     
  final String? err;

  const BiliTopicFeedPage({
    required this.items,
    this.offset,
    this.hasMore = false,
    this.sortBy = 0,
    this.err,
  });
}
