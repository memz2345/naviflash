                                        
  
                
                                                      
                                             
                      
                                                        
                                            
                                
  
                                                                
                                                         
                                         
                                     
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/app_tooltip.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart' show MorphIconButton;

                                                      
class SideBarDrawerState {
  SideBarDrawerState._();

               
  static final ValueNotifier<bool> open = ValueNotifier<bool>(false);

  static void setOpen(bool value) {
    if (open.value != value) open.value = value;
  }
}

                                      
                                                            
const Duration kSideBarMenuTurnDuration = Duration(milliseconds: 246);

                                 
class SideBarMenuButton extends StatefulWidget {
                                                        
  final VoidCallback onTap;
  final String? tooltip;
  final double size;
  final double iconSize;

                                            
  final bool transparent;

                                                    
  final bool frosted;
  final Color? iconColor;

  const SideBarMenuButton({
    super.key,
    required this.onTap,
    this.tooltip,
    this.size = 40.0,
    this.iconSize = 22.0,
    this.transparent = true,
    this.frosted = false,
    this.iconColor,
  });

  @override
  State<SideBarMenuButton> createState() => _SideBarMenuButtonState();
}

class _SideBarMenuButtonState extends State<SideBarMenuButton>
    with SingleTickerProviderStateMixin {
                                             
                                               
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: kSideBarMenuTurnDuration,
    );
    SideBarDrawerState.open.addListener(_onDrawerStateChanged);
                                  
    _onDrawerStateChanged();
  }

  void _onDrawerStateChanged() {
    if (!mounted) return;
    if (SideBarDrawerState.open.value) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    SideBarDrawerState.open.removeListener(_onDrawerStateChanged);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
                                           
                                           
                                 
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) =>
          Transform.rotate(angle: math.pi / 2 * _ctrl.value, child: child),
      child: MorphIconButton(
        icon: Icons.menu,
        tooltip: widget.tooltip,
        size: widget.size,
        iconSize: widget.iconSize,
        transparent: widget.transparent,
        frosted: widget.frosted,
        iconColor: widget.iconColor,
        onTap: widget.onTap,
      ),
    );
  }
}

                 
   
                            
                                           
                
                                                    
                                          
class SideBarEntryButton extends StatelessWidget {
  final VoidCallback onTap;

                          
  final Animation<double>? menuRotation;

  const SideBarEntryButton({
    super.key,
    required this.onTap,
    this.menuRotation,
  });

                                        
  Widget _buildMenuIcon(Color color, {required double size}) {
    final icon = Icon(Icons.menu, size: size, color: color);
    final rotation = menuRotation;
    if (rotation == null) return icon;
    return AnimatedBuilder(
      animation: rotation,
      builder: (context, child) => Transform.rotate(
        angle: math.pi / 2 * rotation.value,
        child: child,
      ),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: BilibiliAccountService.instance,
      builder: (context, _) {
        final account = BilibiliAccountService.instance;
        final logged = account.isLoggedIn;
        final avatarUrl = account.avatarUrl;
        final iconColor = cs.onSurface;
        return AppTooltip(
          message: logged && account.uname.isNotEmpty ? account.uname : '侧边栏',
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              customBorder: const StadiumBorder(),
              splashColor: cs.primary.withValues(alpha: 0.14),
              highlightColor: cs.primary.withValues(alpha: 0.06),
              child: logged
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                                                   
                        ClipRect(
                          child: SizedBox(
                            width: 15,
                            height: 40,
                            child: _buildMenuIcon(iconColor, size: 20),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cs.outlineVariant.withValues(
                                  alpha: 0.65,
                                ),
                                width: 1.2,
                              ),
                            ),
                            child: ClipOval(
                              child: SizedBox(
                                width: 34,
                                height: 34,
                                child: avatarUrl.isNotEmpty
                                    ? Image(
                                        image: CachedImageProvider(
                                          avatarUrl,
                                          headers:
                                              NetworkSettingsService
                                                  .instance
                                                  .apiHeaders
                                                  .isEmpty
                                              ? null
                                              : NetworkSettingsService
                                                    .instance
                                                    .apiHeaders,
                                        ),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.account_circle,
                                          size: 22,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      )
                                    : Icon(
                                        Icons.account_circle,
                                        size: 24,
                                        color: cs.onSurfaceVariant,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 9,
                      ),
                      child: _buildMenuIcon(iconColor, size: 21),
                    ),
            ),
          ),
        );
      },
    );
  }
}
