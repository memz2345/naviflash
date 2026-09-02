import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../l10n/l10n_helper.dart';

/// 获取设备信息并返回带 Material Icons 的 UI 组件
Future<Widget> getHostSystemInfo() async {
  final deviceInfo = DeviceInfoPlugin();
  final List<Widget> infoRows = [];

  // 辅助方法：统一添加"图标+标签+值"的行
  void _addRow(IconData icon, String label, String value) {
    infoRows.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text(value, style: const TextStyle(fontSize: 14, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  try {
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
//  修复：使用 ?? 处理可空类型，使用 toString() 转换 int
      _addRow(Icons.system_update, L10n.current.deviceOs, '${info.version.release ?? 'Unknown'} (SDK ${info.version.sdkInt})');
      _addRow(Icons.build, L10n.current.deviceBuild, info.version.incremental ?? 'N/A');
      _addRow(Icons.security, L10n.current.deviceSecurityPatch, info.version.securityPatch ?? 'N/A');
      _addRow(Icons.business, L10n.current.deviceOem, info.manufacturer ?? 'Unknown');
      _addRow(Icons.branding_watermark, L10n.current.deviceBrand, info.brand ?? 'Unknown');
      _addRow(Icons.phone_android, L10n.current.deviceModel, info.model ?? 'Unknown');
      _addRow(Icons.display_settings, L10n.current.deviceRomVersion, info.display ?? 'N/A');
      _addRow(Icons.fingerprint, L10n.current.deviceFingerprint, info.fingerprint ?? 'N/A');
      
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      _addRow(Icons.apple, L10n.current.deviceOs, info.systemVersion ?? 'Unknown');
      _addRow(Icons.phone_iphone, L10n.current.deviceModel, info.model ?? 'Unknown');
      _addRow(Icons.account_circle, L10n.current.deviceName, info.name ?? 'Unknown');
      
    } else if (Platform.isWindows) {
      final info = await deviceInfo.windowsInfo;
      _addRow(Icons.desktop_windows, L10n.current.deviceOs, '${info.releaseId ?? 'Unknown'} / ${info.displayVersion ?? 'Unknown'}');
      _addRow(Icons.build, L10n.current.deviceBuild, info.buildNumber.toString()); //  修复：int 转 String
      _addRow(Icons.computer, L10n.current.deviceComputerName, info.computerName ?? 'Unknown');
      
    } else if (Platform.isMacOS) {
      final info = await deviceInfo.macOsInfo;
      _addRow(Icons.apple, L10n.current.deviceOs, info.osRelease ?? 'Unknown');
      _addRow(Icons.laptop_mac, L10n.current.deviceHardwareModel, info.model ?? 'Unknown');
      _addRow(Icons.memory, L10n.current.deviceKernel, info.kernelVersion ?? 'Unknown');
      
    } else if (Platform.isLinux) {
      final info = await deviceInfo.linuxInfo;
      _addRow(Icons.terminal, L10n.current.deviceDistro, info.prettyName ?? 'Unknown');
      _addRow(Icons.build, L10n.current.deviceVersion, '${info.version ?? 'Unknown'} (${info.versionCodename ?? 'N/A'})');
      
    } else {
      _addRow(Icons.help_outline, L10n.current.devicePlatform, Platform.operatingSystem);
    }
  } catch (e) {
    infoRows.add(
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(L10n.current.deviceInfoFailed('$e'),
            style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: infoRows,
  );
}