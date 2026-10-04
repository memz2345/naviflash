                                                
  
                                               
                                                      
                                                 
                                                           

import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show Color;

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:naviflash/services/cache_dirs.dart';
import '../l10n/l10n_helper.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/image_cache_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/fan_decorate_card.dart';

                                            
                                                 
                                      
                                            

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

               
                                                                               
                                       
String _normalizeUrl(String url) {
  if (url.isEmpty) return url;
  if (url.startsWith('bfs/')) return 'https://i0.hdslb.com/$url';
  if (url.startsWith('//')) return 'https:$url';
  return url;
}

                                                   
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

                                            
           
                                            

class BiliUserSpaceCard {
  final int mid;
  final String name;
  final String face;
  final String sign;
  final int level;
  final int vipType;
  final int vipStatus;
  final int officialType;
  final String sex;                           
  final int fans;       
  final int following;       
  final int archiveCount;       
  final int likeNum;       

                                              
  final String topPhoto;

                                               
  final String pendantImage;

                                             
  final BiliFansDetail? fansDetail;

                                                            
  final BiliFanDecorate? fanDecorate;

                                  
  final BiliNameplate? nameplate;

                                                                
                               
  final bool isSeniorMember;

  const BiliUserSpaceCard({
    required this.mid,
    required this.name,
    required this.face,
    required this.sign,
    required this.level,
    required this.vipType,
    required this.vipStatus,
    required this.officialType,
    required this.sex,
    required this.fans,
    required this.following,
    required this.archiveCount,
    required this.likeNum,
    required this.topPhoto,
    this.pendantImage = '',
    this.fansDetail,
    this.fanDecorate,
    this.nameplate,
    this.isSeniorMember = false,
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
      sex: (card?['sex'] as String?) ?? '',
                                               
      fans: _toInt(json['follower'] ?? card?['follower']),
      following: _toInt(card?['attention']),
      archiveCount: _toInt(json['archive_count']),
      likeNum: _toInt(json['like_num']),
      topPhoto: _normalizeUrl((card?['top_photo'] as String?) ?? ''),
      pendantImage: _normalizeUrl((pendant?['image'] as String?) ?? ''),
      fansDetail: fansDetailJson == null
          ? null
          : BiliFansDetail.fromJson(fansDetailJson),
      fanDecorate: BiliFanDecorate.fromSpaceData(json),
      nameplate: BiliNameplate.fromAny(card?['nameplate']),
      isSeniorMember: _isSeniorMember(json, card, levelInfo),
    );
  }
}

                                                     
                                                     
bool _isSeniorMember(
  Map<String, dynamic>? data,
  Map<String, dynamic>? card,
  Map<String, dynamic>? levelInfo,
) {
  for (final m in [card, data, levelInfo]) {
    if (m == null) continue;
    if (_toInt(m['identity']) == 2) return true;
    if (_toInt(m['is_senior_member']) == 1) return true;
    final senior = _asMap(m['senior']);
    if (senior != null && _toInt(senior['status']) > 0) return true;
  }
  return false;
}

                                            
class BiliFansDetail {
                      
  final int number;

                     
  final String medalName;

           
  final int level;

                 
  final Color colorStart;

              
  final Color colorEnd;

            
  final Color colorBorder;

               
  final Color nameColor;

           
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

                                          
  static Color _colorFromInt(int v) {
    if (v <= 0) return const Color(0xFFFB7299);
    return Color(0xFF000000 | v);
  }
}

                                            
           
                                            

class BiliUserVideo {
  final String bvid;
  final String title;
  final String pic;
  final String author;
  final int mid;
  final int play;
  final int danmaku;
  final int duration;     
  final int created;            

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
                                                    
      duration: _toSeconds(json['length']),
      created: _toInt(json['created']),
    );
  }
}

class BiliUserVideoPage {
  final List<BiliUserVideo> videos;
  final int count;        

                                                    
                                                     
  final Map<int, BiliUserVideoCategory> tlist;

  const BiliUserVideoPage({
    required this.videos,
    required this.count,
    this.tlist = const {},
  });
}

                   
class BiliUserVideoCategory {
  final int tid;
  final String name;
  final int count;

  const BiliUserVideoCategory({
    required this.tid,
    required this.name,
    required this.count,
  });

  factory BiliUserVideoCategory.fromJson(int tid, Map<String, dynamic> json) {
    return BiliUserVideoCategory(
      tid: _toInt(json['tid']) != 0 ? _toInt(json['tid']) : tid,
      name: (json['name'] as String?) ?? '',
      count: _toInt(json['count']),
    );
  }
}

                                            
             
                                            

class BiliUserDynamic {
  final String idStr;
  final String type;
  final String title;                          
  final String text;        
  final String cover;                         
  final int pubTs;                
  final int like;       
  final int comment;       
  final int forward;       

                                                    
  final String bvid;
  final int aid;

                                                                                 
  final List<String> images;

                                      
  final List<BiliDynTextNode> textNodes;

                       
  final String topicName;
  final String topicUrl;

                                            
  final BiliUserDynamic? orig;

                                 
  final String authorName;
  final String authorFace;
  final int authorMid;

                                  
  final String durationText;
  final int play;
  final int danmaku;

                                 
  final String articleUrl;

                            
  final int liveRoomId;

                                   
  String get actionUrl {
    if (bvid.isNotEmpty) return 'https://www.bilibili.com/video/$bvid';
    if (articleUrl.isNotEmpty) return articleUrl;
    if (liveRoomId > 0) return 'https://live.bilibili.com/$liveRoomId';
    if (idStr.isNotEmpty) return 'https://www.bilibili.com/opus/$idStr';
    return '';
  }

               
  bool get isArchive => bvid.isNotEmpty || aid > 0;

            
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

                                                          
    String text = (desc['text'] as String?) ?? '';
    if (text.isEmpty && opus != null) {
      final summary = _asMap(opus['summary']);
      if (summary != null) {
        text = (summary['text'] as String?) ?? '';
      }
    }

                                                                       
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
  final String offset;                     
  final bool hasMore;

  const BiliUserDynamicPage({
    required this.items,
    required this.offset,
    required this.hasMore,
  });
}

                                            
                                            
                                            

                                          
class BiliDynTextNode {
  final String type;                                                           
  final String text;
  final String rid;                          
  final String url;        
  final String? emojiUrl;             

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
  final String type;                                                 
  final String text;                 
  final List<BiliDynTextNode> textNodes;         
  final List<String> images;                                

                                                           
  final String commentIdStr;
  final int commentType;

                                    
  final String? archiveTitle;
  final String? archiveCover;
  final String? bvid;
  final int aid;
  final String? archiveDurationText;
  final int archivePlay;
  final int archiveDanmaku;

                           
  final String? articleTitle;
  final String? articleUrl;

                        
  final String? liveTitle;
  final String? liveCover;
  final int liveRoomId;

                                
  final BiliDynamicDetail? orig;

