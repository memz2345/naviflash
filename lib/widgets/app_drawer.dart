// lib/widgets/app_drawer.dart
//
// 传统抽屉（AppDrawer）：NaviFlash 全局侧边栏。
// 原为 Navi 本地账号体系；现按 PiliPlus/主页需求改造成 B 站版：
//   - 可拉伸头部：B 站账号背景（个性/粉丝装扮 top_photo → 头像模糊兜底）
//     + 账号信息前景（头像挂件 / 昵称 / UID / 粉丝装扮编号徽章 / 登录 CTA）
//   - 菜单（胶囊样式）：主页 / 离线缓存 / 观看记录 / 订阅 / 稍后再看 / 设置
//   - 从本抽屉打开的页面以「抽屉模式」进入：顶栏左侧显示菜单按钮（可再次
//     打开本抽屉），而不是返回箭头 —— 与设置页 standalone 行为一致。
// 顶层主页（推荐流）与这些页面各自 Scaffold 挂 drawer: AppDrawer(currentPage:...)。
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/screens/my_cache_page.dart';
import 'package:naviflash/screens/settings_split_screen.dart';
import 'package:naviflash/screens/watch_history_page.dart';
import 'package:naviflash/screens/bilibili_watch_later_page.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/fans_medal_badge.dart';
import 'package:naviflash/widgets/pendant_avatar.dart';

import '../build_info.g.dart';
import '../services/device.dart';

/// 全局 B 站版侧边栏。
class AppDrawer extends StatelessWidget {
  /// 当前所在页 id（'home' / 'cache' / 'history' / 'watchlater' /
  /// 'subscribe' / 'settings' / 'space'），用于高亮菜单项。
  final String currentPage;

