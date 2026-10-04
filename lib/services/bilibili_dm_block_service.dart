                                              
  
                                                   
                                     
                                                                    
                                                                      
                                                      
  
                                 
                                                     
  
                                                      
                                              
                                                                       
                                               
  
                                                      
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bilibili_account_service.dart';
import 'bilibili_api_helpers.dart';
import 'network_settings_service.dart';

                                           
      
                                           

                                                     
class BiliDmFilterRule {
                  
  final int id;

                                             
  final int type;

                                  
  final String filter;

                              
  final String comment;

  const BiliDmFilterRule({
    required this.id,
    required this.type,
    required this.filter,
    this.comment = '',
  });

  factory BiliDmFilterRule.fromJson(Map<String, dynamic> json) {
    return BiliDmFilterRule(
      id: biliToInt(json['id']),
      type: biliToInt(json['type']),
      filter: biliAsStr(json['filter']).trim(),
      comment: biliAsStr(json['comment']).trim(),
    );
  }
}

                     
   
                                                              
                               
class BiliDmBlockItem {
  final String text;

                                  
  final String uidHash;

  const BiliDmBlockItem(this.text, {this.uidHash = ''});
}

                                           
                                 
                                           

                                          
final List<int> _crc32Table = _buildCrc32Table();

List<int> _buildCrc32Table() {
  final table = List<int>.filled(256, 0);
  for (var i = 0; i < 256; i++) {
    var c = i;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    }
    table[i] = c;
  }
  return table;
}

                                           
                                     
String biliDmUidHash(Object uid) {
                                                   
             
  final bytes = utf8.encode(uid.toString());
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc = _crc32Table[(crc ^ b) & 0xFF] ^ (crc >>> 8);
  }
  return ((crc ^ 0xFFFFFFFF) & 0xFFFFFFFF).toRadixString(16);
}

                             
   
                       
                                          
                          
                                                     
               
bool biliDmMatchesRule(BiliDmBlockItem item, BiliDmFilterRule rule) {
  switch (rule.type) {
    case 0:
      final kw = rule.filter;
      return kw.isNotEmpty && item.text.contains(kw);
    case 1:
      final pattern = _stripRegexSlashes(rule.filter);
      if (pattern.isEmpty) return false;
      try {
        return RegExp(pattern, caseSensitive: false).hasMatch(item.text);
      } on FormatException {
        return false;
      } on ArgumentError {
        return false;
      }
    case 2:
      final a = item.uidHash.trim();
      final b = rule.filter.trim().toLowerCase();
      if (a.isEmpty || b.isEmpty) return false;
      final aLower = a.toLowerCase();
      if (aLower == b) return true;
                                   
      final aInt = int.tryParse(aLower, radix: 16);
      final bInt = int.tryParse(b, radix: 16);
      return aInt != null && bInt != null && aInt == bInt;
    default:
      return false;
  }
}

                                              
String _stripRegexSlashes(String filter) {
  final m = RegExp(r'^/(.*)/$').firstMatch(filter.trim());
  return m?.group(1) ?? filter.trim();
}

                                           
      
                                           

abstract final class BilibiliDmBlockService {
  static const String _apiBase = 'https://api.bilibili.com';

  static const String _togglePrefsKey = 'danmaku_dm_block_rules_enabled';

               
  static const Duration cacheTtl = Duration(minutes: 10);

  static List<BiliDmFilterRule>? _cache;
  static DateTime _cacheAt = DateTime.fromMillisecondsSinceEpoch(0);
  static Future<void>? _loading;

                                               
                                              
  static bool _rulesEnabled = true;
  static bool _prefsLoaded = false;

