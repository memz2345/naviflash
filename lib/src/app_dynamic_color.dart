                                 
  
                                            
                           
  
                                                      
                                          
                                                      
                                                             
                                                            
                                               
                                    
                               
  
                                                
                           
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

class AppDynamicColorBuilder extends StatefulWidget {
  const AppDynamicColorBuilder({super.key, required this.builder});

                                                             
  final Widget Function(
    ColorScheme? lightDynamic,
    ColorScheme? darkDynamic,
  )
  builder;

  @override
  State<AppDynamicColorBuilder> createState() => _AppDynamicColorBuilderState();
}

class _AppDynamicColorBuilderState extends State<AppDynamicColorBuilder> {
  static const MethodChannel _channel =
      MethodChannel('com.memz2345.navi.flash/dynamic_color');

  ColorScheme? _light;
  ColorScheme? _dark;

                                   
                                
  int? _lastLightPrimary;
  int? _lastDarkPrimary;

  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_onNativeCall);
    _loadPalette();
  }

  @override
  void dispose() {
                                           
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _onNativeCall(MethodCall call) async {
    if (call.method == 'onColorsChanged') {
                             
      await _loadPalette();
      final seq = _loadSeq;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && seq == _loadSeq) _loadPalette();
      });
    }
  }

  Future<void> _loadPalette() async {
    final seq = ++_loadSeq;
    try {
                                                                    
      // ignore: deprecated_member_use
      final CorePalette? palette = await DynamicColorPlugin.getCorePalette();
      if (!mounted || seq != _loadSeq) return;
      if (palette != null) {
        final light = palette.toColorScheme();
        final dark = palette.toColorScheme(brightness: Brightness.dark);
        _applySchemes(light, dark);
        return;
      }
    } on PlatformException {
                         
    }

                                          
    if (!Platform.isAndroid && !Platform.isIOS) {
      try {
        final Color? accent = await DynamicColorPlugin.getAccentColor();
        if (!mounted || seq != _loadSeq) return;
        if (accent != null) {
          _applySchemes(
            ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.light),
            ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
          );
        }
      } on PlatformException {
        if (kDebugMode) {
          debugPrint('AppDynamicColor: 获取系统强调色失败');
        }
      }
    }
  }

                                             
  void _applySchemes(ColorScheme light, ColorScheme dark) {
    final lp = light.primary.toARGB32();
    final dp = dark.primary.toARGB32();
    if (lp == _lastLightPrimary && dp == _lastDarkPrimary) return;
    _lastLightPrimary = lp;
    _lastDarkPrimary = dp;
    setState(() {
      _light = light;
      _dark = dark;
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(_light, _dark);
}
