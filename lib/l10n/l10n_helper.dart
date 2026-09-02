import 'app_localizations.dart';
import 'app_localizations_zh.dart';

/// 无 BuildContext 场景下的本地化取词器（服务层 / 通知 / 桌面悬浮窗）。
/// UI 构建期间由 MyApp 通过 [L10n.setCurrent] 同步当前语言，
/// UI 未就绪时回退到简体中文。
class L10n {
  static AppLocalizations _current = AppLocalizationsZhCn();

  static AppLocalizations get current => _current;

  static void setCurrent(AppLocalizations value) => _current = value;
}
