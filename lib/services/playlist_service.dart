// lib/services/playlist_service.dart
//
// 播放列表数据模型 + 持久化服务
// 注意：类名 Playlist 与 media_kit 同名，player.dart 需使用
// `import 'package:media_kit/media_kit.dart' hide Playlist;` 规避冲突。

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../l10n/l10n_helper.dart';

// ═════════════════════════════════════════
//  数据模型：单集条目
// ═════════════════════════════════════════

class PlaylistItem {
  final String id;
  final String url;
  final String title;
  final int index; // 集数顺序（0 起始，由 service 维护）
  final Map<String, String>? headers; // WebDAV 鉴权头
  final String? subtitleUrl;
  final String? subtitleName;
  final String? authenticatedUrl; // 内嵌鉴权的 URL（封面/直连用）
  final String? danmakuSource; //  弹幕源（'bv' 或 'cid'）
  final String? danmakuType; //  'bv' | 'cid'
  final String? commentSource; //  评论区 oid（番剧每集的 aid，与 cid 不同）

  PlaylistItem({
    required this.id,
    required this.url,
    required this.title,
    required this.index,
    this.headers,
    this.subtitleUrl,
    this.subtitleName,
    this.authenticatedUrl,
    this.danmakuSource,
    this.danmakuType,
    this.commentSource,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'index': index,
        'headers': headers,
        'subtitleUrl': subtitleUrl,
        'subtitleName': subtitleName,
        'authenticatedUrl': authenticatedUrl,
        'danmakuSource': danmakuSource,
        'danmakuType': danmakuType,
        'commentSource': commentSource,
      };

  factory PlaylistItem.fromJson(Map<String, dynamic> json) => PlaylistItem(
        id: (json['id'] as String?) ?? '',
        url: (json['url'] as String?) ?? '',
        title: (json['title'] as String?) ?? L10n.current.commonUnknown,
        index: (json['index'] as int?) ?? 0,
        headers: (json['headers'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v.toString())),
        subtitleUrl: json['subtitleUrl'] as String?,
        subtitleName: json['subtitleName'] as String?,
        authenticatedUrl: json['authenticatedUrl'] as String?,
        danmakuSource: json['danmakuSource'] as String?,
        danmakuType: json['danmakuType'] as String?,
        commentSource: json['commentSource'] as String?,
      );

  PlaylistItem copyWith({
    String? id,
    String? url,
    String? title,
    int? index,
    Map<String, String>? headers,
    String? subtitleUrl,
    String? subtitleName,
    String? authenticatedUrl,
    String? danmakuSource,
    String? danmakuType,
    String? commentSource,
  }) {
    return PlaylistItem(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      index: index ?? this.index,
      headers: headers ?? this.headers,
      subtitleUrl: subtitleUrl ?? this.subtitleUrl,
      subtitleName: subtitleName ?? this.subtitleName,
      authenticatedUrl: authenticatedUrl ?? this.authenticatedUrl,
      danmakuSource: danmakuSource ?? this.danmakuSource,
      danmakuType: danmakuType ?? this.danmakuType,
      commentSource: commentSource ?? this.commentSource,
    );
  }
}

// ═════════════════════════════════════════
//  数据模型：播放列表
// ═════════════════════════════════════════

class Playlist {
  final String id;
  String name; // 可变，便于重命名
  final List<PlaylistItem> items; // 可变列表，service 维护顺序与编号
  final DateTime createdAt;
  DateTime updatedAt;
  int currentIndex; // 当前播放到第几集
  int currentPositionMs; // 当前集进度
  String? backgroundPath; //  自定义背景图路径

  Playlist({
    required this.id,
    required this.name,
    List<PlaylistItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.currentIndex = 0,
    this.currentPositionMs = 0,
    this.backgroundPath,
  })  : items = items ?? <PlaylistItem>[],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  PlaylistItem? get currentItem =>
      (currentIndex >= 0 && currentIndex < items.length)
          ? items[currentIndex]
          : null;

