                                    
  
                                                 
                                                      
                                                 
  
       
                                                               
                                                                
  
      
                                                              
                                                                   
                                                        
                                                          
                                                                        
                                                               
                                                     
                                                            
                                                      
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:naviflash/screens/article_page.dart';
import 'package:naviflash/screens/bilibili_bangumi_page.dart';
import 'package:naviflash/screens/bilibili_live_room_page.dart';
import 'package:naviflash/screens/bilibili_search_page.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/screens/dynamic_detail_page.dart';
import 'package:naviflash/widgets/frosted_route.dart';

import 'bv_av.dart';
import 'link_utils.dart';

                                           
                              
                                           

           
sealed class BiliUriTarget {
  const BiliUriTarget();
}

                              
final class VideoTarget extends BiliUriTarget {
  const VideoTarget({
    this.bvid,
    this.aid,
    this.cid,
    this.part,
    this.progress,
    this.commentRootId,
    this.commentSecondaryId,
  });

  final String? bvid;

  final int? aid;

                                        
  final int? cid;

                                      
  final int? part;

                                                        
  final Duration? progress;

                               
  final int? commentRootId;

  final int? commentSecondaryId;
}

                                      
final class BangumiTarget extends BiliUriTarget {
  const BangumiTarget({this.seasonId, this.epId});

  final int? seasonId;
  final int? epId;
}

final class SpaceTarget extends BiliUriTarget {
  const SpaceTarget(this.mid);

  final int mid;
}

final class LiveTarget extends BiliUriTarget {
  const LiveTarget(this.roomId);

  final int roomId;
}

final class ArticleTarget extends BiliUriTarget {
  const ArticleTarget(this.cvid);

  final int cvid;
}

final class DynamicTarget extends BiliUriTarget {
  const DynamicTarget(this.id);

  final String id;
}

final class SearchTarget extends BiliUriTarget {
  const SearchTarget(this.keyword);

  final String keyword;
}

                                             
final class WebTarget extends BiliUriTarget {
  const WebTarget(this.url);

  final String url;
}

                                           
           
                                           

