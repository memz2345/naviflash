# -*- coding: utf-8 -*-
"""发弹幕面板支持底部预留偏移；短视频页两处 push 传底栏回调。"""
import io


def edit(path, pairs):
    s = io.open(path, encoding='utf-8').read()
    for old, new in pairs:
        assert s.count(old) >= 1, (path, old[:70])
        s = s.replace(old, new, 1)
    io.open(path, 'w', encoding='utf-8', newline='').write(s)
    print('ok', path)


edit(
    'lib/widgets/danmaku/danmaku_send_sheet.dart',
    [
        (
            "Future<DanmakuSendStyle?> showDanmakuSendSheet(\n"
            "  BuildContext context, {\n"
            "  String initialText = '',\n"
            "}) {\n"
            "  return showModalBottomSheet<DanmakuSendStyle>(\n"
            "    context: context,\n"
            "    isScrollControlled: true,\n"
            "    backgroundColor: Colors.transparent,\n"
            "    builder: (ctx) => _DanmakuSendSheet(initialText: initialText),\n"
            "  );\n"
            "}",
            "Future<DanmakuSendStyle?> showDanmakuSendSheet(\n"
            "  BuildContext context, {\n"
            "  String initialText = '',\n"
            "  /// 额外的底部留白（短视频页自带底栏时为底栏让位）。\n"
            "  /// 键盘弹起时系统已经把面板顶起来了（此时底栏被键盘盖住），\n"
            "  /// 因此只在键盘收起时生效。\n"
            "  double bottomPadding = 0,\n"
            "}) {\n"
            "  return showModalBottomSheet<DanmakuSendStyle>(\n"
            "    context: context,\n"
            "    isScrollControlled: true,\n"
            "    backgroundColor: Colors.transparent,\n"
            "    builder: (ctx) => _DanmakuSendSheet(\n"
            "      initialText: initialText,\n"
            "      bottomPadding: bottomPadding,\n"
            "    ),\n"
            "  );\n"
            "}",
        ),
        (
            "class _DanmakuSendSheet extends StatefulWidget {\n"
            "  final String initialText;\n"
            "\n"
            "  const _DanmakuSendSheet({required this.initialText});\n",
            "class _DanmakuSendSheet extends StatefulWidget {\n"
            "  final String initialText;\n"
            "  final double bottomPadding;\n"
            "\n"
            "  const _DanmakuSendSheet({\n"
            "    required this.initialText,\n"
            "    this.bottomPadding = 0,\n"
            "  });\n",
        ),
        (
            "    return Padding(\n"
            "      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),\n"
            "      child: Padding(\n"
            "        padding: const EdgeInsets.all(12),",
            "    final viewInsets = MediaQuery.of(context).viewInsets.bottom;\n"
            "    // 键盘弹起时 viewInsets 已经把面板顶起（底栏此刻被键盘盖住），\n"
            "    // 只在键盘收起时才额外给底栏让位\n"
            "    final bottomGap = viewInsets > 0 ? viewInsets : widget.bottomPadding;\n"
            "    return Padding(\n"
            "      padding: EdgeInsets.only(bottom: bottomGap),\n"
            "      child: Padding(\n"
            "        padding: const EdgeInsets.all(12),",
        ),
    ],
)

edit(
    'lib/screens/bilibili_recommend_page.dart',
    [
        (
            "  void _openShorts() {\n"
            "    Navigator.of(context).push<void>(\n"
            "      MaterialPageRoute<void>(builder: (_) => const BilibiliShortsPage()),\n"
            "    );\n"
            "  }",
            "  void _openShorts() {\n"
            "    Navigator.of(context).push<void>(\n"
            "      MaterialPageRoute<void>(\n"
            "        builder: (_) => BilibiliShortsPage(\n"
            "          // 短视频页自带底栏：点其它 tab 时先退出沉浸页再切 tab\n"
            "          onNavTabSelected: (id) {\n"
            "            Navigator.of(context).pop();\n"
            "            _onTabTap(\n"
            "              id == 'home' ? _homeTabIndex : (kNavItemTabIndex[id] ?? 1),\n"
            "            );\n"
            "          },\n"
            "        ),\n"
            "      ),\n"
            "    );\n"
            "  }",
        ),
    ],
)

edit(
    'lib/widgets/side_bar_shell.dart',
    [
        (
            "    if (pageId == 'shorts') {\n"
            "      Navigator.of(context).push<void>(\n"
            "        MaterialPageRoute<void>(builder: (_) => const BilibiliShortsPage()),\n"
            "      );\n"
            "      return;\n"
            "    }",
            "    if (pageId == 'shorts') {\n"
            "      Navigator.of(context).push<void>(\n"
            "        MaterialPageRoute<void>(\n"
            "          builder: (_) => BilibiliShortsPage(\n"
            "            // 短视频页自带底栏：点其它项时先退出沉浸页再切区块\n"
            "            onNavTabSelected: (id) {\n"
            "              Navigator.of(context).pop();\n"
            "              _onNavigate(id);\n"
            "            },\n"
            "          ),\n"
            "        ),\n"
            "      );\n"
            "      return;\n"
            "    }",
        ),
    ],
)
