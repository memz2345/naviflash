import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../l10n/l10n_helper.dart';

class PlayRecord {
  final String id;
  final String videoUrl;
  final String title;
  final int positionMs;
  final int durationMs;
  final DateTime savedAt;
  final String? thumbnailPath;
  final Map<String, String>? httpHeaders;
  final String? subtitleUrl;
                         
  final String? danmakuSource;               
  final String? danmakuType;                    

  PlayRecord({
    required this.id,
    required this.videoUrl,
    required this.title,
    required this.positionMs,
    required this.durationMs,
    required this.savedAt,
    this.thumbnailPath,
    this.httpHeaders,
    this.subtitleUrl,
    this.danmakuSource,         
    this.danmakuType,           
  });

  double get progress =>
      durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;

  bool get isFinished => progress > 0.95;

  String get progressLabel {
    final pos = Duration(milliseconds: positionMs);
    final dur = Duration(milliseconds: durationMs);
    String fmt(Duration d) {
      final h = d.inHours.toString().padLeft(2, '0');
      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
      final s = (d.inSeconds % 60).toString().padLeft(2, '0');
      return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
    }
    return '${fmt(pos)} / ${fmt(dur)}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'videoUrl': videoUrl,
        'title': title,
        'positionMs': positionMs,
        'durationMs': durationMs,
        'savedAt': savedAt.toIso8601String(),
        'thumbnailPath': thumbnailPath,
        'httpHeaders': httpHeaders,
        'subtitleUrl': subtitleUrl,
        'danmakuSource': danmakuSource,         
        'danmakuType': danmakuType,             
      };

  factory PlayRecord.fromJson(Map<String, dynamic> json) => PlayRecord(
        id: json['id'] as String,
        videoUrl: json['videoUrl'] as String,
        title: json['title'] as String? ?? L10n.current.unknownVideo,
        positionMs: json['positionMs'] as int? ?? 0,
        durationMs: json['durationMs'] as int? ?? 0,
        savedAt: DateTime.tryParse(json['savedAt'] ?? '') ?? DateTime.now(),
        thumbnailPath: json['thumbnailPath'] as String?,
        httpHeaders: (json['httpHeaders'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v.toString())),
        subtitleUrl: json['subtitleUrl'] as String?,
        danmakuSource: json['danmakuSource'] as String?,         
        danmakuType: json['danmakuType'] as String?,             
      );
}

          
class PlayHistoryService extends ChangeNotifier {
  static const _fileName = 'play_history.json';
  static const _maxRecords = 200;

  List<PlayRecord> _records = [];
  bool _loaded = false;

  List<PlayRecord> get records => List.unmodifiable(_records);
  bool get isLoaded => _loaded;

  Future<void> initialize() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final raw = await file.readAsString();
        final list = (jsonDecode(raw) as List)
            .map((e) => PlayRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        _records = list;
      }
    } catch (e) {
      debugPrint('PlayHistory 加载失败: $e');
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
      final raw = jsonEncode(_records.map((r) => r.toJson()).toList());
      await file.writeAsString(raw);
    } catch (e) {
      debugPrint('PlayHistory 写入失败: $e');
    }
  }

  static String generateId(String videoUrl) {
    String stable;
    try {
      final uri = Uri.parse(videoUrl);
      stable = '${uri.scheme}://${uri.host}${uri.path}';
    } catch (_) {
      stable = videoUrl;
    }
    return md5.convert(utf8.encode(stable)).toString();
  }

  PlayRecord? findByUrl(String videoUrl) {
    final id = generateId(videoUrl);
    try {
      return _records.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  PlayRecord? findById(String id) {
    try {
      return _records.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

                                              
  List<PlayRecord> findByIdPrefix(String prefix) {
    return _records.where((r) => r.id.startsWith(prefix)).toList();
  }

  Future<void> saveProgress({
    required String videoUrl,
    required String title,
    required int positionMs,
    required int durationMs,
    String? thumbnailPath,
    Map<String, String>? httpHeaders,
    String? subtitleUrl,
    String? danmakuSource,         
    String? danmakuType,           
    String? id,                                                     
                                                  
    bool force = false,                        
  }) async {
    if (!force && positionMs < 3000) return;

    final finalId = id ?? generateId(videoUrl);

    if (durationMs > 0 && positionMs / durationMs > 0.95) {
      await removeById(finalId);
      return;
    }

    final existing = _records.indexWhere((r) => r.id == finalId);

    final record = PlayRecord(
      id: finalId,
      videoUrl: videoUrl,
      title: title,
      positionMs: positionMs,
      durationMs: durationMs,
      savedAt: DateTime.now(),
      thumbnailPath: thumbnailPath,
      httpHeaders: httpHeaders,
      subtitleUrl: subtitleUrl,
      danmakuSource: danmakuSource,         
      danmakuType: danmakuType,             
    );

    if (existing >= 0) {
      _records[existing] = record;
    } else {
      _records.insert(0, record);
    }

    if (_records.length > _maxRecords) {
      _records = _records.sublist(0, _maxRecords);
    }

    await _persist();
    notifyListeners();
  }

  Future<void> removeByUrl(String videoUrl) async {
    final id = generateId(videoUrl);
    _records.removeWhere((r) => r.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> removeById(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _records.clear();
    await _persist();
    notifyListeners();
  }
}