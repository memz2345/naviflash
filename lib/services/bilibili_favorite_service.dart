// lib/services/bilibili_favorite_service.dart
//
//   - 收藏夹列表：x/v3/fav/folder/created/list-all
//   - 收藏夹内容：x/v3/fav/resource/list
//   - 加入/移出收藏夹：x/v3/fav/resource/batch-deal（POST）
//
// 重要：B 站收藏夹操作必须携带登录 Cookie。这里**始终**使用
// BilibiliAccountService.rawCookie（不受「携带 Cookie 请求」设置影响），
// 未登录时各方法返回失败原因。
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import '../l10n/l10n_helper.dart';

// ═════════════════════════════════════════
//  模型
// ═════════════════════════════════════════

Map<String, dynamic>? _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

int _toInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}

String _normalizeUrl(String url) {
  if (url.isEmpty) return url;
  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('http://')) return 'https://${url.substring(7)}';
  return url;
}

/// 一个收藏夹。
class BiliFavFolder {
  final int id; // media_id
  final String title;
  final String cover;
  final int mediaCount;
  final int attr; // 可见性等属性位
  final bool isPublic;
  final int favState; // 当前视频是否已在该夹（0/1），收藏夹选择器用

  const BiliFavFolder({
    required this.id,
    required this.title,
    required this.cover,
    required this.mediaCount,
    required this.attr,
    required this.isPublic,
    required this.favState,
  });

  factory BiliFavFolder.fromJson(Map<String, dynamic> json) {
    final attr = _toInt(json['attr']);
    return BiliFavFolder(
      id: _toInt(json['id']),
      title: (json['title'] as String?) ?? '',
      cover: _normalizeUrl((json['cover'] as String?) ?? ''),
      mediaCount: _toInt(json['media_count']),
      attr: attr,
      // attr 第 0 位：0 = 公开，1 = 私密
      isPublic: (attr & 1) == 0,
      favState: _toInt(json['fav_state']),
    );
  }
}

/// 收藏夹里的一个视频。
class BiliFavVideo {
  final int aid;
  final int type; // 2 = 视频稿件，12 = 音频，21 = 视频合集
  final String bvid;
  final String title;
  final String cover;
  final String upper;
  final int duration; // 秒
  final int favTime; // 收藏时间戳
  final int play;
  final int danmaku;
  final int attr; // 0 = 正常；非 0 = 失效（up 删除 / 其他原因）

  const BiliFavVideo({
    required this.aid,
    required this.type,
    required this.bvid,
    required this.title,
    required this.cover,
    required this.upper,
    required this.duration,
    required this.favTime,
    required this.play,
    required this.danmaku,
    required this.attr,
  });

  /// 内容是否已失效（up 删除 / 其他原因），失效内容不跳转播放。
  bool get isUnavailable => attr != 0;

  /// 内容类型展示名（2 = 视频稿件，12 = 音频，21 = 视频合集，其余兜底）。
  String? get typeLabel => switch (type) {
    2 => null,
    12 => '音频',
    21 => '合集',
    _ => null,
  };

  String get url => bvid.isNotEmpty
      ? 'https://www.bilibili.com/video/$bvid'
      : 'https://www.bilibili.com/video/av$aid';

