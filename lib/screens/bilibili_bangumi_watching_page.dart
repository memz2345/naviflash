                                                  
  
                    
                                                         
                                                            
                                                     
                                    
                                               
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_bangumi_page.dart';
import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/src/content_reveal_gate.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/back_top_fab.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/lazy_cover_image.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/video_card.dart';
import 'package:naviflash/widgets/page_loading.dart';

                      
const double _kTopBarHeight = 56.0;

                                         
const int _pageSize = 20;

class BilibiliBangumiWatchingPage extends StatefulWidget {
  const BilibiliBangumiWatchingPage({super.key});

  @override
  State<BilibiliBangumiWatchingPage> createState() =>
      _BilibiliBangumiWatchingPageState();
}

class _BilibiliBangumiWatchingPageState
    extends State<BilibiliBangumiWatchingPage> {
  bool _isLoggedIn = false;

  List<BiliUserBangumi> _items = [];
  int _total = 0;
  int _pn = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  final _fabVisibility = BackTopFabVisibility();
  late final ScrollController _scroll = ScrollController();

                                    
                               
  ContentRevealGate? _revealGate;

  bool get _isContentGated => _revealGate?.isGated ?? false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScrollPosition);
    _isLoggedIn = BilibiliAccountService.instance.isLoggedIn;
    if (_isLoggedIn) _load(forceRefresh: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _revealGate?.dispose();
    _revealGate = null;
    super.dispose();
  }

                                 
                             
  void _armRevealGate() {
    _revealGate?.dispose();
    _revealGate = ContentRevealGate(
                                         
      onUnlock: () {
        if (mounted) setState(() {});
      },
    )..arm(context);
  }

  void _onScrollPosition() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) _loadMore();
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n is! ScrollUpdateNotification) return false;
    final labelChanged = _fabVisibility.update(n.scrollDelta ?? 0);
    if (labelChanged && mounted) setState(() {});
    return false;
  }

  void _scrollToTop() {
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

             

  Future<void> _load({bool forceRefresh = false}) async {
    if (!forceRefresh && (_loading || _loadingMore)) return;
    if (!mounted) return;
    if (forceRefresh) {
      final showFullscreen = _items.isEmpty;
      if (showFullscreen) _armRevealGate();
      setState(() {
        _loading = showFullscreen;
        _loadingMore = false;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    final targetPn = forceRefresh ? 1 : _pn + 1;
    final mid = BilibiliAccountService.instance.mid;
    final page = await BilibiliUserSpaceService.fetchUserBangumi(
      mid: mid,
      followStatus: 2,          
      pn: targetPn,
      ps: _pageSize,
    );
    if (!mounted) return;
    if (page == null) {
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (forceRefresh || _items.isEmpty) {
          _error = BilibiliUserSpaceService.lastErrorDetail ?? '加载失败，请重试';
        }
        if (!forceRefresh) _hasMore = false;
      });
      return;
    }
                                       
    final seen = <int>{
      if (!forceRefresh) for (final it in _items) it.seasonId,
    };
    final fresh = page.items.where((it) => seen.add(it.seasonId)).toList();
    setState(() {
      if (forceRefresh) {
        _items = fresh;
        _pn = 1;
      } else {
        _items = [..._items, ...fresh];
        _pn = targetPn;
      }
      _total = page.total;
                                    
      _hasMore = fresh.isNotEmpty &&
          (_total <= 0 ? fresh.length >= _pageSize : _items.length < _total);
      _loading = false;
      _loadingMore = false;
      _error = null;
    });
  }

  void _loadMore() {
    if (_loading || _loadingMore || !_hasMore || _error != null) return;
    _load();
  }

                      
  Future<void> _goLogin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BilibiliLoginScreen()),
    );
    if (!mounted) return;
    final loggedIn = BilibiliAccountService.instance.isLoggedIn;
    if (loggedIn != _isLoggedIn || (loggedIn && _items.isEmpty && !_loading)) {
      setState(() => _isLoggedIn = loggedIn);
      if (loggedIn) _load(forceRefresh: true);
    }
  }

  void _openItem(BiliUserBangumi item) {
    FocusManager.instance.primaryFocus?.unfocus();
    openBilibiliBangumi(
      context,
      seasonId: item.seasonId,
      initialTitle: item.title,
      initialCover: BilibiliUserSpaceService.bangumiCoverUrl(item.cover),
      heroTag: 'bili_bangumi_${item.seasonId}',
    );
  }

             

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scaffold = Scaffold(
      backgroundColor: cs.surfaceContainer,
                                            
      floatingActionButton: !_isLoggedIn || (_error != null && _items.isEmpty)
          ? (_isLoggedIn ? LoadRetryPill(onRetry: () => _load(forceRefresh: true)) : null)
          : BackTopFab(
              extended: _fabVisibility.extended,
              onTap: _scrollToTop,
            ),
      body: Stack(
        children: [
                                             
          PageBackground(baseColor: cs.surfaceContainer, contentStyle: true),
          SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: _buildBody(cs)),
                Align(
                  alignment: Alignment.topCenter,
                  child: _buildTopBar(cs),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return IosBackdropScale(child: scaffold);
  }

  Widget _buildBody(ColorScheme cs) {
                        
    if (!_isLoggedIn) {
      return Column(
        children: [
          SizedBox(height: _kTopBarHeight),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 44,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '登录后可查看追番进度',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(onPressed: _goLogin, child: const Text('去登录')),
                ],
              ),
            ),
          ),
        ],
      );
    }
                                     
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _items.isEmpty,
    ) ||
        _isContentGated) {
      return Column(
        children: [
          SizedBox(height: _kTopBarHeight),
          const Expanded(child: PageLoadingIndicator()),
        ],
      );
    }
    if (_error != null && _items.isEmpty) {
      return Column(
        children: [
          SizedBox(height: _kTopBarHeight),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return Column(
        children: [
          SizedBox(height: _kTopBarHeight),
          Expanded(
            child: Center(
              child: Text(
                '还没有正在追的番剧',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ],
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: AppRefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        color: cs.primary,
                                                
                              
        edgeOffset: context.watch<SettingsService>().refreshEdgeOffset,
        displacement:
            _kTopBarHeight + 10 - 40.0 + context.watch<SettingsService>().refreshDisplacement,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AppRefreshScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
                                          
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                height: _kTopBarHeight,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final columns = (width / 150).floor().clamp(2, 6);
                  final cardW = (width - (columns - 1) * 12) / columns;
                                                  
                  final cellH = cardW * 4 / 3 + 84 + 12;
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: cardW / cellH,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _WatchingCard(
                        item: _items[i],
                        onTap: () => _openItem(_items[i]),
                      ),
                      childCount: _items.length,
                    ),
                  );
                },
              ),
            ),
            if (_loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 72,
              ),
            ),
          ],
        ),
      ),
    );
  }

                                  
  Widget _buildTopBar(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return FrostedPanel(
      opacity: 0.75,
      blurSigma: 12,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _kTopBarHeight,
          child: Row(
            children: [
              const SizedBox(width: 8),
              MorphIconButton(
                icon: Icons.arrow_back,
                tooltip: l10n.homeBack,
                onTap: () => Navigator.of(context).pop(),
                frosted: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '正在追的番剧',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

                                           
                                        
                                           

                                           
                                 
                                      
                                           

class _WatchingCard extends StatelessWidget {
  final BiliUserBangumi item;
  final VoidCallback onTap;

  const _WatchingCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    final progress = item.progress.isNotEmpty
        ? item.progress
        : item.newEpIndex;
    final meta = <String>[
      if (item.ratingScore > 0) '${item.ratingScore.toStringAsFixed(1)} 分',
      item.isFinish ? '已完结' : '连载中',
    ].join(' · ');
    return VideoCardV(
      data: VideoCardData(
        cover: BilibiliUserSpaceService.bangumiCoverUrl(item.cover),
        title: item.title,
                                 
        heroTag: 'bili_bangumi_${item.seasonId}',
                                                    
        coverAspect: 3 / 4,
        badge: item.badge.isNotEmpty ? item.badge : null,
        reason: progress.isNotEmpty ? progress : null,
        subtitle: meta,
        coverWidget: LazyCoverImage(
          BilibiliUserSpaceService.bangumiCoverUrl(item.cover),
          headers: headers,
          fit: BoxFit.cover,
          aspect: 3 / 4,
          maxDimension: 480,
        ),
      ),
      onTap: onTap,
    );
  }
}
