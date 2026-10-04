                                   
  
                                               
                                                            
                                            
  
                                     
                                             
                                                       
                                         
                                                                  
                                                    
                                             
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../services/settings_service.dart';
import 'liquid_glass.dart';

typedef LiquidDomMenuBuilder =
    Widget Function(BuildContext context, VoidCallback close);

                                                           
   
                                
                                       
                                                                
                                   
                      
VoidCallback showLiquidDomMenu(
  BuildContext context, {
  required Offset globalPosition,
  required LiquidDomMenuBuilder builder,
  required double menuWidth,
  required double menuHeight,
  double menuRadius = 18.0,

                                         
                                                      
  Size? originSize,

                  
  VoidCallback? onOpened,

                     
  VoidCallback? onOpenedComplete,

                  
  VoidCallback? onCloseStarted,

                           
  VoidCallback? onClosed,
}) {
  final size = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);
                                         
                                             
                        
  final maxContentH = size.height - padding.top - padding.bottom - 20.0 - 24.0;
  final targetContentHeight = math.min(
    menuHeight,
    math.max(48.0, maxContentH),
  );

                                                 
  final useJelly = SettingsService.liquidGlassMenuJellyEnabled;

  return showNaviGlassMenu(
    context,
    globalPosition: globalPosition,
    menuWidth: menuWidth,
                                                 
    menuHeight: targetContentHeight + 24.0,
    menuRadius: menuRadius,
    useJelly: useJelly,
    onOpened: onOpened,
    onOpenedComplete: onOpenedComplete,
    onCloseStarted: onCloseStarted,
    onClosed: onClosed,
    itemsBuilder: (menuContext, close) => [
      GlassMenuLabel(
                                                  
        height: targetContentHeight,
        horizontalPadding: 0,
                                                  
        child: SizedBox.expand(
          child: Builder(
            builder: (ctx) => builder(menuContext, close),
          ),
        ),
      ),
    ],
  );
}

                                                      
                                                         
                       
   
                                   
   
                                                  
                                                 
                        
VoidCallback showNaviGlassMenu(
  BuildContext context, {
  required Offset globalPosition,
  required List<Widget> Function(
    BuildContext menuContext,
    VoidCallback close,
  )
  itemsBuilder,
  required double menuWidth,
  double? menuHeight,
  double menuRadius = 18.0,
  bool useJelly = true,
  VoidCallback? onOpened,
  VoidCallback? onOpenedComplete,
  VoidCallback? onCloseStarted,
  VoidCallback? onClosed,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final overlayBox = overlay.context.findRenderObject() as RenderBox?;
                                                          
  final origin = overlayBox == null
      ? globalPosition
      : overlayBox.globalToLocal(globalPosition);

  final targetMediaQuery = MediaQuery.of(context);
  final targetTheme = Theme.of(context);
  final legacyPlain = SettingsService.liquidGlassMenusDisabled;
  final controller = GlassMenuController();

  final quality = naviGlassAdvanced && !legacyPlain
      ? GlassQuality.premium
      : GlassQuality.minimal;
  final settings = legacyPlain
                                       
      ? const LiquidGlassSettings(
          blur: 8,
          thickness: 4,
          glassColor: Color(0x14FFFFFF),
          saturation: 1.1,
          refractiveIndex: 0.6,
          lightIntensity: 0.5,
          ambientStrength: 0.2,
        )
      : buildNaviGlassSettings();

  late final OverlayEntry entry;
  VoidCallback closeHandle = () {};
  var onClosedFired = false;

  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: origin.dx,
      top: origin.dy,
      child: MediaQuery(
                                                      
                                        
        data: targetMediaQuery.copyWith(disableAnimations: !useJelly),
        child: CupertinoTheme(
                                                       
          data: CupertinoThemeData(brightness: targetTheme.brightness),
          child: GlassMenu(
            controller: controller,
            trigger: const SizedBox.shrink(),
            morphFromZero: true,
            autoAdjustToScreen: true,
            menuPadding: const EdgeInsets.all(10),
            menuWidth: menuWidth,
            menuHeight: menuHeight,
            menuBorderRadius: menuRadius,
            itemBorderRadius: (menuRadius - 6.0).clamp(12.0, 24.0),
            settings: settings,
            quality: quality,
            selectionColor: targetTheme.brightness == Brightness.dark
                ? const Color(0x26FFFFFF)
                : const Color(0x1F000000),
            showDismissBarrier: true,
            onClose: () {
              onCloseStarted?.call();
                                                         
              Future.delayed(const Duration(milliseconds: 450), () {
                if (entry.mounted) entry.remove();
                if (!onClosedFired) {
                  onClosedFired = true;
                  onClosed?.call();
                }
              });
            },
            items: itemsBuilder(context, () {
              closeHandle();
            }),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  closeHandle = () => controller.close();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!entry.mounted) return;
    controller.open();
    onOpened?.call();
                                                 
    Future.delayed(const Duration(milliseconds: 500), () {
      onOpenedComplete?.call();
    });
  });
  return () => controller.close();
}
