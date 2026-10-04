                                        
  
                                   
                                                  
                                         
                                                      
                                               
                             
                                             
                         
                                  
                       
                                      
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/history_center_page.dart';
import 'package:naviflash/screens/my_cache_page.dart';
import 'package:naviflash/screens/settings_split_screen.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/app_tooltip.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/src/custom_icons.dart';
import 'app_drawer.dart';
import 'app_toast.dart';
import 'expressive_app_bar.dart' show FrostedPanel;

class CollapsibleSideBar extends StatefulWidget {
                                                    
  final String currentPage;

                            
  final ValueChanged<String> onNavigate;

                                   
                                          
  final bool? expandedOverride;

                                         
                            
  final bool overlay;

                                         
  final VoidCallback? onOverlayMenuTap;

  const CollapsibleSideBar({
    super.key,
    this.currentPage = 'home',
    required this.onNavigate,
    this.expandedOverride,
    this.overlay = false,
    this.onOverlayMenuTap,
  });

             
                                               
  static const double minWidth = 80;

                     
  static const double expandedWidth = 224;

                                
  static const Duration animDuration = Duration(milliseconds: 260);
  static const Curve animCurve = Curves.easeInOutCubic;

                                             
  static final ValueNotifier<bool> expanded = ValueNotifier(false);
  static bool _loaded = false;

                              
  static Future<void> loadExpandedState() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      expanded.value = prefs.getBool('sideBarExpanded') ?? false;
    } catch (_) {}
  }

                                                  
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
                                                   
                                         
        final overlayBlur = overlay && isExpanded;
                                                               
        return RepaintBoundary(
          child: AnimatedContainer(
            duration: CollapsibleSideBar.animDuration,
            curve: CollapsibleSideBar.animCurve,
            width: isExpanded
                ? CollapsibleSideBar.expandedWidth
                : CollapsibleSideBar.minWidth,
                                             
                                 
            color: Colors.transparent,
                                                         
                                                         
                                                    
                                                               
                                                  
                                                             
            clipBehavior: Clip.hardEdge,
                                                              
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

                                          
                                            
                               
                    
                                            
                                     
  Widget _buildCollapsedRail(ColorScheme cs, AppLocalizations l10n) {
    final isSearchSelected = widget.currentPage == 'search';
                                              
                                                 
                                    
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: CollapsibleSideBar.minWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                                                      
                                                      
                                                        
                                                     
                                                  
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: CollapsibleSideBar.minWidth,
                                                           
                                              
                    height: 44,
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
                    icon: Icons.smart_display,
                    outlinedIcon: Icons.smart_display_outlined,
                    label: l10n.shortsTitle,
                    isSelected: widget.currentPage == 'shorts',
                    onTap: () => widget.onNavigate('shorts'),
                  ),
                  const SizedBox(height: 6),
                  _CollapsedNavItem(
                    icon: CustomIcons.motion_photos_on,
                    outlinedIcon: CustomIcons.motion_photos_on_outlined,
                    label: l10n.drawerDynamics,
                    isSelected: widget.currentPage == 'dynamics',
                    onTap: () => widget.onNavigate('dynamics'),
                  ),
                  const SizedBox(height: 6),
                  _CollapsedNavItem(
                    icon: Icons.forum,
                    outlinedIcon: Icons.forum_outlined,
                    label: l10n.drawerMessages,
                    isSelected: widget.currentPage == 'messages',
                    onTap: () => widget.onNavigate('messages'),
                  ),
                  const SizedBox(height: 6),
                                                   
                  _CollapsedNavItem(
                    icon: Icons.person,
                    outlinedIcon: Icons.person_outline,
                    label: l10n.drawerMine,
                    isSelected: widget.currentPage == 'mine',
                    onTap: () => widget.onNavigate('mine'),
                    avatar: ListenableBuilder(
                      listenable: BilibiliAccountService.instance,
                      builder: (context, _) {
                        final cs = Theme.of(context).colorScheme;
                        final url = BilibiliAccountService.instance.avatarUrl;
                        if (url.isEmpty) {
                          return CircleAvatar(
                            radius: 13,
                            backgroundColor: cs.onSurfaceVariant.withValues(
                              alpha: 0.2,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                          );
                        }
                        final headers =
                            NetworkSettingsService.instance.apiHeaders;
                        return CircleAvatar(
                          radius: 13,
                          backgroundImage: CachedImageProvider(
                            url,
                            headers: headers.isEmpty ? null : headers,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
                                              
            _MoreMenuButton(isExpanded: false),
                                 
            SafeArea(top: false, child: const SizedBox(height: 4)),
          ],
        ),
      ),
    );
  }

                                
                                                          
                                                     
  Widget _buildExpandedList(ColorScheme cs, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                                                    
                                       
                                                       
                                         
                                                      
                                                      
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: SizedBox(
                  width: 44,
                  height: 44,
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
                                                 
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
            children: [
                                                                       
              _expandedSearchTile(
                cs,
                isSelected: widget.currentPage == 'search',
                title: l10n.drawerSearch,
                onTap: () => widget.onNavigate('search'),
              ),
              const SizedBox(height: 4),
              _gmailCapsuleItem(
                cs,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                title: l10n.drawerHome,
                pageId: 'home',
              ),
              _gmailCapsuleItem(
                cs,
                icon: Icons.smart_display_outlined,
                selectedIcon: Icons.smart_display,
                title: l10n.shortsTitle,
                pageId: 'shorts',
              ),
              _gmailCapsuleItem(
                cs,
                icon: CustomIcons.motion_photos_on_outlined,
                selectedIcon: CustomIcons.motion_photos_on,
                title: l10n.drawerDynamics,
                pageId: 'dynamics',
              ),
              _gmailCapsuleItem(
                cs,
                icon: Icons.forum_outlined,
                selectedIcon: Icons.forum,
                title: l10n.drawerMessages,
                pageId: 'messages',
              ),
              _gmailCapsuleItem(
                cs,
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                title: l10n.drawerMine,
                pageId: 'mine',
              ),
                                                     
                                 
                                                       
            ],
          ),
        ),
                                     
        AnimatedSize(
          duration: CollapsibleSideBar.animDuration,
          curve: CollapsibleSideBar.animCurve,
          child: _BottomSection(isExpanded: true),
        ),
                           
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
        child: AnimatedContainer(
          duration: CollapsibleSideBar.animDuration,
          curve: CollapsibleSideBar.animCurve,
          decoration: BoxDecoration(
            color: isSelected ? cs.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Material(
            color: Colors.transparent,
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
                                               
                                      
                  AnimatedSwitcher(
                    duration: kThemeAnimationDuration,
                    switchInCurve: Curves.easeInOutCubicEmphasized,
                    switchOutCurve: Curves.easeInOutCubicEmphasized.flipped,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Icon(
                      key: ValueKey<bool>(isSelected),
                      isSelected ? selectedIcon : icon,
                      size: 22,
                      color: isSelected
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                                                                
                    child: AnimatedDefaultTextStyle(
                      duration: kThemeAnimationDuration,
                      curve: Curves.easeInOutCubicEmphasized,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant,
                      ),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        color: isSelected
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }


                                                 
                                                
                                           
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
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 26, color: fg),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                                                  
                                                 
                      height: 1,
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

class _CollapsedSearchButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CollapsedSearchButton({required this.isSelected, required this.onTap});

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
                                                  
   
                                                         
                                              
                                                             
                                
                                                         
                                               
class _CollapsedNavItem extends StatefulWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

                                    
              
  final Widget? avatar;

  const _CollapsedNavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.avatar,
  });

  @override
  State<_CollapsedNavItem> createState() => _CollapsedNavItemState();
}

class _CollapsedNavItemState extends State<_CollapsedNavItem>
    with SingleTickerProviderStateMixin {
                                             
                                                              
                                                          
                                                                    
                                                       
                     
  late final AnimationController _indicatorController;

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      duration: kThemeAnimationDuration,
      vsync: this,
      value: widget.isSelected ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(_CollapsedNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
                                                   
      widget.isSelected
          ? _indicatorController.forward()
          : _indicatorController.reverse();
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedBg = cs.primaryContainer;
    final selectedFg = cs.onPrimaryContainer;
                                         
                                   
    final Widget iconWidget;
    if (widget.avatar != null) {
                                         
      iconWidget = ClipOval(
        child: SizedBox(width: 26, height: 26, child: widget.avatar),
      );
    } else {
      iconWidget = AnimatedSwitcher(
        duration: kThemeAnimationDuration,
        switchInCurve: Curves.easeInOutCubicEmphasized,
        switchOutCurve: Curves.easeInOutCubicEmphasized.flipped,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: Icon(
          key: ValueKey<bool>(widget.isSelected),
          widget.isSelected ? widget.icon : widget.outlinedIcon,
          size: 24,
          color: widget.isSelected ? selectedFg : cs.onSurfaceVariant,
        ),
      );
    }
                                                  
                                       
                                           
                                                  
                                             
                                                 
                                         
    final pill = SizedBox(
      width: 56,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          NavigationIndicator(
            animation: _indicatorController,
            color: selectedBg,
            width: 56,
            height: 32,
            shape: const StadiumBorder(),
          ),
          iconWidget,
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                child: pill,
              ),
            ),
                                                 
                                                       
                     
            AnimatedSize(
              duration: CollapsibleSideBar.animDuration,
              curve: CollapsibleSideBar.animCurve,
              alignment: Alignment.topCenter,
              child: widget.isSelected && widget.label.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: kThemeAnimationDuration,
                        curve: Curves.easeInOutCubicEmphasized,
                        builder: (context, opacity, child) =>
                            Opacity(opacity: opacity, child: child),
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                            height: 1,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(height: 2),
            ),
          ],
        ),
      ),
    );
  }
}

                                                
                                           
                                                 
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
    return AppTooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

                                         
                                         
            
