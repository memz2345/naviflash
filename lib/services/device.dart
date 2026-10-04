import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../l10n/l10n_helper.dart';

                                     
Future<Widget> getHostSystemInfo() async {
  final deviceInfo = DeviceInfoPlugin();
  final List<Widget> infoRows = [];

                         
  void addRow(IconData icon, String label, String value) {
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
                                        
      addRow(Icons.system_update, L10n.current.deviceOs, '${info.version.release} (SDK ${info.version.sdkInt})');
      addRow(Icons.build, L10n.current.deviceBuild, info.version.incremental);
      addRow(Icons.security, L10n.current.deviceSecurityPatch, info.version.securityPatch ?? 'N/A');
      addRow(Icons.business, L10n.current.deviceOem, info.manufacturer);
      addRow(Icons.branding_watermark, L10n.current.deviceBrand, info.brand);
      addRow(Icons.phone_android, L10n.current.deviceModel, info.model);
      addRow(Icons.display_settings, L10n.current.deviceRomVersion, info.display);
      addRow(Icons.fingerprint, L10n.current.deviceFingerprint, info.fingerprint);
      
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      addRow(Icons.apple, L10n.current.deviceOs, info.systemVersion);
      addRow(Icons.phone_iphone, L10n.current.deviceModel, info.model);
      addRow(Icons.account_circle, L10n.current.deviceName, info.name);
      
    } else if (Platform.isWindows) {
      final info = await deviceInfo.windowsInfo;
      addRow(Icons.desktop_windows, L10n.current.deviceOs, '${info.releaseId} / ${info.displayVersion}');
      addRow(Icons.build, L10n.current.deviceBuild, info.buildNumber.toString());                    
      addRow(Icons.computer, L10n.current.deviceComputerName, info.computerName);
      
    } else if (Platform.isMacOS) {
      final info = await deviceInfo.macOsInfo;
      addRow(Icons.apple, L10n.current.deviceOs, info.osRelease);
      addRow(Icons.laptop_mac, L10n.current.deviceHardwareModel, info.model);
      addRow(Icons.memory, L10n.current.deviceKernel, info.kernelVersion);
      
    } else if (Platform.isLinux) {
      final info = await deviceInfo.linuxInfo;
      addRow(Icons.terminal, L10n.current.deviceDistro, info.prettyName);
      addRow(Icons.build, L10n.current.deviceVersion, '${info.version ?? 'Unknown'} (${info.versionCodename ?? 'N/A'})');
      
    } else {
      addRow(Icons.help_outline, L10n.current.devicePlatform, Platform.operatingSystem);
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