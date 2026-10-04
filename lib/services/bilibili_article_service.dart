                                             
  
                                               
                                    
                                      
                                                          
                                        
                                                  
                                                    
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:naviflash/services/cache_dirs.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart' show WbiSign;
import 'package:naviflash/services/network_settings_service.dart';
import '../l10n/l10n_helper.dart';

                                            
                        
                                            

Map<String, dynamic>? _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

int _toInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}

                                         
String _normalizeUrl(String url) {
  if (url.isEmpty) return url;
  if (url.startsWith('bfs/')) return 'https://i0.hdslb.com/$url';
  if (url.startsWith('//')) return 'https:$url';
  return url;
}

                                            
      
                                            

class BiliArticleAuthor {
  final int mid;
  final String name;
  final String face;

  const BiliArticleAuthor({
    required this.mid,
    required this.name,
    required this.face,
  });

  factory BiliArticleAuthor.fromJson(Map<String, dynamic> json) {
    return BiliArticleAuthor(
      mid: _toInt(json['mid']),
      name: (json['name'] as String?) ?? '',
      face: _normalizeUrl((json['face'] as String?) ?? ''),
    );
  }
}

class BiliArticleStats {
  final int view;      
  final int like;      
  final int favorite;      
  final int reply;      
  final int share;      
  final int coin;      

  const BiliArticleStats({
    required this.view,
    required this.like,
    required this.favorite,
    required this.reply,
    required this.share,
    required this.coin,
  });

  factory BiliArticleStats.fromJson(Map<String, dynamic> json) {
    return BiliArticleStats(
      view: _toInt(json['view']),
      like: _toInt(json['like']),
      favorite: _toInt(json['favorite']),
      reply: _toInt(json['reply']),
      share: _toInt(json['share']),
      coin: _toInt(json['coin']),
    );
  }
}

                              
                                                                  
                                                       
class BiliArticleOps {
  final Object insert;
  final String clazz;

  const BiliArticleOps({required this.insert, required this.clazz});

                             
  String? get cardImage {
    final m = _asMap(insert);
    if (m == null) return null;
    final url = ((m['url'] as String?) ?? (m['image'] as String?)) ?? '';
    return url.isEmpty ? null : _normalizeUrl(url);
  }

                                             
  String? get cardId {
    final m = _asMap(insert);
    if (m == null) return null;
    final id = (m['id'] as String?) ?? '';
    return id.isEmpty ? null : id;
  }

  factory BiliArticleOps.fromJson(Map<String, dynamic> json) {
    final insert = json['insert'] ?? '';
    final attrs = _asMap(json['attributes']);
    return BiliArticleOps(
      insert: insert,
      clazz: (attrs?['class'] as String?) ?? '',
    );
  }
}

class BiliArticle {
  final int id;
  final int type;                            
  final String title;
  final BiliArticleAuthor? author;
  final int publishTime;          
  final String cover;      
  final List<String> images;        
  final String contentHtml;                    
  final List<BiliArticleOps> ops;                     
  final BiliArticleStats? stats;

                                                   
                            
  final String dynIdStr;

  const BiliArticle({
    required this.id,
    required this.type,
    required this.title,
    required this.author,
    required this.publishTime,
    required this.cover,
    required this.images,
    required this.contentHtml,
    required this.ops,
    required this.stats,
    required this.dynIdStr,
  });

                    
  bool get isOps => ops.isNotEmpty;

                 
  bool get isHtml => contentHtml.isNotEmpty;

                   
  String get url => 'https://www.bilibili.com/read/cv$id';

  factory BiliArticle.fromJson(Map<String, dynamic> json) {
    final authorJson = _asMap(json['author']);
    final statsJson = _asMap(json['stats']);
    final rawImages = json['origin_image_urls'];
    final imageUrls = rawImages is List
        ? rawImages
              .whereType<String>()
              .map(_normalizeUrl)
              .where((u) => u.isNotEmpty)
              .toList()
        : <String>[];
    final rawOps = json['ops'];
    final ops = rawOps is List
        ? rawOps
              .whereType<Map<String, dynamic>>()
              .map(BiliArticleOps.fromJson)
              .toList()
        : <BiliArticleOps>[];
    return BiliArticle(
      id: _toInt(json['id']),
      type: _toInt(json['type']),
      title: (json['title'] as String?) ?? '',
      author: authorJson == null
          ? null
          : BiliArticleAuthor.fromJson(authorJson),
      publishTime: _toInt(json['publish_time']),
      cover: imageUrls.isNotEmpty ? imageUrls.first : '',
      images: imageUrls,
      contentHtml: (json['content'] as String?) ?? '',
      ops: ops,
      stats: statsJson == null ? null : BiliArticleStats.fromJson(statsJson),
      dynIdStr: (json['dyn_id_str'] as String?) ?? '',
    );
  }
}

                                            
      
                                            

