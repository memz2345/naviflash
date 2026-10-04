                                    
  
                                                                         
                                                                      
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/src/custom_icons.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/liquid_glass.dart';

class GlassBottomBarTab {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;

  const GlassBottomBarTab({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });
}

                                               
   
                                                          
                             
GlassBottomBarTab navItemTab(String id, AppLocalizations l10n) {
  return switch (id) {
    'dynamics' => GlassBottomBarTab(
      label: l10n.bottomNavItemDynamics,
      icon: CustomIcons.motion_photos_on_outlined,
      selectedIcon: CustomIcons.motion_photos_on,
    ),
    'live' => GlassBottomBarTab(
      label: l10n.bottomNavItemLive,
      icon: Icons.live_tv_outlined,
      selectedIcon: Icons.live_tv,
    ),
    'shorts' => GlassBottomBarTab(
      label: l10n.shortsTitle,
      icon: Icons.smart_display_outlined,
      selectedIcon: Icons.smart_display,
    ),
    'messages' => GlassBottomBarTab(
      label: l10n.drawerMessages,
      icon: Icons.forum_outlined,
      selectedIcon: Icons.forum,
    ),
    'mine' => GlassBottomBarTab(
      label: l10n.drawerMine,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
    _ => GlassBottomBarTab(
      label: l10n.bottomNavItemHome,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
  };
}

class GlassBottomBar extends StatelessWidget {
  final List<GlassBottomBarTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final double barHeight;

                                       
  final GlassTabBarExtraButton? extraButton;

  const GlassBottomBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.barHeight = 60,
    this.extraButton,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
                                    
                                                
    bool jelly = true;
    try {
      jelly = context.select<SettingsService, bool>(
        (s) => s.liquidGlassBottomBarJelly,
      );
    } on ProviderNotFoundException {
      jelly = true;
    }
                                                           
                                                        
    final bar = GlassTabBar.bottom(
      extraButton: extraButton,
      tabs: [
        for (final tab in tabs)
          GlassTab(
            label: tab.label,
            icon: Icon(tab.icon),
            activeIcon: Icon(tab.selectedIcon ?? tab.icon),
            glowColor: colorScheme.primary.withValues(alpha: 0.22),
          ),
      ],
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
      barHeight: barHeight,
      horizontalPadding: 12,
      verticalPadding: 8,
      enableBlend: true,
      blendAmount: 10,
      iconSize: 22,
      labelFontSize: 12,
      selectedIconColor: colorScheme.primary,
      selectedLabelColor: colorScheme.primary,
      unselectedIconColor: colorScheme.onSurface.withValues(alpha: 0.72),
      unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.72),
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      indicatorColor: colorScheme.primary.withValues(alpha: 0.10),
                                       
      settings: buildNaviGlassSettings(
        blur: 12,
        thickness: 14,
        tintOpacity: 0.02,
        lightIntensity: 0.05,
        ambientStrength: 0,
        fresnelStrength: 0.5,
        glowIntensity: 0.08,
        specularSharpness: GlassSpecularSharpness.soft,
                                                     
                                                   
                                   
                                                 
        shadowElevation: 0,
      ),
      indicatorSettings: buildNaviGlassSettings(
        blur: 4,
        thickness: 16,
        tintOpacity: 0.1,
        lightIntensity: 0.04,
        ambientStrength: 0.01,
        ambientRim: 0.01,
        fresnelStrength: 0.18,
        glowIntensity: 0,
        chromaticAberration: 0,
        shadowElevation: 0,
        specularSharpness: GlassSpecularSharpness.soft,
      ),
      quality: SettingsService.fragmentRenderingEnabled
          ? GlassQuality.premium
          : GlassQuality.minimal,
      maskingQuality: jelly ? MaskingQuality.high : MaskingQuality.off,
      indicatorPinchStrength: 0.32,
      magnification: 1.08,
      glowBlurRadius: 16,
      glowSpreadRadius: 2,
      glowOpacity: 0.22,
      interactionGlowColor: colorScheme.primary.withValues(alpha: 0.32),
      pressScale: 1.02,
    );
                                                                                
                                                         
    return bar;
  }
}

                                 
                                       
   
                                        
                                          
                                                            
                                    
class AppBottomBar extends StatelessWidget {
  final List<GlassBottomBarTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final double barHeight;

                                          
  final GlassTabBarExtraButton? extraButton;

                                                    
                                                   
  final GlassBottomBarTab? optionalTab;

                                              
  final VoidCallback? onOptionalTab;

                                             
  final VoidCallback? onLongPress;

  const AppBottomBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.barHeight = 60,
    this.extraButton,
    this.optionalTab,
    this.onOptionalTab,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
                                                       
                                 
    bool useM3 = false;
    try {
      useM3 = context.select<SettingsService, bool>(
        (settings) => settings.useM3BottomBar,
      );
    } on ProviderNotFoundException {
      useM3 = false;
    }
    late final Widget bar;
    if (useM3) {
      final count = tabs.length;
      final hasOptional = optionalTab != null;
                                                       
                                                
                                             
      bar = FrostedPanel(
        opacity: 0.75,
        child: Padding(
                                                   
                                       
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
                                                    
                                                      
            selectedIndex: selectedIndex < 0
                ? 0
                : selectedIndex.clamp(0, count - 1),
            onDestinationSelected: (index) {
              if (hasOptional && index >= count) {
                onOptionalTab?.call();
              } else {
                onTabSelected(index);
              }
            },
            destinations: [
              for (final tab in tabs)
                NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon ?? tab.icon),
                  label: tab.label,
                  tooltip: tab.label,
                ),
              if (hasOptional)
                NavigationDestination(
                  icon: Icon(optionalTab!.icon),
                  selectedIcon:
                      Icon(optionalTab!.selectedIcon ?? optionalTab!.icon),
                  label: optionalTab!.label,
                  tooltip: optionalTab!.label,
                ),
            ],
          ),
        ),
      );
    } else {
      bar = GlassBottomBar(
        tabs: tabs,
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
        barHeight: barHeight,
        extraButton: extraButton,
      );
    }
    final onLongPress = this.onLongPress;
    if (onLongPress == null) return bar;
                                            
                                   
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: onLongPress,
      child: bar,
    );
  }
}
