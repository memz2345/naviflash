                                             
  
                                      
                                   
                                                         
                                   
                                         
                             
                                
                                                   
                                                        
                                        
                                
                      
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bilibili_watch_later_service.dart';
import 'package:naviflash/widgets/app_drawer.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/back_top_fab.dart';
import 'package:naviflash/widgets/frosted_page_bar.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/morph_widgets.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/video_card.dart';
import 'package:naviflash/widgets/page_loading.dart';
import 'package:naviflash/widgets/side_bar_menu_button.dart';

                                          
                          
const double _kTopBarHeight = 56.0;

               
enum WatchLaterSort {
                        
  recentAdd,

                     
  earliestAdd,

                        
  longest,
}

                                           
               
bool watchLaterIsUnfinished(WatchLaterItem e) =>
    e.duration <= 0 || e.progress < e.duration;

                            
                                                          
                                                  
List<WatchLaterItem> filterSortWatchLater(
  List<WatchLaterItem> items, {
  bool onlyUnfinished = false,
  String keyword = '',
  WatchLaterSort sort = WatchLaterSort.recentAdd,
}) {
  Iterable<WatchLaterItem> list = items;
  if (onlyUnfinished) {
    list = list.where(watchLaterIsUnfinished);
  }
  if (keyword.isNotEmpty) {
    final kw = keyword.toLowerCase();
    list = list.where(
      (e) =>
          e.title.toLowerCase().contains(kw) ||
          e.upName.toLowerCase().contains(kw),
    );
  }
  final result = list.toList();
  if (sort == WatchLaterSort.earliestAdd) {
    result.sort((a, b) => a.addAt.compareTo(b.addAt));
  } else if (sort == WatchLaterSort.longest) {
    result.sort((a, b) => b.duration.compareTo(a.duration));
  }
  return result;
}

class BilibiliWatchLaterPage extends StatefulWidget {
                                   
                     
  final bool drawerMode;

  const BilibiliWatchLaterPage({super.key, this.drawerMode = false});

  @override
  State<BilibiliWatchLaterPage> createState() => _BilibiliWatchLaterPageState();
}

class _BilibiliWatchLaterPageState extends State<BilibiliWatchLaterPage> {
  List<WatchLaterItem> _items = [];
  bool _loading = true;
  bool _clearing = false;
  String? _error;

                        
  bool _searching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _keyword = '';

                                   
  bool _onlyUnfinished = false;

             
  WatchLaterSort _sort = WatchLaterSort.recentAdd;

                     
  bool _multiSelect = false;
  final Set<int> _selectedAids = {};

              
  bool _batchDeleting = false;

                                   
  List<WatchLaterItem> get _visibleItems => filterSortWatchLater(
        _items,
        onlyUnfinished: _onlyUnfinished,
        keyword: _keyword,
        sort: _sort,
      );

                     
  late final ScrollController _scroll = ScrollController();

                                       
                                   
  final _fabVisibility = BackTopFabVisibility();

                                    
  final GlobalKey<BackTopFabState> _fabKey = GlobalKey();

                                     
                                     
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();

                              
  bool _atTop = true;

  @override
  void initState() {
    super.initState();
    debugPrint('[AutoTest] WatchLater initState');
    _searchCtrl.addListener(() {
      setState(() => _keyword = _searchCtrl.text.trim().toLowerCase());
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return;
    final metrics = notification.metrics;
    final delta = notification.scrollDelta ?? 0;
                                        
    if (_fabVisibility.update(delta) && mounted) {
      setState(() {});
    }
                                   
    final atTop = metrics.pixels <= 0.5;
    if (atTop != _atTop && mounted) {
      setState(() => _atTop = atTop);
    }
  }

  void _scrollToTop() {
    if (!_scroll.hasClients || _scroll.offset <= 0) return;
                                           
    final ms = (300 + _scroll.offset / 20).clamp(300.0, 1200.0).round();
    final duration = Duration(milliseconds: ms);
    _fabKey.currentState?.startFlight(duration);
    _scroll.animateTo(0, duration: duration, curve: Curves.easeOut);
  }

  Future<void> _load() async {
    debugPrint('[AutoTest] WatchLater fetchList start');
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    final (:items, :err) = await BilibiliWatchLaterService.fetchList();
    debugPrint('[AutoTest] WatchLater fetchList done items=${items.length} err=$err');
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
      _error = err;
    });
  }