  factory BiliFavVideo.fromJson(Map<String, dynamic> json) {
    final upper = json['upper'];
    final upperName = upper is Map
        ? (upper['name'] as String?) ?? ''
        : (json['upper'] as String?) ?? '';
    final cnt = _asMap(json['cnt_info']);
    return BiliFavVideo(
      aid: _toInt(json['id']),
      type: _toInt(json['type']),
      bvid: (json['bvid'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      cover: _normalizeUrl((json['cover'] as String?) ?? ''),
      upper: upperName,
      duration: _toInt(json['duration']),
      favTime: _toInt(json['fav_time']),
      play: _toInt(cnt?['play']),
      danmaku: _toInt(cnt?['danmaku']),
      attr: _toInt(json['attr']),
    );
  }
}

/// 收藏夹视频分页。
class BiliFavVideoPage {
  final List<BiliFavVideo> videos;
  final bool hasMore;
  final int total;

  const BiliFavVideoPage({
    required this.videos,
    required this.hasMore,
    required this.total,
  });
}

// ═════════════════════════════════════════
//  服务
// ═════════════════════════════════════════

abstract final class BilibiliFavoriteService {
  static const String _folderApi =
      'https://api.bilibili.com/x/v3/fav/folder/created/list-all';
  static const String _resourceApi =
      'https://api.bilibili.com/x/v3/fav/resource/list';
  static const String _batchApi =
      'https://api.bilibili.com/x/v3/fav/resource/batch-deal';
  static const String _addFolderApi =
      'https://api.bilibili.com/x/v3/fav/folder/add';

  /// 最近一次失败原因（供界面展示）。
  static String? lastErrorDetail;

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  /// 是否已登录（有原始 Cookie 即可，不依赖「携带 Cookie」开关）。
  static bool get isLoggedIn => BilibiliAccountService.instance.isLoggedIn;

  /// 当前登录账号 mid（0 表示未登录）。
  static int get mid => BilibiliAccountService.instance.mid;

  /// 请求头：始终携带原始登录 Cookie（不受「携带 Cookie」设置影响）。
  static Map<String, String> _headers() {
    final raw = BilibiliAccountService.instance.rawCookie;
    return {
      ..._defaultHeaders,
      if (raw.isNotEmpty) 'Cookie': raw,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  static String _csrf() {
    final raw = BilibiliAccountService.instance.rawCookie;
    final m = RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(raw);
    return m?.group(1) ?? '';
  }

  /// 当前账号 mid：优先账号服务缓存；缺失时从 Cookie 的 DedeUserID 兜底，
  /// 避免 up_mid=0 导致接口返回 -400。
  static int _accountMid() {
    final cached = BilibiliAccountService.instance.mid;
    if (cached > 0) return cached;
    final raw = BilibiliAccountService.instance.rawCookie;
    final m = RegExp('(?:^|;\\s*)DedeUserID=([^;]+)').firstMatch(raw);
    return m == null ? 0 : (int.tryParse(m.group(1) ?? '') ?? 0);
  }

  /// 拉取收藏夹列表。
  /// [rid]/[type] 传了时，返回的每个收藏夹带 fav_state（该资源是否已收藏）。
  static Future<List<BiliFavFolder>?> fetchFolders({
    int? mid,
    int? rid,
    int? type,
  }) async {
    try {
      if (!isLoggedIn) {
        lastErrorDetail = L10n.current.commentNotLoggedIn;
        return null;
      }
      final params = <String, String>{
        'up_mid': (mid ?? _accountMid()).toString(),
        if (rid != null) 'rid': rid.toString(),
        if (type != null) 'type': type.toString(),
      };
      final uri = Uri.parse(_folderApi).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        return null;
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint('[Fav] 收藏夹 code=${json['code']} ${json['message']}');
        return null;
      }
      final data = _asMap(json['data']);
      if (data == null) return null;
      lastErrorDetail = null;
      return (data['list'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BiliFavFolder.fromJson)
          .toList();
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Fav] 拉取收藏夹异常: $e');
      return null;
    }
  }

  /// 拉取收藏夹内的视频列表。
  ///
  /// [order] 排序：mtime 最近收藏 / view 播放最多 / pubtime 最近投稿；
  /// [keyword] 夹内搜索关键字（空 = 不搜索）；
  /// [tid] 主分区筛选（0 = 全部分区，同 x/v3/fav/resource/list 的 tid 参数）。
  static Future<BiliFavVideoPage?> fetchFolderVideos({
    required int mediaId,
    int pn = 1,
    int ps = 20,
    String order = 'mtime',
    String keyword = '',
    int tid = 0,
  }) async {
    try {
      if (!isLoggedIn) {
        lastErrorDetail = L10n.current.commentNotLoggedIn;
        return null;
      }
      final uri = Uri.parse(_resourceApi).replace(
        queryParameters: {
          'media_id': mediaId.toString(),
          'pn': pn.toString(),
          'ps': ps.toString(),
          'keyword': keyword,
          'order': order,
          'type': '0',
          'tid': tid.toString(),
          'platform': 'web',
        },
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        return null;
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        return null;
      }
      final data = _asMap(json['data']);
      if (data == null) {
        lastErrorDetail = L10n.current.biliResponseNoData;
        return null;
      }
      lastErrorDetail = null;
      return BiliFavVideoPage(
        videos: (data['medias'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(BiliFavVideo.fromJson)
            .toList(),
        hasMore: (data['has_more'] as bool?) ?? false,
        total: _toInt(_asMap(data['info'])?['media_count']),
      );
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Fav] 拉取收藏夹内容异常: $e');
      return null;
    }
  }

  /// 加入 / 移出收藏夹。
  /// [addIds] 要加入的收藏夹 id；[delIds] 要移出的收藏夹 id。
  /// 返回 (ok, message)。
  static Future<({bool ok, String message})> addVideoToFavorites({
    required int aid,
    required List<int> addIds,
    List<int> delIds = const [],
  }) async {
    final csrf = _csrf();
    if (!isLoggedIn) {
      return (ok: false, message: L10n.current.commentNotLoggedIn);
    }
    if (csrf.isEmpty) {
      return (ok: false, message: L10n.current.commentMissingJct);
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_batchApi),
            headers: {
              ..._headers(),
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'resources': '$aid:2',
              'add_media_ids': addIds.join(','),
              'del_media_ids': delIds.join(','),
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}');
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        return (
          ok: false,
          message: '${json['message']}',
        );
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[Fav] 加入收藏夹异常: $e');
      return (ok: false, message: '$e');
    }
  }

  /// [title] 收藏夹名；[isPublic] true 公开，false 私密。
  /// 返回 (ok, message, mediaId)。
  static Future<({bool ok, String message, int mediaId})> createFolder({
    required String title,
    bool isPublic = true,
  }) async {
    final csrf = _csrf();
    if (!isLoggedIn) {
      return (ok: false, message: L10n.current.commentNotLoggedIn, mediaId: 0);
    }
    if (csrf.isEmpty) {
      return (
        ok: false,
        message: L10n.current.commentMissingJct,
        mediaId: 0,
      );
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_addFolderApi),
            headers: {
              ..._headers(),
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'title': title,
              'intro': '',
              'privacy': isPublic ? '0' : '1',
              'cover': '',
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}', mediaId: 0);
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        return (ok: false, message: '${json['message']}', mediaId: 0);
      }
      final data = _asMap(json['data']);
      return (ok: true, message: '', mediaId: _toInt(data?['media_id']));
    } catch (e) {
      debugPrint('[Fav] 新建收藏夹异常: $e');
      return (ok: false, message: '$e', mediaId: 0);
    }
  }
}
