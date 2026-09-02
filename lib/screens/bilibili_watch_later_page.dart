// lib/screens/bilibili_watch_later_page.dart
//
// 稍后再看页（对照 PiliPlus 的 watchLater 页面）：
//   - 列表：封面 + 标题 + UP 主 + 时长 / 进度 + 加入时间
//   - 点击用视频查看页打开（与推荐页卡片同款转场）
//   - 单条移除 / 清空全部（带确认）
//   - 进度续播提示（看到 x:xx）
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bilibili_watch_later_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/widgets/app_drawer.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';

class BilibiliWatchLaterPage extends StatefulWidget {
  /// 从全局侧边栏进入：顶栏显示「菜单」按钮并可再次打开侧边栏，
  /// 而非返回箭头（与设置页一致）。
  final bool drawerMode;

  const BilibiliWatchLaterPage({super.key, this.drawerMode = false});

  @override
  State<BilibiliWatchLaterPage> createState() => _BilibiliWatchLaterPageState();
}

class _BilibiliWatchLaterPageState extends State<BilibiliWatchLaterPage> {
  List<WatchLaterItem> _items = [];
  bool _loading = true;
  bool _clearing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('[AutoTest] WatchLater initState');
    _load();
  }

  Future<void> _load() async {
    debugPrint('[AutoTest] WatchLater fetchList start');
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    final (:items, :err) = await BilibiliWatchLaterService.fetchList();
    debugPrint('[AutoTest] WatchLater fetchList done items=${items.length} err=$err');
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
      _error = err;
    });
  }

  Future<void> _remove(WatchLaterItem item) async {
    final r = await BilibiliWatchLaterService.remove(
      aid: item.aid,
      bvid: item.bvid,
    );
    if (!mounted) return;
    if (r.ok) {
      setState(() => _items.removeWhere((e) => e.aid == item.aid));
      showAppToast(context, '已移除');
    } else {
      showAppToast(context, r.message, error: true);
    }
  }

  Future<void> _clearAll() async {
    if (_items.isEmpty || _clearing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空稍后再看', style: TextStyle(fontSize: 16)),
        content: Text(
          '将移除全部 ${_items.length} 个视频，确定继续吗？',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _clearing = true);
    final r = await BilibiliWatchLaterService.clearAll();
    if (!mounted) return;
    setState(() => _clearing = false);
    if (r.ok) {
      setState(_items.clear);
      showAppToast(context, '已清空');
    } else {
      showAppToast(context, r.message, error: true);
    }
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BilibiliLoginScreen()),
    );
  }

  String _fmtDuration(int sec) {
    if (sec <= 0) return '';
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    if (h > 0) return '$h:${two(m)}:${two(s)}';
    return '$m:${two(s)}';
  }

  String _fmtAddAt(int ts) {
    if (ts <= 0) return '';
    final t = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return '刚刚添加';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前添加';
    if (diff.inDays < 1) return '${diff.inHours} 小时前添加';
    if (t.year == now.year) return '${t.month}/${t.day} 添加';
    return '${t.year}/${t.month}/${t.day} 添加';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      drawer: widget.drawerMode
          ? const AppDrawer(currentPage: 'watchlater')
          : null,
      appBar: AppBar(
        leading: widget.drawerMode
            ? Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: '侧边栏',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              )
            : null,
        title: const Text('稍后再看'),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: '清空',
              onPressed: _clearing ? null : _clearAll,
            ),
        ],
      ),
      // 加载失败重试：右下角 Extended FAB（重新加载）
      floatingActionButton: _error != null && _items.isEmpty && !_loading
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 8,
              ),
              child: LoadRetryPill(onRetry: _load),
            )
          : null,
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (!BilibiliWatchLaterService.canUse && _items.isEmpty && !_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.watch_later_outlined, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              '登录后可以查看稍后再看',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _openLogin,
              child: const Text('去登录'),
            ),
          ],
        ),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.watch_later_outlined,
              size: 48,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              '还没有稍后再看的视频',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              '在视频页菜单里可以「添加到稍后再看」',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _buildCard(cs, _items[i]),
      ),
    );
  }

  Widget _buildCard(ColorScheme cs, WatchLaterItem item) {
    final cover = item.cover;
    final duration = _fmtDuration(item.duration);
    final progress = _fmtDuration(item.progress);
    final showProgress =
        item.progress > 0 && item.duration > 0 && item.progress < item.duration;
    final addAt = _fmtAddAt(item.addAt);
    final meta = <String>[
      if (duration.isNotEmpty) duration,
      if (showProgress) '看到 $progress',
      if (addAt.isNotEmpty) addAt,
    ].join(' · ');

    return Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (item.bvid.isEmpty) return;
          openBilibiliVideo(
            context,
            bvid: item.bvid,
            initialTitle: item.title,
            initialCover: item.cover,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 148,
                  height: 93,
                  child: cover.isEmpty
                      ? Container(
                          color: cs.surfaceContainerHighest,
                          child: Icon(
                            Icons.movie_outlined,
                            color: cs.onSurfaceVariant,
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image(
                              image: CachedImageProvider(cover),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: cs.surfaceContainerHighest,
                              ),
                            ),
                            if (showProgress)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: LinearProgressIndicator(
                                  value: item.progress / item.duration,
                                  minHeight: 3,
                                  backgroundColor: Colors.black38,
                                  valueColor: AlwaysStoppedAnimation(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // 信息
              Expanded(
                child: SizedBox(
                  height: 93,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.isEmpty ? '（无标题）' : item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (item.upName.isNotEmpty)
                        Text(
                          item.upName,
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
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // 移除
              SizedBox(
                width: 32,
                height: 93,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  tooltip: '移除',
                  onPressed: () => _remove(item),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
