# 视频页顶部操作行：毛玻璃圆钮 → 纯透明（保留 morph + ripple）
import io

path = 'lib/screens/player.dart'
with io.open(path, encoding='utf-8') as f:
    text = f.read()

PAIRS = [
    # 返回
    (
        '                            // 返回按钮：与搜索页一致的毛玻璃圆钮\n'
        '                            MorphIconButton(\n'
        '                              icon: Icons.arrow_back,\n'
        '                              tooltip: L10n.current.playerBackTooltip,\n'
        '                              onTap: () => Navigator.of(context).pop(),\n'
        '                              frosted: true,\n'
        '                            ),',
        '                            // 返回按钮：叠在画面上，背景透明（不挡视频），\n'
        '                            // 只保留 morph 形变 + 水波纹\n'
        '                            MorphIconButton(\n'
        '                              icon: Icons.arrow_back,\n'
        '                              tooltip: L10n.current.playerBackTooltip,\n'
        '                              iconColor: Colors.white,\n'
        '                              transparent: true,\n'
        '                              onTap: () => Navigator.of(context).pop(),\n'
        '                            ),',
    ),
    # 主页
    (
        '                            MorphIconButton(\n'
        '                              icon: Icons.home_outlined,\n'
        '                              tooltip: l10n.bottomNavItemHome,\n'
        '                              onTap: _goHome,\n'
        '                              frosted: true,\n'
        '                            ),',
        '                            MorphIconButton(\n'
        '                              icon: Icons.home_outlined,\n'
        '                              tooltip: l10n.bottomNavItemHome,\n'
        '                              iconColor: Colors.white,\n'
        '                              transparent: true,\n'
        '                              onTap: _goHome,\n'
        '                            ),',
    ),
    # 听视频
    (
        '                              iconColor: onlyPlayAudio\n'
        '                                  ? Colors.blueAccent\n'
        '                                  : null,\n'
        '                              tooltip: L10n.current.playerOnlyPlayAudio,\n'
        '                              onTap: () => setOnlyPlayAudio(!onlyPlayAudio),\n'
        '                              frosted: true,',
        '                              iconColor: onlyPlayAudio\n'
        '                                  ? Colors.blueAccent\n'
        '                                  : Colors.white,\n'
        '                              tooltip: L10n.current.playerOnlyPlayAudio,\n'
        '                              transparent: true,\n'
        '                              onTap: () => setOnlyPlayAudio(!onlyPlayAudio),',
    ),
    # 投屏
    (
        '                            MorphIconButton(\n'
        '                              icon: Icons.tv_outlined,\n'
        '                              tooltip: L10n.current.playerCast,\n'
        '                              onTap: () => _openDlnaCast(),\n'
        '                              frosted: true,\n'
        '                            ),',
        '                            MorphIconButton(\n'
        '                              icon: Icons.tv_outlined,\n'
        '                              tooltip: L10n.current.playerCast,\n'
        '                              iconColor: Colors.white,\n'
        '                              transparent: true,\n'
        '                              onTap: () => _openDlnaCast(),\n'
        '                            ),',
    ),
    # 更多（玻璃菜单按钮）
    (
        '                            // ⋮ 更多（弹幕列表 / 查看笔记 / 字幕设置 /\n'
        '                            // 高级设置 / 旋转 90°）液态玻璃 + liquid-dom\n'
        '                            // 动画菜单；与返回同款毛玻璃圆钮。\n'
        '                            LiquidGlassMenuButton(\n'
        '                              icon: Icons.more_vert,\n'
        '                              useMorphStyle: true,\n'
        '                              frosted: true,\n',
        '                            // ⋮ 更多（弹幕列表 / 查看笔记 / 字幕设置 /\n'
        '                            // 高级设置 / 旋转 90°）玻璃菜单；触发器同样透明\n'
        '                            // （保留 morph + ripple）。\n'
        '                            LiquidGlassMenuButton(\n'
        '                              icon: Icons.more_vert,\n'
        '                              useMorphStyle: true,\n'
        '                              transparent: true,\n'
        '                              iconColor: Colors.white,\n',
    ),
]

for old, new in PAIRS:
    assert text.count(old) == 1, (old[:60], text.count(old))
    text = text.replace(old, new)

with io.open(path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(text)
print('patched', path)
