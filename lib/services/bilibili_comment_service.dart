// lib/services/bilibili_comment_service.dart
//
// lib/models_new/reply/* 实现，按本项目风格精简为只读评论浏览）：
//   - 主楼评论：x/v2/reply/main（热度/时间排序，游标分页）
//   - 楼中楼：  x/v2/reply/reply（root 分页）
// 请求方式与弹幕 Fetcher 一致：复用 NetworkSettingsService 的客户端与请求头。

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart'
    show WbiSign, BiliFansDetail;
import 'package:naviflash/services/image_cache_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import '../l10n/l10n_helper.dart';

// ═════════════════════════════════════════
//  模型：评论成员
// ═════════════════════════════════════════

class BiliCommentMember {
  final String mid;
  final String uname;
  final String avatar;
  final int level;
  final int vipType;
  final int vipStatus;
  final int officialType;

  /// 头像粉丝装扮挂件图（member.pendant.image，用户当前佩戴的装扮挂件，
  final String pendantImage;

  /// 粉丝装扮徽章（member.fans_detail，仅登录且对方佩戴了当前账号
  /// 粉丝勋章时服务端下发，可为 null）。
  final BiliFansDetail? fansDetail;

  const BiliCommentMember({
    required this.mid,
    required this.uname,
    required this.avatar,
    required this.level,
    required this.vipType,
    required this.vipStatus,
    required this.officialType,
    this.pendantImage = '',
    this.fansDetail,
  });

  factory BiliCommentMember.fromJson(Map<String, dynamic> json) {
    final vip = json['vip'] as Map<String, dynamic>?;
    final official = json['official_verify'] as Map<String, dynamic>?;
    final levelInfo = json['level_info'] as Map<String, dynamic>?;
    final pendant = json['pendant'] as Map<String, dynamic>?;
    final fansDetailJson = json['fans_detail'] as Map<String, dynamic>?;
    return BiliCommentMember(
      mid: (json['mid'] as dynamic)?.toString() ?? '',
      uname: (json['uname'] as String?) ?? '',
      avatar: (json['avatar'] as String?) ?? '',
      level: (levelInfo?['current_level'] as num?)?.toInt() ?? 0,
      vipType: (vip?['vipType'] as num?)?.toInt() ?? 0,
      vipStatus: (vip?['vipStatus'] as num?)?.toInt() ?? 0,
      officialType: (official?['type'] as num?)?.toInt() ?? -1,
      pendantImage: _normalizeUrl((pendant?['image'] as String?) ?? ''),
      fansDetail: fansDetailJson == null
          ? null
          : BiliFansDetail.fromJson(fansDetailJson),
    );
  }
}

// ═════════════════════════════════════════
//  模型：评论表情（content.emote，随评论下发）
// ═════════════════════════════════════════

class BiliCommentEmote {
  final String text; // 表情文本，如 [呲牙]
  final String url; // 表情图地址
  final int size;

  const BiliCommentEmote({
    required this.text,
    required this.url,
    required this.size,
  });

  factory BiliCommentEmote.fromJson(String text, Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>?;
    return BiliCommentEmote(
      text: text,
      url: (json['url'] as String?) ?? '',
      size: (meta?['size'] as num?)?.toInt() ?? 0,
    );
  }
}

// ═════════════════════════════════════════
//  模型：评论配图（content.pictures）
// ═════════════════════════════════════════

class BiliCommentPicture {
  final String src;
  final int width;
  final int height;

  const BiliCommentPicture({
    required this.src,
    required this.width,
    required this.height,
  });

