                                               
  
                                     
                                 
                                                         
                                                
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/comment/comment_composer.dart';
import 'package:naviflash/widgets/comment/comment_composer_fab.dart';
import 'package:naviflash/widgets/comment/comment_content.dart';
import 'package:naviflash/widgets/comment/comment_dialogue_sheet.dart';
import 'package:naviflash/widgets/comment/comment_menu.dart';
import 'package:naviflash/widgets/comment/comment_translate.dart';
import 'package:naviflash/widgets/comment/tap_avatar_hero.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/fans_medal_badge.dart';
import 'package:naviflash/widgets/fan_decorate_card.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/pendant_avatar.dart';
import 'package:naviflash/widgets/user_level_icon.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/widgets/page_loading.dart';

            
                                            
                    
void pushCommentDetail(
  BuildContext context, {
  required String cid,
  required BiliComment root,
  required String episodeTitle,
  String? highlightRpid,
  String commentType = '1',
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CommentDetailPage(
        cid: cid,
        root: root,
        episodeTitle: episodeTitle,
        highlightRpid: highlightRpid,
        commentType: commentType,
      ),
    ),
  );
}

class CommentDetailPage extends StatefulWidget {
  final String cid;
  final BiliComment root;
  final String episodeTitle;
  final String? highlightRpid;
  final String commentType;

  const CommentDetailPage({
    super.key,
    required this.cid,
    required this.root,
    required this.episodeTitle,
    this.highlightRpid,
    this.commentType = '1',
  });

  @override
  State<CommentDetailPage> createState() => _CommentDetailPageState();
}

class _CommentDetailPageState extends State<CommentDetailPage> {
  final ScrollController _scrollController = ScrollController();

                                          
                                          
                                  
  final Object _composerHeroTag = UniqueKey();

  List<BiliComment> _replies = [];
  int _page = 1;
  bool _isEnd = false;
  bool _loading = true;
  bool _loadingMore = false;
  int _total = 0;

                 
  final Map<String, bool> _liked = {};
  final Map<String, int> _likeCounts = {};

                             
                                   
