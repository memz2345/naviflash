                                             
  
                                                
                                                     
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/l10n_helper.dart';
import 'bilibili_translate_service.dart';


enum NetworkMode {
                   
  standard('standard'),

                                                
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

                                            
                                  
  bool _enableChatIPv6 = true;

                                            
                                      
                                                   
  bool _enableLocalSendCompat = false;

                     
  Map<String, String> _hostOverrides = {};

                            
  static const Map<String, String> kDefaultOverrides = {};

                                        
  static const String kDoHEndpoint = 'https://1dot1dot1dot1.cloudflare-dns.com';

                                     
  static const int kDefaultLanPort = 26523;

                                            
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

                      
  Future<void> setEnableChatIPv6(bool value) async {
    if (_enableChatIPv6 == value) return;
    _enableChatIPv6 = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('networkEnableChatIPv6', value);
    notifyListeners();
  }

                                 
                                                    
  Future<void> setEnableLocalSendCompat(bool value) async {
    if (_enableLocalSendCompat == value) return;
    _enableLocalSendCompat = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('networkEnableLocalSendCompat', value);
    notifyListeners();
  }


                                       
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

                                                                       

                                            
                                                    
  void _applyHttpOverrides() {
    if (_mode.usesCompatibleConnection) {
      HttpOverrides.global = _NaviHttpOverrides(this);
    } else {
      if (HttpOverrides.current is _NaviHttpOverrides) {
        HttpOverrides.global = null;
      }
    }
  }

                     
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
