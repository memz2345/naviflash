                                                  
  
                                                    
                                                          
                                                                                   
                                                                                   
                                                                                  
                                                                
                                                                          
                                                         
                                                               
                                            
                                                      
                                            
                                                                                    
                                
                                                          
                                                                              
                                                                            
                                                                  
                                                                                   
                                                    
                                                                     
                                             
                                                          
                                                                    
                                                              
  
                            
                                                                    
                                                   
                                                                       
                                                                               
                                                                              
                                        
  
                                                         
                                                   
                                                
                                                      
                                                         
                                                               
                                                               
                                                   
import 'package:naviflash/utils/json_decode.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

import 'bilibili_account_service.dart';
import 'bilibili_api_helpers.dart';
import 'bilibili_user_space_service.dart'
    show BilibiliUserSpaceService, WbiSign;
import 'network_settings_service.dart';

                                           
      
                                           

                                          
class BiliVoteOption {
  final int optIdx;
  final String optDesc;
  final int cnt;
  final String imgUrl;

  const BiliVoteOption({
    required this.optIdx,
    required this.optDesc,
    this.cnt = 0,
    this.imgUrl = '',
  });

                                             
  factory BiliVoteOption.fromJson(dynamic json, int fallbackIdx) {
    final m = biliAsMap(json) ?? const <String, dynamic>{};
    return BiliVoteOption(
      optIdx: biliToInt(m['opt_idx'] ?? fallbackIdx),
      optDesc: biliAsStr(m['opt_desc']),
      cnt: biliToInt(m['cnt']),
      imgUrl: biliNormalizeUrl(biliAsStr(m['img_url'])),
    );
  }
}

                                      
class BiliVoteInfo {
  final int voteId;
  final String title;
  final String desc;

                        
  final int type;

                        
  final int choiceCnt;
  final int endTime;
  final int joinNum;
  final List<BiliVoteOption> options;

                                        
  final List<int> myVotes;

  const BiliVoteInfo({
    required this.voteId,
    required this.title,
    this.desc = '',
    this.type = 0,
    this.choiceCnt = 1,
    this.endTime = 0,
    this.joinNum = 0,
    this.options = const [],
    this.myVotes = const [],
  });

                                                   
                                                   
                                      
  factory BiliVoteInfo.fromVoteInfoJson(
    dynamic json, {
    List<int> myVotes = const [],
  }) {
    final m = biliAsMap(json) ?? const <String, dynamic>{};
    final rawOptions = biliAsList<dynamic>(m['options']);
    final my = myVotes.isNotEmpty ? myVotes : biliAsList<int>(m['my_votes']);
    return BiliVoteInfo(
      voteId: biliToInt(m['vote_id']),
      title: biliAsStr(m['title']).trim(),
      desc: biliAsStr(m['desc']),
      type: biliToInt(m['type']),
      choiceCnt: (biliToInt(m['choice_cnt']) <= 0
          ? 1
          : biliToInt(m['choice_cnt'])),
      endTime: biliToInt(m['end_time']),
      joinNum: biliToInt(m['join_num']),
      myVotes: my,
      options: [
        for (var i = 0; i < rawOptions.length; i++)
          BiliVoteOption.fromJson(rawOptions[i], i),
      ],
    );
  }

                                       
                                                         
                                      
  factory BiliVoteInfo.fromSeparatedJson(dynamic data) {
    final m = biliAsMap(data);
    if (m == null) return const BiliVoteInfo(voteId: 0, title: '');
    if (m['vote_info'] != null) {
      return BiliVoteInfo.fromVoteInfoJson(
        m['vote_info'],
        myVotes: biliAsList<int>(m['my_votes']),
      );
    }
    return BiliVoteInfo.fromVoteInfoJson(m);
  }

  bool get hasVoted => myVotes.isNotEmpty;

                      
  bool endedAt(DateTime now) =>
      endTime > 0 && endTime * 1000 <= now.millisecondsSinceEpoch;

  bool get canVote => !hasVoted && !endedAt(DateTime.now());

                                          
  List<double> percentages() => votePercentages(options);
}

                          
                                      
List<double> votePercentages(List<BiliVoteOption> options) {
  final total = options.fold<int>(0, (sum, o) => sum + o.cnt);
  if (total <= 0) return List<double>.filled(options.length, 0);
  return [
    for (final o in options) o.cnt / total,
  ];
}

                        
class BiliVoteRef {
  final int voteId;
  final String title;

