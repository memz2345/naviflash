# -*- coding: utf-8 -*-
"""第六轮 A：字幕 / 弹幕设置面板的颜色跟随主题（内嵌到浅色面板时可读）。

把硬编码的 Colors.white* 换成 State 上的调色板 getter：
  embedded（内嵌到视频页「更多」面板，浅色底）→ 主题色
  否则（播放器黑底侧栏 / 底部弹层）→ 保持原来的白色系
"""
import io
import re

TARGETS = [
    'lib/widgets/subtitle_controller.dart',
    'lib/widgets/danmaku/danmaku_settings_panel.dart',
]

# 长 -> 短，避免 Colors.white 抢先匹配 Colors.white70
REPLACES = [
    ('Colors.white70', '_fgMuted'),
    ('Colors.white54', '_fgMuted'),
    ('Colors.white38', '_fgFaint'),
    ('Colors.white30', '_border'),
    ('Colors.white24', '_line'),
    ('Colors.white12', '_lineFaint'),
    ('Colors.white10', '_fill'),
    ('Colors.white', '_fg'),
]

PALETTE = '''
  // ── 内嵌调色板 ──
  //
  // 本面板原本是「播放器黑底侧栏」专用的（写死白字）。内嵌到视频页
  // 「更多」面板（浅色底）时白字会糊掉，所以 embedded 时整组颜色改走主题。
  bool get _themed => widget.embedded;
  ColorScheme get _cs => Theme.of(context).colorScheme;

  /// 主文字 / 主图标。
  Color get _fg => _themed ? _cs.onSurface : Colors.white;

  /// 次级文字 / 次级图标。
  Color get _fgMuted => _themed ? _cs.onSurfaceVariant : Colors.white70;

  /// 最弱的说明文字。
  Color get _fgFaint =>
      _themed ? _cs.onSurfaceVariant.withValues(alpha: 0.75) : Colors.white38;

  /// 分隔线。
  Color get _line => _themed ? _cs.outlineVariant : Colors.white24;

  /// 更淡的分隔线 / 轨道底色。
  Color get _lineFaint =>
      _themed ? _cs.outlineVariant.withValues(alpha: 0.6) : Colors.white12;

  /// 极淡的填充（未选中胶囊底等）。
  Color get _fill =>
      _themed ? _cs.surfaceContainerHighest : Colors.white10;

  /// 描边。
  Color get _border => _themed ? _cs.outlineVariant : Colors.white30;

'''

for path in TARGETS:
    s = io.open(path, encoding='utf-8').read()
    lines = s.split('\n')
    # 保护「颜色预设」这类数据行：整行只有 Colors.white,（带缩进与尾逗号）
    out = []
    protected = 0
    for ln in lines:
        if ln.strip() == 'Colors.white,':
            out.append(ln)
            protected += 1
            continue
        for old, new in REPLACES:
            if old in ln:
                ln = ln.replace(old, new)
                break
        out.append(ln)
    s = '\n'.join(out)
    print('replaced in %s (protected %d palette lines)' % (path, protected))

    # 插入调色板 getter：紧跟 State 类的 `{` 之后
    m = re.search(
        r'class _\w+State extends State<\w+> \{\n', s
    )
    assert m, path
    s = s[: m.end()] + PALETTE + s[m.end():]

    io.open(path, 'w', encoding='utf-8', newline='').write(s)
    print('ok', path)
