                                       
  
                                  
  
                                 
                                                    
                                                               
                                              
                                            
  
                                      
                                                 
  
                                             
                                                                                 
                         
  
                                               
                                                    
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:naviflash/utils/recommend_filter.dart';

                           
enum UgcFilterScope {
                 
  recommend('recommend', 'banWordForRecommend'),

                               
  zone('zone', 'banWordForZone'),

           
  reply('reply', 'banWordForReply'),

           
  dyn('dyn', 'banWordForDyn');

  const UgcFilterScope(this.id, this.legacyPrefKey);

                     
  final String id;

                    
  final String legacyPrefKey;
}

class UgcFilterService extends ChangeNotifier {
  UgcFilterService._();

  static final UgcFilterService instance = UgcFilterService._();

  static const String _prefKey = 'ugcFilterRules';

  final Map<UgcFilterScope, List<String>> _rules = <UgcFilterScope, List<String>>{
    for (final s in UgcFilterScope.values) s: <String>[],
  };
  final Map<UgcFilterScope, RegExp?> _compiled = <UgcFilterScope, RegExp?>{};

  bool _initialized = false;

  bool get isInitialized => _initialized;

                          
     
                                                           
                                                      
  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final s in UgcFilterScope.values) {
            final list = decoded[s.id];
            if (list is List) {
              _rules[s] = list
                  .whereType<String>()
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
          }
        }
      } else {
                         
        var migrated = false;
        for (final s in UgcFilterScope.values) {
          final legacy = prefs.getString(s.legacyPrefKey);
          final parsed = splitRules(legacy ?? '');
          if (parsed.isNotEmpty) {
            _rules[s] = parsed;
            migrated = true;
          }
        }
        if (migrated) await _persist();
      }
    } catch (e) {
      debugPrint('[UgcFilter] 读取规则失败: $e');
    }
    _recompileAll();
  }

                              

                            
  List<String> rulesOf(UgcFilterScope scope) =>
      List<String>.unmodifiable(_rules[scope] ?? const <String>[]);

                
  int countOf(UgcFilterScope scope) => _rules[scope]?.length ?? 0;

                 
  bool get hasAnyRule => _rules.values.any((e) => e.isNotEmpty);

                         
  RegExp? regexOf(UgcFilterScope scope) => _compiled[scope];

                                                          
  String patternOf(UgcFilterScope scope) => _compiled[scope]?.pattern ?? '';

                          
  bool shouldFilter(UgcFilterScope scope, String text) {
    if (text.isEmpty) return false;
    final re = _compiled[scope];
    if (re == null) return false;
    return re.hasMatch(text);
  }

                            
  static bool isValidRule(String rule) {
    if (rule.trim().isEmpty) return false;
    try {
      RegExp(rule);
      return true;
    } catch (_) {
      return false;
    }
  }

                              

           
  Future<void> setRules(UgcFilterScope scope, List<String> rules) async {
    _rules[scope] = _normalize(rules);
    await _afterChange();
  }

                             
  Future<int> setRulesFromText(UgcFilterScope scope, String text) async {
    final rules = splitRules(text);
    await setRules(scope, rules);
    return rules.length;
  }

                                
  Future<int> addRules(UgcFilterScope scope, List<String> rules) async {
    final current = List<String>.from(_rules[scope] ?? const <String>[]);
    var added = 0;
    for (final r in _normalize(rules)) {
      if (current.contains(r)) continue;
      current.add(r);
      added++;
    }
    if (added == 0) return 0;
    _rules[scope] = current;
    await _afterChange();
    return added;
  }

  Future<void> addRule(UgcFilterScope scope, String rule) =>
      addRules(scope, <String>[rule]).then((_) {});

                
  Future<void> removeRule(UgcFilterScope scope, String rule) async {
    final current = _rules[scope];
    if (current == null || !current.remove(rule)) return;
    await _afterChange();
  }

                        
  Future<void> removeAt(UgcFilterScope scope, Iterable<int> indexes) async {
    final current = _rules[scope];
    if (current == null || current.isEmpty) return;
    final drop = indexes.toSet();
    _rules[scope] = <String>[
      for (var i = 0; i < current.length; i++)
        if (!drop.contains(i)) current[i],
    ];
    await _afterChange();
  }

            
  Future<void> clear(UgcFilterScope scope) async {
    if ((_rules[scope] ?? const <String>[]).isEmpty) return;
    _rules[scope] = <String>[];
    await _afterChange();
  }

                       
  Future<int> deleteMatching(
    UgcFilterScope scope, {
    required String find,
    bool isRegex = false,
    bool caseSensitive = false,
  }) async {
    final current = _rules[scope];
    if (current == null || current.isEmpty || find.isEmpty) return 0;
    final keep = <String>[];
    var hit = 0;
    for (final rule in current) {
      if (_ruleMatches(
        rule,
        find,
        isRegex: isRegex,
        caseSensitive: caseSensitive,
      )) {
        hit++;
      } else {
        keep.add(rule);
      }
    }
    if (hit == 0) return 0;
    _rules[scope] = keep;
    await _afterChange();
    return hit;
  }

                                                     
  Future<int> replaceInRules(
    UgcFilterScope scope, {
    required String find,
    required String replace,
    bool isRegex = false,
    bool caseSensitive = false,
    bool wholeWord = false,
  }) async {
    final current = _rules[scope];
    if (current == null || current.isEmpty || find.isEmpty) return 0;
    var hit = 0;
    final out = <String>[];
    for (final rule in current) {
      final next = _replaceInText(
        rule,
        find: find,
        replace: replace,
        isRegex: isRegex,
        caseSensitive: caseSensitive,
        wholeWord: wholeWord,
      );
      if (next == rule) {
        out.add(rule);
        continue;
      }
      hit++;
      if (next.trim().isNotEmpty) out.add(next);
    }
    if (hit == 0) return 0;
    _rules[scope] = _normalize(out);
    await _afterChange();
    return hit;
  }

                                 
  Future<bool> replaceRuleAt(
    UgcFilterScope scope,
    int index, {
    required String find,
    required String replace,
    bool isRegex = false,
    bool caseSensitive = false,
    bool wholeWord = false,
  }) async {
    final current = _rules[scope];
    if (current == null || index < 0 || index >= current.length) return false;
    final next = _replaceInText(
      current[index],
      find: find,
      replace: replace,
      isRegex: isRegex,
      caseSensitive: caseSensitive,
      wholeWord: wholeWord,
    );
    if (next == current[index]) return false;
    final out = List<String>.from(current);
    if (next.trim().isEmpty) {
      out.removeAt(index);
    } else {
      out[index] = next;
    }
    _rules[scope] = _normalize(out);
    await _afterChange();
    return true;
  }

                     
     
                                            
  List<int> matchIndexes(
    UgcFilterScope scope, {
    required String find,
    bool isRegex = false,
    bool caseSensitive = false,
    bool wholeWord = false,
  }) {
    final current = _rules[scope] ?? const <String>[];
    if (find.isEmpty) return const <int>[];
    return <int>[
      for (var i = 0; i < current.length; i++)
        if (_regexFor(
          find,
          isRegex: isRegex,
          caseSensitive: caseSensitive,
          wholeWord: wholeWord,
        ).hasMatch(current[i]))
          i,
    ];
  }

                              
  String exportText(UgcFilterScope scope) =>
      (_rules[scope] ?? const <String>[]).join('\n');

                                 

                
                                                  
                                            
  static List<String> splitRules(String text) {
    if (text.trim().isEmpty) return const <String>[];
    final parts = text.contains('\n')
        ? text.split('\n')
        : text.split(RegExp(r'[|,，;；]'));
    return _normalize(parts);
  }

  static List<String> _normalize(Iterable<String> rules) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in rules) {
      final r = raw.trim();
      if (r.isEmpty || !seen.add(r)) continue;
      out.add(r);
    }
    return out;
  }

                               

  bool _ruleMatches(
    String rule,
    String find, {
    required bool isRegex,
    required bool caseSensitive,
  }) {
    final re = _regexFor(
      find,
      isRegex: isRegex,
      caseSensitive: caseSensitive,
      wholeWord: false,
    );
    return re.hasMatch(rule);
  }

                           
  final Map<String, RegExp> _matchCache = <String, RegExp>{};

  RegExp _regexFor(
    String find, {
    required bool isRegex,
    required bool caseSensitive,
    required bool wholeWord,
  }) {
    final key = '$find\u0000$isRegex$caseSensitive$wholeWord';
    final cached = _matchCache[key];
    if (cached != null) return cached;
    var pattern = isRegex ? find : RegExp.escape(find);
    if (wholeWord) pattern = '^(?:$pattern)\$';
    RegExp re;
    try {
      re = RegExp(pattern, caseSensitive: caseSensitive);
    } catch (_) {
                             
      re = RegExp(r'(?!)');
    }
    if (_matchCache.length > 64) _matchCache.clear();
    _matchCache[key] = re;
    return re;
  }

  String _replaceInText(
    String text, {
    required String find,
    required String replace,
    required bool isRegex,
    required bool caseSensitive,
    required bool wholeWord,
  }) {
    final re = _regexFor(
      find,
      isRegex: isRegex,
      caseSensitive: caseSensitive,
      wholeWord: wholeWord,
    );
    return text.replaceAll(re, replace);
  }

  Future<void> _afterChange() async {
    _recompileAll();
    await _persist();
    notifyListeners();
  }

  void _recompileAll() {
    _matchCache.clear();
    for (final s in UgcFilterScope.values) {
      _compiled[s] = _compile(_rules[s] ?? const <String>[]);
    }
                                             
    RecommendFilter.setBanWordPatterns(
      recommendPattern: patternOf(UgcFilterScope.recommend),
      zonePattern: patternOf(UgcFilterScope.zone),
    );
  }

                                               
  static RegExp? _compile(List<String> rules) {
    final valid = <String>[];
    for (final r in rules) {
      try {
        RegExp(r);
        valid.add('(?:$r)');
      } catch (e) {
        debugPrint('[UgcFilter] 规则不是合法正则，已跳过: $r ($e)');
      }
    }
    if (valid.isEmpty) return null;
    try {
      return RegExp(valid.join('|'), caseSensitive: false);
    } catch (e) {
      debugPrint('[UgcFilter] 合成正则失败: $e');
      return null;
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefKey,
        jsonEncode(<String, Object?>{
          for (final s in UgcFilterScope.values) s.id: _rules[s] ?? const [],
        }),
      );
    } catch (e) {
      debugPrint('[UgcFilter] 写入规则失败: $e');
    }
  }

  @visibleForTesting
  Future<void> debugReset() async {
    for (final s in UgcFilterScope.values) {
      _rules[s] = <String>[];
    }
    _initialized = false;
    _compiled.clear();
    _matchCache.clear();
  }
}
