// lib/main.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:naviflash/widgets/xiaomi_freeform_media_query.dart'; //  小米小窗 padding 兜底 (flutter#161086)
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'screens/bilibili_recommend_page.dart';
import 'widgets/side_bar_shell.dart';
import 'screens/player.dart';
import 'screens/bilibili_search_page.dart';
import 'screens/my_cache_page.dart';
import 'screens/bilibili_video_page.dart' show openBilibiliVideo;
import 'services/jump_list_service.dart';
import 'services/app_shortcut_bridge.dart';
import 'services/log_service.dart';
import 'services/settings_service.dart';
import 'services/network_settings_service.dart';
import 'services/bilibili_translate_service.dart';
import 'services/bilibili_account_service.dart'; //  B 站账号
import 'services/bilibili_title_cache.dart'; //  全局翻译标题缓存
import 'services/display_mode_service.dart';
import 'services/app_locale_service.dart'; //  Android 13+ 按应用设置语言
import 'services/open_video_service.dart';
import 'services/player_settings_service.dart';
import 'services/play_history_service.dart';
import 'services/watch_history_service.dart';
import 'services/playlist_service.dart';
import 'services/favorites_service.dart'; //  本地收藏夹
import 'services/webdav_service.dart';
import 'services/notification_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:audio_service/audio_service.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'services/media_kit_audio_handler.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/ios_push_transition.dart';
import 'build_info.g.dart';

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

late MediaKitAudioHandler audioHandler;

// ================= 外部打开视频缓存（冷启动 UI 未就绪时暂存） =================
OpenVideoRequest? _pendingExternalVideo;

void _cachePendingExternalVideo(OpenVideoRequest request) {
  _pendingExternalVideo = request;
}

//  外部打开会话：连续打开时用序号区分「用户退出」与「被新视频替换」
int _externalSessionSeq = 0;
Timer? _externalNavTimer;

//  外部「打开方式」的视频 → 直接进入播放器（不写入播放历史）；
//   退出播放器（back / 返回键）→ 返回调用方应用，而不是回到应用主界面。
void navigateToExternalVideo(OpenVideoRequest request) {
  final context = globalNavigatorKey.currentContext;
  if (context == null) {
    _cachePendingExternalVideo(request);
    debugPrint('⏳ UI 未就绪，已缓存外部视频: ${request.name}');
    return;
  }

  if (!File(request.path).existsSync()) {
    showAppToast(
      context,
      AppLocalizations.of(context).openVideoFailed,
      error: true,
    );
    return;
  }

  //  去抖：连续打开时只保留最后一次跳转
  _externalNavTimer?.cancel();
  _externalNavTimer = Timer(const Duration(milliseconds: 120), () async {
    _externalNavTimer = null;
    final seq = ++_externalSessionSeq;
    final navigator = globalNavigatorKey.currentState;
    if (navigator == null) return;

    //  销毁上一个外部播放器（pop 会触发其 dispose → player.dispose()）
    navigator.popUntil((route) => route.isFirst);

    //  等旧播放器完全释放后再创建新的，避免新旧 player 并存冲突
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (seq != _externalSessionSeq) return; // 期间又收到新请求，本次作废
    if (!navigator.mounted) return;

    await navigator.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'external_video'),
        builder: (_) => MpvPlayerPage(
          videoUrl: request.path,
          title: request.name ?? L10n.current.externalVideo,
          //  外部打开的内容不记录播放历史
          recordHistory: false,
        ),
      ),
    );

    //  播放器被关闭（用户点 back / 系统返回键）→ 返回调用方应用
    if (seq == _externalSessionSeq) {
      debugPrint('📤 外部视频播放结束，返回调用方应用');
      await OpenVideoService.finishExternalSession();
    }
  });
  debugPrint('✅ 外部视频进入播放器: ${request.name}');
}

// =====================================================================
//  JumpList（Windows）与 App 长按快捷入口（Android / iOS）统一动作处理
//   动作串：search（B站搜索）/ offline（离线视频·我的缓存）/
//           recommend（推荐主页）/ video:<bvid>（最近观看的视频）
// =====================================================================
WatchHistoryService? _watchHistoryForJumpList;

