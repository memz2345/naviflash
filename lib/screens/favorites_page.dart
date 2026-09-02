// lib/screens/favorites_page.dart
//
// 本地收藏夹页面：展示收藏的视频（封面 / 标题 / BV·AV / UP 主），
// 点击用内置浏览器打开，长按 / 右键删除。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/favorites_service.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'bilibili_video_page.dart';
import 'browser_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesService>();
    final items = favorites.items;
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ExpressiveSliverAppBar(
            title: '本地收藏',
            leading: MorphIconButton(
              icon: Icons.arrow_back,
              tooltip: l10n.homeBack,
              onTap: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (items.isNotEmpty)
                MorphIconButton(
                  icon: Icons.delete_sweep_outlined,
                  tooltip: '清空收藏',
                  onTap: () => _confirmClearAll(context, favorites),
                ),
            ],
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 72,
                      color: cs.onSurface.withOpacity(0.25),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '还没有收藏的视频',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '在视频卡片上长按 / 右键，选择「收藏到本地」即可添加',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (items.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = items[index];
                  final isFirst = index == 0;
                  final isLast = index == items.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : kCardGap),
                    child: MorphItem(
                      selected: false,
                      isFirst: isFirst,
                      isLast: isLast,
                      child: _FavoriteTile(item: item),
                    ),
                  );
                }, childCount: items.length),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, FavoritesService favorites) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空收藏'),
        content: const Text('确定要清空全部本地收藏吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              favorites.clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  final FavoriteVideo item;
  const _FavoriteTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => _open(context),
      onLongPress: () => _remove(context),
      onSecondaryTapDown: (details) => _remove(context),
      borderRadius: BorderRadius.circular(kItemPressedRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _buildCover(cs),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BilibiliTitleCache.displayTitle(
                      item.bvid,
                      item.title.isEmpty ? '未命名视频' : item.title,
                    ),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item.author.isNotEmpty)
                    Text(
                      item.author,
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    item.aid > 0 ? '${item.bvid} · av${item.aid}' : item.bvid,
                    style: textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.4),
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.favorite_rounded, color: cs.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(ColorScheme cs) {
    return Container(
      width: 96,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: cs.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: item.bvid.isNotEmpty
          ? Hero(
              tag: 'bili_video_${item.bvid}',
              child: item.cover.isNotEmpty
                  ? Image.network(
                      item.cover,
                      fit: BoxFit.cover,
                      headers:
                          NetworkSettingsService.instance.apiHeaders.isEmpty
                          ? null
                          : NetworkSettingsService.instance.apiHeaders,
                      errorBuilder: (_, __, ___) => _placeholderIcon(cs),
                    )
                  : _placeholderIcon(cs),
            )
          : item.cover.isNotEmpty
          ? Image.network(
              item.cover,
              fit: BoxFit.cover,
              headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                  ? null
                  : NetworkSettingsService.instance.apiHeaders,
              errorBuilder: (_, __, ___) => _placeholderIcon(cs),
            )
          : _placeholderIcon(cs),
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

  void _open(BuildContext context) {
    HapticFeedback.lightImpact();
    if (item.bvid.isNotEmpty) {
      openBilibiliVideo(
        context,
        bvid: item.bvid,
        initialTitle: item.title,
        initialCover: item.cover,
        heroTag: 'bili_video_${item.bvid}',
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrowserPage(
          initialUrl: item.url,
          title: item.title.isEmpty ? 'B站视频' : item.title,
        ),
      ),
    );
  }

  void _remove(BuildContext context) {
    HapticFeedback.lightImpact();
    final favorites = context.read<FavoritesService>();
    favorites.removeByBvid(item.bvid);
    showAppToast(context, '已取消收藏');
  }
}
