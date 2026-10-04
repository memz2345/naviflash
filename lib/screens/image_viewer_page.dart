                                     
  
                  
                                 
                                
                                        
                                               
                                         
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:gal/gal.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/services/native_menu_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/more_menu_sheet.dart';
import 'package:naviflash/widgets/ios_zoom_hero.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/bilibili_user_space_service.dart';
import '../services/lnative_bridge.dart';
import '../services/network_settings_service.dart';
import '../l10n/app_localizations.dart';

           
class ImageViewerSource {
             
  final String? url;

             
  final String? filePath;

             
  final Uint8List? bytes;

                                     
  final String? heroTag;

  const ImageViewerSource({this.url, this.filePath, this.bytes, this.heroTag});
}

class ImageViewerPage extends StatefulWidget {
                                    

  final String? filePath;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final String? heroTag;

             

                            
  final List<ImageViewerSource>? sources;

                
  final int initialIndex;

  const ImageViewerPage({
    super.key,
    this.filePath,
    this.imageBytes,
    this.imageUrl,
    this.heroTag,
    this.sources,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
                              
  late final List<ImageViewerSource> _sources;
  late final PageController _pageController;
  late int _current;

                                                
                                               
                             
  late final String? _zoomHeroTag = SettingsService.heroTransitionBlurEnabled
      ? _sources[widget.initialIndex.clamp(0, _sources.length - 1)].heroTag
      : null;

  @override
  void initState() {
    super.initState();
    if (widget.sources != null && widget.sources!.isNotEmpty) {
      _sources = List.of(widget.sources!);
    } else {
      _sources = [
        ImageViewerSource(
          url: widget.imageUrl,
          filePath: widget.filePath,
          bytes: widget.imageBytes,
          heroTag: widget.heroTag,
        ),
      ];
    }
    _current = widget.initialIndex.clamp(0, _sources.length - 1);
    _pageController = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  ImageViewerSource get _currentSource => _sources[_current];


                               
  Future<Uint8List?> _bytesFor(ImageViewerSource source) async {
    if (source.bytes != null) return source.bytes;
    if (source.filePath != null && File(source.filePath!).existsSync()) {
      return File(source.filePath!).readAsBytes();
    }
    if (source.url != null && source.url!.trim().isNotEmpty) {
      return BilibiliUserSpaceService.fetchBytes(source.url!);
    }
    return null;
  }

  Future<Uint8List?> get _currentBytes => _bytesFor(_currentSource);

                             
  Future<String> _getTempImagePath() async {
    if (_currentSource.filePath != null &&
        File(_currentSource.filePath!).existsSync()) {
      return _currentSource.filePath!;
    }
    final bytes = await _currentBytes;
    if (bytes == null) throw Exception('未找到图片数据');
    final dir = await getTemporaryDirectory();
    final ext = _currentSource.filePath?.isNotEmpty == true
        ? _currentSource.filePath!.split('.').last.toLowerCase()
        : 'png';
    final file = File(
      '${dir.path}/temp_viewer_image_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await file.writeAsBytes(bytes);
    return file.path;
  }


                                         
  void _showToast(String msg) {
    showAppToast(context, msg);
  }

              
  Future<void> _saveToGallery() async {
    try {
      _showToast(AppLocalizations.of(context).viewerSaving);
      final path = await _getTempImagePath();
      await Gal.putImage(path);
      if (!mounted) return;
      _showToast(AppLocalizations.of(context).viewerSaveSuccess);
    } catch (e) {
      if (!mounted) return;
      _showToast(AppLocalizations.of(context).viewerSaveFailed(e.toString()));
    }
  }

                              
  Future<void> _saveAllToGallery() async {
    final total = _sources.length;
    final progress = ValueNotifier<int>(0);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: ValueListenableBuilder<int>(
          valueListenable: progress,
          builder: (ctx, done, _) => AlertDialog(
            title: const Text('保存全部图片'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: total > 0 ? done / total : 0),
                const SizedBox(height: 12),
                Text('正在保存 $done / $total', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
    var saved = 0;
    for (var i = 0; i < _sources.length; i++) {
      try {
        final bytes = await _bytesFor(_sources[i]);
        if (bytes != null && bytes.isNotEmpty) {
          await Gal.putImageBytes(
            bytes,
            name: 'naviflash_${DateTime.now().millisecondsSinceEpoch}_$i',
          );
          saved++;
        }
      } catch (_) {
                           
      }
      progress.value = i + 1;
    }
    progress.dispose();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    _showToast(
      saved == 0
          ? AppLocalizations.of(context).viewerSaveFailed('未能读取图片数据')
          : '已保存 $saved/$total 张图片',
    );
  }

           
  Future<void> _shareImage() async {
    try {
      final path = await _getTempImagePath();
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: AppLocalizations.of(context).viewerShareImage,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showToast(AppLocalizations.of(context).viewerShareFailed(e.toString()));
    }
  }

                         
  Future<void> _copyToClipboard() async {
    try {
      _showToast(AppLocalizations.of(context).viewerCopying);
      final bytes = await _currentBytes;
      if (!mounted) return;
      if (bytes == null) {
        _showToast(AppLocalizations.of(context).viewerImageDataNotFound);
        return;
      }
      final success = await NativeBridge.copyImageToClipboard(bytes);
      if (!mounted) return;
      _showToast(
        success
            ? AppLocalizations.of(context).scanCopiedToClipboard
            : AppLocalizations.of(context).chatCopyFailed,
      );
    } catch (e) {
      if (!mounted) return;
      _showToast(AppLocalizations.of(context).viewerCopyFailed(e.toString()));
    }
  }

                              
  Future<void> _copyImageLink() async {
    final url = _currentSource.url;
    if (url == null || url.trim().isEmpty) {
      _showToast(AppLocalizations.of(context).viewerImageDataNotFound);
      return;
    }
    try {
      await Clipboard.setData(ClipboardData(text: url.trim()));
      if (!mounted) return;
      _showToast(AppLocalizations.of(context).scanCopiedToClipboard);
    } catch (e) {
      if (!mounted) return;
      _showToast(AppLocalizations.of(context).viewerCopyFailed(e.toString()));
    }
  }

               
  Future<void> _showBottomMenu() async {
    final l10n = AppLocalizations.of(context);
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      items: [
        NativeMenuItem(
          text: l10n.viewerSaveToAlbum,
          icon: Icons.save_alt,
          onTap: _saveToGallery,
        ),
        if (_sources.length > 1)
          NativeMenuItem(
            text: '保存全部图片',
            icon: Icons.collections,
            onTap: _saveAllToGallery,
          ),
        NativeMenuItem(
          text: l10n.viewerShareImage,
          icon: Icons.share,
          onTap: _shareImage,
        ),
        if (Platform.isWindows)
          NativeMenuItem(
            text: l10n.viewerCopyToClipboard,
            icon: Icons.copy,
            onTap: _copyToClipboard,
          ),
                         
        if (_currentSource.url != null &&
            _currentSource.url!.trim().isNotEmpty)
          NativeMenuItem(
            text: l10n.browserCopyLink,
            icon: Icons.link,
            onTap: _copyImageLink,
          ),
      ],
    );
    if (nativeOk || !mounted) return;
    showAppBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return GlassMenuSurface(
          radius: 16.0,
          blur: 12.0,
          stretch: 0.3,
          legacyClipRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
          legacyDecoration: BoxDecoration(
            color: const Color(0xFF212121).withValues(alpha: 0.85),
          ),
          content: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              ListTile(
                leading: const Icon(Icons.save_alt, color: Colors.white),
                title: Text(l10n.viewerSaveToAlbum,
                    style: const TextStyle(color: Colors.white)),
              onTap: () {
                  Navigator.pop(ctx);
                  _saveToGallery();
                },
              ),
              if (_sources.length > 1)
                ListTile(
                  leading: const Icon(Icons.collections, color: Colors.white),
                  title: const Text('保存全部图片',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _saveAllToGallery();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.white),
                title: Text(l10n.viewerShareImage,
                    style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareImage();
                },
              ),
              if (Platform.isWindows)
                ListTile(
                  leading: const Icon(Icons.copy, color: Colors.white),
                  title: Text(l10n.viewerCopyToClipboard,
                      style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _copyToClipboard();
                  },
                ),
                               
              if (_currentSource.url != null &&
                  _currentSource.url!.trim().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.link, color: Colors.white),
                  title: Text(l10n.browserCopyLink,
                      style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _copyImageLink();
                  },
                ),
              const Divider(color: Colors.white24, height: 1),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.white54),
                title: Text(l10n.commonCancel,
                    style: const TextStyle(color: Colors.white54)),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    Widget page = Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _sources.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              return _ZoomableImageView(
                source: _sources[index],
                                                    
                                                      
                                                   
                                                
                suppressHero: SettingsService.heroTransitionBlurEnabled,
                onTap: () => Navigator.of(context).maybePop(),
                onLongPress: _showBottomMenu,
              );
            },
          ),
          if (_sources.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${_current + 1}/${_sources.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
                                  
                                              
                                          
                                      
    final zoomHeroTag = _zoomHeroTag;
    if (zoomHeroTag != null) {
      page = Hero(
          transitionOnUserGestures: true,
        tag: zoomHeroTag,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        flightShuttleBuilder: imageZoomHeroFlightShuttle,
        child: page,
      );
    }
    return page;
  }
}

                          
class _ZoomableImageView extends StatefulWidget {
  final ImageViewerSource source;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

                                                  
  final bool suppressHero;

  const _ZoomableImageView({
    required this.source,
    required this.onTap,
    required this.onLongPress,
    this.suppressHero = false,
  });

  @override
  State<_ZoomableImageView> createState() => _ZoomableImageViewState();
}

class _ZoomableImageViewState extends State<_ZoomableImageView> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Widget _buildImage(BoxFit fit) {
    final l10n = AppLocalizations.of(context);
    final source = widget.source;
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    Widget? image;
    if (source.bytes != null) {
      image = Image.memory(
        source.bytes!,
        fit: fit,
                                      
                          
        cacheWidth: 2560,
        errorBuilder: (_, __, ___) =>
            _ImageErrorWidget(message: l10n.viewerImageLoadFailed),
      );
    } else if (source.filePath != null &&
        File(source.filePath!).existsSync()) {
      image = Image.file(
        File(source.filePath!),
        fit: fit,
                             
        cacheWidth: 2560,
        errorBuilder: (_, __, ___) =>
            _ImageErrorWidget(message: l10n.viewerImageLoadFailed),
      );
    } else if (source.url != null && source.url!.trim().isNotEmpty) {
      image = Image.network(
        source.url!,
        fit: fit,
        headers: headers,
        cacheWidth: 2560,
        errorBuilder: (_, __, ___) =>
            _ImageErrorWidget(message: l10n.viewerImageLoadFailed),
      );
    }
    if (image == null) {
      return _ImageErrorWidget(message: l10n.viewerImageDataNotFound);
    }
                                   
                                              
    final heroTag = source.heroTag;
    if (widget.suppressHero || heroTag == null) return image;
    return Hero(transitionOnUserGestures: true, tag: heroTag, child: image);
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 4.0,
      clipBehavior: Clip.none,
      child: Center(
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: _buildImage(BoxFit.contain),
        ),
      ),
    );
  }
}

class _ImageErrorWidget extends StatelessWidget {
  final String message;
  const _ImageErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, size: 60, color: Colors.white54),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
