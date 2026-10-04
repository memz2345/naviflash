                                
  
                                                        
                                                
                                           
                                                          
                                      
                                           
                             
                       
import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/tts_install_prompt.dart';
import 'tts_install_screen.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
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
import 'package:html/parser.dart' as html_parser;
import 'package:naviflash/services/tts_model_service.dart';
import 'package:naviflash/services/tts_speech_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/services/interaction_bar_service.dart';
import 'package:naviflash/widgets/article_content_view.dart';
import 'package:naviflash/widgets/comment/article_comments_panel.dart';
import 'package:naviflash/widgets/comment/comment_panel.dart';
import 'package:naviflash/widgets/comment/inline_comments_section.dart';
import 'package:naviflash/widgets/comment/comment_composer.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_zoom_hero.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/long_press_glass_tab_switcher.dart';
import 'package:naviflash/widgets/morph_widgets.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart' hide MorphIconButton;
import 'package:provider/provider.dart';
import 'browser_page.dart';
import 'image_viewer_page.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/hero_gesture_curve.dart';
import 'package:naviflash/widgets/zoom_hero_exit.dart';

                
   
                                                    
                                             
                                             
                                                           
class ArticlePage extends StatefulWidget implements ImmersivePageMarker {
  final int cvid;

                               
  final String? initialTitle;

                                    
                                 
  final String? heroTag;

                                   
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

                                       
  String _translatedTitle = '';

                                 
  String _displayTitle(BiliArticle article) =>
      _translatedTitle.isNotEmpty ? _translatedTitle : article.title;

  final ScrollController _scrollController = ScrollController();

                                      
  final GlobalKey _commentsKey = GlobalKey();

                       
  final InteractionBarService _interactionBar = InteractionBarService();

                                           
  bool _liked = false;
  int _likeCount = 0;
  bool _faved = false;
  int _favCount = 0;
  int _commentCount = 0;
  bool _interactionBusy = false;

                                                         
                          
  bool get _isWideScreen => MediaQuery.of(context).size.width >= 768;

                                               
  bool get _usesZoomHero =>
      widget.heroTag != null && SettingsService.heroTransitionBlurEnabled;

                                 
                                           
  bool _zoomHeroActive = true;

  Animation<double>? _routeAnimation;
  AnimationStatusListener? _routeAnimListener;

                                       
                                                      
                                                      
                                
  late final ZoomHeroBackDrag _backDrag = ZoomHeroBackDrag(
                                                 
                       
    canDrag: () => true,
    setHeroWrapped: (wrapped) {
      if (!_usesZoomHero || _zoomHeroActive == wrapped) return;
      setState(() => _zoomHeroActive = wrapped);
    },
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backDrag.attach(context);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
                                        
    _interactionBar.setHandlers(
      onWriteComment: _openComposer,
      onCommentsTap: _onCommentsTap,
      onLike: _toggleLike,
      onFavorite: _toggleFav,
      onForward: _share,
    );
    _load();
                                 
                                      
                                        
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
    _interactionBar.hide();
    _backDrag.detach();
    if (_routeAnimListener != null) {
      _routeAnimation?.removeStatusListener(_routeAnimListener!);
      _routeAnimListener = null;
    }
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
                                         
                                             
    unawaited(InteractionBarService.refresh());
    final show = _scrollController.offset > 240;
    if (show != _showAppBarTitle && mounted) {
      setState(() => _showAppBarTitle = show);
    }
  }

