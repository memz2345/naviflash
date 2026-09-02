// lib/services/bilibili_search_history.dart
//
// B 站搜索历史：每个搜索类别（视频 / 番剧 / 影视 / 直播间 / 用户 / 专栏）
import 'package:shared_preferences/shared_preferences.dart';
import 'bilibili_search_service.dart';

class BilibiliSearchHistory {
  /// 单个类别最多保留的搜索记录数。
  static const int maxLength = 20;

  static String _key(BiliSearchType type) =>
      'bili_search_history_${type.code}';

  /// 读取某类别的搜索历史（最新的在最前）。
  static Future<List<String>> load(BiliSearchType type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key(type)) ?? const [];
  }

  /// 持久化某类别搜索历史（页面已维护好的去重列表）。
  static Future<void> persist(BiliSearchType type, List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(type), list.take(maxLength).toList());
  }

  /// 清空某类别搜索历史。
  static Future<void> clear(BiliSearchType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(type));
  }
}
