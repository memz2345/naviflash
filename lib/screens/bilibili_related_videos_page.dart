                                                
  
                     
                                   
                              
                          
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bilibili_translate_api.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:naviflash/services/bilibili_video_service.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/ugc_selection_area.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/standard_list_page.dart';
import 'package:naviflash/widgets/video_card.dart';
import 'package:naviflash/widgets/page_loading.dart';

class BilibiliRelatedVideosPage extends StatefulWidget {
                
  final String bvid;

                                           
  final Widget? header;

                                              
                                              
  final bool heroTagsDisabled;

  const BilibiliRelatedVideosPage({
    super.key,
    required this.bvid,
    this.header,
    this.heroTagsDisabled = false,
  });

                                         
  static final ValueNotifier<bool> _gridMode = ValueNotifier(true);
  static bool _gridLoaded = false;

                                       
  static ValueNotifier<bool> get gridModeNotifier => _gridMode;
  static void toggleGridMode() {
    _gridMode.value = !_gridMode.value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('bili_related_grid_mode', _gridMode.value),
    );
  }

  @override
  State<BilibiliRelatedVideosPage> createState() =>
      _BilibiliRelatedVideosPageState();
}

class _BilibiliRelatedVideosPageState extends State<BilibiliRelatedVideosPage>
    with AutomaticKeepAliveClientMixin {
  List<BiliRelatedVideo>? _items;
  bool _loading = true;
  String? _error;

                                
  final Map<String, String> _titleOverrides = {};

                                           
                         
  final Set<String> _showOriginalTitles = {};

                                          
                            
  static const Duration _cacheTtl = Duration(minutes: 10);
  static final Map<String, _CachedRelated> _cache = {};
  static final Set<String> _animatedBvids = {};

                                     
  bool _animateCards = false;

  Future<void> _ensureGridLoaded() async {
    if (BilibiliRelatedVideosPage._gridLoaded) return;
    BilibiliRelatedVideosPage._gridLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    BilibiliRelatedVideosPage._gridMode.value =
        prefs.getBool('bili_related_grid_mode') ?? true;
  }

  void _onGridModeChanged() {
    if (mounted) setState(() {});
  }

  @override
  bool get wantKeepAlive => true;

                                  
                        
  String _titleFor(BiliRelatedVideo item) {
    if (_showOriginalTitles.contains(item.bvid)) return item.title;
    final local = _titleOverrides[item.bvid];
    if (local != null && local.isNotEmpty) return local;
    return BilibiliTitleCache.displayTitle(item.bvid, item.title);
  }

                                   
                                  
  Future<void> _translateTitles() async {
    final items = _items;
    if (items == null || items.isEmpty) return;
    final translate = BilibiliTranslateService.instance;
    if (!translate.enabled) return;
    final list = <({String bvid, String title})>[];
    final overrides = <String, String>{};
    for (final v in items) {
      if (v.bvid.isEmpty || v.title.isEmpty) continue;
      final cached = BilibiliTitleCache.translatedTitle(v.bvid);
      if (cached != null) {
        overrides[v.bvid] = cached;
      } else {
        list.add((bvid: v.bvid, title: v.title));
      }
    }
    if (overrides.isNotEmpty && mounted) {
      setState(() => _titleOverrides.addAll(overrides));
    }
    if (list.isEmpty) return;
    final remote = await BilibiliTranslateApi.translateTitles(list);
    if (!mounted || remote.isEmpty) return;
    BilibiliTitleCache.rememberAll(remote);
    setState(() {
      _titleOverrides.addAll(remote);
    });
  }

  @override
  void initState() {
    super.initState();
    _ensureGridLoaded();
    BilibiliRelatedVideosPage._gridMode.addListener(_onGridModeChanged);
                                           
    final cached = _cache[widget.bvid];
    if (cached != null && DateTime.now().difference(cached.time) < _cacheTtl) {
      _items = cached.items;
      _loading = false;
      _error = null;
                                           
      _translateTitles();
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    BilibiliRelatedVideosPage._gridMode.removeListener(_onGridModeChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BilibiliRelatedVideosPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bvid != widget.bvid) {
                        
      _items = null;
      _load(forceRefresh: true);
    }
  }

             
                                             
                            
  Future<void> _load({
    bool forceRefresh = false,
    bool fromPull = false,
  }) async {
    final keep = fromPull || (_items?.isNotEmpty ?? false);
    if (!keep) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final list = await BilibiliVideoService.fetchRelated(
      widget.bvid,
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;
                              
    final seen = <String>{};
    final deduped = list
        .where((v) => v.bvid.isNotEmpty && seen.add(v.bvid))
        .toList();
                                    
    final failed = deduped.isEmpty && BilibiliVideoService.lastErrorDetail != null;
    final firstTime = _animatedBvids.add(widget.bvid);
    if (!failed || !keep) {
      _cache[widget.bvid] = _CachedRelated(deduped);
    }
    setState(() {
      _loading = false;
      if (!failed || !keep) {
        _items = deduped;
        _animateCards = firstTime;
        _error = deduped.isEmpty ? BilibiliVideoService.lastErrorDetail : null;
      }
    });
                               
    _translateTitles();
    if (firstTime) {
                                          
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _animateCards = false);
      });
    }
  }

  void _open(BiliRelatedVideo item) {
                                                   
                                                            
                                                      
    openBilibiliVideo(
      context,
      bvid: item.bvid,
      initialTitle: _titleFor(item),
      initialCover: item.pic,
      heroTag: widget.heroTagsDisabled ? null : 'bili_video_${item.bvid}',
      wideClassic: true,
    );
  }

  void _showLongPressMenu(BiliRelatedVideo item) {
    showVideoBottomSheet(
      context,
      bvid: item.bvid,
      title: item.title,
      cover: item.pic,
      author: item.ownerName,
      showOriginal: _showOriginalTitles.contains(item.bvid),
      onToggleOriginal: (show) => _setShowOriginal(item.bvid, show),
    );
  }

                               
  void _showContextMenu(BiliRelatedVideo item, Offset globalPosition) {
    showVideoContextMenu(
      context,
      bvid: item.bvid,
      title: item.title,
      cover: item.pic,
      author: item.ownerName,
      globalPosition: globalPosition,
      showOriginal: _showOriginalTitles.contains(item.bvid),
      onToggleOriginal: (show) => _setShowOriginal(item.bvid, show),
    );
  }

                                      
  void _setShowOriginal(String bvid, bool show) {
    setState(() {
      if (show) {
        _showOriginalTitles.add(bvid);
      } else {
        _showOriginalTitles.remove(bvid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final items = _items;
    return Stack(
      children: [
        UgcSelectionArea(
          child: AppRefreshIndicator(
          onRefresh: () => _load(forceRefresh: true, fromPull: true),
          color: cs.primary,
          child: CustomScrollView(
                                            
                                                 
            physics: shouldShowFullScreenLoading(
              loading: _loading,
              isEmpty: items?.isEmpty ?? true,
            )
                ? const NeverScrollableScrollPhysics()
                : const AppRefreshScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
            slivers: [
              if (widget.header != null)
                SliverToBoxAdapter(child: widget.header),
              if (shouldShowFullScreenLoading(
                loading: _loading,
                isEmpty: items?.isEmpty ?? true,
              ))
                const PageLoadingSliver()
              else if (_error != null && items!.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _errorView(cs))              else if (items!.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).relatedEmpty,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else if (!BilibiliRelatedVideosPage._gridMode.value)
                                              
                videoCardListSliver(
                  itemCount: items.length,
                  itemBuilder: (_, i) => _CardEntrance(
                    index: i,
                    animate: _animateCards,
                    child: _listCard(cs, items[i]),
                  ),
                )
              else
                                               
                                                    
                videoCardGridSliver(
                  itemCount: items.length,
                  itemBuilder: (_, i) => _CardEntrance(
                    index: i,
                    animate: _animateCards,
                    child: _gridCard(cs, items[i]),
                  ),
                ),
              bottomSpaceSliver(context),
            ],
          ),
        ),
        ),
                                        
        if (_error != null && items != null && items.isEmpty)
          PositionedRetryFab(onRetry: () => _load(forceRefresh: true)),
      ],
    );
  }

  Widget _errorView(ColorScheme cs) {
    return Center(
      child: Text(
        _error ?? AppLocalizations.of(context).biliLoadFailed,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
    );
  }

                                                                      

                                            
  Widget _gridCard(ColorScheme cs, BiliRelatedVideo item) {
    return VideoCardV(
      data: _videoCardData(item),
      onTap: () => _open(item),
      onLongPress: () => _showLongPressMenu(item),
      onSecondaryTap: (pos) => _showContextMenu(item, pos),
    );
  }

                                              
  Widget _listCard(ColorScheme cs, BiliRelatedVideo item) {
    return VideoCardH(
      data: _videoCardData(item),
      onTap: () => _open(item),
      onLongPress: () => _showLongPressMenu(item),
      onSecondaryTap: (pos) => _showContextMenu(item, pos),
    );
  }

                                                  
                                                         
                             
  VideoCardData _videoCardData(BiliRelatedVideo item) => VideoCardData(
    cover: item.pic,
    title: _titleFor(item),
    heroTag: (item.bvid == widget.bvid || widget.heroTagsDisabled)
        ? null
        : 'bili_video_${item.bvid}',
    view: item.view,
    danmaku: item.danmaku,
    duration: item.duration,
    ownerName: item.ownerName,
    pubdate: item.pubdate,
  );

}

class _CardEntrance extends StatefulWidget {
  final int index;
  final bool animate;
  final Widget child;

  const _CardEntrance({
    required this.index,
    required this.animate,
    required this.child,
  });

  @override
  State<_CardEntrance> createState() => _CardEntranceState();
}

class _CardEntranceState extends State<_CardEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scale = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    if (widget.animate) {
                            
      Future.delayed(Duration(milliseconds: 40 + widget.index * 20), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

               
class _CachedRelated {
  final List<BiliRelatedVideo> items;
  final DateTime time;
  _CachedRelated(this.items) : time = DateTime.now();
}
