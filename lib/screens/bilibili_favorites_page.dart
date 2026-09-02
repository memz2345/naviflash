// lib/screens/bilibili_favorites_page.dart
//
//   - 收藏夹列表页：展示当前登录账号的收藏夹（封面 / 名称 / 数量 / 公开私密），
//     下拉刷新 / 刷新按钮静默重拉
//   - 收藏夹详情页：夹内视频浏览（参考 PiliPlus fav_detail 扩展）——
//     类别（主分区）筛选 + 排序 + 夹内搜索 + 单列/多列切换 + 触底分页
// 所有请求始终携带登录 Cookie（不受「携带 Cookie」设置影响）。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_favorite_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/comment/comment_composer_fab.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'bilibili_login_screen.dart';
import 'bilibili_related_videos_page.dart';
import 'bilibili_video_page.dart';
import 'browser_page.dart';

// 夹内筛选用的「类别」= 内容主分区（tid 与 x/v3/fav/resource/list 的
// tid 参数一致，实测服务端按主分区过滤有效）。
const List<({String name, int tid})> _kFavFolderZones = [
  (name: '动画', tid: 1),
  (name: '音乐', tid: 3),
  (name: '舞蹈', tid: 129),
  (name: '游戏', tid: 4),
  (name: '知识', tid: 36),
  (name: '科技', tid: 188),
  (name: '运动', tid: 234),
  (name: '汽车', tid: 223),
  (name: '生活', tid: 160),
  (name: '美食', tid: 211),
  (name: '动物圈', tid: 217),
  (name: '鬼畜', tid: 119),
  (name: '时尚', tid: 155),
  (name: '娱乐', tid: 5),
  (name: '影视', tid: 181),
];

/// 夹内排序（order 参数，与 PiliPlus 收藏夹排序文案一致）。
const List<({String value, String label})> _kFavSortOrders = [
  (value: 'mtime', label: '最近收藏'),
  (value: 'view', label: '最多播放'),
  (value: 'pubtime', label: '最近投稿'),
];

String _fmtFavCount(int n) {
  if (n >= 100000000) {
    return '${(n / 100000000).toStringAsFixed(1)}亿';
  }
  if (n >= 10000) {
    final v = (n / 10000).toStringAsFixed(1);
    return '${v.endsWith('.0') ? v.substring(0, v.length - 2) : v}万';
  }
  return '$n';
}

