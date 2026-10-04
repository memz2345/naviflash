import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

void main() {
  final now = DateTime.now();
  final formatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

                                              
  const String kCodename = 'RedStone-R2';

  final flutterVersion = _detectFlutterVersion();

  final content = '''
// GENERATED FILE - DO NOT EDIT MANUALLY
// Generated on: $formatted
class BuildInfo {
  static const String buildCodename = '$kCodename';
  static const String buildTimestamp = '$formatted';

  /// 构建时的 Flutter SDK 版本（「Powered by Flutter x.y.z」用）。
  static const String flutterVersion = '$flutterVersion';
  static const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
}
''';

  File('lib/build_info.g.dart').writeAsStringSync(content);
  print(' Build info generated successfully.');
  print('  Codename: $kCodename');
  print(' Timestamp: $formatted');
  print(' Flutter:   $flutterVersion');
}

                                               
                     
String _detectFlutterVersion() {
  final exe = Platform.isWindows ? 'flutter.bat' : 'flutter';
  try {
    final result = Process.runSync(exe, ['--version', '--machine']);
    if (result.exitCode == 0) {
      final decoded = jsonDecode(result.stdout as String);
      if (decoded is Map && decoded['frameworkVersion'] is String) {
        final version = decoded['frameworkVersion'] as String;
        if (version.isNotEmpty) return version;
      }
    }
  } catch (_) {
                    
  }
  return 'unknown';
}
