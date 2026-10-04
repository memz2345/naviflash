                                            
                                                  
                            
import 'package:flutter/material.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';

import 'package:naviflash/screens/article_page.dart';
import 'package:naviflash/screens/bilibili_user_space_page_v2.dart';
import 'package:naviflash/services/bilibili_bangumi_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/page_loading.dart';

class BilibiliPgcReviewPage extends StatefulWidget {
  final int mediaId;
  final String title;

  const BilibiliPgcReviewPage({
    super.key,
    required this.mediaId,
    this.title = '',
  });

  @override
  State<BilibiliPgcReviewPage> createState() => _BilibiliPgcReviewPageState();
}

class _BilibiliPgcReviewPageState extends State<BilibiliPgcReviewPage> {
  final GlobalKey<_ReviewTabState> _shortKey = GlobalKey<_ReviewTabState>();

  Future<void> _openPostDialog() async {
    var score = 5;
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('写短评'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => setDlgState(() => score = i),
                        icon: Icon(
                          i <= score ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFC107),
                          size: 26,
                        ),
                      ),
                    const Spacer(),
                    Text('$score 星', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    hintText: '说说你的看法（100 字以内）',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('发布'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final content = controller.text.trim();
    if (content.isEmpty) {
      showAppToast(context, '内容不能为空', error: true);
      return;
    }
    final res = await BilibiliBangumiService.postShortReview(
      mediaId: widget.mediaId,
      score: score,
      content: content,
    );
    if (!mounted) return;
    if (!res.ok) {
      showAppToast(context, res.message, error: true);
      return;
    }
    showAppToast(context, '点评成功');
    _shortKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: cs.surfaceContainer,
        appBar: AppBar(
          title: Text(
            widget.title.isEmpty ? '番剧点评' : '${widget.title} · 点评',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: '长评'),
              Tab(text: '短评'),
            ],
          ),
        ),
        body: Stack(
          children: [
            PageBackground(baseColor: cs.surfaceContainer),
            TabBarView(
              children: [
                _ReviewTab(
                  mediaId: widget.mediaId,
                  long: true,
                ),
                _ReviewTab(
                  key: _shortKey,
                  mediaId: widget.mediaId,
                  long: false,
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openPostDialog,
          icon: const Icon(Icons.rate_review_outlined),
          label: const Text('写短评'),
        ),
      ),
    );
  }
}

class _ReviewTab extends StatefulWidget {
  final int mediaId;
  final bool long;

  const _ReviewTab({super.key, required this.mediaId, required this.long});

  @override
  State<_ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<_ReviewTab> {
  final List<BiliPgcReview> _items = [];
  final ScrollController _scroll = ScrollController();
  String _next = '';
  int _count = 0;
  int _sort = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> reload({bool viaRefresh = false}) async {
    setState(() {
                                        
                                           
      _loading = _items.isEmpty && !viaRefresh;
      _error = null;
    });
    final page = await BilibiliBangumiService.fetchReviews(
      mediaId: widget.mediaId,
      long: widget.long,
      sort: _sort,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (page == null) {
                                      
        if (_items.isEmpty) {
          _error = '点评加载失败';
        } else {
          showAppToast(context, '点评刷新失败，请稍后重试', error: true);
        }
        return;
      }
      _items
        ..clear()
        ..addAll(page.items);
      _next = page.next;
      _count = page.count;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || _next.isEmpty) return;
    setState(() => _loadingMore = true);
    final page = await BilibiliBangumiService.fetchReviews(
      mediaId: widget.mediaId,
      long: widget.long,
      sort: _sort,
      cursor: _next,
    );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (page == null) return;
      final seen = _items.map((e) => e.reviewId).toSet();
      _items.addAll(page.items.where((e) => !seen.contains(e.reviewId)));
      _next = page.next;
      _count = page.count;
    });
  }

  Future<void> _onLike(BiliPgcReview item, bool like) async {
    final res = await BilibiliBangumiService.reviewAction(
      mediaId: widget.mediaId,
      reviewId: item.reviewId,
      like: like,
    );
    if (!mounted) return;
    if (!res.ok) {
      showAppToast(context, res.message, error: true);
      return;
    }
    setState(() {
      final idx = _items.indexWhere((e) => e.reviewId == item.reviewId);
      if (idx < 0) return;
      final old = _items[idx];
      _items[idx] = BiliPgcReview(
        reviewId: old.reviewId,
        articleId: old.articleId,
        authorMid: old.authorMid,
        authorName: old.authorName,
        authorFace: old.authorFace,
        title: old.title,
        content: old.content,
        pushTime: old.pushTime,
        score: old.score,
        likes: like
            ? (old.liked ? old.likes : old.likes + 1)
            : old.likes,
        liked: like ? !old.liked : false,
        disliked: like ? false : !old.disliked,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _items.isEmpty,
    )) {
      return const PageLoadingIndicator();
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            FilledButton(onPressed: reload, child: const Text('重试')),
          ],
        ),
      );
    }
    return AppRefreshIndicator(
      onRefresh: () => reload(viaRefresh: true),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Row(
              children: [
                Text(
                  '$_count 条点评',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _sort = _sort == 0 ? 1 : 0);
                    reload();
                  },
                  child: Text(_sort == 0 ? '默认排序' : '最新排序'),
                ),
              ],
            );
          }
          final item = _items[index - 1];
          return _reviewRow(cs, item);
        },
      ),
    );
  }

  Widget _reviewRow(ColorScheme cs, BiliPgcReview item) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: widget.long && item.articleId > 0
          ? () => Navigator.of(context).push(
                ImmersiveMaterialPageRoute(
                  page: ArticlePage(cvid: item.articleId),
                ),
              )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: item.authorMid > 0
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  BilibiliUserSpacePage(mid: item.authorMid),
                            ),
                          )
                      : null,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.surfaceContainerHighest,
                    backgroundImage: item.authorFace.isEmpty
                        ? null
                        : CachedImageProvider(item.authorFace),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.authorName,
                        style: const TextStyle(fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          for (var i = 1; i <= 5; i++)
                            Icon(
                              i <= item.score
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 12,
                              color: const Color(0xFFFFC107),
                            ),
                          const SizedBox(width: 6),
                          Text(
                            item.pushTime,
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.title.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              item.content,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                InkWell(
                  onTap: () => _onLike(item, true),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.liked
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          size: 15,
                          color: item.liked ? cs.primary : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.likes}',
                          style: TextStyle(
                            fontSize: 11,
                            color: item.liked
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!widget.long)
                  InkWell(
                    onTap: () => _onLike(item, false),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Icon(
                        item.disliked
                            ? Icons.thumb_down
                            : Icons.thumb_down_outlined,
                        size: 15,
                        color: item.disliked
                            ? cs.error
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            Divider(height: 18, color: cs.outlineVariant.withValues(alpha: .5)),
          ],
        ),
      ),
    );
  }
}
