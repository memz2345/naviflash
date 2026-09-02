// lib/widgets/playlist_detail_screen.dart
// 下方为该列表全部剧集，点击任意一集即可从该集开始播放。
// 背景图与播放列表页小图共用 Hero 动画。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/services/playlist_service.dart';
import 'package:naviflash/services/bilibili_season_service.dart';
import 'package:naviflash/screens/player.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/comment/comment_panel.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/widgets.dart';
import '../src/loading_indicator_m3e.dart';
import 'package:naviflash/l10n/app_localizations.dart';

/// 列表页小图与详情页背景共用的 Hero tag
String playlistBackgroundHeroTag(String playlistId) =>
    'playlist_bg_$playlistId';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  bool _isPickingBg = false;
  bool _isSelectMode = false;
  final Set<int> _selected = {};

  // ─── 播放 ───

  void _playFrom(BuildContext context, Playlist pl, int index,
      {bool forceRestart = false}) {
    if (pl.items.isEmpty) return;
    final item = pl.items[index];
    // 点击「当前集」且已有进度 → 断点续播；否则从头播放
    final isResume = !forceRestart &&
        index == pl.currentIndex &&
        pl.currentPositionMs > 3000;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MpvPlayerPage(
          videoUrl: item.url,
          title: item.title,
          httpHeaders: item.headers,
          subtitleUrl: item.subtitleUrl,
          subtitleName: item.subtitleName,
          initialPosition:
              isResume ? Duration(milliseconds: pl.currentPositionMs) : null,
          playlist: pl,
          initialEpisodeIndex: index,
        ),
      ),
    );
  }


  Future<void> _handlePickBackground(
      BuildContext context, Playlist pl) async {
    setState(() => _isPickingBg = true);
    try {
      final ok =
          await context.read<PlaylistService>().pickAndSaveBackground(pl.id);
      if (ok && mounted) {
        showAppToast(context, AppLocalizations.of(context).playlistDetailBgUpdated);
      }
    } catch (e) {
      if (mounted) {
        showAppToast(
          context,
          AppLocalizations.of(context).playlistDetailBgFail(e.toString()),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingBg = false);
    }
  }

  Future<void> _handleRemoveBackground(
      BuildContext context, Playlist pl) async {
    await context.read<PlaylistService>().removeBackground(pl.id);
    if (mounted) {
      showAppToast(context, AppLocalizations.of(context).playlistDetailBgRemoved);
    }
  }

  void _showBackgroundOptions(BuildContext context, Playlist pl) {
    final theme = Theme.of(context);
    final hasBg =
        pl.backgroundPath != null && File(pl.backgroundPath!).existsSync();
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FrostedSheet(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.wallpaper,
                        color: theme.colorScheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      l10n.playlistDetailBgTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await _handlePickBackground(context, pl);
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(hasBg
                      ? l10n.playlistDetailBgChange
                      : l10n.playlistDetailBgPick),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                if (hasBg) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await _handleRemoveBackground(context, pl);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.playlistDetailBgRemove),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                          color: theme.colorScheme.error.withOpacity(0.5)),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(l10n.commonCancel),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundImage(Playlist pl, ColorScheme cs) {
    final bgPath = pl.backgroundPath;
    final hasBg = bgPath != null && File(bgPath).existsSync();
    if (hasBg) {
      return Image.file(
        File(bgPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultGradient(cs),
      );
    }
    return _defaultGradient(cs);
  }

  Widget _defaultGradient(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            cs.primaryContainer,
            cs.tertiaryContainer,
          ],
        ),
      ),
    );
  }

  // ─── 右上角菜单：编辑名字 / 多选 / 弹幕 ───

  Future<void> _showRenameDialog(BuildContext context, Playlist pl) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: pl.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.playlistRenameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: InputDecoration(hintText: l10n.playlistRenameHint),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;
    await context.read<PlaylistService>().renamePlaylist(pl.id, result);
    if (mounted) {
      showAppToast(context, l10n.playlistRenameSaved);
    }
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      _selected.clear();
    });
  }

  Future<void> _deleteSelected(BuildContext context, Playlist pl) async {
    final l10n = AppLocalizations.of(context);
    if (_selected.isEmpty) {
      showAppToast(context, l10n.playlistSelectEmpty);
      return;
    }
    final service = context.read<PlaylistService>();
    final indices = _selected.toList()..sort((a, b) => b.compareTo(a));
    for (final i in indices) {
      await service.removeItem(pl.id, i);
    }
    if (mounted) {
      setState(() {
        _selected.clear();
        _isSelectMode = false;
      });
      showAppToast(context, l10n.playlistSelectDeleted(indices.length));
    }
  }

  // ─── 评论区：仅当该集已关联 cid 弹幕与评论区 oid（aid）时可用 ───

  void _openComments(BuildContext context, PlaylistItem item) {
    // 评论区 oid 是番剧每集的 aid（av 号），不是弹幕 cid
    final aid = item.commentSource;
    if (item.danmakuType != 'cid' ||
        aid == null ||
        aid.isEmpty ||
        !RegExp(r'^\d+$').hasMatch(aid) ||
        aid == '0') {
      return;
    }
    showCommentPanel(context, cid: aid, episodeTitle: item.title);
  }

  // ─── 弹幕：SS 号导入（按 1、2、3... 顺序匹配） ───

  Future<void> _showDanmakuSsDialog(BuildContext context, Playlist pl) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final ss = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.playlistDanmakuTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration:
              InputDecoration(hintText: l10n.playlistDanmakuSsHint),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
    controller.dispose();
    if (ss == null || ss.isEmpty || !mounted) return;

    // 获取剧集期间显示进度
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: LoadingIndicatorM3E(),
      ),
    );
    final episodes = await BilibiliSeasonService.fetchSections(ss);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // 关闭进度
    if (!mounted) return;

    if (episodes == null || episodes.isEmpty) {
      showAppToast(context, l10n.playlistDanmakuFetchFail, error: true);
      return;
    }
    await _showDanmakuSelectDialog(context, pl, episodes);
  }

  Future<void> _showDanmakuSelectDialog(
    BuildContext context,
    Playlist pl,
    List<SeasonEpisode> episodes,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = <int>{for (var i = 0; i < episodes.length; i++) i};

    final result = await showDialog<List<int>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(l10n.playlistDanmakuSelectTitle(episodes.length)),
              content: SizedBox(
                width: 420,
                height: 400,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: selected.length == episodes.length,
                          onChanged: (v) => setDialogState(() {
                            if (v == true) {
                              selected
                                ..clear()
                                ..addAll(
                                    List.generate(episodes.length, (i) => i));
                            } else {
                              selected.clear();
                            }
                          }),
                        ),
                        Text(l10n.playlistDanmakuSelectAll),
                        const Spacer(),
                        Text(
                          '${selected.length}/${episodes.length}',
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: episodes.length,
                        itemBuilder: (context, index) {
                          final ep = episodes[index];
                          final isChecked = selected.contains(index);
                          return CheckboxListTile(
                            dense: true,
                            value: isChecked,
                            controlAffinity:
                                ListTileControlAffinity.leading,
                            onChanged: (v) => setDialogState(() {
                              if (v == true) {
                                selected.add(index);
                              } else {
                                selected.remove(index);
                              }
                            }),
                            title: Text(
                              '${index + 1}. ${ep.displayTitle}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              'cid: ${ep.cid} · ${_formatDuration(ep.duration)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(ctx).pop(selected.toList()..sort()),
                  icon: const Icon(Icons.subtitles, size: 18),
                  label: Text(l10n.playlistDanmakuImport),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == null || result.isEmpty || !mounted) return;

//  按 1、2、3... 顺序依次为列表中第 1、2、3... 集附加弹幕，
    //   同时保存评论区 oid（aid），评论区与弹幕 cid 是两套 id
    final service = context.read<PlaylistService>();
    final cidList = [for (final i in result) '${episodes[i].cid}'];
    final aidList = [for (final i in result) '${episodes[i].aid}'];
    final attached =
        await service.attachDanmakuToItems(pl.id, cidList, aidList: aidList);
    if (!mounted) return;
    final msg = attached > 0
        ? l10n.playlistDanmakuAttached(attached)
        : l10n.playlistSelectEmpty;
    showAppToast(context, msg);
    if (attached > 0 && cidList.length > attached) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        showAppToast(
          context,
          l10n.playlistDanmakuExceed(cidList.length, attached),
        );
      });
    }
  }

  String _formatDuration(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    // 实时监听 service，返回的仍是同一 Playlist 实例（原地变更），保证数据新鲜
    final service = context.watch<PlaylistService>();
    final pl = service.findById(widget.playlist.id) ?? widget.playlist;
    final items = pl.items;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
//  多选模式底部操作栏
      bottomNavigationBar: _isSelectMode
          ? Material(
              color: cs.surfaceContainerHigh,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _toggleSelectMode,
                          icon: const Icon(Icons.close, size: 20),
                          label: Text(l10n.playlistSelectDone),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _deleteSelected(context, pl),
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: cs.onError,
                        ),
                        label: Text(
                            l10n.playlistSelectDelete(_selected.length)),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
//  FAB：从头开始播放
      floatingActionButton: _isSelectMode
          ? null
          : FloatingActionButton.extended(
              onPressed: items.isEmpty
                  ? null
                  : () => _playFrom(context, pl, 0, forceRestart: true),
              icon: const Icon(Icons.replay),
              label: Text(l10n.playlistFabRestart),
              tooltip: l10n.playlistFabRestart,
            ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ── 顶部背景图（可点击更换，Hero 与列表页小图联动） ──
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            stretchTriggerOffset: 60,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            leading: MorphIconButton(
              icon: Icons.arrow_back,
              tooltip: l10n.homeBack,
              onTap: () => Navigator.of(context).pop(),
            ),
            actions: [
              MorphIconButton(
                icon: _isPickingBg
                    ? Icons.hourglass_top
                    : Icons.wallpaper_outlined,
                tooltip: l10n.playlistDetailBgTitle,
                onTap: _isPickingBg
                    ? null
                    : () => _showBackgroundOptions(context, pl),
              ),
//  右上角三点菜单：编辑名字 / 多选 / 弹幕（液态玻璃 + liquid-dom 动画）
              LiquidGlassMenuButton(
                icon: Icons.more_vert,
                tooltip: l10n.playlistMenuMore,
                menuWidth: 220,
                actions: [
                  GlassMenuAction(
                    icon: Icons.edit_outlined,
                    text: l10n.playlistMenuRename,
                    onTap: () => _showRenameDialog(context, pl),
                  ),
                  GlassMenuAction(
                    icon: Icons.checklist,
                    text: l10n.playlistMenuMultiSelect,
                    onTap: _toggleSelectMode,
                  ),
                  GlassMenuAction(
                    icon: Icons.subtitles_outlined,
                    text: l10n.playlistMenuDanmaku,
                    onTap: () => _showDanmakuSsDialog(context, pl),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final safeTop = MediaQuery.of(context).padding.top;
                final isCollapsed =
                    constraints.biggest.height <= kToolbarHeight + safeTop + 1;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. 背景图层（Hero）
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _showBackgroundOptions(context, pl),
                          child: Hero(
                            tag: playlistBackgroundHeroTag(pl.id),
                            child: _buildBackgroundImage(pl, cs),
                          ),
                        ),
                      ),
                    ),
                    // 2. 底部渐变遮罩
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 160,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.65),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 3. 展开态：列表名 + 集数
                    AnimatedOpacity(
                      opacity: isCollapsed ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: isCollapsed,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pl.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.playlistDetailEpisodes(items.length),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 4. 折叠态小标题
                    AnimatedOpacity(
                      opacity: isCollapsed ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 56,
                            top: safeTop,
                          ),
                          child: Text(
                            pl.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // ── 剧集列表 ──
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 72,
                      color: cs.onSurface.withOpacity(0.25),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.playlistDetailEmpty,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    final isCurrent = index == pl.currentIndex;
                    final isSelected = _selected.contains(index);
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == items.length - 1 ? 0 : kCardGap,
                      ),
                      child: MorphItem(
                        selected: _isSelectMode ? isSelected : isCurrent,
                        isFirst: index == 0,
                        isLast: index == items.length - 1,
                        child: _EpisodeTile(
                          item: item,
                          index: index,
                          isCurrent: isCurrent,
                          resumeMs: isCurrent ? pl.currentPositionMs : 0,
                          selectMode: _isSelectMode,
                          isSelected: isSelected,
                          hasComments: item.danmakuType == 'cid' &&
                              (item.commentSource?.isNotEmpty ?? false) &&
                              item.commentSource != '0',
                          onOpenComments: () => _openComments(context, item),
                          onTap: () {
                            if (_isSelectMode) {
                              setState(() {
                                if (!_selected.remove(index)) {
                                  _selected.add(index);
                                }
                              });
                            } else {
                              _playFrom(context, pl, index);
                            }
                          },
                        ),
                      ),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}


class _EpisodeTile extends StatelessWidget {
  final PlaylistItem item;
  final int index;
  final bool isCurrent;
  final int resumeMs;
  final bool selectMode;
  final bool isSelected;
  final bool hasComments;
  final VoidCallback? onOpenComments;
  final VoidCallback onTap;

  const _EpisodeTile({
    required this.item,
    required this.index,
    required this.isCurrent,
    required this.resumeMs,
    required this.selectMode,
    required this.isSelected,
    required this.hasComments,
    required this.onOpenComments,
    required this.onTap,
  });

  String _formatPosition(int ms) {
    if (ms <= 0) return '0:00';
    final s = (ms / 1000).round();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(sec)}' : '$m:${two(sec)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kItemPressedRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // ── 序号 / 当前播放标记（多选模式下为复选框） ──
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selectMode
                    ? (isSelected
                        ? cs.primary
                        : cs.surfaceContainerHighest)
                    : (isCurrent ? cs.primary : cs.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(kItemRadius),
              ),
              child: selectMode
                  ? (isSelected
                      ? Icon(Icons.check, color: cs.onPrimary, size: 26)
                      : const SizedBox.shrink())
                  : (isCurrent
                      ? Icon(Icons.play_arrow, color: cs.onPrimary, size: 26)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        )),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isCurrent ? cs.onSecondaryContainer : cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCurrent && resumeMs > 3000
                        ? l10n.playlistDetailResume(_formatPosition(resumeMs))
                        : l10n.playlistDetailEpisodeOf(index + 1),
                    style: textTheme.bodySmall?.copyWith(
                      color: isCurrent
                          ? cs.onSecondaryContainer.withOpacity(0.7)
                          : cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            selectMode
                ? Checkbox(
                    value: isSelected,
                    activeColor: cs.primary,
                    onChanged: (_) => onTap(),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
//  评论区入口：仅当该集已关联 cid 弹幕时显示
                      if (hasComments)
                        IconButton(
                          tooltip: l10n.commentPanelTitle,
                          visualDensity: VisualDensity.compact,
                          onPressed: onOpenComments,
                          icon: Icon(
                            Icons.forum_outlined,
                            size: 20,
                            color: cs.primary.withOpacity(0.85),
                          ),
                        ),
                      Icon(
                        Icons.play_circle_filled_rounded,
                        size: 32,
                        color: isCurrent
                            ? cs.primary
                            : cs.onSurface.withOpacity(0.35),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
