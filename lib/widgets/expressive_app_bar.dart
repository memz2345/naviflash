                                      
import 'dart:ui';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/app_tooltip.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/long_press_glass_tab_switcher.dart';
import 'morph_card.dart';                                                  

                                     
   
           
                    
                             
                    
                                          
     
       
class MorphIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final double iconSize;

                                                 
  final bool frosted;

                                          
     
                                      
                                        
                            
  final bool transparent;

                                          
  final Color? iconColor;

  const MorphIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 40.0,
    this.iconSize = 22.0,
    this.frosted = false,
    this.transparent = false,
    this.iconColor,
  });

  @override
  State<MorphIconButton> createState() => _MorphIconButtonState();
}

class _MorphIconButtonState extends State<MorphIconButton> {
  bool _pressed = false;

                                                   
                                              
             
  bool _pointerDown = false;

  bool get _deformed => _pressed || _pointerDown;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.secondaryContainer;
                                           
                                   
    final baseColor = widget.transparent
        ? Colors.transparent
        : widget.frosted
        ? cs.surfaceContainer.withValues(alpha: 0.75)
        : base;
    final pressedColor = widget.transparent
                                             
                                      
        ? Colors.white.withValues(alpha: 0.18)
        : Color.alphaBlend(
            cs.onSecondaryContainer.withValues(alpha: 0.12),
            baseColor,
          );

                            
    final radius = BorderRadius.circular(_deformed ? kIconBtnRadius : 100.0);
                                                      
                                               
    final splashRadius = widget.transparent
        ? BorderRadius.circular(kIconBtnRadius)
        : radius;

    Widget button = AnimatedContainer(
      duration: kMorphDuration,
      curve: kMorphCurve,
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: _deformed ? pressedColor : baseColor,
        borderRadius: radius,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: splashRadius,
          highlightColor: Colors.transparent,
                                                  
                                                                
                             
          splashColor: widget.transparent
              ? Colors.white.withValues(alpha: 0.25)
              : cs.onSecondaryContainer.withValues(alpha: 0.3),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: widget.iconColor ?? cs.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ),
    );

                                            
    if (widget.frosted && !widget.transparent) {
      button = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: button,
        ),
      );
    }

    if (widget.tooltip != null) {
      button = AppTooltip(
        message: widget.tooltip!,
        triggerMode: TooltipTriggerMode.longPress,
        child: button,
      );
    }

                                                    
                                  
    button = Listener(
      onPointerDown: (_) => setState(() => _pointerDown = true),
      onPointerUp: (_) => setState(() => _pointerDown = false),
      onPointerCancel: (_) => setState(() => _pointerDown = false),
      child: button,
    );

    return Center(child: button);
  }
}

                      
   
                                     
   
           
                 
                   
                                                     
     
       
class FrostedPanel extends StatelessWidget {
                
  final double blurSigma;

                   
  final double opacity;

                        
  final Color? color;

              
  final BorderRadius? borderRadius;

  final Widget child;

  const FrostedPanel({
    super.key,
    required this.child,
    this.blurSigma = 10.0,
    this.opacity = 0.7,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
                                                
                                             
                                                  
                                             
                                           
    final bg = color ?? colorScheme.surfaceContainer.withValues(alpha: opacity);
                                                                          
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      clipBehavior: Clip.hardEdge,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
                                              
            border: Border.all(color: bg, width: 0.6),
          ),
          child: child,
        ),
      ),
    );
  }
}

                                          
   
                                                  
                                          
                                  
   
           
              
                                                                         
       
class GradientBlurBar extends StatelessWidget {
                     
  final double sigmaTop;

                     
  final double sigmaBottom;

                                
     
                                                         
                                                
                                                   
  final int bands;

                                  
  final double topOpacity;

               
  final double bottomOpacity;

