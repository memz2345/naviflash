# tool/patch_like_avatar.py
#
# 一次性补丁：收到的赞 / 社区互动头像默认显示「最后一个操作的人」
# （点赞等互动消息聚合多人时，取 users 列表最后一位 = 最近一次操作者）。
# 用法：python tool/patch_like_avatar.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET = "lib/screens/msg_like_me_page.dart"

REPLACEMENTS = [
    (
        "    final users = item.users;\n    final first = users.isEmpty ? BiliMsgUser.empty : users.first;",
        "    final users = item.users;\n    // 社区互动头像默认显示「最后一个操作的人」（users 末位 = 最近一次点赞）。\n    final first = users.isEmpty ? BiliMsgUser.empty : users.last;",
    ),
    (
        "    if (users.length == 1) {\n      return MsgAvatar(url: users.first.avatar, mid: users.first.mid, size: 45);\n    }\n    final shown = users.take(4).toList();",
        "    if (users.length == 1) {\n      return MsgAvatar(url: users.last.avatar, mid: users.last.mid, size: 45);\n    }\n    // 最近操作者放左上角（叠放顺序：最新的先画）。\n    final shown = users.reversed.take(4).toList();",
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
