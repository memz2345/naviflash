                                            
  
                                
                                              
                                                        
                                         
                                             
                                                
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';

import 'package:naviflash/screens/bilibili_audio_song_page.dart';
import 'package:naviflash/services/bilibili_audio_zone_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/page_loading.dart';

class BilibiliAudioZonePage extends StatefulWidget {
                                      
  final int? menuId;

  const BilibiliAudioZonePage({super.key, this.menuId});

  @override
  State<BilibiliAudioZonePage> createState() => _BilibiliAudioZonePageState();
}

class _BilibiliAudioZonePageState extends State<BilibiliAudioZonePage> {
               
  List<AudioZoneMenu> _rankMenus = const [];
  List<AudioZoneMenu> _hitMenus = const [];
  bool _loading = true;
  String? _error;

                 
  AudioZoneMenuDetail? _menuDetail;
  bool _menuLoading = true;
  String? _menuError;

  bool get _isMenuMode => widget.menuId != null;

  @override
  void initState() {
    super.initState();
    if (_isMenuMode) {
      unawaited(_loadMenu());
    } else {
      unawaited(_loadHome());
    }
  }

  Future<void> _loadHome() async {
    setState(() {
                                        
                               
      _loading = _rankMenus.isEmpty && _hitMenus.isEmpty;
      _error = null;
    });
    final results = await Future.wait([
      BilibiliAudioZoneService.fetchRankMenus(pn: 1, ps: 12),
      BilibiliAudioZoneService.fetchHitMenus(pn: 1, ps: 12),
    ]);
    if (!mounted) return;
    final errs = results.map((r) => r.err).whereType<String>().toList();
    setState(() {
                                     
                            
      if (results[0].menus.isNotEmpty || _rankMenus.isEmpty) {
        _rankMenus = results[0].menus;
      }
      if (results[1].menus.isNotEmpty || _hitMenus.isEmpty) {
        _hitMenus = results[1].menus;
      }
      _loading = false;
                                 
      _error = _rankMenus.isEmpty && _hitMenus.isEmpty && errs.isNotEmpty
          ? errs.first
          : null;
    });
  }

  Future<void> _loadMenu() async {
    setState(() {
                                 
      _menuLoading = _menuDetail == null;
      _menuError = null;
    });
    final res = await BilibiliAudioZoneService.fetchMenuDetail(widget.menuId!);
    if (!mounted) return;
    if (res.detail == null && _menuDetail != null) {
                       
      setState(() => _menuLoading = false);
      showAppToast(context, res.err ?? '歌单刷新失败', error: true);
      return;
    }
    setState(() {
      _menuDetail = res.detail;
      _menuLoading = false;
      _menuError = res.detail == null ? (res.err ?? '歌单加载失败') : null;
    });
  }

