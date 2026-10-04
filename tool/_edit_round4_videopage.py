# -*- coding: utf-8 -*-
"""第四轮：宽屏「更多」面板改成面板内导航栈（push / back / X / 预测式返回）。"""
import io

P = 'lib/screens/bilibili_video_page.dart'
s = io.open(P, encoding='utf-8').read()
orig = s


def rep(old, new, count=1):
    global s
    n = s.count(old)
    assert n == count, ('count=%d expect=%d' % (n, count), old[:90])
    s = s.replace(old, new, count)


# ── 1. imports ──
rep(
    "import 'package:naviflash/widgets/danmaku/danmaku_list_sheet.dart';\n",
    "import 'package:naviflash/widgets/danmaku/danmaku_list_sheet.dart';\n"
    "import 'package:naviflash/widgets/danmaku/danmaku_settings_panel.dart';\n",
)
rep(
    "import 'package:naviflash/services/bilibili_watch_later_service.dart';\n",
    "import 'package:naviflash/services/bilibili_watch_later_service.dart';\n"
    "import 'package:naviflash/services/player_audio_service.dart';\n"
    "import 'package:naviflash/services/super_resolution_service.dart';\n",
)

# ── 2. 状态字段 ──
rep(
    "  // 本次系统返回手势是否由 lite 面板接管\n"
    "  bool _memberBackOwned = false;\n",
    "  // 本次系统返回手势是否由 lite 面板接管\n"
    "  bool _memberBackOwned = false;\n"
    "  // 「更多」面板的当前子页面 key（null = 菜单根）\n"
    "  String? _morePageKey;\n"
    "  // 面板整体显隐（0 = 收在右侧屏外，1 = 展开）\n"
    "  late final AnimationController _moreMenuCtrl = AnimationController(\n"
    "    vsync: this,\n"
    "    duration: const Duration(milliseconds: 260),\n"
    "  );\n"
    "  // 面板内导航深度（0 = 菜单根，1 = 子页面完全覆盖）\n"
    "  late final AnimationController _moreNavCtrl = AnimationController(\n"
    "    vsync: this,\n"
    "    duration: const Duration(milliseconds: 260),\n"
    "  );\n"
    "  // 本次系统返回手势是否由「更多」面板接管\n"
    "  bool _moreBackOwned = false;\n",
)

rep(
    "    WidgetsBinding.instance.removeObserver(this);\n"
    "    _memberPanelCtrl.dispose();\n",
    "    WidgetsBinding.instance.removeObserver(this);\n"
    "    _memberPanelCtrl.dispose();\n"
    "    _moreMenuCtrl.dispose();\n"
    "    _moreNavCtrl.dispose();\n",
)

# ── 3. PopScope：更多面板也走关闭动画 ──
rep(
    "        if (_moreMenuOpen) {\n"
    "          _setMoreMenuOpen(false);\n"
    "          return;\n"
    "        }",
    "        if (_moreMenuOpen) {\n"
    "          unawaited(_closeMoreMenu());\n"
    "          return;\n"
    "        }",
)

# ── 4. 预测式返回：lite 面板 / 更多面板都能跟手 ──
rep(
    """  @override
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
""",
    """  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    // 实体 / 虚拟返回键不跟手，交给 PopScope 分支处理
    if (backEvent.isButtonEvent) return false;
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    // lite 作者空间：整个面板滑出
    if (_memberPanelOpen) {
      _memberBackOwned = true;
      _memberPanelCtrl.value = 1 - backEvent.progress;
      return true;
    }
    // 「更多」面板：有子页面时跟手 pop 子页面，在菜单根时跟手整个面板滑出
    if (_moreMenuOpen) {
      _moreBackOwned = true;
      _moreBackCtrl.value = 1 - backEvent.progress;
      return true;
    }
    return false;
  }

  /// 当前该被返回手势驱动的是哪个控制器（子页面优先）。
  AnimationController get _moreBackCtrl =>
      _morePageKey != null ? _moreNavCtrl : _moreMenuCtrl;

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (_moreBackOwned) {
      _moreBackCtrl.value = 1 - backEvent.progress;
      return;
    }
    if (!_memberBackOwned) return;
    _memberPanelCtrl.value = 1 - backEvent.progress;
  }

  @override
  void handleCommitBackGesture() {
    if (_moreBackOwned) {
      _moreBackOwned = false;
      // 子页面 → 退回菜单根；菜单根 → 关掉整个面板（不弹播放页）
      if (_morePageKey != null) {
        unawaited(_popMorePage());
      } else {
        unawaited(_closeMoreMenu());
      }
      return;
    }
    if (!_memberBackOwned) return;
    _memberBackOwned = false;
    unawaited(_closeMemberPanel());
  }

  @override
  void handleCancelBackGesture() {
    if (_moreBackOwned) {
      _moreBackOwned = false;
      _moreBackCtrl.animateTo(
        1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (!_memberBackOwned) return;
    _memberBackOwned = false;
    _memberPanelCtrl.animateTo(
      1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
""",
)

