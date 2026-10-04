# -*- coding: utf-8 -*-
"""第二轮 B：短视频页共用菜单项 / lite 面板排序右上化 + 前往空间 / 评论排序 PiliPlus 化。"""
import io


def edit(path, pairs):
    s = io.open(path, encoding='utf-8').read()
    for old, new in pairs:
        assert s.count(old) >= 1, (path, old[:80])
        s = s.replace(old, new, 1)
    io.open(path, 'w', encoding='utf-8', newline='').write(s)
    print('ok', path)


# ── 短视频页：菜单项改用共享组件（与视频页竖屏菜单同一套样式）──
s = io.open('lib/screens/bilibili_shorts_page.dart', encoding='utf-8').read()
s = s.replace(
    "import 'package:naviflash/widgets/glass_bottom_bar.dart';\n",
    "import 'package:naviflash/widgets/glass_bottom_bar.dart';\n"
    "import 'package:naviflash/widgets/more_menu_sheet.dart';\n",
    1,
)
s = s.replace('            _MoreMenuItem(', '            MoreMenuItem(')
cls = s.index('class _MoreMenuItem extends StatelessWidget {')
end = s.index('\n}\n', cls) + len('\n}\n')
# 连同类后面的空行一起删掉
while s[end:end + 1] == '\n':
    end += 1
s = s[:cls] + s[end:]
io.open('lib/screens/bilibili_shorts_page.dart', 'w', encoding='utf-8', newline='').write(s)
print('ok shorts')

# ── lite 作者空间：排序改成右上角切换（PiliPlus 同款）+ 前往空间 ──
edit(
    'lib/widgets/video/horizontal_member_panel.dart',
    [
        (
            "        // 数量 + 排序（最新 / 最热）\n"
            "        Padding(\n"
            "          padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),\n"
            "          child: Row(\n"
            "            children: [\n"
            "              Text(\n"
            "                l10n.memberLiteVideoCount('$_count'),\n"
            "                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),\n"
            "              ),\n"
            "              const Spacer(),\n"
            "              _OrderChip(\n"
            "                text: '最新',\n"
            "                selected: _order == 'pubdate',\n"
            "                onTap: () => _switchOrder('pubdate'),\n"
            "              ),\n"
            "              const SizedBox(width: 6),\n"
            "              _OrderChip(\n"
            "                text: '最热',\n"
            "                selected: _order == 'click',\n"
            "                onTap: () => _switchOrder('click'),\n"
            "              ),\n"
            "            ],\n"
            "          ),\n"
            "        ),",
            "        // 数量（左）+ 排序切换（右上，PiliPlus 同款 TextButton.icon）\n"
            "        Padding(\n"
            "          padding: const EdgeInsets.fromLTRB(12, 2, 6, 2),\n"
            "          child: Row(\n"
            "            mainAxisAlignment: MainAxisAlignment.spaceBetween,\n"
            "            children: [\n"
            "              Text(\n"
            "                l10n.memberLiteVideoCount('$_count'),\n"
            "                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),\n"
            "              ),\n"
            "              TextButton.icon(\n"
            "                style: const ButtonStyle(\n"
            "                  visualDensity: VisualDensity(\n"
            "                    horizontal: -2,\n"
            "                    vertical: -1.25,\n"
            "                  ),\n"
            "                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,\n"
            "                ),\n"
            "                onPressed: () => _switchOrder(\n"
            "                  _order == 'pubdate' ? 'click' : 'pubdate',\n"
            "                ),\n"
            "                icon: Icon(Icons.sort, size: 16, color: cs.secondary),\n"
            "                label: Text(\n"
            "                  _order == 'pubdate'\n"
            "                      ? l10n.memberLiteOrderPubdate\n"
            "                      : l10n.memberLiteOrderClick,\n"
            "                  style: TextStyle(fontSize: 13, color: cs.secondary),\n"
            "                ),\n"
            "              ),\n"
            "            ],\n"
            "          ),\n"
            "        ),",
        ),
        (
            "                  label: Text(\n"
            "                    l10n.memberLiteViewFull,",
            "                  label: Text(\n"
            "                    l10n.memberLiteGoSpace,",
        ),
    ],
)