  late final Object? _highlightToken = widget.highlightRpid == null
      ? null
      : Object();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
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

                                 
  void _ensureHighlightLoaded() {
    final target = widget.highlightRpid;
    if (target == null || _isEnd || _loading || _loadingMore) return;
    if (_replies.any((r) => r.rpid == target)) return;
    _loadMore();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final page = await BilibiliCommentService.fetchSubComments(
      cid: widget.cid,
      root: widget.root.rpid,
      page: 1,
      type: widget.commentType,
    );
    if (!mounted) return;
    if (page == null) {
      setState(() {
        _loading = false;
        _isEnd = true;
      });
      return;
    }
    setState(() {
      _replies = page.replies;
      _isEnd = page.isEnd;
                                                 
      _total = page.total > 0
          ? page.total
          : (widget.root.rcount > 0 ? widget.root.rcount : widget.root.count);
      _loading = false;
    });
    _ensureHighlightLoaded();
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _isEnd) return;
    setState(() => _loadingMore = true);
    final result = await BilibiliCommentService.fetchSubCommentsSkipEmpty(
      cid: widget.cid,
      root: widget.root.rpid,
      page: _page + 1,
      type: widget.commentType,
    );
    if (!mounted) return;
    if (result == null) {
      setState(() => _loadingMore = false);
      return;
    }
    final page = result.page;
    setState(() {
      _page = result.fetchedPage;
                                  
      final known = _replies.map((e) => e.rpid).toSet();
      _replies = [
        ..._replies,
        ...page.replies.where((c) => !known.contains(c.rpid)),
      ];
                                      
      _isEnd = page.isEnd || page.replies.isEmpty;
                              
      if (page.total > 0) _total = page.total;
      _loadingMore = false;
    });
    _ensureHighlightLoaded();
  }

                                          
        
                                          

  bool _isLiked(BiliComment c) => _liked[c.rpid] ?? false;
  int _likeCountOf(BiliComment c) => _likeCounts[c.rpid] ?? c.like;

  Future<void> _toggleLike(BiliComment c) async {
                    
    HapticFeedback.lightImpact();
    if (!BilibiliCommentService.canInteract) {
      showAppToast(
        context,
        AppLocalizations.of(context).commentLikeLoginRequired,
      );
      return;
    }
    final wasLiked = _isLiked(c);
    final prevCount = _likeCountOf(c);
    final target = !wasLiked;
    setState(() {
      _liked[c.rpid] = target;
      _likeCounts[c.rpid] = prevCount + (target ? 1 : -1);
    });
    final result = await BilibiliCommentService.likeComment(
      oid: widget.cid,
      rpid: c.rpid,
      like: target,
      type: widget.commentType,
    );
    if (!mounted) return;
    if (result.ok) return;
    setState(() {
      _liked[c.rpid] = wasLiked;
      _likeCounts[c.rpid] = prevCount;
    });
    showAppToast(
      context,
      AppLocalizations.of(context).commentLikeFail(result.message),
    );
  }

                                          
        
                                          

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              ExpressiveSliverAppBar(
                title: AppLocalizations.of(context).commentDetailTitle,
                leading: MorphIconButton(
                  icon: Icons.arrow_back,
                  tooltip: l10n.homeBack,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              if (shouldShowFullScreenLoading(
                loading: _loading,
                isEmpty: _replies.isEmpty,
              ))
                const PageLoadingSliver()
              else if (_replies.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 56,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.commentDetailEmpty,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index == 0) {
                                                            
                                                   
                        final isLast = _isEnd && _replies.isEmpty;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: isLast ? 0 : kCardGap,
                          ),
                          child: MorphItem(
                            selected: false,
                            isFirst: true,
                            isLast: isLast,
                            child: _DetailCommentCard(
                              comment: widget.root,
                              isRoot: true,
                              liked: _isLiked(widget.root),
                              likeCount: _likeCountOf(widget.root),
                              onLikeTap: () => _toggleLike(widget.root),
                              onReply: (_) => _openComposer(),
                              oid: int.tryParse(widget.cid) ?? 0,
                              type: int.tryParse(widget.commentType) ?? 1,
                            ),
                          ),
                        );
                      }
                      final i = index - 1;
                      if (i == _replies.length) {
                        return _buildFooter();
                      }
                      final reply = _replies[i];
                      final isLast = _isEnd && i == _replies.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : kCardGap),
                        child: MorphItem(
                          selected: false,
                          isFirst: false,
                          isLast: isLast,
                                                      
                          flashToken: reply.rpid == widget.highlightRpid
                              ? _highlightToken
                              : null,
                          child: _DetailCommentCard(
                            comment: reply,
                            isRoot: false,
                            liked: _isLiked(reply),
                            likeCount: _likeCountOf(reply),
                            onLikeTap: () => _toggleLike(reply),
                            onReply: _replyToCard,
                            oid: int.tryParse(widget.cid) ?? 0,
                            type: int.tryParse(widget.commentType) ?? 1,
                            rootComment: widget.root,
                            dialogueSeed: () => {
                              for (final r in _replies) r.rpid: r,
                            },
                          ),
                        ),
                      );
                    }, childCount: _replies.length + 2),
                  ),
                ),
            ],
          ),
                                             
                                                             
                                                         
                                                     
                                                      
          Positioned(
            right: 16,
                                         
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: CommentComposerFab(
              heroTag: _composerHeroTag,
              icon: Icons.reply,
              label: l10n.commentComposerFabReply,
              labelVisible: ModalRoute.of(context)?.isCurrent ?? true,
              onPressed: _openComposer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          _isEnd
              ? l10n.commentDetailNoMore(_total)
              : l10n.commentDetailLoadMore,
          style: TextStyle(fontSize: 12, color: cs.outline),
        ),
      ),
    );
  }

                                     
  Future<void> _openComposer() async {
    final result = await showCommentComposer(
      context,
      oid: int.tryParse(widget.cid) ?? 0,
      replyTo: widget.root,
      type: int.tryParse(widget.commentType) ?? 1,
      heroTag: _composerHeroTag,
      sourceTitle: widget.episodeTitle,
      sourceId: widget.cid,
    );
    if (!mounted || !result.sent) return;
    if (result.comment != null) {
      setState(() {
        _replies.add(result.comment!);
        _total += 1;
      });
    }
                                  
  }

                                          
                       
  Future<void> _replyToCard(BiliComment comment) async {
    final result = await showCommentComposer(
      context,
      oid: int.tryParse(widget.cid) ?? 0,
      replyTo: comment,
      type: int.tryParse(widget.commentType) ?? 1,
      heroTag: _composerHeroTag,
      sourceTitle: widget.episodeTitle,
      sourceId: widget.cid,
    );
    if (!mounted || !result.sent) return;
    if (result.comment != null) {
      setState(() {
        _replies.add(result.comment!);
        _total += 1;
      });
    }
  }
}

                                            
                   
                                            

