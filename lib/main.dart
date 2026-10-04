                
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/widgets/xiaomi_freeform_media_query.dart';                                     
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:window_manager/window_manager.dart';
import 'package:naviflash/services/liquid_glass_bar_service.dart';
import 'package:naviflash/services/window_state_service.dart';
import 'package:naviflash/services/efficiency_mode_automation.dart';
import 'package:path_provider/path_provider.dart';
import 'src/app_dynamic_color.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'src/theme_seed_ext.dart';                              
import 'screens/bilibili_recommend_page.dart';
import 'widgets/side_bar_shell.dart';
import 'widgets/custom_toast.dart';                              
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'screens/player.dart';
import 'screens/bilibili_search_page.dart';
import 'screens/my_cache_page.dart';
import 'screens/bilibili_dynamics_page.dart';
import 'screens/watch_history_page.dart';
import 'screens/bilibili_video_page.dart'
    show openBilibiliVideo, resolveB23ShortLink;
import 'services/bili_uri_router.dart';
import 'services/link_utils.dart';
import 'services/memory_pressure_service.dart';
import 'services/jump_list_service.dart';
import 'services/app_shortcut_bridge.dart';
import 'services/fav_widget_service.dart';                
import 'services/log_service.dart';
import 'services/tts_export_licenses.dart';
import 'services/settings_service.dart';
import 'services/tts_download_service.dart';
import 'services/network_settings_service.dart';
import 'services/bilibili_translate_service.dart';
import 'services/bilibili_account_service.dart';          
import 'services/bilibili_favorite_service.dart';                  
import 'services/bilibili_title_cache.dart';             
import 'services/display_mode_service.dart';
import 'services/device_corner_service.dart';                     
import 'services/app_locale_service.dart';                        
import 'services/open_video_service.dart';
import 'services/player_settings_service.dart';
import 'services/player_shortcut_service.dart';
import 'services/play_history_service.dart';
import 'services/watch_history_service.dart';
import 'services/playlist_service.dart';
import 'services/favorites_service.dart';          
import 'services/my_reply_service.dart';                
import 'services/webdav_service.dart';
import 'services/notification_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:audio_service/audio_service.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'services/media_kit_audio_handler.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/fav_widget_folder_picker.dart';
import 'package:naviflash/widgets/edge_scroll_haptic.dart';
import 'package:naviflash/widgets/navi_overscroll.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/ios_push_transition.dart';
import 'package:naviflash/widgets/mini_player_layer.dart';
import 'build_info.g.dart';

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

late MediaKitAudioHandler audioHandler;

                                                              
OpenVideoRequest? _pendingExternalVideo;

                                    
                                         
                                              
Future<OpenVideoRequest?>? _pendingExternalVideoFetch;

void _cachePendingExternalVideo(OpenVideoRequest request) {
  _pendingExternalVideo = request;
}

                                    
int _externalSessionSeq = 0;
Timer? _externalNavTimer;

                                                      
                                        
String _externalVideoUrl(String path) =>
    Platform.isWindows ? Uri.file(path).toString() : path;

                                   
                                           
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

  debugPrint('✅ 外部视频进入播放器: ${request.name}');

                                     
                                  
  if (_externalSessionSeq == 0) {
    final navigator = globalNavigatorKey.currentState;
    if (navigator == null) {
      _cachePendingExternalVideo(request);
      return;
    }
    final seq = ++_externalSessionSeq;
    navigator
        .push(
          MaterialPageRoute(
            settings: const RouteSettings(name: 'external_video'),
            builder: (_) => MpvPlayerPage(
              videoUrl: _externalVideoUrl(request.path),
              title: request.name ?? L10n.current.externalVideo,
                                
              recordHistory: false,
            ),
          ),
        )
        .then((_) {
          if (seq == _externalSessionSeq) {
            debugPrint('📤 外部视频播放结束，返回调用方应用');
            OpenVideoService.finishExternalSession();
          }
        });
    return;
  }

                           
  _externalNavTimer?.cancel();
  _externalNavTimer = Timer(const Duration(milliseconds: 120), () async {
    _externalNavTimer = null;
    final seq = ++_externalSessionSeq;
    final navigator = globalNavigatorKey.currentState;
    if (navigator == null) return;

                                                       
    navigator.popUntil((route) => route.isFirst);

                                        
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (seq != _externalSessionSeq) return;                 
    if (!navigator.mounted) return;

    await navigator.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'external_video'),
        builder: (_) => MpvPlayerPage(
          videoUrl: _externalVideoUrl(request.path),
          title: request.name ?? L10n.current.externalVideo,
                            
          recordHistory: false,
        ),
      ),
    );

                                         
    if (seq == _externalSessionSeq) {
      debugPrint('📤 外部视频播放结束，返回调用方应用');
      await OpenVideoService.finishExternalSession();
    }
  });
}

                                                                        
                                                      
                                          
                                                   
                                                                        
WatchHistoryService? _watchHistoryForJumpList;

