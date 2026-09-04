// lib/widgets/live_room_grid.dart
//
// 直播间卡片 / 自适应网格（从 bilibili_live_page 抽出共用）：
//   - LiveRoomGrid：下拉刷新 + 触底加载 + 错误重试 + 空态
//   - LiveRoomCard：点击进入直播间查看页（BilibiliLiveRoomPage），
//     长按仍可用内置浏览器打开网页兜底
// 数据来源见 services/bilibili_live_service.dart。
import 'package:flutter/material.dart';
import 'package:naviflash/src/content_reveal_gate.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/MetroTile.dart';
import 'package:naviflash/screens/bilibili_live_room_page.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/widgets/lazy_cover_image.dart';
import 'package:naviflash/services/network_settings_service.dart';

// ════════════════════════════════════════
//  通用直播间列表（推荐 / 分区 / 关注 / 分类共用）
// ════════════════════════════════════════

class LiveRoomGrid extends StatefulWidget {
  /// 按页码拉取数据（page 从 1 起）。
  final Future<LiveResult<LiveRoomItem>> Function(int page) loader;

  /// 变化后重置列表并回到第 1 页（切换分区 / 排序 / 账号时使用）。
  final Object? resetKey;

  final String emptyText;

  /// 每页条数（仅用于「是否还有更多」的推断，实际由 loader 决定）。
  final int pageSize;

  /// 外部滚动控制器（宿主需要「滚回顶部 / 统一监听」时传入；
  /// 不传则内部自建，并随组件销毁）。
  final ScrollController? scrollController;

  /// 网格内边距（默认 16/8/16/16）。
  final EdgeInsets? padding;

  /// 网格最大列数（宽屏想更密时调大；默认 4，与旧直播页一致）。
  final int maxColumns;

  const LiveRoomGrid({
    super.key,
    required this.loader,
    this.resetKey,
    this.emptyText = '暂无内容',
    this.pageSize = 30,
    this.scrollController,
    this.padding,
    this.maxColumns = 4,
  });

  @override
  State<LiveRoomGrid> createState() => _LiveRoomGridState();
}