  Future<void> _load() async {
    setState(() {
                                       
                                         
      _loading = _article == null;
      _error = null;
    });
    final article = await BilibiliArticleService.fetchArticle(
      cvid: widget.cvid,
    );
    if (!mounted) return;
    if (article == null && _article != null) {
      setState(() => _loading = false);
      showAppToast(
        context,
        BilibiliArticleService.lastErrorDetail ??
            AppLocalizations.of(context).articleLoadFailed,
        error: true,
      );
      return;
    }
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
      final stats = article.stats;
      _likeCount = stats?.like ?? 0;
      _favCount = stats?.favorite ?? 0;
      _commentCount = stats?.reply ?? 0;
                                            
      final interaction = await BilibiliArticleService.fetchInteraction(
        cvid: widget.cvid,
      );
      if (!mounted) return;
      if (interaction != null) {
        _liked = interaction.liked;
        _faved = interaction.fav;
      }
      _refreshInteractionBar();
    }
  }

                   
  void _refreshInteractionBar() {
    final cs = Theme.of(context).colorScheme;
    _interactionBar.show(
      colorScheme: cs,
      writeLabel: '写评论',
      commentCount: _commentCount,
      likeCount: _likeCount,
      favoriteCount: _favCount,
      forwardCount: _article?.stats?.share ?? 0,
      liked: _liked,
      favorite: _faved,
    );
  }


                                  
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
                   
    }
  }

             

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
                                                      
                                            
    String norm(String u) => u.startsWith('//') ? 'https:$u' : u;
    final target = norm(url);
    final normalizedAll = [for (final u in all) norm(u)];
    var index = normalizedAll.indexOf(target);

                                 
    final List<String> urls;
    if (index >= 0) {
      urls = List.of(all);
    } else {
      index = 0;
      urls = [url, ...all];
    }

    final isCover = target == norm(_article?.cover ?? '');
                                            
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
                                                   
        heroZoom: sources[index].heroTag != null,
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

                
     
                                             
                                  
  static const int _maxReadChars = 1200;

                   
  Future<void> _readAloud() async {
    final l10n = AppLocalizations.of(context);
    final svc = TtsSpeechService.instance;
    final id = 'article_${widget.cvid}';

    final article = _article;
    if (article == null) return;

    final text = _plainTextOf(article.contentHtml);
    if (text.isEmpty) return;

    final clipped = text.length > _maxReadChars;
    final toSpeak =
        clipped ? text.substring(0, _maxReadChars) : text;

    try {
      await svc.speak(id, toSpeak);
      if (!mounted) return;
      if (clipped) {
        showAppToast(context, l10n.ttsTruncatedHint('$_maxReadChars'));
      }
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

                               
  static String _plainTextOf(String html) {
    if (html.trim().isEmpty) return '';
    final doc = html_parser.parse(html);
    final text = doc.body?.text ?? '';
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

                                   
  Future<void> _openComposer() async {
    final r = await showCommentComposer(
      context,
      oid: widget.cvid,
      type: 12,
      sourceTitle: _article?.title ?? widget.initialTitle ?? '',
      sourceId: widget.cvid.toString(),
    );
    if (r.sent) {
                   
      final state = _commentsKey.currentState;
      if (state is InlineCommentsSectionState) state.reload();
      setState(() => _commentCount++);
      _refreshInteractionBar();
    }
  }

                                          
  void _onCommentsTap() {
    final ctx = _commentsKey.currentContext;
    final ro = ctx?.findRenderObject();
    if (ro != null && _scrollController.hasClients) {
      final viewport = RenderAbstractViewport.of(ro);
      final target = viewport.getOffsetToReveal(ro, 0).offset;
      if (_scrollController.position.pixels < target - 2) {
        _scrollController.position.animateTo(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
        return;
      }
    }
    _openComposer();
  }

                                     
  Future<void> _toggleLike() async {
    final article = _article;
    if (article == null || _interactionBusy) return;
    final target = !_liked;
    _interactionBusy = true;
    final res = await BilibiliArticleService.like(
      dynIdStr: article.dynIdStr,
      like: target,
    );
    if (!mounted) return;
    _interactionBusy = false;
    if (res.ok) {
      setState(() {
        _liked = target;
        _likeCount = (_likeCount + (target ? 1 : -1)).clamp(0, 1 << 31);
      });
      _refreshInteractionBar();
    } else {
      showAppToast(context, res.message, error: true);
    }
  }

                                   
  Future<void> _toggleFav() async {
    if (_interactionBusy) return;
    final target = !_faved;
    _interactionBusy = true;
    final res = await BilibiliArticleService.setFavorite(
      cvid: widget.cvid,
      fav: target,
    );
    if (!mounted) return;
    _interactionBusy = false;
    if (res.ok) {
      setState(() {
        _faved = target;
        _favCount = (_favCount + (target ? 1 : -1)).clamp(0, 1 << 31);
      });
      _refreshInteractionBar();
    } else {
      showAppToast(context, res.message, error: true);
    }
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
        showCommentPanel(
          context,
          cid: widget.cvid.toString(),
          episodeTitle: _article?.title ?? '',
          commentType: '12',
        );
      case 4:
        _share();
    }
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

             

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final article = _article;
    Widget page = Scaffold(
      backgroundColor: cs.surfaceContainer,
      extendBodyBehindAppBar: true,
                                         
                                     
                                      
      extendBody:
          article != null &&
          (InteractionBarService.isSupported ||
              SettingsService.fragmentRenderingEnabled),
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
          ListenableBuilder(
            listenable: TtsSpeechService.instance,
            builder: (ctx, _) {
              final speaking =
                  TtsSpeechService.instance.isActive('article_${widget.cvid}');
              return LiquidGlassMenuButton(
                icon: Icons.more_vert,
                tooltip: l10n.articleShare,
                menuWidth: 220,
                actions: [
                  GlassMenuAction(
                    icon: speaking
                        ? Icons.stop_circle_outlined
                        : Icons.record_voice_over_outlined,
                    text: speaking ? l10n.ttsReadAloudStop : l10n.ttsReadAloud,
                    onTap: _readAloud,
                  ),
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
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
                                           
                          
      bottomNavigationBar:
          InteractionBarService.isSupported || article == null
              ? null
              : _buildBottomBar(cs, l10n),
      body: SafeArea(
                                              
                                 
                                                        
                                            
        top: false,
        bottom: false,
        child: _isWideScreen
            ? _buildWideLayout(cs, l10n)
            : _buildBody(cs, l10n),
      ),
    );

                                                
                                           
                                      
                                  
    if (_usesZoomHero && _zoomHeroActive) {
                                                  
                                     
                                      
                                    
      final Curve? gestureCurve = HeroGestureCurve.curveOrNull(context);
      page = Hero(
        transitionOnUserGestures: true,
        tag: widget.heroTag!,
        curve: gestureCurve ?? Curves.easeOutCubic,
        reverseCurve: gestureCurve ?? Curves.easeInCubic,
                                          
                                             
        placeholderBuilder: _backDrag.placeholder,
                                                            
                                                      
                                                           
                                                 
                                               
        flightShuttleBuilder:
            (flightContext, animation, direction, fromContext, toContext) {
              final isPop = direction == HeroFlightDirection.pop;
              final target = isPop ? fromContext : toContext;
              final heroWidget = target.widget as Hero;
                                            
              const flightRadius = 12.0;
                                            
              final fadeIn = CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
              );
              return AnimatedBuilder(
                animation: fadeIn,
                builder: (context, _) {
                                                               
                                                
                  final returning =
                      isPop || animation.status == AnimationStatus.reverse;
                                             
                                                             
                                                  
                  final screen = MediaQuery.sizeOf(context);
                  final Widget flying;
                  if (isPop) {
                                                   
                                               
                    flying = (toContext.widget as Hero).child;
                  } else {
                                              
                                         
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
                                                
                                    
                    opacity: returning ? 1.0 : 0.35 + 0.65 * fadeIn.value,
                    child: flying,
                  );
                },
              );
            },
                                                     
                                                         
                                                  
        child: KeyedSubtree(
          key: _backDrag.bodyKey,
          child: ZoomHeroScope(
                                               
                                           
            active: _usesZoomHero && _zoomHeroActive,
            child: HeroMode(enabled: false, child: page),
          ),
        ),
      );
    }

                                       
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

                                          
  Widget _buildWideLayout(ColorScheme cs, AppLocalizations l10n) {
    final rightWidth = (MediaQuery.of(context).size.width * 0.34).clamp(
      320.0,
      480.0,
    );
    final article = _article;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                                                         
        Expanded(child: _buildBody(cs, l10n)),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
                       
        SizedBox(
          width: rightWidth,
          child: SafeArea(
                                           
                               
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
    return AppRefreshIndicator(
      onRefresh: _load,
      child: SelectionArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: AppRefreshScrollPhysics(),
          ),
          slivers: [
                                             
                                                    
                                                                 
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).top + kToolbarHeight,
              ),
            ),
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: ArticleContentBody(
                  html: article.isHtml ? article.contentHtml : null,
                  ops: article.isOps ? article.ops : null,
                  allImages: article.images,
                  onImageTap: _openImage,
                  onLinkTap: _openLink,
                                                      
                  heroTagsDisabled: _usesZoomHero && _zoomHeroActive,
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
                      cid: article.id.toString(),
                      commentType: '12',
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
                                         
        SizedBox(
          height: MediaQuery.paddingOf(context).top + kToolbarHeight,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kGroupRadius),
            child: _usesZoomHero ? cover : Hero(transitionOnUserGestures: true, tag: heroTag, child: cover),
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
                                                     
                                      
            if (_usesZoomHero && _zoomHeroActive)
              coverImage
            else
              Hero(transitionOnUserGestures: true, tag: articleCoverHeroTag(article.cover), child: coverImage),
                                                         
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
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
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
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          );
    return InkWell(
      onTap: author != null ? _openAuthor : null,
      borderRadius: BorderRadius.circular(kItemPressedRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
                                                         
                                                                 
                                                  
                                                                         
                                  
            if (author != null &&
                author.mid > 0 &&
                !(_usesZoomHero && _zoomHeroActive))
              Hero(transitionOnUserGestures: true, tag: 'bili_space_avatar_${author.mid}', child: avatar)
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
      return _buildLongPressArticleBar(cs, stats, normalBar);
    }
                                
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
      child: normalBar,
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
            onTap: () => showCommentPanel(
              context,
              cid: widget.cvid.toString(),
              episodeTitle: _article?.title ?? '',
              commentType: '12',
            ),
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
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.articleLoadFailed,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
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
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
                                        
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
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.articleNoContent,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
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
