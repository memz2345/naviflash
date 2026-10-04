                                               
  
                                             
                                              
                  
import 'package:flutter/foundation.dart';

                       
class SettingsSearchTarget {
                                     
  final int token;

                                                        
  final String pageRoute;

                                       
  final String? optionKey;

                 
  final String pageTitle;

                 
  final String optionName;

  const SettingsSearchTarget({
    required this.token,
    required this.pageRoute,
    this.optionKey,
    required this.pageTitle,
    required this.optionName,
  });
}

                         
class SettingsSearchController {
  SettingsSearchController._();

  static final ValueNotifier<SettingsSearchTarget?> current =
      ValueNotifier(null);

  static int _seq = 0;

                                 
  static void request({
    required String pageRoute,
    String? optionKey,
    required String pageTitle,
    required String optionName,
  }) {
    current.value = SettingsSearchTarget(
      token: ++_seq,
      pageRoute: pageRoute,
      optionKey: optionKey,
      pageTitle: pageTitle,
      optionName: optionName,
    );
  }

               
  static void clear() => current.value = null;
}
