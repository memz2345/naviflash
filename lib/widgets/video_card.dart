                              
  
                                                   
                                                    
                                                       
  
                                      
                                    
                                         

import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/metro_tile.dart';
import 'package:naviflash/widgets/liquid_glass.dart';

                                           
                    
                                           

                 
   
                                            
                                    
@immutable
class VideoCardData {
  const VideoCardData({
    required this.cover,
    required this.title,
    this.heroTag,
    this.titleSpan,
    this.view,
    this.viewText,
    this.danmaku,
    this.duration = 0,
    this.durationText,
    this.badge,
    this.reason,
    this.ownerName = '',
    this.pubdate = 0,
    this.subtitle,
    this.subtitleTrailing,
    this.coverWidget,
    this.coverOverlay,
    this.progress,
    this.coverAspect = 16 / 10,
  });

                      
  final String cover;

                                         
  final String title;
  final TextSpan? titleSpan;

                                     
  final String? heroTag;

                                
                                  
  final int? view;

                             
  final String? viewText;

                             
  final int? danmaku;

                             
  final int duration;

                                         
  final String? durationText;

                              
  final String? badge;

                        
  final String? reason;

                         
  final String ownerName;

                                            
  final int pubdate;

                                                  
  final String? subtitle;

                             
  final Widget? subtitleTrailing;

                                            
                                 
  final Widget? coverWidget;

                            
  final Widget? coverOverlay;

                                   
  final double? progress;

                                    
                                
  final double coverAspect;

                          
  String? get badgeDurationText {
    if (durationText != null && durationText!.isNotEmpty) return durationText;
    if (duration > 0) return formatCardDuration(duration);
    return null;
  }

                        
  String? badgeViewText([AppLocalizations? l10n]) {
    if (viewText != null && viewText!.isNotEmpty) return viewText;
                                               
    if (view != null && view! > 0) return formatCardCount(view!, l10n);
    return null;
  }
}

                                           
                  
                                           

String formatCardCount(int n, [AppLocalizations? l10n]) {
  if (n >= 100000000) {
    return (l10n != null)
        ? l10n.countYi((n / 100000000).toStringAsFixed(1))
        : '${(n / 100000000).toStringAsFixed(1)} 亿';
  }
  if (n >= 10000) {
    return (l10n != null)
        ? l10n.countWan((n / 10000).toStringAsFixed(1))
        : '${(n / 10000).toStringAsFixed(1)} 万';
  }
  return '$n';
}

String formatCardDuration(int sec) {
  String two(int n) => n.toString().padLeft(2, '0');
  final m = sec ~/ 60;
  final s = sec % 60;
  return m >= 60 ? '${m ~/ 60}:${two(m % 60)}:${two(s)}' : '$m:${two(s)}';
}

String formatCardAgo(int ts, AppLocalizations l10n) {
  if (ts <= 0) return '';
  final diff = DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(ts * 1000),
  );
  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
  if (diff.inDays < 30) return l10n.timeDaysAgo(diff.inDays);
  final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

                                           
                 
                                           

                                              
                                 
class VideoCardV extends StatelessWidget {
  const VideoCardV({
    super.key,
    required this.data,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
  });

