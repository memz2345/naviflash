// lib/services/bilibili_video_service.dart
//
// lib/models/video/play/url.dart 实现，按本项目风格精简）：
//   - 视频详情：x/web-interface/view（标题/UP/统计/分P/简介，无需 WBI）
//   - 播放地址：x/player/wbi/playurl（DASH 分轨 + FLV/MP4 durl 兜底，WBI 签名）
//   - 相关视频：x/web-interface/archive/related
//   - 评论区：委托 BilibiliCommentService（x/v2/reply/main，含风控 buvid3）
// 请求方式与弹幕/评论区 Fetcher 一致：复用 NetworkSettingsService 客户端
// 与请求头；Cookie 遵循「携带 Cookie 请求」开关。

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_comment_service.dart' as comment_svc;
import 'package:naviflash/services/bilibili_user_space_service.dart'
    show WbiSign, BilibiliUserSpaceService;
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/video_cache_service.dart';

export 'package:naviflash/services/bilibili_comment_service.dart' show BiliComment;

// ═════════════════════════════════════════
//  安全解析工具（字段类型不稳定，统一兜底）
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

String _toStr(dynamic v) => v?.toString() ?? '';

/// 简单缓存条目（数据 + 写入时间）。
class _CacheEntry<T> {
  final T? data;
  final DateTime time;
  _CacheEntry({required this.data}) : time = DateTime.now();
}

// ═════════════════════════════════════════
//  模型：视频详情
// ═════════════════════════════════════════

/// 分P 条目。
class BiliVideoPage {
  final int cid;
  final int page; // 分P 序号（1 起始）
  final String part; // 分P 标题
  final int duration; // 秒

  const BiliVideoPage({
    required this.cid,
    required this.page,
    required this.part,
    required this.duration,
  });
}

class BiliVideoDetail {
  final String bvid;
  final int aid;
  final String title;
  final String desc;
  final String pic; // 封面
  final int pubdate;
  final int duration; // 总时长（秒）
  final String ownerName;
  final int ownerMid;
  final String ownerFace;

  /// UP 主粉丝数 / 投稿数（view 接口 owner.fans / owner.videos 下发）。
  final int ownerFans;
  final int ownerVideos;

  final int view;
  final int danmaku;
  final int reply;
  final int favorite;
  final int coin;
  final int share;
  final int like;
  final List<BiliVideoPage> pages;

  const BiliVideoDetail({
    required this.bvid,
    required this.aid,
    required this.title,
    required this.desc,
    required this.pic,
    required this.pubdate,
    required this.duration,
    required this.ownerName,
    required this.ownerMid,
    required this.ownerFace,
    required this.ownerFans,
    required this.ownerVideos,
    required this.view,
    required this.danmaku,
    required this.reply,
    required this.favorite,
    required this.coin,
    required this.share,
    required this.like,
    required this.pages,
  });

  factory BiliVideoDetail.fromJson(Map<String, dynamic> json) {
    final owner = _asMap(json['owner']) ?? const <String, dynamic>{};
    final stat = _asMap(json['stat']) ?? const <String, dynamic>{};
    final pages = (json['pages'] as List?) ?? const [];
    return BiliVideoDetail(
      bvid: _toStr(json['bvid']),
      aid: _toInt(json['aid']),
      title: _toStr(json['title']),
      desc: _toStr(json['desc']),
      pic: _toStr(json['pic']),
      pubdate: _toInt(json['pubdate']),
      duration: _toInt(json['duration']),
      ownerName: _toStr(owner['name']),
      ownerMid: _toInt(owner['mid']),
      ownerFace: _toStr(owner['face']),
      ownerFans: _toInt(owner['fans']),
      ownerVideos: _toInt(owner['videos']),
      view: _toInt(stat['view']),
      danmaku: _toInt(stat['danmaku']),
      reply: _toInt(stat['reply']),
      favorite: _toInt(stat['favorite']),
      coin: _toInt(stat['coin']),
      share: _toInt(stat['share']),
      like: _toInt(stat['like']),
      pages: pages
          .map(
            (e) => BiliVideoPage(
              cid: _toInt(_asMap(e)?['cid']),
              page: _toInt(_asMap(e)?['page']),
              part: _toStr(_asMap(e)?['part']),
              duration: _toInt(_asMap(e)?['duration']),
            ),
          )
          .toList(),
    );
  }
}

// ═════════════════════════════════════════
//  模型：播放地址
// ═════════════════════════════════════════

/// 单个 DASH 轨（视频或音频）。
class BiliDashStream {
  final int id;
  final String baseUrl;
  final List<String> backupUrls;
  final String mimeType;
  final String codecs;
  final int width;
  final int height;
  final int bandwidth;

  const BiliDashStream({
    required this.id,
    required this.baseUrl,
    required this.backupUrls,
    required this.mimeType,
    required this.codecs,
    required this.width,
    required this.height,
    required this.bandwidth,
  });

  factory BiliDashStream.fromJson(Map<String, dynamic> json) {
    return BiliDashStream(
      id: _toInt(json['id']),
      baseUrl: _toStr(json['baseUrl'] ?? json['base_url']),
      backupUrls:
          ((json['backupUrl'] ?? json['backup_url']) as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      mimeType: _toStr(json['mimeType'] ?? json['mime_type']),
      codecs: _toStr(json['codecs']),
      width: _toInt(json['width']),
      height: _toInt(json['height']),
      bandwidth: _toInt(json['bandWidth'] ?? json['bandwidth']),
    );
  }

  Iterable<String> get allUrls sync* {
    if (baseUrl.isNotEmpty) yield baseUrl;
    yield* backupUrls;
  }
}

/// 一个可选的画质档位。
class BiliQuality {
  final int qn;
  final String label;

