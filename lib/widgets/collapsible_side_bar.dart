// lib/widgets/collapsible_side_bar.dart
//
// 宽屏 / 横屏侧边栏（参考 PiliPlus 桌面端布局思路）：
//   - 固定显示在左侧；收起态 = M3 竖向导航栏（NavigationRail，纯图标），
//     展开态 = 普通 M3 胶囊 list（图标 + 文字，胶囊选中态）
//   - 最顶上 Material 风格 menu 按钮：点击展开（menu → menu_open），
//     再点一下缩回去（menu_open → menu）；图标始终与导航项/列表项对齐
//   - 展开/收起状态全局共享（跨页面一致）并持久化
//   - 点击菜单项不推路由：由宿主（SideBarShell）切换内容区，无转场动画
//     （与设置页左侧面板切换右侧内容一致）
//   - 背景色与内容区一致（不画自己的底色，由宿主画布提供），
//     与内容区之间不画分隔线，留空即可
//   - 竖屏（窄屏）不使用本组件，仍走原来的抽屉（AppDrawer）
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/history_center_page.dart';
import 'package:naviflash/screens/my_cache_page.dart';
import 'package:naviflash/screens/settings_split_screen.dart';
import 'package:naviflash/screens/user_profile_page.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'app_drawer.dart';
import 'app_toast.dart';
import 'expressive_app_bar.dart' show FrostedPanel;

class CollapsibleSideBar extends StatefulWidget {
  /// 当前所在页面 id（高亮对应菜单项，与 AppDrawer.currentPage 一致）。
  final String currentPage;

  /// 点击菜单项回调（宿主切换内容区，不推路由）。
  final ValueChanged<String> onNavigate;

  /// 非 null 时用该值代替全局展开状态（悬停浮层模式专用：
  /// 浮层展开/收起由宿主鼠标悬停状态驱动，不写全局 [expanded]）。
  final bool? expandedOverride;

  /// 浮层模式：覆盖在内容区之上（叠放），自带背景 + 阴影 + 右侧圆角；
  /// 正常模式保持透明背景（由宿主画布统一提供）。
  final bool overlay;

  /// 浮层模式点击顶部 menu 按钮的回调（宿主：转手动展开并关闭浮层）。
  final VoidCallback? onOverlayMenuTap;

  const CollapsibleSideBar({
    super.key,
    this.currentPage = 'home',
    required this.onNavigate,
    this.expandedOverride,
    this.overlay = false,
    this.onOverlayMenuTap,
  });

  // ── 宽度 ──
  /// 收起态宽度 = NavigationRail 的 minWidth（竖向导航栏）。
  static const double minWidth = 80;
  /// 展开态宽度（胶囊 list）。
  static const double expandedWidth = 224;

  /// 展开 / 收起动画时长与曲线（宽度、底部高度共用）。
  static const Duration animDuration = Duration(milliseconds: 260);
  static const Curve animCurve = Curves.easeInOutCubic;

  // ── 展开 / 收起状态：全局共享并持久化（所有页面共用同一个侧边栏状态） ──
  static final ValueNotifier<bool> expanded = ValueNotifier(false);
  static bool _loaded = false;

  /// 从本地恢复展开状态（页面首次构建侧边栏时调用）。
  static Future<void> loadExpandedState() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      expanded.value = prefs.getBool('sideBarExpanded') ?? false;
    } catch (_) {}
  }

  /// 切换展开 / 收起并持久化（侧边栏顶部 menu 按钮与各页 AppBar 汉堡共用）。
  static Future<void> toggle() async {
    expanded.value = !expanded.value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sideBarExpanded', expanded.value);
    } catch (_) {}
  }

  @override
  State<CollapsibleSideBar> createState() => _CollapsibleSideBarState();
}

class _CollapsibleSideBarState extends State<CollapsibleSideBar> {
  @override
  void initState() {
    super.initState();
    CollapsibleSideBar.loadExpandedState();
  }

