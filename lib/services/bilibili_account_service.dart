                                             
  
                               
                                                   
                                            
                        
                                                   
                                                           
                                               
                            
                                                       
                                               
                                                     
                                              
                                          
                       
import 'package:naviflash/utils/json_decode.dart';
import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/l10n_helper.dart';

             
enum BiliQrStatus {
  notScanned,               
  scanned,                 
  expired,                 
  success,        
  failed,               
}

                                        
class BiliQrInfo {
  final String url;
  final String key;

  const BiliQrInfo({required this.url, required this.key});
}

           
typedef BiliNavInfo = ({String uname, int mid, String face});

           
                                                        
                               
typedef BiliPwdLoginResult = ({
  bool success,
  String message,
  bool needGeetest,
  String? gt,
  String? challenge,
  String? recaptchaToken,
});

              
                                                        
                                 
typedef BiliSmsSendResult = ({
  bool success,
  String message,
  bool needGeetest,
  String? gt,
  String? challenge,
  String? recaptchaToken,
});

              
typedef BiliSmsLoginResult = ({bool success, String message});

                                          
                                        
enum BiliCookieScope {
  video,                        
  comments,         
  search,             
  article,         
  userSpace,        
  season,           
  interactions,                                  
}

                                    
                                                
class BiliStoredAccount {
  final int mid;
  final String uname;
  final String avatarUrl;

                                                     
  final String rawCookie;

  const BiliStoredAccount({
    required this.mid,
    required this.uname,
    required this.avatarUrl,
    required this.rawCookie,
  });

  BiliStoredAccount copyWith({
    int? mid,
    String? uname,
    String? avatarUrl,
    String? rawCookie,
  }) =>
      BiliStoredAccount(
        mid: mid ?? this.mid,
        uname: uname ?? this.uname,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        rawCookie: rawCookie ?? this.rawCookie,
      );

  Map<String, dynamic> toJson() => {
        'mid': mid,
        'uname': uname,
        'avatarUrl': avatarUrl,
        'rawCookie': rawCookie,
      };

  static BiliStoredAccount fromJson(Map<String, dynamic> json) =>
      BiliStoredAccount(
        mid: _readMid(json['mid']),
        uname: (json['uname'] as String?) ?? '',
        avatarUrl: (json['avatarUrl'] as String?) ?? '',
        rawCookie: (json['rawCookie'] as String?) ?? '',
      );

  static int _readMid(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      other is BiliStoredAccount &&
      other.mid == mid &&
      other.uname == uname &&
      other.avatarUrl == avatarUrl &&
      other.rawCookie == rawCookie;

  @override
  int get hashCode => Object.hash(mid, uname, avatarUrl, rawCookie);

  @override
  String toString() => 'BiliStoredAccount($mid, $uname)';
}

class BilibiliAccountService extends ChangeNotifier {
  static BilibiliAccountService? _instance;