  /// 该档位可能提供的解码格式（support_formats.codecs，如 avc1 / hev1 / av01）。
  final List<String> codecs;

  const BiliQuality({
    required this.qn,
    required this.label,
    this.codecs = const [],
  });
}

/// B 站视频 CDN 镜像节点（换源候选）。
class BiliCdnMirror {
  final String label;
  final String host;

  const BiliCdnMirror({required this.label, required this.host});
}

/// 预设 B 站 CDN 镜像域名表（参考 PiliPlus CDNService）：
/// 拿到 playurl 的 baseUrl 后把 host 替换成这些镜像域名即可换源。
/// 按运营商分档：阿里云 / 腾讯云 / 华为云（含融合/08 系列）/ 中转 / 海外。
const List<BiliCdnMirror> kBiliCdnMirrors = [
  // 阿里云
  BiliCdnMirror(label: '阿里云', host: 'upos-sz-mirrorali.bilivideo.com'),
  BiliCdnMirror(label: '阿里云 B', host: 'upos-sz-mirroralib.bilivideo.com'),
  BiliCdnMirror(label: '阿里云 O1', host: 'upos-sz-mirroralio1.bilivideo.com'),
  // 腾讯云
  BiliCdnMirror(label: '腾讯云', host: 'upos-sz-mirrorcos.bilivideo.com'),
  BiliCdnMirror(label: '腾讯云 B', host: 'upos-sz-mirrorcosb.bilivideo.com'),
  BiliCdnMirror(label: '腾讯云 O1', host: 'upos-sz-mirrorcoso1.bilivideo.com'),
  // 华为云（融合 CDN）
  BiliCdnMirror(label: '华为云', host: 'upos-sz-mirrorhw.bilivideo.com'),
  BiliCdnMirror(label: '华为云 B', host: 'upos-sz-mirrorhwb.bilivideo.com'),
  BiliCdnMirror(label: '华为云 O1', host: 'upos-sz-mirrorhwo1.bilivideo.com'),
  BiliCdnMirror(label: '华为云 08C', host: 'upos-sz-mirror08c.bilivideo.com'),
  BiliCdnMirror(label: '华为云 08H', host: 'upos-sz-mirror08h.bilivideo.com'),
  BiliCdnMirror(label: '华为云 08CT', host: 'upos-sz-mirror08ct.bilivideo.com'),
  // 中转
  BiliCdnMirror(label: '腾讯云 中转', host: 'upos-tf-all-tx.bilivideo.com'),
  BiliCdnMirror(label: '华为云 中转', host: 'upos-tf-all-hw.bilivideo.com'),
  // 海外
  BiliCdnMirror(label: '阿里云 海外', host: 'upos-sz-mirroraliov.bilivideo.com'),
  BiliCdnMirror(label: '腾讯云 海外', host: 'upos-sz-mirrorcosov.bilivideo.com'),
  BiliCdnMirror(label: '华为云 海外', host: 'upos-sz-mirrorhwov.bilivideo.com'),
  BiliCdnMirror(label: 'Akamai 海外', host: 'upos-hz-mirrorakam.akamaized.net'),
  BiliCdnMirror(label: 'B站 香港', host: 'cn-hk-eq-bcache-01.bilivideo.com'),
];

/// 一个可选的字幕（B 站 playurl 下发，多为 AI 字幕）。
class BiliSubtitle {
  final String lan;
  final String lanDoc;
  final String url;

  const BiliSubtitle({
    required this.lan,
    required this.lanDoc,
    required this.url,
  });

  factory BiliSubtitle.fromJson(Map<String, dynamic> json) {
    var url = _toStr(json['subtitle_url']);
    if (url.startsWith('//')) url = 'https:$url';
    if (url.startsWith('http://')) url = 'https://${url.substring(7)}';
    return BiliSubtitle(
      lan: _toStr(json['lan']),
      lanDoc: _toStr(json['lan_doc'] ?? json['lan_doc_brief']),
      url: url,
    );
  }
}

/// 高能进度条片段（/x/player/v2 的 data.view_points，from/to 单位为秒）。
class BiliViewPoint {
  /// 1 = 看点，2 = 高能（用户标记），3 = 高能片段。
  final int type;
  final int from;
  final int to;
  final String content;

  const BiliViewPoint({
    required this.type,
    required this.from,
    required this.to,
    required this.content,
  });

  factory BiliViewPoint.fromJson(Map<String, dynamic> json) {
    return BiliViewPoint(
      type: _toInt(json['type']),
      from: _toInt(json['from']),
      to: _toInt(json['to']),
      content: _toStr(json['content']),
    );
  }
}

class BiliPlayUrl {
  final int quality;
  final List<BiliQuality> qualities;
  final List<BiliDashStream> videoStreams;
  final List<BiliDashStream> audioStreams;
  final List<String> durlUrls; // FLV/MP4 兜底
  final List<BiliSubtitle> subtitles; // 可用字幕列表