  final String authorName;
  final String authorFace;
  final int authorMid;
  final int pubTs;
  final int likeCount;
  final int commentCount;
  final int forwardCount;

                                         
  final bool liked;

                                                   
  final bool isTop;

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
    this.liked = false,
    this.isTop = false,
  });

                   
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
        : 17;                    

           
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

         
    String? liveTitle;
    String? liveCover;
    int liveRoomId = 0;
    if (majorType == 'MAJOR_TYPE_LIVE') {
      final live = _asMap(major['live']) ?? const <String, dynamic>{};
      liveTitle = (live['title'] as String?) ?? '';
      liveCover = _normalizeUrl((live['cover'] as String?) ?? '');
      liveRoomId = _toInt(live['room_id']);
    }

                                                          
    final opusMap = _asMap(major['opus']);
    String text = (desc['text'] as String?) ?? '';
    if (text.isEmpty && opusMap != null) {
      final summary = _asMap(opusMap['summary']);
      if (summary != null) {
        text = (summary['text'] as String?) ?? '';
      }
    }

                                                       
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
      liked: _asMap(stat['like'])?['status'] == true,
      isTop: author['is_top'] == true ||
          ((_asMap(modules['module_tag'])?['text'] as String?) ?? '') == '置顶',
    );
  }
}

                                            
                                                  
                                            

class BiliUserBangumi {
  final int seasonId;
  final int mediaId;
  final String title;
  final String cover;
  final String badge;              
  final String seasonTypeName;             
  final bool isFinish;        
  final bool isStarted;        
  final String newEpIndex;                    
  final String newEpPubTime;            
  final double ratingScore;             
  final int ratingCount;        
  final String evaluate;      
  final String subtitle;       
  final String progress;                  
  final String publishTime;        
  final List<String> areas;        

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

                                            
                                                               
                                            

              
                                                           
                                                       
class BiliSpaceProfile {
  final int mid;
  final String name;
  final String face;
  final String sign;
  final String sex;              
  final int level;
  final int vipType;
  final int vipStatus;
  final String vipLabel;                          
  final int officialType;            
  final String officialDesc;                  
  final String pendantImage;
  final int fans;
  final int following;
  final int likeNum;       
  final int archiveCount;         
  final int articleCount;       
  final String topPhoto;        
  final String location;                                  
  final String? userIdentity;                                  

                                         
                                                   
                                                    
  final int? attribute;
  final int? special;

                                                              
  final bool? isFollowed;

                             
  final int elecTotal;
  final List<String> elecAvatars;

                   
  final int guardCount;

                                         
  final bool isLive;
  final int liveRoomId;
  final String liveTitle;

                                        
  final BiliFansDetail? fansDetail;

                                                                 
  final BiliFanDecorate? fanDecorate;

                                  
  final BiliNameplate? nameplate;

                                                                
                                            
  final bool isSeniorMember;

                                   
  final bool hasSeasonOrSeries;

  const BiliSpaceProfile({
    required this.mid,
    required this.name,
    required this.face,
    required this.sign,
    required this.sex,
    required this.level,
    required this.vipType,
    required this.vipStatus,
    required this.vipLabel,
    required this.officialType,
    required this.officialDesc,
    required this.pendantImage,
    required this.fans,
    required this.following,
    required this.likeNum,
    required this.archiveCount,
    required this.articleCount,
    required this.topPhoto,
    required this.location,
    required this.elecTotal,
    required this.elecAvatars,
    required this.guardCount,
    required this.isLive,
    required this.liveRoomId,
    required this.liveTitle,
    required this.hasSeasonOrSeries,
    this.userIdentity,
    this.attribute,
    this.special,
    this.isFollowed,
    this.fansDetail,
      this.fanDecorate,
      this.nameplate,
      this.isSeniorMember = false,
  });

                                                                    
  factory BiliSpaceProfile.fromAppJson(Map<String, dynamic> json) {
    final card = _asMap(json['card']) ?? const <String, dynamic>{};
    final levelInfo = _asMap(card['level_info']);
    final vip = _asMap(card['vip']);
    final official = _asMap(card['official_verify']);
    final pendant = _asMap(card['pendant']);
    final likes = _asMap(card['likes']);
    final cardRelation = _asMap(card['relation']);
    final elec = _asMap(json['elec']);
    final guard = _asMap(json['guard']);
    final live = _asMap(json['live']);
    final archive = _asMap(json['archive']);
    final article = _asMap(json['article']);
    final ugcSeason = _asMap(json['ugc_season']);
    final series = _asMap(json['series']);

                                                          
    String location = '';
    String? realName;
    final rawTags = json['space_tag'] as List<dynamic>?;
    for (final t in rawTags ?? const []) {
      final m = _asMap(t);
      if (m == null) continue;
      final type = (m['type'] as String?) ?? '';
      final title = (m['title'] as String?) ?? '';
      if (type == 'location' && location.isEmpty) {
        location = title;
      } else if (type == 'real_name' && (realName?.isEmpty ?? true)) {
        realName = title;
      }
    }

                                  
    final elecAvatars = <String>[];
    for (final e in (elec?['list'] as List<dynamic>? ?? const [])) {
      final m = _asMap(e);
      final avatar = _normalizeUrl((m?['avatar'] as String?) ?? '');
      if (avatar.isNotEmpty) elecAvatars.add(avatar);
    }

                                      
    int guardCount = 0;
    final rawGuardCount = guard?['count'];
    if (rawGuardCount is num) {
      guardCount = rawGuardCount.toInt();
    } else if (rawGuardCount is String) {
      guardCount = int.tryParse(rawGuardCount) ?? 0;
    } else if (rawGuardCount == null) {
      final desc = (guard?['desc'] as String?) ?? '';
      guardCount = int.tryParse(
            RegExp(r'^(\d+)').firstMatch(desc)?.group(1) ?? '',
          ) ??
          0;
    }

    return BiliSpaceProfile(
      mid: _toInt(card['mid']),
      name: (card['name'] as String?) ?? '',
      face: _normalizeUrl((card['face'] as String?) ?? ''),
      sign: (card['sign'] as String?) ?? '',
      sex: (card['sex'] as String?) ?? '',
      level: _toInt(levelInfo?['current_level']),
      vipType: _toInt(vip?['vipType']),
      vipStatus: _toInt(vip?['vipStatus']),
      vipLabel: (_asMap(vip?['label'])?['text'] as String?) ?? '',
      officialType: official == null
          ? -1
          : _toInt(official['type']),
      officialDesc: (official?['desc'] as String?) ?? '',
      pendantImage: _normalizeUrl((pendant?['image'] as String?) ?? ''),
      fans: _toInt(json['follower'] ?? card['fans']),
      following: _toInt(card['attention']),
      likeNum: _toInt(likes?['like_num']),
      archiveCount: _toInt(archive?['count']),
      articleCount: _toInt(article?['count']),
      topPhoto: _normalizeUrl((card['top_photo'] as String?) ?? ''),
      location: location,
      userIdentity: (realName?.isNotEmpty ?? false) ? realName : null,
      attribute: json['relation'] is int ? json['relation'] as int : null,
      special: (json['rel_special'] as num?)?.toInt(),
      isFollowed: cardRelation == null
          ? null
          : _toInt(cardRelation['is_followed']) == 1,
      elecTotal: _toInt(elec?['total']),
      elecAvatars: elecAvatars,
      guardCount: guardCount,
      isLive: _toInt(live?['live_status']) == 1,
      liveRoomId: _toInt(live?['roomid']),
      liveTitle: (live?['title'] as String?) ?? '',
      hasSeasonOrSeries:
          (_toInt(ugcSeason?['count']) > 0) ||
          ((series?['item'] as List<dynamic>?)?.isNotEmpty == true),
      fansDetail: _asMap(card['fans_detail']) == null
          ? null
          : BiliFansDetail.fromJson(_asMap(card['fans_detail'])!),
      fanDecorate: BiliFanDecorate.fromSpaceData(json),
      nameplate: BiliNameplate.fromAny(card['nameplate']),
      isSeniorMember: _isSeniorMember(json, card, levelInfo),
    );
  }

                                                      
                                              
