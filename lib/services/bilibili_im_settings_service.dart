                                                 
  
                                                            
              
  
                                            
                                              
                          
                                             
                                                            
                                                 
                                                           
                                          
                                      
  
                                                               
                                                    
                                                   
                                                                   
                                                          
                                     
  
                                            
                 
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'bilibili_account_service.dart';
import 'network_settings_service.dart';

                                                                   
class BiliMsgNotifyType {
  static const int everyone = 0;
  static const int following = 1;
  static const int none = 2;
}

                             
class BiliMsgSettings {
                            
  final int replyNotify;

                      
  final int atNotify;

                       
  final int likeNotify;

               
  final bool receiveUnfollowMsg;

               
  final bool showUnfollowedMsg;

              
  final bool shouldReceiveGroup;

              
  final bool isGroupFold;

                                              
  final bool aiIntercept;

  const BiliMsgSettings({
    required this.replyNotify,
    required this.atNotify,
    required this.likeNotify,
    required this.receiveUnfollowMsg,
    required this.showUnfollowedMsg,
    required this.shouldReceiveGroup,
    required this.isGroupFold,
    required this.aiIntercept,
  });
}

                                
class BiliMsgDisturb {
              
  final bool isOpen;

                         
  final int selectedId;

                                       
  final List<({int id, String label})> options;

                      
  final String endTime;

  const BiliMsgDisturb({
    required this.isOpen,
    required this.selectedId,
    required this.options,
    required this.endTime,
  });
}

abstract final class BilibiliImSettingsService {
  static const String _vcBase = 'https://api.vc.bilibili.com';

                                        
  static const BiliCookieScope _scope = BiliCookieScope.interactions;

                                             
  static bool get canUse {
    try {
      return BilibiliAccountService.instance.cookieHeaderFor(_scope) != null;
    } catch (_) {
      return false;
    }
  }

  static Map<String, String> _headers() {
    final cookie = BilibiliAccountService.instance
        .cookieHeaderFor(_scope)?['Cookie'];
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': 'https://message.bilibili.com/',
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  static String _csrf() {
    final raw = BilibiliAccountService.instance.rawCookie;
    return RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(raw)?.group(1) ??
        '';
  }

  static int _toInt(dynamic v, [int fallback = 0]) => switch (v) {
        int i => i,
        num n => n.toInt(),
        String s => int.tryParse(s) ?? fallback,
        bool b => b ? 1 : 0,
        _ => fallback,
      };

  static bool _toBool(dynamic v) => switch (v) {
        bool b => b,
        int i => i != 0,
        String s => s == '1' || s.toLowerCase() == 'true',
        _ => false,
      };

                                               
  static Future<BiliMsgSettings?> fetchSettings() async {
    if (!canUse) return null;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            Uri.parse(
              '$_vcBase/link_setting/v1/link_setting/get',
            ).replace(
              queryParameters: {
                'msg_notify': '1',
                'show_unfollowed_msg': '1',
                'build': '0',
                'mobi_app': 'web',
              },
            ),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map || json['code'] != 0) return null;
      final data = json['data'];
      if (data is! Map) return null;
      return BiliMsgSettings(
        replyNotify: _toInt(data['set_comment']),
        atNotify: _toInt(data['set_at']),
        likeNotify: _toInt(data['set_like']),
        receiveUnfollowMsg: _toBool(data['receive_unfollow_msg']),
        showUnfollowedMsg: _toBool(data['show_unfollowed_msg']),
        shouldReceiveGroup: _toBool(data['should_receive_group']),
        isGroupFold: _toBool(data['is_group_fold']),
        aiIntercept: _toBool(data['ai_intercept']),
      );
    } catch (e) {
      debugPrint('[ImSettings] link_setting/get 异常: $e');
      return null;
    }
  }

                                                   
                         
  static Future<String?> saveSettings(Map<String, Object?> fields) async {
    if (!canUse) return '未登录或网络异常';
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse('$_vcBase/link_setting/v1/link_setting/set'),
            headers: _headers(),
            body: {
              ...fields.map((k, v) => MapEntry(k, '$v')),
              'build': '0',
              'mobi_app': 'web',
              'csrf_token': _csrf(),
              'csrf': _csrf(),
            },
          )
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is Map && json['code'] == 0) return null;
      final msg = json is Map ? '${json['message'] ?? json['msg']}' : '$json';
      debugPrint('[ImSettings] link_setting/set 失败: $msg');
      return msg;
    } catch (e) {
      debugPrint('[ImSettings] link_setting/set 异常: $e');
      return '$e';
    }
  }

                                                       
                      
  static Future<BiliMsgDisturb?> fetchDisturb() async {
    if (!canUse) return null;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            Uri.parse('$_vcBase/x/im/anti_disturb/get_disturb').replace(
              queryParameters: {'scene': '2'},
            ),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map || json['code'] != 0) return null;
      final data = json['data'];
      if (data is! Map) return null;
      final options = <({int id, String label})>[];
      final rawOptions = data['options'];
      if (rawOptions is List) {
        for (final o in rawOptions.whereType<Map>()) {
          final id = _toInt(o['id'], -1);
          if (id < 0) continue;
          final label = '${o['name'] ?? o['text'] ?? o['label'] ?? ''}';
          options.add((id: id, label: label));
        }
      }
      return BiliMsgDisturb(
        isOpen: _toBool(data['is_open']),
        selectedId: _toInt(data['selected_id']),
        options: options,
        endTime: '${data['end_time'] ?? ''}',
      );
    } catch (e) {
      debugPrint('[ImSettings] get_disturb 异常: $e');
      return null;
    }
  }

                                                
                         
  static Future<String?> saveDisturb({
    required int id,
    required bool isOpen,
  }) async {
    if (!canUse) return '未登录或网络异常';
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse('$_vcBase/x/im/anti_disturb/set_disturb'),
            headers: _headers(),
            body: {
              'id': '$id',
              'is_open': isOpen ? '1' : '0',
            },
          )
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is Map && json['code'] == 0) return null;
      final msg = json is Map ? '${json['message'] ?? json['msg']}' : '$json';
      debugPrint('[ImSettings] set_disturb 失败: $msg');
      return msg;
    } catch (e) {
      debugPrint('[ImSettings] set_disturb 异常: $e');
      return '$e';
    }
  }
}
