                                           
  
                                                
                                                 
                                                       
                                         
                                                 
                                                     
                                                      
                                        
import 'package:flutter/material.dart';
import 'package:naviflash/widgets/standard_list_page.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_favorite_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:naviflash/services/favorites_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/comment/comment_composer_fab.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/lazy_cover_image.dart' show thumbnailCoverUrl;
import 'package:naviflash/widgets/video_card.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/more_menu_sheet.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'bilibili_login_screen.dart';
import 'bilibili_related_videos_page.dart';
import 'bilibili_video_page.dart';
import 'browser_page.dart';
import 'favorites_page.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';

                                                   
                           
const List<({String name, int tid})> _kFavFolderZones = [
  (name: '动画', tid: 1),
  (name: '音乐', tid: 3),
  (name: '舞蹈', tid: 129),
  (name: '游戏', tid: 4),
  (name: '知识', tid: 36),
  (name: '科技', tid: 188),
  (name: '运动', tid: 234),
  (name: '汽车', tid: 223),
  (name: '生活', tid: 160),
  (name: '美食', tid: 211),
  (name: '动物圈', tid: 217),
  (name: '鬼畜', tid: 119),
  (name: '时尚', tid: 155),
  (name: '娱乐', tid: 5),
  (name: '影视', tid: 181),
];

                                        
const List<({String value, String label})> _kFavSortOrders = [
  (value: 'mtime', label: '最近收藏'),
  (value: 'view', label: '最多播放'),
  (value: 'pubtime', label: '最近投稿'),
];

String _fmtFavCount(int n) {
  if (n >= 100000000) {
    return '${(n / 100000000).toStringAsFixed(1)}亿';
  }
  if (n >= 10000) {
    final v = (n / 10000).toStringAsFixed(1);
    return '${v.endsWith('.0') ? v.substring(0, v.length - 2) : v}万';
  }
  return '$n';
}

