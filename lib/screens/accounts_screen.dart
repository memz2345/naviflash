                                   
  
                             
                                                 
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';
import 'package:provider/provider.dart';
import '../services/bilibili_account_service.dart';
import '../services/bilibili_comment_service.dart';
import '../services/network_settings_service.dart';
import '../services/webdav_service.dart';
import '../services/webview_cookie_service.dart';
import '../services/settings_service.dart';
import '../services/native_menu_service.dart';
import '../screens/bilibili_login_screen.dart';
import '../screens/bilibili_login_devices_page.dart';
import '../screens/bilibili_login_log_page.dart';
import '../screens/bili_cookie_scope_page.dart';
import '../screens/bilibili_user_space_page.dart';
import '../screens/bilibili_favorites_page.dart';
import '../screens/webdav_settings_screen.dart';
import '../widgets/expressive_app_bar.dart';
import '../widgets/morph_card.dart';
import '../widgets/more_menu_sheet.dart';
import '../widgets/page_background.dart';
import '../l10n/app_localizations.dart';

class AccountsScreen extends StatefulWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const AccountsScreen({
    super.key,
    this.isSplitView = false,
    this.onBack,
  });

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    showAppToast(context, message);
  }


  Future<void> _openBiliLogin() async {
    final l10n = AppLocalizations.of(context);
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const BilibiliLoginScreen()),
    );
    if (ok == true) _showSnack(l10n.accountsBiliLoginSuccess);
  }

                                                
               
  Future<void> _switchAccount(int index, String uname) async {
    HapticFeedback.lightImpact();
    final service = context.read<BilibiliAccountService>();
    if (index == service.activeIndex) return;
    await service.switchAccount(index);
    if (mounted) _showSnack(uname.isEmpty ? '已切换账号' : '已切换到「$uname」');
  }

                                              
  Future<void> _showAccountMenu(int index) async {
    final service = context.read<BilibiliAccountService>();
    final accounts = service.accounts;
    if (index < 0 || index >= accounts.length) return;
    final acc = accounts[index];
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      title: acc.uname.isEmpty ? 'B 站账号' : acc.uname,
      items: [
        NativeMenuItem(
          text: '切换此账号',
          icon: Icons.swap_horiz_rounded,
          onTap: () => _switchAccount(index, acc.uname),
        ),
        NativeMenuItem(
          text: '删除此账号',
          icon: Icons.delete_outline,
          destructive: true,
          onTap: () => _removeStoredAccount(index, acc.uname),
        ),
      ],
    );
    if (nativeOk || !mounted) return;
    await showAppBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('切换此账号'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _switchAccount(index, acc.uname);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(sheetCtx).colorScheme.error,
              ),
              title: Text(
                '删除此账号',
                style: TextStyle(color: Theme.of(sheetCtx).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _removeStoredAccount(index, acc.uname);
              },
            ),
          ],
        ),
      ),
    );
  }

                                                   
                 
  Future<void> _removeStoredAccount(int index, String uname) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除账号'),
        content: Text(
          '将移除「${uname.isEmpty ? 'B 站账号' : uname}」本地保存的登录 '
          'Cookie，不影响 B 站账号本身；之后可重新登录。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final service = context.read<BilibiliAccountService>();
    await service.removeAccount(index);
    if (mounted) _showSnack('已删除账号');
  }

  Future<void> _logoutBili() async {
    final l10n = AppLocalizations.of(context);
                                 
                                           
    var clearWebview = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountsBiliLogoutTitle),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.accountsBiliLogoutHint),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                value: clearWebview,
                onChanged: (value) =>
                    setDialogState(() => clearWebview = value ?? false),
                title: Text(l10n.accountsClearWebviewCookieTitle),
                subtitle: Text(
                  l10n.accountsClearWebviewCookieSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.accountsLogout),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      await context.read<BilibiliAccountService>().logout();
      if (clearWebview) {
        await WebviewCookieService.clearAllCookies();
      }
      if (mounted) {
        _showSnack(clearWebview
            ? l10n.accountsLoggedOutWithCookie
            : l10n.accountsLoggedOut);
      }
    }
  }

                                             
  Future<void> _clearBrowserCookies() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountsClearCookieTitle),
        content: Text(l10n.accountsClearCookieContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.accountsClearAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final cleared = await WebviewCookieService.clearAllCookies();
    if (mounted) {
      _showSnack(
        cleared
            ? l10n.accountsCookieCleared
            : l10n.accountsCookieEmpty,
      );
    }
  }

  Widget _buildBiliAvatar(ColorScheme cs, String avatarUrl) {
    Widget child;
    if (avatarUrl.isNotEmpty) {
      child = Image.network(
        BilibiliCommentService.avatarUrl(avatarUrl),
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        headers: NetworkSettingsService.instance.apiHeaders.isEmpty
            ? null
            : NetworkSettingsService.instance.apiHeaders,
        errorBuilder: (_, __, ___) => Icon(
          Icons.account_circle,
          size: 24,
          color: cs.onSurfaceVariant,
        ),
      );
    } else {
      child = Icon(Icons.account_circle, size: 24, color: cs.onSurfaceVariant);
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: cs.surfaceContainerHighest,
      child: child,
    );
  }

  List<MorphRowItem> _buildBiliItems(
    BilibiliAccountService account,
    ColorScheme cs,
  ) {
    final l10n = AppLocalizations.of(context);
    if (!account.isLoggedIn) {
      return [
        MorphRowItem(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: _buildBiliAvatar(cs, ''),
            title: Text(l10n.accountsBiliLoginTitle),
            subtitle: Text(
              l10n.accountsBiliLoginSubtitle,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: cs.onSurfaceVariant,
              size: 20,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              _openBiliLogin();
            },
          ),
        ),
        _buildRecommendSourceItem(cs),
                                                          
        if (!Platform.isLinux)
          MorphRowItem(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Icon(Icons.cookie_outlined, size: 26, color: cs.onSurfaceVariant),
              title: Text(l10n.accountsClearBrowserCookie),
              subtitle: Text(
                l10n.accountsClearBrowserCookieSubtitle,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                _clearBrowserCookies();
              },
            ),
          ),
      ];
    }
    final items = <MorphRowItem>[
                                    
      for (var i = 0; i < account.accounts.length; i++)
        i == account.activeIndex
            ? _buildActiveAccountRow(account, cs, l10n)
            : _buildStoredAccountRow(cs, i, account.accounts[i]),
      _buildAddAccountItem(cs),
      MorphRowItem(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Icon(
            Icons.bookmark_add_outlined,
            size: 26,
            color: cs.onSurfaceVariant,
          ),
          title: const Text('B 站收藏夹'),
          subtitle: Text(
            '在线收藏夹（始终携带登录 Cookie）',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: cs.onSurfaceVariant,
            size: 20,
          ),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BilibiliFavoritesPage()),
            );
          },
        ),
      ),
      _buildBiliPageItem(
        cs,
        Icons.phonelink_lock_outlined,
        '账号安全（登录设备）',
        '查看当前登录的设备列表',
        (_) => const BilibiliLoginDevicesPage(),
      ),
      _buildBiliPageItem(
        cs,
        Icons.receipt_long_outlined,
        '登录记录',
        '最近一周的登录 IP 与地点',
        (_) => const BilibiliLoginLogPage(),
      ),
      MorphRowItem(
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: Icon(
            Icons.cookie_outlined,
            size: 26,
            color: cs.onSurfaceVariant,
          ),
          title: Text(l10n.accountsCarryCookie),
          subtitle: Text(
            account.carryCookie
                ? l10n.accountsCarryCookieOn
                : l10n.accountsCarryCookieOff,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          value: account.carryCookie,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            account.setCarryCookie(value);
          },
        ),
      ),
      MorphRowItem(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Icon(
            Icons.tune,
            size: 26,
            color: cs.onSurfaceVariant,
          ),
          title: Text(l10n.accountsCookieScope),
          subtitle: Text(
            l10n.accountsCookieScopeSubtitle,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: cs.onSurfaceVariant,
            size: 20,
          ),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BiliCookieScopePage()),
            );
          },
        ),
      ),
                                                        
      if (!Platform.isLinux)
        MorphRowItem(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Icon(
              Icons.cookie_outlined,
              size: 26,
              color: cs.onSurfaceVariant,
            ),
            title: Text(l10n.accountsClearBrowserCookie),
            subtitle: Text(
              l10n.accountsClearBrowserCookieSubtitle,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              _clearBrowserCookies();
            },
          ),
        ),
      _buildRecommendSourceItem(cs),
    ];
    return items;
  }

                    
  Widget _buildCurrentBadge(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '当前',
        style: TextStyle(
          fontSize: 10,
          height: 1.5,
          fontWeight: FontWeight.w600,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }

                                              
  MorphRowItem _buildActiveAccountRow(
    BilibiliAccountService account,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    return MorphRowItem(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
                                                    
        leading: Hero(
          transitionOnUserGestures: true,
          tag: 'bili_space_avatar_${account.mid}',
          child: _buildBiliAvatar(cs, account.avatarUrl),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                account.uname.isEmpty ? l10n.accountsLoggedIn : account.uname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            _buildCurrentBadge(cs),
          ],
        ),
        subtitle: Text(
          l10n.accountsLoggedInUid(account.mid),
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
            TextButton(
              onPressed: _logoutBili,
              child: Text(l10n.accountsLogout),
            ),
          ],
        ),
                              
        onTap: () {
          if (account.mid <= 0) return;
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BilibiliUserSpacePage(mid: account.mid),
            ),
          );
        },
      ),
    );
  }

                                 
  MorphRowItem _buildStoredAccountRow(
    ColorScheme cs,
    int index,
    BiliStoredAccount acc,
  ) {
    return MorphRowItem(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: _buildBiliAvatar(cs, acc.avatarUrl),
        title: Text(
          acc.uname.isEmpty ? 'B 站账号 ${acc.mid}' : acc.uname,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'UID ${acc.mid}',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert, size: 20, color: cs.onSurfaceVariant),
          tooltip: '更多操作',
          onPressed: () {
            HapticFeedback.lightImpact();
            _showAccountMenu(index);
          },
        ),
        onTap: () => _switchAccount(index, acc.uname),
      ),
    );
  }

                                              
                          
  MorphRowItem _buildAddAccountItem(ColorScheme cs) {
    return MorphRowItem(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: Icon(
          Icons.person_add_alt_1,
          size: 26,
          color: cs.onSurfaceVariant,
        ),
        title: const Text('添加账号'),
        subtitle: Text(
          '扫码 / 粘贴 Cookie / 密码登录新增账号',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: cs.onSurfaceVariant,
          size: 20,
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          _openBiliLogin();
        },
      ),
    );
  }

                                  
  MorphRowItem _buildBiliPageItem(
    ColorScheme cs,
    IconData icon,
    String title,
    String subtitle,
    WidgetBuilder page,
  ) {
    return MorphRowItem(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: Icon(icon, size: 26, color: cs.onSurfaceVariant),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: cs.onSurfaceVariant,
          size: 20,
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(builder: page),
          );
        },
      ),
    );
  }

                               
  MorphRowItem _buildRecommendSourceItem(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return MorphRowItem(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: Icon(Icons.tune, size: 26, color: cs.onSurfaceVariant),
        title: Text(l10n.recommendSourceTitle),
        subtitle: Text(
          _recommendSourceLabel(),
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: cs.onSurfaceVariant,
          size: 20,
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          _showRecommendSourceSheet();
        },
      ),
    );
  }

  String _recommendSourceLabel() {
    final l10n = AppLocalizations.of(context);
    return switch (context.read<SettingsService>().recommendSource) {
      BiliRecommendSource.web => l10n.recommendSourceWeb,
      BiliRecommendSource.app => l10n.recommendSourceApp,
    };
  }

                   
  Future<void> _showRecommendSourceSheet() async {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final settings = context.read<SettingsService>();
    final current = settings.recommendSource;
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      title: l10n.recommendSourceTitle,
      items: [
        for (final source in BiliRecommendSource.values)
          NativeMenuItem(
            text: source == BiliRecommendSource.web
                ? l10n.recommendSourceWeb
                : l10n.recommendSourceApp,
            checked: source == current,
            onTap: () {
              if (source != current) settings.setRecommendSource(source);
            },
          ),
      ],
    );
    if (nativeOk || !mounted) return;
    showAppBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final current = settings.recommendSource;
            return SafeArea(
              child: Material(
                color: cs.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      l10n.recommendSourceTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<BiliRecommendSource>(
                      groupValue: current,
                      onChanged: (v) {
                        if (v == null || v == current) {
                          Navigator.pop(sheetContext);
                          return;
                        }
                        settings.setRecommendSource(v);
                        setSheetState(() {});
                        Navigator.pop(sheetContext);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final source in BiliRecommendSource.values)
                            RadioListTile<BiliRecommendSource>(
                              value: source,
                              title: Text(
                                source == BiliRecommendSource.web
                                    ? l10n.recommendSourceWeb
                                    : l10n.recommendSourceApp,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  Future<void> _openWebDav() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WebDavSettingsScreen()),
    );
  }

  List<MorphRowItem> _buildWebDavItems(WebDavService webdav, ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final configured = webdav.isConfigured;
    return [
      MorphRowItem(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: configured
                ? cs.primaryContainer
                : cs.surfaceContainerHighest,
            child: Icon(
              configured ? Icons.cloud_done_outlined : Icons.cloud_outlined,
              size: 22,
              color: configured ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
          title: Text(l10n.accountsWebdavCloud),
          subtitle: Text(
            configured
                ? (webdav.enabled
                    ? l10n.accountsWebdavConfiguredOn
                    : l10n.accountsWebdavConfiguredOff)
                : l10n.accountsWebdavNotConfigured,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: cs.onSurfaceVariant,
            size: 20,
          ),
          onTap: () {
            HapticFeedback.lightImpact();
            _openWebDav();
          },
        ),
      ),
    ];
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final account = context.watch<BilibiliAccountService>();
    final webdav = context.watch<WebDavService>();

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer),
          CustomScrollView(
            physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),                                                  
            slivers: [
          ExpressiveSliverAppBar(
            title: l10n.accountsTitle,
            expandedHeight: 152,
            leading: widget.isSplitView
                ? null
                : MorphIconButton(
                    tooltip: l10n.commonBackTooltip,
                    icon: Icons.arrow_back,
                    onTap: _handleBack,
                  ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle(context, l10n.accountsSectionBili),
                  const SizedBox(height: 12),
                  ...buildMorphSegmentedList(
                    _buildBiliItems(account, cs),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'WebDAV'),
                  const SizedBox(height: 12),
                  ...buildMorphSegmentedList(
                    _buildWebDavItems(webdav, cs),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}
