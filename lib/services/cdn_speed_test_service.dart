                                           
                                                
                            
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

             
class CdnSpeedResult {
  final String label;
  final String url;

                       
  final double bytesPerSec;
  final String? error;

  const CdnSpeedResult({
    required this.label,
    required this.url,
    required this.bytesPerSec,
    this.error,
  });

  bool get ok => bytesPerSec > 0;

              
  String get speedText {
    if (!ok) return error ?? '失败';
    if (bytesPerSec >= 1024 * 1024) {
      return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    }
    return '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
  }
}

abstract final class CdnSpeedTestService {
                        
  static const int maxBytes = 2 * 1024 * 1024;

               
  static const Duration maxDuration = Duration(seconds: 6);

                         
  static const Map<String, String> _baseHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

                                                  
  static Future<CdnSpeedResult> test(
    String label,
    String url, {
    Map<String, String>? headers,
  }) async {
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(url))
        ..headers.addAll({
          ..._baseHeaders,
          ...?headers,
                                            
        });
      final resp = await client
          .send(req)
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode >= 400) {
        client.close();
        return CdnSpeedResult(
          label: label,
          url: url,
          bytesPerSec: 0,
          error: 'HTTP ${resp.statusCode}',
        );
      }
      var received = 0;
      final sw = Stopwatch()..start();
      final completer = Completer<void>();
      late StreamSubscription<List<int>> sub;
      sub = resp.stream.listen(
        (chunk) {
          received += chunk.length;
          if (received >= maxBytes || sw.elapsed >= maxDuration) {
            sub.cancel();
            if (!completer.isCompleted) completer.complete();
          }
        },
        onError: (Object e) {
          if (!completer.isCompleted) completer.complete();
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );
      await completer.future.timeout(
        maxDuration + const Duration(seconds: 2),
        onTimeout: () => sub.cancel(),
      );
      sw.stop();
      client.close();

      if (received <= 0 || sw.elapsedMilliseconds <= 0) {
        return CdnSpeedResult(
          label: label,
          url: url,
          bytesPerSec: 0,
          error: received <= 0 ? '无数据' : '超时',
        );
      }
      final speed = received / (sw.elapsedMicroseconds / 1000000.0);
      return CdnSpeedResult(label: label, url: url, bytesPerSec: speed);
    } catch (e) {
      client.close();
      if (kDebugMode) debugPrint('[CDN测速] $label 失败: $e');
      return CdnSpeedResult(
        label: label,
        url: url,
        bytesPerSec: 0,
        error: '连接失败',
      );
    }
  }
}