abstract final class BilibiliArticleService {
  static const String _viewApi = 'https://api.bilibili.com/x/article/view';

                                    
  static String? lastErrorDetail;

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

                                      
                                           
  static final String _buvid3 = _genBuvid3();

                                               
                                          
  static String? _spiBuvid3;
  static String? _spiBuvid4;

  static String _genBuvid3() {
    final r = Random();
    String hex(int n) =>
        List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    final uuid =
        '${hex(8)}-${hex(4)}-4${hex(3)}-'
                '${'89ab'[r.nextInt(4)]}${hex(3)}-${hex(12)}'
            .toUpperCase();
    return '$uuid${r.nextInt(100000).toString().padLeft(5, '0')}infoc';
  }

  static Future<void> _ensureDeviceFp() async {
    if (_spiBuvid3 != null) return;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
                                           
      final resp = await client
          .get(
            Uri.parse('https://api.bilibili.com/x/frontend/finger/spi'),
            headers: {
              ..._defaultHeaders,
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        if (json['code'] == -352) {
          debugPrint('[Article] spi 获取指纹被风控 (-352)，回退随机指纹');
        }
        return;
      }
      final data = _asMap(json['data']);
      if (data == null) return;
      final b3 = (data['b_3'] as String?) ?? '';
      if (b3.isNotEmpty) {
        _spiBuvid3 = b3;
        _spiBuvid4 = (data['b_4'] as String?) ?? '';
      }
    } catch (e) {
      debugPrint('[Article] 获取设备指纹失败: $e');
    }
  }

  static String _genBLsid() {
    const chars = '0123456789abcdef';
    final r = Random();
    String hex(int n) =>
        List.generate(n, (_) => chars[r.nextInt(chars.length)]).join();
    return '${hex(16)}_${hex(8)}';
  }

