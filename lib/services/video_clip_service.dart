                                       
            
                                                            
                                             
                                                            
                                                                 
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:media_kit/media_kit.dart' show NativePlayer, Player;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:naviflash/services/mpv_transcoder.dart';

abstract final class VideoClipService {
                               
  static const List<String> mp4Codecs = ['libx264', 'libopenh264', 'mpeg4'];
                                    
     
                                             
                                             
  static Future<Uint8List?> captureGif({
    required Player player,
    required double startSec,
    required double endSec,
    double fps = 10,
    int width = 480,
    void Function(double progress)? onProgress,
  }) async {
    final platform = player.platform;
    if (platform is! NativePlayer) return null;
    if (endSec - startSec < 0.2 || fps <= 0) return null;

    final wasPlaying = player.state.playing;
    final prevPos = player.state.position;
    final tmp = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final frames = <img.Image>[];

    final total = ((endSec - startSec) * fps).round().clamp(1, 150);
    try {
      await player.pause();
      for (var i = 0; i < total; i++) {
        final t = startSec + i / fps;
        await _seekAndWait(player, t);
        final path = p.join(tmp.path, 'navi_clip_${stamp}_$i.png');
        final file = File(path);
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (_) {}
        }
        try {
          await platform.command(['screenshot-to-file', path, 'video']);
        } catch (e) {
          if (kDebugMode) debugPrint('[Clip] screenshot 命令失败: $e');
        }
                            
        if (await _waitFile(file, timeoutMs: 2500)) {
          final bytes = await file.readAsBytes();
          var frame = img.decodePng(bytes);
          if (frame != null) {
            if (frame.width > width) {
              frame = img.copyResize(frame, width: width, interpolation: img.Interpolation.average);
            }
            frames.add(frame);
          }
          try {
            file.deleteSync();
          } catch (_) {}
        }
        onProgress?.call(0.9 * (i + 1) / total);
      }
    } finally {
                          
      try {
        await player.seek(prevPos);
        if (wasPlaying) await player.play();
      } catch (_) {}
    }

    if (frames.isEmpty) return null;
    onProgress?.call(0.92);
    final durationCs = (100 / fps).round().clamp(2, 100);
    final encoder = img.GifEncoder(numColors: 256);
    for (final f in frames) {
      encoder.addFrame(f, duration: durationCs);
    }
    final bytes = encoder.finish();
    onProgress?.call(1.0);
    return bytes;
  }

                                                  
                           
  static Future<String?> transcodeMp4({
    required Player player,
    required String url,
    required String outFile,
    required double startSec,
    required double endSec,
    Map<String, String>? headers,
    void Function(double progress)? onProgress,
  }) async {
    final platform = player.platform;
    if (platform is! NativePlayer) return null;
    if (endSec - startSec < 0.2) return null;
    final transcoder = MpvTranscoder(
      platform: platform,
      url: url,
      outFile: outFile,
      start: startSec,
      end: endSec,
      httpHeaders: headers,
      onProgress: onProgress,
    );
    final ok = await transcoder.run(mp4Codecs);
    return ok ? outFile : null;
  }

                                      
                         
  static Future<Uint8List?> captureCoverJpeg({
    required Player player,
    required double atSec,
  }) async {
    final platform = player.platform;
    if (platform is! NativePlayer) return null;
    final tmp = await getTemporaryDirectory();
    final path = p.join(
      tmp.path,
      'navi_cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final file = File(path);
    try {
      if (file.existsSync()) file.deleteSync();
      await _seekAndWait(player, atSec);
      await platform.command(['screenshot-to-file', path, 'video']);
      if (await _waitFile(file, timeoutMs: 2500)) {
        final bytes = await file.readAsBytes();
        return bytes.isEmpty ? null : bytes;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Clip] 抓取封面失败: $e');
    } finally {
      try {
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }
    return null;
  }

                                 
  static Future<void> _seekAndWait(Player player, double targetSec) async {    final target = Duration(milliseconds: (targetSec * 1000).round());
    try {
      await player.seek(target);
    } catch (_) {
      return;
    }
    final deadline = DateTime.now().add(const Duration(milliseconds: 1800));
    while (DateTime.now().isBefore(deadline)) {
      final posMs = player.state.position.inMilliseconds;
      if ((posMs - target.inMilliseconds).abs() < 350) {
                              
        await Future.delayed(const Duration(milliseconds: 90));
        return;
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  static Future<bool> _waitFile(File file, {required int timeoutMs}) async {
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (DateTime.now().isBefore(deadline)) {
      if (file.existsSync() && file.lengthSync() > 0) return true;
      await Future.delayed(const Duration(milliseconds: 60));
    }
    return file.existsSync() && file.lengthSync() > 0;
  }
}
