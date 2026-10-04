                                         
  
                                            
                                                 
import 'package:naviflash/services/bilibili_account_service.dart';

                                
Map<String, dynamic>? biliAsMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

                   
List<T> biliAsList<T>(dynamic v) {
  if (v is List) return v.whereType<T>().toList();
  return const [];
}

int biliToInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}

double biliToDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

String biliAsStr(dynamic v) => v is String ? v : (v == null ? '' : v.toString());

                                                   
String biliNormalizeUrl(String url) {
  if (url.isEmpty) return url;
  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('http://')) return 'https://${url.substring(7)}';
  return url;
}

                                            
String? biliLoginCookie([BiliCookieScope scope = BiliCookieScope.userSpace]) =>
    BilibiliAccountService.instance.cookieHeaderFor(scope)?['Cookie'];

                                              
String biliExtractCsrf(String cookie) {
  final m = RegExp(r'bili_jct=([^;]+)').firstMatch(cookie);
  return m?.group(1) ?? '';
}

                         
int get biliCurrentMid => BilibiliAccountService.instance.mid;