# ── 5. 打开 / 关闭 / 面板内导航 ──
rep(
    """  void _toggleMoreMenu() {
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
""",
    """  void _toggleMoreMenu() {
    if (_moreMenuOpen) {
      unawaited(_closeMoreMenu());
      return;
    }
    // 竖屏：底部弹出菜单（PiliPlus / 短视频页同款），盖在「相关视频 / 评论」上
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
    _openMoreMenu();
  }

  void _openMoreMenu() {
    if (_moreMenuOpen) return;
    setState(() {
      _moreMenuOpen = true;
      _morePageKey = null;
      _moreNavCtrl.value = 0;
    });
    _moreMenuCtrl.forward(from: 0);
  }

  Future<void> _closeMoreMenu() async {
    if (!_moreMenuOpen) return;
    await _moreMenuCtrl.reverse();
    if (!mounted) return;
    setState(() {
      _moreMenuOpen = false;
      _morePageKey = null;
      _moreNavCtrl.value = 0;
    });
  }

  /// 面板内「push」：推入一项的子页面（字幕设置 / 弹幕设置 …）。
  void _pushMorePage(String key) {
    if (_morePageKey == key) return;
    setState(() => _morePageKey = key);
    _moreNavCtrl.forward(from: 0);
  }

  /// 面板内「back」：从子页面退回菜单根。
  Future<void> _popMorePage() async {
    if (_morePageKey == null) return;
    await _moreNavCtrl.reverse();
    if (!mounted) return;
    setState(() => _morePageKey = null);
  }
""",
)

# ── 6. 面板本体：菜单根 + 子页面（水平推入）──
old_card_start = '  /// 宽屏「更多」下拉面板：遮罩 + 面板本体（占据右侧「相关视频 / 评论」栏）。'
old_card_end = '  /// 「听视频」独立页（PiliPlus /audio 同款）'
i0 = s.index(old_card_start)
i1 = s.index(old_card_end)
assert i0 < i1

