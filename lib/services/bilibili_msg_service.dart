                                         
  
                                                                       
                                                   
                                                  
                                                  
                                                          
                                                                   
                                                     
                                                 
                                                    
                                                                                    
  
                                   
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'bilibili_account_service.dart';
import 'bilibili_user_space_service.dart' show WbiSign;
import 'network_settings_service.dart';

                                           
          
                                           

int _toInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}

int? _toIntOrNull(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

String _toStr(dynamic v) => v?.toString() ?? '';

Map<String, dynamic>? _asMap(dynamic v) => v is Map<String, dynamic> ? v : null;

String _fixUrl(String url) {
  final t = url.trim();
  if (t.isEmpty) return '';
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  if (t.startsWith('//')) return 'https:$t';
  return 'https://$t';
}

List<Map<String, dynamic>> _asMapList(dynamic v) => v is List
    ? v.whereType<Map<String, dynamic>>().toList(growable: false)
    : const [];

                                           
      
                                           

                            
class BiliMsgUser {
  final int mid;
  final String nickname;
  final String avatar;

  const BiliMsgUser({
    required this.mid,
    required this.nickname,
    required this.avatar,
  });

  static BiliMsgUser fromJson(Map<String, dynamic> json) => BiliMsgUser(
    mid: _toInt(json['mid']),
    nickname: _toStr(json['nickname']),
    avatar: _fixUrl(_toStr(json['avatar'])),
  );

  static const BiliMsgUser empty = BiliMsgUser(
    mid: 0,
    nickname: '',
    avatar: '',
  );
}

                                                               
class BiliMsgContent {
  final String business;
  final int businessId;
  final int subjectId;
  final String nativeUri;
  final String image;

                   
  final String sourceContent;

               
  final String targetReplyContent;

              
  final String rootReplyContent;

  const BiliMsgContent({
    this.business = '',
    this.businessId = 0,
    this.subjectId = 0,
    this.nativeUri = '',
    this.image = '',
    this.sourceContent = '',
    this.targetReplyContent = '',
    this.rootReplyContent = '',
  });

  static BiliMsgContent fromJson(Map<String, dynamic> json) => BiliMsgContent(
    business: _toStr(json['business']),
    businessId: _toInt(json['business_id']),
    subjectId: _toInt(json['subject_id']),
    nativeUri: _toStr(json['native_uri']),
    image: _fixUrl(_toStr(json['image'])),
    sourceContent: _toStr(json['source_content']),
    targetReplyContent: _toStr(json['target_reply_content']),
    rootReplyContent: _toStr(json['root_reply_content']),
  );
}

         
class BiliMsgReplyItem {
  final int id;
  final BiliMsgUser user;
  final BiliMsgContent content;
  final int counts;

                       
  final int isMulti;
  final int replyTime;

  const BiliMsgReplyItem({
    required this.id,
    required this.user,
    required this.content,
    required this.counts,
    required this.isMulti,
    required this.replyTime,
  });

  static BiliMsgReplyItem fromJson(Map<String, dynamic> json) =>
      BiliMsgReplyItem(
        id: _toInt(json['id']),
        user: _asMap(json['user']) == null
            ? BiliMsgUser.empty
            : BiliMsgUser.fromJson(_asMap(json['user'])!),
        content: _asMap(json['item']) == null
            ? const BiliMsgContent()
            : BiliMsgContent.fromJson(_asMap(json['item'])!),
        counts: _toInt(json['counts']),
        isMulti: _toInt(json['is_multi']),
        replyTime: _toInt(json['reply_time']),
      );
}

        
class BiliMsgAtItem {
  final int id;
  final BiliMsgUser user;
  final BiliMsgContent content;
  final int atTime;

  const BiliMsgAtItem({
    required this.id,
    required this.user,
    required this.content,
    required this.atTime,
  });

  static BiliMsgAtItem fromJson(Map<String, dynamic> json) => BiliMsgAtItem(
    id: _toInt(json['id']),
    user: _asMap(json['user']) == null
        ? BiliMsgUser.empty
        : BiliMsgUser.fromJson(_asMap(json['user'])!),
    content: _asMap(json['item']) == null
        ? const BiliMsgContent()
        : BiliMsgContent.fromJson(_asMap(json['item'])!),
    atTime: _toInt(json['at_time']),
  );
}

               
class BiliMsgLikeItem {
  final int id;
  final List<BiliMsgUser> users;
  final String business;
  final String title;
  final String image;
  final String nativeUri;

             
  final int counts;
  final int likeTime;

                                
  int noticeState;

  BiliMsgLikeItem({
    required this.id,
    required this.users,
    required this.business,
    required this.title,
    required this.image,
    required this.nativeUri,
    required this.counts,
    required this.likeTime,
    required this.noticeState,
  });

  static BiliMsgLikeItem fromJson(Map<String, dynamic> json) {
    final item = _asMap(json['item']) ?? const <String, dynamic>{};
    return BiliMsgLikeItem(
      id: _toInt(json['id']),
      users: _asMapList(
        json['users'],
      ).map(BiliMsgUser.fromJson).toList(growable: false),
      business: _toStr(item['business']),
      title: _toStr(item['title']),
      image: _fixUrl(_toStr(item['image'])),
      nativeUri: _toStr(item['native_uri']),
      counts: _toInt(json['counts']),
      likeTime: _toInt(json['like_time']),
      noticeState: _toInt(json['notice_state']),
    );
  }
}

                       
class BiliMsgLikeDetailItem {
  final BiliMsgUser user;
  final int likeTime;

  const BiliMsgLikeDetailItem({required this.user, required this.likeTime});

  static BiliMsgLikeDetailItem fromJson(Map<String, dynamic> json) =>
      BiliMsgLikeDetailItem(
        user: _asMap(json['user']) == null
            ? BiliMsgUser.empty
            : BiliMsgUser.fromJson(_asMap(json['user'])!),
        likeTime: _toInt(json['like_time']),
      );
}

         
class BiliMsgSysItem {
  final int id;
  final int cursor;
  final String title;
  final String content;
  final String timeAt;

  const BiliMsgSysItem({
    required this.id,
    required this.cursor,
    required this.title,
    required this.content,
    required this.timeAt,
  });

  static BiliMsgSysItem fromJson(Map<String, dynamic> json) {
    var content = _toStr(json['content']);
    if (content.isNotEmpty) {
      try {
        final decoded = jsonDecode(content);
        final web = _asMap(decoded)?['web'];
        if (web != null) content = _toStr(web);
      } catch (_) {}
    }
    return BiliMsgSysItem(
      id: _toInt(json['id']),
      cursor: _toInt(json['cursor']),
      title: _toStr(json['title']),
      content: content,
      timeAt: _toStr(json['time_at']),
    );
  }
}

                               
class BiliMsgFeedUnread {
  final int reply;
  final int at;
  final int like;
  final int sysMsg;

  const BiliMsgFeedUnread({
    this.reply = 0,
    this.at = 0,
    this.like = 0,
    this.sysMsg = 0,
  });

  static const BiliMsgFeedUnread zero = BiliMsgFeedUnread();

  int get total => reply + at + like + sysMsg;

  static BiliMsgFeedUnread fromJson(Map<String, dynamic> json) =>
      BiliMsgFeedUnread(
        reply: _toInt(json['reply']),
        at: _toInt(json['at']),
        like: _toInt(json['like']),
        sysMsg: _toInt(json['sys_msg']),
      );
}

                         
class BiliMsgPage<T> {
  final List<T> items;
  final int? cursor;
  final int? cursorTime;
  final bool isEnd;
  final String? err;

  const BiliMsgPage({
    required this.items,
    this.cursor,
    this.cursorTime,
    this.isEnd = false,
    this.err,
  });

  bool get hasError => err != null && err!.isNotEmpty;
}

                        
class BiliMsgLikePage {
  final List<BiliMsgLikeItem> latest;
  final List<BiliMsgLikeItem> total;
  final int? cursor;
  final int? cursorTime;
  final bool isEnd;
  final String? err;

  const BiliMsgLikePage({
    required this.latest,
    required this.total,
    this.cursor,
    this.cursorTime,
    this.isEnd = false,
    this.err,
  });

  bool get hasError => err != null && err!.isNotEmpty;
  bool get isEmpty => latest.isEmpty && total.isEmpty;
}

                                           
      
                                           

abstract final class BilibiliMsgService {
  static const String _apiBase = 'https://api.bilibili.com';
  static const String _vcBase = 'https://api.vc.bilibili.com';
  static const String _messageBase = 'https://message.bilibili.com';

                                       
  static const BiliCookieScope _scope = BiliCookieScope.interactions;

  static Map<String, String> _headers() {
    final cookie = BilibiliAccountService.instance.cookieHeaderFor(
      _scope,
    )?['Cookie'];
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': 'https://message.bilibili.com',
      'Origin': 'https://message.bilibili.com',
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  static String _csrf() {
    final raw = BilibiliAccountService.instance.rawCookie;
    return RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(raw)?.group(1) ??
        '';
  }

                                  
  static bool get canUse =>
      BilibiliAccountService.instance.cookieHeaderFor(_scope) != null;

  static const Map<String, String> _commonQuery = {
    'platform': 'web',
    'mobi_app': 'web',
    'build': '0',
    'web_location': '333.40164',
  };

               

  static Future<BiliMsgPage<BiliMsgReplyItem>> fetchReplyMe({
    int? cursor,
    int? cursorTime,
  }) async {
    final json = await _getJson('$_apiBase/x/msgfeed/reply', {
      ..._commonQuery,
      if (cursor != null) 'id': '$cursor',
      if (cursorTime != null) 'reply_time': '$cursorTime',
    });
    if (json.err != null) {
      return BiliMsgPage(items: const [], err: json.err);
    }
    final data = _asMap(json.data) ?? const <String, dynamic>{};
    final page = _asMap(data['cursor']);
    return BiliMsgPage(
      items: _asMapList(
        data['items'],
      ).map(BiliMsgReplyItem.fromJson).toList(growable: false),
      cursor: _toIntOrNull(page?['id']),
      cursorTime: _toIntOrNull(page?['time']),
      isEnd: page?['is_end'] == true,
    );
  }

              

  static Future<BiliMsgPage<BiliMsgAtItem>> fetchAtMe({
    int? cursor,
    int? cursorTime,
  }) async {
    final json = await _getJson('$_apiBase/x/msgfeed/at', {
      ..._commonQuery,
      if (cursor != null) 'id': '$cursor',
      if (cursorTime != null) 'at_time': '$cursorTime',
    });
    if (json.err != null) {
      return BiliMsgPage(items: const [], err: json.err);
    }
    final data = _asMap(json.data) ?? const <String, dynamic>{};
    final page = _asMap(data['cursor']);
    return BiliMsgPage(
      items: _asMapList(
        data['items'],
      ).map(BiliMsgAtItem.fromJson).toList(growable: false),
      cursor: _toIntOrNull(page?['id']),
      cursorTime: _toIntOrNull(page?['time']),
      isEnd: page?['is_end'] == true,
    );
  }

               

  static Future<BiliMsgLikePage> fetchLikeMe({
    int? cursor,
    int? cursorTime,
  }) async {
    final json = await _getJson('$_apiBase/x/msgfeed/like', {
      ..._commonQuery,
      if (cursor != null) 'id': '$cursor',
      if (cursorTime != null) 'like_time': '$cursorTime',
    });
    if (json.err != null) {
      return BiliMsgLikePage(latest: const [], total: const [], err: json.err);
    }
    final data = _asMap(json.data) ?? const <String, dynamic>{};
    final latest = _asMap(data['latest']) ?? const <String, dynamic>{};
    final total = _asMap(data['total']) ?? const <String, dynamic>{};
    final page = _asMap(total['cursor']);
    return BiliMsgLikePage(
      latest: _asMapList(
        latest['items'],
      ).map(BiliMsgLikeItem.fromJson).toList(growable: false),
      total: _asMapList(
        total['items'],
      ).map(BiliMsgLikeItem.fromJson).toList(growable: false),
      cursor: _toIntOrNull(page?['id']),
      cursorTime: _toIntOrNull(page?['time']),
      isEnd: page?['is_end'] == true,
    );
  }

                                       
  static Future<BiliMsgPage<BiliMsgLikeDetailItem>> fetchLikeDetail({
    required Object cardId,
    int pn = 1,
    Object lastMid = 0,
  }) async {
    final json = await _getJson('$_apiBase/x/msgfeed/like_detail', {
      'card_id': '$cardId',
      'pn': '$pn',
      'last_mid': '$lastMid',
      'platform': 'web',
      'build': '0',
      'mobi_app': 'web',
      'web_location': '333.40164',
    });
    if (json.err != null) {
      return BiliMsgPage(items: const [], err: json.err);
    }
    final data = _asMap(json.data) ?? const <String, dynamic>{};
    final page = _asMap(data['page']);
    return BiliMsgPage(
      items: _asMapList(
        data['items'],
      ).map(BiliMsgLikeDetailItem.fromJson).toList(growable: false),
      cursor: pn,
      isEnd: page?['is_end'] == true,
    );
  }

               

  static Future<BiliMsgPage<BiliMsgSysItem>> fetchSysMsg({
    int? cursor,
    int pageSize = 20,
  }) async {
    final json = await _getJson('$_messageBase/x/sys-msg/query_notify_list', {
      if (cursor != null) 'cursor': '$cursor',
      'page_size': '$pageSize',
      'mobi_app': 'web',
      'build': '0',
      'web_location': '333.40164',
    });
    if (json.err != null) {
      return BiliMsgPage(items: const [], err: json.err);
    }
    final list = json.data is List
        ? json.data as List
        : (json.data is Map ? (json.data as Map)['items'] : null);
    final items = _asMapList(
      list,
    ).map(BiliMsgSysItem.fromJson).toList(growable: false);
    return BiliMsgPage(
      items: items,
      cursor: items.isEmpty ? null : items.last.cursor,
      isEnd: items.length < pageSize,
    );
  }

                                
  static Future<({bool ok, String message})> updateSysCursor(int cursor) async {
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    final json = await _getJson('$_messageBase/x/sys-msg/update_cursor', {
      'csrf': csrf,
      'cursor': '$cursor',
      'has_up': '0',
      'build': '0',
      'mobi_app': 'web',
    });
    if (json.err != null) return (ok: false, message: json.err!);
    return (ok: true, message: '');
  }

              

  static Future<({BiliMsgFeedUnread unread, String? err})>
  fetchMsgFeedUnread() async {
    final json = await _getJson('$_apiBase/x/msgfeed/unread', {
      'build': '0',
      'mobi_app': 'web',
      'web_location': '333.1365',
    });
    if (json.err != null) {
      return (unread: BiliMsgFeedUnread.zero, err: json.err);
    }
    final data = _asMap(json.data);
    if (data == null) {
      return (unread: BiliMsgFeedUnread.zero, err: '返回内容为空');
    }
    return (unread: BiliMsgFeedUnread.fromJson(data), err: null);
  }

                    

                                                     
  static Future<({bool ok, String message})> deleteMsgFeed({
    required int tp,
    required Object id,
  }) async {
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    return _post('$_apiBase/x/msgfeed/del', {
      'tp': '$tp',
      'id': '$id',
      'build': '0',
      'mobi_app': 'web',
      'csrf_token': csrf,
      'csrf': csrf,
    });
  }

                                 
  static Future<({bool ok, String message})> setNotice({
    required Object id,
    required int noticeState,
  }) async {
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    return _post('$_apiBase/x/msgfeed/notice', {
      'mobi_app': 'web',
      'platform': 'web',
      'tp': '0',
      'id': '$id',
      'notice_state': '$noticeState',
      'build': '0',
      'csrf_token': csrf,
      'csrf': csrf,
    });
  }

                            

  static Future<({bool ok, String message})> ackSession({
    required int talkerId,
    required int ackSeqno,
  }) async {
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    final params = await WbiSign.sign({
      'talker_id': '$talkerId',
      'session_type': '1',
      'ack_seqno': '$ackSeqno',
      'build': '0',
      'mobi_app': 'web',
      'csrf_token': csrf,
      'csrf': csrf,
    });
    final json = await _getJson(
      '$_vcBase/session_svr/v1/session_svr/update_ack',
      params,
    );
    if (json.err != null) return (ok: false, message: json.err!);
    return (ok: true, message: '');
  }

               

  static Future<({dynamic data, String? err})> _getJson(
    String url,
    Map<String, String> query,
  ) async {
    if (!canUse) {
      return (data: null, err: '还没有登录，登录后才能查看消息');
    }
    try {
      final uri = Uri.parse(url).replace(queryParameters: query);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      return _decode(resp.statusCode, resp.bodyBytes);
    } catch (e) {
      debugPrint('[Msg] GET $url 失败: $e');
      return (data: null, err: '网络异常：${e.runtimeType}');
    }
  }

  static Future<({bool ok, String message})> _post(
    String url,
    Map<String, String> fields,
  ) async {
    if (!canUse) return (ok: false, message: '还没有登录');
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(url),
            headers: {
              ..._headers(),
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: fields,
          )
          .timeout(const Duration(seconds: 15));
      final json = _decode(resp.statusCode, resp.bodyBytes);
      if (json.err != null) return (ok: false, message: json.err!);
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[Msg] POST $url 失败: $e');
      return (ok: false, message: '网络异常：${e.runtimeType}');
    }
  }

  static ({dynamic data, String? err}) _decode(int status, List<int> bytes) {
    if (status != 200) return (data: null, err: 'HTTP $status');
    dynamic json;
    try {
      json = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      return (data: null, err: '返回内容不是 JSON');
    }
    if (json is! Map<String, dynamic>) {
      return (data: null, err: '返回内容不是 JSON 对象');
    }
    final code = _toInt(json['code']);
    if (code != 0) {
      final msg = _toStr(json['message']).isNotEmpty
          ? _toStr(json['message'])
          : _toStr(json['msg']);
      return (data: null, err: msg.isEmpty ? '接口返回 $code' : msg);
    }
    return (data: json['data'], err: null);
  }
}