class _MoreMenuButton extends StatefulWidget {
  final bool isExpanded;

  const _MoreMenuButton({required this.isExpanded});

  @override
  State<_MoreMenuButton> createState() => _MoreMenuButtonState();
}

class _MoreMenuButtonState extends State<_MoreMenuButton> {
  final GlobalKey _buttonKey = GlobalKey();

                                              
     
                                                 
                                                
                                         
                         
                                                                             
                                            
  void _push(NavigatorState navigator, Widget page) {
    if (!navigator.mounted) return;
    navigator.push(MaterialPageRoute(builder: (_) => page));
  }

  void _showMenu() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
                                                   
    final navigator = Navigator.of(context);
    showGlassDropdownMenu(
      context,
      actions: [
        GlassMenuAction(
          icon: Icons.history,
          text: l10n.drawerHistory,
          onTap: () => _push(navigator, const HistoryCenterPage()),
        ),
        GlassMenuAction(
          icon: Icons.download_rounded,
          text: l10n.drawerMyCache,
          onTap: () => _push(navigator, const MyCachePage()),
        ),
        GlassMenuAction(
          icon: Icons.settings,
          text: l10n.drawerSettings,
          onTap: () => _push(
            navigator,
            const SplitSettingsScreen(isStandalone: true),
          ),
        ),
        GlassMenuAction(
          icon: Icons.info_outline,
          text: l10n.drawerAbout,
                                                  
          onTap: () => showDrawerInfoDialog(navigator.context),
        ),
      ],
                                         
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
          height: 44,
          child: Icon(Icons.more_vert, size: 22, color: cs.onSurfaceVariant),
        ),
      ),
    );
    if (!isExpanded) {
                                     
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: CollapsibleSideBar.minWidth,
                                          
          height: 44,
          child: Center(
            child: AppTooltip(message: l10n.sideBarMore, child: capsule),
          ),
        ),
      );
    }
                                         
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

                               
class _BottomSection extends StatelessWidget {
  final bool isExpanded;

  const _BottomSection({required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    final settingsService = context.read<SettingsService>();
                                       
    return ListenableBuilder(
      listenable: BilibiliAccountService.instance,
      builder: (context, _) => _buildBody(context, settingsService),
    );
  }

  Widget _buildBody(BuildContext context, SettingsService settingsService) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final account = BilibiliAccountService.instance;
    final loggedIn = account.isLoggedIn;
                                        
    final name = loggedIn && account.uname.isNotEmpty
        ? account.uname
        : (settingsService.nickname?.isNotEmpty == true
              ? settingsService.nickname!
              : '请先登录');
    final hasAvatar =
        settingsService.avatarPath != null &&
        File(settingsService.avatarPath!).existsSync();
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    final ImageProvider? avatarImage = loggedIn && account.avatarUrl.isNotEmpty
        ? CachedImageProvider(
            BilibiliUserSpaceService.avatarUrl(account.avatarUrl),
            headers: headers,
          )
        : hasAvatar
        ? FileImage(File(settingsService.avatarPath!))
        : null;

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
            avatarImage ?? const AssetImage('assets/bili_icons/noface.jpeg'),
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
                      name,
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
                children: [avatar, const SizedBox(height: 4), themeBtn],
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