  factory BiliSpaceProfile.fromWebCardJson(Map<String, dynamic> json) {
    final card = _asMap(json['card']) ?? const <String, dynamic>{};
    final levelInfo = _asMap(card['level_info']);
    final vip = _asMap(card['vip']);
    final official = _asMap(card['official_verify']);
    final pendant = _asMap(card['pendant']);
    return BiliSpaceProfile(
      mid: _toInt(card['mid']),
      name: (card['name'] as String?) ?? '',
      face: _normalizeUrl((card['face'] as String?) ?? ''),
      sign: (card['sign'] as String?) ?? '',
      sex: (card['sex'] as String?) ?? '',
      level: _toInt(levelInfo?['current_level']),
      vipType: _toInt(vip?['vipType']),
      vipStatus: _toInt(vip?['vipStatus']),
      vipLabel: '',
      officialType: _toInt(official?['type']),
      officialDesc: (official?['desc'] as String?) ?? '',
      pendantImage: _normalizeUrl((pendant?['image'] as String?) ?? ''),
      fans: _toInt(json['follower'] ?? card['follower']),
      following: _toInt(card['attention']),
      likeNum: _toInt(json['like_num']),
      archiveCount: _toInt(json['archive_count']),
      articleCount: 0,
      topPhoto: _normalizeUrl((card['top_photo'] as String?) ?? ''),
      location: '',
      elecTotal: 0,
      elecAvatars: const [],
      guardCount: 0,
      isLive: false,
      liveRoomId: 0,
      liveTitle: '',
      hasSeasonOrSeries: false,
      fansDetail: _asMap(card['fans_detail']) == null
          ? null
          : BiliFansDetail.fromJson(_asMap(card['fans_detail'])!),
      fanDecorate: BiliFanDecorate.fromSpaceData(json),
      nameplate: BiliNameplate.fromAny(card['nameplate']),
      isSeniorMember: _isSeniorMember(json, card, levelInfo),
    );
  }

                                                 
  BiliSpaceProfile mergedWith(BiliSpaceProfile web) {
    return BiliSpaceProfile(
      mid: mid,
      name: name.isNotEmpty ? name : web.name,
      face: face.isNotEmpty ? face : web.face,
      sign: sign.isNotEmpty ? sign : web.sign,
      sex: sex.isNotEmpty ? sex : web.sex,
      level: level > 0 ? level : web.level,
      vipType: vipType,
      vipStatus: vipStatus,
      vipLabel: vipLabel,
      officialType: officialType,
      officialDesc: officialDesc.isNotEmpty ? officialDesc : web.officialDesc,
      pendantImage: pendantImage.isNotEmpty ? pendantImage : web.pendantImage,
      fans: fans > 0 ? fans : web.fans,
      following: following,
      likeNum: likeNum > 0 ? likeNum : web.likeNum,
      archiveCount: archiveCount,
      articleCount: articleCount,
      topPhoto: topPhoto.isNotEmpty ? topPhoto : web.topPhoto,
      location: location.isNotEmpty ? location : web.location,
      userIdentity: userIdentity ?? web.userIdentity,
      attribute: attribute,
      special: special,
      isFollowed: isFollowed,
      elecTotal: elecTotal,
      elecAvatars: elecAvatars,
      guardCount: guardCount,
      isLive: isLive,
      liveRoomId: liveRoomId,
      liveTitle: liveTitle,
      hasSeasonOrSeries: hasSeasonOrSeries,
      fansDetail: fansDetail ?? web.fansDetail,
      fanDecorate: fanDecorate ?? web.fanDecorate,
      nameplate: nameplate ?? web.nameplate,
      isSeniorMember: isSeniorMember || web.isSeniorMember,
    );
  }
}

                                            
                                                     
                                            

                                                             
class BiliSpaceSeasonItem {
  final int? seasonId;
  final int? seriesId;
  final String name;
  final String cover;
  final int total;       
  final String description;

                             
  bool get isSeason => seasonId != null && seasonId! > 0;
  int get id => isSeason ? seasonId! : (seriesId ?? 0);

  const BiliSpaceSeasonItem({
    required this.seasonId,
    required this.seriesId,
    required this.name,
    required this.cover,
    required this.total,
    required this.description,
  });

  factory BiliSpaceSeasonItem.fromJson(Map<String, dynamic> json) {
    final meta = _asMap(json['meta']) ?? json;
    final rawSeason = meta['season_id'];
    final rawSeries = meta['series_id'];
    return BiliSpaceSeasonItem(
      seasonId: rawSeason is num ? rawSeason.toInt() : int.tryParse('$rawSeason'),
      seriesId: rawSeries is num ? rawSeries.toInt() : int.tryParse('$rawSeries'),
      name: (meta['name'] as String?) ?? '',
      cover: _normalizeUrl((meta['cover'] as String?) ?? ''),
      total: _toInt(meta['total']),
      description: (meta['description'] as String?) ?? '',
    );
  }
}

                                              
class BiliSpaceSeasonSeries {
  final List<BiliSpaceSeasonItem> items;
  final int total;

  const BiliSpaceSeasonSeries({required this.items, required this.total});
}

                                                         
class BiliSpaceArcPage {
  final List<BiliUserVideo> videos;
  final int total;
  final bool hasMore;

                                                
  final int? next;

  const BiliSpaceArcPage({
    required this.videos,
    required this.total,
    required this.hasMore,
    this.next,
  });
}

                                            
                                                                         
                                            

class BiliCoinLikeItem {
  final String bvid;
  final String title;
  final String cover;
  final int aid;
  final int play;
  final int danmaku;
  final int duration;     
  final String author;
  final int mid;
  final String createdText;              

  const BiliCoinLikeItem({
    required this.bvid,
    required this.title,
    required this.cover,
    required this.aid,
    required this.play,
    required this.danmaku,
    required this.duration,
    required this.author,
    required this.mid,
    required this.createdText,
  });

