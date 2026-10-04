import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/screens/ai_settings_screen.dart';
import 'package:naviflash/screens/player_settings_screen.dart';
import 'package:naviflash/screens/player_shortcuts_screen.dart';
import 'package:naviflash/screens/log_viewer_page.dart';
import 'package:naviflash/screens/open_source_licenses_page.dart';
import 'package:naviflash/screens/storage_settings_screen.dart';
import '../screens/about_page.dart';
import '../screens/display_settings_screen.dart';
import '../screens/preferences_screen.dart';
import '../screens/recommend_settings_screen.dart';
import '../screens/ugc_filter_settings_screen.dart';
import '../screens/network_settings_screen.dart';
import '../screens/accounts_screen.dart';
import '../screens/language_settings_screen.dart';
import '../widgets/morph_card.dart';
import '../widgets/app_toast.dart';
import '../widgets/expressive_app_bar.dart';
import '../widgets/side_bar_menu_button.dart';
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

                      
  late final _RightNavObserver _rightNavObserver;

                                                      
                                                              
  bool _observerRebuildPending = false;

  bool get _isWideScreen => MediaQuery.of(context).size.width >= 768;

             
  int _titleTapCount = 0;
  DateTime _lastTitleTap = DateTime(2000);

                          
                                         
                      
  late final ScrollController _compactScroll = ScrollController();
  bool _compactBarCollapsed = false;

  @override
  void dispose() {
    _compactScroll.dispose();
    super.dispose();
  }

  void _onCompactScroll(ScrollNotification n) {
    if (n is! ScrollUpdateNotification) return;
    final collapsed = n.metrics.extentBefore > 48;
    if (collapsed != _compactBarCollapsed) {
      setState(() => _compactBarCollapsed = collapsed);
    }
  }

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
                              
        SettingsEntry(
          name: l10n.settingsStorage,
          route: '/storage',
          icon: Icons.storage_outlined,
          subtitle: l10n.settingsStorageSub,
        ),
                                         
                              
        SettingsEntry(
          name: l10n.settingsAi,
          route: '/ai',
          icon: Icons.auto_awesome_outlined,
          subtitle: l10n.settingsAiSub,
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
                                   
        SettingsEntry(
          name: l10n.settingsLanguage,
          route: '/language',
          icon: Icons.translate,
          subtitle: l10n.settingsLanguageSub,
        ),
                         
        SettingsEntry(
          name: l10n.settingsPlayer,
          route: '/player',
          icon: Icons.play_circle_outline,
          subtitle: l10n.settingsPlayerSub,
        ),
                                    
        SettingsEntry(
          name: '快捷键',
          route: '/shortcuts',
          icon: Icons.keyboard_alt_outlined,
          subtitle: '播放器键盘快捷键',
        ),
                                       
        SettingsEntry(
          name: l10n.settingsPreferences,
          route: '/preferences',
          icon: Icons.tune_outlined,
          subtitle: l10n.settingsPreferencesSub,
        ),
                                                         
        SettingsEntry(
          name: l10n.settingsRecommend,
          route: '/recommend',
          icon: Icons.recommend_outlined,
          subtitle: l10n.settingsRecommendSub,
        ),
                                                
        SettingsEntry(
          name: l10n.ugcFilterTitle,
          route: '/ugc-filter',
          icon: Icons.filter_alt_outlined,
          subtitle: l10n.ugcFilterSectionScopes,
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
          name: l10n.drawerAbout,
          route: '/about',
          icon: Icons.info_outline,
          subtitle: l10n.settingsAboutSub,
        ),
                     
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
                                        
    _rightNavObserver = _RightNavObserver(_onRightNavStackChanged);
    if (widget.initialRoute != null) {
      final exists = _allEntries.any((e) => e.route == widget.initialRoute);
      if (exists) _selectedRoute = widget.initialRoute!;
    }
  }

                                                
     
                                                     
                                        
                                                 
  void _onRightNavStackChanged() {
    if (_observerRebuildPending) return;
    _observerRebuildPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _observerRebuildPending = false;
      if (mounted) setState(() {});
    });
  }

                                     
  Future<void> _openSearch() async {
              
    HapticFeedback.lightImpact();
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => SettingsSearchPage(onSelect: _onSearchResult),
      ),
    );
  }

                                         
                                          
  void _onSearchResult(SettingsSearchEntry target, Rect cardRect) {
                              
    if (target.pageRoute == '/about') {
      showAppToast(context, '暂不可用');
      return;
    }
                               
    SettingsSearchController.request(
      pageRoute: target.pageRoute,
      optionKey: target.optionKey,
      pageTitle: target.pageTitle,
      optionName: target.name,
    );
                                    
    if (_isWideScreen && _selectedRoute != target.pageRoute) {
      setState(() {
        _selectedRoute = target.pageRoute;
        _rightNavKey = GlobalKey<NavigatorState>();              
      });
    }
    final entry = _allEntries.firstWhere(
      (e) => e.route == target.pageRoute,
      orElse: () => _allEntries.first,
    );
                                                 
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
                                      
    if (widget.isStandalone && !_isWideScreen) {
      return SideBarMenuButton(
        tooltip: l10n.homeOpenMenu,
        transparent: false,
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
              
    HapticFeedback.lightImpact();
                               
    if (entry.route == '/about') {
      showAppToast(context, '暂不可用');
      return;
    }
    if (_isWideScreen) {
      if (_selectedRoute == entry.route) return;
      setState(() {
        _selectedRoute = entry.route;
        _rightNavKey = GlobalKey<NavigatorState>();              
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _buildSubPage(entry, showBack: true)),
      );
    }
  }


                       
     
                                 
                                                            
  Widget _buildSubPage(SettingsEntry entry, {required bool showBack}) {
    switch (entry.route) {
      case '/display':
        return DisplaySettingsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
                      
      case '/network':
        return NetworkSettingsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
                                 
      case '/language':
        return LanguageSettingsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
                   
      case '/player':
        return PlayerSettingsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
                                
      case '/shortcuts':
        return PlayerShortcutsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
                              
      case '/preferences':
        return PreferencesScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
                                           
      case '/recommend':
        return RecommendSettingsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
                         
      case '/ugc-filter':
        return UgcFilterSettingsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
                   
      case '/licenses':
        return OpenSourceLicensesPage(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
                      
      case '/accounts':
        return AccountsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
                      
      case '/logs':
        return LogViewerPage(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
                            
      case '/storage':
        return StorageSettingsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
                                           
      case '/ai':
        return AiSettingsScreen(
          isSplitView: !showBack,
          onBack: showBack ? () => Navigator.of(context).pop() : null,
        );
                                                         
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
                                                     
    final rightCanPop = _rightNavKey.currentState?.canPop() ?? false;

    return PopScope(
      canPop: !(_isWideScreen && rightCanPop),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
                                  
        if (_isWideScreen && _rightNavKey.currentState?.canPop() == true) {
          _rightNavKey.currentState!.pop();
        }
                                             
                                            
      },
      child: _isWideScreen ? _buildSplitLayout() : _buildCompactLayout(),
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
                                               
                                                
                                 
          SizedBox(width: 300, child: _buildLeftPanel()),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(
            child: Navigator(
              key: _rightNavKey,
              observers: [_rightNavObserver],          
              onGenerateRoute: (_) {
                return MaterialPageRoute(
                  builder: (_) {
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
                                                 
                                                           
    final spacerHeight =
        MediaQuery.of(context).padding.top +
        (_compactBarCollapsed ? 56.0 : 152.0);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: cs.surfaceContainerLow,
      drawer: const AppDrawer(currentPage: 'settings'),
                                    
      onDrawerChanged: SideBarDrawerState.setOpen,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainerLow),
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                _onCompactScroll(n);
                return false;
              },
              child: CustomScrollView(
                controller: _compactScroll,
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),                                                  
                slivers: [
                  SliverToBoxAdapter(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      height: spacerHeight,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
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
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: _buildCompactBar(cs, l10n),
          ),
        ],
      ),
    );
  }

                                         
                                                   
  Widget _buildCompactBar(ColorScheme cs, AppLocalizations l10n) {
    const dur = Duration(milliseconds: 220);
    return FrostedPanel(
      opacity: 0.75,
      blurSigma: 12,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  _buildLeading(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _compactBarCollapsed ? 1 : 0,
                      duration: dur,
                      curve: Curves.easeInOut,
                      child: GestureDetector(
                        onTap: _onTitleTap,
                        child: Text(
                          l10n.drawerSettings,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ),
                  MorphIconButton(
                    icon: Icons.search,
                    tooltip: l10n.settingsSearch,
                    onTap: _openSearch,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _compactBarCollapsed ? 0.0 : 1.0),
              duration: dur,
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return ClipRect(
                  child: Align(
                    heightFactor: value,
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                );
              },
              child: SizedBox(
                height: 96,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                                                              
                    padding: const EdgeInsets.only(left: 16, bottom: 28),
                    child: GestureDetector(
                      onTap: _onTitleTap,
                      child: Text(
                        l10n.drawerSettings,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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

                                                         

  Widget _buildLeftPanel() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final groups = _buildGroups(l10n);

    return Container(
      color: cs.surfaceContainerLow,
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),                                                  
        slivers: [
          ExpressiveSliverAppBar(
            title: l10n.drawerSettings,
            expandedHeight: 152,
            onTitleRepeatedTap: _onTitleTap,
            leading: widget.isStandalone
                ? SideBarMenuButton(
                    tooltip: l10n.openSidebar,
                    transparent: false,
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
                                      : cs.onSurface.withValues(alpha: 0.85),
                                ),
                              ),
                              subtitle: Text(
                                entry.subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? cs.onSecondaryContainer.withValues(alpha: 0.7)
                                      : cs.onSurfaceVariant.withValues(alpha: 0.7),
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
            physics: const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),                                                  
            slivers: [
              ExpressiveSliverAppBar(
                title: entry.name,
                expandedHeight: 152,
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
                        color: cs.onSurfaceVariant.withValues(alpha: 0.35),
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
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
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
