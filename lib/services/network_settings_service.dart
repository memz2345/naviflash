// lib/services/network_settings_service.dart
//
// 网络设置服务：连接模式 / Host 映射 / DoH 查询 / 请求头 / 连通性测试。
// 兼容直连基于 dart:io HttpOverrides 实现（IP 直连 / 可选跳过证书校验）。
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/l10n_helper.dart';
import 'bilibili_translate_service.dart';


enum NetworkMode {
  /// 标准模式：正常系统网络栈。
  standard('standard'),

  /// 兼容直连模式：Host 映射 IP 直连 + 可选关闭证书校验，绕过 SNI 干扰。
  compat('compat');

  const NetworkMode(this.code);

  final String code;

  static const List<NetworkMode> selectableValues = [
    NetworkMode.compat,
    NetworkMode.standard,
  ];

  static NetworkMode fromCode(String? code) {
    for (final mode in NetworkMode.values) {
      if (mode.code == code) return mode;
    }
    return NetworkMode.standard;
  }

  bool get usesCompatibleConnection => this == NetworkMode.compat;
}


class NetCheckResult {
  final String name;
  final String url;
  final bool success;
  final String message;
  final Duration elapsed;

  const NetCheckResult({
    required this.name,
    required this.url,
    required this.success,
    required this.message,
    required this.elapsed,
  });
}


class NetworkSettingsService extends ChangeNotifier {
  static NetworkSettingsService? _instance;

  /// 全局单例（initialize 后可用），供静态 API 服务读取 UA / 客户端。
  static NetworkSettingsService get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError('NetworkSettingsService 尚未初始化');
    }
    return inst;
  }

  NetworkMode _mode = NetworkMode.standard;
  bool _allowInsecureCert = false;
  String _referer = '';
  String _userAgent = '';

///  聊天 IPv6 开关（默认开启）：控制 TCP 双栈监听、IPv6 发现广播、
  ///    IPv6 地址展示与连接。可在网络设置里手动关闭。
  bool _enableChatIPv6 = true;

///  LocalSend 兼容开关（默认关闭）：关闭时使用 navi 原生协议方案；
  ///    在网络设置中手动开启后，启用 LocalSend 协议服务
  ///    （UDP 组播发现 + HTTP/HTTPS REST API，端口 53317）。
  bool _enableLocalSendCompat = false;

  /// 域名 → IP 的自定义映射。
  Map<String, String> _hostOverrides = {};

  /// 内置默认映射（无内置项，全部由用户自定义）。
  static const Map<String, String> kDefaultOverrides = {};

  /// DoH 查询端点（Cloudflare JSON DNS API）。
  static const String kDoHEndpoint = 'https://1dot1dot1dot1.cloudflare-dns.com';

  /// 本项目 ConnectionService 的局域网发现端口。
  static const int kDefaultLanPort = 26523;

  /// 共享 http 客户端（dart:io 默认客户端），随模式/配置变化重建。
  http.Client? _client;
  bool _clientCompatMode = false;


  NetworkMode get mode => _mode;
  bool get allowInsecureCert => _allowInsecureCert;
  String get referer => _referer;
  String get userAgent => _userAgent;
  bool get enableChatIPv6 => _enableChatIPv6;
  bool get enableLocalSendCompat => _enableLocalSendCompat;
  Map<String, String> get hostOverrides =>
      Map.unmodifiable(_hostOverrides);
  bool get isCompatMode => _mode.usesCompatibleConnection;

  /// 用户配置的请求头（UA / Referer），未设置时不包含对应项。
  /// 启用 B 站 AI 翻译时追加翻译头（locale / device / metadata bin）。
  Map<String, String> get apiHeaders => {
        if (_userAgent.isNotEmpty) 'User-Agent': _userAgent,
        if (_referer.isNotEmpty) 'Referer': _referer,
        ...BilibiliTranslateService.activeHeaders,
      };

  NetworkSettingsService();

  Future<void> initialize() async {
    _instance = this;
    await _load();
    _applyHttpOverrides();
    notifyListeners();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = NetworkMode.fromCode(prefs.getString('networkMode'));
    _allowInsecureCert = prefs.getBool('networkAllowInsecureCert') ?? false;
    _referer = prefs.getString('networkReferer') ?? '';
    _userAgent = prefs.getString('networkUserAgent') ?? '';
    _enableChatIPv6 = prefs.getBool('networkEnableChatIPv6') ?? true;
    _enableLocalSendCompat =
        prefs.getBool('networkEnableLocalSendCompat') ?? false;

    _hostOverrides = Map.of(kDefaultOverrides);
    final saved = prefs.getString('networkHostOverrides');
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as Map<String, dynamic>;
        _hostOverrides = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (e) {
        _hostOverrides = Map.of(kDefaultOverrides);
      }
    }
  }

  Future<void> _saveOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('networkHostOverrides', jsonEncode(_hostOverrides));
  }


  Future<void> setMode(NetworkMode value) async {
    if (_mode == value) return;
    _mode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('networkMode', value.code);
    _invalidateClient();
    _applyHttpOverrides();
    notifyListeners();
  }

  Future<void> setAllowInsecureCert(bool value) async {
    if (_allowInsecureCert == value) return;
    _allowInsecureCert = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('networkAllowInsecureCert', value);
    _invalidateClient();
    _applyHttpOverrides();
    notifyListeners();
  }

  Future<void> setReferer(String value) async {
    if (_referer == value) return;
    _referer = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('networkReferer', value);
    notifyListeners();
  }

  Future<void> setUserAgent(String value) async {
    if (_userAgent == value) return;
    _userAgent = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('networkUserAgent', value);
    _invalidateClient();
    notifyListeners();
  }

