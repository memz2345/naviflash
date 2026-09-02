// lib/services/bilibili_interaction_service.dart
//
// relation 实现，与本项目 Cookie 登录方式对齐）：
//   - 互动状态：x/web-interface/archive/relation（当前账号是否点赞/投币/收藏/关注）
//   - 点赞/取消赞：x/web-interface/archive/like（web 端，csrf）
//   - 投币：        x/web-interface/coin/add
//   - 一键三连：    x/web-interface/archive/like/triple
//   - 收藏/取消：   复用 BilibiliFavoriteService（batch-deal / unfav-all）
//   - 关注/取关：   x/relation/modify
//   - 硬币余额：    x/web-interface/nav（data.money）
//
// 所有互动接口都要求登录，且遵循「携带 Cookie 请求」开关
// （BilibiliAccountService 的「互动操作」Cookie 范围非空才可互动，与评论点赞一致）。
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/network_settings_service.dart';

// ═════════════════════════════════════════
//  模型：当前账号对视频的互动状态
// ═════════════════════════════════════════

class BiliVideoRelation {
  /// 是否已点赞。
  final bool like;

  /// 是否已点踩。
  final bool dislike;

  /// 当前账号已投的硬币数（0 / 1 / 2）。
  final int coin;

  /// 是否已收藏。
  final bool favorite;

  /// 是否已关注 UP 主。
  final bool attention;

  const BiliVideoRelation({
    required this.like,
    required this.dislike,
    required this.coin,
    required this.favorite,
    required this.attention,
  });

  factory BiliVideoRelation.fromJson(Map<String, dynamic> json) {
    return BiliVideoRelation(
      like: _asBool(json['like']),
      dislike: _asBool(json['dislike']),
      coin: _toInt(json['coin']).clamp(0, 2),
      favorite: _asBool(json['favorite']),
      attention: _asBool(json['attention']),
    );
  }
}

/// 一键三连结果（data 字段）。
class BiliTripleResult {
  final bool like;
  final bool coin;
  final bool fav;

  /// 本次投币数（一般为 1）。
  final int multiply;

  const BiliTripleResult({
    required this.like,
    required this.coin,
    required this.fav,
    required this.multiply,
  });

  factory BiliTripleResult.fromJson(Map<String, dynamic> json) {
    return BiliTripleResult(
      like: _asBool(json['like']),
      coin: _asBool(json['coin']),
      fav: _asBool(json['fav']),
      multiply: _toInt(json['multiply']).clamp(1, 2),
    );
  }
}

// ═════════════════════════════════════════
//  工具
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

bool _asBool(dynamic v) => v == true || v == 1 || v == '1';

// ═════════════════════════════════════════
//  服务
// ═════════════════════════════════════════

abstract final class BilibiliInteractionService {
  static const String _relationApi =
      'https://api.bilibili.com/x/web-interface/archive/relation';
  static const String _likeApi =
      'https://api.bilibili.com/x/web-interface/archive/like';
  static const String _coinApi =
      'https://api.bilibili.com/x/web-interface/coin/add';
  static const String _tripleApi =
      'https://api.bilibili.com/x/web-interface/archive/like/triple';
  static const String _unfavAllApi =
      'https://api.bilibili.com/x/v3/fav/resource/unfav-all';
  static const String _relationModApi =
      'https://api.bilibili.com/x/relation/modify';
  static const String _navApi = 'https://api.bilibili.com/x/web-interface/nav';
  //   body: aid + dislike（'0' = 点踩，'1' = 取消点踩）。本项目为 Cookie 登录，
  //   附 csrf 尽力而为，接口返回非 0 时给出可读错误。
  static const String _dislikeApi =
      'https://app.bilibili.com/x/v2/view/dislike';

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  /// 最近一次失败原因（供界面展示）。
  static String? lastErrorDetail;

  /// 是否可互动：已登录且开启「携带 Cookie 请求」（与评论点赞一致）。
  static bool get canInteract =>
      BilibiliAccountService.instance
          .cookieHeaderFor(BiliCookieScope.interactions) !=
      null;

  /// 会话级 buvid3（降低风控 -352 概率，格式同评论区服务）。
  static final String _buvid3 = _genBuvid3();

  static String _genBuvid3() {
    final r = Random();
    String hex(int n) =>
        List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    final uuid =
        '${hex(8)}-${hex(4)}-4${hex(3)}-'
                '${'89ab'[r.nextInt(4)]}${hex(3)}-${hex(12)}'
            .toUpperCase();
    return '$uuid${r.nextInt(100000).toString().padLeft(5, '0')}infoc';
  }

