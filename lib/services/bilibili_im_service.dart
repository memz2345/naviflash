                                        
  
                                               
  
                                                                      
                                                       
                              
                                                                            
                                                          
                                                                            
                                                              
                                                                                  
                                                                          
                                                                       
                                                                              
                                                                             
  
                                               
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'bilibili_account_service.dart';
import 'bilibili_user_space_service.dart' show WbiSign;
import 'network_settings_service.dart';

                                           
          
                                           

int _toInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
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

                                           
      
                                           

                                 
abstract final class ImMsgType {
  static const int text = 1;
  static const int picture = 2;
  static const int customFace = 3;
  static const int voice = 4;
  static const int withdraw = 5;
  static const int share = 7;
  static const int notify = 10;
  static const int videoCard = 11;
  static const int articleCard = 12;
  static const int pictureCard = 13;
  static const int commonShareCard = 14;
  static const int specialCard = 16;
  static const int tipMessage = 18;

                     
  static const int system = tipMessage;

                                                 
  static bool isCard(int type) =>
      type == notify ||
      type == videoCard ||
      type == pictureCard ||
      type == specialCard ||
      type == tipMessage;
}

           
class BiliImMessage {
  final int senderUid;
  final int receiverId;
  final int receiverType;
  final int msgType;
  final String content;
  final int timestamp;
  final int msgSeqno;
  final int msgKey;
  final int msgStatus;
  final int msgSource;

  const BiliImMessage({
    required this.senderUid,
    required this.receiverId,
    required this.receiverType,
    required this.msgType,
    required this.content,
    required this.timestamp,
    required this.msgSeqno,
    required this.msgKey,
    required this.msgStatus,
    required this.msgSource,
  });

  static BiliImMessage fromJson(Map<String, dynamic> json) => BiliImMessage(
    senderUid: _toInt(json['sender_uid']),
    receiverId: _toInt(json['receiver_id']),
    receiverType: _toInt(json['receiver_type']),
    msgType: _toInt(json['msg_type']),
    content: _toStr(json['content']),
    timestamp: _toInt(json['timestamp']),
    msgSeqno: _toInt(json['msg_seqno']),
    msgKey: _toInt(json['msg_key']),
    msgStatus: _toInt(json['msg_status']),
    msgSource: _toInt(json['msg_source']),
  );
}

           
class BiliImSession {
  final int talkerId;
  final int sessionType;
  final String name;
  final String face;
  final BiliImMessage? lastMsg;
  final int unread;
  final int timestamp;
  final bool pinned;
  final bool isFollow;
  final int ackSeqno;
  final int maxSeqno;
  final int topTs;

  const BiliImSession({
    required this.talkerId,
    required this.sessionType,
    required this.name,
    required this.face,
    required this.lastMsg,
    required this.unread,
    required this.timestamp,
    required this.pinned,
    required this.isFollow,
    required this.ackSeqno,
    required this.maxSeqno,
    required this.topTs,
  });

  static BiliImSession fromJson(Map<String, dynamic> json) => BiliImSession(
    talkerId: _toInt(json['talker_id']),
    sessionType: _toInt(json['session_type']),
    name: '',
    face: '',
    lastMsg: _asMap(json['last_msg']) == null
        ? null
        : BiliImMessage.fromJson(_asMap(json['last_msg'])!),
    unread: _toInt(json['unread_count']),
    timestamp: _toInt(json['session_ts']),
    pinned: _toInt(json['top_ts']) > 0,
    isFollow: _toInt(json['is_follow']) == 1,
    ackSeqno: _toInt(json['ack_seqno']),
    maxSeqno: _toInt(json['max_seqno']),
    topTs: _toInt(json['top_ts']),
  );

                             
  BiliImSession withUser({String? name, String? face}) => BiliImSession(
    talkerId: talkerId,
    sessionType: sessionType,
    name: name ?? this.name,
    face: face ?? this.face,
    lastMsg: lastMsg,
    unread: unread,
    timestamp: timestamp,
    pinned: pinned,
    isFollow: isFollow,
    ackSeqno: ackSeqno,
    maxSeqno: maxSeqno,
    topTs: topTs,
  );

                                                  
                                               
