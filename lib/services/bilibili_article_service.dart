// lib/services/bilibili_article_service.dart
//
// articleView / articleInfo 实现，按本项目风格精简为只读浏览）：
//   - 文章详情：x/article/view（需 WBI 签名）
//     · type 1：data.content 为 HTML 正文
//     · type 3：data.ops 为 JSON 富文本段落（insert + attributes）
//     · data.stats 含 阅读/点赞/收藏/评论/转发 等计数
// 请求方式与搜索/用户空间服务一致：复用 NetworkSettingsService 客户端与
// 请求头，设备指纹（buvid3/buvid4/b_lsid）+ 登录 Cookie 降低风控概率。
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart' show WbiSign;
import 'package:naviflash/services/network_settings_service.dart';
import '../l10n/l10n_helper.dart';

// ═════════════════════════════════════════
//  安全解析工具（与搜索/用户空间服务同款）
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

/// 补全 B 站图片地址（相对路径/无协议头 → 完整 https URL）。
String _normalizeUrl(String url) {
  if (url.isEmpty) return url;
  if (url.startsWith('bfs/')) return 'https://i0.hdslb.com/$url';
  if (url.startsWith('//')) return 'https:$url';
  return url;
}

// ═════════════════════════════════════════
//  模型
// ═════════════════════════════════════════

class BiliArticleAuthor {
  final int mid;
  final String name;
  final String face;

  const BiliArticleAuthor({
    required this.mid,
    required this.name,
    required this.face,
  });

  factory BiliArticleAuthor.fromJson(Map<String, dynamic> json) {
    return BiliArticleAuthor(
      mid: _toInt(json['mid']),
      name: (json['name'] as String?) ?? '',
      face: _normalizeUrl((json['face'] as String?) ?? ''),
    );
  }
}

class BiliArticleStats {
  final int view; // 阅读
  final int like; // 点赞
  final int favorite; // 收藏
  final int reply; // 评论
  final int share; // 转发
  final int coin; // 硬币

  const BiliArticleStats({
    required this.view,
    required this.like,
    required this.favorite,
    required this.reply,
    required this.share,
    required this.coin,
  });

  factory BiliArticleStats.fromJson(Map<String, dynamic> json) {
    return BiliArticleStats(
      view: _toInt(json['view']),
      like: _toInt(json['like']),
      favorite: _toInt(json['favorite']),
      reply: _toInt(json['reply']),
      share: _toInt(json['share']),
      coin: _toInt(json['coin']),
    );
  }
}

/// 单个 JSON 富文本操作（type=3 文章用）：
///   - [insert]：String 时为文本（含 \n）；Map 时为卡片（image/video/article 等）
///   - [clazz]：attributes.class（如 'article-card card'）
class BiliArticleOps {
  final Object insert;
  final String clazz;

  const BiliArticleOps({required this.insert, required this.clazz});

  /// 卡片图片地址（insert 为 Map 时）。
  String? get cardImage {
    final m = _asMap(insert);
    if (m == null) return null;
    final url = ((m['url'] as String?) ?? (m['image'] as String?)) ?? '';
    return url.isEmpty ? null : _normalizeUrl(url);
  }

  /// 卡片跳转目标 id（article-card / video-card 等）。
  String? get cardId {
    final m = _asMap(insert);
    if (m == null) return null;
    final id = (m['id'] as String?) ?? '';
    return id.isEmpty ? null : id;
  }

  factory BiliArticleOps.fromJson(Map<String, dynamic> json) {
    final insert = json['insert'] ?? '';
    final attrs = _asMap(json['attributes']);
    return BiliArticleOps(
      insert: insert,
      clazz: (attrs?['class'] as String?) ?? '',
    );
  }
}

class BiliArticle {
  final int id;
  final int type; // 1 = HTML 正文；3 = JSON ops
  final String title;
  final BiliArticleAuthor? author;
  final int publishTime; // Unix 秒
  final String cover; // 首图
  final List<String> images; // 全部图片
  final String contentHtml; // type=1 的 HTML 正文
  final List<BiliArticleOps> ops; // type=3 的 JSON 富文本
  final BiliArticleStats? stats;

  const BiliArticle({
    required this.id,
    required this.type,
    required this.title,
    required this.author,
    required this.publishTime,
    required this.cover,
    required this.images,
    required this.contentHtml,
    required this.ops,
    required this.stats,
  });

