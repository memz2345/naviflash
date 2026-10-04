                                           
  
                                               
                                                       
                                                                  
                                           
                                                                
                                                       
                                  

import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_comment_service.dart' as comment_svc;
import 'package:naviflash/services/bilibili_user_space_service.dart'
    show WbiSign, BilibiliUserSpaceService;
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/player_settings_service.dart';
import 'package:naviflash/services/video_cache_service.dart';
import 'package:naviflash/utils/recommend_filter.dart';

export 'package:naviflash/services/bilibili_comment_service.dart' show BiliComment;

                                            
                        
                                            

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

                      
class _CacheEntry<T> {
  final T? data;
  final DateTime time;
  _CacheEntry({required this.data}) : time = DateTime.now();
}

                                            
           
                                            

          
class BiliVideoPage {
  final int cid;
  final int page;               
  final String part;         
  final int duration;     

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
  final String pic;      
  final int pubdate;
  final int duration;          
  final String ownerName;
  final int ownerMid;
  final String ownerFace;

                                                          
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

                                                
                                           
  final bool isSteinGate;

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
    this.isSteinGate = false,
  });

  factory BiliVideoDetail.fromJson(Map<String, dynamic> json) {
    final owner = _asMap(json['owner']) ?? const <String, dynamic>{};
    final stat = _asMap(json['stat']) ?? const <String, dynamic>{};
    final rights = _asMap(json['rights']) ?? const <String, dynamic>{};
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
      isSteinGate: _toInt(rights['is_stein_gate']) == 1,
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

              
class BiliQuality {
  final int qn;
  final String label;

                                                                
  final List<String> codecs;

  const BiliQuality({
    required this.qn,
    required this.label,
    this.codecs = const [],
  });
}

                         
class BiliCdnMirror {
  final String label;
  final String host;

  const BiliCdnMirror({required this.label, required this.host});
}

                                             
                                               
                                               
const List<BiliCdnMirror> kBiliCdnMirrors = [
        
  BiliCdnMirror(label: '阿里云', host: 'upos-sz-mirrorali.bilivideo.com'),
  BiliCdnMirror(label: '阿里云 B', host: 'upos-sz-mirroralib.bilivideo.com'),
  BiliCdnMirror(label: '阿里云 O1', host: 'upos-sz-mirroralio1.bilivideo.com'),
        
  BiliCdnMirror(label: '腾讯云', host: 'upos-sz-mirrorcos.bilivideo.com'),
  BiliCdnMirror(label: '腾讯云 B', host: 'upos-sz-mirrorcosb.bilivideo.com'),
  BiliCdnMirror(label: '腾讯云 O1', host: 'upos-sz-mirrorcoso1.bilivideo.com'),
                
  BiliCdnMirror(label: '华为云', host: 'upos-sz-mirrorhw.bilivideo.com'),
  BiliCdnMirror(label: '华为云 B', host: 'upos-sz-mirrorhwb.bilivideo.com'),
  BiliCdnMirror(label: '华为云 O1', host: 'upos-sz-mirrorhwo1.bilivideo.com'),
  BiliCdnMirror(label: '华为云 08C', host: 'upos-sz-mirror08c.bilivideo.com'),
  BiliCdnMirror(label: '华为云 08H', host: 'upos-sz-mirror08h.bilivideo.com'),
  BiliCdnMirror(label: '华为云 08CT', host: 'upos-sz-mirror08ct.bilivideo.com'),
       
  BiliCdnMirror(label: '腾讯云 中转', host: 'upos-tf-all-tx.bilivideo.com'),
  BiliCdnMirror(label: '华为云 中转', host: 'upos-tf-all-hw.bilivideo.com'),
       
  BiliCdnMirror(label: '阿里云 海外', host: 'upos-sz-mirroraliov.bilivideo.com'),
  BiliCdnMirror(label: '腾讯云 海外', host: 'upos-sz-mirrorcosov.bilivideo.com'),
  BiliCdnMirror(label: '华为云 海外', host: 'upos-sz-mirrorhwov.bilivideo.com'),
  BiliCdnMirror(label: 'Akamai 海外', host: 'upos-hz-mirrorakam.akamaized.net'),
  BiliCdnMirror(label: 'B站 香港', host: 'cn-hk-eq-bcache-01.bilivideo.com'),
];

                                         
                                                      
                    
const List<BiliQuality> kBiliQualityPresets = [
  BiliQuality(qn: 127, label: '8K 超高清'),
  BiliQuality(qn: 126, label: '杜比视界'),
  BiliQuality(qn: 125, label: 'HDR 真彩'),
  BiliQuality(qn: 120, label: '4K 超清'),
  BiliQuality(qn: 116, label: '1080P60 高帧率'),
  BiliQuality(qn: 112, label: '1080P+ 高码率'),
  BiliQuality(qn: 100, label: '智能修复'),
  BiliQuality(qn: 80, label: '1080P 高清'),
  BiliQuality(qn: 74, label: '720P60 高帧率'),
  BiliQuality(qn: 64, label: '720P 高清'),
  BiliQuality(qn: 32, label: '480P 清晰'),
  BiliQuality(qn: 16, label: '360P 流畅'),
];

                                                  
                                           
                           
const Map<int, String> kBiliAudioQualityNames = {
  30216: '64K',
  30232: '132K',
  30280: '192K 高码率',
  30250: '杜比全景声',
  30251: 'Hi-Res 无损',
};

            
   
                                                              
                                            
                                                               
                                                             
                                                          
                                                       
                                
                                            
class BiliSubtitle {
  final String lan;
  final String lanDoc;
  final String url;

                                                   
                                              
  final String urlV2;

                                      
  final bool isAi;

  const BiliSubtitle({
    required this.lan,
    required this.lanDoc,
    required this.url,
    this.urlV2 = '',
    this.isAi = false,
  });

  factory BiliSubtitle.fromJson(Map<String, dynamic> json) {
    final isAi = _toInt(json['type']) == 1;
    var doc = _toStr(json['lan_doc'] ?? json['lan_doc_brief']);
                                                     
                                                      
    if (doc.isEmpty) doc = isAi ? 'AI' : _toStr(json['lan']);
    return BiliSubtitle(
      lan: _toStr(json['lan']),
      lanDoc: doc,
      url: _normalizeSubtitleUrl(_toStr(json['subtitle_url'])),
      urlV2: _normalizeSubtitleUrl(_toStr(json['subtitle_url_v2'])),
      isAi: isAi,
    );
  }

                                                        
  static int compare(BiliSubtitle a, BiliSubtitle b) {
    final aZh = a.lan.contains('zh');
    final bZh = b.lan.contains('zh');
    if (aZh != bZh) return aZh ? -1 : 1;
    if (a.isAi != b.isAi) return a.isAi ? 1 : -1;
    return 0;
  }
}

                                                        
String _normalizeSubtitleUrl(String raw) {
  var url = raw.trim();
  if (url.isEmpty) return '';
  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('http://')) return 'https://${url.substring(7)}';
  return url;
}

                                            
class BiliSubtitleCue {
  final double from;
  final double to;
  final String content;