  /// 顶部 menu 按钮点击：浮层模式由宿主接管（转手动展开并关闭浮层），
  /// 正常模式切换全局展开状态。
  void _onMenuTap() {
    if (widget.overlay) {
      widget.onOverlayMenuTap?.call();
    } else {
      CollapsibleSideBar.toggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final overlay = widget.overlay;
    return ValueListenableBuilder<bool>(
      valueListenable: CollapsibleSideBar.expanded,
      builder: (context, globalExpanded, _) {
        final isExpanded = widget.expandedOverride ?? globalExpanded;
        // 浮层模式：展开时用毛玻璃（FrostedPanel，与顶栏 / tab 同款），
        // 覆盖在内容区之上；收起时保持透明，视觉上与底层收起侧边栏一致
        final overlayBlur = overlay && isExpanded;
        // 用 RepaintBoundary 隔离侧边栏宽度动画，避免每帧重绘右侧 IndexedStack 内容
        return RepaintBoundary(
          child: AnimatedContainer(
            duration: CollapsibleSideBar.animDuration,
            curve: CollapsibleSideBar.animCurve,
            width: isExpanded
                ? CollapsibleSideBar.expandedWidth
                : CollapsibleSideBar.minWidth,
            // 背景色与内容区保持一致（宿主画布统一提供），不画自己的底色；
            // 浮层展开态例外：毛玻璃自带半透明底色
            color: Colors.transparent,
            // 关键：动画期间 width 从 80→224 渐变，但 child（展开态完整内容）
            // 在 isExpanded 翻 true 的瞬间就立即切换，需要 ~224 才放得下；
            // 若不裁剪，动画前期 width 还停在 80 时，展开态 Row 可用宽度
            // 仅 20（80 - padding），会触发 RenderFlex overflow（黄黑条纹）
            // 并在 debug 下刷异常；横屏进入视频页时持续命中 → 表现为卡死。
            // clipBehavior 让超出现宽的部分被裁剪，动画结束 width=224 时完整显示。
            clipBehavior: Clip.hardEdge,
            // 收起 = 竖向导航栏；展开 = 胶囊 list；用 Key 避免动画期间子树复用导致的布局抖动
            child: overlayBlur
                ? FrostedPanel(
                    blurSigma: 10,
                    opacity: 0.75,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(16),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(isExpanded),
                      child: _buildExpandedList(cs, l10n),
                    ),
                  )
                : KeyedSubtree(
                    key: ValueKey(isExpanded),
                    child: isExpanded
                        ? _buildExpandedList(cs, l10n)
                        : _buildCollapsedRail(cs, l10n),
                  ),
          ),
        );
      },
    );
  }

