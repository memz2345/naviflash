                                           
  
                                                         
  
                                
                                        
                                                                      
                                          
                                                                     
                                           
                               
                                                 
                                               
                                                
                                                                     
                                                             
                                                               
                                                                     
import 'dart:convert';
import 'dart:typed_data';

import 'package:grpc/grpc.dart';

import 'bilibili_account_service.dart';
import 'bilibili_translate_service.dart';
import 'bv_av.dart';

              
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
      ClientMethod<List<int>, List<int>>(batchPath, (q) => q, (bytes) => bytes);

  static final ClientMethod<List<int>, List<int>> _replyMethod =
      ClientMethod<List<int>, List<int>>(replyPath, (q) => q, (bytes) => bytes);

                                          
                                                            
                                
  static ClientChannel? _channel;
  static ClientChannel get _sharedChannel =>
      _channel ??= ClientChannel(host, port: port);

                                           
     
                           
                                               
                                                        
                                          
                                       
                                                  
  static Future<BiliVideoTranslation?> translateVideoTitle({
    required int aid,
    required String title,
    String? desc,
  }) async {
    final translate = BilibiliTranslateService.instance;
    if (!translate.enabled) return null;
    final headers = translate.requestHeaders;
    if (headers.isEmpty) return null;

    final cookie = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.video,
    )?['Cookie'];
    final metadata = <String, String>{
      ...headers,
      if (cookie != null && cookie.isNotEmpty) 'cookie': cookie,
    };
    const detailSpmid = 'main.ugc-video-detail.0.0';

    final channel = _sharedChannel;
    {
      final client = Client(
        channel,
        options: CallOptions(
          metadata: metadata,
          timeout: const Duration(seconds: 20),
        ),
      );

             
      BiliTranslatedField? titleField;
      try {
                                
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
    }
  }

                                          
                                         
                                
  static Future<Map<String, String>> translateVideoTags({
    required int aid,
    required List<String> tags,
  }) async {
    final map = <String, String>{};
    final translate = BilibiliTranslateService.instance;
    if (!translate.enabled || tags.isEmpty) return map;
    final headers = translate.requestHeaders;
    if (headers.isEmpty) return map;
    final cookie = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.video,
    )?['Cookie'];
    final metadata = <String, String>{
      ...headers,
      if (cookie != null && cookie.isNotEmpty) 'cookie': cookie,
    };
    const spmid = 'main.ugc-video-detail.0.0';
                              
    final clean = [
      for (final t in tags)
        if (t.trim().isNotEmpty) t,
    ];
    if (clean.isEmpty) return map;
    final channel = _sharedChannel;
    try {
      final client = Client(
        channel,
        options: CallOptions(
          metadata: metadata,
          timeout: const Duration(seconds: 20),
        ),
      );
                                
      List<Map<String, BiliTranslatedField>> replies = const [];
      try {
        final resp = await client.$createUnaryCall(
          _batchMethod,
          _encodeTagBatchReq(aid, clean),
        );
        replies = _parseBatchReply(Uint8List.fromList(resp));
      } catch (_) {}
      for (var i = 0; i < clean.length && i < replies.length; i++) {
        final t = replies[i]['title']?.translated;
        if (t != null && t.isNotEmpty && t != clean[i]) map[clean[i]] = t;
      }
                                             
      if (map.isEmpty) {
        for (var i = 0; i < clean.length; i++) {
          final tag = clean[i];
          try {
            final field = await _unaryField(
              client,
              bizType: 1,
              businessId: '${aid}_t$i',
              fields: const ['title'],
              texts: [tag],
              spmid: spmid,
              key: 'title',
            );
            final t = field?.translated;
            if (t != null && t.isNotEmpty && t != tag) map[tag] = t;
          } catch (_) {
                        
          }
        }
      }
    } catch (_) {
                 
    } finally {
      try {
        await channel.shutdown();
      } catch (_) {}
    }
    return map;
  }

                               
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

                 
     
                                                    
                                                 
                                
                               
  static Future<BiliTranslatedField?> translateArticleTitle({
    required int cvid,
    required String title,
  }) async {
    final translate = BilibiliTranslateService.instance;
    if (!translate.enabled) return null;
    final headers = translate.requestHeaders;
    if (headers.isEmpty) return null;

    final cookie = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.video,
    )?['Cookie'];
    final metadata = <String, String>{
      ...headers,
      if (cookie != null && cookie.isNotEmpty) 'cookie': cookie,
    };
    const spmid = 'main.read-detail.0.0';

    final channel = _sharedChannel;
    {
      final client = Client(
        channel,
        options: CallOptions(
          metadata: metadata,
          timeout: const Duration(seconds: 20),
        ),
      );

                            
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
    }
  }

                              
                                                              
                                                
                                                            
                                                     
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

    final cookie = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.video,
    )?['Cookie'];
    final metadata = <String, String>{
      ...headers,
      if (cookie != null && cookie.isNotEmpty) 'cookie': cookie,
    };

    final channel = _sharedChannel;
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
    }
  }

                      
                                                                  
                                                         
                                                        
                                                               
     
                                          
                                      
                                                    
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

    final cookie = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.comments,
    )?['Cookie'];
    final metadata = <String, String>{
      ...headers,
      if (cookie != null && cookie.isNotEmpty) 'cookie': cookie,
    };

    final payload = _encodeTranslateReplyReq(
      oid: oid,
      type: type,
      rpids: rpids,
    );

    final channel = _sharedChannel;
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
    }
  }

                                                                 

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
    return _concat(
      _concat(_tag(fieldNumber, 2), _encodeVarint(data.length)),
      data,
    );
  }

  static Uint8List _bytes(int fieldNumber, Uint8List data) =>
      _concat(_concat(_tag(fieldNumber, 2), _encodeVarint(data.length)), data);

  static Uint8List _int32(int fieldNumber, int value) =>
      _concat(_tag(fieldNumber, 0), _encodeVarint(value));

  static Uint8List _int64(int fieldNumber, int value) {
    if (value < 0) value += 1 << 64;
    return _concat(_tag(fieldNumber, 0), _encodeVarint(value));
  }

                                                                          
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
      out.add(
        _concat(
          _concat(_tag(3, 2), _encodeVarint(body.length)),
          body.toBytes(),
        ),
      );
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

                                 
     
                        
                                                      
                                           
                           
                                               
                                    
  static Uint8List _encodeTagBatchReq(int aid, List<String> tags) {
    final out = BytesBuilder(copy: false);
    for (var i = 0; i < tags.length; i++) {
      out.add(
        _bytes(
          2,
          _encodeSimpleReq(
            bizType: 1,
            businessId: '${aid}_t$i',
            fields: const ['title'],
            texts: [tags[i]],
          ),
        ),
      );
    }
    return out.toBytes();
  }

                                                                       
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
