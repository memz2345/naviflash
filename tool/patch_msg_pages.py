# tool/patch_msg_pages.py
#
# 一次性补丁：消息相关页面改用 MsgPageScaffold（热门页同款毛玻璃顶栏）
# + 私信未读接口换成 BilibiliImService.fetchUnread()。
# 显式 UTF-8，逐条精确替换，未命中的会打印出来。
# 用法：python tool/patch_msg_pages.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

REPLACEMENTS = {
    "lib/screens/msg_feed_list_page.dart": [
        (
            "return Scaffold(\n      appBar: AppBar(title: Text(widget.title)),",
            "return MsgPageScaffold(\n      title: widget.title,",
        ),
        ("      body: _buildBody(cs),\n    );", "      child: _buildBody(cs),\n    );"),
    ],
    "lib/screens/msg_like_me_page.dart": [
        (
            "return Scaffold(\n      appBar: AppBar(title: Text(AppLocalizations.of(context).msgLikedMe)),",
            "return MsgPageScaffold(\n      title: AppLocalizations.of(context).msgLikedMe,",
        ),
        ("      body: _buildBody(cs),\n    );", "      child: _buildBody(cs),\n    );"),
    ],
    "lib/screens/msg_like_detail_page.dart": [
        (
            "return Scaffold(\n      appBar: AppBar(\n        title: Text(AppLocalizations.of(context).msgLikeDetailTitle),\n      ),",
            "return MsgPageScaffold(\n      title: AppLocalizations.of(context).msgLikeDetailTitle,",
        ),
        ("      body: _buildBody(cs),\n    );", "      child: _buildBody(cs),\n    );"),
    ],
    "lib/screens/message_center_page.dart": [
        (
            "return Scaffold(\n      appBar: AppBar(title: Text(AppLocalizations.of(context).msgCenterTitle)),\n      body: !BilibiliMsgService.canUse",
            "return MsgPageScaffold(\n      title: AppLocalizations.of(context).msgCenterTitle,\n      child: !BilibiliMsgService.canUse",
        ),
        (
            "    final im = await BilibiliImService.fetchTotalUnread();",
            "    final im = await BilibiliImService.fetchUnread();",
        ),
        (
            "      final data = im.data;\n      if (data != null && data.hasSessionSingleUnread()) {\n        _whisperUnread =\n            data.sessionSingleUnread.unfollowUnread.toInt() +\n            data.sessionSingleUnread.followUnread.toInt();\n      }",
            "      _whisperUnread = im.unread.total;",
        ),
    ],
    "lib/widgets/message_center_entry.dart": [
        (
            "    final im = await BilibiliImService.fetchTotalUnread();\n    if (!mounted) return;\n    var count = feed.unread.total;\n    final data = im.data;\n    if (data != null && data.hasSessionSingleUnread()) {\n      count +=\n          data.sessionSingleUnread.unfollowUnread.toInt() +\n          data.sessionSingleUnread.followUnread.toInt();\n    }\n    setState(() => _unread = count);",
            "    final im = await BilibiliImService.fetchUnread();\n    if (!mounted) return;\n    setState(() => _unread = feed.unread.total + im.unread.total);",
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
    total_missing = 0
    for path, pairs in REPLACEMENTS.items():
        missing = apply(path, pairs)
        if missing:
            total_missing += len(missing)
            print("MISS %s:" % path)
            for m in missing:
                print("   - %s" % m)
        else:
            print("ok   %s" % path)
    print("missing total: %d" % total_missing)
    return 1 if total_missing else 0


if __name__ == "__main__":
    sys.exit(main())
