                                      
                                          
                           
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:naviflash/services/live_dm_block_store.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/page_loading.dart';

class LiveDmBlockPage extends StatefulWidget {
                             
  final int roomId;

  const LiveDmBlockPage({super.key, this.roomId = 0});

  @override
  State<LiveDmBlockPage> createState() => _LiveDmBlockPageState();
}

class _LiveDmBlockPageState extends State<LiveDmBlockPage>
    with SingleTickerProviderStateMixin {
  final LiveDmBlockStore _store = LiveDmBlockStore.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _store.ensureLoaded(widget.roomId);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _add(bool isKeyword) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isKeyword ? '添加屏蔽关键词' : '添加屏蔽用户'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType:
              isKeyword ? TextInputType.text : TextInputType.number,
          inputFormatters: isKeyword
              ? null
              : [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: isKeyword ? '输入关键词（子串匹配）' : '输入 UID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    if (value == null || value.trim().isEmpty || !mounted) return;
    final result = isKeyword
        ? await _store.addKeyword(value)
        : await _store.addUser(int.tryParse(value.trim()) ?? 0, 'UID$value');
    if (!mounted) return;
    if (!result.ok) {
      showAppToast(context, result.message, error: true);
      return;
    }
    setState(() {});
  }

  Future<void> _remove(bool isKeyword, String label, Object key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除规则'),
        content: Text('确定删除「$label」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = isKeyword
        ? await _store.removeKeyword(label)
        : await _store.removeUser(key as int);
    if (!mounted) return;
    if (!result.ok) {
      showAppToast(context, result.message, error: true);
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: cs.surfaceContainer,
        appBar: AppBar(
          title: const Text('直播弹幕屏蔽'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '关键词'),
              Tab(text: '用户'),
            ],
          ),
        ),
        body: Stack(
          children: [
            PageBackground(baseColor: cs.surfaceContainer),
            if (_loading)
              const PageLoadingIndicator()
            else
              TabBarView(
                children: [
                  _buildChips(
                    cs,
                    items: [
                      for (final k in _store.keywords) (label: k, key: k),
                    ],
                    onDelete: (item) => _remove(true, item.label, item.key),
                  ),
                  _buildChips(
                    cs,
                    items: [
                      for (final e in _store.users.entries)
                        (
                          label: e.value.isEmpty ? 'UID${e.key}' : e.value,
                          key: e.key,
                        ),
                    ],
                    onDelete: (item) => _remove(false, item.label, item.key),
                  ),
                ],
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            final tab = DefaultTabController.of(context).index;
            _add(tab == 0);
          },
          icon: const Icon(Icons.add),
          label: const Text('添加'),
        ),
      ),
    );
  }

  Widget _buildChips(
    ColorScheme cs, {
    required List<({String label, Object key})> items,
    required ValueChanged<({String label, Object key})> onDelete,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          '暂无屏蔽规则\n命中的弹幕不会在聊天面板显示',
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurfaceVariant, height: 1.6),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              InputChip(
                label: Text(item.label),
                onDeleted: () => onDelete(item),
                deleteIcon: const Icon(Icons.close, size: 16),
              ),
          ],
        ),
      ],
    );
  }
}
