# -*- coding: utf-8 -*-
"""第六轮 B：面板子页面统一主题色外壳 + 修「自由拖拽」开关不刷新。"""
import io


def edit(path, pairs):
    s = io.open(path, encoding='utf-8').read()
    for old, new, cnt in pairs:
        n = s.count(old)
        assert n == cnt, (path, 'count=%d expect=%d' % (n, cnt), old[:90])
        s = s.replace(old, new, cnt)
    io.open(path, 'w', encoding='utf-8', newline='').write(s)
    print('ok', path)


# ══════════ 1. player：面板内嵌内容的状态回推 ══════════
edit(
    'lib/screens/player.dart',
    [
        # 1a. 版本号 notifier
        (
            """  // ── 「更多」面板的内嵌子页面（宽屏右侧面板里以 push 感显示，不弹弹层）──

  /// 字幕设置内容（无外框 / 无标题），宿主「更多」面板的子页面直接渲染。
  Widget buildSubtitleSettingsBody() =>
      _buildSubtitleSettingsBody(embedded: true);""",
            """  // ── 「更多」面板的内嵌子页面（宽屏右侧面板里以 push 感显示，不弹弹层）──

  /// 面板子页面的树挂在**宿主（视频页）**下面，播放器 setState 不会带上它，
  /// 所以凡是被面板显示出来的播放器状态（字幕拖拽开关 / 字号 / 颜色 / 位置）
  /// 变更后都要 `++`，宿主外层的 ValueListenableBuilder 才会重建。
  final ValueNotifier<int> _uiRevision = ValueNotifier<int>(0);

  void _bumpUiRevision() {
    if (!mounted) return;
    _uiRevision.value++;
  }

  /// 字幕设置内容（无外框 / 无标题），宿主「更多」面板的子页面直接渲染。
  Widget buildSubtitleSettingsBody() => ValueListenableBuilder<int>(
    valueListenable: _uiRevision,
    builder: (context, _, __) => _buildSubtitleSettingsBody(embedded: true),
  );""",
            1,
        ),
        # 1b. dispose
        (
            """  void dispose() {
    // 兜底：桌面画中画状态下退出播放页时恢复窗口""",
            """  void dispose() {
    _uiRevision.dispose();
    // 兜底：桌面画中画状态下退出播放页时恢复窗口""",
            1,
        ),
        # 1c. 拖拽开关
        (
            """    setState(() {
      _subDragEnabled = !_subDragEnabled;
      if (!_subDragEnabled) _subtitleDragging = false;
    });""",
            """    setState(() {
      _subDragEnabled = !_subDragEnabled;
      if (!_subDragEnabled) _subtitleDragging = false;
    });
    // 面板里这个 switch 是受控的，得让宿主一起重建才跟手
    _bumpUiRevision();""",
            1,
        ),
        # 1d. 重置位置
        (
            """    setState(() {
      _subPadL = PlayerSettingsService.defaultSubtitlePadL;
      _subPadR = PlayerSettingsService.defaultSubtitlePadR;
      _subPadB = PlayerSettingsService.defaultSubtitlePadB;
    });""",
            """    setState(() {
      _subPadL = PlayerSettingsService.defaultSubtitlePadL;
      _subPadR = PlayerSettingsService.defaultSubtitlePadR;
      _subPadB = PlayerSettingsService.defaultSubtitlePadB;
    });
    _bumpUiRevision();""",
            1,
        ),
        # 1e. 面板里的字号 / 颜色回调
        (
            """        onFontSizeChanged: (v) => setState(() => _subFontSize = v),
        onFontColorChanged: (c) => setState(() => _subColor = c),
        onBgColorChanged: (c) => setState(() => _subBgColor = c),""",
            """        onFontSizeChanged: (v) => setState(() {
          _subFontSize = v;
          _bumpUiRevision();
        }),
        onFontColorChanged: (c) => setState(() {
          _subColor = c;
          _bumpUiRevision();
        }),
        onBgColorChanged: (c) => setState(() {
          _subBgColor = c;
          _bumpUiRevision();
        }),""",
            1,
        ),
    ],
)

