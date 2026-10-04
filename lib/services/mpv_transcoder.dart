                                   
                                         
                                                       
                                      
// ignore_for_file: implementation_imports
import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:media_kit/ffi/src/allocation.dart';
import 'package:media_kit/ffi/src/utf8.dart';
import 'package:media_kit/generated/libmpv/bindings.dart' as generated;
import 'package:media_kit/media_kit.dart' show NativePlayer;
import 'package:media_kit/src/player/native/core/initializer.dart';

class MpvTranscoder {
  final NativePlayer _platform;
  final String url;
  final String outFile;
  final double start;
  final double end;
  final Map<String, String>? httpHeaders;
  final void Function(double progress)? onProgress;

  Pointer<generated.mpv_handle>? _ctx;
  Completer<bool> _completer = Completer<bool>();
  Timer? _timeout;
  bool _success = false;
  bool _finished = false;

                                
     
                                            
                                
                                         
  static Future<void>? _pendingDestroy;

  MpvTranscoder({
    required NativePlayer platform,
    required this.url,
    required this.outFile,
    required this.start,
    required this.end,
    this.httpHeaders,
    this.onProgress,
  }) : _platform = platform;

                                         
  Future<bool> run(List<String> codecs) async {
    if (end <= start) return false;
    for (final codec in codecs) {
                                         
                                                       
      final pending = _pendingDestroy;
      if (pending != null) {
        await pending;
      }
      final ok = await _runOnce(codec);
      if (ok) return true;
                      
      try {
        final f = File(outFile);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
    return false;
  }

                    
  void cancel() => _finish(false);

  Future<bool> _runOnce(String codec) async {
    _success = false;
    _finished = false;
    _completer = Completer<bool>();
    final mpv = _platform.mpv;
    try {
      final ctx = await Initializer(mpv).create(
        _onEvent,
        options: {
          'idle': 'once',
          'o': outFile,
          'start': start.toStringAsFixed(3),
          'end': end.toStringAsFixed(3),
          'of': 'mp4',
          'ovc': codec,
          'ovcopts': 'preset=veryfast,crf=23',
                                 
          'aid': 'no',
          'osd-level': '0',
                                 
          'vf': 'format=yuv420p',
        },
      );
      _ctx = ctx;
                                         
      final headers = httpHeaders;
      if (headers != null && headers.isNotEmpty) {
        final parts = <String>[];
        headers.forEach((k, v) {
          final value = v.trim();
          if (value.isEmpty) return;
          parts.add('$k: ${value.replaceAll(',', r'\,')}');
        });
        if (parts.isNotEmpty) {
          _setPropertyString(ctx, 'http-header-fields', parts.join(','));
        }
      }
      mpv.mpv_request_event(
        ctx,
        generated.mpv_event_id.MPV_EVENT_SHUTDOWN,
        1,
      );
      mpv.mpv_request_event(
        ctx,
        generated.mpv_event_id.MPV_EVENT_END_FILE,
        1,
      );
      _observeProperty(ctx, 'time-pos');
      final level = (kDebugMode ? 'info' : 'error').toNativeUtf8();
      mpv.mpv_request_log_messages(ctx, level.cast());
      calloc.free(level);

      _command(ctx, ['loadfile', url]);

                                 
      final guardMs = ((end - start) * 4000).round() + 30000;
      _timeout = Timer(Duration(milliseconds: guardMs), () {
        if (kDebugMode) debugPrint('[Transcode] $codec 超时');
        _finish(false);
      });
      return await _completer.future;
    } catch (e) {
      debugPrint('[Transcode] $codec 启动失败: $e');
      _finish(false);
      return false;
    }
  }

  Future<void> _onEvent(Pointer<generated.mpv_event> event) async {
    switch (event.ref.event_id) {
      case generated.mpv_event_id.MPV_EVENT_PROPERTY_CHANGE:
        try {
          final prop = event.ref.data
              .cast<generated.mpv_event_property>()
              .ref;
          if (prop.name.cast<Utf8>().toDartString() == 'time-pos' &&
              prop.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
            final pos = prop.data.cast<Double>().value;
            final total = end - start;
            if (total > 0) {
              onProgress?.call(((pos - start) / total).clamp(0.0, 1.0));
            }
          }
        } catch (_) {}
        break;
      case generated.mpv_event_id.MPV_EVENT_FILE_LOADED:
        _success = true;
        break;
      case generated.mpv_event_id.MPV_EVENT_LOG_MESSAGE:
        try {
          final log = event.ref.data
              .cast<generated.mpv_event_log_message>()
              .ref;
          final level = log.level.cast<Utf8>().toDartString().trim();
          if (kDebugMode) {
            debugPrint(
              '[Transcode] $level '
              '${log.prefix.cast<Utf8>().toDartString().trim()}: '
              '${log.text.cast<Utf8>().toDartString().trim()}',
            );
          }
          if (level == 'error' || level == 'fatal') _success = false;
        } catch (_) {}
        break;
      case generated.mpv_event_id.MPV_EVENT_SHUTDOWN:
        onProgress?.call(1.0);
        _finish(_success);
        break;
      default:
        break;
    }
  }

  void _finish(bool success) {
    if (_finished) return;
    _finished = true;
    _timeout?.cancel();
    _timeout = null;
    _disposeCtx();
    var ok = success;
    try {
      final f = File(outFile);
      ok = ok && f.existsSync() && f.lengthSync() > 1024;
    } catch (_) {
      ok = false;
    }
    if (!_completer.isCompleted) _completer.complete(ok);
  }

  void _disposeCtx() {
    final ctx = _ctx;
    if (ctx == null) return;
    _ctx = null;
    try {
      final mpv = _platform.mpv;
                                                     
                        
      Initializer(mpv).dispose(ctx);
                                                             
                                                         
                                                    
                                         
                                    
                                                         
      _pendingDestroy = Future<void>.delayed(const Duration(seconds: 2), () {
        mpv.mpv_terminate_destroy(ctx);
      });
    } catch (e) {
      debugPrint('[Transcode] 释放转码实例失败: $e');
    }
  }

  void _command(Pointer<generated.mpv_handle> ctx, List<String> args) {
    final pointers = args.map((e) => e.toNativeUtf8()).toList();
    final arr = calloc<Pointer<Int8>>(pointers.length + 1);
    for (var i = 0; i < args.length; i++) {
      arr[i] = pointers[i].cast<Int8>();
    }
    _platform.mpv.mpv_command(ctx, arr);
    calloc.free(arr);
    pointers.forEach(calloc.free);
  }

  void _setPropertyString(
    Pointer<generated.mpv_handle> ctx,
    String name,
    String value,
  ) {
    final n = name.toNativeUtf8();
    final v = value.toNativeUtf8();
    _platform.mpv.mpv_set_property_string(ctx, n.cast(), v.cast());
    calloc.free(n);
    calloc.free(v);
  }

  void _observeProperty(
    Pointer<generated.mpv_handle> ctx,
    String property,
  ) {
    final name = property.toNativeUtf8();
    _platform.mpv.mpv_observe_property(
      ctx,
      property.hashCode,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_DOUBLE,
    );
    calloc.free(name);
  }
}