  bool get hasNext => currentIndex < items.length - 1;
  bool get hasPrev => currentIndex > 0;
  int get count => items.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((i) => i.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'currentIndex': currentIndex,
        'currentPositionMs': currentPositionMs,
        'backgroundPath': backgroundPath,
      };

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now();
    return Playlist(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? L10n.current.unnamedPlaylist,
      items: (json['items'] as List?)
              ?.map((e) => PlaylistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <PlaylistItem>[],
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? createdAt,
      currentIndex: (json['currentIndex'] as int?) ?? 0,
      currentPositionMs: (json['currentPositionMs'] as int?) ?? 0,
      backgroundPath: json['backgroundPath'] as String?,
    );
  }
}

// ═════════════════════════════════════════
//  服务
// ═════════════════════════════════════════

class PlaylistService extends ChangeNotifier {
  static const _fileName = 'playlists.json';
  static const _maxPlaylists = 50;

//  FIX: 微秒时间戳 + 自增计数器 + 随机数，杜绝同毫秒 id 碰撞
  // （旧版用毫秒时间戳，同步循环批量导入会生成重复 id，
  //   导致 ReorderableListView 的 ValueKey 冲突崩溃）
  static int _idCounter = 0;
  static final Random _rng = Random();

  List<Playlist> _playlists = [];
  bool _loaded = false;

  List<Playlist> get playlists => List.unmodifiable(_playlists);
  bool get isLoaded => _loaded;

  static String generateId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final raw = '$ts-${_idCounter++}-${_rng.nextInt(0x7fffffff)}';
    return md5.convert(utf8.encode(raw)).toString().substring(0, 16);
  }

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  // ─── 初始化 ───

  Future<void> initialize() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final raw = await file.readAsString();
        _playlists = (jsonDecode(raw) as List)
            .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
            .toList();
        _sanitizeLoadedData(); //  FIX: 修复历史坏数据
      }
    } catch (e) {
      debugPrint('PlaylistService 加载失败: $e');
    }
    _loaded = true;
    notifyListeners();
  }

