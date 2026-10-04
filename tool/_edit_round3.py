# -*- coding: utf-8 -*-
"""第三轮：视频页「更多」菜单扩充 + MoreMenuAction 支持副标题。"""
import io


def edit(path, pairs):
    s = io.open(path, encoding='utf-8').read()
    for old, new in pairs:
        assert s.count(old) >= 1, (path, old[:90])
        s = s.replace(old, new, 1)
    io.open(path, 'w', encoding='utf-8', newline='').write(s)
    print('ok', path)


# ── 1. 菜单项支持副标题（显示当前状态，PiliPlus 同款）──
edit(
    'lib/widgets/more_menu_sheet.dart',
    [
        (
            "  const MoreMenuAction({\n"
            "    required this.icon,\n"
            "    required this.label,\n"
            "    required this.onTap,\n"
            "    this.trailing,\n",
            "  const MoreMenuAction({\n"
            "    required this.icon,\n"
            "    required this.label,\n"
            "    required this.onTap,\n"
            "    this.trailing,\n"
            "    /// 副标题：显示当前状态（如「当前：1080P」）。\n"
            "    this.subtitle,\n",
        ),
        (
            "  final Widget? trailing;\n"
            "  final bool closeAfter;\n"
            "}",
            "  final Widget? trailing;\n"
            "  final String? subtitle;\n"
            "  final bool closeAfter;\n"
            "}",
        ),
        (
            "  const MoreMenuItem({\n"
            "    super.key,\n"
            "    required this.icon,\n"
            "    required this.label,\n"
            "    this.trailing,\n"
            "    this.onTap,\n"
            "    this.dense = true,\n"
            "  });\n",
            "  const MoreMenuItem({\n"
            "    super.key,\n"
            "    required this.icon,\n"
            "    required this.label,\n"
            "    this.trailing,\n"
            "    this.subtitle,\n"
            "    this.onTap,\n"
            "    this.dense = true,\n"
            "  });\n",
        ),
        (
            "  final Widget? trailing;\n"
            "  final VoidCallback? onTap;\n"
            "  final bool dense;\n",
            "  final Widget? trailing;\n"
            "  final String? subtitle;\n"
            "  final VoidCallback? onTap;\n"
            "  final bool dense;\n",
        ),
        (
            "      title: Text(label, style: const TextStyle(fontSize: 14)),\n"
            "      trailing: trailing,\n"
            "      onTap: onTap,\n",
            "      title: Text(label, style: const TextStyle(fontSize: 14)),\n"
            "      subtitle: subtitle == null\n"
            "          ? null\n"
            "          : Text(\n"
            "              subtitle!,\n"
            "              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),\n"
            "            ),\n"
            "      trailing: trailing,\n"
            "      onTap: onTap,\n",
        ),
        (
            "                      MoreMenuItem(\n"
            "                        icon: a.icon,\n"
            "                        label: a.label,\n"
            "                        trailing: a.trailing,\n",
            "                      MoreMenuItem(\n"
            "                        icon: a.icon,\n"
            "                        label: a.label,\n"
            "                        trailing: a.trailing,\n"
            "                        subtitle: a.subtitle,\n",
        ),
    ],
)

# ── 2. 视频页菜单扩充 ──
P = 'lib/screens/bilibili_video_page.dart'
s = io.open(P, encoding='utf-8').read()


def rep(old, new, count=1):
    global s
    assert s.count(old) >= 1, old[:100]
    s = s.replace(old, new, count)


rep(
    "                      MoreMenuItem(\n"
    "                        icon: a.icon,\n"
    "                        label: a.label,\n"
    "                        trailing: a.trailing,\n"
    "                        onTap: () {",
    "                      MoreMenuItem(\n"
    "                        icon: a.icon,\n"
    "                        label: a.label,\n"
    "                        trailing: a.trailing,\n"
    "                        subtitle: a.subtitle,\n"
    "                        onTap: () {",
)

rep(
    "import 'package:naviflash/services/bilibili_video_service.dart';\n",
    "import 'package:naviflash/services/bilibili_video_service.dart';\n"
    "import 'package:naviflash/services/bilibili_watch_later_service.dart';\n",
)

old_actions = """    return [
      if (showDanmakuList)
        MoreMenuAction(
          icon: Icons.format_list_bulleted_outlined,
          label: l10n.playerDanmakuList,
          onTap: _showCollapsedDanmakuList,
        ),
      if (hasBvid) ...[
        MoreMenuAction(
          icon: Icons.headphones_rounded,
          label: l10n.playerListenPage,
          onTap: () => unawaited(_openAudioPage()),
        ),
        MoreMenuAction(
          icon: cacheIcon,
          label: cacheText,
          onTap: () => unawaited(_manualCache()),
        ),
        MoreMenuAction(
          icon: Icons.article_outlined,
          label: l10n.playerViewNotes,
          onTap: _showCollapsedVideoNotes,
        ),
        MoreMenuAction(
          icon: Icons.edit_note,
          label: l10n.playerWriteNote,
          onTap: _writeCollapsedVideoNote,
        ),
        MoreMenuAction(
          icon: _onlyPlayAudio
              ? Icons.headphones_rounded
              : Icons.headphones_outlined,
          label: l10n.playerOnlyPlayAudioInline,
          onTap: () => unawaited(_toggleOnlyPlayAudio()),
          // 开关类：留在菜单里看勾选变化，不自动关闭
          closeAfter: false,
          trailing: _onlyPlayAudio
              ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
              : null,
        ),
      ],
    ];
  }"""

