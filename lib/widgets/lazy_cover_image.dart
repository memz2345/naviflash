                                    
  
                                    
                                                   
                                      
                                                
                                                     
                                        
                                                   
                   
  
                                                
                              
import 'package:flutter/material.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';

                                             
   
                                                       
                                               
                                               
                                       
String thumbnailCoverUrl(
  String url, {
  double? width,
  double? height,
  double? aspect,
  int maxDimension = 480,
  double? devicePixelRatio,
}) {
  final normalized = url.startsWith('//') ? 'https:$url' : url;
  if (normalized.isEmpty) return normalized;
                                    
  if (normalized.contains('@') || normalized.contains('?')) return normalized;

  double? tw = width;
  double? th = height;
  if (tw != null && th == null && aspect != null) th = tw / aspect;
  if (th != null && tw == null && aspect != null) tw = th * aspect;
  if (tw == null && th == null) {
                                               
                        
    final a = aspect ?? (16 / 9);
    if (a >= 1) {
      tw = maxDimension.toDouble();
      th = maxDimension / a;
    } else {
      th = maxDimension.toDouble();
      tw = maxDimension * a;
    }
  }
  if (tw == null || th == null) return normalized;             

                                              
  final dpr = devicePixelRatio ?? 2.0;
  int w = (tw * dpr).round();
  int h = (th * dpr).round();
  final cap = maxDimension.toDouble();
  if (w > cap || h > cap) {
    final r = cap / (w > h ? w : h);
    w = (w * r).round();
    h = (h * r).round();
  }
  return '$normalized@${w}w_${h}h_1c.webp';
}

             
   
         
                                                              
                                             
                                       
                                                         
                                                           
class LazyCoverImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final double? aspect;
  final BoxFit fit;
                                     
  final int maxDimension;
                                 
  final double preloadExtent;
                                                       
  final Map<String, String>? headers;
                                    
  final ImageErrorWidgetBuilder? errorBuilder;

  const LazyCoverImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.aspect,
    this.fit = BoxFit.cover,
    this.maxDimension = 480,
    this.preloadExtent = 400,
    this.headers,
    this.errorBuilder,
  });

  @override
  State<LazyCoverImage> createState() => _LazyCoverImageState();
}

class _LazyCoverImageState extends State<LazyCoverImage> {
  bool _shouldLoad = false;
  ScrollPosition? _position;
  final GlobalKey _boxKey = GlobalKey();

  @override
  void initState() {
    super.initState();
                                      
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pos = Scrollable.maybeOf(context)?.position;
    if (pos != _position) {
      _position?.removeListener(_onScroll);
      _position = pos;
      _position?.addListener(_onScroll);
    }
                                
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    _position = null;
    super.dispose();
  }

  void _onScroll() => _check();

                                     
                                      
  void _check() {
    if (!mounted || _shouldLoad) return;
    final ctx = _boxKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final screenH = MediaQuery.sizeOf(ctx).height;
    final within = rect.bottom >= -widget.preloadExtent &&
        rect.top <= screenH + widget.preloadExtent;
    if (within && mounted) setState(() => _shouldLoad = true);
  }

  Widget _placeholder(ColorScheme cs, {bool withIcon = false}) {
    final block = Container(
      color: cs.surfaceContainerHighest,
      child: withIcon
          ? const Center(
              child: Icon(Icons.movie_outlined, color: Colors.white24),
            )
          : null,
    );
    return block;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final placeholder = _placeholder(cs);

                            
    if (widget.url.isEmpty) {
      return _sized(placeholder, cs, withIcon: true);
    }

                                       
    if (!_shouldLoad) {
      return _sized(placeholder, cs);
    }

    final headers = widget.headers ??
        (NetworkSettingsService.instance.apiHeaders.isEmpty
            ? null
            : NetworkSettingsService.instance.apiHeaders);
    final thumb = thumbnailCoverUrl(
      widget.url,
      width: widget.width,
      height: widget.height,
      aspect: widget.aspect,
      maxDimension: widget.maxDimension,
      devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
    );

    final img = Image(
      image: CachedImageProvider(thumb, headers: headers),
      fit: widget.fit,
                                         
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return placeholder;
      },
      errorBuilder: widget.errorBuilder ??
          (_, __, ___) => _placeholder(cs, withIcon: true),
    );

    return _sized(img, cs);
  }

                                                          
                                     
  Widget _sized(Widget child, ColorScheme cs, {bool withIcon = false}) {
    final inner = withIcon
        ? (child is Container ? child : _placeholder(cs, withIcon: true))
        : child;
    if (widget.width != null && widget.height != null) {
      return SizedBox(
        key: _boxKey,
        width: widget.width,
        height: widget.height,
        child: inner,
      );
    }
    if (widget.aspect != null) {
      return AspectRatio(
        key: _boxKey,
        aspectRatio: widget.aspect!,
        child: inner,
      );
    }
                                           
    return KeyedSubtree(key: _boxKey, child: inner);
  }
}
