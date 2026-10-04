                                        
  
                                                
                                        
                               
import 'package:flutter/material.dart';

import '../tts_install_prompt.dart';
import '../../screens/tts_install_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/services/tts_model_service.dart';
import 'package:naviflash/services/tts_speech_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/app_tooltip.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/search_video_menu.dart' show GlassMenuAction;
import 'package:naviflash/widgets/fans_medal_badge.dart';
import 'package:naviflash/widgets/fan_decorate_card.dart';
import 'package:naviflash/widgets/pendant_avatar.dart';
import 'package:naviflash/widgets/user_level_icon.dart';
import 'comment_content.dart';
import 'comment_detail_page.dart';
import 'comment_dialogue_sheet.dart';
import 'comment_menu.dart';
import 'comment_translate.dart';
import 'tap_avatar_hero.dart';
import '../morph_card.dart';

                          
class CommentTile extends StatefulWidget {
  final BiliComment comment;
  final String cid;
  final String episodeTitle;
  final bool isTop;
  final String commentType;

                                           
                           
  final bool heroTagsDisabled;

  final ValueChanged<BiliComment>? onReply;

  const CommentTile({
    super.key,
    required this.comment,
    required this.cid,
    required this.episodeTitle,
    required this.isTop,
    this.commentType = '1',
    this.heroTagsDisabled = false,
    this.onReply,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _expanded = false;        
  bool _subExpanded = false;         
  bool _subLoading = false;
  bool _subError = false;
  List<BiliComment> _subReplies = [];
  int _subPage = 1;
  bool _subIsEnd = false;
  int _subTotal = 0;

                                     
  String? _translated;
  bool _translating = false;

                                            
  bool _liked = false;
  bool _disliked = false;
  int _likeCount = 0;
  bool _voting = false;

  BiliComment get _c => widget.comment;

                                      
                          
  bool get _translateAvailable => BilibiliTranslateService.enabledOrFalse;

  @override
  void initState() {
    super.initState();
    _syncFromComment();
  }

  @override
  void didUpdateWidget(covariant CommentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
                                     
    if (oldWidget.comment.rpid != _c.rpid) {
      _expanded = false;
      _syncFromComment();
    }
  }

                          
  void _syncFromComment() {
    _liked = _c.action == 1;
    _disliked = _c.action == 2;
    _likeCount = _c.like;
                              
    _translated = CommentTranslateCache.of(_c.rpid);
  }

                                        
            
  Future<void> _toggleLike() async {
    if (_voting) return;
    final want = !_liked;
    setState(() {
      _voting = true;
      _liked = want;
      _likeCount = (_likeCount + (want ? 1 : -1)).clamp(0, 1 << 30).toInt();
      if (want) _disliked = false;
    });
    final r = await BilibiliCommentService.likeComment(
      oid: _c.oid,
      rpid: _c.rpid,
      like: want,
      type: widget.commentType,
    );
    if (!mounted) return;
    setState(() {
      _voting = false;
      if (!r.ok) {
        _liked = !want;
        _likeCount = (_likeCount + (want ? -1 : 1)).clamp(0, 1 << 30).toInt();
      }
    });
    if (!r.ok) showAppToast(context, r.message, error: true);
  }

                                            
  Future<void> _toggleDislike() async {
    if (_voting) return;
    final want = !_disliked;
    setState(() {
      _voting = true;
      _disliked = want;
      if (want && _liked) {
                 
        _liked = false;
        _likeCount = (_likeCount - 1).clamp(0, 1 << 30).toInt();
      }
    });
    final r = await BilibiliCommentService.dislikeComment(
      oid: _c.oid,
      rpid: _c.rpid,
      dislike: want,
      type: widget.commentType,
    );
    if (!mounted) return;
    setState(() {
      _voting = false;
      if (!r.ok) _disliked = !want;
    });
    if (!r.ok) showAppToast(context, r.message, error: true);
  }

  Future<void> _toggleTranslate() async {
    if (_translating) return;
    if (_translated != null) {
      CommentTranslateCache.forget(_c.rpid);
      setState(() => _translated = null);
      return;
    }
    setState(() => _translating = true);
    final t = await fetchCommentTranslation(
      context,
      oid: int.tryParse(_c.oid) ?? 0,
      type: int.tryParse(widget.commentType) ?? 1,
      rpid: int.tryParse(_c.rpid) ?? 0,
      original: _c.message,
    );
    if (!mounted) return;
                         
    if (t != null) CommentTranslateCache.remember(_c.rpid, t);
    setState(() {
      _translating = false;
      _translated = t;
    });
  }

                    
  String get _speakId => 'comment_${_c.rpid}';

                     
  Future<void> _speak() async {
    final l10n = AppLocalizations.of(context);
    if (_c.message.trim().isEmpty) return;
    try {
      await TtsSpeechService.instance.speak(_speakId, _c.message);
    } on TtsModelException catch (_) {
      if (!mounted) return;
                                                
      if (await promptTtsNotInstalled(context, l10n)) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TtsInstallScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, l10n.ttsSpeakFailed('$e'), error: true);
    }
  }

  String _formatTime(int ts, AppLocalizations l10n) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final now = DateTime.now();
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    String two(int n) => n.toString().padLeft(2, '0');
    if (sameDay) {
      return '${two(dt.hour)}:${two(dt.minute)}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;
    if (isYesterday) {
      return '${l10n.commentYesterday} ${two(dt.hour)}:${two(dt.minute)}';
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

  String get _subHint {
    if (_subReplies.isNotEmpty) {
      return _subIsEnd
          ? '${_subReplies.length}'
          : '${_subReplies.length} / $_subTotal';
    }
    return '$_subTotal';
  }

  Future<void> _toggleSubReplies(AppLocalizations l10n) async {
    if (_subExpanded) {
      setState(() => _subExpanded = false);
      return;
    }
    setState(() {
      _subExpanded = true;
      _subLoading = _subReplies.isEmpty;
      _subError = false;
    });
    if (_subReplies.isNotEmpty) return;
    final result = await BilibiliCommentService.fetchSubCommentsSkipEmpty(
      cid: widget.cid,
      root: _c.rpid,
      page: 1,
      type: widget.commentType,
    );
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _subLoading = false;
        _subError = true;
      });
      return;
    }
    final page = result.page;
    setState(() {
      _subLoading = false;
      _subReplies = page.replies;
      _subPage = result.fetchedPage;
      _subIsEnd = page.isEnd || page.replies.isEmpty;
      _subTotal = page.total;
    });
  }

                                
                                          
                          
                                        