void _handleExternalAction(String action) {
  debugPrint('🎯 外部快捷动作: $action');
  final navigator = globalNavigatorKey.currentState;
  if (navigator == null) {
    // 冷启动极早期（Navigator 尚未挂载）到达的动作：推迟到首帧后再执行，
    // 避免动作被静默丢弃（表现为长按快捷入口点击无反应）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (globalNavigatorKey.currentState != null) {
        _handleExternalAction(action);
      } else {
        debugPrint('⚠️ Navigator 仍不可用，丢弃快捷动作: $action');
      }
    });
    return;
  }

  if (action == 'recommend') {
    // 任务「推荐」：回到主页（根页面即 B站推荐流）
    navigator.popUntil((r) => r.isFirst);
    return;
  }

  final context = globalNavigatorKey.currentContext;
  if (context == null) return;

  if (action.startsWith('video:')) {
    final bvid = action.substring('video:'.length).trim();
    if (bvid.isEmpty) return;
    openBilibiliVideo(context, bvid: bvid);
    return;
  }

  Widget? page;
  if (action == 'search') {
    page = const BilibiliSearchPage();
  } else if (action == 'offline') {
    page = const MyCachePage(drawerMode: true);
  }
  if (page == null) {
    debugPrint('⚠️ 未知的外部快捷动作: $action');
    return;
  }
  navigator.push(MaterialPageRoute(builder: (_) => page!));
}

/// 由观看历史生成 JumpList「最近观看」条目（按 bvid 去重取最新 5 条）。
List<JumpListItem> _recentJumpListItems() {
  final svc = _watchHistoryForJumpList;
  if (svc == null) return const [];
  final seen = <String>{};
  final items = <JumpListItem>[];
  for (final e in svc.entries) {
    if (e.bvid.isEmpty) continue;
    if (!seen.add(e.bvid)) continue;
    final title = e.title.trim().replaceAll(RegExp(r'\s+'), ' ');
    items.add(
      JumpListItem(
        name: title.isEmpty ? 'BV ${e.bvid}' : title,
        action: 'video:${e.bvid}',
      ),
    );
    if (items.length >= 5) break;
  }
  return items;
}

Future<void> _refreshJumpListRecents() async {
  if (!Platform.isWindows) return;
  await JumpListService().updateRecentVideos(_recentJumpListItems());
}

/// 初始化各平台的快捷入口（在首帧后调用，保证 Navigator 可用）。
void _initShortcutsAndJumpList() {
  if (Platform.isAndroid || Platform.isIOS) {
    final bridge = AppShortcutBridge()..onAction = _handleExternalAction;
    bridge.initialize();
  }
  if (Platform.isWindows) {
    final jumpList = JumpListService()
      ..onAction = _handleExternalAction; // 已有实例运行时，原生热推送动作
    // 先注册热推送入口，再拉取冷启动参数，避免时序竞态
    jumpList.init();
    _watchHistoryForJumpList?.addListener(_refreshJumpListRecents);
    _refreshJumpListRecents();
    // 冷启动（无运行实例时由 JumpList 直接启动本进程）：拉取动作并执行
    jumpList.consumeLaunchAction().then((action) {
      if (action != null && action.isNotEmpty) _handleExternalAction(action);
    });
  }
}

void main() {
  runZonedGuarded(_runMain, (error, stack) {
    debugPrint('⚠️ 未捕获异常: $error\n$stack');
    LogService.crash('未捕获异常', 'ZONE_ERROR: $error\n$stack');
    _appendCrashLog('ZONE_ERROR: $error\n$stack');
  });
}