  /// 收起态：对齐截图的极简竖栏（顶部 menu + 搜索大圆角，其余沉底）。
  /// - 最顶上：menu 胶囊按钮（点击展开，menu → menu_open）
  /// - 往下：方形大圆角搜索按钮（截图里顶部浅绿圆角）
  /// - 中间留空（Spacer）
  /// - 底部：导航图标纵列（首页 / 推荐 / 用户），选中项浅绿胶囊 + 文字
  /// - 最下面：⋮ 更多菜单（历史 / 缓存 / 设置 / 关于）
  Widget _buildCollapsedRail(ColorScheme cs, AppLocalizations l10n) {
    final isSearchSelected = widget.currentPage == 'search';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 最顶部：menu 胶囊按钮（按需求“最上面加上 menu 按钮”） ──
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
child: SizedBox(
                  width: CollapsibleSideBar.minWidth,
                  height: 40,
                  child: Center(
                    child: _CapsuleIconButton(
                      icon: Icons.menu,
                      tooltip: l10n.sideBarExpand,
                      onTap: () => _onMenuTap(),
                    ),
                  ),
                ),
            ),
          ),
        ),
        // ── 搜索：方形大圆角（截图顶部浅绿圆角，~56x56, radius 18） ──
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Center(
            child: _CollapsedSearchButton(
              isSelected: isSearchSelected,
              onTap: () => widget.onNavigate('search'),
            ),
          ),
        ),
        const Spacer(),
        // ── 底部导航：图标纵列（首页 / 推荐 / 用户） ──
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CollapsedNavItem(
                icon: Icons.home,
                outlinedIcon: Icons.home_outlined,
                label: l10n.drawerHome,
                isSelected: widget.currentPage == 'home',
                onTap: () => widget.onNavigate('home'),
              ),
              const SizedBox(height: 6),
              _CollapsedNavItem(
                icon: Icons.person,
                outlinedIcon: Icons.person_outline,
                label: l10n.settingsUser,
                isSelected: false,
                onTap: () {
                  // 用户页全屏打开（推路由），与抽屉头像入口一致
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UserProfilePage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // ── ⋮ 更多菜单（历史 / 缓存 / 设置 / 关于） ──
        _MoreMenuButton(isExpanded: false),
        // 底部安全区占位（与截图底部留白一致）
        SafeArea(top: false, child: const SizedBox(height: 4)),
      ],
    );
  }

  /// 展开态：Gmail 风格胶囊 list（对齐截图）。
  /// 截图特征：顶部左侧 menu，下方全宽胶囊 list，选中项浅蓝胶囊 + 右侧计数，图标空心/实心切换。
  /// 本应用仅保留实际功能：首页 / 推荐（ + 搜索作为快速入口，仍保留以免导航断裂）。
  Widget _buildExpandedList(ColorScheme cs, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 顶部：胶囊 menu 按钮（与 Gmail 左上角汉堡一致，左侧对齐） ──
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 7),
                child: SizedBox(
                  width: 44,
                  height: 36,
                  child: _CapsuleIconButton(
                    icon: Icons.menu_open,
                    tooltip: l10n.sideBarCollapse,
                    onTap: () => _onMenuTap(),
                  ),
                ),
              ),
            ),
          ),
        ),
        // ── Gmail 胶囊 list：首页 / 推荐（实际功能） ──
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
            children: [
              // 搜索：与收起态同款方圆绿块 + 右侧“搜索”文字（按需求：和收缩一样，加两个字）
              _expandedSearchTile(
                cs,
                isSelected: widget.currentPage == 'search',
                title: '搜索',
                onTap: () => widget.onNavigate('search'),
              ),
              const SizedBox(height: 4),
              // 分组间隔（Gmail 收件箱上方无分割线，此处加 6px 空隙）
              _gmailCapsuleItem(
                cs,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                title: l10n.drawerHome,
                pageId: 'home',
              ),
              _gmailCapsuleItem(
                cs,
                icon: Icons.live_tv_outlined,
                selectedIcon: Icons.live_tv,
                title: '直播',
                pageId: 'live',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Divider(height: 1),
              ),
              // 预留：更多/标签区域占位（Gmail 截图的“显示更多标签/标签 +”）
              // 本应用实际未启用，保留为注释示例
              // _gmailSectionHeader(l10n.sideBarMore),
            ],
          ),
        ),
        // ── 底部：头像 + 昵称 + 锁定 / 主题 ──
        AnimatedSize(
          duration: CollapsibleSideBar.animDuration,
          curve: CollapsibleSideBar.animCurve,
          child: _BottomSection(isExpanded: true),
        ),
        // ── 最下面：⋮ 更多菜单 ──
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MoreMenuButton(isExpanded: true),
          ),
        ),
      ],
    );
  }

  /// 展开态胶囊：紧凑胶囊（回退贴边，宽自适应文字结束，非全宽拉伸）
  Widget _gmailCapsuleItem(
    ColorScheme cs, {
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required String pageId,
    String? trailing,
  }) {
    final isSelected = widget.currentPage == pageId;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Material(
          color: isSelected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (pageId == widget.currentPage) return;
              widget.onNavigate(pageId);
            },
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? selectedIcon : icon,
                    size: 22,
                    color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (trailing != null && trailing.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      trailing,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 展开态搜索：Gmail 类 FAB，颜色与收起态搜索一致（Material 主题色）
  Widget _expandedSearchTile(
    ColorScheme cs, {
    required bool isSelected,
    required String title,
    required VoidCallback onTap,
  }) {
    final bg = cs.primaryContainer;
    final fg = cs.onPrimaryContainer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 20, color: fg),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: fg,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 收起态顶部大圆角搜索按钮（Material 主题色 primaryContainer）。
class _CollapsedSearchButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CollapsedSearchButton({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.primaryContainer;
    final fg = cs.onPrimaryContainer;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.search, size: 26, color: fg),
        ),
      ),
    );
  }
}

/// 收起态底部单项：选中时 primaryContainer 胶囊 + 下方文字，未选中仅图标。
class _CollapsedNavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CollapsedNavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedBg = cs.primaryContainer;
    final selectedFg = cs.onPrimaryContainer;
    final iconWidget = Icon(
      isSelected ? icon : outlinedIcon,
      size: 24,
      color: isSelected ? selectedFg : cs.onSurfaceVariant,
    );
    final pill = isSelected
        ? Container(
            width: 56,
            height: 32,
            decoration: BoxDecoration(
              color: selectedBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: iconWidget),
          )
        : SizedBox(
            width: 56,
            height: 32,
            child: Center(child: iconWidget),
          );
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              pill,
              // 仅选中项显示文字，未选中只显示图标
              if (isSelected && label.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    height: 1,
                  ),
                ),
              ] else
                const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// 顶部 menu 按钮：无背景（去掉莫名 tonal 底色），仅图标 + Tooltip
