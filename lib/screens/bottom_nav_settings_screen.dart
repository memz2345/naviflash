                                              
  
                                                
  
                                                   
                                                    
                                           
                                            
                                               
  
                                                              
                                                    
                                                         
                                                   
                                            
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/liquid_glass_bar_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/bottom_nav_settings_dialog.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/glass_bottom_bar.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:provider/provider.dart';

class BottomNavSettingsScreen extends StatefulWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const BottomNavSettingsScreen({
    super.key,
    this.isSplitView = false,
    this.onBack,
  });

  @override
  State<BottomNavSettingsScreen> createState() =>
      _BottomNavSettingsScreenState();
}

class _BottomNavSettingsScreenState extends State<BottomNavSettingsScreen>
    with RouteAware {
                          
  bool _isTopRoute = true;
  bool _nativeBarShown = false;
  String? _nativeBarKey;
  int? _nativeBarIndex;
  ModalRoute<dynamic>? _nativeBarRoute;

                                  
  int _previewIndex = 0;

  @override
  void initState() {
    super.initState();
    LiquidGlassBarService.bindTabSelected(_onBarTabSelected);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _nativeBarRoute) {
      if (_nativeBarRoute != null) {
        liquidGlassBarRouteObserver.unsubscribe(this);
      }
      _nativeBarRoute = route;
      liquidGlassBarRouteObserver.subscribe(this, route);
                                      
      _isTopRoute = route.isCurrent;
    }
  }

  @override
  void didPushNext() {
    _isTopRoute = false;
    _hideNativeBar();
  }

  @override
  void didPopNext() {
    _isTopRoute = true;
    if (mounted) setState(() {});
  }

  void _hideNativeBar() {
    if (!_nativeBarShown) return;
    _nativeBarShown = false;
    _nativeBarKey = null;
    _nativeBarIndex = null;
    debugPrint('[glassbar] hide（底栏设置页被盖住 / 销毁）');
    unawaited(LiquidGlassBarService.hide());
  }

  @override
  void dispose() {
    liquidGlassBarRouteObserver.unsubscribe(this);
    _nativeBarRoute = null;
    LiquidGlassBarService.unbindTabSelected(_onBarTabSelected);
                                               
    if (LiquidGlassBarService.ownsVisibleBar(_onBarTabSelected)) {
      unawaited(LiquidGlassBarService.hide());
    }
    super.dispose();
  }

                                           
  void _onBarTabSelected(int index) {
    if (!mounted) return;
    setState(() => _previewIndex = index);
    unawaited(LiquidGlassBarService.refresh(force: true));
  }

  List<GlassBottomBarTab> _tabs(AppLocalizations l10n, SettingsService s) {
    final tabs = [
      for (final id in s.bottomNavOrder) navItemTab(id, l10n),
    ];
    if (s.bottomBarSearch) {
      tabs.add(
        GlassBottomBarTab(
          label: l10n.settingsSearch,
          icon: Icons.search_outlined,
          selectedIcon: Icons.search,
        ),
      );
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsService>();
    final tabs = _tabs(l10n, settings);
    final index = tabs.isEmpty
        ? 0
        : _previewIndex.clamp(0, tabs.length - 1).toInt();

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      bottomNavigationBar: _buildPreviewBar(tabs, index, l10n),
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainerLow),
          ScrollConfiguration(
            behavior: const MaterialScrollBehavior(),
            child: CustomScrollView(
              slivers: [
                ExpressiveSliverAppBar(
                  title: l10n.bottomNavSettingsTitle,
                  expandedHeight: 152,
                  leading: widget.isSplitView
                      ? null
                      : MorphIconButton(
                          tooltip: l10n.startScreenGoBack,
                          icon: Icons.arrow_back,
                          onTap:
                              widget.onBack ??
                              () => Navigator.of(context).pop(),
                        ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.bottomNavSettingsSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.bottomNavPreviewHint,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...buildMorphSegmentedList([
                          for (final id in SettingsService.kAllBottomNavIds)
                            MorphRowItem(
                              interactive: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: bottomNavSettingRow(
                                  context,
                                  id: id,
                                  l10n: l10n,
                                  order: settings.bottomNavOrder,
                                  onChanged: (next) async {
                                    await settings.setBottomNavOrder(next);
                                    if (mounted) setState(() {});
                                  },
                                ),
                              ),
                            ),
                        ]),
                        const SizedBox(height: 20),
                        ...buildMorphSegmentedList([
                          MorphRowItem(
                            interactive: false,
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.search_outlined,
                                size: 26,
                                color: cs.primary,
                              ),
                              title: Text(l10n.prefBottomBarSearch),
                              subtitle: Text(
                                l10n.prefBottomBarSearchDesc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              value: settings.bottomBarSearch,
                              onChanged: (v) => settings.setBottomBarSearch(v),
                            ),
                          ),
                          MorphRowItem(
                            interactive: false,
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.dock_outlined,
                                size: 26,
                                color: cs.primary,
                              ),
                              title: Text(l10n.prefUseM3BottomBar),
                              value: settings.useM3BottomBar,
                              onChanged: (v) => settings.setUseM3BottomBar(v),
                            ),
                          ),
                          MorphRowItem(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.restart_alt,
                                size: 26,
                                color: cs.primary,
                              ),
                              title: Text(l10n.bottomNavSettingsReset),
                              onTap: () async {
                                await settings.setBottomNavOrder(
                                  List.of(SettingsService.kDefaultBottomNavOrder),
                                );
                                await settings.setBottomBarSearch(true);
                                await settings.setUseM3BottomBar(false);
                                if (!context.mounted) return;
                                setState(() => _previewIndex = 0);
                                showAppToast(context, l10n.bottomNavResetDone);
                              },
                            ),
                          ),
                        ]),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

                                      
  Widget _buildPreviewBar(
    List<GlassBottomBarTab> tabs,
    int index,
    AppLocalizations l10n,
  ) {
    final useNative = LiquidGlassBarService.canUseNative;
                                       
    _syncNativeBar(visible: useNative, tabs: tabs, index: index, l10n: l10n);
    if (useNative) {
      return SizedBox(height: LiquidGlassBarService.slotHeight(context));
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: AppBottomBar(
          tabs: tabs,
          selectedIndex: index,
          onTabSelected: _onBarTabSelected,
        ),
      ),
    );
  }

                           
  void _syncNativeBar({
    required bool visible,
    required List<GlassBottomBarTab> tabs,
    required int index,
    required AppLocalizations l10n,
  }) {
    if (!visible || !_isTopRoute || tabs.isEmpty) {
      _hideNativeBar();
      return;
    }
    LiquidGlassBarService.refresh();
    final size = MediaQuery.sizeOf(context);
    final key =
        '${tabs.length}|${tabs.map((t) => t.label).join(',')}|'
        '${size.width.round()}x${size.height.round()}';
    if (_nativeBarShown && _nativeBarKey == key && _nativeBarIndex == index) {
      return;
    }
    final needShow = !_nativeBarShown || _nativeBarKey != key;
    _nativeBarKey = key;
    _nativeBarIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (needShow) {
        final ok = await LiquidGlassBarService.show(
          context: context,
          tabs: [
            for (var i = 0; i < tabs.length; i++)
              LiquidGlassBarTab(
                id: 'preview$i',
                label: tabs[i].label,
                icon: tabs[i].icon,
                selectedIcon: tabs[i].selectedIcon,
              ),
          ],
          index: index,
          accent: Theme.of(context).colorScheme.primary,
        );
        if (!ok) {
                                           
          LiquidGlassBarService.enabled = false;
          if (mounted) setState(() {});
          return;
        }
        _nativeBarShown = true;
      } else {
        await LiquidGlassBarService.updateIndex(index);
      }
      await LiquidGlassBarService.refresh(force: true);
    });
  }
}