String _fmtFavDuration(int seconds) {
  if (seconds <= 0) return '';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// 相对收藏时间（供列表 meta 展示）。
String _fmtFavTime(int ts) {
  if (ts <= 0) return '';
  final t = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  final now = DateTime.now();
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return '刚刚收藏';
  if (diff.inHours < 1) return '${diff.inMinutes} 分钟前收藏';
  if (diff.inDays < 1) return '${diff.inHours} 小时前收藏';
  if (diff.inDays < 30) return '${diff.inDays} 天前收藏';
  if (t.year == now.year) return '${t.month}月${t.day}日收藏';
  return '${t.year}/${t.month}/${t.day} 收藏';
}

/// 吸顶筛选栏（搜索行 / 类别 chips 行共用）。
class _PinnedFilterBar extends SliverPersistentHeaderDelegate {
  _PinnedFilterBar({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: height, child: child);
  }

  @override
  bool shouldRebuild(covariant _PinnedFilterBar oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}

// ═════════════════════════════════════════
//  收藏夹列表页
// ═════════════════════════════════════════

class BilibiliFavoritesPage extends StatefulWidget {
  const BilibiliFavoritesPage({super.key});

  @override
  State<BilibiliFavoritesPage> createState() => _BilibiliFavoritesPageState();
}

class _BilibiliFavoritesPageState extends State<BilibiliFavoritesPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  List<BiliFavFolder>? _folders;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 首次进入页面时拉取收藏夹列表：此时才显示全屏 3e 加载器。
  Future<void> _load() async {
    setState(() {
      _loading = _folders == null;
      _error = null;
    });
    final folders = await BilibiliFavoriteService.fetchFolders();
    if (!mounted) return;
    if (folders == null) {
      setState(() {
        _loading = false;
        _error = BilibiliFavoriteService.lastErrorDetail ?? '加载失败';
      });
      return;
    }
    setState(() {
      _folders = folders;
      _loading = false;
    });
  }

  /// 刷新（下拉手势 / 刷新按钮 / 错误重试共用）：只由下拉刷新指示器
  /// 显示状态，绝不弹全屏加载器；已有内容时静默替换，失败保留旧内容。
  Future<void> _refresh() async {
    final folders = await BilibiliFavoriteService.fetchFolders();
    if (!mounted) return;
    if (folders == null) {
      if (_folders == null) {
        setState(() {
          _error = BilibiliFavoriteService.lastErrorDetail ?? '加载失败';
        });
      }
      return;
    }
    setState(() {
      _folders = folders;
      _error = null;
      _loading = false;
    });
  }

  /// 程序化调出下拉刷新指示器（刷新按钮 / 错误重试按钮使用，走 onRefresh）。
  void _showRefreshIndicator() {
    _refreshKey.currentState?.show();
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建收藏夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(hintText: '收藏夹名称', counterText: ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim().isNotEmpty),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (created != true || !mounted) return;
    final result = await BilibiliFavoriteService.createFolder(
      title: controller.text.trim(),
    );
    if (!mounted) return;
    if (!result.ok) {
      showAppToast(context, '创建失败：${result.message}');
      return;
    }
    // 静默刷新列表（新建成功后不弹全屏加载器）。
    await _refresh();
  }

  void _goLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BilibiliLoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final folders = _folders;

    return Scaffold(
      // 加载失败重试：右下角 Extended FAB（重新加载）
      floatingActionButton: folders == null && _error != null && !_loading
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 8,
              ),
              child: LoadRetryPill(onRetry: _showRefreshIndicator),
            )
          : null,
      body: RefreshIndicator(
        key: _refreshKey,
        color: cs.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: _loading
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          slivers: [
          ExpressiveSliverAppBar(
            title: 'B 站收藏夹',
            leading: MorphIconButton(
              icon: Icons.arrow_back,
              tooltip: AppLocalizations.of(context).homeBack,
              onTap: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (folders != null && folders.isNotEmpty) ...[
                MorphIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: '刷新',
                  onTap: _showRefreshIndicator,
                ),
                MorphIconButton(
                  icon: Icons.create_new_folder_outlined,
                  tooltip: '新建收藏夹',
                  onTap: _createFolder,
                ),
              ],
            ],
          ),
          if (!BilibiliFavoriteService.isLoggedIn)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_circle_outlined,
                      size: 64,
                      color: cs.onSurface.withOpacity(0.25),
                    ),
                    const SizedBox(height: 14),
                    const Text('需要登录 B 站账号'),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _goLogin,
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('去登录'),
                    ),
                  ],
                ),
              ),
            )
          else if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: LoadingIndicatorM3E()),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 56,
                      color: cs.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            )
          else if (folders == null || folders.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open_outlined,
                      size: 56,
                      color: cs.onSurface.withOpacity(0.25),
                    ),
                    const SizedBox(height: 12),
                    const Text('还没有收藏夹'),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _createFolder,
                      icon: const Icon(
                        Icons.create_new_folder_outlined,
                        size: 18,
                      ),
                      label: const Text('新建收藏夹'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _FolderCard(
                    folder: folders[index],
                    onTap: () => _openFolder(context, folders[index]),
                  ),
                  childCount: folders.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFolder(BuildContext context, BiliFavFolder folder) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BilibiliFavFolderPage(folder: folder)),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final BiliFavFolder folder;
  final VoidCallback onTap;

  const _FolderCard({required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: folder.cover.isNotEmpty
                  ? Image(
                      image: CachedImageProvider(
                        folder.cover,
                        headers:
                            NetworkSettingsService.instance.apiHeaders.isEmpty
                            ? null
                            : NetworkSettingsService.instance.apiHeaders,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(cs),
                    )
                  : _placeholder(cs),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          folder.isPublic ? Icons.public : Icons.lock_outline,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${folder.mediaCount} 个内容 · '
                          '${folder.isPublic ? '公开' : '私密'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.folder_outlined,
        size: 32,
        color: cs.onSurfaceVariant.withOpacity(0.4),
      ),
    );
  }
}

