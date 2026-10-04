                                     
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:window_manager/window_manager.dart';
import 'package:naviflash/services/onnx_dependency_service.dart';
import 'package:naviflash/services/native_menu_service.dart';
import 'package:naviflash/services/storage_paths.dart';
import 'package:naviflash/services/tts_backend_policy.dart';
import 'package:naviflash/services/tts_model_service.dart';
import 'package:naviflash/services/ugc_filter_service.dart';
import 'package:naviflash/services/windows_power_service.dart';
import 'package:naviflash/services/sleep_timer_service.dart';
import 'package:naviflash/services/efficiency_mode_automation.dart';
import 'package:naviflash/utils/recommend_filter.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

                                            
                                                             
enum BrowserUaMode {
                                   
  auto('auto'),

                   
  desktop('desktop'),

                   
  mobile('mobile');

  const BrowserUaMode(this.code);

  final String code;

  static BrowserUaMode fromCode(String? code) => BrowserUaMode.values
      .firstWhere((m) => m.code == code, orElse: () => BrowserUaMode.auto);
}

                                 
enum BiliRecommendSource {
                                                               
  web('web'),

                                                         
  app('app');

  const BiliRecommendSource(this.code);

  final String code;

  static BiliRecommendSource fromCode(String? code) =>
      BiliRecommendSource.values
          .firstWhere((s) => s.code == code, orElse: () => BiliRecommendSource.web);
}

class SettingsService extends ChangeNotifier {
  Color _themeSeedColor = Colors.blue;

                                                
                                               
  FlexSchemeVariant _schemeVariant = FlexSchemeVariant.tonalSpot;
  bool _restrictIP = false;
  String? _nickname;
  String? _avatarPath;
  ThemeMode _themeMode = ThemeMode.system;
  double _fontWeight = 400.0;
  bool _isPureBlackMode = false;
  bool _useDynamicColor = true;
  bool _enableFragmentRendering = true;
  bool _disableLiquidGlassMenus = false;
  List<Map<String, dynamic>> _customThemes = [];
  String? _lockScreenWallpaperPath;
  bool _lockScreenFollowThemeColor = false;
  bool _lockScreenShowBattery = true;
  bool _lockScreenShowNetwork = true;
  double _windowWidth = 1024.0;
  double _windowHeight = 768.0;
  String? _backgroundImagePath;
  double _backgroundImageSize = 300.0;
  double _backgroundImageOpacity = 1.0;
  bool _isLocked = false;

                       
  double _playerDefaultRate = 1.0;
  String _playerEndBehavior = 'pause';                     
  bool _showPlayerStats = false;
  bool _autoPiPOnBackground = false;

                               
  bool _sleepTimerExitApp = false;

                                          
  bool _playlistReversePlay = false;

                            
  bool _autoOfflineCache = true;

                                               
                               
  String _onnxDepBaseUrl = '';

                      
                                                    
                                     
                                     
  String _autoCachePath = '';
  String _videoDownloadPath = '';
  String _modelDownloadPath = '';

                                        
                                             
  int _ttsMirror = TtsMirror.hfMirror.index;

                                         
  String _ttsCustomUrl = '';

                                                          
                                            
  int _ttsInferenceDevice = TtsInferenceDevicePreference.auto.index;

                                      
                                  