final RegExp _schemePrefix = RegExp(r'^\S+://');
                                             
                                  
final RegExp _bvRegExp = RegExp(r'[Bb][Vv]1[0-9A-Za-z]{9}');
final RegExp _avRegExp = RegExp(r'av(\d+)', caseSensitive: false);
final RegExp _digitsRegExp = RegExp(r'/(\d+)');

                                              
const Set<String> _nativeHosts = <String>{
  'video',
  'bangumi',
  'pgc',
  'space',
  'live',
  'article',
  'opus',
  'dynamic',
  'following',
  'search',
  'read',
  'root',
};

                                                      
BiliUriTarget parseBiliUri(String uri) {
  final raw = uri.trim();
  if (raw.isEmpty || raw.startsWith('?')) return const WebTarget('');

                                                            
                                        
  var normalized = raw;
  if (normalized.startsWith('//')) {
    normalized = 'https:$normalized';
  } else if (!_schemePrefix.hasMatch(normalized)) {
    normalized = 'https://$normalized';
  }

  final parsed = Uri.tryParse(normalized);
  if (parsed == null) return WebTarget(normalized);

                                                 
  final uri0 = _restoreAwakenedScheme(parsed) ?? parsed;

  final scheme = uri0.scheme.toLowerCase();
  if (scheme == 'bilibili') return _parseNativeScheme(uri0);
  if (scheme == 'http' || scheme == 'https') return _parseHttp(uri0);
                                                        
                                     
  return const WebTarget('');
}

                                                                
                                                                    
   
                                             
                        
Uri? _restoreAwakenedScheme(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  final host = uri.host;
                                                 
  if (host.isEmpty || host.contains('.')) return null;
                                                         
                                 
  final segs = uri.pathSegments.where((String e) => e.isNotEmpty).toList();
  if (segs.isEmpty || !_nativeHosts.contains(segs.first.toLowerCase())) {
    return null;
  }
  final query = uri.hasQuery ? '?${uri.query}' : '';
  return Uri.tryParse('bilibili://${segs.join('/')}$query');
}

                          
   
                                                                  
                                                           
                                                  
BiliUriTarget _parseNativeScheme(Uri uri) {
  final host = uri.host.toLowerCase();
  final segs = uri.pathSegments.where((String e) => e.isNotEmpty).toList();
  final query = uri.queryParameters;
  String? seg(int i) => i < segs.length ? segs[i] : null;
  int? digitsOf(String? s) =>
      s == null ? null : int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), ''));

  switch (host) {
    case 'video':
                                                       
      final id = _matchVideoId(uri.path) ?? _aidFromDigits(uri.path);
      if (id == null) return const WebTarget('');
      return _videoTarget(id, query);
    case 'bangumi' || 'pgc':
                                                                     
      final raw = (seg(0) == 'season' || seg(0) == 'ep') ? seg(1) : seg(0);
      final ssid = digitsOf(raw);
      if (ssid == null || ssid <= 0) return const WebTarget('');
      return BangumiTarget(seasonId: ssid);
    case 'space':
      final mid = int.tryParse(seg(0) ?? '');
      if (mid == null || mid <= 0) return const WebTarget('');
      return SpaceTarget(mid);
    case 'article' || 'opus':
      final cvid = digitsOf(seg(0));
      if (cvid == null || cvid <= 0) return const WebTarget('');
      return ArticleTarget(cvid);
    case 'dynamic' || 't':
      final id = seg(0);
      if (id == null || id.isEmpty) return const WebTarget('');
      return DynamicTarget(id);
    case 'following':
                                                                      
      final dynId = seg(1);
      if (dynId == null || dynId.isEmpty) return const WebTarget('');
      return DynamicTarget(dynId);
    case 'live':
      final roomId = digitsOf(seg(0));
      if (roomId == null || roomId <= 0) return const WebTarget('');
      return LiveTarget(roomId);
    default:
      return const WebTarget('');
  }
}

                                              
BiliUriTarget _parseHttp(Uri uri) {
  final host = uri.host.toLowerCase();
  final segs = uri.pathSegments.where((String e) => e.isNotEmpty).toList();
  final web = WebTarget(uri.toString());

  if (host.endsWith('t.bilibili.com')) {
    final id = segs.isEmpty ? '' : segs.first;
    return id.isEmpty ? web : DynamicTarget(id);
  }
  if (host.endsWith('live.bilibili.com')) {
    final roomId = _firstInt(uri.path);
    return roomId == null ? web : LiveTarget(roomId);
  }
  if (host.endsWith('space.bilibili.com')) {
    final mid = _firstInt(uri.path);
    return mid == null ? web : SpaceTarget(mid);
  }
  if (host.endsWith('search.bilibili.com')) {
    final keyword = uri.queryParameters['keyword'];
    return (keyword == null || keyword.isEmpty) ? web : SearchTarget(keyword);
  }

                                        
                                        
  final isBili = host.contains('bilibili.com') ||
      host.contains('bilibili.cn') ||
      host.contains('bilibili.tv');
  if (!isBili || host.endsWith('b23.tv')) return web;

                                               
  final first = segs.isEmpty ? '' : segs.first;
  final area = (first == 'mobile' || first == 'h5' || first == 'v')
      ? (segs.length > 1 ? segs[1] : '')
      : first;

  switch (area) {
    case 'video':
      final id = _matchVideoId(uri.path) ?? _aidFromDigits(uri.path);
      if (id == null) return web;
      return _videoTarget(id, uri.queryParameters);
    case 'bangumi':
      final ssid = _intOf(uri.path, RegExp(r'/ss(\d+)', caseSensitive: false));
      final mdid = _intOf(uri.path, RegExp(r'/md(\d+)', caseSensitive: false));
      final epid = _intOf(uri.path, RegExp(r'/ep(\d+)', caseSensitive: false));
      final seasonId = ssid ?? mdid;
                                                          
                                      
      if (seasonId == null) return web;
      return BangumiTarget(seasonId: seasonId, epId: epid);
    case 'read' || 'note' || 'note-app':
      final cvid =
          _intOf(uri.path, RegExp(r'/cv(\d+)', caseSensitive: false)) ??
          int.tryParse(uri.queryParameters['cvid'] ?? '');
      return cvid == null ? web : ArticleTarget(cvid);
    case 'opus' || 'dynamic':
      final id = _firstInt(uri.path);
      return id == null ? web : DynamicTarget('$id');
    default:
      return web;
  }
}

                    
({int? aid, String? bvid})? _matchVideoId(String path) {
  final bv = _bvRegExp.firstMatch(path)?.group(0);
  if (bv != null) return (aid: null, bvid: 'BV${bv.substring(2)}');
  final av = _avRegExp.firstMatch(path)?.group(1);
  if (av != null) {
    final aid = int.tryParse(av);
    if (aid != null && aid > 0) return (aid: aid, bvid: null);
  }
  return null;
}

                                                           
({int? aid, String? bvid})? _aidFromDigits(String path) {
  final aid = _firstInt(path);
  return aid == null ? null : (aid: aid, bvid: null);
}