// ═════════════════════════════════════════
//  收藏夹详情页（夹内视频）
//
//  参考 PiliPlus fav_detail 扩展：
//   - 类别筛选：吸顶主分区 chips（全部 / 动画 / 音乐 / …，服务端 tid 过滤）
//   - 排序：最近收藏 / 最多播放 / 最近投稿（order 参数）
//   - 夹内搜索：吸顶搜索框（keyword 参数）
//   - 单列 / 多列布局切换：与视频页相关视频共用全局状态 + FAB
//   - 加载约定：全屏加载器只用于首次进入；已有内容时（下拉刷新 / 换筛选 /
//     排序 / 搜索）保留内容静默重拉，由下拉指示器 / 触底加载器显示状态，
//     不再弹全屏加载器造成闪烁
// ═════════════════════════════════════════

class BilibiliFavFolderPage extends StatefulWidget {
  final BiliFavFolder folder;

  const BilibiliFavFolderPage({super.key, required this.folder});

  @override
  State<BilibiliFavFolderPage> createState() => _BilibiliFavFolderPageState();
}

class _BilibiliFavFolderPageState extends State<BilibiliFavFolderPage> {
  static const double _gridTargetWidth = 200.0;
  static const int _gridMinColumns = 2;
  static const int _gridMaxColumns = 8;

  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtl = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  final List<BiliFavVideo> _videos = [];
  int _page = 1;
  bool _hasMore = true;

  /// 内容区是否展示整块（全屏）3e 加载器：仅首次进入 /
  /// 空列表上切换筛选（无内容可保留）时显示；刷新一律走下拉加载器。
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  /// 筛选条件。
  int _tid = 0; // 0 = 全部分区
  String _order = 'mtime'; // mtime / view / pubtime
  String _keyword = ''; // 夹内搜索关键字
  bool _searchOpen = false;

  /// 第 1 页请求在途 / 代次：筛选、排序、搜索、下拉刷新共用串行队列，
  /// 迟到的旧请求结果按代次丢弃。
  Future<void> _reloadChain = Future.value();
  int _epoch = 0;
  bool _busy = false;

  /// 下拉刷新指示器是否正在驱动刷新（亮圈期间 chips 等点击直接排队）。
  bool _indicatorActive = false;

  bool get _hasActiveFilter => _tid != 0 || _keyword.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _syncGridModePref();
    _reload(initial: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  /// 与视频页相关视频共用同一个单列 / 多列全局状态；冷启动时先读回持久化值。
  Future<void> _syncGridModePref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    BilibiliRelatedVideosPage.gridModeNotifier.value =
        prefs.getBool('bili_related_grid_mode') ?? true;
  }

  /// 用户触发的重拉（类别 chips / 排序 / 搜索 / 清除筛选 / 刷新按钮 /
  /// 错误重试统一入口）：一律用「下拉加载器」显示状态，绝不弹全屏加载器。
  ///  - 下拉加载器空闲：show() 亮起下拉圈，随后 RefreshIndicator 自己调用
  ///    [_indicatorRefresh] 驱动请求；
  ///  - 已有请求在跑（[_indicatorActive]）：直接排队，避免丢请求。
  void _userReload() {
    final state = _refreshKey.currentState;
    if (state == null || _indicatorActive) {
      _enqueueReload();
      return;
    }
    state.show();
  }

  /// 下拉指示器（下拉手势 / show() 调出）驱动刷新：亮圈期间置
  /// [_indicatorActive]，期间再点 chips 等直接排队而非重复 show()。
  Future<void> _indicatorRefresh() async {
    _indicatorActive = true;
    try {
      await _enqueueReload();
    } finally {
      _indicatorActive = false;
    }
  }

