                                            
  
                                                     
                                         
  
        
                                       
                                                                         
                              
                                          
                           
                                             
                   
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerShortcutService extends ChangeNotifier {
  PlayerShortcutService._();

  static final PlayerShortcutService instance = PlayerShortcutService._();

                                
  static const int maxKeysPerAction = 3;

  static const String _enabledKey = 'player_shortcuts_enabled';
  static const String _prefix = 'shortcut_';

           
     
                                                 
                                                
               
  static const Map<String, List<String>> defaultShortcuts =
      <String, List<String>>{
    'playorpause': <String>[' '],
    'forward': <String>['Arrow Right', 'D'],
    'rewind': <String>['Arrow Left'],
    'next': <String>['N'],
    'prev': <String>['P'],
    'volumeup': <String>['Arrow Up'],
    'volumedown': <String>['Arrow Down'],
    'togglemute': <String>['M'],
    'fullscreen': <String>['F'],
    'exitfullscreen': <String>['Escape'],
    'toggledanmaku': <String>['V'],
    'screenshot': <String>['S'],
    'skip': <String>['K'],
    'speed1': <String>['1'],
    'speed2': <String>['2'],
    'speed3': <String>['3'],
    'speedup': <String>['X'],
    'speeddown': <String>['Z'],
  };

                  
  static const Map<String, String> shortcutsChineseName = <String, String>{
    'playorpause': '播放 / 暂停',
    'forward': '快进 / 长按倍速',
    'rewind': '快退',
    'next': '下一集',
    'prev': '上一集',
    'volumeup': '音量加',
    'volumedown': '音量减',
    'togglemute': '静音',
    'fullscreen': '全屏',
    'exitfullscreen': '退出全屏',
    'toggledanmaku': '弹幕开关',
    'screenshot': '截图',
    'skip': '跳过片头',
    'speed1': '倍速：1x',
    'speed2': '倍速：2x',
    'speed3': '倍速：3x',
    'speedup': '倍速加',
    'speeddown': '倍速减',
  };

                         
  static const Map<String, String> shortcutsDescription = <String, String>{
    'forward': '短按快进 10 秒，长按加速到 2x（原快捷键 D / → 保留）',
    'exitfullscreen': 'Esc 仍走系统返回，可在全屏播放页退出',
    'skip': '跳到片头/广告片段之后（需片头跳过数据）',
    'speedup': '每次 +0.25x',
    'speeddown': '每次 -0.25x',
  };

                                        
  final Map<String, List<String>> _custom = <String, List<String>>{};

  bool _enabled = true;
  bool _loaded = false;

  bool get enabled => _enabled;
  bool get isLoaded => _loaded;

                           
  List<String> get actionIds => defaultShortcuts.keys.toList(growable: false);

  String actionName(String action) =>
      shortcutsChineseName[action] ?? action;

  String actionDescription(String action) => shortcutsDescription[action] ?? '';

                      
  List<String> keysOf(String action) {
    final custom = _custom[action];
    if (custom != null) return List<String>.unmodifiable(custom);
    return List<String>.unmodifiable(
      defaultShortcuts[action] ?? const <String>[],
    );
  }

                                     
  Map<String, List<String>> snapshot() => <String, List<String>>{
        for (final action in defaultShortcuts.keys) action: keysOf(action),
      };

                                      
  String displayKey(String label) => keyAliases[label] ?? label;

  String displayKeys(String action) {
    final keys = keysOf(action);
    if (keys.isEmpty) return '未设置';
    return keys.map(displayKey).join(' / ');
  }

  bool isCustomized(String action) => _custom.containsKey(action);

                 
  bool get hasCustomization => _custom.isNotEmpty;

                                  
  String? ownerOf(String label, {String? except}) {
    for (final action in defaultShortcuts.keys) {
      if (action == except) continue;
      if (keysOf(action).contains(label)) return action;
    }
    return null;
  }

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_enabledKey) ?? true;
      _custom.clear();
      for (final action in defaultShortcuts.keys) {
        final list = prefs.getStringList('$_prefix$action');
        if (list != null) _custom[action] = list;
      }
    } catch (e) {
      debugPrint('[Shortcut] 读取快捷键设置失败: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (e) {
      debugPrint('[Shortcut] 保存快捷键开关失败: $e');
    }
  }

                                  
  Future<void> setKeys(String action, List<String> keys) async {
    final normalized = <String>[];
    for (final k in keys) {
      if (k.isEmpty || normalized.contains(k)) continue;
      normalized.add(k);
      if (normalized.length >= maxKeysPerAction) break;
    }
    final defaults = defaultShortcuts[action] ?? const <String>[];
    if (listEquals(normalized, defaults)) {
      _custom.remove(action);
    } else {
      _custom[action] = normalized;
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_custom.containsKey(action)) {
        await prefs.setStringList('$_prefix$action', normalized);
      } else {
        await prefs.remove('$_prefix$action');
      }
    } catch (e) {
      debugPrint('[Shortcut] 保存快捷键失败: $e');
    }
  }

                                
  Future<void> addKey(String action, String label) async {
    final keys = keysOf(action);
    if (keys.contains(label)) return;
    if (keys.length >= maxKeysPerAction) return;
    await setKeys(action, <String>[...keys, label]);
  }

  Future<void> removeKey(String action, String label) async {
    final keys = keysOf(action).where((k) => k != label).toList();
    await setKeys(action, keys);
  }

                  
  Future<void> resetAction(String action) async {
    if (!_custom.containsKey(action)) return;
    _custom.remove(action);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$action');
    } catch (e) {
      debugPrint('[Shortcut] 恢复默认快捷键失败: $e');
    }
  }

               
  Future<void> resetAll() async {
    _custom.clear();
    _enabled = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, true);
      for (final action in defaultShortcuts.keys) {
        await prefs.remove('$_prefix$action');
      }
    } catch (e) {
      debugPrint('[Shortcut] 恢复默认快捷键失败: $e');
    }
  }
}

              
const Map<String, String> keyAliases = <String, String>{
  ' ': '空格',
  'Arrow Up': '↑',
  'Arrow Down': '↓',
  'Arrow Left': '←',
  'Arrow Right': '→',
  'Enter': '回车',
  'Tab': 'Tab',
  'Escape': 'Esc',
  'Backspace': '退格',
  'Delete': 'Delete',
  'Page Up': 'Page Up',
  'Page Down': 'Page Down',
  'Home': 'Home',
  'End': 'End',
};
