# -*- coding: utf-8 -*-
"""第二轮：lite 面板滑入动画 + 预测式返回 / PiliPlus 式排序 / 楼中楼内嵌 / 竖屏底部菜单。"""
import io

P = 'lib/screens/bilibili_video_page.dart'
s = io.open(P, encoding='utf-8').read()


def rep(old, new, count=1):
    global s
    assert s.count(old) >= 1, old[:100]
    s = s.replace(old, new, count)


# ── 1. import ──
rep(
    "import 'package:naviflash/widgets/video/horizontal_member_panel.dart';\n",
    "import 'package:naviflash/widgets/more_menu_sheet.dart';\n"
    "import 'package:naviflash/widgets/video/horizontal_member_panel.dart';\n",
)

# ── 2. mixin ──
rep(
    "class _BilibiliVideoPageState extends State<BilibiliVideoPage>\n"
    "    with TickerProviderStateMixin {",
    "class _BilibiliVideoPageState extends State<BilibiliVideoPage>\n"
    "    with TickerProviderStateMixin, WidgetsBindingObserver {",
)

# ── 3. 动画控制器字段 ──
rep(
    "  // 宽屏右侧是否切到「lite 版作者空间」（只列该 UP 的投稿视频）\n"
    "  bool _memberPanelOpen = false;\n",
    "  // 宽屏右侧是否切到「lite 版作者空间」（只列该 UP 的投稿视频）\n"
    "  bool _memberPanelOpen = false;\n"
    "  // lite 面板的滑入 / 滑出动画：0 = 滑到屏幕下方之外，1 = 完全展开。\n"
    "  // 返回手势跟手期间由系统进度直接 seek（见 handleUpdateBackGestureProgress）。\n"
    "  late final AnimationController _memberPanelCtrl = AnimationController(\n"
    "    vsync: this,\n"
    "    duration: const Duration(milliseconds: 280),\n"
    "  );\n"
    "  // 本次系统返回手势是否由 lite 面板接管\n"
    "  bool _memberBackOwned = false;\n",
)

# ── 4. initState / dispose ──
rep(
    "  void initState() {\n"
    "    super.initState();\n"
    "    _videoTitle = widget.initialTitle ?? '';",
    "  void initState() {\n"
    "    super.initState();\n"
    "    // 预测式返回（Android 14+）：lite 面板 / 更多面板展开时接管返回手势\n"
    "    WidgetsBinding.instance.addObserver(this);\n"
    "    _videoTitle = widget.initialTitle ?? '';",
)
rep(
    "  void dispose() {\n"
    "    _backDrag.detach();",
    "  void dispose() {\n"
    "    WidgetsBinding.instance.removeObserver(this);\n"
    "    _memberPanelCtrl.dispose();\n"
    "    _backDrag.detach();",
)

# ── 5. PopScope：关闭 lite 面板走动画 ──
rep(
    "        if (_memberPanelOpen) {\n"
    "          setState(() => _memberPanelOpen = false);\n"
    "          return;\n"
    "        }",
    "        if (_memberPanelOpen) {\n"
    "          _closeMemberPanel();\n"
    "          return;\n"
    "        }",
)

# ── 6. UP 主行：打开 lite 面板（带滑入动画）──
rep(
    "            if (_isWideScreen) {\n"
    "              setState(() => _memberPanelOpen = true);\n"
    "              return;\n"
    "            }",
    "            if (_isWideScreen) {\n"
    "              _openMemberPanel();\n"
    "              return;\n"
    "            }",
)

# ── 7. 宽屏右栏：抽出 _buildWideRightPanel / _buildWideMediaPanel ──
start = s.index('                : _memberPanelOpen\n')
si = s.index(': Stack(\n                    children: [', start)
stack_start = si + len(': ')
tail_mark = '\n                    ),\n          ),\n        ),\n      ],\n    );\n  }\n'
stack_end = s.index('\n                    ),\n          ),', stack_start) + len(
    '\n                    ),'
)
stack_src = s[stack_start:stack_end]
s = s[:start] + '                : _buildWideRightPanel(cs),' + s[stack_end:]

