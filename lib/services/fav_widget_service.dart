                                       
  
                                      
                                                        
            
  
               
                                             
                                            
                           
  
                                         
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:naviflash/services/bilibili_favorite_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract final class FavWidgetService {
  static const MethodChannel _channel =
      MethodChannel('com.memz2345.navi.flash/home_widget');

                                              
  static const int maxItems = 4;

                                                   
                                             
                  
  static const int _coverW = 336;
  static const int _coverH = 189;

  static const String _referer = 'https://www.bilibili.com/';
  static const String _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

                                   
  static Future<void>? _inflight;

                                       
  static DateTime? _lastRefreshAt;

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

                                
  static Future<bool> hasWidgets() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('hasWidgets') ?? false;
    } catch (e) {
      debugPrint('[FavWidget] 查询小组件失败: $e');
      return false;
    }
  }

                        
     
                                        
  static Future<void> refresh() {
    final running = _inflight;
    if (running != null) return running;
    final task = _refresh();
    _inflight = task;
    return task.whenComplete(() => _inflight = null);
  }

                                     
                                      
  static Future<void> refreshNow() async {
    final running = _inflight;
    if (running != null) await running;
    await refresh();
  }

                                           
                                       
  static Future<void> refreshIfStale({
    Duration minInterval = const Duration(minutes: 5),
  }) {
    final last = _lastRefreshAt;
    if (last != null && DateTime.now().difference(last) < minInterval) {
      return Future<void>.value();
    }
    return refresh();
  }

  static Future<void> _refresh() async {
    if (!isSupported) return;
    try {
      if (!await hasWidgets()) {
        debugPrint('[FavWidget] 桌面未放置小组件，跳过刷新');
        return;
      }
      if (!BilibiliFavoriteService.isLoggedIn) {
        debugPrint('[FavWidget] 未登录，跳过刷新');
        return;
      }

      final folders = await BilibiliFavoriteService.fetchFolders();
      if (folders == null || folders.isEmpty) {
        debugPrint('[FavWidget] 没拿到收藏夹: ${BilibiliFavoriteService.lastErrorDetail}');
        return;
      }
                                            
                      
      final wantedId = SettingsService.favWidgetFolderIdStatic;
      var folder = folders.first;
      if (wantedId != 0) {
        final idx = folders.indexWhere((f) => f.id == wantedId);
        if (idx >= 0) {
          folder = folders[idx];
        } else {
          debugPrint('[FavWidget] 选中的收藏夹 $wantedId 已不存在，回退第一个');
        }
      }

      final page = await BilibiliFavoriteService.fetchFolderVideos(
        mediaId: folder.id,
        ps: maxItems,
        order: 'mtime',          
      );
                                          
      if (page == null) {
        debugPrint('[FavWidget] 拉取失败: ${BilibiliFavoriteService.lastErrorDetail}');
        return;
      }
                                         
      final videos = page.videos;

      final dir = await _cacheDir();
      final items = <Map<String, Object?>>[];
      final keep = <String>{};

      for (final v in videos.take(maxItems)) {
        final key = _fileKey(v);
        keep.add(key);
        final file = File(p.join(dir.path, '$key.jpg'));
        final coverUrl = _sizedCover(v.cover);
        if (coverUrl.isNotEmpty) {
                                        
          if (!file.existsSync() || await file.length() < 1024) {
            final bytes = await _download(coverUrl);
            if (bytes != null && bytes.isNotEmpty) {
              await file.writeAsBytes(bytes, flush: true);
            }
          }
        }
        items.add(<String, Object?>{
          'title': v.title,
          'coverPath': file.existsSync() ? file.path : null,
          'bvid': v.bvid.isEmpty ? null : v.bvid,
        });
      }

                              
      await _pruneCovers(dir, keep);

      final ok = await _channel.invokeMethod<bool>('updateFavWidget', {
        'folderTitle': folder.title,
        'coverCacheDir': dir.path,
        'items': items,
      });
      _lastRefreshAt = DateTime.now();
      debugPrint('[FavWidget] 已推送 ${items.length} 条（${folder.title}）ok=$ok');
    } catch (e) {
      debugPrint('[FavWidget] 刷新失败: $e');
    }
  }

                              
  static Future<Directory> _cacheDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'fav_widget'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

                              
  static String _fileKey(BiliFavVideo v) {
    if (v.bvid.isNotEmpty) {
      return v.bvid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
    }
    return 'av${v.aid}';
  }

                                    
  static String _sizedCover(String url) {
    if (url.isEmpty || url.contains('@')) return url;
    return '$url@${_coverW}w_${_coverH}h_1c.jpg';
  }

  static Future<Uint8List?> _download(String url) async {
    try {
      final resp = await http
          .get(Uri.parse(url), headers: {'User-Agent': _ua, 'Referer': _referer})
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        debugPrint('[FavWidget] 封面下载失败 HTTP ${resp.statusCode}: $url');
        return null;
      }
      return resp.bodyBytes;
    } catch (e) {
      debugPrint('[FavWidget] 封面下载异常: $e');
      return null;
    }
  }

                       
  static Future<void> _pruneCovers(Directory dir, Set<String> keep) async {
    try {
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = p.basenameWithoutExtension(entity.path);
        if (keep.contains(name)) continue;
        await entity.delete().catchError((_) => entity);
      }
    } catch (e) {
      debugPrint('[FavWidget] 清理旧封面失败: $e');
    }
  }
}
