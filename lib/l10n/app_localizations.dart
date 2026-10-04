import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

                                                                             
                                               
   
                                                                             
                                                                           
                                         
   
           
                                         
   
                       
                                                                      
                                                          
                                
      
       
   
                          
   
                                                                         
             
   
           
                 
                                     
                            
                    
                                                                   
   
                            
       
   
                       
   
                                                                         
                                                                             
                                                                            
         
   
                                                                           
                                                                             
                            
   
                                                                             
                                                                
   
                                                                         
                                                                          
                                                                             
                                                                                    
             
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

                                                                                
                
     
                                                                                   
                                                                                  
                                              
     
                                                                    
                                                                             
                                            
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

                                                                
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'US'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'HK'),
    Locale('zh', 'TW'),
  ];

                                             
     
                                           
                          
  String metroDate(int month, int day);

                                               
     
                                           
               
  String get metroSunday;

                                               
     
                                           
               
  String get metroMonday;

                                                
     
                                           
               
  String get metroTuesday;

                                                  
     
                                           
               
  String get metroWednesday;

                                                 
     
                                           
               
  String get metroThursday;

                                               
     
                                           
               
  String get metroFriday;

                                                 
     
                                           
               
  String get metroSaturday;

                                              
     
                                           
              
  String get metroLogin;

                                                
     
                                           
              
  String get metroWelcome;

                                                     
     
                                           
                   
  String get imageViewerNoFile;

                                                       
     
                                           
                    
  String get syncPassphraseEmpty;

                                                      
     
                                           
                                        
  String get imageBytesRequired;

                                                        
     
                                           
                   
  String get webdavConnectSuccess;

                                                     
     
                                           
                 
  String get webdavConfigSaved;

                                                        
     
                                           
                             
  String get webdavConfigureFirst;

                                                             
     
                                           
                          
  String get webdavSelectContactsFirst;

                                                 
     
                                           
                          
  String get webdavNoFiles;

                                                       
     
                                           
                
  String get webdavConfirmBackup;

                                                       
     
                                           
                                                                                  
  String webdavBackupConfirm(int contacts, int files, String path);

                                                     
     
                                           
                
  String get webdavStartBackup;

                                                        
     
                                           
                
  String get webdavBackingUpTitle;

                                                         
     
                                           
                
  String get webdavBackupDoneTitle;

                                                    
     
                                           
                          
  String webdavTotalFiles(int count);

                                                      
     
                                           
                      
  String webdavSuccessCount(int count);

                                                   
     
                                           
                      
  String webdavFailCount(int count);

                                                    
     
                                           
                             
  String webdavMoreErrors(int count);

                                                   
     
                                           
              
  String get webdavBackupFab;

                                                  
     
                                           
                  
  String get webdavShowInfo;

                                                  
     
                                           
                  
  String get webdavHideInfo;

                                                    
     
                                           
                     
  String get webdavScanToFill;

                                                    
     
                                           
                     
  String get webdavScanFilled;

                                                      
     
                                           
                 
  String get webdavServerConfig;

                                                        
     
                                           
                 
  String get webdavServerUrlLabel;

                                                       
     
                                           
               
  String get webdavUsernameLabel;

                                                       
     
                                           
              
  String get webdavPasswordLabel;

                                                         
     
                                           
                  
  String get webdavRemotePathLabel;

                                                 
     
                                           
                  
  String get webdavTesting;

                                                     
     
                                           
                   
  String get webdavSaveAndTest;

                                                  
     
                                           
               
  String get webdavSaveOnly;

                                                         
     
                                           
                  
  String get webdavConnectVerified;

                                                    
     
                                           
                
  String get webdavAutoBackup;

                                                             
     
                                           
                     
  String get webdavAutoBackupOnReceive;

                                                            
     
                                           
                        
  String get webdavAutoBackupSubtitle;

                                                   
     
                                           
                
  String get webdavMediaSync;

                                                       
     
                                           
                  
  String get webdavSyncPlaylists;

                                                     
     
                                           
                
  String get webdavSyncDanmaku;

                                                             
     
                                           
                            
  String get webdavPassphraseEncrypted;

                                                         
     
                                           
                           
  String get webdavPassphrasePlain;

                                                        
     
                                           
                          
  String get webdavPassphraseHint;

                                                            
     
                                           
                  
  String get webdavGeneratePassphrase;

                                                       
     
                                           
                                                                                                              
  String get webdavMediaSyncHint;

                                                      
     
                                           
                                                                                       
  String get webdavEncryptionOn;

                                                       
     
                                           
                                                                 
  String get webdavEncryptionOff;

                                                        
     
                                           
                 
  String get webdavBackupContacts;

                                                          
     
                                           
                                        
  String webdavSelectedContacts(int selected, int total);

                                                        
     
                                           
                        
  String get webdavSearchContacts;

                                                     
     
                                           
                
  String get webdavDeselectAll;

                                                   
     
                                           
                       
  String webdavFileCount(int count);

                                                    
     
                                           
                 
  String get webdavNoContacts;

                                                 
     
                                           
                 
  String get webdavNoMatch;

                                                         
     
                                           
                                
  String webdavContactSubtitle(String ip, int count);

                                                
     
                                           
              
  String get webdavManage;

                                                  
     
                                           
                
  String get webdavLastSync;

                                                   
     
                                           
                
  String get webdavLastError;

                                                     
     
                                           
                        
  String get webdavClearConfig;

                                                             
     
                                           
                        
  String get webdavClearConfigSubtitle;

                                                   
     
                                           
              
  String get webdavUserLabel;

                                                      
     
                                           
                     
  String webdavStatusActive(String name);

                                                          
     
                                           
                     
  String webdavStatusConfigured(String name);

                                                             
     
                                           
               
  String get webdavStatusNotConfigured;

                                                   
     
                                           
                
  String get webdavNotSynced;

                                                 
     
                                           
                   
  String get webdavJustNow;

                                                    
     
                                           
                              
  String webdavMinutesAgo(int minutes);

                                                  
     
                                           
                            
  String webdavHoursAgo(int hours);

                                                    
     
                                           
                                      
  String webdavSyncedDate(int month, int day, String time);

                                                             
     
                                           
                                        
  String get webdavPassphraseGenerated;

                                                      
     
                                           
                
  String get webdavConfirmClear;

                                                          
     
                                           
                                                       
  String get webdavClearConfirmText;

                                                      
     
                                           
                
  String get profileEditProfile;

                                                         
     
                                           
                
  String get profileAccountSection;

                                                       
     
                                           
                     
  String get profileWebdavBackup;

                                                         
     
                                           
                          
  String profileWebdavLoggedIn(String username);

                                                      
     
                                           
               
  String get profileNotLoggedIn;

                                                        
     
                                           
              
  String get profileAvatarSection;

                                                       
     
                                           
                
  String get profileChangeAvatar;

                                                       
     
                                           
                
  String get profileRemoveAvatar;

                                                          
     
                                           
                   
  String get profilePickFromGallery;

                                                               
     
                                           
                  
  String get profileRestoreDefaultAvatar;

                                                        
     
                                           
                
  String get profileSetBackground;

                                                     
     
                                           
                       
  String get profileBgSubtitle;

                                                         
     
                                           
                
  String get profileRestoreDefault;

                                                           
     
                                           
                           
  String get profileBgRemoveSubtitle;

                                                      
     
                                           
                
  String get profileInfoSection;

                                                        
     
                                           
              
  String get profileNicknameLabel;

                                                 
     
                                           
               
  String get profileNotSet;

                                                  
     
                                           
                  
  String get profileBgTitle;

                                                        
     
                                           
                   
  String get profileAvatarUpdated;

                                                       
     
                                           
                             
  String profileAvatarFailed(String error);

                                                              
     
                                           
                               
  String get profileRemoveAvatarConfirm;

                                                        
     
                                           
                 
  String get profileAvatarRemoved;

                                                      
     
                                           
                
  String get profileSetNickname;

                                                       
     
                                           
                
  String get profileNicknameHint;

                                                        
     
                                           
                  
  String get profileNicknameEmpty;

                                                          
     
                                           
                   
  String get profileNicknameUpdated;

                                                     
     
                                           
               
  String get colorDefaultGreen;

                                             
     
                                           
               
  String get colorPink;

                                            
     
                                           
              
  String get colorRed;

                                               
     
                                           
              
  String get colorOrange;

                                              
     
                                           
               
  String get colorAmber;

                                               
     
                                           
              
  String get colorYellow;

                                             
     
                                           
               
  String get colorLime;

                                                   
     
                                           
               
  String get colorLightGreen;

                                              
     
                                           
              
  String get colorGreen;

                                             
     
                                           
              
  String get colorCyan;

                                             
     
                                           
               
  String get colorTeal;

                                                  
     
                                           
               
  String get colorLightBlue;

                                             
     
                                           
              
  String get colorBlue;

                                               
     
                                           
               
  String get colorIndigo;

                                               
     
                                           
              
  String get colorPurple;

                                                   
     
                                           
               
  String get colorDeepPurple;

                                                 
     
                                           
               
  String get colorBlueGrey;

                                              
     
                                           
              
  String get colorBrown;

                                             
     
                                           
              
  String get colorGrey;

                                                       
     
                                           
                     
  String get themeColorExtracted;

                                                    
     
                                           
                         
  String themeColorFailed(String error);

                                                  
     
                                           
                   
  String get themeImageOnly;

                                              
     
                                           
              
  String get themeTitle;

                                                    
     
                                           
                        
  String themeColorCopied(String hex);

                                                   
     
                                           
              
  String get themeAppearance;

                                                      
     
                                           
                     
  String get themeDarkBlackened;

                                            
     
                                           
               
  String get themeOff;

                                                
     
                                           
               
  String get themeEnabled;

                                                      
     
                                           
              
  String get themeColorsSection;

                                                     
     
                                           
                 
  String get themePaletteStyle;

                                                     
     
                                           
                  
  String get themeFollowSystem;

                                                  
     
                                           
                
  String get themePickColor;

                                                 
     
                                           
                       
  String get themeDropHint;

                                                 
     
                                           
                
  String get themeNewTheme;

                                                 
     
                                           
                          
  String themeSwitched(String name);

                                                    
     
                                           
                
  String get themeDeleteTitle;

                                                      
     
                                           
                                    
  String themeDeleteConfirm(String name);

                                                
     
                                           
                          
  String themeDeleted(String name);

                                                    
     
                                           
                   
  String get themeCreateTitle;

                                                  
     
                                           
                
  String get themeNameLabel;

                                                 
     
                                           
                 
  String get themeNameHint;

                                                 
     
                                           
                    
  String get themeHexLabel;

                                                
     
                                           
                                
  String get themeHexHint;

                                                
     
                                           
                                
  String themeCreated(String name);

                                                  
     
                                           
                
  String get themeCopyColor;

                                                      
     
                                           
                 
  String get themePickFromImage;

                                              
     
                                           
                
  String get searchBack;

                                              
     
                                           
                  
  String get searchHint;

                                                
     
                                           
                      
  String get searchPrompt;

                                                  
     
                                           
                                  
  String get searchExamples;

                                                   
     
                                           
                             
  String searchNoResults(String query);

                                                   
     
                                           
                
  String get searchThemeMode;

                                                   
     
                                           
                  
  String get searchPureBlack;

                                                    
     
                                           
                
  String get searchThemeColor;

                                                    
     
                                           
                
  String get searchFontWeight;

                                                      
     
                                           
                
  String get searchDisplayScale;

                                                     
     
                                           
                        
  String get searchDisplayMode;

                                                   
     
                                           
               
  String get searchStatusBar;

                                                         
     
                                           
                   
  String get searchKeepWindowRatio;

                                                        
     
                                           
                 
  String get searchLongPressSpeed;

                                                    
     
                                           
                
  String get searchScreenshot;

                                                           
     
                                           
                   
  String get searchScreenshotDanmaku;

                                                      
     
                                           
                
  String get searchPlayProgress;

                                               
     
                                           
                
  String get searchHwdec;

                                                   
     
                                           
                
  String get searchVideoSync;

                                                            
     
                                           
                    
  String get searchImmersiveLongPress;

                                                
     
                                           
                     
  String get searchMpvLog;

                                                     
     
                                           
                    
  String get searchMpvLogLevel;

                                                     
     
                                           
                
  String get searchNetworkMode;

                                                      
     
                                           
                   
  String get searchInsecureCert;

                                                  
     
                                           
                   
  String get searchChatIpv6;

                                                          
     
                                           
                 
  String get searchConnectivityTest;

                                                       
     
                                           
                   
  String get searchHostOverrides;

                                                  
     
                                           
                  
  String get searchDohQuery;

                                                 
     
                                           
                       
  String get searchReferer;

                                                   
     
                                           
                          
  String get searchUserAgent;

                                                        
     
                                           
                
  String get searchSystemSettings;

                                                      
     
                                           
                
  String get searchUserSettings;

                                                      
     
                                           
                    
  String get settingsDisplaySub;

                                                  
     
                                           
              
  String get settingsSystem;

                                                     
     
                                           
                    
  String get settingsSystemSub;

                                                   
     
                                           
              
  String get settingsStorage;

                                                      
     
                                           
                     
  String get settingsStorageSub;

                                                   
     
                                           
              
  String get settingsNetwork;

                                                      
     
                                           
                       
  String get settingsNetworkSub;

                                                    
     
                                           
              
  String get settingsLanguage;

                                                       
     
                                           
                             
  String get settingsLanguageSub;

                                                     
     
                                           
                
  String get ttsDownloadCancel;

                                                        
     
                                           
                       
  String get ttsDownloadDoneTitle;

                                                       
     
                                           
                                                
  String get ttsDownloadDoneBody;

                                                     
     
                                           
                 
  String get ttsNoInstallTitle;

                                                       
     
                                           
                            
  String get ttsNoInstallHeading;

                                                        
     
                                           
                 
  String get ttsNoInstallDownload;

                                                           
     
                                           
                               
  String get ttsNoInstallDownloadSub;

                                                     
     
                                           
               
  String get ttsNoInstallLater;

                                                        
     
                                           
                 
  String get ttsNoInstallLaterSub;

                                                       
     
                                           
                      
  String get ttsInstallPageTitle;

                                                        
     
                                           
                 
  String get ugcFilterWindowTitle;

                                                         
     
                                           
                 
  String get ugcFilterResultPrefix;

                                                               
     
                                           
                 
  String get ugcFilterDeleteMatchesPlain;

                                                  
     
                                           
                
  String get ugcFilterTitle;

                                                          
     
                                           
                     
  String get ugcFilterSectionScopes;

                                                           
     
                                           
                
  String get ugcFilterScopeRecommend;

                                                              
     
                                           
                      
  String get ugcFilterScopeRecommendSub;

                                                      
     
                                           
                
  String get ugcFilterScopeZone;

                                                         
     
                                           
                                   
  String get ugcFilterScopeZoneSub;

                                                       
     
                                           
              
  String get ugcFilterScopeReply;

                                                          
     
                                           
                      
  String get ugcFilterScopeReplySub;

                                                     
     
                                           
              
  String get ugcFilterScopeDyn;

                                                        
     
                                           
                      
  String get ugcFilterScopeDynSub;

                                                  
     
                                           
                              
  String get ugcFilterEmpty;

                                                    
     
                                           
                  
  String get ugcFilterAddHint;

                                                
     
                                           
              
  String get ugcFilterAdd;

                                                 
     
                                           
                 
  String get ugcFilterEdit;

                                                   
     
                                           
              
  String get ugcFilterDelete;

                                                  
     
                                           
                
  String get ugcFilterClear;

                                                
     
                                           
                  
  String get ugcFilterDup;

                                                    
     
                                           
                     
  String get ugcFilterInvalid;

                                                    
     
                                           
               
  String get ugcFilterDeleted;

                                                    
     
                                           
               
  String get ugcFilterCleared;

                                                     
     
                                           
                 
  String get ugcFilterNoResult;

                                                     
     
                                           
              
  String get ugcFilterMenuMore;

                                                          
     
                                           
                  
  String get ugcFilterMenuClipboard;

                                                     
     
                                           
                 
  String get ugcFilterMenuFile;

                                                       
     
                                           
              
  String get ugcFilterMenuExport;

                                                       
     
                                           
                      
  String get ugcFilterMenuWebdav;

                                                        
     
                                           
                    
  String get ugcFilterImportEmpty;

                                                        
     
                                           
                     
  String get ugcFilterExportEmpty;

                                                        
     
                                           
                
  String get ugcFilterFindReplace;

                                                 
     
                                           
              
  String get ugcFilterFind;

                                                    
     
                                           
              
  String get ugcFilterReplace;

                                                 
     
                                           
              
  String get ugcFilterPrev;

                                                 
     
                                           
              
  String get ugcFilterNext;

                                                       
     
                                           
              
  String get ugcFilterReplaceOne;

                                                       
     
                                           
              
  String get ugcFilterReplaceAll;

                                                    
     
                                           
                
  String get ugcFilterHistory;

                                                         
     
                                           
                  
  String get ugcFilterClearHistory;

                                                          
     
                                           
                 
  String get ugcFilterCaseSensitive;

                                                      
     
                                           
                         
  String get ugcFilterWholeWord;

                                                  
     
                                           
                 
  String get ugcFilterRegex;

                                                
     
                                           
                                                                                                       
  String get ugcFilterTip;

                                                       
     
                                           
                     
  String ugcFilterRulesCount(int count);

                                                  
     
                                           
                         
  String ugcFilterAdded(int count);

                                                        
     
                                           
                        
  String ugcFilterResultCount(int count);

                                                     
     
                                           
                         
  String ugcFilterReplaced(int count);

                                                           
     
                                           
                          
  String ugcFilterDeletedMatches(int count);

                                                     
     
                                           
                                       
  String ugcFilterImported(int added, int skipped);

                                                         
     
                                           
                        
  String ugcFilterImportFailed(String error);

                                                         
     
                                           
                        
  String ugcFilterExportFailed(String error);

                                                     
     
                                           
                              
  String ugcFilterWebdavOk(String name);

                                                       
     
                                           
                        
  String ugcFilterWebdavFail(String error);

                                                   
     
                                           
                  
  String get prefLinkSection;

                                                     
     
                                           
                 
  String get settingsRecommend;

                                                        
     
                                           
                        
  String get settingsRecommendSub;

                                                     
     
                                           
               
  String get rcmdSectionSource;

                                                    
     
                                           
                        
  String get rcmdUseAppSource;

                                                       
     
                                           
                                      
  String get rcmdUseAppSourceSub;

                                                       
     
                                           
                 
  String get rcmdSectionBehavior;

                                                    
     
                                           
                    
  String get rcmdKeepLastData;

                                                       
     
                                           
                       
  String get rcmdKeepLastDataSub;

                                                        
     
                                           
                      
  String get rcmdSavedPositionTip;

                                                           
     
                                           
                               
  String get rcmdSavedPositionTipSub;

                                                            
     
                                           
                  
  String get rcmdSavedPositionTipText;

                                                     
     
                                           
               
  String get rcmdSectionFilter;

                                                
     
                                           
               
  String get rcmdNoFilter;

                                                    
     
                                           
               
  String get rcmdMinLikeRatio;

                                                       
     
                                           
                        
  String get rcmdMinLikeRatioSub;

                                                   
     
                                           
                
  String get rcmdMinDuration;

                                                      
     
                                           
                       
  String get rcmdMinDurationSub;

                                               
     
                                           
               
  String get rcmdMinPlay;

                                                  
     
                                           
                        
  String get rcmdMinPlaySub;

                                               
     
                                           
                   
  String get rcmdBanWord;

                                                  
     
                                           
                            
  String get rcmdBanWordSub;

                                                   
     
                                           
               
  String get rcmdBanWordHint;

                                               
     
                                           
                   
  String get rcmdBanZone;

                                                  
     
                                           
                                   
  String get rcmdBanZoneSub;

                                                   
     
                                           
               
  String get rcmdBanZoneHint;

                                                      
     
                                           
                         
  String get rcmdExemptFollowed;

                                                         
     
                                           
                              
  String get rcmdExemptFollowedSub;

                                                     
     
                                           
                          
  String get rcmdFilterRelated;

                                                        
     
                                           
                            
  String get rcmdFilterRelatedSub;

                                                  
     
                                           
                                              
  String get rcmdFilterHint;

                                                   
     
                                           
                         
  String get rcmdFilterSaved;

                                                          
     
                                           
                    
  String get prefOpenSupportedLinks;

                                                             
     
                                           
                                                          
  String get prefOpenSupportedLinksSub;

                                                           
     
                                           
                                       
  String get linkSettingsUnavailable;

                                                  
     
                                           
                
  String get appLangSection;

                                                       
     
                                           
                
  String get appLangFollowSystem;

                                                   
     
                                           
                  
  String get biliLangSection;

                                                 
     
                                           
                 
  String get biliAiSection;

                                                         
     
                                           
                    
  String get biliAiTranslateEnable;

                                                         
     
                                           
                                   
  String get biliAiTranslateOnDesc;

                                                          
     
                                           
                        
  String get biliAiTranslateOffDesc;

                                            
     
                                           
                
  String get langZhCn;

                                            
     
                                           
                    
  String get langZhHk;

                                            
     
                                           
                    
  String get langZhTw;

                                            
     
                                           
                       
  String get langEnUs;

                                            
     
                                           
               
  String get langJaJp;

                                            
     
                                           
               
  String get langKoKr;

                                                  
     
                                           
               
  String get settingsPlayer;

                                                     
     
                                           
                     
  String get settingsPlayerSub;

                                                          
     
                                           
                      
  String get settingsStartScreenSub;

                                                
     
                                           
              
  String get settingsLogs;

                                                   
     
                                           
                       
  String get settingsLogsSub;

                                                    
     
                                           
              
  String get settingsAccounts;

                                                       
     
                                           
                      
  String get settingsAccountsSub;

                                                
     
                                           
              
  String get settingsUser;

                                                   
     
                                           
                    
  String get settingsUserSub;

                                                    
     
                                           
                  
  String get settingsAboutSub;

                                                    
     
                                           
                
  String get settingsLicenses;

                                                       
     
                                           
                      
  String get settingsLicensesSub;

                                                  
     
                                           
                
  String get settingsSearch;

                                               
     
                                           
                 
  String get openSidebar;

                                                                
     
                                           
                                
  String get settingsPlaceholderEasterEgg;

                                                     
     
                                           
                     
  String storageClearTitle(String label);

                                                       
     
                                           
                                         
  String storageClearConfirm(String label);

                                                
     
                                           
              
  String get storageClear;

                                                  
     
                                           
                      
  String storageCleared(String label);

                                                 
     
                                           
              
  String get refreshAction;

                                                       
     
                                           
              
  String get storageCacheSection;

                 
     
                                           
                
  String get storageUsageBreakdown;

                       
     
                                           
               
  String get storageUsageTotal;

            
     
                                           
                     
  String get storageUsageEmpty;

                                   
     
                                           
                
  String get storageDataCache;

                               
     
                                           
                 
  String get storageAiDeps;

                                                     
     
                                           
                
  String get storageImageCache;

                                                   
     
                                           
                 
  String get storageCounting;

                                                    
     
                                           
                                
  String storageFileCount(int count, String size);

                                                       
     
                                           
                
  String get storageDanmakuCache;

                                                     
     
                                           
                                
  String storageVideoCount(int count, String size);

                          
     
                                           
                        
  String get settingsAutoOfflineCache;

                   
     
                                           
                                                                           
  String get settingsAutoOfflineCacheHint;

                    
     
                                           
                  
  String get storageVideoCache;

                  
     
                                           
                                                   
  String get storageVideoCacheDesc;

                                                      
     
                                           
                  
  String get storageMemoryCache;

                                                          
     
                                           
                               
  String get storageMemoryCacheDesc;

                                                   
     
                                           
                 
  String get storageClearing;

                                                   
     
                                           
                    
  String get storageClearAll;

                                                    
     
                                           
                                                                   
  String get storageCacheHint;

                                                        
     
                                           
                  
  String get storageClearAllTitle;

                                                          
     
                                           
                                               
  String get storageClearAllConfirm;

                                                     
     
                                           
                   
  String get storageAllCleared;

                                                          
     
                                           
                
  String get storageLocationSection;

                                                            
     
                                           
                  
  String get storageLocationAutoCache;

                                                                
     
                                           
                                         
  String get storageLocationAutoCacheDesc;

                                                        
     
                                           
                  
  String get storageLocationVideo;

                                                            
     
                                           
                           
  String get storageLocationVideoDesc;

                                                         
     
                                           
                   
  String get storageLocationModels;

                                                             
     
                                           
                           
  String get storageLocationModelsDesc;

                                                          
     
                                           
                  
  String get storageLocationDefault;

                                                              
     
                                           
                      
  String get storageLocationUnsupported;

                                                         
     
                                           
              
  String get storageLocationChoose;

                                                       
     
                                           
                
  String get storageLocationPick;

                                                            
     
                                           
                  
  String get storageLocationNewFolder;

                                                             
     
                                           
                 
  String get storageLocationFolderName;

                                                               
     
                                           
                        
  String get storageLocationCreateFailed;

                                                        
     
                                           
                
  String get storageLocationReset;

                                                            
     
                                           
                   
  String get storageLocationResetDone;

                                                          
     
                                           
                     
  String storageLocationCurrent(String path);

                                                          
     
                                           
                       
  String storageLocationSetDone(String path);

                                                       
     
                                           
                     
  String storageLocationFree(String size);

                                                              
     
                                           
                          
  String get storageLocationNotWritable;

                                                              
     
                                           
                                                                       
  String get storageLocationAndroidHint;

                                                          
     
                                           
                                     
  String get storageLocationKeepOld;

                                                        
     
                                           
                     
  String get ttsLiveDownloadTitle;

                                              
     
                                           
              
  String get settingsAi;

                                                 
     
                                           
                               
  String get settingsAiSub;

                                                        
     
                                           
                                               
  String get bottomNavPreviewHint;

                                                      
     
                                           
                 
  String get bottomNavResetDone;

                                                               
     
                                           
                 
  String get verificationPendingRequests;

                                                         
     
                                           
                   
  String get verificationNoPending;

                                                         
     
                                           
                      
  String verificationIpAddress(String ip);

                                                        
     
                                           
                     
  String verificationNickname(String name);

                                                           
     
                                           
                       
  String verificationRequestTime(String time);

                                                             
     
                                           
                        
  String get verificationRejectInvalid;

                                                        
     
                                           
                   
  String get verificationRejected;

                                                      
     
                                           
              
  String get verificationReject;

                                                             
     
                                           
                        
  String get verificationAcceptInvalid;

                                                        
     
                                           
                   
  String get verificationAccepted;

                                                      
     
                                           
              
  String get verificationAccept;

                                                      
     
                                           
                       
  String get startScreenWarning;

                                                    
     
                                           
                
  String get startScreenTitle;

                                                     
     
                                           
                  
  String get startScreenGoBack;

                                                     
     
                                           
                  
  String get enableStartScreen;

                                                             
     
                                           
                                      
  String get startScreenEnableSubtitle;

                                               
     
                                           
                    
  String get enableCharm;

                                                       
     
                                           
                             
  String get charmEnableSubtitle;

                                                     
     
                                           
                      
  String get charmGestureTitle;

                                                        
     
                                           
                                    
  String get charmGestureSubtitle;

                                                 
     
                                           
                
  String get externalVideo;

                                                    
     
                                           
                  
  String get audioChannelName;

                                                         
     
                                           
                   
  String get foregroundChannelName;

                                                         
     
                                           
                       
  String get foregroundChannelDesc;

                                                   
     
                                           
               
  String get foregroundTitle;

                                                  
     
                                           
               
  String get foregroundText;

                                                        
     
                                           
              
  String get drawerBilibiliSearch;

                                                       
     
                                           
              
  String get recommendBottomHome;

                                                       
     
                                           
              
  String get recommendBottomLive;

                                                        
     
                                           
                  
  String get commentImageLoadFail;

                                                      
     
                                           
                
  String get commentDetailTitle;

                                                            
     
                                           
                                        
  String get commentLikeLoginRequired;

                                                   
     
                                           
                        
  String commentLikeFail(String error);

                                                
     
                                           
                  
  String get relatedEmpty;

                                                  
     
                                           
                
  String get biliLoadFailed;

                                            
     
                                           
                    
  String countWan(String count);

                                           
     
                                           
                    
  String countYi(String count);

                                                      
     
                                           
                 
  String get searchNoNewContent;

                                                             
     
                                           
                      
  String get searchNewContentRefreshed;

                                                       
     
                                           
                
  String get biliDialogNeedLogin;

                                                          
     
                                           
                                     
  String get biliDialogInteractDesc;

                                               
     
                                           
               
  String get biliGoLogin;

                                                       
     
                                           
                                            
  String get biliCookieScopeHint;

                                                   
     
                                           
                
  String get videoTabRelated;

                                                    
     
                                           
              
  String get videoTabComments;

                                                         
     
                                           
                      
  String videoTabCommentsCount(int count);

                                                    
     
                                           
                      
  String videoTabEpisodes(int count);

                                                 
     
                                           
              
  String get videoTabIntro;

                                                   
     
                                           
                       
  String danmakuWatching(String count);

                                                    
     
                                           
                         
  String danmakuLoadedBar(String count);

                                                   
     
                                           
                
  String get danmakuToggleOn;

                                                  
     
                                           
                
  String get danmakuDisable;

                                                    
     
                                           
                       
  String get danmakuInputHint;

                                                     
     
                                           
                    
  String get danmakuToastEmpty;

                                                        
     
                                           
                        
  String danmakuToastSendFail(String error);

                                                    
     
                                           
                 
  String get danmakuToastSent;

                                                    
     
                                           
                      
  String get videoLikeTooltip;

                                                      
     
                                           
                
  String get videoUnlikeTooltip;

                                                    
     
                                           
              
  String get videoCoinTooltip;

                                                   
     
                                           
              
  String get videoFavTooltip;

                                                     
     
                                           
                
  String get videoUnfavTooltip;

                                                   
     
                                           
              
  String get videoShareLabel;

                                                   
     
                                           
                      
  String videoStatRating(String count);

                                                      
     
                                           
                     
  String videoStatFollowing(String count);

                                                     
     
                                           
                      
  String videoStatWatching(String count);

                                                    
     
                                           
              
  String get videoFollowLabel;

                                                      
     
                                           
               
  String get videoFollowedLabel;

                                                      
     
                                           
                 
  String get commentDetailEmpty;

                                                       
     
                                           
                                
  String commentDetailNoMore(int count);

                                                         
     
                                           
                  
  String get commentDetailLoadMore;

                                                          
     
                                           
              
  String get commentDetailRootBadge;

                                                        
     
                                           
                   
  String get commentDetailDeleted;

                                                   
     
                                           
                
  String get commentMenuCopy;

                                                         
     
                                           
                
  String get commentMenuSelectText;

                                                      
     
                                           
                
  String get commentDialogTitle;

                                                      
     
                                           
                   
  String get commentDialogEmpty;

                                                        
     
                                           
                    
  String get danmakuInputBvPrompt;

                                                         
     
                                           
                   
  String get danmakuInputCidPrompt;

                                                          
     
                                           
                      
  String get danmakuInputCidNumeric;

                                                        
     
                                           
                                          
  String danmakuInputCacheHit(int count, String oid);

                                                            
     
                                           
                                        
  String danmakuInputFetchSuccess(int count, String oid);

                                                         
     
                                           
                
  String get danmakuInputFetchFail;

                                                     
     
                                           
                       
  String get danmakuInputTitle;

                                                         
     
                                           
               
  String get danmakuInputTypeLabel;

                                                      
     
                                           
                                   
  String get danmakuInputBvHint;

                                                       
     
                                           
                                   
  String get danmakuInputCidHint;

                                                        
     
                                           
                  
  String get danmakuInputFetching;

                                                            
     
                                           
                
  String get danmakuInputFetchDanmaku;

                                                     
     
                                           
                  
  String get danmakuInputEmpty;

                                                       
     
                                           
                             
  String get danmakuCidFetchFail;

                                                 
     
                                           
                               
  String danmakuNoData(String oid);

                                                        
     
                                           
                
  String get danmakuSettingsTitle;

                                                     
     
                                           
               
  String get danmakuDataSource;

                                                         
     
                                           
                
  String get danmakuDisplayControl;

                                                 
     
                                           
                
  String get danmakuEnable;

                                                    
     
                                           
                 
  String get danmakuSmartMask;

                                                        
     
                                           
                          
  String get danmakuSmartMaskDesc;

                                                     
     
                                           
                
  String get danmakuTypeFilter;

                                                     
     
                                           
                
  String get danmakuTypeScroll;

                                                  
     
                                           
                
  String get danmakuTypeTop;

                                                     
     
                                           
                
  String get danmakuTypeBottom;

                                                       
     
                                           
                      
  String get danmakuTypeAdvanced;

                                                           
     
                                           
                         
  String get danmakuAdvancedSubtitle;

                                                     
     
                                           
                
  String get danmakuParameters;

                                                      
     
                                           
                
  String get danmakuScrollSpeed;

                                                  
     
                                           
                
  String get danmakuOpacity;

                                                   
     
                                           
                
  String get danmakuFontSize;

                                                   
     
                                           
                
  String get danmakuMaxLines;

                                                     
     
                                           
                     
  String danmakuLinesCount(int count);

                                                       
     
                                           
                
  String get danmakuQuickActions;

                                                      
     
                                           
                
  String get danmakuResetParams;

                                                       
     
                                           
                
  String get danmakuClearDanmaku;

                                                       
     
                                           
                       
  String get danmakuLoadLocalXml;

                                                      
     
                                           
                            
  String get danmakuFetchOnline;

                                                    
     
                                           
                  
  String get danmakuNotLoaded;

                                                      
     
                                           
                           
  String danmakuLoadedCount(int count);

                                                        
     
                                           
                
  String get danmakuBlockColorful;

                                                      
     
                                           
                 
  String get danmakuCloudFilter;

                                                         
     
                                           
              
  String get danmakuCloudFilterOff;

                                                           
     
                                           
                     
  String danmakuCloudFilterLevel(int level);

                                                     
     
                                           
                  
  String get danmakuFontSizeFS;

                                                  
     
                                           
                     
  String danmakuSeconds(int value);

                                                 
     
                                           
              
  String get danmakuOthers;

                                                      
     
                                           
                
  String get danmakuMassiveMode;

                                                        
     
                                           
                 
  String get danmakuStatic2Scroll;

                                                   
     
                                           
                
  String get danmakuShowArea;

                                                     
     
                                           
                
  String get danmakuFontWeight;

                                                      
     
                                           
                
  String get danmakuStrokeWidth;

                                                         
     
                                           
                  
  String get danmakuScrollDuration;

                                                         
     
                                           
                  
  String get danmakuStaticDuration;

                                                     
     
                                           
                
  String get danmakuLineHeight;

                                                  
     
                                           
                        
  String danmakuResetTo(String value);

                                                 
     
                                           
              
  String get naviAddAction;

                                                       
     
                                           
                           
  String playlistImportAdded(int count);

                                                           
     
                                           
                
  String get playlistAddEpisodeTitle;

                                                      
     
                                           
              
  String get playlistTitleLabel;

                                                       
     
                                           
                 
  String get playlistEpisodeHint;

                                                         
     
                                           
                  
  String get playlistVideoUrlLabel;

                                               
     
                                           
              
  String get playlistAdd;

                                                        
     
                                           
                     
  String get playlistNameRequired;

                                                           
     
                                           
                     
  String get playlistAtLeastOneVideo;

                                                     
     
                                           
                  
  String get playlistEditTitle;

                                                       
     
                                           
                  
  String get playlistCreateTitle;

                                                     
     
                                           
                  
  String get playlistNameLabel;

                                                    
     
                                           
                  
  String get playlistNameHint;

                                                       
     
                                           
                     
  String get playlistWebdavMulti;

                                                      
     
                                           
                     
  String playlistItemsCount(int count);

                                                   
     
                                           
                     
  String get playlistNoItems;

                                                      
     
                                           
                    
  String get playlistImportHint;

                                                       
     
                                           
                
  String get playlistSaveChanges;

                                                             
     
                                           
              
  String get playlistEpisodePanelTitle;

                                                          
     
                                           
                           
  String playlistEpisodeCurrent(int index);

                                                      
     
                                           
                            
  String playlistSyncResult(String what, String message);

                                                      
     
                                           
                    
  String get playlistSyncTwoWay;

                                                              
     
                                           
                                 
  String get playlistSyncTwoWaySubtitle;

                                                            
     
                                           
                 
  String get playlistRestoreFromCloud;

                                                                    
     
                                           
                                 
  String get playlistRestoreFromCloudSubtitle;

                                                         
     
                                           
                 
  String get playlistUploadToCloud;

                                                                 
     
                                           
                                 
  String get playlistUploadToCloudSubtitle;

                                                       
     
                                           
                  
  String get playlistSyncDanmaku;

                                                               
     
                                           
                            
  String get playlistSyncDanmakuSubtitle;

                                                   
     
                                           
                       
  String playlistCreated(String name);

                                                       
     
                                           
                  
  String get playlistDeleteTitle;

                                                         
     
                                           
                           
  String playlistDeleteConfirm(String name);

                                                      
     
                                           
                  
  String get playlistNewTooltip;

                                                     
     
                                           
                
  String get playlistListTitle;

                                                     
     
                                           
               
  String get playlistCloudSync;

                                                   
     
                                           
                
  String get playlistMyLists;

                                                   
     
                                           
                  
  String get playlistNoLists;

                                                       
     
                                           
                                    
  String playlistListSummary(int count);

                                                      
     
                                           
                   
  String get playlistEmptyTitle;

                                                     
     
                                           
                            
  String get playlistEmptyHint;

                                                  
     
                                           
              
  String get playlistResume;

                                                      
     
                                           
              
  String get playlistEditAction;

                                                        
     
                                           
                                       
  String playlistTileProgress(int total, int current);

                                               
     
                                           
                
  String get subtitleOff;

                                                         
     
                                           
                   
  String subtitleTrackFallback(String id);

                                                       
     
                                           
                         
  String subtitleLoadedLocal(String name);

                                                               
     
                                           
                           
  String get subtitleWebdavNotConfigured;

                                                             
     
                                           
                          
  String get subtitleWebdavFolderEmpty;

                                                      
     
                                           
                  
  String get subtitleSelectFile;

                                                          
     
                                           
                               
  String subtitleDownloadFailed(int code);

                                                        
     
                                           
                           
  String subtitleLoadedRemote(String name);

                                                     
     
                                           
                           
  String subtitleLoadError(String error);

                                                      
     
                                           
                   
  String get subtitlePanelTitle;

                                                     
     
                                           
                  
  String get subtitleLoadLocal;

                                                      
     
                                           
                         
  String get subtitleLoadWebdav;

                                                    
     
                                           
              
  String get subtitleFontSize;

                                                     
     
                                           
                
  String get subtitleFontColor;

                                                   
     
                                           
                
  String get subtitleBgColor;

                                                      
     
                                           
                      
  String get subtitleDragToggle;

                                                    
     
                                           
                            
  String get subtitleDragHint;

                                                         
     
                                           
                  
  String get subtitlePositionReset;

                                                   
     
                                           
                
  String get webdavInputPath;

                                              
     
                                           
              
  String get webdavGoTo;

                                                       
     
                                           
                          
  String get webdavLoginRequired;

                                                       
     
                                           
                         
  String get webdavLoginSubtitle;

                                                            
     
                                           
                            
  String get webdavLoginSubtitleMulti;

                                                 
     
                                           
              
  String get webdavRefresh;

                                              
     
                                           
             
  String get webdavRoot;

                                                
     
                                           
              
  String get webdavParent;

                                                     
     
                                           
                  
  String get webdavFolderEmpty;

                                                       
     
                                           
                   
  String get webdavPullToRefresh;

                                                     
     
                                           
                   
  String get webdavSelectVideo;

                                              
     
                                           
              
  String get webdavPlay;

                                                          
     
                                           
                
  String get webdavMultiSelectTitle;

                                                     
     
                                           
                 
  String get webdavNoSelection;

                                                       
     
                                           
                          
  String webdavSelectedCount(int count);

                                                        
     
                                           
                          
  String webdavSelectionOrder(String names);

                                               
     
                                           
              
  String get webdavClear;

                                                          
     
                                           
                
  String get webdavConfirmSelection;

                                                 
     
                                           
               
  String get webdavGoLogin;

                                                
     
                                           
                
  String get profileTitle;

                                                       
     
                                           
              
  String get settingsAvatarTitle;

                                                     
     
                                           
               
  String get settingsAvatarSet;

                                                  
     
                                           
               
  String get settingsNotSet;

                                                               
     
                                           
                
  String get settingsAvatarChangeTooltip;

                                                               
     
                                           
                
  String get settingsAvatarDeleteTooltip;

                                                         
     
                                           
                 
  String get settingsAvatarUpdated;

                                                            
     
                                           
                          
  String settingsPickAvatarFailed(String error);

                                                             
     
                                           
                
  String get settingsAvatarDeleteTitle;

                                                               
     
                                           
                       
  String get settingsAvatarDeleteConfirm;

                                                                        
     
                                           
                               
  String get settingsAvatarDeleteConfirmPermanent;

                                                         
     
                                           
                 
  String get settingsAvatarDeleted;

                                                    
     
                                           
              
  String get settingsNickname;

                                                               
     
                                           
                
  String get settingsNicknameEditTooltip;

                                                       
     
                                           
                
  String get settingsSetNickname;

                                                          
     
                                           
                   
  String get settingsNicknamePrompt;

                                                        
     
                                           
                
  String get settingsNicknameHint;

                                                         
     
                                           
                  
  String get settingsNicknameEmpty;

                                                           
     
                                           
                           
  String get settingsNicknameTooLong;

                                                           
     
                                           
                 
  String get settingsNicknameUpdated;

                                                         
     
                                           
                
  String get settingsLockWallpaper;

                                                              
     
                                           
                    
  String get settingsWallpaperCustomSet;

                                                              
     
                                           
                    
  String get settingsWallpaperDefaultBg;

                                                            
     
                                           
                 
  String get settingsWallpaperUpdated;

                                                                
     
                                           
                
  String get settingsWallpaperPickTooltip;

                                                           
     
                                           
                
  String get settingsWallpaperDelete;

                                                                  
     
                                           
                            
  String get settingsWallpaperDeleteConfirm;

                                                            
     
                                           
                 
  String get settingsWallpaperDeleted;

                                                     
     
                                           
                  
  String get settingsDecoImage;

                                                        
     
                                           
                               
  String get settingsDecoImageSet;

                                                            
     
                                           
                  
  String get settingsDecoImageUpdated;

                                                           
     
                                           
                          
  String settingsPickImageFailed(String error);

                                                            
     
                                           
                
  String get settingsPickImageTooltip;

                                                           
     
                                           
                 
  String get settingsDecoImageDelete;

                                                                  
     
                                           
                         
  String get settingsDecoImageDeleteConfirm;

                                                            
     
                                           
                  
  String get settingsDecoImageDeleted;

                                                
     
                                           
              
  String get settingsSize;

                                                       
     
                                           
                     
  String settingsSizePxLabel(String size);

                                                       
     
                                           
                    
  String settingsSizePxValue(String size);

                                                   
     
                                           
              
  String get settingsOpacity;

                                                               
     
                                           
                      
  String settingsOpacityPercentValue(int percent);

                                                   
     
                                           
              
  String get settingsDisplay;

                                                           
     
                                           
                             
  String get settingsDisplaySubtitle;

                                                    
     
                                           
                
  String get settingsAppTheme;

                                                        
     
                                           
                         
  String settingsCurrentColor(String color);

                                                      
     
                                           
                
  String get settingsFontWeight;

                                                             
     
                                           
                         
  String settingsCurrentFontWeight(int weight);

                                                        
     
                                           
                
  String get settingsDisplayScale;

                                                        
     
                                           
                           
  String settingsCurrentScale(int percent);

                                                      
     
                                           
                      
  String get settingsRestrictIp;

                                                              
     
                                           
                                   
  String get settingsRestrictIpSubtitle;

                                                       
     
                                           
                
  String get settingsDefaultPort;

                                                            
     
                                           
                  
  String get settingsAdjustFontWeight;

                                                             
     
                                           
                       
  String settingsFontWeightPreview(int weight);

                                                          
     
                                           
              
  String get settingsWeightHairline;

                                                      
     
                                           
             
  String get settingsWeightThin;

                                                         
     
                                           
              
  String get settingsWeightRegular;

                                                        
     
                                           
              
  String get settingsWeightMedium;

                                                      
     
                                           
             
  String get settingsWeightBold;

                                                       
     
                                           
              
  String get settingsWeightBlack;

                                                             
     
                                           
                   
  String get settingsFontWeightUpdated;

                                            
     
                                           
              
  String get logTitle;

                                                  
     
                                           
                  
  String get logBackTooltip;

                                              
     
                                           
              
  String get logRefresh;

                                               
     
                                           
                
  String get logClearAll;

                                                 
     
                                           
                
  String get logClearTitle;

                                                   
     
                                           
                                             
  String get logClearConfirm;

                                                  
     
                                           
              
  String get logClearAction;

                                                   
     
                                           
                             
  String logDeletedCount(int count);

                                                  
     
                                           
                
  String get logCopyContent;

                                            
     
                                           
                
  String get logShare;

                                                 
     
                                           
                 
  String get logDeleteThis;

                                                   
     
                                           
                 
  String get logEmptyContent;

                                                      
     
                                           
                       
  String logStorageLocation(String path);

                                                   
     
                                           
                      
  String get logErrorSection;

                                                  
     
                                           
                  
  String get logNoErrorLogs;

                                                 
     
                                           
                      
  String get logMpvSection;

                                                
     
                                           
                     
  String get logNoMpvLogs;

                                                  
     
                                           
                   
  String get logReadingLogs;

                                                        
     
                                           
                      
  String get lockFollowThemeColor;

                                                   
     
                                           
                
  String get lockShowBattery;

                                                   
     
                                           
                
  String get lockShowNetwork;

                                            
     
                                           
                          
  String lockDate(int month, int day);

                                                 
     
                                           
               
  String get weekdaySunday;

                                                 
     
                                           
               
  String get weekdayMonday;

                                                  
     
                                           
               
  String get weekdayTuesday;

                                                    
     
                                           
               
  String get weekdayWednesday;

                                                   
     
                                           
               
  String get weekdayThursday;

                                                 
     
                                           
               
  String get weekdayFriday;

                                                   
     
                                           
               
  String get weekdaySaturday;

                                                    
     
                                           
                         
  String get myQrSelectIpHint;

                                                
     
                                           
                   
  String get myQrNoIpType;

                                             
     
                                           
               
  String get myQrInUse;

                                               
     
                                           
                 
  String get myQrSetAsQr;

                                                       
     
                                           
                  
  String get netLanDiscoveryPort;

                                                  
     
                                           
                                
  String netDohNoRecord(String domain);

                                                     
     
                                           
                         
  String netDohQueryFailed(String error);

                                                   
     
                                           
                                  
  String netMappingSaved(String domain, String ip);

                                                     
     
                                           
                      
  String get netAddHostMapping;

                                                  
     
                                           
              
  String get netDomainLabel;

                                              
     
                                           
                 
  String get netIpLabel;

                                          
     
                                           
              
  String get netAdd;

                                                   
     
                                           
                                
  String netMappingAdded(String host, String ip);

                                                     
     
                                           
                         
  String netMappingRemoved(String host);

                                            
     
                                           
              
  String get netTitle;

                                                  
     
                                           
                  
  String get netBackTooltip;

                                                
     
                                           
                
  String get netRetestAll;

                                                            
     
                                           
                
  String get netConnectionModeSection;

                                                  
     
                                           
                
  String get netNetworkMode;

                                                        
     
                                           
                
  String get netModeStandardLabel;

                                                      
     
                                           
                
  String get netModeCompatLabel;

                                                       
     
                                           
                     
  String get netModeStandardDesc;

                                                        
     
                                           
                   
  String get netAllowInsecureCert;

                                                            
     
                                           
                                 
  String get netAllowInsecureCertDesc;

                                               
     
                                           
                   
  String get netChatIpv6;

                                                 
     
                                           
                                 
  String get netChatIpv6On;

                                                  
     
                                           
                           
  String get netChatIpv6Off;

                                                           
     
                                           
                              
  String get netChatIpv6EnabledSnack;

                                                            
     
                                           
                              
  String get netChatIpv6DisabledSnack;

                                                      
     
                                           
                        
  String get netLocalSendCompat;

                                                        
     
                                           
                                                                
  String get netLocalSendCompatOn;

                                                         
     
                                           
                              
  String get netLocalSendCompatOff;

                                                                  
     
                                           
                            
  String get netLocalSendCompatEnabledSnack;

                                                                   
     
                                           
                                    
  String get netLocalSendCompatDisabledSnack;

                                                  
     
                                           
                        
  String get lsSectionTitle;

                                                
     
                                           
                           
  String get lsHintEnable;

                                                    
     
                                           
                                                                      
  String get lsHintEnableDesc;

                                               
     
                                           
              
  String get lsEnableNow;

                                                  
     
                                           
                            
  String get lsEnabledSnack;

                                               
     
                                           
                            
  String get lsNoDevices;

                                              
     
                                           
                   
  String get lsHttpScan;

                                                  
     
                                           
                                
  String get lsHttpScanning;

                                                  
     
                                           
                
  String get lsHttpScanDone;

                                              
     
                                           
                
  String get lsSendFile;

                                                  
     
                                           
                                 
  String get lsSendFileDesc;

                                           
     
                                           
                
  String get lsProbe;

                                             
     
                                           
                   
  String get lsProbing;

                                                
     
                                           
                
  String get lsProbeFound;

                                                   
     
                                           
                 
  String get lsProbeNotFound;

                                                
     
                                           
                          
  String lsPickFailed(String error);

                                            
     
                                           
                    
  String get lsNoPath;

                                                  
     
                                           
                         
  String lsSendingTitle(String alias);

                                                 
     
                                           
                            
  String lsSendSuccess(int count);

                                                
     
                                           
                                  
  String lsSendFailed(int count);

                                                         
     
                                           
                  
  String get lsReceiveRequestTitle;

                                                        
     
                                           
                                      
  String lsReceiveRequestDesc(int count, String size);

                                            
     
                                           
              
  String get lsAccept;

                                            
     
                                           
              
  String get lsReject;

                                              
     
                                           
                
  String get lsOpenFile;

                                                          
     
                                           
                  
  String get lsReceiveCompleteTitle;

                                                         
     
                                           
                                    
  String lsReceiveCompleteDesc(String fileName, String path);

                                                  
     
                                           
                            
  String lsFileReceived(String fileName);

                                                          
     
                                           
                 
  String get netConnectivitySection;

                                                         
     
                                           
                   
  String get netHostMappingSection;

                                                   
     
                                           
                        
  String get netMappingReset;

                                                      
     
                                           
                
  String get netRestoreDefaults;

                                                 
     
                                           
                
  String get netNoMappings;

                                                 
     
                                           
                
  String get netAddMapping;

                                                      
     
                                           
                  
  String get netDohQuerySection;

                                                   
     
                                           
                                                                 
  String get netDohQueryDesc;

                                                       
     
                                           
                           
  String netDohResultDisplay(String domain, String ip);

                                                    
     
                                           
                 
  String get netSaveAsMapping;

                                                     
     
                                           
               
  String get netHeadersSection;

                                                    
     
                                           
                                               
  String get netRefererNotSet;

                                             
     
                                           
               
  String get netNotSet;

                                                        
     
                                           
                      
  String netHeaderEditorTitle(String title);

                                                  
     
                                           
                       
  String netHeaderSaved(String title);

                                            
     
                                           
                
  String get ossTitle;

                                                  
     
                                           
                  
  String get ossBackTooltip;

                                                   
     
                                           
                
  String get ossCopyFullText;

                                                    
     
                                           
                       
  String get ossLicenseCopied;

                                                    
     
                                           
                
  String get playHistoryTitle;

                                                          
     
                                           
                  
  String get playHistoryBackTooltip;

                                                       
     
                                           
                
  String get playHistoryClearAll;

                                                    
     
                                           
                 
  String get playHistoryEmpty;

                                                       
     
                                           
                       
  String get playHistoryEmptySub;

                                                         
     
                                           
                  
  String get playHistoryClearTitle;

                                                           
     
                                           
                                     
  String get playHistoryClearConfirm;

                                                          
     
                                           
              
  String get playHistoryClearAction;

                                                     
     
                                           
                
  String get playHistoryResume;

                                                           
     
                                           
                
  String get playHistoryDeleteRecord;

                                                      
     
                                           
                             
  String playHistoryDeleted(String title);

                                               
     
                                           
              
  String get timeJustNow;

                                                  
     
                                           
                       
  String timeMinutesAgo(int count);

                                                
     
                                           
                       
  String timeHoursAgo(int count);

                                               
     
                                           
                      
  String timeDaysAgo(int count);

                                                     
     
                                           
                
  String get playerArtistVideo;

                                                        
     
                                           
                
  String get playerArtistPlaylist;

                                                      
     
                                           
                     
  String get playerArtistWebdav;

                                                        
     
                                           
                     
  String get playerWebdavSubtitle;

                                                    
     
                                           
                              
  String playerResumeFrom(String position);

                                                    
     
                                           
                         
  String playerNowPlaying(String title);

                                                      
     
                                           
                           
  String playerDanmakuCache(int count);

                                                         
     
                                           
                                  
  String playerDanmakuBilibili(int count);

                                                       
     
                                           
                    
  String get playerDanmakuNoData;

                                                       
     
                                           
                           
  String playerDanmakuLoaded(int count);

                                                       
     
                                           
                                    
  String playerDanmakuOnline(int count);

                                                                
     
                                           
                                
  String playerDanmakuLoadedFromCache(int count);

                                                             
     
                                           
                             
  String playerDanmakuLoadedOnline(int count);

                                                          
     
                                           
                         
  String playerScreenshotFailed(String error);

                                                      
     
                                           
                  
  String get playerSavedToAlbum;

                                                                
     
                                           
                                
  String playerScreenshotSavedToAlbum(String fileName);

                                                    
     
                                           
                         
  String playerSaveFailed(String error);

                                                   
     
                                           
                            
  String playerPipFailed(String error);

                                                  
     
                                           
              
  String get playerFitAdapt;

                                                    
     
                                           
              
  String get playerFitStretch;

                                                 
     
                                           
              
  String get playerFitFill;

                                                  
     
                                           
                
  String get playerEndPause;

                                                 
     
                                           
                
  String get playerEndLoop;

                                                 
     
                                           
                
  String get playerEndExit;

                                                          
     
                                           
                
  String get playerSubtitleSettings;

                                                          
     
                                           
                
  String get playerAdvancedSettings;

                                                        
     
                                           
                
  String get playerFlipHorizontal;

                                                            
     
                                           
                  
  String get playerFlipHorizontalDesc;

                                                      
     
                                           
                
  String get playerFlipVertical;

                                                          
     
                                           
                  
  String get playerFlipVerticalDesc;

                                                   
     
                                           
                    
  String get playerShowStats;

                                                       
     
                                           
                        
  String get playerShowStatsDesc;

                                                 
     
                                           
                     
  String get playerAutoPip;

                                                             
     
                                           
                     
  String get playerLoadDanmakuOnResume;

                                                                 
     
                                           
                             
  String get playerLoadDanmakuOnResumeDesc;

                                                     
     
                                           
                
  String get playerDefaultRate;

                                                            
     
                                           
                  
  String get playerDefaultEndBehavior;

                                                         
     
                                           
                   
  String get playerTimePickerTitle;

                                                      
     
                                           
             
  String get playerTimeUnitHour;

                                                        
     
                                           
             
  String get playerTimeUnitMinute;

                                                        
     
                                           
             
  String get playerTimeUnitSecond;

                                                   
     
                                           
                  
  String get playerBuffering;

                                                       
     
                                           
                   
  String get playerHwdecSoftware;

                                                       
     
                                           
                       
  String playerHwdecHardware(String mode);

                                                     
     
                                           
                
  String get playerSourceLocal;

                                                        
     
                                           
               
  String get playerStatResolution;

                                                        
     
                                           
                
  String get playerStatVideoCodec;

                                                        
     
                                           
                
  String get playerStatAudioCodec;

                                                     
     
                                           
              
  String get playerStatBitrate;

                                                 
     
                                           
              
  String get playerStatFps;

                                                    
     
                                           
              
  String get playerStatDecode;

                                                      
     
                                           
              
  String get playerStatSubtitle;

                                            
     
                                           
              
  String get playerOn;

                                             
     
                                           
              
  String get playerOff;

                                                     
     
                                           
              
  String get playerStatDanmaku;

                                                      
     
                                           
              
  String get playerStatDownload;

                                                    
     
                                           
              
  String get playerStatSource;

                                                      
     
                                           
              
  String get playerStatPosition;

                                                      
     
                                           
              
  String get playerStatDuration;

                                                  
     
                                           
                  
  String get playerCopyLink;

                                                    
     
                                           
                          
  String playerCopyLinkAt(String time);

                                                     
     
                                           
                  
  String get playerCopyLinkAt0;

                                                      
     
                                           
                     
  String playerCopyLinkDone(String url);

                                                         
     
                                           
                         
  String get playerCopyLinkNotBili;

                                                     
     
                                           
                  
  String get playerColorAdjust;

                                                         
     
                                           
              
  String get playerColorBrightness;

                                                       
     
                                           
               
  String get playerColorContrast;

                                                         
     
                                           
               
  String get playerColorSaturation;

                                                  
     
                                           
              
  String get playerColorHue;

                                                    
     
                                           
              
  String get playerColorGamma;

                                                    
     
                                           
              
  String get playerColorReset;

                                                          
     
                                           
                        
  String get playerColorUnavailable;

                                               
     
                                           
                
  String get playerStats;

                                                          
     
                                           
                 
  String get playerAlignAspectRatio;

                                                              
     
                                           
                     
  String get playerAlignAspectRatioDone;

                                                                
     
                                           
                    
  String get playerAlignAspectRatioFailed;

                                               
     
                                           
              
  String get commonClose;

                                                       
     
                                           
                
  String get playerPlaybackError;

                                                           
     
                                           
                            
  String playerAllEpisodesPlayed(int count);

                                                        
     
                                           
                        
  String playerFastForwarding(String rate);

                                                   
     
                                           
                
  String get playerTapToSave;

                                                     
     
                                           
                
  String get playerResetScreen;

                                                     
     
                                           
                  
  String get playerBackTooltip;

                                                  
     
                                           
                 
  String get playerRotate90;

                                                 
     
                                           
              
  String get playerQuality;

                                                       
     
                                           
                           
  String get playerQualityLocked;

                                                    
     
                                           
              
  String get playerFullscreen;

                                                      
     
                                           
                
  String get playerBiliSubtitle;

                                                      
     
                                           
                
  String get playerDecodeFormat;

                                                                  
     
                                           
                    
  String get playerDecodeFormatSwitchFailed;

                                                    
     
                                           
              
  String get playerDecodeAuto;

                                                         
     
                                           
              
  String get playerDecodeAutoShort;

                                                   
     
                                           
                       
  String get playerDecodeAvc;

                                                    
     
                                           
                        
  String get playerDecodeHevc;

                                                   
     
                                           
               
  String get playerDecodeAv1;

                                                            
     
                                           
                  
  String get playerSubtitleLoadFailed;

                                                           
     
                                           
                
  String get playerSubtitleBilingual;

                                                             
     
                                           
                                        
  String playerSubtitleBilingualOn(String primary, String secondary);

                                                                      
     
                                           
                                
  String get playerSubtitleBilingualUnavailable;

                                                            
     
                                           
                
  String get playerSubtitleSecondLang;

                                                      
     
                                           
                
  String get playerSubtitleDrag;

                                                        
     
                                           
                                 
  String get playerSubtitleDragOn;

                                                         
     
                                           
                   
  String get playerSubtitleDragOff;

                                                          
     
                                           
                  
  String get playerSubtitleDragging;

                                                          
     
                                           
                       
  String get playerSubtitleDragHint;

                                                               
     
                                           
                   
  String get playerSubtitlePositionSaved;

                                                               
     
                                           
                  
  String get playerSubtitlePositionReset;

                                                      
     
                                           
                
  String get playerPortraitMode;

                                                       
     
                                           
                
  String get playerLandscapeMode;

                                                     
     
                                           
              
  String get playerDescription;

                                                      
     
                                           
                      
  String get playerWebdavSource;

                                              
     
                                           
              
  String get playerCast;

                                                       
     
                                           
               
  String get playerWatchTogether;

                                                    
     
                                           
                    
  String get watchInviteTitle;

                                                      
     
                                           
                   
  String get watchWaitingAccept;

                                                   
     
                                           
                    
  String get watchSelectPeer;

                                                     
     
                                           
                    
  String get watchNoOnlinePeer;

                                                   
     
                                           
                            
  String watchInviteSent(String name);

                                                   
     
                                           
                          
  String watchActiveWith(String name);

                                                     
     
                                           
                     
  String get watchPeerRejected;

                                                     
     
                                           
                    
  String get watchPeerNoAnswer;

                                                 
     
                                           
                    
  String get watchPeerLeft;

                                                  
     
                                           
                        
  String get watchTcpFailed;

                                                          
     
                                           
                       
  String get watchConnectionDropped;

                                                   
     
                                           
                           
  String get watchUrlInvalid;

                                                 
     
                                           
                      
  String get rcInviteTitle;

                                                
     
                                           
                                
  String get rcInviteHint;

                                                  
     
                                           
                       
  String get rcPeerRejected;

                                               
     
                                           
                         
  String get rcTcpFailed;

                                                       
     
                                           
                        
  String get rcConnectionDropped;

                                             
     
                                           
                    
  String get rcTimeout;

                                                         
     
                                           
                           
  String get rcShizukuNotInstalled;

                                                             
     
                                           
                                                    
  String get rcShizukuNotInstalledHint;

                                                       
     
                                           
                         
  String get rcShizukuGrantTitle;

                                                      
     
                                           
                                             
  String get rcShizukuGrantHint;

                                                  
     
                                           
                      
  String get rcShizukuGrant;

                                                
     
                                           
                
  String get rcRequesting;

                                                       
     
                                           
                       
  String get rcShizukuNotGranted;

                                                         
     
                                           
                          
  String rcScreenCaptureFailed(String error);

                                                 
     
                                           
                  
  String get rcShareFailed;

                                           
     
                                           
              
  String get rcRetry;

                                           
     
                                           
              
  String get rcClose;

                                            
     
                                           
              
  String get rcCancel;

                                          
     
                                           
              
  String get rcSend;

                                                
     
                                           
                 
  String get rcConnecting;

                                                 
     
                                           
                         
  String rcControlling(String name);

                                                     
     
                                           
                             
  String rcBeingControlled(String name);

                                         
     
                                           
                  
  String get rcEnd;

                                                    
     
                                           
                     
  String get rcConnectionLost;

                                                  
     
                                           
                   
  String get rcSessionEnded;

                                               
     
                                           
                
  String get rcInputText;

                                                   
     
                                           
                        
  String get rcInputTextHint;

                                             
     
                                           
              
  String get rcKeyBack;

                                             
     
                                           
              
  String get rcKeyHome;

                                                
     
                                           
                
  String get rcKeyRecents;

                                                 
     
                                           
               
  String get rcKeyVolumeUp;

                                                   
     
                                           
               
  String get rcKeyVolumeDown;

                                                 
     
                                           
              
  String get dlnaPageTitle;

                                               
     
                                           
                
  String get dlnaRefresh;

                                                 
     
                                           
                        
  String get dlnaSearching;

                                                
     
                                           
                    
  String get dlnaNoDevice;

                                                    
     
                                           
                                             
  String get dlnaNoDeviceHint;

                                                   
     
                                           
                
  String get dlnaSearchAgain;

                                                    
     
                                           
                
  String get dlnaFoundDevices;

                                                   
     
                                           
                         
  String dlnaCastStarted(String device);

                                                  
     
                                           
                         
  String dlnaCastFailed(String device);

                                                 
     
                                           
                          
  String dlnaCastingTo(String device);

                                                
     
                                           
                
  String get dlnaStopCast;

                                            
     
                                           
              
  String get dlnaPlay;

                                             
     
                                           
              
  String get dlnaPause;

                                                
     
                                           
                
  String get dlnaVolumeUp;

                                                  
     
                                           
                
  String get dlnaVolumeDown;

                                                   
     
                                           
                   
  String get dlnaFileMissing;

                                                         
     
                                           
                              
  String dlnaServerStartFailed(String error);

                                                       
     
                                           
              
  String get playerEpisodeSelect;

                                                         
     
                                           
                
  String get playerDanmakuSettings;

                                           
     
                                           
               
  String get psTitle;

                                                 
     
                                           
                  
  String get psBackTooltip;

                                                   
     
                                           
                
  String get psStaffEntrance;

                                                    
     
                                           
              
  String get psDisplaySection;

                                               
     
                                           
               
  String get psStatusBar;

                                                   
     
                                           
                              
  String get psStatusBarDesc;

                                                     
     
                                           
                   
  String get psKeepWindowRatio;

                                                         
     
                                           
                           
  String get psKeepWindowRatioDesc;

                                                                
     
                                           
                                            
  String get psKeepWindowRatioDesktopOnly;

                                                        
     
                                           
              
  String get psInteractionSection;

                                                    
     
                                           
                 
  String get psLongPressSpeed;

                                                        
     
                                           
                                
  String get psLongPressSpeedDesc;

                                                
     
                                           
                
  String get psScreenshot;

                                                    
     
                                           
                               
  String get psScreenshotDesc;

                                                       
     
                                           
                   
  String get psScreenshotDanmaku;

                                                           
     
                                           
                          
  String get psScreenshotDanmakuDesc;

                                                     
     
                                           
              
  String get psProgressSection;

                                                  
     
                                           
                
  String get psPlayProgress;

                                               
     
                                           
                     
  String get psNoHistory;

                                                  
     
                                           
                          
  String psHistoryCount(int count);

                                                 
     
                                           
              
  String get psMiscSection;

                                           
     
                                           
                
  String get psHwdec;

                                               
     
                                           
                     
  String get psHwdecAuto;

                                                   
     
                                           
                         
  String get psHwdecSoftware;

                                                    
     
                                           
              
  String get psHwdecAutoShort;

                                                       
     
                                           
               
  String get psHwdecPureSoftware;

                                                      
     
                                           
                 
  String get psHwdecDisabledTag;

                                                  
     
                                           
                
  String get hwdecPageTitle;

                                                
     
                                           
                
  String get hwdecEnabled;

                                                    
     
                                           
                              
  String get hwdecEnabledHint;

                                                      
     
                                           
                        
  String get hwdecOnlySupported;

                                                          
     
                                           
                                                              
  String get hwdecOnlySupportedHint;

                                             
     
                                           
                                                                                             
  String get hwdecHint;

                                                       
     
                                           
                    
  String hwdecSelectedPrefix(String n);

                                                     
     
                                           
                                                  
  String get hwdecEmptyWarning;

                                               
     
                                           
                
  String get psVideoSync;

                                                       
     
                                           
                        
  String get psVsyncAudioDefault;

                                                   
     
                                           
                         
  String get psVsyncResample;

                                                
     
                                           
                           
  String get psVsyncAdrop;

                                                
     
                                           
                           
  String get psVsyncVdrop;

                                                
     
                                           
              
  String get psVsyncAudio;

                                                          
     
                                           
                 
  String get psVsyncDisplayResample;

                                                       
     
                                           
                  
  String get psVsyncDisplayAdrop;

                                                       
     
                                           
                  
  String get psVsyncDisplayVdrop;

                                                        
     
                                           
                    
  String get psImmersiveLongPress;

                                                            
     
                                           
                                
  String get psImmersiveLongPressDesc;

                                                
     
                                           
              
  String get psLogSection;

                                            
     
                                           
                     
  String get psMpvLog;

                                                   
     
                                           
                                  
  String psMpvLogEnabled(String level);

                                                    
     
                                           
                               
  String get psMpvLogDisabled;

                                                 
     
                                           
                    
  String get psMpvLogLevel;

                                                     
     
                                           
                             
  String get psMpvLogLevelDesc;

                                                 
     
                                           
               
  String get psMpvLogError;

                                                
     
                                           
              
  String get psMpvLogWarn;

                                                       
     
                                           
                  
  String get psMpvLogWarnDefault;

                                                
     
                                           
              
  String get psMpvLogInfo;

                                                   
     
                                           
              
  String get psMpvLogVerbose;

                                                 
     
                                           
              
  String get psMpvLogDebug;

                                                 
     
                                           
                   
  String get psMpvLogTrace;

                                              
     
                                           
                
  String get psViewLogs;

                                                  
     
                                           
                                  
  String get psViewLogsDesc;

                                                       
     
                                           
                       
  String testPlaylistCreated(String name);

                                                 
     
                                           
               
  String get testPageTitle;

                                                          
     
                                           
                
  String get testVideoSourceSection;

                                                           
     
                                           
                      
  String get testVideoSourceSubtitle;

                                                   
     
                                           
                     
  String get testWebdavVideo;

                                                       
     
                                           
                             
  String get testWebdavVideoDesc;

                                                  
     
                                           
                
  String get testLocalVideo;

                                                      
     
                                           
                        
  String get testLocalVideoDesc;

                                                     
     
                                           
                
  String get testRecentSection;

                                                          
     
                                           
                  
  String get testLastPlayedSubtitle;

                                                 
     
                                           
                  
  String get testNoRecords;

                                                       
     
                                           
                
  String get testPlaylistSection;

                                                               
     
                                           
                          
  String get testPlaylistSectionSubtitle;

                                                      
     
                                           
                  
  String get testPlaylistManage;

                                                          
     
                                           
                                   
  String get testPlaylistManageDesc;

                                                      
     
                                           
                  
  String get testPlaylistCreate;

                                                          
     
                                           
                                  
  String get testPlaylistCreateDesc;

                                                           
     
                                           
                
  String get testQuickActionsSection;

                                                            
     
                                           
                  
  String get testQuickActionsSubtitle;

                                                     
     
                                           
                    
  String get testUrlDirectPlay;

                                                         
     
                                           
                         
  String get testUrlDirectPlayDesc;

                                                         
     
                                           
                   
  String get testVideoWithSubtitle;

                                                             
     
                                           
                       
  String get testVideoWithSubtitleDesc;

                                                     
     
                                           
                      
  String get testNoVideoPlayed;

                                                     
     
                                           
                    
  String get testEnterUrlTitle;

                                            
     
                                           
              
  String get testPlay;

                                                        
     
                                           
                 
  String get testAddSubtitleTitle;

                                                         
     
                                           
                                    
  String testAddSubtitlePrompt(String name);

                                            
     
                                           
              
  String get testSkip;

                                                      
     
                                           
                
  String get testSelectSubtitle;

                                                     
     
                                           
                     
  String get testAboutLegalese;

                                                 
     
                                           
                                                                                          
  String get testAboutBody;

                                                   
     
                                           
                
  String get testSourceLocal;

                                                           
     
                                           
                   
  String get testSourceLocalSubtitle;

                                                            
     
                                           
                   
  String get accountsBiliLoginSuccess;

                                                           
     
                                           
                     
  String get accountsBiliLogoutTitle;

                                                          
     
                                           
                                       
  String get accountsBiliLogoutHint;

                                                                   
     
                                           
                            
  String get accountsClearWebviewCookieTitle;

                                                                      
     
                                           
                                 
  String get accountsClearWebviewCookieSubtitle;

                                                  
     
                                           
              
  String get accountsLogout;

                                                               
     
                                           
                              
  String get accountsLoggedOutWithCookie;

                                                     
     
                                           
                 
  String get accountsLoggedOut;

                                                            
     
                                           
                           
  String get accountsClearCookieTitle;

                                                              
     
                                           
                                            
  String get accountsClearCookieContent;

                                                       
     
                                           
              
  String get accountsClearAction;

                                                         
     
                                           
                           
  String get accountsCookieCleared;

                                                       
     
                                           
                                      
  String get accountsCookieEmpty;

                                                          
     
                                           
                    
  String get accountsBiliLoginTitle;

                                                             
     
                                           
                                 
  String get accountsBiliLoginSubtitle;

                                                              
     
                                           
                          
  String get accountsClearBrowserCookie;

                                                                      
     
                                           
                      
  String get accountsClearBrowserCookieSubtitle;

                                                    
     
                                           
               
  String get accountsLoggedIn;

                                                       
     
                                           
                           
  String accountsLoggedInUid(int mid);

                                                       
     
                                           
                        
  String get accountsCarryCookie;

                                                         
     
                                           
                               
  String get accountsCarryCookieOn;

                                                          
     
                                           
                               
  String get accountsCarryCookieOff;

                                                       
     
                                           
                       
  String get accountsCookieScope;

                                                               
     
                                           
                             
  String get accountsCookieScopeSubtitle;

                                                    
     
                                           
                       
  String get cookieScopeTitle;

                                                   
     
                                           
                                                                           
  String get cookieScopeHint;

                                                    
     
                                           
                   
  String get cookieScopeVideo;

                                                        
     
                                           
                            
  String get cookieScopeVideoDesc;

                                                       
     
                                           
              
  String get cookieScopeComments;

                                                           
     
                                           
                   
  String get cookieScopeCommentsDesc;

                                                     
     
                                           
              
  String get cookieScopeSearch;

                                                         
     
                                           
                       
  String get cookieScopeSearchDesc;

                                                      
     
                                           
                 
  String get cookieScopeArticle;

                                                          
     
                                           
                       
  String get cookieScopeArticleDesc;

                                                        
     
                                           
                
  String get cookieScopeUserSpace;

                                                            
     
                                           
                            
  String get cookieScopeUserSpaceDesc;

                                                     
     
                                           
                 
  String get cookieScopeSeason;

                                                         
     
                                           
                       
  String get cookieScopeSeasonDesc;

                                                           
     
                                           
                
  String get cookieScopeInteractions;

                                                               
     
                                           
                                     
  String get cookieScopeInteractionsDesc;

                                                        
     
                                           
                
  String get cookieScopeEnableAll;

                                                         
     
                                           
                
  String get cookieScopeDisableAll;

                                                       
     
                                           
                     
  String get accountsWebdavCloud;

                                                              
     
                                           
                         
  String get accountsWebdavConfiguredOn;

                                                               
     
                                           
                         
  String get accountsWebdavConfiguredOff;

                                                               
     
                                           
                        
  String get accountsWebdavNotConfigured;

                                                 
     
                                           
              
  String get accountsTitle;

                                                       
     
                                           
                 
  String get accountsSectionBili;

                                                     
     
                                           
                  
  String get commonBackTooltip;

                                                       
     
                                           
                    
  String get biliLoginFetchingQr;

                                                          
     
                                           
                         
  String get biliLoginQrFetchFailed;

                                                        
     
                                           
                            
  String get biliLoginScanWithApp;

                                                            
     
                                           
                    
  String get biliLoginInputAccountPwd;

                                                        
     
                                           
                    
  String get biliLoginFailedRetry;

                                                  
     
                                           
                 
  String get biliLoginTitle;

                                                     
     
                                           
                
  String get biliLoginScanMode;

                                                       
     
                                           
                     
  String get biliLoginCookieMode;

                                                    
     
                                           
                
  String get biliLoginPwdMode;

                                                       
     
                                           
                     
  String get biliLoginViaBrowser;

                                                       
     
                                           
                                                
  String get biliLoginCookieHint;

                                                     
     
                                           
                 
  String get biliLoginWebTitle;

                                                               
     
                                           
                                       
  String get biliLoginCookieImportFailed;

                                                    
     
                                           
                
  String get biliLoginRefetch;

                                                      
     
                                           
                 
  String get biliLoginRefreshQr;

                                                    
     
                                           
                                             
  String get biliLoginScanTip;

                                                              
     
                                           
                                                                                                                              
  String get biliLoginCookieInstruction;

                                                      
     
                                           
                
  String get biliLoginVerifying;

                                                           
     
                                           
                 
  String get biliLoginVerifyAndLogin;

                                                         
     
                                           
                              
  String get biliLoginAccountLabel;

                                                          
     
                                           
              
  String get biliLoginPasswordLabel;

                                                      
     
                                           
                
  String get biliLoginLoggingIn;

                                                        
     
                                           
              
  String get biliLoginLoginAction;

                                                       
     
                                           
                                      
  String get biliLoginSliderHint;

                                                   
     
                                           
              
  String get searchFilterAny;

                                                       
     
                                           
                
  String get searchFilterLastDay;

                                                        
     
                                           
                
  String get searchFilterLastWeek;

                                                        
     
                                           
                
  String get searchFilterHalfYear;

                                                           
     
                                           
                
  String get searchFilterAllDuration;

                                                        
     
                                           
                  
  String get searchFilterDur0to10;

                                                         
     
                                           
                   
  String get searchFilterDur10to30;

                                                         
     
                                           
                   
  String get searchFilterDur30to60;

                                                         
     
                                           
                 
  String get searchFilterDur60plus;

                                                 
     
                                           
              
  String get searchZoneAll;

                                                   
     
                                           
              
  String get searchZoneAnime;

                                                       
     
                                           
              
  String get searchZoneGuochuang;

                                                   
     
                                           
              
  String get searchZoneMusic;

                                                   
     
                                           
              
  String get searchZoneDance;

                                                  
     
                                           
              
  String get searchZoneGame;

                                                       
     
                                           
              
  String get searchZoneKnowledge;

                                                  
     
                                           
              
  String get searchZoneTech;

                                                    
     
                                           
              
  String get searchZoneSports;

                                                 
     
                                           
              
  String get searchZoneCar;

                                                  
     
                                           
              
  String get searchZoneLife;

                                                  
     
                                           
              
  String get searchZoneFood;

                                                    
     
                                           
              
  String get searchZoneAnimal;

                                                     
     
                                           
              
  String get searchZoneKichiku;

                                                     
     
                                           
              
  String get searchZoneFashion;

                                                  
     
                                           
              
  String get searchZoneInfo;

                                                 
     
                                           
              
  String get searchZoneEnt;

                                                 
     
                                           
              
  String get searchZoneDoc;

                                                  
     
                                           
              
  String get searchZoneFilm;

                                                
     
                                           
              
  String get searchZoneTv;

                                                           
     
                                           
                    
  String get searchCaptchaInitFailed;

                                                           
     
                                           
                   
  String get searchCaptchaIncomplete;

                                                               
     
                                           
                   
  String get searchCaptchaValidateFailed;

                                                                    
     
                                           
                       
  String get searchCaptchaValidateFailedRetry;

                                                       
     
                                           
                       
  String get searchCaptchaPassed;

                                                  
     
                                           
                   
  String get searchBiliHint;

                                                      
     
                                           
                
  String get searchHistoryTitle;

                                                      
     
                                           
              
  String get searchHistoryClear;

                                                             
     
                                           
                          
  String get searchHistoryClearConfirm;

                                                      
     
                                           
                  
  String get searchHistoryEmpty;

                                                
     
                                           
              
  String get drawerSearch;

                                                  
     
                                           
              
  String get drawerDynamics;

                                                  
     
                                           
              
  String get drawerMessages;

                                              
     
                                           
              
  String get drawerMine;

                                                          
     
                                           
                 
  String get biliAccountNotLoggedIn;

                                                   
     
                                           
              
  String get bottomNavMoveUp;

                                                     
     
                                           
              
  String get bottomNavMoveDown;

                                                          
     
                                           
                
  String get bottomNavSettingsTitle;

                                                             
     
                                           
                                       
  String get bottomNavSettingsSubtitle;

                                                     
     
                                           
              
  String get bottomNavItemHome;

                                                         
     
                                           
              
  String get bottomNavItemDynamics;

                                                     
     
                                           
              
  String get bottomNavItemLive;

                                                          
     
                                           
              
  String get bottomNavSettingsReset;

                                                            
     
                                           
                     
  String get bottomNavSettingsKeepOne;

                                                     
     
                                           
              
  String get prefSearchSection;

                                                      
     
                                           
                     
  String get prefSearchTrending;

                                                         
     
                                           
                            
  String get prefSearchTrendingSub;

                                                       
     
                                           
                
  String get prefSearchDiscovery;

                                                          
     
                                           
                          
  String get prefSearchDiscoverySub;

                                                       
     
                                           
                 
  String get searchTrendingTitle;

                                                          
     
                                           
                
  String get searchTrendingFullList;

                                                        
     
                                           
                
  String get searchDiscoveryTitle;

                                                  
     
                                           
                      
  String get hotSearchTitle;

                                                         
     
                                           
                
  String get searchDiscoveryFailed;

                                                        
     
                                           
                
  String get searchDiscoveryEmpty;

                                                     
     
                                           
                  
  String get searchVideoFilter;

                                                         
     
                                           
                        
  String searchFilterWithCount(int count);

                                                
     
                                           
              
  String get searchFilter;

                                                         
     
                                           
              
  String get searchSwitchSingleCol;

                                                     
     
                                           
              
  String get searchSwitchMulti;

                                                     
     
                                           
              
  String get searchLayoutMulti;

                                                      
     
                                           
              
  String get searchLayoutSingle;

                                                       
     
                                           
                  
  String get searchPickStartDate;

                                                     
     
                                           
                  
  String get searchPickEndDate;

                                                        
     
                                           
                
  String get searchPubTimeSection;

                                                   
     
                                           
              
  String get searchDateBegin;

                                                
     
                                           
             
  String get searchDateTo;

                                                 
     
                                           
              
  String get searchDateEnd;

                                                         
     
                                           
                
  String get searchDurationSection;

                                                     
     
                                           
                
  String get searchZoneSection;

                                                   
     
                                           
                 
  String get searchAntiFuzzy;

                                                       
     
                                           
                                          
  String get searchAntiFuzzyHint;

                                                     
     
                                           
              
  String get searchFilterReset;

                                                   
     
                                           
                     
  String get searchAllLoaded;

                                                     
     
                                           
                       
  String get searchKeywordHint;

                                                       
     
                                           
                         
  String get searchPressToSearch;

                                                        
     
                                           
                                   
  String searchNoResultInType(String keyword, String type);

                                                      
     
                                           
                                  
  String searchResultsCount(String type, String count);

                                                       
     
                                           
                
  String get userSpaceLoadFailed;

                                                             
     
                                           
                  
  String get userSpaceAvatarLoadFailed;

                                                  
     
                                           
                  
  String get userSpaceTitle;

                                                    
     
                                           
                        
  String get userSpaceLoading;

                                                        
     
                                           
                
  String get userSpaceLoadingName;

                                                     
     
                                           
              
  String get userSpaceStatFans;

                                                          
     
                                           
              
  String get userSpaceStatFollowing;

                                                       
     
                                           
              
  String get userSpaceStatVideos;

                                                      
     
                                           
              
  String get userSpaceStatLikes;

                                                       
     
                                           
                         
  String userSpaceVideoCount(int count);

                                                             
     
                                           
                
  String get userSpaceSectionAllVideos;

                                                     
     
                                           
                
  String get userSpaceNoVideos;

                                                          
     
                                           
                  
  String get userSpaceDynLoadFailed;

                                                       
     
                                           
                
  String get userSpaceNoDynamics;

                                                              
     
                                           
                    
  String get userSpaceBangumiLoadFailed;

                                                      
     
                                           
                
  String get userSpaceNoBangumi;

                                                         
     
                                           
                            
  String userSpaceBangumiCount(int count);

                                                     
     
                                           
                         
  String get userSpaceLazySign;

                                                    
     
                                           
              
  String get userSpaceTabHome;

                                                       
     
                                           
              
  String get userSpaceTabDynamic;

                                                       
     
                                           
              
  String get userSpaceTabBangumi;

                                                  
     
                                           
              
  String get userSpaceToday;

                                                            
     
                                           
              
  String get userSpaceBangumiFinished;

                                                               
     
                                           
               
  String get userSpaceBangumiSerializing;

                                                              
     
                                           
                     
  String userSpaceBangumiAiringDate(String date);

                                              
     
                                           
              
  String get browserApp;

                                                         
     
                                           
                         
  String browserOpenAppAttempt(String app);

                                                       
     
                                           
                        
  String get browserNoAppForLink;

                                                           
     
                                           
                               
  String get browserOpenFailedSystem;

                                                          
     
                                           
                 
  String get browserEmptyCookieHint;

                                                  
     
                                           
                
  String get browserCopyAll;

                                                       
     
                                           
                     
  String get browserCookieCopied;

                                                      
     
                                           
                     
  String get browserCookieEmpty;

                                                     
     
                                           
                         
  String get browserSetUaTitle;

                                                 
     
                                           
                            
  String get browserUaHint;

                                                         
     
                                           
                 
  String get browserApplyAndReload;

                                                    
     
                                           
                       
  String get browserUaUpdated;

                                                      
     
                                           
                             
  String browserUaSetFailed(String error);

                                                            
     
                                           
                                                    
  String get browserWindowsInitFailed;

                                                               
     
                                           
                                                                              
  String get browserBiliCookieReadFailed;

                                                             
     
                                           
                           
  String get browserCookieImportFailed;

                                                         
     
                                           
                 
  String get browserStoppedLoading;

                                                           
     
                                           
                      
  String get browserClipboardAllowed;

                                                           
     
                                           
                        
  String get browserClipboardBlocked;

                                                       
     
                                           
                    
  String get browserNoCurrentUrl;

                                                             
     
                                           
                                
  String get browserTroubleshootFailed;

                                                               
     
                                           
                     
  String get browserSystemBrowserMissing;

                                                  
     
                                           
              
  String get browserQrTitle;

                                                       
     
                                           
                 
  String get browserSaveToDevice;

                                                  
     
                                           
                         
  String get browserQrSaved;

                                                     
     
                                           
                         
  String browserSaveFailed(String error);

                                                      
     
                                           
                
  String get browserStopLoading;

                                                    
     
                                           
                
  String get browserImporting;

                                                          
     
                                           
                   
  String get browserLoginDoneImport;

                                                          
     
                                           
                 
  String get browserClipboardAccess;

                                                  
     
                                           
                 
  String get browserShareQr;

                                                   
     
                                           
                
  String get browserCopyLink;

                                                      
     
                                           
                      
  String get browserViewCookies;

                                                
     
                                           
                 
  String get browserSetUa;

                                                     
     
                                           
                    
  String get browserUaModeAuto;

                                                        
     
                                           
               
  String get browserUaModeDesktop;

                                                       
     
                                           
               
  String get browserUaModeMobile;

                                                  
     
                                           
              
  String get browserRefresh;

                                                        
     
                                           
                 
  String get browserSystemBrowser;

                                                              
     
                                           
                  
  String get browserTroubleshootNetwork;

                                                              
     
                                           
                        
  String get browserUnsupportedPlatform;

                                                         
     
                                           
                        
  String get browserOpenedInSystem;

                                                         
     
                                           
                      
  String get browserReopenInSystem;

                                                            
     
                                           
                
  String get browserAndroidErrorTitle;

                                                            
     
                                           
              
  String get browserAndroidErrorCause;

                                                             
     
                                           
                                                  
  String get browserAndroidErrorDetail;

                                                        
     
                                           
                                                    
  String get browserUpdateWebview;

                                                         
     
                                           
                                
  String get browserOpenDevOptions;

                                                          
     
                                           
                      
  String get browserAppleErrorTitle;

                                                           
     
                                           
                
  String get browserAppleErrorReport;

                                                           
     
                                           
                                            
  String get browserAppleErrorDetail;

                                                      
     
                                           
                                                   
  String get browserBsodMessage;

                                                        
     
                                           
                            
  String get browserBsodNoRestart;

                                                       
     
                                           
                   
  String get browserBsodComplete;

                                                        
     
                                           
                   
  String get browserBsodSolutions;

                                                       
     
                                           
                           
  String get browserBsodDownload;

                                                        
     
                                           
                           
  String get browserBsodWinUpdate;

                                                     
     
                                           
                          
  String get browserBsodScanQr;

                                                       
     
                                           
                                         
  String get browserBsodStopCode;

                                                           
     
                                           
                    
  String get browserCantOpenExternal;

                                                
     
                                           
                   
  String get callOutgoing;

                                                
     
                                           
                 
  String get callIncoming;

                                                  
     
                                           
                  
  String get callConnecting;

                                                                     
     
                                           
                        
  String get chatConnectionNotEstablishedImage;

                                                 
     
                                           
                   
  String get chatImageSent;

                                                       
     
                                           
                  
  String get chatImageSendFailed;

                                                                   
     
                                           
                             
  String chatClipboardImageProcessFailed(String error);

                                                   
     
                                           
                        
  String get chatImageStaged;

                                                        
     
                                           
                    
  String get chatClipboardNoImage;

                                                                 
     
                                           
                             
  String chatClipboardImageFetchFailed(String error);

                                                                   
     
                                           
                       
  String get chatClipboardEmptyOrUnsupported;

                                                                    
     
                                           
                        
  String get chatConnectionNotEstablishedFile;

                                                    
     
                                           
                 
  String get chatFileNotExist;

                                                      
     
                                           
                  
  String get chatFileSendFailed;

                                                       
     
                                           
                             
  String chatFileSentSuccess(String fileName);

                                                     
     
                                           
                          
  String chatFileSendError(String error);

                                                 
     
                                           
                 
  String get chatIpUnknown;

                                                    
     
                                           
                       
  String get chatReconnecting;

                                                       
     
                                           
                             
  String get chatReconnectFailed;

                                                     
     
                                           
                
  String get chatStatusUnknown;

                                                     
     
                                           
                
  String get chatStatusWaiting;

                                          
     
                                           
             
  String get chatMe;

                                                    
     
                                           
                    
  String get chatFileInfoLost;

                                                      
     
                                           
                            
  String chatOpenFileFailed(String message);

                                                         
     
                                           
                  
  String get chatFileNotDownloaded;

                                                     
     
                                           
                          
  String chatOpenFileError(String error);

                                                           
     
                                           
                              
  String get chatFilePathUnavailable;

                                                      
     
                                           
                          
  String chatPickFileFailed(String error);

                                                            
     
                                           
                    
  String get chatImagePathUnavailable;

                                                       
     
                                           
                          
  String chatPickImageFailed(String error);

                                                
     
                                           
                
  String get chatCopyText;

                                                  
     
                                           
                
  String get chatSelectText;

                                                
     
                                           
                
  String get chatOpenFile;

                                                 
     
                                           
                
  String get chatCopyImage;

                                                 
     
                                           
                
  String get chatSaveImage;

                                                    
     
                                           
                     
  String get chatCopyingImage;

                                                   
     
                                           
                       
  String get chatImageCopied;

                                                  
     
                                           
                
  String get chatCopyFailed;

                                                       
     
                                           
                           
  String chatCopyImageFailed(String error);

                                              
     
                                           
                   
  String get chatSaving;

                                                   
     
                                           
                  
  String get chatSaveSuccess;

                                                  
     
                                           
                         
  String chatSaveFailed(String error);

                                                      
     
                                           
                
  String get chatMessageContent;

                                                    
     
                                           
                   
  String get chatEmptyContent;

                                                            
     
                                           
                         
  String get chatDeleteMessageConfirm;

                                                      
     
                                           
                 
  String get chatMessageDeleted;

                                                     
     
                                           
                
  String get chatOpenLinkTitle;

                                                
     
                                           
                     
  String chatWillOpen(String url);

                                                    
     
                                           
                   
  String get chatBrowserTitle;

                                                    
     
                                           
                  
  String get chatCantOpenLink;

                                                      
     
                                           
                          
  String chatOpenLinkFailed(String error);

                                                 
     
                                           
              
  String get chatPlusImage;

                                                
     
                                           
              
  String get chatPlusFile;

                                                  
     
                                           
                 
  String get chatImageReady;

                                            
     
                                           
              
  String get chatMore;

                                                  
     
                                           
                
  String get chatPasteImage;

                                                 
     
                                           
                   
  String get chatInputHint;

                                             
     
                                           
                
  String get chatEmoji;

                                            
     
                                           
              
  String get chatSend;

                                                      
     
                                           
                       
  String get chatInvalidAddress;

                                                      
     
                                           
                  
  String get chatImageSendError;

                                                  
     
                                           
                        
  String chatSendFailed(String error);

                                                         
     
                                           
                         
  String get chatConnStatusUnknown;

                                                         
     
                                           
                         
  String get chatPendingCannotSend;

                                                    
     
                                           
                  
  String get chatConnRejected;

                                                        
     
                                           
                   
  String get chatConnDisconnected;

                                                          
     
                                           
                         
  String get chatConnNotEstablished;

                                                  
     
                                           
                      
  String get chatNoMessages;

                                                         
     
                                           
                        
  String get chatDisconnectedRetry;

                                                     
     
                                           
                      
  String get chatRejectedRetry;

                                                   
     
                                           
                 
  String get chatExpandInput;

                                                    
     
                                           
                    
  String get discoverMyLanIps;

                                                      
     
                                           
                                 
  String get discoverNoIpOfType;

                                                    
     
                                           
                    
  String discoverIpCopied(String ip);

                                                 
     
                                           
                  
  String get discoverTitle;

                                                
     
                                           
                 
  String get discoverMyIp;

                                                            
     
                                           
                 
  String get discoverRefreshBroadcast;

                                                      
     
                                           
                 
  String get discoverLanDevices;

                                                     
     
                                           
                        
  String get discoverSearching;

                                                       
     
                                           
                    
  String get discoverSendRequest;

                                                         
     
                                           
                     
  String get discoverPendingVerify;

                                                         
     
                                           
                     
  String get discoverRejectedRetry;

                                                             
     
                                           
                    
  String get discoverDisconnectedRetry;

                                                         
     
                                           
                
  String get discoverUnknownDevice;

                                                            
     
                                           
                  
  String get discoverAlreadyConnected;

                                                          
     
                                           
                           
  String get discoverAlreadyPending;

                                                         
     
                                           
                             
  String get discoverConnectFailed;

                                                         
     
                                           
                    
  String get discoverManualConnect;

                                                         
     
                                           
                                                
  String get discoverConnectIpHint;

                                                       
     
                                           
                         
  String get displayScaleCompact;

                                                     
     
                                           
                     
  String get displayScaleSmall;

                                                       
     
                                           
              
  String get displayScaleDefault;

                                                     
     
                                           
                     
  String get displayScaleLarge;

                                                         
     
                                           
                       
  String get displayScaleLargeFont;

                                                    
     
                                           
                     
  String get displayScaleHuge;

                                                   
     
                                           
                       
  String get displayScaleMin;

                                                          
     
                                           
                     
  String get displayScaleCompactBig;

                                                             
     
                                           
                
  String get displayScaleSystemDefault;

                                                              
     
                                           
                     
  String get displayScaleLargeFontShort;

                                                     
     
                                           
                
  String get displayScaleTitle;

                                                           
     
                                           
                 
  String get displaySplashBackground;

                                                                 
     
                                           
                        
  String get displaySplashBackgroundCustom;

                                                                  
     
                                           
              
  String get displaySplashBackgroundDefault;

                                                                  
     
                                           
                           
  String get displaySplashBackgroundSetDone;

                                                                    
     
                                           
                     
  String get displaySplashBackgroundSetFailed;

                                                                  
     
                                           
                    
  String get displaySplashBackgroundCleared;

                                                                       
     
                                           
                
  String get displaySplashBackgroundClearTooltip;

                                                             
     
                                           
                  
  String get displayHeroTransitionBlur;

                                                            
     
                                           
                      
  String get displayIosPushTransition;

                                                                  
     
                                           
                
  String get displayIosPushTransitionCorner;

                                                                      
     
                                           
                    
  String get displayIosPushTransitionCornerAuto;

                                                                             
     
                                           
                                 
  String get displayIosPushTransitionCornerUnsupported;

                                                           
     
                                           
                      
  String get searchIosPushTransition;

                                               
     
                                           
                 
  String get pageBgTitle;

                                                  
     
                                           
                              
  String get pageBgSubtitle;

                                                 
     
                                           
                   
  String get pageBgEnabled;

                                                 
     
                                           
                
  String get pageBgOpacity;

                                              
     
                                           
                
  String get pageBgBlur;

                                                
     
                                           
               
  String get pageBgNotSet;

                                              
     
                                           
                   
  String get pageBgPick;

                                               
     
                                           
                 
  String get pageBgClear;

                                                        
     
                                           
                 
  String get pageBgContentSection;

                                                        
     
                                           
                  
  String get pageBgContentEnabled;

                                                         
     
                                           
                                           
  String get pageBgContentSubtitle;

                                                        
     
                                           
                 
  String get pageBgContentOpacity;

                                                     
     
                                           
                 
  String get pageBgContentBlur;

                                                     
     
                                           
                     
  String get pageBgContentPick;

                                                      
     
                                           
                    
  String get pageBgContentClear;

                                               
     
                                           
                  
  String get pageBgSaved;

                                                 
     
                                           
                  
  String get pageBgCleared;

                                                    
     
                                           
                  
  String get pageBgPickFailed;

                                             
     
                                           
                 
  String get cropTitle;

                                                  
     
                                           
              
  String get cropAspectFree;

                                             
     
                                           
              
  String get cropApply;

                                             
     
                                           
              
  String get cropReset;

                                                        
     
                                           
                
  String get displayAdvancedGlass;

                                                                  
     
                                           
                
  String get displayDisableLiquidGlassMenus;

                                                    
     
                                           
                  
  String get displayMenuJelly;

                                                        
     
                                           
                                    
  String get displayMenuJellyHint;

                                                         
     
                                           
                  
  String get displayBottomBarJelly;

                                                             
     
                                           
                                   
  String get displayBottomBarJellyHint;

                                                         
     
                                           
                    
  String get displayVideoCardGlass;

                                                             
     
                                           
                                           
  String get displayVideoCardGlassHint;

                                                    
     
                                           
                       
  String get displayChatGlass;

                                                        
     
                                           
                                
  String get displayChatGlassHint;

                                                           
     
                                           
                  
  String get displayLiquidGlassTuner;

                                                                   
     
                                           
                                 
  String get displayLiquidGlassTunerSubtitle;

                                                  
     
                                           
                
  String get lgTunerPreview;

                                                          
     
                                           
                
  String get lgTunerSectionMaterial;

                                                    
     
                                           
                
  String get lgTunerThickness;

                                               
     
                                           
                
  String get lgTunerBlur;

                                               
     
                                           
                
  String get lgTunerTint;

                                                     
     
                                           
               
  String get lgTunerSaturation;

                                                          
     
                                           
               
  String get lgTunerRefractiveIndex;

                                                         
     
                                           
                
  String get lgTunerLightIntensity;

                                                  
     
                                           
               
  String get lgTunerAmbient;

                                                     
     
                                           
                
  String get lgTunerLightAngle;

                                                     
     
                                           
              
  String get lgTunerAberration;

                                                
     
                                           
                
  String get lgTunerReset;

                                               
     
                                           
                                                                       
  String get lgTunerNote;

                                                       
     
                                           
                                                                         
  String get lgTunerFallbackNote;

                                                     
     
                                           
                    
  String get displayScaleReset;

                                                        
     
                                           
                
  String get displayScaleFineTune;

                                                       
     
                                           
                
  String get displayScalePresets;

                                                    
     
                                           
                                                          
  String get displayScaleNote;

                                                         
     
                                           
                       
  String displayScaleConnCount(int count);

                                                     
     
                                           
              
  String get displayThemeLight;

                                                    
     
                                           
              
  String get displayThemeDark;

                                                        
     
                                           
              
  String get displaySettingsTitle;

                                                            
     
                                           
              
  String get displaySectionAppearance;

                                                    
     
                                           
                
  String get displayThemeMode;

                                                    
     
                                           
                  
  String get displayPureBlack;

                                                      
     
                                           
                     
  String get displayPureBlackOn;

                                              
     
                                           
               
  String get displayOff;

                                                             
     
                                           
               
  String get displaySectionPersonalize;

                                                     
     
                                           
                
  String get displayThemeColor;

                                                            
     
                                           
                  
  String get displayFollowSystemColor;

                                                     
     
                                           
                
  String get displayFontWeight;

                                                           
     
                                           
               
  String get displaySeedDefaultGreen;

                                                   
     
                                           
               
  String get displaySeedPink;

                                                  
     
                                           
              
  String get displaySeedRed;

                                                     
     
                                           
              
  String get displaySeedOrange;

                                                    
     
                                           
               
  String get displaySeedAmber;

                                                     
     
                                           
              
  String get displaySeedYellow;

                                                   
     
                                           
               
  String get displaySeedLime;

                                                         
     
                                           
               
  String get displaySeedLightGreen;

                                                    
     
                                           
              
  String get displaySeedGreen;

                                                   
     
                                           
              
  String get displaySeedCyan;

                                                   
     
                                           
               
  String get displaySeedTeal;

                                                        
     
                                           
               
  String get displaySeedLightBlue;

                                                   
     
                                           
              
  String get displaySeedBlue;

                                                     
     
                                           
               
  String get displaySeedIndigo;

                                                     
     
                                           
              
  String get displaySeedPurple;

                                                         
     
                                           
               
  String get displaySeedDeepPurple;

                                                       
     
                                           
               
  String get displaySeedBlueGrey;

                                                    
     
                                           
              
  String get displaySeedBrown;

                                                   
     
                                           
              
  String get displaySeedGrey;

                                                     
     
                                           
               
  String get displaySeedCustom;

                                                     
     
                                           
                         
  String displayWeightThin(int weight);

                                                      
     
                                           
                        
  String displayWeightLight(int weight);

                                                        
     
                                           
                         
  String displayWeightRegular(int weight);

                                                       
     
                                           
                         
  String displayWeightMedium(int weight);

                                                     
     
                                           
                        
  String displayWeightBold(int weight);

                                                      
     
                                           
                         
  String displayWeightBlack(int weight);

                                                       
     
                                           
                          
  String displayWeightCustom(int weight);

                                                  
     
                                           
              
  String get fontWeightThin;

                                                   
     
                                           
             
  String get fontWeightLight;

                                                     
     
                                           
              
  String get fontWeightRegular;

                                                    
     
                                           
              
  String get fontWeightMedium;

                                                  
     
                                           
             
  String get fontWeightBold;

                                                   
     
                                           
              
  String get fontWeightBlack;

                                                        
     
                                           
                                                                        
  String get fontWeightSampleText;

                                                       
     
                                           
                 
  String get fontWeightSaveApply;

                                                
     
                                           
                  
  String get geetestTitle;

                                                     
     
                                           
                                   
  String get geetestInitFailed;

                                                      
     
                                           
                                         
  String get geetestUnsupported;

                                                        
     
                                           
                  
  String get slicerPickImageFirst;

                                                       
     
                                           
                    
  String get slicerRowColInvalid;

                                                 
     
                                           
                         
  String get slicerSuccess;

                                                    
     
                                           
                         
  String slicerSaveFailed(String error);

                                               
     
                                           
                  
  String get slicerTitle;

                                                  
     
                                           
                          
  String get slicerTileSize;

                                                   
     
                                           
                     
  String get slicerColsLabel;

                                                   
     
                                           
                     
  String get slicerRowsLabel;

                                                 
     
                                           
                                       
  String slicerPreview(int count, String type);

                                                    
     
                                           
                  
  String get slicerProcessing;

                                                     
     
                                           
                   
  String get slicerSaveToStart;

                                                
     
                                           
                   
  String get viewerSaving;

                                                     
     
                                           
                
  String get viewerSaveSuccess;

                                                    
     
                                           
                         
  String viewerSaveFailed(String error);

                                                    
     
                                           
                
  String get viewerShareImage;

                                                     
     
                                           
                         
  String viewerShareFailed(String error);

                                                 
     
                                           
                   
  String get viewerCopying;

                                                    
     
                                           
                         
  String viewerCopyFailed(String error);

                                                     
     
                                           
                 
  String get viewerSaveToAlbum;

                                                         
     
                                           
                  
  String get viewerCopyToClipboard;

                                                         
     
                                           
                  
  String get viewerImageLoadFailed;

                                                           
     
                                           
                   
  String get viewerImageDataNotFound;

                                                       
     
                                           
                  
  String get userSpaceMidInvalid;

                                                   
     
                                           
                     
  String get userSpaceNoCard;

                                                   
     
                                           
                     
  String get userSpaceNoList;

                                                   
     
                                           
              
  String get searchTypeVideo;

                                                     
     
                                           
              
  String get searchTypeBangumi;

                                                
     
                                           
              
  String get searchTypeFt;

                                                  
     
                                           
               
  String get searchTypeLive;

                                                  
     
                                           
              
  String get searchTypeUser;

                                                     
     
                                           
              
  String get searchTypeArticle;

                                                   
     
                                           
             
  String get tenThousandUnit;

                                                   
     
                                           
                                  
  String searchVideoMeta(String play, String danmaku);

                                               
     
                                           
                      
  String searchScore(String score);

                                                
     
                                           
                      
  String searchOnline(String count);

                                                  
     
                                           
                                 
  String searchUserMeta(String fans, String videos);

                                                     
     
                                           
                                   
  String searchArticleMeta(String views, String replies);

                                                     
     
                                           
              
  String get searchBadgeCourse;

                                                   
     
                                           
              
  String get searchBadgeLive;

                                                   
     
                                           
              
  String get searchBadgeCoop;

                                                      
     
                                           
               
  String get searchBadgeLiveNow;

                                                      
     
                                           
                 
  String get searchKeywordEmpty;

                                                     
     
                                           
                  
  String get searchBadResponse;

                                                
     
                                           
                
  String get searchFailed;

                                                          
     
                                           
                              
  String get searchGaiaParamMissing;

                                                           
     
                                           
                                     
  String searchGaiaRegisterError(String error);

                                                            
     
                                           
                                                  
  String searchGaiaValidateFailed(int isValid);

                                                           
     
                                           
                                     
  String searchGaiaValidateError(String error);

                                                   
     
                                           
                  
  String get commentOidEmpty;

                                                    
     
                                           
                       
  String commentException(String error);

                                                       
     
                                           
                           
  String commentSubHttpError(int code);

                                                    
     
                                           
                        
  String get commentSubNoData;

                                                       
     
                                           
                          
  String commentSubException(String error);

                                                      
     
                                           
                                 
  String get commentNotLoggedIn;

                                                     
     
                                           
                                    
  String get commentMissingJct;

                                                       
     
                                           
                         
  String commentNetworkError(String error);

                                                   
     
                                           
                                  
  String commentApiError(String message, int code);

                                            
     
                                           
                
  String get deviceOs;

                                               
     
                                           
                
  String get deviceBuild;

                                                       
     
                                           
                
  String get deviceSecurityPatch;

                                             
     
                                           
                  
  String get deviceOem;

                                               
     
                                           
              
  String get deviceBrand;

                                               
     
                                           
              
  String get deviceModel;

                                                    
     
                                           
                    
  String get deviceRomVersion;

                                                     
     
                                           
                
  String get deviceFingerprint;

                                              
     
                                           
                
  String get deviceName;

                                                      
     
                                           
                
  String get deviceComputerName;

                                                       
     
                                           
                
  String get deviceHardwareModel;

                                                
     
                                           
                
  String get deviceKernel;

                                                
     
                                           
               
  String get deviceDistro;

                                                 
     
                                           
              
  String get deviceVersion;

                                                  
     
                                           
              
  String get devicePlatform;

                                                    
     
                                           
                           
  String deviceInfoFailed(String error);

                                                     
     
                                           
                         
  String get logWebUnsupported;

                                                     
     
                                           
                  
  String get logNotInitialized;

                                                 
     
                                           
                          
  String logAppDataDir(String path);

                                                     
     
                                           
                                    
  String logAppDataRoaming(String path);

                                                 
     
                                           
                                       
  String logAppSupport(String path);

                                                   
     
                                           
                          
  String logLocalDataDir(String path);

                                                   
     
                                           
                  
  String get nowPlayingVideo;

                                                 
     
                                           
              
  String get commonUnknown;

                                                   
     
                                           
                   
  String get unnamedPlaylist;

                                                
     
                                           
                
  String get unknownVideo;

                                                  
     
                                           
                                 
  String dohQueryFailed(int code);

                                                     
     
                                           
                    
  String get tcpConnectSuccess;

                                                 
     
                                           
                                    
  String get netModeCompat;

                                                   
     
                                           
                   
  String get netModeStandard;

                                                        
     
                                           
                         
  String netHostResolveFailed(String host);

                                                   
     
                                           
                     
  String get biliCookieEmpty;

                                                        
     
                                           
                                                     
  String get biliCookieIncomplete;

                                                        
     
                                           
                                                               
  String get biliCookieMissingJct;

                                                     
     
                                           
                                   
  String get biliCookieInvalid;

                                                    
     
                                           
                
  String get biliLoginSuccess;

                                                 
     
                                           
                       
  String biliHttpError(int code);

                                                   
     
                                           
                               
  String get biliRiskBlocked;

                                                 
     
                                           
                  
  String get biliQrExpired;

                                                 
     
                                           
                       
  String get biliQrScanned;

                                                 
     
                                           
                
  String get biliQrWaiting;

                                                     
     
                                           
                
  String get biliRequestFailed;

                                                      
     
                                           
                     
  String get biliResponseNoData;

                                                         
     
                                           
                                  
  String get biliQrNoSessionCookie;

                                                    
     
                                           
                                                              
  String get biliQrMissingJct;

                                                       
     
                                           
                         
  String get biliNoSessionCookie;

                                                    
     
                                           
                          
  String get biliWebKeyFailed;

                                                        
     
                                           
                  
  String get biliPwdEncryptFailed;

                                                   
     
                                           
                    
  String get biliNeedGeetest;

                                                    
     
                                           
                
  String get biliUnknownError;

                                               
     
                                           
                
  String get csPlaylists;

                                             
     
                                           
              
  String get csDanmaku;

                                                    
     
                                           
                                        
  String get csCloudEncrypted;

                                                       
     
                                           
                                
  String get csCloudPassMismatch;

                                                 
     
                                           
                           
  String get csCloudNoFile;

                                                       
     
                                           
                  
  String get csRestoredFromCloud;

                                              
     
                                           
                
  String get csSyncDone;

                                                   
     
                                           
                           
  String csUploadBgCount(int count);

                                                     
     
                                           
                           
  String csDownloadBgCount(int count);

                                                       
     
                                           
                          
  String csUploadedFileCount(int count);

                                                         
     
                                           
                          
  String csDownloadedFileCount(int count);

                                                      
     
                                           
                          
  String csMergedListsCount(int count);

                                               
     
                                           
               
  String get csEncrypted;

                                                
     
                                           
                         
  String csSyncFailed(String error);

                                                       
     
                                           
                                
  String csUploadedPlaylists(int count);

                                                    
     
                                           
                                             
  String csDanmakuSummary(int uploaded, int downloaded);

                                                   
     
                                           
                                     
  String csDanmakuFailed(int failed, String details);

                                               
     
                                           
                
  String get unknownUser;

                                                     
     
                                           
                                    
  String transferSpeedBody(String fileName, String speed);

                                               
     
                                           
                
  String get sendingFile;

                                                 
     
                                           
                          
  String receivingFile(String fileName);

                                                           
     
                                           
                
  String get notificationChannelName;

                                                           
     
                                           
                       
  String get notificationChannelDesc;

                                                     
     
                                           
              
  String get notificationReply;

                                                        
     
                                           
                 
  String get screenshotSavedTitle;

                                                          
     
                                           
                    
  String get screenshotSavedToAlbum;

                                                       
     
                                           
              
  String get notificationConfirm;

                                                       
     
                                           
                          
  String get callInProgressError;

                                                 
     
                                           
                                    
  String get callTcpFailed;

                                                         
     
                                           
                                
  String get callConnectionDropped;

                                                  
     
                                           
                          
  String callInitFailed(String error);

                                                    
     
                                           
                          
  String callAcceptFailed(String error);

                                                   
     
                                           
                
  String get callRecordVoice;

                                                            
     
                                           
                
  String get callRecordMissedOutgoing;

                                                      
     
                                           
                 
  String get callRecordRejected;

                                                            
     
                                           
                
  String get callRecordMissedIncoming;

                                                    
     
                                           
                 
  String get callPeerNoAnswer;

                                               
     
                                           
              
  String get callUnknown;

                                                  
     
                                           
               
  String get callInProgress;

                                                     
     
                                           
                                              
  String get webdavHttpWarning;

                                                        
     
                                           
                         
  String get webdavConfigRequired;

                                                    
     
                                           
                         
  String get webdavAuthFailed;

                                                       
     
                                           
                            
  String webdavConnectFailed(int code);

                                                      
     
                                           
                                 
  String webdavNetworkError(String msg);

                                                      
     
                                           
                        
  String webdavUnknownError(String error);

                                                       
     
                                           
                      
  String get webdavNotConfigured;

                                                          
     
                                           
                           
  String webdavLocalFileMissing(String path);

                                                      
     
                                           
                            
  String webdavUploadFailed(int code);

                                                     
     
                                           
                        
  String webdavUploadError(String error);

                                                        
     
                                           
                             
  String webdavDownloadFailed(int code);

                                                       
     
                                           
                         
  String webdavDownloadError(String error);

                                                      
     
                                           
                         
  String webdavDeleteFailed(String error);

                                                    
     
                                           
                           
  String webdavListFailed(String error);

                                                        
     
                                           
                                    
  String webdavPropfindFailed(int code);

                                                    
     
                                           
                      
  String webdavNetworkErr(String msg);

                                                         
     
                                           
                               
  String webdavPreparingBackup(int count);

                                                   
     
                                           
                                        
  String webdavBackingUp(String nickname, String fileName);

                                                    
     
                                           
                                       
  String webdavBackupDone(int success, int fail);

                                                
     
                                           
              
  String get commonCancel;

                                            
     
                                           
              
  String get commonOk;

                                                 
     
                                           
              
  String get commonConnect;

                                              
     
                                           
              
  String get commonSave;

                                                
     
                                           
              
  String get commonCreate;

                                                
     
                                           
              
  String get commonDelete;

                                              
     
                                           
              
  String get drawerHome;

                                                              
     
                                           
                
  String get drawerVerificationRequests;

                                                  
     
                                           
              
  String get drawerSettings;

                                               
     
                                           
              
  String get drawerAbout;

                                                   
     
                                           
                
  String get drawerCloseMenu;

                                                 
     
                                           
                
  String get drawerLockNow;

                                                    
     
                                           
                 
  String get drawerNoNickname;

                                                      
     
                                           
                   
  String get drawerSwitchToDark;

                                                       
     
                                           
                   
  String get drawerSwitchToLight;

                                                   
     
                                           
                
  String get drawerLightMode;

                                                  
     
                                           
                
  String get drawerDarkMode;

                                                    
     
                                           
                
  String get drawerSystemMode;

                                                       
     
                                           
                       
  String drawerThemeSwitched(String mode);

                                                     
     
                                           
                         
  String drawerFetchFailed(String error);

                                                      
     
                                           
                  
  String get drawerNoDeviceInfo;

                                                         
     
                                           
                 
  String get drawerBackgroundTitle;

                                                             
     
                                           
                                  
  String get drawerBackgroundHasCustom;

                                                            
     
                                           
                            
  String get drawerBackgroundNoCustom;

                                                           
     
                                           
                    
  String get drawerBackgroundUpdated;

                                                             
     
                                           
                         
  String drawerBackgroundSetFailed(String error);

                                                          
     
                                           
                
  String get drawerBackgroundChange;

                                                          
     
                                           
                  
  String get drawerBackgroundSelect;

                                                            
     
                                           
                   
  String get drawerBackgroundRestored;

                                                          
     
                                           
                
  String get drawerBackgroundRemove;

                                                
     
                                           
                
  String get homeOpenMenu;

                                                     
     
                                           
                
  String get homeAddConnection;

                                                
     
                                           
              
  String get homeMessages;

                                                     
     
                                           
                
  String get homeNoConnections;

                                                         
     
                                           
                        
  String get homePullToRefreshHint;

                                                  
     
                                           
                        
  String get homeLoadFailed;

                                                 
     
                                           
                
  String get homeRetryLoad;

                                                      
     
                                           
                
  String get homeUnknownAddress;

                                                  
     
                                           
                
  String get homeNoMessages;

                                                   
     
                                           
                           
  String homeFileMessage(String fileName);

                                                        
     
                                           
              
  String get homeFileFallbackName;

                                                          
     
                                           
                
  String get homeMessagePlaceholder;

                                                  
     
                                           
                 
  String get connectionLost;

                                                   
     
                                           
                   
  String get openVideoFailed;

                                                      
     
                                           
                  
  String get connectDialogTitle;

                                                 
     
                                           
                                                 
  String get connectIpHint;

                                                  
     
                                           
                     
  String get connectIpEmpty;

                                                    
     
                                           
                      
  String get connectIpInvalid;

                                                   
     
                                           
                       
  String get connectIpNotLan;

                                                      
     
                                           
                          
  String get connectRequestSent;

                                                 
     
                                           
                                     
  String get connectFailed;

                                              
     
                                           
               
  String get homeScanQr;

                                                
     
                                           
                 
  String get homeMyQrCode;

                                                 
     
                                           
                
  String get homeManualAdd;

                                                  
     
                                           
                   
  String get scannedFriends;

                                             
     
                                           
               
  String get scanTitle;

                                                   
     
                                           
                        
  String get scanTitleWebdav;

                                            
     
                                           
                         
  String get scanHint;

                                                  
     
                                           
                                 
  String get scanHintWebdav;

                                                     
     
                                           
                         
  String get scanHintAddFriend;

                                                 
     
                                           
                      
  String get scanPreparing;

                                                        
     
                                           
                   
  String get scanPermissionNeeded;

                                                           
     
                                           
                                
  String get scanPermissionNeededMsg;

                                                        
     
                                           
                    
  String get scanPermissionDenied;

                                                           
     
                                           
                                 
  String get scanPermissionDeniedMsg;

                                                         
     
                                           
                  
  String get scanCameraUnavailable;

                                             
     
                                           
              
  String get scanRetry;

                                                    
     
                                           
                  
  String get scanOpenSettings;

                                             
     
                                           
               
  String get scanTorch;

                                                    
     
                                           
                 
  String get scanDetectedLink;

                                                      
     
                                           
                            
  String get scanOpenLinkPrompt;

                                            
     
                                           
              
  String get scanCopy;

                                            
     
                                           
              
  String get scanOpen;

                                                  
     
                                           
                 
  String get scanLinkCopied;

                                                         
     
                                           
                       
  String get scanDetectedBiliVideo;

                                                       
     
                                           
                          
  String get scanBiliVideoPrompt;

                                                   
     
                                           
                      
  String scanBiliVideoAt(String time);

                                                 
     
                                           
                
  String get scanOpenVideo;

                                                      
     
                                           
                         
  String get scanDetectedWebdav;

                                                    
     
                                           
                                          
  String get scanWebdavPrompt;

                                                     
     
                                           
                 
  String get scanOpenInBrowser;

                                                  
     
                                           
                
  String get scanFillConfig;

                                                    
     
                                           
                 
  String get scanDetectedText;

                                                         
     
                                           
                   
  String get scanCopiedToClipboard;

                                             
     
                                           
              
  String get scanClose;

                                                   
     
                                           
                
  String get scanResultTitle;

                                                       
     
                                           
                    
  String get scanErrorPermission;

                                                        
     
                                           
                     
  String get scanErrorUnsupported;

                                                     
     
                                           
                      
  String get scanErrorDisposed;

                                                    
     
                                           
                          
  String scanErrorGeneric(String code);

                                                  
     
                                           
                            
  String scanInitFailed(String error);

                                                      
     
                                           
                    
  String get scanDetectedDevice;

                                                       
     
                                           
                       
  String get scanAddFriendPrompt;

                                                 
     
                                           
                
  String get scanAddFriend;

                                                   
     
                                           
                          
  String get scanFriendAdded;

                                                       
     
                                           
                               
  String get scanFriendAddFailed;

                                             
     
                                           
                 
  String get myQrTitle;

                                            
     
                                           
                        
  String get myQrHint;

                                               
     
                                           
                            
  String get myQrEmbedIp;

                                                
     
                                           
                    
  String get myQrLocalIps;

                                                   
     
                                           
                   
  String get myQrCopyContent;

                                              
     
                                           
                   
  String get myQrCopied;

                                            
     
                                           
                                 
  String get myQrNoIp;

                                                           
     
                                           
              
  String get displayModeSectionTitle;

                                                    
     
                                           
                
  String get displayModeTitle;

                                                   
     
                                           
              
  String get displayModeAuto;

                                                        
     
                                           
                
  String get displayModeSystemTag;

                                                   
     
                                           
                       
  String get displayModeHint;

                                                          
     
                                           
                                    
  String get displayModeUnsupported;

                                                          
     
                                           
                     
  String get displayModeAndroidOnly;

                                                      
     
                                           
                       
  String get displayModeLoading;

                                                    
     
                                           
                       
  String get displayModeEmpty;

                                                        
     
                                           
                
  String get playerSectionEnhance;

                                                        
     
                                           
                
  String get superResolutionTitle;

                                                      
     
                                           
              
  String get superResolutionOff;

                                                             
     
                                           
                   
  String get superResolutionEfficiency;

                                                          
     
                                           
                    
  String get superResolutionQuality;

                                                       
     
                                           
                                               
  String get superResolutionHint;

                                                       
     
                                           
                   
  String get skipIntroOutroTitle;

                                                      
     
                                           
                                           
  String get skipIntroOutroHint;

                                             
     
                                           
                
  String get skipIntro;

                                             
     
                                           
                
  String get skipOutro;

                                                          
     
                                           
                       
  String playlistDetailEpisodes(int count);

                                                       
     
                                           
                            
  String get playlistDetailEmpty;

                                                           
     
                                           
                       
  String playlistDetailEpisodeOf(int index);

                                                        
     
                                           
                             
  String playlistDetailResume(String position);

                                                         
     
                                           
               
  String get playlistDetailBgTitle;

                                                        
     
                                           
                  
  String get playlistDetailBgPick;

                                                          
     
                                           
                
  String get playlistDetailBgChange;

                                                          
     
                                           
                
  String get playlistDetailBgRemove;

                                                           
     
                                           
                    
  String get playlistDetailBgUpdated;

                                                           
     
                                           
                   
  String get playlistDetailBgRemoved;

                                                        
     
                                           
                        
  String playlistDetailBgFail(String error);

                                                      
     
                                           
                
  String get playlistFabRestart;

                                                    
     
                                           
                
  String get playlistMenuMore;

                                                      
     
                                           
                
  String get playlistMenuRename;

                                                           
     
                                           
              
  String get playlistMenuMultiSelect;

                                                       
     
                                           
              
  String get playlistMenuDanmaku;

                                                       
     
                                           
                   
  String get playlistRenameTitle;

                                                      
     
                                           
                    
  String get playlistRenameHint;

                                                       
     
                                           
                
  String get playlistRenameSaved;

                                                      
     
                                           
              
  String get playlistSelectDone;

                                                       
     
                                           
                  
  String get playlistSelectEmpty;

                                                        
     
                                           
                         
  String playlistSelectDelete(int count);

                                                         
     
                                           
                         
  String playlistSelectDeleted(int count);

                                                        
     
                                           
                  
  String get playlistDanmakuTitle;

                                                         
     
                                           
                                
  String get playlistDanmakuSsHint;

                                                            
     
                                           
                           
  String get playlistDanmakuFetchFail;

                                                              
     
                                           
                             
  String playlistDanmakuSelectTitle(int count);

                                                            
     
                                           
              
  String get playlistDanmakuSelectAll;

                                                         
     
                                           
                   
  String get playlistDanmakuImport;

                                                           
     
                                           
                            
  String playlistDanmakuAttached(int count);

                                                         
     
                                           
                                                 
  String playlistDanmakuExceed(int selected, int total);

                                                   
     
                                           
                  
  String get splitSelectChat;

                                                 
     
                                           
                 
  String get statusPending;

                                                   
     
                                           
               
  String get statusConnected;

                                                  
     
                                           
               
  String get statusRejected;

                                                      
     
                                           
               
  String get statusDisconnected;

                                             
     
                                           
              
  String get homeStart;

                                            
     
                                           
              
  String get homeDone;

                                            
     
                                           
                  
  String get homeBack;

                                                
     
                                           
                
  String get homeOverview;

                                                 
     
                                           
                
  String get homeLocalUser;

                                                    
     
                                           
                
  String get homeDefaultGroup;

                                                
     
                                           
               
  String get homeNewGroup;

                                                    
     
                                           
                   
  String get homeUnnamedGroup;

                                                        
     
                                           
                
  String get homeDeleteGroupTitle;

                                                          
     
                                           
                                  
  String get homeDeleteGroupMessage;

                                                     
     
                                           
                
  String get homeNewGroupTitle;

                                                     
     
                                           
                  
  String get homeGroupNameHint;

                                                        
     
                                           
                 
  String get homeRenameGroupTitle;

                                                        
     
                                           
                 
  String get homeNewGroupNameHint;

                                                  
     
                                           
                
  String get homeImageSlice;

                                                      
     
                                           
                      
  String tileSizeLabelSmall(String size);

                                                     
     
                                           
                      
  String tileSizeLabelWide(String size);

                                                      
     
                                           
                      
  String tileSizeLabelLarge(String size);

                                                
     
                                           
               
  String get homeGroupOne;

                                                
     
                                           
               
  String get homeGroupTwo;

                                                         
     
                                           
                 
  String get homeGroupProductivity;

                                                   
     
                                           
              
  String get homeGroupLegacy;

                                                   
     
                                           
                
  String get tileImageSlicer;

                                                      
     
                                           
                
  String get tileSystemSettings;

                                                
     
                                           
               
  String get tileDatabase;

                                                  
     
                                           
                   
  String get tileLcdDisplay;

                                                  
     
                                           
                  
  String get tileLedDynamic;

                                                 
     
                                           
                  
  String get tileLedStatic;

                                                 
     
                                           
                  
  String get tilePisScreen;

                                                    
     
                                           
                
  String get tileRoutePreview;

                                                             
     
                                           
                 
  String get tileStationEntranceDesign;

                                                             
     
                                           
                 
  String get tileStationEntrancePillar;

                                                               
     
                                           
                 
  String get tileStationEntranceSideName;

                                                        
     
                                           
                
  String get tilePlatformSideName;

                                                       
     
                                           
                 
  String get tileScreenDoorCover;

                                                       
     
                                           
               
  String get tileStationNameSign;

                                                   
     
                                           
                
  String get tileGeneralSign;

                                                  
     
                                           
                
  String get tileLineSymbol;

                                              
     
                                           
                  
  String get tileBusLcd;

                                                  
     
                                           
                    
  String get tileJsonEditor;

                                                  
     
                                           
                
  String get tileNamingRule;

                                                    
     
                                           
                
  String get tilePlatformText;

                                                     
     
                                           
                
  String get tileDepartureText;

                                                   
     
                                           
                
  String get tileArrivalText;

                                                                
     
                                           
                   
  String get tileOperationDirectionLegacy;

                                                        
     
                                           
                     
  String get tileLegacyLcdWarning;

                                                   
     
                                           
                
  String get tileLinearRoute;

                                                
     
                                           
              
  String get tileRoadSign;

                                                     
     
                                           
               
  String get commentPanelTitle;

                                                     
     
                                           
                       
  String commentTotalCount(int count);

                                                   
     
                                           
               
  String get commentSortHeat;

                                                   
     
                                           
               
  String get commentSortTime;

                                                  
     
                                           
                     
  String get commentLoading;

                                                   
     
                                           
                        
  String get commentLoadFail;

                                                       
     
                                           
                    
  String get commentLoadMoreFail;

                                                 
     
                                           
                   
  String get commentNoMore;

                                                      
     
                                           
                  
  String get commentLoadingMore;

                                                
     
                                           
                 
  String get commentEmpty;

                                                       
     
                                           
                
  String get commentViewDialogue;

                                                        
     
                                           
                
  String get commentDialogueTitle;

                                                   
     
                                           
                
  String get msgMenuSettings;

                                                       
     
                                           
                    
  String get msgSettingsLoadFail;

                                                       
     
                                           
                
  String get msgSettingsSaveFail;

                                                 
     
                                           
              
  String get commentPinned;

                                                  
     
                                           
                 
  String get commentDeleted;

                                                 
     
                                           
              
  String get commentExpand;

                                                   
     
                                           
              
  String get commentCollapse;

                                                              
     
                                           
                            
  String get commentTranslateNeedEnable;

                                                        
     
                                           
                  
  String get commentTranslateNone;

                                                
     
                                           
              
  String get commentReply;

                                                    
     
                                           
              
  String get commentTranslate;

                                                           
     
                                           
                
  String get commentTranslateRestore;

                                                      
     
                                           
              
  String get commentLikeTooltip;

                                                         
     
                                           
              
  String get commentDislikeTooltip;

                                                   
     
                                           
                         
  String commentSubCount(int count);

                                                      
     
                                           
                          
  String commentSubLoadMore(String hint);

                                                    
     
                                           
              
  String get commentYesterday;

                                                     
     
                                           
                  
  String get articleLoadFailed;

                                                    
     
                                           
                         
  String get articleNoContent;

                                                      
     
                                           
                 
  String get articleOpenBrowser;

                                                
     
                                           
              
  String get articleShare;

                                                        
     
                                           
                
  String get articleAuthorUnknown;

                                                        
     
                                           
                
  String get browserLinkPageTitle;

                                                
     
                                           
                      
  String articleViews(String count);

                                                      
     
                                           
                  
  String get contactPickerTitle;

                                                             
     
                                           
                
  String get contactPickerContentLabel;

                                                            
     
                                           
                    
  String get contactPickerContentHint;

                                                             
     
                                           
                  
  String get contactPickerContentEmpty;

                                                           
     
                                           
                 
  String get contactPickerSearchHint;

                                                      
     
                                           
                 
  String get contactPickerEmpty;

                                                        
     
                                           
                     
  String get contactPickerNoMatch;

                                                          
     
                                           
              
  String get contactPickerSelectAll;

                                                            
     
                                           
                            
  String contactPickerSendToCount(int count);

                                                     
     
                                           
                             
  String contactPickerSent(int count);

                                                             
     
                                           
                            
  String contactPickerNotConnected(String name);

                                                           
     
                                           
                        
  String contactPickerSendFailed(String error);

                                                       
     
                                           
              
  String get contactPickerOnline;

                                                        
     
                                           
              
  String get contactPickerOffline;

                                                         
     
                                           
                
  String get articleShareToContact;

                                                     
     
                                           
                
  String get playerDanmakuList;

                                                          
     
                                           
                              
  String playerDanmakuListCount(int count);

                                                          
     
                                           
                
  String get playerDanmakuListEmpty;

                                                            
     
                                           
                  
  String get playerDanmakuListNoMatch;

                                                               
     
                                           
                  
  String get playerDanmakuListSearchHint;

                                                                
     
                                           
                   
  String get playerDanmakuListJumpCurrent;

                                                   
     
                                           
                
  String get playerViewNotes;

                                                    
     
                                           
              
  String get playerNotesTitle;

                                                    
     
                                           
                       
  String playerNotesCount(int count);

                                                    
     
                                           
                     
  String get playerNotesEmpty;

                                                     
     
                                           
                 
  String get playerNotesNoMore;

                                                         
     
                                           
                  
  String get playerNotesLoadFailed;

                                                       
     
                                           
                
  String get playerNotesViewFull;

                                                   
     
                                           
               
  String get playerWriteNote;

                                                   
     
                                           
               
  String get noteEditorWrite;

                                                   
     
                                           
               
  String get noteEditorTitle;

                                                       
     
                                           
                  
  String get noteEditorTitleHint;

                                                         
     
                                           
                  
  String get noteEditorContentHint;

                                                   
     
                                           
              
  String get noteEditorEmoji;

                                                     
     
                                           
              
  String get noteEditorPublish;

                                                          
     
                                           
                    
  String get noteEditorEmptyContent;

                                                             
     
                                           
                           
  String get noteEditorContentTooShort;

                                                         
     
                                           
                                 
  String get noteEditorNotLoggedIn;

                                                       
     
                                           
                 
  String get noteEditorPublished;

                                                                 
     
                                           
                            
  String get noteEditorPublishNetworkError;

                                                             
     
                                           
                          
  String get noteEditorPublishRejected;

                                                        
     
                                           
                   
  String get noteEditorDraftSaved;

                                                          
     
                                           
                       
  String get noteEditorLoggedInHint;

                                                       
     
                                           
                            
  String get noteEditorGuestHint;

                                                     
     
                                           
                                 
  String noteEditorSavedAt(String hour, String minute);

                                                       
     
                                           
                     
  String noteEditorCharCount(int count);

                                                     
     
                                           
                
  String get noteEditorMyDraft;

                                                         
     
                                           
                
  String get noteEditorDeleteDraft;

                                                     
     
                                           
                
  String get playerMoreTooltip;

                                                          
     
                                           
                 
  String get commentComposerBarHint;

                                                       
     
                                           
                   
  String get commentComposerHint;

                                                            
     
                                           
                      
  String commentComposerReplyHint(String name);

                                                          
     
                                           
                      
  String commentComposerReplyTo(String name);

                                                        
     
                                           
              
  String get commentComposerEmote;

                                                       
     
                                           
              
  String get commentComposerSend;

                                                        
     
                                           
                    
  String get commentComposerEmpty;

                                                                   
     
                                           
                          
  String get commentComposerEmoteUnavailable;

                                                            
     
                                           
                
  String get commentComposerPickImage;

                                                       
     
                                           
              
  String get commentComposerMore;

                                                                
     
                                           
                
  String get commentComposerVideoProgress;

                                                                  
     
                                           
                
  String get commentComposerVideoScreenshot;

                                                             
     
                                           
                            
  String commentComposerImageLimit(int count);

                                                                
     
                                           
                       
  String get commentComposerCaptureFailed;

                                                               
     
                                           
                      
  String get commentComposerUploadFailed;

                                                           
     
                                           
               
  String get commentComposerFabLabel;

                                                           
     
                                           
               
  String get commentComposerFabReply;

                                                    
     
                                           
               
  String get danmakuSendTitle;

                                                        
     
                                           
              
  String get danmakuSendModeLabel;

                                                            
     
                                           
              
  String get danmakuSendFontSizeLabel;

                                                         
     
                                           
              
  String get danmakuSendColorLabel;

                                                        
     
                                           
             
  String get danmakuFontSizeSmall;

                                                           
     
                                           
              
  String get danmakuFontSizeStandard;

                                                        
     
                                           
             
  String get danmakuFontSizeLarge;

                                                          
     
                                           
                 
  String get danmakuSendCustomColor;

                                                      
     
                                           
              
  String get danmakuSendColorOk;

                                                                 
     
                                           
                       
  String get danmakuSendPreviewPlaceholder;

                                                 
     
                                           
                
  String get drawerHistory;

                                                    
     
                                           
                
  String get drawerWatchLater;

                                                 
     
                                           
                
  String get drawerMyCache;

                                                      
     
                                           
                
  String get historyCenterTitle;

                                                   
     
                                           
                
  String get historyTabWatch;

                                                  
     
                                           
                
  String get historyTabPlay;

                                                     
     
                                           
                   
  String get historySearchHint;

                                                       
     
                                           
                  
  String get historyPauseHistory;

                                                        
     
                                           
                  
  String get historyResumeHistory;

                                                    
     
                                           
                   
  String get historyPausedTip;

                                                          
     
                                           
                
  String get historyPausedTipAction;

                                                            
     
                                           
                  
  String get historyClearWatchHistory;

                                                           
     
                                           
                  
  String get historyClearPlayHistory;

                                                        
     
                                           
                
  String get historyClearAllTitle;

                                                          
     
                                           
                                    
  String historyClearAllConfirm(String label);

                                                         
     
                                           
                  
  String get historyNoWatchHistory;

                                                        
     
                                           
                  
  String get historyNoPlayHistory;

                                                         
     
                                           
                
  String get historyDeleteSelected;

                                                        
     
                                           
                        
  String historySelectedCount(int count);

                                                         
     
                                           
                 
  String get historySearchNoResult;

                                                       
     
                                           
                   
  String get historyPauseOnSnack;

                                                        
     
                                           
                   
  String get historyResumeOnSnack;

                                                      
     
                                           
                           
  String historyDeleteToast(int count);

                                                
     
                                           
                
  String get myCacheTitle;

                                                     
     
                                           
                     
  String get myCacheSearchHint;

                                                      
     
                                           
                
  String get myCacheDownloading;

                                                 
     
                                           
               
  String get myCacheCached;

                                                  
     
                                           
                  
  String get myCacheNoCache;

                                                     
     
                                           
                      
  String myCacheGroupCount(int count);

                                                      
     
                                           
                
  String get myCacheDeleteGroup;

                                                        
     
                                           
                
  String get myCacheUpdateDanmaku;

                                                        
     
                                           
                  
  String get myCacheClearAllTitle;

                                                          
     
                                           
                                                
  String myCacheClearAllConfirm(int count, String size);

                                                       
     
                                           
              
  String get cacheActionDownload;

                                                     
     
                                           
               
  String get cacheActionCached;

                                                      
     
                                           
               
  String get cacheActionCaching;

                                                     
     
                                           
                   
  String get cacheToastSuccess;

                                                    
     
                                           
                  
  String get cacheToastCached;

                                                    
     
                                           
                        
  String cacheToastFailed(String error);

                                                   
     
                                           
              
  String get drawerRecommend;

                                                      
     
                                           
                
  String get recommendSourceWeb;

                                                      
     
                                           
                
  String get recommendSourceApp;

                                                  
     
                                           
                  
  String get recommendEmpty;

                                                       
     
                                           
                 
  String get recommendSwitchList;

                                                       
     
                                           
                 
  String get recommendSwitchGrid;

                                                 
     
                                           
                 
  String get sideBarExpand;

                                                   
     
                                           
                 
  String get sideBarCollapse;

                                               
     
                                           
              
  String get sideBarMore;

                                                   
     
                                           
              
  String get recommendTabHot;

                                                       
     
                                           
              
  String get recommendTabBangumi;

                                                        
     
                                           
                  
  String get recommendSourceTitle;

                                                       
     
                                           
                
  String get settingsPreferences;

                                                          
     
                                           
                   
  String get settingsPreferencesSub;

                                                            
     
                                           
                 
  String get settingsPreferencesEmpty;

                                                        
     
                                           
                
  String get prefBottomBarSection;

                                                      
     
                                           
                    
  String get prefUseM3BottomBar;

                                                          
     
                                           
                                               
  String get prefUseM3BottomBarDesc;

                                                       
     
                                           
                  
  String get prefBottomBarSearch;

                                                           
     
                                           
                                                          
  String get prefBottomBarSearchDesc;

                                                     
     
                                           
                  
  String get prefWindowSection;

                                                  
     
                                           
                
  String get prefWindowSize;

                                                      
     
                                           
              
  String get prefRefreshSection;

                                                           
     
                                           
                  
  String get prefRefreshDisplacement;

                                                               
     
                                           
                         
  String get prefRefreshDisplacementDesc;

                                                         
     
                                           
                   
  String get prefRefreshEdgeOffset;

                                                             
     
                                           
                       
  String get prefRefreshEdgeOffsetDesc;

                                                         
     
                                           
                
  String get userSpaceFollowMutual;

                                                          
     
                                           
               
  String get userSpaceFollowBlocked;

                                                       
     
                                           
               
  String get userSpaceFollowDone;

                                                         
     
                                           
                 
  String get userSpaceUnfollowDone;

                                                       
     
                                           
                      
  String get userSpaceFollowFail;

                                                           
     
                                           
                   
  String get commonTapOutsideToClose;

                                                        
     
                                           
                
  String get prefFileAssocSection;

                                                        
     
                                           
                    
  String get prefFileAssocDefault;

                                                           
     
                                           
                                   
  String get prefFileAssocDefaultSub;

                                                  
     
                                           
                
  String get msgCenterTitle;

                                                     
     
                                           
                                  
  String get msgCenterSubtitle;

                                                        
     
                                           
                       
  String get msgCenterLoginPrompt;

                                              
     
                                           
                
  String get msgReplyMe;

                                           
     
                                           
               
  String get msgAtMe;

                                              
     
                                           
                
  String get msgLikedMe;

                                                
     
                                           
                
  String get msgSysNotice;

                                                
     
                                           
                
  String get msgMyWhisper;

                                                      
     
                                           
                       
  String get msgWhisperSubtitle;

                                                  
     
                                           
                       
  String msgUnreadCount(int count);

                                                  
     
                                           
              
  String get msgTimeJustNow;

                                                     
     
                                           
                       
  String msgTimeMinutesAgo(int count);

                                                    
     
                                           
                     
  String msgTimeYesterday(String time);

                                              
     
                                           
               
  String get msgGoLogin;

                                                          
     
                                           
                    
  String get msgDeleteNoticeConfirm;

                                              
     
                                           
               
  String get msgDeleted;

                                                         
     
                                           
                          
  String msgLoginPromptFeature(String title);

                                             
     
                                           
                 
  String get msgNoMore;

                                                 
     
                                           
                   
  String get msgReplyEmpty;

                                                   
     
                                           
                   
  String msgUserFallback(String mid);

                                           
     
                                           
               
  String get msgEtAl;

                                                 
     
                                           
                                        
  String msgReplyTitle(String business, int counts);

                                              
     
                                           
                    
  String get msgAtEmpty;

                                              
     
                                           
                              
  String msgAtTitle(String business);

                                                        
     
                                           
                  
  String get msgDeleteNoticeTitle;

                                                       
     
                                           
                               
  String get msgDeleteNoticeBody;

                                                 
     
                                           
                
  String get msgMuteNotice;

                                                     
     
                                           
                                   
  String get msgMuteNoticeBody;

                                                   
     
                                           
                
  String get msgSettingSaved;

                                                       
     
                                           
                       
  String get msgLoginPromptLikes;

                                                 
     
                                           
                   
  String get msgLikedEmpty;

                                                         
     
                                           
                           
  String get msgLikedEmptySubtitle;

                                                    
     
                                           
              
  String get msgSectionLatest;

                                                   
     
                                           
              
  String get msgSectionTotal;

                                              
     
                                           
              
  String get msgSomeone;

                                                
     
                                           
                              
  String msgEtAlCount(String name, int count);

                                               
     
                                           
                
  String get msgLikedYou;

                                                        
     
                                           
                           
  String msgLikedYourBusiness(String business);

                                                  
     
                                           
                 
  String get msgNoticeMuted;

                                                   
     
                                           
                
  String get msgUnmuteNotice;

                                                      
     
                                           
                
  String get msgLikeDetailTitle;

                                                      
     
                                           
                  
  String get msgLikeDetailEmpty;

                                               
     
                                           
                   
  String get msgSysEmpty;

                                                         
     
                                           
                 
  String get msgDeleteSessionTitle;

                                                        
     
                                           
                                      
  String get msgDeleteSessionBody;

                                               
     
                                           
                 
  String get msgUnpinned;

                                             
     
                                           
               
  String get msgPinned;

                                            
     
                                           
                
  String get msgUnpin;

                                          
     
                                           
                
  String get msgPin;

                                                    
     
                                           
                
  String get msgDeleteSession;

                                                         
     
                                           
                     
  String get msgLoginPromptWhisper;

                                                   
     
                                           
                   
  String get msgWhisperEmpty;

                                                           
     
                                           
                               
  String get msgWhisperEmptySubtitle;

                                                
     
                                           
                  
  String get msgNoMessage;

                                                      
     
                                           
                   
  String get msgWithdrawConfirm;

                                               
     
                                           
              
  String get msgWithdraw;

                                                
     
                                           
               
  String get msgWithdrawn;

                                                    
     
                                           
                    
  String get msgWithdrawnSelf;

                                                     
     
                                           
                     
  String get msgWithdrawnOther;

                                                
     
                                           
                   
  String get msgChatEmpty;

                                                        
     
                                           
                     
  String get msgChatEmptySubtitle;

                                                
     
                                           
                    
  String get msgNoEarlier;

                                                
     
                                           
                   
  String get msgInputHint;

                                              
     
                                           
                
  String get msgPicture;

                                                    
     
                                           
                    
  String get msgPictureFailed;

                                            
     
                                           
                  
  String get msgShare;

                                                      
     
                                           
                              
  String msgUnsupportedType(String type);

                                            
     
                                           
                
  String get msgVoice;

                                                
     
                                           
              
  String get msgCardVideo;

                                                  
     
                                           
              
  String get msgCardArticle;

                                               
     
                                           
              
  String get msgCardLive;

                                                  
     
                                           
              
  String get msgCardDynamic;

                                                
     
                                           
              
  String get msgCardAlbum;

                                                  
     
                                           
                 
  String get msgCardInvalid;

                                                     
     
                                           
                
  String get msgCardViewDetail;

                                                
     
                                           
                     
  String get msgAutoReply;

                                                     
     
                                           
                   
  String get msgUploadingImage;

                                                   
     
                                           
                
  String get msgChatSettings;

                                                  
     
                                           
                  
  String get msgPushReceive;

                                                      
     
                                           
                                                    
  String get msgPushReceiveDesc;

                                                       
     
                                           
                      
  String get msgPushCloseConfirm;

                                              
     
                                           
                
  String get msgPinChat;

                                               
     
                                           
                 
  String get msgChatMute;

                                               
     
                                           
                 
  String get msgBlockAdd;

                                                        
     
                                           
                   
  String get msgBlockConfirmTitle;

                                                       
     
                                           
                                                         
  String get msgBlockConfirmBody;

                                             
     
                                           
              
  String get msgReport;

                                                  
     
                                           
                     
  String msgReportTitle(String name);

                                                        
     
                                           
                        
  String get msgReportContentHint;

                                                       
     
                                           
                        
  String get msgReportReasonHint;

                                                           
     
                                           
                        
  String get msgReportReasonRequired;

                                                    
     
                                           
                
  String get msgReportSuccess;

                                                   
     
                                           
                
  String get msgReportFailed;

                                                         
     
                                           
                
  String get msgReportReasonAvatar;

                                                           
     
                                           
                
  String get msgReportReasonNickname;

                                                       
     
                                           
                
  String get msgReportReasonSign;

                                                       
     
                                           
                
  String get msgReportReasonPorn;

                                                        
     
                                           
                
  String get msgReportReasonFalse;

                                                            
     
                                           
              
  String get msgReportReasonForbidden;

                                                         
     
                                           
                
  String get msgReportReasonAttack;

                                                        
     
                                           
                
  String get msgReportReasonFraud;

                                                       
     
                                           
                  
  String get msgReportReasonLink;

                                              
     
                                           
              
  String get msgRefresh;

                                              
     
                                           
              
  String get commonSend;

                                               
     
                                           
              
  String get commonRetry;

                                                   
     
                                           
                
  String get msgInteractions;

                                               
     
                                           
                
  String get msgLoadMore;

                                                 
     
                                           
              
  String get dynamicsTitle;

                                                  
     
                                           
              
  String get dynamicsTabAll;

                                                    
     
                                           
              
  String get dynamicsTabVideo;

                                                  
     
                                           
              
  String get dynamicsTabPgc;

                                                      
     
                                           
              
  String get dynamicsTabArticle;

                                                 
     
                                           
                   
  String get dynamicsEmpty;

                                                       
     
                                           
                      
  String get dynamicsLoginPrompt;

                                                  
     
                                           
                   
  String get onnxDepSection;

                                               
     
                                           
                                                       
  String get onnxDepDesc;

                                                       
     
                                           
               
  String get onnxDepNotInstalled;

                                                       
     
                                           
                
  String get onnxDepSizeCounting;

                                                   
     
                                           
              
  String get onnxDepDownload;

                                                    
     
                                           
              
  String get onnxDepUninstall;

                                                         
     
                                           
                      
  String get onnxDepUninstallTitle;

                                                      
     
                                           
                      
  String get onnxDepUninstalled;

                                                      
     
                                           
                         
  String get onnxDepInstallDone;

                                                      
     
                                           
                        
  String get onnxDepUnsupported;

                                                      
     
                                           
               
  String get onnxDepSourceTitle;

                                                     
     
                                           
                             
  String get onnxDepSourceDesc;

                                                      
     
                                           
                                  
  String get onnxDepNeedInstall;

                                                      
     
                                           
                  
  String get onnxDepSourceSaved;

                                                    
     
                                           
                        
  String onnxDepInstalled(String size);

                                                      
     
                                           
                         
  String onnxDepDownloading(String percent);

                                                           
     
                                           
                                                    
  String onnxDepUninstallConfirm(String size);

                                                 
     
                                           
                        
  String onnxDepFailed(String error);

                                                      
     
                                           
                 
  String get favWidgetPickTitle;

                                                     
     
                                           
                              
  String get favWidgetPickHint;

                                                      
     
                                           
                       
  String get favWidgetNeedLogin;

                                                           
     
                                           
                        
  String favWidgetFolderSwitched(String name);

                                                 
     
                                           
                    
  String get ossSearchHint;

                                                  
     
                                           
              
  String get ossClearSearch;

                                                  
     
                                           
                 
  String get ossDepsSection;

                                              
     
                                           
                     
  String get ossLoading;

                                                 
     
                                           
                          
  String get ossLoadFailed;

                                                  
     
                                           
                     
  String get ossEmptySearch;

                                            
     
                                           
              
  String get ossRetry;

                                                    
     
                                           
                       
  String ossLicensesCount(int count);

                                                   
     
                                           
                                
  String ossLicenseIndex(int index, int total);

                                                    
     
                                           
                                             
  String ossPackagesCount(int total, int licenses);

                                                   
     
                                           
                
  String get userPickerTitle;

                                                        
     
                                           
                  
  String get userPickerSearchHint;

                                                   
     
                                           
                  
  String get userPickerEmpty;

                                                        
     
                                           
                
  String get userPickerLoadFailed;

                                                  
     
                                           
              
  String get userPickerDone;

                                               
     
                                           
               
  String get shortsTitle;

                                               
     
                                           
                  
  String get shortsEmpty;

                                              
     
                                           
                   
  String get ttsSection;

                                                 
     
                                           
                          
  String get ttsModelLabel;

                                           
     
                                           
                                                            
  String get ttsDesc;

                                                   
     
                                           
               
  String get ttsNotInstalled;

                                              
     
                                           
                          
  String get ttsPartial;

                                                   
     
                                           
                
  String get ttsSizeCounting;

                                               
     
                                           
              
  String get ttsDownload;

                                             
     
                                           
                
  String get ttsResume;

                                                
     
                                           
              
  String get ttsUninstall;

                                                     
     
                                           
                       
  String get ttsUninstallTitle;

                                                  
     
                                           
                       
  String get ttsUninstalled;

                                                  
     
                                           
                         
  String get ttsInstallDone;

                                                  
     
                                           
                         
  String get ttsUnsupported;

                                                  
     
                                           
               
  String get ttsSourceTitle;

                                                 
     
                                           
                                             
  String get ttsSourceDesc;

                                                  
     
                                           
                  
  String get ttsSourceSaved;

                                                     
     
                                           
                          
  String get ttsMirrorOfficial;

                                                  
     
                                           
                               
  String get ttsMirrorChina;

                                                   
     
                                           
                 
  String get ttsMirrorCustom;

                                                 
     
                                           
                         
  String get ttsEngineIdle;

                                                    
     
                                           
                     
  String get ttsEngineLoading;

                                                  
     
                                           
                 
  String get ttsEngineReady;

                                                   
     
                                           
                
  String get ttsEngineUnload;

                                                     
     
                                           
                           
  String get ttsEngineUnloaded;

                                                   
     
                                           
                
  String get ttsBackendTitle;

                                                  
     
                                           
              
  String get ttsBackendAuto;

                                                 
     
                                           
               
  String get ttsBackendNpu;

                                                 
     
                                           
               
  String get ttsBackendGpu;

                                                 
     
                                           
               
  String get ttsBackendCpu;

                                                      
     
                                           
                                 
  String get ttsBackendAutoDesc;

                                                     
     
                                           
                               
  String get ttsBackendNpuDesc;

                                                     
     
                                           
                               
  String get ttsBackendGpuDesc;

                                                     
     
                                           
                          
  String get ttsBackendCpuDesc;

                                                               
     
                                           
                                       
  String get ttsBackendNpuRuntimeMissing;

                                                                    
     
                                           
                                     
  String get ttsBackendNpuHardwareUnsupported;

                                                    
     
                                           
                          
  String ttsEngineReadyOn(String name);

                                                  
     
                                           
                                   
  String get ttsNeedInstall;

                                                     
     
                                           
                           
  String get ttsRuntimePending;

                                              
     
                                           
                    
  String get ttsVoTitle;

                                             
     
                                           
                                    
  String get ttsVoDesc;

                                              
     
                                           
                      
  String get ttsVoEmpty;

                                             
     
                                           
                
  String get ttsVoPick;

                                              
     
                                           
                 
  String get ttsVoAdded;

                                                    
     
                                           
                 
  String get ttsVoDeleteTitle;

                                                
     
                                           
                 
  String get ttsVoDeleted;

                                                
     
                                           
                
  String get ttsVoDefault;

                                            
     
                                           
              
  String get ttsVoUse;

                                                     
     
                                           
                  
  String get ttsPickAudioTitle;

                                                        
     
                                           
                     
  String get ttsVoUnsupportedFile;

                                                
     
                                           
                        
  String ttsInstalled(String size);

                                                  
     
                                           
                         
  String ttsDownloading(String percent);

                                                      
     
                                           
                                  
  String ttsDownloadingFile(String percent, String name);

                                                       
     
                                           
                                                  
  String ttsUninstallConfirm(String size);

                                             
     
                                           
                        
  String ttsFailed(String error);

                                                   
     
                                           
                          
  String ttsVoPickFailed(String error);

                                                      
     
                                           
                          
  String ttsVoDeleteConfirm(String name);

                                              
     
                                           
                           
  String ttsVoCount(String count);

                                                
     
                                           
              
  String get ttsReadAloud;

                                                    
     
                                           
                
  String get ttsReadAloudStop;

                                                   
     
                                           
                   
  String get ttsSynthesizing;

                                                  
     
                                           
                        
  String ttsSpeakFailed(String error);

                                                    
     
                                           
                               
  String ttsTruncatedHint(String count);

                                                       
     
                                           
               
  String get playerOnlyPlayAudio;

                                                           
     
                                           
                                 
  String get playerOnlyPlayAudioDesc;

                                                     
     
                                           
                         
  String videoBgmUsedCount(String count);

                                         
     
                                           
              
  String get comic;

                                              
     
                                           
                 
  String get memberShop;

                                             
     
                                           
               
  String get audioZone;

                                           
     
                                           
              
  String get opusTab;

                                             
     
                                           
                
  String get matchInfo;

                                             
     
                                           
               
  String get watchLive;

                                                   
     
                                           
                
  String get interestStation;

                                              
     
                                           
                
  String get noteManage;

                                                   
     
                                           
                 
  String get noteUnpublished;

                                                 
     
                                           
                
  String get notePublished;

                                                  
     
                                           
                
  String get deleteSelected;

                                                     
     
                                           
                        
  String get confirmDeleteNote;

                                            
     
                                           
                
  String get favTopic;

                                                  
     
                                           
                      
  String get cancelFavTopic;

                                                
     
                                           
                 
  String get inputIdTitle;

                                               
     
                                           
                          
  String get inputIdHint;

                                             
     
                                           
                
  String get noContent;

                                             
     
                                           
              
  String get bubbleAll;

                                          
     
                                           
              
  String get cancel;

                                           
     
                                           
               
  String get deleted;

                                                   
     
                                           
                
  String get operationFailed;

                                           
     
                                           
              
  String get confirm;

                                             
     
                                           
              
  String get selectAll;

                                              
     
                                           
                
  String get loadFailed;

                                                       
     
                                           
              
  String get videoMorePanelTitle;

                                                   
     
                                           
                
  String get memberLiteTitle;

                                                      
     
                                           
                  
  String get memberLiteViewFull;

                                                   
     
                                           
                
  String get memberLiteEmpty;

                                                  
     
                                           
               
  String get audioPageTitle;

                                                  
     
                                           
              
  String get audioPageSpeed;

                                                  
     
                                           
                
  String get audioPageRetry;

                                                    
     
                                           
               
  String get playerListenPage;

                                                             
     
                                           
                        
  String get playerOnlyPlayAudioInline;

                                                        
     
                                           
                         
  String memberLiteVideoCount(String count);

                                                     
     
                                           
                
  String get memberLiteGoSpace;

                                                         
     
                                           
                
  String get commentSortLatestDesc;

                                                          
     
                                           
                
  String get commentSortHottestDesc;

                                                          
     
                                           
              
  String get commentSortLatestShort;

                                                           
     
                                           
              
  String get commentSortHottestShort;

                                                          
     
                                           
                
  String get memberLiteOrderPubdate;

                                                        
     
                                           
                
  String get memberLiteOrderClick;

                                                       
     
                                           
                
  String get videoMenuWatchLater;

                                                   
     
                                           
                
  String get videoMenuReload;

                                                   
     
                                           
                
  String get playerMenuStats;

                                                        
     
                                           
              
  String get playerMenuScreenshot;

                                                       
     
                                           
                
  String get playerMenuAudioNorm;

                                                         
     
                                           
                  
  String get playerMenuAudioDevice;

                                                    
     
                                           
              
  String get playerMenuSource;

                                                         
     
                                           
                
  String get playerMenuEndBehavior;

                                                  
     
                                           
                  
  String get screenshotCopy;

                                                    
     
                                           
                   
  String get screenshotCopied;

                                                             
     
                                           
                           
  String get screenshotCopyUnsupported;

                                              
     
                                           
              
  String get commonCopy;

                                                       
     
                                           
                  
  String get subtitleDownloadAll;

                                                           
     
                                           
                    
  String get subtitleDownloadPickDir;

                                                        
     
                                           
                        
  String get subtitleDownloadNone;

                                                             
     
                                           
                  
  String get subtitleDownloadAllFailed;

                                                        
     
                                           
                                  
  String subtitleDownloadDone(String count, String dir);

                                                   
     
                                           
              
  String get prefPerfSection;

                                                      
     
                                           
                
  String get prefEfficiencyMode;

                                                         
     
                                           
                                                
  String get prefEfficiencyModeSub;

                                                                 
     
                                           
                       
  String get prefEfficiencyModeUnsupported;

                                                             
     
                                           
                
  String get prefEfficiencyModeReading;

                                                            
     
                                           
                           
  String get prefEfficiencyModeActive;

                                                              
     
                                           
               
  String get prefEfficiencyModeInactive;

                                                            
     
                                           
                              
  String prefEfficiencyModeFailed(String detail);

                                              
     
                                           
                
  String get sleepTimer;

                                                    
     
                                           
                
  String get sleepTimerCustom;

                                                              
     
                                           
                   
  String get sleepTimerStopAfterCurrent;

                                                                   
     
                                           
                
  String get sleepTimerStopAfterCurrentShort;

                                                    
     
                                           
                  
  String get sleepTimerCancel;

                                                        
     
                                           
                   
  String get sleepTimerArmedToast;

                                                            
     
                                           
                   
  String get sleepTimerCancelledToast;

                                                                        
     
                                           
                      
  String get sleepTimerStopAfterCurrentArmedToast;

                                                               
     
                                           
                   
  String get sleepTimerCustomDialogTitle;

                                                        
     
                                           
               
  String get sleepTimerCustomHint;

                                                        
     
                                           
              
  String get sleepTimerCustomUnit;

                                                           
     
                                           
                     
  String get sleepTimerInvalidNumber;

                                                             
     
                                           
                     
  String get settingsSleepTimerExitApp;

                                                                 
     
                                           
                                      
  String get settingsSleepTimerExitAppDesc;

                                                     
     
                                           
                    
  String sleepTimerMinutes(int min);

                                                       
     
                                           
                
  String get playlistReversePlay;

                                                         
     
                                           
                   
  String get playlistReversePlayOn;

                                                          
     
                                           
                   
  String get playlistReversePlayOff;

                                                           
     
                                           
                
  String get msgSettingsNotifSection;

                                                          
     
                                           
                    
  String get msgSettingsReplyNotify;

                                                              
     
                                           
                        
  String get msgSettingsReplyNotifyDesc;

                                                       
     
                                           
                   
  String get msgSettingsAtNotify;

                                                           
     
                                           
                       
  String get msgSettingsAtNotifyDesc;

                                                         
     
                                           
                  
  String get msgSettingsLikeNotify;

                                                             
     
                                           
                       
  String get msgSettingsLikeNotifyDesc;

                                                             
     
                                           
               
  String get msgSettingsNotifyEveryone;

                                                              
     
                                           
                
  String get msgSettingsNotifyFollowing;

                                                         
     
                                           
                     
  String get msgSettingsNotifyNone;

                                                             
     
                                           
                
  String get msgSettingsReceiveSection;

                                                              
     
                                           
                    
  String get msgSettingsReceiveUnfollow;

                                                                  
     
                                           
                                             
  String get msgSettingsReceiveUnfollowDesc;

                                                           
     
                                           
                    
  String get msgSettingsUnfollowFold;

                                                               
     
                                           
                          
  String get msgSettingsUnfollowFoldDesc;

                                                           
     
                                           
                   
  String get msgSettingsGroupReceive;

                                                        
     
                                           
                   
  String get msgSettingsGroupFold;

                                                             
     
                                           
                  
  String get msgSettingsSmartIntercept;

                                                                 
     
                                           
                                                
  String get msgSettingsSmartInterceptDesc;

                                                                    
     
                                           
               
  String get msgSettingsAntiHarassmentSection;

                                                             
     
                                           
                 
  String get msgSettingsAntiHarassment;

                                                          
     
                                           
                     
  String get msgSettingsScopeSelect;

                                                         
     
                                           
                            
  String msgSettingsValidUntil(String time);

                                                              
     
                                           
                                                       
  String get prefEfficiencyModeAutoDesc;
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
