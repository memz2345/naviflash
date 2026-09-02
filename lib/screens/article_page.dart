// lib/screens/article_page.dart
//
// B 站专栏（文章）查看页（参考 PiliPlus pages/article/view.dart 布局）：
//   - 拉取文章详情（服务见 bilibili_article_service.dart）
//   - 头部：封面图（可选）+ 标题 + 作者（点击进空间）+ 发布时间/阅读量
//   - 正文：HTML 正文 / JSON ops 富文本，统一由 ArticleContentBody 渲染
//   - 正文图片：点击全屏查看（可左右滑动切换全部图片），长按放大预览
//   - 底部操作栏：阅读 / 点赞 / 收藏 / 评论 / 转发（只读展示计数）
//   - 顶栏菜单：浏览器打开 / 分享 / 复制链接
//   - 失败可重试；正文支持文本选择复制
import 'package:flutter/material.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/services/bilibili_article_service.dart';
import 'package:naviflash/services/bilibili_translate_api.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/article_content_view.dart';
import 'package:naviflash/widgets/comment/article_comments_panel.dart';
import 'package:naviflash/widgets/comment/comment_panel.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/long_press_glass_tab_switcher.dart';
import 'package:naviflash/widgets/morph_widgets.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart' hide MorphIconButton;
import 'package:provider/provider.dart';
import 'browser_page.dart';
import 'image_viewer_page.dart';

class ArticlePage extends StatefulWidget {
  final int cvid;

  /// 预填标题（搜索结果直接展示，避免加载前标题空白）。
  final String? initialTitle;

  /// 入口 Hero 标签（搜索页整卡 → 本页整页放大飞入动画；
  /// 关闭「Hero 转场背景模糊」时退化为经典封面飞入）。
  final String? heroTag;

  /// 入口封面图（加载中先展示，文章加载完成后替换为真实封面）。
  final String? coverUrl;

  const ArticlePage({
    super.key,
    required this.cvid,
    this.initialTitle,
    this.heroTag,
    this.coverUrl,
  });

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  BiliArticle? _article;
  bool _loading = true;
  String? _error;
  bool _showAppBarTitle = false;

  /// AI 翻译后的标题（未翻译时为空，渲染层回退到原文，参考视频页）。
  String _translatedTitle = '';

  /// 实际展示标题：优先翻译结果，翻译为空/相同时回退原文。
  String _displayTitle(BiliArticle article) =>
      _translatedTitle.isNotEmpty ? _translatedTitle : article.title;

  final ScrollController _scrollController = ScrollController();

  /// 宽横屏检测：与 settings_split_screen / B 站播放页一致（宽度 ≥ 768）。
  /// 宽屏时左侧文章 + 右侧评论区分屏展示。
  bool get _isWideScreen => MediaQuery.of(context).size.width >= 768;

  /// 是否使用整页 Hero（iOS 开 App 放大）：开启模糊 + 有入口 tag。
  bool get _usesZoomHero =>
      widget.heroTag != null && SettingsService.heroTransitionBlurEnabled;

  /// 整页 Hero 是否还包裹着页面：入场飞行结束后移除，
  /// 返回时由 PopScope 拦截先重新包裹再 pop（与视频播放页一致）。
  bool _zoomHeroActive = true;

