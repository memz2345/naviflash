import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'liquid_glass.dart';

                                                                        
                                                                              
        
   
                                                                             
                                                                             
                                                                              
                                                      
class LongPressGlassTabSwitcher extends StatefulWidget {
  const LongPressGlassTabSwitcher({
    super.key,
    required this.child,
    required this.tabs,
    required this.selectedIndex,
    required this.onIndexChanged,
    this.onSelectionEnd,
    this.barHeight = 44.0,
    this.glassInset = EdgeInsets.zero,
  });

                                    
  final Widget child;

                                                             
  final List<GlassTab> tabs;

                                      
  final int selectedIndex;

                                                                     
  final ValueChanged<int> onIndexChanged;

                                                                        
  final ValueChanged<int>? onSelectionEnd;

                                                 
  final double barHeight;

                                           
                                         
                                           
                                    
  final EdgeInsetsGeometry glassInset;

  @override
  State<LongPressGlassTabSwitcher> createState() =>
      _LongPressGlassTabSwitcherState();
}

class _LongPressGlassTabSwitcherState extends State<LongPressGlassTabSwitcher> {
  bool _active = false;
  int? _dragIndex;
  int _pressIndex = 0;

                                           
                                  
  int _originIndex = 0;
  double _anchorDx = 0;
  double _itemWidth = 0;
  final ScrollController _scrollController = ScrollController();

  int get _displayIndex {
    final index = _dragIndex ?? widget.selectedIndex;
    return index.clamp(0, math.max(0, widget.tabs.length - 1));
  }