  const BiliVoteRef({required this.voteId, this.title = ''});
}

                                                   
class BiliReserveInfo {
  final int rid;
  final String title;
  final int state;
  final int reserveTotal;
  final String desc1;
  final String desc2;
  final String desc3;
  final String desc3Url;

       
  final int btnStatus;
  final int btnType;

                                                   
  final String btnCheckText;
  final String btnUncheckText;
  final int btnDisable;
  final String btnJumpUrl;

  const BiliReserveInfo({
    required this.rid,
    required this.title,
    this.state = 0,
    this.reserveTotal = 0,
    this.desc1 = '',
    this.desc2 = '',
    this.desc3 = '',
    this.desc3Url = '',
    this.btnStatus = 0,
    this.btnType = 0,
    this.btnCheckText = '已预约',
    this.btnUncheckText = '预约',
    this.btnDisable = 0,
    this.btnJumpUrl = '',
  });

                                                
  bool get isReserved => btnType > 0 && btnStatus == btnType;

  bool get canReserve => rid > 0 && btnDisable != 1 && btnJumpUrl.isEmpty;

                                      
  static BiliReserveInfo? tryParse(dynamic json) {
    final m = biliAsMap(json);
    if (m == null) return null;
    String descText(String key) =>
        biliAsStr(biliAsMap(m[key])?['text'] ?? m[key]);
    final btn = biliAsMap(m['button']) ?? const <String, dynamic>{};
    return BiliReserveInfo(
      rid: biliToInt(m['rid']),
      title: biliAsStr(m['title']),
      state: biliToInt(m['state']),
      reserveTotal: biliToInt(m['reserve_total']),
      desc1: descText('desc1'),
      desc2: descText('desc2'),
      desc3: descText('desc3'),
      desc3Url: biliAsStr(biliAsMap(m['desc3'])?['jump_url']),
      btnStatus: biliToInt(btn['status']),
      btnType: biliToInt(btn['type']),
      btnCheckText: biliAsStr(biliAsMap(btn['check'])?['text']).isNotEmpty
          ? biliAsStr(biliAsMap(btn['check'])?['text'])
          : '已预约',
      btnUncheckText: biliAsStr(biliAsMap(btn['uncheck'])?['text']).isNotEmpty
          ? biliAsStr(biliAsMap(btn['uncheck'])?['text'])
          : '预约',
      btnDisable: biliToInt(btn['disable']),
      btnJumpUrl: biliAsStr(btn['jump_url']),
    );
  }

                                                
                                   
  static BiliReserveInfo? fromModules(dynamic modules) {
    final mods = biliAsMap(modules);
    if (mods == null) return null;
    final dyn = biliAsMap(mods['module_dynamic']) ?? const <String, dynamic>{};
    final additional = biliAsMap(dyn['additional']);
    if (additional != null &&
        biliAsStr(additional['type']) == 'ADDITIONAL_TYPE_RESERVE') {
      final r = BiliReserveInfo.tryParse(additional['reserve']);
      if (r != null) return r;
    }
    final major = biliAsMap(dyn['major']);
    if (major != null) return BiliReserveInfo.tryParse(major['reserve']);
    return null;
  }

                                        
                                          
  static BiliVoteRef? voteRefFromModules(dynamic modules) {
    final mods = biliAsMap(modules);
    if (mods == null) return null;
    final dyn = biliAsMap(mods['module_dynamic']) ?? const <String, dynamic>{};
    final majorVote = biliAsMap(biliAsMap(dyn['major'])?['vote']);
    if (majorVote != null) {
      final id = biliToInt(majorVote['vote_id']);
      if (id > 0) {
        return BiliVoteRef(
          voteId: id,
          title: biliAsStr(majorVote['title']).isNotEmpty
              ? biliAsStr(majorVote['title'])
              : biliAsStr(majorVote['desc']),
        );
      }
    }
    return voteRefFromTextNodes(dyn['desc']);
  }

                                                          
  static BiliVoteRef? voteRefFromTextNodes(dynamic desc) {
    final nodes = biliAsList<dynamic>(biliAsMap(desc)?['rich_text_nodes']);
    for (final n in nodes) {
      final m = biliAsMap(n);
      if (m == null) continue;
      if (biliAsStr(m['type']) == 'RICH_TEXT_NODE_TYPE_VOTE') {
        final id = biliToInt(m['rid']);
        if (id > 0) {
          return BiliVoteRef(voteId: id, title: biliAsStr(m['text']));
        }
      }
    }
    return null;
  }
}

                                           
                             
                                           

                                   
class BiliRichToken {
                              
