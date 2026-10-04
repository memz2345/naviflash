                                     
import 'package:naviflash/widgets/video_card.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/services/play_history_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/standard_list_page.dart';
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
                                          
                                          
    return StandardListScaffold(
      topBar: StandardListTopBar(
        title: l10n.playHistoryTitle,
        showBack: true,
        actions: [
          if (records.isNotEmpty)
            MorphIconButton(
              icon: Icons.delete_sweep_outlined,
              tooltip: l10n.playHistoryClearAll,
              onTap: () => _confirmClearAll(context, history),
              frosted: true,
            ),
        ],
      ),
      body: CustomScrollView(
                                                   
        physics: const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          topBarSpaceSliver(kStdTopBarHeight),
          if (records.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 72,
                      color: cs.onSurface.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.playHistoryEmpty,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.playHistoryEmptySub,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _buildSectionTitle(
                  context,
                  '${l10n.playHistoryTitle} · ${records.length}',
                ),
              ),
            ),
            videoCardListSliver(
              itemCount: records.length,
              itemBuilder: (_, index) => _HistoryTile(record: records[index]),
            ),
          ],
          bottomSpaceSliver(context),
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
    final thumbPath = record.thumbnailPath;
    final hasThumb = thumbPath != null && File(thumbPath).existsSync();
    return VideoCardH(
      data: VideoCardData(
        cover: '',
        title: record.title,
        subtitle:
            '${record.progressLabel}  ${_formatSavedTime(record.savedAt)}',
        progress: record.progress,
                                     
        heroTag: 'history_thumb_${record.id}',
        coverWidget: Container(
          color: cs.surfaceContainerHighest,
          child: hasThumb
              ? Image.file(
                  File(thumbPath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(
                      Icons.movie_outlined,
                      color: cs.onSurface.withValues(alpha: 0.3),
                      size: 28,
                    ),
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.movie_outlined,
                    color: cs.onSurface.withValues(alpha: 0.3),
                    size: 28,
                  ),
                ),
        ),
      ),
      onTap: () => _resumePlay(context),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.play_circle_filled_rounded,
              color: cs.primary,
              size: 36,
            ),
            tooltip: AppLocalizations.of(context).playHistoryResume,
            onPressed: () => _resumePlay(context),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: cs.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
            tooltip: AppLocalizations.of(context).playHistoryDeleteRecord,
            onPressed: () => _removeRecord(context),
          ),
        ],
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
                           
          heroTag: 'history_thumb_${record.id}',
                   
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