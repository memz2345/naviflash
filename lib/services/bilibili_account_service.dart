// lib/services/bilibili_account_service.dart
//
// 单账号 Cookie 模式）：
//   - 登录方式：① QR 扫码（passport-login qrcode 生成 + 轮询，成功时从
//     Set-Cookie 提取会话 Cookie） ② 手动粘贴浏览器 Cookie
//   - Cookie 持久化到本地；用户可通过「携带 Cookie 请求」开关自由决定是否
//     把 Cookie 附加到 B 站 API 请求——登录后评论/剧集等接口返回值更完整，
//     也避免部分接口的风控限制（-352 等）。
import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/l10n_helper.dart';

/// 扫码登录轮询状态。
enum BiliQrStatus {
  notScanned, // 等待扫码（86039）
  scanned, // 已扫码待确认（86090）
  expired, // 二维码已失效（86038）
  success, // 登录成功
  failed, // 请求失败 / 网络异常
}

/// 二维码信息（生成接口返回的登录链接 + 轮询凭证 auth_code）。
class BiliQrInfo {
  final String url;
  final String key;

  const BiliQrInfo({required this.url, required this.key});
}

/// 登录校验结果。
typedef BiliNavInfo = ({String uname, int mid, String face});

/// 密码登录结果。
/// [needGeetest] 为 true 时需弹出极验滑块验证码，用 [gt]/[challenge]/
/// [recaptchaToken] 验证后携带结果重试。
typedef BiliPwdLoginResult = ({
  bool success,
  String message,
  bool needGeetest,
  String? gt,
  String? challenge,
  String? recaptchaToken,
});

/// Cookie 使用范围：允许用户按请求类型控制账号 Cookie 是否附加。
/// 与「携带 Cookie 请求」总开关叠加生效（总开关关闭时全部不携带）。
enum BiliCookieScope {
  video, // 视频详情 / 播放地址 / 播放进度上报
  comments, // 评论区列表
  search, // 搜索建议与搜索结果
  article, // 专栏与动态
  userSpace, // 用户空间
  season, // 番剧 / 剧集
  interactions, // 点赞 / 投币 / 收藏 / 关注 / 发送弹幕等互动写操作
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

  // Web 端（/x/passport-login/web/qrcode/...）扫码成功后只在网页前端 JS 里
  // 写入 bili_jct，poll 响应拿不到；TV 端 poll 成功时会在 JSON body 的
  // data.cookie_info.cookies 里下发完整 Cookie（含 SESSDATA / bili_jct）。
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

  /// 登录接口下发的 Cookie 只保留这些关键项（其余 Path/Expires 等属性丢弃）。
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
  String _avatarUrl = ''; // 头像地址（nav 接口 face，登录时保存）

  /// 登录会话的 buvid3/buvid4（设备指纹 Cookie）。
  /// B 站 Web 扫码流程要求 generate → poll 全程携带同一个 buvid3，
  /// 否则扫码确认后服务端无法关联会话（一直 86090 或不下发 SESSDATA）。
  String _buvid3 = '';
  String _buvid4 = '';

  /// 完整 Cookie 字符串（登录后保留，未启用携带时也不清除）。
  String get rawCookie => _rawCookie;

  /// 用户开关：是否把 Cookie 附加到 B 站 API 请求。
  bool get carryCookie => _carryCookie;
  String get uname => _uname;
  int get mid => _mid;
  String get avatarUrl => _avatarUrl;
  bool get isLoggedIn => _rawCookie.isNotEmpty;

  /// [scope] 是否已开启携带（仅看范围开关本身，不看登录态与总开关）。
  bool isCookieScopeSet(BiliCookieScope scope) => _cookieScopes.contains(scope);

  /// [scope] 范围是否实际允许携带 Cookie（登录 + 总开关 + 范围开关）。
  bool isCookieScopeEnabled(BiliCookieScope scope) =>
      isLoggedIn && _carryCookie && _cookieScopes.contains(scope);

  /// 按范围返回 Cookie 头；范围未启用、未登录或总开关关闭时返回 null。
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

  Future<void> initialize() async {
    _instance = this;
    final prefs = await SharedPreferences.getInstance();
    _rawCookie = prefs.getString(_prefsCookie) ?? '';
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
    _avatarUrl = prefs.getString(_prefsAvatar) ?? '';
    // 恢复登录名 / mid：否则重启后 mid=0，调用依赖 up_mid 的接口会返回 -400
    _uname = prefs.getString(_prefsUname) ?? '';
    _mid = prefs.getInt(_prefsMid) ?? 0;
    notifyListeners();
  }

  // ═════════════════════════════════════
  //  手动粘贴 Cookie
  // ═════════════════════════════════════