new_actions = """    // 播放器已挂载时才能拿到 State（播放器的能力项依赖它）
    final st = _playerKey.currentState;
    final check = const Icon(Icons.check, size: 18, color: Colors.blueAccent);
    return [
      if (showDanmakuList)
        MoreMenuAction(
          icon: Icons.format_list_bulleted_outlined,
          label: l10n.playerDanmakuList,
          onTap: _showCollapsedDanmakuList,
        ),
      if (hasBvid) ...[
        MoreMenuAction(
          icon: Icons.watch_later_outlined,
          label: l10n.videoMenuWatchLater,
          onTap: () => unawaited(_addToWatchLater()),
        ),
        MoreMenuAction(
          icon: Icons.headphones_rounded,
          label: l10n.playerListenPage,
          onTap: () => unawaited(_openAudioPage()),
        ),
        MoreMenuAction(
          icon: cacheIcon,
          label: cacheText,
          onTap: () => unawaited(_manualCache()),
        ),
        MoreMenuAction(
          icon: Icons.article_outlined,
          label: l10n.playerViewNotes,
          onTap: _showCollapsedVideoNotes,
        ),
        MoreMenuAction(
          icon: Icons.edit_note,
          label: l10n.playerWriteNote,
          onTap: _writeCollapsedVideoNote,
        ),
        MoreMenuAction(
          icon: Icons.copy_outlined,
          label: l10n.playerCopyLink,
          onTap: () => unawaited(_copyShareLink()),
        ),
        MoreMenuAction(
          icon: Icons.ios_share_outlined,
          label: l10n.videoShareLabel,
          onTap: _openShareMenu,
        ),
        MoreMenuAction(
          icon: Icons.refresh_outlined,
          label: l10n.videoMenuReload,
          onTap: () => unawaited(_loadDetail()),
        ),
        MoreMenuAction(
          icon: _onlyPlayAudio
              ? Icons.headphones_rounded
              : Icons.headphones_outlined,
          label: l10n.playerOnlyPlayAudioInline,
          onTap: () => unawaited(_toggleOnlyPlayAudio()),
          // 开关类：留在菜单里看勾选变化，不自动关闭
          closeAfter: false,
          trailing: _onlyPlayAudio ? check : null,
        ),
      ],
      // ── 播放器已实现的能力（PiliPlus showSettingSheet 同位置的那批）──
      if (st != null) ...[
        MoreMenuAction(
          icon: Icons.tune_rounded,
          label: l10n.playerDanmakuSettings,
          onTap: st.openDanmakuSettings,
        ),
        MoreMenuAction(
          icon: Icons.subtitles_outlined,
          label: l10n.playerSubtitleSettings,
          onTap: st.openSubtitleSettings,
        ),
        MoreMenuAction(
          icon: Icons.image_outlined,
          label: l10n.playerMenuScreenshot,
          onTap: () => unawaited(st.captureScreenshot()),
        ),
        MoreMenuAction(
          icon: Icons.graphic_eq_outlined,
          label: l10n.playerMenuAudioNorm,
          onTap: () => unawaited(st.showAudioNormalizationMenu()),
        ),
        MoreMenuAction(
          icon: Icons.speaker_group_outlined,
          label: l10n.playerMenuAudioDevice,
          onTap: () => unawaited(st.showAudioDeviceMenu()),
        ),
        MoreMenuAction(
          icon: Icons.dns_outlined,
          label: l10n.playerMenuSource,
          onTap: st.showSourceMenu,
        ),
        MoreMenuAction(
          icon: Icons.high_quality_outlined,
          label: l10n.superResolutionTitle,
          onTap: () => unawaited(st.showSuperResolutionMenu()),
        ),
        MoreMenuAction(
          icon: Icons.info_outline,
          label: l10n.playerMenuStats,
          onTap: st.showPlaybackStats,
        ),
        MoreMenuAction(
          icon: Icons.flip,
          label: l10n.playerFlipHorizontal,
          onTap: st.toggleFlipX,
          closeAfter: false,
          trailing: st.currentFlipX ? check : null,
        ),
        MoreMenuAction(
          icon: Icons.flip_camera_android_outlined,
          label: l10n.playerFlipVertical,
          onTap: st.toggleFlipY,
          closeAfter: false,
          trailing: st.currentFlipY ? check : null,
        ),
        MoreMenuAction(
          icon: Icons.repeat,
          label: l10n.playerMenuEndBehavior,
          subtitle: switch (st.currentEndBehavior) {
            EndBehavior.loop => l10n.playerEndLoop,
            EndBehavior.exit => l10n.playerEndExit,
            EndBehavior.pause => l10n.playerEndPause,
          },
          onTap: () => unawaited(st.cycleEndBehavior()),
          closeAfter: false,
        ),
      ],
    ];
  }

  /// 添加至稍后再看（x/v2/history/toview/add）。
  Future<void> _addToWatchLater() async {
    final detail = _detail;
    if (detail == null) return;
    final r = await BilibiliWatchLaterService.add(
      aid: detail.aid,
      bvid: detail.bvid,
    );
    if (!mounted) return;
    _toast(r.message, error: !r.ok);
  }"""

rep(old_actions, new_actions)

io.open(P, 'w', encoding='utf-8', newline='').write(s)
print('ok', P)
