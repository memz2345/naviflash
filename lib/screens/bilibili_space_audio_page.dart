                                             
  
                                  
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_audio_song_page.dart';
import 'package:naviflash/services/bilibili_audio_zone_service.dart';
import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/bilibili_space_audio_service.dart';
import 'package:naviflash/widgets/paged_list.dart';

class BilibiliSpaceAudioPage extends StatelessWidget {
  const BilibiliSpaceAudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mid = biliCurrentMid;
    return BiliListPage<BiliSpaceAudioItem>(
      title: l10n.audioZone,
      gridAspect: 0.82,
      fetcher: (page) => BilibiliSpaceAudioService.fetch(mid: mid, pn: page),
      itemBuilder: (c, item) => _AudioCard(
        item: item,
        onTap: () => _open(c, item),
      ),
    );
  }

  void _open(BuildContext c, BiliSpaceAudioItem item) {
                                  
    Navigator.of(c).push(
      MaterialPageRoute(
        builder: (_) => BilibiliAudioSongPage(
          queue: [
            AudioZoneSong(
              id: item.id,
              title: item.title,
              author: '',
              cover: item.cover,
              duration: 0,
              play: item.play,
              intro: '',
              uploader: '',
              uid: item.uid,
              avid: item.aid,
              bvid: item.bvid,
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioCard extends StatelessWidget {
  final BiliSpaceAudioItem item;
  final VoidCallback onTap;

  const _AudioCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.cover.isNotEmpty
                  ? Image.network(
                      item.cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: cs.surfaceContainerHighest),
                    )
                  : Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.audiotrack, color: cs.onSurfaceVariant),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_compact(item.play)} ▶  ${_compact(item.comment)} 💬',
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

  String _compact(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}万';
    return n.toString();
  }
}
