                                             
  
                                              
                                         
                                      
                                                         

import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart'
    show WbiSign, BiliFansDetail;
import 'package:naviflash/services/image_cache_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/ugc_filter_service.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/widgets/fan_decorate_card.dart';

                                            
           
                                            

class BiliCommentMember {
  final String mid;
  final String uname;
  final String avatar;
  final int level;
  final int vipType;
  final int vipStatus;
  final int officialType;

                                                 
  final String pendantImage;

                                             
                          
  final BiliFansDetail? fansDetail;

                                                                
  final BiliFanDecorate? fanDecorate;

                                    
  final BiliNameplate? nameplate;

                                                    
  final BiliDigitalItem? digitalItem;

                                                            
                                            
  final bool isSeniorMember;

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
    this.fanDecorate,
    this.nameplate,
    this.digitalItem,
    this.isSeniorMember = false,
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
      fanDecorate: BiliFanDecorate.fromMember(json),
      nameplate: BiliNameplate.fromAny(json['nameplate']),
      digitalItem: BiliDigitalItem.fromMember(json),
      isSeniorMember: _isSeniorMember(json, levelInfo),
    );
  }
}

                                                     
                                              
bool _isSeniorMember(
  Map<String, dynamic> member,
  Map<String, dynamic>? levelInfo,
) {
  for (final m in [member, levelInfo]) {
    if (m == null) continue;
    if ((m['is_senior_member'] as num?)?.toInt() == 1) return true;
    final senior = m['senior'];
    if (senior is Map && ((senior['status'] as num?)?.toInt() ?? 0) > 0) {
      return true;
    }
    if ((m['identity'] as num?)?.toInt() == 2) return true;
  }
  return false;
}

                                            
                                
                                            

class BiliCommentEmote {
  final String text;               
  final String url;         
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

                                          
String _normalizeUrl(String url) {
  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('http://')) return 'https://${url.substring(7)}';
  return url;
}

                                            
           
                                            

class BiliComment {
  final String rpid;
  final String oid;
  final String mid;
  final String root;
  final String parent;
  final int count;                         
  final int rcount;                                       
  final int like;
  final int ctime;
  final String message;
  final Map<String, BiliCommentEmote> emotes;             
  final List<BiliCommentPicture> pictures;         
  final BiliCommentMember member;
  final List<BiliComment> replies;              

                                                
                    
  final String location;

                                                  
                                                
                                                 
  final int dialog;

                       
                                                    
                              
  final int action;

                                           
  final bool isUp;

  const BiliComment({
    required this.rpid,
    required this.oid,
    required this.mid,
    required this.root,
    required this.parent,
    required this.count,
    this.rcount = 0,
    required this.like,
    required this.ctime,
    required this.message,
    required this.emotes,
    required this.pictures,
    required this.member,
    required this.replies,
    this.location = '',
    this.dialog = 0,
    this.action = 0,
    this.isUp = false,
  });

                                   
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
    rcount: rcount,
    like: like,
    ctime: ctime,
    message: message,
    emotes: emotes,
    pictures: pictures,
    member: member,
    replies: replies,
    location: location,
    dialog: dialog,
    action: action,
    isUp: isUp ?? this.isUp,
  );

  factory BiliComment.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>?;
    final subList = json['replies'] as List<dynamic>?;
                                                         
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
                                              
    final dynamic picsRaw = content?['pictures'];
    final picsList = picsRaw is List
        ? picsRaw
        : (picsRaw is Map ? [picsRaw] : const <dynamic>[]);
    final pictures = picsList
        .whereType<Map<String, dynamic>>()
        .map(BiliCommentPicture.fromJson)
        .where((p) => p.src.isNotEmpty)
        .toList();
                                                         
    final rc = json['reply_control'] as Map<String, dynamic>?;
    return BiliComment(
      rpid: (json['rpid'] as dynamic)?.toString() ?? '',
      oid: (json['oid'] as dynamic)?.toString() ?? '',
      mid: (json['mid'] as dynamic)?.toString() ?? '',
      root: (json['root'] as dynamic)?.toString() ?? '',
      parent: (json['parent'] as dynamic)?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      rcount: (json['rcount'] as num?)?.toInt() ?? 0,
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
          .where((c) => !UgcFilterService.instance.shouldFilter(
                UgcFilterScope.reply,
                c.message,
              ))
          .toList(),
                                                           
                              
      location:
          (rc?['location'] as String?) ??
          (json['location'] as String?) ??
          '',
      dialog: (rc?['dialog'] as num?)?.toInt() ?? 0,
      action: (json['action'] as num?)?.toInt() ?? 0,
    );
  }
}

                                            
                                            
                                            

              
class BiliPanelEmote {
                                    
