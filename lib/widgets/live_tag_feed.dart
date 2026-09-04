// lib/widgets/live_tag_feed.dart
//
// PiliPlus 式「直播标签浏览」首页（单页直播流）：
//   - 顶部「我的关注 · X 人正在直播」横条（登录且有直播中的关注才出现，
//     点头像进直播间，右侧「查看全部」进关注直播列表页）
//   - 「推荐 / 一级分区」标签行：默认推荐流，点分区直接在本页切换成
//     该分区房间流（与 PiliPlus 的 areaEntrance 行同构）
//   - 选中分区后出现「二级分区（标签）」行 + 排序行（推荐 / 人气 / 最新开播）
//   - 行尾「全部分类」入口 → 直播分类宫格页（对应 PiliPlus LiveAreaPage）
//   - 数据与卡片复用 BilibiliLiveService + LiveRoomGrid
//
// 该组件被两处复用：侧边栏「直播」区块（BilibiliLivePage 整体改为本组件）与
// 首页推荐流的「直播」tab，两处交互与观感保持一致。
import 'package:flutter/material.dart';

import 'package:naviflash/screens/bilibili_live_categories_page.dart';
import 'package:naviflash/screens/bilibili_live_following_page.dart';
import 'package:naviflash/screens/bilibili_live_room_page.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/live_room_grid.dart';

/// 排序方式（对应 second/getList 的 sort_type）。
enum LiveFeedSort { recommend, online, liveTime }

class LiveTagFeed extends StatefulWidget {
  /// 顶部「我的关注」横条（登录后展示）。
  final bool showFollowStrip;

  /// 房间网格最大列数（宽屏推荐页可传 8 保持更密布局）。
  final int gridMaxColumns;

  /// 内容顶部留白：用于悬浮顶栏（毛玻璃 tab 栏）下方场景，避免头部
  /// 标签行被顶栏盖住；普通整页场景传 0。
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
  /// 内容延迟显示门控：大量直播卡片在路由转场 / tab 切换动画途中一次上屏
  /// 会把动画顶掉帧，故动画未结束前继续显示加载指示器。
  static const List<(LiveFeedSort, String, String)> _sorts = [
    (LiveFeedSort.recommend, '推荐', BilibiliLiveService.sortDefault),
    (LiveFeedSort.online, '人气', BilibiliLiveService.sortOnline),
    (LiveFeedSort.liveTime, '最新开播', BilibiliLiveService.sortLiveTime),
  ];

  final ScrollController _scroll = ScrollController();

  // ── 分区 ──
  List<LiveAreaGroup> _groups = const [];
  bool _areasLoading = true;
  String? _areasError;

  /// -1 = 推荐流；>=0 = 某一级分区（含它的二级分区 / 排序行）。
  int _parent = -1;

  /// 0 = 该分区全部；>0 = 二级分区 id。
  int _child = 0;
  LiveFeedSort _sort = LiveFeedSort.recommend;

  /// 数据代次：点当前 tab 刷新 / 重试时 +1 让列表强制回到第 1 页。
  int _reloadTick = 0;

  // ── 关注横条 ──
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
    final result = await BilibiliLiveService.fetchFollowing(page: 1, pageSize: 9);
    if (!mounted || acc.mid != BilibiliAccountService.instance.mid) return;
    _followLoading = false;
    switch (result) {
      case LiveOk<LiveRoomItem>(:final items, :final total):
        setState(() {
          _follows = items;
          _followTotal = total;
        });
      case LiveError<LiveRoomItem>():
        // 关注接口失败静默：不挡推荐流，下次登录态变化再试
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

  /// 外部刷新入口：切回第 1 页并重新拉（分区失败也会重试）。
  Future<void> refresh() async {
    setState(() => _reloadTick++);
    if (_areasError != null || _groups.isEmpty) {
      await _loadAreas();
    }
    _loadFollows();
  }

  /// 外部滚回顶部入口（点击当前 tab 时）。
  void scrollToTop() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  // ── 选择 ──

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
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BilibiliLiveCategoriesPage(
        initialParentId: _parent > 0 ? _parent : 0,
      ),
    ));
  }

  // ── 构建 ──

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    final bool areaMode = _parent >= 0;
    final String resetKey =
        '$_reloadTick-${areaMode ? 'a$_parent-$_child-${_sort.name}' : 'rcmd'}';

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
            scrollController: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            maxColumns: widget.gridMaxColumns,
            emptyText: areaMode ? '这个分区现在没人开播' : '暂时没有推荐的直播间',
            loader: (page) => areaMode
                ? BilibiliLiveService.fetchAreaRooms(
                    parentAreaId: _parent,
                    areaId: _child,
                    sortType: _sorts
                        .firstWhere((s) => s.$1 == _sort,
                            orElse: () => _sorts.first)
                        .$3,
                    page: page,
                  )
                : BilibiliLiveService.fetchRecommend(page: page),
          ),
        ),
      ],
    );
  }

  // ── 我的关注横条（PiliPlus live 页顶部模块） ──

  Widget _buildFollowStrip(ColorScheme cs) {
    return ListenableBuilder(
      listenable: BilibiliAccountService.instance,
      builder: (context, _) {
        final acc = BilibiliAccountService.instance;
        // 未登录 / 没有直播中的关注 → 整条隐藏
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
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
                                      child: Icon(Icons.person,
                                          size: 22,
                                          color: cs.onSurfaceVariant),
                                    )
                                  : Image(
                                      image: CachedImageProvider(
                                          item.face,
                                          headers: headers),
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 40,
                                        height: 40,
                                        color: cs.surfaceContainerHighest,
                                        child: Icon(Icons.person,
                                            size: 22,
                                            color: cs.onSurfaceVariant),
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

  // ── 一级分区标签行：推荐 + 各分区（PiliPlus areaEntrance 行） ──

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
                  return _chip(cs, '推荐', _parent < 0,
                      () => _selectParent(-1));
                }
                final g = _groups[i - 1];
                return _chip(cs, g.name, _parent == g.id,
                    () => _selectParent(g.id));
              },
            ),
          ),
          // 分区加载失败 / 中：右上补一个重试小入口
          if (_areasError != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: '分区加载失败，点此重试',
                icon: Icon(Icons.refresh_rounded,
                    size: 20, color: cs.primary),
                onPressed: _loadAreas,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: '全部分类',
              icon: Icon(Icons.grid_view_rounded,
                  size: 20, color: cs.primary),
              onPressed: _openCategories,
            ),
          ),
        ],
      ),
    );
  }

  // ── 二级分区（标签）行 ──

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
              style: TextStyle(
                  fontSize: 12, color: cs.onSurfaceVariant),
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
          return _chip(cs, c.name, _child == c.id, () => _selectChild(c.id),
              filled: false);
        },
      ),
    );
  }

  // ── 排序行 ──

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
          return _chip(cs, label, _sort == sort, () => _selectSort(sort),
              filled: false);
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
      selectedColor:
          filled ? cs.primaryContainer.withValues(alpha: 0.5) : cs.primary,
      backgroundColor: cs.surfaceBright,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        color:
            selected ? (filled ? cs.primary : cs.onPrimary) : cs.onSurfaceVariant,
      ),
    );
  }
}
