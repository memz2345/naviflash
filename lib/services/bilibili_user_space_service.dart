// lib/services/bilibili_user_space_service.dart
//
// 与 lib/utils/wbi_sign.dart 实现，按本项目风格精简为只读浏览）：
//   - 用户卡片：x/web-interface/card（昵称/头像/粉丝/关注/简介等，无需签名）
//   - 视频列表：x/space/wbi/arc/search（最新发布，需 WBI 签名）
// 请求方式与弹幕/评论 Fetcher 一致：复用 NetworkSettingsService 客户端与请求头。

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show Color;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/l10n_helper.dart';
import 'package:flutter/services.dart' show Uint8List;
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/image_cache_service.dart';
import 'package:naviflash/services/network_settings_service.dart';

// ═════════════════════════════════════════
//  安全解析工具（B 站接口字段类型不稳定：count 可能为 bool/字符串「1.2万」、
//  时长可能是 "MM:SS" 字符串等，统一安全转换避免类型强转崩溃）
// ═════════════════════════════════════════

Map<String, dynamic>? _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

int _toInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) {
    final t = v.trim();
    if (t.isEmpty) return 0;
    if (t.endsWith('万')) {
      return ((double.tryParse(t.substring(0, t.length - 1)) ?? 0) * 10000)
          .round();
    }
    return int.tryParse(t) ?? 0;
  }
  return 0;
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim()) ?? 0;
  return 0;
}

bool _toBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  return false;
}

/// 补全 B 站图片地址：
///   - `bfs/...` 相对路径（acc/info 的 top_photo 等空间图）→ https://i0.hdslb.com/bfs/...
///   - `//...` 无协议头（动态接口下发）→ https:...
String _normalizeUrl(String url) {
  if (url.isEmpty) return url;
  if (url.startsWith('bfs/')) return 'https://i0.hdslb.com/$url';
  if (url.startsWith('//')) return 'https:$url';
  return url;
}

/// 解析空间接口的时长字段：可能是秒数，也可能是 "MM:SS" / "H:MM:SS" 字符串。
int _toSeconds(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) {
    final parts = v.trim().split(':').map(int.tryParse).toList();
    if (parts.length == 3 &&
        parts[0] != null &&
        parts[1] != null &&
        parts[2] != null) {
      return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
    }
    if (parts.length == 2 && parts[0] != null && parts[1] != null) {
      return parts[0]! * 60 + parts[1]!;
    }
  }
  return 0;
}

// ═════════════════════════════════════════
//  模型：用户卡片
// ═════════════════════════════════════════

class BiliUserSpaceCard {
  final int mid;
  final String name;
  final String face;
  final String sign;
  final int level;
  final int vipType;
  final int vipStatus;
  final int officialType;
  final int fans; // 粉丝数
  final int following; // 关注数
  final int archiveCount; // 视频数
  final int likeNum; // 获赞数

  /// 空间背景图（card 接口无签名，稳定可拿；未设置装扮时为 B 站官方默认图）。
  final String topPhoto;

  /// 头像粉丝装扮挂件图（card.pendant.image，用户当前佩戴的装扮挂件，
  final String pendantImage;

  /// 粉丝装扮（fans_detail，仅登录且是目标 UP 的粉丝时服务端下发）。
  final BiliFansDetail? fansDetail;

  const BiliUserSpaceCard({
    required this.mid,
    required this.name,
    required this.face,
    required this.sign,
    required this.level,
    required this.vipType,
    required this.vipStatus,
    required this.officialType,
    required this.fans,
    required this.following,
    required this.archiveCount,
    required this.likeNum,
    required this.topPhoto,
    this.pendantImage = '',
    this.fansDetail,
  });

  factory BiliUserSpaceCard.fromJson(Map<String, dynamic> json) {
    final card = _asMap(json['card']);
    final vip = _asMap(card?['vip']);
    final official = _asMap(card?['official_verify']);
    final levelInfo = _asMap(card?['level_info']);
    final pendant = _asMap(card?['pendant']);
    final fansDetailJson = _asMap(card?['fans_detail']);
    return BiliUserSpaceCard(
      mid: _toInt(card?['mid']),
      name: (card?['name'] as String?) ?? '',
      face: (card?['face'] as String?) ?? '',
      sign: (card?['sign'] as String?) ?? '',
      level: _toInt(levelInfo?['current_level']),
      vipType: _toInt(vip?['vipType']),
      vipStatus: _toInt(vip?['vipStatus']),
      officialType: _toInt(official?['type']),
      // 粉丝数优先取 data.follower（card.follower 兜底）
      fans: _toInt(json['follower'] ?? card?['follower']),
      following: _toInt(card?['attention']),
      archiveCount: _toInt(json['archive_count']),
      likeNum: _toInt(json['like_num']),
      topPhoto: _normalizeUrl((card?['top_photo'] as String?) ?? ''),
      pendantImage: _normalizeUrl((pendant?['image'] as String?) ?? ''),
      fansDetail: fansDetailJson == null
          ? null
          : BiliFansDetail.fromJson(fansDetailJson),
    );
  }
}

/// 仅当请求携带登录 Cookie 且当前用户是目标 UP 的粉丝时服务端才会下发。
class BiliFansDetail {
  /// 粉丝编号（装扮上的 #NNN）。
  final int number;

  /// 粉丝装扮名（如「法外狂徒」）。
  final String medalName;

  /// 粉丝等级。
  final int level;

  /// 装扮主色（渐变起始）。
  final Color colorStart;

  /// 装扮渐变结束色。
  final Color colorEnd;

  /// 装扮边框色。
  final Color colorBorder;

  /// 装扮昵称/文字色。
  final Color nameColor;

  /// 是否点亮。
  final bool isLight;

  const BiliFansDetail({
    required this.number,
    required this.medalName,
    required this.level,
    required this.colorStart,
    required this.colorEnd,
    required this.colorBorder,
    required this.nameColor,
    required this.isLight,
  });

  factory BiliFansDetail.fromJson(Map<String, dynamic> json) {
    // 兼容两种下发格式：
    //   - 卡片接口 card.fans_detail（粉丝装扮）：
    //     color_start / color_end / color_border / name_color (+number 编号)
    //   - 评论区接口 member.fans_detail（粉丝勋章）：
    //     medal_color_start / medal_color_end / medal_color_border /
    //     medal_color_name（无 number，等级仍为 level）
    int color(List<String> keys) {
      for (final k in keys) {
        final v = _toInt(json[k]);
        if (v != 0) return v;
      }
      return 0;
    }

    return BiliFansDetail(
      number: _toInt(json['number']),
      medalName: (json['medal_name'] as String?) ?? '',
      level: _toInt(json['level']),
      colorStart: _colorFromInt(color(['medal_color_start', 'color_start'])),
      colorEnd: _colorFromInt(color(['medal_color_end', 'color_end'])),
      colorBorder: _colorFromInt(color(['medal_color_border', 'color_border'])),
      nameColor: _colorFromInt(
        color(['medal_color_name', 'color_name', 'name_color']),
      ),
      isLight: _toInt(json['is_light']) != 0,
    );
  }

  /// 十进制 RGB int → Color（0 或无值回退 B 站主题粉）。
  static Color _colorFromInt(int v) {
    if (v <= 0) return const Color(0xFFFB7299);
    return Color(0xFF000000 | v);
  }
}

// ═════════════════════════════════════════
//  模型：视频条目
// ═════════════════════════════════════════

class BiliUserVideo {
  final String bvid;
  final String title;
  final String pic;
  final String author;
  final int mid;
  final int play;
  final int danmaku;
  final int duration; // 秒
  final int created; // Unix 时间戳

  const BiliUserVideo({
    required this.bvid,
    required this.title,
    required this.pic,
    required this.author,
    required this.mid,
    required this.play,
    required this.danmaku,
    required this.duration,
    required this.created,
  });

