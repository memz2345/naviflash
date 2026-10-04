import 'app_localizations.dart';
import 'app_localizations_zh.dart';

                                                
                                               
                   
class L10n {
  static AppLocalizations _current = AppLocalizationsZhCn();

  static AppLocalizations get current => _current;

  static void setCurrent(AppLocalizations value) => _current = value;
}
