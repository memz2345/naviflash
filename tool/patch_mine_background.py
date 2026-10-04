# tool/patch_mine_background.py
#
# 一次性补丁：个人中心（我的页）用推荐页同款背景图 + 玻璃卡片（受开关控制）。
# 用法：python tool/patch_mine_background.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET = "lib/screens/bilibili_mine_page.dart"

REPLACEMENTS = [
    # 1) 导入
    (
        "import 'package:naviflash/widgets/message_center_entry.dart';",
        "import 'package:naviflash/widgets/message_center_entry.dart';\nimport 'package:naviflash/widgets/msg_views.dart';\nimport 'package:naviflash/widgets/page_background.dart';",
    ),
    # 2) 快捷入口包玻璃卡片
    (
        "          const SizedBox(height: 14),\n          _buildQuickActions(cs),",
        "          const SizedBox(height: 14),\n          Padding(\n            padding: const EdgeInsets.symmetric(horizontal: 16),\n            child: msgGlassCard(\n              radius: 20,\n              child: Padding(\n                padding: const EdgeInsets.symmetric(vertical: 6),\n                child: _buildQuickActions(cs),\n              ),\n            ),\n          ),",
    ),
    # 3) 列表区包玻璃卡片
    (
        "          Padding(\n            padding: const EdgeInsets.symmetric(horizontal: 16),\n            child: Column(\n              children: buildMorphSegmentedList([",
        "          Padding(\n            padding: const EdgeInsets.symmetric(horizontal: 16),\n            child: msgGlassCard(\n              radius: 20,\n              child: Column(\n              children: buildMorphSegmentedList([",
    ),
    (
        "              ]),\n            ),\n          ),\n        ],\n      ),\n    );",
        "              ]),\n              ),\n            ),\n          ),\n        ],\n      ),\n    );",
    ),
    # 4) 背景图层
    (
        "    if (widget.embeddedInShell) {\n      return Scaffold(\n        backgroundColor: Colors.transparent,\n        body: SafeArea(bottom: false, child: content),\n      );\n    }\n    return Scaffold(\n      backgroundColor: cs.surfaceContainer,\n      appBar: AppBar(\n        title: const Text('我的'),\n        backgroundColor: cs.surfaceContainer,\n      ),\n      body: SafeArea(child: content),\n    );",
        "    // 内容页共享背景图（与推荐/搜索/热门页同一张，见设置）\n    final body = Stack(\n      children: [\n        PageBackground(baseColor: cs.surfaceContainer, contentStyle: true),\n        content,\n      ],\n    );\n    if (widget.embeddedInShell) {\n      return Scaffold(\n        backgroundColor: Colors.transparent,\n        body: SafeArea(bottom: false, child: body),\n      );\n    }\n    return Scaffold(\n      backgroundColor: cs.surfaceContainer,\n      appBar: AppBar(\n        title: const Text('我的'),\n        backgroundColor: cs.surfaceContainer,\n      ),\n      body: SafeArea(child: body),\n    );",
    ),
]


def main():
    full = os.path.join(ROOT, TARGET)
    with io.open(full, "r", encoding="utf-8") as f:
        text = f.read()
    missing = []
    for old, new in REPLACEMENTS:
        if old not in text:
            missing.append(old.strip().splitlines()[0][:80])
            continue
        text = text.replace(old, new, 1)
    with io.open(full, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    if missing:
        print("MISS %s:" % TARGET)
        for m in missing:
            print("   - %s" % m)
        return 1
    print("ok   %s" % TARGET)
    return 0


if __name__ == "__main__":
    sys.exit(main())
