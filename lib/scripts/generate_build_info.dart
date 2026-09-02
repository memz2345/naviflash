import 'dart:io';
import 'package:intl/intl.dart';

void main() {
  final now = DateTime.now();
  final formatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

//  暂时在此硬编码构建代号，后续可改为读取 pubspec.yaml 或 CI 环境变量
  const String kCodename = 'RedStone-R2';

  final content = '''
// GENERATED FILE - DO NOT EDIT MANUALLY
// Generated on: $formatted
class BuildInfo {
  static const String buildCodename = '$kCodename';
  static const String buildTimestamp = '$formatted';
  static const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
}
''';

  File('lib/build_info.g.dart').writeAsStringSync(content);
  print(' Build info generated successfully.');
  print('  Codename: $kCodename');
  print(' Timestamp: $formatted');
}