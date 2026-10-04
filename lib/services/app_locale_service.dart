                                       
  
                                       
  
                   
                                       
                                                   
                                                               
                               
  
            
                                               
                                       
  
                                               
                                             
  
                                     
                                  
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'lnative_bridge.dart';
import 'settings_service.dart';

class AppLocaleService with WidgetsBindingObserver {
  AppLocaleService._();

  static final AppLocaleService instance = AppLocaleService._();

  SettingsService? _settings;

                                                     
  static Future<void> attach(SettingsService settings) async {
    final s = instance;
    s._settings = settings;
    if (!Platform.isAndroid) return;
    WidgetsBinding.instance.addObserver(s);
    NativeBridge.setOnAppLocalesChangedListener(s._onSystemLocalesChanged);
    await s._syncFromSystem(migrate: true);
  }

                                            
                                                                
                      
  static Future<void> applyInAppChoice(String? code) async {
    final settings = instance._settings;
    if (settings == null) {
      debugPrint('AppLocaleService 尚未 attach，忽略语言选择: $code');
      return;
    }
    await settings.setAppLocaleCode(code);
    if (Platform.isAndroid) {
      await NativeBridge.setSystemAppLocale(code);
    }
  }

                                                 
  Future<void> resync() => _syncFromSystem(migrate: false);

  void _onSystemLocalesChanged(List<String> tags) {
                                         
                                       
    resync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resync();
    }
  }

                                             
                               
                          
  Future<void> _syncFromSystem({required bool migrate}) async {
    final settings = _settings;
    if (settings == null) return;
    final tags = await NativeBridge.getSystemAppLocales();
    if (tags == null) return;                       
    if (tags.isEmpty) {
      final code = settings.appLocaleCode;
      if (code == null) return;
      if (migrate) {
                                         
        await NativeBridge.setSystemAppLocale(code);
      } else {
                           
        await settings.setAppLocaleCode(null);
      }
      return;
    }
    _applySystemTags(tags);
  }

  Future<void> _applySystemTags(List<String> tags) async {
    final settings = _settings;
    if (settings == null || tags.isEmpty) return;
    final normalized = normalizeLocaleTag(tags.first);
    if (settings.appLocaleCode != normalized) {
      await settings.setAppLocaleCode(normalized);
    }
  }

                                              
                                                     
  static String normalizeLocaleTag(String tag) {
    final parts = tag.replaceAll('_', '-').split('-');
    final lang = parts.isNotEmpty ? parts[0].toLowerCase() : '';
    final region = parts.length > 1 ? parts[1].toUpperCase() : null;
    if (lang == 'zh') {
      return switch (region) {
        'TW' => 'zh-TW',
        'HK' => 'zh-HK',
        _ => 'zh-CN',
      };
    }
    if (lang == 'en') return 'en-US';
    return tag;
  }
}
