// lib/services/bilibili_translate_api.dart
//
// B 站 AI 翻译 gRPC 客户端（对照桌面逆向模块 bilibili_ai_translate.py）。
//
//   - 视频标题/简介翻译不走 REST，而是 gRPC:
//     POST https://grpc.biliapi.net:443
//          /bilibili.app.translation.v1.Translation/TranslationSimple
//   - 请求体是 protobuf TranslationSimpleReq:
//       1 bizType    enum   1=ARC(视频) 2=REPLY 3=OPUS 4=LIVE 5=CHEESE
//       2 businessId string 业务ID（视频用 avid）
//       3 spmid      string 埋点
//       4 fields     []string 如 ["title","desc"]
//       5 text       []string 与 fields 一一对应的原文
//   - 目标语言 + AI 翻译开关由请求头 x-bili-locale-bin 决定（见
//     BilibiliTranslateService.requestHeaders），头值必须 base64 去 '=' 补位。
//   - 响应 TranslationSimpleReply: 1=results[] TranslatedField
//     TranslatedField: 1=field 2=originalText 3=translatedText
//                      4=isTranslated(bool) 5=lang 6=region 7=script
import 'dart:convert';
import 'dart:typed_data';

import 'package:grpc/grpc.dart';

import 'bilibili_account_service.dart';
import 'bilibili_translate_service.dart';
import 'bv_av.dart';

/// 单条字段的翻译结果。
class BiliTranslatedField {
  final String field;
  final String original;
  final String translated;
  final bool isTranslated;
  final String language;
  final String region;
  final String script;

  const BiliTranslatedField({
    required this.field,
    required this.original,
    required this.translated,
    required this.isTranslated,
    this.language = '',
    this.region = '',
    this.script = '',
  });
}

/// 视频标题+简介的翻译结果。
class BiliVideoTranslation {
  final String title;
  final String originalTitle;
  final String desc;
  final String originalDesc;
  final bool isTranslated;

  const BiliVideoTranslation({
    required this.title,
    required this.originalTitle,
    required this.desc,
    required this.originalDesc,
    required this.isTranslated,
  });
}

class BilibiliTranslateApi {
  static const String host = 'grpc.biliapi.net';
  static const int port = 443;
  static const String methodPath =
      '/bilibili.app.translation.v1.Translation/TranslationSimple';
  static const String batchPath =
      '/bilibili.app.translation.v1.Translation/TranslationBatch';
  static const String replyPath =
      '/bilibili.main.community.reply.v1.Reply/TranslateReply';

  static final ClientMethod<List<int>, List<int>> _method =
      ClientMethod<List<int>, List<int>>(
    methodPath,
    (q) => q,
    (bytes) => bytes,
  );

  static final ClientMethod<List<int>, List<int>> _batchMethod =
      ClientMethod<List<int>, List<int>>(
    batchPath,
    (q) => q,
    (bytes) => bytes,
  );

  static final ClientMethod<List<int>, List<int>> _replyMethod =
      ClientMethod<List<int>, List<int>>(
    replyPath,
    (q) => q,
    (bytes) => bytes,
  );

