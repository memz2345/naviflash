// lib/services/settings_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

/// 内置浏览器 UA 模式（常态化保存）：仅把用户设置的 UA 在手机端 / 电脑端
/// 之间替换关键字（详见 browser_page.dart 的 uaToMobile / uaToDesktop）。
enum BrowserUaMode {
  /// 自动：跟随用户设置的 UA / 系统默认，不做关键字替换。
  auto('auto'),

  /// 电脑端：替换为桌面 UA。
  desktop('desktop'),

  /// 手机端：替换为移动 UA。
  mobile('mobile');

  const BrowserUaMode(this.code);

  final String code;

  static BrowserUaMode fromCode(String? code) => BrowserUaMode.values
      .firstWhere((m) => m.code == code, orElse: () => BrowserUaMode.auto);
}

/// B 站推荐数据来源（web 端推荐 / APP 端推荐）。
enum BiliRecommendSource {
  /// Web 端推荐（x/web-interface/wbi/index/top/feed/rcmd，无需登录也可看）。
  web('web'),

  /// APP 端推荐（app.bilibili.com/x/v2/feed/index，设备指纹即可获取）。
  app('app');

  const BiliRecommendSource(this.code);

  final String code;

  static BiliRecommendSource fromCode(String? code) =>
      BiliRecommendSource.values
          .firstWhere((s) => s.code == code, orElse: () => BiliRecommendSource.web);
}

class SettingsService extends ChangeNotifier {
  Color _themeSeedColor = Colors.blue;
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

  // �?新增：播放器高级设置持久化字�?
  double _playerDefaultRate = 1.0;
  String _playerEndBehavior = 'pause'; // pause, loop, exit
  bool _showPlayerStats = false;
  bool _autoPiPOnBackground = false;

//  新增：自动离线缓存播放过的视频（存储设置页开关）
  bool _autoOfflineCache = true;

  // �?新增：磁贴顺序持久化字段
  List<String> _tileOrder = [];

  // �?新增：图片切割磁贴碎片配�?
  List<Map<String, dynamic>> _imageSlices = [];

  // �?新增：侧边栏背景�?
  String? _drawerBackgroundPath;
  bool _hideWebDavInfo = false;
  // �?新增：显示缩�?
  double _displayScale = 1.0;

//  新增：开始屏幕 / Charm 相关设置
  bool _enableStartScreen = true;
  bool _enableCharm = true;
  bool _enableCharmGesture = true;
  bool _startScreenWarningDismissed = false;

//  新增：无痕模式（开启后不记录观看历史、不上报 B 站播放进度）
  bool _incognitoMode = false;

//  新增：屏幕帧率（DisplayMode）偏好，存 DisplayMode.toString()（如 "#0 0x0 @ 0Hz"）
  String? _displayMode;

  // �?新增：应用界面语言偏好（null=跟随系统，'zh' / 'en'）
  String? _appLocaleCode;

//  新增：内置浏览器剪贴板访问权限（默认允许，用户可在浏览器菜单中切换）
  bool _browserAllowClipboard = true;

//  新增：内置浏览器 UA 模式（自动 / 电脑端 / 手机端，默认自动）
  BrowserUaMode _browserUaMode = BrowserUaMode.auto;

//  新增：B 站推荐数据来源（web 端推荐 / APP 端推荐，默认 web）
  BiliRecommendSource _recommendSource = BiliRecommendSource.web;

//  新增：Hero 转场背景模糊（iOS 风格），关闭后恢复经典无模糊 Hero 效果
  bool _heroTransitionBlur = true;

//  新增：iOS 风格全局 push 转场（新页面右滑入 + 圆角渐变归零，
  //    旧页面左移 + 渐变模糊）；关闭后使用 Flutter 默认页面转场
  bool _iosPushTransition = true;
  double _iosPushTransitionCornerRadius = 26.0;

//  新增：页面背景图系统（expressive_app_bar 布局页面共用）：
  // 裁剪后的背景图文件 + 全局开关 + 强度（不透明度）+ 模糊
  String? _pageBackgroundPath;
  bool _pageBackgroundEnabled = false;
  double _pageBackgroundOpacity = 0.25;
  double _pageBackgroundBlur = 4.0;

//  新增：液态玻璃调校参数（LiquidGlassSettings），全局应用于所有玻璃表面
  double _liquidGlassThickness = 20.0;
  double _liquidGlassBlur = 10.0;
  double _liquidGlassTintOpacity = 0.0;
  double _liquidGlassSaturation = 1.0;
  double _liquidGlassRefractiveIndex = 1.3;
  double _liquidGlassLightIntensity = 0.0;
  double _liquidGlassAmbientStrength = 0.0;
  double _liquidGlassLightAngle = math.pi / 2;
  double _liquidGlassChromaticAberration = 0.02;

