// lib/services/bilibili_recommend_service.dart
//
// B 站推荐��频（参��?PiliPlus）：
//   - Web ����荐：x/web-interface/wbi/index/top/feed/rcmd（WBI 签名�?//   - APP ����荐：app.bilibili.com/x/v2/feed/index（移动��参数 + 专属头）
// 两���均��������录状态下获取基��推荐（仅依赖设��指纹 buvid3/buvid4），
// 登录并开����携�?Cookie 请求」时附加账号 Cookie 获得����化推荐�?// 请求方式与搜�?用户空间服务��致：复用 NetworkSettingsService 客户�?// 与��求头，Cookie 遵循「携�?Cookie 请求」开关�
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart' show WbiSign;
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';

// ════════════════════════════════════════�?//  安全解析工具（字段类型不稳定，统��兜底�?// ════════════════════════════════════════

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

String _toStr(dynamic v) => v?.toString() ?? '';

/// 解析�?.2�?/ 3.4�?/ 1000」这类文����整数
int _parseCountText(String s) {
  final t = s.trim();
  if (t.isEmpty || t == '-') return 0;
  final m = RegExp(r'^([\d.]+)\s*(千|万|亿?)').firstMatch(t);
  if (m == null) return int.tryParse(t) ?? 0;
  final num = double.tryParse(m.group(1) ?? '') ?? 0;
  final unit = switch (m.group(2)) {
    '千' => 1000,
    '万' => 10000,
    '亿' => 100000000,
    _ => 1,
  };
  return (num * unit).round();
}

// ════════════════════════════════════════�?//  模型：推荐��频条����统一 Web / APP 两��数据源）
// ════════════════════════════════════════

class BiliRecommendItem {
  final String bvid;
  final int aid;
  final int cid;
  final String title;
  final String cover;
  final int duration; // 
  final int pubdate; // Unix 
  final String ownerName;
  final int ownerMid;
  final int view;
  final int danmaku;
  final int like;

  /// 推荐原因（��「热门������已关注」等，可为空）�
  final String rcmdReason;

  const BiliRecommendItem({
    required this.bvid,
    required this.aid,
    required this.cid,
    required this.title,
    required this.cover,
    required this.duration,
    required this.pubdate,
    required this.ownerName,
    required this.ownerMid,
    required this.view,
    required this.danmaku,
    required this.like,
    required this.rcmdReason,
  });
}

// ════════════════════════════════════════�?//  模型：番剧索引条�������� tab 使用�?// ════════════════════════════════════════

class BiliBangumiItem {
  final int seasonId;
  final String title;
  final String cover;
  final String badge; // 角标（��「独家������会员���等
  final String indexShow; // ����题（如���全 13 话������更新至 5 话���）
  final String score; // 评分文本（���?.8」）

  const BiliBangumiItem({
    required this.seasonId,
    required this.title,
    required this.cover,
    required this.badge,
    required this.indexShow,
    required this.score,
  });
}

/// ����首页����图（/pgc/page/channel �?BANNER 模块，与官方 App
/// ���� tab 顶部����同源）：既有剧集安利也有活动页（�?/// 「投稿安利动画，赢现金大奖���），[seasonId] �?0 时表示活动链接�
class BiliBangumiBannerItem {
  final int seasonId;
  final int seasonType;
  final String title;
  final String subTitle;
  final String cover; // 16:9 ����大图
  final String bgImg;
  final String url; // 点击跳转链接

  const BiliBangumiBannerItem({
    required this.seasonId,
    required this.seasonType,
    required this.title,
    required this.subTitle,
    required this.cover,
    required this.bgImg,
    required this.url,
  });
}

/// ����首页����榜单条目（channel 响应 RANK 模块�?sub_items）�
class BiliBangumiRankItem {
  final int seasonId;
  final String title;
  final String cover;
  final String subTitle;
  final String newEpShow; // 更新至�� N 
  final String url;

