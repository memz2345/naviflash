                                        
  
                                               
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/services/bilibili_bubble_service.dart';
import 'package:naviflash/widgets/paged_list.dart';
import 'package:naviflash/widgets/standard_list_page.dart';

class BilibiliBubblePage extends StatefulWidget {
  final String tribeId;
  const BilibiliBubblePage({super.key, required this.tribeId});

  @override
  State<BilibiliBubblePage> createState() => _BilibiliBubblePageState();
}

class _BilibiliBubblePageState extends State<BilibiliBubblePage> {
  BiliBubblePageData? _data;
  bool _loading = true;
  String? _error;
  int _tab = 0;          
  List<BiliBubbleDyn> _dyn = const [];
  bool _tabLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBase();
  }

  Future<void> _loadBase() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await BilibiliBubbleService.fetch(tribeId: widget.tribeId);
      _data = d;
      _dyn = d?.dynList ?? const [];
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _selectTab(int i) async {
    if (i == _tab) return;
    setState(() {
      _tab = i;
      _tabLoading = true;
    });
    final cat = i == 0 ? null : _data!.categories[i - 1].id;
    try {
      final d = await BilibiliBubbleService.fetch(
        tribeId: widget.tribeId,
        categoryId: cat,
      );
      if (mounted) {
        setState(() {
          _dyn = d?.dynList ?? const [];
          _tabLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _tabLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final cats = <({String id, String name})>[
      (id: '', name: l10n.bubbleAll),
      ...?_data?.categories,
    ];
    final topH = kStdTopBarHeight;
    return StandardListScaffold(
      topBar: StandardListTopBar(
        title: _data?.tribeName.isNotEmpty == true
            ? _data!.tribeName
            : l10n.interestStation,
        showBack: true,
      ),
      body: CustomScrollView(
        slivers: [
          topBarSpaceSliver(topH),
          if (_loading)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else if (_error != null && _data == null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 40, color: cs.error),
                      const SizedBox(height: 12),
                      Text(l10n.loadFailed),
                      const SizedBox(height: 4),
                      Text(_error!,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            if (cats.length > 1)
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      for (var i = 0; i < cats.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cats[i].name),
                            selected: _tab == i,
                            onSelected: (_) => _selectTab(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            genericGridSliver(
              itemCount: _dyn.length,
              aspectRatio: 2.6,
              itemBuilder: (c, i) => _DynCard(
                item: _dyn[i],
                onTap: () => _open(c, _dyn[i]),
              ),
            ),
            if (_tabLoading)
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
        ],
      ),
    );
  }

  void _open(BuildContext c, BiliBubbleDyn item) {
    Navigator.of(c).push(
      MaterialPageRoute(
        builder: (_) =>
            BrowserPage(initialUrl: item.webUrl, title: item.title),
      ),
    );
  }
}

class _DynCard extends StatelessWidget {
  final BiliBubbleDyn item;
  final VoidCallback onTap;
  const _DynCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.title.isEmpty ? item.dynId : item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.author} · ${item.timeText}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
