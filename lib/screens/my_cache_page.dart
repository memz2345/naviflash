                                 
  
                                   
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/video_cache_service.dart';
import 'package:naviflash/services/manual_video_cache.dart';
import 'package:naviflash/services/native_menu_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/more_menu_sheet.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/frosted_page_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/app_drawer.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/side_bar_menu_button.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

class MyCachePage extends StatefulWidget {
                                       
                       
  final bool embeddedInShell;

                                   
                     
  final bool drawerMode;

  const MyCachePage({
    super.key,
    this.embeddedInShell = false,
    this.drawerMode = false,
  });

  @override
  State<MyCachePage> createState() => _MyCachePageState();
}

class _MyCachePageState extends State<MyCachePage> {
  List<VideoStreamCacheEntry>? _entries;
  Map<String, List<VideoStreamCacheEntry>> _grouped = {};
  bool _loading = true;

  bool _searching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _keyword = '';

  bool _multiSelect = false;
  final Set<String> _selectedBvids = {};
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _keyword = _searchCtrl.text.trim().toLowerCase());
    });
    _refresh();
    VideoStreamCache.queueVersion.addListener(_onQueueVersion);
                                
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (ManualVideoCache.allPendingCount > 0 && mounted) {
        setState(() {});
      }
    });
  }

  void _onQueueVersion() {
    if (!mounted) return;
    setState(() {});
    _refresh();
  }

  @override
  void dispose() {
    VideoStreamCache.queueVersion.removeListener(_onQueueVersion);
    _pollTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool viaRefresh = false}) async {
                                        
                               
                             
    setState(() => _loading = _entries == null && !viaRefresh);
                                                       
    final entries = await ManualVideoCache.listAllEntries();
    final grouped = <String, List<VideoStreamCacheEntry>>{};
    for (final e in entries) {
      grouped.putIfAbsent(e.bvid, () => []).add(e);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.cid.compareTo(b.cid));
    }
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _grouped = grouped;
      _loading = false;
    });
  }

  Future<void> _handleRefresh() async {
    await _refresh(viaRefresh: true);
  }

  List<String> get _filteredBvids {
    if (_keyword.isEmpty) return _grouped.keys.toList();
    return _grouped.entries
        .where((kv) =>
            kv.key.toLowerCase().contains(_keyword) ||
            kv.value.any((e) => e.bvid.toLowerCase().contains(_keyword)))
        .map((e) => e.key)
        .toList();
  }

  int get _totalSize {
    int s = 0;
    for (final e in _entries ?? <VideoStreamCacheEntry>[]) {
      s += e.bytes;
    }
    return s;
  }

  String _size(int bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  void _toggleMultiSelect() {
    HapticFeedback.lightImpact();
    setState(() {
      _multiSelect = !_multiSelect;
      if (!_multiSelect) _selectedBvids.clear();
    });
  }

  Future<void> _deleteGroup(String bvid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.current.myCacheDeleteGroup),
        content: Text('确定删除 $bvid 下的全部缓存视频吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(L10n.current.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ManualVideoCache.deleteByBvidAny(bvid);
    _selectedBvids.remove(bvid);
    await _refresh();
    if (!mounted) return;
    showAppToast(context, '已删除 $bvid');
  }

  Future<void> _deleteSingle(VideoStreamCacheEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除缓存'),
        content: Text('确定删除 ${e.bvid}（cid ${e.cid}）的缓存吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    await ManualVideoCache.deleteEntryAny(e);
    await _refresh();
    if (!mounted) return;
    showAppToast(context, '已删除 ${e.bvid}');
  }

  Future<void> _deleteSelected() async {
    if (_selectedBvids.isEmpty) return;
    final count = _selectedBvids.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.current.historyDeleteSelected),
        content: Text('确定删除选中的 $count 组缓存吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(L10n.current.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    for (final bvid in _selectedBvids.toList()) {
      await ManualVideoCache.deleteByBvidAny(bvid);
    }
    _selectedBvids.clear();
    setState(() => _multiSelect = false);
    await _refresh();
    if (!mounted) return;
    showAppToast(context, L10n.current.historyDeleteToast(count));
  }

  Future<void> _clearAll() async {
    final entries = _entries ?? [];
    if (entries.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.current.myCacheClearAllTitle),
        content: Text(L10n.current.myCacheClearAllConfirm(entries.length, _size(_totalSize))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(L10n.current.commonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(L10n.current.storageClear),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ManualVideoCache.clearAllBoth();
    await _refresh();
    if (!mounted) return;
    showAppToast(context, L10n.current.storageCleared(L10n.current.myCacheTitle));
  }

  bool get _isAllSelected =>
      _filteredBvids.isNotEmpty && _selectedBvids.length == _filteredBvids.length;

  void _selectAll() {
    setState(() {
      _multiSelect = true;
      _selectedBvids
        ..clear()
        ..addAll(_filteredBvids);
    });
    HapticFeedback.lightImpact();
    showAppToast(context, '已全选 ${_selectedBvids.length} 组');
  }

  void _deselectAll() {
    setState(() => _selectedBvids.clear());
    HapticFeedback.lightImpact();
    showAppToast(context, '已取消全选');
  }

  void _handleFabTap() {
    if (!_multiSelect) {
               
      HapticFeedback.lightImpact();
      setState(() => _multiSelect = true);
    } else {
                           
      if (_selectedBvids.isEmpty) {
        showAppToast(context, '未选择任何缓存');
        return;
      }
      _deleteSelected();
    }
  }

  void _handleFabLongPress() {
    if (_multiSelect) {
                                      
      if (_isAllSelected) {
        _deselectAll();
      } else {
                           
        showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(L10n.current.myCacheClearAllTitle),
            content: Text('是否清空全部缓存？\n将删除全部 ${_entries?.length ?? 0} 个视频 · ${_size(_totalSize)}'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(L10n.current.commonCancel)),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(L10n.current.storageClear),
              ),
            ],
          ),
        ).then((ok) {
          if (ok == true) _clearAll();
        });
      }
    } else {
                                
                                           
                                        
                                  
      if (_isAllSelected) {
        _deselectAll();
      } else {
        _selectAll();
      }
    }
  }

  Widget _buildFab(ColorScheme cs) {
    IconData icon;
    String label;
    String tooltip;
    if (!_multiSelect) {
      icon = Icons.checklist_rounded;
      label = '多选';
      tooltip = '多选（长按全选）';
    } else {
                            
      if (_selectedBvids.isNotEmpty) {
        icon = Icons.delete_outline;
        label = '清除 (${_selectedBvids.length})';
        tooltip = '清除选中（长按全部清除）';
      } else {
        icon = Icons.close_rounded;
        label = '退出多选';
        tooltip = '退出多选（长按全选）';
      }
    }
                                                
                                        
    return Semantics(
      onLongPress: _handleFabLongPress,
      onLongPressHint: tooltip,
      child: GestureDetector(
        onLongPress: _handleFabLongPress,
        child: FloatingActionButton.extended(
          heroTag: 'my_cache_fab',
          tooltip: tooltip,
          backgroundColor: _multiSelect
              ? cs.errorContainer
              : cs.primaryContainer,
          foregroundColor: _multiSelect
              ? cs.onErrorContainer
              : cs.onPrimaryContainer,
          onPressed: _handleFabTap,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bvids = _filteredBvids;
    final pendingCount = ManualVideoCache.allPendingCount;

                                   
    final scaffold = Scaffold(
      backgroundColor: widget.embeddedInShell
          ? Colors.transparent
          : cs.surfaceContainerLow,
      drawer: widget.drawerMode && !widget.embeddedInShell
          ? const AppDrawer(currentPage: 'cache')
          : null,
                                    
      onDrawerChanged: SideBarDrawerState.setOpen,
      floatingActionButton: _buildFab(cs),
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainerLow),
          SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
                                                    
          const SliverToBoxAdapter(
            child: SizedBox(height: kFrostedPageBarHeight),
          ),
          if (_searching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: L10n.current.myCacheSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _searching = false;
                          _searchCtrl.clear();
                        });
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
          if (pendingCount > 0)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${L10n.current.myCacheDownloading} ($pendingCount)',
                        style: TextStyle(color: cs.onPrimaryContainer, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      _size(_totalSize),
                      style: TextStyle(color: cs.onPrimaryContainer.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

        ],
        body: _loading
            ? const Center(child: LoadingIndicatorM3E())
            : (_entries == null || _entries!.isEmpty)
                ? _empty(cs)
                : bvids.isEmpty
                    ? _empty(cs, msg: L10n.current.historySearchNoResult)
                    : AppRefreshIndicator(
                        color: cs.primary,
                        onRefresh: _handleRefresh,
                        child: SingleChildScrollView(
                          physics: const AppRefreshScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 84),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSectionTitle(context, '已缓存 · ${bvids.length} 组 · ${_size(_totalSize)}'),
                              const SizedBox(height: 12),
                              ...List.generate(bvids.length, (index) {
                                final bvid = bvids[index];
                                final list = _grouped[bvid]!;
                                final isSelected = _selectedBvids.contains(bvid);
                                return Padding(
                                  padding: EdgeInsets.only(bottom: index == bvids.length - 1 ? 0 : kCardGap),
                                  child: MorphItem(
                                    selected: isSelected,
                                    isFirst: index == 0,
                                    isLast: index == bvids.length - 1,
                                    child: _buildGroupCardContent(cs, bvid, list, isSelected: isSelected),
                                  ),
                                );
                              }),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
      ),
                ),
                                               
                Align(
                  alignment: Alignment.topCenter,
                  child: FrostedPageBar(
                    title: _multiSelect
                        ? L10n.current.historySelectedCount(_selectedBvids.length)
                        : L10n.current.myCacheTitle,
                    drawerMode: widget.drawerMode,
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
                              icon: Icons.delete_outline,
                              tooltip: '删除',
                              onTap: _selectedBvids.isEmpty
                                  ? null
                                  : _deleteSelected,
                              transparent: true,
                            ),
                          ]
                        : [
                                                         
                            MorphIconButton(
                              icon: _searching ? Icons.close : Icons.search,
                              tooltip: L10n.current.myCacheSearchHint,
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
                                  icon: Icons.checklist,
                                  text: '多选',
                                  onTap: _toggleMultiSelect,
                                ),
                                GlassMenuAction(
                                  icon: Icons.refresh_rounded,
                                  text: L10n.current.refreshAction,
                                  onTap: _refresh,
                                ),
                                GlassMenuAction(
                                  icon: Icons.delete_sweep_outlined,
                                  text: L10n.current.myCacheClearAllTitle,
                                  isDestructive: true,
                                  onTap: _clearAll,
                                ),
                              ],
                            ),
                          ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _multiSelect ? _buildBottomBar(cs) : null,
    );
                                         
    return widget.embeddedInShell
        ? scaffold
        : IosBackdropScale(child: scaffold);
  }

  Widget _buildBottomBar(ColorScheme cs) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(L10n.current.historySelectedCount(_selectedBvids.length))),
            FilledButton.icon(
              onPressed: _selectedBvids.isEmpty ? null : _deleteSelected,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(L10n.current.historyDeleteSelected),
              style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
            ),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _toggleMultiSelect, child: Text(L10n.current.commonCancel)),
          ],
        ),
      ),
    );
  }

  Widget _empty(ColorScheme cs, {String? msg}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(msg ?? L10n.current.myCacheNoCache, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text('观看视频数秒后自动缓存到本地', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildGroupCardContent(ColorScheme cs, String bvid, List<VideoStreamCacheEntry> list, {required bool isSelected}) {
    final cover = list.first.cover;
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty ? null : NetworkSettingsService.instance.apiHeaders;
    int totalBytes = 0;
    for (final e in list) {
      totalBytes += e.bytes;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (_multiSelect) {
            setState(() {
              if (isSelected) {
                _selectedBvids.remove(bvid);
              } else {
                _selectedBvids.add(bvid);
              }
            });
            return;
          }
          openBilibiliVideo(context, bvid: bvid, initialCover: cover.isNotEmpty ? cover : null);
        },
        onLongPress: () {
          if (_multiSelect) return;
          HapticFeedback.mediumImpact();
          _showGroupMenu(bvid, list);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          child: Row(
            children: [
              if (_multiSelect)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) {
                      setState(() {
                        if (isSelected) {
                          _selectedBvids.remove(bvid);
                        } else {
                          _selectedBvids.add(bvid);
                        }
                      });
                    },
                  ),
                ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 112,
                      height: 64,
                      child: cover.isNotEmpty
                          ? Image(
                              image: CachedImageProvider(
                                BilibiliUserSpaceService.coverUrl(cover),
                                headers: headers,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _coverFallback(cs),
                            )
                          : _coverFallback(cs),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        L10n.current.myCacheGroupCount(list.length),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bvid,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    const SizedBox(height: 4),
                    Text(
                      '${_size(totalBytes)}  ·  ${_qnLabel(list.first.qn)}',
                      style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final e in list.take(6))
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              openBilibiliVideo(context, bvid: e.bvid, initialCover: e.cover);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('cid ${e.cid}',
                                      style: TextStyle(fontSize: 10, color: cs.onSecondaryContainer)),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => _deleteSingle(e),
                                    child: Icon(Icons.close, size: 10, color: cs.onSecondaryContainer),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (list.length > 6)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('+${list.length - 6}',
                                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_multiSelect)
                LiquidGlassMenuButton(
                  icon: Icons.more_vert,
                  size: 32,
                  iconSize: 18,
                  actions: [
                    GlassMenuAction(
                      icon: Icons.play_arrow_rounded,
                      text: L10n.current.webdavPlay,
                      onTap: () => openBilibiliVideo(context, bvid: bvid),
                    ),
                    GlassMenuAction(
                      icon: Icons.delete_outline,
                      text: L10n.current.myCacheDeleteGroup,
                      isDestructive: true,
                      onTap: () => _deleteGroup(bvid),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showGroupMenu(
    String bvid,
    List<VideoStreamCacheEntry> list,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      items: [
        NativeMenuItem(
          text: L10n.current.webdavPlay,
          icon: Icons.open_in_new,
          onTap: () => openBilibiliVideo(context, bvid: bvid),
        ),
        NativeMenuItem(
          text: '删除整组',
          icon: Icons.delete_outline,
          destructive: true,
          onTap: () => _deleteGroup(bvid),
        ),
      ],
    );
    if (nativeOk || !mounted) return;
    showAppBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: GlassMenuSurface(
          radius: 24,
          blur: 12,
          tintOpacity: 0.12,
          lightIntensity: 0.2,
          stretch: 0.3,
          legacyClipRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          legacyDecoration: BoxDecoration(
            color: (Theme.of(ctx).brightness == Brightness.dark
                    ? cs.surfaceContainerHigh
                    : cs.surfaceContainerLow)
                .withValues(alpha: 0.85),
            border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
          ),
          content: Column(
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    openBilibiliVideo(context, bvid: bvid);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new, size: 20, color: cs.onSurfaceVariant),
                        const SizedBox(width: 14),
                        Text(L10n.current.webdavPlay, style: TextStyle(fontSize: 14, color: cs.onSurface)),
                      ],
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteGroup(bvid);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        const SizedBox(width: 14),
                        const Text('删除整组', style: TextStyle(fontSize: 14, color: Colors.red)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverFallback(ColorScheme cs) => Container(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        child: const Icon(Icons.play_circle_outline, size: 30),
      );

  String _qnLabel(int qn) {
    if (qn <= 0) return '自动';
    if (qn >= 10000) return '4K';
    if (qn >= 8000) return '1080P60';
    if (qn >= 6000) return '1080P';
    if (qn >= 4000) return '720P';
    return '${qn}P';
  }
}
