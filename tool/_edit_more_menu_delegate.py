# -*- coding: utf-8 -*-
"""播放器「⋮ 更多」可委托给外层（视频页下拉面板）。"""
import io


def edit(path, pairs):
    s = io.open(path, encoding='utf-8').read()
    for old, new in pairs:
        assert s.count(old) >= 1, (path, old[:70])
        s = s.replace(old, new, 1)
    io.open(path, 'w', encoding='utf-8', newline='').write(s)
    print('ok', path)


# ── 1. LiquidGlassMenuButton：允许外层接管点击（不展开自带玻璃菜单）──
edit(
    'lib/widgets/liquid_glass_menu_button.dart',
    [
        (
            "    this.padding,\n"
            "    this.frosted = false,\n"
            "  });\n",
            "    this.padding,\n"
            "    this.frosted = false,\n"
            "    /// 非空时点击触发器走这个回调，而**不**展开自带玻璃菜单。\n"
            "    /// 用于「外层要自己画菜单面板」的场景（如 B 站视频播放页把 ⋮\n"
            "    /// 菜单显示在「相关视频 / 评论」区域，且带 X 关闭）。\n"
            "    this.overrideOnTap,\n"
            "  });\n",
        ),
        (
            "  final bool frosted;\n",
            "  final bool frosted;\n"
            "\n"
            "  /// 见构造函数同名参数：非空时接管点击（不展开自带菜单）。\n"
            "  final VoidCallback? overrideOnTap;\n",
        ),
        (
            "          triggerBuilder: (ctx, toggle) => _buildButton(onTap: toggle),",
            "          triggerBuilder: (ctx, toggle) =>\n"
            "              _buildButton(onTap: widget.overrideOnTap ?? toggle),",
        ),
    ],
)

# ── 2. MpvPlayerPage：新增 onMoreMenuRequested ──
edit(
    'lib/screens/player.dart',
    [
        (
            "  /// 「听视频」（仅音频）开关变化回调（宿主页面同步菜单勾选状态）。\n"
            "  final ValueChanged<bool>? onOnlyPlayAudioChanged;\n",
            "  /// 「听视频」（仅音频）开关变化回调（宿主页面同步菜单勾选状态）。\n"
            "  final ValueChanged<bool>? onOnlyPlayAudioChanged;\n"
            "\n"
            "  /// 非空时点击控制条「⋮ 更多」走这个回调，不再展开播放器自带菜单。\n"
            "  /// B 站视频播放页用它把菜单显示在「相关视频 / 评论」区域（可 X 关闭）。\n"
            "  final VoidCallback? onMoreMenuRequested;\n",
        ),
        (
            "    this.onOnlyPlayAudioChanged,\n",
            "    this.onOnlyPlayAudioChanged,\n"
            "    this.onMoreMenuRequested,\n",
        ),
        # 全屏顶栏 ⋮
        (
            "                            LiquidGlassMenuButton(\n"
            "                              icon: Icons.more_vert,\n"
            "                              useMorphStyle: true,\n"
            "                              frosted: true,\n"
            "                              menuWidth: 220,\n",
            "                            LiquidGlassMenuButton(\n"
            "                              icon: Icons.more_vert,\n"
            "                              useMorphStyle: true,\n"
            "                              frosted: true,\n"
            "                              menuWidth: 220,\n"
            "                              overrideOnTap: widget.onMoreMenuRequested,\n",
        ),
        # 内嵌（视频页）控制条 ⋮
        (
            "                              LiquidGlassMenuButton(\n"
            "                                icon: Icons.more_vert,\n"
            "                                iconColor: Colors.white,\n"
            "                                useMorphStyle: false,\n"
            "                                iconSize: 26,\n"
            "                                tooltip: '更多',\n"
            "                                menuWidth: 220,\n",
            "                              LiquidGlassMenuButton(\n"
            "                                icon: Icons.more_vert,\n"
            "                                iconColor: Colors.white,\n"
            "                                useMorphStyle: false,\n"
            "                                iconSize: 26,\n"
            "                                tooltip: '更多',\n"
            "                                menuWidth: 220,\n"
            "                                overrideOnTap: widget.onMoreMenuRequested,\n",
        ),
    ],
)
