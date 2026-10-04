                                                
  
                                                          
  
                                        
                                                          
                                              
                                                                     
                                                           
                                                                 
                        
                                                                       
                                                                    
                                                
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';

import 'bilibili_account_service.dart';

abstract final class BilibiliReplyGrpcService {
  static const String host = 'grpc.biliapi.net';
  static const int port = 443;
  static const String methodPath =
      '/bilibili.main.community.reply.v1.Reply/MainList';

  static final ClientMethod<List<int>, List<int>> _method =
      ClientMethod<List<int>, List<int>>(
        methodPath,
        (q) => q,
        (bytes) => bytes,
      );

                                                       
                                            
                       
  static ClientChannel? _channel;
  static ClientChannel get _sharedChannel =>
      _channel ??= ClientChannel(host, port: port);

                                            
  static final Map<String, ({bool value, DateTime at})> _cache = {};
  static const Duration _cacheTtl = Duration(minutes: 10);

                                       
                                              
  static Future<bool?> isCurated({required int oid, int type = 1}) async {
    if (oid <= 0) return null;
    final key = '${oid}_$type';
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.at) < _cacheTtl) {
      return cached.value;
    }
    final payload = _encodeMainListReq(oid: oid, type: type);
    final channel = _sharedChannel;
    try {
      final metadata = <String, String>{
        'x-bili-device-bin': deviceBinB64,
        'x-bili-metadata-bin': metadataBinB64,
        'buvid': _buvidValue,
      };
                                           
      String? cookie;
      try {
        cookie = BilibiliAccountService.instance.cookieHeaderFor(
          BiliCookieScope.comments,
        )?['Cookie'];
      } catch (_) {
        cookie = null;
      }
      if (cookie != null && cookie.isNotEmpty) {
        metadata['cookie'] = cookie;
      }
      final client = Client(
        channel,
        options: CallOptions(
          metadata: metadata,
          timeout: const Duration(seconds: 12),
        ),
      );
      final resp = await client.$createUnaryCall(_method, payload);
      final curated = _parseMainListReply(Uint8List.fromList(resp));
      if (curated != null) {
        _cache[key] = (value: curated, at: DateTime.now());
      }
      return curated;
    } catch (e) {
      debugPrint('[ReplyGrpc] MainList 异常: $e');
      return null;
    }
  }

                             
  static void invalidate({int? oid, int? type}) {
    if (oid == null) {
      _cache.clear();
      return;
    }
    _cache.remove('${oid}_${type ?? 1}');
  }

                                                                 

                                                           
  static Uint8List _encodeMainListReq({required int oid, required int type}) {
    final out = BytesBuilder(copy: false)
      ..add(_int64(1, oid))
      ..add(_int64(2, type))
      ..add(_int32(9, 2));
    return out.toBytes();
  }

                                                                 

                                                  
                                        
  static bool? _parseMainListReply(Uint8List data) {
    var sawSubjectControl = false;
    var title = '';
    for (final f in _walk(data)) {
      if (f.number == 3 && f.wire == 2 && f.value != null) {
        sawSubjectControl = true;
        for (final g in _walk(f.value!)) {
          if (g.number == 17 && g.wire == 2 && g.value != null) {
            title = utf8.decode(g.value!, allowMalformed: true);
          }
        }
      }
    }
    if (!sawSubjectControl) return null;
    return title.contains('精选');
  }

                                                                        

  static String? _buvid;
  static String? _deviceBinB64;
  static String? _metadataBinB64;

  static String get _buvidValue => _buvid ??= _genBuvid();

  static String get deviceBinB64 => _deviceBinB64 ??= _b64(_encodeDevice());

  static String get metadataBinB64 =>
      _metadataBinB64 ??= _b64(_encodeMetadata());

  static String _b64(List<int> bytes) =>
      base64Encode(bytes).replaceAll('=', '');

                                                                     
                                                         
  static Uint8List _encodeDevice() {
    final out = BytesBuilder(copy: false)
      ..add(_int64(1, 10013))
      ..add(_int64(2, 8840200));
    final buvid = _buvidValue;
    if (buvid.isNotEmpty) out.add(_string(3, buvid));
    out
      ..add(_string(4, 'android'))
      ..add(_string(5, 'android'))
      ..add(_string(6, 'Pixel 8'))
      ..add(_string(7, 'bili'))
      ..add(_string(8, 'Google'))
      ..add(_string(9, 'Pixel 8'))
      ..add(_string(10, '14'))
      ..add(_string(13, '8.84.0'));
    return out.toBytes();
  }

                                                                
  static Uint8List _encodeMetadata() {
    final out = BytesBuilder(copy: false)
      ..add(_string(2, 'android'))
      ..add(_int64(4, 8840200))
      ..add(_string(5, 'bili'));
    final buvid = _buvidValue;
    if (buvid.isNotEmpty) out.add(_string(6, buvid));
    out.add(_string(7, 'android'));
    return out.toBytes();
  }

  static String _genBuvid() {
    final r = Random();
    String hex(int n) =>
        List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    final uuid =
        '${hex(8)}-${hex(4)}-4${hex(3)}-'
                '${'89ab'[r.nextInt(4)]}${hex(3)}-${hex(12)}'
            .toUpperCase();
    return '$uuid${r.nextInt(100000).toString().padLeft(5, '0')}infoc';
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

  static Uint8List _int32(int fieldNumber, int value) =>
      _concat(_tag(fieldNumber, 0), _encodeVarint(value));

  static Uint8List _int64(int fieldNumber, int value) {
    if (value < 0) value += 1 << 64;
    return _concat(_tag(fieldNumber, 0), _encodeVarint(value));
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
