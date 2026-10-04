                                            
  
               
  
                                   
                                                                       
                                     
                                             
                                        
  
                    
                                                       
                                          
                                                            
                                       
                                                    
                                  
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'bilibili_account_service.dart';
import 'bilibili_recommend_service.dart';
import 'bilibili_user_space_service.dart' show WbiSign;
import 'network_settings_service.dart';

                             
class BiliRegion {
  final int tid;
  final String name;
  final IconData icon;

                       
  final List<BiliRegion> children;

  const BiliRegion({
    required this.tid,
    required this.name,
    required this.icon,
    this.children = const [],
  });
}

                                        
                                        
                                        
                             
class SubRegionLatestPage {
  final List<BiliRecommendItem> items;
  final int nextMainPn;
  final bool exhausted;
  final String? error;

  const SubRegionLatestPage({
    required this.items,
    required this.nextMainPn,
    required this.exhausted,
    this.error,
  });

  bool get isError => error != null;
}

abstract final class BilibiliRegionService {
  static const String _webApi = 'https://api.bilibili.com/x/web-interface';

                                                 
                                
                
  static const List<BiliRegion> regions = [
    BiliRegion(
      tid: 1,
      name: '动画',
      icon: Icons.animation,
      children: [
        BiliRegion(tid: 24, name: 'MAD·AMV', icon: Icons.movie_filter),
        BiliRegion(tid: 25, name: 'MMD·3D', icon: Icons.view_in_ar),
        BiliRegion(tid: 27, name: '综合', icon: Icons.category),
        BiliRegion(tid: 47, name: '短片·手书·配音', icon: Icons.draw),
        BiliRegion(tid: 210, name: '手办·模玩', icon: Icons.toys),
        BiliRegion(tid: 86, name: '特摄', icon: Icons.videocam),
      ],
    ),
    BiliRegion(
      tid: 3,
      name: '音乐',
      icon: Icons.music_note,
      children: [
        BiliRegion(tid: 28, name: '原创音乐', icon: Icons.music_note),
        BiliRegion(tid: 29, name: '音乐现场', icon: Icons.mic_external_on),
        BiliRegion(tid: 31, name: '翻唱', icon: Icons.mic),
        BiliRegion(tid: 59, name: '演奏', icon: Icons.piano),
        BiliRegion(tid: 193, name: 'MV', icon: Icons.play_circle),
        BiliRegion(tid: 30, name: 'VOCALOID·UTAU', icon: Icons.record_voice_over),
        BiliRegion(tid: 130, name: '音乐综合', icon: Icons.library_music),
        BiliRegion(tid: 194, name: '电音', icon: Icons.equalizer),
      ],
    ),
    BiliRegion(
      tid: 4,
      name: '游戏',
      icon: Icons.sports_esports,
      children: [
        BiliRegion(tid: 17, name: '单机游戏', icon: Icons.videogame_asset),
        BiliRegion(tid: 65, name: '网络游戏', icon: Icons.lan),
        BiliRegion(tid: 172, name: '手机游戏', icon: Icons.smartphone),
        BiliRegion(tid: 171, name: '电子竞技', icon: Icons.emoji_events),
        BiliRegion(tid: 173, name: '桌游棋牌', icon: Icons.casino),
        BiliRegion(tid: 136, name: '音游', icon: Icons.queue_music),
        BiliRegion(tid: 121, name: 'GMV', icon: Icons.theaters),
        BiliRegion(tid: 19, name: 'Mugen', icon: Icons.sports_mma),
      ],
    ),
    BiliRegion(
      tid: 5,
      name: '娱乐',
      icon: Icons.celebration,
      children: [
        BiliRegion(tid: 71, name: '综艺', icon: Icons.live_tv),
        BiliRegion(tid: 137, name: '明星', icon: Icons.star),
        BiliRegion(tid: 131, name: '娱乐圈', icon: Icons.auto_awesome),
      ],
    ),
    BiliRegion(
      tid: 36,
      name: '知识',
      icon: Icons.school,
      children: [
        BiliRegion(tid: 201, name: '科学科普', icon: Icons.science),
        BiliRegion(tid: 124, name: '社科·法律·心理', icon: Icons.account_balance),
        BiliRegion(tid: 228, name: '人文历史', icon: Icons.menu_book),
        BiliRegion(tid: 207, name: '财经商业', icon: Icons.trending_up),
        BiliRegion(tid: 208, name: '校园学习', icon: Icons.castle),
        BiliRegion(tid: 209, name: '职业职场', icon: Icons.work),
        BiliRegion(tid: 229, name: '设计·创意', icon: Icons.design_services),
        BiliRegion(tid: 122, name: '野生技能协会', icon: Icons.explore),
      ],
    ),
    BiliRegion(
      tid: 119,
      name: '鬼畜',
      icon: Icons.sentiment_very_satisfied,
      children: [
        BiliRegion(tid: 22, name: '鬼畜调教', icon: Icons.tune),
        BiliRegion(tid: 26, name: '音MAD', icon: Icons.graphic_eq),
        BiliRegion(tid: 126, name: '人力VOCALOID', icon: Icons.record_voice_over),
        BiliRegion(tid: 216, name: '鬼畜剧场', icon: Icons.theater_comedy),
      ],
    ),
    BiliRegion(
      tid: 129,
      name: '舞蹈',
      icon: Icons.accessibility_new,
      children: [
        BiliRegion(tid: 20, name: '宅舞', icon: Icons.favorite),
        BiliRegion(tid: 154, name: '舞蹈综合', icon: Icons.directions_run),
        BiliRegion(tid: 156, name: '舞蹈教程', icon: Icons.school),
        BiliRegion(tid: 198, name: '街舞', icon: Icons.skateboarding),
        BiliRegion(tid: 199, name: '明星舞蹈', icon: Icons.star),
        BiliRegion(tid: 200, name: '中国舞', icon: Icons.park),
      ],
    ),
    BiliRegion(
      tid: 155,
      name: '生活',
      icon: Icons.home,
      children: [
        BiliRegion(tid: 21, name: '日常', icon: Icons.wb_sunny),
        BiliRegion(tid: 138, name: '搞笑', icon: Icons.sentiment_very_satisfied),
        BiliRegion(tid: 239, name: '家居房产', icon: Icons.chair),
        BiliRegion(tid: 161, name: '手工', icon: Icons.handyman),
        BiliRegion(tid: 162, name: '绘画', icon: Icons.brush),
        BiliRegion(tid: 219, name: '户外', icon: Icons.landscape),
      ],
    ),
    BiliRegion(
      tid: 160,
      name: '时尚',
      icon: Icons.checkroom,
      children: [
        BiliRegion(tid: 157, name: '美妆护肤', icon: Icons.face),
        BiliRegion(tid: 158, name: '穿搭', icon: Icons.dry_cleaning),
        BiliRegion(tid: 159, name: '时尚潮流', icon: Icons.watch),
      ],
    ),
    BiliRegion(
      tid: 181,
      name: '影视',
      icon: Icons.movie_filter,
      children: [
        BiliRegion(tid: 85, name: '短片', icon: Icons.movie),
        BiliRegion(tid: 182, name: '影视杂谈', icon: Icons.forum),
        BiliRegion(tid: 183, name: '影视剪辑', icon: Icons.content_cut),
        BiliRegion(tid: 184, name: '预告·资讯', icon: Icons.notifications),
      ],
    ),
    BiliRegion(
      tid: 188,
      name: '科技',
      icon: Icons.memory,
      children: [
        BiliRegion(tid: 95, name: '软件应用', icon: Icons.apps),
        BiliRegion(tid: 122, name: '计算机技术', icon: Icons.computer),
        BiliRegion(tid: 96, name: '极客DIY', icon: Icons.construction),
        BiliRegion(tid: 230, name: '野生技术协会', icon: Icons.explore),
        BiliRegion(tid: 238, name: '摄影摄像', icon: Icons.camera),
        BiliRegion(tid: 735, name: '影音智能', icon: Icons.speaker),
      ],
    ),
    BiliRegion(
      tid: 211,
      name: '美食',
      icon: Icons.restaurant,
      children: [
        BiliRegion(tid: 76, name: '美食制作', icon: Icons.soup_kitchen),
        BiliRegion(tid: 212, name: '美食侦探', icon: Icons.search),
        BiliRegion(tid: 213, name: '美食测评', icon: Icons.thumb_up),
        BiliRegion(tid: 214, name: '田园美食', icon: Icons.eco),
        BiliRegion(tid: 215, name: '美食记录', icon: Icons.video_library),
      ],
    ),
    BiliRegion(
      tid: 217,
      name: '动物圈',
      icon: Icons.pets,
      children: [
        BiliRegion(tid: 216, name: '萌宠', icon: Icons.pets),
        BiliRegion(tid: 217, name: '动物综合', icon: Icons.park),
        BiliRegion(tid: 218, name: '野生动物', icon: Icons.forest),
      ],
    ),
    BiliRegion(
      tid: 223,
      name: '汽车',
      icon: Icons.directions_car,
      children: [
        BiliRegion(tid: 176, name: '汽车生活', icon: Icons.directions_car),
        BiliRegion(tid: 224, name: '汽车资讯', icon: Icons.newspaper),
        BiliRegion(tid: 225, name: '购车攻略', icon: Icons.shopping_cart),
        BiliRegion(tid: 226, name: '汽车文化', icon: Icons.local_car_wash),
        BiliRegion(tid: 227, name: '摩托车', icon: Icons.two_wheeler),
        BiliRegion(tid: 228, name: '赛车', icon: Icons.sports_motorsports),
      ],
    ),
    BiliRegion(
      tid: 234,
      name: '运动',
      icon: Icons.sports_basketball,
      children: [
        BiliRegion(tid: 241, name: '运动综合', icon: Icons.sports),
        BiliRegion(tid: 238, name: '健身', icon: Icons.fitness_center),
        BiliRegion(tid: 242, name: '篮球', icon: Icons.sports_basketball),
        BiliRegion(tid: 243, name: '足球', icon: Icons.sports_soccer),
        BiliRegion(tid: 246, name: '羽毛球', icon: Icons.sports_tennis),
        BiliRegion(tid: 249, name: '轮滑', icon: Icons.roller_skating),
      ],
    ),
    BiliRegion(
      tid: 177,
      name: '纪录片',
      icon: Icons.videocam,
      children: [
        BiliRegion(tid: 37, name: '人文·历史', icon: Icons.menu_book),
        BiliRegion(tid: 39, name: '科学·探索·自然', icon: Icons.public),
        BiliRegion(tid: 40, name: '社会·纪录·时事', icon: Icons.record_voice_over),
      ],
    ),
  ];

                                                 
  static BiliRegion? parentOf(int tid) {
    for (final region in regions) {
      for (final child in region.children) {
        if (child.tid == tid) return region;
      }
    }
    return null;
  }