  Animation<double>? _routeAnimation;
  AnimationStatusListener? _routeAnimListener;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
    // 入场飞行（与路由过渡同步）结束后移除整页 Hero：
    // 解除对内层 Hero 的嵌套限制（封面/正文图片可独立飞行）。
    // 无路由动画（heroTag 为空 / 经典路由已完成）时立即移除。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _routeAnimation = ModalRoute.of(context)?.animation;
      final anim = _routeAnimation;
      if (anim == null || anim.isCompleted) {
        setState(() {
          _zoomHeroActive = false;
        });
        return;
      }
      _routeAnimListener = (status) {
        if (status == AnimationStatus.completed && mounted) {
          _routeAnimation?.removeStatusListener(_routeAnimListener!);
          _routeAnimListener = null;
          setState(() {
            _zoomHeroActive = false;
          });
        }
      };
      anim.addStatusListener(_routeAnimListener!);
    });
  }

  @override
  void dispose() {
    if (_routeAnimListener != null) {
      _routeAnimation?.removeStatusListener(_routeAnimListener!);
      _routeAnimListener = null;
    }
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollController.offset > 240;
    if (show != _showAppBarTitle && mounted) {
      setState(() => _showAppBarTitle = show);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final article = await BilibiliArticleService.fetchArticle(
      cvid: widget.cvid,
    );
    if (!mounted) return;
    setState(() {
      _article = article;
      _loading = false;
      _error = article == null
          ? BilibiliArticleService.lastErrorDetail ??
                AppLocalizations.of(context).articleLoadFailed
          : null;
    });
    if (article != null) {
      _translateTitle(article);
    }
  }

  /// AI 翻译专栏标题并刷新显示（静默失败，不影响原标题）。
  Future<void> _translateTitle(BiliArticle article) async {
    try {
      final translate = context.read<BilibiliTranslateService>();
      if (!translate.enabled) return;
      final res = await BilibiliTranslateApi.translateArticleTitle(
        cvid: article.id,
        title: article.title,
      );
      if (!mounted || res == null) return;
      final translated = res.translated.isNotEmpty
          ? res.translated
          : res.original;
      if (translated.isNotEmpty && translated != article.title) {
        setState(() => _translatedTitle = translated);
      }
    } catch (_) {
      // 翻译失败时保持原标题
    }
  }

  // ── 动作 ──

  void _openAuthor() {
    final mid = _article?.author?.mid ?? 0;
    if (mid <= 0) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BilibiliUserSpacePage(mid: mid)));
  }

  void _openBrowser() {
    final url = _article?.url;
    if (url == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrowserPage(
          initialUrl: url,
          title:
              _article?.title ?? AppLocalizations.of(context).searchTypeArticle,
        ),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrowserPage(
          initialUrl: url,
          title: AppLocalizations.of(context).browserLinkPageTitle,
        ),
      ),
    );
  }

  Future<void> _openImage(String url, List<String> all) async {
    if (!mounted) return;
    // 规范化比较：正文 <img> 的 src 与 origin_image_urls 可能格式不同
    // （如 // 无协议头），直接 indexOf 会返回 -1 导致打开错图。
    String norm(String u) => u.startsWith('//') ? 'https:$u' : u;
    final target = norm(url);
    final normalizedAll = [for (final u in all) norm(u)];
    var index = normalizedAll.indexOf(target);

    // 被点击的图片必须出现在查看器里：找不到时把它放到首位
    final List<String> urls;
    if (index >= 0) {
      urls = List.of(all);
    } else {
      index = 0;
      urls = [url, ...all];
    }

    final isCover = target == norm(_article?.cover ?? '');
    // 同一 URL 只给首次出现加 Hero（封面用独立前缀标签），避免同名冲突
    final seen = <String>{};
    final sources = <ImageViewerSource>[
      for (var i = 0; i < urls.length; i++)
        ImageViewerSource(
          url: urls[i],
          heroTag: isCover && i == index
              ? articleCoverHeroTag(urls[i])
              : seen.add(norm(urls[i]))
              ? articleImageHeroTag(urls[i])
              : null,
        ),
    ];
    await Navigator.of(context).push(
      heroTransitionRoute(
        page: ImageViewerPage(sources: sources, initialIndex: index),
      ),
    );
  }

  void _copyLink() {
    final url = _article?.url;
    if (url == null) return;
    Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    showAppToast(context, AppLocalizations.of(context).scanLinkCopied);
  }

  void _share() {
    final url = _article?.url;
    if (url == null) return;
    SharePlus.instance.share(ShareParams(text: url));
  }

  void _openComments() {
    final article = _article;
    if (article == null) return;
    // 专栏评论区 type=12（参考 PiliPlus commentType = 12）
    showCommentPanel(
      context,
      cid: article.id.toString(),
      episodeTitle: article.title,
      commentType: '12',
    );
  }

  void _onLongPressBottomAction(int index) {
    switch (index) {
      case 0:
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      case 1:
        showAppToast(context, '点赞统计暂为只读');
      case 2:
        showAppToast(context, '收藏统计暂为只读');
      case 3:
        _openComments();
      case 4:
        _share();
    }
  }

  // ── 工具 ──

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

  // ── 构建 ──

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final article = _article;
    Widget page = Scaffold(
      backgroundColor: cs.surfaceContainer,
      extendBodyBehindAppBar: true,
      // 液态玻璃底栏时正文延伸到栏后滚动（玻璃才有内容可折射/模糊）
      extendBody: SettingsService.fragmentRenderingEnabled && article != null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        // 与 B 站搜索页同款毛玻璃顶栏：模糊 sigma 10 + surface 0.75
        flexibleSpace: FrostedPanel(
          opacity: 0.75,
          child: const SizedBox.expand(),
        ),
        title:
            _showAppBarTitle &&
                article != null &&
                _displayTitle(article).isNotEmpty
            ? Text(
                _displayTitle(article),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Text(
                widget.initialTitle?.isNotEmpty == true
                    ? widget.initialTitle!
                    : l10n.searchTypeArticle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
              if (article != null)
                MorphIconButton(
                  icon: Icons.open_in_browser_outlined,
                  tooltip: l10n.articleOpenBrowser,
                  onTap: _openBrowser,
                ),
            ],
          ),
        ),
        actions: [
          LiquidGlassMenuButton(
            icon: Icons.more_vert,
            tooltip: l10n.articleShare,
            menuWidth: 220,
            actions: [
              GlassMenuAction(
                icon: Icons.share_outlined,
                text: l10n.articleShare,
                onTap: _share,
              ),
              GlassMenuAction(
                icon: Icons.copy_rounded,
                text: l10n.browserCopyLink,
                onTap: _copyLink,
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: article != null ? _buildBottomBar(cs, l10n) : null,
      body: SafeArea(
        // top: false → 内容延伸到毛玻璃顶栏下方，滚动时才能看到模糊
        //（状态栏区域已由顶栏毛玻璃覆盖，不需要再垫高）
        // 玻璃底栏（extendBody）时 bottom: false → 正文延伸到栏后滚动，
        // 玻璃才有内容可折射/模糊（底部余量由滚动内容 spacer 提供）
        top: false,
        bottom: !(SettingsService.fragmentRenderingEnabled && article != null),
        child: _isWideScreen
            ? _buildWideLayout(cs, l10n)
            : _buildBody(cs, l10n),
      ),
    );

    // 整页 Hero：iOS 开 App 式放大到全屏（搜索专栏卡片 → 专栏阅读页）。
    // 与视频播放页同款：入场飞行结束后移除（_zoomHeroActive），
    // 解除对内层 Hero 的嵌套限制（封面/正文图片可独立飞行）；
    // 返回时由 PopScope 拦截先重新包裹再 pop。
    if (_usesZoomHero && _zoomHeroActive) {
      page = Hero(
        tag: widget.heroTag!,
        // 非线性飞行：入场 easeOutCubic（快起慢收，iOS 开 App 手感），
        // 返回 easeInCubic 镜像（慢起快收缩回卡片）
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        flightShuttleBuilder:
            (flightContext, animation, direction, fromContext, toContext) {
              final isPop = direction == HeroFlightDirection.pop;
              final target = isPop ? fromContext : toContext;
              final heroWidget = target.widget as Hero;
              // 运动过程保留卡片圆角（与搜索卡片 12px 圆角一致）
              const flightRadius = 12.0;
              // 卡片飞行期间新内容渐显（前段快速淡入，到站前全不透明）
              final fadeIn = CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
              );
              return AnimatedBuilder(
                animation: fadeIn,
                builder: (context, _) {
                  // push 中途被 pop 时 Hero 会复用原 shuttle，direction
                  // 仍是 push；按真实状态识别反向飞行，保持画面连续。
                  final returning =
                      isPop || animation.status == AnimationStatus.reverse;
                  // 页面始终按目标尺寸布局（避免飞行期间小矩形硬布局
                  // 导致 RenderFlex overflow），再用 FittedBox 缩放到
                  // 当前飞行矩形，呈现 iOS 开 App 式的整页放大效果。
                  final screen = MediaQuery.sizeOf(context);
                  final Widget flying;
                  if (isPop) {
                    // 返回：渲染目标卡片本体（封面 + 标题文字），按飞行矩形
                    // 自然布局——整个卡片一起运动，保留卡片自身圆角。
                    flying = (toContext.widget as Hero).child;
                  } else {
                    // 进入：按卡片比例裁剪整页内容，而不是压缩整页，
                    // 与 iOS 卡片展开的视觉方式一致。
                    flying = ClipRRect(
                      borderRadius: BorderRadius.circular(flightRadius),
                      clipBehavior: Clip.antiAlias,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(flightRadius),
                          child: SizedBox(
                            width: screen.width,
                            height: screen.height,
                            child: heroWidget.child,
                          ),
                        ),
                      ),
                    );
                  }
                  return Opacity(
                    // 返回时保持卡片不透明，避免飞行结束前淡到 0.35
                    // 后与真实卡片切换产生闪烁。
                    opacity: returning ? 1.0 : 0.35 + 0.65 * fadeIn.value,
                    child: flying,
                  );
                },
              );
            },
        child: HeroMode(enabled: false, child: page),
      );
    }

    // 整页 Hero 已移除时先重新包裹（恢复返回缩回动画）再 pop
    return PopScope(
      canPop: !_usesZoomHero || _zoomHeroActive,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (mounted && _usesZoomHero && !_zoomHeroActive) {
          setState(() => _zoomHeroActive = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
        }
      },
      child: page,
    );
  }

  /// 宽横屏分屏布局：左栏文章正文，右栏评论区（参考 B 站播放页宽屏布局）。
  Widget _buildWideLayout(ColorScheme cs, AppLocalizations l10n) {
    final rightWidth = (MediaQuery.of(context).size.width * 0.34).clamp(
      320.0,
      480.0,
    );
    final article = _article;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 左栏：文章正文（加载中 / 出错 / 无内容状态由 _buildBody 处理） ──
        Expanded(child: _buildBody(cs, l10n)),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: cs.outlineVariant.withOpacity(0.5),
        ),
        // ── 右栏：评论区 ──
        SizedBox(
          width: rightWidth,
          child: SafeArea(
            // 玻璃底栏（extendBody）时底部垫高到胶囊栏上方，
            // 评论列表最后一条不会被玻璃栏遮挡
            top: false,
            bottom: SettingsService.fragmentRenderingEnabled && article != null,
            child: Container(
              color: cs.surfaceContainer,
              child: article == null
                  ? _buildCommentsPlaceholder(cs, l10n)
                  : ArticleCommentsPanel(
                      cid: widget.cvid.toString(),
                      episodeTitle: article.title,
                    ),
            ),
          ),
        ),
      ],
    );
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

  Widget _buildBody(ColorScheme cs, AppLocalizations l10n) {
    if (_loading) {
      final heroTag = widget.heroTag;
      final coverUrl = widget.coverUrl;
      if (heroTag != null && coverUrl != null && coverUrl.isNotEmpty) {
        return _buildLoadingWithHero(cs, l10n, heroTag, coverUrl);
      }
      return const Center(child: LoadingIndicatorM3E());
    }
    final article = _article;
    if (article == null) {
      return _buildError(cs, l10n);
    }
    if (!article.isHtml && !article.isOps) {
      return _buildNoContent(cs, l10n);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: SelectionArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            if (article.cover.isNotEmpty)
              SliverToBoxAdapter(child: _buildCover(cs, article)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (article.title.isNotEmpty) _buildTitle(article, cs),
                  _buildAuthorRow(cs, l10n, article),
                  const SizedBox(height: 4),
                ]),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              sliver: SliverToBoxAdapter(
                child: ArticleContentBody(
                  html: article.isHtml ? article.contentHtml : null,
                  ops: article.isOps ? article.ops : null,
                  allImages: article.images,
                  onImageTap: _openImage,
                  onLinkTap: _openLink,
                  // 整页放大飞行期间禁用正文图片 Hero（避免 Hero 嵌套断言）
                  heroTagsDisabled: _usesZoomHero && _zoomHeroActive,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                // 玻璃底栏（extendBody + SafeArea bottom:false）时
                // MediaQuery 底部 padding 已包含底栏高度，正好用作滚动余量
                height: MediaQuery.of(context).padding.bottom + 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 加载中占位：入口封面带 Hero（与搜索页整卡同名 tag 触发飞入动画），
  /// 下方加载指示器；文章加载完成后替换为真实封面。
  /// 整页放大模式（_usesZoomHero）下不加内层 Hero：整页本身就是飞行 Hero，
  /// 内层 Hero 会触发「Hero 嵌套 Hero」断言（且返回重包裹时同样会嵌套）。
  Widget _buildLoadingWithHero(
    ColorScheme cs,
    AppLocalizations l10n,
    String heroTag,
    String coverUrl,
  ) {
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    final cover = Image(
      image: CachedImageProvider(coverUrl, headers: headers),
      width: double.infinity,
      fit: BoxFit.fitWidth,
      errorBuilder: (_, __, ___) => Container(
        height: 140,
        color: cs.surfaceContainerHighest,
        child: Icon(
          Icons.article_outlined,
          size: 40,
          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kGroupRadius),
            child: _usesZoomHero ? cover : Hero(tag: heroTag, child: cover),
          ),
        ),
        const Expanded(child: Center(child: LoadingIndicatorM3E())),
      ],
    );
  }

  Widget _buildCover(ColorScheme cs, BiliArticle article) {
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    // 走 CachedImageProvider：首图落盘缓存，下次查看直接读本地
    final coverImage = Image(
      image: CachedImageProvider(article.cover, headers: headers),
      width: double.infinity,
      fit: BoxFit.fitWidth,
      errorBuilder: (_, __, ___) => Container(
        height: 140,
        color: cs.surfaceContainerHighest,
        child: Icon(
          Icons.article_outlined,
          size: 40,
          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kGroupRadius),
        child: Stack(
          children: [
            // 整页放大飞行期间不加封面 Hero（避免 Hero 嵌套 Hero 断言），
            // 飞行结束后恢复（点击封面 → 大图查看器飞入）
            if (_usesZoomHero && _zoomHeroActive)
              coverImage
            else
              Hero(tag: articleCoverHeroTag(article.cover), child: coverImage),
            // 透明 Material + InkWell 覆盖层：点击时在封面上显示 ripple
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openImage(article.cover, article.images),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BiliArticle article, ColorScheme cs) {
    final title = _displayTitle(article);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.35,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _buildAuthorRow(
    ColorScheme cs,
    AppLocalizations l10n,
    BiliArticle article,
  ) {
    final author = article.author;
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    final dateText = _formatDate(article.publishTime);
    final stats = article.stats;
    final viewText = stats != null && stats.view > 0
        ? l10n.articleViews(_formatCount(stats.view))
        : '';
    final avatar = author != null && author.face.isNotEmpty
        ? ClipOval(
            child: SizedBox(
              width: 40,
              height: 40,
              child: Image.network(
                BilibiliArticleService.avatarUrl(author.face),
                fit: BoxFit.cover,
                headers: headers,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.surfaceContainerHighest,
                  child: Icon(
                    Icons.person_outline,
                    color: cs.onSurfaceVariant.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          )
        : Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              color: cs.onSurfaceVariant.withOpacity(0.4),
            ),
          );
    return InkWell(
      onTap: author != null ? _openAuthor : null,
      borderRadius: BorderRadius.circular(kItemPressedRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // 头像 Hero：与 BilibiliUserSpacePage 头部头像同 tag。
            // 整页放大飞行（_usesZoomHero && _zoomHeroActive）期间不加 Hero，
            // 否则返回时整页被重新包裹成 Hero 后，头像成为 Hero 的后代，
            // 触发「A Hero widget cannot be the descendant of another Hero」
            // 断言报错（与封面 Hero 同处理）。
            if (author != null &&
                author.mid > 0 &&
                !(_usesZoomHero && _zoomHeroActive))
              Hero(tag: 'bili_space_avatar_${author.mid}', child: avatar)
            else
              avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author?.name.isNotEmpty == true
                        ? author!.name
                        : l10n.articleAuthorUnknown,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  if (dateText.isNotEmpty || viewText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        [
                          dateText,
                          viewText,
                        ].where((s) => s.isNotEmpty).join(' · '),
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
            Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme cs, AppLocalizations l10n) {
    final stats = _article?.stats;
    final content = _buildArticleStatsContent(cs, stats);
    if (!SettingsService.fragmentRenderingEnabled) {
      final normalBar = Container(
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
      return _buildLongPressArticleBar(cs, stats, normalBar);
    }
    // 高级玻璃渲染开启：底部操作栏换成悬浮液态玻璃胶囊。
    final normalBar = Padding(
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
    return _buildLongPressArticleBar(cs, stats, normalBar);
  }

  Widget _buildLongPressArticleBar(
    ColorScheme cs,
    BiliArticleStats? stats,
    Widget normalBar,
  ) {
    return LongPressGlassTabSwitcher(
      child: normalBar,
      // 对齐常规态底栏内容区域：高级玻璃态 NaviGlass 胶囊左右各缩 16，
      // 非高级 Container 左右各缩 8。glass 浮层用同款 inset 才不会从
      // 屏幕边缘 0 开始而与胶囊错位。
      glassInset: SettingsService.fragmentRenderingEnabled
          ? const EdgeInsets.symmetric(horizontal: 16)
          : const EdgeInsets.symmetric(horizontal: 8),
      tabs: const [
        GlassTab(
          label: '阅读',
          icon: Icon(Icons.remove_red_eye_outlined),
          activeIcon: Icon(Icons.remove_red_eye),
        ),
        GlassTab(
          label: '点赞',
          icon: Icon(Icons.thumb_up_alt_outlined),
          activeIcon: Icon(Icons.thumb_up_alt),
        ),
        GlassTab(
          label: '收藏',
          icon: Icon(Icons.star_outline_rounded),
          activeIcon: Icon(Icons.star_rounded),
        ),
        GlassTab(
          label: '评论',
          icon: Icon(Icons.mode_comment_outlined),
          activeIcon: Icon(Icons.mode_comment),
        ),
        GlassTab(
          label: '转发',
          icon: Icon(Icons.share_outlined),
          activeIcon: Icon(Icons.share),
        ),
      ],
      selectedIndex: 0,
      onIndexChanged: (_) {},
      onSelectionEnd: _onLongPressBottomAction,
      barHeight: 52,
    );
  }

  Widget _buildArticleStatsContent(
    ColorScheme cs,
    BiliArticleStats? stats, {
    int? selectedIndex,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.remove_red_eye_outlined,
            text: _formatCount(stats?.view ?? 0),
            cs: cs,
            selected: selectedIndex == 0,
          ),
        ),
        Expanded(
          child: _StatItem(
            icon: Icons.thumb_up_alt_outlined,
            text: _formatCount(stats?.like ?? 0),
            cs: cs,
            selected: selectedIndex == 1,
          ),
        ),
        Expanded(
          child: _StatItem(
            icon: Icons.star_outline_rounded,
            text: _formatCount(stats?.favorite ?? 0),
            cs: cs,
            selected: selectedIndex == 2,
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: _openComments,
            borderRadius: BorderRadius.circular(12),
            child: _StatItem(
              icon: Icons.mode_comment_outlined,
              text: _formatCount(stats?.reply ?? 0),
              cs: cs,
              selected: selectedIndex == 3,
            ),
          ),
        ),
        Expanded(
          child: _StatItem(
            icon: Icons.share_outlined,
            text: _formatCount(stats?.share ?? 0),
            cs: cs,
            selected: selectedIndex == 4,
          ),
        ),
      ],
    );
  }

  Widget _buildError(ColorScheme cs, AppLocalizations l10n) {
    final detail = _error;
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: cs.onSurfaceVariant.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.articleLoadFailed,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              if (detail != null && detail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // 加载失败重试：右下角 Extended FAB（重新加载）
        PositionedRetryFab(
          onRetry: _load,
          bottomOffset: MediaQuery.paddingOf(context).bottom + 16,
        ),
      ],
    );
  }

  Widget _buildNoContent(ColorScheme cs, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.article_outlined,
            size: 56,
            color: cs.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.articleNoContent,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: _openBrowser,
            icon: const Icon(Icons.open_in_browser_outlined, size: 18),
            label: Text(l10n.articleOpenBrowser),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════
//  底部统计项
// ═════════════════════════════════════════

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;
  final bool selected;

  const _StatItem({
    required this.icon,
    required this.text,
    required this.cs,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 19,
          color: selected ? cs.primary : cs.onSurfaceVariant,
        ),
        const SizedBox(height: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : null,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