  Future<void> _remove(WatchLaterItem item) async {
    final r = await BilibiliWatchLaterService.remove(
      aid: item.aid,
      bvid: item.bvid,
    );
    if (!mounted) return;
    if (r.ok) {
      setState(() => _items.removeWhere((e) => e.aid == item.aid));
      showAppToast(context, '已移除');
    } else {
      showAppToast(context, r.message, error: true);
    }
  }

  Future<void> _clearAll() async {
    if (_items.isEmpty || _clearing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空稍后再看', style: TextStyle(fontSize: 16)),
        content: Text(
          '将移除全部 ${_items.length} 个视频，确定继续吗？',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _clearing = true);
    final r = await BilibiliWatchLaterService.clearAll();
    if (!mounted) return;
    setState(() => _clearing = false);
    if (r.ok) {
      setState(_items.clear);
      showAppToast(context, '已清空');
    } else {
      showAppToast(context, r.message, error: true);
    }
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BilibiliLoginScreen()),
    );
  }

                                             
            
                                             

  void _toggleMultiSelect() {
    HapticFeedback.lightImpact();
    setState(() {
      _multiSelect = !_multiSelect;
      if (!_multiSelect) _selectedAids.clear();
    });
  }

  bool _isAllSelected(List<WatchLaterItem> visible) =>
      visible.isNotEmpty && _selectedAids.length >= visible.length;

  void _toggleSelectAll(List<WatchLaterItem> visible) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isAllSelected(visible)) {
        _selectedAids.clear();
      } else {
        _selectedAids
          ..clear()
          ..addAll(visible.map((e) => e.aid));
      }
    });
  }

                                     
  Future<void> _deleteSelected() async {
    if (_selectedAids.isEmpty || _batchDeleting) return;
    final targets =
        _items.where((e) => _selectedAids.contains(e.aid)).toList();
    if (targets.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移除选中视频', style: TextStyle(fontSize: 16)),
        content: Text(
          '将把选中的 ${targets.length} 个视频移出稍后再看，确定继续吗？',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _batchDeleting = true);
                                  
    final r = await BilibiliWatchLaterService.removeMany(targets);
    if (!mounted) return;
    final failed = r.ok ? 0 : targets.length;
    if (r.ok) {
      final removed = targets.map((e) => e.aid).toSet();
      _items.removeWhere((e) => removed.contains(e.aid));
      _selectedAids.clear();
    }
    setState(() {
      _batchDeleting = false;
      if (failed == 0) {
        _multiSelect = false;
      }
    });
    showAppToast(
      context,
      failed == 0
          ? '已移除 ${targets.length} 个视频'
          : '$failed 个视频移除失败',
      error: failed > 0,
    );
  }

  String _fmtDuration(int sec) {
    if (sec <= 0) return '';
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    if (h > 0) return '$h:${two(m)}:${two(s)}';
    return '$m:${two(s)}';
  }

  String _fmtAddAt(int ts) {
    if (ts <= 0) return '';
    final t = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return '刚刚添加';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前添加';
    if (diff.inDays < 1) return '${diff.inHours} 小时前添加';
    if (t.year == now.year) return '${t.month}/${t.day} 添加';
    return '${t.year}/${t.month}/${t.day} 添加';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
                                       
    final scaffold = Scaffold(
      backgroundColor: cs.surfaceContainer,
                                  
      drawer: widget.drawerMode
          ? const AppDrawer(currentPage: 'watchlater')
          : null,
                                    
      onDrawerChanged: SideBarDrawerState.setOpen,
      floatingActionButton: _buildFab(),
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

                                        
                                    
  Widget? _buildFab() {
    if (_multiSelect) return null;
    if (_error != null && _items.isEmpty && !_loading) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 8,
        ),
        child: LoadRetryPill(onRetry: _load),
      );
    }
    if (_items.isEmpty || _loading) return null;
    return BackTopFab(
      key: _fabKey,
      extended: _fabVisibility.extended,
      atTop: _atTop,
      onTap: _scrollToTop,
      onRefresh: _userReload,
    );
  }

                                     
                               
  void _userReload() {
    final state = _refreshKey.currentState;
    if (state == null) {
      _load();
      return;
    }
    state.show();
  }

                                      
                               
  Widget _buildTopBar(ColorScheme cs) {
    final visible = _visibleItems;
    return FrostedPageBar(
      title: _multiSelect ? '已选 ${_selectedAids.length} 项' : '稍后再看',
      drawerMode: widget.drawerMode && !_multiSelect,
      leading: _multiSelect
          ? MorphIconButton(
              icon: Icons.close,
              tooltip: '退出多选',
              onTap: _toggleMultiSelect,
              transparent: true,
            )
          : null,
      actions: _multiSelect
          ? [
              MorphIconButton(
                icon: Icons.select_all_rounded,
                tooltip: _isAllSelected(visible) ? '取消全选' : '全选',
                onTap: () => _toggleSelectAll(visible),
                transparent: true,
              ),
              MorphIconButton(
                icon: _batchDeleting
                    ? Icons.hourglass_top_rounded
                    : Icons.delete_outline,
                tooltip: '移除选中',
                onTap: _selectedAids.isEmpty || _batchDeleting
                    ? null
                    : _deleteSelected,
                transparent: true,
              ),
            ]
          : [
              MorphIconButton(
                icon: _searching ? Icons.close : Icons.search,
                tooltip: '搜索稍后再看',
                onTap: () {
                  setState(() {
                    _searching = !_searching;
                    if (!_searching) _searchCtrl.clear();
                  });
                },
                transparent: true,
              ),
              if (_items.isNotEmpty)
                LiquidGlassMenuButton(
                  icon: Icons.more_vert,
                  tooltip: '更多',
                  transparent: true,
                  actions: [
                    GlassMenuAction(
                      icon: Icons.checklist_rounded,
                      text: '多选',
                      onTap: _toggleMultiSelect,
                    ),
                    GlassMenuAction(
                      icon: Icons.delete_sweep_outlined,
                      text: _clearing ? '清空中…' : '清空稍后再看',
                      isEnabled: !_clearing && !_batchDeleting,
                      isDestructive: true,
                      onTap: _clearAll,
                    ),
                  ],
                ),
            ],
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (!BilibiliWatchLaterService.canUse && _items.isEmpty && !_loading) {
      return _centeredState(
        cs,
        icon: Icons.watch_later_outlined,
        text: '登录后可以查看稍后再看',
        action: FilledButton.tonal(
          onPressed: _openLogin,
          child: const Text('去登录'),
        ),
      );
    }
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _items.isEmpty,
    )) {
      return _centeredState(cs, child: const PageLoadingIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return _centeredState(
        cs,
        text: _error!,
      );
    }
    if (_items.isEmpty) {
      return _centeredState(
        cs,
        icon: Icons.watch_later_outlined,
        text: '还没有稍后再看的视频',
        subText: '在视频页菜单里可以「添加到稍后再看」',
      );
    }
    final visible = _visibleItems;
    if (visible.isEmpty) {
      return _centeredState(
        cs,
        icon: _onlyUnfinished
            ? Icons.done_all_rounded
            : Icons.search_off_rounded,
        text: _onlyUnfinished ? '没有未看完的视频' : '没有找到匹配的视频',
        subText: _onlyUnfinished ? null : '换个搜索词试试',
      );
    }
                                          
                                       
    return AppRefreshIndicator(
      refreshIndicatorKey: _refreshKey,
      onRefresh: _load,
      color: cs.primary,
      edgeOffset: 0,
                                 
                         
      displacement: _kTopBarHeight + 10,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          _onScroll(n);
          return false;
        },
        child: CustomScrollView(
          controller: _scroll,
          physics: const AppRefreshScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
                   
            SliverToBoxAdapter(
              child: SizedBox(height: _kTopBarHeight),
            ),
                              
            if (_searching)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '搜索标题 / UP 主',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            _searching = false;
                            _searchCtrl.clear();
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                    ),
                  ),
                ),
              ),
                                                    
            if (_items.isNotEmpty)
              SliverToBoxAdapter(child: _buildFilterSortBar(cs)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _buildCard(cs, visible[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

                                              
                                            
  Widget _buildFilterSortBar(ColorScheme cs) {
    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
            ),
            selectedColor: cs.secondaryContainer,
            backgroundColor: cs.surfaceContainerHigh,
            side: BorderSide.none,
            onSelected: (_) => onTap(),
          ),
        );
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        children: [
          chip('全部', !_onlyUnfinished,
              () => setState(() => _onlyUnfinished = false)),
          chip('未看完', _onlyUnfinished,
              () => setState(() => _onlyUnfinished = true)),
          const SizedBox(width: 4),
          for (final s in WatchLaterSort.values)
            chip(_sortLabel(s), _sort == s, () => setState(() => _sort = s)),
        ],
      ),
    );
  }

  String _sortLabel(WatchLaterSort s) => switch (s) {
        WatchLaterSort.recentAdd => '最近添加',
        WatchLaterSort.earliestAdd => '最早添加',
        WatchLaterSort.longest => '时长最长',
      };

                            
  Widget _centeredState(
    ColorScheme cs, {
    IconData? icon,
    String? text,
    String? subText,
    Widget? action,
    Widget? child,
  }) {
    return Column(
      children: [
        SizedBox(height: _kTopBarHeight),
        Expanded(
          child: Center(
            child: child ??
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null)
                      Icon(icon, size: 48, color: cs.onSurfaceVariant),
                    if (icon != null) const SizedBox(height: 12),
                    if (text != null)
                      Text(
                        text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    if (subText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (action != null) ...[
                      const SizedBox(height: 12),
                      action,
                    ],
                  ],
                ),
          ),
        ),
      ],
    );
  }

                                           
                                            
                                      
                   
  Widget _buildCard(ColorScheme cs, WatchLaterItem item) {
    final showProgress =
        item.progress > 0 && item.duration > 0 && item.progress < item.duration;
    final meta = <String>[
      if (item.duration > 0) _fmtDuration(item.duration),
      if (showProgress) '看到 ${_fmtDuration(item.progress)}',
      if (item.addAt > 0) _fmtAddAt(item.addAt),
    ].join(' · ');
    final selected = _selectedAids.contains(item.aid);

    void toggle() {
      setState(() {
        if (selected) {
          _selectedAids.remove(item.aid);
        } else {
          _selectedAids.add(item.aid);
        }
      });
    }

    final card = VideoCardH(
      data: VideoCardData(
        cover: item.cover,
        title: item.title.isEmpty ? '（无标题）' : item.title,
        duration: item.duration,
        progress: showProgress ? item.progress / item.duration : null,
        ownerName: item.upName,
        subtitle: meta,
      ),
      onTap: _multiSelect
          ? toggle
          : item.bvid.isEmpty
              ? null
              : () => openBilibiliVideo(
                  context,
                  bvid: item.bvid,
                  initialTitle: item.title,
                  initialCover: item.cover,
                ),
      onLongPress: () {
        if (_multiSelect) {
          toggle();
          return;
        }
        HapticFeedback.mediumImpact();
        setState(() {
          _multiSelect = true;
          _selectedAids.add(item.aid);
        });
      },
      trailing: _multiSelect
          ? null
          : SizedBox(
              width: 32,
              height: 84,
              child: IconButton(
                icon: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
                tooltip: '移除',
                onPressed: () => _remove(item),
              ),
            ),
    );
    if (!_multiSelect) return card;
    return Stack(
      children: [
        card,
        Positioned(
          left: 8,
          top: 8,
          child: GestureDetector(
            onTap: toggle,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: selected ? cs.primary : Colors.white70,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