  int get timestampSeconds =>
      timestamp > 100000000000000 ? timestamp ~/ 1000000 : timestamp;

                                    
  String get summary {
    final msg = lastMsg;
    if (msg == null) return '';
    final content = msg.content;
    switch (msg.msgType) {
      case ImMsgType.text:
      case ImMsgType.notify:
      case ImMsgType.system:
        return _jsonText(content);
      case ImMsgType.picture:
      case ImMsgType.customFace:
        return '[图片]';
      case ImMsgType.voice:
        return '[语音]';
      case ImMsgType.withdraw:
        return '[撤回了一条消息]';
      case ImMsgType.share:
      case ImMsgType.commonShareCard:
        return '[分享]';
      case ImMsgType.videoCard:
        return '[视频]';
      case ImMsgType.articleCard:
        return '[专栏]';
      case ImMsgType.pictureCard:
        return '[图片卡]';
      case ImMsgType.specialCard:
        return '[卡片消息]';
      default:
        final text = _jsonText(content);
        return text.isEmpty ? '[消息]' : text;
    }
  }

  static String _jsonText(String content) {
    if (content.isEmpty) return '';
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map) {
        final inner = decoded['content'];
        if (inner is String) return inner;
        if (inner is List) {
          return inner
              .whereType<Map>()
              .map((e) => _toStr(e['text']))
              .where((e) => e.isNotEmpty)
              .join();
        }
        final title = decoded['title'];
        if (title != null) return _toStr(title);
      }
      if (decoded is String) return decoded;
    } catch (_) {}
    return content;
  }
}

           
class BiliImSessionPage {
  final List<BiliImSession> sessions;
  final int? offset;
  final bool hasMore;
  final String? err;

  const BiliImSessionPage({
    required this.sessions,
    this.offset,
    this.hasMore = false,
    this.err,
  });

  bool get hasError => err != null && err!.isNotEmpty;
}

                                   
class BiliImMessagePage {
  final List<BiliImMessage> messages;
  final bool hasMore;
  final int? minSeqno;
  final String? err;

  const BiliImMessagePage({
    required this.messages,
    this.hasMore = false,
    this.minSeqno,
    this.err,
  });

  bool get hasError => err != null && err!.isNotEmpty;
}

          
class BiliImUnread {
  final int follow;
  final int unfollow;
  final int bizFollow;
  final int bizUnfollow;

  const BiliImUnread({
    this.follow = 0,
    this.unfollow = 0,
    this.bizFollow = 0,
    this.bizUnfollow = 0,
  });

  static const BiliImUnread zero = BiliImUnread();

  int get total => follow + unfollow + bizFollow + bizUnfollow;
}

                                                    
class BiliImSessionSettings {
                       
  final int followStatus;

                         
  final int pushSetting;

                             
  final int showPushSetting;

  const BiliImSessionSettings({
    this.followStatus = 0,
    this.pushSetting = 1,
    this.showPushSetting = 0,
  });

  bool get isBlocked => followStatus == 128;

  bool get pushEnabled => pushSetting == 0;

  bool get showPushSwitch => showPushSetting == 1;

  BiliImSessionSettings copyWith({
    int? followStatus,
    int? pushSetting,
    int? showPushSetting,
  }) => BiliImSessionSettings(
    followStatus: followStatus ?? this.followStatus,
    pushSetting: pushSetting ?? this.pushSetting,
    showPushSetting: showPushSetting ?? this.showPushSetting,
  );

  static BiliImSessionSettings fromJson(Map<String, dynamic> json) =>
      BiliImSessionSettings(
        followStatus: _toInt(json['follow_status']),
        pushSetting: _toInt(json['push_setting']),
        showPushSetting: _toInt(json['show_push_setting']),
      );
}

                                           
      
                                           

abstract final class BilibiliImService {
  static const String _apiBase = 'https://api.bilibili.com';
  static const String _vcBase = 'https://api.vc.bilibili.com';

                                       
  static const BiliCookieScope _scope = BiliCookieScope.interactions;

                             
  static bool get canUse =>
      BilibiliAccountService.instance.cookieHeaderFor(_scope) != null;