  /// 翻译视频标题（含简介）。未启用 AI 翻译 / 全部失败时返回 null。
  ///
  /// 关键（test.apk 逆向 + 实测）：
  ///   - 标题和简介必须**拆成独立请求**——同一次请求带多个字段时服务端返回空。
  ///   - 标题字段优先走「按 avid 查表翻译」：fields=["title"]、text 留空；
  ///     若该视频没有服务端预生成的目标语言标题，自动降级为「文本翻译」：
  ///     把标题原文填进 text（服务端对提供的文本做通用翻译）。
  ///   - 简介字段始终用文本翻译：fields=["desc"]、text=[desc]。
  static Future<BiliVideoTranslation?> translateVideoTitle({
    required int aid,
    required String title,
    String? desc,
  }) async {
    final translate = BilibiliTranslateService.instance;
    if (!translate.enabled) return null;
    final headers = translate.requestHeaders;
    if (headers.isEmpty) return null;

    final cookie = BilibiliAccountService.instance
        .cookieHeaderFor(BiliCookieScope.video)?['Cookie'];
    final metadata = <String, String>{
      ...headers,
      if (cookie != null && cookie.isNotEmpty) 'cookie': cookie,
    };
    const detailSpmid = 'main.ugc-video-detail.0.0';

    final channel = ClientChannel(host, port: port);
    try {
      final client = Client(
        channel,
        options: CallOptions(
          metadata: metadata,
          timeout: const Duration(seconds: 20),
        ),
      );

      // ① 标题
      BiliTranslatedField? titleField;
      try {
        // 1a) 按 avid 查表（text 空）
        final byId = await _unaryField(
          client,
          bizType: 1,
          businessId: '$aid',
          fields: const ['title'],
          texts: const [],
          spmid: detailSpmid,
          key: 'title',
        );
        if (byId != null && byId.translated.isNotEmpty) {
          titleField = byId;
        }
      } catch (_) {}
      // 1b) 查表无结果 → 退化文本翻译
      if (titleField == null && title.isNotEmpty) {
        try {
          final byText = await _unaryField(
            client,
            bizType: 1,
            businessId: '$aid',
            fields: const ['title'],
            texts: [title],
            spmid: detailSpmid,
            key: 'title',
          );
          if (byText != null && byText.translated.isNotEmpty) {
            titleField = byText;
          }
        } catch (_) {}
      }

      // ② 简介（文本翻译）
      BiliTranslatedField? descField;
      if (desc != null && desc.isNotEmpty) {
        try {
          descField = await _unaryField(
            client,
            bizType: 1,
            businessId: '$aid',
            fields: const ['desc'],
            texts: [desc],
            spmid: detailSpmid,
            key: 'desc',
          );
        } catch (_) {}
      }

      if (titleField == null && descField == null) return null;
      return BiliVideoTranslation(
        title: titleField?.translated ?? '',
        originalTitle: titleField?.original ?? title,
        desc: descField?.translated ?? '',
        originalDesc: descField?.original ?? '',
        isTranslated: (titleField ?? descField)?.isTranslated ?? false,
      );
    } finally {
      try {
        await channel.shutdown();
      } catch (_) {}
    }
  }

  /// 单字段 unary 调用并取回对应字段的翻译结果。
  static Future<BiliTranslatedField?> _unaryField(
    Client client, {
    required int bizType,
    required String businessId,
    required List<String> fields,
    required List<String> texts,
    required String spmid,
    required String key,
  }) async {
    final payload = _encodeSimpleReq(
      bizType: bizType,
      businessId: businessId,
      fields: fields,
      texts: texts,
      spmid: spmid,
    );
    final resp = await client.$createUnaryCall(_method, payload);
    return _parseSimpleReplyFields(Uint8List.fromList(resp))[key];
  }

  /// 翻译专栏（文章）标题。
  ///
  /// 与视频同源 gRPC：bizType=3（OPUS，B 站已将专栏/动态统一为 OPUS），
  /// businessId 用文章的 cvid/id。先按 id 查表翻译（text 空），
  /// 无结果时退化为文本翻译（把标题原文填进 text）。
  /// 未启用 AI 翻译 / 全部失败时返回 null。
  static Future<BiliTranslatedField?> translateArticleTitle({
    required int cvid,
    required String title,
  }) async {
    final translate = BilibiliTranslateService.instance;
    if (!translate.enabled) return null;
    final headers = translate.requestHeaders;
    if (headers.isEmpty) return null;

    final cookie = BilibiliAccountService.instance
        .cookieHeaderFor(BiliCookieScope.video)?['Cookie'];
    final metadata = <String, String>{
      ...headers,
      if (cookie != null && cookie.isNotEmpty) 'cookie': cookie,
    };
    const spmid = 'main.read-detail.0.0';

    final channel = ClientChannel(host, port: port);
    try {
      final client = Client(
        channel,
        options: CallOptions(
          metadata: metadata,
          timeout: const Duration(seconds: 20),
        ),
      );

      // ① 按 id 查表翻译（text 空）
      BiliTranslatedField? field;
      try {
        final byId = await _unaryField(
          client,
          bizType: 3,
          businessId: '$cvid',
          fields: const ['title'],
          texts: const [],
          spmid: spmid,
          key: 'title',
        );
        if (byId != null && byId.translated.isNotEmpty) {
          field = byId;
        }
      } catch (_) {}
      // ② 查表无结果 → 退化文本翻译
      if ((field == null || field.translated.isEmpty) && title.isNotEmpty) {
        try {
          final byText = await _unaryField(
            client,
            bizType: 3,
            businessId: '$cvid',
            fields: const ['title'],
            texts: [title],
            spmid: spmid,
            key: 'title',
          );
          if (byText != null && byText.translated.isNotEmpty) {
            field = byText;
          }
        } catch (_) {}
      }
      return field;
    } finally {
      try {
        await channel.shutdown();
      } catch (_) {}
    }
  }

