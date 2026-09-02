// lib/widgets/long_press_image_preview.dart
//
//   - 长按 [child]（缩略图）弹出预览：大图居中展示，背景为原图高斯模糊
//     + 深色遮罩，松手自动收起（点按预览也可关闭）
//   - 飞入/飞回动画：缩略图从原始位置放大飞到屏幕中央（等效 Hero 效果）
//   - 支持网络图（[imageUrl]）与内存图（[imageBytes]）两种来源
//
// 实现说明：预览用 OverlayEntry 插入根 Overlay，而不是 Navigator 路由——
// Navigator 每次路由切换都会调用 _cancelActivePointers() 取消所有进行中的
// 指针手势（navigator.dart 的 _afterNavigation），长按手势会被掐断且松手
// 事件丢失；Overlay 插入不会影响手势，从而保证「长按 → 预览 → 松手返回」
// 的完整手势闭环。
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/widgets/morph_card.dart';

/// 长按预览图片。用 [child] 包住任意缩略图组件即可获得
/// 「长按放大预览、松手返回」能力，并带有飞入/飞回动画。
///
/// [imageUrl] 与 [imageBytes] 至少提供一个（均提供时优先网络图）。
class LongPressImagePreview extends StatefulWidget {
  final Widget child;
  final String? imageUrl;
  final Uint8List? imageBytes;
  /// 圆角：默认与 Material 3 / morph 设计统一的大圆角（kGroupRadius = 16）。
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
    // 缩略图在屏幕上的全局矩形（飞行动画的起点）
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

// ═════════════════════════════════════════
//  预览浮层：模糊背景 + 居中大图 + 飞入/飞回动画
// ═════════════════════════════════════════

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
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.flightDuration,
    reverseDuration: widget.dismissDuration,
  );

  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    // 下一帧再启动动画，确保首帧定位在缩略图位置
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

  /// 居中目标矩形（大图展示区域，图内按 contain 适配）。
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
          // 背景模糊/遮罩快速淡入淡出
          final bgOpacity = (_controller.status == AnimationStatus.reverse
                  ? _controller.value
                  : _controller.value * 4)
              .clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── 背景：纯背景模糊 ──
              // BackdropFilter 直接模糊 overlay 下方的页面内容（背后的真实
              // 界面），而非把预览图本身糊在背景上（避免「图后有图」）。
              Opacity(
                opacity: bgOpacity,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
              // ── 深色遮罩 ──
              Opacity(
                opacity: bgOpacity * 0.62,
                child: const ColoredBox(color: Colors.black),
              ),
              // ── 飞入/飞出的图片 ──
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
