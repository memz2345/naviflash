                                               
  
                                                                
                                    
                                                                    
                                                     
                                                      
                                                     
                                                    
                                                    
                                
  
                                                  
                                               
                                                   
                                           
import 'package:naviflash/utils/json_decode.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/utils/recommend_filter.dart';

                                           
      
                                           

                                                
class BiliBlackUser {
  final int mid;
  final String uname;
  final String face;

               
  final String sign;

                                      
  final int mtime;

  const BiliBlackUser({
    required this.mid,
    required this.uname,
    required this.face,
    required this.sign,
    required this.mtime,
  });

  factory BiliBlackUser.fromJson(Map<String, dynamic> json) => BiliBlackUser(
    mid: biliToInt(json['mid']),
    uname: biliAsStr(json['uname']),
    face: biliNormalizeUrl(biliAsStr(json['face'])),
    sign: biliAsStr(json['sign']),
    mtime: biliToInt(json['mtime']),
  );
}

                                           
      
                                           

                                          
class BilibiliBlacklistService extends ChangeNotifier {
  BilibiliBlacklistService._();

  static final BilibiliBlacklistService instance = BilibiliBlacklistService._();

  static const String _apiBase = 'https://api.bilibili.com';

                                                      
  static const String _cachePrefKey = 'biliBlacklistCache';

                            
  static const String _filterPrefKey = 'biliBlacklistFilterRecommend';

                                                
  static const Duration cacheTtl = Duration(hours: 24);

                                            
  static const int _maxCachePages = 40;

  static const int _pageSize = 50;

  bool _initialized = false;

                                
  Set<int> _mids = const <int>{};

                             
  int _cacheSavedAtMs = 0;

                      
  bool _filterRecommend = false;

                         
  Future<void>? _refreshing;

  bool get isInitialized => _initialized;

                              

                     
  Set<int> get mids => Set<int>.unmodifiable(_mids);

           
  int get cachedCount => _mids.length;

                      
  bool get isFilterRecommend => _filterRecommend;

                                        
  bool isBlacklisted(int mid) => _mids.contains(mid);

                 
  bool get isCacheFresh =>
      _cacheSavedAtMs > 0 &&
      DateTime.now().millisecondsSinceEpoch - _cacheSavedAtMs <
          cacheTtl.inMilliseconds;

                              
                                     