  /// 批量翻译视频标题（搜索卡片 / 相关视频列表）。
  /// 走 TranslationBatch：每项一个 TranslationSimpleReq(title)，返回按序
  /// 对应的 TranslationSimpleReply（字段1=results[]）。
  /// [items] 仅需 bvid + 原始标题；内部用 BvAv 算出 avid 作为 businessId。
  /// 返回 ``Map<bvid, 英文标题>``；未启用翻译 / 失败 / 无译文时为空 Map。
  static Future<Map<String, String>> translateTitles(
    List<({String bvid, String title})> items,
  ) async {
    if (items.isEmpty) return const {};
    final translate = BilibiliTranslateService.instance;
    if (!translate.enabled) return const {};
    final headers = translate.requestHeaders;
    if (headers.isEmpty) return const {};

    final valid = <({int aid, String bvid, String title})>[];
    for (final it in items) {
      final aid = BvAv.decode(it.bvid);
      if (aid == null || aid <= 0 || it.title.isEmpty) continue;
      valid.add((aid: aid, bvid: it.bvid, title: it.title));
    }
    if (valid.isEmpty) return const {};

    final cookie = BilibiliAccountService.instance
        .cookieHeaderFor(BiliCookieScope.video)?['Cookie'];
    final metadata = <String, String>{
      ...headers,
      if (cookie != null && cookie.isNotEmpty) 'cookie': cookie,
    };

    final channel = ClientChannel(host, port: port);
    try {
      final client = Client(
        channel,
        options: CallOptions(
          metadata: metadata,
          timeout: const Duration(seconds: 20),
        ),
      );
      final payload = _encodeBatchReq(valid);
      final resp = await client.$createUnaryCall(_batchMethod, payload);
      final replies = _parseBatchReply(Uint8List.fromList(resp));
      final out = <String, String>{};
      for (var i = 0; i < valid.length && i < replies.length; i++) {
        final tf = replies[i]['title'];
        if (tf != null && tf.translated.isNotEmpty) {
          out[valid[i].bvid] = tf.translated;
        }
      }
      return out;
    } catch (_) {
      return const {};
    } finally {
      try {
        await channel.shutdown();
      } catch (_) {}
    }
  }

  /// 评论翻译（评论区「翻译」按钮）。
  /// gRPC: /bilibili.main.community.reply.v1.Reply/TranslateReply
  /// 请求 TranslateReplyReq: 1=type 2=oid 3=rpids(packed)。
  /// 响应 TranslateReplyResp: 1=``map<rpid, ReplyInfo>``，
  /// 译文取 ReplyInfo.translatedContent(17) → Content.message(1)。
  ///
  /// 登录说明：该接口不强依赖登录态（免登录 + buvid 设备头即可请求，
  /// 与标题翻译同网关；登录后更稳、风控更少）。方法与标题翻译一致——
  /// 有 Cookie 就带，没有也照常发。返回 {rpid: 译文}，失败/无结果为空 Map。
  static Future<Map<int, String>> translateComment({
    required int oid,
    required int type,
    required List<int> rpids,
  }) async {
    if (rpids.isEmpty) return const {};
    final translate = BilibiliTranslateService.instance;
    if (!translate.enabled) return const {};
    final headers = translate.requestHeaders;
    if (headers.isEmpty) return const {};

    final cookie = BilibiliAccountService.instance
        .cookieHeaderFor(BiliCookieScope.comments)?['Cookie'];
    final metadata = <String, String>{
      ...headers,
      if (cookie != null && cookie.isNotEmpty) 'cookie': cookie,
    };

    final payload =
        _encodeTranslateReplyReq(oid: oid, type: type, rpids: rpids);

    final channel = ClientChannel(host, port: port);
    try {
      final client = Client(
        channel,
        options: CallOptions(
          metadata: metadata,
          timeout: const Duration(seconds: 20),
        ),
      );
      final resp = await client.$createUnaryCall(_replyMethod, payload);
      return _parseTranslateReplyResp(Uint8List.fromList(resp));
    } catch (_) {
      return const {};
    } finally {
      try {
        await channel.shutdown();
      } catch (_) {}
    }
  }

