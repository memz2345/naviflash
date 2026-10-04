# -*- coding: utf-8 -*-
"""视频页：⋮ 下拉面板 / 横屏 lite 作者空间 / 听视频独立页入口。"""
import io

P = 'lib/screens/bilibili_video_page.dart'
s = io.open(P, encoding='utf-8').read()


def rep(old, new, count=1):
    global s
    assert s.count(old) >= 1, old[:90]
    s = s.replace(old, new, count)


# ── 1. imports ──
rep(
    "import 'package:naviflash/screens/bilibili_video_page.dart';\n",
    "",
    0,
) if False else None
rep(
    "import 'package:naviflash/widgets/expressive_app_bar.dart';\n",
    "import 'package:naviflash/screens/bilibili_audio_page.dart';\n"
    "import 'package:naviflash/widgets/expressive_app_bar.dart';\n"
    "import 'package:naviflash/widgets/video/horizontal_member_panel.dart';\n",
)

# ── 2. 状态字段 ──
rep(
    "  // 听视频（仅音频）：播放器内部状态经 onOnlyPlayAudioChanged 回传\n"
    "  bool _onlyPlayAudio = false;\n",
    "  // 听视频（仅音频）：播放器内部状态经 onOnlyPlayAudioChanged 回传\n"
    "  bool _onlyPlayAudio = false;\n"
    "  // 右上角 ⋮ 的「更多」下拉面板是否展开（竖屏落在「相关视频 / 评论」\n"
    "  // 区域右侧，宽屏落在右侧栏；顶部 X / 点遮罩 / 返回键都能关）\n"
    "  bool _moreMenuOpen = false;\n"
    "  // 宽屏右侧是否切到「lite 版作者空间」（只列该 UP 的投稿视频）\n"
    "  bool _memberPanelOpen = false;\n",
)

# ── 3. 播放器：⋮ 委托给本页面板（全屏时仍用播放器自带菜单）──
rep(
    "      onOnlyPlayAudioChanged: (v) {\n"
    "        if (mounted && _onlyPlayAudio != v) {\n"
    "          setState(() => _onlyPlayAudio = v);\n"
    "        }\n"
    "      },\n"
    "    );",
    "      onOnlyPlayAudioChanged: (v) {\n"
    "        if (mounted && _onlyPlayAudio != v) {\n"
    "          setState(() => _onlyPlayAudio = v);\n"
    "        }\n"
    "      },\n"
    "      // 「⋮ 更多」交给本页：竖屏 / 宽屏都显示为可关闭的下拉面板\n"
    "      // （全屏时没有「相关视频 / 评论」区域，仍用播放器自带菜单）\n"
    "      onMoreMenuRequested: _fullscreen ? null : _toggleMoreMenu,\n"
    "    );",
)

# ── 4. 面板挂到页面 Stack 最上层 ──
rep(
    "              },\n"
    "            ),\n"
    "        ],\n"
    "      ),\n"
    "    );\n"
    "\n"
    "    // bodyKey 必须**直接**包住整页本体",
    "              },\n"
    "            ),\n"
    "            // 「更多」下拉面板（⋮）：遮罩 + 面板，点遮罩或 X 关闭\n"
    "            if (_moreMenuOpen && !_fullscreen) _buildMoreMenuPanel(cs),\n"
    "        ],\n"
    "      ),\n"
    "    );\n"
    "\n"
    "    // bodyKey 必须**直接**包住整页本体",
)

# ── 5. PopScope：面板展开时先关面板 ──
rep(
    "      canPop:\n"
    "          !_fullscreen &&\n",
    "      canPop:\n"
    "          !_moreMenuOpen &&\n"
    "          !_memberPanelOpen &&\n"
    "          !_fullscreen &&\n",
)
rep(
    "      onPopInvokedWithResult: (didPop, result) {\n"
    "        if (didPop) return;\n"
    "        if (_fullscreen && mounted) {",
    "      onPopInvokedWithResult: (didPop, result) {\n"
    "        if (didPop) return;\n"
    "        // 「更多」面板 / lite 作者空间展开时，返回键先收面板\n"
    "        if (_moreMenuOpen) {\n"
    "          _setMoreMenuOpen(false);\n"
    "          return;\n"
    "        }\n"
    "        if (_memberPanelOpen) {\n"
    "          setState(() => _memberPanelOpen = false);\n"
    "          return;\n"
    "        }\n"
    "        if (_fullscreen && mounted) {",
)