  /// 串行化第 1 页请求：连续切换筛选时只保留最后一个结果。
  Future<void> _enqueueReload() {
    final link = _reloadChain.then((_) => _reload());
    _reloadChain = link;
    return link;
  }

  /// 拉取第 1 页。
  ///  - [initial]=true：页面首次进入，显示整块（全屏）3e 加载器；
  ///  - 其余重拉一律不置全屏加载：有内容时保留旧内容静默重拉；无内容时
  ///    保留当前空态 / 错误视图，由调用方提供的下拉加载器显示进行状态。
  Future<void> _reload({bool initial = false}) async {
    final epoch = ++_epoch;
    _busy = true;
    if (mounted && initial) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final result = await BilibiliFavoriteService.fetchFolderVideos(
      mediaId: widget.folder.id,
      pn: 1,
      order: _order,
      keyword: _keyword,
      tid: _tid,
    );
    if (!mounted) return;
    if (epoch != _epoch) return; // 已被更新的请求取代，丢弃过期结果
    _busy = false;
    if (result == null) {
      final detail = BilibiliFavoriteService.lastErrorDetail ?? '加载失败';
      if (_videos.isEmpty) {
        setState(() {
          _loading = false;
          _error = detail;
        });
      } else {
        showAppToast(context, '刷新失败：$detail', error: true);
      }
      return;
    }
    setState(() {
      _videos
        ..clear()
        ..addAll(result.videos);
      _page = 1;
      _hasMore = result.hasMore;
      _loading = false;
      _error = null;
    });
    _jumpToTop();
  }