wide_methods = """
  /// 宽屏右侧栏：「相关视频 / 评论」打底，lite 作者空间从屏幕下方滑入覆盖。
  Widget _buildWideRightPanel(ColorScheme cs) {
    return Stack(
      children: [
        Positioned.fill(child: _buildWideMediaPanel(cs)),
        if (_memberPanelOpen)
          Positioned.fill(
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _memberPanelCtrl,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                ),
              ),
              child: HorizontalMemberPanel(
                mid: _detail!.ownerMid,
                name: _detail!.ownerName,
                face: _detail!.ownerFace,
                focusBvid: _detail!.bvid,
                onClose: _closeMemberPanel,
                onPickVideo: (bvid) {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => BilibiliVideoPage(bvid: bvid),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  /// 宽屏右侧「相关视频 / 评论」面板（评论区含内嵌 Navigator）。
  Widget _buildWideMediaPanel(ColorScheme cs) {
    return STACK_SRC;
  }

  /// 打开 lite 作者空间（从下方滑入）。
  void _openMemberPanel() {
    if (_memberPanelOpen) return;
    setState(() => _memberPanelOpen = true);
    _memberPanelCtrl.forward(from: 0);
  }

  /// 关闭 lite 作者空间（滑回下方；动画结束后才从树里摘掉）。
  Future<void> _closeMemberPanel() async {
    if (!_memberPanelOpen) return;
    await _memberPanelCtrl.reverse();
    if (!mounted) return;
    setState(() => _memberPanelOpen = false);
  }

  // ── 预测式返回（Android 14+）：lite 面板展开时接管返回手势 ──
  //
  // lite 面板是页面内的抽屉层、不是独立路由，不能走
  // PredictiveBackGestureDetector（那条路要求接管者最终 pop 路由）。
  // 与短视频评论区抽屉同一套做法：直接实现 WidgetsBindingObserver 的四个回调，
  // 用系统给的进度驱动面板下滑；提交 = 关面板（**不是弹掉整个播放页**），
  // 取消 = 回弹。面板没展开时一律不接管，交回系统走正常弹栈。
  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    // 实体 / 虚拟返回键不跟手，交给 PopScope 分支处理
    if (backEvent.isButtonEvent) return false;
    if (!_memberPanelOpen || !mounted) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    _memberBackOwned = true;
    // 系统进度 0→1 对应面板 1→0（完全展开 → 滑出屏幕）
    _memberPanelCtrl.value = 1 - backEvent.progress;
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (!_memberBackOwned) return;
    _memberPanelCtrl.value = 1 - backEvent.progress;
  }

  @override
  void handleCommitBackGesture() {
    if (!_memberBackOwned) return;
    _memberBackOwned = false;
    unawaited(_closeMemberPanel());
  }

  @override
  void handleCancelBackGesture() {
    if (!_memberBackOwned) return;
    _memberBackOwned = false;
    _memberPanelCtrl.animateTo(
      1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

"""
wide_methods = wide_methods.replace('STACK_SRC', stack_src)
marker = '  // ═══════════ 紧凑（竖屏）：上 播放器（外层 Stack 共享实例覆盖），下 tab ═══════════'
s = s.replace(marker, wide_methods + marker, 1)