  static BilibiliAccountService get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError('BilibiliAccountService 尚未初始化');
    }
    return inst;
  }

  static const String _prefsCookie = 'biliAccountCookie';
  static const String _prefsCarry = 'biliAccountCarryCookie';
  static const String _prefsCookieScopes = 'biliAccountCookieScopes';
  static const String _prefsAvatar = 'biliAccountAvatar';
  static const String _prefsUname = 'biliAccountUname';
  static const String _prefsMid = 'biliAccountMid';

                                                              
                                    
  static const String _prefsAccounts = 'biliAccountList';

                                                            
                                                       
                                                                  
  static const String _qrcodeGenApi =
      'https://passport.bilibili.com/x/passport-tv-login/qrcode/auth_code';
  static const String _qrcodePollApi =
      'https://passport.bilibili.com/x/passport-tv-login/qrcode/poll';
  static const String _appKey = 'dfca71928277209b';
  static const String _appSec = 'b5475a8825547a4fc26c7d518eaaa02e';
  static const String _navApi = 'https://api.bilibili.com/x/web-interface/nav';
  static const String _spiApi = 'https://api.bilibili.com/x/frontend/finger/spi';
  static const String _webKeyApi =
      'https://passport.bilibili.com/x/passport-login/web/key';
  static const String _webLoginApi =
      'https://passport.bilibili.com/x/passport-login/web/login';
  static const String _webCaptchaApi =
      'https://passport.bilibili.com/x/passport-login/captcha?source=main_web';
  static const String _webSmsSendApi =
      'https://passport.bilibili.com/x/passport-login/web/sms/send';
  static const String _webSmsConfirmApi =
      'https://passport.bilibili.com/x/passport-login/web/sms/confirm';

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  static Map<String, String> get _apiHeaders => {
        ..._defaultHeaders,
        ...NetworkSettingsService.instance.apiHeaders,
      };

                                        
  Map<String, String> get _passportApiHeaders => {
        ..._apiHeaders,
        'Referer': 'https://passport.bilibili.com/',
      };

                                                     
  static const Set<String> _keepCookies = {
    'SESSDATA',
    'bili_jct',
    'DedeUserID',
    'DedeUserID__ckMd5',
    'sid',
    'buvid3',
    'buvid4',
    'b_nut',
    'b_lsid',
    'b_lsid2',
    'bili_ticket',
    'bili_ticket_expires',
    'fingerprint',
    'fingerprint3',
    'fingerprint_s',
  };

  String _rawCookie = '';
  bool _carryCookie = false;
  Set<BiliCookieScope> _cookieScopes = {...BiliCookieScope.values};
  String _uname = '';
  int _mid = 0;
  String _avatarUrl = '';                           

                                    
                                                             
  List<BiliStoredAccount> _accounts = const [];
  int _activeIndex = -1;

                                               
  List<BiliStoredAccount> get accounts => List.unmodifiable(_accounts);

                       
  int get activeIndex => _activeIndex;

                         
  BiliStoredAccount? get activeAccount =>
      (_activeIndex >= 0 && _activeIndex < _accounts.length)
          ? _accounts[_activeIndex]
          : null;

             
  int get accountCount => _accounts.length;

                                       
                                                    
                                               
  String _buvid3 = '';
  String _buvid4 = '';

                                      
  String get rawCookie => _rawCookie;

                                     
  bool get carryCookie => _carryCookie;
  String get uname => _uname;
  int get mid => _mid;
  String get avatarUrl => _avatarUrl;
  bool get isLoggedIn => _rawCookie.isNotEmpty;

                                          
  bool isCookieScopeSet(BiliCookieScope scope) => _cookieScopes.contains(scope);

                                                 
  bool isCookieScopeEnabled(BiliCookieScope scope) =>
      isLoggedIn && _carryCookie && _cookieScopes.contains(scope);

                                             
  Map<String, String>? cookieHeaderFor(BiliCookieScope scope) =>
      isCookieScopeEnabled(scope) ? {'Cookie': _rawCookie} : null;

  Future<void> setCookieScopeEnabled(
    BiliCookieScope scope,
    bool enabled,
  ) async {
    if (enabled == _cookieScopes.contains(scope)) return;
    if (enabled) {
      _cookieScopes.add(scope);
    } else {
      _cookieScopes.remove(scope);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsCookieScopes,
      _cookieScopes.map((s) => s.name).join(','),
    );
    notifyListeners();
  }

  Future<void> setAllCookieScopesEnabled(bool enabled) async {
    _cookieScopes = enabled ? {...BiliCookieScope.values} : {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsCookieScopes,
      _cookieScopes.map((s) => s.name).join(','),
    );
    notifyListeners();
  }

                                          
                                         
                                          

                                                         
                                          
  @visibleForTesting
  static ({List<BiliStoredAccount> accounts, int activeMid}) decodeAccounts(
    String json,
  ) {
    try {
      final root = jsonDecode(json);
      if (root is! Map) return (accounts: const [], activeMid: 0);
      final activeMid = BiliStoredAccount._readMid(root['activeMid']);
      final rawList = root['accounts'];
      if (rawList is! List) return (accounts: const [], activeMid: activeMid);
      final accounts = <BiliStoredAccount>[];
      for (final item in rawList) {
        if (item is! Map) continue;
        try {
          accounts.add(
            BiliStoredAccount.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (_) {
                           
        }
      }
      return (accounts: accounts, activeMid: activeMid);
    } catch (_) {
      return (accounts: const [], activeMid: 0);
    }
  }

                                  
  @visibleForTesting
  static String encodeAccounts(
    List<BiliStoredAccount> accounts,
    int activeMid,
  ) {
    return jsonEncode({
      'activeMid': activeMid,
      'accounts': [for (final a in accounts) a.toJson()],
    });
  }

                                              
                         
  @visibleForTesting
  static int resolveActiveIndex(
    List<BiliStoredAccount> accounts,
    int activeMid,
  ) {
    if (accounts.isEmpty) return -1;
    if (activeMid != 0) {
      final i = accounts.indexWhere((a) => a.mid == activeMid);
      if (i >= 0) return i;
    }
    return 0;
  }

                                             
                                       
                                  
  @visibleForTesting
  static (List<BiliStoredAccount>, int) upsertAccount(
    List<BiliStoredAccount> accounts,
    BiliStoredAccount incoming,
  ) {
    final list = [...accounts];
    if (incoming.mid != 0) {
      final i = list.indexWhere((a) => a.mid == incoming.mid);
      if (i >= 0) {
        list[i] = incoming;
        return (list, i);
      }
    }
    list.add(incoming);
    return (list, list.length - 1);
  }

                                     
                                          
  @visibleForTesting
  static int indexAfterRemoval(int length, int removedIndex) {
    if (length <= 1) return -1;
    final fallback = removedIndex - 1;
    return fallback >= 0 ? fallback : 0;
  }

                                          
  void _applyActiveToLive() {
    final active = activeAccount;
    if (active == null) {
      _rawCookie = '';
      _uname = '';
      _mid = 0;
      _avatarUrl = '';
      return;
    }
    _rawCookie = active.rawCookie;
    _uname = active.uname;
    _mid = active.mid;
    _avatarUrl = active.avatarUrl;
  }

                                             
                                         
  Future<void> _persistAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final active = activeAccount;
    await prefs.setString(
      _prefsAccounts,
      encodeAccounts(_accounts, active?.mid ?? 0),
    );
    if (active != null) {
      await prefs.setString(_prefsCookie, active.rawCookie);
      await prefs.setString(_prefsAvatar, active.avatarUrl);
      await prefs.setString(_prefsUname, active.uname);
      await prefs.setInt(_prefsMid, active.mid);
    } else {
      await prefs.remove(_prefsCookie);
      await prefs.remove(_prefsAvatar);
      await prefs.remove(_prefsUname);
      await prefs.remove(_prefsMid);
    }
  }

  Future<void> initialize() async {
    _instance = this;
    final prefs = await SharedPreferences.getInstance();
    _carryCookie = prefs.getBool(_prefsCarry) ?? false;
    final scopesRaw = prefs.getString(_prefsCookieScopes);
    if (scopesRaw != null && scopesRaw.isNotEmpty) {
      final restored = <BiliCookieScope>{};
      for (final name in scopesRaw.split(',')) {
        for (final scope in BiliCookieScope.values) {
          if (scope.name == name) restored.add(scope);
        }
      }
      _cookieScopes = restored;
    }
                                          
                              
    final accountsJson = prefs.getString(_prefsAccounts);
    final decoded = (accountsJson == null || accountsJson.isEmpty)
        ? (accounts: const <BiliStoredAccount>[], activeMid: 0)
        : decodeAccounts(accountsJson);
    if (decoded.accounts.isNotEmpty) {
      _accounts = decoded.accounts;
      _activeIndex = resolveActiveIndex(decoded.accounts, decoded.activeMid);
    } else {
      final legacyCookie = prefs.getString(_prefsCookie) ?? '';
      if (legacyCookie.isNotEmpty) {
        _accounts = [
          BiliStoredAccount(
            mid: prefs.getInt(_prefsMid) ?? 0,
            uname: prefs.getString(_prefsUname) ?? '',
            avatarUrl: prefs.getString(_prefsAvatar) ?? '',
            rawCookie: legacyCookie,
          ),
        ];
        _activeIndex = 0;
      } else {
        _accounts = const [];
        _activeIndex = -1;
      }
      await _persistAccounts();
    }
    _applyActiveToLive();
                                                      
    notifyListeners();
  }

                                          
                 
                                          

                                  
                                             
                                          
                                                
                       
  Future<({bool ok, String message})> loginWithCookie(String raw) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return (ok: false, message: L10n.current.biliCookieEmpty);
    if (!RegExp(r'(SESSDATA|DedeUserID)\s*=', caseSensitive: false)
        .hasMatch(trimmed)) {
      return (
        ok: false,
        message: L10n.current.biliCookieIncomplete,
      );
    }
    if (!RegExp(r'bili_jct\s*=', caseSensitive: false).hasMatch(trimmed)) {
      return (
        ok: false,
        message: L10n.current.biliCookieMissingJct,
      );
    }
    final nav = await _fetchNav(trimmed);
    if (nav == null) {
      return (ok: false, message: L10n.current.biliCookieInvalid);
    }
    final (list, activeIdx) = upsertAccount(
      _accounts,
      BiliStoredAccount(
        mid: nav.mid,
        uname: nav.uname,
        avatarUrl: nav.face,
        rawCookie: trimmed,
      ),
    );
    _accounts = list;
    _activeIndex = activeIdx;
    _applyActiveToLive();
    _carryCookie = true;
                                    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsCarry, true);
    await _persistAccounts();
    notifyListeners();
    return (ok: true, message: L10n.current.biliLoginSuccess);
  }

                                                 
  Future<BiliNavInfo?> _fetchNav(String cookie) async {
    final client = await NetworkSettingsService.instance.getApiClient();
    try {
      final resp = await client
          .get(
            Uri.parse(_navApi),
            headers: {..._apiHeaders, 'Cookie': cookie},
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null || data['isLogin'] != true) return null;
      return (
        uname: (data['uname'] as String?) ?? '',
        mid: (data['mid'] as num?)?.toInt() ?? 0,
        face: (data['face'] as String?) ?? '',
      );
    } catch (e) {
      debugPrint('[BiliAccount] 校验 Cookie 失败: $e');
      return null;
    }
  }

  Future<void> setCarryCookie(bool value) async {
    if (_carryCookie == value) return;
    _carryCookie = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsCarry, value);
    notifyListeners();
  }

                                      
                                      
                                                
               
  Future<void> logout() async {
    if (_accounts.length > 1) {
      await removeAccount(_activeIndex);
      return;
    }
    _accounts = const [];
    _activeIndex = -1;
    _rawCookie = '';
    _carryCookie = false;
    _cookieScopes = {...BiliCookieScope.values};
    _uname = '';
    _mid = 0;
    _avatarUrl = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsAccounts);
    await prefs.remove(_prefsCookie);
    await prefs.remove(_prefsAvatar);
    await prefs.remove(_prefsUname);
    await prefs.remove(_prefsMid);
    await prefs.remove(_prefsCookieScopes);
    await prefs.setBool(_prefsCarry, false);
    notifyListeners();
  }

                                          
                 
                                          

                                                 
                                                 
                                       
  Future<void> switchAccount(int index) async {
    if (index < 0 || index >= _accounts.length || index == _activeIndex) {
      return;
    }
    _activeIndex = index;
    _applyActiveToLive();
    await _persistAccounts();
    notifyListeners();
  }

                                         
  Future<bool> switchAccountByMid(int mid) async {
    final i = _accounts.indexWhere((a) => a.mid == mid);
    if (i < 0) return false;
    await switchAccount(i);
    return true;
  }

                                   
                                          
                              
  Future<bool> removeAccount(int index) async {
    if (index < 0 || index >= _accounts.length) return false;
    if (_accounts.length == 1) {
      await logout();
      return true;
    }
    final wasActive = index == _activeIndex;
    final lengthBefore = _accounts.length;
    _accounts = [..._accounts]..removeAt(index);
    if (wasActive) {
      _activeIndex = indexAfterRemoval(lengthBefore, index);
    } else if (index < _activeIndex) {
      _activeIndex -= 1;
    }
    if (_activeIndex >= _accounts.length) _activeIndex = _accounts.length - 1;
    _applyActiveToLive();
    await _persistAccounts();
    notifyListeners();
    return false;
  }

                                          
                                        
                                          

                                                    
  Future<void> _ensureBuvid() async {
    if (_buvid3.isNotEmpty) return;
    final client = await NetworkSettingsService.instance.getApiClient();
    try {
      final resp = await client
          .get(Uri.parse(_spiApi), headers: _apiHeaders)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return;
      _buvid3 = (data['b_3'] as String?) ?? '';
      _buvid4 = (data['b_4'] as String?) ?? '';
    } catch (e) {
      debugPrint('[BiliAccount] 获取 buvid 失败: $e');
    }
  }

                                      
  Map<String, String> get _sessionCookieHeader {
    final parts = <String>[];
    if (_buvid3.isNotEmpty) parts.add('buvid3=$_buvid3');
    if (_buvid4.isNotEmpty) parts.add('buvid4=$_buvid4');
    return parts.isEmpty ? const {} : {'Cookie': parts.join('; ')};
  }

                                       
  static Map<String, String> _appSignedParams(
    Map<String, String> params,
  ) {
    final ts = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final all = <String, String>{
      ...params,
      'appkey': _appKey,
      'ts': ts,
    };
    final sortedKeys = all.keys.toList()..sort();
    final query =
        sortedKeys.map((k) => '${Uri.encodeQueryComponent(k)}='
            '${Uri.encodeQueryComponent(all[k] ?? '')}').join('&');
    final sign = md5.convert(utf8.encode('$query$_appSec')).toString();
    return {...all, 'sign': sign};
  }

                                                
  Future<BiliQrInfo?> generateQr() async {
    final client = await NetworkSettingsService.instance.getApiClient();
    try {
      final body = _appSignedParams({
        'local_id': '0',
        'platform': 'android',
        'mobi_app': 'android_hd',
      });
      final resp = await client
          .post(
            Uri.parse(_qrcodeGenApi),
            headers: {
              ..._apiHeaders,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      final url = (data['url'] as String?) ?? '';
      final key = (data['auth_code'] as String?) ?? '';
      if (url.isEmpty || key.isEmpty) return null;
      return BiliQrInfo(url: url, key: key);
    } catch (e) {
      debugPrint('[BiliAccount] 获取二维码失败: $e');
      return null;
    }
  }

                                                    
                                     
  Future<({BiliQrStatus status, String message})> pollQr(String key) async {
    final client = await NetworkSettingsService.instance.getApiClient();
    try {
      final body = _appSignedParams({
        'auth_code': key,
        'local_id': '0',
      });
      final resp = await client
          .post(
            Uri.parse(_qrcodePollApi),
            headers: {
              ..._apiHeaders,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (status: BiliQrStatus.failed,
            message: L10n.current.biliHttpError(resp.statusCode));
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        if (json['code'] == -412) {
          return (
            status: BiliQrStatus.failed,
            message: L10n.current.biliRiskBlocked,
          );
        }
        switch (json['code']) {
          case 86038:
            return (
                status: BiliQrStatus.expired,
                message: L10n.current.biliQrExpired);
          case 86090:
            return (
              status: BiliQrStatus.scanned,
              message: L10n.current.biliQrScanned,
            );
          case 86039:
            return (
                status: BiliQrStatus.notScanned,
                message: L10n.current.biliQrWaiting);
          default:
            return (
              status: BiliQrStatus.failed,
              message:
                  json['message'] as String? ?? L10n.current.biliRequestFailed,
            );
        }
      }
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        return (
            status: BiliQrStatus.failed,
            message: L10n.current.biliResponseNoData);
      }
                                                          
                                                          
      final cookie = _extractCookiesFromCookieInfo(
        (data['cookie_info'] as Map<String, dynamic>?)?['cookies'] as List?,
      );
      if (cookie.isEmpty) {
        return (
          status: BiliQrStatus.failed,
          message: L10n.current.biliQrNoSessionCookie,
        );
      }
      if (!RegExp(r'bili_jct\s*=', caseSensitive: false).hasMatch(cookie)) {
        return (
          status: BiliQrStatus.failed,
          message: L10n.current.biliQrMissingJct,
        );
      }
      final loginResult = await loginWithCookie(cookie);
      return loginResult.ok
          ? (status: BiliQrStatus.success,
              message: L10n.current.biliLoginSuccess)
          : (
              status: BiliQrStatus.failed,
              message: loginResult.message,
            );
    } catch (e) {
      debugPrint('[BiliAccount] 轮询二维码失败: $e');
      return (status: BiliQrStatus.failed,
          message: L10n.current.biliRequestFailed);
    }
  }

                                                              
                  
  static String _extractCookiesFromCookieInfo(List<dynamic>? cookieInfo) {
    if (cookieInfo == null) return '';
    final parts = <String>[];
    for (final item in cookieInfo) {
      if (item is! Map) continue;
      final name = (item['name'] as String?) ?? '';
      final value = (item['value'] as String?) ?? '';
      if (_keepCookies.contains(name) && value.isNotEmpty) {
        parts.add('$name=$value');
      }
    }
    return parts.join('; ');
  }

                                                   
                                                 
                                            
  static String _extractCookies(String setCookieHeader) {
    final parts = <String>[];
    final re = RegExp(r'([A-Za-z0-9_\-]+)\s*=\s*([^;]+)');
    for (final m in re.allMatches(setCookieHeader)) {
      final name = m.group(1);
      final value = m.group(2)?.trim() ?? '';
      if (name != null && _keepCookies.contains(name) && value.isNotEmpty) {
        parts.add('$name=$value');
      }
    }
    return parts.join('; ');
  }

                                                     
                                                                                             
                                                 
  static String _extractCookiesFromUrl(String url) {
    final query = Uri.tryParse(url)?.query;
    if (query == null || query.isEmpty) return '';
    final parts = <String>[];
    for (final item in query.split('&')) {
      final eq = item.indexOf('=');
      if (eq <= 0) continue;
      final name = item.substring(0, eq);
      final value = item.substring(eq + 1);
      if (value.isNotEmpty && _keepCookies.contains(name)) {
        parts.add('$name=$value');
      }
    }
    return parts.join('; ');
  }

                                                           
  static String _mergeCookieStrings(String primary, String fallback) {
    final names = <String>{};
    final parts = <String>[];
    for (final segment in [primary, fallback]) {
      for (final part in segment.split(';')) {
        final trimmed = part.trim();
        if (trimmed.isEmpty) continue;
        final name = trimmed.split('=').first.trim();
        if (names.add(name)) parts.add(trimmed);
      }
    }
    return parts.join('; ');
  }

                                          
                              
                                          

                            
  Future<({String hash, String key})?> _fetchWebKey() async {
    final client = await NetworkSettingsService.instance.getApiClient();
    try {
      final resp = await client
          .get(
            Uri.parse(_webKeyApi),
            headers: {..._apiHeaders, ..._sessionCookieHeader},
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      final hash = (data['hash'] as String?) ?? '';
      final key = (data['key'] as String?) ?? '';
      if (hash.isEmpty || key.isEmpty) return null;
      return (hash: hash, key: key);
    } catch (e) {
      debugPrint('[BiliAccount] 获取登录公钥失败: $e');
      return null;
    }
  }

                   
                                      
                                                          
                                
  Future<BiliPwdLoginResult> loginWithPassword({
    required String username,
    required String password,
    String? geeChallenge,
    String? geeValidate,
    String? geeSeccode,
  }) async {
    await _ensureBuvid();
    final webKey = await _fetchWebKey();
    if (webKey == null) {
      return (
        success: false,
        message: L10n.current.biliWebKeyFailed,
        needGeetest: false,
        gt: null,
        challenge: null,
        recaptchaToken: null,
      );
    }
    String encryptedPassword;
    try {
      final dynamic publicKey = enc.RSAKeyParser().parse(webKey.key);
      encryptedPassword = enc.Encrypter(
        enc.RSA(publicKey: publicKey),
      ).encrypt(webKey.hash + password).base64;
    } catch (e) {
      debugPrint('[BiliAccount] RSA 加密失败: $e');
      return (
        success: false,
        message: L10n.current.biliPwdEncryptFailed,
        needGeetest: false,
        gt: null,
        challenge: null,
        recaptchaToken: null,
      );
    }
    final client = await NetworkSettingsService.instance.getApiClient();
    try {
      final resp = await client
          .post(
            Uri.parse(_webLoginApi),
            headers: {
              ..._apiHeaders,
              ..._sessionCookieHeader,
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'username': username,
              'password': encryptedPassword,
              'keep': 'true',
              if (geeChallenge != null) 'challenge': geeChallenge,
              if (geeValidate != null) 'validate': geeValidate,
              if (geeSeccode != null) 'seccode': geeSeccode,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (
          success: false,
          message: L10n.current.biliHttpError(resp.statusCode),
          needGeetest: false,
          gt: null,
          challenge: null,
          recaptchaToken: null,
        );
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      final code = json['code'] as num?;
      final message =
          (json['message'] as String?) ?? L10n.current.biliUnknownError;
      if (code == 0) {
                                                                
                                                 
        final data = json['data'] as Map<String, dynamic>?;
        final urlCookie = _extractCookiesFromUrl(
          (data?['url'] as String?) ?? '',
        );
        final headerCookie = _extractCookies(
          resp.headers['set-cookie'] ?? '',
        );
        final cookie = _mergeCookieStrings(urlCookie, headerCookie);
        if (cookie.isEmpty) {
          return (
            success: false,
            message: L10n.current.biliNoSessionCookie,
            needGeetest: false,
            gt: null,
            challenge: null,
            recaptchaToken: null,
          );
        }
        final loginResult = await loginWithCookie(cookie);
        return (
          success: loginResult.ok,
          message: loginResult.ok ? L10n.current.biliLoginSuccess : loginResult.message,
          needGeetest: false,
          gt: null,
          challenge: null,
          recaptchaToken: null,
        );
      }
      if (code == -105) {
                    
        final data = json['data'] as Map<String, dynamic>?;
        final captchaUrl =
            (data?['url'] as String?) ?? (data?['recaptcha_url'] as String?);
        if (captchaUrl != null && captchaUrl.isNotEmpty) {
          final uri = Uri.tryParse(captchaUrl);
          if (uri != null) {
            return (
              success: false,
              message: L10n.current.biliNeedGeetest,
              needGeetest: true,
              gt: uri.queryParameters['gee_gt'],
              challenge: uri.queryParameters['gee_challenge'],
              recaptchaToken: uri.queryParameters['recaptcha_token'],
            );
          }
        }
      }
      return (
        success: false,
        message: message,
        needGeetest: false,
        gt: null,
        challenge: null,
        recaptchaToken: null,
      );
    } catch (e) {
      debugPrint('[BiliAccount] 密码登录失败: $e');
      return (
        success: false,
        message: '$e',
        needGeetest: false,
        gt: null,
        challenge: null,
        recaptchaToken: null,
      );
    }
  }

                                          
                                     
                                          

  static BiliSmsSendResult _smsSendFailure(String message) => (
        success: false,
        message: message,
        needGeetest: false,
        gt: null,
        challenge: null,
        recaptchaToken: null,
      );

                                                   
                                
  Future<({String token, String gt, String challenge})?>
      _fetchWebCaptcha() async {
    final client = await NetworkSettingsService.instance.getApiClient();
    try {
      final resp = await client
          .get(Uri.parse(_webCaptchaApi), headers: _passportApiHeaders)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;
      final data = json['data'] as Map<String, dynamic>?;
      final token = (data?['token'] as String?) ?? '';
      if (token.isEmpty) return null;
      final geetest = data?['geetest'] as Map<String, dynamic>?;
      return (
        token: token,
        gt: (geetest?['gt'] as String?) ?? '',
        challenge: (geetest?['challenge'] as String?) ?? '',
      );
    } catch (e) {
      debugPrint('[BiliAccount] 获取登录验证码配置失败: $e');
      return null;
    }
  }

                                              
  BiliSmsSendResult? _smsGeetestFromUrl(String? url, String fallbackToken) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    final gt = uri?.queryParameters['gee_gt'] ?? '';
    final challenge = uri?.queryParameters['gee_challenge'] ?? '';
    if (gt.isEmpty || challenge.isEmpty) return null;
    return (
      success: false,
      message: L10n.current.biliNeedGeetest,
      needGeetest: true,
      gt: gt,
      challenge: challenge,
      recaptchaToken:
          uri?.queryParameters['recaptcha_token'] ?? fallbackToken,
    );
  }

                        
                                          
                                                  
                                      
  Future<BiliSmsSendResult> sendSmsLoginCode({
    required String cid,
    required String tel,
    String? recaptchaToken,
    String? geeChallenge,
    String? geeValidate,
    String? geeSeccode,
  }) async {
    if (tel.isEmpty) {
      return _smsSendFailure('请输入手机号');
    }
    await _ensureBuvid();
    String token = recaptchaToken ?? '';
    if (recaptchaToken == null) {
                                      
      final captcha = await _fetchWebCaptcha();
      if (captcha == null) {
        return _smsSendFailure('获取验证码配置失败，请稍后重试');
      }
      token = captcha.token;
      if (captcha.gt.isNotEmpty && captcha.challenge.isNotEmpty) {
        return (
          success: false,
          message: L10n.current.biliNeedGeetest,
          needGeetest: true,
          gt: captcha.gt,
          challenge: captcha.challenge,
          recaptchaToken: token,
        );
      }
    }
    final client = await NetworkSettingsService.instance.getApiClient();
    try {
      final resp = await client
          .post(
            Uri.parse(_webSmsSendApi),
            headers: {
              ..._passportApiHeaders,
              ..._sessionCookieHeader,
              'Origin': 'https://passport.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'cid': cid,
              'tel': tel,
              'source': 'main_web',
              'token': token,
              'csrf': '',
              if (geeChallenge != null) 'challenge': geeChallenge,
              if (geeValidate != null) 'validate': geeValidate,
              if (geeSeccode != null) 'seccode': geeSeccode,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return _smsSendFailure(L10n.current.biliHttpError(resp.statusCode));
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      final code = json['code'] as num?;
      final message =
          (json['message'] as String?) ?? L10n.current.biliUnknownError;
      final data = json['data'] as Map<String, dynamic>?;
      if (code == 0) {
                                        
        final geetest =
            _smsGeetestFromUrl(data?['recaptcha_url'] as String?, token);
        if (geetest != null) return geetest;
        return (
          success: true,
          message: '验证码已发送',
          needGeetest: false,
          gt: null,
          challenge: null,
          recaptchaToken: null,
        );
      }
      if (code == -105) {
                   
        final geetest = _smsGeetestFromUrl(
          (data?['recaptcha_url'] as String?) ?? (data?['url'] as String?),
          token,
        );
        if (geetest != null) return geetest;
      }
      if (code == -412) {
        return _smsSendFailure(L10n.current.biliRiskBlocked);
      }
      return _smsSendFailure(
          message.isEmpty ? '验证码发送失败，请稍后重试' : message);
    } catch (e) {
      debugPrint('[BiliAccount] 发送短信验证码失败: $e');
      return _smsSendFailure('验证码发送失败：$e');
    }
  }

                        
                                                      
                                        
  Future<BiliSmsLoginResult> loginWithSmsCode({
    required String cid,
    required String tel,
    required String code,
  }) async {
    final client = await NetworkSettingsService.instance.getApiClient();
    try {
      final resp = await client
          .post(
            Uri.parse(_webSmsConfirmApi),
            headers: {
              ..._passportApiHeaders,
              ..._sessionCookieHeader,
              'Origin': 'https://passport.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'cid': cid,
              'tel': tel,
              'code': code,
              'source': 'main_web',
              'csrf': '',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (
          success: false,
          message: L10n.current.biliHttpError(resp.statusCode),
        );
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      final respCode = json['code'] as num?;
      final message =
          (json['message'] as String?) ?? L10n.current.biliUnknownError;
      if (respCode == 0) {
        final data = json['data'] as Map<String, dynamic>?;
        final cookie = _extractCookiesFromCookieInfo(
          (data?['cookie_info'] as Map<String, dynamic>?)?['cookies'] as List?,
        );
        if (cookie.isEmpty) {
          return (success: false, message: L10n.current.biliNoSessionCookie);
        }
        final loginResult = await loginWithCookie(cookie);
        return (
          success: loginResult.ok,
          message: loginResult.ok
              ? L10n.current.biliLoginSuccess
              : loginResult.message,
        );
      }
                                        
      return (success: false, message: message);
    } catch (e) {
      debugPrint('[BiliAccount] 短信验证码登录失败: $e');
      return (success: false, message: '登录失败：$e');
    }
  }
}
