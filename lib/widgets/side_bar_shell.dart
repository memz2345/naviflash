                                  
  
                                 
                                     
                                             
                                                 
                                       
                
                                              
                                   
                                   
                                              
import 'dart:async';
import 'package:naviflash/screens/bilibili_search_page.dart';

import 'package:flutter/material.dart';
import 'package:naviflash/screens/bilibili_recommend_page.dart';
import 'package:naviflash/screens/bilibili_mine_page.dart';
import 'package:naviflash/screens/bilibili_dynamics_page.dart';
import 'package:naviflash/screens/message_center_page.dart';
import 'package:naviflash/screens/bilibili_shorts_page.dart';
import 'package:naviflash/services/memory_pressure_service.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'collapsible_side_bar.dart';

class SideBarShell extends StatefulWidget {
  const SideBarShell({super.key});

  @override
  State<SideBarShell> createState() => _SideBarShellState();
}

class _SideBarShellState extends State<SideBarShell> {
                                                
                                       
                                          
                                    
                          
                                              
                                    
                                                        
    
                                               
                                                   
                                            
                                            
  static const List<String> _sectionIds = [
    'home',
    'search',
    'dynamics',
    'messages',
    'mine',
    'shorts',
  ];

                                           
                                               
  final GlobalKey<BilibiliShortsPageState> _shortsKey = GlobalKey();

                                 
  static const Duration _hoverDelay = Duration(milliseconds: 800);

  String _currentPageId = 'home';

                                            
  final Set<String> _visited = {'home'};

                         
  bool _hoverArmed = false;

                             
  bool _hoverExpanded = false;
  Timer? _hoverTimer;

  @override
  void initState() {
    super.initState();
                                    
                          
    CollapsibleSideBar.expanded.addListener(_onManualExpandedChanged);
                                               
                                                         
                            
    MemoryPressureService.tick.addListener(_onMemoryPressure);
  }

  @override
  void dispose() {
    CollapsibleSideBar.expanded.removeListener(_onManualExpandedChanged);
    MemoryPressureService.tick.removeListener(_onMemoryPressure);
    _hoverTimer?.cancel();
    super.dispose();
  }

  void _onMemoryPressure() {
    if (!mounted || _visited.length <= 1) return;
    setState(() => _visited.retainAll({_currentPageId}));
  }

  void _onManualExpandedChanged() {
                                       
                  
    _hoverTimer?.cancel();
    _hoverArmed = false;
    setState(() => _hoverExpanded = false);
  }

  void _onHoverEnter() {
    if (CollapsibleSideBar.expanded.value) return;              
    _hoverArmed = true;
    _hoverTimer?.cancel();
    _hoverTimer = Timer(_hoverDelay, () {
      if (!mounted || !_hoverArmed) return;
      if (CollapsibleSideBar.expanded.value) return;
      setState(() => _hoverExpanded = true);
    });
  }

  void _onHoverExit() {
    _hoverArmed = false;
    _hoverTimer?.cancel();
    if (_hoverExpanded) setState(() => _hoverExpanded = false);
  }

                                     
  void _onOverlayMenuTap() {
    CollapsibleSideBar.toggle();
    if (_hoverExpanded) setState(() => _hoverExpanded = false);
  }

  void _onNavigate(String pageId) {
    if (pageId == _currentPageId || !_sectionIds.contains(pageId)) return;
    setState(() {
      _currentPageId = pageId;
      _visited.add(pageId);
    });
                                              
                               
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_currentPageId == 'shorts') {
        _shortsKey.currentState?.resumePlayback();
      } else {
        _shortsKey.currentState?.pausePlayback();
      }
    });
  }

  Widget _buildSection(String id) {
    return switch (id) {
      'search' => const BilibiliSearchPage(embeddedInShell: true),
      'dynamics' => const BilibiliDynamicsPage(embeddedInShell: true),
      'messages' => const MessageCenterPage(embeddedInShell: true),
      'mine' => const BilibiliMinePage(embeddedInShell: true),
                                               
                                        
                        
      'shorts' => BilibiliShortsPage(key: _shortsKey, embeddedInShell: true),
                   
      _ => const BilibiliRecommendPage(embeddedInShell: true),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
                                       
                                           
                                                    
                                                 
                                     
                                                
                                                   
                                              
    return IosBackdropScale(
      child: ColoredBox(
                               
        color: cs.surfaceContainerLow,
        child: SafeArea(
          top: true,
          bottom: false,
          left: false,
          right: false,
          child: Stack(
            children: [
                                       
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RepaintBoundary(
                                                   
                                                       
                                              
                    child: Visibility(
                      visible: !_hoverExpanded,
                      maintainSize: true,
                      maintainState: true,
                      maintainAnimation: true,
                      child: CollapsibleSideBar(
                        currentPage: _currentPageId,
                        onNavigate: _onNavigate,
                      ),
                    ),
                  ),
                                                       
                  Expanded(
                    child: RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: ColoredBox(
                                                              
                                                        
                                                             
                                                                        
                                                              
                                                          
                                                                         
                                                   
                                                            
                                                     
                                                          
                            color: cs.surfaceContainer,
                            child: IndexedStack(
                              index: _sectionIds.indexOf(_currentPageId),
                              children: [
                                for (final id in _sectionIds)
                                  _visited.contains(id)
                                      ? RepaintBoundary(
                                                                           
                                                                    
                                                                
                                                                           
                                                                                  
                                                                              
                                          child: HeroMode(
                                            enabled: id == _currentPageId,
                                            child: _SectionSwitchFade(
                                              active: id == _currentPageId,
                                              child: _buildSection(id),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
                                               
                                           
                          
              if (!CollapsibleSideBar.expanded.value)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: MouseRegion(
                                                      
                                           
                                            
                    onEnter: (_) => _onHoverEnter(),
                    onExit: (_) => _onHoverExit(),
                    child: AnimatedContainer(
                      duration: CollapsibleSideBar.animDuration,
                      curve: CollapsibleSideBar.animCurve,
                      width: _hoverExpanded
                          ? CollapsibleSideBar.expandedWidth
                          : CollapsibleSideBar.minWidth,
                      child: CollapsibleSideBar(
                        currentPage: _currentPageId,
                        onNavigate: _onNavigate,
                        expandedOverride: _hoverExpanded,
                        overlay: true,
                        onOverlayMenuTap: _onOverlayMenuTap,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

                                                  
                                                      
                                                 
                                                  
                                  
class _SectionSwitchFade extends StatelessWidget {
  final bool active;
  final Widget child;

  const _SectionSwitchFade({required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: active ? Offset.zero : const Offset(0, 0.02),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }
}
