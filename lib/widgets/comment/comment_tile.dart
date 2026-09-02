// lib/widgets/comment/comment_tile.dart
//
// 富评论区卡片（从 CommentPanel 抽出，供评论面板 / 视频播放页评论区复用）：
//   - 头像 / 昵称 / 等级 / 时间 / 点赞数 / 正文 / 配图
//   - 楼中楼内联展开（分页加载）+ 点击跳转评论详情页
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/fans_medal_badge.dart';
import 'package:naviflash/widgets/pendant_avatar.dart';
import 'package:naviflash/widgets/user_level_icon.dart';
import 'comment_content.dart';
import 'comment_detail_page.dart';
import 'comment_menu.dart';
import 'comment_translate.dart';
import 'tap_avatar_hero.dart';
import '../morph_card.dart';

/// 富评论区卡片：主楼评论 + 楼中楼内联展开。
class CommentTile extends StatefulWidget {
  final BiliComment comment;
  final String cid;
  final String episodeTitle;
  final bool isTop;
  final String commentType;

  /// 整页 Hero（视频页整页放大）包裹期间为 true：头像不挂载 Hero
  /// （避免「Hero 嵌套 Hero」断言）。
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
  bool _expanded = false; // 正文展开
  bool _subExpanded = false; // 楼中楼展开
  bool _subLoading = false;
  bool _subError = false;
  List<BiliComment> _subReplies = [];
  int _subPage = 1;
  bool _subIsEnd = false;
  int _subTotal = 0;

  // ── 主楼评论翻译：有译文时正文替换显示，再点图标恢复原文 ──
  String? _translated;
  bool _translating = false;

  BiliComment get _c => widget.comment;

  Future<void> _toggleTranslate() async {
    if (_translating) return;
    if (_translated != null) {
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
    setState(() {
      _translating = false;
      _translated = t;
    });
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

  /// 跳转评论详情页（展示楼主评论 + 全部楼中楼回复）。
  /// [target] 为被点击的那条楼中楼回复；非空时详情页会自动滚动定位到
  /// 该回复并闪烁数下（同设置搜索高亮效果）。
  /// 未展开时先展开楼中楼，营造「卡片展开 → 自然过渡到详情页」的效果。
  Future<void> _openDetail([BiliComment? target]) async {
    // 与设置页一致的清脆震动反馈
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
      // 按 rpid 去重，防止分页错位导致的重复/漏评论
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

    // 不整卡包 Hero：评论区配图缩略图自身带 Hero（图片 → 查看器飞入），
    // Hero 不能嵌套；评论 → 详情页改用普通跳转
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
              // ── 头部：头像(右下角大会员徽标) + 昵称 + 等级 + 时间 ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(cs, member, isVip: isVip),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 昵称行：名字 + 大会员 / 认证 + 等级（放在名字右边）
                        Row(
                          children: [
                            Flexible(
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
                            // B 站原版 LV 徽标（LV6 及以上带闪电）
                            buildUserLevel(member.level),
                            // ── 粉丝装扮（仅登录且对方佩戴当前账号粉丝勋章时下发） ──
                            if (member.fansDetail case final fansDetail?) ...[
                              const SizedBox(width: 6),
                              FansMedalBadge(
                                detail: fansDetail,
                                fontSize: 9,
                                showNumber: false,
                              ),
                            ],
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
              const SizedBox(height: 8),
              // ── 置顶标识 + 正文 + 配图 + 点赞 + 楼中楼 ──
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
                            // 译文替换原文显示（再点 translate 图标恢复）
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
                    // ── 评论区配图 ──
                    CommentPictures(pictures: _c.pictures),
                    // ── 展开 / 收起长评论 ──
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
                    // ── 回复 + 点赞 + 翻译图标（翻译在点赞右边，纯 icon 无文字） ──
                    if (_c.message.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onReply != null) ...[
                            _ReplyButton(
                              onTap: () => widget.onReply!(_c),
                              count: _c.count,
                            ),
                            const SizedBox(width: 14),
                          ],
                          if (_c.like > 0) ...[
                            Icon(
                              Icons.thumb_up_alt_outlined,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatCount(_c.like, l10n),
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
                          CommentTranslateIconButton(
                            active: _translated != null,
                            translating: _translating,
                            onTap: _toggleTranslate,
                          ),
                        ],
                      ),
                    ],
                    // ── 楼中楼 ──
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
    // 点击头像 → UP 主空间主页（始终走根导航，全页展示，不局限于右侧面板）。
    // Hero 动画：与 BilibiliUserSpacePage 头部头像同 tag，
    // 仅点击时挂载（列表中同一 UP 可能出现多次，避免 tag 冲突）。
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
        color: cs.onInverseSurface.withOpacity(0.5),
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
                    // 展开按钮独立响应，避免与整行跳转详情冲突
                    GestureDetector(
                      onTap: () => _toggleSubReplies(l10n),
                      child: Tooltip(
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

/// 楼中楼单条。
class SubReplyRow extends StatefulWidget {
  final BiliComment sub;
  final VoidCallback? onTap;

  /// 评论区类型（1=视频，12=专栏），用于评论翻译接口。
  final String commentType;

  const SubReplyRow({
    super.key,
    required this.sub,
    this.onTap,
    this.commentType = '1',
  });

  @override
  State<SubReplyRow> createState() => _SubReplyRowState();
}

class _SubReplyRowState extends State<SubReplyRow> {
  BiliComment get _sub => widget.sub;

  // ── 楼中楼评论翻译：译文替换原文，再点图标恢复 ──
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
      oid: int.tryParse(_sub.oid) ?? 0,
      type: int.tryParse(widget.commentType) ?? 1,
      rpid: int.tryParse(_sub.rpid) ?? 0,
      original: _sub.message,
    );
    if (!mounted) return;
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
              Text.rich(
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
                      emotes: _translated == null ? _sub.emotes : const {},
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: cs.onSurface.withOpacity(0.85),
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
              // ── 楼中楼翻译图标（右侧） ──
              if (_sub.message.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: CommentTranslateIconButton(
                    active: _translated != null,
                    translating: _translating,
                    onTap: _toggleTranslate,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplyButton extends StatelessWidget {
  final VoidCallback onTap;
  final int count;

  const _ReplyButton({required this.onTap, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 14,
            color: cs.onSurfaceVariant,
          ),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
