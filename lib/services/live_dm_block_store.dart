                                        
                                            
                                                
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_live_service.dart';

class LiveDmBlockStore {
  LiveDmBlockStore._();

  static final LiveDmBlockStore instance = LiveDmBlockStore._();

  static const String _prefsKeywords = 'live_dm_block_keywords';
  static const String _prefsUsers = 'live_dm_block_users';

                  
  final List<String> keywords = [];

                     
  final Map<int, String> users = {};

  bool _loaded = false;
  int _roomId = 0;

  bool get loaded => _loaded;
  bool get isEmpty => keywords.isEmpty && users.isEmpty;

  bool get _loggedIn => BilibiliAccountService.instance.isLoggedIn;

                               
  Future<void> ensureLoaded(int roomId) async {
    if (_loaded && _roomId == roomId) return;
    _roomId = roomId;
    await _loadLocal();
    if (_loggedIn && roomId > 0) {
      final info = await BilibiliLiveService.fetchShieldInfo(roomId);
      if (info != null) {
        for (final k in info.keywords) {
          if (!keywords.contains(k)) keywords.add(k);
        }
        info.users.forEach((uid, name) => users[uid] = name);
        await _persist();
      }
    }
    _loaded = true;
  }

                             
  bool isBlocked(String text, int uid) {
    if (uid > 0 && users.containsKey(uid)) return true;
    if (keywords.isEmpty) return false;
    for (final k in keywords) {
      if (k.isNotEmpty && text.contains(k)) return true;
    }
    return false;
  }

  Future<({bool ok, String message})> addKeyword(String keyword) async {
    final k = keyword.trim();
    if (k.isEmpty) return (ok: false, message: '请输入关键词');
    if (keywords.contains(k)) return (ok: false, message: '该关键词已存在');
    if (_loggedIn && _roomId > 0) {
      final r = await BilibiliLiveService.addShieldKeyword(
        roomId: _roomId,
        keyword: k,
      );
      if (!r.ok) return (ok: false, message: r.message);
    }
    keywords.insert(0, k);
    await _persist();
    return (ok: true, message: '');
  }

  Future<({bool ok, String message})> removeKeyword(String keyword) async {
    if (_loggedIn && _roomId > 0) {
      final r = await BilibiliLiveService.delShieldKeyword(
        roomId: _roomId,
        keyword: keyword,
      );
      if (!r.ok) return (ok: false, message: r.message);
    }
    keywords.remove(keyword);
    await _persist();
    return (ok: true, message: '');
  }

  Future<({bool ok, String message})> addUser(int uid, String name) async {
    if (uid <= 0) return (ok: false, message: '无效用户');
    if (users.containsKey(uid)) return (ok: false, message: '已屏蔽该用户');
    if (_loggedIn && _roomId > 0) {
      final r = await BilibiliLiveService.shieldUser(
        uid: uid,
        roomId: _roomId,
        add: true,
      );
      if (!r.ok) return (ok: false, message: r.message);
    }
    users[uid] = name;
    await _persist();
    return (ok: true, message: '');
  }

  Future<({bool ok, String message})> removeUser(int uid) async {
    if (_loggedIn && _roomId > 0) {
      final r = await BilibiliLiveService.shieldUser(
        uid: uid,
        roomId: _roomId,
        add: false,
      );
      if (!r.ok) return (ok: false, message: r.message);
    }
    users.remove(uid);
    await _persist();
    return (ok: true, message: '');
  }

  Future<void> _loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      keywords
        ..clear()
        ..addAll(prefs.getStringList(_prefsKeywords) ?? const []);
      users.clear();
      final raw = prefs.getString(_prefsUsers);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            final uid = int.tryParse('$key') ?? 0;
            if (uid > 0) users[uid] = '$value';
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[LiveBlock] 读取本地规则失败: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKeywords, keywords);
      await prefs.setString(
        _prefsUsers,
        jsonEncode(users.map((k, v) => MapEntry('$k', v))),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[LiveBlock] 保存本地规则失败: $e');
    }
  }
}
