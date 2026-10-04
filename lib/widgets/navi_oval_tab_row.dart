                                     
  
                                           
                                     
                                        
                            
                                    
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:naviflash/widgets/long_press_glass_tab_switcher.dart';

class NaviOvalTabRow extends StatelessWidget {
                                
  final List<String> labels;

  final int selectedIndex;

                                         
  final ValueChanged<int> onTap;

                             
  final List<GlassTab>? glassTabs;

               
  final double height;

  const NaviOvalTabRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onTap,
    this.glassTabs,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
                                                  
    Widget row = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < labels.length; i++)
            _NaviOvalTab(
              label: labels[i],
              selected: i == selectedIndex,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
    final tabs = glassTabs;
    if (tabs == null || tabs.isEmpty) {
      return SizedBox(height: height, child: Center(child: row));
    }
    return LongPressGlassTabSwitcher(
      tabs: tabs,
      selectedIndex: selectedIndex,
      onIndexChanged: onTap,
      barHeight: height - 4,
      child: Center(child: row),
    );
  }
}

                                         
class _NaviOvalTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NaviOvalTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      splashColor: cs.primary.withValues(alpha: 0.12),
      highlightColor: cs.primary.withValues(alpha: 0.08),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
                                                       
                                             
                            
          SizedBox(
            height: 19,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.0,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
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
