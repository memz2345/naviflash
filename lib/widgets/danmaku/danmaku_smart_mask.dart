                                   
  
                                                   
                                            
                                           
  
                                             
                                                       
                                 
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/onnx_dependency_service.dart';
import 'package:onnxruntime_v2/onnxruntime_v2.dart';

              
class SmartMaskResult {
                                          
  final ui.Image? image;

                         
  final double coverage;

  const SmartMaskResult({this.image, this.coverage = 0});
}

                                             

class _MsgInit {
  final Uint8List modelBytes;

                                             
                                        
  final String runtimePath;
  _MsgInit(this.modelBytes, this.runtimePath);
}

class _MsgInfer {
  final Uint8List rgba;
  final int width, height;
  _MsgInfer(this.rgba, this.width, this.height);
}

class _MsgReady {
  final bool ok;
  final String? error;
  _MsgReady(this.ok, this.error);
}

class _MsgMask {
  final Uint8List rgba;              
  final int width, height;
  final double coverage;
  _MsgMask(this.rgba, this.width, this.height, this.coverage);
}

class _MsgError {
  final String error;
  _MsgError(this.error);
}

class _MsgDispose {}

class _MsgDisposed {}

                                       
                              
class DanmakuSmartMaskService {
  static const int maxConsecutiveErrors = 3;

  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _recvPort;
  Completer<bool>? _starting;
  Completer<SmartMaskResult?>? _pending;
  int _errorCount = 0;
  bool _broken = false;
  bool _depMissing = false;

                                     
  bool get isBroken => _broken;

                                            
  static Future<bool> isDependencyInstalled() async {
    final st = await OnnxDependencyService.state();
    return st == OnnxDepState.installed;
  }

                                     
  bool get isDependencyMissing => _depMissing;

                                  
                                 
  Future<SmartMaskResult?> infer(Uint8List rgba, int width, int height) async {
    if (_broken || width <= 0 || height <= 0) return null;
                                        
    if (_depMissing && OnnxDependencyService.installedCached) {
      _depMissing = false;
    }
    if (_depMissing) return null;
    final started = await _ensureStarted();
    if (!started || _sendPort == null || _broken) return null;
    if (_pending != null) return null;           
    _pending = Completer<SmartMaskResult?>();
    _sendPort!.send(_MsgInfer(rgba, width, height));
    try {
      return await _pending!.future.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      _onError('推理超时');
      return null;
    }
  }

  Future<bool> _ensureStarted() async {
    if (_sendPort != null) return true;
    final existing = _starting;
    if (existing != null) return existing.future;
    final starting = Completer<bool>();
    _starting = starting;
    try {
      final runtimePath = await OnnxDependencyService.runtimeFilePath();
      final modelPath = await OnnxDependencyService.modelPath();
      if (runtimePath == null || modelPath == null) {
                                         
        _depMissing = true;
        starting.complete(false);
        return false;
      }
      final modelBytes = await File(modelPath).readAsBytes();
      final recv = ReceivePort();
      _recvPort = recv;
      _isolate = await Isolate.spawn(_workerEntry, recv.sendPort,
          debugName: 'danmaku-smart-mask');
      SendPort? workerPort;
      var readyDone = false;
      recv.listen((msg) {
        if (msg is SendPort && workerPort == null) {
          workerPort = msg;
          workerPort!.send(_MsgInit(modelBytes, runtimePath));
        } else if (msg is _MsgReady && !readyDone) {
          readyDone = true;
          if (msg.ok) {
            _sendPort = workerPort;
            _errorCount = 0;
            starting.complete(true);
          } else {
            starting.complete(false);
            _markBroken('智能防遮挡模型初始化失败: ${msg.error}');
          }
        } else if (msg is _MsgMask || msg is _MsgError || msg is _MsgDisposed) {
          if (!readyDone) return;                  
          _onMessage(msg);
        }
      });
      return await starting.future.timeout(const Duration(seconds: 20));
    } catch (e) {
      _markBroken('智能防遮挡初始化失败: $e');
      return false;
    } finally {
      _starting = null;
    }
  }

