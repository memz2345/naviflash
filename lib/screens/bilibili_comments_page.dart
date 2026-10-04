                                          
  
                                
                              
                      
                                                        
                              

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/services/bilibili_video_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/comment/comment_composer.dart';
import 'package:naviflash/widgets/comment/comment_tile.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/ugc_selection_area.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/page_loading.dart';

class BilibiliCommentsPage extends StatefulWidget {
                      
  final int oid;

                                     
  final int? upMid;

                           
  final String? episodeTitle;

                                           
                           
  final bool heroTagsDisabled;

                                  
  final double? Function()? currentProgress;

                                   
  final Future<Uint8List?> Function()? captureFrame;

                                          
                                          
  final ValueNotifier<int>? commentPostedTick;

                                           
                                      
  final int? jumpRpid;

                                     
  final int? jumpSubRpid;

  const BilibiliCommentsPage({
    super.key,
    required this.oid,
    this.upMid,
    this.episodeTitle,
    this.heroTagsDisabled = false,
    this.currentProgress,
    this.captureFrame,
    this.commentPostedTick,
    this.jumpRpid,
    this.jumpSubRpid,
  });

  @override
  State<BilibiliCommentsPage> createState() => _BilibiliCommentsPageState();
}

class _BilibiliCommentsPageState extends State<BilibiliCommentsPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final List<BiliComment> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _isEnd = false;
  String? _error;
  String? _nextOffset;
  int _sort = 0;                 
                                      
                                     
  int _loadGen = 0;

                                   
                            
  bool _jumpInjected = false;

                        
  String? _flashRpid;

             
     
                                                          
                                                
                                                                
                                                     
                                           
                                                             
  late final AnimationController _flashController;

                                              
                                  
  static const Duration _cacheTtl = Duration(minutes: 10);
  static final Map<String, _CachedComments> _cache = {};

                                           
                              
  double? _pendingRestoreOffset;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
                                                      
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scrollController.addListener(_onScroll);
    widget.commentPostedTick?.addListener(_onCommentPostedTick);
                                      
    final cached = _cache['${widget.oid}_$_sort'];
    if (cached != null && DateTime.now().difference(cached.time) < _cacheTtl) {
      _items.addAll(cached.items);
      _nextOffset = cached.nextOffset;
      _isEnd = cached.isEnd;
      _loading = false;
                              
      _pendingRestoreOffset = cached.scrollOffset;
      _scheduleRestoreScroll();
                                       
      _maybeInjectJump();
    } else {
      _loadFirst();
    }
  }

                                     
                        
  void _scheduleRestoreScroll() {
    final target = _pendingRestoreOffset;
    if (target == null || target <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingRestoreOffset == null) return;
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (max <= 0) return;
      final clamped = target.clamp(0.0, max);
      if ((_scrollController.offset - clamped).abs() > 1) {
        _scrollController.jumpTo(clamped);
      }
      if (max >= target - 1 || _isEnd) {
        _pendingRestoreOffset = null;
      }
    });
  }

                            
  void _saveScrollOffsetToCache() {
    if (!_scrollController.hasClients) return;
    final cached = _cache['${widget.oid}_$_sort'];
    if (cached != null) {
      cached.scrollOffset = _scrollController.offset;
    }
  }

  @override
  void didUpdateWidget(covariant BilibiliCommentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.oid != widget.oid) {
      _jumpInjected = false;
      _flashRpid = null;
      _loadFirst(forceRefresh: true);
    }
  }

  @override
  void dispose() {
                                         
    _saveScrollOffsetToCache();
    widget.commentPostedTick?.removeListener(_onCommentPostedTick);
    _flashController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

                                                 
  void _onCommentPostedTick() {
    if (mounted) _loadFirst(forceRefresh: true, viaRefresh: true);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    _saveScrollOffsetToCache();
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
                                          
    _loadFirst(forceRefresh: true, viaRefresh: _items.isNotEmpty);
  }

                                      
                                          
                                              
  Future<void> _loadFirst({
    bool forceRefresh = false,
    bool viaRefresh = false,
  }) async {
    final gen = ++_loadGen;
    setState(() {
      _loading = !viaRefresh;
      _loadingMore = false;                                    
      _error = null;
      if (!viaRefresh) _items.clear();
      _isEnd = false;
      _nextOffset = null;
    });
    final page = await BilibiliVideoService.fetchReplies(
      oid: widget.oid,
      sort: _sort,
      forceRefresh: forceRefresh,
    );
                                      
    if (!mounted || gen != _loadGen) return;
    setState(() {
      _loading = false;
      if (page == null) {
        _error =
            BilibiliVideoService.lastErrorDetail ??
            AppLocalizations.of(context).commentLoadFail;
        return;
      }
                                  
      if (viaRefresh) _items.clear();
      _items.addAll(page.replies);
      _isEnd =
          page.isEnd || page.nextOffset == null || page.nextOffset!.isEmpty;
      _nextOffset = page.nextOffset;
    });
    _cache['${widget.oid}_$_sort'] = _CachedComments(
      items: List.of(_items),
      nextOffset: _nextOffset,
      isEnd: _isEnd,
    );
                                   
    _maybeInjectJump();
                               
    _scheduleRestoreScroll();
  }

                                        
                              
  Future<void> _maybeInjectJump() async {
    final rpid = widget.jumpRpid;
    if (rpid == null || rpid <= 0 || _jumpInjected) return;
    _jumpInjected = true;
    final comment = await BilibiliCommentService.fetchCommentThread(
      cid: '${widget.oid}',
      rpid: '$rpid',
    );
    if (!mounted || comment == null) return;
    setState(() {
      _items.removeWhere((e) => e.rpid == comment.rpid);
      _items.insert(0, comment);
      _flashRpid = comment.rpid;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
    _flashController.forward(from: 0);
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
                                     
                                                      
                                                       
                                                           
    if (!mounted || gen != _loadGen) {
      if (mounted) setState(() => _loadingMore = false);
      return;
    }
    setState(() {
      _loadingMore = false;
      if (page == null) return;
                                               
                                                 
      final known = <String>{..._items.map((e) => e.rpid)};
      _items.addAll(page.replies.where((c) => !known.contains(c.rpid)));
                                                         
                                                       
                                        
      _isEnd =
          page.isEnd || page.nextOffset == null || page.nextOffset!.isEmpty;
      _nextOffset = page.nextOffset;
    });
                                      
                      
    _saveCacheAfterLoad();
    _scheduleRestoreScroll();
  }

                          
  void _saveCacheAfterLoad() {
    final offset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    _cache['${widget.oid}_$_sort'] = _CachedComments(
      items: List.of(_items),
      nextOffset: _nextOffset,
      isEnd: _isEnd,
    )..scrollOffset = offset;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
                                                
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 6, 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _sort == 1
                    ? AppLocalizations.of(context).commentSortLatestDesc
                    : AppLocalizations.of(context).commentSortHottestDesc,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              TextButton.icon(
                style: const ButtonStyle(
                  visualDensity: VisualDensity(horizontal: -2, vertical: -1.25),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _loading
                    ? null
                    : () => _switchSort(_sort == 1 ? 0 : 1),
                icon: Icon(Icons.sort, size: 16, color: cs.secondary),
                label: Text(
                  _sort == 1
                      ? AppLocalizations.of(context).commentSortLatestShort
                      : AppLocalizations.of(context).commentSortHottestShort,
                  style: TextStyle(fontSize: 13, color: cs.secondary),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 12),
        Expanded(
          child: Stack(
            children: [
              AppRefreshIndicator(
                triggerMode: RefreshIndicatorTriggerMode.onEdge,
                edgeOffset: 0,
                displacement: 40,
                onRefresh: () =>
                    _loadFirst(forceRefresh: true, viaRefresh: true),
                color: cs.primary,
                                                 
                                                      
                                                
                                             
                child: Builder(
                  builder: (context) {
                    final scrollView = CustomScrollView(
                      controller: _scrollController,
                      physics: const AppRefreshScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        if (shouldShowFullScreenLoading(
                          loading: _loading,
                          isEmpty: _items.isEmpty,
                        ))
                          const PageLoadingSliver()
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
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
                                  if (i >= _items.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Center(
                                        child: _isEnd
                                            ? Text(
                                                AppLocalizations.of(
                                                  context,
                                                ).commentNoMore,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: cs.onSurfaceVariant
                                                      .withValues(alpha: 0.6),
                                                ),
                                              )
                                            : const LoadingIndicatorM3E(),
                                      ),
                                    );
                                  }
                                  final isLast =
                                      _isEnd && i == _items.length - 1;
                                  final item = _items[i];
                                  final tile = MorphItem(
                                    selected: false,
                                    isFirst: i == 0,
                                    isLast: isLast,
                                    child: CommentTile(
                                      comment: item,
                                      cid: widget.oid.toString(),
                                      episodeTitle: widget.episodeTitle ?? '',
                                      isTop: false,
                                      heroTagsDisabled: widget.heroTagsDisabled,
                                      onReply: _replyToComment,
                                    ),
                                  );
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: isLast ? 0 : kCardGap,
                                    ),
                                    child: _flashRpid == item.rpid
                                        ? AnimatedBuilder(
                                            animation: _flashController,
                                            builder: (context, child) {
                                              final alpha =
                                                  (1 - _flashController.value) *
                                                  0.35;
                                              return DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: cs.primary.withValues(
                                                    alpha: alpha,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: child,
                                              );
                                            },
                                            child: tile,
                                          )
                                        : tile,
                                  );
                                },
                                                               
                                childCount: _items.length + 1,
                                addAutomaticKeepAlives: false,
                              ),
                            ),
                          ),
                      ],
                    );
                    if (!UgcSelectionArea.enabled) return scrollView;
                    return UgcSelectionArea(child: scrollView);
                  },
                ),
              ),
                                              
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

                                                                   
                                         

                                     
                                
  Future<void> _replyToComment(BiliComment comment) async {
    final result = await showCommentComposer(
      context,
      oid: widget.oid,
      replyTo: comment,
                          
      heroTag: kVideoPageCommentHeroTag,
      sourceTitle: widget.episodeTitle,
    );
    if (!mounted || !result.sent) return;
                                          
    _loadFirst(forceRefresh: true, viaRefresh: _items.isNotEmpty);
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

                      
class _CachedComments {
  final List<BiliComment> items;
  final String? nextOffset;
  final bool isEnd;
  final DateTime time;

                                
  double scrollOffset = 0;

  _CachedComments({
    required this.items,
    required this.nextOffset,
    required this.isEnd,
  }) : time = DateTime.now();
}