  final String text;

                                           
  final int type;
  final String bizId;

  const BiliRichToken({
    required this.text,
    required this.type,
    this.bizId = '',
  });
}

                                  
class BiliDynEditDraft {
  final String dynId;
  final String type;
  final String text;
  final List<BiliRichToken> tokens;
  final List<BiliEditImage> images;
  final bool privatePub;
  final int topicId;
  final String topicName;

                                    
  final String repostId;

  const BiliDynEditDraft({
    required this.dynId,
    required this.type,
    required this.text,
    this.tokens = const [],
    this.images = const [],
    this.privatePub = false,
    this.topicId = 0,
    this.topicName = '',
    this.repostId = '',
  });

  bool get isRepost => repostId.isNotEmpty;
}

                                        
class BiliEditImage {
  final String url;
  final int width;
  final int height;
  final double size;

  const BiliEditImage({
    required this.url,
    this.width = 0,
    this.height = 0,
    this.size = 0,
  });
}

                           
   
                                                
                                                           
                                                            
BiliDynEditDraft? parseEditDraft(dynamic rawItem) {
  final item = biliAsMap(rawItem);
  if (item == null) return null;
  final modules = biliAsMap(item['modules']) ?? const <String, dynamic>{};
  final dyn = biliAsMap(modules['module_dynamic']) ?? const <String, dynamic>{};
  final major = biliAsMap(dyn['major']) ?? const <String, dynamic>{};
  final majorType = biliAsStr(major['type']);
  final desc = biliAsMap(dyn['desc']) ?? const <String, dynamic>{};
  final opus = biliAsMap(major['opus']);
  final idStr = biliAsStr(item['id_str']);
  if (idStr.isEmpty) return null;

             
  String text = biliAsStr(desc['text']);
  var nodes = biliAsList<dynamic>(desc['rich_text_nodes']);
  if (text.isEmpty && opus != null) {
    final summary = biliAsMap(opus['summary']);
    text = biliAsStr(summary?['text']);
    if (nodes.isEmpty) nodes = biliAsList<dynamic>(summary?['rich_text_nodes']);
  }

                                              
                        
  final tokens = <BiliRichToken>[];
  for (final n in nodes) {
    final m = biliAsMap(n);
    if (m == null) continue;
    switch (biliAsStr(m['type'])) {
      case 'RICH_TEXT_NODE_TYPE_AT':
        tokens.add(
          BiliRichToken(text: biliAsStr(m['text']), type: 2, bizId: biliAsStr(m['rid'])),
        );
      case 'RICH_TEXT_NODE_TYPE_EMOJI':
        tokens.add(BiliRichToken(text: biliAsStr(m['text']), type: 9));
      case 'RICH_TEXT_NODE_TYPE_VOTE':
        tokens.add(BiliRichToken(text: biliAsStr(m['text']), type: 4, bizId: biliAsStr(m['rid'])));
    }
  }

                           
  final images = <BiliEditImage>[];
  if (opus != null) {
    for (final p in biliAsList<dynamic>(opus['pics'])) {
      final m = biliAsMap(p);
      if (m == null) continue;
      final u = biliAsStr(m['url'] ?? m['src']);
      if (u.isEmpty) continue;
      images.add(
        BiliEditImage(
          url: biliNormalizeUrl(u),
          width: biliToInt(m['img_width'] ?? m['width']),
          height: biliToInt(m['img_height'] ?? m['height']),
          size: biliToDouble(m['img_size'] ?? m['size']),
        ),
      );
    }
  } else if (majorType == 'MAJOR_TYPE_DRAW') {
    for (final it in biliAsList<dynamic>(biliAsMap(major['draw'])?['items'])) {
      final m = biliAsMap(it);
      if (m == null) continue;
      final u = biliAsStr(m['src']);
      if (u.isEmpty) continue;
      images.add(
        BiliEditImage(
          url: biliNormalizeUrl(u),
          width: biliToInt(m['img_width'] ?? m['width']),
          height: biliToInt(m['img_height'] ?? m['height']),
          size: biliToDouble(m['img_size'] ?? m['size']),
        ),
      );
    }
  }

              
  var private = false;
  final visibilities = biliAsList<dynamic>(item['visibilities']);
  for (final v in visibilities) {
    final t = biliAsStr(biliAsMap(v)?['type']);
    if (t.contains('private')) private = true;
  }

             
  final topic = biliAsMap(dyn['topic']);

              
  final origId = biliAsStr(biliAsMap(item['orig'])?['id_str']);

  return BiliDynEditDraft(
    dynId: idStr,
    type: biliAsStr(item['type']),
    text: text,
    tokens: tokens,
    images: images,
    privatePub: private,
    topicId: biliToInt(topic?['id']),
    topicName: biliAsStr(topic?['name']),
    repostId: origId,
  );
}

                                           
                       
                                           

                                                                   
Map<String, dynamic> buildCreateVotePayload({
  required String title,
  String desc = '',
  int type = 0,
  int choiceCnt = 1,
  required int durationSec,
  required List<String> options,
  required int mid,
  int? voteId,
}) {
  return {
    'vote_info': {
      'title': title,
      'desc': desc,
      'type': type,
      'choice_cnt': choiceCnt,
      'duration': durationSec,
      'options': [
        for (final o in options) {'opt_desc': o, 'img_url': ''},
      ],
      'only_fans_level': 0,
      'vote_publisher': mid,
      if (voteId != null) 'vote_id': voteId,
    },
  };
}

                                                    
Map<String, dynamic> buildDoVoteBody({
  required int voteId,
  required List<int> votes,
  required int mid,
  required String csrf,
  int dynamicId = 0,
  bool anonymous = false,
}) {
  return {
    'vote_id': voteId,
    'votes': votes,
    'voter_uid': mid,
    'status': anonymous ? 1 : 0,
    'op_bit': 0,
    'dynamic_id': dynamicId,
    'csrf_token': csrf,
    'csrf': csrf,
  };
}

                                                        
List<Map<String, dynamic>> buildVoteContents(
  String text,
  int voteId,
  String voteTitle,
) {
  return [
    {'raw_text': text, 'type': 1, 'biz_id': ''},
    {'raw_text': voteTitle, 'type': 4, 'biz_id': '$voteId'},
  ];
}

                                            
                                       
