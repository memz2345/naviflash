                                       
  
                                         
                                                               
                                                            
                                                            
                                                        
  
                                     
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_dynamics_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/dynamic_card.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/msg_feed_common.dart';

                                            
String topicNameFromText(String text) {
  final t = text.trim();
  if (t.length > 2 && t.startsWith('#') && t.endsWith('#')) {
    return t.substring(1, t.length - 1);
  }
  return t.replaceAll('#', '').trim();
}

        
class BilibiliTopicPage extends StatefulWidget {
                          
  final int topicId;

                             
  final String name;

  const BilibiliTopicPage({super.key, required this.topicId, this.name = ''});

  @override
  State<BilibiliTopicPage> createState() => _BilibiliTopicPageState();
}

class _BilibiliTopicPageState extends State<BilibiliTopicPage> {
  BiliTopicDetails? _details;
  final List<BiliDynamicDetail> _items = [];
  final ScrollController _scroll = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _offset;
  bool _hasMore = false;

                  
  int _sortBy = 0;

                        
  bool _faving = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) _loadMore();
  }

  Future<void> _load({bool reload = true}) async {
    if (reload) {
      setState(() {
        _loading = _items.isEmpty;
        _error = null;
      });
    }
                               
    if (_details == null) {
      final (:details, :err) = await BilibiliDynamicsService.fetchTopicDetails(
        widget.topicId,
      );
      if (!mounted) return;
      if (details != null) {
        _details = details;
      } else if (err != null && _error == null) {
        _error = err;
      }
    }
    final page = await BilibiliDynamicsService.fetchTopicFeed(
      topicId: widget.topicId,
      sortBy: _sortBy,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (page.err != null && page.items.isEmpty) {
        _error = page.err;
        return;
      }
      _error = null;
      _items
        ..clear()
        ..addAll(page.items);
      _offset = page.offset;
      _hasMore = page.hasMore;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading || _offset == null) return;
    setState(() => _loadingMore = true);
    final page = await BilibiliDynamicsService.fetchTopicFeed(
      topicId: widget.topicId,
      sortBy: _sortBy,
      offset: _offset,
    );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (page.err != null) {
        _hasMore = false;
        return;
      }
      final seen = _items.map((e) => e.idStr).toSet();
      for (final e in page.items) {
        if (seen.add(e.idStr)) _items.add(e);
      }
      _offset = page.offset;
      _hasMore = page.hasMore && page.offset != null;
    });
  }

  Future<void> _switchSort(int sortBy) async {
    if (sortBy == _sortBy) return;
    setState(() {
      _sortBy = sortBy;
      _loading = true;
      _offset = null;
      _hasMore = false;
    });
    await _load(reload: false);
  }

  Future<void> _toggleFav() async {
    final d = _details;
    if (d == null || _faving) return;
    setState(() => _faving = true);
    final r = await BilibiliDynamicsService.setTopicFav(
      topicId: d.id > 0 ? d.id : widget.topicId,
      fav: !d.isFav,
    );
    if (!mounted) return;
    setState(() {
      _faving = false;
      if (r.ok) {
        _details = BiliTopicDetails(
          id: d.id,
          name: d.name,
          view: d.view,
          discuss: d.discuss,
          fav: d.fav + (d.isFav ? -1 : 1),
          like: d.like,
          description: d.description,
          isFav: !d.isFav,
          isLike: d.isLike,
        );
      }
    });
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    if (r.ok) {
      showAppToast(context, isZh ? (d.isFav ? '已取消收藏' : '已收藏') : 'Done');
    } else {
      showAppToast(context, r.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final name = _details?.name.isNotEmpty == true
        ? _details!.name
        : (widget.name.isNotEmpty
              ? widget.name
              : (isZh ? '话题' : 'Topic'));
    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLow,
        scrolledUnderElevation: 0,
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: _buildBody(cs, l10n, isZh, name),
    );
  }

  Widget _buildBody(
    ColorScheme cs,
    AppLocalizations l10n,
    bool isZh,
    String name,
  ) {
    if (_loading && _items.isEmpty) {
      return const Center(child: LoadingIndicatorM3E());
    }
    if (_error != null && _items.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tag_outlined,
                    size: 44,
                    color: cs.onSurface.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: LoadRetryPill(onRetry: () => _load()),
          ),
        ],
      );
    }
    return AppRefreshIndicator(
      onRefresh: () => _load(reload: false),
      child: ListView(
        controller: _scroll,
        physics: const AppRefreshScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          _buildHeader(cs, isZh, name),
          const SizedBox(height: 6),
          _buildSortRow(cs, isZh),
          const SizedBox(height: 4),
          if (_items.isEmpty && _error == null)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: MsgEmptyView(
                icon: Icons.dynamic_feed_outlined,
                title: isZh ? '该话题下还没有动态' : 'No posts in this topic',
              ),
            )
          else ...[
            for (final item in _items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DynamicCard(item: item),
              ),
            _buildFooter(cs, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs, AppLocalizations l10n) {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: LoadingIndicatorM3E()),
      );
    }
    if (!_hasMore && _items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            l10n.msgNoMore,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }

  Widget _buildSortRow(ColorScheme cs, bool isZh) {
    return Row(
      children: [
        for (final entry in [
          (0, isZh ? '综合' : 'Top'),
          (1, isZh ? '最新' : 'Latest'),
        ])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.$2),
              selected: _sortBy == entry.$1,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => _switchSort(entry.$1),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme cs, bool isZh, String name) {
    final d = _details;
    final desc = d?.description ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.tag_rounded, size: 14, color: cs.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (d != null)
                IconButton.filledTonal(
                  tooltip: isZh ? '收藏话题' : 'Favorite',
                  onPressed: _faving ? null : _toggleFav,
                  icon: _faving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          d.isFav ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 20,
                        ),
                ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              desc,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          if (d != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _stat(cs, isZh ? '浏览' : 'Views', d.view),
                _stat(cs, isZh ? '讨论' : 'Posts', d.discuss),
                _stat(cs, isZh ? '收藏' : 'Favs', d.fav),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(ColorScheme cs, String label, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatCount(value),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

                        
  String _formatCount(int v) {
    if (v <= 0) return '0';
    if (v < 10000) return '$v';
    final w = v / 10000;
    return '${w >= 10 ? w.toStringAsFixed(0) : w.toStringAsFixed(1)}万';
  }
}
