# tool/patch_overscroll_glass.py
#
# 一次性补丁：开启「视频卡片玻璃材质」（真玻璃）时，到顶/到底改用 MD2 光晕
# （GlowingOverscrollIndicator），不再用 M3 拉伸；其余情况保持拉伸。
# 三处 ScrollBehavior 统一走 widgets/navi_overscroll.dart。
# 用法：python tool/patch_overscroll_glass.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MAIN = "lib/main.dart"
FORK = "lib/widgets/plus_refresh_indicator.dart"
MOUSE = "lib/widgets/app_refresh_indicator.dart"

MAIN_OLD = """    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return child;
    }
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );"""
MAIN_NEW = """    // 真玻璃卡片开启时改走 MD2 光晕（拉伸会把玻璃卡片一起缩放变形），
    // 选择逻辑集中在 widgets/navi_overscroll.dart。
    return buildNaviOverscrollIndicator(context, child, details);"""

FORK_OLD = """    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return child;
    }
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );"""
FORK_NEW = """    // 与 NaviScrollBehavior 统一：真玻璃时用 MD2 光晕，否则 M3 拉伸。
    return buildNaviOverscrollIndicator(context, child, details);"""

MOUSE_OLD = """  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };
}"""
MOUSE_NEW = """  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };

  // 过卷指示器与全局保持一致（真玻璃 → MD2 光晕，否则 M3 拉伸），
  // 否则本 behavior 覆盖到的滚动视图会退回 Material 默认拉伸。
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return buildNaviOverscrollIndicator(context, child, details);
  }
}"""

IMPORTS = {
    MAIN: (
        "import 'package:naviflash/widgets/page_background.dart';",
        "import 'package:naviflash/widgets/navi_overscroll.dart';\nimport 'package:naviflash/widgets/page_background.dart';",
    ),
    FORK: (
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\n\nimport 'package:naviflash/widgets/navi_overscroll.dart';",
    ),
    MOUSE: (
        "import 'package:naviflash/widgets/plus_refresh_indicator.dart'",
        "import 'package:naviflash/widgets/navi_overscroll.dart';\nimport 'package:naviflash/widgets/plus_refresh_indicator.dart'",
    ),
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
    jobs = [
        (MAIN, [(IMPORTS[MAIN][0], IMPORTS[MAIN][1]), (MAIN_OLD, MAIN_NEW)]),
        (FORK, [(IMPORTS[FORK][0], IMPORTS[FORK][1]), (FORK_OLD, FORK_NEW)]),
        (MOUSE, [(IMPORTS[MOUSE][0], IMPORTS[MOUSE][1]), (MOUSE_OLD, MOUSE_NEW)]),
    ]
    for path, pairs in jobs:
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
