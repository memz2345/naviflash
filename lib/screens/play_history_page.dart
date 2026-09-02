// lib/screens/play_history_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/services/play_history_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/screens/player.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
class PlayHistoryPage extends StatelessWidget {
  const PlayHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<PlayHistoryService>();
    final records = history.records;
    final l10n = AppLocalizations.of(context);

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainerLow),
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              ExpressiveSliverAppBar(
                title: l10n.playHistoryTitle,
                expandedHeight: 120,
                leading: MorphIconButton(
                  icon: Icons.arrow_back,
                  tooltip: l10n.playHistoryBackTooltip,
                  onTap: () => Navigator.of(context).pop(),
                ),
                actions: [
                  if (records.isNotEmpty)
                    MorphIconButton(
                      icon: Icons.delete_sweep_outlined,
                      tooltip: l10n.playHistoryClearAll,
                      onTap: () => _confirmClearAll(context, history),
                    ),
                  const SizedBox(width: 4),
                ],
              ),
              if (records.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 72, color: cs.onSurface.withValues(alpha: 0.25)),
                        const SizedBox(height: 16),
                        Text(l10n.playHistoryEmpty, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
                        const SizedBox(height: 8),
                        Text(l10n.playHistoryEmptySub, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.35))),
                      ],
                    ),
                  ),
                ),
              if (records.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionTitle(context, '${l10n.playHistoryTitle} · ${records.length}'),
                        const SizedBox(height: 12),
                        ...List.generate(records.length, (index) {
                          final record = records[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: index == records.length - 1 ? 0 : kCardGap),
                            child: MorphItem(selected: false, isFirst: index == 0, isLast: index == records.length - 1, child: _HistoryTile(record: record)),
                          );
                        }),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, PlayHistoryService history) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.playHistoryClearTitle),
        content: Text(l10n.playHistoryClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              history.clearAll();
              Navigator.pop(ctx);
            },
            child: Text(l10n.playHistoryClearAction),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, textAlign: TextAlign.left, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary));
  }
}
class _HistoryTile extends StatelessWidget {
  final PlayRecord record;
  const _HistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => _resumePlay(context),
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
                    record.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.progressLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 进度条
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: record.progress,
                      minHeight: 3,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(cs.primary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatSavedTime(record.savedAt),
                    style: textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.play_circle_filled_rounded,
                  color: cs.primary, size: 36),
              tooltip: AppLocalizations.of(context).playHistoryResume,
              onPressed: () => _resumePlay(context),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded,
                  color: cs.onSurface.withOpacity(0.4), size: 20),
              tooltip: AppLocalizations.of(context).playHistoryDeleteRecord,
              onPressed: () => _removeRecord(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(ColorScheme cs) {
    final thumbPath = record.thumbnailPath;
    final hasThumb = thumbPath != null && File(thumbPath).existsSync();

    return Hero(
      tag: 'history_thumb_${record.id}',
      child: Container(
        width: 96,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: cs.surfaceContainerHighest,
        ),
        clipBehavior: Clip.antiAlias,
        child: hasThumb
            ? Image.file(
                File(thumbPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderIcon(cs),
              )
            : _placeholderIcon(cs),
      ),
    );
  }

  Widget _placeholderIcon(ColorScheme cs) {
    return Center(
      child: Icon(
        Icons.movie_outlined,
        color: cs.onSurface.withOpacity(0.3),
        size: 28,
      ),
    );
  }

  void _resumePlay(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MpvPlayerPage(
          videoUrl: record.videoUrl,
          httpHeaders: record.httpHeaders,
          subtitleUrl: record.subtitleUrl,
          // 缩略图 Hero 飞入播放器
          heroTag: 'history_thumb_${record.id}',
          // 传递初始进度
          initialPosition: Duration(milliseconds: record.positionMs),
                  title: record.title,
        danmakuSource: record.danmakuSource,
        danmakuType: record.danmakuType,
        ),
      ),
    );
  }

  void _removeRecord(BuildContext context) {
    final history = context.read<PlayHistoryService>();
    history.removeById(record.id);
    showAppToast(
        context, AppLocalizations.of(context).playHistoryDeleted(record.title));
  }

  String _formatSavedTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return L10n.current.timeJustNow;
    if (diff.inMinutes < 60) {
      return L10n.current.timeMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return L10n.current.timeHoursAgo(diff.inHours);
    }
    if (diff.inDays < 7) {
      return L10n.current.timeDaysAgo(diff.inDays);
    }
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}