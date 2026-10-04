                                          
  
                                                            
                                                             
                                                     
                                               
                   
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/network_settings_service.dart';

int _toInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim()) ?? 0;
  return 0;
}

Map<String, dynamic>? _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

                                                       
                   
                                                 
                                                     
bool _isSeniorMember(
  Map<String, dynamic> json,
  Map<String, dynamic>? levelInfo,
) {
  for (final m in [json, levelInfo]) {
    if (m == null) continue;
    if (_toInt(m['identity']) == 2) return true;
    if (_toInt(m['is_senior_member']) == 1) return true;
    final senior = _asMap(m['senior']);
    if (senior != null && _toInt(senior['status']) > 0) return true;
  }
  return false;
}

class BiliMineProfile {
  final int mid;
  final String uname;
  final String face;
  final double money;
  final int level;
  final int currentExp;
  final int nextExp;
  final int vipType;
  final int vipStatus;

                                                           
                                          
  final bool isSeniorMember;

  const BiliMineProfile({
    required this.mid,
    required this.uname,
    required this.face,
    required this.money,
    required this.level,
    required this.currentExp,
    required this.nextExp,
    required this.vipType,
    required this.vipStatus,
    this.isSeniorMember = false,
  });

                                                           
  double get expProgress {
    if (level >= 6) return 1;
    if (nextExp <= 0) return 0;
    return (currentExp / nextExp).clamp(0.0, 1.0);
  }

  factory BiliMineProfile.fromJson(Map<String, dynamic> json) {
    final levelInfo = _asMap(json['level_info']) ?? const {};
    final level = _toInt(levelInfo['current_level']);
    final currentExp = _toInt(levelInfo['current_exp']);
    final nextExp = level >= 6
        ? currentExp
        : _toInt(levelInfo['next_exp']);
    return BiliMineProfile(
      mid: _toInt(json['mid']),
      uname: (json['uname'] as String?) ?? '',
      face: (json['face'] as String?) ?? '',
      money: _toDouble(json['money']),
      level: level,
      currentExp: currentExp,
      nextExp: nextExp,
      vipType: _toInt(json['vipType']),
      vipStatus: _toInt(json['vipStatus']),
      isSeniorMember: _isSeniorMember(json, levelInfo),
    );
  }
}

                                         
class BiliMineStat {
  final int following;
  final int follower;
  final int dynamicCount;

  const BiliMineStat({
    required this.following,
    required this.follower,
    required this.dynamicCount,
  });

  factory BiliMineStat.fromJson(Map<String, dynamic> json) {
    return BiliMineStat(
      following: _toInt(json['following']),
      follower: _toInt(json['follower']),
      dynamicCount: _toInt(json['dynamic_count']),
    );
  }
}

abstract final class BilibiliMineService {
  static const String _navApi = 'https://api.bilibili.com/x/web-interface/nav';
  static const String _statApi =
      'https://api.bilibili.com/x/web-interface/nav/stat';

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

                      
  static String? lastErrorDetail;

  static bool get isLoggedIn => BilibiliAccountService.instance.isLoggedIn;

  static Map<String, String> _headers() {
    final raw = BilibiliAccountService.instance.rawCookie;
    return {
      ..._defaultHeaders,
      if (raw.isNotEmpty) 'Cookie': raw,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

                              
  static Future<BiliMineProfile?> fetchProfile() async {
    try {
      if (!isLoggedIn) return null;
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(_navApi), headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        return null;
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint('[Mine] nav code=${json['code']} ${json['message']}');
        return null;
      }
      final data = _asMap(json['data']);
      if (data == null || data['isLogin'] != true) return null;
      lastErrorDetail = null;
      return BiliMineProfile.fromJson(data);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Mine] 拉取用户信息异常: $e');
      return null;
    }
  }

                                         
  static Future<BiliMineStat?> fetchStat() async {
    try {
      if (!isLoggedIn) return null;
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(_statApi), headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        debugPrint('[Mine] stat HTTP ${resp.statusCode}');
        return null;
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        debugPrint('[Mine] stat code=${json['code']} ${json['message']}');
        return null;
      }
      final data = _asMap(json['data']);
      if (data == null) return null;
      return BiliMineStat.fromJson(data);
    } catch (e) {
      debugPrint('[Mine] 拉取用户状态异常: $e');
      return null;
    }
  }
}
