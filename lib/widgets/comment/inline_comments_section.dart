                                                   
  
                                
                                                
                                        
                                                      
  
                                                        
                               
import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/comment/comment_tile.dart';
import 'package:naviflash/widgets/morph_card.dart';

class InlineCommentsSection extends StatefulWidget {
                                           
  final String cid;

                             
  final String commentType;

  const InlineCommentsSection({
    super.key,
    required this.cid,
    required this.commentType,
  });

  @override
  State<InlineCommentsSection> createState() => InlineCommentsSectionState();
}

class InlineCommentsSectionState extends State<InlineCommentsSection> {
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

  bool get _hasTop => _topReplies.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    final epoch = ++_loadEpoch;
    setState(() {
      _loading = true;
      _error = null;
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
    if (!mounted || epoch != _loadEpoch) return;
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
  }

                                    
  Future<void> maybeLoadMore() async {
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
          .where((c) => known.add(c.rpid))
          .toList();
      _comments = [..._comments, ...fresh];
      _next = page.next;
      _isEnd = page.isEnd ||
          page.next.isEmpty ||
          page.next == cursor ||
          fresh.isEmpty;
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
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: LoadingIndicatorM3E()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(_error!, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.scanRetry),
            ),
          ],
        ),
      );
    }

    final total = _comments.length + _topReplies.length;
    final footer = _buildFooter(cs, l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                                  
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
          child: Row(
            children: [
              Text(
                _allCount > 0
                    ? l10n.commentTotalCount(_allCount)
                    : l10n.commentPanelTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text(l10n.commentSortHeat),
                    icon: const Icon(Icons.local_fire_department, size: 15),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text(l10n.commentSortTime),
                    icon: const Icon(Icons.schedule, size: 15),
                  ),
                ],
                selected: {_sort},
                onSelectionChanged:
                    _loading ? null : (s) => _switchSort(s.first),
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
       ),
        const SizedBox(height: 8),
        if (total == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              l10n.commentEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          )
        else
          for (var index = 0; index < total; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: kCardGap),
              child: MorphItem(
                selected: false,
                isFirst: index == 0,
                isLast: index == total - 1,
                child: Builder(builder: (context) {
                  final BiliComment comment;
                  if (_hasTop && index < _topReplies.length) {
                    comment = _topReplies[index];
                  } else {
                    comment =
                        _comments[index - (_hasTop ? _topReplies.length : 0)];
                  }
                  return CommentTile(
                    comment: comment,
                    cid: widget.cid,
                    episodeTitle: '',
                    isTop: _hasTop && index < _topReplies.length,
                    commentType: widget.commentType,
                  );
                }),
              ),
            ),
        footer,
      ],
    );
  }

  Widget _buildFooter(ColorScheme cs, AppLocalizations l10n) {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: LoadingIndicatorM3E(
            constraints: BoxConstraints.tightFor(width: 24, height: 24),
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
                      
    return InkWell(
      onTap: maybeLoadMore,
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
