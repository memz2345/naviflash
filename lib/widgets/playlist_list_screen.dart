// lib/widgets/playlist_list_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/services/playlist_service.dart';
import 'package:naviflash/services/webdav_service.dart';
import 'package:naviflash/services/cloud_sync_service.dart';
import 'package:naviflash/screens/player.dart';
import 'package:naviflash/widgets/widgets.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/playlist_create_dialog.dart';
import 'package:naviflash/widgets/playlist_detail_screen.dart';
import 'package:naviflash/l10n/app_localizations.dart';

/// 播放列表管理页（M3 Expressive 风格）
class PlaylistListScreen extends StatefulWidget {
  const PlaylistListScreen({super.key});

  @override
  State<PlaylistListScreen> createState() => _PlaylistListScreenState();
}

class _PlaylistListScreenState extends State<PlaylistListScreen> {
  bool _syncing = false;

  // ─── 操作 ───

  /// 云同步操作统一入口：执行 + 结果 SnackBar
  Future<void> _runSync(
    Future<CloudSyncResult> Function(CloudSyncService sync) action,
  ) async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final webdav = context.read<WebDavService>();
    final playlists = context.read<PlaylistService>();
    final result = await action(CloudSyncService(
      webdav: webdav,
      playlists: playlists,
    ));
    if (!mounted) return;
    setState(() => _syncing = false);
    final l10n = AppLocalizations.of(context);
    showAppToast(context, l10n.playlistSyncResult(result.what, result.message));
  }

  /// 云同步菜单：双向同步 / 从云端恢复 / 上传到云端 / 同步弹幕
  void _showSyncMenu(BuildContext context) {
    HapticFeedback.lightImpact();
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kGroupRadius)),
      ),
      builder: (ctx) => FrostedSheet(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(kGroupRadius)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ...buildMorphSegmentedList([
                MorphRowItem(
                  child: ListTile(
                    leading: Icon(Icons.sync_rounded, color: cs.primary),
                    title: Text(l10n.playlistSyncTwoWay),
                    subtitle: Text(l10n.playlistSyncTwoWaySubtitle),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _runSync((s) => s.syncPlaylists());
                    },
                  ),
                ),
                MorphRowItem(
                  child: ListTile(
                    leading: Icon(Icons.cloud_download_outlined,
                        color: cs.primary),
                    title: Text(l10n.playlistRestoreFromCloud),
                    subtitle: Text(l10n.playlistRestoreFromCloudSubtitle),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _runSync((s) => s.syncPlaylists(restoreFromCloud: true));
                    },
                  ),
                ),
                MorphRowItem(
                  child: ListTile(
                    leading: Icon(Icons.cloud_upload_outlined,
                        color: cs.primary),
                    title: Text(l10n.playlistUploadToCloud),
                    subtitle: Text(l10n.playlistUploadToCloudSubtitle),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _runSync((s) => s.pushPlaylists());
                    },
                  ),
                ),
                MorphRowItem(
                  child: ListTile(
                    leading: Icon(Icons.subtitles_outlined, color: cs.primary),
                    title: Text(l10n.playlistSyncDanmaku),
                    subtitle: Text(l10n.playlistSyncDanmakuSubtitle),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _runSync((s) => s.syncDanmaku());
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 8),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Future<void> _createNew(BuildContext context) async {
    final created = await PlaylistCreateDialog.show(context);
    if (created != null && context.mounted) {
      showAppToast(
        context,
        AppLocalizations.of(context).playlistCreated(created.name),
      );
    }
  }

  Future<void> _edit(BuildContext context, Playlist playlist) async {
    await PlaylistCreateDialog.show(context, existingPlaylist: playlist);
  }

  void _confirmDelete(BuildContext context, Playlist playlist) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.playlistDeleteTitle),
        content: Text(l10n.playlistDeleteConfirm(playlist.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              context.read<PlaylistService>().deletePlaylist(playlist.id);
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }

//  点击列表 → 进入详情页，查看全部剧集并从任意一集播放
  void _openDetail(BuildContext context, Playlist playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  // 快捷入口：从上次位置直接续播
  void _startPlaying(BuildContext context, Playlist playlist) {
    if (playlist.items.isEmpty) {
      showAppToast(context, AppLocalizations.of(context).playlistDetailEmpty);
      return;
    }
    final item = playlist.currentItem ?? playlist.items.first;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MpvPlayerPage(
          videoUrl: item.url,
          title: item.title,
          httpHeaders: item.headers,
          subtitleUrl: item.subtitleUrl,
          subtitleName: item.subtitleName,
          initialPosition: playlist.currentPositionMs > 0
              ? Duration(milliseconds: playlist.currentPositionMs)
              : null,
          playlist: playlist,
          initialEpisodeIndex: playlist.currentIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final playlists = context.watch<PlaylistService>().playlists;

    return Scaffold(
//  创建入口：带「创建」文本的扩展 FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNew(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.commonCreate),
        tooltip: l10n.playlistNewTooltip,
      ),
      body: CustomScrollView(
        slivers: [
          // ── 顶部 Expressive 折叠栏 ──
          ExpressiveSliverAppBar(
            title: l10n.playlistListTitle,
            leading: MorphIconButton(
              icon: Icons.arrow_back,
              tooltip: l10n.homeBack,
              onTap: () => Navigator.of(context).pop(),
            ),
            actions: [
              MorphIconButton(
                icon: _syncing
                    ? Icons.hourglass_top
                    : Icons.cloud_sync_outlined,
                tooltip: l10n.playlistCloudSync,
                onTap: _syncing ? null : () => _showSyncMenu(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          // ── 内容区 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // ── 分组标题 ──
                  _SectionHeader(
                    icon: Icons.queue_music,
                    title: l10n.playlistMyLists,
                    subtitle: playlists.isEmpty
                        ? l10n.playlistNoLists
                        : l10n.playlistListSummary(playlists.length),
                  ),
                  const SizedBox(height: 12),
                  // ── 空状态 / 分段卡片列表 ──
                  if (playlists.isEmpty)
                    MorphItem(
                      selected: false,
                      isFirst: true,
                      isLast: true,
                      interactive: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildEmpty(cs),
                      ),
                    )
                  else
                    ...buildMorphSegmentedList([
                      for (final p in playlists)
                        MorphRowItem(
                          child: _PlaylistTile(
                            playlist: p,
                            onTap: () => _openDetail(context, p),
                            onQuickPlay: () => _startPlaying(context, p),
                            onEdit: () => _edit(context, p),
                            onDelete: () => _confirmDelete(context, p),
                          ),
                        ),
                    ]),
                  const SizedBox(height: 96), // 给 FAB 留出空间
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(kItemRadius),
          ),
          child: Icon(
            Icons.queue_music_outlined,
            color: cs.onSurfaceVariant,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.playlistEmptyTitle,
                style: TextStyle(fontSize: 14, color: cs.onSurface),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.playlistEmptyHint,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onQuickPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlaylistTile({
    required this.playlist,
    required this.onTap,
    required this.onQuickPlay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final progress = playlist.items.isNotEmpty
        ? (playlist.currentIndex + 1) / playlist.items.length
        : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kItemPressedRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _buildThumbnail(cs),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.playlistTileProgress(
                        playlist.items.length, playlist.currentIndex + 1),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            LiquidGlassMenuButton(
              icon: Icons.more_vert,
              tooltip: l10n.playlistMenuMore,
              iconColor: cs.onSurfaceVariant,
              useMorphStyle: false,
              menuWidth: 220,
              actions: [
                GlassMenuAction(
                  icon: Icons.play_arrow,
                  text: l10n.playlistResume,
                  onTap: onQuickPlay,
                ),
                GlassMenuAction(
                  icon: Icons.edit,
                  text: l10n.playlistEditAction,
                  onTap: onEdit,
                ),
                GlassMenuAction(
                  icon: Icons.delete,
                  text: l10n.commonDelete,
                  isDestructive: true,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 小图 = 用户设置的背景图（与详情页 Hero 联动）；未设置时显示默认图标
  Widget _buildThumbnail(ColorScheme cs) {
    final bgPath = playlist.backgroundPath;
    final hasBg = bgPath != null && File(bgPath).existsSync();

    final placeholder = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(kItemRadius),
      ),
      child: Icon(
        Icons.queue_music,
        color: cs.onPrimaryContainer,
        size: 22,
      ),
    );

    if (!hasBg) return placeholder;

    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kItemRadius),
      ),
      child: Hero(
        tag: playlistBackgroundHeroTag(playlist.id),
        child: Image.file(
          File(bgPath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      ),
    );
  }
}