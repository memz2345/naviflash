// lib/screens/bilibili_recommend_page.dart
//
// B 站推荐页（参考 PiliPlus 首页布局）：
//   - 五个 tab：推荐 / 热门 / 番剧 / 分区 / 直播（替代标题位置）
//   - 推荐 tab 支持 Web 端 / APP 端两种数据源（在设置 → 账号页切换，
//     持久化到设置）；未登录也可获取基础推荐
//   - 热门 tab：x/web-interface/popular；番剧 tab：/pgc/season/index/result
//   - 直播 tab：services/bilibili_live_service.dart（推荐直播间，
//     卡片与视频卡片同款，点击进直播间查看页）
//   - 触底加载动画与搜索页一致（LoadingIndicatorM3E + 已全部加载）
//   - 单列 / 多列切换为视频页同款 FAB（状态全局共享 + 持久化）
//   - 下拉刷新 / 触底加载更多 / 长按右键菜单 / 封面 Hero / AI 标题翻译
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_bangumi_page.dart';
import 'package:naviflash/screens/bilibili_popular_list_page.dart';
import 'package:naviflash/screens/bilibili_region_page.dart';
import 'package:naviflash/screens/bilibili_search_page.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/screens/bilibili_live_room_page.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_hot_service.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/services/bilibili_recommend_service.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:naviflash/services/bilibili_translate_api.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/link_utils.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/app_drawer.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/feed_loading_overlay.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/long_press_glass_tab_switcher.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/MetroTile.dart';
import 'package:naviflash/widgets/cover_menu_sheet.dart';
import 'package:naviflash/widgets/search_video_menu.dart';

/// 单个 tab 的分页状态（推荐 / 热门 / 番剧 / 直播 共用）。
class _TabState<T> {
  List<T> items = [];
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  String? error;

  /// 页号：推荐 = freshIdx（0 起）；热门 / 番剧 = 页码 - 1（0 起）。
  int page = 0;

  /// 待播放入场动画的 key 集合（首次加载 / 下拉刷新新插入的卡片，
  /// 与搜索页 _FreshSlideIn 同款：下滑 + 淡入，动画播完后清空）。
  final Set<String> freshKeys = {};

  // ── 网格行变化动画状态（多列布局下列数或行数变化时卡片平滑平移） ──
  int prevCols = 0;
  int prevCount = 0;
  String? prevFirstKey;
  final Map<int, Offset> itemTranslations = {};
}

class BilibiliRecommendPage extends StatefulWidget {
  /// 宽屏 SideBarShell 内嵌模式：不显示返回按钮，背景透明
  /// （由 Shell 画布统一提供）。
  final bool embeddedInShell;

  const BilibiliRecommendPage({super.key, this.embeddedInShell = false});

  // ── 单列 / 多列状态：全局共享并持久化（与相关视频页一致） ──
  static final ValueNotifier<bool> _gridMode = ValueNotifier(true);
  static bool _gridLoaded = false;

  static ValueNotifier<bool> get gridModeNotifier => _gridMode;
  static void toggleGridMode() {
    _gridMode.value = !_gridMode.value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('bili_recommend_grid_mode', _gridMode.value),
    );
  }

  @override
  State<BilibiliRecommendPage> createState() => _BilibiliRecommendPageState();
}

