// lib/services/bilibili_live_danmaku_service.dart
//
// B 站直播弹幕 WebSocket 客户端（协议流程对照 PiliPlus 的 tcp/live.dart）：
//   1. getDanmuInfo（WBI 签名）取弹幕服务器列表与 token
//   2. 连 wss://{host}:{wss_port}/sub，发 AUTH 包（op=7，protover=1 → zlib）
//   3. 每 30s 发一次心跳（op=2），回包 op=3 体是当前人气值
//   4. op=5 为业务消息，protover=1 时包体是 zlib 压缩的一批内层包，
//      解压后逐包按 cmd 分发（弹幕 / 进场 / 礼物 / 上舰 / SC / 人气…）
// 断线自动重连（2s 起步指数退避，封顶 60s），重连前重新取 token。
//
// 协议要点（踩过坑）：
//   - AUTH 的 opcode 是 7，不是 2（2 是心跳）；opcode 发错服务器不回包
//     也不推弹幕；
//   - protover=2 在 B 站语义是 brotli 压缩、1 是 zlib、0 是裸 JSON：
//     必须用 1 才能和下面的 ZLibCodec 匹配（brotli 数据拿 zlib 解必失败）。
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import 'bilibili_account_service.dart';
import 'bilibili_user_space_service.dart' show WbiSign;
import 'network_settings_service.dart';

// ════════════════════════════════════════
//  事件模型
// ════════════════════════════════════════

/// 弹幕流事件基类（聊天面板与弹幕覆盖层共用一条流）。
sealed class LiveDanmuEvent {
  const LiveDanmuEvent();
}

/// 一条弹幕（DANMU_MSG）。
class LiveDmEvent extends LiveDanmuEvent {
  final String name;
  final int uid;

  /// 弹幕文本（表情以 [name] 形式混在文本里）。
  final String text;

  /// 文字颜色（ARGB）。
  final Color color;

  /// 表情名 → 图片地址（聊天面板内联渲染）。
  final Map<String, String> emotes;

  /// 粉丝牌名（空 = 无牌）。
  final String medalName;
  final int medalLevel;

  /// 是否自己发的（用于高亮）。
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

/// 进场 / 关注提示（INTERACT_WORD，msgType 1=进入 2=关注）。
class LiveEnterEvent extends LiveDanmuEvent {
  final String name;
  final int uid;
  final int msgType;
  const LiveEnterEvent(this.name, this.uid, this.msgType);
}

/// 礼物（GIFT / COMBO_SEND）。
class LiveGiftEvent extends LiveDanmuEvent {
  final String name;
  final int uid;
  final String giftName;
  final int num;

  /// 动作词（投喂 / FEED…）。
  final String action;
  const LiveGiftEvent(this.name, this.uid, this.giftName, this.num,
      {this.action = '投喂'});
}

/// 上舰（GUARD_BUY，guardLevel 1=总督 2=提督 3=舰长）。
class LiveGuardEvent extends LiveDanmuEvent {
  final String name;
  final int uid;
  final String giftName;
  final int num;
  final int guardLevel;
  const LiveGuardEvent(this.name, this.uid, this.giftName, this.num,
      this.guardLevel);
}

/// SuperChat（醒目留言）。
class LiveSuperChatEvent extends LiveDanmuEvent {
  final int id;
  final String uname;
  final int uid;
  final String face;

  /// 价格（人民币）。
  final num price;
  final String message;

  /// 背景色（B 站给的整型色值，0xFF000000 | v）。
  final Color topColor;
  final Color bottomColor;

  /// 到期时间戳（秒）。
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

/// SC 删除（SUPER_CHAT_MESSAGE_DELETE）。
class LiveSuperChatDeleteEvent extends LiveDanmuEvent {
  final List<int> ids;
  const LiveSuperChatDeleteEvent(this.ids);
}

/// 观看人数变化（WATCHED_CHANGE，textLarge 形如「2551.7万人看过」）。
class LiveWatchedEvent extends LiveDanmuEvent {
  final String textLarge;
  const LiveWatchedEvent(this.textLarge);
}

/// 高能观众数（ONLINE_RANK_COUNT）。
class LiveOnlineRankEvent extends LiveDanmuEvent {
  final int count;
  const LiveOnlineRankEvent(this.count);
}

/// 标题变更（ROOM_CHANGE）。
class LiveRoomChangeEvent extends LiveDanmuEvent {
  final String title;
  const LiveRoomChangeEvent(this.title);
}

/// 心跳回包（当前房间人气值）。
class LivePopularityEvent extends LiveDanmuEvent {
  final int count;
  const LivePopularityEvent(this.count);
}

/// 开播状态变化（PREPARING / LIVE）。
class LiveStatusEvent extends LiveDanmuEvent {
  final bool living;
  const LiveStatusEvent(this.living);
}

// ════════════════════════════════════════
//  客户端
// ════════════════════════════════════════

class BilibiliLiveDanmakuClient {
  BilibiliLiveDanmakuClient({required this.roomId, this.selfUid = 0});

