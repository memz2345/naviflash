// lib/screens/bilibili_login_screen.dart
//
//   - 扫码登录：展示二维码，轮询 passport qrcode/poll，成功后自动保存 Cookie
//   - 粘贴 Cookie：从浏览器复制完整 Cookie 字符串校验登录
// 登录成功后 pop(true)，由调用方提示。
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/screens/geetest_dialog.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/glass_bottom_bar.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BilibiliLoginScreen extends StatefulWidget {
  const BilibiliLoginScreen({super.key});

  @override
  State<BilibiliLoginScreen> createState() => _BilibiliLoginScreenState();
}

class _BilibiliLoginScreenState extends State<BilibiliLoginScreen>
    with SingleTickerProviderStateMixin {
  // 0 = 扫码登录，1 = 粘贴 Cookie，2 = 密码登录
  int _mode = 0;
  late TabController _tabController;

  // ── 扫码登录状态 ──
  BiliQrInfo? _qr;
  BiliQrStatus _qrStatus = BiliQrStatus.notScanned;
  String _qrMessage = L10n.current.biliLoginFetchingQr;
  bool _qrLoading = true;
  Timer? _pollTimer;

  // ── 粘贴 Cookie 状态 ──
  final _cookieController = TextEditingController();
  bool _cookieSubmitting = false;

  // ── 密码登录状态 ──
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _pwdSubmitting = false;
  bool _pwdObscure = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: _mode);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_mode != _tabController.index) {
        setState(() => _mode = _tabController.index);
        if (_tabController.index == 0) _fetchQr();
      }
    });
    _fetchQr();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollTimer?.cancel();
    _cookieController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ═════════════════════════════════════
  //  扫码登录
  // ═════════════════════════════════════

  Future<void> _fetchQr() async {
    _pollTimer?.cancel();
    setState(() {
      _qrLoading = true;
      _qr = null;
      _qrStatus = BiliQrStatus.notScanned;
      _qrMessage = AppLocalizations.of(context).biliLoginFetchingQr;
    });
    final qr = await BilibiliAccountService.instance.generateQr();
    if (!mounted) return;
    if (qr == null) {
      setState(() {
        _qrLoading = false;
        _qrStatus = BiliQrStatus.failed;
        _qrMessage = AppLocalizations.of(context).biliLoginQrFetchFailed;
      });
      return;
    }
    setState(() {
      _qr = qr;
      _qrLoading = false;
      _qrStatus = BiliQrStatus.notScanned;
      _qrMessage = AppLocalizations.of(context).biliLoginScanWithApp;
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    final key = _qr?.key;
    if (key == null) return;
    final result = await BilibiliAccountService.instance.pollQr(key);
    if (!mounted) return;
    setState(() {
      _qrStatus = result.status;
      _qrMessage = result.message;
    });
    if (result.status == BiliQrStatus.success) {
      _pollTimer?.cancel();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    } else if (result.status == BiliQrStatus.expired ||
        result.status == BiliQrStatus.failed) {
      _pollTimer?.cancel();
    }
  }

  // ═════════════════════════════════════
  //  粘贴 Cookie
  // ═════════════════════════════════════

  Future<void> _submitCookie() async {
    final raw = _cookieController.text.trim();
    if (raw.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _cookieSubmitting = true);
    // 缺 bili_jct 等不完整情况由 loginWithCookie 返回详细原因
    final result = await BilibiliAccountService.instance.loginWithCookie(raw);
    if (!mounted) return;
    setState(() => _cookieSubmitting = false);
    if (result.ok) {
      Navigator.of(context).pop(true);
    } else {
      _showSnack(result.message);
    }
  }

  // ═════════════════════════════════════
  //  密码登录
  // ═════════════════════════════════════

  Future<void> _loginByPassword() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      _showSnack(AppLocalizations.of(context).biliLoginInputAccountPwd);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _pwdSubmitting = true);
    await _doPasswordLogin(username, password);
  }

  Future<void> _doPasswordLogin(
    String username,
    String password, {
    String? challenge,
    String? validate,
    String? seccode,
    bool geetestRetried = false,
  }) async {
    final result = await BilibiliAccountService.instance.loginWithPassword(
      username: username,
      password: password,
      geeChallenge: challenge,
      geeValidate: validate,
      geeSeccode: seccode,
    );
    if (!mounted) return;
    if (result.success) {
      setState(() => _pwdSubmitting = false);
      Navigator.of(context).pop(true);
      return;
    }
    if (!geetestRetried &&
        result.needGeetest &&
        result.gt != null &&
        result.gt!.isNotEmpty &&
        result.challenge != null &&
        result.challenge!.isNotEmpty) {
      // 需要极验滑块验证：弹窗验证后重试一次
      final geetest = await showGeetestDialog(
        context: context,
        gt: result.gt!,
        challenge: result.challenge!,
      );
      if (!mounted) return;
      if (geetest == null) {
        setState(() => _pwdSubmitting = false);
        return;
      }
      await _doPasswordLogin(
        username,
        password,
        challenge: geetest['geetest_challenge'],
        validate: geetest['geetest_validate'],
        seccode: geetest['geetest_seccode'],
        geetestRetried: true,
      );
      return;
    }
    if (!mounted) return;
    setState(() => _pwdSubmitting = false);
    _showSnack(result.message.isEmpty
        ? AppLocalizations.of(context).biliLoginFailedRetry
        : result.message);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    showAppToast(context, message, error: true);
  }

  // ═════════════════════════════════════
  //  构建
  // ═════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: GlassBottomBar(
            tabs: [
              GlassBottomBarTab(
                label: l10n.biliLoginScanMode,
                icon: Icons.qr_code_2_outlined,
                selectedIcon: Icons.qr_code_2,
              ),
              GlassBottomBarTab(
                label: l10n.biliLoginCookieMode,
                icon: Icons.content_paste_outlined,
                selectedIcon: Icons.content_paste,
              ),
              GlassBottomBarTab(
                label: l10n.biliLoginPwdMode,
                icon: Icons.password_outlined,
                selectedIcon: Icons.password,
              ),
            ],
            selectedIndex: _tabController.index,
            onTabSelected: (i) {
              if (_tabController.index == i) {
                if (i == 0) _fetchQr();
                return;
              }
              _tabController.animateTo(i);
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          const PageBackground(),
          NestedScrollView(
            headerSliverBuilder: (context, _) => [
              ExpressiveSliverAppBar(
                title: l10n.biliLoginTitle,
                leading: MorphIconButton(
                  icon: Icons.arrow_back,
                  tooltip: l10n.commonBackTooltip,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              physics: const ClampingScrollPhysics(),
              children: [
                _buildSwipeTab(
                  cs,
                  onRefresh: () async => _fetchQr(),
                  child: _buildQrMode(cs),
                ),
                _buildSwipeTab(
                  cs,
                  onRefresh: () async =>
                      Future<void>.delayed(const Duration(milliseconds: 400)),
                  child: _buildCookieMode(cs),
                ),
                _buildSwipeTab(
                  cs,
                  onRefresh: () async =>
                      Future<void>.delayed(const Duration(milliseconds: 400)),
                  child: _buildPasswordMode(cs),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeTab(ColorScheme cs,
      {required Future<void> Function() onRefresh, required Widget child}) {
    return RefreshIndicator(
      color: cs.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics:
            const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, 32 + MediaQuery.of(context).padding.bottom + 72),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  child,
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _loginViaBrowser,
                    icon: const Icon(Icons.public, size: 18),
                    label:
                        Text(AppLocalizations.of(context).biliLoginViaBrowser),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context).biliLoginCookieHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 下拉刷新：重新获取当前模式数据（扫码 → 刷新二维码）。
  Future<void> _onPullRefresh() async {
    if (_mode == 0) {
      await _fetchQr();
    } else if (_mode == 2) {
      // 密码模式无刷新动作，稍作等待以展示动画
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }

  /// 打开内置浏览器进行网页版登录；登录完成后自动导入 Cookie。
  Future<void> _loginViaBrowser() async {
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BrowserPage(
          initialUrl: 'https://passport.bilibili.com/login',
          title: AppLocalizations.of(context).biliLoginWebTitle,
          biliLoginMode: true,
          onBiliLoginCookie: (cookie) async {
            final result = await BilibiliAccountService.instance
                .loginWithCookie(cookie);
            if (result.ok && mounted) {
              Navigator.of(context).pop(true);
            }
            return result;
          },
        ),
      ),
    );
    if (!mounted) return;
    if (loggedIn == true) {
      Navigator.of(context).pop(true);
    } else if (loggedIn == null) {
      // 浏览器页未完成导入就返回（可能被系统返回键关闭）
    } else {
      _showSnack(AppLocalizations.of(context).biliLoginCookieImportFailed);
    }
  }

  Widget _buildQrMode(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final Widget qrWidget;
    if (_qrLoading) {
      qrWidget = SizedBox(
        width: 240,
        height: 240,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
        ),
      );
    } else if (_qr == null) {
      qrWidget = SizedBox(
        width: 240,
        height: 240,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 72, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _fetchQr,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.biliLoginRefetch),
            ),
          ],
        ),
      );
    } else {
      qrWidget = GestureDetector(
        onLongPress: () {
          HapticFeedback.lightImpact();
          const msg = '我可是高性能的呢(￣^￣)ゞ';
          final isAndroid = !kIsWeb && Platform.isAndroid;
          if (isAndroid) {
            showAppToast(context, msg);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(msg)),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: _qr!.url,
            version: QrVersions.auto,
            size: 216,
            backgroundColor: Colors.white,
          ),
        ),
      );
    }

    return Column(
      children: [
        // ── 二维码 + 常驻刷新按钮 ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            qrWidget,
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: IconButton.filledTonal(
                tooltip: l10n.biliLoginRefreshQr,
                onPressed: _qrLoading ? null : _fetchQr,
                icon: const Icon(Icons.refresh, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _qrMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color:
                _qrStatus == BiliQrStatus.success ||
                    _qrStatus == BiliQrStatus.scanned
                ? cs.primary
                : cs.onSurfaceVariant,
          ),
        ),
        if (_qrStatus == BiliQrStatus.expired ||
            _qrStatus == BiliQrStatus.failed)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FilledButton.tonalIcon(
              onPressed: _fetchQr,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.biliLoginRefreshQr),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          l10n.biliLoginScanTip,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildCookieMode(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.biliLoginCookieInstruction,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cookieController,
          maxLines: 6,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\n\n'))],
          decoration: InputDecoration(
            hintText: 'SESSDATA=xxx; bili_jct=xxx; DedeUserID=xxx; …',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _cookieSubmitting ? null : _submitCookie,
          icon: _cookieSubmitting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onPrimary,
                  ),
                )
              : const Icon(Icons.login, size: 18),
          label: Text(
            _cookieSubmitting ? l10n.biliLoginVerifying : l10n.biliLoginVerifyAndLogin,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordMode(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _usernameController,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: l10n.biliLoginAccountLabel,
            prefixIcon: const Icon(Icons.person_outline, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _pwdObscure,
          autocorrect: false,
          enableSuggestions: false,
          onSubmitted: (_) => _loginByPassword(),
          decoration: InputDecoration(
            labelText: l10n.biliLoginPasswordLabel,
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _pwdObscure ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () => setState(() => _pwdObscure = !_pwdObscure),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _pwdSubmitting ? null : _loginByPassword,
          icon: _pwdSubmitting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onPrimary,
                  ),
                )
              : const Icon(Icons.login, size: 18),
          label: Text(
            _pwdSubmitting ? l10n.biliLoginLoggingIn : l10n.biliLoginLoginAction,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.biliLoginSliderHint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