  /// 是否 JSON 富文本正文。
  bool get isOps => ops.isNotEmpty;

  /// 是否 HTML 正文。
  bool get isHtml => contentHtml.isNotEmpty;

  /// 文章在 B 站的可读地址。
  String get url => 'https://www.bilibili.com/read/cv$id';

  factory BiliArticle.fromJson(Map<String, dynamic> json) {
    final authorJson = _asMap(json['author']);
    final statsJson = _asMap(json['stats']);
    final rawImages = json['origin_image_urls'];
    final imageUrls = rawImages is List
        ? rawImages
              .whereType<String>()
              .map(_normalizeUrl)
              .where((u) => u.isNotEmpty)
              .toList()
        : <String>[];
    final rawOps = json['ops'];
    final ops = rawOps is List
        ? rawOps
              .whereType<Map<String, dynamic>>()
              .map(BiliArticleOps.fromJson)
              .toList()
        : <BiliArticleOps>[];
    return BiliArticle(
      id: _toInt(json['id']),
      type: _toInt(json['type']),
      title: (json['title'] as String?) ?? '',
      author: authorJson == null
          ? null
          : BiliArticleAuthor.fromJson(authorJson),
      publishTime: _toInt(json['publish_time']),
      cover: imageUrls.isNotEmpty ? imageUrls.first : '',
      images: imageUrls,
      contentHtml: (json['content'] as String?) ?? '',
      ops: ops,
      stats: statsJson == null ? null : BiliArticleStats.fromJson(statsJson),
    );
  }
}

// ═════════════════════════════════════════
//  服务
// ═════════════════════════════════════════

abstract final class BilibiliArticleService {
  static const String _viewApi = 'https://api.bilibili.com/x/article/view';

  /// 最近一次失败的具体原因（供界面展示，便于诊断），成功时清空。
  static String? lastErrorDetail;

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  /// 会话级持久 buvid3（与评论区服务一致：生成一次，全程复用，
  /// 避免每次拉取时更换设备指纹被 B 站风控标记为 bot 导致 -352）。
  static final String _buvid3 = _genBuvid3();

  /// 设备指纹（buvid3/buvid4）：优先从 spi 接口取服务端下发的真实值，
  /// 会话内缓存；失败时回退 _buvid3。真实指纹可显著降低风控拦截概率。
  static String? _spiBuvid3;
  static String? _spiBuvid4;

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

