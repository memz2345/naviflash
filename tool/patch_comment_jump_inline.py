# tool/patch_comment_jump_inline.py
#
# 一次性补丁：消息中心点击回复/@/赞 → 视频页直接加载评论区，
# 目标评论插到列表第一位并闪一下（下拉刷新后注入项消失）。
#   1) bilibili_comments_page.dart：新增 jumpRpid/jumpSubRpid，注入 + 高亮闪烁
#   2) bilibili_video_page.dart：去掉 push 评论详情页，改为把 jump 参数传给
#      评论页 + 自动切到「评论」tab
# 用法：python tool/patch_comment_jump_inline.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

COMMENTS = "lib/screens/bilibili_comments_page.dart"
VIDEO = "lib/screens/bilibili_video_page.dart"

COMMENTS_PATCH = [
    # 1) 新增参数
    (
        "  /// 评论发送成功后的刷新信号（由视频页统一「发评论」FAB 自顶向下驱动）；\n  /// 非空时评论页监听它，count 变化即强制刷新第一页（含新评论与计数）。\n  final ValueNotifier<int>? commentPostedTick;\n\n  const BilibiliCommentsPage({\n    super.key,\n    required this.oid,\n    this.upMid,\n    this.episodeTitle,\n    this.heroTagsDisabled = false,\n    this.currentProgress,\n    this.captureFrame,\n    this.commentPostedTick,\n  });",
        "  /// 评论发送成功后的刷新信号（由视频页统一「发评论」FAB 自顶向下驱动）；\n  /// 非空时评论页监听它，count 变化即强制刷新第一页（含新评论与计数）。\n  final ValueNotifier<int>? commentPostedTick;\n\n  /// 消息中心「回复我的 / @我 / 收到的赞」直达评论：目标主楼 rpid。\n  /// 首次加载后把该评论插到列表第一位并闪一下；下拉刷新后注入项消失。\n  final int? jumpRpid;\n\n  /// 楼中楼 rpid（comment_secondary_id）。\n  final int? jumpSubRpid;\n\n  const BilibiliCommentsPage({\n    super.key,\n    required this.oid,\n    this.upMid,\n    this.episodeTitle,\n    this.heroTagsDisabled = false,\n    this.currentProgress,\n    this.captureFrame,\n    this.commentPostedTick,\n    this.jumpRpid,\n    this.jumpSubRpid,\n  });",
    ),
    # 2) mixin + 闪烁状态
    (
        "class _BilibiliCommentsPageState extends State<BilibiliCommentsPage>\n    with AutomaticKeepAliveClientMixin {",
        "class _BilibiliCommentsPageState extends State<BilibiliCommentsPage>\n    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {",
    ),
    (
        "  // 加载代次：切排序/刷新/换 oid 时自增，使飞行中的旧请求失效，\n  // 避免把旧排序/旧视频的评论追加到当前列表（竞态导致重复/错乱）。\n  int _loadGen = 0;",
        "  // 加载代次：切排序/刷新/换 oid 时自增，使飞行中的旧请求失效，\n  // 避免把旧排序/旧视频的评论追加到当前列表（竞态导致重复/错乱）。\n  int _loadGen = 0;\n\n  // ── 消息中心直达评论：注入的目标评论 + 闪一下高亮 ──\n  /// 已尝试过注入（只注入一次；刷新后不再注入）。\n  bool _jumpInjected = false;\n\n  /// 需要闪烁高亮的 rpid（注入项）。\n  String? _flashRpid;\n  late final AnimationController _flashController = AnimationController(\n    vsync: this,\n    duration: const Duration(milliseconds: 1400),\n  );",
    ),
    # 3) dispose
    (
        "  @override\n  void dispose() {\n    widget.commentPostedTick?.removeListener(_onCommentPostedTick);\n    _scrollController.dispose();\n    super.dispose();\n  }",
        "  @override\n  void dispose() {\n    widget.commentPostedTick?.removeListener(_onCommentPostedTick);\n    _flashController.dispose();\n    _scrollController.dispose();\n    super.dispose();\n  }",
    ),
    # 4) 换 oid 时允许重新注入
    (
        "    if (oldWidget.oid != widget.oid) {\n      _loadFirst(forceRefresh: true);\n    }",
        "    if (oldWidget.oid != widget.oid) {\n      _jumpInjected = false;\n      _flashRpid = null;\n      _loadFirst(forceRefresh: true);\n    }",
    ),
    # 5) _loadFirst 结束注入（并清掉旧的闪烁标记）
    (
        "    _cache['${widget.oid}_$_sort'] = _CachedComments(\n      items: List.of(_items),\n      nextOffset: _nextOffset,\n      isEnd: _isEnd,\n    );\n  }",
        "    _cache['${widget.oid}_$_sort'] = _CachedComments(\n      items: List.of(_items),\n      nextOffset: _nextOffset,\n      isEnd: _isEnd,\n    );\n    // 消息中心直达评论：首次加载后注入目标评论（刷新后失效）。\n    _maybeInjectJump();\n  }\n\n  /// 注入消息中心点进来的目标评论：插到第一位 + 滚动到顶 + 闪一下。\n  /// 只注入一次；下拉刷新会重建列表，注入项随之消失。\n  Future<void> _maybeInjectJump() async {\n    final rpid = widget.jumpRpid;\n    if (rpid == null || rpid <= 0 || _jumpInjected) return;\n    _jumpInjected = true;\n    final comment = await BilibiliCommentService.fetchCommentThread(\n      cid: '${widget.oid}',\n      rpid: '$rpid',\n    );\n    if (!mounted || comment == null) return;\n    setState(() {\n      _items.removeWhere((e) => e.rpid == comment.rpid);\n      _items.insert(0, comment);\n      _flashRpid = comment.rpid;\n    });\n    if (_scrollController.hasClients) {\n      _scrollController.animateTo(\n        0,\n        duration: const Duration(milliseconds: 260),\n        curve: Curves.easeOut,\n      );\n    }\n    _flashController.forward(from: 0);\n  }",
    ),
    # 6) 条目闪烁包装
    (
        "                            final isLast = _isEnd && i == _items.length - 1;\n                            return Padding(\n                              padding:\n                                  EdgeInsets.only(bottom: isLast ? 0 : kCardGap),\n                              child: MorphItem(\n                                selected: false,\n                                isFirst: i == 0,\n                                isLast: isLast,\n                                child: CommentTile(\n                                  comment: _items[i],\n                                  cid: widget.oid.toString(),\n                                  episodeTitle: widget.episodeTitle ?? '',\n                                  isTop: false,\n                                  heroTagsDisabled: widget.heroTagsDisabled,\n                                  onReply: _replyToComment,\n                                ),\n                              ),\n                            );",
        "                            final isLast = _isEnd && i == _items.length - 1;\n                            final item = _items[i];\n                            final tile = MorphItem(\n                              selected: false,\n                              isFirst: i == 0,\n                              isLast: isLast,\n                              child: CommentTile(\n                                comment: item,\n                                cid: widget.oid.toString(),\n                                episodeTitle: widget.episodeTitle ?? '',\n                                isTop: false,\n                                heroTagsDisabled: widget.heroTagsDisabled,\n                                onReply: _replyToComment,\n                              ),\n                            );\n                            return Padding(\n                              padding:\n                                  EdgeInsets.only(bottom: isLast ? 0 : kCardGap),\n                              child: _flashRpid == item.rpid\n                                  ? AnimatedBuilder(\n                                      animation: _flashController,\n                                      builder: (context, child) {\n                                        final alpha =\n                                            (1 - _flashController.value) * 0.35;\n                                        return DecoratedBox(\n                                          decoration: BoxDecoration(\n                                            color: cs.primary.withValues(\n                                              alpha: alpha,\n                                            ),\n                                            borderRadius: BorderRadius.circular(\n                                              12,\n                                            ),\n                                          ),\n                                          child: child,\n                                        );\n                                      },\n                                      child: tile,\n                                    )\n                                  : tile,\n                            );",
    ),
    # 7) 导入评论服务
    (
        "import 'package:naviflash/services/bilibili_video_service.dart';",
        "import 'package:naviflash/services/bilibili_comment_service.dart';\nimport 'package:naviflash/services/bilibili_video_service.dart';",
    ),
]