int? _firstInt(String path) =>
    int.tryParse(_digitsRegExp.firstMatch(path)?.group(1) ?? '');

int? _intOf(String path, RegExp re) =>
    int.tryParse(re.firstMatch(path)?.group(1) ?? '');

                                         
VideoTarget _videoTarget(
  ({int? aid, String? bvid}) id,
  Map<String, String> query,
) {
  int? part;
  final p = int.tryParse(query['p'] ?? '');
                                
  if (p != null && p > 0) part = p - 1;
  final page = int.tryParse(query['page'] ?? '');
                                    
  if (page != null && page >= 0) part = page;
  return VideoTarget(
    bvid: id.bvid,
    aid: id.aid,
    cid: int.tryParse(query['cid'] ?? ''),
    part: part,
    progress: _videoProgress(query),
    commentRootId: int.tryParse(query['comment_root_id'] ?? ''),
    commentSecondaryId: int.tryParse(query['comment_secondary_id'] ?? ''),
  );
}

                                                             
Duration? _videoProgress(Map<String, String> query) {
  final ms = int.tryParse(
    query['start_progress'] ?? query['dm_progress'] ?? '',
  );
  if (ms != null) return Duration(milliseconds: ms);
  final t = double.tryParse(query['t'] ?? '');
  if (t != null) return Duration(milliseconds: (t * 1000).round());
  return null;
}

                                           
           
                                           

                                               
bool openBiliUri(BuildContext context, String uri) {
  final target = parseBiliUri(uri);
  switch (target) {
    case VideoTarget():
      final String bvid;
      final tbv = target.bvid;
      if (tbv == null || tbv.isEmpty) {
                                                         
        final aid = target.aid;
        if (aid == null || aid <= 0) return false;
        final encoded = BvAv.encode(aid);                   
        if (encoded == null) return false;
        bvid = encoded;
      } else {
        bvid = tbv;
      }
      openBilibiliVideo(
        context,
        bvid: bvid,
        initialPosition: target.progress,
        initialCid: target.cid,
        initialPage: target.part,
        commentRootId: target.commentRootId,
        commentSecondaryId: target.commentSecondaryId,
      );
      return true;
    case BangumiTarget(:final seasonId):
                                                       
      if (seasonId == null || seasonId <= 0) return false;
      pushBangumi(context, seasonId);
      return true;
    case SpaceTarget(:final mid):
      pushUserSpace(context, mid);
      return true;
    case LiveTarget(:final roomId):
      pushLiveRoom(context, roomId);
      return true;
    case ArticleTarget(:final cvid):
      pushArticle(context, cvid);
      return true;
    case DynamicTarget(:final id):
      pushDynamic(context, id);
      return true;
    case SearchTarget(:final keyword):
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BilibiliSearchPage(
            initialKeyword: keyword,
            recordInitialKeyword: false,
          ),
        ),
      );
      return true;
    case WebTarget(:final url):
      if (url.isEmpty) return false;
      unawaited(openLinkInBuiltInBrowser(context, url: url, confirm: false));
      return true;
  }
}

                             

void pushBangumi(BuildContext context, int seasonId) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => BilibiliBangumiPage(seasonId: seasonId)),
  );
}

void pushUserSpace(BuildContext context, int mid) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => BilibiliUserSpacePage(mid: mid)));
}

void pushArticle(BuildContext context, int cvid) {
  Navigator.of(
    context,
  ).push(ImmersiveMaterialPageRoute(page: ArticlePage(cvid: cvid)));
}

void pushDynamic(BuildContext context, String id) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => DynamicDetailPage(id: id)));
}

void pushLiveRoom(BuildContext context, int roomId) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => BilibiliLiveRoomPage(roomId: roomId)),
  );
}
