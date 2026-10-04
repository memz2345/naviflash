                                          
  
                                        
                                        
  
                                   
                               
import 'dart:io';

import 'package:naviflash/services/bilibili_article_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/image_cache_service.dart';
import 'package:naviflash/services/manual_video_cache.dart';
import 'package:naviflash/services/onnx_dependency_service.dart';
import 'package:naviflash/services/tts_model_service.dart';
import 'package:naviflash/services/video_cache_service.dart';
import 'package:naviflash/widgets/danmaku/danmaku_fetcher.dart';

                      
enum StorageCategory {
                           
  offlineVideo,

                        
  image,

          
  danmaku,

                               
  data,

                                                           
  ai,
}

class StorageUsageService {
  StorageUsageService._();

                              
  static Future<Map<StorageCategory, int>> load() async {
    final video = await _guard(ManualVideoCache.totalAllSize());
    final image = await _guard(ImageCacheService.totalSize());
    final danmaku = await _guard(_danmakuBytes());
    final videoJson = await _guard(VideoJsonCache.totalSize());
    final article = await _guard(_dirBytes(await ArticleCache.cacheDir));
    final dynamicDetail = await _guard(
      _dirBytes(await DynamicDetailCache.cacheDir),
    );
    final onnx = await _guard(OnnxDependencyService.installedBytes());
    final tts = await _guard(TtsModelService.installedBytes());

    return <StorageCategory, int>{
      StorageCategory.offlineVideo: video,
      StorageCategory.image: image,
      StorageCategory.danmaku: danmaku,
      StorageCategory.data: videoJson + article + dynamicDetail,
      StorageCategory.ai: onnx + tts,
    };
  }

                                 
  static Future<int> dirBytes(Directory dir) => _dirBytes(dir);

  static Future<int> _danmakuBytes() async {
    var total = 0;
    for (final f in await DanmakuCacheManager.listCachedFiles()) {
      total += await f.length().catchError((_) => 0);
    }
    return total;
  }

  static Future<int> _dirBytes(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          total += await entity.length().catchError((_) => 0);
        }
      }
    } catch (_) {
                              
    }
    return total;
  }

                                       
  static Future<int> _guard(Future<int> future) async {
    try {
      final v = await future;
      return v > 0 ? v : 0;
    } catch (_) {
      return 0;
    }
  }
}