  /// 全局静态开关：供 FrostedHeroRoute 在路由构建时读取（无 BuildContext）。
  static bool heroTransitionBlurEnabled = true;

  /// 全局静态开关：供 NaviGlass 等在无 BuildContext 的场景（Overlay、
  /// Dialog）读取「高级玻璃渲染（片元着色器）」设置。
  static bool fragmentRenderingEnabled = true;

  /// 全局静态开关：供 GlassMenuSurface 等读取「禁用液态玻璃菜单」设置
  /// （开启后下拉菜单恢复传统毛玻璃样式，聊天页不受影响）。
  static bool liquidGlassMenusDisabled = false;

  /// 全局静态镜像：供无 BuildContext 的视频离线缓存服务读取
  /// 「自动离线缓存播放过的视频」开关。
  static bool autoOfflineCacheEnabled = true;

  /// 全局静态镜像：供 NaviGlass 等在无 BuildContext 的场景（Overlay、
  /// Dialog）读取「液态玻璃调校」参数（液态玻璃调校页即时更新）。
  static double liquidGlassThickness = 20.0;
  static double liquidGlassBlur = 10.0;
  static double liquidGlassTintOpacity = 0.0;
  static double liquidGlassSaturation = 1.0;
  static double liquidGlassRefractiveIndex = 1.3;
  static double liquidGlassLightIntensity = 0.0;
  static double liquidGlassAmbientStrength = 0.0;
  static double liquidGlassLightAngle = math.pi / 2;
  static double liquidGlassChromaticAberration = 0.02;

  bool get hideWebDavInfo => _hideWebDavInfo;
  Color get themeSeedColor => _themeSeedColor;
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

//  新增 Getters
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

//  应用界面语言偏好 Getters
  /// null = 跟随系统；否则为 BCP-47 标签（'zh-CN' / 'zh-TW' / 'zh-HK' / 'en-US'）。
  String? get appLocaleCode => _appLocaleCode;

  /// 供 MaterialApp.locale 使用：null 时跟随系统语言。
  /// 兼容完整标签（'zh-CN'）与旧版纯语言码（'zh'）。
  Locale? get appLocale {
    final code = _appLocaleCode;
    if (code == null) return null;
    final parts = code.split('-');
    if (parts.length < 2) return Locale(parts[0]);
    return Locale(parts[0], parts[1]);
  }

//  页面背景图系统 Getters
  String? get pageBackgroundPath => _pageBackgroundPath;
  bool get pageBackgroundEnabled => _pageBackgroundEnabled;
  double get pageBackgroundOpacity => _pageBackgroundOpacity;
  double get pageBackgroundBlur => _pageBackgroundBlur;

//  液态玻璃调校 Getters
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

  // �?新增 Getters
  double get playerDefaultRate => _playerDefaultRate;
  String get playerEndBehavior => _playerEndBehavior;
  bool get showPlayerStats => _showPlayerStats;
  bool get autoPiPOnBackground => _autoPiPOnBackground;
  bool get autoOfflineCache => _autoOfflineCache;
  List<String> get tileOrder => _tileOrder;
  List<Map<String, dynamic>> get imageSlices => _imageSlices;
  String? get drawerBackgroundPath => _drawerBackgroundPath;
  double get displayScale => _displayScale;

  SettingsService();

  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeSeedColor = Color(
      prefs.getInt('themeSeedColor') ?? Colors.blue.value,
    );
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

    // �?加载播放器设�?
    _playerDefaultRate = prefs.getDouble('playerDefaultRate') ?? 1.0;
    _playerEndBehavior = prefs.getString('playerEndBehavior') ?? 'pause';
    _showPlayerStats = prefs.getBool('showPlayerStats') ?? false;
    _autoPiPOnBackground = prefs.getBool('autoPiPOnBackground') ?? false;

//  加载自动离线缓存开关（静态镜像供无 BuildContext 的缓存服务读取）
    _autoOfflineCache = prefs.getBool('autoOfflineCache') ?? true;
    autoOfflineCacheEnabled = _autoOfflineCache;

