// lib/widgets/pendant_avatar.dart
//
// lib/common/widgets/pendant_avatar.dart）：
//   - 挂件模式下头像略微缩小（-pendOffset），挂件图放大到头像的 1.75 倍
//     居中叠在头像上方（顶部超出容器，用 Stack(clipBehavior: none) 承接）；
//   - 右下角可叠加徽标（大会员 SVG 等）；
//   - 头像用项目自建 CachedImageProvider（内存 → 磁盘 → 网络三级缓存）。
import 'package:flutter/material.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';

class PendantAvatar extends StatelessWidget {
  /// 输出总尺寸（含挂件外延）。
  final double size;

  /// 挂件模式下头像缩小的量（越大挂件越向外凸出）。
  final double pendOffset;

  /// 头像地址（建议已带 @96w_96h_1c.webp 压缩）。为空时显示 [fallback]。
  final String? avatarUrl;

  /// 粉丝装扮挂件图地址（未佩戴时为空串/不传）。
  final String? pendantUrl;

  /// 头像占位（无地址 / 加载失败时显示）。
  final Widget? fallback;

  /// 头像右下角徽标（如大会员 SVG）。
  final Widget? badge;

  /// 无挂件时头像的描边宽度（0 = 不描边）。
  final double ringWidth;

  /// 无挂件时头像的描边颜色。
  final Color ringColor;

  /// 无挂件时头像的阴影。
  final List<BoxShadow>? shadow;

  final VoidCallback? onTap;

  const PendantAvatar({
    super.key,
    required this.size,
    this.pendOffset = 6,
    this.avatarUrl,
    this.pendantUrl,
    this.fallback,
    this.badge,
    this.ringWidth = 0,
    this.ringColor = Colors.white,
    this.shadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = avatarUrl ?? '';
    final pendant = pendantUrl ?? '';
    final showPendant = pendant.isNotEmpty;
    final avatarSize = showPendant ? size - pendOffset : size;

    // ── 1. 头像（圆形裁剪 + 图片/占位） ──
    Widget avatar = ClipOval(
      child: Container(
        width: avatarSize,
        height: avatarSize,
        color: cs.surfaceContainerHighest,
        child: url.isEmpty
            ? Center(child: fallback ?? const SizedBox.shrink())
            : Image(
                image: CachedImageProvider(
                  url,
                  headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                      ? null
                      : NetworkSettingsService.instance.apiHeaders,
                ),
                width: avatarSize,
                height: avatarSize,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Center(child: fallback ?? const SizedBox.shrink()),
              ),
      ),
    );

    if (!showPendant && ringWidth > 0) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: ringWidth),
          boxShadow: shadow,
        ),
        child: avatar,
      );
    }

    // ── 3. 右下角徽标（始终贴着头像角，不受挂件外延影响） ──
    if (badge != null) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(right: -2, bottom: -2, child: badge!),
        ],
      );
    }

    if (showPendant) {
      final pendantSize = avatarSize * 1.75;
      avatar = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          avatar,
          Positioned(
            top: -0.375 * avatarSize + pendOffset / 2,
            child: IgnorePointer(
              child: Image(
                image: CachedImageProvider(
                  pendant,
                  headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                      ? null
                      : NetworkSettingsService.instance.apiHeaders,
                ),
                width: pendantSize,
                height: pendantSize,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      );
      avatar = SizedBox.square(dimension: size, child: avatar);
    }

    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: avatar,
      );
    }
    return avatar;
  }
}
