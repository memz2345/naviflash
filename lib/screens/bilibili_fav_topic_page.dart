                                           
  
                               
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_topic_page.dart';
import 'package:naviflash/screens/browser_page.dart';
import 'package:naviflash/services/bilibili_fav_topic_service.dart';
import 'package:naviflash/services/paged_result.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/paged_list.dart';
import 'package:naviflash/widgets/standard_list_page.dart';

class BilibiliFavTopicPage extends StatefulWidget {
  const BilibiliFavTopicPage({super.key});

  @override
  State<BilibiliFavTopicPage> createState() => _BilibiliFavTopicPageState();
}

class _BilibiliFavTopicPageState extends State<BilibiliFavTopicPage> {
  late final PagedListController<BiliFavTopicItem> _ctl;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctl = PagedListController<BiliFavTopicItem>(
      (page) => BilibiliFavTopicService.fetchList(page: page),
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

  Future<void> _cancel(BiliFavTopicItem item) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.cancelFavTopic),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success =
        await BilibiliFavTopicService.cancelFav(topicId: item.id);
    if (success) {
      _ctl.refresh();
      if (mounted) showAppToast(context, l10n.deleted);
    } else if (mounted) {
      showAppToast(context, l10n.operationFailed, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final topH = kStdTopBarHeight;
    return StandardListScaffold(
      topBar: StandardListTopBar(title: l10n.favTopic, showBack: true),
      body: ListenableBuilder(
        listenable: _ctl,
        builder: (c, _) {
          if (!_ctl.initiallyLoaded && _ctl.loading) {
            return CustomScrollView(
              slivers: [
                topBarSpaceSliver(topH),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 260,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ],
            );
          }
          if (_ctl.error != null && _ctl.items.isEmpty) {
            return CustomScrollView(
              slivers: [
                topBarSpaceSliver(topH),
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 40, color: cs.error),
                          const SizedBox(height: 12),
                          Text(l10n.loadFailed),
                          const SizedBox(height: 4),
                          Text(_ctl.error!,
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant)),
                        ],
                      ),
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
              if (_ctl.items.isEmpty && !_ctl.loading && !_ctl.hasMore)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      l10n.noContent,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                )
              else
                genericGridSliver(
                  itemCount: _ctl.items.length,
                  aspectRatio: 2.4,
                  itemBuilder: (c, i) => _TopicChip(
                    item: _ctl.items[i],
                    onTap: () => _open(c, _ctl.items[i]),
                    onLongPress: () => _cancel(_ctl.items[i]),
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
    );
  }

  void _open(BuildContext c, BiliFavTopicItem i) {
                                     
                         
    if (i.id > 0) {
      Navigator.of(c).push(
        MaterialPageRoute(
          builder: (_) => BilibiliTopicPage(topicId: i.id, name: i.name),
        ),
      );
      return;
    }
    Navigator.of(c).push(
      MaterialPageRoute(
        builder: (_) => BrowserPage(initialUrl: i.webUrl, title: i.name),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final BiliFavTopicItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TopicChip({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        alignment: Alignment.center,
        child: Text(
          '# ${item.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