  factory BiliCoinLikeItem.fromJson(Map<String, dynamic> json) {
    final stat = _asMap(json['stat']) ?? json;
    return BiliCoinLikeItem(
      bvid: (json['bvid'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      cover: _normalizeUrl((json['cover'] as String?) ?? ''),
      aid: _toInt(json['param']),
      play: _toInt(stat['play']),
      danmaku: _toInt(stat['danmaku']),
      duration: _toSeconds(
        json['duration'] ?? json['length'],
      ),
      author: (json['author'] as String?) ?? '',
      mid: _toInt(json['mid']),
      createdText: (json['publish_time_text'] as String?) ?? '',
    );
  }

                         
  BiliUserVideo toVideo() => BiliUserVideo(
        bvid: bvid,
        title: title,
        pic: cover,
        author: author,
        mid: mid,
        play: play,
        danmaku: danmaku,
        duration: duration,
        created: 0,
      );
}

class BiliCoinLikePage {
  final List<BiliCoinLikeItem> items;
  final int count;

  const BiliCoinLikePage({required this.items, required this.count});
}

                                            
                                            
                                            

class BiliRelationUser {
  final int mid;
  final String uname;
  final String face;
  final String sign;
  final String officialDesc;
  final int attribute;                       

  const BiliRelationUser({
    required this.mid,
    required this.uname,
    required this.face,
    required this.sign,
    required this.officialDesc,
    required this.attribute,
  });

  factory BiliRelationUser.fromJson(Map<String, dynamic> json) {
    final official = _asMap(json['official_verify']);
    return BiliRelationUser(
      mid: _toInt(json['mid']),
      uname: (json['uname'] as String?) ?? '',
      face: _normalizeUrl((json['face'] as String?) ?? ''),
      sign: (json['sign'] as String?) ?? '',
      officialDesc: (official?['desc'] as String?) ?? '',
      attribute: _toInt(json['attribute']),
    );
  }
}

class BiliRelationListPage {
  final List<BiliRelationUser> users;
  final int total;

  const BiliRelationListPage({required this.users, required this.total});
}

                              
class BiliFollowTag {
                                       
  final int tagid;
  final String name;

                           
  final int count;

  const BiliFollowTag({
    required this.tagid,
    required this.name,
    this.count = 0,
  });

  factory BiliFollowTag.fromJson(Map<String, dynamic> json) => BiliFollowTag(
    tagid: _toInt(json['tagid']),
    name: '${json['name'] ?? ''}',
    count: _toInt(json['count']),
  );
}

                                     
class BiliSpaceArticle {
  final String title;
  final String cover;
  final String uri;                           
  final String publishText;
  final int view;
  final int reply;

  const BiliSpaceArticle({
    required this.title,
    required this.cover,
    required this.uri,
    required this.publishText,
    required this.view,
    required this.reply,
  });

                                 
  int get cvid {
    final m1 = RegExp(r'^bilibili://article/(\d+)').firstMatch(uri);
    if (m1 != null) return int.tryParse(m1.group(1)!) ?? 0;
    final m2 = RegExp(r'/read/cv(\d+)').firstMatch(uri);
    if (m2 != null) return int.tryParse(m2.group(1)!) ?? 0;
    return int.tryParse(uri) ?? 0;
  }

  factory BiliSpaceArticle.fromJson(Map<String, dynamic> json) {
    final stats = _asMap(json['stats']) ?? const <String, dynamic>{};
    final covers = json['origin_image_urls'];
    String cover = '';
    if (covers is List && covers.isNotEmpty) cover = '${covers.first}';
    return BiliSpaceArticle(
      title: (json['title'] as String?) ?? '',
      cover: _normalizeUrl(cover),
      uri: (json['uri'] as String?) ?? '',
      publishText: (json['publish_time_text'] as String?) ?? '',
      view: _toInt(stats['view']),
      reply: _toInt(stats['reply']),
    );
  }
}

class BiliSpaceArticlePage {
  final List<BiliSpaceArticle> items;
  final int count;

  const BiliSpaceArticlePage({required this.items, required this.count});
}

                                            
      
                                            

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

                                    
  static String? lastErrorDetail;

                                                
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

                                               
                                             
  static String? _spiBuvid3;
  static String? _spiBuvid4;

                                 
                                 
  static Future<void>? _fpFuture;

  static Future<void> _ensureDeviceFp() {
    if (_spiBuvid3 != null) return Future<void>.value();
                                             
                                                        
                                          
    return _fpFuture ??= _fetchDeviceFp().whenComplete(() {
      if (_spiBuvid3 == null) _fpFuture = null;
    });
  }

  static Future<void> _fetchDeviceFp() async {
    if (_spiBuvid3 != null) return;
                                        
                                                  
    try {
      final prefs = await SharedPreferences.getInstance();
      final b3 = prefs.getString('spi_buvid3');
      if (b3 != null && b3.isNotEmpty) {
        _spiBuvid3 = b3;
        _spiBuvid4 = prefs.getString('spi_buvid4') ?? '';
        return;
      }
    } catch (_) {
                 
    }
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(_spiApi), headers: _defaultHeaders)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return;
      final data = _asMap(json['data']);
      if (data == null) return;
      final b3 = (data['b_3'] as String?) ?? '';
      if (b3.isNotEmpty) {
        _spiBuvid3 = b3;
        _spiBuvid4 = (data['b_4'] as String?) ?? '';
                     
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('spi_buvid3', _spiBuvid3!);
          await prefs.setString('spi_buvid4', _spiBuvid4 ?? '');
        } catch (_) {
                      
        }
      }
    } catch (e) {
      debugPrint('[UserSpace] 获取设备指纹失败: $e');
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
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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

                                                   
                             
     
                                                        
  static Future<int?> fetchUserRelation({required int mid}) async {
    try {
      final account = BilibiliAccountService.instance;
      if (!account.isLoggedIn) return null;
      if (mid <= 0 || mid == account.mid) return null;
      final uri = Uri.parse(
        'https://api.bilibili.com/x/relation',
      ).replace(queryParameters: {'fid': mid.toString()});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        debugPrint('[UserSpace] relation code=${json['code']}');
        return null;
      }
      final data = _asMap(json['data']);
      return data == null ? null : _toInt(data['attribute']);
    } catch (e) {
      debugPrint('[UserSpace] 拉取关注关系异常: $e');
      return null;
    }
  }

                                                 
                                        