String _fmtFavDuration(int seconds) {
  if (seconds <= 0) return '';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

                        
String _fmtFavTime(int ts) {
  if (ts <= 0) return '';
  final t = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  final now = DateTime.now();
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return '刚刚收藏';
  if (diff.inHours < 1) return '${diff.inMinutes} 分钟前收藏';
  if (diff.inDays < 1) return '${diff.inHours} 小时前收藏';
  if (diff.inDays < 30) return '${diff.inDays} 天前收藏';
  if (t.year == now.year) return '${t.month}月${t.day}日收藏';
  return '${t.year}/${t.month}/${t.day} 收藏';
}

                              
class _PinnedFilterBar extends SliverPersistentHeaderDelegate {
  _PinnedFilterBar({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: height, child: child);
  }

  @override
  bool shouldRebuild(covariant _PinnedFilterBar oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}

                                            
          
                                            

class BilibiliFavoritesPage extends StatefulWidget {
  const BilibiliFavoritesPage({super.key});

  @override
  State<BilibiliFavoritesPage> createState() => _BilibiliFavoritesPageState();
}

class _BilibiliFavoritesPageState extends State<BilibiliFavoritesPage> {
                                      
                                          
  static const SliverGridDelegate _folderGridDelegate =
      SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      );

                                                       
                             
  static const String _pinnedPrefKey = 'bili_fav_folder_pinned';

  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  List<BiliFavFolder>? _folders;
  bool _loading = true;
  String? _error;

                               
  List<int> _pinnedIds = [];

                              
  bool _managing = false;

                                                     
                                    
                                   
  bool _lastLoggedIn = false;
  int _lastMid = 0;

  @override
  void initState() {
    super.initState();
    _lastLoggedIn = BilibiliFavoriteService.isLoggedIn;
    _lastMid = BilibiliFavoriteService.mid;
    BilibiliAccountService.instance.addListener(_onAccountChanged);
    _loadPinned();
    _load();
  }

                           
  Future<void> _loadPinned() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = (prefs.getStringList(_pinnedPrefKey) ?? const [])
          .map((s) => int.tryParse(s))
          .whereType<int>()
          .toList();
      if (!mounted) return;
      setState(() => _pinnedIds = ids);
                       
      if (_folders != null) {
        setState(() => _folders = _sortFolders(_folders!));
      }
    } catch (_) {
                             
    }
  }

  Future<void> _persistPinned() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _pinnedPrefKey,
      _pinnedIds.map((id) => id.toString()).toList(),
    );
  }

                                         
                                    
  List<BiliFavFolder> _sortFolders(List<BiliFavFolder> folders) {
    int rank(BiliFavFolder f) {
      final i = _pinnedIds.indexOf(f.id);
      return i < 0 ? 1 << 30 : i;
    }

    final indexed = [for (var i = 0; i < folders.length; i++) (folders[i], i)];
    indexed.sort((a, b) {
      final r = rank(a.$1).compareTo(rank(b.$1));
      return r != 0 ? r : a.$2.compareTo(b.$2);
    });
    return [for (final e in indexed) e.$1];
  }

  Future<void> _togglePinned(BiliFavFolder folder) async {
    HapticFeedback.lightImpact();
    setState(() {
      if (_pinnedIds.contains(folder.id)) {
        _pinnedIds.remove(folder.id);
      } else {
        _pinnedIds.insert(0, folder.id);
      }
      if (_folders != null) _folders = _sortFolders(_folders!);
    });
    await _persistPinned();
  }

  @override
  void dispose() {
    BilibiliAccountService.instance.removeListener(_onAccountChanged);
    super.dispose();
  }

  void _onAccountChanged() {
    final loggedIn = BilibiliFavoriteService.isLoggedIn;
    final mid = BilibiliFavoriteService.mid;
    if (loggedIn == _lastLoggedIn && mid == _lastMid) return;
    _lastLoggedIn = loggedIn;
    _lastMid = mid;
    if (!mounted) return;
    if (loggedIn) {
                                    
      _load();
    } else {
                           
      setState(() {
        _folders = null;
        _loading = false;
        _error = null;
      });
    }
  }

                                    
  Future<void> _load() async {
    setState(() {
      _loading = _folders == null;
      _error = null;
    });
    final folders = await BilibiliFavoriteService.fetchFolders();
    if (!mounted) return;
    if (folders == null) {
      setState(() {
        _loading = false;
        _error = BilibiliFavoriteService.lastErrorDetail ?? '加载失败';
      });
      return;
    }
    setState(() {
      _folders = _sortFolders(folders);
      _loading = false;
    });
  }

                                        
                                      
  Future<void> _refresh() async {
    final folders = await BilibiliFavoriteService.fetchFolders();
    if (!mounted) return;
    if (folders == null) {
      if (_folders == null) {
        setState(() {
          _error = BilibiliFavoriteService.lastErrorDetail ?? '加载失败';
        });
      }
      return;
    }
    setState(() {
      _folders = _sortFolders(folders);
      _error = null;
      _loading = false;
    });
  }

                                                
  void _showRefreshIndicator() {
    _refreshKey.currentState?.show();
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建收藏夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(hintText: '收藏夹名称', counterText: ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim().isNotEmpty),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (created != true || !mounted) return;
    final result = await BilibiliFavoriteService.createFolder(
      title: controller.text.trim(),
    );
    if (!mounted) return;
    if (!result.ok) {
      showAppToast(context, '创建失败：${result.message}');
      return;
    }
                            
    await _refresh();
  }

  void _goLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BilibiliLoginScreen()));
  }

                                              
                                
                                              

                                      
  Future<void> _showFolderMenu(BiliFavFolder folder) async {
    HapticFeedback.mediumImpact();
    final pinned = _pinnedIds.contains(folder.id);
    await showMoreMenuSheet(
      context: context,
      actions: [
        MoreMenuAction(
          icon: Icons.folder_open_outlined,
          label: '打开',
          onTap: () => _openFolder(context, folder),
        ),
        MoreMenuAction(
          icon: pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
          label: pinned ? '取消置顶' : '置顶',
          onTap: () => _togglePinned(folder),
        ),
        if (!folder.isDefault) ...[
          MoreMenuAction(
            icon: Icons.edit_outlined,
            label: '重命名',
            onTap: () => _renameFolder(folder),
          ),
          MoreMenuAction(
            icon: Icons.delete_outline,
            label: '删除收藏夹',
            onTap: () => _deleteFolder(folder),
          ),
        ],
      ],
    );
  }

                                                
                 
  Future<void> _renameFolder(BiliFavFolder folder) async {
    if (_managing) return;
    final controller = TextEditingController(text: folder.title);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名收藏夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: '收藏夹名称',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim().isNotEmpty),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final title = controller.text.trim();
    if (title.isEmpty || title == folder.title) return;
    setState(() => _managing = true);
    final result = await BilibiliFavoriteService.renameFolder(
      mediaId: folder.id,
      title: title,
      isPublic: folder.isPublic,
      cover: folder.cover,
    );
    if (!mounted) return;
    setState(() => _managing = false);
    if (!result.ok) {
      showAppToast(context, '重命名失败：${result.message}', error: true);
      return;
    }
    showAppToast(context, '已重命名');
    await _refresh();
  }

                                        
  Future<void> _deleteFolder(BiliFavFolder folder) async {
    if (_managing) return;
    if (folder.isDefault) {
      showAppToast(context, '默认收藏夹不能删除', error: true);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除收藏夹'),
        content: Text(
          '将删除收藏夹「${folder.title}」（${folder.mediaCount} 个内容）。\n\n'
          '收藏夹内的视频不会被删除，但这些内容的收藏关系无法恢复。'
          '此操作不可撤销，确定继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _managing = true);
    final result = await BilibiliFavoriteService.deleteFolder(
      mediaId: folder.id,
    );
    if (!mounted) return;
    setState(() => _managing = false);
    if (!result.ok) {
      showAppToast(context, '删除失败：${result.message}', error: true);
      return;
    }
                 
    if (_pinnedIds.contains(folder.id)) {
      setState(() {
        _pinnedIds.remove(folder.id);
        if (_folders != null) {
          _folders = _folders!
              .where((f) => f.id != folder.id)
              .toList();
        }
      });
      await _persistPinned();
    }
    if (!mounted) return;
    showAppToast(context, '已删除收藏夹');
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final folders = _folders;
    final hasFolderList = folders != null && folders.isNotEmpty;

    return StandardListScaffold(
      topBar: StandardListTopBar(
        title: 'B 站收藏夹',
        showBack: true,
        actions: [
          if (hasFolderList) ...[
            MorphIconButton(
              icon: Icons.refresh_rounded,
              tooltip: '刷新',
              onTap: _showRefreshIndicator,
              frosted: true,
            ),
            MorphIconButton(
              icon: Icons.create_new_folder_outlined,
              tooltip: '新建收藏夹',
              onTap: _createFolder,
              frosted: true,
            ),
          ],
        ],
      ),
                                      
      floatingActionButton: folders == null && _error != null && !_loading
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 8,
              ),
              child: LoadRetryPill(onRetry: _showRefreshIndicator),
            )
          : null,
      body: AppRefreshIndicator(
        refreshIndicatorKey: _refreshKey,
        color: cs.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: _loading
              ? const NeverScrollableScrollPhysics()
              : const AppRefreshScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
          slivers: [
            topBarSpaceSliver(kStdTopBarHeight),
                                            
                                                   
                                   
          if (hasFolderList)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              sliver: SliverGrid(
                gridDelegate: _folderGridDelegate,
                delegate: SliverChildBuilderDelegate(
                  (context, index) => index == 0
                      ? const _LocalFavoritesCard()
                      : _FolderCard(
                          folder: folders[index - 1],
                          pinned: _pinnedIds.contains(folders[index - 1].id),
                          onTap: () => _openFolder(context, folders[index - 1]),
                          onLongPress: () =>
                              _showFolderMenu(folders[index - 1]),
                        ),
                  childCount: folders.length + 1,
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              sliver: SliverGrid(
                gridDelegate: _folderGridDelegate,
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const _LocalFavoritesCard(),
                  childCount: 1,
                ),
              ),
            ),
            if (!BilibiliFavoriteService.isLoggedIn)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        size: 64,
                        color: cs.onSurface.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 14),
                      const Text('需要登录 B 站账号'),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _goLogin,
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('去登录'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: LoadingIndicatorM3E()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 56,
                        color: cs.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              )
            else
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_open_outlined,
                        size: 56,
                        color: cs.onSurface.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 12),
                      const Text('还没有收藏夹'),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _createFolder,
                        icon: const Icon(
                          Icons.create_new_folder_outlined,
                          size: 18,
                        ),
                        label: const Text('新建收藏夹'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          ],
        ),
      ),
    );
  }

  void _openFolder(BuildContext context, BiliFavFolder folder) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BilibiliFavFolderPage(folder: folder)),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final BiliFavFolder folder;
  final VoidCallback onTap;

                                   
  final VoidCallback? onLongPress;

                        
  final bool pinned;

  const _FolderCard({
    required this.folder,
    required this.onTap,
    this.onLongPress,
    this.pinned = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  folder.cover.isNotEmpty
                      ? Image(
                                                         
                                                              
                                                                
                          image: CachedImageProvider(
                            thumbnailCoverUrl(
                              folder.cover,
                              width: 200,
                              aspect: 16 / 10,
                            ),
                            headers:
                                NetworkSettingsService.instance.apiHeaders.isEmpty
                                ? null
                                : NetworkSettingsService.instance.apiHeaders,
                          ),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(cs),
                        )
                      : _placeholder(cs),
                  if (pinned)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Icon(
                        Icons.push_pin_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.95),
                        shadows: const [
                          Shadow(blurRadius: 4, color: Colors.black54),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          folder.isPublic ? Icons.public : Icons.lock_outline,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                                                              
                                                    
                        Expanded(
                          child: Text(
                            '${folder.mediaCount} 个内容 · '
                            '${folder.isPublic ? '公开' : '私密'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.folder_outlined,
        size: 32,
        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }
}

                                                  
                                          
                        
class _LocalFavoritesCard extends StatelessWidget {
  const _LocalFavoritesCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
                                                      
                             
    final count = context.watch<FavoritesService>().items.length;
    return Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                                    
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Container(
                color: cs.primaryContainer,
                alignment: Alignment.center,
                child: Icon(
                  Icons.bookmarks_rounded,
                  size: 40,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本地收藏',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.offline_pin_rounded,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$count 个内容 · 离线可用',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FavoritesPage()));
  }
}

                                            
                
  
                              
                                                    
                                      
                             
                                       
                                           
                                           
                   
                                            

class BilibiliFavFolderPage extends StatefulWidget {
  final BiliFavFolder folder;

  const BilibiliFavFolderPage({super.key, required this.folder});

  @override
  State<BilibiliFavFolderPage> createState() => _BilibiliFavFolderPageState();
}

class _BilibiliFavFolderPageState extends State<BilibiliFavFolderPage> {
  static const double _gridTargetWidth = 200.0;
  static const int _gridMinColumns = 2;
  static const int _gridMaxColumns = 8;

  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtl = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  final List<BiliFavVideo> _videos = [];
  int _page = 1;
  bool _hasMore = true;

                                 
                                     
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

           
  int _tid = 0;            
  String _order = 'mtime';                          
  String _keyword = '';           
  bool _searchOpen = false;

                                
  bool _multiSelect = false;
  final Set<int> _selectedIds = {};
  bool _batchDeleting = false;

                                         
                    
  Future<void> _reloadChain = Future.value();
  int _epoch = 0;
  bool _busy = false;

                                          
  bool _indicatorActive = false;

  bool get _hasActiveFilter => _tid != 0 || _keyword.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _syncGridModePref();
    _reload(initial: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

                                           
  Future<void> _syncGridModePref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    BilibiliRelatedVideosPage.gridModeNotifier.value =
        prefs.getBool('bili_related_grid_mode') ?? true;
  }

                                          
                                          
  bool _pendingJumpToTop = false;

                                                
                                        
                                                      
                                  
                                               
  void _userReload({bool jumpToTop = true}) {
    _pendingJumpToTop = jumpToTop;
    final state = _refreshKey.currentState;
    if (state == null || _indicatorActive) {
      _enqueueReload(jumpToTop: jumpToTop);
      return;
    }
    state.show();
  }

                                       
                                                     
  Future<void> _indicatorRefresh() async {
    _indicatorActive = true;
    try {
      await _enqueueReload(jumpToTop: _pendingJumpToTop);
    } finally {
      _indicatorActive = false;
      _pendingJumpToTop = false;
    }
  }

                                  
  Future<void> _enqueueReload({bool jumpToTop = true}) {
    final link = _reloadChain.then((_) => _reload(jumpToTop: jumpToTop));
    _reloadChain = link;
    return link;
  }

              
                                              
                                        
                                          
  Future<void> _reload({bool initial = false, bool jumpToTop = true}) async {
    final epoch = ++_epoch;
    _busy = true;
    if (mounted && initial) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final result = await BilibiliFavoriteService.fetchFolderVideos(
      mediaId: widget.folder.id,
      pn: 1,
      order: _order,
      keyword: _keyword,
      tid: _tid,
    );
    if (!mounted) return;
    if (epoch != _epoch) return;                    
    _busy = false;
    if (result == null) {
      final detail = BilibiliFavoriteService.lastErrorDetail ?? '加载失败';
      if (_videos.isEmpty) {
        setState(() {
          _loading = false;
          _error = detail;
        });
      } else {
        showAppToast(context, '刷新失败：$detail', error: true);
      }
      return;
    }
    setState(() {
      _videos
        ..clear()
        ..addAll(result.videos);
      _page = 1;
      _hasMore = result.hasMore;
      _loading = false;
      _error = null;
    });
                                               
                  
    if (jumpToTop) _jumpToTop();
  }

  void _jumpToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || _busy || _error != null) {
      return;
    }
    final epoch = _epoch;
    setState(() => _loadingMore = true);
    final result = await BilibiliFavoriteService.fetchFolderVideos(
      mediaId: widget.folder.id,
      pn: _page + 1,
      order: _order,
      keyword: _keyword,
      tid: _tid,
    );
    if (!mounted) return;
    if (result != null && epoch == _epoch) {
      final known = _videos.map((e) => e.aid).toSet();
      setState(() {
        _videos.addAll(result.videos.where((e) => !known.contains(e.aid)));
        _page += 1;
        _hasMore = result.hasMore;
      });
    }
    if (mounted) setState(() => _loadingMore = false);
  }

  void _setZone(int tid) {
    if (tid == _tid) return;
    _tid = tid;
    _userReload();
  }

  void _setOrder(String order) {
    if (order == _order) return;
    _order = order;
    _userReload();
  }

  void _toggleSearch() {
    if (_searchOpen) {
                               
                                          
                                          
      final hadKeyword = _keyword.isNotEmpty;
      setState(() {
        _searchOpen = false;
        _searchCtl.clear();
        _keyword = '';
      });
      if (hadKeyword) _userReload();
    } else {
      setState(() => _searchOpen = true);
    }
  }

  void _applyKeyword(String raw) {
    final keyword = raw.trim();
    if (keyword == _keyword) return;
    _keyword = keyword;
    _userReload();
  }

  void _clearSearch() {
    _searchCtl.clear();
    _applyKeyword('');
  }

  void _clearFilters() {
    final hadZone = _tid != 0;
    final hadKeyword = _keyword.isNotEmpty;
    final wasSearchOpen = _searchOpen;
    if (!_hasActiveFilter && !wasSearchOpen) return;
                                                 
                       
    setState(() {
      _tid = 0;
      _searchOpen = false;
      _searchCtl.clear();
      _keyword = '';
    });
    if (hadZone || hadKeyword) _userReload();
  }

  void _openVideo(BuildContext ctx, BiliFavVideo video) {
    HapticFeedback.lightImpact();
    if (video.isUnavailable) {
      showAppToast(ctx, '内容已失效，无法播放', error: true);
      return;
    }
    if (video.bvid.isNotEmpty) {
      openBilibiliVideo(
        ctx,
        bvid: video.bvid,
        initialTitle: video.title,
        initialCover: video.cover,
        heroTag: 'bili_video_${video.bvid}',
      );
      return;
    }
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => BrowserPage(
          initialUrl: video.url,
          title: video.title.isEmpty ? 'B站内容' : video.title,
        ),
      ),
    );
  }

                                              
              
                                              

  void _toggleMultiSelect() {
    HapticFeedback.lightImpact();
    setState(() {
      _multiSelect = !_multiSelect;
      if (!_multiSelect) _selectedIds.clear();
    });
  }

  bool _isAllSelected() =>
      _videos.isNotEmpty && _selectedIds.length >= _videos.length;

  void _toggleSelectAll() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isAllSelected()) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_videos.map((v) => v.aid));
      }
    });
  }

  void _toggleVideo(BiliFavVideo video) {
    setState(() {
      if (_selectedIds.contains(video.aid)) {
        _selectedIds.remove(video.aid);
      } else {
        _selectedIds.add(video.aid);
      }
    });
  }

  void _enterMultiSelect(BiliFavVideo video) {
    if (_multiSelect) {
      _toggleVideo(video);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _multiSelect = true;
      _selectedIds.add(video.aid);
    });
  }

                                                  
  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty || _batchDeleting) return;
    final targets =
        _videos.where((v) => _selectedIds.contains(v.aid)).toList();
    if (targets.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('取消收藏'),
        content: Text(
          '将把选中的 ${targets.length} 个内容移出收藏夹「${widget.folder.title}」，'
          '确定继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _batchDeleting = true);
    final result = await BilibiliFavoriteService.batchDelVideos(
      mediaId: widget.folder.id,
      videos: targets,
    );
    if (!mounted) return;
    setState(() => _batchDeleting = false);
    if (!result.ok) {
      showAppToast(context, '取消收藏失败：${result.message}', error: true);
      return;
    }
    setState(() {
      final removed = targets.map((v) => v.aid).toSet();
      _videos.removeWhere((v) => removed.contains(v.aid));
      _selectedIds.clear();
      _multiSelect = false;
    });
    showAppToast(context, '已移除 ${targets.length} 个内容');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final hasContent = _videos.isNotEmpty;
    final showRetry =
        _error != null && _videos.isEmpty && !_loading;
    return Scaffold(
                                       
                                         
                                 
      floatingActionButton: _multiSelect
          ? null
          : showRetry
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              child: LoadRetryPill(onRetry: _userReload),
            )
          : hasContent
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              child: ValueListenableBuilder<bool>(
                valueListenable: BilibiliRelatedVideosPage.gridModeNotifier,
                builder: (context, gridMode, _) {
                  return CommentComposerFab(
                    icon: gridMode
                        ? Icons.view_agenda_outlined
                        : Icons.grid_view_rounded,
                    label: gridMode
                        ? l10n.searchSwitchSingleCol
                        : l10n.searchSwitchMulti,
                    labelVisible:
                        ModalRoute.of(context)?.isCurrent ?? true,
                    onPressed: BilibiliRelatedVideosPage.toggleGridMode,
                  );
                },
              ),
            )
          : null,
                              
      bottomNavigationBar: _multiSelect ? _buildMultiSelectBottomBar(cs) : null,
      body: ValueListenableBuilder<bool>(
        valueListenable: BilibiliRelatedVideosPage.gridModeNotifier,
        builder: (context, gridMode, _) {
          return AppRefreshIndicator(
            refreshIndicatorKey: _refreshKey,
            color: cs.primary,
            onRefresh: _indicatorRefresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                  _loadMore();
                }
                return false;
              },
              child: CustomScrollView(
                controller: _scroll,
                physics: _loading && _videos.isEmpty
                    ? const NeverScrollableScrollPhysics()
                    : const AppRefreshScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                slivers: [
                  ExpressiveSliverAppBar(
                    title: _multiSelect
                        ? '已选 ${_selectedIds.length} 项'
                        : widget.folder.title,
                    leading: _multiSelect
                        ? MorphIconButton(
                            icon: Icons.close,
                            tooltip: '退出多选',
                            onTap: _toggleMultiSelect,
                          )
                        : MorphIconButton(
                            icon: Icons.arrow_back,
                            tooltip: l10n.homeBack,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                    actions: _multiSelect
                        ? [
                            MorphIconButton(
                              icon: Icons.select_all_rounded,
                              tooltip: _isAllSelected() ? '取消全选' : '全选',
                              onTap: _toggleSelectAll,
                            ),
                            MorphIconButton(
                              icon: _batchDeleting
                                  ? Icons.hourglass_top_rounded
                                  : Icons.delete_outline,
                              tooltip: '取消收藏',
                              onTap: _selectedIds.isEmpty || _batchDeleting
                                  ? null
                                  : _deleteSelected,
                            ),
                            const SizedBox(width: 6),
                          ]
                        : [
                            MorphIconButton(
                              icon: Icons.refresh_rounded,
                              tooltip: '刷新',
                              onTap: _userReload,
                            ),
                            MorphIconButton(
                              icon: _searchOpen
                                  ? Icons.close_rounded
                                  : Icons.search_rounded,
                              tooltip: _searchOpen ? '收起搜索' : '在收藏夹内搜索',
                              onTap: _toggleSearch,
                            ),
                            const SizedBox(width: 6),
                          ],
                  ),
                                            
                  if (_searchOpen)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedFilterBar(
                        height: 58,
                        child: _buildSearchRow(cs),
                      ),
                    ),
                                               
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedFilterBar(
                      height: 48,
                      child: _buildZoneBar(cs),
                    ),
                  ),
                                                                     
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedFilterBar(
                      height: 44,
                      child: _buildSortBar(cs),
                    ),
                  ),
                  ..._buildContentSlivers(cs, gridMode),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

                                   
  Widget _buildMultiSelectBottomBar(ColorScheme cs) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(child: Text('已选 ${_selectedIds.length} 项')),
            FilledButton.icon(
              onPressed: _selectedIds.isEmpty || _batchDeleting
                  ? null
                  : _deleteSelected,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('取消收藏'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _toggleMultiSelect, child: const Text('取消')),
          ],
        ),
      ),
    );
  }

                                                   
  Widget _buildSortBar(ColorScheme cs) {
    return Container(
      height: 44,
      color: cs.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        children: [
          for (final o in _kFavSortOrders)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(o.label),
                selected: _order == o.value,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight:
                      _order == o.value ? FontWeight.w600 : FontWeight.w400,
                  color: _order == o.value
                      ? cs.onSecondaryContainer
                      : cs.onSurfaceVariant,
                ),
                selectedColor: cs.secondaryContainer,
                backgroundColor: cs.surfaceContainerHigh,
                side: BorderSide.none,
                onSelected: (_) => _setOrder(o.value),
              ),
            ),
        ],
      ),
    );
  }

                

  Widget _buildSearchRow(ColorScheme cs) {
    return Container(
      height: 58,
      padding: const EdgeInsets.fromLTRB(16, 9, 12, 9),
      color: cs.surface,
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 19, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _searchCtl,
              textInputAction: TextInputAction.search,
              onSubmitted: _applyKeyword,
              style: TextStyle(fontSize: 13.5, color: cs.onSurface),
              decoration: InputDecoration(
                isDense: true,
                hintText: '搜索夹内内容（标题 / UP 主）',
                hintStyle: TextStyle(fontSize: 13, color: cs.outline),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_keyword.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: cs.outline),
              tooltip: '清除',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              onPressed: _clearSearch,
            ),
        ],
      ),
    );
  }

  Widget _buildZoneBar(ColorScheme cs) {
                                        
    final chips = <Widget>[
      if (!_hasActiveFilter)
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Text(
            '共 ${widget.folder.mediaCount} 条',
            style: TextStyle(fontSize: 11, color: cs.outline),
          ),
        ),
      _zoneChip(cs, '全部', 0),
      for (final z in _kFavFolderZones) _zoneChip(cs, z.name, z.tid),
    ];
    return Container(
      height: 48,
      color: cs.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: chips,
      ),
    );
  }

  Widget _zoneChip(ColorScheme cs, String label, int tid) {
    final selected = _tid == tid;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
        ),
        selectedColor: cs.secondaryContainer,
        backgroundColor: cs.surfaceContainerHigh,
        side: BorderSide.none,
        onSelected: (_) => _setZone(tid),
      ),
    );
  }

              

  List<Widget> _buildContentSlivers(ColorScheme cs, bool gridMode) {
    if (_loading && _videos.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: LoadingIndicatorM3E()),
        ),
        _BottomSpacer(),
      ];
    }
    if (_error != null && _videos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 56,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        const _BottomSpacer(),
      ];
    }
    if (_videos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _hasActiveFilter
                      ? Icons.search_off_rounded
                      : Icons.video_library_outlined,
                  size: 56,
                  color: cs.onSurface.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 12),
                Text(
                  _hasActiveFilter ? '没有找到相关内容' : '收藏夹还是空的',
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
                if (_hasActiveFilter) ...[
                  const SizedBox(height: 4),
                  Text(
                    '换个分类或搜索词试试',
                    style: TextStyle(fontSize: 12, color: cs.outline),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonalIcon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: const Text('清除筛选'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const _BottomSpacer(),
      ];
    }
    final content = <Widget>[
      if (gridMode)
        _buildGrid(cs)
      else
        _buildSingleList(cs),
      _buildFooter(cs),
      const _BottomSpacer(),
    ];
    return content;
  }

  Widget _buildSingleList(ColorScheme cs) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final video = _videos[index];
          final isLast = index == _videos.length - 1;
          final selected = _selectedIds.contains(video.aid);
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : kCardGap),
            child: MorphItem(
              selected: selected,
              isFirst: true,
              isLast: true,
              interactive: true,
              child: _FavVideoTile(
                video: video,
                multiSelect: _multiSelect,
                selected: selected,
                onToggle: () => _toggleVideo(video),
                onLongPress: () => _enterMultiSelect(video),
                onTap: () {
                  if (_multiSelect) {
                    _toggleVideo(video);
                    return;
                  }
                  _openVideo(context, video);
                },
              ),
            ),
          );
        }, childCount: _videos.length),
      ),
    );
  }

  Widget _buildGrid(ColorScheme cs) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = (width / _gridTargetWidth)
              .floor()
              .clamp(_gridMinColumns, _gridMaxColumns);
          final cardW = (width - (columns - 1) * 12) / columns;
                                        
          final cellH = cardW * 10 / 16 + 86;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: cardW / cellH,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final video = _videos[index];
              final selected = _selectedIds.contains(video.aid);
              Widget cell = _FavVideoGridCard(
                video: video,
                onTap: () {
                  if (_multiSelect) {
                    _toggleVideo(video);
                    return;
                  }
                  _openVideo(context, video);
                },
                onLongPress: () => _enterMultiSelect(video),
              );
              if (_multiSelect) {
                cell = Stack(
                  children: [
                    cell,
                    Positioned(
                      left: 8,
                      top: 8,
                      child: GestureDetector(
                        onTap: () => _toggleVideo(video),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 22,
                            color: selected
                                ? cs.primary
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return cell;
            }, childCount: _videos.length),
          );
        },
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
                                                       
                                                           
                                                           
                                             
    if (_loadingMore) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Center(child: LoadingIndicatorM3E()),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(
            _hasMore ? '上滑加载更多' : '已全部加载',
            style: TextStyle(fontSize: 12, color: cs.outline),
          ),
        ),
      ),
    );
  }
}

                           
class _BottomSpacer extends StatelessWidget {
  const _BottomSpacer();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: MediaQuery.of(context).padding.bottom + 88,
      ),
    );
  }
}

                                               
                      
