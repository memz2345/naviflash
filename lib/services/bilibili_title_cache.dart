                                         
  
                            
  
                                           
                                        
                                                  
  
                                     
                              
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

                            
class BilibiliTitleCache {
  static BilibiliTitleCache? _instance;

                                           
  static String? translatedTitle(String bvid) {
    final inst = _instance;
    if (inst == null || bvid.isEmpty) return null;
    final t = inst._titles[bvid];
    return (t == null || t.isEmpty) ? null : t;
  }

                                       
  static String displayTitle(String bvid, String fallback) =>
      translatedTitle(bvid) ?? fallback;

                                     
  static void remember(String bvid, String originalTitle, String translated) {
    final inst = _instance;
    if (inst == null || bvid.isEmpty) return;
    final t = translated.trim();
    if (t.isEmpty || t == originalTitle) return;
    inst._titles[bvid] = t;
    inst._persist();
  }

                                                
  static void rememberAll(Map<String, String> titles) {
    final inst = _instance;
    if (inst == null || titles.isEmpty) return;
    inst._titles.addAll(titles);
    inst._persist();
  }

  static const String _prefsKey = 'biliVideoTranslatedTitles';
  static const int _maxEntries = 2000;

  final Map<String, String> _titles = {};
  bool _loaded = false;

                
  Future<void> initialize() async {
    _instance = this;
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          for (final e in decoded.entries) {
            if (e.value is String) _titles[e.key] = e.value as String;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ 载入翻译标题缓存失败: $e');
    }
    _loaded = true;
  }

  bool get isLoaded => _loaded;

  void _persist() {
    if (_titles.length > _maxEntries) {
      final iter = _titles.entries;
      final keep = iter.length > _maxEntries
          ? iter.toList().sublist(iter.length - _maxEntries)
          : iter.toList();
      _titles
        ..clear()
        ..addEntries(keep);
    }
                  
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.setString(_prefsKey, jsonEncode(_titles));
        })
        .catchError((e) {
          debugPrint('⚠️ 保存翻译标题缓存失败: $e');
        });
  }

                 
  static Future<void> clearAll() async {
    _instance?._titles.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<void> clear() async {
    _titles.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

                                               
                                   
  static Future<List<MapEntry<String, String>>> allEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      final entries = <MapEntry<String, String>>[];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          for (final e in decoded.entries) {
            if (e.value is String) {
              entries.add(MapEntry(e.key, e.value as String));
            }
          }
        }
      }
      entries.sort((a, b) => a.key.compareTo(b.key));
      return entries;
    } catch (_) {
      return const [];
    }
  }

                        
  static Future<void> forget(String bvid) async {
    _instance?._titles.remove(bvid);
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        decoded.remove(bvid);
        await prefs.setString(_prefsKey, jsonEncode(decoded));
      }
    } catch (_) {}
  }
}