  static Future<bool> modifyUserRelation({
    required int mid,
    required bool follow,
  }) async {
    try {
      final account = BilibiliAccountService.instance;
      if (!account.isLoggedIn || mid <= 0 || mid == account.mid) return false;
      final cookieHeader = account.cookieHeaderFor(
        BiliCookieScope.interactions,
      );
      final rawCookie = cookieHeader?['Cookie'] ?? '';
      final csrf = _extractCookieValue(rawCookie, 'bili_jct');
      if (csrf.isEmpty) return false;
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse('https://api.bilibili.com/x/relation/modify'),
            headers: {
              ..._defaultHeaders,
              'Referer': 'https://space.bilibili.com/$mid',
              'Origin': 'https://space.bilibili.com',
              'Cookie': rawCookie,
              'Content-Type': 'application/x-www-form-urlencoded',
              ...NetworkSettingsService.instance.apiHeaders,
            },
            body: {
              'fid': mid.toString(),
              'act': follow ? '1' : '2',
              're_src': '11',
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return false;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        debugPrint('[UserSpace] relation modify code=${json['code']}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[UserSpace] 关注操作异常: $e');
      return false;
    }
  }

                                       
  static String _extractCookieValue(String cookie, String name) {
    final m = RegExp('(?:^|;\\s*)$name=([^;]+)').firstMatch(cookie);
    return m?.group(1) ?? '';
  }

                                          
                  
                                          

                           
                                                             
                           
                                              
  static Future<BiliUserVideoPage?> fetchUserVideos({
    required int mid,
    int pn = 1,
    int ps = 30,
    String order = 'pubdate',
    int tid = 0,
  }) async {
    try {
      if (mid <= 0) {
        lastErrorDetail = L10n.current.userSpaceMidInvalid;
        return null;
      }
      final params = await WbiSign.sign({
        'mid': mid.toString(),
        'order': order,
        'pn': pn.toString(),
        'ps': ps.toString(),
        'tid': tid.toString(),
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
      var json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> ||
          (json['code'] != 0 && json['code'] != 200)) {
                                      
                                  
        final legacyUri =
            Uri.parse('https://api.bilibili.com/x/space/arc/search').replace(
              queryParameters: {
                'mid': mid.toString(),
                'order': order,
                'pn': pn.toString(),
                'ps': ps.toString(),
                'tid': tid.toString(),
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
                                                 
      final list = _asMap(data['list']);
      final rawList =
          list?['vlist'] as List<dynamic>? ?? (data['list'] as List<dynamic>?);
      final page = _asMap(data['page']);
                                                    
      final tlist = <int, BiliUserVideoCategory>{};
      final rawTlist = data['tlist'];
      if (rawTlist is Map) {
        for (final entry in rawTlist.entries) {
          final tid = int.tryParse('${entry.key}');
          final m = _asMap(entry.value);
          if (tid == null || m == null) continue;
          tlist[tid] = BiliUserVideoCategory.fromJson(tid, m);
        }
      }
      lastErrorDetail = null;
      return BiliUserVideoPage(
        videos: (rawList ?? [])
            .whereType<Map<String, dynamic>>()
            .map(BiliUserVideo.fromJson)
            .toList(),
        count: _toInt(page?['count']),
        tlist: tlist,
      );
    } catch (e) {
      lastErrorDetail = L10n.current.commentException('$e');
      debugPrint('[UserSpace] 拉取视频列表异常: $e');
      return null;
    }
  }

                                          
                                        
                                          

                                                                  
                                         
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
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        debugPrint(
          '[UserSpace] banner code=${json['code']} ${json['message']}',
        );
        return null;
      }
      final data = _asMap(json['data']);
      final images = _asMap(data?['images']);
                                                   
                                                  
                         
      final light = _normalizeUrl((images?['imgUrl'] as String?) ?? '');
      final dark = _normalizeUrl((images?['night_imgurl'] as String?) ?? '');
                                           
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

                                          
                  
                                          

                                                         
                                   
     
                                                      
                                                   
                                        
                                          
  static Future<BiliUserDynamicPage?> fetchUserDynamics({
    required int mid,
    String offset = '',
    int maxPages = 1,
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
        final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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

                                                
     
                                                      
                                   
                     
  static Future<BiliDynamicDetail?> fetchDynamicDetail({
    required String id,
  }) async {
    if (id.isEmpty) {
      lastErrorDetail = L10n.current.biliResponseNoData;
      return null;
    }
                                  
    final cachedItem = await DynamicDetailCache.load(id);
    if (cachedItem != null) {
      debugPrint('[UserSpace] dynDetail 命中缓存: $id');
      lastErrorDetail = null;
      return BiliDynamicDetail.fromJson(cachedItem);
    }
                     
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
        final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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
                     
      await DynamicDetailCache.save(id, item);
      return BiliDynamicDetail.fromJson(item);
    }
                                      
    final stale = await DynamicDetailCache.load(id, allowStale: true);
    if (stale != null) {
      lastErrorDetail = null;
      return BiliDynamicDetail.fromJson(stale);
    }
    lastErrorDetail = netError ?? L10n.current.biliResponseNoData;
    return null;
  }

                                          
        
                                          

                          
  static String avatarUrl(String url, {int size = 96}) {
    if (url.isEmpty) return '';
    return '${_normalizeUrl(url)}@${size}w_${size}h_1c.webp';
  }

                             
  static String coverUrl(String url) {
    if (url.isEmpty) return '';
    return '${_normalizeUrl(url)}@320w_200h_1c.webp';
  }

                                     
                                            
  static String bangumiCoverUrl(String url) {
    if (url.isEmpty) return '';
    return '${_normalizeUrl(url)}@480w_640h_1c.webp';
  }

                       
     
                                     
                                         
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

                                          
                                       
                                          

                                      
                                                
                                              
  static Future<BiliUserBangumiPage?> fetchUserBangumi({
    required int mid,
    int type = 1,
    int followStatus = 0,
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
          if (followStatus > 0) 'follow_status': followStatus.toString(),
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
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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

                                          
                                    
                                          

                              
  static Future<BiliSpaceArticlePage?> fetchSpaceArticles({
    required int mid,
    int pn = 1,
    int ps = 10,
  }) async {
    if (mid <= 0) {
      lastErrorDetail = L10n.current.userSpaceMidInvalid;
      return null;
    }
    try {
      final data = await _appGet(
        'https://app.bilibili.com/x/v2/space/article',
        {
          'build': '8430300',
          'channel': 'master',
          'version': '8.43.0',
          'c_locale': 'zh_CN',
          'mobi_app': 'android',
          'platform': 'android',
          'pn': pn.toString(),
          'ps': ps.toString(),
          's_locale': 'zh_CN',
          'statistics': _statisticsApp,
          'vmid': mid.toString(),
        },
      );
      if (data == null) {
        lastErrorDetail = '专栏列表为空';
        return null;
      }
      final raw = data['item'];
      final items = raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(BiliSpaceArticle.fromJson)
              .where((e) => e.title.isNotEmpty)
              .toList()
          : <BiliSpaceArticle>[];
      lastErrorDetail = null;
      return BiliSpaceArticlePage(
        items: items,
        count: _toInt(data['count']),
      );
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[UserSpace] 拉取专栏列表异常: $e');
      return null;
    }
  }

                                          
                                             
                                          
  static const String _appUserAgent =
      'Mozilla/5.0 BiliDroid/8.43.0 (bbcallen@gmail.com) os/android '
      'model/android mobi_app/android build/8430300 channel/master '
      'innerVer/8430300 osVer/15 network/2';
  static const String _statisticsApp =
      '{"appId":1,"platform":3,"version":"8.43.0","abtest":""}';
  static const Map<String, String> _appBaseHeaders = {
    'User-Agent': _appUserAgent,
    'env': 'prod',
    'app-key': 'android64',
  };

                                                 
  static Future<Map<String, dynamic>?> _appGet(
    String url,
    Map<String, String> query,
  ) async {
    final client = await NetworkSettingsService.instance.getApiClient();
    final resp = await client
        .get(
          Uri.parse(url).replace(queryParameters: query),
          headers: {
            ..._appBaseHeaders,
            'Cookie': await _buildCookie(),
            ...NetworkSettingsService.instance.apiHeaders,
          },
        )
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      debugPrint('[UserSpace] app GET $url HTTP ${resp.statusCode}');
      return null;
    }
    final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
    if (json is! Map<String, dynamic> || json['code'] != 0) {
      debugPrint(
        '[UserSpace] app GET $url code=${json is Map ? json['code'] : '?'}',
      );
      return null;
    }
    return _asMap(json['data']);
  }

                                          
                                              
                                          

                                           
                                                   
                                                      
                                       
  static Future<BiliSpaceProfile?> fetchSpaceProfile({
    required int mid,
  }) async {
    if (mid <= 0) {
      lastErrorDetail = L10n.current.userSpaceMidInvalid;
      return null;
    }
    final results = await Future.wait<Map<String, dynamic>?>([
      _appGet(
        'https://app.bilibili.com/x/v2/space',
        {
          'build': '8430300',
          'version': '8.43.0',
          'c_locale': 'zh_CN',
          'channel': 'master',
          'mobi_app': 'android',
          'platform': 'android',
          's_locale': 'zh_CN',
          'statistics': _statisticsApp,
          'vmid': mid.toString(),
        },
      ).catchError((_) => null),
      _getJson('https://api.bilibili.com/x/web-interface/card', {
        'mid': mid.toString(),
        'photo': 'true',
      }).catchError((_) => null),
    ]);
    final appData = results[0];
    final cardData = results[1];
    if (appData != null) {
      final profile = BiliSpaceProfile.fromAppJson(appData);
      if (cardData != null) {
        lastErrorDetail = null;
        return profile.mergedWith(
          BiliSpaceProfile.fromWebCardJson(cardData),
        );
      }
      lastErrorDetail = null;
      return profile;
    }
    if (cardData != null) {
      lastErrorDetail = null;
      return BiliSpaceProfile.fromWebCardJson(cardData);
    }
    lastErrorDetail ??= L10n.current.userSpaceNoCard;
    return null;
  }

                                      
  static Future<Map<String, dynamic>?> _getJson(
    String url,
    Map<String, String> query,
  ) async {
    final client = await NetworkSettingsService.instance.getApiClient();
    final resp = await client
        .get(
          Uri.parse(url).replace(queryParameters: query),
          headers: await _buildHeaders(),
        )
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) return null;
    final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
    if (json is! Map<String, dynamic> || json['code'] != 0) return null;
    return _asMap(json['data']);
  }

                                          
                                 
                                          

                                                
                                   
  static Future<({int attribute, int special})?> fetchRelationDetail({
    required int mid,
  }) async {
    final account = BilibiliAccountService.instance;
    if (!account.isLoggedIn || mid <= 0 || mid == account.mid) return null;
    final data = await _getJson('https://api.bilibili.com/x/relation', {
      'fid': mid.toString(),
    });
    if (data == null) {
      final attr = await fetchUserRelation(mid: mid);
      return attr == null ? null : (attribute: attr, special: 0);
    }
    return (
      attribute: _toInt(data['attribute']),
      special: _toInt(data['special']),
    );
  }

                                
                                                            
  static Future<bool> modifyRelationAct({
    required int mid,
    required int act,
  }) async {
    try {
      final account = BilibiliAccountService.instance;
      if (!account.isLoggedIn || mid <= 0 || mid == account.mid) return false;
      final cookieHeader = account.cookieHeaderFor(
        BiliCookieScope.interactions,
      );
      final rawCookie = cookieHeader?['Cookie'] ?? '';
      final csrf = _extractCookieValue(rawCookie, 'bili_jct');
      if (csrf.isEmpty) return false;
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse('https://api.bilibili.com/x/relation/modify'),
            headers: {
              ..._defaultHeaders,
              'Referer': 'https://space.bilibili.com/$mid',
              'Origin': 'https://space.bilibili.com',
              'Cookie': rawCookie,
              'Content-Type': 'application/x-www-form-urlencoded',
              ...NetworkSettingsService.instance.apiHeaders,
            },
            body: {
              'fid': mid.toString(),
              'act': act.toString(),
              're_src': '11',
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return false;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        debugPrint('[UserSpace] relation modify act=$act code=${json['code']}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[UserSpace] 关系操作异常: $e');
      return false;
    }
  }

                                                   
                                            
  static Future<bool> specialFollowAction({
    required int mid,
    required bool add,
  }) async {
    try {
      final account = BilibiliAccountService.instance;
      if (!account.isLoggedIn) return false;
      final cookieHeader = account.cookieHeaderFor(
        BiliCookieScope.interactions,
      );
      final rawCookie = cookieHeader?['Cookie'] ?? '';
      final csrf = _extractCookieValue(rawCookie, 'bili_jct');
      if (csrf.isEmpty) return false;
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(
              add
                  ? 'https://api.bilibili.com/x/relation/tag/special/add'
                  : 'https://api.bilibili.com/x/relation/tag/special/del',
            ),
            headers: {
              ..._defaultHeaders,
              'Referer': 'https://space.bilibili.com/$mid',
              'Origin': 'https://space.bilibili.com',
              'Cookie': rawCookie,
              'Content-Type': 'application/x-www-form-urlencoded',
              ...NetworkSettingsService.instance.apiHeaders,
            },
            body: {'fid': mid.toString(), 'csrf': csrf},
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return false;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      return json['code'] == 0;
    } catch (e) {
      debugPrint('[UserSpace] 特别关注操作异常: $e');
      return false;
    }
  }

                                          
                                       
                                          

                                                              
                                               
  static Future<BiliSpaceSeasonSeries?> fetchSeasonSeries({
    required int mid,
    int pn = 1,
    int ps = 10,
  }) async {
    try {
      final data = await _getJson(
        'https://api.bilibili.com/x/polymer/web-space/seasons_series_list',
        {
          'mid': mid.toString(),
          'page_num': pn.toString(),
          'page_size': ps.toString(),
        },
      );
      if (data == null) {
        lastErrorDetail = L10n.current.biliResponseNoData;
        return null;
      }
      final itemsLists = _asMap(data['items_lists']);
      final items = <BiliSpaceSeasonItem>[];
      for (final list in [
        itemsLists?['seasons_list'],
        itemsLists?['series_list'],
      ]) {
        for (final e in (list as List<dynamic>? ?? const [])) {
          final m = _asMap(e);
          if (m == null) continue;
          items.add(BiliSpaceSeasonItem.fromJson(m));
        }
      }
      lastErrorDetail = null;
      return BiliSpaceSeasonSeries(
        items: items,
        total: _toInt(_asMap(data['page'])?['total']),
      );
    } catch (e) {
      lastErrorDetail = L10n.current.commentException('$e');
      debugPrint('[UserSpace] 拉取合集列表异常: $e');
      return null;
    }
  }

                                            
  static Future<BiliSpaceArcPage?> fetchSeasonVideos({
    required int mid,
    int? seasonId,
    int? seriesId,
    int? next,
    int pn = 1,
  }) async {
    final isSeason = seasonId != null && seasonId > 0;
                                                               
    final query = <String, String>{
      'build': '8430300',
      'version': '8.43.0',
      'mobi_app': 'android',
      'platform': 'android',
      'c_locale': 'zh_CN',
      's_locale': 'zh_CN',
      'channel': 'master',
      'qn': '32',
      'vmid': mid.toString(),
      'statistics': _statisticsApp,
      if (next != null) 'next': next.toString(),
      if (isSeason) 'season_id': seasonId.toString() else 'series_id': (seriesId ?? 0).toString(),
    };
    var data = await _appGet(
      isSeason
          ? 'https://app.bilibili.com/x/v2/space/season/videos'
          : 'https://app.bilibili.com/x/v2/space/series',
      query,
    );
                                        
    if (data == null && !isSeason) {
      data = await _getJson('https://api.bilibili.com/x/series/archives', {
        'mid': mid.toString(),
        'series_id': (seriesId ?? 0).toString(),
        'pn': pn.toString(),
        'ps': '20',
      }).catchError((_) => Future<Map<String, dynamic>?>.value(null));
      if (data != null) {
        final archives = (data['archives'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(
              (a) => BiliUserVideo(
                bvid: (a['bvid'] as String?) ?? '',
                title: (a['title'] as String?) ?? '',
                pic: _normalizeUrl((a['pic'] as String?) ?? ''),
                author: (a['author'] as String?) ?? '',
                mid: _toInt(a['mid']),
                play: _toInt(a['play']),
                danmaku: _toInt(a['video_review']),
                duration: _toSeconds(a['length']),
                created: _toInt(a['created']),
              ),
            )
            .toList();
        return BiliSpaceArcPage(
          videos: archives,
          total: _toInt(_asMap(data['page'])?['total']),
          hasMore: archives.length >= 20,
          next: null,
        );
      }
    }
    if (data == null) {
      lastErrorDetail = L10n.current.biliResponseNoData;
      return null;
    }
                                                    
    final videos = (data['item'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((e) {
          final stat = _asMap(e['stat']);
          return BiliUserVideo(
            bvid: (e['bvid'] as String?) ?? '',
            title: (e['title'] as String?) ?? '',
            pic: _normalizeUrl((e['cover'] as String?) ?? ''),
            author: (e['author'] as String?) ?? '',
            mid: _toInt(e['param']),
            play: _toInt(stat?['play']),
            danmaku: _toInt(stat?['danmaku']),
            duration: e['duration'] is num
                ? _toInt(e['duration'])
                : _toSeconds(e['length']),
            created: 0,
          );
        })
        .toList();
    final hasNext = data['has_next'] == true;
    final nextRaw = data['next'];
    return BiliSpaceArcPage(
      videos: videos,
      total: _toInt(data['count']),
      hasMore: hasNext && nextRaw is num && nextRaw.toInt() > 0,
      next: nextRaw is num ? nextRaw.toInt() : null,
    );
  }

                                          
                                                 
                                          

                                                  
                                                     
  static Future<BiliCoinLikePage?> fetchCoinLikeArc({
    required int mid,
    required String mode,
    int pn = 1,
  }) async {
    try {
      final data = await _appGet(
        mode == 'coin'
            ? 'https://app.bilibili.com/x/v2/space/coinarc'
            : 'https://app.bilibili.com/x/v2/space/likearc',
        {
          'pn': pn.toString(),
          'ps': '20',
          'vmid': mid.toString(),
          'build': '8430300',
          'version': '8.43.0',
          'platform': 'android',
          'mobi_app': 'android',
          'statistics': _statisticsApp,
        },
      );
      if (data == null) {
        lastErrorDetail = L10n.current.biliResponseNoData;
        return null;
      }
      final items = (data['item'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BiliCoinLikeItem.fromJson)
          .toList();
      lastErrorDetail = null;
      return BiliCoinLikePage(items: items, count: _toInt(data['count']));
    } catch (e) {
      lastErrorDetail = L10n.current.commentException('$e');
      debugPrint('[UserSpace] 拉取投币/获赞列表异常: $e');
      return null;
    }
  }

                                          
                                             
                                          

                                                               
     
                                                               
                               
  static Future<BiliRelationListPage?> fetchFollowings({
    required int mid,
    int pn = 1,
    String orderType = '',
    int tagid = 0,
  }) async {
    try {
      final data = await _getJson(
        'https://api.bilibili.com/x/relation/followings',
        {
          'vmid': mid.toString(),
          'pn': pn.toString(),
          'ps': '20',
          'order': 'desc',
          'order_type': orderType,
          if (tagid > 0) 'tagid': tagid.toString(),
        },
      );
      if (data == null) {
        lastErrorDetail = L10n.current.biliResponseNoData;
        return null;
      }
      lastErrorDetail = null;
      return BiliRelationListPage(
        users: (data['list'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(BiliRelationUser.fromJson)
            .toList(),
        total: _toInt(data['total']),
      );
    } catch (e) {
      lastErrorDetail = L10n.current.commentException('$e');
      debugPrint('[UserSpace] 拉取关注列表异常: $e');
      return null;
    }
  }

                                                                    

                                                              
     
                                                               
                                                    
  static Future<bool> _spacePost(
    String path,
    Map<String, String> body,
  ) async {
    try {
      final account = BilibiliAccountService.instance;
      if (!account.isLoggedIn) return false;
      final rawCookie = account.cookieHeaderFor(
        BiliCookieScope.interactions,
      )?['Cookie'];
      if (rawCookie == null || rawCookie.isEmpty) return false;
      final csrf = _extractCookieValue(rawCookie, 'bili_jct');
      if (csrf.isEmpty) return false;
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse('https://api.bilibili.com$path'),
            headers: {
              ..._defaultHeaders,
              'Origin': 'https://space.bilibili.com',
              'Cookie': rawCookie,
              'Content-Type': 'application/x-www-form-urlencoded',
              ...NetworkSettingsService.instance.apiHeaders,
            },
            body: {...body, 'csrf': csrf},
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return false;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        debugPrint('[UserSpace] $path code=${json['code']}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[UserSpace] $path 异常: $e');
      return false;
    }
  }

                                            
     
                                                
                        
  static Future<List<BiliFollowTag>?> fetchFollowTags() async {
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            Uri.parse('https://api.bilibili.com/x/relation/tags'),
            headers: await _buildHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;
      final data = json['data'];
      if (data is! List) return null;
      return data
          .whereType<Map<String, dynamic>>()
          .map(BiliFollowTag.fromJson)
          .where((t) => t.tagid > 0)
          .toList();
    } catch (e) {
      debugPrint('[UserSpace] 拉取关注分组异常: $e');
      return null;
    }
  }

                                    
  static Future<bool> createFollowTag(String name) async {
    if (name.trim().isEmpty) return false;
    return _spacePost('/x/relation/tag/create', {'tag': name.trim()});
  }

                                     
  static Future<bool> renameFollowTag(int tagid, String name) async {
    if (tagid <= 0 || name.trim().isEmpty) return false;
    return _spacePost(
      '/x/relation/tag/update',
      {'tagid': tagid.toString(), 'tag': name.trim()},
    );
  }

                                                    
  static Future<bool> deleteFollowTag(int tagid) async {
    if (tagid <= 0) return false;
    return _spacePost('/x/relation/tag/del', {'tagid': tagid.toString()});
  }

                                                             
                                                                    
  static Future<bool> addUsersToTag(int tagid, List<int> fids) async {
    if (tagid <= 0 || fids.isEmpty) return false;
    return _spacePost(
      '/x/relation/tags/addUsers',
      {'tagids': tagid.toString(), 'fids': fids.join(',')},
    );
  }

                                                       
  static Future<bool> sortFollowTags(List<int> tagids) async {
    if (tagids.isEmpty) return false;
    return _spacePost(
      '/x/relation/tags/update_sort',
      {'tagids': tagids.join(',')},
    );
  }

                                                         
  static Future<BiliRelationListPage?> searchFollowings({
    required String name,
    int pn = 1,
  }) async {
    final mid = BilibiliAccountService.instance.mid;
    if (mid <= 0 || name.trim().isEmpty) {
      lastErrorDetail = L10n.current.searchKeywordEmpty;
      return null;
    }
    try {
      final params = await WbiSign.sign({
        'vmid': mid.toString(),
        'pn': pn.toString(),
        'ps': '20',
        'order': 'desc',
        'order_type': 'attention',
        'gaia_source': 'main_web',
        'name': name.trim(),
        'web_location': '333.999',
      });
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            Uri.parse(
              'https://api.bilibili.com/x/relation/followings/search',
            ).replace(queryParameters: params),
            headers: await _buildHeaders(),
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        return null;
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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
      return BiliRelationListPage(
        users: (data['list'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(BiliRelationUser.fromJson)
            .toList(),
        total: _toInt(data['total']),
      );
    } catch (e) {
      lastErrorDetail = L10n.current.commentException('$e');
      debugPrint('[UserSpace] 关注搜索异常: $e');
      return null;
    }
  }

                                                                     

                                                      
     
                                         
                               
  static Future<Map<String, int>?> fetchSpacePrivacy() async {
    final mid = BilibiliAccountService.instance.mid;
    if (mid <= 0) {
      lastErrorDetail = L10n.current.biliAccountNotLoggedIn;
      return null;
    }
    try {
      final data = await _getJson('https://api.bilibili.com/x/space/setting/app', {
        'mid': mid.toString(),
      });
      if (data == null) {
        lastErrorDetail ??= L10n.current.biliResponseNoData;
        return null;
      }
      final privacy = _asMap(data['privacy']);
      if (privacy == null) {
        lastErrorDetail = L10n.current.biliResponseNoData;
        return null;
      }
      lastErrorDetail = null;
      return privacy.map(
        (k, v) => MapEntry(k, v is num ? v.toInt() : int.tryParse('$v') ?? 0),
      );
    } catch (e) {
      lastErrorDetail = L10n.current.commentException('$e');
      debugPrint('[UserSpace] 读取空间隐私异常: $e');
      return null;
    }
  }

                                                            
     
                                    
  static Future<bool> saveSpacePrivacyItem(String key, int value) =>
      _spacePost('/x/space/privacy/batch/modify', {key: value.toString()});

                              
  static Future<BiliRelationListPage?> fetchFans({
    required int mid,
    int pn = 1,
  }) async {
    try {
      final data = await _getJson('https://api.bilibili.com/x/relation/fans', {
        'vmid': mid.toString(),
        'pn': pn.toString(),
        'ps': '20',
        'order': 'desc',
      });
      if (data == null) {
        lastErrorDetail = L10n.current.biliResponseNoData;
        return null;
      }
      lastErrorDetail = null;
      return BiliRelationListPage(
        users: (data['list'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(BiliRelationUser.fromJson)
            .toList(),
        total: _toInt(data['total']),
      );
    } catch (e) {
      lastErrorDetail = L10n.current.commentException('$e');
      debugPrint('[UserSpace] 拉取粉丝列表异常: $e');
      return null;
    }
  }
}

                                            
                                            
  
                                               
                                                                 
                                           

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
                                          
                                                      
                                        
                                        
    return String.fromCharCodes(
      _mixinKeyEncTab.map((i) => i < codeUnits.length ? codeUnits[i] : 0x30),
    );
  }

                                      
     
                                                  
                                     
                                            
  static Future<String> _fetchMixinKey() async {
    try {
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
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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
    } catch (e) {
      if (kDebugMode) debugPrint('[WbiSign] 获取 mixinKey 失败: $e');
      return '';
    }
  }

                                  
  static Future<String>? _keyFuture;

                                               
  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

                                        
  static Future<String?> _readDiskKey(String dateKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('wbi_key_date') != dateKey) return null;
      final key = prefs.getString('wbi_mixin_key');
      return (key == null || key.isEmpty) ? null : key;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeDiskKey(String dateKey, String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wbi_key_date', dateKey);
      await prefs.setString('wbi_mixin_key', key);
    } catch (_) {
                          
    }
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
                                       
                                         
                             
    final dateKey = _dateKey(today);
    final disk = await _readDiskKey(dateKey);
    if (disk != null) {
      _mixinKey = disk;
      _keyDate = today;
      return disk;
    }
                                               
    final key = await (_keyFuture ??= _fetchMixinKey());
    if (key.isEmpty) {
      _keyFuture = null;          
      return cached ?? '';
    }
    _mixinKey = key;
    _keyDate = today;
    await _writeDiskKey(dateKey, key);
    return key;
  }

                           
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

                                            
            
                                            

                                    
                                                  
                   
class DynamicDetailCache {
  static const String cacheDirName = 'dynamic_detail_cache';

                                
  static const Duration ttl = Duration(hours: 24);

                     
  static const int _maxCacheFiles = 200;

                                        
  static Future<Directory> get cacheDir async {
    final appDir = await AppCacheDirs.root();
    final dir = Directory('${appDir.path}/$cacheDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

                         
  static String cacheKey(String id) =>
      md5.convert(utf8.encode(id.trim())).toString();

  static Future<File> _cacheFile(String id) async {
    final dir = await cacheDir;
    return File('${dir.path}/${cacheKey(id)}.json');
  }

                                     
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

                 
  static Future<void> clearAll() async {
    try {
      final dir = await cacheDir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

                                         
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

                 
  static Future<void> deleteOne(String id) async {
    try {
      final file = await _cacheFile(id);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

                       
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
