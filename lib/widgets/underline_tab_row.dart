                                     
  
                                
                                              
                                 
                                    
  
                                          
import 'package:flutter/material.dart';

import 'package:naviflash/widgets/expressive_app_bar.dart' show ScrollableTabRow;

class UnderlineTabRow extends StatelessWidget {
            
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

               
  final double height;

            
  final EdgeInsets padding;

                    
  final double tabPadding;

  final double fontSize;

  const UnderlineTabRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.height = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.tabPadding = 14,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: ScrollableTabRow(
        padding: padding,
        tabs: [
          for (var i = 0; i < labels.length; i++)
            _buildTab(context, cs, labels[i], i),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    ColorScheme cs,
    String label,
    int index,
  ) {
    final selected = index == selectedIndex;
    return InkWell(
      onTap: () => onSelected(index),
      customBorder: const StadiumBorder(),
      splashColor: cs.primary.withValues(alpha: 0.12),
      highlightColor: cs.primary.withValues(alpha: 0.08),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(tabPadding, 10, tabPadding, 4),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
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