  static const Map<String, String> _webHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

  static Future<Map<String, String>> _buildWebHeaders() async {
    final cookie = BilibiliAccountService.instance
        .cookieHeaderFor(BiliCookieScope.video)?['Cookie'];
    return {
      ..._webHeaders,
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

                                                      
                                                     
                                    
  static Future<BiliRecommendResult<BiliRecommendItem>> fetchRegionLatest({
    required int rid,
    required int pn,
    int ps = 20,
  }) async {
    try {
      final (rawList, err) = await _fetchNewlistRaw(rid, pn, ps);
      if (rawList == null) return BiliRecommendError(err);
      final items = rawList
          .map(_parseArchive)
          .where((v) => v != null)
          .cast<BiliRecommendItem>()
          .toList();
      return BiliRecommendOk(items);
    } catch (e) {
      debugPrint('[Region] latest 异常: $e');
      return BiliRecommendError('$e');
    }
  }

                                                
     
                                                   
                                                        
                                                        
                                                 
                                
  static Future<SubRegionLatestPage> fetchSubRegionLatest({
    required int rid,
    required int mainPn,
    int ps = 20,
  }) async {
    final parent = parentOf(rid);
    if (parent == null) {
      return const SubRegionLatestPage(
        items: [],
        nextMainPn: 1,
        exhausted: true,
        error: '非二级分区',
      );
    }
    try {
      final collected = <BiliRecommendItem>[];
      final seenBvids = <String>{};
      var pn = mainPn < 1 ? 1 : mainPn;
      var exhausted = false;
      while (collected.length < ps && !exhausted && pn - mainPn < 8) {
        final (rawList, err) = await _fetchNewlistRaw(parent.tid, pn, 50);
        if (rawList == null) {
          return SubRegionLatestPage(
            items: const [],
            nextMainPn: pn,
            exhausted: true,
            error: err,
          );
        }
        if (rawList.isEmpty) {
          exhausted = true;               
          break;
        }
        for (final archive in rawList) {
          if (_toInt(archive['tid']) != rid) continue;
          final item = _parseArchive(archive);
          if (item == null || !seenBvids.add(item.bvid)) continue;
          collected.add(item);
        }
        pn++;
      }
      return SubRegionLatestPage(
        items: collected,
        nextMainPn: pn,
        exhausted: exhausted,
      );
    } catch (e) {
      debugPrint('[Region] subRegionLatest 异常: $e');
      return SubRegionLatestPage(
        items: const [],
        nextMainPn: mainPn,
        exhausted: true,
        error: '$e',
      );
    }
  }

                                              
                                            
  static Future<(List<Map<String, dynamic>>?, String)> _fetchNewlistRaw(
    int rid,
    int pn,
    int ps,
  ) async {
    final uri = Uri.parse('$_webApi/newlist').replace(
      queryParameters: {
        'rid': rid.toString(),
        'pn': pn.toString(),
        'ps': ps.toString(),
      },
    );
    final client = await NetworkSettingsService.instance.getApiClient();
    final resp = await client
        .get(uri, headers: await _buildWebHeaders())
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      debugPrint('[Region] newlist HTTP ${resp.statusCode}');
      return (null, 'HTTP ${resp.statusCode}');
    }
    final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
    if (json['code'] != 0) {
      debugPrint('[Region] newlist code=${json['code']} ${json['message']}');
      return (null, 'code=${json['code']} ${json['message']}');
    }
    final data = json['data'];
    final rawList = data is Map ? data['archives'] : null;
    if (rawList is! List) {
      return (null, '数据为空');
    }
    return (
      rawList.whereType<Map<String, dynamic>>().toList(),
      '',
    );
  }

                                                   
                                                   
                                                      
                                                      
  static Future<BiliRecommendResult<BiliRecommendItem>> _fetchLegacyRegionRank(
    int rid,
  ) async {
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final headers = await _buildWebHeaders();
      final merged = <String, BiliRecommendItem?>{};
      for (final day in const ['3', '7']) {
        final uri = Uri.parse('$_webApi/ranking/region').replace(
          queryParameters: {'rid': rid.toString(), 'day': day},
        );
        final resp = await client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 15));
        if (resp.statusCode != 200) {
          debugPrint('[Region] legacy HTTP ${resp.statusCode}');
          continue;
        }
        final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
        if (json['code'] != 0) {
          debugPrint('[Region] legacy code=${json['code']} ${json['message']}');
          continue;
        }
        final data = json['data'];
        if (data is! List) continue;
        for (final raw in data.whereType<Map<String, dynamic>>()) {
          final item = _parseLegacyArchive(raw);
          if (item != null) merged.putIfAbsent(item.bvid, () => item);
        }
      }
      if (merged.isEmpty) {
        return BiliRecommendError('数据为空');
      }
      return BiliRecommendOk(
        merged.values.whereType<BiliRecommendItem>().toList(),
      );
    } catch (e) {
      debugPrint('[Region] legacy 异常: $e');
      return BiliRecommendError('$e');
    }
  }

                                                           
                                     
                                                 
  static Future<BiliRecommendResult<BiliRecommendItem>> fetchRegionRank({
    required int rid,
  }) async {
    if (parentOf(rid) != null) {
      return _fetchLegacyRegionRank(rid);
    }
    try {
      final params = await WbiSign.sign({
        'rid': rid.toString(),
        'type': 'all',
      });
      final uri = Uri.parse('$_webApi/ranking/v2').replace(
        queryParameters: params,
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildWebHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        debugPrint('[Region] rank HTTP ${resp.statusCode}');
        return BiliRecommendError('HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) {
        debugPrint('[Region] rank code=${json['code']} ${json['message']}');
        return BiliRecommendError('code=${json['code']} ${json['message']}');
      }
      final data = json['data'];
      final rawList = data is Map ? data['list'] : null;
      if (rawList is! List) {
        return BiliRecommendError('数据为空');
      }
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(_parseArchive)
          .where((v) => v != null)
          .cast<BiliRecommendItem>()
          .toList();
      return BiliRecommendOk(items);
    } catch (e) {
      debugPrint('[Region] rank 异常: $e');
      return BiliRecommendError('$e');
    }
  }

                                                   
  static BiliRecommendItem? _parseArchive(Map<String, dynamic> json) {
    final bvid = json['bvid']?.toString() ?? '';
    if (bvid.isEmpty) return null;
    final title = json['title']?.toString() ?? '';
    if (title.isEmpty) return null;
    final owner = json['owner'];
    final stat = json['stat'];
    final rcmdReason = json['rcmd_reason'];
    return BiliRecommendItem(
      bvid: bvid,
      aid: _toInt(json['aid']),
      cid: _toInt(json['cid']),
      title: title,
      cover: json['pic']?.toString() ?? '',
      duration: _toInt(json['duration']),
      pubdate: _toInt(json['pubdate']),
      ownerName: owner is Map ? (owner['name']?.toString() ?? '') : '',
      ownerMid: owner is Map ? _toInt(owner['mid']) : 0,
      view: stat is Map ? _toInt(stat['view']) : 0,
      danmaku: stat is Map ? _toInt(stat['danmaku']) : 0,
      like: stat is Map ? _toInt(stat['like']) : 0,
      rcmdReason:
          rcmdReason is Map ? (rcmdReason['content']?.toString() ?? '') : '',
    );
  }

                                                       
                                                      
  static BiliRecommendItem? _parseLegacyArchive(Map<String, dynamic> json) {
    final bvid = json['bvid']?.toString() ?? '';
    if (bvid.isEmpty) return null;
    final title = json['title']?.toString() ?? '';
    if (title.isEmpty) return null;
    return BiliRecommendItem(
      bvid: bvid,
      aid: _toInt(json['aid']),
      cid: 0,                               
      title: title,
      cover: json['pic']?.toString() ?? '',
      duration: _parseClockDuration(json['duration']),
      pubdate: 0,                             
      ownerName: json['author']?.toString() ?? '',
      ownerMid: _toInt(json['mid']),
      view: _toInt(json['play']),
      danmaku: _toInt(json['video_review']),
      like: 0,
      rcmdReason: '',
    );
  }

                                             
  static int _parseClockDuration(dynamic v) {
    final s = v?.toString() ?? '';
    if (!s.contains(':')) return _toInt(v);
    var sec = 0;
    for (final part in s.split(':')) {
      sec = sec * 60 + (int.tryParse(part.trim()) ?? 0);
    }
    return sec;
  }

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }
}