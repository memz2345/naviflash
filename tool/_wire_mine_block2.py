# tool/_wire_mine_block2.py
# 把块 2 / 块 5 的 8 个入口接入「我的」页次要入口列表（原子修改）。
import io

PATH = r'F:\f\naviflashv2\lib\screens\bilibili_mine_page.dart'

with io.open(PATH, 'r', encoding='utf-8') as f:
    src = f.read()


def ensure_import(content, line):
    return content if line in content else content.replace(
        "import 'package:naviflash/l10n/l10n_helper.dart';",
        "import 'package:naviflash/l10n/l10n_helper.dart';\n" + line,
        1,
    )


new_imports = [
    "import 'package:naviflash/l10n/app_localizations.dart';",
    "import 'package:naviflash/screens/bilibili_comic_page.dart';",
    "import 'package:naviflash/screens/bilibili_shop_page.dart';",
    "import 'package:naviflash/screens/bilibili_space_audio_page.dart';",
    "import 'package:naviflash/screens/bilibili_opus_page.dart';",
    "import 'package:naviflash/screens/bilibili_match_page.dart';",
    "import 'package:naviflash/screens/bilibili_bubble_page.dart';",
    "import 'package:naviflash/screens/bilibili_fav_note_page.dart';",
    "import 'package:naviflash/screens/bilibili_fav_topic_page.dart';",
]
for imp in new_imports:
    if imp not in src:
        src = src.replace(
            "import 'package:naviflash/l10n/l10n_helper.dart';",
            "import 'package:naviflash/l10n/l10n_helper.dart';\n" + imp,
            1,
        )

# 2) 辅助方法：输入 ID 弹窗（赛事 / 小站需要 cid / tribeId）
anchor_open = (
    "  void _open(Widget page) {\n"
    "    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));\n"
    "  }"
)
helper_code = (
    "\n"
    "  Future<void> _openMatch() async {\n"
    "    final l10n = AppLocalizations.of(context);\n"
    "    final raw = await _askId(l10n.inputIdTitle, l10n.inputIdHint);\n"
    "    if (raw != null && raw.isNotEmpty) {\n"
    "      final cid = int.tryParse(raw);\n"
    "      if (cid != null) _open(BilibiliMatchPage(cid: cid));\n"
    "    }\n"
    "  }\n"
    "\n"
    "  Future<void> _openBubble() async {\n"
    "    final l10n = AppLocalizations.of(context);\n"
    "    final raw = await _askId(l10n.inputIdTitle, l10n.inputIdHint);\n"
    "    if (raw != null && raw.isNotEmpty) {\n"
    "      _open(BilibiliBubblePage(tribeId: raw));\n"
    "    }\n"
    "  }\n"
    "\n"
    "  Future<String?> _askId(String title, String hint) async {\n"
    "    final controller = TextEditingController();\n"
    "    final result = await showDialog<String>(\n"
    "      context: context,\n"
    "      builder: (c) => AlertDialog(\n"
    "        title: Text(title),\n"
    "        content: TextField(\n"
    "          controller: controller,\n"
    "          decoration: InputDecoration(hintText: hint),\n"
    "          keyboardType: TextInputType.number,\n"
    "        ),\n"
    "        actions: [\n"
    "          TextButton(\n"
    "            onPressed: () => Navigator.pop(c),\n"
    "            child: Text(AppLocalizations.of(context).cancel),\n"
    "          ),\n"
    "          TextButton(\n"
    "            onPressed: () => Navigator.pop(c, controller.text.trim()),\n"
    "            child: Text(AppLocalizations.of(context).confirm),\n"
    "          ),\n"
    "        ],\n"
    "      ),\n"
    "    );\n"
    "    return result;\n"
    "  }"
)
if '_openMatch' not in src:
    src = src.replace(anchor_open, anchor_open + helper_code, 1)

# 3) 插入 8 个入口（设置项之后，列表闭合 ]), 之前）
old_block = (
    "                      onTap: () =>\n"
    "                          _open(const SplitSettingsScreen(isStandalone: true)),\n"
    "                    ),\n"
    "                  ),"
)
closing = "                ]),"
assert (old_block + "\n" + closing) in src, 'anchor not found'

specs = [
    ("Icons.menu_book_outlined", "漫画", "_open(const BilibiliComicPage())"),
    ("Icons.shopping_bag_outlined", "会员购小店", "_open(const BilibiliShopPage())"),
    ("Icons.audiotrack_outlined", "音频区", "_open(const BilibiliSpaceAudioPage())"),
    ("Icons.article_outlined", "图文", "_open(const BilibiliOpusPage())"),
    ("Icons.emoji_events_outlined", "赛事", "_openMatch"),
    ("Icons.groups_outlined", "兴趣小站", "_openBubble"),
    ("Icons.note_outlined", "笔记管理", "_open(const BilibiliFavNotePage())"),
    ("Icons.tag_outlined", "我的话题", "_open(const BilibiliFavTopicPage())"),
]
entry_lines = []
for icon, label, onTap in specs:
    tap = onTap if not onTap.startswith("_open(") else f"() => {onTap}"
    entry_lines.append(
        "                  MorphRowItem(\n"
        "                    child: ListTile(\n"
        f"                      leading: Icon({icon}, color: cs.onSurfaceVariant),\n"
        f"                      title: const Text('{label}'),\n"
        "                      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),\n"
        f"                      onTap: {tap},\n"
        "                    ),\n"
        "                  ),"
    )
entries_text = "\n".join(entry_lines)

new_block = old_block + "\n" + entries_text + "\n" + closing
src = src.replace(old_block + "\n" + closing, new_block, 1)

with io.open(PATH, 'w', encoding='utf-8', newline='') as f:
    f.write(src)
print('mine page wired: imports + helpers + 8 entries')
