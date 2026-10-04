                                       
  
                               
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/services/watch_history_service.dart';
import 'package:naviflash/services/bilibili_history_service.dart';
import 'package:naviflash/services/play_history_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/screens/player.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/glass_bottom_bar.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/standard_list_page.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/navi_spring_physics.dart';
import 'package:naviflash/widgets/video_card.dart';

class HistoryCenterPage extends StatefulWidget {
  final int initialTab;                   

                                       
                       
  final bool embeddedInShell;

  const HistoryCenterPage({
    super.key,
    this.initialTab = 0,
    this.embeddedInShell = false,
  });

  @override
  State<HistoryCenterPage> createState() => _HistoryCenterPageState();
}

class _HistoryCenterPageState extends State<HistoryCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _searching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _keyword = '';

  bool _multiSelect = false;
  final Set<String> _selectedWatchKeys = {};
  final Set<String> _selectedPlayIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        if (_multiSelect) {
          setState(() {
            _multiSelect = false;
            _selectedWatchKeys.clear();
            _selectedPlayIds.clear();
          });
        }
        return;
      }
                  
      if (mounted) setState(() {});
      if (_multiSelect) {
        setState(() {
          _multiSelect = false;
          _selectedWatchKeys.clear();
          _selectedPlayIds.clear();
        });
      }
    });
    _searchCtrl.addListener(() {
      setState(() => _keyword = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchCtrl.clear();
        _keyword = '';
      }
    });
  }

  void _toggleMultiSelect() {
    HapticFeedback.lightImpact();
    setState(() {
      _multiSelect = !_multiSelect;
      if (!_multiSelect) {
        _selectedWatchKeys.clear();
        _selectedPlayIds.clear();
      }
    });
  }

  Future<void> _clearCurrent() async {
    final isWatch = _tabController.index == 0;
    final l10n = AppLocalizations.of(context);
    final label = isWatch ? l10n.historyTabWatch : l10n.historyTabPlay;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.historyClearAllTitle),
        content: Text(l10n.historyClearAllConfirm(label)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.storageClear),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (isWatch) {
      await context.read<WatchHistoryService>().clearAll();
    } else {
      await context.read<PlayHistoryService>().clearAll();
    }
    if (!mounted) return;
    showAppToast(context, l10n.storageCleared(label));
    setState(() {
      _multiSelect = false;
      _selectedWatchKeys.clear();
      _selectedPlayIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final isWatch = _tabController.index == 0;
    if (isWatch) {
      final svc = context.read<WatchHistoryService>();
                                      
      final byKey = {for (final e in svc.entries) e.key: e};
      final kids = <String>[];
      for (final k in _selectedWatchKeys.toList()) {
        final aid = byKey[k]?.aid ?? 0;
        if (aid > 0) kids.add(BilibiliHistoryService.buildKid('archive', aid));
      }
      if (kids.isNotEmpty) {
        await BilibiliHistoryService.deleteItems(kids);
      }
      for (final k in _selectedWatchKeys.toList()) {
        await svc.removeByKey(k);
      }
    } else {
      final svc = context.read<PlayHistoryService>();
      for (final id in _selectedPlayIds.toList()) {
        await svc.removeById(id);
      }
    }
    final count =
        isWatch ? _selectedWatchKeys.length : _selectedPlayIds.length;
    if (!mounted) return;
    showAppToast(context, L10n.current.historyDeleteToast(count));
    setState(() {
      _multiSelect = false;
      _selectedWatchKeys.clear();
      _selectedPlayIds.clear();
    });
  }

  Future<void> _handleWatchRefresh() async {
                                          
                                                  
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() {});
  }

  Future<void> _handlePlayRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsService>();
    final paused = settings.incognitoMode;

                                          
                                                 
    return StandardListScaffold(
      extendBody: true,
      topBar: _buildStdTopBar(l10n, cs),
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, _) => [
              topBarSpaceSliver(kStdTopBarHeight),
              if (_searching) _buildSearchBar(cs),
              if (paused) _buildPauseTip(cs),
            ],
            body: naviTabBarView(
              controller: _tabController,
                                                 
                                               
                                      
              physics: _multiSelect
                  ? const NeverScrollableScrollPhysics()
                  : const NaviTabBarViewScrollPhysics(),
              children: [
                _buildWatchTab(),
                _buildPlayTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _multiSelect
          ? _buildBottomBar(l10n, cs)
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: AppBottomBar(
                  tabs: [
                    GlassBottomBarTab(
                      label: l10n.historyTabWatch,
                      icon: Icons.history_outlined,
                      selectedIcon: Icons.history,
                    ),
                    GlassBottomBarTab(
                      label: l10n.historyTabPlay,
                      icon: Icons.play_circle_outline,
                      selectedIcon: Icons.play_circle,
                    ),
                  ],
                  selectedIndex: _tabController.index,
                  onTabSelected: (i) {
                    if (_tabController.index == i) return;
                    setState(() => _tabController.index = i);
                  },
                ),
              ),
            ),
    );
  }

                                       
  Widget _buildStdTopBar(AppLocalizations l10n, ColorScheme cs) {
    final paused = context.watch<SettingsService>().incognitoMode;
    final title = _multiSelect
        ? l10n.historySelectedCount(
            _tabController.index == 0
                ? _selectedWatchKeys.length
                : _selectedPlayIds.length,
          )
        : l10n.historyCenterTitle;
    final Widget? titleWidget = _searching && !_multiSelect
        ? TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.historySearchHint,
              border: InputBorder.none,
              isDense: true,
              hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
            ),
            style: TextStyle(color: cs.onSurface, fontSize: 15),
          )
        : null;
    return StandardListTopBar(
      title: title,
      titleWidget: titleWidget,
      showBack: !widget.embeddedInShell,
      onBack: _multiSelect
          ? _toggleMultiSelect
          : () => Navigator.of(context).maybePop(),
      actions: _multiSelect
          ? [
              MorphIconButton(
                icon: Icons.delete_outline,
                tooltip: l10n.historyDeleteSelected,
                onTap: (_tabController.index == 0
                        ? _selectedWatchKeys.isEmpty
                        : _selectedPlayIds.isEmpty)
                    ? null
                    : _deleteSelected,
                frosted: true,
              ),
            ]
          : [
              MorphIconButton(
                icon: _searching ? Icons.close : Icons.search,
                tooltip: l10n.historySearchHint,
                onTap: _toggleSearch,
                frosted: true,
              ),
              MorphIconButton(
                icon: Icons.checklist,
                tooltip: '多选',
                onTap: _toggleMultiSelect,
                frosted: true,
              ),
              LiquidGlassMenuButton(
                icon: Icons.more_vert,
                tooltip: '更多',
                actions: _historyMenuActions(paused),
              ),
            ],
    );
  }

                                   
  List<GlassMenuAction> _historyMenuActions(bool paused) => [
    GlassMenuAction(
      icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
      text: paused
          ? L10n.current.historyResumeHistory
          : L10n.current.historyPauseHistory,
      onTap: () async {
        final newVal = !paused;
        await context.read<SettingsService>().setIncognitoMode(newVal);
        if (!mounted) return;
        showAppToast(
          context,
          newVal
              ? L10n.current.historyPauseOnSnack
              : L10n.current.historyResumeOnSnack,
        );
      },
    ),
    GlassMenuAction(
      icon: Icons.delete_sweep_outlined,
      text: _tabController.index == 0
          ? L10n.current.historyClearWatchHistory
          : L10n.current.historyClearPlayHistory,
      onTap: _clearCurrent,
    ),
    GlassMenuAction(
      icon: Icons.done_all_rounded,
      text: '删除已看完',
      onTap: _deleteFinished,
    ),
  ];

                       
  Future<void> _deleteFinished() async {
    if (_tabController.index == 0) {
      final svc = context.read<WatchHistoryService>();
      final finished = svc.entries
          .where((e) => e.finished)
          .map((e) => e.key)
          .toList();
      for (final k in finished) {
        await svc.removeByKey(k);
      }
      if (!mounted) return;
      showAppToast(context, L10n.current.historyDeleteToast(finished.length));
    } else {
      final svc = context.read<PlayHistoryService>();
      final finished = svc.records
          .where((e) => e.isFinished)
          .map((e) => e.id)
          .toList();
      for (final id in finished) {
        await svc.removeById(id);
      }
      if (!mounted) return;
      showAppToast(context, L10n.current.historyDeleteToast(finished.length));
    }
  }



  Widget _buildSearchBar(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.historySearchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSearch,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: cs.surfaceContainerHighest,
          ),
        ),
      ),
    );
  }

  Widget _buildPauseTip(ColorScheme cs) {
    return SliverToBoxAdapter(
      child: Container(
        height: 38,
        color: cs.secondaryContainer.withValues(alpha: 0.8),
        padding: const EdgeInsets.only(left: 16, right: 6),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: cs.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                L10n.current.historyPausedTip,
                style: TextStyle(color: cs.onSecondaryContainer, fontSize: 13),
              ),
            ),
            GestureDetector(
              onTap: () async {
                await context.read<SettingsService>().setIncognitoMode(false);
                if (!mounted) return;
                showAppToast(context, L10n.current.historyResumeOnSnack);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(L10n.current.historyPausedTipAction,
                    style: TextStyle(color: cs.primary, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n, ColorScheme cs) {
    final count = _tabController.index == 0
        ? _selectedWatchKeys.length
        : _selectedPlayIds.length;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(l10n.historySelectedCount(count),
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ),
            FilledButton.icon(
              onPressed: count == 0 ? null : _deleteSelected,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(l10n.historyDeleteSelected),
              style: FilledButton.styleFrom(
                  backgroundColor: cs.error, foregroundColor: cs.onError),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _toggleMultiSelect,
              child: Text(l10n.commonCancel),
            ),
          ],
        ),
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

  Widget _buildWatchTab() {
    final entries = context.watch<WatchHistoryService>().entries;
    final filtered = _keyword.isEmpty
        ? entries
        : entries
            .where((e) =>
                e.title.toLowerCase().contains(_keyword) ||
                e.bvid.toLowerCase().contains(_keyword) ||
                (e.upperName ?? '').toLowerCase().contains(_keyword))
            .toList();

    if (entries.isEmpty) {
      return _empty(L10n.current.historyNoWatchHistory, Icons.history);
    }
    if (filtered.isEmpty) {
      return _empty(L10n.current.historySearchNoResult, Icons.search_off);
    }
    return AppRefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: _handleWatchRefresh,
      child: SingleChildScrollView(
        physics: const AppRefreshScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 84),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(context, '${AppLocalizations.of(context).historyTabWatch} · ${filtered.length}'),
            const SizedBox(height: 12),
            ...List.generate(filtered.length, (i) {
              final e = filtered[i];
              final selected = _selectedWatchKeys.contains(e.key);
              return Padding(
                padding: EdgeInsets.only(bottom: i == filtered.length - 1 ? 0 : kCardGap),
                child: MorphItem(
                  selected: selected,
                  isFirst: i == 0,
                  isLast: i == filtered.length - 1,
                  child: _WatchTileContent(
                    entry: e,
                    multiSelect: _multiSelect,
                    selected: selected,
                    onTap: () {
                      if (_multiSelect) {
                        setState(() {
                          if (selected) {
                            _selectedWatchKeys.remove(e.key);
                          } else {
                            _selectedWatchKeys.add(e.key);
                          }
                        });
                        return;
                      }
                                                               
                      Navigator.of(context).push(ImmersiveMaterialPageRoute<void>(
                        page: BilibiliVideoPage(
                          bvid: e.bvid,
                          initialTitle: e.title,
                          initialCover: e.coverUrl,
                        ),
                      ));
                    },
                    onLongPress: () {
                      if (!_multiSelect) {
                        setState(() {
                          _multiSelect = true;
                          _selectedWatchKeys.add(e.key);
                        });
                        HapticFeedback.mediumImpact();
                      }
                    },
                    onDelete: () => context.read<WatchHistoryService>().removeByKey(e.key),
                  ),
                ),
              );
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayTab() {
    final records = context.watch<PlayHistoryService>().records;
    final filtered = _keyword.isEmpty
        ? records
        : records
            .where((r) =>
                r.title.toLowerCase().contains(_keyword) ||
                r.videoUrl.toLowerCase().contains(_keyword))
            .toList();
    if (records.isEmpty) {
      return _empty(L10n.current.historyNoPlayHistory, Icons.play_circle_outline);
    }
    if (filtered.isEmpty) {
      return _empty(L10n.current.historySearchNoResult, Icons.search_off);
    }
    return AppRefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: _handlePlayRefresh,
      child: SingleChildScrollView(
        physics: const AppRefreshScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 84),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(context, '${AppLocalizations.of(context).historyTabPlay} · ${filtered.length}'),
            const SizedBox(height: 12),
            ...List.generate(filtered.length, (i) {
              final r = filtered[i];
              final selected = _selectedPlayIds.contains(r.id);
              return Padding(
                padding: EdgeInsets.only(bottom: i == filtered.length - 1 ? 0 : kCardGap),
                child: MorphItem(
                  selected: selected,
                  isFirst: i == 0,
                  isLast: i == filtered.length - 1,
                  child: _PlayTileContent(
                    record: r,
                    multiSelect: _multiSelect,
                    selected: selected,
                    onTap: () {
                      if (_multiSelect) {
                        setState(() {
                          if (selected) {
                            _selectedPlayIds.remove(r.id);
                          } else {
                            _selectedPlayIds.add(r.id);
                          }
                        });
                        return;
                      }
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MpvPlayerPage(
                          videoUrl: r.videoUrl,
                          title: r.title,
                          httpHeaders: r.httpHeaders,
                          subtitleUrl: r.subtitleUrl,
                          danmakuSource: r.danmakuSource,
                          danmakuType: r.danmakuType,
                          initialPosition: Duration(milliseconds: r.positionMs),
                          heroTag: 'history_thumb_${r.id}',
                        ),
                      ));
                    },
                    onLongPress: () {
                      if (!_multiSelect) {
                        setState(() {
                          _multiSelect = true;
                          _selectedPlayIds.add(r.id);
                        });
                        HapticFeedback.mediumImpact();
                      }
                    },
                    onDelete: () => context.read<PlayHistoryService>().removeById(r.id),
                  ),
                ),
              );
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _empty(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(msg,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _WatchTileContent extends StatelessWidget {
  final WatchHistoryEntry entry;
  final bool multiSelect;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  const _WatchTileContent({
    required this.entry,
    required this.multiSelect,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
                                      
                                    
    return VideoCardH(
      data: VideoCardData(
        cover: (entry.coverUrl != null && entry.coverUrl!.isNotEmpty)
            ? entry.coverUrl!
            : '',
        title: entry.title,
        subtitle: '${_formatTime(entry.watchedAt)}  ${entry.bvid}',
        progress: entry.progress,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
      trailing: multiSelect
          ? Checkbox(value: selected, onChanged: (_) => onTap())
          : IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
            ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return L10n.current.timeJustNow;
    if (diff.inHours < 24) return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${t.month}-${t.day} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

class _PlayTileContent extends StatelessWidget {
  final PlayRecord record;
  final bool multiSelect;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  const _PlayTileContent({
    required this.record,
    required this.multiSelect,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
                                           
                           
    return VideoCardH(
      data: VideoCardData(
        cover: '',
        title: record.title,
        subtitle: record.progressLabel,
        progress: record.progress,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
      trailing: multiSelect
          ? Checkbox(value: selected, onChanged: (_) => onTap())
          : IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
            ),
    );
  }
}