  final VideoCardData data;

                    
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<Offset>? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final glassOn = SettingsService.videoCardGlassEnabled;
    final card = Material(
                                       
                                     
      color: glassOn ? Colors.transparent : cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTapDown: onSecondaryTap == null
            ? null
            : (details) => onSecondaryTap!(details.globalPosition),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: data.coverAspect,
              child: _CardCover(data: data, withHero: true),
            ),
            Expanded(
              child: _infoGlass(
                context,
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardTitle(data: data),
                      const Spacer(),
                      if (data.reason != null && data.reason!.isNotEmpty) ...[
                        Text(
                          data.reason!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: cs.primary),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _subtitleOf(l10n),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (data.subtitleTrailing != null)
                            data.subtitleTrailing!,
                          if (data.danmaku != null && data.danmaku! > 0) ...[
                            Icon(
                              Icons.subtitles_outlined,
                              size: 12,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              formatCardCount(data.danmaku!, l10n),
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
                                               
                                          
    final heroTag = data.heroTag;
    if (heroTag != null && SettingsService.heroTransitionBlurEnabled) {
      return _metro(
        Hero(
            transitionOnUserGestures: true,
          tag: heroTag,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
          child: card,
        ),
      );
    }
    return _metro(card);
  }

  String _subtitleOf(AppLocalizations l10n) {
    final override = data.subtitle;
    if (override != null) return override;
    final ago = formatCardAgo(data.pubdate, l10n);
    final owner = data.ownerName;
    if (ago.isEmpty) return owner;
    if (owner.isEmpty) return ago;
    return '$ago  $owner';
  }
}

                                           
                
                                           

                                          
                        
class VideoCardH extends StatelessWidget {
  const VideoCardH({
    super.key,
    required this.data,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,

                                     
                                 
    this.coverBadges = false,

                                         
                            
    this.statsTrailing,

                                  
                            
    this.trailing,
  });

  final VideoCardData data;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<Offset>? onSecondaryTap;
  final bool coverBadges;
  final Widget? statsTrailing;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final thumb = _CardCover(
      data: data,
      withHero: true,
      width: 148,
      height: 84,
      badges: coverBadges,
    );
    final glassOn = SettingsService.videoCardGlassEnabled;
    final card = Material(
                                       
                                     
      color: glassOn ? Colors.transparent : cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTapDown: onSecondaryTap == null
            ? null
            : (details) => onSecondaryTap!(details.globalPosition),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              thumb,
              const SizedBox(width: 12),
              Expanded(
                child: _infoGlass(
                  context,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CardTitle(data: data),
                      if (data.reason != null && data.reason!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          data.reason!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: cs.primary),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _subtitleOf(l10n),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (data.subtitleTrailing != null)
                            data.subtitleTrailing!,
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (data.view != null || data.viewText != null) ...[
                            Icon(
                              Icons.play_arrow_rounded,
                              size: 13,
                              color: cs.onSurfaceVariant,
                            ),
                            Text(
                              data.viewText ??
                                  formatCardCount(data.view ?? 0, l10n),
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (data.danmaku != null) ...[
                            const SizedBox(width: 10),
                            Icon(
                              Icons.subtitles_outlined,
                              size: 13,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              formatCardCount(data.danmaku!, l10n),
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (statsTrailing != null) ...[
                            const Spacer(),
                            statsTrailing!,
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
    final heroTag = data.heroTag;
    if (heroTag != null && SettingsService.heroTransitionBlurEnabled) {
      return _metro(
        Hero(
            transitionOnUserGestures: true,
          tag: heroTag,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
          child: card,
        ),
      );
    }
    return _metro(card);
  }

  String _subtitleOf(AppLocalizations l10n) {
    final override = data.subtitle;
    if (override != null) return override;
    final ago = formatCardAgo(data.pubdate, l10n);
    final owner = data.ownerName;
    if (ago.isEmpty) return owner;
    if (owner.isEmpty) return ago;
    return '$ago  $owner';
  }
}

                                           
        
                                           

                                    
                                             
Widget _metro(Widget child) => MetroTileInteraction(
  onTapStart: (_, __) {},
  showBorder: false,
  pressScale: 1.0,
  child: child,
);

                                    
                                   
                                                  
                                             
                                                            
           
                                      
                           
   
                                   
                                       
Widget videoCardInfoGlass(BuildContext context, Widget child) {
  if (!SettingsService.videoCardGlassEnabled) return child;
  return GlassContainer(
    useOwnLayer: true,
                                 
    settings: buildNaviGlassSettings(
      blur: 12,
      lightIntensity: 0.2,
      tintOpacity: 0,
    ),
    quality: naviGlassAdvanced
        ? GlassQuality.premium
        : GlassQuality.minimal,
    shape: LiquidRoundedRectangle(borderRadius: 0),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

Widget _infoGlass(BuildContext context, Widget child) =>
    videoCardInfoGlass(context, child);

                             
                                           
                                              
                                     
class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.data});

  final VideoCardData data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = TextStyle(
      fontSize: 13,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: cs.onSurface,
    );
    final span = data.titleSpan;
    if (span != null) {
      return Text.rich(
        span,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: base,
      );
    }
    return Text(
      data.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: base,
    );
  }
}

                                              
                                               
class _CardCover extends StatelessWidget {
  const _CardCover({
    required this.data,
    this.withHero = false,
    this.width,
    this.height,

                                       
                                             
                           
    this.badges = true,
  });

  final VideoCardData data;
  final bool withHero;
  final double? width;
  final double? height;
  final bool badges;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final viewText = badges ? data.badgeViewText(l10n) : null;
    final durationText = badges ? data.badgeDurationText : null;

    Widget cover = data.coverWidget ?? _defaultCover(cs);
    final heroTag = data.heroTag;
    if (withHero &&
        heroTag != null &&
        !SettingsService.heroTransitionBlurEnabled) {
      cover = Hero(
          transitionOnUserGestures: true,
        tag: heroTag,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: cover,
      );
    }

    final stack = Stack(
      fit: StackFit.expand,
      children: [
        cover,
                             
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 36,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),
        if (badges && data.badge != null && data.badge!.isNotEmpty)
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFB7299),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                data.badge!,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
        if (viewText != null)
          Positioned(
            left: 8,
            bottom: 6,
            child: Row(
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                Text(
                  viewText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        if (durationText != null)
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                durationText,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
        if (data.progress != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LinearProgressIndicator(
              value: data.progress!.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: Colors.black38,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
        if (data.coverOverlay != null)
          Positioned.fill(child: data.coverOverlay!),
      ],
    );

    if (width != null && height != null) {
      return SizedBox(width: width, height: height, child: stack);
    }
    return stack;
  }

  Widget _defaultCover(ColorScheme cs) {
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    final placeholder = Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: Icon(Icons.movie_outlined, color: Colors.white24),
      ),
    );
    if (data.cover.isEmpty) return placeholder;
    return Image(
      image: CachedImageProvider(data.cover, headers: headers),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}