VIDEO_PATCH = [
    # 1) 去掉 push 评论详情页的逻辑
    (
        "    // 消息中心「回复我的 / @我」直达评论：拉主楼评论并打开评论详情。\n    _maybeJumpToComment(detail);\n  }\n\n  /// 消息中心直达评论：拉取目标主楼评论后 push 评论详情页\n  /// （highlightRpid 定位到具体的楼中楼回复）。\n  Future<void> _maybeJumpToComment(BiliVideoDetail detail) async {\n    final rootId = widget.commentRootId;\n    if (rootId == null || rootId <= 0 || _commentJumped) return;\n    _commentJumped = true;\n    final root = await BilibiliCommentService.fetchCommentThread(\n      cid: '${detail.aid}',\n      rpid: '$rootId',\n    );\n    if (!mounted || root == null) return;\n    pushCommentDetail(\n      context,\n      cid: '${detail.aid}',\n      root: root,\n      episodeTitle: detail.title,\n      highlightRpid: widget.commentSecondaryId?.toString(),\n    );\n  }",
        "  }",
    ),
    # 2) 状态字段：注入标记改为「是否要自动切到评论 tab」
    (
        "  // 消息中心直达评论：只跳一次（详情加载完成后触发）。\n  bool _commentJumped = false;",
        "  /// 消息中心直达评论：评论 tab 的初始下标（0 = 简介/相关，1 = 评论）。\n  int get _initialTabIndex =>\n      (widget.commentRootId ?? 0) > 0 ? 1 : 0;",
    ),
    # 3) 两处 DefaultTabController 加 initialIndex
    (
        "                : DefaultTabController(\n                    length: 2,",
        "                : DefaultTabController(\n                    length: 2,\n                    initialIndex: _initialTabIndex,",
    ),
    (
        "                  : DefaultTabController(\n                      length: 2,",
        "                  : DefaultTabController(\n                      length: 2,\n                      initialIndex: _initialTabIndex,",
    ),
    # 4) 两处评论页传 jump 参数
    (
        "                                          builder: (_) => BilibiliCommentsPage(\n                                            oid: _detail!.aid,\n                                            upMid: _detail!.ownerMid,",
        "                                          builder: (_) => BilibiliCommentsPage(\n                                            oid: _detail!.aid,\n                                            upMid: _detail!.ownerMid,\n                                            jumpRpid: widget.commentRootId,\n                                            jumpSubRpid:\n                                                widget.commentSecondaryId,",
    ),
    (
        "                                  child: BilibiliCommentsPage(\n                                    oid: detail.aid,\n                                    upMid: detail.ownerMid,",
        "                                  child: BilibiliCommentsPage(\n                                    oid: detail.aid,\n                                    upMid: detail.ownerMid,\n                                    jumpRpid: widget.commentRootId,\n                                    jumpSubRpid:\n                                        widget.commentSecondaryId,",
    ),
    # 5) 清掉不再使用的导入
    (
        "import 'package:naviflash/services/bilibili_comment_service.dart';\nimport 'package:naviflash/widgets/comment/comment_composer.dart';\nimport 'package:naviflash/widgets/comment/comment_detail_page.dart';",
        "import 'package:naviflash/widgets/comment/comment_composer.dart';",
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
    for path, pairs in ((COMMENTS, COMMENTS_PATCH), (VIDEO, VIDEO_PATCH)):
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