  factory BiliUserVideo.fromJson(Map<String, dynamic> json) {
    return BiliUserVideo(
      bvid: (json['bvid'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      pic: (json['pic'] as String?) ?? '',
      author: (json['author'] as String?) ?? '',
      mid: _toInt(json['mid']),
      play: _toInt(json['play']),
      danmaku: _toInt(json['video_review']),
      // length 字段可能是 "MM:SS" / "H:MM:SS" 字符串，也可能是秒数
      duration: _toSeconds(json['length']),
      created: _toInt(json['created']),
    );
  }
}

class BiliUserVideoPage {
  final List<BiliUserVideo> videos;
  final int count; // 视频总数

  const BiliUserVideoPage({required this.videos, required this.count});
}

// ═════════════════════════════════════════
//  模型：用户动态条目
// ═════════════════════════════════════════

class BiliUserDynamic {
  final String idStr;
  final String type;
  final String title; // 标题（投稿/图文/直播等），纯文字动态时为空
  final String text; // 动态正文
  final String cover; // 封面色（投稿/专栏/直播封面；图文取首图）
  final int pubTs; // 发布时间（Unix 秒）
  final int like; // 点赞数
  final int comment; // 评论数
  final int forward; // 转发数

  /// 投稿视频动态（MAJOR_TYPE_ARCHIVE）的 bvid/aid；其他类型为空/0。
  final String bvid;
  final int aid;

  /// 图文动态的全部图片（MAJOR_TYPE_OPUS → opus.pics[].url，MAJOR_TYPE_DRAW → items[].src）。
  final List<String> images;

  /// 富文本节点（@ / 话题 / 表情 / 链接），供正文完整渲染。
  final List<BiliDynTextNode> textNodes;

  /// 动态话题（#xx#），无则为空串。
  final String topicName;
  final String topicUrl;

  /// 转发来源（DYNAMIC_TYPE_FORWARD），无转发则为 null。
  final BiliUserDynamic? orig;

  /// 作者信息（空间动态里即页面主人；转发来源元信息除外）。
  final String authorName;
  final String authorFace;
  final int authorMid;

  /// 投稿视频时长（如「12:34」）/ 播放量 / 弹幕数。
  final String durationText;
  final int play;
  final int danmaku;

  /// 专栏跳转地址（MAJOR_TYPE_ARTICLE）。
  final String articleUrl;

  /// 直播间号（MAJOR_TYPE_LIVE）。
  final int liveRoomId;

  /// 动态对应页面 URL：投稿视频跳视频页，其余跳动态详情页。
  String get actionUrl {
    if (bvid.isNotEmpty) return 'https://www.bilibili.com/video/$bvid';
    if (articleUrl.isNotEmpty) return articleUrl;
    if (liveRoomId > 0) return 'https://live.bilibili.com/$liveRoomId';
    if (idStr.isNotEmpty) return 'https://www.bilibili.com/opus/$idStr';
    return '';
  }

  /// 是否投稿视频动态。
  bool get isArchive => bvid.isNotEmpty || aid > 0;

  /// 是否含图片。
  bool get hasImages => images.isNotEmpty;

  const BiliUserDynamic({
    required this.idStr,
    required this.type,
    required this.title,
    required this.text,
    required this.cover,
    required this.pubTs,
    required this.like,
    required this.comment,
    required this.forward,
    required this.bvid,
    required this.aid,
    this.images = const [],
    this.textNodes = const [],
    this.topicName = '',
    this.topicUrl = '',
    this.orig,
    this.authorName = '',
    this.authorFace = '',
    this.authorMid = 0,
    this.durationText = '',
    this.play = 0,
    this.danmaku = 0,
    this.articleUrl = '',
    this.liveRoomId = 0,
  });

  /// 封面/标题按 major.type 分派：
  ///   - MAJOR_TYPE_ARCHIVE / UGC_SEASON / PGC → major.{archive,ugc_season,pgc}.cover/title；
  ///     补 duration_text / stat.play / stat.danmaku
  ///   - MAJOR_TYPE_OPUS → major.opus.pics[].url 全图 / title / summary.text（正文兜底）
  ///   - MAJOR_TYPE_DRAW → major.draw.items[].src 全图
  ///   - MAJOR_TYPE_ARTICLE → major.article.covers[] / title / jump_url
  ///   - MAJOR_TYPE_LIVE → major.live.cover / title / room_id
  /// 富文本节点取 desc.rich_text_nodes，空则回退 opus.summary.rich_text_nodes。
  /// module_stat 里的 count 字段可能是数字、bool 或字符串（如「1.2万」），
  /// 全部走安全解析，避免类型强转崩溃。
  factory BiliUserDynamic.fromJson(Map<String, dynamic> json) {
    final modules = _asMap(json['modules']) ?? const <String, dynamic>{};
    final moduleDynamic =
        _asMap(modules['module_dynamic']) ?? const <String, dynamic>{};
    final major = _asMap(moduleDynamic['major']) ?? const <String, dynamic>{};
    final majorType = (major['type'] as String?) ?? '';
    final desc = _asMap(moduleDynamic['desc']) ?? const <String, dynamic>{};
    final opus = _asMap(major['opus']);

    String title = '';
    String cover = '';
    String bvid = '';
    int aid = 0;
    String durationText = '';
    int play = 0;
    int danmaku = 0;
    String articleUrl = '';
    int liveRoomId = 0;
    final images = <String>[];

    switch (majorType) {
      case 'MAJOR_TYPE_ARCHIVE':
      case 'MAJOR_TYPE_UGC_SEASON':
      case 'MAJOR_TYPE_PGC':
        final sub =
            _asMap(
              major[majorType == 'MAJOR_TYPE_ARCHIVE'
                  ? 'archive'
                  : majorType == 'MAJOR_TYPE_UGC_SEASON'
                  ? 'ugc_season'
                  : 'pgc'],
            ) ??
            const <String, dynamic>{};
        title = (sub['title'] as String?) ?? '';
        cover = (sub['cover'] as String?) ?? '';
        // 投稿视频动态记录 bvid/aid，供跳转与兜底提取视频
        bvid = (sub['bvid'] as String?) ?? '';
        aid = _toInt(sub['aid']);
        durationText = (sub['duration_text'] as String?) ?? '';
        final subStat = _asMap(sub['stat']) ?? const <String, dynamic>{};
        play = _toInt(subStat['play']);
        danmaku = _toInt(subStat['danmaku']);
      case 'MAJOR_TYPE_OPUS':
        if (opus != null) {
          title = (opus['title'] as String?) ?? '';
          final pics = (opus['pics'] as List<dynamic>?) ?? const [];
          for (final p in pics) {
            final m = _asMap(p);
            if (m == null) continue;
            final u = (m['url'] as String?) ?? (m['src'] as String?) ?? '';
            if (u.isNotEmpty) images.add(_normalizeUrl(u));
          }
          if (title.isEmpty && images.isNotEmpty) {
            final summary =
                _asMap(opus['summary']) ?? const <String, dynamic>{};
            title = (summary['text'] as String?) ?? '';
          }
        }
      case 'MAJOR_TYPE_DRAW':
        final items =
            _asMap(major['draw'])?['items'] as List<dynamic>? ?? const [];
        for (final it in items) {
          final m = _asMap(it);
          if (m == null) continue;
          final u = (m['src'] as String?) ?? '';
          if (u.isNotEmpty) images.add(_normalizeUrl(u));
        }
      case 'MAJOR_TYPE_ARTICLE':
        final article = _asMap(major['article']) ?? const <String, dynamic>{};
        title = (article['title'] as String?) ?? '';
        final covers = (article['covers'] as List<dynamic>?) ?? const [];
        if (covers.isNotEmpty) cover = covers.first as String? ?? '';
        articleUrl = _normalizeUrl((article['jump_url'] as String?) ?? '');
        if (articleUrl.isEmpty) {
          final id = (article['id'] as String?) ?? '';
          if (id.isNotEmpty) articleUrl = 'https://www.bilibili.com/read/cv$id';
        }
      case 'MAJOR_TYPE_LIVE':
        final live = _asMap(major['live']) ?? const <String, dynamic>{};
        title = (live['title'] as String?) ?? '';
        cover = (live['cover'] as String?) ?? '';
        liveRoomId = _toInt(live['room_id']);
    }

    if (cover.isEmpty && images.isNotEmpty) cover = images.first;

    // 正文：desc.text 优先，空则回退 opus.summary.text（图文动态正文通常在此）。
    String text = (desc['text'] as String?) ?? '';
    if (text.isEmpty && opus != null) {
      final summary = _asMap(opus['summary']);
      if (summary != null) {
        text = (summary['text'] as String?) ?? '';
      }
    }

    // 富文本节点：desc.rich_text_nodes 优先，空则回退 opus.summary.rich_text_nodes。
    var textNodes = ((desc['rich_text_nodes'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BiliDynTextNode.fromJson)
        .toList();
    if (textNodes.isEmpty && opus != null) {
      final summary = _asMap(opus['summary']);
      if (summary != null) {
        textNodes = ((summary['rich_text_nodes'] as List<dynamic>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(BiliDynTextNode.fromJson)
            .toList();
      }
    }

    // module_stat 部分字段值可能是 bool / 非 Map（如 status 字段），
    // 只对 Map 形态的条目取 count，其余视为 0。
    final stat = _asMap(modules['module_stat']) ?? const <String, dynamic>{};
    int countOf(String key) {
      final entry = _asMap(stat[key]);
      if (entry == null) return 0;
      return _toInt(entry['count']);
    }

    final author =
        _asMap(modules['module_author']) ?? const <String, dynamic>{};
    final topic = _asMap(moduleDynamic['topic']);
    final topicId = (topic?['id'] as String?) ?? '';
    final origMap = _asMap(json['orig']);

    return BiliUserDynamic(
      idStr: (json['id_str'] as String?) ?? '',
      type: (json['type'] as String?) ?? majorType,
      title: title,
      text: text,
      cover: cover,
      pubTs: _toInt(author['pub_ts']),
      like: countOf('like'),
      comment: countOf('comment'),
      forward: countOf('forward'),
      bvid: bvid,
      aid: aid,
      images: images,
      textNodes: textNodes,
      topicName: (topic?['name'] as String?) ?? '',
      topicUrl: topicId.isNotEmpty
          ? 'https://www.bilibili.com/topic/$topicId'
          : '',
      orig: origMap == null ? null : BiliUserDynamic.fromJson(origMap),
      authorName: (author['name'] as String?) ?? '',
      authorFace: _normalizeUrl((author['face'] as String?) ?? ''),
      authorMid: _toInt(author['mid']),
      durationText: durationText,
      play: play,
      danmaku: danmaku,
      articleUrl: articleUrl,
      liveRoomId: liveRoomId,
    );
  }
}

class BiliUserDynamicPage {
  final List<BiliUserDynamic> items;
  final String offset; // 下一页游标（无更多时为 '-1'）
  final bool hasMore;

  const BiliUserDynamicPage({
    required this.items,
    required this.offset,
    required this.hasMore,
  });
}

// ═════════════════════════════════════════
//  模型：动态详情（x/polymer/web-dynamic/v1/detail）
// ═════════════════════════════════════════

/// 富文本节点（desc.rich_text_nodes），供动态详情正文渲染。
class BiliDynTextNode {
  final String type; // RICH_TEXT_NODE_TYPE_TEXT / AT / TOPIC / EMOJI / WEB ...
  final String text;
  final String rid; // AT → mid；TOPIC → 话题 id
  final String url; // 跳转地址
  final String? emojiUrl; // EMOJI 表情图

  const BiliDynTextNode({
    required this.type,
    required this.text,
    required this.rid,
    required this.url,
    this.emojiUrl,
  });

  factory BiliDynTextNode.fromJson(Map<String, dynamic> json) {
    final emoji = _asMap(json['emoji']);
    return BiliDynTextNode(
      type: (json['type'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
      rid: (json['rid'] as String?) ?? '',
      url: (json['jump_url'] as String?) ?? '',
      emojiUrl: _normalizeUrl((emoji?['url'] as String?) ?? ''),
    );
  }
}

class BiliDynamicDetail {
  final String idStr;
  final String type; // DYNAMIC_TYPE_AV / WORD / DRAW / FORWARD / ...
  final String text; // 正文（desc.text）
  final List<BiliDynTextNode> textNodes; // 富文本节点
  final List<String> images; // 全部图片（opus.pics / draw.items）

  /// 评论区 oid（basic.comment_id_str；缺省回退动态 id，动态默认 type=17）。
  final String commentIdStr;
  final int commentType;

  // 投稿视频 / 合集（MAJOR_TYPE_ARCHIVE 等）
  final String? archiveTitle;
  final String? archiveCover;
  final String? bvid;
  final int aid;
  final String? archiveDurationText;
  final int archivePlay;
  final int archiveDanmaku;

  // 专栏（MAJOR_TYPE_ARTICLE）
  final String? articleTitle;
  final String? articleUrl;

  // 直播（MAJOR_TYPE_LIVE）
  final String? liveTitle;
  final String? liveCover;
  final int liveRoomId;

  /// 转发来源（DYNAMIC_TYPE_FORWARD）
  final BiliDynamicDetail? orig;

  final String authorName;
  final String authorFace;
  final int authorMid;
  final int pubTs;
  final int likeCount;
  final int commentCount;
  final int forwardCount;

  const BiliDynamicDetail({
    required this.idStr,
    required this.type,
    required this.text,
    required this.textNodes,
    required this.images,
    this.commentIdStr = '',
    this.commentType = 0,
    this.archiveTitle,
    this.archiveCover,
    this.bvid,
    this.aid = 0,
    this.archiveDurationText,
    this.archivePlay = 0,
    this.archiveDanmaku = 0,
    this.articleTitle,
    this.articleUrl,
    this.liveTitle,
    this.liveCover,
    this.liveRoomId = 0,
    this.orig,
    required this.authorName,
    required this.authorFace,
    required this.authorMid,
    required this.pubTs,
    required this.likeCount,
    required this.commentCount,
    required this.forwardCount,
  });

  /// 动态在 B 站的可读地址。
  String get url => 'https://www.bilibili.com/opus/$idStr';

  bool get isArchive =>
      type == 'DYNAMIC_TYPE_AV' ||
      type == 'DYNAMIC_TYPE_UGC_SEASON' ||
      type == 'DYNAMIC_TYPE_PGC';
  bool get hasImages => images.isNotEmpty;

  factory BiliDynamicDetail.fromJson(Map<String, dynamic> json) {
    final modules = _asMap(json['modules']) ?? const <String, dynamic>{};
    final moduleDynamic =
        _asMap(modules['module_dynamic']) ?? const <String, dynamic>{};
    final major = _asMap(moduleDynamic['major']) ?? const <String, dynamic>{};
    final majorType = (major['type'] as String?) ?? '';
    final desc = _asMap(moduleDynamic['desc']) ?? const <String, dynamic>{};
    final author =
        _asMap(modules['module_author']) ?? const <String, dynamic>{};
    final stat = _asMap(modules['module_stat']) ?? const <String, dynamic>{};

    int countOf(String key) => _toInt(_asMap(stat[key])?['count']);

    final idStr = (json['id_str'] as String?) ?? '';
    final basic = _asMap(json['basic']);
    final commentIdStr =
        ((basic?['comment_id_str'] as String?) ?? '').isNotEmpty
        ? (basic?['comment_id_str'] as String?)!
        : idStr;
    final commentType = _toInt(basic?['comment_type']) > 0
        ? _toInt(basic?['comment_type'])
        : 17; // 17 = 动态/图文（opus）

    // 图片列表
    final images = <String>[];
    if (majorType == 'MAJOR_TYPE_OPUS') {
      final pics = (major['opus'] as Map<String, dynamic>?)?['pics'] as List?;
      for (final p in pics ?? const []) {
        final m = _asMap(p);
        if (m == null) continue;
        final u = (m['url'] as String?) ?? (m['src'] as String?) ?? '';
        if (u.isNotEmpty) images.add(_normalizeUrl(u));
      }
    } else if (majorType == 'MAJOR_TYPE_DRAW') {
      final items =
          _asMap(major['draw'])?['items'] as List<dynamic>? ?? const [];
      for (final it in items) {
        final m = _asMap(it);
        if (m == null) continue;
        final u = (m['src'] as String?) ?? '';
        if (u.isNotEmpty) images.add(_normalizeUrl(u));
      }
    }

    // 投稿视频 / 合集
    String? archiveTitle;
    String? archiveCover;
    String? bvid;
    int aid = 0;
    String? archiveDurationText;
    int archivePlay = 0;
    int archiveDanmaku = 0;
    if (majorType == 'MAJOR_TYPE_ARCHIVE' ||
        majorType == 'MAJOR_TYPE_UGC_SEASON' ||
        majorType == 'MAJOR_TYPE_PGC') {
      final sub =
          _asMap(
            major[majorType == 'MAJOR_TYPE_ARCHIVE'
                ? 'archive'
                : majorType == 'MAJOR_TYPE_UGC_SEASON'
                ? 'ugc_season'
                : 'pgc'],
          ) ??
          const <String, dynamic>{};
      archiveTitle = (sub['title'] as String?) ?? '';
      archiveCover = _normalizeUrl((sub['cover'] as String?) ?? '');
      bvid = (sub['bvid'] as String?) ?? '';
      aid = _toInt(sub['aid']);
      archiveDurationText = (sub['duration_text'] as String?) ?? '';
      final subStat = _asMap(sub['stat']) ?? const <String, dynamic>{};
      archivePlay = _toInt(subStat['play']);
      archiveDanmaku = _toInt(subStat['danmaku']);
    }

    // 专栏
    String? articleTitle;
    String? articleUrl;
    if (majorType == 'MAJOR_TYPE_ARTICLE') {
      final article = _asMap(major['article']) ?? const <String, dynamic>{};
      articleTitle = (article['title'] as String?) ?? '';
      articleUrl = (article['jump_url'] as String?) ?? '';
      if (articleUrl.isEmpty) {
        final id = (article['id'] as String?) ?? '';
        if (id.isNotEmpty) articleUrl = 'https://www.bilibili.com/read/cv$id';
      }
    }

    // 直播
    String? liveTitle;
    String? liveCover;
    int liveRoomId = 0;
    if (majorType == 'MAJOR_TYPE_LIVE') {
      final live = _asMap(major['live']) ?? const <String, dynamic>{};
      liveTitle = (live['title'] as String?) ?? '';
      liveCover = _normalizeUrl((live['cover'] as String?) ?? '');
      liveRoomId = _toInt(live['room_id']);
    }

    // 正文：desc.text 优先，空则回退 opus.summary.text（图文动态正文通常在此）。
    final opusMap = _asMap(major['opus']);
    String text = (desc['text'] as String?) ?? '';
    if (text.isEmpty && opusMap != null) {
      final summary = _asMap(opusMap['summary']);
      if (summary != null) {
        text = (summary['text'] as String?) ?? '';
      }
    }

    // 富文本节点：desc.rich_text_nodes 优先，空则回退 opus.summary。
    var textNodes = ((desc['rich_text_nodes'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BiliDynTextNode.fromJson)
        .toList();
    if (textNodes.isEmpty && opusMap != null) {
      final summary = _asMap(opusMap['summary']);
      if (summary != null) {
        textNodes = ((summary['rich_text_nodes'] as List<dynamic>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(BiliDynTextNode.fromJson)
            .toList();
      }
    }

    return BiliDynamicDetail(
      idStr: idStr,
      type: (json['type'] as String?) ?? majorType,
      text: text,
      textNodes: textNodes,
      images: images,
      commentIdStr: commentIdStr,
      commentType: commentType,
      archiveTitle: archiveTitle,
      archiveCover: archiveCover,
      bvid: bvid,
      aid: aid,
      archiveDurationText: archiveDurationText,
      archivePlay: archivePlay,
      archiveDanmaku: archiveDanmaku,
      articleTitle: articleTitle,
      articleUrl: articleUrl,
      liveTitle: liveTitle,
      liveCover: liveCover,
      liveRoomId: liveRoomId,
      orig: _asMap(json['orig']) == null
          ? null
          : BiliDynamicDetail.fromJson(_asMap(json['orig'])!),
      authorName: (author['name'] as String?) ?? '',
      authorFace: _normalizeUrl((author['face'] as String?) ?? ''),
      authorMid: _toInt(author['mid']),
      pubTs: _toInt(author['pub_ts']),
      likeCount: countOf('like'),
      commentCount: countOf('comment'),
      forwardCount: countOf('forward'),
    );
  }
}

// ═════════════════════════════════════════
//  模型：追番条目（x/space/bangumi/follow/list，type=1 番剧）
// ═════════════════════════════════════════

class BiliUserBangumi {
  final int seasonId;
  final int mediaId;
  final String title;
  final String cover;
  final String badge; // 角标（独家/完结等）
  final String seasonTypeName; // 番剧/电影/国创…
  final bool isFinish; // 是否完结
  final bool isStarted; // 是否开播
  final String newEpIndex; // 最新一话（如「更新至第12话」）
  final String newEpPubTime; // 最新一话更新时间
  final double ratingScore; // 评分（无则为 0）
  final int ratingCount; // 评分人数
  final String evaluate; // 简介
  final String subtitle; // 副标题
  final String progress; // 自己的观看进度（空串表示无）
  final String publishTime; // 开播时间
  final List<String> areas; // 制作地区

  const BiliUserBangumi({
    required this.seasonId,
    required this.mediaId,
    required this.title,
    required this.cover,
    required this.badge,
    required this.seasonTypeName,
    required this.isFinish,
    required this.isStarted,
    required this.newEpIndex,
    required this.newEpPubTime,
    required this.ratingScore,
    required this.ratingCount,
    required this.evaluate,
    required this.subtitle,
    required this.progress,
    required this.publishTime,
    required this.areas,
  });

  factory BiliUserBangumi.fromJson(Map<String, dynamic> json) {
    final newEp = _asMap(json['new_ep']);
    final rating = _asMap(json['rating']);
    final publish = _asMap(json['publish']);
    final areas = (json['areas'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((a) => (a['name'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    return BiliUserBangumi(
      seasonId: _toInt(json['season_id']),
      mediaId: _toInt(json['media_id']),
      title: (json['title'] as String?) ?? '',
      cover: (json['cover'] as String?) ?? '',
      badge: (json['badge'] as String?) ?? '',
      seasonTypeName: (json['season_type_name'] as String?) ?? '',
      isFinish: _toBool(json['is_finish']),
      isStarted: _toBool(json['is_started']),
      newEpIndex: (newEp?['index_show'] as String?) ?? '',
      newEpPubTime: (newEp?['pub_time'] as String?) ?? '',
      ratingScore: _toDouble(rating?['score']),
      ratingCount: _toInt(rating?['count']),
      evaluate: (json['evaluate'] as String?) ?? '',
      subtitle: (json['subtitle'] as String?) ?? '',
      progress: (json['progress'] as String?) ?? '',
      publishTime: (publish?['pub_time'] as String?) ?? '',
      areas: areas,
    );
  }
}

class BiliUserBangumiPage {
  final List<BiliUserBangumi> items;
  final int total;

  const BiliUserBangumiPage({required this.items, required this.total});
}

// ═════════════════════════════════════════
//  服务
// ═════════════════════════════════════════

abstract final class BilibiliUserSpaceService {
  static const String _cardApi =
      'https://api.bilibili.com/x/web-interface/card';
  static const String _videoApi =
      'https://api.bilibili.com/x/space/wbi/arc/search';
  static const String _dynamicApi =
      'https://api.bilibili.com/x/polymer/web-dynamic/v1/feed/space';
  static const String _dynamicDetailApi =
      'https://api.bilibili.com/x/polymer/web-dynamic/v1/detail';
  static const String _bangumiApi =
      'https://api.bilibili.com/x/space/bangumi/follow/list';
  static const String _accInfoApi =
      'https://api.bilibili.com/x/space/wbi/acc/info';
  static const String _navApi = 'https://api.bilibili.com/x/web-interface/nav';
  static const String _spiApi =
      'https://api.bilibili.com/x/frontend/finger/spi';

  static const String _dynFeatures =
      'itemOpusStyle,listOnlyfans,onlyfansQaCard';

  /// 最近一次失败的具体原因（供界面展示，便于诊断），成功时清空。
  static String? lastErrorDetail;

  /// 随机生成 buvid3（spi 接口取真实指纹失败时的兜底，与评论区服务同款格式）。
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

  static String _randB64(int n) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final r = Random();
    return List.generate(n, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://space.bilibili.com',
  };

  /// 设备指纹（buvid3/buvid4）：优先从 spi 接口取服务端下发的真实值，
  /// 会话内缓存；失败时回退随机生成。真实指纹 + b_nut/b_lsid 可显著
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
      debugPrint('[UserSpace] 获取设备指纹失败: $e');
    }
  }

  /// 随机 b_lsid（浏览器同款 16 位十六进制 + 下划线 + 8 位十六进制）。
  static String _genBLsid() {
    const chars = '0123456789abcdef';
    final r = Random();
    String hex(int n) =>
        List.generate(n, (_) => chars[r.nextInt(chars.length)]).join();
    return '${hex(16)}_${hex(8)}';
  }

  /// 拼装请求 Cookie：设备指纹（buvid3/buvid4/b_nut/b_lsid）
  /// + 登录 Cookie（用户开启「携带 Cookie 请求」时，优先级最高）。
  static Future<String> _buildCookie() async {
    await _ensureDeviceFp();
    final parts = <String>[
      'buvid3=${_spiBuvid3 ?? _genBuvid3()}',
      if (_spiBuvid4?.isNotEmpty ?? false) 'buvid4=$_spiBuvid4',
      'b_nut=${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
      'b_lsid=${_genBLsid()}',
    ];
    final accountCookie = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.userSpace,
    )?['Cookie'];
    if (accountCookie != null && accountCookie.isNotEmpty) {
      parts.insert(0, accountCookie);
    }
    return parts.join('; ');
  }

  /// 请求头（设备指纹 Cookie + 登录 Cookie + 用户自定义 UA/Referer）。
  static Future<Map<String, String>> _buildHeaders({
    String referer = 'https://space.bilibili.com',
    bool withOrigin = false,
  }) async {
    final cookie = await _buildCookie();
    return {
      ..._defaultHeaders,
      'Referer': referer,
      'Cookie': cookie,
      if (withOrigin) 'Origin': 'https://space.bilibili.com',
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  // ═════════════════════════════════════
  //  用户卡片
  // ═════════════════════════════════════

  /// 拉取 UP 主卡片信息（昵称/头像/简介/粉丝/关注/视频数/获赞数等）。
  static Future<BiliUserSpaceCard?> fetchUserCard({required int mid}) async {
    try {
      if (mid <= 0) {
        lastErrorDetail = L10n.current.userSpaceMidInvalid;
        return null;
      }
      final uri = Uri.parse(
        _cardApi,
      ).replace(queryParameters: {'mid': mid.toString(), 'photo': 'true'});
      final client = await NetworkSettingsService.instance.getApiClient();
      final headers = await _buildHeaders();
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[UserSpace] HTTP ${resp.statusCode}');
        return null;
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']} (mid=$mid)';
        debugPrint('[UserSpace] card code=${json['code']} ${json['message']}');
        return null;
      }
      final data = _asMap(json['data']);
      if (data == null || data['card'] == null) {
        lastErrorDetail = L10n.current.userSpaceNoCard;
        return null;
      }
      lastErrorDetail = null;
      return BiliUserSpaceCard.fromJson(data);
    } catch (e) {
      lastErrorDetail = L10n.current.commentException('$e');
      debugPrint('[UserSpace] 拉取用户卡片异常: $e');
      return null;
    }
  }

  // ═════════════════════════════════════
  //  视频列表（WBI 签名）
  // ═════════════════════════════════════

  /// 拉取 UP 主视频列表（按最新发布排序，一页 30 条）。
  /// 优先走 WBI 签名接口；失败时回退旧版 x/space/arc/search。
  static Future<BiliUserVideoPage?> fetchUserVideos({
    required int mid,
    int pn = 1,
    int ps = 30,
  }) async {
    try {
      if (mid <= 0) {
        lastErrorDetail = L10n.current.userSpaceMidInvalid;
        return null;
      }
      final params = await WbiSign.sign({
        'mid': mid.toString(),
        'order': 'pubdate',
        'pn': pn.toString(),
        'ps': ps.toString(),
        'tid': '0',
        'platform': 'web',
        'web_location': '333.1387',
        'order_avoided': 'true',
        'dm_img_list': '[]',
        'dm_img_str': _randB64(64),
        'dm_cover_img_str': _randB64(128),
        'dm_img_inter': '{"ds":[],"wh":[0,0,0],"of":[0,0,0]}',
      });
      final uri = Uri.parse(_videoApi).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final headers = await _buildHeaders(
        referer: 'https://space.bilibili.com/$mid/video',
        withOrigin: true,
      );
      var resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      var json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> ||
          (json['code'] != 0 && json['code'] != 200)) {
        // 回退旧版接口（无需 WBI 签名，个别网络环境可通过；
        // 补上 platform 等参数避免被风控截断）
        final legacyUri =
            Uri.parse('https://api.bilibili.com/x/space/arc/search').replace(
              queryParameters: {
                'mid': mid.toString(),
                'order': 'pubdate',
                'pn': pn.toString(),
                'ps': ps.toString(),
                'tid': '0',
                'platform': 'web',
                'web_location': '333.1387',
              },
            );
        try {
          final legacyResp = await client
              .get(legacyUri, headers: headers)
              .timeout(const Duration(seconds: 15));
          if (legacyResp.statusCode == 200) {
            final legacyJson = jsonDecode(utf8.decode(legacyResp.bodyBytes));
            if (legacyJson is Map<String, dynamic>) {
              resp = legacyResp;
              json = legacyJson;
            }
          }
        } catch (e) {
          debugPrint('[UserSpace] 回退旧版接口失败: $e');
        }
      }
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[UserSpace] HTTP ${resp.statusCode}');
        return null;
      }
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']} (mid=$mid)';
        debugPrint('[UserSpace] video code=${json['code']} ${json['message']}');
        return null;
      }
      final data = _asMap(json['data']);
      if (data == null || data['list'] == null) {
        lastErrorDetail = L10n.current.userSpaceNoList;
        return null;
      }
      // Web 版接口为 data.list.vlist；部分接口形态直接返回 List
      final list = _asMap(data['list']);
      final rawList =
          list?['vlist'] as List<dynamic>? ?? (data['list'] as List<dynamic>?);
      final page = _asMap(data['page']);
      lastErrorDetail = null;
      return BiliUserVideoPage(
        videos: (rawList ?? [])
            .whereType<Map<String, dynamic>>()
            .map(BiliUserVideo.fromJson)
            .toList(),
        count: _toInt(page?['count']),
      );
    } catch (e) {
      lastErrorDetail = L10n.current.commentException('$e');
      debugPrint('[UserSpace] 拉取视频列表异常: $e');
      return null;
    }
  }

  // ═════════════════════════════════════
  //  空间内视频搜索（x/v2/space/archive/search）
  // ═════════════════════════════════════

  /// 与站内 `/x/v2/space/archive/search` 接口）：返回 [BiliUserVideoPage]。
  /// 失败时返回 null（[lastErrorDetail] 记录原因）。
  static Future<BiliUserVideoPage?> searchUserVideos({
    required int mid,
    required String keyword,
    int pn = 1,
    int ps = 20,
  }) async {
    final trimmed = keyword.trim();
    if (mid <= 0) {
      lastErrorDetail = L10n.current.userSpaceMidInvalid;
      return null;
    }
    if (trimmed.isEmpty) {
      lastErrorDetail = L10n.current.searchKeywordEmpty;
      return null;
    }
    try {
      final params = await WbiSign.sign({
        'mid': mid.toString(),
        'keyword': trimmed,
        'pn': pn.toString(),
        'ps': ps.toString(),
        'order': 'pubdate',
        'tid': '0',
        'search_type': 'video',
        'scope': '0',
        'platform': 'web',
        'web_location': '333.1387',
        // 与 fetchUserVideos 一致的风控参数
        'order_avoided': 'true',
        'dm_img_list': '[]',
        'dm_img_str': _randB64(64),
        'dm_cover_img_str': _randB64(128),
        'dm_img_inter': '{"ds":[],"wh":[0,0,0],"of":[0,0,0]}',
      });
      final uri = Uri.parse(
        'https://api.bilibili.com/x/v2/space/archive/search',
      ).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final headers = await _buildHeaders(
        referer: 'https://space.bilibili.com/$mid/search/video',
        withOrigin: true,
      );
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[UserSpace] search HTTP ${resp.statusCode}');
        return null;
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> ||
          (json['code'] != 0 && json['code'] != 200)) {
        lastErrorDetail = 'code=${json['code'] ?? '?'} ${json['message']}';
        debugPrint(
          '[UserSpace] search code=${json['code']} ${json['message']}',
        );
        return null;
      }
      final data = _asMap(json['data']);
      if (data == null) {
        lastErrorDetail = L10n.current.biliResponseNoData;
        return null;
      }
      final rawList = (data['list'] as List<dynamic>?) ?? const [];
      lastErrorDetail = null;
      return BiliUserVideoPage(
        videos: rawList
            .whereType<Map<String, dynamic>>()
            .map(BiliUserVideo.fromJson)
            .toList(),
        count: _toInt(data['count']),
      );
    } catch (e) {
      lastErrorDetail = L10n.current.commentException('$e');
      debugPrint('[UserSpace] 空间视频搜索异常: $e');
      return null;
    }
  }

  // ═════════════════════════════════════
  //  空间横幅
  // ═════════════════════════════════════

  /// x/space/wbi/acc/info 的 images.imgUrl / images.night_imgurl）。
  /// 未设置自定义横幅的用户，服务端会下发官方默认图（深色浅色各一张）。
  static Future<({String light, String dark})?> fetchUserBanner({
    required int mid,
  }) async {
    try {
      if (mid <= 0) return null;

      final params = await WbiSign.sign({
        'mid': mid.toString(),
        'token': '',
        'platform': 'web',
        'web_location': '1550101',
        'dm_img_list': '[]',
        'dm_img_str': _randB64(64),
        'dm_cover_img_str': _randB64(128),
        'dm_img_inter': '{"ds":[],"wh":[0,0,0],"of":[0,0,0]}',
      });
      final uri = Uri.parse(_accInfoApi).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final headers = await _buildHeaders(
        referer: 'https://space.bilibili.com/$mid',
        withOrigin: true,
      );
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        debugPrint(
          '[UserSpace] banner code=${json['code']} ${json['message']}',
        );
        return null;
      }
      final data = _asMap(json['data']);
      final images = _asMap(data?['images']);
      // 注意：当前 acc/info 接口 images 通常为 null（B 站已调整），
      // 只有 data.top_photo（相对路径 bfs/...，需补全协议头）可用，
      // 未设置装扮时即为官方默认背景图。
      final light = _normalizeUrl((images?['imgUrl'] as String?) ?? '');
      final dark = _normalizeUrl((images?['night_imgurl'] as String?) ?? '');
      // images 为空时（接口未下发）回退 data.top_photo
      if (light.isEmpty && dark.isEmpty) {
        final top = _normalizeUrl((data?['top_photo'] as String?) ?? '');
        if (top.isEmpty) return null;
        return (light: top, dark: top);
      }
      return (
        light: light.isNotEmpty ? light : dark,
        dark: dark.isNotEmpty ? dark : light,
      );
    } catch (e) {
      debugPrint('[UserSpace] 拉取空间横幅异常: $e');
      return null;
    }
  }

  // ═════════════════════════════════════
  //  用户动态（WBI 签名）
  // ═════════════════════════════════════

  /// x/polymer/web-dynamic/v1/feed/space，含 WBI 签名与风控参数）。
  /// 聚合全部动态返回（避免只显示一页 ~20 条导致数量偏少）。
  /// 单次最多翻 [maxPages] 页（默认 30，约 600 条）防止异常时请求过多。
  static Future<BiliUserDynamicPage?> fetchUserDynamics({
    required int mid,
    String offset = '',
    int maxPages = 30,
  }) async {
    try {
      if (mid <= 0) {
        lastErrorDetail = L10n.current.userSpaceMidInvalid;
        return null;
      }
      final client = await NetworkSettingsService.instance.getApiClient();
      final allItems = <BiliUserDynamic>[];
      var cursor = offset;
      var hasMore = true;
      String? firstError;
      final seen = <String>{};

      for (var i = 0; i < maxPages && hasMore; i++) {
        final params = await WbiSign.sign({
          'offset': cursor,
          'host_mid': mid.toString(),
          'timezone_offset': '-480',
          'features': _dynFeatures,
          'platform': 'web',
          'web_location': '333.1387',
          'dm_img_list': '[]',
          'dm_img_str': _randB64(64),
          'dm_cover_img_str': _randB64(128),
          'dm_img_inter': '{"ds":[],"wh":[0,0,0],"of":[0,0,0]}',
          'x-bili-device-req-json':
              '{"platform":"web","device":"pc","spmid":"333.1387"}',
        });
        final uri = Uri.parse(_dynamicApi).replace(queryParameters: params);
        final headers = await _buildHeaders(
          referer: 'https://space.bilibili.com/$mid/dynamic',
          withOrigin: true,
        );
        final resp = await client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 15));
        if (resp.statusCode != 200) {
          firstError = 'HTTP ${resp.statusCode}';
          debugPrint('[UserSpace] dyn HTTP ${resp.statusCode}');
          break;
        }
        final json = jsonDecode(utf8.decode(resp.bodyBytes));
        if (json['code'] != 0) {
          firstError = 'code=${json['code']} ${json['message']} (mid=$mid)';
          debugPrint('[UserSpace] dyn code=${json['code']} ${json['message']}');
          break;
        }
        final data = _asMap(json['data']);
        if (data == null) {
          firstError = L10n.current.biliResponseNoData;
          break;
        }
        final pageItems = (data['items'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(BiliUserDynamic.fromJson)
            .where((e) => e.idStr.isNotEmpty && seen.add(e.idStr))
            .toList();
        allItems.addAll(pageItems);
        final next = (data['offset'] as String?) ?? '';
        hasMore = _toBool(data['has_more']) && next.isNotEmpty;
        // 游标没前进说明没有更多，避免死循环
        if (next.isEmpty || next == cursor) break;
        cursor = next;
      }

      if (allItems.isEmpty && firstError != null) {
        lastErrorDetail = firstError;
        return null;
      }
      lastErrorDetail = null;
      return BiliUserDynamicPage(items: allItems, offset: '', hasMore: false);
    } catch (e) {
      lastErrorDetail = L10n.current.commentException('$e');
      debugPrint('[UserSpace] 拉取动态列表异常: $e');
      return null;
    }
  }

  /// 拉取单条动态详情（x/polymer/web-dynamic/v1/detail）。
  ///
  /// 带本地缓存（[DynamicDetailCache]）：TTL 内直接读缓存渲染、不再请求网络；
  /// 网络失败 / 数据异常时回退缓存（即使过期）保证离线可看；
  /// 设置页「清理缓存」可一键清除。
  static Future<BiliDynamicDetail?> fetchDynamicDetail({
    required String id,
  }) async {
    if (id.isEmpty) {
      lastErrorDetail = L10n.current.biliResponseNoData;
      return null;
    }
    // ① 缓存命中（TTL 内）：直接读本地渲染，不请求网络
    final cachedItem = await DynamicDetailCache.load(id);
    if (cachedItem != null) {
      debugPrint('[UserSpace] dynDetail 命中缓存: $id');
      lastErrorDetail = null;
      return BiliDynamicDetail.fromJson(cachedItem);
    }
    // ② 网络拉取，成功后落盘缓存
    Map<String, dynamic>? item;
    String? netError;
    try {
      final params = <String, String>{
        'timezone_offset': '-480',
        'id': id,
        'features': _dynFeatures,
        'gaia_source': 'Athena',
        'web_location': '333.1330',
        'x-bili-device-req-json':
            '{"platform":"web","device":"pc","spmid":"333.1330"}',
      };
      final uri = Uri.parse(_dynamicDetailApi).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final headers = await _buildHeaders(
        referer: 'https://www.bilibili.com',
        withOrigin: true,
      );
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        netError = 'HTTP ${resp.statusCode}';
        debugPrint('[UserSpace] dynDetail HTTP ${resp.statusCode}');
      } else {
        final json = jsonDecode(utf8.decode(resp.bodyBytes));
        if (json['code'] != 0) {
          netError = 'code=${json['code']} ${json['message']}';
          debugPrint('[UserSpace] dynDetail code=${json['code']}');
        } else {
          final data = _asMap(json['data']);
          item = _asMap(data?['item']);
        }
      }
    } catch (e) {
      netError = L10n.current.commentException('$e');
      debugPrint('[UserSpace] 拉取动态详情异常: $e');
    }
    if (item != null) {
      lastErrorDetail = null;
      // 落盘缓存，下次直接读本地
      await DynamicDetailCache.save(id, item);
      return BiliDynamicDetail.fromJson(item);
    }
    // ③ 网络失败 / 数据异常：回退缓存（即使过期），保证离线可看
    final stale = await DynamicDetailCache.load(id, allowStale: true);
    if (stale != null) {
      lastErrorDetail = null;
      return BiliDynamicDetail.fromJson(stale);
    }
    lastErrorDetail = netError ?? L10n.current.biliResponseNoData;
    return null;
  }

  // ═════════════════════════════════════
  //  图片
  // ═════════════════════════════════════

  /// 头像地址（压缩到 96px，加速加载）。
  static String avatarUrl(String url, {int size = 96}) {
    if (url.isEmpty) return '';
    return '${_normalizeUrl(url)}@${size}w_${size}h_1c.webp';
  }

  /// 封面地址（压缩到 320x200，加速加载）。
  static String coverUrl(String url) {
    if (url.isEmpty) return '';
    return '${_normalizeUrl(url)}@320w_200h_1c.webp';
  }

  /// 追番封面地址（竖版 3:4，480x640，按显示比例裁剪）。
  /// 不要用 [coverUrl] 的 16:10 压缩：竖版封面会被裁剪成横向后
  static String bangumiCoverUrl(String url) {
    if (url.isEmpty) return '';
    return '${_normalizeUrl(url)}@480w_640h_1c.webp';
  }

  /// 下载图片原始字节（大图查看器用）。
  ///
  /// 带本地磁盘缓存 + 并发去重：命中私有目录缓存直接读本地文件；
  /// 同一 URL 并发共享同一下载；新图片落盘，设置页「清理缓存」可清除。
  static Future<Uint8List?> fetchBytes(String url) {
    if (url.trim().isEmpty) return Future.value(null);
    final pending = _pendingBytes[url];
    if (pending != null) return pending;
    final future = _fetchBytesImpl(url);
    _pendingBytes[url] = future;
    future.whenComplete(() => _pendingBytes.remove(url));
    return future;
  }

  static final Map<String, Future<Uint8List?>> _pendingBytes = {};

  static Future<Uint8List?> _fetchBytesImpl(String url) async {
    try {
      final cached = await ImageCacheService.load(url);
      if (cached != null) {
        Uint8List? bytes;
        try {
          bytes = await cached.readAsBytes();
        } catch (_) {}
        if (bytes != null) return bytes;
      }
      final client = await NetworkSettingsService.instance.getApiClient();
      final headers = await _buildHeaders();
      final resp = await client
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return null;
      final bytes = resp.bodyBytes;
      await ImageCacheService.save(url, bytes);
      return bytes;
    } catch (e) {
      debugPrint('[UserSpace] 下载图片失败: $e');
      return null;
    }
  }

  // ═════════════════════════════════════
  //  追番列表（x/space/bangumi/follow/list）
  // ═════════════════════════════════════

  /// 拉取用户的追番列表（type=1 番剧；type=2 为追剧）。
  /// 公开列表游客可读；私密列表需登录且开启「携带 Cookie 请求」。
  static Future<BiliUserBangumiPage?> fetchUserBangumi({
    required int mid,
    int type = 1,
    int pn = 1,
    int ps = 30,
  }) async {
    try {
      if (mid <= 0) {
        lastErrorDetail = L10n.current.userSpaceMidInvalid;
        return null;
      }
      final uri = Uri.parse(_bangumiApi).replace(
        queryParameters: {
          'mid': mid.toString(),
          'vmid': mid.toString(),
          'type': type.toString(),
          'pn': pn.toString(),
          'ps': ps.toString(),
          'order': 'pubdate',
        },
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final headers = await _buildHeaders(
        referer: 'https://space.bilibili.com/$mid/bangumi',
        withOrigin: true,
      );
      final resp = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[UserSpace] bangumi HTTP ${resp.statusCode}');
        return null;
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorDetail = 'code=${json['code']} ${json['message']} (mid=$mid)';
        debugPrint(
          '[UserSpace] bangumi code=${json['code']} ${json['message']}',
        );
        return null;
      }
      final data = _asMap(json['data']);
      if (data == null) {
        lastErrorDetail = L10n.current.biliResponseNoData;
        return null;
      }
      lastErrorDetail = null;
      return BiliUserBangumiPage(
        items: (data['list'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(BiliUserBangumi.fromJson)
            .toList(),
        total: _toInt(data['total']),
      );
    } catch (e) {
      lastErrorDetail = L10n.current.commentException('$e');
      debugPrint('[UserSpace] 拉取追番列表异常: $e');
      return null;
    }
  }
}

// ═════════════════════════════════════════
// ═════════════════════════════════════════
//
// x/space/wbi/arc/search 等接口要求 w_rid + wts 参数：
// 从 x/web-interface/nav 的 wbi_img 取 img_key/sub_key 拼出 mixinKey，
// 对参数按 key 排序拼串后 md5 生成 w_rid。密钥每天更换，按天缓存。

abstract final class WbiSign {
  static const List<int> _mixinKeyEncTab = [
    46,
    47,
    18,
    2,
    53,
    8,
    23,
    32,
    15,
    50,
    10,
    31,
    58,
    3,
    45,
    35,
    27,
    43,
    5,
    49,
    33,
    9,
    42,
    19,
    29,
    28,
    14,
    39,
    12,
    38,
    41,
    13,
  ];
  static final RegExp _chrFilter = RegExp(r"[!'\(\)\*]");

  static String? _mixinKey;
  static DateTime? _keyDate;

  static String _getMixinKey(String orig) {
    final codeUnits = orig.codeUnits;
    return String.fromCharCodes(_mixinKeyEncTab.map((i) => codeUnits[i]));
  }

  /// 获取当天 mixinKey（nav 接口无鉴权要求，游客可读）。
  static Future<String> _fetchMixinKey() async {
    final client = await NetworkSettingsService.instance.getApiClient();
    final resp = await client
        .get(
          Uri.parse(BilibiliUserSpaceService._navApi),
          headers: {
            ...BilibiliUserSpaceService._defaultHeaders,
            'Cookie': await BilibiliUserSpaceService._buildCookie(),
          },
        )
        .timeout(const Duration(seconds: 15));
    final json = jsonDecode(utf8.decode(resp.bodyBytes));
    final wbiImg =
        (json['data'] as Map<String, dynamic>?)?['wbi_img']
            as Map<String, dynamic>?;
    final img = (wbiImg?['img_url'] as String?) ?? '';
    final sub = (wbiImg?['sub_url'] as String?) ?? '';
    if (img.isEmpty || sub.isEmpty) return '';
    String fileName(String url) {
      final name = url.split('/').last;
      final dot = name.lastIndexOf('.');
      return dot > 0 ? name.substring(0, dot) : name;
    }

    return _getMixinKey(fileName(img) + fileName(sub));
  }

  static Future<String> _mixinKeyOfToday() async {
    final today = DateTime.now();
    final cached = _mixinKey;
    if (cached != null &&
        _keyDate != null &&
        _keyDate!.year == today.year &&
        _keyDate!.month == today.month &&
        _keyDate!.day == today.day) {
      return cached;
    }
    final key = await _fetchMixinKey();
    if (key.isEmpty) return cached ?? '';
    _mixinKey = key;
    _keyDate = today;
    return key;
  }

  /// 为参数附加 wts / w_rid 签名。
  static Future<Map<String, String>> sign(Map<String, String> params) async {
    final mixinKey = await _mixinKeyOfToday();
    if (mixinKey.isEmpty) return params;
    final all = <String, String>{
      ...params,
      'wts': '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
    };
    final keys = all.keys.toList()..sort();
    final query = keys
        .map(
          (k) =>
              '${Uri.encodeComponent(k)}='
              '${Uri.encodeComponent((all[k] ?? '').replaceAll(_chrFilter, ''))}',
        )
        .join('&');
    final wRid = md5.convert(utf8.encode('$query$mixinKey')).toString();
    return {...all, 'w_rid': wRid};
  }
}

// ═════════════════════════════════════════
//  动态详情本地缓存
// ═════════════════════════════════════════

/// 动态详情缓存：拉取到的单条动态原始 JSON 落盘到应用私有目录
/// （<文档目录>/dynamic_detail_cache），下次查看直接读本地、不重新请求；
/// 设置页「清理缓存」可一键清除。
class DynamicDetailCache {
  static const String cacheDirName = 'dynamic_detail_cache';

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

  /// 动态 id → 缓存文件名（md5）。
  static String cacheKey(String id) =>
      md5.convert(utf8.encode(id.trim())).toString();

  static Future<File> _cacheFile(String id) async {
    final dir = await cacheDir;
    return File('${dir.path}/${cacheKey(id)}.json');
  }

  /// 保存动态原始 JSON 到缓存（含时间戳用于 TTL 判断）。
  static Future<void> save(String id, Map<String, dynamic> item) async {
    try {
      final file = await _cacheFile(id);
      await file.writeAsString(
        jsonEncode({'ts': DateTime.now().millisecondsSinceEpoch, 'item': item}),
        flush: true,
      );
      await _evictOldEntries();
    } catch (e) {
      debugPrint('[DynamicDetailCache] 写入缓存失败: $e');
    }
  }

  /// 读取缓存；[allowStale] 为 true 时即使过期也返回（网络失败回退用）。
  static Future<Map<String, dynamic>?> load(
    String id, {
    bool allowStale = false,
  }) async {
    try {
      final file = await _cacheFile(id);
      if (!await file.exists()) return null;
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map<String, dynamic>) return null;
      final ts = (raw['ts'] as num?)?.toInt() ?? 0;
      final item = raw['item'];
      if (item is! Map<String, dynamic>) return null;
      final fresh =
          DateTime.now().millisecondsSinceEpoch - ts < ttl.inMilliseconds;
      if (!fresh && !allowStale) return null;
      return item;
    } catch (e) {
      debugPrint('[DynamicDetailCache] 读取缓存失败: $e');
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

  /// 清空所有动态详情缓存。
  static Future<void> clearAll() async {
    try {
      final dir = await cacheDir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// 列出全部已缓存动态（读文件内容提取 id/作者/正文，供透明查看页）。
  static Future<List<DynamicCacheEntry>> listEntries() async {
    try {
      final dir = await cacheDir;
      if (!await dir.exists()) return const [];
      final entries = <DynamicCacheEntry>[];
      await for (final entity in dir.list()) {
        if (entity is! File || !entity.path.endsWith('.json')) continue;
        try {
          final raw = jsonDecode(await entity.readAsString());
          final item = (raw is Map<String, dynamic>) ? raw['item'] : null;
          if (item is! Map<String, dynamic>) continue;
          String id = (item['id_str'] as String?) ?? '';
          if (id.isEmpty) {
            id = entity.uri.pathSegments.last.replaceAll('.json', '');
          }
          // 作者 + 正文（供列表展示）
          final modules = _asMap(item['modules']) ?? const <String, dynamic>{};
          final author = _asMap(modules['module_author']);
          final moduleDynamic = _asMap(modules['module_dynamic']);
          final desc = _asMap(moduleDynamic?['desc']);
          var text = (desc?['text'] as String?) ?? '';
          if (text.isEmpty) {
            final opus = _asMap(_asMap(moduleDynamic?['major'])?['opus']);
            final summary = _asMap(opus?['summary']);
            text = (summary?['text'] as String?) ?? '';
          }
          var bytes = 0;
          var savedAt = DateTime.fromMillisecondsSinceEpoch(0);
          try {
            bytes = await entity.length();
            savedAt = await entity.lastModified();
          } catch (_) {}
          entries.add(
            DynamicCacheEntry(
              id: id,
              author: (author?['name'] as String?) ?? '',
              text: text,
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

  /// 删除单条动态详情缓存。
  static Future<void> deleteOne(String id) async {
    try {
      final file = await _cacheFile(id);
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

/// 一条已缓存动态记录（供「已缓存文字/数据」查看页透明展示）。
class DynamicCacheEntry {
  final String id;
  final String author;
  final String text;
  final int bytes;
  final DateTime savedAt;

  const DynamicCacheEntry({
    required this.id,
    required this.author,
    required this.text,
    required this.bytes,
    required this.savedAt,
  });

  String get url => 'https://www.bilibili.com/opus/$id';
}
