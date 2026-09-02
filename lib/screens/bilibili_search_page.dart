// lib/screens/bilibili_search_page.dart
//
// B 站搜索页（布局/卡片与设置搜索页 settings_search_page.dart 一致：
// 顶部返回按钮 + 圆角填充搜索框，结果用 morph 分段卡片）：
//   - 输入关键词，点击「搜索」/ 回车后才开始搜索（不做实时刷新）
//   - 输入时展示搜索建议下拉（suggest，防抖请求，morph 卡片），
//     点击建议词直接搜索；建议不随点击其他元素消失
//   - 搜索类别 Tab：视频 / 番剧 / 影视 / 直播间 / 用户 / 专栏，
//     每个 Tab 独立分页加载并显示结果数量（懒加载）
//   - 结果标题中的搜索词高亮显示（解析接口 <em> 标签）
//   - 触底自动加载下一页（page + 1）
//   - 风控时复用 screens/geetest_dialog.dart 的极验滑块验证码：
//     v_voucher → gaia register → 极验弹窗 → gaia validate → grisk_id
//     （作为 Cookie x-bili-gaia-vtoken 携带重试原搜索）
//   - 点击结果项用 BrowserPage 打开对应 B 站页面
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:naviflash/screens/article_page.dart';
import 'package:naviflash/screens/bilibili_bangumi_page.dart';
import 'package:naviflash/screens/bilibili_live_room_page.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/screens/geetest_dialog.dart';
import 'package:naviflash/services/bilibili_search_history.dart';
import 'package:naviflash/services/bilibili_search_service.dart';
import 'package:naviflash/services/bilibili_search_cache.dart';
import 'package:naviflash/services/bilibili_translate_api.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/lnative_bridge.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/MetroTile.dart';
import 'package:naviflash/widgets/widgets.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'browser_page.dart';

// ═════════════════════════════════════════
//  顶栏 / 选项卡尺寸
// ═════════════════════════════════════════

/// 顶栏（返回 + 搜索框）总高度：上 8 + 输入框 ~48 + 下 4。
const double kSearchBarHeight = 60.0;

/// 毛玻璃选项卡栏高度。
const double kSearchTabBarHeight = 48.0;

// ═════════════════════════════════════════
// ═════════════════════════════════════════

/// 发布时长选项（index → pubtime_begin_s 偏移）。
const List<String> kPubTimeOptions = ['不限', '最近一天', '最近一周', '最近半年'];

/// 内容时长选项（index → duration 参数；30-60 与 60+ 接口同为 3）。
const List<String> kDurationOptions = [
  '全部时长',
  '0-10分钟',
  '10-30分钟',
  '30-60分钟',
  '60分钟+',
];

/// 内容分区选项（tids=0 表示全部）。
const List<({String label, int tids})> kZoneOptions = [
  (label: '全部', tids: 0),
  (label: '动画', tids: 1),
  (label: '番剧', tids: 13),
  (label: '国创', tids: 167),
  (label: '音乐', tids: 3),
  (label: '舞蹈', tids: 129),
  (label: '游戏', tids: 4),
  (label: '知识', tids: 36),
  (label: '科技', tids: 188),
  (label: '运动', tids: 234),
  (label: '汽车', tids: 223),
  (label: '生活', tids: 160),
  (label: '美食', tids: 221),
  (label: '动物', tids: 217),
  (label: '鬼畜', tids: 119),
  (label: '时尚', tids: 115),
  (label: '资讯', tids: 202),
  (label: '娱乐', tids: 5),
  (label: '影视', tids: 181),
  (label: '记录', tids: 177),
  (label: '电影', tids: 23),
  (label: '电视', tids: 11),
];

/// 视频搜索筛选状态。
class _FilterState {
  int pubTime = 0; // kPubTimeOptions 下标（0=不限）
  int duration = 0; // kDurationOptions 下标
  int zone = 0; // tids（0 = 全部）

  /// 自定义起止时间（Unix 秒）。任一非空时优先于 [pubTime] 预设。
  int? customBegin;
  int? customEnd;

  bool antiFuzzy = false; // 防模糊：限定 2009-06-26 至今（默认关闭）

  /// 仅限标题包含搜索词任一字符的视频（本地过滤，排除大数据推荐污染）。
  bool keywordFilter = false;

  /// 当前激活的筛选项数量（用于按钮角标）。
  int get activeCount =>
      (pubTime != 0 ? 1 : 0) +
      ((customBegin != null || customEnd != null) ? 1 : 0) +
      (duration != 0 ? 1 : 0) +
      (zone != 0 ? 1 : 0) +
      (antiFuzzy ? 1 : 0) +
      (keywordFilter ? 1 : 0);
}

/// 单个搜索类别的分页状态。
class _TypeData {
  final List<BiliSearchItem> items = [];
  int numResults = 0;
  int page = 0;
  bool loaded = false;
  bool loading = false;
  bool loadingMore = false;

  /// 「加载下一页插入顶部」式刷新（下拉刷新 / 点击当前 tab）进行中：
  /// 防并发重入（刷新期间不再置 loading，列表保留，由下拉加载器呈现状态）。
  bool refreshing = false;
  bool hasMore = true;
  String? error;

  /// 下拉刷新时新插入的项 id 集合（用于入场动画，动画完成后清空）。
  final Set<int> freshInsertIds = {};

  void reset() {
    items.clear();
    numResults = 0;
    page = 0;
    loaded = false;
    loading = false;
    loadingMore = false;
    refreshing = false;
    hasMore = true;
    error = null;
    freshInsertIds.clear();
  }
}

class BilibiliSearchPage extends StatefulWidget {
  final String initialKeyword;

  /// 是否记录「由 initialKeyword 触发的自动搜索」到搜索历史。
  /// 视频页点击 tag 跳转时传 false：tag 只是跳转锚点，不应污染搜索历史；
  /// 用户在搜索页内手动发起的后续搜索仍会正常记录。
  final bool recordInitialKeyword;

  /// 宽屏 SideBarShell 内嵌模式：不显示返回按钮、不拦截返回，
  /// 背景透明（由 Shell 画布统一提供）。
  final bool embeddedInShell;

  const BilibiliSearchPage({
    super.key,
    this.initialKeyword = '',
    this.recordInitialKeyword = true,
    this.embeddedInShell = false,
  });

  @override
  State<BilibiliSearchPage> createState() => _BilibiliSearchPageState();
}

