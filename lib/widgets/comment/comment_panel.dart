                                         
  
                                              
                  
                                   

import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/comment/comment_tile.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

            
                                          
Future<void> showCommentPanel(
  BuildContext context, {
  required String cid,
  required String episodeTitle,
  String commentType = '1',
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommentPanel(
      cid: cid,
      episodeTitle: episodeTitle,
      commentType: commentType,
    ),
  );
}

class CommentPanel extends StatefulWidget {
  final String cid;
  final String episodeTitle;
  final String commentType;

  const CommentPanel({
    super.key,
    required this.cid,
    required this.episodeTitle,
    this.commentType = '1',
  });

  @override
  State<CommentPanel> createState() => _CommentPanelState();
}

class _CommentPanelState extends State<CommentPanel> {
  final ScrollController _scrollController = ScrollController();

  List<BiliComment> _comments = [];
  List<BiliComment> _topReplies = [];
  String _next = '';
  bool _isEnd = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _allCount = 0;
  int _sort = 0;                 

                                        
     
                                         
                                               
                                                
                          
  int _loadEpoch = 0;

                                          
           
  int _moreEmptyStreak = 0;

                          
  bool _moreScheduled = false;

  bool get _hasTop => _topReplies.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
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

  Future<void> _load({bool viaRefresh = false}) async {
    final epoch = ++_loadEpoch;
    setState(() {
                                        
                                                
      _loading = _comments.isEmpty && !viaRefresh;
      _error = null;
                                          
                                   
      _loadingMore = false;
      _isEnd = false;
      _next = '';
      _moreEmptyStreak = 0;
    });
    final page = await BilibiliCommentService.fetchComments(
      cid: widget.cid,
      sort: _sort,
      type: widget.commentType,
    );
                                  
    if (!mounted || epoch != _loadEpoch) return;
    if (page == null) {
      setState(() {
        _loading = false;
                                      
        if (_comments.isEmpty) {
          _error = AppLocalizations.of(context).commentLoadFail;
        } else {
          showAppToast(
            context,
            AppLocalizations.of(context).commentLoadFail,
            error: true,
          );
        }
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
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _isEnd || _next.isEmpty) return;
    final epoch = _loadEpoch;
    final cursor = _next;
    setState(() => _loadingMore = true);
    final page = await BilibiliCommentService.fetchComments(
      cid: widget.cid,
      sort: _sort,
      offset: cursor,
      type: widget.commentType,
    );
                                       
    if (!mounted || epoch != _loadEpoch) return;
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
                                 
                                             
                                      
               
      final known = <String>{
        ..._comments.map((e) => e.rpid),
        ..._topReplies.map((e) => e.rpid),
      };
      final fresh = page.comments
          .where((c) => !known.contains(c.rpid))
          .toList();
      _comments = [..._comments, ...fresh];
      _next = page.next;
                                          
                                
                                        
                        
      if (page.next == cursor) {
        _isEnd = true;
      } else if (fresh.isEmpty) {
        _moreEmptyStreak++;
        if (_moreEmptyStreak >= 2) _isEnd = true;
      } else {
        _moreEmptyStreak = 0;
      }
      _isEnd = _isEnd || page.isEnd || page.next.isEmpty;
      _loadingMore = false;
    });
  }

               
     
                                               
                                                 
                                               
  void _scheduleLoadMore() {
    if (_moreScheduled ||
        _isEnd ||
        _loading ||
        _loadingMore ||
        _next.isEmpty) {
      return;
    }
    _moreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _moreScheduled = false;
      if (!mounted) return;
      _loadMore();
    });
  }

  void _switchSort(int sort) {
    if (_sort == sort || _loading) return;
    setState(() => _sort = sort);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      child: FrostedSheet(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          height: maxHeight,
          color: Colors.transparent,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                         
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
                            
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
              child: Row(
                children: [
                  Icon(Icons.forum_outlined, color: cs.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.commentPanelTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (_allCount > 0)
                    Text(
                      l10n.commentTotalCount(_allCount),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l10n.scanClose,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
                         
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
              child: Text(
                widget.episodeTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
                         
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
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
            const Divider(height: 12),
                          
            Expanded(child: _buildBody(cs, l10n)),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs, AppLocalizations l10n) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingIndicatorM3E(),
            const SizedBox(height: 14),
            Text(
              l10n.commentLoading,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
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
              color: cs.onSurface.withValues(alpha: 0.25),
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
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
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
              color: cs.onSurface.withValues(alpha: 0.25),
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
    return AppRefreshIndicator(
      onRefresh: () => _load(viaRefresh: true),
      color: cs.primary,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AppRefreshScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
                                              
                               
    _scheduleLoadMore();
    return InkWell(
      onTap: _loadMore,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            l10n.commentLoadingMore,
            style: TextStyle(fontSize: 12, color: cs.outline),
          ),
        ),
      ),
    );
  }
}