# 删掉不再使用的 _OrderChip
p = 'lib/widgets/video/horizontal_member_panel.dart'
s = io.open(p, encoding='utf-8').read()
i = s.index('class _OrderChip extends StatelessWidget {')
j = s.index('\n}\n', i) + len('\n}\n')
while s[j:j + 1] == '\n':
    j += 1
s = s[:i] + s[j:]
io.open(p, 'w', encoding='utf-8', newline='').write(s)
print('ok panel cleanup')

# ── 评论区排序：SegmentedButton → PiliPlus 右上角切换 ──
edit(
    'lib/screens/bilibili_comments_page.dart',
    [
        (
            "        // ── 排序切换：热度 / 时间 ──\n"
            "        Padding(\n"
            "          padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),\n"
            "          child: Row(\n"
            "            children: [\n"
            "              SegmentedButton<int>(\n"
            "                segments: [\n"
            "                  ButtonSegment(\n"
            "                    value: 0,\n"
            "                    label: Text(AppLocalizations.of(context).commentSortHeat),\n"
            "                    icon: const Icon(Icons.local_fire_department, size: 16),\n"
            "                  ),\n"
            "                  ButtonSegment(\n"
            "                    value: 1,\n"
            "                    label: Text(AppLocalizations.of(context).commentSortTime),\n"
            "                    icon: const Icon(Icons.schedule, size: 16),\n"
            "                  ),\n"
            "                ],\n"
            "                selected: {_sort},\n"
            "                onSelectionChanged: _loading\n"
            "                    ? null\n"
            "                    : (s) => _switchSort(s.first),\n"
            "                showSelectedIcon: false,\n"
            "                style: ButtonStyle(\n"
            "                  visualDensity: VisualDensity.compact,\n"
            "                  textStyle: WidgetStatePropertyAll(\n"
            "                    TextStyle(fontSize: 12, color: cs.onSurface),\n"
            "                  ),\n"
            "                ),\n"
            "              ),\n"
            "            ],\n"
            "          ),\n"
            "        ),",
            "        // ── 排序：左侧当前排序说明 + 右上角切换（PiliPlus 同款）──\n"
            "        Padding(\n"
            "          padding: const EdgeInsets.fromLTRB(14, 2, 6, 2),\n"
            "          child: Row(\n"
            "            mainAxisAlignment: MainAxisAlignment.spaceBetween,\n"
            "            children: [\n"
            "              Text(\n"
            "                _sort == 1\n"
            "                    ? AppLocalizations.of(context).commentSortLatestDesc\n"
            "                    : AppLocalizations.of(context).commentSortHottestDesc,\n"
            "                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),\n"
            "              ),\n"
            "              TextButton.icon(\n"
            "                style: const ButtonStyle(\n"
            "                  visualDensity: VisualDensity(\n"
            "                    horizontal: -2,\n"
            "                    vertical: -1.25,\n"
            "                  ),\n"
            "                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,\n"
            "                ),\n"
            "                onPressed: _loading\n"
            "                    ? null\n"
            "                    : () => _switchSort(_sort == 1 ? 0 : 1),\n"
            "                icon: Icon(Icons.sort, size: 16, color: cs.secondary),\n"
            "                label: Text(\n"
            "                  _sort == 1\n"
            "                      ? AppLocalizations.of(context).commentSortLatestShort\n"
            "                      : AppLocalizations.of(context).commentSortHottestShort,\n"
            "                  style: TextStyle(fontSize: 13, color: cs.secondary),\n"
            "                ),\n"
            "              ),\n"
            "            ],\n"
            "          ),\n"
            "        ),",
        ),
    ],
)