new_card = '''  /// 宽屏「更多」面板：遮罩 + 面板本体（占据右侧「相关视频 / 评论」栏）。
  ///
  /// 面板内部是一个小导航栈：根是菜单列表，点子项（字幕设置 / 弹幕设置 /
  /// 弹幕列表 / 查看笔记 / 换源 …）时从右侧推入对应内容 —— 和普通 push
  /// 一样有返回（左上角 back 回菜单）与销毁（右上角 X 关掉整个面板）。
  Widget _buildMoreMenuPanel(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final rightWidth = (media.size.width * 0.34).clamp(320.0, 480.0);
    return Stack(
      children: [
        // 遮罩：点空白处直接关掉面板
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => unawaited(_closeMoreMenu()),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          width: rightWidth,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _moreMenuCtrl,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  ),
                ),
            child: _buildMoreMenuCard(cs, l10n, media.size.height),
          ),
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
        child: AnimatedBuilder(
          animation: _moreNavCtrl,
          builder: (context, _) {
            final v = _moreNavCtrl.value;
            final pageKey = _morePageKey;
            return Stack(
              children: [
                // ── 菜单根：推进子页面时向左退让 + 变淡（push 的层次感）──
                Positioned.fill(
                  child: FractionalTranslation(
                    translation: Offset(-0.2 * v, 0),
                    child: Opacity(
                      opacity: (1 - 0.55 * v).clamp(0.0, 1.0),
                      child: _buildMoreMenuRoot(cs, l10n),
                    ),
                  ),
                ),
                // ── 子页面：从右侧推入 ──
                if (pageKey != null)
                  Positioned.fill(
                    child: FractionalTranslation(
                      translation: Offset(1 - v, 0),
                      child: _buildMoreSubPage(cs, l10n, pageKey),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 面板根：菜单列表。
  Widget _buildMoreMenuRoot(ColorScheme cs, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMorePanelHeader(cs, title: l10n.videoMorePanelTitle),
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
                    subtitle: a.subtitle,
                    trailing: a.trailing,
                    onTap: () {
                      // 有子页面的项：在面板内 push，不跳走
                      if (a.opensPage) {
                        _pushMorePage(a.pageKey!);
                        return;
                      }
                      if (a.closeAfter) unawaited(_closeMoreMenu());
                      a.onTap();
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 面板内的子页面：顶栏（back 回菜单 + 标题 + X 销毁面板）+ 内容。
  Widget _buildMoreSubPage(
    ColorScheme cs,
    AppLocalizations l10n,
    String key,
  ) {
    final body = _buildMorePageBody(key);
    return Column(
      children: [
        _buildMorePanelHeader(
          cs,
          title: _morePageTitle(l10n, key),
          onBack: () => unawaited(_popMorePage()),
        ),
        const Divider(height: 1),
        Expanded(
          child: body ?? Center(
            child: Text(
              l10n.loadFailed,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }

  /// 面板顶栏：子页面左侧是 back，右侧永远是 X（关掉整个面板）。
  Widget _buildMorePanelHeader(
    ColorScheme cs, {
    required String title,
    VoidCallback? onBack,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: L10n.current.commonCancel,
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: onBack,
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.more_vert,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: L10n.current.commonClose,
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => unawaited(_closeMoreMenu()),
          ),
        ],
      ),
    );
  }

  String _morePageTitle(AppLocalizations l10n, String key) => switch (key) {
    'danmakuSettings' => l10n.playerDanmakuSettings,
    'danmakuList' => l10n.playerDanmakuList,
    'notes' => l10n.playerViewNotes,
    'subtitleSettings' => l10n.playerSubtitleSettings,
    'audioNormalization' => l10n.playerMenuAudioNorm,
    'audioDevice' => l10n.playerMenuAudioDevice,
    'source' => l10n.playerMenuSource,
    'superResolution' => l10n.superResolutionTitle,
    _ => l10n.videoMorePanelTitle,
  };

  /// 子页面内容。返回 null 表示当前状态拿不到内容（播放器没挂载等）。
  Widget? _buildMorePageBody(String key) {
    final st = _playerKey.currentState;
    final detail = _detail;
    switch (key) {
      case 'danmakuSettings':
        return DanmakuSettingsPanel(
          controller: _danmaku,
          onClose: () => unawaited(_popMorePage()),
        );
      case 'danmakuList':
        return DanmakuListSheet(
          controller: _danmaku,
          onSeek: (seconds) => _playerKey.currentState?.player.seek(
            Duration(milliseconds: (seconds * 1000).round()),
          ),
          currentPosition: () =>
              (_playerKey.currentState?.player.state.position.inMilliseconds ??
                  0) /
              1000.0,
        );
      case 'notes':
        if (detail == null) return null;
        return BiliNoteListSheet(
          aid: detail.aid,
          bvid: detail.bvid,
          videoTitle: detail.title,
        );
      case 'subtitleSettings':
        return st?.buildSubtitleSettingsBody();
      case 'audioDevice':
        return st?.buildAudioDeviceBody();
      case 'audioNormalization':
        if (st == null) return null;
        return _buildOptionList(
          options: [
            for (final m in MpvPlayerPageState.audioNormalizationModes)
              (label: PlayerAudioService.label(m), selected: st.audioNormalizationValue == m),
          ],
          onPick: (i) => st.applyAudioNormalization(
            MpvPlayerPageState.audioNormalizationModes[i],
          ),
        );
      case 'superResolution':
        if (st == null) return null;
        final l10n = AppLocalizations.of(context);
        final modes = MpvPlayerPageState.superResolutionModes;
        return _buildOptionList(
          options: [
            for (final m in modes)
              (
                label: switch (m) {
                  SuperResolutionService.modeEfficiency =>
                    l10n.superResolutionEfficiency,
                  SuperResolutionService.modeQuality =>
                    l10n.superResolutionQuality,
                  _ => l10n.superResolutionOff,
                },
                selected: st.superResolutionValue == m,
              ),
          ],
          onPick: (i) => st.applySuperResolution(modes[i]),
        );
      case 'source':
        if (st == null) return null;
        return _buildOptionList(
          options: st.sourceOptions,
          onPick: (i) => st.selectSourceAt(i),
        );
    }
    return null;
  }

  /// 单选列表（音量均衡 / 超分辨率 / 换源共用）。
  Widget _buildOptionList({
    required List<({String label, bool selected})> options,
    required Future<void> Function(int index) onPick,
  }) {
    if (options.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noContent,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: options.length,
      itemBuilder: (context, i) {
        final o = options[i];
        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: Text(
            o.label,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: o.selected
              ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
              : null,
          onTap: () async {
            await onPick(i);
            if (mounted) setState(() {});
          },
        );
      },
    );
  }

'''
s = s[:i0] + new_card + s[i1:]

