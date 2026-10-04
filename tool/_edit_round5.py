# -*- coding: utf-8 -*-
"""第五轮：面板子页面换成自己的外壳（不透明底 + 深/浅按内容切换 + 去重复标题栏）。"""
import io

# ══════════ 1. DanmakuSettingsPanel：embedded 时不自带标题栏 ══════════
P = 'lib/widgets/danmaku/danmaku_settings_panel.dart'
s = io.open(P, encoding='utf-8').read()


def rep(old, new, count=1):
    global s
    n = s.count(old)
    assert n == count, ('count=%d expect=%d' % (n, count), old[:90])
    s = s.replace(old, new, count)


rep(
    """class DanmakuSettingsPanel extends StatefulWidget {
  final DanmakuController controller;
  final VoidCallback onClose;
  final VoidCallback? onLoadFile;
  final VoidCallback? onFetchOnline;

  const DanmakuSettingsPanel({
    super.key,
    required this.controller,
    required this.onClose,
    this.onLoadFile,
    this.onFetchOnline,
  });""",
    """class DanmakuSettingsPanel extends StatefulWidget {
  final DanmakuController controller;
  final VoidCallback onClose;
  final VoidCallback? onLoadFile;
  final VoidCallback? onFetchOnline;

  /// 内嵌模式：由宿主（视频页「更多」面板）提供外壳与标题栏，
  /// 这里只渲染内容 —— 否则会出现两个标题栏、两个关闭钮。
  ///
  /// ⚠️ 面板内容是给黑色背景设计的（硬编码白字），内嵌时宿主外壳
  /// 必须是深色底，否则字看不清。
  final bool embedded;

  const DanmakuSettingsPanel({
    super.key,
    required this.controller,
    required this.onClose,
    this.onLoadFile,
    this.onFetchOnline,
    this.embedded = false,
  });""",
)

rep(
    """    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 标题栏 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.subtitles, color: Colors.blueAccent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      l10n.danmakuSettingsTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),

          // ── 内容区 ──""",
    """    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 标题栏（内嵌模式由宿主提供，跳过）──
          if (!widget.embedded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.subtitles,
                        color: Colors.blueAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.danmakuSettingsTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
          ],

          // ── 内容区 ──""",
)

io.open(P, 'w', encoding='utf-8', newline='').write(s)
print('ok', P)

# ══════════ 2. SubtitlePanel：embedded 时不自带标题 ══════════
P = 'lib/widgets/subtitle_controller.dart'
s = io.open(P, encoding='utf-8').read()

rep(
    """class SubtitlePanel extends StatefulWidget {""",
    """class SubtitlePanel extends StatefulWidget {
  /// 内嵌模式：宿主（视频页「更多」面板）已有标题栏，这里不再重复渲染。
  /// ⚠️ 本面板为黑色背景设计（硬编码白字），内嵌时宿主外壳必须是深色底。
  final bool embedded;
""",
)
rep(
    """    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(l10n.subtitlePanelTitle,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
""",
    """    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(l10n.subtitlePanelTitle,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
""",
)
rep(
    """    required this.onBgColorChanged,
  });""",
    """    required this.onBgColorChanged,
    this.embedded = false,
  });""",
)
io.open(P, 'w', encoding='utf-8', newline='').write(s)
print('ok', P)
