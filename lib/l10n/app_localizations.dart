import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'US'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'HK'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @metroDate.
  ///
  /// In zh_CN, this message translates to:
  /// **'{month}月{day}日'**
  String metroDate(int month, int day);

  /// No description provided for @metroSunday.
  ///
  /// In zh_CN, this message translates to:
  /// **'星期日'**
  String get metroSunday;

  /// No description provided for @metroMonday.
  ///
  /// In zh_CN, this message translates to:
  /// **'星期一'**
  String get metroMonday;

  /// No description provided for @metroTuesday.
  ///
  /// In zh_CN, this message translates to:
  /// **'星期二'**
  String get metroTuesday;

  /// No description provided for @metroWednesday.
  ///
  /// In zh_CN, this message translates to:
  /// **'星期三'**
  String get metroWednesday;

  /// No description provided for @metroThursday.
  ///
  /// In zh_CN, this message translates to:
  /// **'星期四'**
  String get metroThursday;

  /// No description provided for @metroFriday.
  ///
  /// In zh_CN, this message translates to:
  /// **'星期五'**
  String get metroFriday;

  /// No description provided for @metroSaturday.
  ///
  /// In zh_CN, this message translates to:
  /// **'星期六'**
  String get metroSaturday;

  /// No description provided for @metroLogin.
  ///
  /// In zh_CN, this message translates to:
  /// **'登录'**
  String get metroLogin;

  /// No description provided for @metroWelcome.
  ///
  /// In zh_CN, this message translates to:
  /// **'欢迎'**
  String get metroWelcome;

  /// No description provided for @imageViewerNoFile.
  ///
  /// In zh_CN, this message translates to:
  /// **'未找到图片文件'**
  String get imageViewerNoFile;

  /// No description provided for @syncPassphraseEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'同步口令不能为空'**
  String get syncPassphraseEmpty;

  /// No description provided for @imageBytesRequired.
  ///
  /// In zh_CN, this message translates to:
  /// **'imageUrl 或 imageBytes 必须提供其一'**
  String get imageBytesRequired;

  /// No description provided for @webdavConnectSuccess.
  ///
  /// In zh_CN, this message translates to:
  /// **'✅ 连接成功！'**
  String get webdavConnectSuccess;

  /// No description provided for @webdavConfigSaved.
  ///
  /// In zh_CN, this message translates to:
  /// **'配置已保存'**
  String get webdavConfigSaved;

  /// No description provided for @webdavConfigureFirst.
  ///
  /// In zh_CN, this message translates to:
  /// **'请先配置并测试 WebDAV 连接'**
  String get webdavConfigureFirst;

  /// No description provided for @webdavSelectContactsFirst.
  ///
  /// In zh_CN, this message translates to:
  /// **'请先在下方选择要备份的联系人'**
  String get webdavSelectContactsFirst;

  /// No description provided for @webdavNoFiles.
  ///
  /// In zh_CN, this message translates to:
  /// **'选中的联系人没有可备份的文件'**
  String get webdavNoFiles;

  /// No description provided for @webdavConfirmBackup.
  ///
  /// In zh_CN, this message translates to:
  /// **'确认备份'**
  String get webdavConfirmBackup;

  /// No description provided for @webdavBackupConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'将备份 {contacts} 位联系人的 {files} 个文件到 WebDAV 服务器。\n远程路径：{path}/chats/<昵称>/'**
  String webdavBackupConfirm(int contacts, int files, String path);

  /// No description provided for @webdavStartBackup.
  ///
  /// In zh_CN, this message translates to:
  /// **'开始备份'**
  String get webdavStartBackup;

  /// No description provided for @webdavBackingUpTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在备份'**
  String get webdavBackingUpTitle;

  /// No description provided for @webdavBackupDoneTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'备份完成'**
  String get webdavBackupDoneTitle;

  /// No description provided for @webdavTotalFiles.
  ///
  /// In zh_CN, this message translates to:
  /// **'总计：{count} 个文件'**
  String webdavTotalFiles(int count);

  /// No description provided for @webdavSuccessCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'成功：{count}'**
  String webdavSuccessCount(int count);

  /// No description provided for @webdavFailCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'失败：{count}'**
  String webdavFailCount(int count);

  /// No description provided for @webdavMoreErrors.
  ///
  /// In zh_CN, this message translates to:
  /// **'...还有 {count} 个错误'**
  String webdavMoreErrors(int count);

  /// No description provided for @webdavBackupFab.
  ///
  /// In zh_CN, this message translates to:
  /// **'备份'**
  String get webdavBackupFab;

  /// No description provided for @webdavShowInfo.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示我的信息'**
  String get webdavShowInfo;

  /// No description provided for @webdavHideInfo.
  ///
  /// In zh_CN, this message translates to:
  /// **'隐藏我的信息'**
  String get webdavHideInfo;

  /// No description provided for @webdavScanToFill.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫码填入服务器地址'**
  String get webdavScanToFill;

  /// No description provided for @webdavScanFilled.
  ///
  /// In zh_CN, this message translates to:
  /// **'已通过扫码填入地址'**
  String get webdavScanFilled;

  /// No description provided for @webdavServerConfig.
  ///
  /// In zh_CN, this message translates to:
  /// **'服务器配置'**
  String get webdavServerConfig;

  /// No description provided for @webdavServerUrlLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'服务器地址'**
  String get webdavServerUrlLabel;

  /// No description provided for @webdavUsernameLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'用户名'**
  String get webdavUsernameLabel;

  /// No description provided for @webdavPasswordLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'密码'**
  String get webdavPasswordLabel;

  /// No description provided for @webdavRemotePathLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'远程备份路径'**
  String get webdavRemotePathLabel;

  /// No description provided for @webdavTesting.
  ///
  /// In zh_CN, this message translates to:
  /// **'测试中...'**
  String get webdavTesting;

  /// No description provided for @webdavSaveAndTest.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存并测试连接'**
  String get webdavSaveAndTest;

  /// No description provided for @webdavSaveOnly.
  ///
  /// In zh_CN, this message translates to:
  /// **'仅保存'**
  String get webdavSaveOnly;

  /// No description provided for @webdavConnectVerified.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接验证通过'**
  String get webdavConnectVerified;

  /// No description provided for @webdavAutoBackup.
  ///
  /// In zh_CN, this message translates to:
  /// **'自动备份'**
  String get webdavAutoBackup;

  /// No description provided for @webdavAutoBackupOnReceive.
  ///
  /// In zh_CN, this message translates to:
  /// **'接收文件时自动备份'**
  String get webdavAutoBackupOnReceive;

  /// No description provided for @webdavAutoBackupSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'仅对下方选中的联系人生效'**
  String get webdavAutoBackupSubtitle;

  /// No description provided for @webdavMediaSync.
  ///
  /// In zh_CN, this message translates to:
  /// **'媒体同步'**
  String get webdavMediaSync;

  /// No description provided for @webdavSyncPlaylists.
  ///
  /// In zh_CN, this message translates to:
  /// **'同步播放列表'**
  String get webdavSyncPlaylists;

  /// No description provided for @webdavSyncDanmaku.
  ///
  /// In zh_CN, this message translates to:
  /// **'同步弹幕'**
  String get webdavSyncDanmaku;

  /// No description provided for @webdavPassphraseEncrypted.
  ///
  /// In zh_CN, this message translates to:
  /// **'同步密码（AES-256 加密）'**
  String get webdavPassphraseEncrypted;

  /// No description provided for @webdavPassphrasePlain.
  ///
  /// In zh_CN, this message translates to:
  /// **'同步密码（留空 = 明文上传）'**
  String get webdavPassphrasePlain;

  /// No description provided for @webdavPassphraseHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写密码后播放列表将加密上传'**
  String get webdavPassphraseHint;

  /// No description provided for @webdavGeneratePassphrase.
  ///
  /// In zh_CN, this message translates to:
  /// **'生成随机密码'**
  String get webdavGeneratePassphrase;

  /// No description provided for @webdavMediaSyncHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放列表（含背景图）与弹幕保存到云端的独立目录（playlists/、danmaku/），不会与聊天备份混在一起。多个设备共用同一远程路径即可互相合并；播放列表可在播放列表页手动同步或从云端恢复。'**
  String get webdavMediaSyncHint;

  /// No description provided for @webdavEncryptionOn.
  ///
  /// In zh_CN, this message translates to:
  /// **'已启用加密：播放列表将以 AES-256-GCM 加密后上传（含内嵌的 WebDAV 鉴权信息），服务器无法读取内容。多台设备需填写相同密码才能解密。'**
  String get webdavEncryptionOn;

  /// No description provided for @webdavEncryptionOff.
  ///
  /// In zh_CN, this message translates to:
  /// **'未加密：播放列表（含内嵌的 WebDAV 鉴权信息）将明文上传，任何能读取服务器文件的人都能看到，不推荐。'**
  String get webdavEncryptionOff;

  /// No description provided for @webdavBackupContacts.
  ///
  /// In zh_CN, this message translates to:
  /// **'备份联系人'**
  String get webdavBackupContacts;

  /// No description provided for @webdavSelectedContacts.
  ///
  /// In zh_CN, this message translates to:
  /// **'已选 {selected} / {total} 位联系人'**
  String webdavSelectedContacts(int selected, int total);

  /// No description provided for @webdavSearchContacts.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索联系人或 IP...'**
  String get webdavSearchContacts;

  /// No description provided for @webdavDeselectAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'取消全选'**
  String get webdavDeselectAll;

  /// No description provided for @webdavFileCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 个文件'**
  String webdavFileCount(int count);

  /// No description provided for @webdavNoContacts.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无联系人'**
  String get webdavNoContacts;

  /// No description provided for @webdavNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'无匹配结果'**
  String get webdavNoMatch;

  /// No description provided for @webdavContactSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'{ip}  ·  {count} 个文件'**
  String webdavContactSubtitle(String ip, int count);

  /// No description provided for @webdavManage.
  ///
  /// In zh_CN, this message translates to:
  /// **'管理'**
  String get webdavManage;

  /// No description provided for @webdavLastSync.
  ///
  /// In zh_CN, this message translates to:
  /// **'上次同步'**
  String get webdavLastSync;

  /// No description provided for @webdavLastError.
  ///
  /// In zh_CN, this message translates to:
  /// **'最近错误'**
  String get webdavLastError;

  /// No description provided for @webdavClearConfig.
  ///
  /// In zh_CN, this message translates to:
  /// **'清除 WebDAV 配置'**
  String get webdavClearConfig;

  /// No description provided for @webdavClearConfigSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除所有服务器信息和凭据'**
  String get webdavClearConfigSubtitle;

  /// No description provided for @webdavUserLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'用户'**
  String get webdavUserLabel;

  /// No description provided for @webdavStatusActive.
  ///
  /// In zh_CN, this message translates to:
  /// **'{name}已激活'**
  String webdavStatusActive(String name);

  /// No description provided for @webdavStatusConfigured.
  ///
  /// In zh_CN, this message translates to:
  /// **'{name}已配置'**
  String webdavStatusConfigured(String name);

  /// No description provided for @webdavStatusNotConfigured.
  ///
  /// In zh_CN, this message translates to:
  /// **'未配置'**
  String get webdavStatusNotConfigured;

  /// No description provided for @webdavNotSynced.
  ///
  /// In zh_CN, this message translates to:
  /// **'尚未同步'**
  String get webdavNotSynced;

  /// No description provided for @webdavJustNow.
  ///
  /// In zh_CN, this message translates to:
  /// **'上次同步：刚刚'**
  String get webdavJustNow;

  /// No description provided for @webdavMinutesAgo.
  ///
  /// In zh_CN, this message translates to:
  /// **'上次同步：{minutes} 分钟前'**
  String webdavMinutesAgo(int minutes);

  /// No description provided for @webdavHoursAgo.
  ///
  /// In zh_CN, this message translates to:
  /// **'上次同步：{hours} 小时前'**
  String webdavHoursAgo(int hours);

  /// No description provided for @webdavSyncedDate.
  ///
  /// In zh_CN, this message translates to:
  /// **'上次同步：{month}月{day}日 {time}'**
  String webdavSyncedDate(int month, int day, String time);

  /// No description provided for @webdavPassphraseGenerated.
  ///
  /// In zh_CN, this message translates to:
  /// **'已生成同步密码并复制到剪贴板，请在其他设备上填入相同密码'**
  String get webdavPassphraseGenerated;

  /// No description provided for @webdavConfirmClear.
  ///
  /// In zh_CN, this message translates to:
  /// **'确认清除'**
  String get webdavConfirmClear;

  /// No description provided for @webdavClearConfirmText.
  ///
  /// In zh_CN, this message translates to:
  /// **'将删除所有 WebDAV 配置（服务器、凭据、联系人选择）。\n已上传的文件不受影响。'**
  String get webdavClearConfirmText;

  /// No description provided for @profileEditProfile.
  ///
  /// In zh_CN, this message translates to:
  /// **'编辑资料'**
  String get profileEditProfile;

  /// No description provided for @profileAccountSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'账户管理'**
  String get profileAccountSection;

  /// No description provided for @profileWebdavBackup.
  ///
  /// In zh_CN, this message translates to:
  /// **'WebDAV 备份'**
  String get profileWebdavBackup;

  /// No description provided for @profileWebdavLoggedIn.
  ///
  /// In zh_CN, this message translates to:
  /// **'{username} 已登录'**
  String profileWebdavLoggedIn(String username);

  /// No description provided for @profileNotLoggedIn.
  ///
  /// In zh_CN, this message translates to:
  /// **'未登录'**
  String get profileNotLoggedIn;

  /// No description provided for @profileAvatarSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'头像'**
  String get profileAvatarSection;

  /// No description provided for @profileChangeAvatar.
  ///
  /// In zh_CN, this message translates to:
  /// **'更换头像'**
  String get profileChangeAvatar;

  /// No description provided for @profileRemoveAvatar.
  ///
  /// In zh_CN, this message translates to:
  /// **'移除头像'**
  String get profileRemoveAvatar;

  /// No description provided for @profilePickFromGallery.
  ///
  /// In zh_CN, this message translates to:
  /// **'从相册选择图片'**
  String get profilePickFromGallery;

  /// No description provided for @profileRestoreDefaultAvatar.
  ///
  /// In zh_CN, this message translates to:
  /// **'恢复默认头像'**
  String get profileRestoreDefaultAvatar;

  /// No description provided for @profileSetBackground.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置背景'**
  String get profileSetBackground;

  /// No description provided for @profileBgSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'为侧边栏选择一张背景图'**
  String get profileBgSubtitle;

  /// No description provided for @profileRestoreDefault.
  ///
  /// In zh_CN, this message translates to:
  /// **'恢复默认'**
  String get profileRestoreDefault;

  /// No description provided for @profileBgRemoveSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'移除自定义背景，使用主题色渐变'**
  String get profileBgRemoveSubtitle;

  /// No description provided for @profileInfoSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'个人信息'**
  String get profileInfoSection;

  /// No description provided for @profileNicknameLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'昵称'**
  String get profileNicknameLabel;

  /// No description provided for @profileNotSet.
  ///
  /// In zh_CN, this message translates to:
  /// **'未设置'**
  String get profileNotSet;

  /// No description provided for @profileBgTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'个人资料背景'**
  String get profileBgTitle;

  /// No description provided for @profileAvatarUpdated.
  ///
  /// In zh_CN, this message translates to:
  /// **'✅ 头像已更新'**
  String get profileAvatarUpdated;

  /// No description provided for @profileAvatarFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'❌ 选择头像失败: {error}'**
  String profileAvatarFailed(String error);

  /// No description provided for @profileRemoveAvatarConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定要删除当前头像吗？此操作无法撤销。'**
  String get profileRemoveAvatarConfirm;

  /// No description provided for @profileAvatarRemoved.
  ///
  /// In zh_CN, this message translates to:
  /// **'头像已移除'**
  String get profileAvatarRemoved;

  /// No description provided for @profileSetNickname.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置昵称'**
  String get profileSetNickname;

  /// No description provided for @profileNicknameHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入昵称'**
  String get profileNicknameHint;

  /// No description provided for @profileNicknameEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'昵称不能为空'**
  String get profileNicknameEmpty;

  /// No description provided for @profileNicknameUpdated.
  ///
  /// In zh_CN, this message translates to:
  /// **'✅ 昵称已更新'**
  String get profileNicknameUpdated;

  /// No description provided for @colorDefaultGreen.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认绿'**
  String get colorDefaultGreen;

  /// No description provided for @colorPink.
  ///
  /// In zh_CN, this message translates to:
  /// **'粉红色'**
  String get colorPink;

  /// No description provided for @colorRed.
  ///
  /// In zh_CN, this message translates to:
  /// **'红色'**
  String get colorRed;

  /// No description provided for @colorOrange.
  ///
  /// In zh_CN, this message translates to:
  /// **'橙色'**
  String get colorOrange;

  /// No description provided for @colorAmber.
  ///
  /// In zh_CN, this message translates to:
  /// **'琥珀色'**
  String get colorAmber;

  /// No description provided for @colorYellow.
  ///
  /// In zh_CN, this message translates to:
  /// **'黄色'**
  String get colorYellow;

  /// No description provided for @colorLime.
  ///
  /// In zh_CN, this message translates to:
  /// **'酸橙色'**
  String get colorLime;

  /// No description provided for @colorLightGreen.
  ///
  /// In zh_CN, this message translates to:
  /// **'浅绿色'**
  String get colorLightGreen;

  /// No description provided for @colorGreen.
  ///
  /// In zh_CN, this message translates to:
  /// **'绿色'**
  String get colorGreen;

  /// No description provided for @colorCyan.
  ///
  /// In zh_CN, this message translates to:
  /// **'青色'**
  String get colorCyan;

  /// No description provided for @colorTeal.
  ///
  /// In zh_CN, this message translates to:
  /// **'蓝绿色'**
  String get colorTeal;

  /// No description provided for @colorLightBlue.
  ///
  /// In zh_CN, this message translates to:
  /// **'浅蓝色'**
  String get colorLightBlue;

  /// No description provided for @colorBlue.
  ///
  /// In zh_CN, this message translates to:
  /// **'蓝色'**
  String get colorBlue;

  /// No description provided for @colorIndigo.
  ///
  /// In zh_CN, this message translates to:
  /// **'靛蓝色'**
  String get colorIndigo;

  /// No description provided for @colorPurple.
  ///
  /// In zh_CN, this message translates to:
  /// **'紫色'**
  String get colorPurple;

  /// No description provided for @colorDeepPurple.
  ///
  /// In zh_CN, this message translates to:
  /// **'深紫色'**
  String get colorDeepPurple;

  /// No description provided for @colorBlueGrey.
  ///
  /// In zh_CN, this message translates to:
  /// **'蓝灰色'**
  String get colorBlueGrey;

  /// No description provided for @colorBrown.
  ///
  /// In zh_CN, this message translates to:
  /// **'棕色'**
  String get colorBrown;

  /// No description provided for @colorGrey.
  ///
  /// In zh_CN, this message translates to:
  /// **'灰色'**
  String get colorGrey;

  /// No description provided for @themeColorExtracted.
  ///
  /// In zh_CN, this message translates to:
  /// **'已从图片提取主题色'**
  String get themeColorExtracted;

  /// No description provided for @themeColorFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'取色失败: {error}'**
  String themeColorFailed(String error);

  /// No description provided for @themeImageOnly.
  ///
  /// In zh_CN, this message translates to:
  /// **'仅支持图片格式'**
  String get themeImageOnly;

  /// No description provided for @themeTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题'**
  String get themeTitle;

  /// No description provided for @themeColorCopied.
  ///
  /// In zh_CN, this message translates to:
  /// **'已复制色号: {hex}'**
  String themeColorCopied(String hex);

  /// No description provided for @themeAppearance.
  ///
  /// In zh_CN, this message translates to:
  /// **'外观'**
  String get themeAppearance;

  /// No description provided for @themeDarkBlackened.
  ///
  /// In zh_CN, this message translates to:
  /// **'深色模式（已黑化）'**
  String get themeDarkBlackened;

  /// No description provided for @themeOff.
  ///
  /// In zh_CN, this message translates to:
  /// **'已关闭'**
  String get themeOff;

  /// No description provided for @themeEnabled.
  ///
  /// In zh_CN, this message translates to:
  /// **'已启用'**
  String get themeEnabled;

  /// No description provided for @themeColorsSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'配色'**
  String get themeColorsSection;

  /// No description provided for @themePaletteStyle.
  ///
  /// In zh_CN, this message translates to:
  /// **'调色板风格'**
  String get themePaletteStyle;

  /// No description provided for @themeFollowSystem.
  ///
  /// In zh_CN, this message translates to:
  /// **'跟随系统配色'**
  String get themeFollowSystem;

  /// No description provided for @themePickColor.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择颜色'**
  String get themePickColor;

  /// No description provided for @themeDropHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'松开以从图片提取主题色'**
  String get themeDropHint;

  /// No description provided for @themeNewTheme.
  ///
  /// In zh_CN, this message translates to:
  /// **'新建主题'**
  String get themeNewTheme;

  /// No description provided for @themeSwitched.
  ///
  /// In zh_CN, this message translates to:
  /// **'已切换至 {name} 主题'**
  String themeSwitched(String name);

  /// No description provided for @themeDeleteTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除主题'**
  String get themeDeleteTitle;

  /// No description provided for @themeDeleteConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定要删除自定义主题 \"{name}\" 吗？'**
  String themeDeleteConfirm(String name);

  /// No description provided for @themeDeleted.
  ///
  /// In zh_CN, this message translates to:
  /// **'已删除 \"{name}\"'**
  String themeDeleted(String name);

  /// No description provided for @themeCreateTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'创建自定义主题'**
  String get themeCreateTitle;

  /// No description provided for @themeNameLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题名称'**
  String get themeNameLabel;

  /// No description provided for @themeNameHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'请输入文本'**
  String get themeNameHint;

  /// No description provided for @themeHexLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'十六进制/RGB'**
  String get themeHexLabel;

  /// No description provided for @themeHexHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 #FF0000 或 255,0,0'**
  String get themeHexHint;

  /// No description provided for @themeCreated.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题 \"{name}\" 已创建并保存'**
  String themeCreated(String name);

  /// No description provided for @themeCopyColor.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制色号'**
  String get themeCopyColor;

  /// No description provided for @themePickFromImage.
  ///
  /// In zh_CN, this message translates to:
  /// **'从图片取色'**
  String get themePickFromImage;

  /// No description provided for @searchBack.
  ///
  /// In zh_CN, this message translates to:
  /// **'返回设置'**
  String get searchBack;

  /// No description provided for @searchHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索设置项…'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入关键词搜索设置项'**
  String get searchPrompt;

  /// No description provided for @searchExamples.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如: 刷新率 / 解码 / UA / 弹幕'**
  String get searchExamples;

  /// No description provided for @searchNoResults.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有找到「{query}」相关设置'**
  String searchNoResults(String query);

  /// No description provided for @searchThemeMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题模式'**
  String get searchThemeMode;

  /// No description provided for @searchPureBlack.
  ///
  /// In zh_CN, this message translates to:
  /// **'纯黑深色模式'**
  String get searchPureBlack;

  /// No description provided for @searchThemeColor.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题配色'**
  String get searchThemeColor;

  /// No description provided for @searchFontWeight.
  ///
  /// In zh_CN, this message translates to:
  /// **'文字粗细'**
  String get searchFontWeight;

  /// No description provided for @searchDisplayScale.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示缩放'**
  String get searchDisplayScale;

  /// No description provided for @searchDisplayMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示模式 / 屏幕刷新率'**
  String get searchDisplayMode;

  /// No description provided for @searchStatusBar.
  ///
  /// In zh_CN, this message translates to:
  /// **'状态栏'**
  String get searchStatusBar;

  /// No description provided for @searchKeepWindowRatio.
  ///
  /// In zh_CN, this message translates to:
  /// **'等比例拉伸窗口'**
  String get searchKeepWindowRatio;

  /// No description provided for @searchLongPressSpeed.
  ///
  /// In zh_CN, this message translates to:
  /// **'长按键加速'**
  String get searchLongPressSpeed;

  /// No description provided for @searchScreenshot.
  ///
  /// In zh_CN, this message translates to:
  /// **'截图功能'**
  String get searchScreenshot;

  /// No description provided for @searchScreenshotDanmaku.
  ///
  /// In zh_CN, this message translates to:
  /// **'截图时显示弹幕'**
  String get searchScreenshotDanmaku;

  /// No description provided for @searchPlayProgress.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放进度'**
  String get searchPlayProgress;

  /// No description provided for @searchHwdec.
  ///
  /// In zh_CN, this message translates to:
  /// **'硬件解码'**
  String get searchHwdec;

  /// No description provided for @searchVideoSync.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频同步'**
  String get searchVideoSync;

  /// No description provided for @searchImmersiveLongPress.
  ///
  /// In zh_CN, this message translates to:
  /// **'沉浸模式长按加速'**
  String get searchImmersiveLongPress;

  /// No description provided for @searchMpvLog.
  ///
  /// In zh_CN, this message translates to:
  /// **'记录 mpv 日志'**
  String get searchMpvLog;

  /// No description provided for @searchMpvLogLevel.
  ///
  /// In zh_CN, this message translates to:
  /// **'mpv 日志细度'**
  String get searchMpvLogLevel;

  /// No description provided for @searchNetworkMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'网络模式'**
  String get searchNetworkMode;

  /// No description provided for @searchInsecureCert.
  ///
  /// In zh_CN, this message translates to:
  /// **'允许不安全证书'**
  String get searchInsecureCert;

  /// No description provided for @searchChatIpv6.
  ///
  /// In zh_CN, this message translates to:
  /// **'聊天 IPv6'**
  String get searchChatIpv6;

  /// No description provided for @searchConnectivityTest.
  ///
  /// In zh_CN, this message translates to:
  /// **'连通性测试'**
  String get searchConnectivityTest;

  /// No description provided for @searchHostOverrides.
  ///
  /// In zh_CN, this message translates to:
  /// **'Host 映射'**
  String get searchHostOverrides;

  /// No description provided for @searchDohQuery.
  ///
  /// In zh_CN, this message translates to:
  /// **'DoH 查询'**
  String get searchDohQuery;

  /// No description provided for @searchReferer.
  ///
  /// In zh_CN, this message translates to:
  /// **'请求头 Referer'**
  String get searchReferer;

  /// No description provided for @searchUserAgent.
  ///
  /// In zh_CN, this message translates to:
  /// **'请求头 User-Agent'**
  String get searchUserAgent;

  /// No description provided for @searchSystemSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'系统设置'**
  String get searchSystemSettings;

  /// No description provided for @searchUserSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'用户设置'**
  String get searchUserSettings;

  /// No description provided for @settingsDisplaySub.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题、字体、布局'**
  String get settingsDisplaySub;

  /// No description provided for @settingsSystem.
  ///
  /// In zh_CN, this message translates to:
  /// **'系统'**
  String get settingsSystem;

  /// No description provided for @settingsSystemSub.
  ///
  /// In zh_CN, this message translates to:
  /// **'语言、存储、权限'**
  String get settingsSystemSub;

  /// No description provided for @settingsStorage.
  ///
  /// In zh_CN, this message translates to:
  /// **'存储'**
  String get settingsStorage;

  /// No description provided for @settingsStorageSub.
  ///
  /// In zh_CN, this message translates to:
  /// **'图片缓存、弹幕缓存'**
  String get settingsStorageSub;

  /// No description provided for @settingsNetwork.
  ///
  /// In zh_CN, this message translates to:
  /// **'网络'**
  String get settingsNetwork;

  /// No description provided for @settingsNetworkSub.
  ///
  /// In zh_CN, this message translates to:
  /// **'Wi-Fi、代理、同步'**
  String get settingsNetworkSub;

  /// No description provided for @settingsLanguage.
  ///
  /// In zh_CN, this message translates to:
  /// **'语言'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSub.
  ///
  /// In zh_CN, this message translates to:
  /// **'应用语言、B 站翻译（AI 翻译）'**
  String get settingsLanguageSub;

  /// No description provided for @appLangSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'应用语言'**
  String get appLangSection;

  /// No description provided for @appLangFollowSystem.
  ///
  /// In zh_CN, this message translates to:
  /// **'跟随系统'**
  String get appLangFollowSystem;

  /// No description provided for @biliLangSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'翻译目标语言'**
  String get biliLangSection;

  /// No description provided for @biliAiSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'AI 翻译'**
  String get biliAiSection;

  /// No description provided for @biliAiTranslateEnable.
  ///
  /// In zh_CN, this message translates to:
  /// **'启用 AI 翻译'**
  String get biliAiTranslateEnable;

  /// No description provided for @biliAiTranslateOnDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'已开启：B 站请求将携带翻译头，返回该语言内容'**
  String get biliAiTranslateOnDesc;

  /// No description provided for @biliAiTranslateOffDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'关闭：按原始语言返回内容'**
  String get biliAiTranslateOffDesc;

  /// No description provided for @langZhCn.
  ///
  /// In zh_CN, this message translates to:
  /// **'简体中文'**
  String get langZhCn;

  /// No description provided for @langZhHk.
  ///
  /// In zh_CN, this message translates to:
  /// **'繁體中文（香港）'**
  String get langZhHk;

  /// No description provided for @langZhTw.
  ///
  /// In zh_CN, this message translates to:
  /// **'繁體中文（台灣）'**
  String get langZhTw;

  /// No description provided for @langEnUs.
  ///
  /// In zh_CN, this message translates to:
  /// **'English（英語）'**
  String get langEnUs;

  /// No description provided for @langJaJp.
  ///
  /// In zh_CN, this message translates to:
  /// **'日本語'**
  String get langJaJp;

  /// No description provided for @langKoKr.
  ///
  /// In zh_CN, this message translates to:
  /// **'한국어'**
  String get langKoKr;

  /// No description provided for @settingsPlayer.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放器'**
  String get settingsPlayer;

  /// No description provided for @settingsPlayerSub.
  ///
  /// In zh_CN, this message translates to:
  /// **'状态栏、加速、截图'**
  String get settingsPlayerSub;

  /// No description provided for @settingsStartScreenSub.
  ///
  /// In zh_CN, this message translates to:
  /// **'开始屏幕、Charm'**
  String get settingsStartScreenSub;

  /// No description provided for @settingsLogs.
  ///
  /// In zh_CN, this message translates to:
  /// **'日志'**
  String get settingsLogs;

  /// No description provided for @settingsLogsSub.
  ///
  /// In zh_CN, this message translates to:
  /// **'错误日志、mpv 日志'**
  String get settingsLogsSub;

  /// No description provided for @settingsAccounts.
  ///
  /// In zh_CN, this message translates to:
  /// **'账号'**
  String get settingsAccounts;

  /// No description provided for @settingsAccountsSub.
  ///
  /// In zh_CN, this message translates to:
  /// **'B 站、WebDAV'**
  String get settingsAccountsSub;

  /// No description provided for @settingsUser.
  ///
  /// In zh_CN, this message translates to:
  /// **'用户'**
  String get settingsUser;

  /// No description provided for @settingsUserSub.
  ///
  /// In zh_CN, this message translates to:
  /// **'账户、隐私、安全'**
  String get settingsUserSub;

  /// No description provided for @settingsAboutSub.
  ///
  /// In zh_CN, this message translates to:
  /// **'版本、许可证'**
  String get settingsAboutSub;

  /// No description provided for @settingsLicenses.
  ///
  /// In zh_CN, this message translates to:
  /// **'开源许可'**
  String get settingsLicenses;

  /// No description provided for @settingsLicensesSub.
  ///
  /// In zh_CN, this message translates to:
  /// **'本项目引用的开源项目'**
  String get settingsLicensesSub;

  /// No description provided for @settingsSearch.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索设置'**
  String get settingsSearch;

  /// No description provided for @openSidebar.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开侧边栏'**
  String get openSidebar;

  /// No description provided for @settingsPlaceholderEasterEgg.
  ///
  /// In zh_CN, this message translates to:
  /// **'唔,有什么问题为什么不问问神奇的芙莉莲呢'**
  String get settingsPlaceholderEasterEgg;

  /// No description provided for @storageClearTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'清理{label}'**
  String storageClearTitle(String label);

  /// No description provided for @storageClearConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定要清理{label}吗？清理后重新浏览图片会再次下载。'**
  String storageClearConfirm(String label);

  /// No description provided for @storageClear.
  ///
  /// In zh_CN, this message translates to:
  /// **'清理'**
  String get storageClear;

  /// No description provided for @storageCleared.
  ///
  /// In zh_CN, this message translates to:
  /// **'{label}已清理'**
  String storageCleared(String label);

  /// No description provided for @refreshAction.
  ///
  /// In zh_CN, this message translates to:
  /// **'刷新'**
  String get refreshAction;

  /// No description provided for @storageCacheSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'缓存'**
  String get storageCacheSection;

  /// No description provided for @storageImageCache.
  ///
  /// In zh_CN, this message translates to:
  /// **'图片缓存'**
  String get storageImageCache;

  /// No description provided for @storageCounting.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在统计…'**
  String get storageCounting;

  /// No description provided for @storageFileCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 个文件 · {size}'**
  String storageFileCount(int count, String size);

  /// No description provided for @storageDanmakuCache.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕缓存'**
  String get storageDanmakuCache;

  /// No description provided for @storageVideoCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 个视频 · {size}'**
  String storageVideoCount(int count, String size);

  /// 存储设置页开关：自动离线缓存播放过的视频
  ///
  /// In zh_CN, this message translates to:
  /// **'自动离线缓存播放过的视频'**
  String get settingsAutoOfflineCache;

  /// 自动离线缓存开关的说明文字
  ///
  /// In zh_CN, this message translates to:
  /// **'观看过的视频会自动下载到本地（约 2GB 上限，超出自动淘汰最旧），下次打开直接从本地播放、不再重复拉取；关闭后不再新增缓存。'**
  String get settingsAutoOfflineCacheHint;

  /// 存储设置页离线视频缓存行标题
  ///
  /// In zh_CN, this message translates to:
  /// **'离线视频缓存'**
  String get storageVideoCache;

  /// 离线视频缓存行的说明文字
  ///
  /// In zh_CN, this message translates to:
  /// **'播放过的视频媒体流（容量上限内自动缓存、LRU 淘汰），下次打开直接从本地播放'**
  String get storageVideoCacheDesc;

  /// No description provided for @storageMemoryCache.
  ///
  /// In zh_CN, this message translates to:
  /// **'内存图片缓存'**
  String get storageMemoryCache;

  /// No description provided for @storageMemoryCacheDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'本次运行中已解码的图片，退出后自动释放'**
  String get storageMemoryCacheDesc;

  /// No description provided for @storageClearing.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在清理…'**
  String get storageClearing;

  /// No description provided for @storageClearAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'一键清理全部缓存'**
  String get storageClearAll;

  /// No description provided for @storageCacheHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'图片缓存为应用私有目录（image_cache），清理后浏览过的评论配图会重新下载；弹幕缓存用于离线弹幕加载。'**
  String get storageCacheHint;

  /// No description provided for @storageClearAllTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'清理全部缓存'**
  String get storageClearAllTitle;

  /// No description provided for @storageClearAllConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'将清空图片缓存、弹幕缓存与内存图片缓存，清理后重新浏览图片会再次下载。'**
  String get storageClearAllConfirm;

  /// No description provided for @storageAllCleared.
  ///
  /// In zh_CN, this message translates to:
  /// **'缓存已全部清理'**
  String get storageAllCleared;

  /// No description provided for @verificationPendingRequests.
  ///
  /// In zh_CN, this message translates to:
  /// **'待处理请求'**
  String get verificationPendingRequests;

  /// No description provided for @verificationNoPending.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无待处理请求'**
  String get verificationNoPending;

  /// No description provided for @verificationIpAddress.
  ///
  /// In zh_CN, this message translates to:
  /// **'IP 地址：{ip}'**
  String verificationIpAddress(String ip);

  /// No description provided for @verificationNickname.
  ///
  /// In zh_CN, this message translates to:
  /// **'昵称：{name}'**
  String verificationNickname(String name);

  /// No description provided for @verificationRequestTime.
  ///
  /// In zh_CN, this message translates to:
  /// **'请求时间：{time}'**
  String verificationRequestTime(String time);

  /// No description provided for @verificationRejectInvalid.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法拒绝：IP 地址无效'**
  String get verificationRejectInvalid;

  /// No description provided for @verificationRejected.
  ///
  /// In zh_CN, this message translates to:
  /// **'已拒绝连接请求'**
  String get verificationRejected;

  /// No description provided for @verificationReject.
  ///
  /// In zh_CN, this message translates to:
  /// **'拒绝'**
  String get verificationReject;

  /// No description provided for @verificationAcceptInvalid.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法接受：IP 地址无效'**
  String get verificationAcceptInvalid;

  /// No description provided for @verificationAccepted.
  ///
  /// In zh_CN, this message translates to:
  /// **'已接受连接请求'**
  String get verificationAccepted;

  /// No description provided for @verificationAccept.
  ///
  /// In zh_CN, this message translates to:
  /// **'同意'**
  String get verificationAccept;

  /// No description provided for @startScreenWarning.
  ///
  /// In zh_CN, this message translates to:
  /// **'我们可能不再更新此项目'**
  String get startScreenWarning;

  /// No description provided for @startScreenTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'开始屏幕'**
  String get startScreenTitle;

  /// No description provided for @startScreenGoBack.
  ///
  /// In zh_CN, this message translates to:
  /// **'转到上一层级'**
  String get startScreenGoBack;

  /// No description provided for @enableStartScreen.
  ///
  /// In zh_CN, this message translates to:
  /// **'启用开始屏幕'**
  String get enableStartScreen;

  /// No description provided for @startScreenEnableSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'允许从 Charm 的 Start 按钮进入开始屏幕'**
  String get startScreenEnableSubtitle;

  /// No description provided for @enableCharm.
  ///
  /// In zh_CN, this message translates to:
  /// **'启用 Charm'**
  String get enableCharm;

  /// No description provided for @charmEnableSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'在屏幕右侧提供 Charm 快捷栏'**
  String get charmEnableSubtitle;

  /// No description provided for @charmGestureTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'手势拉出 Charm'**
  String get charmGestureTitle;

  /// No description provided for @charmGestureSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'从屏幕右边缘向左滑动或悬停右上角拉出 Charm'**
  String get charmGestureSubtitle;

  /// No description provided for @externalVideo.
  ///
  /// In zh_CN, this message translates to:
  /// **'外部视频'**
  String get externalVideo;

  /// No description provided for @audioChannelName.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频媒体播放'**
  String get audioChannelName;

  /// No description provided for @foregroundChannelName.
  ///
  /// In zh_CN, this message translates to:
  /// **'Navi 保活'**
  String get foregroundChannelName;

  /// No description provided for @foregroundChannelDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'主人~保持我后台运行~'**
  String get foregroundChannelDesc;

  /// No description provided for @foregroundTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'保活中'**
  String get foregroundTitle;

  /// No description provided for @foregroundText.
  ///
  /// In zh_CN, this message translates to:
  /// **'我验牌'**
  String get foregroundText;

  /// No description provided for @drawerBilibiliSearch.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索'**
  String get drawerBilibiliSearch;

  /// No description provided for @commentImageLoadFail.
  ///
  /// In zh_CN, this message translates to:
  /// **'图片加载失败'**
  String get commentImageLoadFail;

  /// No description provided for @commentDetailTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'评论详情'**
  String get commentDetailTitle;

  /// No description provided for @commentLikeLoginRequired.
  ///
  /// In zh_CN, this message translates to:
  /// **'请先登录 B 站账号（并开启携带 Cookie）后再点赞'**
  String get commentLikeLoginRequired;

  /// No description provided for @commentLikeFail.
  ///
  /// In zh_CN, this message translates to:
  /// **'点赞失败：{error}'**
  String commentLikeFail(String error);

  /// No description provided for @relatedEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无相关推荐'**
  String get relatedEmpty;

  /// No description provided for @biliLoadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'加载失败'**
  String get biliLoadFailed;

  /// No description provided for @countWan.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count}万'**
  String countWan(String count);

  /// No description provided for @countYi.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count}亿'**
  String countYi(String count);

  /// No description provided for @searchNoNewContent.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无新内容'**
  String get searchNoNewContent;

  /// No description provided for @searchNewContentRefreshed.
  ///
  /// In zh_CN, this message translates to:
  /// **'已为您刷新一组新内容'**
  String get searchNewContentRefreshed;

  /// No description provided for @biliDialogNeedLogin.
  ///
  /// In zh_CN, this message translates to:
  /// **'需要登录'**
  String get biliDialogNeedLogin;

  /// No description provided for @biliDialogInteractDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'点赞 / 投币 / 三连等互动需要登录 B 站账号'**
  String get biliDialogInteractDesc;

  /// No description provided for @biliGoLogin.
  ///
  /// In zh_CN, this message translates to:
  /// **'去登录'**
  String get biliGoLogin;

  /// No description provided for @biliCookieScopeHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'请在账号设置中开启「携带 Cookie 请求」与「互动操作」范围'**
  String get biliCookieScopeHint;

  /// No description provided for @videoTabRelated.
  ///
  /// In zh_CN, this message translates to:
  /// **'相关视频'**
  String get videoTabRelated;

  /// No description provided for @videoTabComments.
  ///
  /// In zh_CN, this message translates to:
  /// **'评论'**
  String get videoTabComments;

  /// No description provided for @videoTabCommentsCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'评论 {count}'**
  String videoTabCommentsCount(int count);

  /// No description provided for @videoTabEpisodes.
  ///
  /// In zh_CN, this message translates to:
  /// **'选集 {count}'**
  String videoTabEpisodes(int count);

  /// No description provided for @videoTabIntro.
  ///
  /// In zh_CN, this message translates to:
  /// **'简介'**
  String get videoTabIntro;

  /// No description provided for @danmakuWatching.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count}人正在看'**
  String danmakuWatching(String count);

  /// No description provided for @danmakuLoadedBar.
  ///
  /// In zh_CN, this message translates to:
  /// **'已装填{count}条弹幕'**
  String danmakuLoadedBar(String count);

  /// No description provided for @danmakuToggleOn.
  ///
  /// In zh_CN, this message translates to:
  /// **'开启弹幕'**
  String get danmakuToggleOn;

  /// No description provided for @danmakuDisable.
  ///
  /// In zh_CN, this message translates to:
  /// **'关闭弹幕'**
  String get danmakuDisable;

  /// No description provided for @danmakuInputHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'发个友善的弹幕见证当下'**
  String get danmakuInputHint;

  /// No description provided for @danmakuToastEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕内容不能为空'**
  String get danmakuToastEmpty;

  /// No description provided for @danmakuToastSendFail.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送失败：{error}'**
  String danmakuToastSendFail(String error);

  /// No description provided for @danmakuToastSent.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕已发送'**
  String get danmakuToastSent;

  /// No description provided for @videoLikeTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'点赞（长按一键三连）'**
  String get videoLikeTooltip;

  /// No description provided for @videoUnlikeTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'取消点赞'**
  String get videoUnlikeTooltip;

  /// No description provided for @videoCoinTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'投币'**
  String get videoCoinTooltip;

  /// No description provided for @videoFavTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'收藏'**
  String get videoFavTooltip;

  /// No description provided for @videoUnfavTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'取消收藏'**
  String get videoUnfavTooltip;

  /// No description provided for @videoShareLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'分享'**
  String get videoShareLabel;

  /// No description provided for @videoStatRating.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count}人评分'**
  String videoStatRating(String count);

  /// No description provided for @videoStatFollowing.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count}追番'**
  String videoStatFollowing(String count);

  /// No description provided for @videoStatWatching.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count}人在看'**
  String videoStatWatching(String count);

  /// No description provided for @videoFollowLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'关注'**
  String get videoFollowLabel;

  /// No description provided for @videoFollowedLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'已关注'**
  String get videoFollowedLabel;

  /// No description provided for @commentDetailEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'还没有回复'**
  String get commentDetailEmpty;

  /// No description provided for @commentDetailNoMore.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有更多回复了（共 {count} 条）'**
  String commentDetailNoMore(int count);

  /// No description provided for @commentDetailLoadMore.
  ///
  /// In zh_CN, this message translates to:
  /// **'滑动加载更多'**
  String get commentDetailLoadMore;

  /// No description provided for @commentDetailRootBadge.
  ///
  /// In zh_CN, this message translates to:
  /// **'楼主'**
  String get commentDetailRootBadge;

  /// No description provided for @commentDetailDeleted.
  ///
  /// In zh_CN, this message translates to:
  /// **'(评论已删除)'**
  String get commentDetailDeleted;

  /// No description provided for @commentMenuCopy.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制评论'**
  String get commentMenuCopy;

  /// No description provided for @commentMenuSelectText.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择文本'**
  String get commentMenuSelectText;

  /// No description provided for @commentDialogTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'评论内容'**
  String get commentDialogTitle;

  /// No description provided for @commentDialogEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'(这里空空的)'**
  String get commentDialogEmpty;

  /// No description provided for @danmakuInputBvPrompt.
  ///
  /// In zh_CN, this message translates to:
  /// **'请输入 BV 号'**
  String get danmakuInputBvPrompt;

  /// No description provided for @danmakuInputCidPrompt.
  ///
  /// In zh_CN, this message translates to:
  /// **'请输入 CID'**
  String get danmakuInputCidPrompt;

  /// No description provided for @danmakuInputCidNumeric.
  ///
  /// In zh_CN, this message translates to:
  /// **'CID 必须为纯数字'**
  String get danmakuInputCidNumeric;

  /// No description provided for @danmakuInputCacheHit.
  ///
  /// In zh_CN, this message translates to:
  /// **'命中本地缓存：{count} 条弹幕 (oid={oid})'**
  String danmakuInputCacheHit(int count, String oid);

  /// No description provided for @danmakuInputFetchSuccess.
  ///
  /// In zh_CN, this message translates to:
  /// **'获取成功：{count} 条弹幕 (oid={oid})'**
  String danmakuInputFetchSuccess(int count, String oid);

  /// No description provided for @danmakuInputFetchFail.
  ///
  /// In zh_CN, this message translates to:
  /// **'获取失败'**
  String get danmakuInputFetchFail;

  /// No description provided for @danmakuInputTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'Bilibili 弹幕'**
  String get danmakuInputTitle;

  /// No description provided for @danmakuInputTypeLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'类型：'**
  String get danmakuInputTypeLabel;

  /// No description provided for @danmakuInputBvHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入 BV 号，将自动获取第一个分P的 CID'**
  String get danmakuInputBvHint;

  /// No description provided for @danmakuInputCidHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'直接输入 CID 纯数字（如从 API 获取）'**
  String get danmakuInputCidHint;

  /// No description provided for @danmakuInputFetching.
  ///
  /// In zh_CN, this message translates to:
  /// **'获取中...'**
  String get danmakuInputFetching;

  /// No description provided for @danmakuInputFetchDanmaku.
  ///
  /// In zh_CN, this message translates to:
  /// **'获取弹幕'**
  String get danmakuInputFetchDanmaku;

  /// No description provided for @danmakuInputEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入不能为空'**
  String get danmakuInputEmpty;

  /// No description provided for @danmakuCidFetchFail.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法获取 CID，请检查 BV 号'**
  String get danmakuCidFetchFail;

  /// No description provided for @danmakuNoData.
  ///
  /// In zh_CN, this message translates to:
  /// **'未获取到弹幕数据（oid={oid}）'**
  String danmakuNoData(String oid);

  /// No description provided for @danmakuSettingsTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕设置'**
  String get danmakuSettingsTitle;

  /// No description provided for @danmakuDataSource.
  ///
  /// In zh_CN, this message translates to:
  /// **'数据源'**
  String get danmakuDataSource;

  /// No description provided for @danmakuDisplayControl.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示控制'**
  String get danmakuDisplayControl;

  /// No description provided for @danmakuEnable.
  ///
  /// In zh_CN, this message translates to:
  /// **'启用弹幕'**
  String get danmakuEnable;

  /// No description provided for @danmakuSmartMask.
  ///
  /// In zh_CN, this message translates to:
  /// **'智能防遮挡'**
  String get danmakuSmartMask;

  /// No description provided for @danmakuSmartMaskDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'识别人物，弹幕不遮挡画面主体'**
  String get danmakuSmartMaskDesc;

  /// No description provided for @danmakuTypeFilter.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕类型'**
  String get danmakuTypeFilter;

  /// No description provided for @danmakuTypeScroll.
  ///
  /// In zh_CN, this message translates to:
  /// **'滚动弹幕'**
  String get danmakuTypeScroll;

  /// No description provided for @danmakuTypeTop.
  ///
  /// In zh_CN, this message translates to:
  /// **'顶部弹幕'**
  String get danmakuTypeTop;

  /// No description provided for @danmakuTypeBottom.
  ///
  /// In zh_CN, this message translates to:
  /// **'底部弹幕'**
  String get danmakuTypeBottom;

  /// No description provided for @danmakuTypeAdvanced.
  ///
  /// In zh_CN, this message translates to:
  /// **'高级弹幕 (BAS)'**
  String get danmakuTypeAdvanced;

  /// No description provided for @danmakuAdvancedSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'动画弹幕，开启可能影响性能'**
  String get danmakuAdvancedSubtitle;

  /// No description provided for @danmakuParameters.
  ///
  /// In zh_CN, this message translates to:
  /// **'参数调节'**
  String get danmakuParameters;

  /// No description provided for @danmakuScrollSpeed.
  ///
  /// In zh_CN, this message translates to:
  /// **'滚动速度'**
  String get danmakuScrollSpeed;

  /// No description provided for @danmakuOpacity.
  ///
  /// In zh_CN, this message translates to:
  /// **'不透明度'**
  String get danmakuOpacity;

  /// No description provided for @danmakuFontSize.
  ///
  /// In zh_CN, this message translates to:
  /// **'字体大小'**
  String get danmakuFontSize;

  /// No description provided for @danmakuMaxLines.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示行数'**
  String get danmakuMaxLines;

  /// No description provided for @danmakuLinesCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 行'**
  String danmakuLinesCount(int count);

  /// No description provided for @danmakuQuickActions.
  ///
  /// In zh_CN, this message translates to:
  /// **'快捷操作'**
  String get danmakuQuickActions;

  /// No description provided for @danmakuResetParams.
  ///
  /// In zh_CN, this message translates to:
  /// **'重置参数'**
  String get danmakuResetParams;

  /// No description provided for @danmakuClearDanmaku.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空弹幕'**
  String get danmakuClearDanmaku;

  /// No description provided for @danmakuLoadLocalXml.
  ///
  /// In zh_CN, this message translates to:
  /// **'加载本地 XML 弹幕'**
  String get danmakuLoadLocalXml;

  /// No description provided for @danmakuFetchOnline.
  ///
  /// In zh_CN, this message translates to:
  /// **'获取 Bilibili 在线弹幕'**
  String get danmakuFetchOnline;

  /// No description provided for @danmakuNotLoaded.
  ///
  /// In zh_CN, this message translates to:
  /// **'尚未加载弹幕'**
  String get danmakuNotLoaded;

  /// No description provided for @danmakuLoadedCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'已加载 {count} 条弹幕'**
  String danmakuLoadedCount(int count);

  /// No description provided for @danmakuBlockColorful.
  ///
  /// In zh_CN, this message translates to:
  /// **'彩色弹幕'**
  String get danmakuBlockColorful;

  /// No description provided for @danmakuCloudFilter.
  ///
  /// In zh_CN, this message translates to:
  /// **'智能云屏蔽'**
  String get danmakuCloudFilter;

  /// No description provided for @danmakuCloudFilterOff.
  ///
  /// In zh_CN, this message translates to:
  /// **'关闭'**
  String get danmakuCloudFilterOff;

  /// No description provided for @danmakuCloudFilterLevel.
  ///
  /// In zh_CN, this message translates to:
  /// **'{level} 级'**
  String danmakuCloudFilterLevel(int level);

  /// No description provided for @danmakuFontSizeFS.
  ///
  /// In zh_CN, this message translates to:
  /// **'全屏字体大小'**
  String get danmakuFontSizeFS;

  /// No description provided for @danmakuSeconds.
  ///
  /// In zh_CN, this message translates to:
  /// **'{value} 秒'**
  String danmakuSeconds(int value);

  /// No description provided for @danmakuOthers.
  ///
  /// In zh_CN, this message translates to:
  /// **'其他'**
  String get danmakuOthers;

  /// No description provided for @danmakuMassiveMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'海量弹幕'**
  String get danmakuMassiveMode;

  /// No description provided for @danmakuStatic2Scroll.
  ///
  /// In zh_CN, this message translates to:
  /// **'固定转滚动'**
  String get danmakuStatic2Scroll;

  /// No description provided for @danmakuShowArea.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示区域'**
  String get danmakuShowArea;

  /// No description provided for @danmakuFontWeight.
  ///
  /// In zh_CN, this message translates to:
  /// **'字体粗细'**
  String get danmakuFontWeight;

  /// No description provided for @danmakuStrokeWidth.
  ///
  /// In zh_CN, this message translates to:
  /// **'描边粗细'**
  String get danmakuStrokeWidth;

  /// No description provided for @danmakuScrollDuration.
  ///
  /// In zh_CN, this message translates to:
  /// **'滚动弹幕时长'**
  String get danmakuScrollDuration;

  /// No description provided for @danmakuStaticDuration.
  ///
  /// In zh_CN, this message translates to:
  /// **'静态弹幕时长'**
  String get danmakuStaticDuration;

  /// No description provided for @danmakuLineHeight.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕行高'**
  String get danmakuLineHeight;

  /// No description provided for @danmakuResetTo.
  ///
  /// In zh_CN, this message translates to:
  /// **'恢复默认：{value}'**
  String danmakuResetTo(String value);

  /// No description provided for @naviAddAction.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加'**
  String get naviAddAction;

  /// No description provided for @playlistImportAdded.
  ///
  /// In zh_CN, this message translates to:
  /// **'已添加 {count} 个文件'**
  String playlistImportAdded(int count);

  /// No description provided for @playlistAddEpisodeTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加集数'**
  String get playlistAddEpisodeTitle;

  /// No description provided for @playlistTitleLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'标题'**
  String get playlistTitleLabel;

  /// No description provided for @playlistEpisodeHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'第 1 集'**
  String get playlistEpisodeHint;

  /// No description provided for @playlistVideoUrlLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频 URL'**
  String get playlistVideoUrlLabel;

  /// No description provided for @playlistAdd.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加'**
  String get playlistAdd;

  /// No description provided for @playlistNameRequired.
  ///
  /// In zh_CN, this message translates to:
  /// **'请输入播放列表名称'**
  String get playlistNameRequired;

  /// No description provided for @playlistAtLeastOneVideo.
  ///
  /// In zh_CN, this message translates to:
  /// **'请至少添加一个视频'**
  String get playlistAtLeastOneVideo;

  /// No description provided for @playlistEditTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'编辑播放列表'**
  String get playlistEditTitle;

  /// No description provided for @playlistCreateTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'创建播放列表'**
  String get playlistCreateTitle;

  /// No description provided for @playlistNameLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放列表名称'**
  String get playlistNameLabel;

  /// No description provided for @playlistNameHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'我的追番列表'**
  String get playlistNameHint;

  /// No description provided for @playlistWebdavMulti.
  ///
  /// In zh_CN, this message translates to:
  /// **'WebDAV 多选'**
  String get playlistWebdavMulti;

  /// No description provided for @playlistItemsCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 集'**
  String playlistItemsCount(int count);

  /// No description provided for @playlistNoItems.
  ///
  /// In zh_CN, this message translates to:
  /// **'还没有添加任何视频'**
  String get playlistNoItems;

  /// No description provided for @playlistImportHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'点击上方按钮导入'**
  String get playlistImportHint;

  /// No description provided for @playlistSaveChanges.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存修改'**
  String get playlistSaveChanges;

  /// No description provided for @playlistEpisodePanelTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'选集'**
  String get playlistEpisodePanelTitle;

  /// No description provided for @playlistEpisodeCurrent.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前: 第 {index} 集'**
  String playlistEpisodeCurrent(int index);

  /// No description provided for @playlistSyncResult.
  ///
  /// In zh_CN, this message translates to:
  /// **'{what}：{message}'**
  String playlistSyncResult(String what, String message);

  /// No description provided for @playlistSyncTwoWay.
  ///
  /// In zh_CN, this message translates to:
  /// **'双向同步播放列表'**
  String get playlistSyncTwoWay;

  /// No description provided for @playlistSyncTwoWaySubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'下载云端并合并，再上传合并结果（含背景图）'**
  String get playlistSyncTwoWaySubtitle;

  /// No description provided for @playlistRestoreFromCloud.
  ///
  /// In zh_CN, this message translates to:
  /// **'从云端恢复'**
  String get playlistRestoreFromCloud;

  /// No description provided for @playlistRestoreFromCloudSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'用云端数据整体覆盖本地播放列表（含背景图）'**
  String get playlistRestoreFromCloudSubtitle;

  /// No description provided for @playlistUploadToCloud.
  ///
  /// In zh_CN, this message translates to:
  /// **'上传到云端'**
  String get playlistUploadToCloud;

  /// No description provided for @playlistUploadToCloudSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'把本地播放列表全量上传（含背景图，不合并）'**
  String get playlistUploadToCloudSubtitle;

  /// No description provided for @playlistSyncDanmaku.
  ///
  /// In zh_CN, this message translates to:
  /// **'同步弹幕缓存'**
  String get playlistSyncDanmaku;

  /// No description provided for @playlistSyncDanmakuSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'与云端弹幕缓存互相合并（取较新）'**
  String get playlistSyncDanmakuSubtitle;

  /// No description provided for @playlistCreated.
  ///
  /// In zh_CN, this message translates to:
  /// **'已创建: {name}'**
  String playlistCreated(String name);

  /// No description provided for @playlistDeleteTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除播放列表'**
  String get playlistDeleteTitle;

  /// No description provided for @playlistDeleteConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定要删除「{name}」吗？'**
  String playlistDeleteConfirm(String name);

  /// No description provided for @playlistNewTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'新建播放列表'**
  String get playlistNewTooltip;

  /// No description provided for @playlistListTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放列表'**
  String get playlistListTitle;

  /// No description provided for @playlistCloudSync.
  ///
  /// In zh_CN, this message translates to:
  /// **'云同步'**
  String get playlistCloudSync;

  /// No description provided for @playlistMyLists.
  ///
  /// In zh_CN, this message translates to:
  /// **'我的列表'**
  String get playlistMyLists;

  /// No description provided for @playlistNoLists.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无播放列表'**
  String get playlistNoLists;

  /// No description provided for @playlistListSummary.
  ///
  /// In zh_CN, this message translates to:
  /// **'共 {count} 个 · 点击列表查看全部剧集'**
  String playlistListSummary(int count);

  /// No description provided for @playlistEmptyTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'还没有播放列表'**
  String get playlistEmptyTitle;

  /// No description provided for @playlistEmptyHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'点击右下角「创建」按钮新建一个吧'**
  String get playlistEmptyHint;

  /// No description provided for @playlistResume.
  ///
  /// In zh_CN, this message translates to:
  /// **'续播'**
  String get playlistResume;

  /// No description provided for @playlistEditAction.
  ///
  /// In zh_CN, this message translates to:
  /// **'编辑'**
  String get playlistEditAction;

  /// No description provided for @playlistTileProgress.
  ///
  /// In zh_CN, this message translates to:
  /// **'{total} 集 · 看到第 {current} 集'**
  String playlistTileProgress(int total, int current);

  /// No description provided for @subtitleOff.
  ///
  /// In zh_CN, this message translates to:
  /// **'关闭字幕'**
  String get subtitleOff;

  /// No description provided for @subtitleTrackFallback.
  ///
  /// In zh_CN, this message translates to:
  /// **'轨道 {id}'**
  String subtitleTrackFallback(String id);

  /// No description provided for @subtitleLoadedLocal.
  ///
  /// In zh_CN, this message translates to:
  /// **'已加载字幕: {name}'**
  String subtitleLoadedLocal(String name);

  /// No description provided for @subtitleWebdavNotConfigured.
  ///
  /// In zh_CN, this message translates to:
  /// **'WebDAV 未配置，请先登录'**
  String get subtitleWebdavNotConfigured;

  /// No description provided for @subtitleWebdavFolderEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'WebDAV 字幕文件夹为空'**
  String get subtitleWebdavFolderEmpty;

  /// No description provided for @subtitleSelectFile.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择字幕文件'**
  String get subtitleSelectFile;

  /// No description provided for @subtitleDownloadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'字幕下载失败: HTTP {code}'**
  String subtitleDownloadFailed(int code);

  /// No description provided for @subtitleLoadedRemote.
  ///
  /// In zh_CN, this message translates to:
  /// **'已加载远程字幕: {name}'**
  String subtitleLoadedRemote(String name);

  /// No description provided for @subtitleLoadError.
  ///
  /// In zh_CN, this message translates to:
  /// **'字幕加载异常: {error}'**
  String subtitleLoadError(String error);

  /// No description provided for @subtitlePanelTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'字幕 (CC)'**
  String get subtitlePanelTitle;

  /// No description provided for @subtitleLoadLocal.
  ///
  /// In zh_CN, this message translates to:
  /// **'加载本地字幕'**
  String get subtitleLoadLocal;

  /// No description provided for @subtitleLoadWebdav.
  ///
  /// In zh_CN, this message translates to:
  /// **'从 WebDAV 加载字幕'**
  String get subtitleLoadWebdav;

  /// No description provided for @subtitleFontSize.
  ///
  /// In zh_CN, this message translates to:
  /// **'字号'**
  String get subtitleFontSize;

  /// No description provided for @subtitleFontColor.
  ///
  /// In zh_CN, this message translates to:
  /// **'字体颜色'**
  String get subtitleFontColor;

  /// No description provided for @subtitleBgColor.
  ///
  /// In zh_CN, this message translates to:
  /// **'背景颜色'**
  String get subtitleBgColor;

  /// No description provided for @webdavInputPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入路径'**
  String get webdavInputPath;

  /// No description provided for @webdavGoTo.
  ///
  /// In zh_CN, this message translates to:
  /// **'前往'**
  String get webdavGoTo;

  /// No description provided for @webdavLoginRequired.
  ///
  /// In zh_CN, this message translates to:
  /// **'请先登录 WebDAV 账号'**
  String get webdavLoginRequired;

  /// No description provided for @webdavLoginSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'配置服务器后可浏览远程视频'**
  String get webdavLoginSubtitle;

  /// No description provided for @webdavLoginSubtitleMulti.
  ///
  /// In zh_CN, this message translates to:
  /// **'登录后可多选远程视频创建播放列表'**
  String get webdavLoginSubtitleMulti;

  /// No description provided for @webdavRefresh.
  ///
  /// In zh_CN, this message translates to:
  /// **'刷新'**
  String get webdavRefresh;

  /// No description provided for @webdavRoot.
  ///
  /// In zh_CN, this message translates to:
  /// **'根'**
  String get webdavRoot;

  /// No description provided for @webdavParent.
  ///
  /// In zh_CN, this message translates to:
  /// **'上级'**
  String get webdavParent;

  /// No description provided for @webdavFolderEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'此文件夹为空'**
  String get webdavFolderEmpty;

  /// No description provided for @webdavPullToRefresh.
  ///
  /// In zh_CN, this message translates to:
  /// **'下拉刷新试试?'**
  String get webdavPullToRefresh;

  /// No description provided for @webdavSelectVideo.
  ///
  /// In zh_CN, this message translates to:
  /// **'请选择视频文件'**
  String get webdavSelectVideo;

  /// No description provided for @webdavPlay.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放'**
  String get webdavPlay;

  /// No description provided for @webdavMultiSelectTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'多选文件'**
  String get webdavMultiSelectTitle;

  /// No description provided for @webdavNoSelection.
  ///
  /// In zh_CN, this message translates to:
  /// **'未选择文件'**
  String get webdavNoSelection;

  /// No description provided for @webdavSelectedCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'已选 {count} 个视频'**
  String webdavSelectedCount(int count);

  /// No description provided for @webdavSelectionOrder.
  ///
  /// In zh_CN, this message translates to:
  /// **'按选择顺序: {names}'**
  String webdavSelectionOrder(String names);

  /// No description provided for @webdavClear.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空'**
  String get webdavClear;

  /// No description provided for @webdavConfirmSelection.
  ///
  /// In zh_CN, this message translates to:
  /// **'确认选择'**
  String get webdavConfirmSelection;

  /// No description provided for @webdavGoLogin.
  ///
  /// In zh_CN, this message translates to:
  /// **'去登录'**
  String get webdavGoLogin;

  /// No description provided for @profileTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'个人信息'**
  String get profileTitle;

  /// No description provided for @settingsAvatarTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'头像'**
  String get settingsAvatarTitle;

  /// No description provided for @settingsAvatarSet.
  ///
  /// In zh_CN, this message translates to:
  /// **'已设置'**
  String get settingsAvatarSet;

  /// No description provided for @settingsNotSet.
  ///
  /// In zh_CN, this message translates to:
  /// **'未设置'**
  String get settingsNotSet;

  /// No description provided for @settingsAvatarChangeTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'更换头像'**
  String get settingsAvatarChangeTooltip;

  /// No description provided for @settingsAvatarDeleteTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除头像'**
  String get settingsAvatarDeleteTooltip;

  /// No description provided for @settingsAvatarUpdated.
  ///
  /// In zh_CN, this message translates to:
  /// **'头像已更新'**
  String get settingsAvatarUpdated;

  /// No description provided for @settingsPickAvatarFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择头像失败：{error}'**
  String settingsPickAvatarFailed(String error);

  /// No description provided for @settingsAvatarDeleteTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除头像'**
  String get settingsAvatarDeleteTitle;

  /// No description provided for @settingsAvatarDeleteConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定要删除当前头像吗？'**
  String get settingsAvatarDeleteConfirm;

  /// No description provided for @settingsAvatarDeleteConfirmPermanent.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定要删除当前头像吗？此操作无法撤销。'**
  String get settingsAvatarDeleteConfirmPermanent;

  /// No description provided for @settingsAvatarDeleted.
  ///
  /// In zh_CN, this message translates to:
  /// **'头像已删除'**
  String get settingsAvatarDeleted;

  /// No description provided for @settingsNickname.
  ///
  /// In zh_CN, this message translates to:
  /// **'昵称'**
  String get settingsNickname;

  /// No description provided for @settingsNicknameEditTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'编辑昵称'**
  String get settingsNicknameEditTooltip;

  /// No description provided for @settingsSetNickname.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置昵称'**
  String get settingsSetNickname;

  /// No description provided for @settingsNicknamePrompt.
  ///
  /// In zh_CN, this message translates to:
  /// **'请输入您的昵称'**
  String get settingsNicknamePrompt;

  /// No description provided for @settingsNicknameHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入昵称'**
  String get settingsNicknameHint;

  /// No description provided for @settingsNicknameEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'昵称不能为空'**
  String get settingsNicknameEmpty;

  /// No description provided for @settingsNicknameTooLong.
  ///
  /// In zh_CN, this message translates to:
  /// **'昵称长度不能超过 20 个字符'**
  String get settingsNicknameTooLong;

  /// No description provided for @settingsNicknameUpdated.
  ///
  /// In zh_CN, this message translates to:
  /// **'昵称已更新'**
  String get settingsNicknameUpdated;

  /// No description provided for @settingsLockWallpaper.
  ///
  /// In zh_CN, this message translates to:
  /// **'锁屏壁纸'**
  String get settingsLockWallpaper;

  /// No description provided for @settingsWallpaperCustomSet.
  ///
  /// In zh_CN, this message translates to:
  /// **'已设置自定义壁纸'**
  String get settingsWallpaperCustomSet;

  /// No description provided for @settingsWallpaperDefaultBg.
  ///
  /// In zh_CN, this message translates to:
  /// **'使用默认深色背景'**
  String get settingsWallpaperDefaultBg;

  /// No description provided for @settingsWallpaperUpdated.
  ///
  /// In zh_CN, this message translates to:
  /// **'壁纸已更新'**
  String get settingsWallpaperUpdated;

  /// No description provided for @settingsWallpaperPickTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择壁纸'**
  String get settingsWallpaperPickTooltip;

  /// No description provided for @settingsWallpaperDelete.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除壁纸'**
  String get settingsWallpaperDelete;

  /// No description provided for @settingsWallpaperDeleteConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定要删除锁屏壁纸并恢复默认吗？'**
  String get settingsWallpaperDeleteConfirm;

  /// No description provided for @settingsWallpaperDeleted.
  ///
  /// In zh_CN, this message translates to:
  /// **'壁纸已删除'**
  String get settingsWallpaperDeleted;

  /// No description provided for @settingsDecoImage.
  ///
  /// In zh_CN, this message translates to:
  /// **'右下角装饰图'**
  String get settingsDecoImage;

  /// No description provided for @settingsDecoImageSet.
  ///
  /// In zh_CN, this message translates to:
  /// **'已设置 (支持透明 PNG/WebP)'**
  String get settingsDecoImageSet;

  /// No description provided for @settingsDecoImageUpdated.
  ///
  /// In zh_CN, this message translates to:
  /// **'装饰图已更新'**
  String get settingsDecoImageUpdated;

  /// No description provided for @settingsPickImageFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择图片失败：{error}'**
  String settingsPickImageFailed(String error);

  /// No description provided for @settingsPickImageTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择图片'**
  String get settingsPickImageTooltip;

  /// No description provided for @settingsDecoImageDelete.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除装饰图'**
  String get settingsDecoImageDelete;

  /// No description provided for @settingsDecoImageDeleteConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定要删除右下角装饰图吗？'**
  String get settingsDecoImageDeleteConfirm;

  /// No description provided for @settingsDecoImageDeleted.
  ///
  /// In zh_CN, this message translates to:
  /// **'装饰图已删除'**
  String get settingsDecoImageDeleted;

  /// No description provided for @settingsSize.
  ///
  /// In zh_CN, this message translates to:
  /// **'大小'**
  String get settingsSize;

  /// No description provided for @settingsSizePxLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'{size} px'**
  String settingsSizePxLabel(String size);

  /// No description provided for @settingsSizePxValue.
  ///
  /// In zh_CN, this message translates to:
  /// **'{size}px'**
  String settingsSizePxValue(String size);

  /// No description provided for @settingsOpacity.
  ///
  /// In zh_CN, this message translates to:
  /// **'透明'**
  String get settingsOpacity;

  /// No description provided for @settingsOpacityPercentValue.
  ///
  /// In zh_CN, this message translates to:
  /// **'{percent}%'**
  String settingsOpacityPercentValue(int percent);

  /// No description provided for @settingsDisplay.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示'**
  String get settingsDisplay;

  /// No description provided for @settingsDisplaySubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题 · 配色 · 文字 · 缩放'**
  String get settingsDisplaySubtitle;

  /// No description provided for @settingsAppTheme.
  ///
  /// In zh_CN, this message translates to:
  /// **'应用主题'**
  String get settingsAppTheme;

  /// No description provided for @settingsCurrentColor.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前配色：#{color}'**
  String settingsCurrentColor(String color);

  /// No description provided for @settingsFontWeight.
  ///
  /// In zh_CN, this message translates to:
  /// **'文字粗细'**
  String get settingsFontWeight;

  /// No description provided for @settingsCurrentFontWeight.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前粗细：{weight}'**
  String settingsCurrentFontWeight(int weight);

  /// No description provided for @settingsDisplayScale.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示缩放'**
  String get settingsDisplayScale;

  /// No description provided for @settingsCurrentScale.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前比例：{percent}%'**
  String settingsCurrentScale(int percent);

  /// No description provided for @settingsRestrictIp.
  ///
  /// In zh_CN, this message translates to:
  /// **'限制内网 IP 连接'**
  String get settingsRestrictIp;

  /// No description provided for @settingsRestrictIpSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'仅允许 A 类、B 类、C 类内网 IP 地址'**
  String get settingsRestrictIpSubtitle;

  /// No description provided for @settingsDefaultPort.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认端口'**
  String get settingsDefaultPort;

  /// No description provided for @settingsAdjustFontWeight.
  ///
  /// In zh_CN, this message translates to:
  /// **'调整文字粗细'**
  String get settingsAdjustFontWeight;

  /// No description provided for @settingsFontWeightPreview.
  ///
  /// In zh_CN, this message translates to:
  /// **'预览：{weight}'**
  String settingsFontWeightPreview(int weight);

  /// No description provided for @settingsWeightHairline.
  ///
  /// In zh_CN, this message translates to:
  /// **'极细'**
  String get settingsWeightHairline;

  /// No description provided for @settingsWeightThin.
  ///
  /// In zh_CN, this message translates to:
  /// **'细'**
  String get settingsWeightThin;

  /// No description provided for @settingsWeightRegular.
  ///
  /// In zh_CN, this message translates to:
  /// **'常规'**
  String get settingsWeightRegular;

  /// No description provided for @settingsWeightMedium.
  ///
  /// In zh_CN, this message translates to:
  /// **'中等'**
  String get settingsWeightMedium;

  /// No description provided for @settingsWeightBold.
  ///
  /// In zh_CN, this message translates to:
  /// **'粗'**
  String get settingsWeightBold;

  /// No description provided for @settingsWeightBlack.
  ///
  /// In zh_CN, this message translates to:
  /// **'极粗'**
  String get settingsWeightBlack;

  /// No description provided for @settingsFontWeightUpdated.
  ///
  /// In zh_CN, this message translates to:
  /// **'字体粗细已更新'**
  String get settingsFontWeightUpdated;

  /// No description provided for @logTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'日志'**
  String get logTitle;

  /// No description provided for @logBackTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'转到上一层级'**
  String get logBackTooltip;

  /// No description provided for @logRefresh.
  ///
  /// In zh_CN, this message translates to:
  /// **'刷新'**
  String get logRefresh;

  /// No description provided for @logClearAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空日志'**
  String get logClearAll;

  /// No description provided for @logClearTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空日志'**
  String get logClearTitle;

  /// No description provided for @logClearConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'将删除 error/ 与 mpv/ 目录下的全部日志文件，确定吗？'**
  String get logClearConfirm;

  /// No description provided for @logClearAction.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空'**
  String get logClearAction;

  /// No description provided for @logDeletedCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'已删除 {count} 个日志文件'**
  String logDeletedCount(int count);

  /// No description provided for @logCopyContent.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制内容'**
  String get logCopyContent;

  /// No description provided for @logShare.
  ///
  /// In zh_CN, this message translates to:
  /// **'分享日志'**
  String get logShare;

  /// No description provided for @logDeleteThis.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除此日志'**
  String get logDeleteThis;

  /// No description provided for @logEmptyContent.
  ///
  /// In zh_CN, this message translates to:
  /// **'（空日志）'**
  String get logEmptyContent;

  /// No description provided for @logStorageLocation.
  ///
  /// In zh_CN, this message translates to:
  /// **'存储位置：{path}'**
  String logStorageLocation(String path);

  /// No description provided for @logErrorSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'错误日志（崩溃必写）'**
  String get logErrorSection;

  /// No description provided for @logNoErrorLogs.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无错误日志'**
  String get logNoErrorLogs;

  /// No description provided for @logMpvSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'mpv 日志（可选）'**
  String get logMpvSection;

  /// No description provided for @logNoMpvLogs.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无 mpv 日志'**
  String get logNoMpvLogs;

  /// No description provided for @logReadingLogs.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在读取日志…'**
  String get logReadingLogs;

  /// No description provided for @lockFollowThemeColor.
  ///
  /// In zh_CN, this message translates to:
  /// **'跟随主题色 (时间)'**
  String get lockFollowThemeColor;

  /// No description provided for @lockShowBattery.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示电池'**
  String get lockShowBattery;

  /// No description provided for @lockShowNetwork.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示网络'**
  String get lockShowNetwork;

  /// No description provided for @lockDate.
  ///
  /// In zh_CN, this message translates to:
  /// **'{month}月{day}日'**
  String lockDate(int month, int day);

  /// No description provided for @weekdaySunday.
  ///
  /// In zh_CN, this message translates to:
  /// **'星期日'**
  String get weekdaySunday;

  /// No description provided for @weekdayMonday.
  ///
  /// In zh_CN, this message translates to:
  /// **'星期一'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In zh_CN, this message translates to:
  /// **'星期二'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In zh_CN, this message translates to:
  /// **'星期三'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In zh_CN, this message translates to:
  /// **'星期四'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In zh_CN, this message translates to:
  /// **'星期五'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In zh_CN, this message translates to:
  /// **'星期六'**
  String get weekdaySaturday;

  /// No description provided for @myQrSelectIpHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'点击选择二维码使用的 IP'**
  String get myQrSelectIpHint;

  /// No description provided for @myQrNoIpType.
  ///
  /// In zh_CN, this message translates to:
  /// **'无该类型 IP'**
  String get myQrNoIpType;

  /// No description provided for @myQrInUse.
  ///
  /// In zh_CN, this message translates to:
  /// **'使用中'**
  String get myQrInUse;

  /// No description provided for @myQrSetAsQr.
  ///
  /// In zh_CN, this message translates to:
  /// **'设为二维码'**
  String get myQrSetAsQr;

  /// No description provided for @netLanDiscoveryPort.
  ///
  /// In zh_CN, this message translates to:
  /// **'本机发现端口'**
  String get netLanDiscoveryPort;

  /// No description provided for @netDohNoRecord.
  ///
  /// In zh_CN, this message translates to:
  /// **'未查询到 {domain} 的 A 记录'**
  String netDohNoRecord(String domain);

  /// No description provided for @netDohQueryFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'查询失败: {error}'**
  String netDohQueryFailed(String error);

  /// No description provided for @netMappingSaved.
  ///
  /// In zh_CN, this message translates to:
  /// **'已保存映射: {domain} → {ip}'**
  String netMappingSaved(String domain, String ip);

  /// No description provided for @netAddHostMapping.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加 Host 映射'**
  String get netAddHostMapping;

  /// No description provided for @netDomainLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'域名'**
  String get netDomainLabel;

  /// No description provided for @netIpLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'IP 地址'**
  String get netIpLabel;

  /// No description provided for @netAdd.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加'**
  String get netAdd;

  /// No description provided for @netMappingAdded.
  ///
  /// In zh_CN, this message translates to:
  /// **'已添加映射: {host} → {ip}'**
  String netMappingAdded(String host, String ip);

  /// No description provided for @netMappingRemoved.
  ///
  /// In zh_CN, this message translates to:
  /// **'已移除映射: {host}'**
  String netMappingRemoved(String host);

  /// No description provided for @netTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'网络'**
  String get netTitle;

  /// No description provided for @netBackTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'转到上一层级'**
  String get netBackTooltip;

  /// No description provided for @netRetestAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部重测'**
  String get netRetestAll;

  /// No description provided for @netConnectionModeSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接模式'**
  String get netConnectionModeSection;

  /// No description provided for @netNetworkMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'网络模式'**
  String get netNetworkMode;

  /// No description provided for @netModeStandardLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'标准模式'**
  String get netModeStandardLabel;

  /// No description provided for @netModeCompatLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'兼容直连'**
  String get netModeCompatLabel;

  /// No description provided for @netModeStandardDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'使用系统默认网络栈'**
  String get netModeStandardDesc;

  /// No description provided for @netAllowInsecureCert.
  ///
  /// In zh_CN, this message translates to:
  /// **'允许不安全证书'**
  String get netAllowInsecureCert;

  /// No description provided for @netAllowInsecureCertDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'兼容直连时跳过证书校验 (IP 直连场景)'**
  String get netAllowInsecureCertDesc;

  /// No description provided for @netChatIpv6.
  ///
  /// In zh_CN, this message translates to:
  /// **'聊天 IPv6'**
  String get netChatIpv6;

  /// No description provided for @netChatIpv6On.
  ///
  /// In zh_CN, this message translates to:
  /// **'已开启：支持 IPv6 聊天、发现与二维码'**
  String get netChatIpv6On;

  /// No description provided for @netChatIpv6Off.
  ///
  /// In zh_CN, this message translates to:
  /// **'已关闭：仅使用 IPv4 聊天'**
  String get netChatIpv6Off;

  /// No description provided for @netChatIpv6EnabledSnack.
  ///
  /// In zh_CN, this message translates to:
  /// **'已开启聊天 IPv6（重启应用生效）'**
  String get netChatIpv6EnabledSnack;

  /// No description provided for @netChatIpv6DisabledSnack.
  ///
  /// In zh_CN, this message translates to:
  /// **'已关闭聊天 IPv6（重启应用生效）'**
  String get netChatIpv6DisabledSnack;

  /// No description provided for @netLocalSendCompat.
  ///
  /// In zh_CN, this message translates to:
  /// **'LocalSend 兼容'**
  String get netLocalSendCompat;

  /// No description provided for @netLocalSendCompatOn.
  ///
  /// In zh_CN, this message translates to:
  /// **'已开启：启用 LocalSend 协议（端口 53317），可与 LocalSend 官方客户端互传文件'**
  String get netLocalSendCompatOn;

  /// No description provided for @netLocalSendCompatOff.
  ///
  /// In zh_CN, this message translates to:
  /// **'已关闭：使用 navi 原生协议方案'**
  String get netLocalSendCompatOff;

  /// No description provided for @netLocalSendCompatEnabledSnack.
  ///
  /// In zh_CN, this message translates to:
  /// **'已开启 LocalSend 兼容'**
  String get netLocalSendCompatEnabledSnack;

  /// No description provided for @netLocalSendCompatDisabledSnack.
  ///
  /// In zh_CN, this message translates to:
  /// **'已关闭 LocalSend 兼容（恢复原生方案）'**
  String get netLocalSendCompatDisabledSnack;

  /// No description provided for @lsSectionTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'LocalSend 设备'**
  String get lsSectionTitle;

  /// No description provided for @lsHintEnable.
  ///
  /// In zh_CN, this message translates to:
  /// **'LocalSend 兼容未开启'**
  String get lsHintEnable;

  /// No description provided for @lsHintEnableDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'开启后可与 LocalSend 官方客户端（Android/iOS/Windows/macOS/Linux）互传文件'**
  String get lsHintEnableDesc;

  /// No description provided for @lsEnableNow.
  ///
  /// In zh_CN, this message translates to:
  /// **'开启'**
  String get lsEnableNow;

  /// No description provided for @lsEnabledSnack.
  ///
  /// In zh_CN, this message translates to:
  /// **'已开启 LocalSend 兼容'**
  String get lsEnabledSnack;

  /// No description provided for @lsNoDevices.
  ///
  /// In zh_CN, this message translates to:
  /// **'未发现 LocalSend 设备'**
  String get lsNoDevices;

  /// No description provided for @lsHttpScan.
  ///
  /// In zh_CN, this message translates to:
  /// **'HTTP 扫描'**
  String get lsHttpScan;

  /// No description provided for @lsHttpScanning.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在扫描局域网（组播不通时的兜底）...'**
  String get lsHttpScanning;

  /// No description provided for @lsHttpScanDone.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描完成'**
  String get lsHttpScanDone;

  /// No description provided for @lsSendFile.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送文件'**
  String get lsSendFile;

  /// No description provided for @lsSendFileDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'通过 LocalSend 协议发送到该设备'**
  String get lsSendFileDesc;

  /// No description provided for @lsProbe.
  ///
  /// In zh_CN, this message translates to:
  /// **'重新探测'**
  String get lsProbe;

  /// No description provided for @lsProbing.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在探测...'**
  String get lsProbing;

  /// No description provided for @lsProbeFound.
  ///
  /// In zh_CN, this message translates to:
  /// **'探测成功'**
  String get lsProbeFound;

  /// No description provided for @lsProbeNotFound.
  ///
  /// In zh_CN, this message translates to:
  /// **'设备未响应'**
  String get lsProbeNotFound;

  /// No description provided for @lsPickFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择文件失败：{error}'**
  String lsPickFailed(String error);

  /// No description provided for @lsNoPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法获取文件路径'**
  String get lsNoPath;

  /// No description provided for @lsSendingTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在发送到 {alias}'**
  String lsSendingTitle(String alias);

  /// No description provided for @lsSendSuccess.
  ///
  /// In zh_CN, this message translates to:
  /// **'成功发送 {count} 个文件'**
  String lsSendSuccess(int count);

  /// No description provided for @lsSendFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'有 {count} 个文件发送成功，其余失败'**
  String lsSendFailed(int count);

  /// No description provided for @lsReceiveRequestTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'接收文件请求'**
  String get lsReceiveRequestTitle;

  /// No description provided for @lsReceiveRequestDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'对方发送了 {count} 个文件，共 {size}'**
  String lsReceiveRequestDesc(int count, String size);

  /// No description provided for @lsAccept.
  ///
  /// In zh_CN, this message translates to:
  /// **'接受'**
  String get lsAccept;

  /// No description provided for @lsReject.
  ///
  /// In zh_CN, this message translates to:
  /// **'拒绝'**
  String get lsReject;

  /// No description provided for @lsOpenFile.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开文件'**
  String get lsOpenFile;

  /// No description provided for @lsReceiveCompleteTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'文件接收完成'**
  String get lsReceiveCompleteTitle;

  /// No description provided for @lsReceiveCompleteDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'{fileName} 已保存到：\n{path}'**
  String lsReceiveCompleteDesc(String fileName, String path);

  /// No description provided for @lsFileReceived.
  ///
  /// In zh_CN, this message translates to:
  /// **'已接收文件：{fileName}'**
  String lsFileReceived(String fileName);

  /// No description provided for @netConnectivitySection.
  ///
  /// In zh_CN, this message translates to:
  /// **'连通性测试'**
  String get netConnectivitySection;

  /// No description provided for @netHostMappingSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'Host 映射'**
  String get netHostMappingSection;

  /// No description provided for @netMappingReset.
  ///
  /// In zh_CN, this message translates to:
  /// **'已恢复内置默认 IP 表'**
  String get netMappingReset;

  /// No description provided for @netRestoreDefaults.
  ///
  /// In zh_CN, this message translates to:
  /// **'恢复默认'**
  String get netRestoreDefaults;

  /// No description provided for @netNoMappings.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无映射'**
  String get netNoMappings;

  /// No description provided for @netAddMapping.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加映射'**
  String get netAddMapping;

  /// No description provided for @netDohQuerySection.
  ///
  /// In zh_CN, this message translates to:
  /// **'DoH 查询'**
  String get netDohQuerySection;

  /// No description provided for @netDohQueryDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'通过 Cloudflare JSON DNS API 查询域名 A 记录，结果可一键保存为 Host 映射'**
  String get netDohQueryDesc;

  /// No description provided for @netDohResultDisplay.
  ///
  /// In zh_CN, this message translates to:
  /// **'{domain} → {ip}'**
  String netDohResultDisplay(String domain, String ip);

  /// No description provided for @netSaveAsMapping.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存为映射'**
  String get netSaveAsMapping;

  /// No description provided for @netHeadersSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'请求头'**
  String get netHeadersSection;

  /// No description provided for @netRefererNotSet.
  ///
  /// In zh_CN, this message translates to:
  /// **'未设置 (示例: https://www.bilibili.com/)'**
  String get netRefererNotSet;

  /// No description provided for @netNotSet.
  ///
  /// In zh_CN, this message translates to:
  /// **'未设置'**
  String get netNotSet;

  /// No description provided for @netHeaderEditorTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置 {title}'**
  String netHeaderEditorTitle(String title);

  /// No description provided for @netHeaderSaved.
  ///
  /// In zh_CN, this message translates to:
  /// **'{title} 已保存'**
  String netHeaderSaved(String title);

  /// No description provided for @ossTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'开源许可'**
  String get ossTitle;

  /// No description provided for @ossBackTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'转到上一层级'**
  String get ossBackTooltip;

  /// No description provided for @ossThanks.
  ///
  /// In zh_CN, this message translates to:
  /// **'致谢'**
  String get ossThanks;

  /// No description provided for @ossSummary.
  ///
  /// In zh_CN, this message translates to:
  /// **'本项目基于 Flutter 构建，共引用 {count} 个开源项目，涵盖 MIT、Apache-2.0 与 BSD-3-Clause 许可证。点击条目即可查看完整许可文本，感谢所有开源作者的无私贡献。'**
  String ossSummary(int count);

  /// No description provided for @ossGroupCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'{name} · {count} 项'**
  String ossGroupCount(String name, int count);

  /// No description provided for @ossCopyFullText.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制全文'**
  String get ossCopyFullText;

  /// No description provided for @ossLicenseCopied.
  ///
  /// In zh_CN, this message translates to:
  /// **'许可文本已复制到剪贴板'**
  String get ossLicenseCopied;

  /// No description provided for @playHistoryTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放历史'**
  String get playHistoryTitle;

  /// No description provided for @playHistoryBackTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'转到上一层级'**
  String get playHistoryBackTooltip;

  /// No description provided for @playHistoryClearAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空全部'**
  String get playHistoryClearAll;

  /// No description provided for @playHistoryEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'这里空空的'**
  String get playHistoryEmpty;

  /// No description provided for @playHistoryEmptySub.
  ///
  /// In zh_CN, this message translates to:
  /// **'唔,今天真是寂寞如雪啊'**
  String get playHistoryEmptySub;

  /// No description provided for @playHistoryClearTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空播放历史'**
  String get playHistoryClearTitle;

  /// No description provided for @playHistoryClearConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'您确定要删除所有保存的播放进度吗？此操作不可撤销。'**
  String get playHistoryClearConfirm;

  /// No description provided for @playHistoryClearAction.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空'**
  String get playHistoryClearAction;

  /// No description provided for @playHistoryResume.
  ///
  /// In zh_CN, this message translates to:
  /// **'继续播放'**
  String get playHistoryResume;

  /// No description provided for @playHistoryDeleteRecord.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除记录'**
  String get playHistoryDeleteRecord;

  /// No description provided for @playHistoryDeleted.
  ///
  /// In zh_CN, this message translates to:
  /// **'已删除「{title}」的播放记录'**
  String playHistoryDeleted(String title);

  /// No description provided for @timeJustNow.
  ///
  /// In zh_CN, this message translates to:
  /// **'刚刚'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 分钟前'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 小时前'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 天前'**
  String timeDaysAgo(int count);

  /// No description provided for @playerArtistVideo.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频播放'**
  String get playerArtistVideo;

  /// No description provided for @playerArtistPlaylist.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放列表'**
  String get playerArtistPlaylist;

  /// No description provided for @playerArtistWebdav.
  ///
  /// In zh_CN, this message translates to:
  /// **'WebDAV 视频'**
  String get playerArtistWebdav;

  /// No description provided for @playerWebdavSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'WebDAV 字幕'**
  String get playerWebdavSubtitle;

  /// No description provided for @playerResumeFrom.
  ///
  /// In zh_CN, this message translates to:
  /// **'已从 {position} 继续播放'**
  String playerResumeFrom(String position);

  /// No description provided for @playerNowPlaying.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在播放: {title}'**
  String playerNowPlaying(String title);

  /// No description provided for @playerDanmakuCache.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕缓存 ({count}条)'**
  String playerDanmakuCache(int count);

  /// No description provided for @playerDanmakuBilibili.
  ///
  /// In zh_CN, this message translates to:
  /// **'Bilibili 弹幕 ({count}条)'**
  String playerDanmakuBilibili(int count);

  /// No description provided for @playerDanmakuNoData.
  ///
  /// In zh_CN, this message translates to:
  /// **'未解析到弹幕数据'**
  String get playerDanmakuNoData;

  /// No description provided for @playerDanmakuLoaded.
  ///
  /// In zh_CN, this message translates to:
  /// **'已加载 {count} 条弹幕'**
  String playerDanmakuLoaded(int count);

  /// No description provided for @playerDanmakuOnline.
  ///
  /// In zh_CN, this message translates to:
  /// **'Bilibili 在线弹幕 ({count}条)'**
  String playerDanmakuOnline(int count);

  /// No description provided for @playerDanmakuLoadedFromCache.
  ///
  /// In zh_CN, this message translates to:
  /// **'已从本地缓存加载 {count} 条弹幕'**
  String playerDanmakuLoadedFromCache(int count);

  /// No description provided for @playerDanmakuLoadedOnline.
  ///
  /// In zh_CN, this message translates to:
  /// **'已加载 {count} 条在线弹幕'**
  String playerDanmakuLoadedOnline(int count);

  /// No description provided for @playerScreenshotFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'截图失败: {error}'**
  String playerScreenshotFailed(String error);

  /// No description provided for @playerSavedToAlbum.
  ///
  /// In zh_CN, this message translates to:
  /// **'已保存到相册'**
  String get playerSavedToAlbum;

  /// No description provided for @playerScreenshotSavedToAlbum.
  ///
  /// In zh_CN, this message translates to:
  /// **'截图 {fileName} 已保存到相册'**
  String playerScreenshotSavedToAlbum(String fileName);

  /// No description provided for @playerSaveFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存失败: {error}'**
  String playerSaveFailed(String error);

  /// No description provided for @playerPipFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'画中画调用失败: {error}'**
  String playerPipFailed(String error);

  /// No description provided for @playerFitAdapt.
  ///
  /// In zh_CN, this message translates to:
  /// **'适配'**
  String get playerFitAdapt;

  /// No description provided for @playerFitStretch.
  ///
  /// In zh_CN, this message translates to:
  /// **'拉伸'**
  String get playerFitStretch;

  /// No description provided for @playerFitFill.
  ///
  /// In zh_CN, this message translates to:
  /// **'填充'**
  String get playerFitFill;

  /// No description provided for @playerEndPause.
  ///
  /// In zh_CN, this message translates to:
  /// **'播完暂停'**
  String get playerEndPause;

  /// No description provided for @playerEndLoop.
  ///
  /// In zh_CN, this message translates to:
  /// **'洗脑循环'**
  String get playerEndLoop;

  /// No description provided for @playerEndExit.
  ///
  /// In zh_CN, this message translates to:
  /// **'播完退出'**
  String get playerEndExit;

  /// No description provided for @playerSubtitleSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'字幕设置'**
  String get playerSubtitleSettings;

  /// No description provided for @playerAdvancedSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'高级设置'**
  String get playerAdvancedSettings;

  /// No description provided for @playerFlipHorizontal.
  ///
  /// In zh_CN, this message translates to:
  /// **'水平镜像'**
  String get playerFlipHorizontal;

  /// No description provided for @playerFlipHorizontalDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'左右翻转画面'**
  String get playerFlipHorizontalDesc;

  /// No description provided for @playerFlipVertical.
  ///
  /// In zh_CN, this message translates to:
  /// **'垂直翻转'**
  String get playerFlipVertical;

  /// No description provided for @playerFlipVerticalDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'上下翻转画面'**
  String get playerFlipVerticalDesc;

  /// No description provided for @playerShowStats.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示视频统计信息'**
  String get playerShowStats;

  /// No description provided for @playerShowStatsDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'编码/分辨率/码率/帧率'**
  String get playerShowStatsDesc;

  /// No description provided for @playerAutoPip.
  ///
  /// In zh_CN, this message translates to:
  /// **'返回桌面自动画中画'**
  String get playerAutoPip;

  /// No description provided for @playerLoadDanmakuOnResume.
  ///
  /// In zh_CN, this message translates to:
  /// **'恢复播放时加载弹幕'**
  String get playerLoadDanmakuOnResume;

  /// No description provided for @playerLoadDanmakuOnResumeDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'从播放历史继续时自动读取/拉取弹幕'**
  String get playerLoadDanmakuOnResumeDesc;

  /// No description provided for @playerDefaultRate.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认倍速'**
  String get playerDefaultRate;

  /// No description provided for @playerDefaultEndBehavior.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认退出行为'**
  String get playerDefaultEndBehavior;

  /// No description provided for @playerBuffering.
  ///
  /// In zh_CN, this message translates to:
  /// **'缓冲中...'**
  String get playerBuffering;

  /// No description provided for @playerHwdecSoftware.
  ///
  /// In zh_CN, this message translates to:
  /// **'软解 (SW)'**
  String get playerHwdecSoftware;

  /// No description provided for @playerHwdecHardware.
  ///
  /// In zh_CN, this message translates to:
  /// **'硬解 ({mode})'**
  String playerHwdecHardware(String mode);

  /// No description provided for @playerSourceLocal.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地文件'**
  String get playerSourceLocal;

  /// No description provided for @playerStatResolution.
  ///
  /// In zh_CN, this message translates to:
  /// **'分辨率'**
  String get playerStatResolution;

  /// No description provided for @playerStatVideoCodec.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频编码'**
  String get playerStatVideoCodec;

  /// No description provided for @playerStatAudioCodec.
  ///
  /// In zh_CN, this message translates to:
  /// **'音频编码'**
  String get playerStatAudioCodec;

  /// No description provided for @playerStatBitrate.
  ///
  /// In zh_CN, this message translates to:
  /// **'码率'**
  String get playerStatBitrate;

  /// No description provided for @playerStatFps.
  ///
  /// In zh_CN, this message translates to:
  /// **'帧率'**
  String get playerStatFps;

  /// No description provided for @playerStatDecode.
  ///
  /// In zh_CN, this message translates to:
  /// **'解码'**
  String get playerStatDecode;

  /// No description provided for @playerStatSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'字幕'**
  String get playerStatSubtitle;

  /// No description provided for @playerOn.
  ///
  /// In zh_CN, this message translates to:
  /// **'开启'**
  String get playerOn;

  /// No description provided for @playerOff.
  ///
  /// In zh_CN, this message translates to:
  /// **'关闭'**
  String get playerOff;

  /// No description provided for @playerStatDanmaku.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕'**
  String get playerStatDanmaku;

  /// No description provided for @playerStatDownload.
  ///
  /// In zh_CN, this message translates to:
  /// **'下载'**
  String get playerStatDownload;

  /// No description provided for @playerStatSource.
  ///
  /// In zh_CN, this message translates to:
  /// **'来源'**
  String get playerStatSource;

  /// No description provided for @playerStatPosition.
  ///
  /// In zh_CN, this message translates to:
  /// **'进度'**
  String get playerStatPosition;

  /// No description provided for @playerStatDuration.
  ///
  /// In zh_CN, this message translates to:
  /// **'时长'**
  String get playerStatDuration;

  /// No description provided for @playerCopyLink.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制视频链接'**
  String get playerCopyLink;

  /// No description provided for @playerCopyLinkAt.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制空降链接（{time}）'**
  String playerCopyLinkAt(String time);

  /// No description provided for @playerCopyLinkAt0.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制空降链接'**
  String get playerCopyLinkAt0;

  /// No description provided for @playerCopyLinkDone.
  ///
  /// In zh_CN, this message translates to:
  /// **'已复制：{url}'**
  String playerCopyLinkDone(String url);

  /// No description provided for @playerCopyLinkNotBili.
  ///
  /// In zh_CN, this message translates to:
  /// **'仅 B 站视频支持复制链接'**
  String get playerCopyLinkNotBili;

  /// No description provided for @playerColorAdjust.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频色彩调节'**
  String get playerColorAdjust;

  /// No description provided for @playerColorBrightness.
  ///
  /// In zh_CN, this message translates to:
  /// **'亮度'**
  String get playerColorBrightness;

  /// No description provided for @playerColorContrast.
  ///
  /// In zh_CN, this message translates to:
  /// **'对比度'**
  String get playerColorContrast;

  /// No description provided for @playerColorSaturation.
  ///
  /// In zh_CN, this message translates to:
  /// **'饱和度'**
  String get playerColorSaturation;

  /// No description provided for @playerColorHue.
  ///
  /// In zh_CN, this message translates to:
  /// **'色相'**
  String get playerColorHue;

  /// No description provided for @playerColorGamma.
  ///
  /// In zh_CN, this message translates to:
  /// **'伽马'**
  String get playerColorGamma;

  /// No description provided for @playerColorReset.
  ///
  /// In zh_CN, this message translates to:
  /// **'重置'**
  String get playerColorReset;

  /// No description provided for @playerColorUnavailable.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前播放器不支持色彩调节'**
  String get playerColorUnavailable;

  /// No description provided for @playerStats.
  ///
  /// In zh_CN, this message translates to:
  /// **'统计信息'**
  String get playerStats;

  /// No description provided for @playerAlignAspectRatio.
  ///
  /// In zh_CN, this message translates to:
  /// **'对齐宽高比'**
  String get playerAlignAspectRatio;

  /// No description provided for @playerAlignAspectRatioDone.
  ///
  /// In zh_CN, this message translates to:
  /// **'窗口已对齐视频比例'**
  String get playerAlignAspectRatioDone;

  /// No description provided for @playerAlignAspectRatioFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法获取视频尺寸'**
  String get playerAlignAspectRatioFailed;

  /// No description provided for @commonClose.
  ///
  /// In zh_CN, this message translates to:
  /// **'关闭'**
  String get commonClose;

  /// No description provided for @playerPlaybackError.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放出错'**
  String get playerPlaybackError;

  /// No description provided for @playerAllEpisodesPlayed.
  ///
  /// In zh_CN, this message translates to:
  /// **'已播放完全部 {count} 集'**
  String playerAllEpisodesPlayed(int count);

  /// No description provided for @playerFastForwarding.
  ///
  /// In zh_CN, this message translates to:
  /// **'{rate} 倍速播放中'**
  String playerFastForwarding(String rate);

  /// No description provided for @playerTapToSave.
  ///
  /// In zh_CN, this message translates to:
  /// **'点我保存'**
  String get playerTapToSave;

  /// No description provided for @playerResetScreen.
  ///
  /// In zh_CN, this message translates to:
  /// **'还原屏幕'**
  String get playerResetScreen;

  /// No description provided for @playerBackTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'转到上一层级'**
  String get playerBackTooltip;

  /// No description provided for @playerRotate90.
  ///
  /// In zh_CN, this message translates to:
  /// **'旋转90度'**
  String get playerRotate90;

  /// No description provided for @playerQuality.
  ///
  /// In zh_CN, this message translates to:
  /// **'画质'**
  String get playerQuality;

  /// No description provided for @playerQualityLocked.
  ///
  /// In zh_CN, this message translates to:
  /// **'该画质不可用（需登录或大会员）'**
  String get playerQualityLocked;

  /// No description provided for @playerFullscreen.
  ///
  /// In zh_CN, this message translates to:
  /// **'全屏'**
  String get playerFullscreen;

  /// No description provided for @playerBiliSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'B站字幕'**
  String get playerBiliSubtitle;

  /// No description provided for @playerDecodeFormat.
  ///
  /// In zh_CN, this message translates to:
  /// **'解码格式'**
  String get playerDecodeFormat;

  /// No description provided for @playerDecodeFormatSwitchFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'切换解码格式失败'**
  String get playerDecodeFormatSwitchFailed;

  /// No description provided for @playerDecodeAuto.
  ///
  /// In zh_CN, this message translates to:
  /// **'自动'**
  String get playerDecodeAuto;

  /// No description provided for @playerDecodeAutoShort.
  ///
  /// In zh_CN, this message translates to:
  /// **'自动'**
  String get playerDecodeAutoShort;

  /// No description provided for @playerDecodeAvc.
  ///
  /// In zh_CN, this message translates to:
  /// **'AVC / H.264'**
  String get playerDecodeAvc;

  /// No description provided for @playerDecodeHevc.
  ///
  /// In zh_CN, this message translates to:
  /// **'HEVC / H.265'**
  String get playerDecodeHevc;

  /// No description provided for @playerDecodeAv1.
  ///
  /// In zh_CN, this message translates to:
  /// **'AV1'**
  String get playerDecodeAv1;

  /// No description provided for @playerSubtitleLoadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'字幕加载失败'**
  String get playerSubtitleLoadFailed;

  /// No description provided for @playerPortraitMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'竖屏模式'**
  String get playerPortraitMode;

  /// No description provided for @playerLandscapeMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'横屏模式'**
  String get playerLandscapeMode;

  /// No description provided for @playerDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'简介'**
  String get playerDescription;

  /// No description provided for @playerWebdavSource.
  ///
  /// In zh_CN, this message translates to:
  /// **'WebDAV 视频源'**
  String get playerWebdavSource;

  /// No description provided for @playerCast.
  ///
  /// In zh_CN, this message translates to:
  /// **'投屏'**
  String get playerCast;

  /// No description provided for @playerWatchTogether.
  ///
  /// In zh_CN, this message translates to:
  /// **'一起看'**
  String get playerWatchTogether;

  /// No description provided for @watchInviteTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'邀请你一起看视频'**
  String get watchInviteTitle;

  /// No description provided for @watchWaitingAccept.
  ///
  /// In zh_CN, this message translates to:
  /// **'等待对方接受…'**
  String get watchWaitingAccept;

  /// No description provided for @watchSelectPeer.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择一起看的好友'**
  String get watchSelectPeer;

  /// No description provided for @watchNoOnlinePeer.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有在线的联系人'**
  String get watchNoOnlinePeer;

  /// No description provided for @watchInviteSent.
  ///
  /// In zh_CN, this message translates to:
  /// **'已发送一起看邀请给 {name}'**
  String watchInviteSent(String name);

  /// No description provided for @watchActiveWith.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在与 {name} 一起看'**
  String watchActiveWith(String name);

  /// No description provided for @watchPeerRejected.
  ///
  /// In zh_CN, this message translates to:
  /// **'对方拒绝了你的邀请'**
  String get watchPeerRejected;

  /// No description provided for @watchPeerNoAnswer.
  ///
  /// In zh_CN, this message translates to:
  /// **'对方没有接受邀请'**
  String get watchPeerNoAnswer;

  /// No description provided for @watchPeerLeft.
  ///
  /// In zh_CN, this message translates to:
  /// **'对方已退出一起看'**
  String get watchPeerLeft;

  /// No description provided for @watchTcpFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法建立连接，一起看失败'**
  String get watchTcpFailed;

  /// No description provided for @watchConnectionDropped.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接已断开，一起看失败'**
  String get watchConnectionDropped;

  /// No description provided for @watchUrlInvalid.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频地址不可用，无法发起一起看'**
  String get watchUrlInvalid;

  /// No description provided for @rcInviteTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'请求远程控制你的设备'**
  String get rcInviteTitle;

  /// No description provided for @rcInviteHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'同意后对方可以看到你的屏幕并操作你的设备'**
  String get rcInviteHint;

  /// No description provided for @rcPeerRejected.
  ///
  /// In zh_CN, this message translates to:
  /// **'对方拒绝了远程控制请求'**
  String get rcPeerRejected;

  /// No description provided for @rcTcpFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法建立连接，远程控制失败'**
  String get rcTcpFailed;

  /// No description provided for @rcConnectionDropped.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接已断开，远程控制失败'**
  String get rcConnectionDropped;

  /// No description provided for @rcTimeout.
  ///
  /// In zh_CN, this message translates to:
  /// **'等待对方响应超时'**
  String get rcTimeout;

  /// No description provided for @rcShizukuNotInstalled.
  ///
  /// In zh_CN, this message translates to:
  /// **'对方设备未安装 Shizuku'**
  String get rcShizukuNotInstalled;

  /// No description provided for @rcShizukuNotInstalledHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'被控端需要安装并启动 Shizuku 服务（shizuku.rikka.app）'**
  String get rcShizukuNotInstalledHint;

  /// No description provided for @rcShizukuGrantTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'需要 Shizuku 授权'**
  String get rcShizukuGrantTitle;

  /// No description provided for @rcShizukuGrantHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'被控端授予 Navi Shizuku 权限后，对方才能远程操作屏幕'**
  String get rcShizukuGrantHint;

  /// No description provided for @rcShizukuGrant.
  ///
  /// In zh_CN, this message translates to:
  /// **'授权 Shizuku'**
  String get rcShizukuGrant;

  /// No description provided for @rcRequesting.
  ///
  /// In zh_CN, this message translates to:
  /// **'请求中…'**
  String get rcRequesting;

  /// No description provided for @rcShizukuNotGranted.
  ///
  /// In zh_CN, this message translates to:
  /// **'Shizuku 未授权'**
  String get rcShizukuNotGranted;

  /// No description provided for @rcScreenCaptureFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'屏幕采集失败：{error}'**
  String rcScreenCaptureFailed(String error);

  /// No description provided for @rcShareFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'屏幕共享失败'**
  String get rcShareFailed;

  /// No description provided for @rcRetry.
  ///
  /// In zh_CN, this message translates to:
  /// **'重试'**
  String get rcRetry;

  /// No description provided for @rcClose.
  ///
  /// In zh_CN, this message translates to:
  /// **'关闭'**
  String get rcClose;

  /// No description provided for @rcCancel.
  ///
  /// In zh_CN, this message translates to:
  /// **'取消'**
  String get rcCancel;

  /// No description provided for @rcSend.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送'**
  String get rcSend;

  /// No description provided for @rcConnecting.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在连接…'**
  String get rcConnecting;

  /// No description provided for @rcControlling.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在远程控制 {name}'**
  String rcControlling(String name);

  /// No description provided for @rcBeingControlled.
  ///
  /// In zh_CN, this message translates to:
  /// **'{name} 正在远程控制你的设备'**
  String rcBeingControlled(String name);

  /// No description provided for @rcEnd.
  ///
  /// In zh_CN, this message translates to:
  /// **'结束远程控制'**
  String get rcEnd;

  /// No description provided for @rcConnectionLost.
  ///
  /// In zh_CN, this message translates to:
  /// **'远程控制连接已断开'**
  String get rcConnectionLost;

  /// No description provided for @rcSessionEnded.
  ///
  /// In zh_CN, this message translates to:
  /// **'远程控制已结束'**
  String get rcSessionEnded;

  /// No description provided for @rcInputText.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入文字'**
  String get rcInputText;

  /// No description provided for @rcInputTextHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'要发送到对方设备上的文字'**
  String get rcInputTextHint;

  /// No description provided for @rcKeyBack.
  ///
  /// In zh_CN, this message translates to:
  /// **'返回'**
  String get rcKeyBack;

  /// No description provided for @rcKeyHome.
  ///
  /// In zh_CN, this message translates to:
  /// **'主页'**
  String get rcKeyHome;

  /// No description provided for @rcKeyRecents.
  ///
  /// In zh_CN, this message translates to:
  /// **'最近任务'**
  String get rcKeyRecents;

  /// No description provided for @rcKeyVolumeUp.
  ///
  /// In zh_CN, this message translates to:
  /// **'音量+'**
  String get rcKeyVolumeUp;

  /// No description provided for @rcKeyVolumeDown.
  ///
  /// In zh_CN, this message translates to:
  /// **'音量-'**
  String get rcKeyVolumeDown;

  /// No description provided for @dlnaPageTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'投屏'**
  String get dlnaPageTitle;

  /// No description provided for @dlnaRefresh.
  ///
  /// In zh_CN, this message translates to:
  /// **'重新搜索'**
  String get dlnaRefresh;

  /// No description provided for @dlnaSearching.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在搜索局域网投屏设备…'**
  String get dlnaSearching;

  /// No description provided for @dlnaNoDevice.
  ///
  /// In zh_CN, this message translates to:
  /// **'未发现可投屏设备'**
  String get dlnaNoDevice;

  /// No description provided for @dlnaNoDeviceHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'请确认电视/盒子与本机处于同一局域网，且已开启 DLNA/投屏功能'**
  String get dlnaNoDeviceHint;

  /// No description provided for @dlnaSearchAgain.
  ///
  /// In zh_CN, this message translates to:
  /// **'重新搜索'**
  String get dlnaSearchAgain;

  /// No description provided for @dlnaFoundDevices.
  ///
  /// In zh_CN, this message translates to:
  /// **'发现设备'**
  String get dlnaFoundDevices;

  /// No description provided for @dlnaCastStarted.
  ///
  /// In zh_CN, this message translates to:
  /// **'已投屏到 {device}'**
  String dlnaCastStarted(String device);

  /// No description provided for @dlnaCastFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'投屏失败：{device}'**
  String dlnaCastFailed(String device);

  /// No description provided for @dlnaCastingTo.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在投屏到 {device}'**
  String dlnaCastingTo(String device);

  /// No description provided for @dlnaStopCast.
  ///
  /// In zh_CN, this message translates to:
  /// **'停止投屏'**
  String get dlnaStopCast;

  /// No description provided for @dlnaPlay.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放'**
  String get dlnaPlay;

  /// No description provided for @dlnaPause.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂停'**
  String get dlnaPause;

  /// No description provided for @dlnaVolumeUp.
  ///
  /// In zh_CN, this message translates to:
  /// **'增大音量'**
  String get dlnaVolumeUp;

  /// No description provided for @dlnaVolumeDown.
  ///
  /// In zh_CN, this message translates to:
  /// **'减小音量'**
  String get dlnaVolumeDown;

  /// No description provided for @dlnaFileMissing.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频文件不存在'**
  String get dlnaFileMissing;

  /// No description provided for @dlnaServerStartFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地文件服务启动失败：{error}'**
  String dlnaServerStartFailed(String error);

  /// No description provided for @playerEpisodeSelect.
  ///
  /// In zh_CN, this message translates to:
  /// **'选集'**
  String get playerEpisodeSelect;

  /// No description provided for @playerDanmakuSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕设置'**
  String get playerDanmakuSettings;

  /// No description provided for @psTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放器'**
  String get psTitle;

  /// No description provided for @psBackTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'转到上一层级'**
  String get psBackTooltip;

  /// No description provided for @psStaffEntrance.
  ///
  /// In zh_CN, this message translates to:
  /// **'员工通道'**
  String get psStaffEntrance;

  /// No description provided for @psDisplaySection.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示'**
  String get psDisplaySection;

  /// No description provided for @psStatusBar.
  ///
  /// In zh_CN, this message translates to:
  /// **'状态栏'**
  String get psStatusBar;

  /// No description provided for @psStatusBarDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'在播放器顶部显示时间、电量与网络图标'**
  String get psStatusBarDesc;

  /// No description provided for @psKeepWindowRatio.
  ///
  /// In zh_CN, this message translates to:
  /// **'等比例拉伸窗口'**
  String get psKeepWindowRatio;

  /// No description provided for @psKeepWindowRatioDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放时窗口仅允许按当前比例缩放'**
  String get psKeepWindowRatioDesc;

  /// No description provided for @psKeepWindowRatioDesktopOnly.
  ///
  /// In zh_CN, this message translates to:
  /// **'仅 Windows / macOS / Linux 桌面平台生效'**
  String get psKeepWindowRatioDesktopOnly;

  /// No description provided for @psInteractionSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'交互'**
  String get psInteractionSection;

  /// No description provided for @psLongPressSpeed.
  ///
  /// In zh_CN, this message translates to:
  /// **'长按键加速'**
  String get psLongPressSpeed;

  /// No description provided for @psLongPressSpeedDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'按住屏幕或键盘 D 键以 2× 倍速快进'**
  String get psLongPressSpeedDesc;

  /// No description provided for @psScreenshot.
  ///
  /// In zh_CN, this message translates to:
  /// **'截图功能'**
  String get psScreenshot;

  /// No description provided for @psScreenshotDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'允许在播放器中截取当前画面并保存至相册'**
  String get psScreenshotDesc;

  /// No description provided for @psScreenshotDanmaku.
  ///
  /// In zh_CN, this message translates to:
  /// **'截图时显示弹幕'**
  String get psScreenshotDanmaku;

  /// No description provided for @psScreenshotDanmakuDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'截图时把当前弹幕一并截入画面'**
  String get psScreenshotDanmakuDesc;

  /// No description provided for @psProgressSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'进度'**
  String get psProgressSection;

  /// No description provided for @psPlayProgress.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放进度'**
  String get psPlayProgress;

  /// No description provided for @psNoHistory.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无保存的播放记录'**
  String get psNoHistory;

  /// No description provided for @psHistoryCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'您有 {count} 条记录'**
  String psHistoryCount(int count);

  /// No description provided for @psMiscSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'杂项'**
  String get psMiscSection;

  /// No description provided for @psHwdec.
  ///
  /// In zh_CN, this message translates to:
  /// **'硬件解码'**
  String get psHwdec;

  /// No description provided for @psHwdecAuto.
  ///
  /// In zh_CN, this message translates to:
  /// **'自动选择最佳解码器'**
  String get psHwdecAuto;

  /// No description provided for @psHwdecSoftware.
  ///
  /// In zh_CN, this message translates to:
  /// **'强制使用 CPU 软件解码'**
  String get psHwdecSoftware;

  /// No description provided for @psHwdecAutoShort.
  ///
  /// In zh_CN, this message translates to:
  /// **'自动'**
  String get psHwdecAutoShort;

  /// No description provided for @psHwdecPureSoftware.
  ///
  /// In zh_CN, this message translates to:
  /// **'纯软解'**
  String get psHwdecPureSoftware;

  /// No description provided for @psVideoSync.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频同步'**
  String get psVideoSync;

  /// No description provided for @psVsyncAudioDefault.
  ///
  /// In zh_CN, this message translates to:
  /// **'以音频时钟为基准（默认）'**
  String get psVsyncAudioDefault;

  /// No description provided for @psVsyncResample.
  ///
  /// In zh_CN, this message translates to:
  /// **'重采样音频以匹配显示刷新率'**
  String get psVsyncResample;

  /// No description provided for @psVsyncAdrop.
  ///
  /// In zh_CN, this message translates to:
  /// **'丢弃 / 重复音频帧以匹配显示'**
  String get psVsyncAdrop;

  /// No description provided for @psVsyncVdrop.
  ///
  /// In zh_CN, this message translates to:
  /// **'丢弃 / 重复视频帧以匹配显示'**
  String get psVsyncVdrop;

  /// No description provided for @psVsyncAudio.
  ///
  /// In zh_CN, this message translates to:
  /// **'音频'**
  String get psVsyncAudio;

  /// No description provided for @psVsyncDisplayResample.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示重采样'**
  String get psVsyncDisplayResample;

  /// No description provided for @psVsyncDisplayAdrop.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示音频丢弃'**
  String get psVsyncDisplayAdrop;

  /// No description provided for @psVsyncDisplayVdrop.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示视频丢弃'**
  String get psVsyncDisplayVdrop;

  /// No description provided for @psImmersiveLongPress.
  ///
  /// In zh_CN, this message translates to:
  /// **'沉浸模式长按加速'**
  String get psImmersiveLongPress;

  /// No description provided for @psImmersiveLongPressDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'控制栏隐藏时仍可通过长按触发 2× 倍速'**
  String get psImmersiveLongPressDesc;

  /// No description provided for @psLogSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'日志'**
  String get psLogSection;

  /// No description provided for @psMpvLog.
  ///
  /// In zh_CN, this message translates to:
  /// **'记录 mpv 日志'**
  String get psMpvLog;

  /// No description provided for @psMpvLogEnabled.
  ///
  /// In zh_CN, this message translates to:
  /// **'已开启，下次播放生效（细度：{level}）'**
  String psMpvLogEnabled(String level);

  /// No description provided for @psMpvLogDisabled.
  ///
  /// In zh_CN, this message translates to:
  /// **'关闭。崩溃日志始终记录，不受此开关影响'**
  String get psMpvLogDisabled;

  /// No description provided for @psMpvLogLevel.
  ///
  /// In zh_CN, this message translates to:
  /// **'mpv 日志细度'**
  String get psMpvLogLevel;

  /// No description provided for @psMpvLogLevelDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'细度越高日志越详细，占用空间也越大'**
  String get psMpvLogLevelDesc;

  /// No description provided for @psMpvLogError.
  ///
  /// In zh_CN, this message translates to:
  /// **'仅错误'**
  String get psMpvLogError;

  /// No description provided for @psMpvLogWarn.
  ///
  /// In zh_CN, this message translates to:
  /// **'警告'**
  String get psMpvLogWarn;

  /// No description provided for @psMpvLogWarnDefault.
  ///
  /// In zh_CN, this message translates to:
  /// **'警告（默认）'**
  String get psMpvLogWarnDefault;

  /// No description provided for @psMpvLogInfo.
  ///
  /// In zh_CN, this message translates to:
  /// **'信息'**
  String get psMpvLogInfo;

  /// No description provided for @psMpvLogVerbose.
  ///
  /// In zh_CN, this message translates to:
  /// **'详细'**
  String get psMpvLogVerbose;

  /// No description provided for @psMpvLogDebug.
  ///
  /// In zh_CN, this message translates to:
  /// **'调试'**
  String get psMpvLogDebug;

  /// No description provided for @psMpvLogTrace.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部（极详细）'**
  String get psMpvLogTrace;

  /// No description provided for @psViewLogs.
  ///
  /// In zh_CN, this message translates to:
  /// **'查看日志'**
  String get psViewLogs;

  /// No description provided for @psViewLogsDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'浏览错误日志与 mpv 日志，支持分享与清除'**
  String get psViewLogsDesc;

  /// No description provided for @testPlaylistCreated.
  ///
  /// In zh_CN, this message translates to:
  /// **'已创建: {name}'**
  String testPlaylistCreated(String name);

  /// No description provided for @testPageTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'测试页'**
  String get testPageTitle;

  /// No description provided for @testVideoSourceSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频来源'**
  String get testVideoSourceSection;

  /// No description provided for @testVideoSourceSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择一个来源开始播放'**
  String get testVideoSourceSubtitle;

  /// No description provided for @testWebdavVideo.
  ///
  /// In zh_CN, this message translates to:
  /// **'WebDAV 视频'**
  String get testWebdavVideo;

  /// No description provided for @testWebdavVideoDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'从 WebDAV 服务器浏览并播放'**
  String get testWebdavVideoDesc;

  /// No description provided for @testLocalVideo.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地视频'**
  String get testLocalVideo;

  /// No description provided for @testLocalVideoDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'从设备存储中选择视频文件'**
  String get testLocalVideoDesc;

  /// No description provided for @testRecentSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'最近播放'**
  String get testRecentSection;

  /// No description provided for @testLastPlayedSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'上次播放记录'**
  String get testLastPlayedSubtitle;

  /// No description provided for @testNoRecords.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无播放记录'**
  String get testNoRecords;

  /// No description provided for @testPlaylistSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放列表'**
  String get testPlaylistSection;

  /// No description provided for @testPlaylistSectionSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'创建、管理播放列表，选集播放'**
  String get testPlaylistSectionSubtitle;

  /// No description provided for @testPlaylistManage.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放列表管理'**
  String get testPlaylistManage;

  /// No description provided for @testPlaylistManageDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'查看 / 编辑 / 删除播放列表，点击直接播放'**
  String get testPlaylistManageDesc;

  /// No description provided for @testPlaylistCreate.
  ///
  /// In zh_CN, this message translates to:
  /// **'新建播放列表'**
  String get testPlaylistCreate;

  /// No description provided for @testPlaylistCreateDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'WebDAV 多选文件建表 / 手动逐集导入'**
  String get testPlaylistCreateDesc;

  /// No description provided for @testQuickActionsSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'快捷操作'**
  String get testQuickActionsSection;

  /// No description provided for @testQuickActionsSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'常用测试入口'**
  String get testQuickActionsSubtitle;

  /// No description provided for @testUrlDirectPlay.
  ///
  /// In zh_CN, this message translates to:
  /// **'URL 直接播放'**
  String get testUrlDirectPlay;

  /// No description provided for @testUrlDirectPlayDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入视频 URL 直接播放'**
  String get testUrlDirectPlayDesc;

  /// No description provided for @testVideoWithSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频 + 字幕'**
  String get testVideoWithSubtitle;

  /// No description provided for @testVideoWithSubtitleDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'同时选择视频和字幕文件'**
  String get testVideoWithSubtitleDesc;

  /// No description provided for @testNoVideoPlayed.
  ///
  /// In zh_CN, this message translates to:
  /// **'还没有播放过任何视频'**
  String get testNoVideoPlayed;

  /// No description provided for @testEnterUrlTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入视频 URL'**
  String get testEnterUrlTitle;

  /// No description provided for @testPlay.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放'**
  String get testPlay;

  /// No description provided for @testAddSubtitleTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加字幕？'**
  String get testAddSubtitleTitle;

  /// No description provided for @testAddSubtitlePrompt.
  ///
  /// In zh_CN, this message translates to:
  /// **'已选择视频：{name}\n是否要加载外挂字幕？'**
  String testAddSubtitlePrompt(String name);

  /// No description provided for @testSkip.
  ///
  /// In zh_CN, this message translates to:
  /// **'跳过'**
  String get testSkip;

  /// No description provided for @testSelectSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择字幕'**
  String get testSelectSubtitle;

  /// No description provided for @testAboutLegalese.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放器前端测试页面'**
  String get testAboutLegalese;

  /// No description provided for @testAboutBody.
  ///
  /// In zh_CN, this message translates to:
  /// **'此页面用于测试 MpvPlayerPage 的各种入口：\n• WebDAV 远程视频\n• 本地视频文件\n• URL 直接播放\n• 视频 + 外挂字幕'**
  String get testAboutBody;

  /// No description provided for @testSourceLocal.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地文件'**
  String get testSourceLocal;

  /// No description provided for @testSourceLocalSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地 + 字幕'**
  String get testSourceLocalSubtitle;

  /// No description provided for @accountsBiliLoginSuccess.
  ///
  /// In zh_CN, this message translates to:
  /// **'B 站登录成功'**
  String get accountsBiliLoginSuccess;

  /// No description provided for @accountsBiliLogoutTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'退出 B 站登录？'**
  String get accountsBiliLogoutTitle;

  /// No description provided for @accountsBiliLogoutHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'退出后将不再携带 Cookie 请求 B 站 API。'**
  String get accountsBiliLogoutHint;

  /// No description provided for @accountsClearWebviewCookieTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'同时清空内置浏览器 Cookie'**
  String get accountsClearWebviewCookieTitle;

  /// No description provided for @accountsClearWebviewCookieSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'不勾选也没关系，之后可在账号设置里手动清除'**
  String get accountsClearWebviewCookieSubtitle;

  /// No description provided for @accountsLogout.
  ///
  /// In zh_CN, this message translates to:
  /// **'退出'**
  String get accountsLogout;

  /// No description provided for @accountsLoggedOutWithCookie.
  ///
  /// In zh_CN, this message translates to:
  /// **'已退出登录并清空浏览器 Cookie'**
  String get accountsLoggedOutWithCookie;

  /// No description provided for @accountsLoggedOut.
  ///
  /// In zh_CN, this message translates to:
  /// **'已退出登录'**
  String get accountsLoggedOut;

  /// No description provided for @accountsClearCookieTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空内置浏览器 Cookie？'**
  String get accountsClearCookieTitle;

  /// No description provided for @accountsClearCookieContent.
  ///
  /// In zh_CN, this message translates to:
  /// **'将清除内置浏览器保存的全部 Cookie，包括网页端的登录状态。'**
  String get accountsClearCookieContent;

  /// No description provided for @accountsClearAction.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空'**
  String get accountsClearAction;

  /// No description provided for @accountsCookieCleared.
  ///
  /// In zh_CN, this message translates to:
  /// **'已清空内置浏览器 Cookie'**
  String get accountsCookieCleared;

  /// No description provided for @accountsCookieEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无内置浏览器 Cookie 可清（浏览器未使用过）'**
  String get accountsCookieEmpty;

  /// No description provided for @accountsBiliLoginTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'登录 B 站账号'**
  String get accountsBiliLoginTitle;

  /// No description provided for @accountsBiliLoginSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫码 / 粘贴 Cookie / 密码登录'**
  String get accountsBiliLoginSubtitle;

  /// No description provided for @accountsClearBrowserCookie.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空内置浏览器 Cookie'**
  String get accountsClearBrowserCookie;

  /// No description provided for @accountsClearBrowserCookieSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'清除网页端残留登录态'**
  String get accountsClearBrowserCookieSubtitle;

  /// No description provided for @accountsLoggedIn.
  ///
  /// In zh_CN, this message translates to:
  /// **'已登录'**
  String get accountsLoggedIn;

  /// No description provided for @accountsLoggedInUid.
  ///
  /// In zh_CN, this message translates to:
  /// **'已登录 · UID {mid}'**
  String accountsLoggedInUid(int mid);

  /// No description provided for @accountsCarryCookie.
  ///
  /// In zh_CN, this message translates to:
  /// **'携带 Cookie 请求'**
  String get accountsCarryCookie;

  /// No description provided for @accountsCarryCookieOn.
  ///
  /// In zh_CN, this message translates to:
  /// **'已开启：B 站 API 以登录身份请求'**
  String get accountsCarryCookieOn;

  /// No description provided for @accountsCarryCookieOff.
  ///
  /// In zh_CN, this message translates to:
  /// **'已关闭：B 站 API 以游客身份请求'**
  String get accountsCarryCookieOff;

  /// No description provided for @accountsCookieScope.
  ///
  /// In zh_CN, this message translates to:
  /// **'Cookie 使用范围'**
  String get accountsCookieScope;

  /// No description provided for @accountsCookieScopeSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择哪些请求使用账号 Cookie'**
  String get accountsCookieScopeSubtitle;

  /// No description provided for @cookieScopeTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'Cookie 使用范围'**
  String get cookieScopeTitle;

  /// No description provided for @cookieScopeHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'仅影响以下请求类型；「携带 Cookie 请求」总开关关闭时，下列设置不生效。B 站在线收藏夹操作始终携带登录 Cookie。'**
  String get cookieScopeHint;

  /// No description provided for @cookieScopeVideo.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频详情与播放'**
  String get cookieScopeVideo;

  /// No description provided for @cookieScopeVideoDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频详情、播放地址与历史进度上报'**
  String get cookieScopeVideoDesc;

  /// No description provided for @cookieScopeComments.
  ///
  /// In zh_CN, this message translates to:
  /// **'评论'**
  String get cookieScopeComments;

  /// No description provided for @cookieScopeCommentsDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'评论区列表请求'**
  String get cookieScopeCommentsDesc;

  /// No description provided for @cookieScopeSearch.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索'**
  String get cookieScopeSearch;

  /// No description provided for @cookieScopeSearchDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索建议与搜索结果请求'**
  String get cookieScopeSearchDesc;

  /// No description provided for @cookieScopeArticle.
  ///
  /// In zh_CN, this message translates to:
  /// **'专栏与动态'**
  String get cookieScopeArticle;

  /// No description provided for @cookieScopeArticleDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'专栏文章与动态内容请求'**
  String get cookieScopeArticleDesc;

  /// No description provided for @cookieScopeUserSpace.
  ///
  /// In zh_CN, this message translates to:
  /// **'用户空间'**
  String get cookieScopeUserSpace;

  /// No description provided for @cookieScopeUserSpaceDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'UP 主空间、投稿与粉丝列表请求'**
  String get cookieScopeUserSpaceDesc;

  /// No description provided for @cookieScopeSeason.
  ///
  /// In zh_CN, this message translates to:
  /// **'番剧与剧集'**
  String get cookieScopeSeason;

  /// No description provided for @cookieScopeSeasonDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'番剧详情与剧集列表请求'**
  String get cookieScopeSeasonDesc;

  /// No description provided for @cookieScopeInteractions.
  ///
  /// In zh_CN, this message translates to:
  /// **'互动操作'**
  String get cookieScopeInteractions;

  /// No description provided for @cookieScopeInteractionsDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'点赞、投币、收藏、关注、发送弹幕等；关闭后无法互动'**
  String get cookieScopeInteractionsDesc;

  /// No description provided for @cookieScopeEnableAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部开启'**
  String get cookieScopeEnableAll;

  /// No description provided for @cookieScopeDisableAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部关闭'**
  String get cookieScopeDisableAll;

  /// No description provided for @accountsWebdavCloud.
  ///
  /// In zh_CN, this message translates to:
  /// **'WebDAV 云盘'**
  String get accountsWebdavCloud;

  /// No description provided for @accountsWebdavConfiguredOn.
  ///
  /// In zh_CN, this message translates to:
  /// **'已配置 · 自动备份已开启'**
  String get accountsWebdavConfiguredOn;

  /// No description provided for @accountsWebdavConfiguredOff.
  ///
  /// In zh_CN, this message translates to:
  /// **'已配置 · 自动备份未开启'**
  String get accountsWebdavConfiguredOff;

  /// No description provided for @accountsWebdavNotConfigured.
  ///
  /// In zh_CN, this message translates to:
  /// **'未配置 · 点击进入设置'**
  String get accountsWebdavNotConfigured;

  /// No description provided for @accountsTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'账号'**
  String get accountsTitle;

  /// No description provided for @accountsSectionBili.
  ///
  /// In zh_CN, this message translates to:
  /// **'B 站账号'**
  String get accountsSectionBili;

  /// No description provided for @commonBackTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'转到上一层级'**
  String get commonBackTooltip;

  /// No description provided for @biliLoginFetchingQr.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在获取二维码…'**
  String get biliLoginFetchingQr;

  /// No description provided for @biliLoginQrFetchFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'获取二维码失败，请检查网络'**
  String get biliLoginQrFetchFailed;

  /// No description provided for @biliLoginScanWithApp.
  ///
  /// In zh_CN, this message translates to:
  /// **'请使用 B 站 App 扫码登录'**
  String get biliLoginScanWithApp;

  /// No description provided for @biliLoginInputAccountPwd.
  ///
  /// In zh_CN, this message translates to:
  /// **'请输入账号和密码'**
  String get biliLoginInputAccountPwd;

  /// No description provided for @biliLoginFailedRetry.
  ///
  /// In zh_CN, this message translates to:
  /// **'登录失败，请重试'**
  String get biliLoginFailedRetry;

  /// No description provided for @biliLoginTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'B 站登录'**
  String get biliLoginTitle;

  /// No description provided for @biliLoginScanMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫码登录'**
  String get biliLoginScanMode;

  /// No description provided for @biliLoginCookieMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'粘贴 Cookie'**
  String get biliLoginCookieMode;

  /// No description provided for @biliLoginPwdMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'密码登录'**
  String get biliLoginPwdMode;

  /// No description provided for @biliLoginViaBrowser.
  ///
  /// In zh_CN, this message translates to:
  /// **'使用内置浏览器登录'**
  String get biliLoginViaBrowser;

  /// No description provided for @biliLoginCookieHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'登录后「携带 Cookie 请求」默认开启，可在 设置 → 账号 中关闭'**
  String get biliLoginCookieHint;

  /// No description provided for @biliLoginWebTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'网页版登录'**
  String get biliLoginWebTitle;

  /// No description provided for @biliLoginCookieImportFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'网页登录 Cookie 导入失败，请重试或改用其他方式'**
  String get biliLoginCookieImportFailed;

  /// No description provided for @biliLoginRefetch.
  ///
  /// In zh_CN, this message translates to:
  /// **'重新获取'**
  String get biliLoginRefetch;

  /// No description provided for @biliLoginRefreshQr.
  ///
  /// In zh_CN, this message translates to:
  /// **'刷新二维码'**
  String get biliLoginRefreshQr;

  /// No description provided for @biliLoginScanTip.
  ///
  /// In zh_CN, this message translates to:
  /// **'提示：打开 B 站 App → 扫一扫，或用「哔哩哔哩」小程序扫码'**
  String get biliLoginScanTip;

  /// No description provided for @biliLoginCookieInstruction.
  ///
  /// In zh_CN, this message translates to:
  /// **'在电脑浏览器登录 bilibili.com，按 F12 打开开发者工具 → Application → Cookies → bilibili.com，复制全部 Cookie（以 SESSDATA= 开头的一串），粘贴到下方输入框'**
  String get biliLoginCookieInstruction;

  /// No description provided for @biliLoginVerifying.
  ///
  /// In zh_CN, this message translates to:
  /// **'校验中…'**
  String get biliLoginVerifying;

  /// No description provided for @biliLoginVerifyAndLogin.
  ///
  /// In zh_CN, this message translates to:
  /// **'登录并校验'**
  String get biliLoginVerifyAndLogin;

  /// No description provided for @biliLoginAccountLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'账号（手机号 / 邮箱 / 用户名）'**
  String get biliLoginAccountLabel;

  /// No description provided for @biliLoginPasswordLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'密码'**
  String get biliLoginPasswordLabel;

  /// No description provided for @biliLoginLoggingIn.
  ///
  /// In zh_CN, this message translates to:
  /// **'登录中…'**
  String get biliLoginLoggingIn;

  /// No description provided for @biliLoginLoginAction.
  ///
  /// In zh_CN, this message translates to:
  /// **'登录'**
  String get biliLoginLoginAction;

  /// No description provided for @biliLoginSliderHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'账号密码登录可能触发滑块验证码，完成验证后会自动重试'**
  String get biliLoginSliderHint;

  /// No description provided for @searchFilterAny.
  ///
  /// In zh_CN, this message translates to:
  /// **'不限'**
  String get searchFilterAny;

  /// No description provided for @searchFilterLastDay.
  ///
  /// In zh_CN, this message translates to:
  /// **'最近一天'**
  String get searchFilterLastDay;

  /// No description provided for @searchFilterLastWeek.
  ///
  /// In zh_CN, this message translates to:
  /// **'最近一周'**
  String get searchFilterLastWeek;

  /// No description provided for @searchFilterHalfYear.
  ///
  /// In zh_CN, this message translates to:
  /// **'最近半年'**
  String get searchFilterHalfYear;

  /// No description provided for @searchFilterAllDuration.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部时长'**
  String get searchFilterAllDuration;

  /// No description provided for @searchFilterDur0to10.
  ///
  /// In zh_CN, this message translates to:
  /// **'0-10分钟'**
  String get searchFilterDur0to10;

  /// No description provided for @searchFilterDur10to30.
  ///
  /// In zh_CN, this message translates to:
  /// **'10-30分钟'**
  String get searchFilterDur10to30;

  /// No description provided for @searchFilterDur30to60.
  ///
  /// In zh_CN, this message translates to:
  /// **'30-60分钟'**
  String get searchFilterDur30to60;

  /// No description provided for @searchFilterDur60plus.
  ///
  /// In zh_CN, this message translates to:
  /// **'60分钟+'**
  String get searchFilterDur60plus;

  /// No description provided for @searchZoneAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部'**
  String get searchZoneAll;

  /// No description provided for @searchZoneAnime.
  ///
  /// In zh_CN, this message translates to:
  /// **'动画'**
  String get searchZoneAnime;

  /// No description provided for @searchZoneGuochuang.
  ///
  /// In zh_CN, this message translates to:
  /// **'国创'**
  String get searchZoneGuochuang;

  /// No description provided for @searchZoneMusic.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐'**
  String get searchZoneMusic;

  /// No description provided for @searchZoneDance.
  ///
  /// In zh_CN, this message translates to:
  /// **'舞蹈'**
  String get searchZoneDance;

  /// No description provided for @searchZoneGame.
  ///
  /// In zh_CN, this message translates to:
  /// **'游戏'**
  String get searchZoneGame;

  /// No description provided for @searchZoneKnowledge.
  ///
  /// In zh_CN, this message translates to:
  /// **'知识'**
  String get searchZoneKnowledge;

  /// No description provided for @searchZoneTech.
  ///
  /// In zh_CN, this message translates to:
  /// **'科技'**
  String get searchZoneTech;

  /// No description provided for @searchZoneSports.
  ///
  /// In zh_CN, this message translates to:
  /// **'运动'**
  String get searchZoneSports;

  /// No description provided for @searchZoneCar.
  ///
  /// In zh_CN, this message translates to:
  /// **'汽车'**
  String get searchZoneCar;

  /// No description provided for @searchZoneLife.
  ///
  /// In zh_CN, this message translates to:
  /// **'生活'**
  String get searchZoneLife;

  /// No description provided for @searchZoneFood.
  ///
  /// In zh_CN, this message translates to:
  /// **'美食'**
  String get searchZoneFood;

  /// No description provided for @searchZoneAnimal.
  ///
  /// In zh_CN, this message translates to:
  /// **'动物'**
  String get searchZoneAnimal;

  /// No description provided for @searchZoneKichiku.
  ///
  /// In zh_CN, this message translates to:
  /// **'鬼畜'**
  String get searchZoneKichiku;

  /// No description provided for @searchZoneFashion.
  ///
  /// In zh_CN, this message translates to:
  /// **'时尚'**
  String get searchZoneFashion;

  /// No description provided for @searchZoneInfo.
  ///
  /// In zh_CN, this message translates to:
  /// **'资讯'**
  String get searchZoneInfo;

  /// No description provided for @searchZoneEnt.
  ///
  /// In zh_CN, this message translates to:
  /// **'娱乐'**
  String get searchZoneEnt;

  /// No description provided for @searchZoneDoc.
  ///
  /// In zh_CN, this message translates to:
  /// **'记录'**
  String get searchZoneDoc;

  /// No description provided for @searchZoneFilm.
  ///
  /// In zh_CN, this message translates to:
  /// **'电影'**
  String get searchZoneFilm;

  /// No description provided for @searchZoneTv.
  ///
  /// In zh_CN, this message translates to:
  /// **'电视'**
  String get searchZoneTv;

  /// No description provided for @searchCaptchaInitFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'验证码初始化失败'**
  String get searchCaptchaInitFailed;

  /// No description provided for @searchCaptchaIncomplete.
  ///
  /// In zh_CN, this message translates to:
  /// **'未完成滑块验证'**
  String get searchCaptchaIncomplete;

  /// No description provided for @searchCaptchaValidateFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'验证码校验失败'**
  String get searchCaptchaValidateFailed;

  /// No description provided for @searchCaptchaValidateFailedRetry.
  ///
  /// In zh_CN, this message translates to:
  /// **'验证码校验失败，请重试'**
  String get searchCaptchaValidateFailedRetry;

  /// No description provided for @searchCaptchaPassed.
  ///
  /// In zh_CN, this message translates to:
  /// **'验证通过，正在重新搜索'**
  String get searchCaptchaPassed;

  /// No description provided for @searchBiliHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索 B 站…'**
  String get searchBiliHint;

  /// No description provided for @searchHistoryTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索历史'**
  String get searchHistoryTitle;

  /// No description provided for @searchHistoryClear.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空'**
  String get searchHistoryClear;

  /// No description provided for @searchHistoryClearConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定清空当前分区的搜索历史？'**
  String get searchHistoryClearConfirm;

  /// No description provided for @searchHistoryEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无搜索历史'**
  String get searchHistoryEmpty;

  /// No description provided for @searchVideoFilter.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频搜索筛选'**
  String get searchVideoFilter;

  /// No description provided for @searchFilterWithCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'筛选 · {count}'**
  String searchFilterWithCount(int count);

  /// No description provided for @searchFilter.
  ///
  /// In zh_CN, this message translates to:
  /// **'筛选'**
  String get searchFilter;

  /// No description provided for @searchSwitchSingleCol.
  ///
  /// In zh_CN, this message translates to:
  /// **'单列'**
  String get searchSwitchSingleCol;

  /// No description provided for @searchSwitchMulti.
  ///
  /// In zh_CN, this message translates to:
  /// **'多列'**
  String get searchSwitchMulti;

  /// No description provided for @searchLayoutMulti.
  ///
  /// In zh_CN, this message translates to:
  /// **'多列'**
  String get searchLayoutMulti;

  /// No description provided for @searchLayoutSingle.
  ///
  /// In zh_CN, this message translates to:
  /// **'单列'**
  String get searchLayoutSingle;

  /// No description provided for @searchPickStartDate.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择开始日期'**
  String get searchPickStartDate;

  /// No description provided for @searchPickEndDate.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择结束日期'**
  String get searchPickEndDate;

  /// No description provided for @searchPubTimeSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'发布时间'**
  String get searchPubTimeSection;

  /// No description provided for @searchDateBegin.
  ///
  /// In zh_CN, this message translates to:
  /// **'开始'**
  String get searchDateBegin;

  /// No description provided for @searchDateTo.
  ///
  /// In zh_CN, this message translates to:
  /// **'至'**
  String get searchDateTo;

  /// No description provided for @searchDateEnd.
  ///
  /// In zh_CN, this message translates to:
  /// **'结束'**
  String get searchDateEnd;

  /// No description provided for @searchDurationSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'内容时长'**
  String get searchDurationSection;

  /// No description provided for @searchZoneSection.
  ///
  /// In zh_CN, this message translates to:
  /// **'内容分区'**
  String get searchZoneSection;

  /// No description provided for @searchAntiFuzzy.
  ///
  /// In zh_CN, this message translates to:
  /// **'防模糊搜索'**
  String get searchAntiFuzzy;

  /// No description provided for @searchAntiFuzzyHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'限定 2009-06-26 至今的结果，避免异常早期数据干扰'**
  String get searchAntiFuzzyHint;

  /// No description provided for @searchFilterReset.
  ///
  /// In zh_CN, this message translates to:
  /// **'重置'**
  String get searchFilterReset;

  /// No description provided for @searchAllLoaded.
  ///
  /// In zh_CN, this message translates to:
  /// **'— 已全部加载 —'**
  String get searchAllLoaded;

  /// No description provided for @searchKeywordHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入关键词搜索 B 站'**
  String get searchKeywordHint;

  /// No description provided for @searchPressToSearch.
  ///
  /// In zh_CN, this message translates to:
  /// **'点击「搜索」或回车开始搜索'**
  String get searchPressToSearch;

  /// No description provided for @searchNoResultInType.
  ///
  /// In zh_CN, this message translates to:
  /// **'「{keyword}」在{type}中暂无结果'**
  String searchNoResultInType(String keyword, String type);

  /// No description provided for @searchResultsCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'{type} · 共 {count} 个结果'**
  String searchResultsCount(String type, String count);

  /// No description provided for @userSpaceLoadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'加载失败'**
  String get userSpaceLoadFailed;

  /// No description provided for @userSpaceAvatarLoadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'头像加载失败'**
  String get userSpaceAvatarLoadFailed;

  /// No description provided for @userSpaceTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'UP 主空间'**
  String get userSpaceTitle;

  /// No description provided for @userSpaceLoading.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在加载 UP 主空间…'**
  String get userSpaceLoading;

  /// No description provided for @userSpaceLoadingName.
  ///
  /// In zh_CN, this message translates to:
  /// **'加载中…'**
  String get userSpaceLoadingName;

  /// No description provided for @userSpaceStatFans.
  ///
  /// In zh_CN, this message translates to:
  /// **'粉丝'**
  String get userSpaceStatFans;

  /// No description provided for @userSpaceStatFollowing.
  ///
  /// In zh_CN, this message translates to:
  /// **'关注'**
  String get userSpaceStatFollowing;

  /// No description provided for @userSpaceStatVideos.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频'**
  String get userSpaceStatVideos;

  /// No description provided for @userSpaceStatLikes.
  ///
  /// In zh_CN, this message translates to:
  /// **'获赞'**
  String get userSpaceStatLikes;

  /// No description provided for @userSpaceVideoCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'共 {count} 个视频'**
  String userSpaceVideoCount(int count);

  /// No description provided for @userSpaceSectionAllVideos.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部视频'**
  String get userSpaceSectionAllVideos;

  /// No description provided for @userSpaceNoVideos.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无投稿'**
  String get userSpaceNoVideos;

  /// No description provided for @userSpaceDynLoadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'动态加载失败'**
  String get userSpaceDynLoadFailed;

  /// No description provided for @userSpaceNoDynamics.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无动态'**
  String get userSpaceNoDynamics;

  /// No description provided for @userSpaceBangumiLoadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'追番列表加载失败'**
  String get userSpaceBangumiLoadFailed;

  /// No description provided for @userSpaceNoBangumi.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无追番'**
  String get userSpaceNoBangumi;

  /// No description provided for @userSpaceBangumiCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'追番 · 共 {count} 部'**
  String userSpaceBangumiCount(int count);

  /// No description provided for @userSpaceLazySign.
  ///
  /// In zh_CN, this message translates to:
  /// **'这个人很懒，什么都没有留下'**
  String get userSpaceLazySign;

  /// No description provided for @userSpaceTabHome.
  ///
  /// In zh_CN, this message translates to:
  /// **'主页'**
  String get userSpaceTabHome;

  /// No description provided for @userSpaceTabDynamic.
  ///
  /// In zh_CN, this message translates to:
  /// **'动态'**
  String get userSpaceTabDynamic;

  /// No description provided for @userSpaceTabBangumi.
  ///
  /// In zh_CN, this message translates to:
  /// **'追番'**
  String get userSpaceTabBangumi;

  /// No description provided for @userSpaceToday.
  ///
  /// In zh_CN, this message translates to:
  /// **'今天'**
  String get userSpaceToday;

  /// No description provided for @userSpaceBangumiFinished.
  ///
  /// In zh_CN, this message translates to:
  /// **'完结'**
  String get userSpaceBangumiFinished;

  /// No description provided for @userSpaceBangumiSerializing.
  ///
  /// In zh_CN, this message translates to:
  /// **'连载中'**
  String get userSpaceBangumiSerializing;

  /// No description provided for @userSpaceBangumiAiringDate.
  ///
  /// In zh_CN, this message translates to:
  /// **'开播 {date}'**
  String userSpaceBangumiAiringDate(String date);

  /// No description provided for @browserApp.
  ///
  /// In zh_CN, this message translates to:
  /// **'应用'**
  String get browserApp;

  /// No description provided for @browserOpenAppAttempt.
  ///
  /// In zh_CN, this message translates to:
  /// **'网页尝试打开: {app}'**
  String browserOpenAppAttempt(String app);

  /// No description provided for @browserNoAppForLink.
  ///
  /// In zh_CN, this message translates to:
  /// **'未找到可打开该链接的应用'**
  String get browserNoAppForLink;

  /// No description provided for @browserOpenFailedSystem.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开失败: 未安装对应应用或受系统限制'**
  String get browserOpenFailedSystem;

  /// No description provided for @browserEmptyCookieHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'这里空空的'**
  String get browserEmptyCookieHint;

  /// No description provided for @browserCopyAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制全部'**
  String get browserCopyAll;

  /// No description provided for @browserCookieCopied.
  ///
  /// In zh_CN, this message translates to:
  /// **'Cookie已复制'**
  String get browserCookieCopied;

  /// No description provided for @browserCookieEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'Cookie空空的'**
  String get browserCookieEmpty;

  /// No description provided for @browserSetUaTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置 User-Agent'**
  String get browserSetUaTitle;

  /// No description provided for @browserUaHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入自定义 User-Agent'**
  String get browserUaHint;

  /// No description provided for @browserApplyAndReload.
  ///
  /// In zh_CN, this message translates to:
  /// **'应用并刷新'**
  String get browserApplyAndReload;

  /// No description provided for @browserUaUpdated.
  ///
  /// In zh_CN, this message translates to:
  /// **'UA 已更新并刷新页面'**
  String get browserUaUpdated;

  /// No description provided for @browserUaSetFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置 UA 失败: {error}'**
  String browserUaSetFailed(String error);

  /// No description provided for @browserWindowsInitFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'Windows WebView 初始化失败，请检查 WebView2 是否已安装'**
  String get browserWindowsInitFailed;

  /// No description provided for @browserBiliCookieReadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'未能读取到完整登录 Cookie（SESSDATA 为 HttpOnly，当前平台无法自动读取），请改用扫码登录或粘贴 Cookie'**
  String get browserBiliCookieReadFailed;

  /// No description provided for @browserCookieImportFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'Cookie 导入失败，请重试'**
  String get browserCookieImportFailed;

  /// No description provided for @browserStoppedLoading.
  ///
  /// In zh_CN, this message translates to:
  /// **'已停止加载'**
  String get browserStoppedLoading;

  /// No description provided for @browserClipboardAllowed.
  ///
  /// In zh_CN, this message translates to:
  /// **'已允许网页写入剪贴板'**
  String get browserClipboardAllowed;

  /// No description provided for @browserClipboardBlocked.
  ///
  /// In zh_CN, this message translates to:
  /// **'已禁止网页自动写入剪贴板'**
  String get browserClipboardBlocked;

  /// No description provided for @browserNoCurrentUrl.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法获取当前链接'**
  String get browserNoCurrentUrl;

  /// No description provided for @browserTroubleshootFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开失败,请检查\"获取帮助\"是否存在'**
  String get browserTroubleshootFailed;

  /// No description provided for @browserSystemBrowserMissing.
  ///
  /// In zh_CN, this message translates to:
  /// **'系统浏览器不见了('**
  String get browserSystemBrowserMissing;

  /// No description provided for @browserQrTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫我'**
  String get browserQrTitle;

  /// No description provided for @browserSaveToDevice.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存到设备'**
  String get browserSaveToDevice;

  /// No description provided for @browserQrSaved.
  ///
  /// In zh_CN, this message translates to:
  /// **'二维码已保存到相册/图片库'**
  String get browserQrSaved;

  /// No description provided for @browserSaveFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存失败: {error}'**
  String browserSaveFailed(String error);

  /// No description provided for @browserStopLoading.
  ///
  /// In zh_CN, this message translates to:
  /// **'停止加载'**
  String get browserStopLoading;

  /// No description provided for @browserImporting.
  ///
  /// In zh_CN, this message translates to:
  /// **'导入中…'**
  String get browserImporting;

  /// No description provided for @browserLoginDoneImport.
  ///
  /// In zh_CN, this message translates to:
  /// **'登录完成，导入'**
  String get browserLoginDoneImport;

  /// No description provided for @browserClipboardAccess.
  ///
  /// In zh_CN, this message translates to:
  /// **'剪贴板访问'**
  String get browserClipboardAccess;

  /// No description provided for @browserShareQr.
  ///
  /// In zh_CN, this message translates to:
  /// **'分享二维码'**
  String get browserShareQr;

  /// No description provided for @browserCopyLink.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制链接'**
  String get browserCopyLink;

  /// No description provided for @browserViewCookies.
  ///
  /// In zh_CN, this message translates to:
  /// **'查看 Cookies'**
  String get browserViewCookies;

  /// No description provided for @browserSetUa.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置 UA'**
  String get browserSetUa;

  /// No description provided for @browserUaModeAuto.
  ///
  /// In zh_CN, this message translates to:
  /// **'自动（跟随系统）'**
  String get browserUaModeAuto;

  /// No description provided for @browserUaModeDesktop.
  ///
  /// In zh_CN, this message translates to:
  /// **'电脑端'**
  String get browserUaModeDesktop;

  /// No description provided for @browserUaModeMobile.
  ///
  /// In zh_CN, this message translates to:
  /// **'手机端'**
  String get browserUaModeMobile;

  /// No description provided for @browserRefresh.
  ///
  /// In zh_CN, this message translates to:
  /// **'刷新'**
  String get browserRefresh;

  /// No description provided for @browserSystemBrowser.
  ///
  /// In zh_CN, this message translates to:
  /// **'系统浏览器'**
  String get browserSystemBrowser;

  /// No description provided for @browserTroubleshootNetwork.
  ///
  /// In zh_CN, this message translates to:
  /// **'检测连接问题'**
  String get browserTroubleshootNetwork;

  /// No description provided for @browserUnsupportedPlatform.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前平台不支持内嵌浏览器'**
  String get browserUnsupportedPlatform;

  /// No description provided for @browserOpenedInSystem.
  ///
  /// In zh_CN, this message translates to:
  /// **'已尝试在系统浏览器中打开'**
  String get browserOpenedInSystem;

  /// No description provided for @browserReopenInSystem.
  ///
  /// In zh_CN, this message translates to:
  /// **'重新用系统浏览器打开'**
  String get browserReopenInSystem;

  /// No description provided for @browserAndroidErrorTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'沒有指令'**
  String get browserAndroidErrorTitle;

  /// No description provided for @browserAndroidErrorCause.
  ///
  /// In zh_CN, this message translates to:
  /// **'原因'**
  String get browserAndroidErrorCause;

  /// No description provided for @browserAndroidErrorDetail.
  ///
  /// In zh_CN, this message translates to:
  /// **'WebView 组件初始化失败\n可能是系统 WebView 未更新或已停用'**
  String get browserAndroidErrorDetail;

  /// No description provided for @browserUpdateWebview.
  ///
  /// In zh_CN, this message translates to:
  /// **'前往 Google Play 更新 Android System WebView'**
  String get browserUpdateWebview;

  /// No description provided for @browserOpenDevOptions.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开开发者选项查看 WebView 实现'**
  String get browserOpenDevOptions;

  /// No description provided for @browserAppleErrorTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'應用程式未預期的結束'**
  String get browserAppleErrorTitle;

  /// No description provided for @browserAppleErrorReport.
  ///
  /// In zh_CN, this message translates to:
  /// **'問題報告'**
  String get browserAppleErrorReport;

  /// No description provided for @browserAppleErrorDetail.
  ///
  /// In zh_CN, this message translates to:
  /// **'無法在此裝置上初始化內嵌瀏覽器。請確認作業系統已更新至最新版本。'**
  String get browserAppleErrorDetail;

  /// No description provided for @browserBsodMessage.
  ///
  /// In zh_CN, this message translates to:
  /// **'你的 Webview2 遇到问题，我们需要收集一些错误信息，然后为你重启应用。'**
  String get browserBsodMessage;

  /// No description provided for @browserBsodNoRestart.
  ///
  /// In zh_CN, this message translates to:
  /// **'(其实不用重启，安装完组件即可)'**
  String get browserBsodNoRestart;

  /// No description provided for @browserBsodComplete.
  ///
  /// In zh_CN, this message translates to:
  /// **'100% 完成'**
  String get browserBsodComplete;

  /// No description provided for @browserBsodSolutions.
  ///
  /// In zh_CN, this message translates to:
  /// **'查看解决方案：'**
  String get browserBsodSolutions;

  /// No description provided for @browserBsodDownload.
  ///
  /// In zh_CN, this message translates to:
  /// **'下载 Webview2 运行时'**
  String get browserBsodDownload;

  /// No description provided for @browserBsodWinUpdate.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开 Windows 更新设置'**
  String get browserBsodWinUpdate;

  /// No description provided for @browserBsodScanQr.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描此 QR 码获取解决方案'**
  String get browserBsodScanQr;

  /// No description provided for @browserBsodStopCode.
  ///
  /// In zh_CN, this message translates to:
  /// **'终止代码：WEBVIEW2_RUNTIME_MISSING'**
  String get browserBsodStopCode;

  /// No description provided for @browserCantOpenExternal.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法打开外部链接'**
  String get browserCantOpenExternal;

  /// No description provided for @callOutgoing.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在呼叫...'**
  String get callOutgoing;

  /// No description provided for @callIncoming.
  ///
  /// In zh_CN, this message translates to:
  /// **'来电...'**
  String get callIncoming;

  /// No description provided for @callConnecting.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接中...'**
  String get callConnecting;

  /// No description provided for @chatConnectionNotEstablishedImage.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接未建立，无法发送图片'**
  String get chatConnectionNotEstablishedImage;

  /// No description provided for @chatImageSent.
  ///
  /// In zh_CN, this message translates to:
  /// **'✅ 图片已发送'**
  String get chatImageSent;

  /// No description provided for @chatImageSendFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送图片失败'**
  String get chatImageSendFailed;

  /// No description provided for @chatClipboardImageProcessFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'处理剪贴板图片失败：{error}'**
  String chatClipboardImageProcessFailed(String error);

  /// No description provided for @chatImageStaged.
  ///
  /// In zh_CN, this message translates to:
  /// **'🖼️ 图片已添加至输入框'**
  String get chatImageStaged;

  /// No description provided for @chatClipboardNoImage.
  ///
  /// In zh_CN, this message translates to:
  /// **'剪贴板无图片数据'**
  String get chatClipboardNoImage;

  /// No description provided for @chatClipboardImageFetchFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'获取剪贴板图片失败：{error}'**
  String chatClipboardImageFetchFailed(String error);

  /// No description provided for @chatClipboardEmptyOrUnsupported.
  ///
  /// In zh_CN, this message translates to:
  /// **'剪贴板为空或格式不支持'**
  String get chatClipboardEmptyOrUnsupported;

  /// No description provided for @chatConnectionNotEstablishedFile.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接未建立，无法发送文件'**
  String get chatConnectionNotEstablishedFile;

  /// No description provided for @chatFileNotExist.
  ///
  /// In zh_CN, this message translates to:
  /// **'文件不存在'**
  String get chatFileNotExist;

  /// No description provided for @chatFileSendFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送文件失败'**
  String get chatFileSendFailed;

  /// No description provided for @chatFileSentSuccess.
  ///
  /// In zh_CN, this message translates to:
  /// **'✅ {fileName} 发送成功'**
  String chatFileSentSuccess(String fileName);

  /// No description provided for @chatFileSendError.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送文件失败：{error}'**
  String chatFileSendError(String error);

  /// No description provided for @chatIpUnknown.
  ///
  /// In zh_CN, this message translates to:
  /// **'IP 未知'**
  String get chatIpUnknown;

  /// No description provided for @chatReconnecting.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在重新建立连接...'**
  String get chatReconnecting;

  /// No description provided for @chatReconnectFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'重连失败，请检查网络或对方是否在线'**
  String get chatReconnectFailed;

  /// No description provided for @chatStatusUnknown.
  ///
  /// In zh_CN, this message translates to:
  /// **'状态未知'**
  String get chatStatusUnknown;

  /// No description provided for @chatStatusWaiting.
  ///
  /// In zh_CN, this message translates to:
  /// **'等待连接'**
  String get chatStatusWaiting;

  /// No description provided for @chatMe.
  ///
  /// In zh_CN, this message translates to:
  /// **'我'**
  String get chatMe;

  /// No description provided for @chatFileInfoLost.
  ///
  /// In zh_CN, this message translates to:
  /// **'(文件信息丢失)'**
  String get chatFileInfoLost;

  /// No description provided for @chatOpenFileFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法打开文件：{message}'**
  String chatOpenFileFailed(String message);

  /// No description provided for @chatFileNotDownloaded.
  ///
  /// In zh_CN, this message translates to:
  /// **'文件尚未下载'**
  String get chatFileNotDownloaded;

  /// No description provided for @chatOpenFileError.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开文件失败：{error}'**
  String chatOpenFileError(String error);

  /// No description provided for @chatFilePathUnavailable.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法获取文件路径 (安卓权限限制?)'**
  String get chatFilePathUnavailable;

  /// No description provided for @chatPickFileFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择文件失败：{error}'**
  String chatPickFileFailed(String error);

  /// No description provided for @chatImagePathUnavailable.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法获取图片路径'**
  String get chatImagePathUnavailable;

  /// No description provided for @chatPickImageFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择图片失败：{error}'**
  String chatPickImageFailed(String error);

  /// No description provided for @chatCopyText.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制文本'**
  String get chatCopyText;

  /// No description provided for @chatSelectText.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择文本'**
  String get chatSelectText;

  /// No description provided for @chatOpenFile.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开文件'**
  String get chatOpenFile;

  /// No description provided for @chatCopyImage.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制图片'**
  String get chatCopyImage;

  /// No description provided for @chatSaveImage.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存图片'**
  String get chatSaveImage;

  /// No description provided for @chatCopyingImage.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在复制图片...'**
  String get chatCopyingImage;

  /// No description provided for @chatImageCopied.
  ///
  /// In zh_CN, this message translates to:
  /// **'✅ 图片已复制到剪贴板'**
  String get chatImageCopied;

  /// No description provided for @chatCopyFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制失败'**
  String get chatCopyFailed;

  /// No description provided for @chatCopyImageFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制图片失败: {error}'**
  String chatCopyImageFailed(String error);

  /// No description provided for @chatSaving.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在保存...'**
  String get chatSaving;

  /// No description provided for @chatSaveSuccess.
  ///
  /// In zh_CN, this message translates to:
  /// **'✅ 保存成功'**
  String get chatSaveSuccess;

  /// No description provided for @chatSaveFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存失败: {error}'**
  String chatSaveFailed(String error);

  /// No description provided for @chatMessageContent.
  ///
  /// In zh_CN, this message translates to:
  /// **'消息内容'**
  String get chatMessageContent;

  /// No description provided for @chatEmptyContent.
  ///
  /// In zh_CN, this message translates to:
  /// **'(这里空空的)'**
  String get chatEmptyContent;

  /// No description provided for @chatDeleteMessageConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'主人确定要删除这条消息吗？'**
  String get chatDeleteMessageConfirm;

  /// No description provided for @chatMessageDeleted.
  ///
  /// In zh_CN, this message translates to:
  /// **'消息已删除'**
  String get chatMessageDeleted;

  /// No description provided for @chatOpenLinkTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开链接'**
  String get chatOpenLinkTitle;

  /// No description provided for @chatWillOpen.
  ///
  /// In zh_CN, this message translates to:
  /// **'将打开：{url}'**
  String chatWillOpen(String url);

  /// No description provided for @chatBrowserTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'内置网页浏览器'**
  String get chatBrowserTitle;

  /// No description provided for @chatCantOpenLink.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法打开链接'**
  String get chatCantOpenLink;

  /// No description provided for @chatOpenLinkFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开链接失败：{error}'**
  String chatOpenLinkFailed(String error);

  /// No description provided for @chatPlusImage.
  ///
  /// In zh_CN, this message translates to:
  /// **'图片'**
  String get chatPlusImage;

  /// No description provided for @chatPlusFile.
  ///
  /// In zh_CN, this message translates to:
  /// **'文件'**
  String get chatPlusFile;

  /// No description provided for @chatImageReady.
  ///
  /// In zh_CN, this message translates to:
  /// **'图片已就绪'**
  String get chatImageReady;

  /// No description provided for @chatMore.
  ///
  /// In zh_CN, this message translates to:
  /// **'更多'**
  String get chatMore;

  /// No description provided for @chatPasteImage.
  ///
  /// In zh_CN, this message translates to:
  /// **'粘贴图片'**
  String get chatPasteImage;

  /// No description provided for @chatInputHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入消息...'**
  String get chatInputHint;

  /// No description provided for @chatEmoji.
  ///
  /// In zh_CN, this message translates to:
  /// **'表情符号'**
  String get chatEmoji;

  /// No description provided for @chatSend.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送'**
  String get chatSend;

  /// No description provided for @chatInvalidAddress.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接地址无效，无法发送'**
  String get chatInvalidAddress;

  /// No description provided for @chatImageSendError.
  ///
  /// In zh_CN, this message translates to:
  /// **'图片发送失败'**
  String get chatImageSendError;

  /// No description provided for @chatSendFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送失败：{error}'**
  String chatSendFailed(String error);

  /// No description provided for @chatConnStatusUnknown.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接状态未知，无法发送消息'**
  String get chatConnStatusUnknown;

  /// No description provided for @chatPendingCannotSend.
  ///
  /// In zh_CN, this message translates to:
  /// **'等待对方验证，无法发送消息'**
  String get chatPendingCannotSend;

  /// No description provided for @chatConnRejected.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接已被拒绝'**
  String get chatConnRejected;

  /// No description provided for @chatConnDisconnected.
  ///
  /// In zh_CN, this message translates to:
  /// **'对方已断开连接'**
  String get chatConnDisconnected;

  /// No description provided for @chatConnNotEstablished.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接尚未建立，无法发送消息'**
  String get chatConnNotEstablished;

  /// No description provided for @chatNoMessages.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无消息，开始聊天吧'**
  String get chatNoMessages;

  /// No description provided for @chatDisconnectedRetry.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接已断开，点击尝试重连'**
  String get chatDisconnectedRetry;

  /// No description provided for @chatRejectedRetry.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接被拒绝，点击重试'**
  String get chatRejectedRetry;

  /// No description provided for @chatExpandInput.
  ///
  /// In zh_CN, this message translates to:
  /// **'展开输入栏'**
  String get chatExpandInput;

  /// No description provided for @discoverMyLanIps.
  ///
  /// In zh_CN, this message translates to:
  /// **'我的局域网 IP'**
  String get discoverMyLanIps;

  /// No description provided for @discoverNoIpOfType.
  ///
  /// In zh_CN, this message translates to:
  /// **'未找到该类型的有效 IP，请检查网络连接。'**
  String get discoverNoIpOfType;

  /// No description provided for @discoverIpCopied.
  ///
  /// In zh_CN, this message translates to:
  /// **'已复制 {ip}'**
  String discoverIpCopied(String ip);

  /// No description provided for @discoverTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'发现附近设备'**
  String get discoverTitle;

  /// No description provided for @discoverMyIp.
  ///
  /// In zh_CN, this message translates to:
  /// **'我的 IP'**
  String get discoverMyIp;

  /// No description provided for @discoverRefreshBroadcast.
  ///
  /// In zh_CN, this message translates to:
  /// **'刷新/广播'**
  String get discoverRefreshBroadcast;

  /// No description provided for @discoverLanDevices.
  ///
  /// In zh_CN, this message translates to:
  /// **'局域网设备'**
  String get discoverLanDevices;

  /// No description provided for @discoverSearching.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在寻找附近的设备...'**
  String get discoverSearching;

  /// No description provided for @discoverSendRequest.
  ///
  /// In zh_CN, this message translates to:
  /// **'点击发送连接请求'**
  String get discoverSendRequest;

  /// No description provided for @discoverPendingVerify.
  ///
  /// In zh_CN, this message translates to:
  /// **'等待对方验证...'**
  String get discoverPendingVerify;

  /// No description provided for @discoverRejectedRetry.
  ///
  /// In zh_CN, this message translates to:
  /// **'已被拒绝，点击重试'**
  String get discoverRejectedRetry;

  /// No description provided for @discoverDisconnectedRetry.
  ///
  /// In zh_CN, this message translates to:
  /// **'已断开，点击重连'**
  String get discoverDisconnectedRetry;

  /// No description provided for @discoverUnknownDevice.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知设备'**
  String get discoverUnknownDevice;

  /// No description provided for @discoverAlreadyConnected.
  ///
  /// In zh_CN, this message translates to:
  /// **'该设备已连接'**
  String get discoverAlreadyConnected;

  /// No description provided for @discoverAlreadyPending.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在等待对方验证，请勿重复发送'**
  String get discoverAlreadyPending;

  /// No description provided for @discoverConnectFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接失败，请检查网络或对方是否在线'**
  String get discoverConnectFailed;

  /// No description provided for @discoverManualConnect.
  ///
  /// In zh_CN, this message translates to:
  /// **'手动连接到对等端'**
  String get discoverManualConnect;

  /// No description provided for @discoverConnectIpHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入 IP 地址（例如：192.168.1.100 / fe80::1）'**
  String get discoverConnectIpHint;

  /// No description provided for @displayScaleCompact.
  ///
  /// In zh_CN, this message translates to:
  /// **'紧凑模式 · 显示更多内容'**
  String get displayScaleCompact;

  /// No description provided for @displayScaleSmall.
  ///
  /// In zh_CN, this message translates to:
  /// **'略小 · 适合大屏'**
  String get displayScaleSmall;

  /// No description provided for @displayScaleDefault.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认'**
  String get displayScaleDefault;

  /// No description provided for @displayScaleLarge.
  ///
  /// In zh_CN, this message translates to:
  /// **'略大 · 更易阅读'**
  String get displayScaleLarge;

  /// No description provided for @displayScaleLargeFont.
  ///
  /// In zh_CN, this message translates to:
  /// **'大字体 · 无障碍友好'**
  String get displayScaleLargeFont;

  /// No description provided for @displayScaleHuge.
  ///
  /// In zh_CN, this message translates to:
  /// **'超大 · 辅助功能'**
  String get displayScaleHuge;

  /// No description provided for @displayScaleMin.
  ///
  /// In zh_CN, this message translates to:
  /// **'最小 · 信息密度最高'**
  String get displayScaleMin;

  /// No description provided for @displayScaleCompactBig.
  ///
  /// In zh_CN, this message translates to:
  /// **'紧凑 · 适合大屏'**
  String get displayScaleCompactBig;

  /// No description provided for @displayScaleSystemDefault.
  ///
  /// In zh_CN, this message translates to:
  /// **'系统默认'**
  String get displayScaleSystemDefault;

  /// No description provided for @displayScaleLargeFontShort.
  ///
  /// In zh_CN, this message translates to:
  /// **'大字体 · 无障碍'**
  String get displayScaleLargeFontShort;

  /// No description provided for @displayScaleTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示缩放'**
  String get displayScaleTitle;

  /// No description provided for @displayHeroTransitionBlur.
  ///
  /// In zh_CN, this message translates to:
  /// **'使用新版动画'**
  String get displayHeroTransitionBlur;

  /// No description provided for @displayIosPushTransition.
  ///
  /// In zh_CN, this message translates to:
  /// **'iOS 风格页面切换'**
  String get displayIosPushTransition;

  /// No description provided for @displayIosPushTransitionCorner.
  ///
  /// In zh_CN, this message translates to:
  /// **'转场圆角'**
  String get displayIosPushTransitionCorner;

  /// No description provided for @searchIosPushTransition.
  ///
  /// In zh_CN, this message translates to:
  /// **'iOS 页面切换动画'**
  String get searchIosPushTransition;

  /// No description provided for @pageBgTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'页面背景图'**
  String get pageBgTitle;

  /// No description provided for @pageBgSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置类页面共用的背景图，选择后可裁剪'**
  String get pageBgSubtitle;

  /// No description provided for @pageBgEnabled.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示页面背景图'**
  String get pageBgEnabled;

  /// No description provided for @pageBgOpacity.
  ///
  /// In zh_CN, this message translates to:
  /// **'背景强度'**
  String get pageBgOpacity;

  /// No description provided for @pageBgBlur.
  ///
  /// In zh_CN, this message translates to:
  /// **'背景模糊'**
  String get pageBgBlur;

  /// No description provided for @pageBgNotSet.
  ///
  /// In zh_CN, this message translates to:
  /// **'未设置'**
  String get pageBgNotSet;

  /// No description provided for @pageBgPick.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择并裁剪图片'**
  String get pageBgPick;

  /// No description provided for @pageBgClear.
  ///
  /// In zh_CN, this message translates to:
  /// **'清除背景图'**
  String get pageBgClear;

  /// No description provided for @pageBgSaved.
  ///
  /// In zh_CN, this message translates to:
  /// **'背景图已更新'**
  String get pageBgSaved;

  /// No description provided for @pageBgCleared.
  ///
  /// In zh_CN, this message translates to:
  /// **'背景图已清除'**
  String get pageBgCleared;

  /// No description provided for @pageBgPickFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择图片失败'**
  String get pageBgPickFailed;

  /// No description provided for @cropTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'裁剪背景图'**
  String get cropTitle;

  /// No description provided for @cropAspectFree.
  ///
  /// In zh_CN, this message translates to:
  /// **'自由'**
  String get cropAspectFree;

  /// No description provided for @cropApply.
  ///
  /// In zh_CN, this message translates to:
  /// **'应用'**
  String get cropApply;

  /// No description provided for @cropReset.
  ///
  /// In zh_CN, this message translates to:
  /// **'重置'**
  String get cropReset;

  /// No description provided for @displayAdvancedGlass.
  ///
  /// In zh_CN, this message translates to:
  /// **'高级渲染'**
  String get displayAdvancedGlass;

  /// No description provided for @displayDisableLiquidGlassMenus.
  ///
  /// In zh_CN, this message translates to:
  /// **'减弱效果'**
  String get displayDisableLiquidGlassMenus;

  /// No description provided for @displayLiquidGlassTuner.
  ///
  /// In zh_CN, this message translates to:
  /// **'液态玻璃调校'**
  String get displayLiquidGlassTuner;

  /// No description provided for @displayLiquidGlassTunerSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'调节玻璃厚度、模糊、着色、折射率等材质参数'**
  String get displayLiquidGlassTunerSubtitle;

  /// No description provided for @lgTunerPreview.
  ///
  /// In zh_CN, this message translates to:
  /// **'实时预览'**
  String get lgTunerPreview;

  /// No description provided for @lgTunerSectionMaterial.
  ///
  /// In zh_CN, this message translates to:
  /// **'材质参数'**
  String get lgTunerSectionMaterial;

  /// No description provided for @lgTunerThickness.
  ///
  /// In zh_CN, this message translates to:
  /// **'玻璃厚度'**
  String get lgTunerThickness;

  /// No description provided for @lgTunerBlur.
  ///
  /// In zh_CN, this message translates to:
  /// **'背景模糊'**
  String get lgTunerBlur;

  /// No description provided for @lgTunerTint.
  ///
  /// In zh_CN, this message translates to:
  /// **'着色强度'**
  String get lgTunerTint;

  /// No description provided for @lgTunerSaturation.
  ///
  /// In zh_CN, this message translates to:
  /// **'饱和度'**
  String get lgTunerSaturation;

  /// No description provided for @lgTunerRefractiveIndex.
  ///
  /// In zh_CN, this message translates to:
  /// **'折射率'**
  String get lgTunerRefractiveIndex;

  /// No description provided for @lgTunerLightIntensity.
  ///
  /// In zh_CN, this message translates to:
  /// **'高光强度'**
  String get lgTunerLightIntensity;

  /// No description provided for @lgTunerAmbient.
  ///
  /// In zh_CN, this message translates to:
  /// **'环境光'**
  String get lgTunerAmbient;

  /// No description provided for @lgTunerLightAngle.
  ///
  /// In zh_CN, this message translates to:
  /// **'光源角度'**
  String get lgTunerLightAngle;

  /// No description provided for @lgTunerAberration.
  ///
  /// In zh_CN, this message translates to:
  /// **'色散'**
  String get lgTunerAberration;

  /// No description provided for @lgTunerReset.
  ///
  /// In zh_CN, this message translates to:
  /// **'恢复默认'**
  String get lgTunerReset;

  /// No description provided for @lgTunerNote.
  ///
  /// In zh_CN, this message translates to:
  /// **'调整即时生效并全局应用：未单独指定参数的玻璃表面（下拉菜单、弹窗等）都会跟随；聊天页顶栏等显式设定的表面保持独立样式。'**
  String get lgTunerNote;

  /// No description provided for @lgTunerFallbackNote.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前平台不支持高级玻璃渲染（Impeller），预览为 FakeGlass 效果；厚度、折射率、饱和度等参数仅移动端生效。'**
  String get lgTunerFallbackNote;

  /// No description provided for @displayScaleReset.
  ///
  /// In zh_CN, this message translates to:
  /// **'重置为 100%'**
  String get displayScaleReset;

  /// No description provided for @displayScaleFineTune.
  ///
  /// In zh_CN, this message translates to:
  /// **'精细调节'**
  String get displayScaleFineTune;

  /// No description provided for @displayScalePresets.
  ///
  /// In zh_CN, this message translates to:
  /// **'快捷预设'**
  String get displayScalePresets;

  /// No description provided for @displayScaleNote.
  ///
  /// In zh_CN, this message translates to:
  /// **'缩放比例会全局应用于文字与部分布局尺寸。设为 100% 可恢复默认。修改即时生效，无需重启。'**
  String get displayScaleNote;

  /// No description provided for @displayScaleConnCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 个连接'**
  String displayScaleConnCount(int count);

  /// No description provided for @displayThemeLight.
  ///
  /// In zh_CN, this message translates to:
  /// **'浅色'**
  String get displayThemeLight;

  /// No description provided for @displayThemeDark.
  ///
  /// In zh_CN, this message translates to:
  /// **'深色'**
  String get displayThemeDark;

  /// No description provided for @displaySettingsTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示'**
  String get displaySettingsTitle;

  /// No description provided for @displaySectionAppearance.
  ///
  /// In zh_CN, this message translates to:
  /// **'外观'**
  String get displaySectionAppearance;

  /// No description provided for @displayThemeMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题模式'**
  String get displayThemeMode;

  /// No description provided for @displayPureBlack.
  ///
  /// In zh_CN, this message translates to:
  /// **'纯黑深色模式'**
  String get displayPureBlack;

  /// No description provided for @displayPureBlackOn.
  ///
  /// In zh_CN, this message translates to:
  /// **'深色模式（已黑化）'**
  String get displayPureBlackOn;

  /// No description provided for @displayOff.
  ///
  /// In zh_CN, this message translates to:
  /// **'已关闭'**
  String get displayOff;

  /// No description provided for @displaySectionPersonalize.
  ///
  /// In zh_CN, this message translates to:
  /// **'个性化'**
  String get displaySectionPersonalize;

  /// No description provided for @displayThemeColor.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题配色'**
  String get displayThemeColor;

  /// No description provided for @displayFollowSystemColor.
  ///
  /// In zh_CN, this message translates to:
  /// **'跟随系统配色'**
  String get displayFollowSystemColor;

  /// No description provided for @displayFontWeight.
  ///
  /// In zh_CN, this message translates to:
  /// **'文字粗细'**
  String get displayFontWeight;

  /// No description provided for @displaySeedDefaultGreen.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认绿'**
  String get displaySeedDefaultGreen;

  /// No description provided for @displaySeedPink.
  ///
  /// In zh_CN, this message translates to:
  /// **'粉红色'**
  String get displaySeedPink;

  /// No description provided for @displaySeedRed.
  ///
  /// In zh_CN, this message translates to:
  /// **'红色'**
  String get displaySeedRed;

  /// No description provided for @displaySeedOrange.
  ///
  /// In zh_CN, this message translates to:
  /// **'橙色'**
  String get displaySeedOrange;

  /// No description provided for @displaySeedAmber.
  ///
  /// In zh_CN, this message translates to:
  /// **'琥珀色'**
  String get displaySeedAmber;

  /// No description provided for @displaySeedYellow.
  ///
  /// In zh_CN, this message translates to:
  /// **'黄色'**
  String get displaySeedYellow;

  /// No description provided for @displaySeedLime.
  ///
  /// In zh_CN, this message translates to:
  /// **'酸橙色'**
  String get displaySeedLime;

  /// No description provided for @displaySeedLightGreen.
  ///
  /// In zh_CN, this message translates to:
  /// **'浅绿色'**
  String get displaySeedLightGreen;

  /// No description provided for @displaySeedGreen.
  ///
  /// In zh_CN, this message translates to:
  /// **'绿色'**
  String get displaySeedGreen;

  /// No description provided for @displaySeedCyan.
  ///
  /// In zh_CN, this message translates to:
  /// **'青色'**
  String get displaySeedCyan;

  /// No description provided for @displaySeedTeal.
  ///
  /// In zh_CN, this message translates to:
  /// **'蓝绿色'**
  String get displaySeedTeal;

  /// No description provided for @displaySeedLightBlue.
  ///
  /// In zh_CN, this message translates to:
  /// **'浅蓝色'**
  String get displaySeedLightBlue;

  /// No description provided for @displaySeedBlue.
  ///
  /// In zh_CN, this message translates to:
  /// **'蓝色'**
  String get displaySeedBlue;

  /// No description provided for @displaySeedIndigo.
  ///
  /// In zh_CN, this message translates to:
  /// **'靛蓝色'**
  String get displaySeedIndigo;

  /// No description provided for @displaySeedPurple.
  ///
  /// In zh_CN, this message translates to:
  /// **'紫色'**
  String get displaySeedPurple;

  /// No description provided for @displaySeedDeepPurple.
  ///
  /// In zh_CN, this message translates to:
  /// **'深紫色'**
  String get displaySeedDeepPurple;

  /// No description provided for @displaySeedBlueGrey.
  ///
  /// In zh_CN, this message translates to:
  /// **'蓝灰色'**
  String get displaySeedBlueGrey;

  /// No description provided for @displaySeedBrown.
  ///
  /// In zh_CN, this message translates to:
  /// **'棕色'**
  String get displaySeedBrown;

  /// No description provided for @displaySeedGrey.
  ///
  /// In zh_CN, this message translates to:
  /// **'灰色'**
  String get displaySeedGrey;

  /// No description provided for @displaySeedCustom.
  ///
  /// In zh_CN, this message translates to:
  /// **'自定义'**
  String get displaySeedCustom;

  /// No description provided for @displayWeightThin.
  ///
  /// In zh_CN, this message translates to:
  /// **'极细 ({weight})'**
  String displayWeightThin(int weight);

  /// No description provided for @displayWeightLight.
  ///
  /// In zh_CN, this message translates to:
  /// **'细 ({weight})'**
  String displayWeightLight(int weight);

  /// No description provided for @displayWeightRegular.
  ///
  /// In zh_CN, this message translates to:
  /// **'常规 ({weight})'**
  String displayWeightRegular(int weight);

  /// No description provided for @displayWeightMedium.
  ///
  /// In zh_CN, this message translates to:
  /// **'中等 ({weight})'**
  String displayWeightMedium(int weight);

  /// No description provided for @displayWeightBold.
  ///
  /// In zh_CN, this message translates to:
  /// **'粗 ({weight})'**
  String displayWeightBold(int weight);

  /// No description provided for @displayWeightBlack.
  ///
  /// In zh_CN, this message translates to:
  /// **'极粗 ({weight})'**
  String displayWeightBlack(int weight);

  /// No description provided for @displayWeightCustom.
  ///
  /// In zh_CN, this message translates to:
  /// **'自定义 ({weight})'**
  String displayWeightCustom(int weight);

  /// No description provided for @fontWeightThin.
  ///
  /// In zh_CN, this message translates to:
  /// **'极细'**
  String get fontWeightThin;

  /// No description provided for @fontWeightLight.
  ///
  /// In zh_CN, this message translates to:
  /// **'细'**
  String get fontWeightLight;

  /// No description provided for @fontWeightRegular.
  ///
  /// In zh_CN, this message translates to:
  /// **'常规'**
  String get fontWeightRegular;

  /// No description provided for @fontWeightMedium.
  ///
  /// In zh_CN, this message translates to:
  /// **'中等'**
  String get fontWeightMedium;

  /// No description provided for @fontWeightBold.
  ///
  /// In zh_CN, this message translates to:
  /// **'粗'**
  String get fontWeightBold;

  /// No description provided for @fontWeightBlack.
  ///
  /// In zh_CN, this message translates to:
  /// **'极粗'**
  String get fontWeightBlack;

  /// No description provided for @fontWeightSampleText.
  ///
  /// In zh_CN, this message translates to:
  /// **'The quick brown fox jumps over the lazy dog.\n敏捷的棕色狐狸跳过懒惰的狗。'**
  String get fontWeightSampleText;

  /// No description provided for @fontWeightSaveApply.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存并应用'**
  String get fontWeightSaveApply;

  /// No description provided for @geetestTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'完成滑块验证'**
  String get geetestTitle;

  /// No description provided for @geetestInitFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'验证码组件初始化失败，请重试或改用其他登录方式'**
  String get geetestInitFailed;

  /// No description provided for @geetestUnsupported.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前平台不支持内嵌验证码，请使用扫码或 Cookie 登录'**
  String get geetestUnsupported;

  /// No description provided for @slicerPickImageFirst.
  ///
  /// In zh_CN, this message translates to:
  /// **'请先选择图片'**
  String get slicerPickImageFirst;

  /// No description provided for @slicerRowColInvalid.
  ///
  /// In zh_CN, this message translates to:
  /// **'行列数必须大于0'**
  String get slicerRowColInvalid;

  /// No description provided for @slicerSuccess.
  ///
  /// In zh_CN, this message translates to:
  /// **'切割成功，已添加到开始屏幕'**
  String get slicerSuccess;

  /// No description provided for @slicerSaveFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存失败: {error}'**
  String slicerSaveFailed(String error);

  /// No description provided for @slicerTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'图片切割磁贴'**
  String get slicerTitle;

  /// No description provided for @slicerTileSize.
  ///
  /// In zh_CN, this message translates to:
  /// **'磁贴尺寸 (所有碎片均相同)'**
  String get slicerTileSize;

  /// No description provided for @slicerColsLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'列数 (Cols)'**
  String get slicerColsLabel;

  /// No description provided for @slicerRowsLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'行数 (Rows)'**
  String get slicerRowsLabel;

  /// No description provided for @slicerPreview.
  ///
  /// In zh_CN, this message translates to:
  /// **'预览：将切割为 {count} 个 {type} 磁贴'**
  String slicerPreview(int count, String type);

  /// No description provided for @slicerProcessing.
  ///
  /// In zh_CN, this message translates to:
  /// **'处理中...'**
  String get slicerProcessing;

  /// No description provided for @slicerSaveToStart.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存到开始屏幕'**
  String get slicerSaveToStart;

  /// No description provided for @viewerSaving.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在保存...'**
  String get viewerSaving;

  /// No description provided for @viewerSaveSuccess.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存成功'**
  String get viewerSaveSuccess;

  /// No description provided for @viewerSaveFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存失败: {error}'**
  String viewerSaveFailed(String error);

  /// No description provided for @viewerShareImage.
  ///
  /// In zh_CN, this message translates to:
  /// **'分享图片'**
  String get viewerShareImage;

  /// No description provided for @viewerShareFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'分享失败: {error}'**
  String viewerShareFailed(String error);

  /// No description provided for @viewerCopying.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在复制...'**
  String get viewerCopying;

  /// No description provided for @viewerCopyFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制失败: {error}'**
  String viewerCopyFailed(String error);

  /// No description provided for @viewerSaveToAlbum.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存到相册'**
  String get viewerSaveToAlbum;

  /// No description provided for @viewerCopyToClipboard.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制到剪贴板'**
  String get viewerCopyToClipboard;

  /// No description provided for @viewerImageLoadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'图片加载失败'**
  String get viewerImageLoadFailed;

  /// No description provided for @viewerImageDataNotFound.
  ///
  /// In zh_CN, this message translates to:
  /// **'未找到图片数据'**
  String get viewerImageDataNotFound;

  /// No description provided for @userSpaceMidInvalid.
  ///
  /// In zh_CN, this message translates to:
  /// **'mid 无效'**
  String get userSpaceMidInvalid;

  /// No description provided for @userSpaceNoCard.
  ///
  /// In zh_CN, this message translates to:
  /// **'响应缺少 card'**
  String get userSpaceNoCard;

  /// No description provided for @userSpaceNoList.
  ///
  /// In zh_CN, this message translates to:
  /// **'响应缺少 list'**
  String get userSpaceNoList;

  /// No description provided for @searchTypeVideo.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频'**
  String get searchTypeVideo;

  /// No description provided for @searchTypeBangumi.
  ///
  /// In zh_CN, this message translates to:
  /// **'番剧'**
  String get searchTypeBangumi;

  /// No description provided for @searchTypeFt.
  ///
  /// In zh_CN, this message translates to:
  /// **'影视'**
  String get searchTypeFt;

  /// No description provided for @searchTypeLive.
  ///
  /// In zh_CN, this message translates to:
  /// **'直播间'**
  String get searchTypeLive;

  /// No description provided for @searchTypeUser.
  ///
  /// In zh_CN, this message translates to:
  /// **'用户'**
  String get searchTypeUser;

  /// No description provided for @searchTypeArticle.
  ///
  /// In zh_CN, this message translates to:
  /// **'专栏'**
  String get searchTypeArticle;

  /// No description provided for @tenThousandUnit.
  ///
  /// In zh_CN, this message translates to:
  /// **'万'**
  String get tenThousandUnit;

  /// No description provided for @searchVideoMeta.
  ///
  /// In zh_CN, this message translates to:
  /// **'{play}播放 · {danmaku}弹幕'**
  String searchVideoMeta(String play, String danmaku);

  /// No description provided for @searchScore.
  ///
  /// In zh_CN, this message translates to:
  /// **'评分 {score}'**
  String searchScore(String score);

  /// No description provided for @searchOnline.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count}人在线'**
  String searchOnline(String count);

  /// No description provided for @searchUserMeta.
  ///
  /// In zh_CN, this message translates to:
  /// **'{fans}粉丝 · {videos}视频'**
  String searchUserMeta(String fans, String videos);

  /// No description provided for @searchArticleMeta.
  ///
  /// In zh_CN, this message translates to:
  /// **'{views}阅读 · {replies}评论'**
  String searchArticleMeta(String views, String replies);

  /// No description provided for @searchBadgeCourse.
  ///
  /// In zh_CN, this message translates to:
  /// **'课堂'**
  String get searchBadgeCourse;

  /// No description provided for @searchBadgeLive.
  ///
  /// In zh_CN, this message translates to:
  /// **'直播'**
  String get searchBadgeLive;

  /// No description provided for @searchBadgeCoop.
  ///
  /// In zh_CN, this message translates to:
  /// **'合作'**
  String get searchBadgeCoop;

  /// No description provided for @searchBadgeLiveNow.
  ///
  /// In zh_CN, this message translates to:
  /// **'直播中'**
  String get searchBadgeLiveNow;

  /// No description provided for @searchKeywordEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'关键词为空'**
  String get searchKeywordEmpty;

  /// No description provided for @searchBadResponse.
  ///
  /// In zh_CN, this message translates to:
  /// **'响应格式异常'**
  String get searchBadResponse;

  /// No description provided for @searchFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索失败'**
  String get searchFailed;

  /// No description provided for @searchGaiaParamMissing.
  ///
  /// In zh_CN, this message translates to:
  /// **'gaia register 参数缺失'**
  String get searchGaiaParamMissing;

  /// No description provided for @searchGaiaRegisterError.
  ///
  /// In zh_CN, this message translates to:
  /// **'gaia register 异常: {error}'**
  String searchGaiaRegisterError(String error);

  /// No description provided for @searchGaiaValidateFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'gaia validate 未通过 (is_valid={isValid})'**
  String searchGaiaValidateFailed(int isValid);

  /// No description provided for @searchGaiaValidateError.
  ///
  /// In zh_CN, this message translates to:
  /// **'gaia validate 异常: {error}'**
  String searchGaiaValidateError(String error);

  /// No description provided for @commentOidEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'oid 为空'**
  String get commentOidEmpty;

  /// No description provided for @commentException.
  ///
  /// In zh_CN, this message translates to:
  /// **'异常: {error}'**
  String commentException(String error);

  /// No description provided for @commentSubHttpError.
  ///
  /// In zh_CN, this message translates to:
  /// **'楼中楼 HTTP {code}'**
  String commentSubHttpError(int code);

  /// No description provided for @commentSubNoData.
  ///
  /// In zh_CN, this message translates to:
  /// **'楼中楼响应缺少 data'**
  String get commentSubNoData;

  /// No description provided for @commentSubException.
  ///
  /// In zh_CN, this message translates to:
  /// **'楼中楼异常: {error}'**
  String commentSubException(String error);

  /// No description provided for @commentNotLoggedIn.
  ///
  /// In zh_CN, this message translates to:
  /// **'未登录或未开启「携带 Cookie 请求」'**
  String get commentNotLoggedIn;

  /// No description provided for @commentMissingJct.
  ///
  /// In zh_CN, this message translates to:
  /// **'Cookie 缺少 bili_jct，请重新登录'**
  String get commentMissingJct;

  /// No description provided for @commentNetworkError.
  ///
  /// In zh_CN, this message translates to:
  /// **'网络异常: {error}'**
  String commentNetworkError(String error);

  /// No description provided for @commentApiError.
  ///
  /// In zh_CN, this message translates to:
  /// **'{message}（code={code}）'**
  String commentApiError(String message, int code);

  /// No description provided for @deviceOs.
  ///
  /// In zh_CN, this message translates to:
  /// **'操作系统'**
  String get deviceOs;

  /// No description provided for @deviceBuild.
  ///
  /// In zh_CN, this message translates to:
  /// **'内部构建'**
  String get deviceBuild;

  /// No description provided for @deviceSecurityPatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'安全补丁'**
  String get deviceSecurityPatch;

  /// No description provided for @deviceOem.
  ///
  /// In zh_CN, this message translates to:
  /// **'OEM 厂商'**
  String get deviceOem;

  /// No description provided for @deviceBrand.
  ///
  /// In zh_CN, this message translates to:
  /// **'品牌'**
  String get deviceBrand;

  /// No description provided for @deviceModel.
  ///
  /// In zh_CN, this message translates to:
  /// **'型号'**
  String get deviceModel;

  /// No description provided for @deviceRomVersion.
  ///
  /// In zh_CN, this message translates to:
  /// **'ROM/显示版本'**
  String get deviceRomVersion;

  /// No description provided for @deviceFingerprint.
  ///
  /// In zh_CN, this message translates to:
  /// **'设备指纹'**
  String get deviceFingerprint;

  /// No description provided for @deviceName.
  ///
  /// In zh_CN, this message translates to:
  /// **'设备名称'**
  String get deviceName;

  /// No description provided for @deviceComputerName.
  ///
  /// In zh_CN, this message translates to:
  /// **'计算机名'**
  String get deviceComputerName;

  /// No description provided for @deviceHardwareModel.
  ///
  /// In zh_CN, this message translates to:
  /// **'硬件型号'**
  String get deviceHardwareModel;

  /// No description provided for @deviceKernel.
  ///
  /// In zh_CN, this message translates to:
  /// **'内核版本'**
  String get deviceKernel;

  /// No description provided for @deviceDistro.
  ///
  /// In zh_CN, this message translates to:
  /// **'发行版'**
  String get deviceDistro;

  /// No description provided for @deviceVersion.
  ///
  /// In zh_CN, this message translates to:
  /// **'版本'**
  String get deviceVersion;

  /// No description provided for @devicePlatform.
  ///
  /// In zh_CN, this message translates to:
  /// **'平台'**
  String get devicePlatform;

  /// No description provided for @deviceInfoFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'获取信息失败: {error}'**
  String deviceInfoFailed(String error);

  /// No description provided for @logWebUnsupported.
  ///
  /// In zh_CN, this message translates to:
  /// **'（Web 不支持文件日志）'**
  String get logWebUnsupported;

  /// No description provided for @logNotInitialized.
  ///
  /// In zh_CN, this message translates to:
  /// **'（未初始化）'**
  String get logNotInitialized;

  /// No description provided for @logAppDataDir.
  ///
  /// In zh_CN, this message translates to:
  /// **'应用数据目录\n{path}'**
  String logAppDataDir(String path);

  /// No description provided for @logAppDataRoaming.
  ///
  /// In zh_CN, this message translates to:
  /// **'AppData（Roaming）\n{path}'**
  String logAppDataRoaming(String path);

  /// No description provided for @logAppSupport.
  ///
  /// In zh_CN, this message translates to:
  /// **'Application Support\n{path}'**
  String logAppSupport(String path);

  /// No description provided for @logLocalDataDir.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地数据目录\n{path}'**
  String logLocalDataDir(String path);

  /// No description provided for @nowPlayingVideo.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在播放视频'**
  String get nowPlayingVideo;

  /// No description provided for @commonUnknown.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知'**
  String get commonUnknown;

  /// No description provided for @unnamedPlaylist.
  ///
  /// In zh_CN, this message translates to:
  /// **'未命名播放列表'**
  String get unnamedPlaylist;

  /// No description provided for @unknownVideo.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知视频'**
  String get unknownVideo;

  /// No description provided for @dohQueryFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'DoH 查询失败: HTTP {code}'**
  String dohQueryFailed(int code);

  /// No description provided for @tcpConnectSuccess.
  ///
  /// In zh_CN, this message translates to:
  /// **'TCP 连接成功'**
  String get tcpConnectSuccess;

  /// No description provided for @netModeCompat.
  ///
  /// In zh_CN, this message translates to:
  /// **'Host 映射 IP 直连, 绕过 SNI 干扰'**
  String get netModeCompat;

  /// No description provided for @netModeStandard.
  ///
  /// In zh_CN, this message translates to:
  /// **'系统默认网络栈'**
  String get netModeStandard;

  /// No description provided for @netHostResolveFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法解析主机 {host}'**
  String netHostResolveFailed(String host);

  /// No description provided for @biliCookieEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'Cookie 为空'**
  String get biliCookieEmpty;

  /// No description provided for @biliCookieIncomplete.
  ///
  /// In zh_CN, this message translates to:
  /// **'Cookie 不完整，请从浏览器复制全部 Cookie（需包含 SESSDATA）'**
  String get biliCookieIncomplete;

  /// No description provided for @biliCookieMissingJct.
  ///
  /// In zh_CN, this message translates to:
  /// **'Cookie 缺少 bili_jct，请重新从浏览器复制完整 Cookie（点赞/发评论等操作依赖它）'**
  String get biliCookieMissingJct;

  /// No description provided for @biliCookieInvalid.
  ///
  /// In zh_CN, this message translates to:
  /// **'Cookie 无效或已过期，请重新从浏览器复制'**
  String get biliCookieInvalid;

  /// No description provided for @biliLoginSuccess.
  ///
  /// In zh_CN, this message translates to:
  /// **'登录成功'**
  String get biliLoginSuccess;

  /// No description provided for @biliHttpError.
  ///
  /// In zh_CN, this message translates to:
  /// **'HTTP {code}'**
  String biliHttpError(int code);

  /// No description provided for @biliRiskBlocked.
  ///
  /// In zh_CN, this message translates to:
  /// **'请求被风控拦截(-412)，请稍后重试'**
  String get biliRiskBlocked;

  /// No description provided for @biliQrExpired.
  ///
  /// In zh_CN, this message translates to:
  /// **'二维码已失效'**
  String get biliQrExpired;

  /// No description provided for @biliQrScanned.
  ///
  /// In zh_CN, this message translates to:
  /// **'已扫码，请在手机上确认'**
  String get biliQrScanned;

  /// No description provided for @biliQrWaiting.
  ///
  /// In zh_CN, this message translates to:
  /// **'等待扫码'**
  String get biliQrWaiting;

  /// No description provided for @biliRequestFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'请求失败'**
  String get biliRequestFailed;

  /// No description provided for @biliResponseNoData.
  ///
  /// In zh_CN, this message translates to:
  /// **'响应缺少 data'**
  String get biliResponseNoData;

  /// No description provided for @biliQrNoSessionCookie.
  ///
  /// In zh_CN, this message translates to:
  /// **'未获取到会话 Cookie，请刷新二维码重试'**
  String get biliQrNoSessionCookie;

  /// No description provided for @biliQrMissingJct.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫码登录未获取到完整会话（缺少 bili_jct），请改用「粘贴 Cookie」或「浏览器登录」方式'**
  String get biliQrMissingJct;

  /// No description provided for @biliNoSessionCookie.
  ///
  /// In zh_CN, this message translates to:
  /// **'未获取到会话 Cookie'**
  String get biliNoSessionCookie;

  /// No description provided for @biliWebKeyFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'获取登录公钥失败，请检查网络'**
  String get biliWebKeyFailed;

  /// No description provided for @biliPwdEncryptFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'密码加密失败'**
  String get biliPwdEncryptFailed;

  /// No description provided for @biliNeedGeetest.
  ///
  /// In zh_CN, this message translates to:
  /// **'需要完成滑块验证'**
  String get biliNeedGeetest;

  /// No description provided for @biliUnknownError.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知错误'**
  String get biliUnknownError;

  /// No description provided for @csPlaylists.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放列表'**
  String get csPlaylists;

  /// No description provided for @csDanmaku.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕'**
  String get csDanmaku;

  /// No description provided for @csCloudEncrypted.
  ///
  /// In zh_CN, this message translates to:
  /// **'云端数据已加密，请先在 WebDAV 设置中填写同步密码'**
  String get csCloudEncrypted;

  /// No description provided for @csCloudPassMismatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'云端数据已加密且同步密码不匹配，无法同步'**
  String get csCloudPassMismatch;

  /// No description provided for @csCloudNoFile.
  ///
  /// In zh_CN, this message translates to:
  /// **'云端没有播放列表文件，无法恢复'**
  String get csCloudNoFile;

  /// No description provided for @csRestoredFromCloud.
  ///
  /// In zh_CN, this message translates to:
  /// **'已从云端恢复'**
  String get csRestoredFromCloud;

  /// No description provided for @csSyncDone.
  ///
  /// In zh_CN, this message translates to:
  /// **'同步完成'**
  String get csSyncDone;

  /// No description provided for @csUploadBgCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'上传背景图 {count} 张'**
  String csUploadBgCount(int count);

  /// No description provided for @csDownloadBgCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'下载背景图 {count} 张'**
  String csDownloadBgCount(int count);

  /// No description provided for @csUploadedFileCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'上传 {count} 个文件'**
  String csUploadedFileCount(int count);

  /// No description provided for @csDownloadedFileCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'下载 {count} 个文件'**
  String csDownloadedFileCount(int count);

  /// No description provided for @csMergedListsCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'合并 {count} 个列表'**
  String csMergedListsCount(int count);

  /// No description provided for @csEncrypted.
  ///
  /// In zh_CN, this message translates to:
  /// **'已加密'**
  String get csEncrypted;

  /// No description provided for @csSyncFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'同步失败: {error}'**
  String csSyncFailed(String error);

  /// No description provided for @csUploadedPlaylists.
  ///
  /// In zh_CN, this message translates to:
  /// **'已上传 {count} 个播放列表到云端'**
  String csUploadedPlaylists(int count);

  /// No description provided for @csDanmakuSummary.
  ///
  /// In zh_CN, this message translates to:
  /// **'上传 {uploaded} 个，下载 {downloaded} 个'**
  String csDanmakuSummary(int uploaded, int downloaded);

  /// No description provided for @csDanmakuFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'，失败 {failed} 个（{details}）'**
  String csDanmakuFailed(int failed, String details);

  /// No description provided for @unknownUser.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知用户'**
  String get unknownUser;

  /// No description provided for @transferSpeedBody.
  ///
  /// In zh_CN, this message translates to:
  /// **'{fileName}  {speed} KB/s'**
  String transferSpeedBody(String fileName, String speed);

  /// No description provided for @sendingFile.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送文件'**
  String get sendingFile;

  /// No description provided for @receivingFile.
  ///
  /// In zh_CN, this message translates to:
  /// **'接收: {fileName}'**
  String receivingFile(String fileName);

  /// No description provided for @notificationChannelName.
  ///
  /// In zh_CN, this message translates to:
  /// **'聊天消息'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDesc.
  ///
  /// In zh_CN, this message translates to:
  /// **'接收聊天消息和快捷回复'**
  String get notificationChannelDesc;

  /// No description provided for @notificationReply.
  ///
  /// In zh_CN, this message translates to:
  /// **'回复'**
  String get notificationReply;

  /// No description provided for @screenshotSavedTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'截图已保存'**
  String get screenshotSavedTitle;

  /// No description provided for @screenshotSavedToAlbum.
  ///
  /// In zh_CN, this message translates to:
  /// **'截图已保存到相册'**
  String get screenshotSavedToAlbum;

  /// No description provided for @notificationConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'确认'**
  String get notificationConfirm;

  /// No description provided for @callInProgressError.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前有未结束的通话，请先挂断'**
  String get callInProgressError;

  /// No description provided for @callTcpFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法连接对方（TCP 建立失败），请确认对方在线'**
  String get callTcpFailed;

  /// No description provided for @callConnectionDropped.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接建立后立即断开，请检查网络或对方状态'**
  String get callConnectionDropped;

  /// No description provided for @callInitFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'发起通话失败：{error}'**
  String callInitFailed(String error);

  /// No description provided for @callAcceptFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'接听通话失败：{error}'**
  String callAcceptFailed(String error);

  /// No description provided for @callRecordVoice.
  ///
  /// In zh_CN, this message translates to:
  /// **'语音通话'**
  String get callRecordVoice;

  /// No description provided for @callRecordMissedOutgoing.
  ///
  /// In zh_CN, this message translates to:
  /// **'未接通话'**
  String get callRecordMissedOutgoing;

  /// No description provided for @callRecordRejected.
  ///
  /// In zh_CN, this message translates to:
  /// **'已拒绝来电'**
  String get callRecordRejected;

  /// No description provided for @callRecordMissedIncoming.
  ///
  /// In zh_CN, this message translates to:
  /// **'未接来电'**
  String get callRecordMissedIncoming;

  /// No description provided for @callPeerNoAnswer.
  ///
  /// In zh_CN, this message translates to:
  /// **'对方未接听'**
  String get callPeerNoAnswer;

  /// No description provided for @callUnknown.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知'**
  String get callUnknown;

  /// No description provided for @callInProgress.
  ///
  /// In zh_CN, this message translates to:
  /// **'通话中'**
  String get callInProgress;

  /// No description provided for @webdavHttpWarning.
  ///
  /// In zh_CN, this message translates to:
  /// **'警告：使用 HTTP 连接，凭证将以明文传输。建议使用 HTTPS。'**
  String get webdavHttpWarning;

  /// No description provided for @webdavConfigRequired.
  ///
  /// In zh_CN, this message translates to:
  /// **'请先填写服务器地址和用户名'**
  String get webdavConfigRequired;

  /// No description provided for @webdavAuthFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'认证失败：用户名或密码错误'**
  String get webdavAuthFailed;

  /// No description provided for @webdavConnectFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接失败：HTTP {code}'**
  String webdavConnectFailed(int code);

  /// No description provided for @webdavNetworkError.
  ///
  /// In zh_CN, this message translates to:
  /// **'网络错误：无法连接到服务器 ({msg})'**
  String webdavNetworkError(String msg);

  /// No description provided for @webdavUnknownError.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知错误：{error}'**
  String webdavUnknownError(String error);

  /// No description provided for @webdavNotConfigured.
  ///
  /// In zh_CN, this message translates to:
  /// **'WebDAV 未配置'**
  String get webdavNotConfigured;

  /// No description provided for @webdavLocalFileMissing.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地文件不存在: {path}'**
  String webdavLocalFileMissing(String path);

  /// No description provided for @webdavUploadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'上传失败：HTTP {code}'**
  String webdavUploadFailed(int code);

  /// No description provided for @webdavUploadError.
  ///
  /// In zh_CN, this message translates to:
  /// **'上传异常：{error}'**
  String webdavUploadError(String error);

  /// No description provided for @webdavDownloadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'下载失败: HTTP {code}'**
  String webdavDownloadFailed(int code);

  /// No description provided for @webdavDownloadError.
  ///
  /// In zh_CN, this message translates to:
  /// **'下载异常: {error}'**
  String webdavDownloadError(String error);

  /// No description provided for @webdavDeleteFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除失败: {error}'**
  String webdavDeleteFailed(String error);

  /// No description provided for @webdavListFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'列出文件失败: {error}'**
  String webdavListFailed(String error);

  /// No description provided for @webdavPropfindFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'PROPFIND 失败: HTTP {code}'**
  String webdavPropfindFailed(int code);

  /// No description provided for @webdavNetworkErr.
  ///
  /// In zh_CN, this message translates to:
  /// **'网络错误：{msg}'**
  String webdavNetworkErr(String msg);

  /// No description provided for @webdavPreparingBackup.
  ///
  /// In zh_CN, this message translates to:
  /// **'准备备份 {count} 个文件...'**
  String webdavPreparingBackup(int count);

  /// No description provided for @webdavBackingUp.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在备份 ({nickname}) {fileName}'**
  String webdavBackingUp(String nickname, String fileName);

  /// No description provided for @webdavBackupDone.
  ///
  /// In zh_CN, this message translates to:
  /// **'备份完成：{success} 成功，{fail} 失败'**
  String webdavBackupDone(int success, int fail);

  /// No description provided for @commonCancel.
  ///
  /// In zh_CN, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定'**
  String get commonOk;

  /// No description provided for @commonConnect.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接'**
  String get commonConnect;

  /// No description provided for @commonSave.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonCreate.
  ///
  /// In zh_CN, this message translates to:
  /// **'创建'**
  String get commonCreate;

  /// No description provided for @commonDelete.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @drawerHome.
  ///
  /// In zh_CN, this message translates to:
  /// **'主页'**
  String get drawerHome;

  /// No description provided for @drawerVerificationRequests.
  ///
  /// In zh_CN, this message translates to:
  /// **'验证请求'**
  String get drawerVerificationRequests;

  /// No description provided for @drawerSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置'**
  String get drawerSettings;

  /// No description provided for @drawerAbout.
  ///
  /// In zh_CN, this message translates to:
  /// **'关于'**
  String get drawerAbout;

  /// No description provided for @drawerCloseMenu.
  ///
  /// In zh_CN, this message translates to:
  /// **'关闭菜单'**
  String get drawerCloseMenu;

  /// No description provided for @drawerLockNow.
  ///
  /// In zh_CN, this message translates to:
  /// **'立即锁定'**
  String get drawerLockNow;

  /// No description provided for @drawerNoNickname.
  ///
  /// In zh_CN, this message translates to:
  /// **'未设置昵称'**
  String get drawerNoNickname;

  /// No description provided for @drawerSwitchToDark.
  ///
  /// In zh_CN, this message translates to:
  /// **'切换到深色模式'**
  String get drawerSwitchToDark;

  /// No description provided for @drawerSwitchToLight.
  ///
  /// In zh_CN, this message translates to:
  /// **'切换到浅色模式'**
  String get drawerSwitchToLight;

  /// No description provided for @drawerLightMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'浅色模式'**
  String get drawerLightMode;

  /// No description provided for @drawerDarkMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'深色模式'**
  String get drawerDarkMode;

  /// No description provided for @drawerSystemMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'跟随系统'**
  String get drawerSystemMode;

  /// No description provided for @drawerThemeSwitched.
  ///
  /// In zh_CN, this message translates to:
  /// **'已切换到 {mode}'**
  String drawerThemeSwitched(String mode);

  /// No description provided for @drawerFetchFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'获取失败: {error}'**
  String drawerFetchFailed(String error);

  /// No description provided for @drawerNoDeviceInfo.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无设备信息'**
  String get drawerNoDeviceInfo;

  /// No description provided for @drawerBackgroundTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'侧边栏背景'**
  String get drawerBackgroundTitle;

  /// No description provided for @drawerBackgroundHasCustom.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前已设置自定义背景，您可以更换或移除。'**
  String get drawerBackgroundHasCustom;

  /// No description provided for @drawerBackgroundNoCustom.
  ///
  /// In zh_CN, this message translates to:
  /// **'为侧边栏设置一张个性化背景图片。'**
  String get drawerBackgroundNoCustom;

  /// No description provided for @drawerBackgroundUpdated.
  ///
  /// In zh_CN, this message translates to:
  /// **'侧边栏背景已更新'**
  String get drawerBackgroundUpdated;

  /// No description provided for @drawerBackgroundSetFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置失败: {error}'**
  String drawerBackgroundSetFailed(String error);

  /// No description provided for @drawerBackgroundChange.
  ///
  /// In zh_CN, this message translates to:
  /// **'更换背景'**
  String get drawerBackgroundChange;

  /// No description provided for @drawerBackgroundSelect.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择背景图片'**
  String get drawerBackgroundSelect;

  /// No description provided for @drawerBackgroundRestored.
  ///
  /// In zh_CN, this message translates to:
  /// **'已恢复默认背景'**
  String get drawerBackgroundRestored;

  /// No description provided for @drawerBackgroundRemove.
  ///
  /// In zh_CN, this message translates to:
  /// **'移除背景'**
  String get drawerBackgroundRemove;

  /// No description provided for @homeOpenMenu.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开菜单'**
  String get homeOpenMenu;

  /// No description provided for @homeAddConnection.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加连接'**
  String get homeAddConnection;

  /// No description provided for @homeMessages.
  ///
  /// In zh_CN, this message translates to:
  /// **'消息'**
  String get homeMessages;

  /// No description provided for @homeNoConnections.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无连接'**
  String get homeNoConnections;

  /// No description provided for @homePullToRefreshHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'下拉刷新或点击右上角添加'**
  String get homePullToRefreshHint;

  /// No description provided for @homeLoadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'聊天记录加载失败，请重试'**
  String get homeLoadFailed;

  /// No description provided for @homeRetryLoad.
  ///
  /// In zh_CN, this message translates to:
  /// **'重新加载'**
  String get homeRetryLoad;

  /// No description provided for @homeUnknownAddress.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知地址'**
  String get homeUnknownAddress;

  /// No description provided for @homeNoMessages.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无消息'**
  String get homeNoMessages;

  /// No description provided for @homeFileMessage.
  ///
  /// In zh_CN, this message translates to:
  /// **'[文件] {fileName}'**
  String homeFileMessage(String fileName);

  /// No description provided for @homeFileFallbackName.
  ///
  /// In zh_CN, this message translates to:
  /// **'文件'**
  String get homeFileFallbackName;

  /// No description provided for @homeMessagePlaceholder.
  ///
  /// In zh_CN, this message translates to:
  /// **'[消息]'**
  String get homeMessagePlaceholder;

  /// No description provided for @connectionLost.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接已失效'**
  String get connectionLost;

  /// No description provided for @openVideoFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法打开该视频'**
  String get openVideoFailed;

  /// No description provided for @connectDialogTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接到对等端'**
  String get connectDialogTitle;

  /// No description provided for @connectIpHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入 IP 地址 (例如：192.168.1.100 或 fe80::1)'**
  String get connectIpHint;

  /// No description provided for @connectIpEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'请输入 IP 地址'**
  String get connectIpEmpty;

  /// No description provided for @connectIpInvalid.
  ///
  /// In zh_CN, this message translates to:
  /// **'IP 地址格式不正确'**
  String get connectIpInvalid;

  /// No description provided for @connectIpNotLan.
  ///
  /// In zh_CN, this message translates to:
  /// **'仅允许内网 IP 地址'**
  String get connectIpNotLan;

  /// No description provided for @connectRequestSent.
  ///
  /// In zh_CN, this message translates to:
  /// **'已发送连接请求，等待对方验证'**
  String get connectRequestSent;

  /// No description provided for @connectFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接失败，请检查 IP 地址是否正确或对方是否在线'**
  String get connectFailed;

  /// No description provided for @homeScanQr.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫一扫'**
  String get homeScanQr;

  /// No description provided for @homeMyQrCode.
  ///
  /// In zh_CN, this message translates to:
  /// **'我的二维码'**
  String get homeMyQrCode;

  /// No description provided for @homeManualAdd.
  ///
  /// In zh_CN, this message translates to:
  /// **'手动添加'**
  String get homeManualAdd;

  /// No description provided for @scannedFriends.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫码添加的好友'**
  String get scannedFriends;

  /// No description provided for @scanTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫一扫'**
  String get scanTitle;

  /// No description provided for @scanTitleWebdav.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描 WebDAV 地址'**
  String get scanTitleWebdav;

  /// No description provided for @scanHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'将二维码 / 条码对准框内'**
  String get scanHint;

  /// No description provided for @scanHintWebdav.
  ///
  /// In zh_CN, this message translates to:
  /// **'将 WebDAV 服务器地址二维码对准框内'**
  String get scanHintWebdav;

  /// No description provided for @scanHintAddFriend.
  ///
  /// In zh_CN, this message translates to:
  /// **'将好友的设备二维码对准框内'**
  String get scanHintAddFriend;

  /// No description provided for @scanPreparing.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在准备摄像头...'**
  String get scanPreparing;

  /// No description provided for @scanPermissionNeeded.
  ///
  /// In zh_CN, this message translates to:
  /// **'需要摄像头权限'**
  String get scanPermissionNeeded;

  /// No description provided for @scanPermissionNeededMsg.
  ///
  /// In zh_CN, this message translates to:
  /// **'请在权限弹窗中允许使用摄像头，才能扫码。'**
  String get scanPermissionNeededMsg;

  /// No description provided for @scanPermissionDenied.
  ///
  /// In zh_CN, this message translates to:
  /// **'摄像头权限被拒绝'**
  String get scanPermissionDenied;

  /// No description provided for @scanPermissionDeniedMsg.
  ///
  /// In zh_CN, this message translates to:
  /// **'权限已被永久拒绝，请前往系统设置手动开启。'**
  String get scanPermissionDeniedMsg;

  /// No description provided for @scanCameraUnavailable.
  ///
  /// In zh_CN, this message translates to:
  /// **'摄像头不可用'**
  String get scanCameraUnavailable;

  /// No description provided for @scanRetry.
  ///
  /// In zh_CN, this message translates to:
  /// **'重试'**
  String get scanRetry;

  /// No description provided for @scanOpenSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'前往系统设置'**
  String get scanOpenSettings;

  /// No description provided for @scanTorch.
  ///
  /// In zh_CN, this message translates to:
  /// **'闪光灯'**
  String get scanTorch;

  /// No description provided for @scanDetectedLink.
  ///
  /// In zh_CN, this message translates to:
  /// **'检测到链接'**
  String get scanDetectedLink;

  /// No description provided for @scanOpenLinkPrompt.
  ///
  /// In zh_CN, this message translates to:
  /// **'是否在内置浏览器中打开以下链接？'**
  String get scanOpenLinkPrompt;

  /// No description provided for @scanCopy.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制'**
  String get scanCopy;

  /// No description provided for @scanOpen.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开'**
  String get scanOpen;

  /// No description provided for @scanLinkCopied.
  ///
  /// In zh_CN, this message translates to:
  /// **'链接已复制'**
  String get scanLinkCopied;

  /// No description provided for @scanDetectedBiliVideo.
  ///
  /// In zh_CN, this message translates to:
  /// **'检测到 B 站视频链接'**
  String get scanDetectedBiliVideo;

  /// No description provided for @scanBiliVideoPrompt.
  ///
  /// In zh_CN, this message translates to:
  /// **'是否用内置播放器打开该视频？'**
  String get scanBiliVideoPrompt;

  /// No description provided for @scanBiliVideoAt.
  ///
  /// In zh_CN, this message translates to:
  /// **'空降至 {time}'**
  String scanBiliVideoAt(String time);

  /// No description provided for @scanOpenVideo.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开视频'**
  String get scanOpenVideo;

  /// No description provided for @scanDetectedWebdav.
  ///
  /// In zh_CN, this message translates to:
  /// **'检测到 WebDAV 地址'**
  String get scanDetectedWebdav;

  /// No description provided for @scanWebdavPrompt.
  ///
  /// In zh_CN, this message translates to:
  /// **'该链接看起来是 WebDAV 服务器地址，是否自动填入配置？'**
  String get scanWebdavPrompt;

  /// No description provided for @scanOpenInBrowser.
  ///
  /// In zh_CN, this message translates to:
  /// **'浏览器打开'**
  String get scanOpenInBrowser;

  /// No description provided for @scanFillConfig.
  ///
  /// In zh_CN, this message translates to:
  /// **'填入配置'**
  String get scanFillConfig;

  /// No description provided for @scanDetectedText.
  ///
  /// In zh_CN, this message translates to:
  /// **'识别到文本'**
  String get scanDetectedText;

  /// No description provided for @scanCopiedToClipboard.
  ///
  /// In zh_CN, this message translates to:
  /// **'已复制到剪贴板'**
  String get scanCopiedToClipboard;

  /// No description provided for @scanClose.
  ///
  /// In zh_CN, this message translates to:
  /// **'关闭'**
  String get scanClose;

  /// No description provided for @scanResultTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫码结果'**
  String get scanResultTitle;

  /// No description provided for @scanErrorPermission.
  ///
  /// In zh_CN, this message translates to:
  /// **'摄像头权限被拒绝'**
  String get scanErrorPermission;

  /// No description provided for @scanErrorUnsupported.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前设备不支持扫码'**
  String get scanErrorUnsupported;

  /// No description provided for @scanErrorDisposed.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫码器已释放，请重试'**
  String get scanErrorDisposed;

  /// No description provided for @scanErrorGeneric.
  ///
  /// In zh_CN, this message translates to:
  /// **'摄像头不可用（{code}）'**
  String scanErrorGeneric(String code);

  /// No description provided for @scanInitFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫码器初始化失败：{error}'**
  String scanInitFailed(String error);

  /// No description provided for @scanDetectedDevice.
  ///
  /// In zh_CN, this message translates to:
  /// **'检测到设备二维码'**
  String get scanDetectedDevice;

  /// No description provided for @scanAddFriendPrompt.
  ///
  /// In zh_CN, this message translates to:
  /// **'是否添加该设备为好友？'**
  String get scanAddFriendPrompt;

  /// No description provided for @scanAddFriend.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加好友'**
  String get scanAddFriend;

  /// No description provided for @scanFriendAdded.
  ///
  /// In zh_CN, this message translates to:
  /// **'已发送好友请求，等待对方验证'**
  String get scanFriendAdded;

  /// No description provided for @scanFriendAddFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加好友失败，请检查网络或对方是否在线'**
  String get scanFriendAddFailed;

  /// No description provided for @myQrTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'我的二维码'**
  String get myQrTitle;

  /// No description provided for @myQrHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'让好友扫描此二维码添加您'**
  String get myQrHint;

  /// No description provided for @myQrEmbedIp.
  ///
  /// In zh_CN, this message translates to:
  /// **'二维码中已嵌入第一个局域网 IP'**
  String get myQrEmbedIp;

  /// No description provided for @myQrLocalIps.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前局域网 IP'**
  String get myQrLocalIps;

  /// No description provided for @myQrCopyContent.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制二维码内容'**
  String get myQrCopyContent;

  /// No description provided for @myQrCopied.
  ///
  /// In zh_CN, this message translates to:
  /// **'已复制到剪贴板'**
  String get myQrCopied;

  /// No description provided for @myQrNoIp.
  ///
  /// In zh_CN, this message translates to:
  /// **'未找到有效的局域网 IP，请检查网络连接。'**
  String get myQrNoIp;

  /// No description provided for @displayModeSectionTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'屏幕'**
  String get displayModeSectionTitle;

  /// No description provided for @displayModeTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'屏幕帧率'**
  String get displayModeTitle;

  /// No description provided for @displayModeAuto.
  ///
  /// In zh_CN, this message translates to:
  /// **'自动'**
  String get displayModeAuto;

  /// No description provided for @displayModeSystemTag.
  ///
  /// In zh_CN, this message translates to:
  /// **'[系统]'**
  String get displayModeSystemTag;

  /// No description provided for @displayModeHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有生效？重启应用试试'**
  String get displayModeHint;

  /// No description provided for @displayModeUnsupported.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前平台不支持设置屏幕帧率（仅 Android）'**
  String get displayModeUnsupported;

  /// No description provided for @displayModeAndroidOnly.
  ///
  /// In zh_CN, this message translates to:
  /// **'仅 Android'**
  String get displayModeAndroidOnly;

  /// No description provided for @displayModeLoading.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在获取屏幕帧率...'**
  String get displayModeLoading;

  /// No description provided for @displayModeEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'未获取到可用的屏幕帧率'**
  String get displayModeEmpty;

  /// No description provided for @playerSectionEnhance.
  ///
  /// In zh_CN, this message translates to:
  /// **'画面增强'**
  String get playerSectionEnhance;

  /// No description provided for @superResolutionTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'超分辨率'**
  String get superResolutionTitle;

  /// No description provided for @superResolutionOff.
  ///
  /// In zh_CN, this message translates to:
  /// **'关闭'**
  String get superResolutionOff;

  /// No description provided for @superResolutionEfficiency.
  ///
  /// In zh_CN, this message translates to:
  /// **'效率（低开销）'**
  String get superResolutionEfficiency;

  /// No description provided for @superResolutionQuality.
  ///
  /// In zh_CN, this message translates to:
  /// **'画质（最佳效果）'**
  String get superResolutionQuality;

  /// No description provided for @superResolutionHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'通过 mpv 着色器实时增强画面，建议配合硬件解码；对动画内容效果最佳'**
  String get superResolutionHint;

  /// No description provided for @skipIntroOutroTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'跳过片头/片尾'**
  String get skipIntroOutroTitle;

  /// No description provided for @skipIntroOutroHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'通过社区共享数据识别片头片尾，仅在视频有 BV+CID 时提示'**
  String get skipIntroOutroHint;

  /// No description provided for @skipIntro.
  ///
  /// In zh_CN, this message translates to:
  /// **'跳过片头'**
  String get skipIntro;

  /// No description provided for @skipOutro.
  ///
  /// In zh_CN, this message translates to:
  /// **'跳过片尾'**
  String get skipOutro;

  /// No description provided for @playlistDetailEpisodes.
  ///
  /// In zh_CN, this message translates to:
  /// **'共 {count} 集'**
  String playlistDetailEpisodes(int count);

  /// No description provided for @playlistDetailEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'该播放列表为空，请先编辑添加视频'**
  String get playlistDetailEmpty;

  /// No description provided for @playlistDetailEpisodeOf.
  ///
  /// In zh_CN, this message translates to:
  /// **'第 {index} 集'**
  String playlistDetailEpisodeOf(int index);

  /// No description provided for @playlistDetailResume.
  ///
  /// In zh_CN, this message translates to:
  /// **'看到这集 · {position}'**
  String playlistDetailResume(String position);

  /// No description provided for @playlistDetailBgTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'背景图'**
  String get playlistDetailBgTitle;

  /// No description provided for @playlistDetailBgPick.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择背景图片'**
  String get playlistDetailBgPick;

  /// No description provided for @playlistDetailBgChange.
  ///
  /// In zh_CN, this message translates to:
  /// **'更换背景'**
  String get playlistDetailBgChange;

  /// No description provided for @playlistDetailBgRemove.
  ///
  /// In zh_CN, this message translates to:
  /// **'移除背景'**
  String get playlistDetailBgRemove;

  /// No description provided for @playlistDetailBgUpdated.
  ///
  /// In zh_CN, this message translates to:
  /// **'✅ 背景图已更新'**
  String get playlistDetailBgUpdated;

  /// No description provided for @playlistDetailBgRemoved.
  ///
  /// In zh_CN, this message translates to:
  /// **'已恢复默认背景'**
  String get playlistDetailBgRemoved;

  /// No description provided for @playlistDetailBgFail.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置失败：{error}'**
  String playlistDetailBgFail(String error);

  /// No description provided for @playlistFabRestart.
  ///
  /// In zh_CN, this message translates to:
  /// **'从头开始'**
  String get playlistFabRestart;

  /// No description provided for @playlistMenuMore.
  ///
  /// In zh_CN, this message translates to:
  /// **'更多操作'**
  String get playlistMenuMore;

  /// No description provided for @playlistMenuRename.
  ///
  /// In zh_CN, this message translates to:
  /// **'编辑名字'**
  String get playlistMenuRename;

  /// No description provided for @playlistMenuMultiSelect.
  ///
  /// In zh_CN, this message translates to:
  /// **'多选'**
  String get playlistMenuMultiSelect;

  /// No description provided for @playlistMenuDanmaku.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕'**
  String get playlistMenuDanmaku;

  /// No description provided for @playlistRenameTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'重命名播放列表'**
  String get playlistRenameTitle;

  /// No description provided for @playlistRenameHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入新的列表名称'**
  String get playlistRenameHint;

  /// No description provided for @playlistRenameSaved.
  ///
  /// In zh_CN, this message translates to:
  /// **'已重命名'**
  String get playlistRenameSaved;

  /// No description provided for @playlistSelectDone.
  ///
  /// In zh_CN, this message translates to:
  /// **'完成'**
  String get playlistSelectDone;

  /// No description provided for @playlistSelectEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'请先选择剧集'**
  String get playlistSelectEmpty;

  /// No description provided for @playlistSelectDelete.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除选中（{count}）'**
  String playlistSelectDelete(int count);

  /// No description provided for @playlistSelectDeleted.
  ///
  /// In zh_CN, this message translates to:
  /// **'已删除 {count} 集'**
  String playlistSelectDeleted(int count);

  /// No description provided for @playlistDanmakuTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'导入番剧弹幕'**
  String get playlistDanmakuTitle;

  /// No description provided for @playlistDanmakuSsHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入番剧 SS 号（season_id）'**
  String get playlistDanmakuSsHint;

  /// No description provided for @playlistDanmakuFetchFail.
  ///
  /// In zh_CN, this message translates to:
  /// **'获取剧集失败，请检查 SS 号'**
  String get playlistDanmakuFetchFail;

  /// No description provided for @playlistDanmakuSelectTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择剧集（共 {count} 集）'**
  String playlistDanmakuSelectTitle(int count);

  /// No description provided for @playlistDanmakuSelectAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'全选'**
  String get playlistDanmakuSelectAll;

  /// No description provided for @playlistDanmakuImport.
  ///
  /// In zh_CN, this message translates to:
  /// **'导入并附加弹幕'**
  String get playlistDanmakuImport;

  /// No description provided for @playlistDanmakuAttached.
  ///
  /// In zh_CN, this message translates to:
  /// **'已为 {count} 集附加弹幕'**
  String playlistDanmakuAttached(int count);

  /// No description provided for @playlistDanmakuExceed.
  ///
  /// In zh_CN, this message translates to:
  /// **'所选 {selected} 集超过列表 {total} 集，超出部分已忽略'**
  String playlistDanmakuExceed(int selected, int total);

  /// No description provided for @splitSelectChat.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择一个聊天'**
  String get splitSelectChat;

  /// No description provided for @statusPending.
  ///
  /// In zh_CN, this message translates to:
  /// **'待对方验证'**
  String get statusPending;

  /// No description provided for @statusConnected.
  ///
  /// In zh_CN, this message translates to:
  /// **'已连接'**
  String get statusConnected;

  /// No description provided for @statusRejected.
  ///
  /// In zh_CN, this message translates to:
  /// **'已拒绝'**
  String get statusRejected;

  /// No description provided for @statusDisconnected.
  ///
  /// In zh_CN, this message translates to:
  /// **'已断开'**
  String get statusDisconnected;

  /// No description provided for @homeStart.
  ///
  /// In zh_CN, this message translates to:
  /// **'开始'**
  String get homeStart;

  /// No description provided for @homeDone.
  ///
  /// In zh_CN, this message translates to:
  /// **'完成'**
  String get homeDone;

  /// No description provided for @homeBack.
  ///
  /// In zh_CN, this message translates to:
  /// **'返回'**
  String get homeBack;

  /// No description provided for @homeOverview.
  ///
  /// In zh_CN, this message translates to:
  /// **'鸟瞰视图'**
  String get homeOverview;

  /// No description provided for @homeLocalUser.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地用户'**
  String get homeLocalUser;

  /// No description provided for @homeDefaultGroup.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认分组'**
  String get homeDefaultGroup;

  /// No description provided for @homeNewGroup.
  ///
  /// In zh_CN, this message translates to:
  /// **'新分组'**
  String get homeNewGroup;

  /// No description provided for @homeUnnamedGroup.
  ///
  /// In zh_CN, this message translates to:
  /// **'(未命名分组)'**
  String get homeUnnamedGroup;

  /// No description provided for @homeDeleteGroupTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'确认删除'**
  String get homeDeleteGroupTitle;

  /// No description provided for @homeDeleteGroupMessage.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除该组将同时删除组内的所有磁贴，是否继续？'**
  String get homeDeleteGroupMessage;

  /// No description provided for @homeNewGroupTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'新建分组'**
  String get homeNewGroupTitle;

  /// No description provided for @homeGroupNameHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入分组名称'**
  String get homeGroupNameHint;

  /// No description provided for @homeRenameGroupTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'为该组命名'**
  String get homeRenameGroupTitle;

  /// No description provided for @homeNewGroupNameHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入新组名'**
  String get homeNewGroupNameHint;

  /// No description provided for @homeImageSlice.
  ///
  /// In zh_CN, this message translates to:
  /// **'图片碎片'**
  String get homeImageSlice;

  /// No description provided for @tileSizeLabelSmall.
  ///
  /// In zh_CN, this message translates to:
  /// **'{size} (小)'**
  String tileSizeLabelSmall(String size);

  /// No description provided for @tileSizeLabelWide.
  ///
  /// In zh_CN, this message translates to:
  /// **'{size} (宽)'**
  String tileSizeLabelWide(String size);

  /// No description provided for @tileSizeLabelLarge.
  ///
  /// In zh_CN, this message translates to:
  /// **'{size} (大)'**
  String tileSizeLabelLarge(String size);

  /// No description provided for @homeGroupOne.
  ///
  /// In zh_CN, this message translates to:
  /// **'分组1'**
  String get homeGroupOne;

  /// No description provided for @homeGroupTwo.
  ///
  /// In zh_CN, this message translates to:
  /// **'分组2'**
  String get homeGroupTwo;

  /// No description provided for @homeGroupProductivity.
  ///
  /// In zh_CN, this message translates to:
  /// **'生产力工具'**
  String get homeGroupProductivity;

  /// No description provided for @homeGroupLegacy.
  ///
  /// In zh_CN, this message translates to:
  /// **'旧版'**
  String get homeGroupLegacy;

  /// No description provided for @tileImageSlicer.
  ///
  /// In zh_CN, this message translates to:
  /// **'图片切割'**
  String get tileImageSlicer;

  /// No description provided for @tileSystemSettings.
  ///
  /// In zh_CN, this message translates to:
  /// **'系统设置'**
  String get tileSystemSettings;

  /// No description provided for @tileDatabase.
  ///
  /// In zh_CN, this message translates to:
  /// **'数据库'**
  String get tileDatabase;

  /// No description provided for @tileLcdDisplay.
  ///
  /// In zh_CN, this message translates to:
  /// **'LCD 显示屏'**
  String get tileLcdDisplay;

  /// No description provided for @tileLedDynamic.
  ///
  /// In zh_CN, this message translates to:
  /// **'LED 动态'**
  String get tileLedDynamic;

  /// No description provided for @tileLedStatic.
  ///
  /// In zh_CN, this message translates to:
  /// **'LED 静态'**
  String get tileLedStatic;

  /// No description provided for @tilePisScreen.
  ///
  /// In zh_CN, this message translates to:
  /// **'PIS 屏幕'**
  String get tilePisScreen;

  /// No description provided for @tileRoutePreview.
  ///
  /// In zh_CN, this message translates to:
  /// **'路线预览'**
  String get tileRoutePreview;

  /// No description provided for @tileStationEntranceDesign.
  ///
  /// In zh_CN, this message translates to:
  /// **'出入口设计'**
  String get tileStationEntranceDesign;

  /// No description provided for @tileStationEntrancePillar.
  ///
  /// In zh_CN, this message translates to:
  /// **'出入口立柱'**
  String get tileStationEntrancePillar;

  /// No description provided for @tileStationEntranceSideName.
  ///
  /// In zh_CN, this message translates to:
  /// **'出入口侧名'**
  String get tileStationEntranceSideName;

  /// No description provided for @tilePlatformSideName.
  ///
  /// In zh_CN, this message translates to:
  /// **'侧方站名'**
  String get tilePlatformSideName;

  /// No description provided for @tileScreenDoorCover.
  ///
  /// In zh_CN, this message translates to:
  /// **'屏蔽门盖板'**
  String get tileScreenDoorCover;

  /// No description provided for @tileStationNameSign.
  ///
  /// In zh_CN, this message translates to:
  /// **'站名牌'**
  String get tileStationNameSign;

  /// No description provided for @tileGeneralSign.
  ///
  /// In zh_CN, this message translates to:
  /// **'通用标识'**
  String get tileGeneralSign;

  /// No description provided for @tileLineSymbol.
  ///
  /// In zh_CN, this message translates to:
  /// **'线路符号'**
  String get tileLineSymbol;

  /// No description provided for @tileBusLcd.
  ///
  /// In zh_CN, this message translates to:
  /// **'巴士 LCD'**
  String get tileBusLcd;

  /// No description provided for @tileJsonEditor.
  ///
  /// In zh_CN, this message translates to:
  /// **'JSON 编辑器'**
  String get tileJsonEditor;

  /// No description provided for @tileNamingRule.
  ///
  /// In zh_CN, this message translates to:
  /// **'命名规范'**
  String get tileNamingRule;

  /// No description provided for @tilePlatformText.
  ///
  /// In zh_CN, this message translates to:
  /// **'站台文本'**
  String get tilePlatformText;

  /// No description provided for @tileDepartureText.
  ///
  /// In zh_CN, this message translates to:
  /// **'出发文本'**
  String get tileDepartureText;

  /// No description provided for @tileArrivalText.
  ///
  /// In zh_CN, this message translates to:
  /// **'到站文本'**
  String get tileArrivalText;

  /// No description provided for @tileOperationDirectionLegacy.
  ///
  /// In zh_CN, this message translates to:
  /// **'运营方向(旧)'**
  String get tileOperationDirectionLegacy;

  /// No description provided for @tileLegacyLcdWarning.
  ///
  /// In zh_CN, this message translates to:
  /// **'旧版LCD(警告)'**
  String get tileLegacyLcdWarning;

  /// No description provided for @tileLinearRoute.
  ///
  /// In zh_CN, this message translates to:
  /// **'线性路线'**
  String get tileLinearRoute;

  /// No description provided for @tileRoadSign.
  ///
  /// In zh_CN, this message translates to:
  /// **'路牌'**
  String get tileRoadSign;

  /// No description provided for @commentPanelTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'评论区'**
  String get commentPanelTitle;

  /// No description provided for @commentTotalCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'共 {count} 条'**
  String commentTotalCount(int count);

  /// No description provided for @commentSortHeat.
  ///
  /// In zh_CN, this message translates to:
  /// **'按热度'**
  String get commentSortHeat;

  /// No description provided for @commentSortTime.
  ///
  /// In zh_CN, this message translates to:
  /// **'按时间'**
  String get commentSortTime;

  /// No description provided for @commentLoading.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在加载评论...'**
  String get commentLoading;

  /// No description provided for @commentLoadFail.
  ///
  /// In zh_CN, this message translates to:
  /// **'评论加载失败，请检查网络'**
  String get commentLoadFail;

  /// No description provided for @commentLoadMoreFail.
  ///
  /// In zh_CN, this message translates to:
  /// **'加载更多评论失败'**
  String get commentLoadMoreFail;

  /// No description provided for @commentNoMore.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有更多评论了'**
  String get commentNoMore;

  /// No description provided for @commentLoadingMore.
  ///
  /// In zh_CN, this message translates to:
  /// **'加载中...'**
  String get commentLoadingMore;

  /// No description provided for @commentEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'还没有评论'**
  String get commentEmpty;

  /// No description provided for @commentPinned.
  ///
  /// In zh_CN, this message translates to:
  /// **'置顶'**
  String get commentPinned;

  /// No description provided for @commentDeleted.
  ///
  /// In zh_CN, this message translates to:
  /// **'评论已删除'**
  String get commentDeleted;

  /// No description provided for @commentExpand.
  ///
  /// In zh_CN, this message translates to:
  /// **'展开'**
  String get commentExpand;

  /// No description provided for @commentCollapse.
  ///
  /// In zh_CN, this message translates to:
  /// **'收起'**
  String get commentCollapse;

  /// No description provided for @commentTranslateNeedEnable.
  ///
  /// In zh_CN, this message translates to:
  /// **'请先在语言设置中开启 AI 翻译'**
  String get commentTranslateNeedEnable;

  /// No description provided for @commentTranslateNone.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有可用翻译'**
  String get commentTranslateNone;

  /// No description provided for @commentSubCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'共 {count} 条回复'**
  String commentSubCount(int count);

  /// No description provided for @commentSubLoadMore.
  ///
  /// In zh_CN, this message translates to:
  /// **'加载更多回复（{hint}）'**
  String commentSubLoadMore(String hint);

  /// No description provided for @commentYesterday.
  ///
  /// In zh_CN, this message translates to:
  /// **'昨天'**
  String get commentYesterday;

  /// No description provided for @articleLoadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'文章加载失败'**
  String get articleLoadFailed;

  /// No description provided for @articleNoContent.
  ///
  /// In zh_CN, this message translates to:
  /// **'文章正文为空或暂不支持渲染'**
  String get articleNoContent;

  /// No description provided for @articleOpenBrowser.
  ///
  /// In zh_CN, this message translates to:
  /// **'浏览器打开'**
  String get articleOpenBrowser;

  /// No description provided for @articleShare.
  ///
  /// In zh_CN, this message translates to:
  /// **'分享'**
  String get articleShare;

  /// No description provided for @articleAuthorUnknown.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知作者'**
  String get articleAuthorUnknown;

  /// No description provided for @browserLinkPageTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'网页链接'**
  String get browserLinkPageTitle;

  /// No description provided for @articleViews.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 阅读'**
  String articleViews(String count);

  /// No description provided for @contactPickerTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送给联系人'**
  String get contactPickerTitle;

  /// No description provided for @contactPickerContentLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送内容'**
  String get contactPickerContentLabel;

  /// No description provided for @contactPickerContentHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入要发送的内容'**
  String get contactPickerContentHint;

  /// No description provided for @contactPickerContentEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'内容不能为空'**
  String get contactPickerContentEmpty;

  /// No description provided for @contactPickerSearchHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索联系人'**
  String get contactPickerSearchHint;

  /// No description provided for @contactPickerEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无联系人'**
  String get contactPickerEmpty;

  /// No description provided for @contactPickerNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'未找到匹配的联系人'**
  String get contactPickerNoMatch;

  /// No description provided for @contactPickerSelectAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'全选'**
  String get contactPickerSelectAll;

  /// No description provided for @contactPickerSendToCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送给 {count} 个联系人'**
  String contactPickerSendToCount(int count);

  /// No description provided for @contactPickerSent.
  ///
  /// In zh_CN, this message translates to:
  /// **'已发送给 {count} 个联系人'**
  String contactPickerSent(int count);

  /// No description provided for @contactPickerNotConnected.
  ///
  /// In zh_CN, this message translates to:
  /// **'「{name}」未连接，无法发送'**
  String contactPickerNotConnected(String name);

  /// No description provided for @contactPickerSendFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送失败：{error}'**
  String contactPickerSendFailed(String error);

  /// No description provided for @contactPickerOnline.
  ///
  /// In zh_CN, this message translates to:
  /// **'在线'**
  String get contactPickerOnline;

  /// No description provided for @contactPickerOffline.
  ///
  /// In zh_CN, this message translates to:
  /// **'离线'**
  String get contactPickerOffline;

  /// No description provided for @articleShareToContact.
  ///
  /// In zh_CN, this message translates to:
  /// **'私信分享'**
  String get articleShareToContact;

  /// No description provided for @playerDanmakuList.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕列表'**
  String get playerDanmakuList;

  /// No description provided for @playerDanmakuListCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'弹幕列表 · 共 {count} 条'**
  String playerDanmakuListCount(int count);

  /// No description provided for @playerDanmakuListEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无弹幕'**
  String get playerDanmakuListEmpty;

  /// No description provided for @playerDanmakuListNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'无匹配的弹幕'**
  String get playerDanmakuListNoMatch;

  /// No description provided for @playerDanmakuListSearchHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索弹幕内容'**
  String get playerDanmakuListSearchHint;

  /// No description provided for @playerDanmakuListJumpCurrent.
  ///
  /// In zh_CN, this message translates to:
  /// **'定位到当前播放'**
  String get playerDanmakuListJumpCurrent;

  /// No description provided for @playerViewNotes.
  ///
  /// In zh_CN, this message translates to:
  /// **'查看笔记'**
  String get playerViewNotes;

  /// No description provided for @playerNotesTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'笔记'**
  String get playerNotesTitle;

  /// No description provided for @playerNotesCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'笔记（{count}）'**
  String playerNotesCount(int count);

  /// No description provided for @playerNotesEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'该视频暂无公开笔记'**
  String get playerNotesEmpty;

  /// No description provided for @playerNotesNoMore.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有更多了'**
  String get playerNotesNoMore;

  /// No description provided for @playerNotesLoadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'笔记加载失败'**
  String get playerNotesLoadFailed;

  /// No description provided for @playerNotesViewFull.
  ///
  /// In zh_CN, this message translates to:
  /// **'查看全部'**
  String get playerNotesViewFull;

  /// No description provided for @playerWriteNote.
  ///
  /// In zh_CN, this message translates to:
  /// **'写笔记'**
  String get playerWriteNote;

  /// No description provided for @noteEditorWrite.
  ///
  /// In zh_CN, this message translates to:
  /// **'写笔记'**
  String get noteEditorWrite;

  /// No description provided for @noteEditorTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'写笔记'**
  String get noteEditorTitle;

  /// No description provided for @noteEditorTitleHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'标题（选填）'**
  String get noteEditorTitleHint;

  /// No description provided for @noteEditorContentHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'开始记笔记…'**
  String get noteEditorContentHint;

  /// No description provided for @noteEditorEmoji.
  ///
  /// In zh_CN, this message translates to:
  /// **'表情'**
  String get noteEditorEmoji;

  /// No description provided for @noteEditorPublish.
  ///
  /// In zh_CN, this message translates to:
  /// **'发布'**
  String get noteEditorPublish;

  /// No description provided for @noteEditorEmptyContent.
  ///
  /// In zh_CN, this message translates to:
  /// **'笔记内容不能为空'**
  String get noteEditorEmptyContent;

  /// No description provided for @noteEditorContentTooShort.
  ///
  /// In zh_CN, this message translates to:
  /// **'内容至少 10 个字符才能发布'**
  String get noteEditorContentTooShort;

  /// No description provided for @noteEditorNotLoggedIn.
  ///
  /// In zh_CN, this message translates to:
  /// **'未登录：笔记已保存为本地草稿，登录后可发布'**
  String get noteEditorNotLoggedIn;

  /// No description provided for @noteEditorPublished.
  ///
  /// In zh_CN, this message translates to:
  /// **'笔记已发布'**
  String get noteEditorPublished;

  /// No description provided for @noteEditorPublishNetworkError.
  ///
  /// In zh_CN, this message translates to:
  /// **'发布失败（网络异常），草稿已保存'**
  String get noteEditorPublishNetworkError;

  /// No description provided for @noteEditorPublishRejected.
  ///
  /// In zh_CN, this message translates to:
  /// **'发布被服务端拒绝，草稿已保留'**
  String get noteEditorPublishRejected;

  /// No description provided for @noteEditorDraftSaved.
  ///
  /// In zh_CN, this message translates to:
  /// **'已自动保存草稿'**
  String get noteEditorDraftSaved;

  /// No description provided for @noteEditorLoggedInHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'已登录，可发布公开笔记'**
  String get noteEditorLoggedInHint;

  /// No description provided for @noteEditorGuestHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'未登录：仅保存本地草稿，不能发布'**
  String get noteEditorGuestHint;

  /// No description provided for @noteEditorSavedAt.
  ///
  /// In zh_CN, this message translates to:
  /// **'草稿已保存 {hour}:{minute}'**
  String noteEditorSavedAt(String hour, String minute);

  /// No description provided for @noteEditorCharCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 字'**
  String noteEditorCharCount(int count);

  /// No description provided for @noteEditorMyDraft.
  ///
  /// In zh_CN, this message translates to:
  /// **'我的草稿'**
  String get noteEditorMyDraft;

  /// No description provided for @noteEditorDeleteDraft.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除草稿'**
  String get noteEditorDeleteDraft;

  /// No description provided for @playerMoreTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'更多操作'**
  String get playerMoreTooltip;

  /// No description provided for @commentComposerBarHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'说点什么…'**
  String get commentComposerBarHint;

  /// No description provided for @commentComposerHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入评论内容…'**
  String get commentComposerHint;

  /// No description provided for @commentComposerReplyHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'回复 @{name}'**
  String commentComposerReplyHint(String name);

  /// No description provided for @commentComposerReplyTo.
  ///
  /// In zh_CN, this message translates to:
  /// **'回复 @{name}'**
  String commentComposerReplyTo(String name);

  /// No description provided for @commentComposerEmote.
  ///
  /// In zh_CN, this message translates to:
  /// **'表情'**
  String get commentComposerEmote;

  /// No description provided for @commentComposerSend.
  ///
  /// In zh_CN, this message translates to:
  /// **'发送'**
  String get commentComposerSend;

  /// No description provided for @commentComposerEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'评论内容不能为空'**
  String get commentComposerEmpty;

  /// No description provided for @commentComposerEmoteUnavailable.
  ///
  /// In zh_CN, this message translates to:
  /// **'表情面板不可用（可能未登录）'**
  String get commentComposerEmoteUnavailable;

  /// No description provided for @commentComposerPickImage.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择图片'**
  String get commentComposerPickImage;

  /// No description provided for @commentComposerMore.
  ///
  /// In zh_CN, this message translates to:
  /// **'更多'**
  String get commentComposerMore;

  /// No description provided for @commentComposerVideoProgress.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频进度'**
  String get commentComposerVideoProgress;

  /// No description provided for @commentComposerVideoScreenshot.
  ///
  /// In zh_CN, this message translates to:
  /// **'视频截图'**
  String get commentComposerVideoScreenshot;

  /// No description provided for @commentComposerImageLimit.
  ///
  /// In zh_CN, this message translates to:
  /// **'最多选择 {count} 张图片'**
  String commentComposerImageLimit(int count);

  /// No description provided for @commentComposerCaptureFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'截图失败，请先开始播放'**
  String get commentComposerCaptureFailed;

  /// No description provided for @commentComposerUploadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'图片上传失败，请重试'**
  String get commentComposerUploadFailed;

  /// No description provided for @commentComposerFabLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'发评论'**
  String get commentComposerFabLabel;

  /// No description provided for @commentComposerFabReply.
  ///
  /// In zh_CN, this message translates to:
  /// **'发回复'**
  String get commentComposerFabReply;

  /// No description provided for @danmakuSendTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'发弹幕'**
  String get danmakuSendTitle;

  /// No description provided for @danmakuSendModeLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'模式'**
  String get danmakuSendModeLabel;

  /// No description provided for @danmakuSendFontSizeLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'字号'**
  String get danmakuSendFontSizeLabel;

  /// No description provided for @danmakuSendColorLabel.
  ///
  /// In zh_CN, this message translates to:
  /// **'颜色'**
  String get danmakuSendColorLabel;

  /// No description provided for @danmakuFontSizeSmall.
  ///
  /// In zh_CN, this message translates to:
  /// **'小'**
  String get danmakuFontSizeSmall;

  /// No description provided for @danmakuFontSizeStandard.
  ///
  /// In zh_CN, this message translates to:
  /// **'标准'**
  String get danmakuFontSizeStandard;

  /// No description provided for @danmakuFontSizeLarge.
  ///
  /// In zh_CN, this message translates to:
  /// **'大'**
  String get danmakuFontSizeLarge;

  /// No description provided for @danmakuSendCustomColor.
  ///
  /// In zh_CN, this message translates to:
  /// **'自定义颜色'**
  String get danmakuSendCustomColor;

  /// No description provided for @danmakuSendColorOk.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定'**
  String get danmakuSendColorOk;

  /// No description provided for @danmakuSendPreviewPlaceholder.
  ///
  /// In zh_CN, this message translates to:
  /// **'发个友善的弹幕见证当下'**
  String get danmakuSendPreviewPlaceholder;

  /// No description provided for @drawerHistory.
  ///
  /// In zh_CN, this message translates to:
  /// **'历史记录'**
  String get drawerHistory;

  /// No description provided for @drawerWatchLater.
  ///
  /// In zh_CN, this message translates to:
  /// **'稍后再看'**
  String get drawerWatchLater;

  /// No description provided for @drawerMyCache.
  ///
  /// In zh_CN, this message translates to:
  /// **'我的缓存'**
  String get drawerMyCache;

  /// No description provided for @historyCenterTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'历史记录'**
  String get historyCenterTitle;

  /// No description provided for @historyTabWatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'观看历史'**
  String get historyTabWatch;

  /// No description provided for @historyTabPlay.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放进度'**
  String get historyTabPlay;

  /// No description provided for @historySearchHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索历史...'**
  String get historySearchHint;

  /// No description provided for @historyPauseHistory.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂停记录历史'**
  String get historyPauseHistory;

  /// No description provided for @historyResumeHistory.
  ///
  /// In zh_CN, this message translates to:
  /// **'恢复记录历史'**
  String get historyResumeHistory;

  /// No description provided for @historyPausedTip.
  ///
  /// In zh_CN, this message translates to:
  /// **'历史记录已暂停'**
  String get historyPausedTip;

  /// No description provided for @historyPausedTipAction.
  ///
  /// In zh_CN, this message translates to:
  /// **'点击恢复'**
  String get historyPausedTipAction;

  /// No description provided for @historyClearWatchHistory.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空观看历史'**
  String get historyClearWatchHistory;

  /// No description provided for @historyClearPlayHistory.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空播放记录'**
  String get historyClearPlayHistory;

  /// No description provided for @historyClearAllTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空历史'**
  String get historyClearAllTitle;

  /// No description provided for @historyClearAllConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定要清空全部{label}吗？此操作不可恢复。'**
  String historyClearAllConfirm(String label);

  /// No description provided for @historyNoWatchHistory.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无观看历史'**
  String get historyNoWatchHistory;

  /// No description provided for @historyNoPlayHistory.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无播放记录'**
  String get historyNoPlayHistory;

  /// No description provided for @historyDeleteSelected.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除选中'**
  String get historyDeleteSelected;

  /// No description provided for @historySelectedCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'已选 {count} 项'**
  String historySelectedCount(int count);

  /// No description provided for @historySearchNoResult.
  ///
  /// In zh_CN, this message translates to:
  /// **'无匹配结果'**
  String get historySearchNoResult;

  /// No description provided for @historyPauseOnSnack.
  ///
  /// In zh_CN, this message translates to:
  /// **'已暂停历史记录'**
  String get historyPauseOnSnack;

  /// No description provided for @historyResumeOnSnack.
  ///
  /// In zh_CN, this message translates to:
  /// **'已恢复历史记录'**
  String get historyResumeOnSnack;

  /// No description provided for @historyDeleteToast.
  ///
  /// In zh_CN, this message translates to:
  /// **'已删除 {count} 条记录'**
  String historyDeleteToast(int count);

  /// No description provided for @myCacheTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'我的缓存'**
  String get myCacheTitle;

  /// No description provided for @myCacheSearchHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索缓存视频...'**
  String get myCacheSearchHint;

  /// No description provided for @myCacheDownloading.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在缓存'**
  String get myCacheDownloading;

  /// No description provided for @myCacheCached.
  ///
  /// In zh_CN, this message translates to:
  /// **'已缓存'**
  String get myCacheCached;

  /// No description provided for @myCacheNoCache.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无缓存视频'**
  String get myCacheNoCache;

  /// No description provided for @myCacheGroupCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count}个视频'**
  String myCacheGroupCount(int count);

  /// No description provided for @myCacheDeleteGroup.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除整组'**
  String get myCacheDeleteGroup;

  /// No description provided for @myCacheUpdateDanmaku.
  ///
  /// In zh_CN, this message translates to:
  /// **'更新弹幕'**
  String get myCacheUpdateDanmaku;

  /// No description provided for @myCacheClearAllTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空全部缓存'**
  String get myCacheClearAllTitle;

  /// No description provided for @myCacheClearAllConfirm.
  ///
  /// In zh_CN, this message translates to:
  /// **'将删除全部已缓存视频（{count}个视频 · {size}），确定吗？'**
  String myCacheClearAllConfirm(int count, String size);

  /// No description provided for @cacheActionDownload.
  ///
  /// In zh_CN, this message translates to:
  /// **'缓存'**
  String get cacheActionDownload;

  /// No description provided for @cacheActionCached.
  ///
  /// In zh_CN, this message translates to:
  /// **'已缓存'**
  String get cacheActionCached;

  /// No description provided for @cacheActionCaching.
  ///
  /// In zh_CN, this message translates to:
  /// **'缓存中'**
  String get cacheActionCaching;

  /// No description provided for @cacheToastSuccess.
  ///
  /// In zh_CN, this message translates to:
  /// **'已加入缓存队列'**
  String get cacheToastSuccess;

  /// No description provided for @cacheToastCached.
  ///
  /// In zh_CN, this message translates to:
  /// **'该视频已缓存'**
  String get cacheToastCached;

  /// No description provided for @cacheToastFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'缓存失败：{error}'**
  String cacheToastFailed(String error);

  /// No description provided for @drawerRecommend.
  ///
  /// In zh_CN, this message translates to:
  /// **'推荐'**
  String get drawerRecommend;

  /// No description provided for @recommendSourceWeb.
  ///
  /// In zh_CN, this message translates to:
  /// **'Web端'**
  String get recommendSourceWeb;

  /// No description provided for @recommendSourceApp.
  ///
  /// In zh_CN, this message translates to:
  /// **'APP端'**
  String get recommendSourceApp;

  /// No description provided for @recommendEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无推荐内容'**
  String get recommendEmpty;

  /// No description provided for @recommendSwitchList.
  ///
  /// In zh_CN, this message translates to:
  /// **'切换为单列'**
  String get recommendSwitchList;

  /// No description provided for @recommendSwitchGrid.
  ///
  /// In zh_CN, this message translates to:
  /// **'切换为多列'**
  String get recommendSwitchGrid;

  /// No description provided for @sideBarExpand.
  ///
  /// In zh_CN, this message translates to:
  /// **'展开侧边栏'**
  String get sideBarExpand;

  /// No description provided for @sideBarCollapse.
  ///
  /// In zh_CN, this message translates to:
  /// **'收起侧边栏'**
  String get sideBarCollapse;

  /// No description provided for @sideBarMore.
  ///
  /// In zh_CN, this message translates to:
  /// **'更多'**
  String get sideBarMore;

  /// No description provided for @recommendTabHot.
  ///
  /// In zh_CN, this message translates to:
  /// **'热门'**
  String get recommendTabHot;

  /// No description provided for @recommendTabBangumi.
  ///
  /// In zh_CN, this message translates to:
  /// **'番剧'**
  String get recommendTabBangumi;

  /// No description provided for @recommendSourceTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'推荐数据来源'**
  String get recommendSourceTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'US':
            return AppLocalizationsEnUs();
        }
        break;
      }
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'HK':
            return AppLocalizationsZhHk();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
