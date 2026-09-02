// lib/screens/watch_history_page.dart
//
// 观看历史页（浏览足迹，区别于进度恢复）：
// - 展示 WatchHistoryService 的本地足迹（bvid + 退出时间 + 进度）
// - 顶部无痕模式开关：开启后不记录、不上报 B 站
// - 云端同步菜单：上传 / 双向同步 / 从云端恢复（基于 WebDAV，复用同步口令加密）
// - 点击条目跳转 B 站视频详情页（带标题/封面预填，避免重复请求）
// - 未登录用户也能记录本地足迹并上传 WebDAV
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/services/watch_history_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/services/webdav_service.dart';
import 'package:naviflash/services/playlist_service.dart';
import 'package:naviflash/services/cloud_sync_service.dart';
import 'package:naviflash/widgets/app_drawer.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/l10n/app_localizations.dart';

class WatchHistoryPage extends StatelessWidget {
  /// 从全局侧边栏进入：顶栏显示「菜单」按钮并可再次打开侧边栏，
  /// 而非返回箭头（与设置页一致）。
  final bool drawerMode;

  const WatchHistoryPage({super.key, this.drawerMode = false});

  @override
  Widget build(BuildContext context) {
    final wh = context.watch<WatchHistoryService>();
    final settings = context.watch<SettingsService>();
    final entries = wh.entries;
    final incognito = settings.incognitoMode;

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      drawer: drawerMode ? const AppDrawer(currentPage: 'history') : null,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainerLow),
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              ExpressiveSliverAppBar(
                title: '观看历史',
                expandedHeight: 120,
                leading: drawerMode
                    ? Builder(
                        builder: (ctx) => MorphIconButton(
                          icon: Icons.menu,
                          tooltip: '侧边栏',
                          onTap: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      )
                    : MorphIconButton(
                        icon: Icons.arrow_back,
                        tooltip: AppLocalizations.of(context).commonBackTooltip,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                actions: [
                  LiquidGlassMenuButton(
                    icon: Icons.cloud_sync_outlined,
                    tooltip: '云端同步',
                    actions: [
                      GlassMenuAction(icon: Icons.cloud_upload_outlined, text: '上传到云端', onTap: () => _doSync(context, 'upload')),
                      GlassMenuAction(icon: Icons.sync_rounded, text: '双向同步', onTap: () => _doSync(context, 'sync')),
                      GlassMenuAction(icon: Icons.cloud_download_outlined, text: '从云端恢复', onTap: () => _doSync(context, 'restore')),
                    ],
                  ),
                  if (entries.isNotEmpty)
                    MorphIconButton(
                      icon: Icons.delete_sweep_outlined,
                      tooltip: '清空',
                      onTap: () => _confirmClearAll(context, wh),
                    ),
                  const SizedBox(width: 4),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle(context, '隐私'),
                      const SizedBox(height: 12),
                      ...buildMorphSegmentedList([
                        MorphRowItem(
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            secondary: Icon(incognito ? Icons.visibility_off : Icons.history, size: 26, color: cs.primary),
                            title: const Text('无痕模式', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            subtitle: Text('开启后不记录观看历史、不上报 B 站', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                            value: incognito,
                            onChanged: (v) => settings.setIncognitoMode(v),
                          ),
                        ),
                      ]),
                      if (incognito) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 20, color: cs.primary),
                              const SizedBox(width: 10),
                              Expanded(child: Text('无痕模式已开启，观看视频不会留下任何记录', style: Theme.of(context).textTheme.bodySmall)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      if (entries.isNotEmpty) ...[
                        _buildSectionTitle(context, '观看记录 · ${entries.length}'),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
              if (entries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 72, color: cs.onSurface.withValues(alpha: 0.25)),
                        const SizedBox(height: 16),
                        Text(incognito ? '无痕模式中' : '暂无观看历史', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
                        const SizedBox(height: 8),
                        Text(incognito ? '关闭无痕后将恢复记录' : '看过的 B 站视频会显示在这里', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.35))),
                      ],
                    ),
                  ),
                ),
              if (entries.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = entries[index];
                        final isFirst = index == 0;
                        final isLast = index == entries.length - 1;
                        return Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : kCardGap),
                          child: MorphItem(selected: false, isFirst: isFirst, isLast: isLast, child: _EntryTile(entry: entry)),
                        );
                      },
                      childCount: entries.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _doSync(BuildContext context, String action) async {
    final wh = context.read<WatchHistoryService>();
    final webdav = context.read<WebDavService>();
    // CloudSyncService 构造需要 playlists，但观看历史同步不依赖它，仅注入以满足签名
    final playlists = context.read<PlaylistService>();
    final sync = CloudSyncService(webdav: webdav, playlists: playlists);
    CloudSyncResult r;
    switch (action) {
      case 'upload':
        r = await sync.pushWatchHistory(wh);
        break;
      case 'restore':
        r = await sync.syncWatchHistory(wh, restoreFromCloud: true);
        break;
      default:
        r = await sync.syncWatchHistory(wh);
    }
    if (!context.mounted) return;
    showAppToast(context, r.message, error: !r.ok);
  }

  void _confirmClearAll(BuildContext context, WatchHistoryService wh) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空观看历史'),
        content: const Text('确定清空所有本地观看历史记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              wh.clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final WatchHistoryEntry entry;
  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => _openVideo(context),
      borderRadius: BorderRadius.circular(kItemPressedRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _buildThumbnail(cs),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((entry.upperName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'UP: ${entry.upperName}',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: entry.progress,
                      minHeight: 3,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                          entry.finished ? cs.tertiary : cs.primary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (entry.finished)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(Icons.check_circle,
                              size: 14, color: cs.tertiary),
                        ),
                      Expanded(
                        child: Text(
                          _formatWatchedTime(entry.watchedAt),
                          style: textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.4),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        entry.bvid,
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.35),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.play_circle_filled_rounded,
                  color: cs.primary, size: 36),
              tooltip: '播放',
              onPressed: () => _openVideo(context),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded,
                  color: cs.onSurface.withOpacity(0.4), size: 20),
              tooltip: '删除',
              onPressed: () =>
                  context.read<WatchHistoryService>().removeByKey(entry.key),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(ColorScheme cs) {
    final url = entry.coverUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 112,
        height: 63, // 16:9
        child: (url != null && url.isNotEmpty)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(cs),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _placeholder(cs),
              )
            : _placeholder(cs),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.play_circle_outline,
            color: cs.onSurfaceVariant.withOpacity(0.4), size: 28),
      );

  void _openVideo(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BilibiliVideoPage(
        bvid: entry.bvid,
        initialTitle: entry.title,
        initialCover: entry.coverUrl,
      ),
    ));
  }

  String _formatWatchedTime(DateTime t) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(t.year, t.month, t.day));
    String two(int n) => n.toString().padLeft(2, '0');
    final hm = '${two(t.hour)}:${two(t.minute)}';
    if (diff.inDays == 0) return '今天 $hm';
    if (diff.inDays == 1) return '昨天 $hm';
    if (diff.inDays < 7) return '${diff.inDays}天前 $hm';
    if (now.year == t.year) return '${two(t.month)}-${two(t.day)} $hm';
    return '${t.year}-${two(t.month)}-${two(t.day)}';
  }
}
