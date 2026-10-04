                                            
  
                                            
                                                     
                                      
                                      
                                         
                                            
  
                                                 
                                                
                                                            
                          
  
                                  

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/morph_widgets.dart';
import 'package:naviflash/widgets/search_video_menu.dart';

               
   
           
                                        
                          
                            
                                     
                     
                
                                                                        
                        
                             
                     
                              
                           
          
        
     
       
   
                                         
                                                       
                                          
class LiquidGlassMenuButton extends StatefulWidget {
                                                       
  final IconData icon;

                                                  
                                       
  final Widget? customChild;

             
  final String? tooltip;

             
  final List<GlassMenuAction> actions;

                  
  final double menuWidth;

                 
  final double menuRadius;

                   
  final double size;

                 
  final double iconSize;

                                                          
                                               
     
                                                       
                              
  final bool useMorphStyle;

                                                  
  final Color? iconColor;

                                              
                        
  final EdgeInsetsGeometry? padding;

                                                                                 
  final bool frosted;

                                                   
                                          
  final bool transparent;

                                 
  final VoidCallback? overrideOnTap;

  const LiquidGlassMenuButton({
    super.key,
    required this.icon,
    required this.actions,
    this.customChild,
    this.tooltip,
    this.menuWidth = 220,
    this.menuRadius = 18.0,
    this.size = 40.0,
    this.iconSize = 22.0,
    this.useMorphStyle = true,
    this.iconColor,
    this.padding,
    this.frosted = false,
    this.transparent = false,
                                     
                                       
                                    
    this.overrideOnTap,
  });

  @override
  State<LiquidGlassMenuButton> createState() => _LiquidGlassMenuButtonState();
}

class _LiquidGlassMenuButtonState extends State<LiquidGlassMenuButton> {
                                          
  final GlobalKey _anchorKey = GlobalKey();

                                               
                                           
                                        
  Future<void> _handleTriggerTap(VoidCallback toggle) async {
    final override = widget.overrideOnTap;
    if (override != null) {
      override();
      return;
    }
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.attached) {
      final ok = await tryShowNativeGlassMenu(
        context,
        actions: widget.actions,
        globalPosition: box.localToGlobal(Offset(0, box.size.height)),
        menuWidth: widget.menuWidth,
      );
      if (ok || !mounted) return;
    }
    toggle();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final jelly = SettingsService.liquidGlassMenuJellyEnabled;

                                                  
                                        
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(disableAnimations: !jelly),
      child: CupertinoTheme(
                                                     
        data: CupertinoThemeData(brightness: brightness),
        child: GlassMenu(
                                                  
                                     
          triggerBuilder: (ctx, toggle) => KeyedSubtree(
            key: _anchorKey,
            child: _buildButton(onTap: () => _handleTriggerTap(toggle)),
          ),
          items: [
            for (final action in widget.actions)
              buildGlassMenuItem(action, brightness),
          ],
          menuWidth: widget.menuWidth,
          menuBorderRadius: widget.menuRadius,
          itemBorderRadius: (widget.menuRadius - 6.0).clamp(12.0, 24.0),
          autoAdjustToScreen: true,
          menuPadding: const EdgeInsets.all(10),
          settings: buildNaviGlassSettings(),
          quality: naviGlassAdvanced
              ? GlassQuality.premium
              : GlassQuality.minimal,
          selectionColor: brightness == Brightness.dark
              ? const Color(0x26FFFFFF)
              : const Color(0x1F000000),
          showDismissBarrier: true,
        ),
      ),
    );
  }

  Widget _buildButton({required VoidCallback onTap}) {
    if (widget.useMorphStyle) {
      return MorphIconButton(
        icon: widget.icon,
        tooltip: widget.tooltip,
        size: widget.size,
        iconSize: widget.iconSize,
        frosted: widget.frosted,
                                       
                            
        transparent: widget.transparent,
        iconColor: widget.iconColor,
        onTap: onTap,
      );
    }
                                        
    final color = widget.iconColor ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    final content = widget.customChild ??
        Icon(widget.icon, color: color, size: widget.iconSize);
    return IconButton(
      icon: content,
      tooltip: widget.tooltip,
      onPressed: onTap,
      padding: widget.padding,
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: color,
      ),
    );
  }
}