    // �?加载磁贴顺序
    _tileOrder = prefs.getStringList('tileOrder') ?? [];

    // �?加载侧边栏背�?
    _drawerBackgroundPath = prefs.getString('drawerBackgroundPath');

    // �?加载显示缩放
    _displayScale = prefs.getDouble('displayScale') ?? 1.0;

//  加载开始屏幕 / Charm 设置
    _enableStartScreen = prefs.getBool('enableStartScreen') ?? true;
    _enableCharm = prefs.getBool('enableCharm') ?? true;
    _enableCharmGesture = prefs.getBool('enableCharmGesture') ?? true;
    _startScreenWarningDismissed =
        prefs.getBool('startScreenWarningDismissed') ?? false;

//  加载屏幕帧率偏好
    _displayMode = prefs.getString('displayMode');

//  加载应用界面语言偏好（旧版本存 'zh'/'en' → 规范化为完整标签）
    _appLocaleCode = _normalizeLocaleCode(prefs.getString('appLocaleCode'));

//  加载内置浏览器剪贴板访问权限
    _browserAllowClipboard = prefs.getBool('browserAllowClipboard') ?? true;

//  加载内置浏览器 UA 模式
    _browserUaMode = BrowserUaMode.fromCode(prefs.getString('browserUaMode'));

//  加载 B 站推荐数据来源
    _recommendSource = BiliRecommendSource.fromCode(
      prefs.getString('recommendSource'),
    );

//  加载 Hero 转场背景模糊开关
    _heroTransitionBlur = prefs.getBool('heroTransitionBlur') ?? true;
    heroTransitionBlurEnabled = _heroTransitionBlur;

//  加载 iOS 风格全局 push 转场设置
    _iosPushTransition = prefs.getBool('iosPushTransition') ?? true;
    _iosPushTransitionCornerRadius =
        prefs.getDouble('iosPushTransitionCornerRadius') ?? 26.0;

//  加载页面背景图系统
    _pageBackgroundPath = prefs.getString('pageBackgroundPath');
    _pageBackgroundEnabled = prefs.getBool('pageBackgroundEnabled') ?? false;
    _pageBackgroundOpacity = prefs.getDouble('pageBackgroundOpacity') ?? 0.25;
    _pageBackgroundBlur = prefs.getDouble('pageBackgroundBlur') ?? 4.0;

//  加载无痕模式开关
    _incognitoMode = prefs.getBool('incognitoMode') ?? false;

//  加载液态玻璃调校参数
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

    // �?加载图片切割碎片配置
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


  // �?新增：显示缩�?Setter
  Future<void> setDisplayScale(double value) async {
    final clamped = value.clamp(0.50, 2.00);
    if (_displayScale == clamped) return;
    _displayScale = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('displayScale', clamped);
    notifyListeners();
  }

//  应用界面语言偏好 Setter
  /// code 取 BCP-47 标签（'zh-CN' / 'zh-TW' / 'zh-HK' / 'en-US'）或 null（跟随系统）。
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

  /// 旧版本语言偏好迁移：'zh' → 'zh-CN'、'en' → 'en-US'，其余原样返回。
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

  // �?新增：图片切割碎�?Setter
  Future<void> setImageSlices(List<Map<String, dynamic>> slices) async {
    _imageSlices = List.from(slices);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('imageSlices', jsonEncode(_imageSlices));
    notifyListeners();
  }

  // �?新增：磁贴顺�?Setter
  Future<void> setTileOrder(List<String> order) async {
    _tileOrder = List.from(order);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tileOrder', _tileOrder);
    notifyListeners();
  }