class _DetailCommentCard extends StatefulWidget {
  final BiliComment comment;
  final bool isRoot;
  final bool liked;
  final int likeCount;
  final VoidCallback onLikeTap;

                                             
  final ValueChanged<BiliComment>? onReply;

                               
  final int oid;

                        
  final int type;

                                    
               
  final BiliComment? rootComment;

                                    
  final Map<String, BiliComment> Function()? dialogueSeed;

  const _DetailCommentCard({
    required this.comment,
    required this.isRoot,
    required this.liked,
    required this.likeCount,
    required this.onLikeTap,
    this.onReply,
    this.oid = 0,
    this.type = 1,
    this.rootComment,
    this.dialogueSeed,
  });

  @override
  State<_DetailCommentCard> createState() => _DetailCommentCardState();
}

class _DetailCommentCardState extends State<_DetailCommentCard> {
  BiliComment get _c => widget.comment;

                           
  bool get _hasDialogue =>
      !widget.isRoot &&
      widget.rootComment != null &&
      _c.parent.isNotEmpty &&
      _c.parent != '0' &&
      _c.parent != _c.root;

                
  void _openDialogue() {
    HapticFeedback.lightImpact();
    showCommentDialogueSheet(
      context,
      cid: '${widget.oid}',
      root: widget.rootComment!,
      reply: _c,
      commentType: '${widget.type}',
      seed: widget.dialogueSeed?.call() ?? const {},
    );
  }

                             
  String? _translated;
  bool _translating = false;

  Future<void> _toggleTranslate() async {
    if (_translating) return;
    if (_translated != null) {
      setState(() => _translated = null);
      return;
    }
    setState(() => _translating = true);
    final t = await fetchCommentTranslation(
      context,
      oid: widget.oid,
      type: widget.type,
      rpid: int.tryParse(_c.rpid) ?? 0,
      original: _c.message,
    );
    if (!mounted) return;
    setState(() {
      _translating = false;
      _translated = t;
    });
  }