  static int get selfMid => BilibiliAccountService.instance.mid;

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

                                                             

                                             
  static Future<BiliImSessionPage> fetchSessions({int? offset}) async {
    if (!canUse) {
      return const BiliImSessionPage(sessions: [], err: '还没有登录，登录后才能查看私信');
    }
    final params = await WbiSign.sign({
      'session_type': '1',
      'group_fold': '1',
      'unfollow_fold': '0',
      'sort_rule': '2',
      'build': '0',
      'mobi_app': 'web',
      if (offset != null && offset > 0) 'end_ts': '$offset',
    });
    final json = await _getJson(
      '$_vcBase/session_svr/v1/session_svr/get_sessions',
      params,
    );
    if (json.err != null) {
      return BiliImSessionPage(sessions: const [], err: json.err);
    }
    final data = _asMap(json.data) ?? const <String, dynamic>{};
    final sessions = (data['session_list'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .map(BiliImSession.fromJson)
        .where((e) => e.talkerId > 0)
        .toList(growable: false);
    final list = sessions ?? const <BiliImSession>[];
                                          
    final cards = await fetchUserCards(
      list.map((e) => e.talkerId).toList(growable: false),
    );
    final merged = list
        .map(
          (e) => cards.containsKey(e.talkerId)
              ? e.withUser(
                  name: cards[e.talkerId]!.name,
                  face: cards[e.talkerId]!.face,
                )
              : e,
        )
        .toList(growable: false);
    return BiliImSessionPage(
      sessions: merged,
      offset: merged.isEmpty ? null : merged.last.timestamp,
      hasMore: _toInt(data['has_more']) == 1,
    );
  }

                                    
     
                                                                 
                                          
                                          
                
  static Future<Map<int, ({String name, String face})>> fetchUserCards(
    List<int> uids,
  ) async {
    final ids = uids.where((e) => e > 0).toSet().toList(growable: false);
    if (ids.isEmpty) return const {};
    final result = <int, ({String name, String face})>{};
    for (var i = 0; i < ids.length; i += 50) {
      final end = i + 50 > ids.length ? ids.length : i + 50;
      final json = await _getJson('$_vcBase/account/v1/user/cards', {
        'uids': ids.sublist(i, end).join(','),
        'build': '0',
        'mobi_app': 'web',
      });
      final data = json.data;
      if (data is List) {
        for (final item in data.whereType<Map<String, dynamic>>()) {
          _fillUserCard(result, item);
        }
      } else if (data is Map) {
        for (final entry in data.entries) {
          final card = _asMap(entry.value);
          if (card != null) _fillUserCard(result, card, fallbackMid: entry.key);
        }
      }
    }
    return result;
  }

  static void _fillUserCard(
    Map<int, ({String name, String face})> out,
    Map<String, dynamic> card, {
    Object? fallbackMid,
  }) {
    final mid = _toInt(card['mid'] ?? fallbackMid);
    if (mid <= 0) return;
    out[mid] = (
      name: _toStr(card['name']),
      face: _fixUrl(_toStr(card['face'])),
    );
  }

                                                             

                            
  static Future<BiliImMessagePage> fetchMessages({
    required int talkerId,
    int? beginSeqno,
    int? endSeqno,
    int size = 20,
  }) async {
    if (!canUse) {
      return const BiliImMessagePage(messages: [], err: '还没有登录，登录后才能查看私信');
    }
    final params = await WbiSign.sign({
      'talker_id': '$talkerId',
      'session_type': '1',
      'size': '$size',
      'build': '0',
      'mobi_app': 'web',
      if (beginSeqno != null) 'begin_seqno': '$beginSeqno',
      if (endSeqno != null) 'end_seqno': '$endSeqno',
    });
    final json = await _getJson(
      '$_vcBase/svr_sync/v1/svr_sync/fetch_session_msgs',
      params,
    );
    if (json.err != null) {
      return BiliImMessagePage(messages: const [], err: json.err);
    }
    final data = _asMap(json.data) ?? const <String, dynamic>{};
    final messages = (data['messages'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .map(BiliImMessage.fromJson)
        .toList(growable: false);
    return BiliImMessagePage(
      messages: messages ?? const <BiliImMessage>[],
      hasMore: _toInt(data['has_more']) == 1,
    );
  }

                                                                

             
  static Future<({bool ok, String message})> sendText({
    required int receiverId,
    required String content,
  }) => _send(
    receiverId: receiverId,
    msgType: ImMsgType.text,
    content: jsonEncode({'content': content}),
  );

                              
  static Future<({bool ok, String message})> sendImage({
    required int receiverId,
    required String url,
    int width = 0,
    int height = 0,
    int size = 0,
    String imageType = 'jpeg',
  }) => _send(
    receiverId: receiverId,
    msgType: ImMsgType.picture,
    content: jsonEncode({
      'url': url,
      'width': width,
      'height': height,
      'imageType': imageType,
      'original': 1,
      if (size > 0) 'size': size,
    }),
  );

                                                            
                                                         
                          
  static Future<({String url, int width, int height, int size})?> uploadImage(
    Uint8List bytes, {
    String filename = 'image.jpg',
  }) async {
    if (!canUse) return null;
    final csrf = _csrf();
    if (csrf.isEmpty) return null;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final req =
          http.MultipartRequest(
              'POST',
              Uri.parse('$_apiBase/x/dynamic/feed/draw/upload_bfs'),
            )
            ..fields['category'] = 'daily'
            ..fields['biz'] = 'im'
            ..fields['csrf'] = csrf
            ..files.add(
              http.MultipartFile.fromBytes(
                'file_up',
                bytes,
                filename: filename,
              ),
            );
      req.headers.addAll(_headers());
      final streamed = await client
          .send(req)
          .timeout(const Duration(seconds: 30));
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode != 200) {
        debugPrint('[IM] 上传图片 HTTP ${resp.statusCode}');
        return null;
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map || _toInt(json['code']) != 0) {
        debugPrint('[IM] 上传图片失败: ${json is Map ? json['message'] : json}');
        return null;
      }
      final data = _asMap(json['data']);
      final url = _fixUrl(_toStr(data?['image_url']));
      if (url.isEmpty) return null;
      return (
        url: url,
        width: _toInt(data?['image_width']),
        height: _toInt(data?['image_height']),
        size: _toInt(data?['img_size']),
      );
    } catch (e) {
      debugPrint('[IM] 上传图片异常: $e');
      return null;
    }
  }

                                      
  static Future<({bool ok, String message})> withdrawMessage({
    required int receiverId,
    required int msgKey,
  }) => _send(
    receiverId: receiverId,
    msgType: ImMsgType.withdraw,
    content: '$msgKey',
  );

  static Future<({bool ok, String message})> _send({
    required int receiverId,
    required int msgType,
    required String content,
  }) async {
    if (!canUse) return (ok: false, message: '还没有登录，登录后才能发私信');
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    final mid = selfMid;
    if (mid <= 0) return (ok: false, message: '登录信息缺少 UID，请重新登录');

    final devId = const Uuid().v4();
    final msg = <String, dynamic>{
      'sender_uid': mid,
      'receiver_id': receiverId,
      'receiver_type': 1,
      'msg_type': msgType,
      'msg_status': 0,
      'dev_id': devId,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'new_face_version': 1,
      'content': content,
    };
    final signed = await WbiSign.sign({
      'w_sender_uid': '$mid',
      'w_receiver_id': '$receiverId',
      'w_dev_id': devId,
    });
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse('$_vcBase/web_im/v1/web_im/send_msg').replace(
              queryParameters: {
                'w_sender_uid': '$mid',
                'w_receiver_id': '$receiverId',
                'w_dev_id': devId,
                if (signed['w_rid'] != null) 'w_rid': '${signed['w_rid']}',
                if (signed['wts'] != null) 'wts': '${signed['wts']}',
              },
            ),
            headers: {
              ..._headers(),
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'msg': jsonEncode(msg),
              'from_firework': '0',
              'build': '0',
              'mobi_app': 'web',
              'csrf_token': csrf,
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      final json = _decode(resp.statusCode, resp.bodyBytes);
      if (json.err != null) return (ok: false, message: json.err!);
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[IM] send_msg 失败: $e');
      return (ok: false, message: '网络异常：${e.runtimeType}');
    }
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

                                    
  static Future<({bool ok, String message})> setPinned({
    required int talkerId,
    required bool pinned,
  }) async {
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    final params = await WbiSign.sign({
      'talker_id': '$talkerId',
      'session_type': '1',
      'op_type': pinned ? '1' : '0',
      'build': '0',
      'mobi_app': 'web',
      'csrf_token': csrf,
      'csrf': csrf,
    });
    return _post('$_vcBase/session_svr/v1/session_svr/set_top', params);
  }

           
  static Future<({bool ok, String message})> deleteSession({
    required int talkerId,
  }) async {
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    final params = await WbiSign.sign({
      'talker_id': '$talkerId',
      'session_type': '1',
      'build': '0',
      'mobi_app': 'web',
      'csrf_token': csrf,
      'csrf': csrf,
    });
    return _post('$_vcBase/session_svr/v1/session_svr/remove_session', params);
  }

             
  static Future<({BiliImUnread unread, String? err})> fetchUnread() async {
    if (!canUse) return (unread: BiliImUnread.zero, err: null);
    final params = await WbiSign.sign({'build': '0', 'mobi_app': 'web'});
    final json = await _getJson(
      '$_vcBase/session_svr/v1/session_svr/single_unread',
      params,
    );
    if (json.err != null) {
      return (unread: BiliImUnread.zero, err: json.err);
    }
    final data = _asMap(json.data);
    if (data == null) return (unread: BiliImUnread.zero, err: null);
    return (
      unread: BiliImUnread(
        follow: _toInt(data['follow_unread']),
        unfollow: _toInt(data['unfollow_unread']),
        bizFollow: _toInt(data['biz_msg_follow_unread']),
        bizUnfollow: _toInt(data['biz_msg_unfollow_unread']),
      ),
      err: null,
    );
  }

                                                                           

                                         
  static Future<({BiliImSessionSettings? data, String? err})>
  fetchSessionSettings({required int talkerUid}) async {
    final csrf = _csrf();
    final json =
        await _getJson('$_vcBase/link_setting/v1/link_setting/get_session_ss', {
          'talker_uid': '$talkerUid',
          'build': '0',
          'mobi_app': 'web',
          if (csrf.isNotEmpty) 'csrf_token': csrf,
          if (csrf.isNotEmpty) 'csrf': csrf,
        });
    if (json.err != null) return (data: null, err: json.err);
    final data = _asMap(json.data);
    if (data == null) return (data: null, err: null);
    return (data: BiliImSessionSettings.fromJson(data), err: null);
  }

                                                    
  static Future<({bool ok, String message})> setPushSetting({
    required int talkerUid,
    required bool enabled,
  }) async {
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    return _post('$_vcBase/link_setting/v1/link_setting/set_push_ss', {
      'setting': enabled ? '1' : '0',
      'talker_uid': '$talkerUid',
      'build': '0',
      'mobi_app': 'web',
      'csrf_token': csrf,
      'csrf': csrf,
    });
  }

                                                     
  static Future<({bool? muted, String? err})> fetchMsgDnd({
    required int talkerUid,
  }) async {
    final mid = selfMid;
    final json = await _getJson(
      '$_vcBase/link_setting/v1/link_setting/get_msg_dnd',
      {
        'own_uid': '$mid',
        'uids_str': '$talkerUid',
        'build': '0',
        'mobi_app': 'web',
      },
    );
    if (json.err != null) return (muted: null, err: json.err);
    final list = _asMap(json.data)?['uid_settings'];
    if (list is! List || list.isEmpty) return (muted: null, err: null);
    final first = _asMap(list.first);
    if (first == null) return (muted: null, err: null);
    return (muted: _toInt(first['setting']) == 1, err: null);
  }

                                                
  static Future<({bool ok, String message})> setMsgDnd({
    required int talkerUid,
    required bool muted,
  }) async {
    final csrf = _csrf();
    final mid = selfMid;
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    if (mid <= 0) return (ok: false, message: '登录信息缺少 UID，请重新登录');
    return _post('$_vcBase/link_setting/v1/link_setting/set_msg_dnd', {
      'uid': '$mid',
      'setting': muted ? '1' : '0',
      'dnd_uid': '$talkerUid',
      'build': '0',
      'mobi_app': 'web',
      'csrf_token': csrf,
      'csrf': csrf,
    });
  }

                                                             

  static Future<({dynamic data, String? err})> _getJson(
    String url,
    Map<String, String> query,
  ) async {
    if (!canUse) return (data: null, err: '还没有登录，登录后才能查看私信');
    try {
      final uri = Uri.parse(url).replace(queryParameters: query);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      return _decode(resp.statusCode, resp.bodyBytes);
    } catch (e) {
      debugPrint('[IM] GET $url 失败: $e');
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
      debugPrint('[IM] POST $url 失败: $e');
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

                          
  static String contentField(String content, String key) {
    if (content.isEmpty) return '';
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map) return _toStr(decoded[key]);
    } catch (_) {}
    return '';
  }

                                              
  static dynamic decodeContent(String content) {
    if (content.isEmpty) return null;
    try {
      return jsonDecode(content);
    } catch (_) {
      return content;
    }
  }

                                            
  static Map<String, dynamic> contentMap(String content) {
    final decoded = decodeContent(content);
    return decoded is Map<String, dynamic> ? decoded : const {};
  }

                                                      
  static List<Map<String, dynamic>> contentList(dynamic value) => value is List
      ? value.whereType<Map<String, dynamic>>().toList(growable: false)
      : const [];

                                                           
                                                          
  static String tipText(String content) {
    if (content.isEmpty) return '';
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map) {
        final inner = decoded['content'];
        if (inner is String) return _textList(inner) ?? inner;
        if (inner is List) return _textList(inner) ?? '';
        final text = decoded['text'];
        if (text != null) return _toStr(text);
      }
      if (decoded is List) return _textList(decoded) ?? '';
      if (decoded is String) return decoded;
    } catch (_) {}
    return content;
  }

                                             
  static String? _textList(dynamic value) {
    List<dynamic>? list;
    if (value is List) {
      list = value;
    } else if (value is String && value.trim().startsWith('[')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) list = decoded;
      } catch (_) {}
    }
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map((e) => _toStr(e['text']))
        .where((e) => e.isNotEmpty)
        .join('\n');
  }
}