class _LiveRoomGridState extends State<LiveRoomGrid>
    with AutomaticKeepAliveClientMixin {
  ScrollController? _ownedScroll;

  ScrollController get _scroll =>
      widget.scrollController ?? (_ownedScroll ??= ScrollController());

  List<LiveRoomItem> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  /// 内容延迟显示门控：大量直播间卡片在转场动画途中一次上屏会把动画顶掉
  /// 帧，故动画未结束前即便数据已就绪也继续显示加载指示器。
  ContentRevealGate? _revealGate;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(forceRefresh: true);
  }

  @override
  void didUpdateWidget(covariant LiveRoomGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetKey != widget.resetKey) {
      _load(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    _revealGate?.dispose();
    _revealGate = null;
    // 仅释放自建的控制器；外部传入的由宿主负责
    _ownedScroll?.dispose();
    _ownedScroll = null;
    super.dispose();
  }

  /// 起一个内容显示门控：路由转场动画结束后才允许显示列表。
  /// 详见 [ContentRevealGate]。
  void _armRevealGate() {
    _revealGate?.dispose();
    _revealGate = ContentRevealGate(
      // 门控解锁后自身的 isGated 已翻转，这里只需触发一次重建。
      onUnlock: () {
        if (mounted) setState(() {});
      },
    )..arm(context);
  }

  /// 列表是否仍需显示加载指示器（= 动画未结束，内容先压着不上屏）。
  bool get _isContentGated => _revealGate?.isGated ?? false;

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) _loadMore();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!forceRefresh && (_loading || _loadingMore)) return;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
    });
    // 仅整屏换内容这一轮门控（首屏 / 切换 resetKey），加载更多保留时不门控
    // —— 否则列表会被门控的保守帧闪回成整屏加载圈。
    if (forceRefresh || _items.isEmpty) {
      _armRevealGate();
    }
    final targetPage = forceRefresh ? 1 : _page + 1;
    final result = await widget.loader(targetPage);
    if (!mounted) return;
    switch (result) {
      case LiveOk<LiveRoomItem>(:final items, :final hasMore):
        // 后端部分接口会回传重复房间，按 roomId 去重后再追加
        final seen = <int>{for (final it in _items) it.roomId};
        final fresh = items.where((it) => seen.add(it.roomId)).toList();
        setState(() {
          if (forceRefresh) {
            _items = fresh;
            _page = 1;
          } else {
            _items = [..._items, ...fresh];
            _page = targetPage;
          }
          _hasMore = hasMore;
          _loading = false;
          _loadingMore = false;
          _error = null;
        });
      case LiveError<LiveRoomItem>(:final detail):
        setState(() {
          _loading = false;
          _loadingMore = false;
          // 加载更多失败只静默结束，避免整页被错误态替换
          if (forceRefresh || _items.isEmpty) _error = detail;
          if (!forceRefresh) _hasMore = false;
        });
    }
  }

  void _loadMore() {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    // [_isContentGated]：数据已就绪但动画未结束，继续压着不上屏。
    if (_loading || _isContentGated) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          // 加载失败重试：右下角 Extended FAB（重新加载）
          PositionedRetryFab(onRetry: () => _load(forceRefresh: true)),
        ],
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          widget.emptyText,
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      color: cs.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns =
              (width / 200).floor().clamp(2, widget.maxColumns);
          return GridView.builder(
            controller: _scroll,
            physics: const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: widget.padding ??
                const EdgeInsets.fromLTRB(16, 8, 16, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              // 与视频卡片网格同款几何（推荐页 / 分类房间页均为 0.78 + 12 间距）：
              // 之前这里公式写反（cover 按 1.6 倍宽预留），Cell 过长、
              // 空白全堆在卡片肚子里。
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: _items.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= _items.length) {
                return _loadingMore
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              }
              return LiveRoomCard(item: _items[i]);
            },
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════
//  直播间卡片（视频卡片同款外观）：
//  16/10 封面 + 底部渐变 + 左下白字人气（≈视频播放量）+
//  右下分区角标（≈视频时长角标）+ 双行标题 + 主播行（右附直播中）。
//  数据缺时长/弹幕，用分区/直播中占位；行为不变（点进房/长按浏览器兜底）。
// ════════════════════════════════════════

class LiveRoomCard extends StatelessWidget {
  final LiveRoomItem item;

  const LiveRoomCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;

    // 封面：可视区门控 + ≤480 CDN 缩略图（直播封面原图较大，逐格
    // 全尺寸解码会在滚动时造成 decode 尖峰与 ImageCache 颠簸）。
    final cover = LazyCoverImage(
      item.cover,
      headers: headers,
      fit: BoxFit.cover,
      maxDimension: 480,
    );

    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openRoom(context),
        onLongPress: () => _openInBrowser(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  cover,
                  // 底部渐变（视频卡片同款，衬左下人气/右下角标）
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
                  // 左下：人气（视频卡片播放量同款）
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
                          _onlineText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 右下：分区（视频卡片时长角标同款位置）
                  if (_areaText.isNotEmpty)
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
                          _areaText,
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
                        Expanded(
                          child: Text(
                            item.uname.isEmpty ? '未知主播' : item.uname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '直播中',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent,
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
    // 视频卡片同款磁贴包装（桌面端悬停倾斜；分类页直播卡片同款）。
    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
  }

  void _openRoom(BuildContext context) {
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

  /// 长按兜底：直播播放页不可用时仍可在浏览器观看。
  void _openInBrowser(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrowserPage(
          initialUrl: item.url,
          title: item.title.isEmpty ? '直播间' : item.title,
        ),
      ),
    );
  }

  String get _onlineText {
    if (item.onlineText.isNotEmpty) return item.onlineText;
    return _fmtCount(item.online);
  }

  /// 优先显示二级分区，其次一级分区。
  String get _areaText {
    if (item.areaName.isNotEmpty) return item.areaName;
    return item.parentAreaName;
  }

  String _fmtCount(int n) {
    if (n >= 100000000) return '${(n / 100000000).toStringAsFixed(1)} 亿';
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)} 万';
    return '$n';
  }
}
