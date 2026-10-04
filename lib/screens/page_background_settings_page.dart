                                                 
  
                          
                         
                          
                                     
                    
            
                                           
                               
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class PageBackgroundSettingsPage extends StatefulWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const PageBackgroundSettingsPage({
    super.key,
    this.isSplitView = false,
    this.onBack,
  });

  @override
  State<PageBackgroundSettingsPage> createState() =>
      _PageBackgroundSettingsPageState();
}

class _PageBackgroundSettingsPageState
    extends State<PageBackgroundSettingsPage> {
  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

                          
                                                  
                 
  Future<void> _pickAndCrop({bool forContentPages = false}) async {
    final l10n = AppLocalizations.of(context);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      HapticFeedback.lightImpact();
      final cropped = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (_) => ImageCropPage(source: File(picked.path)),
        ),
      );
      if (cropped == null || !mounted) return;
      final service = context.read<SettingsService>();
      final ok = forContentPages
          ? await service.saveContentPageBackgroundImage(cropped)
          : await service.savePageBackgroundImage(cropped);
      if (!mounted) return;
      showAppToast(
        context,
        ok ? l10n.pageBgSaved : l10n.pageBgPickFailed,
        error: !ok,
      );
      setState(() {});
    } catch (e) {
      debugPrint('选择背景图失败: $e');
      if (mounted) {
        showAppToast(context, l10n.pageBgPickFailed, error: true);
      }
    }
  }

  Future<void> _clear({bool forContentPages = false}) async {
    final l10n = AppLocalizations.of(context);
    final service = context.read<SettingsService>();
    if (forContentPages) {
      await service.removeContentPageBackground();
    } else {
      await service.removePageBackground();
    }
    if (!mounted) return;
    showAppToast(context, l10n.pageBgCleared);
    setState(() {});
  }

                                          
  Widget _buildPreview(ColorScheme cs, SettingsService settings) {
    final l10n = AppLocalizations.of(context);
    final path = settings.pageBackgroundPath;
    final hasBg = path != null && path.isNotEmpty && File(path).existsSync();
    final opacity = settings.pageBackgroundOpacity.clamp(0.0, 1.0);
    final blur = settings.pageBackgroundBlur.clamp(0.0, 24.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(kGroupRadius),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: cs.surfaceContainerHigh,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasBg)
                Opacity(
                  opacity: opacity,
                  child: blur > 0.5
                      ? ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: blur,
                            sigmaY: blur,
                          ),
                          child: Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        )
                      : Image.file(
                          File(path),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                ),
              Center(
                child: Icon(
                  hasBg
                      ? Icons.image_outlined
                      : Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: cs.onSurfaceVariant.withValues(
                    alpha: hasBg ? 0 : 0.35,
                  ),
                ),
              ),
              if (!hasBg)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 56),
                    child: Text(
                      l10n.pageBgNotSet,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsService>();
    final path = settings.pageBackgroundPath;
    final hasBg = path != null && path.isNotEmpty && File(path).existsSync();
    final contentPath = settings.contentPageBackgroundPath;
    final hasContentBg =
        contentPath != null &&
        contentPath.isNotEmpty &&
        File(contentPath).existsSync();

    return PopScope(
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: cs.surfaceContainerLow,
        body: Stack(
          children: [
            PageBackground(baseColor: cs.surfaceContainerLow),
                                                          
                                       
            ScrollConfiguration(
              behavior: const MaterialScrollBehavior(),
              child: CustomScrollView(
                slivers: [
                  ExpressiveSliverAppBar(
                    title: l10n.pageBgTitle,
                    expandedHeight: 152,
                    leading: widget.isSplitView
                        ? null
                        : MorphIconButton(
                            tooltip: l10n.commonBackTooltip,
                            icon: Icons.arrow_back,
                            onTap: _handleBack,
                          ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                                     
                          _buildPreview(cs, settings),
                          const SizedBox(height: 16),
                          ...buildMorphSegmentedList([
                            MorphRowItem(
                              child: SwitchListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                secondary: Icon(
                                  Icons.wallpaper_outlined,
                                  size: 26,
                                  color: cs.onSurfaceVariant,
                                ),
                                title: Text(l10n.pageBgEnabled),
                                subtitle: Text(
                                  l10n.pageBgSubtitle,
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                                value: settings.pageBackgroundEnabled,
                                onChanged: hasBg
                                    ? (v) =>
                                          settings.setPageBackgroundEnabled(v)
                                    : null,
                              ),
                            ),
                            MorphRowItem(
                              child: _buildSliderTile(
                                cs,
                                icon: Icons.opacity_outlined,
                                title: l10n.pageBgOpacity,
                                value: settings.pageBackgroundOpacity,
                                min: 0.05,
                                max: 0.8,
                                display:
                                    '${(settings.pageBackgroundOpacity * 100).round()}%',
                                onChanged: settings.setPageBackgroundOpacity,
                              ),
                            ),
                            MorphRowItem(
                              child: _buildSliderTile(
                                cs,
                                icon: Icons.blur_on_outlined,
                                title: l10n.pageBgBlur,
                                value: settings.pageBackgroundBlur,
                                min: 0,
                                max: 20,
                                display:
                                    '${settings.pageBackgroundBlur.round()}',
                                onChanged: settings.setPageBackgroundBlur,
                              ),
                            ),
                            MorphRowItem(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: Icon(
                                  Icons.crop_outlined,
                                  size: 26,
                                  color: cs.onSurfaceVariant,
                                ),
                                title: Text(l10n.pageBgPick),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: cs.onSurfaceVariant,
                                ),
                                onTap: _pickAndCrop,
                              ),
                            ),
                            if (hasBg)
                              MorphRowItem(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: Icon(
                                    Icons.delete_outline,
                                    size: 26,
                                    color: cs.error,
                                  ),
                                  title: Text(
                                    l10n.pageBgClear,
                                    style: TextStyle(color: cs.error),
                                  ),
                                  onTap: _clear,
                                ),
                              ),
                          ]),
                          const SizedBox(height: 24),
                          Text(
                            l10n.pageBgContentSection,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                                                           
                          ...buildMorphSegmentedList([
                            MorphRowItem(
                              child: SwitchListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                secondary: Icon(
                                  Icons.photo_library_outlined,
                                  size: 26,
                                  color: cs.onSurfaceVariant,
                                ),
                                title: Text(l10n.pageBgContentEnabled),
                                subtitle: Text(
                                  l10n.pageBgContentSubtitle,
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                                value: settings.contentPageBackgroundEnabled,
                                onChanged: hasContentBg
                                    ? (v) => settings
                                        .setContentPageBackgroundEnabled(v)
                                    : null,
                              ),
                            ),
                            MorphRowItem(
                              child: _buildSliderTile(
                                cs,
                                icon: Icons.opacity_outlined,
                                title: l10n.pageBgContentOpacity,
                                value: settings.contentPageBackgroundOpacity,
                                min: 0.05,
                                max: 0.6,
                                display:
                                    '${(settings.contentPageBackgroundOpacity * 100).round()}%',
                                onChanged:
                                    settings.setContentPageBackgroundOpacity,
                              ),
                            ),
                            MorphRowItem(
                              child: _buildSliderTile(
                                cs,
                                icon: Icons.blur_on_outlined,
                                title: l10n.pageBgContentBlur,
                                value: settings.contentPageBackgroundBlur,
                                min: 0,
                                max: 20,
                                display:
                                    '${settings.contentPageBackgroundBlur.round()}',
                                onChanged: settings.setContentPageBackgroundBlur,
                              ),
                            ),
                                                         
                            MorphRowItem(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: Icon(
                                  Icons.crop_outlined,
                                  size: 26,
                                  color: cs.onSurfaceVariant,
                                ),
                                title: Text(l10n.pageBgContentPick),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: cs.onSurfaceVariant,
                                ),
                                onTap: () => _pickAndCrop(forContentPages: true),
                              ),
                            ),
                            if (hasContentBg)
                              MorphRowItem(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: Icon(
                                    Icons.delete_outline,
                                    size: 26,
                                    color: cs.error,
                                  ),
                                  title: Text(
                                    l10n.pageBgContentClear,
                                    style: TextStyle(color: cs.error),
                                  ),
                                  onTap: () =>
                                      _clear(forContentPages: true),
                                ),
                              ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderTile(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 26, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(fontSize: 15)),
                    ),
                    Text(
                      display,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

                                            
                             
                                            

class ImageCropPage extends StatefulWidget {
               
  final File source;

  const ImageCropPage({super.key, required this.source});

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  Uint8List? _bytes;
  img.Image? _srcImage;
  ui.Image? _uiImage;
  bool _error = false;
  bool _busy = false;

                                                
  double _scale = 1.0;
  Offset _offset = Offset.zero;

           
  double _gestureStartScale = 1.0;
  Offset _gestureStartOffset = Offset.zero;
  Offset _gestureStartFocal = Offset.zero;

                     
  double? _aspect;

                                                 
  Size _lastView = Size.zero;

  static const List<(String, double?)> _aspects = [
    ('自由', null),
    ('1:1', 1.0),
    ('4:3', 4 / 3),
    ('3:4', 3 / 4),
    ('16:9', 16 / 9),
    ('9:16', 9 / 16),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await widget.source.readAsBytes();
      final src = img.decodeImage(bytes);
      final uiImage = await decodeImageFromList(bytes);
      if (!mounted) return;
      if (src == null) {
        setState(() => _error = true);
        return;
      }
      setState(() {
        _bytes = bytes;
        _srcImage = src;
        _uiImage = uiImage;
      });
    } catch (e) {
      debugPrint('加载裁剪图片失败: $e');
      if (mounted) setState(() => _error = true);
    }
  }

  void _reset() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

                         
  Rect _windowRect(Size view) {
    final aspect = _aspect;
    if (aspect == null || aspect <= 0) {
      return Offset.zero & view;
    }
    const margin = 16.0;
    var w = view.width - margin * 2;
    var h = w / aspect;
    if (h > view.height - margin * 2) {
      h = view.height - margin * 2;
      w = h * aspect;
    }
    return Rect.fromCenter(
      center: view.center(Offset.zero),
      width: w,
      height: h,
    );
  }

                                       
  Future<void> _apply() async {
    final src = _srcImage;
    final bytes = _bytes;
    if (src == null || bytes == null || _busy) return;
    setState(() => _busy = true);
    try {
                                                   
      final view = _lastView;
      if (view.width <= 0 || view.height <= 0) {
        setState(() => _busy = false);
        return;
      }

      final fit = math.min(view.width / src.width, view.height / src.height);
      final imgCenter = Offset(src.width / 2, src.height / 2);
      final viewCenter = view.center(Offset.zero);

                              
      Offset toImage(Offset p) {
        final centered = p - viewCenter - _offset;
        return imgCenter + centered / (_scale * fit);
      }

      final window = _windowRect(view);
      var p1 = toImage(window.topLeft);
      var p2 = toImage(window.bottomRight);
      final left = p1.dx.clamp(0.0, src.width - 1.0);
      final top = p1.dy.clamp(0.0, src.height - 1.0);
      final right = p2.dx.clamp(left + 1.0, src.width.toDouble());
      final bottom = p2.dy.clamp(top + 1.0, src.height.toDouble());

      final cropped = img.copyCrop(
        src,
        x: left.round(),
        y: top.round(),
        width: math.max(1, right.round() - left.round()),
        height: math.max(1, bottom.round() - top.round()),
      );
      final outBytes = img.encodeJpg(cropped, quality: 90);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/navi_page_bg_crop_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(outBytes);
      if (mounted) Navigator.of(context).pop(file);
    } catch (e) {
      debugPrint('裁剪图片失败: $e');
      if (mounted) {
        setState(() => _busy = false);
        showAppToast(context, '裁剪失败', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
                                  
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              bottom: 4,
            ),
            child: Row(
              children: [
                const SizedBox(width: 4),
                MorphIconButton(
                  icon: Icons.arrow_back,
                  tooltip: l10n.commonBackTooltip,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.cropTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _apply,
                  child: Text(
                    l10n.cropApply,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
                      
          Expanded(
            child: _error
                ? Center(
                    child: Text(
                      '图片加载失败',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                : _uiImage == null
                ? const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final view = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      _lastView = view;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onScaleStart: (d) {
                          _gestureStartScale = _scale;
                          _gestureStartOffset = _offset;
                          _gestureStartFocal = d.localFocalPoint;
                        },
                        onScaleUpdate: (d) {
                          setState(() {
                            final newScale = (_gestureStartScale * d.scale)
                                .clamp(1.0, 8.0);
                            final viewCenter = view.center(Offset.zero);
                            final startCenter =
                                viewCenter + _gestureStartOffset;
                            final rel = _gestureStartFocal - startCenter;
                            final newCenter =
                                d.localFocalPoint -
                                rel * (newScale / _gestureStartScale);
                            _scale = newScale;
                            _offset = newCenter - viewCenter;
                          });
                        },
                        child: Stack(
                          children: [
                            Positioned.fill(child: _buildImageLayer(view)),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _CropOverlayPainter(
                                    rect: _windowRect(view),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
                               
          Container(
            color: const Color(0xFF1C1C1E),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final (label, aspect) in _aspects) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: _aspect == aspect,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: _aspect == aspect
                                  ? cs.onPrimaryContainer
                                  : Colors.white,
                            ),
                            selectedColor: cs.primaryContainer,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            onSelected: (_) => setState(() => _aspect = aspect),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(l10n.cropReset),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

                                        
  Widget _buildImageLayer(Size view) {
    final uiImage = _uiImage!;
    final fit = math.min(
      view.width / uiImage.width,
      view.height / uiImage.height,
    );
    final fitW = uiImage.width * fit;
    final fitH = uiImage.height * fit;
    return Center(
      child: Transform.translate(
        offset: _offset,
        child: Transform.scale(
          scale: _scale,
          child: SizedBox(
            width: fitW,
            height: fitH,
            child: RawImage(image: uiImage, fit: BoxFit.fill),
          ),
        ),
      ),
    );
  }
}

                            
class _CropOverlayPainter extends CustomPainter {
  final Rect rect;

  _CropOverlayPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
                          
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(rect);
    canvas.drawPath(path, dim);

           
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white;
    canvas.drawRect(rect, border);

          
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withValues(alpha: 0.4);
    for (var i = 1; i < 3; i++) {
      final x = rect.left + rect.width * i / 3;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), grid);
      final y = rect.top + rect.height * i / 3;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) =>
      oldDelegate.rect != rect;
}
