import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:naviflash/main.dart' show globalNavigatorKey;
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/mini_player_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/player_settings_service.dart';
import 'package:naviflash/widgets/navi_video_surface.dart';

             
   
                                                              
                                         
         
                                      
                                      
class MiniPlayerLayer extends StatefulWidget {
  const MiniPlayerLayer({super.key});

  @override
  State<MiniPlayerLayer> createState() => _MiniPlayerLayerState();
}

class _MiniPlayerLayerState extends State<MiniPlayerLayer>
    with TickerProviderStateMixin {
  final MiniPlayerService _service = MiniPlayerService.instance;
  final GlobalKey<NaviVideoSurfaceState> _surfaceKey =
      GlobalKey<NaviVideoSurfaceState>();

                           
  late final AnimationController _appearCtrl;

                         
  late final AnimationController _expandCtrl;

  bool _expanding = false;

                           
  bool _surfaceReady = false;

  Offset? _dragTopLeft;
  Offset? _dragStartPointer;
  Offset? _dragStartTopLeft;

  static const double _margin = 12;
  static const double _minWidth = 168;
  static const double _maxWidth = 360;
  static const double _aspectRatio = 16 / 9;

  @override
  void initState() {
    super.initState();
    _appearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    if (_service.isActive) _appearCtrl.value = 1;
    _service.addListener(_onServiceChanged);
    unawaited(_service.loadSavedPosition());
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _appearCtrl.dispose();
    _expandCtrl.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    if (_service.isActive) {
                            
      _dragTopLeft = null;
      _surfaceReady = false;
      _appearCtrl.forward(from: 0);
    }
    setState(() {});
  }

  Size _windowSize(Size screen) {
    final w = (screen.width * 0.42).clamp(_minWidth, _maxWidth);
    return Size(w, w / _aspectRatio);
  }

                                     
  Rect _restingRect(Size screen) {
    final win = _windowSize(screen);
    final drag = _dragTopLeft;
    if (drag != null) {
      return Rect.fromLTWH(drag.dx, drag.dy, win.width, win.height);
    }
    final maxLeft = (screen.width - win.width - _margin).clamp(0.0, double.infinity);
    final maxTop =
        (screen.height - win.height - _margin).clamp(0.0, double.infinity);
    final savedLeft = _service.savedLeftRatio;
    final savedTop = _service.savedTopRatio;
    final left = savedLeft != null
        ? (savedLeft * screen.width).clamp(0.0, maxLeft)
        : maxLeft;
                  
    final top = savedTop != null
        ? (savedTop * screen.height).clamp(0.0, maxTop)
        : (screen.height - win.height - 96).clamp(0.0, maxTop);
    return Rect.fromLTWH(left, top, win.width, win.height);
  }

  Offset _clampTopLeft(Offset topLeft, Size screen) {
    final win = _windowSize(screen);
    final maxLeft = (screen.width - win.width).clamp(0.0, double.infinity);
    final maxTop = (screen.height - win.height).clamp(0.0, double.infinity);
    return Offset(
      topLeft.dx.clamp(0.0, maxLeft),
      topLeft.dy.clamp(0.0, maxTop),
    );
  }

                        
  Future<void> _snapAndPersist(Size screen) async {
    final topLeft = _dragTopLeft;
    if (topLeft == null) return;
    final win = _windowSize(screen);
    final centerX = topLeft.dx + win.width / 2;
    final targetLeft =
        centerX < screen.width / 2 ? _margin : screen.width - win.width - _margin;
    final snapped = Offset(
      targetLeft.clamp(0.0, (screen.width - win.width).clamp(0.0, double.infinity)),
      topLeft.dy,
    );
    setState(() => _dragTopLeft = snapped);
    await _service.persistFrameRatio(
      Rect.fromLTWH(snapped.dx, snapped.dy, win.width, win.height),
      screen,
    );
  }

  Future<void> _openVideoPage(String bvid, Duration position) async {
    final navigator = globalNavigatorKey.currentState;
    if (navigator == null) return;
    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            BilibiliVideoPage(bvid: bvid, initialPosition: position),
      ),
    );
  }

                                   
  Future<void> _expandToVideoPage() async {
    final data = _service.data;
    if (data == null || _expanding) return;
    final bvid = data.bvid;
    if (bvid == null || bvid.isEmpty) return;
    final position = _surfaceKey.currentState?.position ?? data.position;

    setState(() => _expanding = true);
    unawaited(_openVideoPage(bvid, position));
    await _expandCtrl.forward(from: 0);
    if (!mounted) return;
    _service.close();
    setState(() => _expanding = false);
  }

  void _closeMini() {
    _service.close();
  }

  @override
  Widget build(BuildContext context) {
                                                     
                                                                 
                                                            
                                                  
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_service.isActive,
        child: AnimatedBuilder(
          animation: Listenable.merge([_service, _appearCtrl, _expandCtrl]),
          builder: (context, _) {
            final data = _service.data;
            if (data == null) return const SizedBox.shrink();

            return LayoutBuilder(
              builder: (context, constraints) {
                final screen = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                if (screen.isEmpty) return const SizedBox.shrink();

                final rest = _restingRect(screen);
                var rect = rest;
                var opacity = 1.0;

                final origin = _service.originRect;
                if (_appearCtrl.value < 1 && origin != null && !_expanding) {
                  final t = Curves.easeOutCubic.transform(_appearCtrl.value);
                  rect = Rect.lerp(origin, rest, t) ?? rest;
                  opacity = Curves.easeOut.transform(_appearCtrl.value);
                }

                if (_expanding) {
                  final t = Curves.easeInCubic.transform(_expandCtrl.value);
                  final target = Rect.fromCenter(
                    center: Offset(screen.width / 2, screen.height / 2),
                    width: screen.width * 0.92,
                    height: screen.width * 0.92 * 9 / 16,
                  );
                  rect = Rect.lerp(rest, target, t) ?? rest;
                  opacity = 1 - t * 0.7;
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fromRect(
                      rect: rect,
                      child: IgnorePointer(
                        ignoring: _expanding,
                        child: Opacity(
                          opacity: opacity.clamp(0.0, 1.0),
                          child: _buildWindow(data, screen, rest),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWindow(MiniPlayerData data, Size screen, Rect rest) {
    const radius = BorderRadius.all(Radius.circular(12));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _expandToVideoPage,
      onPanStart: (details) {
        _dragStartPointer = details.globalPosition;
        _dragStartTopLeft = Offset(rest.left, rest.top);
      },
      onPanUpdate: (details) {
        final startPointer = _dragStartPointer;
        final startTopLeft = _dragStartTopLeft;
        if (startPointer == null || startTopLeft == null) return;
        final delta = details.globalPosition - startPointer;
        setState(
          () => _dragTopLeft = _clampTopLeft(startTopLeft + delta, screen),
        );
      },
      onPanEnd: (_) => unawaited(_snapAndPersist(screen)),
      child: Material(
        color: Colors.black,
        elevation: 12,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NaviVideoSurface(
              key: _surfaceKey,
              videoUrl: data.videoUrl,
              httpHeaders: data.httpHeaders,
              initialPosition: data.position,
              fit: BoxFit.contain,
              playerSettings: context.read<PlayerSettingsService>(),
              onReady: () {
                if (mounted && !_surfaceReady) {
                  setState(() => _surfaceReady = true);
                }
              },
            ),
                                      
            if (data.cover != null && data.cover!.isNotEmpty)
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _surfaceReady ? 0 : 1,
                  duration: const Duration(milliseconds: 220),
                  child: Image(
                    image: CachedImageProvider(data.cover!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
                        
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xCC000000)],
                    ),
                  ),
                  child: Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: _RoundIconButton(
                icon: Icons.close_rounded,
                onTap: _closeMini,
              ),
            ),
            Positioned(
              left: 4,
              bottom: 4,
              child: _RoundIconButton(
                icon: Icons.pause_rounded,
                onTap: () =>
                    unawaited(_surfaceKey.currentState?.togglePlay() ??
                        Future<void>.value()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

                         
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(icon, size: 15, color: Colors.white),
        ),
      ),
    );
  }
}
