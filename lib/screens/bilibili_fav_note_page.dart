                                          
  
                                
                                                     
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/services/bilibili_fav_note_service.dart';
import 'package:naviflash/services/paged_result.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/standard_list_page.dart';

class BilibiliFavNotePage extends StatelessWidget {
  const BilibiliFavNotePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: StandardListScaffold(
        topBar: StandardListTopBar(
          title: l10n.noteManage,
          showBack: true,
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.noteUnpublished),
              Tab(text: l10n.notePublished),
            ],
            indicatorSize: TabBarIndicatorSize.label,
          ),
          bottomHeight: 48,
        ),
        body: TabBarView(
          children: [
            _NoteTab(isPublish: false),
            _NoteTab(isPublish: true),
          ],
        ),
      ),
    );
  }
}

class _NoteTab extends StatefulWidget {
  final bool isPublish;
  const _NoteTab({required this.isPublish});

  @override
  State<_NoteTab> createState() => _NoteTabState();
}

class _NoteTabState extends State<_NoteTab> {
  late final PagedListController<BiliFavNoteItem> _ctl;
  final ScrollController _scroll = ScrollController();
  final Set<String> _selected = {};
  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    _ctl = PagedListController<BiliFavNoteItem>(
      (page) => BilibiliFavNoteService.fetchList(
        isPublish: widget.isPublish,
        pn: page,
      ),
    );
    _ctl.refresh();
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 600) {
        _ctl.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _idOf(BiliFavNoteItem i) => widget.isPublish ? i.cvid : i.noteId;

  void _toggle(BiliFavNoteItem i) {
    setState(() {
      final id = _idOf(i);
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
      _selecting = _selected.isNotEmpty;
    });
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.confirmDeleteNote),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l10n.deleteSelected),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await BilibiliFavNoteService.deleteNotes(
      isPublish: widget.isPublish,
      ids: _selected.toList(),
    );
    if (success) {
      setState(() {
        _selected.clear();
        _selecting = false;
      });
      _ctl.refresh();
      if (mounted) showAppToast(context, l10n.deleted);
    } else if (mounted) {
      showAppToast(context, l10n.operationFailed, error: true);
    }
  }

  void _onTap(BiliFavNoteItem i) {
    if (_selecting) {
      _toggle(i);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BrowserPage(initialUrl: i.webUrl, title: i.title),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final topH = kStdTopBarHeight + 48;
    return Stack(
      children: [
        ListenableBuilder(
          listenable: _ctl,
          builder: (c, _) {
            if (!_ctl.initiallyLoaded && _ctl.loading) {
              return CustomScrollView(
                slivers: [
                  topBarSpaceSliver(topH),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ],
              );
            }
            if (_ctl.items.isEmpty && !_ctl.loading && !_ctl.hasMore) {
              return CustomScrollView(
                slivers: [
                  topBarSpaceSliver(topH),
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        l10n.noContent,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                ],
              );
            }
            return CustomScrollView(
              controller: _scroll,
              slivers: [
                topBarSpaceSliver(topH),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (c, i) => _NoteItemCard(
                        item: _ctl.items[i],
                        selected: _selected.contains(_idOf(_ctl.items[i])),
                        onTap: () => _onTap(_ctl.items[i]),
                        onLongPress: () => _toggle(_ctl.items[i]),
                      ),
                      childCount: _ctl.items.length,
                    ),
                  ),
                ),
                if (_ctl.loading)
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 56,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                bottomSpaceSliver(context),
              ],
            );
          },
        ),
        if (_selecting)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8)
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                MediaQuery.of(context).padding.bottom + 10,
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      if (_selected.length == _ctl.items.length) {
                        _selected.clear();
                        _selecting = false;
                      } else {
                        _selected.addAll(_ctl.items.map(_idOf));
                      }
                    }),
                    child: Text(l10n.selectAll),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _delete,
                    child: Text(
                      _selected.isNotEmpty
                          ? '${l10n.deleteSelected} (${_selected.length})'
                          : l10n.deleteSelected,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _NoteItemCard extends StatelessWidget {
  final BiliFavNoteItem item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NoteItemCard({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (item.pic.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.pic,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 64,
                    height: 64,
                    color: cs.surfaceContainerHighest,
                  ),
                ),
              )
            else
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.note_outlined, color: cs.onSurfaceVariant),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    item.summary.isNotEmpty ? item.summary : item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (selected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
