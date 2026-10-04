                                           
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/more_menu_sheet.dart';
import '../services/settings_service.dart';
import '../services/native_menu_service.dart';
import '../services/display_mode_service.dart';
import '../services/device_corner_service.dart';
import '../services/splash_service.dart';
import '../screens/display_scale_page.dart';
import '../screens/font_weight_screen.dart';
import '../screens/theme_selector_screen.dart';
import '../screens/display_mode_screen.dart';
import '../screens/liquid_glass_tuner_screen.dart';
import '../screens/page_background_settings_page.dart';
import '../widgets/widgets.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';
import '../l10n/app_localizations.dart';

class DisplaySettingsScreen extends StatefulWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const DisplaySettingsScreen({
    super.key,
    this.isSplitView = false,
    this.onBack,
  });

  @override
  State<DisplaySettingsScreen> createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends State<DisplaySettingsScreen> {
                        
                                             
                           
  late final ScrollController _scroll = ScrollController();
  bool _barCollapsed = false;

                                      
  bool _hasSplashBackground = false;
  bool _splashApplying = false;

  @override
  void initState() {
    super.initState();
    if (SplashService.isSupported) {
      SplashService.hasBackground().then((v) {
        if (mounted) setState(() => _hasSplashBackground = v);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onBarScroll(ScrollNotification n) {
    if (n is! ScrollUpdateNotification) return;
    final collapsed = n.metrics.extentBefore > 48;
    if (collapsed != _barCollapsed) {
      setState(() => _barCollapsed = collapsed);
    }
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

                                       
                                              
  Future<void> _pickSplashBackground() async {
    if (_splashApplying) return;
    final l10n = AppLocalizations.of(context);
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null) return;
    setState(() => _splashApplying = true);
    final ok = await SplashService.setBackground(picked.path);
    if (!mounted) return;
    setState(() {
      _splashApplying = false;
      if (ok) _hasSplashBackground = true;
    });
    showAppToast(
      context,
      ok
          ? l10n.displaySplashBackgroundSetDone
          : l10n.displaySplashBackgroundSetFailed,
      error: !ok,
    );
  }

                      
  Future<void> _clearSplashBackground() async {
    if (_splashApplying) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _splashApplying = true);
    final ok = await SplashService.clearBackground();
    if (!mounted) return;
    setState(() {
      _splashApplying = false;
      if (ok) _hasSplashBackground = false;
    });
    showAppToast(
      context,
      ok
          ? l10n.displaySplashBackgroundCleared
          : l10n.displaySplashBackgroundSetFailed,
      error: !ok,
    );
  }

                                          
                           
                        
  void _navigateTo(String route) {
    Widget page;
    switch (route) {
      case '/display-scale':
        page = const DisplayScalePage();
        break;
      case '/font-weight':
        page = const FontWeightScreen();
        break;
      case '/theme':
        page = ThemeSelectorScreen(isSplitView: widget.isSplitView);
        break;
      case '/display-mode':
        page = const DisplayModeScreen();
        break;
      case '/liquid-glass-tuner':
        page = const LiquidGlassTunerScreen();
        break;
      case '/page-background':
        page = PageBackgroundSettingsPage(isSplitView: widget.isSplitView);
        break;
      default:
        return;
    }
                      
    HapticFeedback.lightImpact();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  String _getThemeModeText(ThemeMode mode) {
    final l10n = AppLocalizations.of(context);
    switch (mode) {
      case ThemeMode.light:
        return l10n.displayThemeLight;
      case ThemeMode.dark:
        return l10n.displayThemeDark;
      case ThemeMode.system:
        return l10n.drawerSystemMode;
    }
  }

  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  Future<void> _showThemeModePicker(
    BuildContext context,
    SettingsService service,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      items: [
        for (final mode in ThemeMode.values)
          NativeMenuItem(
            text: _getThemeModeText(mode),
            icon: _getThemeModeIcon(mode),
            checked: service.themeMode == mode,
            onTap: () => service.setThemeMode(mode),
          ),
      ],
    );
    if (nativeOk || !context.mounted) return;
    showAppBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kGroupRadius)),
      ),
      builder: (ctx) => FrostedSheet(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(kGroupRadius),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: RadioGroup<ThemeMode>(
              groupValue: service.themeMode,
              onChanged: (val) {
                if (val != null) {
                  service.setThemeMode(val);
                  Navigator.pop(ctx);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ...ThemeMode.values.map((mode) {
                    final isSelected = service.themeMode == mode;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      child: MorphItem(
                        selected: isSelected,
                        isFirst: mode == ThemeMode.values.first,
                        isLast: mode == ThemeMode.values.last,
                        child: RadioListTile<ThemeMode>(
                          title: Text(
                            _getThemeModeText(mode),
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          secondary: Icon(
                            _getThemeModeIcon(mode),
                            color:
                                isSelected ? cs.primary : cs.onSurfaceVariant,
                          ),
                          value: mode,
                          activeColor: cs.primary,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsService = context.watch<SettingsService>();
    final isPureBlackVisible = settingsService.themeMode != ThemeMode.light;
    final l10n = AppLocalizations.of(context);

                                   
    final seedScheme = ColorScheme.fromSeed(
      seedColor: settingsService.themeSeedColor,
    );

    return PopScope(
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
        body: Stack(
          children: [
            PageBackground(baseColor: colorScheme.surfaceContainer),
                                                          
                                       
                                         
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  _onBarScroll(n);
                  return false;
                },
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior(),
                  child: CustomScrollView(
                    controller: _scroll,
                    slivers: [
                      SliverToBoxAdapter(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          height:
                              MediaQuery.of(context).padding.top +
                              (_barCollapsed ? 56.0 : 120.0),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                                                                 
                                                                
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                         
                              _buildSectionTitle(
                                context,
                                l10n.displaySectionAppearance,
                              ),
                              const SizedBox(height: 12),
                              MorphItem(
                                selected: false,
                                isFirst: true,
                                isLast: !isPureBlackVisible,
                                flashKey: 'theme_mode',
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: Icon(
                                    _getThemeModeIcon(
                                      settingsService.themeMode,
                                    ),
                                    size: 26,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  title: Text(l10n.displayThemeMode),
                                  subtitle: Text(
                                    _getThemeModeText(
                                      settingsService.themeMode,
                                    ),
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onTap: () => _showThemeModePicker(
                                    context,
                                    settingsService,
                                  ),
                                ),
                              ),
                              _AnimatedCollapse(
                                visible: isPureBlackVisible,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: kCardGap),
                                  child: MorphItem(
                                    selected: false,
                                    isFirst: false,
                                    isLast: true,
                                    flashKey: 'pure_black',
                                    child: SwitchListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                      secondary: Icon(
                                        Icons.brightness_2_outlined,
                                        size: 26,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      title: Text(l10n.displayPureBlack),
                                      subtitle: Text(
                                        settingsService.isPureBlackMode
                                            ? l10n.displayPureBlackOn
                                            : l10n.displayOff,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      value: settingsService.isPureBlackMode,
                                      onChanged: (value) => settingsService
                                          .setIsPureBlackMode(value),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                                          
                              _buildSectionTitle(
                                context,
                                l10n.displaySectionPersonalize,
                              ),
                              const SizedBox(height: 12),
                              ...buildMorphSegmentedList([
                                                                              
                                                                  
                                                                              
                                MorphRowItem(
                                  flashKey: 'theme_color',
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: Icon(
                                      Icons.palette_outlined,
                                      size: 26,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(l10n.displayThemeColor),
                                    subtitle: Text(
                                      settingsService.useDynamicColor
                                          ? l10n.displayFollowSystemColor
                                          : _getSeedColorName(
                                              settingsService.themeSeedColor,
                                            ),
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                                     
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: ClipOval(
                                            child: CustomPaint(
                                              size: const Size(22, 22),
                                              painter: FourColorPainter(
                                                topLeft:
                                                    seedScheme.primaryContainer,
                                                topRight: seedScheme
                                                    .secondaryContainer,
                                                bottomLeft: seedScheme.primary,
                                                bottomRight:
                                                    seedScheme.secondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                    onTap: () => _navigateTo('/theme'),
                                  ),
                                ),
                                MorphRowItem(
                                  flashKey: 'font_weight',
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: Icon(
                                      Icons.format_bold_outlined,
                                      size: 26,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(l10n.displayFontWeight),
                                    subtitle: Text(
                                      _getFontWeightLabel(
                                        settingsService.fontWeight,
                                      ),
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'A',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: _toFontWeight(
                                              settingsService.fontWeight,
                                            ),
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                    onTap: () => _navigateTo('/font-weight'),
                                  ),
                                ),
                                MorphRowItem(
                                  flashKey: 'display_scale',
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: Icon(
                                      Icons.zoom_in_outlined,
                                      size: 26,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(l10n.displayScaleTitle),
                                    subtitle: Text(
                                      _getScaleDescription(
                                        settingsService.displayScale,
                                      ),
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${(settingsService.displayScale * 100).round()}%',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                    onTap: () => _navigateTo('/display-scale'),
                                  ),
                                ),
                                                        
                                                               
                                                    
                                if (Platform.isAndroid)
                                  MorphRowItem(
                                    flashKey: 'splash_background',
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      leading: Icon(
                                        Icons.wallpaper_outlined,
                                        size: 26,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      title: Text(
                                        l10n.displaySplashBackground,
                                      ),
                                      subtitle: Text(
                                        _hasSplashBackground
                                            ? l10n
                                                .displaySplashBackgroundCustom
                                            : l10n
                                                .displaySplashBackgroundDefault,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      trailing: _splashApplying
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                              ),
                                            )
                                          : _hasSplashBackground
                                              ? IconButton(
                                                  tooltip: l10n
                                                      .displaySplashBackgroundClearTooltip,
                                                  icon: Icon(
                                                    Icons.restart_alt,
                                                    size: 22,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  onPressed:
                                                      _clearSplashBackground,
                                                )
                                              : Icon(
                                                  Icons.chevron_right,
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                      onTap: _pickSplashBackground,
                                    ),
                                  ),
                                MorphRowItem(
                                  flashKey: 'hero_transition_blur',
                                  child: SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    secondary: Icon(
                                      Icons.blur_on_outlined,
                                      size: 26,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(l10n.displayHeroTransitionBlur),
                                    value: settingsService.heroTransitionBlur,
                                    onChanged: (value) => settingsService
                                        .setHeroTransitionBlur(value),
                                  ),
                                ),
                                MorphRowItem(
                                  flashKey: 'ios_push_transition',
                                  child: SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    secondary: Icon(
                                      Icons.animation,
                                      size: 26,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(l10n.displayIosPushTransition),
                                    value: settingsService.iosPushTransition,
                                    onChanged: (value) => settingsService
                                        .setIosPushTransition(value),
                                  ),
                                ),
                                MorphRowItem(
                                  flashKey: 'advanced_glass',
                                  child: SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    secondary: Icon(
                                      Icons.auto_awesome_outlined,
                                      size: 26,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(l10n.displayAdvancedGlass),
                                    value:
                                        settingsService.enableFragmentRendering,
                                    onChanged: (value) => settingsService
                                        .setEnableFragmentRendering(value),
                                  ),
                                ),
                                MorphRowItem(
                                  flashKey: 'disable_liquid_glass_menus',
                                  child: SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    secondary: Icon(
                                      Icons.list_alt_outlined,
                                      size: 26,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(
                                      l10n.displayDisableLiquidGlassMenus,
                                    ),
                                    value:
                                        settingsService.disableLiquidGlassMenus,
                                    onChanged: (value) => settingsService
                                        .setDisableLiquidGlassMenus(value),
                                  ),
                                ),
                                MorphRowItem(
                                  flashKey: 'menu_jelly',
                                  child: SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    secondary: Icon(
                                      Icons.animation_outlined,
                                      size: 26,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(l10n.displayMenuJelly),
                                    subtitle: Text(
                                      l10n.displayMenuJellyHint,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    value: settingsService.liquidGlassMenuJelly,
                                    onChanged: (value) => settingsService
                                        .setLiquidGlassMenuJelly(value),
                                  ),
                                ),
                                MorphRowItem(
                                  flashKey: 'bottom_bar_jelly',
                                  child: SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    secondary: Icon(
                                      Icons.water_drop_outlined,
                                      size: 26,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(
                                      l10n.displayBottomBarJelly,
                                    ),
                                    subtitle: Text(
                                      l10n.displayBottomBarJellyHint,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    value:
                                        settingsService.liquidGlassBottomBarJelly,
                                    onChanged: (value) => settingsService
                                        .setLiquidGlassBottomBarJelly(value),
                                  ),
                                ),
                                MorphRowItem(
                                  flashKey: 'video_card_glass',
                                  child: SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    secondary: Icon(
                                      Icons.smart_display,
                                      size: 26,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(l10n.displayVideoCardGlass),
                                    subtitle: Text(
                                      l10n.displayVideoCardGlassHint,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    value: settingsService.videoCardGlass,
                                    onChanged: (value) => settingsService
                                        .setVideoCardGlass(value),
                                  ),
                                ),
                                MorphRowItem(
                                  flashKey: 'chat_glass',
                                  child: SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    secondary: Icon(
                                      Icons.forum_outlined,
                                      size: 26,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(l10n.displayChatGlass),
                                    subtitle: Text(
                                      l10n.displayChatGlassHint,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    value: settingsService.chatGlass,
                                    onChanged: (value) =>
                                        settingsService.setChatGlass(value),
                                  ),
                                ),
                                MorphRowItem(
                                  flashKey: 'page_background',
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: Icon(
                                      Icons.wallpaper_outlined,
                                      size: 26,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(l10n.pageBgTitle),
                                    subtitle: Text(
                                      settingsService.pageBackgroundPath != null
                                          ? l10n.pageBgSubtitle
                                          : l10n.pageBgNotSet,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    onTap: () =>
                                        _navigateTo('/page-background'),
                                  ),
                                ),
                                MorphRowItem(
                                  flashKey: 'liquid_glass_tuner',
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: Icon(
                                      Icons.bubble_chart_outlined,
                                      size: 26,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(l10n.displayLiquidGlassTuner),
                                    subtitle: Text(
                                      l10n.displayLiquidGlassTunerSubtitle,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    onTap: () =>
                                        _navigateTo('/liquid-glass-tuner'),
                                  ),
                                ),
                              ]),
                                                             
                              _AnimatedCollapse(
                                visible: settingsService.iosPushTransition,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: kCardGap),
                                  child: MorphItem(
                                    selected: false,
                                    isFirst: false,
                                    isLast: true,
                                    flashKey: 'ios_push_transition_corner',
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 4,
                                              ),
                                          leading: Icon(
                                            Icons.rounded_corner_outlined,
                                            size: 26,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          title: Text(
                                            l10n.displayIosPushTransitionCorner,
                                          ),
                                          subtitle: settingsService
                                                      .iosPushTransitionCornerAuto &&
                                                  !DeviceCornerService
                                                      .hasDeviceValue
                                              ? Text(
                                                  l10n
                                                      .displayIosPushTransitionCornerUnsupported,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                )
                                              : null,
                                          trailing: Text(
                                            '${DeviceCornerService.resolveFor(settingsService).round()}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        Slider(
                                          value: settingsService
                                              .iosPushTransitionCornerRadius
                                              .clamp(0.0, 48.0),
                                          min: 0,
                                          max: 48,
                                          divisions: 48,
                                          label:
                                              '${settingsService.iosPushTransitionCornerRadius.round()}',
                                          activeColor: colorScheme.primary,
                                                            
                                                            
                                                           
                                                             
                                                        
                                          onChanged:
                                              settingsService
                                                      .iosPushTransitionCornerAuto &&
                                                  DeviceCornerService
                                                      .hasDeviceValue
                                              ? null
                                              : (v) => settingsService
                                                    .setIosPushTransitionCornerRadius(
                                                      v,
                                                    ),
                                        ),
                                        const Divider(height: 1),
                                        SwitchListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 4,
                                              ),
                                          secondary: Icon(
                                            Icons.phone_android_outlined,
                                            size: 26,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          title: Text(
                                            l10n
                                                .displayIosPushTransitionCornerAuto,
                                          ),
                                          value: settingsService
                                              .iosPushTransitionCornerAuto,
                                          onChanged: (value) => settingsService
                                              .setIosPushTransitionCornerAuto(
                                                value,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                                         
                                                                             
                                                    
                              if (Platform.isAndroid) ...[
                                _buildSectionTitle(
                                  context,
                                  l10n.displayModeSectionTitle,
                                ),
                                const SizedBox(height: 12),
                                MorphItem(
                                  selected: false,
                                  isFirst: true,
                                  isLast: true,
                                  flashKey: 'display_mode',
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: Icon(
                                      Icons.speed_outlined,
                                      size: 26,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(l10n.displayModeTitle),
                                    subtitle: Text(
                                      DisplayModeService.labelOf(
                                        settingsService.displayMode,
                                        autoText: l10n.displayModeAuto,
                                      ),
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    onTap: () => _navigateTo('/display-mode'),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: _buildOverlayBar(l10n),
            ),
          ],
        ),
      ),
    );
  }

                                   
                                                      
  Widget _buildOverlayBar(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    const dur = Duration(milliseconds: 260);
    const curve = Curves.easeInOut;
    final safeTop = MediaQuery.of(context).padding.top;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
                                    
            AnimatedOpacity(
              opacity: _barCollapsed ? 1 : 0,
              duration: dur,
              curve: curve,
              child: FrostedPanel(
                child: SizedBox(height: safeTop + kToolbarHeight),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: safeTop),
              child: SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    SizedBox(width: widget.isSplitView ? 12 : 8),
                    if (!widget.isSplitView)
                      MorphIconButton(
                        tooltip: l10n.commonBackTooltip,
                        icon: Icons.arrow_back,
                        onTap: _handleBack,
                      ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: AnimatedOpacity(
                        opacity: _barCollapsed ? 1 : 0,
                        duration: dur,
                        curve: curve,
                        child: Text(
                          l10n.displaySettingsTitle,
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
                  ],
                ),
              ),
            ),
          ],
        ),
                            
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: _barCollapsed ? 0.0 : 1.0),
          duration: dur,
          curve: curve,
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
            height: 64,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: Text(
                  l10n.displaySettingsTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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

  String _getSeedColorName(Color color) {
    final l10n = AppLocalizations.of(context);
    final presets = {
      0xFF386A20: l10n.displaySeedDefaultGreen,
      Colors.pink.toARGB32(): l10n.displaySeedPink,
      Colors.red.toARGB32(): l10n.displaySeedRed,
      Colors.orange.toARGB32(): l10n.displaySeedOrange,
      Colors.amber.toARGB32(): l10n.displaySeedAmber,
      Colors.yellow.toARGB32(): l10n.displaySeedYellow,
      Colors.lime.toARGB32(): l10n.displaySeedLime,
      Colors.lightGreen.toARGB32(): l10n.displaySeedLightGreen,
      Colors.green.toARGB32(): l10n.displaySeedGreen,
      Colors.cyan.toARGB32(): l10n.displaySeedCyan,
      Colors.teal.toARGB32(): l10n.displaySeedTeal,
      Colors.lightBlue.toARGB32(): l10n.displaySeedLightBlue,
      Colors.blue.toARGB32(): l10n.displaySeedBlue,
      Colors.indigo.toARGB32(): l10n.displaySeedIndigo,
      Colors.purple.toARGB32(): l10n.displaySeedPurple,
      Colors.deepPurple.toARGB32(): l10n.displaySeedDeepPurple,
      Colors.blueGrey.toARGB32(): l10n.displaySeedBlueGrey,
      Colors.brown.toARGB32(): l10n.displaySeedBrown,
      Colors.grey.toARGB32(): l10n.displaySeedGrey,
    };
    return presets[color.toARGB32()] ?? l10n.displaySeedCustom;
  }

  String _getFontWeightLabel(double weight) {
    final l10n = AppLocalizations.of(context);
    if (weight <= 100) return l10n.displayWeightThin(100);
    if (weight <= 300) return l10n.displayWeightLight(300);
    if (weight <= 400) return l10n.displayWeightRegular(400);
    if (weight <= 500) return l10n.displayWeightMedium(500);
    if (weight <= 700) return l10n.displayWeightBold(700);
    if (weight <= 900) return l10n.displayWeightBlack(900);
    return l10n.displayWeightCustom(weight.toInt());
  }

  FontWeight _toFontWeight(double v) {
    if (v <= 100) return FontWeight.w100;
    if (v <= 200) return FontWeight.w200;
    if (v <= 300) return FontWeight.w300;
    if (v <= 400) return FontWeight.w400;
    if (v <= 500) return FontWeight.w500;
    if (v <= 600) return FontWeight.w600;
    if (v <= 700) return FontWeight.w700;
    if (v <= 800) return FontWeight.w800;
    return FontWeight.w900;
  }

  String _getScaleDescription(double scale) {
    final l10n = AppLocalizations.of(context);
    if (scale < 0.75) return l10n.displayScaleCompact;
    if (scale < 1.0) return l10n.displayScaleSmall;
    if (scale == 1.0) return l10n.displayScaleDefault;
    if (scale <= 1.25) return l10n.displayScaleLarge;
    if (scale <= 1.5) return l10n.displayScaleLargeFont;
    return l10n.displayScaleHuge;
  }
}

class _AnimatedCollapse extends StatelessWidget {
  final bool visible;
  final Widget child;
  final double maxHeight;

  const _AnimatedCollapse({
    required this.visible,
    required this.child,
  }) : maxHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        constraints: BoxConstraints(maxHeight: visible ? maxHeight : 0.0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: visible ? 1.0 : 0.0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            offset: visible ? Offset.zero : const Offset(0, -0.2),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}

class FourColorPainter extends CustomPainter {
  final Color topLeft, topRight, bottomLeft, bottomRight;

  FourColorPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final paint = Paint();

    paint.color = topLeft;
    canvas.drawRect(Rect.fromLTWH(0, 0, w / 2, h / 2), paint);

    paint.color = topRight;
    canvas.drawRect(Rect.fromLTWH(w / 2, 0, w / 2, h / 2), paint);

    paint.color = bottomLeft;
    canvas.drawRect(Rect.fromLTWH(0, h / 2, w / 2, h / 2), paint);

    paint.color = bottomRight;
    canvas.drawRect(Rect.fromLTWH(w / 2, h / 2, w / 2, h / 2), paint);
  }

  @override
  bool shouldRepaint(covariant FourColorPainter oldDelegate) {
    return oldDelegate.topLeft != topLeft ||
        oldDelegate.topRight != topRight ||
        oldDelegate.bottomLeft != bottomLeft ||
        oldDelegate.bottomRight != bottomRight;
  }
}
