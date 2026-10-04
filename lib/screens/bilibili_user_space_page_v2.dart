                                               
  
                                               
                                                   
                                                    
                                                   
                                                   
                                               
                                           
                                      
                                                            
                                          
                                                 
                                                       

import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_cheese_service.dart';
import 'package:naviflash/services/bilibili_im_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/native_menu_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/screens/whisper_chat_page.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/app_tooltip.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/fans_medal_badge.dart';
import 'package:naviflash/widgets/fan_decorate_card.dart';
import 'package:naviflash/widgets/medal_wall_sheet.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/lazy_cover_image.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/more_menu_sheet.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/search_video_menu.dart' show GlassMenuAction;
import 'package:naviflash/widgets/dynamic_waterfall.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/pendant_avatar.dart';
import 'package:naviflash/widgets/user_level_icon.dart';
import 'article_page.dart';
import 'bilibili_bangumi_page.dart';
import 'bilibili_cheese_page.dart';
import 'bilibili_follow_page.dart';
import 'bilibili_guard_list_page.dart';
import 'bilibili_live_room_page.dart';
import 'bilibili_topic_page.dart';
import 'bilibili_upower_rank_page.dart';
import 'bilibili_video_page.dart';
import 'browser_page.dart';
import 'dynamic_detail_page.dart';
import 'image_viewer_page.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/navi_spring_physics.dart';
import 'package:naviflash/widgets/video_card.dart';
import 'package:naviflash/widgets/page_loading.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

                                        
enum _VideoLayout { single, grid, waterfall }

                               
class BilibiliUserSpacePage extends StatefulWidget {
  final int mid;

                                            
                                  
  final String? focusBvid;

  const BilibiliUserSpacePage({super.key, required this.mid, this.focusBvid});

  @override
  State<BilibiliUserSpacePage> createState() => _BilibiliUserSpacePageState();
}