  final String text;
  final String url;

                                             
  final int size;

  const BiliPanelEmote({required this.text, required this.url, this.size = 0});

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

                                   
class BiliEmotePackage {
  final String url;       
  final int type;
  final List<BiliPanelEmote> emotes;

  const BiliEmotePackage({
    required this.url,
    required this.type,
    required this.emotes,
  });

                            
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

                                            
           
                                            

class BiliCommentPage {
  final List<BiliComment> comments;
  final List<BiliComment> topReplies;        
  final String next;         
  final bool isEnd;
  final int allCount;        

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

                                            
                                 
  final BiliComment? root;

  const BiliSubCommentPage({
    required this.replies,
    required this.isEnd,
    required this.total,
    this.root,
  });
}

                                            
      
                                            

abstract final class BilibiliCommentService {
  static const String _mainApi = 'https://api.bilibili.com/x/v2/reply/main';
  static const String _subApi = 'https://api.bilibili.com/x/v2/reply/reply';
  static const String _actionApi = 'https://api.bilibili.com/x/v2/reply/action';

                                     
  static const String _hateApi = 'https://api.bilibili.com/x/v2/reply/hate';
  static const String _replyAddApi = 'https://api.bilibili.com/x/v2/reply/add';
  static const String _emotePanelApi =
      'https://api.bilibili.com/x/emote/user/panel/web';

                                 
  static List<BiliEmotePackage>? _emotePanelCache;

                             
  static void resetEmotePanelCache() => _emotePanelCache = null;

                                    
  static String? lastErrorDetail;

                                                  
  static int? lastErrorCode;

                                                     
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

     
                                        
                                                                
                                                                
                                 
                                                      
                                               
  static const Map<String, String> _guestAppHeaders = {
    'User-Agent': 'Dart/3.6 (dart:io)',
    'Accept-Encoding': 'gzip',
    'env': 'prod',
    'app-key': 'android64',
    'x-bili-aurora-zone': 'sh001',
  };

                        
  static int _modeOf(int sort) => sort == 1 ? 2 : 3;

                                                     
  static bool _asBool(dynamic v) => v == true || v == 1 || v == '1';

                                                   
                                                 
  static bool _guestMode(bool forceGuest) =>
      forceGuest ||
      BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.comments,
      ) ==
      null;

                            
    
                                                   
                                                     
                                                 
               