  const BiliBangumiRankItem({
    required this.seasonId,
    required this.title,
    required this.cover,
    required this.subTitle,
    required this.newEpShow,
    required this.url,
  });
}

/// 继续看条����guess 接口 recent_watch 模块�?CommonCard）：
/// 封面 [cover]、进�?[progressPercent]�?-100）���小���?[desc]
class BiliBangumiContinueItem {
  final int seasonId;
  final String title;
  final String cover;
  final String desc;
  final int progressPercent;
  final String newEpShow;
  final String url;

  const BiliBangumiContinueItem({
    required this.seasonId,
    required this.title,
    required this.cover,
    required this.desc,
    required this.progressPercent,
    required this.newEpShow,
    required this.url,
  });
}

// ════════════════════════════════════════�?//  请求结果
// ════════════════════════════════════════

sealed class BiliRecommendResult<T> {}

/// 正常返回（列表可能为空）
class BiliRecommendOk<T> extends BiliRecommendResult<T> {
  final List<T> items;
  BiliRecommendOk(this.items);
}

/// 请求失败（网�?/ �?0 业务�?/ 解析失败）�
class BiliRecommendError<T> extends BiliRecommendResult<T> {
  final String detail;
  BiliRecommendError(this.detail);
}

// ════════════════════════════════════════�?//  服务
// ════════════════════════════════════════

abstract final class BilibiliRecommendService {
  static const String _webApi =
      'https://api.bilibili.com/x/web-interface/wbi/index/top/feed/rcmd';
  static const String _appApi = 'https://app.bilibili.com/x/v2/feed/index';
  static const String _spiApi =
      'https://api.bilibili.com/x/frontend/finger/spi';

  /// ��近一次失败的具体原因（供界面展示，便于诊����
  static String? lastErrorDetail;

  static const Map<String, String> _webHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  /// APP ����荐专�?UA（android_hd 平板����
  static const String _appUA =
      'Mozilla/5.0 BiliDroid/2.0.1 (bbcallen@gmail.com) os/android '
      'model/android_hd mobi_app/android_hd build/2001100 channel/master '
      'innerVer/2001100 osVer/15 network/2';

  // ���� 设��指纹（buvid3 / buvid4），����录时也能请求推荐 ����

  static String? _fpBuvid3;
  static String? _fpBuvid4;

