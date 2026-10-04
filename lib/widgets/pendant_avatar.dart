                                  
  
                                           
                                                
                                                       
                           
                                                     
import 'package:flutter/material.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';

class PendantAvatar extends StatelessWidget {
                   
  final double size;

                             
  final double pendOffset;

                                                      
  final String? avatarUrl;

                            
  final String? pendantUrl;

                          
  final Widget? fallback;

                        
  final Widget? badge;

                           
  final double ringWidth;

                  
  final Color ringColor;

                
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
