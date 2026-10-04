                                          
  
                
  
                                         
                                       
  
                                                                
                                      
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bilibili_search_service.dart';

                   
Map<String, dynamic> _itemToJson(BiliSearchItem e) => {
  'type': e.type.code,
  'mid': e.mid,
  'titleSegments': [
    for (final s in e.titleSegments) {'t': s.text, 'h': s.highlight},
  ],
  'cover': e.cover,
  'subtitle': e.subtitle,
  'meta': e.meta,
  'badge': e.badge,
  'duration': e.duration,
  'actionUrl': e.actionUrl,
  'desc': e.desc,
  'play': e.play,
  'danmaku': e.danmaku,
  'id': e.id,
  'bvid': e.bvid,
  'seasonId': e.seasonId,
};

BiliSearchItem _itemFromJson(Map<String, dynamic> j) {
  final segs = <({String text, bool highlight})>[];
  final raw = j['titleSegments'];
  if (raw is List) {
    for (final s in raw) {
      if (s is Map) {
        segs.add((
          text: (s['t'] as String?) ?? '',
          highlight: (s['h'] as bool?) ?? false,
        ));
      }
    }
  }
  if (segs.isEmpty) {
    segs.add((text: (j['actionUrl'] as String?) ?? '', highlight: false));
  }
  return BiliSearchItem(
    type: BiliSearchType.values.firstWhere(
      (t) => t.code == j['type'],
      orElse: () => BiliSearchType.video,
    ),
    mid: (j['mid'] as num?)?.toInt() ?? 0,
    titleSegments: segs,
    cover: (j['cover'] as String?) ?? '',
    subtitle: (j['subtitle'] as String?) ?? '',
    meta: (j['meta'] as String?) ?? '',
    badge: (j['badge'] as String?) ?? '',
    duration: (j['duration'] as String?) ?? '',
    actionUrl: (j['actionUrl'] as String?) ?? '',
    desc: (j['desc'] as String?) ?? '',
    play: (j['play'] as num?)?.toInt() ?? 0,
    danmaku: (j['danmaku'] as num?)?.toInt() ?? 0,
    id: (j['id'] as num?)?.toInt() ?? 0,
    bvid: (j['bvid'] as String?) ?? '',
    seasonId: (j['seasonId'] as num?)?.toInt() ?? 0,
  );
}

                      
class BiliSearchCacheEntry {
  final List<BiliSearchItem> items;
  final int numResults;
  final int page;
  final bool hasMore;
  final DateTime savedAt;

  const BiliSearchCacheEntry({
    required this.items,
    required this.numResults,
    required this.page,
    required this.hasMore,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'items': [for (final e in items) _itemToJson(e)],
    'numResults': numResults,
    'page': page,
    'hasMore': hasMore,
    'savedAt': savedAt.toIso8601String(),
  };

  factory BiliSearchCacheEntry.fromJson(Map<String, dynamic> j) {
    final list = <BiliSearchItem>[];
    final raw = j['items'];
    if (raw is List) {
      for (final it in raw) {
        if (it is Map) {
          list.add(_itemFromJson(Map<String, dynamic>.from(it)));
        }
      }
    }
    return BiliSearchCacheEntry(
      items: list,
      numResults: (j['numResults'] as num?)?.toInt() ?? 0,
      page: (j['page'] as num?)?.toInt() ?? 0,
      hasMore: (j['hasMore'] as bool?) ?? false,
      savedAt:
          DateTime.tryParse((j['savedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

                                            
class BilibiliSearchCache {
  static const String _prefsKey = 'biliSearchResultsCache';
  static const Duration _ttl = Duration(minutes: 10);
  static const int _maxPerKey = 60;

                 
  static String keyFor({
    required String keyword,
    required BiliSearchType type,
    String filterKey = '',
  }) => '$type.code|$filterKey|$keyword';

  static Future<void> save(String key, BiliSearchCacheEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = _loadAll(prefs);
      all[key] = entry;
      _trim(all);
      await prefs.setString(
        _prefsKey,
        jsonEncode({for (final e in all.entries) e.key: e.value.toJson()}),
      );
    } catch (e) {
      debugPrint('⚠️ 保存搜索缓存失败: $e');
    }
  }

                                    
  static Future<BiliSearchCacheEntry?> load(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entry = _loadAll(prefs)[key];
      if (entry == null) return null;
      if (DateTime.now().difference(entry.savedAt) > _ttl) return null;
      if (entry.items.isEmpty) return null;
      return entry;
    } catch (e) {
      debugPrint('⚠️ 读取搜索缓存失败: $e');
      return null;
    }
  }

  static Map<String, BiliSearchCacheEntry> _loadAll(SharedPreferences prefs) {
    final out = <String, BiliSearchCacheEntry>{};
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return out;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        for (final e in decoded.entries) {
          if (e.value is Map) {
            out[e.key] = BiliSearchCacheEntry.fromJson(
              Map<String, dynamic>.from(e.value as Map),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ 解析搜索缓存失败: $e');
    }
    return out;
  }

  static void _trim(Map<String, BiliSearchCacheEntry> all) {
    if (all.length <= _maxPerKey) return;
    final entries = all.entries.toList()
      ..sort((a, b) => b.value.savedAt.compareTo(a.value.savedAt));
    final keep = entries.sublist(0, _maxPerKey);
    all
      ..clear()
      ..addEntries(keep);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
