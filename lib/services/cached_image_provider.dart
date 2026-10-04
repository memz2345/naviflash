                                          
  
                                                    
                                                        
                                                    
                                                    
                                          
  
                                                              
  
                                                  
                                                 
                                       
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:naviflash/services/image_cache_service.dart';

class CachedImageProvider extends ImageProvider<CachedImageProvider> {
  final String url;
  final Map<String, String>? headers;
  final double scale;

                                    
  final int? cacheWidth;

                                               
  final int? cacheHeight;

  const CachedImageProvider(
    this.url, {
    this.headers,
    this.scale = 1.0,
    this.cacheWidth,
    this.cacheHeight,
  });

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
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    if (key.cacheWidth == null && key.cacheHeight == null) {
      return decode(buffer);
    }
    return decode(
      buffer,
      getTargetSize: (int intrinsicWidth, int intrinsicHeight) {
        return _fitTargetSize(
          intrinsicWidth,
          intrinsicHeight,
          key.cacheWidth,
          key.cacheHeight,
        );
      },
    );
  }

                                       
  ui.TargetImageSize _fitTargetSize(
    int intrinsicWidth,
    int intrinsicHeight,
    int? maxWidth,
    int? maxHeight,
  ) {
    if (maxWidth == null && maxHeight == null) {
      return ui.TargetImageSize(width: intrinsicWidth, height: intrinsicHeight);
    }
    final double ratio = math.max(
      maxWidth == null ? 1.0 : intrinsicWidth / maxWidth,
      maxHeight == null ? 1.0 : intrinsicHeight / maxHeight,
    );
    if (ratio <= 1.0) {
      return ui.TargetImageSize(width: intrinsicWidth, height: intrinsicHeight);
    }
    return ui.TargetImageSize(
      width: (intrinsicWidth / ratio).round(),
      height: (intrinsicHeight / ratio).round(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is CachedImageProvider &&
        other.url == url &&
        other.scale == scale &&
        other.cacheWidth == cacheWidth &&
        other.cacheHeight == cacheHeight;
  }

  @override
  int get hashCode => Object.hash(url, scale, cacheWidth, cacheHeight);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'CachedImageProvider')}("$url", '
      'scale: ${scale.toStringAsFixed(1)})';
}
