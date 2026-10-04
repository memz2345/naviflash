                                       
  
                                
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/bilibili_comic_service.dart';
import 'package:naviflash/widgets/paged_list.dart';

class BilibiliComicPage extends StatelessWidget {
  const BilibiliComicPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mid = biliCurrentMid;
    return BiliListPage<BiliComicItem>(
      title: l10n.comic,
      gridAspect: 0.7,
      fetcher: (page) => BilibiliComicService.fetch(mid: mid, pn: page),
      itemBuilder: (c, item) => _ComicCard(
        item: item,
        onTap: () => _open(c, item),
      ),
    );
  }

  void _open(BuildContext c, BiliComicItem item) {
    Navigator.of(c).push(
      MaterialPageRoute(
        builder: (_) => BrowserPage(initialUrl: item.webUrl, title: item.title),
      ),
    );
  }
}

class _ComicCard extends StatelessWidget {
  final BiliComicItem item;
  final VoidCallback onTap;

  const _ComicCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final badge = item.styles.isNotEmpty
        ? item.styles.take(2).join(' · ')
        : item.label;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.cover.isNotEmpty
                  ? Image.network(
                      item.cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: cs.surfaceContainerHighest),
                    )
                  : Container(color: cs.surfaceContainerHighest),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          if (badge.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                badge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
