import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/fans_medal_badge.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/pendant_avatar.dart';
import 'package:naviflash/widgets/user_level_icon.dart';
import 'article_page.dart';
import 'bilibili_bangumi_page.dart';
import 'bilibili_live_room_page.dart';
import 'bilibili_video_page.dart';
import 'browser_page.dart';
import 'dynamic_detail_page.dart';
import 'image_viewer_page.dart';

enum _VideoLayout { single, grid, waterfall }

class BilibiliUserSpacePage extends StatefulWidget {
  final int mid;

  /// 从视频页作者点击进入时传入的源视频 BV —— 用于定位到「上次观看」的视频
  ///（自动切到视频 tab 并把该视频滚动到可见位置并高亮）。
  final String? focusBvid;

  const BilibiliUserSpacePage({super.key, required this.mid, this.focusBvid});

  @override
  State<BilibiliUserSpacePage> createState() => _BilibiliUserSpacePageState();
}

class _BilibiliUserSpacePageState extends State<BilibiliUserSpacePage>
    with TickerProviderStateMixin {
  /// 头部背景展开高度：参考 PiliPlus 头图（约 135px 横幅）压缩为横向较长横幅，
  /// 让背景图以「较长」比例显示在最上方（kToolbarHeight + 横幅 ≈ 220）。
  static const double _expandedHeight = 220.0;
  static const double _avatarRadius = 46.0;
  static const double _tabBarHeight = 48.0;

  /// 头像向上突出的高度（占据一点点背景图空间的偏移）。
  static const double _avatarProtrude = 24.0;

  late final TabController _tabController;

  /// 头部背景缩放（下拉回弹放大 + 上滑收起轻微放大，iOS 头图观感）。
  final ValueNotifier<double> _bgZoom = ValueNotifier(1.0);
  final ScrollController _scrollController = ScrollController();

  /// 下拉刷新指示器（点击当前 Tab 已到最顶端时用 show() 调出加载器）。
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  /// NestedScrollView 的 key：经由其 innerController 判断 / 回顶当前 Tab 内容。
  final GlobalKey<NestedScrollViewState> _nestedKey =
      GlobalKey<NestedScrollViewState>();

  BiliUserSpaceCard? _card;
  List<BiliUserVideo> _videos = [];
  int _videoCount = 0;

  /// 视频布局模式。
  _VideoLayout _videoLayout = _VideoLayout.grid;
  int _prevGridCols = 0;
  int _prevItemCount = 0;
  String? _prevFirstVideoBvid;
  late final AnimationController _gridRowAnimCtrl;
  final Map<int, Offset> _itemTranslations = {};
  int _videoPage = 1; // 当前已加载的页码
  bool _videoLoadingMore = false;
  bool _videoHasMore = true;

  /// 上次观看定位：待定位的 bvid（来自视频页作者点击），以及是否已执行过。
  String? _focusBvid;
  bool _focusApplied = false;
  final Map<String, GlobalKey> _videoCardKeys = {};

  List<BiliUserDynamic> _dynamics = [];
  String? _dynError;
  String _dynOffset = ''; // 下一页游标（空表示无更多）
  bool _dynLoadingMore = false;
  bool _dynHasMore = true;
  ({String light, String dark})? _banner;
  BiliUserBangumiPage? _bangumiPage;
  String? _bangumiError;
  bool _bangumiLoading = false;
  bool _bangumiStarted = false;
  bool _loading = true;
  bool _isRefreshing = false;
  String? _error;

  String get _avatarHeroTag => 'bili_space_avatar_${widget.mid}';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _gridRowAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _gridRowAnimCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _itemTranslations.clear();
      }
    });
    _scrollController.addListener(_onScroll);
    _load();
  }

  /// 背景缩放：下拉回弹时放大背景；上滑收起时轻微放大。
  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final pixels = _scrollController.position.pixels;
    const collapse = _expandedHeight - kToolbarHeight;
    double zoom = 1.0;
    if (pixels < 0) {
      // 顶部下拉回弹（BouncingScrollPhysics）：随拉伸放大，最多 +60%
      zoom += -pixels / _expandedHeight * 0.6;
    } else {
      // 上滑收起：随收起进度轻微放大，最多 +10%
      final t = (pixels / collapse).clamp(0.0, 1.0);
      zoom += t * 0.10;
    }
    zoom = zoom.clamp(1.0, 1.6);
    if ((zoom - _bgZoom.value).abs() > 0.001) {
      _bgZoom.value = zoom;
    }
  }

  void _onTabChanged() {
    if (_tabController.index == 3 && !_bangumiStarted) {
      _loadBangumi();
    }
  }

  /// 点击 Tab：切换由 TabBar 内部处理；「点击当前 Tab」时——
  ///  - 未到页面最顶端 → 头图 + 当前 Tab 内容一起回到最顶端
  ///  - 已是最顶端 → 用 show() 调出下拉加载器并刷新（无需手动下拉）
  void _onTabTap(int index) {
    if (index != _tabController.index) return;
    final outer = _scrollController;
    final inner = _nestedKey.currentState?.innerController;

    final outerNotTop = outer.hasClients && outer.offset > 0;
    final innerNotTop = inner != null && inner.hasClients && inner.offset > 0;

    if (outerNotTop || innerNotTop) {
      final futures = <Future<void>>[];
      if (outerNotTop) {
        futures.add(
          outer.animateTo(
            0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          ),
        );
      }
      if (innerNotTop) {
        futures.add(
          inner.animateTo(
            0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          ),
        );
      }
      return;
    }
    // 已最顶端：显示下拉加载器并刷新
    _refreshKey.currentState?.show();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bgZoom.dispose();
    _tabController.dispose();
    _gridRowAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    // 下拉刷新时若已有内容则保留界面（避免整页闪回加载圈），仅静默重拉
    final hasContent =
        _card != null || _videos.isNotEmpty || _dynamics.isNotEmpty;
    setState(() {
      if (!refresh || !hasContent) {
        _loading = true;
      }
      _error = null;
    });
    List<Object?> results;
    try {
      results = await Future.wait([
        BilibiliUserSpaceService.fetchUserCard(mid: widget.mid),
        BilibiliUserSpaceService.fetchUserVideos(mid: widget.mid),
        BilibiliUserSpaceService.fetchUserBanner(mid: widget.mid),
        BilibiliUserSpaceService.fetchUserDynamics(mid: widget.mid),
      ]);
    } catch (e) {
      // 单个请求异常不应拖垮整个页面
      debugPrint('[UserSpace] 并行加载异常: $e');
      results = [null, null, null, null];
    }
    if (!mounted) return;
    final card = results[0] as BiliUserSpaceCard?;
    final videos = results[1] as BiliUserVideoPage?;
    final banner = results[2] as ({String light, String dark})?;
    final dynamics = results[3] as BiliUserDynamicPage?;
    if (card == null && videos == null && dynamics == null) {
      setState(() {
        _loading = false;
        _error =
            BilibiliUserSpaceService.lastErrorDetail ??
            AppLocalizations.of(context).userSpaceLoadFailed;
      });
      return;
    }
    var videoList = videos?.videos ?? [];
    if (videoList.isEmpty) {
      videoList = _extractVideosFromDynamics(dynamics?.items ?? []);
    }
    setState(() {
      _card = card;
      _videos = videoList;
      _videoCount = videos?.count ?? videoList.length;
      // 视频接口成功且总数大于首屏条数时允许继续翻页；
      // 从动态兜底提取时（videos == null）不允许翻页（后续页无对应数据源）。
      _videoPage = 1;
      _videoLoadingMore = false;
      _videoHasMore =
          videos != null &&
          videoList.isNotEmpty &&
          videoList.length < _videoCount;
      _dynamics = dynamics?.items ?? [];
      _dynOffset = dynamics?.offset ?? '';
      _dynLoadingMore = false;
      _dynHasMore = (dynamics?.hasMore ?? false) && (_dynOffset.isNotEmpty);
      _dynError = dynamics == null
          ? BilibiliUserSpaceService.lastErrorDetail
          : null;
      _banner = banner;
      _loading = false;
    });
    _applyFocusIfNeeded();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      await _load(refresh: true);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  /// （单列 / 瀑布流）定位卡片的 GlobalKey：首次访问时创建。
  GlobalKey _videoFocusKey(String bvid) =>
      _videoCardKeys.putIfAbsent(bvid, GlobalKey.new);

  /// 当前视频是否为「上次观看」定位目标。
  bool _isFocusVideo(String bvid) => _focusBvid != null && bvid == _focusBvid;

  /// 单列 / 瀑布流定位包装：给目标卡片挂 key 并渲染高亮描边。
  Widget _listHighlightWrap(String bvid, Widget child) {
    if (bvid.isEmpty) return child;
    final key = _videoFocusKey(bvid);
    if (!_isFocusVideo(bvid)) return KeyedSubtree(key: key, child: child);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, t, c) => KeyedSubtree(
        key: key,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(
                alpha: (t * 0.95).clamp(0.0, 1.0),
              ),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.35 * t),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: c,
        ),
      ),
    );
  }

  /// 定位「上次观看」视频（来自视频页作者点击）：自动切到视频 tab 并高亮、
  /// 尽量滚动到该视频可见处。只执行一次。
  void _applyFocusIfNeeded() {
    if (_focusApplied) return;
    final focusBvid = widget.focusBvid;
    if (focusBvid == null || focusBvid.isEmpty) return;
    final idx = _videos.indexWhere((v) => v.bvid == focusBvid);
    if (idx < 0) return;
    _focusApplied = true;
    _focusBvid = focusBvid;
    // 切到视频 tab（index 2）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tabController.animateTo(2);
      // 网格列数用于估算目标卡片纵向偏移（Scrollable.ensureVisible 兜底）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final key = _videoCardKeys[focusBvid];
        final ctx = key?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            alignment: 0.5,
          );
        }
        setState(() {}); // 刷新以绘制高亮
      });
    });
  }

  /// 从动态条目中提取投稿视频（MAJOR_TYPE_ARCHIVE），供视频接口失败时兜底。
  List<BiliUserVideo> _extractVideosFromDynamics(List<BiliUserDynamic> items) {
    final result = <BiliUserVideo>[];
    for (final dyn in items) {
      if (dyn.bvid.isEmpty && dyn.aid <= 0) continue;
      // 动态 module_stat 已有 like/comment，播放数缺失则填 0
      result.add(
        BiliUserVideo(
          bvid: dyn.bvid,
          title: dyn.title,
          pic: dyn.cover,
          author: _card?.name ?? '',
          mid: widget.mid,
          play: 0,
          danmaku: 0,
          duration: 0,
          created: dyn.pubTs,
        ),
      );
    }
    return result;
  }

  Future<void> _retryDynamics() async {
    setState(() {
      _dynError = null;
      _dynamics = [];
      _dynOffset = '';
      _dynHasMore = true;
    });
    final page = await BilibiliUserSpaceService.fetchUserDynamics(
      mid: widget.mid,
    );
    if (!mounted) return;
    setState(() {
      _dynamics = page?.items ?? [];
      _dynOffset = page?.offset ?? '';
      _dynHasMore = (page?.hasMore ?? false) && (page?.offset ?? '').isNotEmpty;
      _dynError = page == null
          ? BilibiliUserSpaceService.lastErrorDetail
          : null;
    });
  }

  Future<void> _loadMoreVideos() async {
    if (_videoLoadingMore || !_videoHasMore || _videos.isEmpty) return;
    setState(() => _videoLoadingMore = true);
    final page = await BilibiliUserSpaceService.fetchUserVideos(
      mid: widget.mid,
      pn: _videoPage + 1,
    );
    if (!mounted) return;
    setState(() {
      _videoLoadingMore = false;
      // 请求失败时保留 hasMore，滚动到底部可再次重试；
      // 返回空页说明没有更多数据，停止翻页。
      if (page == null) return;
      if (page.videos.isEmpty) {
        _videoHasMore = false;
        return;
      }
      _videoPage += 1;
      _videos.addAll(page.videos);
      _videoHasMore = _videos.length < _videoCount;
    });
  }

  Future<void> _loadMoreDynamics() async {
    if (_dynLoadingMore || !_dynHasMore || _dynOffset.isEmpty) return;
    setState(() => _dynLoadingMore = true);
    final page = await BilibiliUserSpaceService.fetchUserDynamics(
      mid: widget.mid,
      offset: _dynOffset,
    );
    if (!mounted) return;
    setState(() {
      _dynLoadingMore = false;
      // 请求失败时保留 hasMore，滚动到底部可再次重试；
      // 返回空页说明没有更多数据，停止翻页。
      if (page == null) return;
      if (page.items.isEmpty) {
        _dynHasMore = false;
        return;
      }
      _dynamics.addAll(page.items);
      _dynOffset = page.offset;
      _dynHasMore = page.hasMore && page.offset.isNotEmpty;
    });
  }

  /// 底部加载更多指示器：加载中显示转圈，无更多显示提示（与搜索结果页同款）。
  Widget _buildLoadMoreFooter({required bool loading, required bool hasMore}) {
    final cs = Theme.of(context).colorScheme;
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: LoadingIndicatorM3E()),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            AppLocalizations.of(context).searchAllLoaded,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }

  /// 加载追番列表（type=1 番剧；为空表示该用户没有追番）。
  Future<void> _loadBangumi() async {
    if (_bangumiLoading || _bangumiStarted && _bangumiPage != null) return;
    setState(() {
      _bangumiStarted = true;
      _bangumiLoading = true;
      _bangumiError = null;
    });
    final page = await BilibiliUserSpaceService.fetchUserBangumi(
      mid: widget.mid,
    );
    if (!mounted) return;
    setState(() {
      _bangumiPage = page;
      _bangumiLoading = false;
      _bangumiError = page == null
          ? BilibiliUserSpaceService.lastErrorDetail
          : null;
    });
  }

  /// 查看头像大图：下载原图字节 → ImageViewerPage（Hero 飞入）。
  Future<void> _openAvatarViewer() async {
    final url = _card?.face ?? '';
    if (url.isEmpty) return;
    final bytes = await BilibiliUserSpaceService.fetchBytes(url);
    if (!mounted) return;
    if (bytes == null) {
      showAppToast(
        context,
        AppLocalizations.of(context).userSpaceAvatarLoadFailed,
        error: true,
      );
      return;
    }
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      heroTransitionRoute(
        page: ImageViewerPage(imageBytes: bytes, heroTag: _avatarHeroTag),
      ),
    );
  }

  /// 打开原生动态详情查看器。
  void _openDynamicDetail(BiliUserDynamic dyn) {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DynamicDetailPage(id: dyn.idStr)));
  }

  /// 打开「主页搜索」：搜索该 UP 主投稿（参考 PiliPlus 空间搜索）。
  void _openSearch(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _MemberSearchPage(mid: widget.mid, upName: _card?.name ?? ''),
      ),
    );
  }

  // ═════════════════════════════════════
  //  构建
  // ═════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      // 下拉刷新：任意 Tab 内容处于顶部时下拉均可触发（NestedScrollView
      // 的滚动通知会冒泡到外层 RefreshIndicator；已有内容时静默重拉不闪加载圈）
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _handleRefresh,
        child: NestedScrollView(
          key: _nestedKey,
          controller: _scrollController,
          physics: (_loading || _isRefreshing)
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: _expandedHeight,
              pinned: true,
              stretch: true,
              stretchTriggerOffset: 60,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              leading: MorphIconButton(
                icon: Icons.arrow_back,
                tooltip: l10n.commonBackTooltip,
                onTap: () => Navigator.pop(context),
              ),
              actions: [
                // ── 主页搜索：搜索该 UP 主的投稿（参考 PiliPlus 空间搜索）──
                MorphIconButton(
                  icon: Icons.search,
                  tooltip: '搜索投稿',
                  onTap: () => _openSearch(context),
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final safeTop = MediaQuery.of(context).padding.top;
                  final currentHeight = constraints.biggest.height;
                  final isCollapsed =
                      currentHeight <= kToolbarHeight + safeTop + 1;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // ── 1. 背景图层：头像模糊 + 渐变遮罩（不可点击），
                      //        带滚动缩放效果 ──
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ValueListenableBuilder<double>(
                            valueListenable: _bgZoom,
                            builder: (context, zoom, _) => Transform.scale(
                              scale: zoom,
                              alignment: Alignment.topCenter,
                              child: _buildBackground(cs),
                            ),
                          ),
                        ),
                      ),
                      // ── 2. 底部渐变遮罩 ──
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 180,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.65),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ── 3. 展开态内容 ──
                      AnimatedOpacity(
                        opacity: isCollapsed ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(
                          ignoring: isCollapsed,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 整体上移让头像顶部略微突出、占据一点点背景图空间
                              //（参考 PiliPlus 头像压住头图上缘的观感）。
                              Transform.translate(
                                offset: const Offset(0, -_avatarProtrude),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: _buildHeaderInfo(cs),
                                ),
                              ),
                              const SizedBox(height: _avatarProtrude + 8),
                            ],
                          ),
                        ),
                      ),
                      // ── 4. 折叠态毛玻璃 ──
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedOpacity(
                          opacity: isCollapsed ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: ClipRect(
                            child: SizedBox(
                              height: kToolbarHeight + safeTop,
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 12,
                                  sigmaY: 12,
                                ),
                                child: Container(
                                  color: cs.surface.withOpacity(
                                    isDark ? 0.75 : 0.65,
                                  ),
                                  alignment: Alignment.bottomLeft,
                                  padding: EdgeInsets.only(
                                    left: 72,
                                    bottom: 12,
                                  ),
                                  child: Text(
                                    _card?.name ?? l10n.userSpaceTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // ── 吸顶 TabBar：主页 / 动态 / 视频 ──
            if (!_loading && _card != null)
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedTabBarDelegate(
                  tabController: _tabController,
                  onTabTap: _onTabTap,
                ),
              ),
          ],
          body: _buildBody(cs),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) {
      return CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoadingIndicatorM3E(),
                  const SizedBox(height: 14),
                  Text(
                    AppLocalizations.of(context).userSpaceLoading,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_error != null && _card == null) {
      return CustomScrollView(
        physics: _isRefreshing
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 56,
                    color: cs.onSurface.withOpacity(0.25),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).userSpaceLoadFailed,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  if (_error != null && _error!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(AppLocalizations.of(context).scanRetry),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildHomeTab(cs),
        _buildDynamicTab(cs),
        _buildVideoTab(cs),
        _buildBangumiTab(cs),
      ],
    );
  }

  /// 主页 Tab：统计 + 最新投稿预览。
  Widget _buildHomeTab(ColorScheme cs) {
    final card = _card;
    final l10n = AppLocalizations.of(context);
    final preview = _videos.take(4).toList();
    return CustomScrollView(
      physics: _isRefreshing
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        // ── 粉丝 / 关注 / 视频 / 获赞 ──
        if (card != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MorphItem(
                selected: false,
                interactive: false,
                isFirst: true,
                isLast: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _buildStatItem(cs, l10n.userSpaceStatFans, card.fans),
                      _buildStatDivider(cs),
                      _buildStatItem(
                        cs,
                        l10n.userSpaceStatFollowing,
                        card.following,
                      ),
                      _buildStatDivider(cs),
                      _buildStatItem(
                        cs,
                        l10n.userSpaceStatVideos,
                        card.archiveCount,
                      ),
                      _buildStatDivider(cs),
                      _buildStatItem(cs, l10n.userSpaceStatLikes, card.likeNum),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            cs,
            l10n.userSpaceStatVideos,
            count: _videoCount,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (preview.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  l10n.userSpaceNoVideos,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ),
            ),
          )
        else
          _buildVideoGrid(preview),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
        ),
      ],
    );
  }

  /// 动态 Tab：动态列表（封面 + 标题 + 正文 + 点赞/评论）。
  Widget _buildDynamicTab(ColorScheme cs) {
    if (_dynError != null && _dynamics.isEmpty) {
      return ListView(
        physics: _isRefreshing
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: cs.onSurface.withOpacity(0.25),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              AppLocalizations.of(context).userSpaceDynLoadFailed,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          if (_dynError != null && _dynError!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _dynError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Center(
            child: FilledButton.icon(
              onPressed: _retryDynamics,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppLocalizations.of(context).scanRetry),
            ),
          ),
        ],
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 300) {
          _loadMoreDynamics();
        }
        return false;
      },
      child: ListView(
        physics: _isRefreshing
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 32,
        ),
        children: [
          if (_dynamics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).userSpaceNoDynamics,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ),
            )
          else ...[
            for (final dyn in _dynamics)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DynamicCard(
                  item: dyn,
                  ownerName: _card?.name,
                  ownerFace: _card?.face,
                  onTap: dyn.idStr.isEmpty
                      ? null
                      : () => _openDynamicDetail(dyn),
                ),
              ),
            _buildLoadMoreFooter(
              loading: _dynLoadingMore,
              hasMore: _dynHasMore,
            ),
          ],
        ],
      ),
    );
  }

  /// 视频 Tab：全部投稿（多列网格 / 单列列表可切换，与搜索结果同款）。
  Widget _buildVideoTab(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 300) {
          _loadMoreVideos();
        }
        return false;
      },
      child: CustomScrollView(
        physics: _isRefreshing
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              cs,
              l10n.userSpaceSectionAllVideos,
              count: _videoCount,
              trailing: _buildVideoLayoutToggle(cs, l10n),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (_videos.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    l10n.userSpaceNoVideos,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            )
          else if (_videoLayout == _VideoLayout.grid)
            _buildVideoGrid(_videos, animate: true)
          else if (_videoLayout == _VideoLayout.waterfall)
            _buildVideoWaterfall(_videos)
          else
            _buildVideoList(_videos),
          SliverToBoxAdapter(
            child: _buildLoadMoreFooter(
              loading: _videoLoadingMore,
              hasMore: _videoHasMore,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
          ),
        ],
      ),
    );
  }

  /// 追番 Tab：追番列表（3 列海报网格，懒加载）。
  Widget _buildBangumiTab(ColorScheme cs) {
    if (_bangumiLoading && _bangumiPage == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: LoadingIndicatorM3E(),
        ),
      );
    }
    if (_bangumiError != null && _bangumiPage == null) {
      return ListView(
        physics: _isRefreshing
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: cs.onSurface.withOpacity(0.25),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              AppLocalizations.of(context).userSpaceBangumiLoadFailed,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          if (_bangumiError != null && _bangumiError!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _bangumiError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Center(
            child: FilledButton.icon(
              onPressed: () {
                setState(() {
                  _bangumiStarted = false;
                  _bangumiPage = null;
                  _bangumiError = null;
                });
                _loadBangumi();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppLocalizations.of(context).scanRetry),
            ),
          ),
        ],
      );
    }
    final bangumi = _bangumiPage;
    if (bangumi == null || bangumi.items.isEmpty) {
      return ListView(
        physics: _isRefreshing
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.video_library_outlined,
            size: 48,
            color: cs.onSurface.withOpacity(0.25),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              AppLocalizations.of(context).userSpaceNoBangumi,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    }
    return CustomScrollView(
      physics: _isRefreshing
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.video_library_outlined, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(
                    context,
                  ).userSpaceBangumiCount(bangumi.total),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 170,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.5,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final bangumi = _bangumiPage!.items[index];
              return _BangumiCard(
                item: bangumi,
                heroTag: bangumi.seasonId > 0
                    ? 'bili_bangumi_${bangumi.seasonId}'
                    : null,
                onTap: bangumi.seasonId > 0
                    ? () => openBilibiliBangumi(
                        context,
                        seasonId: bangumi.seasonId,
                        initialTitle: bangumi.title,
                        initialCover: BilibiliUserSpaceService.bangumiCoverUrl(
                          bangumi.cover,
                        ),
                        heroTag: 'bili_bangumi_${bangumi.seasonId}',
                      )
                    : null,
              );
            }, childCount: _bangumiPage!.items.length),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
        ),
      ],
    );
  }

  /// 分区标题（视频 / 全部视频）。
  Widget _buildSectionHeader(
    ColorScheme cs,
    String title, {
    required int count,
    Widget? trailing,
  }) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(Icons.video_library_outlined, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$title${count > 0 ? ' · ${l10n.userSpaceVideoCount(count)}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  /// 检测视频网格布局变化并启动行平移动画。
  void _checkGridLayoutChange(int cols, int count, double cellW, double cellH) {
    if (_prevGridCols == 0) {
      _prevGridCols = cols;
      _prevItemCount = count;
      if (count > 0) _prevFirstVideoBvid = _videos[0].bvid;
      return;
    }
    if (_prevGridCols == cols && _prevItemCount == count) return;
    if (count == 0 || _prevItemCount == 0) {
      _prevGridCols = cols;
      _prevItemCount = count;
      if (count > 0) _prevFirstVideoBvid = _videos[0].bvid;
      return;
    }

    final oldCols = _prevGridCols;
    final newCols = cols;
    final minCount = _prevItemCount < count ? _prevItemCount : count;
    final newFirstBvid = _videos[0].bvid;

    // 完全替换（重新加载）：不播放动画
    if (_prevFirstVideoBvid != null && _prevFirstVideoBvid != newFirstBvid) {
      _itemTranslations.clear();
      _prevGridCols = cols;
      _prevItemCount = count;
      _prevFirstVideoBvid = newFirstBvid;
      return;
    }

    _itemTranslations.clear();
    bool anyMoved = false;
    for (int i = 0; i < minCount; i++) {
      final oldRow = i ~/ oldCols;
      final oldCol = i % oldCols;
      final newRow = i ~/ newCols;
      final newCol = i % newCols;
      if (oldRow != newRow || oldCol != newCol) {
        anyMoved = true;
        _itemTranslations[i] = Offset(
          (oldCol - newCol) * cellW,
          (oldRow - newRow) * cellH,
        );
      }
    }

    _prevGridCols = cols;
    _prevItemCount = count;
    _prevFirstVideoBvid = newFirstBvid;

    if (anyMoved) {
      _gridRowAnimCtrl.reset();
      _gridRowAnimCtrl.forward();
    }
  }

  /// 视频网格（自适应多列，与搜索结果同款：最少 2 列，宽屏更多列）。
  Widget _buildVideoGrid(List<BiliUserVideo> videos, {bool animate = false}) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = (width / 200).floor().clamp(2, 8);

          if (animate) {
            final cardW = (width - (columns - 1) * 12) / columns;
            final cellW = cardW + 12;
            final cellH = cardW / 0.78 + 12;
            _checkGridLayoutChange(columns, videos.length, cellW, cellH);
          }

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final video = videos[index];
              if (animate) {
                return ListenableBuilder(
                  listenable: _gridRowAnimCtrl,
                  builder: (context, _) {
                    final t = Curves.easeInOut.transform(
                      _gridRowAnimCtrl.value,
                    );
                    final delta = _itemTranslations[index];
                    Widget card = _VideoCard(
                      video: video,
                      heroTag: 'bili_video_${video.bvid}',
                      cardKey: _videoFocusKey(video.bvid),
                      highlight: _isFocusVideo(video.bvid),
                      onTap: video.bvid.isEmpty
                          ? null
                          : () => openBilibiliVideo(
                              context,
                              bvid: video.bvid,
                              initialTitle: video.title,
                              initialCover: video.pic,
                              heroTag: 'bili_video_${video.bvid}',
                            ),
                    );
                    if (delta != null && t < 1.0) {
                      card = Transform.translate(
                        offset: Offset(delta.dx * (1 - t), delta.dy * (1 - t)),
                        child: card,
                      );
                    }
                    return card;
                  },
                );
              }
              return _VideoCard(
                video: video,
                heroTag: 'bili_video_${video.bvid}',
                cardKey: _videoFocusKey(video.bvid),
                highlight: _isFocusVideo(video.bvid),
                onTap: video.bvid.isEmpty
                    ? null
                    : () => openBilibiliVideo(
                        context,
                        bvid: video.bvid,
                        initialTitle: video.title,
                        initialCover: video.pic,
                        heroTag: 'bili_video_${video.bvid}',
                      ),
              );
            }, childCount: videos.length),
          );
        },
      ),
    );
  }

  /// 视频单列列表（与搜索结果单列同款：完整圆角卡片）。
  Widget _buildVideoList(List<BiliUserVideo> videos) {
    final cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final video in videos)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _listHighlightWrap(
                  video.bvid,
                  MorphItem(
                    selected: false,
                    isFirst: true,
                    isLast: true,
                    interactive: true,
                    child: _buildVideoListCard(cs, video),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 视频单列列表卡片：缩略图 + 标题 + 作者/播放信息。
  Widget _buildVideoListCard(ColorScheme cs, BiliUserVideo video) {
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    final fallback = Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.videocam_outlined,
        size: 24,
        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 96,
        height: 60,
        child: video.pic.isNotEmpty
            ? Image(
                image: CachedImageProvider(
                  BilibiliUserSpaceService.coverUrl(video.pic),
                  headers: headers,
                ),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );
    // 单列是横向宽行卡片：整行飞向竖屏视频页会因宽高比跨度太大而严重
    // 拉伸变形。因此只让封面缩略图作为 Hero 源（点击时封面 → 视频页
    // 放大，返回时封面缩回），避免整行卡片动画失真。
    final leading = video.bvid.isNotEmpty
        ? Hero(
            tag: 'bili_video_${video.bvid}',
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
            child: thumb,
          )
        : thumb;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: leading,
      title: Text(
        BilibiliTitleCache.displayTitle(video.bvid, video.title),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${video.author} · ${AppLocalizations.of(context).searchVideoMeta(_formatCount(video.play), _formatCount(video.danmaku))}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ),
      trailing: Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
      onTap: video.bvid.isEmpty
          ? null
          : () => openBilibiliVideo(
              context,
              bvid: video.bvid,
              initialTitle: video.title,
              initialCover: video.pic,
              heroTag: 'bili_video_${video.bvid}',
            ),
    );
  }

  /// 视频布局切换按钮（单列 ↔ 多列 ↔ 瀑布流，循环切换）。
  Widget _buildVideoLayoutToggle(ColorScheme cs, AppLocalizations l10n) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final (IconData icon, String label) = switch (_videoLayout) {
      _VideoLayout.single => (
        Icons.view_agenda_outlined,
        l10n.searchLayoutSingle,
      ),
      _VideoLayout.grid => (Icons.grid_view_rounded, l10n.searchLayoutMulti),
      _VideoLayout.waterfall => (
        Icons.view_column_outlined,
        isZh ? '瀑布流' : 'Waterfall',
      ),
    };
    return Tooltip(
      message: switch (_videoLayout) {
        _VideoLayout.single => l10n.searchSwitchMulti,
        _VideoLayout.grid => isZh ? '切换为瀑布流' : 'Switch to Waterfall',
        _VideoLayout.waterfall => l10n.searchSwitchSingleCol,
      },
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(kGroupRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() {
            _videoLayout = switch (_videoLayout) {
              _VideoLayout.single => _VideoLayout.grid,
              _VideoLayout.grid => _VideoLayout.waterfall,
              _VideoLayout.waterfall => _VideoLayout.single,
            };
            _prevGridCols = 0;
            _prevItemCount = 0;
            _prevFirstVideoBvid = null;
            _itemTranslations.clear();
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(ColorScheme cs) {
    final banner = _banner;
    if (banner != null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final url = isDark && banner.dark.isNotEmpty ? banner.dark : banner.light;
      if (url.isNotEmpty) {
        return Image(
          image: CachedImageProvider(
            '$url@672w_378h_1c.webp',
            headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                ? null
                : NetworkSettingsService.instance.apiHeaders,
          ),
          fit: BoxFit.cover,
          color: isDark ? const Color(0x8D000000) : const Color(0x5DFFFFFF),
          colorBlendMode: isDark ? BlendMode.darken : BlendMode.lighten,
          errorBuilder: (_, __, ___) => _buildTopPhotoFallback(cs),
        );
      }
    }
    return _buildTopPhotoFallback(cs);
  }

  /// 横幅缺失时的默认背景：card.top_photo（官方默认背景图 / 装扮背景图），
  /// 仍不可用时退回「头像模糊 + 渐变」。
  Widget _buildTopPhotoFallback(ColorScheme cs) {
    final top = _card?.topPhoto ?? '';
    if (top.isNotEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Image(
        image: CachedImageProvider(
          '$top@672w_378h_1c.webp',
          headers: NetworkSettingsService.instance.apiHeaders.isEmpty
              ? null
              : NetworkSettingsService.instance.apiHeaders,
        ),
        fit: BoxFit.cover,
        color: isDark ? const Color(0x8D000000) : const Color(0x5DFFFFFF),
        colorBlendMode: isDark ? BlendMode.darken : BlendMode.lighten,
        errorBuilder: (_, __, ___) => _buildBlurredAvatarFallback(cs),
      );
    }
    return _buildBlurredAvatarFallback(cs);
  }

  /// 无横幅时的兜底背景：头像模糊 + 主题色渐变。
  Widget _buildBlurredAvatarFallback(ColorScheme cs) {
    final face = _card?.face ?? '';
    if (face.isNotEmpty) {
      return Image(
        image: CachedImageProvider(
          BilibiliUserSpaceService.avatarUrl(face, size: 320),
          headers: NetworkSettingsService.instance.apiHeaders.isEmpty
              ? null
              : NetworkSettingsService.instance.apiHeaders,
        ),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultGradient(cs),
        frameBuilder: (context, child, frame, wasSyncLoaded) {
          if (wasSyncLoaded || frame != null) {
            return ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: child,
            );
          }
          return _defaultGradient(cs);
        },
      );
    }
    return _defaultGradient(cs);
  }

  Widget _defaultGradient(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.primaryContainer, cs.tertiaryContainer],
        ),
      ),
    );
  }

  /// 展开态头部：头像 + 昵称/UID + 简介。
  Widget _buildHeaderInfo(ColorScheme cs) {
    final card = _card;
    final face = card?.face ?? '';
    final isVip = (card?.vipStatus ?? 0) > 0 && (card?.vipType ?? 0) == 2;
    final userLevel = card?.level ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── 头像：点击查看大图（Hero 动画），佩戴粉丝装扮时显示挂件 ──
            GestureDetector(
              onTap: _openAvatarViewer,
              child: Hero(
                tag: _avatarHeroTag,
                child: PendantAvatar(
                  size: _avatarRadius * 2,
                  pendOffset: 8,
                  avatarUrl: face.isNotEmpty
                      ? BilibiliUserSpaceService.avatarUrl(face)
                      : '',
                  pendantUrl: card?.pendantImage,
                  ringWidth: 3,
                  ringColor: Colors.white.withOpacity(0.9),
                  shadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  fallback: Icon(
                    Icons.person,
                    size: _avatarRadius,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            card?.name ??
                                AppLocalizations.of(
                                  context,
                                ).userSpaceLoadingName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(blurRadius: 6, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                        if (card != null) ...[
                          if (isVip) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.workspace_premium,
                              size: 18,
                              color: Color(0xFFFB7299),
                            ),
                          ],
                          if ((card.officialType) >= 0) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: card.officialType == 1
                                  ? const Color(0xFF23ADE5)
                                  : Colors.white70,
                            ),
                          ],
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'UID ${widget.mid}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                        shadows: const [
                          Shadow(blurRadius: 4, color: Colors.black45),
                        ],
                      ),
                    ),
                    // ── 粉丝装扮（仅登录且是粉丝时下发，参考 PiliPlus 样式） ──
                    if (card?.fansDetail case final fansDetail?)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: FansMedalBadge(detail: fansDetail),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // B 站原版 LV 徽标（LV6 及以上带闪电）
                        buildUserLevel(userLevel),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (card?.sign ?? '').isNotEmpty
                                ? card!.sign
                                : AppLocalizations.of(
                                    context,
                                  ).userSpaceLazySign,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                              shadows: const [
                                Shadow(blurRadius: 4, color: Colors.black45),
                              ],
                            ),
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
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 10000) {
      final w = n / 10000;
      return '${w.toStringAsFixed(w >= 100 ? 0 : 1)}${L10n.current.tenThousandUnit}';
    }
    return '$n';
  }

  Widget _buildStatItem(ColorScheme cs, String label, int value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            _formatCount(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(ColorScheme cs) {
    return Container(
      width: 1,
      height: 26,
      color: cs.outlineVariant.withOpacity(0.5),
    );
  }

  /// 瀑布流视频网格（TikTok/Douyin 风格：竖 9:16 封面，无间距，下方仅显示播放量）。
  Widget _buildVideoWaterfall(List<BiliUserVideo> videos) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = (width / 130).floor().clamp(3, 4);
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              childAspectRatio: 9 / 16,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final video = videos[index];
              final heroTag = 'waterfall_video_${video.bvid}';
              return _listHighlightWrap(
                video.bvid,
                _WaterfallVideoCard(
                  video: video,
                  heroTag: heroTag,
                  onTap: video.bvid.isEmpty
                      ? null
                      : () => openBilibiliVideo(
                          context,
                          bvid: video.bvid,
                          initialTitle: video.title,
                          initialCover: video.pic,
                          heroTag: heroTag,
                        ),
                ),
              );
            }, childCount: videos.length),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════
