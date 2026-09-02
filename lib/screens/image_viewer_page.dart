// lib/screens/image_viewer_page.dart
//
// 图片查看器（支持单图/多图）：
//   - 来源：本地文件 / 内存字节 / 网络图片（url）
//   - 多图：PageView 左右滑动切换 + 页码角标
//   - 缩放/平移：InteractiveViewer（每个页面独立状态）
//   - Hero 动画：每个来源可携带 heroTag，源页面用同名 Hero 即可飞入
//   - 点按关闭；长按弹出 保存/分享/复制 菜单（网络图自动下载后再操作）
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:gal/gal.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/bilibili_user_space_service.dart';
import '../services/lnative_bridge.dart';
import '../services/network_settings_service.dart';
import '../l10n/app_localizations.dart';

/// 单个查看来源。
class ImageViewerSource {
  /// 网络图片地址。
  final String? url;

  /// 本地文件路径。
  final String? filePath;

  /// 内存图片字节。
  final Uint8List? bytes;

  /// 该图的 Hero 标签（源页面同名 Hero 触发飞入动画）。
  final String? heroTag;

  const ImageViewerSource({this.url, this.filePath, this.bytes, this.heroTag});
}

class ImageViewerPage extends StatefulWidget {
  // ── 单图（向后兼容：本地文件 / 内存字节 / 网络图）──

  final String? filePath;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final String? heroTag;

  // ── 多图 ──

  /// 多图来源列表（提供时优先于上面的单图参数）。
  final List<ImageViewerSource>? sources;

  /// 初始展示的图片下标。
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
  /// 归一化后的来源列表（由单图参数或多图列表构建）。
  late final List<ImageViewerSource> _sources;
  late final PageController _pageController;
  late int _current;

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


  /// 获取当前图片的字节（网络图自动下载，带本地缓存）。
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

  /// 获取当前图片的本地临时路径（用于分享和保存）。
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


  /// 跨平台 Toast 提示
  void _showToast(String msg) {
    if (Platform.isAndroid) {
      NativeBridge.showToast(msg); // 安卓端使用原生 Toast
    } else {
      // Windows/其他平台使用 SnackBar
      showAppToast(context, msg);
    }
  }

  /// 保存当前图到相册
  Future<void> _saveToGallery() async {
    try {
      _showToast(AppLocalizations.of(context).viewerSaving);
      final path = await _getTempImagePath();
      await Gal.putImage(path);
      _showToast(AppLocalizations.of(context).viewerSaveSuccess);
    } catch (e) {
      _showToast(AppLocalizations.of(context).viewerSaveFailed(e.toString()));
    }
  }

  /// 分享当前图
  Future<void> _shareImage() async {
    try {
      final path = await _getTempImagePath();
      await Share.shareXFiles(
        [XFile(path)],
        text: AppLocalizations.of(context).viewerShareImage,
      );
    } catch (e) {
      _showToast(AppLocalizations.of(context).viewerShareFailed(e.toString()));
    }
  }

  /// 复制当前图到剪贴板 (Windows)
  Future<void> _copyToClipboard() async {
    try {
      _showToast(AppLocalizations.of(context).viewerCopying);
      final bytes = await _currentBytes;
      if (bytes == null) {
        _showToast(AppLocalizations.of(context).viewerImageDataNotFound);
        return;
      }
      final success = await NativeBridge.copyImageToClipboard(bytes);
      _showToast(
        success
            ? AppLocalizations.of(context).scanCopiedToClipboard
            : AppLocalizations.of(context).chatCopyFailed,
      );
    } catch (e) {
      _showToast(AppLocalizations.of(context).viewerCopyFailed(e.toString()));
    }
  }

  /// 复制当前图片链接（仅远程加载的图片有 URL）。
  Future<void> _copyImageLink() async {
    final url = _currentSource.url;
    if (url == null || url.trim().isEmpty) {
      _showToast(AppLocalizations.of(context).viewerImageDataNotFound);
      return;
    }
    try {
      await Clipboard.setData(ClipboardData(text: url.trim()));
      _showToast(AppLocalizations.of(context).scanCopiedToClipboard);
    } catch (e) {
      _showToast(AppLocalizations.of(context).viewerCopyFailed(e.toString()));
    }
  }

  /// 长按弹出的底部菜单
  void _showBottomMenu() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
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
              // 复制链接（仅远程加载的图片）
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
    final multiple = _sources.length > 1;
    return Scaffold(
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
                onTap: () => Navigator.of(context).maybePop(),
                onLongPress: _showBottomMenu,
              );
            },
          ),
          if (multiple)
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
  }
}

/// 单页图片：缩放 + 点按关闭 + 长按菜单。
class _ZoomableImageView extends StatefulWidget {
  final ImageViewerSource source;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ZoomableImageView({
    required this.source,
    required this.onTap,
    required this.onLongPress,
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
        errorBuilder: (_, __, ___) =>
            _ImageErrorWidget(message: l10n.viewerImageLoadFailed),
      );
    } else if (source.filePath != null &&
        File(source.filePath!).existsSync()) {
      image = Image.file(
        File(source.filePath!),
        fit: fit,
//  限制解码尺寸，避免超大图片全尺寸解码 OOM 闪退
        cacheWidth: 1920,
        errorBuilder: (_, __, ___) =>
            _ImageErrorWidget(message: l10n.viewerImageLoadFailed),
      );
    } else if (source.url != null && source.url!.trim().isNotEmpty) {
      image = Image.network(
        source.url!,
        fit: fit,
        headers: headers,
        errorBuilder: (_, __, ___) =>
            _ImageErrorWidget(message: l10n.viewerImageLoadFailed),
      );
    }
    if (image == null) {
      return _ImageErrorWidget(message: l10n.viewerImageDataNotFound);
    }
    // Hero 动画：带 heroTag 的页面包裹 Hero（多图时每页独立 tag，无冲突）
    final heroTag = source.heroTag;
    return heroTag != null ? Hero(tag: heroTag, child: image) : image;
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
