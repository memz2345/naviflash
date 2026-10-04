                                           
  
                                           
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/services/player_shortcut_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/widgets.dart';

class PlayerShortcutsScreen extends StatefulWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const PlayerShortcutsScreen({
    super.key,
    this.isSplitView = false,
    this.onBack,
  });

  @override
  State<PlayerShortcutsScreen> createState() => _PlayerShortcutsScreenState();
}

class _PlayerShortcutsScreenState extends State<PlayerShortcutsScreen> {
  PlayerShortcutService get _service => PlayerShortcutService.instance;

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

               

                      
  Future<void> _replaceKey(String action) async {
    final label = await showDialog<String>(
      context: context,
      builder: (_) => _KeyCaptureDialog(actionName: _service.actionName(action)),
    );
    if (label == null || !mounted) return;
    await _bindKey(action, label, replace: true);
  }

             
  Future<void> _appendKey(String action) async {
    final keys = _service.keysOf(action);
    if (keys.length >= PlayerShortcutService.maxKeysPerAction) {
      showAppToast(context, '每个功能最多绑定 '
          '${PlayerShortcutService.maxKeysPerAction} 个按键');
      return;
    }
    final label = await showDialog<String>(
      context: context,
      builder: (_) => _KeyCaptureDialog(actionName: _service.actionName(action)),
    );
    if (label == null || !mounted) return;
    await _bindKey(action, label, replace: false);
  }

  Future<void> _bindKey(
    String action,
    String label, {
    required bool replace,
  }) async {
    final owner = _service.ownerOf(label, except: action);
    if (owner != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('按键冲突'),
          content: Text(
            '「${_service.displayKey(label)}」已绑定给'
            '「${_service.actionName(owner)}」。\n'
            '是否改绑到「${_service.actionName(action)}」？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('改绑'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      await _service.removeKey(owner, label);
    }

    if (replace) {
      await _service.setKeys(action, <String>[label]);
    } else {
      await _service.addKey(action, label);
    }
    if (!mounted) return;
    showAppToast(
      context,
      '「${_service.actionName(action)}」→ ${_service.displayKey(label)}',
    );
  }

  Future<void> _resetAction(String action) async {
    await _service.resetAction(action);
    if (!mounted) return;
    showAppToast(
      context,
      '已恢复「${_service.actionName(action)}」默认键位：'
      '${_service.displayKeys(action)}',
    );
  }

  Future<void> _resetAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复默认快捷键'),
        content: const Text('将清空所有自定义按键并恢复出厂键位，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _service.resetAll();
    if (!mounted) return;
    showAppToast(context, '已恢复全部默认快捷键');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
        body: Stack(
          children: [
            PageBackground(baseColor: colorScheme.surfaceContainer),
            ListenableBuilder(
              listenable: _service,
              builder: (context, _) {
                return CustomScrollView(
                  physics: const ClampingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    ExpressiveSliverAppBar(
                      title: '播放器快捷键',
                      expandedHeight: 152,
                      leading: widget.isSplitView
                          ? null
                          : MorphIconButton(
                              tooltip: L10n.current.commonBackTooltip,
                              icon: Icons.arrow_back,
                              onTap: _handleBack,
                            ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildBody(context, colorScheme),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, ColorScheme cs) {
    final actions = _service.actionIds;
    final rows = <Widget>[];

    for (var i = 0; i < actions.length; i++) {
      final action = actions[i];
      final keys = _service.keysOf(action);
      final customized = _service.isCustomized(action);
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
          child: MorphItem(
            selected: false,
            isFirst: true,
            isLast: true,
            flashKey: 'shortcut_$action',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _service.actionName(action),
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                if (customized) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '已改',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: cs.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (_service
                                .actionDescription(action)
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  _service.actionDescription(action),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '恢复默认',
                        icon: Icon(
                          Icons.restore,
                          size: 20,
                          color: customized
                              ? cs.primary
                              : cs.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        onPressed: customized
                            ? () => _resetAction(action)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final key in keys)
                        InputChip(
                          label: Text(_service.displayKey(key)),
                          labelStyle: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          onDeleted: () => _service.removeKey(action, key),
                          deleteIcon: const Icon(Icons.close, size: 16),
                        ),
                      if (keys.isEmpty)
                        Text(
                          '未绑定',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.keyboard, size: 16),
                        label: Text(keys.isEmpty ? '绑定按键' : '改键'),
                        onPressed: () => keys.isEmpty
                            ? _appendKey(action)
                            : _replaceKey(action),
                      ),
                      if (keys.isNotEmpty &&
                          keys.length <
                              PlayerShortcutService.maxKeysPerAction)
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: const Text('追加'),
                          onPressed: () => _appendKey(action),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return [
      Text(
        '快捷键',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
      ),
      const SizedBox(height: 12),
      MorphItem(
        selected: false,
        isFirst: true,
        isLast: true,
        flashKey: 'shortcuts_enabled',
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: Icon(
            Icons.keyboard_alt_outlined,
            size: 26,
            color: cs.onSurfaceVariant,
          ),
          title: const Text('启用播放器快捷键'),
          subtitle: Text(
            '关闭后仅保留原有的 D / → 长按倍速与短按快进',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          value: _service.enabled,
          onChanged: _service.setEnabled,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        '按键绑定',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
      ),
      const SizedBox(height: 4),
      Text(
        '点击「改键」后按下目标按键即可绑定。Esc 由系统返回统一处理，'
        '不参与改键；带 Ctrl / Alt / Cmd 的组合键不会被占用。',
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      const SizedBox(height: 12),
      ...rows,
      const SizedBox(height: 24),
      MorphItem(
        selected: false,
        isFirst: true,
        isLast: true,
        flashKey: 'shortcuts_reset_all',
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Icon(Icons.settings_backup_restore, color: cs.error),
          title: const Text('恢复全部默认快捷键'),
          subtitle: Text(
            '清空所有自定义键位',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          onTap: _resetAll,
        ),
      ),
    ];
  }
}

                                   
class _KeyCaptureDialog extends StatefulWidget {
  const _KeyCaptureDialog({required this.actionName});

  final String actionName;

  @override
  State<_KeyCaptureDialog> createState() => _KeyCaptureDialogState();
}

class _KeyCaptureDialogState extends State<_KeyCaptureDialog> {
  final FocusNode _node = FocusNode(debugLabel: 'shortcut-capture');
  String? _preview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _node.requestFocus();
    });
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('设置「${widget.actionName}」'),
      content: KeyboardListener(
        focusNode: _node,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
          final key = event.logicalKey;
                               
          if (key == LogicalKeyboardKey.escape) return;
          final label = key.keyLabel.isNotEmpty
              ? key.keyLabel
              : (key.debugName ?? '');
          if (label.isEmpty) return;
          setState(() => _preview = label);
          Navigator.of(context).pop(label);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('请按下要绑定的按键…'),
            const SizedBox(height: 12),
            Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                _preview == null
                    ? '等待按键'
                    : (keyAliases[_preview!] ?? _preview!),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
