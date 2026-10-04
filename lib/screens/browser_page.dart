           
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as win;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:naviflash/widgets/app_toast.dart';
import '../widgets/liquid_glass_menu_button.dart';
import '../widgets/search_video_menu.dart';
import '../services/lnative_bridge.dart';
import '../services/network_settings_service.dart';
import '../services/settings_service.dart';
import '../services/webview_cookie_service.dart';
import '../src/loading_indicator_m3e.dart';
import '../src/expressive_loading_indicator.dart';
import '../l10n/app_localizations.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart' show MorphIconButton;

Future<void> showNativeToast(String message) async {
  await NativeBridge.showToast(message);
}

Future<void> showPlatformAppropriateMessage(
  BuildContext context,
  String message,
) async {
  assert(message.isNotEmpty);
                                                            
              
  if (!context.mounted) return;
  showAppToast(context, message);
}

                                                                     
                                             
                                                                     

                                                            
bool _isMobileUa(String ua) {
  final lower = ua.toLowerCase();
  return lower.contains('android') ||
      lower.contains('iphone') ||
      lower.contains('ipad') ||
      lower.contains('mobile') ||
      lower.contains('mobi');
}

                                                 
String _replacePlatformSegment(String ua, String replacement) {
  final start = ua.indexOf('(');
  if (start < 0) return ua;
  final end = ua.indexOf(')', start + 1);
  if (end < 0) return ua;
  return ua.replaceRange(start, end + 1, '($replacement)');
}

                                                     
String _stripMobileMarkers(String ua) => ua.replaceAll(
      RegExp(r'\s+Mobile(?:/[0-9A-Za-z.\-]+)?\b', caseSensitive: false),
      '',
    );

                                                          
                                                                  
String _addMobileMarkers(String ua) {
  if (RegExp(r'\bMobile\b', caseSensitive: false).hasMatch(ua)) return ua;
  final idx = ua.indexOf(' Safari/');
  if (idx >= 0) return ua.replaceRange(idx, idx + 1, ' Mobile Safari/');
  return ua;
}

                            
String uaToMobile(String ua) {
  if (ua.isEmpty || _isMobileUa(ua)) return ua;
  final seg = ua.contains('Macintosh')
      ? 'iPhone; CPU iPhone OS 16_0 like Mac OS X'
      : 'Linux; Android 13; Pixel 7';
  return _addMobileMarkers(_replacePlatformSegment(ua, seg));
}

                            
String uaToDesktop(String ua) {
  if (ua.isEmpty || !_isMobileUa(ua)) return ua;
  final seg = ua.contains('iPhone') || ua.contains('iPad')
      ? 'Macintosh; Intel Mac OS X 10_15_7'
      : 'Windows NT 10.0; Win64; x64';
  return _stripMobileMarkers(_replacePlatformSegment(ua, seg));
}

class BrowserPage extends StatefulWidget {
  final String initialUrl;
  final String title;

                                   
                                                     
  final bool biliLoginMode;

                                            
  final Future<({bool ok, String message})> Function(String cookie)?
      onBiliLoginCookie;

  const BrowserPage({
    super.key,
    required this.initialUrl,
    required this.title,
    this.biliLoginMode = false,
    this.onBiliLoginCookie,
  });

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  WebViewController? _webviewController;
  win.WebviewController? _windowsController;
  bool _isLoading = true;
  bool _isRefreshing = false;
  double _progress = 0.0;
  String? _currentTitle;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _hasInitError = false;
  bool _allowClipboardAccess = true;
  bool _clipboardPrefLoaded = false;
                                        
