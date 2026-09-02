// lib/screens/bilibili_comments_page.dart
//
// 评论区独立 page，横竖屏复用：上拉分页加载评论主列表。
// 参考评论面板（CommentPanel）的富卡片布局：
//   - 顶部「热度 / 时间」排序切换
//   - MorphItem 动态卡片 + 富卡片（CommentTile）：头像/昵称/等级/时间/点赞/
//     正文/配图/楼中楼内联展开，点击进入评论详情页
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_video_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/comment/comment_composer.dart';
import 'package:naviflash/widgets/comment/comment_tile.dart';
import 'package:naviflash/widgets/morph_card.dart';

class BilibiliCommentsPage extends StatefulWidget {
  /// 视频 aid（评论区 oid）。
  final int oid;

  /// UP 主 mid（用于标记 UP 本人评论；不传则不做标记）。
  final int? upMid;

  /// 视频标题（打开楼中楼详情页时展示，可空）。
  final String? episodeTitle;

  /// 整页 Hero（视频页整页放大）包裹期间为 true：头像不挂载 Hero
  /// （避免「Hero 嵌套 Hero」断言）。
  final bool heroTagsDisabled;

  /// 当前播放进度（秒）；供评论发送面板加号「视频进度」插入。
  final double? Function()? currentProgress;

  /// 取当前播放器画面 PNG；供评论发送面板加号「视频截图」。
  final Future<Uint8List?> Function()? captureFrame;

  /// 评论发送成功后的刷新信号（由视频页统一「发评论」FAB 自顶向下驱动）；
  /// 非空时评论页监听它，count 变化即强制刷新第一页（含新评论与计数）。
  final ValueNotifier<int>? commentPostedTick;

  const BilibiliCommentsPage({
    super.key,
    required this.oid,
    this.upMid,
    this.episodeTitle,
    this.heroTagsDisabled = false,
    this.currentProgress,
    this.captureFrame,
    this.commentPostedTick,
  });

  @override
  State<BilibiliCommentsPage> createState() => _BilibiliCommentsPageState();
}