# ── 6. 宽屏右侧：可切到 lite 作者空间 ──
rep(
    "            child: _detail == null\n"
    "                ? _detailPlaceholder(cs)\n"
    "                : Stack(\n"
    "                    children: [",
    "            child: _detail == null\n"
    "                ? _detailPlaceholder(cs)\n"
    "                : _memberPanelOpen\n"
    "                ? HorizontalMemberPanel(\n"
    "                    mid: _detail!.ownerMid,\n"
    "                    name: _detail!.ownerName,\n"
    "                    face: _detail!.ownerFace,\n"
    "                    focusBvid: _detail!.bvid,\n"
    "                    onClose: () =>\n"
    "                        setState(() => _memberPanelOpen = false),\n"
    "                    onPickVideo: (bvid) {\n"
    "                      Navigator.of(context).push<void>(\n"
    "                        MaterialPageRoute<void>(\n"
    "                          builder: (_) => BilibiliVideoPage(bvid: bvid),\n"
    "                        ),\n"
    "                      );\n"
    "                    },\n"
    "                  )\n"
    "                : Stack(\n"
    "                    children: [",
)

# ── 7. UP 主行：宽屏时改为在右侧栏展开 lite 空间 ──
rep(
    "          onTap: () {\n"
    "            Navigator.of(context).push(\n"
    "              MaterialPageRoute(\n"
    "                builder: (_) => BilibiliUserSpacePage(\n"
    "                  mid: detail.ownerMid,\n"
    "                  focusBvid: detail.bvid,\n"
    "                ),\n"
    "              ),\n"
    "            );\n"
    "          },",
    "          onTap: () {\n"
    "            // 横屏（宽屏）不整页跳转：右侧栏本来就是「相关视频 / 评论」\n"
    "            // 的位置，直接在那里展开 lite 版作者空间（PiliPlus 同款）。\n"
    "            if (_isWideScreen) {\n"
    "              setState(() => _memberPanelOpen = true);\n"
    "              return;\n"
    "            }\n"
    "            Navigator.of(context).push(\n"
    "              MaterialPageRoute(\n"
    "                builder: (_) => BilibiliUserSpacePage(\n"
    "                  mid: detail.ownerMid,\n"
    "                  focusBvid: detail.bvid,\n"
    "                ),\n"
    "              ),\n"
    "            );\n"
    "          },",
)