  /// 互动请求头：登录 Cookie + buvid3 + 用户自定义头。
  static Map<String, String> _headers() {
    final cookieHeader = BilibiliAccountService.instance
        .cookieHeaderFor(BiliCookieScope.interactions);
    final cookie = cookieHeader?['Cookie'] ?? '';
    return {
      ..._defaultHeaders,
      if (cookie.isNotEmpty) 'Cookie': '$cookie; buvid3=$_buvid3',
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  /// 当前账号 mid：优先账号服务缓存；缺失时从 Cookie 的 DedeUserID 兜底。
  static int _accountMid() {
    final cached = BilibiliAccountService.instance.mid;
    if (cached > 0) return cached;
    final raw = BilibiliAccountService.instance.rawCookie;
    final m = RegExp('(?:^|;\\s*)DedeUserID=([^;]+)').firstMatch(raw);
    return m == null ? 0 : (int.tryParse(m.group(1) ?? '') ?? 0);
  }

  static String _csrf() {
    final raw = BilibiliAccountService.instance.rawCookie;
    final m = RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(raw);
    return m?.group(1) ?? '';
  }

  /// 拉取当前账号对视频的互动状态（点赞/投币/收藏/关注）。
  /// 未登录或未开启携带 Cookie 时返回 null（不视为错误）。
  static Future<BiliVideoRelation?> fetchVideoRelation({
    required int aid,
    required String bvid,
  }) async {
    if (!canInteract) return null;
    try {
      final uri = Uri.parse(_relationApi).replace(
        queryParameters: {
          'aid': aid.toString(),
          'bvid': bvid,
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
        debugPrint('[BiliInteract] relation code=${json['code']}');
        return null;
      }
      final data = _asMap(json['data']);
      lastErrorDetail = null;
      if (data == null) return null;
      return BiliVideoRelation.fromJson(data);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[BiliInteract] 拉取互动状态异常: $e');
      return null;
    }
  }

  /// 点赞 / 取消点赞。
  /// [like] true = 点赞，false = 取消点赞。
  static Future<({bool ok, String message})> likeVideo({
    required int aid,
    required bool like,
  }) async {
    final csrf = _csrf();
    if (!canInteract) {
      return (ok: false, message: _notLoggedInMsg());
    }
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_likeApi),
            headers: {
              ..._headers(),
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'aid': aid.toString(),
              // web 端：1 = 点赞，2 = 取消赞
              'like': like ? '1' : '2',
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (resp.statusCode != 200 || json['code'] != 0) {
        return (
          ok: false,
          message: resp.statusCode != 200
              ? 'HTTP ${resp.statusCode}'
              : '${json['message']}',
        );
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[BiliInteract] 点赞异常: $e');
      return (ok: false, message: '$e');
    }
  }

  /// 投币。
  /// [multiply] 投币数量（1 或 2）；[selectLike] 是否同时点赞。
  static Future<({bool ok, String message})> coinVideo({
    required int aid,
    required int multiply,
    bool selectLike = false,
  }) async {
    final csrf = _csrf();
    if (!canInteract) {
      return (ok: false, message: _notLoggedInMsg());
    }
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_coinApi),
            headers: {
              ..._headers(),
              'Origin': 'https://www.bilibili.com',
              'Referer': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'aid': aid.toString(),
              'multiply': multiply.toString(),
              'select_like': selectLike ? '1' : '0',
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (resp.statusCode != 200 || json['code'] != 0) {
        final code = json['code'];
        var message = resp.statusCode != 200
            ? 'HTTP ${resp.statusCode}'
            : '${json['message']}';
        if (code == 34005 || code == 34006) {
          message = '硬币不足';
        } else if (code == -403) {
          message = '已超过投币上限';
        }
        return (ok: false, message: message);
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[BiliInteract] 投币异常: $e');
      return (ok: false, message: '$e');
    }
  }

  /// 一键三连（点赞 + 投币 + 收藏）。
  static Future<({bool ok, String message, BiliTripleResult? data})>
  tripleLike({required int aid}) async {
    final csrf = _csrf();
    if (!canInteract) {
      return (ok: false, message: _notLoggedInMsg(), data: null);
    }
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录', data: null);
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_tripleApi),
            headers: {
              ..._headers(),
              'Origin': 'https://www.bilibili.com',
              'Referer': 'https://www.bilibili.com/video/$aid',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'aid': aid.toString(),
              'eab_x': '2',
              'ramval': '0',
              'source': 'web_normal',
              'ga': '1',
              'csrf': csrf,
              'spmid': '333.788.0.0',
              'statistics': '{"appId":100,"platform":5}',
            },
          )
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (resp.statusCode != 200 || json['code'] != 0) {
        return (
          ok: false,
          message: resp.statusCode != 200
              ? 'HTTP ${resp.statusCode}'
              : '${json['message']}',
          data: null,
        );
      }
      final data = _asMap(json['data']);
      return (
        ok: true,
        message: '',
        data: data == null ? null : BiliTripleResult.fromJson(data),
      );
    } catch (e) {
      debugPrint('[BiliInteract] 三连异常: $e');
      return (ok: false, message: '$e', data: null);
    }
  }

