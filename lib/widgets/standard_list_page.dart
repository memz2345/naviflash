                                      
  
                                         
                           
  
                     
                                   
                        
                                              
                                  
                                                           
                                                               
                                      
                                                
                                              
  
                                                         
                                               
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/widgets/back_top_fab.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/page_loading.dart';

                          
const double kStdTopBarHeight = 56.0;

                                       
const double kVideoCardTargetWidth = 200.0;
const int kVideoCardMinColumns = 2;
const int kVideoCardMaxColumns = 8;

                                    
const double kVideoCardAspect = 0.78;

                                                   
class GridModePrefs {
  static Future<bool> load(String key, {bool fallback = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('gridMode_$key') ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  static Future<void> save(String key, bool grid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('gridMode_$key', grid);
    } catch (_) {
                    
    }
  }
}

            
   
                                                                 
                                               
class StandardListScaffold extends StatelessWidget {
  final Widget body;
  final Widget topBar;

                       
  final Widget? floatingActionButton;

                           
  final List<Widget> overlays;

                           
  final Widget? bottomNavigationBar;

                              
  final bool extendBody;

  const StandardListScaffold({
    super.key,
    required this.body,
    required this.topBar,
    this.floatingActionButton,
    this.overlays = const [],
    this.bottomNavigationBar,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IosBackdropScale(
      child: Scaffold(
        backgroundColor: cs.surfaceContainer,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        extendBody: extendBody,
        body: Stack(
          children: [
                                               
            PageBackground(baseColor: cs.surfaceContainer, contentStyle: true),
            SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(child: body),
                  ...overlays,
                  Align(alignment: Alignment.topCenter, child: topBar),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

                                           
class StandardListTopBar extends StatelessWidget {
  final String title;

                                
  final bool showBack;
  final VoidCallback? onBack;

                              
  final bool? gridMode;
  final ValueChanged<bool>? onToggleGrid;

                 
  final List<Widget>? actions;

                               
  final Widget? bottom;

                       
  final double bottomHeight;

                           
  final bool collapsed;

                      
  final Widget? titleWidget;

  const StandardListTopBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.gridMode,
    this.onToggleGrid,
    this.actions,
    this.bottom,
    this.bottomHeight = 0,
    this.collapsed = false,
    this.titleWidget,
  });

                                  
  double get totalHeight =>
      (collapsed ? 0.0 : kStdTopBarHeight) + bottomHeight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return FrostedPanel(
      opacity: 0.75,
      blurSigma: 12,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                                                        
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: collapsed ? 0.0 : 1.0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              builder: (context, value, child) => ClipRect(
                child: Align(
                  heightFactor: value,
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              ),
              child: SizedBox(
                height: kStdTopBarHeight,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    if (showBack)
                      MorphIconButton(
                        icon: Icons.arrow_back,
                        tooltip: l10n.homeBack,
                        onTap: onBack ?? () => Navigator.of(context).maybePop(),
                        frosted: true,
                      ),
                    if (showBack) const SizedBox(width: 12),
                    Expanded(
                      child: titleWidget ??
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                    ),
                    if (gridMode != null && onToggleGrid != null)
                      MorphIconButton(
                        icon: gridMode!
                            ? Icons.grid_view_rounded
                            : Icons.view_list_rounded,
                        tooltip: gridMode!
                            ? (isZh ? '切换为单列' : 'Switch to list')
                            : (isZh ? '切换为网格' : 'Switch to grid'),
                        onTap: () => onToggleGrid!(!gridMode!),
                        frosted: true,
                      ),
                    ...?actions,
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

                                        
Widget topBarSpaceSliver(double height) => SliverToBoxAdapter(
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeInOut,
    height: height,
  ),
);

                                                 
Widget videoCardGridSliver({
  required int itemCount,
  required Widget Function(BuildContext context, int index) itemBuilder,
  double spacing = 12,
  EdgeInsets padding = const EdgeInsets.fromLTRB(16, 4, 16, 8),
}) {
  return SliverPadding(
    padding: padding,
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final columns = (width / kVideoCardTargetWidth)
            .floor()
            .clamp(kVideoCardMinColumns, kVideoCardMaxColumns);
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: kVideoCardAspect,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => itemBuilder(context, index),
            childCount: itemCount,
          ),
        );
      },
    ),
  );
}

                        
Widget videoCardListSliver({
  required int itemCount,
  required Widget Function(BuildContext context, int index) itemBuilder,
  double gap = 8,
  EdgeInsets padding = const EdgeInsets.fromLTRB(16, 4, 16, 8),
}) {
  return SliverPadding(
    padding: padding,
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : gap),
          child: itemBuilder(context, index),
        ),
        childCount: itemCount,
      ),
    ),
  );
}

                          
Widget bottomSpaceSliver(BuildContext context) => SliverToBoxAdapter(
  child: SizedBox(height: MediaQuery.of(context).padding.bottom + 72),
);

                                                    
const Widget loadingMoreSliver = pageLoadingMoreSliver;

                                   
   
                               
Widget? standardListFab({
  required bool hasError,
  required bool isEmpty,
  required VoidCallback onRetry,
  required bool extended,
  required VoidCallback onTapTop,
  bool atTop = false,
  VoidCallback? onRefresh,
  GlobalKey<BackTopFabState>? fabKey,
}) {
  if (hasError && isEmpty) return LoadRetryPill(onRetry: onRetry);
  return BackTopFab(
    key: fabKey,
    extended: extended,
    atTop: atTop,
    onTap: onTapTop,
    onRefresh: onRefresh,
  );
}
