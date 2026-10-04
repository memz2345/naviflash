                                        
  
                           
                                                
                                                             
                                                 
                                               
                                                         
                                                   
                                                                  

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/services/bilibili_cheese_service.dart';
import 'package:naviflash/services/bilibili_video_service.dart'
    show BiliPlayUrl, BilibiliVideoService;
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/playback_focus.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/screens/player.dart';
import 'package:naviflash/services/playlist_service.dart'
    show Playlist, PlaylistItem;

                                                 
                                               
const Map<String, String> _cheeseMediaHeaders = {
  'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Referer': 'https://www.bilibili.com',
};

                                               
void openBilibiliCheese(
  BuildContext context, {
  required int seasonId,
  int? epId,
  String? initialTitle,
  String? initialCover,
  String? heroTag,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  unawaited(PlaybackFocus.instance.pauseAll());
  Navigator.of(context).push(
    heroTransitionRoute(
      heroZoom: heroTag != null,
      page: BilibiliCheesePage(
        seasonId: seasonId,
        epId: epId,
        initialTitle: initialTitle,
        initialCover: initialCover,
        heroTag: heroTag,
      ),
    ),
  );
}

class BilibiliCheesePage extends StatefulWidget {
  final int seasonId;

                                         
  final int? epId;
  final String? initialTitle;
  final String? initialCover;
  final String? heroTag;

  const BilibiliCheesePage({
    super.key,
    required this.seasonId,
    this.epId,
    this.initialTitle,
    this.initialCover,
    this.heroTag,
  });

  @override
  State<BilibiliCheesePage> createState() => _BilibiliCheesePageState();
}

class _BilibiliCheesePageState extends State<BilibiliCheesePage> {
  CheeseSeason? _season;
  bool _loading = true;
  bool _resolving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
                                  
                               
      _loading = _season == null;
      _error = null;
    });
    final season = await BilibiliCheeseService.fetchSeason(
      seasonId: widget.seasonId,
      epId: widget.epId,
    );
    if (!mounted) return;
    if (season == null && _season != null) {
                            
      setState(() => _loading = false);
      showAppToast(
        context,
        BilibiliCheeseService.lastErrorDetail ?? '课程刷新失败',
        error: true,
      );
      return;
    }
    setState(() {
      _season = season;
      _loading = false;
      _error = season == null
          ? (BilibiliCheeseService.lastErrorDetail ?? '课程加载失败')
          : null;
    });
  }

                                
  int _defaultEpisodeIndex() {
    final season = _season;
    if (season == null || season.episodes.isEmpty) return 0;
    final lastEpId = season.userStatus.lastEpId;
    if (lastEpId > 0) {
      final i = season.episodes.indexWhere((e) => e.epId == lastEpId);
      if (i >= 0) return i;
    }
    final firstPlayable = season.episodes.indexWhere((e) => e.playable);
    return firstPlayable >= 0 ? firstPlayable : 0;
  }

                                          
  Future<void> _play(int startIndex) async {
    final season = _season;
    if (season == null || _resolving) return;
    final episodes = season.episodes;
    if (startIndex < 0 || startIndex >= episodes.length) return;
    if (!BilibiliCheeseService.hasLoginCookie &&
        !episodes[startIndex].playable) {
      showAppToast(context, '未购买该课程，登录后可试看', error: true);
      return;
    }
    setState(() => _resolving = true);
    String? startError;
    final resolved = <String?>[...episodes.map((_) => null)];
    var resumeMs = 0;
    _playInfos.clear();
                                 
    for (var chunkStart = 0; chunkStart < episodes.length; chunkStart += 5) {
      final chunkEnd = (chunkStart + 5).clamp(0, episodes.length);
      final results = await Future.wait([
        for (var i = chunkStart; i < chunkEnd; i++)
          _resolveEpisode(season, episodes[i]),
      ]);
      for (var i = chunkStart; i < chunkEnd; i++) {
        final r = results[i - chunkStart];
        if (r == null) continue;
        resolved[i] = r.$1;
        if (i == startIndex) {
          resumeMs = r.$2;
        }
      }
      if (resolved[startIndex] == null && chunkEnd > startIndex) {
        startError = BilibiliCheeseService.lastErrorDetail ?? '解析播放地址失败';
        break;
      }
    }
    if (!mounted) return;
    if (resolved[startIndex] == null) {
      setState(() => _resolving = false);
      showAppToast(context, startError ?? '解析播放地址失败', error: true);
      return;
    }
                       
    final items = <PlaylistItem>[];
    for (var i = 0; i < episodes.length; i++) {
      final url = resolved[i];
      if (url == null || url.isEmpty) continue;
      final e = episodes[i];
      items.add(
        PlaylistItem(
          id: 'cheese_ep_${e.epId}',
          url: url,
          title: '${i + 1}. ${e.title}',
          index: i,
          danmakuSource: e.cid > 0 ? e.cid.toString() : null,
          danmakuType: 'cid',
          commentSource: e.aid > 0 ? e.aid.toString() : null,
        ),
      );
    }
                 
    var listIndex = 0;
    for (var i = 0; i < items.length; i++) {
      if (items[i].index == startIndex) listIndex = i;
    }
    final startEp = episodes[startIndex];
    final startInfo = _playInfos[startEp.epId];
    setState(() => _resolving = false);
    if (items.isEmpty) {
      showAppToast(context, '无可用播放地址', error: true);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MpvPlayerPage(
          videoUrl: items[listIndex].url,
          title: startEp.title,
          artist: season.title,
          httpHeaders: _cheeseMediaHeaders,
                                             
          danmakuSource: startEp.cid > 0 ? startEp.cid.toString() : null,
          danmakuType: 'cid',
          playlist: Playlist(
            id: 'cheese_ss_${season.seasonId}',
            name: season.title,
            items: items,
          ),
          initialEpisodeIndex: listIndex,
          initialPosition: resumeMs > 0
              ? Duration(milliseconds: resumeMs)
              : null,
          playUrlInfo: startInfo,
          initialQualityQn: startInfo?.quality,
          artUri: season.cover,
          historyId: 'cheese_ep_${startEp.epId}',
        ),
      ),
    );
  }

                               
  final Map<int, BiliPlayUrl> _playInfos = {};

  Future<(String, int)?> _resolveEpisode(
    CheeseSeason season,
    CheeseEpisode ep,
  ) async {
    if (ep.cid <= 0 && ep.epId <= 0) return null;
    final r = await BilibiliCheeseService.fetchPlayUrl(
      seasonId: season.seasonId,
      epId: ep.epId,
      aid: ep.aid,
      cid: ep.cid,
    );
    if (r == null) return null;
    final url = BilibiliVideoService.buildPlayableUrl(r.playUrl);
    if (url == null) return null;
    _playInfos[ep.epId] = r.playUrl;
    return (url, r.resumeMs);
  }

  String _fmtDuration(int sec) {
    if (sec <= 0) return '';
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _fmtCount(int n) {
    if (n >= 100000000) return '${(n / 100000000).toStringAsFixed(1)}亿';
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}万';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        title: Text(
          _season?.title ?? widget.initialTitle ?? '课堂',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 44,
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重试'),
                  ),
                ],
              ),
            )
          else
            _buildBody(cs),
          if (_resolving)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black38,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        '正在解析播放地址…',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    final season = _season!;
    final payed = season.userStatus.payed;
    return AppRefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(cs, season, payed)),
          SliverToBoxAdapter(child: _buildEpisodeListHeader(cs, season)),
          SliverList.builder(
            itemCount: season.episodes.length,
            itemBuilder: (context, index) =>
                _buildEpisodeTile(cs, season, index),
          ),
          SliverToBoxAdapter(child: _buildBrief(cs, season)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, CheeseSeason season, bool payed) {
    final up = season.up;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: widget.heroTag ?? 'cheese_cover_${widget.seasonId}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 138,
                height: 92,
                color: cs.surfaceContainerHighest,
                child: season.cover.isEmpty
                    ? const SizedBox.shrink()
                    : Image(
                        image: CachedImageProvider(season.cover),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        season.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (season.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    season.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _badge(payed ? '已购' : '未购买',
                        payed ? cs.primaryContainer : cs.surfaceContainerHighest,
                        payed ? cs.onPrimaryContainer : cs.onSurfaceVariant),
                    if (season.epCount > 0)
                      Text(
                        '共${season.epCount}课时',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    if (season.playCount > 0)
                      Text(
                        '${_fmtCount(season.playCount)}播放',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    if (season.payment != null && !payed)
                      Text(
                        season.payment!.displayPrice,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                  ],
                ),
                if (up != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ClipOval(
                        child: Container(
                          width: 22,
                          height: 22,
                          color: cs.surfaceContainerHighest,
                          child: up.avatar.isEmpty
                              ? null
                              : Image(
                                  image: CachedImageProvider(up.avatar),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          up.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildEpisodeListHeader(ColorScheme cs, CheeseSeason season) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(Icons.playlist_play_outlined, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            '课时列表（${season.episodes.length}）',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _resolving ? null : () => _play(_defaultEpisodeIndex()),
            icon: Icon(
              season.userStatus.lastEpId > 0
                  ? Icons.play_circle_outline
                  : Icons.play_arrow_rounded,
              size: 18,
            ),
            label: Text(
              season.userStatus.lastEpId > 0 ? '继续播放' : '开始播放',
              style: const TextStyle(fontSize: 13),
            ),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeTile(ColorScheme cs, CheeseSeason season, int index) {
    final ep = season.episodes[index];
    final playable = ep.playable;
    final isLastWatched =
        season.userStatus.lastEpId > 0 && ep.epId == season.userStatus.lastEpId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isLastWatched
            ? cs.secondaryContainer.withValues(alpha: 0.45)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _resolving
              ? null
              : () async {
                  if (!playable && !BilibiliCheeseService.hasLoginCookie) {
                    showAppToast(context, '未购买：${ep.previewToast.isEmpty ? '该集需购买后观看' : ep.previewToast}', error: true);
                    return;
                  }
                  await _play(index);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: playable ? cs.primary : cs.outline,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ep.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: playable
                              ? cs.onSurface
                              : cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (ep.durationSec > 0) ...[
                            Text(
                              _fmtDuration(ep.durationSec),
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.outline,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (ep.play > 0)
                            Text(
                              '${_fmtCount(ep.play)}播放',
                              style: TextStyle(fontSize: 11, color: cs.outline),
                            ),
                          if (!playable && ep.previewToast.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                ep.previewToast,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.outline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (ep.label.isNotEmpty)
                  _badge(ep.label, cs.tertiaryContainer, cs.onTertiaryContainer)
                else if (!playable)
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: cs.outline,
                  )
                else if (ep.watched)
                  Icon(Icons.check_circle_outline, size: 15, color: cs.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrief(ColorScheme cs, CheeseSeason season) {
    final text = season.briefContent;
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                '简介',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
