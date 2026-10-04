                                    
  
                                                  
  
                                                            
                                   
  
                                      
                                                         
                                     
import 'dart:io';

import 'package:naviflash/services/live_update_service.dart';

abstract final class TtsLiveUpdate {
                                         
  static const int notificationId = 4820;

  static bool get _isEn => Platform.localeName.toLowerCase().startsWith('en');

  static String get _tTitle => _isEn ? 'AI narration' : 'AI 朗读';

  static String _trim(String text, [int max = 40]) {
    final oneLine = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return oneLine.length > max ? '${oneLine.substring(0, max)}…' : oneLine;
  }

                               

  static Future<void> downloadStart() async {
    await LiveUpdateService.start(
      notificationId,
      _tTitle,
      text: _isEn ? 'Downloading model…' : '正在下载模型…',
    );
  }

  static Future<void> downloadProgress(
    int received,
    int total,
    String name,
  ) async {
    if (total <= 0) {
      await LiveUpdateService.update(
        notificationId,
        progress: 0,
        text: name,
        indeterminate: true,
      );
      return;
    }
    final percent = (received / total * 100).clamp(0, 100).round();
    await LiveUpdateService.update(
      notificationId,
      progress: percent,
      text: '$percent% · ${_mb(received)}/${_mb(total)}',
    );
  }

  static Future<void> downloadDone() async {
    await LiveUpdateService.finish(
      notificationId,
      title: _tTitle,
      text: _isEn ? 'Model ready' : '模型下载完成',
    );
  }

  static Future<void> downloadFail(String message) async {
    await LiveUpdateService.fail(
      notificationId,
      title: _tTitle,
      text: message.isEmpty
          ? (_isEn ? 'Download failed' : '下载失败')
          : _trim(message, 60),
    );
  }

                          

                             
  static Future<void> synthesizeStart(String text) async {
    await LiveUpdateService.start(
      notificationId,
      _tTitle,
      text: _isEn ? 'Preparing…' : '准备合成…',
    );
  }

                                    
  static Future<void> synthesizing(String text) async {
    await LiveUpdateService.update(
      notificationId,
      progress: 0,
      text: _isEn ? 'Synthesizing…' : '正在合成语音…',
      indeterminate: true,
    );
  }

                          
  static Future<void> synthesizeDone(Duration duration) async {
    final seconds = duration.inSeconds;
    await LiveUpdateService.finish(
      notificationId,
      title: _tTitle,
      text: _isEn ? 'Done ($seconds s)' : '合成完成 · $seconds 秒',
    );
  }

  static Future<void> synthesizeFail(Object error) async {
    final msg = '$error';
    await LiveUpdateService.fail(
      notificationId,
      title: _tTitle,
      text: msg.isEmpty ? (_isEn ? 'Failed' : '合成失败') : _trim(msg, 60),
    );
  }

                         
  static Future<void> cancel() => LiveUpdateService.cancel(notificationId);

  static String _mb(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    return '${bytes}B';
  }
}