  const BiliPlayUrl({
    required this.quality,
    required this.qualities,
    required this.videoStreams,
    required this.audioStreams,
    required this.durlUrls,
    this.subtitles = const [],
  });

  bool get hasDash => videoStreams.isNotEmpty && audioStreams.isNotEmpty;
  bool get hasDurl => durlUrls.isNotEmpty;

  /// 服务端实际下发了对应视频流的画质集合（未下发的即为锁定/不可用画质，
  /// 真正能播的档位）。
  Set<int> get availableQns => videoStreams.map((s) => s.id).toSet();

  /// 指定画质是否可用（有对应 DASH 视频流）。
  bool isQualityAvailable(int qn) =>
      availableQns.contains(qn) || durlUrls.isNotEmpty;

  /// 指定画质可用的解码格式前缀列表（从 support_formats.codecs 提取）。
  List<String> codecsForQuality(int qn) {
    for (final q in qualities) {
      if (q.qn == qn) return q.codecs;
    }
    return const [];
  }

  factory BiliPlayUrl.fromJson(Map<String, dynamic> json) {
    final dash = _asMap(json['dash']);
    final supportFormats = (json['support_formats'] as List?) ?? const [];
    final durl = (json['durl'] as List?) ?? const [];

    // 画质列表：优先 support_formats，其次 accept_quality + accept_description
    final qualities = <BiliQuality>[];
    if (supportFormats.isNotEmpty) {
      for (final f in supportFormats) {
        final m = _asMap(f);
        if (m == null) continue;
        final qn = _toInt(m['quality']);
        if (qn <= 0) continue;
        final label = _toStr(m['new_description'] ?? m['display_desc']).trim();
        if (label.isEmpty) continue;
        // codecs 形如 ["avc1","hev1","av01",...]，用于解码格式选择
        final codecs =
            (m['codecs'] as List?)
                ?.map((e) => e.toString().toLowerCase())
                .toList() ??
            const [];
        qualities.add(BiliQuality(qn: qn, label: label, codecs: codecs));
      }
    }
    if (qualities.isEmpty) {
      final qs = (json['accept_quality'] as List?) ?? const [];
      final descs = (json['accept_description'] as List?) ?? const [];
      for (var i = 0; i < qs.length; i++) {
        final qn = _toInt(qs[i]);
        if (qn <= 0) continue;
        final label = i < descs.length ? _toStr(descs[i]) : '${qn}P';
        qualities.add(BiliQuality(qn: qn, label: label));
      }
    }

    // 字幕：data.subtitle.subtitles[]（AI 字幕，需单独拉取 JSON 转换）
    final subtitleJson = _asMap(json['subtitle']);
    final subtitles = ((subtitleJson?['subtitles']) as List?) ?? const [];
    final subtitleList = subtitles
        .map((e) => BiliSubtitle.fromJson(_asMap(e) ?? const {}))
        .where((s) => s.url.isNotEmpty)
        .toList();

    return BiliPlayUrl(
      quality: _toInt(json['quality']),
      qualities: qualities,
      videoStreams:
          (dash?['video'] as List?)
              ?.map((e) => BiliDashStream.fromJson(_asMap(e) ?? const {}))
              .toList() ??
          const [],
      audioStreams:
          (dash?['audio'] as List?)
              ?.map((e) => BiliDashStream.fromJson(_asMap(e) ?? const {}))
              .toList() ??
          const [],
      durlUrls: durl
          .map((e) => _toStr(_asMap(e)?['url']))
          .where((s) => s.isNotEmpty)
          .toList(),
      subtitles: subtitleList,
    );
  }
}

// ═════════════════════════════════════════
//  模型：相关视频
// ═════════════════════════════════════════

class BiliRelatedVideo {
  final String bvid;
  final String title;
  final String pic;
  final int pubdate;
  final int duration;
  final String ownerName;
  final int view;
  final int danmaku;

  const BiliRelatedVideo({
    required this.bvid,
    required this.title,
    required this.pic,
    required this.pubdate,
    required this.duration,
    required this.ownerName,
    required this.view,
    required this.danmaku,
  });

  factory BiliRelatedVideo.fromJson(Map<String, dynamic> json) {
    final owner = _asMap(json['owner']) ?? const <String, dynamic>{};
    final stat = _asMap(json['stat']) ?? const <String, dynamic>{};
    return BiliRelatedVideo(
      bvid: _toStr(json['bvid']),
      title: _toStr(json['title']),
      pic: _toStr(json['pic']),
      pubdate: _toInt(json['pubdate']),
      duration: _toInt(json['duration']),
      ownerName: _toStr(owner['name']),
      view: _toInt(stat['view']),
      danmaku: _toInt(stat['danmaku']),
    );
  }
}

/// 相关视频条目。
class BiliVideoTag {
  final int id;
  final String name;
  final String type; // topic / bgm / '' 等

  const BiliVideoTag({
    required this.id,
    required this.name,
    required this.type,
  });

  factory BiliVideoTag.fromJson(Map<String, dynamic> json) {
    return BiliVideoTag(
      id: _toInt(json['tag_id']),
      name: _toStr(json['tag_name']),
      type: _toStr(json['tag_type'] ?? json['type']),
    );
  }
}

// ═════════════════════════════════════════
//  模型：评论分页（列表页使用，字段名贴合 UI）
// ═════════════════════════════════════════

class BiliReplyPage {
  final List<comment_svc.BiliComment> replies;
  final String? nextOffset;
  final bool isEnd;

