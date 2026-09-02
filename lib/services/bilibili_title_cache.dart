// lib/services/bilibili_title_cache.dart
//
// 全局按 bvid 共享并持久化的视频翻译标题缓存。
//
// 目标：任何视频卡片（搜索 / 相关视频 / 收藏 / 播放历史 / 用户空间等）
// 只要某个 bvid 翻译过一次标题，就永久记住，无需再次请求 AI 翻译。
// 数据以 JSON 落盘 SharedPreferences，并在内存中保留一份，支持即时读取。
//
// 访问方法全部为静态且对「未初始化」安全（返回原文 / 空操作），因此
// 在 widget 测试或冷启动早期直接调用也不会抛错。
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局 bvid → 翻译标题 的持久化缓存服务。
class BilibiliTitleCache {
  static BilibiliTitleCache? _instance;

  /// 读取某 bvid 的翻译标题；未初始化 / 没有 / 空时返回 null。
  static String? translatedTitle(String bvid) {
    final inst = _instance;
    if (inst == null || bvid.isEmpty) return null;
    final t = inst._titles[bvid];
    return (t == null || t.isEmpty) ? null : t;
  }

  /// 便捷展示：有翻译标题就用翻译，否则用 [fallback] 原文。
  static String displayTitle(String bvid, String fallback) =>
      translatedTitle(bvid) ?? fallback;

  /// 记忆一个 bvid 的翻译标题（与原文不同才存储，避免污染）。
  static void remember(String bvid, String originalTitle, String translated) {
    final inst = _instance;
    if (inst == null || bvid.isEmpty) return;
    final t = translated.trim();
    if (t.isEmpty || t == originalTitle) return;
    inst._titles[bvid] = t;
    inst._persist();
  }

  /// 批量记忆：直接使用 translateTitles 返回的 Map（已过滤成功项）。
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

  /// 读取并载入磁盘缓存。
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
    // 异步落盘，不阻塞 UI
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.setString(_prefsKey, jsonEncode(_titles));
        })
        .catchError((e) {
          debugPrint('⚠️ 保存翻译标题缓存失败: $e');
        });
  }

  /// 清空全部翻译标题缓存。
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

  /// 列出全部翻译标题缓存（bvid → 译文，按 bvid 排序），供透明查看页展示。
  /// 直接读磁盘，不依赖 [initialize] 是否已执行。
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

  /// 删除单个 bvid 的翻译标题缓存。
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