  double get _safeItemWidth =>
      _itemWidth > 0 ? _itemWidth : _computeItemWidth(context);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (widget.tabs.isEmpty) return;
    _itemWidth = _computeItemWidth(context);
    final index = _indexAt(details.localPosition);
    _originIndex = widget.selectedIndex;
    _pressIndex = index;
    _anchorDx = details.localPosition.dx;
    setState(() {
      _active = true;
      _dragIndex = index;
    });
    widget.onIndexChanged(index);
                                                                    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToAnchor(index, _anchorDx);
    });
  }

  void _onLongPressMove(LongPressMoveUpdateDetails details) {
    if (!_active || widget.tabs.isEmpty) return;
    final width = _safeItemWidth;
    if (width <= 0) return;
    final delta = details.localPosition.dx - _anchorDx;
    final index = (_pressIndex + (delta / width).round())
        .clamp(0, widget.tabs.length - 1);
    if (index == _dragIndex) return;
    setState(() => _dragIndex = index);
    _scrollToAnchor(index, _anchorDx, animate: true);
    widget.onIndexChanged(index);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_active) return;
                                                          
                                              
    final index = _dragIndex ?? widget.selectedIndex;
    widget.onSelectionEnd?.call(index);
    if (!mounted) return;
    setState(() {
      _active = false;
      _dragIndex = null;
    });
  }

  double _computeItemWidth(BuildContext context) {
    final theme = Theme.of(context);
    final style = (theme.textTheme.labelMedium ?? theme.textTheme.bodyMedium)!
        .copyWith(fontSize: 13);
    final scaler = MediaQuery.textScalerOf(context);
    var maxLabel = 0.0;
    for (final tab in widget.tabs) {
      final painter = TextPainter(
        text: TextSpan(text: tab.label ?? '', style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      maxLabel = math.max(maxLabel, painter.width);
    }
                                                                               
                                                                           
    return maxLabel + 12 + 8;
  }

                                                                          
  int _indexAt(Offset localPosition) {
    final width = _safeItemWidth;
    if (width <= 0 || widget.tabs.isEmpty) return 0;
    var index = (localPosition.dx / width).floor();
    if (Directionality.of(context) == TextDirection.rtl) {
      index = widget.tabs.length - 1 - index;
    }
    return index.clamp(0, widget.tabs.length - 1);
  }

                                                                  
     
                                                                            
                                                                            
                                                                               
  void _scrollToAnchor(int index, double anchorDx, {bool animate = false}) {
    if (!_scrollController.hasClients || widget.tabs.isEmpty) return;
    final max = _scrollController.position.maxScrollExtent;
    final target = ((_safeItemWidth * index) - anchorDx).clamp(0.0, max);
    if (!animate) {
      _scrollController.jumpTo(target);
      return;
    }
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tabs = widget.tabs;
    final itemWidth = _safeItemWidth;
    final glass = tabs.isEmpty
        ? const SizedBox.shrink(key: ValueKey('glass-empty'))
        : IgnorePointer(
            key: const ValueKey('glass-active'),
                                              
                                          
            child: Padding(
              padding: widget.glassInset,
              child: SizedBox(
                width: double.infinity,
                height: widget.barHeight,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: itemWidth * tabs.length,
                    height: widget.barHeight,
                    child: GlassTabBar.inline(
                      tabs: tabs,
                      selectedIndex: _displayIndex,
                      onTabSelected: widget.onIndexChanged,
                      barHeight: widget.barHeight,
                      horizontalPadding: 0,
                      verticalPadding: 0,
                      tabPadding: const EdgeInsets.symmetric(horizontal: 6),
                      iconLabelSpacing: 3,
                      labelFontSize: 13,
                      tabWidth: itemWidth,
                      iconSize: 18,
                      enableBlend: true,
                      blendAmount: 8,
                      showIndicator: true,
                      indicatorColor: cs.primary.withValues(alpha: 0.10),
                      indicatorPinchStrength: 0.25,
                      indicatorExpansion: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      settings: buildNaviGlassSettings(
                        blur: 6,
                        thickness: 18,
                        tintOpacity: 0.06,
                        lightIntensity: 0.06,
                        ambientStrength: 0.02,
                        fresnelStrength: 0.35,
                        glowIntensity: 0.08,
                        specularSharpness: GlassSpecularSharpness.soft,
                                                              
                                                           
                                                         
                        shadowElevation: 0,
                      ),
                      indicatorSettings: buildNaviGlassSettings(
                        blur: 2,
                        thickness: 16,
                        tintOpacity: 0.08,
                        lightIntensity: 0.04,
                        ambientStrength: 0.01,
                        ambientRim: 0.01,
                        fresnelStrength: 0.16,
                        glowIntensity: 0,
                        chromaticAberration: 0,
                        shadowElevation: 0,
                        specularSharpness: GlassSpecularSharpness.soft,
                      ),
                      quality: naviGlassAdvanced
                          ? GlassQuality.premium
                          : GlassQuality.minimal,
                      maskingQuality: MaskingQuality.high,
                      magnification: 1.04,
                      selectedIconColor: cs.primary,
                      selectedLabelColor: cs.primary,
                      unselectedIconColor:
                          cs.onSurface.withValues(alpha: 0.78),
                      unselectedLabelColor:
                          cs.onSurface.withValues(alpha: 0.78),
                      interactionGlowColor: cs.primary.withValues(alpha: 0.24),
                      glowBlurRadius: 12,
                      glowSpreadRadius: 1,
                      glowOpacity: 0.16,
                      pressScale: 1.01,
                    ),
                  ),
                ),
              ),
            ),
          );
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMove,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: () {
        if (!mounted || !_active) return;
                                                
                                            
                                          
        final origin = _originIndex;
        final changed = widget.selectedIndex != origin;
        setState(() {
          _active = false;
          _dragIndex = null;
        });
        if (changed) widget.onIndexChanged(origin);
      },
      child: Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _active
                ? const SizedBox.shrink(key: ValueKey('child-hidden'))
                : KeyedSubtree(
                    key: const ValueKey('child-visible'),
                    child: widget.child,
                  ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 140),
            reverseDuration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              fit: StackFit.passthrough,
              alignment: Alignment.center,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            ),
            child: _active
                ? glass
                : const SizedBox.shrink(key: ValueKey('glass-hidden')),
          ),
        ],
      ),
    );
  }
}
