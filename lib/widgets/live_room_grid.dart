                                  
  
                                            
                                           
                                                     
                       
                                             
import 'package:flutter/material.dart';
import 'package:naviflash/src/content_reveal_gate.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/screens/bilibili_live_room_page.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/widgets/lazy_cover_image.dart';
import 'package:naviflash/widgets/video_card.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';

                                           
                                
                                           

class LiveRoomGrid extends StatefulWidget {
                          
  final Future<LiveResult<LiveRoomItem>> Function(int page) loader;

                                         
  final Object? resetKey;

                                        
                            
  final int refreshTick;

  final String emptyText;

                                         
  final int pageSize;

                                   
                      
  final ScrollController? scrollController;

                           
  final EdgeInsets? padding;

                                    
  final int maxColumns;

  const LiveRoomGrid({
    super.key,
    required this.loader,
    this.resetKey,
    this.refreshTick = 0,
    this.emptyText = '暂无内容',
    this.pageSize = 30,
    this.scrollController,
    this.padding,
    this.maxColumns = 4,
  });

  @override
  State<LiveRoomGrid> createState() => _LiveRoomGridState();
}

class _LiveRoomGridState extends State<LiveRoomGrid>
    with AutomaticKeepAliveClientMixin {
  ScrollController? _ownedScroll;

  ScrollController get _scroll =>
      widget.scrollController ?? (_ownedScroll ??= ScrollController());

  List<LiveRoomItem> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

                                       
                                 
  ContentRevealGate? _revealGate;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(forceRefresh: true);
  }

  @override
  void didUpdateWidget(covariant LiveRoomGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetKey != widget.resetKey) {
                                
      setState(() => _items = []);
      _load(forceRefresh: true);
      return;
    }
    if (oldWidget.refreshTick != widget.refreshTick) {
                                     
      _load(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    _revealGate?.dispose();
    _revealGate = null;
                           
    _ownedScroll?.dispose();
    _ownedScroll = null;
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

                                      
  bool get _isContentGated => _revealGate?.isGated ?? false;

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) _loadMore();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!forceRefresh && (_loading || _loadingMore)) return;
    if (!mounted) return;
    setState(() {
                                  
      _loading = _items.isEmpty;
      _loadingMore = false;
      _error = null;
    });
                                           
                       
    if (_items.isEmpty) {
      _armRevealGate();
    }
    final targetPage = forceRefresh ? 1 : _page + 1;
    final result = await widget.loader(targetPage);
    if (!mounted) return;
    switch (result) {
      case LiveOk<LiveRoomItem>(:final items, :final hasMore):
                                        
        final seen = <int>{for (final it in _items) it.roomId};
        final fresh = items.where((it) => seen.add(it.roomId)).toList();
        setState(() {
          if (forceRefresh) {
            _items = fresh;
            _page = 1;
          } else {
            _items = [..._items, ...fresh];
            _page = targetPage;
          }
          _hasMore = hasMore;
          _loading = false;
          _loadingMore = false;
          _error = null;
        });
      case LiveError<LiveRoomItem>(:final detail):
        setState(() {
          _loading = false;
          _loadingMore = false;
                                   
          if (forceRefresh || _items.isEmpty) _error = detail;
          if (!forceRefresh) _hasMore = false;
        });
    }
  }

  void _loadMore() {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

                                             
    if (_loading || _isContentGated) {
      return const Center(child: LoadingIndicatorM3E());
    }
    if (_error != null && _items.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
          ),
                                          
          PositionedRetryFab(onRetry: () => _load(forceRefresh: true)),
        ],
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          widget.emptyText,
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      );
    }

    return AppRefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      color: cs.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = (width / 200).floor().clamp(2, widget.maxColumns);
          return GridView.builder(
            controller: _scroll,
            physics: const AppRefreshScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: widget.padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
                                                         
                                                    
                            
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: _items.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= _items.length) {
                return _loadingMore
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              }
              return LiveRoomCard(item: _items[i]);
            },
          );
        },
      ),
    );
  }
}

                                           
                                               
                                                 
                    
                               
                                
                               
                      
                            
                                           

class LiveRoomCard extends StatelessWidget {
  final LiveRoomItem item;

  const LiveRoomCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;

    return VideoCardV(
      data: VideoCardData(
        cover: item.cover,
        title: item.title.isEmpty ? '未命名直播间' : item.title,
                                              
                                                  
        coverWidget: LazyCoverImage(
          item.cover,
          headers: headers,
          fit: BoxFit.cover,
          maxDimension: 480,
        ),
        viewText: _onlineText,
        durationText: _areaText,
        ownerName: item.uname.isEmpty ? '未知主播' : item.uname,
        subtitleTrailing: const _LiveNowBadge(),
      ),
      onTap: () => _openRoom(context),
      onLongPress: () => _openInBrowser(context),
    );
  }

  void _openRoom(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BilibiliLiveRoomPage(
          roomId: item.roomId,
          title: item.title,
          uname: item.uname,
          face: item.face,
          cover: item.cover,
        ),
      ),
    );
  }

                             
  void _openInBrowser(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrowserPage(
          initialUrl: item.url,
          title: item.title.isEmpty ? '直播间' : item.title,
        ),
      ),
    );
  }

  String get _onlineText {
    if (item.onlineText.isNotEmpty) return item.onlineText;
    if (item.online >= 100000000) {
      return '${(item.online / 100000000).toStringAsFixed(1)} 亿';
    }
    if (item.online >= 10000) {
      return '${(item.online / 10000).toStringAsFixed(1)} 万';
    }
    return '${item.online}';
  }

                      
  String get _areaText {
    if (item.areaName.isNotEmpty) return item.areaName;
    return item.parentAreaName;
  }
}

                                 
class _LiveNowBadge extends StatelessWidget {
  const _LiveNowBadge();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
          ),
          child: SizedBox(width: 6, height: 6),
        ),
        SizedBox(width: 4),
        Text('直播中', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
      ],
    );
  }
}
