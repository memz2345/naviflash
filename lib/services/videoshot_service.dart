                                      
                                                  
                                       
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/network_settings_service.dart';

                               
class VideoShotData {
               
  final int imgXLen;

               
  final int imgYLen;

                                    
  double imgXSize;

          
  double imgYSize;

                                         
  final List<String> image;

                     
  final List<int> index;

  VideoShotData({
    required this.imgXLen,
    required this.imgYLen,
    required this.imgXSize,
    required this.imgYSize,
    required this.image,
    required this.index,
  });

  int get totalPerImage => imgXLen * imgYLen;

  factory VideoShotData.fromJson(Map<String, dynamic> json) {
    final images = (json['image'] as List?)
            ?.map((e) => _fixUrl(e.toString()))
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];
    final idx = (json['index'] as List?)
            ?.map((e) => e is num ? e.toInt() : int.tryParse('$e') ?? 0)
            .toList() ??
        const <int>[];
    return VideoShotData(
      imgXLen: (json['img_x_len'] as num?)?.toInt() ?? 10,
      imgYLen: (json['img_y_len'] as num?)?.toInt() ?? 10,
      imgXSize: (json['img_x_size'] as num?)?.toDouble() ?? 0,
      imgYSize: (json['img_y_size'] as num?)?.toDouble() ?? 0,
      image: images,
      index: idx,
    );
  }

  static String _fixUrl(String url) {
    final t = url.trim();
    if (t.isEmpty) return '';
    if (t.startsWith('http://')) return t.replaceFirst('http://', 'https://');
    if (t.startsWith('//')) return 'https:$t';
    return t;
  }
}

abstract final class VideoshotService {
  static const String _api = 'https://api.bilibili.com/x/player/videoshot';

  static const String _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

                                               
  static Future<VideoShotData?> fetch({
    required String bvid,
    required int cid,
  }) async {
    final bv = bvid.trim();
    if (bv.isEmpty || cid <= 0) return null;
    try {
      final uri = Uri.parse(_api).replace(
        queryParameters: {'bvid': bv, 'cid': '$cid', 'index': '1'},
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            uri,
            headers: {
              'User-Agent': _ua,
              'Referer': 'https://www.bilibili.com/video/$bv',
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> || json['code'] != 0) return null;
      final data = json['data'];
      if (data is! Map<String, dynamic>) return null;
      final shot = VideoShotData.fromJson(data);
      if (shot.image.isEmpty || shot.index.isEmpty) return null;
      return shot;
    } catch (e) {
      if (kDebugMode) debugPrint('[VideoShot] 拉取缩略图失败: $e');
      return null;
    }
  }
}