# ══════════ 2. 视频页：子页面外壳统一主题色（不再分深浅） ══════════
P = 'lib/screens/bilibili_video_page.dart'
s = io.open(P, encoding='utf-8').read()


def rep(old, new, count=1):
    global s
    n = s.count(old)
    assert n == count, ('count=%d expect=%d' % (n, count), old[:90])
    s = s.replace(old, new, count)


rep(
    """  /// 面板内的子页面：自己的外壳（不透明底 + back/标题/X）+ 内容。
  ///
  /// 复用来的内容组件分两类，外壳得跟着分：
  ///   * 播放器的弹幕 / 字幕侧栏组件是为**黑底白字**写的 → 这类子页面用深色壳；
  ///   * 笔记列表、选项列表跟随主题 → 用主题壳。
  /// 不给壳的话下层菜单会透上来（而且深色组件在浅色壳里白字发虚）。
  Widget _buildMoreSubPage(
    ColorScheme cs,
    AppLocalizations l10n,
    String key,
  ) {
    final dark = _morePageIsDark(key);
    final fg = dark ? Colors.white : cs.onSurface;
    final divider = dark
        ? Colors.white24
        : cs.outlineVariant.withValues(alpha: 0.6);
    final body = _buildMorePageBody(key);
    return Material(
      color: dark ? const Color(0xF2121212) : cs.surfaceContainerHigh,
      child: Column(
        children: [
          _buildMorePanelHeader(
            cs,
            title: _morePageTitle(l10n, key),
            onBack: () => unawaited(_popMorePage()),
            fg: fg,
          ),
          Divider(height: 1, color: divider),
          Expanded(
            child:
                body ??
                Center(
                  child: Text(
                    l10n.loadFailed,
                    style: TextStyle(
                      fontSize: 13,
                      color: dark ? Colors.white54 : cs.onSurfaceVariant,
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  /// 该子页面的内容是「黑底白字」的播放器侧栏组件吗。
  bool _morePageIsDark(String key) => switch (key) {
    'danmakuSettings' || 'subtitleSettings' => true,
    _ => false,
  };
""",
    """  /// 面板内的子页面：自己的外壳（不透明底 + back/标题/X）+ 内容。
  ///
  /// 外壳配色和菜单根完全一致（同一个 surfaceContainerHigh），这样切进子页面
  /// 时面板不会突然变色。内容组件里的「黑底白字」都已经改成跟随主题
  /// （见 DanmakuSettingsPanel / SubtitlePanel 的 `embedded` 调色板）。
  Widget _buildMoreSubPage(
    ColorScheme cs,
    AppLocalizations l10n,
    String key,
  ) {
    final body = _buildMorePageBody(key);
    return Material(
      color: cs.surfaceContainerHigh,
      child: Column(
        children: [
          _buildMorePanelHeader(
            cs,
            title: _morePageTitle(l10n, key),
            onBack: () => unawaited(_popMorePage()),
          ),
          Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.6),
          ),
          Expanded(
            child:
                body ??
                Center(
                  child: Text(
                    l10n.loadFailed,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
""",
)

rep(
    """    required String title,
    VoidCallback? onBack,
    Color? fg,
  }) {""",
    """    required String title,
    VoidCallback? onBack,
  }) {""",
)

rep(
    """              child: Icon(
                Icons.more_vert,
                size: 18,
                color: fg ?? cs.onSurfaceVariant,
              ),""",
    """              child: Icon(
                Icons.more_vert,
                size: 18,
                color: cs.onSurfaceVariant,
              ),""",
)

rep(
    """              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: fg,
              ),""",
    """              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),""",
)

rep(
    """            icon: Icon(Icons.close, size: 20, color: fg),""",
    """            icon: const Icon(Icons.close, size: 20),""",
)

io.open(P, 'w', encoding='utf-8', newline='').write(s)
print('ok', P)