  const BiliReplyPage({
    required this.replies,
    required this.nextOffset,
    required this.isEnd,
  });
}

// ═════════════════════════════════════════
//  模型：视频公开笔记（播放器「查看笔记」弹层使用）
// ═════════════════════════════════════════

/// 单条公开笔记（本质是 cv 专栏文章，点击后用 ArticlePage 打开）。
class BiliVideoNote {
  final int cvid;
  final String summary;
  final String pubTime;
  final int authorMid;
  final String authorName;
  final String authorFace;
  final bool isVip;

  const BiliVideoNote({
    required this.cvid,
    required this.summary,
    required this.pubTime,
    required this.authorMid,
    required this.authorName,
    required this.authorFace,
    this.isVip = false,
  });

  factory BiliVideoNote.fromJson(Map<String, dynamic> json) {
    final author = _asMap(json['author']) ?? const {};
    final vip = _asMap(author['vip_info']) ?? const {};
    return BiliVideoNote(
      cvid: _toInt(json['cvid']),
      summary: _toStr(json['summary']),
      pubTime: _toStr(json['pubtime']),
      authorMid: _toInt(author['mid']),
      authorName: _toStr(author['name']),
      authorFace: _toStr(author['face']),
      isVip: _toInt(vip['status']) > 0 && _toInt(vip['type']) == 2,
    );
  }
}

/// 笔记分页（page.total 驱动加载更多）。
class BiliVideoNotePage {
  final List<BiliVideoNote> list;
  final int total;

  const BiliVideoNotePage({required this.list, required this.total});
}

// ═════════════════════════════════════════
//  服务
// ═════════════════════════════════════════

abstract final class BilibiliVideoService {
  static const String _viewApi =
      'https://api.bilibili.com/x/web-interface/view';
  static const String _relatedApi =
      'https://api.bilibili.com/x/web-interface/archive/related';
  static const String _playUrlApi =
      'https://api.bilibili.com/x/player/wbi/playurl';

  static const String _defaultReferer = 'https://www.bilibili.com';
  static const String _defaultUA =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  /// 最近一次失败的具体原因（供界面展示，便于诊断），成功时清空。
  static String? lastErrorDetail;

  // ── 请求缓存（会话级，避免同一视频重复请求评论/推荐浪费流量） ──
  static const Duration _cacheTtl = Duration(minutes: 10);
  static final Map<String, _CacheEntry<Object?>> _cache = {};

  /// 持久 JSON 缓存（VideoJsonCache）有效期：
  ///   - 视频详情：6 小时内直接读本地，不再请求 view 接口；
  ///   - 播放地址：B 站 URL 有效期约 2 小时，取 70 分钟内直接复用，
  ///     过期但网络失败时仍回退（至少能试播）。
  static const Duration _detailCacheTtl = Duration(hours: 6);
  static const Duration _playUrlCacheTtl = Duration(minutes: 70);

  static _CacheEntry<T> _cached<T>(String key) {
    final e = _cache[key];
    if (e == null) return _CacheEntry<T>(data: null);
    if (DateTime.now().difference(e.time) > _cacheTtl) {
      _cache.remove(key);
      return _CacheEntry<T>(data: null);
    }
    // 类型不匹配（理论不该发生，防御）时按未命中处理，避免强转崩溃
    if (e is _CacheEntry<T>) return e;
    return _CacheEntry<T>(data: null);
  }