  /// 校验并保存用户 Cookie（浏览器复制的完整字符串）。
  /// 校验通过且 nav 接口确认已登录时返回 ok=true，并自动开启携带开关。
  /// 缺少 bili_jct 时拒绝登录——点赞等互动接口依赖它（csrf）。
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsCookie, trimmed);
    await prefs.setBool(_prefsCarry, true);
    await prefs.setString(_prefsAvatar, nav.face);
    await prefs.setString(_prefsUname, nav.uname);
    await prefs.setInt(_prefsMid, nav.mid);
    _rawCookie = trimmed;
    _carryCookie = true;
    _uname = nav.uname;
    _mid = nav.mid;
    _avatarUrl = nav.face;
    notifyListeners();
    return (ok: true, message: L10n.current.biliLoginSuccess);
  }

  /// 用指定 Cookie 请求 nav 接口确认登录状态，返回 (uname, mid)。
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
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
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
    _rawCookie = '';
    _carryCookie = false;
    _cookieScopes = {...BiliCookieScope.values};
    _uname = '';
    _mid = 0;
    _avatarUrl = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsCookie);
    await prefs.remove(_prefsAvatar);
    await prefs.remove(_prefsUname);
    await prefs.remove(_prefsMid);
    await prefs.remove(_prefsCookieScopes);
    await prefs.setBool(_prefsCarry, false);
    notifyListeners();
  }

  // ═════════════════════════════════════
  //  QR 扫码登录（passport-login web qrcode）
  // ═════════════════════════════════════

  /// 获取 buvid3/buvid4 设备指纹 Cookie（Web 扫码/密码登录前置步骤）。
  Future<void> _ensureBuvid() async {
    if (_buvid3.isNotEmpty) return;
    final client = await NetworkSettingsService.instance.getApiClient();
    try {
      final resp = await client
          .get(Uri.parse(_spiApi), headers: _apiHeaders)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return;
      _buvid3 = (data['b_3'] as String?) ?? '';
      _buvid4 = (data['b_4'] as String?) ?? '';
    } catch (e) {
      debugPrint('[BiliAccount] 获取 buvid 失败: $e');
    }
  }

  /// 当前登录会话的 Cookie 头（buvid3/buvid4）。
  Map<String, String> get _sessionCookieHeader {
    final parts = <String>[];
    if (_buvid3.isNotEmpty) parts.add('buvid3=$_buvid3');
    if (_buvid4.isNotEmpty) parts.add('buvid4=$_buvid4');
    return parts.isEmpty ? const {} : {'Cookie': parts.join('; ')};
  }

  /// 参数排序后拼成 query 串，再拼接 appsec 取 MD5。
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

  /// 获取二维码（TV 端 auth_code 接口，登录链接 + auth_code）。
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
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
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

  /// 轮询扫码状态。登录成功（code=0）时从 data.cookie_info.cookies
  /// 提取完整会话 Cookie（含 bili_jct）并校验保存。
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
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
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
      // 登录成功：TV 流在 JSON body 下发 data.cookie_info.cookies，
      // 包含 SESSDATA / bili_jct 等完整会话凭证（Web 流没有 bili_jct）。
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

  /// 从 TV 流登录成功响应的 data.cookie_info.cookies（[{name, value}]）中
  /// 提取关键 Cookie。
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

  /// 从 Set-Cookie 头字符串中提取关键 Cookie。多个 Set-Cookie 被
  /// package:http 以 ", " 合并，且部分值携带 Expires（含逗号），
  /// 因此逐项匹配到分号为止（B 站 Cookie 值均为百分号编码，不含分号）。
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

  /// 从扫码成功返回的 crossDomain 跳转链接（data.url）提取登录 Cookie。
  /// 链接形如 https://passport.biligame.com/crossDomain?DedeUserID=xx&SESSDATA=xx&bili_jct=xx...
  /// 注意：值与 Set-Cookie 一致（可能含 %2C 等百分号编码），此处不做解码。
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

  /// 合并两段 Cookie 字符串：优先保留 [primary] 的字段，[fallback] 只补充缺失项。
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

  // ═════════════════════════════════════
  //  密码登录（passport-login web）
  // ═════════════════════════════════════

  /// 获取 RSA 公钥与 hash（salt）。
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
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
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

  /// 密码登录（Web 接口）。
  /// 密码为 RSA-PKCS1v15 加密的「hash + 密码」。
  /// 返回 [BiliPwdLoginResult]：成功 / 需要极验验证码（带 gt/challenge/
  /// recaptchaToken，验证后重试）/ 失败。
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
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      final code = json['code'] as num?;
      final message =
          (json['message'] as String?) ?? L10n.current.biliUnknownError;
      if (code == 0) {
        // 登录成功：会话 Cookie 从 data.url（crossDomain 链接）与 Set-Cookie
        // 两处合并获取，避免 bili_jct 只出现在 data.url 时被漏掉。
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
        // 需要极验滑块验证码
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
}
