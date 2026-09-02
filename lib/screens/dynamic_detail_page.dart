// lib/screens/dynamic_detail_page.dart
//
//   - 通过 x/polymer/web-dynamic/v1/detail 拉取单条动态
//   - 渲染：作者行、富文本正文（@ / 话题 / 表情）、图片网格、
//     投稿视频卡 / 专栏卡 / 直播卡、转发嵌套卡片
//   - 评论区：与专栏查看页一致的宽屏/竖屏布局——
//       宽屏（宽 ≥ 768）：左侧动态内容 + 右侧评论区面板
//       竖屏：动态内容 + 底部操作栏（点赞/评论/转发，点评论弹出面板）
//   - 图片点击全屏查看；作者点击进空间
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/screens/article_page.dart';
import 'package:naviflash/screens/bilibili_live_room_page.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/comment/article_comments_panel.dart';
import 'package:naviflash/widgets/comment/comment_panel.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart' hide MorphIconButton;
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/morph_widgets.dart';
import 'browser_page.dart';
import 'image_viewer_page.dart';

class DynamicDetailPage extends StatefulWidget {
  final String id;

  const DynamicDetailPage({super.key, required this.id});

  @override
  State<DynamicDetailPage> createState() => _DynamicDetailPageState();
}

class _DynamicDetailPageState extends State<DynamicDetailPage> {
  BiliDynamicDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final detail = await BilibiliUserSpaceService.fetchDynamicDetail(
      id: widget.id,
    );
    if (!mounted) return;
    if (detail == null) {
      setState(() {
        _loading = false;
        _error = BilibiliUserSpaceService.lastErrorDetail ?? '加载失败';
      });
      return;
    }
    setState(() {
      _detail = detail;
      _loading = false;
    });
  }

  void _openBrowser() {
    final detail = _detail;
    if (detail == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrowserPage(initialUrl: detail.url, title: '动态详情'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final detail = _detail;

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        // 与专栏/搜索页同款毛玻璃顶栏
        flexibleSpace: FrostedPanel(
          opacity: 0.75,
          child: const SizedBox.expand(),
        ),
        title: const Text('动态详情', maxLines: 1, overflow: TextOverflow.ellipsis),
        leadingWidth: 112,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              MorphIconButton(
                icon: Icons.arrow_back,
                tooltip: l10n.homeBack,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              if (detail != null)
                MorphIconButton(
                  icon: Icons.open_in_browser_outlined,
                  tooltip: '浏览器打开',
                  onTap: _openBrowser,
                ),
            ],
          ),
        ),
      ),
      // 底部操作栏：点赞 / 评论 / 转发（点评论打开评论区）
      bottomNavigationBar: detail != null ? _buildBottomBar(cs, detail) : null,
      body: SafeArea(
        // top: false → 内容延伸到毛玻璃顶栏下方
        top: false,
        child: _isWideScreen
            ? _buildWideLayout(cs, l10n, detail)
            : _buildBody(cs, l10n, detail),
      ),
    );
  }

  /// 宽横屏检测：与专栏 / 播放页一致（宽度 ≥ 768）。
  /// 宽屏时左侧动态内容 + 右侧评论区面板分屏展示。
  bool get _isWideScreen => MediaQuery.of(context).size.width >= 768;

  Widget _buildWideLayout(
    ColorScheme cs,
    AppLocalizations l10n,
    BiliDynamicDetail? detail,
  ) {
    final rightWidth = (MediaQuery.of(context).size.width * 0.34).clamp(
      320.0,
      480.0,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 左栏：动态内容（加载中 / 出错由 _buildBody 处理） ──
        Expanded(child: _buildBody(cs, l10n, detail)),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: cs.outlineVariant.withOpacity(0.5),
        ),
        // ── 右栏：评论区 ──
        SizedBox(
          width: rightWidth,
          child: SafeArea(
            top: false,
            bottom: true,
            child: Container(
              color: cs.surfaceContainer,
              child: detail == null
                  ? _buildCommentsPlaceholder(cs, l10n)
                  : ArticleCommentsPanel(
                      cid: _commentCid(detail),
                      episodeTitle: '动态详情',
                      commentType: '${_commentType(detail)}',
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// 评论区 oid（basic.comment_id_str，缺省回退动态 id）。
  String _commentCid(BiliDynamicDetail d) =>
      d.commentIdStr.isNotEmpty ? d.commentIdStr : d.idStr;

  /// 评论区类型（basic.comment_type，缺省 17 = 动态/图文）。
  int _commentType(BiliDynamicDetail d) =>
      d.commentType > 0 ? d.commentType : 17;

  /// 竖屏 / 左栏主体：加载 / 出错 / 内容滚动。
  Widget _buildBody(
    ColorScheme cs,
    AppLocalizations l10n,
    BiliDynamicDetail? detail,
  ) {
    if (_loading) {
      return const Center(child: LoadingIndicatorM3E());
    }
    if (detail == null) {
      return _buildError(cs, l10n);
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: cs.primary,
      child: CustomScrollView(
        physics: _loading
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _buildContentChildren(cs, detail),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 动态内容块列表（作者行 / 正文 / 图片 / 模块卡 / 转发）。
  List<Widget> _buildContentChildren(ColorScheme cs, BiliDynamicDetail d) {
    return [
      _buildAuthorRow(cs, d),
      const SizedBox(height: 12),
      _buildTextContent(cs, d),
      if (d.hasImages) ...[const SizedBox(height: 12), _buildImageGrid(cs, d)],
      if (d.isArchive) ...[
        const SizedBox(height: 12),
        _buildArchiveCard(cs, d),
      ],
      if (d.articleTitle != null) ...[
        const SizedBox(height: 12),
        _buildArticleCard(cs, d),
      ],
      if (d.liveRoomId > 0) ...[
        const SizedBox(height: 12),
        _buildLiveCard(cs, d),
      ],
      if (d.orig != null) ...[
        const SizedBox(height: 12),
        _buildRepostCard(cs, d.orig!),
      ],
    ];
  }

  Widget _buildCommentsPlaceholder(ColorScheme cs, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 48,
            color: cs.onSurfaceVariant.withOpacity(0.35),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.commentPanelTitle,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme cs, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 56,
            color: cs.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _error ?? '加载失败',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ),
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

  /// 打开评论区（竖屏底部操作栏入口）。
  void _openComments(BiliDynamicDetail d) {
    showCommentPanel(
      context,
      cid: _commentCid(d),
      episodeTitle: '动态详情',
      commentType: '${_commentType(d)}',
    );
  }

  Widget _buildBottomBar(ColorScheme cs, BiliDynamicDetail d) {
    final content = Row(
      children: [
        Expanded(
          child: _StatItem(
            cs: cs,
            icon: Icons.favorite_outline_rounded,
            text: _formatCount(d.likeCount),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => _openComments(d),
            borderRadius: BorderRadius.circular(12),
            child: _StatItem(
              cs: cs,
              icon: Icons.mode_comment_outlined,
              text: _formatCount(d.commentCount),
            ),
          ),
        ),
        Expanded(
          child: _StatItem(
            cs: cs,
            icon: Icons.share_outlined,
            text: _formatCount(d.forwardCount),
          ),
        ),
      ],
    );
    // 高级玻璃渲染开启：底部操作栏换成悬浮液态玻璃胶囊（与专栏页一致），
    // 设置关闭时保持原有纯色底栏。
    if (!SettingsService.fragmentRenderingEnabled) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
          ),
        ),
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 6,
          bottom: MediaQuery.of(context).padding.bottom + 6,
        ),
        child: content,
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: NaviGlass(
        radius: 26,
        blur: 12,
        thickness: 18,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: content,
        ),
      ),
    );
  }

  // ── 作者行 ──
  Widget _buildAuthorRow(ColorScheme cs, BiliDynamicDetail d) {
    final avatar = ClipOval(
      child: d.authorFace.isNotEmpty
          ? Image(
              image: CachedImageProvider(
                BilibiliUserSpaceService.avatarUrl(d.authorFace),
                headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                    ? null
                    : NetworkSettingsService.instance.apiHeaders,
              ),
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _avatarPlaceholder(cs),
            )
          : _avatarPlaceholder(cs),
    );
    return Row(
      children: [
        GestureDetector(
          onTap: d.authorMid > 0
              ? () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BilibiliUserSpacePage(mid: d.authorMid),
                    ),
                  );
                }
              : null,
          // 头像 Hero：与 BilibiliUserSpacePage 头部头像同 tag
          child: d.authorMid > 0
              ? Hero(tag: 'bili_space_avatar_${d.authorMid}', child: avatar)
              : avatar,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.authorName.isEmpty ? '未知用户' : d.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(d.pubTs),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarPlaceholder(ColorScheme cs) {
    return Container(
      width: 42,
      height: 42,
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.person_outline, size: 24, color: cs.onSurfaceVariant),
    );
  }

  // ── 正文（富文本） ──
  Widget _buildTextContent(ColorScheme cs, BiliDynamicDetail d) {
    final text = d.text;
    if (text.isEmpty) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 15, height: 1.6, color: cs.onSurface),
        children: _buildSpans(cs, d),
      ),
    );
  }

  List<InlineSpan> _buildSpans(ColorScheme cs, BiliDynamicDetail d) {
    final nodes = d.textNodes;
    if (nodes.isEmpty) return [TextSpan(text: d.text)];
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      switch (node.type) {
        case 'RICH_TEXT_NODE_TYPE_AT':
          spans.add(
            TextSpan(
              text: node.text,
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w500),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  final mid = int.tryParse(node.rid) ?? 0;
                  if (mid > 0) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BilibiliUserSpacePage(mid: mid),
                      ),
                    );
                  }
                },
            ),
          );
        case 'RICH_TEXT_NODE_TYPE_TOPIC':
          spans.add(
            TextSpan(
              text: node.text,
              style: TextStyle(color: cs.primary),
            ),
          );
        case 'RICH_TEXT_NODE_TYPE_EMOJI':
          if (node.emojiUrl != null && node.emojiUrl!.isNotEmpty) {
            spans.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Image(
                    image: CachedImageProvider(node.emojiUrl!),
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) =>
                        Text(node.text, style: TextStyle(fontSize: 15)),
                  ),
                ),
              ),
            );
          } else {
            spans.add(TextSpan(text: node.text));
          }
        default:
          spans.add(TextSpan(text: node.text));
      }
    }
    return spans;
  }

  // ── 图片网格 ──
  Widget _buildImageGrid(ColorScheme cs, BiliDynamicDetail d) {
    final images = d.images;
    if (images.length == 1) {
      return _buildImageTile(cs, d, images[0], 0);
    }
    final columns = images.length == 2 ? 2 : 3;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        for (var i = 0; i < images.length; i++)
          _buildImageTile(cs, d, images[i], i),
      ],
    );
  }

  Widget _buildImageTile(
    ColorScheme cs,
    BiliDynamicDetail d,
    String url,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          heroTransitionRoute(
            page: ImageViewerPage(
              sources: [
                for (final u in d.images)
                  ImageViewerSource(url: u, heroTag: null),
              ],
              initialIndex: index,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        // 走 CachedImageProvider（内存 → 磁盘 → 网络）：动态图落盘缓存，
        // 下次查看直接从本地读，设置页「清理缓存」可清除。
        child: Image(
          image: CachedImageProvider(
            url,
            headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                ? null
                : NetworkSettingsService.instance.apiHeaders,
          ),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: cs.surfaceContainerHighest,
            child: Icon(
              Icons.broken_image_outlined,
              color: cs.onSurfaceVariant.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }

  // ── 投稿视频卡 ──
  Widget _buildArchiveCard(ColorScheme cs, BiliDynamicDetail d) {
    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final bvid = d.bvid != null && d.bvid!.isNotEmpty ? d.bvid! : null;
          if (bvid != null) {
            openBilibiliVideo(
              context,
              bvid: bvid,
              initialTitle: d.archiveTitle ?? '',
              initialCover: d.archiveCover ?? '',
              heroTag: 'bili_video_$bvid',
            );
            return;
          }
          final url = d.aid > 0
              ? 'https://www.bilibili.com/video/av${d.aid}'
              : '';
          if (url.isEmpty) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  BrowserPage(initialUrl: url, title: d.archiveTitle ?? ''),
            ),
          );
        },
        child: Row(
          children: [
            SizedBox(
              width: 140,
              height: 88,
              child: d.bvid != null &&
                      d.bvid!.isNotEmpty &&
                      // 整页 Hero（iOS 整卡放大）模式：封面不单独包 Hero，
                      // 整卡 Hero 在 _buildArchiveCard 返回处；经典模式
                      // 保持封面 Hero。
                      !SettingsService.heroTransitionBlurEnabled
                  ? Hero(
                      tag: 'bili_video_${d.bvid!}',
                      child:
                          d.archiveCover != null && d.archiveCover!.isNotEmpty
                          ? Image(
                              image: CachedImageProvider(
                                BilibiliUserSpaceService.coverUrl(
                                  d.archiveCover!,
                                ),
                                headers:
                                    NetworkSettingsService
                                        .instance
                                        .apiHeaders
                                        .isEmpty
                                    ? null
                                    : NetworkSettingsService
                                          .instance
                                          .apiHeaders,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _mediaPlaceholder(cs),
                            )
                          : _mediaPlaceholder(cs),
                    )
                  : d.archiveCover != null && d.archiveCover!.isNotEmpty
                  ? Image(
                      image: CachedImageProvider(
                        BilibiliUserSpaceService.coverUrl(d.archiveCover!),
                        headers:
                            NetworkSettingsService.instance.apiHeaders.isEmpty
                            ? null
                            : NetworkSettingsService.instance.apiHeaders,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _mediaPlaceholder(cs),
                    )
                  : _mediaPlaceholder(cs),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.archiveTitle ?? '视频动态',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (d.archiveDurationText != null &&
                            d.archiveDurationText!.isNotEmpty) ...[
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            d.archiveDurationText!,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        Text(
                          _formatCount(d.archivePlay),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.subtitles_outlined,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatCount(d.archiveDanmaku),
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
            ),
          ],
        ),
      ),
    );
    // 整页 Hero（iOS 整卡放大）模式：Hero 包整个卡片；经典模式封面
    // Hero 已由封面区提供。
    if (d.bvid != null && d.bvid!.isNotEmpty && SettingsService.heroTransitionBlurEnabled) {
      return Hero(
        tag: 'bili_video_${d.bvid!}',
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: card,
      );
    }
    return card;
  }

  // ── 专栏卡 ──
  Widget _buildArticleCard(ColorScheme cs, BiliDynamicDetail d) {
    return _buildTapCard(
      cs,
      icon: Icons.article_outlined,
      title: d.articleTitle ?? '专栏',
      subtitle: '阅读专栏',
      onTap: () {
        final cvMatch = RegExp(r'/cv(\d+)').firstMatch(d.articleUrl ?? '');
        final cvid = cvMatch == null ? 0 : int.tryParse(cvMatch.group(1)!) ?? 0;
        if (cvid > 0) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ArticlePage(cvid: cvid, initialTitle: d.articleTitle),
            ),
          );
        } else if (d.articleUrl != null && d.articleUrl!.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  BrowserPage(initialUrl: d.articleUrl!, title: '专栏'),
            ),
          );
        }
      },
    );
  }

  // ── 直播卡 ──
  Widget _buildLiveCard(ColorScheme cs, BiliDynamicDetail d) {
    return _buildTapCard(
      cs,
      icon: Icons.live_tv_outlined,
      title: d.liveTitle ?? '直播',
      subtitle: '进入直播间',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BilibiliLiveRoomPage(
              roomId: d.liveRoomId,
              title: d.liveTitle ?? '',
              uname: d.authorName,
              face: d.authorFace,
              cover: d.liveCover ?? '',
            ),
          ),
        );
      },
    );
  }

  Widget _buildTapCard(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 26, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  // ── 转发嵌套卡 ──
  Widget _buildRepostCard(ColorScheme cs, BiliDynamicDetail orig) {
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DynamicDetailPage(id: orig.idStr),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '@${orig.authorName}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(orig.pubTs),
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (orig.text.isNotEmpty)
                Text(
                  orig.text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: cs.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              if (orig.hasImages) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 72,
                  child: Row(
                    children: [
                      for (final img in orig.images.take(3))
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image(
                              image: CachedImageProvider(
                                img,
                                headers:
                                    NetworkSettingsService
                                        .instance
                                        .apiHeaders
                                        .isEmpty
                                    ? null
                                    : NetworkSettingsService
                                          .instance
                                          .apiHeaders,
                              ),
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 72,
                                height: 72,
                                color: cs.surfaceContainerHighest,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (orig.isArchive)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          orig.archiveTitle ?? '视频',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaPlaceholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.movie_outlined, size: 28, color: cs.onSurfaceVariant),
    );
  }

  String _formatCount(int n) {
    if (n >= 10000) {
      final w = n / 10000;
      return '${w.toStringAsFixed(w >= 100 ? 0 : 1)}${L10n.current.tenThousandUnit}';
    }
    return '$n';
  }

  String _formatDate(int ts) {
    if (ts <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context);
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${l10n.userSpaceToday} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}

// ═════════════════════════════════════════
//  底部统计项（与专栏查看页同款）
// ═════════════════════════════════════════

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;
  const _StatItem({required this.icon, required this.text, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: cs.onSurfaceVariant),
        const SizedBox(height: 3),
        Text(
          text,
          style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
