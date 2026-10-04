                                            
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerSettingsService extends ChangeNotifier {
                                  
                                                       
                                               
                    
  static PlayerSettingsService? get shared => _shared;
  static PlayerSettingsService? _shared;

  PlayerSettingsService() {
    _shared = this;
  }

  static const _kShowFakeStatusBar = 'player_show_fake_status_bar';
  static const _kEnableLongPressSpeed = 'player_enable_long_press_speed';
  static const _kEnableScreenshot = 'player_enable_screenshot';
  static const _kHwdecMode = 'player_hwdec_mode';
  static const _kHwdecEnabled = 'player_hwdec_enabled';
  static const _kHwdecOnlySupported = 'player_hwdec_only_supported';
  static const _kLongPressInImmersive = 'player_long_press_in_immersive';
  static const _kVideoSync = 'player_video_sync';
       
  static const _kLoadDanmakuOnResume = 'player_load_danmaku_on_resume';
  static const _kShowDanmakuInScreenshot = 'player_show_danmaku_in_screenshot';
                      
  static const _kKeepWindowAspectRatio = 'player_keep_window_aspect_ratio';
  static const _kSuperResolution = 'player_super_resolution';
                                                  
  static const _kSkipIntroOutro = 'player_skip_intro_outro';
                                             
  static const _kAudioNormalization = 'player_audio_normalization';
                                               
  static const _kAudioOutputDevice = 'player_audio_output_device';
                  
  static const _kShowSeekPreview = 'player_show_seek_preview';
                                      
  static const _kPgcSkipMode = 'player_pgc_skip_mode';
                           
  static const _kRecordFormat = 'player_record_format';
                 
  static const _kRecordFps = 'player_record_fps';
                 
  static const _kRecordWidth = 'player_record_width';
                        
  static const _kRecordMaxSeconds = 'player_record_max_seconds';
                       
  static const _kEnableMpvLog = 'player_enable_mpv_log';
  static const _kMpvLogLevel = 'player_mpv_log_level';
  static const _kPreferredDecodeFormat = 'player_preferred_decode_format';
                   
  static const _kSubtitleDragEnabled = 'player_subtitle_drag_enabled';
  static const _kSubtitleBilingual = 'player_subtitle_bilingual';
  static const _kSubtitleTranslateLang = 'player_subtitle_translate_lang';
  static const _kSubtitlePadL = 'player_subtitle_pad_l';
  static const _kSubtitlePadR = 'player_subtitle_pad_r';
  static const _kSubtitlePadB = 'player_subtitle_pad_b';
                                     
  static const _kDefaultQnWifi = 'player_default_qn_wifi';
  static const _kDefaultQnCellular = 'player_default_qn_cellular';
                                        
                               
  static const _kDefaultAudioQualityId = 'player_default_audio_quality_id';

                                                         
  static const double defaultSubtitlePadL = 16.0;
  static const double defaultSubtitlePadR = 16.0;
  static const double defaultSubtitlePadB = 24.0;

  late SharedPreferences _prefs;

  bool _showFakeStatusBar = true;
  bool _enableLongPressSpeed = true;
  bool _enableScreenshot = true;
  String _hwdecMode = 'auto';
  bool _hwdecEnabled = true;             
  bool _hwdecOnlySupported = true;                         
  bool _longPressInImmersive = true;
  String _videoSync = 'audio';
  bool _loadDanmakuOnResume = true;             
  bool _showDanmakuInScreenshot = true;             
  bool _keepWindowAspectRatio = true;             
  String _superResolutionMode = 'disable';             
  bool _skipIntroOutro = true;             
  String _audioNormalization = 'disable';             
  String _audioOutputDevice = '';             
  bool _showSeekPreview = true;             
  String _pgcSkipMode = 'button';              
  String _recordFormat = 'gif';               
  int _recordFps = 10;        
  int _recordWidth = 480;        
  int _recordMaxSeconds = 10;        
  bool _enableMpvLog = false;             
  String _mpvLogLevel = 'warn';                
  String _preferredDecodeFormat = 'auto';             
  bool _subtitleDragEnabled = false;                           
  bool _subtitleBilingual = false;             
  String _subtitleTranslateLang = 'en-US';                   
  double _subtitlePadL = defaultSubtitlePadL;
  double _subtitlePadR = defaultSubtitlePadR;
  double _subtitlePadB = defaultSubtitlePadB;
  int _defaultQnWifi = 116;                       
  int _defaultQnCellular = 80;                    
  int _defaultAudioQualityId = 0;                   

                    
  bool get showFakeStatusBar => _showFakeStatusBar;
  bool get enableLongPressSpeed => _enableLongPressSpeed;
  bool get enableScreenshot => _enableScreenshot;
  String get hwdecMode => _hwdecMode;
  bool get hwdecEnabled => _hwdecEnabled;        
  bool get hwdecOnlySupported => _hwdecOnlySupported;        
  bool get longPressInImmersive => _longPressInImmersive;
  String get videoSync => _videoSync;
  bool get loadDanmakuOnResume => _loadDanmakuOnResume;        
  bool get showDanmakuInScreenshot => _showDanmakuInScreenshot;        
  bool get keepWindowAspectRatio => _keepWindowAspectRatio;        
  String get superResolutionMode => _superResolutionMode;        
  bool get skipIntroOutro => _skipIntroOutro;        
  String get audioNormalization => _audioNormalization;        
  String get audioOutputDevice => _audioOutputDevice;        
  bool get showSeekPreview => _showSeekPreview;        
  String get pgcSkipMode => _pgcSkipMode;        
  String get recordFormat => _recordFormat;        
  int get recordFps => _recordFps;        
  int get recordWidth => _recordWidth;        
  int get recordMaxSeconds => _recordMaxSeconds;        
  bool get enableMpvLog => _enableMpvLog;        
  String get mpvLogLevel => _mpvLogLevel;        
  String get preferredDecodeFormat => _preferredDecodeFormat;        
  bool get subtitleDragEnabled => _subtitleDragEnabled;        
  bool get subtitleBilingual => _subtitleBilingual;        
  String get subtitleTranslateLang => _subtitleTranslateLang;        
  double get subtitlePadL => _subtitlePadL;        
  double get subtitlePadR => _subtitlePadR;        
  double get subtitlePadB => _subtitlePadB;        
  int get defaultQnWifi => _defaultQnWifi;        
  int get defaultQnCellular => _defaultQnCellular;        
  int get defaultAudioQualityId => _defaultAudioQualityId;        

                                                
  EdgeInsets get subtitlePadding => EdgeInsets.fromLTRB(
    _subtitlePadL,
    0,
    _subtitlePadR,
    _subtitlePadB,
  );

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _showFakeStatusBar = _prefs.getBool(_kShowFakeStatusBar) ?? true;
    _enableLongPressSpeed = _prefs.getBool(_kEnableLongPressSpeed) ?? true;
    _enableScreenshot = _prefs.getBool(_kEnableScreenshot) ?? true;
    _hwdecMode = _prefs.getString(_kHwdecMode) ?? 'auto';
    _hwdecEnabled = _prefs.getBool(_kHwdecEnabled) ?? true;        
    _hwdecOnlySupported = _prefs.getBool(_kHwdecOnlySupported) ?? true;        
    _longPressInImmersive = _prefs.getBool(_kLongPressInImmersive) ?? true;
    _videoSync = _prefs.getString(_kVideoSync) ?? 'audio';
    _loadDanmakuOnResume = _prefs.getBool(_kLoadDanmakuOnResume) ?? true;        
    _showDanmakuInScreenshot = _prefs.getBool(_kShowDanmakuInScreenshot) ?? true;        
    _keepWindowAspectRatio = _prefs.getBool(_kKeepWindowAspectRatio) ?? true;        
    _superResolutionMode = _prefs.getString(_kSuperResolution) ?? 'disable';        
    _skipIntroOutro = _prefs.getBool(_kSkipIntroOutro) ?? true;        
    _audioNormalization =
        _prefs.getString(_kAudioNormalization) ?? 'disable';        
    _audioOutputDevice = _prefs.getString(_kAudioOutputDevice) ?? '';        
    _showSeekPreview = _prefs.getBool(_kShowSeekPreview) ?? true;        
    _pgcSkipMode = _prefs.getString(_kPgcSkipMode) ?? 'button';        
    _recordFormat = _prefs.getString(_kRecordFormat) ?? 'gif';        
    _recordFps = _prefs.getInt(_kRecordFps) ?? 10;        
    _recordWidth = _prefs.getInt(_kRecordWidth) ?? 480;        
    _recordMaxSeconds = _prefs.getInt(_kRecordMaxSeconds) ?? 10;        
    _enableMpvLog = _prefs.getBool(_kEnableMpvLog) ?? false;        
    _mpvLogLevel = _prefs.getString(_kMpvLogLevel) ?? 'warn';        
    _preferredDecodeFormat =
        _prefs.getString(_kPreferredDecodeFormat) ?? 'auto';        
    _subtitleDragEnabled = _prefs.getBool(_kSubtitleDragEnabled) ?? false;        
    _subtitleBilingual = _prefs.getBool(_kSubtitleBilingual) ?? false;        
    _subtitleTranslateLang =
        _prefs.getString(_kSubtitleTranslateLang) ?? 'en-US';        
    _subtitlePadL =
        _prefs.getDouble(_kSubtitlePadL) ?? defaultSubtitlePadL;        
    _subtitlePadR =
        _prefs.getDouble(_kSubtitlePadR) ?? defaultSubtitlePadR;        
    _subtitlePadB =
        _prefs.getDouble(_kSubtitlePadB) ?? defaultSubtitlePadB;        
    _defaultQnWifi = _prefs.getInt(_kDefaultQnWifi) ?? 116;        
    _defaultQnCellular = _prefs.getInt(_kDefaultQnCellular) ?? 80;        
    _defaultAudioQualityId =
        _prefs.getInt(_kDefaultAudioQualityId) ?? 0;        
    notifyListeners();
  }

                    
  Future<void> setShowFakeStatusBar(bool value) async {
    if (_showFakeStatusBar == value) return;
    _showFakeStatusBar = value;
    await _prefs.setBool(_kShowFakeStatusBar, value);
    notifyListeners();
  }

  Future<void> setEnableLongPressSpeed(bool value) async {
    if (_enableLongPressSpeed == value) return;
    _enableLongPressSpeed = value;
    await _prefs.setBool(_kEnableLongPressSpeed, value);
    notifyListeners();
  }

  Future<void> setEnableScreenshot(bool value) async {
    if (_enableScreenshot == value) return;
    _enableScreenshot = value;
    await _prefs.setBool(_kEnableScreenshot, value);
    notifyListeners();
  }

  Future<void> setHwdecMode(String value) async {
    if (_hwdecMode == value) return;
    _hwdecMode = value;
    await _prefs.setString(_kHwdecMode, value);
    notifyListeners();
  }

       
  Future<void> setHwdecEnabled(bool value) async {
    if (_hwdecEnabled == value) return;
    _hwdecEnabled = value;
    await _prefs.setBool(_kHwdecEnabled, value);
    notifyListeners();
  }

       
  Future<void> setHwdecOnlySupported(bool value) async {
    if (_hwdecOnlySupported == value) return;
    _hwdecOnlySupported = value;
    await _prefs.setBool(_kHwdecOnlySupported, value);
    notifyListeners();
  }

  Future<void> setLongPressInImmersive(bool value) async {
    if (_longPressInImmersive == value) return;
    _longPressInImmersive = value;
    await _prefs.setBool(_kLongPressInImmersive, value);
    notifyListeners();
  }

  Future<void> setVideoSync(String value) async {
    if (_videoSync == value) return;
    _videoSync = value;
    await _prefs.setString(_kVideoSync, value);
    notifyListeners();
  }

       
  Future<void> setLoadDanmakuOnResume(bool value) async {
    if (_loadDanmakuOnResume == value) return;
    _loadDanmakuOnResume = value;
    await _prefs.setBool(_kLoadDanmakuOnResume, value);
    notifyListeners();
  }

       
  Future<void> setShowDanmakuInScreenshot(bool value) async {
    if (_showDanmakuInScreenshot == value) return;
    _showDanmakuInScreenshot = value;
    await _prefs.setBool(_kShowDanmakuInScreenshot, value);
    notifyListeners();
  }

                  
  Future<void> setKeepWindowAspectRatio(bool value) async {
    if (_keepWindowAspectRatio == value) return;
    _keepWindowAspectRatio = value;
    await _prefs.setBool(_kKeepWindowAspectRatio, value);
    notifyListeners();
  }

                                              
  Future<void> setSuperResolutionMode(String value) async {
    if (_superResolutionMode == value) return;
    _superResolutionMode = value;
    await _prefs.setString(_kSuperResolution, value);
    notifyListeners();
  }

               
  Future<void> setSkipIntroOutro(bool value) async {
    if (_skipIntroOutro == value) return;
    _skipIntroOutro = value;
    await _prefs.setBool(_kSkipIntroOutro, value);
    notifyListeners();
  }

              
  Future<void> setAudioNormalization(String value) async {
    if (_audioNormalization == value) return;
    _audioNormalization = value;
    await _prefs.setString(_kAudioNormalization, value);
    notifyListeners();
  }

                       
  Future<void> setAudioOutputDevice(String value) async {
    if (_audioOutputDevice == value) return;
    _audioOutputDevice = value;
    await _prefs.setString(_kAudioOutputDevice, value);
    notifyListeners();
  }

                  
  Future<void> setShowSeekPreview(bool value) async {
    if (_showSeekPreview == value) return;
    _showSeekPreview = value;
    await _prefs.setBool(_kShowSeekPreview, value);
    notifyListeners();
  }

                                      
  Future<void> setPgcSkipMode(String value) async {
    if (_pgcSkipMode == value) return;
    _pgcSkipMode = value;
    await _prefs.setString(_kPgcSkipMode, value);
    notifyListeners();
  }

                             
  Future<void> setRecordFormat(String value) async {
    if (_recordFormat == value) return;
    _recordFormat = value;
    await _prefs.setString(_kRecordFormat, value);
    notifyListeners();
  }

                 
  Future<void> setRecordFps(int value) async {
    if (_recordFps == value) return;
    _recordFps = value;
    await _prefs.setInt(_kRecordFps, value);
    notifyListeners();
  }

                 
  Future<void> setRecordWidth(int value) async {
    if (_recordWidth == value) return;
    _recordWidth = value;
    await _prefs.setInt(_kRecordWidth, value);
    notifyListeners();
  }

                        
  Future<void> setRecordMaxSeconds(int value) async {
    if (_recordMaxSeconds == value) return;
    _recordMaxSeconds = value;
    await _prefs.setInt(_kRecordMaxSeconds, value);
    notifyListeners();
  }

                 
  Future<void> setEnableMpvLog(bool value) async {
    if (_enableMpvLog == value) return;
    _enableMpvLog = value;
    await _prefs.setBool(_kEnableMpvLog, value);
    notifyListeners();
  }

                                                         
  Future<void> setMpvLogLevel(String value) async {
    if (_mpvLogLevel == value) return;
    _mpvLogLevel = value;
    await _prefs.setString(_kMpvLogLevel, value);
    notifyListeners();
  }

                                         
  Future<void> setPreferredDecodeFormat(String value) async {
    if (_preferredDecodeFormat == value) return;
    _preferredDecodeFormat = value;
    await _prefs.setString(_kPreferredDecodeFormat, value);
    notifyListeners();
  }

              
  Future<void> setSubtitleDragEnabled(bool value) async {
    if (_subtitleDragEnabled == value) return;
    _subtitleDragEnabled = value;
    await _prefs.setBool(_kSubtitleDragEnabled, value);
    notifyListeners();
  }

              
  Future<void> setSubtitleBilingual(bool value) async {
    if (_subtitleBilingual == value) return;
    _subtitleBilingual = value;
    await _prefs.setBool(_kSubtitleBilingual, value);
    notifyListeners();
  }

                                        
  Future<void> setSubtitleTranslateLang(String value) async {
    if (_subtitleTranslateLang == value) return;
    _subtitleTranslateLang = value;
    await _prefs.setString(_kSubtitleTranslateLang, value);
    notifyListeners();
  }

                           
  Future<void> setSubtitlePadding({
    required double left,
    required double right,
    required double bottom,
  }) async {
    final changed = left != _subtitlePadL ||
        right != _subtitlePadR ||
        bottom != _subtitlePadB;
    _subtitlePadL = left;
    _subtitlePadR = right;
    _subtitlePadB = bottom;
    if (!changed) return;
    await _prefs.setDouble(_kSubtitlePadL, left);
    await _prefs.setDouble(_kSubtitlePadR, right);
    await _prefs.setDouble(_kSubtitlePadB, bottom);
    notifyListeners();
  }

                                
  Future<void> setDefaultQnWifi(int value) async {
    if (_defaultQnWifi == value) return;
    _defaultQnWifi = value;
    await _prefs.setInt(_kDefaultQnWifi, value);
    notifyListeners();
  }

                                
  Future<void> setDefaultQnCellular(int value) async {
    if (_defaultQnCellular == value) return;
    _defaultQnCellular = value;
    await _prefs.setInt(_kDefaultQnCellular, value);
    notifyListeners();
  }

                                        
  Future<void> setDefaultAudioQualityId(int value) async {
    if (_defaultAudioQualityId == value) return;
    _defaultAudioQualityId = value;
    await _prefs.setInt(_kDefaultAudioQualityId, value);
    notifyListeners();
  }
}