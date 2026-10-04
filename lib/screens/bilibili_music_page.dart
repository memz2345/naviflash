                                       
                                        
                                             
                                
                       
import 'package:flutter/material.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';

import 'package:naviflash/screens/bilibili_user_space_page_v2.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bilibili_music_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/page_loading.dart';

class BilibiliMusicPage extends StatefulWidget {
  final String musicId;

  const BilibiliMusicPage({super.key, required this.musicId});

  @override
  State<BilibiliMusicPage> createState() => _BilibiliMusicPageState();
}

class _BilibiliMusicPageState extends State<BilibiliMusicPage> {
  BiliBgmDetail? _detail;
  List<BiliBgmRecommend> _recommend = const [];
  bool _loading = true;
  bool _wishing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
                                        
                                         
    final hadDetail = _detail != null;
    final results = await Future.wait([
      BilibiliMusicService.fetchDetail(widget.musicId),
      BilibiliMusicService.fetchRecommend(widget.musicId),
    ]);
    if (!mounted) return;
    final detail = results[0] as BiliBgmDetail?;
    final recommend = (results[1] as List).cast<BiliBgmRecommend>();
    if (detail == null && hadDetail) {
      showAppToast(context, '音乐信息刷新失败', error: true);
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _detail = detail;
      _recommend = recommend;
      _loading = false;
    });
  }

  Future<void> _toggleWish() async {
    final d = _detail;
    if (d == null || _wishing) return;
    final target = !d.wishListen;
    setState(() => _wishing = true);
    final res = await BilibiliMusicService.wish(
      musicId: d.musicId,
      like: target,
    );
    if (!mounted) return;
    if (!res.ok) {
      setState(() => _wishing = false);
      showAppToast(context, res.message, error: true);
      return;
    }
    setState(() {
      _wishing = false;
      _detail = BiliBgmDetail(
        musicId: d.musicId,
        title: d.title,
        cover: d.cover,
        album: d.album,
        source: d.source,
        artists: d.artists,
        mvBvid: d.mvBvid,
        mvCid: d.mvCid,
        mvAid: d.mvAid,
        wishListen: target,
        wishCount: (d.wishCount + (target ? 1 : -1)).clamp(0, 1 << 31),
        listenPv: d.listenPv,
        relationCount: d.relationCount,
      );
    });
  }

  String _fmt(int n) {
    if (n >= 100000000) return '${(n / 100000000).toStringAsFixed(1)}亿';
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}万';
    return '$n';
  }

  static String _fmtDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(title: const Text('音乐')),
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer),
          if (_loading)
            const PageLoadingIndicator()
          else if (_detail == null)
            Center(
              child: Text(
                '音乐信息加载失败',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            )
          else
            AppRefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _buildHeader(cs),
                  const SizedBox(height: 16),
                  if (_recommend.isNotEmpty) ...[
                    Text(
                      '使用该 BGM 的稿件（${_recommend.length}）',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final item in _recommend) _recRow(cs, item),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    final d = _detail!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: d.cover.isEmpty
                    ? Container(
                        width: 84,
                        height: 84,
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.music_note,
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : Image(
                        image: CachedImageProvider(d.cover),
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 84,
                          height: 84,
                          color: cs.surfaceContainerHighest,
                          child: Icon(
                            Icons.music_note,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.title.isEmpty ? '未知音乐' : d.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (d.artistText.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final a in d.artists)
                            if (a.name.isNotEmpty)
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: a.mid > 0
                                    ? () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                BilibiliUserSpacePage(
                                                  mid: a.mid,
                                                ),
                                          ),
                                        )
                                    : null,
                                child: Text(
                                  a.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: a.mid > 0
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    if (d.album.isNotEmpty || d.source.isNotEmpty)
                      Text(
                        [
                          if (d.album.isNotEmpty) '专辑：${d.album}',
                          if (d.source.isNotEmpty) '出处：${d.source}',
                        ].join('   '),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${_fmt(d.listenPv)} 播放   ${_fmt(d.relationCount)} 稿件',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              if (d.mvBvid.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => openBilibiliVideo(
                    context,
                    bvid: d.mvBvid,
                  ),
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: const Text('看 MV'),
                ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _wishing ? null : _toggleWish,
                icon: Icon(
                  d.wishListen ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: d.wishListen ? cs.error : null,
                ),
                label: Text(_fmt(d.wishCount)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recRow(ColorScheme cs, BiliBgmRecommend item) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => openBilibiliVideo(context, bvid: item.bvid),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 128,
                height: 72,
                child: item.cover.isEmpty
                    ? Container(color: cs.surfaceContainerHighest)
                    : Image(
                        image: CachedImageProvider(item.cover),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: cs.surfaceContainerHighest),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.upName}   ${_fmt(item.play)}播放'
                    '   ${_fmtDuration(item.duration)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
