// lib/screens/geetest_dialog.dart
//
//   - 加载极验官方 fullpage SDK，内嵌 webview 完成滑块验证
//   - 验证成功后通过 JS 桥把 geetest_challenge / geetest_validate /
//     geetest_seccode 回传，关闭弹窗并返回结果
// 平台：Android/iOS/macOS 用 webview_flutter，Windows 用 webview_windows。
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as win;
import 'package:naviflash/l10n/app_localizations.dart';

/// 弹出极验滑块验证，返回验证结果（含 geetest_challenge/geetest_validate/
/// geetest_seccode），取消或失败返回 null。
Future<Map<String, String>?> showGeetestDialog({
  required BuildContext context,
  required String gt,
  required String challenge,
}) {
  return showDialog<Map<String, String>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => GeetestDialog(gt: gt, challenge: challenge),
  );
}

class GeetestDialog extends StatefulWidget {
  const GeetestDialog({super.key, required this.gt, required this.challenge});

  final String gt;
  final String challenge;

  @override
  State<GeetestDialog> createState() => _GeetestDialogState();
}

class _GeetestDialogState extends State<GeetestDialog> {
  static const _geetestJsUri =
      'https://static.geetest.com/static/js/fullpage.0.0.0.js';

  late final Future<String?> _configFuture;
  WebViewController? _mobileController;
  win.WebviewController? _windowsController;
  bool _mobileReady = false;
  bool _windowsReady = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _configFuture = _fetchConfig();
    if (Platform.isWindows) {
      _initWindows();
    } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      _initMobile();
    }
  }

  @override
  void dispose() {
    _windowsController?.dispose();
    super.dispose();
  }

  /// 请求 gettype.php 获取极验初始化配置（JSONP 格式）。
  Future<String?> _fetchConfig() async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(
        Uri.parse('https://api.geetest.com/gettype.php?gt=${widget.gt}'),
      );
      req.headers.set('User-Agent',
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      final trimmed = body.trim();
      if (!trimmed.startsWith('(') || !trimmed.endsWith(')')) {
        return null;
      }
      final json =
          jsonDecode(trimmed.substring(1, trimmed.length - 1)) as Map;
      if (json['status'] != 'success') return null;
      final data = (json['data'] as Map).cast<String, dynamic>()
        ..addAll({
          'gt': widget.gt,
          'challenge': widget.challenge,
          'offline': false,
          'new_captcha': true,
          'product': 'bind',
          'width': '100%',
          'https': true,
          'protocol': 'https://',
        });
      return jsonEncode(data);
    } catch (e) {
      debugPrint('[Geetest] 获取配置失败: $e');
      return null;
    } finally {
      client.close();
    }
  }

  String _buildHtml(String configJson) {
    return '''
<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width,initial-scale=1.0">
</head><body style="margin:0;padding:0;background:#fff;">
<script src="$_geetestJsUri"></script>
<script>
function __bridge(n, o) {
  var s = n + ':' + JSON.stringify(o);
  try {
    if (window.chrome && window.chrome.webview) { window.chrome.webview.postMessage(s); }
    else if (window.GeetestBridge) { GeetestBridge.postMessage(s); }
  } catch (e) {}
}
var t = Geetest($configJson);
t.onReady(function(){ t.verify(); });
t.onSuccess(function(){ __bridge('success', t.getValidate()); });
t.onError(function(o){ __bridge('error', o); });
t.onClose(function(){ __bridge('close', null); });
</script>
</body></html>
''';
  }

  // ── Windows（webview_windows）──

  Future<void> _initWindows() async {
    final config = await _configFuture;
    if (!mounted) return;
    if (config == null) {
      setState(() => _failed = true);
      return;
    }
    final controller = win.WebviewController();
    try {
      await controller.initialize();
      controller.webMessage.listen((msg) {
        _handleBridgeMessage(msg?.toString() ?? '');
      });
      await controller.loadUrl(
        'data:text/html;base64,${base64Encode(utf8.encode(_buildHtml(config)))}',
      );
      if (!mounted) {
        controller.dispose();
        return;
      }
      _windowsController = controller;
      setState(() => _windowsReady = true);
    } catch (e) {
      debugPrint('[Geetest] Windows webview 初始化失败: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  // ── 移动端 / macOS（webview_flutter）──

  Future<void> _initMobile() async {
    final config = await _configFuture;
    if (!mounted) return;
    if (config == null) {
      setState(() => _failed = true);
      return;
    }
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'GeetestBridge',
        onMessageReceived: (message) {
          _handleBridgeMessage(message.message);
        },
      );
    try {
      await controller.loadHtmlString(_buildHtml(config));
      if (!mounted) return;
      _mobileController = controller;
      setState(() => _mobileReady = true);
    } catch (e) {
      debugPrint('[Geetest] WebView 初始化失败: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  /// 处理 JS 桥消息：`success:<json>` / `error:<json>` / `close:null`。
  void _handleBridgeMessage(String raw) {
    final colon = raw.indexOf(':');
    if (colon <= 0) return;
    final name = raw.substring(0, colon);
    final payload = raw.substring(colon + 1);
    switch (name) {
      case 'success':
        try {
          final data = (jsonDecode(payload) as Map).cast<String, dynamic>();
          final result = <String, String>{
            'geetest_challenge': (data['geetest_challenge'] as String?) ?? '',
            'geetest_validate': (data['geetest_validate'] as String?) ?? '',
            'geetest_seccode': (data['geetest_seccode'] as String?) ?? '',
          };
          if (mounted) Navigator.of(context).pop(result);
        } catch (e) {
          debugPrint('[Geetest] 结果解析失败: $e');
        }
        break;
      case 'close':
        if (mounted) Navigator.of(context).pop();
        break;
      case 'error':
        debugPrint('[Geetest] 验证出错: $payload');
        break;
    }
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(AppLocalizations.of(context).geetestTitle),
      content: SizedBox(
        width: 340,
        height: 420,
        child: _buildBody(cs),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).commonCancel),
        ),
      ],
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: cs.error),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context).geetestInitFailed),
          ],
        ),
      );
    }
    if (Platform.isWindows) {
      if (!_windowsReady || _windowsController == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return win.Webview(_windowsController!);
    }
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      if (!_mobileReady || _mobileController == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return WebViewWidget(controller: _mobileController!);
    }
    return Center(child: Text(AppLocalizations.of(context).geetestUnsupported));
  }
}
