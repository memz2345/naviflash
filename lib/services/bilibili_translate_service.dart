// lib/services/bilibili_translate_service.dart
//
// B 站 AI 翻译设置 + 翻译请求头生成。
//
//   - 翻译目标语言由 protobuf 编码后 base64 进 x-bili-locale-bin 头决定
//   - 边缘网关把 x-bili-*-bin 头按 base64 解码，头值必须 base64 且无 '=' 补位
//   - x-bili-metadata-bin 是 Metadata proto（非 Device），见 _encodeMetadata
//
// 本服务负责：
//   - 持久化「启用 AI 翻译」开关与目标语言
//   - 开启后生成 bilibili 请求头（locale / metadata / device bin），
//     由 NetworkSettingsService.apiHeaders 合并到所有 B 站 API 请求上，
//     使服务端按所选语言返回 AI 翻译后的标题 / 简介等内容。
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 可供选择的 B 站翻译目标语言。
class BiliTranslateLanguage {
  /// 形如 zh-CN / en-US / ja-JP 的语言码，同时作为持久化值与 Locale 依据。
  final String code;

  /// protobuf Locale 的 language 字段。
  final String language;

  /// protobuf Locale 的 script 字段（如 Hans），可空。
  final String script;

  /// protobuf Locale 的 region 字段。
  final String region;

  const BiliTranslateLanguage({
    required this.code,
    required this.language,
    this.script = '',
    required this.region,
  });

  static const List<BiliTranslateLanguage> values = [
    BiliTranslateLanguage(code: 'zh-CN', language: 'zh', region: 'CN'),
    BiliTranslateLanguage(code: 'zh-HK', language: 'zh', region: 'HK'),
    BiliTranslateLanguage(code: 'zh-TW', language: 'zh', region: 'TW'),
    BiliTranslateLanguage(code: 'en-US', language: 'en', region: 'US'),
    BiliTranslateLanguage(code: 'ja-JP', language: 'ja', region: 'JP'),
    BiliTranslateLanguage(code: 'ko-KR', language: 'ko', region: 'KR'),
  ];

  static BiliTranslateLanguage fromCode(String? code) => values
      .firstWhere((l) => l.code == code, orElse: () => values.first);
}

/// B 站 AI 翻译设置服务：开关 + 目标语言。
class BilibiliTranslateService extends ChangeNotifier {
  static BilibiliTranslateService? _instance;

