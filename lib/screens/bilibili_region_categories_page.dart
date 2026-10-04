                                                   
  
                                                   
                     
                                                           
                                               
                             
                                                   
                                                     
                                             
import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_audio_zone_page.dart';
import 'package:naviflash/screens/bilibili_region_videos_page.dart';
import 'package:naviflash/services/bilibili_region_service.dart';
import 'package:naviflash/src/content_reveal_gate.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/navi_spring_physics.dart';

                                     
const double _kTopBarHeight = 56.0;

                                        
const double _kTabBarHeight = 48.0;

class BilibiliRegionCategoriesPage extends StatefulWidget {
                               
                      
  final int initialTid;

  const BilibiliRegionCategoriesPage({super.key, this.initialTid = 0});

  @override
  State<BilibiliRegionCategoriesPage> createState() =>
      _BilibiliRegionCategoriesPageState();
}

class _BilibiliRegionCategoriesPageState
    extends State<BilibiliRegionCategoriesPage>
    with SingleTickerProviderStateMixin {
  static const double kCollapseThreshold = 120.0;

                      
  List<BiliRegion> get _groups => BilibiliRegionService.regions;

                                                
                                   
                                    
                                             
  late final TabController? _tabController;

                              
  int get _selectedIndex => _tabController?.index ?? 0;

  bool _topCollapsed = false;

                                      
                               
  ContentRevealGate? _revealGate;

                                    
  bool get _isContentGated => _revealGate?.isGated ?? false;

  double get _effectiveTopBarHeight =>
      _topCollapsed ? _kTabBarHeight : _kTopBarHeight + _kTabBarHeight;

  @override
  void initState() {
    super.initState();
    final groups = _groups;
    var initialIndex = 0;
    if (widget.initialTid > 0 && groups.isNotEmpty) {
                                
      var i = groups.indexWhere((g) => g.tid == widget.initialTid);
      if (i < 0) {
        i = groups.indexWhere(
          (g) => g.children.any((c) => c.tid == widget.initialTid),
        );
      }
      if (i >= 0) initialIndex = i;
    }
    if (groups.isEmpty) {
                                                    
                         
      _tabController = null;
    } else {
      _tabController = TabController(
        length: groups.length,
        initialIndex: initialIndex.clamp(0, groups.length - 1),
        vsync: this,
      )..addListener(_onTabChanged);
    }
    _armRevealGate();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _revealGate?.dispose();
    _revealGate = null;
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

  void _onScrollNotification(ScrollNotification n) {
    if (n is! ScrollUpdateNotification) return;
    final delta = n.scrollDelta ?? 0;
    var collapsed = _topCollapsed;
    if (delta > 0 && n.metrics.extentBefore > kCollapseThreshold) {
      collapsed = true;
    } else if (delta < 0 || n.metrics.extentBefore < 1) {
      collapsed = false;
    }
    if (collapsed != _topCollapsed) {
      setState(() => _topCollapsed = collapsed);
    }
  }

                                      
  void _selectGroup(int index) {
    final ctrl = _tabController;
    if (ctrl == null ||
        index == ctrl.index ||
        index < 0 ||
        index >= _groups.length) {
      return;
    }
    ctrl.animateTo(index);
  }

                                                       
  void _onTabChanged() {
    final ctrl = _tabController;
    if (ctrl == null || !mounted) return;
    setState(() {
      if (!ctrl.indexIsChanging) _topCollapsed = false;
    });
  }

  void _openRegion(BiliRegion region) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BilibiliRegionVideosPage(region: region),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

                                        
                                             
    final body = _isContentGated
        ? Column(
            children: [
              SizedBox(height: _effectiveTopBarHeight),
              const Expanded(
                child: Center(child: LoadingIndicatorM3E()),
              ),
            ],
          )
        : _tabController == null
        ? Column(
                                                      
            children: [
              SizedBox(height: _effectiveTopBarHeight),
              Expanded(
                child: Center(
                  child: Text(
                    '暂无分区',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          )
        : naviTabBarView(
                                                   
                                   
            controller: _tabController,
            children: [
              for (var i = 0; i < _groups.length; i++)
                NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    _onScrollNotification(n);
                    return false;
                  },
                                                       
                                                        
                  child: CustomScrollView(
                    physics: const ClampingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          height: _effectiveTopBarHeight,
                        ),
                      ),
                      ..._regionSlivers(cs, i),
                    ],
                  ),
                ),
            ],
          );

                                   
    return IosBackdropScale(
      child: Scaffold(
        backgroundColor: cs.surfaceContainer,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: body,
              ),
              Align(
                alignment: Alignment.topCenter,
                child: _buildTopBar(cs),
              ),
            ],
          ),
        ),
      ),
    );
  }

                                                
  List<Widget> _regionSlivers(ColorScheme cs, int groupIndex) {
    final group = _groups[groupIndex];
    if (group.children.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              '该分区下暂时没有子分区',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ];
    }
                                       
                                            
    final hasAudioEntry = group.tid == 3;
    final children = <BiliRegion>[
      BiliRegion(tid: group.tid, name: '全部', icon: group.icon),
      ...group.children,
    ];
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        sliver: SliverGrid(
                                          
                                                   
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 110,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              if (i == 0) {
                return _RegionCell(
                  region: children[0],
                  onOpen: _openRegion,
                );
              }
              if (hasAudioEntry && i == 1) return const _AudioZoneCell();
              final index = i - (hasAudioEntry ? 1 : 0);
              return _RegionCell(
                region: children[index],
                onOpen: _openRegion,
              );
            },
            childCount: children.length + (hasAudioEntry ? 1 : 0),
          ),
        ),
      ),
    ];
  }

                                            
  Widget _buildTopBar(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return FrostedPanel(
      opacity: 0.75,
      blurSigma: 12,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _topCollapsed ? 0.0 : 1.0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return ClipRect(
                  child: Align(
                    heightFactor: value,
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                );
              },
              child: SizedBox(
                height: _kTopBarHeight,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    MorphIconButton(
                      icon: Icons.arrow_back,
                      tooltip: l10n.homeBack,
                      onTap: () => Navigator.of(context).pop(),
                      frosted: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '分区',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: _kTabBarHeight,
              child: ScrollableTabRow(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: [
                  for (var i = 0; i < _groups.length; i++)
                    _buildGroupTab(_groups[i], i, cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

                                                   
  Widget _buildGroupTab(BiliRegion group, int index, ColorScheme cs) {
    final selected = index == _selectedIndex;
    return InkWell(
      onTap: () => _selectGroup(index),
      customBorder: const StadiumBorder(),
      splashColor: cs.primary.withValues(alpha: 0.12),
      highlightColor: cs.primary.withValues(alpha: 0.08),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Text(
              group.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: 3,
            width: selected ? 24 : 0,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

                                           
                             
                                           

                                  
                                     
class _AudioZoneCell extends StatelessWidget {
  const _AudioZoneCell();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BilibiliAudioZonePage(),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.headphones,
                size: 24,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '音频',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

                                              
class _RegionCell extends StatelessWidget {
  final BiliRegion region;
  final ValueChanged<BiliRegion> onOpen;

  const _RegionCell({required this.region, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onOpen(region),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(region.icon, size: 24, color: cs.primary),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                region.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
