                                            
  
                                           
                              
                                           
                                              
  
                                                       
                                                        
                                                      
                                             
           
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/widgets/morph_card.dart';

                                  
                               
   
                                                
class LongPressImagePreview extends StatefulWidget {
  final Widget child;
  final String? imageUrl;
  final Uint8List? imageBytes;
                                                            
  final BorderRadius borderRadius;

  const LongPressImagePreview({
    super.key,
    required this.child,
    this.imageUrl,
    this.imageBytes,
    this.borderRadius = const BorderRadius.all(Radius.circular(kGroupRadius)),
  }) : assert(
          imageUrl != null || imageBytes != null,
          'imageUrl 与 imageBytes 至少提供一个',
        );

  @override
  State<LongPressImagePreview> createState() => _LongPressImagePreviewState();
}

class _LongPressImagePreviewState extends State<LongPressImagePreview> {
  static const Duration _flightDuration = Duration(milliseconds: 260);
  static const Duration _dismissDuration = Duration(milliseconds: 180);

  bool _previewOpen = false;
  OverlayEntry? _entry;

  void _open() {
    if (_previewOpen) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
                            
    final fromRect = box.localToGlobal(Offset.zero) & box.size;
    _previewOpen = true;
    HapticFeedback.mediumImpact();
    final entry = OverlayEntry(
      builder: (_) => _PreviewOverlay(
        imageUrl: widget.imageUrl,
        imageBytes: widget.imageBytes,
        fromRect: fromRect,
        borderRadius: widget.borderRadius,
        flightDuration: _flightDuration,
        dismissDuration: _dismissDuration,
        onDismiss: _close,
      ),
    );
    _entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _close() {
    if (!_previewOpen) return;
    _previewOpen = false;
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _open(),
      onLongPressEnd: (_) => _close(),
      onLongPressCancel: _close,
      child: widget.child,
    );
  }
}

                                            
                              
                                            

class _PreviewOverlay extends StatefulWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final Rect fromRect;
  final BorderRadius borderRadius;
  final Duration flightDuration;
  final Duration dismissDuration;
  final VoidCallback onDismiss;

  const _PreviewOverlay({
    required this.imageUrl,
    required this.imageBytes,
    required this.fromRect,
    required this.borderRadius,
    required this.flightDuration,
    required this.dismissDuration,
    required this.onDismiss,
  });

  @override
  State<_PreviewOverlay> createState() => _PreviewOverlayState();
}

class _PreviewOverlayState extends State<_PreviewOverlay>
    with SingleTickerProviderStateMixin {
                                                       
                     
  late final AnimationController _controller;

  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.flightDuration,
      reverseDuration: widget.dismissDuration,
    );
                            
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    _controller.reverse().whenComplete(widget.onDismiss);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

                                    
  Rect _targetRect(Size screen) {
    final maxW = screen.width * 0.92;
    final maxH = screen.height * 0.85;
    return Rect.fromCenter(
      center: Offset(screen.width / 2, screen.height / 2),
      width: maxW,
      height: maxH,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final targetRect = _targetRect(screen);

    return GestureDetector(
      onTap: _dismiss,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_controller.value);
          final rect = Rect.lerp(widget.fromRect, targetRect, t)!;
          final radius = BorderRadius.lerp(
            widget.borderRadius,
            const BorderRadius.all(Radius.circular(kGroupRadius)),
            t,
          )!;
                          
          final bgOpacity = (_controller.status == AnimationStatus.reverse
                  ? _controller.value
                  : _controller.value * 4)
              .clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
                               
                                                          
                                             
              Opacity(
                opacity: bgOpacity,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
                           
              Opacity(
                opacity: bgOpacity * 0.62,
                child: const ColoredBox(color: Colors.black),
              ),
                               
              Positioned.fromRect(
                rect: rect,
                child: ClipRRect(
                  borderRadius: radius,
                  child: _buildImage(BoxFit.contain),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImage(BoxFit fit) {
    final url = widget.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image(
        image: CachedImageProvider(url),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
      );
    }
    final bytes = widget.imageBytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
      );
    }
    return _buildErrorPlaceholder();
  }

  Widget _buildErrorPlaceholder() {
    return const ColoredBox(
      color: Color(0x66000000),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 40,
          color: Colors.white54,
        ),
      ),
    );
  }
}