class _BilibiliCommentsPageState extends State<BilibiliCommentsPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final List<BiliComment> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _isEnd = false;
  String? _error;
  String? _nextOffset;
  int _sort = 0; // 0 = 热度，1 = 时间
  // 加载代次：切排序/刷新/换 oid 时自增，使飞行中的旧请求失效，
  // 避免把旧排序/旧视频的评论追加到当前列表（竞态导致重复/错乱）。
  int _loadGen = 0;

  // ── 会话级缓存：跨布局切换（宽屏 ↔ 紧凑）复用同一 oid+sort 的评论，
  //    避免重新拉取浪费流量（首帧直接展示缓存数据）。 ──
  static const Duration _cacheTtl = Duration(minutes: 10);
  static final Map<String, _CachedComments> _cache = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.commentPostedTick?.addListener(_onCommentPostedTick);
    // 布局切换重建 State 时直接复用已缓存评论，不再重新拉取。
    final cached = _cache['${widget.oid}_$_sort'];
    if (cached != null &&
        DateTime.now().difference(cached.time) < _cacheTtl) {
      _items.addAll(cached.items);
      _nextOffset = cached.nextOffset;
      _isEnd = cached.isEnd;
      _loading = false;
    } else {
      _loadFirst();
    }
  }

  @override
  void didUpdateWidget(covariant BilibiliCommentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.oid != widget.oid) {
      _loadFirst(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    widget.commentPostedTick?.removeListener(_onCommentPostedTick);
    _scrollController.dispose();
    super.dispose();
  }

  /// 视频页统一 FAB 发评论成功后 tick+1，此处强制刷新第一页（含新评论与计数）。
  void _onCommentPostedTick() {
    if (mounted) _loadFirst(forceRefresh: true);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_loading || _loadingMore || _isEnd) return;
    if (_nextOffset == null || _nextOffset!.isEmpty) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  void _switchSort(int sort) {
    if (_sort == sort || _loading) return;
    setState(() => _sort = sort);
    _loadFirst(forceRefresh: true);
  }

  Future<void> _loadFirst({bool forceRefresh = false}) async {
    final gen = ++_loadGen;
    setState(() {
      _loading = true;
      _loadingMore = false; // 重置，避免切排序时飞行中的 _loadMore 把旧数据追加进来
      _error = null;
      _items.clear();
      _isEnd = false;
      _nextOffset = null;
    });
    final page = await BilibiliVideoService.fetchReplies(
      oid: widget.oid,
      sort: _sort,
      forceRefresh: forceRefresh,
    );
    // 期间若发生切排序/刷新/换 oid，本次结果作废，不再写入列表
    if (!mounted || gen != _loadGen) return;
    setState(() {
      _loading = false;
      if (page == null) {
        _error = BilibiliVideoService.lastErrorDetail ??
            AppLocalizations.of(context).commentLoadFail;
        return;
      }
      _items.addAll(page.replies);
      _isEnd = page.isEnd ||
          page.nextOffset == null ||
          page.nextOffset!.isEmpty;
      _nextOffset = page.nextOffset;
    });
    _cache['${widget.oid}_$_sort'] = _CachedComments(
      items: List.of(_items),
      nextOffset: _nextOffset,
      isEnd: _isEnd,
    );
  }

  Future<void> _loadMore() async {
    if (_nextOffset == null || _nextOffset!.isEmpty) {
      if (mounted) setState(() => _isEnd = true);
      return;
    }
    final gen = _loadGen;
    setState(() => _loadingMore = true);
    final page = await BilibiliVideoService.fetchReplies(
      oid: widget.oid,
      offset: _nextOffset,
      sort: _sort,
    );
    // 期间若发生切排序/刷新/换 oid，本次结果作废，不再追加。
    // 必须重置 _loadingMore，否则会被卡在 true 导致后续 _loadMore 永远
    // 被 _onScroll 的守卫跳过（_loadFirst 的 setState 理论上会重置，但
    // 若 _loadFirst 的 await 尚未开始 setState，这里直接 return 就漏了）。
    if (!mounted || gen != _loadGen) {
      if (mounted) setState(() => _loadingMore = false);
      return;
    }
    setState(() {
      _loadingMore = false;
      if (page == null) return;
      // 按 rpid 去重：B 站游标分页偶尔返回重叠/重复页（尤其游客态或翻到边界
      // 时），不加去重会在列表里出现同一条评论多次。与 CommentPanel 一致。
      final known = <String>{..._items.map((e) => e.rpid)};
      _items.addAll(page.replies.where((c) => !known.contains(c.rpid)));
      // isEnd 判断必须同时检查 nextOffset 为空——和 CommentPanel 一致。
      // service 层的 isEnd 已含 next.isEmpty 检查，但这里再加一层防御，
      // 避免任何中间环节（如 BiliReplyPage 构造）遗漏。
      _isEnd = page.isEnd ||
          page.nextOffset == null ||
          page.nextOffset!.isEmpty;
      _nextOffset = page.nextOffset;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // ── 排序切换：热度 / 时间 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
          child: Row(
            children: [
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text(AppLocalizations.of(context).commentSortHeat),
                    icon: const Icon(Icons.local_fire_department, size: 16),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text(AppLocalizations.of(context).commentSortTime),
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
            ],
          ),
        ),
        const Divider(height: 12),
        Expanded(
          child: Stack(
            children: [
              RefreshIndicator(
                triggerMode: RefreshIndicatorTriggerMode.onEdge,
                edgeOffset: 0,
                displacement: 40,
                onRefresh: () => _loadFirst(forceRefresh: true),
                color: cs.primary,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (_loading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: LoadingIndicatorM3E()),
                      )
                    else if (_error != null && _items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _errorView(cs),
                      )
                    else if (_items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).commentEmpty,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, i) {
                            if (i >= _items.length) {
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: Center(
                                  child: _isEnd
                                      ? Text(
                                          AppLocalizations
                                              .of(context)
                                              .commentNoMore,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: cs.onSurfaceVariant
                                                .withOpacity(0.6),
                                          ),
                                        )
                                      : const LoadingIndicatorM3E(),
                                ),
                              );
                            }
                            final isLast = _isEnd && i == _items.length - 1;
                            return Padding(
                              padding:
                                  EdgeInsets.only(bottom: isLast ? 0 : kCardGap),
                              child: MorphItem(
                                selected: false,
                                isFirst: i == 0,
                                isLast: isLast,
                                child: CommentTile(
                                  comment: _items[i],
                                  cid: widget.oid.toString(),
                                  episodeTitle: widget.episodeTitle ?? '',
                                  isTop: false,
                                  heroTagsDisabled: widget.heroTagsDisabled,
                                  onReply: _replyToComment,
                                ),
                              ),
                            );
                          }, childCount: _items.length + 1),
                        ),
                      ),
                  ],
                ),
              ),
              // 加载失败重试：右下角 Extended FAB（重新加载）
              if (_error != null && _items.isEmpty)
                PositionedRetryFab(
                  onRetry: () => _loadFirst(forceRefresh: true),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // 「发评论」FAB 已提升到视频页统一 FAB（见 bilibili_video_page._buildSharedFab），
  // 由视频页调用 showCommentComposer 并驱动评论页刷新。

  /// 点评论卡本体 / 回复按钮：以该评论为目标打开面板（楼中楼）；
  /// 发送成功后强制刷新列表（楼中楼计数与预览同步更新）。
  Future<void> _replyToComment(BiliComment comment) async {
    final result = await showCommentComposer(
      context,
      oid: widget.oid,
      replyTo: comment,
      // 回复不支持图片，无需进度/截图回调
      heroTag: kVideoPageCommentHeroTag,
    );
    if (!mounted || !result.sent) return;
    _loadFirst(forceRefresh: true);
  }

  Widget _errorView(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// 评论列表缓存条目（跨布局切换复用）。
class _CachedComments {
  final List<BiliComment> items;
  final String? nextOffset;
  final bool isEnd;
  final DateTime time;
  _CachedComments({
    required this.items,
    required this.nextOffset,
    required this.isEnd,
  }) : time = DateTime.now();
}
