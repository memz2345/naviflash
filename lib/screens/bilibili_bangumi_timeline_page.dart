                                                  
  
                                                      
                     
  
                                        
                                      
                                               
                                      
                
import 'package:flutter/material.dart';

import 'package:naviflash/screens/bilibili_bangumi_page.dart';
import 'package:naviflash/services/bilibili_bangumi_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/standard_list_page.dart';
import 'package:naviflash/widgets/underline_tab_row.dart';
import 'package:naviflash/widgets/page_loading.dart';

class BilibiliBangumiTimelinePage extends StatefulWidget {
  const BilibiliBangumiTimelinePage({super.key});

  @override
  State<BilibiliBangumiTimelinePage> createState() =>
      _BilibiliBangumiTimelinePageState();
}

class _BilibiliBangumiTimelinePageState
    extends State<BilibiliBangumiTimelinePage>
    with SingleTickerProviderStateMixin {
  List<BiliTimelineDay> _days = const [];
  bool _loading = true;
  String? _error;

                                    
  TabController? _tab;

                                          
                                                
  final Map<int, GlobalKey<RefreshIndicatorState>> _refreshKeys = {};

                        
  static const double _tabRowHeight = 46;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tab?.dispose();
    super.dispose();
  }

  Future<void> _load({bool viaRefresh = false}) async {
    setState(() {
                                         
                                
      _loading = _days.isEmpty && !viaRefresh;
      _error = null;
    });
    final days = await BilibiliBangumiService.fetchTimeline();
    if (!mounted) return;
    if (days.isEmpty && _days.isNotEmpty) {
                                            
      setState(() => _loading = false);
      if (viaRefresh) {
        showAppToast(context, '时间表刷新失败，请稍后重试', error: true);
      }
      return;
    }
    _syncTab(days);
    setState(() {
      _days = days;
      _loading = false;
      _error = days.isEmpty ? '时间表加载失败' : null;
    });
  }

                                        
                               
  void _userReload() {
    final idx = _tab?.index ?? 0;
    final state = _refreshKeys[idx]?.currentState;
    if (state == null) {
      _load(viaRefresh: true);
      return;
    }
    state.show();
  }

  GlobalKey<RefreshIndicatorState> _refreshKeyOf(int index) =>
      _refreshKeys.putIfAbsent(index, GlobalKey<RefreshIndicatorState>.new);

                                            
                                            
  void _syncTab(List<BiliTimelineDay> days) {
    final prev = _tab;
    if (prev != null && prev.length == days.length) {
      return;
    }
    final keepIndex = prev?.index;
    prev?.dispose();
    if (days.isEmpty) {
      _tab = null;
      return;
    }
    final todayIdx = days.indexWhere((d) => d.isToday);
    final initial = keepIndex != null && keepIndex >= 0 && keepIndex < days.length
        ? keepIndex
        : (todayIdx < 0 ? 0 : todayIdx);
    final tab = TabController(length: days.length, vsync: this, initialIndex: initial);
    tab.addListener(() {
      if (mounted && !tab.indexIsChanging) setState(() {});
    });
    _tab = tab;
  }

  static const List<String> _weekNames = [
    '',
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tab = _tab;
    return StandardListScaffold(
      topBar: StandardListTopBar(
        title: '追番时间表',
        showBack: true,
        bottomHeight: tab == null ? 0 : _tabRowHeight,
        bottom: tab == null ? null : _buildDateTabs(cs, tab),
        actions: [
          MorphIconButton(
            icon: Icons.refresh_rounded,
            tooltip: '刷新',
            onTap: _userReload,
            frosted: true,
          ),
        ],
      ),
      body: _buildBody(cs, tab),
    );
  }

                                          
  Widget _buildDateTabs(ColorScheme cs, TabController tab) {
    return UnderlineTabRow(
      labels: [
        for (final d in _days)
          d.isToday
              ? '${d.date} 今天'
              : '${d.date} ${_weekNames[d.dayOfWeek.clamp(1, 7)]}',
      ],
      selectedIndex: tab.index,
      onSelected: (i) {
        if (i != tab.index) tab.animateTo(i);
      },
      height: _tabRowHeight,
      fontSize: 13.5,
    );
  }

  Widget _buildBody(ColorScheme cs, TabController? tab) {
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _days.isEmpty,
    )) {
      return const PageLoadingIndicator();
    }
    if (_error != null && _days.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 44,
                    color: cs.onSurface.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: LoadRetryPill(onRetry: () => _load()),
          ),
        ],
      );
    }
    if (tab == null || _days.isEmpty) {
      return Center(
        child: Text(
          '时间表暂无数据',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      );
    }
                                       
                                         
    return TabBarView(
      controller: tab,
      children: [
        for (var i = 0; i < _days.length; i++) _buildDay(cs, i, _days[i]),
      ],
    );
  }

  Widget _buildDay(ColorScheme cs, int dayIndex, BiliTimelineDay day) {
    if (day.episodes.isEmpty) {
      return Center(
        child: Text(
          '当天没有更新',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      );
    }
                                         
                                  
    return AppRefreshIndicator(
      refreshIndicatorKey: _refreshKeyOf(dayIndex),
      onRefresh: () => _load(viaRefresh: true),
      color: cs.primary,
      child: GridView.builder(
        physics: const AppRefreshScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
        16,
                                      
                      
        kStdTopBarHeight + _tabRowHeight + 12,
        16,
        MediaQuery.of(context).padding.bottom + 32,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.56,
      ),
      itemCount: day.episodes.length,
      itemBuilder: (context, index) =>
          _EpisodeCard(cs: cs, item: day.episodes[index]),
      ),
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  final ColorScheme cs;
  final BiliTimelineEpisode item;

  const _EpisodeCard({required this.cs, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: item.seasonId > 0
          ? () => openBilibiliBangumi(
              context,
              seasonId: item.seasonId,
              initialTitle: item.title,
              initialCover: item.cover,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.cover.isEmpty
                      ? Container(color: cs.surfaceContainerHighest)
                      : Image(
                          image: CachedImageProvider(item.cover),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: cs.surfaceContainerHighest),
                        ),
                  if (item.follow == 1)
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          '已追番',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (item.pubTime.isNotEmpty)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.66),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item.pubTime,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.pubIndex.isNotEmpty)
            Text(
              item.pubIndex,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
