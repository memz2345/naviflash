// lib/screens/player_settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/services/player_settings_service.dart';
import 'package:naviflash/services/play_history_service.dart';
import 'package:naviflash/services/favorites_service.dart';
import 'package:naviflash/widgets/widgets.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/screens/player_test_page.dart';
import 'package:naviflash/screens/play_history_page.dart';
import 'package:naviflash/screens/watch_history_page.dart';
import 'package:naviflash/screens/favorites_page.dart';
import 'package:naviflash/screens/log_viewer_page.dart';
import 'package:naviflash/l10n/app_localizations.dart';

class PlayerSettingsScreen extends StatefulWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const PlayerSettingsScreen({
    super.key,
    this.isSplitView = false,
    this.onBack,
  });

  @override
  State<PlayerSettingsScreen> createState() => _PlayerSettingsScreenState();
}

class _PlayerSettingsScreenState extends State<PlayerSettingsScreen> {
  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _openPlayerTest() {
//  跳转时触发清脆震动反馈
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PlayerTestPage()));
  }

  void _openPlayHistory() {
//  跳转时触发清脆震动反馈
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PlayHistoryPage()));
  }

  void _openWatchHistory() {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WatchHistoryPage()));
  }

  void _openLogViewer() {
//  跳转时触发清脆震动反馈
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LogViewerPage()));
  }

  String _mpvLogLevelLabel(String level, AppLocalizations l10n) =>
      switch (level) {
        'error' => l10n.psMpvLogError,
        'warn' => l10n.psMpvLogWarnDefault,
        'info' => l10n.psMpvLogInfo,
        'v' => l10n.psMpvLogVerbose,
        'debug' => l10n.psMpvLogDebug,
        'trace' => l10n.psMpvLogTrace,
        _ => level,
      };

  // ─── 辅助标签 ───

  String _hwdecLabel(String mode, AppLocalizations l10n) => switch (mode) {
    'auto' => l10n.psHwdecAuto,
    'no' => l10n.psHwdecSoftware,
    'vaapi' => 'VA-API（Linux / Android）',
    'nvdec' => 'NVIDIA NVDEC',
    'videotoolbox' => 'Apple VideoToolbox',
    'mediacodec' => 'Android MediaCodec',
    'd3d11va' => 'Windows D3D11VA',
    _ => mode,
  };

  String _videoSyncLabel(String sync, AppLocalizations l10n) => switch (sync) {
    'audio' => l10n.psVsyncAudioDefault,
    'display-resample' => l10n.psVsyncResample,
    'display-adrop' => l10n.psVsyncAdrop,
    'display-vdrop' => l10n.psVsyncVdrop,
    _ => sync,
  };

  String _superResolutionLabel(String mode, AppLocalizations l10n) =>
      switch (mode) {
        'efficiency' => l10n.superResolutionEfficiency,
        'quality' => l10n.superResolutionQuality,
        _ => l10n.superResolutionOff,
      };

  String _decodeFormatLabel(String mode, AppLocalizations l10n) =>
      switch (mode) {
        'avc' => l10n.playerDecodeAvc,
        'hevc' => l10n.playerDecodeHevc,
        'av1' => l10n.playerDecodeAv1,
        _ => l10n.playerDecodeAuto,
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<PlayerSettingsService>();
    final history = context.watch<PlayHistoryService>();
    final favorites = context.watch<FavoritesService>();
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: widget.onBack == null,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
        body: Stack(
          children: [
            PageBackground(baseColor: colorScheme.surfaceContainer),
            CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                ExpressiveSliverAppBar(
                  title: l10n.psTitle,
                  expandedHeight: 120,
                  leading: widget.isSplitView
                      ? null
                      : MorphIconButton(
                          tooltip: l10n.psBackTooltip,
                          icon: Icons.arrow_back,
                          onTap: _handleBack,
                        ),
                  actions: [
                    MorphIconButton(
                      icon: Icons.rocket_launch,
                      tooltip: l10n.psStaffEntrance,
                      onTap: _openPlayerTest,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  // 用 SliverToBoxAdapter(Column) 全量构建所有选项，
                  // 保证折叠区外的选项也存在，搜索跳转才能 ensureVisible 定位。
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ─── 显示 ───
                        _buildSectionTitle(context, l10n.psDisplaySection),
                        const SizedBox(height: 12),
                        MorphItem(
                          selected: false,
                          isFirst: true,
                          isLast: true,
                          flashKey: 'status_bar',
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            secondary: Icon(
                              Icons.phone_android,
                              size: 26,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            title: Text(l10n.psStatusBar),
                            subtitle: Text(
                              l10n.psStatusBarDesc,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            value: settings.showFakeStatusBar,
                            onChanged: settings.setShowFakeStatusBar,
                          ),
                        ),

                        // ─── 窗口（等比例拉伸）───
                        const SizedBox(height: 12),
                        MorphItem(
                          selected: false,
                          isFirst: true,
                          isLast: true,
                          flashKey: 'keep_window_ratio',
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            secondary: Icon(
                              Icons.aspect_ratio,
                              size: 26,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            title: Text(l10n.psKeepWindowRatio),
                            subtitle: Text(
//  不支持平台也显示，但不会生效
                              Platform.isWindows ||
                                      Platform.isMacOS ||
                                      Platform.isLinux
                                  ? l10n.psKeepWindowRatioDesc
                                  : l10n.psKeepWindowRatioDesktopOnly,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            value: settings.keepWindowAspectRatio,
                            onChanged: settings.setKeepWindowAspectRatio,
                          ),
                        ),

                        // ─── 交互 ───
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, l10n.psInteractionSection),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          MorphRowItem(
                            flashKey: 'long_press_speed',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.touch_app,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.psLongPressSpeed),
                              subtitle: Text(
                                l10n.psLongPressSpeedDesc,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.enableLongPressSpeed,
                              onChanged: settings.setEnableLongPressSpeed,
                            ),
                          ),
                          MorphRowItem(
                            flashKey: 'screenshot',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.camera_alt,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.psScreenshot),
                              subtitle: Text(
                                l10n.psScreenshotDesc,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.enableScreenshot,
                              onChanged: settings.setEnableScreenshot,
                            ),
                          ),
                          MorphRowItem(
                            flashKey: 'screenshot_danmaku',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.subtitles,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.psScreenshotDanmaku),
                              subtitle: Text(
                                l10n.psScreenshotDanmakuDesc,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.showDanmakuInScreenshot,
                              onChanged: settings.setShowDanmakuInScreenshot,
                            ),
                          ),
                        ]),

                        // ─── 进度 ───
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, l10n.psProgressSection),
                        const SizedBox(height: 12),
                        MorphItem(
                          selected: false,
                          isFirst: true,
                          isLast: true,
                          flashKey: 'play_history',
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Icon(
                              Icons.history_rounded,
                              size: 26,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            title: Text(l10n.psPlayProgress),
                            subtitle: Text(
                              history.records.isEmpty
                                  ? l10n.psNoHistory
                                  : l10n.psHistoryCount(history.records.length),
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onTap: _openPlayHistory,
                          ),
                        ),

                        // ─── 观看历史 ───
                        const SizedBox(height: kCardGap),
                        MorphItem(
                          selected: false,
                          isFirst: true,
                          isLast: true,
                          flashKey: 'watch_history',
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Icon(
                              Icons.history_edu_rounded,
                              size: 26,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            title: const Text('观看历史'),
                            subtitle: Text(
                              '浏览足迹（含无痕模式与云同步）',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onTap: _openWatchHistory,
                          ),
                        ),

                        // ─── 本地收藏 ───
                        const SizedBox(height: kCardGap),
                        MorphItem(
                          selected: false,
                          isFirst: true,
                          isLast: true,
                          flashKey: 'local_favorites',
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Icon(
                              Icons.favorite_border_rounded,
                              size: 26,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            title: Text('本地收藏'),
                            subtitle: Text(
                              favorites.items.isEmpty
                                  ? '暂无收藏'
                                  : '共 ${favorites.items.length} 条收藏',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const FavoritesPage(),
                                ),
                              );
                            },
                          ),
                        ),

                        // ─── 画面增强 ───
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, l10n.playerSectionEnhance),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          MorphRowItem(
                            flashKey: 'super_resolution',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.auto_awesome_motion,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.superResolutionTitle),
                              subtitle: Text(
                                '${_superResolutionLabel(settings.superResolutionMode, l10n)}\n${l10n.superResolutionHint}',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: MorphGlassDropdown<String>(
                                value: settings.superResolutionMode,
                                items: [
                                  DropdownMenuItem(
                                    value: 'disable',
                                    child: Text(l10n.superResolutionOff),
                                  ),
                                  DropdownMenuItem(
                                    value: 'efficiency',
                                    child: Text(l10n.superResolutionEfficiency),
                                  ),
                                  DropdownMenuItem(
                                    value: 'quality',
                                    child: Text(l10n.superResolutionQuality),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    settings.setSuperResolutionMode(val);
                                  }
                                },
                              ),
                            ),
                          ),
                          // 跳过片头/片尾
                          MorphRowItem(
                            flashKey: 'skip_intro_outro',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.skip_next_rounded,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.skipIntroOutroTitle),
                              subtitle: Text(
                                l10n.skipIntroOutroHint,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.skipIntroOutro,
                              onChanged: settings.setSkipIntroOutro,
                            ),
                          ),
                        ]),

                        // ─── 杂项 ───
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, l10n.psMiscSection),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          // 硬件解码
                          MorphRowItem(
                            flashKey: 'hwdec',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.memory_rounded,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.psHwdec),
                              subtitle: Text(
                                _hwdecLabel(settings.hwdecMode, l10n),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: MorphGlassDropdown<String>(
                                value: settings.hwdecMode,
                                items: [
                                  DropdownMenuItem(
                                    value: 'auto',
                                    child: Text(l10n.psHwdecAutoShort),
                                  ),
                                  DropdownMenuItem(
                                    value: 'no',
                                    child: Text(l10n.psHwdecPureSoftware),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'vaapi',
                                    child: Text('VA-API'),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'nvdec',
                                    child: Text('NVDEC'),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'videotoolbox',
                                    child: Text('VideoToolbox'),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'mediacodec',
                                    child: Text('MediaCodec'),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'd3d11va',
                                    child: Text('D3D11VA'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) settings.setHwdecMode(val);
                                },
                              ),
                            ),
                          ),
                          // 视频同步
                          MorphRowItem(
                            flashKey: 'video_sync',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.sync_rounded,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.psVideoSync),
                              subtitle: Text(
                                _videoSyncLabel(settings.videoSync, l10n),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: MorphGlassDropdown<String>(
                                value: settings.videoSync,
                                items: [
                                  DropdownMenuItem(
                                    value: 'audio',
                                    child: Text(l10n.psVsyncAudio),
                                  ),
                                  DropdownMenuItem(
                                    value: 'display-resample',
                                    child: Text(l10n.psVsyncDisplayResample),
                                  ),
                                  DropdownMenuItem(
                                    value: 'display-adrop',
                                    child: Text(l10n.psVsyncDisplayAdrop),
                                  ),
                                  DropdownMenuItem(
                                    value: 'display-vdrop',
                                    child: Text(l10n.psVsyncDisplayVdrop),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) settings.setVideoSync(val);
                                },
                              ),
                            ),
                          ),
                          MorphRowItem(
                            flashKey: 'decode_format',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.video_settings_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.playerDecodeFormat),
                              subtitle: Text(
                                _decodeFormatLabel(
                                  settings.preferredDecodeFormat,
                                  l10n,
                                ),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: MorphGlassDropdown<String>(
                                value: settings.preferredDecodeFormat,
                                items: [
                                  DropdownMenuItem(
                                    value: 'auto',
                                    child: Text(l10n.playerDecodeAuto),
                                  ),
                                  DropdownMenuItem(
                                    value: 'avc',
                                    child: Text(l10n.playerDecodeAvc),
                                  ),
                                  DropdownMenuItem(
                                    value: 'hevc',
                                    child: Text(l10n.playerDecodeHevc),
                                  ),
                                  DropdownMenuItem(
                                    value: 'av1',
                                    child: Text(l10n.playerDecodeAv1),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    settings.setPreferredDecodeFormat(val);
                                  }
                                },
                              ),
                            ),
                          ),
                          // 沉浸模式长按加速
                          MorphRowItem(
                            flashKey: 'immersive_long_press',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.visibility_off_rounded,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.psImmersiveLongPress),
                              subtitle: Text(
                                l10n.psImmersiveLongPressDesc,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.longPressInImmersive,
                              onChanged: settings.setLongPressInImmersive,
                            ),
                          ),
                        ]),

                        // ─── 日志 ───
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, l10n.psLogSection),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          // 记录 mpv 日志（可选）
                          MorphRowItem(
                            flashKey: 'mpv_log',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.receipt_long_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.psMpvLog),
                              subtitle: Text(
                                settings.enableMpvLog
                                    ? l10n.psMpvLogEnabled(
                                        _mpvLogLevelLabel(
                                          settings.mpvLogLevel,
                                          l10n,
                                        ),
                                      )
                                    : l10n.psMpvLogDisabled,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.enableMpvLog,
                              onChanged: settings.setEnableMpvLog,
                            ),
                          ),
                          // mpv 日志细度
                          if (settings.enableMpvLog)
                            MorphRowItem(
                              flashKey: 'mpv_log_level',
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: Icon(
                                  Icons.tune_rounded,
                                  size: 26,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: Text(l10n.psMpvLogLevel),
                                subtitle: Text(
                                  l10n.psMpvLogLevelDesc,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: MorphGlassDropdown<String>(
                                  value: settings.mpvLogLevel,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'error',
                                      child: Text(l10n.psMpvLogError),
                                    ),
                                    DropdownMenuItem(
                                      value: 'warn',
                                      child: Text(l10n.psMpvLogWarn),
                                    ),
                                    DropdownMenuItem(
                                      value: 'info',
                                      child: Text(l10n.psMpvLogInfo),
                                    ),
                                    DropdownMenuItem(
                                      value: 'v',
                                      child: Text(l10n.psMpvLogVerbose),
                                    ),
                                    DropdownMenuItem(
                                      value: 'debug',
                                      child: Text(l10n.psMpvLogDebug),
                                    ),
                                    DropdownMenuItem(
                                      value: 'trace',
                                      child: Text(l10n.psMpvLogTrace),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      settings.setMpvLogLevel(val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          // 查看日志
                          MorphRowItem(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.article_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.psViewLogs),
                              subtitle: Text(
                                l10n.psViewLogsDesc,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onTap: _openLogViewer,
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
}
