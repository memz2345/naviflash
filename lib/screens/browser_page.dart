//飞萤扑火，向死而生
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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

Future<void> showNativeToast(String message) async {
  await NativeBridge.showToast(message);
}

Future<void> showPlatformAppropriateMessage(
  BuildContext context,
  String message,
) async {
  assert(message.isNotEmpty);
  if (Platform.isAndroid) {
    await showNativeToast(message);
  } else {
    if (!context.mounted) return;
    showAppToast(context, message);
  }
}

// ══════════════════════════════════════════════════════════════════
//  仅替换 UA 中的设备关键字，保留 Chrome/WebKit/版本号等其余内容）
// ══════════════════════════════════════════════════════════════════

/// 判断 UA 是否为手机端（含 Android / iPhone / iPad / Mobile / Mobi）。
bool _isMobileUa(String ua) {
  final lower = ua.toLowerCase();
  return lower.contains('android') ||
      lower.contains('iphone') ||
      lower.contains('ipad') ||
      lower.contains('mobile') ||
      lower.contains('mobi');
}

/// 替换 UA 里第一个括号内的平台段（`(Windows NT ...; ...)` 等）。
String _replacePlatformSegment(String ua, String replacement) {
  final start = ua.indexOf('(');
  if (start < 0) return ua;
  final end = ua.indexOf(')', start + 1);
  if (end < 0) return ua;
  return ua.replaceRange(start, end + 1, '($replacement)');
}

/// 移除 UA 里的 Mobile 标记（如 " Mobile"、" Mobile/15E148"）。
String _stripMobileMarkers(String ua) => ua.replaceAll(
      RegExp(r'\s+Mobile(?:/[0-9A-Za-z.\-]+)?\b', caseSensitive: false),
      '',
    );

/// 在 Safari 前补上 Mobile 标记（Chrome 系 → "Mobile Safari/..."；
/// Safari 系 → "Version/x Mobile/... Safari/..."，这里统一加 " Mobile"）。
String _addMobileMarkers(String ua) {
  if (RegExp(r'\bMobile\b', caseSensitive: false).hasMatch(ua)) return ua;
  final idx = ua.indexOf(' Safari/');
  if (idx >= 0) return ua.replaceRange(idx, idx + 1, ' Mobile Safari/');
  return ua;
}

/// 把 UA 切换为手机端（已是手机端则原样返回）。
String uaToMobile(String ua) {
  if (ua.isEmpty || _isMobileUa(ua)) return ua;
  final seg = ua.contains('Macintosh')
      ? 'iPhone; CPU iPhone OS 16_0 like Mac OS X'
      : 'Linux; Android 13; Pixel 7';
  return _addMobileMarkers(_replacePlatformSegment(ua, seg));
}

