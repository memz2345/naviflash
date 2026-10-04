                                       
  
                                             
  
                                                  
                               
                                                             
                                        
                                    

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_user_space_page_v2.dart';
import 'package:naviflash/services/bilibili_video_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/native_menu_service.dart';
import 'package:naviflash/services/playback_focus.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/more_menu_sheet.dart';
import 'package:naviflash/widgets/page_loading.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

                           
class AudioEpisode {
  final int cid;
  final String title;

  const AudioEpisode({required this.cid, required this.title});
}

class BilibiliAudioPage extends StatefulWidget {
  const BilibiliAudioPage({
    super.key,
    required this.bvid,
    required this.title,
    required this.cover,
    required this.episodes,
    this.initialIndex = 0,
    this.initialPosition,
    this.initialDuration,
    this.ownerName,
    this.ownerMid,
    this.ownerFace,
  });

  final String bvid;
  final String title;
  final String cover;

                                        
  final List<AudioEpisode> episodes;
  final int initialIndex;

                                       
                         
  final Duration? initialPosition;

                                       
                                            
                                  
  final Duration? initialDuration;

  final String? ownerName;
  final int? ownerMid;
  final String? ownerFace;

  @override
  State<BilibiliAudioPage> createState() => _BilibiliAudioPageState();
}

