import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/screens/player_settings_screen.dart';
import 'package:naviflash/screens/log_viewer_page.dart';
import 'package:naviflash/screens/open_source_licenses_page.dart';
import 'package:naviflash/screens/storage_settings_screen.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../screens/about_page.dart';
import '../screens/display_settings_screen.dart';
import '../screens/user_profile_page.dart';
import '../screens/network_settings_screen.dart';
import '../screens/accounts_screen.dart';
import '../screens/language_settings_screen.dart';
import '../widgets/morph_card.dart';
import '../widgets/expressive_app_bar.dart';
import '../services/lnative_bridge.dart';
import '../widgets/app_drawer.dart';
import '../widgets/page_background.dart';
import '../screens/settings_search_page.dart';
import '../services/settings_search_controller.dart';
import '../l10n/app_localizations.dart';


class SettingsEntry {
  final String name;
  final String route;
  final IconData icon;
  final String subtitle;
  const SettingsEntry({
    required this.name,
    required this.route,
    required this.icon,
    this.subtitle = '',
  });
}

class SettingsGroup {
  final List<SettingsEntry> entries;
  const SettingsGroup({required this.entries});
}

//
// 子页面（如 DisplaySettingsScreen）会自行向右侧嵌套 Navigator push 二级页面，
// 父级 SplitSettingsScreen 需要感知栈深度变化，以正确设置 PopScope.canPop。
// 直接监听 didPush / didPop 等回调即可。
class _RightNavObserver extends NavigatorObserver {
  final VoidCallback onStackChanged;
  _RightNavObserver(this.onStackChanged);

  @override
  void didPush(Route route, Route? previousRoute) => onStackChanged();

  @override
  void didPop(Route route, Route? previousRoute) => onStackChanged();

  @override
  void didRemove(Route route, Route? previousRoute) => onStackChanged();

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => onStackChanged();
}


class SplitSettingsScreen extends StatefulWidget {
  final bool isStandalone;
  final String? initialRoute;
  final VoidCallback? onOpenDrawer;

  /// 宽屏 SideBarShell 内嵌模式：不显示侧边栏（Shell 已提供）、
  /// 不显示侧边栏入口（汉堡/返回），背景透明（由 Shell 画布统一提供）。
  final bool embeddedInShell;

  const SplitSettingsScreen({
    super.key,
    this.isStandalone = false,
    this.initialRoute,
    this.onOpenDrawer,
    this.embeddedInShell = false,
  });

  @override
  State<SplitSettingsScreen> createState() => _SplitSettingsScreenState();
}

class _SplitSettingsScreenState extends State<SplitSettingsScreen> {
  String _selectedRoute = '/display';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<NavigatorState> _rightNavKey = GlobalKey<NavigatorState>();

  // 右侧 Navigator 栈监听器
  late final _RightNavObserver _rightNavObserver;

  // 去重标志：保证同一帧内 observer 多次回调只排期一次 postFrame rebuild，
  // 同时避免在嵌套 Navigator 首帧 restoreState 的 build 锁内对祖先 setState。
  bool _observerRebuildPending = false;

  bool get _isWideScreen => MediaQuery.of(context).size.width >= 768;

  static const String _heroTag = 'user_avatar_hero';

  // 彩蛋: 连点标题
  int _titleTapCount = 0;
  DateTime _lastTitleTap = DateTime(2000);

  void _onTitleTap() {
    if (!Platform.isAndroid) return;
    final now = DateTime.now();
    if (now.difference(_lastTitleTap).inMilliseconds > 800) {
      _titleTapCount = 0;
    }
    _lastTitleTap = now;
    _titleTapCount++;
    if (_titleTapCount >= 5) {
      _titleTapCount = 0;
      NativeBridge.openEasterEgg();
    }
  }