  /// 真实房间号（长号；短号会连不上）。
  final int roomId;

  /// 当前登录用户 mid（用于标记自己发的弹幕），未登录传 0。
  final int selfUid;

  final StreamController<LiveDanmuEvent> _events =
      StreamController<LiveDanmuEvent>.broadcast();

  /// 弹幕事件流（broadcast，可多处订阅）。
  Stream<LiveDanmuEvent> get events => _events.stream;

  WebSocket? _ws;
  Timer? _heartbeat;
  Timer? _reconnect;
  bool _disposed = false;

  /// 当前重连等待秒数（认证成功后归零）。
  int _reconnectDelay = 2;

  /// 供页面显示连接状态（true = 已完成认证）。
  bool authed = false;

  /// 连接（内部自带重连；重复调用无害）。
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
      // 依次尝试每台服务器
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

  /// getDanmuInfo（WBI 签名），返回 data 节点；失败返回 null。
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
      final cookie = BilibiliAccountService.instance
          .cookieHeaderFor(BiliCookieScope.video)?['Cookie'];
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            uri,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Referer': 'https://live.bilibili.com/',
              if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
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
      _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
        _send(ws, _op(_opHeartbeat, utf8.encode('[object Object]')));
      });
      return ws;
    } catch (e) {
      debugPrint('[LiveDm] 连接 $url 失败：$e');
      return null;
    }
  }

  void _sendAuth(WebSocket ws, String token) {
    final payload = jsonEncode({
      'uid': selfUid,
      'roomid': roomId,
      // protover=1：让服务器回包用 zlib 压缩（与下方 ZLibCodec 匹配）。
      // 注意 2 在 B 站语义是 brotli，brotli 数据拿 zlib 解必失败。
      'protover': 1,
      'platform': 'web',
      'type': 2,
      'key': token,
    });
    // 认证 opcode 是 7（_opAuth），不是 2（心跳）——发错服务器不回包
    // 也不推弹幕。
    _send(ws, _op(_opAuth, utf8.encode(payload)));
  }

  // ── 帧编解码 ──

  /// 包头 16 字节：包长(4) 头长(2) 协议版本(2) 操作码(4) 序号(4)，大端。
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
      ..setUint16(6, 1) // 协议版本：正文为裸 JSON
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

  /// 解析一串可能连续排布的二进制包。
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
          }
        case _opHeartbeatReply:
          if (body.length >= 4) {
            final popularity =
                ByteData.sublistView(body).getUint32(0);
            _emit(LivePopularityEvent(popularity));
          }
        case _opMessage:
          if (protover == 1) {
            // zlib 压缩的内层包（可能是一批）
            try {
              final raw = ZLibCodec().decoder.convert(body);
              _parsePackets(Uint8List.fromList(raw));
            } catch (e) {
              debugPrint('[LiveDm] zlib 解压失败：$e');
            }
          } else if (protover == 0) {
            // 内层包正文就是一条 JSON 业务消息（未压缩）
            try {
              final obj = jsonDecode(utf8.decode(body));
              if (obj is Map<String, dynamic>) _handleJson(obj);
            } catch (e) {
              debugPrint('[LiveDm] 消息解析失败：$e');
            }
          } else {
            // protover=2 是 brotli、3 是 zstd：auth 固定用 1（zlib），
            // 正常不会收到；真收到时记日志便于排查（当前不支持）。
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

  // ── 业务消息分发 ──

  void _handleJson(Map<String, dynamic> obj) {
    final cmd = obj['cmd']?.toString() ?? '';
    // 前缀形如 DANMU_MSG:4:0:2:2:2:0
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

  /// DANMU_MSG：新版 info[0][15] 带 user/extra 结构，老版 info[2] 兜底。
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
    // info[0] 是按下标取值的元数据数组，15 号位为用户/附加信息 map
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
    // 老版结构兜底：info[2] = [uid, uname, ...]
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

  // ── 测试钩子（仅 flutter test 使用，见 test/live_danmaku_protocol_test.dart）──

  /// 构造认证包（op=7，protover=1）。协议关键数字若有回归，测试立刻红。
  @visibleForTesting
  Uint8List debugEncodeAuth(int roomId, String token, {int selfUid = 0}) {
    final payload = jsonEncode({
      'uid': selfUid,
      'roomid': roomId,
      'protover': 1,
      'platform': 'web',
      'type': 2,
      'key': token,
    });
    return _op(_opAuth, utf8.encode(payload));
  }

  /// 直接喂入一帧原始字节走完整解析链路（不依赖真实 WebSocket）。
  @visibleForTesting
  void debugFeedBytes(Uint8List bytes) => _parsePackets(bytes);

  // ── 重连 ──

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

  // ── 小工具 ──

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