# ── 8. 竖屏评论区：内嵌 Navigator（楼中楼不再全屏）──
rep(
    """                                // 右 tab：评论
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: _tabBarHeight,
                                  ),
                                  child: BilibiliCommentsPage(
                                    oid: detail.aid,
                                    upMid: detail.ownerMid,
                                    jumpRpid: widget.commentRootId,
                                    jumpSubRpid: widget.commentSecondaryId,
                                    episodeTitle: detail.title,
                                    heroTagsDisabled:
                                        _zoomHeroBlocksInnerHeroes,
                                    currentProgress: _commentsPanelProgress,
                                    captureFrame: _commentsPanelCaptureFrame,
                                  ),
                                ),
""",
    """                                // 右 tab：评论
                                // 评论区面板内嵌 Navigator：楼中楼（回复详情）
                                // 作为独立 push **只在评论区内**展示（PiliPlus
                                // 同款），不再整页跳全屏评论详情；返回键关闭回复页
                                // 而不销毁播放器 / 整个播放页。
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: _tabBarHeight,
                                  ),
                                  child: NavigatorPopHandler(
                                    enabled: !_fullscreen,
                                    onPopWithResult: (result) =>
                                        _commentsNavKey.currentState
                                            ?.maybePop(),
                                    child: Navigator(
                                      key: _commentsNavKey,
                                      observers: [_commentsNavObserver],
                                      onGenerateRoute: (settings) =>
                                          MaterialPageRoute<void>(
                                            settings: settings,
                                            builder: (_) =>
                                                BilibiliCommentsPage(
                                                  oid: detail.aid,
                                                  upMid: detail.ownerMid,
                                                  jumpRpid: widget.commentRootId,
                                                  jumpSubRpid:
                                                      widget.commentSecondaryId,
                                                  commentPostedTick:
                                                      _commentPostedTick,
                                                  episodeTitle: detail.title,
                                                  heroTagsDisabled:
                                                      _zoomHeroBlocksInnerHeroes,
                                                  currentProgress:
                                                      _commentsPanelProgress,
                                                  captureFrame:
                                                      _commentsPanelCaptureFrame,
                                                ),
                                          ),
                                    ),
                                  ),
                                ),
""",
)

# ── 9. 「更多」菜单：竖屏底部弹出（短视频 / PiliPlus 同款）+ 共用菜单项 ──
b0 = s.index('  void _toggleMoreMenu() => _setMoreMenuOpen(!_moreMenuOpen);')
b1 = s.index('  /// 「听视频」独立页（PiliPlus /audio 同款）')
new_menu = '''  /// 「更多」菜单项（竖屏底部菜单与宽屏右侧面板共用同一份）。
  List<MoreMenuAction> _moreMenuActions() {
    final l10n = AppLocalizations.of(context);
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
    return [
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
  }

  /// 打开「更多」菜单。
  ///
  /// 竖屏 → 底部弹出面板（与短视频页 ⋮ 同款，也就是 PiliPlus 的
  /// showSettingSheet 样式），盖在「相关视频 / 评论」区域上，带 X 关闭；
  /// 宽屏 → 右侧栏面板。
  void _toggleMoreMenu() {
    if (_moreMenuOpen) {
      _setMoreMenuOpen(false);
      return;
    }
    if (!_isWideScreen) {
      unawaited(
        showMoreMenuSheet(
          context: context,
          title: AppLocalizations.of(context).videoMorePanelTitle,
          actions: _moreMenuActions(),
        ),
      );
      return;
    }
    _setMoreMenuOpen(true);
  }

  void _setMoreMenuOpen(bool value) {
    if (_moreMenuOpen == value) return;
    setState(() => _moreMenuOpen = value);
  }

  /// 宽屏「更多」下拉面板：遮罩 + 面板本体（占据右侧「相关视频 / 评论」栏）。
  Widget _buildMoreMenuPanel(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final w = media.size.width;
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
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          width: rightWidth,
          child: _buildMoreMenuCard(cs, l10n, media.size.height),
        ),
      ],
    );
  }

  Widget _buildMoreMenuCard(
    ColorScheme cs,
    AppLocalizations l10n,
    double maxHeight,
  ) {
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
                    for (final a in _moreMenuActions())
                      MoreMenuItem(
                        icon: a.icon,
                        label: a.label,
                        trailing: a.trailing,
                        onTap: () {
                          if (a.closeAfter) _setMoreMenuOpen(false);
                          a.onTap();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

'''
s = s[:b0] + new_menu + s[b1:]

io.open(P, 'w', encoding='utf-8', newline='').write(s)
print('ok')
