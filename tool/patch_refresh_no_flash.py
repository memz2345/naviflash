# tool/patch_refresh_no_flash.py
#
# 一次性补丁：刷新不要「内容消失 / 闪一下」——
#   1) 推荐页：下拉刷新不播放入场动画（不再整列表淡入），新内容插到最前、
#      旧内容顺延到后面；热门/番剧 tab 仍为整体替换
#   2) 直播网格：刷新不再 arm 内容门控 + 不再整屏加载器
#   3) 热门/排行榜/每周必看页：已有内容时刷新不再整屏加载器
#   4) 分区视频页：同上
# 用法：python tool/patch_refresh_no_flash.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

RECOMMEND = "lib/screens/bilibili_recommend_page.dart"
LIVE_GRID = "lib/widgets/live_room_grid.dart"
POPULAR = "lib/screens/bilibili_popular_list_page.dart"
REGION = "lib/screens/bilibili_region_videos_page.dart"

RECOMMEND_OLD = """        setState(() {
          if (forceRefresh) {
            data.items = deduped;
            data.freshKeys
              ..clear()
              ..addAll(deduped.map((v) => v.bvid));
          } else {"""

RECOMMEND_NEW = """        setState(() {
          if (forceRefresh) {
            final wasEmpty = data.items.isEmpty;
            if (data == _rcmd && !wasEmpty) {
              // 推荐页下拉刷新：新内容插到最前，旧内容顺延到后面
              // （保持阅读位置，且不整列表淡入 → 没有「消失一下」的观感）
              final freshBvids = deduped.map((v) => v.bvid).toSet();
              final old = data.items
                  .where((v) => !freshBvids.contains(v.bvid))
                  .toList(growable: false);
              data.items = [...deduped, ...old];
            } else {
              data.items = deduped;
            }
            // 只有首次加载（列表本来就是空的）才播放入场动画；
            // 下拉刷新直接替换内容，不再整列表淡入闪一下。
            data.freshKeys.clear();
            if (wasEmpty) {
              data.freshKeys.addAll(deduped.map((v) => v.bvid));
            }
          } else {"""

LIVE_GRID_PATCH = [
    (
        "    setState(() {\n      _loading = true;\n      _loadingMore = false;\n      _error = null;\n    });\n    // 仅整屏换内容这一轮门控（首屏 / 切换 resetKey），加载更多保留时不门控\n    // —— 否则列表会被门控的保守帧闪回成整屏加载圈。\n    if (forceRefresh || _items.isEmpty) {",
        "    setState(() {\n      // 已有内容时刷新不弹整屏加载器（下拉圈本身就是反馈）\n      _loading = _items.isEmpty;\n      _loadingMore = false;\n      _error = null;\n    });\n    // 仅「首次进入 / 切换 resetKey」这一轮门控；下拉刷新不再门控，\n    // 否则列表会被藏起来闪一下再出现。\n    if (_items.isEmpty) {",
    ),
]

POPULAR_PATCH = [
    (
        "  Future<void> _load() async {\n    setState(() {\n      _loading = true;\n      _error = null;\n    });",
        "  Future<void> _load() async {\n    setState(() {\n      // 已有内容时刷新静默替换：不弹整屏加载器（下拉圈本身就是反馈）\n      _loading = _items.isEmpty;\n      _error = null;\n    });",
    ),
]

REGION_PATCH = [
    (
        "      if (forceRefresh) {\n        _loading = true;\n        _loadingMore = false;\n      } else {",
        "      if (forceRefresh) {\n        // 已有内容时刷新静默替换，不弹整屏加载器\n        _loading = _items.isEmpty;\n        _loadingMore = false;\n      } else {",
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
    for path, pairs in (
        (RECOMMEND, [(RECOMMEND_OLD, RECOMMEND_NEW)]),
        (LIVE_GRID, LIVE_GRID_PATCH),
        (POPULAR, POPULAR_PATCH),
        (REGION, REGION_PATCH),
    ):
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