  Future<void> _openDetail([BiliComment? target]) async {
                    
    HapticFeedback.lightImpact();
    if (!_subExpanded && _c.count > 0) {
      await _toggleSubReplies(AppLocalizations.of(context));
    }
    if (!mounted) return;
    pushCommentDetail(
      context,
      cid: widget.cid,
      root: _c,
      episodeTitle: widget.episodeTitle,
      highlightRpid: target?.rpid,
      commentType: widget.commentType,
    );
  }

  Future<void> _loadMoreSubs() async {
    if (_subLoading || _subIsEnd) return;
    setState(() => _subLoading = true);
    final result = await BilibiliCommentService.fetchSubCommentsSkipEmpty(
      cid: widget.cid,
      root: _c.rpid,
      page: _subPage + 1,
      type: widget.commentType,
    );
    if (!mounted) return;
    if (result == null) {
      setState(() => _subLoading = false);
      showAppToast(
        context,
        AppLocalizations.of(context).commentLoadMoreFail,
        error: true,
      );
      return;
    }
    final page = result.page;
    setState(() {
      _subPage = result.fetchedPage;
                                  
      final known = _subReplies.map((e) => e.rpid).toSet();
      _subReplies = [
        ..._subReplies,
        ...page.replies.where((c) => !known.contains(c.rpid)),
      ];
      _subIsEnd = page.isEnd || page.replies.isEmpty;
      _subTotal = page.total;
      _subLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final member = _c.member;
    final isVip = member.vipStatus > 0 && member.vipType == 2;

                                              
                               
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(kItemPressedRadius),
        onTap: () {
          HapticFeedback.lightImpact();
          if (widget.onReply != null) widget.onReply!(_c);
        },
        onLongPress: () =>
            showCommentActionsSheet(context, copyText: _translated ?? _c.message),
        onSecondaryTapDown: (details) => showCommentTextMenu(
          context,
          copyText: _translated ?? _c.message,
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
                        _buildAvatar(cs, member, isVip: isVip),
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
                                    _formatTime(_c.ctime, l10n),
                                    style: TextStyle(
                                      fontSize: 11,
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
                padding: const EdgeInsets.only(left: 44),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isTop)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          l10n.commentPinned,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    _c.message.isEmpty
                        ? Text(
                            l10n.commentDeleted,
                            style: TextStyle(
                              fontSize: 13,
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
                                message: _c.message,
                                emotes: _c.emotes,
                                maxLines: _expanded ? null : 4,
                                overflow:
                                    _expanded ? null : TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: cs.onSurface,
                                ),
                              ),
                                  
                    CommentPictures(pictures: _c.pictures),
                                       
                    if (_c.message.length > 60)
                      GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _expanded
                                ? l10n.commentCollapse
                                : l10n.commentExpand,
                            style: TextStyle(fontSize: 12, color: cs.primary),
                          ),
                        ),
                      ),
                                            
                                                               
                                                     
                                                        
                                                       
                    if (_c.message.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                                                           
                                                    
                                                                    
                                                         
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    _formatTime(_c.ctime, l10n),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                if (_c.location.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _c.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                                if (widget.onReply != null) ...[
                                  const SizedBox(width: 12),
                                  _ReplyTextButton(
                                    text: l10n.commentReply,
                                    onTap: () => widget.onReply!(_c),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CommentVoteButton(
                            icon: _liked
                                ? Icons.thumb_up_alt
                                : Icons.thumb_up_alt_outlined,
                            active: _liked,
                            tooltip: l10n.commentLikeTooltip,
                            label: _likeCount > 0
                                ? _formatCount(_likeCount, l10n)
                                : null,
                            onTap: _toggleLike,
                          ),
                          const SizedBox(width: 14),
                          _CommentVoteButton(
                            icon: _disliked
                                ? Icons.thumb_down_alt
                                : Icons.thumb_down_alt_outlined,
                            active: _disliked,
                            tooltip: l10n.commentDislikeTooltip,
                            onTap: _toggleDislike,
                          ),
                          if (!_expanded && _translateAvailable) ...[
                            const SizedBox(width: 14),
                            CommentTranslateIconButton(
                              active: _translated != null,
                              translating: _translating,
                              onTap: _toggleTranslate,
                            ),
                          ],
                          const SizedBox(width: 6),
                          CommentMoreMenuButton(
                            copyText: _translated ?? _c.message,
                            speakId: _speakId,
                            onSpeak: _speak,
                            onTranslate: _translateAvailable
                                ? _toggleTranslate
                                : null,
                            translating: _translating,
                            translated: _translated != null,
                          ),
                        ],
                      ),
                    ],
                                
                    if (_c.count > 0) _buildSubReplies(cs, l10n),
                  ],
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(
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
      heroTag: widget.heroTagsDisabled ? null : 'bili_space_avatar_$mid',
      avatar: avatarWidget,
      onTap: () async {
        HapticFeedback.lightImpact();
        await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => BilibiliUserSpacePage(mid: mid)),
        );
      },
    );
  }

  Widget _buildSubReplies(ColorScheme cs, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: cs.onInverseSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(kItemRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_subExpanded)
            InkWell(
              borderRadius: BorderRadius.circular(kItemRadius),
              onTap: _openDetail,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 13,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      l10n.commentSubCount(_c.count),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                                           
                    GestureDetector(
                      onTap: () => _toggleSubReplies(l10n),
                      child: AppTooltip(
                        message: l10n.commentExpand,
                        triggerMode: TooltipTriggerMode.longPress,
                        child: Icon(
                          Icons.expand_more,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final sub in _subReplies)
                    SubReplyRow(
                      sub: sub,
                      commentType: widget.commentType,
                      root: _c,
                      cid: widget.cid,
                      onTap: () => _openDetail(sub),
                    ),
                  if (_subLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: LoadingIndicatorM3E(
                          constraints: const BoxConstraints.tightFor(
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    )
                  else if (_subError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () => _toggleSubReplies(l10n),
                          icon: const Icon(Icons.refresh, size: 15),
                          label: Text(l10n.scanRetry),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    )
                  else if (!_subIsEnd)
                    TextButton(
                      onPressed: _loadMoreSubs,
                      child: Text(
                        l10n.commentSubLoadMore(_subHint),
                        style: TextStyle(fontSize: 12, color: cs.primary),
                      ),
                    )
                  else if (_subReplies.length < _subTotal)
                    TextButton(
                      onPressed: _loadMoreSubs,
                      child: Text(
                        l10n.commentSubLoadMore(_subHint),
                        style: TextStyle(fontSize: 12, color: cs.primary),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

          
class SubReplyRow extends StatefulWidget {
  final BiliComment sub;
  final VoidCallback? onTap;

                                        
  final BiliComment? root;

                              
  final String cid;

                                 
  final String commentType;

  const SubReplyRow({
    super.key,
    required this.sub,
    this.onTap,
    this.root,
    this.cid = '',
    this.commentType = '1',
  });

  @override
  State<SubReplyRow> createState() => _SubReplyRowState();
}

class _SubReplyRowState extends State<SubReplyRow> {
  BiliComment get _sub => widget.sub;

                                           
  bool get _hasDialogue =>
      widget.root != null &&
      _sub.parent.isNotEmpty &&
      _sub.parent != '0' &&
      _sub.parent != _sub.root;

                            
  void _openDialogue() {
    HapticFeedback.lightImpact();
    showCommentDialogueSheet(
      context,
      cid: widget.cid,
      root: widget.root!,
      reply: _sub,
      commentType: widget.commentType,
    );
  }

                                
  String? _translated;
  bool _translating = false;

  @override
  void initState() {
    super.initState();
                             
    _translated = CommentTranslateCache.of(_sub.rpid);
  }

  Future<void> _toggleTranslate() async {
    if (_translating) return;
    if (_translated != null) {
      CommentTranslateCache.forget(_sub.rpid);
      setState(() => _translated = null);
      return;
    }
    setState(() => _translating = true);
    final t = await fetchCommentTranslation(
      context,
      oid: int.tryParse(_sub.oid) ?? 0,
      type: int.tryParse(widget.commentType) ?? 1,
      rpid: int.tryParse(_sub.rpid) ?? 0,
      original: _sub.message,
    );
    if (!mounted) return;
    if (t != null) CommentTranslateCache.remember(_sub.rpid, t);
    setState(() {
      _translating = false;
      _translated = t;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayText = _translated ?? _sub.message;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.onTap,
        onLongPress: () => showCommentActionsSheet(
          context,
          copyText: '${_sub.member.uname}: ${_translated ?? _sub.message}',
        ),
        onSecondaryTapDown: (details) => showCommentTextMenu(
          context,
          copyText: '${_sub.member.uname}: ${_translated ?? _sub.message}',
          globalPosition: details.globalPosition,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
                                          
                                             
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${_sub.member.uname}: ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                          ...buildCommentSpans(
                            message: displayText,
                            emotes: _translated == null
                                ? _sub.emotes
                                : const {},
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: cs.onSurface.withValues(alpha: 0.85),
                            ),
                            context: context,
                          ),
                        ],
                      ),
                      maxLines: _translated == null ? 2 : null,
                      overflow: _translated == null
                          ? TextOverflow.ellipsis
                          : TextOverflow.visible,
                    ),
                  ),
                  if (_sub.message.isNotEmpty &&
                      BilibiliTranslateService.enabledOrFalse)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 1),
                      child: CommentTranslateIconButton(
                        active: _translated != null,
                        translating: _translating,
                        onTap: _toggleTranslate,
                      ),
                    ),
                ],
              ),
                                             
              if (_sub.location.isNotEmpty || _hasDialogue) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (_sub.location.isNotEmpty)
                      Flexible(
                        child: Text(
                          _sub.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (_hasDialogue) ...[
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openDialogue,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 2,
                          ),
                          child: Text(
                            AppLocalizations.of(context).commentViewDialogue,
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

                                      
class _ReplyTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _ReplyTextButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

                                          
class _CommentVoteButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String? label;
  final String? tooltip;
  final VoidCallback onTap;

  const _CommentVoteButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.label,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = active ? cs.primary : cs.onSurfaceVariant;
    final child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(label!, style: TextStyle(fontSize: 11, color: color)),
          ],
        ],
      ),
    );
    if (tooltip == null) return child;
    return AppTooltip(message: tooltip!, child: child);
  }
}

                                
   
                                       
                                    
class CommentMoreMenuButton extends StatelessWidget {
  final String copyText;
  final String speakId;
  final VoidCallback onSpeak;
  final VoidCallback? onTranslate;
  final bool translating;
  final bool translated;

  const CommentMoreMenuButton({
    super.key,
    required this.copyText,
    required this.speakId,
    required this.onSpeak,
    this.onTranslate,
    this.translating = false,
    this.translated = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: TtsSpeechService.instance,
      builder: (context, _) {
        final svc = TtsSpeechService.instance;
        final speaking = svc.isActive(speakId);
        final l10n = AppLocalizations.of(context);
        return LiquidGlassMenuButton(
          icon: Icons.more_vert,
          tooltip: l10n.playerMoreTooltip,
          useMorphStyle: false,
          iconColor: cs.onSurfaceVariant,
          size: 28,
          iconSize: 16,
          menuWidth: 190,
          actions: [
            GlassMenuAction(
              icon: speaking
                  ? Icons.stop_circle_outlined
                  : Icons.record_voice_over_outlined,
              text: speaking ? l10n.ttsReadAloudStop : l10n.ttsReadAloud,
              onTap: onSpeak,
            ),
            if (onTranslate != null)
              GlassMenuAction(
                icon: Icons.translate,
                text: translated
                    ? l10n.commentTranslateRestore
                    : l10n.commentTranslate,
                isEnabled: !translating,
                onTap: onTranslate!,
              ),
            GlassMenuAction(
              icon: Icons.copy,
              text: l10n.commentMenuCopy,
              onTap: () => copyCommentText(context, copyText),
            ),
          ],
        );
      },
    );
  }
}
