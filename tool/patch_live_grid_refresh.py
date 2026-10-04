# tool/patch_live_grid_refresh.py
#
# 一次性补丁：直播网格区分「数据源切换」（清空 + 重载）与「下拉刷新」
# （保留内容、静默替换），避免刷新时整列表闪一下。
#   - LiveRoomGrid 新增 refreshTick
#   - live_tag_feed：resetKey 只表达数据源，刷新走 refreshTick
# 用法：python tool/patch_live_grid_refresh.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

GRID = "lib/widgets/live_room_grid.dart"
FEED = "lib/widgets/live_tag_feed.dart"

GRID_PATCH = [
    (
        "  void didUpdateWidget(covariant LiveRoomGrid oldWidget) {\n    super.didUpdateWidget(oldWidget);\n    if (oldWidget.resetKey != widget.resetKey) {\n      _load(forceRefresh: true);\n    }\n  }",
        "  void didUpdateWidget(covariant LiveRoomGrid oldWidget) {\n    super.didUpdateWidget(oldWidget);\n    if (oldWidget.resetKey != widget.resetKey) {\n      // 数据源变化（分区 / 排序）：先清空再整屏加载\n      setState(() => _items = []);\n      _load(forceRefresh: true);\n      return;\n    }\n    if (oldWidget.refreshTick != widget.refreshTick) {\n      // 下拉刷新：保留当前内容，拉到新数据后直接替换（不闪一下）\n      _load(forceRefresh: true);\n    }\n  }",
    ),
]

FEED_PATCH = [
    (
        "    final String resetKey =\n        '$_reloadTick-${areaMode ? 'a$_parent-$_child-${_sort.name}' : 'rcmd'}';",
        "    // resetKey 只表达「数据源」（分区 / 排序）——刷新走 refreshTick，\n    // 这样下拉刷新不会把整列表清空重建（不再闪一下）。\n    final String resetKey = areaMode\n        ? 'a$_parent-$_child-${_sort.name}'\n        : 'rcmd';",
    ),
    (
        "          child: LiveRoomGrid(\n            resetKey: resetKey,",
        "          child: LiveRoomGrid(\n            resetKey: resetKey,\n            refreshTick: _reloadTick,",
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


def find_field_anchor(path):
    """在 LiveRoomGrid 的 resetKey 字段旁插入 refreshTick 字段声明。"""
    full = os.path.join(ROOT, path)
    with io.open(full, "r", encoding="utf-8") as f:
        text = f.read()
    anchor = "  final String resetKey;"
    if anchor not in text:
        return False
    text = text.replace(
        anchor,
        "  final String resetKey;\n\n"
        "  /// 外部刷新信号（+1 即重新拉第 1 页）：只换内容，不清空列表。\n"
        "  final int refreshTick;",
        1,
    )
    ctor_anchor = "    required this.resetKey,"
    if ctor_anchor not in text:
        print("MISS ctor: %s" % ctor_anchor)
        return False
    text = text.replace(
        ctor_anchor,
        "    required this.resetKey,\n    this.refreshTick = 0,",
        1,
    )
    with io.open(full, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    return True


def main():
    total = 0
    if not find_field_anchor(GRID):
        total += 1
        print("MISS fields: %s" % GRID)
    else:
        print("ok   %s (fields)" % GRID)

    for path, pairs in ((GRID, GRID_PATCH), (FEED, FEED_PATCH)):
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
