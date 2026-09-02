// lib/services/bilibili_search_service.dart
//
//   - 分类搜索：x/web-interface/wbi/search/type，支持 video / media_bangumi /
//     media_ft / live_room / bili_user / article 六类，均需 WBI 签名
//   - 结果标题里 B 站返回 <em class="keyword"> 高亮标签，统一解析成
//     (text, highlight) 段列表供 UI 高亮渲染
//   - 风控验证：响应 data.v_voucher 非空时走 gaia-vgate 验证码流程——
//     ① register（x/gaia-vgate/v1/register，v_voucher → token + geetest gt/challenge）
//     ② 极验滑块弹窗（复用 screens/geetest_dialog.dart 的 showGeetestDialog）
//     ③ validate（x/gaia-vgate/v1/validate，极验结果 → grisk_id）
//     ④ 把 grisk_id 作为 Cookie x-bili-gaia-vtoken 携带重试原搜索
// 请求方式与用户空间/评论服务一致：复用 NetworkSettingsService 客户端与请求头，
// 设备指纹（buvid3/buvid4/b_lsid）+ 登录 Cookie 降低风控概率。
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart' show WbiSign;
import 'package:naviflash/services/network_settings_service.dart';
import '../l10n/l10n_helper.dart';

// ═════════════════════════════════════════
//  安全解析工具（复用用户空间服务的解析风格）
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

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim()) ?? 0;
  return 0;
}

/// 安全解析列表：值为 String / Map 等非 List 类型时返回 null，
/// 避免 `as List<dynamic>?` 在字段类型不符时抛类型强转异常。
List<dynamic>? _asList(dynamic v) => v is List ? v : null;

/// 去掉 B 站返回文本里的 HTML 标签（<em>…</em> 等）。
String _stripHtml(String s) {
  if (s.isEmpty) return s;
  return s.replaceAll(RegExp(r'<[^>]+>'), '');
}

/// 把带 <em class="keyword"> 的标题解析成 (text, highlight) 段列表。
/// 无 <em> 时退化为单段纯文本；若 [fallbackKeyword] 非空且没有 <em> 高亮，
/// 则按关键词在文本中手动拆分高亮（忽略大小写，命中全部出现位置）。
List<({String text, bool highlight})> _parseTitleEm(
  String raw, {
  String fallbackKeyword = '',
}) {
  final segments = <({String text, bool highlight})>[];
  final emReg = RegExp(r'<em[^>]*>(.*?)</em>', dotAll: true);
  var last = 0;
  for (final m in emReg.allMatches(raw)) {
    if (m.start > last) {
      segments.add((text: raw.substring(last, m.start), highlight: false));
    }
    segments.add((text: _stripHtml(m.group(1) ?? ''), highlight: true));
    last = m.end;
  }
  if (last < raw.length) {
    segments.add((text: raw.substring(last), highlight: false));
  }
  if (segments.isEmpty) {
    segments.add((text: _stripHtml(raw), highlight: false));
  }
  final hasHighlight = segments.any((s) => s.highlight);
  if (!hasHighlight && fallbackKeyword.isNotEmpty) {
    return _highlightPlain(_stripHtml(raw), fallbackKeyword);
  }
  return segments;
}

/// 按关键词手动拆分纯文本高亮。
List<({String text, bool highlight})> _highlightPlain(
  String text,
  String keyword,
) {
  final segments = <({String text, bool highlight})>[];
  if (keyword.isEmpty) {
    segments.add((text: text, highlight: false));
    return segments;
  }
  final lower = text.toLowerCase();
  final kw = keyword.toLowerCase();
  var last = 0;
  var idx = lower.indexOf(kw);
  while (idx != -1) {
    if (idx > last) {
      segments.add((text: text.substring(last, idx), highlight: false));
    }
    segments.add((text: text.substring(idx, idx + kw.length), highlight: true));
    last = idx + kw.length;
    idx = lower.indexOf(kw, last);
  }
  if (last < text.length) {
    segments.add((text: text.substring(last), highlight: false));
  }
  if (segments.isEmpty) {
    segments.add((text: text, highlight: false));
  }
  return segments;
}

String _normalizeUrl(String url) {
  if (url.startsWith('//')) return 'https:$url';
  return url;
}

String _formatCount(int n) {
  final unit = L10n.current.tenThousandUnit;
  final usesK = unit == 'K';
  if (n >= (usesK ? 1000 : 10000)) {
    final v = n / (usesK ? 1000 : 10000);
    return '${v.toStringAsFixed(v >= 100 ? 0 : 1)}$unit';
  }
  return '$n';
}

