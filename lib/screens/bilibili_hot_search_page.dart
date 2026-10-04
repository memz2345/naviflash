                                            
  
                                                 
                                   
                                 
                                            
                               
                       
                                       
                      
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_search_page.dart';
import 'package:naviflash/services/bilibili_search_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/back_top_fab.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/page_background.dart';

class BilibiliHotSearchPage extends StatefulWidget {
  const BilibiliHotSearchPage({super.key});

  @override
  State<BilibiliHotSearchPage> createState() => _BilibiliHotSearchPageState();
}

class _BilibiliHotSearchPageState extends State<BilibiliHotSearchPage> {
  static const double kTopBarHeight = 56.0;

  final ScrollController _scrollController = ScrollController();

  List<BiliHotSearchItem> _items = const [];
  int _topCount = 0;
  bool _loading = true;
  String? _error;

                                      
  String? _bannerUrl;

                                           
  final ValueNotifier<double> _topBarRatio = ValueNotifier(0.0);

                                
  double _bannerHeight = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadBanner();
  }

  @override
  void dispose() {
    _topBarRatio.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBanner() async {
    final url = await BilibiliSearchService.fetchPageHeader();
    if (!mounted || url == null) return;
    setState(() => _bannerUrl = url);
  }

                                           
  void _onScroll(ScrollNotification n) {
    if (_bannerUrl == null) return;
    final top = MediaQuery.of(context).padding.top;
    final range = _bannerHeight - kTopBarHeight - top;
    if (range <= 0) return;
    final ratio = (n.metrics.pixels / range).clamp(0.0, 1.0);
    if ((ratio - _topBarRatio.value).abs() > 0.004) {
      _topBarRatio.value = ratio;
    }
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (mounted && !forceRefresh) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final res = await BilibiliSearchService.searchTrending(
      limit: 30,
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (res) {
        case BiliHotSearchOk(:final items, :final topCount):
          _items = items;
          _topCount = topCount;
          _error = null;
        case BiliHotSearchFail(:final detail):
          _error = detail;
      }
    });
  }

  void _onTapItem(BiliHotSearchItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BilibiliSearchPage(initialKeyword: item.keyword),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
                                               
    _bannerHeight = _bannerUrl == null
        ? 0
        : MediaQuery.sizeOf(context).width * 528 / 1125;
    final scaffold = Scaffold(
      backgroundColor: cs.surfaceContainer,
      floatingActionButton: _error != null
          ? LoadRetryPill(onRetry: () => _load(forceRefresh: true))
          : BackTopFab(
              extended: false,
              onTap: () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
      body: Stack(
        children: [
                                      
          PageBackground(baseColor: cs.surfaceContainer, contentStyle: true),
          SafeArea(
            child: Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    _onScroll(n);
                    return false;
                  },
                  child: Positioned.fill(child: _buildBody(cs, l10n)),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: _buildTopBar(cs, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return IosBackdropScale(child: scaffold);
  }

  Widget _buildTopBar(ColorScheme cs, AppLocalizations l10n) {
                                            
    return ValueListenableBuilder<double>(
      valueListenable: _topBarRatio,
      builder: (context, ratio, _) {
        final hasBanner = _bannerUrl != null;
        final onBanner = hasBanner && ratio < 0.5;
        final fg = onBanner ? Colors.white : cs.onSurface;
        return FrostedPanel(
                                     
          opacity: hasBanner ? 0.75 * ratio : 0.75,
          blurSigma: hasBanner ? 10.0 * ratio : 10.0,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kTopBarHeight,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  MorphIconButton(
                    icon: Icons.arrow_back,
                    tooltip: l10n.homeBack,
                    onTap: () => Navigator.of(context).pop(),
                    frosted: true,
                    iconColor: onBanner ? Colors.white : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.hotSearchTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: fg,
                                              
                        shadows: onBanner
                            ? const [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 6,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                  MorphIconButton(
                    icon: Icons.refresh_outlined,
                    tooltip: l10n.refreshAction,
                    iconSize: 20,
                    iconColor: onBanner ? Colors.white : cs.onSurfaceVariant,
                    frosted: true,
                    onTap: () => _load(forceRefresh: true),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

                                             
                                       
  Widget _buildBanner(double width, ColorScheme cs) {
    final url = _bannerUrl!;
    return SizedBox(
      height: _bannerHeight,
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
                                   
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primaryContainer.withValues(alpha: 0.55),
                  cs.surfaceContainerHighest.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
          Image.network(
            url,
            fit: BoxFit.cover,
            headers: NetworkSettingsService.instance.apiHeaders,
            errorBuilder: (_, _, _) {
                                      
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _bannerUrl != null) {
                  setState(() => _bannerUrl = null);
                }
              });
              return const SizedBox.shrink();
            },
          ),
                                     
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.32),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme cs, AppLocalizations l10n) {
    if (_loading && _items.isEmpty) {
      return const Center(child: LoadingIndicatorM3E());
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 44,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => _load(forceRefresh: true),
                child: Text(l10n.refreshAction),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          l10n.searchDiscoveryEmpty,
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      );
    }
    return AppRefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      color: cs.primary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
                                          
          if (_bannerUrl != null)
            SliverToBoxAdapter(
              child: _buildBanner(MediaQuery.sizeOf(context).width, cs),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: kTopBarHeight)),
          SliverList.separated(
            itemCount: _items.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              indent: 52,
              endIndent: 16,
              color: cs.outlineVariant.withValues(alpha: 0.18),
            ),
            itemBuilder: (context, index) => _buildRow(cs, index),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(ColorScheme cs, int index) {
    final item = _items[index];
    final isTop = index < _topCount;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: () => _onTapItem(item),
      leading: SizedBox(
        width: 28,
        child: Center(
          child: isTop
              ? const Icon(
                  Icons.vertical_align_top_outlined,
                  size: 18,
                  color: Color(0xFFd1403e),
                )
              : Text(
                  '${index + 1 - _topCount}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontSize: 17,
                    color: _rankColor(index - _topCount, cs),
                  ),
                ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              item.keyword,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, height: 1.1),
            ),
          ),
          if (item.icon != null && item.icon!.isNotEmpty) ...[
            const SizedBox(width: 5),
            Image.network(
              item.icon!,
              height: 15,
              headers: NetworkSettingsService.instance.apiHeaders,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ] else if (item.showLiveIcon) ...[
            const SizedBox(width: 5),
            _liveBadge(cs),
          ],
        ],
      ),
    );
  }

                                      
                
  Widget _liveBadge(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFfb7299),
        borderRadius: BorderRadius.circular(2),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          fontSize: 9,
          height: 1.1,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

                                              
  Color _rankColor(int rank, ColorScheme cs) {
    return switch (rank) {
      0 => const Color(0xFFfdad13),
      1 => const Color(0xFF8aace1),
      2 => const Color(0xFFdfa777),
      _ => cs.outline,
    };
  }
}