class _BilibiliRecommendPageState extends State<BilibiliRecommendPage>
    with TickerProviderStateMixin {
  /// 多列网格列数：按可用宽度自适应（每张卡片目标宽度约 [kVideoCardTargetWidth]），
  /// 至少 2 列、至多 8 列，与搜索页同款。
  static const double kVideoCardTargetWidth = 200.0;
  static const int kVideoCardMinColumns = 2;
  static const int kVideoCardMaxColumns = 8;

  late final AnimationController _gridRowAnimCtrl;

  static final _TabState<BiliRecommendItem> _rcmd = _TabState();
  static final _TabState<BiliRecommendItem> _hot = _TabState();
  static final _TabState<BiliBangumiItem> _bangumi = _TabState();
  static final _TabState<LiveRoomItem> _live = _TabState();

  /// 番剧 tab 顶部轮播图（/pgc/page/channel BANNER 模块，增强内容，
  /// 拉取失败时留空自动隐藏轮播）。
  static List<BiliBangumiBannerItem> _bangumiBanners = [];

  /// 番剧 tab 热门榜单（channel 响应 RANK 模块 sub_items）。
  static List<BiliBangumiRankItem> _bangumiRankItems = [];

  /// 番剧 tab「继续看」（guess 接口 recent_watch，需登录）。
  static List<BiliBangumiContinueItem> _bangumiContinueItems = [];
  static bool _bangumiContinueLoaded = false;

  /// 热门页相关搜索（热搜词）。
  static List<String> _hotwords = [];
  static bool _hotwordsLoaded = false;

  /// 热门页顶部入口（云控）：由 gRPC Popular/Index 下发（icon / title / uri /
  /// 数量均服务端控制）；拉取失败 / 为空时回退本地 [_kHotEntranceFallback]。
  static List<BiliHotEntrance> _hotEntrances = [];
  static bool _hotEntrancesLoaded = false;

  /// 轮播布局：M3 center-aligned hero，一次显示 3 张——
  /// 中间 7/9 大图 + 左右各 1/9 露出的邻图。
  static const List<int> _kBangumiCarouselWeights = [1, 7, 1];

  /// 轮播控制器 + 自动播放定时器（4 秒一帧，到末尾跳回开头循环，
  /// 仅番剧 tab 可见时推进，用户拖动时暂停）。
  final CarouselController _bangumiCarouselCtrl = CarouselController();
  Timer? _bangumiCarouselTimer;

  /// 加权布局下推进一帧的滚动步长（首个权重 × 视口 / 权重和）。
  double _bangumiCarouselStep = 0;

  /// 轮播可见性探测（10s 图片刷新要求首图控件在屏幕内）。
  final GlobalKey _bangumiCarouselKey = GlobalKey();

  /// 10 秒图片刷新定时器：仅当首图在屏幕内时重新拉取轮播数据。
  Timer? _bangumiBannerRefreshTimer;
  bool _bangumiBannerLoading = false;

  /// 推荐页顶部轮播（与番剧首图同款交互：加权 CarouselView +
  /// 自动播放 + 拖动暂停）：数据取自推荐 feed 首屏前 [kRcmdBannerCount]
  /// 条视频（已过滤广告，无运营广告位）。
  static const int kRcmdBannerCount = 5;
  List<BiliRecommendItem> _rcmdBanners = [];
  final CarouselController _rcmdCarouselCtrl = CarouselController();
  Timer? _rcmdCarouselTimer;
  double _rcmdCarouselStep = 0;

  final ScrollController _rcmdScroll = ScrollController();
  final ScrollController _hotScroll = ScrollController();
  final ScrollController _bangumiScroll = ScrollController();
  final ScrollController _liveScroll = ScrollController();

  /// 推荐数据源（从设置读取，设置里改动后自动重新加载推荐 tab）。
  BiliRecommendSource _source = BiliRecommendSource.web;

  /// tab 控制器（搜索页同款 oval tab）。
  late final TabController _tabController;

  /// 分区页 key（点击当前 tab 时滚回顶部）。
  final GlobalKey<BilibiliRegionPageState> _regionKey =
      GlobalKey<BilibiliRegionPageState>();

  /// 各 feed 的下拉刷新 key（0 直播 / 1 推荐 / 2 热门 / 3 番剧）。
  /// 点击当前 tab / 长按刷新时用 show() 亮出下拉加载器；
  /// 全屏 3e 只保留给该 feed 首次进入（无内容）时。
  final List<GlobalKey<RefreshIndicatorState>> _feedRefreshKeys =
      List.generate(4, (_) => GlobalKey<RefreshIndicatorState>());

  /// 主页 Scaffold key：左上入口用它打开全局侧边栏（AppDrawer）。
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// 顶栏以 oval tab 形式展示的页（分区走右侧图标按钮，不占 oval 位）。
  /// 物理顺序即视觉顺序（直播 0 在最前，推荐 1 次之……），这样从推荐页
  /// 向左滑可直接滑到直播 tab；默认进入仍是推荐页（initialIndex = 1）。
  static const List<int> _kOvalTabs = [0, 1, 2, 3];

  /// tab 页标题（oval tab 与长按菜单共用），按下标对应物理 tab。
  static const List<String> _kTabLabels = [
    '直播',
    '推荐',
    '热门',
    '番剧',
    '分区',
  ];

  /// AI 翻译后的标题覆盖表（bvid → 英文标题）。
  final Map<String, String> _titleOverrides = {};

  /// 「查看原文」原地切换的 bvid 集合。
  final Set<String> _showOriginalTitles = {};

  bool _gridMode = true;

  /// 热门 tab「相关搜索」是否展开（默认折叠，点击标题行右侧 v 展开）。
  bool _hotSearchExpanded = false;

  /// initState 缓存的 SettingsService 引用：dispose 时 widget 已 deactivate，
  /// context.read 会抛「Looking up a deactivated widget's ancestor is unsafe」，
  /// 必须在 initState 里取好引用、dispose 直接用。
  late final SettingsService _settings;

  @override
  void initState() {
    super.initState();
    _settings = context.read<SettingsService>();
    _source = _settings.recommendSource;
    _tabController = TabController(length: 5, initialIndex: 1, vsync: this)
      ..addListener(_onTabChanged);
    _gridRowAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _loadGridState();
    BilibiliRecommendPage._gridMode.addListener(_onGridModeChanged);
    _rcmdScroll.addListener(
      () => _onScroll(_rcmdScroll, _loadRcmdMore),
    );
    _hotScroll.addListener(() => _onScroll(_hotScroll, _loadHotMore));
    _bangumiScroll.addListener(
      () => _onScroll(_bangumiScroll, _loadBangumiMore),
    );
    _liveScroll.addListener(() => _onScroll(_liveScroll, _loadLiveMore));
    // 设置里切换推荐数据源 → 自动刷新推荐 tab
    _settings.addListener(_onSettingsChanged);
    // 底栏切换不刷新：静态缓存已有一屏数据时跳过首屏加载
    if (_rcmd.items.isEmpty) {
      _loadRcmd(forceRefresh: true);
    } else {
      _translateTitles(_rcmd.items);
    }
    // 轮播图片 10s 定时刷新（tick 内守卫：仅首图在屏幕内时执行）
    _startBangumiBannerRefresh();
  }

  @override
  void dispose() {
    _bangumiCarouselTimer?.cancel();
    _bangumiBannerRefreshTimer?.cancel();
    _rcmdCarouselTimer?.cancel();
    _bangumiCarouselCtrl.dispose();
    _rcmdCarouselCtrl.dispose();
    _tabController.dispose();
    BilibiliRecommendPage._gridMode.removeListener(_onGridModeChanged);
    _settings.removeListener(_onSettingsChanged);
    _rcmdScroll.dispose();
    _hotScroll.dispose();
    _bangumiScroll.dispose();
    _liveScroll.dispose();
    _gridRowAnimCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 3) {
      // 切到番剧 tab：启动轮播自动播放（tick 守卫会自愈等待轮播构建）
      _startBangumiCarouselAutoPlay();
    } else if (_tabController.index == 1) {
      // 切回推荐 tab：启动推荐轮播自动播放
      _startRcmdCarouselAutoPlay();
    }
    if (mounted) setState(() {});
  }

  /// 点击当前 tab：滚回顶部并刷新；点击其他 tab：切换（与搜索页一致）。
  void _onTabTap(int index) {
    if (_tabController.index == index) {
      if (index == 4) {
        // 分区页：滚回顶部（静态分区表，无需刷新）
        _regionKey.currentState?.scrollToTop();
        return;
      }
      final sc = switch (index) {
        1 => _rcmdScroll,
        2 => _hotScroll,
        0 => _liveScroll,
        _ => _bangumiScroll,
      };
      if (sc.hasClients && sc.offset > 0) {
        sc.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      // 刷新用下拉加载器呈现（feed 未构建时退化为直接重拉）
      _refreshCurrentFeed(index);
    } else {
      _tabController.animateTo(index);
    }
  }

  /// 用下拉加载器刷新指定 feed：show() 会自行调用该 feed 的
  /// onRefresh（load(forceRefresh: true, viaRefresh: true)）。
  void _refreshCurrentFeed(int index) {
    final state = _feedRefreshKeys[index].currentState;
    if (state != null) {
      state.show();
      return;
    }
    _forceLoadTab(index);
  }

  /// 直接重拉指定 feed（不经过下拉指示器；供 feed 未构建等兜底场景）。
  void _forceLoadTab(int index) {
    switch (index) {
      case 1:
        _loadRcmd(forceRefresh: true);
      case 2:
        _loadHot(forceRefresh: true);
      case 0:
        _loadLive(forceRefresh: true);
      default:
        _loadBangumi(forceRefresh: true);
    }
  }

  // ═════════════════════════════════════════
  //  全局侧边栏（AppDrawer，B 站版传统抽屉）
  // ═════════════════════════════════════════

  /// 打开全局侧边栏（主页入口/从侧边栏进入的页面共用同一抽屉）。
  void _openSideMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _loadGridState() async {
    if (BilibiliRecommendPage._gridLoaded) {
      _gridMode = BilibiliRecommendPage._gridMode.value;
      return;
    }
    BilibiliRecommendPage._gridLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    BilibiliRecommendPage._gridMode.value =
        prefs.getBool('bili_recommend_grid_mode') ?? true;
    _gridMode = BilibiliRecommendPage._gridMode.value;
  }

  void _onGridModeChanged() {
    if (!mounted) return;
    setState(() => _gridMode = BilibiliRecommendPage._gridMode.value);
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final source = context.read<SettingsService>().recommendSource;
    if (source == _source) return;
    _source = source;
    _loadRcmd(forceRefresh: true);
  }

  void _onScroll(ScrollController controller, VoidCallback loadMore) {
    if (!controller.hasClients) return;
    final pos = controller.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      loadMore();
    }
  }

  // ═════════════════════════════════════════
  //  加载逻辑
  // ═════════════════════════════════════════

  /// 通用视频列表加载（推荐 / 热门共用）。
  ///
  /// [forceRefresh] 重拉第 1 页；[viaRefresh] = 由下拉加载器驱动
  /// （下拉手势 / show() 调出），此时即使列表为空也保留当前空态 / 错误
  /// 视图，状态交给下拉圈，避免全屏加载器与下拉圈叠加闪烁。
  Future<void> _loadVideoTab(
    _TabState<BiliRecommendItem> data,
    Future<BiliRecommendResult<BiliRecommendItem>> Function(int page)
    fetcher, {
    bool forceRefresh = false,
    bool viaRefresh = false,
  }) async {
    if (!forceRefresh && (data.loading || data.loadingMore)) return;
    setState(() {
      if (forceRefresh) {
        // 统一加载器约定：
        //  - 首次进入（无内容且非下拉指示器驱动）→ 全屏 3e 加载器；
        //  - 已有内容 / 下拉指示器驱动的刷新 → 保留当前列表，由
        //    下拉加载器显示状态，不再整页闪回加载圈。
        data.loading = data.items.isEmpty && !viaRefresh;
        data.loadingMore = false;
        data.error = null;
      } else {
        data.loadingMore = true;
      }
    });
    final result = await fetcher(data.page);
    if (!mounted) return;
    switch (result) {
      case BiliRecommendOk(:final items):
        // 去重（Hero 同名 tag 不允许重复出现）：
        // - 单批内按 bvid 去重；
        // - 加载更多时还需剔除与已有列表重复的 bvid（推荐接口分页
        //   可能返回已加载项，同一 bvid 在网格中出现两次 → 同名
        //   Hero tag 重复 → 点击视频时抛「There are multiple heroes
        //   that share the same tag within a subtree」）
        final seen = <String>{};
        final deduped = items
            .where((v) => v.bvid.isNotEmpty && seen.add(v.bvid))
            .toList();
        setState(() {
          if (forceRefresh) {
            data.items = deduped;
            data.freshKeys
              ..clear()
              ..addAll(deduped.map((v) => v.bvid));
          } else {
            final existing = data.items.map((v) => v.bvid).toSet();
            final fresh = deduped
                .where((v) => !existing.contains(v.bvid))
                .toList();
            data.items = [...data.items, ...fresh];
          }
          data.page += 1;
          data.hasMore = deduped.isNotEmpty;
          data.loading = false;
          data.loadingMore = false;
          data.error = null;
        });
        // 推荐 tab 首屏（首次进入 / 下拉刷新 / 点击 tab 刷新）：
        // 取前几条视频作为顶部轮播（无广告，数据即推荐 feed 本身）
        if (data == _rcmd && forceRefresh && deduped.isNotEmpty) {
          final banners = deduped.take(kRcmdBannerCount).toList();
          setState(() => _rcmdBanners = banners);
          _startRcmdCarouselAutoPlay();
        }
        _translateTitles(data.items);
        if (forceRefresh && deduped.isNotEmpty) {
          // 动画播完后清空标记（360ms 动画 + 80ms 延迟 + 余量）
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() => data.freshKeys.clear());
            }
          });
        }
      case BiliRecommendError(:final detail):
        setState(() {
          data.loading = false;
          data.loadingMore = false;
          if (forceRefresh || data.items.isEmpty) {
            data.error = detail;
          }
        });
    }
  }

  /// 推荐 tab（数据源来自设置）。
  Future<void> _loadRcmd({
    bool forceRefresh = false,
    bool viaRefresh = false,
  }) {
    return _loadVideoTab(
      _rcmd,
      (page) => BilibiliRecommendService.fetch(
        source: _source,
        freshIdx: page,
      ),
      forceRefresh: forceRefresh,
      viaRefresh: viaRefresh,
    );
  }

  void _loadRcmdMore() {
    if (_rcmd.loading || _rcmd.loadingMore || !_rcmd.hasMore) return;
    _loadRcmd();
  }

  /// 直播 tab（结构对齐 [_loadVideoTab]：按 roomId 去重，不参与 AI 标题翻译）。
  Future<void> _loadLive({
    bool forceRefresh = false,
    bool viaRefresh = false,
  }) async {
    final data = _live;
    if (!forceRefresh && (data.loading || data.loadingMore)) return;
    setState(() {
      if (forceRefresh) {
        data.loading = data.items.isEmpty && !viaRefresh;
        data.loadingMore = false;
        data.error = null;
        // 直播推荐是分页接口（page 1/2/3 内容不同），下拉刷新要回到第 1 页
        // （视频 tab 的推荐走 freshIdx 递增流，不需要归零）
        data.page = 0;
      } else {
        data.loadingMore = true;
      }
    });
    final result =
        await BilibiliLiveService.fetchRecommend(page: data.page + 1);
    if (!mounted) return;
    switch (result) {
      case LiveOk<LiveRoomItem>(:final items, :final hasMore):
        final seen = <int>{};
        final deduped = items
            .where((v) => v.roomId > 0 && seen.add(v.roomId))
            .toList();
        setState(() {
          if (forceRefresh) {
            data.items = deduped;
            data.freshKeys
              ..clear()
              ..addAll(deduped.map((v) => v.roomId.toString()));
          } else {
            final existing = data.items.map((v) => v.roomId).toSet();
            final fresh =
                deduped.where((v) => !existing.contains(v.roomId)).toList();
            data.items = [...data.items, ...fresh];
          }
          data.page += 1;
          data.hasMore = hasMore && deduped.isNotEmpty;
          data.loading = false;
          data.loadingMore = false;
          data.error = null;
        });
        if (forceRefresh && deduped.isNotEmpty) {
          // 与视频 tab 同款：入场动画播完后清空标记
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) setState(() => data.freshKeys.clear());
          });
        }
      case LiveError<LiveRoomItem>(:final detail):
        setState(() {
          data.loading = false;
          data.loadingMore = false;
          if (forceRefresh || data.items.isEmpty) data.error = detail;
        });
    }
  }

  void _loadLiveMore() {
    if (_live.loading || _live.loadingMore || !_live.hasMore) return;
    _loadLive();
  }

  /// 热门 tab。
  Future<void> _loadHot({
    bool forceRefresh = false,
    bool viaRefresh = false,
  }) {
    if (forceRefresh) {
      // 下拉刷新 / 点击 tab 刷新：重拉云控入口与热搜词
      _hotwordsLoaded = false;
      _hotEntrancesLoaded = false;
    }
    // 云控入口：首屏懒加载 / 下拉刷新 / 点击 tab 刷新都要拉取
    //（成功一次后由 [_hotEntrancesLoaded] 防重，失败不置位可重试）
    _loadHotEntrances();
    _loadHotwords();
    return _loadVideoTab(
      _hot,
      (page) => BilibiliRecommendService.fetchPopular(pn: page + 1),
      forceRefresh: forceRefresh,
      viaRefresh: viaRefresh,
    );
  }

  /// 拉取热门页相关搜索（热搜词；失败静默隐藏；成功一次后防重）。
  Future<void> _loadHotwords() async {
    if (_hotwordsLoaded) return;
    final words = await BilibiliRecommendService.fetchHotwords();
    if (!mounted || words.isEmpty) return;
    setState(() {
      _hotwords = words;
      _hotwordsLoaded = true;
    });
  }

  void _loadHotMore() {
    if (_hot.loading || _hot.loadingMore || !_hot.hasMore) return;
    _loadHot();
  }

  /// 番剧 tab。
  Future<void> _loadBangumi({
    bool forceRefresh = false,
    bool viaRefresh = false,
  }) async {
    final data = _bangumi;
    if (!forceRefresh && (data.loading || data.loadingMore)) return;
    setState(() {
      if (forceRefresh) {
        data.loading = data.items.isEmpty && !viaRefresh;
        data.loadingMore = false;
        data.error = null;
      } else {
        data.loadingMore = true;
      }
    });
    final result = await BilibiliRecommendService.fetchBangumi(
      page: data.page + 1,
    );
    if (!mounted) return;
    switch (result) {
      case BiliRecommendOk(:final items):
        // 去重（Hero 同名 tag 不允许重复出现）：单批内去重 + 加载更多
        // 时剔除与已有列表重复的 seasonId
        final seen = <String>{};
        final deduped = items
            .where((v) => seen.add(v.seasonId.toString()))
            .toList();
        setState(() {
          if (forceRefresh) {
            data.items = deduped;
            data.freshKeys
              ..clear()
              ..addAll(deduped.map((v) => v.seasonId.toString()));
          } else {
            final existing = data.items
                .map((v) => v.seasonId.toString())
                .toSet();
            final fresh = deduped
                .where((v) => !existing.contains(v.seasonId.toString()))
                .toList();
            data.items = [...data.items, ...fresh];
          }
          data.page += 1;
          data.hasMore = deduped.isNotEmpty;
          data.loading = false;
          data.loadingMore = false;
          data.error = null;
        });
        // 首屏（首次进入 / 下拉刷新 / 点击 tab 刷新）加载完顺带拉轮播 / 榜单 / 继续看，
        // 触底加载更多不重复拉
        if (data.page == 1 && deduped.isNotEmpty) {
          _loadBangumiChannel();
          _loadBangumiContinue();
        }
        if (forceRefresh && deduped.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() => data.freshKeys.clear());
            }
          });
        }
      case BiliRecommendError(:final detail):
        setState(() {
          data.loading = false;
          data.loadingMore = false;
          if (forceRefresh || data.items.isEmpty) {
            data.error = detail;
          }
        });
    }
  }

  void _loadBangumiMore() {
    if (_bangumi.loading || _bangumi.loadingMore || !_bangumi.hasMore) return;
    _loadBangumi();
  }

  /// 批量 AI 翻译标题（静默失败，不影响原文）。
  Future<void> _translateTitles(List<BiliRecommendItem> items) async {
    if (items.isEmpty) return;
    final translate = BilibiliTranslateService.instance;
    if (!translate.enabled) return;
    final list = <({String bvid, String title})>[];
    final overrides = <String, String>{};
    for (final v in items) {
      if (v.bvid.isEmpty || v.title.isEmpty) continue;
      final cached = BilibiliTitleCache.translatedTitle(v.bvid);
      if (cached != null) {
        overrides[v.bvid] = cached;
      } else {
        list.add((bvid: v.bvid, title: v.title));
      }
    }
    if (overrides.isNotEmpty && mounted) {
      setState(() => _titleOverrides.addAll(overrides));
    }
    if (list.isEmpty) return;
    final remote = await BilibiliTranslateApi.translateTitles(list);
    if (!mounted || remote.isEmpty) return;
    BilibiliTitleCache.rememberAll(remote);
    setState(() => _titleOverrides.addAll(remote));
  }

  // ═════════════════════════════════════════
  //  点击 / 菜单
  // ═════════════════════════════════════════

  /// 卡片展示用标题：优先本地已翻译，再查全局缓存，否则原文。
  String _titleFor(BiliRecommendItem item) {
    if (_showOriginalTitles.contains(item.bvid)) return item.title;
    final local = _titleOverrides[item.bvid];
    if (local != null && local.isNotEmpty) return local;
    return BilibiliTitleCache.displayTitle(item.bvid, item.title);
  }

  void _open(BiliRecommendItem item) {
    // 与搜索页同款 iOS 开 App 整页放大转场：整卡 Hero 飞行期间背景
    // 渐变模糊，本页（IosBackdropScale）同步向中心缩小。
    FocusManager.instance.primaryFocus?.unfocus();
    openBilibiliVideo(
      context,
      bvid: item.bvid,
      initialTitle: _titleFor(item),
      initialCover: item.cover,
      heroTag: 'bili_video_${item.bvid}',
    );
  }

  void _openBangumi(BiliBangumiItem item) {
    FocusManager.instance.primaryFocus?.unfocus();
    openBilibiliBangumi(
      context,
      seasonId: item.seasonId,
      initialTitle: item.title,
      initialCover: item.cover,
      heroTag: 'bili_bangumi_${item.seasonId}',
    );
  }

  /// 拉取番剧首页运营页数据（轮播 + 热门榜单；失败静默；防重入）。
  Future<void> _loadBangumiChannel() async {
    if (_bangumiBannerLoading) return;
    _bangumiBannerLoading = true;
    final result = await BilibiliRecommendService.fetchBangumiChannel();
    _bangumiBannerLoading = false;
    if (!mounted) return;
    if (result.banners.isEmpty && result.ranks.isEmpty) return;
    setState(() {
      if (result.banners.isNotEmpty) _bangumiBanners = result.banners;
      if (result.ranks.isNotEmpty) _bangumiRankItems = result.ranks;
    });
    if (result.banners.isNotEmpty) _startBangumiCarouselAutoPlay();
  }

  /// 拉取番剧「继续看」（需登录；成功一次后不再重复请求，
  /// 未登录 / 失败静默隐藏该区块）。
  Future<void> _loadBangumiContinue() async {
    if (_bangumiContinueLoaded) return;
    final account = BilibiliAccountService.instance;
    if (!account.isLoggedIn) return;
    if (account.cookieHeaderFor(BiliCookieScope.video) == null) return;
    final items = await BilibiliRecommendService.fetchBangumiContinue();
    if (!mounted || items.isEmpty) return;
    setState(() {
      _bangumiContinueItems = items;
      _bangumiContinueLoaded = true;
    });
  }

  /// 启动 10s 图片刷新：仅在首图控件位于屏幕内（番剧 tab 可见 +
  /// 轮播未滚出视口）时重新拉取轮播数据，不在屏幕内跳过本次。
  void _startBangumiBannerRefresh() {
    _bangumiBannerRefreshTimer?.cancel();
    _bangumiBannerRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      if (_tabController.index != 3) return; // 非番剧 tab
      if (!_isBangumiCarouselOnScreen()) return; // 首图不在屏幕内
      _loadBangumiChannel();
    });
  }

  /// 轮播首图控件是否在屏幕内（GlobalKey → RenderBox 全局矩形与
  /// 屏幕竖向区间是否有交集）。
  bool _isBangumiCarouselOnScreen() {
    final ctx = _bangumiCarouselKey.currentContext;
    if (ctx == null) return false;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return false;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final screen = MediaQuery.sizeOf(ctx);
    return rect.bottom > 0 && rect.top < screen.height;
  }

  /// 启动轮播自动播放（幂等：先取消旧定时器）。
  /// tick 内的守卫保证只在番剧 tab 可见、轮播已构建、至少 2 张时推进。
  void _startBangumiCarouselAutoPlay() {
    _bangumiCarouselTimer?.cancel();
    _bangumiCarouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_tabController.index != 3) return; // 番剧 tab 不可见时暂停
      if (_bangumiBanners.length < 2) return;
      if (!_bangumiCarouselCtrl.hasClients) return; // 轮播尚未构建
      final pos = _bangumiCarouselCtrl.position;
      final step = _bangumiCarouselStep;
      if (step <= 0) return;
      // infinite 模式下 maxScrollExtent 为无穷，pixels 持续累加即无限循环；
      // 非 infinite 兜底：到末尾回卷到开头
      if (pos.maxScrollExtent.isFinite &&
          pos.pixels + step >= pos.maxScrollExtent - 1) {
        pos.jumpTo(0);
      }
      _bangumiCarouselCtrl.animateTo(
        pos.pixels + step,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  /// 启动推荐轮播自动播放（与番剧轮播同款，幂等）。
  /// tick 内守卫：仅推荐 tab 可见、至少 2 张、轮播已构建时推进。
  void _startRcmdCarouselAutoPlay() {
    _rcmdCarouselTimer?.cancel();
    _rcmdCarouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_tabController.index != 1) return; // 推荐 tab 不可见时暂停
      if (_rcmdBanners.length < 2) return;
      if (!_rcmdCarouselCtrl.hasClients) return;
      final pos = _rcmdCarouselCtrl.position;
      final step = _rcmdCarouselStep;
      if (step <= 0) return;
      if (pos.maxScrollExtent.isFinite &&
          pos.pixels + step >= pos.maxScrollExtent - 1) {
        pos.jumpTo(0);
      }
      _rcmdCarouselCtrl.animateTo(
        pos.pixels + step,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  /// 推荐页轮播：与番剧首图同款 Material 3 [CarouselView.weighted]
  /// 中心式布局（flexWeights [1, 7, 1]），16:9 大图、吸附切换、自动播放。
  /// 数据为推荐 feed 首屏视频（无广告）。
  Widget _buildRcmdCarousel(ColorScheme cs, AppLocalizations l10n) {
    final banners = _rcmdBanners;
    if (banners.length < 2) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;
    final viewport = width - 32;
    final weights = _kBangumiCarouselWeights;
    final sum = weights[0] + weights[1] + weights[2];
    final middleExtent = viewport * weights[1] / sum;
    final height = middleExtent * 9 / 16;
    _rcmdCarouselStep = viewport * weights[0] / sum;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SizedBox(
        height: height,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            // 用户拖动时暂停自动播放，松手后恢复
            if (n is ScrollStartNotification && n.dragDetails != null) {
              _rcmdCarouselTimer?.cancel();
            } else if (n is ScrollEndNotification) {
              _startRcmdCarouselAutoPlay();
            }
            return false;
          },
          child: CarouselView.weighted(
            controller: _rcmdCarouselCtrl,
            flexWeights: weights,
            itemSnapping: true,
            consumeMaxWeight: false,
            infinite: true,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            itemClipBehavior: Clip.antiAlias,
            onTap: (i) => _openRcmdBanner(banners[i % banners.length]),
            children: [
              for (final item in banners) _rcmdCarouselCard(cs, item),
            ],
          ),
        ),
      ),
    );
  }

  /// 推荐轮播卡片：16:9 高清封面 + 底部渐变 + 标题 + 时长角标，
  /// 封面包 Hero（tag 与列表卡片不同，避免同名冲突）。
  Widget _rcmdCarouselCard(ColorScheme cs, BiliRecommendItem item) {
    final cover = item.cover.startsWith('//')
        ? 'https:${item.cover}'
        : item.cover;
    final hq = cover.isEmpty ? '' : '$cover@640w_400h_1c.webp';
    final card = Stack(
      fit: StackFit.expand,
      children: [
        _coverImage(hq, aspect: 16 / 9),
        // 底部渐变遮罩
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.62),
              ],
            ),
          ),
        ),
        // 标题 + 播放信息（左下角）
        Positioned(
          left: 14,
          right: 14,
          bottom: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titleFor(item),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Colors.black45, blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              // 播放信息行：两侧邻卡（1/9 宽）内容区很窄，文字必须可收缩
              // （Flexible + ellipsis），否则横向 RenderFlex 溢出
              Row(
                children: [
                  if (item.view > 0)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                          Flexible(
                            child: Text(
                              _fmtCount(item.view),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  if (item.duration > 0)
                    Flexible(
                      child: Text(
                        _fmtDur(item.duration),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    return Hero(
      tag: 'bili_rcmd_banner_${item.bvid}',
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
      child: card,
    );
  }

  /// 轮播点击：与列表卡片一致的 iOS 整页放大转场，
  /// Hero tag 用轮播专用前缀避免与列表卡片冲突。
  void _openRcmdBanner(BiliRecommendItem item) {
    FocusManager.instance.primaryFocus?.unfocus();
    openBilibiliVideo(
      context,
      bvid: item.bvid,
      initialTitle: _titleFor(item),
      initialCover: item.cover,
      heroTag: 'bili_rcmd_banner_${item.bvid}',
    );
  }

  /// 轮播点击：iOS 转场与列表卡片一致——
  /// 剧集走封面 Hero 整页放大（banner 专用 tag 避免与列表重复），
  /// 活动页走 iOS 模糊滑动转场打开内置浏览器。
  void _openBangumiBanner(BiliBangumiBannerItem item) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (item.seasonId > 0) {
      openBilibiliBangumi(
        context,
        seasonId: item.seasonId,
        initialTitle: item.title,
        initialCover: item.cover,
        heroTag: 'bili_bangumi_banner_${item.seasonId}',
      );
    } else if (item.url.isNotEmpty) {
      final normalized =
          item.url.startsWith('//') ? 'https:${item.url}' : item.url;
      Navigator.of(context).push(
        heroTransitionRoute(
          heroZoom: false,
          page: BrowserPage(
            initialUrl: normalized,
            title: AppLocalizations.of(context).chatBrowserTitle,
          ),
        ),
      );
    }
  }

  void _showLongPressMenu(BiliRecommendItem item) {
    showVideoBottomSheet(
      context,
      bvid: item.bvid,
      title: item.title,
      cover: item.cover,
      author: item.ownerName,
      showOriginal: _showOriginalTitles.contains(item.bvid),
      onToggleOriginal: (show) => _setShowOriginal(item.bvid, show),
    );
  }

  void _showContextMenu(BiliRecommendItem item, Offset globalPosition) {
    showVideoContextMenu(
      context,
      bvid: item.bvid,
      title: item.title,
      cover: item.cover,
      author: item.ownerName,
      globalPosition: globalPosition,
      showOriginal: _showOriginalTitles.contains(item.bvid),
      onToggleOriginal: (show) => _setShowOriginal(item.bvid, show),
    );
  }

  void _setShowOriginal(String bvid, bool show) {
    setState(() {
      if (show) {
        _showOriginalTitles.add(bvid);
      } else {
        _showOriginalTitles.remove(bvid);
      }
    });
  }

  /// 番剧卡片长按 / 右键液态玻璃菜单。
  void _showBangumiMenu(BiliBangumiItem item, Offset globalPosition) {
    showGlassDropdownMenu(
      context,
      actions: [
        GlassMenuAction(
          icon: Icons.play_circle_outline,
          text: '应用内播放',
          onTap: () => _openBangumi(item),
        ),
        GlassMenuAction(
          icon: Icons.tag_outlined,
          text: '复制SS号',
          onTap: () => _copyText('ss${item.seasonId}'),
        ),
        GlassMenuAction(
          icon: Icons.link,
          text: '复制番剧链接',
          onTap: () => _copyText(
            'https://www.bilibili.com/bangumi/play/ss${item.seasonId}',
          ),
        ),
      ],
      globalPosition: globalPosition,
      menuWidth: 200,
    );
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) showAppToast(context, '已复制 $text');
  }

  // ═════════════════════════════════════════
  //  构建
  // ═════════════════════════════════════════

@override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isPortraitBottomBar = !widget.embeddedInShell &&
        MediaQuery.of(context).orientation == Orientation.portrait;
    // 当前 tab（0-3）为 feed：加载失败且无内容时，右下角换成「重新加载」FAB
    final tabIndex = _tabController.index;
    final currentFeed = switch (tabIndex) {
      0 => _live,
      1 => _rcmd,
      2 => _hot,
      3 => _bangumi,
      _ => null,
    };
    final feedError = currentFeed != null &&
        currentFeed.error != null &&
        currentFeed.items.isEmpty;
    final scaffold = Scaffold(
      key: _scaffoldKey,
      // 全局侧边栏（B 站版传统抽屉 AppDrawer；宽屏 Shell 内嵌时由 Shell 提供）
      drawer: widget.embeddedInShell
          ? null
          : const AppDrawer(currentPage: 'home'),
      backgroundColor: widget.embeddedInShell
          ? Colors.transparent
          : cs.surfaceContainer,
      // ── 右下角 FAB：加载失败 = 重新加载；正常 = 单列 / 多列切换
      //（标准 FAB，竖屏底栏时抬起避免被玻璃底栏遮挡） ──
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: isPortraitBottomBar ? 72 : 0),
        child: feedError
            ? LoadRetryPill(onRetry: () => _forceLoadTab(tabIndex))
            : FloatingActionButton(
                tooltip: _gridMode
                    ? l10n.searchSwitchSingleCol
                    : l10n.searchSwitchMulti,
                onPressed: BilibiliRecommendPage.toggleGridMode,
                child: Icon(
                  _gridMode
                      ? Icons.view_agenda_outlined
                      : Icons.grid_view_rounded,
                ),
              ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // ── 内容区：铺满，滚动到毛玻璃顶栏下方 ──
            Positioned.fill(
              child: TabBarView(
                controller: _tabController,
                // 物理顺序 = 视觉顺序：0 直播 / 1 推荐 / 2 热门 / 3 番剧 / 4 分区。
                // 直播放最左，从推荐页（index 1）向左滑即可直达直播 tab。
                children: [
                  _tabWithHeroMode(
                    0,
                    _LazyKeepAliveTab(
                      onFirstBuild: _loadLive,
                      child: _buildVideoFeed<LiveRoomItem>(
                        cs,
                        l10n,
                        _live,
                        _liveScroll,
                        refreshKey: _feedRefreshKeys[0],
                        load: _loadLive,
                        keyOf: (v) => v.roomId.toString(),
                        gridCard: _gridLiveCard,
                        listCard: _listLiveCard,
                      ),
                    ),
                  ),
                  _tabWithHeroMode(
                    1,
                    _LazyKeepAliveTab(
                      onFirstBuild: null,
                      child: _buildVideoFeed(
                        cs,
                        l10n,
                        _rcmd,
                        _rcmdScroll,
                        refreshKey: _feedRefreshKeys[1],
                        load: _loadRcmd,
                        keyOf: (v) => v.bvid,
                        gridCard: _gridCard,
                        listCard: _listCard,
                        header: _rcmdBanners.length >= 2
                            ? _buildRcmdCarousel(cs, l10n)
                            : null,
                      ),
                    ),
                  ),
                  _tabWithHeroMode(
                    2,
                    _LazyKeepAliveTab(
                      onFirstBuild: _loadHot,
                      child: _buildVideoFeed(
                        cs,
                        l10n,
                        _hot,
                        _hotScroll,
                        refreshKey: _feedRefreshKeys[2],
                        load: _loadHot,
                        keyOf: (v) => v.bvid,
                        gridCard: _gridCard,
                        listCard: _listCard,
                        header: _buildHotHeader(cs, l10n),
                      ),
                    ),
                  ),
                  _tabWithHeroMode(
                    3,
                    _LazyKeepAliveTab(
                      onFirstBuild: _loadBangumi,
                      child: _buildBangumiFeed(cs, l10n),
                    ),
                  ),
                  _tabWithHeroMode(
                    4,
                    _LazyKeepAliveTab(
                      onFirstBuild: null,
                      child: BilibiliRegionPage(key: _regionKey),
                    ),
                  ),
                ],
              ),
            ),
            // ── 顶部毛玻璃栏（搜索页同款模糊）：内容从下方滚过被模糊 ──
            Align(
              alignment: Alignment.topCenter,
              child: _buildTabBar(cs, l10n),
            ),
          ],
        ),
      ),
    );
    // 注意：这里刻意不做「随 secondary 向左 parallax」的底栏平移效果。
    // 打开视频走的是 iOS 整页放大转场（FrostedHeroRoute），此前的
    // secondary 左移与整页放大叠加，观感是「背景向左滑动」，与搜索页
    // （只有景深缩放 + 背景模糊）不一致，已按统一动画移除。
    // 内嵌在 SideBarShell 时背景缩放由 Shell 统一提供（含侧边栏一起缩放）
    return widget.embeddedInShell
        ? scaffold
        : IosBackdropScale(child: scaffold);
  }

  /// 顶栏高度（毛玻璃栏，内容滚动到下方）。
  static const double kTabBarHeight = 56.0;

  /// 顶栏：毛玻璃（搜索页 FrostedPanel 同款模糊）+ 返回/侧边栏入口 +
  /// oval tab。竖屏（非宽屏嵌入且竖向）时在最右追加搜索 / 分区按钮。
  Widget _buildTabBar(ColorScheme cs, AppLocalizations l10n) {
    final isPortrait = !widget.embeddedInShell &&
        MediaQuery.orientationOf(context) == Orientation.portrait;
    return FrostedPanel(
      opacity: 0.75,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kTabBarHeight,
          child: Row(
            children: [
              if (!widget.embeddedInShell) ...[
                // NaviFlash：本页可作为应用根页面（无返回可退时）
                // 提供左侧侧边栏入口（未登录完整 icon；登录后头像胶囊）
                if (Navigator.canPop(context))
                  _RoundIconButton(
                    icon: Icons.arrow_back,
                    tooltip: l10n.homeBack,
                    onTap: () => Navigator.pop(context),
                  )
                else
                  _SideBarEntry(onTap: _openSideMenu),
                const SizedBox(width: 4),
              ],
              // tab 数量增加后窄屏可能排不下：空间够时居中不变，
              // 不够时改为横向滚动（Center + 横向 SingleChildScrollView）
              Expanded(
                child: Center(
                  // 长按 oval tab：搜索页同款液态玻璃菜单（按住左右滑动切换）
                  child: LongPressGlassTabSwitcher(
                    selectedIndex: _tabController.index,
                    onIndexChanged: (index) {
                      if (index != _tabController.index) {
                        _tabController.animateTo(index);
                      }
                    },
                    tabs: [
                      for (final i in _kOvalTabs)
                        GlassTab(label: _ovalTabLabel(i, l10n)),
                    ],
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final i in _kOvalTabs) _buildOvalTab(i, cs, l10n),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isPortrait) ...[
                _RoundIconButton(
                  icon: Icons.search,
                  tooltip: l10n.drawerBilibiliSearch,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BilibiliSearchPage(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: '分区',
                  child: IconButton(
                    icon: Icon(
                      _tabController.index == 4
                          ? Icons.grid_view_rounded
                          : Icons.grid_view_outlined,
                      size: 22,
                    ),
                    color:
                        _tabController.index == 4 ? cs.primary : cs.onSurface,
                    onPressed: () => _onTabTap(4),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 搜索页同款 oval tab：椭圆点击区 + 文字 + 动画下划线指示器。
  Widget _buildOvalTab(int index, ColorScheme cs, AppLocalizations l10n) {
    final selected = _tabController.index == index;
    final label = _ovalTabLabel(index, l10n);
    return InkWell(
      onTap: () => _onTabTap(index),
      customBorder: const StadiumBorder(),
      splashColor: cs.primary.withValues(alpha: 0.12),
      highlightColor: cs.primary.withValues(alpha: 0.08),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: 3,
            width: selected ? 24 : 0,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  /// oval tab 与长按玻璃菜单共用的 tab 文案。
  String _ovalTabLabel(int index, AppLocalizations l10n) {
    return switch (index) {
      // 1/2/3 沿用翻译文案，0 直播、4 分区按项目约定硬编码中文
      1 => l10n.drawerRecommend,
      2 => l10n.recommendTabHot,
      3 => l10n.recommendTabBangumi,
      _ => _kTabLabels[index],
    };
  }

  /// tab 页包一层 HeroMode：只有当前 tab 的卡片参与 Hero 飞行动画。
  ///
  /// 各 tab 靠 AutomaticKeepAlive 保活，切换后仍留在同一棵 widget 树里；
  /// 推荐流与热门榜经常出现同一条视频，两边卡片的 Hero tag 都是
  /// `bili_video_$bvid`，同时存在时点击会抛
  ///「There are multiple heroes that share the same tag within a subtree」
  ///（debug 红屏、release 只打日志）。
  Widget _tabWithHeroMode(int index, Widget child) {
    return HeroMode(
      enabled: _tabController.index == index,
      child: child,
    );
  }

  /// 通用 feed（推荐 / 热门 / 直播 共用）：网格 / 单列 + 触底加载动画（搜索页同款）。
  ///
  /// [keyOf] 给列表项提供唯一 key（入场动画 / 网格变化动画用），
  /// [gridCard] / [listCard] 决定卡片外观 —— 直播 tab 传入与视频卡片同款的
  /// [_gridLiveCard] / [_listLiveCard]，其余交互完全一致。
  Widget _buildVideoFeed<T>(
    ColorScheme cs,
    AppLocalizations l10n,
    _TabState<T> data,
    ScrollController controller, {
    required GlobalKey<RefreshIndicatorState> refreshKey,
    required Future<void> Function({
      bool forceRefresh,
      bool viaRefresh,
    })
    load,
    required String Function(T) keyOf,
    required Widget Function(ColorScheme cs, T item) gridCard,
    required Widget Function(ColorScheme cs, T item) listCard,
    Widget? header,
  }) {
    final items = data.items;
    return RefreshIndicator(
      key: refreshKey,
      onRefresh: () => load(forceRefresh: true, viaRefresh: true),
      color: cs.primary,
      // 指示器停留位置下推到悬浮顶栏（kTabBarHeight）下方，避免被顶栏盖住
      edgeOffset: 0,
      displacement: kTabBarHeight + 10,
      child: Stack(
        children: [
          CustomScrollView(
            controller: controller,
            physics: data.loading
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
            slivers: [
              // 顶栏留白：内容滚动到毛玻璃栏下方
              SliverToBoxAdapter(child: SizedBox(height: kTabBarHeight)),
              // 热门页顶部入口（排行榜 / 每周必看 / 入站必刷 + 相关搜索）
              if (header != null) SliverToBoxAdapter(child: header),
              if (data.loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: LoadingIndicatorM3E()),
                )
              else if (data.error != null && items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _errorView(cs, l10n),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      l10n.recommendEmpty,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else if (!_gridMode)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Column(
                      children: [
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _FreshSlideIn(
                              isFresh: data.freshKeys.contains(keyOf(item)),
                              child: listCard(cs, item),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      final columns = (width / kVideoCardTargetWidth)
                          .floor()
                          .clamp(
                            kVideoCardMinColumns,
                            kVideoCardMaxColumns,
                          );
                      final cardW = (width - (columns - 1) * 12) / columns;
                      final cellW = cardW + 12;
                      final cellH = cardW / 0.78 + 12;
                      _checkGridLayoutChange(
                        data,
                        items,
                        keyOf,
                        columns,
                        items.length,
                        cellW,
                        cellH,
                      );
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final item = items[i];
                            return ListenableBuilder(
                              listenable: _gridRowAnimCtrl,
                              builder: (context, _) {
                                final t = Curves.easeInOut.transform(
                                  _gridRowAnimCtrl.value,
                                );
                                final delta = data.itemTranslations[i];
                                Widget card = _FreshSlideIn(
                                  isFresh: data.freshKeys.contains(keyOf(item)),
                                  child: gridCard(cs, item),
                                );
                                if (delta != null && t < 1.0) {
                                  card = Transform.translate(
                                    offset: Offset(
                                      delta.dx * (1 - t),
                                      delta.dy * (1 - t),
                                    ),
                                    child: card,
                                  );
                                }
                                return card;
                              },
                            );
                          },
                          childCount: items.length,
                        ),
                      );
                    },
                  ),
                ),
            // 底部留白：浮动指示器不占内容空间，列表末尾仍需避让玻璃底栏
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom +
                    (!widget.embeddedInShell &&
                            MediaQuery.of(context).orientation ==
                                Orientation.portrait
                        ? 76
                        : 72),
              ),
            ),
          ],
        ),
        FeedLoadingOverlay(
          loadingMore: data.loadingMore,
          hasMore: data.hasMore,
          bottomOffset: _feedOverlayBottom(context),
        ),
      ],
      ),
    );
  }

  /// 浮动加载指示器距离屏底的距离：避让底部玻璃底栏（独立页 + 竖屏时显示）
  /// + safe area 底部 + 16；嵌入式 / 横屏 = 仅 safe area + 16。
  double _feedOverlayBottom(BuildContext context) {
    final hasBottomBar = !widget.embeddedInShell &&
        MediaQuery.of(context).orientation == Orientation.portrait;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return (hasBottomBar ? 60 : 0) + safeBottom + 16;
  }

  /// 热门页顶部入口（对齐官方 gRPC 云控结构：
  /// bilibili.app.show.v1 Popular/Index → PopularReply.config.top_items，
  /// 数量 / 图标 / 标题 / 跳转链接全部由服务端下发）。
  /// navi 无运营后台，接口失败 / 返回空时回退以下本地入口
  /// （排行榜 / 每周必看 / 入站必刷，与热门列表页同源）。
  static const List<({String title, IconData icon, BiliPopularListKind kind})>
      _kHotEntranceFallback = [
    (
      title: '排行榜',
      icon: Icons.leaderboard_rounded,
      kind: BiliPopularListKind.ranking,
    ),
    (
      title: '每周必看',
      icon: Icons.calendar_view_week_rounded,
      kind: BiliPopularListKind.weekly,
    ),
    (
      title: '入站必刷',
      icon: Icons.auto_awesome_rounded,
      kind: BiliPopularListKind.precious,
    ),
  ];

  /// 热门页顶部：入口（云控，数量 / 图标 / 标题随服务端变化）+
  /// 相关搜索（热搜词）。
  Widget _buildHotHeader(ColorScheme cs, AppLocalizations l10n) {
    final entrances = _hotEntrances;
    final useCloud = entrances.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 入口 ──
          if (useCloud)
            // 云控入口：数量可能较多，横向滚动（与官方 App 一致）
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entrances.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) =>
                    _hotEntryCloud(cs, entrances[i]),
              ),
            )
          else
            // 兜底入口：按列表渲染，数量自适应
            Row(
              children: [
                for (final e in _kHotEntranceFallback) ...[
                  if (e != _kHotEntranceFallback.first)
                    const SizedBox(width: 10),
                  Expanded(
                    child: _hotEntry(
                      cs,
                      icon: e.icon,
                      text: e.title,
                      onTap: () => _openPopularList(e.kind),
                    ),
                  ),
                ],
              ],
            ),
          // ── 相关搜索（热搜词，点击跳转搜索；默认折叠，点 v 展开） ──
          if (_hotwords.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() {
                _hotSearchExpanded = !_hotSearchExpanded;
              }),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '相关搜索',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _hotSearchExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (_hotSearchExpanded) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final word in _hotwords)
                    ActionChip(
                      label: Text(word),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BilibiliSearchPage(
                              initialKeyword: word,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 拉取热门页云控入口（gRPC Popular/Index）。
  /// 失败 / 为空时保持回退入口（不覆盖已有数据）。
  Future<void> _loadHotEntrances() async {
    if (_hotEntrancesLoaded) return;
    final items = await BilibiliHotService.fetchHotEntrances();
    if (!mounted || items.isEmpty) return;
    setState(() {
      _hotEntrances = items;
      _hotEntrancesLoaded = true;
    });
  }

  /// 云控入口按钮：网络图标（服务端下发，带 Referer 头）+ 标题。
  Widget _hotEntryCloud(ColorScheme cs, BiliHotEntrance entrance) {
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    final iconUrl = entrance.icon.startsWith('//')
        ? 'https:${entrance.icon}'
        : entrance.icon;
    return SizedBox(
      width: 72,
      child: Material(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openHotEntrance(entrance),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: Image(
                      image: CachedImageProvider(iconUrl, headers: headers),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  entrance.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 打开云控入口：本地有对应列表页的走原生页（排行榜 / 每周必看 /
  /// 入站必刷），其余 H5 链接用内置浏览器打开。
  void _openHotEntrance(BiliHotEntrance entrance) {
    final uri = entrance.uri;
    if (uri.startsWith('bilibili://rank')) {
      _openPopularList(BiliPopularListKind.ranking);
    } else if (entrance.title == '每周必看') {
      _openPopularList(BiliPopularListKind.weekly);
    } else if (entrance.title == '入站必刷') {
      _openPopularList(BiliPopularListKind.precious);
    } else if (uri.isNotEmpty) {
      openLinkInBuiltInBrowser(context, url: uri, confirm: false);
    }
  }

  /// 热门页入口按钮（返回 Material 本体，由调用方的 Row + Expanded 提供弹性；
  /// 自身不再包 Expanded，否则「Expanded 嵌套 Expanded」触发
  /// Incorrect use of ParentDataWidget）。
  Widget _hotEntry(
    ColorScheme cs, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, size: 24, color: cs.primary),
                const SizedBox(height: 4),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  /// 打开排行榜 / 每周必看 / 入站必刷 列表页。
  void _openPopularList(BiliPopularListKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BilibiliPopularListPage(kind: kind),
      ),
    );
  }

  /// 番剧 feed：竖版封面（3:4）网格 / 单列。
  Widget _buildBangumiFeed(ColorScheme cs, AppLocalizations l10n) {
    final data = _bangumi;
    final items = data.items;
    return RefreshIndicator(
      key: _feedRefreshKeys[3],
      onRefresh: () => _loadBangumi(forceRefresh: true, viaRefresh: true),
      color: cs.primary,
      // 指示器停留位置下推到悬浮顶栏（kTabBarHeight）下方，避免被顶栏盖住
      edgeOffset: 0,
      displacement: kTabBarHeight + 10,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _bangumiScroll,
            physics: data.loading
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
        slivers: [
          // 顶栏留白：内容滚动到毛玻璃栏下方
          SliverToBoxAdapter(child: SizedBox(height: kTabBarHeight)),
          if (data.loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: LoadingIndicatorM3E()),
            )
          else if (data.error != null && items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _errorView(cs, l10n),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  l10n.recommendEmpty,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else ...[
            // 顶部轮播图（Material 3 CarouselView：官方番剧 tab 同源
            // BANNER 模块，横向滑动 + 吸附，点击进入详情 / 活动页）
            SliverToBoxAdapter(
              child: _bangumiBanners.isEmpty
                  ? SizedBox(key: _bangumiCarouselKey, height: 0)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: _bangumiCarousel(cs, _bangumiBanners),
                    ),
            ),
            // 热门排行榜（首图下方）
            if (_bangumiRankItems.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildBangumiRank(cs, l10n),
              ),
            // 继续看（热门下方，需登录）
            if (_bangumiContinueItems.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildBangumiContinue(cs, l10n),
              ),
            if (!_gridMode)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _FreshSlideIn(
                            isFresh: data.freshKeys.contains(
                              item.seasonId.toString(),
                            ),
                            child: _bangumiListCard(cs, item),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final columns = (width / 160)
                      .floor()
                      .clamp(kVideoCardMinColumns, 6);
                  final cardW = (width - (columns - 1) * 12) / columns;
                  final cellW = cardW + 12;
                  // 封面 3:4 + 文字区固定高度，避免窄屏下文字区溢出截断
                  final cellH = cardW * 4 / 3 + 84 + 12;
                  _checkGridLayoutChange(
                    data,
                    items,
                    (v) => v.seasonId.toString(),
                    columns,
                    items.length,
                    cellW,
                    cellH,
                  );
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: cardW / cellH,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final item = items[i];
                        return ListenableBuilder(
                          listenable: _gridRowAnimCtrl,
                          builder: (context, _) {
                            final t = Curves.easeInOut.transform(
                              _gridRowAnimCtrl.value,
                            );
                            final delta = data.itemTranslations[i];
                            Widget card = _FreshSlideIn(
                              isFresh: data.freshKeys.contains(
                                item.seasonId.toString(),
                              ),
                              child: _bangumiGridCard(cs, item),
                            );
                            if (delta != null && t < 1.0) {
                              card = Transform.translate(
                                offset: Offset(
                                  delta.dx * (1 - t),
                                  delta.dy * (1 - t),
                                ),
                                child: card,
                              );
                            }
                            return card;
                          },
                        );
                      },
                      childCount: items.length,
                    ),
                  );
                },
              ),
            ),
          ],
          // 底部留白：浮动指示器不占内容空间，列表末尾仍需避让玻璃底栏
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom +
                  (!widget.embeddedInShell &&
                          MediaQuery.of(context).orientation ==
                              Orientation.portrait
                      ? 76
                      : 72),
            ),
          ),
        ],
      ),
          FeedLoadingOverlay(
            loadingMore: data.loadingMore,
            hasMore: data.hasMore,
            bottomOffset: _feedOverlayBottom(context),
          ),
        ],
      ),
    );
  }

  /// 番剧轮播图：Material 3 [CarouselView.weighted] 中心式布局
  /// （flexWeights [1, 7, 1]），当前大图居中，左右各露出一张邻图，
  /// 16:9 大图、吸附切换、自动播放。
  Widget _bangumiCarousel(ColorScheme cs, List<BiliBangumiBannerItem> banners) {
    if (banners.isEmpty) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;
    final viewport = width - 32;
    final weights = _kBangumiCarouselWeights;
    final sum = weights[0] + weights[1] + weights[2];
    // 中间大图占 7/9 视口宽，高度按 16:9 计算
    final middleExtent = viewport * weights[1] / sum;
    final height = middleExtent * 9 / 16;
    _bangumiCarouselStep = viewport * weights[0] / sum;
    return SizedBox(
      key: _bangumiCarouselKey,
      height: height,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          // 用户拖动时暂停自动播放，松手后恢复
          if (n is ScrollStartNotification && n.dragDetails != null) {
            _bangumiCarouselTimer?.cancel();
          } else if (n is ScrollEndNotification) {
            _startBangumiCarouselAutoPlay();
          }
          return false;
        },
        child: CarouselView.weighted(
          controller: _bangumiCarouselCtrl,
          flexWeights: weights,
          itemSnapping: true,
          consumeMaxWeight: false,
          infinite: true,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(
            // Flutter 文档 CarouselView 默认大圆角 28
            borderRadius: BorderRadius.circular(28),
          ),
          itemClipBehavior: Clip.antiAlias,
          onTap: (i) => _openBangumiBanner(banners[i % banners.length]),
          children: [
            for (final item in banners) _bangumiCarouselCard(cs, item),
          ],
        ),
      ),
    );
  }

  /// 热门排行榜：标题 + 横向榜单（名次 + 封面 + 标题 + 更新话数）。
  Widget _buildBangumiRank(ColorScheme cs, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '热门榜单',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _bangumiRankItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final item = _bangumiRankItems[i];
                return GestureDetector(
                  onTap: () => _openBangumiSimple(item.seasonId,
                      item.title, item.cover),
                  child: SizedBox(
                    width: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 封面 + 名次角标
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _coverImage(item.cover,
                                  width: 100, height: 132),
                            ),
                            Positioned(
                              left: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: i == 0
                                      ? const Color(0xFFFB7299)
                                      : Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (item.newEpShow.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.newEpShow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 继续看：标题 + 横向卡片（封面带进度条 + 标题 + 小简介），
  /// 仅登录且数据非空时显示。
  Widget _buildBangumiContinue(ColorScheme cs, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '继续观看',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _bangumiContinueItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final item = _bangumiContinueItems[i];
                return GestureDetector(
                  onTap: () => _openBangumiSimple(item.seasonId,
                      item.title, item.cover),
                  child: SizedBox(
                    width: 132,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 封面 + 底部进度条
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 132,
                            height: 132,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _coverImage(item.cover, aspect: 1),
                                // 底部渐变 + 进度条
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: 3,
                                    color: Colors.white24,
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: (item.progressPercent /
                                              100)
                                          .clamp(0.0, 1.0),
                                      child: const ColoredBox(
                                        color: Color(0xFFFB7299),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                        if (item.desc.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.3,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 无 Hero 的番剧详情跳转（排行榜 / 继续看卡片，iOS 模糊转场）。
  void _openBangumiSimple(int seasonId, String title, String cover) {
    FocusManager.instance.primaryFocus?.unfocus();
    openBilibiliBangumi(
      context,
      seasonId: seasonId,
      initialTitle: title,
      initialCover: cover,
    );
  }

  /// 轮播图卡片：官方 App 同款合成——
/// bg_img 不透明背景铺满 + 底部渐变 + 标题区（水平居中）：
/// cover 透明标题文字图（高 = 卡高 × 27.5%，宽自适应）或标题文本，
/// 下方 4dp 间隔 + 副标题；无 bg_img 时 cover 整图铺底。
  Widget _bangumiCarouselCard(ColorScheme cs, BiliBangumiBannerItem item) {
    final hasBg = item.bgImg.isNotEmpty;
    final hasCoverText = item.cover.isNotEmpty;
    final card = LayoutBuilder(
      builder: (context, constraints) {
        final titleHeight = constraints.maxHeight * 0.275;
        return Stack(
          fit: StackFit.expand,
          children: [
            // 背景层：bg_img 优先，否则用 cover 整图
            _coverImage(hasBg ? item.bgImg : item.cover, aspect: 16 / 9),
            // 底部渐变遮罩
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.62),
                  ],
                ),
              ),
            ),
            // cover 标题文字图（中下部分，水平居中，保持不变）
            if (hasCoverText && hasBg)
              Positioned(
                left: 12,
                right: 12,
                bottom: 25,
                child: _bannerTitleOverlay(item.cover, titleHeight),
              ),
            // 文字（左下角）：无 cover 图时的标题兜底 + 副标题
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasCoverText && item.title.isNotEmpty)
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 6),
                        ],
                      ),
                    ),
                  if (item.subTitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
    // 剧集：包 Hero 与 openBilibiliBangumi 的 banner tag 匹配，
    // 点击时封面整页放大（iOS 转场，与列表卡片一致）；活动页无 Hero。
    if (item.seasonId <= 0) return card;
    return Hero(
      tag: 'bili_bangumi_banner_${item.seasonId}',
      child: card,
    );
  }

  /// cover 标题文字图叠层（透明 PNG，FillHeight 同官方：高度固定、
  /// 宽度按原图比例，水平居中；加载失败静默隐藏）。
  Widget _bannerTitleOverlay(String url, double height) {
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    final normalized = url.startsWith('//') ? 'https:$url' : url;
    return Center(
      child: SizedBox(
        height: height,
        child: Image(
          image: CachedImageProvider(normalized, headers: headers),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// 检测网格布局变化并启动行平移动画（与搜索页同款）。
  void _checkGridLayoutChange<T>(
    _TabState<T> data,
    List<T> items,
    String Function(T) keyOf,
    int cols,
    int count,
    double cellW,
    double cellH,
  ) {
    if (items.isEmpty) return;
    if (data.prevCols == 0) {
      data.prevCols = cols;
      data.prevCount = count;
      data.prevFirstKey = keyOf(items[0]);
      return;
    }
    if (data.prevCols == cols && data.prevCount == count) return;
    if (count == 0 || data.prevCount == 0) {
      data.prevCols = cols;
      data.prevCount = count;
      data.prevFirstKey = keyOf(items[0]);
      return;
    }

    final oldCols = data.prevCols;
    final newCols = cols;
    final minCount = data.prevCount < count ? data.prevCount : count;
    final newFirstKey = keyOf(items[0]);

    // 完全替换（下拉刷新）：不播放动画
    if (data.prevFirstKey != null && data.prevFirstKey != newFirstKey) {
      data.itemTranslations.clear();
      data.prevCols = cols;
      data.prevCount = count;
      data.prevFirstKey = newFirstKey;
      return;
    }

    data.itemTranslations.clear();
    bool anyMoved = false;
    for (int i = 0; i < minCount; i++) {
      final oldRow = i ~/ oldCols;
      final oldCol = i % oldCols;
      final newRow = i ~/ newCols;
      final newCol = i % newCols;
      if (oldRow != newRow || oldCol != newCol) {
        anyMoved = true;
        data.itemTranslations[i] = Offset(
          (oldCol - newCol) * cellW,
          (oldRow - newRow) * cellH,
        );
      }
    }

    data.prevCols = cols;
    data.prevCount = count;
    data.prevFirstKey = newFirstKey;

    if (anyMoved) {
      // 延迟到帧后启动：本方法在 SliverLayoutBuilder 构建期间被调用，
      // 直接 reset/forward 会通知 ListenableBuilder 在 build 中
      // markNeedsBuild → 抛 setState() called during build 异常
      //（侧边栏手动展开推挤内容区宽度时触发）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _gridRowAnimCtrl.reset();
        _gridRowAnimCtrl.forward();
      });
    }
  }

  /// 触底加载动画已挪到 [FeedLoadingOverlay] 浮动显示（与底部玻璃底栏互不干扰）。
  /// —— 原本这里有个 [_buildFooter] 实现 inline footer + 留白，已经全部废弃。

  Widget _errorView(ColorScheme cs, AppLocalizations l10n) {
    return Center(
      child: Text(
        _lastError ?? l10n.biliLoadFailed,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
    );
  }

  String? get _lastError => BilibiliRecommendService.lastErrorDetail;

  // ═════════════════════════════════════════
  //  卡片
  // ═════════════════════════════════════════

  /// 视频网格卡片（对齐相关视频页网格卡片样式）。
  Widget _gridCard(ColorScheme cs, BiliRecommendItem item) {
    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(item),
        onLongPress: () => _showLongPressMenu(item),
        onSecondaryTapDown: (details) =>
            _showContextMenu(item, details.globalPosition),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 整页 Hero（iOS 整卡放大）时封面不单独包 Hero：
                  // 整卡 Hero 在卡片最外层（见 _gridCard 返回处），
                  // 内层再包同 tag Hero 会嵌套冲突；经典模式保持封面
                  // Hero（只包封面缩略图，文字不随封面飞）。
                  SettingsService.heroTransitionBlurEnabled
                      ? _coverImage(item.cover, aspect: 16 / 10)
                      : _coverImageWithHero(
                          item.cover,
                          item.bvid,
                          aspect: 16 / 10,
                        ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (item.view > 0)
                    Positioned(
                      left: 8,
                      bottom: 6,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          Text(
                            _fmtCount(item.view),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (item.duration > 0)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _fmtDur(item.duration),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleFor(item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (item.rcmdReason.isNotEmpty) ...[
                      Text(
                        item.rcmdReason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_fmtAgo(item.pubdate)}  ${item.ownerName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (item.danmaku > 0) ...[
                          Icon(
                            Icons.subtitles_outlined,
                            size: 12,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _fmtCount(item.danmaku),
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    // 整页 Hero（iOS 整卡放大）模式：Hero 包整个卡片，飞行起点/终点
    // = 整个卡片（封面 + 文字一起运动）；经典模式封面 Hero 已由
    // _coverImageWithHero 承担，此处不再包。
    if (SettingsService.heroTransitionBlurEnabled) {
      return _wrapCard(
        item,
        Hero(
          tag: 'bili_video_${item.bvid}',
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
          child: card,
        ),
      );
    }
    return _wrapCard(item, card);
  }

  /// 视频单列卡片（对齐相关视频页单列卡片样式）。
  Widget _listCard(ColorScheme cs, BiliRecommendItem item) {
    Widget thumb = _coverImage(item.cover, width: 148, height: 84);
    // 经典模式：Hero 只包缩略图（文字不随封面飞）；
    // 整页 Hero 模式：不在此包，整卡 Hero 在卡片最外层（见返回处）。
    if (!SettingsService.heroTransitionBlurEnabled) {
      thumb = Hero(
        tag: 'bili_video_${item.bvid}',
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: thumb,
      );
    }
    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(item),
        onLongPress: () => _showLongPressMenu(item),
        onSecondaryTapDown: (details) =>
            _showContextMenu(item, details.globalPosition),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              thumb,
              const SizedBox(width: 12),
              Expanded(
                // 高度随内容自适应（不再固定 84px）：标题两行 + 推荐理由
                // 同时存在时内容会超过 84px，固定高度会纵向 RenderFlex 溢出；
                // 去掉 Spacer（需要受限高度），改用 min 尺寸列，内容多高卡片多高
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _titleFor(item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    if (item.rcmdReason.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.rcmdReason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${_fmtAgo(item.pubdate)}  ${item.ownerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        Text(
                          _fmtCount(item.view),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.subtitles_outlined,
                          size: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _fmtCount(item.danmaku),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // 整页 Hero（iOS 整卡放大）模式：Hero 包整个卡片（封面 + 文字一起
    // 运动）；经典模式缩略图 Hero 已在卡片内层提供。
    if (SettingsService.heroTransitionBlurEnabled) {
      return MetroTileInteraction(
        onTapStart: (_, __) {},
        showBorder: false,
        child: Hero(
          tag: 'bili_video_${item.bvid}',
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
          child: card,
        ),
      );
    }
    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
  }

  /// 网格卡片外包装：磁贴倾斜（Hero 已由封面层 [_coverImageWithHero]
  /// 单独承担，不再包整卡，避免文字随封面一起飞）。
  Widget _wrapCard(BiliRecommendItem item, Widget card) {
    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
  }

  // ═════════════════════════════════════════
  //  直播卡片
  //  外观与视频卡片 [_gridCard] / [_listCard] 同款（圆角 12、16:10 封面、
  //  底部渐变遮罩 + 双角标、13px 标题、11px 底部信息行），
  //  只把数据换成直播间：角标为「人气 / 分区」，底部为主播名。
  // ═════════════════════════════════════════

  /// 直播封面右下角标文本：二级分区优先，其次一级分区，都没有则「直播中」。
  String _liveAreaText(LiveRoomItem item) {
    if (item.areaName.isNotEmpty) return item.areaName;
    if (item.parentAreaName.isNotEmpty) return item.parentAreaName;
    return '直播中';
  }

  /// 人气展示：网格角标用与视频播放数同款格式（[_fmtCount]），
  /// 单列卡片用服务端给的原文（如「2551.7万人气」）。
  String _liveOnlineText(LiveRoomItem item) => _fmtCount(item.online);

  /// 打开直播间：进直播间查看页（弹幕 / 聊天 / 清晰度 / 线路）。
  void _openLive(LiveRoomItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BilibiliLiveRoomPage(
          roomId: item.roomId,
          title: item.title,
          uname: item.uname,
          face: item.face,
          cover: item.cover,
        ),
      ),
    );
  }

  /// 直播卡片右键液态玻璃菜单（需要落点位置）。
  void _showLiveMenu(LiveRoomItem item, Offset globalPosition) {
    showGlassDropdownMenu(
      context,
      actions: _liveActions(item),
      globalPosition: globalPosition,
      menuWidth: 200,
    );
  }

  /// 直播卡片长按：与视频卡片同款「大封面 + 玻璃菜单」底部弹层
  /// （封面 Hero 与卡片缩略图同名 tag，长按飞入）。
  void _showLiveLongPressMenu(LiveRoomItem item) {
    showCoverMenuBottomSheet(
      context,
      cover: item.cover,
      title: item.title,
      subtitle: item.uname.isEmpty
          ? _liveOnlineText(item)
          : '${item.uname} · ${_liveOnlineText(item)}',
      heroTag: 'bili_live_${item.roomId}',
      actions: [
        for (final a
            in _liveActions(item, closeMenu: () => Navigator.of(context).pop()))
          (icon: a.icon, text: a.text, onTap: a.onTap),
      ],
    );
  }

  /// 番剧卡片长按：与视频卡片同款「大封面 + 玻璃菜单」底部弹层
  /// （封面 Hero 与卡片缩略图同名 tag，长按飞入）。
  void _showBangumiLongPressMenu(BiliBangumiItem item) {
    final subtitle = [
      if (item.indexShow.isNotEmpty) item.indexShow,
      if (item.score.isNotEmpty) '${item.score} 分',
    ].join(' · ');
    showCoverMenuBottomSheet(
      context,
      cover: item.cover,
      title: item.title,
      subtitle: subtitle,
      heroTag: 'bili_bangumi_${item.seasonId}',
      actions: [
        (
          icon: Icons.play_circle_outline,
          text: '应用内播放',
          onTap: () {
            Navigator.of(context).pop();
            _openBangumi(item);
          },
        ),
        (
          icon: Icons.tag_outlined,
          text: '复制SS号',
          onTap: () {
            Navigator.of(context).pop();
            _copyText('ss${item.seasonId}');
          },
        ),
        (
          icon: Icons.link,
          text: '复制番剧链接',
          onTap: () {
            Navigator.of(context).pop();
            _copyText(
              'https://www.bilibili.com/bangumi/play/ss${item.seasonId}',
            );
          },
        ),
      ],
    );
  }

  /// 直播卡片动作（长按底部弹层 / 右键下拉菜单共用）。
  ///
  /// [closeMenu] 用于底部弹层的手动关闭；右键下拉菜单由
  /// [showGlassDropdownMenu] 自行 dismiss，传 null 即可。
  List<GlassMenuAction> _liveActions(
    LiveRoomItem item, {
    VoidCallback? closeMenu,
  }) =>
      [
        GlassMenuAction(
          icon: Icons.open_in_browser,
          text: '在浏览器打开',
          onTap: () {
            closeMenu?.call();
            _openLive(item);
          },
        ),
        GlassMenuAction(
          icon: Icons.link,
          text: '复制直播间链接',
          onTap: () {
            closeMenu?.call();
            _copyText(item.url);
          },
        ),
        GlassMenuAction(
          icon: Icons.tag_outlined,
          text: '复制房间号',
          onTap: () {
            closeMenu?.call();
            _copyText(item.roomId.toString());
          },
        ),
      ];

  /// 直播网格卡片（与 [_gridCard] 同款外观）。
  Widget _gridLiveCard(ColorScheme cs, LiveRoomItem item) {
    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openLive(item),
        onLongPress: () => _showLiveLongPressMenu(item),
        onSecondaryTapDown: (details) =>
            _showLiveMenu(item, details.globalPosition),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'bili_live_${item.roomId}',
                    child: _coverImage(item.cover, aspect: 16 / 10),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (item.online > 0)
                    Positioned(
                      left: 8,
                      bottom: 6,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.visibility_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          Text(
                            _liveOnlineText(item),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _liveAreaText(item),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? '未命名直播间' : item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.live_tv_rounded,
                          size: 12,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '直播中',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.uname.isEmpty ? '未知主播' : item.uname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
  }

  /// 直播单列卡片（与 [_listCard] 同款外观）。
  Widget _listLiveCard(ColorScheme cs, LiveRoomItem item) {
    final thumb = Hero(
      tag: 'bili_live_${item.roomId}',
      child: _coverImage(item.cover, width: 148, height: 84),
    );
    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openLive(item),
        onLongPress: () => _showLiveLongPressMenu(item),
        onSecondaryTapDown: (details) =>
            _showLiveMenu(item, details.globalPosition),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              thumb,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title.isEmpty ? '未命名直播间' : item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.uname.isEmpty ? '未知主播' : item.uname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          size: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          item.onlineText.isNotEmpty
                              ? item.onlineText
                              : _fmtCount(item.online),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.tag_rounded,
                          size: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _liveAreaText(item),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
  }

  /// 番剧网格卡片（竖版 3:4 封面 + 评分 / 角标）。
  Widget _bangumiGridCard(ColorScheme cs, BiliBangumiItem item) {
    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onLongPress: () => _showBangumiLongPressMenu(item),
        child: InkWell(
        onTap: () => _openBangumi(item),
        onSecondaryTapDown: (d) => _showBangumiMenu(item, d.globalPosition),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _coverImage(item.cover, aspect: 3 / 4),
                  // 底部渐变
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 32,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 评分（左上）
                  if (item.score.isNotEmpty)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Color(0xFFFFC107),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.score,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // 角标（右上）
                  if (item.badge.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.badge,
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (item.indexShow.isNotEmpty)
                      Text(
                        item.indexShow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
    return Hero(tag: 'bili_bangumi_${item.seasonId}', child: card);
  }

  /// 番剧单列卡片。
  Widget _bangumiListCard(ColorScheme cs, BiliBangumiItem item) {
    Widget thumb = _coverImage(item.cover, width: 100, height: 133);
    // 整页 Hero（iOS 整卡放大）模式：缩略图不单独包 Hero，整卡 Hero 在
    // 卡片最外层；经典模式保持缩略图 Hero。
    if (!SettingsService.heroTransitionBlurEnabled) {
      thumb = Hero(
        tag: 'bili_bangumi_${item.seasonId}',
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: thumb,
      );
    }
    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onLongPress: () => _showBangumiLongPressMenu(item),
        child: InkWell(
        onTap: () => _openBangumi(item),
        onSecondaryTapDown: (d) => _showBangumiMenu(item, d.globalPosition),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              thumb,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    if (item.score.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFFFC107),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.score,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (item.indexShow.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.indexShow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (item.badge.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.badge,
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
    // 整页 Hero（iOS 整卡放大）模式：Hero 包整个卡片；经典模式缩略图
    // Hero 已在卡片内层提供。
    if (SettingsService.heroTransitionBlurEnabled) {
      return MetroTileInteraction(
        onTapStart: (_, __) {},
        showBorder: false,
        child: Hero(
          tag: 'bili_bangumi_${item.seasonId}',
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
          child: card,
        ),
      );
    }
    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
  }

  /// 封面图（CachedImageProvider，16:10 或 3:4 或固定尺寸）。
  Widget _coverImage(
    String url, {
    double? width,
    double? height,
    double aspect = 16 / 10,
  }) {
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    Widget img = url.isEmpty
        ? Container(
            color: Colors.grey.shade800,
            child: const Center(
              child: Icon(Icons.movie_outlined, color: Colors.white24),
            ),
          )
        : Image(
            image: CachedImageProvider(url, headers: headers),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade800,
              child: const Center(
                child: Icon(Icons.movie_outlined, color: Colors.white24),
              ),
            ),
          );
    return width != null && height != null
        ? SizedBox(width: width, height: height, child: img)
        : AspectRatio(aspectRatio: aspect, child: img);
  }

  /// 封面图 + Hero（进入视频页时只飞封面背景图，不带卡片文字）。
  Widget _coverImageWithHero(
    String url,
    String bvid, {
    double? width,
    double? height,
    double aspect = 16 / 10,
  }) {
    final img = _coverImage(url, width: width, height: height, aspect: aspect);
    return Hero(
      tag: 'bili_video_$bvid',
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
      child: img,
    );
  }

  String _fmtCount(int n) {
    final l10n = AppLocalizations.of(context);
    if (n >= 100000000) {
      return l10n.countYi((n / 100000000).toStringAsFixed(1));
    }
    if (n >= 10000) return l10n.countWan((n / 10000).toStringAsFixed(1));
    return '$n';
  }

  String _fmtDur(int sec) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = sec ~/ 60;
    final s = sec % 60;
    return m >= 60 ? '${m ~/ 60}:${two(m % 60)}:${two(s)}' : '$m:${two(s)}';
  }

  String _fmtAgo(int ts) {
    if (ts <= 0) return '';
    final l10n = AppLocalizations.of(context);
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ts * 1000),
    );
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 30) return l10n.timeDaysAgo(diff.inDays);
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

/// 懒加载 + 保活的 tab 容器：首次构建触发 [onFirstBuild]（仅一次），
/// 切走后保持 State / 滚动位置不销毁。
class _LazyKeepAliveTab extends StatefulWidget {
  final Future<void> Function()? onFirstBuild;
  final Widget child;

  const _LazyKeepAliveTab({this.onFirstBuild, required this.child});

  @override
  State<_LazyKeepAliveTab> createState() => _LazyKeepAliveTabState();
}

class _LazyKeepAliveTabState extends State<_LazyKeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 首次构建时触发懒加载（State 保活，只会执行一次）。
    // 延迟到首帧后执行：initState 处于 build 阶段，直接调用会触发
    // 父级 setState 抛「setState() called during build」。
    final load = widget.onFirstBuild;
    if (load != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => load());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// 竖屏主页左侧边栏入口（替换原 ⋮ 更多按钮，无背景色）：
///  - 未登录：完整菜单 icon；
///  - 已登录：左半菜单 icon + B 站头像（头像随账号变化实时刷新）。
/// 悬浮面板只出现在顶栏下方，因此本入口在侧边栏打开时仍常驻顶栏，
/// 点击即可关闭侧边栏。
class _SideBarEntry extends StatelessWidget {
  final VoidCallback onTap;

  const _SideBarEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: BilibiliAccountService.instance,
      builder: (context, _) {
        final account = BilibiliAccountService.instance;
        final logged = account.isLoggedIn;
        final avatarUrl = account.avatarUrl;
        final iconColor = cs.onSurface;
        return Tooltip(
          message: logged && account.uname.isNotEmpty
              ? account.uname
              : '侧边栏',
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              customBorder: const StadiumBorder(),
              splashColor: cs.primary.withValues(alpha: 0.14),
              highlightColor: cs.primary.withValues(alpha: 0.06),
              child: logged
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 左半 icon：窄条裁切，露出半个菜单 icon
                        ClipRect(
                          child: SizedBox(
                            width: 15,
                            height: 40,
                            child: Icon(
                              Icons.menu,
                              size: 20,
                              color: iconColor,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cs.outlineVariant.withValues(
                                  alpha: 0.65,
                                ),
                                width: 1.2,
                              ),
                            ),
                            child: ClipOval(
                              child: SizedBox(
                                width: 34,
                                height: 34,
                                child: avatarUrl.isNotEmpty
                                    ? Image(
                                        image: CachedImageProvider(
                                          avatarUrl,
                                          headers:
                                              NetworkSettingsService
                                                      .instance
                                                      .apiHeaders
                                                      .isEmpty
                                                  ? null
                                                  : NetworkSettingsService
                                                      .instance
                                                      .apiHeaders,
                                        ),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.account_circle,
                                          size: 22,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      )
                                    : Icon(
                                        Icons.account_circle,
                                        size: 24,
                                        color: cs.onSurfaceVariant,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 9,
                      ),
                      child: Icon(Icons.menu, size: 21, color: iconColor),
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// 顶栏圆形图标按钮（与用户空间页 MorphIconButton 相近的轻量实现）。
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 22),
        color: cs.onSurface,
        onPressed: onTap,
      ),
    );
  }
}

/// 卡片入场动画（与搜索页同款：下滑 + 淡入，360ms + 80ms 延迟）。
/// 首次加载 / 下拉刷新新插入的卡片播放，其余（加载更多等）不播。
class _FreshSlideIn extends StatefulWidget {
  final bool isFresh;
  final Widget child;

  const _FreshSlideIn({required this.isFresh, required this.child});

  @override
  State<_FreshSlideIn> createState() => _FreshSlideInState();
}

class _FreshSlideInState extends State<_FreshSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    if (widget.isFresh) {
      // 微小延迟让列表布局先完成，动画再开始
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isFresh) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: FractionalTranslation(translation: _slide.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}