// lib/services/player_settings_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerSettingsService extends ChangeNotifier {
  static const _kShowFakeStatusBar = 'player_show_fake_status_bar';
  static const _kEnableLongPressSpeed = 'player_enable_long_press_speed';
  static const _kEnableScreenshot = 'player_enable_screenshot';
  static const _kHwdecMode = 'player_hwdec_mode';
  static const _kLongPressInImmersive = 'player_long_press_in_immersive';
  static const _kVideoSync = 'player_video_sync';
//  NEW
  static const _kLoadDanmakuOnResume = 'player_load_danmaku_on_resume';
  static const _kShowDanmakuInScreenshot = 'player_show_danmaku_in_screenshot';
//  NEW：播放器页仅允许等比例拉伸窗口
  static const _kKeepWindowAspectRatio = 'player_keep_window_aspect_ratio';
  static const _kSuperResolution = 'player_super_resolution';
//  NEW：跳过片头/片尾（BilibiliSponsorBlock，仅 BV+CID 时生效）
  static const _kSkipIntroOutro = 'player_skip_intro_outro';
//  NEW：mpv 日志（可选，细度可调）
  static const _kEnableMpvLog = 'player_enable_mpv_log';
  static const _kMpvLogLevel = 'player_mpv_log_level';
  static const _kPreferredDecodeFormat = 'player_preferred_decode_format';

  late SharedPreferences _prefs;

  bool _showFakeStatusBar = true;
  bool _enableLongPressSpeed = true;
  bool _enableScreenshot = true;
  String _hwdecMode = 'auto';
  bool _longPressInImmersive = true;
  String _videoSync = 'audio';
  bool _loadDanmakuOnResume = true; //  NEW 默认开启
  bool _showDanmakuInScreenshot = true; //  NEW 默认开启
  bool _keepWindowAspectRatio = true; //  NEW 默认开启
  String _superResolutionMode = 'disable'; //  NEW 默认关闭
  bool _skipIntroOutro = true; //  NEW 默认开启
  bool _enableMpvLog = false; //  NEW 默认关闭
  String _mpvLogLevel = 'warn'; //  NEW 默认 warn
  String _preferredDecodeFormat = 'auto'; //  NEW 默认自动

  // ─── Getters ───
  bool get showFakeStatusBar => _showFakeStatusBar;
  bool get enableLongPressSpeed => _enableLongPressSpeed;
  bool get enableScreenshot => _enableScreenshot;
  String get hwdecMode => _hwdecMode;
  bool get longPressInImmersive => _longPressInImmersive;
  String get videoSync => _videoSync;
  bool get loadDanmakuOnResume => _loadDanmakuOnResume; //  NEW
  bool get showDanmakuInScreenshot => _showDanmakuInScreenshot; //  NEW
  bool get keepWindowAspectRatio => _keepWindowAspectRatio; //  NEW
  String get superResolutionMode => _superResolutionMode; //  NEW
  bool get skipIntroOutro => _skipIntroOutro; //  NEW
  bool get enableMpvLog => _enableMpvLog; //  NEW
  String get mpvLogLevel => _mpvLogLevel; //  NEW
  String get preferredDecodeFormat => _preferredDecodeFormat; //  NEW

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _showFakeStatusBar = _prefs.getBool(_kShowFakeStatusBar) ?? true;
    _enableLongPressSpeed = _prefs.getBool(_kEnableLongPressSpeed) ?? true;
    _enableScreenshot = _prefs.getBool(_kEnableScreenshot) ?? true;
    _hwdecMode = _prefs.getString(_kHwdecMode) ?? 'auto';
    _longPressInImmersive = _prefs.getBool(_kLongPressInImmersive) ?? true;
    _videoSync = _prefs.getString(_kVideoSync) ?? 'audio';
    _loadDanmakuOnResume = _prefs.getBool(_kLoadDanmakuOnResume) ?? true; //  NEW
    _showDanmakuInScreenshot = _prefs.getBool(_kShowDanmakuInScreenshot) ?? true; //  NEW
    _keepWindowAspectRatio = _prefs.getBool(_kKeepWindowAspectRatio) ?? true; //  NEW
    _superResolutionMode = _prefs.getString(_kSuperResolution) ?? 'disable'; //  NEW
    _skipIntroOutro = _prefs.getBool(_kSkipIntroOutro) ?? true; //  NEW
    _enableMpvLog = _prefs.getBool(_kEnableMpvLog) ?? false; //  NEW
    _mpvLogLevel = _prefs.getString(_kMpvLogLevel) ?? 'warn'; //  NEW
    _preferredDecodeFormat =
        _prefs.getString(_kPreferredDecodeFormat) ?? 'auto'; //  NEW
    notifyListeners();
  }

  // ─── Setters ───
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

//  NEW
  Future<void> setLoadDanmakuOnResume(bool value) async {
    if (_loadDanmakuOnResume == value) return;
    _loadDanmakuOnResume = value;
    await _prefs.setBool(_kLoadDanmakuOnResume, value);
    notifyListeners();
  }

//  NEW
  Future<void> setShowDanmakuInScreenshot(bool value) async {
    if (_showDanmakuInScreenshot == value) return;
    _showDanmakuInScreenshot = value;
    await _prefs.setBool(_kShowDanmakuInScreenshot, value);
    notifyListeners();
  }

//  NEW：仅允许等比例拉伸窗口
  Future<void> setKeepWindowAspectRatio(bool value) async {
    if (_keepWindowAspectRatio == value) return;
    _keepWindowAspectRatio = value;
    await _prefs.setBool(_kKeepWindowAspectRatio, value);
    notifyListeners();
  }

//  NEW：超分辨率模式（disable / efficiency / quality）
  Future<void> setSuperResolutionMode(String value) async {
    if (_superResolutionMode == value) return;
    _superResolutionMode = value;
    await _prefs.setString(_kSuperResolution, value);
    notifyListeners();
  }

//  NEW：跳过片头/片尾
  Future<void> setSkipIntroOutro(bool value) async {
    if (_skipIntroOutro == value) return;
    _skipIntroOutro = value;
    await _prefs.setBool(_kSkipIntroOutro, value);
    notifyListeners();
  }

//  NEW：记录 mpv 日志
  Future<void> setEnableMpvLog(bool value) async {
    if (_enableMpvLog == value) return;
    _enableMpvLog = value;
    await _prefs.setBool(_kEnableMpvLog, value);
    notifyListeners();
  }

//  NEW：mpv 日志细度（error / warn / info / v / debug / trace）
  Future<void> setMpvLogLevel(String value) async {
    if (_mpvLogLevel == value) return;
    _mpvLogLevel = value;
    await _prefs.setString(_kMpvLogLevel, value);
    notifyListeners();
  }

//  NEW：首选视频解码格式（auto / avc / hevc / av1）
  Future<void> setPreferredDecodeFormat(String value) async {
    if (_preferredDecodeFormat == value) return;
    _preferredDecodeFormat = value;
    await _prefs.setString(_kPreferredDecodeFormat, value);
    notifyListeners();
  }
}