///  FIX: 清洗加载数据 —— 修复重复/空 id、index 编号错乱、越界进度
  void _sanitizeLoadedData() {
    var changed = false;
    for (final p in _playlists) {
      // 1) 重复 / 空 id 重新分配
      final used = <String>{};
      for (var i = 0; i < p.items.length; i++) {
        final item = p.items[i];
        if (item.id.isEmpty || used.contains(item.id)) {
          final newId = generateId();
          p.items[i] = item.copyWith(id: newId);
          used.add(newId);
          changed = true;
        } else {
          used.add(item.id);
        }
      }
      // 2) index 编号与位置对齐
      for (var i = 0; i < p.items.length; i++) {
        if (p.items[i].index != i) {
          p.items[i] = p.items[i].copyWith(index: i);
          changed = true;
        }
      }
      // 3) currentIndex / position 越界保护
      if (p.items.isEmpty) {
        if (p.currentIndex != 0) {
          p.currentIndex = 0;
          changed = true;
        }
      } else if (p.currentIndex < 0 || p.currentIndex >= p.items.length) {
        p.currentIndex = 0;
        changed = true;
      }
      if (p.currentPositionMs < 0) {
        p.currentPositionMs = 0;
        changed = true;
      }
    }
    if (changed) _persist();
  }

  Future<void> _persist() async {
    try {
      final file = await _file;
      final raw = jsonEncode(_playlists.map((p) => p.toJson()).toList());
      await file.writeAsString(raw);
    } catch (e) {
      debugPrint('PlaylistService 写入失败: $e');
    }
  }

  // ─── 查询 ───

  Playlist? findById(String id) {
    for (final p in _playlists) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ─── CRUD ───

  Future<Playlist> createPlaylist({
    required String name,
    required List<PlaylistItem> items,
  }) async {
//  FIX: 创建时统一重新编号，避免外部传入的 index 脏数据
    final normalized = <PlaylistItem>[
      for (var i = 0; i < items.length; i++) items[i].copyWith(index: i),
    ];
    final playlist = Playlist(
      id: generateId(),
      name: name,
      items: normalized,
      createdAt: DateTime.now(),
    );
    _playlists.insert(0, playlist);
    if (_playlists.length > _maxPlaylists) {
      _playlists = _playlists.sublist(0, _maxPlaylists);
    }
    await _persist();
    notifyListeners();
    return playlist;
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final p = findById(id);
    final trimmed = newName.trim();
    if (p == null || trimmed.isEmpty) return;
    p.name = trimmed;
    p.updatedAt = DateTime.now();
    await _persist();
    notifyListeners();
  }


  Future<void> setBackgroundPath(String id, String? path) async {
    final p = findById(id);
    if (p == null) return;
    p.backgroundPath = path;
    p.updatedAt = DateTime.now();
    await _persist();
    notifyListeners();
  }

  /// 从相册选择背景图并复制到应用文档目录，成功后替换旧图
  Future<bool> pickAndSaveBackground(String id) async {
    final p = findById(id);
    if (p == null) return false;
    try {
      final pickedFile = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (pickedFile == null) return false;
      final dir = await getApplicationDocumentsDirectory();
      final bgDir = Directory('${dir.path}/playlist_backgrounds');
      if (!await bgDir.exists()) await bgDir.create(recursive: true);
      final fileName =
          'bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${bgDir.path}/$fileName';
      await File(pickedFile.path).copy(savedPath);
      // 删除旧背景图
      if (p.backgroundPath != null) {
        try {
          final oldFile = File(p.backgroundPath!);
          if (await oldFile.exists()) await oldFile.delete();
        } catch (e) {
          if (kDebugMode) debugPrint('删除旧背景图失败: $e');
        }
      }
      await setBackgroundPath(id, savedPath);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('选择播放列表背景失败: $e');
      return false;
    }
  }

  Future<void> removeBackground(String id) async {
    final p = findById(id);
    if (p == null) return;
    if (p.backgroundPath != null) {
      try {
        final file = File(p.backgroundPath!);
        if (await file.exists()) await file.delete();
      } catch (e) {
        if (kDebugMode) debugPrint('删除背景图失败: $e');
      }
    }
    await setBackgroundPath(id, null);
  }

///  NEW: 整体替换集数列表（编辑保存用，保留 id 与播放进度，
  ///  替代旧的「delete + create」方案，避免丢失进度和改变 id）
  Future<void> updatePlaylistItems(String id, List<PlaylistItem> items) async {
    final p = findById(id);
    if (p == null) return;
    p.items
      ..clear()
      ..addAll(
          [for (var i = 0; i < items.length; i++) items[i].copyWith(index: i)]);
    if (p.currentIndex >= p.items.length) {
      p.currentIndex = p.items.length - 1;
    }
    p.updatedAt = DateTime.now();
    await _persist();
    notifyListeners();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _playlists.clear();
    await _persist();
    notifyListeners();
  }

  // ─── 集数管理 ───

  Future<void> addItem(String playlistId, PlaylistItem item) =>
      addItems(playlistId, [item]);

  Future<void> addItems(String playlistId, List<PlaylistItem> newItems) async {
    final p = findById(playlistId);
    if (p == null || newItems.isEmpty) return;
    for (final item in newItems) {
      p.items.add(item.copyWith(index: p.items.length));
    }
    p.updatedAt = DateTime.now();
    await _persist();
    notifyListeners();
  }

  Future<void> removeItem(String playlistId, int index) async {
    final p = findById(playlistId);
    if (p == null || index < 0 || index >= p.items.length) return;
    p.items.removeAt(index);
    _reindex(p);
//  FIX: 列表缩短后钳制 currentIndex，防止越界
    if (p.currentIndex >= p.items.length) {
      p.currentIndex = p.items.length - 1;
    }
    p.updatedAt = DateTime.now();
    await _persist();
    notifyListeners();
  }

///  按顺序（1、2、3...）为列表前 N 集附加弹幕源（cid），
  /// 同时可附带评论区 oid（aid）。返回实际附加成功的集数。
  Future<int> attachDanmakuToItems(
    String playlistId,
    List<String> cidList, {
    List<String>? aidList,
  }) async {
    final p = findById(playlistId);
    if (p == null || cidList.isEmpty) return 0;
    var attached = 0;
    for (var i = 0; i < cidList.length && i < p.items.length; i++) {
      p.items[i] = p.items[i].copyWith(
        danmakuSource: cidList[i],
        danmakuType: 'cid',
        commentSource: aidList != null && i < aidList.length
            ? (aidList[i].isEmpty || aidList[i] == '0'
                ? p.items[i].commentSource
                : aidList[i])
            : p.items[i].commentSource,
      );
      attached++;
    }
    if (attached > 0) {
      p.updatedAt = DateTime.now();
      await _persist();
      notifyListeners();
    }
    return attached;
  }

  Future<void> moveItem(String playlistId, int from, int to) async {
    final p = findById(playlistId);
    if (p == null || from == to) return;
    if (from < 0 || from >= p.items.length) return;
    if (to < 0 || to >= p.items.length) return;
    final item = p.items.removeAt(from);
    p.items.insert(to, item);
    _reindex(p);
    p.updatedAt = DateTime.now();
    await _persist();
    notifyListeners();
  }

  void _reindex(Playlist p) {
    for (var i = 0; i < p.items.length; i++) {
      p.items[i] = p.items[i].copyWith(index: i);
    }
  }

  // ─── 播放进度 ───

  Future<void> updateProgress({
    required String playlistId,
    required int episodeIndex,
    required int positionMs,
  }) async {
    final p = findById(playlistId);
    if (p == null) return;
//  FIX: 越界保护（旧版直接赋值可能存进非法 index）
    if (episodeIndex >= 0 && episodeIndex < p.items.length) {
      p.currentIndex = episodeIndex;
    }
    if (positionMs >= 0) {
      p.currentPositionMs = positionMs;
    }
    p.updatedAt = DateTime.now();
    await _persist();
    notifyListeners();
  }

  // ─── 云同步：导出 / 合并 / 恢复 ───

  /// 导出全部播放列表为 JSON 字符串（云同步上传用）。
  String exportJson() {
    return jsonEncode(_playlists.map((p) => p.toJson()).toList());
  }

  /// 合并云端播放列表：按 id 去重，同 id 取 updatedAt 较新者。
  /// 返回合并统计（新增 / 更新 / 无变化），并持久化。
  Future<({int added, int updated, int unchanged})> mergeFromJson(
    String json,
  ) async {
    int added = 0;
    int updated = 0;
    int unchanged = 0;
    try {
      final remote = (jsonDecode(json) as List)
          .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
          .toList();

      final localById = {for (final p in _playlists) p.id: p};
      for (final rp in remote) {
        if (rp.id.isEmpty) continue;
        final lp = localById[rp.id];
        if (lp == null) {
          _playlists.add(rp);
          added++;
        } else if (rp.updatedAt.isAfter(lp.updatedAt)) {
          // 整体替换为较新版本
          final idx = _playlists.indexOf(lp);
          _playlists[idx] = rp;
          updated++;
        } else {
          unchanged++;
        }
      }
      // 注意：不做「本地有而远端没有 → 删除」的传播，
      // 避免首次同步/单侧离线时误删本地数据；删除暂不同步。
      if (_playlists.length > _maxPlaylists) {
        _playlists = _playlists.sublist(0, _maxPlaylists);
      }
      await _persist();
      notifyListeners();
    } catch (e) {
      debugPrint('PlaylistService 合并失败: $e');
    }
    return (added: added, updated: updated, unchanged: unchanged);
  }

  /// 用云端数据整体替换本地（从云端恢复）。
  /// 返回恢复的播放列表数量。
  Future<int> replaceFromJson(String json) async {
    try {
      final remote = (jsonDecode(json) as List)
          .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
          .toList();
      _playlists = remote;
      _sanitizeLoadedData();
      await _persist();
      notifyListeners();
      return remote.length;
    } catch (e) {
      debugPrint('PlaylistService 恢复失败: $e');
      return 0;
    }
  }
}