  static Future<void> _ensureDeviceFp() async {
    if (_spiBuvid3 != null) return;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      // 不携带临时 buvid3 Cookie，让 spi 端点下发全新指纹
      final resp = await client
          .get(
            Uri.parse('https://api.bilibili.com/x/frontend/finger/spi'),
            headers: {
              ..._defaultHeaders,
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        if (json['code'] == -352) {
          debugPrint('[Article] spi 获取指纹被风控 (-352)，回退随机指纹');
        }
        return;
      }
      final data = _asMap(json['data']);
      if (data == null) return;
      final b3 = (data['b_3'] as String?) ?? '';
      if (b3.isNotEmpty) {
        _spiBuvid3 = b3;
        _spiBuvid4 = (data['b_4'] as String?) ?? '';
      }
    } catch (e) {
      debugPrint('[Article] 获取设备指纹失败: $e');
    }
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
      'buvid3=${_spiBuvid3 ?? _buvid3}',
      if (_spiBuvid4?.isNotEmpty ?? false) 'buvid4=$_spiBuvid4',
      'b_nut=${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
      'b_lsid=${_genBLsid()}',
    ];
    final accountCookie = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.article,
    )?['Cookie'];
    if (accountCookie != null && accountCookie.isNotEmpty) {
      parts.insert(0, accountCookie);
    }
    return parts.join('; ');
  }

  static Future<Map<String, String>> _buildHeaders({required int cvid}) async {
    final cookie = await _buildCookie();
    return {
      ..._defaultHeaders,
      'Referer': 'https://www.bilibili.com/read/cv$cvid/',
      'Origin': 'https://www.bilibili.com',
      'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  /// 失败返回 null，[lastErrorDetail] 记录原因。
  ///
  /// 带本地缓存（[ArticleCache]）：TTL 内直接读缓存渲染、不再请求网络；
  /// 网络失败 / 数据异常时回退缓存（即使过期）保证离线可看；
  /// 设置页「清理缓存」可一键清除。
  static Future<BiliArticle?> fetchArticle({required int cvid}) async {
    if (cvid <= 0) {
      lastErrorDetail = L10n.current.biliResponseNoData;
      return null;
    }
    // ① 缓存命中（TTL 内）：直接读本地渲染，不请求网络
    final cached = await ArticleCache.load(cvid);
    if (cached != null) {
      debugPrint('[Article] 命中缓存: cv$cvid');
      lastErrorDetail = null;
      return BiliArticle.fromJson(cached);
    }
    // ② 网络拉取，成功后落盘缓存
    Map<String, dynamic>? data;
    String? netError;
    try {
      // 不携带 dm_* 类反指纹参数，避免格式不当触发 code-352
      final params = await WbiSign.sign({
        'id': cvid.toString(),
        'gaia_source': 'main_web',
        'web_location': '333.976',
      });
      final uri = Uri.parse(_viewApi).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final headers = await _buildHeaders(cvid: cvid);
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        netError = L10n.current.biliHttpError(resp.statusCode);
        debugPrint('[Article] HTTP ${resp.statusCode}');
      } else {
        final json = jsonDecode(utf8.decode(resp.bodyBytes));
        if (json is! Map<String, dynamic>) {
          netError = L10n.current.biliResponseNoData;
        } else {
          final code = json['code'];
          if (code != 0 && code != 200) {
            netError = 'code=$code ${json['message']} (cvid=$cvid)';
            debugPrint('[Article] code=$code ${json['message']}');
          } else {
            data = _asMap(json['data']);
            if (data == null || _toInt(data['id']) <= 0) {
              netError = L10n.current.biliResponseNoData;
              data = null;
            }
          }
        }
      }
    } catch (e) {
      netError = L10n.current.commentException('$e');
      debugPrint('[Article] 拉取专栏异常: $e');
    }
    if (data != null) {
      lastErrorDetail = null;
      // 落盘缓存，下次直接读本地
      await ArticleCache.save(cvid, data);
      return BiliArticle.fromJson(data);
    }
    // ③ 网络失败 / 数据异常：回退缓存（即使过期），保证离线可看
    final stale = await ArticleCache.load(cvid, allowStale: true);
    if (stale != null) {
      lastErrorDetail = null;
      return BiliArticle.fromJson(stale);
    }
    lastErrorDetail = netError ?? L10n.current.biliResponseNoData;
    return null;
  }

  // ── 图片 ──

  /// 作者头像地址（压缩到 96px）。
  static String avatarUrl(String url, {int size = 96}) {
    if (url.isEmpty) return '';
    return '${_normalizeUrl(url)}@${size}w_${size}h_1c.webp';
  }
}

// ═════════════════════════════════════════
//  专栏详情本地缓存
// ═════════════════════════════════════════

/// 专栏详情缓存：拉取到的文章原始 JSON 落盘到应用私有目录
/// （<文档目录>/article_cache），下次查看直接读本地、不重新请求；
/// 设置页「清理缓存」可一键清除。
class ArticleCache {
  static const String cacheDirName = 'article_cache';

  /// 测试专用：fake-async 测试环境下 dart:io 文件操作不会完成，
  /// 会让整个加载流程挂起；置为 true 时跳过磁盘缓存读写
  /// （读返回未命中、写直接忽略）。生产代码永远保持 false。
  static bool disabled = false;

  /// 缓存有效期（24 小时内直接读缓存，不再请求网络）。
  static const Duration ttl = Duration(hours: 24);

  /// 最多缓存条数，超出后淘汰最旧。
  static const int _maxCacheFiles = 200;

  /// 缓存目录（应用私有文档目录下，不跟随系统清理）。
  static Future<Directory> get cacheDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$cacheDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// cvid → 缓存文件名（md5）。
  static String cacheKey(int cvid) =>
      md5.convert(utf8.encode('$cvid')).toString();

  static Future<File> _cacheFile(int cvid) async {
    final dir = await cacheDir;
    return File('${dir.path}/${cacheKey(cvid)}.json');
  }

