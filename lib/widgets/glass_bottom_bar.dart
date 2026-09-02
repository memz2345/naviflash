// lib/widgets/glass_bottom_bar.dart
//
// Compatibility facade for the project's existing bottom-bar call sites.
// Rendering and indicator physics now come from liquid_glass_widgets.
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:naviflash/services/settings_service.dart';
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

class GlassBottomBar extends StatelessWidget {
  final List<GlassBottomBarTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final double barHeight;

  const GlassBottomBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.barHeight = 60,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 叠加 Tooltip 层：每个底栏项的 label 作为 tooltip 内容（与 tab 文字一致），
    // 覆盖在 GlassTabBar 之上提供悬停/长按提示，同时透传拖拽给底层的 jelly 指示器。
    final bar = GlassTabBar.bottom(
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
        blur: 10,
        thickness: 18,
        tintOpacity: 0.04,
        lightIntensity: 0.05,
        ambientStrength: 0.02,
        fresnelStrength: 0.65,
        glowIntensity: 0.12,
        specularSharpness: GlassSpecularSharpness.soft,
      ),
      indicatorSettings: buildNaviGlassSettings(
        blur: 4,
        thickness: 18,
        tintOpacity: 0.08,
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
      maskingQuality: MaskingQuality.high,
      indicatorPinchStrength: 0.32,
      magnification: 1.08,
      glowBlurRadius: 16,
      glowSpreadRadius: 2,
      glowOpacity: 0.22,
      interactionGlowColor: colorScheme.primary.withValues(alpha: 0.32),
      pressScale: 1.02,
    );
    // 仅保留底层 GlassTabBar 的手势与拖拽，Tooltip 通过底层 BottomBarTabItem 内部已包裹的 Tooltip 触发；
    // 此处不再叠加会拦截水平拖拽的透明手势层，避免与 TabIndicator 的 jelly 拖拽冲突。
    return bar;
  }
}
