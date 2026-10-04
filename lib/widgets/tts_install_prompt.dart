                                      
  
                        
                                           
                                         
                          
  
                                                   
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/windows_task_dialog.dart';
import 'app_toast.dart';

Future<bool> promptTtsNotInstalled(
  BuildContext context,
  AppLocalizations l10n,
) async {
  if (WindowsTaskDialog.isSupported) {
    return WindowsTaskDialog.askTtsNotInstalled(l10n);
  }
  showAppToast(context, l10n.ttsNeedInstall, error: true);
  return false;
}
