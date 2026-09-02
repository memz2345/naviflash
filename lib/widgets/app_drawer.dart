import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:naviflash/screens/bilibili_watch_later_page.dart';
import 'package:naviflash/screens/settings_split_screen.dart';
import 'package:naviflash/screens/user_profile_page.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/device.dart';
import '../screens/bilibili_search_page.dart';
import '../screens/bilibili_live_page.dart';
import '../screens/history_center_page.dart';
import '../screens/my_cache_page.dart';
import '../widgets/expressive_app_bar.dart';
import '../build_info.g.dart';
import '../l10n/app_localizations.dart';
import '../src/loading_indicator_m3e.dart';

class AppDrawer extends StatelessWidget {
  final String currentPage;
  const AppDrawer({super.key, this.currentPage = 'home'});

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(
      context,
      listen: false,
    );
    final currentThemeMode = settingsService.themeMode;
    final l10n = AppLocalizations.of(context);

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ================= 可拉伸头部（前景/背景分层） =================
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: false,
            floating: false,
            stretch: true,
            stretchTriggerOffset: 80,
            elevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: Stack(
              fit: StackFit.expand,
              children: [
                // ─── 背景层：受 zoom + blur 影响 ───
                FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: _DrawerBackgroundLayer(
                    settingsService: settingsService,
                  ),
                ),
                // ─── 前景层：不受 blur 影响 ───
                _DrawerForegroundLayer(
                  settingsService: settingsService,
                  currentThemeMode: currentThemeMode,
                ),
              ],
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              // 主导航 4 项：搜索 / 主页（B站推荐流）/ 直播 / 设置，其余收进右上角 ⋮
              _buildDrawerItem(
                context,
                icon: Icons.search,
                title: l10n.drawerBilibiliSearch,
                pageId: 'search',
                onTap: () {
                  Navigator.pop(context);
                  if (currentPage != 'search') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BilibiliSearchPage(),
                      ),
                    );
                  }
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.home,
                title: l10n.drawerHome,
                pageId: 'home',
                onTap: () {
                  Navigator.pop(context);
                  // 主页即应用根页面（B站推荐流）：清栈回到首页
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.live_tv_outlined,
                title: '直播',
                pageId: 'live',
                onTap: () {
                  Navigator.pop(context);
                  if (currentPage != 'live') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BilibiliLivePage(),
                      ),
                    );
                  }
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.settings,
                title: l10n.drawerSettings,
                pageId: 'settings',
                onTap: () {
                  Navigator.pop(context);
                  if (currentPage != 'settings') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SplitSettingsScreen(isStandalone: true),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ],
      ),
    );
  }

  // ================= 菜单项（胶囊形） =================
  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String pageId,
    required VoidCallback onTap,
  }) {
    final isSelected = currentPage == pageId;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
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
          child: StretchableNaviGlass(
            radius: 24.0,
            blur: 16.0,
            stretch: 0.3,
            child: Material(
              color: Colors.transparent,
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
                                child: LoadingIndicatorM3E(),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text(
                              l10n.drawerFetchFailed(
                                snapshot.error.toString(),
                              ),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                          final deviceInfo =
                              snapshot.data ??
                              Text(
                                l10n.drawerNoDeviceInfo,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
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

// ================= 背景层（受 stretch blur/zoom 影响） =================
class _DrawerBackgroundLayer extends StatelessWidget {
  final SettingsService settingsService;
  const _DrawerBackgroundLayer({required this.settingsService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgPath = settingsService.drawerBackgroundPath;
    final hasBg = bgPath != null && File(bgPath).existsSync();

    return GestureDetector(
      onTap: () => _showChangeBackgroundDialog(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图片或默认渐变
          if (hasBg)
            Image.file(
              File(bgPath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _defaultGradient(theme),
            )
          else
            _defaultGradient(theme),
          // 底部渐变遮罩（保证前景文字可读）
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 140,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultGradient(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
            theme.colorScheme.tertiaryContainer,
          ],
        ),
      ),
    );
  }

  void _showChangeBackgroundDialog(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasBg =
        settingsService.drawerBackgroundPath != null &&
        File(settingsService.drawerBackgroundPath!).existsSync();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FrostedSheet(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.wallpaper,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.drawerBackgroundTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasBg
                        ? l10n.drawerBackgroundHasCustom
                        : l10n.drawerBackgroundNoCustom,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      try {
                        final success = await settingsService
                            .pickAndSaveDrawerBackground();
                        if (success && context.mounted) {
                          showAppToast(context, l10n.drawerBackgroundUpdated);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          showAppToast(
                            context,
                            l10n.drawerBackgroundSetFailed(e.toString()),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      hasBg
                          ? l10n.drawerBackgroundChange
                          : l10n.drawerBackgroundSelect,
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (hasBg) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await settingsService.removeDrawerBackground();
                        if (context.mounted) {
                          showAppToast(context, l10n.drawerBackgroundRestored);
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.drawerBackgroundRemove),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(
                          color: theme.colorScheme.error.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text(l10n.commonCancel),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ================= 前景层（不受 stretch blur 影响） =================
class _DrawerForegroundLayer extends StatelessWidget {
  final SettingsService settingsService;
  final ThemeMode currentThemeMode;

  const _DrawerForegroundLayer({
    required this.settingsService,
    required this.currentThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: _headerIconButton(
            icon: Icons.menu,
            tooltip: l10n.drawerCloseMenu,
            onPressed: () => Navigator.pop(context),
          ),
        ),

        // ─── 右上角：主题切换 + ⋮ 溢出（与宽屏侧边栏一致） ───
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _headerIconButton(
                icon: currentThemeMode == ThemeMode.dark
                    ? Icons.brightness_4
                    : currentThemeMode == ThemeMode.light
                    ? Icons.brightness_7
                    : Icons.brightness_auto,
                tooltip: _getThemeModeTooltip(context, currentThemeMode),
                onPressed: () => _toggleThemeMode(context, settingsService),
              ),
              const SizedBox(width: 8),
              const _DrawerHeaderOverflowButton(),
            ],
          ),
        ),

        // ─── 底部：头像 + 昵称 ───
        Positioned(
          left: 20,
          bottom: 16,
          right: 20,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UserProfilePage()),
                  );
                },
                child: _buildAvatar(settingsService.avatarPath),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      settingsService.nickname?.isNotEmpty == true
                          ? settingsService.nickname!
                          : l10n.drawerNoNickname,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String? avatarPath) {
    final hasAvatar = avatarPath != null && File(avatarPath).existsSync();
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 32,
        backgroundColor: Colors.white.withOpacity(0.3),
        backgroundImage: hasAvatar ? FileImage(File(avatarPath)) : null,
        child: !hasAvatar
            ? const Icon(Icons.account_circle, size: 44, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.2),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  String _getThemeModeTooltip(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context);
    switch (mode) {
      case ThemeMode.light:
        return l10n.drawerSwitchToDark;
      case ThemeMode.dark:
        return l10n.drawerSwitchToLight;
      case ThemeMode.system:
        return l10n.drawerSwitchToLight;
    }
  }

  void _toggleThemeMode(BuildContext context, SettingsService settingsService) {
    final l10n = AppLocalizations.of(context);
    ThemeMode currentMode = settingsService.themeMode;
    ThemeMode newMode;
    switch (currentMode) {
      case ThemeMode.system:
        newMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        newMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newMode = ThemeMode.system;
        break;
    }
    settingsService.setThemeMode(newMode);
    String modeName = newMode == ThemeMode.light
        ? l10n.drawerLightMode
        : newMode == ThemeMode.dark
        ? l10n.drawerDarkMode
        : l10n.drawerSystemMode;
    showAppToast(context, l10n.drawerThemeSwitched(modeName));
  }
}

/// 侧边栏右上角 ⋮ 溢出菜单（传统抽屉专用，精简后与宽屏侧边栏一致）
/// 仅保留 4 项主导航，其余历史/缓存/稍后再看/关于收进此菜单（液态玻璃菜单）
class _DrawerHeaderOverflowButton extends StatefulWidget {
  const _DrawerHeaderOverflowButton();

  @override
  State<_DrawerHeaderOverflowButton> createState() =>
      _DrawerHeaderOverflowButtonState();
}

class _DrawerHeaderOverflowButtonState
    extends State<_DrawerHeaderOverflowButton> {
  final GlobalKey _key = GlobalKey();

  void _showMenu() {
    final l10n = AppLocalizations.of(context);
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    // 捕获抽屉的 BuildContext，用于先关闭抽屉再跳转
    final drawerContext = context;
    showGlassDropdownMenu(
      drawerContext,
      actions: [
        GlassMenuAction(
          icon: Icons.history,
          text: l10n.drawerHistory,
          onTap: () {
            Navigator.pop(drawerContext);
            Navigator.of(drawerContext).push(
              MaterialPageRoute(builder: (_) => const HistoryCenterPage()),
            );
          },
        ),
        GlassMenuAction(
          icon: Icons.watch_later_outlined,
          text: l10n.drawerWatchLater,
          onTap: () {
            Navigator.pop(drawerContext);
            Navigator.of(drawerContext).push(
              MaterialPageRoute(
                builder: (_) => const BilibiliWatchLaterPage(),
              ),
            );
          },
        ),
        GlassMenuAction(
          icon: Icons.download_rounded,
          text: l10n.drawerMyCache,
          onTap: () {
            Navigator.pop(drawerContext);
            Navigator.of(drawerContext).push(
              MaterialPageRoute(builder: (_) => const MyCachePage()),
            );
          },
        ),
        GlassMenuAction(
          icon: Icons.info_outline,
          text: l10n.drawerAbout,
          onTap: () {
            Navigator.pop(drawerContext);
            // 抽屉关闭后弹关于弹窗，需用外层 context
            Future.delayed(const Duration(milliseconds: 220), () {
              if (drawerContext.mounted) showDrawerInfoDialog(drawerContext);
            });
          },
        ),
      ],
      globalPosition: box.localToGlobal(Offset.zero),
      originSize: box.size,
      menuWidth: 224,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context).sideBarMore,
      child: Material(
        key: _key,
        color: Colors.white.withOpacity(0.2),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _showMenu,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
