                                           
  
                                                    
                                                          
                                                 
                                                        
                                  
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/screens/image_viewer_page.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_zoom_hero.dart';
import 'package:naviflash/widgets/long_press_image_preview.dart';
import 'package:naviflash/widgets/ugc_rich_text.dart';
import 'package:naviflash/l10n/app_localizations.dart';

                                  
Map<String, String>? _imageHeaders() {
  try {
    final headers = NetworkSettingsService.instance.apiHeaders;
    return headers.isEmpty ? null : headers;
  } catch (_) {
    return null;
  }
}

                                                
                                                
                                             
class CommentMessageText extends StatelessWidget {
  final String message;
  final Map<String, BiliCommentEmote> emotes;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final void Function(Duration position)? onSeek;
  final Duration? maxSeekable;

  const CommentMessageText({
    super.key,
    required this.message,
    required this.emotes,
    this.style,
    this.maxLines,
    this.overflow,
    this.onSeek,
    this.maxSeekable,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(
        children: buildCommentSpans(
          message: message,
          emotes: emotes,
          style: style,
          context: context,
          onSeek: onSeek,
          maxSeekable: maxSeekable,
        ),
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

                                              
                                                   
List<InlineSpan> buildCommentSpans({
  required String message,
  required Map<String, BiliCommentEmote> emotes,
  TextStyle? style,
  BuildContext? context,
  void Function(Duration position)? onSeek,
  Duration? maxSeekable,
}) {
  if (message.isEmpty) return const [];
  return buildUgcSpans(
    text: message,
    style: style,
    emotes: emotes,
    context: context,
    onSeek: onSeek,
    maxSeekable: maxSeekable,
    accentColor: const Color(0xFF23ADE5),
  );
}

                                    
class CommentPictures extends StatelessWidget {
  final List<BiliCommentPicture> pictures;

  const CommentPictures({super.key, required this.pictures});

  static const double _thumbHeight = 96;
  static const double _thumbMaxWidth = 220;

  @override
  Widget build(BuildContext context) {
    if (pictures.isEmpty) return const SizedBox.shrink();
    final list = pictures.take(4).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final pic in list) _CommentPicThumb(picture: pic)],
      ),
    );
  }
}

class _CommentPicThumb extends StatefulWidget {
  final BiliCommentPicture picture;

  const _CommentPicThumb({required this.picture});

  @override
  State<_CommentPicThumb> createState() => _CommentPicThumbState();
}

class _CommentPicThumbState extends State<_CommentPicThumb> {
  bool _downloading = false;
                                          
  static int _heroSeq = 0;
  late final String _heroTag =
      'comment_pic_${_p.src.hashCode}_${_heroSeq++}';

  BiliCommentPicture get _p => widget.picture;

                                
  double _thumbWidth() {
    final w = _p.width > 0 ? _p.width.toDouble() : 1.0;
    final h = _p.height > 0 ? _p.height.toDouble() : 1.0;
    final ratio = (h / w).clamp(0.5, 3.0);
    return (CommentPictures._thumbHeight / ratio).clamp(
      48.0,
      CommentPictures._thumbMaxWidth,
    );
  }

                                       
  Widget _buildPicImage(ColorScheme cs) {
    final image = Image(
      image: CachedImageProvider(
        '${_p.src}@${_thumbWidth().round()}w_'
        '${CommentPictures._thumbHeight.round()}h_1c.webp',
        headers: _imageHeaders(),
      ),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => Icon(
        Icons.image_outlined,
        size: 28,
        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
    if (ZoomHeroScope.activeOf(context)) return image;
    if (SettingsService.heroTransitionBlurEnabled) {
                                           
      return Hero(
          transitionOnUserGestures: true,
        tag: _heroTag,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        flightShuttleBuilder: imageZoomHeroFlightShuttle,
        child: image,
      );
    }
    return Hero(
        transitionOnUserGestures: true,
      tag: _heroTag,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
      child: image,
    );
  }

                   
  Future<void> _openViewer(BuildContext context) async {
    if (_downloading) return;
    HapticFeedback.lightImpact();
    setState(() => _downloading = true);
    final bytes = await BilibiliCommentService.fetchBytes(_p.src);
    if (!context.mounted) return;
    setState(() => _downloading = false);
    if (bytes == null) {
      showAppToast(
        context,
        AppLocalizations.of(context).commentImageLoadFail,
        error: true,
      );
      return;
    }
    await Navigator.of(context).push(
      heroTransitionRoute(
                                                   
        heroZoom: true,
        page: ImageViewerPage(
          imageBytes: bytes,
          heroTag: _heroTag,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
                                        
    return LongPressImagePreview(
      imageUrl: _p.src,
      child: GestureDetector(
        onTap: () => _openViewer(context),
        child: Container(
          width: _thumbWidth(),
          height: CommentPictures._thumbHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
                                                               
                                            
                                                    
                                                        
                                       
              _buildPicImage(cs),
              if (_downloading)
                ColoredBox(
                  color: Colors.black38,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: cs.primary,
                      ),
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
