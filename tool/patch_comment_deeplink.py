# tool/patch_comment_deeplink.py
#
# 一次性补丁：消息中心「回复我的 / @我」点击直达视频 + 对应评论。
#   1) BiliSubCommentPage 增加 root（主楼评论），并新增 fetchCommentThread
#   2) 视频页 BilibiliVideoPage / openBilibiliVideo 支持 commentRootId / commentSecondaryId
#   3) bili_uri_router 解析 native_uri 里的 comment_root_id / comment_secondary_id
# 用法：python tool/patch_comment_deeplink.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SERVICE = "lib/services/bilibili_comment_service.dart"
VIDEO = "lib/screens/bilibili_video_page.dart"
ROUTER = "lib/services/bili_uri_router.dart"

REPLACEMENTS = {
    SERVICE: [
        # 1) 模型加 root
        (
            "class BiliSubCommentPage {\n  final List<BiliComment> replies;\n  final bool isEnd;\n  final int total;\n\n  const BiliSubCommentPage({\n    required this.replies,\n    required this.isEnd,\n    required this.total,\n  });\n}",
            "class BiliSubCommentPage {\n  final List<BiliComment> replies;\n  final bool isEnd;\n  final int total;\n\n  /// 主楼评论（`/x/v2/reply/reply` 的 data.root）：\n  /// 消息中心「回复我的 / @我」直达评论时用来定位主楼。\n  final BiliComment? root;\n\n  const BiliSubCommentPage({\n    required this.replies,\n    required this.isEnd,\n    required this.total,\n    this.root,\n  });\n}",
        ),
        # 2) fetchSubComments 返回 root
        (
            "      return BiliSubCommentPage(\n        replies: (data['replies'] as List<dynamic>? ?? [])\n            .whereType<Map<String, dynamic>>()\n            .map(BiliComment.fromJson)\n            .toList(),\n        isEnd: _asBool(pageJson?['is_end']),\n        total: (pageJson?['count'] as num?)?.toInt() ?? 0,\n      );",
            "      final rootJson = data['root'];\n      return BiliSubCommentPage(\n        replies: (data['replies'] as List<dynamic>? ?? [])\n            .whereType<Map<String, dynamic>>()\n            .map(BiliComment.fromJson)\n            .toList(),\n        isEnd: _asBool(pageJson?['is_end']),\n        total: (pageJson?['count'] as num?)?.toInt() ?? 0,\n        root: rootJson is Map<String, dynamic>\n            ? BiliComment.fromJson(rootJson)\n            : null,\n      );",
        ),
        # 3) 新增按 rpid 取主楼评论
        (
            "  /// 楼中楼（二级回复）分页拉取。\n  static Future<BiliSubCommentPage?> fetchSubComments({",
            "  /// 按 rpid 拉取主楼评论（消息中心「回复我的 / @我」直达评论用）。\n  /// 走 `/x/v2/reply/reply?root=<rpid>`：data.root 即主楼评论。\n  static Future<BiliComment?> fetchCommentThread({\n    required String cid,\n    required String rpid,\n    String type = '1',\n  }) async {\n    final page = await fetchSubComments(\n      cid: cid,\n      root: rpid,\n      type: type,\n    );\n    if (page == null) return null;\n    final root = page.root;\n    if (root != null) return root;\n    for (final r in page.replies) {\n      if (r.rpid == rpid) return r;\n    }\n    return null;\n  }\n\n  /// 楼中楼（二级回复）分页拉取。\n  static Future<BiliSubCommentPage?> fetchSubComments({",
        ),
    ],
    VIDEO: [
        # 1) 导入评论详情页
        (
            "import 'package:naviflash/widgets/comment/comment_composer.dart';",
            "import 'package:naviflash/services/bilibili_comment_service.dart';\nimport 'package:naviflash/widgets/comment/comment_composer.dart';\nimport 'package:naviflash/widgets/comment/comment_detail_page.dart';",
        ),
        # 2) openBilibiliVideo 参数
        (
            "  String? heroTag,\n  Duration? initialPosition,\n  bool wideClassic = false,\n}) {\n  // 推入视频页前收起虚拟键盘并清除焦点",
            "  String? heroTag,\n  Duration? initialPosition,\n  bool wideClassic = false,\n  int? commentRootId,\n  int? commentSecondaryId,\n}) {\n  // 推入视频页前收起虚拟键盘并清除焦点",
        ),
        (
            "  final page = BilibiliVideoPage(\n    bvid: bvid,\n    initialTitle: initialTitle,\n    initialCover: initialCover,\n    heroTag: heroTag,\n    initialPosition: initialPosition,\n    wideClassic: wideClassic,\n  );",
            "  final page = BilibiliVideoPage(\n    bvid: bvid,\n    initialTitle: initialTitle,\n    initialCover: initialCover,\n    heroTag: heroTag,\n    initialPosition: initialPosition,\n    wideClassic: wideClassic,\n    commentRootId: commentRootId,\n    commentSecondaryId: commentSecondaryId,\n  );",
        ),
        # 3) BilibiliVideoPage 字段 + 构造
        (
            "  /// 宽屏经典模式：推荐视频入口在宽屏下使用标准封面 Hero 转场\n  /// （无整页 Hero 放大、无毛玻璃模糊）；**仅宽屏生效** ——\n  /// 竖屏推荐视频与搜索页等入口一样保留 iOS 整页放大 + 模糊动画。\n  final bool wideClassic;\n\n  const BilibiliVideoPage({\n    super.key,\n    required this.bvid,\n    this.initialTitle,\n    this.initialCover,\n    this.heroTag,\n    this.initialPosition,\n    this.wideClassic = false,\n  });",
            "  /// 宽屏经典模式：推荐视频入口在宽屏下使用标准封面 Hero 转场\n  /// （无整页 Hero 放大、无毛玻璃模糊）；**仅宽屏生效** ——\n  /// 竖屏推荐视频与搜索页等入口一样保留 iOS 整页放大 + 模糊动画。\n  final bool wideClassic;\n\n  /// 消息中心直达评论：主楼 rpid（`bilibili://video/<aid>?comment_root_id=…`）。\n  final int? commentRootId;\n\n  /// 楼中楼 rpid（`comment_secondary_id`）：定位并高亮该条回复。\n  final int? commentSecondaryId;\n\n  const BilibiliVideoPage({\n    super.key,\n    required this.bvid,\n    this.initialTitle,\n    this.initialCover,\n    this.heroTag,\n    this.initialPosition,\n    this.wideClassic = false,\n    this.commentRootId,\n    this.commentSecondaryId,\n  });",
        ),
        # 4) state 字段
        (
            "  // UP 主粉丝数 / 投稿数：view 接口的 owner 不含这些字段（恒为 0），\n  // 详情加载后异步用 card 接口补充（见 _loadOwnerStats）。",
            "  // 消息中心直达评论：只跳一次（详情加载完成后触发）。\n  bool _commentJumped = false;\n\n  // UP 主粉丝数 / 投稿数：view 接口的 owner 不含这些字段（恒为 0），\n  // 详情加载后异步用 card 接口补充（见 _loadOwnerStats）。",
        ),
        # 5) 详情加载完成后触发跳转
        (
            "    // AI 翻译标题/简介（异步，翻译完成后刷新标题显示）\n    _translateDetail(detail);\n  }",
            "    // AI 翻译标题/简介（异步，翻译完成后刷新标题显示）\n    _translateDetail(detail);\n    // 消息中心「回复我的 / @我」直达评论：拉主楼评论并打开评论详情。\n    _maybeJumpToComment(detail);\n  }\n\n  /// 消息中心直达评论：拉取目标主楼评论后 push 评论详情页\n  /// （highlightRpid 定位到具体的楼中楼回复）。\n  Future<void> _maybeJumpToComment(BiliVideoDetail detail) async {\n    final rootId = widget.commentRootId;\n    if (rootId == null || rootId <= 0 || _commentJumped) return;\n    _commentJumped = true;\n    final root = await BilibiliCommentService.fetchCommentThread(\n      cid: '${detail.aid}',\n      rpid: '$rootId',\n    );\n    if (!mounted || root == null) return;\n    pushCommentDetail(\n      context,\n      cid: '${detail.aid}',\n      root: root,\n      episodeTitle: detail.title,\n      highlightRpid: widget.commentSecondaryId?.toString(),\n    );\n  }",
        ),
    ],
    ROUTER: [
        # bilibili://video/<aid>?...comment_root_id=…
        (
            "      case 'video':\n        final aid = int.tryParse(tail.replaceAll(RegExp(r'[^0-9]'), ''));\n        final bvid = aid == null ? null : BvAv.encode(aid);\n        if (bvid == null) return false;\n        openBilibiliVideo(context, bvid: bvid);\n        return true;",
            "      case 'video':\n        final aid = int.tryParse(tail.replaceAll(RegExp(r'[^0-9]'), ''));\n        final bvid = aid == null ? null : BvAv.encode(aid);\n        if (bvid == null) return false;\n        final query = Uri.tryParse(raw)?.queryParameters ?? const {};\n        openBilibiliVideo(\n          context,\n          bvid: bvid,\n          commentRootId: int.tryParse(query['comment_root_id'] ?? ''),\n          commentSecondaryId: int.tryParse(\n            query['comment_secondary_id'] ?? '',\n          ),\n        );\n        return true;",
        ),
        # H5 视频链接同样解析评论参数
        (
            "    final bvMatch = RegExp(r'/video/(BV[0-9A-Za-z]{10})').firstMatch(path);\n    if (bvMatch != null) {\n      openBilibiliVideo(context, bvid: bvMatch.group(1)!);\n      return true;\n    }",
            "    final bvMatch = RegExp(r'/video/(BV[0-9A-Za-z]{10})').firstMatch(path);\n    if (bvMatch != null) {\n      final query = parsed?.queryParameters ?? const {};\n      openBilibiliVideo(\n        context,\n        bvid: bvMatch.group(1)!,\n        commentRootId: int.tryParse(query['comment_root_id'] ?? ''),\n        commentSecondaryId: int.tryParse(query['comment_secondary_id'] ?? ''),\n      );\n      return true;\n    }",
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
