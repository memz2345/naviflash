                                    
  
                     
                                                                
                                             
                                           
                                              
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/side_bar_menu_button.dart';

                                      
                             
const double kFrostedPageBarHeight = 56.0;

class FrostedPageBar extends StatelessWidget {
  final String title;

                                                 
  final bool drawerMode;

                         
  final List<Widget> actions;

                                              
               
  final Widget? leading;

                                                  
                      
  final Widget? bottom;
  final double bottomHeight;

  const FrostedPageBar({
    super.key,
    required this.title,
    this.drawerMode = false,
    this.actions = const [],
    this.leading,
    this.bottom,
    this.bottomHeight = 44,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FrostedPanel(
      opacity: 0.75,
      blurSigma: 12,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: kFrostedPageBarHeight,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  leading ??
                      (drawerMode
                          ? Builder(
                              builder: (ctx) => SideBarMenuButton(
                                tooltip: '侧边栏',
                                onTap: () => Scaffold.of(ctx).openDrawer(),
                              ),
                            )
                          : MorphIconButton(
                              icon: Icons.arrow_back,
                              tooltip: AppLocalizations.of(context).homeBack,
                              onTap: () => Navigator.of(context).maybePop(),
                              transparent: true,
                            )),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  ...actions,
                  const SizedBox(width: 8),
                ],
              ),
            ),
            if (bottom != null)
              SizedBox(height: bottomHeight, child: bottom),
          ],
        ),
      ),
    );
  }
}