// ═════════════════════════════════════════
//  搜索类型
// ═════════════════════════════════════════

enum BiliSearchType {
  video('video'),
  mediaBangumi('media_bangumi'),
  mediaFt('media_ft'),
  liveRoom('live_room'),
  biliUser('bili_user'),
  article('article');

  const BiliSearchType(this.code);

  final String code;

  String get label => switch (this) {
    BiliSearchType.video => L10n.current.searchTypeVideo,
    BiliSearchType.mediaBangumi => L10n.current.searchTypeBangumi,
    BiliSearchType.mediaFt => L10n.current.searchTypeFt,
    BiliSearchType.liveRoom => L10n.current.searchTypeLive,
    BiliSearchType.biliUser => L10n.current.searchTypeUser,
    BiliSearchType.article => L10n.current.searchTypeArticle,
  };
}

// ═════════════════════════════════════════
//  模型：统一搜索结果条目
// ═════════════════════════════════════════

class BiliSearchItem {
  final BiliSearchType type;

  /// 用户 mid（biliUser 类型跳转空间页用；其余类型为 0）。
  final int mid;

  /// 标题高亮段（命中关键词的段 highlight=true）。
  final List<({String text, bool highlight})> titleSegments;

  /// 封面/头像地址（可空）。
  final String cover;

  /// 副标题：UP 主名 / UP 名 / 房主名 / 专栏分类。
  final String subtitle;

  /// 统计文本：播放·弹幕 / 在线 / 粉丝·视频 / 阅读·评论 等。
  final String meta;

  /// 角标（直播 / 课堂 / 合作 / 更新中 等）。
  final String badge;

  /// 时长 / 更新话数。
  final String duration;

  /// 点击跳转 URL。
  final String actionUrl;

  /// 简介（可空）。
  final String desc;

  /// 播放数（video 类型有效，其余为 0；双列网格封面角标用）。
  final int play;

  /// 弹幕数（video 类型有效，其余为 0）。
  final int danmaku;

  /// 条目在 B 站的资源 id（专栏为 cvid，其余类型为 0），
  /// 供应用内查看器直接拉取详情（如 ArticlePage）。
  final int id;

  /// 视频 BV 号（video 类型有效，其余类型为空），供复制 BV / 转换 AV 用。
  final String bvid;

  /// 番剧 SS 号（media_bangumi / media_ft 类型有效，其余为 0），
  /// 供应用内番剧播放页直接拉取详情（如 BilibiliBangumiPage）。
  final int seasonId;

  /// 直播间号（liveRoom 类型有效，其余为 0），
  /// 供应用内直播间查看页直接开播（如 BilibiliLiveRoomPage）。
  final int roomId;

  const BiliSearchItem({
    required this.type,
    required this.mid,
    required this.titleSegments,
    required this.cover,
    required this.subtitle,
    required this.meta,
    required this.badge,
    required this.duration,
    required this.actionUrl,
    required this.desc,
    this.play = 0,
    this.danmaku = 0,
    this.id = 0,
    this.bvid = '',
    this.seasonId = 0,
    this.roomId = 0,
  });
}

/// 一页搜索结果。
class BiliSearchPage {
  final List<BiliSearchItem> items;
  final int numResults;
  final int page;
  final int pageSize;

  const BiliSearchPage({
    required this.items,
    required this.numResults,
    required this.page,
    required this.pageSize,
  });
}

// ═════════════════════════════════════════
//  模型：搜索建议
// ═════════════════════════════════════════

class BiliSearchSuggest {
  final String keyword; // 搜索词（点击建议时用于搜索）
  final String display; // 显示文本（已去除 <em> 高亮标签）

  const BiliSearchSuggest({required this.keyword, required this.display});
}

// ═════════════════════════════════════════
//  搜索结果（可能触发风控验证码）
// ═════════════════════════════════════════

sealed class BiliSearchResult {}

/// 正常返回结果。
class BiliSearchOk extends BiliSearchResult {
  final BiliSearchPage page;
  BiliSearchOk(this.page);
}

/// 触发风控：data.v_voucher 非空，需要走极验滑块验证码。
/// 用 [vVoucher] 走 register → 极验 → validate 拿到 grisk_id 后重试。
class BiliSearchCaptcha extends BiliSearchResult {
  final String vVoucher;
  BiliSearchCaptcha(this.vVoucher);
}