  String _formatTime(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${two(dt.hour)}:${two(dt.minute)}';
    }
    if (dt.year == now.year) {
      return '${two(dt.month)}-${two(dt.day)}';
    }
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
  }

  String _formatCount(int n, AppLocalizations l10n) {
    if (n >= 10000) {
      final w = n / 10000;
      return '${w.toStringAsFixed(w >= 100 ? 0 : 1)}${l10n.tenThousandUnit}';
    }
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final comment = _c;
    final member = comment.member;
    final isVip = member.vipStatus > 0 && member.vipType == 2;
    final isRoot = widget.isRoot;
    final liked = widget.liked;
    final likeCount = widget.likeCount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(kItemPressedRadius),
                                           
        onTap: () {
          HapticFeedback.lightImpact();
          if (widget.onReply != null) widget.onReply!(comment);
        },
                                      
        onLongPress: () =>
            showCommentActionsSheet(context, copyText: _translated ?? comment.message),
        onSecondaryTapDown: (details) => showCommentTextMenu(
          context,
          copyText: _translated ?? comment.message,
          globalPosition: details.globalPosition,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                                                   
                                  
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      right: member.fanDecorate != null ? 104 : 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAvatar(context, cs, member, isVip: isVip),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Text(
                                      member.uname,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isVip
                                            ? const Color(0xFFFB7299)
                                            : cs.onSurface,
                                      ),
                                    ),
                                  ),
                                                             
                                                                            
                                  Flexible(
                                    flex: 2,
                                    fit: FlexFit.loose,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(width: 6),
                                          if (isVip)
                                            const Icon(
                                              Icons.workspace_premium,
                                              size: 14,
                                              color: Color(0xFFFB7299),
                                            ),
                                          if (member.officialType >= 0) ...[
                                            const SizedBox(width: 3),
                                            Icon(
                                              Icons.verified,
                                              size: 13,
                                              color: member.officialType == 1
                                                  ? const Color(0xFF23ADE5)
                                                  : cs.secondary,
                                            ),
                                          ],
                                          if (isRoot) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 5,
                                                vertical: 1,
                                              ),
                                              decoration: BoxDecoration(
                                                color: cs.primary
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                l10n.commentDetailRootBadge,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: cs.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(width: 6),
                                                                           
                                          buildUserLevel(
                                            member.level,
                                            isSeniorMember:
                                                member.isSeniorMember,
                                          ),
                                                                            
                                          if (member.fansDetail
                                              case final fansDetail?) ...[
                                            const SizedBox(width: 6),
                                            FansMedalBadge(
                                              detail: fansDetail,
                                              fontSize: 9,
                                              showNumber: false,
                                            ),
                                          ],
                                                                                   
                                                                            
                                          if (member.nameplate
                                              case final plate?) ...[
                                            const SizedBox(width: 6),
                                            NameplateBadge(
                                                plate: plate, height: 16),
                                          ] else if (member.digitalItem
                                              case final di?) ...[
                                            const SizedBox(width: 6),
                                            DigitalItemBadge(item: di, height: 16),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    _formatTime(comment.ctime),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  if (comment.location.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        comment.location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                                                      
                  if (member.fanDecorate case final decorate?)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: FanDecorateCornerCard(decorate: decorate),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 46),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    comment.message.isEmpty
                        ? Text(
                            l10n.commentDetailDeleted,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: cs.onSurfaceVariant,
                            ),
                          )
                        : _translated != null
                                                      
                        ? Text(
                            _translated!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: cs.onSurface,
                            ),
                          )
                        : CommentMessageText(
                            message: comment.message,
                            emotes: comment.emotes,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: cs.onSurface,
                            ),
                          ),
                                  
                    CommentPictures(pictures: comment.pictures),
                                                               
                    if (comment.message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onReply != null) ...[
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => widget.onReply!(comment),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 4,
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline,
                                  size: 15,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
                          if (_hasDialogue)
                            Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _openDialogue,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    l10n.commentViewDialogue,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: widget.onLikeTap,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    liked
                                        ? Icons.thumb_up_alt
                                        : Icons.thumb_up_alt_outlined,
                                    size: 15,
                                    color: liked
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatCount(likeCount, l10n),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: liked
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          CommentTranslateIconButton(
                            active: _translated != null,
                            translating: _translating,
                            onTap: _toggleTranslate,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    ColorScheme cs,
    BiliCommentMember member, {
    required bool isVip,
  }) {
    final avatarWidget = PendantAvatar(
      size: 36,
      avatarUrl: BilibiliCommentService.avatarUrl(member.avatar),
      pendantUrl: member.pendantImage,
      badge: isVip
          ? SvgPicture.asset('assets/bili_icons/vip.svg', width: 17, height: 17)
          : null,
      fallback: Icon(Icons.person, size: 22, color: cs.onSurfaceVariant),
    );
                                             
                                                 
                                          
    final mid = int.tryParse(member.mid) ?? 0;
    if (mid <= 0) return avatarWidget;
    return TapAvatarHero(
      heroTag: 'bili_space_avatar_$mid',
      avatar: avatarWidget,
      onTap: () async {
        HapticFeedback.lightImpact();
        await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => BilibiliUserSpacePage(mid: mid)),
        );
      },
    );
  }
}
