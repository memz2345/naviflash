                          
import 'dart:io' show Platform, Process, ProcessResult;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class NativeBridge {
           
  static const MethodChannel _toastChannel = MethodChannel('com.memz2345.navi.flash/toast');
  static const MethodChannel _exitChannel = MethodChannel('com.memz2345.navi.flash/exit');
  static const MethodChannel _mediaScanChannel = MethodChannel('com.memz2345.navi.flash/media_scan');
  static const MethodChannel _easterEggChannel = MethodChannel('com.memz2345.navi.flash/easter_egg');

                                      
                                     
  static const MethodChannel _clipboardChannel = MethodChannel('com.memz2345.navi.flash/clipboard');

                                                      
  static const MethodChannel _localeChannel = MethodChannel('com.memz2345.navi.flash/locale');

  static void Function(String type, dynamic data)? _onPasteListener;
  static bool _isClipboardInitialized = false;
  static void Function(List<String> tags)? _onAppLocalesChanged;

                                                    

                
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
                         
  static Future<void> requestExit() async {
    try {
      await _exitChannel.invokeMethod('exitApp');
    } on PlatformException catch (e) {
      debugPrint("Failed to request exit: '${e.message}'.");
    }
  }

                                           
  static Future<void> openEasterEgg() async {
    try {
      await _easterEggChannel.invokeMethod('openEasterEgg');
    } on PlatformException catch (e) {
      debugPrint("Failed to open Easter Egg: '${e.message}'.");
    }
  }

                          
  static Future<void> scanMediaFile(String filePath) async {
    try {
      await _mediaScanChannel.invokeMethod('scanFile', {'path': filePath});
    } on PlatformException catch (e) {
      debugPrint("Failed to scan file: '${e.message}'.");
    }
  }

                                                                  

                                                       
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

                                         
  static void setOnPasteListener(void Function(String type, dynamic data) listener) {
    _onPasteListener = listener;
  }

                 
                                                                  
                          
  static Future<Map<String, dynamic>?> getClipboardData() async {
    try {
      final result = await _clipboardChannel.invokeMethod<Map<dynamic, dynamic>>('getClipboardData');
      if (result == null) return null;
                                            
      return result.map((key, value) => MapEntry(key.toString(), value));
    } on PlatformException catch (e) {
      debugPrint('NativeBridge getClipboardData PlatformException: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('NativeBridge getClipboardData Error: $e');
      return null;
    }
  }

                                                            

                                                         
                                                  
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

                                                     
  static const MethodChannel _storageChannel = MethodChannel('com.memz2345.navi.flash/storage');

                                 
                                                                       
                    
  static Future<Map<String, int>?> getStorageInfo() async {
                               
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
                                 
    } catch (e) {
      debugPrint('NativeBridge getStorageInfo Error: $e');
    }

                                                            
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

                                                          
  static const MethodChannel _exportFileChannel =
      MethodChannel('com.memz2345.navi.flash/export_file');

                                                 
     
                                                        
                                           
                                                  
  static Future<String?> saveFileToDownloads({
    required String sourcePath,
    required String fileName,
    required String mime,
  }) async {
    if (!kIsWeb && !Platform.isAndroid) return null;
    try {
      return await _exportFileChannel.invokeMethod<String>(
        'saveToDownloads',
        {'path': sourcePath, 'name': fileName, 'mime': mime},
      );
    } on PlatformException catch (e) {
      debugPrint('NativeBridge saveToDownloads failed: ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

                                                                
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
                                             
      String drive = 'C';
      try {
        final docPath = await _getAppDocPath();
        if (docPath != null && docPath.length >= 2 && docPath[1] == ':') {
          drive = docPath[0].toUpperCase();
        }
      } catch (_) {}
                           
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
                
      final wmicResult = await _runProcessWithTimeout(
        'wmic',
        ['logicaldisk', 'where', 'DeviceID="$drive:"', 'get', 'Size,FreeSpace', '/format:csv'],
        timeoutMs: 2500,
      );
      if (wmicResult != null && wmicResult.exitCode == 0) {
        final out = wmicResult.stdout.toString();
        final lines = out.split('\n').where((l) => l.contains(':')).toList();
        for (final line in lines) {
                                              
          final cols = line.split(',');
          if (cols.length >= 4) {
            final free = int.tryParse(cols[cols.length - 2].trim()) ?? 0;
            final total = int.tryParse(cols[cols.length - 1].trim()) ?? 0;
            if (total > 0) {
              return {'totalBytes': total, 'freeBytes': free, 'usedBytes': total - free};
            }
          } else {
                    
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
                                       
          final dataLine = lines.last.trim();
                                                                               
          final parts = dataLine.split(RegExp(r'\s+'));
          if (parts.length >= 4) {
                                  
                                                           
            final totalKb = int.tryParse(parts[parts.length - 4]) ?? 0;
                                                                         
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