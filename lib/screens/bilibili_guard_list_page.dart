                                            
                                                             
                          
import 'package:flutter/material.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';

import 'package:naviflash/screens/bilibili_user_space_page_v2.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/widgets/page_background.dart';

class BilibiliGuardListPage extends StatefulWidget {
                             
  final int mid;
  final String name;

  const BilibiliGuardListPage({
    super.key,
    required this.mid,
    this.name = '',
  });

  @override
  State<BilibiliGuardListPage> createState() => _BilibiliGuardListPageState();
}

class _BilibiliGuardListPageState extends State<BilibiliGuardListPage> {
  final ScrollController _scroll = ScrollController();
  final List<LiveGuardItem> _items = [];
  List<LiveGuardItem> _top = const [];
  int _page = 1;
  bool _loading = false;
  bool _end = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(refresh: true);
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
    final res = await BilibiliLiveService.fetchGuardList(
      ruid: widget.mid,
      page: _page,
    );
    if (!mounted) return;
    switch (res) {
      case LiveOk<LiveGuardItem>(:final items, :final hasMore):
        setState(() {
          if (refresh) {
            _items.clear();
                               
            _top = items.take(3).toList();
            _items.addAll(items.skip(_top.length));
          } else {
            _items.addAll(items);
          }
          _page++;
          _end = !hasMore;
          _loading = false;
          _error = null;
        });
      case LiveError<LiveGuardItem>(:final detail):
        setState(() {
          _loading = false;
          _error = detail;
        });
    }
  }

  Color _guardColor(int level) => switch (level) {
        1 => const Color(0xFFE23B4D),
        2 => const Color(0xFF9B59B6),
        _ => const Color(0xFF2E8AE6),
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        title: Text(
          widget.name.isEmpty ? '大航海舰队' : '${widget.name}的舰队',
        ),
      ),
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer),
          if (_error != null && _items.isEmpty && _top.isEmpty)
            Center(
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
            )
          else
            AppRefreshIndicator(
              onRefresh: () => _load(refresh: true),
              child: CustomScrollView(
                controller: _scroll,
                slivers: [
                  if (_top.isNotEmpty)
                    SliverToBoxAdapter(child: _buildPodium(cs)),
                  SliverList.builder(
                    itemCount: _items.length + (_end ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index >= _items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        );
                      }
                      final item = _items[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: cs.surfaceContainerHighest,
                          backgroundImage: item.face.isEmpty
                              ? null
                              : CachedImageProvider(item.face),
                        ),
                        title: Text(
                          item.username,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          item.guardLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: _guardColor(item.guardLevel),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  BilibiliUserSpacePage(mid: item.uid),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

                           
  Widget _buildPodium(ColorScheme cs) {
    final order = <int>[1, 0, 2];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final i in order)
            if (i < _top.length)
              Expanded(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        CircleAvatar(
                          radius: i == 0 ? 26 : 22,
                          backgroundColor: cs.surfaceContainerHighest,
                          backgroundImage: _top[i].face.isEmpty
                              ? null
                              : CachedImageProvider(_top[i].face),
                        ),
                        Positioned(
                          bottom: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _guardColor(_top[i].guardLevel),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _top[i].guardLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _top[i].username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
