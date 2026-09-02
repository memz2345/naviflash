// lib/screens/bilibili_live_categories_page.dart
//
// 直播分类页（参考 PiliPlus live_area / live_area_detail）：
//   - BilibiliLiveCategoriesPage：一级分区 TabBar + 二级分区图标宫格
//   - BilibiliLiveCategoryRoomsPage：某分类下的直播间列表（排序切换 + 翻页）
// 数据来源见 services/bilibili_live_service.dart（分区树 / second/getList）。
import 'package:flutter/material.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/live_room_grid.dart';

class BilibiliLiveCategoriesPage extends StatefulWidget {
  /// 进入时定位到的父分区（0 表示第一个）。
  final int initialParentId;

  const BilibiliLiveCategoriesPage({super.key, this.initialParentId = 0});

  @override
  State<BilibiliLiveCategoriesPage> createState() =>
      _BilibiliLiveCategoriesPageState();
}

class _BilibiliLiveCategoriesPageState
    extends State<BilibiliLiveCategoriesPage>
    with TickerProviderStateMixin {
  List<LiveAreaGroup> _groups = [];
  String? _error;
  bool _loading = true;

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await BilibiliLiveService.fetchAreaList();
    if (!mounted) return;
    switch (result) {
      case LiveOk<LiveAreaGroup>(:final items):
        // 服务端返回顺序不固定，ID 升序后「一起看」等聚合分区排后面，
        // 常用的娱乐 / 手游等大分区靠前
        items.sort((a, b) => a.id.compareTo(b.id));
        var initialIndex = 0;
        if (widget.initialParentId > 0) {
          final i = items.indexWhere((g) => g.id == widget.initialParentId);
          if (i >= 0) initialIndex = i;
        }
        _tabController?.dispose();
        _tabController = TabController(
          length: items.length,
          vsync: this,
          initialIndex: initialIndex,
        );
        setState(() {
          _groups = items;
          _loading = false;
        });
      case LiveError<LiveAreaGroup>(:final detail):
        setState(() {
          _loading = false;
          _error = detail;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(onPressed: _load, child: const Text('重试')),
              ],
            ),
          )
        : Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  for (final g in _groups) Tab(text: g.name),
                ],
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 14),
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.label,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    for (final g in _groups) _AreaGridView(group: g),
                  ],
                ),
              ),
            ],
          );

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        title: const Text('直播分类'),
        backgroundColor: cs.surfaceContainer,
      ),
      body: SafeArea(child: body),
    );
  }
}

// ════════════════════════════════════════
//  一个一级分区下的二级分区宫格
// ════════════════════════════════════════

class _AreaGridView extends StatelessWidget {
  final LiveAreaGroup group;

  const _AreaGridView({required this.group});

  @override
  Widget build(BuildContext context) {
    if (group.children.isEmpty) {
      return Center(
        child: Text(
          '该分区下暂时没有子分类',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return GridView.builder(
      physics: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 96,
        mainAxisSpacing: 18,
        crossAxisSpacing: 8,
        mainAxisExtent: 78,
      ),
      itemCount: group.children.length,
      itemBuilder: (context, i) =>
          _AreaIconItem(area: group.children[i], parentName: group.name),
    );
  }
}

class _AreaIconItem extends StatelessWidget {
  final LiveAreaItem area;
  final String parentName;

  const _AreaIconItem({required this.area, required this.parentName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;

    final icon = area.isAll || area.pic.isEmpty
        ? Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.apps,
              size: 22,
              color: cs.primary,
            ),
          )
        : ClipOval(
            child: Image(
              image: CachedImageProvider(area.pic, headers: headers),
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 46,
                height: 46,
                color: cs.primaryContainer.withValues(alpha: 0.45),
                child: Icon(Icons.apps, size: 22, color: cs.primary),
              ),
            ),
          );

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BilibiliLiveCategoryRoomsPage(
            parentAreaId: area.parentId > 0 ? area.parentId : area.id,
            areaId: area.id,
            parentName: parentName,
            areaName: area.name,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 5),
          Text(
            area.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════
//  分类下的直播间列表
// ════════════════════════════════════════

/// 排序方式（对应 second/getList 的 sort_type）。
enum _CategorySort { recommend, online, liveTime }

class BilibiliLiveCategoryRoomsPage extends StatefulWidget {
  final int parentAreaId;
  final int areaId;
  final String parentName;
  final String areaName;

  const BilibiliLiveCategoryRoomsPage({
    super.key,
    required this.parentAreaId,
    required this.areaId,
    required this.parentName,
    required this.areaName,
  });

  @override
  State<BilibiliLiveCategoryRoomsPage> createState() =>
      _BilibiliLiveCategoryRoomsPageState();
}

class _BilibiliLiveCategoryRoomsPageState
    extends State<BilibiliLiveCategoryRoomsPage> {
  static const List<(_CategorySort, String, String)> _sorts = [
    (_CategorySort.recommend, '推荐', BilibiliLiveService.sortDefault),
    (_CategorySort.online, '人气', BilibiliLiveService.sortOnline),
    (_CategorySort.liveTime, '最新开播', BilibiliLiveService.sortLiveTime),
  ];

  _CategorySort _sort = _CategorySort.recommend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = widget.areaId == 0 || widget.areaName == '全部'
        ? widget.parentName
        : widget.areaName;

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        backgroundColor: cs.surfaceContainer,
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _sorts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => _chip(_sorts[i]),
              ),
            ),
            Expanded(
              child: LiveRoomGrid(
                resetKey: '${widget.parentAreaId}-${widget.areaId}-${_sort.name}',
                loader: (page) => BilibiliLiveService.fetchAreaRooms(
                  parentAreaId: widget.parentAreaId,
                  areaId: widget.areaId,
                  sortType: _sorts
                      .firstWhere((s) => s.$1 == _sort, orElse: () => _sorts.first)
                      .$3,
                  page: page,
                ),
                emptyText: '这个分类现在没人开播',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip((_CategorySort, String, String) sort) {
    final cs = Theme.of(context).colorScheme;
    final selected = _sort == sort.$1;
    return ChoiceChip(
      label: Text(sort.$2),
      selected: selected,
      onSelected: (_) => setState(() => _sort = sort.$1),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      selectedColor: cs.primaryContainer.withValues(alpha: 0.5),
      backgroundColor: cs.surfaceBright,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        color: selected ? cs.primary : cs.onSurfaceVariant,
      ),
    );
  }
}