void _handleExternalAction(String action) {
  debugPrint('🎯 外部快捷动作: $action');
  final navigator = globalNavigatorKey.currentState;
  if (navigator == null) {
                                             
                                 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (globalNavigatorKey.currentState != null) {
        _handleExternalAction(action);
      } else {
        debugPrint('⚠️ Navigator 仍不可用，丢弃快捷动作: $action');
      }
    });
    return;
  }

  if (action == 'widget_refresh') {
                               
    unawaited(FavWidgetService.refresh());
    return;
  }

  if (action == 'widget_pick_folder') {
                                 
    unawaited(_pickFavWidgetFolder());
    return;
  }

  if (action == 'recommend') {
                              
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

  if (action.startsWith('uri:')) {
                                                   
                                                                   
    unawaited(
      _openExternalUri(context, action.substring('uri:'.length).trim()),
    );
    return;
  }

  Widget? page;
  if (action == 'search') {
    page = const BilibiliSearchPage();
  } else if (action == 'offline') {
    page = const MyCachePage(drawerMode: true);
  } else if (action == 'dynamics') {
                                     
    page = const BilibiliDynamicsPage();
  } else if (action == 'history') {
                             
    page = const WatchHistoryPage();
  }
  if (page == null) {
    debugPrint('⚠️ 未知的外部快捷动作: $action');
    return;
  }
  navigator.push(MaterialPageRoute(builder: (_) => page!));
}

                                                           
   
                                                   
                                                           
Future<void> _openExternalUri(BuildContext context, String raw) async {
  if (raw.isEmpty) return;
  var url = raw;
  final uri = Uri.tryParse(url);
  if (uri != null && uri.host.toLowerCase().endsWith('b23.tv')) {
    final resolved = await resolveB23ShortLink(url);
    if (resolved != null && resolved.isNotEmpty) url = resolved;
  }
  if (!context.mounted) return;
  debugPrint('🔗 外部链接: $url');
  if (!openBiliUri(context, url)) {
                                   
    await openLinkInBuiltInBrowser(context, url: url, confirm: false);
  }
}

                                   
   
                                                      
                                   