  void _jumpToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || _busy || _error != null) {
      return;
    }
    final epoch = _epoch;
    setState(() => _loadingMore = true);
    final result = await BilibiliFavoriteService.fetchFolderVideos(
      mediaId: widget.folder.id,
      pn: _page + 1,
      order: _order,
      keyword: _keyword,
      tid: _tid,
    );
    if (!mounted) return;
    if (result != null && epoch == _epoch) {
      final known = _videos.map((e) => e.aid).toSet();
      setState(() {
        _videos.addAll(result.videos.where((e) => !known.contains(e.aid)));
        _page += 1;
        _hasMore = result.hasMore;
      });
    }
    if (mounted) setState(() => _loadingMore = false);
  }

  void _setZone(int tid) {
    if (tid == _tid) return;
    _tid = tid;
    _userReload();
  }

  void _setOrder(String order) {
    if (order == _order) return;
    _order = order;
    _userReload();
  }

  void _toggleSearch() {
    if (_searchOpen) {
      // 收起搜索 = 清除夹内搜索条件（回到全部）
      _searchOpen = false;
      _searchCtl.clear();
      _applyKeyword('');
    } else {
      setState(() => _searchOpen = true);
    }
  }

  void _applyKeyword(String raw) {
    final keyword = raw.trim();
    if (keyword == _keyword) return;
    _keyword = keyword;
    _userReload();
  }

  void _clearSearch() {
    _searchCtl.clear();
    _applyKeyword('');
  }

  void _clearFilters() {
    final hadZone = _tid != 0;
    final hadKeyword = _keyword.isNotEmpty;
    _tid = 0;
    if (_searchOpen) _searchOpen = false;
    _searchCtl.clear();
    _keyword = '';
    if (hadZone || hadKeyword) _userReload();
  }

  void _openVideo(BuildContext ctx, BiliFavVideo video) {
    HapticFeedback.lightImpact();
    if (video.isUnavailable) {
      showAppToast(ctx, '内容已失效，无法播放', error: true);
      return;
    }
    if (video.bvid.isNotEmpty) {
      openBilibiliVideo(
        ctx,
        bvid: video.bvid,
        initialTitle: video.title,
        initialCover: video.cover,
        heroTag: 'bili_video_${video.bvid}',
      );
      return;
    }
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => BrowserPage(
          initialUrl: video.url,
          title: video.title.isEmpty ? 'B站内容' : video.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final hasContent = _videos.isNotEmpty;
    final showRetry =
        _error != null && _videos.isEmpty && !_loading;
    return Scaffold(
      // 加载失败重试：右下角 Extended FAB（重新加载）；
      // 正常浏览时才显示单列 / 多列切换 FAB（视频页同款胶囊按钮，
      // 共用同一全局状态 + 持久化）
      floatingActionButton: showRetry
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              child: LoadRetryPill(onRetry: _userReload),
            )
          : hasContent
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              child: ValueListenableBuilder<bool>(
                valueListenable: BilibiliRelatedVideosPage.gridModeNotifier,
                builder: (context, gridMode, _) {
                  return CommentComposerFab(
                    icon: gridMode
                        ? Icons.view_agenda_outlined
                        : Icons.grid_view_rounded,
                    label: gridMode
                        ? l10n.searchSwitchSingleCol
                        : l10n.searchSwitchMulti,
                    labelVisible:
                        ModalRoute.of(context)?.isCurrent ?? true,
                    onPressed: BilibiliRelatedVideosPage.toggleGridMode,
                  );
                },
              ),
            )
          : null,
      body: ValueListenableBuilder<bool>(
        valueListenable: BilibiliRelatedVideosPage.gridModeNotifier,
        builder: (context, gridMode, _) {
          return RefreshIndicator(
            key: _refreshKey,
            color: cs.primary,
            onRefresh: _indicatorRefresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                  _loadMore();
                }
                return false;
              },
              child: CustomScrollView(
                controller: _scroll,
                physics: _loading && _videos.isEmpty
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                slivers: [
                  ExpressiveSliverAppBar(
                    title: widget.folder.title,
                    leading: MorphIconButton(
                      icon: Icons.arrow_back,
                      tooltip: l10n.homeBack,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    actions: [
                      MorphIconButton(
                        icon: Icons.refresh_rounded,
                        tooltip: '刷新',
                        onTap: _userReload,
                      ),
                      MorphIconButton(
                        icon: _searchOpen
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        tooltip: _searchOpen ? '收起搜索' : '在收藏夹内搜索',
                        onTap: _toggleSearch,
                      ),
                      PopupMenuButton<String>(
                        onSelected: _setOrder,
                        itemBuilder: (context) => [
                          for (final o in _kFavSortOrders)
                            PopupMenuItem(
                              value: o.value,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(o.label),
                                  ),
                                  if (_order == o.value)
                                    Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                        ],
                        child: const MorphIconButton(
                          icon: Icons.sort_rounded,
                          tooltip: '排序方式',
                          onTap: null,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                  // ── 吸顶：夹内搜索行（展开搜索时显示） ──
                  if (_searchOpen)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedFilterBar(
                        height: 58,
                        child: _buildSearchRow(cs),
                      ),
                    ),
                  // ── 吸顶：类别（主分区）筛选 chips 行 ──
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedFilterBar(
                      height: 48,
                      child: _buildZoneBar(cs),
                    ),
                  ),
                  ..._buildContentSlivers(cs, gridMode),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 吸顶筛选栏 ──

  Widget _buildSearchRow(ColorScheme cs) {
    return Container(
      height: 58,
      padding: const EdgeInsets.fromLTRB(16, 9, 12, 9),
      color: cs.surface,
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 19, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _searchCtl,
              textInputAction: TextInputAction.search,
              onSubmitted: _applyKeyword,
              style: TextStyle(fontSize: 13.5, color: cs.onSurface),
              decoration: InputDecoration(
                isDense: true,
                hintText: '搜索夹内内容（标题 / UP 主）',
                hintStyle: TextStyle(fontSize: 13, color: cs.outline),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_keyword.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: cs.outline),
              tooltip: '清除',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              onPressed: _clearSearch,
            ),
        ],
      ),
    );
  }

  Widget _buildZoneBar(ColorScheme cs) {
    final chips = <Widget>[
      Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Text(
          _hasActiveFilter ? '' : '共 ${widget.folder.mediaCount} 条',
          style: TextStyle(fontSize: 11, color: cs.outline),
        ),
      ),
      _zoneChip(cs, '全部', 0),
      for (final z in _kFavFolderZones) _zoneChip(cs, z.name, z.tid),
    ];
    return Container(
      height: 48,
      color: cs.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: chips,
      ),
    );
  }

  Widget _zoneChip(ColorScheme cs, String label, int tid) {
    final selected = _tid == tid;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
        ),
        selectedColor: cs.secondaryContainer,
        backgroundColor: cs.surfaceContainerHigh,
        side: BorderSide.none,
        onSelected: (_) => _setZone(tid),
      ),
    );
  }

  // ── 内容区 ──

  List<Widget> _buildContentSlivers(ColorScheme cs, bool gridMode) {
    if (_loading && _videos.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: LoadingIndicatorM3E()),
        ),
        _BottomSpacer(),
      ];
    }
    if (_error != null && _videos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 56,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        const _BottomSpacer(),
      ];
    }
    if (_videos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _hasActiveFilter
                      ? Icons.search_off_rounded
                      : Icons.video_library_outlined,
                  size: 56,
                  color: cs.onSurface.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 12),
                Text(
                  _hasActiveFilter ? '没有找到相关内容' : '收藏夹还是空的',
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
                if (_hasActiveFilter) ...[
                  const SizedBox(height: 4),
                  Text(
                    '换个分类或搜索词试试',
                    style: TextStyle(fontSize: 12, color: cs.outline),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonalIcon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: const Text('清除筛选'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const _BottomSpacer(),
      ];
    }
    final content = <Widget>[
      if (gridMode)
        _buildGrid(cs)
      else
        _buildSingleList(cs),
      _buildFooter(cs),
      const _BottomSpacer(),
    ];
    return content;
  }

  Widget _buildSingleList(ColorScheme cs) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final video = _videos[index];
          final isLast = index == _videos.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : kCardGap),
            child: MorphItem(
              selected: false,
              isFirst: true,
              isLast: true,
              interactive: true,
              child: _FavVideoTile(
                video: video,
                onTap: () => _openVideo(context, video),
              ),
            ),
          );
        }, childCount: _videos.length),
      ),
    );
  }

  Widget _buildGrid(ColorScheme cs) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = (width / _gridTargetWidth)
              .floor()
              .clamp(_gridMinColumns, _gridMaxColumns);
          final cardW = (width - (columns - 1) * 12) / columns;
          // 封面 16:9 + 底部文字区约 86px
          final cellH = cardW * 9 / 16 + 86;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: cardW / cellH,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final video = _videos[index];
              return _FavVideoGridCard(
                video: video,
                onTap: () => _openVideo(context, video),
              );
            }, childCount: _videos.length),
          );
        },
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(child: LoadingIndicatorM3E()),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          _hasMore ? '上滑加载更多' : '已全部加载',
          style: TextStyle(fontSize: 12, color: cs.outline),
        ),
      ),
    );
  }
}