  // ═════════════════════ protobuf wire 编码 ═════════════════════

  static Uint8List _encodeVarint(int value) {
    final out = BytesBuilder(copy: false);
    while (true) {
      final b = value & 0x7F;
      value >>= 7;
      if (value != 0) {
        out.addByte(b | 0x80);
      } else {
        out.addByte(b);
        return out.toBytes();
      }
    }
  }

  static Uint8List _tag(int fieldNumber, int wireType) =>
      _encodeVarint((fieldNumber << 3) | wireType);

  static Uint8List _concat(Uint8List a, Uint8List b) {
    final out = Uint8List(a.length + b.length);
    out.setRange(0, a.length, a);
    out.setRange(a.length, out.length, b);
    return out;
  }

  static Uint8List _string(int fieldNumber, String value) {
    final data = Uint8List.fromList(utf8.encode(value));
    return _concat(_concat(_tag(fieldNumber, 2), _encodeVarint(data.length)), data);
  }

  static Uint8List _bytes(int fieldNumber, Uint8List data) =>
      _concat(_concat(_tag(fieldNumber, 2), _encodeVarint(data.length)), data);

  static Uint8List _int32(int fieldNumber, int value) =>
      _concat(_tag(fieldNumber, 0), _encodeVarint(value));

  static Uint8List _int64(int fieldNumber, int value) {
    if (value < 0) value += 1 << 64;
    return _concat(_tag(fieldNumber, 0), _encodeVarint(value));
  }

  /// TranslateReplyReq: 1=type(int64) 2=oid(int64) 3=rpids(packed int64)。
  static Uint8List _encodeTranslateReplyReq({
    required int oid,
    required int type,
    required List<int> rpids,
  }) {
    final out = BytesBuilder(copy: false)..add(_int64(1, type));
    out.add(_int64(2, oid));
    if (rpids.isNotEmpty) {
      final body = BytesBuilder(copy: false);
      for (final r in rpids) {
        body.add(_encodeVarint(r < 0 ? r + (1 << 64) : r));
      }
      out.add(_concat(
        _concat(_tag(3, 2), _encodeVarint(body.length)),
        body.toBytes(),
      ));
    }
    return out.toBytes();
  }

  static Uint8List _encodeSimpleReq({
    required int bizType,
    required String businessId,
    required List<String> fields,
    required List<String> texts,
    String spmid = '',
  }) {
    final out = BytesBuilder(copy: false)..add(_int32(1, bizType));
    if (businessId.isNotEmpty) out.add(_string(2, businessId));
    if (spmid.isNotEmpty) out.add(_string(3, spmid));
    for (final f in fields) {
      out.add(_string(4, f));
    }
    for (final t in texts) {
      out.add(_string(5, t));
    }
    return out.toBytes();
  }

  /// TranslationBatchReq: 1=spmid(可选), 2=items[] TranslationSimpleReq。
  static Uint8List _encodeBatchReq(
    List<({int aid, String bvid, String title})> items,
  ) {
    final out = BytesBuilder(copy: false);
    for (final it in items) {
      final item = _encodeSimpleReq(
        bizType: 1,
        businessId: '${it.aid}',
        fields: const ['title'],
        texts: [it.title],
      );
      out.add(_bytes(2, item));
    }
    return out.toBytes();
  }

  /// TranslationBatchReply: 1=results[] TranslationSimpleReply（与 items 按序对应）。
  /// 返回 ``List<Map<String, BiliTranslatedField>>``。
  static List<Map<String, BiliTranslatedField>> _parseBatchReply(
    Uint8List data,
  ) {
    final out = <Map<String, BiliTranslatedField>>[];
    for (final f in _walk(data)) {
      if (f.number != 1 || f.wire != 2) continue;
      out.add(_parseSimpleReplyFields(f.value!));
    }
    return out;
  }