  /// 全局单例（initialize 后可用）。
  static BilibiliTranslateService get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError('BilibiliTranslateService 尚未初始化');
    }
    return inst;
  }

  /// 未初始化时返回空头，供 apiHeaders 安全合并。
  static Map<String, String> get activeHeaders {
    final inst = _instance;
    if (inst == null) return const {};
    return inst.requestHeaders;
  }

  bool _enabled = false;
  BiliTranslateLanguage _language = BiliTranslateLanguage.values.first;

  /// 会话级 buvid（device bin 使用）。
  late final String _buvid = _genBuvid();

  /// device-bin / metadata-bin 只依赖会话级常量（buvid / fts 等），
  /// 惰性计算一次并固定 —— header 内容必须稳定，否则每次 build 都会拿到新的
  /// NetworkImage（本 Flutter 版本的 NetworkImage.== 会比对 headers），
  /// 导致封面图反复重新下载、页面闪屏。
  late final String _deviceBinB64 = _b64(_encodeDevice());
  late final String _metadataBinB64 = _b64(_encodeMetadata());


  bool get enabled => _enabled;

  BiliTranslateLanguage get language => _language;

  /// 启用 AI 翻译时返回翻译请求头，关闭时返回空 Map。
  /// 与 APK (国际版) 的 okhttp 拦截器 xp2.a / kntr.net.comm 保持一致：
  ///   - x-bili-device-bin          = Device  proto (base64 去补位)
  ///   - x-bili-metadata-bin        = Metadata proto (base64 去补位, 不是 Device!)
  ///   - x-bili-locale-bin          = Locale  proto (含 always_translate 字段7)
  ///   - buvid                      明文头
  Map<String, String> get requestHeaders {
    if (!_enabled) return const {};
    final sys = _systemLocale();
    final now = DateTime.now();
    final utc = _formatUtcOffset(now.timeZoneOffset);
    final locale = _encodeLocale(
      _language,
      sLanguage: sys.$1,
      sRegion: sys.$2,
      utcOffset: utc,
      isDaylightTime: now.timeZoneOffset != _standardOffsetFor(now),
      alwaysTranslate: true,
    );
    return {
      'x-bili-locale-bin': _b64(locale),
      'x-bili-metadata-bin': _metadataBinB64,
      'x-bili-device-bin': _deviceBinB64,
      'buvid': _buvid,
    };
  }

  BilibiliTranslateService();

  Future<void> initialize() async {
    _instance = this;
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('biliAiTranslateEnabled') ?? false;
    _language = BiliTranslateLanguage.fromCode(
      prefs.getString('biliAiTranslateLang'),
    );
    notifyListeners();
  }


  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biliAiTranslateEnabled', value);
    notifyListeners();
  }

  Future<void> setLanguage(BiliTranslateLanguage value) async {
    if (_language == value) return;
    _language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('biliAiTranslateLang', value.code);
    notifyListeners();
  }

  // ================= protobuf wire 编码（与逆向模块一致） =================

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

  static Uint8List _encodeTag(int fieldNumber, int wireType) =>
      _encodeVarint((fieldNumber << 3) | wireType);

  static Uint8List _encodeString(int fieldNumber, String value) {
    final data = Uint8List.fromList(utf8.encode(value));
    final head = BytesBuilder(copy: false)
      ..add(_encodeTag(fieldNumber, 2))
      ..add(_encodeVarint(data.length));
    return _concat(head.toBytes(), data);
  }

  static Uint8List _encodeBytesField(int fieldNumber, Uint8List data) {
    final head = BytesBuilder(copy: false)
      ..add(_encodeTag(fieldNumber, 2))
      ..add(_encodeVarint(data.length));
    return _concat(head.toBytes(), data);
  }

  static Uint8List _encodeInt64(int fieldNumber, int value) {
    if (value < 0) value += 1 << 64;
    return _concat(_encodeTag(fieldNumber, 0), _encodeVarint(value));
  }

  static Uint8List _concat(Uint8List a, Uint8List b) {
    final out = Uint8List(a.length + b.length);
    out.setRange(0, a.length, a);
    out.setRange(a.length, out.length, b);
    return out;
  }

  /// 体系/边缘网关一致的 -bin 头编码：标准 base64 去掉 '=' 补位。
  /// (io.grpc.InternalMetadata.BASE64_ENCODING_OMIT_PADDING) 与
  /// kntr kotlin.io.encoding.Base64.Default（均无补位）。
  static String _b64(List<int> bytes) => base64Encode(bytes).replaceAll('=', '');

  static Uint8List _encodeBool(int fieldNumber, bool value) =>
      _concat(_encodeTag(fieldNumber, 0), _encodeVarint(value ? 1 : 0));

  static Uint8List _localeIds(String language, String script, String region) {
    final out = BytesBuilder(copy: false);
    if (language.isNotEmpty) out.add(_encodeString(1, language));
    if (script.isNotEmpty) out.add(_encodeString(2, script));
    if (region.isNotEmpty) out.add(_encodeString(3, region));
    return out.toBytes();
  }

  /// x-bili-locale-bin：bilibili.metadata.locale.Locale（决定翻译目标语言 +
  /// AI 翻译开关）。与 APK LocaleCache/kntr.base.net.comm.imp.j 生成的字节等价：
  ///   1 c_locale = App 当前语言（目标语言）
  ///   2 s_locale = 系统语言
  ///   4 timezone（本实现省略，服务端按 utc_offset 折算）
  ///   5 utc_offset 如 +08:00
  ///   6 is_daylight_time
  ///   7 always_translate
  static Uint8List _encodeLocale(
    BiliTranslateLanguage lang, {
    String sLanguage = '',
    String sRegion = '',
    String utcOffset = '',
    bool isDaylightTime = false,
    bool alwaysTranslate = false,
  }) {
    final out = BytesBuilder(copy: false);
    out.add(_encodeBytesField(
      1,
      _localeIds(lang.language, lang.script, lang.region),
    ));
    if (sLanguage.isNotEmpty) {
      out.add(_encodeBytesField(2, _localeIds(sLanguage, '', sRegion)));
    }
    if (utcOffset.isNotEmpty) out.add(_encodeString(5, utcOffset));
    if (isDaylightTime) out.add(_encodeBool(6, true));
    if (alwaysTranslate) out.add(_encodeBool(7, true));
    return out.toBytes();
  }

  /// x-bili-device-bin：bilibili.metadata.device.Device（字段号与逆向模块一致）。
  Uint8List _encodeDevice() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final out = BytesBuilder(copy: false)
      ..add(_encodeInt64(1, 1))
      ..add(_encodeInt64(2, 8060000));
    if (_buvid.isNotEmpty) {
      out.add(_encodeString(3, _buvid));
    }
    out
      ..add(_encodeString(4, 'android'))
      ..add(_encodeString(5, 'android'))
      ..add(_encodeString(6, 'phone'))
      ..add(_encodeString(7, 'yingyongbao'))
      ..add(_encodeString(8, 'Xiaomi'))
      ..add(_encodeString(9, 'MI 11'))
      ..add(_encodeString(10, 'Android 12'))
      ..add(_encodeString(13, '8.6.0'))
      ..add(_encodeInt64(15, now));
    return out.toBytes();
  }

  /// x-bili-metadata-bin：bilibili.metadata.Metadata（注意：不是 Device!）
  /// 1 accessKey 2 mobiApp 3 device 4 build 5 channel 6 buvid 7 platform
  Uint8List _encodeMetadata() {
    final out = BytesBuilder(copy: false)
      ..add(_encodeString(2, 'android'))
      ..add(_encodeString(3, 'phone'))
      ..add(_encodeInt64(4, 8060000))
      ..add(_encodeString(5, 'yingyongbao'));
    if (_buvid.isNotEmpty) out.add(_encodeString(6, _buvid));
    out.add(_encodeString(7, 'android'));
    return out.toBytes();
  }

  /// 系统语言 (s_locale)：解析 Platform.localeName（如 zh_CN / en_US）。
  static (String, String) _systemLocale() {
    try {
      final parts = Platform.localeName.split(RegExp(r'[_-]'));
      final lang = parts.isNotEmpty ? parts.first : '';
      final region = parts.length > 1 ? parts[1].toUpperCase() : '';
      return (lang, region);
    } catch (_) {
      return ('', '');
    }
  }

  /// 将 Duration 偏移格式化为 +08:00 / -05:00。
  static String _formatUtcOffset(Duration offset) {
    final minutes = offset.inMinutes;
    final sign = minutes >= 0 ? '+' : '-';
    final abs = minutes.abs();
    final h = (abs ~/ 60).toString().padLeft(2, '0');
    final m = (abs % 60).toString().padLeft(2, '0');
    return '$sign$h:$m';
  }

  /// 粗估标准时区偏移（忽略 DST），用于判断 is_daylight_time。
  static Duration _standardOffsetFor(DateTime dt) {
    final jan = DateTime(dt.year, 1, 1);
    return jan.timeZoneOffset;
  }

  static String _genBuvid() {
    final r = Random();
    String hex(int n) =>
        List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    final uuid =
        '${hex(8)}-${hex(4)}-4${hex(3)}-'
        '${'89ab'[r.nextInt(4)]}${hex(3)}-${hex(12)}'.toUpperCase();
    return '$uuid${r.nextInt(100000).toString().padLeft(5, '0')}infoc';
  }
}