  const BiliSubtitleCue({
    required this.from,
    required this.to,
    required this.content,
  });

                          
  static BiliSubtitleCue? fromJson(Map<dynamic, dynamic> json) {
    final from = (json['from'] as num?)?.toDouble();
    final to = (json['to'] as num?)?.toDouble();
    final content =
        (json['content'] as String?)?.replaceAll(RegExp(r'\s+'), ' ').trim() ??
        '';
    if (from == null || to == null || content.isEmpty) return null;
    return BiliSubtitleCue(from: from, to: to, content: content);
  }
}

                                                          
class BiliViewPoint {
                                   
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

                                                      
                                    
class BiliClipSegment {
                                                        
  final String type;
  final int startSec;
  final int endSec;

  const BiliClipSegment({
    required this.type,
    required this.startSec,
    required this.endSec,
  });

  bool get isIntro => type == 'CLIP_TYPE_OP';
  bool get isOutro => type == 'CLIP_TYPE_ED';

  factory BiliClipSegment.fromJson(Map<String, dynamic> json) {
    return BiliClipSegment(
      type: _toStr(json['clipType'] ?? json['clip_type']),
      startSec: _toInt(json['start']),
      endSec: _toInt(json['end']),
    );
  }
}

class BiliPlayUrl {
  final int quality;
  final List<BiliQuality> qualities;
  final List<BiliDashStream> videoStreams;
  final List<BiliDashStream> audioStreams;

                                               
                          
