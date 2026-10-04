                                             
  
                                               
                                    
                                     
                                           
                             
                                                     
                                                     

import 'package:flutter/material.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/screens/bilibili_user_space_page_v2.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/services/bilibili_cheese_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/widgets/page_background.dart';

class BilibiliUpowerRankPage extends StatefulWidget {
  final int mid;
  final String name;

                             
  final int? count;

  const BilibiliUpowerRankPage({
    super.key,
    required this.mid,
    this.name = '',
    this.count,
  });

  @override
  State<BilibiliUpowerRankPage> createState() => _BilibiliUpowerRankPageState();
}

class _BilibiliUpowerRankPageState extends State<BilibiliUpowerRankPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();

  TabController? _tabController;
  List<CheeseUpowerLevel> _levels = const [];
                                    
  final Map<int, List<CheeseUpowerRankEntry>> _cache = {};
  final Set<int> _loadingLevels = {};
  String? _error;

                                      
  int _currentPrivilegeType = 0;

  bool get _loading => _loadingLevels.contains(_currentPrivilegeType);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    final level = _currentPrivilegeType;
    if (!refresh && (_cache[level] != null || _loadingLevels.contains(level))) {
      return;
    }
    setState(() {
      _loadingLevels.add(level);
      _error = null;
    });
    final rank = await BilibiliCheeseService.fetchUpowerRank(
      upMid: widget.mid,
      privilegeType: level > 0 ? level : null,
    );
    if (!mounted) return;
    setState(() {
      _loadingLevels.remove(level);
      if (rank == null) {
        _error = BilibiliCheeseService.lastErrorDetail ?? '充电榜加载失败';
        return;
      }
      _cache[level] = rank.entries;
                                                   
      if (level == 0 && rank.levels.length > 1 && _tabController == null) {
        _levels = rank.levels;
        _tabController = TabController(length: _levels.length, vsync: this);
        _tabController!.addListener(() {
          if (_tabController!.indexIsChanging) return;
          final type = _levels[_tabController!.index].privilegeType;
          if (type == _currentPrivilegeType) return;
          setState(() => _currentPrivilegeType = type);
          _load();
        });
      }
    });
  }

  List<CheeseUpowerRankEntry> get _entries =>
      _cache[_currentPrivilegeType] ?? const [];

  Color _rankColor(int index, ColorScheme cs) => switch (index) {
    0 => const Color(0xFFfdad13),
    1 => const Color(0xFF8aace1),
    2 => const Color(0xFFdfa777),
    _ => cs.outline,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final countSuffix = widget.count == null ? '' : '(${widget.count})';
    final tabController = _tabController;
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        title: Text(
          '${widget.name.isEmpty ? 'UP主' : widget.name}的充电排行榜$countSuffix',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BrowserPage(
                    initialUrl:
                        'https://member.bilibili.com/mall/upower-pay?mid=${widget.mid}&oid=${widget.mid}',
                    title: '充电',
                  ),
                ),
              );
            },
            child: const Text('充电'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer),
          Column(
            children: [
              if (tabController != null)
                Material(
                  color: cs.surfaceContainerLow,
                  child: TabBar(
                    controller: tabController,
                    labelColor: cs.primary,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    indicatorColor: cs.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      for (final l in _levels)
                        Tab(text: '${l.name}(${l.memberTotal})'),
                    ],
                  ),
                ),
              Expanded(
                child: _error != null && _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: () => _load(refresh: true),
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : _entries.isEmpty && _loading
                    ? const Center(child: CircularProgressIndicator())
                    : AppRefreshIndicator(
                        onRefresh: () => _load(refresh: true),
                        child: CustomScrollView(
                          controller: _scroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverList.builder(
                              itemCount: _entries.length,
                              itemBuilder: (context, index) =>
                                  _buildTile(cs, index),
                            ),
                            if (_entries.isEmpty)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Text(
                                    '还没有充电用户',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).padding.bottom + 32,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTile(ColorScheme cs, int index) {
    final item = _entries[index];
    final rankNo = item.rank > 0 ? item.rank : index + 1;
    return ListTile(
      onTap: item.mid > 0
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BilibiliUserSpacePage(mid: item.mid),
                ),
              );
            }
          : null,
      leading: SizedBox(
        width: 32,
        child: Center(
          child: Text(
            '$rankNo',
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
              color: _rankColor(index, cs),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: cs.surfaceContainerHighest,
            backgroundImage: item.avatar.isEmpty
                ? null
                : CachedImageProvider(item.avatar),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              item.nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      trailing: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${item.day}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(text: ' 天', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
