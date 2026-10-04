                                                  
  
                                                          
                                           
                                                                      
                                         
                                                 
                                                   
                                         
  
                                         
                                                    
             
                                                   
                                                     
                                        
                                                           
                      
                                              
                                              
                                     
                                                  
import 'package:naviflash/utils/json_decode.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import 'bilibili_account_service.dart';
import 'bilibili_user_space_service.dart' show WbiSign;
import 'network_settings_service.dart';

                                           
        
                                           

                             
sealed class LiveDanmuEvent {
  const LiveDanmuEvent();
}

                    
class LiveDmEvent extends LiveDanmuEvent {
  final String name;
  final int uid;

                               
  final String text;

                 
  final Color color;

                           
  final Map<String, String> emotes;

                   
  final String medalName;
  final int medalLevel;

                   
  final bool isSelf;

  const LiveDmEvent({
    required this.name,
    required this.uid,
    required this.text,
    required this.color,
    required this.emotes,
    this.medalName = '',
    this.medalLevel = 0,
    this.isSelf = false,
  });
}

                                               
class LiveEnterEvent extends LiveDanmuEvent {
  final String name;
  final int uid;
  final int msgType;
  const LiveEnterEvent(this.name, this.uid, this.msgType);
}

                          
class LiveGiftEvent extends LiveDanmuEvent {
  final String name;
  final int uid;
  final String giftName;
  final int num;

                      
  final String action;
  const LiveGiftEvent(this.name, this.uid, this.giftName, this.num,
      {this.action = '投喂'});
}

                                            
class LiveGuardEvent extends LiveDanmuEvent {
  final String name;
  final int uid;
  final String giftName;
  final int num;
  final int guardLevel;
  const LiveGuardEvent(this.name, this.uid, this.giftName, this.num,
      this.guardLevel);
}

                    
class LiveSuperChatEvent extends LiveDanmuEvent {
  final int id;
  final String uname;
  final int uid;
  final String face;

              
  final num price;
  final String message;

                                    
  final Color topColor;
  final Color bottomColor;

               
  final int endTime;
  const LiveSuperChatEvent({
    required this.id,
    required this.uname,
    required this.uid,
    required this.face,
    required this.price,
    required this.message,
    required this.topColor,
    required this.bottomColor,
    required this.endTime,
  });
}

                                     
class LiveSuperChatDeleteEvent extends LiveDanmuEvent {
  final List<int> ids;
  const LiveSuperChatDeleteEvent(this.ids);
}

                                                    
class LiveWatchedEvent extends LiveDanmuEvent {
  final String textLarge;
  const LiveWatchedEvent(this.textLarge);
}

                             
class LiveOnlineRankEvent extends LiveDanmuEvent {
  final int count;
  const LiveOnlineRankEvent(this.count);
}

                      
class LiveRoomChangeEvent extends LiveDanmuEvent {
  final String title;
  const LiveRoomChangeEvent(this.title);
}

                  
class LivePopularityEvent extends LiveDanmuEvent {
  final int count;
  const LivePopularityEvent(this.count);
}

                             
class LiveStatusEvent extends LiveDanmuEvent {
  final bool living;
  const LiveStatusEvent(this.living);
}

                                           
       
                                           

class BilibiliLiveDanmakuClient {
  BilibiliLiveDanmakuClient({required this.roomId, this.selfUid = 0});

                       
  final int roomId;

                                    
  final int selfUid;

  final StreamController<LiveDanmuEvent> _events =
      StreamController<LiveDanmuEvent>.broadcast();

                             
  Stream<LiveDanmuEvent> get events => _events.stream;

  WebSocket? _ws;
  Timer? _heartbeat;
  Timer? _reconnect;
  bool _disposed = false;

                        
  int _reconnectDelay = 2;

                              
  bool authed = false;

                        
  Future<void> start() async {
    if (_disposed || _ws != null) return;
    try {
      final info = await _fetchDanmuInfo();
      if (_disposed) return;
      if (info == null) {
        _scheduleReconnect();
        return;
      }
      final (:token, :hosts) = info;
      if (hosts.isEmpty) {
        debugPrint('[LiveDm] 弹幕服务器列表为空');
        _scheduleReconnect();
        return;
      }
                  
      for (final host in hosts) {
        final ws = await _tryConnect(host, token);
        if (_disposed) return;
        if (ws != null) {
          _ws = ws;
          return;
        }
      }
      debugPrint('[LiveDm] 所有弹幕服务器连接失败');
      _scheduleReconnect();
    } catch (e) {
      debugPrint('[LiveDm] 连接异常：$e');
      _scheduleReconnect();
    }
  }