  final List<BiliDashStream> dolbyStreams;

                                                          
  final BiliDashStream? flacStream;

  final List<String> durlUrls;              
  final List<BiliSubtitle> subtitles;          
  final List<BiliClipSegment> clipSegments;                       

  const BiliPlayUrl({
    required this.quality,
    required this.qualities,
    required this.videoStreams,
    required this.audioStreams,
    required this.durlUrls,
    this.dolbyStreams = const [],
    this.flacStream,
    this.subtitles = const [],
    this.clipSegments = const [],
  });

  bool get hasDash => videoStreams.isNotEmpty && audioStreams.isNotEmpty;
  bool get hasDurl => durlUrls.isNotEmpty;

                                                              
                                              
                                               
  List<BiliDashStream> get allAudioStreams {
    final merged = <BiliDashStream>[...audioStreams];
    final seen = merged.map((s) => s.id).toSet();
    for (final s in dolbyStreams) {
      if (seen.add(s.id)) merged.add(s);
    }
    final flac = flacStream;
    if (flac != null && seen.add(flac.id)) merged.add(flac);
    return merged;
  }

                                        
               
  Set<int> get availableQns => videoStreams.map((s) => s.id).toSet();

                             
  bool isQualityAvailable(int qn) =>
      availableQns.contains(qn) || durlUrls.isNotEmpty;

                                                   
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

                                                                     
    final qualities = <BiliQuality>[];
    if (supportFormats.isNotEmpty) {
      for (final f in supportFormats) {
        final m = _asMap(f);
        if (m == null) continue;
        final qn = _toInt(m['quality']);
        if (qn <= 0) continue;
        final label = _toStr(m['new_description'] ?? m['display_desc']).trim();
        if (label.isEmpty) continue;
                                                        
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

                                                        
    final subtitleJson = _asMap(json['subtitle']);
    final subtitles = ((subtitleJson?['subtitles']) as List?) ?? const [];
    final subtitleList = subtitles
        .map((e) => BiliSubtitle.fromJson(_asMap(e) ?? const {}))
        .where((s) => s.url.isNotEmpty)
        .toList();

                                           
    final clipList = ((json['clip_info_list'] as List?) ?? const [])
        .map((e) => BiliClipSegment.fromJson(_asMap(e) ?? const {}))
        .where((c) => c.endSec > c.startSec)
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
      dolbyStreams:
          (_asMap(dash?['dolby'])?['audio'] as List?)
              ?.map((e) => BiliDashStream.fromJson(_asMap(e) ?? const {}))
              .toList() ??
          const [],
      flacStream: _asMap(dash?['flac'])?['audio'] == null
          ? null
          : BiliDashStream.fromJson(
              _asMap(_asMap(dash?['flac'])!['audio']) ?? const {},
            ),
      durlUrls: durl
          .map((e) => _toStr(_asMap(e)?['url']))
          .where((s) => s.isNotEmpty)
          .toList(),
      subtitles: subtitleList,
      clipSegments: clipList,
    );
  }
}

                                            
           
                                            

class BiliRelatedVideo {
  final String bvid;
  final String title;
  final String pic;
  final int pubdate;
  final int duration;
  final String ownerName;
  final int view;
  final int danmaku;

                                         
  final int like;