  BrowserUaMode _uaMode = BrowserUaMode.auto;
                                                        
                                   
  String? _baseUa;
                                               
                                             
                                                         
                                                    
  ScaffoldMessengerState? _messenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
                                 
                                                        
    if (!_clipboardPrefLoaded) {
      _clipboardPrefLoaded = true;
      final settings = context.read<SettingsService>();
      if (_allowClipboardAccess != settings.browserAllowClipboard) {
        _allowClipboardAccess = settings.browserAllowClipboard;
      }
    }
  }

                      
  Timer? _biliCheckTimer;
  bool _biliLoggedIn = false;
  bool _biliImporting = false;

  static const String _biliNavCheckJs = '''
(function(){
  var cb = 'window.__navcb_' + Date.now();
  window[cb] = function(json){
    var ok = json && json.code === 0 && json.data && json.data.isLogin === true;
    if (ok) {
      if (window.chrome && window.chrome.webview) {
        window.chrome.webview.postMessage('BILI_LOGIN_OK');
      } else if (window.FlutterBiliLogin) {
        FlutterBiliLogin.postMessage('BILI_LOGIN_OK');
      }
    }
  };
  var s = document.createElement('script');
  s.src = 'https://api.bilibili.com/x/web-interface/nav?jsonp=' + cb;
  document.body.appendChild(s);
})();
''';

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
                                                           
                                                         
    try {
      _uaMode = context.read<SettingsService>().browserUaMode;
    } catch (_) {}
    if (Platform.isWindows) {
      _initWindows();
    } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      _initNativeWebView();
    } else {
      _openInSystemBrowser();
    }
    if (widget.biliLoginMode) {
      _startBiliLoginCheck();
    }
  }

  void _startBiliLoginCheck() {
    _biliCheckTimer?.cancel();
    _biliCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_biliLoggedIn) {
        _biliCheckTimer?.cancel();
        return;
      }
                                              
      try {
        if (Platform.isWindows) {
          await _windowsController?.executeScript(_biliNavCheckJs);
        } else {
          await _webviewController?.runJavaScript(_biliNavCheckJs);
        }
      } catch (_) {}
                                                             
                                        
      try {
        final docCookie = await _readDocumentCookie();
        if (docCookie != null &&
            docCookie.contains('bili_jct=') &&
            mounted &&
            !_biliLoggedIn) {
          setState(() => _biliLoggedIn = true);
        }
      } catch (_) {}
    });
  }

                                                    
  Future<String?> _readDocumentCookie() async {
    String? result;
    if (Platform.isWindows) {
      result = await _windowsController?.executeScript(
        'return document.cookie;',
      );
    } else {
      result = (await _webviewController?.runJavaScriptReturningResult(
            'document.cookie',
          )) as String?;
    }
    if (result is String) {
      return result.replaceAll(RegExp(r'^"|"$'), '').trim();
    }
    return null;
  }

  void _goBack() {
    if (Platform.isWindows) {
      _windowsController?.goBack();
    } else {
      _webviewController?.goBack();
    }
  }

  void _goForward() {
    if (Platform.isWindows) {
      _windowsController?.goForward();
    } else {
      _webviewController?.goForward();
    }
  }

  void _handleCustomScheme(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    String scheme = uri.scheme.toLowerCase();
    String appHint = scheme;
    switch (scheme) {
      default:
        appHint = '$scheme ${AppLocalizations.of(context).browserApp}';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).browserOpenAppAttempt(appHint),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: AppLocalizations.of(context).scanOpen,
          onPressed: () async {
            try {
              final bool launched = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!launched && mounted) {
                showPlatformAppropriateMessage(
                  context,
                  AppLocalizations.of(context).browserNoAppForLink,
                );
              }
            } catch (e) {
              if (mounted) {
                showPlatformAppropriateMessage(
                  context,
                  AppLocalizations.of(context).browserOpenFailedSystem,
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _initNativeWebView() {
    try {
      final settingsUa = NetworkSettingsService.instance.userAgent;
      _baseUa = settingsUa.isEmpty ? null : settingsUa;
      final effectiveUa = _effectiveUa(_baseUa ?? '');
      _webviewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(effectiveUa.isEmpty ? null : effectiveUa)
        ..addJavaScriptChannel(
          'FlutterBiliLogin',
          onMessageReceived: (message) {
            if (message.message == 'BILI_LOGIN_OK' && mounted) {
              setState(() => _biliLoggedIn = true);
            }
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              final uri = Uri.tryParse(request.url);
              if (uri != null &&
                  uri.scheme != 'http' &&
                  uri.scheme != 'https' &&
                  uri.scheme != 'file' &&
                  uri.scheme != 'data' &&
                  uri.scheme != 'about' &&
                  uri.scheme != 'content' &&
                  uri.scheme != 'chrome' &&
                  uri.scheme != 'javascript') {
                _handleCustomScheme(request.url);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            onPageStarted: (_) async {
              if (!mounted) return;
              try {
                await _webviewController?.runJavaScript(
                  _getClipboardInterceptJs(),
                );
                await _webviewController?.runJavaScript(
                  'window.__ALLOW_CLIPBOARD__ = $_allowClipboardAccess;',
                );
              } catch (e) {
                debugPrint('Android JS injection failed: $e');
              }

              final canGoBack = await _webviewController?.canGoBack() ?? false;
              final canGoForward =
                  await _webviewController?.canGoForward() ?? false;
              if (!mounted) return;
              setState(() {
                _canGoBack = canGoBack;
                _canGoForward = canGoForward;
                _isLoading = true;
                _progress = 0.0;
              });
            },
            onProgress: (int progress) {
              if (!mounted) return;
              setState(() {
                _progress = progress / 100.0;
              });
            },
            onPageFinished: (String url) async {
              if (!mounted) return;
                                                        
                                    
              await _syncBaseUaIfNeeded();
              String? title;
              try {
                title = await _webviewController?.getTitle();
              } catch (e) {
                debugPrint("Failed to get title on Android: $e");
              }
              final canGoBack = await _webviewController?.canGoBack() ?? false;
              final canGoForward =
                  await _webviewController?.canGoForward() ?? false;
              if (!mounted) return;
              setState(() {
                _canGoBack = canGoBack;
                _canGoForward = canGoForward;
                _isLoading = false;
                if (title != null && title.trim().isNotEmpty) {
                  _currentTitle = title.trim();
                }
              });
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.initialUrl));
    } catch (e) {
      debugPrint("Native WebView 初始化失败: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasInitError = true;
        });
      }
    }
  }

  String _getClipboardInterceptJs() {
    return '''
    (function() {
        if (window.__CLIPBOARD_INTERCEPTED__) return;
        window.__CLIPBOARD_INTERCEPTED__ = true;
        if (typeof window.__ALLOW_CLIPBOARD__ === 'undefined') {
            window.__ALLOW_CLIPBOARD__ = true;
        }

        // 1. 拦截现代 Clipboard API
        if (navigator.clipboard) {
            const originalWriteText = navigator.clipboard.writeText;
            if (originalWriteText) {
                navigator.clipboard.writeText = function(text) {
                    if (!window.__ALLOW_CLIPBOARD__) {
                        console.warn('Clipboard write blocked by app.');
                        return Promise.reject(new DOMException('Blocked by app', 'NotAllowedError'));
                    }
                    return originalWriteText.call(navigator.clipboard, text);
                };
            }
            const originalWrite = navigator.clipboard.write;
            if (originalWrite) {
                navigator.clipboard.write = function(data) {
                    if (!window.__ALLOW_CLIPBOARD__) return Promise.reject(new DOMException('Blocked', 'NotAllowedError'));
                    return originalWrite.call(navigator.clipboard, data);
                };
            }
        }

        // 2. 拦截传统 execCommand API
        const originalExecCommand = document.execCommand;
        if (originalExecCommand) {
            document.execCommand = function(cmd, ui, val) {
                if ((cmd === 'copy' || cmd === 'cut') && !window.__ALLOW_CLIPBOARD__) {
                    console.warn('Clipboard execCommand blocked by app.');
                    return false;
                }
                return originalExecCommand.call(document, cmd, ui, val);
            };
        }
    })();
    ''';
  }

  Future<void> _updateClipboardPermissionInJs() async {
    final js = 'window.__ALLOW_CLIPBOARD__ = $_allowClipboardAccess;';
    try {
      if (Platform.isWindows) {
        await _windowsController?.executeScript(js);
      } else {
        await _webviewController?.runJavaScript(js);
      }
    } catch (e) {
      debugPrint('Failed to update clipboard permission in JS: $e');
    }
  }

  Future<void> _showCookieDialog() async {
    String? cookie;
    try {
      if (Platform.isWindows) {
        final result = await _windowsController?.executeScript(
          'return document.cookie;',
        );
        if (result is String) {
          cookie = result.replaceAll(RegExp(r'^"|"$'), '');
        }
      } else {
        final result = await _webviewController?.runJavaScriptReturningResult(
          'document.cookie',
        );
        if (result is String) {
          cookie = result.replaceAll(RegExp(r'^"|"$'), '');
        }
      }
    } catch (e) {
      debugPrint('Failed to get cookie: $e');
    }
    if (!mounted) return;
    final TextEditingController controller = TextEditingController(
      text: cookie ?? '',
    );
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cookies'),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              maxLines: 15,
              minLines: 5,
              readOnly: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(dialogContext).browserEmptyCookieHint,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(dialogContext).scanClose),
            ),
            ElevatedButton.icon(
              label: Text(AppLocalizations.of(dialogContext).browserCopyAll),
              onPressed: () async {
                if (cookie != null && cookie.trim().isNotEmpty) {
                  await Clipboard.setData(ClipboardData(text: cookie.trim()));
                  if (mounted) {
                    showPlatformAppropriateMessage(
                      context,
                      AppLocalizations.of(context).browserCookieCopied,
                    );
                  }
                } else {
                  if (mounted) {
                    showPlatformAppropriateMessage(
                      context,
                      AppLocalizations.of(context).browserCookieEmpty,
                    );
                  }
                }
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUaDialog() async {
    String? currentUa;
    try {
      if (Platform.isWindows) {
        final result = await _windowsController?.executeScript(
          "return navigator.userAgent;",
        );
        if (result is String) {
          currentUa = result.replaceAll(RegExp(r'^"|"$'), '').trim();
        }
      } else {
        currentUa = await _webviewController?.getUserAgent();
      }
    } catch (e) {
      debugPrint('Failed to get UA: $e');
    }
    if (!mounted) return;
    final TextEditingController uaController = TextEditingController(
      text: currentUa ?? '',
    );
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext).browserSetUaTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: uaController,
              maxLines: 4,
              minLines: 2,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(dialogContext).browserUaHint,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(dialogContext).commonCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUa = uaController.text.trim();
                Navigator.of(dialogContext).pop();
                await _applyUserAgent(newUa);
              },
              child: Text(AppLocalizations.of(dialogContext).browserApplyAndReload),
            ),
          ],
        );
      },
    );
  }

  Future<void> _applyUserAgent(String ua) async {
                                   
    _baseUa = ua.isEmpty ? null : ua;
    try {
      if (Platform.isWindows) {
        await _windowsController?.setUserAgent(ua);
        _windowsController?.reload();
      } else {
        await _webviewController?.setUserAgent(ua.isEmpty ? null : ua);
        _webviewController?.reload();
      }
      if (mounted) {
        showPlatformAppropriateMessage(
          context,
          AppLocalizations.of(context).browserUaUpdated,
        );
      }
    } catch (e) {
      debugPrint('Failed to set UA: $e');
      if (mounted) {
        showPlatformAppropriateMessage(
          context,
          AppLocalizations.of(context).browserUaSetFailed('$e'),
        );
      }
    }
  }

                                           

                                                       
  String _effectiveUa(String baseUa) {
    if (baseUa.isEmpty) return '';
    return switch (_uaMode) {
      BrowserUaMode.auto => baseUa,
      BrowserUaMode.desktop => uaToDesktop(baseUa),
      BrowserUaMode.mobile => uaToMobile(baseUa),
    };
  }

                              
  Future<String?> _readWebviewUa() async {
    try {
      if (Platform.isWindows) {
        final r = await _windowsController?.executeScript(
          'return navigator.userAgent;',
        );
        if (r is String) {
          final ua = r.replaceAll(RegExp(r'^"|"$'), '').trim();
          return ua.isEmpty ? null : ua;
        }
        return null;
      }
      return await _webviewController?.getUserAgent();
    } catch (e) {
      debugPrint('Failed to read UA: $e');
      return null;
    }
  }

                                                  
  Future<void> _readBaseUaFromWebview() async {
    final ua = await _readWebviewUa();
    if (ua != null && ua.isNotEmpty) _baseUa = ua;
  }

                                      
                                           
  Future<void> _syncBaseUaIfNeeded() async {
    if (_baseUa != null && _baseUa!.isNotEmpty) return;
    if (_uaMode == BrowserUaMode.auto) return;
    final ua = await _readWebviewUa();
    if (ua == null || ua.isEmpty) return;
    _baseUa = ua;
    final effective = _effectiveUa(ua);
    if (effective == ua) return;               
    try {
      if (Platform.isWindows) {
        await _windowsController?.setUserAgent(effective);
        _windowsController?.reload();
      } else {
        await _webviewController?.setUserAgent(effective);
        _webviewController?.reload();
      }
    } catch (e) {
      debugPrint('Failed to sync UA mode: $e');
    }
  }

                                                 
  Future<void> _setUaMode(BrowserUaMode mode) async {
    if (_uaMode == mode) return;
    setState(() => _uaMode = mode);
    try {
      final settings = context.read<SettingsService>();
      await settings.setBrowserUaMode(mode);
    } catch (e) {
      debugPrint('Failed to persist UA mode: $e');
    }
    if (_baseUa == null || _baseUa!.isEmpty) {
      await _readBaseUaFromWebview();
    }
    final effective = _effectiveUa(_baseUa ?? '');
    try {
      if (Platform.isWindows) {
        await _windowsController?.setUserAgent(effective);
        _windowsController?.reload();
      } else {
        await _webviewController?.setUserAgent(
          effective.isEmpty ? null : effective,
        );
        _webviewController?.reload();
      }
      if (mounted) {
        showPlatformAppropriateMessage(
          context,
          AppLocalizations.of(context).browserUaUpdated,
        );
      }
    } catch (e) {
      debugPrint('Failed to set UA mode: $e');
      if (mounted) {
        showPlatformAppropriateMessage(
          context,
          AppLocalizations.of(context).browserUaSetFailed('$e'),
        );
      }
    }
  }

  Future<void> _initWindows() async {
    _windowsController = win.WebviewController();
    try {
      await _windowsController!.initialize();
                                               
      WebviewCookieService.registerWindowsController(_windowsController);
      final settingsUa = NetworkSettingsService.instance.userAgent;
      _baseUa = settingsUa.isEmpty ? null : settingsUa;
      final effectiveUa = _effectiveUa(_baseUa ?? '');
      if (effectiveUa.isNotEmpty) {
        await _windowsController!.setUserAgent(effectiveUa);
      }
      await _windowsController!.addScriptToExecuteOnDocumentCreated('''
document.addEventListener('click', function(e) {
var target = e.target;
while (target && target.tagName !== 'A') {
target = target.parentElement;
}
if (target && target.href) {
var scheme = target.href.split(':')[0].toLowerCase();
if (['http', 'https', 'file', 'data', 'javascript', 'blob'].indexOf(scheme) === -1) {
e.preventDefault();
e.stopPropagation();
window.chrome.webview.postMessage('CUSTOM_SCHEME:' + target.href);
}
}
}, true);
''');
      await _windowsController!.addScriptToExecuteOnDocumentCreated(
        _getClipboardInterceptJs(),
      );

      _windowsController!.webMessage.listen((msg) {
        final msgStr = msg?.toString() ?? '';
        if (msgStr == 'BILI_LOGIN_OK' && mounted) {
          setState(() => _biliLoggedIn = true);
        }
      });

      _windowsController!.loadingState.listen((state) async {
        if (!mounted) return;
        if (state == win.LoadingState.loading) {
          setState(() {
            _isLoading = true;
            _progress = 0.2;
            _currentTitle = null;
          });
        } else if (state == win.LoadingState.navigationCompleted) {
                                                    
                                
          await _syncBaseUaIfNeeded();
          await Future.delayed(const Duration(milliseconds: 150));
          String? jsTitle;
          try {
            final result = await _windowsController!.executeScript(
              "return document.title;",
            );
            if (result is String && result.trim().isNotEmpty) {
              jsTitle = result.trim();
            }
          } catch (e) {
            debugPrint("Windows: Failed to get document.title - $e");
          }
          try {
            await _windowsController?.executeScript(
              'window.__ALLOW_CLIPBOARD__ = $_allowClipboardAccess;',
            );
          } catch (e) {
            debugPrint('Windows clipboard sync failed: $e');
          }

          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _progress = 1.0;

            _currentTitle = jsTitle ?? widget.title;
          });
        }
      });
      await _windowsController!.loadUrl(widget.initialUrl);
    } catch (e) {
      debugPrint("Windows WebView 初始化失败: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasInitError = true;
        });
        showPlatformAppropriateMessage(
          context,
          AppLocalizations.of(context).browserWindowsInitFailed,
        );
      }
    }
  }

  @override
  void dispose() {
    _biliCheckTimer?.cancel();
                                           
                     
    _messenger?.removeCurrentSnackBar();
                                    
    if (identical(WebviewCookieService.windowsController, _windowsController)) {
      WebviewCookieService.registerWindowsController(null);
    }
    _windowsController?.dispose();
    super.dispose();
  }

                                           

                                                                
  String? _parseCdpCookies(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final cookies = (decoded['cookies'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .where(
            (c) => ((c['domain'] as String?) ?? '').contains('bilibili.com'),
          )
          .map((c) => '${c['name']}=${c['value'] ?? ''}')
          .toList();
      return cookies.isEmpty ? null : cookies.join('; ');
    } catch (e) {
      debugPrint('解析 CDP cookies 失败: $e');
      return null;
    }
  }

                                                             
  Future<String?> _captureBiliCookie() async {
    if (Platform.isWindows) {
      final json = await _windowsController?.getCookies();
      final cookie = _parseCdpCookies(json);
      if (cookie != null && cookie.contains('SESSDATA')) return cookie;
      return null;
    }
    if (Platform.isAndroid) {
      try {
        final cm = WebViewCookieManager();
        final cookies = await cm.getCookies(
          domain: Uri.parse('https://www.bilibili.com'),
        );
        final parts = cookies
            .map((c) => '${c.name}=${c.value}')
            .where((p) => p.isNotEmpty)
            .toList();
        final cookie = parts.join('; ');
        if (cookie.contains('SESSDATA')) return cookie;
      } catch (e) {
        debugPrint('CookieManager 获取失败: $e');
      }
      return null;
    }
                                                          
    try {
      final result = await _webviewController?.runJavaScriptReturningResult(
        'document.cookie',
      );
      final cookie = (result as String?)
          ?.replaceAll(RegExp(r'^"|"$'), '')
          .trim();
      if (cookie != null && cookie.isNotEmpty) return cookie;
    } catch (e) {
      debugPrint('document.cookie 获取失败: $e');
    }
    return null;
  }

  Future<void> _importBiliLogin() async {
    if (_biliImporting) return;
    setState(() => _biliImporting = true);
    final cookie = await _captureBiliCookie();
    if (!mounted) return;
    if (cookie == null) {
      setState(() => _biliImporting = false);
      showPlatformAppropriateMessage(
        context,
        AppLocalizations.of(context).browserBiliCookieReadFailed,
      );
      return;
    }
    final result = await widget.onBiliLoginCookie?.call(cookie);
    if (!mounted) return;
    setState(() => _biliImporting = false);
    if (result?.ok ?? false) {
      if (mounted) Navigator.of(context).pop();
    } else {
      showPlatformAppropriateMessage(
        context,
        result?.message.isNotEmpty == true
            ? result!.message
            : AppLocalizations.of(context).browserCookieImportFailed,
      );
    }
  }

  Future<void> _stopLoading() async {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      await _webviewController?.loadRequest(Uri.parse('about:blank'));
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _progress = 0.0;
      });
      showPlatformAppropriateMessage(
        context,
        AppLocalizations.of(context).browserStoppedLoading,
      );
    } else if (Platform.isWindows) {
      await _windowsController?.stop();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _progress = 0.0;
      });
      showPlatformAppropriateMessage(
        context,
        AppLocalizations.of(context).browserStoppedLoading,
      );
    }
  }

  Future<void> _handleMenuOption(String value) async {
    if (value == 'toggle_clipboard') {
      setState(() {
        _allowClipboardAccess = !_allowClipboardAccess;
      });
      _updateClipboardPermissionInJs();
                               
      try {
        final settings = context.read<SettingsService>();
        await settings.setBrowserAllowClipboard(_allowClipboardAccess);
      } catch (e) {
        debugPrint('Failed to persist clipboard permission: $e');
      }
      if (!mounted) return;
      showPlatformAppropriateMessage(
        context,
        _allowClipboardAccess
            ? AppLocalizations.of(context).browserClipboardAllowed
            : AppLocalizations.of(context).browserClipboardBlocked,
      );
      return;
    }

    String? currentUrl;
    if (Platform.isWindows) {
      try {
        final result = await _windowsController?.executeScript(
          "return window.location.href;",
        );
        if (result is String) {
          String cleanUrl = result.replaceAll(RegExp(r'^"|"$'), '').trim();
          if (cleanUrl.isNotEmpty && cleanUrl != 'about:blank') {
            currentUrl = cleanUrl;
          } else {
            currentUrl = widget.initialUrl;
          }
        } else {
          currentUrl = widget.initialUrl;
        }
      } catch (e) {
        currentUrl = widget.initialUrl;
      }
    } else {
      currentUrl = await _webviewController?.currentUrl() ?? widget.initialUrl;
    }
    if (value == 'share_qr') {
      if (currentUrl.isNotEmpty) {
        _showQrCodeDialog(currentUrl);
      } else {
        if (mounted) {
          showPlatformAppropriateMessage(
            context,
            AppLocalizations.of(context).browserNoCurrentUrl,
          );
        }
      }
      return;
    }
    switch (value) {
      case 'troubleshoot_network':
        final troubleshootUri = Uri.parse(
          'ms-contact-support://smc-to-emerald/NetworkAndInternetTroubleshooter',
        );
        if (await canLaunchUrl(troubleshootUri)) {
          await launchUrl(
            troubleshootUri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          if (!mounted) break;
          showPlatformAppropriateMessage(
            context,
            AppLocalizations.of(context).browserTroubleshootFailed,
          );
        }
        break;
      case 'copy':
        await Clipboard.setData(ClipboardData(text: currentUrl));
        if (!mounted) break;
        showPlatformAppropriateMessage(
          context,
          AppLocalizations.of(context).scanLinkCopied,
        );
        break;
      case 'copy_cookie':
        await _showCookieDialog();
        break;
      case 'set_ua':
        await _showUaDialog();
        break;
      case 'ua_mode_auto':
        await _setUaMode(BrowserUaMode.auto);
        break;
      case 'ua_mode_desktop':
        await _setUaMode(BrowserUaMode.desktop);
        break;
      case 'ua_mode_mobile':
        await _setUaMode(BrowserUaMode.mobile);
        break;
      case 'refresh':
        if (Platform.isWindows) {
          _windowsController?.reload();
        } else {
          _webviewController?.reload();
        }
        break;
      case 'system':
        final uri = Uri.parse(currentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (!mounted) break;
          showPlatformAppropriateMessage(
            context,
            AppLocalizations.of(context).browserSystemBrowserMissing,
          );
        }
        break;
    }
  }

  void _showQrCodeDialog(String url) {
    final ScreenshotController screenshotController = ScreenshotController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext).browserQrTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Screenshot(
                controller: screenshotController,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: QrImageView(
                    data: url,
                    version: QrVersions.auto,
                    size: 220.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                url,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(dialogContext).scanClose),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt, size: 18),
              label: Text(AppLocalizations.of(dialogContext).browserSaveToDevice),
              onPressed: () async {
                try {
                  final Uint8List? imageBytes = await screenshotController
                      .capture(pixelRatio: 3.0);
                  if (imageBytes != null) {
                    await Gal.putImageBytes(
                      imageBytes,
                      name:
                          'qrcode_${DateTime.now().millisecondsSinceEpoch}.png',
                    );
                    if (mounted) {
                      showPlatformAppropriateMessage(
                        context,
                        AppLocalizations.of(context).browserQrSaved,
                      );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    showPlatformAppropriateMessage(
                      context,
                      AppLocalizations.of(context).browserSaveFailed('$e'),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showTopProgress = _isLoading;
    final l10n = AppLocalizations.of(context);
    final String displayTitle = _currentTitle ?? widget.title;
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _canGoBack) {
          _goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          centerTitle: false,
          title: Padding(
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).padding.left + 8.0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MorphIconButton(
                  icon: Icons.arrow_back,
                  iconSize: 24,
                  tooltip: l10n.commonBackTooltip,
                  transparent: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                MorphIconButton(
                  icon: Icons.close,
                  iconSize: 24,
                  tooltip: l10n.browserStopLoading,
                  transparent: true,
                  onTap: _isLoading ? _stopLoading : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottom: showTopProgress
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2.0),
                  child: LinearProgressIndicator(
                    value: Platform.isAndroid ? _progress : null,
                    backgroundColor: Colors.transparent,
                    minHeight: 2.0,
                  ),
                )
              : null,
          actions: [
            if (widget.biliLoginMode && _biliLoggedIn)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: FilledButton.icon(
                  onPressed: _biliImporting ? null : _importBiliLogin,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                  ),
                  icon: _biliImporting
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        )
                      : const Icon(Icons.login, size: 16),
                  label: Text(
                    _biliImporting
                        ? l10n.browserImporting
                        : l10n.browserLoginDoneImport,
                  ),
                ),
              ),
            LiquidGlassMenuButton(
              icon: Icons.more_vert,
              tooltip: l10n.playlistMenuMore,
              menuWidth: 220,
                                                       
              transparent: true,
              actions: [
                GlassMenuAction(
                  icon: Icons.content_paste_go,
                  text: l10n.browserClipboardAccess,
                  trailing: _allowClipboardAccess
                      ? Icon(
                          Icons.check,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => _handleMenuOption('toggle_clipboard'),
                ),
                GlassMenuAction(
                  icon: Icons.qr_code_2,
                  text: l10n.browserShareQr,
                  onTap: () => _handleMenuOption('share_qr'),
                ),
                GlassMenuAction(
                  icon: Icons.copy,
                  text: l10n.browserCopyLink,
                  onTap: () => _handleMenuOption('copy'),
                ),
                GlassMenuAction(
                  icon: Icons.cookie,
                  text: l10n.browserViewCookies,
                  onTap: () => _handleMenuOption('copy_cookie'),
                ),
                GlassMenuAction(
                  icon: Icons.emoji_people,
                  text: l10n.browserSetUa,
                  onTap: () => _handleMenuOption('set_ua'),
                ),
                                                         
                GlassMenuAction(
                  icon: Icons.autorenew,
                  text: l10n.browserUaModeAuto,
                  trailing: _uaMode == BrowserUaMode.auto
                      ? Icon(
                          Icons.check,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => _handleMenuOption('ua_mode_auto'),
                ),
                GlassMenuAction(
                  icon: Icons.desktop_windows,
                  text: l10n.browserUaModeDesktop,
                  trailing: _uaMode == BrowserUaMode.desktop
                      ? Icon(
                          Icons.check,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => _handleMenuOption('ua_mode_desktop'),
                ),
                GlassMenuAction(
                  icon: Icons.smartphone,
                  text: l10n.browserUaModeMobile,
                  trailing: _uaMode == BrowserUaMode.mobile
                      ? Icon(
                          Icons.check,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => _handleMenuOption('ua_mode_mobile'),
                ),
                GlassMenuAction(
                  icon: Icons.refresh,
                  text: l10n.browserRefresh,
                  onTap: () => _handleMenuOption('refresh'),
                ),
                GlassMenuAction(
                  icon: Icons.open_in_browser,
                  text: l10n.browserSystemBrowser,
                  onTap: () => _handleMenuOption('system'),
                ),
                if (Platform.isWindows)
                  GlassMenuAction(
                    icon: Icons.network_check,
                    text: l10n.browserTroubleshootNetwork,
                    onTap: () => _handleMenuOption('troubleshoot_network'),
                  ),
              ],
            ),
          ],
        ),
        body: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (PointerDownEvent event) {
            if (event.kind == PointerDeviceKind.mouse) {
              if (event.buttons & 8 != 0) {
                if (_canGoBack) {
                  _goBack();
                } else {
                  Navigator.of(context).pop();
                }
              } else if (event.buttons & 16 != 0) {
                if (_canGoForward) {
                  _goForward();
                }
              }
            }
          },
          child: Platform.isWindows
              ? _buildWindowsView()
              : _buildNativeWebView(),
        ),
      ),
    );
  }

  Future<void> _openInSystemBrowser() async {
    final uri = Uri.tryParse(widget.initialUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildUnsupportedPlatform() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.browserUnsupportedPlatform,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.browserOpenedInSystem,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.open_in_browser),
              label: Text(l10n.browserReopenInSystem),
              onPressed: _openInSystemBrowser,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowsView() {
    if (_hasInitError) {
      return _buildBsodErrorPage();
    }
    if (_windowsController?.value.isInitialized != true) {
      return const Center(child: ExpressiveLoadingIndicator());
    }
    return win.Webview(_windowsController!);
  }

  Widget _buildNativeWebView() {
    if (_hasInitError) {
      if (Platform.isAndroid) return _buildAndroidErrorPage();
      if (Platform.isIOS || Platform.isMacOS) return _buildAppleErrorPage();
      return _buildGenericErrorPage();
    }
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      return _buildUnsupportedPlatform();
    }
    if (_webviewController == null) {
      return const Center(child: LoadingIndicatorM3E());
    }
    return AppRefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () async {
        setState(() => _isRefreshing = true);
        try {
          await _webviewController!.reload();
        } finally {
          if (mounted) setState(() => _isRefreshing = false);
        }
      },
      child: AbsorbPointer(
        absorbing: _isRefreshing,
        child: WebViewWidget(controller: _webviewController!),
      ),
    );
  }

  Widget _buildAndroidErrorPage() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: const Color(0xFF1B1B1B),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 30, 32, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _DeadAndroidPainter(
                    color: colorScheme.error.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context).browserAndroidErrorTitle,
                style: TextStyle(
                  color: colorScheme.error.withValues(alpha: 0.85),
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No command.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 36),
              _buildErrorInfoBlock(
                AppLocalizations.of(context).browserAndroidErrorCause,
                AppLocalizations.of(context).browserAndroidErrorDetail,
              ),
              const SizedBox(height: 18),
              _buildErrorLink(
                AppLocalizations.of(context).browserUpdateWebview,
                'https://play.google.com/store/apps/details?id=com.google.android.webview',
              ),
              const SizedBox(height: 8),
              _buildErrorLink(
                AppLocalizations.of(context).browserOpenDevOptions,
                '#',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppleErrorPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    return Container(
      color: bgColor,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  AppLocalizations.of(context).browserAppleErrorTitle,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'WebView initialization failed',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: textColor.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).browserAppleErrorReport,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context).browserAppleErrorDetail,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text(AppLocalizations.of(context).homeBack),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenericErrorPage() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kernel panic - not syncing',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[  0.000000] WebView Initialization Failed',
                        style: TextStyle(
                          color: Colors.red[300],
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        '[  0.004000] CPU: Flutter/Dart Unsupported',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        '[  0.008000] Attempted to init native browser',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        '[  0.012000] ---[ end Kernel panic - not syncing ]---',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text(AppLocalizations.of(context).homeBack),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBsodErrorPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = colorScheme.primary;
    final textColor = colorScheme.onPrimary;
    return Container(
      color: bgColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 40, 40, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ':(',
                style: TextStyle(
                  color: textColor,
                  fontSize: 100,
                  fontWeight: FontWeight.w300,
                  height: 1,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).browserBsodMessage,
                style: TextStyle(color: textColor, fontSize: 22, height: 1.4),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).browserBsodNoRestart,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).browserBsodComplete,
                style: TextStyle(color: textColor, fontSize: 22),
              ),
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context).browserBsodSolutions,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildBsodLink(
                AppLocalizations.of(context).browserBsodDownload,
                'https://developer.microsoft.com/microsoft-edge/webview2/',
                textColor,
              ),
              _buildBsodLink(
                AppLocalizations.of(context).browserBsodWinUpdate,
                'ms-settings:windowsupdate',
                textColor,
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    color: Colors.white,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(4),
                    child: QrImageView(
                      data: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                      version: QrVersions.auto,
                      size: 72,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).browserBsodScanQr,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.9),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.of(context).browserBsodStopCode,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBsodLink(String text, String url, Color textColor) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            showPlatformAppropriateMessage(
              context,
              AppLocalizations.of(context).browserCantOpenExternal,
            );
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            decoration: TextDecoration.underline,
            decorationColor: textColor,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorInfoBlock(String label, String content) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorLink(String text, String url) {
    return GestureDetector(
      onTap: url == '#'
          ? null
          : () async {
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 14,
            decoration: url == '#' ? null : TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

class _DeadAndroidPainter extends CustomPainter {
  final Color color;
  _DeadAndroidPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

           
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy + 12),
          width: w * 0.28,
          height: h * 0.38,
        ),
        const Radius.circular(12),
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

                         
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy - 22),
        width: w * 0.34,
        height: h * 0.22,
      ),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      headRect,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

               
    paint.strokeWidth = 3;
    canvas.drawLine(Offset(cx - 10, cy - 36), Offset(cx - 16, cy - 52), paint);
    canvas.drawLine(Offset(cx + 10, cy - 36), Offset(cx + 16, cy - 52), paint);

                     
    paint.strokeWidth = 3.5;
    const eyeW = 10.0;
    canvas.drawLine(
      Offset(cx - 14 - eyeW, cy - 28),
      Offset(cx - 14 + eyeW, cy - 18),
      paint,
    );
    canvas.drawLine(
      Offset(cx - 14 + eyeW, cy - 28),
      Offset(cx - 14 - eyeW, cy - 18),
      paint,
    );
    canvas.drawLine(
      Offset(cx + 14 - eyeW, cy - 28),
      Offset(cx + 14 + eyeW, cy - 18),
      paint,
    );
    canvas.drawLine(
      Offset(cx + 14 + eyeW, cy - 28),
      Offset(cx + 14 - eyeW, cy - 18),
      paint,
    );

                           
    final triPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final triPath = Path()
      ..moveTo(cx, cy + 42)
      ..lineTo(cx - 10, cy + 30)
      ..lineTo(cx + 10, cy + 30)
      ..close();
    canvas.drawPath(triPath, triPaint);
    canvas.drawLine(Offset(cx, cy + 34), Offset(cx, cy + 38), paint);
    canvas.drawCircle(Offset(cx, cy + 40.5), 1.2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
