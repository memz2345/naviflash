                                      
  
                                              
                                
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

              
class FavoriteVideo {
                      
  final String bvid;

                       
  final int aid;

           
  final String title;

                            
  final String cover;

                
  final String author;

           
  final DateTime savedAt;

  const FavoriteVideo({
    required this.bvid,
    required this.aid,
    required this.title,
    required this.cover,
    required this.author,
    required this.savedAt,
  });

                   
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

                  
  bool isFavorite(String bvid) => _items.any((e) => e.bvid == bvid);

             
                                 
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

                 
  Future<void> removeByBvid(String bvid) async {
    final before = _items.length;
    _items.removeWhere((e) => e.bvid == bvid);
    if (_items.length == before) return;
    await _persist();
    notifyListeners();
  }

            
  Future<void> clearAll() async {
    if (_items.isEmpty) return;
    _items = [];
    await _persist();
    notifyListeners();
  }
}
