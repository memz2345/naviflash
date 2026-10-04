                                          
  
                                                  
                                                               
                                       
                 
                                               
import 'package:flutter/material.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:flutter/services.dart';

import 'package:naviflash/services/bilibili_dm_block_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/page_loading.dart';

class BilibiliDmBlockPage extends StatefulWidget {
  const BilibiliDmBlockPage({super.key});

  @override
  State<BilibiliDmBlockPage> createState() => _BilibiliDmBlockPageState();
}

class _BilibiliDmBlockPageState extends State<BilibiliDmBlockPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  List<BiliDmFilterRule> _rules = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool force = true}) async {
    if (!BilibiliDmBlockService.canUse) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '还没有登录，登录后屏蔽词会同步到 B 站账号';
      });
      return;
    }
    final rules = await BilibiliDmBlockService.getRules(force: force);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _rules = rules;
      _error = null;
    });
  }

  Future<void> _add() async {
    final tab = _tab.index;
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(switch (tab) {
          1 => '添加正则屏蔽',
          2 => '添加屏蔽用户',
          _ => '添加屏蔽关键词',
        }),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: tab == 2 ? TextInputType.number : TextInputType.text,
          inputFormatters: tab == 2
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: switch (tab) {
              1 => '输入正则表达式，如 12{3,}',
              2 => '输入用户 UID',
              _ => '输入关键词（子串匹配）',
            },
            helperText: tab == 1 ? '非法正则不会命中任何弹幕' : null,
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
    if (value == null || !mounted) return;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
                            
    if (tab == 1) {
      final pattern =
          RegExp(r'^/(.*)/$').firstMatch(trimmed)?.group(1) ?? trimmed;
      try {
        RegExp(pattern);
      } catch (_) {
        if (!mounted) return;
        showAppToast(context, '正则表达式无效，请检查后重试', error: true);
        return;
      }
    }
    final result = await BilibiliDmBlockService.addRule(
      type: tab,
      filter: trimmed,
    );
    if (!mounted) return;
    if (!result.ok) {
      showAppToast(context, result.message, error: true);
      return;
    }
    showAppToast(context, '添加成功，已同步到账号');
    await _refresh();
  }

  Future<void> _remove(BiliDmFilterRule rule) async {
    final label = _ruleLabel(rule);
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
    final result = await BilibiliDmBlockService.deleteRules([rule.id]);
    if (!mounted) return;
    if (!result.ok) {
      showAppToast(context, result.message, error: true);
      return;
    }
    showAppToast(context, '已删除');
    await _refresh();
  }

                                 
                                     
  String _ruleLabel(BiliDmFilterRule rule) {
    if (rule.comment.isNotEmpty) return rule.comment;
    if (rule.type == 2) return 'UID(${rule.filter})';
    return rule.filter;
  }

  String _ruleSub(BiliDmFilterRule rule) {
    if (rule.comment.isNotEmpty && rule.type == 2) {
      return '哈希 ${rule.filter}';
    }
    return rule.comment.isNotEmpty ? '备注：${rule.comment}' : '';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        title: const Text('弹幕屏蔽管理'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: '关键词'),
            Tab(text: '正则'),
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
                for (var tab = 0; tab < 3; tab++)
                  AppRefreshIndicator(
                    onRefresh: () => _refresh(),
                    child: _buildRuleList(cs, tab),
                  ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('添加'),
      ),
    );
  }

  Widget _buildRuleList(ColorScheme cs, int tab) {
    final rules = _rules.where((r) => r.type == tab).toList();
    if (rules.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 96),
        children: [
          Text(
            _error ?? '暂无${switch (tab) { 1 => '正则', 2 => '用户', _ => '关键词' }}屏蔽规则\n命中的弹幕将在播放器中隐藏',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.6),
          ),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '共 ${rules.length} 条，下拉刷新 · 侧滑删除',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ),
        for (final rule in rules)
          Dismissible(
            key: ValueKey('dm-block-rule-${rule.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
            ),
            confirmDismiss: (_) async {
              await _remove(rule);
              return false;                    
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: cs.surfaceContainerHigh,
              child: ListTile(
                dense: true,
                title: Text(
                  _ruleLabel(rule),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: _ruleSub(rule).isEmpty
                    ? null
                    : Text(
                        _ruleSub(rule),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _remove(rule),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