class _BilibiliUserSpacePageState extends State<BilibiliUserSpacePage>
    with TickerProviderStateMixin {
                                            
                                     
                                                     
  static const double _bannerHeight = 170.0;
  static const double _avatarSize = 76.0;
  static const double _tabBarHeight = 48.0;
  static const double _baseExpandedHeight = 384.0;

                                         
  static const double _avatarProtrude = 26.0;

                        
  static const double _signExpandedExtra = 58.0;

                                  
  bool _signExpanded = false;

                     
  double get _expandedHeight => _signExpanded
      ? _baseExpandedHeight + _signExpandedExtra
      : _baseExpandedHeight;

  late final TabController _tabController;

                                         
  final ValueNotifier<double> _bgZoom = ValueNotifier(1.0);
  final ScrollController _scrollController = ScrollController();

                                                            
                                                       
  double _pullOverscrollPx = 0;

                                   
  late final AnimationController _pullSettleCtrl;

                           
  double _pullSettleFrom = 0;

                                             
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

                                                                  
  final GlobalKey<NestedScrollViewState> _nestedKey =
      GlobalKey<NestedScrollViewState>();

                    
  BiliSpaceProfile? _profile;
  ({String light, String dark})? _banner;

                                      
  int? _attribute;                                          
  int _special = 0;             
  bool? _isFollowed;                      
  bool _relationBusy = false;

  bool get _isSelfSpace =>
      BilibiliAccountService.instance.isLoggedIn &&
      BilibiliAccountService.instance.mid == widget.mid;

                 
  List<BiliUserVideo> _videos = [];
  int _videoCount = 0;
  int _videoPage = 1;
  bool _videoLoadingMore = false;
  bool _videoHasMore = true;
  String _videoOrder = 'pubdate';                             
  int _videoTid = 0;                
  Map<int, BiliUserVideoCategory> _tlist = const {};

             
  _VideoLayout _videoLayout = _VideoLayout.grid;
  int _prevGridCols = 0;
  int _prevItemCount = 0;
  int _prevFirstHash = 0;
  late final AnimationController _gridRowAnimCtrl;
  final Map<int, Offset> _itemTranslations = {};

             
  List<BiliUserDynamic> _dynamics = [];
  String? _dynError;
  String _dynOffset = '';
  bool _dynLoadingMore = false;
  bool _dynHasMore = true;

                          
  bool _dynLoading = false;

                                   
  BiliSpaceSeasonSeries? _seasons;
  bool _seasonsStarted = false;
  bool _seasonsLoading = false;
  String? _seasonsError;

                                       
  BiliUserBangumiPage? _bangumiPage;
  int _bangumiType = 1;
  String? _bangumiError;
  bool _bangumiLoading = false;
  bool _bangumiStarted = false;

                                                   
  final List<CheeseCourseItem> _cheeseCourses = [];
  int _cheesePage = 1;
  bool _cheeseHasMore = false;
  bool _cheeseStarted = false;
  bool _cheeseLoading = false;
  String? _cheeseError;

                             
  final List<BiliSpaceArticle> _articles = [];
  int _articlesPage = 1;
  bool _articlesStarted = false;
  bool _articlesLoading = false;
  bool _articlesHasMore = true;
  String? _articlesError;

  bool _loading = true;
  String? _error;

                                           
  String? _focusBvid;
  bool _focusApplied = false;
  final Map<String, GlobalKey> _videoCardKeys = {};

  String get _avatarHeroTag => 'bili_space_avatar_${widget.mid}';

  @override
  void initState() {
    super.initState();
                                       
    _tabController = TabController(length: 7, vsync: this);
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
    _pullSettleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _pullSettleCtrl.addListener(_onPullSettleTick);
    _pullSettleCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pullOverscrollPx = 0;
        _updateBgZoom();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _pullSettleCtrl.dispose();
    _scrollController.dispose();
    _bgZoom.dispose();
    _tabController.dispose();
    _gridRowAnimCtrl.dispose();
    super.dispose();
  }

                                          
                           
                                          

  void _onPullSettleTick() {
    if (!_pullSettleCtrl.isAnimating) return;
    final t = Curves.easeOutCubic.transform(_pullSettleCtrl.value);
    _pullOverscrollPx = _pullSettleFrom * (1 - t);
    _updateBgZoom();
  }

  void _beginPullSettle() {
    if (_pullOverscrollPx <= 0) return;
    _pullSettleFrom = _pullOverscrollPx;
    _pullSettleCtrl
      ..stop()
      ..value = 0
      ..forward();
  }

  void _updateBgZoom() {
    if (!mounted || !_scrollController.hasClients) return;
    final pixels = _scrollController.position.pixels;
    final collapse = _expandedHeight - kToolbarHeight;
    final collapseZoom = 1.0 + (pixels / collapse).clamp(0.0, 1.0) * 0.10;
    final pullZoom = 1.0 + _pullOverscrollPx / _expandedHeight * 0.6;
    final zoom = (pullZoom > collapseZoom ? pullZoom : collapseZoom).clamp(
      1.0,
      1.6,
    );
    if ((zoom - _bgZoom.value).abs() > 0.001) {
      _bgZoom.value = zoom;
    }
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollController.position.pixels > 0.5 && _pullOverscrollPx != 0) {
      _pullOverscrollPx = 0;
    }
    _updateBgZoom();
  }

  bool _handleHeaderOverscroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is OverscrollNotification) {
      _pullSettleCtrl.stop();
      if (n.overscroll < 0) {
        _pullOverscrollPx += -n.overscroll;
      } else {
        _pullOverscrollPx -= n.overscroll;
        if (_pullOverscrollPx < 0) _pullOverscrollPx = 0;
      }
      _updateBgZoom();
    } else if (n is ScrollUpdateNotification) {
      if (n.metrics.pixels > 0.5 && _pullOverscrollPx != 0) {
        _pullOverscrollPx = 0;
        _updateBgZoom();
      }
    } else if (n is ScrollEndNotification) {
      _beginPullSettle();
    }
    return false;
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
                                     
    if (_tabController.index == 3 && !_seasonsStarted) _loadSeasons();
    if (_tabController.index == 4 && !_bangumiStarted) _loadBangumi();
    if (_tabController.index == 5 && !_cheeseStarted) _loadCheese();
    if (_tabController.index == 6 && !_articlesStarted) _loadArticles();
  }

                                          
                                        
                                    
  void _onTabTap(int index) {
    if (index != _tabController.index) return;
    final outer = _scrollController;
    final inner = _nestedKey.currentState?.innerController;

    final outerNotTop = outer.hasClients && outer.offset > 0;
    final innerNotTop = inner != null && inner.hasClients && inner.offset > 0;

    if (outerNotTop || innerNotTop) {
      if (outerNotTop) {
        outer.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      if (innerNotTop) {
        inner.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }
    _refreshKey.currentState?.show();
  }

                                          
          
                                          

  Future<void> _load({bool refresh = false}) async {
    final hasContent =
        _profile != null || _videos.isNotEmpty || _dynamics.isNotEmpty;
    setState(() {
      if (!refresh || !hasContent) _loading = true;
      _error = null;
    });
    List<Object?> results;
    try {
                                                       
                                                     
      results = await Future.wait([
        BilibiliUserSpaceService.fetchSpaceProfile(mid: widget.mid),
        BilibiliUserSpaceService.fetchUserVideos(
          mid: widget.mid,
          order: _videoOrder,
          tid: _videoTid,
        ),
        BilibiliUserSpaceService.fetchUserBanner(mid: widget.mid),
      ]);
    } catch (e) {
      debugPrint('[UserSpace] 并行加载异常: $e');
      results = [null, null, null];
    }
    if (!mounted) return;
    final profile = results[0] as BiliSpaceProfile?;
    final videos = results[1] as BiliUserVideoPage?;
    final banner = results[2] as ({String light, String dark})?;
    if (profile == null && videos == null) {
      setState(() {
        _loading = false;
        _error =
            BilibiliUserSpaceService.lastErrorDetail ??
            AppLocalizations.of(context).userSpaceLoadFailed;
      });
      return;
    }
    setState(() {
                                          
                                                
      if (profile != null) _profile = profile;
      if (videos != null || _videos.isEmpty) {
        _videos = videos?.videos ?? [];
        _videoCount = videos?.count ?? _videos.length;
        _videoPage = 1;
        _videoLoadingMore = false;
        _videoHasMore =
            videos != null &&
            _videos.isNotEmpty &&
            _videos.length < _videoCount;
        _tlist = videos?.tlist ?? const {};
      }
      _banner = banner;
      _loading = false;
    });
    _loadRelation();
    _applyFocusIfNeeded();
                                  
                                       
    _loadDynamics();
  }

                                
     
                            
  Future<void> _loadDynamics() async {
    if (_dynLoading) return;
    setState(() => _dynLoading = true);
    final page = await BilibiliUserSpaceService.fetchUserDynamics(
      mid: widget.mid,
    );
    if (!mounted) return;
    if (page == null && _dynamics.isNotEmpty) {
                          
      setState(() => _dynLoading = false);
      showAppToast(
        context,
        BilibiliUserSpaceService.lastErrorDetail ?? '动态刷新失败',
        error: true,
      );
      return;
    }
    setState(() {
      _dynLoading = false;
      _dynamics = page?.items ?? [];
      _dynOffset = page?.offset ?? '';
      _dynHasMore = (page?.hasMore ?? false) && _dynOffset.isNotEmpty;
      _dynError = page == null
          ? BilibiliUserSpaceService.lastErrorDetail
          : null;
                                       
      if (_videos.isEmpty && _dynamics.isNotEmpty) {
        _videos = _extractVideosFromDynamics(_dynamics);
        _videoCount = _videos.length;
        _videoHasMore = false;
      }
    });
  }

                                          
  Future<void> _loadRelation() async {
    if (_isSelfSpace) return;
    final detail = await BilibiliUserSpaceService.fetchRelationDetail(
      mid: widget.mid,
    );
    if (!mounted || detail == null) return;
    setState(() {
      _attribute = detail.attribute;
      _special = detail.special;
    });
  }

  Future<void> _handleRefresh() async {
                                                   
    await _load(refresh: true);
  }

                          

  Future<void> _loadMoreVideos() async {
    if (_videoLoadingMore || !_videoHasMore || _videos.isEmpty) return;
    setState(() => _videoLoadingMore = true);
    final page = await BilibiliUserSpaceService.fetchUserVideos(
      mid: widget.mid,
      pn: _videoPage + 1,
      order: _videoOrder,
      tid: _videoTid,
    );
    if (!mounted) return;
    setState(() {
      _videoLoadingMore = false;
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

                                               
  Future<void> _toggleVideoOrder() async {
    if (_videoLoadingMore) return;
    setState(() {
      _videoOrder = _videoOrder == 'pubdate' ? 'click' : 'pubdate';
      _videoPage = 1;
      _videoHasMore = true;
    });
    final page = await BilibiliUserSpaceService.fetchUserVideos(
      mid: widget.mid,
      order: _videoOrder,
      tid: _videoTid,
    );
    if (!mounted || page == null) return;
    setState(() {
      _videos = page.videos;
      _videoCount = page.count != 0 ? page.count : page.videos.length;
      _videoHasMore = _videos.length < _videoCount && page.videos.isNotEmpty;
    });
  }

                   
  Future<void> _selectVideoTid(int tid) async {
    if (tid == _videoTid) return;
    setState(() {
      _videoTid = tid;
      _videoPage = 1;
      _videoHasMore = true;
    });
    final page = await BilibiliUserSpaceService.fetchUserVideos(
      mid: widget.mid,
      order: _videoOrder,
      tid: _videoTid,
    );
    if (!mounted || page == null) return;
    setState(() {
      _videos = page.videos;
      _videoCount = page.count != 0 ? page.count : page.videos.length;
      _videoHasMore = _videos.length < _videoCount && page.videos.isNotEmpty;
    });
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

                                   

  Future<void> _loadSeasons() async {
    if (_seasonsLoading || (_seasonsStarted && _seasons != null)) return;
    setState(() {
      _seasonsStarted = true;
      _seasonsLoading = true;
      _seasonsError = null;
    });
    final page = await BilibiliUserSpaceService.fetchSeasonSeries(
      mid: widget.mid,
    );
    if (!mounted) return;
    setState(() {
      _seasons = page;
      _seasonsLoading = false;
      _seasonsError = page == null
          ? BilibiliUserSpaceService.lastErrorDetail
          : null;
    });
  }

                           

  Future<void> _loadBangumi() async {
    if (_bangumiLoading || (_bangumiStarted && _bangumiPage != null)) return;
    setState(() {
      _bangumiStarted = true;
      _bangumiLoading = true;
      _bangumiError = null;
    });
    final page = await BilibiliUserSpaceService.fetchUserBangumi(
      mid: widget.mid,
      type: _bangumiType,
    );
    if (!mounted) return;
    if (page == null && _bangumiPage != null) {
                       
      setState(() {
        _bangumiLoading = false;
        _bangumiError = BilibiliUserSpaceService.lastErrorDetail;
      });
      return;
    }
    setState(() {
      _bangumiPage = page;
      _bangumiLoading = false;
      _bangumiError = page == null
          ? BilibiliUserSpaceService.lastErrorDetail
          : null;
    });
  }

  Future<void> _switchBangumiType(int type) async {
    if (type == _bangumiType) return;
    setState(() {
      _bangumiType = type;
      _bangumiPage = null;
      _bangumiError = null;
    });
    await _loadBangumi();
  }

                                                   

  Future<void> _loadCheese({bool more = false}) async {
    if (_cheeseLoading) return;
    if (more && !_cheeseHasMore) return;
    if (!more) _cheesePage = 1;
    setState(() {
      _cheeseStarted = true;
      _cheeseLoading = true;
      if (!more) _cheeseError = null;
    });
    final page = await BilibiliCheeseService.fetchUserCourses(
      mid: widget.mid,
      pn: _cheesePage,
    );
    if (!mounted) return;
    setState(() {
      _cheeseLoading = false;
      if (page == null) {
        _cheeseError =
            BilibiliCheeseService.lastErrorDetail ?? '课程加载失败';
        return;
      }
      if (!more) _cheeseCourses.clear();
      final seen = _cheeseCourses.map((e) => e.seasonId).toSet();
      _cheeseCourses.addAll(page.items.where((e) => !seen.contains(e.seasonId)));
      _cheeseHasMore = page.hasMore;
      _cheesePage++;
      _cheeseError = null;
    });
  }

                                                      

  Future<void> _loadArticles({bool more = false}) async {
    if (_articlesLoading) return;
    if (more && !_articlesHasMore) return;
    setState(() {
      _articlesStarted = true;
      _articlesLoading = true;
      if (!more) {
        _articlesError = null;
        _articlesPage = 1;
        _articlesHasMore = true;
      }
    });
    final page = await BilibiliUserSpaceService.fetchSpaceArticles(
      mid: widget.mid,
      pn: _articlesPage,
    );
    if (!mounted) return;
    setState(() {
      _articlesLoading = false;
      if (page == null) {
        _articlesError =
            BilibiliUserSpaceService.lastErrorDetail ?? '专栏加载失败';
        return;
      }
      if (!more) _articles.clear();
      final seen = _articles.map((e) => e.cvid).toSet();
      _articles.addAll(page.items.where((e) => !seen.contains(e.cvid)));
      _articlesHasMore =
          page.items.isNotEmpty && _articles.length < page.count;
      _articlesPage++;
      _articlesError = null;
    });
  }

  Widget _buildArticleTab(ColorScheme cs) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    if (_articlesLoading && _articles.isEmpty) {
      return const Center(child: LoadingIndicatorM3E());
    }
    if (_articlesError != null && _articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _articlesError!,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _loadArticles(),
              child: Text(isZh ? '重试' : 'Retry'),
            ),
          ],
        ),
      );
    }
    if (_articles.isEmpty) {
      return Center(
        child: Text(
          isZh ? '还没有发布专栏' : 'No articles yet',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _articles.length + 1,
      itemBuilder: (context, index) {
        if (index >= _articles.length) {
          if (_articlesLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          if (_articlesHasMore) {
            return Center(
              child: TextButton(
                onPressed: () => _loadArticles(more: true),
                child: Text(isZh ? '加载更多' : 'Load more'),
              ),
            );
          }
          return const SizedBox(height: 8);
        }
        final item = _articles[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: item.cvid > 0
                ? () => Navigator.of(context).push(
                      ImmersiveMaterialPageRoute(
                        page: ArticlePage(cvid: item.cvid),
                      ),
                    )
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 132,
                    height: 80,
                    child: item.cover.isEmpty
                        ? Container(color: cs.surfaceContainerHighest)
                        : Image(
                            image: CachedImageProvider(
                              item.cover,
                              headers: NetworkSettingsService
                                      .instance.apiHeaders.isEmpty
                                  ? null
                                  : NetworkSettingsService.instance.apiHeaders,
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: cs.surfaceContainerHighest,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5, height: 1.35),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.publishText}   ${_formatCount(item.view)}阅读'
                        ' · ${_formatCount(item.reply)}评论',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

                   

  GlobalKey _videoFocusKey(String bvid) =>
      _videoCardKeys.putIfAbsent(bvid, GlobalKey.new);

  bool _isFocusVideo(String bvid) => _focusBvid != null && bvid == _focusBvid;

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

  void _applyFocusIfNeeded() {
    if (_focusApplied) return;
    final focusBvid = widget.focusBvid;
    if (focusBvid == null || focusBvid.isEmpty) return;
    final idx = _videos.indexWhere((v) => v.bvid == focusBvid);
    if (idx < 0) return;
    _focusApplied = true;
    _focusBvid = focusBvid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tabController.animateTo(2);
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
        setState(() {});
      });
    });
  }

                                                  
  List<BiliUserVideo> _extractVideosFromDynamics(List<BiliUserDynamic> items) {
    final result = <BiliUserVideo>[];
    for (final dyn in items) {
      if (dyn.bvid.isEmpty && dyn.aid <= 0) continue;
      result.add(
        BiliUserVideo(
          bvid: dyn.bvid,
          title: dyn.title,
          pic: dyn.cover,
          author: _profile?.name ?? '',
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

                                          
                                                     
                                          

                                             
                                      
  String _followLabel(AppLocalizations l10n, bool isZh) {
    final attr = _attribute;
    if (_special == 1) return isZh ? '特别关注' : 'Special';
    return switch (attr) {
      null => l10n.videoFollowLabel,
      0 => l10n.videoFollowLabel,
      1 => isZh ? '悄悄关注' : 'Whisper',
      2 => l10n.videoFollowedLabel,
      4 || 6 => l10n.userSpaceFollowMutual,
      128 => isZh ? '移除黑名单' : 'Unblock',
      _ => l10n.videoFollowedLabel,
    };
  }

  Future<void> _onFollowButtonTap() async {
    if (_relationBusy) return;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final l10n = AppLocalizations.of(context);

                                                   
    if (_isSelfSpace) {
      showAppToast(context, isZh ? '可在「我的」中编辑资料' : 'Edit profile in Mine');
      return;
    }
                                  
    if (_attribute == 128) {
      await _modifyRelation(act: 6, doneMsg: isZh ? '已移除黑名单' : 'Unblocked');
      return;
    }
               
    final followed = _attribute != null && _attribute! != 0;
    if (!followed) {
      if (!await _ensureLogin()) return;
      await _modifyRelation(act: 1, doneMsg: l10n.userSpaceFollowDone);
      return;
    }
                                                          
    HapticFeedback.lightImpact();
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      items: [
        NativeMenuItem(
          text: _special == 1
              ? (isZh ? '移除特别关注' : 'Remove special follow')
              : (isZh ? '加入特别关注' : 'Add special follow'),
          icon: _special == 1
              ? Icons.notifications_off_outlined
              : Icons.notifications_on_outlined,
          onTap: () async {
            final add = _special != 1;
            final ok = await BilibiliUserSpaceService.specialFollowAction(
              mid: widget.mid,
              add: add,
            );
            if (!mounted) return;
            if (ok) {
              setState(() => _special = add ? 1 : 0);
              showAppToast(
                context,
                add
                    ? (isZh ? '已特别关注' : 'Special followed')
                    : (isZh ? '已移除特别关注' : 'Removed'),
              );
            } else {
              showAppToast(context, l10n.userSpaceFollowFail, error: true);
            }
          },
        ),
        NativeMenuItem(
          text: isZh ? '取消关注' : 'Unfollow',
          icon: Icons.person_remove_outlined,
          destructive: true,
          onTap: () => _modifyRelation(
            act: 2,
            doneMsg: l10n.userSpaceUnfollowDone,
          ),
        ),
      ],
    );
    if (nativeOk || !mounted) return;
    await showAppBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.92,
      ),
      builder: (sheetCtx) {
        final cs = Theme.of(sheetCtx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  _special == 1
                      ? Icons.notifications_off_outlined
                      : Icons.notifications_on_outlined,
                  color: cs.primary,
                ),
                title: Text(
                  _special == 1
                      ? (isZh
                          ? '移除特别关注'
                          : 'Remove special follow')
                      : (isZh ? '加入特别关注' : 'Add special follow'),
                ),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  final add = _special != 1;
                  final ok = await BilibiliUserSpaceService.specialFollowAction(
                    mid: widget.mid,
                    add: add,
                  );
                  if (!mounted) return;
                  if (ok) {
                    setState(() => _special = add ? 1 : 0);
                    showAppToast(
                      context,
                      add ? (isZh ? '已特别关注' : 'Special followed') : (isZh ? '已移除特别关注' : 'Removed'),
                    );
                  } else {
                    showAppToast(
                      context,
                      l10n.userSpaceFollowFail,
                      error: true,
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.person_remove_outlined,
                  color: cs.error,
                ),
                title: Text(
                  isZh ? '取消关注' : 'Unfollow',
                  style: TextStyle(color: cs.error),
                ),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  await _modifyRelation(
                    act: 2,
                    doneMsg: l10n.userSpaceUnfollowDone,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

                           
  Future<bool> _ensureLogin() async {
    final account = BilibiliAccountService.instance;
    if (account.isLoggedIn) return true;
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.biliDialogNeedLogin),
        content: Text(l10n.biliDialogInteractDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.biliGoLogin),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BilibiliLoginScreen()));
    }
    return false;
  }

                                                      
  Future<void> _modifyRelation({
    required int act,
    required String doneMsg,
  }) async {
    if (_relationBusy) return;
    if (!await _ensureLogin()) return;
    setState(() => _relationBusy = true);
    final ok = await BilibiliUserSpaceService.modifyRelationAct(
      mid: widget.mid,
      act: act,
    );
    if (!mounted) return;
    setState(() {
      _relationBusy = false;
      if (ok) {
        switch (act) {
          case 1:
            _attribute = 2;
          case 2:
            _attribute = 0;
            _special = 0;
          case 5:
            _attribute = 128;
          case 6:
            _attribute = 0;
          case 7:
            _isFollowed = false;
        }
      }
    });
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    if (ok) {
      showAppToast(context, doneMsg);
    } else {
      showAppToast(
        context,
        isZh ? '操作失败，请稍后重试' : 'Operation failed',
        error: true,
      );
    }
  }

                              
  void _openWhisper() {
    HapticFeedback.lightImpact();
    if (!BilibiliImService.canUse) {
                              
      showAppToast(context, AppLocalizations.of(context).biliAccountNotLoggedIn);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhisperChatPage(
          talkerId: widget.mid,
          name: _profile?.name ?? '',
          face: _profile?.face ?? '',
        ),
      ),
    );
  }

                                            
  Future<void> _shareUser() async {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    await Clipboard.setData(
      ClipboardData(text: 'https://space.bilibili.com/${widget.mid}'),
    );
    if (mounted) {
      showAppToast(context, isZh ? '链接已复制' : 'Link copied');
    }
  }

                                               
  Future<void> _openAvatarViewer() async {
    final url = _profile?.face ?? '';
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
                                          
        heroZoom: true,
        page: ImageViewerPage(imageBytes: bytes, heroTag: _avatarHeroTag),
      ),
    );
  }

                  
  void _openDynamicDetail(BiliUserDynamic dyn) {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DynamicDetailPage(id: dyn.idStr)));
  }

                                            
  void _openSearch() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _MemberSearchPage(mid: widget.mid, upName: _profile?.name ?? ''),
      ),
    );
  }

                                          
        
                                          
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

                                           
                                                
                            
    if (_loading && _profile == null) {
      return Scaffold(
        backgroundColor: cs.surfaceContainer,
        body: Stack(
          children: [
            SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LoadingIndicatorM3E(),
                        const SizedBox(height: 14),
                        Text(
                          l10n.userSpaceLoading,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                                      
                  Positioned(
                    left: 8,
                    top: 4,
                    child: MorphIconButton(
                      icon: Icons.arrow_back,
                      tooltip: l10n.commonBackTooltip,
                      onTap: () => Navigator.pop(context),
                      frosted: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final scaffold = Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: Stack(
        children: [
          AppRefreshIndicator(
            refreshIndicatorKey: _refreshKey,
            onRefresh: _handleRefresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleHeaderOverscroll,
              child: NestedScrollView(
                key: _nestedKey,
                controller: _scrollController,
                physics: _loading
                    ? const NeverScrollableScrollPhysics()
                    : const AppRefreshScrollPhysics(
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
                    actions: _buildAppBarActions(cs, isZh),
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) {
                        final safeTop = MediaQuery.of(context).padding.top;
                        final currentHeight = constraints.biggest.height;
                        final toolbarH = kToolbarHeight + safeTop;
                                                            
                                                             
                                                      
                                                      
                        final range = _expandedHeight - toolbarH;
                        final progress = range <= 0
                            ? 1.0
                            : ((_expandedHeight - currentHeight) / range)
                                  .clamp(0.0, 1.0);

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                                                         
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: _bannerHeight,
                              child: ClipRect(
                                child: ValueListenableBuilder<double>(
                                  valueListenable: _bgZoom,
                                  builder: (context, zoom, _) =>
                                      Transform.scale(
                                        scale: zoom,
                                        alignment: Alignment.topCenter,
                                        child: _buildBanner(context),
                                      ),
                                ),
                              ),
                            ),
                                             
                            Opacity(
                                                          
                              opacity: (1.0 - progress * 1.3).clamp(0.0, 1.0),
                              child: IgnorePointer(
                                ignoring: progress > 0.5,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [_buildHeaderBody(context)],
                                ),
                              ),
                            ),
                                              
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Opacity(
                                opacity: progress.clamp(0.0, 1.0),
                                child: ClipRect(
                                  child: SizedBox(
                                    height: kToolbarHeight + safeTop,
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 12,
                                        sigmaY: 12,
                                      ),
                                      child: Container(
                                        color: cs.surface.withValues(
                                          alpha: isDark ? 0.75 : 0.65,
                                        ),
                                        alignment: Alignment.bottomLeft,
                                        padding: EdgeInsets.only(
                                          left: 72,
                                          bottom: 12,
                                        ),
                                        child: Text(
                                          _profile?.name ??
                                              l10n.userSpaceTitle,
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
                                    
                  if (!_loading && _profile != null)
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
          ),
        ],
      ),
    );
    return IosBackdropScale(child: scaffold);
  }

                                        
  List<Widget> _buildAppBarActions(ColorScheme cs, bool isZh) {
    final loggedIn = BilibiliAccountService.instance.isLoggedIn;
    return [
      MorphIconButton(
        icon: Icons.search,
        tooltip: isZh ? '搜索投稿' : 'Search videos',
        onTap: _openSearch,
      ),
      LiquidGlassMenuButton(
        icon: Icons.more_vert,
        tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
        menuWidth: 220,
        actions: [
          if (loggedIn && !_isSelfSpace)
            GlassMenuAction(
              icon: Icons.block,
              text: _attribute == 128
                  ? (isZh ? '移除黑名单' : 'Unblock')
                  : (isZh ? '加入黑名单' : 'Block'),
              onTap: () {
                final blocked = _attribute == 128;
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(isZh ? '提示' : 'Notice'),
                    content: Text(
                      blocked
                          ? (isZh
                                ? '从黑名单移除该用户？'
                                : 'Remove from blacklist?')
                          : (isZh ? '确定拉黑该用户？' : 'Block this user?'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(l10nCommonCancel(ctx)),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _modifyRelation(
                            act: blocked ? 6 : 5,
                            doneMsg: blocked
                                ? (isZh ? '已移除黑名单' : 'Unblocked')
                                : (isZh ? '已拉黑' : 'Blocked'),
                          );
                        },
                        child: Text(isZh ? '确认' : 'OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (loggedIn && !_isSelfSpace && _isFollowed == true)
            GlassMenuAction(
              icon: Icons.remove_circle_outline_outlined,
              text: isZh ? '移除粉丝' : 'Remove fan',
              onTap: () => _modifyRelation(
                act: 7,
                doneMsg: isZh ? '已移除粉丝' : 'Fan removed',
              ),
            ),
          GlassMenuAction(
            icon: Icons.military_tech_outlined,
            text: isZh ? '粉丝勋章墙' : 'Fan medals',
            onTap: () => showMedalWallSheet(context, mid: widget.mid),
          ),
          GlassMenuAction(
            icon: Icons.share_outlined,
            text: _isSelfSpace
                ? (isZh ? '分享我的主页' : 'Share my profile')
                : (isZh ? '分享UP主' : 'Share'),
            onTap: _shareUser,
          ),
        ],
      ),
      const SizedBox(width: 4),
    ];
  }

                                      
  static String l10nCommonCancel(BuildContext ctx) =>
      AppLocalizations.of(ctx).commonCancel;

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

    if (_error != null && _profile == null) {
      return CustomScrollView(
        physics: const AppRefreshScrollPhysics(
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
                    color: cs.onSurface.withValues(alpha: 0.25),
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
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
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

    return naviTabBarView(
      controller: _tabController,
      children: [
        _buildHomeTab(cs),
        _buildDynamicTab(cs),
        _buildVideoTab(cs),
        _buildSeasonTab(cs),
        _buildBangumiTab(cs),
        _buildCheeseTab(cs),
        _buildArticleTab(cs),
      ],
    );
  }

                                          
                                              
                                          

                                             
                                               
                          
  Widget _buildHeaderBody(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        Widget content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                                            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Transform.translate(
                    offset: const Offset(0, -_avatarProtrude),
                    child: _buildHeaderAvatar(cs),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildHeaderActions(cs),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameRow(cs),
                                                     
                  if (_profile?.fanDecorate case final decorate?)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: FanDecorateBadge(
                        decorate: decorate,
                        height: 26,
                        maxWidth: 168,
                      ),
                    ),
                  if (_profile?.officialDesc.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    _buildVerifyChip(cs),
                  ],
                  const SizedBox(height: 4),
                  _buildUidRow(cs),
                  const SizedBox(height: 6),
                  _buildSignBlock(cs),
                  if (_buildChargeRow(cs) != null) ...[
                    const SizedBox(height: 8),
                    _buildChargeRow(cs)!,
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        );
        if (isWide) {
          content = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: content,
              ),
            ),
          );
        }
        return content;
      },
    );
  }

                                   
                               
  Widget _buildHeaderAvatar(ColorScheme cs) {
    final profile = _profile;
    final face = profile?.face ?? '';
    return GestureDetector(
      onTap: _openAvatarViewer,
      child: Hero(
          transitionOnUserGestures: true,
        tag: _avatarHeroTag,
        child: PendantAvatar(
          size: _avatarSize,
          pendOffset: 8,
          avatarUrl: face.isNotEmpty
              ? BilibiliUserSpaceService.avatarUrl(face, size: 144)
              : '',
          pendantUrl: profile?.pendantImage,
          ringWidth: 3,
          ringColor: (profile?.isLive ?? false)
              ? const Color(0xFFFB7299)
              : Colors.white.withValues(alpha: 0.9),
          shadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          fallback: Icon(
            Icons.person,
            size: _avatarSize / 2,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

                                             
  Widget _buildHeaderActions(ColorScheme cs) {
    final profile = _profile;
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 20, bottom: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                         
          if (profile?.isLive ?? false) ...[
            GestureDetector(
              onTap: profile!.liveRoomId > 0
                  ? () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BilibiliLiveRoomPage(
                            roomId: profile.liveRoomId,
                            title: profile.liveTitle,
                            uname: profile.name,
                            face: profile.face,
                          ),
                        ),
                      );
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFB7299),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.podcasts,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isZh ? '直播中' : 'LIVE',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
                                     
          Row(
            children: [
              _buildStatItem(
                cs,
                l10n.userSpaceStatFans,
                profile?.fans ?? 0,
                onTap: () => _openFollowList(isFans: true),
              ),
              _buildStatDivider(cs),
              _buildStatItem(
                cs,
                l10n.userSpaceStatFollowing,
                profile?.following ?? 0,
                onTap: () => _openFollowList(isFans: false),
              ),
              _buildStatDivider(cs),
              _buildStatItem(
                cs,
                l10n.userSpaceStatLikes,
                profile?.likeNum ?? 0,
                onTap: (profile?.likeNum ?? 0) > 0
                    ? () => _openCoinLikeArc('like')
                    : null,
              ),
            ],
          ),
                                                           
          if (!_isSelfSpace) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.outlined(
                  onPressed: _openWhisper,
                  tooltip: isZh ? '私信' : 'Message',
                  icon: const Icon(Icons.mail_outline, size: 20),
                  style: ButtonStyle(
                    side: WidgetStatePropertyAll(
                      BorderSide(
                        width: 1.0,
                        color: cs.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _buildFollowButton(cs)),
              ],
            ),
          ],
        ],
      ),
    );
  }

                                              
  void _openFollowList({required bool isFans}) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BilibiliFollowPage(
          mid: widget.mid,
          name: _profile?.name ?? '',
          initialFans: isFans,
        ),
      ),
    );
  }

                                                       
  void _openCoinLikeArc(String mode) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CoinLikeArcPage(
          mid: widget.mid,
          mode: mode,
          name: _profile?.name ?? '',
        ),
      ),
    );
  }

                                            
                                    
  Widget _buildFollowButton(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final attr = _attribute;
    final blocked = attr == 128;
    final followed = attr != null && attr != 0;
    final label = _followLabel(l10n, isZh);
    final button = _relationBusy
        ? SizedBox(
            height: 36,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          )
        : followed
        ? OutlinedButton.icon(
            onPressed: _onFollowButtonTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onSurfaceVariant,
              side: BorderSide(color: cs.outlineVariant),
              backgroundColor: cs.surfaceContainerHigh.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              _special == 1
                  ? Icons.notifications_on_outlined
                  : (attr == 4 || attr == 6)
                  ? Icons.people_alt_outlined
                  : Icons.check_rounded,
              size: 17,
            ),
            label: Text(
              label,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        : FilledButton.icon(
            onPressed: blocked ? _onFollowButtonTap : _onFollowButtonTap,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              blocked ? Icons.block : Icons.add_rounded,
              size: 18,
            ),
            label: Text(
              label,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
    return SizedBox(height: 36, child: button);
  }

                                        
  Widget _buildNameRow(ColorScheme cs) {
    final profile = _profile;
    final isVip =
        (profile?.vipStatus ?? 0) > 0 && (profile?.vipType ?? 0) == 2;
    final vipLabel = profile?.vipLabel ?? '';
    final sex = profile?.sex ?? '';
    final vipColor = const Color(0xFFFB7299);
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GestureDetector(
          onTap: () async {
            final name = profile?.name ?? '';
            if (name.isEmpty) return;
            HapticFeedback.lightImpact();
            await Clipboard.setData(ClipboardData(text: name));
            if (mounted) {
              showAppToast(context, '已复制昵称');
            }
          },
          child: Text(
            profile?.name ?? AppLocalizations.of(context).userSpaceLoadingName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: isVip ? vipColor : cs.onSurface,
            ),
          ),
        ),
                                  
        buildUserLevel(
          profile?.level ?? 0,
          isSeniorMember: profile?.isSeniorMember ?? false,
        ),
        if (isVip)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: vipColor,
            ),
            child: Text(
              vipLabel.isEmpty ? '大会员' : vipLabel,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        if ((profile?.officialType ?? -1) >= 0)
          Icon(
            Icons.verified,
            size: 16,
            color: profile!.officialType == 0
                ? const Color(0xFFF5A623)
                : const Color(0xFF23ADE5),
          ),
        if (sex == '男')
          const Icon(Icons.male_rounded, size: 17, color: Color(0xFF4FA8E8))
        else if (sex == '女')
          const Icon(Icons.female_rounded, size: 17, color: Color(0xFFFB7299)),
                                                
        if (profile?.fansDetail case final fansDetail?)
          GestureDetector(
            onTap: () => showMedalWallSheet(context, mid: widget.mid),
            child: FansMedalBadge(detail: fansDetail),
          ),
                                                                  
        if (profile?.fanDecorate case final decorate?) ...[
          const SizedBox(width: 6),
          FanDecorateBadge(
            decorate: decorate,
            height: 15,
            showImage: false,
          ),
        ],
                                               
        if (profile?.nameplate case final plate?) ...[
          const SizedBox(width: 6),
          NameplateBadge(plate: plate, height: 18),
        ],
      ],
    );
  }

                                              
  Widget _buildVerifyChip(ColorScheme cs) {
    final officialType = _profile?.officialType ?? -1;
    final desc = _profile?.officialDesc ?? '';
    if (desc.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.onInverseSurface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.offline_bolt,
            size: 15,
            color: officialType == 0
                ? const Color(0xFFF5A623)
                : const Color(0xFF23ADE5),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              desc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

                                                                 
  Widget _buildUidRow(ColorScheme cs) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final location = _profile?.location ?? '';
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () async {
            HapticFeedback.lightImpact();
            await Clipboard.setData(ClipboardData(text: '${widget.mid}'));
            if (mounted) {
              showAppToast(context, isZh ? '已复制 UID' : 'UID copied');
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Text(
              'UID: ${widget.mid}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
        ),
        if (location.isNotEmpty)
          Text(
            location.startsWith('IP') ? location : 'IP属地：$location',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        if (_profile?.userIdentity?.isNotEmpty ?? false)
          Text(
            _profile!.userIdentity!,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
      ],
    );
  }

                                           
  Widget _buildSignBlock(ColorScheme cs) {
    final sign = (_profile?.sign ?? '').trim();
    if (sign.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _signExpanded = !_signExpanded),
      child: Text(
        sign,
        maxLines: _signExpanded ? 8 : 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          height: 1.45,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }

                                                         
  Widget? _buildChargeRow(ColorScheme cs) {
    final profile = _profile;
    if (profile == null) return null;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final children = <Widget>[
      if (profile.elecTotal > 0)
        _buildChargeItem(
          cs,
          profile.elecAvatars,
          profile.elecTotal,
          '人为TA充电',
          Icons.bolt,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BilibiliUpowerRankPage(
                  mid: widget.mid,
                  name: _profile?.name ?? '',
                  count: profile.elecTotal,
                ),
              ),
            );
          },
          tooltip: isZh ? '查看充电排行榜' : 'View upower rank',
        ),
      if (profile.guardCount > 0)
        _buildChargeItem(
          cs,
          const [],
          profile.guardCount,
          '人加入大航海',
          Icons.anchor,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BilibiliGuardListPage(
                  mid: widget.mid,
                  name: _profile?.name ?? '',
                ),
              ),
            );
          },
          tooltip: isZh ? '查看大航海舰队' : 'View fleet',
        ),
    ];
    if (children.isEmpty) return null;
    return Padding(
      padding: EdgeInsets.zero,
      child: Wrap(spacing: 16, runSpacing: 6, children: children),
    );
  }

  Widget _buildChargeItem(
    ColorScheme cs,
    List<String> avatars,
    int count,
    String desc,
    IconData icon, {
    VoidCallback? onTap,
    String? tooltip,
  }) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: cs.primary),
        const SizedBox(width: 4),
        if (avatars.isNotEmpty) ...[
          for (var i = 0; i < avatars.take(3).length; i++)
            Padding(
              padding: EdgeInsets.only(right: i == 0 ? 0 : 2),
              child: Transform.translate(
                offset: Offset(i == 0 ? 0 : -6.0 * i, 0),
                child: ClipOval(
                  child: Image(
                    image: CachedImageProvider(
                      BilibiliUserSpaceService.avatarUrl(avatars[i], size: 48),
                      headers:
                          NetworkSettingsService.instance.apiHeaders.isEmpty
                          ? null
                          : NetworkSettingsService.instance.apiHeaders,
                    ),
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(width: 20, height: 20, color: cs.surfaceContainerHighest),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 2),
        ],
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: _formatCount(count),
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: ' $desc',
                style: TextStyle(fontSize: 12, color: cs.outline),
              ),
            ],
          ),
        ),
      ],
    );
    if (onTap == null) return row;
    final tappable = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: row,
      ),
    );
    return tooltip == null ? tappable : AppTooltip(message: tooltip, child: tappable);
  }

                               
  Widget _buildStatItem(
    ColorScheme cs,
    String label,
    int value, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
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
        ),
      ),
    );
  }

  Widget _buildStatDivider(ColorScheme cs) {
    return Container(
      width: 1,
      height: 26,
      color: cs.outlineVariant.withValues(alpha: 0.5),
    );
  }

                                          
          
                                          

  Widget _buildBanner(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var url = _bannerUrl;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: url.isEmpty ? null : _openBannerViewer,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url.isNotEmpty)
                                             
            Hero(
                transitionOnUserGestures: true,
              tag: _bannerHeroTag,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
              child: LazyCoverImage(
                url,
                fit: BoxFit.cover,
                maxDimension: 800,
                errorBuilder: (_, __, ___) => _buildBlurredAvatarFallback(cs),
              ),
            )
          else
            _buildBlurredAvatarFallback(cs),
                                                 
          DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.25),
            ),
          ),
                                     
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                                                             
                                                              
                                                               
                    cs.surfaceContainer.withValues(alpha: 0),
                    cs.surfaceContainer.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

                                                   
  String _bannerUrlOf() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final banner = _banner;
    var url = banner == null
        ? ''
        : (isDark && banner.dark.isNotEmpty ? banner.dark : banner.light);
    if (url.isEmpty) url = _profile?.topPhoto ?? '';
    return url;
  }

  String get _bannerUrl => _bannerUrlOf();

                                           
  String get _bannerHeroTag => 'space_banner_${widget.mid}';

  void _openBannerViewer() {
    final url = _bannerUrl;
    if (url.isEmpty) return;
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      heroTransitionRoute(
                                          
        heroZoom: true,
        page: ImageViewerPage(
          sources: [
            ImageViewerSource(url: url, heroTag: _bannerHeroTag),
          ],
        ),
      ),
    );
  }

                             
  Widget _buildBlurredAvatarFallback(ColorScheme cs) {
    final face = _profile?.face ?? '';
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
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }

                            
  Widget _buildSectionHeader(
    ColorScheme cs,
    String title, {
    required int count,
    Widget? trailing,
    IconData icon = Icons.video_library_outlined,
  }) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary),
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

                                        
  Widget _buildViewAllButton(ColorScheme cs, VoidCallback onTap) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(kGroupRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isZh ? '查看全部' : 'View all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
              Icon(Icons.chevron_right, size: 15, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }

                                                      
  Widget _buildHomeTab(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final preview = _videos.take(4).toList();
    return CustomScrollView(
      physics: const AppRefreshScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                                    
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            cs,
            l10n.userSpaceStatVideos,
            count: _videoCount,
            trailing: preview.isEmpty
                ? null
                : _buildViewAllButton(cs, () => _tabController.animateTo(2)),
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
                                    
        if (_dynamics.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              cs,
              l10n.userSpaceTabDynamic,
              count: _dynamics.length,
              icon: Icons.dynamic_feed_outlined,
              trailing: _buildViewAllButton(
                cs,
                () => _tabController.animateTo(1),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final dyn in _dynamics.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DynamicCard(
                        item: dyn,
                        ownerName: _profile?.name,
                        ownerFace: _profile?.face,
                        onTap: dyn.idStr.isEmpty
                            ? null
                            : () => _openDynamicDetail(dyn),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
        ),
      ],
    );
  }

                                        
  Widget _buildDynamicTab(ColorScheme cs) {
    if (_dynError != null && _dynamics.isEmpty) {
      return ListView(
        physics: const AppRefreshScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.25),
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
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
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
      child: CustomScrollView(
        physics: const AppRefreshScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
        slivers: [
          if (_dynamics.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  AppLocalizations.of(context).userSpaceNoDynamics,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ),
            )
          else ...[
                                 
            DynamicWaterfallSliver(
              items: _dynamics,
              itemKey: (item) => ValueKey<String>(item.idStr),
              singleColumnPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              multiColumnPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              spacing: 12,
              itemBuilder: (context, dyn) => _DynamicCard(
                item: dyn,
                ownerName: _profile?.name,
                ownerFace: _profile?.face,
                onTap: dyn.idStr.isEmpty
                    ? null
                    : () => _openDynamicDetail(dyn),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildLoadMoreFooter(
                loading: _dynLoadingMore,
                hasMore: _dynHasMore,
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 32,
              ),
            ),
          ],
        ],
      ),
    );
  }

                                                      
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
        physics: const AppRefreshScrollPhysics(
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
                             
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip(
                    cs,
                    icon: Icons.sort,
                    label: _videoOrder == 'pubdate' ? '最新发布' : '最多播放',
                    onTap: _toggleVideoOrder,
                  ),
                  if (_tlist.isNotEmpty)
                    _buildFilterChip(
                      cs,
                      icon: Icons.category_outlined,
                      label: _videoTid == 0
                          ? '全部分区'
                          : (_tlist[_videoTid]?.name ?? '分区'),
                      onTap: _showTidPicker,
                    ),
                ],
              ),
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

                        
  Widget _buildFilterChip(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(kGroupRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: cs.primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
              Icon(Icons.expand_more, size: 14, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }

                                    
  Future<void> _showTidPicker() async {
    final entries = _tlist.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      items: [
        NativeMenuItem(
          text: '全部分区',
          icon: Icons.apps,
          checked: _videoTid == 0,
          onTap: () => _selectVideoTid(0),
        ),
        for (final cat in entries)
          NativeMenuItem(
            text: cat.name,
            subtitle: '${cat.count}',
            icon: Icons.category_outlined,
            checked: cat.tid == _videoTid,
            onTap: () => _selectVideoTid(cat.tid),
          ),
      ],
    );
    if (nativeOk || !mounted) return;
    showAppBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.92,
      ),
      builder: (sheetCtx) {
        final cs = Theme.of(sheetCtx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.apps,
                  color: _videoTid == 0 ? cs.primary : cs.onSurfaceVariant,
                ),
                title: Text(
                  '全部分区',
                  style: TextStyle(
                    color: _videoTid == 0 ? cs.primary : cs.onSurface,
                    fontWeight: _videoTid == 0
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _selectVideoTid(0);
                },
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final cat = entries[index];
                    final selected = cat.tid == _videoTid;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.category_outlined,
                        size: 20,
                        color: selected ? cs.primary : cs.onSurfaceVariant,
                      ),
                      title: Text(
                        cat.name,
                        style: TextStyle(
                          color: selected ? cs.primary : cs.onSurface,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      trailing: Text(
                        '${cat.count}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        _selectVideoTid(cat.tid);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

                         
  void _checkGridLayoutChange(int cols, int count, double cellW, double cellH) {
    final firstHash = _videos.isEmpty ? 0 : _videos.first.bvid.hashCode;
    if (_prevGridCols == 0) {
      _prevGridCols = cols;
      _prevItemCount = count;
      _prevFirstHash = firstHash;
      return;
    }
    if (_prevGridCols == cols && _prevItemCount == count) return;
    if (count == 0 || _prevItemCount == 0) {
      _prevGridCols = cols;
      _prevItemCount = count;
      _prevFirstHash = firstHash;
      return;
    }

    final oldCols = _prevGridCols;
    final newCols = cols;
    final minCount = _prevItemCount < count ? _prevItemCount : count;

                       
    if (_prevFirstHash != firstHash) {
      _itemTranslations.clear();
      _prevGridCols = cols;
      _prevItemCount = count;
      _prevFirstHash = firstHash;
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
    _prevFirstHash = firstHash;

    if (anyMoved) {
      _gridRowAnimCtrl.reset();
      _gridRowAnimCtrl.forward();
    }
  }

                                       
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
              if (animate) {
                final delta = _itemTranslations[index];
                if (delta != null) {
                  card = ListenableBuilder(
                    listenable: _gridRowAnimCtrl,
                    builder: (context, _) {
                      final t = Curves.easeInOut.transform(
                        _gridRowAnimCtrl.value,
                      );
                      if (t >= 1.0) return card;
                      return Transform.translate(
                        offset: Offset(delta.dx * (1 - t), delta.dy * (1 - t)),
                        child: card,
                      );
                    },
                  );
                }
              }
              return card;
            }, childCount: videos.length),
          );
        },
      ),
    );
  }

                               
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
                                      
                                          
                              
    final leading = video.bvid.isNotEmpty
        ? Hero(
              transitionOnUserGestures: true,
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
    return AppTooltip(
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
            _prevFirstHash = 0;
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

                                          
                                  
                                          

  Widget _buildSeasonTab(ColorScheme cs) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    if (_seasonsLoading && _seasons == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: LoadingIndicatorM3E(),
        ),
      );
    }
    if (_seasonsError != null && _seasons == null) {
      return ListView(
        physics: const AppRefreshScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.video_collection_outlined,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              isZh ? '合集列表加载失败' : 'Failed to load seasons',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: FilledButton.icon(
              onPressed: () {
                setState(() {
                  _seasonsStarted = false;
                  _seasons = null;
                  _seasonsError = null;
                });
                _loadSeasons();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppLocalizations.of(context).scanRetry),
            ),
          ),
        ],
      );
    }
    final seasons = _seasons;
    if (seasons == null || seasons.items.isEmpty) {
      return ListView(
        physics: const AppRefreshScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.video_collection_outlined,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              isZh ? '暂无合集' : 'No seasons yet',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    }
    return CustomScrollView(
      physics: const AppRefreshScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.video_collection_outlined,
                  size: 16,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isZh
                      ? '合集 · 共 ${seasons.items.length} 个'
                      : 'Seasons · ${seasons.items.length}',
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
            gridDelegate:
                const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = seasons.items[index];
              return _SeasonCard(
                item: item,
                onTap: item.id > 0
                    ? () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _SeasonDetailPage(
                              mid: widget.mid,
                              item: item,
                              upName: _profile?.name ?? '',
                            ),
                          ),
                        );
                      }
                    : null,
              );
            }, childCount: seasons.items.length),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
        ),
      ],
    );
  }

                                          
                                  
                                          

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
        physics: const AppRefreshScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          const SizedBox(height: 90),
                             
          Center(child: _buildBangumiTypeToggle(cs)),
          const SizedBox(height: 10),
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              AppLocalizations.of(context).userSpaceBangumiLoadFailed,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
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
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return CustomScrollView(
      physics: const AppRefreshScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(child: Center(child: _buildBangumiTypeToggle(cs))),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (bangumi == null || bangumi.items.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  _bangumiType == 1
                      ? AppLocalizations.of(context).userSpaceNoBangumi
                      : (isZh ? '暂无追剧' : 'No dramas yet'),
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 16,
                    color: cs.primary,
                  ),
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
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 170,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.5,
                  ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = bangumi.items[index];
                return _BangumiCard(
                  item: item,
                  heroTag: item.seasonId > 0
                      ? 'bili_bangumi_${item.seasonId}'
                      : null,
                  onTap: item.seasonId > 0
                      ? () => openBilibiliBangumi(
                          context,
                          seasonId: item.seasonId,
                          initialTitle: item.title,
                          initialCover: BilibiliUserSpaceService
                              .bangumiCoverUrl(item.cover),
                          heroTag: 'bili_bangumi_${item.seasonId}',
                        )
                      : null,
                );
              }, childCount: bangumi.items.length),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
        ),
      ],
    );
  }

                                        
  Widget _buildCheeseTab(ColorScheme cs) {
    if (_cheeseLoading && _cheeseCourses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: LoadingIndicatorM3E(),
        ),
      );
    }
    if (_cheeseError != null && _cheeseCourses.isEmpty) {
      return ListView(
        physics: const AppRefreshScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          const SizedBox(height: 90),
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _cheeseError!,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: FilledButton.icon(
              onPressed: () {
                setState(() {
                  _cheeseStarted = false;
                  _cheeseError = null;
                });
                _loadCheese();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppLocalizations.of(context).scanRetry),
            ),
          ),
        ],
      );
    }
    return CustomScrollView(
      physics: const AppRefreshScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        if (_cheeseCourses.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  '暂无课程',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: _cheeseCourses.length,
              itemBuilder: (context, index) {
                final item = _cheeseCourses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CheeseCourseCard(
                    item: item,
                    onTap: item.seasonId > 0
                        ? () => openBilibiliCheese(
                            context,
                            seasonId: item.seasonId,
                            initialTitle: item.title,
                            initialCover: item.cover,
                            heroTag: 'bili_cheese_${item.seasonId}',
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          if (_cheeseHasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Center(
                  child: _cheeseLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : OutlinedButton(
                          onPressed: () => _loadCheese(more: true),
                          child: const Text('加载更多'),
                        ),
                ),
              ),
            ),
        ],
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
        ),
      ],
    );
  }

                                                      
  Widget _buildBangumiTypeToggle(ColorScheme cs) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return SegmentedButton<int>(
      segments: [
        ButtonSegment(
          value: 1,
          icon: const Icon(Icons.movie_outlined, size: 16),
          label: Text(
            isZh ? '番剧' : 'Anime',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        ButtonSegment(
          value: 2,
          icon: const Icon(Icons.live_tv_outlined, size: 16),
          label: Text(
            isZh ? '追剧' : 'Drama',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
      selected: {_bangumiType},
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: cs.secondaryContainer,
        selectedForegroundColor: cs.onSecondaryContainer,
        visualDensity: VisualDensity.compact,
      ),
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) _switchBangumiType(selection.first);
      },
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

                                            
                                    
                                            

class _CheeseCourseCard extends StatelessWidget {
  final CheeseCourseItem item;
  final VoidCallback? onTap;

  const _CheeseCourseCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 104,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Hero(
                tag: 'bili_cheese_${item.seasonId}',
                child: SizedBox(
                  width: 156,
                  child: item.cover.isEmpty
                      ? Container(color: cs.surfaceContainerHighest)
                      : Image(
                          image: CachedImageProvider(item.cover),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: cs.surfaceContainerHighest),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          if (item.statusText.isNotEmpty) ...[
                            Text(
                              item.statusText,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(
                            Icons.school_outlined,
                            size: 13,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '课堂',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
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
      ),
    );
  }
}

                                            
                                     
                                            

class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedTabBarDelegate({required this.tabController, this.onTabTap});

  final TabController tabController;

                                            
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
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final l10n = AppLocalizations.of(context);
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
          Tab(text: l10n.userSpaceTabHome),
          Tab(text: l10n.userSpaceTabDynamic),
          Tab(text: l10n.userSpaceStatVideos),
          Tab(text: isZh ? '合集' : 'Seasons'),
          Tab(text: l10n.userSpaceTabBangumi),
          Tab(text: isZh ? '课程' : 'Courses'),
          Tab(text: isZh ? '专栏' : 'Articles'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) =>
      oldDelegate.tabController != tabController ||
      oldDelegate.onTabTap != onTabTap;
}

                                            
                                  
                                            

class _DynamicCard extends StatelessWidget {
  final BiliUserDynamic item;
  final VoidCallback? onTap;

                                            
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
                                                 
        highlightColor: Colors.transparent,
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
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w500),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  final id = int.tryParse(node.rid) ?? 0;
                  if (id <= 0) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BilibiliTopicPage(
                        topicId: id,
                        name: topicNameFromText(node.text),
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
                                                 
                                   
    final heroTag = item.idStr.isNotEmpty
        ? 'space_dyn_img_${item.idStr}_$index'
        : 'space_dyn_img_${url.hashCode}_$index';
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          heroTransitionRoute(
                                              
            heroZoom: true,
            page: ImageViewerPage(
              sources: [
                for (var i = 0; i < item.images.length; i++)
                  ImageViewerSource(
                    url: item.images[i],
                    heroTag: item.idStr.isNotEmpty
                        ? 'space_dyn_img_${item.idStr}_$i'
                        : 'space_dyn_img_${item.images[i].hashCode}_$i',
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

                
  Widget _buildArchiveCard(BuildContext context, ColorScheme cs) {
    final title = item.title.isEmpty ? '视频动态' : item.title;
                                    
                                              
    return VideoCardH(
      data: VideoCardData(
        cover: item.cover.isEmpty
            ? ''
            : BilibiliUserSpaceService.coverUrl(item.cover),
        title: title,
        view: item.play,
        danmaku: item.danmaku,
      ),
      statsTrailing: item.durationText.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.durationText,
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
            )
          : null,
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
    );
  }

              
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
            ImmersiveMaterialPageRoute(
              page: ArticlePage(cvid: cvid, initialTitle: item.title),
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

                                            
                                      
                                            

class _VideoCard extends StatelessWidget {
  final BiliUserVideo video;
  final VoidCallback? onTap;
  final String? heroTag;

                                 
  final bool highlight;

                  
  final GlobalKey? cardKey;

  const _VideoCard({
    required this.video,
    this.onTap,
    this.heroTag,
    this.highlight = false,
    this.cardKey,
  });

  @override
  @override
  Widget build(BuildContext context) {
                                                
                                          
    Widget card = VideoCardV(
      data: VideoCardData(
        cover: BilibiliUserSpaceService.coverUrl(video.pic),
        title: BilibiliTitleCache.displayTitle(video.bvid, video.title),
        heroTag: heroTag,
        view: video.play,
        danmaku: video.danmaku,
        duration: video.duration,
        subtitle: _formatDate(video.created),
      ),
      onTap: onTap,
    );
    if (cardKey != null) {
      card = KeyedSubtree(key: cardKey!, child: card);
    }
    if (highlight) {
                                   
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
        child: card,
      );
    }
    return card;
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
            transitionOnUserGestures: true,
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
                        Colors.black.withValues(alpha: 0.55),
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
        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
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
                        transitionOnUserGestures: true,
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
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                                ),
                              ),
                            )
                          : Container(
                              color: cs.surfaceContainerHighest,
                              child: Icon(
                                Icons.movie_outlined,
                                size: 32,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
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
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        Icons.movie_outlined,
                        size: 32,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
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
                            Colors.black.withValues(alpha: 0.55),
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
                          color: Colors.black.withValues(alpha: 0.65),
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
                          color: Colors.black.withValues(alpha: 0.65),
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
                        color: cs.primary.withValues(alpha: 0.9),
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

                                            
                                            
                                            

class _SeasonCard extends StatelessWidget {
  final BiliSpaceSeasonItem item;
  final VoidCallback? onTap;

  const _SeasonCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
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
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.cover.isNotEmpty)
                    Image(
                      image: CachedImageProvider(
                        BilibiliUserSpaceService.coverUrl(item.cover),
                        headers:
                            NetworkSettingsService.instance.apiHeaders.isEmpty
                            ? null
                            : NetworkSettingsService.instance.apiHeaders,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.video_collection_outlined,
                          size: 32,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        Icons.video_collection_outlined,
                        size: 32,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                                   
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.isSeason
                                ? Icons.video_collection_outlined
                                : Icons.playlist_play,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            item.isSeason
                                ? (isZh ? '合集' : 'Season')
                                : (isZh ? '系列' : 'Series'),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (item.total > 0)
                    Positioned(
                      right: 6,
                      bottom: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isZh ? '${item.total} 个内容' : '${item.total} items',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

                                            
                                               
                                            

class _SeasonDetailPage extends StatefulWidget {
  final int mid;
  final BiliSpaceSeasonItem item;
  final String upName;

  const _SeasonDetailPage({
    required this.mid,
    required this.item,
    required this.upName,
  });

  @override
  State<_SeasonDetailPage> createState() => _SeasonDetailPageState();
}

class _SeasonDetailPageState extends State<_SeasonDetailPage> {
  final List<BiliUserVideo> _videos = [];
  int _total = 0;
  int? _next;                                   
  int _pn = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final page = await BilibiliUserSpaceService.fetchSeasonVideos(
      mid: widget.mid,
      seasonId: widget.item.isSeason ? widget.item.seasonId : null,
      seriesId: widget.item.isSeason ? null : widget.item.seriesId,
      next: _next,
      pn: _pn,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      if (page == null) {
        _error = BilibiliUserSpaceService.lastErrorDetail;
        return;
      }
      _videos.addAll(page.videos);
      _total = page.total;
      _hasMore = page.hasMore;
      _next = page.next;
      if (_next == null) _pn += 1;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLow,
        scrolledUnderElevation: 0,
        title: Text(
          widget.item.name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 300) {
            _loadMore();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AppRefreshScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  '${widget.upName} · ${l10n.userSpaceVideoCount(_total > 0 ? _total : _videos.length)}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
            ),
            if (shouldShowFullScreenLoading(
              loading: _loading,
              isEmpty: _videos.isEmpty,
            ))
              const PageLoadingSliver()
            else if (_error != null && _videos.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error ?? l10n.userSpaceLoadFailed,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        _load();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(l10n.scanRetry),
                    ),
                  ],
                ),
              )
            else if (_videos.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    l10n.userSpaceNoVideos,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ),
              )
            else ...[
              const SliverPadding(padding: EdgeInsets.only(top: 8)),
              _buildVideoGrid(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _loadingMore
                        ? const LoadingIndicatorM3E()
                        : (_hasMore
                              ? const SizedBox(height: 8)
                              : Text(
                                  l10n.searchAllLoaded,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                )),
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

                                   
  Widget _buildVideoGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final columns = (constraints.crossAxisExtent / 200)
              .floor()
              .clamp(2, 8);
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == _videos.length - 1) _loadMore();
              final video = _videos[index];
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
            }, childCount: _videos.length),
          );
        },
      ),
    );
  }
}

                                            
                                                 
                                            

class _CoinLikeArcPage extends StatefulWidget {
  final int mid;
  final String mode;                           
  final String name;

  const _CoinLikeArcPage({
    required this.mid,
    required this.mode,
    required this.name,
  });

  @override
  State<_CoinLikeArcPage> createState() => _CoinLikeArcPageState();
}

class _CoinLikeArcPageState extends State<_CoinLikeArcPage> {
  final List<BiliCoinLikeItem> _items = [];
  int _pn = 1;
  int _count = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final page = await BilibiliUserSpaceService.fetchCoinLikeArc(
      mid: widget.mid,
      mode: widget.mode,
      pn: _pn,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      if (page == null) {
        _error = BilibiliUserSpaceService.lastErrorDetail;
        return;
      }
      _items.addAll(page.items);
      _count = page.count;
      _hasMore = page.items.isNotEmpty && _items.length < _count;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    _pn += 1;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final title = widget.mode == 'coin'
        ? (isZh ? '最近投币' : 'Recent coins')
        : (isZh ? '获赞的视频' : 'Liked videos');
    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLow,
        scrolledUnderElevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 300) {
            _loadMore();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AppRefreshScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            if (shouldShowFullScreenLoading(
              loading: _loading,
              isEmpty: _items.isEmpty,
            ))
              const PageLoadingSliver()
            else if (_error != null && _items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        _error ?? l10n.userSpaceLoadFailed,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        _load();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(l10n.scanRetry),
                    ),
                  ],
                ),
              )
            else if (_items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    isZh ? '暂无记录' : 'Nothing here yet',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = (constraints.crossAxisExtent / 200)
                        .floor()
                        .clamp(2, 8);
                    return SliverGrid(
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == _items.length - 1) _loadMore();
                        final video = _items[index].toVideo();
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
                      }, childCount: _items.length),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _loadingMore
                        ? const LoadingIndicatorM3E()
                        : (_hasMore
                              ? const SizedBox(height: 8)
                              : Text(
                                  l10n.searchAllLoaded,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                )),
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

                                            
                                     
                                            

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

           
    if (_loading && _results.isEmpty) {
      return const Center(child: LoadingIndicatorM3E());
    }

             
    if (_error != null && _results.isEmpty) {
      return ListView(
        physics: const AppRefreshScrollPhysics(
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

          
    if (_results.isEmpty) {
      return ListView(
        physics: const AppRefreshScrollPhysics(
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
      physics: const AppRefreshScrollPhysics(
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
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
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