  factory BiliCommentPicture.fromJson(Map<String, dynamic> json) {
    return BiliCommentPicture(
      src: _normalizeUrl((json['img_src'] as String?) ?? ''),
      width: (json['img_width'] as num?)?.toInt() ?? 0,
      height: (json['img_height'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 补全/升级图片地址协议：接口下发的可能是 `//` 或 `http://`。
String _normalizeUrl(String url) {
  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('http://')) return 'https://${url.substring(7)}';
  return url;
}

// ═════════════════════════════════════════
//  模型：评论条目
// ═════════════════════════════════════════

class BiliComment {
  final String rpid;
  final String oid;
  final String mid;
  final String root;
  final String parent;
  final int count; // 楼中楼总回复数
  final int like;
  final int ctime;
  final String message;
  final Map<String, BiliCommentEmote> emotes; // 本条评论用到的表情
  final List<BiliCommentPicture> pictures; // 评论区配图
  final BiliCommentMember member;
  final List<BiliComment> replies; // 主楼附带的楼中楼预览

  /// 评论地区（x/v2/reply 接口下发，可能为空）。
  final String location;

  /// 是否 UP 主本人评论（由调用方在知道视频 owner mid 时设置）。
  final bool isUp;

  const BiliComment({
    required this.rpid,
    required this.oid,
    required this.mid,
    required this.root,
    required this.parent,
    required this.count,
    required this.like,
    required this.ctime,
    required this.message,
    required this.emotes,
    required this.pictures,
    required this.member,
    required this.replies,
    this.location = '',
    this.isUp = false,
  });

  // ── 便捷访问（列表页直接使用，无需钻 member） ──
  String get uname => member.uname;
  String get avatar => member.avatar;
  int get replyCount => count;

  BiliComment copyWith({int? count, bool? isUp}) => BiliComment(
        rpid: rpid,
        oid: oid,
        mid: mid,
        root: root,
        parent: parent,
        count: count ?? this.count,
        like: like,
        ctime: ctime,
        message: message,
        emotes: emotes,
        pictures: pictures,
        member: member,
        replies: replies,
        location: location,
        isUp: isUp ?? this.isUp,
      );

  factory BiliComment.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>?;
    final subList = json['replies'] as List<dynamic>?;
    // content.emote：[表情文本] → {url, meta:{size}}，用于正文内联渲染
    final emoteJson = content?['emote'] as Map<String, dynamic>?;
    final emotes = Map<String, BiliCommentEmote>.fromEntries(
      (emoteJson?.entries ?? const <MapEntry<String, dynamic>>[])
          .where((e) => e.value is Map<String, dynamic>)
          .map(
            (e) => MapEntry(
              e.key,
              BiliCommentEmote.fromJson(e.key, e.value as Map<String, dynamic>),
            ),
          )
          .where((e) => e.value.url.isNotEmpty),
    );
    // content.pictures 可能为列表；个别场景为单个对象，统一转为列表
    final dynamic picsRaw = content?['pictures'];
    final picsList = picsRaw is List
        ? picsRaw
        : (picsRaw is Map ? [picsRaw] : const <dynamic>[]);
    final pictures = picsList
        .whereType<Map<String, dynamic>>()
        .map(BiliCommentPicture.fromJson)
        .where((p) => p.src.isNotEmpty)
        .toList();
    return BiliComment(
      rpid: (json['rpid'] as dynamic)?.toString() ?? '',
      oid: (json['oid'] as dynamic)?.toString() ?? '',
      mid: (json['mid'] as dynamic)?.toString() ?? '',
      root: (json['root'] as dynamic)?.toString() ?? '',
      parent: (json['parent'] as dynamic)?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      like: (json['like'] as num?)?.toInt() ?? 0,
      ctime: (json['ctime'] as num?)?.toInt() ?? 0,
      message: (content?['message'] as String?) ?? '',
      emotes: emotes,
      pictures: pictures,
      member: json['member'] is Map<String, dynamic>
          ? BiliCommentMember.fromJson(json['member'] as Map<String, dynamic>)
          : const BiliCommentMember(
              mid: '',
              uname: '',
              avatar: '',
              level: 0,
              vipType: 0,
              vipStatus: 0,
              officialType: -1,
            ),
      replies: (subList ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BiliComment.fromJson)
          .toList(),
      location: (json['location'] as String?) ?? '',
    );
  }
}

// ═════════════════════════════════════════
//  模型：B 站表情面板（写评论用，/x/emote/user/panel/web）
// ═════════════════════════════════════════

/// 表情包里的单个表情。
class BiliPanelEmote {
  /// 发送用的文本（如 "[dog]"，原样进 message）。
  final String text;
  final String url;

  /// meta.size：1 = 小表情；0/其他 = 大表情（面板格子尺寸区分）。
  final int size;

  const BiliPanelEmote({
    required this.text,
    required this.url,
    this.size = 0,
  });

  factory BiliPanelEmote.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'];
    return BiliPanelEmote(
      text: (json['text'] as dynamic)?.toString() ?? '',
      url: (json['url'] as dynamic)?.toString() ?? '',
      size: (meta is Map ? meta['size'] : null) is num
          ? (meta!['size'] as num).toInt()
          : 0,
    );
  }
}

/// 一个表情包（如「热词」「小白脸」；type 4 = 文字包）。
class BiliEmotePackage {
  final String url; // 包图标
  final int type;
  final List<BiliPanelEmote> emotes;

  const BiliEmotePackage({
    required this.url,
    required this.type,
    required this.emotes,
  });

  /// type 4 = 文字包（面板按文字渲染）。
  bool get isTextPackage => type == 4;

  factory BiliEmotePackage.fromJson(Map<String, dynamic> json) {
    final rawEmotes = json['emote'];
    return BiliEmotePackage(
      url: (json['url'] as dynamic)?.toString() ?? '',
      type: (json['type'] as num?)?.toInt() ?? 0,
      emotes: rawEmotes is List
          ? rawEmotes
                .whereType<Map<String, dynamic>>()
                .map(BiliPanelEmote.fromJson)
                .where((e) => e.text.isNotEmpty && e.url.isNotEmpty)
                .toList()
          : const [],
    );
  }
}

// ═════════════════════════════════════════
//  模型：分页结果
// ═════════════════════════════════════════

class BiliCommentPage {
  final List<BiliComment> comments;
  final List<BiliComment> topReplies; // 置顶评论
  final String next; // 下一页游标
  final bool isEnd;
  final int allCount; // 评论总数

  const BiliCommentPage({
    required this.comments,
    required this.topReplies,
    required this.next,
    required this.isEnd,
    required this.allCount,
  });
}

class BiliSubCommentPage {
  final List<BiliComment> replies;
  final bool isEnd;
  final int total;

  const BiliSubCommentPage({
    required this.replies,
    required this.isEnd,
    required this.total,
  });
}

// ═════════════════════════════════════════
//  服务
// ═════════════════════════════════════════

abstract final class BilibiliCommentService {
  static const String _mainApi = 'https://api.bilibili.com/x/v2/reply/main';
  static const String _subApi = 'https://api.bilibili.com/x/v2/reply/reply';
  static const String _actionApi = 'https://api.bilibili.com/x/v2/reply/action';
  static const String _replyAddApi = 'https://api.bilibili.com/x/v2/reply/add';
  static const String _emotePanelApi =
      'https://api.bilibili.com/x/emote/user/panel/web';

  /// 表情面板会话级缓存（登录后一次拉取，关闭弹层不重拉）。
  static List<BiliEmotePackage>? _emotePanelCache;

  /// 清空表情面板缓存（刷新 / 切换账号后重拉）。
  static void resetEmotePanelCache() => _emotePanelCache = null;

  /// 最近一次失败的具体原因（供界面展示，便于诊断），成功时清空。
  static String? lastErrorDetail;

  /// 游客态走 APP 伪装头 + 空 cookie（Cookie: ''），不带 buvid3——
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

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  ///
  /// 关键点（经 tool/reply_probe.dart 实测验证）：
  ///     BiliDroid UA 会被 B 站风控拦截（code: -352），Chrome UA + wbi 只给
  ///     3 条评论（is_end=true）。只有 `Dart/3.6 (dart:io)` 这个 UA + APP
  ///     伪装头组合能通过风控、返回全量 20 条/页。
  ///   - **不签 wbi、不带 web_location、不带 buvid3 cookie**。
  ///   - **HTTP/2 不是必需的**——HTTP/1.1 同样能拉到全量评论。
  static const Map<String, String> _guestAppHeaders = {
    'User-Agent': 'Dart/3.6 (dart:io)',
    'Accept-Encoding': 'gzip',
    'env': 'prod',
    'app-key': 'android64',
    'x-bili-aurora-zone': 'sh001',
  };

  /// 排序：0 = 按热度，1 = 按时间
  static int _modeOf(int sort) => sort == 1 ? 2 : 3;

  /// 接口的 is_end 字段可能是 bool（true/false），个别场景也可能是 1/0。
  static bool _asBool(dynamic v) => v == true || v == 1 || v == '1';

  /// 游客（未登录且未开启携带 Cookie）时为 true：走 APP 伪装头、不带 wbi。
  static bool get _isGuest =>
      BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.comments,
      ) ==
      null;

  /// 登录走 Web 头 + 完整 Cookie。
  //
  // 游客模式下必须排除 apiHeaders 里的 User-Agent / Referer——
  // 用户在网络设置里自定义的 UA（如 Chrome / BiliDroid）会破坏 APP 伪装，
  // 导致风控拦截（-352）或只给 3 条评论。翻译相关的 x-bili-* / buvid
  // 头不影响风控，保留。
  static Map<String, String> get _headers {
    if (_isGuest) {
      final extra = Map.of(NetworkSettingsService.instance.apiHeaders)
        ..removeWhere(
          (k, _) =>
              k.toLowerCase() == 'user-agent' ||
              k.toLowerCase() == 'referer',
        );
      return {
        ...extra,
        ..._guestAppHeaders,
        'Cookie': '',
      };
    }
    return {
      ..._defaultHeaders,
      'Cookie': 'buvid3=$_buvid3',
//  用户登录且开启「携带 Cookie 请求」时附加完整 Cookie，
      //   覆盖上面的游客 buvid3（登录后评论区接口返回值更完整）
      ...?BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.comments,
      ),
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  /// 主楼评论分页拉取。
  /// [sort] 0 = 按热度，1 = 按时间。
  /// [offset] 为服务端游标，由调用方把上一页的 next 原样传回：
  ///   - 第一页传空（不带 offset 字段）
  ///   - 之后每页传上一页返回的 cursor.pagination_reply.next_offset，
  ///     直到服务端标记 is_end
  ///
  /// 登录态与游客统一走 /main 的 mode + pagination_str 游标分页（与 B 站
  /// Web 端一致）。注意两点：
  ///     的是旧接口 x/v2/reply，若把 pn/ps/sort 发给 /main 会被服务端
  ///     忽略（永远返回按热度排序的第一页，无法翻页）；
  ///   - 真正的翻页游标在 cursor.pagination_reply.next_offset，
  ///     cursor.next 只是页码计数（如 2），拿它当游标会被服务端忽略，
  ///     永远重复返回第一页。
  static Future<BiliCommentPage?> fetchComments({
    required String cid,
    int sort = 0,
    String offset = '',
    String type = '1',
  }) async {
    try {
      final oid = cid.trim();
      if (oid.isEmpty) {
        lastErrorDetail = L10n.current.commentOidEmpty;
        return null;
      }
      // 登录：走 Web 风格（pagination_str 带 max_num + _gt_、web_location、
      //   wbi 签名，与 B 站 Web 端一致）。
      //   （见 _guestAppHeaders 注释），pagination_str 只含 offset、不带
      //   web_location、不签 wbi。经 probe 实测：Chrome UA + wbi 只给 3 条
      //   （is_end=true），BiliDroid UA 被风控拦截（-352），只有
      //   Dart/3.6 (dart:io) UA + APP 头能拉全量 20 条/页。
      final paginationStr = _isGuest
          ? jsonEncode({'offset': offset})
          : jsonEncode({
              if (offset.isNotEmpty) 'offset': offset,
              'max_num': 20,
              '_gt_': 0,
            }).replaceAll(' ', '');
      final baseParams = <String, String>{
        'oid': oid,
        'type': type,
        'mode': _modeOf(sort).toString(),
        'pagination_str': paginationStr,
      };
      final params = _isGuest
          ? baseParams
          // 签名失败（拿不到 mixinKey）时原样返回，请求照常发出。
          : await WbiSign.sign({...baseParams, 'web_location': '333.788'});
      final uri = Uri.parse(_mainApi).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[Comment] HTTP ${resp.statusCode}');
        return null;
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']} (oid=$oid)';
        debugPrint('[Comment] code=${json['code']} message=${json['message']}');
        return null;
      }
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        lastErrorDetail = L10n.current.biliResponseNoData;
        return null;
      }

      final topReplies = (data['top_replies'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BiliComment.fromJson)
          .toList();
      // 置顶评论的 rpid 集合：服务端在第一页可能把置顶评论同时放进
      // replies 和 top_replies，导致 UI 列表里同一条评论出现两次
      // （一次在置顶区、一次在普通区）。按 rpid 从普通列表里剔除。
      final topRpids = topReplies.map((e) => e.rpid).toSet();
      final comments = (data['replies'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BiliComment.fromJson)
          .where((c) => !topRpids.contains(c.rpid))
          .toList();
      final cursorJson = data['cursor'] as Map<String, dynamic>?;
      // 真正的游标在 pagination_reply.next_offset；cursor.next 只是页码
      // 计数（如 2），不是游标
      final paginationReply =
          cursorJson?['pagination_reply'] as Map<String, dynamic>?;
      var next = (paginationReply?['next_offset'] as dynamic)?.toString() ?? '';
      if (next.isEmpty) {
        // 兼容旧版服务端：cursor.next 为大数时也作为游标使用
        final legacy = (cursorJson?['next'] as dynamic)?.toString() ?? '';
        if (legacy.isNotEmpty && (int.tryParse(legacy) ?? 0) > 10000000000) {
          next = legacy;
        }
      }
      final isEnd = _asBool(cursorJson?['is_end']) || next.isEmpty;
      final allCount = (cursorJson?['all_count'] as num?)?.toInt() ?? 0;

      lastErrorDetail = null;
      return BiliCommentPage(
        comments: comments,
        topReplies: topReplies,
        next: next,
        isEnd: isEnd,
        allCount: allCount,
      );
    } catch (e) {
      lastErrorDetail = L10n.current.commentException('$e');
      debugPrint('[Comment] 拉取主楼评论异常: $e');
      return null;
    }
  }

  /// 楼中楼（二级回复）分页拉取。
  static Future<BiliSubCommentPage?> fetchSubComments({
    required String cid,
    required String root,
    int page = 1,
    int pageSize = 20,
    String type = '1',
  }) async {
    try {
      final uri = Uri.parse(_subApi).replace(
        queryParameters: {
          'oid': cid.trim(),
          'type': type,
          'root': root,
          'pn': page.toString(),
          'ps': pageSize.toString(),
          'sort': '1',
        },
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = L10n.current.commentSubHttpError(resp.statusCode);
        debugPrint('[Comment] 楼中楼 HTTP ${resp.statusCode}');
        return null;
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']} (oid=$cid)';
        debugPrint('[Comment] 楼中楼 code=${json['code']} ${json['message']}');
        return null;
      }
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        lastErrorDetail = L10n.current.commentSubNoData;
        return null;
      }
      final pageJson = data['page'] as Map<String, dynamic>?;
      lastErrorDetail = null;
      return BiliSubCommentPage(
        replies: (data['replies'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(BiliComment.fromJson)
            .toList(),
        isEnd: _asBool(pageJson?['is_end']),
        total: (pageJson?['count'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      lastErrorDetail = L10n.current.commentSubException('$e');
      debugPrint('[Comment] 拉取楼中楼异常: $e');
      return null;
    }
  }

  /// 楼中楼拉取（跳过空页）。
  /// B 站 /x/v2/reply/reply 的 pn 分页在个别评论存在时可能返回空页或
  /// 直到拉到数据、is_end 或连续空页达到 [maxEmptyPages] 页为止。
  /// 返回实际拉到的页码与分页结果。
  static Future<({BiliSubCommentPage page, int fetchedPage})?>
  fetchSubCommentsSkipEmpty({
    required String cid,
    required String root,
    required int page,
    int pageSize = 20,
    int maxEmptyPages = 3,
    String type = '1',
  }) async {
    var current = page;
    for (var i = 0; i < maxEmptyPages; i++) {
      final result = await fetchSubComments(
        cid: cid,
        root: root,
        page: current,
        pageSize: pageSize,
        type: type,
      );
      if (result == null) return null;
      if (result.replies.isNotEmpty || result.isEnd) {
        return (page: result, fetchedPage: current);
      }
      current += 1;
    }
    return (
      page: const BiliSubCommentPage(replies: [], isEnd: false, total: 0),
      fetchedPage: current - 1,
    );
  }

  /// 头像地址（压缩到 96px，加速加载）。
  static String avatarUrl(String url, {int size = 96}) {
    if (url.isEmpty) return '';
    return '$url@${size}w_${size}h_1c.webp';
  }

  /// 表情地址（按渲染尺寸压缩，加速加载；gif 表情保留动图）。
  static String emoteUrl(String url, {int size = 64}) {
    if (url.isEmpty) return '';
    if (url.toLowerCase().endsWith('.gif')) return url;
    return '$url@${size}w_${size}h.webp';
  }

  /// 下载原始图片字节（评论区配图大图查看用）。
  ///
  /// 带本地磁盘缓存 + 并发去重（见 [ImageCacheService.fetch]）：
  ///   - 命中缓存（私有目录 image_cache）直接读本地文件，不再重复下载；
  ///   - 同一 URL 并发请求共享同一个下载 Future，连续点击只下载一次；
  ///   - 新下载的图片落盘到缓存，设置页「清理缓存」可一键清除。
  static Future<Uint8List?> fetchBytes(String url) {
    if (url.trim().isEmpty) return Future.value(null);
    return ImageCacheService.fetch(url, headers: _headers);
  }

  // ═════════════════════════════════════
  //  评论互动（点赞）
  // ═════════════════════════════════════

  /// 是否可发表互动（点赞等）：已登录且开启「携带 Cookie 请求」。
  static bool get canInteract =>
      BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.interactions,
      ) !=
      null;

  /// 点赞 / 取消点赞评论。
  /// [like] true = 点赞，false = 取消点赞。
  /// [type] 评论区类型（默认 '1' 视频；'12' 专栏文章）。
  /// 返回 (ok, message)：ok=true 成功；message 为失败原因（含服务端 code）。
  static Future<({bool ok, String message})> likeComment({
    required String oid,
    required String rpid,
    required bool like,
    String type = '1',
  }) async {
    final cookieHeader = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.interactions,
    );
    if (cookieHeader == null) {
      return (ok: false, message: L10n.current.commentNotLoggedIn);
    }
    final rawCookie = cookieHeader['Cookie'] ?? '';
    final csrf = _extractCookie(rawCookie, 'bili_jct');
    if (csrf.isEmpty) {
      return (ok: false, message: L10n.current.commentMissingJct);
    }
    // 补充 buvid3 设备指纹，降低风控拦截（-352）概率
    final buvid3 = _extractCookie(rawCookie, 'buvid3');
    final cookie = buvid3.isEmpty && _buvid3.isNotEmpty
        ? '$rawCookie; buvid3=$_buvid3'
        : rawCookie;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_actionApi),
            headers: {
              ..._defaultHeaders,
              ...cookieHeader,
              'Cookie': cookie,
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'type': type,
              'oid': oid,
              'rpid': rpid,
              'action': like ? '1' : '2',
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}');
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        final msg = L10n.current.commentApiError(
          json['message'] as String? ?? L10n.current.biliUnknownError,
          (json['code'] as num?)?.toInt() ?? 0,
        );
        debugPrint('[Comment] 点赞失败: $msg');
        return (ok: false, message: msg);
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[Comment] 点赞异常: $e');
      return (ok: false, message: L10n.current.commentNetworkError('$e'));
    }
  }

  static String _extractCookie(String cookie, String name) {
    final m = RegExp('(?:^|;\\s*)$name=([^;]+)').firstMatch(cookie);
    return m?.group(1) ?? '';
  }

  /// VideoHttp.replyAdd）。表情按 `[xxx]` 纯文本包含在 [message] 里；
  /// 回复一级评论时 root = parent = 该评论 rpid（楼中楼）。
  /// [pictures] 为已上传图片的元数据列表（`{img_width, img_height,
  /// img_size, img_src}`，见 [uploadCommentImage]；仅一级评论支持）。
  /// 成功返回服务端生成的评论（可直接插到列表顶部 / 楼中楼末尾），
  /// 解析失败但 code=0 时 comment 为 null（视为已发送）。
  static Future<({BiliComment? comment, String message})> sendComment({
    required int oid,
    required String message,
    int type = 1,
    int? root,
    int? parent,
    List<Map<String, dynamic>>? pictures,
  }) async {
    final cookieHeader = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.interactions,
    );
    if (cookieHeader == null) {
      return (comment: null, message: L10n.current.commentNotLoggedIn);
    }
    final rawCookie = cookieHeader['Cookie'] ?? '';
    final csrf = _extractCookie(rawCookie, 'bili_jct');
    if (csrf.isEmpty) {
      return (comment: null, message: L10n.current.commentMissingJct);
    }
    // 补充 buvid3 设备指纹，降低风控拦截（-352）概率
    final buvid3 = _extractCookie(rawCookie, 'buvid3');
    final cookie = buvid3.isEmpty && _buvid3.isNotEmpty
        ? '$rawCookie; buvid3=$_buvid3'
        : rawCookie;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(_replyAddApi),
            headers: {
              ..._defaultHeaders,
              ...cookieHeader,
              'Cookie': cookie,
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'type': type.toString(),
              'oid': oid.toString(),
              if (root != null && root != 0) 'root': root.toString(),
              if (parent != null && parent != 0) 'parent': parent.toString(),
              'message': message,
              if (pictures != null && pictures.isNotEmpty)
                'pictures': jsonEncode(pictures),
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (comment: null, message: 'HTTP ${resp.statusCode}');
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        final msg =
            (json['message'] as String? ?? L10n.current.biliUnknownError);
        debugPrint('[Comment] 发送评论失败: ${json['code']} $msg');
        return (comment: null, message: msg);
      }
      // code=0：解析服务端回传的新评论（失败不影响「已发送」）
      final reply = (json['data'] as Map<String, dynamic>?)?['reply'];
      BiliComment? comment;
      try {
        if (reply is Map<String, dynamic>) {
          comment = BiliComment.fromJson(reply);
        }
      } catch (e) {
        debugPrint('[Comment] 解析新评论失败（不影响发送结果）: $e');
      }
      return (comment: comment, message: '');
    } catch (e) {
      debugPrint('[Comment] 发送评论异常: $e');
      return (comment: null, message: L10n.current.commentNetworkError('$e'));
    }
  }