  static void _storeCache<T>(String key, T data) {
//  必须显式写 _CacheEntry<T>：若不写，赋给 Map<String,_CacheEntry<Object?>>
    // 时上下文类型会把运行时类型推断成 _CacheEntry<Object>，之后 _cached<T>
    // 的 _CacheEntry<T> 强转就会抛 _TypeError（如 fetchOwnerStats 的 (int,int)）。
    _cache[key] = _CacheEntry<T>(data: data);
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

  /// 拼装请求 Cookie：设备指纹 + 登录 Cookie（遵循「携带 Cookie」开关）。
  static String _buildCookie() {
    final parts = <String>[
      'buvid3=${_genBuvid3()}',
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

  static Map<String, String> _headers() {
    final cookie = _buildCookie();
    return {
      'User-Agent': _defaultUA,
      'Referer': _defaultReferer,
      'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  /// 拉取 UP 主粉丝数 / 投稿数（view 接口的 owner 不含粉丝/投稿数，
  /// 需 card 接口补充；结果会话内缓存 10 分钟）。
  static Future<(int, int)?> fetchOwnerStats(int mid) async {
    if (mid <= 0) return null;
    final key = 'owner_$mid';
    final cached = _cached<(int, int)>(key);
    if (cached.data != null) return cached.data;
    final card = await BilibiliUserSpaceService.fetchUserCard(mid: mid);
    if (card == null) return null;
    final result = (card.fans, card.archiveCount);
    _storeCache(key, result);
    return result;
  }

  /// 从 BV 号拉取视频详情（带持久 JSON 缓存：TTL 内直接读本地，
  /// 网络失败回退缓存，保证再次打开秒开/离线可看）。
  static Future<BiliVideoDetail?> fetchDetail(String bvid) async {
    final bv = bvid.trim();
    if (bv.isEmpty) {
      lastErrorDetail = 'BV 号为空';
      return null;
    }
    final cacheKey = 'detail_$bv';
    // ① 命中新缓存：直接返回，不再请求 view 接口
    final cached = await VideoJsonCache.load(cacheKey, ttl: _detailCacheTtl);
    if (cached != null) {
      lastErrorDetail = null;
      return BiliVideoDetail.fromJson(cached);
    }
    // ② 网络拉取
    Map<String, dynamic>? data;
    String? netError;
    try {
      final uri = Uri.parse(_viewApi).replace(queryParameters: {'bvid': bv});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        netError = 'HTTP ${resp.statusCode}';
        debugPrint('[BiliVideo] view HTTP ${resp.statusCode}');
      } else {
        final json = jsonDecode(utf8.decode(resp.bodyBytes));
        if (json['code'] != 0) {
          netError = 'code=${json['code']} ${json['message']}';
          debugPrint(
            '[BiliVideo] view code=${json['code']} ${json['message']}',
          );
        } else {
          data = _asMap(json['data']);
          if (data == null) netError = '视频不存在';
        }
      }
    } catch (e) {
      netError = '$e';
      debugPrint('[BiliVideo] 拉取视频详情异常: $e');
    }
    if (data != null) {
      lastErrorDetail = null;
      // 落盘缓存，下次直接读本地
      await VideoJsonCache.save(cacheKey, data);
      return BiliVideoDetail.fromJson(data);
    }
    // ③ 网络失败 / 数据异常：回退缓存（即使过期）
    final stale = await VideoJsonCache.load(
      cacheKey,
      ttl: _detailCacheTtl,
      allowStale: true,
    );
    if (stale != null) {
      lastErrorDetail = null;
      return BiliVideoDetail.fromJson(stale);
    }
    lastErrorDetail = netError ?? '视频不存在';
    return null;
  }

  /// 解析视频播放地址（DASH + durl 兜底）。qn 为 0 时使用服务端默认档位。
  ///
  /// 带持久 JSON 缓存：TTL 内直接复用上次解析结果（不再走 WBI + playurl
  /// 接口，打开同一视频秒出地址）；网络失败时回退缓存（即使过期）。
  static Future<BiliPlayUrl?> fetchPlayUrl({
    required String bvid,
    required int cid,
    int qn = 0,
  }) async {
    final bv = bvid.trim();
    if (bv.isEmpty || cid <= 0) {
      lastErrorDetail = '参数不完整';
      return null;
    }
    final cacheKey = 'play_${bv}_${cid}_$qn';
    // ① 命中缓存：直接返回（B 站 URL 有效期约 2 小时，TTL 内安全）
    final cached = await VideoJsonCache.load(cacheKey, ttl: _playUrlCacheTtl);
    if (cached != null) {
      lastErrorDetail = null;
      return BiliPlayUrl.fromJson(cached);
    }
    // ② 网络解析
    Map<String, dynamic>? data;
    String? netError;
    try {
      final params = await WbiSign.sign({
        'bvid': bv,
        'cid': cid.toString(),
        'qn': (qn > 0 ? qn : 80).toString(),
        // 获取 DASH（含 4K/杜比/HDR）+ durl 兜底
        'fnval': '4048',
        'fnver': '0',
        'fourk': '1',
        'gaia_source': 'pre-load',
        'web_location': '1315873',
        'platform': 'web',
        'dm_img_list': '[]',
        'dm_img_str': _randB64(64),
        'dm_cover_img_str': _randB64(128),
        'dm_img_inter': '{"ds":[],"wh":[0,0,0],"of":[0,0,0]}',
      });
      final uri = Uri.parse(_playUrlApi).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        netError = 'HTTP ${resp.statusCode}';
        debugPrint('[BiliVideo] playurl HTTP ${resp.statusCode}');
      } else {
        final json = jsonDecode(utf8.decode(resp.bodyBytes));
        if (json['code'] != 0) {
          netError = 'code=${json['code']} ${json['message']}';
          debugPrint(
            '[BiliVideo] playurl code=${json['code']} ${json['message']}',
          );
        } else {
          data = _asMap(json['data']);
          if (data == null) netError = '播放地址为空';
        }
      }
    } catch (e) {
      netError = '$e';
      debugPrint('[BiliVideo] 解析播放地址异常: $e');
    }
    if (data != null) {
      lastErrorDetail = null;
      // 落盘缓存（URL 签名含时效，但 TTL 内可复用，过后自动过期）
      await VideoJsonCache.save(cacheKey, data);
      return BiliPlayUrl.fromJson(data);
    }
    // ③ 网络失败：回退缓存（即使过期，试播）
    final stale = await VideoJsonCache.load(
      cacheKey,
      ttl: _playUrlCacheTtl,
      allowStale: true,
    );
    if (stale != null) {
      lastErrorDetail = null;
      return BiliPlayUrl.fromJson(stale);
    }
    lastErrorDetail = netError ?? '播放地址为空';
    return null;
  }

  /// 拉取相关视频列表（结果缓存 10 分钟，同一视频只请求一次）。
  /// [forceRefresh] 为 true 时忽略缓存重新请求。
  static Future<List<BiliRelatedVideo>> fetchRelated(
    String bvid, {
    bool forceRefresh = false,
  }) async {
    final bv = bvid.trim();
    if (bv.isEmpty) return const [];
    final key = 'rel_$bv';
    if (!forceRefresh) {
      final cached = _cached<List<BiliRelatedVideo>>(key);
      if (cached.data != null) return cached.data!;
    }
    try {
      final uri = Uri.parse(_relatedApi).replace(queryParameters: {'bvid': bv});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[BiliVideo] related HTTP ${resp.statusCode}');
        return const [];
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        debugPrint('[BiliVideo] related code=${json['code']}');
        return const [];
      }
      final data = json['data'];
      if (data is! List) {
        lastErrorDetail = '数据为空';
        return const [];
      }
      final result = data
          .whereType<Map<String, dynamic>>()
          .map(BiliRelatedVideo.fromJson)
          .where((v) => v.bvid.isNotEmpty)
          .toList();
      lastErrorDetail = null;
      _storeCache(key, result);
      return result;
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[BiliVideo] 拉取相关视频异常: $e');
      return const [];
    }
  }

  /// 拉取视频评论（委托 BilibiliCommentService，含风控 buvid3 cookie）。
  /// [oid] 为视频 aid（评论区分区 oid，与 cid 不同）。
  /// [sort] 0 = 按热度，1 = 按时间。
  /// 按 oid + sort + offset 缓存 10 分钟，翻页不重复请求。
  static Future<BiliReplyPage?> fetchReplies({
    required int oid,
    String? offset,
    int sort = 0,
    bool forceRefresh = false,
  }) async {
    final key = 'rep_${oid}_${sort}_${offset ?? ''}';
    if (!forceRefresh) {
      final cached = _cached<BiliReplyPage>(key);
      if (cached.data != null) return cached.data!;
    }
    final page = await comment_svc.BilibiliCommentService.fetchComments(
      cid: oid.toString(),
      offset: offset ?? '',
      sort: sort,
    );
    if (page == null) {
      lastErrorDetail = comment_svc.BilibiliCommentService.lastErrorDetail;
      return null;
    }
    lastErrorDetail = null;
    final result = BiliReplyPage(
      replies: page.comments,
      nextOffset: page.next.isEmpty ? null : page.next,
      isEnd: page.isEnd,
    );
    _storeCache(key, result);
    return result;
  }

  /// 从 Cookie 中提取指定字段（如 bili_jct）。
  static String _extractCookie(String cookie, String name) {
    final m = RegExp('(?:^|;\\s*)$name=([^;]+)').firstMatch(cookie);
    return m?.group(1) ?? '';
  }

  /// 需要登录且开启「携带 Cookie 请求」，否则静默跳过。
  static Future<void> reportProgress({
    required String bvid,
    required int aid,
    required int cid,
    required Duration position,
  }) async {
    final cookieHeader = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.video,
    );
    if (cookieHeader == null) return;
    final rawCookie = cookieHeader['Cookie'] ?? '';
    final csrf = _extractCookie(rawCookie, 'bili_jct');
    if (csrf.isEmpty) return;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      await client
          .post(
            Uri.parse(
              'https://api.bilibili.com/x/click-interface/web/heartbeat',
            ),
            headers: {
              ..._headers(),
              ...cookieHeader,
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'bvid': bvid,
              'aid': aid.toString(),
              'cid': cid.toString(),
              'played_time': position.inSeconds.toString(),
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 10));
      debugPrint(
        '[BiliVideo] 已上报播放进度: $bvid cid=$cid pos=${position.inSeconds}s',
      );
    } catch (e) {
      debugPrint('[BiliVideo] 上报播放进度失败: $e');
    }
  }