//  吸顶 TabBar（主页 / 动态 / 视频）
// ═════════════════════════════════════════

class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedTabBarDelegate({required this.tabController, this.onTabTap});

  final TabController tabController;

  /// Tab 点击回调（含点击当前 Tab；切换索引由 TabBar 内部处理）。
  final ValueChanged<int>? onTabTap;

  @override
  double get minExtent => _BilibiliUserSpacePageState._tabBarHeight;

  @override
  double get maxExtent => _BilibiliUserSpacePageState._tabBarHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      child: TabBar(
        controller: tabController,
        onTap: onTabTap,
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: AppLocalizations.of(context).userSpaceTabHome),
          Tab(text: AppLocalizations.of(context).userSpaceTabDynamic),
          Tab(text: AppLocalizations.of(context).userSpaceStatVideos),
          Tab(text: AppLocalizations.of(context).userSpaceTabBangumi),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) =>
      oldDelegate.tabController != tabController ||
      oldDelegate.onTabTap != onTabTap;
}

// ═════════════════════════════════════════
//  动态卡片（点击用内置浏览器打开）
// ═════════════════════════════════════════

class _DynamicCard extends StatelessWidget {
  final BiliUserDynamic item;
  final VoidCallback? onTap;

  /// 页面作者信息兜底（空间接口个别动态缺 module_author 时使用）。
  final String? ownerName;
  final String? ownerFace;