  void _onMessage(dynamic msg) {
    if (msg is _MsgMask) {
      final done = _pending;
      _pending = null;
      _errorCount = 0;
      if (done == null || done.isCompleted) return;
      if (msg.coverage <= 0 || msg.width <= 0 || msg.height <= 0) {
        done.complete(const SmartMaskResult(image: null, coverage: 0));
        return;
      }
      ui.decodeImageFromPixels(
        msg.rgba,
        msg.width,
        msg.height,
        ui.PixelFormat.rgba8888,
        (image) => done.isCompleted
            ? image.dispose()
            : done.complete(
                SmartMaskResult(image: image, coverage: msg.coverage)),
      );
    } else if (msg is _MsgError) {
      _onError(msg.error);
    } else if (msg is _MsgDisposed) {
      _isolate?.kill();
      _isolate = null;
      _sendPort = null;
      _recvPort?.close();
      _recvPort = null;
    }
  }

  void _onError(String error) {
    _errorCount++;
    debugPrint('[SmartMask] $error ($_errorCount/$maxConsecutiveErrors)');
    final done = _pending;
    _pending = null;
    if (done != null && !done.isCompleted) done.complete(null);
    if (_errorCount >= maxConsecutiveErrors) {
      _markBroken('智能防遮挡连续失败 $maxConsecutiveErrors 次，已停用');
    }
  }

  void _markBroken(String reason) {
    if (_broken) return;
    _broken = true;
    debugPrint('[SmartMask] $reason');
  }