  static Future<String> _buildCookie() async {
    await _ensureDeviceFp();
    final parts = <String>[
      'buvid3=${_spiBuvid3 ?? _buvid3}',
      if (_spiBuvid4?.isNotEmpty ?? false) 'buvid4=$_spiBuvid4',
      'b_nut=${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
      'b_lsid=${_genBLsid()}',
    ];
    final accountCookie = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.article,
    )?['Cookie'];
    if (accountCookie != null && accountCookie.isNotEmpty) {
      parts.insert(0, accountCookie);
    }
    return parts.join('; ');
  }

  static Future<Map<String, String>> _buildHeaders({required int cvid}) async {
    final cookie = await _buildCookie();
    return {
      ..._defaultHeaders,
      'Referer': 'https://www.bilibili.com/read/cv$cvid/',
      'Origin': 'https://www.bilibili.com',
      'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

                                       
     
                                                
                                   
                     
  static Future<BiliArticle?> fetchArticle({required int cvid}) async {
    if (cvid <= 0) {
      lastErrorDetail = L10n.current.biliResponseNoData;
      return null;
    }
                                  
    final cached = await ArticleCache.load(cvid);
    if (cached != null) {
      debugPrint('[Article] 命中缓存: cv$cvid');
      lastErrorDetail = null;
      return BiliArticle.fromJson(cached);
    }
                     
    Map<String, dynamic>? data;
    String? netError;
    try {
                                          
      final params = await WbiSign.sign({
        'id': cvid.toString(),
        'gaia_source': 'main_web',
        'web_location': '333.976',
      });
      final uri = Uri.parse(_viewApi).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final headers = await _buildHeaders(cvid: cvid);
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        netError = L10n.current.biliHttpError(resp.statusCode);
        debugPrint('[Article] HTTP ${resp.statusCode}');
      } else {
        final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
        if (json is! Map<String, dynamic>) {
          netError = L10n.current.biliResponseNoData;
        } else {
          final code = json['code'];
          if (code != 0 && code != 200) {
            netError = 'code=$code ${json['message']} (cvid=$cvid)';
            debugPrint('[Article] code=$code ${json['message']}');
          } else {
            data = _asMap(json['data']);
            if (data == null || _toInt(data['id']) <= 0) {
              netError = L10n.current.biliResponseNoData;
              data = null;
            }
          }
        }
      }
    } catch (e) {
      netError = L10n.current.commentException('$e');
      debugPrint('[Article] 拉取专栏异常: $e');
    }
    if (data != null) {
      lastErrorDetail = null;
                     
      await ArticleCache.save(cvid, data);
      return BiliArticle.fromJson(data);
    }
                                      
    final stale = await ArticleCache.load(cvid, allowStale: true);
    if (stale != null) {
      lastErrorDetail = null;
      return BiliArticle.fromJson(stale);
    }
    lastErrorDetail = netError ?? L10n.current.biliResponseNoData;
    return null;
  }

             

                       
  static String avatarUrl(String url, {int size = 96}) {
    if (url.isEmpty) return '';
    return '${_normalizeUrl(url)}@${size}w_${size}h_1c.webp';
  }

                                                               

  static const String _infoApi =
      'https://api.bilibili.com/x/article/viewinfo';
  static const String _thumbApi =
      'https://api.bilibili.com/x/dynamic/feed/dyn/thumb';
  static const String _favAddApi =
      'https://api.bilibili.com/x/article/favorites/add';
  static const String _favDelApi =
      'https://api.bilibili.com/x/article/favorites/del';

  static String _csrf() {
    final raw = BilibiliAccountService.instance.rawCookie;
    return RegExp(r'(?:^|;\s*)bili_jct=([^;]+)').firstMatch(raw)?.group(1) ?? '';
  }

                               
                                               
                                  
                                  
  static Future<({bool liked, bool fav, int replyCount})?> fetchInteraction({
    required int cvid,
  }) async {
    try {
      final params = await WbiSign.sign({
        'id': cvid.toString(),
        'mobi_app': 'pc',
        'from': 'web',
        'gaia_source': 'main_web',
      });
      final uri = Uri.parse(_infoApi).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _defaultHeaders)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map || json['code'] != 0) return null;
      final data = _asMap(json['data']);
      if (data == null) return null;
      final stats = _asMap(data['stats']);
      return (
        liked: (stats?['like'] ?? 0) == 1,
        fav: data['favorite'] == true,
        replyCount: _toInt(stats?['reply']),
      );
    } catch (e) {
      debugPrint('[Article] viewinfo 拉取失败: $e');
      return null;
    }
  }

                                     
                                     
  static Future<({bool ok, String message})> like({
    required String dynIdStr,
    required bool like,
  }) async {
    final csrf = _csrf();
    if (csrf.isEmpty) {
      return (ok: false, message: '还没有登录，登录后才能点赞');
    }
    if (dynIdStr.isEmpty) {
      return (ok: false, message: '该文章暂不支持点赞');
    }
    return _postForm(
      _thumbApi,
      csrf,
      body: {
        'dyn_id_str': dynIdStr,
        'up': like ? '1' : '2',
        'spmid': '333.1365.0.0',
      },
      referer: 'https://t.bilibili.com/',
    );
  }

                                                             
  static Future<({bool ok, String message})> setFavorite({
    required int cvid,
    required bool fav,
  }) async {
    final csrf = _csrf();
    if (csrf.isEmpty) {
      return (ok: false, message: '还没有登录，登录后才能收藏');
    }
    return _postForm(
      fav ? _favAddApi : _favDelApi,
      csrf,
      body: {'id': cvid.toString()},
      referer: 'https://www.bilibili.com/read/cv$cvid',
    );
  }

                              
  static Future<({bool ok, String message})> _postForm(
    String url,
    String csrf, {
    required Map<String, String> body,
    required String referer,
  }) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: {'csrf': csrf});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            uri,
            headers: {
              ..._defaultHeaders,
              'Content-Type': 'application/x-www-form-urlencoded',
              'Referer': referer,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map) return (ok: false, message: '返回内容不是 JSON');
      if (json['code'] != 0) {
        final msg = '${json['message'] ?? ''}';
        return (ok: false, message: msg.isEmpty ? '接口返回 ${json['code']}' : msg);
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[Article] POST 失败 ($url): $e');
      return (ok: false, message: '网络异常：${e.runtimeType}');
    }
  }
}

                                            
            
                                            

                                  
                                           
                   
class ArticleCache {
  static const String cacheDirName = 'article_cache';

                                             
                                  
                                    
  static bool disabled = false;

                                
  static const Duration ttl = Duration(hours: 24);

                     
  static const int _maxCacheFiles = 200;

                                        
  static Future<Directory> get cacheDir async {
    final appDir = await AppCacheDirs.root();
    final dir = Directory('${appDir.path}/$cacheDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

                        
  static String cacheKey(int cvid) =>
      md5.convert(utf8.encode('$cvid')).toString();

  static Future<File> _cacheFile(int cvid) async {
    final dir = await cacheDir;
    return File('${dir.path}/${cacheKey(cvid)}.json');
  }

                                     
  static Future<void> save(int cvid, Map<String, dynamic> data) async {
    if (disabled) return;
    try {
      final file = await _cacheFile(cvid);
      await file.writeAsString(
        jsonEncode({'ts': DateTime.now().millisecondsSinceEpoch, 'data': data}),
        flush: true,
      );
      await _evictOldEntries();
    } catch (e) {
      debugPrint('[ArticleCache] 写入缓存失败: $e');
    }
  }

                                                 
  static Future<Map<String, dynamic>?> load(
    int cvid, {
    bool allowStale = false,
  }) async {
    if (disabled) return null;
    try {
      final file = await _cacheFile(cvid);
      if (!await file.exists()) return null;
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map<String, dynamic>) return null;
      final ts = (raw['ts'] as num?)?.toInt() ?? 0;
      final data = raw['data'];
      if (data is! Map<String, dynamic>) return null;
      final fresh =
          DateTime.now().millisecondsSinceEpoch - ts < ttl.inMilliseconds;
      if (!fresh && !allowStale) return null;
      return data;
    } catch (e) {
      debugPrint('[ArticleCache] 读取缓存失败: $e');
      return null;
    }
  }

                
  static Future<int> totalSize() async {
    try {
      final dir = await cacheDir;
      if (!await dir.exists()) return 0;
      var total = 0;
      await for (final entity in dir.list()) {
        if (entity is File) {
          total += await entity.length().catchError((_) => 0);
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

             
  static Future<int> count() async {
    try {
      final dir = await cacheDir;
      if (!await dir.exists()) return 0;
      var count = 0;
      await for (final entity in dir.list()) {
        if (entity is File) count++;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

               
  static Future<void> clearAll() async {
    try {
      final dir = await cacheDir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

                                        
  static Future<List<ArticleCacheEntry>> listEntries() async {
    try {
      final dir = await cacheDir;
      if (!await dir.exists()) return const [];
      final entries = <ArticleCacheEntry>[];
      await for (final entity in dir.list()) {
        if (entity is! File || !entity.path.endsWith('.json')) continue;
        try {
          final raw = jsonDecode(await entity.readAsString());
          final data = (raw is Map<String, dynamic>) ? raw['data'] : null;
          if (data is! Map<String, dynamic>) continue;
          var cvid = _toInt(data['id']);
          if (cvid <= 0) {
            cvid =
                int.tryParse(
                  entity.uri.pathSegments.last.replaceAll('.json', ''),
                ) ??
                0;
          }
          var bytes = 0;
          var savedAt = DateTime.fromMillisecondsSinceEpoch(0);
          try {
            bytes = await entity.length();
            savedAt = await entity.lastModified();
          } catch (_) {}
          entries.add(
            ArticleCacheEntry(
              cvid: cvid,
              title: (data['title'] as String?) ?? '',
              bytes: bytes,
              savedAt: savedAt,
            ),
          );
        } catch (_) {}
      }
      entries.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return entries;
    } catch (_) {
      return const [];
    }
  }

               
  static Future<void> deleteOne(int cvid) async {
    try {
      final file = await _cacheFile(cvid);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

                       
  static Future<void> _evictOldEntries() async {
    try {
      final dir = await cacheDir;
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();
      if (files.length <= _maxCacheFiles) return;
      files.sort(
        (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),
      );
      for (final f in files.take(files.length - _maxCacheFiles)) {
        await f.delete();
      }
    } catch (_) {}
  }
}

                                  
class ArticleCacheEntry {
  final int cvid;
  final String title;
  final int bytes;
  final DateTime savedAt;

  const ArticleCacheEntry({
    required this.cvid,
    required this.title,
    required this.bytes,
    required this.savedAt,
  });

  String get url => 'https://www.bilibili.com/read/cv$cvid';
}
