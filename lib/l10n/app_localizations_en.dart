// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

                                        
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String metroDate(int month, int day) {
    return '$month/$day';
  }

  @override
  String get metroSunday => 'Sunday';

  @override
  String get metroMonday => 'Monday';

  @override
  String get metroTuesday => 'Tuesday';

  @override
  String get metroWednesday => 'Wednesday';

  @override
  String get metroThursday => 'Thursday';

  @override
  String get metroFriday => 'Friday';

  @override
  String get metroSaturday => 'Saturday';

  @override
  String get metroLogin => 'Log in';

  @override
  String get metroWelcome => 'Welcome';

  @override
  String get imageViewerNoFile => 'Image file not found';

  @override
  String get syncPassphraseEmpty => 'Sync passphrase cannot be empty';

  @override
  String get imageBytesRequired => 'Provide either imageUrl or imageBytes';

  @override
  String get webdavConnectSuccess => 'Connected!';

  @override
  String get webdavConfigSaved => 'Configuration saved';

  @override
  String get webdavConfigureFirst =>
      'Configure and test the WebDAV connection first';

  @override
  String get webdavSelectContactsFirst =>
      'Select the contacts to back up below first';

  @override
  String get webdavNoFiles => 'The selected contacts have no files to back up';

  @override
  String get webdavConfirmBackup => 'Confirm backup';

  @override
  String webdavBackupConfirm(int contacts, int files, String path) {
    return 'Back up $files files from $contacts contacts to the WebDAV server.\nRemote path: $path/chats/<nickname>/';
  }

  @override
  String get webdavStartBackup => 'Start backup';

  @override
  String get webdavBackingUpTitle => 'Backing up';

  @override
  String get webdavBackupDoneTitle => 'Backup done';

  @override
  String webdavTotalFiles(int count) {
    return 'Total: $count files';
  }

  @override
  String webdavSuccessCount(int count) {
    return 'Succeeded: $count';
  }

  @override
  String webdavFailCount(int count) {
    return 'Failed: $count';
  }

  @override
  String webdavMoreErrors(int count) {
    return '...$count more errors';
  }

  @override
  String get webdavBackupFab => 'Backup';

  @override
  String get webdavShowInfo => 'Show my info';

  @override
  String get webdavHideInfo => 'Hide my info';

  @override
  String get webdavScanToFill => 'Scan to fill the server URL';

  @override
  String get webdavScanFilled => 'Address filled from QR code';

  @override
  String get webdavServerConfig => 'Server configuration';

  @override
  String get webdavServerUrlLabel => 'Server URL';

  @override
  String get webdavUsernameLabel => 'Username';

  @override
  String get webdavPasswordLabel => 'Password';

  @override
  String get webdavRemotePathLabel => 'Remote backup path';

  @override
  String get webdavTesting => 'Testing...';

  @override
  String get webdavSaveAndTest => 'Save and test connection';

  @override
  String get webdavSaveOnly => 'Save only';

  @override
  String get webdavConnectVerified => 'Connection verified';

  @override
  String get webdavAutoBackup => 'Auto backup';

  @override
  String get webdavAutoBackupOnReceive => 'Auto back up received files';

  @override
  String get webdavAutoBackupSubtitle =>
      'Applies only to the selected contacts below';

  @override
  String get webdavMediaSync => 'Media sync';

  @override
  String get webdavSyncPlaylists => 'Sync playlists';

  @override
  String get webdavSyncDanmaku => 'Sync danmaku';

  @override
  String get webdavPassphraseEncrypted => 'Sync passphrase (AES-256 encrypted)';

  @override
  String get webdavPassphrasePlain =>
      'Sync passphrase (leave empty = plain upload)';

  @override
  String get webdavPassphraseHint =>
      'Playlists will be uploaded encrypted once a passphrase is set';

  @override
  String get webdavGeneratePassphrase => 'Generate random passphrase';

  @override
  String get webdavMediaSyncHint =>
      'Playlists (including backgrounds) and danmaku are stored in separate cloud directories (playlists/, danmaku/), so they won\'t mix with chat backups. Devices sharing the same remote path can merge with each other; playlists can also be synced manually or restored from the cloud on the playlist page.';

  @override
  String get webdavEncryptionOn =>
      'Encryption enabled: playlists are uploaded encrypted with AES-256-GCM (including embedded WebDAV auth), so the server cannot read the content. Other devices must use the same passphrase to decrypt.';

  @override
  String get webdavEncryptionOff =>
      'Not encrypted: playlists (including embedded WebDAV auth) are uploaded in plaintext. Anyone with server access can read them. Not recommended.';

  @override
  String get webdavBackupContacts => 'Backup contacts';

  @override
  String webdavSelectedContacts(int selected, int total) {
    return '$selected / $total contacts selected';
  }

  @override
  String get webdavSearchContacts => 'Search contacts or IP...';

  @override
  String get webdavDeselectAll => 'Deselect all';

  @override
  String webdavFileCount(int count) {
    return '$count files';
  }

  @override
  String get webdavNoContacts => 'No contacts';

  @override
  String get webdavNoMatch => 'No matches';

  @override
  String webdavContactSubtitle(String ip, int count) {
    return '$ip  ·  $count files';
  }

  @override
  String get webdavManage => 'Manage';

  @override
  String get webdavLastSync => 'Last sync';

  @override
  String get webdavLastError => 'Last error';

  @override
  String get webdavClearConfig => 'Clear WebDAV configuration';

  @override
  String get webdavClearConfigSubtitle =>
      'Delete all server info and credentials';

  @override
  String get webdavUserLabel => 'User';

  @override
  String webdavStatusActive(String name) {
    return '$name active';
  }

  @override
  String webdavStatusConfigured(String name) {
    return '$name configured';
  }

  @override
  String get webdavStatusNotConfigured => 'Not configured';

  @override
  String get webdavNotSynced => 'Not synced yet';

  @override
  String get webdavJustNow => 'Last sync: just now';

  @override
  String webdavMinutesAgo(int minutes) {
    return 'Last sync: $minutes minutes ago';
  }

  @override
  String webdavHoursAgo(int hours) {
    return 'Last sync: $hours hours ago';
  }

  @override
  String webdavSyncedDate(int month, int day, String time) {
    return 'Last sync: $month/$day $time';
  }

  @override
  String get webdavPassphraseGenerated =>
      'A sync passphrase was generated and copied to the clipboard. Enter the same passphrase on other devices';

  @override
  String get webdavConfirmClear => 'Confirm clearing';

  @override
  String get webdavClearConfirmText =>
      'This deletes all WebDAV configuration (server, credentials, selected contacts).\nAlready uploaded files are not affected.';

  @override
  String get profileEditProfile => 'Edit profile';

  @override
  String get profileAccountSection => 'Account';

  @override
  String get profileWebdavBackup => 'WebDAV backup';

  @override
  String profileWebdavLoggedIn(String username) {
    return '$username logged in';
  }

  @override
  String get profileNotLoggedIn => 'Not logged in';

  @override
  String get profileAvatarSection => 'Avatar';

  @override
  String get profileChangeAvatar => 'Change avatar';

  @override
  String get profileRemoveAvatar => 'Remove avatar';

  @override
  String get profilePickFromGallery => 'Pick an image from the gallery';

  @override
  String get profileRestoreDefaultAvatar => 'Restore default avatar';

  @override
  String get profileSetBackground => 'Set background';

  @override
  String get profileBgSubtitle => 'Choose a background image for the sidebar';

  @override
  String get profileRestoreDefault => 'Restore default';

  @override
  String get profileBgRemoveSubtitle =>
      'Remove the custom background and use the theme gradient';

  @override
  String get profileInfoSection => 'Profile info';

  @override
  String get profileNicknameLabel => 'Nickname';

  @override
  String get profileNotSet => 'Not set';

  @override
  String get profileBgTitle => 'Profile background';

  @override
  String get profileAvatarUpdated => 'Avatar updated';

  @override
  String profileAvatarFailed(String error) {
    return 'Failed to pick avatar: $error';
  }

  @override
  String get profileRemoveAvatarConfirm =>
      'Remove the current avatar? This cannot be undone.';

  @override
  String get profileAvatarRemoved => 'Avatar removed';

  @override
  String get profileSetNickname => 'Set nickname';

  @override
  String get profileNicknameHint => 'Enter nickname';

  @override
  String get profileNicknameEmpty => 'Nickname cannot be empty';

  @override
  String get profileNicknameUpdated => 'Nickname updated';

  @override
  String get colorDefaultGreen => 'Default green';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorRed => 'Red';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorAmber => 'Amber';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorLime => 'Lime';

  @override
  String get colorLightGreen => 'Light green';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorCyan => 'Cyan';

  @override
  String get colorTeal => 'Teal';

  @override
  String get colorLightBlue => 'Light blue';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorIndigo => 'Indigo';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorDeepPurple => 'Deep purple';

  @override
  String get colorBlueGrey => 'Blue grey';

  @override
  String get colorBrown => 'Brown';

  @override
  String get colorGrey => 'Grey';

  @override
  String get themeColorExtracted => 'Theme color extracted from image';

  @override
  String themeColorFailed(String error) {
    return 'Failed to pick color: $error';
  }

  @override
  String get themeImageOnly => 'Only image formats are supported';

  @override
  String get themeTitle => 'Theme';

  @override
  String themeColorCopied(String hex) {
    return 'Color code copied: $hex';
  }

  @override
  String get themeAppearance => 'Appearance';

  @override
  String get themeDarkBlackened => 'Dark mode (pure black)';

  @override
  String get themeOff => 'Off';

  @override
  String get themeEnabled => 'On';

  @override
  String get themeColorsSection => 'Colors';

  @override
  String get themePaletteStyle => 'Palette style';

  @override
  String get themeFollowSystem => 'Follow system colors';

  @override
  String get themePickColor => 'Pick a color';

  @override
  String get themeDropHint =>
      'Release to extract the theme color from the image';

  @override
  String get themeNewTheme => 'New theme';

  @override
  String themeSwitched(String name) {
    return 'Switched to the $name theme';
  }

  @override
  String get themeDeleteTitle => 'Delete theme';

  @override
  String themeDeleteConfirm(String name) {
    return 'Delete the custom theme \"$name\"?';
  }

  @override
  String themeDeleted(String name) {
    return '\"$name\" deleted';
  }

  @override
  String get themeCreateTitle => 'Create custom theme';

  @override
  String get themeNameLabel => 'Theme name';

  @override
  String get themeNameHint => 'Enter text';

  @override
  String get themeHexLabel => 'Hex / RGB';

  @override
  String get themeHexHint => 'e.g. #FF0000 or 255,0,0';

  @override
  String themeCreated(String name) {
    return 'Theme \"$name\" created and saved';
  }

  @override
  String get themeCopyColor => 'Copy color code';

  @override
  String get themePickFromImage => 'Pick color from image';

  @override
  String get searchBack => 'Back to settings';

  @override
  String get searchHint => 'Search settings…';

  @override
  String get searchPrompt => 'Type keywords to search settings';

  @override
  String get searchExamples => 'e.g. refresh rate / decode / UA / danmaku';

  @override
  String searchNoResults(String query) {
    return 'No settings found for \"$query\"';
  }

  @override
  String get searchThemeMode => 'Theme mode';

  @override
  String get searchPureBlack => 'Pure black dark mode';

  @override
  String get searchThemeColor => 'Theme colors';

  @override
  String get searchFontWeight => 'Font weight';

  @override
  String get searchDisplayScale => 'Display scale';

  @override
  String get searchDisplayMode => 'Display mode / refresh rate';

  @override
  String get searchStatusBar => 'Status bar';

  @override
  String get searchKeepWindowRatio => 'Keep window aspect ratio';

  @override
  String get searchLongPressSpeed => 'Hold to speed up';

  @override
  String get searchScreenshot => 'Screenshot';

  @override
  String get searchScreenshotDanmaku => 'Show danmaku in screenshots';

  @override
  String get searchPlayProgress => 'Playback progress';

  @override
  String get searchHwdec => 'Hardware decoding';

  @override
  String get searchVideoSync => 'Video sync';

  @override
  String get searchImmersiveLongPress => 'Immersive hold-to-speed';

  @override
  String get searchMpvLog => 'Log mpv output';

  @override
  String get searchMpvLogLevel => 'mpv log level';

  @override
  String get searchNetworkMode => 'Network mode';

  @override
  String get searchInsecureCert => 'Allow insecure certificates';

  @override
  String get searchChatIpv6 => 'Chat IPv6';

  @override
  String get searchConnectivityTest => 'Connectivity test';

  @override
  String get searchHostOverrides => 'Host overrides';

  @override
  String get searchDohQuery => 'DoH query';

  @override
  String get searchReferer => 'Referer header';

  @override
  String get searchUserAgent => 'User-Agent header';

  @override
  String get searchSystemSettings => 'System settings';

  @override
  String get searchUserSettings => 'User settings';

  @override
  String get settingsDisplaySub => 'Theme, fonts, layout';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsSystemSub => 'Language, storage, permissions';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsStorageSub => 'Image cache, danmaku cache';

  @override
  String get settingsNetwork => 'Network';

  @override
  String get settingsNetworkSub => 'Wi-Fi, proxy, sync';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSub => 'App language, Bilibili AI translation';

  @override
  String get ttsDownloadCancel => 'Cancel download';

  @override
  String get ttsDownloadDoneTitle => 'TTS model downloaded';

  @override
  String get ttsDownloadDoneBody =>
      'You can now use read-aloud in comments and articles. Downloads resume and keep running in the background.';

  @override
  String get ttsNoInstallTitle => 'Read aloud';

  @override
  String get ttsNoInstallHeading =>
      'TTS is not installed yet. What would you like to do?';

  @override
  String get ttsNoInstallDownload => 'Download TTS';

  @override
  String get ttsNoInstallDownloadSub => 'Pull the model from Hugging Face';

  @override
  String get ttsNoInstallLater => 'Never mind';

  @override
  String get ttsNoInstallLaterSub => 'Maybe later';

  @override
  String get ttsInstallPageTitle => 'Download the TTS model';

  @override
  String get ugcFilterWindowTitle => 'Find and Replace';

  @override
  String get ugcFilterResultPrefix => 'Results: ';

  @override
  String get ugcFilterDeleteMatchesPlain => 'Delete matches';

  @override
  String get ugcFilterTitle => 'Filter settings';

  @override
  String get ugcFilterSectionScopes => 'UGC keyword filters';

  @override
  String get ugcFilterScopeRecommend => 'Home feed';

  @override
  String get ugcFilterScopeRecommendSub => 'Hide videos whose title matches';

  @override
  String get ugcFilterScopeZone => 'Zones';

  @override
  String get ugcFilterScopeZoneSub =>
      'Applies to the app feed, popular and ranking only';

  @override
  String get ugcFilterScopeReply => 'Comments';

  @override
  String get ugcFilterScopeReplySub => 'Hide comments whose content matches';

  @override
  String get ugcFilterScopeDyn => 'Dynamics';

  @override
  String get ugcFilterScopeDynSub => 'Hide dynamics whose content matches';

  @override
  String get ugcFilterEmpty => 'No keywords yet; type above and tap Add';

  @override
  String get ugcFilterAddHint => 'Keyword or regex';

  @override
  String get ugcFilterAdd => 'Add';

  @override
  String get ugcFilterEdit => 'Edit keyword';

  @override
  String get ugcFilterDelete => 'Delete';

  @override
  String get ugcFilterClear => 'Clear all';

  @override
  String get ugcFilterDup => 'Already exists, skipped';

  @override
  String get ugcFilterInvalid => 'Not a valid regular expression';

  @override
  String get ugcFilterDeleted => 'Deleted';

  @override
  String get ugcFilterCleared => 'Cleared';

  @override
  String get ugcFilterNoResult => 'No match';

  @override
  String get ugcFilterMenuMore => 'More';

  @override
  String get ugcFilterMenuClipboard => 'Import from clipboard';

  @override
  String get ugcFilterMenuFile => 'Import from file';

  @override
  String get ugcFilterMenuExport => 'Export';

  @override
  String get ugcFilterMenuWebdav => 'Export to WebDAV';

  @override
  String get ugcFilterImportEmpty => 'Clipboard has no text';

  @override
  String get ugcFilterExportEmpty => 'Nothing to export';

  @override
  String get ugcFilterFindReplace => 'Find and replace';

  @override
  String get ugcFilterFind => 'Find';

  @override
  String get ugcFilterReplace => 'Replace';

  @override
  String get ugcFilterPrev => 'Previous';

  @override
  String get ugcFilterNext => 'Next';

  @override
  String get ugcFilterReplaceOne => 'Replace';

  @override
  String get ugcFilterReplaceAll => 'All';

  @override
  String get ugcFilterHistory => 'History';

  @override
  String get ugcFilterClearHistory => 'Clear find history';

  @override
  String get ugcFilterCaseSensitive => 'Case sensitive';

  @override
  String get ugcFilterWholeWord => 'Whole keyword must match';

  @override
  String get ugcFilterRegex => 'Regular expression';

  @override
  String get ugcFilterTip =>
      'Every keyword is a regular expression (case-insensitive). Cc = case sensitive, W = the whole keyword must match, .* = treat the find field as a regex. Import merges and dedupes (nothing is overwritten); export is plain text, one per line.';

  @override
  String ugcFilterRulesCount(int count) {
    return '$count rules';
  }

  @override
  String ugcFilterAdded(int count) {
    return 'Added $count';
  }

  @override
  String ugcFilterResultCount(int count) {
    return 'Results: $count';
  }

  @override
  String ugcFilterReplaced(int count) {
    return 'Replaced $count';
  }

  @override
  String ugcFilterDeletedMatches(int count) {
    return 'Delete matches ($count)';
  }

  @override
  String ugcFilterImported(int added, int skipped) {
    return 'Imported $added, skipped $skipped duplicates';
  }

  @override
  String ugcFilterImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String ugcFilterExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String ugcFilterWebdavOk(String name) {
    return 'Uploaded to WebDAV: $name';
  }

  @override
  String ugcFilterWebdavFail(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get prefLinkSection => 'Link handling';

  @override
  String get settingsRecommend => 'Recommend feed';

  @override
  String get settingsRecommendSub => 'Source, filters and refresh behaviour';

  @override
  String get rcmdSectionSource => 'Source';

  @override
  String get rcmdUseAppSource => 'Use app-side recommendations';

  @override
  String get rcmdUseAppSourceSub =>
      'Switch to the app feed when the web feed disappoints';

  @override
  String get rcmdSectionBehavior => 'Refresh and keep';

  @override
  String get rcmdKeepLastData => 'Keep previous feed on refresh';

  @override
  String get rcmdKeepLastDataSub => 'Pull to refresh keeps the previous items';

  @override
  String get rcmdSavedPositionTip => 'Show last-seen position tip';

  @override
  String get rcmdSavedPositionTipSub =>
      'Insert a tip where the previous items start';

  @override
  String get rcmdSavedPositionTipText => 'You stopped here';

  @override
  String get rcmdSectionFilter => 'Filters';

  @override
  String get rcmdNoFilter => 'No filter';

  @override
  String get rcmdMinLikeRatio => 'Like ratio';

  @override
  String get rcmdMinLikeRatioSub => 'Hide videos below this like ratio';

  @override
  String get rcmdMinDuration => 'Duration';

  @override
  String get rcmdMinDurationSub => 'Hide videos shorter than this';

  @override
  String get rcmdMinPlay => 'Views';

  @override
  String get rcmdMinPlaySub => 'Hide videos below this view count';

  @override
  String get rcmdBanWord => 'Title keyword filter';

  @override
  String get rcmdBanWordSub => 'Regular expression; matching titles are hidden';

  @override
  String get rcmdBanWordHint => 'Not set';

  @override
  String get rcmdBanZone => 'Zone keyword filter';

  @override
  String get rcmdBanZoneSub =>
      'Applies to the app feed, popular and ranking only';

  @override
  String get rcmdBanZoneHint => 'Not set';

  @override
  String get rcmdExemptFollowed => 'Exempt followed uploaders';

  @override
  String get rcmdExemptFollowedSub => 'Content from followed uploaders is kept';

  @override
  String get rcmdFilterRelated => 'Apply filters to related videos';

  @override
  String get rcmdFilterRelatedSub =>
      'Popular, search and other entries are unaffected';

  @override
  String get rcmdFilterHint =>
      'Filters apply on the next fetch. Keywords are regular expressions; leave empty to disable.';

  @override
  String get rcmdFilterSaved => 'Saved; applies on the next fetch';

  @override
  String get prefOpenSupportedLinks => 'Open supported links';

  @override
  String get prefOpenSupportedLinksSub =>
      'Set this app as the default handler for bilibili / memz2345.top links';

  @override
  String get linkSettingsUnavailable =>
      'Could not open system settings; look for the default-handler entry manually';

  @override
  String get appLangSection => 'App language';

  @override
  String get appLangFollowSystem => 'Follow system';

  @override
  String get biliLangSection => 'Target language';

  @override
  String get biliAiSection => 'AI Translation';

  @override
  String get biliAiTranslateEnable => 'Enable AI translation';

  @override
  String get biliAiTranslateOnDesc =>
      'Enabled: Bilibili requests carry translation headers';

  @override
  String get biliAiTranslateOffDesc =>
      'Disabled: content stays in the original language';

  @override
  String get langZhCn => '简体中文 (Simplified Chinese)';

  @override
  String get langZhHk => '繁體中文 (Traditional Chinese, HK)';

  @override
  String get langZhTw => '繁體中文 (Traditional Chinese, TW)';

  @override
  String get langEnUs => 'English';

  @override
  String get langJaJp => '日本語 (Japanese)';

  @override
  String get langKoKr => '한국어 (Korean)';

  @override
  String get settingsPlayer => 'Player';

  @override
  String get settingsPlayerSub => 'Status bar, speed, screenshots';

  @override
  String get settingsStartScreenSub => 'Start screen, Charm';

  @override
  String get settingsLogs => 'Logs';

  @override
  String get settingsLogsSub => 'Error logs, mpv logs';

  @override
  String get settingsAccounts => 'Accounts';

  @override
  String get settingsAccountsSub => 'Bilibili, WebDAV';

  @override
  String get settingsUser => 'User';

  @override
  String get settingsUserSub => 'Account, privacy, security';

  @override
  String get settingsAboutSub => 'Version, licenses';

  @override
  String get settingsLicenses => 'Open source licenses';

  @override
  String get settingsLicensesSub => 'Open source projects used by this app';

  @override
  String get settingsSearch => 'Search settings';

  @override
  String get openSidebar => 'Open sidebar';

  @override
  String get settingsPlaceholderEasterEgg =>
      'Hmm, why not ask the wonderful Frieren?';

  @override
  String storageClearTitle(String label) {
    return 'Clear $label';
  }

  @override
  String storageClearConfirm(String label) {
    return 'Clear $label? Images will be re-downloaded when viewed again.';
  }

  @override
  String get storageClear => 'Clear';

  @override
  String storageCleared(String label) {
    return '$label cleared';
  }

  @override
  String get refreshAction => 'Refresh';

  @override
  String get storageCacheSection => 'Cache';

  @override
  String get storageUsageBreakdown => 'Usage breakdown';

  @override
  String get storageUsageTotal => 'Total used';

  @override
  String get storageUsageEmpty => 'Nothing to count yet';

  @override
  String get storageDataCache => 'Data cache';

  @override
  String get storageAiDeps => 'AI components';

  @override
  String get storageImageCache => 'Image cache';

  @override
  String get storageCounting => 'Counting…';

  @override
  String storageFileCount(int count, String size) {
    return '$count files · $size';
  }

  @override
  String get storageDanmakuCache => 'Danmaku cache';

  @override
  String storageVideoCount(int count, String size) {
    return '$count videos · $size';
  }

  @override
  String get settingsAutoOfflineCache => 'Auto cache played videos';

  @override
  String get settingsAutoOfflineCacheHint =>
      'Videos you watch are saved locally (about a 2 GB cap, oldest evicted when full), and play from disk next time without re-downloading. Turn off to stop adding new caches.';

  @override
  String get storageVideoCache => 'Offline video cache';

  @override
  String get storageVideoCacheDesc =>
      'Media of played videos (auto-cached within the size cap, LRU evicted); plays from disk next time';

  @override
  String get storageMemoryCache => 'In-memory image cache';

  @override
  String get storageMemoryCacheDesc =>
      'Images decoded during this session; freed automatically on exit';

  @override
  String get storageClearing => 'Clearing…';

  @override
  String get storageClearAll => 'Clear all cache';

  @override
  String get storageCacheHint =>
      'The image cache is the app\'s private directory (image_cache); cleared comment images will be re-downloaded. The danmaku cache is used for offline danmaku.';

  @override
  String get storageClearAllTitle => 'Clear all cache';

  @override
  String get storageClearAllConfirm =>
      'This clears the image cache, danmaku cache and in-memory image cache. Images will be re-downloaded when viewed again.';

  @override
  String get storageAllCleared => 'All cache cleared';

  @override
  String get storageLocationSection => 'Storage locations';

  @override
  String get storageLocationAutoCache => 'Auto cache location';

  @override
  String get storageLocationAutoCacheDesc =>
      'Where playback cache, images, danmaku and articles are stored';

  @override
  String get storageLocationVideo => 'Video download location';

  @override
  String get storageLocationVideoDesc =>
      'Where videos you cache manually are saved';

  @override
  String get storageLocationModels => 'AI models location';

  @override
  String get storageLocationModelsDesc =>
      'AI narration models and the anti-occlusion dependency';

  @override
  String get storageLocationDefault => 'System default';

  @override
  String get storageLocationUnsupported => 'Not customizable on this platform';

  @override
  String get storageLocationChoose => 'Change';

  @override
  String get storageLocationPick => 'Choose folder';

  @override
  String get storageLocationNewFolder => 'New subfolder';

  @override
  String get storageLocationFolderName => 'Folder name';

  @override
  String get storageLocationCreateFailed =>
      'Could not create it, try another name';

  @override
  String get storageLocationReset => 'Reset to default';

  @override
  String get storageLocationResetDone => 'Reset to the default location';

  @override
  String storageLocationCurrent(String path) {
    return 'Current: $path';
  }

  @override
  String storageLocationSetDone(String path) {
    return 'Set to $path';
  }

  @override
  String storageLocationFree(String size) {
    return '$size available';
  }

  @override
  String get storageLocationNotWritable =>
      'Not writable, fell back to the default location';

  @override
  String get storageLocationAndroidHint =>
      'On Android you can only pick the system standard folders (Movies, Download, Documents, also on the SD card) or the app private folder, and create subfolders inside them';

  @override
  String get storageLocationKeepOld =>
      'Files in the old location are kept and still readable; new downloads go to the new one';

  @override
  String get ttsLiveDownloadTitle => 'AI narration model download';

  @override
  String get settingsAi => 'AI';

  @override
  String get settingsAiSub =>
      'Smart occlusion and AI narration: models, mirrors, inference device';

  @override
  String get bottomNavPreviewHint =>
      'The bar at the bottom is a live preview: on Android it is the native glass bar itself';

  @override
  String get bottomNavResetDone => 'Reset to default';

  @override
  String get verificationPendingRequests => 'Pending requests';

  @override
  String get verificationNoPending => 'No pending requests';

  @override
  String verificationIpAddress(String ip) {
    return 'IP address: $ip';
  }

  @override
  String verificationNickname(String name) {
    return 'Nickname: $name';
  }

  @override
  String verificationRequestTime(String time) {
    return 'Request time: $time';
  }

  @override
  String get verificationRejectInvalid => 'Cannot reject: invalid IP address';

  @override
  String get verificationRejected => 'Connection request rejected';

  @override
  String get verificationReject => 'Reject';

  @override
  String get verificationAcceptInvalid => 'Cannot accept: invalid IP address';

  @override
  String get verificationAccepted => 'Connection request accepted';

  @override
  String get verificationAccept => 'Accept';

  @override
  String get startScreenWarning => 'This project may no longer be updated';

  @override
  String get startScreenTitle => 'Start screen';

  @override
  String get startScreenGoBack => 'Navigate up';

  @override
  String get enableStartScreen => 'Enable start screen';

  @override
  String get startScreenEnableSubtitle =>
      'Allow opening the start screen from the Charm Start button';

  @override
  String get enableCharm => 'Enable Charm';

  @override
  String get charmEnableSubtitle =>
      'Show the Charm bar on the right edge of the screen';

  @override
  String get charmGestureTitle => 'Gesture to open Charm';

  @override
  String get charmGestureSubtitle =>
      'Swipe left from the right edge or hover the top-right corner to open Charm';

  @override
  String get externalVideo => 'External video';

  @override
  String get audioChannelName => 'Video media playback';

  @override
  String get foregroundChannelName => 'Navi keep-alive';

  @override
  String get foregroundChannelDesc => 'Keep me running in the background';

  @override
  String get foregroundTitle => 'Keeping alive';

  @override
  String get foregroundText => 'Verifying';

  @override
  String get drawerBilibiliSearch => 'Bilibili Search';

  @override
  String get recommendBottomHome => 'Home';

  @override
  String get recommendBottomLive => 'Live';

  @override
  String get commentImageLoadFail => 'Image failed to load';

  @override
  String get commentDetailTitle => 'Comment Details';

  @override
  String get commentLikeLoginRequired =>
      'Please log in to your Bilibili account (and enable sending cookies) before liking';

  @override
  String commentLikeFail(String error) {
    return 'Like failed: $error';
  }

  @override
  String get relatedEmpty => 'No related videos';

  @override
  String get biliLoadFailed => 'Failed to load';

  @override
  String countWan(String count) {
    return '${count}W';
  }

  @override
  String countYi(String count) {
    return '${count}M';
  }

  @override
  String get searchNoNewContent => 'No new content';

  @override
  String get searchNewContentRefreshed =>
      'Refreshed with a new batch of content';

  @override
  String get biliDialogNeedLogin => 'Login required';

  @override
  String get biliDialogInteractDesc =>
      'Likes, coins, triple-send and other interactions require logging in to a Bilibili account';

  @override
  String get biliGoLogin => 'Go to login';

  @override
  String get biliCookieScopeHint =>
      'Enable \"Carry Cookie\" and the \"Interactions\" scope in Account settings';

  @override
  String get videoTabRelated => 'Related';

  @override
  String get videoTabComments => 'Comments';

  @override
  String videoTabCommentsCount(int count) {
    return 'Comments $count';
  }

  @override
  String videoTabEpisodes(int count) {
    return 'Episodes $count';
  }

  @override
  String get videoTabIntro => 'Intro';

  @override
  String danmakuWatching(String count) {
    return '$count watching';
  }

  @override
  String danmakuLoadedBar(String count) {
    return '$count danmaku loaded';
  }

  @override
  String get danmakuToggleOn => 'Enable danmaku';

  @override
  String get danmakuDisable => 'Disable danmaku';

  @override
  String get danmakuInputHint => 'Post a friendly danmaku to mark this moment';

  @override
  String get danmakuToastEmpty => 'Danmaku text cannot be empty';

  @override
  String danmakuToastSendFail(String error) {
    return 'Failed to send: $error';
  }

  @override
  String get danmakuToastSent => 'Danmaku sent';

  @override
  String get videoLikeTooltip => 'Like (long-press for triple-send)';

  @override
  String get videoUnlikeTooltip => 'Unlike';

  @override
  String get videoCoinTooltip => 'Coin';

  @override
  String get videoFavTooltip => 'Favorite';

  @override
  String get videoUnfavTooltip => 'Unfavorite';

  @override
  String get videoShareLabel => 'Share';

  @override
  String videoStatRating(String count) {
    return '$count rated';
  }

  @override
  String videoStatFollowing(String count) {
    return '$count following';
  }

  @override
  String videoStatWatching(String count) {
    return '$count watching';
  }

  @override
  String get videoFollowLabel => 'Follow';

  @override
  String get videoFollowedLabel => 'Following';

  @override
  String get commentDetailEmpty => 'No replies yet';

  @override
  String commentDetailNoMore(int count) {
    return 'No more replies ($count total)';
  }

  @override
  String get commentDetailLoadMore => 'Scroll to load more';

  @override
  String get commentDetailRootBadge => 'OP';

  @override
  String get commentDetailDeleted => '(Comment deleted)';

  @override
  String get commentMenuCopy => 'Copy Comment';

  @override
  String get commentMenuSelectText => 'Select Text';

  @override
  String get commentDialogTitle => 'Comment Content';

  @override
  String get commentDialogEmpty => '(It\'s empty here)';

  @override
  String get danmakuInputBvPrompt => 'Please enter a BV ID';

  @override
  String get danmakuInputCidPrompt => 'Please enter a CID';

  @override
  String get danmakuInputCidNumeric => 'CID must contain only digits';

  @override
  String danmakuInputCacheHit(int count, String oid) {
    return 'Cache hit: $count danmaku loaded (oid=$oid)';
  }

  @override
  String danmakuInputFetchSuccess(int count, String oid) {
    return 'Loaded: $count danmaku (oid=$oid)';
  }

  @override
  String get danmakuInputFetchFail => 'Failed to fetch';

  @override
  String get danmakuInputTitle => 'Bilibili Danmaku';

  @override
  String get danmakuInputTypeLabel => 'Type: ';

  @override
  String get danmakuInputBvHint =>
      'Enter a BV ID to automatically fetch the CID of the first part';

  @override
  String get danmakuInputCidHint =>
      'Enter a numeric CID directly (e.g. obtained from an API)';

  @override
  String get danmakuInputFetching => 'Fetching...';

  @override
  String get danmakuInputFetchDanmaku => 'Fetch Danmaku';

  @override
  String get danmakuInputEmpty => 'Input cannot be empty';

  @override
  String get danmakuCidFetchFail =>
      'Unable to fetch CID, please check the BV ID';

  @override
  String danmakuNoData(String oid) {
    return 'No danmaku data found (oid=$oid)';
  }

  @override
  String get danmakuSettingsTitle => 'Danmaku Settings';

  @override
  String get danmakuDataSource => 'Data Source';

  @override
  String get danmakuDisplayControl => 'Display Control';

  @override
  String get danmakuEnable => 'Enable Danmaku';

  @override
  String get danmakuSmartMask => 'Smart Anti-Occlusion';

  @override
  String get danmakuSmartMaskDesc =>
      'Detects people so danmaku won\'t cover them';

  @override
  String get danmakuTypeFilter => 'Danmaku Type';

  @override
  String get danmakuTypeScroll => 'Scrolling Danmaku';

  @override
  String get danmakuTypeTop => 'Top Danmaku';

  @override
  String get danmakuTypeBottom => 'Bottom Danmaku';

  @override
  String get danmakuTypeAdvanced => 'Advanced Danmaku (BAS)';

  @override
  String get danmakuAdvancedSubtitle =>
      'Animated danmaku; enabling may affect performance';

  @override
  String get danmakuParameters => 'Parameters';

  @override
  String get danmakuScrollSpeed => 'Scroll Speed';

  @override
  String get danmakuOpacity => 'Opacity';

  @override
  String get danmakuFontSize => 'Font Size';

  @override
  String get danmakuMaxLines => 'Max Lines';

  @override
  String danmakuLinesCount(int count) {
    return '$count lines';
  }

  @override
  String get danmakuQuickActions => 'Quick Actions';

  @override
  String get danmakuResetParams => 'Reset Parameters';

  @override
  String get danmakuClearDanmaku => 'Clear Danmaku';

  @override
  String get danmakuLoadLocalXml => 'Load Local XML Danmaku';

  @override
  String get danmakuFetchOnline => 'Fetch Online Bilibili Danmaku';

  @override
  String get danmakuNotLoaded => 'No danmaku loaded yet';

  @override
  String danmakuLoadedCount(int count) {
    return '$count danmaku loaded';
  }

  @override
  String get danmakuBlockColorful => 'Colored danmaku';

  @override
  String get danmakuCloudFilter => 'Smart cloud filter';

  @override
  String get danmakuCloudFilterOff => 'Off';

  @override
  String danmakuCloudFilterLevel(int level) {
    return 'Level $level';
  }

  @override
  String get danmakuFontSizeFS => 'Fullscreen font size';

  @override
  String danmakuSeconds(int value) {
    return '${value}s';
  }

  @override
  String get danmakuOthers => 'Others';

  @override
  String get danmakuMassiveMode => 'Massive mode';

  @override
  String get danmakuStatic2Scroll => 'Static to scroll';

  @override
  String get danmakuShowArea => 'Show area';

  @override
  String get danmakuFontWeight => 'Font weight';

  @override
  String get danmakuStrokeWidth => 'Stroke width';

  @override
  String get danmakuScrollDuration => 'Scroll duration (s)';

  @override
  String get danmakuStaticDuration => 'Static duration (s)';

  @override
  String get danmakuLineHeight => 'Line height';

  @override
  String danmakuResetTo(String value) {
    return 'Reset to default: $value';
  }

  @override
  String get naviAddAction => 'Add';

  @override
  String playlistImportAdded(int count) {
    return 'Added $count files';
  }

  @override
  String get playlistAddEpisodeTitle => 'Add Episode';

  @override
  String get playlistTitleLabel => 'Title';

  @override
  String get playlistEpisodeHint => 'Episode 1';

  @override
  String get playlistVideoUrlLabel => 'Video URL';

  @override
  String get playlistAdd => 'Add';

  @override
  String get playlistNameRequired => 'Please enter a playlist name';

  @override
  String get playlistAtLeastOneVideo => 'Please add at least one video';

  @override
  String get playlistEditTitle => 'Edit Playlist';

  @override
  String get playlistCreateTitle => 'Create Playlist';

  @override
  String get playlistNameLabel => 'Playlist Name';

  @override
  String get playlistNameHint => 'My anime list';

  @override
  String get playlistWebdavMulti => 'WebDAV Multi-select';

  @override
  String playlistItemsCount(int count) {
    return '$count episodes';
  }

  @override
  String get playlistNoItems => 'No videos added yet';

  @override
  String get playlistImportHint => 'Tap the buttons above to import';

  @override
  String get playlistSaveChanges => 'Save Changes';

  @override
  String get playlistEpisodePanelTitle => 'Episodes';

  @override
  String playlistEpisodeCurrent(int index) {
    return 'Current: Episode $index';
  }

  @override
  String playlistSyncResult(String what, String message) {
    return '$what: $message';
  }

  @override
  String get playlistSyncTwoWay => 'Two-way Sync Playlists';

  @override
  String get playlistSyncTwoWaySubtitle =>
      'Download from cloud and merge, then upload the merged result (includes backgrounds)';

  @override
  String get playlistRestoreFromCloud => 'Restore from Cloud';

  @override
  String get playlistRestoreFromCloudSubtitle =>
      'Overwrite local playlists with cloud data (includes backgrounds)';

  @override
  String get playlistUploadToCloud => 'Upload to Cloud';

  @override
  String get playlistUploadToCloudSubtitle =>
      'Upload all local playlists (includes backgrounds, no merging)';

  @override
  String get playlistSyncDanmaku => 'Sync Danmaku Cache';

  @override
  String get playlistSyncDanmakuSubtitle =>
      'Merge with the cloud danmaku cache (keep the newer)';

  @override
  String playlistCreated(String name) {
    return 'Created: $name';
  }

  @override
  String get playlistDeleteTitle => 'Delete Playlist';

  @override
  String playlistDeleteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get playlistNewTooltip => 'New Playlist';

  @override
  String get playlistListTitle => 'Playlists';

  @override
  String get playlistCloudSync => 'Cloud Sync';

  @override
  String get playlistMyLists => 'My Lists';

  @override
  String get playlistNoLists => 'No playlists';

  @override
  String playlistListSummary(int count) {
    return '$count total · Tap a list to view all episodes';
  }

  @override
  String get playlistEmptyTitle => 'No playlists yet';

  @override
  String get playlistEmptyHint =>
      'Tap the \"Create\" button at the bottom right to create one';

  @override
  String get playlistResume => 'Resume';

  @override
  String get playlistEditAction => 'Edit';

  @override
  String playlistTileProgress(int total, int current) {
    return '$total episodes · Watched up to episode $current';
  }

  @override
  String get subtitleOff => 'Off';

  @override
  String subtitleTrackFallback(String id) {
    return 'Track $id';
  }

  @override
  String subtitleLoadedLocal(String name) {
    return 'Subtitle loaded: $name';
  }

  @override
  String get subtitleWebdavNotConfigured =>
      'WebDAV is not configured, please log in first';

  @override
  String get subtitleWebdavFolderEmpty => 'The WebDAV subtitle folder is empty';

  @override
  String get subtitleSelectFile => 'Select Subtitle File';

  @override
  String subtitleDownloadFailed(int code) {
    return 'Subtitle download failed: HTTP $code';
  }

  @override
  String subtitleLoadedRemote(String name) {
    return 'Remote subtitle loaded: $name';
  }

  @override
  String subtitleLoadError(String error) {
    return 'Subtitle load error: $error';
  }

  @override
  String get subtitlePanelTitle => 'Subtitles (CC)';

  @override
  String get subtitleLoadLocal => 'Load Local Subtitle';

  @override
  String get subtitleLoadWebdav => 'Load Subtitle from WebDAV';

  @override
  String get subtitleFontSize => 'Font Size';

  @override
  String get subtitleFontColor => 'Font Color';

  @override
  String get subtitleBgColor => 'Background Color';

  @override
  String get subtitleDragToggle => 'Subtitle drag (free position)';

  @override
  String get subtitleDragHint =>
      'When enabled, you can freely drag subtitles around the screen';

  @override
  String get subtitlePositionReset => 'Reset subtitle position';

  @override
  String get webdavInputPath => 'Enter Path';

  @override
  String get webdavGoTo => 'Go';

  @override
  String get webdavLoginRequired =>
      'Please log in to your WebDAV account first';

  @override
  String get webdavLoginSubtitle =>
      'Configure a server to browse remote videos';

  @override
  String get webdavLoginSubtitleMulti =>
      'After logging in, you can multi-select remote videos to create playlists';

  @override
  String get webdavRefresh => 'Refresh';

  @override
  String get webdavRoot => 'Root';

  @override
  String get webdavParent => 'Parent';

  @override
  String get webdavFolderEmpty => 'This folder is empty';

  @override
  String get webdavPullToRefresh => 'Try pulling down to refresh?';

  @override
  String get webdavSelectVideo => 'Please select a video file';

  @override
  String get webdavPlay => 'Play';

  @override
  String get webdavMultiSelectTitle => 'Multi-select Files';

  @override
  String get webdavNoSelection => 'No files selected';

  @override
  String webdavSelectedCount(int count) {
    return '$count videos selected';
  }

  @override
  String webdavSelectionOrder(String names) {
    return 'In selection order: $names';
  }

  @override
  String get webdavClear => 'Clear';

  @override
  String get webdavConfirmSelection => 'Confirm Selection';

  @override
  String get webdavGoLogin => 'Log In';

  @override
  String get profileTitle => 'Profile';

  @override
  String get settingsAvatarTitle => 'Avatar';

  @override
  String get settingsAvatarSet => 'Set';

  @override
  String get settingsNotSet => 'Not set';

  @override
  String get settingsAvatarChangeTooltip => 'Change avatar';

  @override
  String get settingsAvatarDeleteTooltip => 'Delete avatar';

  @override
  String get settingsAvatarUpdated => 'Avatar updated';

  @override
  String settingsPickAvatarFailed(String error) {
    return 'Failed to pick avatar: $error';
  }

  @override
  String get settingsAvatarDeleteTitle => 'Delete avatar';

  @override
  String get settingsAvatarDeleteConfirm =>
      'Are you sure you want to delete the current avatar?';

  @override
  String get settingsAvatarDeleteConfirmPermanent =>
      'Are you sure you want to delete the current avatar? This cannot be undone.';

  @override
  String get settingsAvatarDeleted => 'Avatar deleted';

  @override
  String get settingsNickname => 'Nickname';

  @override
  String get settingsNicknameEditTooltip => 'Edit nickname';

  @override
  String get settingsSetNickname => 'Set nickname';

  @override
  String get settingsNicknamePrompt => 'Please enter your nickname';

  @override
  String get settingsNicknameHint => 'Enter nickname';

  @override
  String get settingsNicknameEmpty => 'Nickname cannot be empty';

  @override
  String get settingsNicknameTooLong => 'Nickname cannot exceed 20 characters';

  @override
  String get settingsNicknameUpdated => 'Nickname updated';

  @override
  String get settingsLockWallpaper => 'Lock screen wallpaper';

  @override
  String get settingsWallpaperCustomSet => 'Custom wallpaper set';

  @override
  String get settingsWallpaperDefaultBg => 'Using default dark background';

  @override
  String get settingsWallpaperUpdated => 'Wallpaper updated';

  @override
  String get settingsWallpaperPickTooltip => 'Choose wallpaper';

  @override
  String get settingsWallpaperDelete => 'Delete wallpaper';

  @override
  String get settingsWallpaperDeleteConfirm =>
      'Delete the lock screen wallpaper and restore default?';

  @override
  String get settingsWallpaperDeleted => 'Wallpaper deleted';

  @override
  String get settingsDecoImage => 'Bottom-right decoration image';

  @override
  String get settingsDecoImageSet => 'Set (transparent PNG/WebP supported)';

  @override
  String get settingsDecoImageUpdated => 'Decoration image updated';

  @override
  String settingsPickImageFailed(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String get settingsPickImageTooltip => 'Choose image';

  @override
  String get settingsDecoImageDelete => 'Delete decoration image';

  @override
  String get settingsDecoImageDeleteConfirm =>
      'Delete the bottom-right decoration image?';

  @override
  String get settingsDecoImageDeleted => 'Decoration image deleted';

  @override
  String get settingsSize => 'Size';

  @override
  String settingsSizePxLabel(String size) {
    return '$size px';
  }

  @override
  String settingsSizePxValue(String size) {
    return '${size}px';
  }

  @override
  String get settingsOpacity => 'Opacity';

  @override
  String settingsOpacityPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsDisplay => 'Display';

  @override
  String get settingsDisplaySubtitle => 'Theme · Color · Text · Scale';

  @override
  String get settingsAppTheme => 'App theme';

  @override
  String settingsCurrentColor(String color) {
    return 'Current color: #$color';
  }

  @override
  String get settingsFontWeight => 'Font weight';

  @override
  String settingsCurrentFontWeight(int weight) {
    return 'Current weight: $weight';
  }

  @override
  String get settingsDisplayScale => 'Display scale';

  @override
  String settingsCurrentScale(int percent) {
    return 'Current scale: $percent%';
  }

  @override
  String get settingsRestrictIp => 'Restrict LAN IP connections';

  @override
  String get settingsRestrictIpSubtitle =>
      'Only allow Class A, B, and C LAN IP addresses';

  @override
  String get settingsDefaultPort => 'Default port';

  @override
  String get settingsAdjustFontWeight => 'Adjust font weight';

  @override
  String settingsFontWeightPreview(int weight) {
    return 'Preview: $weight';
  }

  @override
  String get settingsWeightHairline => 'Hairline';

  @override
  String get settingsWeightThin => 'Thin';

  @override
  String get settingsWeightRegular => 'Regular';

  @override
  String get settingsWeightMedium => 'Medium';

  @override
  String get settingsWeightBold => 'Bold';

  @override
  String get settingsWeightBlack => 'Black';

  @override
  String get settingsFontWeightUpdated => 'Font weight updated';

  @override
  String get logTitle => 'Logs';

  @override
  String get logBackTooltip => 'Navigate up';

  @override
  String get logRefresh => 'Refresh';

  @override
  String get logClearAll => 'Clear logs';

  @override
  String get logClearTitle => 'Clear logs';

  @override
  String get logClearConfirm =>
      'All log files under error/ and mpv/ will be deleted. Continue?';

  @override
  String get logClearAction => 'Clear';

  @override
  String logDeletedCount(int count) {
    return '$count log files deleted';
  }

  @override
  String get logCopyContent => 'Copy content';

  @override
  String get logShare => 'Share log';

  @override
  String get logDeleteThis => 'Delete this log';

  @override
  String get logEmptyContent => '(Empty log)';

  @override
  String logStorageLocation(String path) {
    return 'Storage location: $path';
  }

  @override
  String get logErrorSection => 'Error logs (written on crash)';

  @override
  String get logNoErrorLogs => 'No error logs';

  @override
  String get logMpvSection => 'mpv logs (optional)';

  @override
  String get logNoMpvLogs => 'No mpv logs';

  @override
  String get logReadingLogs => 'Reading logs…';

  @override
  String get lockFollowThemeColor => 'Follow theme color (time)';

  @override
  String get lockShowBattery => 'Show battery';

  @override
  String get lockShowNetwork => 'Show network';

  @override
  String lockDate(int month, int day) {
    return '$month/$day';
  }

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get myQrSelectIpHint => 'Tap to choose the IP used in the QR code';

  @override
  String get myQrNoIpType => 'No IP of this type';

  @override
  String get myQrInUse => 'In use';

  @override
  String get myQrSetAsQr => 'Set as QR';

  @override
  String get netLanDiscoveryPort => 'Local discovery port';

  @override
  String netDohNoRecord(String domain) {
    return 'No A record found for $domain';
  }

  @override
  String netDohQueryFailed(String error) {
    return 'Query failed: $error';
  }

  @override
  String netMappingSaved(String domain, String ip) {
    return 'Mapping saved: $domain → $ip';
  }

  @override
  String get netAddHostMapping => 'Add host mapping';

  @override
  String get netDomainLabel => 'Domain';

  @override
  String get netIpLabel => 'IP address';

  @override
  String get netAdd => 'Add';

  @override
  String netMappingAdded(String host, String ip) {
    return 'Mapping added: $host → $ip';
  }

  @override
  String netMappingRemoved(String host) {
    return 'Mapping removed: $host';
  }

  @override
  String get netTitle => 'Network';

  @override
  String get netBackTooltip => 'Navigate up';

  @override
  String get netRetestAll => 'Retest all';

  @override
  String get netConnectionModeSection => 'Connection mode';

  @override
  String get netNetworkMode => 'Network mode';

  @override
  String get netModeStandardLabel => 'Standard mode';

  @override
  String get netModeCompatLabel => 'Compatibility direct connect';

  @override
  String get netModeStandardDesc => 'Use the system default network stack';

  @override
  String get netAllowInsecureCert => 'Allow insecure certificates';

  @override
  String get netAllowInsecureCertDesc =>
      'Skip certificate verification in compatibility mode (IP direct connect)';

  @override
  String get netChatIpv6 => 'Chat IPv6';

  @override
  String get netChatIpv6On =>
      'Enabled: IPv6 chat, discovery and QR codes supported';

  @override
  String get netChatIpv6Off => 'Disabled: IPv4 only for chat';

  @override
  String get netChatIpv6EnabledSnack =>
      'Chat IPv6 enabled (takes effect after restart)';

  @override
  String get netChatIpv6DisabledSnack =>
      'Chat IPv6 disabled (takes effect after restart)';

  @override
  String get netLocalSendCompat => 'LocalSend compatibility';

  @override
  String get netLocalSendCompatOn =>
      'Enabled: LocalSend protocol (port 53317) for file transfer with LocalSend clients';

  @override
  String get netLocalSendCompatOff =>
      'Disabled: using the navi native protocol';

  @override
  String get netLocalSendCompatEnabledSnack =>
      'LocalSend compatibility enabled';

  @override
  String get netLocalSendCompatDisabledSnack =>
      'LocalSend compatibility disabled (native protocol restored)';

  @override
  String get lsSectionTitle => 'LocalSend devices';

  @override
  String get lsHintEnable => 'LocalSend compatibility is off';

  @override
  String get lsHintEnableDesc =>
      'Enable it to share files with LocalSend official clients (Android/iOS/Windows/macOS/Linux)';

  @override
  String get lsEnableNow => 'Enable';

  @override
  String get lsEnabledSnack => 'LocalSend compatibility enabled';

  @override
  String get lsNoDevices => 'No LocalSend devices found';

  @override
  String get lsHttpScan => 'HTTP scan';

  @override
  String get lsHttpScanning =>
      'Scanning local network (fallback when multicast fails)...';

  @override
  String get lsHttpScanDone => 'Scan finished';

  @override
  String get lsSendFile => 'Send files';

  @override
  String get lsSendFileDesc => 'Send to this device via the LocalSend protocol';

  @override
  String get lsProbe => 'Probe again';

  @override
  String get lsProbing => 'Probing...';

  @override
  String get lsProbeFound => 'Probe succeeded';

  @override
  String get lsProbeNotFound => 'Device did not respond';

  @override
  String lsPickFailed(String error) {
    return 'Failed to pick files: $error';
  }

  @override
  String get lsNoPath => 'File path unavailable';

  @override
  String lsSendingTitle(String alias) {
    return 'Sending to $alias';
  }

  @override
  String lsSendSuccess(int count) {
    return '$count files sent successfully';
  }

  @override
  String lsSendFailed(int count) {
    return '$count files sent successfully, others failed';
  }

  @override
  String get lsReceiveRequestTitle => 'Incoming file request';

  @override
  String lsReceiveRequestDesc(int count, String size) {
    return 'The peer wants to send $count files ($size in total)';
  }

  @override
  String get lsAccept => 'Accept';

  @override
  String get lsReject => 'Reject';

  @override
  String get lsOpenFile => 'Open file';

  @override
  String get lsReceiveCompleteTitle => 'File received';

  @override
  String lsReceiveCompleteDesc(String fileName, String path) {
    return '$fileName saved to:\n$path';
  }

  @override
  String lsFileReceived(String fileName) {
    return 'File received: $fileName';
  }

  @override
  String get netConnectivitySection => 'Connectivity test';

  @override
  String get netHostMappingSection => 'Host mapping';

  @override
  String get netMappingReset => 'Restored built-in default IP table';

  @override
  String get netRestoreDefaults => 'Restore defaults';

  @override
  String get netNoMappings => 'No mappings';

  @override
  String get netAddMapping => 'Add mapping';

  @override
  String get netDohQuerySection => 'DoH query';

  @override
  String get netDohQueryDesc =>
      'Query domain A records via the Cloudflare JSON DNS API; results can be saved as host mappings with one tap';

  @override
  String netDohResultDisplay(String domain, String ip) {
    return '$domain → $ip';
  }

  @override
  String get netSaveAsMapping => 'Save as mapping';

  @override
  String get netHeadersSection => 'Request headers';

  @override
  String get netRefererNotSet => 'Not set (e.g. https://www.bilibili.com/)';

  @override
  String get netNotSet => 'Not set';

  @override
  String netHeaderEditorTitle(String title) {
    return 'Set $title';
  }

  @override
  String netHeaderSaved(String title) {
    return '$title saved';
  }

  @override
  String get ossTitle => 'Open source licenses';

  @override
  String get ossBackTooltip => 'Navigate up';

  @override
  String get ossCopyFullText => 'Copy full text';

  @override
  String get ossLicenseCopied => 'License text copied to clipboard';

  @override
  String get playHistoryTitle => 'Play history';

  @override
  String get playHistoryBackTooltip => 'Navigate up';

  @override
  String get playHistoryClearAll => 'Clear all';

  @override
  String get playHistoryEmpty => 'Nothing here yet';

  @override
  String get playHistoryEmptySub => 'Hmm, it\'s quite quiet today';

  @override
  String get playHistoryClearTitle => 'Clear play history';

  @override
  String get playHistoryClearConfirm =>
      'Are you sure you want to delete all saved play progress? This cannot be undone.';

  @override
  String get playHistoryClearAction => 'Clear';

  @override
  String get playHistoryResume => 'Resume playback';

  @override
  String get playHistoryDeleteRecord => 'Delete record';

  @override
  String playHistoryDeleted(String title) {
    return 'Deleted play record for “$title”';
  }

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get playerArtistVideo => 'Video playback';

  @override
  String get playerArtistPlaylist => 'Playlist';

  @override
  String get playerArtistWebdav => 'WebDAV video';

  @override
  String get playerWebdavSubtitle => 'WebDAV subtitle';

  @override
  String playerResumeFrom(String position) {
    return 'Resumed from $position';
  }

  @override
  String playerNowPlaying(String title) {
    return 'Now playing: $title';
  }

  @override
  String playerDanmakuCache(int count) {
    return 'Danmaku cache ($count)';
  }

  @override
  String playerDanmakuBilibili(int count) {
    return 'Bilibili danmaku ($count)';
  }

  @override
  String get playerDanmakuNoData => 'No danmaku data parsed';

  @override
  String playerDanmakuLoaded(int count) {
    return '$count danmaku items loaded';
  }

  @override
  String playerDanmakuOnline(int count) {
    return 'Bilibili online danmaku ($count)';
  }

  @override
  String playerDanmakuLoadedFromCache(int count) {
    return 'Loaded $count danmaku items from local cache';
  }

  @override
  String playerDanmakuLoadedOnline(int count) {
    return 'Loaded $count online danmaku items';
  }

  @override
  String playerScreenshotFailed(String error) {
    return 'Screenshot failed: $error';
  }

  @override
  String get playerSavedToAlbum => 'Saved to album';

  @override
  String playerScreenshotSavedToAlbum(String fileName) {
    return 'Screenshot $fileName saved to album';
  }

  @override
  String playerSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String playerPipFailed(String error) {
    return 'Picture-in-picture failed: $error';
  }

  @override
  String get playerFitAdapt => 'Contain';

  @override
  String get playerFitStretch => 'Stretch';

  @override
  String get playerFitFill => 'Fill';

  @override
  String get playerEndPause => 'Pause when finished';

  @override
  String get playerEndLoop => 'Loop';

  @override
  String get playerEndExit => 'Exit when finished';

  @override
  String get playerSubtitleSettings => 'Subtitle settings';

  @override
  String get playerAdvancedSettings => 'Advanced settings';

  @override
  String get playerFlipHorizontal => 'Mirror horizontally';

  @override
  String get playerFlipHorizontalDesc => 'Flip the image horizontally';

  @override
  String get playerFlipVertical => 'Flip vertically';

  @override
  String get playerFlipVerticalDesc => 'Flip the image vertically';

  @override
  String get playerShowStats => 'Show video stats';

  @override
  String get playerShowStatsDesc => 'Codec / resolution / bitrate / frame rate';

  @override
  String get playerAutoPip => 'Auto picture-in-picture on home';

  @override
  String get playerLoadDanmakuOnResume => 'Load danmaku on resume';

  @override
  String get playerLoadDanmakuOnResumeDesc =>
      'Automatically read/fetch danmaku when resuming from play history';

  @override
  String get playerDefaultRate => 'Default playback speed';

  @override
  String get playerDefaultEndBehavior => 'Default end behavior';

  @override
  String get playerTimePickerTitle => 'Jump to time';

  @override
  String get playerTimeUnitHour => 'h';

  @override
  String get playerTimeUnitMinute => 'm';

  @override
  String get playerTimeUnitSecond => 's';

  @override
  String get playerBuffering => 'Buffering…';

  @override
  String get playerHwdecSoftware => 'Software decode (SW)';

  @override
  String playerHwdecHardware(String mode) {
    return 'Hardware decode ($mode)';
  }

  @override
  String get playerSourceLocal => 'Local file';

  @override
  String get playerStatResolution => 'Resolution';

  @override
  String get playerStatVideoCodec => 'Video codec';

  @override
  String get playerStatAudioCodec => 'Audio codec';

  @override
  String get playerStatBitrate => 'Bitrate';

  @override
  String get playerStatFps => 'Frame rate';

  @override
  String get playerStatDecode => 'Decode';

  @override
  String get playerStatSubtitle => 'Subtitle';

  @override
  String get playerOn => 'On';

  @override
  String get playerOff => 'Off';

  @override
  String get playerStatDanmaku => 'Danmaku';

  @override
  String get playerStatDownload => 'Download';

  @override
  String get playerStatSource => 'Source';

  @override
  String get playerStatPosition => 'Position';

  @override
  String get playerStatDuration => 'Duration';

  @override
  String get playerCopyLink => 'Copy video link';

  @override
  String playerCopyLinkAt(String time) {
    return 'Copy link at $time';
  }

  @override
  String get playerCopyLinkAt0 => 'Copy link at current position';

  @override
  String playerCopyLinkDone(String url) {
    return 'Copied: $url';
  }

  @override
  String get playerCopyLinkNotBili =>
      'Copying links is only supported for Bilibili videos';

  @override
  String get playerColorAdjust => 'Video color adjustment';

  @override
  String get playerColorBrightness => 'Brightness';

  @override
  String get playerColorContrast => 'Contrast';

  @override
  String get playerColorSaturation => 'Saturation';

  @override
  String get playerColorHue => 'Hue';

  @override
  String get playerColorGamma => 'Gamma';

  @override
  String get playerColorReset => 'Reset';

  @override
  String get playerColorUnavailable =>
      'Color adjustment is not supported by this player';

  @override
  String get playerStats => 'Statistics';

  @override
  String get playerAlignAspectRatio => 'Match aspect ratio';

  @override
  String get playerAlignAspectRatioDone => 'Window aligned to video ratio';

  @override
  String get playerAlignAspectRatioFailed => 'Couldn\'t get video size';

  @override
  String get commonClose => 'Close';

  @override
  String get playerPlaybackError => 'Playback error';

  @override
  String playerAllEpisodesPlayed(int count) {
    return 'All $count episodes played';
  }

  @override
  String playerFastForwarding(String rate) {
    return 'Playing at $rate speed';
  }

  @override
  String get playerTapToSave => 'Tap to save';

  @override
  String get playerResetScreen => 'Reset screen';

  @override
  String get playerBackTooltip => 'Navigate up';

  @override
  String get playerRotate90 => 'Rotate 90°';

  @override
  String get playerQuality => 'Quality';

  @override
  String get playerQualityLocked =>
      'This quality is unavailable (login or VIP required)';

  @override
  String get playerFullscreen => 'Fullscreen';

  @override
  String get playerBiliSubtitle => 'Bilibili subtitle';

  @override
  String get playerDecodeFormat => 'Decode format';

  @override
  String get playerDecodeFormatSwitchFailed => 'Failed to switch decode format';

  @override
  String get playerDecodeAuto => 'Auto';

  @override
  String get playerDecodeAutoShort => 'Auto';

  @override
  String get playerDecodeAvc => 'AVC / H.264';

  @override
  String get playerDecodeHevc => 'HEVC / H.265';

  @override
  String get playerDecodeAv1 => 'AV1';

  @override
  String get playerSubtitleLoadFailed => 'Failed to load subtitle';

  @override
  String get playerSubtitleBilingual => 'Bilingual subtitles';

  @override
  String playerSubtitleBilingualOn(String primary, String secondary) {
    return 'Bilingual subtitles: $primary / $secondary';
  }

  @override
  String get playerSubtitleBilingualUnavailable =>
      'This video only provides a single-language subtitle, bilingual mode unavailable';

  @override
  String get playerSubtitleSecondLang => 'Translation language';

  @override
  String get playerSubtitleDrag => 'Subtitle drag';

  @override
  String get playerSubtitleDragOn =>
      'Subtitle drag enabled: drag the screen to reposition';

  @override
  String get playerSubtitleDragOff => 'Subtitle drag disabled';

  @override
  String get playerSubtitleDragging => 'Dragging subtitle…';

  @override
  String get playerSubtitleDragHint => 'Drag subtitle on screen to reposition';

  @override
  String get playerSubtitlePositionSaved => 'Subtitle position saved';

  @override
  String get playerSubtitlePositionReset => 'Reset subtitle position';

  @override
  String get playerPortraitMode => 'Portrait mode';

  @override
  String get playerLandscapeMode => 'Landscape mode';

  @override
  String get playerDescription => 'Description';

  @override
  String get playerWebdavSource => 'WebDAV video source';

  @override
  String get playerCast => 'Cast';

  @override
  String get playerWatchTogether => 'Watch together';

  @override
  String get watchInviteTitle => 'invites you to watch together';

  @override
  String get watchWaitingAccept => 'Waiting for the other side to accept…';

  @override
  String get watchSelectPeer => 'Choose a friend to watch with';

  @override
  String get watchNoOnlinePeer => 'No online contacts';

  @override
  String watchInviteSent(String name) {
    return 'Watch-together invite sent to $name';
  }

  @override
  String watchActiveWith(String name) {
    return 'Watching together with $name';
  }

  @override
  String get watchPeerRejected => 'The other side rejected your invite';

  @override
  String get watchPeerNoAnswer => 'The other side didn\'t accept the invite';

  @override
  String get watchPeerLeft => 'The other side left watch together';

  @override
  String get watchTcpFailed => 'Couldn\'t connect. Watch together failed';

  @override
  String get watchConnectionDropped =>
      'Connection dropped. Watch together failed';

  @override
  String get watchUrlInvalid =>
      'Video URL unavailable. Can\'t start watch together';

  @override
  String get rcInviteTitle => 'requests remote control of your device';

  @override
  String get rcInviteHint =>
      'Once accepted, they can see your screen and control your device';

  @override
  String get rcPeerRejected =>
      'The other side rejected the remote control request';

  @override
  String get rcTcpFailed => 'Couldn\'t connect. Remote control failed';

  @override
  String get rcConnectionDropped => 'Connection dropped. Remote control failed';

  @override
  String get rcTimeout => 'Timed out waiting for the other side';

  @override
  String get rcShizukuNotInstalled =>
      'Shizuku is not installed on the target device';

  @override
  String get rcShizukuNotInstalledHint =>
      'The target device needs Shizuku running (shizuku.rikka.app)';

  @override
  String get rcShizukuGrantTitle => 'Shizuku authorization required';

  @override
  String get rcShizukuGrantHint =>
      'After granting Navi Shizuku permission on the target, they can control the screen remotely';

  @override
  String get rcShizukuGrant => 'Grant Shizuku';

  @override
  String get rcRequesting => 'Requesting…';

  @override
  String get rcShizukuNotGranted => 'Shizuku is not granted';

  @override
  String rcScreenCaptureFailed(String error) {
    return 'Screen capture failed: $error';
  }

  @override
  String get rcShareFailed => 'Screen share failed';

  @override
  String get rcRetry => 'Retry';

  @override
  String get rcClose => 'Close';

  @override
  String get rcCancel => 'Cancel';

  @override
  String get rcSend => 'Send';

  @override
  String get rcConnecting => 'Connecting…';

  @override
  String rcControlling(String name) {
    return 'Controlling $name remotely';
  }

  @override
  String rcBeingControlled(String name) {
    return '$name is controlling your device remotely';
  }

  @override
  String get rcEnd => 'End remote control';

  @override
  String get rcConnectionLost => 'Remote control connection lost';

  @override
  String get rcSessionEnded => 'Remote control ended';

  @override
  String get rcInputText => 'Input text';

  @override
  String get rcInputTextHint => 'Text to send to the target device';

  @override
  String get rcKeyBack => 'Back';

  @override
  String get rcKeyHome => 'Home';

  @override
  String get rcKeyRecents => 'Recents';

  @override
  String get rcKeyVolumeUp => 'Volume up';

  @override
  String get rcKeyVolumeDown => 'Volume down';

  @override
  String get dlnaPageTitle => 'Cast';

  @override
  String get dlnaRefresh => 'Rescan';

  @override
  String get dlnaSearching => 'Searching for DLNA devices on the LAN…';

  @override
  String get dlnaNoDevice => 'No cast device found';

  @override
  String get dlnaNoDeviceHint =>
      'Make sure your TV/box is on the same network and DLNA/casting is enabled';

  @override
  String get dlnaSearchAgain => 'Search again';

  @override
  String get dlnaFoundDevices => 'Devices found';

  @override
  String dlnaCastStarted(String device) {
    return 'Casting to $device';
  }

  @override
  String dlnaCastFailed(String device) {
    return 'Cast failed: $device';
  }

  @override
  String dlnaCastingTo(String device) {
    return 'Casting to $device';
  }

  @override
  String get dlnaStopCast => 'Stop casting';

  @override
  String get dlnaPlay => 'Play';

  @override
  String get dlnaPause => 'Pause';

  @override
  String get dlnaVolumeUp => 'Volume up';

  @override
  String get dlnaVolumeDown => 'Volume down';

  @override
  String get dlnaFileMissing => 'Video file not found';

  @override
  String dlnaServerStartFailed(String error) {
    return 'Failed to start local file server: $error';
  }

  @override
  String get playerEpisodeSelect => 'Episodes';

  @override
  String get playerDanmakuSettings => 'Danmaku settings';

  @override
  String get psTitle => 'Player';

  @override
  String get psBackTooltip => 'Navigate up';

  @override
  String get psStaffEntrance => 'Staff entrance';

  @override
  String get psDisplaySection => 'Display';

  @override
  String get psStatusBar => 'Status bar';

  @override
  String get psStatusBarDesc =>
      'Show time, battery and network icons at the top of the player';

  @override
  String get psKeepWindowRatio => 'Lock window aspect ratio';

  @override
  String get psKeepWindowRatioDesc =>
      'During playback the window can only be resized at the current aspect ratio';

  @override
  String get psKeepWindowRatioDesktopOnly =>
      'Only takes effect on Windows / macOS / Linux desktop';

  @override
  String get psInteractionSection => 'Interaction';

  @override
  String get psLongPressSpeed => 'Long-press speed boost';

  @override
  String get psLongPressSpeedDesc =>
      'Hold the screen or the D key on the keyboard to fast-forward at 2× speed';

  @override
  String get psScreenshot => 'Screenshot';

  @override
  String get psScreenshotDesc =>
      'Allow capturing the current frame in the player and saving it to the album';

  @override
  String get psScreenshotDanmaku => 'Include danmaku in screenshots';

  @override
  String get psScreenshotDanmakuDesc =>
      'Capture the current danmaku together with the screenshot';

  @override
  String get psProgressSection => 'Progress';

  @override
  String get psPlayProgress => 'Play progress';

  @override
  String get psNoHistory => 'No saved play records';

  @override
  String psHistoryCount(int count) {
    return 'You have $count records';
  }

  @override
  String get psMiscSection => 'Miscellaneous';

  @override
  String get psHwdec => 'Hardware decoding';

  @override
  String get psHwdecAuto => 'Automatically choose the best decoder';

  @override
  String get psHwdecSoftware => 'Force CPU software decoding';

  @override
  String get psHwdecAutoShort => 'Auto';

  @override
  String get psHwdecPureSoftware => 'Software only';

  @override
  String get psHwdecDisabledTag => 'Hard decoding off';

  @override
  String get hwdecPageTitle => 'Hardware decoding';

  @override
  String get hwdecEnabled => 'Enable hardware decoding';

  @override
  String get hwdecEnabledHint =>
      'Plays video with lower power consumption; disable if it crashes/freezes';

  @override
  String get hwdecOnlySupported =>
      'Show only options supported by this platform';

  @override
  String get hwdecOnlySupportedHint =>
      'Filter options by device platform (Windows / macOS / Linux / Android / iOS)';

  @override
  String get hwdecHint =>
      'Tap options to build an ordered mpv --hwdec fallback chain: preferred decoders first, later ones tried on failure, software decoding if all fail. Multiple selection and platform filtering are supported.';

  @override
  String hwdecSelectedPrefix(String n) {
    return '$n selected';
  }

  @override
  String get hwdecEmptyWarning =>
      'Keep at least one hardware decoding option (auto / auto-safe recommended as fallback)';

  @override
  String get psVideoSync => 'Video sync';

  @override
  String get psVsyncAudioDefault => 'Use audio clock as reference (default)';

  @override
  String get psVsyncResample =>
      'Resample audio to match the display refresh rate';

  @override
  String get psVsyncAdrop => 'Drop / duplicate audio frames to match display';

  @override
  String get psVsyncVdrop => 'Drop / duplicate video frames to match display';

  @override
  String get psVsyncAudio => 'Audio';

  @override
  String get psVsyncDisplayResample => 'Display resample';

  @override
  String get psVsyncDisplayAdrop => 'Display audio drop';

  @override
  String get psVsyncDisplayVdrop => 'Display video drop';

  @override
  String get psImmersiveLongPress => 'Long-press speed in immersive mode';

  @override
  String get psImmersiveLongPressDesc =>
      'Long-press still triggers 2× speed when the controls are hidden';

  @override
  String get psLogSection => 'Logs';

  @override
  String get psMpvLog => 'Record mpv logs';

  @override
  String psMpvLogEnabled(String level) {
    return 'Enabled, takes effect on next playback (level: $level)';
  }

  @override
  String get psMpvLogDisabled =>
      'Disabled. Crash logs are always recorded regardless of this switch';

  @override
  String get psMpvLogLevel => 'mpv log level';

  @override
  String get psMpvLogLevelDesc =>
      'Higher levels produce more detailed logs and use more space';

  @override
  String get psMpvLogError => 'Errors only';

  @override
  String get psMpvLogWarn => 'Warnings';

  @override
  String get psMpvLogWarnDefault => 'Warnings (default)';

  @override
  String get psMpvLogInfo => 'Info';

  @override
  String get psMpvLogVerbose => 'Verbose';

  @override
  String get psMpvLogDebug => 'Debug';

  @override
  String get psMpvLogTrace => 'All (very verbose)';

  @override
  String get psViewLogs => 'View logs';

  @override
  String get psViewLogsDesc =>
      'Browse error logs and mpv logs, with sharing and clearing';

  @override
  String testPlaylistCreated(String name) {
    return 'Created: $name';
  }

  @override
  String get testPageTitle => 'Test page';

  @override
  String get testVideoSourceSection => 'Video source';

  @override
  String get testVideoSourceSubtitle => 'Choose a source to start playing';

  @override
  String get testWebdavVideo => 'WebDAV video';

  @override
  String get testWebdavVideoDesc => 'Browse and play from a WebDAV server';

  @override
  String get testLocalVideo => 'Local video';

  @override
  String get testLocalVideoDesc => 'Choose a video file from device storage';

  @override
  String get testRecentSection => 'Recently played';

  @override
  String get testLastPlayedSubtitle => 'Last played record';

  @override
  String get testNoRecords => 'No play records yet';

  @override
  String get testPlaylistSection => 'Playlists';

  @override
  String get testPlaylistSectionSubtitle =>
      'Create and manage playlists, play by episodes';

  @override
  String get testPlaylistManage => 'Manage playlists';

  @override
  String get testPlaylistManageDesc =>
      'View / edit / delete playlists, tap to play directly';

  @override
  String get testPlaylistCreate => 'New playlist';

  @override
  String get testPlaylistCreateDesc =>
      'Build a playlist from multiple WebDAV files / import episodes manually';

  @override
  String get testQuickActionsSection => 'Quick actions';

  @override
  String get testQuickActionsSubtitle => 'Common test entries';

  @override
  String get testUrlDirectPlay => 'Play URL directly';

  @override
  String get testUrlDirectPlayDesc => 'Enter a video URL to play directly';

  @override
  String get testVideoWithSubtitle => 'Video + subtitles';

  @override
  String get testVideoWithSubtitleDesc =>
      'Select a video and a subtitle file together';

  @override
  String get testNoVideoPlayed => 'No video has been played yet';

  @override
  String get testEnterUrlTitle => 'Enter video URL';

  @override
  String get testPlay => 'Play';

  @override
  String get testAddSubtitleTitle => 'Add subtitles?';

  @override
  String testAddSubtitlePrompt(String name) {
    return 'Video selected: $name\nLoad external subtitles?';
  }

  @override
  String get testSkip => 'Skip';

  @override
  String get testSelectSubtitle => 'Choose subtitles';

  @override
  String get testAboutLegalese => 'Player frontend test page';

  @override
  String get testAboutBody =>
      'This page tests the various entry points of MpvPlayerPage:\n• WebDAV remote video\n• Local video files\n• Direct URL playback\n• Video + external subtitles';

  @override
  String get testSourceLocal => 'Local file';

  @override
  String get testSourceLocalSubtitle => 'Local + subtitles';

  @override
  String get accountsBiliLoginSuccess => 'Bilibili login successful';

  @override
  String get accountsBiliLogoutTitle => 'Log out of Bilibili?';

  @override
  String get accountsBiliLogoutHint =>
      'After logging out, the Bilibili API will no longer be called with your Cookie.';

  @override
  String get accountsClearWebviewCookieTitle =>
      'Also clear in-app browser cookies';

  @override
  String get accountsClearWebviewCookieSubtitle =>
      'Leaving it unchecked is fine. You can still clear them later in account settings.';

  @override
  String get accountsLogout => 'Log out';

  @override
  String get accountsLoggedOutWithCookie =>
      'Logged out and cleared browser cookies';

  @override
  String get accountsLoggedOut => 'Logged out';

  @override
  String get accountsClearCookieTitle => 'Clear in-app browser cookies?';

  @override
  String get accountsClearCookieContent =>
      'This will clear all cookies stored by the in-app browser, including web logins.';

  @override
  String get accountsClearAction => 'Clear';

  @override
  String get accountsCookieCleared => 'In-app browser cookies cleared';

  @override
  String get accountsCookieEmpty =>
      'No in-app browser cookies to clear (browser has not been used)';

  @override
  String get accountsBiliLoginTitle => 'Log in to Bilibili account';

  @override
  String get accountsBiliLoginSubtitle => 'QR code / Paste Cookie / Password';

  @override
  String get accountsClearBrowserCookie => 'Clear in-app browser cookies';

  @override
  String get accountsClearBrowserCookieSubtitle => 'Clear leftover web logins';

  @override
  String get accountsLoggedIn => 'Logged in';

  @override
  String accountsLoggedInUid(int mid) {
    return 'Logged in · UID $mid';
  }

  @override
  String get accountsCarryCookie => 'Send requests with Cookie';

  @override
  String get accountsCarryCookieOn =>
      'On: Bilibili API requests use your login identity';

  @override
  String get accountsCarryCookieOff =>
      'Off: Bilibili API requests use guest identity';

  @override
  String get accountsCookieScope => 'Cookie usage scope';

  @override
  String get accountsCookieScopeSubtitle =>
      'Choose which requests use your account Cookie';

  @override
  String get cookieScopeTitle => 'Cookie Usage Scope';

  @override
  String get cookieScopeHint =>
      'Only affects the request types below. When \"Send requests with Cookie\" is off, these settings have no effect. Bilibili online-favorites operations always send your login Cookie.';

  @override
  String get cookieScopeVideo => 'Video details & playback';

  @override
  String get cookieScopeVideoDesc =>
      'Video info, play URLs and watch-progress reporting';

  @override
  String get cookieScopeComments => 'Comments';

  @override
  String get cookieScopeCommentsDesc => 'Comment section requests';

  @override
  String get cookieScopeSearch => 'Search';

  @override
  String get cookieScopeSearchDesc => 'Search suggestions and result requests';

  @override
  String get cookieScopeArticle => 'Articles & moments';

  @override
  String get cookieScopeArticleDesc => 'Article and dynamic-feed requests';

  @override
  String get cookieScopeUserSpace => 'User space';

  @override
  String get cookieScopeUserSpaceDesc =>
      'Creator space, videos and follower-list requests';

  @override
  String get cookieScopeSeason => 'Seasons & episodes';

  @override
  String get cookieScopeSeasonDesc =>
      'Season details and episode-list requests';

  @override
  String get cookieScopeInteractions => 'Interactions';

  @override
  String get cookieScopeInteractionsDesc =>
      'Like, coin, favorite, follow and danmaku sending; disabled when off';

  @override
  String get cookieScopeEnableAll => 'Enable all';

  @override
  String get cookieScopeDisableAll => 'Disable all';

  @override
  String get accountsWebdavCloud => 'WebDAV Cloud Drive';

  @override
  String get accountsWebdavConfiguredOn => 'Configured · Auto backup on';

  @override
  String get accountsWebdavConfiguredOff => 'Configured · Auto backup off';

  @override
  String get accountsWebdavNotConfigured =>
      'Not configured · Tap to open settings';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get accountsSectionBili => 'Bilibili Account';

  @override
  String get commonBackTooltip => 'Navigate up';

  @override
  String get biliLoginFetchingQr => 'Fetching QR code…';

  @override
  String get biliLoginQrFetchFailed =>
      'Failed to fetch QR code, please check your network';

  @override
  String get biliLoginScanWithApp =>
      'Scan the QR code with the Bilibili app to log in';

  @override
  String get biliLoginInputAccountPwd =>
      'Please enter your account and password';

  @override
  String get biliLoginFailedRetry => 'Login failed, please try again';

  @override
  String get biliLoginTitle => 'Bilibili Login';

  @override
  String get biliLoginScanMode => 'QR Code Login';

  @override
  String get biliLoginCookieMode => 'Paste Cookie';

  @override
  String get biliLoginPwdMode => 'Password Login';

  @override
  String get biliLoginViaBrowser => 'Log in with in-app browser';

  @override
  String get biliLoginCookieHint =>
      '\"Send requests with Cookie\" is on by default after login. You can turn it off in Settings → Accounts.';

  @override
  String get biliLoginWebTitle => 'Web Login';

  @override
  String get biliLoginCookieImportFailed =>
      'Failed to import the Cookie from web login. Please retry or use another method.';

  @override
  String get biliLoginRefetch => 'Fetch again';

  @override
  String get biliLoginRefreshQr => 'Refresh QR code';

  @override
  String get biliLoginScanTip =>
      'Tip: open the Bilibili app → Scan, or scan with the Bilibili mini program';

  @override
  String get biliLoginCookieInstruction =>
      'Log in to bilibili.com in a desktop browser, press F12 to open DevTools → Application → Cookies → bilibili.com, copy all cookies (the string starting with SESSDATA=), and paste them into the field below';

  @override
  String get biliLoginVerifying => 'Verifying…';

  @override
  String get biliLoginVerifyAndLogin => 'Log in and verify';

  @override
  String get biliLoginAccountLabel => 'Account (phone / email / username)';

  @override
  String get biliLoginPasswordLabel => 'Password';

  @override
  String get biliLoginLoggingIn => 'Logging in…';

  @override
  String get biliLoginLoginAction => 'Log in';

  @override
  String get biliLoginSliderHint =>
      'Password login may trigger a slider captcha. It will automatically retry after verification.';

  @override
  String get searchFilterAny => 'Any';

  @override
  String get searchFilterLastDay => 'Last day';

  @override
  String get searchFilterLastWeek => 'Last week';

  @override
  String get searchFilterHalfYear => 'Last 6 months';

  @override
  String get searchFilterAllDuration => 'All durations';

  @override
  String get searchFilterDur0to10 => '0-10 min';

  @override
  String get searchFilterDur10to30 => '10-30 min';

  @override
  String get searchFilterDur30to60 => '30-60 min';

  @override
  String get searchFilterDur60plus => '60+ min';

  @override
  String get searchZoneAll => 'All';

  @override
  String get searchZoneAnime => 'Animation';

  @override
  String get searchZoneGuochuang => 'Domestic Creation';

  @override
  String get searchZoneMusic => 'Music';

  @override
  String get searchZoneDance => 'Dance';

  @override
  String get searchZoneGame => 'Games';

  @override
  String get searchZoneKnowledge => 'Knowledge';

  @override
  String get searchZoneTech => 'Tech';

  @override
  String get searchZoneSports => 'Sports';

  @override
  String get searchZoneCar => 'Auto';

  @override
  String get searchZoneLife => 'Life';

  @override
  String get searchZoneFood => 'Food';

  @override
  String get searchZoneAnimal => 'Animals';

  @override
  String get searchZoneKichiku => 'Kichiku';

  @override
  String get searchZoneFashion => 'Fashion';

  @override
  String get searchZoneInfo => 'News';

  @override
  String get searchZoneEnt => 'Entertainment';

  @override
  String get searchZoneDoc => 'Documentary';

  @override
  String get searchZoneFilm => 'Movies';

  @override
  String get searchZoneTv => 'TV';

  @override
  String get searchCaptchaInitFailed => 'Captcha initialization failed';

  @override
  String get searchCaptchaIncomplete => 'Slider verification not completed';

  @override
  String get searchCaptchaValidateFailed => 'Captcha verification failed';

  @override
  String get searchCaptchaValidateFailedRetry =>
      'Captcha verification failed, please retry';

  @override
  String get searchCaptchaPassed => 'Verification passed, searching again';

  @override
  String get searchBiliHint => 'Search Bilibili…';

  @override
  String get searchHistoryTitle => 'Search history';

  @override
  String get searchHistoryClear => 'Clear';

  @override
  String get searchHistoryClearConfirm =>
      'Clear search history for this section?';

  @override
  String get searchHistoryEmpty => 'No search history';

  @override
  String get drawerSearch => 'Search';

  @override
  String get drawerDynamics => 'Dynamics';

  @override
  String get drawerMessages => 'Messages';

  @override
  String get drawerMine => 'Me';

  @override
  String get biliAccountNotLoggedIn => 'Not logged in';

  @override
  String get bottomNavMoveUp => 'Move up';

  @override
  String get bottomNavMoveDown => 'Move down';

  @override
  String get bottomNavSettingsTitle => 'Bottom navigation';

  @override
  String get bottomNavSettingsSubtitle =>
      'Drag to reorder (the first item opens on launch), uncheck to hide';

  @override
  String get bottomNavItemHome => 'Home';

  @override
  String get bottomNavItemDynamics => 'Dynamics';

  @override
  String get bottomNavItemLive => 'Live';

  @override
  String get bottomNavSettingsReset => 'Reset';

  @override
  String get bottomNavSettingsKeepOne => 'Keep at least one item';

  @override
  String get prefSearchSection => 'Search';

  @override
  String get prefSearchTrending => 'Trending searches';

  @override
  String get prefSearchTrendingSub =>
      'Show trending keywords and the full list entry on the search page';

  @override
  String get prefSearchDiscovery => 'Search discovery';

  @override
  String get prefSearchDiscoverySub =>
      'Show recommended keywords on the search page';

  @override
  String get searchTrendingTitle => 'Trending now';

  @override
  String get searchTrendingFullList => 'Full list';

  @override
  String get searchDiscoveryTitle => 'Discover';

  @override
  String get hotSearchTitle => 'bilibili Trending';

  @override
  String get searchDiscoveryFailed => 'Failed to load';

  @override
  String get searchDiscoveryEmpty => 'Nothing here';

  @override
  String get searchVideoFilter => 'Video search filters';

  @override
  String searchFilterWithCount(int count) {
    return 'Filters · $count';
  }

  @override
  String get searchFilter => 'Filters';

  @override
  String get searchSwitchSingleCol => 'Single column';

  @override
  String get searchSwitchMulti => 'Multi-column';

  @override
  String get searchLayoutMulti => 'Multi-column';

  @override
  String get searchLayoutSingle => 'Single column';

  @override
  String get searchPickStartDate => 'Select start date';

  @override
  String get searchPickEndDate => 'Select end date';

  @override
  String get searchPubTimeSection => 'Published';

  @override
  String get searchDateBegin => 'Start';

  @override
  String get searchDateTo => 'to';

  @override
  String get searchDateEnd => 'End';

  @override
  String get searchDurationSection => 'Duration';

  @override
  String get searchZoneSection => 'Partition';

  @override
  String get searchAntiFuzzy => 'Anti-fuzzy search';

  @override
  String get searchAntiFuzzyHint =>
      'Limit results from 2009-06-26 to now, avoiding abnormal early data';

  @override
  String get searchFilterReset => 'Reset';

  @override
  String get searchAllLoaded => '— All loaded —';

  @override
  String get searchKeywordHint => 'Enter a keyword to search Bilibili';

  @override
  String get searchPressToSearch =>
      'Tap \"Search\" or press Enter to start searching';

  @override
  String searchNoResultInType(String keyword, String type) {
    return 'No results for \"$keyword\" in $type';
  }

  @override
  String searchResultsCount(String type, String count) {
    return '$type · $count results';
  }

  @override
  String get userSpaceLoadFailed => 'Failed to load';

  @override
  String get userSpaceAvatarLoadFailed => 'Failed to load avatar';

  @override
  String get userSpaceTitle => 'Creator Space';

  @override
  String get userSpaceLoading => 'Loading creator space…';

  @override
  String get userSpaceLoadingName => 'Loading…';

  @override
  String get userSpaceStatFans => 'Followers';

  @override
  String get userSpaceStatFollowing => 'Following';

  @override
  String get userSpaceStatVideos => 'Videos';

  @override
  String get userSpaceStatLikes => 'Likes';

  @override
  String userSpaceVideoCount(int count) {
    return '$count videos';
  }

  @override
  String get userSpaceSectionAllVideos => 'All Videos';

  @override
  String get userSpaceNoVideos => 'No posts yet';

  @override
  String get userSpaceDynLoadFailed => 'Failed to load posts';

  @override
  String get userSpaceNoDynamics => 'No posts yet';

  @override
  String get userSpaceBangumiLoadFailed => 'Failed to load bangumi list';

  @override
  String get userSpaceNoBangumi => 'No bangumi';

  @override
  String userSpaceBangumiCount(int count) {
    return 'Bangumi · $count titles';
  }

  @override
  String get userSpaceLazySign =>
      'This user is too lazy to leave anything here';

  @override
  String get userSpaceTabHome => 'Home';

  @override
  String get userSpaceTabDynamic => 'Posts';

  @override
  String get userSpaceTabBangumi => 'Bangumi';

  @override
  String get userSpaceToday => 'Today';

  @override
  String get userSpaceBangumiFinished => 'Finished';

  @override
  String get userSpaceBangumiSerializing => 'Ongoing';

  @override
  String userSpaceBangumiAiringDate(String date) {
    return 'Airing $date';
  }

  @override
  String get browserApp => 'app';

  @override
  String browserOpenAppAttempt(String app) {
    return 'The page tried to open: $app';
  }

  @override
  String get browserNoAppForLink => 'No app found to open this link';

  @override
  String get browserOpenFailedSystem =>
      'Failed to open: no matching app installed or blocked by the system';

  @override
  String get browserEmptyCookieHint => 'It\'s empty here';

  @override
  String get browserCopyAll => 'Copy all';

  @override
  String get browserCookieCopied => 'Cookie copied';

  @override
  String get browserCookieEmpty => 'No cookies found';

  @override
  String get browserSetUaTitle => 'Set User-Agent';

  @override
  String get browserUaHint => 'Enter a custom User-Agent';

  @override
  String get browserApplyAndReload => 'Apply and reload';

  @override
  String get browserUaUpdated => 'UA updated and page reloaded';

  @override
  String browserUaSetFailed(String error) {
    return 'Failed to set UA: $error';
  }

  @override
  String get browserWindowsInitFailed =>
      'Windows WebView initialization failed. Please check that WebView2 is installed.';

  @override
  String get browserBiliCookieReadFailed =>
      'Could not read the full login Cookie (SESSDATA is HttpOnly and cannot be read automatically on this platform). Please use QR code login or paste the Cookie instead.';

  @override
  String get browserCookieImportFailed =>
      'Failed to import Cookie, please retry';

  @override
  String get browserStoppedLoading => 'Loading stopped';

  @override
  String get browserClipboardAllowed =>
      'Web pages may now write to the clipboard';

  @override
  String get browserClipboardBlocked =>
      'Web pages are blocked from writing to the clipboard automatically';

  @override
  String get browserNoCurrentUrl => 'Could not get the current URL';

  @override
  String get browserTroubleshootFailed =>
      'Failed to open. Please check whether \"Get Help\" is available.';

  @override
  String get browserSystemBrowserMissing => 'System browser is missing (';

  @override
  String get browserQrTitle => 'Scan me';

  @override
  String get browserSaveToDevice => 'Save to device';

  @override
  String get browserQrSaved => 'QR code saved to gallery';

  @override
  String browserSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get browserStopLoading => 'Stop loading';

  @override
  String get browserImporting => 'Importing…';

  @override
  String get browserLoginDoneImport => 'Logged in, import';

  @override
  String get browserClipboardAccess => 'Clipboard access';

  @override
  String get browserShareQr => 'Share QR code';

  @override
  String get browserCopyLink => 'Copy link';

  @override
  String get browserViewCookies => 'View cookies';

  @override
  String get browserSetUa => 'Set UA';

  @override
  String get browserUaModeAuto => 'Auto (follow system)';

  @override
  String get browserUaModeDesktop => 'Desktop';

  @override
  String get browserUaModeMobile => 'Mobile';

  @override
  String get browserRefresh => 'Refresh';

  @override
  String get browserSystemBrowser => 'System browser';

  @override
  String get browserTroubleshootNetwork => 'Troubleshoot network';

  @override
  String get browserUnsupportedPlatform =>
      'Embedded browser is not supported on this platform';

  @override
  String get browserOpenedInSystem => 'Attempted to open in the system browser';

  @override
  String get browserReopenInSystem => 'Reopen in system browser';

  @override
  String get browserAndroidErrorTitle => 'No command.';

  @override
  String get browserAndroidErrorCause => 'Cause';

  @override
  String get browserAndroidErrorDetail =>
      'WebView initialization failed\nYour system WebView may be outdated or disabled';

  @override
  String get browserUpdateWebview =>
      'Update Android System WebView on Google Play';

  @override
  String get browserOpenDevOptions =>
      'Open developer options to view the WebView implementation';

  @override
  String get browserAppleErrorTitle => 'The app quit unexpectedly';

  @override
  String get browserAppleErrorReport => 'Problem report';

  @override
  String get browserAppleErrorDetail =>
      'Unable to initialize the embedded browser on this device. Please make sure your operating system is up to date.';

  @override
  String get browserBsodMessage =>
      'Your WebView2 ran into a problem. We need to collect some error info and then restart the app for you.';

  @override
  String get browserBsodNoRestart =>
      '(Actually no restart needed, just install the component)';

  @override
  String get browserBsodComplete => '100% complete';

  @override
  String get browserBsodSolutions => 'View solutions:';

  @override
  String get browserBsodDownload => 'Download WebView2 runtime';

  @override
  String get browserBsodWinUpdate => 'Open Windows Update settings';

  @override
  String get browserBsodScanQr => 'Scan this QR code for solutions';

  @override
  String get browserBsodStopCode => 'Stop code: WEBVIEW2_RUNTIME_MISSING';

  @override
  String get browserCantOpenExternal => 'Could not open the external link';

  @override
  String get callOutgoing => 'Calling...';

  @override
  String get callIncoming => 'Incoming call...';

  @override
  String get callConnecting => 'Connecting...';

  @override
  String get chatConnectionNotEstablishedImage =>
      'No connection, cannot send image';

  @override
  String get chatImageSent => '✅ Image sent';

  @override
  String get chatImageSendFailed => 'Failed to send image';

  @override
  String chatClipboardImageProcessFailed(String error) {
    return 'Failed to process clipboard image: $error';
  }

  @override
  String get chatImageStaged => '🖼️ Image added to input';

  @override
  String get chatClipboardNoImage => 'No image data in clipboard';

  @override
  String chatClipboardImageFetchFailed(String error) {
    return 'Failed to get clipboard image: $error';
  }

  @override
  String get chatClipboardEmptyOrUnsupported =>
      'Clipboard is empty or the format is unsupported';

  @override
  String get chatConnectionNotEstablishedFile =>
      'No connection, cannot send file';

  @override
  String get chatFileNotExist => 'File does not exist';

  @override
  String get chatFileSendFailed => 'Failed to send file';

  @override
  String chatFileSentSuccess(String fileName) {
    return '✅ $fileName sent';
  }

  @override
  String chatFileSendError(String error) {
    return 'Failed to send file: $error';
  }

  @override
  String get chatIpUnknown => 'Unknown IP';

  @override
  String get chatReconnecting => 'Reconnecting...';

  @override
  String get chatReconnectFailed =>
      'Reconnect failed. Check your network or whether the peer is online.';

  @override
  String get chatStatusUnknown => 'Unknown status';

  @override
  String get chatStatusWaiting => 'Waiting for connection';

  @override
  String get chatMe => 'Me';

  @override
  String get chatFileInfoLost => '(File info missing)';

  @override
  String chatOpenFileFailed(String message) {
    return 'Could not open file: $message';
  }

  @override
  String get chatFileNotDownloaded => 'File has not been downloaded';

  @override
  String chatOpenFileError(String error) {
    return 'Failed to open file: $error';
  }

  @override
  String get chatFilePathUnavailable =>
      'Could not get file path (Android permission limits?)';

  @override
  String chatPickFileFailed(String error) {
    return 'Failed to pick file: $error';
  }

  @override
  String get chatImagePathUnavailable => 'Could not get image path';

  @override
  String chatPickImageFailed(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String get chatCopyText => 'Copy text';

  @override
  String get chatSelectText => 'Select text';

  @override
  String get chatOpenFile => 'Open file';

  @override
  String get chatCopyImage => 'Copy image';

  @override
  String get chatSaveImage => 'Save image';

  @override
  String get chatCopyingImage => 'Copying image...';

  @override
  String get chatImageCopied => '✅ Image copied to clipboard';

  @override
  String get chatCopyFailed => 'Copy failed';

  @override
  String chatCopyImageFailed(String error) {
    return 'Failed to copy image: $error';
  }

  @override
  String get chatSaving => 'Saving...';

  @override
  String get chatSaveSuccess => '✅ Saved';

  @override
  String chatSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get chatMessageContent => 'Message content';

  @override
  String get chatEmptyContent => '(It\'s empty here)';

  @override
  String get chatDeleteMessageConfirm =>
      'Are you sure you want to delete this message?';

  @override
  String get chatMessageDeleted => 'Message deleted';

  @override
  String get chatOpenLinkTitle => 'Open link';

  @override
  String chatWillOpen(String url) {
    return 'Will open: $url';
  }

  @override
  String get chatBrowserTitle => 'In-app web browser';

  @override
  String get chatCantOpenLink => 'Could not open link';

  @override
  String chatOpenLinkFailed(String error) {
    return 'Failed to open link: $error';
  }

  @override
  String get chatPlusImage => 'Image';

  @override
  String get chatPlusFile => 'File';

  @override
  String get chatImageReady => 'Image ready';

  @override
  String get chatMore => 'More';

  @override
  String get chatPasteImage => 'Paste image';

  @override
  String get chatInputHint => 'Type a message...';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String get chatSend => 'Send';

  @override
  String get chatInvalidAddress => 'Invalid connection address, cannot send';

  @override
  String get chatImageSendError => 'Image send failed';

  @override
  String chatSendFailed(String error) {
    return 'Send failed: $error';
  }

  @override
  String get chatConnStatusUnknown =>
      'Connection status unknown, cannot send message';

  @override
  String get chatPendingCannotSend =>
      'Waiting for the peer to verify, cannot send message';

  @override
  String get chatConnRejected => 'Connection was rejected';

  @override
  String get chatConnDisconnected => 'The peer has disconnected';

  @override
  String get chatConnNotEstablished =>
      'Connection has not been established, cannot send message';

  @override
  String get chatNoMessages => 'No messages yet, start chatting';

  @override
  String get chatDisconnectedRetry => 'Connection lost, tap to reconnect';

  @override
  String get chatRejectedRetry => 'Connection rejected, tap to retry';

  @override
  String get chatExpandInput => 'Expand input bar';

  @override
  String get discoverMyLanIps => 'My LAN IPs';

  @override
  String get discoverNoIpOfType =>
      'No valid IP of this type found. Please check your network connection.';

  @override
  String discoverIpCopied(String ip) {
    return 'Copied $ip';
  }

  @override
  String get discoverTitle => 'Discover nearby devices';

  @override
  String get discoverMyIp => 'My IP';

  @override
  String get discoverRefreshBroadcast => 'Refresh/Broadcast';

  @override
  String get discoverLanDevices => 'LAN devices';

  @override
  String get discoverSearching => 'Searching for nearby devices...';

  @override
  String get discoverSendRequest => 'Tap to send a connection request';

  @override
  String get discoverPendingVerify => 'Waiting for peer verification...';

  @override
  String get discoverRejectedRetry => 'Rejected, tap to retry';

  @override
  String get discoverDisconnectedRetry => 'Disconnected, tap to reconnect';

  @override
  String get discoverUnknownDevice => 'Unknown device';

  @override
  String get discoverAlreadyConnected => 'This device is already connected';

  @override
  String get discoverAlreadyPending =>
      'Waiting for peer verification, please do not send again';

  @override
  String get discoverConnectFailed =>
      'Connection failed. Check your network or whether the peer is online.';

  @override
  String get discoverManualConnect => 'Manually connect to a peer';

  @override
  String get discoverConnectIpHint =>
      'Enter IP address (e.g. 192.168.1.100 / fe80::1)';

  @override
  String get displayScaleCompact => 'Compact mode · Show more content';

  @override
  String get displayScaleSmall => 'Slightly smaller · Good for large screens';

  @override
  String get displayScaleDefault => 'Default';

  @override
  String get displayScaleLarge => 'Slightly larger · Easier to read';

  @override
  String get displayScaleLargeFont => 'Large text · Accessibility friendly';

  @override
  String get displayScaleHuge => 'Extra large · Assistive features';

  @override
  String get displayScaleMin => 'Smallest · Highest information density';

  @override
  String get displayScaleCompactBig => 'Compact · Good for large screens';

  @override
  String get displayScaleSystemDefault => 'System default';

  @override
  String get displayScaleLargeFontShort => 'Large text · Accessibility';

  @override
  String get displayScaleTitle => 'Display Scale';

  @override
  String get displaySplashBackground => 'Splash background';

  @override
  String get displaySplashBackgroundCustom =>
      'Custom image, applies on next launch';

  @override
  String get displaySplashBackgroundDefault => 'Default';

  @override
  String get displaySplashBackgroundSetDone =>
      'Splash background set — takes effect on next launch';

  @override
  String get displaySplashBackgroundSetFailed =>
      'Failed to set splash background';

  @override
  String get displaySplashBackgroundCleared =>
      'Restored default splash background';

  @override
  String get displaySplashBackgroundClearTooltip => 'Reset';

  @override
  String get displayHeroTransitionBlur => 'Use new animations';

  @override
  String get displayIosPushTransition => 'iOS-style page transitions';

  @override
  String get displayIosPushTransitionCorner => 'Transition corner radius';

  @override
  String get displayIosPushTransitionCornerAuto => 'Match screen corners';

  @override
  String get displayIosPushTransitionCornerUnsupported =>
      'Screen corner radius unavailable, using the manual value below';

  @override
  String get searchIosPushTransition => 'iOS page transition animation';

  @override
  String get pageBgTitle => 'Page background';

  @override
  String get pageBgSubtitle =>
      'Background image shared by settings-style pages, croppable after selection';

  @override
  String get pageBgEnabled => 'Show page background';

  @override
  String get pageBgOpacity => 'Background opacity';

  @override
  String get pageBgBlur => 'Background blur';

  @override
  String get pageBgNotSet => 'Not set';

  @override
  String get pageBgPick => 'Pick and crop image';

  @override
  String get pageBgClear => 'Remove background';

  @override
  String get pageBgContentSection => 'Content pages share';

  @override
  String get pageBgContentEnabled => 'Use on content pages';

  @override
  String get pageBgContentSubtitle =>
      'Search / Recommend / Hot / Anime / Live pages share this background image';

  @override
  String get pageBgContentOpacity => 'Content opacity';

  @override
  String get pageBgContentBlur => 'Content blur';

  @override
  String get pageBgContentPick => 'Pick & crop for content pages';

  @override
  String get pageBgContentClear => 'Clear content pages background';

  @override
  String get pageBgSaved => 'Background updated';

  @override
  String get pageBgCleared => 'Background removed';

  @override
  String get pageBgPickFailed => 'Failed to pick image';

  @override
  String get cropTitle => 'Crop background';

  @override
  String get cropAspectFree => 'Free';

  @override
  String get cropApply => 'Apply';

  @override
  String get cropReset => 'Reset';

  @override
  String get displayAdvancedGlass => 'Advanced rendering';

  @override
  String get displayDisableLiquidGlassMenus => 'Reduce effects';

  @override
  String get displayMenuJelly => 'Menu jelly animation';

  @override
  String get displayMenuJellyHint =>
      'Liquid morph animation for popup menus (off: menus appear instantly)';

  @override
  String get displayBottomBarJelly => 'Bottom bar jelly effect';

  @override
  String get displayBottomBarJellyHint =>
      'Jelly physics of the bottom bar indicator (off: simple color change)';

  @override
  String get displayVideoCardGlass => 'Video card glass material';

  @override
  String get displayVideoCardGlassHint =>
      'Glass material for video cards (performance heavy: many glass cards per screen)';

  @override
  String get displayChatGlass => 'Chat / message glass material';

  @override
  String get displayChatGlassHint =>
      'Use liquid glass for chat bubbles and message cards';

  @override
  String get displayLiquidGlassTuner => 'Liquid glass tuning';

  @override
  String get displayLiquidGlassTunerSubtitle =>
      'Adjust glass thickness, blur, tint, refraction and other material parameters';

  @override
  String get lgTunerPreview => 'Live preview';

  @override
  String get lgTunerSectionMaterial => 'Material parameters';

  @override
  String get lgTunerThickness => 'Thickness';

  @override
  String get lgTunerBlur => 'Background blur';

  @override
  String get lgTunerTint => 'Tint';

  @override
  String get lgTunerSaturation => 'Saturation';

  @override
  String get lgTunerRefractiveIndex => 'Refractive index';

  @override
  String get lgTunerLightIntensity => 'Highlight intensity';

  @override
  String get lgTunerAmbient => 'Ambient light';

  @override
  String get lgTunerLightAngle => 'Light angle';

  @override
  String get lgTunerAberration => 'Chromatic dispersion';

  @override
  String get lgTunerReset => 'Reset';

  @override
  String get lgTunerNote =>
      'Changes apply instantly and globally: glass surfaces without explicit parameters (dropdown menus, dialogs, etc.) follow these values, while surfaces with explicit styles (e.g. the chat top bar) stay independent.';

  @override
  String get lgTunerFallbackNote =>
      'Advanced glass rendering (Impeller) is unavailable on this platform, so the preview shows the FakeGlass fallback. Thickness, refraction and saturation only apply on mobile.';

  @override
  String get displayScaleReset => 'Reset to 100%';

  @override
  String get displayScaleFineTune => 'Fine tune';

  @override
  String get displayScalePresets => 'Quick presets';

  @override
  String get displayScaleNote =>
      'The scale applies globally to text and some layout sizes. Set it to 100% to restore the default. Changes take effect immediately without a restart.';

  @override
  String displayScaleConnCount(int count) {
    return '$count connections';
  }

  @override
  String get displayThemeLight => 'Light';

  @override
  String get displayThemeDark => 'Dark';

  @override
  String get displaySettingsTitle => 'Display';

  @override
  String get displaySectionAppearance => 'Appearance';

  @override
  String get displayThemeMode => 'Theme mode';

  @override
  String get displayPureBlack => 'Pure black dark mode';

  @override
  String get displayPureBlackOn => 'Dark mode (pure black)';

  @override
  String get displayOff => 'Off';

  @override
  String get displaySectionPersonalize => 'Personalization';

  @override
  String get displayThemeColor => 'Theme color';

  @override
  String get displayFollowSystemColor => 'Follow system color';

  @override
  String get displayFontWeight => 'Font weight';

  @override
  String get displaySeedDefaultGreen => 'Default green';

  @override
  String get displaySeedPink => 'Pink';

  @override
  String get displaySeedRed => 'Red';

  @override
  String get displaySeedOrange => 'Orange';

  @override
  String get displaySeedAmber => 'Amber';

  @override
  String get displaySeedYellow => 'Yellow';

  @override
  String get displaySeedLime => 'Lime';

  @override
  String get displaySeedLightGreen => 'Light green';

  @override
  String get displaySeedGreen => 'Green';

  @override
  String get displaySeedCyan => 'Cyan';

  @override
  String get displaySeedTeal => 'Teal';

  @override
  String get displaySeedLightBlue => 'Light blue';

  @override
  String get displaySeedBlue => 'Blue';

  @override
  String get displaySeedIndigo => 'Indigo';

  @override
  String get displaySeedPurple => 'Purple';

  @override
  String get displaySeedDeepPurple => 'Deep purple';

  @override
  String get displaySeedBlueGrey => 'Blue grey';

  @override
  String get displaySeedBrown => 'Brown';

  @override
  String get displaySeedGrey => 'Grey';

  @override
  String get displaySeedCustom => 'Custom';

  @override
  String displayWeightThin(int weight) {
    return 'Thin ($weight)';
  }

  @override
  String displayWeightLight(int weight) {
    return 'Light ($weight)';
  }

  @override
  String displayWeightRegular(int weight) {
    return 'Regular ($weight)';
  }

  @override
  String displayWeightMedium(int weight) {
    return 'Medium ($weight)';
  }

  @override
  String displayWeightBold(int weight) {
    return 'Bold ($weight)';
  }

  @override
  String displayWeightBlack(int weight) {
    return 'Black ($weight)';
  }

  @override
  String displayWeightCustom(int weight) {
    return 'Custom ($weight)';
  }

  @override
  String get fontWeightThin => 'Thin';

  @override
  String get fontWeightLight => 'Light';

  @override
  String get fontWeightRegular => 'Regular';

  @override
  String get fontWeightMedium => 'Medium';

  @override
  String get fontWeightBold => 'Bold';

  @override
  String get fontWeightBlack => 'Black';

  @override
  String get fontWeightSampleText =>
      'The quick brown fox jumps over the lazy dog.\nThe quick brown fox jumps over the lazy dog.';

  @override
  String get fontWeightSaveApply => 'Save and apply';

  @override
  String get geetestTitle => 'Complete slider verification';

  @override
  String get geetestInitFailed =>
      'Captcha component failed to initialize. Please retry or use another login method.';

  @override
  String get geetestUnsupported =>
      'Embedded captcha is not supported on this platform. Please use QR code or Cookie login.';

  @override
  String get slicerPickImageFirst => 'Please select an image first';

  @override
  String get slicerRowColInvalid =>
      'Row and column counts must be greater than 0';

  @override
  String get slicerSuccess =>
      'Sliced successfully and added to the Start screen';

  @override
  String slicerSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get slicerTitle => 'Image Slicer Tile';

  @override
  String get slicerTileSize => 'Tile size (all slices are the same)';

  @override
  String get slicerColsLabel => 'Columns (Cols)';

  @override
  String get slicerRowsLabel => 'Rows (Rows)';

  @override
  String slicerPreview(int count, String type) {
    return 'Preview: will be sliced into $count $type tiles';
  }

  @override
  String get slicerProcessing => 'Processing...';

  @override
  String get slicerSaveToStart => 'Save to Start screen';

  @override
  String get viewerSaving => 'Saving...';

  @override
  String get viewerSaveSuccess => 'Saved';

  @override
  String viewerSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get viewerShareImage => 'Share image';

  @override
  String viewerShareFailed(String error) {
    return 'Share failed: $error';
  }

  @override
  String get viewerCopying => 'Copying...';

  @override
  String viewerCopyFailed(String error) {
    return 'Copy failed: $error';
  }

  @override
  String get viewerSaveToAlbum => 'Save to gallery';

  @override
  String get viewerCopyToClipboard => 'Copy to clipboard';

  @override
  String get viewerImageLoadFailed => 'Failed to load image';

  @override
  String get viewerImageDataNotFound => 'Image data not found';

  @override
  String get userSpaceMidInvalid => 'Invalid mid';

  @override
  String get userSpaceNoCard => 'Response is missing card';

  @override
  String get userSpaceNoList => 'Response is missing list';

  @override
  String get searchTypeVideo => 'Videos';

  @override
  String get searchTypeBangumi => 'Anime';

  @override
  String get searchTypeFt => 'Movies & TV';

  @override
  String get searchTypeLive => 'Live';

  @override
  String get searchTypeUser => 'Users';

  @override
  String get searchTypeArticle => 'Articles';

  @override
  String get tenThousandUnit => 'K';

  @override
  String searchVideoMeta(String play, String danmaku) {
    return '$play views · $danmaku danmaku';
  }

  @override
  String searchScore(String score) {
    return 'Rating $score';
  }

  @override
  String searchOnline(String count) {
    return '$count online';
  }

  @override
  String searchUserMeta(String fans, String videos) {
    return '$fans fans · $videos videos';
  }

  @override
  String searchArticleMeta(String views, String replies) {
    return '$views reads · $replies comments';
  }

  @override
  String get searchBadgeCourse => 'Course';

  @override
  String get searchBadgeLive => 'Live';

  @override
  String get searchBadgeCoop => 'Collab';

  @override
  String get searchBadgeLiveNow => 'Live now';

  @override
  String get searchKeywordEmpty => 'Keyword is empty';

  @override
  String get searchBadResponse => 'Unexpected response format';

  @override
  String get searchFailed => 'Search failed';

  @override
  String get searchGaiaParamMissing => 'gaia register: missing parameters';

  @override
  String searchGaiaRegisterError(String error) {
    return 'gaia register error: $error';
  }

  @override
  String searchGaiaValidateFailed(int isValid) {
    return 'gaia validate failed (is_valid=$isValid)';
  }

  @override
  String searchGaiaValidateError(String error) {
    return 'gaia validate error: $error';
  }

  @override
  String get commentOidEmpty => 'oid is empty';

  @override
  String commentException(String error) {
    return 'Exception: $error';
  }

  @override
  String commentSubHttpError(int code) {
    return 'Replies HTTP $code';
  }

  @override
  String get commentSubNoData => 'Replies response is missing data';

  @override
  String commentSubException(String error) {
    return 'Replies error: $error';
  }

  @override
  String get commentNotLoggedIn =>
      'Not logged in or \"Carry Cookie\" is turned off';

  @override
  String get commentMissingJct =>
      'Cookie is missing bili_jct. Please log in again';

  @override
  String commentNetworkError(String error) {
    return 'Network error: $error';
  }

  @override
  String commentApiError(String message, int code) {
    return '$message (code=$code)';
  }

  @override
  String get deviceOs => 'Operating system';

  @override
  String get deviceBuild => 'Build number';

  @override
  String get deviceSecurityPatch => 'Security patch';

  @override
  String get deviceOem => 'OEM manufacturer';

  @override
  String get deviceBrand => 'Brand';

  @override
  String get deviceModel => 'Model';

  @override
  String get deviceRomVersion => 'ROM / Display version';

  @override
  String get deviceFingerprint => 'Device fingerprint';

  @override
  String get deviceName => 'Device name';

  @override
  String get deviceComputerName => 'Computer name';

  @override
  String get deviceHardwareModel => 'Hardware model';

  @override
  String get deviceKernel => 'Kernel version';

  @override
  String get deviceDistro => 'Distribution';

  @override
  String get deviceVersion => 'Version';

  @override
  String get devicePlatform => 'Platform';

  @override
  String deviceInfoFailed(String error) {
    return 'Failed to get info: $error';
  }

  @override
  String get logWebUnsupported => '(File logging is not supported on the Web)';

  @override
  String get logNotInitialized => '(Not initialized)';

  @override
  String logAppDataDir(String path) {
    return 'App data directory\n$path';
  }

  @override
  String logAppDataRoaming(String path) {
    return 'AppData (Roaming)\n$path';
  }

  @override
  String logAppSupport(String path) {
    return 'Application Support\n$path';
  }

  @override
  String logLocalDataDir(String path) {
    return 'Local data directory\n$path';
  }

  @override
  String get nowPlayingVideo => 'Playing video';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get unnamedPlaylist => 'Untitled playlist';

  @override
  String get unknownVideo => 'Unknown video';

  @override
  String dohQueryFailed(int code) {
    return 'DoH query failed: HTTP $code';
  }

  @override
  String get tcpConnectSuccess => 'TCP connection succeeded';

  @override
  String get netModeCompat =>
      'Host-mapped IP direct connection, bypassing SNI interference';

  @override
  String get netModeStandard => 'System default network stack';

  @override
  String netHostResolveFailed(String host) {
    return 'Unable to resolve host $host';
  }

  @override
  String get biliCookieEmpty => 'Cookie is empty';

  @override
  String get biliCookieIncomplete =>
      'Incomplete Cookie. Copy the full Cookie from your browser (must include SESSDATA)';

  @override
  String get biliCookieMissingJct =>
      'Cookie is missing bili_jct. Re-copy the full Cookie from your browser (likes and comments depend on it)';

  @override
  String get biliCookieInvalid =>
      'Invalid or expired Cookie. Copy it again from your browser';

  @override
  String get biliLoginSuccess => 'Logged in';

  @override
  String biliHttpError(int code) {
    return 'HTTP $code';
  }

  @override
  String get biliRiskBlocked =>
      'Request blocked by risk control (-412). Please retry later';

  @override
  String get biliQrExpired => 'QR code expired';

  @override
  String get biliQrScanned => 'Scanned. Confirm on your phone';

  @override
  String get biliQrWaiting => 'Waiting to scan';

  @override
  String get biliRequestFailed => 'Request failed';

  @override
  String get biliResponseNoData => 'Response is missing data';

  @override
  String get biliQrNoSessionCookie =>
      'Failed to obtain the session Cookie. Refresh the QR code and retry';

  @override
  String get biliQrMissingJct =>
      'QR login didn\'t return a full session (missing bili_jct). Use \"Paste Cookie\" or \"Browser login\" instead';

  @override
  String get biliNoSessionCookie => 'Failed to obtain the session Cookie';

  @override
  String get biliWebKeyFailed =>
      'Failed to get the login public key. Check your network';

  @override
  String get biliPwdEncryptFailed => 'Failed to encrypt the password';

  @override
  String get biliNeedGeetest => 'Slider verification required';

  @override
  String get biliUnknownError => 'Unknown error';

  @override
  String get csPlaylists => 'Playlists';

  @override
  String get csDanmaku => 'Danmaku';

  @override
  String get csCloudEncrypted =>
      'Cloud data is encrypted. Enter the sync passphrase in WebDAV settings first';

  @override
  String get csCloudPassMismatch =>
      'Cloud data is encrypted and the sync passphrase doesn\'t match. Cannot sync';

  @override
  String get csCloudNoFile => 'No playlist file on the cloud. Cannot restore';

  @override
  String get csRestoredFromCloud => 'Restored from cloud';

  @override
  String get csSyncDone => 'Sync complete';

  @override
  String csUploadBgCount(int count) {
    return 'Uploaded $count background images';
  }

  @override
  String csDownloadBgCount(int count) {
    return 'Downloaded $count background images';
  }

  @override
  String csUploadedFileCount(int count) {
    return 'Uploaded $count file(s)';
  }

  @override
  String csDownloadedFileCount(int count) {
    return 'Downloaded $count file(s)';
  }

  @override
  String csMergedListsCount(int count) {
    return 'Merged $count playlist(s)';
  }

  @override
  String get csEncrypted => 'Encrypted';

  @override
  String csSyncFailed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String csUploadedPlaylists(int count) {
    return 'Uploaded $count playlist(s) to the cloud';
  }

  @override
  String csDanmakuSummary(int uploaded, int downloaded) {
    return 'Uploaded $uploaded, downloaded $downloaded';
  }

  @override
  String csDanmakuFailed(int failed, String details) {
    return ', $failed failed ($details)';
  }

  @override
  String get unknownUser => 'Unknown user';

  @override
  String transferSpeedBody(String fileName, String speed) {
    return '$fileName  $speed KB/s';
  }

  @override
  String get sendingFile => 'Sending file';

  @override
  String receivingFile(String fileName) {
    return 'Receiving: $fileName';
  }

  @override
  String get notificationChannelName => 'Chat messages';

  @override
  String get notificationChannelDesc =>
      'Receive chat messages and quick replies';

  @override
  String get notificationReply => 'Reply';

  @override
  String get screenshotSavedTitle => 'Screenshot saved';

  @override
  String get screenshotSavedToAlbum => 'Screenshot saved to album';

  @override
  String get notificationConfirm => 'OK';

  @override
  String get callInProgressError => 'There is an active call. Hang up first';

  @override
  String get callTcpFailed =>
      'Failed to connect to the peer (TCP setup failed). Make sure the peer is online';

  @override
  String get callConnectionDropped =>
      'Connection dropped right after setup. Check the network or the peer';

  @override
  String callInitFailed(String error) {
    return 'Failed to start the call: $error';
  }

  @override
  String callAcceptFailed(String error) {
    return 'Failed to answer the call: $error';
  }

  @override
  String get callRecordVoice => 'Voice call';

  @override
  String get callRecordMissedOutgoing => 'Missed outgoing call';

  @override
  String get callRecordRejected => 'Rejected call';

  @override
  String get callRecordMissedIncoming => 'Missed call';

  @override
  String get callPeerNoAnswer => 'The peer didn\'t answer';

  @override
  String get callUnknown => 'Unknown';

  @override
  String get callInProgress => 'In call';

  @override
  String get webdavHttpWarning =>
      'Warning: Using HTTP sends credentials in plaintext. HTTPS is recommended.';

  @override
  String get webdavConfigRequired =>
      'Please fill in the server URL and username first';

  @override
  String get webdavAuthFailed =>
      'Authentication failed: wrong username or password';

  @override
  String webdavConnectFailed(int code) {
    return 'Connection failed: HTTP $code';
  }

  @override
  String webdavNetworkError(String msg) {
    return 'Network error: could not reach the server ($msg)';
  }

  @override
  String webdavUnknownError(String error) {
    return 'Unknown error: $error';
  }

  @override
  String get webdavNotConfigured => 'WebDAV is not configured';

  @override
  String webdavLocalFileMissing(String path) {
    return 'Local file does not exist: $path';
  }

  @override
  String webdavUploadFailed(int code) {
    return 'Upload failed: HTTP $code';
  }

  @override
  String webdavUploadError(String error) {
    return 'Upload error: $error';
  }

  @override
  String webdavDownloadFailed(int code) {
    return 'Download failed: HTTP $code';
  }

  @override
  String webdavDownloadError(String error) {
    return 'Download error: $error';
  }

  @override
  String webdavDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String webdavListFailed(String error) {
    return 'Failed to list files: $error';
  }

  @override
  String webdavPropfindFailed(int code) {
    return 'PROPFIND failed: HTTP $code';
  }

  @override
  String webdavNetworkErr(String msg) {
    return 'Network error: $msg';
  }

  @override
  String webdavPreparingBackup(int count) {
    return 'Preparing to back up $count files...';
  }

  @override
  String webdavBackingUp(String nickname, String fileName) {
    return 'Backing up ($nickname) $fileName';
  }

  @override
  String webdavBackupDone(int success, int fail) {
    return 'Backup done: $success succeeded, $fail failed';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonConnect => 'Connect';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonDelete => 'Delete';

  @override
  String get drawerHome => 'Home';

  @override
  String get drawerVerificationRequests => 'Verification Requests';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerAbout => 'About';

  @override
  String get drawerCloseMenu => 'Close menu';

  @override
  String get drawerLockNow => 'Lock now';

  @override
  String get drawerNoNickname => 'No nickname set';

  @override
  String get drawerSwitchToDark => 'Switch to dark mode';

  @override
  String get drawerSwitchToLight => 'Switch to light mode';

  @override
  String get drawerLightMode => 'Light mode';

  @override
  String get drawerDarkMode => 'Dark mode';

  @override
  String get drawerSystemMode => 'Follow system';

  @override
  String drawerThemeSwitched(String mode) {
    return 'Switched to $mode';
  }

  @override
  String drawerFetchFailed(String error) {
    return 'Failed to fetch: $error';
  }

  @override
  String get drawerNoDeviceInfo => 'No device info';

  @override
  String get drawerBackgroundTitle => 'Sidebar background';

  @override
  String get drawerBackgroundHasCustom =>
      'A custom background is set. You can change or remove it.';

  @override
  String get drawerBackgroundNoCustom =>
      'Set a personalized background image for the sidebar.';

  @override
  String get drawerBackgroundUpdated => '✅ Sidebar background updated';

  @override
  String drawerBackgroundSetFailed(String error) {
    return '❌ Failed to set: $error';
  }

  @override
  String get drawerBackgroundChange => 'Change background';

  @override
  String get drawerBackgroundSelect => 'Choose background image';

  @override
  String get drawerBackgroundRestored => 'Default background restored';

  @override
  String get drawerBackgroundRemove => 'Remove background';

  @override
  String get homeOpenMenu => 'Open menu';

  @override
  String get homeAddConnection => 'Add connection';

  @override
  String get homeMessages => 'Messages';

  @override
  String get homeNoConnections => 'No connections';

  @override
  String get homePullToRefreshHint => 'Pull to refresh or tap + to add';

  @override
  String get homeLoadFailed => 'Failed to load chats, please retry';

  @override
  String get homeRetryLoad => 'Retry';

  @override
  String get homeUnknownAddress => 'Unknown address';

  @override
  String get homeNoMessages => 'No messages';

  @override
  String homeFileMessage(String fileName) {
    return '[File] $fileName';
  }

  @override
  String get homeFileFallbackName => 'File';

  @override
  String get homeMessagePlaceholder => '[Message]';

  @override
  String get connectionLost => 'Connection lost';

  @override
  String get openVideoFailed => 'Failed to open the video';

  @override
  String get connectDialogTitle => 'Connect to peer';

  @override
  String get connectIpHint =>
      'Enter IP address (e.g. 192.168.1.100 or fe80::1)';

  @override
  String get connectIpEmpty => 'Please enter an IP address';

  @override
  String get connectIpInvalid => 'Invalid IP address format';

  @override
  String get connectIpNotLan => 'Only LAN IP addresses are allowed';

  @override
  String get connectRequestSent =>
      'Connection request sent, waiting for verification';

  @override
  String get connectFailed =>
      'Connection failed. Check the IP address or whether the peer is online';

  @override
  String get homeScanQr => 'Scan QR code';

  @override
  String get homeMyQrCode => 'My QR code';

  @override
  String get homeManualAdd => 'Add manually';

  @override
  String get scannedFriends => 'Friends added by QR';

  @override
  String get scanTitle => 'Scan';

  @override
  String get scanTitleWebdav => 'Scan WebDAV address';

  @override
  String get scanHint => 'Align the QR code / barcode within the frame';

  @override
  String get scanHintWebdav =>
      'Align the WebDAV server address QR code within the frame';

  @override
  String get scanHintAddFriend =>
      'Align your friend\'s device QR code within the frame';

  @override
  String get scanPreparing => 'Preparing camera...';

  @override
  String get scanPermissionNeeded => 'Camera permission required';

  @override
  String get scanPermissionNeededMsg =>
      'Please allow camera access in the permission dialog to scan.';

  @override
  String get scanPermissionDenied => 'Camera permission denied';

  @override
  String get scanPermissionDeniedMsg =>
      'Permission is permanently denied. Enable it manually in system settings.';

  @override
  String get scanCameraUnavailable => 'Camera unavailable';

  @override
  String get scanRetry => 'Retry';

  @override
  String get scanOpenSettings => 'Go to system settings';

  @override
  String get scanTorch => 'Flashlight';

  @override
  String get scanDetectedLink => 'Link detected';

  @override
  String get scanOpenLinkPrompt => 'Open this link in the built-in browser?';

  @override
  String get scanCopy => 'Copy';

  @override
  String get scanOpen => 'Open';

  @override
  String get scanLinkCopied => 'Link copied';

  @override
  String get scanDetectedBiliVideo => 'Bilibili video link detected';

  @override
  String get scanBiliVideoPrompt => 'Open this video in the built-in player?';

  @override
  String scanBiliVideoAt(String time) {
    return 'Jump to $time';
  }

  @override
  String get scanOpenVideo => 'Open video';

  @override
  String get scanDetectedWebdav => 'WebDAV address detected';

  @override
  String get scanWebdavPrompt =>
      'This looks like a WebDAV server address. Fill it into the config automatically?';

  @override
  String get scanOpenInBrowser => 'Open in browser';

  @override
  String get scanFillConfig => 'Fill into config';

  @override
  String get scanDetectedText => 'Text detected';

  @override
  String get scanCopiedToClipboard => 'Copied to clipboard';

  @override
  String get scanClose => 'Close';

  @override
  String get scanResultTitle => 'Scan result';

  @override
  String get scanErrorPermission => 'Camera permission denied';

  @override
  String get scanErrorUnsupported => 'Scanning is not supported on this device';

  @override
  String get scanErrorDisposed => 'Scanner has been disposed. Please retry.';

  @override
  String scanErrorGeneric(String code) {
    return 'Camera unavailable ($code)';
  }

  @override
  String scanInitFailed(String error) {
    return 'Scanner initialization failed: $error';
  }

  @override
  String get scanDetectedDevice => 'Device QR code detected';

  @override
  String get scanAddFriendPrompt => 'Add this device as a friend?';

  @override
  String get scanAddFriend => 'Add friend';

  @override
  String get scanFriendAdded => 'Friend request sent, waiting for verification';

  @override
  String get scanFriendAddFailed =>
      'Failed to add friend. Check the network or whether the peer is online';

  @override
  String get myQrTitle => 'My QR code';

  @override
  String get myQrHint => 'Have your friends scan this QR code to add you';

  @override
  String get myQrEmbedIp => 'The first LAN IP is embedded in the QR code';

  @override
  String get myQrLocalIps => 'Current LAN IPs';

  @override
  String get myQrCopyContent => 'Copy QR content';

  @override
  String get myQrCopied => 'Copied to clipboard';

  @override
  String get myQrNoIp =>
      'No valid LAN IP found. Please check your network connection.';

  @override
  String get displayModeSectionTitle => 'Screen';

  @override
  String get displayModeTitle => 'Screen refresh rate';

  @override
  String get displayModeAuto => 'Auto';

  @override
  String get displayModeSystemTag => '[System]';

  @override
  String get displayModeHint => 'Not working? Try restarting the app';

  @override
  String get displayModeUnsupported =>
      'Screen refresh rate settings are only supported on Android';

  @override
  String get displayModeAndroidOnly => 'Android only';

  @override
  String get displayModeLoading => 'Loading screen refresh rates...';

  @override
  String get displayModeEmpty => 'No screen refresh rates available';

  @override
  String get playerSectionEnhance => 'Picture enhancement';

  @override
  String get superResolutionTitle => 'Super resolution';

  @override
  String get superResolutionOff => 'Off';

  @override
  String get superResolutionEfficiency => 'Efficiency (low overhead)';

  @override
  String get superResolutionQuality => 'Quality (best effect)';

  @override
  String get superResolutionHint =>
      'Real-time enhancement via mpv shaders. Recommended with hardware decoding; works best on anime content';

  @override
  String get skipIntroOutroTitle => 'Skip intro/outro';

  @override
  String get skipIntroOutroHint =>
      'Detects intros/outros via community data; only prompts when the video has BV+CID';

  @override
  String get skipIntro => 'Skip intro';

  @override
  String get skipOutro => 'Skip outro';

  @override
  String playlistDetailEpisodes(int count) {
    return '$count episodes';
  }

  @override
  String get playlistDetailEmpty =>
      'This playlist is empty. Add videos via edit first';

  @override
  String playlistDetailEpisodeOf(int index) {
    return 'Episode $index';
  }

  @override
  String playlistDetailResume(String position) {
    return 'Resumed at $position';
  }

  @override
  String get playlistDetailBgTitle => 'Background image';

  @override
  String get playlistDetailBgPick => 'Choose background image';

  @override
  String get playlistDetailBgChange => 'Change background';

  @override
  String get playlistDetailBgRemove => 'Remove background';

  @override
  String get playlistDetailBgUpdated => '✅ Background updated';

  @override
  String get playlistDetailBgRemoved => 'Default background restored';

  @override
  String playlistDetailBgFail(String error) {
    return 'Failed to set: $error';
  }

  @override
  String get playlistFabRestart => 'Start over';

  @override
  String get playlistMenuMore => 'More actions';

  @override
  String get playlistMenuRename => 'Rename';

  @override
  String get playlistMenuMultiSelect => 'Multi-select';

  @override
  String get playlistMenuDanmaku => 'Danmaku';

  @override
  String get playlistRenameTitle => 'Rename playlist';

  @override
  String get playlistRenameHint => 'Enter a new name';

  @override
  String get playlistRenameSaved => 'Renamed';

  @override
  String get playlistSelectDone => 'Done';

  @override
  String get playlistSelectEmpty => 'Select episodes first';

  @override
  String playlistSelectDelete(int count) {
    return 'Delete selected ($count)';
  }

  @override
  String playlistSelectDeleted(int count) {
    return 'Deleted $count episodes';
  }

  @override
  String get playlistDanmakuTitle => 'Import season danmaku';

  @override
  String get playlistDanmakuSsHint => 'Enter the season SS number (season_id)';

  @override
  String get playlistDanmakuFetchFail =>
      'Failed to fetch episodes. Check the SS number';

  @override
  String playlistDanmakuSelectTitle(int count) {
    return 'Select episodes ($count total, matched in order 1, 2, 3... to playlist episodes 1, 2, 3...)';
  }

  @override
  String get playlistDanmakuSelectAll => 'Select all';

  @override
  String get playlistDanmakuImport => 'Import & attach danmaku';

  @override
  String playlistDanmakuAttached(int count) {
    return 'Danmaku attached to $count episodes';
  }

  @override
  String playlistDanmakuExceed(int selected, int total) {
    return '$selected selected exceed the $total episodes in the list; extras were ignored';
  }

  @override
  String get splitSelectChat => 'Select a chat';

  @override
  String get statusPending => 'Awaiting verification';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusDisconnected => 'Disconnected';

  @override
  String get homeStart => 'Start';

  @override
  String get homeDone => 'Done';

  @override
  String get homeBack => 'Navigate up';

  @override
  String get homeOverview => 'Overview';

  @override
  String get homeLocalUser => 'Local user';

  @override
  String get homeDefaultGroup => 'Default group';

  @override
  String get homeNewGroup => 'New group';

  @override
  String get homeUnnamedGroup => '(Unnamed group)';

  @override
  String get homeDeleteGroupTitle => 'Confirm deletion';

  @override
  String get homeDeleteGroupMessage =>
      'Deleting this group will also delete all tiles in it. Continue?';

  @override
  String get homeNewGroupTitle => 'New group';

  @override
  String get homeGroupNameHint => 'Enter group name';

  @override
  String get homeRenameGroupTitle => 'Name this group';

  @override
  String get homeNewGroupNameHint => 'Enter new group name';

  @override
  String get homeImageSlice => 'Image slice';

  @override
  String tileSizeLabelSmall(String size) {
    return '$size (Small)';
  }

  @override
  String tileSizeLabelWide(String size) {
    return '$size (Wide)';
  }

  @override
  String tileSizeLabelLarge(String size) {
    return '$size (Large)';
  }

  @override
  String get homeGroupOne => 'Group 1';

  @override
  String get homeGroupTwo => 'Group 2';

  @override
  String get homeGroupProductivity => 'Productivity';

  @override
  String get homeGroupLegacy => 'Legacy';

  @override
  String get tileImageSlicer => 'Image slicer';

  @override
  String get tileSystemSettings => 'System settings';

  @override
  String get tileDatabase => 'Database';

  @override
  String get tileLcdDisplay => 'LCD display';

  @override
  String get tileLedDynamic => 'LED dynamic';

  @override
  String get tileLedStatic => 'LED static';

  @override
  String get tilePisScreen => 'PIS screen';

  @override
  String get tileRoutePreview => 'Route preview';

  @override
  String get tileStationEntranceDesign => 'Entrance design';

  @override
  String get tileStationEntrancePillar => 'Entrance pillar';

  @override
  String get tileStationEntranceSideName => 'Entrance side name';

  @override
  String get tilePlatformSideName => 'Platform side name';

  @override
  String get tileScreenDoorCover => 'Screen door cover';

  @override
  String get tileStationNameSign => 'Station name sign';

  @override
  String get tileGeneralSign => 'General sign';

  @override
  String get tileLineSymbol => 'Line symbol';

  @override
  String get tileBusLcd => 'Bus LCD';

  @override
  String get tileJsonEditor => 'JSON editor';

  @override
  String get tileNamingRule => 'Naming rule';

  @override
  String get tilePlatformText => 'Platform text';

  @override
  String get tileDepartureText => 'Departure text';

  @override
  String get tileArrivalText => 'Arrival text';

  @override
  String get tileOperationDirectionLegacy => 'Operation direction (Legacy)';

  @override
  String get tileLegacyLcdWarning => 'Legacy LCD (Warning)';

  @override
  String get tileLinearRoute => 'Linear route';

  @override
  String get tileRoadSign => 'Road sign';

  @override
  String get commentPanelTitle => 'Comments';

  @override
  String commentTotalCount(int count) {
    return '$count comments';
  }

  @override
  String get commentSortHeat => 'By popularity';

  @override
  String get commentSortTime => 'By time';

  @override
  String get commentLoading => 'Loading comments...';

  @override
  String get commentLoadFail => 'Failed to load comments, check network';

  @override
  String get commentLoadMoreFail => 'Failed to load more comments';

  @override
  String get commentNoMore => 'No more comments';

  @override
  String get commentLoadingMore => 'Loading...';

  @override
  String get commentEmpty => 'No comments yet';

  @override
  String get commentViewDialogue => 'View conversation';

  @override
  String get commentDialogueTitle => 'Conversation';

  @override
  String get msgMenuSettings => 'Message settings';

  @override
  String get msgSettingsLoadFail => 'Failed to load message settings';

  @override
  String get msgSettingsSaveFail => 'Failed to save';

  @override
  String get commentPinned => 'Pinned';

  @override
  String get commentDeleted => 'Comment deleted';

  @override
  String get commentExpand => 'Expand';

  @override
  String get commentCollapse => 'Collapse';

  @override
  String get commentTranslateNeedEnable =>
      'Enable AI translation in Language settings first';

  @override
  String get commentTranslateNone => 'No translation available';

  @override
  String get commentReply => 'Reply';

  @override
  String get commentTranslate => 'Translate';

  @override
  String get commentTranslateRestore => 'Show original';

  @override
  String get commentLikeTooltip => 'Like';

  @override
  String get commentDislikeTooltip => 'Dislike';

  @override
  String commentSubCount(int count) {
    return '$count replies';
  }

  @override
  String commentSubLoadMore(String hint) {
    return 'Load more replies ($hint)';
  }

  @override
  String get commentYesterday => 'Yesterday';

  @override
  String get articleLoadFailed => 'Failed to load article';

  @override
  String get articleNoContent =>
      'Article content is empty or not supported yet';

  @override
  String get articleOpenBrowser => 'Open in browser';

  @override
  String get articleShare => 'Share';

  @override
  String get articleAuthorUnknown => 'Unknown author';

  @override
  String get browserLinkPageTitle => 'Web link';

  @override
  String articleViews(String count) {
    return '$count reads';
  }

  @override
  String get contactPickerTitle => 'Send to contact';

  @override
  String get contactPickerContentLabel => 'Content';

  @override
  String get contactPickerContentHint => 'Enter content to send';

  @override
  String get contactPickerContentEmpty => 'Content cannot be empty';

  @override
  String get contactPickerSearchHint => 'Search contacts';

  @override
  String get contactPickerEmpty => 'No contacts yet';

  @override
  String get contactPickerNoMatch => 'No matching contacts';

  @override
  String get contactPickerSelectAll => 'Select all';

  @override
  String contactPickerSendToCount(int count) {
    return 'Send to $count contact(s)';
  }

  @override
  String contactPickerSent(int count) {
    return 'Sent to $count contact(s)';
  }

  @override
  String contactPickerNotConnected(String name) {
    return '$name is not connected, cannot send';
  }

  @override
  String contactPickerSendFailed(String error) {
    return 'Send failed: $error';
  }

  @override
  String get contactPickerOnline => 'Online';

  @override
  String get contactPickerOffline => 'Offline';

  @override
  String get articleShareToContact => 'Share via chat';

  @override
  String get playerDanmakuList => 'Danmaku list';

  @override
  String playerDanmakuListCount(int count) {
    return 'Danmaku list · $count total';
  }

  @override
  String get playerDanmakuListEmpty => 'No danmaku yet';

  @override
  String get playerDanmakuListNoMatch => 'No matching danmaku';

  @override
  String get playerDanmakuListSearchHint => 'Search danmaku';

  @override
  String get playerDanmakuListJumpCurrent => 'Jump to current position';

  @override
  String get playerViewNotes => 'View notes';

  @override
  String get playerNotesTitle => 'Notes';

  @override
  String playerNotesCount(int count) {
    return 'Notes ($count)';
  }

  @override
  String get playerNotesEmpty => 'No public notes yet';

  @override
  String get playerNotesNoMore => 'No more';

  @override
  String get playerNotesLoadFailed => 'Failed to load notes';

  @override
  String get playerNotesViewFull => 'View full';

  @override
  String get playerWriteNote => 'Write note';

  @override
  String get noteEditorWrite => 'Write note';

  @override
  String get noteEditorTitle => 'Write note';

  @override
  String get noteEditorTitleHint => 'Title (optional)';

  @override
  String get noteEditorContentHint => 'Start taking notes…';

  @override
  String get noteEditorEmoji => 'Emoji';

  @override
  String get noteEditorPublish => 'Publish';

  @override
  String get noteEditorEmptyContent => 'Note content cannot be empty';

  @override
  String get noteEditorContentTooShort =>
      'Content must be at least 10 characters to publish';

  @override
  String get noteEditorNotLoggedIn =>
      'Not logged in: note saved as local draft; log in to publish';

  @override
  String get noteEditorPublished => 'Note published';

  @override
  String get noteEditorPublishNetworkError =>
      'Publish failed (network error); draft saved';

  @override
  String get noteEditorPublishRejected =>
      'Publish rejected by server; draft kept';

  @override
  String get noteEditorDraftSaved => 'Draft auto-saved';

  @override
  String get noteEditorLoggedInHint => 'Logged in: publishing available';

  @override
  String get noteEditorGuestHint =>
      'Not logged in: local drafts only, cannot publish';

  @override
  String noteEditorSavedAt(String hour, String minute) {
    return 'Draft saved $hour:$minute';
  }

  @override
  String noteEditorCharCount(int count) {
    return '$count chars';
  }

  @override
  String get noteEditorMyDraft => 'My draft';

  @override
  String get noteEditorDeleteDraft => 'Delete draft';

  @override
  String get playerMoreTooltip => 'More actions';

  @override
  String get commentComposerBarHint => 'Say something…';

  @override
  String get commentComposerHint => 'Write a comment…';

  @override
  String commentComposerReplyHint(String name) {
    return 'Reply to @$name';
  }

  @override
  String commentComposerReplyTo(String name) {
    return 'Replying to @$name';
  }

  @override
  String get commentComposerEmote => 'Emotes';

  @override
  String get commentComposerSend => 'Send';

  @override
  String get commentComposerEmpty => 'Comment cannot be empty';

  @override
  String get commentComposerEmoteUnavailable =>
      'Emote panel unavailable (not logged in?)';

  @override
  String get commentComposerPickImage => 'Pick image';

  @override
  String get commentComposerMore => 'More';

  @override
  String get commentComposerVideoProgress => 'Video progress';

  @override
  String get commentComposerVideoScreenshot => 'Video screenshot';

  @override
  String commentComposerImageLimit(int count) {
    return 'Up to $count images';
  }

  @override
  String get commentComposerCaptureFailed =>
      'Screenshot failed; start playback first';

  @override
  String get commentComposerUploadFailed => 'Image upload failed, please retry';

  @override
  String get commentComposerFabLabel => 'Post comment';

  @override
  String get commentComposerFabReply => 'Post reply';

  @override
  String get danmakuSendTitle => 'Send danmaku';

  @override
  String get danmakuSendModeLabel => 'Mode';

  @override
  String get danmakuSendFontSizeLabel => 'Size';

  @override
  String get danmakuSendColorLabel => 'Color';

  @override
  String get danmakuFontSizeSmall => 'Small';

  @override
  String get danmakuFontSizeStandard => 'Normal';

  @override
  String get danmakuFontSizeLarge => 'Large';

  @override
  String get danmakuSendCustomColor => 'Custom color';

  @override
  String get danmakuSendColorOk => 'OK';

  @override
  String get danmakuSendPreviewPlaceholder => 'Send a friendly danmaku';

  @override
  String get drawerHistory => 'History';

  @override
  String get drawerWatchLater => 'Watch Later';

  @override
  String get drawerMyCache => 'My Cache';

  @override
  String get historyCenterTitle => 'History';

  @override
  String get historyTabWatch => 'Watch History';

  @override
  String get historyTabPlay => 'Playback';

  @override
  String get historySearchHint => 'Search history...';

  @override
  String get historyPauseHistory => 'Pause history';

  @override
  String get historyResumeHistory => 'Resume history';

  @override
  String get historyPausedTip => 'History is paused';

  @override
  String get historyPausedTipAction => 'Tap to resume';

  @override
  String get historyClearWatchHistory => 'Clear watch history';

  @override
  String get historyClearPlayHistory => 'Clear playback history';

  @override
  String get historyClearAllTitle => 'Clear history';

  @override
  String historyClearAllConfirm(String label) {
    return 'Clear all $label? This cannot be undone.';
  }

  @override
  String get historyNoWatchHistory => 'No watch history';

  @override
  String get historyNoPlayHistory => 'No playback records';

  @override
  String get historyDeleteSelected => 'Delete selected';

  @override
  String historySelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get historySearchNoResult => 'No results';

  @override
  String get historyPauseOnSnack => 'History paused';

  @override
  String get historyResumeOnSnack => 'History resumed';

  @override
  String historyDeleteToast(int count) {
    return 'Deleted $count records';
  }

  @override
  String get myCacheTitle => 'My Cache';

  @override
  String get myCacheSearchHint => 'Search cached videos...';

  @override
  String get myCacheDownloading => 'Downloading';

  @override
  String get myCacheCached => 'Cached';

  @override
  String get myCacheNoCache => 'No cached videos';

  @override
  String myCacheGroupCount(int count) {
    return '$count videos';
  }

  @override
  String get myCacheDeleteGroup => 'Delete group';

  @override
  String get myCacheUpdateDanmaku => 'Update danmaku';

  @override
  String get myCacheClearAllTitle => 'Clear all cache';

  @override
  String myCacheClearAllConfirm(int count, String size) {
    return 'Delete all cached videos ($count videos · $size)?';
  }

  @override
  String get cacheActionDownload => 'Cache';

  @override
  String get cacheActionCached => 'Cached';

  @override
  String get cacheActionCaching => 'Caching';

  @override
  String get cacheToastSuccess => 'Added to download queue';

  @override
  String get cacheToastCached => 'Already cached';

  @override
  String cacheToastFailed(String error) {
    return 'Cache failed: $error';
  }

  @override
  String get drawerRecommend => 'Recommend';

  @override
  String get recommendSourceWeb => 'Web';

  @override
  String get recommendSourceApp => 'App';

  @override
  String get recommendEmpty => 'No recommendations';

  @override
  String get recommendSwitchList => 'Switch to list';

  @override
  String get recommendSwitchGrid => 'Switch to grid';

  @override
  String get sideBarExpand => 'Expand sidebar';

  @override
  String get sideBarCollapse => 'Collapse sidebar';

  @override
  String get sideBarMore => 'More';

  @override
  String get recommendTabHot => 'Hot';

  @override
  String get recommendTabBangumi => 'Bangumi';

  @override
  String get recommendSourceTitle => 'Recommendation source';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsPreferencesSub => 'Miscellaneous & personal preferences';

  @override
  String get settingsPreferencesEmpty => 'No preferences yet';

  @override
  String get prefBottomBarSection => 'Bottom bar style';

  @override
  String get prefUseM3BottomBar => 'Use M3 bottom bar';

  @override
  String get prefUseM3BottomBarDesc =>
      'Replace the glass bottom bar with a standard Material 3 NavigationBar';

  @override
  String get prefBottomBarSearch => 'Bottom bar search entry';

  @override
  String get prefBottomBarSearchDesc =>
      'Show search in the recommend page bottom bar (glass: orphan button at the right; M3: extra destination; top bar search hidden when enabled)';

  @override
  String get prefWindowSection => 'Default window size';

  @override
  String get prefWindowSize => 'Startup window';

  @override
  String get prefRefreshSection => 'Refresh';

  @override
  String get prefRefreshDisplacement => 'Refresh trigger distance';

  @override
  String get prefRefreshDisplacementDesc =>
      'How far to drag down before the refresh triggers';

  @override
  String get prefRefreshEdgeOffset => 'Refresh indicator offset';

  @override
  String get prefRefreshEdgeOffsetDesc =>
      'Distance of the refresh indicator from the top edge';

  @override
  String get userSpaceFollowMutual => 'Mutual follow';

  @override
  String get userSpaceFollowBlocked => 'Blocked';

  @override
  String get userSpaceFollowDone => 'Following';

  @override
  String get userSpaceUnfollowDone => 'Unfollowed';

  @override
  String get userSpaceFollowFail => 'Operation failed, try again later';

  @override
  String get commonTapOutsideToClose => 'Tap outside to close';

  @override
  String get prefFileAssocSection => 'File associations';

  @override
  String get prefFileAssocDefault => 'Set as default app';

  @override
  String get prefFileAssocDefaultSub =>
      'Open video files with NaviFlash on double-click';

  @override
  String get msgCenterTitle => 'Message center';

  @override
  String get msgCenterSubtitle => 'Replies · Mentions · Likes · Messages';

  @override
  String get msgCenterLoginPrompt => 'Sign in to view the message center';

  @override
  String get msgReplyMe => 'Replies';

  @override
  String get msgAtMe => 'Mentions';

  @override
  String get msgLikedMe => 'Likes';

  @override
  String get msgSysNotice => 'Notifications';

  @override
  String get msgMyWhisper => 'Messages';

  @override
  String get msgWhisperSubtitle => 'Your private chats with creators';

  @override
  String msgUnreadCount(int count) {
    return '$count unread';
  }

  @override
  String get msgTimeJustNow => 'Just now';

  @override
  String msgTimeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String msgTimeYesterday(String time) {
    return 'Yesterday $time';
  }

  @override
  String get msgGoLogin => 'Sign in';

  @override
  String get msgDeleteNoticeConfirm => 'Delete this notification?';

  @override
  String get msgDeleted => 'Deleted';

  @override
  String msgLoginPromptFeature(String title) {
    return 'Sign in to view $title';
  }

  @override
  String get msgNoMore => 'No more results';

  @override
  String get msgReplyEmpty => 'No replies yet';

  @override
  String msgUserFallback(String mid) {
    return 'User $mid';
  }

  @override
  String get msgEtAl => ' and others';

  @override
  String msgReplyTitle(String business, int counts) {
    return ' commented $counts times on your $business';
  }

  @override
  String get msgAtEmpty => 'Nobody has mentioned you yet';

  @override
  String msgAtTitle(String business) {
    return ' mentioned you in $business';
  }

  @override
  String get msgDeleteNoticeTitle => 'Delete this notification?';

  @override
  String get msgDeleteNoticeBody => 'It reappears when you get new likes.';

  @override
  String get msgMuteNotice => 'Mute';

  @override
  String get msgMuteNoticeBody =>
      'You will no longer be notified about likes on this item, but it stays in the list.';

  @override
  String get msgSettingSaved => 'Saved';

  @override
  String get msgLoginPromptLikes => 'Sign in to view likes you received';

  @override
  String get msgLikedEmpty => 'No likes yet';

  @override
  String get msgLikedEmptySubtitle => 'Likes on your posts will show up here';

  @override
  String get msgSectionLatest => 'Latest';

  @override
  String get msgSectionTotal => 'Total';

  @override
  String get msgSomeone => 'Someone';

  @override
  String msgEtAlCount(String name, int count) {
    return '$name and $count others';
  }

  @override
  String get msgLikedYou => ' liked you';

  @override
  String msgLikedYourBusiness(String business) {
    return ' liked your $business';
  }

  @override
  String get msgNoticeMuted => 'Notifications off';

  @override
  String get msgUnmuteNotice => 'Unmute';

  @override
  String get msgLikeDetailTitle => 'Likes';

  @override
  String get msgLikeDetailEmpty => 'No likes yet';

  @override
  String get msgSysEmpty => 'No notifications yet';

  @override
  String get msgDeleteSessionTitle => 'Delete chat?';

  @override
  String get msgDeleteSessionBody =>
      'The chat is removed from the list and reappears if they message you again.';

  @override
  String get msgUnpinned => 'Unpinned';

  @override
  String get msgPinned => 'Pinned';

  @override
  String get msgUnpin => 'Unpin';

  @override
  String get msgPin => 'Pin chat';

  @override
  String get msgDeleteSession => 'Delete chat';

  @override
  String get msgLoginPromptWhisper => 'Sign in to view messages';

  @override
  String get msgWhisperEmpty => 'No chats yet';

  @override
  String get msgWhisperEmptySubtitle =>
      'Tap “Message” on a creator’s profile to start chatting';

  @override
  String get msgNoMessage => '[No messages]';

  @override
  String get msgWithdrawConfirm => 'Withdraw this message?';

  @override
  String get msgWithdraw => 'Withdraw';

  @override
  String get msgWithdrawn => 'Withdrawn';

  @override
  String get msgWithdrawnSelf => 'You withdrew a message';

  @override
  String get msgWithdrawnOther => 'The other person withdrew a message';

  @override
  String get msgChatEmpty => 'No messages yet';

  @override
  String get msgChatEmptySubtitle => 'Say hi';

  @override
  String get msgNoEarlier => 'No earlier messages';

  @override
  String get msgInputHint => 'Message…';

  @override
  String get msgPicture => '[Image]';

  @override
  String get msgPictureFailed => '[Image failed to load]';

  @override
  String get msgShare => '[Shared content]';

  @override
  String msgUnsupportedType(String type) {
    return '[Unsupported message type $type]';
  }

  @override
  String get msgVoice => '[Voice]';

  @override
  String get msgCardVideo => 'Video';

  @override
  String get msgCardArticle => 'Article';

  @override
  String get msgCardLive => 'Live';

  @override
  String get msgCardDynamic => 'Post';

  @override
  String get msgCardAlbum => 'Album';

  @override
  String get msgCardInvalid => 'Content unavailable';

  @override
  String get msgCardViewDetail => 'View details';

  @override
  String get msgAutoReply => 'This message is an auto reply';

  @override
  String get msgUploadingImage => 'Uploading image…';

  @override
  String get msgChatSettings => 'Chat settings';

  @override
  String get msgPushReceive => 'Receive message notifications';

  @override
  String get msgPushReceiveDesc =>
      'If disabled, you will no longer receive this user\'s image/text messages or video/article push notifications. Notification-type messages are unaffected.';

  @override
  String get msgPushCloseConfirm => 'Turn off content push?';

  @override
  String get msgPinChat => 'Pin chat';

  @override
  String get msgChatMute => 'Mute notifications';

  @override
  String get msgBlockAdd => 'Block user';

  @override
  String get msgBlockConfirmTitle => 'Block this user?';

  @override
  String get msgBlockConfirmBody =>
      'Blocking will unfollow the user and unsubscribe from their collections, and prevent them from interacting with you or viewing your space.';

  @override
  String get msgReport => 'Report';

  @override
  String msgReportTitle(String name) {
    return 'Report: $name';
  }

  @override
  String get msgReportContentHint =>
      'Report content (required, multiple choice)';

  @override
  String get msgReportReasonHint => 'Report reason (optional, single choice)';

  @override
  String get msgReportReasonRequired =>
      'Select at least one report content item';

  @override
  String get msgReportSuccess => 'Report submitted';

  @override
  String get msgReportFailed => 'Report failed';

  @override
  String get msgReportReasonAvatar => 'Inappropriate avatar';

  @override
  String get msgReportReasonNickname => 'Inappropriate nickname';

  @override
  String get msgReportReasonSign => 'Inappropriate signature';

  @override
  String get msgReportReasonPorn => 'Pornography or vulgarity';

  @override
  String get msgReportReasonFalse => 'False information';

  @override
  String get msgReportReasonForbidden => 'Prohibited content';

  @override
  String get msgReportReasonAttack => 'Personal attack';

  @override
  String get msgReportReasonFraud => 'Gambling or fraud';

  @override
  String get msgReportReasonLink => 'Illicit external links';

  @override
  String get msgRefresh => 'Refresh';

  @override
  String get commonSend => 'Send';

  @override
  String get commonRetry => 'Retry';

  @override
  String get msgInteractions => 'Community';

  @override
  String get msgLoadMore => 'Load more';

  @override
  String get dynamicsTitle => 'Dynamics';

  @override
  String get dynamicsTabAll => 'All';

  @override
  String get dynamicsTabVideo => 'Videos';

  @override
  String get dynamicsTabPgc => 'Anime';

  @override
  String get dynamicsTabArticle => 'Articles';

  @override
  String get dynamicsEmpty => 'No dynamics yet';

  @override
  String get dynamicsLoginPrompt =>
      'Sign in to see dynamics from creators you follow';

  @override
  String get onnxDepSection => 'Smart danmaku mask';

  @override
  String get onnxDepDesc =>
      'Smart danmaku masking needs the ONNX Runtime library and a segmentation model. Neither is bundled with the installer.';

  @override
  String get onnxDepNotInstalled => 'Not installed';

  @override
  String get onnxDepSizeCounting => 'Calculating…';

  @override
  String get onnxDepDownload => 'Download';

  @override
  String get onnxDepUninstall => 'Uninstall';

  @override
  String get onnxDepUninstallTitle => 'Remove smart mask files?';

  @override
  String get onnxDepUninstalled => 'Smart mask files removed';

  @override
  String get onnxDepInstallDone => 'Installed. Smart danmaku masking is ready.';

  @override
  String get onnxDepUnsupported =>
      'Smart danmaku masking is not supported on this platform';

  @override
  String get onnxDepSourceTitle => 'Download source';

  @override
  String get onnxDepSourceDesc =>
      'Custom download URL. Leave empty to use the built-in default.';

  @override
  String get onnxDepNeedInstall =>
      'Download the smart mask files first in Settings, then AI.';

  @override
  String get onnxDepSourceSaved => 'Download source updated';

  @override
  String onnxDepInstalled(String size) {
    return 'Installed · $size';
  }

  @override
  String onnxDepDownloading(String percent) {
    return 'Downloading $percent';
  }

  @override
  String onnxDepUninstallConfirm(String size) {
    return 'This deletes the runtime library and the model ($size). Smart masking stops working until you download them again.';
  }

  @override
  String onnxDepFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get favWidgetPickTitle => 'Choose a folder';

  @override
  String get favWidgetPickHint =>
      'The widget shows the newest saved items from this folder.';

  @override
  String get favWidgetNeedLogin => 'Sign in first to choose a folder.';

  @override
  String favWidgetFolderSwitched(String name) {
    return 'Now showing $name';
  }

  @override
  String get ossSearchHint => 'Search packages';

  @override
  String get ossClearSearch => 'Clear';

  @override
  String get ossDepsSection => 'Third-party dependencies';

  @override
  String get ossLoading => 'Collecting license information…';

  @override
  String get ossLoadFailed =>
      'Could not read the license registry. Try again later.';

  @override
  String get ossEmptySearch => 'No matching packages';

  @override
  String get ossRetry => 'Retry';

  @override
  String ossLicensesCount(int count) {
    return '$count licenses';
  }

  @override
  String ossLicenseIndex(int index, int total) {
    return 'License $index of $total';
  }

  @override
  String ossPackagesCount(int total, int licenses) {
    return '$total packages · $licenses license texts';
  }

  @override
  String get userPickerTitle => 'Select users';

  @override
  String get userPickerSearchHint => 'Search my follows';

  @override
  String get userPickerEmpty => 'No users found';

  @override
  String get userPickerLoadFailed => 'Failed to load';

  @override
  String get userPickerDone => 'Done';

  @override
  String get shortsTitle => 'Shorts';

  @override
  String get shortsEmpty => 'Nothing here yet';

  @override
  String get ttsSection => 'AI read-aloud engine';

  @override
  String get ttsModelLabel => 'Qwen3-TTS 1.7B';

  @override
  String get ttsDesc =>
      'Read articles, posts and comments aloud with voice cloning. The model is not bundled with the app and needs a one-time 1.4 GB download.';

  @override
  String get ttsNotInstalled => 'Not downloaded';

  @override
  String get ttsPartial => 'Download is incomplete, resume to finish it';

  @override
  String get ttsSizeCounting => 'Calculating...';

  @override
  String get ttsDownload => 'Download';

  @override
  String get ttsResume => 'Resume';

  @override
  String get ttsUninstall => 'Delete';

  @override
  String get ttsUninstallTitle => 'Delete the read-aloud engine?';

  @override
  String get ttsUninstalled => 'Read-aloud engine deleted';

  @override
  String get ttsInstallDone => 'Download complete. Read-aloud is ready.';

  @override
  String get ttsUnsupported => 'Read-aloud is not supported on this platform';

  @override
  String get ttsSourceTitle => 'Download source';

  @override
  String get ttsSourceDesc =>
      'Switch to a mirror if HuggingFace is unreachable, or enter a custom address';

  @override
  String get ttsSourceSaved => 'Download source updated';

  @override
  String get ttsMirrorOfficial => 'HuggingFace official';

  @override
  String get ttsMirrorChina => 'hf-mirror (recommended in China)';

  @override
  String get ttsMirrorCustom => 'Custom address';

  @override
  String get ttsEngineIdle => 'Not loaded, loads on first read-aloud';

  @override
  String get ttsEngineLoading => 'Loading the read-aloud engine...';

  @override
  String get ttsEngineReady => 'Engine ready';

  @override
  String get ttsEngineUnload => 'Release engine';

  @override
  String get ttsEngineUnloaded =>
      'Engine released, it reloads on the next read-aloud';

  @override
  String get ttsBackendTitle => 'Inference backend';

  @override
  String get ttsBackendAuto => 'Auto';

  @override
  String get ttsBackendNpu => 'NPU';

  @override
  String get ttsBackendGpu => 'GPU';

  @override
  String get ttsBackendCpu => 'CPU';

  @override
  String get ttsBackendAutoDesc =>
      'Prefer NPU on Qualcomm, fall back automatically';

  @override
  String get ttsBackendNpuDesc => 'Qualcomm Snapdragon NPU (Hexagon)';

  @override
  String get ttsBackendGpuDesc => 'Vulkan / Metal acceleration';

  @override
  String get ttsBackendCpuDesc => 'CPU only, best compatibility';

  @override
  String get ttsBackendNpuRuntimeMissing =>
      'This build does not bundle an NPU runtime yet; it runs on CPU for now';

  @override
  String get ttsBackendNpuHardwareUnsupported =>
      'NPU is only supported on Qualcomm Snapdragon; this device will fall back to CPU';

  @override
  String ttsEngineReadyOn(String name) {
    return 'Engine ready · $name';
  }

  @override
  String get ttsNeedInstall =>
      'Download the read-aloud engine first: Settings, then Storage.';

  @override
  String get ttsRuntimePending =>
      'Model is ready, the inference runtime is not wired up yet';

  @override
  String get ttsVoTitle => 'Voice (cloning)';

  @override
  String get ttsVoDesc =>
      'Pick 3 to 15 seconds of clear speech and read-aloud will use that voice';

  @override
  String get ttsVoEmpty => 'Not set, using the default voice';

  @override
  String get ttsVoPick => 'Pick audio';

  @override
  String get ttsVoAdded => 'Voice added';

  @override
  String get ttsVoDeleteTitle => 'Delete this voice?';

  @override
  String get ttsVoDeleted => 'Voice deleted';

  @override
  String get ttsVoDefault => 'Default voice';

  @override
  String get ttsVoUse => 'Use';

  @override
  String get ttsPickAudioTitle => 'Pick a voice sample';

  @override
  String get ttsVoUnsupportedFile => 'Please pick an audio file';

  @override
  String ttsInstalled(String size) {
    return 'Downloaded · $size';
  }

  @override
  String ttsDownloading(String percent) {
    return 'Downloading $percent';
  }

  @override
  String ttsDownloadingFile(String percent, String name) {
    return 'Downloading $percent · $name';
  }

  @override
  String ttsUninstallConfirm(String size) {
    return 'This deletes the model files ($size). Read-aloud stops working until you download them again.';
  }

  @override
  String ttsFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String ttsVoPickFailed(String error) {
    return 'Could not read the audio: $error';
  }

  @override
  String ttsVoDeleteConfirm(String name) {
    return 'This deletes the voice: $name.';
  }

  @override
  String ttsVoCount(String count) {
    return '$count voices saved';
  }

  @override
  String get ttsReadAloud => 'Read aloud';

  @override
  String get ttsReadAloudStop => 'Stop';

  @override
  String get ttsSynthesizing => 'Synthesizing speech...';

  @override
  String ttsSpeakFailed(String error) {
    return 'Read-aloud failed: $error';
  }

  @override
  String ttsTruncatedHint(String count) {
    return 'Long article: reading the first $count characters only';
  }

  @override
  String get playerOnlyPlayAudio => 'Listen only';

  @override
  String get playerOnlyPlayAudioDesc =>
      'Play sound only and hide the picture. Progress and speed are unaffected.';

  @override
  String videoBgmUsedCount(String count) {
    return 'Used by $count videos';
  }

  @override
  String get comic => 'Comics';

  @override
  String get memberShop => 'Member Shop';

  @override
  String get audioZone => 'Audio Zone';

  @override
  String get opusTab => 'Opus';

  @override
  String get matchInfo => 'Match';

  @override
  String get watchLive => 'Watch Live';

  @override
  String get interestStation => 'Interest Zone';

  @override
  String get noteManage => 'Notes';

  @override
  String get noteUnpublished => 'Unpublished';

  @override
  String get notePublished => 'Published';

  @override
  String get deleteSelected => 'Delete Selected';

  @override
  String get confirmDeleteNote => 'Delete the selected notes?';

  @override
  String get favTopic => 'My Topics';

  @override
  String get cancelFavTopic => 'Cancel following this topic?';

  @override
  String get inputIdTitle => 'Enter ID';

  @override
  String get inputIdHint => 'Enter the match or tribe ID';

  @override
  String get noContent => 'No content';

  @override
  String get bubbleAll => 'All';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleted => 'Deleted';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get confirm => 'Confirm';

  @override
  String get selectAll => 'Select All';

  @override
  String get loadFailed => 'Failed to load';

  @override
  String get videoMorePanelTitle => 'More';

  @override
  String get memberLiteTitle => 'Uploader';

  @override
  String get memberLiteViewFull => 'Open full profile';

  @override
  String get memberLiteEmpty => 'No videos yet';

  @override
  String get audioPageTitle => 'Listen';

  @override
  String get audioPageSpeed => 'Speed';

  @override
  String get audioPageRetry => 'Retry';

  @override
  String get playerListenPage => 'Listen to audio';

  @override
  String get playerOnlyPlayAudioInline => 'Audio only (stay here)';

  @override
  String memberLiteVideoCount(String count) {
    return '$count videos';
  }

  @override
  String get memberLiteGoSpace => 'Go to space';

  @override
  String get commentSortLatestDesc => 'Newest comments';

  @override
  String get commentSortHottestDesc => 'Top comments';

  @override
  String get commentSortLatestShort => 'Newest';

  @override
  String get commentSortHottestShort => 'Top';

  @override
  String get memberLiteOrderPubdate => 'Latest';

  @override
  String get memberLiteOrderClick => 'Most played';

  @override
  String get videoMenuWatchLater => 'Watch later';

  @override
  String get videoMenuReload => 'Reload';

  @override
  String get playerMenuStats => 'Playback info';

  @override
  String get playerMenuScreenshot => 'Screenshot';

  @override
  String get playerMenuAudioNorm => 'Volume normalization';

  @override
  String get playerMenuAudioDevice => 'Audio output device';

  @override
  String get playerMenuSource => 'Switch CDN';

  @override
  String get playerMenuEndBehavior => 'Play order';

  @override
  String get screenshotCopy => 'Copy to clipboard';

  @override
  String get screenshotCopied => 'Copied to clipboard';

  @override
  String get screenshotCopyUnsupported =>
      'Copying images to the clipboard is not supported on this platform';

  @override
  String get commonCopy => 'Copy';

  @override
  String get subtitleDownloadAll => 'Download all subtitles';

  @override
  String get subtitleDownloadPickDir => 'Choose where to save subtitles';

  @override
  String get subtitleDownloadNone => 'No subtitles available for this video';

  @override
  String get subtitleDownloadAllFailed => 'Subtitle download failed';

  @override
  String subtitleDownloadDone(String count, String dir) {
    return 'Saved $count subtitle files to $dir';
  }

  @override
  String get prefPerfSection => 'Performance';

  @override
  String get prefEfficiencyMode => 'Efficiency mode';

  @override
  String get prefEfficiencyModeSub =>
      'Schedule this app at the low power tier (EcoQoS). Saves battery when idling in the background, foreground feels slightly slower.';

  @override
  String get prefEfficiencyModeUnsupported =>
      'Efficiency mode is not supported on this system';

  @override
  String get prefEfficiencyModeReading => 'Reading…';

  @override
  String get prefEfficiencyModeActive =>
      'Active · scheduled at the low power tier';

  @override
  String get prefEfficiencyModeInactive => 'Not active';

  @override
  String prefEfficiencyModeFailed(String detail) {
    return 'Efficiency mode did not take effect ($detail)';
  }

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String get sleepTimerCustom => 'Custom…';

  @override
  String get sleepTimerStopAfterCurrent => 'Pause after this episode';

  @override
  String get sleepTimerStopAfterCurrentShort => 'after this episode';

  @override
  String get sleepTimerCancel => 'Cancel sleep timer';

  @override
  String get sleepTimerArmedToast => 'Sleep timer started';

  @override
  String get sleepTimerCancelledToast => 'Sleep timer cancelled';

  @override
  String get sleepTimerStopAfterCurrentArmedToast =>
      'Playback will pause after this episode';

  @override
  String get sleepTimerCustomDialogTitle => 'Custom sleep timer';

  @override
  String get sleepTimerCustomHint => 'Minutes';

  @override
  String get sleepTimerCustomUnit => 'min';

  @override
  String get sleepTimerInvalidNumber => 'Enter a valid number of minutes';

  @override
  String get settingsSleepTimerExitApp => 'Quit app when timer ends';

  @override
  String get settingsSleepTimerExitAppDesc =>
      'Pause playback when the timer fires, then quit NaviFlash (desktop only)';

  @override
  String sleepTimerMinutes(int min) {
    return '$min min';
  }

  @override
  String get playlistReversePlay => 'Reverse play';

  @override
  String get playlistReversePlayOn => 'Reverse play on';

  @override
  String get playlistReversePlayOff => 'Reverse play off';

  @override
  String get msgSettingsNotifSection => 'Notifications';

  @override
  String get msgSettingsReplyNotify => 'Reply notifications';

  @override
  String get msgSettingsReplyNotifyDesc =>
      '(Who can trigger reply notifications)';

  @override
  String get msgSettingsAtNotify => 'Mention notifications';

  @override
  String get msgSettingsAtNotifyDesc => '(Who can trigger @-notifications)';

  @override
  String get msgSettingsLikeNotify => 'Like notifications';

  @override
  String get msgSettingsLikeNotifyDesc =>
      '(Who can trigger like notifications)';

  @override
  String get msgSettingsNotifyEveryone => 'Everyone';

  @override
  String get msgSettingsNotifyFollowing => 'People I follow';

  @override
  String get msgSettingsNotifyNone => 'Do not notify';

  @override
  String get msgSettingsReceiveSection => 'Message receiving';

  @override
  String get msgSettingsReceiveUnfollow => 'DMs from non-followed users';

  @override
  String get msgSettingsReceiveUnfollowDesc =>
      '(If turned off, you will no longer receive DMs from non-followed users; notification messages are unaffected)';

  @override
  String get msgSettingsUnfollowFold => 'Fold DMs from non-followed users';

  @override
  String get msgSettingsUnfollowFoldDesc =>
      '(DMs from non-followed users will be folded)';

  @override
  String get msgSettingsGroupReceive => 'Receive fan-club messages';

  @override
  String get msgSettingsGroupFold => 'Fold fan-club messages';

  @override
  String get msgSettingsSmartIntercept => 'Smart DM filtering';

  @override
  String get msgSettingsSmartInterceptDesc =>
      '(When on, only DMs / comments / danmaku from specified users reach you for 7 days, and @-notifications are stopped)';

  @override
  String get msgSettingsAntiHarassmentSection => 'Anti-harassment';

  @override
  String get msgSettingsAntiHarassment => 'Anti-harassment settings';

  @override
  String get msgSettingsScopeSelect => 'Who can send you DMs';

  @override
  String msgSettingsValidUntil(String time) {
    return '(Valid until $time)';
  }

  @override
  String get prefEfficiencyModeAutoDesc =>
      'Normal performance in the foreground; enters efficiency mode after 3 minutes in the background and restores instantly on return. Skipped while playing.';
}

                                                                         
class AppLocalizationsEnUs extends AppLocalizationsEn {
  AppLocalizationsEnUs() : super('en_US');

  @override
  String metroDate(int month, int day) {
    return '$month/$day';
  }

  @override
  String get metroSunday => 'Sunday';

  @override
  String get metroMonday => 'Monday';

  @override
  String get metroTuesday => 'Tuesday';

  @override
  String get metroWednesday => 'Wednesday';

  @override
  String get metroThursday => 'Thursday';

  @override
  String get metroFriday => 'Friday';

  @override
  String get metroSaturday => 'Saturday';

  @override
  String get metroLogin => 'Log in';

  @override
  String get metroWelcome => 'Welcome';

  @override
  String get imageViewerNoFile => 'Image file not found';

  @override
  String get syncPassphraseEmpty => 'Sync passphrase cannot be empty';

  @override
  String get imageBytesRequired => 'Provide either imageUrl or imageBytes';

  @override
  String get webdavConnectSuccess => 'Connected!';

  @override
  String get webdavConfigSaved => 'Configuration saved';

  @override
  String get webdavConfigureFirst =>
      'Configure and test the WebDAV connection first';

  @override
  String get webdavSelectContactsFirst =>
      'Select the contacts to back up below first';

  @override
  String get webdavNoFiles => 'The selected contacts have no files to back up';

  @override
  String get webdavConfirmBackup => 'Confirm backup';

  @override
  String webdavBackupConfirm(int contacts, int files, String path) {
    return 'Back up $files files from $contacts contacts to the WebDAV server.\nRemote path: $path/chats/<nickname>/';
  }

  @override
  String get webdavStartBackup => 'Start backup';

  @override
  String get webdavBackingUpTitle => 'Backing up';

  @override
  String get webdavBackupDoneTitle => 'Backup done';

  @override
  String webdavTotalFiles(int count) {
    return 'Total: $count files';
  }

  @override
  String webdavSuccessCount(int count) {
    return 'Succeeded: $count';
  }

  @override
  String webdavFailCount(int count) {
    return 'Failed: $count';
  }

  @override
  String webdavMoreErrors(int count) {
    return '...$count more errors';
  }

  @override
  String get webdavBackupFab => 'Backup';

  @override
  String get webdavShowInfo => 'Show my info';

  @override
  String get webdavHideInfo => 'Hide my info';

  @override
  String get webdavScanToFill => 'Scan to fill the server URL';

  @override
  String get webdavScanFilled => 'Address filled from QR code';

  @override
  String get webdavServerConfig => 'Server configuration';

  @override
  String get webdavServerUrlLabel => 'Server URL';

  @override
  String get webdavUsernameLabel => 'Username';

  @override
  String get webdavPasswordLabel => 'Password';

  @override
  String get webdavRemotePathLabel => 'Remote backup path';

  @override
  String get webdavTesting => 'Testing...';

  @override
  String get webdavSaveAndTest => 'Save and test connection';

  @override
  String get webdavSaveOnly => 'Save only';

  @override
  String get webdavConnectVerified => 'Connection verified';

  @override
  String get webdavAutoBackup => 'Auto backup';

  @override
  String get webdavAutoBackupOnReceive => 'Auto back up received files';

  @override
  String get webdavAutoBackupSubtitle =>
      'Applies only to the selected contacts below';

  @override
  String get webdavMediaSync => 'Media sync';

  @override
  String get webdavSyncPlaylists => 'Sync playlists';

  @override
  String get webdavSyncDanmaku => 'Sync danmaku';

  @override
  String get webdavPassphraseEncrypted => 'Sync passphrase (AES-256 encrypted)';

  @override
  String get webdavPassphrasePlain =>
      'Sync passphrase (leave empty = plain upload)';

  @override
  String get webdavPassphraseHint =>
      'Playlists will be uploaded encrypted once a passphrase is set';

  @override
  String get webdavGeneratePassphrase => 'Generate random passphrase';

  @override
  String get webdavMediaSyncHint =>
      'Playlists (including backgrounds) and danmaku are stored in separate cloud directories (playlists/, danmaku/), so they won\'t mix with chat backups. Devices sharing the same remote path can merge with each other; playlists can also be synced manually or restored from the cloud on the playlist page.';

  @override
  String get webdavEncryptionOn =>
      'Encryption enabled: playlists are uploaded encrypted with AES-256-GCM (including embedded WebDAV auth), so the server cannot read the content. Other devices must use the same passphrase to decrypt.';

  @override
  String get webdavEncryptionOff =>
      'Not encrypted: playlists (including embedded WebDAV auth) are uploaded in plaintext. Anyone with server access can read them. Not recommended.';

  @override
  String get webdavBackupContacts => 'Backup contacts';

  @override
  String webdavSelectedContacts(int selected, int total) {
    return '$selected / $total contacts selected';
  }

  @override
  String get webdavSearchContacts => 'Search contacts or IP...';

  @override
  String get webdavDeselectAll => 'Deselect all';

  @override
  String webdavFileCount(int count) {
    return '$count files';
  }

  @override
  String get webdavNoContacts => 'No contacts';

  @override
  String get webdavNoMatch => 'No matches';

  @override
  String webdavContactSubtitle(String ip, int count) {
    return '$ip  ·  $count files';
  }

  @override
  String get webdavManage => 'Manage';

  @override
  String get webdavLastSync => 'Last sync';

  @override
  String get webdavLastError => 'Last error';

  @override
  String get webdavClearConfig => 'Clear WebDAV configuration';

  @override
  String get webdavClearConfigSubtitle =>
      'Delete all server info and credentials';

  @override
  String get webdavUserLabel => 'User';

  @override
  String webdavStatusActive(String name) {
    return '$name active';
  }

  @override
  String webdavStatusConfigured(String name) {
    return '$name configured';
  }

  @override
  String get webdavStatusNotConfigured => 'Not configured';

  @override
  String get webdavNotSynced => 'Not synced yet';

  @override
  String get webdavJustNow => 'Last sync: just now';

  @override
  String webdavMinutesAgo(int minutes) {
    return 'Last sync: $minutes minutes ago';
  }

  @override
  String webdavHoursAgo(int hours) {
    return 'Last sync: $hours hours ago';
  }

  @override
  String webdavSyncedDate(int month, int day, String time) {
    return 'Last sync: $month/$day $time';
  }

  @override
  String get webdavPassphraseGenerated =>
      'A sync passphrase was generated and copied to the clipboard. Enter the same passphrase on other devices';

  @override
  String get webdavConfirmClear => 'Confirm clearing';

  @override
  String get webdavClearConfirmText =>
      'This deletes all WebDAV configuration (server, credentials, selected contacts).\nAlready uploaded files are not affected.';

  @override
  String get profileEditProfile => 'Edit profile';

  @override
  String get profileAccountSection => 'Account';

  @override
  String get profileWebdavBackup => 'WebDAV backup';

  @override
  String profileWebdavLoggedIn(String username) {
    return '$username logged in';
  }

  @override
  String get profileNotLoggedIn => 'Not logged in';

  @override
  String get profileAvatarSection => 'Avatar';

  @override
  String get profileChangeAvatar => 'Change avatar';

  @override
  String get profileRemoveAvatar => 'Remove avatar';

  @override
  String get profilePickFromGallery => 'Pick an image from the gallery';

  @override
  String get profileRestoreDefaultAvatar => 'Restore default avatar';

  @override
  String get profileSetBackground => 'Set background';

  @override
  String get profileBgSubtitle => 'Choose a background image for the sidebar';

  @override
  String get profileRestoreDefault => 'Restore default';

  @override
  String get profileBgRemoveSubtitle =>
      'Remove the custom background and use the theme gradient';

  @override
  String get profileInfoSection => 'Profile info';

  @override
  String get profileNicknameLabel => 'Nickname';

  @override
  String get profileNotSet => 'Not set';

  @override
  String get profileBgTitle => 'Profile background';

  @override
  String get profileAvatarUpdated => 'Avatar updated';

  @override
  String profileAvatarFailed(String error) {
    return 'Failed to pick avatar: $error';
  }

  @override
  String get profileRemoveAvatarConfirm =>
      'Remove the current avatar? This cannot be undone.';

  @override
  String get profileAvatarRemoved => 'Avatar removed';

  @override
  String get profileSetNickname => 'Set nickname';

  @override
  String get profileNicknameHint => 'Enter nickname';

  @override
  String get profileNicknameEmpty => 'Nickname cannot be empty';

  @override
  String get profileNicknameUpdated => 'Nickname updated';

  @override
  String get colorDefaultGreen => 'Default green';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorRed => 'Red';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorAmber => 'Amber';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorLime => 'Lime';

  @override
  String get colorLightGreen => 'Light green';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorCyan => 'Cyan';

  @override
  String get colorTeal => 'Teal';

  @override
  String get colorLightBlue => 'Light blue';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorIndigo => 'Indigo';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorDeepPurple => 'Deep purple';

  @override
  String get colorBlueGrey => 'Blue gray';

  @override
  String get colorBrown => 'Brown';

  @override
  String get colorGrey => 'Gray';

  @override
  String get themeColorExtracted => 'Theme color extracted from image';

  @override
  String themeColorFailed(String error) {
    return 'Failed to pick color: $error';
  }

  @override
  String get themeImageOnly => 'Only image formats are supported';

  @override
  String get themeTitle => 'Theme';

  @override
  String themeColorCopied(String hex) {
    return 'Color code copied: $hex';
  }

  @override
  String get themeAppearance => 'Appearance';

  @override
  String get themeDarkBlackened => 'Dark mode (pure black)';

  @override
  String get themeOff => 'Off';

  @override
  String get themeEnabled => 'On';

  @override
  String get themeColorsSection => 'Colors';

  @override
  String get themePaletteStyle => 'Palette style';

  @override
  String get themeFollowSystem => 'Follow system colors';

  @override
  String get themePickColor => 'Pick a color';

  @override
  String get themeDropHint =>
      'Release to extract the theme color from the image';

  @override
  String get themeNewTheme => 'New theme';

  @override
  String themeSwitched(String name) {
    return 'Switched to the $name theme';
  }

  @override
  String get themeDeleteTitle => 'Delete theme';

  @override
  String themeDeleteConfirm(String name) {
    return 'Delete the custom theme \"$name\"?';
  }

  @override
  String themeDeleted(String name) {
    return '\"$name\" deleted';
  }

  @override
  String get themeCreateTitle => 'Create custom theme';

  @override
  String get themeNameLabel => 'Theme name';

  @override
  String get themeNameHint => 'Enter text';

  @override
  String get themeHexLabel => 'Hex / RGB';

  @override
  String get themeHexHint => 'e.g. #FF0000 or 255,0,0';

  @override
  String themeCreated(String name) {
    return 'Theme \"$name\" created and saved';
  }

  @override
  String get themeCopyColor => 'Copy color code';

  @override
  String get themePickFromImage => 'Pick color from image';

  @override
  String get searchBack => 'Back to settings';

  @override
  String get searchHint => 'Search settings…';

  @override
  String get searchPrompt => 'Type keywords to search settings';

  @override
  String get searchExamples => 'e.g. refresh rate / decode / UA / danmaku';

  @override
  String searchNoResults(String query) {
    return 'No settings found for \"$query\"';
  }

  @override
  String get searchThemeMode => 'Theme mode';

  @override
  String get searchPureBlack => 'Pure black dark mode';

  @override
  String get searchThemeColor => 'Theme colors';

  @override
  String get searchFontWeight => 'Font weight';

  @override
  String get searchDisplayScale => 'Display scale';

  @override
  String get searchDisplayMode => 'Display mode / refresh rate';

  @override
  String get searchStatusBar => 'Status bar';

  @override
  String get searchKeepWindowRatio => 'Keep window aspect ratio';

  @override
  String get searchLongPressSpeed => 'Hold to speed up';

  @override
  String get searchScreenshot => 'Screenshot';

  @override
  String get searchScreenshotDanmaku => 'Show danmaku in screenshots';

  @override
  String get searchPlayProgress => 'Playback progress';

  @override
  String get searchHwdec => 'Hardware decoding';

  @override
  String get searchVideoSync => 'Video sync';

  @override
  String get searchImmersiveLongPress => 'Immersive hold-to-speed';

  @override
  String get searchMpvLog => 'Log mpv output';

  @override
  String get searchMpvLogLevel => 'mpv log level';

  @override
  String get searchNetworkMode => 'Network mode';

  @override
  String get searchInsecureCert => 'Allow insecure certificates';

  @override
  String get searchChatIpv6 => 'Chat IPv6';

  @override
  String get searchConnectivityTest => 'Connectivity test';

  @override
  String get searchHostOverrides => 'Host overrides';

  @override
  String get searchDohQuery => 'DoH query';

  @override
  String get searchReferer => 'Referer header';

  @override
  String get searchUserAgent => 'User-Agent header';

  @override
  String get searchSystemSettings => 'System settings';

  @override
  String get searchUserSettings => 'User settings';

  @override
  String get settingsDisplaySub => 'Theme, fonts, layout';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsSystemSub => 'Language, storage, permissions';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsStorageSub => 'Image cache, danmaku cache';

  @override
  String get settingsNetwork => 'Network';

  @override
  String get settingsNetworkSub => 'Wi-Fi, proxy, sync';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSub => 'App language, Bilibili AI translation';

  @override
  String get ttsDownloadCancel => 'Cancel download';

  @override
  String get ttsDownloadDoneTitle => 'TTS model downloaded';

  @override
  String get ttsDownloadDoneBody =>
      'You can now use read-aloud in comments and articles. Downloads resume and keep running in the background.';

  @override
  String get ttsNoInstallTitle => 'Read aloud';

  @override
  String get ttsNoInstallHeading =>
      'TTS is not installed yet. What would you like to do?';

  @override
  String get ttsNoInstallDownload => 'Download TTS';

  @override
  String get ttsNoInstallDownloadSub => 'Pull the model from Hugging Face';

  @override
  String get ttsNoInstallLater => 'Never mind';

  @override
  String get ttsNoInstallLaterSub => 'Maybe later';

  @override
  String get ttsInstallPageTitle => 'Download the TTS model';

  @override
  String get ugcFilterWindowTitle => 'Find and Replace';

  @override
  String get ugcFilterResultPrefix => 'Results: ';

  @override
  String get ugcFilterDeleteMatchesPlain => 'Delete matches';

  @override
  String get ugcFilterTitle => 'Filter settings';

  @override
  String get ugcFilterSectionScopes => 'UGC keyword filters';

  @override
  String get ugcFilterScopeRecommend => 'Home feed';

  @override
  String get ugcFilterScopeRecommendSub => 'Hide videos whose title matches';

  @override
  String get ugcFilterScopeZone => 'Zones';

  @override
  String get ugcFilterScopeZoneSub =>
      'Applies to the app feed, popular and ranking only';

  @override
  String get ugcFilterScopeReply => 'Comments';

  @override
  String get ugcFilterScopeReplySub => 'Hide comments whose content matches';

  @override
  String get ugcFilterScopeDyn => 'Dynamics';

  @override
  String get ugcFilterScopeDynSub => 'Hide dynamics whose content matches';

  @override
  String get ugcFilterEmpty => 'No keywords yet; type above and tap Add';

  @override
  String get ugcFilterAddHint => 'Keyword or regex';

  @override
  String get ugcFilterAdd => 'Add';

  @override
  String get ugcFilterEdit => 'Edit keyword';

  @override
  String get ugcFilterDelete => 'Delete';

  @override
  String get ugcFilterClear => 'Clear all';

  @override
  String get ugcFilterDup => 'Already exists, skipped';

  @override
  String get ugcFilterInvalid => 'Not a valid regular expression';

  @override
  String get ugcFilterDeleted => 'Deleted';

  @override
  String get ugcFilterCleared => 'Cleared';

  @override
  String get ugcFilterNoResult => 'No match';

  @override
  String get ugcFilterMenuMore => 'More';

  @override
  String get ugcFilterMenuClipboard => 'Import from clipboard';

  @override
  String get ugcFilterMenuFile => 'Import from file';

  @override
  String get ugcFilterMenuExport => 'Export';

  @override
  String get ugcFilterMenuWebdav => 'Export to WebDAV';

  @override
  String get ugcFilterImportEmpty => 'Clipboard has no text';

  @override
  String get ugcFilterExportEmpty => 'Nothing to export';

  @override
  String get ugcFilterFindReplace => 'Find and replace';

  @override
  String get ugcFilterFind => 'Find';

  @override
  String get ugcFilterReplace => 'Replace';

  @override
  String get ugcFilterPrev => 'Previous';

  @override
  String get ugcFilterNext => 'Next';

  @override
  String get ugcFilterReplaceOne => 'Replace';

  @override
  String get ugcFilterReplaceAll => 'All';

  @override
  String get ugcFilterHistory => 'History';

  @override
  String get ugcFilterClearHistory => 'Clear find history';

  @override
  String get ugcFilterCaseSensitive => 'Case sensitive';

  @override
  String get ugcFilterWholeWord => 'Whole keyword must match';

  @override
  String get ugcFilterRegex => 'Regular expression';

  @override
  String get ugcFilterTip =>
      'Every keyword is a regular expression (case-insensitive). Cc = case sensitive, W = the whole keyword must match, .* = treat the find field as a regex. Import merges and dedupes (nothing is overwritten); export is plain text, one per line.';

  @override
  String ugcFilterRulesCount(int count) {
    return '$count rules';
  }

  @override
  String ugcFilterAdded(int count) {
    return 'Added $count';
  }

  @override
  String ugcFilterResultCount(int count) {
    return 'Results: $count';
  }

  @override
  String ugcFilterReplaced(int count) {
    return 'Replaced $count';
  }

  @override
  String ugcFilterDeletedMatches(int count) {
    return 'Delete matches ($count)';
  }

  @override
  String ugcFilterImported(int added, int skipped) {
    return 'Imported $added, skipped $skipped duplicates';
  }

  @override
  String ugcFilterImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String ugcFilterExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String ugcFilterWebdavOk(String name) {
    return 'Uploaded to WebDAV: $name';
  }

  @override
  String ugcFilterWebdavFail(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get prefLinkSection => 'Link handling';

  @override
  String get settingsRecommend => 'Recommend feed';

  @override
  String get settingsRecommendSub => 'Source, filters and refresh behaviour';

  @override
  String get rcmdSectionSource => 'Source';

  @override
  String get rcmdUseAppSource => 'Use app-side recommendations';

  @override
  String get rcmdUseAppSourceSub =>
      'Switch to the app feed when the web feed disappoints';

  @override
  String get rcmdSectionBehavior => 'Refresh and keep';

  @override
  String get rcmdKeepLastData => 'Keep previous feed on refresh';

  @override
  String get rcmdKeepLastDataSub => 'Pull to refresh keeps the previous items';

  @override
  String get rcmdSavedPositionTip => 'Show last-seen position tip';

  @override
  String get rcmdSavedPositionTipSub =>
      'Insert a tip where the previous items start';

  @override
  String get rcmdSavedPositionTipText => 'You stopped here';

  @override
  String get rcmdSectionFilter => 'Filters';

  @override
  String get rcmdNoFilter => 'No filter';

  @override
  String get rcmdMinLikeRatio => 'Like ratio';

  @override
  String get rcmdMinLikeRatioSub => 'Hide videos below this like ratio';

  @override
  String get rcmdMinDuration => 'Duration';

  @override
  String get rcmdMinDurationSub => 'Hide videos shorter than this';

  @override
  String get rcmdMinPlay => 'Views';

  @override
  String get rcmdMinPlaySub => 'Hide videos below this view count';

  @override
  String get rcmdBanWord => 'Title keyword filter';

  @override
  String get rcmdBanWordSub => 'Regular expression; matching titles are hidden';

  @override
  String get rcmdBanWordHint => 'Not set';

  @override
  String get rcmdBanZone => 'Zone keyword filter';

  @override
  String get rcmdBanZoneSub =>
      'Applies to the app feed, popular and ranking only';

  @override
  String get rcmdBanZoneHint => 'Not set';

  @override
  String get rcmdExemptFollowed => 'Exempt followed uploaders';

  @override
  String get rcmdExemptFollowedSub => 'Content from followed uploaders is kept';

  @override
  String get rcmdFilterRelated => 'Apply filters to related videos';

  @override
  String get rcmdFilterRelatedSub =>
      'Popular, search and other entries are unaffected';

  @override
  String get rcmdFilterHint =>
      'Filters apply on the next fetch. Keywords are regular expressions; leave empty to disable.';

  @override
  String get rcmdFilterSaved => 'Saved; applies on the next fetch';

  @override
  String get prefOpenSupportedLinks => 'Open supported links';

  @override
  String get prefOpenSupportedLinksSub =>
      'Set this app as the default handler for bilibili / memz2345.top links';

  @override
  String get linkSettingsUnavailable =>
      'Could not open system settings; look for the default-handler entry manually';

  @override
  String get appLangSection => 'App language';

  @override
  String get appLangFollowSystem => 'Follow system';

  @override
  String get biliLangSection => 'Target language';

  @override
  String get biliAiSection => 'AI Translation';

  @override
  String get biliAiTranslateEnable => 'Enable AI translation';

  @override
  String get biliAiTranslateOnDesc =>
      'Enabled: Bilibili requests carry translation headers';

  @override
  String get biliAiTranslateOffDesc =>
      'Disabled: content stays in the original language';

  @override
  String get langZhCn => '简体中文 (Simplified Chinese)';

  @override
  String get langZhHk => '繁體中文 (Traditional Chinese, HK)';

  @override
  String get langZhTw => '繁體中文 (Traditional Chinese, TW)';

  @override
  String get langEnUs => 'English';

  @override
  String get langJaJp => '日本語 (Japanese)';

  @override
  String get langKoKr => '한국어 (Korean)';

  @override
  String get settingsPlayer => 'Player';

  @override
  String get settingsPlayerSub => 'Status bar, speed, screenshots';

  @override
  String get settingsStartScreenSub => 'Start screen, Charm';

  @override
  String get settingsLogs => 'Logs';

  @override
  String get settingsLogsSub => 'Error logs, mpv logs';

  @override
  String get settingsAccounts => 'Accounts';

  @override
  String get settingsAccountsSub => 'Bilibili, WebDAV';

  @override
  String get settingsUser => 'User';

  @override
  String get settingsUserSub => 'Account, privacy, security';

  @override
  String get settingsAboutSub => 'Version, licenses';

  @override
  String get settingsLicenses => 'Open source licenses';

  @override
  String get settingsLicensesSub => 'Open source projects used by this app';

  @override
  String get settingsSearch => 'Search settings';

  @override
  String get openSidebar => 'Open sidebar';

  @override
  String get settingsPlaceholderEasterEgg =>
      'Hmm, why not ask the wonderful Frieren?';

  @override
  String storageClearTitle(String label) {
    return 'Clear $label';
  }

  @override
  String storageClearConfirm(String label) {
    return 'Clear $label? Images will be re-downloaded when viewed again.';
  }

  @override
  String get storageClear => 'Clear';

  @override
  String storageCleared(String label) {
    return '$label cleared';
  }

  @override
  String get refreshAction => 'Refresh';

  @override
  String get storageCacheSection => 'Cache';

  @override
  String get storageUsageBreakdown => 'Usage breakdown';

  @override
  String get storageUsageTotal => 'Total used';

  @override
  String get storageUsageEmpty => 'Nothing to count yet';

  @override
  String get storageDataCache => 'Data cache';

  @override
  String get storageAiDeps => 'AI components';

  @override
  String get storageImageCache => 'Image cache';

  @override
  String get storageCounting => 'Counting…';

  @override
  String storageFileCount(int count, String size) {
    return '$count files · $size';
  }

  @override
  String get storageDanmakuCache => 'Danmaku cache';

  @override
  String storageVideoCount(int count, String size) {
    return '$count videos · $size';
  }

  @override
  String get settingsAutoOfflineCache => 'Auto cache played videos';

  @override
  String get settingsAutoOfflineCacheHint =>
      'Videos you watch are saved locally (about a 2 GB cap, oldest evicted when full), and play from disk next time without re-downloading. Turn off to stop adding new caches.';

  @override
  String get storageVideoCache => 'Offline video cache';

  @override
  String get storageVideoCacheDesc =>
      'Media of played videos (auto-cached within the size cap, LRU evicted); plays from disk next time';

  @override
  String get storageMemoryCache => 'In-memory image cache';

  @override
  String get storageMemoryCacheDesc =>
      'Images decoded during this session; freed automatically on exit';

  @override
  String get storageClearing => 'Clearing…';

  @override
  String get storageClearAll => 'Clear all cache';

  @override
  String get storageCacheHint =>
      'The image cache is the app\'s private directory (image_cache); cleared comment images will be re-downloaded. The danmaku cache is used for offline danmaku.';

  @override
  String get storageClearAllTitle => 'Clear all cache';

  @override
  String get storageClearAllConfirm =>
      'This clears the image cache, danmaku cache and in-memory image cache. Images will be re-downloaded when viewed again.';

  @override
  String get storageAllCleared => 'All cache cleared';

  @override
  String get storageLocationSection => 'Storage locations';

  @override
  String get storageLocationAutoCache => 'Auto cache location';

  @override
  String get storageLocationAutoCacheDesc =>
      'Where playback cache, images, danmaku and articles are stored';

  @override
  String get storageLocationVideo => 'Video download location';

  @override
  String get storageLocationVideoDesc =>
      'Where videos you cache manually are saved';

  @override
  String get storageLocationModels => 'AI models location';

  @override
  String get storageLocationModelsDesc =>
      'AI narration models and the anti-occlusion dependency';

  @override
  String get storageLocationDefault => 'System default';

  @override
  String get storageLocationUnsupported => 'Not customizable on this platform';

  @override
  String get storageLocationChoose => 'Change';

  @override
  String get storageLocationPick => 'Choose folder';

  @override
  String get storageLocationNewFolder => 'New subfolder';

  @override
  String get storageLocationFolderName => 'Folder name';

  @override
  String get storageLocationCreateFailed =>
      'Could not create it, try another name';

  @override
  String get storageLocationReset => 'Reset to default';

  @override
  String get storageLocationResetDone => 'Reset to the default location';

  @override
  String storageLocationCurrent(String path) {
    return 'Current: $path';
  }

  @override
  String storageLocationSetDone(String path) {
    return 'Set to $path';
  }

  @override
  String storageLocationFree(String size) {
    return '$size available';
  }

  @override
  String get storageLocationNotWritable =>
      'Not writable, fell back to the default location';

  @override
  String get storageLocationAndroidHint =>
      'On Android you can only pick the system standard folders (Movies, Download, Documents, also on the SD card) or the app private folder, and create subfolders inside them';

  @override
  String get storageLocationKeepOld =>
      'Files in the old location are kept and still readable; new downloads go to the new one';

  @override
  String get ttsLiveDownloadTitle => 'AI narration model download';

  @override
  String get settingsAi => 'AI';

  @override
  String get settingsAiSub =>
      'Smart occlusion and AI narration: models, mirrors, inference device';

  @override
  String get bottomNavPreviewHint =>
      'The bar at the bottom is a live preview: on Android it is the native glass bar itself';

  @override
  String get bottomNavResetDone => 'Reset to default';

  @override
  String get verificationPendingRequests => 'Pending requests';

  @override
  String get verificationNoPending => 'No pending requests';

  @override
  String verificationIpAddress(String ip) {
    return 'IP address: $ip';
  }

  @override
  String verificationNickname(String name) {
    return 'Nickname: $name';
  }

  @override
  String verificationRequestTime(String time) {
    return 'Request time: $time';
  }

  @override
  String get verificationRejectInvalid => 'Cannot reject: invalid IP address';

  @override
  String get verificationRejected => 'Connection request rejected';

  @override
  String get verificationReject => 'Reject';

  @override
  String get verificationAcceptInvalid => 'Cannot accept: invalid IP address';

  @override
  String get verificationAccepted => 'Connection request accepted';

  @override
  String get verificationAccept => 'Accept';

  @override
  String get startScreenWarning => 'This project may no longer be updated';

  @override
  String get startScreenTitle => 'Start screen';

  @override
  String get startScreenGoBack => 'Navigate up';

  @override
  String get enableStartScreen => 'Enable start screen';

  @override
  String get startScreenEnableSubtitle =>
      'Allow opening the start screen from the Charm Start button';

  @override
  String get enableCharm => 'Enable Charm';

  @override
  String get charmEnableSubtitle =>
      'Show the Charm bar on the right edge of the screen';

  @override
  String get charmGestureTitle => 'Gesture to open Charm';

  @override
  String get charmGestureSubtitle =>
      'Swipe left from the right edge or hover the top-right corner to open Charm';

  @override
  String get externalVideo => 'External video';

  @override
  String get audioChannelName => 'Video media playback';

  @override
  String get foregroundChannelName => 'Navi keep-alive';

  @override
  String get foregroundChannelDesc => 'Keep me running in the background';

  @override
  String get foregroundTitle => 'Keeping alive';

  @override
  String get foregroundText => 'Verifying';

  @override
  String get drawerBilibiliSearch => 'Bilibili Search';

  @override
  String get recommendBottomHome => 'Home';

  @override
  String get recommendBottomLive => 'Live';

  @override
  String get commentImageLoadFail => 'Image failed to load';

  @override
  String get commentDetailTitle => 'Comment Details';

  @override
  String get commentLikeLoginRequired =>
      'Please log in to your Bilibili account (and enable sending cookies) before liking';

  @override
  String commentLikeFail(String error) {
    return 'Like failed: $error';
  }

  @override
  String get relatedEmpty => 'No related videos';

  @override
  String get biliLoadFailed => 'Failed to load';

  @override
  String countWan(String count) {
    return '${count}W';
  }

  @override
  String countYi(String count) {
    return '${count}M';
  }

  @override
  String get searchNoNewContent => 'No new content';

  @override
  String get searchNewContentRefreshed =>
      'Refreshed with a new batch of content';

  @override
  String get biliDialogNeedLogin => 'Login required';

  @override
  String get biliDialogInteractDesc =>
      'Likes, coins, triple-send and other interactions require logging in to a Bilibili account';

  @override
  String get biliGoLogin => 'Go to login';

  @override
  String get biliCookieScopeHint =>
      'Enable \"Carry Cookie\" and the \"Interactions\" scope in Account settings';

  @override
  String get videoTabRelated => 'Related';

  @override
  String get videoTabComments => 'Comments';

  @override
  String videoTabCommentsCount(int count) {
    return 'Comments $count';
  }

  @override
  String videoTabEpisodes(int count) {
    return 'Episodes $count';
  }

  @override
  String get videoTabIntro => 'Intro';

  @override
  String danmakuWatching(String count) {
    return '$count watching';
  }

  @override
  String danmakuLoadedBar(String count) {
    return '$count danmaku loaded';
  }

  @override
  String get danmakuToggleOn => 'Enable danmaku';

  @override
  String get danmakuDisable => 'Disable danmaku';

  @override
  String get danmakuInputHint => 'Post a friendly danmaku to mark this moment';

  @override
  String get danmakuToastEmpty => 'Danmaku text cannot be empty';

  @override
  String danmakuToastSendFail(String error) {
    return 'Failed to send: $error';
  }

  @override
  String get danmakuToastSent => 'Danmaku sent';

  @override
  String get videoLikeTooltip => 'Like (long-press for triple-send)';

  @override
  String get videoUnlikeTooltip => 'Unlike';

  @override
  String get videoCoinTooltip => 'Coin';

  @override
  String get videoFavTooltip => 'Favorite';

  @override
  String get videoUnfavTooltip => 'Unfavorite';

  @override
  String get videoShareLabel => 'Share';

  @override
  String videoStatRating(String count) {
    return '$count rated';
  }

  @override
  String videoStatFollowing(String count) {
    return '$count following';
  }

  @override
  String videoStatWatching(String count) {
    return '$count watching';
  }

  @override
  String get videoFollowLabel => 'Follow';

  @override
  String get videoFollowedLabel => 'Following';

  @override
  String get commentDetailEmpty => 'No replies yet';

  @override
  String commentDetailNoMore(int count) {
    return 'No more replies ($count total)';
  }

  @override
  String get commentDetailLoadMore => 'Scroll to load more';

  @override
  String get commentDetailRootBadge => 'OP';

  @override
  String get commentDetailDeleted => '(Comment deleted)';

  @override
  String get commentMenuCopy => 'Copy Comment';

  @override
  String get commentMenuSelectText => 'Select Text';

  @override
  String get commentDialogTitle => 'Comment Content';

  @override
  String get commentDialogEmpty => '(It\'s empty here)';

  @override
  String get danmakuInputBvPrompt => 'Please enter a BV ID';

  @override
  String get danmakuInputCidPrompt => 'Please enter a CID';

  @override
  String get danmakuInputCidNumeric => 'CID must contain only digits';

  @override
  String danmakuInputCacheHit(int count, String oid) {
    return 'Cache hit: $count danmaku loaded (oid=$oid)';
  }

  @override
  String danmakuInputFetchSuccess(int count, String oid) {
    return 'Loaded: $count danmaku (oid=$oid)';
  }

  @override
  String get danmakuInputFetchFail => 'Failed to fetch';

  @override
  String get danmakuInputTitle => 'Bilibili Danmaku';

  @override
  String get danmakuInputTypeLabel => 'Type: ';

  @override
  String get danmakuInputBvHint =>
      'Enter a BV ID to automatically fetch the CID of the first part';

  @override
  String get danmakuInputCidHint =>
      'Enter a numeric CID directly (e.g. obtained from an API)';

  @override
  String get danmakuInputFetching => 'Fetching...';

  @override
  String get danmakuInputFetchDanmaku => 'Fetch Danmaku';

  @override
  String get danmakuInputEmpty => 'Input cannot be empty';

  @override
  String get danmakuCidFetchFail =>
      'Unable to fetch CID, please check the BV ID';

  @override
  String danmakuNoData(String oid) {
    return 'No danmaku data found (oid=$oid)';
  }

  @override
  String get danmakuSettingsTitle => 'Danmaku Settings';

  @override
  String get danmakuDataSource => 'Data Source';

  @override
  String get danmakuDisplayControl => 'Display Control';

  @override
  String get danmakuEnable => 'Enable Danmaku';

  @override
  String get danmakuSmartMask => 'Smart Anti-Occlusion';

  @override
  String get danmakuSmartMaskDesc =>
      'Detects people so danmaku won\'t cover them';

  @override
  String get danmakuTypeFilter => 'Danmaku Type';

  @override
  String get danmakuTypeScroll => 'Scrolling Danmaku';

  @override
  String get danmakuTypeTop => 'Top Danmaku';

  @override
  String get danmakuTypeBottom => 'Bottom Danmaku';

  @override
  String get danmakuTypeAdvanced => 'Advanced Danmaku (BAS)';

  @override
  String get danmakuAdvancedSubtitle =>
      'Animated danmaku; enabling may affect performance';

  @override
  String get danmakuParameters => 'Parameters';

  @override
  String get danmakuScrollSpeed => 'Scroll Speed';

  @override
  String get danmakuOpacity => 'Opacity';

  @override
  String get danmakuFontSize => 'Font Size';

  @override
  String get danmakuMaxLines => 'Max Lines';

  @override
  String danmakuLinesCount(int count) {
    return '$count lines';
  }

  @override
  String get danmakuQuickActions => 'Quick Actions';

  @override
  String get danmakuResetParams => 'Reset Parameters';

  @override
  String get danmakuClearDanmaku => 'Clear Danmaku';

  @override
  String get danmakuLoadLocalXml => 'Load Local XML Danmaku';

  @override
  String get danmakuFetchOnline => 'Fetch Online Bilibili Danmaku';

  @override
  String get danmakuNotLoaded => 'No danmaku loaded yet';

  @override
  String danmakuLoadedCount(int count) {
    return '$count danmaku loaded';
  }

  @override
  String get danmakuBlockColorful => 'Colored danmaku';

  @override
  String get danmakuCloudFilter => 'Smart cloud filter';

  @override
  String get danmakuCloudFilterOff => 'Off';

  @override
  String danmakuCloudFilterLevel(int level) {
    return 'Level $level';
  }

  @override
  String get danmakuFontSizeFS => 'Fullscreen font size';

  @override
  String danmakuSeconds(int value) {
    return '${value}s';
  }

  @override
  String get danmakuOthers => 'Others';

  @override
  String get danmakuMassiveMode => 'Massive mode';

  @override
  String get danmakuStatic2Scroll => 'Static to scroll';

  @override
  String get danmakuShowArea => 'Show area';

  @override
  String get danmakuFontWeight => 'Font weight';

  @override
  String get danmakuStrokeWidth => 'Stroke width';

  @override
  String get danmakuScrollDuration => 'Scroll duration (s)';

  @override
  String get danmakuStaticDuration => 'Static duration (s)';

  @override
  String get danmakuLineHeight => 'Line height';

  @override
  String danmakuResetTo(String value) {
    return 'Reset to default: $value';
  }

  @override
  String get naviAddAction => 'Add';

  @override
  String playlistImportAdded(int count) {
    return 'Added $count files';
  }

  @override
  String get playlistAddEpisodeTitle => 'Add Episode';

  @override
  String get playlistTitleLabel => 'Title';

  @override
  String get playlistEpisodeHint => 'Episode 1';

  @override
  String get playlistVideoUrlLabel => 'Video URL';

  @override
  String get playlistAdd => 'Add';

  @override
  String get playlistNameRequired => 'Please enter a playlist name';

  @override
  String get playlistAtLeastOneVideo => 'Please add at least one video';

  @override
  String get playlistEditTitle => 'Edit Playlist';

  @override
  String get playlistCreateTitle => 'Create Playlist';

  @override
  String get playlistNameLabel => 'Playlist Name';

  @override
  String get playlistNameHint => 'My anime list';

  @override
  String get playlistWebdavMulti => 'WebDAV Multi-select';

  @override
  String playlistItemsCount(int count) {
    return '$count episodes';
  }

  @override
  String get playlistNoItems => 'No videos added yet';

  @override
  String get playlistImportHint => 'Tap the buttons above to import';

  @override
  String get playlistSaveChanges => 'Save Changes';

  @override
  String get playlistEpisodePanelTitle => 'Episodes';

  @override
  String playlistEpisodeCurrent(int index) {
    return 'Current: Episode $index';
  }

  @override
  String playlistSyncResult(String what, String message) {
    return '$what: $message';
  }

  @override
  String get playlistSyncTwoWay => 'Two-way Sync Playlists';

  @override
  String get playlistSyncTwoWaySubtitle =>
      'Download from cloud and merge, then upload the merged result (includes backgrounds)';

  @override
  String get playlistRestoreFromCloud => 'Restore from Cloud';

  @override
  String get playlistRestoreFromCloudSubtitle =>
      'Overwrite local playlists with cloud data (includes backgrounds)';

  @override
  String get playlistUploadToCloud => 'Upload to Cloud';

  @override
  String get playlistUploadToCloudSubtitle =>
      'Upload all local playlists (includes backgrounds, no merging)';

  @override
  String get playlistSyncDanmaku => 'Sync Danmaku Cache';

  @override
  String get playlistSyncDanmakuSubtitle =>
      'Merge with the cloud danmaku cache (keep the newer)';

  @override
  String playlistCreated(String name) {
    return 'Created: $name';
  }

  @override
  String get playlistDeleteTitle => 'Delete Playlist';

  @override
  String playlistDeleteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get playlistNewTooltip => 'New Playlist';

  @override
  String get playlistListTitle => 'Playlists';

  @override
  String get playlistCloudSync => 'Cloud Sync';

  @override
  String get playlistMyLists => 'My Lists';

  @override
  String get playlistNoLists => 'No playlists';

  @override
  String playlistListSummary(int count) {
    return '$count total · Tap a list to view all episodes';
  }

  @override
  String get playlistEmptyTitle => 'No playlists yet';

  @override
  String get playlistEmptyHint =>
      'Tap the \"Create\" button at the bottom right to create one';

  @override
  String get playlistResume => 'Resume';

  @override
  String get playlistEditAction => 'Edit';

  @override
  String playlistTileProgress(int total, int current) {
    return '$total episodes · Watched up to episode $current';
  }

  @override
  String get subtitleOff => 'Off';

  @override
  String subtitleTrackFallback(String id) {
    return 'Track $id';
  }

  @override
  String subtitleLoadedLocal(String name) {
    return 'Subtitle loaded: $name';
  }

  @override
  String get subtitleWebdavNotConfigured =>
      'WebDAV is not configured, please log in first';

  @override
  String get subtitleWebdavFolderEmpty => 'The WebDAV subtitle folder is empty';

  @override
  String get subtitleSelectFile => 'Select Subtitle File';

  @override
  String subtitleDownloadFailed(int code) {
    return 'Subtitle download failed: HTTP $code';
  }

  @override
  String subtitleLoadedRemote(String name) {
    return 'Remote subtitle loaded: $name';
  }

  @override
  String subtitleLoadError(String error) {
    return 'Subtitle load error: $error';
  }

  @override
  String get subtitlePanelTitle => 'Subtitles (CC)';

  @override
  String get subtitleLoadLocal => 'Load Local Subtitle';

  @override
  String get subtitleLoadWebdav => 'Load Subtitle from WebDAV';

  @override
  String get subtitleFontSize => 'Font Size';

  @override
  String get subtitleFontColor => 'Font Color';

  @override
  String get subtitleBgColor => 'Background Color';

  @override
  String get subtitleDragToggle => 'Subtitle drag (free position)';

  @override
  String get subtitleDragHint =>
      'When enabled, you can freely drag subtitles around the screen';

  @override
  String get subtitlePositionReset => 'Reset subtitle position';

  @override
  String get webdavInputPath => 'Enter Path';

  @override
  String get webdavGoTo => 'Go';

  @override
  String get webdavLoginRequired =>
      'Please log in to your WebDAV account first';

  @override
  String get webdavLoginSubtitle =>
      'Configure a server to browse remote videos';

  @override
  String get webdavLoginSubtitleMulti =>
      'After logging in, you can multi-select remote videos to create playlists';

  @override
  String get webdavRefresh => 'Refresh';

  @override
  String get webdavRoot => 'Root';

  @override
  String get webdavParent => 'Parent';

  @override
  String get webdavFolderEmpty => 'This folder is empty';

  @override
  String get webdavPullToRefresh => 'Try pulling down to refresh?';

  @override
  String get webdavSelectVideo => 'Please select a video file';

  @override
  String get webdavPlay => 'Play';

  @override
  String get webdavMultiSelectTitle => 'Multi-select Files';

  @override
  String get webdavNoSelection => 'No files selected';

  @override
  String webdavSelectedCount(int count) {
    return '$count videos selected';
  }

  @override
  String webdavSelectionOrder(String names) {
    return 'In selection order: $names';
  }

  @override
  String get webdavClear => 'Clear';

  @override
  String get webdavConfirmSelection => 'Confirm Selection';

  @override
  String get webdavGoLogin => 'Log In';

  @override
  String get profileTitle => 'Profile';

  @override
  String get settingsAvatarTitle => 'Avatar';

  @override
  String get settingsAvatarSet => 'Set';

  @override
  String get settingsNotSet => 'Not set';

  @override
  String get settingsAvatarChangeTooltip => 'Change avatar';

  @override
  String get settingsAvatarDeleteTooltip => 'Delete avatar';

  @override
  String get settingsAvatarUpdated => 'Avatar updated';

  @override
  String settingsPickAvatarFailed(String error) {
    return 'Failed to pick avatar: $error';
  }

  @override
  String get settingsAvatarDeleteTitle => 'Delete avatar';

  @override
  String get settingsAvatarDeleteConfirm =>
      'Are you sure you want to delete the current avatar?';

  @override
  String get settingsAvatarDeleteConfirmPermanent =>
      'Are you sure you want to delete the current avatar? This cannot be undone.';

  @override
  String get settingsAvatarDeleted => 'Avatar deleted';

  @override
  String get settingsNickname => 'Nickname';

  @override
  String get settingsNicknameEditTooltip => 'Edit nickname';

  @override
  String get settingsSetNickname => 'Set nickname';

  @override
  String get settingsNicknamePrompt => 'Please enter your nickname';

  @override
  String get settingsNicknameHint => 'Enter nickname';

  @override
  String get settingsNicknameEmpty => 'Nickname cannot be empty';

  @override
  String get settingsNicknameTooLong => 'Nickname cannot exceed 20 characters';

  @override
  String get settingsNicknameUpdated => 'Nickname updated';

  @override
  String get settingsLockWallpaper => 'Lock screen wallpaper';

  @override
  String get settingsWallpaperCustomSet => 'Custom wallpaper set';

  @override
  String get settingsWallpaperDefaultBg => 'Using default dark background';

  @override
  String get settingsWallpaperUpdated => 'Wallpaper updated';

  @override
  String get settingsWallpaperPickTooltip => 'Choose wallpaper';

  @override
  String get settingsWallpaperDelete => 'Delete wallpaper';

  @override
  String get settingsWallpaperDeleteConfirm =>
      'Delete the lock screen wallpaper and restore default?';

  @override
  String get settingsWallpaperDeleted => 'Wallpaper deleted';

  @override
  String get settingsDecoImage => 'Bottom-right decoration image';

  @override
  String get settingsDecoImageSet => 'Set (transparent PNG/WebP supported)';

  @override
  String get settingsDecoImageUpdated => 'Decoration image updated';

  @override
  String settingsPickImageFailed(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String get settingsPickImageTooltip => 'Choose image';

  @override
  String get settingsDecoImageDelete => 'Delete decoration image';

  @override
  String get settingsDecoImageDeleteConfirm =>
      'Delete the bottom-right decoration image?';

  @override
  String get settingsDecoImageDeleted => 'Decoration image deleted';

  @override
  String get settingsSize => 'Size';

  @override
  String settingsSizePxLabel(String size) {
    return '$size px';
  }

  @override
  String settingsSizePxValue(String size) {
    return '${size}px';
  }

  @override
  String get settingsOpacity => 'Opacity';

  @override
  String settingsOpacityPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsDisplay => 'Display';

  @override
  String get settingsDisplaySubtitle => 'Theme · Color · Text · Scale';

  @override
  String get settingsAppTheme => 'App theme';

  @override
  String settingsCurrentColor(String color) {
    return 'Current color: #$color';
  }

  @override
  String get settingsFontWeight => 'Font weight';

  @override
  String settingsCurrentFontWeight(int weight) {
    return 'Current weight: $weight';
  }

  @override
  String get settingsDisplayScale => 'Display scale';

  @override
  String settingsCurrentScale(int percent) {
    return 'Current scale: $percent%';
  }

  @override
  String get settingsRestrictIp => 'Restrict LAN IP connections';

  @override
  String get settingsRestrictIpSubtitle =>
      'Only allow Class A, B, and C LAN IP addresses';

  @override
  String get settingsDefaultPort => 'Default port';

  @override
  String get settingsAdjustFontWeight => 'Adjust font weight';

  @override
  String settingsFontWeightPreview(int weight) {
    return 'Preview: $weight';
  }

  @override
  String get settingsWeightHairline => 'Hairline';

  @override
  String get settingsWeightThin => 'Thin';

  @override
  String get settingsWeightRegular => 'Regular';

  @override
  String get settingsWeightMedium => 'Medium';

  @override
  String get settingsWeightBold => 'Bold';

  @override
  String get settingsWeightBlack => 'Black';

  @override
  String get settingsFontWeightUpdated => 'Font weight updated';

  @override
  String get logTitle => 'Logs';

  @override
  String get logBackTooltip => 'Navigate up';

  @override
  String get logRefresh => 'Refresh';

  @override
  String get logClearAll => 'Clear logs';

  @override
  String get logClearTitle => 'Clear logs';

  @override
  String get logClearConfirm =>
      'All log files under error/ and mpv/ will be deleted. Continue?';

  @override
  String get logClearAction => 'Clear';

  @override
  String logDeletedCount(int count) {
    return '$count log files deleted';
  }

  @override
  String get logCopyContent => 'Copy content';

  @override
  String get logShare => 'Share log';

  @override
  String get logDeleteThis => 'Delete this log';

  @override
  String get logEmptyContent => '(Empty log)';

  @override
  String logStorageLocation(String path) {
    return 'Storage location: $path';
  }

  @override
  String get logErrorSection => 'Error logs (written on crash)';

  @override
  String get logNoErrorLogs => 'No error logs';

  @override
  String get logMpvSection => 'mpv logs (optional)';

  @override
  String get logNoMpvLogs => 'No mpv logs';

  @override
  String get logReadingLogs => 'Reading logs…';

  @override
  String get lockFollowThemeColor => 'Follow theme color (time)';

  @override
  String get lockShowBattery => 'Show battery';

  @override
  String get lockShowNetwork => 'Show network';

  @override
  String lockDate(int month, int day) {
    return '$month/$day';
  }

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get myQrSelectIpHint => 'Tap to choose the IP used in the QR code';

  @override
  String get myQrNoIpType => 'No IP of this type';

  @override
  String get myQrInUse => 'In use';

  @override
  String get myQrSetAsQr => 'Set as QR';

  @override
  String get netLanDiscoveryPort => 'Local discovery port';

  @override
  String netDohNoRecord(String domain) {
    return 'No A record found for $domain';
  }

  @override
  String netDohQueryFailed(String error) {
    return 'Query failed: $error';
  }

  @override
  String netMappingSaved(String domain, String ip) {
    return 'Mapping saved: $domain → $ip';
  }

  @override
  String get netAddHostMapping => 'Add host mapping';

  @override
  String get netDomainLabel => 'Domain';

  @override
  String get netIpLabel => 'IP address';

  @override
  String get netAdd => 'Add';

  @override
  String netMappingAdded(String host, String ip) {
    return 'Mapping added: $host → $ip';
  }

  @override
  String netMappingRemoved(String host) {
    return 'Mapping removed: $host';
  }

  @override
  String get netTitle => 'Network';

  @override
  String get netBackTooltip => 'Navigate up';

  @override
  String get netRetestAll => 'Retest all';

  @override
  String get netConnectionModeSection => 'Connection mode';

  @override
  String get netNetworkMode => 'Network mode';

  @override
  String get netModeStandardLabel => 'Standard mode';

  @override
  String get netModeCompatLabel => 'Compatibility direct connect';

  @override
  String get netModeStandardDesc => 'Use the system default network stack';

  @override
  String get netAllowInsecureCert => 'Allow insecure certificates';

  @override
  String get netAllowInsecureCertDesc =>
      'Skip certificate verification in compatibility mode (IP direct connect)';

  @override
  String get netChatIpv6 => 'Chat IPv6';

  @override
  String get netChatIpv6On =>
      'Enabled: IPv6 chat, discovery and QR codes supported';

  @override
  String get netChatIpv6Off => 'Disabled: IPv4 only for chat';

  @override
  String get netChatIpv6EnabledSnack =>
      'Chat IPv6 enabled (takes effect after restart)';

  @override
  String get netChatIpv6DisabledSnack =>
      'Chat IPv6 disabled (takes effect after restart)';

  @override
  String get netLocalSendCompat => 'LocalSend compatibility';

  @override
  String get netLocalSendCompatOn =>
      'Enabled: LocalSend protocol (port 53317) for file transfer with LocalSend clients';

  @override
  String get netLocalSendCompatOff =>
      'Disabled: using the navi native protocol';

  @override
  String get netLocalSendCompatEnabledSnack =>
      'LocalSend compatibility enabled';

  @override
  String get netLocalSendCompatDisabledSnack =>
      'LocalSend compatibility disabled (native protocol restored)';

  @override
  String get lsSectionTitle => 'LocalSend devices';

  @override
  String get lsHintEnable => 'LocalSend compatibility is off';

  @override
  String get lsHintEnableDesc =>
      'Enable it to share files with LocalSend official clients (Android/iOS/Windows/macOS/Linux)';

  @override
  String get lsEnableNow => 'Enable';

  @override
  String get lsEnabledSnack => 'LocalSend compatibility enabled';

  @override
  String get lsNoDevices => 'No LocalSend devices found';

  @override
  String get lsHttpScan => 'HTTP scan';

  @override
  String get lsHttpScanning =>
      'Scanning local network (fallback when multicast fails)...';

  @override
  String get lsHttpScanDone => 'Scan finished';

  @override
  String get lsSendFile => 'Send files';

  @override
  String get lsSendFileDesc => 'Send to this device via the LocalSend protocol';

  @override
  String get lsProbe => 'Probe again';

  @override
  String get lsProbing => 'Probing...';

  @override
  String get lsProbeFound => 'Probe succeeded';

  @override
  String get lsProbeNotFound => 'Device did not respond';

  @override
  String lsPickFailed(String error) {
    return 'Failed to pick files: $error';
  }

  @override
  String get lsNoPath => 'File path unavailable';

  @override
  String lsSendingTitle(String alias) {
    return 'Sending to $alias';
  }

  @override
  String lsSendSuccess(int count) {
    return '$count files sent successfully';
  }

  @override
  String lsSendFailed(int count) {
    return '$count files sent successfully, others failed';
  }

  @override
  String get lsReceiveRequestTitle => 'Incoming file request';

  @override
  String lsReceiveRequestDesc(int count, String size) {
    return 'The peer wants to send $count files ($size in total)';
  }

  @override
  String get lsAccept => 'Accept';

  @override
  String get lsReject => 'Reject';

  @override
  String get lsOpenFile => 'Open file';

  @override
  String get lsReceiveCompleteTitle => 'File received';

  @override
  String lsReceiveCompleteDesc(String fileName, String path) {
    return '$fileName saved to:\n$path';
  }

  @override
  String lsFileReceived(String fileName) {
    return 'File received: $fileName';
  }

  @override
  String get netConnectivitySection => 'Connectivity test';

  @override
  String get netHostMappingSection => 'Host mapping';

  @override
  String get netMappingReset => 'Restored built-in default IP table';

  @override
  String get netRestoreDefaults => 'Restore defaults';

  @override
  String get netNoMappings => 'No mappings';

  @override
  String get netAddMapping => 'Add mapping';

  @override
  String get netDohQuerySection => 'DoH query';

  @override
  String get netDohQueryDesc =>
      'Query domain A records via the Cloudflare JSON DNS API; results can be saved as host mappings with one tap';

  @override
  String netDohResultDisplay(String domain, String ip) {
    return '$domain → $ip';
  }

  @override
  String get netSaveAsMapping => 'Save as mapping';

  @override
  String get netHeadersSection => 'Request headers';

  @override
  String get netRefererNotSet => 'Not set (e.g. https://www.bilibili.com/)';

  @override
  String get netNotSet => 'Not set';

  @override
  String netHeaderEditorTitle(String title) {
    return 'Set $title';
  }

  @override
  String netHeaderSaved(String title) {
    return '$title saved';
  }

  @override
  String get ossTitle => 'Open source licenses';

  @override
  String get ossBackTooltip => 'Navigate up';

  @override
  String get ossCopyFullText => 'Copy full text';

  @override
  String get ossLicenseCopied => 'License text copied to clipboard';

  @override
  String get playHistoryTitle => 'Play history';

  @override
  String get playHistoryBackTooltip => 'Navigate up';

  @override
  String get playHistoryClearAll => 'Clear all';

  @override
  String get playHistoryEmpty => 'Nothing here yet';

  @override
  String get playHistoryEmptySub => 'Hmm, it\'s quite quiet today';

  @override
  String get playHistoryClearTitle => 'Clear play history';

  @override
  String get playHistoryClearConfirm =>
      'Are you sure you want to delete all saved play progress? This cannot be undone.';

  @override
  String get playHistoryClearAction => 'Clear';

  @override
  String get playHistoryResume => 'Resume playback';

  @override
  String get playHistoryDeleteRecord => 'Delete record';

  @override
  String playHistoryDeleted(String title) {
    return 'Deleted play record for “$title”';
  }

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get playerArtistVideo => 'Video playback';

  @override
  String get playerArtistPlaylist => 'Playlist';

  @override
  String get playerArtistWebdav => 'WebDAV video';

  @override
  String get playerWebdavSubtitle => 'WebDAV subtitle';

  @override
  String playerResumeFrom(String position) {
    return 'Resumed from $position';
  }

  @override
  String playerNowPlaying(String title) {
    return 'Now playing: $title';
  }

  @override
  String playerDanmakuCache(int count) {
    return 'Danmaku cache ($count)';
  }

  @override
  String playerDanmakuBilibili(int count) {
    return 'Bilibili danmaku ($count)';
  }

  @override
  String get playerDanmakuNoData => 'No danmaku data parsed';

  @override
  String playerDanmakuLoaded(int count) {
    return '$count danmaku items loaded';
  }

  @override
  String playerDanmakuOnline(int count) {
    return 'Bilibili online danmaku ($count)';
  }

  @override
  String playerDanmakuLoadedFromCache(int count) {
    return 'Loaded $count danmaku items from local cache';
  }

  @override
  String playerDanmakuLoadedOnline(int count) {
    return 'Loaded $count online danmaku items';
  }

  @override
  String playerScreenshotFailed(String error) {
    return 'Screenshot failed: $error';
  }

  @override
  String get playerSavedToAlbum => 'Saved to album';

  @override
  String playerScreenshotSavedToAlbum(String fileName) {
    return 'Screenshot $fileName saved to album';
  }

  @override
  String playerSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String playerPipFailed(String error) {
    return 'Picture-in-picture failed: $error';
  }

  @override
  String get playerFitAdapt => 'Contain';

  @override
  String get playerFitStretch => 'Stretch';

  @override
  String get playerFitFill => 'Fill';

  @override
  String get playerEndPause => 'Pause when finished';

  @override
  String get playerEndLoop => 'Loop';

  @override
  String get playerEndExit => 'Exit when finished';

  @override
  String get playerSubtitleSettings => 'Subtitle settings';

  @override
  String get playerAdvancedSettings => 'Advanced settings';

  @override
  String get playerFlipHorizontal => 'Mirror horizontally';

  @override
  String get playerFlipHorizontalDesc => 'Flip the image horizontally';

  @override
  String get playerFlipVertical => 'Flip vertically';

  @override
  String get playerFlipVerticalDesc => 'Flip the image vertically';

  @override
  String get playerShowStats => 'Show video stats';

  @override
  String get playerShowStatsDesc => 'Codec / resolution / bitrate / frame rate';

  @override
  String get playerAutoPip => 'Auto picture-in-picture on home';

  @override
  String get playerLoadDanmakuOnResume => 'Load danmaku on resume';

  @override
  String get playerLoadDanmakuOnResumeDesc =>
      'Automatically read/fetch danmaku when resuming from play history';

  @override
  String get playerDefaultRate => 'Default playback speed';

  @override
  String get playerDefaultEndBehavior => 'Default end behavior';

  @override
  String get playerTimePickerTitle => 'Jump to time';

  @override
  String get playerTimeUnitHour => 'h';

  @override
  String get playerTimeUnitMinute => 'm';

  @override
  String get playerTimeUnitSecond => 's';

  @override
  String get playerBuffering => 'Buffering…';

  @override
  String get playerHwdecSoftware => 'Software decode (SW)';

  @override
  String playerHwdecHardware(String mode) {
    return 'Hardware decode ($mode)';
  }

  @override
  String get playerSourceLocal => 'Local file';

  @override
  String get playerStatResolution => 'Resolution';

  @override
  String get playerStatVideoCodec => 'Video codec';

  @override
  String get playerStatAudioCodec => 'Audio codec';

  @override
  String get playerStatBitrate => 'Bitrate';

  @override
  String get playerStatFps => 'Frame rate';

  @override
  String get playerStatDecode => 'Decode';

  @override
  String get playerStatSubtitle => 'Subtitle';

  @override
  String get playerOn => 'On';

  @override
  String get playerOff => 'Off';

  @override
  String get playerStatDanmaku => 'Danmaku';

  @override
  String get playerStatDownload => 'Download';

  @override
  String get playerStatSource => 'Source';

  @override
  String get playerStatPosition => 'Position';

  @override
  String get playerStatDuration => 'Duration';

  @override
  String get playerCopyLink => 'Copy video link';

  @override
  String playerCopyLinkAt(String time) {
    return 'Copy link at $time';
  }

  @override
  String get playerCopyLinkAt0 => 'Copy link at current position';

  @override
  String playerCopyLinkDone(String url) {
    return 'Copied: $url';
  }

  @override
  String get playerCopyLinkNotBili =>
      'Copying links is only supported for Bilibili videos';

  @override
  String get playerColorAdjust => 'Video color adjustment';

  @override
  String get playerColorBrightness => 'Brightness';

  @override
  String get playerColorContrast => 'Contrast';

  @override
  String get playerColorSaturation => 'Saturation';

  @override
  String get playerColorHue => 'Hue';

  @override
  String get playerColorGamma => 'Gamma';

  @override
  String get playerColorReset => 'Reset';

  @override
  String get playerColorUnavailable =>
      'Color adjustment is not supported by this player';

  @override
  String get playerStats => 'Statistics';

  @override
  String get playerAlignAspectRatio => 'Match aspect ratio';

  @override
  String get playerAlignAspectRatioDone => 'Window aligned to video ratio';

  @override
  String get playerAlignAspectRatioFailed => 'Couldn\'t get video size';

  @override
  String get commonClose => 'Close';

  @override
  String get playerPlaybackError => 'Playback error';

  @override
  String playerAllEpisodesPlayed(int count) {
    return 'All $count episodes played';
  }

  @override
  String playerFastForwarding(String rate) {
    return 'Playing at $rate speed';
  }

  @override
  String get playerTapToSave => 'Tap to save';

  @override
  String get playerResetScreen => 'Reset screen';

  @override
  String get playerBackTooltip => 'Navigate up';

  @override
  String get playerRotate90 => 'Rotate 90°';

  @override
  String get playerQuality => 'Quality';

  @override
  String get playerQualityLocked =>
      'This quality is unavailable (login or VIP required)';

  @override
  String get playerFullscreen => 'Fullscreen';

  @override
  String get playerBiliSubtitle => 'Bilibili subtitle';

  @override
  String get playerDecodeFormat => 'Decode format';

  @override
  String get playerDecodeFormatSwitchFailed => 'Failed to switch decode format';

  @override
  String get playerDecodeAuto => 'Auto';

  @override
  String get playerDecodeAutoShort => 'Auto';

  @override
  String get playerDecodeAvc => 'AVC / H.264';

  @override
  String get playerDecodeHevc => 'HEVC / H.265';

  @override
  String get playerDecodeAv1 => 'AV1';

  @override
  String get playerSubtitleLoadFailed => 'Failed to load subtitle';

  @override
  String get playerSubtitleBilingual => 'Bilingual subtitles';

  @override
  String playerSubtitleBilingualOn(String primary, String secondary) {
    return 'Bilingual subtitles: $primary / $secondary';
  }

  @override
  String get playerSubtitleBilingualUnavailable =>
      'This video only provides a single-language subtitle, bilingual mode unavailable';

  @override
  String get playerSubtitleSecondLang => 'Translation language';

  @override
  String get playerSubtitleDrag => 'Subtitle drag';

  @override
  String get playerSubtitleDragOn =>
      'Subtitle drag enabled: drag the screen to reposition';

  @override
  String get playerSubtitleDragOff => 'Subtitle drag disabled';

  @override
  String get playerSubtitleDragging => 'Dragging subtitle…';

  @override
  String get playerSubtitleDragHint => 'Drag subtitle on screen to reposition';

  @override
  String get playerSubtitlePositionSaved => 'Subtitle position saved';

  @override
  String get playerSubtitlePositionReset => 'Reset subtitle position';

  @override
  String get playerPortraitMode => 'Portrait mode';

  @override
  String get playerLandscapeMode => 'Landscape mode';

  @override
  String get playerDescription => 'Description';

  @override
  String get playerWebdavSource => 'WebDAV video source';

  @override
  String get playerCast => 'Cast';

  @override
  String get playerWatchTogether => 'Watch together';

  @override
  String get watchInviteTitle => 'invites you to watch together';

  @override
  String get watchWaitingAccept => 'Waiting for the other side to accept…';

  @override
  String get watchSelectPeer => 'Choose a friend to watch with';

  @override
  String get watchNoOnlinePeer => 'No online contacts';

  @override
  String watchInviteSent(String name) {
    return 'Watch-together invite sent to $name';
  }

  @override
  String watchActiveWith(String name) {
    return 'Watching together with $name';
  }

  @override
  String get watchPeerRejected => 'The other side rejected your invite';

  @override
  String get watchPeerNoAnswer => 'The other side didn\'t accept the invite';

  @override
  String get watchPeerLeft => 'The other side left watch together';

  @override
  String get watchTcpFailed => 'Couldn\'t connect. Watch together failed';

  @override
  String get watchConnectionDropped =>
      'Connection dropped. Watch together failed';

  @override
  String get watchUrlInvalid =>
      'Video URL unavailable. Can\'t start watch together';

  @override
  String get rcInviteTitle => 'requests remote control of your device';

  @override
  String get rcInviteHint =>
      'Once accepted, they can see your screen and control your device';

  @override
  String get rcPeerRejected =>
      'The other side rejected the remote control request';

  @override
  String get rcTcpFailed => 'Couldn\'t connect. Remote control failed';

  @override
  String get rcConnectionDropped => 'Connection dropped. Remote control failed';

  @override
  String get rcTimeout => 'Timed out waiting for the other side';

  @override
  String get rcShizukuNotInstalled =>
      'Shizuku is not installed on the target device';

  @override
  String get rcShizukuNotInstalledHint =>
      'The target device needs Shizuku running (shizuku.rikka.app)';

  @override
  String get rcShizukuGrantTitle => 'Shizuku authorization required';

  @override
  String get rcShizukuGrantHint =>
      'After granting Navi Shizuku permission on the target, they can control the screen remotely';

  @override
  String get rcShizukuGrant => 'Grant Shizuku';

  @override
  String get rcRequesting => 'Requesting…';

  @override
  String get rcShizukuNotGranted => 'Shizuku is not granted';

  @override
  String rcScreenCaptureFailed(String error) {
    return 'Screen capture failed: $error';
  }

  @override
  String get rcShareFailed => 'Screen share failed';

  @override
  String get rcRetry => 'Retry';

  @override
  String get rcClose => 'Close';

  @override
  String get rcCancel => 'Cancel';

  @override
  String get rcSend => 'Send';

  @override
  String get rcConnecting => 'Connecting…';

  @override
  String rcControlling(String name) {
    return 'Controlling $name remotely';
  }

  @override
  String rcBeingControlled(String name) {
    return '$name is controlling your device remotely';
  }

  @override
  String get rcEnd => 'End remote control';

  @override
  String get rcConnectionLost => 'Remote control connection lost';

  @override
  String get rcSessionEnded => 'Remote control ended';

  @override
  String get rcInputText => 'Input text';

  @override
  String get rcInputTextHint => 'Text to send to the target device';

  @override
  String get rcKeyBack => 'Back';

  @override
  String get rcKeyHome => 'Home';

  @override
  String get rcKeyRecents => 'Recents';

  @override
  String get rcKeyVolumeUp => 'Volume up';

  @override
  String get rcKeyVolumeDown => 'Volume down';

  @override
  String get dlnaPageTitle => 'Cast';

  @override
  String get dlnaRefresh => 'Rescan';

  @override
  String get dlnaSearching => 'Searching for DLNA devices on the LAN…';

  @override
  String get dlnaNoDevice => 'No cast device found';

  @override
  String get dlnaNoDeviceHint =>
      'Make sure your TV/box is on the same network and DLNA/casting is enabled';

  @override
  String get dlnaSearchAgain => 'Search again';

  @override
  String get dlnaFoundDevices => 'Devices found';

  @override
  String dlnaCastStarted(String device) {
    return 'Casting to $device';
  }

  @override
  String dlnaCastFailed(String device) {
    return 'Cast failed: $device';
  }

  @override
  String dlnaCastingTo(String device) {
    return 'Casting to $device';
  }

  @override
  String get dlnaStopCast => 'Stop casting';

  @override
  String get dlnaPlay => 'Play';

  @override
  String get dlnaPause => 'Pause';

  @override
  String get dlnaVolumeUp => 'Volume up';

  @override
  String get dlnaVolumeDown => 'Volume down';

  @override
  String get dlnaFileMissing => 'Video file not found';

  @override
  String dlnaServerStartFailed(String error) {
    return 'Failed to start local file server: $error';
  }

  @override
  String get playerEpisodeSelect => 'Episodes';

  @override
  String get playerDanmakuSettings => 'Danmaku settings';

  @override
  String get psTitle => 'Player';

  @override
  String get psBackTooltip => 'Navigate up';

  @override
  String get psStaffEntrance => 'Staff entrance';

  @override
  String get psDisplaySection => 'Display';

  @override
  String get psStatusBar => 'Status bar';

  @override
  String get psStatusBarDesc =>
      'Show time, battery and network icons at the top of the player';

  @override
  String get psKeepWindowRatio => 'Lock window aspect ratio';

  @override
  String get psKeepWindowRatioDesc =>
      'During playback the window can only be resized at the current aspect ratio';

  @override
  String get psKeepWindowRatioDesktopOnly =>
      'Only takes effect on Windows / macOS / Linux desktop';

  @override
  String get psInteractionSection => 'Interaction';

  @override
  String get psLongPressSpeed => 'Long-press speed boost';

  @override
  String get psLongPressSpeedDesc =>
      'Hold the screen or the D key on the keyboard to fast-forward at 2× speed';

  @override
  String get psScreenshot => 'Screenshot';

  @override
  String get psScreenshotDesc =>
      'Allow capturing the current frame in the player and saving it to the album';

  @override
  String get psScreenshotDanmaku => 'Include danmaku in screenshots';

  @override
  String get psScreenshotDanmakuDesc =>
      'Capture the current danmaku together with the screenshot';

  @override
  String get psProgressSection => 'Progress';

  @override
  String get psPlayProgress => 'Play progress';

  @override
  String get psNoHistory => 'No saved play records';

  @override
  String psHistoryCount(int count) {
    return 'You have $count records';
  }

  @override
  String get psMiscSection => 'Miscellaneous';

  @override
  String get psHwdec => 'Hardware decoding';

  @override
  String get psHwdecAuto => 'Automatically choose the best decoder';

  @override
  String get psHwdecSoftware => 'Force CPU software decoding';

  @override
  String get psHwdecAutoShort => 'Auto';

  @override
  String get psHwdecPureSoftware => 'Software only';

  @override
  String get psHwdecDisabledTag => 'Hard decoding off';

  @override
  String get hwdecPageTitle => 'Hardware decoding';

  @override
  String get hwdecEnabled => 'Enable hardware decoding';

  @override
  String get hwdecEnabledHint =>
      'Plays video with lower power consumption; disable if it crashes/freezes';

  @override
  String get hwdecOnlySupported =>
      'Show only options supported by this platform';

  @override
  String get hwdecOnlySupportedHint =>
      'Filter options by device platform (Windows / macOS / Linux / Android / iOS)';

  @override
  String get hwdecHint =>
      'Tap options to build an ordered mpv --hwdec fallback chain: preferred decoders first, later ones tried on failure, software decoding if all fail. Multiple selection and platform filtering are supported.';

  @override
  String hwdecSelectedPrefix(String n) {
    return '$n selected';
  }

  @override
  String get hwdecEmptyWarning =>
      'Keep at least one hardware decoding option (auto / auto-safe recommended as fallback)';

  @override
  String get psVideoSync => 'Video sync';

  @override
  String get psVsyncAudioDefault => 'Use audio clock as reference (default)';

  @override
  String get psVsyncResample =>
      'Resample audio to match the display refresh rate';

  @override
  String get psVsyncAdrop => 'Drop / duplicate audio frames to match display';

  @override
  String get psVsyncVdrop => 'Drop / duplicate video frames to match display';

  @override
  String get psVsyncAudio => 'Audio';

  @override
  String get psVsyncDisplayResample => 'Display resample';

  @override
  String get psVsyncDisplayAdrop => 'Display audio drop';

  @override
  String get psVsyncDisplayVdrop => 'Display video drop';

  @override
  String get psImmersiveLongPress => 'Long-press speed in immersive mode';

  @override
  String get psImmersiveLongPressDesc =>
      'Long-press still triggers 2× speed when the controls are hidden';

  @override
  String get psLogSection => 'Logs';

  @override
  String get psMpvLog => 'Record mpv logs';

  @override
  String psMpvLogEnabled(String level) {
    return 'Enabled, takes effect on next playback (level: $level)';
  }

  @override
  String get psMpvLogDisabled =>
      'Disabled. Crash logs are always recorded regardless of this switch';

  @override
  String get psMpvLogLevel => 'mpv log level';

  @override
  String get psMpvLogLevelDesc =>
      'Higher levels produce more detailed logs and use more space';

  @override
  String get psMpvLogError => 'Errors only';

  @override
  String get psMpvLogWarn => 'Warnings';

  @override
  String get psMpvLogWarnDefault => 'Warnings (default)';

  @override
  String get psMpvLogInfo => 'Info';

  @override
  String get psMpvLogVerbose => 'Verbose';

  @override
  String get psMpvLogDebug => 'Debug';

  @override
  String get psMpvLogTrace => 'All (very verbose)';

  @override
  String get psViewLogs => 'View logs';

  @override
  String get psViewLogsDesc =>
      'Browse error logs and mpv logs, with sharing and clearing';

  @override
  String testPlaylistCreated(String name) {
    return 'Created: $name';
  }

  @override
  String get testPageTitle => 'Test page';

  @override
  String get testVideoSourceSection => 'Video source';

  @override
  String get testVideoSourceSubtitle => 'Choose a source to start playing';

  @override
  String get testWebdavVideo => 'WebDAV video';

  @override
  String get testWebdavVideoDesc => 'Browse and play from a WebDAV server';

  @override
  String get testLocalVideo => 'Local video';

  @override
  String get testLocalVideoDesc => 'Choose a video file from device storage';

  @override
  String get testRecentSection => 'Recently played';

  @override
  String get testLastPlayedSubtitle => 'Last played record';

  @override
  String get testNoRecords => 'No play records yet';

  @override
  String get testPlaylistSection => 'Playlists';

  @override
  String get testPlaylistSectionSubtitle =>
      'Create and manage playlists, play by episodes';

  @override
  String get testPlaylistManage => 'Manage playlists';

  @override
  String get testPlaylistManageDesc =>
      'View / edit / delete playlists, tap to play directly';

  @override
  String get testPlaylistCreate => 'New playlist';

  @override
  String get testPlaylistCreateDesc =>
      'Build a playlist from multiple WebDAV files / import episodes manually';

  @override
  String get testQuickActionsSection => 'Quick actions';

  @override
  String get testQuickActionsSubtitle => 'Common test entries';

  @override
  String get testUrlDirectPlay => 'Play URL directly';

  @override
  String get testUrlDirectPlayDesc => 'Enter a video URL to play directly';

  @override
  String get testVideoWithSubtitle => 'Video + subtitles';

  @override
  String get testVideoWithSubtitleDesc =>
      'Select a video and a subtitle file together';

  @override
  String get testNoVideoPlayed => 'No video has been played yet';

  @override
  String get testEnterUrlTitle => 'Enter video URL';

  @override
  String get testPlay => 'Play';

  @override
  String get testAddSubtitleTitle => 'Add subtitles?';

  @override
  String testAddSubtitlePrompt(String name) {
    return 'Video selected: $name\nLoad external subtitles?';
  }

  @override
  String get testSkip => 'Skip';

  @override
  String get testSelectSubtitle => 'Choose subtitles';

  @override
  String get testAboutLegalese => 'Player frontend test page';

  @override
  String get testAboutBody =>
      'This page tests the various entry points of MpvPlayerPage:\n• WebDAV remote video\n• Local video files\n• Direct URL playback\n• Video + external subtitles';

  @override
  String get testSourceLocal => 'Local file';

  @override
  String get testSourceLocalSubtitle => 'Local + subtitles';

  @override
  String get accountsBiliLoginSuccess => 'Bilibili login successful';

  @override
  String get accountsBiliLogoutTitle => 'Log out of Bilibili?';

  @override
  String get accountsBiliLogoutHint =>
      'After logging out, the Bilibili API will no longer be called with your Cookie.';

  @override
  String get accountsClearWebviewCookieTitle =>
      'Also clear in-app browser cookies';

  @override
  String get accountsClearWebviewCookieSubtitle =>
      'Leaving it unchecked is fine. You can still clear them later in account settings.';

  @override
  String get accountsLogout => 'Log out';

  @override
  String get accountsLoggedOutWithCookie =>
      'Logged out and cleared browser cookies';

  @override
  String get accountsLoggedOut => 'Logged out';

  @override
  String get accountsClearCookieTitle => 'Clear in-app browser cookies?';

  @override
  String get accountsClearCookieContent =>
      'This will clear all cookies stored by the in-app browser, including web logins.';

  @override
  String get accountsClearAction => 'Clear';

  @override
  String get accountsCookieCleared => 'In-app browser cookies cleared';

  @override
  String get accountsCookieEmpty =>
      'No in-app browser cookies to clear (browser has not been used)';

  @override
  String get accountsBiliLoginTitle => 'Log in to Bilibili account';

  @override
  String get accountsBiliLoginSubtitle => 'QR code / Paste Cookie / Password';

  @override
  String get accountsClearBrowserCookie => 'Clear in-app browser cookies';

  @override
  String get accountsClearBrowserCookieSubtitle => 'Clear leftover web logins';

  @override
  String get accountsLoggedIn => 'Logged in';

  @override
  String accountsLoggedInUid(int mid) {
    return 'Logged in · UID $mid';
  }

  @override
  String get accountsCarryCookie => 'Send requests with Cookie';

  @override
  String get accountsCarryCookieOn =>
      'On: Bilibili API requests use your login identity';

  @override
  String get accountsCarryCookieOff =>
      'Off: Bilibili API requests use guest identity';

  @override
  String get accountsCookieScope => 'Cookie usage scope';

  @override
  String get accountsCookieScopeSubtitle =>
      'Choose which requests use your account Cookie';

  @override
  String get cookieScopeTitle => 'Cookie Usage Scope';

  @override
  String get cookieScopeHint =>
      'Only affects the request types below. When \"Send requests with Cookie\" is off, these settings have no effect. Bilibili online-favorites operations always send your login Cookie.';

  @override
  String get cookieScopeVideo => 'Video details & playback';

  @override
  String get cookieScopeVideoDesc =>
      'Video info, play URLs and watch-progress reporting';

  @override
  String get cookieScopeComments => 'Comments';

  @override
  String get cookieScopeCommentsDesc => 'Comment section requests';

  @override
  String get cookieScopeSearch => 'Search';

  @override
  String get cookieScopeSearchDesc => 'Search suggestions and result requests';

  @override
  String get cookieScopeArticle => 'Articles & moments';

  @override
  String get cookieScopeArticleDesc => 'Article and dynamic-feed requests';

  @override
  String get cookieScopeUserSpace => 'User space';

  @override
  String get cookieScopeUserSpaceDesc =>
      'Creator space, videos and follower-list requests';

  @override
  String get cookieScopeSeason => 'Seasons & episodes';

  @override
  String get cookieScopeSeasonDesc =>
      'Season details and episode-list requests';

  @override
  String get cookieScopeInteractions => 'Interactions';

  @override
  String get cookieScopeInteractionsDesc =>
      'Like, coin, favorite, follow and danmaku sending; disabled when off';

  @override
  String get cookieScopeEnableAll => 'Enable all';

  @override
  String get cookieScopeDisableAll => 'Disable all';

  @override
  String get accountsWebdavCloud => 'WebDAV Cloud Drive';

  @override
  String get accountsWebdavConfiguredOn => 'Configured · Auto backup on';

  @override
  String get accountsWebdavConfiguredOff => 'Configured · Auto backup off';

  @override
  String get accountsWebdavNotConfigured =>
      'Not configured · Tap to open settings';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get accountsSectionBili => 'Bilibili Account';

  @override
  String get commonBackTooltip => 'Navigate up';

  @override
  String get biliLoginFetchingQr => 'Fetching QR code…';

  @override
  String get biliLoginQrFetchFailed =>
      'Failed to fetch QR code, please check your network';

  @override
  String get biliLoginScanWithApp =>
      'Scan the QR code with the Bilibili app to log in';

  @override
  String get biliLoginInputAccountPwd =>
      'Please enter your account and password';

  @override
  String get biliLoginFailedRetry => 'Login failed, please try again';

  @override
  String get biliLoginTitle => 'Bilibili Login';

  @override
  String get biliLoginScanMode => 'QR Code Login';

  @override
  String get biliLoginCookieMode => 'Paste Cookie';

  @override
  String get biliLoginPwdMode => 'Password Login';

  @override
  String get biliLoginViaBrowser => 'Log in with in-app browser';

  @override
  String get biliLoginCookieHint =>
      '\"Send requests with Cookie\" is on by default after login. You can turn it off in Settings → Accounts.';

  @override
  String get biliLoginWebTitle => 'Web Login';

  @override
  String get biliLoginCookieImportFailed =>
      'Failed to import the Cookie from web login. Please retry or use another method.';

  @override
  String get biliLoginRefetch => 'Fetch again';

  @override
  String get biliLoginRefreshQr => 'Refresh QR code';

  @override
  String get biliLoginScanTip =>
      'Tip: open the Bilibili app → Scan, or scan with the Bilibili mini program';

  @override
  String get biliLoginCookieInstruction =>
      'Log in to bilibili.com in a desktop browser, press F12 to open DevTools → Application → Cookies → bilibili.com, copy all cookies (the string starting with SESSDATA=), and paste them into the field below';

  @override
  String get biliLoginVerifying => 'Verifying…';

  @override
  String get biliLoginVerifyAndLogin => 'Log in and verify';

  @override
  String get biliLoginAccountLabel => 'Account (phone / email / username)';

  @override
  String get biliLoginPasswordLabel => 'Password';

  @override
  String get biliLoginLoggingIn => 'Logging in…';

  @override
  String get biliLoginLoginAction => 'Log in';

  @override
  String get biliLoginSliderHint =>
      'Password login may trigger a slider captcha. It will automatically retry after verification.';

  @override
  String get searchFilterAny => 'Any';

  @override
  String get searchFilterLastDay => 'Last day';

  @override
  String get searchFilterLastWeek => 'Last week';

  @override
  String get searchFilterHalfYear => 'Last 6 months';

  @override
  String get searchFilterAllDuration => 'All durations';

  @override
  String get searchFilterDur0to10 => '0-10 min';

  @override
  String get searchFilterDur10to30 => '10-30 min';

  @override
  String get searchFilterDur30to60 => '30-60 min';

  @override
  String get searchFilterDur60plus => '60+ min';

  @override
  String get searchZoneAll => 'All';

  @override
  String get searchZoneAnime => 'Animation';

  @override
  String get searchZoneGuochuang => 'Domestic Creation';

  @override
  String get searchZoneMusic => 'Music';

  @override
  String get searchZoneDance => 'Dance';

  @override
  String get searchZoneGame => 'Games';

  @override
  String get searchZoneKnowledge => 'Knowledge';

  @override
  String get searchZoneTech => 'Tech';

  @override
  String get searchZoneSports => 'Sports';

  @override
  String get searchZoneCar => 'Auto';

  @override
  String get searchZoneLife => 'Life';

  @override
  String get searchZoneFood => 'Food';

  @override
  String get searchZoneAnimal => 'Animals';

  @override
  String get searchZoneKichiku => 'Kichiku';

  @override
  String get searchZoneFashion => 'Fashion';

  @override
  String get searchZoneInfo => 'News';

  @override
  String get searchZoneEnt => 'Entertainment';

  @override
  String get searchZoneDoc => 'Documentary';

  @override
  String get searchZoneFilm => 'Movies';

  @override
  String get searchZoneTv => 'TV';

  @override
  String get searchCaptchaInitFailed => 'Captcha initialization failed';

  @override
  String get searchCaptchaIncomplete => 'Slider verification not completed';

  @override
  String get searchCaptchaValidateFailed => 'Captcha verification failed';

  @override
  String get searchCaptchaValidateFailedRetry =>
      'Captcha verification failed, please retry';

  @override
  String get searchCaptchaPassed => 'Verification passed, searching again';

  @override
  String get searchBiliHint => 'Search Bilibili…';

  @override
  String get searchHistoryTitle => 'Search history';

  @override
  String get searchHistoryClear => 'Clear';

  @override
  String get searchHistoryClearConfirm =>
      'Clear search history for this section?';

  @override
  String get searchHistoryEmpty => 'No search history';

  @override
  String get drawerSearch => 'Search';

  @override
  String get drawerDynamics => 'Dynamics';

  @override
  String get drawerMessages => 'Messages';

  @override
  String get drawerMine => 'Me';

  @override
  String get biliAccountNotLoggedIn => 'Not logged in';

  @override
  String get bottomNavMoveUp => 'Move up';

  @override
  String get bottomNavMoveDown => 'Move down';

  @override
  String get bottomNavSettingsTitle => 'Bottom navigation';

  @override
  String get bottomNavSettingsSubtitle =>
      'Drag to reorder (the first item opens on launch), uncheck to hide';

  @override
  String get bottomNavItemHome => 'Home';

  @override
  String get bottomNavItemDynamics => 'Dynamics';

  @override
  String get bottomNavItemLive => 'Live';

  @override
  String get bottomNavSettingsReset => 'Reset';

  @override
  String get bottomNavSettingsKeepOne => 'Keep at least one item';

  @override
  String get prefSearchSection => 'Search';

  @override
  String get prefSearchTrending => 'Trending searches';

  @override
  String get prefSearchTrendingSub =>
      'Show trending keywords and the full list entry on the search page';

  @override
  String get prefSearchDiscovery => 'Search discovery';

  @override
  String get prefSearchDiscoverySub =>
      'Show recommended keywords on the search page';

  @override
  String get searchTrendingTitle => 'Trending now';

  @override
  String get searchTrendingFullList => 'Full list';

  @override
  String get searchDiscoveryTitle => 'Discover';

  @override
  String get hotSearchTitle => 'bilibili Trending';

  @override
  String get searchDiscoveryFailed => 'Failed to load';

  @override
  String get searchDiscoveryEmpty => 'Nothing here';

  @override
  String get searchVideoFilter => 'Video search filters';

  @override
  String searchFilterWithCount(int count) {
    return 'Filters · $count';
  }

  @override
  String get searchFilter => 'Filters';

  @override
  String get searchSwitchSingleCol => 'Single column';

  @override
  String get searchSwitchMulti => 'Multi-column';

  @override
  String get searchLayoutMulti => 'Multi-column';

  @override
  String get searchLayoutSingle => 'Single column';

  @override
  String get searchPickStartDate => 'Select start date';

  @override
  String get searchPickEndDate => 'Select end date';

  @override
  String get searchPubTimeSection => 'Published';

  @override
  String get searchDateBegin => 'Start';

  @override
  String get searchDateTo => 'to';

  @override
  String get searchDateEnd => 'End';

  @override
  String get searchDurationSection => 'Duration';

  @override
  String get searchZoneSection => 'Partition';

  @override
  String get searchAntiFuzzy => 'Anti-fuzzy search';

  @override
  String get searchAntiFuzzyHint =>
      'Limit results from 2009-06-26 to now, avoiding abnormal early data';

  @override
  String get searchFilterReset => 'Reset';

  @override
  String get searchAllLoaded => '— All loaded —';

  @override
  String get searchKeywordHint => 'Enter a keyword to search Bilibili';

  @override
  String get searchPressToSearch =>
      'Tap \"Search\" or press Enter to start searching';

  @override
  String searchNoResultInType(String keyword, String type) {
    return 'No results for \"$keyword\" in $type';
  }

  @override
  String searchResultsCount(String type, String count) {
    return '$type · $count results';
  }

  @override
  String get userSpaceLoadFailed => 'Failed to load';

  @override
  String get userSpaceAvatarLoadFailed => 'Failed to load avatar';

  @override
  String get userSpaceTitle => 'Creator Space';

  @override
  String get userSpaceLoading => 'Loading creator space…';

  @override
  String get userSpaceLoadingName => 'Loading…';

  @override
  String get userSpaceStatFans => 'Followers';

  @override
  String get userSpaceStatFollowing => 'Following';

  @override
  String get userSpaceStatVideos => 'Videos';

  @override
  String get userSpaceStatLikes => 'Likes';

  @override
  String userSpaceVideoCount(int count) {
    return '$count videos';
  }

  @override
  String get userSpaceSectionAllVideos => 'All Videos';

  @override
  String get userSpaceNoVideos => 'No posts yet';

  @override
  String get userSpaceDynLoadFailed => 'Failed to load posts';

  @override
  String get userSpaceNoDynamics => 'No posts yet';

  @override
  String get userSpaceBangumiLoadFailed => 'Failed to load bangumi list';

  @override
  String get userSpaceNoBangumi => 'No bangumi';

  @override
  String userSpaceBangumiCount(int count) {
    return 'Bangumi · $count titles';
  }

  @override
  String get userSpaceLazySign =>
      'This user is too lazy to leave anything here';

  @override
  String get userSpaceTabHome => 'Home';

  @override
  String get userSpaceTabDynamic => 'Posts';

  @override
  String get userSpaceTabBangumi => 'Bangumi';

  @override
  String get userSpaceToday => 'Today';

  @override
  String get userSpaceBangumiFinished => 'Finished';

  @override
  String get userSpaceBangumiSerializing => 'Ongoing';

  @override
  String userSpaceBangumiAiringDate(String date) {
    return 'Airing $date';
  }

  @override
  String get browserApp => 'app';

  @override
  String browserOpenAppAttempt(String app) {
    return 'The page tried to open: $app';
  }

  @override
  String get browserNoAppForLink => 'No app found to open this link';

  @override
  String get browserOpenFailedSystem =>
      'Failed to open: no matching app installed or blocked by the system';

  @override
  String get browserEmptyCookieHint => 'It\'s empty here';

  @override
  String get browserCopyAll => 'Copy all';

  @override
  String get browserCookieCopied => 'Cookie copied';

  @override
  String get browserCookieEmpty => 'No cookies found';

  @override
  String get browserSetUaTitle => 'Set User-Agent';

  @override
  String get browserUaHint => 'Enter a custom User-Agent';

  @override
  String get browserApplyAndReload => 'Apply and reload';

  @override
  String get browserUaUpdated => 'UA updated and page reloaded';

  @override
  String browserUaSetFailed(String error) {
    return 'Failed to set UA: $error';
  }

  @override
  String get browserWindowsInitFailed =>
      'Windows WebView initialization failed. Please check that WebView2 is installed.';

  @override
  String get browserBiliCookieReadFailed =>
      'Could not read the full login Cookie (SESSDATA is HttpOnly and cannot be read automatically on this platform). Please use QR code login or paste the Cookie instead.';

  @override
  String get browserCookieImportFailed =>
      'Failed to import Cookie, please retry';

  @override
  String get browserStoppedLoading => 'Loading stopped';

  @override
  String get browserClipboardAllowed =>
      'Web pages may now write to the clipboard';

  @override
  String get browserClipboardBlocked =>
      'Web pages are blocked from writing to the clipboard automatically';

  @override
  String get browserNoCurrentUrl => 'Could not get the current URL';

  @override
  String get browserTroubleshootFailed =>
      'Failed to open. Please check whether \"Get Help\" is available.';

  @override
  String get browserSystemBrowserMissing => 'System browser is missing (';

  @override
  String get browserQrTitle => 'Scan me';

  @override
  String get browserSaveToDevice => 'Save to device';

  @override
  String get browserQrSaved => 'QR code saved to gallery';

  @override
  String browserSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get browserStopLoading => 'Stop loading';

  @override
  String get browserImporting => 'Importing…';

  @override
  String get browserLoginDoneImport => 'Logged in, import';

  @override
  String get browserClipboardAccess => 'Clipboard access';

  @override
  String get browserShareQr => 'Share QR code';

  @override
  String get browserCopyLink => 'Copy link';

  @override
  String get browserViewCookies => 'View cookies';

  @override
  String get browserSetUa => 'Set UA';

  @override
  String get browserUaModeAuto => 'Auto (follow system)';

  @override
  String get browserUaModeDesktop => 'Desktop';

  @override
  String get browserUaModeMobile => 'Mobile';

  @override
  String get browserRefresh => 'Refresh';

  @override
  String get browserSystemBrowser => 'System browser';

  @override
  String get browserTroubleshootNetwork => 'Troubleshoot network';

  @override
  String get browserUnsupportedPlatform =>
      'Embedded browser is not supported on this platform';

  @override
  String get browserOpenedInSystem => 'Attempted to open in the system browser';

  @override
  String get browserReopenInSystem => 'Reopen in system browser';

  @override
  String get browserAndroidErrorTitle => 'No command.';

  @override
  String get browserAndroidErrorCause => 'Cause';

  @override
  String get browserAndroidErrorDetail =>
      'WebView initialization failed\nYour system WebView may be outdated or disabled';

  @override
  String get browserUpdateWebview =>
      'Update Android System WebView on Google Play';

  @override
  String get browserOpenDevOptions =>
      'Open developer options to view the WebView implementation';

  @override
  String get browserAppleErrorTitle => 'The app quit unexpectedly';

  @override
  String get browserAppleErrorReport => 'Problem report';

  @override
  String get browserAppleErrorDetail =>
      'Unable to initialize the embedded browser on this device. Please make sure your operating system is up to date.';

  @override
  String get browserBsodMessage =>
      'Your WebView2 ran into a problem. We need to collect some error info and then restart the app for you.';

  @override
  String get browserBsodNoRestart =>
      '(Actually no restart needed, just install the component)';

  @override
  String get browserBsodComplete => '100% complete';

  @override
  String get browserBsodSolutions => 'View solutions:';

  @override
  String get browserBsodDownload => 'Download WebView2 runtime';

  @override
  String get browserBsodWinUpdate => 'Open Windows Update settings';

  @override
  String get browserBsodScanQr => 'Scan this QR code for solutions';

  @override
  String get browserBsodStopCode => 'Stop code: WEBVIEW2_RUNTIME_MISSING';

  @override
  String get browserCantOpenExternal => 'Could not open the external link';

  @override
  String get callOutgoing => 'Calling...';

  @override
  String get callIncoming => 'Incoming call...';

  @override
  String get callConnecting => 'Connecting...';

  @override
  String get chatConnectionNotEstablishedImage =>
      'No connection, cannot send image';

  @override
  String get chatImageSent => '✅ Image sent';

  @override
  String get chatImageSendFailed => 'Failed to send image';

  @override
  String chatClipboardImageProcessFailed(String error) {
    return 'Failed to process clipboard image: $error';
  }

  @override
  String get chatImageStaged => '🖼️ Image added to input';

  @override
  String get chatClipboardNoImage => 'No image data in clipboard';

  @override
  String chatClipboardImageFetchFailed(String error) {
    return 'Failed to get clipboard image: $error';
  }

  @override
  String get chatClipboardEmptyOrUnsupported =>
      'Clipboard is empty or the format is unsupported';

  @override
  String get chatConnectionNotEstablishedFile =>
      'No connection, cannot send file';

  @override
  String get chatFileNotExist => 'File does not exist';

  @override
  String get chatFileSendFailed => 'Failed to send file';

  @override
  String chatFileSentSuccess(String fileName) {
    return '✅ $fileName sent';
  }

  @override
  String chatFileSendError(String error) {
    return 'Failed to send file: $error';
  }

  @override
  String get chatIpUnknown => 'Unknown IP';

  @override
  String get chatReconnecting => 'Reconnecting...';

  @override
  String get chatReconnectFailed =>
      'Reconnect failed. Check your network or whether the peer is online.';

  @override
  String get chatStatusUnknown => 'Unknown status';

  @override
  String get chatStatusWaiting => 'Waiting for connection';

  @override
  String get chatMe => 'Me';

  @override
  String get chatFileInfoLost => '(File info missing)';

  @override
  String chatOpenFileFailed(String message) {
    return 'Could not open file: $message';
  }

  @override
  String get chatFileNotDownloaded => 'File has not been downloaded';

  @override
  String chatOpenFileError(String error) {
    return 'Failed to open file: $error';
  }

  @override
  String get chatFilePathUnavailable =>
      'Could not get file path (Android permission limits?)';

  @override
  String chatPickFileFailed(String error) {
    return 'Failed to pick file: $error';
  }

  @override
  String get chatImagePathUnavailable => 'Could not get image path';

  @override
  String chatPickImageFailed(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String get chatCopyText => 'Copy text';

  @override
  String get chatSelectText => 'Select text';

  @override
  String get chatOpenFile => 'Open file';

  @override
  String get chatCopyImage => 'Copy image';

  @override
  String get chatSaveImage => 'Save image';

  @override
  String get chatCopyingImage => 'Copying image...';

  @override
  String get chatImageCopied => '✅ Image copied to clipboard';

  @override
  String get chatCopyFailed => 'Copy failed';

  @override
  String chatCopyImageFailed(String error) {
    return 'Failed to copy image: $error';
  }

  @override
  String get chatSaving => 'Saving...';

  @override
  String get chatSaveSuccess => '✅ Saved';

  @override
  String chatSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get chatMessageContent => 'Message content';

  @override
  String get chatEmptyContent => '(It\'s empty here)';

  @override
  String get chatDeleteMessageConfirm =>
      'Are you sure you want to delete this message?';

  @override
  String get chatMessageDeleted => 'Message deleted';

  @override
  String get chatOpenLinkTitle => 'Open link';

  @override
  String chatWillOpen(String url) {
    return 'Will open: $url';
  }

  @override
  String get chatBrowserTitle => 'In-app web browser';

  @override
  String get chatCantOpenLink => 'Could not open link';

  @override
  String chatOpenLinkFailed(String error) {
    return 'Failed to open link: $error';
  }

  @override
  String get chatPlusImage => 'Image';

  @override
  String get chatPlusFile => 'File';

  @override
  String get chatImageReady => 'Image ready';

  @override
  String get chatMore => 'More';

  @override
  String get chatPasteImage => 'Paste image';

  @override
  String get chatInputHint => 'Type a message...';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String get chatSend => 'Send';

  @override
  String get chatInvalidAddress => 'Invalid connection address, cannot send';

  @override
  String get chatImageSendError => 'Image send failed';

  @override
  String chatSendFailed(String error) {
    return 'Send failed: $error';
  }

  @override
  String get chatConnStatusUnknown =>
      'Connection status unknown, cannot send message';

  @override
  String get chatPendingCannotSend =>
      'Waiting for the peer to verify, cannot send message';

  @override
  String get chatConnRejected => 'Connection was rejected';

  @override
  String get chatConnDisconnected => 'The peer has disconnected';

  @override
  String get chatConnNotEstablished =>
      'Connection has not been established, cannot send message';

  @override
  String get chatNoMessages => 'No messages yet, start chatting';

  @override
  String get chatDisconnectedRetry => 'Connection lost, tap to reconnect';

  @override
  String get chatRejectedRetry => 'Connection rejected, tap to retry';

  @override
  String get chatExpandInput => 'Expand input bar';

  @override
  String get discoverMyLanIps => 'My LAN IPs';

  @override
  String get discoverNoIpOfType =>
      'No valid IP of this type found. Please check your network connection.';

  @override
  String discoverIpCopied(String ip) {
    return 'Copied $ip';
  }

  @override
  String get discoverTitle => 'Discover nearby devices';

  @override
  String get discoverMyIp => 'My IP';

  @override
  String get discoverRefreshBroadcast => 'Refresh/Broadcast';

  @override
  String get discoverLanDevices => 'LAN devices';

  @override
  String get discoverSearching => 'Searching for nearby devices...';

  @override
  String get discoverSendRequest => 'Tap to send a connection request';

  @override
  String get discoverPendingVerify => 'Waiting for peer verification...';

  @override
  String get discoverRejectedRetry => 'Rejected, tap to retry';

  @override
  String get discoverDisconnectedRetry => 'Disconnected, tap to reconnect';

  @override
  String get discoverUnknownDevice => 'Unknown device';

  @override
  String get discoverAlreadyConnected => 'This device is already connected';

  @override
  String get discoverAlreadyPending =>
      'Waiting for peer verification, please do not send again';

  @override
  String get discoverConnectFailed =>
      'Connection failed. Check your network or whether the peer is online.';

  @override
  String get discoverManualConnect => 'Manually connect to a peer';

  @override
  String get discoverConnectIpHint =>
      'Enter IP address (e.g. 192.168.1.100 / fe80::1)';

  @override
  String get displayScaleCompact => 'Compact mode · Show more content';

  @override
  String get displayScaleSmall => 'Slightly smaller · Good for large screens';

  @override
  String get displayScaleDefault => 'Default';

  @override
  String get displayScaleLarge => 'Slightly larger · Easier to read';

  @override
  String get displayScaleLargeFont => 'Large text · Accessibility friendly';

  @override
  String get displayScaleHuge => 'Extra large · Assistive features';

  @override
  String get displayScaleMin => 'Smallest · Highest information density';

  @override
  String get displayScaleCompactBig => 'Compact · Good for large screens';

  @override
  String get displayScaleSystemDefault => 'System default';

  @override
  String get displayScaleLargeFontShort => 'Large text · Accessibility';

  @override
  String get displayScaleTitle => 'Display Scale';

  @override
  String get displaySplashBackground => 'Splash background';

  @override
  String get displaySplashBackgroundCustom =>
      'Custom image, applies on next launch';

  @override
  String get displaySplashBackgroundDefault => 'Default';

  @override
  String get displaySplashBackgroundSetDone =>
      'Splash background set — takes effect on next launch';

  @override
  String get displaySplashBackgroundSetFailed =>
      'Failed to set splash background';

  @override
  String get displaySplashBackgroundCleared =>
      'Restored default splash background';

  @override
  String get displaySplashBackgroundClearTooltip => 'Reset';

  @override
  String get displayHeroTransitionBlur => 'Use new animations';

  @override
  String get displayIosPushTransition => 'iOS-style page transitions';

  @override
  String get displayIosPushTransitionCorner => 'Transition corner radius';

  @override
  String get displayIosPushTransitionCornerAuto => 'Match screen corners';

  @override
  String get displayIosPushTransitionCornerUnsupported =>
      'Screen corner radius unavailable, using the manual value below';

  @override
  String get searchIosPushTransition => 'iOS page transition animation';

  @override
  String get pageBgTitle => 'Page background';

  @override
  String get pageBgSubtitle =>
      'Background image shared by settings-style pages, croppable after selection';

  @override
  String get pageBgEnabled => 'Show page background';

  @override
  String get pageBgOpacity => 'Background opacity';

  @override
  String get pageBgBlur => 'Background blur';

  @override
  String get pageBgNotSet => 'Not set';

  @override
  String get pageBgPick => 'Pick and crop image';

  @override
  String get pageBgClear => 'Remove background';

  @override
  String get pageBgContentSection => 'Content pages share';

  @override
  String get pageBgContentEnabled => 'Use on content pages';

  @override
  String get pageBgContentSubtitle =>
      'Search / Recommend / Hot / Anime / Live pages share this background image';

  @override
  String get pageBgContentOpacity => 'Content opacity';

  @override
  String get pageBgContentBlur => 'Content blur';

  @override
  String get pageBgContentPick => 'Pick & crop for content pages';

  @override
  String get pageBgContentClear => 'Clear content pages background';

  @override
  String get pageBgSaved => 'Background updated';

  @override
  String get pageBgCleared => 'Background removed';

  @override
  String get pageBgPickFailed => 'Failed to pick image';

  @override
  String get cropTitle => 'Crop background';

  @override
  String get cropAspectFree => 'Free';

  @override
  String get cropApply => 'Apply';

  @override
  String get cropReset => 'Reset';

  @override
  String get displayAdvancedGlass => 'Advanced rendering';

  @override
  String get displayDisableLiquidGlassMenus => 'Reduce effects';

  @override
  String get displayMenuJelly => 'Menu jelly animation';

  @override
  String get displayMenuJellyHint =>
      'Liquid morph animation for popup menus (off: menus appear instantly)';

  @override
  String get displayBottomBarJelly => 'Bottom bar jelly effect';

  @override
  String get displayBottomBarJellyHint =>
      'Jelly physics of the bottom bar indicator (off: simple color change)';

  @override
  String get displayVideoCardGlass => 'Video card glass material';

  @override
  String get displayVideoCardGlassHint =>
      'Glass material for video cards (performance heavy: many glass cards per screen)';

  @override
  String get displayChatGlass => 'Chat / message glass material';

  @override
  String get displayChatGlassHint =>
      'Use liquid glass for chat bubbles and message cards';

  @override
  String get displayLiquidGlassTuner => 'Liquid glass tuning';

  @override
  String get displayLiquidGlassTunerSubtitle =>
      'Adjust glass thickness, blur, tint, refraction and other material parameters';

  @override
  String get lgTunerPreview => 'Live preview';

  @override
  String get lgTunerSectionMaterial => 'Material parameters';

  @override
  String get lgTunerThickness => 'Thickness';

  @override
  String get lgTunerBlur => 'Background blur';

  @override
  String get lgTunerTint => 'Tint';

  @override
  String get lgTunerSaturation => 'Saturation';

  @override
  String get lgTunerRefractiveIndex => 'Refractive index';

  @override
  String get lgTunerLightIntensity => 'Highlight intensity';

  @override
  String get lgTunerAmbient => 'Ambient light';

  @override
  String get lgTunerLightAngle => 'Light angle';

  @override
  String get lgTunerAberration => 'Chromatic dispersion';

  @override
  String get lgTunerReset => 'Reset';

  @override
  String get lgTunerNote =>
      'Changes apply instantly and globally: glass surfaces without explicit parameters (dropdown menus, dialogs, etc.) follow these values, while surfaces with explicit styles (e.g. the chat top bar) stay independent.';

  @override
  String get lgTunerFallbackNote =>
      'Advanced glass rendering (Impeller) is unavailable on this platform, so the preview shows the FakeGlass fallback. Thickness, refraction and saturation only apply on mobile.';

  @override
  String get displayScaleReset => 'Reset to 100%';

  @override
  String get displayScaleFineTune => 'Fine tune';

  @override
  String get displayScalePresets => 'Quick presets';

  @override
  String get displayScaleNote =>
      'The scale applies globally to text and some layout sizes. Set it to 100% to restore the default. Changes take effect immediately without a restart.';

  @override
  String displayScaleConnCount(int count) {
    return '$count connections';
  }

  @override
  String get displayThemeLight => 'Light';

  @override
  String get displayThemeDark => 'Dark';

  @override
  String get displaySettingsTitle => 'Display';

  @override
  String get displaySectionAppearance => 'Appearance';

  @override
  String get displayThemeMode => 'Theme mode';

  @override
  String get displayPureBlack => 'Pure black dark mode';

  @override
  String get displayPureBlackOn => 'Dark mode (pure black)';

  @override
  String get displayOff => 'Off';

  @override
  String get displaySectionPersonalize => 'Personalization';

  @override
  String get displayThemeColor => 'Theme color';

  @override
  String get displayFollowSystemColor => 'Follow system color';

  @override
  String get displayFontWeight => 'Font weight';

  @override
  String get displaySeedDefaultGreen => 'Default green';

  @override
  String get displaySeedPink => 'Pink';

  @override
  String get displaySeedRed => 'Red';

  @override
  String get displaySeedOrange => 'Orange';

  @override
  String get displaySeedAmber => 'Amber';

  @override
  String get displaySeedYellow => 'Yellow';

  @override
  String get displaySeedLime => 'Lime';

  @override
  String get displaySeedLightGreen => 'Light green';

  @override
  String get displaySeedGreen => 'Green';

  @override
  String get displaySeedCyan => 'Cyan';

  @override
  String get displaySeedTeal => 'Teal';

  @override
  String get displaySeedLightBlue => 'Light blue';

  @override
  String get displaySeedBlue => 'Blue';

  @override
  String get displaySeedIndigo => 'Indigo';

  @override
  String get displaySeedPurple => 'Purple';

  @override
  String get displaySeedDeepPurple => 'Deep purple';

  @override
  String get displaySeedBlueGrey => 'Blue grey';

  @override
  String get displaySeedBrown => 'Brown';

  @override
  String get displaySeedGrey => 'Grey';

  @override
  String get displaySeedCustom => 'Custom';

  @override
  String displayWeightThin(int weight) {
    return 'Thin ($weight)';
  }

  @override
  String displayWeightLight(int weight) {
    return 'Light ($weight)';
  }

  @override
  String displayWeightRegular(int weight) {
    return 'Regular ($weight)';
  }

  @override
  String displayWeightMedium(int weight) {
    return 'Medium ($weight)';
  }

  @override
  String displayWeightBold(int weight) {
    return 'Bold ($weight)';
  }

  @override
  String displayWeightBlack(int weight) {
    return 'Black ($weight)';
  }

  @override
  String displayWeightCustom(int weight) {
    return 'Custom ($weight)';
  }

  @override
  String get fontWeightThin => 'Thin';

  @override
  String get fontWeightLight => 'Light';

  @override
  String get fontWeightRegular => 'Regular';

  @override
  String get fontWeightMedium => 'Medium';

  @override
  String get fontWeightBold => 'Bold';

  @override
  String get fontWeightBlack => 'Black';

  @override
  String get fontWeightSampleText =>
      'The quick brown fox jumps over the lazy dog.\nThe quick brown fox jumps over the lazy dog.';

  @override
  String get fontWeightSaveApply => 'Save and apply';

  @override
  String get geetestTitle => 'Complete slider verification';

  @override
  String get geetestInitFailed =>
      'Captcha component failed to initialize. Please retry or use another login method.';

  @override
  String get geetestUnsupported =>
      'Embedded captcha is not supported on this platform. Please use QR code or Cookie login.';

  @override
  String get slicerPickImageFirst => 'Please select an image first';

  @override
  String get slicerRowColInvalid =>
      'Row and column counts must be greater than 0';

  @override
  String get slicerSuccess =>
      'Sliced successfully and added to the Start screen';

  @override
  String slicerSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get slicerTitle => 'Image Slicer Tile';

  @override
  String get slicerTileSize => 'Tile size (all slices are the same)';

  @override
  String get slicerColsLabel => 'Columns (Cols)';

  @override
  String get slicerRowsLabel => 'Rows (Rows)';

  @override
  String slicerPreview(int count, String type) {
    return 'Preview: will be sliced into $count $type tiles';
  }

  @override
  String get slicerProcessing => 'Processing...';

  @override
  String get slicerSaveToStart => 'Save to Start screen';

  @override
  String get viewerSaving => 'Saving...';

  @override
  String get viewerSaveSuccess => 'Saved';

  @override
  String viewerSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get viewerShareImage => 'Share image';

  @override
  String viewerShareFailed(String error) {
    return 'Share failed: $error';
  }

  @override
  String get viewerCopying => 'Copying...';

  @override
  String viewerCopyFailed(String error) {
    return 'Copy failed: $error';
  }

  @override
  String get viewerSaveToAlbum => 'Save to gallery';

  @override
  String get viewerCopyToClipboard => 'Copy to clipboard';

  @override
  String get viewerImageLoadFailed => 'Failed to load image';

  @override
  String get viewerImageDataNotFound => 'Image data not found';

  @override
  String get userSpaceMidInvalid => 'Invalid mid';

  @override
  String get userSpaceNoCard => 'Response is missing card';

  @override
  String get userSpaceNoList => 'Response is missing list';

  @override
  String get searchTypeVideo => 'Videos';

  @override
  String get searchTypeBangumi => 'Anime';

  @override
  String get searchTypeFt => 'Movies & TV';

  @override
  String get searchTypeLive => 'Live';

  @override
  String get searchTypeUser => 'Users';

  @override
  String get searchTypeArticle => 'Articles';

  @override
  String get tenThousandUnit => 'K';

  @override
  String searchVideoMeta(String play, String danmaku) {
    return '$play views · $danmaku danmaku';
  }

  @override
  String searchScore(String score) {
    return 'Rating $score';
  }

  @override
  String searchOnline(String count) {
    return '$count online';
  }

  @override
  String searchUserMeta(String fans, String videos) {
    return '$fans fans · $videos videos';
  }

  @override
  String searchArticleMeta(String views, String replies) {
    return '$views reads · $replies comments';
  }

  @override
  String get searchBadgeCourse => 'Course';

  @override
  String get searchBadgeLive => 'Live';

  @override
  String get searchBadgeCoop => 'Collab';

  @override
  String get searchBadgeLiveNow => 'Live now';

  @override
  String get searchKeywordEmpty => 'Keyword is empty';

  @override
  String get searchBadResponse => 'Unexpected response format';

  @override
  String get searchFailed => 'Search failed';

  @override
  String get searchGaiaParamMissing => 'gaia register: missing parameters';

  @override
  String searchGaiaRegisterError(String error) {
    return 'gaia register error: $error';
  }

  @override
  String searchGaiaValidateFailed(int isValid) {
    return 'gaia validate failed (is_valid=$isValid)';
  }

  @override
  String searchGaiaValidateError(String error) {
    return 'gaia validate error: $error';
  }

  @override
  String get commentOidEmpty => 'oid is empty';

  @override
  String commentException(String error) {
    return 'Exception: $error';
  }

  @override
  String commentSubHttpError(int code) {
    return 'Replies HTTP $code';
  }

  @override
  String get commentSubNoData => 'Replies response is missing data';

  @override
  String commentSubException(String error) {
    return 'Replies error: $error';
  }

  @override
  String get commentNotLoggedIn =>
      'Not logged in or \"Carry Cookie\" is turned off';

  @override
  String get commentMissingJct =>
      'Cookie is missing bili_jct. Please log in again';

  @override
  String commentNetworkError(String error) {
    return 'Network error: $error';
  }

  @override
  String commentApiError(String message, int code) {
    return '$message (code=$code)';
  }

  @override
  String get deviceOs => 'Operating system';

  @override
  String get deviceBuild => 'Build number';

  @override
  String get deviceSecurityPatch => 'Security patch';

  @override
  String get deviceOem => 'OEM manufacturer';

  @override
  String get deviceBrand => 'Brand';

  @override
  String get deviceModel => 'Model';

  @override
  String get deviceRomVersion => 'ROM / Display version';

  @override
  String get deviceFingerprint => 'Device fingerprint';

  @override
  String get deviceName => 'Device name';

  @override
  String get deviceComputerName => 'Computer name';

  @override
  String get deviceHardwareModel => 'Hardware model';

  @override
  String get deviceKernel => 'Kernel version';

  @override
  String get deviceDistro => 'Distribution';

  @override
  String get deviceVersion => 'Version';

  @override
  String get devicePlatform => 'Platform';

  @override
  String deviceInfoFailed(String error) {
    return 'Failed to get info: $error';
  }

  @override
  String get logWebUnsupported => '(File logging is not supported on the Web)';

  @override
  String get logNotInitialized => '(Not initialized)';

  @override
  String logAppDataDir(String path) {
    return 'App data directory\n$path';
  }

  @override
  String logAppDataRoaming(String path) {
    return 'AppData (Roaming)\n$path';
  }

  @override
  String logAppSupport(String path) {
    return 'Application Support\n$path';
  }

  @override
  String logLocalDataDir(String path) {
    return 'Local data directory\n$path';
  }

  @override
  String get nowPlayingVideo => 'Playing video';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get unnamedPlaylist => 'Untitled playlist';

  @override
  String get unknownVideo => 'Unknown video';

  @override
  String dohQueryFailed(int code) {
    return 'DoH query failed: HTTP $code';
  }

  @override
  String get tcpConnectSuccess => 'TCP connection succeeded';

  @override
  String get netModeCompat =>
      'Host-mapped IP direct connection, bypassing SNI interference';

  @override
  String get netModeStandard => 'System default network stack';

  @override
  String netHostResolveFailed(String host) {
    return 'Unable to resolve host $host';
  }

  @override
  String get biliCookieEmpty => 'Cookie is empty';

  @override
  String get biliCookieIncomplete =>
      'Incomplete Cookie. Copy the full Cookie from your browser (must include SESSDATA)';

  @override
  String get biliCookieMissingJct =>
      'Cookie is missing bili_jct. Re-copy the full Cookie from your browser (likes and comments depend on it)';

  @override
  String get biliCookieInvalid =>
      'Invalid or expired Cookie. Copy it again from your browser';

  @override
  String get biliLoginSuccess => 'Logged in';

  @override
  String biliHttpError(int code) {
    return 'HTTP $code';
  }

  @override
  String get biliRiskBlocked =>
      'Request blocked by risk control (-412). Please retry later';

  @override
  String get biliQrExpired => 'QR code expired';

  @override
  String get biliQrScanned => 'Scanned. Confirm on your phone';

  @override
  String get biliQrWaiting => 'Waiting to scan';

  @override
  String get biliRequestFailed => 'Request failed';

  @override
  String get biliResponseNoData => 'Response is missing data';

  @override
  String get biliQrNoSessionCookie =>
      'Failed to obtain the session Cookie. Refresh the QR code and retry';

  @override
  String get biliQrMissingJct =>
      'QR login didn\'t return a full session (missing bili_jct). Use \"Paste Cookie\" or \"Browser login\" instead';

  @override
  String get biliNoSessionCookie => 'Failed to obtain the session Cookie';

  @override
  String get biliWebKeyFailed =>
      'Failed to get the login public key. Check your network';

  @override
  String get biliPwdEncryptFailed => 'Failed to encrypt the password';

  @override
  String get biliNeedGeetest => 'Slider verification required';

  @override
  String get biliUnknownError => 'Unknown error';

  @override
  String get csPlaylists => 'Playlists';

  @override
  String get csDanmaku => 'Danmaku';

  @override
  String get csCloudEncrypted =>
      'Cloud data is encrypted. Enter the sync passphrase in WebDAV settings first';

  @override
  String get csCloudPassMismatch =>
      'Cloud data is encrypted and the sync passphrase doesn\'t match. Cannot sync';

  @override
  String get csCloudNoFile => 'No playlist file on the cloud. Cannot restore';

  @override
  String get csRestoredFromCloud => 'Restored from cloud';

  @override
  String get csSyncDone => 'Sync complete';

  @override
  String csUploadBgCount(int count) {
    return 'Uploaded $count background images';
  }

  @override
  String csDownloadBgCount(int count) {
    return 'Downloaded $count background images';
  }

  @override
  String csUploadedFileCount(int count) {
    return 'Uploaded $count file(s)';
  }

  @override
  String csDownloadedFileCount(int count) {
    return 'Downloaded $count file(s)';
  }

  @override
  String csMergedListsCount(int count) {
    return 'Merged $count playlist(s)';
  }

  @override
  String get csEncrypted => 'Encrypted';

  @override
  String csSyncFailed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String csUploadedPlaylists(int count) {
    return 'Uploaded $count playlist(s) to the cloud';
  }

  @override
  String csDanmakuSummary(int uploaded, int downloaded) {
    return 'Uploaded $uploaded, downloaded $downloaded';
  }

  @override
  String csDanmakuFailed(int failed, String details) {
    return ', $failed failed ($details)';
  }

  @override
  String get unknownUser => 'Unknown user';

  @override
  String transferSpeedBody(String fileName, String speed) {
    return '$fileName  $speed KB/s';
  }

  @override
  String get sendingFile => 'Sending file';

  @override
  String receivingFile(String fileName) {
    return 'Receiving: $fileName';
  }

  @override
  String get notificationChannelName => 'Chat messages';

  @override
  String get notificationChannelDesc =>
      'Receive chat messages and quick replies';

  @override
  String get notificationReply => 'Reply';

  @override
  String get screenshotSavedTitle => 'Screenshot saved';

  @override
  String get screenshotSavedToAlbum => 'Screenshot saved to album';

  @override
  String get notificationConfirm => 'OK';

  @override
  String get callInProgressError => 'There is an active call. Hang up first';

  @override
  String get callTcpFailed =>
      'Failed to connect to the peer (TCP setup failed). Make sure the peer is online';

  @override
  String get callConnectionDropped =>
      'Connection dropped right after setup. Check the network or the peer';

  @override
  String callInitFailed(String error) {
    return 'Failed to start the call: $error';
  }

  @override
  String callAcceptFailed(String error) {
    return 'Failed to answer the call: $error';
  }

  @override
  String get callRecordVoice => 'Voice call';

  @override
  String get callRecordMissedOutgoing => 'Missed outgoing call';

  @override
  String get callRecordRejected => 'Rejected call';

  @override
  String get callRecordMissedIncoming => 'Missed call';

  @override
  String get callPeerNoAnswer => 'The peer didn\'t answer';

  @override
  String get callUnknown => 'Unknown';

  @override
  String get callInProgress => 'In call';

  @override
  String get webdavHttpWarning =>
      'Warning: Using HTTP sends credentials in plaintext. HTTPS is recommended.';

  @override
  String get webdavConfigRequired =>
      'Please fill in the server URL and username first';

  @override
  String get webdavAuthFailed =>
      'Authentication failed: wrong username or password';

  @override
  String webdavConnectFailed(int code) {
    return 'Connection failed: HTTP $code';
  }

  @override
  String webdavNetworkError(String msg) {
    return 'Network error: could not reach the server ($msg)';
  }

  @override
  String webdavUnknownError(String error) {
    return 'Unknown error: $error';
  }

  @override
  String get webdavNotConfigured => 'WebDAV is not configured';

  @override
  String webdavLocalFileMissing(String path) {
    return 'Local file does not exist: $path';
  }

  @override
  String webdavUploadFailed(int code) {
    return 'Upload failed: HTTP $code';
  }

  @override
  String webdavUploadError(String error) {
    return 'Upload error: $error';
  }

  @override
  String webdavDownloadFailed(int code) {
    return 'Download failed: HTTP $code';
  }

  @override
  String webdavDownloadError(String error) {
    return 'Download error: $error';
  }

  @override
  String webdavDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String webdavListFailed(String error) {
    return 'Failed to list files: $error';
  }

  @override
  String webdavPropfindFailed(int code) {
    return 'PROPFIND failed: HTTP $code';
  }

  @override
  String webdavNetworkErr(String msg) {
    return 'Network error: $msg';
  }

  @override
  String webdavPreparingBackup(int count) {
    return 'Preparing to back up $count files...';
  }

  @override
  String webdavBackingUp(String nickname, String fileName) {
    return 'Backing up ($nickname) $fileName';
  }

  @override
  String webdavBackupDone(int success, int fail) {
    return 'Backup done: $success succeeded, $fail failed';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonConnect => 'Connect';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonDelete => 'Delete';

  @override
  String get drawerHome => 'Home';

  @override
  String get drawerVerificationRequests => 'Verification Requests';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerAbout => 'About';

  @override
  String get drawerCloseMenu => 'Close menu';

  @override
  String get drawerLockNow => 'Lock now';

  @override
  String get drawerNoNickname => 'No nickname set';

  @override
  String get drawerSwitchToDark => 'Switch to dark mode';

  @override
  String get drawerSwitchToLight => 'Switch to light mode';

  @override
  String get drawerLightMode => 'Light mode';

  @override
  String get drawerDarkMode => 'Dark mode';

  @override
  String get drawerSystemMode => 'Follow system';

  @override
  String drawerThemeSwitched(String mode) {
    return 'Switched to $mode';
  }

  @override
  String drawerFetchFailed(String error) {
    return 'Failed to fetch: $error';
  }

  @override
  String get drawerNoDeviceInfo => 'No device info';

  @override
  String get drawerBackgroundTitle => 'Sidebar background';

  @override
  String get drawerBackgroundHasCustom =>
      'A custom background is set. You can change or remove it.';

  @override
  String get drawerBackgroundNoCustom =>
      'Set a personalized background image for the sidebar.';

  @override
  String get drawerBackgroundUpdated => '✅ Sidebar background updated';

  @override
  String drawerBackgroundSetFailed(String error) {
    return '❌ Failed to set: $error';
  }

  @override
  String get drawerBackgroundChange => 'Change background';

  @override
  String get drawerBackgroundSelect => 'Choose background image';

  @override
  String get drawerBackgroundRestored => 'Default background restored';

  @override
  String get drawerBackgroundRemove => 'Remove background';

  @override
  String get homeOpenMenu => 'Open menu';

  @override
  String get homeAddConnection => 'Add connection';

  @override
  String get homeMessages => 'Messages';

  @override
  String get homeNoConnections => 'No connections';

  @override
  String get homePullToRefreshHint => 'Pull to refresh or tap + to add';

  @override
  String get homeLoadFailed => 'Failed to load chats, please retry';

  @override
  String get homeRetryLoad => 'Retry';

  @override
  String get homeUnknownAddress => 'Unknown address';

  @override
  String get homeNoMessages => 'No messages';

  @override
  String homeFileMessage(String fileName) {
    return '[File] $fileName';
  }

  @override
  String get homeFileFallbackName => 'File';

  @override
  String get homeMessagePlaceholder => '[Message]';

  @override
  String get connectionLost => 'Connection lost';

  @override
  String get openVideoFailed => 'Failed to open the video';

  @override
  String get connectDialogTitle => 'Connect to peer';

  @override
  String get connectIpHint =>
      'Enter IP address (e.g. 192.168.1.100 or fe80::1)';

  @override
  String get connectIpEmpty => 'Please enter an IP address';

  @override
  String get connectIpInvalid => 'Invalid IP address format';

  @override
  String get connectIpNotLan => 'Only LAN IP addresses are allowed';

  @override
  String get connectRequestSent =>
      'Connection request sent, waiting for verification';

  @override
  String get connectFailed =>
      'Connection failed. Check the IP address or whether the peer is online';

  @override
  String get homeScanQr => 'Scan QR code';

  @override
  String get homeMyQrCode => 'My QR code';

  @override
  String get homeManualAdd => 'Add manually';

  @override
  String get scannedFriends => 'Friends added by QR';

  @override
  String get scanTitle => 'Scan';

  @override
  String get scanTitleWebdav => 'Scan WebDAV address';

  @override
  String get scanHint => 'Align the QR code / barcode within the frame';

  @override
  String get scanHintWebdav =>
      'Align the WebDAV server address QR code within the frame';

  @override
  String get scanHintAddFriend =>
      'Align your friend\'s device QR code within the frame';

  @override
  String get scanPreparing => 'Preparing camera...';

  @override
  String get scanPermissionNeeded => 'Camera permission required';

  @override
  String get scanPermissionNeededMsg =>
      'Please allow camera access in the permission dialog to scan.';

  @override
  String get scanPermissionDenied => 'Camera permission denied';

  @override
  String get scanPermissionDeniedMsg =>
      'Permission is permanently denied. Enable it manually in system settings.';

  @override
  String get scanCameraUnavailable => 'Camera unavailable';

  @override
  String get scanRetry => 'Retry';

  @override
  String get scanOpenSettings => 'Go to system settings';

  @override
  String get scanTorch => 'Flashlight';

  @override
  String get scanDetectedLink => 'Link detected';

  @override
  String get scanOpenLinkPrompt => 'Open this link in the built-in browser?';

  @override
  String get scanCopy => 'Copy';

  @override
  String get scanOpen => 'Open';

  @override
  String get scanLinkCopied => 'Link copied';

  @override
  String get scanDetectedBiliVideo => 'Bilibili video link detected';

  @override
  String get scanBiliVideoPrompt => 'Open this video in the built-in player?';

  @override
  String scanBiliVideoAt(String time) {
    return 'Jump to $time';
  }

  @override
  String get scanOpenVideo => 'Open video';

  @override
  String get scanDetectedWebdav => 'WebDAV address detected';

  @override
  String get scanWebdavPrompt =>
      'This looks like a WebDAV server address. Fill it into the config automatically?';

  @override
  String get scanOpenInBrowser => 'Open in browser';

  @override
  String get scanFillConfig => 'Fill into config';

  @override
  String get scanDetectedText => 'Text detected';

  @override
  String get scanCopiedToClipboard => 'Copied to clipboard';

  @override
  String get scanClose => 'Close';

  @override
  String get scanResultTitle => 'Scan result';

  @override
  String get scanErrorPermission => 'Camera permission denied';

  @override
  String get scanErrorUnsupported => 'Scanning is not supported on this device';

  @override
  String get scanErrorDisposed => 'Scanner has been disposed. Please retry.';

  @override
  String scanErrorGeneric(String code) {
    return 'Camera unavailable ($code)';
  }

  @override
  String scanInitFailed(String error) {
    return 'Scanner initialization failed: $error';
  }

  @override
  String get scanDetectedDevice => 'Device QR code detected';

  @override
  String get scanAddFriendPrompt => 'Add this device as a friend?';

  @override
  String get scanAddFriend => 'Add friend';

  @override
  String get scanFriendAdded => 'Friend request sent, waiting for verification';

  @override
  String get scanFriendAddFailed =>
      'Failed to add friend. Check the network or whether the peer is online';

  @override
  String get myQrTitle => 'My QR code';

  @override
  String get myQrHint => 'Have your friends scan this QR code to add you';

  @override
  String get myQrEmbedIp => 'The first LAN IP is embedded in the QR code';

  @override
  String get myQrLocalIps => 'Current LAN IPs';

  @override
  String get myQrCopyContent => 'Copy QR content';

  @override
  String get myQrCopied => 'Copied to clipboard';

  @override
  String get myQrNoIp =>
      'No valid LAN IP found. Please check your network connection.';

  @override
  String get displayModeSectionTitle => 'Screen';

  @override
  String get displayModeTitle => 'Screen refresh rate';

  @override
  String get displayModeAuto => 'Auto';

  @override
  String get displayModeSystemTag => '[System]';

  @override
  String get displayModeHint => 'Not working? Try restarting the app';

  @override
  String get displayModeUnsupported =>
      'Screen refresh rate settings are only supported on Android';

  @override
  String get displayModeAndroidOnly => 'Android only';

  @override
  String get displayModeLoading => 'Loading screen refresh rates...';

  @override
  String get displayModeEmpty => 'No screen refresh rates available';

  @override
  String get playerSectionEnhance => 'Picture enhancement';

  @override
  String get superResolutionTitle => 'Super resolution';

  @override
  String get superResolutionOff => 'Off';

  @override
  String get superResolutionEfficiency => 'Efficiency (low overhead)';

  @override
  String get superResolutionQuality => 'Quality (best effect)';

  @override
  String get superResolutionHint =>
      'Real-time enhancement via mpv shaders. Recommended with hardware decoding; works best on anime content';

  @override
  String get skipIntroOutroTitle => 'Skip intro/outro';

  @override
  String get skipIntroOutroHint =>
      'Detects intros/outros via community data; only prompts when the video has BV+CID';

  @override
  String get skipIntro => 'Skip intro';

  @override
  String get skipOutro => 'Skip outro';

  @override
  String playlistDetailEpisodes(int count) {
    return '$count episodes';
  }

  @override
  String get playlistDetailEmpty =>
      'This playlist is empty. Add videos via edit first';

  @override
  String playlistDetailEpisodeOf(int index) {
    return 'Episode $index';
  }

  @override
  String playlistDetailResume(String position) {
    return 'Resumed at $position';
  }

  @override
  String get playlistDetailBgTitle => 'Background image';

  @override
  String get playlistDetailBgPick => 'Choose background image';

  @override
  String get playlistDetailBgChange => 'Change background';

  @override
  String get playlistDetailBgRemove => 'Remove background';

  @override
  String get playlistDetailBgUpdated => '✅ Background updated';

  @override
  String get playlistDetailBgRemoved => 'Default background restored';

  @override
  String playlistDetailBgFail(String error) {
    return 'Failed to set: $error';
  }

  @override
  String get playlistFabRestart => 'Start over';

  @override
  String get playlistMenuMore => 'More actions';

  @override
  String get playlistMenuRename => 'Rename';

  @override
  String get playlistMenuMultiSelect => 'Multi-select';

  @override
  String get playlistMenuDanmaku => 'Danmaku';

  @override
  String get playlistRenameTitle => 'Rename playlist';

  @override
  String get playlistRenameHint => 'Enter a new name';

  @override
  String get playlistRenameSaved => 'Renamed';

  @override
  String get playlistSelectDone => 'Done';

  @override
  String get playlistSelectEmpty => 'Select episodes first';

  @override
  String playlistSelectDelete(int count) {
    return 'Delete selected ($count)';
  }

  @override
  String playlistSelectDeleted(int count) {
    return 'Deleted $count episodes';
  }

  @override
  String get playlistDanmakuTitle => 'Import season danmaku';

  @override
  String get playlistDanmakuSsHint => 'Enter the season SS number (season_id)';

  @override
  String get playlistDanmakuFetchFail =>
      'Failed to fetch episodes. Check the SS number';

  @override
  String playlistDanmakuSelectTitle(int count) {
    return 'Select episodes ($count total, matched in order 1, 2, 3... to playlist episodes 1, 2, 3...)';
  }

  @override
  String get playlistDanmakuSelectAll => 'Select all';

  @override
  String get playlistDanmakuImport => 'Import & attach danmaku';

  @override
  String playlistDanmakuAttached(int count) {
    return 'Danmaku attached to $count episodes';
  }

  @override
  String playlistDanmakuExceed(int selected, int total) {
    return '$selected selected exceed the $total episodes in the list; extras were ignored';
  }

  @override
  String get splitSelectChat => 'Select a chat';

  @override
  String get statusPending => 'Awaiting verification';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusDisconnected => 'Disconnected';

  @override
  String get homeStart => 'Start';

  @override
  String get homeDone => 'Done';

  @override
  String get homeBack => 'Navigate up';

  @override
  String get homeOverview => 'Overview';

  @override
  String get homeLocalUser => 'Local user';

  @override
  String get homeDefaultGroup => 'Default group';

  @override
  String get homeNewGroup => 'New group';

  @override
  String get homeUnnamedGroup => '(Unnamed group)';

  @override
  String get homeDeleteGroupTitle => 'Confirm deletion';

  @override
  String get homeDeleteGroupMessage =>
      'Deleting this group will also delete all tiles in it. Continue?';

  @override
  String get homeNewGroupTitle => 'New group';

  @override
  String get homeGroupNameHint => 'Enter group name';

  @override
  String get homeRenameGroupTitle => 'Name this group';

  @override
  String get homeNewGroupNameHint => 'Enter new group name';

  @override
  String get homeImageSlice => 'Image slice';

  @override
  String tileSizeLabelSmall(String size) {
    return '$size (Small)';
  }

  @override
  String tileSizeLabelWide(String size) {
    return '$size (Wide)';
  }

  @override
  String tileSizeLabelLarge(String size) {
    return '$size (Large)';
  }

  @override
  String get homeGroupOne => 'Group 1';

  @override
  String get homeGroupTwo => 'Group 2';

  @override
  String get homeGroupProductivity => 'Productivity';

  @override
  String get homeGroupLegacy => 'Legacy';

  @override
  String get tileImageSlicer => 'Image slicer';

  @override
  String get tileSystemSettings => 'System settings';

  @override
  String get tileDatabase => 'Database';

  @override
  String get tileLcdDisplay => 'LCD display';

  @override
  String get tileLedDynamic => 'LED dynamic';

  @override
  String get tileLedStatic => 'LED static';

  @override
  String get tilePisScreen => 'PIS screen';

  @override
  String get tileRoutePreview => 'Route preview';

  @override
  String get tileStationEntranceDesign => 'Entrance design';

  @override
  String get tileStationEntrancePillar => 'Entrance pillar';

  @override
  String get tileStationEntranceSideName => 'Entrance side name';

  @override
  String get tilePlatformSideName => 'Platform side name';

  @override
  String get tileScreenDoorCover => 'Screen door cover';

  @override
  String get tileStationNameSign => 'Station name sign';

  @override
  String get tileGeneralSign => 'General sign';

  @override
  String get tileLineSymbol => 'Line symbol';

  @override
  String get tileBusLcd => 'Bus LCD';

  @override
  String get tileJsonEditor => 'JSON editor';

  @override
  String get tileNamingRule => 'Naming rule';

  @override
  String get tilePlatformText => 'Platform text';

  @override
  String get tileDepartureText => 'Departure text';

  @override
  String get tileArrivalText => 'Arrival text';

  @override
  String get tileOperationDirectionLegacy => 'Operation direction (Legacy)';

  @override
  String get tileLegacyLcdWarning => 'Legacy LCD (Warning)';

  @override
  String get tileLinearRoute => 'Linear route';

  @override
  String get tileRoadSign => 'Road sign';

  @override
  String get commentPanelTitle => 'Comments';

  @override
  String commentTotalCount(int count) {
    return '$count comments';
  }

  @override
  String get commentSortHeat => 'By popularity';

  @override
  String get commentSortTime => 'By time';

  @override
  String get commentLoading => 'Loading comments...';

  @override
  String get commentLoadFail => 'Failed to load comments, check network';

  @override
  String get commentLoadMoreFail => 'Failed to load more comments';

  @override
  String get commentNoMore => 'No more comments';

  @override
  String get commentLoadingMore => 'Loading...';

  @override
  String get commentEmpty => 'No comments yet';

  @override
  String get commentViewDialogue => 'View conversation';

  @override
  String get commentDialogueTitle => 'Conversation';

  @override
  String get msgMenuSettings => 'Message settings';

  @override
  String get msgSettingsLoadFail => 'Failed to load message settings';

  @override
  String get msgSettingsSaveFail => 'Failed to save';

  @override
  String get commentPinned => 'Pinned';

  @override
  String get commentDeleted => 'Comment deleted';

  @override
  String get commentExpand => 'Expand';

  @override
  String get commentCollapse => 'Collapse';

  @override
  String get commentTranslateNeedEnable =>
      'Enable AI translation in Language settings first';

  @override
  String get commentTranslateNone => 'No translation available';

  @override
  String get commentReply => 'Reply';

  @override
  String get commentTranslate => 'Translate';

  @override
  String get commentTranslateRestore => 'Show original';

  @override
  String get commentLikeTooltip => 'Like';

  @override
  String get commentDislikeTooltip => 'Dislike';

  @override
  String commentSubCount(int count) {
    return '$count replies';
  }

  @override
  String commentSubLoadMore(String hint) {
    return 'Load more replies ($hint)';
  }

  @override
  String get commentYesterday => 'Yesterday';

  @override
  String get articleLoadFailed => 'Failed to load article';

  @override
  String get articleNoContent =>
      'Article content is empty or not supported yet';

  @override
  String get articleOpenBrowser => 'Open in browser';

  @override
  String get articleShare => 'Share';

  @override
  String get articleAuthorUnknown => 'Unknown author';

  @override
  String get browserLinkPageTitle => 'Web link';

  @override
  String articleViews(String count) {
    return '$count reads';
  }

  @override
  String get contactPickerTitle => 'Send to contact';

  @override
  String get contactPickerContentLabel => 'Content';

  @override
  String get contactPickerContentHint => 'Enter content to send';

  @override
  String get contactPickerContentEmpty => 'Content cannot be empty';

  @override
  String get contactPickerSearchHint => 'Search contacts';

  @override
  String get contactPickerEmpty => 'No contacts yet';

  @override
  String get contactPickerNoMatch => 'No matching contacts';

  @override
  String get contactPickerSelectAll => 'Select all';

  @override
  String contactPickerSendToCount(int count) {
    return 'Send to $count contact(s)';
  }

  @override
  String contactPickerSent(int count) {
    return 'Sent to $count contact(s)';
  }

  @override
  String contactPickerNotConnected(String name) {
    return '$name is not connected, cannot send';
  }

  @override
  String contactPickerSendFailed(String error) {
    return 'Send failed: $error';
  }

  @override
  String get contactPickerOnline => 'Online';

  @override
  String get contactPickerOffline => 'Offline';

  @override
  String get articleShareToContact => 'Share via chat';

  @override
  String get playerDanmakuList => 'Danmaku list';

  @override
  String playerDanmakuListCount(int count) {
    return 'Danmaku list · $count total';
  }

  @override
  String get playerDanmakuListEmpty => 'No danmaku yet';

  @override
  String get playerDanmakuListNoMatch => 'No matching danmaku';

  @override
  String get playerDanmakuListSearchHint => 'Search danmaku';

  @override
  String get playerDanmakuListJumpCurrent => 'Jump to current position';

  @override
  String get playerViewNotes => 'View notes';

  @override
  String get playerNotesTitle => 'Notes';

  @override
  String playerNotesCount(int count) {
    return 'Notes ($count)';
  }

  @override
  String get playerNotesEmpty => 'No public notes yet';

  @override
  String get playerNotesNoMore => 'No more';

  @override
  String get playerNotesLoadFailed => 'Failed to load notes';

  @override
  String get playerNotesViewFull => 'View full';

  @override
  String get playerWriteNote => 'Write note';

  @override
  String get noteEditorWrite => 'Write note';

  @override
  String get noteEditorTitle => 'Write note';

  @override
  String get noteEditorTitleHint => 'Title (optional)';

  @override
  String get noteEditorContentHint => 'Start taking notes…';

  @override
  String get noteEditorEmoji => 'Emoji';

  @override
  String get noteEditorPublish => 'Publish';

  @override
  String get noteEditorEmptyContent => 'Note content cannot be empty';

  @override
  String get noteEditorContentTooShort =>
      'Content must be at least 10 characters to publish';

  @override
  String get noteEditorNotLoggedIn =>
      'Not logged in: note saved as local draft; log in to publish';

  @override
  String get noteEditorPublished => 'Note published';

  @override
  String get noteEditorPublishNetworkError =>
      'Publish failed (network error); draft saved';

  @override
  String get noteEditorPublishRejected =>
      'Publish rejected by server; draft kept';

  @override
  String get noteEditorDraftSaved => 'Draft auto-saved';

  @override
  String get noteEditorLoggedInHint => 'Logged in: publishing available';

  @override
  String get noteEditorGuestHint =>
      'Not logged in: local drafts only, cannot publish';

  @override
  String noteEditorSavedAt(String hour, String minute) {
    return 'Draft saved $hour:$minute';
  }

  @override
  String noteEditorCharCount(int count) {
    return '$count chars';
  }

  @override
  String get noteEditorMyDraft => 'My draft';

  @override
  String get noteEditorDeleteDraft => 'Delete draft';

  @override
  String get playerMoreTooltip => 'More actions';

  @override
  String get commentComposerBarHint => 'Say something…';

  @override
  String get commentComposerHint => 'Write a comment…';

  @override
  String commentComposerReplyHint(String name) {
    return 'Reply to @$name';
  }

  @override
  String commentComposerReplyTo(String name) {
    return 'Replying to @$name';
  }

  @override
  String get commentComposerEmote => 'Emotes';

  @override
  String get commentComposerSend => 'Send';

  @override
  String get commentComposerEmpty => 'Comment cannot be empty';

  @override
  String get commentComposerEmoteUnavailable =>
      'Emote panel unavailable (not logged in?)';

  @override
  String get commentComposerPickImage => 'Pick image';

  @override
  String get commentComposerMore => 'More';

  @override
  String get commentComposerVideoProgress => 'Video progress';

  @override
  String get commentComposerVideoScreenshot => 'Video screenshot';

  @override
  String commentComposerImageLimit(int count) {
    return 'Up to $count images';
  }

  @override
  String get commentComposerCaptureFailed =>
      'Screenshot failed; start playback first';

  @override
  String get commentComposerUploadFailed => 'Image upload failed, please retry';

  @override
  String get commentComposerFabLabel => 'Post comment';

  @override
  String get commentComposerFabReply => 'Post reply';

  @override
  String get danmakuSendTitle => 'Send danmaku';

  @override
  String get danmakuSendModeLabel => 'Mode';

  @override
  String get danmakuSendFontSizeLabel => 'Size';

  @override
  String get danmakuSendColorLabel => 'Color';

  @override
  String get danmakuFontSizeSmall => 'Small';

  @override
  String get danmakuFontSizeStandard => 'Normal';

  @override
  String get danmakuFontSizeLarge => 'Large';

  @override
  String get danmakuSendCustomColor => 'Custom color';

  @override
  String get danmakuSendColorOk => 'OK';

  @override
  String get danmakuSendPreviewPlaceholder => 'Send a friendly danmaku';

  @override
  String get drawerHistory => 'History';

  @override
  String get drawerWatchLater => 'Watch Later';

  @override
  String get drawerMyCache => 'My Cache';

  @override
  String get historyCenterTitle => 'History';

  @override
  String get historyTabWatch => 'Watch History';

  @override
  String get historyTabPlay => 'Playback';

  @override
  String get historySearchHint => 'Search history...';

  @override
  String get historyPauseHistory => 'Pause history';

  @override
  String get historyResumeHistory => 'Resume history';

  @override
  String get historyPausedTip => 'History is paused';

  @override
  String get historyPausedTipAction => 'Tap to resume';

  @override
  String get historyClearWatchHistory => 'Clear watch history';

  @override
  String get historyClearPlayHistory => 'Clear playback history';

  @override
  String get historyClearAllTitle => 'Clear history';

  @override
  String historyClearAllConfirm(String label) {
    return 'Clear all $label? This cannot be undone.';
  }

  @override
  String get historyNoWatchHistory => 'No watch history';

  @override
  String get historyNoPlayHistory => 'No playback records';

  @override
  String get historyDeleteSelected => 'Delete selected';

  @override
  String historySelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get historySearchNoResult => 'No results';

  @override
  String get historyPauseOnSnack => 'History paused';

  @override
  String get historyResumeOnSnack => 'History resumed';

  @override
  String historyDeleteToast(int count) {
    return 'Deleted $count records';
  }

  @override
  String get myCacheTitle => 'My Cache';

  @override
  String get myCacheSearchHint => 'Search cached videos...';

  @override
  String get myCacheDownloading => 'Downloading';

  @override
  String get myCacheCached => 'Cached';

  @override
  String get myCacheNoCache => 'No cached videos';

  @override
  String myCacheGroupCount(int count) {
    return '$count videos';
  }

  @override
  String get myCacheDeleteGroup => 'Delete group';

  @override
  String get myCacheUpdateDanmaku => 'Update danmaku';

  @override
  String get myCacheClearAllTitle => 'Clear all cache';

  @override
  String myCacheClearAllConfirm(int count, String size) {
    return 'Delete all cached videos ($count videos · $size)?';
  }

  @override
  String get cacheActionDownload => 'Cache';

  @override
  String get cacheActionCached => 'Cached';

  @override
  String get cacheActionCaching => 'Caching';

  @override
  String get cacheToastSuccess => 'Added to download queue';

  @override
  String get cacheToastCached => 'Already cached';

  @override
  String cacheToastFailed(String error) {
    return 'Cache failed: $error';
  }

  @override
  String get drawerRecommend => 'Recommend';

  @override
  String get recommendSourceWeb => 'Web';

  @override
  String get recommendSourceApp => 'App';

  @override
  String get recommendEmpty => 'No recommendations';

  @override
  String get recommendSwitchList => 'Switch to list';

  @override
  String get recommendSwitchGrid => 'Switch to grid';

  @override
  String get sideBarExpand => 'Expand sidebar';

  @override
  String get sideBarCollapse => 'Collapse sidebar';

  @override
  String get sideBarMore => 'More';

  @override
  String get recommendTabHot => 'Hot';

  @override
  String get recommendTabBangumi => 'Bangumi';

  @override
  String get recommendSourceTitle => 'Recommendation source';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsPreferencesSub => 'Miscellaneous & personal preferences';

  @override
  String get settingsPreferencesEmpty => 'No preferences yet';

  @override
  String get prefBottomBarSection => 'Bottom bar style';

  @override
  String get prefUseM3BottomBar => 'Use M3 bottom bar';

  @override
  String get prefUseM3BottomBarDesc =>
      'Replace the glass bottom bar with a standard Material 3 NavigationBar';

  @override
  String get prefBottomBarSearch => 'Bottom bar search entry';

  @override
  String get prefBottomBarSearchDesc =>
      'Show search in the recommend page bottom bar (glass: orphan button at the right; M3: extra destination; top bar search hidden when enabled)';

  @override
  String get prefWindowSection => 'Default window size';

  @override
  String get prefWindowSize => 'Startup window';

  @override
  String get prefRefreshSection => 'Refresh';

  @override
  String get prefRefreshDisplacement => 'Refresh trigger distance';

  @override
  String get prefRefreshDisplacementDesc =>
      'How far to drag down before the refresh triggers';

  @override
  String get prefRefreshEdgeOffset => 'Refresh indicator offset';

  @override
  String get prefRefreshEdgeOffsetDesc =>
      'Distance of the refresh indicator from the top edge';

  @override
  String get userSpaceFollowMutual => 'Mutual follow';

  @override
  String get userSpaceFollowBlocked => 'Blocked';

  @override
  String get userSpaceFollowDone => 'Following';

  @override
  String get userSpaceUnfollowDone => 'Unfollowed';

  @override
  String get userSpaceFollowFail => 'Operation failed, try again later';

  @override
  String get commonTapOutsideToClose => 'Tap outside to close';

  @override
  String get prefFileAssocSection => 'File associations';

  @override
  String get prefFileAssocDefault => 'Set as default app';

  @override
  String get prefFileAssocDefaultSub =>
      'Open video files with NaviFlash on double-click';

  @override
  String get msgCenterTitle => 'Message center';

  @override
  String get msgCenterSubtitle => 'Replies · Mentions · Likes · Messages';

  @override
  String get msgCenterLoginPrompt => 'Sign in to view the message center';

  @override
  String get msgReplyMe => 'Replies';

  @override
  String get msgAtMe => 'Mentions';

  @override
  String get msgLikedMe => 'Likes';

  @override
  String get msgSysNotice => 'Notifications';

  @override
  String get msgMyWhisper => 'Messages';

  @override
  String get msgWhisperSubtitle => 'Your private chats with creators';

  @override
  String msgUnreadCount(int count) {
    return '$count unread';
  }

  @override
  String get msgTimeJustNow => 'Just now';

  @override
  String msgTimeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String msgTimeYesterday(String time) {
    return 'Yesterday $time';
  }

  @override
  String get msgGoLogin => 'Sign in';

  @override
  String get msgDeleteNoticeConfirm => 'Delete this notification?';

  @override
  String get msgDeleted => 'Deleted';

  @override
  String msgLoginPromptFeature(String title) {
    return 'Sign in to view $title';
  }

  @override
  String get msgNoMore => 'No more results';

  @override
  String get msgReplyEmpty => 'No replies yet';

  @override
  String msgUserFallback(String mid) {
    return 'User $mid';
  }

  @override
  String get msgEtAl => ' and others';

  @override
  String msgReplyTitle(String business, int counts) {
    return ' commented $counts times on your $business';
  }

  @override
  String get msgAtEmpty => 'Nobody has mentioned you yet';

  @override
  String msgAtTitle(String business) {
    return ' mentioned you in $business';
  }

  @override
  String get msgDeleteNoticeTitle => 'Delete this notification?';

  @override
  String get msgDeleteNoticeBody => 'It reappears when you get new likes.';

  @override
  String get msgMuteNotice => 'Mute';

  @override
  String get msgMuteNoticeBody =>
      'You will no longer be notified about likes on this item, but it stays in the list.';

  @override
  String get msgSettingSaved => 'Saved';

  @override
  String get msgLoginPromptLikes => 'Sign in to view likes you received';

  @override
  String get msgLikedEmpty => 'No likes yet';

  @override
  String get msgLikedEmptySubtitle => 'Likes on your posts will show up here';

  @override
  String get msgSectionLatest => 'Latest';

  @override
  String get msgSectionTotal => 'Total';

  @override
  String get msgSomeone => 'Someone';

  @override
  String msgEtAlCount(String name, int count) {
    return '$name and $count others';
  }

  @override
  String get msgLikedYou => ' liked you';

  @override
  String msgLikedYourBusiness(String business) {
    return ' liked your $business';
  }

  @override
  String get msgNoticeMuted => 'Notifications off';

  @override
  String get msgUnmuteNotice => 'Unmute';

  @override
  String get msgLikeDetailTitle => 'Likes';

  @override
  String get msgLikeDetailEmpty => 'No likes yet';

  @override
  String get msgSysEmpty => 'No notifications yet';

  @override
  String get msgDeleteSessionTitle => 'Delete chat?';

  @override
  String get msgDeleteSessionBody =>
      'The chat is removed from the list and reappears if they message you again.';

  @override
  String get msgUnpinned => 'Unpinned';

  @override
  String get msgPinned => 'Pinned';

  @override
  String get msgUnpin => 'Unpin';

  @override
  String get msgPin => 'Pin chat';

  @override
  String get msgDeleteSession => 'Delete chat';

  @override
  String get msgLoginPromptWhisper => 'Sign in to view messages';

  @override
  String get msgWhisperEmpty => 'No chats yet';

  @override
  String get msgWhisperEmptySubtitle =>
      'Tap “Message” on a creator’s profile to start chatting';

  @override
  String get msgNoMessage => '[No messages]';

  @override
  String get msgWithdrawConfirm => 'Withdraw this message?';

  @override
  String get msgWithdraw => 'Withdraw';

  @override
  String get msgWithdrawn => 'Withdrawn';

  @override
  String get msgWithdrawnSelf => 'You withdrew a message';

  @override
  String get msgWithdrawnOther => 'The other person withdrew a message';

  @override
  String get msgChatEmpty => 'No messages yet';

  @override
  String get msgChatEmptySubtitle => 'Say hi';

  @override
  String get msgNoEarlier => 'No earlier messages';

  @override
  String get msgInputHint => 'Message…';

  @override
  String get msgPicture => '[Image]';

  @override
  String get msgPictureFailed => '[Image failed to load]';

  @override
  String get msgShare => '[Shared content]';

  @override
  String msgUnsupportedType(String type) {
    return '[Unsupported message type $type]';
  }

  @override
  String get msgVoice => '[Voice]';

  @override
  String get msgCardVideo => 'Video';

  @override
  String get msgCardArticle => 'Article';

  @override
  String get msgCardLive => 'Live';

  @override
  String get msgCardDynamic => 'Post';

  @override
  String get msgCardAlbum => 'Album';

  @override
  String get msgCardInvalid => 'Content unavailable';

  @override
  String get msgCardViewDetail => 'View details';

  @override
  String get msgAutoReply => 'This message is an auto reply';

  @override
  String get msgUploadingImage => 'Uploading image…';

  @override
  String get msgChatSettings => 'Chat settings';

  @override
  String get msgPushReceive => 'Receive message notifications';

  @override
  String get msgPushReceiveDesc =>
      'If disabled, you will no longer receive this user\'s image/text messages or video/article push notifications. Notification-type messages are unaffected.';

  @override
  String get msgPushCloseConfirm => 'Turn off content push?';

  @override
  String get msgPinChat => 'Pin chat';

  @override
  String get msgChatMute => 'Mute notifications';

  @override
  String get msgBlockAdd => 'Block user';

  @override
  String get msgBlockConfirmTitle => 'Block this user?';

  @override
  String get msgBlockConfirmBody =>
      'Blocking will unfollow the user and unsubscribe from their collections, and prevent them from interacting with you or viewing your space.';

  @override
  String get msgReport => 'Report';

  @override
  String msgReportTitle(String name) {
    return 'Report: $name';
  }

  @override
  String get msgReportContentHint =>
      'Report content (required, multiple choice)';

  @override
  String get msgReportReasonHint => 'Report reason (optional, single choice)';

  @override
  String get msgReportReasonRequired =>
      'Select at least one report content item';

  @override
  String get msgReportSuccess => 'Report submitted';

  @override
  String get msgReportFailed => 'Report failed';

  @override
  String get msgReportReasonAvatar => 'Inappropriate avatar';

  @override
  String get msgReportReasonNickname => 'Inappropriate nickname';

  @override
  String get msgReportReasonSign => 'Inappropriate signature';

  @override
  String get msgReportReasonPorn => 'Pornography or vulgarity';

  @override
  String get msgReportReasonFalse => 'False information';

  @override
  String get msgReportReasonForbidden => 'Prohibited content';

  @override
  String get msgReportReasonAttack => 'Personal attack';

  @override
  String get msgReportReasonFraud => 'Gambling or fraud';

  @override
  String get msgReportReasonLink => 'Illicit external links';

  @override
  String get msgRefresh => 'Refresh';

  @override
  String get commonSend => 'Send';

  @override
  String get commonRetry => 'Retry';

  @override
  String get msgInteractions => 'Community';

  @override
  String get msgLoadMore => 'Load more';

  @override
  String get dynamicsTitle => 'Dynamics';

  @override
  String get dynamicsTabAll => 'All';

  @override
  String get dynamicsTabVideo => 'Videos';

  @override
  String get dynamicsTabPgc => 'Anime';

  @override
  String get dynamicsTabArticle => 'Articles';

  @override
  String get dynamicsEmpty => 'No dynamics yet';

  @override
  String get dynamicsLoginPrompt =>
      'Sign in to see dynamics from creators you follow';

  @override
  String get onnxDepSection => 'Smart danmaku mask';

  @override
  String get onnxDepDesc =>
      'Smart danmaku masking needs the ONNX Runtime library and a segmentation model. Neither is bundled with the installer.';

  @override
  String get onnxDepNotInstalled => 'Not installed';

  @override
  String get onnxDepSizeCounting => 'Calculating…';

  @override
  String get onnxDepDownload => 'Download';

  @override
  String get onnxDepUninstall => 'Uninstall';

  @override
  String get onnxDepUninstallTitle => 'Remove smart mask files?';

  @override
  String get onnxDepUninstalled => 'Smart mask files removed';

  @override
  String get onnxDepInstallDone => 'Installed. Smart danmaku masking is ready.';

  @override
  String get onnxDepUnsupported =>
      'Smart danmaku masking is not supported on this platform';

  @override
  String get onnxDepSourceTitle => 'Download source';

  @override
  String get onnxDepSourceDesc =>
      'Custom download URL. Leave empty to use the built-in default.';

  @override
  String get onnxDepNeedInstall =>
      'Download the smart mask files first in Settings, then AI.';

  @override
  String get onnxDepSourceSaved => 'Download source updated';

  @override
  String onnxDepInstalled(String size) {
    return 'Installed · $size';
  }

  @override
  String onnxDepDownloading(String percent) {
    return 'Downloading $percent';
  }

  @override
  String onnxDepUninstallConfirm(String size) {
    return 'This deletes the runtime library and the model ($size). Smart masking stops working until you download them again.';
  }

  @override
  String onnxDepFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get favWidgetPickTitle => 'Choose a folder';

  @override
  String get favWidgetPickHint =>
      'The widget shows the newest saved items from this folder.';

  @override
  String get favWidgetNeedLogin => 'Sign in first to choose a folder.';

  @override
  String favWidgetFolderSwitched(String name) {
    return 'Now showing $name';
  }

  @override
  String get ossSearchHint => 'Search packages';

  @override
  String get ossClearSearch => 'Clear';

  @override
  String get ossDepsSection => 'Third-party dependencies';

  @override
  String get ossLoading => 'Collecting license information…';

  @override
  String get ossLoadFailed =>
      'Could not read the license registry. Try again later.';

  @override
  String get ossEmptySearch => 'No matching packages';

  @override
  String get ossRetry => 'Retry';

  @override
  String ossLicensesCount(int count) {
    return '$count licenses';
  }

  @override
  String ossLicenseIndex(int index, int total) {
    return 'License $index of $total';
  }

  @override
  String ossPackagesCount(int total, int licenses) {
    return '$total packages · $licenses license texts';
  }

  @override
  String get userPickerTitle => 'Select users';

  @override
  String get userPickerSearchHint => 'Search my follows';

  @override
  String get userPickerEmpty => 'No users found';

  @override
  String get userPickerLoadFailed => 'Failed to load';

  @override
  String get userPickerDone => 'Done';

  @override
  String get shortsTitle => 'Shorts';

  @override
  String get shortsEmpty => 'Nothing here yet';

  @override
  String get ttsSection => 'AI read-aloud engine';

  @override
  String get ttsModelLabel => 'Qwen3-TTS 1.7B';

  @override
  String get ttsDesc =>
      'Read articles, posts and comments aloud with voice cloning. The model is not bundled with the app and needs a one-time 1.4 GB download.';

  @override
  String get ttsNotInstalled => 'Not downloaded';

  @override
  String get ttsPartial => 'Download is incomplete, resume to finish it';

  @override
  String get ttsSizeCounting => 'Calculating...';

  @override
  String get ttsDownload => 'Download';

  @override
  String get ttsResume => 'Resume';

  @override
  String get ttsUninstall => 'Delete';

  @override
  String get ttsUninstallTitle => 'Delete the read-aloud engine?';

  @override
  String get ttsUninstalled => 'Read-aloud engine deleted';

  @override
  String get ttsInstallDone => 'Download complete. Read-aloud is ready.';

  @override
  String get ttsUnsupported => 'Read-aloud is not supported on this platform';

  @override
  String get ttsSourceTitle => 'Download source';

  @override
  String get ttsSourceDesc =>
      'Switch to a mirror if HuggingFace is unreachable, or enter a custom address';

  @override
  String get ttsSourceSaved => 'Download source updated';

  @override
  String get ttsMirrorOfficial => 'HuggingFace official';

  @override
  String get ttsMirrorChina => 'hf-mirror (recommended in China)';

  @override
  String get ttsMirrorCustom => 'Custom address';

  @override
  String get ttsEngineIdle => 'Not loaded, loads on first read-aloud';

  @override
  String get ttsEngineLoading => 'Loading the read-aloud engine...';

  @override
  String get ttsEngineReady => 'Engine ready';

  @override
  String get ttsEngineUnload => 'Release engine';

  @override
  String get ttsEngineUnloaded =>
      'Engine released, it reloads on the next read-aloud';

  @override
  String get ttsBackendTitle => 'Inference backend';

  @override
  String get ttsBackendAuto => 'Auto';

  @override
  String get ttsBackendNpu => 'NPU';

  @override
  String get ttsBackendGpu => 'GPU';

  @override
  String get ttsBackendCpu => 'CPU';

  @override
  String get ttsBackendAutoDesc =>
      'Prefer NPU on Qualcomm, fall back automatically';

  @override
  String get ttsBackendNpuDesc => 'Qualcomm Snapdragon NPU (Hexagon)';

  @override
  String get ttsBackendGpuDesc => 'Vulkan / Metal acceleration';

  @override
  String get ttsBackendCpuDesc => 'CPU only, best compatibility';

  @override
  String get ttsBackendNpuRuntimeMissing =>
      'This build does not bundle an NPU runtime yet; it runs on CPU for now';

  @override
  String get ttsBackendNpuHardwareUnsupported =>
      'NPU is only supported on Qualcomm Snapdragon; this device will fall back to CPU';

  @override
  String ttsEngineReadyOn(String name) {
    return 'Engine ready · $name';
  }

  @override
  String get ttsNeedInstall =>
      'Download the read-aloud engine first: Settings, then Storage.';

  @override
  String get ttsRuntimePending =>
      'Model is ready, the inference runtime is not wired up yet';

  @override
  String get ttsVoTitle => 'Voice (cloning)';

  @override
  String get ttsVoDesc =>
      'Pick 3 to 15 seconds of clear speech and read-aloud will use that voice';

  @override
  String get ttsVoEmpty => 'Not set, using the default voice';

  @override
  String get ttsVoPick => 'Pick audio';

  @override
  String get ttsVoAdded => 'Voice added';

  @override
  String get ttsVoDeleteTitle => 'Delete this voice?';

  @override
  String get ttsVoDeleted => 'Voice deleted';

  @override
  String get ttsVoDefault => 'Default voice';

  @override
  String get ttsVoUse => 'Use';

  @override
  String get ttsPickAudioTitle => 'Pick a voice sample';

  @override
  String get ttsVoUnsupportedFile => 'Please pick an audio file';

  @override
  String ttsInstalled(String size) {
    return 'Downloaded · $size';
  }

  @override
  String ttsDownloading(String percent) {
    return 'Downloading $percent';
  }

  @override
  String ttsDownloadingFile(String percent, String name) {
    return 'Downloading $percent · $name';
  }

  @override
  String ttsUninstallConfirm(String size) {
    return 'This deletes the model files ($size). Read-aloud stops working until you download them again.';
  }

  @override
  String ttsFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String ttsVoPickFailed(String error) {
    return 'Could not read the audio: $error';
  }

  @override
  String ttsVoDeleteConfirm(String name) {
    return 'This deletes the voice: $name.';
  }

  @override
  String ttsVoCount(String count) {
    return '$count voices saved';
  }

  @override
  String get ttsReadAloud => 'Read aloud';

  @override
  String get ttsReadAloudStop => 'Stop';

  @override
  String get ttsSynthesizing => 'Synthesizing speech...';

  @override
  String ttsSpeakFailed(String error) {
    return 'Read-aloud failed: $error';
  }

  @override
  String ttsTruncatedHint(String count) {
    return 'Long article: reading the first $count characters only';
  }

  @override
  String get playerOnlyPlayAudio => 'Listen only';

  @override
  String get playerOnlyPlayAudioDesc =>
      'Play sound only and hide the picture. Progress and speed are unaffected.';

  @override
  String videoBgmUsedCount(String count) {
    return 'Used by $count videos';
  }

  @override
  String get comic => 'Comics';

  @override
  String get memberShop => 'Member Shop';

  @override
  String get audioZone => 'Audio Zone';

  @override
  String get opusTab => 'Opus';

  @override
  String get matchInfo => 'Match';

  @override
  String get watchLive => 'Watch Live';

  @override
  String get interestStation => 'Interest Zone';

  @override
  String get noteManage => 'Notes';

  @override
  String get noteUnpublished => 'Unpublished';

  @override
  String get notePublished => 'Published';

  @override
  String get deleteSelected => 'Delete Selected';

  @override
  String get confirmDeleteNote => 'Delete the selected notes?';

  @override
  String get favTopic => 'My Topics';

  @override
  String get cancelFavTopic => 'Cancel following this topic?';

  @override
  String get inputIdTitle => 'Enter ID';

  @override
  String get inputIdHint => 'Enter the match or tribe ID';

  @override
  String get noContent => 'No content';

  @override
  String get bubbleAll => 'All';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleted => 'Deleted';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get confirm => 'Confirm';

  @override
  String get selectAll => 'Select All';

  @override
  String get loadFailed => 'Failed to load';

  @override
  String get videoMorePanelTitle => 'More';

  @override
  String get memberLiteTitle => 'Uploader';

  @override
  String get memberLiteViewFull => 'Open full profile';

  @override
  String get memberLiteEmpty => 'No videos yet';

  @override
  String get audioPageTitle => 'Listen';

  @override
  String get audioPageSpeed => 'Speed';

  @override
  String get audioPageRetry => 'Retry';

  @override
  String get playerListenPage => 'Listen to audio';

  @override
  String get playerOnlyPlayAudioInline => 'Audio only (stay here)';

  @override
  String memberLiteVideoCount(String count) {
    return '$count videos';
  }

  @override
  String get memberLiteGoSpace => 'Go to space';

  @override
  String get commentSortLatestDesc => 'Newest comments';

  @override
  String get commentSortHottestDesc => 'Top comments';

  @override
  String get commentSortLatestShort => 'Newest';

  @override
  String get commentSortHottestShort => 'Top';

  @override
  String get memberLiteOrderPubdate => 'Latest';

  @override
  String get memberLiteOrderClick => 'Most played';

  @override
  String get videoMenuWatchLater => 'Watch later';

  @override
  String get videoMenuReload => 'Reload';

  @override
  String get playerMenuStats => 'Playback info';

  @override
  String get playerMenuScreenshot => 'Screenshot';

  @override
  String get playerMenuAudioNorm => 'Volume normalization';

  @override
  String get playerMenuAudioDevice => 'Audio output device';

  @override
  String get playerMenuSource => 'Switch CDN';

  @override
  String get playerMenuEndBehavior => 'Play order';

  @override
  String get screenshotCopy => 'Copy to clipboard';

  @override
  String get screenshotCopied => 'Copied to clipboard';

  @override
  String get screenshotCopyUnsupported =>
      'Copying images to the clipboard is not supported on this platform';

  @override
  String get commonCopy => 'Copy';

  @override
  String get subtitleDownloadAll => 'Download all subtitles';

  @override
  String get subtitleDownloadPickDir => 'Choose where to save subtitles';

  @override
  String get subtitleDownloadNone => 'No subtitles available for this video';

  @override
  String get subtitleDownloadAllFailed => 'Subtitle download failed';

  @override
  String subtitleDownloadDone(String count, String dir) {
    return 'Saved $count subtitle files to $dir';
  }

  @override
  String get prefPerfSection => 'Performance';

  @override
  String get prefEfficiencyMode => 'Efficiency mode';

  @override
  String get prefEfficiencyModeSub =>
      'Schedule this app at the low power tier (EcoQoS). Saves battery when idling in the background, foreground feels slightly slower.';

  @override
  String get prefEfficiencyModeUnsupported =>
      'Efficiency mode is not supported on this system';

  @override
  String get prefEfficiencyModeReading => 'Reading…';

  @override
  String get prefEfficiencyModeActive =>
      'Active · scheduled at the low power tier';

  @override
  String get prefEfficiencyModeInactive => 'Not active';

  @override
  String prefEfficiencyModeFailed(String detail) {
    return 'Efficiency mode did not take effect ($detail)';
  }

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String get sleepTimerCustom => 'Custom…';

  @override
  String get sleepTimerStopAfterCurrent => 'Pause after this episode';

  @override
  String get sleepTimerStopAfterCurrentShort => 'after this episode';

  @override
  String get sleepTimerCancel => 'Cancel sleep timer';

  @override
  String get sleepTimerArmedToast => 'Sleep timer started';

  @override
  String get sleepTimerCancelledToast => 'Sleep timer cancelled';

  @override
  String get sleepTimerStopAfterCurrentArmedToast =>
      'Playback will pause after this episode';

  @override
  String get sleepTimerCustomDialogTitle => 'Custom sleep timer';

  @override
  String get sleepTimerCustomHint => 'Minutes';

  @override
  String get sleepTimerCustomUnit => 'min';

  @override
  String get sleepTimerInvalidNumber => 'Enter a valid number of minutes';

  @override
  String get settingsSleepTimerExitApp => 'Quit app when timer ends';

  @override
  String get settingsSleepTimerExitAppDesc =>
      'Pause playback when the timer fires, then quit NaviFlash (desktop only)';

  @override
  String sleepTimerMinutes(int min) {
    return '$min min';
  }

  @override
  String get playlistReversePlay => 'Reverse play';

  @override
  String get playlistReversePlayOn => 'Reverse play on';

  @override
  String get playlistReversePlayOff => 'Reverse play off';

  @override
  String get msgSettingsNotifSection => 'Notifications';

  @override
  String get msgSettingsReplyNotify => 'Reply notifications';

  @override
  String get msgSettingsReplyNotifyDesc =>
      '(Who can trigger reply notifications)';

  @override
  String get msgSettingsAtNotify => 'Mention notifications';

  @override
  String get msgSettingsAtNotifyDesc => '(Who can trigger @-notifications)';

  @override
  String get msgSettingsLikeNotify => 'Like notifications';

  @override
  String get msgSettingsLikeNotifyDesc =>
      '(Who can trigger like notifications)';

  @override
  String get msgSettingsNotifyEveryone => 'Everyone';

  @override
  String get msgSettingsNotifyFollowing => 'People I follow';

  @override
  String get msgSettingsNotifyNone => 'Do not notify';

  @override
  String get msgSettingsReceiveSection => 'Message receiving';

  @override
  String get msgSettingsReceiveUnfollow => 'DMs from non-followed users';

  @override
  String get msgSettingsReceiveUnfollowDesc =>
      '(If turned off, you will no longer receive DMs from non-followed users; notification messages are unaffected)';

  @override
  String get msgSettingsUnfollowFold => 'Fold DMs from non-followed users';

  @override
  String get msgSettingsUnfollowFoldDesc =>
      '(DMs from non-followed users will be folded)';

  @override
  String get msgSettingsGroupReceive => 'Receive fan-club messages';

  @override
  String get msgSettingsGroupFold => 'Fold fan-club messages';

  @override
  String get msgSettingsSmartIntercept => 'Smart DM filtering';

  @override
  String get msgSettingsSmartInterceptDesc =>
      '(When on, only DMs / comments / danmaku from specified users reach you for 7 days, and @-notifications are stopped)';

  @override
  String get msgSettingsAntiHarassmentSection => 'Anti-harassment';

  @override
  String get msgSettingsAntiHarassment => 'Anti-harassment settings';

  @override
  String get msgSettingsScopeSelect => 'Who can send you DMs';

  @override
  String msgSettingsValidUntil(String time) {
    return '(Valid until $time)';
  }

  @override
  String get prefEfficiencyModeAutoDesc =>
      'Normal performance in the foreground; enters efficiency mode after 3 minutes in the background and restores instantly on return. Skipped while playing.';
}
