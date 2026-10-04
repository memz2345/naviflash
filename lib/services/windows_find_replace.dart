                                         
  
                                        
                                                              
                                                      
  
                                               
                                        
                                         
  
                                              
                                                 
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

abstract final class WindowsFindReplace {
  static const MethodChannel _channel = MethodChannel(
    'com.memz2345.navi.flash/find_replace',
  );

                                                         
  @visibleForTesting
  static bool debugForceUnsupported = false;

                                  
  @visibleForTesting
  static Future<List<String>?> Function(
    AppLocalizations l10n,
    List<String> rules,
  )? debugOpener;

  static bool get isSupported => Platform.isWindows && !debugForceUnsupported;

                                         
  static Future<List<String>?> show({
    required AppLocalizations l10n,
    required List<String> rules,
  }) async {
    if (!isSupported) return null;
    final opener = debugOpener;
    if (opener != null) return opener(l10n, rules);
    try {
      final result = await _channel.invokeMethod<List<Object?>>(
        'show',
        <String, Object?>{
          'title': l10n.ugcFilterWindowTitle,
          'find': l10n.ugcFilterFind,
          'replace': l10n.ugcFilterReplace,
          'resultPrefix': l10n.ugcFilterResultPrefix,
          'caseSensitive': 'Cc',
          'wholeWord': 'W',
          'regex': '.*',
          'prev': l10n.ugcFilterPrev,
          'next': l10n.ugcFilterNext,
          'replaceOne': l10n.ugcFilterReplaceOne,
          'replaceAll': l10n.ugcFilterReplaceAll,
          'deleteMatches': l10n.ugcFilterDeleteMatchesPlain,
          'ok': l10n.commonSave,
          'cancel': l10n.commonCancel,
          'rules': rules,
        },
      );
      if (result == null) return null;
      return result.whereType<String>().toList();
    } on MissingPluginException {
      return null;                                  
    } catch (_) {
      return null;
    }
  }
}
