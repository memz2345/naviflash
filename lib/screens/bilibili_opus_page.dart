                                      
  
                                        
                                            
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/bilibili_opus_service.dart';
import 'package:naviflash/services/paged_result.dart';
import 'package:naviflash/widgets/paged_list.dart';

class BilibiliOpusPage extends StatefulWidget {
  const BilibiliOpusPage({super.key});

  @override
  State<BilibiliOpusPage> createState() => _BilibiliOpusPageState();
}

class _BilibiliOpusPageState extends State<BilibiliOpusPage> {
  String? _offset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mid = biliCurrentMid;
    return BiliListPage<BiliOpusItem>(
      title: l10n.opusTab,
      gridAspect: 0.8,
      fetcher: (page) async {
        final r = await BilibiliOpusService.fetch(
          mid: mid,
          page: page,
          offset: page == 1 ? null : _offset,
        );
        if (page != 1) _offset = r.nextOffset;
        return PagedResult(r.items, r.hasMore);
      },
      itemBuilder: (c, item) => _OpusCard(
        item: item,
        onTap: () => _open(c, item),
      ),
    );
  }

  void _open(BuildContext c, BiliOpusItem item) {
    Navigator.of(c).push(
      MaterialPageRoute(
        builder: (_) =>
            BrowserPage(initialUrl: item.webUrl, title: item.content),
      ),
    );
  }
}

class _OpusCard extends StatelessWidget {
  final BiliOpusItem item;
  final VoidCallback onTap;

  const _OpusCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasCover = item.cover.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCover)
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  item.cover,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: cs.surfaceContainerHighest),
                ),
              ),
            )
          else
            Container(
              height: 96,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.article_outlined, color: cs.onSurfaceVariant),
            ),
          const SizedBox(height: 6),
          Text(
            item.content.isEmpty ? item.opusId : item.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          if (item.like > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '👍 ${item.like}',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
