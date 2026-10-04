                                
  
                                             
  
                   
                                              
                                       
  
                                                         
                                                                      
                                                             
                                              
                                                                
                                                 
                              
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/l10n_helper.dart';

class LogService {
  LogService._();

  static const int _maxLogPartSize = 10 * 1024 * 1024;                 
  static const int _maxParts = 4;                  
  static const Duration _maxAge = Duration(days: 7);                

  static Directory? _baseDir;
  static Directory? _errorDir;
  static Directory? _mpvDir;
  static bool _initialized = false;

                                             
  static Directory? get baseDir => _baseDir;

                  
  static Directory? get errorDir => _errorDir;

               
  static Directory? get mpvDir => _mpvDir;

  static String get baseDirLabel {
    if (kIsWeb) return L10n.current.logWebUnsupported;
    final p = _baseDir?.path;
    if (p == null || p.isEmpty) return L10n.current.logNotInitialized;
    if (Platform.isAndroid) return L10n.current.logAppDataDir(p);
    if (Platform.isWindows) return L10n.current.logAppDataRoaming(p);
    if (Platform.isMacOS) return L10n.current.logAppSupport(p);
    if (Platform.isLinux) return L10n.current.logLocalDataDir(p);
    return p;
  }

                                            
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      if (kIsWeb) return;
      _baseDir = await getApplicationSupportDirectory();
      _errorDir = Directory('${_baseDir!.path}${Platform.pathSeparator}error');
      _mpvDir = Directory('${_baseDir!.path}${Platform.pathSeparator}mpv');
      await _errorDir!.create(recursive: true);
      await _mpvDir!.create(recursive: true);
      _cleanupOldLogs();
    } catch (e) {
      debugPrint('⚠️ 日志目录初始化失败: $e');
    }
  }

                                    
  static Future<void> logAppStart({
    required String appName,
    required String version,
  }) async {
    if (kIsWeb) return;
    await _write(
      _errorDir,
      'error_${_dateStamp()}.log',
      '=== 应用启动 $appName $version | ${Platform.operatingSystem} '
          '${Platform.operatingSystemVersion} | ${DateTime.now().toIso8601String()} ===',
    );
  }

                            
  static Future<void> error(String message, [StackTrace? stack]) async {
    debugPrint('⚠️ [日志] $message');
    if (kIsWeb) return;
    final sb = StringBuffer()
      ..writeln('[ERROR] ${_timeStamp()} $message');
    if (stack != null) sb.writeln(stack);
    await _write(_errorDir, 'error_${_dateStamp()}.log', sb.toString());
  }

                                                
                            
  static Future<void> crash(String title, String body) async {
    debugPrint('💥 [崩溃] $title');
    if (kIsWeb) return;
    final stamp = _fileStamp();
    final content =
        '=== $title ===\n时间: ${DateTime.now().toIso8601String()}\n'
        '平台: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n\n$body\n';
    await _write(_errorDir, 'error_${_dateStamp()}.log', content);
    await _write(_errorDir, 'crash_$stamp.log', content);
  }

                                           
  static Future<void> mpv(String level, String text) async {
    await _write(
      _mpvDir,
      'mpv_${_dateStamp()}.log',
      '[$level] ${_timeStamp()} $text',
    );
  }

                                                             

                                                                  
  static Future<void> _write(Directory? dir, String name, String content) async {
    try {
      if (kIsWeb || dir == null) return;
      if (!await dir.exists()) await dir.create(recursive: true);

      var file = File('${dir.path}${Platform.pathSeparator}$name');
                                                
      if (await file.exists() && await file.length() > _maxLogPartSize) {
        if (name.endsWith('.log')) {
          final base = name.substring(0, name.length - 4);
          var part = 2;
          var partFile = File(
              '${dir.path}${Platform.pathSeparator}${base}_$part.log');
          while (part < _maxParts && partFile.existsSync()) {
            part++;
            partFile = File(
                '${dir.path}${Platform.pathSeparator}${base}_$part.log');
          }
          file = partFile;
        }
      }

      final sink = file.openWrite(mode: FileMode.append);
      sink.write(content);
      if (!content.endsWith('\n')) sink.write('\n');
      await sink.flush();
      await sink.close();
    } catch (_) {}
  }

                   
  static void _cleanupOldLogs() {
    final cutoff = DateTime.now().subtract(_maxAge);
    for (final dir in [_errorDir, _mpvDir]) {
      if (dir == null || !dir.existsSync()) continue;
      try {
        for (final entity in dir.listSync()) {
          if (entity is! File) continue;
          try {
            final stat = entity.statSync();
            if (stat.modified.isBefore(cutoff)) {
              entity.deleteSync();
            }
          } catch (_) {}
        }
      } catch (_) {}
    }
  }

                      
  static String _dateStamp() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

                           
  static String _fileStamp() {
    final n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}_'
        '${n.hour.toString().padLeft(2, '0')}'
        '${n.minute.toString().padLeft(2, '0')}'
        '${n.second.toString().padLeft(2, '0')}';
  }

                    
  static String _timeStamp() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:'
        '${n.minute.toString().padLeft(2, '0')}:'
        '${n.second.toString().padLeft(2, '0')}';
  }
}
