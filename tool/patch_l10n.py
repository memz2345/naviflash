import io, sys, os

BASE = r"F:\naviv2\navi\lib\l10n"

# (key, old_value, new_value)
hk_changes = [
    ("startScreenGoBack", "回到上一層", "向上瀏覽"),
    ("netBackTooltip", "返回上一層", "向上瀏覽"),
    ("ossBackTooltip", "返回上一層", "向上瀏覽"),
    ("playHistoryBackTooltip", "返回上一層", "向上瀏覽"),
    ("playerBackTooltip", "返回上一層", "向上瀏覽"),
    ("psBackTooltip", "返回上一層", "向上瀏覽"),
    ("commonBackTooltip", "返回上一層", "向上瀏覽"),
]

en_changes = [
    ("commonBackTooltip", "Go back", "Navigate up"),
    ("playerBackTooltip", "Go back", "Navigate up"),
    ("netBackTooltip", "Go back", "Navigate up"),
    ("ossBackTooltip", "Go back", "Navigate up"),
    ("playHistoryBackTooltip", "Go back", "Navigate up"),
    ("psBackTooltip", "Go back", "Navigate up"),
    ("startScreenGoBack", "Go back", "Navigate up"),
    ("logBackTooltip", "Go back", "Navigate up"),
]

def patch(path, changes):
    with io.open(path, "r", encoding="utf-8") as f:
        text = f.read()
    orig = text
    for key, old, new in changes:
        needle = '"%s": "%s"' % (key, old)
        repl = '"%s": "%s"' % (key, new)
        if needle not in text:
            print("WARN: not found in %s: %s" % (os.path.basename(path), needle))
            continue
        if text.count(needle) != 1:
            print("WARN: multiple matches in %s: %s" % (os.path.basename(path), needle))
        text = text.replace(needle, repl)
    if text != orig:
        with io.open(path, "w", encoding="utf-8") as f:
            f.write(text)
        print("patched:", os.path.basename(path))
    else:
        print("no change:", os.path.basename(path))

patch(os.path.join(BASE, "app_zh_HK.arb"), hk_changes)
patch(os.path.join(BASE, "app_en.arb"), en_changes)
patch(os.path.join(BASE, "app_en_US.arb"), en_changes)
print("done")