class _BilibiliAudioPageState extends State<BilibiliAudioPage>
    implements PlaybackAudioSource {
                                             
  static const Map<String, String> _mediaHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  static const List<double> _rates = [0.75, 1.0, 1.25, 1.5, 2.0];

  Player? _player;
  int _index = 0;
  bool _loading = true;
  String? _error;
  double _rate = 1.0;

                                     
  Duration? _pendingSeek;

                                           
                                     
  final ValueNotifier<Duration> _posNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _durNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> _playingNotifier = ValueNotifier(false);

  final List<StreamSubscription<dynamic>> _subs = [];

                                                  

  @override
  bool get isPlaying => _player?.state.playing ?? false;

  @override
  Future<void> pause() async => _player?.pause();

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(
      0,
      math.max(0, widget.episodes.length - 1),
    );
    PlaybackFocus.instance.register(this);
    _pendingSeek = widget.initialPosition;
                                                 
                                         
                  
    if (widget.initialPosition != null) {
      _posNotifier.value = widget.initialPosition!;
    }
    if (widget.initialDuration != null) {
      _durNotifier.value = widget.initialDuration!;
    }
    unawaited(_init());
  }

  @override
  void dispose() {
    PlaybackFocus.instance.unregister(this);
    for (final s in _subs) {
      s.cancel();
    }
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
    _subs.add(
      player.stream.position.listen((p) => _posNotifier.value = p),
    );
    _subs.add(player.stream.duration.listen((d) => _durNotifier.value = d));
    _subs.add(player.stream.playing.listen((v) => _playingNotifier.value = v));
    _subs.add(
      player.stream.completed.listen((v) {
        if (v) unawaited(_next());
      }),
    );
    await _openCurrent(autoPlay: true);
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

  Future<void> _openCurrent({bool autoPlay = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final ep = widget.episodes[_index];
    final play = await BilibiliVideoService.fetchPlayUrl(
      bvid: widget.bvid,
      cid: ep.cid,
    );
    if (!mounted) return;
    final url = play == null
        ? null
        : BilibiliVideoService.buildAudioUrl(play);
    if (url == null) {
      setState(() {
        _loading = false;
        _error = BilibiliVideoService.lastErrorDetail ?? '解析播放地址失败';
      });
      return;
    }
    try {
      await _player!.open(Media(url, httpHeaders: _mediaHeaders));
                        
      await _applyAudioOnly(_player!);
      if (_rate != 1.0) await _player!.setRate(_rate);
                                    
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
    if (index < 0 || index >= widget.episodes.length) return;
    _index = index;
    await _openCurrent(autoPlay: true);
  }

  Future<void> _next() => _goTo(_index + 1);

  Future<void> _prev() => _goTo(_index - 1);

  Future<void> _setRate(double rate) async {
    _rate = rate;
    if (mounted) setState(() {});
    await _player?.setRate(rate);
  }

                                                             

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final landscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final multi = widget.episodes.length > 1;

    return PopScope(
                                               
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_posNotifier.value);
      },
      child: Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
                                             
                                
        leading: MorphIconButton(
          icon: Icons.arrow_back,
          tooltip: l10n.commonBackTooltip,
          onTap: () => Navigator.of(context).pop(_posNotifier.value),
        ),
        title: Text(l10n.audioPageTitle),
        actions: [
                                                   
          LiquidGlassMenuButton(
            icon: Icons.speed_outlined,
            tooltip: l10n.audioPageSpeed,
            useMorphStyle: false,
            iconColor: cs.onSurface,
            menuWidth: 160,
            actions: [
              for (final r in _rates)
                GlassMenuAction(
                  icon: Icons.speed,
                  text: '${r}x',
                  trailing: _rate == r
                      ? const Icon(Icons.check, size: 18)
                      : null,
                  onTap: () => _setRate(r),
                ),
            ],
          ),
                     
          if (multi)
            MorphIconButton(
              icon: Icons.playlist_play_rounded,
              tooltip: l10n.playerArtistPlaylist,
              onTap: _showPlaylist,
            ),
        ],
      ),
      body: Stack(
        children: [
                                       
                      
          Positioned.fill(child: _buildImmersiveBackdrop(cs)),
          SafeArea(
        child: _error != null
            ? _buildError(cs, l10n)
            : (landscape
                  ? Row(
                      children: [
                        Expanded(child: Center(child: _buildCover(cs))),
                        Expanded(child: _buildControls(cs, l10n, multi)),
                      ],
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildCover(cs),
                        const SizedBox(height: 20),
                        Expanded(child: _buildControls(cs, l10n, multi)),
                      ],
                    )),
          ),
        ],
      ),
      ),
    );
  }

                                         
  Widget _buildImmersiveBackdrop(ColorScheme cs) {
    final cover = widget.cover;
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

  Widget _buildError(ColorScheme cs, AppLocalizations l10n) {
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
              onPressed: () => _openCurrent(autoPlay: true),
              child: Text(l10n.audioPageRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(ColorScheme cs) {
    final size = MediaQuery.of(context).size;
    final edge = math
        .min(math.min(size.width, size.height) * 0.5, 260.0)
        .clamp(120.0, 260.0);
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
      child: widget.cover.isEmpty
          ? placeholder
          : Image(
              image: CachedImageProvider(widget.cover),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }

  Widget _buildControls(ColorScheme cs, AppLocalizations l10n, bool multi) {
    final title = widget.episodes.length > 1
        ? widget.episodes[_index].title
        : widget.title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          _buildUpRow(cs),
          const SizedBox(height: 18),
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
        ],
      ),
    );
  }

  Widget _buildUpRow(ColorScheme cs) {
    final name = widget.ownerName;
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    final mid = widget.ownerMid ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: mid <= 0
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BilibiliUserSpacePage(
                    mid: mid,
                    focusBvid: widget.bvid,
                  ),
                ),
              );
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((widget.ownerFace ?? '').isNotEmpty)
              ClipOval(
                child: Image(
                  image: CachedImageProvider(widget.ownerFace!),
                  width: 22,
                  height: 22,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 22),
                ),
              )
            else
              const SizedBox(width: 22),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
          ],
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
                              Duration(
                                milliseconds: (v * total).round(),
                              ),
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
        if (multi)
          IconButton(
            iconSize: 32,
            icon: const Icon(Icons.skip_previous_rounded),
            onPressed: _index > 0 ? () => unawaited(_prev()) : null,
          )
        else
          const SizedBox(width: 48),
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
        if (multi)
          IconButton(
            iconSize: 32,
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: _index < widget.episodes.length - 1
                ? () => unawaited(_next())
                : null,
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }

                   
  Future<void> _showPlaylist() async {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      title: l10n.playerArtistPlaylist,
      items: [
        for (var i = 0; i < widget.episodes.length; i++)
          NativeMenuItem(
            text: widget.episodes[i].title,
            subtitle: '${i + 1}/${widget.episodes.length}',
            checked: i == _index,
            onTap: () => unawaited(_goTo(i)),
          ),
      ],
    );
    if (nativeOk || !mounted) return;
    showAppBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Text(
                      l10n.playerArtistPlaylist,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_index + 1}/${widget.episodes.length}',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.episodes.length,
                  itemBuilder: (ctx, i) {
                    final ep = widget.episodes[i];
                    final active = i == _index;
                    return ListTile(
                      dense: true,
                      selected: active,
                      leading: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          color: active ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                      title: Text(
                        ep.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        unawaited(_goTo(i));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _fmt(Duration d) {
    final total = d.inSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    final mm = h > 0 ? m.toString().padLeft(2, '0') : '$m';
    return h > 0
        ? '$h:$mm:${s.toString().padLeft(2, '0')}'
        : '$mm:${s.toString().padLeft(2, '0')}';
  }
}