  Future<({String token, List<Map<String, dynamic>> hosts})?>
      _fetchDanmuInfo() async {
    final data = await _getDanmuInfoData(roomId);
    if (data == null) return null;
    final token = data['token']?.toString() ?? '';
    final list = data['host_list'];
    final hosts = <Map<String, dynamic>>[];
    if (list is List) {
      for (final h in list.whereType<Map<String, dynamic>>()) {
        if ((h['host']?.toString() ?? '').isNotEmpty) hosts.add(h);
      }
    }
    return (token: token, hosts: hosts);
  }

                                         
                    
  static final String _guestBuvid3 = _genBuvid3();

  static String _genBuvid3() {
    final r = Random();
    String hex(int n) =>
        List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    final uuid =
        '${hex(8)}-${hex(4)}-4${hex(3)}-'
                '${'89ab'[r.nextInt(4)]}${hex(3)}-${hex(12)}'
            .toUpperCase();
    return '$uuid${r.nextInt(100000).toString().padLeft(5, '0')}infoc';
  }

  static String _extractCookie(String cookie, String name) {
    final m = RegExp('(?:^|;\\s*)$name=([^;]+)').firstMatch(cookie);
    return m?.group(1) ?? '';
  }

                                              
                                                   
  static String _resolveBuvid3() {
    var fromCookie = '';
    try {
      final cookie = BilibiliAccountService.instance
              .cookieHeaderFor(BiliCookieScope.video)?['Cookie'] ??
          '';
      fromCookie = _extractCookie(cookie, 'buvid3');
    } catch (_) {
                                       
    }
    return fromCookie.isNotEmpty ? fromCookie : _guestBuvid3;
  }

                                                
  static Future<Map<String, dynamic>?> _getDanmuInfoData(int roomId) async {
    try {
      final params = await WbiSign.sign({
        'id': roomId.toString(),
        'type': '0',
        'web_location': '444.8',
      });
      final uri = Uri.parse(
        'https://api.live.bilibili.com/xlive/web-room/v1/index/getDanmuInfo',
      ).replace(queryParameters: params);
      final loginCookie = BilibiliAccountService.instance
          .cookieHeaderFor(BiliCookieScope.video)?['Cookie'];
      final buvid3 = _resolveBuvid3();
                                                 
      final cookie = loginCookie == null || loginCookie.isEmpty
          ? 'buvid3=$buvid3'
          : _extractCookie(loginCookie, 'buvid3').isEmpty
              ? '$loginCookie; buvid3=$buvid3'
              : loginCookie;
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            uri,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Referer': 'https://live.bilibili.com/',
              'Cookie': cookie,
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final decoded = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;
      if (_toInt(decoded['code']) != 0) return null;
      final data = decoded['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      debugPrint('[LiveDm] 获取弹幕服务器失败：$e');
      return null;
    }
  }

  Future<WebSocket?> _tryConnect(
    Map<String, dynamic> host,
    String token,
  ) async {
    final url =
        'wss://${host['host']}:${_toInt(host['wss_port'])}/sub';
    try {
      final ws = await WebSocket.connect(url)
          .timeout(const Duration(seconds: 8));
      debugPrint('[LiveDm] 已连接 $url');
      ws.listen(
        (data) => _onFrame(data),
        onDone: () {
          debugPrint('[LiveDm] 连接断开');
          _onDisconnected();
        },
        onError: (e) {
          debugPrint('[LiveDm] 连接错误：$e');
          _onDisconnected();
        },
        cancelOnError: true,
      );
      _sendAuth(ws, token);
                                                               
                           
      return ws;
    } catch (e) {
      debugPrint('[LiveDm] 连接 $url 失败：$e');
      return null;
    }
  }

  void _sendAuth(WebSocket ws, String token) {
    _send(ws, _encodeAuth(roomId, token));
  }

                                               
                                                          
  Uint8List _encodeAuth(int roomId, String token, {int selfUid = 0}) {
    final payload = jsonEncode({
      'uid': selfUid,
      'roomid': roomId,
                                                      
      'protover': 2,
      'platform': 'web',
      'type': 2,
      'key': token,
                                    
      'buvid': _resolveBuvid3(),
    });
    return _op(_opAuth, utf8.encode(payload));
  }

                                                      
  void _startHeartbeat() {
    _heartbeat?.cancel();
    if (_ws == null) return;
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      _send(_ws, _op(_opHeartbeat, const []));
    });
  }

               

                                                   
  static const int _headerLen = 16;

  static const int _opHeartbeat = 2;
  static const int _opHeartbeatReply = 3;
  static const int _opMessage = 5;
  static const int _opAuth = 7;
  static const int _opAuthReply = 8;

  Uint8List _op(int opcode, List<int> body) {
    final total = _headerLen + body.length;
    final b = BytesBuilder();
    final head = ByteData(_headerLen)
      ..setUint32(0, total)
      ..setUint16(4, _headerLen)
      ..setUint16(6, 1)                  
      ..setUint32(8, opcode)
      ..setUint32(12, 1);
    b.add(head.buffer.asUint8List());
    b.add(body);
    return b.toBytes();
  }

  void _send(WebSocket? ws, List<int> packet) {
    try {
      ws?.add(packet);
    } catch (e) {
      debugPrint('[LiveDm] 发送失败：$e');
    }
  }

  void _onFrame(dynamic data) {
    try {
      if (data is List<int>) {
        _parsePackets(Uint8List.fromList(data));
      }
    } catch (e) {
      debugPrint('[LiveDm] 帧解析异常：$e');
    }
  }

                      
  void _parsePackets(Uint8List bytes) {
    var offset = 0;
    while (offset + _headerLen <= bytes.length) {
      final bd = ByteData.sublistView(bytes, offset);
      final packetLen = bd.getUint32(0);
      if (packetLen < _headerLen || offset + packetLen > bytes.length) break;
      final headerLen = bd.getUint16(4);
      final protover = bd.getUint16(6);
      final opcode = bd.getUint32(8);
      var body = bytes.sublist(
        offset + headerLen,
        offset + packetLen,
      );

      switch (opcode) {
        case _opAuthReply:
          authed = _authOk(body);
          if (authed) {
            _reconnectDelay = 2;
            debugPrint('[LiveDm] 房间 $roomId 认证成功');
            _startHeartbeat();
          } else {
            debugPrint('[LiveDm] 房间 $roomId 认证失败：${utf8.decode(body)}');
          }
        case _opHeartbeatReply:
          if (body.length >= 4) {
            final popularity =
                ByteData.sublistView(body).getUint32(0);
            _emit(LivePopularityEvent(popularity));
          }
        case _opMessage:
          if (protover == 2 || protover == 1) {
                                                        
                                                     
            try {
              final raw = ZLibCodec().decoder.convert(body);
              _parsePackets(Uint8List.fromList(raw));
            } catch (e) {
              debugPrint('[LiveDm] zlib 解压失败：$e');
            }
          } else if (protover == 0) {
                                       
            try {
              final obj = jsonDecode(utf8.decode(body));
              if (obj is Map<String, dynamic>) _handleJson(obj);
            } catch (e) {
              debugPrint('[LiveDm] 消息解析失败：$e');
            }
          } else {
                                                             
                                               
            debugPrint('[LiveDm] 未支持的压缩版本 protover=$protover');
          }
        default:
          break;
      }
      offset += packetLen;
    }
  }

  bool _authOk(Uint8List body) {
    try {
      final obj = jsonDecode(utf8.decode(body));
      if (obj is Map<String, dynamic>) {
        return _toInt(obj['code']) == 0;
      }
    } catch (_) {}
    return false;
  }

                 

  void _handleJson(Map<String, dynamic> obj) {
    final cmd = obj['cmd']?.toString() ?? '';
                                 
    final base = cmd.split(':')[0];
    switch (base) {
      case 'DANMU_MSG':
        _emit(_parseDm(obj['info']));
      case 'INTERACT_WORD':
        final data = _mapOf(obj['data']);
        _emit(LiveEnterEvent(
          _s(data['uname']),
          _toInt(data['uid']),
          _toInt(data['msg_type']),
        ));
      case 'GIFT':
        final data = _mapOf(obj['data']);
        _emit(LiveGiftEvent(
          _s(data['uname']),
          _toInt(data['uid']),
          _s(data['giftName']),
          _toInt(data['num']),
          action: _s(data['action']),
        ));
      case 'COMBO_SEND':
        final data = _mapOf(obj['data']);
        _emit(LiveGiftEvent(
          _s(data['uname']),
          _toInt(data['uid']),
          _s(_pick(data, ['gift_name', 'giftName'])),
          _toInt(_pick(data, ['combo_num', 'gift_num', 'num'])),
          action: _s(data['action']),
        ));
      case 'GUARD_BUY':
        final data = _mapOf(obj['data']);
        _emit(LiveGuardEvent(
          _s(data['username']),
          _toInt(data['uid']),
          _s(data['gift_name']),
          _toInt(data['num']),
          _toInt(data['guard_level']),
        ));
      case 'SUPER_CHAT_MESSAGE':
        final sc = _parseSuperChat(_mapOf(obj['data']));
        if (sc != null) _emit(sc);
      case 'SUPER_CHAT_MESSAGE_DELETE':
        final data = _mapOf(obj['data']);
        final ids = (data['ids'] as List? ?? const [])
            .map((e) => _toInt(e))
            .toList();
        _emit(LiveSuperChatDeleteEvent(ids));
      case 'WATCHED_CHANGE':
        _emit(LiveWatchedEvent(
          _s(_mapOf(obj['data'])['text_large']),
        ));
      case 'ONLINE_RANK_COUNT':
        _emit(LiveOnlineRankEvent(_toInt(_mapOf(obj['data'])['count'])));
      case 'ROOM_CHANGE':
        _emit(LiveRoomChangeEvent(_s(_mapOf(obj['data'])['title'])));
      case 'PREPARING':
        _emit(const LiveStatusEvent(false));
      case 'LIVE':
        _emit(const LiveStatusEvent(true));
      default:
        break;
    }
  }

                                                             
  LiveDmEvent _parseDm(dynamic info) {
    if (info is! List || info.length < 2) {
      return LiveDmEvent(
        name: '',
        uid: 0,
        text: '',
        color: const Color(0xFFFFFFFF),
        emotes: const {},
      );
    }
    final text = _s(info[1]);
                                             
    final metaList = info[0] is List ? info[0] as List : const [];
    final hasContent = metaList.length > 15 &&
        metaList[15] is Map<String, dynamic>;

    String name = '';
    int uid = 0;
    String medalName = '';
    int medalLevel = 0;
    Map<String, String> emotes = const {};
    int colorInt = 16777215;

    if (hasContent) {
      final content = metaList[15] as Map<String, dynamic>;
      final user = _mapOf(content['user']);
      final base = _mapOf(user['base']);
      name = _s(base['name']);
      uid = _toInt(user['uid']);
      final medal = _mapOf(user['medal']);
      medalName = _s(medal['name']);
      medalLevel = _toInt(medal['level']);
      final extraRaw = _s(content['extra']);
      if (extraRaw.isNotEmpty) {
        try {
          final extra = jsonDecode(extraRaw);
          if (extra is Map<String, dynamic>) {
            colorInt = _toInt(extra['color'], fallback: 16777215);
            final emots = extra['emots'];
            if (emots is Map<String, dynamic>) {
              emotes = {
                for (final e in emots.entries)
                  if (_mapOf(e.value)['url'] != null)
                    e.key: _s(_mapOf(e.value)['url']),
              };
            }
          }
        } catch (_) {}
      }
    }
                                         
    if (name.isEmpty && info.length > 2 && info[2] is List) {
      final user2 = info[2] as List;
      uid = user2.isNotEmpty ? _toInt(user2[0]) : 0;
      name = user2.length > 1 ? _s(user2[1]) : '';
    }
    if (metaList.length > 3) {
      final c = _toInt(metaList[3]);
      if (c > 0) colorInt = c;
    }

    return LiveDmEvent(
      name: name,
      uid: uid,
      text: text,
      color: Color(0xFF000000 | (colorInt & 0xFFFFFF)),
      emotes: emotes,
      medalName: medalName,
      medalLevel: medalLevel,
      isSelf: selfUid > 0 && uid == selfUid,
    );
  }

  LiveSuperChatEvent? _parseSuperChat(Map<String, dynamic> data) {
    final id = _toInt(data['id']);
    if (id <= 0) return null;
    final user = _mapOf(data['user_info']);
    return LiveSuperChatEvent(
      id: id,
      uname: _s(user['uname']),
      uid: _toInt(data['uid']),
      face: _s(user['face']),
      price: data['price'] is num
          ? data['price'] as num
          : (num.tryParse('${data['price']}') ?? 0),
      message: _s(data['message']),
      topColor: Color(0xFF000000 | (_toInt(data['background_color']) & 0xFFFFFF)),
      bottomColor: Color(
          0xFF000000 | (_toInt(data['background_bottom_color']) & 0xFFFFFF)),
      endTime: _toInt(data['end_time']),
    );
  }

                                                                        

                                              
  @visibleForTesting
  Uint8List debugEncodeAuth(int roomId, String token, {int selfUid = 0}) =>
      _encodeAuth(roomId, token, selfUid: selfUid);

                                         
  @visibleForTesting
  void debugFeedBytes(Uint8List bytes) => _parsePackets(bytes);

             

  void _onDisconnected() {
    _ws = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    authed = false;
    if (!_disposed) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnect != null) return;
    final delay = _reconnectDelay;
    _reconnectDelay = (_reconnectDelay * 2).clamp(2, 60);
    debugPrint('[LiveDm] ${delay}s 后重连');
    _reconnect = Timer(Duration(seconds: delay), () {
      _reconnect = null;
      start();
    });
  }

  void dispose() {
    _disposed = true;
    _reconnect?.cancel();
    _reconnect = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    try {
      _ws?.close();
    } catch (_) {}
    _ws = null;
    _events.close();
  }

  void _emit(LiveDanmuEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

              

  static Map<String, dynamic> _mapOf(dynamic v) =>
      v is Map<String, dynamic> ? v : const <String, dynamic>{};

  static String _s(dynamic v) => v?.toString() ?? '';

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  static String _pick(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return '';
  }
}