Future<void> _pickFavWidgetFolder() async {
  final navContext = globalNavigatorKey.currentContext;
  if (navContext == null) return;
  final l10n = AppLocalizations.of(navContext);
  if (!BilibiliFavoriteService.isLoggedIn) {
    showAppToast(navContext, l10n.favWidgetNeedLogin);
    return;
  }
  final picked = await showFavWidgetFolderPicker(navContext);
  if (picked == null) return;
  await SettingsService.setFavWidgetFolderIdGlobal(picked.id);
  await FavWidgetService.refreshNow();
  if (!navContext.mounted) return;
  showAppToast(navContext, l10n.favWidgetFolderSwitched(picked.title));
}

                                               
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

                                        
void _initShortcutsAndJumpList() {
  if (Platform.isAndroid || Platform.isIOS) {
    final bridge = AppShortcutBridge()..onAction = _handleExternalAction;
    bridge.initialize();
  }
  if (Platform.isAndroid) {
                                        
                                  
    Future<void>.delayed(const Duration(seconds: 4), () {
      unawaited(FavWidgetService.refresh());
    });
  }
  if (Platform.isWindows) {
                                          
                                             
                       
    unawaited(OpenVideoService.registerFileAssociations());
    final jumpList = JumpListService()
      ..onAction = _handleExternalAction;                   
                               
    jumpList.init();
    _watchHistoryForJumpList?.addListener(_refreshJumpListRecents);
    _refreshJumpListRecents();
                                            
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

                                                
                                              
                                                    
  PaintingBinding.instance.imageCache
    ..maximumSize = 500
    ..maximumSizeBytes = 64 << 20;

                                     
  registerTtsExportLicenses();

                                    
                                    
                                        
                                        
                                 
                                              
  if (Platform.isAndroid || Platform.isWindows) {
    OpenVideoService.setOnVideoIntent((request) {
      if (!File(request.path).existsSync()) return;
      debugPrint('📺 收到外部视频打开请求: ${request.name}');
      navigateToExternalVideo(request);
    });
    _pendingExternalVideoFetch = OpenVideoService.consumePending();
  }

  await LiquidGlassWidgets.initialize();
                                     
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

                                                
                                  
    final startup = await WindowStateService.loadStartupState();

    WindowOptions windowOptions = WindowOptions(
      size: Size(startup.width, startup.height),
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
                                                   
                        
      if (startup.maximized) {
        try {
          await windowManager.maximize();
        } catch (e) {
          if (kDebugMode) debugPrint('[Window] 恢复最大化失败: $e');
        }
      }
      await windowManager.focus();
    });
  }

  final settingsService = SettingsService();
  await settingsService.initialize();

                                              
                                     
  unawaited(TtsDownloadService.instance.initialize());

                                     
                                    
  WindowStateService.instance.attach(settingsService);

                               
                                           
  await AppLocaleService.attach(settingsService);

                                     
  final networkSettingsService = NetworkSettingsService();
  await networkSettingsService.initialize();

                              
  final biliTranslateService = BilibiliTranslateService();
  await biliTranslateService.initialize();

                                  
  await BilibiliTitleCache().initialize();

                                   
  final biliAccountService = BilibiliAccountService();
  await biliAccountService.initialize();

                                          
  if (Platform.isAndroid) {
    await DisplayModeService.restorePreferred(settingsService);
  }

                                    
                                          
  await DeviceCornerService.load();

                
  final playerSettingsService = PlayerSettingsService();
  await playerSettingsService.initialize();

                                     
  await PlayerShortcutService.instance.initialize();

               
  final playHistoryService = PlayHistoryService();
  await playHistoryService.initialize();

                                        
  final watchHistoryService = WatchHistoryService();
  await watchHistoryService.initialize();
  _watchHistoryForJumpList = watchHistoryService;                             

               
  final playlistService = PlaylistService();
  await playlistService.initialize();

                
  final favoritesService = FavoritesService();
  await favoritesService.initialize();

                                          
  final myReplyService = MyReplyService.instance;
  await myReplyService.initialize();

  final webDavService = WebDavService();

                                                        
                                              
  SmartDialog.config.toast = SmartConfigToast(
    displayType: SmartToastType.onlyRefresh,
  );

  runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      child: AppLifecycleWrapper(
        child: MyApp(
          settingsService: settingsService,
          networkSettingsService: networkSettingsService,
          biliTranslateService: biliTranslateService,
          biliAccountService: biliAccountService,        
          playerSettingsService: playerSettingsService,
          playHistoryService: playHistoryService,
          watchHistoryService: watchHistoryService,           
          playlistService: playlistService,        
          favoritesService: favoritesService,          
          myReplyService: myReplyService,          
          webDavService: webDavService,
        ),
      ),
    ),
  );
}

                                        
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
    if (state == AppLifecycleState.resumed) {
                                           
      unawaited(FavWidgetService.refreshIfStale());
    }
  }

  @override
  void didHaveMemoryPressure() {
    debugPrint('⚠️ 系统内存压力：清空 imageCache 并广播释放可重建状态');
    MemoryPressureService.handleMemoryPressure();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void _initCrashLogging() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    final text = 'FLUTTER_ERROR: ${details.exception}\n${details.stack}';
                                                
                                                    
    if (!_shouldWriteCrashLog('${details.exception}')) return;
    LogService.crash('Flutter 错误', text);
    _appendCrashLog(text);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    final text = 'PLATFORM_ERROR: $error\n$stack';
    if (!_shouldWriteCrashLog('$error')) return false;
    LogService.crash('平台错误', text);
    _appendCrashLog(text);
    return false;
  };
}

                                                
final Map<String, DateTime> _recentCrashAt = <String, DateTime>{};
int _suppressedCrashCount = 0;
const Duration _crashThrottle = Duration(seconds: 5);

