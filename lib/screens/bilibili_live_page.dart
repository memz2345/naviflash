// lib/screens/bilibili_live_page.dart
//
// 直播推荐页（接口与数据来源见 services/bilibili_live_service.dart）：
//   - 推荐：推荐直播间流，下拉刷新 + 触底加载
//   - 分区：一级/二级分区切换 + 排序（推荐 / 人气 / 最新开播），
//     右上角入口可进「直播分类」页全量浏览
//   - 关注：登录态下正在直播的关注主播
// 卡片点击进入直播间查看页（BilibiliLiveRoomPage），长按可用浏览器兜底。
//
// 列表 / 卡片 / 分页逻辑抽在 widgets/live_room_grid.dart，
// 与分区 / 推荐服务保持一致：自适应列数网格、封面缓存、错误重试、空态提示。
import 'package:flutter/material.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/screens/bilibili_live_categories_page.dart';
import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/widgets/live_room_grid.dart';

class BilibiliLivePage extends StatefulWidget {
  /// 宽屏侧边栏内嵌模式：不画自己的 AppBar（外层壳已有标题区）、背景透明。
  final bool embeddedInShell;

  const BilibiliLivePage({super.key, this.embeddedInShell = false});

  @override
  State<BilibiliLivePage> createState() => _BilibiliLivePageState();
}

class _BilibiliLivePageState extends State<BilibiliLivePage>
    with TickerProviderStateMixin {
  static const List<String> _tabs = ['推荐', '分区', '关注'];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tabBar = TabBar(
      controller: _tabController,
      tabs: [for (final t in _tabs) Tab(text: t)],
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
      labelColor: cs.primary,
      unselectedLabelColor: cs.onSurfaceVariant,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
    );

    final body = Column(
      children: [
        if (widget.embeddedInShell)
          Container(
            color: cs.surface,
            child: SafeArea(bottom: false, child: tabBar),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              LiveRoomGrid(
                loader: (page) => BilibiliLiveService.fetchRecommend(page: page),
                emptyText: '暂时没有推荐的直播间',
              ),
              const _LiveAreaTab(),
              const _LiveFollowTab(),
            ],          ),
        ),
      ],
    );

    if (widget.embeddedInShell) {
      return Scaffold(backgroundColor: Colors.transparent, body: body);
    }
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        title: const Text('直播'),
        backgroundColor: cs.surfaceContainer,
        bottom: tabBar,
      ),
      body: SafeArea(child: body),
    );
  }
}

// ════════════════════════════════════════
//  分区 tab
// ════════════════════════════════════════

/// 分区排序（对应 sort_type 参数）。
enum _AreaSort { recommend, online, liveTime }

class _LiveAreaTab extends StatefulWidget {
  const _LiveAreaTab();

  @override
  State<_LiveAreaTab> createState() => _LiveAreaTabState();
}

class _LiveAreaTabState extends State<_LiveAreaTab>
    with AutomaticKeepAliveClientMixin {
  static const List<(_AreaSort, String, String)> _sorts = [
    (_AreaSort.recommend, '推荐', BilibiliLiveService.sortDefault),
    (_AreaSort.online, '人气', BilibiliLiveService.sortOnline),
    (_AreaSort.liveTime, '最新开播', BilibiliLiveService.sortLiveTime),
  ];

  List<LiveAreaGroup> _groups = [];
  String? _areasError;
  bool _areasLoading = true;

  int _parentId = 0;
  int _areaId = 0;
  _AreaSort _sort = _AreaSort.recommend;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    setState(() {
      _areasLoading = true;
      _areasError = null;
    });
    final result = await BilibiliLiveService.fetchAreaList();
    if (!mounted) return;
    switch (result) {
      case LiveOk<LiveAreaGroup>(:final items):
        setState(() {
          _groups = items;
          _areasLoading = false;
          // 默认选中第一个一级分区下的「全部」
          if (_parentId == 0 && items.isNotEmpty) {
            _parentId = items.first.id;
            _areaId = 0;
          }
        });
      case LiveError<LiveAreaGroup>(:final detail):
        setState(() {
          _areasLoading = false;
          _areasError = detail;
        });
    }
  }

  void _selectParent(LiveAreaGroup group) {
    if (_parentId == group.id) return;
    setState(() {
      _parentId = group.id;
      _areaId = 0;
    });
  }

  void _selectArea(LiveAreaItem area) {
    if (_areaId == area.id) return;
    setState(() => _areaId = area.id);
  }

  void _selectSort(_AreaSort sort) {
    if (_sort == sort) return;
    setState(() => _sort = sort);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    if (_areasLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_areasError != null) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _areasError!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          // 加载失败重试：右下角 Extended FAB（重新加载）
          PositionedRetryFab(onRetry: _loadAreas),
        ],
      );
    }

    LiveAreaGroup? currentGroup;
    for (final g in _groups) {
      if (g.id == _parentId) {
        currentGroup = g;
        break;
      }
    }
    final children = currentGroup?.children;

    return Column(
      children: [
        // 一级分区
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) =>
                _chip(cs, _groups[i].name, _parentId == _groups[i].id,
                    () => _selectParent(_groups[i])),
          ),
        ),
        // 二级分区
        if (children != null && children.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: children.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _chip(
                cs,
                children[i].name,
                _areaId == children[i].id,
                () => _selectArea(children[i]),
                filled: false,
              ),
            ),
          ),
        // 排序（末尾入口进「直播分类」页，宫格浏览全部分区）
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 8, 6),
          child: Row(
            children: [
              for (final (sort, label, _) in _sorts) ...[
                _chip(cs, label, _sort == sort, () => _selectSort(sort),
                    filled: false),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              SizedBox(
                height: 32,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BilibiliLiveCategoriesPage(
                        initialParentId: _parentId,
                      ),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: Icon(Icons.grid_view, size: 16, color: cs.primary),
                  label: Text(
                    '全部分类',
                    style: TextStyle(fontSize: 12, color: cs.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LiveRoomGrid(
            // 分区 / 子分区 / 排序任一变化都重新加载
            resetKey: '$_parentId-$_areaId-${_sort.name}',
            loader: (page) => BilibiliLiveService.fetchAreaRooms(
              parentAreaId: _parentId,
              areaId: _areaId,
              sortType: _sorts
                  .firstWhere((s) => s.$1 == _sort,
                      orElse: () => _sorts.first)
                  .$3,
              page: page,
            ),
            emptyText: '这个分区现在没人开播',
          ),
        ),
      ],
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
        color: selected
            ? (filled ? cs.primary : cs.onPrimary)
            : cs.onSurfaceVariant,
      ),
    );
  }
}

// ════════════════════════════════════════
//  关注 tab
// ════════════════════════════════════════

class _LiveFollowTab extends StatelessWidget {
  const _LiveFollowTab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 登录态变化（登录 / 退出）时自动重建列表
    return ListenableBuilder(
      listenable: BilibiliAccountService.instance,
      builder: (context, _) {
        final account = BilibiliAccountService.instance;
        if (!account.isLoggedIn) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.live_tv_outlined,
                    size: 48, color: cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(
                  '登录后可以看到关注的主播',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => _openLogin(context),
                  child: const Text('去登录'),
                ),
              ],
            ),
          );
        }
        return LiveRoomGrid(
          resetKey: 'follow-${account.mid}',
          loader: (page) => BilibiliLiveService.fetchFollowing(page: page),
          emptyText: '关注的主播都没在播',
          pageSize: 9,
        );
      },
    );
  }

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BilibiliLoginScreen()),
    );
  }
}
