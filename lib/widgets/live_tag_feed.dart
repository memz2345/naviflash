                                 
  
                               
                                          
                                
                                       
                                            
                                               
                                                     
                                                 
  
                                                
                             
import 'package:flutter/material.dart';

import 'package:naviflash/screens/bilibili_live_categories_page.dart';
import 'package:naviflash/screens/bilibili_live_following_page.dart';
import 'package:naviflash/screens/bilibili_live_room_page.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/live_room_grid.dart';

                                        
enum LiveFeedSort { recommend, online, liveTime }

class LiveTagFeed extends StatefulWidget {
                        
  final bool showFollowStrip;

                                 
  final int gridMaxColumns;

                                       
                         
  final double headerInset;

  const LiveTagFeed({
    super.key,
    this.showFollowStrip = true,
    this.gridMaxColumns = 6,
    this.headerInset = 0,
  });

  @override
  LiveTagFeedState createState() => LiveTagFeedState();
}

class LiveTagFeedState extends State<LiveTagFeed>
    with AutomaticKeepAliveClientMixin {
                                           
                               
  static const List<(LiveFeedSort, String, String)> _sorts = [
    (LiveFeedSort.recommend, '推荐', BilibiliLiveService.sortDefault),
    (LiveFeedSort.online, '人气', BilibiliLiveService.sortOnline),
    (LiveFeedSort.liveTime, '最新开播', BilibiliLiveService.sortLiveTime),
  ];

  final ScrollController _scroll = ScrollController();

             
  List<LiveAreaGroup> _groups = const [];
  bool _areasLoading = true;
  String? _areasError;

                                          
  int _parent = -1;

                             
  int _child = 0;
  LiveFeedSort _sort = LiveFeedSort.recommend;

                                            
  int _reloadTick = 0;

               
  bool _followLoading = false;
  bool _followTried = false;
  List<LiveRoomItem> _follows = const [];
  int? _followTotal;
  int? _followMid;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAreas();
    BilibiliAccountService.instance.addListener(_onAccountChanged);
    _onAccountChanged();
  }

  @override
  void dispose() {
    BilibiliAccountService.instance.removeListener(_onAccountChanged);
    _scroll.dispose();
    super.dispose();
  }

  void _onAccountChanged() {
    final acc = BilibiliAccountService.instance;
    if (acc.isLoggedIn) {
      if (_followMid != acc.mid || !_followTried) {
        _loadFollows();
      }
    } else {
      _followMid = null;
      if (_follows.isNotEmpty || _followTried) {
        setState(() {
          _follows = const [];
          _followTotal = null;
          _followTried = false;
        });
      }
    }
  }

  Future<void> _loadFollows() async {
    final acc = BilibiliAccountService.instance;
    if (!acc.isLoggedIn || _followLoading) return;
    _followLoading = true;
    _followTried = true;
    _followMid = acc.mid;
    final result = await BilibiliLiveService.fetchFollowing(
      page: 1,
      pageSize: 9,
    );
    if (!mounted || acc.mid != BilibiliAccountService.instance.mid) return;
    _followLoading = false;
    switch (result) {
      case LiveOk<LiveRoomItem>(:final items, :final total):
        setState(() {
          _follows = items;
          _followTotal = total;
        });
      case LiveError<LiveRoomItem>():
                                   
        setState(() {
          _follows = const [];
          _followTotal = null;
        });
    }
  }

  Future<void> _loadAreas() async {
    if (!_areasLoading) {
      setState(() {
        _areasLoading = true;
        _areasError = null;
      });
    }
    final result = await BilibiliLiveService.fetchAreaList();
    if (!mounted) return;
    switch (result) {
      case LiveOk<LiveAreaGroup>(:final items):
        setState(() {
          _groups = items;
          _areasLoading = false;
          _areasError = null;
        });
      case LiveError<LiveAreaGroup>(:final detail):
        setState(() {
          _areasLoading = false;
          _areasError = detail;
        });
    }
  }

                                   
  Future<void> refresh() async {
    setState(() => _reloadTick++);
    if (_areasError != null || _groups.isEmpty) {
      await _loadAreas();
    }
    _loadFollows();
  }

                           
  void scrollToTop() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

             

  void _selectParent(int id) {
    if (id == _parent) return;
    setState(() {
      _parent = id;
      _child = 0;
      _sort = LiveFeedSort.recommend;
    });
  }

  void _selectChild(int id) {
    if (id == _child) return;
    setState(() => _child = id);
  }

  void _selectSort(LiveFeedSort sort) {
    if (sort == _sort) return;
    setState(() => _sort = sort);
  }

  void _openCategories() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BilibiliLiveCategoriesPage(
          initialParentId: _parent > 0 ? _parent : 0,
        ),
      ),
    );
  }

             

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    final bool areaMode = _parent >= 0;
                                                   
                               
    final String resetKey = areaMode
        ? 'a$_parent-$_child-${_sort.name}'
        : 'rcmd';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: widget.headerInset),
        if (widget.showFollowStrip) _buildFollowStrip(cs),
        _buildAreaRow(cs),
        if (areaMode) _buildChildRow(cs),
        if (areaMode) _buildSortRow(cs),
        Expanded(
          child: LiveRoomGrid(
            resetKey: resetKey,
            refreshTick: _reloadTick,
            scrollController: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            maxColumns: widget.gridMaxColumns,
            emptyText: areaMode ? '这个分区现在没人开播' : '暂时没有推荐的直播间',
            loader: (page) => areaMode
                ? BilibiliLiveService.fetchAreaRooms(
                    parentAreaId: _parent,
                    areaId: _child,
                    sortType: _sorts
                        .firstWhere(
                          (s) => s.$1 == _sort,
                          orElse: () => _sorts.first,
                        )
                        .$3,
                    page: page,
                  )
                : BilibiliLiveService.fetchRecommend(page: page),
          ),
        ),
      ],
    );
  }

                                      

  Widget _buildFollowStrip(ColorScheme cs) {
    return ListenableBuilder(
      listenable: BilibiliAccountService.instance,
      builder: (context, _) {
        final acc = BilibiliAccountService.instance;
                                
        if (!acc.isLoggedIn || _follows.isEmpty) {
          return const SizedBox.shrink();
        }
        final total = _followTotal ?? _follows.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 2),
              child: Row(
                children: [
                  Text(
                    '我的关注',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$total 人正在直播',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BilibiliLiveFollowingPage(),
                      ),
                    ),
                    child: Text(
                      '查看全部',
                      style: TextStyle(fontSize: 12.5, color: cs.primary),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 66,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _follows.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final item = _follows[i];
                  final headers =
                      NetworkSettingsService.instance.apiHeaders.isEmpty
                      ? null
                      : NetworkSettingsService.instance.apiHeaders;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BilibiliLiveRoomPage(
                          roomId: item.roomId,
                          title: item.title,
                          uname: item.uname,
                          face: item.face,
                          cover: item.cover,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: 56,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 1.5,
                                color: cs.primary,
                                strokeAlign: BorderSide.strokeAlignInside,
                              ),
                            ),
                            child: ClipOval(
                              child: item.face.isEmpty
                                  ? Container(
                                      width: 40,
                                      height: 40,
                                      color: cs.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.person,
                                        size: 22,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    )
                                  : Image(
                                      image: CachedImageProvider(
                                        item.face,
                                        headers: headers,
                                      ),
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 40,
                                        height: 40,
                                        color: cs.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.person,
                                          size: 22,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              item.uname.isEmpty ? '主播' : item.uname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

                                                    

  Widget _buildAreaRow(ColorScheme cs) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _groups.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _chip(cs, '推荐', _parent < 0, () => _selectParent(-1));
                }
                final g = _groups[i - 1];
                return _chip(
                  cs,
                  g.name,
                  _parent == g.id,
                  () => _selectParent(g.id),
                );
              },
            ),
          ),
                                  
          if (_areasError != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: '分区加载失败，点此重试',
                icon: Icon(Icons.refresh_rounded, size: 20, color: cs.primary),
                onPressed: _loadAreas,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: '全部分类',
              icon: Icon(Icons.grid_view_rounded, size: 20, color: cs.primary),
              onPressed: _openCategories,
            ),
          ),
        ],
      ),
    );
  }

                    

  Widget _buildChildRow(ColorScheme cs) {
    LiveAreaGroup? group;
    for (final g in _groups) {
      if (g.id == _parent) {
        group = g;
        break;
      }
    }
    final children = group?.children ?? const <LiveAreaItem>[];
    if (children.isEmpty) {
      return SizedBox(
        height: 34,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '该分区暂无子分类',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = children[i];
          return _chip(
            cs,
            c.name,
            _child == c.id,
            () => _selectChild(c.id),
            filled: false,
          );
        },
      ),
    );
  }

              

  Widget _buildSortRow(ColorScheme cs) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _sorts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (sort, label, _) = _sorts[i];
          return _chip(
            cs,
            label,
            _sort == sort,
            () => _selectSort(sort),
            filled: false,
          );
        },
      ),
    );
  }

  Widget _chip(
    ColorScheme cs,
    String label,
    bool selected,
    VoidCallback onTap, {
    bool filled = true,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      selectedColor: filled
          ? cs.primaryContainer.withValues(alpha: 0.5)
          : cs.primary,
      backgroundColor: cs.surfaceBright,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        color: selected
            ? (filled ? cs.primary : cs.onPrimary)
            : cs.onSurfaceVariant,
      ),
    );
  }
}
