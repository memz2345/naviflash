                              
  
                                   
                                           
                                                
                                              
                             
                                                 
                                        
                                              
                                      
                                           
                                                   
                                          
              
                                                                  
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_dynamics_page.dart';
import 'package:naviflash/screens/bilibili_recommend_page.dart';
import 'package:naviflash/screens/bilibili_subscription_page.dart';
import 'package:naviflash/screens/message_center_page.dart';
import 'package:naviflash/screens/my_cache_page.dart';
import 'package:naviflash/screens/bilibili_my_comments_page.dart';
import 'package:naviflash/screens/settings_split_screen.dart';
import 'package:naviflash/screens/watch_history_page.dart';
import 'package:naviflash/screens/bilibili_watch_later_page.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart' show MorphIconButton;
import 'package:naviflash/widgets/mine_user_header.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/src/custom_icons.dart';

import '../build_info.g.dart';
import '../services/device.dart';

               
class AppDrawer extends StatefulWidget {
                                                            
                                                  
  final String currentPage;

  const AppDrawer({super.key, this.currentPage = 'home'});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
                                             
                                            
  final ValueNotifier<double> _stretchPx = ValueNotifier(0);

  @override
  void dispose() {
    _stretchPx.dispose();
    super.dispose();
  }

                                        
  bool _onDrawerScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is OverscrollNotification) {
      _stretchPx.value = n.overscroll.abs();
    } else if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
      if (!n.metrics.outOfRange && _stretchPx.value != 0) {
        _stretchPx.value = 0;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 304,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: _onDrawerScroll,
        child: CustomScrollView(
                                                           
                                                             
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
                                                          
            SliverAppBar(
              expandedHeight: 272.0,
              pinned: false,
              floating: false,
              stretch: true,
              stretchTriggerOffset: 60,
              elevation: 0,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                                                              
                stretchModes: const [],
                background: _DrawerAccountHeader(stretch: _stretchPx),
              ),
            ),
                        
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 10),
                _item(
                  context,
                  icon: Icons.home_rounded,
                  title: '主页',
                  pageId: 'home',
                  onTap: () => _navTo(context, 'home'),
                ),
                _item(
                  context,
                  icon: Icons.download_rounded,
                  title: '离线缓存',
                  pageId: 'cache',
                  onTap: () => _navTo(context, 'cache'),
                ),
                _item(
                  context,
                  icon: Icons.history_rounded,
                  title: '观看记录',
                  pageId: 'history',
                  onTap: () => _navTo(context, 'history'),
                ),
                _item(
                  context,
                  icon: Icons.mode_comment_outlined,
                  title: '我的评论',
                  pageId: 'mycomments',
                  onTap: () => _navTo(context, 'mycomments'),
                ),
                _item(
                  context,
                  icon: CustomIcons.motion_photos_on_outlined,
                  title: '动态',
                  pageId: 'dynamics',
                  onTap: () => _navTo(context, 'dynamics'),
                ),
                _item(
                  context,
                  icon: Icons.subscriptions_outlined,
                  title: '订阅',
                  pageId: 'subscribe',
                  onTap: () => _navTo(context, 'subscribe'),
                ),
                _item(
                  context,
                  icon: Icons.watch_later_outlined,
                  title: '稍后再看',
                  pageId: 'watchlater',
                  onTap: () => _navTo(context, 'watchlater'),
                ),
                const SizedBox(height: 4),
                                                     
                _item(
                  context,
                  icon: Icons.forum_outlined,
                  title: AppLocalizations.of(context).msgCenterTitle,
                  pageId: 'messages',
                  onTap: () => _navTo(context, 'messages'),
                ),
                const SizedBox(height: 14),
                _item(
                  context,
                  icon: Icons.settings_outlined,
                  title: AppLocalizations.of(context).drawerSettings,
                  pageId: 'settings',
                  onTap: () => _navTo(context, 'settings'),
                ),
                const SizedBox(height: 18),
              ]),
            ),
          ],
        ),
      ),
    );
  }

                
     
                                     
                                               
                                         
                                                  
                                                          
                                              
                                            
  void _navTo(BuildContext context, String pageId) {
                                                 
                                                 
                                         
    void closeDrawer() {
      final scaffold = Scaffold.maybeOf(context);
      if (scaffold?.hasDrawer ?? false) {
        scaffold!.closeDrawer();
      } else {
        Navigator.of(context).pop();
      }
    }

    if (pageId == widget.currentPage) {
      closeDrawer();
      return;
    }
    closeDrawer();

    final nav = Navigator.of(context);

                                     
    if (pageId == 'home' || pageId == 'dynamics' || pageId == 'messages') {
      final switched = BilibiliRecommendPage.switchNavSection(pageId);
      if (switched) {
                                         
                                
        nav.popUntil((r) => r.isFirst);
        return;
      }
                                         
      if (pageId == 'home') {
        nav.popUntil((r) => r.isFirst);
        return;
      }
    }

                            
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => _pageFor(pageId)),
      (r) => r.isFirst,
    );
  }

                            
  Widget _pageFor(String pageId) {
    switch (pageId) {
      case 'cache':
        return const MyCachePage(drawerMode: true);
      case 'history':
        return const WatchHistoryPage(drawerMode: true);
      case 'watchlater':
        return const BilibiliWatchLaterPage(drawerMode: true);
      case 'mycomments':
        return const BilibiliMyCommentsPage(drawerMode: true);
      case 'messages':
        return const MessageCenterPage(drawerMode: true);
      case 'dynamics':
        return const BilibiliDynamicsPage(drawerMode: true);
      case 'subscribe':
        return const BilibiliSubscriptionPage(drawerMode: true);
      default:
        return const SplitSettingsScreen(isStandalone: true);
    }
  }

                               
  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String pageId,
    required VoidCallback onTap,
  }) {
    final isSelected = widget.currentPage == pageId;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? cs.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

                                       
                           
class _DrawerAccountHeader extends StatefulWidget {
                                             
  final ValueListenable<double> stretch;

  const _DrawerAccountHeader({required this.stretch});

  @override
  State<_DrawerAccountHeader> createState() => _DrawerAccountHeaderState();
}

class _DrawerAccountHeaderState extends State<_DrawerAccountHeader> {
                                             
  static BiliUserSpaceCard? _cachedCard;
  static int _cachedMid = 0;
  static bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCardIfNeeded();
  }

  Future<void> _loadCardIfNeeded() async {
    final account = BilibiliAccountService.instance;
    if (!account.isLoggedIn || _loading) return;
    if (_cachedCard != null && _cachedMid == account.mid) return;
    _loading = true;
    final card = await BilibiliUserSpaceService.fetchUserCard(mid: account.mid);
    _loading = false;
    if (!mounted) return;
    if (card != null) {
      _cachedCard = card;
      _cachedMid = account.mid;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: BilibiliAccountService.instance,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                                                     
                                                 
                                         
                _tappableBg(
                  context,
                  child: ValueListenableBuilder<double>(
                    valueListenable: widget.stretch,
                    builder: (context, px, _) {
                      final t = px.clamp(0.0, 160.0);
                      return Transform.scale(
                        scale: 1 + t / 1200,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: t / 14,
                            sigmaY: t / 14,
                          ),
                          child: _buildBackground(cs),
                        ),
                      );
                    },
                  ),
                ),
                                         
                                                     
                                              
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.12),
                          Colors.transparent,
                          cs.surfaceContainerLow.withValues(alpha: 0.95),
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                ),
                                               
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                                                           
                            MorphIconButton(
                              icon: Icons.close_rounded,
                              tooltip: '关闭',
                              onTap: () => Navigator.pop(context),
                              transparent: true,
                            ),
                            const Spacer(),
                          ],
                        ),
                        const Spacer(),
                        _buildAccountBlock(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBackground(ColorScheme cs) {
    final account = BilibiliAccountService.instance;
                                           
    if (!account.isLoggedIn) {
      return Image.asset(
        'assets/easter_egg/logged_out_bg.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultBackground(cs),
      );
    }
    final card = _cachedCard;
    final photo = card?.topPhoto ?? '';
    if (loggedCardPhoto(card)) {
      return Image(
        image: CachedImageProvider(
          '$photo@672w_378h_1c.webp',
          headers: NetworkSettingsService.instance.apiHeaders.isEmpty
              ? null
              : NetworkSettingsService.instance.apiHeaders,
        ),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _blurredAvatarBg(cs, account.avatarUrl),
      );
    }
    if (account.isLoggedIn && account.avatarUrl.isNotEmpty) {
      return _blurredAvatarBg(cs, account.avatarUrl);
    }
    return _defaultBackground(cs);
  }

                                     
  Widget _defaultBackground(ColorScheme cs) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer,
            cs.tertiaryContainer,
            cs.secondaryContainer,
          ],
        ),
      ),
    );
  }

  bool loggedCardPhoto(BiliUserSpaceCard? card) {
    final account = BilibiliAccountService.instance;
    return account.isLoggedIn && card != null && card.topPhoto.isNotEmpty;
  }

  Widget _blurredAvatarBg(ColorScheme cs, String avatarUrl) {
    return Image(
      image: CachedImageProvider(
        BilibiliUserSpaceService.avatarUrl(avatarUrl, size: 320),
        headers: NetworkSettingsService.instance.apiHeaders.isEmpty
            ? null
            : NetworkSettingsService.instance.apiHeaders,
      ),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primaryContainer, cs.tertiaryContainer],
          ),
        ),
      ),
      frameBuilder: (context, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded || frame != null) {
          return ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: child,
          );
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primaryContainer, cs.tertiaryContainer],
            ),
          ),
        );
      },
    );
  }

                                   
                                    
  Widget _tappableBg(BuildContext context, {required Widget child}) {
    if (BilibiliAccountService.instance.isLoggedIn) return child;
    return GestureDetector(
      onTap: () => showAppToast(context, '你说拯救世界 也包括我吗'),
      child: child,
    );
  }

                                                     
                                   
                                          
  Widget _buildAccountBlock() {
    return const MineUserHeader(
      style: MineHeaderStyle.onImage,
      popBeforeNavigate: true,
    );
  }
}

                         
void showDrawerInfoDialog(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context);
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.45 : 0.25),
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Material(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 26,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.drawerAbout,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 0.5),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                    child: FutureBuilder<Widget>(
                      future: getHostSystemInfo(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: LoadingIndicatorM3E(),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(
                            l10n.drawerFetchFailed(snapshot.error.toString()),
                            style: TextStyle(color: theme.colorScheme.error),
                          );
                        }
                        final deviceInfo =
                            snapshot.data ??
                            Text(
                              l10n.drawerNoDeviceInfo,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            deviceInfo,
                            const Divider(height: 20, thickness: 0.5),
                            _drawerInfoTile(
                              context,
                              Icons.code,
                              'Codename',
                              BuildInfo.buildCodename,
                            ),
                            const SizedBox(height: 10),
                            _drawerInfoTile(
                              context,
                              Icons.access_time,
                              'Build Time',
                              BuildInfo.buildTimestamp,
                            ),
                            const SizedBox(height: 10),
                            _drawerInfoTile(
                              context,
                              BuildInfo.isDebug
                                  ? Icons.bug_report
                                  : Icons.shield,
                              'Running',
                              BuildInfo.isDebug ? 'Debug' : 'Release',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          l10n.commonOk,
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _drawerInfoTile(
  BuildContext context,
  IconData icon,
  String label,
  String value,
) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ],
  );
}
