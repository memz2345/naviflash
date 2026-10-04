                                                
  
                             
                                                              
                                                  
                                 
                                                 
                                    
                                               
                                               
                         
import 'package:flutter/material.dart';

                  
                                               
                                          
                                         
class CommentComposerFab extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

                                                             
                                 
  final bool labelVisible;

                                       
  final Object? heroTag;

  const CommentComposerFab({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.labelVisible,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fab = FloatingActionButton.extended(
                                                   
      heroTag: null,
      tooltip: label,
      onPressed: onPressed,
                                                            
      backgroundColor: cs.secondaryContainer,
      foregroundColor: cs.onSecondaryContainer,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                         
                   
      extendedIconLabelSpacing: 0,
                                               
                                     
      extendedPadding: const EdgeInsetsDirectional.only(start: 16, end: 16),
      icon: Icon(icon),
      label: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ClipRect(
            child: SizeTransition(
              sizeFactor: anim,
              axis: Axis.horizontal,
                                  
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        ),
        child: labelVisible
            ? Row(
                key: const ValueKey(true),
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 8),
                  Text(label, maxLines: 1, softWrap: false),
                ],
              )
            : const SizedBox.shrink(key: ValueKey(false)),
      ),
    );
    if (heroTag != null) return Hero(transitionOnUserGestures: true, tag: heroTag!, child: fab);
    return fab;
  }
}
