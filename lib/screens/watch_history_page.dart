                                      
  
                       
                                                   
                            
                                                 
                                                 
                                         
                                     
                                               
                                          
                                                 
                                         
import 'package:flutter/material.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/services/watch_history_service.dart';
import 'package:naviflash/services/bilibili_history_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/services/webdav_service.dart';
import 'package:naviflash/services/playlist_service.dart';
import 'package:naviflash/services/cloud_sync_service.dart';
import 'package:naviflash/widgets/app_drawer.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/frosted_page_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/more_menu_sheet.dart';
import 'package:naviflash/widgets/morph_widgets.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/side_bar_menu_button.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';

class WatchHistoryPage extends StatefulWidget {
                                   
                     
  final bool drawerMode;

  const WatchHistoryPage({super.key, this.drawerMode = false});

  @override
  State<WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends State<WatchHistoryPage> {
                                    
  bool _cloudSyncing = false;

                                           
  bool _searching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _keyword = '';

                          
  bool _multiSelect = false;
  final Set<String> _selectedKeys = {};

                      
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _keyword = _searchCtrl.text.trim().toLowerCase());
    });
                             
                                                 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncCloud(manual: false);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

                                  
  List<WatchHistoryEntry> _filteredEntries(List<WatchHistoryEntry> entries) {
    if (_keyword.isEmpty) return entries;
    return entries
        .where((e) =>
            e.title.toLowerCase().contains(_keyword) ||
            (e.upperName ?? '').toLowerCase().contains(_keyword))
        .toList();
  }

  void _toggleMultiSelect() {
    HapticFeedback.lightImpact();
    setState(() {
      _multiSelect = !_multiSelect;
      if (!_multiSelect) _selectedKeys.clear();
    });
  }

                                                  
                                           
                                   
  Future<void> _syncCloud({required bool manual}) async {
    if (_cloudSyncing) return;
                                                
    if (!BilibiliHistoryService.canUse) return;
    final wh = context.read<WatchHistoryService>();
    _cloudSyncing = true;
    try {
      var added = 0;
      var updated = 0;
      var page = await BilibiliHistoryService.fetchPage();
      var pageIndex = 0;
      const maxPages = 3;                          
      while (pageIndex < maxPages) {
        if (page.err != null) {
                                                     
          debugPrint(
            '云端观看历史同步失败: ${page.err} (code ${page.code})',
          );
          return;
        }
        final stat = await wh.upsertCloudEntries(
          page.items.map((e) => e.toWatchHistoryEntry()).toList(),
        );
        added += stat.added;
        updated += stat.updated;
        pageIndex++;
                                 
        if (!manual || !page.hasMore || page.nextMax <= 0) break;
        page = await BilibiliHistoryService.fetchPage(
          max: page.nextMax,
          viewAt: page.nextViewAt,
        );
      }
      if (!mounted) return;
      if (manual) {
        showAppToast(
          context,
          added + updated > 0 ? '已同步云端观看记录' : '云端记录已是最新',
        );
      }
    } catch (e) {
      debugPrint('云端观看历史同步失败: $e');
    } finally {
      _cloudSyncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wh = context.watch<WatchHistoryService>();
    final settings = context.watch<SettingsService>();
    final entries = wh.entries;
                                 
    final visible = _filteredEntries(entries);
    final incognito = settings.incognitoMode;
    final cs = Theme.of(context).colorScheme;
                                              
    final scaffold = Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      drawer: widget.drawerMode ? const AppDrawer(currentPage: 'history') : null,
                                    
      onDrawerChanged: SideBarDrawerState.setOpen,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainerLow),
          SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                    child: _buildBody(
                        context, wh, settings, incognito, cs, visible)),
                Align(
                  alignment: Alignment.topCenter,
                  child: FrostedPageBar(
                    title: _multiSelect
                        ? '已选 ${_selectedKeys.length} 项'
                        : '观看历史',
                    drawerMode: widget.drawerMode && !_multiSelect,
                    leading: _multiSelect
                        ? MorphIconButton(
                            icon: Icons.close,
                            tooltip: '退出多选',
                            onTap: _toggleMultiSelect,
                            transparent: true,
                          )
                        : null,
                    actions: _multiSelect
                        ? [
                            MorphIconButton(
                              icon: Icons.select_all_rounded,
                              tooltip: _isAllSelected(visible)
                                  ? '取消全选'
                                  : '全选',
                              onTap: () => _toggleSelectAll(visible),
                              transparent: true,
                            ),
                            MorphIconButton(
                              icon: _deleting
                                  ? Icons.hourglass_top_rounded
                                  : Icons.delete_outline,
                              tooltip: '删除选中',
                              onTap: _selectedKeys.isEmpty || _deleting
                                  ? null
                                  : _deleteSelected,
                              transparent: true,
                            ),
                          ]
                        : [
                            MorphIconButton(
                              icon: _searching ? Icons.close : Icons.search,
                              tooltip: '搜索观看记录',
                              onTap: () {
                                setState(() {
                                  _searching = !_searching;
                                  if (!_searching) _searchCtrl.clear();
                                });
                              },
                              transparent: true,
                            ),
                                                           
                            LiquidGlassMenuButton(
                              icon: Icons.more_vert,
                              tooltip: '更多',
                              transparent: true,
                              actions: [
                                GlassMenuAction(
                                  icon: Icons.checklist_rounded,
                                  text: '多选',
                                  onTap: _toggleMultiSelect,
                                ),
                                GlassMenuAction(icon: Icons.cloud_upload_outlined, text: '上传到云端', onTap: () => _doSync(context, 'upload')),
                                GlassMenuAction(icon: Icons.sync_rounded, text: '双向同步', onTap: () => _doSync(context, 'sync')),
                                GlassMenuAction(icon: Icons.cloud_download_outlined, text: '从云端恢复', onTap: () => _doSync(context, 'restore')),
                                GlassMenuAction(
                                  icon: incognito ? Icons.visibility_off : Icons.visibility,
                                  text: incognito ? '关闭无痕模式' : '开启无痕模式',
                                  onTap: () => settings.setIncognitoMode(!incognito),
                                ),
                                if (entries.isNotEmpty)
                                  GlassMenuAction(
                                    icon: Icons.delete_sweep_outlined,
                                    text: '清空观看历史',
                                    isDestructive: true,
                                    onTap: () => _confirmClearAll(context, wh),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 4),
                          ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
                            
    return IosBackdropScale(child: scaffold);
  }

                          
  bool _isAllSelected(List<WatchHistoryEntry> visible) =>
      visible.isNotEmpty && _selectedKeys.length >= visible.length;

  void _toggleSelectAll(List<WatchHistoryEntry> visible) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isAllSelected(visible)) {
        _selectedKeys.clear();
      } else {
        _selectedKeys
          ..clear()
          ..addAll(visible.map((e) => e.key));
      }
    });
  }

                                            
                         
  Future<void> _deleteSelected() async {
    if (_selectedKeys.isEmpty || _deleting) return;
    final wh = context.read<WatchHistoryService>();
    final selected =
        wh.entries.where((e) => _selectedKeys.contains(e.key)).toList();
    if (selected.isEmpty) return;
    final cloudKids = selected
        .where((e) => e.aid != null && e.aid! > 0)
        .map((e) => BilibiliHistoryService.buildKid('archive', e.aid!))
        .toList();
    final hasCloud = BilibiliHistoryService.canUse && cloudKids.isNotEmpty;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除选中记录'),
        content: Text(
          '将删除选中的 ${selected.length} 条观看记录'
          '${hasCloud ? '，并同步删除 B 站账号的云端观看历史' : ''}。'
          '云端记录删除后不可恢复，确定继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
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
    setState(() => _deleting = true);
    String? cloudErr;
    if (hasCloud) {
      final r = await BilibiliHistoryService.deleteItems(cloudKids);
      if (!r.ok) cloudErr = r.message;
    }
    for (final e in selected) {
      await wh.removeByKey(e.key);
    }
    if (!mounted) return;
    setState(() {
      _selectedKeys.clear();
      _multiSelect = false;
      _deleting = false;
    });
    showAppToast(
      context,
      cloudErr == null
          ? '已删除 ${selected.length} 条记录'
          : '本地已删除，云端删除失败：$cloudErr',
      error: cloudErr != null,
    );
  }

                                
  Future<void> _deleteSingle(WatchHistoryEntry entry) async {
    final hasCloud = BilibiliHistoryService.canUse &&
        entry.aid != null &&
        entry.aid! > 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: Text(
          '确定删除「${entry.title}」的观看记录'
          '${hasCloud ? '（含 B 站云端记录）' : ''}吗？',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
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
    String? cloudErr;
    if (hasCloud) {
      final r = await BilibiliHistoryService.deleteItem(
        BilibiliHistoryService.buildKid('archive', entry.aid!),
      );
      if (!r.ok) cloudErr = r.message;
    }
    if (!mounted) return;
    await context.read<WatchHistoryService>().removeByKey(entry.key);
    if (!mounted) return;
    _selectedKeys.remove(entry.key);
    showAppToast(
      context,
      cloudErr == null ? '已删除' : '本地已删除，云端删除失败：$cloudErr',
      error: cloudErr != null,
    );
  }

                              
  void _showEntryMenu(WatchHistoryEntry entry) {
    HapticFeedback.mediumImpact();
    showMoreMenuSheet(
      context: context,
      actions: [
        MoreMenuAction(
          icon: Icons.play_arrow_rounded,
          label: '播放',
          onTap: () => _openEntry(context, entry),
        ),
        MoreMenuAction(
          icon: Icons.checklist_rounded,
          label: '多选',
          onTap: () {
            setState(() {
              _multiSelect = true;
              _selectedKeys.add(entry.key);
            });
          },
        ),
        MoreMenuAction(
          icon: Icons.delete_outline,
          label: '删除该记录',
          onTap: () => _deleteSingle(entry),
        ),
      ],
    );
  }

  void _openEntry(BuildContext context, WatchHistoryEntry entry) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BilibiliVideoPage(
        bvid: entry.bvid,
        initialTitle: entry.title,
        initialCover: entry.coverUrl,
      ),
    ));
  }

                                     
  Widget _buildBody(
    BuildContext context,
    WatchHistoryService wh,
    SettingsService settings,
    bool incognito,
    ColorScheme cs,
    List<WatchHistoryEntry> visible,
  ) {
    final entries = wh.entries;
    return AppRefreshIndicator(
                                         
                            
      displacement: kFrostedPageBarHeight + 10,
      edgeOffset: 0,
      onRefresh: () => _syncCloud(manual: true),
      child: CustomScrollView(
                                                        
        physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
                                                        
          const SliverToBoxAdapter(
            child: SizedBox(height: kFrostedPageBarHeight),
          ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                                          
                        if (_searching)
                          TextField(
                            controller: _searchCtrl,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: '搜索标题 / UP 主',
                              prefixIcon: const Icon(Icons.search, size: 22),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _searching = false;
                                    _searchCtrl.clear();
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: cs.surfaceContainerHighest,
                            ),
                          ),
                        if (incognito) ...[
                          if (_searching) const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.shield_outlined, size: 20, color: cs.primary),
                                const SizedBox(width: 10),
                                Expanded(child: Text('无痕模式已开启，观看视频不会留下任何记录', style: Theme.of(context).textTheme.bodySmall)),
                              ],
                            ),
                          ),
                        ],
                        if (!_searching) const SizedBox(height: 16),
                        if (visible.isNotEmpty) ...[
                          _buildSectionTitle(context, '观看记录 · ${visible.length}'),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
                if (entries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_rounded, size: 72, color: cs.onSurface.withValues(alpha: 0.25)),
                          const SizedBox(height: 16),
                          Text(incognito ? '无痕模式中' : '暂无观看历史', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
                          const SizedBox(height: 8),
                          Text(incognito ? '关闭无痕后将恢复记录' : '看过的 B 站视频会显示在这里', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.35))),
                        ],
                      ),
                    ),
                  )
                else if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 56, color: cs.onSurface.withValues(alpha: 0.25)),
                          const SizedBox(height: 12),
                          Text('没有找到匹配的记录', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                  ),
                if (visible.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = visible[index];
                          final isFirst = index == 0;
                          final isLast = index == visible.length - 1;
                          final selected = _selectedKeys.contains(entry.key);
                          return Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : kCardGap),
                            child: MorphItem(
                              selected: selected,
                              isFirst: isFirst,
                              isLast: isLast,
                              child: _EntryTile(
                                entry: entry,
                                multiSelect: _multiSelect,
                                selected: selected,
                                onToggle: () {
                                  setState(() {
                                    if (selected) {
                                      _selectedKeys.remove(entry.key);
                                    } else {
                                      _selectedKeys.add(entry.key);
                                    }
                                  });
                                },
                                onLongPress: () => _showEntryMenu(entry),
                              ),
                            ),
                          );
                        },
                        childCount: visible.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
      );
  }

  Future<void> _doSync(BuildContext context, String action) async {
    final wh = context.read<WatchHistoryService>();
    final webdav = context.read<WebDavService>();
                                                           
    final playlists = context.read<PlaylistService>();
    final sync = CloudSyncService(webdav: webdav, playlists: playlists);
    CloudSyncResult r;
    switch (action) {
      case 'upload':
        r = await sync.pushWatchHistory(wh);
        break;
      case 'restore':
        r = await sync.syncWatchHistory(wh, restoreFromCloud: true);
        break;
      default:
        r = await sync.syncWatchHistory(wh);
    }
    if (!context.mounted) return;
    showAppToast(context, r.message, error: !r.ok);
  }

                                          
  Future<void> _confirmClearAll(BuildContext context, WatchHistoryService wh) async {
    final clearCloud = BilibiliHistoryService.canUse;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空观看历史'),
        content: Text(
          '将删除本地全部 ${wh.entries.length} 条观看记录'
          '${clearCloud ? '，并清空 B 站账号的云端观看历史' : ''}。\n\n'
          '此操作不可撤销，云端记录删除后无法找回。确定继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    String? cloudErr;
    if (clearCloud) {
      final r = await BilibiliHistoryService.clearAll();
      if (!r.ok) cloudErr = r.message;
    }
    await wh.clearAll();
    if (!context.mounted) return;
    showAppToast(
      context,
      cloudErr == null ? '已清空' : '本地已清空，云端清空失败：$cloudErr',
      error: cloudErr != null,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final WatchHistoryEntry entry;

                                  
  final bool multiSelect;
  final bool selected;
  final VoidCallback? onToggle;
  final VoidCallback? onLongPress;

  const _EntryTile({
    required this.entry,
    this.multiSelect = false,
    this.selected = false,
    this.onToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        if (multiSelect) {
          onToggle?.call();
          return;
        }
        _openVideo(context);
      },
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(kItemPressedRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            if (multiSelect) ...[
              Checkbox(
                value: selected,
                onChanged: (_) => onToggle?.call(),
              ),
              const SizedBox(width: 4),
            ],
            _buildThumbnail(cs),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((entry.upperName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'UP: ${entry.upperName}',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: entry.progress,
                      minHeight: 3,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                          entry.finished ? cs.tertiary : cs.primary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (entry.finished)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(Icons.check_circle,
                              size: 14, color: cs.tertiary),
                        ),
                      Expanded(
                        child: Text(
                          _formatWatchedTime(entry.watchedAt),
                          style: textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        entry.bvid,
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.35),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (multiSelect)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.3),
                  size: 22,
                ),
              )
            else ...[
              IconButton(
                icon: Icon(Icons.play_circle_filled_rounded,
                    color: cs.primary, size: 36),
                tooltip: '播放',
                onPressed: () => _openVideo(context),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    color: cs.onSurface.withValues(alpha: 0.4), size: 20),
                tooltip: '删除',
                onPressed: () =>
                    context.read<WatchHistoryService>().removeByKey(entry.key),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(ColorScheme cs) {
    final url = entry.coverUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 112,
        height: 63,        
        child: (url != null && url.isNotEmpty)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(cs),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _placeholder(cs),
              )
            : _placeholder(cs),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.play_circle_outline,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4), size: 28),
      );

  void _openVideo(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BilibiliVideoPage(
        bvid: entry.bvid,
        initialTitle: entry.title,
        initialCover: entry.coverUrl,
      ),
    ));
  }

  String _formatWatchedTime(DateTime t) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(t.year, t.month, t.day));
    String two(int n) => n.toString().padLeft(2, '0');
    final hm = '${two(t.hour)}:${two(t.minute)}';
    if (diff.inDays == 0) return '今天 $hm';
    if (diff.inDays == 1) return '昨天 $hm';
    if (diff.inDays < 7) return '${diff.inDays}天前 $hm';
    if (now.year == t.year) return '${two(t.month)}-${two(t.day)} $hm';
    return '${t.year}-${two(t.month)}-${two(t.day)}';
  }
}
