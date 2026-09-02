// lib/services/favorites_service.dart
//
// 本地收藏夹服务：把 B 站视频收藏到本地，记录 BV / AV、封面、标题、UP 主。
// 持久化方式与播放历史一致：JSON 文件写入应用文档目录。
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 一条本地收藏的视频。
class FavoriteVideo {
  /// BV 号（唯一键，大小写敏感）。
  final String bvid;

  /// AV 号（由 BV 转换，可空）。
  final int aid;

  /// 视频标题。
  final String title;

  /// 封面完整地址（已处理尺寸参数，可直接加载）。
  final String cover;

  /// UP 主名（可空）。
  final String author;

  /// 收藏时间。
  final DateTime savedAt;

  const FavoriteVideo({
    required this.bvid,
    required this.aid,
    required this.title,
    required this.cover,
    required this.author,
    required this.savedAt,
  });

  /// 视频在 B 站的可读地址。
  String get url => 'https://www.bilibili.com/video/$bvid';

  Map<String, dynamic> toJson() => {
        'bvid': bvid,
        'aid': aid,
        'title': title,
        'cover': cover,
        'author': author,
        'savedAt': savedAt.toIso8601String(),
      };

  factory FavoriteVideo.fromJson(Map<String, dynamic> json) => FavoriteVideo(
        bvid: (json['bvid'] as String?) ?? '',
        aid: (json['aid'] as num?)?.toInt() ?? 0,
        title: (json['title'] as String?) ?? '',
        cover: (json['cover'] as String?) ?? '',
        author: (json['author'] as String?) ?? '',
        savedAt: DateTime.tryParse((json['savedAt'] as String?) ?? '') ??
            DateTime.now(),
      );
}

class FavoritesService extends ChangeNotifier {
  static const String _fileName = 'favorites.json';

  List<FavoriteVideo> _items = [];
  bool _loaded = false;

  /// 收藏列表（最新收藏在前）。
  List<FavoriteVideo> get items => List.unmodifiable(_items);

  bool get isLoaded => _loaded;

  Future<void> initialize() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final raw = await file.readAsString();
        final list = (jsonDecode(raw) as List)
            .map((e) => FavoriteVideo.fromJson(e as Map<String, dynamic>))
            .toList();
        _items = list;
      }
    } catch (e) {
      debugPrint('收藏夹加载失败: $e');
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
      final raw = jsonEncode(_items.map((e) => e.toJson()).toList());
      await file.writeAsString(raw);
    } catch (e) {
      debugPrint('收藏夹写入失败: $e');
    }
  }

  /// 是否已收藏该 BV 号。
  bool isFavorite(String bvid) => _items.any((e) => e.bvid == bvid);

  /// 切换收藏状态。
  /// 返回 true 表示已收藏，false 表示取消收藏。
  Future<bool> toggle({
    required String bvid,
    required int aid,
    required String title,
    required String cover,
    required String author,
  }) async {
    final existing = _items.indexWhere((e) => e.bvid == bvid);
    if (existing >= 0) {
      _items.removeAt(existing);
      await _persist();
      notifyListeners();
      return false;
    }
    _items.insert(
      0,
      FavoriteVideo(
        bvid: bvid,
        aid: aid,
        title: title,
        cover: cover,
        author: author,
        savedAt: DateTime.now(),
      ),
    );
    await _persist();
    notifyListeners();
    return true;
  }

  /// 按 BV 号取消收藏。
  Future<void> removeByBvid(String bvid) async {
    final before = _items.length;
    _items.removeWhere((e) => e.bvid == bvid);
    if (_items.length == before) return;
    await _persist();
    notifyListeners();
  }

  /// 清空收藏夹。
  Future<void> clearAll() async {
    if (_items.isEmpty) return;
    _items = [];
    await _persist();
    notifyListeners();
  }
}