  const BiliRelatedVideo({
    required this.bvid,
    required this.title,
    required this.pic,
    required this.pubdate,
    required this.duration,
    required this.ownerName,
    required this.view,
    required this.danmaku,
    this.like = -1,
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
      like: stat['like'] == null ? -1 : _toInt(stat['like']),
    );
  }
}

           
class BiliVideoTag {
  final int id;
  final String name;
  final String type;                      

                                         
  final String musicId;

  const BiliVideoTag({
    required this.id,
    required this.name,
    required this.type,
    this.musicId = '',
  });

  factory BiliVideoTag.fromJson(Map<String, dynamic> json) {
    return BiliVideoTag(
      id: _toInt(json['tag_id']),
      name: _toStr(json['tag_name']),
      type: _toStr(json['tag_type'] ?? json['type']),
      musicId: _toStr(json['music_id']),
    );
  }
}

                           
class BiliAiPart {
  final int timestamp;
  final String content;

  const BiliAiPart({required this.timestamp, required this.content});
}

             
class BiliAiOutline {
  final String title;
  final List<BiliAiPart> parts;

  const BiliAiOutline({required this.title, required this.parts});
}

            
class BiliAiConclusion {
  final String summary;
  final List<BiliAiOutline> outline;

  const BiliAiConclusion({required this.summary, required this.outline});
}

                                            
                           
                                            

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

                            
class BiliVideoNotePage {
  final List<BiliVideoNote> list;
  final int total;

  const BiliVideoNotePage({required this.list, required this.total});
}

                                            
      
                                            

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

                                    
  static String? lastErrorDetail;

                                        
  static const Duration _cacheTtl = Duration(minutes: 10);
  static final Map<String, _CacheEntry<Object?>> _cache = {};

                                    
                                       
                                              
                             
  static const Duration _detailCacheTtl = Duration(hours: 6);
  static const Duration _playUrlCacheTtl = Duration(minutes: 70);

  static _CacheEntry<T> _cached<T>(String key) {
    final e = _cache[key];
    if (e == null) return _CacheEntry<T>(data: null);
    if (DateTime.now().difference(e.time) > _cacheTtl) {
      _cache.remove(key);
      return _CacheEntry<T>(data: null);
    }
                                     
    if (e is _CacheEntry<T>) return e;
    return _CacheEntry<T>(data: null);
  }

