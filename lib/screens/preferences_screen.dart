                                      
  
                        
                                                     
                                   
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, FilteringTextInputFormatter, HapticFeedback;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/screens/bottom_nav_settings_screen.dart';
import 'package:provider/provider.dart';
import '../services/open_video_service.dart';
import '../services/app_link_service.dart';
import '../services/player_settings_service.dart';
import '../services/settings_service.dart';
import '../services/shortcut_editor_service.dart';
import '../widgets/widgets.dart';
import '../widgets/page_background.dart';
import '../l10n/app_localizations.dart';

class PreferencesScreen extends StatelessWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const PreferencesScreen({
    super.key,
    this.isSplitView = false,
    this.onBack,
  });

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsService>();
                                               
    final playerSettings = context.watch<PlayerSettingsService>();

    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
        body: Stack(
          children: [
            PageBackground(baseColor: colorScheme.surfaceContainer),
            CustomScrollView(
              physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                ExpressiveSliverAppBar(
                  title: l10n.settingsPreferences,
                  expandedHeight: 152,
                  leading: isSplitView
                      ? null
                      : MorphIconButton(
                          tooltip: l10n.netBackTooltip,
                          icon: Icons.arrow_back,
                          onTap: () => _handleBack(context),
                        ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                                       
                        _buildSectionTitle(context, l10n.prefBottomBarSection),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          MorphRowItem(
                            flashKey: 'use_m3_bottom_bar',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.dock_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.prefUseM3BottomBar),
                              value: settings.useM3BottomBar,
                              onChanged: settings.setUseM3BottomBar,
                            ),
                          ),
                          MorphRowItem(
                            flashKey: 'bottom_bar_search',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.search_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.prefBottomBarSearch),
                              value: settings.bottomBarSearch,
                              onChanged: settings.setBottomBarSearch,
                            ),
                          ),
                                                            
                          MorphRowItem(
                            flashKey: 'bottom_nav_items',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.reorder,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.bottomNavSettingsTitle),
                              subtitle: Text(
                                l10n.bottomNavSettingsSubtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: colorScheme.onSurfaceVariant,
                              ),
                                                     
                                                        
                                           
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const BottomNavSettingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                                                       
                                                         
                          if (ShortcutEditorService.isSupported)
                            MorphRowItem(
                              flashKey: 'app_shortcut_editor',
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: Icon(
                                  Icons.apps_outlined,
                                  size: 26,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: const Text('长按快捷菜单'),
                                subtitle: Text(
                                  '自定义桌面长按图标的快捷入口 · 改完即时生效',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onTap: () => ShortcutEditorService()
                                    .open(colorScheme),
                              ),
                            ),
                        ]),

                                        
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, l10n.prefSearchSection),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          MorphRowItem(
                            flashKey: 'search_trending_enabled',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.whatshot_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.prefSearchTrending),
                              subtitle: Text(
                                l10n.prefSearchTrendingSub,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.searchTrendingEnabled,
                              onChanged: settings.setSearchTrendingEnabled,
                            ),
                          ),
                          MorphRowItem(
                            flashKey: 'search_rcmd_enabled',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.lightbulb_outline,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.prefSearchDiscovery),
                              subtitle: Text(
                                l10n.prefSearchDiscoverySub,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.searchRcmdEnabled,
                              onChanged: settings.setSearchRcmdEnabled,
                            ),
                          ),
                        ]),

                                     
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, '评论'),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          MorphRowItem(
                            flashKey: 'enable_comm_antifraud',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.shield_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: const Text('发评反诈助手'),
                              subtitle: Text(
                                '发送评论后自动检查评论是否可见'
                                '（shadow ban / 精选是否被 UP 选入），'
                                '结果写入「我的评论」并弹窗提示',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.enableCommAntifraud,
                              onChanged: settings.setEnableCommAntifraud,
                            ),
                          ),
                        ]),

                                     
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, l10n.prefRefreshSection),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          MorphRowItem(
                            child: _buildSliderTile(
                              context,
                              icon: Icons.arrow_downward,
                              title: l10n.prefRefreshDisplacement,
                              value: settings.refreshDisplacement,
                              min: 40,
                              max: 200,
                              divisions: 8,                  
                              onChanged: settings.setRefreshDisplacement,
                            ),
                          ),
                          MorphRowItem(
                            child: _buildSliderTile(
                              context,
                              icon: Icons.vertical_align_top,
                              title: l10n.prefRefreshEdgeOffset,
                              value: settings.refreshEdgeOffset,
                              min: 0,
                              max: 120,
                              divisions: 12,                 
                              onChanged: settings.setRefreshEdgeOffset,
                            ),
                          ),
                        ]),

                                                               
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, '滑动动画'),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          MorphRowItem(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.chrome_reader_mode_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: const Text(
                                '滑动动画弹簧参数',
                                style: TextStyle(fontSize: 15),
                              ),
                              subtitle: Text(
                                'mass ${_fmtSpring(settings.springMass)} · '
                                    'stiffness ${_fmtSpring(settings.springStiffness)} · '
                                    'damping ${_fmtSpring(settings.springDamping)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onTap: () => _showSpringDialog(context),
                            ),
                          ),
                        ]),

                                        
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, 'Toast'),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          MorphRowItem(
                            flashKey: 'toast_use_fluttertoast',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.notifications_none,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: const Text('使用 fluttertoast'),
                              subtitle: Text(
                                '开启后纯提示改走应用内浮层（支持多条并行堆叠）；'
                                '关闭时 Android 使用系统原生 toast',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.toastUseFluttertoast,
                              onChanged: settings.setToastUseFluttertoast,
                            ),
                          ),
                                                               
                          if (settings.toastUseFluttertoast) ...[
                            MorphRowItem(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: Icon(
                                  Icons.format_color_fill_outlined,
                                  size: 26,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: const Text(
                                  '背景颜色',
                                  style: TextStyle(fontSize: 15),
                                ),
                                trailing: _ToastColorSwatch(
                                  color: settings.toastBgColor,
                                ),
                                onTap: () => _showToastBgColorDialog(context),
                              ),
                            ),
                            MorphRowItem(
                              child: _buildSliderTile(
                                context,
                                icon: Icons.opacity,
                                title: '背景不透明度',
                                value: settings.toastBgOpacity,
                                min: 0.1,
                                max: 1.0,
                                divisions: 9,                    
                                format:
                                    (v) => '${(v * 100).round()} %',
                                onChanged: settings.setToastBgOpacity,
                              ),
                            ),
                            MorphRowItem(
                              flashKey: 'toast_bg_blur',
                              child: SwitchListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                secondary: Icon(
                                  Icons.blur_on,
                                  size: 26,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: const Text('背景模糊'),
                                subtitle: Text(
                                  '浮层背景套毛玻璃（BackdropFilter）效果',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                value: settings.toastBgBlur,
                                onChanged: settings.setToastBgBlur,
                              ),
                            ),
                          ],
                        ]),

                                                  
                        if (Platform.isWindows ||
                            Platform.isMacOS ||
                            Platform.isLinux) ...[
                          const SizedBox(height: 32),
                          _buildSectionTitle(context, l10n.prefWindowSection),
                          const SizedBox(height: 12),
                          ...buildMorphSegmentedList([
                            MorphRowItem(
                              flashKey: 'default_window_size',
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: Icon(
                                  Icons.aspect_ratio_outlined,
                                  size: 26,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: Text(l10n.prefWindowSize),
                                subtitle: Text(
                                  '${settings.windowWidth.round()} × '
                                  '${settings.windowHeight.round()}',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onTap: () =>
                                    _showWindowSizeDialog(context, settings),
                              ),
                            ),
                          ]),
                        ],

                                                  
                                                    
                                                     
                        if (Platform.isWindows) ...[
                          const SizedBox(height: 32),
                          _buildSectionTitle(context, l10n.prefFileAssocSection),
                          const SizedBox(height: 12),
                          ...buildMorphSegmentedList([
                            MorphRowItem(
                              flashKey: 'file_assoc_default',
                              child: SwitchListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                secondary: Icon(
                                  Icons.play_circle_outline,
                                  size: 26,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: Text(l10n.prefFileAssocDefault),
                                subtitle: Text(
                                  l10n.prefFileAssocDefaultSub,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                value: settings.fileAssociationDefault,
                                onChanged: (value) async {
                                  await settings.setFileAssociationDefault(value);
                                  await OpenVideoService
                                      .registerFileAssociations(
                                    asDefault: value,
                                  );
                                },
                              ),
                            ),
                          ]),
                        ],

                                                
                                                    
                                                   
                                                
                                                         
                        if (Platform.isWindows) ...[
                          const SizedBox(height: 32),
                          _buildSectionTitle(context, l10n.prefPerfSection),
                          const SizedBox(height: 12),
                          ...buildMorphSegmentedList([
                            const MorphRowItem(
                              flashKey: 'efficiency_mode',
                              child: _EfficiencyModeTile(),
                            ),
                          ]),
                        ],

                                                                   
                                                                    
                                                          
                                                      
                        if (Platform.isAndroid) ...[
                          const SizedBox(height: 32),
                          _buildSectionTitle(context, l10n.prefLinkSection),
                          const SizedBox(height: 12),
                          ...buildMorphSegmentedList([
                            MorphRowItem(
                              flashKey: 'open_supported_links',
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: Icon(
                                  Icons.link_outlined,
                                  size: 26,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: Text(l10n.prefOpenSupportedLinks),
                                subtitle: Text(
                                  l10n.prefOpenSupportedLinksSub,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.open_in_new,
                                  size: 20,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  final ok = await AppLinkService
                                      .openLinkVerifySettings();
                                  if (!ok && context.mounted) {
                                    showAppToast(
                                      context,
                                      l10n.linkSettingsUnavailable,
                                    );
                                  }
                                },
                              ),
                            ),
                          ]),
                        ],

                                                               
                                                          
                                        
                        if (Platform.isAndroid) ...[
                          const SizedBox(height: 32),
                          _buildSectionTitle(context, '原生菜单'),
                          const SizedBox(height: 12),
                          ...buildMorphSegmentedList([
                            MorphRowItem(
                              flashKey: 'disable_native_menu',
                              child: SwitchListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                secondary: Icon(
                                  Icons.widgets_outlined,
                                  size: 26,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: const Text('不使用原生菜单'),
                                subtitle: const Text(
                                  '改用与其他平台一致的 Flutter 玻璃菜单',
                                  style: TextStyle(fontSize: 12),
                                ),
                                value: settings.disableNativeMenu,
                                onChanged: settings.setDisableNativeMenu,
                              ),
                            ),
                          ]),
                        ],

                                                           
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, '播放器记忆'),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                                                
                          MorphRowItem(
                            flashKey: 'player_default_rate',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.speed_rounded,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.playerDefaultRate),
                              trailing: MorphGlassDropdown<double>(
                                value: settings.playerDefaultRate,
                                items: [0.5, 1.0, 1.25, 1.5, 2.0, 3.0]
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text('${r}x'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    settings.setPlayerDefaultRate(val);
                                  }
                                },
                              ),
                            ),
                          ),
                                     
                          MorphRowItem(
                            flashKey: 'player_end_behavior',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.video_settings_rounded,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.playerDefaultEndBehavior),
                              trailing: MorphGlassDropdown<String>(
                                value: settings.playerEndBehavior,
                                items: [
                                  DropdownMenuItem(
                                    value: 'pause',
                                    child: Text(l10n.playerEndPause),
                                  ),
                                  DropdownMenuItem(
                                    value: 'loop',
                                    child: Text(l10n.playerEndLoop),
                                  ),
                                  DropdownMenuItem(
                                    value: 'exit',
                                    child: Text(l10n.playerEndExit),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    settings.setPlayerEndBehavior(val);
                                  }
                                },
                              ),
                            ),
                          ),
                                                     
                          if (Platform.isWindows ||
                              Platform.isMacOS ||
                              Platform.isLinux)
                            MorphRowItem(
                              flashKey: 'sleep_timer_exit_app',
                              child: SwitchListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                secondary: Icon(
                                  Icons.timer_outlined,
                                  size: 26,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: Text(l10n.settingsSleepTimerExitApp),
                                subtitle: Text(
                                  l10n.settingsSleepTimerExitAppDesc,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                value: settings.sleepTimerExitApp,
                                onChanged: settings.setSleepTimerExitApp,
                              ),
                            ),
                                        
                          MorphRowItem(
                            flashKey: 'load_danmaku_on_resume',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.subtitles_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.playerLoadDanmakuOnResume),
                              subtitle: Text(
                                l10n.playerLoadDanmakuOnResumeDesc,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: playerSettings.loadDanmakuOnResume,
                              onChanged:
                                  playerSettings.setLoadDanmakuOnResume,
                            ),
                          ),
                                                      
                          if (Platform.isAndroid)
                            MorphRowItem(
                              flashKey: 'auto_pip',
                              child: SwitchListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                secondary: Icon(
                                  Icons.picture_in_picture_alt_outlined,
                                  size: 26,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: Text(l10n.playerAutoPip),
                                value: settings.autoPiPOnBackground,
                                onChanged: settings.setAutoPiPOnBackground,
                              ),
                            ),
                                                            
                          MorphRowItem(
                            flashKey: 'player_stats',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.analytics_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.playerShowStats),
                              subtitle: Text(
                                l10n.playerShowStatsDesc,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.showPlayerStats,
                              onChanged: Platform.isWindows
                                  ? null
                                  : settings.setShowPlayerStats,
                            ),
                          ),
                        ]),

                                                     
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, '录制'),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                                                           
                          MorphRowItem(
                            flashKey: 'record_format',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.videocam_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: const Text('录制格式'),
                              subtitle: Text(
                                Platform.isAndroid || Platform.isIOS
                                    ? '动态照片：JPEG+MP4 合成，相册长按播放'
                                    : '动态照片在桌面端保存为 MP4 视频',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: MorphGlassDropdown<String>(
                                value: playerSettings.recordFormat,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'gif',
                                    child: Text('GIF 动图'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'livePhoto',
                                    child: Text('动态照片'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    playerSettings.setRecordFormat(val);
                                  }
                                },
                              ),
                            ),
                          ),
                                   
                          MorphRowItem(
                            flashKey: 'record_fps',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.slow_motion_video,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: const Text('GIF 帧率'),
                              subtitle: Text(
                                '仅 GIF 模式生效',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: MorphGlassDropdown<int>(
                                value: playerSettings.recordFps,
                                items: const [
                                  DropdownMenuItem(value: 8, child: Text('8 fps')),
                                  DropdownMenuItem(value: 10, child: Text('10 fps')),
                                  DropdownMenuItem(value: 12, child: Text('12 fps')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    playerSettings.setRecordFps(val);
                                  }
                                },
                              ),
                            ),
                          ),
                                   
                          MorphRowItem(
                            flashKey: 'record_width',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.photo_size_select_large,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: const Text('GIF 宽度'),
                              subtitle: Text(
                                '宽度越大文件越大，仅 GIF 模式生效',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: MorphGlassDropdown<int>(
                                value: playerSettings.recordWidth,
                                items: const [
                                  DropdownMenuItem(value: 320, child: Text('320 px')),
                                  DropdownMenuItem(value: 480, child: Text('480 px')),
                                  DropdownMenuItem(value: 640, child: Text('640 px')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    playerSettings.setRecordWidth(val);
                                  }
                                },
                              ),
                            ),
                          ),
                                         
                          MorphRowItem(
                            flashKey: 'record_max_seconds',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.timer_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: const Text('最长录制时长'),
                              subtitle: Text(
                                '达到上限自动停止并保存',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: MorphGlassDropdown<int>(
                                value: playerSettings.recordMaxSeconds,
                                items: const [
                                  DropdownMenuItem(value: 5, child: Text('5 秒')),
                                  DropdownMenuItem(value: 10, child: Text('10 秒')),
                                  DropdownMenuItem(value: 15, child: Text('15 秒')),
                                  DropdownMenuItem(value: 30, child: Text('30 秒')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    playerSettings.setRecordMaxSeconds(val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ],
        ),
      ),
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

                                           
                                                              
  Widget _buildSliderTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String Function(double value)? format,
  }) {
    final cs = Theme.of(context).colorScheme;
    final display = format != null ? format(value) : '${value.round()} dp';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 26, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(fontSize: 15)),
                    ),
                    Text(
                      display,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  label: display,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

                                                                      
                               
  
                                                           
                                                
                                      
                                                      
                                                                      

                                   
                                              
void _showWindowSizeDialog(BuildContext context, SettingsService settings) {
  showDialog<void>(
    context: context,
    builder: (_) => _WindowSizeDialog(settings: settings),
  );
}

                 
   
                                                 
                                             
                                          
class _EfficiencyModeTile extends StatelessWidget {
  const _EfficiencyModeTile();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsService>();
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Icon(
        Icons.eco_outlined,
        size: 26,
        color: cs.onSurfaceVariant,
      ),
      title: Text(l10n.prefEfficiencyMode),
      subtitle: Text(
        l10n.prefEfficiencyModeAutoDesc,
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
      isThreeLine: true,
      value: settings.efficiencyMode,
      onChanged: settings.setEfficiencyMode,
    );
  }
}

