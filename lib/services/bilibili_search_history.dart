                                            
  
                                               
import 'package:shared_preferences/shared_preferences.dart';
import 'bilibili_search_service.dart';

class BilibiliSearchHistory {
                     
  static const int maxLength = 20;

  static String _key(BiliSearchType type) =>
      'bili_search_history_${type.code}';

                         
  static Future<List<String>> load(BiliSearchType type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key(type)) ?? const [];
  }

                              
  static Future<void> persist(BiliSearchType type, List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(type), list.take(maxLength).toList());
  }

                
  static Future<void> clear(BiliSearchType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(type));
  }
}
