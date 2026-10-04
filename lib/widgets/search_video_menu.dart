                                     
  
                                  
              
                          
                      
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassMenuItem;
import 'package:provider/provider.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bv_av.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:naviflash/services/bilibili_favorite_service.dart';
import 'package:naviflash/services/favorites_service.dart';
import 'package:naviflash/services/native_menu_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/fav_folder_picker.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/liquid_dom_menu.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/glass_menu_style.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

                                  
                                                       
                           
void showVideoContextMenu(
  BuildContext context, {
  required String bvid,
  String title = '',
  String cover = '',
  String author = '',
  Offset? globalPosition,
  bool showOriginal = false,
  ValueChanged<bool>? onToggleOriginal,
}) {
  final bv = bvid.trim();
  if (bv.isEmpty) return;
  final colorScheme = Theme.of(context).colorScheme;
  final screenSize = MediaQuery.of(context).size;
  const menuWidth = 220.0;
  VoidCallback? dismiss;
  final items = _buildVideoMenuItems(
    context,
    bvid: bv,
    title: title,
    cover: cover,
    author: author,
    closeMenu: () => dismiss?.call(),
    showOriginal: showOriginal,
    onToggleOriginal: onToggleOriginal,
  );
                           
  final menuHeight = items.length * 44.0 + (items.length - 1) * 1.0 + 12.0;
  showLiquidDomMenu(
    context,
    globalPosition:
        globalPosition ?? Offset(screenSize.width / 2, screenSize.height / 2),
    menuWidth: menuWidth,
    menuHeight: menuHeight,
    builder: (menuContext, close) {
      dismiss = close;
      return _buildLiquidVideoMenuContent(
        menuContext,
        colorScheme: colorScheme,
        items: items,
      );
    },
  );
}

                          
                                                       
                           
Future<void> showVideoBottomSheet(
  BuildContext context, {
  required String bvid,
  String title = '',
  String cover = '',
  String author = '',
  bool showOriginal = false,
  ValueChanged<bool>? onToggleOriginal,
}) async {
  final bv = bvid.trim();
  if (bv.isEmpty) return Future.value();
  final items = _buildVideoMenuItems(
    context,
    bvid: bv,
    title: title,
    cover: cover,
    author: author,
    closeMenu: () => Navigator.of(context).pop(),
    showOriginal: showOriginal,
    onToggleOriginal: onToggleOriginal,
  );
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final legacyBg = isDark
      ? cs.surfaceContainerHigh.withValues(alpha: 0.8)
      : cs.surfaceContainerLow.withValues(alpha: 0.85);
                                           
  PopupOverlayGuard.open();
  try {
    return await showAppBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
                                   
                                           
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: GlassMenuSurface(
          radius: 24.0,
          blur: 12.0,
                                          
                                        
                                
          tintOpacity: 0.12,
          lightIntensity: 0.2,
          stretch: 0.3,
          legacyClipRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          legacyDecoration: BoxDecoration(
            color: legacyBg,
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                         
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                                                        
                  if (cover.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Hero(
                            transitionOnUserGestures: true,
                          tag: 'bili_video_$bv',
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  cover,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade800,
                                    child: const Center(
                                      child: Icon(
                                        Icons.movie_outlined,
                                        color: Colors.white24,
                                      ),
                                    ),
                                  ),
                                ),
                                                 
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      28,
                                      12,
                                      10,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.65),
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (author.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            author,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  for (final item in items)
                                                
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: item.onTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                item.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  } finally {
    PopupOverlayGuard.close();
  }
}

                          
List<_MenuData> _buildVideoMenuItems(
  BuildContext context, {
  required String bvid,
  required String title,
  required String cover,
  required String author,
  required VoidCallback closeMenu,
  bool showOriginal = false,
  ValueChanged<bool>? onToggleOriginal,
}) {
  final bv = bvid.trim();
  final aid = BvAv.decode(bv);
  final favorites = context.read<FavoritesService>();
  final isFav = favorites.isFavorite(bv);
  return [
    _MenuData(
      icon: Icons.play_circle_outline,
      text: '应用内播放',
      onTap: () {
        closeMenu();
        openBilibiliVideo(
          context,
          bvid: bv,
          initialTitle: title,
          initialCover: cover,
        );
      },
    ),
    _MenuData(
      icon: Icons.copy_all_outlined,
      text: '复制BV号',
      onTap: () {
        closeMenu();
        _copy(context, bv);
      },
    ),
    if (aid != null)
      _MenuData(
        icon: Icons.tag_outlined,
        text: '复制AV号',
        onTap: () {
          closeMenu();
          _copy(context, 'av$aid');
        },
      ),
    _MenuData(
      icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      text: isFav ? '取消收藏' : '收藏到本地',
      onTap: () async {
        closeMenu();
        final added = await favorites.toggle(
          bvid: bv,
          aid: aid ?? 0,
          title: title,
          cover: cover,
          author: author,
        );
        if (!context.mounted) return;
        showAppToast(context, added ? '已收藏到本地收藏夹' : '已取消收藏');
      },
    ),
                                   
    if (aid != null && BilibiliFavoriteService.isLoggedIn)
      _MenuData(
        icon: Icons.bookmark_add_outlined,
        text: '加入B站收藏夹',
        onTap: () {
          closeMenu();
          showFavFolderPicker(context, aid: aid, title: title);
        },
      ),
                               
                                              
                                                    
                                    
                      
    if (BilibiliTitleCache.displayTitle(bv, title) != title &&
        title.isNotEmpty)
      _MenuData(
        icon: Icons.translate_outlined,
        text: showOriginal ? '查看译文' : '查看原文',
        onTap: () {
          closeMenu();
          onToggleOriginal?.call(!showOriginal);
        },
      ),
  ];
}

void _copy(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  showAppToast(context, '已复制 $text');
}

class _MenuData {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _MenuData({
    required this.icon,
    required this.text,
    required this.onTap,
  });
}

Widget _buildLiquidVideoMenuContent(
  BuildContext context, {
  required ColorScheme colorScheme,
  required List<_MenuData> items,
}) {
  return GlassMenu(
    colorScheme: colorScheme,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    children: [
      for (final item in items)
        GlassMenuRow(
          colorScheme: colorScheme,
          icon: item.icon,
          label: item.text,
          onTap: item.onTap,
        ),
    ],
  );
}


                   
class GlassMenuAction {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

                                   
                                                      
  final Widget? trailing;

                                
  final bool isDestructive;

                               
  final bool isEnabled;

  const GlassMenuAction({
    required this.icon,
    required this.text,
    required this.onTap,
    this.trailing,
    this.isDestructive = false,
    this.isEnabled = true,
  });
}

                                
   
                  
                                         
                                                     
                       
                                              
                            
List<NativeMenuItem>? nativeItemsOfActions(List<GlassMenuAction> actions) {
  final items = <NativeMenuItem>[];
  for (final action in actions) {
    var checked = false;
    final trailing = action.trailing;
    if (trailing != null) {
      if (trailing is Icon) {
        checked = trailing.icon == Icons.check;
      } else {
        return null;
      }
    }
    items.add(
      NativeMenuItem(
        text: action.text,
        icon: action.icon,
        checked: checked,
        destructive: action.isDestructive,
        enabled: action.isEnabled,
        onTap: action.onTap,
      ),
    );
  }
  return items;
}

                                              
   
                                              
                                                    
                            
Future<bool> tryShowNativeGlassMenu(
  BuildContext context, {
  required List<GlassMenuAction> actions,
  required Offset globalPosition,
  double menuWidth = 220,
}) async {
  if (actions.isEmpty) return false;
  final items = nativeItemsOfActions(actions);
  if (items == null) return false;
  return NativeMenuService.showMenu(
    context,
    items: items,
    position: globalPosition,
    width: menuWidth,
  );
}

                                     
                                                      
                                              
             
   
                                                       
                                                
             
   
                                    
                                                   
Future<void> showGlassDropdownMenu(
  BuildContext context, {
  required List<GlassMenuAction> actions,
  required Offset globalPosition,
  double menuWidth = 220,
  double menuRadius = 18.0,

                                    
                                   
  Size? originSize,

                                       
                                             
                                  
  bool scrollable = false,

                                            
  bool preferNative = true,

                  
  VoidCallback? onOpened,

                     
  VoidCallback? onOpenedComplete,

                  
  VoidCallback? onCloseStarted,

                           
  VoidCallback? onClosed,
}) async {
  if (actions.isEmpty) return;
  if (preferNative &&
      await tryShowNativeGlassMenu(
        context,
        actions: actions,
        globalPosition: globalPosition,
        menuWidth: menuWidth,
      )) {
    return;
  }
                                       
  if (!context.mounted) return;
  final brightness = Theme.of(context).brightness;
  showNaviGlassMenu(
    context,
    globalPosition: globalPosition,
    menuWidth: menuWidth,
                                                         
                                                
    menuHeight: null,
    menuRadius: menuRadius,
    onOpened: onOpened,
    onOpenedComplete: onOpenedComplete,
    onCloseStarted: onCloseStarted,
    onClosed: onClosed,
    itemsBuilder: (menuContext, close) => [
      for (final action in actions)
        buildGlassMenuItem(
          action,
          brightness,
          onTap: () {
            close();
            action.onTap();
          },
        ),
    ],
  );
}

                                                
                                                  
                                                        
                              
GlassMenuItem buildGlassMenuItem(
  GlassMenuAction action,
  Brightness brightness, {
  VoidCallback? onTap,
}) {
  final foreground = brightness == Brightness.dark
      ? const Color(0xFFE6E6E6)
      : const Color(0xFF1A1A1A);
  return GlassMenuItem(
    title: action.text,
    icon: Icon(action.icon),
    isDestructive: action.isDestructive,
    enabled: action.isEnabled,
    trailing: action.trailing,
    height: 44.0,
    iconSize: 18.0,
    titleStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: action.isDestructive ? null : foreground,
    ),
    onTap: onTap ?? action.onTap,
  );
}

                                                
                                        
   
                                                 
                                                  
Future<void> showFrostedActionSheet(
  BuildContext context, {
  String? cover,
  String? title,
  String? subtitle,
  required List<GlassMenuAction> actions,
}) async {
                                                  
                                      
  final nativeItems = nativeItemsOfActions(actions);
  if (nativeItems != null) {
    final sheetTitle = [
      if (title != null && title.trim().isNotEmpty) title.trim(),
      if (subtitle != null && subtitle.trim().isNotEmpty) subtitle.trim(),
    ].join(' · ');
    final nativeOk = await NativeMenuService.showMoreSheet(
      context,
      title: sheetTitle,
      items: nativeItems,
    );
    if (nativeOk || !context.mounted) return;
  }
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final menuBg = isDark
      ? cs.surfaceContainerHigh.withValues(alpha: 0.8)
      : cs.surfaceContainerLow.withValues(alpha: 0.85);
                                           
  PopupOverlayGuard.open();
  try {
    return await showAppBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
                                         
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: GlassMenuSurface(
          radius: 24.0,
          blur: 12.0,
          tintOpacity: 0.12,
          lightIntensity: 0.2,
          stretch: 0.3,
          legacyClipRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          legacyDecoration: BoxDecoration(
            color: menuBg,
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                         
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                             
                  if (cover != null && cover.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                cover,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade800,
                                  child: const Center(
                                    child: Icon(
                                      Icons.movie_outlined,
                                      color: Colors.white24,
                                    ),
                                  ),
                                ),
                              ),
                              if (title != null && title.isNotEmpty)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      28,
                                      12,
                                      10,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.65),
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (subtitle != null &&
                                            subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                        
                  for (final action in actions)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          action.onTap();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                action.icon,
                                size: 20,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                action.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  } finally {
    PopupOverlayGuard.close();
  }
}