  const _DynamicCard({
    required this.item,
    this.onTap,
    this.ownerName,
    this.ownerFace,
  });

  bool get _isArchive => item.bvid.isNotEmpty || item.aid > 0;
  bool get _hasImages => item.images.isNotEmpty;
  bool get _isForward =>
      item.orig != null || item.type == 'DYNAMIC_TYPE_FORWARD';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAuthorRow(context, cs),
              if (item.topicName.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildTopicRow(cs),
              ],
              if (item.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildText(context, cs),
              ],
              if (_hasImages) ...[
                const SizedBox(height: 8),
                _buildImageGrid(context, cs),
              ],
              if (_isArchive) ...[
                const SizedBox(height: 8),
                _buildArchiveCard(context, cs),
              ],
              if (item.articleUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildArticleCard(context, cs),
              ],
              if (item.liveRoomId > 0) ...[
                const SizedBox(height: 8),
                _buildLiveCard(context, cs),
              ],
              if (item.orig != null) ...[
                const SizedBox(height: 8),
                _buildRepostCard(context, cs, item.orig!),
              ],
              const SizedBox(height: 10),
              _buildStatsRow(context, cs),
            ],
          ),
        ),
      ),
    );
  }

  // ── 作者行：头像 + 昵称 + 时间 ──
  Widget _buildAuthorRow(BuildContext context, ColorScheme cs) {
    final face = item.authorFace.isNotEmpty ? item.authorFace : ownerFace ?? '';
    final name = item.authorName.isNotEmpty ? item.authorName : ownerName ?? '';
    return Row(
      children: [
        ClipOval(
          child: face.isNotEmpty
              ? Image(
                  image: CachedImageProvider(
                    BilibiliUserSpaceService.avatarUrl(face),
                    headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                        ? null
                        : NetworkSettingsService.instance.apiHeaders,
                  ),
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _avatarPlaceholder(cs),
                )
              : _avatarPlaceholder(cs),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name.isEmpty ? 'UP主' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (_isForward) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '转发',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(item.pubTs),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (item.authorMid > 0)
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
      ],
    );
  }

  Widget _avatarPlaceholder(ColorScheme cs) {
    return Container(
      width: 36,
      height: 36,
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.person_outline, size: 20, color: cs.onSurfaceVariant),
    );
  }

  // ── 话题行 ──
  Widget _buildTopicRow(ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.tag_rounded, size: 15, color: cs.primary),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            '#${item.topicName}#',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: cs.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ── 正文：富文本（@ / 话题 / 表情 / 链接），最多 5 行收起 ──
  Widget _buildText(BuildContext context, ColorScheme cs) {
    final style = TextStyle(fontSize: 14, height: 1.55, color: cs.onSurface);
    final nodes = item.textNodes;
    if (nodes.isEmpty) {
      return Text(
        item.text,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return Text.rich(
      TextSpan(style: style, children: _buildSpans(context, cs)),
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<InlineSpan> _buildSpans(BuildContext context, ColorScheme cs) {
    final spans = <InlineSpan>[];
    final base = TextStyle(fontSize: 14, height: 1.55, color: cs.onSurface);
    for (final node in item.textNodes) {
      switch (node.type) {
        case 'RICH_TEXT_NODE_TYPE_AT':
        case 'RICH_TEXT_NODE_TYPE_WEB':
          spans.add(
            TextSpan(
              text: node.text,
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w500),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  if (node.type == 'RICH_TEXT_NODE_TYPE_AT') {
                    final mid = int.tryParse(node.rid) ?? 0;
                    if (mid > 0) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BilibiliUserSpacePage(mid: mid),
                        ),
                      );
                    }
                  } else if (node.url.isNotEmpty) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            BrowserPage(initialUrl: node.url, title: '链接'),
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
                    errorBuilder: (_, __, ___) => Text(node.text, style: base),
                  ),
                ),
              ),
            );
          } else {
            spans.add(TextSpan(text: node.text, style: base));
          }
        default:
          spans.add(TextSpan(text: node.text, style: base));
      }
    }
    return spans;
  }

  // ── 图片网格（完整展示图文动态的全部图片）──
  Widget _buildImageGrid(BuildContext context, ColorScheme cs) {
    final images = item.images;
    if (images.length == 1) {
      return SizedBox(
        height: 200,
        width: double.infinity,
        child: _buildImageTile(context, cs, images.first, 0),
      );
    }
    final columns = images.length == 2 ? 2 : 3;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1,
      children: [
        for (var i = 0; i < images.length; i++)
          _buildImageTile(context, cs, images[i], i),
      ],
    );
  }

  Widget _buildImageTile(
    BuildContext context,
    ColorScheme cs,
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
                for (final u in item.images)
                  ImageViewerSource(url: u, heroTag: null),
              ],
              initialIndex: index,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
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
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  // ── 投稿视频卡 ──
  Widget _buildArchiveCard(BuildContext context, ColorScheme cs) {
    final title = item.title.isEmpty ? '视频动态' : item.title;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (item.bvid.isNotEmpty) {
            openBilibiliVideo(
              context,
              bvid: item.bvid,
              initialTitle: title,
              initialCover: item.cover.isEmpty ? null : item.cover,
            );
          } else if (item.aid > 0) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BrowserPage(
                  initialUrl: 'https://www.bilibili.com/video/av${item.aid}',
                  title: title,
                ),
              ),
            );
          }
        },
        child: Row(
          children: [
            SizedBox(
              width: 128,
              height: 76,
              child: item.cover.isNotEmpty
                  ? Image(
                      image: CachedImageProvider(
                        BilibiliUserSpaceService.coverUrl(item.cover),
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
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (item.durationText.isNotEmpty) ...[
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            item.durationText,
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
                          _formatCount(item.play),
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
                          _formatCount(item.danmaku),
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
  }

  // ── 专栏卡 ──
  Widget _buildArticleCard(BuildContext context, ColorScheme cs) {
    return _buildModuleRow(
      context,
      cs,
      icon: Icons.article_outlined,
      title: item.title.isEmpty ? '专栏' : item.title,
      subtitle: '阅读专栏',
      onTap: () {
        final cvMatch = RegExp(r'/cv(\d+)').firstMatch(item.articleUrl);
        final cvid = cvMatch == null
            ? 0
            : (int.tryParse(cvMatch.group(1)!) ?? 0);
        if (cvid > 0) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ArticlePage(cvid: cvid, initialTitle: item.title),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  BrowserPage(initialUrl: item.articleUrl, title: '专栏'),
            ),
          );
        }
      },
    );
  }

  // ── 直播卡 ──
  Widget _buildLiveCard(BuildContext context, ColorScheme cs) {
    return _buildModuleRow(
      context,
      cs,
      icon: Icons.live_tv_outlined,
      title: item.title.isEmpty ? '直播' : item.title,
      subtitle: '进入直播间',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BilibiliLiveRoomPage(
              roomId: item.liveRoomId,
              title: item.title,
              uname: item.authorName,
              face: item.authorFace,
              cover: item.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildModuleRow(
    BuildContext context,
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 24, color: cs.primary),
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  // ── 转发嵌套卡 ──
  Widget _buildRepostCard(
    BuildContext context,
    ColorScheme cs,
    BiliUserDynamic orig,
  ) {
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (orig.idStr.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DynamicDetailPage(id: orig.idStr),
              ),
            );
          } else if (orig.bvid.isNotEmpty) {
            openBilibiliVideo(
              context,
              bvid: orig.bvid,
              initialTitle: orig.title,
              initialCover: orig.cover.isEmpty ? null : orig.cover,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '@${orig.authorName.isEmpty ? '用户' : orig.authorName}',
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
              if (orig.text.isNotEmpty) ...[
                const SizedBox(height: 6),
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
              ],
              if (orig.images.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      for (final img in orig.images.take(4))
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
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
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 64,
                                height: 64,
                                color: cs.surfaceContainerHighest,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (_moduleHintRow(cs, orig) case final hint?) ...[
                const SizedBox(height: 8),
                hint,
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 转发来源的模块提示行（视频 / 专栏 / 直播），无则返回 null。
  Widget? _moduleHintRow(ColorScheme cs, BiliUserDynamic o) {
    final IconData icon;
    final String text;
    if (o.bvid.isNotEmpty) {
      icon = Icons.play_circle_outline;
      text = o.title.isEmpty ? '视频' : o.title;
    } else if (o.articleUrl.isNotEmpty) {
      icon = Icons.article_outlined;
      text = o.title.isEmpty ? '专栏' : o.title;
    } else if (o.liveRoomId > 0) {
      icon = Icons.live_tv_outlined;
      text = o.title.isEmpty ? '直播' : o.title;
    } else if (o.durationText.isNotEmpty) {
      icon = Icons.play_circle_outline;
      text = o.title.isEmpty ? '视频' : o.title;
    } else {
      return null;
    }
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  // ── 统计行 ──
  Widget _buildStatsRow(BuildContext context, ColorScheme cs) {
    return Row(
      children: [
        const Spacer(),
        _statItem(cs, Icons.favorite_outline_rounded, item.like),
        _statItem(cs, Icons.chat_bubble_outline_rounded, item.comment),
        _statItem(cs, Icons.share_outlined, item.forward),
      ],
    );
  }

  Widget _statItem(ColorScheme cs, IconData icon, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            _formatCount(count),
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _mediaPlaceholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.movie_outlined, size: 26, color: cs.onSurfaceVariant),
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
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${L10n.current.userSpaceToday} ${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}

// ═════════════════════════════════════════
//  视频卡片（点击用内置浏览器打开）
// ═════════════════════════════════════════

class _VideoCard extends StatelessWidget {
  final BiliUserVideo video;
  final VoidCallback? onTap;
  final String? heroTag;

  /// 「上次观看」定位高亮：给卡片加一圈主题色描边淡入动画。
  final bool highlight;

  /// 供上层定位滚动到该卡片。
  final GlobalKey? cardKey;

  const _VideoCard({
    required this.video,
    this.onTap,
    this.heroTag,
    this.highlight = false,
    this.cardKey,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 整张卡片（封面 + 标题文字）作为 Hero 源，与视频播放页整页 Hero
    // 同 tag —— 返回转场时整个卡片一起运动（与搜索页视频卡片一致）。
    Widget card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 封面 + 时长 / 播放数 ──
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (video.pic.isNotEmpty)
                    Image(
                      image: CachedImageProvider(
                        BilibiliUserSpaceService.coverUrl(video.pic),
                        headers:
                            NetworkSettingsService.instance.apiHeaders.isEmpty
                            ? null
                            : NetworkSettingsService.instance.apiHeaders,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.videocam_outlined,
                          size: 32,
                          color: cs.onSurfaceVariant.withOpacity(0.4),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        Icons.videocam_outlined,
                        size: 32,
                        color: cs.onSurfaceVariant.withOpacity(0.4),
                      ),
                    ),
                  // 底部渐变遮罩
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 播放数
                  Positioned(
                    left: 8,
                    bottom: 6,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        Text(
                          _formatCount(video.play),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 时长
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(video.duration),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BilibiliTitleCache.displayTitle(video.bvid, video.title),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.subtitles_outlined,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${_formatCount(video.danmaku)} ${AppLocalizations.of(context).csDanmaku}',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(video.created),
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
    if (cardKey != null) {
      card = KeyedSubtree(key: cardKey!, child: card);
    }
    if (highlight) {
      // 定位高亮：主题色圆角描边 + 淡入，提示「上次观看」
      card = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(
                alpha: (t * 0.95).clamp(0.0, 1.0),
              ),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.35 * t),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      );
    }
    if (heroTag != null) {
      card = Hero(
        tag: heroTag!,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: card,
      );
    }
    return card;
  }

  String _formatCount(int n) {
    if (n >= 10000) {
      final w = n / 10000;
      return '${w.toStringAsFixed(w >= 100 ? 0 : 1)}${L10n.current.tenThousandUnit}';
    }
    return '$n';
  }

  static String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  static String _formatDate(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}

class _WaterfallVideoCard extends StatelessWidget {
  final BiliUserVideo video;
  final String heroTag;
  final VoidCallback? onTap;
  const _WaterfallVideoCard({
    required this.video,
    required this.heroTag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Hero(
          tag: heroTag,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (video.pic.isNotEmpty)
                Image(
                  image: CachedImageProvider(
                    BilibiliUserSpaceService.coverUrl(video.pic),
                    headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                        ? null
                        : NetworkSettingsService.instance.apiHeaders,
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(cs),
                )
              else
                _fallback(cs),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 6,
                bottom: 5,
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _formatCount(video.play),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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

  Widget _fallback(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.videocam_outlined,
        size: 32,
        color: cs.onSurfaceVariant.withOpacity(0.4),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 10000) {
      final w = n / 10000;
      return '${w.toStringAsFixed(w >= 100 ? 0 : 1)}${L10n.current.tenThousandUnit}';
    }
    return '$n';
  }
}

class _BangumiCard extends StatelessWidget {
  final BiliUserBangumi item;
  final VoidCallback? onTap;

  /// 封面 Hero tag（非空时封面参与飞行动画，与番剧播放页同 tag，
  /// 参考 _VideoCard 的视频封面 Hero 处理）。
  final String? heroTag;
  const _BangumiCard({required this.item, this.onTap, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (heroTag != null)
                    Hero(
                      tag: heroTag!,
                      child: item.cover.isNotEmpty
                          ? Image(
                              image: CachedImageProvider(
                                BilibiliUserSpaceService.bangumiCoverUrl(
                                  item.cover,
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
                              errorBuilder: (_, __, ___) => Container(
                                color: cs.surfaceContainerHighest,
                                child: Icon(
                                  Icons.movie_outlined,
                                  size: 32,
                                  color: cs.onSurfaceVariant.withOpacity(0.4),
                                ),
                              ),
                            )
                          : Container(
                              color: cs.surfaceContainerHighest,
                              child: Icon(
                                Icons.movie_outlined,
                                size: 32,
                                color: cs.onSurfaceVariant.withOpacity(0.4),
                              ),
                            ),
                    )
                  else if (item.cover.isNotEmpty)
                    Image(
                      image: CachedImageProvider(
                        BilibiliUserSpaceService.bangumiCoverUrl(item.cover),
                        headers:
                            NetworkSettingsService.instance.apiHeaders.isEmpty
                            ? null
                            : NetworkSettingsService.instance.apiHeaders,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.movie_outlined,
                          size: 32,
                          color: cs.onSurfaceVariant.withOpacity(0.4),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        Icons.movie_outlined,
                        size: 32,
                        color: cs.onSurfaceVariant.withOpacity(0.4),
                      ),
                    ),

                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 34,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (item.isFinish)
                    Positioned(
                      right: 6,
                      bottom: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalizations.of(context).userSpaceBangumiFinished,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else if (item.isStarted)
                    Positioned(
                      right: 6,
                      bottom: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).userSpaceBangumiSerializing,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (item.badge.isNotEmpty)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFB7299),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.badge,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: item.ratingScore > 0
                              ? const Color(0xFFF5A623)
                              : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.ratingScore > 0
                                ? item.ratingScore.toStringAsFixed(1)
                                : item.seasonTypeName.isEmpty
                                ? AppLocalizations.of(context).searchTypeBangumi
                                : item.seasonTypeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _metaLine(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: cs.primary.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _metaLine() {
    if (item.progress.isNotEmpty) return item.progress;
    if (item.newEpIndex.isNotEmpty) return item.newEpIndex;
    if (item.publishTime.length >= 10) {
      return L10n.current.userSpaceBangumiAiringDate(
        item.publishTime.substring(0, 10),
      );
    }
    return '';
  }
}

// ═════════════════════════════════════════
//  主页搜索（搜索该 UP 主投稿，参考 PiliPlus 空间搜索）
// ═════════════════════════════════════════

class _MemberSearchPage extends StatefulWidget {
  final int mid;
  final String upName;
  const _MemberSearchPage({required this.mid, required this.upName});

  @override
  State<_MemberSearchPage> createState() => _MemberSearchPageState();
}

class _MemberSearchPageState extends State<_MemberSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<BiliUserVideo> _results = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = false;
  bool _searched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final p = _scrollController.position;
    if (p.pixels >= p.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _search({bool reset = true}) async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) return;
    if (_loading) return;
    setState(() {
      _loading = true;
      if (reset) {
        _results = [];
        _page = 1;
        _error = null;
      }
      _searched = true;
    });
    final page = await BilibiliUserSpaceService.searchUserVideos(
      mid: widget.mid,
      keyword: keyword,
      pn: _page,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (page == null) {
        _error =
            BilibiliUserSpaceService.lastErrorDetail ??
            AppLocalizations.of(context).userSpaceLoadFailed;
        return;
      }
      _results.addAll(page.videos);
      _page += 1;
      _hasMore = _results.length < page.count && page.videos.isNotEmpty;
    });
  }

  Future<void> _loadMore() async {
    if (!_searched || _loading || !_hasMore) return;
    await _search(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLow,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: '搜索「${widget.upName}」的投稿',
              hintStyle: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                      },
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: cs.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);

    // 未搜索
    if (!_searched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              '输入关键词搜索「${widget.upName}」的投稿',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // 首屏加载
    if (_loading && _results.isEmpty) {
      return const Center(child: LoadingIndicatorM3E());
    }

    // 错误且无结果
    if (_error != null && _results.isEmpty) {
      return ListView(
        physics: const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          const SizedBox(height: 100),
          Icon(Icons.cloud_off_outlined, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: FilledButton.icon(
              onPressed: () => _search(),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.scanRetry),
            ),
          ),
        ],
      );
    }

    // 空结果
    if (_results.isEmpty) {
      return ListView(
        physics: const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          const SizedBox(height: 100),
          Icon(Icons.search_off, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '未找到与「${_controller.text.trim()}」相关的投稿',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final video = _results[index];
              return _VideoCard(
                video: video,
                heroTag: 'bili_video_${video.bvid}',
                onTap: video.bvid.isEmpty
                    ? null
                    : () => openBilibiliVideo(
                        context,
                        bvid: video.bvid,
                        initialTitle: video.title,
                        initialCover: video.pic,
                        heroTag: 'bili_video_${video.bvid}',
                      ),
              );
            }, childCount: _results.length),
          ),
        ),
        if (_loading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: LoadingIndicatorM3E()),
            ),
          )
        else if (!_hasMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  l10n.searchAllLoaded,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          )
        else
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
        ),
      ],
    );
  }
}
