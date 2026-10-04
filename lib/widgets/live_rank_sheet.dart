                                   
                                         
import 'package:flutter/material.dart';

import 'package:naviflash/screens/bilibili_user_space_page_v2.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

            
Future<void> showLiveRankSheet(
  BuildContext context, {
  required int ruid,
  required int roomId,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.72,
      child: _LiveRankPanel(ruid: ruid, roomId: roomId),
    ),
  );
}

class _LiveRankPanel extends StatelessWidget {
  final int ruid;
  final int roomId;

  const _LiveRankPanel({required this.ruid, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: LiveRankType.values.length,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              '贡献榜',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          TabBar(
            tabs: [
              for (final t in LiveRankType.values)
                Tab(text: t.title, height: 40),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final t in LiveRankType.values)
                  _RankList(ruid: ruid, roomId: roomId, type: t),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankList extends StatefulWidget {
  final int ruid;
  final int roomId;
  final LiveRankType type;

  const _RankList({
    required this.ruid,
    required this.roomId,
    required this.type,
  });

  @override
  State<_RankList> createState() => _RankListState();
}

class _RankListState extends State<_RankList>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scroll = ScrollController();
  final List<LiveRankItem> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _end = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >
        _scroll.position.maxScrollExtent - 300) {
      _load();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    if (!refresh && _end) return;
    setState(() {
      _loading = true;
      if (refresh) {
        _page = 1;
        _end = false;
        _error = null;
      }
    });
    final res = await BilibiliLiveService.fetchContributionRank(
      ruid: widget.ruid,
      roomId: widget.roomId,
      type: widget.type,
      page: _page,
    );
    if (!mounted) return;
    switch (res) {
      case LiveOk<LiveRankItem>(:final items, :final hasMore):
        setState(() {
          if (refresh) _items.clear();
          _items.addAll(items);
          _page++;
          _end = !hasMore || items.isEmpty;
          _loading = false;
          _error = null;
        });
      case LiveError<LiveRankItem>(:final detail):
        setState(() {
          _loading = false;
          _error = detail;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _load(refresh: true),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return Center(
        child: Text('暂无数据', style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }
    final showScore = widget.type == LiveRankType.online;
    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        controller: _scroll,
        itemCount: _items.length + (_end ? 0 : 1),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final item = _items[index];
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 26,
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _rankColor(index, cs),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.surfaceContainerHighest,
                  backgroundImage: item.face.isEmpty
                      ? null
                      : CachedImageProvider(item.face),
                ),
              ],
            ),
            title: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: item.medalName.isEmpty
                ? null
                : Text(
                    '${item.medalName} · ${item.medalLevel}',
                    style: TextStyle(
                      fontSize: 11,
                      color: item.medalColorText > 0
                          ? _medalColor(item.medalColorText)
                          : cs.onSurfaceVariant,
                    ),
                  ),
            trailing: showScore
                ? Text(
                    '${item.score}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BilibiliUserSpacePage(mid: item.uid),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Color _rankColor(int index, ColorScheme cs) {
    return switch (index) {
      0 => const Color(0xFFFDAD13),
      1 => const Color(0xFF8AACE1),
      2 => const Color(0xFFDFA777),
      _ => cs.onSurfaceVariant,
    };
  }

  static Color _medalColor(int value) {
    final v = value <= 0xFFFFFF ? (0xFF000000 | value) : value;
    return Color(v);
  }
}
