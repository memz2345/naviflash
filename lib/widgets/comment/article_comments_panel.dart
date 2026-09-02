// lib/widgets/comment/article_comments_panel.dart
//
// 通用内嵌评论区面板（横屏右侧栏 / 独立区域复用）：热度/时间排序、游标分页、
// 置顶评论 + MorphItem 动态卡片 + 楼中楼展开。数据走
// BilibiliCommentService.fetchComments。
// 专栏页按默认 commentType '12'（文章），动态详情页传动态的评论区类型。
import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/comment/comment_tile.dart';
import 'package:naviflash/widgets/morph_card.dart';

class ArticleCommentsPanel extends StatefulWidget {
  /// 评论区 oid（视频为 aid、专栏为 cvid、动态为 comment_id_str）。
  final String cid;
  final String episodeTitle;

  final String commentType;

  const ArticleCommentsPanel({
    super.key,
    required this.cid,
    required this.episodeTitle,
    this.commentType = '12',
  });

  @override
  State<ArticleCommentsPanel> createState() => _ArticleCommentsPanelState();
}

class _ArticleCommentsPanelState extends State<ArticleCommentsPanel>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  List<BiliComment> _comments = [];
  List<BiliComment> _topReplies = [];
  String _next = '';
  bool _isEnd = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _allCount = 0;
  int _sort = 0; // 0 = 热度，1 = 时间

  bool get _hasTop => _topReplies.isNotEmpty;

  // 会话级缓存：宽屏 ↔ 紧凑切换重建 State 时直接复用，避免重复拉取
  static const Duration _cacheTtl = Duration(minutes: 10);
  static final Map<String, _CachedArticleComments> _cache = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final cached = _cache['${widget.cid}_${widget.commentType}_$_sort'];
    if (cached != null && DateTime.now().difference(cached.time) < _cacheTtl) {
      _comments = cached.comments;
      _topReplies = cached.topReplies;
      _next = cached.next;
      _isEnd = cached.isEnd;
      _allCount = cached.allCount;
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      // 重置分页状态，防止切换排序时正在飞行的 _loadMore 完成后
      // 把旧排序的评论追加到新列表上（竞态导致重复/错乱）。
      _loadingMore = false;
      _isEnd = false;
      _next = '';
      _comments = [];
      _topReplies = [];
    });
    final page = await BilibiliCommentService.fetchComments(
      cid: widget.cid,
      sort: _sort,
      type: widget.commentType,
    );
    if (!mounted) return;
    if (page == null) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).commentLoadFail;
      });
      return;
    }
    setState(() {
      _comments = page.comments;
      _topReplies = page.topReplies;
      _next = page.next;
      _isEnd = page.isEnd || page.next.isEmpty;
      _allCount = page.allCount;
      _loading = false;
    });
    _cache['${widget.cid}_${widget.commentType}_$_sort'] =
        _CachedArticleComments(
          comments: List.of(_comments),
          topReplies: List.of(_topReplies),
          next: _next,
          isEnd: _isEnd,
          allCount: _allCount,
        );
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _isEnd || _next.isEmpty) return;
    setState(() => _loadingMore = true);
    final page = await BilibiliCommentService.fetchComments(
      cid: widget.cid,
      sort: _sort,
      offset: _next,
      type: widget.commentType,
    );
    if (!mounted) return;
    if (page == null) {
      setState(() => _loadingMore = false);
      showAppToast(
        context,
        AppLocalizations.of(context).commentLoadMoreFail,
        error: true,
      );
      return;
    }
    setState(() {
      // 按 rpid 去重，防止服务端异常返回重复评论。
      // known 必须同时包含普通列表和置顶评论的 rpid——置顶评论可能在
      // 后续页作为普通评论再次返回，导致同一条评论在置顶区和普通区
      // 各显示一次。
      final known = <String>{
        ..._comments.map((e) => e.rpid),
        ..._topReplies.map((e) => e.rpid),
      };
      _comments = [
        ..._comments,
        ...page.comments.where((c) => !known.contains(c.rpid)),
      ];
      _next = page.next;
      _isEnd = page.isEnd || page.next.isEmpty;
      _loadingMore = false;
    });
  }

  void _switchSort(int sort) {
    if (_sort == sort || _loading) return;
    setState(() => _sort = sort);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 头部：标题 + 总数 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
          child: Row(
            children: [
              Icon(Icons.forum_outlined, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.commentPanelTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (_allCount > 0)
                Text(
                  l10n.commentTotalCount(_allCount),
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ),
        // ── 排序切换 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              // 面板较窄（宽屏右栏）时按比例缩小，避免溢出：
              // Expanded 提供有界宽度，FittedBox 才能缩小过宽的分段按钮
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<int>(
                    segments: [
                      ButtonSegment(
                        value: 0,
                        label: Text(l10n.commentSortHeat),
                        icon: const Icon(Icons.local_fire_department, size: 16),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text(l10n.commentSortTime),
                        icon: const Icon(Icons.schedule, size: 16),
                      ),
                    ],
                    selected: {_sort},
                    onSelectionChanged: _loading
                        ? null
                        : (s) => _switchSort(s.first),
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStatePropertyAll(
                        TextStyle(fontSize: 12, color: cs.onSurface),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 12),
        Expanded(child: _buildBody(cs, l10n)),
      ],
    );
  }

  Widget _buildBody(ColorScheme cs, AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: LoadingIndicatorM3E());
    }

    if (_error != null) {
      final detail = BilibiliCommentService.lastErrorDetail;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: cs.onSurface.withOpacity(0.25),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            if (detail != null && detail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.scanRetry),
            ),
          ],
        ),
      );
    }

    if (_comments.isEmpty && !_hasTop) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 56,
              color: cs.onSurface.withOpacity(0.25),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.commentEmpty,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final allCount = _comments.length + (_hasTop ? _topReplies.length : 0);
    return RefreshIndicator(
      onRefresh: _load,
      color: cs.primary,
      child: ListView.builder(
        controller: _scrollController,
        physics: _loading
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
        itemCount: allCount + 1,
        itemBuilder: (context, index) {
          if (index == allCount) {
            return _buildFooter(cs, l10n);
          }
          final BiliComment comment;
          if (_hasTop && index < _topReplies.length) {
            comment = _topReplies[index];
          } else {
            final i = index - (_hasTop ? _topReplies.length : 0);
            comment = _comments[i];
          }
          // 每组 = 一条主楼评论 + 它的楼中楼回复（MorphItem 动态卡片）
          final isFirst = index == 0;
          final isLast = index == allCount - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : kCardGap),
            child: MorphItem(
              selected: false,
              isFirst: isFirst,
              isLast: isLast,
              child: CommentTile(
                comment: comment,
                cid: widget.cid,
                episodeTitle: widget.episodeTitle,
                isTop: _hasTop && index < _topReplies.length,
                commentType: widget.commentType,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs, AppLocalizations l10n) {
    if (_loadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: LoadingIndicatorM3E(
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
          ),
        ),
      );
    }
    if (_isEnd) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            l10n.commentNoMore,
            style: TextStyle(fontSize: 12, color: cs.outline),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          l10n.commentLoadingMore,
          style: TextStyle(fontSize: 12, color: cs.outline),
        ),
      ),
    );
  }
}

/// 评论区缓存条目（跨布局切换复用）。
class _CachedArticleComments {
  final List<BiliComment> comments;
  final List<BiliComment> topReplies;
  final String next;
  final bool isEnd;
  final int allCount;
  final DateTime time;
  _CachedArticleComments({
    required this.comments,
    required this.topReplies,
    required this.next,
    required this.isEnd,
    required this.allCount,
  }) : time = DateTime.now();
}
