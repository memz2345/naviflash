# -*- coding: utf-8 -*-
"""第五轮 B：弹幕列表支持内嵌关闭回调 + 视频页面板子页换新外壳。"""
import io


def edit(path, pairs):
    s = io.open(path, encoding='utf-8').read()
    for old, new, cnt in pairs:
        n = s.count(old)
        assert n == cnt, (path, 'count=%d expect=%d' % (n, cnt), old[:90])
        s = s.replace(old, new, cnt)
    io.open(path, 'w', encoding='utf-8', newline='').write(s)
    print('ok', path)


# ══════════ 1. DanmakuListSheet：内嵌时关闭走外部回调 ══════════
edit(
    'lib/widgets/danmaku/danmaku_list_sheet.dart',
    [
        (
            """  /// 当前播放进度（秒）；非空时打开自动定位/跟随当前进度。
  final double Function()? currentPosition;

  const DanmakuListSheet({
    super.key,
    required this.controller,
    required this.onSeek,
    this.currentPosition,
  });""",
            """  /// 当前播放进度（秒）；非空时打开自动定位/跟随当前进度。
  final double Function()? currentPosition;

  /// 内嵌（视频页「更多」面板子页面）时的关闭回调。
  ///
  /// 不传时关闭钮走 `Navigator.maybePop()`（弹层场景）；内嵌时面板不是路由，
  /// 直接 maybePop 会把整个播放页弹掉，所以必须传这个。
  final VoidCallback? onClose;

  const DanmakuListSheet({
    super.key,
    required this.controller,
    required this.onSeek,
    this.currentPosition,
    this.onClose,
  });""",
            1,
        ),
        (
            """                          onPressed: () => Navigator.of(context).maybePop(),""",
            """                          onPressed: () {
                            final close = widget.onClose;
                            if (close != null) {
                              close();
                              return;
                            }
                            Navigator.of(context).maybePop();
                          },""",
            1,
        ),
    ],
)

# ══════════ 2. 视频页：子页面外壳（不透明 + 深/浅按内容切） + 菜单根不残留 ══════════
P = 'lib/screens/bilibili_video_page.dart'
s = io.open(P, encoding='utf-8').read()


def rep(old, new, count=1):
    global s
    n = s.count(old)
    assert n == count, ('count=%d expect=%d' % (n, count), old[:90])
    s = s.replace(old, new, count)


# 2a. 菜单根：子页面完全推入后不再渲染（否则会透出来 / 抢手势）
rep(
    """                // ── 菜单根：推进子页面时向左退让 + 变淡（push 的层次感）──
                Positioned.fill(
                  child: FractionalTranslation(
                    translation: Offset(-0.2 * v, 0),
                    child: Opacity(
                      opacity: (1 - 0.55 * v).clamp(0.0, 1.0),
                      child: _buildMoreMenuRoot(cs, l10n),
                    ),
                  ),
                ),""",
    """                // ── 菜单根：推进子页面时向左退让 + 变淡（push 的层次感）；
                //    子页面完全推入后（v == 1）直接不渲染，避免任何透出 ──
                if (v < 1)
                  Positioned.fill(
                    child: FractionalTranslation(
                      translation: Offset(-0.2 * v, 0),
                      child: Opacity(
                        opacity: (1 - 0.7 * v).clamp(0.0, 1.0),
                        child: _buildMoreMenuRoot(cs, l10n),
                      ),
                    ),
                  ),""",
)

# 2b. 子页面外壳：不透明底 + 深/浅按内容切换 + 顶栏颜色跟随
rep(
    """  /// 面板内的子页面：顶栏（back 回菜单 + 标题 + X 销毁面板）+ 内容。
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
  }) {""",
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

  /// 面板顶栏：子页面左侧是 back，右侧永远是 X（关掉整个面板）。
  Widget _buildMorePanelHeader(
    ColorScheme cs, {
    required String title,
    VoidCallback? onBack,
    Color? fg,
  }) {""",
)

# 2c. 顶栏配色跟随
rep(
    """          else
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
          ),""",
    """          else
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.more_vert,
                size: 18,
                color: fg ?? cs.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: L10n.current.commonClose,
            icon: Icon(Icons.close, size: 20, color: fg),
            onPressed: () => unawaited(_closeMoreMenu()),
          ),""",
)

# 2d. 内容组件改走 embedded / onClose
rep(
    """      case 'danmakuSettings':
        return DanmakuSettingsPanel(
          controller: _danmaku,
          onClose: () => unawaited(_popMorePage()),
        );
      case 'danmakuList':
        return DanmakuListSheet(
          controller: _danmaku,
          onSeek: (seconds) => _playerKey.currentState?.player.seek(
            Duration(milliseconds: (seconds * 1000).round()),
          ),""",
    """      case 'danmakuSettings':
        return DanmakuSettingsPanel(
          controller: _danmaku,
          onClose: () => unawaited(_popMorePage()),
          // 外壳（标题栏 / 关闭钮）由面板统一提供
          embedded: true,
        );
      case 'danmakuList':
        return DanmakuListSheet(
          controller: _danmaku,
          onClose: () => unawaited(_popMorePage()),
          onSeek: (seconds) => _playerKey.currentState?.player.seek(
            Duration(milliseconds: (seconds * 1000).round()),
          ),""",
)

io.open(P, 'w', encoding='utf-8', newline='').write(s)
print('ok', P)