List<Map<String, dynamic>> buildEditContents(
  String text,
  List<BiliRichToken> tokens,
) {
  final candidates = tokens
      .where((t) => t.text.isNotEmpty)
      .toList(growable: false);
  if (candidates.isEmpty) {
    return [
      {'raw_text': text, 'type': 1, 'biz_id': ''},
    ];
  }
  final nodes = <Map<String, dynamic>>[];
  final buffer = StringBuffer();
  var index = 0;

  void flushText() {
    if (buffer.isEmpty) return;
    nodes.add({'raw_text': buffer.toString(), 'type': 1, 'biz_id': ''});
    buffer.clear();
  }

  while (index < text.length) {
    var matched = false;
    for (final token in candidates) {
      if (text.startsWith(token.text, index)) {
        flushText();
        nodes.add({
          'raw_text': token.text,
          'type': token.type,
          'biz_id': token.bizId,
        });
        index += token.text.length;
        matched = true;
        break;
      }
    }
    if (!matched) {
      buffer.write(text[index]);
      index++;
    }
  }
  flushText();
  if (nodes.isEmpty) {
    nodes.add({'raw_text': text, 'type': 1, 'biz_id': ''});
  }
  return nodes;
}

                                                       
Map<String, dynamic> buildEditDynReq({
  required String uploadId,
  required List<Map<String, dynamic>> contents,
  List<Map<String, dynamic>> pics = const [],
  bool privatePub = false,
  int topicId = 0,
  String topicName = '',
}) {
  return {
    'content': {'contents': contents},
    if (privatePub)
      'option': {
        'private_pub': 1,
      },
    'scene': pics.isEmpty ? 1 : 2,
    if (pics.isNotEmpty) 'pics': pics,
    'upload_id': uploadId,
    'meta': {
      'app_meta': {'from': 'create.dynamic.web', 'mobi_app': 'web'},
    },
    if (topicId > 0 && topicName.isNotEmpty)
      'topic': {
        'id': topicId,
        'name': topicName,
        'from_source': 'dyn.web.list',
        'from_topic_id': 0,
      },
  };
}

                                     
Map<String, dynamic> buildReserveAttachCard(int reserveSid) => {
  'common_card': {
    'type': 14,
    'biz_id': reserveSid,
    'reserve_source': 0,
    'reserve_lottery': 0,
  },
};

                                               
Map<String, String> buildReserveCreateFields({
  required String title,
  required int startTs,
  required String csrf,
}) {
  return {
    'type': '2',
    'sub_type': '0',
    'from': '1',
    'title': title,
    'live_plan_start_time': '$startTs',
    'csrf': csrf,
  };
}

                                           
      
                                           

