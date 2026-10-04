                                               
  
                         
  
                                                          
                                                            
                                                                       
  
         
                           
                                                          
                                                             
                                     
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

                    
class BiliTranslateLanguage {
                                                        
  final String code;

                                    
  final String language;

                                             
  final String script;

                                  
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

                            
class BilibiliTranslateService extends ChangeNotifier {
  static BilibiliTranslateService? _instance;

                           
  static BilibiliTranslateService get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError('BilibiliTranslateService 尚未初始化');
    }
    return inst;
  }

                                  
  static Map<String, String> get activeHeaders {
    final inst = _instance;
    if (inst == null) return const {};
    return inst.requestHeaders;
  }

                                 
     
                                         
                                                    
                                    
  static bool get enabledOrFalse => _instance?._enabled ?? false;

                                   
  static const List<String> translateHeaderKeys = [
    'x-bili-locale-bin',
    'x-bili-metadata-bin',
    'x-bili-device-bin',
    'buvid',
  ];

                                   
     
                                              
                                              
                          
  static BiliTranslateLanguage? displayLanguageFor(String? appLocaleCode) {
    var code = appLocaleCode ?? _platformLocaleCode();
    if (code.isEmpty) return null;
                                                   
    code = code.toLowerCase().replaceAll('_', '-');
                                                     
    final map = <String, String>{
      'zh': 'zh-cn',
      'en': 'en-us',
      'ja': 'ja-jp',
      'ko': 'ko-kr',
    };
    code = map[code] ?? code;
    for (final lang in BiliTranslateLanguage.values) {
      if (lang.code.toLowerCase() == code) return lang;
    }
    return null;
  }

                                  
  static String _platformLocaleCode() {
    try {
      return Platform.localeName;
    } catch (_) {
      return '';
    }
  }

                                   
     
                                                        
                                             
                                     
                     
     
                                        
  Map<String, String> headersForDisplayLocale(String? appLocaleCode) {
    final lang = displayLanguageFor(appLocaleCode);
    if (lang == null) return const {};
    final sys = _systemLocale();
    final now = DateTime.now();
    final locale = _encodeLocale(
      lang,
      sLanguage: sys.$1,
      sRegion: sys.$2,
      utcOffset: _formatUtcOffset(now.timeZoneOffset),
      isDaylightTime: now.timeZoneOffset != _standardOffsetFor(now),
      alwaysTranslate: false,
    );
    return {
      'x-bili-locale-bin': _b64(locale),
      'x-bili-metadata-bin': _metadataBinB64,
      'x-bili-device-bin': _deviceBinB64,
      'buvid': _buvid,
    };
  }

  bool _enabled = false;
  BiliTranslateLanguage _language = BiliTranslateLanguage.values.first;

                               
  late final String _buvid = _genBuvid();

                                                        
                                                  
                                                              
                       
  late final String _deviceBinB64 = _b64(_encodeDevice());
  late final String _metadataBinB64 = _b64(_encodeMetadata());


  bool get enabled => _enabled;

  BiliTranslateLanguage get language => _language;

                                  
                                                          
                                                                 
                                                                              
                                                                             
                                        
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

                                        
  static String _formatUtcOffset(Duration offset) {
    final minutes = offset.inMinutes;
    final sign = minutes >= 0 ? '+' : '-';
    final abs = minutes.abs();
    final h = (abs ~/ 60).toString().padLeft(2, '0');
    final m = (abs % 60).toString().padLeft(2, '0');
    return '$sign$h:$m';
  }

                                             
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