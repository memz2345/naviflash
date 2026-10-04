                                        
  
                                                       
                                                          
  
                                              
                                                                        
                                           
  
                                                               
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

                      
typedef TaskDialogLink = ({String text, String subtitle});

abstract final class WindowsTaskDialog {
  static const MethodChannel _channel = MethodChannel(
    'com.memz2345.navi.flash/task_dialog',
  );

                                                        
  @visibleForTesting
  static bool debugForceUnsupported = false;

                                  
  @visibleForTesting
  static Future<int?> Function(String heading, List<TaskDialogLink> links)?
  debugOpener;

  static bool get isSupported =>
      Platform.isWindows && !debugForceUnsupported;

                     
     
                                                       
  static Future<int?> show({
    required String title,
    required String heading,
    String? content,
    required List<TaskDialogLink> links,
  }) async {
    if (!isSupported || links.isEmpty) return null;
    final opener = debugOpener;
    if (opener != null) return opener(heading, links);
    try {
      final selected = await _channel.invokeMethod<int>('show', <String, Object?>{
        'title': title,
        'heading': heading,
        if (content != null && content.isNotEmpty) 'content': content,
        'links': <Map<String, String>>[
          for (final link in links)
            <String, String>{'text': link.text, 'subtitle': link.subtitle},
        ],
      });
      if (selected == null || selected < 0) return null;
      return selected;
    } on MissingPluginException {
      return null;
    } catch (e) {
      debugPrint('⚠️ 任务对话框调用失败: $e');
      return null;
    }
  }

                           
     
                                            
                                     
  static Future<bool> askTtsNotInstalled(AppLocalizations l10n) async {
    final selected = await show(
      title: l10n.ttsNoInstallTitle,
      heading: l10n.ttsNoInstallHeading,
      links: <TaskDialogLink>[
        (
          text: l10n.ttsNoInstallDownload,
          subtitle: l10n.ttsNoInstallDownloadSub,
        ),
        (text: l10n.ttsNoInstallLater, subtitle: l10n.ttsNoInstallLaterSub),
      ],
    );
    return selected == 0;
  }
}