  /// 取消收藏（从所有收藏夹移出）。
  static Future<({bool ok, String message})> unfavoriteAll({
    required int aid,
  }) async {
    final csrf = _csrf();
    if (!canInteract) {
      return (ok: false, message: _notLoggedInMsg());
    }
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_unfavAllApi),
            headers: {
              ..._headers(),
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'rid': aid.toString(),
              'type': '2',
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (resp.statusCode != 200 || json['code'] != 0) {
        return (
          ok: false,
          message: resp.statusCode != 200
              ? 'HTTP ${resp.statusCode}'
              : '${json['message']}',
        );
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[BiliInteract] 取消收藏异常: $e');
      return (ok: false, message: '$e');
    }
  }

  /// 关注 / 取消关注 UP 主。
  /// [act] 1 = 关注，2 = 取消关注。
  static Future<({bool ok, String message})> followUser({
    required int mid,
    required int act,
  }) async {
    final csrf = _csrf();
    if (!canInteract) {
      return (ok: false, message: _notLoggedInMsg());
    }
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_relationModApi),
            headers: {
              ..._headers(),
              'Origin': 'https://space.bilibili.com',
              'Referer': 'https://space.bilibili.com/$mid',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'fid': mid.toString(),
              'act': act.toString(),
              're_src': '11',
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (resp.statusCode != 200 || json['code'] != 0) {
        return (
          ok: false,
          message: resp.statusCode != 200
              ? 'HTTP ${resp.statusCode}'
              : '${json['message']}',
        );
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[BiliInteract] 关注异常: $e');
      return (ok: false, message: '$e');
    }
  }

  /// [dislike] true = 点踩，false = 取消点踩。
  /// 该接口为 app 端（access_key 鉴权），本应用为 Cookie 登录，附带
  /// bili_jct csrf 尽力提交；若服务端拒绝（-400 / -101 等）返回可读错误。
  static Future<({bool ok, String message})> dislikeVideo({
    required int aid,
    required bool dislike,
  }) async {
    final csrf = _csrf();
    if (!canInteract) {
      return (ok: false, message: _notLoggedInMsg());
    }
    if (csrf.isEmpty) {
      return (ok: false, message: '缺少 bili_jct，请重新登录');
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_dislikeApi),
            headers: {
              ..._headers(),
              'Origin': 'https://app.bilibili.com',
              'Referer': 'https://app.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'aid': aid.toString(),
              'dislike': dislike ? '0' : '1',
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (resp.statusCode != 200 || json['code'] != 0) {
        return (
          ok: false,
          message: resp.statusCode != 200
              ? 'HTTP ${resp.statusCode}'
              : '${json['message']}',
        );
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[BiliInteract] 点踩异常: $e');
      return (ok: false, message: '$e');
    }
  }

  /// 拉取当前账号硬币余额（未登录 / 异常返回 null）。
  static Future<int?> fetchMyCoins() async {
    if (!canInteract) return null;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(_navApi), headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;
      final money = _asMap(json['data'])?['money'];
      if (money is num) return money.toInt();
      if (money is String) return int.tryParse(money);
      return null;
    } catch (e) {
      debugPrint('[BiliInteract] 拉取硬币余额异常: $e');
      return null;
    }
  }

  /// 当前账号 mid（供收藏夹等接口使用）。
  static int get accountMid => _accountMid();

  static String _notLoggedInMsg() {
    final account = BilibiliAccountService.instance;
    if (!account.isLoggedIn) return '请先登录 B 站账号';
    return '请在网络设置中开启「携带 Cookie 请求」';
  }
}