  static Future<void> _ensureDeviceFp() async {
    if (_fpBuvid3 != null) return;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(_spiApi), headers: _webHeaders)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return;
      final data = _asMap(json['data']);
      if (data == null) return;
      final b3 = (data['b_3'] as String?) ?? '';
      if (b3.isNotEmpty) {
        _fpBuvid3 = b3;
        _fpBuvid4 = (data['b_4'] as String?) ?? '';
      }
    } catch (e) {
      debugPrint('[Recommend] 获取设��指纹失败: $e');
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

  /// Web �?Cookie：��备指�?+ 登录 Cookie（遵����携�?Cookie」开关）
  static Future<String> _buildWebCookie() async {
    await _ensureDeviceFp();
    final parts = <String>[
      'buvid3=${_fpBuvid3 ?? _genBuvid3()}',
      if (_fpBuvid4?.isNotEmpty ?? false) 'buvid4=$_fpBuvid4',
      'b_nut=${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
    ];
    final accountCookie = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.video,
    )?['Cookie'];
    if (accountCookie != null && accountCookie.isNotEmpty) {
      parts.insert(0, accountCookie);
    }
    return parts.join('; ');
  }

  static Future<Map<String, String>> _buildWebHeaders() async {
    return {
      ..._webHeaders,
      'Cookie': await _buildWebCookie(),
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  // ���� Web �����?����

  /// Web ����荐（x/web-interface/wbi/index/top/feed/rcmd）��?  /// [freshIdx] 为��量刷新游标（���已加载条数，首���?0）�
  static Future<BiliRecommendResult<BiliRecommendItem>> fetchWeb({
    required int freshIdx,
    int ps = 20,
  }) async {
    try {
      final params = await WbiSign.sign({
        'version': '1',
        'feed_version': 'V8',
        'homepage_ver': '1',
        'ps': ps.toString(),
        'fresh_idx': freshIdx.toString(),
        'brush': freshIdx.toString(),
        'fresh_type': '4',
        'web_location': '1430650',
      });
      final uri = Uri.parse(_webApi).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildWebHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[Recommend] web HTTP ${resp.statusCode}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint('[Recommend] web code=${json['code']} ${json['message']}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final data = _asMap(json['data']);
      final rawList = data?['item'];
      if (rawList is! List) {
        lastErrorDetail = '数据为空';
        return BiliRecommendError(lastErrorDetail!);
      }
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .where((e) => e['goto'] == 'av') // 过滤直播 / 广告等非视频卡片
          .map(_parseWebItem)
          .where((v) => v != null)
          .cast<BiliRecommendItem>()
          .toList();
      lastErrorDetail = null;
      return BiliRecommendOk(items);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Recommend] web 推荐异常: $e');
      return BiliRecommendError(lastErrorDetail!);
    }
  }

  static BiliRecommendItem? _parseWebItem(Map<String, dynamic> json) {
    final owner = _asMap(json['owner']) ?? const <String, dynamic>{};
    final stat = _asMap(json['stat']) ?? const <String, dynamic>{};
    final reason = _asMap(json['rcmd_reason']);
    final bvid = _toStr(json['bvid']);
    if (bvid.isEmpty) return null;
    return BiliRecommendItem(
      bvid: bvid,
      aid: _toInt(json['id']),
      cid: _toInt(json['cid']),
      title: _toStr(json['title']),
      cover: _toStr(json['pic']),
      duration: _toInt(json['duration']),
      pubdate: _toInt(json['pubdate']),
      ownerName: _toStr(owner['name']),
      ownerMid: _toInt(owner['mid']),
      view: _toInt(stat['view']),
      danmaku: _toInt(stat['danmaku']),
      like: _toInt(stat['like']),
      rcmdReason: _toStr(reason?['content']),
    );
  }

  // ���� APP �����?����

  /// APP ����荐（app.bilibili.com/x/v2/feed/index）��?  /// [freshIdx] 为��量刷新游标（首���?0）��?  /// ����录也����：仅依赖设��指纹头（buvid / fp_local / session_id 等）
  static Future<BiliRecommendResult<BiliRecommendItem>> fetchApp({
    required int freshIdx,
  }) async {
    try {
      await _ensureDeviceFp();
      final buvid = _fpBuvid3 ?? _genBuvid3();
      final cookieParts = <String>[
        'buvid3=$buvid',
        if (_fpBuvid4?.isNotEmpty ?? false) 'buvid4=$_fpBuvid4',
      ];
      final accountCookie = BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.video,
      )?['Cookie'];
      if (accountCookie != null && accountCookie.isNotEmpty) {
        cookieParts.insert(0, accountCookie);
      }
      final query = {
        'build': '2001100',
        'c_locale': 'zh_CN',
        'channel': 'master',
        'column': '4',
        'device': 'pad',
        'device_name': 'android',
        'device_type': '0',
        'disable_rcmd': '0',
        'flush': '5',
        'fnval': '976',
        'fnver': '0',
        'force_host': '2', // 使用 https
        'fourk': '1',
        'guidance': '0',
        'https_url_req': '0',
        'idx': freshIdx.toString(),
        'mobi_app': 'android_hd',
        'network': 'wifi',
        'platform': 'android',
        'player_net': '1',
        'pull': freshIdx == 0 ? 'true' : 'false',
        'qn': '32',
        'recsys_mode': '0',
        's_locale': 'zh_CN',
        'splash_id': '',
        'statistics':
            '{"appId":5,"platform":3,"version":"2.0.1","abtest":""}',
        'voice_balance': '0',
      };
      final uri = Uri.parse(_appApi).replace(queryParameters: query);
      final headers = <String, String>{
        'User-Agent': _appUA,
        'Cookie': cookieParts.join('; '),
        'buvid': buvid,
        'fp_local': '1' * 64,
        'fp_remote': '1' * 64,
        'session_id': '11111111',
        'env': 'prod',
        'app-key': 'android_hd',
        'x-bili-trace-id': '11111111111111111111111111111111:1111111111111111:0:0',
        'x-bili-aurora-eid': '',
        'x-bili-aurora-zone': '',
        'bili-http-engine': 'cronet',
        ...NetworkSettingsService.instance.apiHeaders,
      };
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[Recommend] app HTTP ${resp.statusCode}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint('[Recommend] app code=${json['code']} ${json['message']}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final data = _asMap(json['data']);
      final rawList = data?['items'];
      if (rawList is! List) {
        lastErrorDetail = '数据为空';
        return BiliRecommendError(lastErrorDetail!);
      }
      final items = rawList
          .whereType<Map<String, dynamic>>()
          // 过滤广告 / 直播 / 不可播放的卡
          .where(
            (e) =>
                e['card_goto'] != 'ad_av' &&
                e['card_goto'] != 'ad_web_s' &&
                _asMap(e['ad_info']) == null &&
                _toInt(e['can_play']) == 1 &&
                e['goto'] == 'av',
          )
          .map(_parseAppItem)
          .where((v) => v != null)
          .cast<BiliRecommendItem>()
          .toList();
      lastErrorDetail = null;
      return BiliRecommendOk(items);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Recommend] app 推荐异常: $e');
      return BiliRecommendError(lastErrorDetail!);
    }
  }

  static BiliRecommendItem? _parseAppItem(Map<String, dynamic> json) {
    final playerArgs = _asMap(json['player_args']) ?? const <String, dynamic>{};
    final args = _asMap(json['args']) ?? const <String, dynamic>{};
    final aid = _toInt(json['param']) > 0
        ? _toInt(json['param'])
        : _toInt(playerArgs['aid']);
    final bvid = _toStr(json['bvid']);
    if (bvid.isEmpty && aid <= 0) return null;
    final title = _toStr(json['title']);
    if (title.isEmpty) return null;
    var like = _toInt(json['like']);
    // APP ����荐原因里����带���xx赞���（如��?.2万赞」），可从中解析点赞
    final rcmdReason = _toStr(json['rcmd_reason']);
    if (like == 0 && rcmdReason.contains('赞')) {
      like = _parseCountText(rcmdReason.replaceAll('赞', ''));
    }
    return BiliRecommendItem(
      bvid: bvid,
      aid: aid,
      cid: _toInt(playerArgs['cid']),
      title: title,
      cover: _toStr(json['cover']),
      duration: _toInt(playerArgs['duration']),
      pubdate: _toInt(json['pubdate']),
      ownerName: _toStr(args['up_name']),
      ownerMid: _toInt(args['up_id']),
      view: _parseCountText(_toStr(json['cover_left_text_1'])),
      danmaku: _parseCountText(_toStr(json['cover_left_text_2'])),
      like: like,
      rcmdReason: rcmdReason,
    );
  }

  /// 按当前������数据源拉取一页推荐�
  static Future<BiliRecommendResult<BiliRecommendItem>> fetch({
    required BiliRecommendSource source,
    required int freshIdx,
    int ps = 20,
  }) {
    return switch (source) {
      BiliRecommendSource.web => fetchWeb(freshIdx: freshIdx, ps: ps),
      BiliRecommendSource.app => fetchApp(freshIdx: freshIdx),
    };
  }

  // ���� ���� ����

  /// ����视��（x/web-interface/popular），[pn] 页码�?1 ��始�
  static Future<BiliRecommendResult<BiliRecommendItem>> fetchPopular({
    required int pn,
    int ps = 20,
  }) async {
    try {
      final uri = Uri.parse('https://api.bilibili.com/x/web-interface/popular')
          .replace(queryParameters: {'pn': pn.toString(), 'ps': ps.toString()});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildWebHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[Recommend] popular HTTP ${resp.statusCode}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint('[Recommend] popular code=${json['code']} ${json['message']}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final data = _asMap(json['data']);
      final rawList = data?['list'];
      if (rawList is! List) {
        lastErrorDetail = '数据为空';
        return BiliRecommendError(lastErrorDetail!);
      }
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(_parseWebItem)
          .where((v) => v != null)
          .cast<BiliRecommendItem>()
          .toList();
      lastErrorDetail = null;
      return BiliRecommendOk(items);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Recommend] popular 异常: $e');
      return BiliRecommendError(lastErrorDetail!);
    }
  }

  // ���� ���� ����

  /// ����索引�?pgc/season/index/result，参�?PiliPlus PgcHttp.pgcIndex）：
  /// st=1 ����，order=3 综合排序，其余筛选参数置 -1 取全部分类�
  // ── 热门页顶部入口：排行榜 / 每周必看 / 入站必刷 / 热搜词 ──

  /// 排行榜（x/web-interface/ranking/v2，全站综合榜，与热门列表同构）。
  static Future<BiliRecommendResult<BiliRecommendItem>> fetchRanking() async {
    return _fetchVideoList(
      'https://api.bilibili.com/x/web-interface/ranking/v2',
      const {'rid': '0', 'type': 'all'},
      tag: 'ranking',
    );
  }

  /// 入站必刷（x/web-interface/popular/precious）。
  static Future<BiliRecommendResult<BiliRecommendItem>> fetchPrecious() async {
    return _fetchVideoList(
      'https://api.bilibili.com/x/web-interface/popular/precious',
      const {'page_size': '10', 'pn': '1'},
      tag: 'precious',
    );
  }

  /// 每周必看：期数列表（number / title）。
  static Future<List<({int number, String title})>> fetchWeeklySeries() async {
    try {
      final uri = Uri.parse(
        'https://api.bilibili.com/x/web-interface/popular/series/list',
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildWebHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return const [];
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return const [];
      final data = _asMap(json['data']);
      final rawList = data?['list'];
      if (rawList is! List) return const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => (
              number: _toInt(e['number']),
              title: _toStr(e['title']),
            ),
          )
          .where((e) => e.number > 0)
          .toList();
    } catch (e) {
      debugPrint('[Recommend] weekly series 异常: $e');
      return const [];
    }
  }

  /// 每周必看：某一期的视频列表（series/one 需 WBI 签名）。
  static Future<BiliRecommendResult<BiliRecommendItem>> fetchWeeklyOne(
    int number,
  ) async {
    final params = await WbiSign.sign({'number': number.toString()});
    return _fetchVideoList(
      'https://api.bilibili.com/x/web-interface/popular/series/one',
      params,
      tag: 'weekly',
    );
  }

  /// 热搜词（s.search.bilibili.com/main/hotword），作为热门页相关搜索。
  static Future<List<String>> fetchHotwords() async {
    try {
      final uri = Uri.parse(
        'https://s.search.bilibili.com/main/hotword',
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildWebHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return const [];
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return const [];
      final rawList = json['list'];
      if (rawList is! List) return const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => _toStr(e['keyword']))
          .where((s) => s.isNotEmpty)
          .take(10)
          .toList();
    } catch (e) {
      debugPrint('[Recommend] hotword 异常: $e');
      return const [];
    }
  }

  /// 通用视频列表拉取（排行榜 / 入站必刷 / 每周必看共用，
  /// 响应 data.list[] 与热门页同构，复用 [_parseWebItem]）。
  static Future<BiliRecommendResult<BiliRecommendItem>> _fetchVideoList(
    String api,
    Map<String, String> params, {
    required String tag,
  }) async {
    try {
      final uri = Uri.parse(api).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildWebHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[Recommend] $tag HTTP ${resp.statusCode}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint('[Recommend] $tag code=${json['code']} ${json['message']}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final data = _asMap(json['data']);
      final rawList = data?['list'];
      if (rawList is! List) {
        lastErrorDetail = '数据为空';
        return BiliRecommendError(lastErrorDetail!);
      }
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(_parseWebItem)
          .where((v) => v != null)
          .cast<BiliRecommendItem>()
          .toList();
      lastErrorDetail = null;
      return BiliRecommendOk(items);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Recommend] $tag 异常: $e');
      return BiliRecommendError(lastErrorDetail!);
    }
  }

  static Future<BiliRecommendResult<BiliBangumiItem>> fetchBangumi({
    required int page,
    int ps = 20,
  }) async {
    try {
      final uri = Uri.parse('https://api.bilibili.com/pgc/season/index/result')
          .replace(
            queryParameters: {
              'st': '1',
              'order': '3',
              'season_version': '-1',
              'spoken_language_type': '-1',
              'area': '-1',
              'is_finish': '-1',
              'copyright': '-1',
              'season_status': '-1',
              'season_month': '-1',
              'year': '-1',
              'style_id': '-1',
              'sort': '0',
              'season_type': '1',
              'type': '1',
              'page': page.toString(),
              'pagesize': ps.toString(),
            },
          );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildWebHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[Recommend] bangumi HTTP ${resp.statusCode}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint('[Recommend] bangumi code=${json['code']} ${json['message']}');
        return BiliRecommendError(lastErrorDetail!);
      }
      final data = _asMap(json['data']);
      final rawList = data?['list'];
      if (rawList is! List) {
        lastErrorDetail = '数据为空';
        return BiliRecommendError(lastErrorDetail!);
      }
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(_parseBangumiItem)
          .where((v) => v != null)
          .cast<BiliBangumiItem>()
          .toList();
      lastErrorDetail = null;
      return BiliRecommendOk(items);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[Recommend] bangumi 异常: $e');
      return BiliRecommendError(lastErrorDetail!);
    }
  }

  static BiliBangumiItem? _parseBangumiItem(Map<String, dynamic> json) {
    final seasonId = _toInt(json['season_id']);
    if (seasonId <= 0) return null;
    final title = _toStr(json['title']);
    if (title.isEmpty) return null;
    return BiliBangumiItem(
      seasonId: seasonId,
      title: title,
      cover: _toStr(json['cover']),
      badge: _toStr(json['badge']),
      indexShow: _toStr(json['index_show']),
      score: _toStr(json['order']),
    );
  }

  /// ����首页运营页（/pgc/page/channel，page_name=bangumi_tab 与官�?App
  /// ���� tab ��致）：一次返回轮����（BANNER 模块�? ����榜单
  /// （RANK 模块 sub_items）���失败静默返回空（��强内容，不影响列����
  static Future<
      ({List<BiliBangumiBannerItem> banners, List<BiliBangumiRankItem> ranks})>
      fetchBangumiChannel() async {
    try {
      final uri = Uri.parse('https://api.bilibili.com/pgc/page/channel')
          .replace(
            queryParameters: {
              'page_name': 'bangumi_tab',
              'cursor': '',
              'extra': '',
            },
          );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildWebHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return (banners: <BiliBangumiBannerItem>[], ranks: <BiliBangumiRankItem>[]);
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return (banners: <BiliBangumiBannerItem>[], ranks: <BiliBangumiRankItem>[]);
      final data = _asMap(json['data']);
      final modules = data?['modules'];
      if (modules is! List) return (banners: <BiliBangumiBannerItem>[], ranks: <BiliBangumiRankItem>[]);
      var banners = <BiliBangumiBannerItem>[];
      var ranks = <BiliBangumiRankItem>[];
      for (final m in modules) {
        final module = _asMap(m);
        if (module == null) continue;
        final moduleData = _asMap(module['module_data']);
        final items = moduleData?['items'];
        switch (_toStr(module['type'])) {
          case 'BANNER':
            if (items is List) {
              banners = items
                  .whereType<Map<String, dynamic>>()
                  .map(_parseBangumiBannerItem)
                  .where((v) => v != null)
                  .cast<BiliBangumiBannerItem>()
                  .toList();
            }
          case 'RANK':
            if (items is List && ranks.isEmpty) {
              for (final it in items) {
                final item = _asMap(it);
                final subs = item?['sub_items'];
                if (subs is! List) continue;
                for (final s in subs) {
                  final sm = _asMap(s);
                  if (sm == null) continue;
                  final seasonId = _toInt(sm['season_id']);
                  if (seasonId <= 0) continue;
                  ranks.add(
                    BiliBangumiRankItem(
                      seasonId: seasonId,
                      title: _toStr(sm['title']),
                      cover: _toStr(sm['cover']),
                      subTitle: _toStr(sm['sub_title']),
                      newEpShow: _toStr(
                        _asMap(sm['new_ep'])?['index_show'],
                      ),
                      url: _toStr(sm['url']),
                    ),
                  );
                }
              }
            }
        }
      }
      return (banners: banners, ranks: ranks);
    } catch (e) {
      debugPrint('[Recommend] bangumi channel 异常: $e');
      return (banners: <BiliBangumiBannerItem>[], ranks: <BiliBangumiRankItem>[]);
    }
  }

  static BiliBangumiBannerItem? _parseBangumiBannerItem(
    Map<String, dynamic> json,
  ) {
    final cover = _toStr(json['cover']);
    if (cover.isEmpty) return null;
    return BiliBangumiBannerItem(
      seasonId: _toInt(json['season_id']),
      seasonType: _toInt(json['season_type']),
      title: _toStr(json['title']),
      subTitle: _toStr(json['sub_title']),
      cover: cover,
      bgImg: _toStr(json['bg_img']),
      url: _toStr(json['url']),
    );
  }

  /// ����「继����」（/pgc/page/guess/bangumi，官�?App 猜你在看同源）：
  /// 解析 type == recent_watch 模块�?CommonCard（封�?/ progress_percent
  /// 进度 / desc 小简介）。需要登�?Cookie（未登录直接返回空，不��求）
  static Future<List<BiliBangumiContinueItem>> fetchBangumiContinue() async {
    final accountCookie = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.video,
    )?['Cookie'];
    if (accountCookie == null || accountCookie.isEmpty) return const [];
    try {
      final uri = Uri.parse('https://api.bilibili.com/pgc/page/guess/bangumi')
          .replace(
            queryParameters: {
              'page_no': '1',
              'page_size': '10',
            },
          );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildWebHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return const [];
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return const [];
      final data = _asMap(json['data']);
      final modules = data?['modules'];
      if (modules is! List) return const [];
      for (final m in modules) {
        final module = _asMap(m);
        if (module == null || _toStr(module['type']) != 'recent_watch') {
          continue;
        }
        final items = module['items'];
        if (items is! List) return const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map(_parseContinueItem)
            .where((v) => v != null)
            .cast<BiliBangumiContinueItem>()
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('[Recommend] bangumi continue 异常: $e');
      return const [];
    }
  }

  static BiliBangumiContinueItem? _parseContinueItem(
    Map<String, dynamic> json,
  ) {
    final seasonId = _toInt(json['season_id']);
    if (seasonId <= 0) return null;
    final title = _toStr(json['title']);
    if (title.isEmpty) return null;
    return BiliBangumiContinueItem(
      seasonId: seasonId,
      title: title,
      cover: _toStr(json['cover']),
      desc: _toStr(json['desc']),
      progressPercent: _toInt(json['progress_percent']),
      newEpShow: _toStr(_asMap(json['new_ep'])?['index_show']),
      url: _toStr(json['url']),
    );
  }

  /// 封面地址（压缩到 320x200，与搜索页封面同款）
  static String coverUrl(String url) {
    if (url.isEmpty) return '';
    final normalized = url.startsWith('//') ? 'https:$url' : url;
    return '$normalized@320w_200h_1c.webp';
  }
}
