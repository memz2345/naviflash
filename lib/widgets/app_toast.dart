                             
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/custom_toast.dart';

                                 
                          
   
                                                        
                                                                 
                           
                                                              
                                                     
                                                        
                    
   
                                     
                                      
void showAppToast(BuildContext context, String message, {bool error = false}) {
                                                         
  if (SettingsService.toastUseFluttertoastEnabled) {
    SmartDialog.showToast(
      message,
      builder: (_) => CustomToast(message, error: error),
    );
    return;
  }

                                                      
                                                             
                                                
  if (!kIsWeb && Platform.isAndroid) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      timeInSecForIosWeb: 2,
    );
    return;
  }

  _showSnackBarFallback(context, message, error: error);
}

                                             
void _showSnackBarFallback(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final cs = Theme.of(context).colorScheme;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? cs.error : cs.inverseSurface,
        duration: const Duration(seconds: 2),
        width:
            Platform.isWindows || Platform.isLinux || Platform.isMacOS
                ? 400.0
                : null,
      ),
    );
}