///  聊天 IPv6 开关（默认开启）。
  Future<void> setEnableChatIPv6(bool value) async {
    if (_enableChatIPv6 == value) return;
    _enableChatIPv6 = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('networkEnableChatIPv6', value);
    notifyListeners();
  }

///  LocalSend 兼容开关（默认关闭）。仅持久化偏好；
  ///    服务启停由网络设置页同步调用 LocalSendService.setEnabled。
  Future<void> setEnableLocalSendCompat(bool value) async {
    if (_enableLocalSendCompat == value) return;
    _enableLocalSendCompat = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('networkEnableLocalSendCompat', value);
    notifyListeners();
  }


  /// 取指定域名的映射 IP；无映射时返回 null（走系统 DNS）。
  String? resolveHost(String host) {
    final saved = _hostOverrides[host];
    if (saved != null && saved.isNotEmpty) return saved;
    return kDefaultOverrides[host];
  }

  Future<void> setHostOverride(String host, String ip) async {
    _hostOverrides[host] = ip;
    await _saveOverrides();
    _invalidateClient();
    _applyHttpOverrides();
    notifyListeners();
  }

  Future<void> removeHostOverride(String host) async {
    if (!_hostOverrides.containsKey(host)) return;
    _hostOverrides.remove(host);
    await _saveOverrides();
    _invalidateClient();
    _applyHttpOverrides();
    notifyListeners();
  }

  Future<void> resetHostOverrides() async {
    _hostOverrides = Map.of(kDefaultOverrides);
    await _saveOverrides();
    _invalidateClient();
    _applyHttpOverrides();
    notifyListeners();
  }


  /// 获取共享 http 客户端（dart:io 默认客户端）。
  /// 兼容直连模式由 HttpOverrides 全局接管（Host 映射 IP 直连 / 证书选项 / UA）。
  Future<http.Client> getApiClient() async {
    final client = _client;
    if (client != null && _clientCompatMode == _mode.usesCompatibleConnection) {
      return client;
    }
    _client?.close();
    final next = http.Client();
    _client = next;
    _clientCompatMode = _mode.usesCompatibleConnection;
    return next;
  }

  void _invalidateClient() {
    _client?.close();
    _client = null;
  }


  /// 通过 Cloudflare JSON DNS API 查询域名的 A 记录，返回解析到的 IP。
  Future<String?> queryDoH(String domain) async {
    final client = await getApiClient();
    final uri = Uri.parse(
      '$kDoHEndpoint/dns-query?name=${Uri.encodeQueryComponent(domain)}',
    );
    final resp = await client
        .get(uri, headers: {'accept': 'application/dns-json'})
        .timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) {
      throw HttpException(L10n.current.dohQueryFailed(resp.statusCode));
    }
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final answers = decoded['Answer'] as List<dynamic>? ?? [];
    final candidates = answers
        .whereType<Map<String, dynamic>>()
        .where((a) => a['type'] == 1 && a['data'] is String)
        .map((a) => a['data'] as String)
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort((l, r) {
      // 优先 IPv4 且非保留段
      bool isPrivate(String ip) {
        final parts = ip.split('.');
        if (parts.length != 4) return true;
        final first = int.tryParse(parts[0]) ?? -1;
        return first == 10 || first == 127 || first == 0;
      }

      return (isPrivate(l) ? 1 : 0) - (isPrivate(r) ? 1 : 0);
    });
    return candidates.first;
  }


  static const List<({String name, String url})> kDefaultTestTargets = [
    (name: 'Cloudflare DoH', url: 'https://1.1.1.1/dns-query'),
    (name: 'Bilibili API', url: 'https://api.bilibili.com/'),
  ];

  /// 测试一个 URL 的连通性：HEAD 优先，失败回退 GET，超时 8s。
  Future<NetCheckResult> testUrl({
    required String name,
    required String url,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse(url);
      final client = await getApiClient();
      try {
        final request = http.Request('HEAD', uri);
        final headers = <String, String>{...apiHeaders};
        if (headers.isNotEmpty) request.headers.addAll(headers);
        var resp = await http.Response.fromStream(
          await client.send(request).timeout(const Duration(seconds: 8)),
        );
        if (resp.statusCode >= 400) {
          resp = await client
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 8));
        }
        stopwatch.stop();
        return NetCheckResult(
          name: name,
          url: url,
          success: true,
          message: 'HTTP ${resp.statusCode}',
          elapsed: stopwatch.elapsed,
        );
      } finally {
        // 共享客户端不在此处关闭
      }
    } catch (e) {
      stopwatch.stop();
      return NetCheckResult(
        name: name,
        url: url,
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
        elapsed: stopwatch.elapsed,
      );
    }
  }

  /// 测试本机局域网发现端口（本项目 ConnectionService 的 UDP 端口）。
  Future<NetCheckResult> testLanPort({
    required String name,
    required String host,
    required int port,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 3),
      );
      await socket.close();
      stopwatch.stop();
      return NetCheckResult(
        name: name,
        url: '$host:$port',
        success: true,
        message: L10n.current.tcpConnectSuccess,
        elapsed: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return NetCheckResult(
        name: name,
        url: '$host:$port',
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
        elapsed: stopwatch.elapsed,
      );
    }
  }

  // ================= HttpOverrides（dart:io 原生客户端兜底） =================

  /// 兼容模式下把全局 HttpClient 的域名解析替换为 Host 映射表，
  /// 并应用用户 UA（覆盖 danmaku_parser 等直接使用 dart:io 的路径）。
  void _applyHttpOverrides() {
    if (_mode.usesCompatibleConnection) {
      HttpOverrides.global = _NaviHttpOverrides(this);
    } else {
      if (HttpOverrides.current is _NaviHttpOverrides) {
        HttpOverrides.global = null;
      }
    }
  }

  /// 供页面显示当前生效的连接信息。
  String get modeDescription => switch (_mode) {
        NetworkMode.compat => L10n.current.netModeCompat,
        NetworkMode.standard => L10n.current.netModeStandard,
      };
}


class _NaviHttpOverrides extends HttpOverrides {
  final NetworkSettingsService service;

  _NaviHttpOverrides(this.service);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    if (service.userAgent.isNotEmpty) {
      client.userAgent = service.userAgent;
    }
    if (service.allowInsecureCert) {
      client.badCertificateCallback = (cert, host, port) => true;
    }
    client.connectionTimeout = const Duration(seconds: 8);
    client.connectionFactory = (uri, proxyHost, proxyPort) {
      final ip = service.resolveHost(uri.host);
      final target = ip ?? uri.host;
      final socketFuture = InternetAddress.lookup(target).then((addresses) {
        if (addresses.isEmpty) {
          throw SocketException(L10n.current.netHostResolveFailed(target));
        }
        return Socket.connect(
          addresses.first,
          uri.port,
          timeout: const Duration(seconds: 8),
        );
      });
      return Future.value(ConnectionTask.fromSocket(socketFuture, () {}));
    };
    return client;
  }
}