  const AppDrawer({super.key, this.currentPage = 'home'});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 304,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ── 可拉伸头部：背景层（zoom/blur）+ 前景账号层 ──
          SliverAppBar(
            expandedHeight: 272.0,
            pinned: false,
            floating: false,
            stretch: true,
            stretchTriggerOffset: 60,
            elevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: _DrawerAccountHeader(
                currentPage: currentPage,
              ),
            ),
          ),
          // ── 菜单项 ──
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 10),
              _item(
                context,
                icon: Icons.home_rounded,
                title: '主页',
                pageId: 'home',
                onTap: () => _navTo(context, 'home'),
              ),
              _item(
                context,
                icon: Icons.download_rounded,
                title: '离线缓存',
                pageId: 'cache',
                onTap: () => _navTo(context, 'cache'),
              ),
              _item(
                context,
                icon: Icons.history_rounded,
                title: '观看记录',
                pageId: 'history',
                onTap: () => _navTo(context, 'history'),
              ),
              _item(
                context,
                icon: Icons.subscriptions_outlined,
                title: '订阅',
                pageId: 'subscribe',
                onTap: () => _navTo(context, 'subscribe'),
              ),
              _item(
                context,
                icon: Icons.watch_later_outlined,
                title: '稍后再看',
                pageId: 'watchlater',
                onTap: () => _navTo(context, 'watchlater'),
              ),
              const SizedBox(height: 14),
              _item(
                context,
                icon: Icons.settings_outlined,
                title: AppLocalizations.of(context).drawerSettings,
                pageId: 'settings',
                onTap: () => _navTo(context, 'settings'),
              ),
              const SizedBox(height: 18),
            ]),
          ),
        ],
      ),
    );
  }

  /// 关闭抽屉并按页跳转；本抽屉进入的页面以「抽屉模式」打开
  /// （顶栏为菜单按钮，可再开本抽屉）。
  void _navTo(BuildContext context, String pageId) {
    if (pageId == currentPage) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context);
    switch (pageId) {
      case 'home':
        Navigator.of(context).popUntil((r) => r.isFirst);
      case 'cache':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const MyCachePage(drawerMode: true),
          ),
        );
      case 'history':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const WatchHistoryPage(drawerMode: true),
          ),
        );
      case 'watchlater':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const BilibiliWatchLaterPage(drawerMode: true),
          ),
        );
      case 'subscribe':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('订阅功能开发中，敬请期待')),
        );
      default:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SplitSettingsScreen(isStandalone: true),
          ),
        );
    }
  }

  /// 菜单项（胶囊形；选中态主色填充，与旧版抽屉一致）。
  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String pageId,
    required VoidCallback onTap,
  }) {
    final isSelected = currentPage == pageId;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? cs.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 可拉伸头部：账号背景（装扮/头像模糊）+ 前景信息层（可滚动伸展时
/// 背景被拉伸模糊，前景保持清晰，与旧版抽屉观感一致）。
class _DrawerAccountHeader extends StatefulWidget {
  final String currentPage;

  const _DrawerAccountHeader({required this.currentPage});

  @override
  State<_DrawerAccountHeader> createState() => _DrawerAccountHeaderState();
}

class _DrawerAccountHeaderState extends State<_DrawerAccountHeader> {
  /// 会话级缓存：同一账号只拉一次个人空间卡片（装扮背景 / 挂件 / 粉丝装扮）。
  static BiliUserSpaceCard? _cachedCard;
  static int _cachedMid = 0;
  static bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCardIfNeeded();
  }

  Future<void> _loadCardIfNeeded() async {
    final account = BilibiliAccountService.instance;
    if (!account.isLoggedIn || _loading) return;
    if (_cachedCard != null && _cachedMid == account.mid) return;
    _loading = true;
    final card = await BilibiliUserSpaceService.fetchUserCard(
      mid: account.mid,
    );
    _loading = false;
    if (!mounted) return;
    if (card != null) {
      _cachedCard = card;
      _cachedMid = account.mid;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: BilibiliAccountService.instance,
      builder: (context, _) {
        final account = BilibiliAccountService.instance;
        final logged = account.isLoggedIn;
        final card = _cachedCard;
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // ── 背景层：装扮背景图（top_photo）→ 头像模糊 → 主题渐变 ──
                _buildBackground(cs),
                // 底部渐变：让头部内容（白字）与下方列表衔接
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.12),
                        Colors.transparent,
                        cs.surfaceContainerLow.withValues(alpha: 0.95),
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
                // ── 前景层：左上角关闭/菜单按钮 + 底部账号区 ──
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _roundIcon(
                              context,
                              Icons.close_rounded,
                              tooltip: '关闭',
                              onTap: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const Spacer(),
                        _buildAccountBlock(context, cs, account, card, logged),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBackground(ColorScheme cs) {
    final account = BilibiliAccountService.instance;
    final card = _cachedCard;
    final photo = card?.topPhoto ?? '';
    if (loggedCardPhoto(card)) {
      return Image(
        image: CachedImageProvider(
          '$photo@672w_378h_1c.webp',
          headers: NetworkSettingsService.instance.apiHeaders.isEmpty
              ? null
              : NetworkSettingsService.instance.apiHeaders,
        ),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _blurredAvatarBg(cs, account.avatarUrl),
      );
    }
    if (account.isLoggedIn && account.avatarUrl.isNotEmpty) {
      return _blurredAvatarBg(cs, account.avatarUrl);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer,
            cs.tertiaryContainer,
            cs.secondaryContainer,
          ],
        ),
      ),
    );
  }

  bool loggedCardPhoto(BiliUserSpaceCard? card) {
    final account = BilibiliAccountService.instance;
    return account.isLoggedIn && card != null && card.topPhoto.isNotEmpty;
  }

  Widget _blurredAvatarBg(ColorScheme cs, String avatarUrl) {
    return Image(
      image: CachedImageProvider(
        BilibiliUserSpaceService.avatarUrl(avatarUrl, size: 320),
        headers: NetworkSettingsService.instance.apiHeaders.isEmpty
            ? null
            : NetworkSettingsService.instance.apiHeaders,
      ),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primaryContainer, cs.tertiaryContainer],
          ),
        ),
      ),
      frameBuilder: (context, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded || frame != null) {
          return ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: child,
          );
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primaryContainer, cs.tertiaryContainer],
            ),
          ),
        );
      },
    );
  }

  Widget _roundIcon(
    BuildContext context,
    IconData icon, {
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.28),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountBlock(
    BuildContext context,
    ColorScheme cs,
    BilibiliAccountService account,
    BiliUserSpaceCard? card,
    bool logged,
  ) {
    if (!logged) {
      return Material(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BilibiliLoginScreen(),
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.login, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  '未登录 B 站账号 · 点击登录',
                  style: TextStyle(color: Colors.white, fontSize: 13.5),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final name = (card?.name.isNotEmpty ?? false) ? card!.name : account.uname;
    final faceUrl = card?.face.isNotEmpty ?? false
        ? BilibiliUserSpaceService.avatarUrl(card!.face)
        : account.avatarUrl.isEmpty
        ? ''
        : BilibiliUserSpaceService.avatarUrl(account.avatarUrl);
    return Row(
      children: [
        PendantAvatar(
          size: 60,
          pendOffset: 8,
          avatarUrl: faceUrl,
          pendantUrl: card?.pendantImage,
          ringWidth: 2,
          ringColor: Colors.white.withValues(alpha: 0.85),
          fallback: const Icon(
            Icons.account_circle,
            size: 44,
            color: Colors.white70,
          ),
          onTap: () {
            Navigator.pop(context);
            if (account.mid > 0) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BilibiliUserSpacePage(mid: account.mid),
                ),
              );
            }
          },
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isNotEmpty ? name : 'B 站账号',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'UID ${account.mid} · 点击进入我的空间',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.85),
                  shadows: const [
                    Shadow(blurRadius: 4, color: Colors.black45),
                  ],
                ),
              ),
              if (card?.fansDetail case final fansDetail?)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: FansMedalBadge(detail: fansDetail),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 「关于」信息弹窗（抽屉与宽屏侧边栏共用）。
void showDrawerInfoDialog(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context);
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(isDark ? 0.45 : 0.25),
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 80,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Material(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 26,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.drawerAbout,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 0.5),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                    child: FutureBuilder<Widget>(
                      future: getHostSystemInfo(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(
                            l10n.drawerFetchFailed(snapshot.error.toString()),
                            style: TextStyle(
                              color: theme.colorScheme.error,
                            ),
                          );
                        }
                        final deviceInfo =
                            snapshot.data ??
                            Text(
                              l10n.drawerNoDeviceInfo,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            deviceInfo,
                            const Divider(height: 20, thickness: 0.5),
                            _drawerInfoTile(
                              context,
                              Icons.code,
                              'Codename',
                              BuildInfo.buildCodename,
                            ),
                            const SizedBox(height: 10),
                            _drawerInfoTile(
                              context,
                              Icons.access_time,
                              'Build Time',
                              BuildInfo.buildTimestamp,
                            ),
                            const SizedBox(height: 10),
                            _drawerInfoTile(
                              context,
                              BuildInfo.isDebug
                                  ? Icons.bug_report
                                  : Icons.shield,
                              'Running',
                              BuildInfo.isDebug ? 'Debug' : 'Release',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          l10n.commonOk,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _drawerInfoTile(
  BuildContext context,
  IconData icon,
  String label,
  String value,
) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
