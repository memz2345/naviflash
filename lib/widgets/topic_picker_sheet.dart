                                      
  
                                                 
                                                    

import 'package:flutter/material.dart';
import 'package:naviflash/services/bilibili_dynamics_service.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

typedef PickedTopic = ({int id, String name});

                                
Future<PickedTopic?> showTopicPicker(BuildContext context) {
  return showAppBottomSheet<PickedTopic>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => const TopicPickerSheet(),
  );
}

class TopicPickerSheet extends StatefulWidget {
  const TopicPickerSheet({super.key});

  @override
  State<TopicPickerSheet> createState() => _TopicPickerSheetState();
}

class _TopicPickerSheetState extends State<TopicPickerSheet> {
  final TextEditingController _controller = TextEditingController();
  List<BiliTopicSearchItem> _items = const [];
  bool _loading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
                              
    _search(reset: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search({bool reset = false}) async {
    if (_loading) return;
    if (reset) {
      _page = 1;
      _hasMore = true;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final list = await BilibiliDynamicsService.searchTopic(
      _controller.text,
      page: _page,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (reset) {
        _items = list;
      } else {
        _items = [..._items, ...list];
      }
                                
      _hasMore = list.length >= 20;
    });
  }

  void _loadMore() {
    if (_loading || !_hasMore) return;
    _page++;
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(reset: true),
                        decoration: InputDecoration(
                          hintText: '搜索话题',
                          isDense: true,
                          prefixIcon: const Icon(Icons.tag, size: 18),
                          suffixIcon: _controller.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _controller.clear();
                                    _search(reset: true);
                                  },
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () => _search(reset: true),
                      child: const Text('搜索'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _buildBody(cs)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => _search(reset: true),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          '没有找到相关话题',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 200) _loadMore();
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
        itemBuilder: (context, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final t = _items[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.tag, size: 18, color: cs.onPrimaryContainer),
            ),
            title: Text(
              t.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: t.statDesc.isNotEmpty
                ? Text(
                    t.statDesc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  )
                : null,
            onTap: () => Navigator.of(context).pop((id: t.id, name: t.name)),
          );
        },
      ),
    );
  }
}
