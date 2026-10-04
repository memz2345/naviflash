# tool/patch_msg_open_fallback2.py
#
# 修正版：1) 评论页缓存分支也注入；2) 条目点击兜底用 subject_id 打开视频。
# 用法：python tool/patch_msg_open_fallback2.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

COMMENTS = "lib/screens/bilibili_comments_page.dart"
VIEWS = "lib/widgets/msg_views.dart"

COMMENTS_OLD = """    if (cached != null && DateTime.now().difference(cached.time) < _cacheTtl) {
      _items.addAll(cached.items);
      _nextOffset = cached.nextOffset;
      _isEnd = cached.isEnd;
      _loading = false;
    } else {"""
COMMENTS_NEW = """    if (cached != null && DateTime.now().difference(cached.time) < _cacheTtl) {
      _items.addAll(cached.items);
      _nextOffset = cached.nextOffset;
      _isEnd = cached.isEnd;
      _loading = false;
      // 命中缓存时不会走 _loadFirst，这里补一次直达注入。
      _maybeInjectJump();
    } else {"""

VIEWS_IMPORT_OLD = "import 'package:naviflash/services/bili_uri_router.dart';"
VIEWS_IMPORT_NEW = (
    "import 'package:naviflash/screens/bilibili_video_page.dart';\n"
    "import 'package:naviflash/services/bili_uri_router.dart';\n"
    "import 'package:naviflash/services/bv_av.dart';"
)

VIEWS_HELPER_ANCHOR = "/// 列表分隔用的统一外边距（卡片之间 8，左右 12）。"
VIEWS_HELPER = (
    "/// 打开消息条目指向的内容：优先 native_uri；没有可路由链接时用\n"
    "/// subject_id 当视频 aid 兜底（B 站回复/点赞通知常见）。\n"
    "void openMsgContent(BuildContext context, BiliMsgContent content) {\n"
    "  if (content.nativeUri.isNotEmpty &&\n"
    "      openBiliUri(context, content.nativeUri)) {\n"
    "    return;\n"
    "  }\n"
    "  if (content.subjectId > 0) {\n"
    "    final bvid = BvAv.encode(content.subjectId);\n"
    "    if (bvid != null) openBilibiliVideo(context, bvid: bvid);\n"
    "  }\n"
    "}\n\n"
) + VIEWS_HELPER_ANCHOR

VIEWS_TAP_OLD = """        onTap: content.nativeUri.isEmpty
            ? null
            : () => openBiliUri(context, content.nativeUri),"""
VIEWS_TAP_NEW = """        onTap: (content.nativeUri.isEmpty && content.subjectId <= 0)
            ? null
            : () => openMsgContent(context, content),"""


def patch(path, pairs, replace_all=False):
    full = os.path.join(ROOT, path)
    with io.open(full, "r", encoding="utf-8") as f:
        text = f.read()
    missing = []
    for old, new in pairs:
        if old not in text:
            missing.append(old.strip().splitlines()[0][:80])
            continue
        if replace_all:
            text = text.replace(old, new)
        else:
            text = text.replace(old, new, 1)
    with io.open(full, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    return missing


def main():
    total = 0
    missing = patch(COMMENTS, [(COMMENTS_OLD, COMMENTS_NEW)])
    total += len(missing)
    for m in missing:
        print("MISS %s: %s" % (COMMENTS, m))

    missing = patch(VIEWS, [(VIEWS_IMPORT_OLD, VIEWS_IMPORT_NEW)])
    total += len(missing)
    for m in missing:
        print("MISS %s: %s" % (VIEWS, m))

    missing = patch(VIEWS, [(VIEWS_HELPER_ANCHOR, VIEWS_HELPER)])
    total += len(missing)
    for m in missing:
        print("MISS %s: %s" % (VIEWS, m))

    missing = patch(VIEWS, [(VIEWS_TAP_OLD, VIEWS_TAP_NEW)], replace_all=True)
    total += len(missing)
    for m in missing:
        print("MISS %s: %s" % (VIEWS, m))

    print("missing total: %d" % total)
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
