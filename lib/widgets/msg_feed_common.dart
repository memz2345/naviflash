                                   
  
                                        
                             
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';

import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/side_bar_menu_button.dart';

                                    
const double kMsgTopBarHeight = 56.0;

                                                        
                                     
                                            
                                                 
double msgTopInset({
  bool hideTitle = false,
  bool hasBottom = false,
  double bottomHeight = 44,
}) =>
    (hideTitle ? 0.0 : kMsgTopBarHeight) + (hasBottom ? bottomHeight : 0.0);

                            
class MsgPageScaffold extends StatelessWidget {
  final String title;

                                            
  final Widget? titleWidget;

                                                  
  final Widget? bottom;

                                       
  final double bottomHeight;

                           
  final bool showBack;

                                    
            
  final bool showTopBar;

                                          
                                   
  final bool hideTitle;

                                                          
                           
  final bool backdropScale;

                                         
                                      
  final Widget? drawer;

                                        
                         
  final Widget? leading;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final Widget child;

  const MsgPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.titleWidget,
    this.bottom,
    this.bottomHeight = 44,
    this.showBack = true,
    this.showTopBar = true,
    this.hideTitle = false,
    this.backdropScale = true,
    this.drawer,
    this.leading,
    this.actions = const [],
    this.floatingActionButton,
  });

                                         
  Widget _leadingButton(BuildContext context) {
    if (drawer != null) {
      return Builder(
        builder: (ctx) => SideBarMenuButton(
          tooltip: '侧边栏',
          onTap: () => Scaffold.of(ctx).openDrawer(),
        ),
      );
    }
    return MorphIconButton(
      icon: Icons.arrow_back,
      tooltip: AppLocalizations.of(context).commonBackTooltip,
      onTap: () => Navigator.of(context).maybePop(),
      transparent: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      drawer: drawer,
                                      
      onDrawerChanged: SideBarDrawerState.setOpen,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer, contentStyle: true),
          SafeArea(
            child: !showTopBar
                ? child
                : Stack(
                    children: [
                                                            
                                                      
                                                 
                                                                   
                      Positioned.fill(child: child),
                      Align(
                        alignment: Alignment.topCenter,
                        child: FrostedPanel(
                          opacity: 0.75,
                          child: SafeArea(
                            bottom: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!hideTitle)
                                  SizedBox(
                                    height: kMsgTopBarHeight,
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 8),
                                        leading ??
                                            (showBack
                                                ? _leadingButton(context)
                                                : const SizedBox(width: 4)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child:
                                              titleWidget ??
                                              Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                        ),
                                        ...actions,
                                        const SizedBox(width: 12),
                                      ],
                                    ),
                                  ),
                                if (bottom != null)
                                  SizedBox(
                                    height: bottomHeight,
                                                                
                                                     
                                    child: hideTitle && showBack
                                        ? Row(
                                            children: [
                                              const SizedBox(width: 6),
                                              leading ?? _leadingButton(context),
                                              const SizedBox(width: 2),
                                              Expanded(child: bottom!),
                                            ],
                                          )
                                        : bottom,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
    return backdropScale ? IosBackdropScale(child: scaffold) : scaffold;
  }
}

                                                               
   
                                              
                                                 
                                                         
                                           
String formatMsgTime(int ts) {
  if (ts <= 0) return '';
  var seconds = ts;
  if (seconds > 100000000000000000) {
    seconds ~/= 1000000000;      
  } else if (seconds > 100000000000000) {
    seconds ~/= 1000000;      
  } else if (seconds > 100000000000) {
    seconds ~/= 1000;      
  }
  final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  final now = DateTime.now();
  final diff = now.difference(dt);
  String two(int n) => n.toString().padLeft(2, '0');
  if (diff.inMinutes < 1 && diff.inSeconds >= 0) {
    return L10n.current.msgTimeJustNow;
  }
  if (diff.inHours < 1 && diff.inMinutes >= 0) {
    return L10n.current.msgTimeMinutesAgo(diff.inMinutes);
  }
  final sameDay =
      dt.year == now.year && dt.month == now.month && dt.day == now.day;
  if (sameDay) return '${two(dt.hour)}:${two(dt.minute)}';
  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday =
      dt.year == yesterday.year &&
      dt.month == yesterday.month &&
      dt.day == yesterday.day;
  if (isYesterday) {
    return L10n.current.msgTimeYesterday('${two(dt.hour)}:${two(dt.minute)}');
  }
  if (dt.year == now.year) return '${two(dt.month)}-${two(dt.day)}';
  return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
}

                                                  
String formatMsgTimeText(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '';
  final parsed = DateTime.tryParse(t);
  if (parsed == null) return t;
  return formatMsgTime(parsed.millisecondsSinceEpoch ~/ 1000);
}

                                   
class MsgAvatar extends StatelessWidget {
  final String url;
  final int mid;
  final double size;

  const MsgAvatar({super.key, required this.url, this.mid = 0, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    final child = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? _fallback(cs)
            : Image(
                image: CachedImageProvider(
                  BilibiliUserSpaceService.avatarUrl(url),
                  headers: headers,
                ),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(cs),
              ),
      ),
    );
    if (mid <= 0) return child;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BilibiliUserSpacePage(mid: mid)),
      ),
      child: child,
    );
  }

  Widget _fallback(ColorScheme cs) => Container(
    color: cs.surfaceContainerHighest,
    child: Icon(
      Icons.person_outline,
      size: size * 0.5,
      color: cs.onSurfaceVariant,
    ),
  );
}

                       
class MsgUnreadBadge extends StatelessWidget {
  final int count;
  final double minSize;

  const MsgUnreadBadge({super.key, required this.count, this.minSize = 18});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: cs.error,
        borderRadius: BorderRadius.circular(minSize),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          fontSize: 10,
          height: 1.1,
          fontWeight: FontWeight.w600,
          color: cs.onError,
        ),
      ),
    );
  }
}

                         
class MsgEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const MsgEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

                           
void pushMsgLogin(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const BilibiliLoginScreen()));
}

                       
class MsgLoginPrompt extends StatelessWidget {
  final IconData icon;
  final String title;

  const MsgLoginPrompt({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => pushMsgLogin(context),
            child: Text(AppLocalizations.of(context).msgGoLogin),
          ),
        ],
      ),
    );
  }
}