  /// 上传评论配图（POST /x/dynamic/feed/draw/upload_bfs，multipart：
  /// MsgHttp.uploadBfs）。返回图片元数据（可直接作为 sendComment 的
  /// pictures 条目）；未登录 / 失败返回 null。
  static Future<Map<String, dynamic>?> uploadCommentImage(
    Uint8List bytes,
  ) async {
    final cookieHeader = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.interactions,
    );
    if (cookieHeader == null) return null;
    final rawCookie = cookieHeader['Cookie'] ?? '';
    final csrf = _extractCookie(rawCookie, 'bili_jct');
    if (csrf.isEmpty) return null;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.bilibili.com/x/dynamic/feed/draw/upload_bfs'),
      )
        ..fields['category'] = 'daily'
        ..fields['biz'] = 'new_dyn'
        ..fields['csrf'] = csrf
        ..files.add(
          http.MultipartFile.fromBytes(
            'file_up',
            bytes,
            filename: 'image_${DateTime.now().millisecondsSinceEpoch}.png',
          ),
        );
      req.headers.addAll({..._defaultHeaders, ...cookieHeader});
      final streamed = await client
          .send(req)
          .timeout(const Duration(seconds: 30));
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode != 200) {
        debugPrint('[Comment] 上传图片 HTTP ${resp.statusCode}');
        return null;
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        debugPrint('[Comment] 上传图片失败: ${json['code']} ${json['message']}');
        return null;
      }
      final data = json['data'];
      if (data is! Map) return null;
      final url = (data['image_url'] as dynamic)?.toString() ?? '';
      if (url.isEmpty) return null;
      return {
        'img_width': (data['image_width'] as num?)?.toInt() ?? 0,
        'img_height': (data['image_height'] as num?)?.toInt() ?? 0,
        'img_size': (data['img_size'] as num?)?.toDouble() ?? 0.0,
        'img_src': url,
      };
    } catch (e) {
      debugPrint('[Comment] 上传图片异常: $e');
      return null;
    }
  }

  /// 拉取 B 站表情面板（GET /x/emote/user/panel/web?business=reply，
  /// 需登录 Cookie；会话级缓存）。未登录 / 失败返回 null。
  static Future<List<BiliEmotePackage>?> fetchEmotePanel() async {
    if (_emotePanelCache != null) return _emotePanelCache;
    final cookieHeader = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.interactions,
    );
    if (cookieHeader == null) return null;
    try {
      final uri = Uri.parse(_emotePanelApi).replace(
        queryParameters: {
          'business': 'reply',
          'web_location': '333.1245',
        },
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: {..._defaultHeaders, ...cookieHeader})
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        debugPrint(
          '[Comment] 表情面板失败: ${json['code']} ${json['message']}',
        );
        return null;
      }
      final packages = (json['data'] as Map<String, dynamic>?)?['packages'];
      if (packages is! List) return null;
      final result = packages
          .whereType<Map<String, dynamic>>()
          .map(BiliEmotePackage.fromJson)
          .where((p) => p.emotes.isNotEmpty)
          .toList();
      if (result.isEmpty) return null;
      _emotePanelCache = result;
      return result;
    } catch (e) {
      debugPrint('[Comment] 拉取表情面板异常: $e');
      return null;
    }
  }

  /// 判断 Cookie 是否包含 bili_jct（点赞/发评论等互动必需）。
  static bool hasBiliJct(String cookie) =>
      RegExp(r'(?:^|;\s*)bili_jct=([^;]+)').hasMatch(cookie);
}