  Future<void> dispose() async {
    final port = _sendPort;
    if (port != null && _isolate != null) {
      port.send(_MsgDispose());
                                             
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
    _recvPort?.close();
    _recvPort = null;
    _pending = null;
    _starting = null;
  }
}

                   

const int _inputSize = 320;               
const int _maskW = 160, _maskH = 90;                           

void _workerEntry(SendPort send) {
  final recv = ReceivePort();
  send.send(recv.sendPort);

  OrtSession? session;
  OrtSessionOptions? options;
  OrtRunOptions? runOptions;
  String inputName = '';
  Float32List? smooth;             

                  
  const mean = [0.485, 0.456, 0.406];
  const std = [0.229, 0.224, 0.225];

  void cleanup() {
    runOptions?.release();
    options?.release();
    session?.release();
    session = null;
    options = null;
    runOptions = null;
  }

  recv.listen((msg) {
    if (msg is _MsgInit) {
      try {
                                        
        OrtLibrary.path = msg.runtimePath;
        OrtEnv.instance.init();
        options = OrtSessionOptions()
          ..setIntraOpNumThreads(Platform.numberOfProcessors >= 8 ? 4 : 2);
        session = OrtSession.fromBuffer(msg.modelBytes, options!);
        inputName = session!.inputNames.first;
        runOptions = OrtRunOptions();
        send.send(_MsgReady(true, null));
      } catch (e) {
        cleanup();
        send.send(_MsgReady(false, e.toString()));
      }
    } else if (msg is _MsgInfer && session != null) {
      try {
        final plane = _preprocess(msg.rgba, msg.width, msg.height, mean, std);
        final input = OrtValueTensor.createTensorWithDataList(
            plane, [1, 3, _inputSize, _inputSize]);
        final outputs = session!.run(runOptions!, {inputName: input});
        final out0 = outputs.first as OrtValueTensor?;
        final value = out0?.value as List?;
        input.release();
        for (final o in outputs) {
          o?.release();
        }
        if (value == null) throw StateError('空输出');
                                  
        final rows = value[0][0] as List;
        const n = _inputSize;
        final prev = smooth;
        final cur = Float32List(n * n);
        for (int y = 0; y < n; y++) {
          final row = rows[y] as List;
          final o = y * n;
          for (int x = 0; x < n; x++) {
            final d = row[x] as double;
            cur[o + x] = prev == null ? d : 0.55 * prev[o + x] + 0.45 * d;
          }
        }
        smooth = cur;
        send.send(_postprocess(cur));
      } catch (e) {
        send.send(_MsgError(e.toString()));
      }
    } else if (msg is _MsgDispose) {
      cleanup();
      send.send(_MsgDisposed());
      recv.close();
    }
  });
}

                                        
Float32List _preprocess(
    Uint8List rgba, int w, int h, List<double> mean, List<double> std) {
  const n = _inputSize;
  final out = Float32List(3 * n * n);
  const plane = n * n;
  for (int y = 0; y < n; y++) {
    final fy = (y + 0.5) * h / n - 0.5;
    int y0 = fy.floor();
    if (y0 < 0) y0 = 0;
    if (y0 > h - 1) y0 = h - 1;
    int y1 = y0 + 1;
    if (y1 > h - 1) y1 = h - 1;
    final wy = (fy - y0).clamp(0.0, 1.0);
    final row0 = y0 * w, row1 = y1 * w;
    for (int x = 0; x < n; x++) {
      final fx = (x + 0.5) * w / n - 0.5;
      int x0 = fx.floor();
      if (x0 < 0) x0 = 0;
      if (x0 > w - 1) x0 = w - 1;
      int x1 = x0 + 1;
      if (x1 > w - 1) x1 = w - 1;
      final wx = (fx - x0).clamp(0.0, 1.0);
      final i00 = (row0 + x0) * 4, i01 = (row0 + x1) * 4;
      final i10 = (row1 + x0) * 4, i11 = (row1 + x1) * 4;
      final dst = y * n + x;
      final w00 = (1 - wx) * (1 - wy), w01 = wx * (1 - wy);
      final w10 = (1 - wx) * wy, w11 = wx * wy;
      for (int c = 0; c < 3; c++) {
        final v = (rgba[i00 + c] * w00 +
                rgba[i01 + c] * w01 +
                rgba[i10 + c] * w10 +
                rgba[i11 + c] * w11) /
            255.0;
        out[c * plane + dst] = (v - mean[c]) / std[c];
      }
    }
  }
  return out;
}

                                             
_MsgMask _postprocess(Float32List prob) {
  const n = _inputSize;
  final alpha = Uint8List(_maskW * _maskH);
  int hit = 0;
  for (int my = 0; my < _maskH; my++) {
    final sy = my * n ~/ _maskH;
    for (int mx = 0; mx < _maskW; mx++) {
      final sx = mx * n ~/ _maskW;
      final v = prob[sy * n + sx];
                                                    
      final a = ((v - 0.32) / 0.20).clamp(0.0, 1.0);
      if (a > 0.5) hit++;
      alpha[my * _maskW + mx] = (a * 255).round();
    }
  }
                                    
  _dilate3x3(alpha, _maskW, _maskH);
  final out = Uint8List(_maskW * _maskH * 4);
  for (int i = 0; i < alpha.length; i++) {
    out[i * 4 + 3] = alpha[i];
  }
  return _MsgMask(out, _maskW, _maskH, hit / (_maskW * _maskH));
}

void _dilate3x3(Uint8List a, int w, int h) {
  final t = Uint8List(w * h);
  for (int y = 0; y < h; y++) {
    final o = y * w;
    for (int x = 0; x < w; x++) {
      var m = a[o + x];
      if (x > 0 && a[o + x - 1] > m) m = a[o + x - 1];
      if (x + 1 < w && a[o + x + 1] > m) m = a[o + x + 1];
      t[o + x] = m;
    }
  }
  for (int x = 0; x < w; x++) {
    for (int y = 0; y < h; y++) {
      var m = t[y * w + x];
      if (y > 0 && t[(y - 1) * w + x] > m) m = t[(y - 1) * w + x];
      if (y + 1 < h && t[(y + 1) * w + x] > m) m = t[(y + 1) * w + x];
      a[y * w + x] = m;
    }
  }
}
