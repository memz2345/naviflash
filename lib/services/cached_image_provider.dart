// lib/services/cached_image_provider.dart
//
// 本项目用自建 ImageCacheService 实现同款「内存 → 磁盘 → 网络」三级缓存）：
//   - 身份 key 仅由 URL 决定（==/hashCode 不含 headers），因此长列表滚动、
//     页面重建、布局切换时复用同一个 Flutter ImageCache 条目，不再重复下载；
//   - 未命中内存时走 ImageCacheService.fetch：磁盘命中直接读文件，否则才
//     发起网络请求并落盘，之后所有地方（缩略图/大图/头像/表情）共享缓存。
//
// 用法：Image(image: CachedImageProvider(url, headers: headers))
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:naviflash/services/image_cache_service.dart';

class CachedImageProvider extends ImageProvider<CachedImageProvider> {
  final String url;
  final Map<String, String>? headers;
  final double scale;

  const CachedImageProvider(this.url, {this.headers, this.scale = 1.0});

  @override
  Future<CachedImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<CachedImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    CachedImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<CachedImageProvider>('Image provider', this),
        DiagnosticsProperty<String>('URL', url),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    CachedImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    assert(key == this);
    final bytes = await ImageCacheService.fetch(url, headers: headers);
    if (bytes == null || bytes.isEmpty) {
      throw Exception('图片加载失败: $url');
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is CachedImageProvider &&
        other.url == url &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'CachedImageProvider')}("$url", '
      'scale: ${scale.toStringAsFixed(1)})';
}