  // �?新增：播放器设置 Setters
  Future<void> setPlayerDefaultRate(double value) async {
    if (_playerDefaultRate == value) return;
    _playerDefaultRate = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('playerDefaultRate', value);
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

  /// 自动离线缓存播放过的视频（存储设置页开关）。
  Future<void> setAutoOfflineCache(bool value) async {
    if (_autoOfflineCache == value) return;
    _autoOfflineCache = value;
    autoOfflineCacheEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoOfflineCache', value);
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

  Future<void> addCustomTheme(String name, Color color) async {
    _customThemes.add({'name': name, 'color': color.value});
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

//  无痕模式：开启后不记录观看历史、不上报 B 站播放进度
  bool get incognitoMode => _incognitoMode;
  Future<void> setIncognitoMode(bool value) async {
    _incognitoMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('incognitoMode', value);
    notifyListeners();
  }

  Future<void> setThemeSeedColor(Color color) async {
    _themeSeedColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeSeedColor', color.value);
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
        if (!await wallpaperDir.exists())
          await wallpaperDir.create(recursive: true);
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

  // �?新增：侧边栏背景�?Setters
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
        if (!await drawerBgDir.exists())
          await drawerBgDir.create(recursive: true);
        final fileName =
            'drawer_bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = '${drawerBgDir.path}/$fileName';
        await File(pickedFile.path).copy(savedPath);
        // 删除旧图
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

//  新增：页面背景图系统 Setters
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

  /// 保存裁剪后的背景图：复制到应用文档目录 page_backgrounds/，删除旧图。
  /// 成功后自动开启「显示页面背景图」开关。
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

  // ================= 开始屏幕 / Charm Setters =================

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

  /// 保存屏幕帧率偏好（DisplayMode.toString()，如 "#1 1080x2400 @ 120Hz"）
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

  /// 保存内置浏览器剪贴板访问权限（true = 允许网页读写剪贴板）。
  Future<void> setBrowserAllowClipboard(bool value) async {
    if (_browserAllowClipboard == value) return;
    _browserAllowClipboard = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('browserAllowClipboard', value);
    notifyListeners();
  }

  /// 保存内置浏览器 UA 模式（自动 / 电脑端 / 手机端）。
  Future<void> setBrowserUaMode(BrowserUaMode value) async {
    if (_browserUaMode == value) return;
    _browserUaMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('browserUaMode', value.code);
    notifyListeners();
  }

  /// 保存 B 站推荐数据来源（web 端推荐 / APP 端推荐）。
  Future<void> setRecommendSource(BiliRecommendSource value) async {
    if (_recommendSource == value) return;
    _recommendSource = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recommendSource', value.code);
    notifyListeners();
  }

  /// Hero 转场背景模糊（iOS 风格毛玻璃）；关闭后恢复经典无模糊 Hero 效果。
  Future<void> setHeroTransitionBlur(bool value) async {
    if (_heroTransitionBlur == value) return;
    _heroTransitionBlur = value;
    heroTransitionBlurEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('heroTransitionBlur', value);
    notifyListeners();
  }

  /// iOS 风格全局 push 转场开关；关闭后使用 Flutter 默认页面转场。
  Future<void> setIosPushTransition(bool value) async {
    if (_iosPushTransition == value) return;
    _iosPushTransition = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('iosPushTransition', value);
    notifyListeners();
  }

  /// iOS 风格转场新页面入场圆角（0 ~ 48，实时生效）。
  Future<void> setIosPushTransitionCornerRadius(double value) async {
    final clamped = value.clamp(0.0, 48.0).toDouble();
    if (_iosPushTransitionCornerRadius == clamped) return;
    _iosPushTransitionCornerRadius = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('iosPushTransitionCornerRadius', clamped);
    notifyListeners();
  }


  void _syncLiquidGlassStatics() {
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

  /// 一次性保存全部液态玻璃调校参数（调校页滑块拖动时调用）。
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
    // IPv4：仅允许内网段
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
    // IPv6：允许 ULA（fc00::/7）与链路本地（fe80::/10）
    final clean = ip.contains('%') ? ip.substring(0, ip.indexOf('%')) : ip;
    final addr = InternetAddress.tryParse(clean);
    if (addr == null || addr.type != InternetAddressType.IPv6) return false;
    final colon = clean.indexOf(':');
    if (colon <= 0) return false;
    final hextet = int.tryParse(clean.substring(0, colon), radix: 16);
    if (hextet == null) return false;
    if ((hextet & 0xFE00) == 0xFC00) return true; // fc00::/7
    if ((hextet & 0xFFC0) == 0xFE80) return true; // fe80::/10
    return false;
  }
}