class _WindowSizeDialog extends StatefulWidget {
  final SettingsService settings;

  const _WindowSizeDialog({required this.settings});

  @override
  State<_WindowSizeDialog> createState() => _WindowSizeDialogState();
}

class _WindowSizeDialogState extends State<_WindowSizeDialog> {
                              
  static const double _minW = 720;
  static const double _minH = 480;

  late final TextEditingController _wCtrl;
  late final TextEditingController _hCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    final w = widget.settings.windowWidth.round();
    final h = widget.settings.windowHeight.round();
    _wCtrl = TextEditingController(text: '$w');
    _hCtrl = TextEditingController(text: '$h');
  }

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final w = double.tryParse(_wCtrl.text.trim());
    final h = double.tryParse(_hCtrl.text.trim());
    if (w == null ||
        h == null ||
        !w.isFinite ||
        !h.isFinite ||
        w < _minW ||
        h < _minH) {
      setState(() {
        _error = '窗口大小不能小于 ${_minW.round()} × ${_minH.round()}';
      });
      return;
    }
    await widget.settings.setWindowSize(w, h);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inputStyle = TextStyle(color: cs.onSurface);
    final labelStyle = TextStyle(color: cs.onSurfaceVariant, fontSize: 12);
    return AlertDialog(
      backgroundColor: cs.surfaceContainerHigh,
      title: const Text('默认窗口大小'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '设置启动应用时的窗口大小，并常态保存',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _wCtrl,
                  style: inputStyle,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: '宽度',
                    labelStyle: labelStyle,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('×'),
              ),
              Expanded(
                child: TextField(
                  controller: _hCtrl,
                  style: inputStyle,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: '高度',
                    labelStyle: labelStyle,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '最小 ${_minW.round()} × ${_minH.round()}',
            style: TextStyle(fontSize: 11, color: cs.outline),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(fontSize: 12, color: cs.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _apply,
          child: const Text('应用'),
        ),
      ],
    );
  }
}

                            
String _fmtSpring(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

void _showSpringDialog(BuildContext context) {
  final settings = context.read<SettingsService>();
  showDialog<void>(
    context: context,
    builder: (_) => _SpringParamsDialog(settings: settings),
  );
}

class _SpringParamsDialog extends StatefulWidget {
  final SettingsService settings;

  const _SpringParamsDialog({required this.settings});

  @override
  State<_SpringParamsDialog> createState() => _SpringParamsDialogState();
}

class _SpringParamsDialogState extends State<_SpringParamsDialog> {
                                        
                                                  
                                     
  late final List<String> _springDescription;

                                                                        
  bool _physicalMode = true;

  @override
  void initState() {
    super.initState();
    _springDescription = [
      widget.settings.springMass.toString(),
      widget.settings.springStiffness.toString(),
      widget.settings.springDamping.toString(),
    ];
  }

  void _physical2Duration() {
    final mass = double.parse(_springDescription[0]);
    final stiffness = double.parse(_springDescription[1]);
    final damping = double.parse(_springDescription[2]);

    final duration = math.sqrt(4 * math.pi * math.pi * mass / stiffness);
    final dampingRatio = damping / (2.0 * math.sqrt(mass * stiffness));
    final bounce = dampingRatio < 1.0
        ? 1.0 - dampingRatio
        : 1.0 / dampingRatio - 1;

    _springDescription[0] = duration.toString();
    _springDescription[1] = bounce.toString();
  }

                                                                              
  void _duration2Physical() {
    final duration = double.parse(_springDescription[0]);
    final bounce = double.parse(_springDescription[1]).clamp(-1.0, 1.0);

    final stiffness = 4 * math.pi * math.pi / math.pow(duration, 2);
    final dampingRatio = bounce > 0 ? 1.0 - bounce : 1.0 / (bounce + 1);
    final damping = 2 * math.sqrt(stiffness) * dampingRatio;

    _springDescription[0] = '1';
    _springDescription[1] = stiffness.toString();
    _springDescription[2] = damping.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('弹簧参数'),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              try {
                if (_physicalMode) {
                  _physical2Duration();
                } else {
                  _duration2Physical();
                }
                _physicalMode = !_physicalMode;
                setState(() {});
              } catch (e) {
                showAppToast(context, e.toString(), error: true);
              }
            },
            child: Text(_physicalMode ? '滑动时间' : '物理参数'),
          ),
        ],
      ),
      content: Column(
        key: ValueKey<bool>(_physicalMode),
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          _physicalMode ? 3 : 2,
          (index) => TextFormField(
            autofocus: index == 0,
            initialValue: _springDescription[index],
            keyboardType: TextInputType.numberWithOptions(
              signed: !_physicalMode && index == 1,
              decimal: true,
            ),
            onChanged: (value) => _springDescription[index] = value,
            inputFormatters: [
              !_physicalMode && index == 1
                  ? FilteringTextInputFormatter.allow(RegExp(r'[-\d\.]+'))
                  : FilteringTextInputFormatter.allow(RegExp(r'[\d\.]+')),
            ],
            decoration: InputDecoration(
              labelText: (_physicalMode
                  ? const ['mass', 'stiffness', 'damping']
                  : const ['duration', 'bounce'])[index],
              suffixText: !_physicalMode && index == 0 ? 's' : null,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            showAppToast(context, '重置成功，立即生效');
            Navigator.pop(context);
            widget.settings.resetSpringDescription();
          },
          child: const Text('重置'),
        ),
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(
            '取消',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        TextButton(
          onPressed: () {
            try {
              if (!_physicalMode) {
                _duration2Physical();
              }
              final res = _springDescription.map(double.parse).toList();
              widget.settings.setSpringDescription(
                mass: res[0],
                stiffness: res[1],
                damping: res[2],
              );
              showAppToast(context, '设置成功');
              Navigator.pop(context);
            } catch (e) {
              showAppToast(context, e.toString(), error: true);
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

                                                                      
                                   
  
                                                 
                                                      
                                      
                                       
                                                                      

                            
class _ToastColorSwatch extends StatelessWidget {
  final Color color;

  const _ToastColorSwatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

void _showToastBgColorDialog(BuildContext context) {
  final settings = context.read<SettingsService>();
  Color tempColor = settings.toastBgColor;
  final hexController = TextEditingController(
    text:
        '#${(tempColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
  );

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void updateColorFromText(String input) {
            try {
              Color newColor;
              if (input.startsWith('#')) {
                newColor = Color(
                  int.parse(input.substring(1), radix: 16) + 0xFF000000,
                );
              } else if (input.contains(',')) {
                final parts = input
                    .split(',')
                    .map((s) => int.parse(s.trim()))
                    .toList();
                newColor = Color.fromRGBO(parts[0], parts[1], parts[2], 1);
              } else {
                newColor = Color(int.parse(input, radix: 16) + 0xFF000000);
              }
              setDialogState(() => tempColor = newColor);
            } catch (_) {}
          }

          return AlertDialog(
            title: const Text('Toast 背景颜色'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorPicker(
                    pickerColor: tempColor,
                    onColorChanged: (color) {
                      final newHex =
                          '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                      setDialogState(() {
                        tempColor = color;
                        if (hexController.text != newHex) {
                          hexController.text = newHex;
                          hexController.selection = TextSelection.fromPosition(
                            TextPosition(offset: newHex.length),
                          );
                        }
                      });
                    },
                    pickerAreaHeightPercent: 0.4,
                    portraitOnly: true,
                                         
                    enableAlpha: false,
                    displayThumbColor: true,
                    labelTypes: const [
                      ColorLabelType.rgb,
                      ColorLabelType.hex,
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: hexController,
                    decoration: InputDecoration(
                      labelText: '十六进制颜色',
                      hintText: '#323232',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_paste),
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            hexController.text = data!.text!;
                            hexController.selection = TextSelection.fromPosition(
                              TextPosition(offset: data.text!.length),
                            );
                            updateColorFromText(data.text!);
                          }
                        },
                      ),
                    ),
                    onChanged: updateColorFromText,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  settings.setToastBgColor(tempColor);
                  Navigator.pop(dialogContext);
                  showAppToast(dialogContext, 'Toast 背景颜色已更新');
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    },
  );
}
