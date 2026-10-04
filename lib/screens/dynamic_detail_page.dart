                                       
  
                                                
                                      
                               
                             
                                     
                                          
                       
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter/services.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/screens/article_page.dart';
import 'package:naviflash/screens/bilibili_live_room_page.dart';
import 'package:naviflash/screens/bilibili_search_page.dart';
import 'package:naviflash/screens/bilibili_topic_page.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/screens/dynamic_publish_page.dart';
import 'package:naviflash/services/bili_uri_router.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_dynamics_service.dart';
import 'package:naviflash/services/bilibili_dynamic_opus_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/comment/article_comments_panel.dart';
import 'package:naviflash/widgets/comment/comment_panel.dart';
import 'package:naviflash/widgets/comment/comment_composer.dart';
import 'package:naviflash/widgets/comment/inline_comments_section.dart';
import 'package:naviflash/services/interaction_bar_service.dart';
import 'package:naviflash/widgets/dynamic/dynamic_reserve_card.dart';
import 'package:naviflash/widgets/dynamic/dynamic_vote_panel.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart' hide MorphIconButton;
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/morph_widgets.dart';
import 'package:naviflash/widgets/ugc_rich_text.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/services/native_menu_service.dart';
import 'package:naviflash/widgets/more_menu_sheet.dart';
import 'browser_page.dart';
import 'image_viewer_page.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/page_loading.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

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

                                          
  Map<String, dynamic>? _rawItem;

               
  bool _liked = false;
  int _likeCount = 0;
  int _forwardCount = 0;
  bool _isTop = false;
  bool _busy = false;

                                     
  bool _faved = false;

                                
  final GlobalKey _commentsKey = GlobalKey();

                       
  final InteractionBarService _interactionBar = InteractionBarService();

  @override
  void initState() {
    super.initState();
    _interactionBar.setHandlers(
      onWriteComment: _openComposer,
      onCommentsTap: _onCommentsTap,
      onLike: _toggleLike,
      onFavorite: _toggleFav,
      onForward: _openRepost,
    );
    _load();
  }

  @override
  void dispose() {
    _interactionBar.hide();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
                                             
                               
    final results = await Future.wait([
      BilibiliUserSpaceService.fetchDynamicDetail(id: widget.id),
      BilibiliDynamicsService.fetchDetailRaw(widget.id),
    ]);
    if (!mounted) return;
    final detail = results[0] as BiliDynamicDetail?;
    final raw = results[1] as Map<String, dynamic>?;
    if (detail == null) {
      setState(() {
        _loading = false;
        _error = BilibiliUserSpaceService.lastErrorDetail ?? '加载失败';
      });
      return;
    }
    setState(() {
      _detail = detail;
      _rawItem = raw;
      _liked = detail.liked;
      _likeCount = detail.likeCount;
      _forwardCount = detail.forwardCount;
      _isTop = detail.isTop;
      _loading = false;
    });
    _refreshInteractionBar();
  }

                             
  Future<void> _toggleLike() async {
    final d = _detail;
    if (d == null || _busy) return;
    final target = !_liked;
    setState(() => _busy = true);
    final prevLiked = _liked;
    final prevCount = _likeCount;
    setState(() {
      _liked = target;
      _likeCount = (_likeCount + (target ? 1 : -1)).clamp(0, 1 << 31);
    });
    final res = await BilibiliDynamicsService.likeDynamic(
      idStr: d.idStr,
      like: target,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!res.ok) {
        _liked = prevLiked;
        _likeCount = prevCount;
      }
    });
    _refreshInteractionBar();
    if (!res.ok) showAppToast(context, res.message, error: true);
  }

                  
  Future<void> _openRepost([BiliDynamicDetail? target]) async {
    final d = target ?? _detail;
    if (d == null) return;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DynamicPublishPage(
          repostDynId: d.idStr,
          repostPreview: d.text,
          repostAuthor: d.authorName,
        ),
      ),
    );
    if (ok == true && mounted) {
      setState(() => _forwardCount++);
      _refreshInteractionBar();
      showAppToast(context, '转发成功');
    }
  }

                                      
  Future<void> _openEditor(BiliDynamicDetail d) async {
    var raw = _rawItem;
    if (raw == null) {
      raw = await BilibiliDynamicsService.fetchDetailRaw(d.idStr);
      if (raw != null && mounted) setState(() => _rawItem = raw);
    }
    final draft = parseEditDraft(raw);
    if (!mounted) return;
    if (draft == null) {
      showAppToast(context, '无法解析动态内容，暂不支持编辑', error: true);
      return;
    }
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DynamicPublishPage(editDraft: draft),
      ),
    );
    if (ok == true && mounted) {
      showAppToast(context, '编辑成功');
      _load();
    }
  }

                              
  Future<void> _saveAllImages(BiliDynamicDetail d) async {
    final urls = d.images;
    if (urls.isEmpty) return;
    final total = urls.length;
    final progress = ValueNotifier<int>(0);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: ValueListenableBuilder<int>(
          valueListenable: progress,
          builder: (ctx, done, _) => AlertDialog(
            title: const Text('保存全部图片'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: total > 0 ? done / total : 0),
                const SizedBox(height: 12),
                Text('正在保存 $done / $total', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
    final count = await BilibiliDynamicOpusService.saveImagesToGallery(
      urls,
      onProgress: (done, t) => progress.value = done,
    );
    progress.dispose();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (count == 0) {
      showAppToast(context, '保存失败，请重试', error: true);
    } else {
      showAppToast(context, count == total ? '已保存 $count 张图片' : '已保存 $count/$total 张');
    }
  }

                                            
  Future<void> _showMoreMenu(BiliDynamicDetail d) async {
    final mid = BilibiliAccountService.instance.mid;
    final isOwn = mid > 0 && d.authorMid == mid;
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      items: [
        NativeMenuItem(
          text: '转发动态',
          icon: Icons.share_outlined,
          onTap: () => _openRepost(d),
        ),
        NativeMenuItem(
          text: '复制链接',
          icon: Icons.link,
          onTap: () {
            Clipboard.setData(ClipboardData(text: d.url));
            showAppToast(context, '已复制链接');
          },
        ),
        if (d.images.length > 1)
          NativeMenuItem(
            text: '保存全部图片',
            icon: Icons.save_alt,
            onTap: () => _saveAllImages(d),
          ),
        if (isOwn)
          NativeMenuItem(
            text: '编辑动态',
            icon: Icons.edit_outlined,
            onTap: () => _openEditor(d),
          ),
        if (isOwn)
          NativeMenuItem(
            text: _isTop ? '取消置顶' : '置顶动态',
            icon: _isTop ? Icons.push_pin_outlined : Icons.push_pin,
            onTap: () async {
              final res = await BilibiliDynamicsService.setTopDynamic(
                idStr: d.idStr,
                top: !_isTop,
              );
              if (!mounted) return;
              if (!res.ok) {
                showAppToast(context, res.message, error: true);
                return;
              }
              setState(() => _isTop = !_isTop);
              showAppToast(context, _isTop ? '已置顶' : '已取消置顶');
            },
          ),
        if (isOwn)
          NativeMenuItem(
            text: '删除动态',
            icon: Icons.delete_outline,
            destructive: true,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dCtx) => AlertDialog(
                  title: const Text('删除动态'),
                  content: const Text('确定删除该动态？删除后不可恢复。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dCtx).pop(false),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dCtx).pop(true),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !mounted) return;
              final res = await BilibiliDynamicsService.removeDynamic(d.idStr);
              if (!mounted) return;
              if (!res.ok) {
                showAppToast(context, res.message, error: true);
                return;
              }
              showAppToast(context, '删除成功');
              Navigator.of(context).pop(true);
            },
          ),
      ],
    );
    if (nativeOk || !mounted) return;
    showAppBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined, size: 20),
              title: const Text('转发动态', style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.of(ctx).pop();
                _openRepost(d);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, size: 20),
              title: const Text('复制链接', style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.of(ctx).pop();
                Clipboard.setData(ClipboardData(text: d.url));
                showAppToast(context, '已复制链接');
              },
            ),
            if (d.images.length > 1)
              ListTile(
                leading: const Icon(Icons.save_alt, size: 20),
                title: const Text('保存全部图片', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _saveAllImages(d);
                },
              ),
            if (isOwn)
              ListTile(
                leading: const Icon(Icons.edit_outlined, size: 20),
                title: const Text('编辑动态', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openEditor(d);
                },
              ),
            if (isOwn)
              ListTile(
                leading: Icon(
                  _isTop ? Icons.push_pin_outlined : Icons.push_pin,
                  size: 20,
                ),
                title: Text(
                  _isTop ? '取消置顶' : '置顶动态',
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final res = await BilibiliDynamicsService.setTopDynamic(
                    idStr: d.idStr,
                    top: !_isTop,
                  );
                  if (!mounted) return;
                  if (!res.ok) {
                    showAppToast(context, res.message, error: true);
                    return;
                  }
                  setState(() => _isTop = !_isTop);
                  showAppToast(context, _isTop ? '已置顶' : '已取消置顶');
                },
              ),
            if (isOwn)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  '删除动态',
                  style: TextStyle(fontSize: 14, color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('删除动态'),
                      content: const Text('确定删除该动态？删除后不可恢复。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dCtx).pop(false),
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(dCtx).pop(true),
                          child: const Text('删除'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true || !mounted) return;
                  final res = await BilibiliDynamicsService.removeDynamic(
                    d.idStr,
                  );
                  if (!mounted) return;
                  if (!res.ok) {
                    showAppToast(context, res.message, error: true);
                    return;
                  }
                  showAppToast(context, '删除成功');
                  Navigator.of(context).pop(true);
                },
              ),
          ],
        ),
      ),
    );
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
                                                    
                                          
                       
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
                         
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
                                              
      bottomNavigationBar:
          InteractionBarService.isSupported || detail == null
              ? null
              : _buildBottomBar(cs, detail),
      body: SafeArea(
                                    
                                                          
        top: false,
        bottom: false,
        child: _isWideScreen
            ? _buildWideLayout(cs, l10n, detail)
            : _buildBody(cs, l10n, detail),
      ),
    );
  }

                                  
                              
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
                                                 
        Expanded(child: _buildBody(cs, l10n, detail)),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
                       
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

                                              
  String _commentCid(BiliDynamicDetail d) =>
      d.commentIdStr.isNotEmpty ? d.commentIdStr : d.idStr;

                                              
  int _commentType(BiliDynamicDetail d) =>
      d.commentType > 0 ? d.commentType : 17;

                                         
  String _dynSourceTitle(BiliDynamicDetail d) {
    final text = d.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isNotEmpty) {
      return text.length > 60 ? '${text.substring(0, 60)}…' : text;
    }
    return d.archiveTitle ??
        d.articleTitle ??
        d.liveTitle ??
        '动态 ${d.idStr}';
  }

                               
  Widget _buildBody(
    ColorScheme cs,
    AppLocalizations l10n,
    BiliDynamicDetail? detail,
  ) {
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: detail == null,
    )) {
      return const PageLoadingIndicator();
    }
    if (detail == null) {
      return _buildError(cs, l10n);
    }
    return AppRefreshIndicator(
      onRefresh: _load,
      color: cs.primary,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.depth == 0) {
                                           
                                            
            InteractionBarService.refresh();
          }
          return false;
        },
        child: CustomScrollView(
          physics: _loading
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(
                  parent: AppRefreshScrollPhysics(),
                ),
          slivers: [
                                           
                                                  
                                                               
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.paddingOf(context).top + kToolbarHeight,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _buildContentChildren(cs, detail),
              ),
            ),
          ),
                                 
          if (!_isWideScreen)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverToBoxAdapter(
                child: KeyedSubtree(
                  key: _commentsKey,
                  child: InlineCommentsSection(
                    cid: _commentCid(detail),
                    commentType: '${_commentType(detail)}',
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(
                                                 
              height:
                  MediaQuery.of(context).padding.bottom +
                  (InteractionBarService.isSupported ? 68 : 16),
            ),
          ),
          ],
        ),
      ),
    );
  }

                                                  
  List<Widget> _buildContentChildren(ColorScheme cs, BiliDynamicDetail d) {
    return [
      _buildAuthorRow(cs, d),
      const SizedBox(height: 12),
      _buildTextContent(cs, d),
      if (d.hasImages) ...[const SizedBox(height: 12), _buildImageGrid(cs, d)],
      if (_voteRef(d) != null) ...[
        const SizedBox(height: 12),
        DynamicVotePanel(
          voteId: _voteRef(d)!.voteId,
          dynamicId: d.idStr,
        ),
      ],
      if (_reserveInfo() != null) ...[
        const SizedBox(height: 12),
        DynamicReserveCard(
          reserve: _reserveInfo()!,
          dynamicId: d.idStr,
        ),
      ],
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

                                                
                                  
  BiliVoteRef? _voteRef(BiliDynamicDetail d) {
    final fromRaw = BiliReserveInfo.voteRefFromModules(_rawItem?['modules']);
    if (fromRaw != null) return fromRaw;
    for (final node in d.textNodes) {
      if (node.type == 'RICH_TEXT_NODE_TYPE_VOTE') {
        final id = int.tryParse(node.rid) ?? 0;
        if (id > 0) return BiliVoteRef(voteId: id, title: node.text);
      }
    }
    return null;
  }

                                                     
  BiliReserveInfo? _reserveInfo() =>
      BiliReserveInfo.fromModules(_rawItem?['modules']);

  Widget _buildCommentsPlaceholder(ColorScheme cs, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 48,
            color: cs.onSurfaceVariant.withValues(alpha: 0.35),
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
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _error ?? '加载失败',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
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

                                           
  void _openComments(BiliDynamicDetail d) {
    showCommentPanel(
      context,
      cid: _commentCid(d),
      episodeTitle: '动态详情',
      commentType: '${_commentType(d)}',
    );
  }

                                  

                   
  void _refreshInteractionBar() {
    final d = _detail;
    if (d == null) return;
    _interactionBar.show(
      colorScheme: Theme.of(context).colorScheme,
      writeLabel: '写评论',
      commentCount: d.commentCount,
      likeCount: _likeCount,
      favoriteCount: 0,
      forwardCount: _forwardCount,
      liked: _liked,
      favorite: _faved,
    );
  }

                          
  Future<void> _openComposer() async {
    final d = _detail;
    if (d == null) return;
    final oid = int.tryParse(_commentCid(d)) ?? 0;
    final r = await showCommentComposer(
      context,
      oid: oid,
      type: _commentType(d),
      sourceTitle: _dynSourceTitle(d),
      sourceId: d.commentIdStr.isNotEmpty ? d.commentIdStr : d.idStr,
    );
    if (r.sent) {
      final st = _commentsKey.currentState;
      if (st is InlineCommentsSectionState) st.reload();
      _refreshInteractionBar();
    }
  }

                                         
  void _onCommentsTap() {
    final ctx = _commentsKey.currentContext;
    final ro = ctx?.findRenderObject();
    if (ro != null) {
      final viewport = RenderAbstractViewport.of(ro);
      final target = viewport.getOffsetToReveal(ro, 0).offset;
                                   
      final pos = PrimaryScrollController.of(context).position;
      if (pos.pixels < target - 2) {
        pos.animateTo(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
        return;
      }
    }
    _openComposer();
  }

                                              
  Future<void> _toggleFav() async {
    final d = _detail;
    if (d == null || _busy) return;
    setState(() => _busy = true);
    final res = await BilibiliDynamicsService.favOpus(
      opusId: d.idStr,
      fav: !_faved,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      setState(() => _faved = !_faved);
      _refreshInteractionBar();
    } else {
      showAppToast(context, res.message, error: true);
    }
  }

  Widget _buildBottomBar(ColorScheme cs, BiliDynamicDetail d) {
    final content = Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _toggleLike,
            borderRadius: BorderRadius.circular(12),
            child: _StatItem(
              cs: cs,
              icon: _liked
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              text: _formatCount(_likeCount),
              color: _liked ? cs.error : null,
            ),
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
          child: InkWell(
            onTap: _openRepost,
            borderRadius: BorderRadius.circular(12),
            child: _StatItem(
              cs: cs,
              icon: Icons.share_outlined,
              text: _formatCount(_forwardCount),
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => _showMoreMenu(d),
            borderRadius: BorderRadius.circular(12),
            child: _StatItem(
              cs: cs,
              icon: Icons.more_horiz,
              text: '更多',
            ),
          ),
        ),
      ],
    );
                                        
                     
    if (!SettingsService.fragmentRenderingEnabled) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
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
                                                      
          child: d.authorMid > 0
              ? Hero(transitionOnUserGestures: true, tag: 'bili_space_avatar_${d.authorMid}', child: avatar)
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
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w500),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  final id = int.tryParse(node.rid) ?? 0;
                  final name = topicNameFromText(node.text);
                  if (name.isEmpty) return;
                                                 
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => id > 0
                          ? BilibiliTopicPage(topicId: id, name: name)
                          : BilibiliSearchPage(
                              initialKeyword: name,
                              recordInitialKeyword: false,
                            ),
                    ),
                  );
                },
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
                                                   
          if (node.url.isNotEmpty) {
            spans.add(
              TextSpan(
                text: node.text,
                style: TextStyle(color: cs.primary),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => openBiliUri(context, node.url),
              ),
            );
          } else {
            spans.addAll(
              buildUgcSpans(
                text: node.text,
                style: TextStyle(fontSize: 15, height: 1.6, color: cs.onSurface),
                context: context,
              ),
            );
          }
      }
    }
    return spans;
  }

               
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
                                              
                      
    final heroTag = 'dyn_img_${d.idStr.isEmpty ? widget.id : d.idStr}_$index';
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          heroTransitionRoute(
                                              
            heroZoom: true,
            page: ImageViewerPage(
              sources: [
                for (var i = 0; i < d.images.length; i++)
                  ImageViewerSource(
                    url: d.images[i],
                    heroTag:
                        'dyn_img_${d.idStr.isEmpty ? widget.id : d.idStr}_$i',
                  ),
              ],
              initialIndex: index,
            ),
          ),
        );
      },
      child: Hero(
          transitionOnUserGestures: true,
        tag: heroTag,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
                                                         
                                     
          child: Image(
            image: CachedImageProvider(
              url,
              headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                  ? null
                  : NetworkSettingsService.instance.apiHeaders,
                                      
                                  
              cacheWidth: 1440,
            ),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: cs.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image_outlined,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }

                
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
                                                         
                                                             
                                   
                      !SettingsService.heroTransitionBlurEnabled
                  ? Hero(
                        transitionOnUserGestures: true,
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
                                            
                    
    if (d.bvid != null && d.bvid!.isNotEmpty && SettingsService.heroTransitionBlurEnabled) {
      return Hero(
          transitionOnUserGestures: true,
        tag: 'bili_video_${d.bvid!}',
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: card,
      );
    }
    return card;
  }

              
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
            ImmersiveMaterialPageRoute(
              page: ArticlePage(cvid: cvid, initialTitle: d.articleTitle),
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

                                            
                   
                                            

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;
  final Color? color;
  const _StatItem({
    required this.icon,
    required this.text,
    required this.cs,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? cs.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: c),
        const SizedBox(height: 3),
        Text(text, style: TextStyle(fontSize: 11.5, color: c)),
      ],
    );
  }
}
