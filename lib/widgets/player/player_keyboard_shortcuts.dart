                                                    
  
                                                           
  
                                                        
                                      
                                  
                   
                  
                                         
  
                             
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/player_shortcut_service.dart';

typedef PlayerShortcutAction = FutureOr<void> Function();

                                            
class PlayerLongPressShortcutActions {
  const PlayerLongPressShortcutActions({
    required this.onRepeat,
    required this.onRelease,
  });

  final PlayerShortcutAction onRepeat;
  final PlayerShortcutAction onRelease;
}

class PlayerKeyboardShortcuts extends StatefulWidget {
  const PlayerKeyboardShortcuts({
    super.key,
    required this.focusScopeNode,
    required this.actions,
    this.longPressActions = const <String, PlayerLongPressShortcutActions>{},
    this.isBlocked,
    this.service,
  });

                                 
  final FocusNode focusScopeNode;

                 
  final Map<String, PlayerShortcutAction> actions;

                       
  final Map<String, PlayerLongPressShortcutActions> longPressActions;

                                    
  final bool Function()? isBlocked;

                       
  final PlayerShortcutService? service;

  @override
  State<PlayerKeyboardShortcuts> createState() =>
      _PlayerKeyboardShortcutsState();
}

class _PlayerKeyboardShortcutsState extends State<PlayerKeyboardShortcuts> {
  PlayerShortcutService get _service =>
      widget.service ?? PlayerShortcutService.instance;

  Map<String, List<String>> _shortcuts = const <String, List<String>>{};

  final Map<LogicalKeyboardKey, PlayerLongPressShortcutActions>
      _activeLongPressKeys =
      <LogicalKeyboardKey, PlayerLongPressShortcutActions>{};

  @override
  void initState() {
    super.initState();
    _reload();
    _service.addListener(_reload);
    FocusManager.instance.addEarlyKeyEventHandler(_handleKeyEvent);
  }

  @override
  void didUpdateWidget(PlayerKeyboardShortcuts oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldService = oldWidget.service ?? PlayerShortcutService.instance;
    final newService = _service;
    if (!identical(oldService, newService)) {
      oldService.removeListener(_reload);
      newService.addListener(_reload);
      _reload();
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_handleKeyEvent);
    _service.removeListener(_reload);
    _releaseAllLongPressShortcuts();
    super.dispose();
  }

                                 
  void _reload() {
    _shortcuts = _service.snapshot();
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
                                                            
                                   
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }

                                         
    if (event is KeyUpEvent) {
      final longPress = _activeLongPressKeys.remove(event.logicalKey);
      if (longPress != null) {
        _invokeAction(longPress.onRelease);
        return KeyEventResult.handled;
      }
    }

    if (!_shouldHandleShortcut()) return KeyEventResult.ignored;

    final label = _labelOf(event.logicalKey);
    if (label == null) return KeyEventResult.ignored;
    final actionName = _findActionName(label);
    if (actionName == null) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      final action = widget.actions[actionName];
      final longPress = widget.longPressActions[actionName];
      if (action == null && longPress == null) return KeyEventResult.ignored;
      if (longPress != null) {
        _activeLongPressKeys[event.logicalKey] = longPress;
      }
      if (action != null) _invokeAction(action);
      return KeyEventResult.handled;
    }

    if (event is KeyRepeatEvent) {
      final longPress = _activeLongPressKeys[event.logicalKey];
      if (longPress == null) return KeyEventResult.ignored;
      _invokeAction(longPress.onRepeat);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  String? _labelOf(LogicalKeyboardKey key) {
    final label = key.keyLabel;
    if (label.isNotEmpty) return label;
    return key.debugName;
  }

  bool _shouldHandleShortcut() {
    if (!_service.enabled) return false;
    if (widget.isBlocked?.call() ?? false) return false;

                                         
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed) {
      return false;
    }

                                  
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return false;
    if (primaryFocus != widget.focusScopeNode &&
        !primaryFocus.ancestors.contains(widget.focusScopeNode)) {
      return false;
    }

    final focusContext = primaryFocus.context;
    if (focusContext == null) return true;
    return focusContext.widget is! EditableText &&
        focusContext.findAncestorWidgetOfExactType<EditableText>() == null;
  }

  String? _findActionName(String keyLabel) {
    for (final entry in _shortcuts.entries) {
      if (entry.value.contains(keyLabel)) return entry.key;
    }
    return null;
  }

  void _releaseAllLongPressShortcuts() {
    final actions = _activeLongPressKeys.values.toSet();
    _activeLongPressKeys.clear();
    for (final action in actions) {
      _invokeAction(action.onRelease);
    }
  }

  void _invokeAction(PlayerShortcutAction action) {
    unawaited(_runAction(action));
  }

  Future<void> _runAction(PlayerShortcutAction action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'player keyboard shortcuts',
          context: ErrorDescription('while invoking a player shortcut'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
