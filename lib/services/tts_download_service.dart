                                         
  
                                          
  
                                                           
                                              
              
                                           
                                   
                                                            
                                                                
                                           
                             
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n_helper.dart';
import 'model_download_service.dart';
import 'notification_service.dart';
import 'tts_live_update.dart';
import 'tts_model_service.dart';

class TtsDownloadService extends ChangeNotifier {
  TtsDownloadService._();

  static final TtsDownloadService instance = TtsDownloadService._();

                                   
  static const String _prefInFlight = 'ttsDownloadInFlight';

                          
  static bool _nativeBound = false;

  bool _running = false;
  bool _cancelRequested = false;
  int _received = 0;
  int _total = 0;
  String _currentFile = '';
  String? _error;
  bool _justFinished = false;

                                
  @visibleForTesting
  static Future<void> Function({
    void Function(int received, int total, String currentName)? onProgress,
    bool Function()? shouldCancel,
  })?
  debugInstaller;

  bool get isRunning => _running;

                             
  bool get justFinished => _justFinished;

  int get received => _received;
  int get total => _total;

                          
  String get currentFile => _currentFile;

                               
  String? get error => _error;

                       
  double? get progress =>
      _total > 0 ? (_received / _total).clamp(0.0, 1.0) : null;

            
                                      
                                               
                       
  Future<void> initialize() async {
    try {
                                        
                             
      if (ModelDownloadService.supported) {
                                                  
        ModelDownloadService.attach();
        _bindNativeCallbacks();
        final st = await ModelDownloadService.status();
        if (st != null && st.running) {
          debugPrint('[TtsDownload] 原生后台下载仍在跑，接回进度');
          _running = true;
          _received = st.received;
          _total = st.total;
          _currentFile = st.name;
          _cancelRequested = false;
          _error = null;
          notifyListeners();
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final inFlight = prefs.getBool(_prefInFlight) == true;
      if (inFlight && await TtsModelService.state() != TtsModelState.installed) {
        debugPrint('[TtsDownload] 检测到上次下载被中断，自动续传');
        unawaited(start());
        return;
      }
      if (inFlight) await prefs.setBool(_prefInFlight, false);
                        
      unawaited(TtsModelService.cleanupOrphans().then((freed) {
        if (freed > 0) {
          debugPrint(
            '[TtsDownload] 启动清理无用断点 ${(freed / 1024 / 1024).round()}MB',
          );
        }
      }));
    } catch (e) {
      debugPrint('[TtsDownload] 初始化失败: $e');
    }
  }

                             
  Future<void> start() async {
    if (_running) return;
    if (await TtsModelService.state() == TtsModelState.installed) return;

    _running = true;
    _cancelRequested = false;
    _error = null;
    _justFinished = false;
    await _setInFlight(true);
    notifyListeners();

                                 
                                                 
    if (ModelDownloadService.supported) {
      _bindNativeCallbacks();
      await TtsModelService.cleanupOrphans();
      final files = await TtsModelService.pendingDownloadFiles();
      if (files.isNotEmpty) {
        final ok = await ModelDownloadService.start(
          title: L10n.current.ttsLiveDownloadTitle,
          files: files,
        );
        if (ok) {
          debugPrint('[TtsDownload] 已交给原生后台下载（${files.length} 个文件）');
          return;
        }
      }
      debugPrint('[TtsDownload] 原生下载不可用，回落 Dart 下载');
    }

                                          
                                       
    await TtsLiveUpdate.downloadStart();
    try {
      await (debugInstaller ?? TtsModelService.install)(
        onProgress: (received, total, name) {
          _received = received;
          _total = total;
          _currentFile = name;
          notifyListeners();
          unawaited(TtsLiveUpdate.downloadProgress(received, total, name));
        },
        shouldCancel: () => _cancelRequested,
      );
      _justFinished = true;
      _received = _total;
      await _setInFlight(false);
      await TtsLiveUpdate.downloadDone();
      await _notifyDone();
    } on TtsModelCancelled {
                          
      await _setInFlight(false);
      unawaited(TtsLiveUpdate.cancel());
    } on TtsModelException catch (e) {
      _error = e.message;
      await _setInFlight(false);
      await TtsLiveUpdate.downloadFail(e.message);
    } catch (e) {
      _error = '$e';
      await _setInFlight(false);
      await TtsLiveUpdate.downloadFail('$e');
    } finally {
      _running = false;
      _cancelRequested = false;
      notifyListeners();
    }
  }

                                       
  void cancel() {
    if (!_running || _cancelRequested) return;
    _cancelRequested = true;
    notifyListeners();
    if (ModelDownloadService.supported) {
      unawaited(ModelDownloadService.cancel());
    }
  }

                                
  void _bindNativeCallbacks() {
    if (_nativeBound) return;
    _nativeBound = true;
    final self = this;
    ModelDownloadService.onProgress = (received, total, percent, name) {
      self._received = received;
      self._total = total;
      self._currentFile = name;
      self.notifyListeners();
    };
    ModelDownloadService.onComplete = (paths) async {
      debugPrint('[TtsDownload] 原生下载完成');
      self._justFinished = true;
      self._received = self._total;
      self._running = false;
      await self._setInFlight(false);
      self.notifyListeners();
      await self._notifyDone();
    };
    ModelDownloadService.onError = (message) async {
      self._error = message;
      self._running = false;
      await self._setInFlight(false);
      self.notifyListeners();
    };
    ModelDownloadService.onCanceled = () async {
      self._running = false;
      self._cancelRequested = false;
      await self._setInFlight(false);
      self.notifyListeners();
    };
  }

  Future<void> _setInFlight(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefInFlight, value);
    } catch (_) {}
  }

                                       
  Future<void> _notifyDone() async {
    try {
      final l10n = L10n.current;
      await NotificationService().showMessageNotification(
        senderIP: l10n.ttsDownloadDoneTitle,
        nickname: l10n.ttsDownloadDoneTitle,
        message: l10n.ttsDownloadDoneBody,
      );
      debugPrint('[TtsDownload] 已发完成通知');
    } catch (e) {
      debugPrint('[TtsDownload] 完成通知失败: $e');
    }
  }

  @visibleForTesting
  void debugReset() {
    _running = false;
    _cancelRequested = false;
    _received = 0;
    _total = 0;
    _currentFile = '';
    _error = null;
    _justFinished = false;
    debugInstaller = null;
  }
}