  static void _storeCache<T>(String key, T data) {
                                                                
                                                         
                                                                        
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

                                          
                              
  static Future<BiliVideoDetail?> fetchDetail(String bvid) async {
    final bv = bvid.trim();
    if (bv.isEmpty) {
      lastErrorDetail = 'BV 号为空';
      return null;
    }
    final cacheKey = 'detail_$bv';
                                
    final cached = await VideoJsonCache.load(cacheKey, ttl: _detailCacheTtl);
    if (cached != null) {
      lastErrorDetail = null;
      return BiliVideoDetail.fromJson(cached);
    }
             
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
        final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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
                     
      await VideoJsonCache.save(cacheKey, data);
      return BiliVideoDetail.fromJson(data);
    }
                               
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

                                      
                                                        
                                                                
     
                                                
                                             
  static Future<int> resolveDefaultQn() async {
    final settings = PlayerSettingsService.shared;
    final wifiQn = settings?.defaultQnWifi ?? 116;
    final cellularQn = settings?.defaultQnCellular ?? 80;
    try {
                                                                            
      final result = await Connectivity().checkConnectivity();
      bool has(ConnectivityResult r) => result.contains(r);
      final cellular =
          has(ConnectivityResult.mobile) || has(ConnectivityResult.bluetooth);
      final strongNet =
          has(ConnectivityResult.wifi) || has(ConnectivityResult.ethernet);
      if (cellular && !strongNet) return cellularQn;
      return wifiQn;
    } catch (e) {
      debugPrint('[BiliVideo] 网络类型检测失败，按 WiFi 默认画质处理: $e');
      return wifiQn;
    }
  }

                                             
                                                 
     
                                                   
                                     
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
                                       
                                             
    final effectiveQn = qn > 0 ? qn : await resolveDefaultQn();
    final cacheKey = 'play_${bv}_${cid}_$effectiveQn';
                                             
    final cached = await VideoJsonCache.load(cacheKey, ttl: _playUrlCacheTtl);
    if (cached != null) {
      lastErrorDetail = null;
      return BiliPlayUrl.fromJson(cached);
    }
             
    Map<String, dynamic>? data;
    String? netError;
    try {
      final params = await WbiSign.sign({
        'bvid': bv,
        'cid': cid.toString(),
        'qn': (effectiveQn > 0 ? effectiveQn : 80).toString(),
                                        
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
        final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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
                                          
      await VideoJsonCache.save(cacheKey, data);
      return BiliPlayUrl.fromJson(data);
    }
                           
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

                                     
                                      
  static Future<List<BiliRelatedVideo>> fetchRelated(
    String bvid, {
    bool forceRefresh = false,
  }) async {
    final bv = bvid.trim();
    if (bv.isEmpty) return const [];
    final key = 'rel_$bv';
    if (!forceRefresh) {
      final cached = _cached<List<BiliRelatedVideo>>(key);
      if (cached.data != null) return _filterRelated(cached.data!);
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
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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
      return _filterRelated(result);
    } catch (e) {
      lastErrorDetail = '$e';
      debugPrint('[BiliVideo] 拉取相关视频异常: $e');
      return const [];
    }
  }

                                               
     
                                            
                               
  static List<BiliRelatedVideo> _filterRelated(List<BiliRelatedVideo> list) {
    if (!RecommendFilter.applyToRelatedVideos) return list;
    return list
        .where(
          (v) => !RecommendFilter.filterAll(
            title: v.title,
            duration: v.duration,
            like: v.like,
            view: v.view,
          ),
        )
        .toList();
  }

                                                          
                                        
                             
                                             
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

                                   
  static String _extractCookie(String cookie, String name) {
    final m = RegExp('(?:^|;\\s*)$name=([^;]+)').firstMatch(cookie);
    return m?.group(1) ?? '';
  }

                                   
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
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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

                       
                                           
                                
     
                                                               
                                            
     
                                                                
                                         
                                     
     
                                                    
                                                 
     
                                                                
                                                 
                            
  static String? buildPlayableUrl(
    BiliPlayUrl info, {
    int? quality,
    List<String>? preferCodecs,
    int sourceIndex = 0,
    String? sourceHost,
    int? audioId,
  }) {
    if (info.hasDash) {
      final video = pickVideoStream(
        info,
        quality: quality,
        preferCodecs: preferCodecs,
      );
      if (video == null) return null;
      final audio = pickAudioStream(info, audioId: audioId);
      final vUrl = _urlAt(video, sourceIndex, host: sourceHost);
      if (vUrl.isEmpty) return null;
      if (audio == null) return vUrl;
      final aUrl = _urlAt(audio, sourceIndex, host: sourceHost);
      if (aUrl.isEmpty) return vUrl;
                                                       
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

                                        
                                     
                                                  
                                     
  static String? buildAudioUrl(
    BiliPlayUrl info, {
    int sourceIndex = 0,
    String? sourceHost,
  }) {
    if (info.audioStreams.isNotEmpty) {
      final audio = info.audioStreams.reduce(
        (a, b) => a.bandwidth > b.bandwidth ? a : b,
      );
      final u = _urlAt(audio, sourceIndex, host: sourceHost);
      if (u.isNotEmpty) return u;
    }
    if (info.hasDurl) {
      var u =
          info.durlUrls[sourceIndex < info.durlUrls.length ? sourceIndex : 0];
      if (sourceHost != null && sourceHost.isNotEmpty) {
        try {
          u = Uri.parse(u).replace(host: sourceHost).toString();
        } catch (_) {}
      }
      return u;
    }
    return null;
  }

                                                               
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

                                             
                                           
     
                                               
                                      
  static BiliDashStream? pickAudioStream(BiliPlayUrl info, {int? audioId}) {
    final all = info.allAudioStreams;
    if (all.isEmpty) return null;
    if (audioId != null && audioId > 0) {
      for (final s in all) {
        if (s.id == audioId) return s;
      }
    }
    return all.reduce((a, b) => a.bandwidth > b.bandwidth ? a : b);
  }

                                            
                                             
  static String audioQualityLabel(
    int id, {
    int bandwidth = 0,
    int index = 0,
  }) {
    final known = kBiliAudioQualityNames[id];
    if (known != null) return known;
    final kbps = (bandwidth / 1000).round();
    final rate = kbps > 0 ? '（码率 $kbps kbps）' : '';
    return '音轨 ${index + 1}$rate';
  }

                            
  static String audioQualityShortLabel(
    int id, {
    int bandwidth = 0,
    int index = 0,
  }) {
    switch (id) {
      case 30216:
        return '64K';
      case 30232:
        return '132K';
      case 30280:
        return '192K';
      case 30250:
        return '杜比';
      case 30251:
        return 'Hi-Res';
    }
    return '音轨${index + 1}';
  }

                                                     
                                    
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

                             
     
                                                           
                                          
                          
                                                      
                                                        
                                                         
  static Future<List<BiliSubtitle>> fetchSubtitles({
    required String bvid,
    required int aid,
    required int cid,
  }) async {
    if (cid <= 0) return const [];
    final fromPlayerInfo = await _fetchSubtitlesFromPlayerInfo(
      bvid: bvid,
      aid: aid,
      cid: cid,
    );
    if (fromPlayerInfo.isNotEmpty) return fromPlayerInfo;
    return _fetchSubtitlesFromDmView(aid: aid, cid: cid);
  }

  static List<BiliSubtitle> _parseSubtitleList(dynamic raw) {
    final list = raw is List ? raw : const <dynamic>[];
    final out = <BiliSubtitle>[];
    final seen = <String>{};
    for (final e in list) {
      final m = _asMap(e);
      if (m == null) continue;
      final sub = BiliSubtitle.fromJson(m);
                                  
      if (sub.url.isEmpty || !seen.add(sub.lan)) continue;
      out.add(sub);
    }
    out.sort(BiliSubtitle.compare);
    return out;
  }

  static Future<List<BiliSubtitle>> _fetchSubtitlesFromPlayerInfo({
    required String bvid,
    required int aid,
    required int cid,
  }) async {
    try {
      final params = await WbiSign.sign({
        if (aid > 0) 'aid': '$aid',
        if (bvid.isNotEmpty) 'bvid': bvid,
        'cid': '$cid',
      });
      final uri = Uri.https(
        'api.bilibili.com',
        '/x/player/wbi/v2',
        params.map((k, v) => MapEntry(k, v)),
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        debugPrint('[BiliVideo] player/v2 HTTP ${resp.statusCode}');
        return const [];
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (_toInt(_asMap(json)?['code']) != 0) return const [];
      final data = _asMap(_asMap(json)?['data']);
      return _parseSubtitleList(_asMap(data?['subtitle'])?['subtitles']);
    } catch (e) {
      debugPrint('[BiliVideo] player/v2 字幕异常: $e');
      return const [];
    }
  }

                                                      
                                     
                                                 
  static Future<List<BiliSubtitle>> _fetchSubtitlesFromDmView({
    required int aid,
    required int cid,
  }) async {
    try {
      final uri = Uri.parse('https://api.bilibili.com/x/v2/dm/view').replace(
        queryParameters: {'type': '1', 'oid': '$cid', 'pid': '$aid'},
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return const [];
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (_toInt(_asMap(json)?['code']) != 0) return const [];
      final data = _asMap(_asMap(json)?['data']);
      return _parseSubtitleList(_asMap(data?['subtitle'])?['subtitles']);
    } catch (e) {
      debugPrint('[BiliVideo] dm view 字幕异常: $e');
      return const [];
    }
  }

                                    
     
                                                             
                                      
  static Future<String?> fetchSubtitleSrtText(String subtitleUrl) async {
    final url = _normalizeSubtitleUrl(subtitleUrl);
    if (url.isEmpty) return null;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(url), headers: _headers())
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        debugPrint('[BiliVideo] subtitle HTTP ${resp.statusCode}');
        return null;
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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
      return sb.toString();
    } catch (e) {
      debugPrint('[BiliVideo] 拉取字幕异常: $e');
      return null;
    }
  }

                                      
                            
  static Future<String?> fetchSubtitleSrt(String subtitleUrl) async {
    final srt = await fetchSubtitleSrtText(subtitleUrl);
    if (srt == null) return null;
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/navi_bili_sub_'
        '${DateTime.now().millisecondsSinceEpoch}.srt',
      );
      await file.writeAsString(srt, encoding: utf8);
      return file.path;
    } catch (e) {
      debugPrint('[BiliVideo] 写字幕文件异常: $e');
      return null;
    }
  }

                                      
  static Future<List<BiliSubtitleCue>?> fetchSubtitleCues(
    String subtitleUrl,
  ) async {
    final url = _normalizeSubtitleUrl(subtitleUrl);
    if (url.isEmpty) return null;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(url), headers: _headers())
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      final body = json['body'];
      if (body is! List) return null;
      final cues = <BiliSubtitleCue>[];
      for (final item in body) {
        final m = item is Map ? item : const <dynamic, dynamic>{};
        final cue = BiliSubtitleCue.fromJson(m);
        if (cue != null) cues.add(cue);
      }
      if (cues.isEmpty) return null;
      cues.sort((a, b) => a.from.compareTo(b.from));
      return cues;
    } catch (e) {
      debugPrint('[BiliVideo] 拉取字幕数据异常: $e');
      return null;
    }
  }

                                 
     
                                         
          
            
       
                                   
          
          
         
                               
  static String buildBilingualSrt({
    required List<BiliSubtitleCue> primary,
    required List<BiliSubtitleCue> second,
  }) {
    if (primary.isEmpty) return '';
    final secondSorted = [...second]
      ..sort((a, b) => a.from.compareTo(b.from));
    final sb = StringBuffer();
    var index = 1;
    for (final p in primary) {
                                         
                                   
      BiliSubtitleCue? trans;
      var bestDist = double.infinity;
      for (final s in secondSorted) {
        if (s.from > p.to + 3.0) break;
        final overlaps = s.to >= p.from - 0.5 && s.from <= p.to + 0.5;
        final near = (s.from - p.from).abs() < 3.0;
        if (!overlaps && !near) continue;
        final dist = (s.from - p.from).abs();
        if (dist < bestDist) {
          bestDist = dist;
          trans = s;
        }
      }
      sb
        ..writeln(index)
        ..writeln('${_srtTimecode(p.from)} --> ${_srtTimecode(p.to)}');
      sb.writeln(p.content);
      if (trans != null &&
          trans.content.isNotEmpty &&
          trans.content.trim() != p.content.trim()) {
        sb.writeln(trans.content);
      }
      sb.writeln();
      index++;
    }
    return sb.toString();
  }

                               
  static Future<String?> writeSrtToTemp(
    String content, {
    String tag = 'navi_bili_bilingual',
  }) async {
    if (content.trim().isEmpty) return null;
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/${tag}_${DateTime.now().millisecondsSinceEpoch}.srt',
      );
      await file.writeAsString(content, encoding: utf8);
      return file.path;
    } catch (e) {
      debugPrint('[BiliVideo] 写字幕临时文件异常: $e');
      return null;
    }
  }

                                               
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
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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

                                                               
     
                                                  
  static Future<({BiliAiConclusion? data, String message})> fetchAiConclusion({
    required String bvid,
    required int cid,
    int? upMid,
  }) async {
    if (bvid.isEmpty || cid <= 0) {
      return (data: null, message: '参数不完整');
    }
    try {
      final params = await WbiSign.sign({
        'bvid': bvid,
        'cid': cid.toString(),
        if (upMid != null && upMid > 0) 'up_mid': upMid.toString(),
      });
      final uri = Uri.parse(
        'https://api.bilibili.com/x/web-interface/view/conclusion/get',
      ).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        return (data: null, message: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> || _toInt(json['code']) != 0) {
        final msg = json is Map ? _toStr(json['message']) : '';
        return (data: null, message: msg.isEmpty ? 'AI 总结获取失败' : msg);
      }
      final data = _asMap(json['data']);
      final dataCode = _toInt(data?['code']);
      if (dataCode != 0) {
        return (
          data: null,
          message: dataCode == 1 ? 'AI 正在处理中，请稍后再试' : '当前视频暂不支持 AI 总结',
        );
      }
      final result = _asMap(data?['model_result']);
      if (result == null) {
        return (data: null, message: '当前视频暂不支持 AI 总结');
      }
      final summary = _toStr(result['summary']);
      final outline = <BiliAiOutline>[];
      final rawOutline = result['outline'];
      if (rawOutline is List) {
        for (final o in rawOutline.whereType<Map<String, dynamic>>()) {
          final parts = <BiliAiPart>[];
          final rawParts = o['part_outline'];
          if (rawParts is List) {
            for (final p in rawParts.whereType<Map<String, dynamic>>()) {
              parts.add(
                BiliAiPart(
                  timestamp: _toInt(p['timestamp']),
                  content: _toStr(p['content']),
                ),
              );
            }
          }
          outline.add(
            BiliAiOutline(title: _toStr(o['title']), parts: parts),
          );
        }
      }
      if (summary.isEmpty && outline.isEmpty) {
        return (data: null, message: '当前视频暂不支持 AI 总结');
      }
      return (
        data: BiliAiConclusion(summary: summary, outline: outline),
        message: '',
      );
    } catch (e) {
      debugPrint('[BiliVideo] AI 总结异常: $e');
      return (data: null, message: '网络异常：${e.runtimeType}');
    }
  }

                                                          
                                                     
     
                                                  
                                       
                                                          
  static Future<List<BiliVideoTag>> fetchVideoTags({
    required String bvid,
    required int aid,
    int? cid,
  }) async {
    if (bvid.isEmpty && aid <= 0) return const [];
    final key = 'tags_$bvid';
    final cached = _cached<List<BiliVideoTag>>(key);
    if (cached.data != null) return cached.data!;
    try {
      final uri = Uri.parse(
            'https://api.bilibili.com/x/web-interface/view/detail/tag',
          )
          .replace(
            queryParameters: {
              if (bvid.isNotEmpty) 'bvid': bvid,
              if (aid > 0) 'aid': aid.toString(),
              if (cid != null && cid > 0) 'cid': cid.toString(),
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
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        debugPrint('[BiliVideo] tags code=${json['code']} ${json['message']}');
        return const [];
      }
      final data = json['data'];
      final List tags = data is List
          ? data
          : (_asMap(data)?['tags'] as List? ?? const []);
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
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return 0;
      return _toInt(_asMap(json['data'])?['total']);
    } catch (e) {
      debugPrint('[BiliVideo] 拉取在线人数异常: $e');
      return 0;
    }
  }

                                                         
                                                
                                         
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
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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
