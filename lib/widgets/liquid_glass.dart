                                
  
                                        
                                               
                                             
                                                     
                                           
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:naviflash/services/settings_service.dart';

LiquidGlassSettings buildNaviGlassSettings({
  double? blur,
  double? thickness,
  double? lightIntensity,
  double? tintOpacity,
  double? saturation,
  double? refractiveIndex,
  double? ambientStrength,
  double? lightAngle,
  double? chromaticAberration,
  double? ambientRim,
  double? fresnelStrength,
  double? glowIntensity,
  double? shadowElevation,
  GlassSpecularSharpness? specularSharpness,
}) {
  return LiquidGlassSettings(
    glassColor: Color.from(
      alpha: tintOpacity ?? SettingsService.liquidGlassTintOpacity,
      red: 1,
      green: 1,
      blue: 1,
    ),
    thickness: thickness ?? SettingsService.liquidGlassThickness,
    blur: blur ?? SettingsService.liquidGlassBlur,
    lightAngle: lightAngle ?? SettingsService.liquidGlassLightAngle,
    lightIntensity: lightIntensity ?? SettingsService.liquidGlassLightIntensity,
    ambientStrength:
        ambientStrength ?? SettingsService.liquidGlassAmbientStrength,
    refractiveIndex:
        refractiveIndex ?? SettingsService.liquidGlassRefractiveIndex,
    saturation: saturation ?? SettingsService.liquidGlassSaturation,
    chromaticAberration:
        chromaticAberration ?? SettingsService.liquidGlassChromaticAberration,
    ambientRim: ambientRim ?? 0,
    fresnelStrength: fresnelStrength ?? 1.0,
    glowIntensity: glowIntensity ?? 0.75,
    shadowElevation: shadowElevation ?? 1.0,
    specularSharpness: specularSharpness ?? GlassSpecularSharpness.medium,
  );
}

bool get naviGlassAdvanced =>
    SettingsService.fragmentRenderingEnabled &&
    ui.ImageFilter.isShaderFilterSupported;

class NaviGlass extends StatelessWidget {
  const NaviGlass({
    super.key,
    required this.radius,
    required this.child,
    this.circle = false,
    this.blur,
    this.thickness,
    this.lightIntensity,
    this.tintOpacity,
    this.saturation,
    this.refractiveIndex,
    this.ambientStrength,
    this.lightAngle,
    this.chromaticAberration,
    this.fresnelStrength,
    this.glowIntensity,
    this.shadowElevation,
    this.ownLayer = true,
    this.stretch = 0.0,
    this.interactionScale = 1.05,
    this.glassify = false,
    this.glassifySettings,
    this.quality,
  });

                              
  final double radius;

                
  final Widget child;

                        
  final bool circle;

                                
  final double? blur;

                                   
                         
  final double? thickness;

                              
  final double? lightIntensity;

                                     
                         
  final double? tintOpacity;

                                        
  final double? saturation;

                                             
  final double? refractiveIndex;

                         
  final double? ambientStrength;

                             
  final double? lightAngle;

                           
  final double? chromaticAberration;

                                              
  final double? fresnelStrength;

                                          
  final double? glowIntensity;

                                           
     
                                      
                   
  final double? shadowElevation;

                            
     
                                                   
                             
  final bool ownLayer;

                                      
  final double stretch;

                                 
  final double interactionScale;

                                                  
                            
  final bool glassify;

                                
  final LiquidGlassSettings? glassifySettings;

                                                     
     
                                               
                                                 
                                          
                                                
                          
  final GlassQuality? quality;

  LiquidGlassSettings buildSettings() => buildNaviGlassSettings(
    blur: blur,
    thickness: thickness,
    lightIntensity: lightIntensity,
    tintOpacity: tintOpacity,
    saturation: saturation,
    refractiveIndex: refractiveIndex,
    ambientStrength: ambientStrength,
    lightAngle: lightAngle,
    chromaticAberration: chromaticAberration,
    fresnelStrength: fresnelStrength,
    glowIntensity: glowIntensity,
    shadowElevation: shadowElevation,
  );

  LiquidGlassSettings buildGlassifySettings() =>
      glassifySettings ?? buildSettings();

  @override
  Widget build(BuildContext context) {
    final settings = buildSettings();
    final shape = circle
        ? const LiquidOval()
        : LiquidRoundedSuperellipse(borderRadius: radius);
    AdaptiveGlass surface(Widget content) => AdaptiveGlass(
      shape: shape,
      settings: settings,
      quality:
          quality ??
          (naviGlassAdvanced ? GlassQuality.premium : GlassQuality.minimal),
      useOwnLayer: ownLayer,
      isInteractive: stretch > 0,
      clipExpansion: stretch > 0 ? const EdgeInsets.all(16) : EdgeInsets.zero,
      child: content,
    );
    if (stretch > 0) {
      return GlassShellStretch(
        stretch: stretch,
        interactionScale: interactionScale,
        shell: surface(const SizedBox.expand()),
        content: child,
      );
    }
    return surface(child);
  }
}

                                    
                                        
   
                             
                             
                                    