# ── 8. 封面态 ⋮ 按钮：改为开关下拉面板 ──
old_top_menu = s[
    s.index("  Widget _buildTopMoreMenu() {") : s.index(
        "  /// 听视频（仅音频）：交给播放器关掉视频轨。"
    )
]
new_top_menu = """  Widget _buildTopMoreMenu() {
    final hasBvid = (_detail?.bvid ?? '').isNotEmpty;
    if (!hasBvid) return const SizedBox.shrink();
    // 点击不再弹右上角小气泡菜单：改为展开「下拉面板」——竖屏落在
    // 「相关视频 / 评论」区域右侧、宽屏占据右侧栏，顶部有 X 可关闭。
    return MorphIconButton(
      icon: Icons.more_vert,
      tooltip: L10n.current.playerMoreTooltip,
      frosted: true,
      onTap: _toggleMoreMenu,
    );
  }

  // ═══════════ 右上角 ⋮ 的下拉面板 ═══════════

  void _toggleMoreMenu() => _setMoreMenuOpen(!_moreMenuOpen);

  void _setMoreMenuOpen(bool value) {
    if (_moreMenuOpen == value) return;
    setState(() => _moreMenuOpen = value);
  }

  /// 「更多」下拉面板：遮罩 + 面板本体。
  ///
  /// 宽屏 → 占据右侧「相关视频 / 评论」那一栏；
  /// 竖屏 → 从播放器下沿右侧往下展开，同样落在「相关视频 / 评论」区域。
  Widget _buildMoreMenuPanel(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;
    final isWide = _isWideScreen;
    final rightWidth = (w * 0.34).clamp(320.0, 480.0);
    return Stack(
      children: [
        // 遮罩：点空白处关闭
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _setMoreMenuOpen(false),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
          ),
        ),
        // 面板跟随播放器折叠进度定位（竖屏滚动时播放器会缩成标题栏）
        ValueListenableBuilder<double>(
          valueListenable: _collapseNotifier,
          builder: (context, collapsePx, _) {
            final playerHeight = (isWide ? (w - rightWidth) : w) * 9 / 16;
            final maxCollapse = math.max(
              0.0,
              playerHeight - _kPlayerCollapsedHeight,
            );
            final collapse = isWide
                ? 0.0
                : collapsePx.clamp(0.0, maxCollapse);
            if (isWide) {
              return Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: rightWidth,
                child: _buildMoreMenuCard(cs, l10n, h),
              );
            }
            final top = media.padding.top + playerHeight - collapse + 6;
            return Positioned(
              top: top,
              right: 12,
              width: math.min(320.0, w - 24),
              child: _buildMoreMenuCard(cs, l10n, h - top - 16),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMoreMenuCard(
    ColorScheme cs,
    AppLocalizations l10n,
    double maxHeight,
  ) {
    final hasBvid = (_detail?.bvid ?? '').isNotEmpty;
    final showDanmakuList = _danmaku.itemCount > 0;
    final cacheIcon = _cacheChecking
        ? Icons.hourglass_top_outlined
        : _isCached
        ? Icons.download_done_rounded
        : _isCaching
        ? Icons.downloading_rounded
        : Icons.download_rounded;
    final cacheText = _cacheChecking
        ? '检查中'
        : _isCached
        ? l10n.cacheActionCached
        : _isCaching
        ? l10n.cacheActionCaching
        : l10n.cacheActionDownload;
    return Material(
      color: cs.surfaceContainerHigh,
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight.clamp(120.0, double.infinity),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              child: Row(
                children: [
                  Icon(Icons.more_vert, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.videoMorePanelTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.commonClose,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => _setMoreMenuOpen(false),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showDanmakuList)
                      _moreMenuTile(
                        Icons.format_list_bulleted_outlined,
                        l10n.playerDanmakuList,
                        _showCollapsedDanmakuList,
                      ),
                    if (hasBvid) ...[
                      _moreMenuTile(Icons.headphones_rounded, l10n.playerListenPage, () {
                        _setMoreMenuOpen(false);
                        unawaited(_openAudioPage());
                      }),
                      _moreMenuTile(cacheIcon, cacheText, () {
                        _setMoreMenuOpen(false);
                        unawaited(_manualCache());
                      }),
                      _moreMenuTile(
                        Icons.article_outlined,
                        l10n.playerViewNotes,
                        () {
                          _setMoreMenuOpen(false);
                          _showCollapsedVideoNotes();
                        },
                      ),
                      _moreMenuTile(Icons.edit_note, l10n.playerWriteNote, () {
                        _setMoreMenuOpen(false);
                        _writeCollapsedVideoNote();
                      }),
                      _moreMenuTile(
                        _onlyPlayAudio
                            ? Icons.headphones_rounded
                            : Icons.headphones_outlined,
                        l10n.playerOnlyPlayAudioInline,
                        () => unawaited(_toggleOnlyPlayAudio()),
                        // 开关类留在面板里（可见勾选变化），不自动关闭
                        closeAfter: false,
                        trailing: _onlyPlayAudio
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.blueAccent,
                              )
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moreMenuTile(
    IconData icon,
    String text,
    VoidCallback onTap, {
    bool closeAfter = true,
    Widget? trailing,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 20, color: cs.onSurfaceVariant),
      title: Text(text, style: const TextStyle(fontSize: 14)),
      trailing: trailing,
      onTap: () {
        if (closeAfter) _setMoreMenuOpen(false);
        onTap();
      },
    );
  }

  /// 「听视频」独立页（PiliPlus /audio 同款）：先暂停内嵌播放器再进，
  /// 避免两个播放器同时出声；返回本页后不自动续播。
  Future<void> _openAudioPage() async {
    final detail = _detail;
    if (detail == null || detail.pages.isEmpty) return;
    final st = _playerKey.currentState;
    await st?.player.pause();
    if (!mounted) return;
    final episodes = <AudioEpisode>[
      for (final p in detail.pages)
        AudioEpisode(
          cid: p.cid,
          title: p.part.isNotEmpty ? p.part : 'P${p.page}',
        ),
    ];
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BilibiliAudioPage(
          bvid: detail.bvid,
          title: detail.title,
          cover: detail.pic,
          episodes: episodes,
          initialIndex: _pageIndex.clamp(0, episodes.length - 1),
          ownerName: detail.ownerName,
          ownerMid: detail.ownerMid,
          ownerFace: detail.ownerFace,
        ),
      ),
    );
  }

"""
s = s.replace(old_top_menu, new_top_menu, 1)

# ── 9. 折叠态 ⋮ 也走同一个面板 ──
old_col = s[
    s.index("  Widget _buildCollapsedMoreMenu() {") : s.index(
        "  /// 顶部右上角更多菜单（常驻，含缓存入口，操作区已移除缓存按钮）"
    )
]
new_col = """  Widget _buildCollapsedMoreMenu() {
    final hasBvid = (_detail?.bvid ?? '').isNotEmpty;
    final showDanmakuList = _danmaku.itemCount > 0;
    if (!hasBvid && !showDanmakuList) return const SizedBox.shrink();
    // 与封面态一致：点击展开页面级「更多」下拉面板（可 X 关闭）
    return IconButton(
      icon: const Icon(Icons.more_vert),
      tooltip: L10n.current.playerMoreTooltip,
      onPressed: _toggleMoreMenu,
    );
  }

"""
s = s.replace(old_col, new_col, 1)

io.open(P, 'w', encoding='utf-8', newline='').write(s)
print('ok')
