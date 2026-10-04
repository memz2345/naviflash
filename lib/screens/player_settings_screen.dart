                                          
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/services/player_settings_service.dart';
import 'package:naviflash/services/player_audio_service.dart';
import 'package:naviflash/services/bilibili_video_service.dart'
    show kBiliQualityPresets, kBiliAudioQualityNames;
import 'package:naviflash/services/favorites_service.dart';
import 'package:naviflash/widgets/widgets.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/screens/watch_history_page.dart';
import 'package:naviflash/screens/favorites_page.dart';
import 'package:naviflash/screens/log_viewer_page.dart';
import 'package:naviflash/screens/hardware_decoding_screen.dart';
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

                                      
  Future<void> _showAudioDeviceHint() async {
    final settings = context.read<PlayerSettingsService>();
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final cleared = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isZh ? '音频输出设备' : 'Audio output device'),
        content: Text(
          isZh
              ? '设备列表由播放器原生枚举：打开任意视频后，点右上角「更多 → 音频输出设备」即可切换。\n\n已保存的选择会在每次打开播放器时自动应用。'
              : 'The device list is provided by the player. Open any video and use "More → Audio output device".\n\nYour saved choice is applied automatically whenever the player opens.',
        ),
        actions: [
          if (settings.audioOutputDevice.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(isZh ? '恢复自动' : 'Reset to auto'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isZh ? '知道了' : 'OK'),
          ),
        ],
      ),
    );
    if (cleared == true) {
      await settings.setAudioOutputDevice('');
    }
  }



  void _openWatchHistory() {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WatchHistoryPage()));
  }

  void _openLogViewer() {
               
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

                 

                                     
                                      
  String _hwdecLabel(String mode, AppLocalizations l10n) {
    if (mode.trim().isEmpty) return l10n.psHwdecAuto;
    final parts = mode.split(',').map((p) => p.trim()).toList();
    if (parts.length == 1) {
      return switch (parts.single) {
        'auto' => l10n.psHwdecAuto,
        'no' => l10n.psHwdecSoftware,
        _ => parts.single,
      };
    }
    return parts.join(', ');
  }

  void _openHardwareDecoding() {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HardwareDecodingScreen()));
  }

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

                                       
  String _qnLabel(int qn) {
    if (qn <= 0) return '跟随B站（最高可用）';
    for (final q in kBiliQualityPresets) {
      if (q.qn == qn) return q.label;
    }
    return '$qn';
  }

  List<DropdownMenuItem<String>> _qnDropdownItems(bool isZh) => [
    DropdownMenuItem(
      value: '0',
      child: Text(isZh ? '跟随B站（最高可用）' : 'Follow Bilibili (best)'),
    ),
    for (final q in kBiliQualityPresets)
      DropdownMenuItem(value: q.qn.toString(), child: Text(q.label)),
  ];

                                        
  String _audioQualityLabel(int id) {
    if (id <= 0) return '自动（最高码率）';
    return kBiliAudioQualityNames[id] ?? '音轨 $id';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<PlayerSettingsService>();
    final favorites = context.watch<FavoritesService>();
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

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
            CustomScrollView(
              physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),                                                  
              slivers: [
                ExpressiveSliverAppBar(
                  title: l10n.psTitle,
                  expandedHeight: 152,
                  leading: widget.isSplitView
                      ? null
                      : MorphIconButton(
                          tooltip: l10n.psBackTooltip,
                          icon: Icons.arrow_back,
                          onTap: _handleBack,
                        ),

                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                                                           
                                                          
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                                     
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

                                                            
                        if (Platform.isWindows ||
                            Platform.isMacOS ||
                            Platform.isLinux) ...[
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
                                l10n.psKeepWindowRatioDesc,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.keepWindowAspectRatio,
                              onChanged: settings.setKeepWindowAspectRatio,
                            ),
                          ),
                        ],

                                     
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
                                                                       
                          if (Platform.isAndroid ||
                              Platform.isIOS ||
                              Platform.isMacOS)
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

                                                      
                        const SizedBox(height: 32),
                        _buildSectionTitle(
                          context,
                          isZh ? '默认画质 / 音质' : 'Default quality',
                        ),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                                       
                          MorphRowItem(
                            flashKey: 'default_qn_wifi',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.wifi_rounded,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(
                                isZh ? '默认画质（WiFi）' : 'Default quality (WiFi)',
                              ),
                              subtitle: Text(
                                _qnLabel(settings.defaultQnWifi),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: MorphGlassDropdown<String>(
                                value: settings.defaultQnWifi.toString(),
                                items: _qnDropdownItems(isZh),
                                onChanged: (val) {
                                  if (val != null) {
                                    settings.setDefaultQnWifi(
                                      int.tryParse(val) ?? 0,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                                       
                          MorphRowItem(
                            flashKey: 'default_qn_cellular',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.signal_cellular_alt_rounded,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(
                                isZh
                                    ? '默认画质（移动网络）'
                                    : 'Default quality (cellular)',
                              ),
                              subtitle: Text(
                                _qnLabel(settings.defaultQnCellular),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: MorphGlassDropdown<String>(
                                value: settings.defaultQnCellular.toString(),
                                items: _qnDropdownItems(isZh),
                                onChanged: (val) {
                                  if (val != null) {
                                    settings.setDefaultQnCellular(
                                      int.tryParse(val) ?? 0,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                                 
                          MorphRowItem(
                            flashKey: 'default_audio_quality',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.music_note_rounded,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(
                                isZh ? '默认音质' : 'Default audio quality',
                              ),
                              subtitle: Text(
                                _audioQualityLabel(
                                  settings.defaultAudioQualityId,
                                ),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: MorphGlassDropdown<String>(
                                value: settings.defaultAudioQualityId
                                    .toString(),
                                items: [
                                  DropdownMenuItem(
                                    value: '0',
                                    child: Text(
                                      isZh ? '自动（最高码率）' : 'Auto (best)',
                                    ),
                                  ),
                                  for (final entry
                                      in kBiliAudioQualityNames.entries)
                                    DropdownMenuItem(
                                      value: entry.key.toString(),
                                      child: Text(entry.value),
                                    ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    settings.setDefaultAudioQualityId(
                                      int.tryParse(val) ?? 0,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ]),

                                       
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
                                                               
                          MorphRowItem(
                            flashKey: 'pgc_skip_mode',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.movie_filter_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(isZh ? '番剧片头/片尾' : 'Anime OP/ED'),
                              subtitle: Text(
                                switch (settings.pgcSkipMode) {
                                  'auto' => isZh ? '自动跳过' : 'Skip automatically',
                                  'off' => isZh ? '不处理' : 'Disabled',
                                  _ => isZh ? '弹出跳过按钮' : 'Show skip button',
                                },
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: MorphGlassDropdown<String>(
                                value: settings.pgcSkipMode,
                                items: [
                                  DropdownMenuItem(
                                    value: 'button',
                                    child: Text(isZh ? '弹按钮' : 'Button'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'auto',
                                    child: Text(isZh ? '自动跳过' : 'Auto'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'off',
                                    child: Text(isZh ? '关闭' : 'Off'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) settings.setPgcSkipMode(val);
                                },
                              ),
                            ),
                          ),
                                       
                          MorphRowItem(
                            flashKey: 'show_seek_preview',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.preview_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(
                                isZh ? '滑动进度预览' : 'Seek preview',
                              ),
                              subtitle: Text(
                                isZh
                                    ? '拖动进度条时显示该时间点的视频缩略图'
                                    : 'Show a thumbnail preview when dragging the progress bar',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: settings.showSeekPreview,
                              onChanged: settings.setShowSeekPreview,
                            ),
                          ),
                        ]),

                                     
                        const SizedBox(height: 32),
                        _buildSectionTitle(
                          context,
                          isZh ? '音频' : 'Audio',
                        ),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                                                        
                          MorphRowItem(
                            flashKey: 'audio_normalization',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.graphic_eq,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(isZh ? '音量均衡' : 'Volume leveling'),
                              subtitle: Text(
                                PlayerAudioService.label(
                                  settings.audioNormalization,
                                ),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: MorphGlassDropdown<String>(
                                value: settings.audioNormalization,
                                items: [
                                  DropdownMenuItem(
                                    value: PlayerAudioService.modeDisable,
                                    child: Text(isZh ? '关闭' : 'Off'),
                                  ),
                                  DropdownMenuItem(
                                    value: PlayerAudioService.modeDynaudnorm,
                                    child: const Text('dynaudnorm'),
                                  ),
                                  DropdownMenuItem(
                                    value: PlayerAudioService.modeLoudnorm,
                                    child: const Text('loudnorm'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    settings.setAudioNormalization(val);
                                  }
                                },
                              ),
                            ),
                          ),
                                                 
                          MorphRowItem(
                            flashKey: 'audio_output_device',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.speaker_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(
                                isZh ? '音频输出设备' : 'Audio output device',
                              ),
                              subtitle: Text(
                                settings.audioOutputDevice.isEmpty
                                    ? (isZh ? '当前：自动' : 'Auto')
                                    : settings.audioOutputDevice,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.white38,
                              ),
                              onTap: _showAudioDeviceHint,
                            ),
                          ),
                        ]),

                                     
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, l10n.psMiscSection),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                                                    
                                            
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
                                '${_hwdecLabel(settings.hwdecMode, l10n)}'
                                '${settings.hwdecEnabled ? '' : '  ·  ${l10n.psHwdecDisabledTag}'}',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.white38,
                              ),
                              onTap: _openHardwareDecoding,
                            ),
                          ),
                                 
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

                                     
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, l10n.psLogSection),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                                          
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