Future<void> _runMain() async {
  MediaKit.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  //  初始化全局日志服务（目录创建 + 清理过期日志），崩溃日志必写
  await LogService.initialize();
  await LogService.logAppStart(
    appName: 'NaviFlash',
    version: BuildInfo.buildCodename,
  );
  _initCrashLogging();

  await NotificationService().initialize();
  debugPrint('通知服务初始化完成');

  audioHandler = await AudioService.init(
    builder: () => MediaKitAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.memz2345.navi.flash.channel.audio',
      androidNotificationChannelName: L10n.current.audioChannelName,
      androidNotificationOngoing: true,
    ),
  );

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(400, 300));

    final prefs = await SharedPreferences.getInstance();
    final initWidth = prefs.getDouble('windowWidth') ?? 1024.0;
    final initHeight = prefs.getDouble('windowHeight') ?? 768.0;

    WindowOptions windowOptions = WindowOptions(
      size: Size(initWidth, initHeight),
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final settingsService = SettingsService();
  await settingsService.initialize();

  //  Android 13+「按应用设置语言」双向同步：
  //    系统设置 → 应用信息 → 语言 修改即时生效，应用内选择也回写系统级
  await AppLocaleService.attach(settingsService);

  //  初始化网络设置服务（连接模式 / Host 映射 / DoH）
  final networkSettingsService = NetworkSettingsService();
  await networkSettingsService.initialize();

  //  初始化 B 站 AI 翻译设置（语言 / 开关）
  final biliTranslateService = BilibiliTranslateService();
  await biliTranslateService.initialize();

  //  初始化全局翻译标题缓存（bvid → 译名，磁盘持久化）
  await BilibiliTitleCache().initialize();

  //  初始化 B 站账号服务（Cookie 登录 / 携带开关）
  final biliAccountService = BilibiliAccountService();
  await biliAccountService.initialize();

  //  恢复上次保存的屏幕帧率偏好（仅 Android；窗口偏好系统不持久保存）
  if (Platform.isAndroid) {
    await DisplayModeService.restorePreferred(settingsService);
  }

  //  初始化播放器设置服务
  final playerSettingsService = PlayerSettingsService();
  await playerSettingsService.initialize();

  //  初始化播放历史服务
  final playHistoryService = PlayHistoryService();
  await playHistoryService.initialize();

  //  初始化观看历史服务（浏览足迹：bvid + 退出时间，未登录也记录）
  final watchHistoryService = WatchHistoryService();
  await watchHistoryService.initialize();
  _watchHistoryForJumpList = watchHistoryService; //  Windows JumpList 最近观看数据源

  //  初始化播放列表服务
  final playlistService = PlaylistService();
  await playlistService.initialize();

  //  初始化本地收藏夹服务
  final favoritesService = FavoritesService();
  await favoritesService.initialize();

  final webDavService = WebDavService();

  runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      child: AppLifecycleWrapper(
        child: MyApp(
          settingsService: settingsService,
          networkSettingsService: networkSettingsService,
          biliTranslateService: biliTranslateService,
          biliAccountService: biliAccountService, //  NEW
          playerSettingsService: playerSettingsService,
          playHistoryService: playHistoryService,
          watchHistoryService: watchHistoryService, //  观看历史足迹
          playlistService: playlistService, //  NEW
          favoritesService: favoritesService, //  本地收藏夹
          webDavService: webDavService,
        ),
      ),
    ),
  );
}

//  通知点击兜底：仅清理通知，不做聊天跳转（NaviFlash 无聊天模块）
@pragma('vm:entry-point')
Future<void> notificationActionReceived(ReceivedAction receivedAction) async {
  final id = receivedAction.id;
  if (id != null) {
    await AwesomeNotifications().cancel(id);
  }
}

class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({super.key, required this.child});

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    debugPrint('生命周期变化：$state');
    final notifService = NotificationService();
    notifService.setAppForeground(state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void _initCrashLogging() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    final text = 'FLUTTER_ERROR: ${details.exception}\n${details.stack}';
    LogService.crash('Flutter 错误', text);
    _appendCrashLog(text);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    final text = 'PLATFORM_ERROR: $error\n$stack';
    LogService.crash('平台错误', text);
    _appendCrashLog(text);
    return false;
  };
}

