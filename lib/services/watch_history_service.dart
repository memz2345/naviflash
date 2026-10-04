                                          
  
                                            
                                         
                                     
                                                
           
                                                        
                                  
                                                                  
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/l10n_helper.dart';

                        
class WatchHistoryEntry {
  final String bvid;
  final int? aid;
  final int? cid;
  final int? epid;
  final String title;
  final String? coverUrl;
  final String? upperName;
  final int positionMs;
  final int durationMs;
  final DateTime watchedAt;
  final bool finished;

  WatchHistoryEntry({
    required this.bvid,
    this.aid,
    this.cid,
    this.epid,
    required this.title,
    this.coverUrl,
    this.upperName,
    required this.positionMs,
    required this.durationMs,
    required this.watchedAt,
    this.finished = false,
  });

                                               
  String get key => cid != null ? '$bvid:$cid' : bvid;

  double get progress =>
      durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() => {
        'bvid': bvid,
        'aid': aid,
        'cid': cid,
        'epid': epid,
        'title': title,
        'coverUrl': coverUrl,
        'upperName': upperName,
        'positionMs': positionMs,
        'durationMs': durationMs,
        'watchedAt': watchedAt.toIso8601String(),
        'finished': finished,
      };

  factory WatchHistoryEntry.fromJson(Map<String, dynamic> json) =>
      WatchHistoryEntry(
        bvid: json['bvid'] as String? ?? '',
        aid: json['aid'] as int?,
        cid: json['cid'] as int?,
        epid: json['epid'] as int?,
        title: json['title'] as String? ?? L10n.current.unknownVideo,
        coverUrl: json['coverUrl'] as String?,
        upperName: json['upperName'] as String?,
        positionMs: json['positionMs'] as int? ?? 0,
        durationMs: json['durationMs'] as int? ?? 0,
        watchedAt:
            DateTime.tryParse(json['watchedAt'] as String? ?? '') ??
                DateTime.now(),
        finished: json['finished'] as bool? ?? false,
      );

  WatchHistoryEntry copyWith({
    int? positionMs,
    int? durationMs,
    DateTime? watchedAt,
    bool? finished,
    String? title,
    String? coverUrl,
    String? upperName,
    int? aid,
    int? cid,
    int? epid,
  }) =>
      WatchHistoryEntry(
        bvid: bvid,
        aid: aid ?? this.aid,
        cid: cid ?? this.cid,
        epid: epid ?? this.epid,
        title: title ?? this.title,
        coverUrl: coverUrl ?? this.coverUrl,
        upperName: upperName ?? this.upperName,
        positionMs: positionMs ?? this.positionMs,
        durationMs: durationMs ?? this.durationMs,
        watchedAt: watchedAt ?? this.watchedAt,
        finished: finished ?? this.finished,
      );
}

         
class WatchHistoryMergeStat {
  final int added;
  final int updated;
  const WatchHistoryMergeStat(this.added, this.updated);
  int get total => added + updated;
}

           
class WatchHistoryService extends ChangeNotifier {
  static const _fileName = 'watch_history.json';
  static const _maxRecords = 500;

  List<WatchHistoryEntry> _entries = [];
  bool _loaded = false;

  List<WatchHistoryEntry> get entries => List.unmodifiable(_entries);
  bool get isLoaded => _loaded;

  Future<void> initialize() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final raw = await file.readAsString();
        final list = (jsonDecode(raw) as List)
            .map((e) => WatchHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        _entries = list;
      }
    } catch (e) {
      debugPrint('WatchHistory 加载失败: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _persist() async {
    try {
      final file = await _file;
      final raw = jsonEncode(_entries.map((e) => e.toJson()).toList());
      await file.writeAsString(raw);
    } catch (e) {
      debugPrint('WatchHistory 写入失败: $e');
    }
  }

                        
                                      
                                              
  Future<void> record(WatchHistoryEntry entry, {bool force = false}) async {
    if (!force && entry.positionMs < 3000) return;
    final key = entry.key;
    final finished =
        entry.durationMs > 0 && entry.positionMs / entry.durationMs > 0.95;
    final merged = entry.copyWith(finished: finished);
    final existingIdx = _entries.indexWhere((e) => e.key == key);
    if (existingIdx >= 0) {
      _entries[existingIdx] = merged;
      final e = _entries.removeAt(existingIdx);
      _entries.insert(0, e);
    } else {
      _entries.insert(0, merged);
    }
    if (_entries.length > _maxRecords) {
      _entries = _entries.sublist(0, _maxRecords);
    }
    await _persist();
    notifyListeners();
  }

  WatchHistoryEntry? findByBvid(String bvid) {
    try {
      return _entries.firstWhere((e) => e.bvid == bvid);
    } catch (_) {
      return null;
    }
  }

  Future<void> removeByKey(String key) async {
    _entries.removeWhere((e) => e.key == key);
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _entries.clear();
    await _persist();
    notifyListeners();
  }

                                              
                 
                                              

  String exportJson() => jsonEncode(_entries.map((e) => e.toJson()).toList());

                             
  Future<int> replaceFromJson(String jsonStr) async {
    try {
      final list = (jsonDecode(jsonStr) as List)
          .map((e) => WatchHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _entries = list;
      await _persist();
      notifyListeners();
      return list.length;
    } catch (e) {
      debugPrint('WatchHistory 恢复失败: $e');
      return 0;
    }
  }

                                         
                
  Future<WatchHistoryMergeStat> mergeFromJson(String jsonStr) async {
    int added = 0, updated = 0;
    try {
      final remote = (jsonDecode(jsonStr) as List)
          .map((e) => WatchHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final r in remote) {
        final idx = _entries.indexWhere((e) => e.key == r.key);
        if (idx < 0) {
          _entries.add(r);
          added++;
        } else if (r.watchedAt.isAfter(_entries[idx].watchedAt)) {
          _entries[idx] = r;
          updated++;
        }
      }
                      
      _entries.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
      if (_entries.length > _maxRecords) {
        _entries = _entries.sublist(0, _maxRecords);
      }
      await _persist();
      notifyListeners();
    } catch (e) {
      debugPrint('WatchHistory 合并失败: $e');
    }
    return WatchHistoryMergeStat(added, updated);
  }

                                            
                               
                                            

                                     
                                                       
                                         
                                   
                              
  Future<WatchHistoryMergeStat> upsertCloudEntries(
    List<WatchHistoryEntry> cloud,
  ) async {
    var added = 0, updated = 0;
    for (final r in cloud) {
      if (r.bvid.isEmpty) continue;
      final idx = _entries.indexWhere((e) => e.key == r.key);
      if (idx < 0) {
        _entries.insert(0, r);
        added++;
      } else if (r.watchedAt.isAfter(_entries[idx].watchedAt)) {
        _entries[idx] = r;
        updated++;
      }
    }
    if (added > 0 || updated > 0) {
                                
      _entries.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
      if (_entries.length > _maxRecords) {
        _entries = _entries.sublist(0, _maxRecords);
      }
      await _persist();
      notifyListeners();
    }
    return WatchHistoryMergeStat(added, updated);
  }
}