  static bool get rulesEnabled => _rulesEnabled;

                     
  static Future<void> ensureLoaded() {
    if (_prefsLoaded) return Future.value();
    _loading ??= () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        _rulesEnabled = prefs.getBool(_togglePrefsKey) ?? true;
      } catch (e) {
        debugPrint('[DmBlock] 读取云屏蔽词开关失败: $e');
      }
      _prefsLoaded = true;
    }();
    return _loading!;
  }

                     
  static Future<void> setRulesEnabled(bool value) async {
    _rulesEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_togglePrefsKey, value);
    } catch (e) {
      debugPrint('[DmBlock] 保存云屏蔽词开关失败: $e');
    }
  }

                                  
  static bool get canUse => biliLoginCookie(BiliCookieScope.interactions) != null;

                                      
                              
  static Future<List<BiliDmFilterRule>> getRules({bool force = false}) async {
    await ensureLoaded();
    if (!force && _cache != null) {
      final fresh = DateTime.now().difference(_cacheAt) < cacheTtl;
      if (fresh) return _cache!;
    }
    if (!canUse) {
      _cache = const <BiliDmFilterRule>[];
      _cacheAt = DateTime.now();
      return _cache!;
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            Uri.parse('$_apiBase/x/dm/filter/user'),
            headers: {
              if (biliLoginCookie(BiliCookieScope.interactions) != null)
                'Cookie': biliLoginCookie(BiliCookieScope.interactions)!,
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        debugPrint('[DmBlock] 规则列表 HTTP ${resp.statusCode}');
        return _cache ?? const <BiliDmFilterRule>[];
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        debugPrint('[DmBlock] 规则列表返回非 JSON 对象');
        return _cache ?? const <BiliDmFilterRule>[];
      }
      final code = biliToInt(json['code']);
      if (code != 0) {
        debugPrint(
          '[DmBlock] 规则列表接口返回 $code: ${biliAsStr(json['message'])}',
        );
        return _cache ?? const <BiliDmFilterRule>[];
      }
      final data = biliAsMap(json['data']) ?? const <String, dynamic>{};
      final list = biliAsList<Map<String, dynamic>>(data['rule']);
      final rules = <BiliDmFilterRule>[];
      for (final e in list) {
        final rule = BiliDmFilterRule.fromJson(e);
        if (rule.filter.isNotEmpty) rules.add(rule);
      }
      _cache = rules;
      _cacheAt = DateTime.now();
      return rules;
    } catch (e) {
      debugPrint('[DmBlock] 规则列表获取失败: $e');
      return _cache ?? const <BiliDmFilterRule>[];
    }
  }

           
     
                                 
                                                       
                      
  static Future<({bool ok, String message})> addRule({
    required int type,
    required String filter,
  }) async {
    final value = filter.trim();
    if (value.isEmpty) return (ok: false, message: '屏蔽内容不能为空');
    if (!canUse) return (ok: false, message: '还没有登录，登录后才能同步屏蔽词');
    final csrf = biliExtractCsrf(
      biliLoginCookie(BiliCookieScope.interactions) ?? '',
    );
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');

    var out = value;
    String? comment;
    if (type == 2) {
      final uid = int.tryParse(value);
      if (uid == null || uid <= 0) return (ok: false, message: 'UID 必须是正整数');
      out = biliDmUidHash(uid);
      comment = 'UID:$uid';
    }
    return _post('$_apiBase/x/dm/filter/user/add', {
      'type': type.toString(),
      'filter': out,
      if (comment != null) 'comment': comment,
      'csrf': csrf,
      'csrf_token': csrf,
    });
  }

                            
  static Future<({bool ok, String message})> deleteRules(
    List<int> ids,
  ) async {
    if (ids.isEmpty) return (ok: false, message: '未选择要删除的规则');
    if (!canUse) return (ok: false, message: '还没有登录');
    final csrf = biliExtractCsrf(
      biliLoginCookie(BiliCookieScope.interactions) ?? '',
    );
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    return _post('$_apiBase/x/dm/filter/user/del', {
      'ids': ids.join(','),
      'csrf': csrf,
      'csrf_token': csrf,
    });
  }

  static Future<({bool ok, String message})> _post(
    String url,
    Map<String, String> fields,
  ) async {
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(url),
            headers: {
              if (biliLoginCookie(BiliCookieScope.interactions) != null)
                'Cookie': biliLoginCookie(BiliCookieScope.interactions)!,
              ...NetworkSettingsService.instance.apiHeaders,
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: fields,
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return (ok: false, message: '返回内容不是 JSON 对象');
      }
      final code = biliToInt(json['code']);
      if (code != 0) {
        final msg = biliAsStr(json['message'] ?? json['msg']);
        return (ok: false, message: msg.isEmpty ? '接口返回 $code' : msg);
      }
                            
      _cache = null;
      _cacheAt = DateTime.fromMillisecondsSinceEpoch(0);
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[DmBlock] 请求失败: $e');
      return (ok: false, message: '网络异常：${e.runtimeType}');
    }
  }

                                      
                        
  static Future<List<BiliDmFilterRule>> rulesForDanmakuFiltering() async {
    await ensureLoaded();
    if (!_rulesEnabled) return const <BiliDmFilterRule>[];
    final rules = await getRules();
    return rules;
  }

                                    
  static bool isBlocked(BiliDmBlockItem item, [List<BiliDmFilterRule>? rules]) {
    for (final rule in rules ?? _cache ?? const <BiliDmFilterRule>[]) {
      if (biliDmMatchesRule(item, rule)) return true;
    }
    return false;
  }
}