# ── 7. 菜单项挂上 pageKey（宽屏面板内 push；竖屏弹层仍走 onTap 直接动作）──
rep(
    """      if (showDanmakuList)
        MoreMenuAction(
          icon: Icons.format_list_bulleted_outlined,
          label: l10n.playerDanmakuList,
          onTap: _showCollapsedDanmakuList,
        ),""",
    """      if (showDanmakuList)
        MoreMenuAction(
          icon: Icons.format_list_bulleted_outlined,
          label: l10n.playerDanmakuList,
          onTap: _showCollapsedDanmakuList,
          pageKey: 'danmakuList',
        ),""",
)
rep(
    """        MoreMenuAction(
          icon: Icons.article_outlined,
          label: l10n.playerViewNotes,
          onTap: _showCollapsedVideoNotes,
        ),""",
    """        MoreMenuAction(
          icon: Icons.article_outlined,
          label: l10n.playerViewNotes,
          onTap: _showCollapsedVideoNotes,
          pageKey: 'notes',
        ),""",
)
rep(
    """        MoreMenuAction(
          icon: Icons.tune_rounded,
          label: l10n.playerDanmakuSettings,
          onTap: st.openDanmakuSettings,
        ),
        MoreMenuAction(
          icon: Icons.subtitles_outlined,
          label: l10n.playerSubtitleSettings,
          onTap: st.openSubtitleSettings,
        ),""",
    """        MoreMenuAction(
          icon: Icons.tune_rounded,
          label: l10n.playerDanmakuSettings,
          onTap: st.openDanmakuSettings,
          pageKey: 'danmakuSettings',
        ),
        MoreMenuAction(
          icon: Icons.subtitles_outlined,
          label: l10n.playerSubtitleSettings,
          onTap: st.openSubtitleSettings,
          pageKey: 'subtitleSettings',
        ),""",
)
rep(
    """        MoreMenuAction(
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
        ),""",
    """        MoreMenuAction(
          icon: Icons.graphic_eq_outlined,
          label: l10n.playerMenuAudioNorm,
          onTap: () => unawaited(st.showAudioNormalizationMenu()),
          pageKey: 'audioNormalization',
        ),
        MoreMenuAction(
          icon: Icons.speaker_group_outlined,
          label: l10n.playerMenuAudioDevice,
          onTap: () => unawaited(st.showAudioDeviceMenu()),
          pageKey: 'audioDevice',
        ),
        MoreMenuAction(
          icon: Icons.dns_outlined,
          label: l10n.playerMenuSource,
          onTap: st.showSourceMenu,
          pageKey: 'source',
        ),
        MoreMenuAction(
          icon: Icons.high_quality_outlined,
          label: l10n.superResolutionTitle,
          onTap: () => unawaited(st.showSuperResolutionMenu()),
          pageKey: 'superResolution',
        ),""",
)

io.open(P, 'w', encoding='utf-8', newline='').write(s)
print('ok, changed:', s != orig)