  void _openMenu(AudioZoneMenu menu) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BilibiliAudioZonePage(menuId: menu.menuId),
      ),
    );
  }

  void _openSongs(List<AudioZoneSong> songs, int index) {
    final playable = songs.where((s) => s.id > 0).toList();
    if (playable.isEmpty) {
      showAppToast(context, '没有可播放的歌曲');
      return;
    }
    var start = index.clamp(0, songs.length - 1);
                       
    if (songs[start].id <= 0) start = 0;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BilibiliAudioSongPage(
          queue: playable,
          initialIndex: playable.indexOf(songs[start]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        leading: MorphIconButton(
          icon: Icons.arrow_back,
          tooltip: '返回',
          onTap: () => Navigator.of(context).maybePop(),
        ),
        title: Text(_isMenuMode ? '歌单' : '音频区'),
      ),
      body: _isMenuMode ? _buildMenuBody(cs) : _buildHomeBody(cs),
    );
  }

                                             
        
                                             

  Widget _buildHomeBody(ColorScheme cs) {
    if (_loading) return const PageLoadingIndicator();
    if (_error != null) {
      return _ErrorView(error: _error!, onRetry: () => unawaited(_loadHome()));
    }
    return AppRefreshIndicator(
      onRefresh: _loadHome,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (_rankMenus.isNotEmpty) ...[
            _SectionHeader(title: '官方榜单', cs: cs),
            SizedBox(height: 168, child: _buildRankCards(cs)),
          ],
          if (_hitMenus.isNotEmpty) ...[
            _SectionHeader(title: '热门歌单', cs: cs),
            _buildHitGrid(cs),
          ],
          if (_rankMenus.isEmpty && _hitMenus.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Center(
                child: Text(
                  '暂时没有内容',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }

                                          
  Widget _buildRankCards(ColorScheme cs) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _rankMenus.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, i) {
        final menu = _rankMenus[i];
        return _RankMenuCard(menu: menu, cs: cs, onOpen: () => _openMenu(menu));
      },
    );
  }

               
  Widget _buildHitGrid(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const columns = 2;
          final tileW = (constraints.maxWidth - (columns - 1) * 12) / columns;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: tileW / (tileW + 54),
            ),
            itemCount: _hitMenus.length,
            itemBuilder: (context, i) =>
                _HitMenuCard(menu: _hitMenus[i], onOpen: () => _openMenu(_hitMenus[i])),
          );
        },
      ),
    );
  }

                                             
          
                                             

  Widget _buildMenuBody(ColorScheme cs) {
    if (_menuLoading) return const PageLoadingIndicator();
    final detail = _menuDetail;
    if (detail == null) {
      return _ErrorView(
        error: _menuError ?? '歌单加载失败',
        onRetry: () => unawaited(_loadMenu()),
      );
    }
    final menu = detail.menu;
    return AppRefreshIndicator(
      onRefresh: _loadMenu,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _MenuHeader(menu: menu, songCount: detail.songs.length),
          const SizedBox(height: 12),
          if (detail.songs.isNotEmpty)
            FilledButton.icon(
              onPressed: () => _openSongs(detail.songs, 0),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('播放全部'),
            ),
          const SizedBox(height: 8),
          for (var i = 0; i < detail.songs.length; i++)
            _SongTile(
              index: i + 1,
              song: detail.songs[i],
              onTap: () => _openSongs(detail.songs, i),
            ),
          if (detail.songs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Center(
                child: Text(
                  '歌单里暂时没有歌曲',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

                                           
       
                                           

class _SectionHeader extends StatelessWidget {
  final String title;
  final ColorScheme cs;

  const _SectionHeader({required this.title, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
      ),
    );
  }
}

                                
class _RankMenuCard extends StatelessWidget {
  final AudioZoneMenu menu;
  final ColorScheme cs;
  final VoidCallback onOpen;

  const _RankMenuCard({
    required this.menu,
    required this.cs,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final previews = menu.previewSongs.take(3).toList();
    return Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: SizedBox(
          width: 264,
          child: Row(
            children: [
              SizedBox(
                width: 128,
                height: 168,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (menu.cover.isNotEmpty)
                      Image(
                        image: CachedImageProvider(menu.cover),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            ColoredBox(color: cs.surfaceContainerHighest),
                      )
                    else
                      ColoredBox(color: cs.surfaceContainerHighest),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Text(
                        menu.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.25,
                          shadows: [
                            Shadow(blurRadius: 6, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final song in previews)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        menu.songCount > 0 ? '${menu.songCount} 首' : '',
                        style: TextStyle(fontSize: 10.5, color: cs.outline),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

                       
class _HitMenuCard extends StatelessWidget {
  final AudioZoneMenu menu;
  final VoidCallback onOpen;

  const _HitMenuCard({required this.menu, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: menu.cover.isNotEmpty
                  ? Image(
                      image: CachedImageProvider(menu.cover),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          ColoredBox(color: cs.surfaceContainerHighest),
                    )
                  : ColoredBox(color: cs.surfaceContainerHighest),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Text(
                menu.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

                             
class _MenuHeader extends StatelessWidget {
  final AudioZoneMenu menu;
  final int songCount;

  const _MenuHeader({required this.menu, required this.songCount});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 96,
            height: 96,
            child: menu.cover.isNotEmpty
                ? Image(
                    image: CachedImageProvider(menu.cover),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        Icons.queue_music_rounded,
                        size: 32,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : ColoredBox(
                    color: cs.surfaceContainerHighest,
                    child: Icon(
                      Icons.queue_music_rounded,
                      size: 32,
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
                menu.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (menu.intro.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  menu.intro,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                _statText(),
                style: TextStyle(fontSize: 11.5, color: cs.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _statText() {
    final parts = <String>[
      if (songCount > 0) '$songCount 首',
      if (menu.play > 0) '${_fmtCount(menu.play)} 次播放',
      if (menu.collect > 0) '${_fmtCount(menu.collect)} 收藏',
    ];
    return parts.join(' · ');
  }

  static String _fmtCount(int n) {
    if (n >= 100000000) return '${(n / 100000000).toStringAsFixed(1)}亿';
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}万';
    return '$n';
  }
}

                        
class _SongTile extends StatelessWidget {
  final int index;
  final AudioZoneSong song;
  final VoidCallback onTap;

  const _SongTile({
    required this.index,
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: SizedBox(
        width: 28,
        child: Text(
          '$index',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: song.author.isNotEmpty
          ? Text(
              song.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            )
          : null,
      trailing: song.duration > 0
          ? Text(
              _fmtDuration(song.duration),
              style: TextStyle(fontSize: 11.5, color: cs.outline),
            )
          : null,
      onTap: onTap,
    );
  }

  static String _fmtDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

                      
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 40),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

                                                       