  int _favWidgetFolderId = 0;

                                             
  static int favWidgetFolderIdStatic = 0;

                                            
  static Future<void> setFavWidgetFolderIdGlobal(int value) async {
    favWidgetFolderIdStatic = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('favWidgetFolderId', value);
  }

                                              
  static String onnxDepBaseUrlStatic = '';

                                           
  static TtsMirror ttsMirrorStatic = TtsMirror.hfMirror;
  static String ttsCustomUrlStatic = '';

                                               
  static TtsInferenceDevicePreference ttsInferenceDeviceStatic =
      TtsInferenceDevicePreference.auto;

                                                
  static Future<void> setTtsInferenceDeviceGlobal(
    TtsInferenceDevicePreference value,
  ) async {
    ttsInferenceDeviceStatic = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ttsInferenceDevice', value.index);
  }

                                               
  static Future<void> applyTtsMirrorGlobal(
    TtsMirror mirror,
    String customUrl,
  ) async {
    ttsMirrorStatic = mirror;
    ttsCustomUrlStatic = customUrl.trim();
    TtsModelService.applyMirror(mirror, customUrl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ttsMirror', mirror.index);
    await prefs.setString('ttsCustomUrl', customUrl.trim());
  }

                                            
                      
  static Future<void> setAutoCachePathGlobal(String value) async {
    final v = value.trim();
    StoragePaths.autoCachePath = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('autoCachePath', v);
  }

                                            
  static Future<void> setVideoDownloadPathGlobal(String value) async {
    final v = value.trim();
    StoragePaths.videoPath = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('videoDownloadPath', v);
  }

                                             
  static Future<void> setModelDownloadPathGlobal(String value) async {
    final v = value.trim();
    StoragePaths.modelsPath = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('modelDownloadPath', v);
  }

                                                             
  static Future<void> setOnnxDepBaseUrlGlobal(String value) async {
    final v = value.trim();
    onnxDepBaseUrlStatic = v;
    OnnxDependencyService.customBaseUrl = v.isEmpty ? null : v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onnxDepBaseUrl', v);
  }

                   
  List<String> _tileOrder = [];

                     
  List<Map<String, dynamic>> _imageSlices = [];

                 
  String? _drawerBackgroundPath;
  bool _hideWebDavInfo = false;
               
  double _displayScale = 1.0;

                        
  bool _enableStartScreen = true;
  bool _enableCharm = true;
  bool _enableCharmGesture = true;
  bool _startScreenWarningDismissed = false;

                                   
  bool _incognitoMode = false;

                                             
                              
  bool _useM3BottomBar = false;

                                    
                                              
  bool _bottomBarSearch = true;

                                         
                                               
  List<String> _bottomNavOrder = List.of(kDefaultBottomNavOrder);
  static const List<String> kDefaultBottomNavOrder = [
    'home',
    'shorts',
    'dynamics',
    'mine',
  ];

                                                
                                 
  static const List<String> kAllBottomNavIds = [
    'home',
    'shorts',
    'dynamics',
    'messages',
    'mine',
  ];

                                           
                                                  
                                       
  bool _disableNativeMenu = false;

                           
                                    
  bool _searchTrendingEnabled = true;
  bool _searchRcmdEnabled = true;

                                                      
                                         
                        
  bool _enableCommAntifraud = false;

                                  
                                           
                              
  double _refreshDisplacement = 40.0;
  double _refreshEdgeOffset = 0.0;

                                    
                                                    
                                                
                                                    
  double _springMass = 1.0;
  double _springStiffness = 438.64908449286037;
  double _springDamping = 41.88790204786391;

                       
                                                   
                                      
                                           
  bool _toastUseFluttertoast = false;
  Color _toastBgColor = const Color(0xFF323232);
  double _toastBgOpacity = 0.8;
  bool _toastBgBlur = false;

                                                                     
  String? _displayMode;

                                            
                                     
  bool _fileAssociationDefault = false;

                                       
                                       
                                                
  bool _efficiencyMode = false;

                                         
  String? _appLocaleCode;

                                      
  bool _browserAllowClipboard = true;

                                       
  BrowserUaMode _browserUaMode = BrowserUaMode.auto;

                                          
  BiliRecommendSource _recommendSource = BiliRecommendSource.web;

                                             
  bool _heroTransitionBlur = true;

                                        
                                          
  bool _iosPushTransition = true;
  double _iosPushTransitionCornerRadius = 26.0;

                                     
  bool _iosPushTransitionCornerAuto = true;

                                                 
                                 
  bool _enableSaveLastData = true;

                                  
  bool _savedRcmdTip = true;

                         
  int _minLikeRatioForRecommend = 0;

                      
  int _minDurationForRcmd = 0;

                     
  int _minPlayForRcmd = 0;

                                                      
                                                            
                    
  bool _exemptFilterForFollowed = true;

                     
  bool _applyFilterToRelatedVideos = true;

                                                            
  bool _recommendGuestMode = false;

                                          
                                  
  String? _pageBackgroundPath;
  bool _pageBackgroundEnabled = false;
  double _pageBackgroundOpacity = 0.25;
  double _pageBackgroundBlur = 4.0;

                                     
                                      
  String? _contentPageBackgroundPath;
  bool _contentPageBackgroundEnabled = false;
  double _contentPageBackgroundOpacity = 0.18;
  double _contentPageBackgroundBlur = 3.0;

                                     
  bool _videoCardGlass = false;
  bool _chatGlass = true;

                                                
                    
                                         
                                               
  bool _liquidGlassMenuJelly = true;
  bool _liquidGlassBottomBarJelly = true;
  double _liquidGlassThickness = 20.0;
  double _liquidGlassBlur = 10.0;
  double _liquidGlassTintOpacity = 0.0;
  double _liquidGlassSaturation = 1.0;
  double _liquidGlassRefractiveIndex = 1.3;
  double _liquidGlassLightIntensity = 0.0;
  double _liquidGlassAmbientStrength = 0.0;
  double _liquidGlassLightAngle = math.pi / 2;
  double _liquidGlassChromaticAberration = 0.02;

                                     
                                        
                                           
  static bool searchTrendingEnabledStatic = true;
  static bool searchRcmdEnabledStatic = true;

                                                          
                                                    
  static bool commAntifraudEnabledStatic = false;

                                                         
  static bool heroTransitionBlurEnabled = true;

                                                      
                                 
  static bool fragmentRenderingEnabled = true;

                                                       
                                                 
                                                                       
                                                             
  static bool rcmdKeepLastData = true;
  static bool rcmdSavedPositionTip = true;
  static int rcmdMinLikeRatio = 0;
  static int rcmdMinDuration = 0;
  static int rcmdMinPlay = 0;
  static String rcmdBanWord = '';
  static String rcmdBanZone = '';
  static bool rcmdExemptFollowed = true;
  static bool rcmdFilterRelatedVideos = true;

                                        
                                                           
                                                 
  static bool rcmdGuestMode = false;

                                               
                                 
  static bool liquidGlassMenusDisabled = false;

                                                            
                                  
  static bool liquidGlassMenuJellyEnabled = true;

                                                    
                              
static bool liquidGlassBottomBarJellyEnabled = true;

                                                 
                          
static bool contentPageBackgroundEnabledValue = false;
static double contentPageBackgroundOpacityValue = 0.18;
static double contentPageBackgroundBlurValue = 3.0;
static bool videoCardGlassEnabled = false;

                                    
static bool chatGlassEnabled = true;

                                        
                       
  static bool autoOfflineCacheEnabled = true;

                                                      
                                       
  static double liquidGlassThickness = 20.0;
  static double liquidGlassBlur = 10.0;
  static double liquidGlassTintOpacity = 0.0;
  static double liquidGlassSaturation = 1.0;
  static double liquidGlassRefractiveIndex = 1.3;
  static double liquidGlassLightIntensity = 0.0;
  static double liquidGlassAmbientStrength = 0.0;
  static double liquidGlassLightAngle = math.pi / 2;
  static double liquidGlassChromaticAberration = 0.02;

                                                  
                                                              
  static SpringDescription naviSpringDescription = SpringDescription(
    mass: 1.0,
    stiffness: 438.64908449286037,
    damping: 41.88790204786391,
  );

                                                             
                                                          
  static bool toastUseFluttertoastEnabled = false;
  static Color toastBgColorValue = const Color(0xFF323232);
  static double toastBgOpacityValue = 0.8;
  static bool toastBgBlurEnabled = false;

  bool get hideWebDavInfo => _hideWebDavInfo;
  Color get themeSeedColor => _themeSeedColor;

                                       
  FlexSchemeVariant get schemeVariant => _schemeVariant;
  bool get restrictIP => _restrictIP;
  String? get nickname => _nickname;
  String? get avatarPath => _avatarPath;
  ThemeMode get themeMode => _themeMode;
  double get fontWeight => _fontWeight;
  bool get isPureBlackMode => _isPureBlackMode;
  bool get useDynamicColor => _useDynamicColor;
  bool get enableFragmentRendering => _enableFragmentRendering;
  bool get disableLiquidGlassMenus => _disableLiquidGlassMenus;
  String? get lockScreenWallpaperPath => _lockScreenWallpaperPath;
  bool get lockScreenFollowThemeColor => _lockScreenFollowThemeColor;
  bool get lockScreenShowBattery => _lockScreenShowBattery;
  bool get lockScreenShowNetwork => _lockScreenShowNetwork;
  List<Map<String, dynamic>> get customThemes => _customThemes;
  double get windowWidth => _windowWidth;
  double get windowHeight => _windowHeight;
  String? get backgroundImagePath => _backgroundImagePath;
  double get backgroundImageSize => _backgroundImageSize;
  double get backgroundImageOpacity => _backgroundImageOpacity;
  bool get isLocked => _isLocked;

              
  bool get enableStartScreen => _enableStartScreen;
  bool get enableCharm => _enableCharm;
  bool get enableCharmGesture => _enableCharmGesture;
  bool get startScreenWarningDismissed => _startScreenWarningDismissed;
  String? get displayMode => _displayMode;
  bool get browserAllowClipboard => _browserAllowClipboard;
  BrowserUaMode get browserUaMode => _browserUaMode;
  BiliRecommendSource get recommendSource => _recommendSource;
  bool get heroTransitionBlur => _heroTransitionBlur;
  bool get iosPushTransition => _iosPushTransition;
  double get iosPushTransitionCornerRadius => _iosPushTransitionCornerRadius;
  bool get iosPushTransitionCornerAuto => _iosPushTransitionCornerAuto;

                 
  bool get enableSaveLastData => _enableSaveLastData;
  bool get savedRcmdTip => _savedRcmdTip;
  int get minLikeRatioForRecommend => _minLikeRatioForRecommend;
  int get minDurationForRcmd => _minDurationForRcmd;
  int get minPlayForRcmd => _minPlayForRcmd;
                                     
                                                
  String get banWordForRecommend =>
      UgcFilterService.instance.patternOf(UgcFilterScope.recommend);

                          
  String get banWordForZone =>
      UgcFilterService.instance.patternOf(UgcFilterScope.zone);
  bool get exemptFilterForFollowed => _exemptFilterForFollowed;
  bool get applyFilterToRelatedVideos => _applyFilterToRelatedVideos;

                
  bool get useM3BottomBar => _useM3BottomBar;
  bool get bottomBarSearch => _bottomBarSearch;

                                               
  bool get disableNativeMenu => _disableNativeMenu;

                                  
  List<String> get bottomNavOrder => List.unmodifiable(_bottomNavOrder);

                      
  bool get searchTrendingEnabled => _searchTrendingEnabled;
  bool get searchRcmdEnabled => _searchRcmdEnabled;

            
  bool get enableCommAntifraud => _enableCommAntifraud;

  double get refreshDisplacement => _refreshDisplacement;
  double get refreshEdgeOffset => _refreshEdgeOffset;

                                 
  double get springMass => _springMass;
  double get springStiffness => _springStiffness;
  double get springDamping => _springDamping;

                    
  bool get toastUseFluttertoast => _toastUseFluttertoast;
  Color get toastBgColor => _toastBgColor;
  double get toastBgOpacity => _toastBgOpacity;
  bool get toastBgBlur => _toastBgBlur;

                                          
  bool get fileAssociationDefault => _fileAssociationDefault;

                                               
                                                     
  bool get efficiencyMode => _efficiencyMode;

                    
                                                                       
  String? get appLocaleCode => _appLocaleCode;

                                           
                                   
  Locale? get appLocale {
    final code = _appLocaleCode;
    if (code == null) return null;
    final parts = code.split('-');
    if (parts.length < 2) return Locale(parts[0]);
    return Locale(parts[0], parts[1]);
  }

                   
  String? get pageBackgroundPath => _pageBackgroundPath;
  bool get pageBackgroundEnabled => _pageBackgroundEnabled;
  double get pageBackgroundOpacity => _pageBackgroundOpacity;
  double get pageBackgroundBlur => _pageBackgroundBlur;

                             
  String? get contentPageBackgroundPath => _contentPageBackgroundPath;
  bool get contentPageBackgroundEnabled => _contentPageBackgroundEnabled;
  double get contentPageBackgroundOpacity => _contentPageBackgroundOpacity;
  double get contentPageBackgroundBlur => _contentPageBackgroundBlur;
  bool get videoCardGlass => _videoCardGlass;
  bool get chatGlass => _chatGlass;

                
  bool get liquidGlassMenuJelly => _liquidGlassMenuJelly;
  bool get liquidGlassBottomBarJelly => _liquidGlassBottomBarJelly;

                  
  double get liquidGlassThicknessValue => _liquidGlassThickness;
  double get liquidGlassBlurValue => _liquidGlassBlur;
  double get liquidGlassTintOpacityValue => _liquidGlassTintOpacity;
  double get liquidGlassSaturationValue => _liquidGlassSaturation;
  double get liquidGlassRefractiveIndexValue => _liquidGlassRefractiveIndex;
  double get liquidGlassLightIntensityValue => _liquidGlassLightIntensity;
  double get liquidGlassAmbientStrengthValue => _liquidGlassAmbientStrength;
  double get liquidGlassLightAngleValue => _liquidGlassLightAngle;
  double get liquidGlassChromaticAberrationValue =>
      _liquidGlassChromaticAberration;

                 
  double get playerDefaultRate => _playerDefaultRate;
  String get playerEndBehavior => _playerEndBehavior;
  bool get showPlayerStats => _showPlayerStats;
  bool get autoPiPOnBackground => _autoPiPOnBackground;
  bool get sleepTimerExitApp => _sleepTimerExitApp;
  bool get playlistReversePlay => _playlistReversePlay;
  bool get autoOfflineCache => _autoOfflineCache;
  int get favWidgetFolderId => _favWidgetFolderId;
  String get onnxDepBaseUrl => _onnxDepBaseUrl;

                           
  String get autoCachePath => _autoCachePath;

                           
  String get videoDownloadPath => _videoDownloadPath;

                          
  String get modelDownloadPath => _modelDownloadPath;
  TtsMirror get ttsMirror => TtsMirror.values[_ttsMirror.clamp(
        0,
        TtsMirror.values.length - 1,
      )];
  String get ttsCustomUrl => _ttsCustomUrl;
  TtsInferenceDevicePreference get ttsInferenceDevice =>
      TtsInferenceDevicePreference.values[_ttsInferenceDevice.clamp(
        0,
        TtsInferenceDevicePreference.values.length - 1,
      )];
  List<String> get tileOrder => _tileOrder;
  List<Map<String, dynamic>> get imageSlices => _imageSlices;
  String? get drawerBackgroundPath => _drawerBackgroundPath;
  double get displayScale => _displayScale;

  SettingsService();

  Future<void> initialize() async {
                                                   
    await UgcFilterService.instance.initialize(force: true);
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeSeedColor = Color(
      prefs.getInt('themeSeedColor') ?? Colors.blue.toARGB32(),
    );

                                          
    final variantIndex = prefs.getInt('schemeVariant') ??
        FlexSchemeVariant.tonalSpot.index;
    _schemeVariant =
        variantIndex >= 0 && variantIndex < FlexSchemeVariant.values.length
            ? FlexSchemeVariant.values[variantIndex]
            : FlexSchemeVariant.tonalSpot;

    _restrictIP = prefs.getBool('restrictIP') ?? false;
    _nickname = prefs.getString('nickname');
    _avatarPath = prefs.getString('avatarPath');
    _fontWeight = prefs.getDouble('fontWeight') ?? 400.0;
    _isPureBlackMode = prefs.getBool('isPureBlackMode') ?? false;
    _useDynamicColor = prefs.getBool('useDynamicColor') ?? false;
    _enableFragmentRendering = prefs.getBool('enableFragmentRendering') ?? true;
    fragmentRenderingEnabled = _enableFragmentRendering;
    _disableLiquidGlassMenus =
        prefs.getBool('disableLiquidGlassMenus') ?? false;
    liquidGlassMenusDisabled = _disableLiquidGlassMenus;
    _lockScreenWallpaperPath = prefs.getString('lockScreenWallpaperPath');
    _lockScreenFollowThemeColor =
        prefs.getBool('lockScreenFollowThemeColor') ?? false;
    _lockScreenShowBattery = prefs.getBool('lockScreenShowBattery') ?? true;
    _lockScreenShowNetwork = prefs.getBool('lockScreenShowNetwork') ?? true;
    _windowWidth = prefs.getDouble('windowWidth') ?? 1024.0;
    _windowHeight = prefs.getDouble('windowHeight') ?? 768.0;
    _backgroundImagePath = prefs.getString('backgroundImagePath');
    _backgroundImageSize = prefs.getDouble('backgroundImageSize') ?? 300.0;
    _backgroundImageOpacity = prefs.getDouble('backgroundImageOpacity') ?? 1.0;
    _isLocked = prefs.getBool('isLocked') ?? false;
    _hideWebDavInfo = prefs.getBool('hideWebDavInfo') ?? false;

                 
    _playerDefaultRate = prefs.getDouble('playerDefaultRate') ?? 1.0;
    _playerEndBehavior = prefs.getString('playerEndBehavior') ?? 'pause';
    _showPlayerStats = prefs.getBool('showPlayerStats') ?? false;
    _autoPiPOnBackground = prefs.getBool('autoPiPOnBackground') ?? false;
                                               
    _sleepTimerExitApp = prefs.getBool('sleepTimerExitApp') ?? false;
    SleepTimerService.instance.exitAppOnEnd = _sleepTimerExitApp;
              
    _playlistReversePlay = prefs.getBool('playlistReversePlay') ?? false;

                                           
    _autoOfflineCache = prefs.getBool('autoOfflineCache') ?? true;
    autoOfflineCacheEnabled = _autoOfflineCache;

                                                       
    _favWidgetFolderId = prefs.getInt('favWidgetFolderId') ?? 0;
    favWidgetFolderIdStatic = _favWidgetFolderId;

                                                            
    _onnxDepBaseUrl = prefs.getString('onnxDepBaseUrl') ?? '';
    onnxDepBaseUrlStatic = _onnxDepBaseUrl;
    OnnxDependencyService.customBaseUrl =
        _onnxDepBaseUrl.trim().isEmpty ? null : _onnxDepBaseUrl.trim();

                                           
    _autoCachePath = prefs.getString('autoCachePath') ?? '';
    _videoDownloadPath = prefs.getString('videoDownloadPath') ?? '';
    _modelDownloadPath = prefs.getString('modelDownloadPath') ?? '';
    StoragePaths.applyFromPrefs(
      autoCache: _autoCachePath,
      video: _videoDownloadPath,
      models: _modelDownloadPath,
    );

                   
    _ttsMirror = prefs.getInt('ttsMirror') ?? TtsMirror.hfMirror.index;
    _ttsCustomUrl = prefs.getString('ttsCustomUrl') ?? '';
    ttsMirrorStatic = ttsMirror;
    ttsCustomUrlStatic = _ttsCustomUrl;
    TtsModelService.applyMirror(ttsMirror, _ttsCustomUrl);

                  
    _ttsInferenceDevice = prefs.getInt('ttsInferenceDevice') ??
        TtsInferenceDevicePreference.auto.index;
    ttsInferenceDeviceStatic = ttsInferenceDevice;

               
    _tileOrder = prefs.getStringList('tileOrder') ?? [];

                 
    _drawerBackgroundPath = prefs.getString('drawerBackgroundPath');

               
    _displayScale = prefs.getDouble('displayScale') ?? 1.0;

                     
    _enableStartScreen = prefs.getBool('enableStartScreen') ?? true;
    _enableCharm = prefs.getBool('enableCharm') ?? true;
    _enableCharmGesture = prefs.getBool('enableCharmGesture') ?? true;
    _startScreenWarningDismissed =
        prefs.getBool('startScreenWarningDismissed') ?? false;

            
    _displayMode = prefs.getString('displayMode');

                                         
    _appLocaleCode = _normalizeLocaleCode(prefs.getString('appLocaleCode'));

                  
    _browserAllowClipboard = prefs.getBool('browserAllowClipboard') ?? true;

                 
    _browserUaMode = BrowserUaMode.fromCode(prefs.getString('browserUaMode'));

                
    _recommendSource = BiliRecommendSource.fromCode(
      prefs.getString('recommendSource'),
    );

                    
    _heroTransitionBlur = prefs.getBool('heroTransitionBlur') ?? true;
    heroTransitionBlurEnabled = _heroTransitionBlur;

                         
    _iosPushTransition = prefs.getBool('iosPushTransition') ?? true;
    _iosPushTransitionCornerRadius =
        prefs.getDouble('iosPushTransitionCornerRadius') ?? 26.0;
    _iosPushTransitionCornerAuto =
        prefs.getBool('iosPushTransitionCornerAuto') ?? true;

                           
    _enableSaveLastData = prefs.getBool('enableSaveLastData') ?? true;
    _savedRcmdTip = prefs.getBool('savedRcmdTip') ?? true;
    _minLikeRatioForRecommend =
        prefs.getInt('minLikeRatioForRecommend') ?? 0;
    _minDurationForRcmd = prefs.getInt('minDurationForRcmd') ?? 0;
    _minPlayForRcmd = prefs.getInt('minPlayForRcmd') ?? 0;
    _exemptFilterForFollowed =
        prefs.getBool('exemptFilterForFollowed') ?? true;
    _applyFilterToRelatedVideos =
        prefs.getBool('applyFilterToRelatedVideos') ?? true;
                                
    _recommendGuestMode = prefs.getBool('recommendGuestMode') ?? false;
    rcmdGuestMode = _recommendGuestMode;
    _syncRecommendFilter();

             
    _pageBackgroundPath = prefs.getString('pageBackgroundPath');
    _pageBackgroundEnabled = prefs.getBool('pageBackgroundEnabled') ?? false;
    _pageBackgroundOpacity =
        prefs.getDouble('pageBackgroundOpacity') ?? 0.25;
    _pageBackgroundBlur = prefs.getDouble('pageBackgroundBlur') ?? 4.0;
    _contentPageBackgroundPath =
        prefs.getString('contentPageBackgroundPath');
    _contentPageBackgroundEnabled =
        prefs.getBool('contentPageBackgroundEnabled') ?? false;
    contentPageBackgroundEnabledValue = _contentPageBackgroundEnabled;
    _contentPageBackgroundOpacity =
        prefs.getDouble('contentPageBackgroundOpacity') ?? 0.18;
    contentPageBackgroundOpacityValue = _contentPageBackgroundOpacity;
    _contentPageBackgroundBlur =
        prefs.getDouble('contentPageBackgroundBlur') ?? 3.0;
    contentPageBackgroundBlurValue = _contentPageBackgroundBlur;
    _videoCardGlass = prefs.getBool('videoCardGlass') ?? false;
    videoCardGlassEnabled = _videoCardGlass;
    _chatGlass = prefs.getBool('chatGlass') ?? true;
    chatGlassEnabled = _chatGlass;

            
    _incognitoMode = prefs.getBool('incognitoMode') ?? false;

                        
    _useM3BottomBar = prefs.getBool('useM3BottomBar') ?? false;
    _bottomBarSearch = prefs.getBool('bottomBarSearch') ?? true;
    final navOrder = prefs.getStringList('bottomNavOrder');
    if (navOrder != null && navOrder.isNotEmpty) {
                                               
                            
      final valid = navOrder.where(kAllBottomNavIds.contains).toList();
      _bottomNavOrder = valid.isNotEmpty
          ? valid
          : List.of(kDefaultBottomNavOrder);
    }

                                      
    _disableNativeMenu = prefs.getBool('disableNativeMenu') ?? false;
    NativeMenuService.enabled = !_disableNativeMenu;
    _searchTrendingEnabled = prefs.getBool('searchTrendingEnabled') ?? true;
    searchTrendingEnabledStatic = _searchTrendingEnabled;
    _searchRcmdEnabled = prefs.getBool('searchRcmdEnabled') ?? true;
    searchRcmdEnabledStatic = _searchRcmdEnabled;
    _enableCommAntifraud = prefs.getBool('enableCommAntifraud') ?? false;
    commAntifraudEnabledStatic = _enableCommAntifraud;
    _refreshDisplacement = prefs.getDouble('refreshDisplacement') ?? 40.0;
    _refreshEdgeOffset = prefs.getDouble('refreshEdgeOffset') ?? 0.0;

                                        
    _springMass = prefs.getDouble('springMass') ?? 1.0;
    _springStiffness =
        prefs.getDouble('springStiffness') ?? 438.64908449286037;
    _springDamping = prefs.getDouble('springDamping') ?? 41.88790204786391;
    _syncSpringStatic();

                                                   
    _toastUseFluttertoast = prefs.getBool('toastUseFluttertoast') ?? false;
    _toastBgColor = Color(prefs.getInt('toastBgColor') ?? 0xFF323232);
    _toastBgOpacity = prefs.getDouble('toastBgOpacity') ?? 0.8;
    _toastBgBlur = prefs.getBool('toastBgBlur') ?? false;
    _syncToastStatics();

    _fileAssociationDefault =
        prefs.getBool('fileAssociationDefault') ?? false;

                                               
                                                 
    _efficiencyMode = prefs.getBool('efficiencyMode') ?? false;

              
    _liquidGlassMenuJelly = prefs.getBool('liquidGlassMenuJelly') ?? true;       
    _liquidGlassBottomBarJelly =
        prefs.getBool('liquidGlassBottomBarJelly') ?? true;       
    _liquidGlassThickness = prefs.getDouble('liquidGlassThickness') ?? 20.0;
    _liquidGlassBlur = prefs.getDouble('liquidGlassBlur') ?? 10.0;
    _liquidGlassTintOpacity = prefs.getDouble('liquidGlassTintOpacity') ?? 0.0;
    _liquidGlassSaturation = prefs.getDouble('liquidGlassSaturation') ?? 1.0;
    _liquidGlassRefractiveIndex =
        prefs.getDouble('liquidGlassRefractiveIndex') ?? 1.3;
    _liquidGlassLightIntensity =
        prefs.getDouble('liquidGlassLightIntensity') ?? 0.0;
    _liquidGlassAmbientStrength =
        prefs.getDouble('liquidGlassAmbientStrength') ?? 0.0;
    _liquidGlassLightAngle =
        prefs.getDouble('liquidGlassLightAngle') ?? math.pi / 2;
    _liquidGlassChromaticAberration =
        prefs.getDouble('liquidGlassChromaticAberration') ?? 0.02;
    _syncLiquidGlassStatics();

                   
    final imageSlicesJson = prefs.getString('imageSlices');
    if (imageSlicesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(imageSlicesJson);
        _imageSlices = List<Map<String, dynamic>>.from(decoded);
      } catch (e) {
        _imageSlices = [];
      }
    }

    final customThemesJson = prefs.getString('customThemes');
    if (customThemesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(customThemesJson);
        _customThemes = decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        _customThemes = [];
      }
    }