class _CapsuleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CapsuleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 44,
            height: 36,
            child: Icon(icon, size: 22, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

/// 侧边栏最下面的 ⋮ 更多菜单按钮：历史记录 / 缓存 / 设置 / 关于。
/// 使用液态玻璃菜单（dom 动画 + 玻璃材质），点击项全屏打开（推路由），
/// 不被侧边栏影响。
class _MoreMenuButton extends StatefulWidget {
  final bool isExpanded;

  const _MoreMenuButton({required this.isExpanded});

  @override
  State<_MoreMenuButton> createState() => _MoreMenuButtonState();
}

class _MoreMenuButtonState extends State<_MoreMenuButton> {
  final GlobalKey _buttonKey = GlobalKey();

  void _openFull(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _showMenu() {
    final l10n = AppLocalizations.of(context);
    final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    showGlassDropdownMenu(
      context,
      actions: [
        GlassMenuAction(
          icon: Icons.history,
          text: l10n.drawerHistory,
          onTap: () => _openFull(context, const HistoryCenterPage()),
        ),
        GlassMenuAction(
          icon: Icons.download_rounded,
          text: l10n.drawerMyCache,
          onTap: () => _openFull(context, const MyCachePage()),
        ),
        GlassMenuAction(
          icon: Icons.settings,
          text: l10n.drawerSettings,
          onTap: () =>
              _openFull(context, const SplitSettingsScreen(isStandalone: true)),
        ),
        GlassMenuAction(
          icon: Icons.info_outline,
          text: l10n.drawerAbout,
          onTap: () => showDrawerInfoDialog(context),
        ),
      ],
      // 按钮左上角 + 尺寸：启用「角对齐」，靠近底部时菜单自动向上展开
      globalPosition: box.localToGlobal(Offset.zero),
      originSize: box.size,
      menuWidth: 224,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isExpanded = widget.isExpanded;
    final capsule = Material(
      color: cs.surfaceContainerHighest,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: _buttonKey,
        onTap: _showMenu,
        child: SizedBox(
          width: 44,
          height: 36,
          child: Icon(Icons.more_vert, size: 22, color: cs.onSurfaceVariant),
        ),
      ),
    );
    if (!isExpanded) {
      // 收起态：胶囊居中于 minWidth 盒（与导航项对齐）
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: CollapsibleSideBar.minWidth,
          height: 40,
          child: Center(child: Tooltip(message: l10n.sideBarMore, child: capsule)),
        ),
      );
    }
    // 展开态：胶囊 list 项样式（图标与列表项对齐，右侧「更多」文字）
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: _buttonKey,
          onTap: _showMenu,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.more_vert, size: 22, color: cs.onSurfaceVariant),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.sideBarMore,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: cs.onSurface),
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

/// 底部：头像 + 昵称（展开时）+ 锁定 / 主题切换。
class _BottomSection extends StatelessWidget {
  final bool isExpanded;

  const _BottomSection({required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final settingsService = context.read<SettingsService>();
    final hasAvatar = settingsService.avatarPath != null &&
        File(settingsService.avatarPath!).existsSync();

    final avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: cs.primaryContainer,
        backgroundImage:
            hasAvatar ? FileImage(File(settingsService.avatarPath!)) : null,
        child: !hasAvatar
            ? Icon(Icons.account_circle, size: 30, color: cs.onSurfaceVariant)
            : null,
      ),
    );

    final themeBtn = IconButton(
      icon: const Icon(Icons.brightness_4, size: 20),
      tooltip: l10n.drawerSwitchToDark,
      color: cs.onSurfaceVariant,
      onPressed: () => _toggleThemeMode(context, settingsService),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: isExpanded
            ? Row(
                children: [
                  const SizedBox(width: 14),
                  avatar,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      settingsService.nickname?.isNotEmpty == true
                          ? settingsService.nickname!
                          : l10n.drawerNoNickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  themeBtn,
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  avatar,
                  const SizedBox(height: 4),
                  themeBtn,
                ],
              ),
      ),
    );
  }

  void _toggleThemeMode(BuildContext context, SettingsService settingsService) {
    final l10n = AppLocalizations.of(context);
    final currentMode = settingsService.themeMode;
    final newMode = switch (currentMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    settingsService.setThemeMode(newMode);
    showAppToast(
      context,
      l10n.drawerThemeSwitched(
        newMode == ThemeMode.light
            ? l10n.drawerLightMode
            : newMode == ThemeMode.dark
            ? l10n.drawerDarkMode
            : l10n.drawerSystemMode,
      ),
    );
  }
}