abstract final class BilibiliDynamicOpusService {
  static const String _apiBase = 'https://api.bilibili.com';
  static const String _editApi = '$_apiBase/x/dynamic/feed/edit/dyn';
  static const String _createDynApi = '$_apiBase/x/dynamic/feed/create/dyn';
  static const String _voteInfoApi = '$_apiBase/x/vote/vote_info';
  static const String _doVoteApi = '$_apiBase/x/vote/do_vote';
  static const String _createVoteApi = '$_apiBase/x/vote/create';
  static const String _updateVoteApi = '$_apiBase/x/vote/update';
  static const String _createReserveApi =
      '$_apiBase/x/new-reserve/up/reserve/create';
  static const String _reserveClickApi = '$_apiBase/x/dynamic/feed/reserve/click';

  static bool get canUse =>
      BilibiliAccountService.instance.cookieHeaderFor(
        BiliCookieScope.interactions,
      ) !=
      null;

  static Map<String, String> _headers() {
    final cookie = biliLoginCookie(BiliCookieScope.interactions);
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': 'https://t.bilibili.com',
      'Origin': 'https://t.bilibili.com',
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  static String _csrf() => biliExtractCsrf(
    BilibiliAccountService.instance.rawCookie,
  );

  static Future<Map<String, dynamic>?> _postJson(
    Uri uri,
    Map<String, dynamic> body, {
    String tag = 'DynOpus',
  }) async {
    try {
      final resp = await (await NetworkSettingsService.instance.getApiClient())
          .post(
            uri,
            headers: {
              ..._headers(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        return {'code': resp.statusCode, 'message': 'HTTP ${resp.statusCode}'};
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      return biliAsMap(json);
    } catch (e) {
      debugPrint('[$tag] 请求失败: $e');
      return null;
    }
  }

  static ({bool ok, String message}) _asResult(Map<String, dynamic>? json) {
    if (json == null) return (ok: false, message: '网络异常');
    if (json['code'] != 0) {
      final msg = biliAsStr(json['message'] ?? json['msg']);
      return (ok: false, message: msg.isEmpty ? '接口返回 ${json['code']}' : msg);
    }
    return (ok: true, message: '');
  }

             

                                                         
  static Future<({BiliVoteInfo? info, String? err})> fetchVoteInfo(
    int voteId,
  ) async {
    if (voteId <= 0) return (info: null, err: '投票 id 无效');
    try {
      final uri = Uri.parse(
        _voteInfoApi,
      ).replace(queryParameters: {'vote_id': '$voteId'});
      final resp = await (await NetworkSettingsService.instance.getApiClient())
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (info: null, err: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return (info: null, err: '返回内容不是 JSON');
      }
      if (json['code'] != 0) {
        final msg = biliAsStr(json['message']);
        return (info: null, err: msg.isEmpty ? '接口返回 ${json['code']}' : msg);
      }
      final info = BiliVoteInfo.fromSeparatedJson(json['data']);
      if (info.voteId <= 0) return (info: null, err: '无效的投票');
      return (info: info, err: null);
    } catch (e) {
      debugPrint('[DynOpus] 拉取投票详情失败: $e');
      return (info: null, err: '网络异常：${e.runtimeType}');
    }
  }

                                       
  static Future<({BiliVoteInfo? info, String? err})> doVote({
    required int voteId,
    required List<int> votes,
    int dynamicId = 0,
    bool anonymous = false,
  }) async {
    if (!canUse) return (info: null, err: '还没有登录，登录后才能投票');
    final csrf = _csrf();
    if (csrf.isEmpty) return (info: null, err: '缺少 bili_jct，请重新登录');
    final json = await _postJson(
      Uri.parse(_doVoteApi).replace(queryParameters: {'csrf': csrf}),
      buildDoVoteBody(
        voteId: voteId,
        votes: votes,
        mid: BilibiliAccountService.instance.mid,
        csrf: csrf,
        dynamicId: dynamicId,
        anonymous: anonymous,
      ),
    );
    if (json == null) return (info: null, err: '网络异常');
    if (json['code'] != 0) {
      final msg = biliAsStr(json['message'] ?? json['msg']);
      return (info: null, err: msg.isEmpty ? '接口返回 ${json['code']}' : msg);
    }
    final info = BiliVoteInfo.fromSeparatedJson(json['data']);
    return (info: info, err: null);
  }

                                          
  static Future<({int? voteId, String? err})> createVote({
    required String title,
    String desc = '',
    required int durationSec,
    required List<String> options,
    int? voteId,
  }) async {
    if (!canUse) return (voteId: null, err: '还没有登录，登录后才能创建投票');
    final csrf = _csrf();
    if (csrf.isEmpty) return (voteId: null, err: '缺少 bili_jct，请重新登录');
    final json = await _postJson(
      Uri.parse(voteId == null ? _createVoteApi : _updateVoteApi)
          .replace(queryParameters: {'csrf': csrf}),
      buildCreateVotePayload(
        title: title,
        desc: desc,
        durationSec: durationSec,
        options: options,
        mid: BilibiliAccountService.instance.mid,
        voteId: voteId,
      ),
    );
    if (json == null) return (voteId: null, err: '网络异常');
    if (json['code'] != 0) {
      final msg = biliAsStr(json['message'] ?? json['msg']);
      return (voteId: null, err: msg.isEmpty ? '接口返回 ${json['code']}' : msg);
    }
    final id = biliToInt(biliAsMap(json['data'])?['vote_id']);
    if (id <= 0) return (voteId: null, err: '接口未返回投票 id');
    return (voteId: id, err: null);
  }

             

                                        
  static Future<({int? sid, String? err})> createReserve({
    required String title,
    required int startTs,
  }) async {
    if (!canUse) return (sid: null, err: '还没有登录，登录后才能创建预约');
    final csrf = _csrf();
    if (csrf.isEmpty) return (sid: null, err: '缺少 bili_jct，请重新登录');
    try {
      final resp = await (await NetworkSettingsService.instance.getApiClient())
          .post(
            Uri.parse(_createReserveApi),
            headers: {
              ..._headers(),
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: buildReserveCreateFields(
              title: title,
              startTs: startTs,
              csrf: csrf,
            ),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        return (sid: null, err: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return (sid: null, err: '返回内容不是 JSON');
      }
      if (json['code'] != 0) {
        final msg = biliAsStr(json['message'] ?? json['msg']);
        return (sid: null, err: msg.isEmpty ? '接口返回 ${json['code']}' : msg);
      }
      final sid = biliToInt(biliAsMap(json['data'])?['sid']);
      if (sid <= 0) return (sid: null, err: '接口未返回预约 id');
      return (sid: sid, err: null);
    } catch (e) {
      debugPrint('[DynOpus] 创建预约失败: $e');
      return (sid: null, err: '网络异常：${e.runtimeType}');
    }
  }

                                        
  static Future<({BiliReserveInfo? info, String? err})> reserveClick({
    required BiliReserveInfo reserve,
    required String dynamicIdStr,
  }) async {
    if (!canUse) return (info: null, err: '还没有登录，登录后才能预约');
    final csrf = _csrf();
    if (csrf.isEmpty) return (info: null, err: '缺少 bili_jct，请重新登录');
                                                
    final nextStatus = reserve.isReserved ? 0 : (reserve.btnType > 0 ? reserve.btnType : 1);
    final json = await _postJson(
      Uri.parse(_reserveClickApi).replace(queryParameters: {'csrf': csrf}),
      {
        'reserve_id': reserve.rid,
        'cur_btn_status': reserve.btnStatus,
        'dynamic_id_str': dynamicIdStr,
        'reserve_total': reserve.reserveTotal,
      },
    );
    if (json == null) return (info: null, err: '网络异常');
    if (json['code'] != 0) {
      final msg = biliAsStr(json['message'] ?? json['msg']);
      return (info: null, err: msg.isEmpty ? '接口返回 ${json['code']}' : msg);
    }
    final data = biliAsMap(json['data']) ?? const <String, dynamic>{};
                                                             
    final updated = BiliReserveInfo(
      rid: reserve.rid,
      title: reserve.title,
      state: reserve.state,
      reserveTotal: biliToInt(data['reserve_update']) > 0
          ? biliToInt(data['reserve_update'])
          : reserve.reserveTotal + (reserve.isReserved ? -1 : 1),
      desc1: reserve.desc1,
      desc2: biliAsStr(data['desc_update']).isNotEmpty
          ? biliAsStr(data['desc_update'])
          : reserve.desc2,
      desc3: reserve.desc3,
      desc3Url: reserve.desc3Url,
      btnStatus: biliToInt(data['final_btn_status']) > 0
          ? biliToInt(data['final_btn_status'])
          : nextStatus,
      btnType: reserve.btnType > 0 ? reserve.btnType : 1,
      btnCheckText: reserve.btnCheckText,
      btnUncheckText: reserve.btnUncheckText,
      btnDisable: reserve.btnDisable,
      btnJumpUrl: reserve.btnJumpUrl,
    );
    return (info: updated, err: null);
  }

                                              

  static String _genUploadId(int mid) =>
      '${mid}_'
      '${DateTime.now().millisecondsSinceEpoch ~/ 1000}_'
      '${DateTime.now().microsecondsSinceEpoch % 9000 + 1000}';

                                                
  static Future<({bool ok, String message, String? dynId})>
  publishVoteDynamic({
    required String text,
    required int voteId,
    required String voteTitle,
    List<({int mid, String name})> mentions = const [],
  }) async {
    return _createDyn(
      contents: _withMentions(
        buildVoteContents(text, voteId, voteTitle),
        mentions,
      ),
      scene: 1,
    );
  }

                                                       
  static Future<({bool ok, String message, String? dynId})>
  publishReserveDynamic({required int reserveSid, String text = ''}) async {
    return _createDyn(
      contents: [
        {'raw_text': text, 'type': 1, 'biz_id': ''},
      ],
      scene: 1,
      attachCard: buildReserveAttachCard(reserveSid),
    );
  }

                                                                  
                                                  
  static Future<({bool ok, String message, String? dynId})> _createDyn({
    required List<Map<String, dynamic>> contents,
    required int scene,
    Map<String, dynamic>? attachCard,
  }) async {
    if (!canUse) return (ok: false, message: '还没有登录，登录后才能发布动态', dynId: null);
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录', dynId: null);
    final mid = BilibiliAccountService.instance.mid;
    try {
      final uri = Uri.parse(_createDynApi).replace(
        queryParameters: {
          'platform': 'web',
          'csrf': csrf,
          'x-bili-device-req-json': '{"platform": "web", "device": "pc"}',
          'x-bili-web-req-json': '{"spm_id": "333.999"}',
        },
      );
      final resp = await (await NetworkSettingsService.instance.getApiClient())
          .post(
            uri,
            headers: {
              ..._headers(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'dyn_req': {
                'content': {'contents': contents},
                'scene': scene,
                'upload_id': _genUploadId(mid),
                'meta': {
                  'app_meta': {'from': 'create.dynamic.web', 'mobi_app': 'web'},
                },
                if (attachCard != null) 'attach_card': attachCard,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}', dynId: null);
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return (ok: false, message: '返回内容不是 JSON', dynId: null);
      }
      if (json['code'] != 0) {
        final msg = biliAsStr(json['message'] ?? json['msg']);
        return (
          ok: false,
          message: msg.isEmpty ? '接口返回 ${json['code']}' : msg,
          dynId: null,
        );
      }
      final dynId = biliAsStr(biliAsMap(json['data'])?['dyn_id']);
      return (ok: true, message: '', dynId: dynId.isEmpty ? null : dynId);
    } catch (e) {
      debugPrint('[DynOpus] 发布动态失败: $e');
      return (ok: false, message: '网络异常：${e.runtimeType}', dynId: null);
    }
  }

                                        
  static List<Map<String, dynamic>> _withMentions(
    List<Map<String, dynamic>> contents,
    List<({int mid, String name})> mentions,
  ) {
    if (mentions.isEmpty) return contents;
    final out = <Map<String, dynamic>>[];
    for (final node in contents) {
      if (node['type'] != 1) {
        out.add(node);
        continue;
      }
      final text = biliAsStr(node['raw_text']);
      final pieces = _splitMentions(text, mentions);
      if (pieces == null) {
        out.add(node);
        continue;
      }
      out.addAll(pieces);
    }
    return out;
  }

  static List<Map<String, dynamic>>? _splitMentions(
    String text,
    List<({int mid, String name})> mentions,
  ) {
    final candidates = mentions.where((m) => m.name.isNotEmpty).toList();
    if (candidates.isEmpty || !text.contains('@')) return null;
    final nodes = <Map<String, dynamic>>[];
    final buffer = StringBuffer();
    var index = 0;
    var matchedAny = false;

    void flushText() {
      if (buffer.isEmpty) return;
      nodes.add({'raw_text': buffer.toString(), 'type': 1, 'biz_id': ''});
      buffer.clear();
    }

    while (index < text.length) {
      var matched = false;
      if (text[index] == '@') {
        for (final mention in candidates) {
          final token = '@${mention.name}';
          if (text.startsWith(token, index)) {
            flushText();
            nodes.add({
              'raw_text': token,
              'type': 2,
              'biz_id': '${mention.mid}',
            });
            index += token.length;
            matched = true;
            matchedAny = true;
            break;
          }
        }
      }
      if (!matched) {
        buffer.write(text[index]);
        index++;
      }
    }
    flushText();
    return matchedAny ? nodes : null;
  }

               

                                                            
     
                                                 
                                          
                                       
  static Future<({bool ok, String message})> editDynamic({
    required BiliDynEditDraft draft,
    required String text,
    List<({int width, int height, double size, String url})> images = const [],
    bool? privatePub,
  }) async {
    if (!canUse) return (ok: false, message: '还没有登录，登录后才能编辑动态');
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    final mid = BilibiliAccountService.instance.mid;
    try {
      final uploadId = _genUploadId(mid);
      final signed = await WbiSign.sign({
        'platform': 'web',
        'csrf': csrf,
        'x-bili-device-req-json':
            '{"platform":"web","device":"pc","spmid":"333.1368"}',
        'w_dyn_req.upload_id': uploadId,
        'w_dyn_req.meta':
            '{"app_meta":{"from":"create.dynamic.web","mobi_app":"web"}}',
      });
      final uri = Uri.parse(_editApi).replace(queryParameters: signed);
      final body = <String, dynamic>{
        'dyn_req': buildEditDynReq(
          uploadId: uploadId,
          contents: buildEditContents(text, draft.tokens),
          pics: [
            for (final i in images)
              {
                'img_width': i.width,
                'img_height': i.height,
                'img_size': i.size,
                'img_src': i.url,
              },
          ],
          privatePub: privatePub ?? draft.privatePub,
          topicId: draft.topicId,
          topicName: draft.topicName,
        ),
        'dyn_id_str': draft.dynId,
        if (draft.isRepost)
          'web_repost_src': {'dyn_id_str': draft.repostId},
      };
      final resp = await (await NetworkSettingsService.instance.getApiClient())
          .post(
            uri,
            headers: {
              ..._headers(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return (ok: false, message: '返回内容不是 JSON');
      }
      return _asResult(json);
    } catch (e) {
      debugPrint('[DynOpus] 编辑动态失败: $e');
      return (ok: false, message: '网络异常：${e.runtimeType}');
    }
  }

               

                                        
                                               
  static Future<int> saveImagesToGallery(
    List<String> urls, {
    void Function(int done, int total)? onProgress,
  }) async {
    var saved = 0;
    final total = urls.length;
    for (var i = 0; i < total; i++) {
      onProgress?.call(i, total);
      final url = urls[i].trim();
      if (url.isEmpty) continue;
      try {
        final bytes = await BilibiliUserSpaceService.fetchBytes(url);
        if (bytes == null || bytes.isEmpty) continue;
        await Gal.putImageBytes(bytes, name: 'naviflash_dyn_${DateTime.now().millisecondsSinceEpoch}_$i');
        saved++;
      } catch (e) {
        debugPrint('[DynOpus] 保存图片失败($url): $e');
      }
    }
    onProgress?.call(total, total);
    return saved;
  }
}
