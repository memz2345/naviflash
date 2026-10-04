                                        
  
                                                                    
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';

import 'package:naviflash/services/bili_uri_router.dart';
import 'package:naviflash/services/bilibili_msg_service.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/msg_feed_common.dart';
import 'package:naviflash/widgets/page_loading.dart';

class MsgLikeDetailPage extends StatefulWidget {
  final Object cardId;
  final String title;

                         
  final String nativeUri;

  const MsgLikeDetailPage({
    super.key,
    required this.cardId,
    this.title = '',
    this.nativeUri = '',
  });

  @override
  State<MsgLikeDetailPage> createState() => _MsgLikeDetailPageState();
}

class _MsgLikeDetailPageState extends State<MsgLikeDetailPage> {
  final List<BiliMsgLikeDetailItem> _items = [];
  final ScrollController _scroll = ScrollController();
  bool _loading = true;
  bool _loadingMore = false;
  bool _end = false;
  String? _error;
  int _pn = 1;

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

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    final page = await BilibiliMsgService.fetchLikeDetail(
      cardId: widget.cardId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = page.err;
      _end = page.isEnd;
      _pn = 1;
      if (page.err == null) {
        _items
          ..clear()
          ..addAll(page.items);
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _end || _loading || _error != null) return;
    setState(() => _loadingMore = true);
    final page = await BilibiliMsgService.fetchLikeDetail(
      cardId: widget.cardId,
      pn: _pn + 1,
    );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (page.err != null) {
        _error = page.err;
        return;
      }
      _pn += 1;
      _end = page.isEnd;
      final before = _items.length;
      _items.addAll(page.items);
      if (_items.length == before) _end = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MsgPageScaffold(
      title: AppLocalizations.of(context).msgLikeDetailTitle,
      floatingActionButton: _error != null && _items.isEmpty && !_loading
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 8,
              ),
              child: LoadRetryPill(onRetry: _load),
            )
          : null,
      child: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _items.isEmpty,
    )) {
      return const PageLoadingIndicator();
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      );
    }
    if (_items.isEmpty) {
      return MsgEmptyView(
        icon: Icons.favorite_border,
        title: AppLocalizations.of(context).msgLikeDetailEmpty,
      );
    }
    return AppRefreshIndicator(
      onRefresh: _load,
                                    
      edgeOffset: kMsgTopBarHeight,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AppRefreshScrollPhysics(),
        slivers: [
                                      
          const SliverToBoxAdapter(
            child: SizedBox(height: kMsgTopBarHeight),
          ),
          if (widget.title.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: InkWell(
                  onTap: widget.nativeUri.isEmpty
                      ? null
                      : () => openBiliUri(context, widget.nativeUri),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SliverList.builder(
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final item = _items[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                leading: MsgAvatar(
                  url: item.user.avatar,
                  mid: item.user.mid,
                  size: 44,
                ),
                title: Text(
                  item.user.nickname.isEmpty
                      ? '用户${item.user.mid}'
                      : item.user.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  formatMsgTime(item.likeTime),
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: item.user.mid <= 0
                    ? null
                    : () => pushUserSpace(context, item.user.mid),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: _loadingMore
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _end
                    ? Text(
                        AppLocalizations.of(context).msgNoMore,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
