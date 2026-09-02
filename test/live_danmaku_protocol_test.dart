// 回归测试：B 站直播弹幕 WebSocket 协议关键数字（对照 PiliPlus / 业界共识）。
//
// 缺陷背景：弹幕一直不显示，根因在协议层两个低级错误——
//   1. 认证包 opcode 用了 2（心跳），正确是 7（AUTH）：服务器不回包、
//      不推任何弹幕；
//   2. auth 里 protover=2（B 站语义 = brotli 压缩），解析端却用
//      ZLibCodec（zlib）解压，brotli 数据拿 zlib 解必失败。
// 修复：认证 op=7 + protover=1（zlib），解析按 protover==1 走 zlib、
// ==0 走裸 JSON。本测试把协议数字锁死，回归即红。
import 'dart:convert';
import 'dart:io' show ZLibCodec;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/services/bilibili_live_danmaku_service.dart';

/// 解析 16 字节包头：返回 (packetLen, headerLen, protover, opcode, body)。
({int len, int header, int protover, int op, Uint8List body}) _parseHead(
  Uint8List bytes,
) {
  final bd = ByteData.sublistView(bytes);
  final len = bd.getUint32(0);
  final header = bd.getUint16(4);
  final protover = bd.getUint16(6);
  final op = bd.getUint32(8);
  return (
    len: len,
    header: header,
    protover: protover,
    op: op,
    body: Uint8List.sublistView(bytes, header, len),
  );
}

void main() {

  test('认证包：opcode=7（不是心跳的 2）、protover=1（zlib）、payload 含 roomid/key', () {
    final client = BilibiliLiveDanmakuClient(roomId: 21696950);
    addTearDown(client.dispose);
    final packet = client.debugEncodeAuth(21696950, 'test-token', selfUid: 0);
    final h = _parseHead(packet);

    expect(h.op, 7, reason: '认证 opcode 必须是 7（AUTH），2 是心跳');
    expect(h.protover, 1, reason: 'protover=1 → 服务器回包用 zlib 压缩');
    expect(h.len, 16 + h.body.length);

    final payload = jsonDecode(utf8.decode(h.body)) as Map<String, dynamic>;
    expect(payload['roomid'], 21696950);
    expect(payload['key'], 'test-token');
    expect(payload['protover'], 1);
  });

  test('心跳回包（op=3）解析出人气值事件', () async {
    final client = BilibiliLiveDanmakuClient(roomId: 21696950);
    addTearDown(client.dispose);
    final events = <LiveDanmuEvent>[];
    final sub = client.events.listen(events.add);

    // 手工构造 op=3 回包：16 字节头 + 4 字节人气值
    final body = ByteData(4)..setUint32(0, 12345);
    final bytes = ByteData(20)
      ..setUint32(0, 20)
      ..setUint16(4, 16)
      ..setUint16(6, 0)
      ..setUint32(8, 3)
      ..setUint32(12, 1);
    bytes.buffer.asUint8List().setRange(16, 20, body.buffer.asUint8List());
    client.debugFeedBytes(bytes.buffer.asUint8List());
    await pumpEventQueue();

    expect(events, hasLength(1));
    expect(events.single, isA<LivePopularityEvent>());
    expect((events.single as LivePopularityEvent).count, 12345);
    sub.cancel();
  });

  test('op=5 + protover=1：zlib 压缩的弹幕批次可解出 DANMU_MSG', () async {
    final client = BilibiliLiveDanmakuClient(roomId: 21696950);
    addTearDown(client.dispose);
    final events = <LiveDanmuEvent>[];
    final sub = client.events.listen(events.add);

    // 内层包：op=5、protover=0、正文 = 一条 DANMU_MSG JSON
    const dm = {
      'cmd': 'DANMU_MSG',
      'info': [
        [3, 16777215, 16777215, 16777215, 16777215, 1, 'test-uid-1', 0],
        '你好直播弹幕',
        [123, '测试用户', 0, 0, 0, 100, 0, 0],
      ],
    };
    final innerBody = utf8.encode(jsonEncode(dm));
    final inner = ByteData(16 + innerBody.length)
      ..setUint32(0, 16 + innerBody.length)
      ..setUint16(4, 16)
      ..setUint16(6, 0)
      ..setUint32(8, 5)
      ..setUint32(12, 1);
    inner.buffer
        .asUint8List()
        .setRange(16, 16 + innerBody.length, innerBody);

    // 外层包：op=5、protover=1、body = zlib(内层包)
    final compressed =
        Uint8List.fromList(ZLibCodec().encoder.convert(inner.buffer.asUint8List()));
    final outer = ByteData(16 + compressed.length)
      ..setUint32(0, 16 + compressed.length)
      ..setUint16(4, 16)
      ..setUint16(6, 1) // protover=1 → zlib
      ..setUint32(8, 5)
      ..setUint32(12, 1);
    outer.buffer.asUint8List().setRange(16, 16 + compressed.length, compressed);

    client.debugFeedBytes(outer.buffer.asUint8List());
    await pumpEventQueue();

    expect(events, hasLength(1), reason: '应解出 1 条弹幕');
    final dmEvent = events.single as LiveDmEvent;
    expect(dmEvent.text, '你好直播弹幕');
    expect(dmEvent.name, '测试用户');
    expect(dmEvent.uid, 123);
    sub.cancel();
  });

  test('DANMU_MSG 新版结构（info[0][15]）能解析出用户名与粉丝牌', () async {
    final client = BilibiliLiveDanmakuClient(roomId: 21696950);
    addTearDown(client.dispose);
    final events = <LiveDanmuEvent>[];
    final sub = client.events.listen(events.add);

    final dm = <String, dynamic>{
      'cmd': 'DANMU_MSG',
      'info': [
        [
          0,
          16777215,
          16777215,
          16777215,
          16777215,
          1,
          'test-uid-1',
          0,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          {
            'user': {
              'base': {'name': '新结构用户'},
              'uid': 999,
              'medal': {'name': '应援牌', 'level': 12},
            },
            'extra': jsonEncode({'color': 4278255360, 'emots': {}}),
          },
        ],
        '新版弹幕文本',
        [1, '兜底用户', 0, 0, 0, 100, 0, 0],
      ],
    };
    final body = utf8.encode(jsonEncode(dm));
    final bytes = ByteData(16 + body.length)
      ..setUint32(0, 16 + body.length)
      ..setUint16(4, 16)
      ..setUint16(6, 0)
      ..setUint32(8, 5)
      ..setUint32(12, 1);
    bytes.buffer.asUint8List().setRange(16, 16 + body.length, body);

    client.debugFeedBytes(bytes.buffer.asUint8List());
    await pumpEventQueue();

    final e = events.single as LiveDmEvent;
    expect(e.text, '新版弹幕文本');
    expect(e.name, '新结构用户', reason: '应优先用 info[0][15] 的新结构用户名');
    expect(e.uid, 999);
    expect(e.medalName, '应援牌');
    expect(e.medalLevel, 12);
    sub.cancel();
  });
}