  /// 保存文章原始 JSON 到缓存（含时间戳用于 TTL 判断）。
  static Future<void> save(int cvid, Map<String, dynamic> data) async {
    if (disabled) return;
    try {
      final file = await _cacheFile(cvid);
      await file.writeAsString(
        jsonEncode({'ts': DateTime.now().millisecondsSinceEpoch, 'data': data}),
        flush: true,
      );
      await _evictOldEntries();
    } catch (e) {
      debugPrint('[ArticleCache] 写入缓存失败: $e');
    }
  }

  /// 读取缓存；[allowStale] 为 true 时即使过期也返回（网络失败回退用）。
  static Future<Map<String, dynamic>?> load(
    int cvid, {
    bool allowStale = false,
  }) async {
    if (disabled) return null;
    try {
      final file = await _cacheFile(cvid);
      if (!await file.exists()) return null;
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map<String, dynamic>) return null;
      final ts = (raw['ts'] as num?)?.toInt() ?? 0;
      final data = raw['data'];
      if (data is! Map<String, dynamic>) return null;
      final fresh =
          DateTime.now().millisecondsSinceEpoch - ts < ttl.inMilliseconds;
      if (!fresh && !allowStale) return null;
      return data;
    } catch (e) {
      debugPrint('[ArticleCache] 读取缓存失败: $e');
      return null;
    }
  }

  /// 缓存总大小（字节）。
  static Future<int> totalSize() async {
    try {
      final dir = await cacheDir;
      if (!await dir.exists()) return 0;
      var total = 0;
      await for (final entity in dir.list()) {
        if (entity is File) {
          total += await entity.length().catchError((_) => 0);
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// 缓存文件数量。
  static Future<int> count() async {
    try {
      final dir = await cacheDir;
      if (!await dir.exists()) return 0;
      var count = 0;
      await for (final entity in dir.list()) {
        if (entity is File) count++;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// 清空所有专栏缓存。
  static Future<void> clearAll() async {
    try {
      final dir = await cacheDir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// 列出全部已缓存专栏（读文件内容提取 cvid/标题，供透明查看页）。
  static Future<List<ArticleCacheEntry>> listEntries() async {
    try {
      final dir = await cacheDir;
      if (!await dir.exists()) return const [];
      final entries = <ArticleCacheEntry>[];
      await for (final entity in dir.list()) {
        if (entity is! File || !entity.path.endsWith('.json')) continue;
        try {
          final raw = jsonDecode(await entity.readAsString());
          final data = (raw is Map<String, dynamic>) ? raw['data'] : null;
          if (data is! Map<String, dynamic>) continue;
          var cvid = _toInt(data['id']);
          if (cvid <= 0) {
            cvid =
                int.tryParse(
                  entity.uri.pathSegments.last.replaceAll('.json', ''),
                ) ??
                0;
          }
          var bytes = 0;
          var savedAt = DateTime.fromMillisecondsSinceEpoch(0);
          try {
            bytes = await entity.length();
            savedAt = await entity.lastModified();
          } catch (_) {}
          entries.add(
            ArticleCacheEntry(
              cvid: cvid,
              title: (data['title'] as String?) ?? '',
              bytes: bytes,
              savedAt: savedAt,
            ),
          );
        } catch (_) {}
      }
      entries.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return entries;
    } catch (_) {
      return const [];
    }
  }

  /// 删除单条专栏缓存。
  static Future<void> deleteOne(int cvid) async {
    try {
      final file = await _cacheFile(cvid);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// 淘汰最旧的缓存文件（超出上限时）。
  static Future<void> _evictOldEntries() async {
    try {
      final dir = await cacheDir;
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();
      if (files.length <= _maxCacheFiles) return;
      files.sort(
        (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),
      );
      for (final f in files.take(files.length - _maxCacheFiles)) {
        await f.delete();
      }
    } catch (_) {}
  }
}

/// 一条已缓存专栏记录（供「已缓存文字/数据」查看页透明展示）。
class ArticleCacheEntry {
  final int cvid;
  final String title;
  final int bytes;
  final DateTime savedAt;

  const ArticleCacheEntry({
    required this.cvid,
    required this.title,
    required this.bytes,
    required this.savedAt,
  });

  String get url => 'https://www.bilibili.com/read/cv$cvid';
}
