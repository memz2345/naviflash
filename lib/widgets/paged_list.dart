                              
  
                                   
                                                  
                                                    
  
                                         
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/paged_result.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/standard_list_page.dart';

                              
Widget genericGridSliver({
  required int itemCount,
  required Widget Function(BuildContext context, int index) itemBuilder,
  double aspectRatio = 0.78,
  double spacing = 12,
  double targetWidth = 200,
  int minColumns = 2,
  int maxColumns = 8,
  EdgeInsets padding = const EdgeInsets.fromLTRB(16, 4, 16, 8),
}) {
  if (itemCount == 0) return const SliverToBoxAdapter(child: SizedBox.shrink());
  return SliverPadding(
    padding: padding,
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final columns = (width / targetWidth)
            .floor()
            .clamp(minColumns, maxColumns);
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => itemBuilder(context, index),
            childCount: itemCount,
          ),
        );
      },
    ),
  );
}

                      
const Widget _loadingMoreSliver = SliverToBoxAdapter(
  child: SizedBox(
    height: 56,
    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
  ),
);

                    
   
                                          
                               
class BiliListPage<T> extends StatefulWidget {
  final String title;
  final Future<PagedResult<T>> Function(int page) fetcher;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double gridAspect;

                             
  final Widget? bottom;

                    
  final double bottomHeight;
  final bool showBack;

  const BiliListPage({
    super.key,
    required this.title,
    required this.fetcher,
    required this.itemBuilder,
    this.gridAspect = 0.78,
    this.bottom,
    this.bottomHeight = 0,
    this.showBack = true,
  });

  @override
  State<BiliListPage<T>> createState() => _BiliListPageState<T>();
}

class _BiliListPageState<T> extends State<BiliListPage<T>> {
  late final PagedListController<T> _ctl;
  final ScrollController _scroll = ScrollController();

                                    
                                        
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();

                             
  bool _atTop = true;

  @override
  void initState() {
    super.initState();
    _ctl = PagedListController<T>(widget.fetcher);
    _ctl.refresh();
    _scroll.addListener(() {
      final atTop = _scroll.position.pixels <= 0.5;
      if (atTop != _atTop && mounted) setState(() => _atTop = atTop);
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 600) {
        _ctl.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

                                     
                  
  Future<void> _refreshWithToast() async {
    await _ctl.refresh();
    if (_ctl.error != null && mounted) {
      showAppToast(context, _ctl.error!, error: true);
    }
  }

                                        
                               
  void _userReload() {
    final state = _refreshKey.currentState;
    if (state == null) {
      _refreshWithToast();
      return;
    }
    state.show();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final topH = kStdTopBarHeight + widget.bottomHeight;
    return StandardListScaffold(
      topBar: StandardListTopBar(
        title: widget.title,
        showBack: widget.showBack,
        bottom: widget.bottom,
        bottomHeight: widget.bottomHeight,
      ),
      body: ListenableBuilder(
        listenable: _ctl,
        builder: (context, _) {
          if (!_ctl.initiallyLoaded && _ctl.loading) {
            return CustomScrollView(
              slivers: [
                topBarSpaceSliver(topH),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 260,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ],
            );
          }
          if (_ctl.error != null && _ctl.items.isEmpty) {
            return CustomScrollView(
              slivers: [
                topBarSpaceSliver(topH),
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 40, color: cs.error),
                          const SizedBox(height: 12),
                          Text(l10n.loadFailed,
                              style: TextStyle(color: cs.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(_ctl.error!,
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          if (_ctl.items.isEmpty && !_ctl.loading && !_ctl.hasMore) {
            return CustomScrollView(
              slivers: [
                topBarSpaceSliver(topH),
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      l10n.noContent,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            );
          }
                                         
                                               
          return AppRefreshIndicator(
            refreshIndicatorKey: _refreshKey,
            onRefresh: _refreshWithToast,
            color: cs.primary,
            child: CustomScrollView(
              controller: _scroll,
              physics: const AppRefreshScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                topBarSpaceSliver(topH),
                genericGridSliver(
                  itemCount: _ctl.items.length,
                  aspectRatio: widget.gridAspect,
                  itemBuilder: (c, i) => widget.itemBuilder(c, _ctl.items[i]),
                ),
                                              
                if (_ctl.loading && !_ctl.refreshing) _loadingMoreSliver,
                bottomSpaceSliver(context),
              ],
            ),
          );
        },
      ),
      floatingActionButton: standardListFab(
        hasError: _ctl.error != null && _ctl.items.isEmpty,
        isEmpty: _ctl.items.isEmpty,
        onRetry: () => _ctl.refresh(),
        extended: false,
        atTop: _atTop,
        onTapTop: () => _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        ),
        onRefresh: _userReload,
      ),
    );
  }
}