  bool get canUse {
    try {
      return BilibiliAccountService.instance.isLoggedIn;
    } catch (_) {
      return false;
    }
  }

                                     

                                                          
     
                                   
  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachePrefKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final list = decoded['mids'];
          _mids = list is List
              ? list.map(biliToInt).where((m) => m > 0).toSet()
              : const <int>{};
          _cacheSavedAtMs = biliToInt(decoded['savedAt']);
        }
      }
      _filterRecommend = prefs.getBool(_filterPrefKey) ?? false;
    } catch (e) {
      debugPrint('[Blacklist] 读取本地缓存失败: $e');
    }
    _syncFilter();
    if (!isCacheFresh && canUse) {
                              
      unawaited(refreshCache());
    }
  }

                                        
  Future<void> ensureLoaded() => initialize();

                                                     
  Future<void> refreshCache() {
    return _refreshing ??= _refreshCacheLocked().whenComplete(() {
      _refreshing = null;
    });
  }

  Future<void> _refreshCacheLocked() async {
    try {
      final mids = <int>{};
      for (var pn = 1; pn <= _maxCachePages; pn++) {
        final page = await fetchPage(pn: pn, ps: _pageSize);
        if (page.err != null) {
                                    
          debugPrint('[Blacklist] 缓存重建失败: ${page.err}');
          return;
        }
        mids.addAll(page.users.map((u) => u.mid));
        if (mids.length >= page.total || page.users.isEmpty) break;
      }
      _mids = mids;
      _cacheSavedAtMs = DateTime.now().millisecondsSinceEpoch;
      await _persistCache();
      _syncFilter();
    } catch (e) {
      debugPrint('[Blacklist] 缓存重建异常: $e');
    }
  }

  Future<void> _persistCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cachePrefKey,
        jsonEncode(<String, Object?>{
          'mids': _mids.toList(),
          'savedAt': _cacheSavedAtMs,
        }),
      );
    } catch (e) {
      debugPrint('[Blacklist] 写入本地缓存失败: $e');
    }
  }

                                                      
  void _syncFilter() {
    RecommendFilter.setBlacklist(enabled: _filterRecommend, mids: _mids);
  }

                              

                      
  Future<void> setFilterRecommend(bool value) async {
    if (_filterRecommend == value) return;
    _filterRecommend = value;
    _syncFilter();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_filterPrefKey, value);
    } catch (e) {
      debugPrint('[Blacklist] 写入过滤开关失败: $e');
    }
  }

                                                          
                                  
  Future<({bool ok, String message})> unblock(int mid) async {
    if (!canUse) return (ok: false, message: '还没有登录，登录后才能操作');
    final csrf = biliExtractCsrf(
      BilibiliAccountService.instance.cookieHeaderFor(
            BiliCookieScope.interactions,
          )?['Cookie'] ??
          '',
    );
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse('$_apiBase/x/relation/modify'),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Referer': 'https://space.bilibili.com/$mid',
              'Origin': 'https://space.bilibili.com',
              'Cookie':
                  BilibiliAccountService.instance.cookieHeaderFor(
                    BiliCookieScope.interactions,
                  )?['Cookie'] ??
                  '',
              'Content-Type': 'application/x-www-form-urlencoded',
              ...NetworkSettingsService.instance.apiHeaders,
            },
            body: {'fid': mid.toString(), 'act': '6', 're_src': '11', 'csrf': csrf},
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
                                     
      if (_mids.remove(mid)) {
        await _persistCache();
        _syncFilter();
        notifyListeners();
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[Blacklist] 取消拉黑失败: $e');
      return (ok: false, message: '网络异常：${e.runtimeType}');
    }
  }

                               

                                                       
  Future<({List<BiliBlackUser> users, int total, String? err})> fetchPage({
    required int pn,
    int ps = _pageSize,
  }) async {
    if (!canUse) {
      return (users: const <BiliBlackUser>[], total: 0, err: '还没有登录，登录后才能查看黑名单');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final uri = Uri.parse('$_apiBase/x/relation/blacks').replace(
        queryParameters: {'pn': pn.toString(), 'ps': ps.clamp(1, 50).toString()},
      );
      final resp = await client
          .get(
            uri,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Referer': 'https://www.bilibili.com',
              'Cookie':
                  BilibiliAccountService.instance.cookieHeaderFor(
                    BiliCookieScope.userSpace,
                  )?['Cookie'] ??
                  '',
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (users: const <BiliBlackUser>[], total: 0, err: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return (users: const <BiliBlackUser>[], total: 0, err: '返回内容不是 JSON 对象');
      }
      final code = biliToInt(json['code']);
      if (code != 0) {
        final msg = biliAsStr(json['message'] ?? json['msg']);
        return (
          users: const <BiliBlackUser>[],
          total: 0,
          err: msg.isEmpty ? '接口返回 $code' : msg,
        );
      }
      final data = biliAsMap(json['data']) ?? const <String, dynamic>{};
      final total = biliToInt(data['total']);
      final users = biliAsList<Map<String, dynamic>>(data['list'])
          .map(BiliBlackUser.fromJson)
          .where((u) => u.mid > 0)
          .toList();
      return (users: users, total: total, err: null);
    } catch (e) {
      debugPrint('[Blacklist] 列表获取失败: $e');
      return (users: const <BiliBlackUser>[], total: 0, err: '网络异常：${e.runtimeType}');
    }
  }

  @visibleForTesting
  Future<void> debugReset() async {
    _initialized = false;
    _mids = const <int>{};
    _cacheSavedAtMs = 0;
    _filterRecommend = false;
    _syncFilter();
  }
}