/// 追加写崩溃日志（应用文档目录 navi_crash.log 为兜底；正式日志在
/// LogService 的应用数据目录 error/ 下），便于复现后排障。
void _appendCrashLog(String text) {
  try {
    getApplicationDocumentsDirectory().then((dir) async {
      final file = File('${dir.path}/navi_crash.log');
      final sink = file.openWrite(mode: FileMode.append);
      sink.write('\n===== ${DateTime.now().toIso8601String()} =====\n$text\n');
      await sink.flush();
      await sink.close();
    });
  } catch (_) {}
}

class MyApp extends StatelessWidget {
  final SettingsService settingsService;
  final NetworkSettingsService networkSettingsService;
  final BilibiliTranslateService biliTranslateService;
  final BilibiliAccountService biliAccountService; //  NEW
  final PlayerSettingsService playerSettingsService;
  final PlayHistoryService playHistoryService;
  final WatchHistoryService watchHistoryService; //  观看历史足迹
  final PlaylistService playlistService; //  NEW
  final FavoritesService favoritesService; //  本地收藏夹
  final WebDavService webDavService;

  const MyApp({
    super.key,
    required this.settingsService,
    required this.networkSettingsService,
    required this.biliTranslateService,
    required this.biliAccountService, //  NEW
    required this.playerSettingsService,
    required this.playHistoryService,
    required this.watchHistoryService, //  观看历史足迹
    required this.playlistService, //  NEW
    required this.favoritesService, //  本地收藏夹
    required this.webDavService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider.value(value: networkSettingsService),
        ChangeNotifierProvider.value(value: biliTranslateService),
        ChangeNotifierProvider.value(value: biliAccountService), //  NEW
        ChangeNotifierProvider.value(value: playerSettingsService),
        ChangeNotifierProvider.value(value: playHistoryService),
        ChangeNotifierProvider.value(value: watchHistoryService), //  观看历史足迹
        ChangeNotifierProvider.value(value: playlistService), //  NEW
        ChangeNotifierProvider.value(value: favoritesService), //  本地收藏夹
        ChangeNotifierProvider.value(value: webDavService),
      ],
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          return Consumer<SettingsService>(
            builder: (context, settings, child) {
              final useDynamic =
                  settings.useDynamicColor &&
                  lightDynamic != null &&
                  darkDynamic != null;

              final lightScheme = useDynamic
                  ? lightDynamic!
                  : ColorScheme.fromSeed(
                      seedColor: settings.themeSeedColor,
                      brightness: Brightness.light,
                    );

              final darkSeedScheme = ColorScheme.fromSeed(
                seedColor: settings.themeSeedColor,
                brightness: Brightness.dark,
              );
              final darkScheme = useDynamic ? darkDynamic! : darkSeedScheme;

              final darkSchemeWithPureBlack = settings.isPureBlackMode
                  ? darkScheme.copyWith(
                      background: Colors.black,
                      surface: Colors.black,
                      surfaceContainer: Colors.black,
                      surfaceContainerHigh: Colors.black,
                      surfaceContainerHighest: const Color(0xFF1C1C1E),
                      surfaceTint: Colors.transparent,
                    )
                  : darkScheme;

              final textTheme = TextTheme(
                bodyLarge: TextStyle(
                  fontWeight: _getFontWeight(settings.fontWeight),
                ),
                bodyMedium: TextStyle(
                  fontWeight: _getFontWeight(settings.fontWeight),
                ),
                bodySmall: TextStyle(
                  fontWeight: _getFontWeight(settings.fontWeight),
                ),
                titleLarge: TextStyle(
                  fontWeight: _getFontWeight(settings.fontWeight),
                ),
                titleMedium: TextStyle(
                  fontWeight: _getFontWeight(settings.fontWeight),
                ),
                titleSmall: TextStyle(
                  fontWeight: _getFontWeight(settings.fontWeight),
                ),
                labelLarge: TextStyle(
                  fontWeight: _getFontWeight(settings.fontWeight),
                ),
                labelMedium: TextStyle(
                  fontWeight: _getFontWeight(settings.fontWeight),
                ),
                labelSmall: TextStyle(
                  fontWeight: _getFontWeight(settings.fontWeight),
                ),
              );

              //  读取显示缩放比例
              final displayScale = settings.displayScale;

              //  iOS 风格全局 push 转场（显示设置中可开关 / 调圆角）：
              //    关闭时传 null → Flutter 各平台默认页面转场。
              final iosPushTransitions = settings.iosPushTransition
                  ? PageTransitionsTheme(
                      builders: <TargetPlatform, PageTransitionsBuilder>{
                        for (final TargetPlatform platform
                            in TargetPlatform.values)
                          platform: IosPushPageTransitionsBuilder(
                            cornerRadius:
                                settings.iosPushTransitionCornerRadius,
                          ),
                      },
                    )
                  : null;

              return GlobalMouseBackWrapper(
                child: MaterialApp(
                  navigatorKey: globalNavigatorKey,
                  title: 'NaviFlash',
                  // 全局滚动手感：Android 触屏统一 iOS 橡皮筋拉伸回弹
                  // （Material 默认的硬停 + 光晕在触屏上太违和），
                  // iOS 本就 Bouncing、桌面保持原生 Clamping 不动。
                  // 显式传了 physics 的组件（列表 / 轮播 / 翻页）优先级更高；
                  // TabBarView / PageView 的翻页 snap 由框架无条件用
                  // PageScrollPhysics 包裹，不受影响。
                  scrollBehavior: const NaviScrollBehavior(),
                  //  应用界面语言：由语言设置页选择，null 时跟随系统。
                  locale: settings.appLocale,
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                    AppLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('zh', 'CN'),
                    Locale('zh', 'TW'),
                    Locale('zh', 'HK'),
                    Locale('zh'),
                    Locale('en', 'US'),
                    Locale('en'),
                  ],
                  theme: ThemeData(
                    useMaterial3: true,
                    colorScheme: lightScheme,
                    textTheme: textTheme,
                    scaffoldBackgroundColor: Colors.transparent,
                    pageTransitionsTheme: iosPushTransitions,
                  ),
                  darkTheme: ThemeData(
                    useMaterial3: true,
                    colorScheme: darkSchemeWithPureBlack,
                    textTheme: textTheme,
                    scaffoldBackgroundColor: Colors.transparent,
                    pageTransitionsTheme: iosPushTransitions,
                  ),
                  themeMode: settings.themeMode,
                  builder: (context, child) {
                    L10n.setCurrent(AppLocalizations.of(context));
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    Color bgColor = Theme.of(context).colorScheme.surface;
                    if (isDark && settings.isPureBlackMode) {
                      bgColor = Colors.black;
                    }

                    //  全局界面缩放：整棵 UI 以「真实尺寸 / scale」的逻辑尺寸布局，
                    //    再用 Transform.scale 放大回真实屏幕 →
                    //    文字、图标、间距、布局全部等比缩放（而非仅缩放文字）。
                    //    注意：必须用 Positioned 显式给定逻辑尺寸——
                    //    非定位子节点会被 Stack 的宽松约束钳制到屏幕大小（导致缩放后留白）。
                    //  小米 HyperOS2/Android15 小窗(freeform)下 MediaQuery.padding.top 会返回
                    //    离谱值（640/737…），导致 SafeArea 布局错乱。先兜底修正，再走显示缩放逻辑。
                    //    详见 flutter/flutter#161086（Open）。
                    final mq = sanitizeXiaomiFreeformPadding(
                      MediaQuery.of(context),
                    );
                    final scaledChild = MediaQuery(
                      data: mq.copyWith(
                        // 文本由 Transform 统一缩放，避免双重缩放
                        textScaler: TextScaler.noScaling,
                        size: mq.size / displayScale,
                        padding: mq.padding / displayScale,
                        viewPadding: mq.viewPadding / displayScale,
                        viewInsets: mq.viewInsets / displayScale,
                      ),
                      child: Transform.scale(
                        scale: displayScale,
                        alignment: Alignment.topLeft,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [if (child != null) child],
                        ),
                      ),
                    );

                    return Stack(
                      fit: StackFit.loose,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(child: Container(color: bgColor)),
                        //  全局页面背景图（页面背景图系统，位于全部
                        //    UI 之下；透明背景页面自动透出，不透明页面
                        //    （如视频页/播放器）不受影响）
                        Positioned.fill(
                          child: const IgnorePointer(
                            child: PageBackground(),
                          ),
                        ),
                        if (child != null)
                          Positioned(
                            left: 0,
                            top: 0,
                            width: mq.size.width / displayScale,
                            height: mq.size.height / displayScale,
                            child: scaledChild,
                          ),
                      ],
                    );
                  },
                  home: const NaviHome(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  FontWeight _getFontWeight(double value) {
    if (value <= 100) return FontWeight.w100;
    if (value <= 200) return FontWeight.w200;
    if (value <= 300) return FontWeight.w300;
    if (value <= 400) return FontWeight.w400;
    if (value <= 500) return FontWeight.w500;
    if (value <= 600) return FontWeight.w600;
    if (value <= 700) return FontWeight.w700;
    if (value <= 800) return FontWeight.w800;
    return FontWeight.w900;
  }
}

// ================= 首页 =================
//  主页 = B 站推荐流：宽屏（≥768）走 SideBarShell（左侧可折叠侧边栏，
//  home 区块内嵌推荐流），窄屏直接以推荐页为根页面（自带返回/更多导航）。
class NaviHome extends StatefulWidget {
  const NaviHome({super.key});

  @override
  State<NaviHome> createState() => _NaviHomeState();
}

class _NaviHomeState extends State<NaviHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ① 消费外部「打开方式」传入的视频（冷启动）
      _consumeExternalVideo();
      // ② 注册外部视频热启动监听
      OpenVideoService.setOnVideoIntent((request) {
        if (!File(request.path).existsSync()) return;
        debugPrint('📺 收到外部视频打开请求: ${request.name}');
        navigateToExternalVideo(request);
      });
      // ③ 初始化 Windows JumpList / 移动端长按快捷入口
      _initShortcutsAndJumpList();
    });
  }

  @override
  void dispose() {
    _watchHistoryForJumpList?.removeListener(_refreshJumpListRecents);
    super.dispose();
  }

  Future<void> _consumeExternalVideo() async {
    final request =
        _pendingExternalVideo ?? await OpenVideoService.consumePending();
    _pendingExternalVideo = null;
    if (request == null) return;
    if (!File(request.path).existsSync()) return;
    Future.delayed(const Duration(milliseconds: 500), () {
      navigateToExternalVideo(request);
    });
  }

  @override
  Widget build(BuildContext context) {
    //  宽屏：侧边栏 Shell（主页区块 = 内嵌 B站推荐流）；
    //  窄屏：推荐页直接作为根页面。
    final isWide = MediaQuery.sizeOf(context).width >= 768;
    return isWide ? const SideBarShell() : const BilibiliRecommendPage();
  }
}

class GlobalMouseBackWrapper extends StatefulWidget {
  final Widget child;
  const GlobalMouseBackWrapper({super.key, required this.child});

  @override
  State<GlobalMouseBackWrapper> createState() => _GlobalMouseBackWrapperState();
}

/// 全局滚动手感：Android 触屏统一 iOS 橡皮筋（Bouncing），
/// 其余平台跟随 Material 默认（iOS 本就 Bouncing、桌面 Clamping）。
///
/// 行为被 `test/scroll_physics_test.dart` 锁定：android / iOS 顶层 physics
/// 必须是 Bouncing，windows 保持 Clamping，TabBarView 翻页 snap 不受影响。
class NaviScrollBehavior extends MaterialScrollBehavior {
  const NaviScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
    return super.getScrollPhysics(context);
  }
}

class _GlobalMouseBackWrapperState extends State<GlobalMouseBackWrapper> {
  void _handlePointerEvent(PointerEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      if (event is PointerDownEvent) {
        if (event.buttons & 8 != 0) {
          globalNavigatorKey.currentState?.maybePop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerEvent,
      onPointerUp: _handlePointerEvent,
      child: widget.child,
    );
  }
}
