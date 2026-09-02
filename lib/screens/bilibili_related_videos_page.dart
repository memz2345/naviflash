// lib/screens/bilibili_related_videos_page.dart
//
// 相关视频独立 page，横竖屏复用：
//   - 单列 / 多列布局可手动切换（状态全局共享 + 持久化）
//   - 卡片样式 / 入场动画对齐搜索视频 / 专栏页
//   - 长按 / 右键菜单 + 封面 Hero
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bilibili_translate_api.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:naviflash/services/bilibili_video_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/MetroTile.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/search_video_menu.dart';

class BilibiliRelatedVideosPage extends StatefulWidget {
  /// 当前视频 bvid。
  final String bvid;

  /// 竖屏时把操作区（标题/UP/动作栏等）作为 header 随列表一起滚动。
  final Widget? header;

  /// 视频播放页的整页 Hero 包裹期间为 true：此时卡片不能用 Hero 包裹
  /// （Flutter 禁止 Hero 嵌套 Hero），跳转也不传 heroTag。
  final bool heroTagsDisabled;

  const BilibiliRelatedVideosPage({
    super.key,
    required this.bvid,
    this.header,
    this.heroTagsDisabled = false,
  });

  // ── 单列 / 多列状态：全局共享（所有相关视频列表共用）并持久化 ──
  static final ValueNotifier<bool> _gridMode = ValueNotifier(true);
  static bool _gridLoaded = false;

  /// 视频页统一 FAB 用：读取 / 切换单列·多列状态（全局共享）。
  static ValueNotifier<bool> get gridModeNotifier => _gridMode;
  static void toggleGridMode() {
    _gridMode.value = !_gridMode.value;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('bili_related_grid_mode', _gridMode.value),
    );
  }

  @override
  State<BilibiliRelatedVideosPage> createState() =>
      _BilibiliRelatedVideosPageState();
}

