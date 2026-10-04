                                          
  
                                               
                                              
                                                           
                                            
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:path_provider/path_provider.dart';

                                            
             
                                            

class BiliNoteDraft {
  final String bvid;
  final String title;
  final String content;

                    
  final int updatedAt;

                                        
  final bool published;

  const BiliNoteDraft({
    required this.bvid,
    this.title = '',
    this.content = '',
    this.updatedAt = 0,
    this.published = false,
  });

  BiliNoteDraft copyWith({
    String? title,
    String? content,
    int? updatedAt,
    bool? published,
  }) =>
      BiliNoteDraft(
        bvid: bvid,
        title: title ?? this.title,
        content: content ?? this.content,
        updatedAt: updatedAt ?? this.updatedAt,
        published: published ?? this.published,
      );

  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        'bvid': bvid,
        'title': title,
        'content': content,
        'updated_at': updatedAt,
        'published': published,
      };

  factory BiliNoteDraft.fromJson(Map<String, dynamic> json) => BiliNoteDraft(
        bvid: json['bvid'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
        published: json['published'] as bool? ?? false,
      );
}

                                            
                                    
                                            

abstract final class NoteDraftCache {
  static const String dirName = 'note_drafts';

                           
  static const int _maxFiles = 100;

  static Future<Directory> get _dir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _fileName(String bvid) =>
      md5.convert(utf8.encode('note_draft_$bvid')).toString();

