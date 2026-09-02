// lib/lnative_bridge.dart
import 'dart:io' show Platform, Process, ProcessResult;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class NativeBridge {
  // 原有功能通道
  static const MethodChannel _toastChannel = MethodChannel('com.memz2345.navi.flash/toast');
  static const MethodChannel _exitChannel = MethodChannel('com.memz2345.navi.flash/exit');
  static const MethodChannel _mediaScanChannel = MethodChannel('com.memz2345.navi.flash/media_scan');
  static const MethodChannel _easterEggChannel = MethodChannel('com.memz2345.navi.flash/easter_egg');

//  统一剪贴板通道 (支持 Win+V / Ctrl+V 的图片与文本)
  // 必须与 flutter_window.cpp 中的通道名完全一致
  static const MethodChannel _clipboardChannel = MethodChannel('com.memz2345.navi.flash/clipboard');

//  Android 13+ 按应用设置语言通道（MainActivity LOCALE_CHANNEL）
  static const MethodChannel _localeChannel = MethodChannel('com.memz2345.navi.flash/locale');

  static void Function(String type, dynamic data)? _onPasteListener;
  static bool _isClipboardInitialized = false;
  static void Function(List<String> tags)? _onAppLocalesChanged;

  // ================= 原有功能 (保持不变) =================

  /// 显示原生 Toast
  static Future<void> showToast(String message) async {
    try {
      await _toastChannel.invokeMethod('showToast', {'message': message});
    } on PlatformException catch (e) {
      debugPrint("Failed to show toast: '${e.message}'.");
    }
  }
static Future<bool> copyImageToClipboard(Uint8List imageBytes) async {
  try {
    final result = await _clipboardChannel.invokeMethod<bool>('copyImage', {'data': imageBytes});
    return result ?? false;
  } on PlatformException catch (e) {
    debugPrint('NativeBridge copyImageToClipboard Error: ${e.message}');
    return false;
  }
}
  /// 请求退出应用 (会弹出原生确认对话框)
  static Future<void> requestExit() async {
    try {
      await _exitChannel.invokeMethod('exitApp');
    } on PlatformException catch (e) {
      debugPrint("Failed to request exit: '${e.message}'.");
    }
  }

  /// 打开原生彩蛋 Activity (Android Compose 设置页)
  static Future<void> openEasterEgg() async {
    try {
      await _easterEggChannel.invokeMethod('openEasterEgg');
    } on PlatformException catch (e) {
      debugPrint("Failed to open Easter Egg: '${e.message}'.");
    }
  }

  /// 扫描媒体文件 (用于保存图片后刷新相册)
  static Future<void> scanMediaFile(String filePath) async {
    try {
      await _mediaScanChannel.invokeMethod('scanFile', {'path': filePath});
    } on PlatformException catch (e) {
      debugPrint("Failed to scan file: '${e.message}'.");
    }
  }

  // ================= 剪贴板模块 (Win+V / Ctrl+V 支持) =================

  /// 初始化剪贴板监听（建议在 main() 或 ChatScreen initState 中调用一次）
  static void init() {
    if (_isClipboardInitialized) return;
    _isClipboardInitialized = true;

    _clipboardChannel.setMethodCallHandler((call) async {
      if (call.method == 'onClipboardPasted') {
        final Map<dynamic, dynamic>? args = call.arguments as Map<dynamic, dynamic>?;
        if (args != null) {
          final String type = args['type'] as String? ?? 'unknown';
          final dynamic data = args['data'];
          _onPasteListener?.call(type, data);
        }
      }
    });
  }

  /// 设置原生粘贴事件回调 (Win+V / Ctrl+V 触发时自动调用)
  static void setOnPasteListener(void Function(String type, dynamic data) listener) {
    _onPasteListener = listener;
  }

  /// 主动获取当前剪贴板内容
  /// 返回格式: {'type': 'image' | 'text', 'data': Uint8List | String}
  /// 若剪贴板为空或格式不支持，返回 null
  static Future<Map<String, dynamic>?> getClipboardData() async {
    try {
      final result = await _clipboardChannel.invokeMethod<Map<dynamic, dynamic>>('getClipboardData');
      if (result == null) return null;
      // 将 dynamic key 转为 String 方便 Dart 层使用
      return result.map((key, value) => MapEntry(key.toString(), value));
    } on PlatformException catch (e) {
      debugPrint('NativeBridge getClipboardData PlatformException: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('NativeBridge getClipboardData Error: $e');
      return null;
    }
  }

  // ================= Android 13+ 按应用设置语言 =================

  /// 读取系统级「按应用设置语言」（BCP-47 标签列表，如 `['zh-CN']`，空 = 跟随系统）。
  /// 返回 null 表示系统不支持（Android < 13 或非 Android 平台）。
  static Future<List<String>?> getSystemAppLocales() async {
    try {
      return await _localeChannel.invokeListMethod<String>('getAppLocales');
    } on PlatformException catch (e) {
      debugPrint('NativeBridge getSystemAppLocales: ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// 写入系统级「按应用设置语言」，[tag] 传 null/空表示恢复「跟随系统」。
  /// 返回是否由系统 API 生效（false = Android < 13，仅应用内偏好生效）。
  static Future<bool> setSystemAppLocale(String? tag) async {
    try {
      return await _localeChannel.invokeMethod<bool>('setAppLocale', {'tag': tag}) ?? false;
    } on PlatformException catch (e) {
      debugPrint('NativeBridge setSystemAppLocale: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  // ================= 存储空间（真实设备存储） =================
  static const MethodChannel _storageChannel = MethodChannel('com.memz2345.navi.flash/storage');

  /// 获取真实设备存储：total/free/used 字节
  /// 优先走原生通道（Android StatFs / iOS FileManager），失败则尝试 Dart 侧桌面 fallback
  /// 返回 null 表示获取失败
  static Future<Map<String, int>?> getStorageInfo() async {
    // 1) 尝试原生通道（Android / iOS）
    try {
      final result = await _storageChannel.invokeMethod<Map<dynamic, dynamic>>('getStorageInfo');
      if (result != null) {
        final total = (result['totalBytes'] as int?) ?? 0;
        final free = (result['freeBytes'] as int?) ?? 0;
        final used = (result['usedBytes'] as int?) ?? (total - free);
        if (total > 0) {
          return {
            'totalBytes': total,
            'freeBytes': free,
            'usedBytes': used,
          };
        }
      }
    } on PlatformException catch (e) {
      debugPrint('NativeBridge getStorageInfo PlatformException: ${e.message}');
    } on MissingPluginException {
      // 通道未注册，继续尝试 Dart fallback
    } catch (e) {
      debugPrint('NativeBridge getStorageInfo Error: $e');
    }

    // 2) Dart 侧桌面 fallback：Windows / macOS / Linux 通过进程查询磁盘
    if (!kIsWeb) {
      try {
        // ignore: avoid_slow_async_io
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          final fallback = await _getStorageInfoViaProcess();
          if (fallback != null && (fallback['totalBytes'] ?? 0) > 0) {
            return fallback;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// 桌面端通过进程查询磁盘信息（Windows: PowerShell / wmic, macOS/Linux: df）
  static Future<Map<String, int>?> _getStorageInfoViaProcess() async {
    try {
      if (Platform.isWindows) {
        return await _getWindowsDiskInfo();
      } else if (Platform.isMacOS || Platform.isLinux) {
        return await _getUnixDiskInfo();
      }
    } catch (e) {
      debugPrint('NativeBridge _getStorageInfoViaProcess error: $e');
    }
    return null;
  }

  static Future<Map<String, int>?> _getWindowsDiskInfo() async {
    try {
      // 尝试 PowerShell Get-PSDrive（取文档目录所在盘符）
      String drive = 'C';
      try {
        final docPath = await _getAppDocPath();
        if (docPath != null && docPath.length >= 2 && docPath[1] == ':') {
          drive = docPath[0].toUpperCase();
        }
      } catch (_) {}
      // PowerShell: 查询指定盘符
      final psResult = await _runProcessWithTimeout(
        'powershell',
        ['-NoProfile', '-Command', '\$d=Get-PSDrive -Name $drive -ErrorAction SilentlyContinue; if(\$d){Write-Output "\$(\$d.Free) \$(\$d.Used)"}'],
        timeoutMs: 2500,
      );
      if (psResult != null && psResult.exitCode == 0) {
        final out = psResult.stdout.toString().trim();
        final parts = out.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final free = int.tryParse(parts[0]) ?? 0;
          final used = int.tryParse(parts[1]) ?? 0;
          final total = free + used;
          if (total > 0) {
            return {'totalBytes': total, 'freeBytes': free, 'usedBytes': used};
          }
        }
      }
      // 兜底：wmic
      final wmicResult = await _runProcessWithTimeout(
        'wmic',
        ['logicaldisk', 'where', 'DeviceID="$drive:"', 'get', 'Size,FreeSpace', '/format:csv'],
        timeoutMs: 2500,
      );
      if (wmicResult != null && wmicResult.exitCode == 0) {
        final out = wmicResult.stdout.toString();
        final lines = out.split('\n').where((l) => l.contains(':')).toList();
        for (final line in lines) {
          // CSV: Node,DeviceID,FreeSpace,Size
          final cols = line.split(',');
          if (cols.length >= 4) {
            final free = int.tryParse(cols[cols.length - 2].trim()) ?? 0;
            final total = int.tryParse(cols[cols.length - 1].trim()) ?? 0;
            if (total > 0) {
              return {'totalBytes': total, 'freeBytes': free, 'usedBytes': total - free};
            }
          } else {
            // 纯空格格式
            final parts = line.trim().split(RegExp(r'\s+'));
            if (parts.length >= 2) {
              final free = int.tryParse(parts[parts.length - 2]) ?? 0;
              final total = int.tryParse(parts[parts.length - 1]) ?? 0;
              if (total > 0) return {'totalBytes': total, 'freeBytes': free, 'usedBytes': total - free};
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, int>?> _getUnixDiskInfo() async {
    try {
      String targetPath = '/';
      try {
        final docPath = await _getAppDocPath();
        if (docPath != null && docPath.isNotEmpty) targetPath = docPath;
      } catch (_) {}
      final result = await _runProcessWithTimeout(
        'df',
        ['-k', targetPath],
        timeoutMs: 2000,
      );
      if (result != null && result.exitCode == 0) {
        final out = result.stdout.toString();
        final lines = out.trim().split('\n');
        if (lines.length >= 2) {
          // 取最后一行（df 可能输出 header + 数据）
          final dataLine = lines.last.trim();
          // 按空白分割，df -k 输出：Filesystem 1K-blocks Used Available Use% Mounted on
          final parts = dataLine.split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            // 不同系统列顺序略有差异，尝试从后往前取
            // 倒数第4: 1K-blocks, 倒数第3: Used, 倒数第2: Available
            final totalKb = int.tryParse(parts[parts.length - 4]) ?? 0;
            // final usedKb = int.tryParse(parts[parts.length - 3]) ?? 0;
            final freeKb = int.tryParse(parts[parts.length - 2]) ?? 0;
            final total = totalKb * 1024;
            final free = freeKb * 1024;
            if (total > 0) {
              return {'totalBytes': total, 'freeBytes': free, 'usedBytes': total - free};
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _getAppDocPath() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } catch (_) {
      return null;
    }
  }

  static Future<ProcessResult?> _runProcessWithTimeout(
    String executable,
    List<String> args, {
    int timeoutMs = 2000,
  }) async {
    try {
      // ignore: avoid_slow_async_io
      final future = Process.run(executable, args);
      return await future.timeout(Duration(milliseconds: timeoutMs));
    } catch (_) {
      return null;
    }
  }

  /// 注册系统级应用语言变化回调（用户在系统「应用信息 → 语言」页修改时触发）。
  static void setOnAppLocalesChangedListener(
      void Function(List<String> tags)? listener) {
    _onAppLocalesChanged = listener;
    _localeChannel.setMethodCallHandler((call) async {
      if (call.method == 'onAppLocalesChanged') {
        final args = call.arguments as Map?;
        final raw = args?['tags'] as List?;
        final tags = raw?.map((e) => e.toString()).toList() ?? const <String>[];
        _onAppLocalesChanged?.call(tags);
      }
    });
  }

  // ================= 兼容旧版 API (平滑过渡，后续可删除) =================

  @Deprecated('请使用 init() 和 setOnPasteListener()')
  static void startListeningClipboardImage(void Function(Uint8List) onImagePasted) {
    init();
    setOnPasteListener((type, data) {
      if (type == 'image' && data is Uint8List) {
        onImagePasted(data);
      }
    });
  }

  @Deprecated('请使用 getClipboardData()')
  static Future<Uint8List?> getClipboardImage() async {
    final data = await getClipboardData();
    if (data != null && data['type'] == 'image') {
      return data['data'] as Uint8List?;
    }
    return null;
  }
}