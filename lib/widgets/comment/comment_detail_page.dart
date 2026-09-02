// lib/widgets/comment/comment_detail_page.dart
//
// 评论详情页：点击评论区「N 条回复」/ 楼中楼行后 push 进入。
//   - 顶部展示楼主（主楼）评论，下方分页加载全部楼中楼回复
//   - ExpressiveSliverAppBar 折叠毛玻璃标题栏 + MorphItem 动态卡片布局
//   - 楼主评论与每条回复均可点赞；未登录/未开启携带 Cookie 时弹原生 Toast
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
import 'package:naviflash/widgets/comment/comment_menu.dart';
import 'package:naviflash/widgets/comment/comment_translate.dart';
import 'package:naviflash/widgets/comment/tap_avatar_hero.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/fans_medal_badge.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/pendant_avatar.dart';
import 'package:naviflash/widgets/user_level_icon.dart';
import 'package:naviflash/l10n/app_localizations.dart';

/// 打开评论详情页。
/// [highlightRpid] 非空时：自动加载楼中楼直到该回复出现，滚动定位到
/// 该回复并像设置搜索一样闪烁数下。
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

  // 本页「发回复」FAB 与弹出面板「发送」按钮共用的唯一 Hero tag：
  // 点击 FAB 时飞到发送按钮，关闭面板时飞回原位 + 文字。每页实例唯一，
  // 避免与评论区 FAB（同 tag 会写死）在路由栈里冲突。
  final Object _composerHeroTag = UniqueKey();

  List<BiliComment> _replies = [];
  int _page = 1;
  bool _isEnd = false;
  bool _loading = true;
  bool _loadingMore = false;
  int _total = 0;

  // 点赞本地状态（乐观更新）
  final Map<String, bool> _liked = {};
  final Map<String, int> _likeCounts = {};

  /// 目标回复的闪烁令牌：整页只创建一次，保持稳定，
  /// 目标行 MorphItem 首次挂载时据此触发滚动+闪烁。
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

  /// 目标回复尚未加载出来时继续翻页，直到出现或全部加载完。
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
      _total = page.total;
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
      // 按 rpid 去重，防止分页错位导致的重复/漏评论
      final known = _replies.map((e) => e.rpid).toSet();
      _replies = [
        ..._replies,
        ...page.replies.where((c) => !known.contains(c.rpid)),
      ];
      // 连续空页（即便未标 is_end）也视为已拉完，避免死循环
      _isEnd = page.isEnd || page.replies.isEmpty;
      _total = page.total;
      _loadingMore = false;
    });
    _ensureHighlightLoaded();
  }

  // ═════════════════════════════════════
  //  点赞
  // ═════════════════════════════════════

  bool _isLiked(BiliComment c) => _liked[c.rpid] ?? false;
  int _likeCountOf(BiliComment c) => _likeCounts[c.rpid] ?? c.like;

  Future<void> _toggleLike(BiliComment c) async {
    // 与设置页一致的清脆震动反馈
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

  // ═════════════════════════════════════
  //  构建
  // ═════════════════════════════════════

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
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: LoadingIndicatorM3E()),
                )
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
                          ).colorScheme.onSurface.withOpacity(0.25),
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
                        // 楼主评论（不包 Hero：配图缩略图自身带 Hero 飞入查看器，
                        // Hero 不能嵌套，评论 → 详情页用普通跳转）
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
                          // 命中目标回复：滚动定位并闪烁（同设置搜索高亮效果）
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
                          ),
                        ),
                      );
                    }, childCount: _replies.length + 2),
                  ),
                ),
            ],
          ),
          // ── 「发回复」FAB（与评论区「发评论」FAB 同款交互）──
          // labelVisible 由路由栈状态驱动：弹出输入面板时该路由 isCurrent=false
          // → 「发回复」文字隐藏；从评论区进入本页（本页 isCurrent=true）文字显示，
          // 返回评论区时反之。heroTag 与弹出面板「发送」按钮共用：点击 FAB 飞到
          // 发送按钮，关闭面板反向飞回原位 + 文字（每页唯一，避免路由栈 Hero 冲突）。
          Positioned(
            right: 16,
            bottom: 16,
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

  /// 打开发送面板（回复楼主）；发送成功后把新回复追加到楼中楼末尾。
  Future<void> _openComposer() async {
    final result = await showCommentComposer(
      context,
      oid: int.tryParse(widget.cid) ?? 0,
      replyTo: widget.root,
      type: int.tryParse(widget.commentType) ?? 1,
      heroTag: _composerHeroTag,
    );
    if (!mounted || !result.sent) return;
    if (result.comment != null) {
      setState(() {
        _replies.add(result.comment!);
        _total += 1;
      });
    }
    // 解析失败但已发送：楼中楼列表下次进入自然刷新，无需处理
  }

  /// 点楼中楼卡「回复」：以该回复为目标打开面板（自动加「回复 @xxx :」
  /// 前缀）；发送成功后同样追加到末尾。
  Future<void> _replyToCard(BiliComment comment) async {
    final result = await showCommentComposer(
      context,
      oid: int.tryParse(widget.cid) ?? 0,
      replyTo: comment,
      type: int.tryParse(widget.commentType) ?? 1,
      heroTag: _composerHeroTag,
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

// ═════════════════════════════════════════
//  评论卡片（楼主 / 回复共用）
// ═════════════════════════════════════════

class _DetailCommentCard extends StatefulWidget {
  final BiliComment comment;
  final bool isRoot;
  final bool liked;
  final int likeCount;
  final VoidCallback onLikeTap;

  /// 点「回复」回调（打开发送面板，回复目标 = 本卡评论）；null = 不显示。
  final ValueChanged<BiliComment>? onReply;

  /// 对象ID（评论接口的 oid，视频为 avid）。
  final int oid;

  /// 评论区类型（1=视频，12=专栏）。
  final int type;

  const _DetailCommentCard({
    required this.comment,
    required this.isRoot,
    required this.liked,
    required this.likeCount,
    required this.onLikeTap,
    this.onReply,
    this.oid = 0,
    this.type = 1,
  });

  @override
  State<_DetailCommentCard> createState() => _DetailCommentCardState();
}

class _DetailCommentCardState extends State<_DetailCommentCard> {
  BiliComment get _c => widget.comment;

  // ── 评论翻译：译文替换原文，再点图标恢复 ──
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
        // 点击卡片本体 → 触发回复（楼主卡回复楼主 / 回复卡回复该楼）
        onTap: () {
          HapticFeedback.lightImpact();
          if (widget.onReply != null) widget.onReply!(comment);
        },
        // 长按 / 右键：复制评论、自由选择文本（与评论区一致）
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
              Row(
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
                            if (isRoot) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
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
                            // B 站原版 LV 徽标（LV6 及以上带闪电，放在名字右边）
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
                              _formatTime(comment.ctime),
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
                            message: comment.message,
                            emotes: comment.emotes,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: cs.onSurface,
                            ),
                          ),
                    // ── 评论区配图 ──
                    CommentPictures(pictures: comment.pictures),
                    // ── 回复 + 点赞 + 翻译图标（翻译在点赞右边，纯 icon 无文字） ──
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
    // 点击头像 → UP 主空间主页（始终走根导航，全页展示，不局限于右侧面板）。
    // Hero 动画：与 BilibiliUserSpacePage 头部头像同 tag，
    // 仅点击时挂载（楼中楼里同一 UP 可能出现多次，避免 tag 冲突）。
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
