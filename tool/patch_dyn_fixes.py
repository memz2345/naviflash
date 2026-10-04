# tool/patch_dyn_fixes.py
#
# 修正：LazyCoverImage 首参为位置参数；去掉 rail 里多余的动态页 import。
# 用法：python tool/patch_dyn_fixes.py
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CARD = "lib/widgets/dynamic_card.dart"
SIDEBAR = "lib/widgets/collapsible_side_bar.dart"


def patch(path, pairs, regex_pairs=()):
    full = os.path.join(ROOT, path)
    with io.open(full, "r", encoding="utf-8") as f:
        text = f.read()
    missing = []
    for old, new in pairs:
        if old not in text:
            missing.append(old.strip().splitlines()[0][:80])
            continue
        text = text.replace(old, new, 1)
    for pattern, repl in regex_pairs:
        text, n = re.subn(pattern, repl, text)
        if n == 0:
            missing.append(pattern[:80])
    with io.open(full, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    return missing


def main():
    total = 0

    # LazyCoverImage(url: X, ...) → LazyCoverImage(X, ...)
    missing = patch(
        CARD,
        [],
        regex_pairs=[
            (r"LazyCoverImage\(\s*url:\s*([^,\n]+),", r"LazyCoverImage(\1,"),
        ],
    )
    total += len(missing)
    for m in missing:
        print("MISS %s: %s" % (CARD, m))
    if not missing:
        print("ok   %s" % CARD)

    missing = patch(
        SIDEBAR,
        [
            (
                "import 'package:naviflash/screens/bilibili_dynamics_page.dart';\n",
                "",
            )
        ],
    )
    total += len(missing)
    for m in missing:
        print("MISS %s: %s" % (SIDEBAR, m))
    if not missing:
        print("ok   %s" % SIDEBAR)

    print("missing total: %d" % total)
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