  static Future<File> _file(String bvid) async {
    final dir = await _dir;
    return File('${dir.path}/${_fileName(bvid)}.json');
  }

                   
  static Future<void> save(BiliNoteDraft draft) async {
    if (draft.bvid.isEmpty) return;
    try {
      final file = await _file(draft.bvid);
      await file.writeAsString(jsonEncode(draft.toJson()), flush: true);
      await _evictIfOverMax();
    } catch (e) {
      debugPrint('[NoteDraft] 保存草稿失败: $e');
    }
  }

                          
  static Future<BiliNoteDraft?> load(String bvid) async {
    if (bvid.isEmpty) return null;
    try {
      final file = await _file(bvid);
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) return null;
      final draft = BiliNoteDraft.fromJson(json);
      return draft.bvid == bvid ? draft : null;
    } catch (e) {
      debugPrint('[NoteDraft] 读取草稿失败: $e');
      return null;
    }
  }

                        
  static Future<void> remove(String bvid) async {
    if (bvid.isEmpty) return;
    try {
      final file = await _file(bvid);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('[NoteDraft] 删除草稿失败: $e');
    }
  }

                                
  static Future<List<BiliNoteDraft>> listAll() async {
    try {
      final dir = await _dir;
      if (!await dir.exists()) return const [];
      final drafts = <BiliNoteDraft>[];
      await for (final e in dir.list()) {
        if (e is! File || !e.path.endsWith('.json')) continue;
        try {
          final json = jsonDecode(await e.readAsString());
          if (json is Map<String, dynamic>) {
            drafts.add(BiliNoteDraft.fromJson(json));
          }
        } catch (_) {
                             
        }
      }
      drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return drafts;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> clearAll() async {
    try {
      final dir = await _dir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[NoteDraft] 清空草稿失败: $e');
    }
  }

  static Future<void> _evictIfOverMax() async {
    try {
      final dir = await _dir;
      final files = <File>[];
      await for (final e in dir.list()) {
        if (e is File && e.path.endsWith('.json')) files.add(e);
      }
      if (files.length <= _maxFiles) return;
                       
      final stats = <(File, DateTime)>[];
      for (final f in files) {
        late DateTime modified;
        try {
          modified = await f.lastModified();
        } catch (_) {
          modified = DateTime.fromMillisecondsSinceEpoch(0);
        }
        stats.add((f, modified));
      }
      stats.sort((a, b) => a.$2.compareTo(b.$2));
      final toDelete = stats.length - _maxFiles;
      for (var i = 0; i < toDelete; i++) {
        try {
          await stats[i].$1.delete();
        } catch (_) {
                        
        }
      }
    } catch (_) {
                     
    }
  }
}

                                            
           
                                            

         
enum BiliNotePublishResult {
  success,
  notLoggedIn,
  networkError,
  apiRejected,
}

abstract final class BilibiliNoteService {
  static const String _addNoteApi = 'https://api.bilibili.com/x/note/add';

  static String _extractCookie(String cookie, String name) {
    final m = RegExp('(?:^|;\\s*)$name=([^;]+)').firstMatch(cookie);
    return m?.group(1) ?? '';
  }

                                               
                             
  static bool get canPublish {
    final cookieHeader = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.video,
    );
    final raw = cookieHeader?['Cookie'] ?? '';
    return _extractCookie(raw, 'bili_jct').isNotEmpty;
  }

                                                 
                                  
  static String buildDeltaContent(String text) {
    final ops = <Map<String, dynamic>>[];
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        ops.add({'insert': '\n'});
      } else {
        ops.add({'insert': '$line\n'});
      }
    }
    if (ops.isEmpty) ops.add({'insert': '\n'});
    return jsonEncode(ops);
  }

                                               
                               
  static String buildSummary(String text) {
    final flat = text
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n+'), '\n')
        .trim();
    if (flat.isEmpty) return '我发布了一篇笔记，快来看看吧~';
    if (flat.length <= 77) return flat;
    return '${flat.substring(0, 77)}...';
  }

                                          
  static bool contentValid(String text) => text.trim().length >= 10;

                                              
                                                          
                        
                                                
                       
  static Future<({BiliNotePublishResult result, int? noteId})> publish({
    required int aid,
    required String fallbackTitle,
    String title = '',
    required String summary,
    required String deltaContent,
    int? noteId,
    bool publish = true,
  }) async {
    final cookieHeader = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.video,
    );
    final raw = cookieHeader?['Cookie'] ?? '';
    final csrf = _extractCookie(raw, 'bili_jct');
    if (csrf.isEmpty) return (result: BiliNotePublishResult.notLoggedIn, noteId: null);

                                             
    final effectiveTitle = (title.trim().isNotEmpty
            ? title.trim()
            : fallbackTitle)
        .trim();
    final truncatedTitle = effectiveTitle.length > 40
        ? effectiveTitle.substring(0, 40)
        : effectiveTitle;

    Future<({BiliNotePublishResult result, int? noteId})> submit(
      int? nid,
    ) async {
      try {
        final client = await NetworkSettingsService.instance.getApiClient();
        final resp = await client
            .post(
              Uri.parse(_addNoteApi),
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                    '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Referer': 'https://www.bilibili.com',
                'Content-Type': 'application/x-www-form-urlencoded',
                if (cookieHeader != null) ...cookieHeader,
              },
              body: {
                'from': 'save',
                'oid': aid.toString(),
                'oid_type': '0',
                if (nid != null) 'note_id': nid.toString(),
                'title': truncatedTitle,
                'summary': summary,
                'content': deltaContent,
                'cont_len': deltaContent.length.toString(),
                'platform': 'web',
                'cls': '1',
                if (publish) ...{
                  'publish': '1',
                  'original': '1',
                  'auto_comment': '0',
                  'comment_format': '2',
                },
                'csrf': csrf,
              }.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&'),
            )
            .timeout(const Duration(seconds: 15));
        if (resp.statusCode != 200) {
          return (result: BiliNotePublishResult.networkError, noteId: null);
        }
        final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
        final code = (json['code'] as num?)?.toInt() ?? -1;
        if (code == 0) {
          final nid = (_asInt(_asMap(json['data'])?['note_id']));
          return (result: BiliNotePublishResult.success, noteId: nid);
        }
        debugPrint('[Note] 发布笔记失败 code=$code ${json['message']}');
                                                 
        if (code == 79508 && nid == null) {
          final existing = await fetchArchiveNoteId(aid: aid);
          if (existing != null) return await submit(existing);
        }
        return (result: BiliNotePublishResult.apiRejected, noteId: null);
      } catch (e) {
        debugPrint('[Note] 发布笔记异常: $e');
        return (result: BiliNotePublishResult.networkError, noteId: null);
      }
    }

    return await submit(noteId);
  }

                                               
                                        
  static Future<int?> fetchArchiveNoteId({required int aid}) async {
    final cookieHeader = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.video,
    );
    if (cookieHeader == null) return null;
    try {
      final uri = Uri.parse('https://api.bilibili.com/x/note/list/archive')
          .replace(
            queryParameters: {
              'oid': aid.toString(),
              'oid_type': '0',
            },
          );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: {..._baseHeaders(), ...cookieHeader})
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if ((json['code'] as num?)?.toInt() != 0) return null;
      final ids = _asMap(json['data'])?['noteIds'];
      if (ids is! List || ids.isEmpty) return null;
      return _asInt(ids.first);
    } catch (e) {
      debugPrint('[Note] 查询已有笔记异常: $e');
      return null;
    }
  }

  static Map<String, String> _baseHeaders() => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.bilibili.com',
      };

  static int? _asInt(Object? v) => v == null ? null : (v is int ? v : int.tryParse('$v'));

  static Map<String, dynamic>? _asMap(Object? v) =>
      v is Map<String, dynamic> ? v : null;
}
