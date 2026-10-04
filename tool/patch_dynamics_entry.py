# tool/patch_dynamics_entry.py
#
# 一次性补丁：动态页入口（抽屉 + 宽屏 rail 收起/展开态 + SideBarShell 区块）。
# 用法：python tool/patch_dynamics_entry.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DRAWER = "lib/widgets/app_drawer.dart"
SIDEBAR = "lib/widgets/collapsible_side_bar.dart"
SHELL = "lib/widgets/side_bar_shell.dart"

DRAWER_PATCH = [
    (
        "import 'package:naviflash/screens/message_center_page.dart';",
        "import 'package:naviflash/screens/bilibili_dynamics_page.dart';\nimport 'package:naviflash/screens/message_center_page.dart';",
    ),
    (
        "                _item(\n                  context,\n                  icon: Icons.history_rounded,\n                  title: '观看记录',\n                  pageId: 'history',\n                  onTap: () => _navTo(context, 'history'),\n                ),",
        "                _item(\n                  context,\n                  icon: Icons.history_rounded,\n                  title: '观看记录',\n                  pageId: 'history',\n                  onTap: () => _navTo(context, 'history'),\n                ),\n                _item(\n                  context,\n                  icon: Icons.dynamic_feed_outlined,\n                  title: '动态',\n                  pageId: 'dynamics',\n                  onTap: () => _navTo(context, 'dynamics'),\n                ),",
    ),
    (
        "      case 'messages':\n        Navigator.of(context).push(\n          MaterialPageRoute(builder: (_) => const MessageCenterPage()),\n        );",
        "      case 'messages':\n        Navigator.of(context).push(\n          MaterialPageRoute(builder: (_) => const MessageCenterPage()),\n        );\n      case 'dynamics':\n        Navigator.of(context).push(\n          MaterialPageRoute(builder: (_) => const BilibiliDynamicsPage()),\n        );",
    ),
]

SIDEBAR_PATCH = [
    (
        "import 'package:naviflash/screens/history_center_page.dart';",
        "import 'package:naviflash/screens/bilibili_dynamics_page.dart';\nimport 'package:naviflash/screens/history_center_page.dart';",
    ),
    # 收起态：消息下方加动态
    (
        "                  _CollapsedNavItem(\n                    icon: Icons.forum,\n                    outlinedIcon: Icons.forum_outlined,\n                    label: '消息',\n                    isSelected: widget.currentPage == 'messages',\n                    onTap: () => widget.onNavigate('messages'),\n                  ),",
        "                  _CollapsedNavItem(\n                    icon: Icons.forum,\n                    outlinedIcon: Icons.forum_outlined,\n                    label: '消息',\n                    isSelected: widget.currentPage == 'messages',\n                    onTap: () => widget.onNavigate('messages'),\n                  ),\n                  const SizedBox(height: 6),\n                  _CollapsedNavItem(\n                    icon: Icons.dynamic_feed,\n                    outlinedIcon: Icons.dynamic_feed_outlined,\n                    label: '动态',\n                    isSelected: widget.currentPage == 'dynamics',\n                    onTap: () => widget.onNavigate('dynamics'),\n                  ),",
    ),
    # 展开态
    (
        "              _gmailCapsuleItem(\n                cs,\n                icon: Icons.forum_outlined,\n                selectedIcon: Icons.forum,\n                title: '消息',\n                pageId: 'messages',\n              ),",
        "              _gmailCapsuleItem(\n                cs,\n                icon: Icons.forum_outlined,\n                selectedIcon: Icons.forum,\n                title: '消息',\n                pageId: 'messages',\n              ),\n              _gmailCapsuleItem(\n                cs,\n                icon: Icons.dynamic_feed_outlined,\n                selectedIcon: Icons.dynamic_feed,\n                title: '动态',\n                pageId: 'dynamics',\n              ),",
    ),
    # 展开态：⋮ 更多菜单里的独立页入口（动态作为整页打开）
    (
        "      case 'watchlater':\n        Navigator.of(context).push(\n          MaterialPageRoute(\n            builder: (_) => const BilibiliWatchLaterPage(drawerMode: true),\n          ),\n        );",
        "      case 'watchlater':\n        Navigator.of(context).push(\n          MaterialPageRoute(\n            builder: (_) => const BilibiliWatchLaterPage(drawerMode: true),\n          ),\n        );\n      case 'dynamics':\n        Navigator.of(context).push(\n          MaterialPageRoute(builder: (_) => const BilibiliDynamicsPage()),\n        );",
    ),
]

SHELL_PATCH = [
    (
        "import 'package:naviflash/screens/bilibili_live_page.dart';",
        "import 'package:naviflash/screens/bilibili_dynamics_page.dart';\nimport 'package:naviflash/screens/bilibili_live_page.dart';",
    ),
    (
        "  static const List<String> _sectionIds = [\n    'home',\n    'search',\n    'live',\n    'messages',\n    'mine',\n  ];",
        "  static const List<String> _sectionIds = [\n    'home',\n    'search',\n    'live',\n    'dynamics',\n    'messages',\n    'mine',\n  ];",
    ),
    (
        "      'messages' => const MessageCenterPage(embeddedInShell: true),",
        "      'dynamics' => const BilibiliDynamicsPage(embeddedInShell: true),\n      'messages' => const MessageCenterPage(embeddedInShell: true),",
    ),
]


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
    for path, pairs in ((DRAWER, DRAWER_PATCH), (SIDEBAR, SIDEBAR_PATCH), (SHELL, SHELL_PATCH)):
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