  const GradientBlurBar({
    super.key,
    this.sigmaTop = 26.0,
    this.sigmaBottom = 4.0,
    this.bands = 3,
    this.topOpacity = 0.85,
    this.bottomOpacity = 0.30,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = bands > 1 ? bands : 1;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
                     
          for (var i = 0; i < n; i++)
            FractionallySizedBox(
              heightFactor: 1.0 / n,
              alignment: Alignment(0, -1.0 + ((2 * i + 1) / n)),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: lerpDouble(
                      sigmaTop,
                      sigmaBottom,
                      n == 1 ? 0.0 : i / (n - 1),
                    )!,
                    sigmaY: 0.0,                      
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
                          
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.surface.withValues(alpha: topOpacity),
                  cs.surface.withValues(alpha: bottomOpacity),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

                                                    
                                                                        
              
   
                                     
                                   
class FrostedSheet extends StatelessWidget {
  final Widget child;

                    
  final BorderRadius borderRadius;

                 
  final double blurSigma;

                     
  final double opacity;

                                     
  final Color? color;

                            
  final double stretch;

  const FrostedSheet({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(24)),
    this.blurSigma = 12.0,
    this.opacity = 0.75,
    this.color,
    this.stretch = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final legacyColor = (color ?? cs.surfaceContainerLow).withValues(
      alpha: opacity,
    );
    if (!SettingsService.fragmentRenderingEnabled) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(color: legacyColor, child: child),
        ),
      );
    }
    final radius = borderRadius.topLeft.x;
    return GlassShellStretch(
      stretch: stretch,
      shell: ClipRRect(
        borderRadius: borderRadius,
        child: NaviGlass(
          radius: radius,
          blur: blurSigma,
          child: const SizedBox.expand(),
        ),
      ),
      content: child,
    );
  }
}

                 
   
                              
                                                  
              
class ScrollableTabRow extends StatefulWidget {
  const ScrollableTabRow({
    super.key,
    required this.tabs,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> tabs;
  final EdgeInsetsGeometry padding;

  @override
  State<ScrollableTabRow> createState() => _ScrollableTabRowState();
}

class _ScrollableTabRowState extends State<ScrollableTabRow> {
  late final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
                                            
    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta == 0) return;
    final pos = _controller.position;
    final target = (pos.pixels + delta).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    _controller.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerSignal: _onPointerSignal,
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Padding(
                padding: widget.padding,
                child: Row(
                                               
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: widget.tabs,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

                                    
   
                                            
                                        
   
           
                        
                               
                                                       
                                                      
     
       
class FrostedSearchHeader extends StatelessWidget {
                                                    
  final bool collapsed;

                                         
                                     
                                   
  final ValueListenable<double>? progressListenable;

                        
  final Widget searchBar;

                                              
  final List<Widget> tabs;

                                                     
                                            
  final Widget? tabRow;

                                   
  final List<GlassTab>? glassTabs;

                  
  final int? glassSelectedIndex;

                     
  final ValueChanged<int>? onGlassTabSelected;

                   
  final double tabBarHeight;

  const FrostedSearchHeader({
    super.key,
    this.collapsed = false,
    this.progressListenable,
    required this.searchBar,
    this.tabs = const [],
    this.tabRow,
    this.glassTabs,
    this.glassSelectedIndex,
    this.onGlassTabSelected,
    this.tabBarHeight = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedPanel(
      opacity: 0.75,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                                                 
                                                           
            if (progressListenable != null)
              ValueListenableBuilder<double>(
                valueListenable: progressListenable!,
                builder: (context, p, child) => _collapseBar(1 - p, child!),
                child: searchBar,
              )
            else
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: collapsed ? 0.0 : 1.0),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                builder: (context, value, child) => _collapseBar(value, child!),
                child: searchBar,
              ),
                                                      
            ClipRect(
              child: SizedBox(
                height: tabBarHeight,
                width: double.infinity,
                child: tabRow ?? _buildTabs(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

                                           
                                         
  Widget _collapseBar(double value, Widget child) {
    final v = value.clamp(0.0, 1.0);
    return ClipRect(
      child: Align(
        heightFactor: v,
        alignment: Alignment.topCenter,
        child: FractionalTranslation(
          translation: Offset(0, -(1 - v)),
          child: Opacity(opacity: v, child: child),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    final normalTabs = ScrollableTabRow(tabs: tabs);
    final glassTabs = this.glassTabs;
    final glassIndex = glassSelectedIndex;
    final onGlassTabSelected = this.onGlassTabSelected;
    if (glassTabs == null ||
        glassIndex == null ||
        onGlassTabSelected == null ||
        glassTabs.isEmpty) {
      return normalTabs;
    }
    return LongPressGlassTabSwitcher(
      tabs: glassTabs,
      selectedIndex: glassIndex,
      onIndexChanged: onGlassTabSelected,
      barHeight: tabBarHeight - 4,
      child: normalTabs,
    );
  }
}

                             
   
                                               
   
           
                           
                         
                               
                               
                                            
        
                
                                                                   
        
     
       
class ExpressiveSliverAppBar extends StatelessWidget {
                      
  final String title;

                                             
  final Widget? leading;

                
  final List<Widget>? actions;

                                           
                                                         
                                                        
                     
  final double expandedHeight;

                          
  final bool pinned;

                                         
  final TextStyle? expandedTitleStyle;

                                     
  final TextStyle? collapsedTitleStyle;

                   
  final double blurSigma;

                      
  final double blurOpacity;

                        
  final VoidCallback? onTitleRepeatedTap;

  const ExpressiveSliverAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.expandedHeight = 152.0,
    this.pinned = true,
    this.expandedTitleStyle,
    this.collapsedTitleStyle,
    this.blurSigma = 10.0,
    this.blurOpacity = 0.7,
    this.onTitleRepeatedTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const leadingWidth = 48.0;
    const dur = Duration(milliseconds: 260);
    const curve = Curves.easeInOut;

    final hasLeading = leading != null;
    final topInset = MediaQuery.paddingOf(context).top;
    return SliverAppBar(
      pinned: pinned,
      leading: leading,
      automaticallyImplyLeading: hasLeading,
      actions: actions,
      backgroundColor: Colors.transparent,
                                                      
      expandedHeight: expandedHeight + topInset,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final safePadding = MediaQuery.of(context).padding;
          final isCollapsed =
              constraints.biggest.height <= kToolbarHeight + safePadding.top;

          return Stack(
            children: [
                                           
                                                                  
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: kToolbarHeight + safePadding.top,
                child: AnimatedOpacity(
                  opacity: isCollapsed ? 1 : 0,
                  duration: dur,
                  curve: curve,
                  child: FrostedPanel(
                    blurSigma: blurSigma,
                    opacity: blurOpacity,
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                                                               
                          SizedBox(
                            width: hasLeading
                                ? leadingWidth + safePadding.left + 12.0
                                : 8.0,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: onTitleRepeatedTap,
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    collapsedTitleStyle ??
                                    TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                            ),
                          ),
                                                         
                          SizedBox(width: (actions?.length ?? 0) * 48.0 + 16.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

                                     
              AnimatedOpacity(
                opacity: isCollapsed ? 0 : 1,
                duration: dur,
                curve: curve,
                child: AnimatedContainer(
                  duration: dur,
                  curve: curve,
                  alignment: Alignment.bottomLeft,
                                                                       
                  padding: EdgeInsets.only(
                    left: 16.0,
                    top: safePadding.top,
                    bottom: 28.0,
                  ),
                  child: GestureDetector(
                    onTap: onTitleRepeatedTap,
                    child: Text(
                      title,
                      style:
                          expandedTitleStyle ??
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
