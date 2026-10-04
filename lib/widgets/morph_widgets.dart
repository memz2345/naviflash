                                 
  
                            
                                                              

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:naviflash/widgets/app_tooltip.dart';


               
const double kGroupRadius = 16.0;

                    
const double kItemRadius = 8.0;

                                                 
const double kItemPressedRadius = 12.0;

                    
const double kListEdgeRadius = 2.0;

                              
const double kIconBtnRadius = 14.0;

                      
const double kCardGap = 2.0;

           
const Duration kMorphDuration = Duration(milliseconds: 70);

           
const Curve kMorphCurve = Curves.fastOutSlowIn;


                                       
   
           
                    
                             
                    
                                                    
     
       
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.secondaryContainer;
                                     
    final baseColor = widget.transparent
        ? Colors.transparent
        : widget.frosted
        ? base.withValues(alpha: 0.35)
        : base;
                                              
                        
    final pressedColor = widget.transparent
        ? Colors.white.withValues(alpha: 0.18)
        : Color.alphaBlend(
            cs.onSecondaryContainer.withValues(alpha: 0.12),
            baseColor,
          );

                            
    final radius =
        BorderRadius.circular(_pressed ? kIconBtnRadius : 100.0);
                                        
    final splashRadius = widget.transparent
        ? BorderRadius.circular(kIconBtnRadius)
        : radius;

    Widget button = AnimatedContainer(
      duration: kMorphDuration,
      curve: kMorphCurve,
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: _pressed ? pressedColor : baseColor,
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

    return Center(child: button);
  }
}


                                           
                           
   
           
              
                           
                      
                                   
                           
     
       
class MorphItem extends StatefulWidget {
                    
  final bool selected;

              
  final bool isFirst;

              
  final bool isLast;

                             
  final bool interactive;

  final Widget child;

  const MorphItem({
    super.key,
    required this.selected,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.interactive = true,
  });

  @override
  State<MorphItem> createState() => _MorphItemState();
}

class _MorphItemState extends State<MorphItem> {
  bool _pressed = false;

  BorderRadius _defaultRadius() {
    const big = kItemPressedRadius;
    const edge = kListEdgeRadius;

    if (widget.isFirst && widget.isLast) {
      return BorderRadius.circular(big);
    }
    if (widget.isFirst) {
      return const BorderRadius.only(
        topLeft: Radius.circular(big),
        topRight: Radius.circular(big),
        bottomLeft: Radius.circular(edge),
        bottomRight: Radius.circular(edge),
      );
    }
    if (widget.isLast) {
      return const BorderRadius.only(
        topLeft: Radius.circular(edge),
        topRight: Radius.circular(edge),
        bottomLeft: Radius.circular(big),
        bottomRight: Radius.circular(big),
      );
    }
    return BorderRadius.circular(edge);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base =
        widget.selected ? cs.secondaryContainer : cs.surfaceBright;
    final overlay = widget.selected
        ? cs.onSecondaryContainer.withValues(alpha: 0.10)
        : cs.onSurface.withValues(alpha: 0.08);
    final color = _pressed ? Color.alphaBlend(overlay, base) : base;

    final radius = _pressed
        ? BorderRadius.circular(kItemPressedRadius)
        : _defaultRadius();

    final container = AnimatedContainer(
      duration: kMorphDuration,
      curve: kMorphCurve,
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: widget.child,
      ),
    );

    if (!widget.interactive) return container;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: container,
    );
  }
}


                                          
class RowItem {
  final Widget child;
  final bool interactive;

  const RowItem({required this.child, this.interactive = true});
}


                                           
   
           
                         
              
                                                              
                                               
                                                             
        
     
       
List<Widget> buildMorphSegment({
  required List<Widget> items,
  double gap = kCardGap,
}) {
  return List.generate(items.length, (i) {
    return Padding(
      padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : gap),
      child: items[i],
    );
  });
}