/// 把 UA 切换为电脑端（已是电脑端则原样返回）。
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

  /// 哔哩哔哩网页登录模式：轮询检测登录状态，登录成功后顶栏出现
  /// 「导入登录状态」按钮，读取 webview 完整 Cookie（含 HttpOnly）后回调。
  final bool biliLoginMode;

  /// 导入回调：参数为拼接好的 Cookie 字符串，返回是否导入成功及失败原因。
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
  bool _isFirstLoad = true;
  String? _currentTitle;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _hasInitError = false;
  bool _allowClipboardAccess = true;
  bool _clipboardPrefLoaded = false;
  /// 内置浏览器 UA 模式（自动 / 电脑端 / 手机端），常态化保存。
  BrowserUaMode _uaMode = BrowserUaMode.auto;
  /// 未做手机/电脑端替换的基准 UA：用户设置的 UA（NetworkSettingsService），
  /// 未设置时为 webview 默认 UA（首次加载后读取）。
  String? _baseUa;
  /// 页面生命周期内捕获的根 ScaffoldMessenger，用于页面销毁时清掉本页
  /// 仍显示的 SnackBar（如「打开 xx 应用」提示），避免残留到下层页面。
  /// 不能用 dispose 里直接 ScaffoldMessenger.of(context)（依赖查找在
  /// dispose 阶段不安全），故在 didChangeDependencies 中提前捕获。
  ScaffoldMessengerState? _messenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
    // 持久化剪贴板权限：首次打开时读取用户上次保存的选择。
    // Provider 在本页面入栈前已就绪（MyApp 根 MultiProvider），可安全访问。
    if (!_clipboardPrefLoaded) {
      _clipboardPrefLoaded = true;
      final settings = context.read<SettingsService>();
      if (_allowClipboardAccess != settings.browserAllowClipboard) {
        _allowClipboardAccess = settings.browserAllowClipboard;
      }
    }
  }

  // ── B 站网页登录模式状态 ──
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
    // 先加载持久化的 UA 模式，供 _initWindows / _initNativeWebView 应用
    // （didChangeDependencies 在 initState 之后才执行，此处必须提前读取）
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
      // 方式一：JSONP 探测 nav 接口（受页面 CSP 等影响可能不生效）
      try {
        if (Platform.isWindows) {
          await _windowsController?.executeScript(_biliNavCheckJs);
        } else {
          await _webviewController?.runJavaScript(_biliNavCheckJs);
        }
      } catch (_) {}
      // 方式二：直接读 document.cookie。bili_jct 为非 HttpOnly Cookie，
      // 网页登录成功后会由前端 JS 写入，可作为可靠的兜底登录信号。
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

  /// 读取 webview 当前页面的 document.cookie（不含 HttpOnly）。
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
              // 未设置自定义 UA 且启用了手机/电脑端模式时，按 webview 默认 UA
              // 替换关键字后应用（首次加载后执行一次）
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
                _isFirstLoad = false;
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
          _isFirstLoad = false;
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
                  if (mounted)
                    showPlatformAppropriateMessage(
                      context,
                      AppLocalizations.of(context).browserCookieCopied,
                    );
                } else {
                  if (mounted)
                    showPlatformAppropriateMessage(
                      context,
                      AppLocalizations.of(context).browserCookieEmpty,
                    );
                }
                if (mounted) Navigator.of(dialogContext).pop();
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
    // 对话框设置的自定义 UA 作为后续手机/电脑端切换的基准
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

  // ── 手机端 / 电脑端 UA 模式（仅替换用户设置的 UA 关键字） ──

  /// 按当前 UA 模式把基准 UA 套用为生效 UA；基准为空则返回空（交给 webview 默认）。
  String _effectiveUa(String baseUa) {
    if (baseUa.isEmpty) return '';
    return switch (_uaMode) {
      BrowserUaMode.auto => baseUa,
      BrowserUaMode.desktop => uaToDesktop(baseUa),
      BrowserUaMode.mobile => uaToMobile(baseUa),
    };
  }

  /// 读取 webview 当前生效的 UA 字符串。
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

  /// 兜底：把 webview 当前生效 UA 记为基准 UA（未设置自定义 UA 时使用）。
  Future<void> _readBaseUaFromWebview() async {
    final ua = await _readWebviewUa();
    if (ua != null && ua.isNotEmpty) _baseUa = ua;
  }

  /// 首次加载完成后，若未设置自定义 UA 且启用了手机/电脑端模式，
  /// 用 webview 默认 UA 作为基准做关键字替换并应用（只执行一次）。
  Future<void> _syncBaseUaIfNeeded() async {
    if (_baseUa != null && _baseUa!.isNotEmpty) return;
    if (_uaMode == BrowserUaMode.auto) return;
    final ua = await _readWebviewUa();
    if (ua == null || ua.isEmpty) return;
    _baseUa = ua;
    final effective = _effectiveUa(ua);
    if (effective == ua) return; // 已是目标模式，无需变更
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

  /// 切换手机端 / 电脑端 / 自动 UA 模式：替换关键字 → 应用并刷新，常态化保存。
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
      // 注册到全局 Cookie 清理服务（退出登录时可选清空浏览器 Cookie）
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
          // 未设置自定义 UA 且启用了手机/电脑端模式时，按 webview 默认 UA
          // 替换关键字后应用（首次加载后执行一次）
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
            _isFirstLoad = false;

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
          _isFirstLoad = false;
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
    // 页面销毁时清掉仍显示的 SnackBar（如「打开 xx 应用」提示），
    // 避免它残留到下层页面继续展示
    _messenger?.removeCurrentSnackBar();
    // 注销全局 Cookie 清理引用（若仍是本页注册的控制器）
    if (identical(WebviewCookieService.windowsController, _windowsController)) {
      WebviewCookieService.registerWindowsController(null);
    }
    _windowsController?.dispose();
    super.dispose();
  }

  // ── B 站网页登录：读取 webview 完整 Cookie 并导入 ──

  /// Windows：解析 CDP Network.getAllCookies 返回的 JSON，拼成 Cookie 串。
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

  /// 抓取当前 webview 的 B 站登录 Cookie（Windows 走 CDP，可含 HttpOnly）。
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
    // iOS / macOS：无 CookieManager 读取能力，退回 document.cookie
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
      // 持久化剪贴板权限，下次打开浏览器保持用户选择
      try {
        final settings = context.read<SettingsService>();
        await settings.setBrowserAllowClipboard(_allowClipboardAccess);
      } catch (e) {
        debugPrint('Failed to persist clipboard permission: $e');
      }
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
      if (currentUrl != null && currentUrl.isNotEmpty) {
        _showQrCodeDialog(currentUrl);
      } else {
        if (mounted)
          showPlatformAppropriateMessage(
            context,
            AppLocalizations.of(context).browserNoCurrentUrl,
          );
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
          showPlatformAppropriateMessage(
            context,
            AppLocalizations.of(context).browserTroubleshootFailed,
          );
        }
        break;
      case 'copy':
        if (currentUrl != null) {
          await Clipboard.setData(ClipboardData(text: currentUrl));
          showPlatformAppropriateMessage(
            context,
            AppLocalizations.of(context).scanLinkCopied,
          );
        }
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
        if (currentUrl != null) {
          final uri = Uri.parse(currentUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            showPlatformAppropriateMessage(
              context,
              AppLocalizations.of(context).browserSystemBrowserMissing,
            );
          }
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
                      Navigator.of(dialogContext).pop();
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
      onPopInvoked: (bool didPop) {
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
                Tooltip(
                  message: l10n.commonBackTooltip,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(24),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.arrow_back, size: 25),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: l10n.browserStopLoading,
                  child: InkWell(
                    onTap: _isLoading ? _stopLoading : null,
                    borderRadius: BorderRadius.circular(24),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.close, size: 25),
                    ),
                  ),
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
                // UA 模式：手机端 / 电脑端（仅替换用户设置的 UA 关键字，常态化保存）
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
    return RefreshIndicator(
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
                    color: colorScheme.error.withOpacity(0.85),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context).browserAndroidErrorTitle,
                style: TextStyle(
                  color: colorScheme.error.withOpacity(0.85),
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No command.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
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
    final colorScheme = Theme.of(context).colorScheme;
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
                    color: textColor.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: textColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).browserAppleErrorReport,
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context).browserAppleErrorDetail,
                        style: TextStyle(
                          color: textColor.withOpacity(0.5),
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
                  color: textColor.withOpacity(0.8),
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
                            color: textColor.withOpacity(0.9),
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
          if (mounted)
            showPlatformAppropriateMessage(
              context,
              AppLocalizations.of(context).browserCantOpenExternal,
            );
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
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
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
            color: Colors.white.withOpacity(0.65),
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

    // Body
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

    // Head (rounded top)
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

    // Antennae
    paint.strokeWidth = 3;
    canvas.drawLine(Offset(cx - 10, cy - 36), Offset(cx - 16, cy - 52), paint);
    canvas.drawLine(Offset(cx + 10, cy - 36), Offset(cx + 16, cy - 52), paint);

    // Eyes - X marks
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

    // Exclamation triangle
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