bool _shouldWriteCrashLog(String key) {
  final now = DateTime.now();
  final last = _recentCrashAt[key];
  if (last != null && now.difference(last) < _crashThrottle) {
    _suppressedCrashCount++;
    return false;
  }
  _recentCrashAt[key] = now;
  if (_recentCrashAt.length > 64) _recentCrashAt.clear();
                                   
  if (_suppressedCrashCount > 0) {
    final n = _suppressedCrashCount;
    _suppressedCrashCount = 0;
    _appendCrashLog('（上一次同类错误后又出现 $n 次，已合并）');
  }
  return true;
}

                                           
                                         
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
  final BilibiliAccountService biliAccountService;        
  final PlayerSettingsService playerSettingsService;
  final PlayHistoryService playHistoryService;
  final WatchHistoryService watchHistoryService;           
  final PlaylistService playlistService;        
  final FavoritesService favoritesService;          
  final MyReplyService myReplyService;          
  final WebDavService webDavService;

  const MyApp({
    super.key,
    required this.settingsService,
    required this.networkSettingsService,
    required this.biliTranslateService,
    required this.biliAccountService,        
    required this.playerSettingsService,
    required this.playHistoryService,
    required this.watchHistoryService,           
    required this.playlistService,        
    required this.favoritesService,          
    required this.myReplyService,          
    required this.webDavService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider.value(value: networkSettingsService),
        ChangeNotifierProvider.value(value: biliTranslateService),
        ChangeNotifierProvider.value(value: biliAccountService),        
        ChangeNotifierProvider.value(value: playerSettingsService),
        ChangeNotifierProvider.value(value: playHistoryService),
        ChangeNotifierProvider.value(value: watchHistoryService),           
        ChangeNotifierProvider.value(value: playlistService),        
        ChangeNotifierProvider.value(value: favoritesService),          
        ChangeNotifierProvider.value(value: myReplyService),          
        ChangeNotifierProvider.value(value: webDavService),
      ],
      child: AppDynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          return Consumer<SettingsService>(
            builder: (context, settings, child) {
              final useDynamic =
                  settings.useDynamicColor &&
                  lightDynamic != null &&
                  darkDynamic != null;

                                                    
                                                           
                                                         
              final lightScheme = useDynamic
                  ? lightDynamic
                  : settings.themeSeedColor.asColorSchemeSeed(
                      settings.schemeVariant,
                      Brightness.light,
                    );

              final darkSeedScheme = settings.themeSeedColor.asColorSchemeSeed(
                settings.schemeVariant,
                Brightness.dark,
              );
              final darkScheme = useDynamic ? darkDynamic : darkSeedScheme;

              final darkSchemeWithPureBlack = settings.isPureBlackMode
                  ? darkScheme.copyWith(
                      surface: Colors.black,
                                                        
                                                               
                                                      
                                                                      
                                            
                      surfaceDim: Colors.black,
                      surfaceContainerLowest: Colors.black,
                      surfaceContainerLow: Colors.black,
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

                          
              final displayScale = settings.displayScale;

                                                   
                                                  
                                                
              final iosPushTransitions = settings.iosPushTransition
                  ? PageTransitionsTheme(
                      builders: <TargetPlatform, PageTransitionsBuilder>{
                        for (final TargetPlatform platform
                            in TargetPlatform.values)
                          platform: IosPushPageTransitionsBuilder(
                            cornerRadius: DeviceCornerService.resolveFor(
                              settings,
                            ),
                          ),
                      },
                    )
                  : null;

              return GlobalMouseBackWrapper(
                child: MaterialApp(
                  navigatorKey: globalNavigatorKey,
                  title: 'NaviFlash',
                                                    
                                                  
                                                        
                                                         
                                                           
                                               
                  scrollBehavior: const NaviScrollBehavior(),
                                                 
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
                                                                
                                    
                  navigatorObservers: [
                    FlutterSmartDialog.observer,
                                                         
                    liquidGlassBarRouteObserver,
                  ],
                  builder: FlutterSmartDialog.init(
                    toastBuilder: CustomToast.new,
                    builder: (context, child) {
                      L10n.setCurrent(AppLocalizations.of(context));
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      Color bgColor = Theme.of(context).colorScheme.surface;
                      if (isDark && settings.isPureBlackMode) {
                        bgColor = Colors.black;
                      }

                                                              
                                                        
                                                       
                                                        
                                                                 
                                                                                        
                                                                          
                                                            
                      final mq = sanitizeXiaomiFreeformPadding(
                        MediaQuery.of(context),
                      );
                      final scaledChild = MediaQuery(
                        data: mq.copyWith(
                                                      
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
                            children: [
                                                           
                              if (child != null) EdgeScrollHaptic(child: child),
                            ],
                          ),
                        ),
                      );

                      return Stack(
                        fit: StackFit.loose,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(child: Container(color: bgColor)),
                                                  
                                                      
                                               
                          Positioned.fill(
                            child: const IgnorePointer(child: PageBackground()),
                          ),
                          if (child != null)
                            Positioned(
                              left: 0,
                              top: 0,
                              width: mq.size.width / displayScale,
                              height: mq.size.height / displayScale,
                              child: scaledChild,
                            ),
                                                       
                                                           
                          const MiniPlayerLayer(),
                        ],
                      );
                    },
                  ),
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
                               
      _consumeExternalVideo();
                      
      OpenVideoService.setOnVideoIntent((request) {
        if (!File(request.path).existsSync()) return;
        debugPrint('📺 收到外部视频打开请求: ${request.name}');
        navigateToExternalVideo(request);
      });
                                           
      _initShortcutsAndJumpList();
                                             
      if (Platform.isWindows &&
          context.read<SettingsService>().fileAssociationDefault) {
        unawaited(OpenVideoService.registerFileAssociations(asDefault: true));
      }
                                                
                                             
                                                           
      if (Platform.isWindows) {
        unawaited(
          EfficiencyModeAutomation.instance.start(
            enabled: context.read<SettingsService>().efficiencyMode,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _watchHistoryForJumpList?.removeListener(_refreshJumpListRecents);
    super.dispose();
  }

  Future<void> _consumeExternalVideo() async {
                                  
    var request = _pendingExternalVideo;
    _pendingExternalVideo = null;
                                          
    if (request == null && _pendingExternalVideoFetch != null) {
      request = await _pendingExternalVideoFetch;
      _pendingExternalVideoFetch = null;
    }
                                               
                                                     
                                                           
                                
    request ??= await OpenVideoService.consumePending();
    if (request == null) return;
    if (!File(request.path).existsSync()) return;
                                     
    navigateToExternalVideo(request);
  }

  @override
  Widget build(BuildContext context) {
                                      
                      
    final isWide = MediaQuery.sizeOf(context).width >= 768;
    return isWide
        ? const SideBarShell()
                                                                     
        : BilibiliRecommendPage(key: BilibiliRecommendPage.navKey);
  }
}

class GlobalMouseBackWrapper extends StatefulWidget {
  final Widget child;
  const GlobalMouseBackWrapper({super.key, required this.child});

  @override
  State<GlobalMouseBackWrapper> createState() => _GlobalMouseBackWrapperState();
}

                                    
                                                 
                                                                     
                                    
                                     
   
                                                               
                                                               
class NaviScrollBehavior extends MaterialScrollBehavior {
  const NaviScrollBehavior();

                                            
                                      
                                        
                                              
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
                                         
                                            
    return buildNaviOverscrollIndicator(context, child, details);
  }
}

class _GlobalMouseBackWrapperState extends State<GlobalMouseBackWrapper> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

                            
                                 
                                    
  bool _handleKeyEvent(KeyEvent event) {
                                                   
                        
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      globalNavigatorKey.currentState?.maybePop();
    }
    return false;
  }

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