/// 内容区底部留白：给 FAB 与系统手势条让位。
class _BottomSpacer extends StatelessWidget {
  const _BottomSpacer();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: MediaQuery.of(context).padding.bottom + 88,
      ),
    );
  }
}

/// 单列卡片（封面 + 标题 / UP / 时长 / BV）。失效内容整卡压暗且不可打开。
class _FavVideoTile extends StatelessWidget {
  final BiliFavVideo video;
  final VoidCallback onTap;

  const _FavVideoTile({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget card = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kItemPressedRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _buildCover(cs),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BilibiliTitleCache.displayTitle(video.bvid, video.title),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (video.upper.isNotEmpty)
                    Text(
                      video.upper,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (video.duration > 0) ...[
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _fmtFavDuration(video.duration),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (video.typeLabel != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          '· ${video.typeLabel}',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.primary,
                          ),
                        ),
                      ],
                      if (video.bvid.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Text(
                          video.bvid,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (video.favTime > 0) ...[
                    const SizedBox(height: 3),
                    Text(
                      _fmtFavTime(video.favTime),
                      style: TextStyle(fontSize: 11, color: cs.outline),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
    if (video.isUnavailable) {
      card = Opacity(opacity: 0.5, child: card);
    }
    // 整页 Hero（iOS 整卡放大）模式：Hero 包整个卡片（封面 + 文字一起
    // 运动）；经典模式封面 Hero 已由 _buildCover 提供。失效内容不跳转，
    // 不参与 Hero 飞入。
    if (video.bvid.isNotEmpty &&
        !video.isUnavailable &&
        SettingsService.heroTransitionBlurEnabled) {
      return Hero(
        tag: 'bili_video_${video.bvid}',
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: card,
      );
    }
    return card;
  }

  Widget _buildCover(ColorScheme cs) {
    return Container(
      width: 120,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: cs.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      // 整页 Hero 模式：封面不单独包 Hero（整卡 Hero 在卡片最外层）；
      // 经典模式保持封面 Hero（只包封面图）。
      child: _coverImage(
        cs,
        video,
        hero: video.bvid.isNotEmpty &&
            !video.isUnavailable &&
            !SettingsService.heroTransitionBlurEnabled,
        heroTag: 'bili_video_${video.bvid}',
      ),
    );
  }
}

/// 收藏夹单列卡片与网格卡片共用的封面图。
Widget _coverImage(
  ColorScheme cs,
  BiliFavVideo video, {
  bool hero = false,
  String? heroTag,
}) {
  Widget image = video.cover.isNotEmpty
      ? Image(
          image: CachedImageProvider(
            video.cover,
            headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                ? null
                : NetworkSettingsService.instance.apiHeaders,
          ),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _coverPlaceholder(cs),
        )
      : _coverPlaceholder(cs);
  if (hero && heroTag != null) {
    image = Hero(
      tag: heroTag,
      child: image,
    );
  }
  return image;
}

Widget _coverPlaceholder(ColorScheme cs) {
  return Center(
    child: Icon(
      Icons.movie_outlined,
      size: 28,
      color: cs.onSurface.withValues(alpha: 0.3),
    ),
  );
}

/// 多列网格卡片（对齐推荐 / 搜索视频网格卡片观感）：
/// 16:9 封面 + 时长角标 / 类型角标 / 失效遮罩 + 标题 / UP / 播放·收藏时间。
class _FavVideoGridCard extends StatelessWidget {
  final BiliFavVideo video;
  final VoidCallback onTap;

  const _FavVideoGridCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unavailable = video.isUnavailable;

    final cover = Stack(
      fit: StackFit.expand,
      children: [
        _coverImage(
          cs,
          video,
          hero: video.bvid.isNotEmpty &&
              !unavailable &&
              !SettingsService.heroTransitionBlurEnabled,
          heroTag: 'bili_video_${video.bvid}',
        ),
        if (video.duration > 0)
          Positioned(
            right: 6,
            bottom: 6,
            child: _coverBadge(_fmtFavDuration(video.duration)),
          ),
        if (video.typeLabel != null)
          Positioned(
            left: 6,
            top: 6,
            child: _coverBadge(
              video.typeLabel!,
              color: cs.tertiaryContainer,
              textColor: cs.onTertiaryContainer,
            ),
          ),
        if (unavailable)
          Positioned.fill(
            child: Container(
              color: Colors.black38,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.link_off_rounded,
                    size: 22,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '已失效',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    final meta = <String>[
      if (video.play > 0) '${_fmtFavCount(video.play)}播放',
      if (video.favTime > 0) _fmtFavTime(video.favTime),
    ].join(' · ');

    Widget card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: cover),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BilibiliTitleCache.displayTitle(video.bvid, video.title),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (video.upper.isNotEmpty)
                      Text(
                        video.upper,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 2),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: cs.outline,
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
    if (unavailable) {
      card = Opacity(opacity: 0.5, child: card);
    }
    // 整页 Hero（iOS 整卡放大）模式：整卡 Hero（封面 + 文字一起运动）。
    if (video.bvid.isNotEmpty &&
        !unavailable &&
        SettingsService.heroTransitionBlurEnabled) {
      return Hero(
        tag: 'bili_video_${video.bvid}',
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: card,
      );
    }
    return card;
  }

  Widget _coverBadge(
    String text, {
    Color? color,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          color: textColor ?? Colors.white,
        ),
      ),
    );
  }
}