    final themeModeString = prefs.getString('themeMode') ?? 'system';
    _themeMode = _parseThemeMode(themeModeString);
    notifyListeners();
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }


                     
  Future<void> setDisplayScale(double value) async {
    final clamped = value.clamp(0.50, 2.00);
    if (_displayScale == clamped) return;
    _displayScale = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('displayScale', clamped);
    notifyListeners();
  }

                   
                                                                          
  Future<void> setAppLocaleCode(String? code) async {
    if (_appLocaleCode == code) return;
    _appLocaleCode = code;
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove('appLocaleCode');
    } else {
      await prefs.setString('appLocaleCode', code);
    }
    notifyListeners();
  }

                                                     
  static String? _normalizeLocaleCode(String? code) {
    switch (code) {
      case 'zh':
        return 'zh-CN';
      case 'en':
        return 'en-US';
    }
    return code;
  }

  Future<void> setHideWebDavInfo(bool value) async {
    if (_hideWebDavInfo == value) return;
    _hideWebDavInfo = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hideWebDavInfo', value);
    notifyListeners();
  }

                       
  Future<void> setImageSlices(List<Map<String, dynamic>> slices) async {
    _imageSlices = List.from(slices);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('imageSlices', jsonEncode(_imageSlices));
    notifyListeners();
  }

                     
  Future<void> setTileOrder(List<String> order) async {
    _tileOrder = List.from(order);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tileOrder', _tileOrder);
    notifyListeners();
  }

                       
  Future<void> setPlayerDefaultRate(double value) async {
    if (_playerDefaultRate == value) return;
    _playerDefaultRate = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('playerDefaultRate', value);
    notifyListeners();
  }

                                                     
  Future<void> setSleepTimerExitApp(bool value) async {
    if (_sleepTimerExitApp == value) return;
    _sleepTimerExitApp = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sleepTimerExitApp', value);
    SleepTimerService.instance.exitAppOnEnd = value;
    notifyListeners();
  }

                         
  Future<void> setPlaylistReversePlay(bool value) async {
    if (_playlistReversePlay == value) return;
    _playlistReversePlay = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('playlistReversePlay', value);
    notifyListeners();
  }

  Future<void> setPlayerEndBehavior(String value) async {
    if (_playerEndBehavior == value) return;
    _playerEndBehavior = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playerEndBehavior', value);
    notifyListeners();
  }

  Future<void> setShowPlayerStats(bool value) async {
    if (_showPlayerStats == value) return;
    _showPlayerStats = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showPlayerStats', value);
    notifyListeners();
  }

  Future<void> setAutoPiPOnBackground(bool value) async {
    if (_autoPiPOnBackground == value) return;
    _autoPiPOnBackground = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoPiPOnBackground', value);
    notifyListeners();
  }

                            
  Future<void> setAutoOfflineCache(bool value) async {
    if (_autoOfflineCache == value) return;
    _autoOfflineCache = value;
    autoOfflineCacheEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoOfflineCache', value);
    notifyListeners();
  }

                                     
  Future<void> setFavWidgetFolderId(int value) async {
    if (_favWidgetFolderId == value) return;
    _favWidgetFolderId = value;
    await setFavWidgetFolderIdGlobal(value);
    notifyListeners();
  }

                                   
  Future<void> setOnnxDepBaseUrl(String value) async {
    final v = value.trim();
    if (_onnxDepBaseUrl == v) return;
    _onnxDepBaseUrl = v;
    await setOnnxDepBaseUrlGlobal(v);
    notifyListeners();
  }

                          
  Future<void> setAutoCachePath(String value) async {
    final v = value.trim();
    if (_autoCachePath == v) return;
    _autoCachePath = v;
    await setAutoCachePathGlobal(v);
    notifyListeners();
  }

                          
  Future<void> setVideoDownloadPath(String value) async {
    final v = value.trim();
    if (_videoDownloadPath == v) return;
    _videoDownloadPath = v;
    await setVideoDownloadPathGlobal(v);
    notifyListeners();
  }

                             
  Future<void> setModelDownloadPath(String value) async {
    final v = value.trim();
    if (_modelDownloadPath == v) return;
    _modelDownloadPath = v;
    await setModelDownloadPathGlobal(v);
    notifyListeners();
  }

                   
  Future<void> setTtsMirror(TtsMirror value, {String? customUrl}) async {
    final url = customUrl ?? _ttsCustomUrl;
    if (_ttsMirror == value.index && _ttsCustomUrl == url) return;
    _ttsMirror = value.index;
    _ttsCustomUrl = url;
    await applyTtsMirrorGlobal(value, url);
    notifyListeners();
  }

  Future<void> setIsLocked(bool value) async {
    if (_isLocked == value) return;
    _isLocked = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLocked', value);
    notifyListeners();
  }

  Future<void> setUseDynamicColor(bool value) async {
    _useDynamicColor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDynamicColor', value);
    notifyListeners();
  }

  Future<void> setEnableFragmentRendering(bool value) async {
    if (_enableFragmentRendering == value) return;
    _enableFragmentRendering = value;
    fragmentRenderingEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableFragmentRendering', value);
    notifyListeners();
  }

  Future<void> setDisableLiquidGlassMenus(bool value) async {
    if (_disableLiquidGlassMenus == value) return;
    _disableLiquidGlassMenus = value;
    liquidGlassMenusDisabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disableLiquidGlassMenus', value);
    notifyListeners();
  }

  Future<void> setLiquidGlassMenuJelly(bool value) async {
    if (_liquidGlassMenuJelly == value) return;
    _liquidGlassMenuJelly = value;
    liquidGlassMenuJellyEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('liquidGlassMenuJelly', value);
    notifyListeners();
  }

  Future<void> setLiquidGlassBottomBarJelly(bool value) async {
    if (_liquidGlassBottomBarJelly == value) return;
    _liquidGlassBottomBarJelly = value;
    liquidGlassBottomBarJellyEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('liquidGlassBottomBarJelly', value);
    notifyListeners();
  }

  Future<void> addCustomTheme(String name, Color color) async {
    _customThemes.add({'name': name, 'color': color.toARGB32()});
    await _saveCustomThemes();
    notifyListeners();
  }

  Future<void> removeCustomTheme(int index) async {
    if (index >= 0 && index < _customThemes.length) {
      _customThemes.removeAt(index);
      await _saveCustomThemes();
      notifyListeners();
    }
  }

  Future<void> _saveCustomThemes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customThemes', jsonEncode(_customThemes));
  }

                               
  bool get incognitoMode => _incognitoMode;
  Future<void> setIncognitoMode(bool value) async {
    _incognitoMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('incognitoMode', value);
    notifyListeners();
  }

                                                    

                                                 
  Future<void> setUseM3BottomBar(bool value) async {
    if (_useM3BottomBar == value) return;
    _useM3BottomBar = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useM3BottomBar', value);
    notifyListeners();
  }

                                 
  Future<void> setBottomBarSearch(bool value) async {
    if (_bottomBarSearch == value) return;
    _bottomBarSearch = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bottomBarSearch', value);
    notifyListeners();
  }

                                            
                                                               
  Future<void> setDisableNativeMenu(bool value) async {
    if (_disableNativeMenu == value) return;
    _disableNativeMenu = value;
    NativeMenuService.enabled = !value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disableNativeMenu', value);
    notifyListeners();
  }

                                  
                           
  Future<void> setBottomNavOrder(List<String> order) async {
    if (order.isEmpty) return;
    if (listEquals(_bottomNavOrder, order)) return;
    _bottomNavOrder = List.of(order);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bottomNavOrder', _bottomNavOrder);
    notifyListeners();
  }

                             
  Future<void> resetBottomNavOrder() async {
    await setBottomNavOrder(List.of(kDefaultBottomNavOrder));
  }

                                      
  Future<void> setSearchTrendingEnabled(bool value) async {
    if (_searchTrendingEnabled == value) return;
    _searchTrendingEnabled = value;
    searchTrendingEnabledStatic = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('searchTrendingEnabled', value);
    notifyListeners();
  }

                             
  Future<void> setSearchRcmdEnabled(bool value) async {
    if (_searchRcmdEnabled == value) return;
    _searchRcmdEnabled = value;
    searchRcmdEnabledStatic = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('searchRcmdEnabled', value);
    notifyListeners();
  }

                            
                                     
  Future<void> setEnableCommAntifraud(bool value) async {
    if (_enableCommAntifraud == value) return;
    _enableCommAntifraud = value;
    commAntifraudEnabledStatic = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableCommAntifraud', value);
    notifyListeners();
  }

                                                         
  Future<void> setRefreshDisplacement(double value) async {
    final clamped = value.clamp(40.0, 200.0).toDouble();
    if (_refreshDisplacement == clamped) return;
    _refreshDisplacement = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('refreshDisplacement', clamped);
    notifyListeners();
  }

                                                         
  Future<void> setRefreshEdgeOffset(double value) async {
    final clamped = value.clamp(0.0, 120.0).toDouble();
    if (_refreshEdgeOffset == clamped) return;
    _refreshEdgeOffset = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('refreshEdgeOffset', clamped);
    notifyListeners();
  }

                                                       
                                       
                          
  Future<void> setSpringDescription({
    required double mass,
    required double stiffness,
    required double damping,
  }) async {
    if (_springMass == mass &&
        _springStiffness == stiffness &&
        _springDamping == damping) {
      return;
    }
    _springMass = mass;
    _springStiffness = stiffness;
    _springDamping = damping;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('springMass', mass);
    await prefs.setDouble('springStiffness', stiffness);
    await prefs.setDouble('springDamping', damping);
    _syncSpringStatic();
    notifyListeners();
  }

                                                         
  Future<void> resetSpringDescription() async {
    _springMass = 1.0;
    _springStiffness = 438.64908449286037;
    _springDamping = 41.88790204786391;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('springMass');
    await prefs.remove('springStiffness');
    await prefs.remove('springDamping');
    _syncSpringStatic();
    notifyListeners();
  }

                                       
  void _syncSpringStatic() {
    naviSpringDescription = SpringDescription(
      mass: _springMass,
      stiffness: _springStiffness,
      damping: _springDamping,
    );
  }

                                                

                                    
                                                      
                                                   
  Future<void> setToastUseFluttertoast(bool value) async {
    if (_toastUseFluttertoast == value) return;
    _toastUseFluttertoast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('toastUseFluttertoast', value);
    _syncToastStatics();
    notifyListeners();
  }

                                                           
                    
  Future<void> setToastBgColor(Color color) async {
    if (_toastBgColor == color) return;
    _toastBgColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('toastBgColor', color.toARGB32());
    _syncToastStatics();
    notifyListeners();
  }

                                         
  Future<void> setToastBgOpacity(double value) async {
    final clamped = value.clamp(0.1, 1.0).toDouble();
    if (_toastBgOpacity == clamped) return;
    _toastBgOpacity = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('toastBgOpacity', clamped);
    _syncToastStatics();
    notifyListeners();
  }

                                         
  Future<void> setToastBgBlur(bool value) async {
    if (_toastBgBlur == value) return;
    _toastBgBlur = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('toastBgBlur', value);
    _syncToastStatics();
    notifyListeners();
  }

                                                        
  void _syncToastStatics() {
    toastUseFluttertoastEnabled = _toastUseFluttertoast;
    toastBgColorValue = _toastBgColor;
    toastBgOpacityValue = _toastBgOpacity;
    toastBgBlurEnabled = _toastBgBlur;
  }

                                       
                                     
  Future<void> setFileAssociationDefault(bool value) async {
    _fileAssociationDefault = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fileAssociationDefault', value);
    notifyListeners();
  }

                           
     
                                     
                               
                                              
  Future<WindowsPowerSnapshot> setEfficiencyMode(bool value) async {
    _efficiencyMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('efficiencyMode', value);
    notifyListeners();
    unawaited(EfficiencyModeAutomation.instance.updateEnabled(value));
    return WindowsPowerService.lastSnapshot ?? const WindowsPowerSnapshot();
  }

  Future<void> setThemeSeedColor(Color color) async {
    _themeSeedColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeSeedColor', color.toARGB32());
    notifyListeners();
  }

                                                           
  Future<void> setSchemeVariant(FlexSchemeVariant variant) async {
    if (_schemeVariant == variant) return;
    _schemeVariant = variant;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('schemeVariant', variant.index);
    notifyListeners();
  }

  Future<void> setRestrictIP(bool value) async {
    _restrictIP = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('restrictIP', value);
    notifyListeners();
  }

  Future<void> setNickname(String value) async {
    _nickname = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', value);
    notifyListeners();
  }

  Future<void> setAvatarPath(String? path) async {
    _avatarPath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString('avatarPath', path);
    } else {
      await prefs.remove('avatarPath');
    }
    notifyListeners();
  }

  Future<void> pickAndSaveAvatar() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final dir = await getApplicationDocumentsDirectory();
        final avatarDir = Directory('${dir.path}/avatars');
        if (!await avatarDir.exists()) await avatarDir.create(recursive: true);
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = '${avatarDir.path}/$fileName';
        await File(pickedFile.path).copy(savedPath);
        await setAvatarPath(savedPath);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error picking avatar: $e');
      rethrow;
    }
  }

  Future<void> removeAvatar() async {
    if (_avatarPath != null) {
      try {
        final file = File(_avatarPath!);
        if (await file.exists()) await file.delete();
      } catch (e) {
        if (kDebugMode) debugPrint('Error deleting avatar file: $e');
      }
    }
    await setAvatarPath(null);
  }

  Future<void> setLockScreenWallpaperPath(String? path) async {
    _lockScreenWallpaperPath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString('lockScreenWallpaperPath', path);
    } else {
      await prefs.remove('lockScreenWallpaperPath');
    }
    notifyListeners();
  }

  Future<void> setLockScreenFollowThemeColor(bool value) async {
    _lockScreenFollowThemeColor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lockScreenFollowThemeColor', value);
    notifyListeners();
  }

  Future<void> setLockScreenShowBattery(bool value) async {
    _lockScreenShowBattery = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lockScreenShowBattery', value);
    notifyListeners();
  }

  Future<void> setLockScreenShowNetwork(bool value) async {
    _lockScreenShowNetwork = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lockScreenShowNetwork', value);
    notifyListeners();
  }

  Future<bool> pickAndSaveLockScreenWallpaper() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (pickedFile != null) {
        final dir = await getApplicationDocumentsDirectory();
        final wallpaperDir = Directory('${dir.path}/wallpapers');
        if (!await wallpaperDir.exists()) {
          await wallpaperDir.create(recursive: true);
        }
        final fileName =
            'wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = '${wallpaperDir.path}/$fileName';
        await File(pickedFile.path).copy(savedPath);
        await setLockScreenWallpaperPath(savedPath);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Error picking wallpaper: $e');
      rethrow;
    }
  }

  Future<void> removeLockScreenWallpaper() async {
    if (_lockScreenWallpaperPath != null) {
      try {
        final file = File(_lockScreenWallpaperPath!);
        if (await file.exists()) await file.delete();
      } catch (e) {
        if (kDebugMode) debugPrint('Error deleting wallpaper file: $e');
      }
    }
    await setLockScreenWallpaperPath(null);
  }

  Future<void> setBackgroundImagePath(String? path) async {
    _backgroundImagePath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString('backgroundImagePath', path);
    } else {
      await prefs.remove('backgroundImagePath');
    }
    notifyListeners();
  }

  Future<bool> pickAndSaveBackgroundImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (pickedFile != null) {
        final dir = await getApplicationDocumentsDirectory();
        final bgDir = Directory('${dir.path}/backgrounds');
        if (!await bgDir.exists()) await bgDir.create(recursive: true);
        final fileName = 'bg_${DateTime.now().millisecondsSinceEpoch}.png';
        final savedPath = '${bgDir.path}/$fileName';
        await File(pickedFile.path).copy(savedPath);
        if (_backgroundImagePath != null) {
          final oldFile = File(_backgroundImagePath!);
          if (await oldFile.exists()) await oldFile.delete();
        }
        await setBackgroundImagePath(savedPath);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Error picking background image: $e');
      rethrow;
    }
  }

  Future<void> removeBackgroundImage() async {
    if (_backgroundImagePath != null) {
      try {
        final file = File(_backgroundImagePath!);
        if (await file.exists()) await file.delete();
      } catch (e) {
        if (kDebugMode) debugPrint('Error deleting background image file: $e');
      }
    }
    await setBackgroundImagePath(null);
  }

  Future<void> setBackgroundImageSize(double value) async {
    _backgroundImageSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('backgroundImageSize', value);
    notifyListeners();
  }

  Future<void> setBackgroundImageOpacity(double value) async {
    _backgroundImageOpacity = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('backgroundImageOpacity', value);
    notifyListeners();
  }

                        
  Future<void> setDrawerBackgroundPath(String? path) async {
    _drawerBackgroundPath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString('drawerBackgroundPath', path);
    } else {
      await prefs.remove('drawerBackgroundPath');
    }
    notifyListeners();
  }

  Future<bool> pickAndSaveDrawerBackground() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (pickedFile != null) {
        final dir = await getApplicationDocumentsDirectory();
        final drawerBgDir = Directory('${dir.path}/drawer_backgrounds');
        if (!await drawerBgDir.exists()) {
          await drawerBgDir.create(recursive: true);
        }
        final fileName =
            'drawer_bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = '${drawerBgDir.path}/$fileName';
        await File(pickedFile.path).copy(savedPath);
               
        if (_drawerBackgroundPath != null) {
          final oldFile = File(_drawerBackgroundPath!);
          if (await oldFile.exists()) await oldFile.delete();
        }
        await setDrawerBackgroundPath(savedPath);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Error picking drawer background: $e');
      rethrow;
    }
  }

  Future<void> removeDrawerBackground() async {
    if (_drawerBackgroundPath != null) {
      try {
        final file = File(_drawerBackgroundPath!);
        if (await file.exists()) await file.delete();
      } catch (e) {
        if (kDebugMode) debugPrint('Error deleting drawer background file: $e');
      }
    }
    await setDrawerBackgroundPath(null);
  }

                      
  Future<void> setPageBackgroundPath(String? path) async {
    _pageBackgroundPath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString('pageBackgroundPath', path);
    } else {
      await prefs.remove('pageBackgroundPath');
    }
    notifyListeners();
  }

                                                 
                         
  Future<bool> savePageBackgroundImage(File croppedFile) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final bgDir = Directory('${dir.path}/page_backgrounds');
      if (!await bgDir.exists()) await bgDir.create(recursive: true);
      final fileName = 'page_bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${bgDir.path}/$fileName';
      await croppedFile.copy(savedPath);
      if (_pageBackgroundPath != null) {
        final oldFile = File(_pageBackgroundPath!);
        if (await oldFile.exists()) await oldFile.delete();
      }
      await setPageBackgroundPath(savedPath);
      await setPageBackgroundEnabled(true);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving page background: $e');
      return false;
    }
  }

  Future<void> removePageBackground() async {
    if (_pageBackgroundPath != null) {
      try {
        final file = File(_pageBackgroundPath!);
        if (await file.exists()) await file.delete();
      } catch (e) {
        if (kDebugMode) debugPrint('Error deleting page background: $e');
      }
    }
    await setPageBackgroundPath(null);
    await setPageBackgroundEnabled(false);
  }

                                        
                            
  Future<bool> saveContentPageBackgroundImage(File croppedFile) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final bgDir = Directory('${dir.path}/content_page_backgrounds');
      if (!await bgDir.exists()) await bgDir.create(recursive: true);
      final fileName =
          'content_page_bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${bgDir.path}/$fileName';
      await croppedFile.copy(savedPath);
      if (_contentPageBackgroundPath != null) {
        final oldFile = File(_contentPageBackgroundPath!);
        if (await oldFile.exists()) await oldFile.delete();
      }
      await setContentPageBackgroundPath(savedPath);
      await setContentPageBackgroundEnabled(true);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving content page background: $e');
      return false;
    }
  }

  Future<void> removeContentPageBackground() async {
    if (_contentPageBackgroundPath != null) {
      try {
        final file = File(_contentPageBackgroundPath!);
        if (await file.exists()) await file.delete();
      } catch (e) {
        if (kDebugMode) debugPrint('Error deleting content page background: $e');
      }
    }
    await setContentPageBackgroundPath(null);
    await setContentPageBackgroundEnabled(false);
  }

  Future<void> setPageBackgroundEnabled(bool value) async {
    _pageBackgroundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pageBackgroundEnabled', value);
    notifyListeners();
  }

  Future<void> setPageBackgroundOpacity(double value) async {
    _pageBackgroundOpacity = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pageBackgroundOpacity', value);
    notifyListeners();
  }

  Future<void> setPageBackgroundBlur(double value) async {
    _pageBackgroundBlur = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pageBackgroundBlur', value);
    notifyListeners();
  }

  Future<void> setContentPageBackgroundPath(String? value) async {
    if (_contentPageBackgroundPath == value) return;
    _contentPageBackgroundPath = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('contentPageBackgroundPath');
    } else {
      await prefs.setString('contentPageBackgroundPath', value);
    }
    notifyListeners();
  }

  Future<void> setContentPageBackgroundEnabled(bool value) async {
    if (_contentPageBackgroundEnabled == value) return;
    _contentPageBackgroundEnabled = value;
    contentPageBackgroundEnabledValue = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('contentPageBackgroundEnabled', value);
    notifyListeners();
  }

  Future<void> setContentPageBackgroundOpacity(double value) async {
    if (_contentPageBackgroundOpacity == value) return;
    _contentPageBackgroundOpacity = value;
    contentPageBackgroundOpacityValue = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('contentPageBackgroundOpacity', value);
    notifyListeners();
  }

  Future<void> setContentPageBackgroundBlur(double value) async {
    if (_contentPageBackgroundBlur == value) return;
    _contentPageBackgroundBlur = value;
    contentPageBackgroundBlurValue = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('contentPageBackgroundBlur', value);
    notifyListeners();
  }

  Future<void> setVideoCardGlass(bool value) async {
    if (_videoCardGlass == value) return;
    _videoCardGlass = value;
    videoCardGlassEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('videoCardGlass', value);
    notifyListeners();
  }

                    
  Future<void> setChatGlass(bool value) async {
    if (_chatGlass == value) return;
    _chatGlass = value;
    chatGlassEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chatGlass', value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeModeToString(mode));
    notifyListeners();
  }

  Future<void> setFontWeight(double value) async {
    _fontWeight = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontWeight', value);
    notifyListeners();
  }

  Future<void> setIsPureBlackMode(bool value) async {
    _isPureBlackMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPureBlackMode', value);
    notifyListeners();
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setWindowSize(double width, double height) async {
    _windowWidth = width.clamp(400.0, double.infinity);
    _windowHeight = height.clamp(300.0, double.infinity);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('windowWidth', _windowWidth);
    await prefs.setDouble('windowHeight', _windowHeight);
    try {
      await windowManager.setSize(Size(_windowWidth, _windowHeight));
    } catch (e) {
      if (kDebugMode) debugPrint('窗口调整失败 (非桌面环境或未初始化): $e');
    }
    notifyListeners();
  }

                                                       
                                                      
                  
  void syncWindowSizeFromSystem(double width, double height) {
    final w = width.clamp(400.0, double.infinity);
    final h = height.clamp(300.0, double.infinity);
    if ((_windowWidth - w).abs() < 0.5 && (_windowHeight - h).abs() < 0.5) {
      return;
    }
    _windowWidth = w;
    _windowHeight = h;
    notifyListeners();
  }

                                                             

  Future<void> setEnableStartScreen(bool value) async {
    if (_enableStartScreen == value) return;
    _enableStartScreen = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableStartScreen', value);
    notifyListeners();
  }

  Future<void> setEnableCharm(bool value) async {
    if (_enableCharm == value) return;
    _enableCharm = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableCharm', value);
    notifyListeners();
  }

  Future<void> setEnableCharmGesture(bool value) async {
    if (_enableCharmGesture == value) return;
    _enableCharmGesture = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableCharmGesture', value);
    notifyListeners();
  }

  Future<void> setStartScreenWarningDismissed(bool value) async {
    if (_startScreenWarningDismissed == value) return;
    _startScreenWarningDismissed = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('startScreenWarningDismissed', value);
    notifyListeners();
  }

                                                               
  Future<void> setDisplayMode(String? mode) async {
    if (_displayMode == mode) return;
    _displayMode = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode != null && mode.isNotEmpty) {
      await prefs.setString('displayMode', mode);
    } else {
      await prefs.remove('displayMode');
    }
    notifyListeners();
  }

                                       
  Future<void> setBrowserAllowClipboard(bool value) async {
    if (_browserAllowClipboard == value) return;
    _browserAllowClipboard = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('browserAllowClipboard', value);
    notifyListeners();
  }

                                    
  Future<void> setBrowserUaMode(BrowserUaMode value) async {
    if (_browserUaMode == value) return;
    _browserUaMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('browserUaMode', value.code);
    notifyListeners();
  }

                                      
  Future<void> setRecommendSource(BiliRecommendSource value) async {
    if (_recommendSource == value) return;
    _recommendSource = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recommendSource', value.code);
    notifyListeners();
  }

                                  

                                        
     
                                                       
                                  
  void _syncRecommendFilter() {
    rcmdKeepLastData = _enableSaveLastData;
    rcmdSavedPositionTip = _savedRcmdTip;
    rcmdMinLikeRatio = _minLikeRatioForRecommend;
    rcmdMinDuration = _minDurationForRcmd;
    rcmdMinPlay = _minPlayForRcmd;
    rcmdBanWord = UgcFilterService.instance.patternOf(UgcFilterScope.recommend);
    rcmdBanZone = UgcFilterService.instance.patternOf(UgcFilterScope.zone);
    rcmdExemptFollowed = _exemptFilterForFollowed;
    rcmdFilterRelatedVideos = _applyFilterToRelatedVideos;
    RecommendFilter.configure(
      minLikeRatioPercent: _minLikeRatioForRecommend,
      minDurationSec: _minDurationForRcmd,
      minPlay: _minPlayForRcmd,
      banWordPattern: rcmdBanWord,
      banZonePattern: rcmdBanZone,
      exemptFollowed: _exemptFilterForFollowed,
      applyToRelatedVideos: _applyFilterToRelatedVideos,
    );
  }

                                 
  Future<void> setEnableSaveLastData(bool value) async {
    if (_enableSaveLastData == value) return;
    _enableSaveLastData = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableSaveLastData', value);
    _syncRecommendFilter();
    notifyListeners();
  }

                                  
  Future<void> setSavedRcmdTip(bool value) async {
    if (_savedRcmdTip == value) return;
    _savedRcmdTip = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('savedRcmdTip', value);
    _syncRecommendFilter();
    notifyListeners();
  }

                         
  Future<void> setMinLikeRatioForRecommend(int value) async {
    if (_minLikeRatioForRecommend == value) return;
    _minLikeRatioForRecommend = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('minLikeRatioForRecommend', value);
    _syncRecommendFilter();
    notifyListeners();
  }

                      
  Future<void> setMinDurationForRcmd(int value) async {
    if (_minDurationForRcmd == value) return;
    _minDurationForRcmd = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('minDurationForRcmd', value);
    _syncRecommendFilter();
    notifyListeners();
  }

                     
  Future<void> setMinPlayForRcmd(int value) async {
    if (_minPlayForRcmd == value) return;
    _minPlayForRcmd = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('minPlayForRcmd', value);
    _syncRecommendFilter();
    notifyListeners();
  }

                                            
                                   
  Future<void> setBanWordForRecommend(String value) async {
    await UgcFilterService.instance.setRulesFromText(
      UgcFilterScope.recommend,
      value,
    );
    notifyListeners();
  }

                           
  Future<void> setBanWordForZone(String value) async {
    await UgcFilterService.instance.setRulesFromText(
      UgcFilterScope.zone,
      value,
    );
    notifyListeners();
  }

                    
  Future<void> setExemptFilterForFollowed(bool value) async {
    if (_exemptFilterForFollowed == value) return;
    _exemptFilterForFollowed = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('exemptFilterForFollowed', value);
    _syncRecommendFilter();
    notifyListeners();
  }

                     
  Future<void> setApplyFilterToRelatedVideos(bool value) async {
    if (_applyFilterToRelatedVideos == value) return;
    _applyFilterToRelatedVideos = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('applyFilterToRelatedVideos', value);
    _syncRecommendFilter();
    notifyListeners();
  }

                                 
  bool get recommendGuestMode => _recommendGuestMode;

  Future<void> setRecommendGuestMode(bool value) async {
    if (_recommendGuestMode == value) return;
    _recommendGuestMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('recommendGuestMode', value);
    rcmdGuestMode = value;                             
    notifyListeners();
  }

                                                
  Future<void> setHeroTransitionBlur(bool value) async {
    if (_heroTransitionBlur == value) return;
    _heroTransitionBlur = value;
    heroTransitionBlurEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('heroTransitionBlur', value);
    notifyListeners();
  }

                                              
  Future<void> setIosPushTransition(bool value) async {
    if (_iosPushTransition == value) return;
    _iosPushTransition = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('iosPushTransition', value);
    notifyListeners();
  }

                                   
  Future<void> setIosPushTransitionCornerRadius(double value) async {
    final clamped = value.clamp(0.0, 48.0).toDouble();
    if (_iosPushTransitionCornerRadius == clamped) return;
    _iosPushTransitionCornerRadius = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('iosPushTransitionCornerRadius', clamped);
    notifyListeners();
  }

                                    
  Future<void> setIosPushTransitionCornerAuto(bool value) async {
    if (_iosPushTransitionCornerAuto == value) return;
    _iosPushTransitionCornerAuto = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('iosPushTransitionCornerAuto', value);
    notifyListeners();
  }


  void _syncLiquidGlassStatics() {
    liquidGlassMenuJellyEnabled = _liquidGlassMenuJelly;
    liquidGlassBottomBarJellyEnabled = _liquidGlassBottomBarJelly;
    liquidGlassThickness = _liquidGlassThickness;
    liquidGlassBlur = _liquidGlassBlur;
    liquidGlassTintOpacity = _liquidGlassTintOpacity;
    liquidGlassSaturation = _liquidGlassSaturation;
    liquidGlassRefractiveIndex = _liquidGlassRefractiveIndex;
    liquidGlassLightIntensity = _liquidGlassLightIntensity;
    liquidGlassAmbientStrength = _liquidGlassAmbientStrength;
    liquidGlassLightAngle = _liquidGlassLightAngle;
    liquidGlassChromaticAberration = _liquidGlassChromaticAberration;
  }

                                  
  Future<void> setLiquidGlassTuning({
    double? thickness,
    double? blur,
    double? tintOpacity,
    double? saturation,
    double? refractiveIndex,
    double? lightIntensity,
    double? ambientStrength,
    double? lightAngle,
    double? chromaticAberration,
  }) async {
    _liquidGlassThickness = thickness ?? _liquidGlassThickness;
    _liquidGlassBlur = blur ?? _liquidGlassBlur;
    _liquidGlassTintOpacity = tintOpacity ?? _liquidGlassTintOpacity;
    _liquidGlassSaturation = saturation ?? _liquidGlassSaturation;
    _liquidGlassRefractiveIndex =
        refractiveIndex ?? _liquidGlassRefractiveIndex;
    _liquidGlassLightIntensity = lightIntensity ?? _liquidGlassLightIntensity;
    _liquidGlassAmbientStrength =
        ambientStrength ?? _liquidGlassAmbientStrength;
    _liquidGlassLightAngle = lightAngle ?? _liquidGlassLightAngle;
    _liquidGlassChromaticAberration =
        chromaticAberration ?? _liquidGlassChromaticAberration;
    _syncLiquidGlassStatics();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('liquidGlassThickness', _liquidGlassThickness);
    await prefs.setDouble('liquidGlassBlur', _liquidGlassBlur);
    await prefs.setDouble('liquidGlassTintOpacity', _liquidGlassTintOpacity);
    await prefs.setDouble('liquidGlassSaturation', _liquidGlassSaturation);
    await prefs.setDouble(
      'liquidGlassRefractiveIndex',
      _liquidGlassRefractiveIndex,
    );
    await prefs.setDouble(
      'liquidGlassLightIntensity',
      _liquidGlassLightIntensity,
    );
    await prefs.setDouble(
      'liquidGlassAmbientStrength',
      _liquidGlassAmbientStrength,
    );
    await prefs.setDouble('liquidGlassLightAngle', _liquidGlassLightAngle);
    await prefs.setDouble(
      'liquidGlassChromaticAberration',
      _liquidGlassChromaticAberration,
    );
    notifyListeners();
  }

  bool isValidIP(String ip) {
    if (!_restrictIP) return true;
                  
    if (!ip.contains(':')) {
      final parts = ip.split('.');
      if (parts.length != 4) return false;
      try {
        final first = int.parse(parts[0]);
        final second = int.parse(parts[1]);
        if (first == 10) return true;
        if (first == 172 && second >= 16 && second <= 31) return true;
        if (first == 192 && second == 168) return true;
        return false;
      } catch (e) {
        return false;
      }
    }
                                            
    final clean = ip.contains('%') ? ip.substring(0, ip.indexOf('%')) : ip;
    final addr = InternetAddress.tryParse(clean);
    if (addr == null || addr.type != InternetAddressType.IPv6) return false;
    final colon = clean.indexOf(':');
    if (colon <= 0) return false;
    final hextet = int.tryParse(clean.substring(0, colon), radix: 16);
    if (hextet == null) return false;
    if ((hextet & 0xFE00) == 0xFC00) return true;            
    if ((hextet & 0xFFC0) == 0xFE80) return true;             
    return false;
  }
}
