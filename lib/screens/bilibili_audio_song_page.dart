                                            
  
                                   
  
                                             
                                                      
                                            
                                                   
                                                         
                                                                
                                                     
                                                    
                                                        
                           
                                                                    
                                                                   
import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'package:naviflash/screens/bilibili_user_space_page_v2.dart';
import 'package:naviflash/services/bilibili_audio_zone_service.dart';
import 'package:naviflash/services/bilibili_favorite_service.dart';
import 'package:naviflash/services/playback_focus.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/page_loading.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

class BilibiliAudioSongPage extends StatefulWidget {
                                        
  final List<AudioZoneSong> queue;
  final int initialIndex;

  const BilibiliAudioSongPage({
    super.key,
    required this.queue,
    this.initialIndex = 0,
  });

  @override
  State<BilibiliAudioSongPage> createState() => _BilibiliAudioSongPageState();
}

class _BilibiliAudioSongPageState extends State<BilibiliAudioSongPage>
    implements PlaybackAudioSource {
  Player? _player;
  int _index = 0;
  bool _loading = true;
  String? _error;

                             
  AudioZoneSong? _detail;

                           
  bool _autoRetryUsed = false;

                            
  Duration? _pendingSeek;

  final List<StreamSubscription<dynamic>> _subs = [];

                                           
                             
  final ValueNotifier<Duration> _posNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _durNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> _playingNotifier = ValueNotifier(false);

  AudioZoneSong get _current => widget.queue[_index];

                                                  

  @override
  bool get isPlaying => _player?.state.playing ?? false;

  @override
  Future<void> pause() async => _player?.pause();

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.queue.length - 1);
    PlaybackFocus.instance.register(this);
    unawaited(_init());
  }

  @override
  void dispose() {
    PlaybackFocus.instance.unregister(this);
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    final player = _player;
    _player = null;
    if (player != null) unawaited(player.dispose());
    _posNotifier.dispose();
    _durNotifier.dispose();
    _playingNotifier.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final player = Player(
      configuration: PlayerConfiguration(bufferSize: 16 * 1024 * 1024),
    );
    _player = player;
    await _applyAudioOnly(player);
    _subs.addAll([
      player.stream.position.listen((p) => _posNotifier.value = p),
      player.stream.duration.listen((d) => _durNotifier.value = d),
      player.stream.playing.listen((v) => _playingNotifier.value = v),
                               
      player.stream.completed.listen((v) {
        if (v) unawaited(_next(autoAdvance: true));
      }),
                                         
      player.stream.error.listen((_) => unawaited(_recoverFromError())),
    ]);
    await _openCurrent(autoPlay: true);
    unawaited(_loadDetail());
  }

                                
  Future<void> _applyAudioOnly(Player player) async {
    try {
      final platform = player.platform;
      if (platform is! NativePlayer) return;
      await platform.setProperty('vid', 'no');
      await platform.setProperty('file-local-options/vid', 'no');
    } catch (_) {
                                 
    }
  }

                                       
  Future<void> _loadDetail() async {
    final song = _current;
    final res = await BilibiliAudioZoneService.fetchSongInfo(song.id);
    if (!mounted) return;
    if (res.song == null || _current.id != song.id) return;
    final s = res.song!;
    setState(() {
      _detail = AudioZoneSong(
        id: s.id,
        title: s.title.isNotEmpty ? s.title : song.title,
        author: s.author.isNotEmpty ? s.author : song.author,
        cover: s.cover.isNotEmpty ? s.cover : song.cover,
        duration: s.duration > 0 ? s.duration : song.duration,
        play: s.play > 0 ? s.play : song.play,
        intro: s.intro,
        uploader: s.uploader,
        uid: s.uid > 0 ? s.uid : song.uid,
        avid: s.avid > 0 ? s.avid : song.avid,
        bvid: s.bvid.isNotEmpty ? s.bvid : song.bvid,
      );
    });
  }

  Future<void> _openCurrent({bool autoPlay = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _autoRetryUsed = false;
      _detail = null;
    });
    _posNotifier.value = Duration.zero;
    _durNotifier.value = Duration.zero;
    final res = await BilibiliAudioZoneService.resolvePlayUrl(
      sid: _current.id,
    );
    if (!mounted) return;
    final url = res.play?.firstUrl;
    if (url == null) {
      setState(() {
        _loading = false;
        _error = res.err ?? '解析播放地址失败';
      });
      return;
    }
    try {
      await _player!.open(
        Media(url, httpHeaders: BilibiliAudioZoneService.mediaHeaders),
      );
                        
      await _applyAudioOnly(_player!);
      final pending = _pendingSeek;
      if (pending != null && pending > Duration.zero) {
        _pendingSeek = null;
        await _player!.seek(pending);
      }
      if (autoPlay) await _player!.play();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
      return;
    }
    if (mounted) setState(() => _loading = false);
  }

                                          
  Future<void> _recoverFromError() async {
    if (!mounted || _player == null || _loading) return;
    final pos = _posNotifier.value;
    if (_autoRetryUsed) return;
    _autoRetryUsed = true;
    debugPrint('[AudioSong] 播放出错，重新解析播放地址（sid=${_current.id}）');
    _pendingSeek = pos;
    await _openCurrent(autoPlay: true);
  }

  Future<void> _togglePlay() async {
    final player = _player;
    if (player == null) return;
    if (player.state.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> _goTo(int index) async {
    if (index < 0 || index >= widget.queue.length) return;
    _index = index;
    _pendingSeek = null;
    await _openCurrent(autoPlay: true);
    unawaited(_loadDetail());
  }

  Future<void> _next({bool autoAdvance = false}) async {
    if (_index >= widget.queue.length - 1) {
                                  
      if (!autoAdvance && mounted) showAppToast(context, '已经是最后一首了');
      return;
    }
    await _goTo(_index + 1);
  }

  Future<void> _prev() async {
    if (_index <= 0) {
      if (mounted) showAppToast(context, '已经是第一首了');
      return;
    }
    await _goTo(_index - 1);
  }

             

  Future<void> _showCollectSheet() async {
    final song = _detail ?? _current;
    if (!BilibiliFavoriteService.isLoggedIn) {
      showAppToast(context, '还没有登录，登录后才能收藏');
      return;
    }
    final folders = await BilibiliFavoriteService.fetchFolders(
      rid: song.id,
      type: 12,
    );
    if (!mounted) return;
    if (folders == null) {
      showAppToast(
        context,
        BilibiliFavoriteService.lastErrorDetail ?? '收藏夹获取失败',
        error: true,
      );
      return;
    }
    var changed = false;
    await showAppBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final cs = Theme.of(sheetCtx).colorScheme;
            final selected = folders
                .where((f) => f.favState == 1)
                .map((f) => f.id)
                .toSet();
            Future<void> toggle(BiliFavFolder folder) async {
              final add = !selected.contains(folder.id);
              final res = await BilibiliAudioZoneService.collectAudio(
                sid: song.id,
                addIds: add ? [folder.id] : const [],
                delIds: add ? const [] : [folder.id],
              );
              if (!sheetCtx.mounted) return;
              if (!res.ok) {
                showAppToast(sheetCtx, res.message, error: true);
                return;
              }
              changed = true;
              setSheetState(() {
                add ? selected.add(folder.id) : selected.remove(folder.id);
              });
            }

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '收藏到歌单收藏夹',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                          child: const Text('完成'),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: folders.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              '还没有创建歌单收藏夹',
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: folders.length,
                            itemBuilder: (ctx, i) {
                              final folder = folders[i];
                              final checked = selected.contains(folder.id);
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  checked
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  size: 20,
                                  color: checked
                                      ? cs.primary
                                      : cs.onSurfaceVariant,
                                ),
                                title: Text(
                                  folder.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  '${folder.mediaCount}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                onTap: () => unawaited(toggle(folder)),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (changed) unawaited(_loadDetail());
  }

                                             
        
                                             

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final song = _detail ?? _current;
    final multi = widget.queue.length > 1;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: MorphIconButton(
          icon: Icons.arrow_back,
          tooltip: '返回',
          onTap: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          multi ? '歌曲 ${_index + 1}/${widget.queue.length}' : '歌曲',
        ),
        actions: [
          IconButton(
            tooltip: '收藏',
            icon: const Icon(Icons.star_border_rounded),
            onPressed: () => unawaited(_showCollectSheet()),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildImmersiveBackdrop(cs)),
          SafeArea(
            child: _error != null
                ? _buildError(cs)
                : Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildCover(cs, song),
                      const SizedBox(height: 16),
                      Expanded(child: _buildControls(cs, song, multi)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

                                 
  Widget _buildImmersiveBackdrop(ColorScheme cs) {
    final cover = (_detail ?? _current).cover;
    if (cover.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.surfaceContainerHighest, cs.surface],
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Image(
            image: CachedImageProvider(cover),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ColoredBox(color: cs.surface),
          ),
        ),
        ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
      ],
    );
  }

  Widget _buildCover(ColorScheme cs, AudioZoneSong song) {
    final size = MediaQuery.of(context).size;
    final edge = (size.shortestSide * 0.5).clamp(120.0, 240.0);
    final placeholder = Container(
      width: edge,
      height: edge,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.audiotrack, size: 56, color: cs.onSurfaceVariant),
    );
    return Container(
      width: edge,
      height: edge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: song.cover.isEmpty
          ? placeholder
          : Image(
              image: CachedImageProvider(song.cover),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 40),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => unawaited(_openCurrent(autoPlay: true)),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ColorScheme cs, AudioZoneSong song, bool multi) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            song.title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          _buildAuthorRow(cs, song),
          if (song.play > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${_fmtCount(song.play)} 次播放',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: PageLoadingIndicator(),
            )
          else ...[
            _buildProgressBar(cs),
            const SizedBox(height: 8),
            _buildControlRow(cs, multi),
          ],
          if ((song.intro).isNotEmpty) ...[
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  song.intro,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _buildAuthorRow(ColorScheme cs, AudioZoneSong song) {
    final author = song.author.isNotEmpty ? song.author : song.uploader;
    if (author.isEmpty) return const SizedBox.shrink();
                                   
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: song.uid <= 0
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BilibiliUserSpacePage(mid: song.uid),
                ),
              );
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          author,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme cs) {
    return ValueListenableBuilder<Duration>(
      valueListenable: _durNotifier,
      builder: (context, dur, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: _posNotifier,
          builder: (context, pos, _) {
            final total = dur.inMilliseconds;
            final value = total <= 0
                ? 0.0
                : (pos.inMilliseconds / total).clamp(0.0, 1.0);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
                  child: Slider(
                    value: value,
                    onChanged: total <= 0
                        ? null
                        : (v) {
                            _player?.seek(
                              Duration(milliseconds: (v * total).round()),
                            );
                          },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmt(pos),
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                    Text(
                      _fmt(dur),
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControlRow(ColorScheme cs, bool multi) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: multi && _index > 0 ? () => unawaited(_prev()) : null,
        ),
        const SizedBox(width: 16),
        ValueListenableBuilder<bool>(
          valueListenable: _playingNotifier,
          builder: (context, playing, _) {
            return IconButton.filledTonal(
              iconSize: 40,
              icon: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              onPressed: () => unawaited(_togglePlay()),
            );
          },
        ),
        const SizedBox(width: 16),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: multi && _index < widget.queue.length - 1
              ? () => unawaited(_next())
              : null,
        ),
      ],
    );
  }

  static String _fmt(Duration d) {
    final total = d.inSeconds;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String _fmtCount(int n) {
    if (n >= 100000000) return '${(n / 100000000).toStringAsFixed(1)}亿';
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}万';
    return '$n';
  }
}
