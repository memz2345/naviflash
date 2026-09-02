// lib/services/log_service.dart
//
// 全局日志服务：统一收集崩溃 / 错误 / mpv 日志，落盘到各平台的应用数据目录。
//
// 目录结构（以应用数据目录为根）：
//   error/  → 崩溃与错误日志（闪退、Flutter 错误、未捕获异常），必写
//   mpv/    → mpv 播放器日志（可选，细度由播放器设置控制）
//
// 各平台落盘位置（path_provider getApplicationSupportDirectory）：
//   Android : /data/data/包名/files/error  与  .../files/mpv  （应用私有数据目录）
//   iOS     : 沙盒/Library/Application Support/error 与 .../mpv
//   Windows : %APPDATA%/应用名/error  与  .../mpv
//   macOS   : ~/Library/Application Support/应用名/error 与 .../mpv
//   Linux   : ~/.local/share/应用名/error 与 .../mpv
//   Web     : 不支持文件写入，仅输出到控制台
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/l10n_helper.dart';

class LogService {
  LogService._();

  static const int _maxLogPartSize = 10 * 1024 * 1024; // 10MB，超出后滚动新文件
  static const int _maxParts = 4; // 同一天最多滚动出 4 个文件
  static const Duration _maxAge = Duration(days: 7); // 自动清理 7 天前的日志

  static Directory? _baseDir;
  static Directory? _errorDir;
  static Directory? _mpvDir;
  static bool _initialized = false;

  /// 应用数据目录（error/ 与 mpv/ 的父目录）；Web 上为 null。
  static Directory? get baseDir => _baseDir;

  /// 错误 / 崩溃日志目录。
  static Directory? get errorDir => _errorDir;

  /// mpv 日志目录。
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

  /// 初始化：解析目录 + 清理过期日志。应在 main() 最早期调用（幂等）。
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

  /// 启动信息（版本 / 平台），写入当日错误日志开头，方便排障。
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

  /// 记录一般错误（非致命），追加到当日错误日志。
  static Future<void> error(String message, [StackTrace? stack]) async {
    debugPrint('⚠️ [日志] $message');
    if (kIsWeb) return;
    final sb = StringBuffer()
      ..writeln('[ERROR] ${_timeStamp()} $message');
    if (stack != null) sb.writeln(stack);
    await _write(_errorDir, 'error_${_dateStamp()}.log', sb.toString());
  }

  /// 记录崩溃（闪退）：写入当日汇总错误日志，同时单独生成 crash_<时间戳>.log
  /// 便于在日志页直接定位 / 分享最近一次崩溃。
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

  /// mpv 日志：追加到当日 mpv 日志（超出 10MB 自动滚动新文件）。
  static Future<void> mpv(String level, String text) async {
    await _write(
      _mpvDir,
      'mpv_${_dateStamp()}.log',
      '[$level] ${_timeStamp()} $text',
    );
  }

  // ───────────────────────── 内部实现 ─────────────────────────

  /// 追加写入；单文件超过 10MB 时滚动到 `mpv_date_2.log` / `_3.log` / `_4.log`。
  static Future<void> _write(Directory? dir, String name, String content) async {
    try {
      if (kIsWeb || dir == null) return;
      if (!await dir.exists()) await dir.create(recursive: true);

      var file = File('${dir.path}${Platform.pathSeparator}$name');
      // 超过大小上限 → 滚动到同一天的下一个序号文件（最多 _maxParts 个）
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

  /// 清理 7 天前的日志文件。
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

  /// 当日日期戳：2026-08-06
  static String _dateStamp() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  /// 文件时间戳：20260806_153000
  static String _fileStamp() {
    final n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}_'
        '${n.hour.toString().padLeft(2, '0')}'
        '${n.minute.toString().padLeft(2, '0')}'
        '${n.second.toString().padLeft(2, '0')}';
  }

  /// 行内时间戳：HH:mm:ss
  static String _timeStamp() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:'
        '${n.minute.toString().padLeft(2, '0')}:'
        '${n.second.toString().padLeft(2, '0')}';
  }
}
