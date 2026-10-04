                                         
  
                                                        
                                        
                          
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/screens/geetest_dialog.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/liquid_glass_bar_service.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/glass_bottom_bar.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/navi_spring_physics.dart';

class BilibiliLoginScreen extends StatefulWidget {
  const BilibiliLoginScreen({super.key});

  @override
  State<BilibiliLoginScreen> createState() => _BilibiliLoginScreenState();
}

class _BilibiliLoginScreenState extends State<BilibiliLoginScreen>
    with SingleTickerProviderStateMixin, RouteAware {
                                              
  int _mode = 0;
  late TabController _tabController;

                                     
                                     
  static const List<String> _modeIds = <String>['qr', 'cookie', 'pwd', 'sms'];

                 
  BiliQrInfo? _qr;
  BiliQrStatus _qrStatus = BiliQrStatus.notScanned;
  String _qrMessage = L10n.current.biliLoginFetchingQr;
  bool _qrLoading = true;
  Timer? _pollTimer;

                       
  final _cookieController = TextEditingController();
  bool _cookieSubmitting = false;

                 
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _pwdSubmitting = false;
  bool _pwdObscure = true;

                  
  String _smsCid = '86';
  final _smsTelController = TextEditingController();
  final _smsCodeController = TextEditingController();
  bool _smsSending = false;            
  bool _smsSubmitting = false;         
  int _smsCountdown = 0;                    
  Timer? _smsCountdownTimer;
  String? _smsRecaptchaToken;                                   
  bool _smsGeetestRetried = false;                

                             
                                                             
                                           
  bool _isTopRoute = true;
  bool _nativeBarShown = false;
  String? _nativeBarKey;
  int? _nativeBarIndex;
  ModalRoute<dynamic>? _nativeBarRoute;

  @override
  void initState() {
    super.initState();
                                                       
                       
    final tabCount = Platform.isLinux ? 2 : 4;
    _tabController = TabController(
        length: tabCount, vsync: this, initialIndex: _mode);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final i = _tabController.index;
      if (_mode != i) {
        setState(() => _mode = i);
        if (i == 0) _fetchQr();
                                 
        unawaited(LiquidGlassBarService.refresh(force: true));
      }
    });
                                        
    LiquidGlassBarService.bindTabSelected(_onBarTabSelected);
  }

                                                 
  bool _qrRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _nativeBarRoute) {
      if (_nativeBarRoute != null) {
        liquidGlassBarRouteObserver.unsubscribe(this);
      }
      _nativeBarRoute = route;
      liquidGlassBarRouteObserver.subscribe(this, route);
                                              
                                                 
                                            
      _isTopRoute = route.isCurrent;
    }
                                                    
                                                          
                                                                      
                                                   
    if (!_qrRequested) {
      _qrRequested = true;
      _fetchQr();
    }
  }

                                    
  @override
  void didPushNext() {
    _isTopRoute = false;
    _hideNativeBar();
  }

                             
  @override
  void didPopNext() {
    _isTopRoute = true;
    if (mounted) setState(() {});
  }

                       
     
                                                       
                                                    
                                                           
  void _hideNativeBar() {
    if (!_nativeBarShown) return;
    _nativeBarShown = false;
    _nativeBarKey = null;
    _nativeBarIndex = null;
    debugPrint('[glassbar] hide（登录页被盖住 / 销毁）');
    unawaited(LiquidGlassBarService.hide());
  }

  @override
  void dispose() {
    liquidGlassBarRouteObserver.unsubscribe(this);
    _nativeBarRoute = null;
                                       
                                                                
                                                        
                                          
    LiquidGlassBarService.unbindTabSelected(_onBarTabSelected);
    if (LiquidGlassBarService.ownsVisibleBar(_onBarTabSelected)) {
      unawaited(LiquidGlassBarService.hide());
    }
    _tabController.dispose();
    _pollTimer?.cancel();
    _smsCountdownTimer?.cancel();
    _cookieController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _smsTelController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

                                          
          
                                          

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

                                          
               
                                          

  Future<void> _submitCookie() async {
    final raw = _cookieController.text.trim();
    if (raw.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _cookieSubmitting = true);
                                                
    final result = await BilibiliAccountService.instance.loginWithCookie(raw);
    if (!mounted) return;
    setState(() => _cookieSubmitting = false);
    if (result.ok) {
      Navigator.of(context).pop(true);
    } else {
      _showSnack(result.message);
    }
  }

                                          
          
                                          

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

                                          
           
                                          

                                       
  Future<void> _sendSmsCode() async {
    final tel = _smsTelController.text.trim();
    if (tel.isEmpty) {
      _showSnack('请输入手机号');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _smsSending = true;
      _smsGeetestRetried = false;
      _smsRecaptchaToken = null;
    });
    await _doSendSmsCode(tel);
  }

  Future<void> _doSendSmsCode(
    String tel, {
    String? challenge,
    String? validate,
    String? seccode,
  }) async {
    final result = await BilibiliAccountService.instance.sendSmsLoginCode(
      cid: _smsCid,
      tel: tel,
      recaptchaToken: challenge != null ? _smsRecaptchaToken : null,
      geeChallenge: challenge,
      geeValidate: validate,
      geeSeccode: seccode,
    );
    if (!mounted) return;
    if (result.success) {
      setState(() => _smsSending = false);
      _startSmsCountdown();
      showAppToast(context, '验证码已发送，请查收');
      return;
    }
    if (!_smsGeetestRetried &&
        result.needGeetest &&
        result.gt != null &&
        result.gt!.isNotEmpty &&
        result.challenge != null &&
        result.challenge!.isNotEmpty) {
                           
      _smsRecaptchaToken = result.recaptchaToken;
      final geetest = await showGeetestDialog(
        context: context,
        gt: result.gt!,
        challenge: result.challenge!,
      );
      if (!mounted) return;
      if (geetest == null) {
                        
        setState(() => _smsSending = false);
        return;
      }
      _smsGeetestRetried = true;
      await _doSendSmsCode(
        tel,
        challenge: geetest['geetest_challenge'],
        validate: geetest['geetest_validate'],
        seccode: geetest['geetest_seccode'],
      );
      return;
    }
    setState(() => _smsSending = false);
    _showSnack(result.message.isEmpty ? '验证码发送失败，请稍后重试' : result.message);
  }

  void _startSmsCountdown() {
    _smsCountdownTimer?.cancel();
    setState(() => _smsCountdown = 60);
    _smsCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _smsCountdown = 60 - timer.tick);
      if (_smsCountdown <= 0) timer.cancel();
    });
  }

  Future<void> _loginBySms() async {
    final tel = _smsTelController.text.trim();
    final code = _smsCodeController.text.trim();
    if (tel.isEmpty) {
      _showSnack('请输入手机号');
      return;
    }
    if (code.isEmpty) {
      _showSnack('请输入短信验证码');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _smsSubmitting = true);
    final result = await BilibiliAccountService.instance.loginWithSmsCode(
      cid: _smsCid,
      tel: tel,
      code: code,
    );
    if (!mounted) return;
    if (result.success) {
      setState(() => _smsSubmitting = false);
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _smsSubmitting = false);
    _showSnack(result.message.isEmpty ? '登录失败，请重试' : result.message);
  }

                                          
        
                                          

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
                                          
      floatingActionButton: _mode == 0
          ? null
          : FloatingActionButton.extended(
              heroTag: 'login_submit_fab',
              onPressed: _submitCurrent,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_busy ? '登录中…' : '登录'),
            ),
      extendBody: true,
      bottomNavigationBar: _buildLoginBottomBar(l10n),
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
            body: naviTabBarView(
              controller: _tabController,
                                                     
                                           
              physics: const AppRefreshScrollPhysics(
                parent: NaviTabBarViewScrollPhysics(),
              ),
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
                                 
                if (!Platform.isLinux)
                  _buildSwipeTab(
                    cs,
                    onRefresh: () async =>
                        Future<void>.delayed(const Duration(milliseconds: 400)),
                    child: _buildPasswordMode(cs),
                  ),
                                  
                if (!Platform.isLinux)
                  _buildSwipeTab(
                    cs,
                    onRefresh: () async =>
                        Future<void>.delayed(const Duration(milliseconds: 400)),
                    child: _buildSmsMode(cs),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

                                          
                               
                                          

             
     
                                                    
                           
  List<GlassBottomBarTab> _loginTabs(AppLocalizations l10n) => <GlassBottomBarTab>[
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
                                      
    if (!Platform.isLinux)
      GlassBottomBarTab(
        label: l10n.biliLoginPwdMode,
        icon: Icons.password_outlined,
        selectedIcon: Icons.password,
      ),
                                        
    if (!Platform.isLinux)
      GlassBottomBarTab(
        label: '验证码登录',
        icon: Icons.sms_outlined,
        selectedIcon: Icons.sms,
      ),
  ];

                                         
                                            
  Widget _buildLoginBottomBar(AppLocalizations l10n) {
    final tabs = _loginTabs(l10n);
    final useNative = LiquidGlassBarService.canUseNative;
                                         
                            
    _syncNativeBar(visible: useNative, tabs: tabs);
    if (useNative) {
      return SizedBox(height: LiquidGlassBarService.slotHeight(context));
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: AppBottomBar(
          tabs: tabs,
          selectedIndex: _tabController.index,
          onTabSelected: _onBarTabSelected,
        ),
      ),
    );
  }

                                
  void _onBarTabSelected(int i) {
    if (_tabController.index == i) {
      if (i == 0) _fetchQr();
      return;
    }
    _tabController.animateTo(i);
  }

                           
     
                                                   
                                                 
  void _syncNativeBar({
    required bool visible,
    required List<GlassBottomBarTab> tabs,
  }) {
                                                     
                                        
                                              
                                    
    if (!visible || !_isTopRoute) {
      _hideNativeBar();
      return;
    }
    LiquidGlassBarService.refresh();
    final index = _tabController.index.clamp(0, tabs.length - 1);
                                            
                           
    final size = MediaQuery.sizeOf(context);
    final key =
        '${tabs.length}|${tabs.map((t) => t.label).join(',')}|'
        '${size.width.round()}x${size.height.round()}';
    if (_nativeBarShown && _nativeBarKey == key && _nativeBarIndex == index) {
      return;
    }
    final needShow = !_nativeBarShown || _nativeBarKey != key;
    _nativeBarKey = key;
    _nativeBarIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (needShow) {
        final ok = await LiquidGlassBarService.show(
          context: context,
          tabs: [
            for (int i = 0; i < tabs.length; i++)
              LiquidGlassBarTab(
                id: i < _modeIds.length ? _modeIds[i] : 'tab$i',
                label: tabs[i].label,
                icon: tabs[i].icon,
                selectedIcon: tabs[i].selectedIcon,
              ),
          ],
          index: index,
          accent: Theme.of(context).colorScheme.primary,
        );
        if (!ok) {
                                             
          LiquidGlassBarService.enabled = false;
          if (mounted) setState(() {});
          return;
        }
        _nativeBarShown = true;
      } else {
        await LiquidGlassBarService.updateIndex(index);
      }
      await LiquidGlassBarService.refresh(force: true);
    });
  }

  Widget _buildSwipeTab(ColorScheme cs,
      {required Future<void> Function() onRefresh, required Widget child}) {
    return AppRefreshIndicator(
      color: cs.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics:
            const AppRefreshScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                                                 
                  if (!Platform.isLinux) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _loginViaBrowser,
                      icon: const Icon(Icons.public, size: 18),
                      label:
                          Text(AppLocalizations.of(context).biliLoginViaBrowser),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

                 
  bool get _busy => switch (_mode) {
    1 => _cookieSubmitting,
    2 => _pwdSubmitting,
    3 => _smsSubmitting,
    _ => false,
  };

                        
  void _submitCurrent() {
    switch (_mode) {
      case 1:
        if (!_cookieSubmitting) _submitCookie();
      case 2:
        if (!_pwdSubmitting) _loginByPassword();
      case 3:
        if (!_smsSubmitting) _loginBySms();
    }
  }

                                      
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
                                 
    } else {
      _showSnack(AppLocalizations.of(context).biliLoginCookieImportFailed);
    }
  }

  Widget _buildQrMode(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final Widget qrWidget;
    if (_qrLoading) {
      qrWidget = const SizedBox(
        width: 240,
        height: 240,
        child: Center(
          child: LoadingIndicatorM3E(),
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
          showAppToast(context, msg);
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
                                          
        Center(child: qrWidget),
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
      ],
    );
  }

  Widget _buildCookieMode(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        const SizedBox(height: 8),
        Text(
          l10n.biliLoginSliderHint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildSmsMode(ColorScheme cs) {
    final canSend = !_smsSending && _smsCountdown <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                         
        Row(
          children: [
            SizedBox(
              width: 100,
                                                      
                                                  
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '区号',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: MorphGlassDropdown<String>(
                  value: _smsCid,
                  menuWidth: 160,
                  items: const [
                    DropdownMenuItem(value: '86', child: Text('+86')),
                    DropdownMenuItem(value: '1', child: Text('+1')),
                    DropdownMenuItem(value: '44', child: Text('+44')),
                    DropdownMenuItem(value: '81', child: Text('+81')),
                    DropdownMenuItem(value: '852', child: Text('+852')),
                    DropdownMenuItem(value: '886', child: Text('+886')),
                  ],
                  onChanged: (v) {
                    if (v != null && v != _smsCid) {
                      setState(() => _smsCid = v);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _smsTelController,
                keyboardType: TextInputType.phone,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: '手机号',
                  prefixIcon: const Icon(Icons.phone_iphone_outlined, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
                           
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _smsCodeController,
                keyboardType: TextInputType.number,
                autocorrect: false,
                enableSuggestions: false,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _loginBySms(),
                decoration: InputDecoration(
                  labelText: '验证码',
                  counterText: '',
                  prefixIcon: const Icon(Icons.sms_outlined, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 58,
              child: OutlinedButton(
                onPressed: canSend ? _sendSmsCode : null,
                child: _smsSending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      )
                    : Text(
                        _smsCountdown > 0
                            ? '重新获取(${_smsCountdown}s)'
                            : '获取验证码',
                        style: const TextStyle(fontSize: 13),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