class GlassShellStretch extends StatefulWidget {
  const GlassShellStretch({
    super.key,
    required this.stretch,
    required this.shell,
    required this.content,
    this.interactionScale = 1.05,
  });

                     
  final double stretch;

           
  final Widget shell;

                  
  final Widget content;

                  
  final double interactionScale;

  @override
  State<GlassShellStretch> createState() => _GlassShellStretchState();
}

class _GlassShellStretchState extends State<GlassShellStretch>
    with SingleTickerProviderStateMixin {
                                      
  static const double _dragSlop = 12.0;

                                                       
                     
  late final AnimationController _spring;
  Animation<Offset>? _releaseAnim;
  Offset _drag = Offset.zero;
  bool _engaged = false;

  void _down(PointerDownEvent event) {
    _spring.stop();
    _releaseAnim = null;
    _drag = Offset.zero;
    if (_engaged) {
      setState(() => _engaged = false);
    }
  }

  void _move(PointerMoveEvent event) {
    _spring.stop();
    _releaseAnim = null;
    _drag += event.delta;
    if (!_engaged && _drag.distance > _dragSlop) {
      setState(() => _engaged = true);
    } else if (_engaged) {
      setState(() {});
    }
  }

  void _up(PointerEvent event) {
    if (_engaged && _drag != Offset.zero) {
      _releaseAnim = Tween<Offset>(
        begin: _drag,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _spring, curve: Curves.elasticOut));
      _spring.forward(from: 0);
    }
    _drag = Offset.zero;
    if (_engaged) {
      setState(() => _engaged = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _spring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spring,
      builder: (context, _) {
        final Offset drag = (_releaseAnim != null && _spring.isAnimating)
            ? _releaseAnim!.value
            : _drag;
        final resisted = Offset(
          _resist(drag.dx) * widget.stretch,
          _resist(drag.dy) * widget.stretch,
        );
        final dragScale =
            1.0 +
            (resisted.dx.abs() + resisted.dy.abs()).clamp(0.0, 80.0) / 800.0;
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: _up,
          onPointerCancel: _up,
          child: Transform.translate(
            offset: resisted,
            child: AnimatedScale(
              scale: (_engaged ? widget.interactionScale : 1.0) * dragScale,
              duration: const Duration(milliseconds: 350),
              curve: Curves.elasticOut,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Positioned.fill(child: widget.shell),
                  widget.content,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _resist(double value) {
    final sign = value < 0 ? -1.0 : 1.0;
    return sign * value.abs() / (1.0 + value.abs() * 0.08);
  }
}

                                
   
                                    
                                   
                                
                
class StretchableNaviGlass extends StatelessWidget {
  const StretchableNaviGlass({
    super.key,
    required this.radius,
    required this.child,
    this.circle = false,
    this.blur,
    this.thickness,
    this.lightIntensity,
    this.ownLayer = true,
    this.stretch = 0.35,
  });

                              
  final double radius;

                           
  final Widget child;

            
  final bool circle;

                                
  final double? blur;

                                                
  final double? thickness;

                        
  final double? lightIntensity;

                            
  final bool ownLayer;

                     
  final double stretch;

  @override
  Widget build(BuildContext context) {
    final active = stretch > 0 && SettingsService.fragmentRenderingEnabled;
    final shell = NaviGlass(
      radius: radius,
      circle: circle,
      blur: blur,
      thickness: thickness,
      lightIntensity: lightIntensity,
      ownLayer: ownLayer,
      child: const SizedBox.expand(),
    );
    if (!active) {
      return NaviGlass(
        radius: radius,
        circle: circle,
        blur: blur,
        thickness: thickness,
        lightIntensity: lightIntensity,
        ownLayer: ownLayer,
        child: child,
      );
    }
    return GlassShellStretch(stretch: stretch, shell: shell, content: child);
  }
}

                                  
                            
                                                                    
                      
class GlassMenuSurface extends StatelessWidget {
  const GlassMenuSurface({
    super.key,
    required this.content,
    this.radius = 14.0,
    this.blur,
    this.tintOpacity,
    this.lightIntensity,
    this.stretch = 0.35,
    this.legacyDecoration,
    this.legacyClipRadius,
  });

                  
  final Widget content;

               
  final double radius;

                                
  final double? blur;

                                                   
     
                                       
                                    
  final double? tintOpacity;

                             
  final double? lightIntensity;

                       
  final double stretch;

                                       
  final BoxDecoration? legacyDecoration;

                                 
  final BorderRadius? legacyClipRadius;

  @override
  Widget build(BuildContext context) {
    if (SettingsService.liquidGlassMenusDisabled) {
      Widget legacy = Container(decoration: legacyDecoration, child: content);
      if (legacyClipRadius != null) {
        legacy = ClipRRect(borderRadius: legacyClipRadius!, child: legacy);
      }
      legacy = BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: blur ?? SettingsService.liquidGlassBlur,
          sigmaY: blur ?? SettingsService.liquidGlassBlur,
        ),
        child: legacy,
      );
      return legacy;
    }
    return GlassShellStretch(
      stretch: stretch,
      shell: NaviGlass(
        radius: radius,
        blur: blur,
        tintOpacity: tintOpacity,
        lightIntensity: lightIntensity,
        child: const SizedBox.expand(),
      ),
      content: content,
    );
  }
}