  // 这里都是占位的
  List<SettingsGroup> _buildGroups(AppLocalizations l10n) => [
    SettingsGroup(
      entries: [
        SettingsEntry(
          name: l10n.settingsDisplay,
          route: '/display',
          icon: Icons.display_settings_outlined,
          subtitle: l10n.settingsDisplaySub,
        ),
        SettingsEntry(
          name: l10n.settingsSystem,
          route: '/system',
          icon: Icons.computer_outlined,
          subtitle: l10n.settingsSystemSub,
        ),
        // ─── 新增：存储（缓存管理） ───
        SettingsEntry(
          name: l10n.settingsStorage,
          route: '/storage',
          icon: Icons.storage_outlined,
          subtitle: l10n.settingsStorageSub,
        ),
      ],
    ),
    SettingsGroup(
      entries: [
        SettingsEntry(
          name: l10n.settingsNetwork,
          route: '/network',
          icon: Icons.wifi_outlined,
          subtitle: l10n.settingsNetworkSub,
        ),
        // ─── 新增：语言（B 站 AI 翻译） ───
        SettingsEntry(
          name: l10n.settingsLanguage,
          route: '/language',
          icon: Icons.translate,
          subtitle: l10n.settingsLanguageSub,
        ),
        // ─── 新增：播放器 ───
        SettingsEntry(
          name: l10n.settingsPlayer,
          route: '/player',
          icon: Icons.play_circle_outline,
          subtitle: l10n.settingsPlayerSub,
        ),
      ],
    ),
    SettingsGroup(
      entries: [
        SettingsEntry(
          name: l10n.settingsLogs,
          route: '/logs',
          icon: Icons.receipt_long_outlined,
          subtitle: l10n.settingsLogsSub,
        ),
      ],
    ),
    SettingsGroup(
      entries: [
        SettingsEntry(
          name: l10n.settingsAccounts,
          route: '/accounts',
          icon: Icons.account_box_outlined,
          subtitle: l10n.settingsAccountsSub,
        ),
      ],
    ),
    SettingsGroup(
      entries: [
        SettingsEntry(
          name: l10n.settingsUser,
          route: '/user',
          icon: Icons.person_outline,
          subtitle: l10n.settingsUserSub,
        ),
      ],
    ),
    SettingsGroup(
      entries: [
        SettingsEntry(
          name: l10n.drawerAbout,
          route: '/about',
          icon: Icons.info_outline,
          subtitle: l10n.settingsAboutSub,
        ),
        // ─── 新增 ───
        SettingsEntry(
          name: l10n.settingsLicenses,
          route: '/licenses',
          icon: Icons.code_rounded,
          subtitle: l10n.settingsLicensesSub,
        ),
      ],
    ),
  ];

  List<SettingsEntry> get _allEntries => _buildGroups(
    AppLocalizations.of(context),
  ).expand((g) => g.entries).toList();

  @override
  void initState() {
    super.initState();
    // observer 回调指向安全调度方法，而非直接 setState
    _rightNavObserver = _RightNavObserver(_onRightNavStackChanged);
    if (widget.initialRoute != null) {
      final exists = _allEntries.any((e) => e.route == widget.initialRoute);
      if (exists) _selectedRoute = widget.initialRoute!;
    }
  }

