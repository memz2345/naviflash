# tool/patch_rail_messages.py
#
# 一次性补丁：宽屏常驻导航栏（rail）增加「消息」入口。
#   1) collapsible_side_bar.dart：收起态 + 展开态各加一项
#   2) side_bar_shell.dart：区块 id / 内容映射 + import
# 用法：python tool/patch_rail_messages.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SIDEBAR = "lib/widgets/collapsible_side_bar.dart"
SHELL = "lib/widgets/side_bar_shell.dart"

REPLACEMENTS = {
    SIDEBAR: [
        # 收起态
        (
            "                  _CollapsedNavItem(\n                    icon: Icons.person,\n                    outlinedIcon: Icons.person_outline,\n                    label: '我的',\n                    isSelected: widget.currentPage == 'mine',\n                    onTap: () => widget.onNavigate('mine'),\n                  ),\n                ],",
            "                  _CollapsedNavItem(\n                    icon: Icons.person,\n                    outlinedIcon: Icons.person_outline,\n                    label: '我的',\n                    isSelected: widget.currentPage == 'mine',\n                    onTap: () => widget.onNavigate('mine'),\n                  ),\n                  const SizedBox(height: 6),\n                  _CollapsedNavItem(\n                    icon: Icons.forum,\n                    outlinedIcon: Icons.forum_outlined,\n                    label: '消息',\n                    isSelected: widget.currentPage == 'messages',\n                    onTap: () => widget.onNavigate('messages'),\n                  ),\n                ],",
        ),
        # 展开态
        (
            "              _gmailCapsuleItem(\n                cs,\n                icon: Icons.person_outline,\n                selectedIcon: Icons.person,\n                title: '我的',\n                pageId: 'mine',\n              ),",
            "              _gmailCapsuleItem(\n                cs,\n                icon: Icons.person_outline,\n                selectedIcon: Icons.person,\n                title: '我的',\n                pageId: 'mine',\n              ),\n              _gmailCapsuleItem(\n                cs,\n                icon: Icons.forum_outlined,\n                selectedIcon: Icons.forum,\n                title: '消息',\n                pageId: 'messages',\n              ),",
        ),
    ],
    SHELL: [
        (
            "  static const List<String> _sectionIds = [\n    'home',\n    'search',\n    'live',\n    'mine',\n  ];",
            "  static const List<String> _sectionIds = [\n    'home',\n    'search',\n    'live',\n    'messages',\n    'mine',\n  ];",
        ),
        (
            "      'mine' => const BilibiliMinePage(embeddedInShell: true),",
            "      'messages' => const MessageCenterPage(embeddedInShell: true),\n      'mine' => const BilibiliMinePage(embeddedInShell: true),",
        ),
    ],
}


def apply(path, pairs):
    full = os.path.join(ROOT, path)
    with io.open(full, "r", encoding="utf-8") as f:
        text = f.read()
    missing = []
    for old, new in pairs:
        if old not in text:
            missing.append(old.strip().splitlines()[0][:80])
            continue
        text = text.replace(old, new, 1)
    with io.open(full, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    return missing


def main():
    total = 0
    for path, pairs in REPLACEMENTS.items():
        missing = apply(path, pairs)
        if missing:
            total += len(missing)
            print("MISS %s:" % path)
            for m in missing:
                print("   - %s" % m)
        else:
            print("ok   %s" % path)
    print("missing total: %d" % total)
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