class _BilibiliSearchPageState extends State<BilibiliSearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _keywordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _suggestDebounce;
  late final TabController _tabController;

  String _activeKeyword = ''; // 已提交的搜索词
  String? _gaiaVtoken; // 验证码换取的 grisk_id，本次会话内复用
  bool _captchaRunning = false;

  /// 跳过第一次搜索历史的记录（initialKeyword 触发的自动搜索，
  /// 见 recordInitialKeyword 说明）。
  bool _skipNextRecord = false;

  /// 视频结果卡片标题的 AI 翻译覆盖表（bvid → 英文标题）。
  final Map<String, String> _videoTitleOverrides = {};

  /// 视频搜索筛选（仅对视频类别生效）。
  final _FilterState _filters = _FilterState();

  /// 防模糊搜索下限：B 站成立日 2009-06-26（排除异常早的脏数据）。
  static final int _antiFuzzyBegin =
      DateTime(2009, 6, 26).millisecondsSinceEpoch ~/ 1000;

  final Map<BiliSearchType, _TypeData> _data = {};

  /// 每个搜索类别的结果区滚动控制器，用于点击 Tab 时滚动到顶部。
  final Map<BiliSearchType, ScrollController> _scrollControllers = {};

  /// 每个搜索类别结果区的下拉刷新 key：点击当前 Tab / 下拉刷新用
  /// show() 亮出下拉加载器（刷新不再整页闪回 3e 加载圈）。
  final Map<BiliSearchType, GlobalKey<RefreshIndicatorState>>
      _resultRefreshKeys = {};

  /// 视频/番剧/专栏共用的多列布局开关（提升到父级，跨 Tab 共享）。
  bool _gridMode = true;

  /// 切换多列/单列布局。
  void _toggleGridMode() {
    setState(() => _gridMode = !_gridMode);
  }

  // 搜索建议
  List<BiliSearchSuggest> _suggests = [];

  final Map<BiliSearchType, List<String>> _histories = {};

  /// 记录当前分区的搜索词（去重插入到最前，超出上限截断）。
  void _recordHistory(BiliSearchType type, String keyword) {
    final term = keyword.trim();
    if (term.isEmpty) return;
    final list = (_histories[type] ?? []).toList()
      ..remove(term)
      ..insert(0, term);
    setState(
      () => _histories[type] = list
          .take(BilibiliSearchHistory.maxLength)
          .toList(),
    );
    BilibiliSearchHistory.persist(type, _histories[type]!);
  }

  /// 点击历史词：填入输入框并直接搜索（并刷新到最前）。
  void _onHistoryTap(String keyword) {
    _suggestDebounce?.cancel();
    _keywordController.text = keyword;
    setState(() => _suggests = []);
    _submitSearch();
  }

  /// 长按历史词：删除该条（当前分区）。
  void _onHistoryLongPress(String keyword) {
    final type = _currentType;
    final list = (_histories[type] ?? []).toList()..remove(keyword);
    setState(() => _histories[type] = list);
    BilibiliSearchHistory.persist(type, list);
  }

  /// 清空当前分区的搜索历史（带确认）。
  void _clearHistory() {
    final type = _currentType;
    final l10n = AppLocalizations.of(context);
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.searchHistoryClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.searchHistoryClear),
          ),
        ],
      ),
    ).then((ok) {
      if (ok != true || !mounted) return;
      setState(() => _histories[type] = []);
      BilibiliSearchHistory.clear(type);
    });
  }

  // ── 顶栏收缩/拉伸（浏览结果时隐藏返回+搜索栏，只留选项卡） ──

  /// 顶栏是否已收缩（返回按钮 + 搜索框隐藏）。
  bool _topCollapsed = false;

  /// 向下滚动超过该偏移才触发收缩，避免在顶部轻微滑动就收起。
  static const double kCollapseScrollThreshold = 120.0;

  /// 处理结果区滚动：向下（delta>0）且超过阈值 → 收缩；向上 → 展开。
  /// 切换 Tab 时保持当前状态（见 [_onTabChanged]）。
  void _onResultsScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return;
    final metrics = notification.metrics;
    final delta = notification.scrollDelta ?? 0;
    var collapsed = _topCollapsed;
    if (delta > 0 && metrics.extentBefore > kCollapseScrollThreshold) {
      collapsed = true;
    } else if (delta < 0) {
      collapsed = false;
    } else if (metrics.extentBefore < 1) {
      collapsed = false;
    }
    if (collapsed != _topCollapsed) {
      setState(() => _topCollapsed = collapsed);
    }
  }

  BiliSearchType get _currentType =>
      BiliSearchType.values[_tabController.index];

  @override
  void initState() {
    super.initState();
    _keywordController.text = widget.initialKeyword;
    for (final type in BiliSearchType.values) {
      _data[type] = _TypeData();
      _scrollControllers[type] = ScrollController();
      _resultRefreshKeys[type] = GlobalKey<RefreshIndicatorState>();
    }
    _tabController = TabController(
      length: BiliSearchType.values.length,
      vsync: this,
    )..addListener(_onTabChanged);
    // 输入变化时重建（清空按钮的显隐依赖文本是否为空）
    _keywordController.addListener(() {
      if (mounted) setState(() {});
    });
    if (widget.initialKeyword.isNotEmpty) {
      // tag 跳转带进来的自动搜索不写入搜索历史
      if (!widget.recordInitialKeyword) {
        _skipNextRecord = true;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _submitSearch());
    }
    // 加载各分区独立搜索历史
    _loadHistories();
  }

  Future<void> _loadHistories() async {
    for (final type in BiliSearchType.values) {
      _histories[type] = await BilibiliSearchHistory.load(type);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _suggestDebounce?.cancel();
    _tabController.dispose();
    _focusNode.dispose();
    _keywordController.dispose();
    for (final c in _scrollControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    // 切换 Tab 仅懒加载当前类别；不重置滚动位置（各 Tab 滚动进度独立保存）。
    // 回顶只发生在「点击当前 Tab」时（见 _buildOvalTab）。
    final type = _currentType;
    _ensureLoaded(type);
    setState(() {});
  }

  /// 输入变化：仅刷新搜索建议，不触发搜索。
  void _onKeywordChanged(String value) {
    _suggestDebounce?.cancel();
    final term = value.trim();
    if (term.isEmpty) {
      setState(() => _suggests = []);
      return;
    }
    _suggestDebounce = Timer(const Duration(milliseconds: 200), () async {
      final list = await BilibiliSearchService.searchSuggest(term);
      if (!mounted) return;
      // 输入已变化则丢弃过期建议
      if (_keywordController.text.trim() != term) return;
      setState(() => _suggests = list);
    });
  }

  /// 点击建议项：填入输入框并直接搜索。
  void _onSuggestTap(BiliSearchSuggest suggest) {
    _suggestDebounce?.cancel();
    _keywordController.text = suggest.keyword;
    setState(() => _suggests = []);
    _submitSearch();
  }

  void _onClearKeyword() {
    _suggestDebounce?.cancel();
    _keywordController.clear();
    setState(() => _suggests = []);
    _focusNode.requestFocus();
  }

  /// 提交搜索：重置所有类别数据并加载当前类别。
  Future<void> _submitSearch() async {
    final keyword = _keywordController.text.trim();
    if (keyword.isEmpty) return;
    _suggestDebounce?.cancel();
    setState(() => _suggests = []);
    FocusScope.of(context).unfocus();
    setState(() {
      _activeKeyword = keyword;
      _topCollapsed = false;
      _videoTitleOverrides.clear();
      for (final data in _data.values) {
        data.reset();
      }
    });
    _ensureLoaded(_currentType);
    // 结果区回到顶部（当前分区；从历史/建议进入搜索时也归零）
    final sc = _scrollControllers[_currentType];
    if (sc != null && sc.hasClients) sc.jumpTo(0);
    // 记录当前分区的搜索历史（不阻塞搜索）；tag 跳转的首次搜索跳过
    if (_skipNextRecord) {
      _skipNextRecord = false;
    } else {
      _recordHistory(_currentType, keyword);
    }
  }

  void _ensureLoaded(BiliSearchType type) {
    if (_activeKeyword.isEmpty) return;
    final data = _data[type]!;
    if (data.loading || data.loadingMore) return;
    if (!data.loaded) {
      _loadType(type, refresh: true);
    }
  }

  /// 结果条目稳定去重键：视频用 BV 号、专栏用 cvid、UP 主用 mid，
  /// 其余类型用资源 id 兜底 actionUrl。
  /// 同一列表内键唯一 → 同名 Hero tag（bili_video_$bvid / article_entry_$id 等）
  /// 不会重复出现，否则 Hero 飞行会在 _allHeroesFor 处直接中断报错。
  static String _itemKey(BiliSearchItem e) {
    if (e.bvid.isNotEmpty) return '${e.type.code}:bvid:${e.bvid}';
    if (e.type == BiliSearchType.biliUser && e.mid > 0) {
      return '${e.type.code}:mid:${e.mid}';
    }
    if (e.id > 0) return '${e.type.code}:id:${e.id}';
    return '${e.type.code}:url:${e.actionUrl}';
  }

  /// 加载某类搜索结果。
  /// [refresh]：重新加载（配合 [keepItems] 不清空旧列表，加载下一页插入到顶端；
  ///   不带 keepItems 则重置并加载第一页）。
  Future<void> _loadType(
    BiliSearchType type, {
    bool refresh = false,
    bool keepItems = false,
  }) async {
    if (_activeKeyword.isEmpty) return;
    final data = _data[type]!;
    if (data.loading || data.loadingMore || data.refreshing) return;

    final keyword = _activeKeyword;
    // 首次加载（非下拉刷新）：先尝试磁盘缓存，命中即立即展示，不再请求网络
    if (refresh && !keepItems) {
      final cached = await BilibiliSearchCache.load(
        BilibiliSearchCache.keyFor(
          keyword: keyword,
          type: type,
          filterKey: _searchFilterKey(),
        ),
      );
      if (cached != null && mounted && keyword == _activeKeyword) {
        setState(() {
          data.items
            ..clear()
            ..addAll(cached.items);
          data.numResults = cached.numResults;
          data.page = cached.page;
          data.hasMore = cached.hasMore;
          data.loading = false;
          data.loadingMore = false;
          data.error = null;
          data.loaded = true;
        });
        if (type == BiliSearchType.video) _translateVideoTitles(type);
        return;
      }
    }
    if (refresh) {
      if (keepItems) {
        // 下拉刷新 / 点击当前 tab 刷新：加载下一页并插入到顶端，旧内容
        // 保留不动。已有内容时不置 loading —— 进行状态由下拉加载器
        // （下拉手势 / show()）呈现，不再整页闪回 3e 加载圈。
        data.refreshing = true;
      } else {
        data.reset();
        data.loading = true;
      }
    } else {
      data.loadingMore = true;
    }
    setState(() {});

    final nextPage = refresh && !keepItems ? 1 : data.page + 1;
    final filter = _videoFilterParams(type);
    final result = await BilibiliSearchService.searchByType(
      type: type,
      keyword: keyword,
      page: nextPage,
      gaiaVtoken: _gaiaVtoken,
      duration: filter.duration,
      tids: filter.tids,
      pubBegin: filter.pubBegin,
      pubEnd: filter.pubEnd,
    );
    if (!mounted) return;
    // 关键词已更换 → 丢弃过期结果（数据已被 _submitSearch 重置）
    if (keyword != _activeKeyword) {
      data.refreshing = false;
      return;
    }

    switch (result) {
      case BiliSearchOk(:final page):
        // 本地关键词过滤：开启 keywordFilter 时仅保留标题包含搜索词
        // 任一字符的视频，排除 B 站大数据推荐污染（标题完全不含搜索词）。
        // 注意：hasMore 仍按 B 站原始 page.items 判断，避免本页被过滤
        // 光后误判为没有更多结果而提前停止分页。
        final filtered = (type == BiliSearchType.video &&
                _filters.keywordFilter &&
                keyword.isNotEmpty)
            ? page.items
                .where((e) => _titleHasAnyKeywordChar(
                      e.titleSegments.map((s) => s.text).join(),
                      keyword,
                    ))
                .toList()
            : page.items;
        setState(() {
          if (keepItems) {
            // 下拉刷新：加载下一页后 diff，新视频插入顶部并播放入场动画
            final existingIds = data.items.map((e) => e.id).toSet();
            final freshItems = filtered
                .where((e) => !existingIds.contains(e.id))
                .toList();
            if (freshItems.isNotEmpty) {
              // 新内容插入到列表最前端，原有内容保留
              data.items.insertAll(0, freshItems);
              // 标记需要播放入场动画的项
              for (final e in freshItems) {
                data.freshInsertIds.add(e.id);
              }
              // 动画播完后清除标记（约 600ms，包含 300ms 延迟 + 300ms 动画）
              Future.delayed(const Duration(milliseconds: 700), () {
                if (mounted) {
                  setState(() => data.freshInsertIds.clear());
                }
              });
              // Android 用平台原生 Toast，其他平台用 SnackBar
              _showRefreshToast(type);
            } else {
              _showSnack(AppLocalizations.of(context).searchNoNewContent);
            }
            data.numResults = page.numResults;
            data.page = page.page;
          } else {
            // B 站搜索分页不稳定：下一页可能重复出现上一页的条目。
            // 追加前按稳定键去重（重复条目会产生同名 Hero tag，
            // 触发 "multiple heroes share the same tag" 导致转场飞行中断）。
            final seen = data.items.map(_itemKey).toSet();
            data.items.addAll(filtered.where((e) => seen.add(_itemKey(e))));
            data.numResults = page.numResults;
            data.page = page.page;
          }
          data.hasMore =
              page.items.isNotEmpty && page.items.length >= page.pageSize;
          data.error = null;
          data.loading = false;
          data.loadingMore = false;
          data.refreshing = false;
          data.loaded = true;
        });
        // 视频结果加载完毕 → 后台批量 AI 翻译标题，回填卡片
        if (type == BiliSearchType.video) {
          _translateVideoTitles(type);
        }
        // 首次请求成功：把当前累积结果写入磁盘缓存，下次同条件秒开
        if (refresh && !keepItems) {
          await BilibiliSearchCache.save(
            BilibiliSearchCache.keyFor(
              keyword: keyword,
              type: type,
              filterKey: _searchFilterKey(),
            ),
            BiliSearchCacheEntry(
              items: List.of(data.items),
              numResults: data.numResults,
              page: data.page,
              hasMore: data.hasMore,
              savedAt: DateTime.now(),
            ),
          );
        }
      case BiliSearchCaptcha(:final vVoucher):
        data.loading = false;
        data.loadingMore = false;
        data.refreshing = false;
        setState(() {});
        await _handleCaptcha(vVoucher, type);
      case BiliSearchError(:final detail):
        setState(() {
          data.error = detail;
          data.loading = false;
          data.loadingMore = false;
          data.refreshing = false;
          data.loaded = true;
        });
        _showSnack(detail);
    }
  }

  /// 后台批量 AI 翻译视频搜索结果标题，回填后 setState 刷新卡片。
  /// 仅视频类别；先读取全局缓存避免重复翻译，仅对缓存未命中的发起请求，
  /// 翻译结果同时写回全局缓存（其它页面的同 bvid 卡片也能直接显示）。
  Future<void> _translateVideoTitles(BiliSearchType type) async {
    if (type != BiliSearchType.video) return;
    final translate = BilibiliTranslateService.instance;
    if (!translate.enabled) return;
    final data = _data[type];
    if (data == null || data.items.isEmpty) return;
    final list = <({String bvid, String title})>[];
    final overrides = <String, String>{};
    final seen = <String>{};
    for (final e in data.items) {
      if (e.type != BiliSearchType.video || e.bvid.isEmpty) continue;
      if (!seen.add(e.bvid)) continue;
      final t = e.titleSegments.map((s) => s.text).join();
      if (t.isEmpty) continue;
      final cached = BilibiliTitleCache.translatedTitle(e.bvid);
      if (cached != null) {
        overrides[e.bvid] = cached;
      } else {
        list.add((bvid: e.bvid, title: t));
      }
    }
    if (overrides.isNotEmpty && mounted) {
      setState(() => _videoTitleOverrides.addAll(overrides));
    }
    if (list.isEmpty) return;
    final remote = await BilibiliTranslateApi.translateTitles(list);
    if (!mounted || remote.isEmpty) return;
    BilibiliTitleCache.rememberAll(remote);
    // 过期守卫：关键词已变或结果被清空时丢弃
    final current = _data[type];
    if (current == null || current.items.isEmpty) return;
    if (_activeKeyword.isEmpty) return;
    setState(() {
      _videoTitleOverrides.addAll(remote);
    });
  }

  void _loadMore(BiliSearchType type) {
    final data = _data[type];
    if (data == null ||
        data.loading ||
        data.loadingMore ||
        data.refreshing ||
        !data.hasMore) {
      return;
    }
    _loadType(type);
  }

  void _retry(BiliSearchType type) {
    _loadType(type, refresh: true);
  }

  // ── 视频筛选 ──

  /// 提交筛选草稿：仅在面板点击「确定」时调用，统一更新过滤条件并重新搜索，
  /// 避免用户在面板里每点一个选项就发一次请求。
  void _applyVideoFilters(_FilterState filters) {
    final changed =
        _filters.pubTime != filters.pubTime ||
        _filters.duration != filters.duration ||
        _filters.zone != filters.zone ||
        _filters.antiFuzzy != filters.antiFuzzy ||
        _filters.keywordFilter != filters.keywordFilter ||
        _filters.customBegin != filters.customBegin ||
        _filters.customEnd != filters.customEnd;
    if (!changed) return;
    _filters.pubTime = filters.pubTime;
    _filters.duration = filters.duration;
    _filters.zone = filters.zone;
    _filters.antiFuzzy = filters.antiFuzzy;
    _filters.keywordFilter = filters.keywordFilter;
    _filters.customBegin = filters.customBegin;
    _filters.customEnd = filters.customEnd;
    final videoData = _data[BiliSearchType.video]!;
    videoData.reset();
    setState(() {});
    _ensureLoaded(BiliSearchType.video);
  }

  /// 计算视频筛选请求参数（其余类型不传）。
  ({int? duration, int? tids, int? pubBegin, int? pubEnd}) _videoFilterParams(
    BiliSearchType type,
  ) {
    if (type != BiliSearchType.video) {
      return (duration: null, tids: null, pubBegin: null, pubEnd: null);
    }
    // 内容时长：0-10=1 / 10-30=2 / 30-60、60+=3（接口只支持 0-3）
    const durationMap = [null, 1, 2, 3, 3];
    final duration = _filters.duration > 0
        ? durationMap[_filters.duration]
        : null;
    final tids = _filters.zone > 0 ? _filters.zone : null;
    // 发布时间：自定义起止优先，否则按预设
    int? pubBegin;
    int? pubEnd;
    if (_filters.customBegin != null || _filters.customEnd != null) {
      pubBegin = _filters.customBegin;
      pubEnd = _filters.customEnd;
    } else {
      final now = DateTime.now();
      switch (_filters.pubTime) {
        case 1: // 最近一天
          pubBegin =
              DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/
              1000;
        case 2: // 最近一周
          pubBegin =
              DateTime(
                now.year,
                now.month,
                now.day - 6,
              ).millisecondsSinceEpoch ~/
              1000;
        case 3: // 最近半年
          pubBegin =
              DateTime(
                now.year,
                now.month,
                now.day - 179,
              ).millisecondsSinceEpoch ~/
              1000;
      }
    }
    // 防模糊：下限不早于 B 站成立日 2009-06-26
    if (_filters.antiFuzzy) {
      if (pubBegin == null || pubBegin < _antiFuzzyBegin) {
        pubBegin = _antiFuzzyBegin;
      }
    }
    return (duration: duration, tids: tids, pubBegin: pubBegin, pubEnd: pubEnd);
  }

  /// 视频筛选的缓存键摘要：筛选不同 → 不同缓存，避免张冠李戴。
  String _searchFilterKey() {
    if (_filters.pubTime == 0 &&
        _filters.duration == 0 &&
        _filters.zone == 0 &&
        !_filters.antiFuzzy &&
        !_filters.keywordFilter &&
        _filters.customBegin == null &&
        _filters.customEnd == null) {
      return '';
    }
    return 'd${_filters.duration}z${_filters.zone}'
        'p${_filters.pubTime}${_filters.antiFuzzy ? 1 : 0}'
        'k${_filters.keywordFilter ? 1 : 0}'
        '${_filters.customBegin ?? ''}-${_filters.customEnd ?? ''}';
  }

  /// 标题是否包含搜索词中的任一非空白字符（用于 [keywordFilter] 本地
  /// 过滤，排除 B 站大数据推荐污染——标题完全不含搜索词任一字的结果）。
  bool _titleHasAnyKeywordChar(String title, String keyword) {
    if (keyword.isEmpty) return true;
    for (final c in keyword.characters) {
      if (c.trim().isEmpty) continue; // 跳过空格/标点空白
      if (title.contains(c)) return true;
    }
    return false;
  }

  /// 风控验证码流程：register → 极验弹窗 → validate → 拿 grisk_id 重试。
  Future<void> _handleCaptcha(String vVoucher, BiliSearchType type) async {
    if (_captchaRunning) return;
    _captchaRunning = true;
    try {
      final registered = await BilibiliSearchService.gaiaVgateRegister(
        vVoucher,
      );
      if (!mounted) return;
      if (registered == null) {
        setState(() {
          _data[type]!.error =
              BilibiliSearchService.lastErrorDetail ??
              AppLocalizations.of(context).searchCaptchaInitFailed;
        });
        return;
      }
      // 复用本地极验滑块验证码弹窗（screens/geetest_dialog.dart）
      final geetest = await showGeetestDialog(
        context: context,
        gt: registered.gt,
        challenge: registered.challenge,
      );
      if (!mounted) return;
      if (geetest == null) {
        setState(() {
          _data[type]!.error = AppLocalizations.of(
            context,
          ).searchCaptchaIncomplete;
        });
        return;
      }
      final griskId = await BilibiliSearchService.gaiaVgateValidate(
        token: registered.token,
        challenge: geetest['geetest_challenge'] ?? '',
        validate: geetest['geetest_validate'] ?? '',
        seccode: geetest['geetest_seccode'] ?? '',
      );
      if (!mounted) return;
      if (griskId == null || griskId.isEmpty) {
        setState(() {
          _data[type]!.error =
              BilibiliSearchService.lastErrorDetail ??
              AppLocalizations.of(context).searchCaptchaValidateFailed;
        });
        _showSnack(
          AppLocalizations.of(context).searchCaptchaValidateFailedRetry,
        );
        return;
      }
      _gaiaVtoken = griskId;
      _showSnack(AppLocalizations.of(context).searchCaptchaPassed);
      await _loadType(type);
    } finally {
      _captchaRunning = false;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    showAppToast(context, message, error: true);
  }

  /// 下拉刷新后提示：Android 用平台原生 Toast，其他平台用 SnackBar。
  void _showRefreshToast(BiliSearchType type) {
    if (!mounted) return;
    final message = AppLocalizations.of(context).searchNewContentRefreshed;
    if (Platform.isAndroid) {
      NativeBridge.showToast(message);
    } else {
      showAppToast(context, '${type.label} · $message');
    }
  }

  /// 返回处理：已有搜索结果时先回到「搜索关键词页」（重置搜索状态），
  /// 未搜索时才真正退出搜索页。顶栏返回按钮与系统返回/鼠标侧键共用。
  void _handleBack() {
    if (_activeKeyword.isNotEmpty) {
      _resetToKeywordState();
    } else {
      Navigator.of(context).pop();
    }
  }

  /// 回到搜索关键词页：清空搜索结果与 Tab 数量，保留输入框里的关键词，
  /// 重新聚焦输入框，便于直接修改后再次搜索。
  void _resetToKeywordState() {
    _suggestDebounce?.cancel();
    setState(() {
      _activeKeyword = '';
      _suggests = [];
      _topCollapsed = false;
      for (final data in _data.values) {
        data.reset();
      }
    });
    _focusNode.requestFocus();
  }

  // ═════════════════════════════════════
  //  构建
  // ═════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final scaffold = Scaffold(
      backgroundColor: widget.embeddedInShell
          ? Colors.transparent
          : cs.surfaceContainer,
      body: SafeArea(
        child: Stack(
          children: [
            // ── 结果区：铺满整个内容区，内容滚动到悬浮毛玻璃栏下方 ──
            Positioned.fill(
              child: TabBarView(
                controller: _tabController,
                children: [
                  for (final type in BiliSearchType.values)
                    _TypeResultsView(
                      type: type,
                      keyword: _activeKeyword,
                      data: _data[type]!,
                      filters: _filters,
                      refreshKey: _resultRefreshKeys[type],
                      onLoadMore: () => _loadMore(type),
                      onRetry: () => _retry(type),
                      onApplyFilters: _applyVideoFilters,
                      onScroll: _onResultsScroll,
                      onRefresh: () =>
                          _loadType(type, refresh: true, keepItems: true),
                      scrollController: _scrollControllers[type]!,
                      topBarCollapsed: _topCollapsed,
                      gridMode: _gridMode,
                      onToggleGrid: _toggleGridMode,
                      history: _histories[type] ?? const [],
                      onHistoryTap: _onHistoryTap,
                      onHistoryLongPress: _onHistoryLongPress,
                      onHistoryClear: _clearHistory,
                      videoTitleOverrides: _videoTitleOverrides,
                    ),
                    ],
                  ),
                ),
                // ── 毛玻璃搜索头部：搜索栏 + 选项卡合成一个连续模糊背景 ──
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  top: 0,
                  left: 0,
                  right: 0,
                  // +2.4 适配 FrostedPanel 双层 0.6 边框导致的 BOTTOM OVERFLOWED，同时兼容 tab 区域下方安全区
                  height: _topCollapsed
                      ? kSearchTabBarHeight + 2.4
                      : kSearchBarHeight + kSearchTabBarHeight + 2.4,
                  child: FrostedSearchHeader(
                    collapsed: _topCollapsed,
                    tabBarHeight: kSearchTabBarHeight,
                    searchBar: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                      child: Row(
                        children: [
                          if (!widget.embeddedInShell) ...[
                            MorphIconButton(
                              icon: Icons.arrow_back,
                              tooltip: l10n.homeBack,
                              onTap: _handleBack,
                              frosted: true,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            // 毛玻璃搜索框：半透明 + 模糊，保留前景文字/图标色
                            child: FrostedPanel(
                              color: cs.surfaceContainerHigh.withValues(
                                alpha: 0.45,
                              ),
                              borderRadius: BorderRadius.circular(kGroupRadius),
                              child: TextField(
                                controller: _keywordController,
                                focusNode: _focusNode,
                                autofocus: widget.initialKeyword.isEmpty,
                                textInputAction: TextInputAction.search,
                                onChanged: _onKeywordChanged,
                                onSubmitted: (_) => _submitSearch(),
                                decoration: InputDecoration(
                                  hintText: l10n.searchBiliHint,
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _keywordController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: _onClearKeyword,
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      kGroupRadius,
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    tabs: [
                      for (final type in BiliSearchType.values)
                        _buildOvalTab(type),
                    ],
                    glassTabs: _buildGlassTabConfigs(),
                    glassSelectedIndex: _tabController.index,
                    onGlassTabSelected: (index) {
                      if (index != _tabController.index) {
                        _tabController.animateTo(index);
                      }
                    },
                  ),
                ),
                // ── 搜索建议下拉（覆盖整个内容区） ──
                if (_suggests.isNotEmpty) _buildSuggestPanel(cs),
              ],
            ),
          ),
        );
    // 已有搜索结果时拦截返回：先回到搜索关键词页，再按一次才退出
    // （内嵌在 SideBarShell 时区块不是路由，不拦截返回）
    return PopScope(
      canPop: widget.embeddedInShell || _activeKeyword.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || widget.embeddedInShell) return;
        _resetToKeywordState();
      },
      // 内嵌在 SideBarShell 时背景缩放由 Shell 统一提供（含侧边栏一起缩放）
      child: widget.embeddedInShell
          ? scaffold
          : IosBackdropScale(child: scaffold),
    );
  }

  /// 自定义 Tab：椭圆/胶囊 ripple（TabBar 内置 ripple 只能是圆角矩形）。
  /// 选中态：主色加粗 + 底部小胶囊指示条。
  List<GlassTab> _buildGlassTabConfigs() {
    return [
      for (final type in BiliSearchType.values)
        GlassTab(label: _searchTabLabel(type)),
    ];
  }

  String _searchTabLabel(BiliSearchType type) {
    final data = _data[type];
    final count = data?.numResults ?? 0;
    return data != null && count > 0
        ? '${type.label} ${_formatCount(count)}'
        : type.label;
  }

  Widget _buildOvalTab(BiliSearchType type, {int? selectedIndex}) {
    final label = _searchTabLabel(type);
    final cs = Theme.of(context).colorScheme;
    final selected =
        (selectedIndex ?? _tabController.index) ==
        BiliSearchType.values.indexOf(type);
    return InkWell(
      onTap: () {
        final currentIndex = _tabController.index;
        final targetIndex = type.index;
        if (currentIndex == targetIndex) {
          // 点击当前 Tab：滚回顶部并刷新
          final sc = _scrollControllers[type];
          if (sc != null && sc.hasClients && sc.offset > 0) {
            sc.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
          // 已有结果时用「下拉加载器」呈现刷新状态（show() 会自行调用
          // 该结果区的 onRefresh）；未搜索 / 无结果区时直接重拉当前页。
          if (_activeKeyword.isNotEmpty) {
            final state = _resultRefreshKeys[type]?.currentState;
            if (state != null) {
              state.show();
              return;
            }
          }
          _loadType(type, refresh: true, keepItems: true);
        } else {
          // 切换到其他 Tab
          _tabController.animateTo(targetIndex);
        }
      },
      customBorder: const StadiumBorder(),
      splashColor: cs.primary.withValues(alpha: 0.12),
      highlightColor: cs.primary.withValues(alpha: 0.08),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
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

  /// 搜索建议下拉面板（morph 分段卡片风格，覆盖整个内容区；
  /// 内容少时按内容自适应收缩，内容多时封顶并可滚动；
  /// 不随失焦/点击其他元素消失，仅在搜索、清空或输入为空时收起）。
  Widget _buildSuggestPanel(ColorScheme cs) {
    return Positioned(
      top: 56,
      left: 20,
      right: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 面板高度自适应内容：上限 = 可用高度 - 底部 4 留白；
          // 内容少时面板收缩到内容高度，不留大片空白
          final maxHeight = (constraints.maxHeight - 4).clamp(
            0.0,
            double.infinity,
          );
          return Material(
            color: cs.surfaceContainer,
            elevation: 6,
            borderRadius: BorderRadius.circular(kGroupRadius),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: buildMorphSegmentedList([
                    for (final suggest in _suggests)
                      MorphRowItem(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          leading: Icon(
                            Icons.search,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                          title: Text(
                            suggest.display,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Icon(
                            Icons.north_west,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                          onTap: () => _onSuggestTap(suggest),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 10000) {
      final w = n / 10000;
      return '${w.toStringAsFixed(w >= 100 ? 0 : 1)}${L10n.current.tenThousandUnit}';
    }
    return '$n';
  }
}

// ═════════════════════════════════════════
//  单个搜索类别的结果视图
// ═════════════════════════════════════════

class _TypeResultsView extends StatefulWidget {
  final BiliSearchType type;
  final String keyword; // 已提交关键词（空 = 未搜索）
  final _TypeData data;
  final _FilterState filters;

  /// 结果区下拉刷新指示器的 key：父级「点击当前 Tab」用它 show() 调出
  /// 下拉加载器（刷新状态不再整页闪回 3e 加载圈）。
  final GlobalKey<RefreshIndicatorState>? refreshKey;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  /// 提交筛选（面板「确定」后统一应用并重新搜索）。
  final void Function(_FilterState filters) onApplyFilters;

  /// 结果区滚动回调（供父级做顶栏收缩/拉伸）。
  final void Function(ScrollNotification notification) onScroll;

  /// 下拉刷新回调（重新加载当前类别第一页，保留用户筛选条件）。
  final Future<void> Function() onRefresh;

  /// 父级管理的滚动控制器（点击 Tab 时用于滚回顶部）。
  final ScrollController scrollController;

  /// 顶部毛玻璃搜索栏是否已收起（结果区据此动态留白）。
  final bool topBarCollapsed;

  /// 多列布局开关（视频/番剧/专栏共用，提升到父级管理）。
  final bool gridMode;

  /// 切换多列/单列布局。
  final VoidCallback onToggleGrid;

  /// 当前分区独立的搜索历史（未搜索时在内容区展示）。
  final List<String> history;

  /// 点击历史词：直接搜索。
  final ValueChanged<String> onHistoryTap;

  /// 长按历史词：删除该条。
  final ValueChanged<String> onHistoryLongPress;

  /// 清空当前分区搜索历史。
  final VoidCallback onHistoryClear;

  /// 视频结果卡片标题的 AI 翻译覆盖表（bvid → 英文标题），
  /// 只对视频类别生效；未翻译时卡片沿用原文。
  final Map<String, String> videoTitleOverrides;

  const _TypeResultsView({
    required this.type,
    required this.keyword,
    required this.data,
    required this.filters,
    this.refreshKey,
    required this.onLoadMore,
    required this.onRetry,
    required this.onApplyFilters,
    required this.onScroll,
    required this.onRefresh,
    required this.scrollController,
    required this.topBarCollapsed,
    required this.gridMode,
    required this.onToggleGrid,
    required this.history,
    required this.onHistoryTap,
    required this.onHistoryLongPress,
    required this.onHistoryClear,
    this.videoTitleOverrides = const {},
  });

  @override
  State<_TypeResultsView> createState() => _TypeResultsViewState();
}

class _TypeResultsViewState extends State<_TypeResultsView>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  /// 多列网格列数：按可用宽度自适应（每张卡片目标宽度约 [kVideoCardTargetWidth]），
  /// 至少 2 列、至多 8 列，保证窄屏/宽屏都有合理密度。
  static const double kVideoCardTargetWidth = 200.0;
  static const int kVideoCardMinColumns = 2;
  static const int kVideoCardMaxColumns = 8;

  // ── 网格行变化动画（多列布局下列数或行数变化时，卡片平滑平移） ──
  int _prevGridCols = 0;
  int _prevItemCount = 0;
  int? _prevFirstItemId;
  late final AnimationController _gridRowAnimCtrl;
  final Map<int, Offset> _itemTranslations = {};

  /// 「查看原文」原地切换：长按/右键菜单把卡片标题切换为原文的 bvid 集合
  /// （再点「查看译文」切回译文，不弹窗）。
  final Set<String> _showOriginalTitles = {};

  /// 「查看原文」原地切换：记录 bvid 的原文展示状态并刷新卡片。
  void _setShowOriginal(String bvid, bool show) {
    setState(() {
      if (show) {
        _showOriginalTitles.add(bvid);
      } else {
        _showOriginalTitles.remove(bvid);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _gridRowAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _gridRowAnimCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _itemTranslations.clear();
      }
    });
  }

  @override
  void didUpdateWidget(_TypeResultsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 布局模式在其他 Tab 切换时同步：重置本视图的网格动画基线
    if (oldWidget.gridMode != widget.gridMode) {
      _prevGridCols = 0;
      _prevItemCount = 0;
      _prevFirstItemId = null;
      _itemTranslations.clear();
    }
  }

  @override
  void dispose() {
    _gridRowAnimCtrl.dispose();
    super.dispose();
  }

  /// 检测网格布局变化并启动行平移动画。
  void _checkGridLayoutChange(int cols, int count, double cellW, double cellH) {
    if (_prevGridCols == 0) {
      _prevGridCols = cols;
      _prevItemCount = count;
      if (count > 0) _prevFirstItemId = widget.data.items[0].id;
      return;
    }
    if (_prevGridCols == cols && _prevItemCount == count) return;
    if (count == 0 || _prevItemCount == 0) {
      _prevGridCols = cols;
      _prevItemCount = count;
      if (count > 0) _prevFirstItemId = widget.data.items[0].id;
      return;
    }

    final oldCols = _prevGridCols;
    final newCols = cols;
    final minCount = _prevItemCount < count ? _prevItemCount : count;
    final newFirstId = widget.data.items[0].id;

    // 完全替换（筛选/新搜索）：不播放动画
    if (_prevFirstItemId != null && _prevFirstItemId != newFirstId) {
      _itemTranslations.clear();
      _prevGridCols = cols;
      _prevItemCount = count;
      _prevFirstItemId = newFirstId;
      return;
    }

    _itemTranslations.clear();
    bool anyMoved = false;
    for (int i = 0; i < minCount; i++) {
      final oldRow = i ~/ oldCols;
      final oldCol = i % oldCols;
      final newRow = i ~/ newCols;
      final newCol = i % newCols;
      if (oldRow != newRow || oldCol != newCol) {
        anyMoved = true;
        _itemTranslations[i] = Offset(
          (oldCol - newCol) * cellW,
          (oldRow - newRow) * cellH,
        );
      }
    }

    _prevGridCols = cols;
    _prevItemCount = count;
    _prevFirstItemId = newFirstId;

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final data = widget.data;

    if (widget.keyword.isEmpty) {
      return widget.history.isEmpty ? _buildHint(cs) : _buildHistoryView(cs);
    }
    // 首次搜索加载 / 换关键词重搜：全屏 3e 加载器（仅首次进入该类别
    // 搜索时；下拉刷新 / 点击当前 tab 的刷新保留列表，由下拉加载器呈现）
    if (!data.loaded || data.loading) {
      return const Center(child: LoadingIndicatorM3E());
    }
    // 失败
    if (data.error != null && data.items.isEmpty) {
      return _buildError(cs);
    }
    // 空结果
    if (data.items.isEmpty) return _buildNoResult(cs);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        widget.onScroll(notification);
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 300) {
          widget.onLoadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        key: widget.refreshKey,
        triggerMode: RefreshIndicatorTriggerMode.onEdge,
        edgeOffset: 0,
        displacement: 40,
        onRefresh: widget.onRefresh,
        color: Theme.of(context).colorScheme.primary,
        child: CustomScrollView(
          controller: widget.scrollController,
          physics: data.loading
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // 顶部留白：内容滚动到悬浮毛玻璃栏（搜索栏 + 选项卡）下方
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                height: widget.topBarCollapsed
                    ? kSearchTabBarHeight + 2.4
                    : kSearchBarHeight + kSearchTabBarHeight + 2.4,
              ),
            ),
            // ── 视频筛选按钮（仅视频类别显示） ──
            if (widget.type == BiliSearchType.video) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _buildFilterButton(cs),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 4)),
            ],
            // ── 分组标题 ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.numResults > 0
                            ? l10n.searchResultsCount(
                                widget.type.label,
                                _formatCount(data.numResults),
                              )
                            : widget.type.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    // ── 番剧/专栏布局切换（与视频共用 gridMode） ──
                    if (widget.type == BiliSearchType.article ||
                        widget.type == BiliSearchType.mediaBangumi)
                      Tooltip(
                        message: widget.gridMode
                            ? l10n.searchSwitchSingleCol
                            : l10n.searchSwitchMulti,
                        child: Material(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(kGroupRadius),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              widget.onToggleGrid();
                              _prevGridCols = 0;
                              _prevItemCount = 0;
                              _prevFirstItemId = null;
                              _itemTranslations.clear();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.gridMode
                                        ? Icons.grid_view_rounded
                                        : Icons.view_agenda_outlined,
                                    size: 15,
                                    color: widget.gridMode
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    widget.gridMode
                                        ? l10n.searchLayoutMulti
                                        : l10n.searchLayoutSingle,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: widget.gridMode
                                          ? FontWeight.w600
                                          : null,
                                      color: widget.gridMode
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // ── 视频/番剧/专栏：多列网格 / 单列列表；其余类型：卡片列表 ──
            if (widget.type == BiliSearchType.video)
              if (widget.gridMode) _buildVideoGrid(cs) else _buildListSliver(cs)
            else if (widget.type == BiliSearchType.mediaBangumi)
              if (widget.gridMode)
                _buildBangumiGrid(cs)
              else
                _buildListSliver(cs)
            else if (widget.type == BiliSearchType.article)
              if (widget.gridMode)
                _buildArticleGrid(cs)
              else
                _buildListSliver(cs)
            else
              _buildListSliver(cs),
            SliverToBoxAdapter(child: _buildFooter(cs)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 单列卡片列表（非视频类别固定使用，视频类别单列模式复用）。
  /// 每张卡片四个角都用完整大圆角，滚动时不会出现「中间项直角被截断」的观感。
  Widget _buildListSliver(ColorScheme cs) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in widget.data.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FreshSlideIn(
                  isFresh: widget.data.freshInsertIds.contains(item.id),
                  child: MorphItem(
                    selected: false,
                    isFirst: true,
                    isLast: true,
                    interactive: true,
                    child: _buildCard(
                      cs,
                      item,
                      // 「查看原文」原地切换后不传译文，卡片回退展示原文
                      translatedTitle: _showOriginalTitles.contains(item.bvid)
                          ? null
                          : widget.videoTitleOverrides[item.bvid],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 视频多列网格（自适应列数，网格卡片样式）。
  Widget _buildVideoGrid(ColorScheme cs) {
    final data = widget.data;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = (width / kVideoCardTargetWidth).floor().clamp(
            kVideoCardMinColumns,
            kVideoCardMaxColumns,
          );
          final cardW = (width - (columns - 1) * 12) / columns;
          final cellW = cardW + 12;
          final cellH = cardW / 0.78 + 12;
          _checkGridLayoutChange(columns, data.items.length, cellW, cellH);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = data.items[index];
              return ListenableBuilder(
                listenable: _gridRowAnimCtrl,
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(_gridRowAnimCtrl.value);
                  final delta = _itemTranslations[index];
                  Widget card = _FreshSlideIn(
                    isFresh: data.freshInsertIds.contains(item.id),
                    child: _VideoGridCard(
                      item: item,
                      // 「查看原文」原地切换后不传译文，卡片回退展示原文
                      translatedTitle: _showOriginalTitles.contains(item.bvid)
                          ? null
                          : widget.videoTitleOverrides[item.bvid],
                      showOriginal: _showOriginalTitles.contains(item.bvid),
                      onToggleOriginal: (show) =>
                          _setShowOriginal(item.bvid, show),
                      onTap: () => _openItem(item),
                    ),
                  );
                  if (delta != null && t < 1.0) {
                    card = Transform.translate(
                      offset: Offset(delta.dx * (1 - t), delta.dy * (1 - t)),
                      child: card,
                    );
                  }
                  return card;
                },
              );
            }, childCount: data.items.length),
          );
        },
      ),
    );
  }

  /// 专栏多列网格（自适应列数，使用专栏卡片样式，含与视频一致的网格动画）。
  Widget _buildArticleGrid(ColorScheme cs) {
    final data = widget.data;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = (width / kVideoCardTargetWidth).floor().clamp(
            kVideoCardMinColumns,
            kVideoCardMaxColumns,
          );
          final cardW = (width - (columns - 1) * 12) / columns;
          final cellW = cardW + 12;
          final cellH = cardW / 0.72 + 12;
          _checkGridLayoutChange(columns, data.items.length, cellW, cellH);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = data.items[index];
              return ListenableBuilder(
                listenable: _gridRowAnimCtrl,
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(_gridRowAnimCtrl.value);
                  final delta = _itemTranslations[index];
                  Widget card = _FreshSlideIn(
                    isFresh: data.freshInsertIds.contains(item.id),
                    child: _ArticleGridCard(
                      item: item,
                      onTap: () => _openItem(item),
                    ),
                  );
                  if (delta != null && t < 1.0) {
                    card = Transform.translate(
                      offset: Offset(delta.dx * (1 - t), delta.dy * (1 - t)),
                      child: card,
                    );
                  }
                  return card;
                },
              );
            }, childCount: data.items.length),
          );
        },
      ),
    );
  }

  /// 含与视频一致的网格行动画）。
  Widget _buildBangumiGrid(ColorScheme cs) {
    final data = widget.data;
    // 封面竖版 0.75 + 底部固定文字区（标题 2 行 + 评分/地区）
    const double textAreaH = 64.0;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = (width / kVideoCardTargetWidth).floor().clamp(
            kVideoCardMinColumns,
            kVideoCardMaxColumns,
          );
          final cardW = (width - (columns - 1) * 12) / columns;
          final cellW = cardW + 12;
          final cellH = cardW / 0.75 + textAreaH + 12;
          _checkGridLayoutChange(columns, data.items.length, cellW, cellH);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: cardW / (cardW / 0.75 + textAreaH),
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = data.items[index];
              return ListenableBuilder(
                listenable: _gridRowAnimCtrl,
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(_gridRowAnimCtrl.value);
                  final delta = _itemTranslations[index];
                  Widget card = _FreshSlideIn(
                    isFresh: data.freshInsertIds.contains(item.id),
                    child: _BangumiGridCard(
                      item: item,
                      onTap: () => _openItem(item),
                    ),
                  );
                  if (delta != null && t < 1.0) {
                    card = Transform.translate(
                      offset: Offset(delta.dx * (1 - t), delta.dy * (1 - t)),
                      child: card,
                    );
                  }
                  return card;
                },
              );
            }, childCount: data.items.length),
          );
        },
      ),
    );
  }

  /// 点击结果项：用户 → 应用内空间页；专栏 → 应用内专栏查看器；
  /// 视频 → 应用内视频播放页；番剧/影视 → 应用内番剧播放页；
  /// 其余 → 内置浏览器打开对应页面。
  void _openItem(BiliSearchItem item) {
    // 跳转前收起虚拟键盘并清除焦点：避免返回搜索页时
    // FocusManager 恢复搜索框焦点导致键盘再次弹出
    FocusManager.instance.primaryFocus?.unfocus();
    if (item.type == BiliSearchType.biliUser && item.mid > 0) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BilibiliUserSpacePage(mid: item.mid)),
      );
    } else if (item.type == BiliSearchType.liveRoom && item.roomId > 0) {
      // 直播间 → 应用内直播间查看页
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BilibiliLiveRoomPage(
            roomId: item.roomId,
            title: item.titleSegments.map((s) => s.text).join(),
            uname: item.subtitle,
            cover: item.cover,
          ),
        ),
      );
    } else if (item.type == BiliSearchType.article && item.id > 0) {
      // 与视频页一致的 iOS 开 App 整页放大转场：整卡 Hero 飞行期间
      // 背景渐变模糊，搜索页同步向中心缩小（关闭模糊时自动回落
      // 到经典 MaterialPageRoute + 封面飞入）
      Navigator.of(context).push(
        heroTransitionRoute(
          heroZoom: true,
          page: ArticlePage(
            cvid: item.id,
            initialTitle: item.titleSegments.map((s) => s.text).join(),
            heroTag: 'article_entry_${item.id}',
            coverUrl: item.cover,
          ),
        ),
      );
    } else if (item.type == BiliSearchType.video && item.bvid.isNotEmpty) {
      openBilibiliVideo(
        context,
        bvid: item.bvid,
        initialTitle: item.titleSegments.map((s) => s.text).join(),
        initialCover: BilibiliSearchService.coverUrl(item.cover),
        heroTag: 'bili_video_${item.bvid}',
      );
    } else if ((item.type == BiliSearchType.mediaBangumi ||
            item.type == BiliSearchType.mediaFt) &&
        item.seasonId > 0) {
      // 番剧/影视 → 应用内番剧播放页（与视频页一致的 iOS 整页放大转场）
      openBilibiliBangumi(
        context,
        seasonId: item.seasonId,
        initialTitle: item.titleSegments.map((s) => s.text).join(),
        initialCover: BilibiliSearchService.bangumiCoverUrl(item.cover),
        heroTag: 'bili_bangumi_${item.seasonId}',
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BrowserPage(
            initialUrl: item.actionUrl,
            title: item.titleSegments.map((s) => s.text).join(),
          ),
        ),
      );
    }
  }

  /// 视频筛选按钮：胶囊样式，带激活筛选数量角标，点击弹出筛选面板；
  /// 右侧为布局切换按钮（单列 / 双列，仅视频类别显示）。
  Widget _buildFilterButton(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final count = widget.filters.activeCount;
    return Row(
      children: [
        Tooltip(
          message: l10n.searchVideoFilter,
          child: Material(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(kGroupRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _openFilterPanel,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune,
                      size: 16,
                      color: count > 0 ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      count > 0
                          ? l10n.searchFilterWithCount(count)
                          : l10n.searchFilter,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: count > 0 ? FontWeight.w600 : null,
                        color: count > 0 ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // ── 布局切换：多列网格 / 单列列表（视频/番剧/专栏共用） ──
        Tooltip(
          message: widget.gridMode
              ? l10n.searchSwitchSingleCol
              : l10n.searchSwitchMulti,
          child: Material(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(kGroupRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                widget.onToggleGrid();
                _prevGridCols = 0;
                _prevItemCount = 0;
                _prevFirstItemId = null;
                _itemTranslations.clear();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.gridMode
                          ? Icons.grid_view_rounded
                          : Icons.view_agenda_outlined,
                      size: 16,
                      color: widget.gridMode ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.gridMode
                          ? l10n.searchLayoutMulti
                          : l10n.searchLayoutSingle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: widget.gridMode ? FontWeight.w600 : null,
                        color: widget.gridMode
                            ? cs.primary
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 发布时间预设 + 自定义起止日期、内容时长、内容分区、防模糊开关。
  /// 面板内调整的是「草稿」筛选状态，点击「确定」才统一提交并重新搜索；
  /// 点击「重置」恢复默认；下滑/点外部关闭则丢弃本次调整，不发起请求。
  void _openFilterPanel() {
    final cs = Theme.of(context).colorScheme;
    final filters = widget.filters;
    // 草稿状态（从当前已生效的筛选初始化）
    var draftPubTime = filters.pubTime;
    var draftDuration = filters.duration;
    var draftZone = filters.zone;
    var draftAntiFuzzy = filters.antiFuzzy;
    var draftKeywordFilter = filters.keywordFilter;
    var draftBegin = filters.customBegin;
    var draftEnd = filters.customEnd;
    // 弹出层期间抑制下层页面 iOS 景深缩放（筛选面板不缩放背景）
    PopupOverlayGuard.open();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final l10n = AppLocalizations.of(sheetContext);
            Widget sectionTitle(String title) => Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );

            // 液态玻璃下拉按钮：点击弹 showGlassDropdownMenu（liquid-dom
            // 弹簧动画 + 液态玻璃），菜单角对齐按钮角。用于发布时间 /
            // 时长 / 分区等选项较多的筛选项，替代平铺 ChoiceChip。
            Widget filterDropdown({
              required String label,
              required List<GlassMenuAction> actions,
            }) {
              return Builder(
                builder: (btnContext) => Material(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(kGroupRadius),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      final box = btnContext.findRenderObject() as RenderBox;
                      if (!box.attached) return;
                      showGlassDropdownMenu(
                        btnContext,
                        actions: actions,
                        globalPosition: box.localToGlobal(Offset.zero),
                        originSize: box.size,
                        menuWidth: 200,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            // 日期显示文本
            String fmtDate(int? ts) {
              if (ts == null) return l10n.searchFilterAny;
              final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
              return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
                  '${dt.day.toString().padLeft(2, '0')}';
            }

            Future<void> pickDate({required bool isBegin}) async {
              final current = isBegin ? draftBegin : draftEnd;
              final other = isBegin ? draftEnd : draftBegin;
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: sheetContext,
                initialDate: current != null
                    ? DateTime.fromMillisecondsSinceEpoch(current * 1000)
                    : (isBegin && other != null
                          ? DateTime.fromMillisecondsSinceEpoch(other * 1000)
                          : now),
                firstDate: isBegin
                    ? DateTime(2009, 6, 26)
                    : (draftBegin != null
                          ? DateTime.fromMillisecondsSinceEpoch(
                              draftBegin! * 1000,
                            )
                          : DateTime(2009, 6, 26)),
                lastDate: isBegin
                    ? (other != null
                          ? DateTime.fromMillisecondsSinceEpoch(other * 1000)
                          : now)
                    : now,
                helpText: isBegin
                    ? l10n.searchPickStartDate
                    : l10n.searchPickEndDate,
              );
              if (picked == null) return;
              final ts =
                  DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    isBegin ? 0 : 23,
                    isBegin ? 0 : 59,
                    isBegin ? 0 : 59,
                  ).millisecondsSinceEpoch ~/
                  1000;
              draftBegin = isBegin ? ts : draftBegin;
              draftEnd = isBegin ? draftEnd : ts;
              setSheetState(() {}); // 刷新面板中的日期按钮
            }

            // 提交草稿：统一应用筛选并重新搜索，然后关闭面板
            void apply() {
              widget.onApplyFilters(
                _FilterState()
                  ..pubTime = draftPubTime
                  ..duration = draftDuration
                  ..zone = draftZone
                  ..antiFuzzy = draftAntiFuzzy
                  ..keywordFilter = draftKeywordFilter
                  ..customBegin = draftBegin
                  ..customEnd = draftEnd,
              );
              Navigator.pop(sheetContext);
            }

            // 重置为默认筛选
            void reset() {
              draftPubTime = 0;
              draftDuration = 0;
              draftZone = 0;
              draftAntiFuzzy = false;
              draftKeywordFilter = false;
              draftBegin = null;
              draftEnd = null;
              setSheetState(() {});
            }

            return GlassMenuSurface(
              radius: 24.0,
              blur: 12.0,
              stretch: 0.3,
              legacyClipRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              legacyDecoration: BoxDecoration(
                color: cs.surfaceContainerLow.withValues(alpha: 0.75),
              ),
              content: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  24 + MediaQuery.viewPaddingOf(sheetContext).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.searchVideoFilter,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ── 发布时间（液态玻璃下拉菜单） ──
                    sectionTitle(l10n.searchPubTimeSection),
                    filterDropdown(
                      label: _pubTimeLabel(draftPubTime, l10n),
                      actions: [
                        for (var i = 0; i < kPubTimeOptions.length; i++)
                          GlassMenuAction(
                            icon: Icons.schedule,
                            text: _pubTimeLabel(i, l10n),
                            trailing:
                                (draftPubTime == i &&
                                        draftBegin == null &&
                                        draftEnd == null)
                                    ? Icon(
                                        Icons.check,
                                        size: 18,
                                        color: cs.primary,
                                      )
                                    : null,
                            onTap: () {
                              draftPubTime = i;
                              draftBegin = null;
                              draftEnd = null;
                              setSheetState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _DateButton(
                            label: l10n.searchDateBegin,
                            value: fmtDate(draftBegin),
                            active: draftBegin != null,
                            cs: cs,
                            onTap: () => pickDate(isBegin: true),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            l10n.searchDateTo,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          child: _DateButton(
                            label: l10n.searchDateEnd,
                            value: fmtDate(draftEnd),
                            active: draftEnd != null,
                            cs: cs,
                            onTap: () => pickDate(isBegin: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ── 内容时长（液态玻璃下拉菜单） ──
                    sectionTitle(l10n.searchDurationSection),
                    filterDropdown(
                      label: _durationLabel(draftDuration, l10n),
                      actions: [
                        for (var i = 0; i < kDurationOptions.length; i++)
                          GlassMenuAction(
                            icon: Icons.timelapse,
                            text: _durationLabel(i, l10n),
                            trailing: draftDuration == i
                                ? Icon(
                                    Icons.check,
                                    size: 18,
                                    color: cs.primary,
                                  )
                                : null,
                            onTap: () {
                              draftDuration = i;
                              setSheetState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ── 内容分区（液态玻璃下拉菜单，22 个分区不再平铺） ──
                    sectionTitle(l10n.searchZoneSection),
                    filterDropdown(
                      label: _zoneLabel(draftZone, l10n),
                      actions: [
                        for (final zone in kZoneOptions)
                          GlassMenuAction(
                            icon: Icons.category_outlined,
                            text: _zoneLabel(zone.tids, l10n),
                            trailing: draftZone == zone.tids
                                ? Icon(
                                    Icons.check,
                                    size: 18,
                                    color: cs.primary,
                                  )
                                : null,
                            onTap: () {
                              draftZone = zone.tids;
                              setSheetState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ── 防模糊搜索 ──
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.searchAntiFuzzy,
                        style: const TextStyle(fontSize: 15),
                      ),
                      subtitle: Text(
                        l10n.searchAntiFuzzyHint,
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: draftAntiFuzzy,
                      onChanged: (v) {
                        draftAntiFuzzy = v;
                        setSheetState(() {}); // 刷新面板中的开关态
                      },
                    ),
                    // ── 仅限标题含搜索词的视频（本地过滤，排除大数据污染） ──
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '仅限标题含搜索词的视频',
                        style: const TextStyle(fontSize: 15),
                      ),
                      subtitle: Text(
                        '开启后仅保留标题确实包含搜索词任一字符的视频，'
                        '排除 B 站大数据推荐污染，结果可能较少',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: draftKeywordFilter,
                      onChanged: (v) {
                        draftKeywordFilter = v;
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    // ── 重置 / 确定 ──
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: reset,
                            child: Text(l10n.searchFilterReset),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: apply,
                            child: Text(l10n.commonOk),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(PopupOverlayGuard.close);
  }

  Widget _buildCard(
    ColorScheme cs,
    BiliSearchItem item, {
    String? translatedTitle,
  }) {
    final isVideo = item.type == BiliSearchType.video && item.bvid.isNotEmpty;
    final hasTranslation =
        translatedTitle != null && translatedTitle.isNotEmpty;
    // 单列是横向宽行卡片：整行飞向竖屏视频页会因宽高比跨度太大而严重
    // 拉伸变形；且飞行 shuttle 在 Navigator overlay 中重建，那里没有
    // Material 祖先，整行 ListTile 会被「No Material widget found」断言
    // 打断（退出时报错）。因此只让封面缩略图作为 Hero 源 —— 与用户空间
    // 单列列表同款：进入时页面从缩略图放大，返回时精确缩回缩略图。
    final heroTag = isVideo
        ? 'bili_video_${item.bvid}'
        : item.type == BiliSearchType.article && item.id > 0
        ? 'article_entry_${item.id}'
        : (item.type == BiliSearchType.mediaBangumi ||
                  item.type == BiliSearchType.mediaFt) &&
              item.seasonId > 0
        ? 'bili_bangumi_${item.seasonId}'
        : null;
    // 整页 Hero（iOS 整卡放大）模式：源 Hero 包整个卡片（封面+文字一起
    // 运动）。注释 2299 行起对「只包缩略图」的顾虑（宽高比拉伸 / 飞行层
    // 无 Material）只适用于无 flightShuttleBuilder 的经典封面 Hero ——
    // 整页模式 shuttle 飞的是整页内容，源 child 只参与矩形测量、不会在
    // overlay 里重建整行卡片。
    final useZoomHero = heroTag != null && SettingsService.heroTransitionBlurEnabled;
    final leading = heroTag != null && !useZoomHero
        ? Hero(
            tag: heroTag,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
            child: _ItemThumb(item: item),
          )
        : _ItemThumb(item: item);
    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: leading,
      title: hasTranslation
          ? Text(
              translatedTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            )
          : Text.rich(
              TextSpan(
                children: [
                  for (final seg in item.titleSegments)
                    TextSpan(
                      text: seg.text,
                      style: seg.highlight
                          ? TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            )
                          : null,
                    ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          [item.subtitle, item.meta].where((s) => s.isNotEmpty).join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
      onTap: () => _openItem(item),
      onLongPress: isVideo
          ? () => showVideoBottomSheet(
              context,
              bvid: item.bvid,
              title: item.titleSegments.map((s) => s.text).join(),
              cover: BilibiliSearchService.coverUrl(item.cover),
              author: item.subtitle,
              showOriginal: _showOriginalTitles.contains(item.bvid),
              onToggleOriginal: (show) => _setShowOriginal(item.bvid, show),
            )
          : null,
    );
    // 桌面端右键菜单（ListTile 无 onSecondaryTapDown，用外层 GestureDetector）
    final card = GestureDetector(
      onSecondaryTapDown: isVideo
          ? (details) => showVideoContextMenu(
              context,
              bvid: item.bvid,
              title: item.titleSegments.map((s) => s.text).join(),
              cover: BilibiliSearchService.coverUrl(item.cover),
              author: item.subtitle,
              globalPosition: details.globalPosition,
              showOriginal: _showOriginalTitles.contains(item.bvid),
              onToggleOriginal: (show) => _setShowOriginal(item.bvid, show),
            )
          : null,
      child: tile,
    );
    // 视频卡片：按压边缘磁贴倾斜（与 home 磁贴同款按压反馈）。
    // 关闭描边：保留卡片自身圆角与 ripple，长按/右键菜单不受影响。
    final interactive = MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
    // 视频/专栏/番剧：经典模式 Hero 只包封面缩略图（见上方 leading），
    // 返回时页面精确缩回缩略图；整页 Hero 模式整卡 Hero 在最外层。
    if (useZoomHero) {
      return Hero(
        tag: heroTag!,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: interactive,
      );
    }
    return interactive;
  }

  Widget _buildFooter(ColorScheme cs) {
    final data = widget.data;
    if (data.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: LoadingIndicatorM3E()),
      );
    }
    if (!data.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            AppLocalizations.of(context).searchAllLoaded,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }

  Widget _buildHint(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.manage_search_rounded,
            size: 56,
            color: cs.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.searchKeywordHint,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.searchPressToSearch,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 未搜索时的内容区搜索历史（当前分区独立，与结果一样随内容滚动）。
  Widget _buildHistoryView(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        widget.onScroll(notification);
        return false;
      },
      child: CustomScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        slivers: [
          // 顶部留白：内容滚动到悬浮毛玻璃栏（搜索栏 + 选项卡）下方
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              height: widget.topBarCollapsed
                  ? kSearchTabBarHeight
                  : kSearchBarHeight + kSearchTabBarHeight,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 分区名 + 搜索历史标题 + 清空按钮
                  Row(
                    children: [
                      Icon(Icons.history, size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.type.label} · ${l10n.searchHistoryTitle}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: widget.onHistoryClear,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: cs.onSurfaceVariant,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text(
                          l10n.searchHistoryClear,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in widget.history)
                        _buildHistoryChip(cs, item),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 历史词 chip：点击直接搜索；长按删除该条。
  Widget _buildHistoryChip(ColorScheme cs, String word) {
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onHistoryTap(word),
        onLongPress: () => widget.onHistoryLongPress(word),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            word,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResult(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: cs.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.searchNoResultInType(widget.keyword, widget.type.label),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final detail = widget.data.error;
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: cs.onSurfaceVariant.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.searchFailed,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              if (detail != null && detail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // 加载失败重试：右下角 Extended FAB（重新加载）
        PositionedRetryFab(
          onRetry: widget.onRetry,
          bottomOffset: MediaQuery.paddingOf(context).bottom + 16,
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 10000) {
      final w = n / 10000;
      return '${w.toStringAsFixed(w >= 100 ? 0 : 1)}${L10n.current.tenThousandUnit}';
    }
    return '$n';
  }

  String _pubTimeLabel(int i, AppLocalizations l10n) {
    switch (i) {
      case 0:
        return l10n.searchFilterAny;
      case 1:
        return l10n.searchFilterLastDay;
      case 2:
        return l10n.searchFilterLastWeek;
      case 3:
        return l10n.searchFilterHalfYear;
    }
    return l10n.searchFilterAny;
  }

  String _durationLabel(int i, AppLocalizations l10n) {
    switch (i) {
      case 0:
        return l10n.searchFilterAllDuration;
      case 1:
        return l10n.searchFilterDur0to10;
      case 2:
        return l10n.searchFilterDur10to30;
      case 3:
        return l10n.searchFilterDur30to60;
      case 4:
        return l10n.searchFilterDur60plus;
    }
    return l10n.searchFilterAllDuration;
  }

  String _zoneLabel(int tids, AppLocalizations l10n) {
    switch (tids) {
      case 0:
        return l10n.searchZoneAll;
      case 1:
        return l10n.searchZoneAnime;
      case 13:
        return l10n.searchTypeBangumi;
      case 167:
        return l10n.searchZoneGuochuang;
      case 3:
        return l10n.searchZoneMusic;
      case 129:
        return l10n.searchZoneDance;
      case 4:
        return l10n.searchZoneGame;
      case 36:
        return l10n.searchZoneKnowledge;
      case 188:
        return l10n.searchZoneTech;
      case 234:
        return l10n.searchZoneSports;
      case 223:
        return l10n.searchZoneCar;
      case 160:
        return l10n.searchZoneLife;
      case 221:
        return l10n.searchZoneFood;
      case 217:
        return l10n.searchZoneAnimal;
      case 119:
        return l10n.searchZoneKichiku;
      case 115:
        return l10n.searchZoneFashion;
      case 202:
        return l10n.searchZoneInfo;
      case 5:
        return l10n.searchZoneEnt;
      case 181:
        return l10n.searchTypeFt;
      case 177:
        return l10n.searchZoneDoc;
      case 23:
        return l10n.searchZoneFilm;
      case 11:
        return l10n.searchZoneTv;
    }
    return l10n.searchZoneAll;
  }
}

// ═════════════════════════════════════════
//  结果缩略图（leading；用户为圆形头像，其余圆角封面 + 时长/角标）
// ═════════════════════════════════════════

class _ItemThumb extends StatelessWidget {
  final BiliSearchItem item;
  const _ItemThumb({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = item.type == BiliSearchType.biliUser;

    final fallback = Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        isUser ? Icons.person_outline : Icons.videocam_outlined,
        size: 24,
        color: cs.onSurfaceVariant.withOpacity(0.4),
      ),
    );

    final image = item.cover.isNotEmpty
        ? (isUser
              ? Image(
                  image: CachedImageProvider(
                    BilibiliSearchService.avatarUrl(item.cover),
                    headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                        ? null
                        : NetworkSettingsService.instance.apiHeaders,
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallback,
                )
              : Image(
                  image: CachedImageProvider(
                    BilibiliSearchService.coverUrl(item.cover),
                    headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                        ? null
                        : NetworkSettingsService.instance.apiHeaders,
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallback,
                ))
        : fallback;

    final thumb = SizedBox(
      width: isUser ? 52 : 96,
      height: isUser ? 52 : 60,
      child: image,
    );

    if (isUser) {
      // 头像 Hero：与 BilibiliUserSpacePage 头像（bili_space_avatar_$mid）
      // 同 tag，点击跳转时圆形头像飞入
      return Hero(
        tag: 'bili_space_avatar_${item.mid}',
        child: ClipOval(child: thumb),
      );
    }

    final thumbCard = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          thumb,
          // 时长角标（右下）
          if (item.duration.isNotEmpty)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  item.duration,
                  style: const TextStyle(fontSize: 9, color: Colors.white),
                ),
              ),
            ),
          // 角标（左上）
          if (item.badge.isNotEmpty)
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFB7299),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  item.badge,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // 视频/专栏：缩略图所在整卡由外层包 Hero（_buildCard / _ArticleGridCard），
    // 与对应页面整页 Hero 同 tag
    return thumbCard;
  }
}

// ═════════════════════════════════════════
// ═════════════════════════════════════════

class _VideoGridCard extends StatelessWidget {
  final BiliSearchItem item;
  final VoidCallback? onTap;

  /// AI 翻译后的英文标题（空 / null 时用原文）。
  final String? translatedTitle;

  /// 「查看原文」原地切换：卡片当前是否展示原文标题。
  final bool showOriginal;

  /// 「查看原文」原地切换回调（true = 切换为原文，false = 切回译文）。
  final ValueChanged<bool>? onToggleOriginal;

  const _VideoGridCard({
    required this.item,
    this.translatedTitle,
    this.onTap,
    this.showOriginal = false,
    this.onToggleOriginal,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: item.bvid.isNotEmpty
            ? () => showVideoBottomSheet(
                context,
                bvid: item.bvid,
                title: item.titleSegments.map((s) => s.text).join(),
                cover: BilibiliSearchService.coverUrl(item.cover),
                author: item.subtitle,
                showOriginal: showOriginal,
                onToggleOriginal: onToggleOriginal,
              )
            : null,
        onSecondaryTapDown: item.bvid.isNotEmpty
            ? (details) => showVideoContextMenu(
                context,
                bvid: item.bvid,
                title: item.titleSegments.map((s) => s.text).join(),
                cover: BilibiliSearchService.coverUrl(item.cover),
                author: item.subtitle,
                globalPosition: details.globalPosition,
                showOriginal: showOriginal,
                onToggleOriginal: onToggleOriginal,
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 封面 + 角标 / 播放数 / 时长 ──
            // 经典模式：Hero 只包封面区域（与视频播放页整页 Hero 同 tag），
            // 返回转场时封面精确落回卡片图片部分；整页 Hero 模式封面不
            // 单独包（整卡 Hero 在卡片最外层，见 _VideoGridCard 返回处）。
            if (item.bvid.isEmpty || SettingsService.heroTransitionBlurEnabled)
              _buildGridCover(item, cs)
            else
              Hero(
                tag: 'bili_video_${item.bvid}',
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
                child: _buildGridCover(item, cs),
              ),
            // ── 标题 + UP 主 / 弹幕数 ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (translatedTitle != null && translatedTitle!.isNotEmpty)
                      Text(
                        translatedTitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: cs.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text.rich(
                        TextSpan(
                          children: [
                            for (final seg in item.titleSegments)
                              TextSpan(
                                text: seg.text,
                                style: seg.highlight
                                    ? TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w700,
                                      )
                                    : null,
                              ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: cs.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.subtitle,
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
                            _formatCount(item.danmaku),
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

    // 按压边缘磁贴倾斜（与 home 磁贴同款按压反馈）。
    // 关闭描边：保留卡片自身圆角与 ripple，长按/右键菜单不受影响。
    final interactive = MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
    // 整页 Hero（iOS 整卡放大）模式：Hero 包整个卡片（封面 + 文字一起
    // 运动）；经典模式封面 Hero 已由封面区域单独包裹（只飞封面图）。
    if (item.bvid.isNotEmpty && SettingsService.heroTransitionBlurEnabled) {
      return Hero(
        tag: 'bili_video_${item.bvid}',
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: interactive,
      );
    }
    return interactive;
  }

  /// 网格卡片封面（16:10 图片 + 渐变遮罩 + 角标/播放数/时长）。
  Widget _buildGridCover(BiliSearchItem item, ColorScheme cs) {
    final cover = AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.cover.isNotEmpty)
            Image(
              image: CachedImageProvider(
                BilibiliSearchService.coverUrl(item.cover),
                headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                    ? null
                    : NetworkSettingsService.instance.apiHeaders,
              ),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackCover(cs),
            )
          else
            _fallbackCover(cs),
          // 底部渐变遮罩
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
          ),
          // 角标（直播 / 课堂 / 合作 等，左上）
          if (item.badge.isNotEmpty)
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFB7299),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.badge,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          // 播放数（左下）
          if (item.play > 0)
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
                    _formatCount(item.play),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // 时长（右下）
          if (item.duration.isNotEmpty)
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.duration,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
    return cover;
  }

  Widget _fallbackCover(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.videocam_outlined,
        size: 32,
        color: cs.onSurfaceVariant.withOpacity(0.4),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 10000) {
      final w = n / 10000;
      return '${w.toStringAsFixed(w >= 100 ? 0 : 1)}${L10n.current.tenThousandUnit}';
    }
    return '$n';
  }
}

// ═════════════════════════════════════════
//  筛选面板日期按钮（自定义起止日期）
// ═════════════════════════════════════════

class _DateButton extends StatelessWidget {
  final String label; // 开始 / 结束
  final String value; // 当前日期文本
  final bool active; // 是否已设置
  final ColorScheme cs;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.active,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kItemPressedRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? cs.secondaryContainer : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(kItemPressedRadius),
          border: Border.all(
            color: active ? cs.secondary.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 16,
              color: active ? cs.onSecondaryContainer : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : null,
                  color: active ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════
//  刷新项入场动画
// ═════════════════════════════════════════

/// 下拉刷新时新插入的搜索结果卡片，播放下滑 + 淡入动画。
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

// ═════════════════════════════════════════
//  专栏搜索结果多列网格卡片
// ═════════════════════════════════════════

class _ArticleGridCard extends StatelessWidget {
  final BiliSearchItem item;
  final VoidCallback? onTap;

  const _ArticleGridCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 封面 ──
            AspectRatio(
              aspectRatio: 16 / 10,
              child: item.cover.isNotEmpty
                  ? Image(
                      image: CachedImageProvider(
                        BilibiliSearchService.coverUrl(item.cover),
                        headers:
                            NetworkSettingsService.instance.apiHeaders.isEmpty
                            ? null
                            : NetworkSettingsService.instance.apiHeaders,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackCover(cs),
                    )
                  : _fallbackCover(cs),
            ),
            // ── 标题 + 作者 / 统计 ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          for (final seg in item.titleSegments)
                            TextSpan(
                              text: seg.text,
                              style: seg.highlight
                                  ? TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                    )
                                  : null,
                            ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (item.meta.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    // 整张专栏卡片（封面 + 标题文字）作为 Hero 源，
    // 与 ArticlePage 整页 Hero 同 tag —— 返回转场时整个卡片一起运动
    // （与视频网格卡片 _VideoGridCard 一致）。
    // 按压边缘磁贴倾斜（与视频卡片 / home 磁贴同款按压反馈）。
    final interactive = MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
    return Hero(tag: 'article_entry_${item.id}', child: interactive);
  }

  Widget _fallbackCover(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.article_outlined,
        size: 32,
        color: cs.onSurfaceVariant.withOpacity(0.4),
      ),
    );
  }
}

// ═════════════════════════════════════════
// ═════════════════════════════════════════

class _BangumiGridCard extends StatelessWidget {
  final BiliSearchItem item;
  final VoidCallback? onTap;

  const _BangumiGridCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 封面（竖版 0.75）+ 角标 / 话数 ──
            AspectRatio(
              aspectRatio: 0.75,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.cover.isNotEmpty)
                    Image(
                      image: CachedImageProvider(
                        BilibiliSearchService.bangumiCoverUrl(item.cover),
                        headers:
                            NetworkSettingsService.instance.apiHeaders.isEmpty
                            ? null
                            : NetworkSettingsService.instance.apiHeaders,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackCover(cs),
                    )
                  else
                    _fallbackCover(cs),
                  // 底部渐变遮罩
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 30,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 角标（追番 / 立即观看，左上）
                  if (item.badge.isNotEmpty)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFB7299),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.badge,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // 话数（index_show，右下）
                  if (item.duration.isNotEmpty)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.duration,
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
            // ── 标题 + 评分 / 地区 ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          for (final seg in item.titleSegments)
                            TextSpan(
                              text: seg.text,
                              style: seg.highlight
                                  ? TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                    )
                                  : null,
                            ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (item.meta.isNotEmpty)
                      Text(
                        item.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFB7299),
                        ),
                      ),
                    if (item.subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    // 按压边缘磁贴倾斜（与视频 / 专栏卡片同款按压反馈）。
    final interactive = MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
    // 整张番剧卡片（封面 + 标题文字）作为 Hero 源，
    // 与番剧播放页整页 Hero 同 tag —— 返回转场时整个卡片一起运动
    // （与视频网格卡片 _VideoGridCard 一致）。
    if (item.seasonId <= 0) return interactive;
    return Hero(tag: 'bili_bangumi_${item.seasonId}', child: interactive);
  }

  Widget _fallbackCover(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.movie_outlined,
        size: 32,
        color: cs.onSurfaceVariant.withOpacity(0.4),
      ),
    );
  }
}