  /// observer 的统一回调：把 rebuild 推迟到帧末，避开 build 锁。
  ///
  /// 嵌套 Navigator 在首次构建时会同步走 restoreState → didPush，
  /// 此刻整棵树正处于 build 阶段，对祖先 setState 非法。
  /// 排到 postFrame 后 build 锁已释放，安全；并用标志去重，一帧只跑一次。
  void _onRightNavStackChanged() {
    if (_observerRebuildPending) return;
    _observerRebuildPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _observerRebuildPending = false;
      if (mounted) setState(() {});
    });
  }

  /// 打开设置搜索页；选中结果后跳转到对应设置页并滚动闪烁目标选项。
  Future<void> _openSearch() async {
//  清脆震动反馈
    HapticFeedback.lightImpact();
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => SettingsSearchPage(onSelect: _onSearchResult),
      ),
    );
  }

  /// 搜索结果选中：请求高亮 → 目标设置页以「整卡展开」转场压在搜索页之上
  /// （宽屏时同步切换右栏到目标页，藏在推入页面背后，退出搜索后右栏已就绪）。
  void _onSearchResult(SettingsSearchEntry target, Rect cardRect) {
    // 先发高亮请求（目标项 initState 命中）
    SettingsSearchController.request(
      pageRoute: target.pageRoute,
      optionKey: target.optionKey,
      pageTitle: target.pageTitle,
      optionName: target.name,
    );
    // 宽屏：右侧栏同步切换到目标页（不可见，但退出搜索后已就绪）
    if (_isWideScreen && _selectedRoute != target.pageRoute) {
      setState(() {
        _selectedRoute = target.pageRoute;
        _rightNavKey = GlobalKey<NavigatorState>(); // 重建 → 右侧栈清空
      });
    }
    final entry = _allEntries.firstWhere(
      (e) => e.route == target.pageRoute,
      orElse: () => _allEntries.first,
    );
    // YouTube 式整卡展开转场（不依赖 Hero，跨 Navigator 同样生效）
    Navigator.of(context, rootNavigator: true).push(
      ExpandingCardPageRoute(
        startRect: cardRect,
        page: _buildSubPage(entry, showBack: true),
      ),
    );
  }

  void _openDrawer() {
    if (widget.onOpenDrawer != null) {
      widget.onOpenDrawer!();
      return;
    }
    _scaffoldKey.currentState?.openDrawer();
  }

  Widget _buildLeading() {
    final l10n = AppLocalizations.of(context);
    if (widget.embeddedInShell) return const SizedBox.shrink();
    // 竖屏独立打开：汉堡打开抽屉；宽屏（⋮ 菜单全屏打开）：返回按钮
    if (widget.isStandalone && !_isWideScreen) {
      return MorphIconButton(
        icon: Icons.menu,
        tooltip: l10n.homeOpenMenu,
        onTap: _openDrawer,
      );
    }
    return MorphIconButton(
      icon: Icons.arrow_back,
      tooltip: l10n.homeBack,
      onTap: () => Navigator.of(context).maybePop(),
    );
  }

  void _onEntryTap(SettingsEntry entry) {
//  清脆震动反馈
    HapticFeedback.lightImpact();
    if (_isWideScreen) {
      if (_selectedRoute == entry.route) return;
      setState(() {
        _selectedRoute = entry.route;
        _rightNavKey = GlobalKey<NavigatorState>(); // 重建 → 右侧栈清空
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _buildSubPage(entry, showBack: true)),
      );
    }
  }

  // ── 账户卡片点击 ──
  void _onAccountTap() {
//  清脆震动反馈
    HapticFeedback.lightImpact();
    if (_isWideScreen) {
      if (_selectedRoute == '/user-profile') return;
      setState(() {
        _selectedRoute = '/user-profile';
        _rightNavKey = GlobalKey<NavigatorState>();
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const UserProfilePage(heroTag: _heroTag),
        ),
      );
    }
  }

  /// 构建右侧 / 紧凑模式的一级页面。
  ///
  /// 注意：不再托管二级导航（不传 onNavigate），
  /// 子页面（如 DisplaySettingsScreen）自行 push 二级页面到当前 Navigator。
  Widget _buildSubPage(SettingsEntry entry, {required bool showBack}) {
    switch (entry.route) {
      case '/display':
        return DisplaySettingsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
      // ─── 新增：网络 ───
      case '/network':
        return NetworkSettingsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
      // ─── 新增：语言（B 站 AI 翻译） ───
      case '/language':
        return LanguageSettingsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
      // ─── 修改 ───
      case '/player':
        return PlayerSettingsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
      // ─── 新增 ───
      case '/licenses':
        return OpenSourceLicensesPage(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
      // ─── 新增：账号 ───
      case '/accounts':
        return AccountsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
      // ─── 新增：日志 ───
      case '/logs':
        return LogViewerPage(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
      // ─── 新增：存储（缓存管理） ───
      case '/storage':
        return StorageSettingsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
      // ─── 关于 / 我的设备（MIUI 风格，Navi 版本 + 用户名称 + 液态存储） ───
      case '/about':
        return AboutPage(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
      default:
        return _PlaceholderPage(
          entry: entry,
          showBack: showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 宽屏 + 右侧栈深度 > 1 → 阻止根 Navigator pop（改为只 pop 右侧）
    final rightCanPop = _rightNavKey.currentState?.canPop() ?? false;

    return PopScope(
      canPop: !(_isWideScreen && rightCanPop),
      onPopInvoked: (didPop) {
        if (didPop) return;
        // 宽屏 + 右侧有二级页面 → 只 pop 右侧
        if (_isWideScreen && _rightNavKey.currentState?.canPop() == true) {
          _rightNavKey.currentState!.pop();
        }
        // 其余情况：非宽屏 / 右侧无二级页面时 canPop 为 true，
        // didPop 已为 true，首行已 return，无需额外处理。
      },
      child: _isWideScreen ? _buildSplitLayout() : _buildCompactLayout(),
    );
  }

  // ==================== 账户区（紧凑模式顶部） ====================

  Widget _buildAccountSection(ColorScheme cs) {
    final settings = context.watch<SettingsService>();
    final avatarPath = settings.avatarPath;
    final hasAvatar = avatarPath != null && File(avatarPath).existsSync();
    final nickname = settings.nickname?.isNotEmpty == true
        ? settings.nickname!
        : AppLocalizations.of(context).drawerNoNickname;

    Widget avatarWidget = CircleAvatar(
      radius: 24,
      backgroundColor: cs.surfaceContainerHighest,
      backgroundImage: hasAvatar ? FileImage(File(avatarPath!)) : null,
      child: !hasAvatar
          ? Icon(Icons.person, size: 24, color: cs.onSurfaceVariant)
          : null,
    );
//  头像 Hero 仅在紧凑模式下执行：拆分模式下点击头像卡片进入
    // 用户资料页（右栏展示，UserProfilePage 不带 heroTag），不做飞行动画。
    // 其余子页面的 Hero 动画（图片/播放列表/视频等）均在各自单一
    // Navigator 内执行，不受拆分布局影响，保持正常。
    if (!_isWideScreen) {
      avatarWidget = Hero(tag: _heroTag, child: avatarWidget);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: buildMorphSegmentedList([
          MorphRowItem(
            child: ListTile(
              leading: avatarWidget,
              title: Text(
                nickname,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Local Account',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
              onTap: _onAccountTap,
            ),
          ),
          MorphRowItem(
            child: ListTile(
              leading: Icon(Icons.flag, color: cs.primary),
              title: const Text('flag'),
              trailing: Icon(
                Icons.chevron_right,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
              onTap: () {
//  清脆震动反馈
                HapticFeedback.lightImpact();
                // TODO: flag 功能
              },
            ),
          ),
        ]),
      ),
    );
  }


  Widget _buildSplitLayout() {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: widget.embeddedInShell
          ? Colors.transparent
          : cs.surfaceContainerLow,
      body: Row(
        children: [
          // 内嵌在 SideBarShell 时左侧侧边栏由 Shell 提供；
          // 本布局只在宽屏使用（窄屏走 _buildCompactLayout），
          // 非内嵌宽屏场景不存在（抽屉仅在窄屏可达）
          SizedBox(width: 300, child: _buildLeftPanel()),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: cs.outlineVariant.withOpacity(0.5),
          ),
          Expanded(
            child: Navigator(
              key: _rightNavKey,
              observers: [_rightNavObserver], // 挂载栈监听器
              onGenerateRoute: (_) {
                return MaterialPageRoute(
                  builder: (_) {
                    if (_selectedRoute == '/user-profile') {
                      return const UserProfilePage(); // 无 Hero
                    }
                    return _buildSubPage(
                      _allEntries.firstWhere(
                        (e) => e.route == _selectedRoute,
                        orElse: () => _allEntries.first,
                      ),
                      showBack: false,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCompactLayout() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: cs.surfaceContainerLow,
      drawer: const AppDrawer(currentPage: 'settings'),
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainerLow),
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              ExpressiveSliverAppBar(
                title: l10n.drawerSettings,
                expandedHeight: 120,
                onTitleRepeatedTap: _onTitleTap,
                leading: _buildLeading(),
                actions: [
                  MorphIconButton(
                    icon: Icons.search,
                    tooltip: l10n.settingsSearch,
                    onTap: _openSearch,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildAccountSection(cs)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ..._buildGroups(
                l10n,
              ).map((group) => _buildGroupSliver(group, cs)),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSliver(SettingsGroup group, ColorScheme cs) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: buildMorphSegmentedList(
              group.entries.map((entry) {
                return MorphRowItem(
                  child: ListTile(
                    leading: Icon(entry.icon, color: cs.primary),
                    title: Text(entry.name),
                    subtitle: entry.subtitle.isNotEmpty
                        ? Text(
                            entry.subtitle,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: cs.onSurfaceVariant,
                      size: 20,
                    ),
                    onTap: () => _onEntryTap(entry),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 左侧导航面板（宽屏） ====================

  Widget _buildLeftPanel() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsService>();
    final avatarPath = settings.avatarPath;
    final hasAvatar = avatarPath != null && File(avatarPath).existsSync();
    final nickname = settings.nickname?.isNotEmpty == true
        ? settings.nickname!
        : l10n.drawerNoNickname;
    final groups = _buildGroups(l10n);

    return Container(
      color: cs.surfaceContainerLow,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          ExpressiveSliverAppBar(
            title: l10n.drawerSettings,
            expandedHeight: 120,
            onTitleRepeatedTap: _onTitleTap,
            leading: widget.isStandalone
                ? MorphIconButton(
                    icon: Icons.menu,
                    tooltip: l10n.openSidebar,
                    onTap: _openDrawer,
                  )
                : null,
            actions: [
              MorphIconButton(
                icon: Icons.search,
                tooltip: l10n.settingsSearch,
                size: 36,
                iconSize: 18,
                onTap: _openSearch,
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  ...buildMorphSegmentedList([
                    MorphRowItem(
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: cs.surfaceContainerHighest,
                          backgroundImage: hasAvatar
                              ? FileImage(File(avatarPath!))
                              : null,
                          child: !hasAvatar
                              ? Icon(
                                  Icons.person,
                                  size: 18,
                                  color: cs.onSurfaceVariant,
                                )
                              : null,
                        ),
                        title: Text(
                          nickname,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selectedRoute == '/user-profile'
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: _selectedRoute == '/user-profile'
                                ? cs.onSecondaryContainer
                                : cs.onSurface.withOpacity(0.85),
                          ),
                        ),
                        subtitle: Text(
                          'Local Account',
                          style: TextStyle(
                            fontSize: 11,
                            color: _selectedRoute == '/user-profile'
                                ? cs.onSecondaryContainer.withOpacity(0.7)
                                : cs.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                        onTap: () {
                          if (_selectedRoute == '/user-profile') return;
//  清脆震动反馈
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedRoute = '/user-profile';
                            _rightNavKey = GlobalKey<NavigatorState>();
                          });
                        },
                      ),
                    ),
                    MorphRowItem(
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.flag,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        title: Text(
                          'Plaza',
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurface.withOpacity(0.85),
                          ),
                        ),
                        onTap: () {
//  清脆震动反馈
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  int cursor = 0;
                  for (int gi = 0; gi < groups.length; gi++) {
                    final group = groups[gi];
                    for (int i = 0; i < group.entries.length; i++) {
                      if (index == cursor) {
                        final entry = group.entries[i];
                        final isSelected = _selectedRoute == entry.route;
                        final isFirst = i == 0;
                        final isLast = i == group.entries.length - 1;
                        final isGroupLast = gi == groups.length - 1;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: isLast ? (isGroupLast ? 0 : 24) : kCardGap,
                          ),
                          child: MorphItem(
                            selected: isSelected,
                            isFirst: isFirst,
                            isLast: isLast,
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                entry.icon,
                                size: 20,
                                color: isSelected
                                    ? cs.onSecondaryContainer
                                    : cs.onSurfaceVariant,
                              ),
                              title: Text(
                                entry.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? cs.onSecondaryContainer
                                      : cs.onSurface.withOpacity(0.85),
                                ),
                              ),
                              subtitle: Text(
                                entry.subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? cs.onSecondaryContainer.withOpacity(0.7)
                                      : cs.onSurfaceVariant.withOpacity(0.7),
                                ),
                              ),
                              onTap: () => _onEntryTap(entry),
                            ),
                          ),
                        );
                      }
                      cursor++;
                    }
                  }
                  return const SizedBox(height: 20);
                },
                childCount:
                    groups.fold<int>(0, (sum, g) => sum + g.entries.length) + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _PlaceholderPage extends StatelessWidget {
  final SettingsEntry entry;
  final bool showBack;
  final VoidCallback? onBack;
  const _PlaceholderPage({
    required this.entry,
    required this.showBack,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainerLow),
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              ExpressiveSliverAppBar(
                title: entry.name,
                expandedHeight: 110,
                leading: showBack
                    ? MorphIconButton(
                        icon: Icons.arrow_back,
                        tooltip: l10n.homeBack,
                        onTap: onBack ?? () => Navigator.of(context).pop(),
                      )
                    : null,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        entry.icon,
                        size: 64,
                        color: cs.onSurfaceVariant.withOpacity(0.35),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        entry.name,
                        style: TextStyle(
                          fontSize: 22,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.subtitle.isNotEmpty
                            ? entry.subtitle
                            : l10n.settingsPlaceholderEasterEgg,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
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
}