class _FavVideoTile extends StatelessWidget {
  final BiliFavVideo video;
  final VoidCallback onTap;

                               
  final bool multiSelect;
  final bool selected;
  final VoidCallback? onToggle;
  final VoidCallback? onLongPress;

  const _FavVideoTile({
    required this.video,
    required this.onTap,
    this.multiSelect = false,
    this.selected = false,
    this.onToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget card = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(kItemPressedRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (multiSelect) ...[
              Checkbox(
                value: selected,
                onChanged: (_) => onToggle?.call(),
              ),
              const SizedBox(width: 4),
            ],
            _buildCover(cs),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BilibiliTitleCache.displayTitle(video.bvid, video.title),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (video.upper.isNotEmpty)
                    Text(
                      video.upper,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (video.duration > 0) ...[
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _fmtFavDuration(video.duration),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (video.typeLabel != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          '· ${video.typeLabel}',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.primary,
                          ),
                        ),
                      ],
                      if (video.bvid.isNotEmpty) ...[
                        const SizedBox(width: 10),
                                                           
                                                          
                                     
                        Flexible(
                          child: Text(
                            video.bvid,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (video.favTime > 0) ...[
                    const SizedBox(height: 3),
                    Text(
                      _fmtFavTime(video.favTime),
                      style: TextStyle(fontSize: 11, color: cs.outline),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (multiSelect)
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.3),
              )
            else
              Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
    if (video.isUnavailable) {
      card = Opacity(opacity: 0.5, child: card);
    }
                                               
                                                 
                   
    if (video.bvid.isNotEmpty &&
        !video.isUnavailable &&
        SettingsService.heroTransitionBlurEnabled) {
      return Hero(
          transitionOnUserGestures: true,
        tag: 'bili_video_${video.bvid}',
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        child: card,
      );
    }
    return card;
  }

  Widget _buildCover(ColorScheme cs) {
    return Container(
      width: 120,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: cs.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
                                                
                              
      child: _coverImage(
        cs,
        video,
        hero: video.bvid.isNotEmpty &&
            !video.isUnavailable &&
            !SettingsService.heroTransitionBlurEnabled,
        heroTag: 'bili_video_${video.bvid}',
        thumbnail: thumbnailCoverUrl(video.cover, width: 120, height: 68),
      ),
    );
  }
}

                       
   
                                                           
                                    
Widget _coverImage(
  ColorScheme cs,
  BiliFavVideo video, {
  bool hero = false,
  String? heroTag,
  String? thumbnail,
}) {
  final url = (thumbnail != null && thumbnail.isNotEmpty)
      ? thumbnail
      : video.cover;
  Widget image = url.isNotEmpty
      ? Image(
          image: CachedImageProvider(
            url,
            headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                ? null
                : NetworkSettingsService.instance.apiHeaders,
          ),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _coverPlaceholder(cs),
        )
      : _coverPlaceholder(cs);
  if (hero && heroTag != null) {
    image = Hero(
        transitionOnUserGestures: true,
      tag: heroTag,
      child: image,
    );
  }
  return image;
}

Widget _coverPlaceholder(ColorScheme cs) {
  return Center(
    child: Icon(
      Icons.movie_outlined,
      size: 28,
      color: cs.onSurface.withValues(alpha: 0.3),
    ),
  );
}

                              
                                                     
                                    
                                         
class _FavVideoGridCard extends StatelessWidget {
  final BiliFavVideo video;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _FavVideoGridCard({
    required this.video,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final unavailable = video.isUnavailable;
    final meta = <String>[
      if (video.play > 0) '${_fmtFavCount(video.play)}播放',
      if (video.favTime > 0) _fmtFavTime(video.favTime),
    ].join(' · ');
    final subtitle = <String>[
      if (video.upper.isNotEmpty) video.upper,
      if (meta.isNotEmpty) meta,
    ].join(' · ');

    Widget card = VideoCardV(
      data: VideoCardData(
        cover: thumbnailCoverUrl(video.cover, aspect: 16 / 10),
        title: BilibiliTitleCache.displayTitle(video.bvid, video.title),
        heroTag: (video.bvid.isNotEmpty && !unavailable)
            ? 'bili_video_${video.bvid}'
            : null,
        view: video.play,
        danmaku: video.danmaku,
        duration: video.duration,
        badge: video.typeLabel,
        subtitle: subtitle,
        coverOverlay: unavailable ? const _UnavailableMask() : null,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
    if (unavailable) {
      card = Opacity(opacity: 0.5, child: card);
    }
    return card;
  }
}

                              
class _UnavailableMask extends StatelessWidget {
  const _UnavailableMask();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black38,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.link_off_rounded,
            size: 22,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 3),
          Text(
            '已失效',
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}
