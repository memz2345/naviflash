# tool/patch_glass_card_color.py
#
# 一次性补丁：玻璃卡片开启时条目底色透明（让玻璃折射透出来），
# 关闭时保持原来的半透明 surface 色。
# 用法：python tool/patch_glass_card_color.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET = "lib/widgets/msg_views.dart"

HELPER = """/// 条目底色：开启玻璃材质时透明（让玻璃折射页面背景），否则半透明 surface 色。
Color msgCardColor(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return SettingsService.videoCardGlassEnabled
      ? Colors.transparent
      : cs.surfaceContainerHigh.withValues(alpha: 0.55);
}

"""

REPLACEMENTS = [
    (
        "/// 列表分隔用的统一外边距（卡片之间 8，左右 12）。",
        HELPER + "/// 列表分隔用的统一外边距（卡片之间 8，左右 12）。",
    ),
    (
        "      color: session.pinned\n          ? cs.onInverseSurface.withValues(\n              alpha: theme.brightness == Brightness.dark ? 0.4 : 0.6,\n            )\n          : cs.surfaceContainerHigh.withValues(alpha: 0.55),",
        "      color: session.pinned\n          ? cs.onInverseSurface.withValues(\n              alpha: theme.brightness == Brightness.dark ? 0.4 : 0.6,\n            )\n          : msgCardColor(context),",
    ),
]

# 四个条目里的同一行底色
REPLACEMENTS += [
    (
        "      color: cs.surfaceContainerHigh.withValues(alpha: 0.55),\n      child: ListTile(",
        "      color: msgCardColor(context),\n      child: ListTile(",
    )
] * 4


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