class _BilibiliRelatedVideosPageState extends State<BilibiliRelatedVideosPage>
    with AutomaticKeepAliveClientMixin {
  List<BiliRelatedVideo>? _items;
  bool _loading = true;
  String? _error;

  /// AI 翻译后的标题覆盖表（bvid → 英文标题）。
  final Map<String, String> _titleOverrides = {};

  /// 「查看原文」原地切换：长按/右键菜单把卡片标题切换为原文的 bvid 集合
  /// （再点「查看译文」切回译文，不弹窗）。
  final Set<String> _showOriginalTitles = {};

  // ── 会话级缓存：跨布局切换（宽屏 ↔ 紧凑）复用同一 bvid 的数据，
  //    避免重新拉取 / 重新播放入场动画 ──
  static const Duration _cacheTtl = Duration(minutes: 10);
  static final Map<String, _CachedRelated> _cache = {};
  static final Set<String> _animatedBvids = {};

  /// 本次构建的推荐卡片是否播放入场动画（仅首次网络加载时播一次）。
  bool _animateCards = false;

  Future<void> _ensureGridLoaded() async {
    if (BilibiliRelatedVideosPage._gridLoaded) return;
    BilibiliRelatedVideosPage._gridLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    BilibiliRelatedVideosPage._gridMode.value =
        prefs.getBool('bili_related_grid_mode') ?? true;
  }

  void _onGridModeChanged() {
    if (mounted) setState(() {});
  }

  @override
  bool get wantKeepAlive => true;

  /// 卡片展示用标题：优先本地已翻译，再查全局缓存，否则原文；
  /// 「查看原文」原地切换后直接展示原文。
  String _titleFor(BiliRelatedVideo item) {
    if (_showOriginalTitles.contains(item.bvid)) return item.title;
    final local = _titleOverrides[item.bvid];
    if (local != null && local.isNotEmpty) return local;
    return BilibiliTitleCache.displayTitle(item.bvid, item.title);
  }

  /// 批量 AI 翻译所有相关视频标题（静默失败，不影响原文）。
  /// 先读取全局缓存避免重复翻译，未命中的发起请求并写回缓存。
  Future<void> _translateTitles() async {
    final items = _items;
    if (items == null || items.isEmpty) return;
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
    setState(() {
      _titleOverrides.addAll(remote);
    });
  }

  @override
  void initState() {
    super.initState();
    _ensureGridLoaded();
    BilibiliRelatedVideosPage._gridMode.addListener(_onGridModeChanged);
    // 布局切换重建 State 时直接复用已缓存数据（不重新拉取、不播动画）。
    final cached = _cache[widget.bvid];
    if (cached != null && DateTime.now().difference(cached.time) < _cacheTtl) {
      _items = cached.items;
      _loading = false;
      _error = null;
      // 缓存命中：仍然发起标题批量翻译（结果返回后 setState 刷新）
      _translateTitles();
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    BilibiliRelatedVideosPage._gridMode.removeListener(_onGridModeChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BilibiliRelatedVideosPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bvid != widget.bvid) {
      // 换视频：旧列表作废，走整屏加载
      _items = null;
      _load(forceRefresh: true);
    }
  }

  /// 拉取相关视频。
  /// [fromPull] = 由下拉刷新指示器驱动：无论列表是否为空都保留当前视图
  /// （状态由下拉加载器呈现），绝不弹全屏加载器。
  Future<void> _load({
    bool forceRefresh = false,
    bool fromPull = false,
  }) async {
    final keep = fromPull || (_items?.isNotEmpty ?? false);
    if (!keep) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final list = await BilibiliVideoService.fetchRelated(
      widget.bvid,
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;
    // 去重（Hero 同名 tag 不允许重复出现）
    final seen = <String>{};
    final deduped = list
        .where((v) => v.bvid.isNotEmpty && seen.add(v.bvid))
        .toList();
    // 下拉刷新失败（服务端异常）：保留旧内容静默失败，不清空列表
    final failed = deduped.isEmpty && BilibiliVideoService.lastErrorDetail != null;
    final firstTime = _animatedBvids.add(widget.bvid);
    if (!failed || !keep) {
      _cache[widget.bvid] = _CachedRelated(deduped);
    }
    setState(() {
      _loading = false;
      if (!failed || !keep) {
        _items = deduped;
        _animateCards = firstTime;
        _error = deduped.isEmpty ? BilibiliVideoService.lastErrorDetail : null;
      }
    });
    // 网络加载后批量翻译标题（异步，翻译完成回填卡片）
    _translateTitles();
    if (firstTime) {
      // 动画播过一次后立刻复位，后续重建（切单列/多列、滚动等）不再动画。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _animateCards = false);
      });
    }
  }

  void _open(BiliRelatedVideo item) {
    // 竖屏：带 heroTag → 视频播放页使用整页 Hero 放大（iOS 开 App）；
    // 宽屏：wideClassic → 标准 MaterialPageRoute + 封面 Hero（无模糊）。
    // 整页 Hero 包裹期间（heroTagsDisabled）不传 tag，避免嵌套 Hero。
    openBilibiliVideo(
      context,
      bvid: item.bvid,
      initialTitle: _titleFor(item),
      initialCover: item.pic,
      heroTag: widget.heroTagsDisabled ? null : 'bili_video_${item.bvid}',
      wideClassic: true,
    );
  }

  void _showLongPressMenu(BiliRelatedVideo item) {
    showVideoBottomSheet(
      context,
      bvid: item.bvid,
      title: item.title,
      cover: item.pic,
      author: item.ownerName,
      showOriginal: _showOriginalTitles.contains(item.bvid),
      onToggleOriginal: (show) => _setShowOriginal(item.bvid, show),
    );
  }

  /// 右键：桌面端上下文菜单（与搜索页一致，保持不变）。
  void _showContextMenu(BiliRelatedVideo item, Offset globalPosition) {
    showVideoContextMenu(
      context,
      bvid: item.bvid,
      title: item.title,
      cover: item.pic,
      author: item.ownerName,
      globalPosition: globalPosition,
      showOriginal: _showOriginalTitles.contains(item.bvid),
      onToggleOriginal: (show) => _setShowOriginal(item.bvid, show),
    );
  }

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
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final items = _items;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true, fromPull: true),
          color: cs.primary,
          child: CustomScrollView(
            physics: _loading
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
            slivers: [
              if (widget.header != null)
                SliverToBoxAdapter(child: widget.header),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: LoadingIndicatorM3E()),
                )
              else if (_error != null && items!.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _errorView(cs))              else if (items!.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).relatedEmpty,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else if (!BilibiliRelatedVideosPage._gridMode.value)
                // 单列：搜索页单列卡片样式
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _CardEntrance(
                              index: i,
                              animate: _animateCards,
                              child: _listCard(cs, items[i]),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                // 多列：搜索视频网格卡片样式（列数随宽度自适应）
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      final columns = width >= 720 ? 3 : 2;
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _CardEntrance(
                            index: i,
                            animate: _animateCards,
                            child: _gridCard(cs, items[i]),
                          ),
                          childCount: items.length,
                        ),
                      );
                    },
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 24,
                ),
              ),
            ],
          ),
        ),
        // 加载失败重试：右下角 Extended FAB（重新加载）
        if (_error != null && items != null && items.isEmpty)
          PositionedRetryFab(onRetry: () => _load(forceRefresh: true)),
      ],
    );
  }

  Widget _errorView(ColorScheme cs) {
    return Center(
      child: Text(
        _error ?? AppLocalizations.of(context).biliLoadFailed,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
    );
  }

  // 单列/多列切换 FAB 已提升到视频页统一 FAB（见 bilibili_video_page._buildSharedFab）。

  // ─── 多列：网格卡片（对齐搜索视频网格卡片样式） ───
  Widget _gridCard(ColorScheme cs, BiliRelatedVideo item) {
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
            // ── 封面 + 播放数 / 时长 ──
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _heroThumb(item, cs),
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
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 播放数（左下）
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
                  // 时长（右下）
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
            // ── 标题 + 时间/UP + 弹幕数 ──
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
    return _wrapCard(item, card);
  }

  // ─── 单列：列表卡片（对齐搜索页单列卡片样式） ───
  Widget _listCard(ColorScheme cs, BiliRelatedVideo item) {
    // 单列是横向宽行卡片：整行飞向竖屏视频页会因宽高比跨度太大而严重
    // 拉伸变形。因此只让封面缩略图作为 Hero 源（与用户空间单列列表
    // 同款）：进入时页面从缩略图放大，返回时精确缩回缩略图。
    // Hero 由 [_heroThumb] 内部包裹（只飞封面背景图）。
    final thumb = _heroThumb(item, cs, width: 148, height: 84);
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
                child: SizedBox(
                  height: 84,
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
              ),
            ],
          ),
        ),
      ),
    );
    return _wrapCard(item, card);
  }

  /// 卡片外包装：横竖屏都加磁贴倾斜（与搜索页卡片一致）。
  /// 经典模式 Hero 由封面 [_heroThumb] / 单列缩略图自行包裹（只飞封面
  /// 背景图，不带卡片文字）；整页 Hero（iOS 整卡放大）模式且
  /// [heroWholeCard] 时，Hero 包整个卡片（封面 + 文字一起运动）。
  /// 整页 Hero 包裹期间（[BilibiliRelatedVideosPage.heroTagsDisabled]）
  /// 封面也不包。
  Widget _wrapCard(
    BiliRelatedVideo item,
    Widget card, {
    bool heroWholeCard = true,
  }) {
    if (heroWholeCard && SettingsService.heroTransitionBlurEnabled) {
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

  /// 封面缩略图（Hero 包在封面图上，只飞背景图不带卡片文字；
  /// 列表卡由 [_listCard] 自行包裹时宽度跨度大，同样只包缩略图）。
  Widget _heroThumb(
    BiliRelatedVideo item,
    ColorScheme cs, {
    double? width,
    double? height,
  }) {
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    Widget img = item.pic.isEmpty
        ? Container(
            color: Colors.grey.shade800,
            child: const Center(
              child: Icon(Icons.movie_outlined, color: Colors.white24),
            ),
          )
        : Image(
            image: CachedImageProvider(item.pic, headers: headers),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade800,
              child: const Center(
                child: Icon(Icons.movie_outlined, color: Colors.white24),
              ),
            ),
          );
    final thumb = width != null && height != null
        ? SizedBox(width: width, height: height, child: img)
        : AspectRatio(aspectRatio: 16 / 10, child: img);
    // 当前视频（widget.bvid 相同）、整页 Hero 包裹期间（heroTagsDisabled）
    // 或整页 Hero（iOS 整卡放大）模式（整卡 Hero 在 _wrapCard 外层）都
    // 不在此包 Hero。
    if (item.bvid == widget.bvid ||
        widget.heroTagsDisabled ||
        SettingsService.heroTransitionBlurEnabled) {
      return thumb;
    }
    return Hero(
      tag: 'bili_video_${item.bvid}',
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
      child: thumb,
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

class _CardEntrance extends StatefulWidget {
  final int index;
  final bool animate;
  final Widget child;

  const _CardEntrance({
    required this.index,
    required this.animate,
    required this.child,
  });

  @override
  State<_CardEntrance> createState() => _CardEntranceState();
}

class _CardEntranceState extends State<_CardEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scale = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    if (widget.animate) {
      // 交错延迟：让列表布局先完成，再依次入场
      Future.delayed(Duration(milliseconds: 40 + widget.index * 20), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// 相关视频列表缓存条目。
class _CachedRelated {
  final List<BiliRelatedVideo> items;
  final DateTime time;
  _CachedRelated(this.items) : time = DateTime.now();
}
