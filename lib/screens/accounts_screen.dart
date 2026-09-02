// lib/screens/accounts_screen.dart
//
// 账号页：B 站账号 + WebDAV 账号入口汇总。
// 使用 ExpressiveSliverAppBar + morph_card 分段卡片布局，
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:provider/provider.dart';
import '../services/bilibili_account_service.dart';
import '../services/bilibili_comment_service.dart';
import '../services/network_settings_service.dart';
import '../services/webdav_service.dart';
import '../services/webview_cookie_service.dart';
import '../services/settings_service.dart';
import '../screens/bilibili_login_screen.dart';
import '../screens/bili_cookie_scope_page.dart';
import '../screens/bilibili_user_space_page.dart';
import '../screens/bilibili_favorites_page.dart';
import '../screens/webdav_settings_screen.dart';
import '../widgets/expressive_app_bar.dart';
import '../widgets/morph_card.dart';
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

  Future<void> _logoutBili() async {
    final l10n = AppLocalizations.of(context);
    // 退出确认：可选「同时清空内置浏览器 Cookie」；
    // 本次不勾选也可以退出，之后仍可在账号设置里手动清除浏览器 Cookie。
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

  /// 手动清空内置浏览器 Cookie（未登录时也可用，用于清除网页端残留登录态）。
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
    return [
      MorphRowItem(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          // 头像 Hero：与 BilibiliUserSpacePage 头部头像同 tag
          leading: Hero(
            tag: 'bili_space_avatar_${account.mid}',
            child: _buildBiliAvatar(cs, account.avatarUrl),
          ),
          title: Text(
            account.uname.isEmpty ? l10n.accountsLoggedIn : account.uname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
          // 点击行 → 打开自己的 B 站空间主页
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
      ),
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
  }

  /// 推荐数据来源（Web 端 / APP 端）设置项。
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

  /// 推荐数据来源选择底部弹层。
  void _showRecommendSourceSheet() {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final settings = context.read<SettingsService>();
    showModalBottomSheet<void>(
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
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
          ExpressiveSliverAppBar(
            title: l10n.accountsTitle,
            expandedHeight: 120,
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