/// 请求失败（网络 / 非 0 业务码 / 解析失败）。
class BiliSearchError extends BiliSearchResult {
  final String detail;
  BiliSearchError(this.detail);
}

// ═════════════════════════════════════════
//  服务
// ═════════════════════════════════════════

abstract final class BilibiliSearchService {
  static const String _searchApi =
      'https://api.bilibili.com/x/web-interface/wbi/search/type';
  static const String _suggestApi =
      'https://s.search.bilibili.com/main/suggest';
  static const String _gaiaRegisterApi =
      'https://api.bilibili.com/x/gaia-vgate/v1/register';
  static const String _gaiaValidateApi =
      'https://api.bilibili.com/x/gaia-vgate/v1/validate';
  static const String _spiApi =
      'https://api.bilibili.com/x/frontend/finger/spi';

  /// 最近一次失败的具体原因（供界面展示，便于诊断）。
  static String? lastErrorDetail;

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://search.bilibili.com',
  };

  // ── 设备指纹与请求头（与用户空间服务同款）──

  static String? _spiBuvid3;
  static String? _spiBuvid4;

  static Future<void> _ensureDeviceFp() async {
    if (_spiBuvid3 != null) return;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(_spiApi), headers: _defaultHeaders)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return;
      final data = _asMap(json['data']);
      if (data == null) return;
      final b3 = (data['b_3'] as String?) ?? '';
      if (b3.isNotEmpty) {
        _spiBuvid3 = b3;
        _spiBuvid4 = (data['b_4'] as String?) ?? '';
      }
    } catch (e) {
      debugPrint('[Search] 获取设备指纹失败: $e');
    }
  }

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

  static String _genBLsid() {
    const chars = '0123456789abcdef';
    final r = Random();
    String hex(int n) =>
        List.generate(n, (_) => chars[r.nextInt(chars.length)]).join();
    return '${hex(16)}_${hex(8)}';
  }

  static Future<String> _buildCookie() async {
    await _ensureDeviceFp();
    final parts = <String>[
      'buvid3=${_spiBuvid3 ?? _genBuvid3()}',
      if (_spiBuvid4?.isNotEmpty ?? false) 'buvid4=$_spiBuvid4',
      'b_nut=${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
      'b_lsid=${_genBLsid()}',
    ];
    final accountCookie = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.search,
    )?['Cookie'];
    if (accountCookie != null && accountCookie.isNotEmpty) {
      parts.insert(0, accountCookie);
    }
    return parts.join('; ');
  }

  static Future<Map<String, String>> _buildHeaders({
    required String keyword,
    String? gaiaVtoken,
  }) async {
    final cookie = await _buildCookie();
    final merged = <String>[
      cookie,
      if (gaiaVtoken != null && gaiaVtoken.isNotEmpty)
        'x-bili-gaia-vtoken=$gaiaVtoken',
    ].join('; ');
    return {
      ..._defaultHeaders,
      'Referer':
          'https://search.bilibili.com/video?keyword=${Uri.encodeComponent(keyword)}',
      'Origin': 'https://search.bilibili.com',
      'Cookie': merged,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  // ── 分类搜索 ──

  /// 携带搜索站 Origin/Referer 与设备指纹 Cookie。按 [type] 解析对应结果。
  /// [gaiaVtoken] 非空时把 grisk_id 作为 Cookie x-bili-gaia-vtoken 携带重试。
  /// 视频类型额外支持筛选：[duration] 内容时长（1 十分钟以下 / 2 十分钟到
  /// 半小时 / 3 半小时以上）、[tids] 内容分区、[pubBegin]/[pubEnd]
  /// 发布时间范围（Unix 秒）。
  static Future<BiliSearchResult> searchByType({
    required BiliSearchType type,
    required String keyword,
    int page = 1,
    int pageSize = 20,
    String? gaiaVtoken,
    int? duration,
    int? tids,
    int? pubBegin,
    int? pubEnd,
  }) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      lastErrorDetail = L10n.current.searchKeywordEmpty;
      return BiliSearchError(L10n.current.searchKeywordEmpty);
    }
    try {
      final params = await WbiSign.sign({
        'search_type': type.code,
        'keyword': trimmed,
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'platform': 'pc',
        'web_location': '1430654',
        if (duration != null && duration > 0) 'duration': duration.toString(),
        if (tids != null && tids > 0) 'tids': tids.toString(),
        if (pubBegin != null) 'pubtime_begin_s': pubBegin.toString(),
        if (pubEnd != null) 'pubtime_end_s': pubEnd.toString(),
      });
      final uri = Uri.parse(_searchApi).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final headers = await _buildHeaders(
        keyword: trimmed,
        gaiaVtoken: gaiaVtoken,
      );
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = L10n.current.biliHttpError(resp.statusCode);
        debugPrint('[Search] HTTP ${resp.statusCode}');
        return BiliSearchError(L10n.current.biliHttpError(resp.statusCode));
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        lastErrorDetail = L10n.current.searchBadResponse;
        return BiliSearchError(L10n.current.searchBadResponse);
      }
      final code = json['code'];
      if (code != 0 && code != 200) {
        // -412 等风控拦截
        lastErrorDetail = 'code=$code ${json['message']}';
        debugPrint('[Search] code=$code ${json['message']}');
        return BiliSearchError(
          code == -412
              ? L10n.current.biliRiskBlocked
              : '${json['message'] ?? L10n.current.searchFailed}',
        );
      }
      final data = _asMap(json['data']);
      if (data == null) {
        lastErrorDetail = L10n.current.biliResponseNoData;
        return BiliSearchError(L10n.current.biliResponseNoData);
      }
      final vVoucher = (data['v_voucher'] as String?) ?? '';
      if (vVoucher.isNotEmpty) {
        debugPrint('[Search] 触发风控，需要验证码验证');
        return BiliSearchCaptcha(vVoucher);
      }
      final result = _asList(data['result']) ?? const [];
      final items = result
          .whereType<Map<String, dynamic>>()
          .map((e) => _parseItem(type, e, trimmed))
          .where((e) => e != null)
          .cast<BiliSearchItem>()
          .toList();
      lastErrorDetail = null;
      return BiliSearchOk(
        BiliSearchPage(
          items: items,
          numResults: _toInt(data['numResults']),
          page: page,
          pageSize: pageSize,
        ),
      );
    } catch (e) {
      lastErrorDetail = L10n.current.commentException('$e');
      debugPrint('[Search] 搜索异常: $e');
      return BiliSearchError(L10n.current.commentException('$e'));
    }
  }

  /// 按类型把原始 JSON 解析为统一条目；无法解析时返回 null。
  /// [keyword] 用于无 <em> 时的兜底高亮。
  static BiliSearchItem? _parseItem(
    BiliSearchType type,
    Map<String, dynamic> json,
    String keyword,
  ) {
    switch (type) {
      case BiliSearchType.video:
        final bvid = (json['bvid'] as String?) ?? '';
        final badge = switch (json['type']) {
          'ketang' => L10n.current.searchBadgeCourse,
          'live_room' => L10n.current.searchBadgeLive,
          _ =>
            _toInt(json['is_union_video']) == 1
                ? L10n.current.searchBadgeCoop
                : '',
        };
        return BiliSearchItem(
          type: type,
          mid: _toInt(json['mid']),
          titleSegments: _parseTitleEm(
            (json['title'] as String?) ?? '',
            fallbackKeyword: keyword,
          ),
          cover: (json['pic'] as String?) ?? '',
          subtitle: (json['author'] as String?) ?? '',
          meta: L10n.current.searchVideoMeta(
            _formatCount(_toInt(json['play'])),
            _formatCount(_toInt(json['video_review'])),
          ),
          badge: badge,
          duration: (json['duration'] as String?) ?? '',
          actionUrl: 'https://www.bilibili.com/video/$bvid',
          desc: (json['description'] as String?) ?? '',
          play: _toInt(json['play']),
          danmaku: _toInt(json['video_review']),
          bvid: bvid,
        );
      case BiliSearchType.mediaBangumi:
      case BiliSearchType.mediaFt:
        final seasonId = _toInt(json['season_id']);
        final score = _toDouble(_asMap(json['media_score'])?['score']);
        // 接口的 areas 字段可能是 String（如 "日本"）也可能是 List，两种形态都兼容
        final areas = switch (json['areas']) {
          final String s => s,
          final List l =>
            l
                .whereType<Map<String, dynamic>>()
                .map((a) => (a['name'] as String?) ?? '')
                .where((s) => s.isNotEmpty)
                .join(' · '),
          _ => '',
        };
        final parts = <String>[
          (json['season_type_name'] as String?) ?? '',
          areas,
        ].where((s) => s.isNotEmpty);
        return BiliSearchItem(
          type: type,
          mid: 0,
          titleSegments: _parseTitleEm(
            (json['title'] as String?) ?? '',
            fallbackKeyword: keyword,
          ),
          cover: (json['cover'] as String?) ?? '',
          subtitle: parts.join(' · '),
          meta: score > 0
              ? L10n.current.searchScore(
                  score.toStringAsFixed(score >= 10 ? 0 : 1),
                )
              : '',
          badge: (json['button_text'] as String?) ?? '',
          duration: (json['index_show'] as String?) ?? '',
          actionUrl: 'https://www.bilibili.com/bangumi/play/ss$seasonId',
          desc: (json['desc'] as String?) ?? '',
          seasonId: seasonId,
        );
      case BiliSearchType.liveRoom:
        final roomId = _toInt(json['roomid']);
        final cover = ((json['cover'] as String?) ?? '').isNotEmpty
            ? (json['cover'] as String?)!
            : ((json['uface'] as String?) ?? '');
        return BiliSearchItem(
          type: type,
          mid: _toInt(json['uid']),
          titleSegments: _parseTitleEm(
            (json['title'] as String?) ?? '',
            fallbackKeyword: keyword,
          ),
          cover: _normalizeUrl(cover),
          subtitle: (json['uname'] as String?) ?? '',
          meta: L10n.current.searchOnline(_formatCount(_toInt(json['online']))),
          badge: (json['cate_name'] as String?) ?? '',
          duration: '',
          actionUrl: 'https://live.bilibili.com/$roomId',
          desc: '',
          roomId: roomId,
        );
      case BiliSearchType.biliUser:
        final mid = _toInt(json['mid']);
        return BiliSearchItem(
          type: type,
          mid: mid,
          titleSegments: _parseTitleEm(
            (json['uname'] as String?) ?? '',
            fallbackKeyword: keyword,
          ),
          cover: (json['upic'] as String?) ?? '',
          subtitle: (json['usign'] as String?) ?? '',
          meta: L10n.current.searchUserMeta(
            _formatCount(_toInt(json['fans'])),
            _formatCount(_toInt(json['videos'])),
          ),
          badge: _toInt(json['is_live']) == 1
              ? L10n.current.searchBadgeLiveNow
              : '',
          duration: '',
          actionUrl: 'https://space.bilibili.com/$mid',
          desc: '',
        );
      case BiliSearchType.article:
        final id = _toInt(json['id']);
        final images = _asList(json['image_urls']) ?? const [];
        return BiliSearchItem(
          type: type,
          mid: _toInt(json['mid']),
          titleSegments: _parseTitleEm(
            (json['title'] as String?) ?? '',
            fallbackKeyword: keyword,
          ),
          cover: images.isNotEmpty ? '${images.first}' : '',
          subtitle: (json['category_name'] as String?) ?? '',
          meta: L10n.current.searchArticleMeta(
            _formatCount(_toInt(json['view'])),
            _formatCount(_toInt(json['reply'])),
          ),
          badge: '',
          duration: '',
          actionUrl: 'https://www.bilibili.com/read/cv$id',
          desc: (json['desc'] as String?) ?? '',
          id: id,
        );
    }
  }

  // ── 搜索建议 ──

  /// s.search.bilibili.com/main/suggest，默认返回 JSONP，手动剥离包裹后解析。
  /// 失败/空输入返回空列表。
  static Future<List<BiliSearchSuggest>> searchSuggest(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return const [];
    try {
      final uri = Uri.parse(_suggestApi).replace(
        queryParameters: {
          'term': trimmed,
          'main_ver': 'v1',
          'highlight': trimmed,
          'jsonp': 'jsonp',
        },
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final headers = await _buildHeaders(keyword: trimmed);
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return const [];
      // JSONP 剥离：形如 jsonp({...}) / callback({...})
      var body = utf8.decode(resp.bodyBytes).trim();
      if (body.startsWith('jsonp(') ||
          body.startsWith('callback(') ||
          (body.startsWith('(') && body.endsWith(')'))) {
        final start = body.indexOf('(') + 1;
        final end = body.lastIndexOf(')');
        if (start > 0 && end > start) {
          body = body.substring(start, end);
        }
      }
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic> || json['code'] != 0) {
        return const [];
      }
      final result = _asMap(json['result']);
      final tag = _asList(result?['tag']) ?? const [];
      return tag
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => BiliSearchSuggest(
              // term 为主，value 兜底（不同接口形态字段名不一致）
              keyword:
                  (((e['term'] as String?) ?? (e['value'] as String?)) ?? '')
                      .trim(),
              display: _stripHtml((e['name'] as String?) ?? ''),
            ),
          )
          .where((s) => s.keyword.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[Search] 获取搜索建议失败: $e');
      return const [];
    }
  }

  // ── gaia-vgate 验证码流程 ──

  /// ① 注册：用 v_voucher 换取验证所需 token 与极验 gt/challenge。
  /// 返回 (token, gt, challenge)；失败返回 null。
  static Future<({String token, String gt, String challenge})?>
  gaiaVgateRegister(String vVoucher) async {
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final cookie = await _buildCookie();
      final accountCookie = BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.search,
      )?['Cookie'];
      final merged = accountCookie != null && accountCookie.isNotEmpty
          ? '$accountCookie; $cookie'
          : cookie;
      final resp = await client
          .post(
            Uri.parse(_gaiaRegisterApi),
            headers: {
              ..._defaultHeaders,
              'Content-Type': 'application/x-www-form-urlencoded',
              'Cookie': merged,
              ...NetworkSettingsService.instance.apiHeaders,
            },
            body: {'v_voucher': vVoucher},
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'gaia register HTTP ${resp.statusCode}';
        return null;
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail =
            'gaia register code=${json['code']} ${json['message']}';
        debugPrint('[Search] gaia register ${json['message']}');
        return null;
      }
      final data = _asMap(json['data']);
      final geetest = _asMap(data?['geetest']);
      final token = (data?['token'] as String?) ?? '';
      final gt = (geetest?['gt'] as String?) ?? '';
      final challenge = (geetest?['challenge'] as String?) ?? '';
      if (token.isEmpty || gt.isEmpty || challenge.isEmpty) {
        lastErrorDetail = L10n.current.searchGaiaParamMissing;
        return null;
      }
      return (token: token, gt: gt, challenge: challenge);
    } catch (e) {
      lastErrorDetail = L10n.current.searchGaiaRegisterError('$e');
      debugPrint('[Search] gaia register 异常: $e');
      return null;
    }
  }

  /// ③ 校验：提交极验结果换取 grisk_id（作为 gaia_vtoken 携带重试）。
  /// 返回 griskId；失败返回 null。
  static Future<String?> gaiaVgateValidate({
    required String token,
    required String challenge,
    required String validate,
    required String seccode,
  }) async {
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final cookie = await _buildCookie();
      final accountCookie = BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.search,
      )?['Cookie'];
      final merged = accountCookie != null && accountCookie.isNotEmpty
          ? '$accountCookie; $cookie'
          : cookie;
      final resp = await client
          .post(
            Uri.parse(_gaiaValidateApi),
            headers: {
              ..._defaultHeaders,
              'Content-Type': 'application/x-www-form-urlencoded',
              'Cookie': merged,
              ...NetworkSettingsService.instance.apiHeaders,
            },
            body: {
              'challenge': challenge,
              'seccode': seccode,
              'token': token,
              'validate': validate,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'gaia validate HTTP ${resp.statusCode}';
        return null;
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail =
            'gaia validate code=${json['code']} ${json['message']}';
        debugPrint('[Search] gaia validate ${json['message']}');
        return null;
      }
      final data = _asMap(json['data']);
      final isValid = _toInt(data?['is_valid']);
      final griskId = (data?['grisk_id'] as String?) ?? '';
      if (isValid != 1 || griskId.isEmpty) {
        lastErrorDetail = L10n.current.searchGaiaValidateFailed(isValid);
        return null;
      }
      lastErrorDetail = null;
      return griskId;
    } catch (e) {
      lastErrorDetail = L10n.current.searchGaiaValidateError('$e');
      debugPrint('[Search] gaia validate 异常: $e');
      return null;
    }
  }

  // ── 图片 ──

  /// 封面地址（压缩到 320x200，与用户空间封面同款）。
  static String coverUrl(String url) {
    if (url.isEmpty) return '';
    return '${_normalizeUrl(url)}@320w_200h_1c.webp';
  }

  /// 番剧封面地址（竖版 3:4，480x640，按显示比例裁剪）。
  /// 不用 [coverUrl] 的 16:10 压缩，避免竖版封面裁剪后放大发糊。
  static String bangumiCoverUrl(String url) {
    if (url.isEmpty) return '';
    return '${_normalizeUrl(url)}@480w_640h_1c.webp';
  }

  /// 头像地址（压缩到 96px）。
  static String avatarUrl(String url, {int size = 96}) {
    if (url.isEmpty) return '';
    return '${_normalizeUrl(url)}@${size}w_${size}h_1c.webp';
  }
}
