                                                 
  
                                             
                                                              
                                                              
                                                                 
                                                                       
                                                                
                                                                       
                                                                  
                                                                    
                                        
                                                                                
                                                              
                                                                 
                                             
               
                                         
                                                      
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/network_settings_service.dart';

                                           
      
                                           

                                       
class BiliCoinExpLogEntry {
                                           
  final String time;

                                         
  final int delta;

                                
  final String reason;

  const BiliCoinExpLogEntry({
    required this.time,
    required this.delta,
    required this.reason,
  });
}

                                   
class BiliLoginLogEntry {
  final String ip;

                                           
  final String timeAt;

                                    
  final int time;

                
  final String geo;

                 
  final String type;

                   
  final String status;

  const BiliLoginLogEntry({
    required this.ip,
    required this.timeAt,
    required this.time,
    required this.geo,
    required this.type,
    required this.status,
  });
}

                                            
class BiliLoginDeviceEntry {
  final String deviceName;
  final bool isCurrentDevice;
  final String latestLoginAt;
  final String source;

  const BiliLoginDeviceEntry({
    required this.deviceName,
    required this.isCurrentDevice,
    required this.latestLoginAt,
    required this.source,
  });
}

                                           
      
                                           

abstract final class BilibiliAccountLogService {
  static const String _apiBase = 'https://api.bilibili.com';
  static const String _passportBase = 'https://passport.bilibili.com';

  static const Map<String, String> _webHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  static String get _rawCookie => BilibiliAccountService.instance.rawCookie;

  static bool get isLoggedIn => BilibiliAccountService.instance.isLoggedIn;

  static Map<String, String> _headers({bool passport = false}) {
    final cookie = _rawCookie;
    return {
      ..._webHeaders,
      if (passport) 'Referer': '$_passportBase/',
      if (cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  static String _csrf() => biliExtractCsrf(_rawCookie);

                                  
  static int _deltaOf(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  static List<BiliCoinExpLogEntry> _parseCoinExpList(dynamic list) {
    final items = <BiliCoinExpLogEntry>[];
    for (final e in biliAsList<Map<String, dynamic>>(list)) {
      items.add(
        BiliCoinExpLogEntry(
          time: biliAsStr(e['time']),
          delta: _deltaOf(e['delta']),
          reason: biliAsStr(e['reason']),
        ),
      );
    }
    return items;
  }

                                
  static Future<({List<BiliCoinExpLogEntry> items, String? err})>
  fetchCoinLog() async {
    return _fetchLog(
      '$_apiBase/x/member/web/coin/log',
      tag: '[AccountLog] 硬币记录',
      notLoggedIn: '还没有登录，登录后才能查看硬币记录',
      parse: _parseCoinExpList,
    );
  }

                 
  static Future<({List<BiliCoinExpLogEntry> items, String? err})>
  fetchExpLog() async {
    return _fetchLog(
      '$_apiBase/x/member/web/exp/log',
      tag: '[AccountLog] 经验记录',
      notLoggedIn: '还没有登录，登录后才能查看经验记录',
      parse: _parseCoinExpList,
    );
  }

                 
  static Future<({List<BiliLoginLogEntry> items, String? err})>
  fetchLoginLog() async {
    return _fetchLog(
      '$_apiBase/x/member/web/login/log',
      tag: '[AccountLog] 登录记录',
      notLoggedIn: '还没有登录，登录后才能查看登录记录',
      parse: (list) {
        final items = <BiliLoginLogEntry>[];
        for (final e in biliAsList<Map<String, dynamic>>(list)) {
          items.add(
            BiliLoginLogEntry(
              ip: biliAsStr(e['ip']),
              timeAt: biliAsStr(e['time_at']),
              time: biliToInt(e['time']),
              geo: biliAsStr(e['geo']),
              type: biliAsStr(e['type']),
              status: biliAsStr(e['status']),
            ),
          );
        }
        return items;
      },
    );
  }

                                                 
  static Future<({List<BiliLoginDeviceEntry> items, String? err})>
  fetchLoginDevices() async {
    if (!isLoggedIn) {
      return (items: const <BiliLoginDeviceEntry>[], err: '还没有登录，登录后才能查看登录设备');
    }
    final csrf = _csrf();
    if (csrf.isEmpty) {
      return (items: const <BiliLoginDeviceEntry>[], err: '缺少 bili_jct，请重新登录');
    }
    final url =
        '$_passportBase/x/safecenter/user_login_devices'
        '?csrf=${Uri.encodeQueryComponent(csrf)}';
    return _fetchLog(
      url,
      tag: '[AccountLog] 登录设备',
      notLoggedIn: '还没有登录，登录后才能查看登录设备',
      passport: true,
      parse: (list) {
        final items = <BiliLoginDeviceEntry>[];
        for (final e in biliAsList<Map<String, dynamic>>(list)) {
          items.add(
            BiliLoginDeviceEntry(
              deviceName: biliAsStr(e['device_name']),
              isCurrentDevice: e['is_current_device'] == true,
              latestLoginAt: biliAsStr(e['latest_login_at']),
              source: biliAsStr(e['source']),
            ),
          );
        }
        return items;
      },
    );
  }

                                                    
  static Future<({List<T> items, String? err})> _fetchLog<T>(
    String url, {
    required String tag,
    required String notLoggedIn,
    required List<T> Function(dynamic list) parse,
    bool passport = false,
  }) async {
    if (!isLoggedIn) {
      return (items: <T>[], err: notLoggedIn);
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(url), headers: _headers(passport: passport))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (items: <T>[], err: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return (items: <T>[], err: '返回内容不是 JSON 对象');
      }
      final code = biliToInt(json['code']);
      if (code != 0) {
        final msg = biliAsStr(json['message'] ?? json['msg']);
        return (items: <T>[], err: msg.isEmpty ? '接口返回 $code' : msg);
      }
      final data = biliAsMap(json['data']) ?? const <String, dynamic>{};
      return (items: parse(data['list'] ?? data['devices']), err: null);
    } catch (e) {
      debugPrint('$tag 获取失败: $e');
      return (items: <T>[], err: '网络异常：${e.runtimeType}');
    }
  }
}