  static Map<String, String> get _headers => _headersFor(false);

                                                 
  static Map<String, String> _headersFor(bool forceGuest) {
    if (_guestMode(forceGuest)) {
      final extra = Map.of(NetworkSettingsService.instance.apiHeaders)
        ..removeWhere(
          (k, _) =>
              k.toLowerCase() == 'user-agent' || k.toLowerCase() == 'referer',
        );
      return {...extra, ..._guestAppHeaders, 'Cookie': ''};
    }
    return {
      ..._defaultHeaders,
      'Cookie': 'buvid3=$_buvid3',
                                            
                                         
      ...?BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.comments,
      ),
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

               
                             
                                          
                             
                                                          
                        
     
                                                        
                    
                                                       
                                 
                                                       
                                               
                    
     
                                                  
                                
  static Future<BiliCommentPage?> fetchComments({
    required String cid,
    int sort = 0,
    String offset = '',
    String type = '1',
    bool forceGuest = false,
  }) async {
    try {
      final oid = cid.trim();
      if (oid.isEmpty) {
        lastErrorDetail = L10n.current.commentOidEmpty;
        return null;
      }
      final guest = _guestMode(forceGuest);
                                                                  
                                 
                                                              
                                                                
                                                    
                                                    
      final paginationStr = guest
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
      final params = guest
          ? baseParams
                                            
          : await WbiSign.sign({...baseParams, 'web_location': '333.788'});
      final uri = Uri.parse(_mainApi).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headersFor(forceGuest))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = 'HTTP ${resp.statusCode}';
        debugPrint('[Comment] HTTP ${resp.statusCode}');
        return null;
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorCode = (json['code'] as num?)?.toInt();
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
          .where((c) => !UgcFilterService.instance.shouldFilter(
                UgcFilterScope.reply,
                c.message,
              ))
          .toList();
                                         
                                                 
                                         
      final topRpids = topReplies.map((e) => e.rpid).toSet();
      final comments = (data['replies'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BiliComment.fromJson)
          .where((c) => !topRpids.contains(c.rpid))
                             
          .where((c) => !UgcFilterService.instance.shouldFilter(
                UgcFilterScope.reply,
                c.message,
              ))
          .toList();
      final cursorJson = data['cursor'] as Map<String, dynamic>?;
                                                             
                     
      final paginationReply =
          cursorJson?['pagination_reply'] as Map<String, dynamic>?;
      var next = (paginationReply?['next_offset'] as dynamic)?.toString() ?? '';
      if (next.isEmpty) {
                                          
        final legacy = (cursorJson?['next'] as dynamic)?.toString() ?? '';
        if (legacy.isNotEmpty && (int.tryParse(legacy) ?? 0) > 10000000000) {
          next = legacy;
        }
      }
      final isEnd = _asBool(cursorJson?['is_end']) || next.isEmpty;
      final allCount = (cursorJson?['all_count'] as num?)?.toInt() ?? 0;

      lastErrorDetail = null;
      lastErrorCode = null;
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

                                          
                                                        
  static Future<BiliComment?> fetchCommentThread({
    required String cid,
    required String rpid,
    String type = '1',
  }) async {
    final page = await fetchSubComments(cid: cid, root: rpid, type: type);
    if (page == null) return null;
    final root = page.root;
    if (root != null) return root;
    for (final r in page.replies) {
      if (r.rpid == rpid) return r;
    }
    return null;
  }

                    
                                             
  static Future<BiliSubCommentPage?> fetchSubComments({
    required String cid,
    required String root,
    int page = 1,
    int pageSize = 20,
    String type = '1',
    bool forceGuest = false,
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
          .get(uri, headers: _headersFor(forceGuest))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        lastErrorDetail = L10n.current.commentSubHttpError(resp.statusCode);
        debugPrint('[Comment] 楼中楼 HTTP ${resp.statusCode}');
        return null;
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        lastErrorCode = (json['code'] as num?)?.toInt();
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
      lastErrorCode = null;
      final rootJson = data['root'];
      final rootComment = rootJson is Map<String, dynamic>
          ? BiliComment.fromJson(rootJson)
          : null;
                                                              
                                       
      var total = (pageJson?['count'] as num?)?.toInt() ?? 0;
      if (total <= 0) total = rootComment?.rcount ?? 0;
      if (total <= 0) total = rootComment?.count ?? 0;
      return BiliSubCommentPage(
        replies: (data['replies'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(BiliComment.fromJson)
            .toList(),
        isEnd: _asBool(pageJson?['is_end']),
        total: total,
        root: rootComment,
      );
    } catch (e) {
      lastErrorDetail = L10n.current.commentSubException('$e');
      debugPrint('[Comment] 拉取楼中楼异常: $e');
      return null;
    }
  }

                  
                                                  
                                                
                     
  static Future<({BiliSubCommentPage page, int fetchedPage})?>
  fetchSubCommentsSkipEmpty({
    required String cid,
    required String root,
    required int page,
    int pageSize = 20,
    int maxEmptyPages = 3,
    String type = '1',
    bool forceGuest = false,
  }) async {
    var current = page;
    for (var i = 0; i < maxEmptyPages; i++) {
      final result = await fetchSubComments(
        cid: cid,
        root: root,
        page: current,
        pageSize: pageSize,
        type: type,
        forceGuest: forceGuest,
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

                                                      
                
     
                                                                 
                                                      
                               
                                    
                                                
  static Future<List<BiliComment>?> fetchDialogueChain({
    required String cid,
    required BiliComment root,
    required BiliComment reply,
    String type = '1',
    Map<String, BiliComment> seed = const {},
    int maxPages = 8,
  }) async {
    if (reply.parent.isEmpty ||
        reply.parent == '0' ||
        reply.parent == reply.root) {
                       
      return null;
    }
    final known = <String, BiliComment>{...seed};
    final chain = <BiliComment>[reply];
    var cur = reply;
    var page = 1;
    var exhausted = false;
    while (true) {
      final parentRpid = cur.parent;
                             
      if (parentRpid.isEmpty || parentRpid == '0' || parentRpid == root.rpid) {
        break;
      }
      var parent = known[parentRpid];
      while (parent == null && !exhausted && page <= maxPages) {
        final p = await fetchSubComments(
          cid: cid,
          root: root.rpid,
          page: page,
          type: type,
        );
        if (p == null) return null;
        for (final r in p.replies) {
          known.putIfAbsent(r.rpid, () => r);
        }
        parent = known[parentRpid];
        if (p.isEnd || p.replies.isEmpty) exhausted = true;
        page += 1;
      }
      if (parent == null) break;                   
      chain.add(parent);
      cur = parent;
    }
    chain.add(root);
    return chain.reversed.toList();                            
  }

                          
  static String avatarUrl(String url, {int size = 96}) {
    if (url.isEmpty) return '';
    return '$url@${size}w_${size}h_1c.webp';
  }

                                    
  static String emoteUrl(String url, {int size = 64}) {
    if (url.isEmpty) return '';
    if (url.toLowerCase().endsWith('.gif')) return url;
    return '$url@${size}w_${size}h.webp';
  }

                           
     
                                                  
                                               
                                              
                                     
  static Future<Uint8List?> fetchBytes(String url) {
    if (url.trim().isEmpty) return Future.value(null);
    return ImageCacheService.fetch(url, headers: _headers);
  }

                                          
              
                                          

                                        
  static bool get canInteract =>
      BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.interactions,
      ) !=
      null;

                  
                                    
                                        
                                                           
  static Future<({bool ok, String message})> likeComment({
    required String oid,
    required String rpid,
    required bool like,
    String type = '1',
  }) => _commentVote(
    api: _actionApi,
    on: like,
    oid: oid,
    rpid: rpid,
    type: type,
    logTag: '点赞',
  );

                              
     
                                                               
                                                    
                                                    
                            
  static Future<({bool ok, String message})> dislikeComment({
    required String oid,
    required String rpid,
    required bool dislike,
    String type = '1',
  }) => _commentVote(
    api: _hateApi,
    on: dislike,
    oid: oid,
    rpid: rpid,
    type: type,
    logTag: '点踩',
  );

                                        
  static Future<({bool ok, String message})> _commentVote({
    required String api,
    required bool on,
    required String oid,
    required String rpid,
    required String type,
    required String logTag,
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
                                    
    final buvid3 = _extractCookie(rawCookie, 'buvid3');
    final cookie = buvid3.isEmpty && _buvid3.isNotEmpty
        ? '$rawCookie; buvid3=$_buvid3'
        : rawCookie;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(api),
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
              'action': on ? '1' : '0',
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        final msg = L10n.current.commentApiError(
          json['message'] as String? ?? L10n.current.biliUnknownError,
          (json['code'] as num?)?.toInt() ?? 0,
        );
        debugPrint('[Comment] $logTag失败: $msg');
        return (ok: false, message: msg);
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[Comment] $logTag异常: $e');
      return (ok: false, message: L10n.current.commentNetworkError('$e'));
    }
  }

  static String _extractCookie(String cookie, String name) {
    final m = RegExp('(?:^|;\\s*)$name=([^;]+)').firstMatch(cookie);
    return m?.group(1) ?? '';
  }

                                                         
                                            
                                                      
                                                          
                                      
                                           
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
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        final msg =
            (json['message'] as String? ?? L10n.current.biliUnknownError);
        debugPrint('[Comment] 发送评论失败: ${json['code']} $msg');
        return (comment: null, message: msg);
      }
                                       
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
      final req =
          http.MultipartRequest(
              'POST',
              Uri.parse(
                'https://api.bilibili.com/x/dynamic/feed/draw/upload_bfs',
              ),
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
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
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

                                                            
                                        
  static Future<List<BiliEmotePackage>?> fetchEmotePanel() async {
    if (_emotePanelCache != null) return _emotePanelCache;
    final cookieHeader = BilibiliAccountService.instance.cookieHeaderFor(
      BiliCookieScope.interactions,
    );
    if (cookieHeader == null) return null;
    try {
      final uri = Uri.parse(_emotePanelApi).replace(
        queryParameters: {'business': 'reply', 'web_location': '333.1245'},
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: {..._defaultHeaders, ...cookieHeader})
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        debugPrint('[Comment] 表情面板失败: ${json['code']} ${json['message']}');
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

                                           
  static bool hasBiliJct(String cookie) =>
      RegExp(r'(?:^|;\s*)bili_jct=([^;]+)').hasMatch(cookie);
}