  /// 拉取 B 站云端播放进度（登录后同步云端历史用）：
  /// 调 /x/web-interface/history/cursor 匹配 aid/bvid，返回该视频最近
  /// 一次观看的分P cid 与进度（秒）。未登录 / 无记录返回 null。
  static Future<({int cid, int progressMs})?> fetchCloudProgress({
    required String bvid,
    required int aid,
  }) async {
    final cookieHeader = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.video,
    );
    if (cookieHeader == null) return null;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            Uri.parse('https://api.bilibili.com/x/web-interface/history/cursor')
                .replace(
                  queryParameters: {
                    'ps': '50',
                    'type': 'archive',
                    'view_at': '0',
                  },
                ),
            headers: {
              ..._headers(),
              ...cookieHeader,
            },
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;
      final list = json['data']?['list'] as List? ?? const [];
      for (final item in list) {
        if (item is! Map) continue;
        if (item['aid']?.toString() != aid.toString() &&
            item['bvid'] != bvid) {
          continue;
        }
        final cid = int.tryParse(item['cid']?.toString() ?? '');
        final progressSec =
            int.tryParse(item['progress']?.toString() ?? '') ?? 0;
        if (cid != null && cid > 0 && progressSec > 0) {
          debugPrint(
            '[BiliVideo] 云端进度: $bvid cid=$cid pos=${progressSec}s',
          );
          return (cid: cid, progressMs: progressSec * 1000);
        }
      }
    } catch (e) {
      debugPrint('[BiliVideo] 拉取云端进度失败: $e');
    }
    return null;
  }

  /// 生成 mpv 可播放的单 URL：
  ///   - 有 DASH → 用 edl:// 拼接最佳视频轨 + 最佳音频轨
  ///   - 否则回退 durl 的 FLV/MP4 地址
  ///
  /// [preferCodecs] 为解码格式前缀偏好列表（如 ['avc1'] / ['hev1','hvc1'] /
  /// ['av01']），在目标画质存在多个编码的视频轨时按顺序挑选；为空或未命中
  ///
  /// [sourceIndex] 为 CDN 源下标：0 = baseUrl，1..n = backupUrls[n-1]
  /// （视频轨与音频轨取同一下标，备用 CDN 顺序一致）。越界时回退到该轨
  /// 最后一个可用地址，保证任何画质/格式组合都不会返回 null。
  ///
  /// [sourceHost] 为手动指定 CDN 镜像域名：非空时把选中地址的 host 替换为
  /// 该域名（PiliPlus 同款换源——预设镜像表替换 baseUrl 的 host）。
  static String? buildPlayableUrl(
    BiliPlayUrl info, {
    int? quality,
    List<String>? preferCodecs,
    int sourceIndex = 0,
    String? sourceHost,
  }) {
    if (info.hasDash) {
      final video = pickVideoStream(
        info,
        quality: quality,
        preferCodecs: preferCodecs,
      );
      if (video == null) return null;
      final audio = info.audioStreams.isEmpty
          ? null
          : info.audioStreams.reduce(
              (a, b) => a.bandwidth > b.bandwidth ? a : b,
            );
      final vUrl = _urlAt(video, sourceIndex, host: sourceHost);
      if (vUrl.isEmpty) return null;
      if (audio == null) return vUrl;
      final aUrl = _urlAt(audio, sourceIndex, host: sourceHost);
      if (aUrl.isEmpty) return vUrl;
      // mpv edl:// 语法：%len% 为 URL 的字节长度，用于让解析器跳过「;」等字符
      return 'edl://'
          '!no_clip;!no_chapters;'
          '%${utf8.encode(vUrl).length}%$vUrl;'
          '!new_stream;!no_clip;!no_chapters;'
          '%${utf8.encode(aUrl).length}%$aUrl';
    }
    if (info.hasDurl) {
      var u = info.durlUrls[sourceIndex < info.durlUrls.length ? sourceIndex : 0];
      if (sourceHost != null && sourceHost.isNotEmpty) {
        try {
          u = Uri.parse(u).replace(host: sourceHost).toString();
        } catch (_) {}
      }
      return u;
    }
    return null;
  }

  /// 按画质 + 解码格式偏好挑选当前应播放的视频轨（换源菜单的源列表基于
  /// 该轨的 baseUrl + backupUrls 生成，保证下标与 [buildPlayableUrl] 一致）。
  static BiliDashStream? pickVideoStream(
    BiliPlayUrl info, {
    int? quality,
    List<String>? preferCodecs,
  }) {
    BiliDashStream? video;
    if (quality != null) {
      final matches = info.videoStreams.where((s) => s.id == quality).toList();
      if (matches.isNotEmpty) {
        video = _pickVideoStream(matches, preferCodecs);
      }
    }
    video ??= _pickVideoStream(
      info.videoStreams.where((s) => s.id == info.quality).toList(),
      preferCodecs,
    );
    if (video != null) return video;
    return info.videoStreams.isEmpty ? null : info.videoStreams.first;
  }

  /// 取某轨指定 CDN 下标的地址（baseUrl=0，backupUrls 依次递增），越界回退
  /// 末位；[host] 非空时替换该地址的域名（预设镜像换源）。
  static String _urlAt(BiliDashStream stream, int index, {String? host}) {
    final urls = stream.allUrls.toList();
    if (urls.isEmpty) return '';
    var u = urls[index.clamp(0, urls.length - 1)];
    if (host != null && host.isNotEmpty) {
      try {
        u = Uri.parse(u).replace(host: host).toString();
      } catch (_) {}
    }
    return u;
  }

  /// 从同画质的多个视频轨中按解码格式偏好挑选。
  static BiliDashStream? _pickVideoStream(
    List<BiliDashStream> streams,
    List<String>? preferCodecs,
  ) {
    if (streams.isEmpty) return null;
    if (preferCodecs != null && preferCodecs.isNotEmpty) {
      for (final codec in preferCodecs) {
        for (final s in streams) {
          if (s.codecs.toLowerCase().startsWith(codec)) return s;
        }
      }
    }
    return streams.first;
  }

  /// 拉取 B 站字幕（playurl 下发的 subtitle_url 是 JSON），转换为 SRT 文件
  /// 落盘到临时目录，返回本地文件路径（mpv/media_kit 可直接加载）。
  static Future<String?> fetchSubtitleSrt(String subtitleUrl) async {
    var url = subtitleUrl.trim();
    if (url.isEmpty) return null;
    if (url.startsWith('//')) url = 'https:$url';
    if (url.startsWith('http://')) url = 'https://${url.substring(7)}';
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(url), headers: _headers())
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        debugPrint('[BiliVideo] subtitle HTTP ${resp.statusCode}');
        return null;
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      final body = json['body'];
      if (body is! List || body.isEmpty) return null;

      final sb = StringBuffer();
      var index = 1;
      for (final item in body) {
        final m = item is Map ? item : const <dynamic, dynamic>{};
        final from = (m['from'] as num?)?.toDouble() ?? 0;
        final to = (m['to'] as num?)?.toDouble() ?? 0;
        final content = (m['content'] as String?)?.trim() ?? '';
        if (content.isEmpty) continue;
        sb
          ..writeln(index)
          ..writeln('${_srtTimecode(from)} --> ${_srtTimecode(to)}')
          ..writeln(content)
          ..writeln();
        index++;
      }
      if (sb.isEmpty) return null;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/navi_bili_sub_'
        '${DateTime.now().millisecondsSinceEpoch}.srt',
      );
      await file.writeAsString(sb.toString(), encoding: utf8);
      return file.path;
    } catch (e) {
      debugPrint('[BiliVideo] 拉取字幕异常: $e');
      return null;
    }
  }

  /// 拉取高能进度条片段（data.view_points，from/to 单位为秒）。
  static Future<List<BiliViewPoint>> fetchViewPoints({
    required int aid,
    required int cid,
  }) async {
    if (aid <= 0 || cid <= 0) return const [];
    try {
      final uri = Uri.parse('https://api.bilibili.com/x/player/v2').replace(
        queryParameters: {'aid': aid.toString(), 'cid': cid.toString()},
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        debugPrint('[BiliVideo] view_point HTTP ${resp.statusCode}');
        return const [];
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return const [];
      final vps = _asMap(json['data'])?['view_points'];
      if (vps is! List) return const [];
      return vps
          .map((e) => BiliViewPoint.fromJson(_asMap(e) ?? const {}))
          .where((v) => v.from >= 0 && v.to > v.from)
          .toList();
    } catch (e) {
      debugPrint('[BiliVideo] 拉取高能进度异常: $e');
      return const [];
    }
  }

  /// 拉取视频标签（x/tag/archive/tags，结果缓存 10 分钟）。
  static Future<List<BiliVideoTag>> fetchVideoTags({
    required String bvid,
    required int aid,
  }) async {
    if (bvid.isEmpty && aid <= 0) return const [];
    final key = 'tags_$bvid';
    final cached = _cached<List<BiliVideoTag>>(key);
    if (cached.data != null) return cached.data!;
    try {
      final uri = Uri.parse('https://api.bilibili.com/x/tag/archive/tags')
          .replace(
            queryParameters: {
              if (aid > 0) 'aid': aid.toString(),
              if (bvid.isNotEmpty) 'bvid': bvid,
              'pn': '1',
              'ps': '30',
            },
          );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        debugPrint('[BiliVideo] tags HTTP ${resp.statusCode}');
        return const [];
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        debugPrint('[BiliVideo] tags code=${json['code']} ${json['message']}');
        return const [];
      }
      final tags = _asMap(json['data'])?['tags'];
      if (tags is! List) return const [];
      final result = tags
          .map((e) => BiliVideoTag.fromJson(_asMap(e) ?? const {}))
          .where((t) => t.name.isNotEmpty)
          .toList();
      _storeCache(key, result);
      return result;
    } catch (e) {
      debugPrint('[BiliVideo] 拉取视频标签异常: $e');
      return const [];
    }
  }

  /// 拉取当前正在观看本视频的人数（/x/player/online/total，返回 data.total）。
  static Future<int> fetchOnlineTotal({
    required int aid,
    required String bvid,
    required int cid,
  }) async {
    if (aid <= 0 || cid <= 0) return 0;
    try {
      final uri = Uri.parse('https://api.bilibili.com/x/player/online/total')
          .replace(
            queryParameters: {
              'aid': aid.toString(),
              'bvid': bvid,
              'cid': cid.toString(),
            },
          );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return 0;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return 0;
      return _toInt(_asMap(json['data'])?['total']);
    } catch (e) {
      debugPrint('[BiliVideo] 拉取在线人数异常: $e');
      return 0;
    }
  }

  /// 拉取视频公开笔记列表（/x/note/publish/list/archive，oid = aid）。
  /// 列表只给 cvid/摘要/作者，正文由 ArticlePage 按 cvid 拉取。
  /// 返回 null 表示请求失败；data.list 为空即该视频无笔记。
  static Future<BiliVideoNotePage?> fetchVideoNotes({
    required int aid,
    int pn = 1,
    int ps = 10,
  }) async {
    if (aid <= 0) return null;
    try {
      final uri = Uri.parse(
        'https://api.bilibili.com/x/note/publish/list/archive',
      ).replace(
        queryParameters: {
          'oid': aid.toString(),
          'oid_type': '0',
          'pn': pn.toString(),
          'ps': ps.toString(),
        },
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        debugPrint('[BiliVideo] notes HTTP ${resp.statusCode}');
        return null;
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        debugPrint('[BiliVideo] notes code=${json['code']} ${json['message']}');
        return null;
      }
      final data = _asMap(json['data']);
      final rawList = data?['list'];
      final list = rawList is List
          ? rawList
                .map((e) => BiliVideoNote.fromJson(_asMap(e) ?? const {}))
                .where((n) => n.cvid > 0)
                .toList()
          : <BiliVideoNote>[];
      final total = _toInt(_asMap(data?['page'])?['total']);
      return BiliVideoNotePage(list: list, total: total);
    } catch (e) {
      debugPrint('[BiliVideo] 拉取视频笔记异常: $e');
      return null;
    }
  }

  static String _srtTimecode(double seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final ms = ((s - s.floor()) * 1000).round();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(s.floor())},${ms.toString().padLeft(3, '0')}';
  }

  static String _randB64(int n) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final r = Random();
    return List.generate(n, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