  /// TranslationSimpleReply: 1=results[] TranslatedField。
  /// 返回 ``Map<String, BiliTranslatedField>``（key = 字段名），
  /// 便于按标题/简介字段分别取结果。
  static Map<String, BiliTranslatedField> _parseSimpleReplyFields(
    Uint8List data,
  ) {
    final out = <String, BiliTranslatedField>{};
    for (final f in _walk(data)) {
      if (f.number != 1 || f.wire != 2) continue;
      final tf = _parseTranslatedField(f.value!);
      if (tf == null || tf.field.isEmpty) continue;
      out[tf.field] = tf;
    }
    return out;
  }

  /// TranslateReplyResp: 1=``map<int64, ReplyInfo>`` 条目（proto map 编码）。
  /// 条目消息：1=key(int64), 2=value(ReplyInfo, message)；
  /// ReplyInfo.translatedContent = 17（Content 类型，message）；Content.message = 1。
  /// 返回 {rpid: 译文}。
  static Map<int, String> _parseTranslateReplyResp(Uint8List data) {
    final out = <int, String>{};
    for (final entry in _walk(data)) {
      if (entry.number != 1 || entry.wire != 2) continue;
      int? key;
      String? translated;
      for (final f in _walk(entry.value!)) {
        if (f.number == 1 && f.wire == 0) {
          key = f.intValue;
        } else if (f.number == 2 && f.wire == 2) {
          // ReplyInfo → translatedContent(17, Content) → message(1)
          for (final r in _walk(f.value!)) {
            if (r.number != 17 || r.wire != 2) continue;
            for (final c in _walk(r.value!)) {
              if (c.number == 1 && c.wire == 2) {
                translated = utf8.decode(c.value!, allowMalformed: true);
              }
            }
          }
        }
      }
      if (key != null && translated != null && translated.isNotEmpty) {
        out[key] = translated;
      }
    }
    return out;
  }

  static BiliTranslatedField? _parseTranslatedField(Uint8List data) {
    var field = '';
    var original = '';
    var translated = '';
    var isTranslated = false;
    var lang = '';
    var region = '';
    var script = '';
    for (final f in _walk(data)) {
      if (f.wire == 2) {
        if (f.number == 1) {
          field = utf8.decode(f.value!, allowMalformed: true);
        } else if (f.number == 2) {
          original = utf8.decode(f.value!, allowMalformed: true);
        } else if (f.number == 3) {
          translated = utf8.decode(f.value!, allowMalformed: true);
        } else if (f.number == 5) {
          lang = utf8.decode(f.value!, allowMalformed: true);
        } else if (f.number == 6) {
          region = utf8.decode(f.value!, allowMalformed: true);
        } else if (f.number == 7) {
          script = utf8.decode(f.value!, allowMalformed: true);
        }
      } else if (f.wire == 0) {
        if (f.number == 4) isTranslated = f.intValue == 1;
      }
    }
    return BiliTranslatedField(
      field: field,
      original: original,
      translated: translated,
      isTranslated: isTranslated,
      language: lang,
      region: region,
      script: script,
    );
  }

  // ═════════════════════ protobuf wire 解析 ═════════════════════

  static Iterable<_PbField> _walk(Uint8List data) sync* {
    var i = 0;
    while (i < data.length) {
      final (key, ni) = _readVarint(data, i);
      i = ni;
      final number = key >> 3;
      final wire = key & 7;
      if (wire == 0) {
        final (value, nj) = _readVarint(data, i);
        i = nj;
        yield _PbField(number, wire, null, value);
      } else if (wire == 2) {
        final (len, nj) = _readVarint(data, i);
        i = nj;
        if (i + len > data.length) return;
        yield _PbField(number, wire, data.sublist(i, i + len), 0);
        i += len;
      } else if (wire == 1) {
        if (i + 8 > data.length) return;
        yield _PbField(number, wire, data.sublist(i, i + 8), 0);
        i += 8;
      } else if (wire == 5) {
        if (i + 4 > data.length) return;
        yield _PbField(number, wire, data.sublist(i, i + 4), 0);
        i += 4;
      } else {
        return;
      }
    }
  }

  static (int, int) _readVarint(Uint8List data, int i) {
    var value = 0;
    var shift = 0;
    while (i < data.length) {
      final b = data[i];
      i++;
      value |= (b & 0x7F) << shift;
      if ((b & 0x80) == 0) break;
      shift += 7;
    }
    return (value, i);
  }
}

class _PbField {
  final int number;
  final int wire;
  final Uint8List? value;
  final int intValue;
  const _PbField(this.number, this.wire, this.value, this.intValue);
}