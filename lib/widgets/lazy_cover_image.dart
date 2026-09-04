// lib/widgets/lazy_cover_image.dart
//
// 可视区懒加载封面组件（推荐页 / 直播 / 番剧 等长列表共用）：
//   - 视口门控：只有当控件进入「屏幕 + [preloadExtent] 缓冲带」时才真正发起
//     图片请求，滑到哪加载到哪，避免一次性把所有封面都拉下来吃带宽；
//   - 缩图下发：按卡片目标尺寸向 B 站 CDN 请求 @WxH_1c.webp 缩略图
//     （CDN 原生支持，原图动辄 1146×717，缩到 480 宽级可省 ~6~8 倍流量）；
//   - 骨架占位：未进入视口 / 解码完成前显示静默占位块，避免空白闪跳；
//   - 复用 CachedImageProvider 的三级缓存（内存→磁盘→网络），已加载过的
//     缩略图滚动回去不再重下。
//
// 缓存 key 仅由 URL 决定，所以即便同一个视频在推荐/热门两个 tab 各出现一次，
// 只要缩图 URL 一致就共享同一条缓存，不会重复下载。
import 'package:flutter/material.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';

/// 把 B 站原图 URL 转成 CDN 缩略图 URL（@WxH_1c.webp）。
///
/// [width]/[height] 为卡片 CSS 目标尺寸（逻辑像素）；二者不全时由 [aspect]
/// 反推，[aspect] 也没有时退化为以 [maxDimension] 为长边的方框。
/// 最终长边不超过 [maxDimension]，并按设备像素比放大以保证清晰，但绝不超出
/// 上限——这是省带宽的关键：1446×717 原图 → 480 宽缩图。
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
  // 已是缩图（含 @ 指令）或带查询参数时不再二次追加，原样返回。
  if (normalized.contains('@') || normalized.contains('?')) return normalized;

  double? tw = width;
  double? th = height;
  if (tw != null && th == null && aspect != null) th = tw / aspect;
  if (th != null && tw == null && aspect != null) tw = th * aspect;
  if (tw == null && th == null) {
    // 无尺寸信息（drop-in 撑满父容器场景）：用封面默认 16:9 推导缩图框，
    // 仍走缩图下发，避免原图直出吃带宽。
    final a = aspect ?? (16 / 9);
    if (a >= 1) {
      tw = maxDimension.toDouble();
      th = maxDimension / a;
    } else {
      th = maxDimension.toDouble();
      tw = maxDimension * a;
    }
  }
  if (tw == null || th == null) return normalized; // 无尺寸信息，用原图

  // 按设备像素比放大到真实像素，但长边封顶到 maxDimension，避免大屏浪费。
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

/// 可视区懒加载封面。
///
/// 两种用法：
///  1. 自描述尺寸（同原 [_coverImage]）：传 [width]/[height] 或 [aspect]，
///     内部用 SizedBox / AspectRatio 约束并显示骨架占位；
///  2. drop-in 撑满模式：三者都不传，则不自带尺寸约束，由父级
///     SizedBox / AspectRatio / ClipRRect 决定大小——可直接替换内联的
///     `Image(CachedImageProvider(url))`，布局零变化，仅叠加缩图 + 门控。
class LazyCoverImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final double? aspect;
  final BoxFit fit;
  /// 缩图长边上限（卡片 480 足够；轮播大图可给到 1280）。
  final int maxDimension;
  /// 进入视口前多少像素开始预加载（缓冲带，默认 400）。
  final double preloadExtent;
  /// 自定义请求头（不传则取 NetworkSettingsService 的 apiHeaders）。
  final Map<String, String>? headers;
  /// 自定义加载失败占位（不传则用默认灰色 + 影片 icon）。
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
    // 首帧后自检一次：若本就处在可视区（如首屏卡片），立即置为加载。
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
    // 依赖变化时（如切 tab 后重新挂载）再自检一次。
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    _position = null;
    super.dispose();
  }

  void _onScroll() => _check();

  /// 几何判定：控件全局矩形与「屏幕竖向区间 ± 缓冲带」是否相交。
  /// 一旦进入即永久置位（不回退，避免滚走再滚回重复触发与占位闪烁）。
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

    // 空 URL：直接给空态占位，永不发起请求。
    if (widget.url.isEmpty) {
      return _sized(placeholder, cs, withIcon: true);
    }

    // 未进入可视区：只显示骨架占位，不发任何网络请求（核心省带宽点）。
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
      // 下载 / 解码期间保持骨架占位，完成后才切到图片，避免空白闪跳。
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return placeholder;
      },
      errorBuilder: widget.errorBuilder ??
          (_, __, ___) => _placeholder(cs, withIcon: true),
    );

    return _sized(img, cs);
  }

  /// 按调用方意图约束尺寸：给定宽高用 SizedBox，给定 [aspect] 包 AspectRatio，
  /// 两者皆无则撑满父容器（drop-in 模式，由父级决定大小）。
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
    // 撑满父容器模式（drop-in 替换内联 Image）：不自带尺寸约束。
    return KeyedSubtree(key: _boxKey, child: inner);
  }
}
