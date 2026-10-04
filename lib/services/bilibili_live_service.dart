                                          
  
                                                 
  
                                              
                                              
                                   
                                                              
                                           
                               
                                                      
                                                            
                                             
                                                                 
                                                                  
                                                               
                                       
                                                     
                                                                       
                                                                         
                                                                         
                                                       
                                                                             
  
                                                      
                                               
                                        
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' show Color;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bilibili_account_service.dart';
import 'bilibili_user_space_service.dart' show WbiSign;
import 'network_settings_service.dart';

                                           
          
                                           

int _toInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}

String _toStr(dynamic v) => v?.toString() ?? '';

String _pick(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return '';
}

                                           
      
                                           

                               
class LiveRoomItem {
                                 
  final int roomId;

  final int uid;
  final String title;

                            
  final String cover;

  final String uname;
  final String face;

                
  final int online;

                                             
  final String onlineText;

  final int areaId;
  final int parentAreaId;
  final String areaName;
  final String parentAreaName;

  const LiveRoomItem({
    required this.roomId,
    required this.uid,
    required this.title,
    required this.cover,
    required this.uname,
    required this.face,
    required this.online,
    required this.onlineText,
    this.areaId = 0,
    this.parentAreaId = 0,
    this.areaName = '',
    this.parentAreaName = '',
  });

                             
  String get url => 'https://live.bilibili.com/$roomId';
}

                                                                   
class LiveSearchRoomItem {
  final int roomId;
  final String title;
  final String cover;
  final String uname;
  final String face;

                                      
  final String onlineText;

  const LiveSearchRoomItem({
    required this.roomId,
    required this.title,
    required this.cover,
    required this.uname,
    required this.face,
    this.onlineText = '',
  });

                                
  LiveRoomItem toRoomItem() => LiveRoomItem(
    roomId: roomId,
    uid: 0,
    title: title,
    cover: cover,
    uname: uname,
    face: face,
    online: 0,
    onlineText: onlineText,
  );
}

                              
class LiveSearchUserItem {
  final int mid;
  final String uname;
  final String face;

                              
  final bool living;
  final String areaName;
  final int fans;

                        
  final int roomId;

  const LiveSearchUserItem({
    required this.mid,
    required this.uname,
    required this.face,
    this.living = false,
    this.areaName = '',
    this.fans = 0,
    this.roomId = 0,
  });
}

                                    
enum LiveSearchKind { room, user }

         
class LiveAreaItem {
  final int id;
  final int parentId;
  final String name;
  final String pic;

  const LiveAreaItem({
    required this.id,
    required this.parentId,
    required this.name,
    this.pic = '',
  });

                          
  bool get isAll => id == 0;
}

                  
class LiveAreaGroup {
  final int id;
  final String name;
  final List<LiveAreaItem> children;

  const LiveAreaGroup({
    required this.id,
    required this.name,
    this.children = const [],
  });
}

                                      
class LiveRoomDetail {
  final int roomId;
  final int uid;

           
  final String title;

           
  final String cover;

                                            
  final String appBackground;

                      
  final String keyframe;
  final String uname;
  final String face;

                        
  final int liveStatus;

                      
  final int liveStartTime;

                              
  final String watchedText;

                            
  final int fansNum;
  final String areaName;
  final String parentAreaName;

  const LiveRoomDetail({
    required this.roomId,
    required this.uid,
    required this.title,
    required this.cover,
    required this.keyframe,
    required this.uname,
    required this.face,
    required this.liveStatus,
    required this.liveStartTime,
    required this.watchedText,
    required this.fansNum,
    required this.areaName,
    required this.parentAreaName,
    this.appBackground = '',
  });

  bool get isLiving => liveStatus == 1;
}

                                          
class LiveStreamOption {
                                       
  final String protocolName;

                      
  final String formatName;

                 
  final String codecName;

                                         
  final String url;

  final int qn;

                                            
  final int score;

  const LiveStreamOption({
    required this.protocolName,
    required this.formatName,
    required this.codecName,
    required this.url,
    required this.qn,
    required this.score,
  });

  String get label => '$formatName·$codecName';
}

                                
class LivePlayInfo {
                            
  final int roomId;
  final int uid;
  final int liveStatus;

                      
  final int liveTime;

                                   
  final bool isPortrait;

                  
  final int currentQn;

                     
  final List<int> acceptQn;

                                
  final List<LiveStreamOption> streams;

  const LivePlayInfo({
    required this.roomId,
    required this.uid,
    required this.liveStatus,
    required this.liveTime,
    required this.isPortrait,
    required this.currentQn,
    required this.acceptQn,
    required this.streams,
  });
}

                                                       
class LiveEmote {
                         
  final String name;
  final String url;
  final int width;
  final int height;

  const LiveEmote({
    required this.name,
    required this.url,
    this.width = 0,
    this.height = 0,
  });
}

                                                               
class LiveSuperChatMsg {
  final int id;
  final String uname;
  final int uid;
  final String face;
  final num price;
  final String message;
  final Color topColor;
  final Color bottomColor;

               
  final int endTime;

  const LiveSuperChatMsg({
    required this.id,
    required this.uname,
    required this.uid,
    required this.face,
    required this.price,
    required this.message,
    required this.topColor,
    required this.bottomColor,
    required this.endTime,
  });

  static Color _color(dynamic v) =>
      Color(0xFF000000 | (_toInt(v) & 0xFFFFFF));

                                         
  static LiveSuperChatMsg? fromData(Map<String, dynamic> data) {
    final id = _toInt(data['id']);
    if (id <= 0) return null;
    final user =
        data['user_info'] is Map<String, dynamic>
            ? data['user_info'] as Map<String, dynamic>
            : const <String, dynamic>{};
    return LiveSuperChatMsg(
      id: id,
      uname: _toStr(user['uname']),
      uid: _toInt(data['uid']),
      face: BilibiliLiveService._fixCover(_toStr(user['face'])),
      price: data['price'] is num
          ? data['price'] as num
          : (num.tryParse('${data['price']}') ?? 0),
      message: _toStr(data['message']),
      topColor: _color(data['background_color']),
      bottomColor: _color(data['background_bottom_color']),
      endTime: _toInt(data['end_time']),
    );
  }
}

                                           
                             
                                           

                              
enum LiveRankType {
  online('在线榜', 'contribution_rank'),
  daily('日榜', 'today_rank'),
  weekly('周榜', 'current_week_rank'),
  monthly('月榜', 'current_month_rank');

  final String title;
  final String sw1tch;

  const LiveRankType(this.title, this.sw1tch);
}

          
class LiveRankItem {
  final int uid;
  final String name;
  final String face;
  final int score;
  final String medalName;
  final int medalLevel;
  final int medalColorStart;
  final int medalColorText;

  const LiveRankItem({
    required this.uid,
    required this.name,
    required this.face,
    required this.score,
    this.medalName = '',
    this.medalLevel = 0,
    this.medalColorStart = 0,
    this.medalColorText = 0,
  });

  factory LiveRankItem.fromJson(Map<String, dynamic> json) {
    final uinfo = json['uinfo'];
    final medal = uinfo is Map ? uinfo['medal'] : null;
    final medalMap = medal is Map ? medal : const {};
    return LiveRankItem(
      uid: _toInt(json['uid']),
      name: _toStr(json['name']),
      face: BilibiliLiveService._fixCover(_toStr(json['face'])),
      score: _toInt(json['score']),
      medalName: _toStr(medalMap['name']),
      medalLevel: _toInt(medalMap['level']),
      medalColorStart: _toInt(medalMap['v2_medal_color_start']),
      medalColorText: _toInt(medalMap['v2_medal_color_text']),
    );
  }
}

                        
class LiveGuardItem {
  final int uid;
  final String username;
  final String face;

                         
  final int guardLevel;

  const LiveGuardItem({
    required this.uid,
    required this.username,
    required this.face,
    required this.guardLevel,
  });

  String get guardLabel => switch (guardLevel) {
        1 => '总督',
        2 => '提督',
        _ => '舰长',
      };

  factory LiveGuardItem.fromJson(Map<String, dynamic> json) {
    return LiveGuardItem(
      uid: _toInt(json['uid']),
      username: _toStr(json['username']),
      face: BilibiliLiveService._fixCover(_toStr(json['face'])),
      guardLevel: _toInt(json['guard_level']),
    );
  }
}

            
class LiveMedalItem {
  final String name;
  final int level;
  final int ruid;              
  final String targetName;
  final String targetIcon;
  final int liveStatus;           
  final bool wearing;          
  final int colorStart;
  final int colorText;

  const LiveMedalItem({
    required this.name,
    required this.level,
    required this.ruid,
    required this.targetName,
    required this.targetIcon,
    required this.liveStatus,
    required this.wearing,
    required this.colorStart,
    required this.colorText,
  });

  factory LiveMedalItem.fromJson(Map<String, dynamic> json) {
    final medalInfo = json['medal_info'];
    final medal = json['uinfo_medal'] ?? medalInfo;
    final map = medal is Map ? medal : const {};
    return LiveMedalItem(
      name: _toStr(map['medal_name'] ?? map['name']),
      level: _toInt(map['level']),
      ruid: _toInt(map['ruid']),
      targetName: _toStr(json['target_name']),
      targetIcon: BilibiliLiveService._fixCover(_toStr(json['target_icon'])),
      liveStatus: _toInt(json['live_status']),
      wearing: _toInt(medalInfo is Map ? medalInfo['wearing_status'] : 0) == 1,
      colorStart: _toInt(map['medal_color_start'] ?? map['v2_medal_color_start']),
      colorText: _toInt(map['medal_color_text'] ?? map['v2_medal_color_text']),
    );
  }
}

                     
class LiveMedalWallData {
  final List<LiveMedalItem> items;
  final int count;
  final String name;
  final String icon;

  const LiveMedalWallData({
    required this.items,
    required this.count,
    required this.name,
    required this.icon,
  });
}

                       
class LiveShieldInfo {
  final List<String> keywords;
  final Map<int, String> users;

  const LiveShieldInfo({required this.keywords, required this.users});

  bool get isEmpty => keywords.isEmpty && users.isEmpty;
}

                                           
                 
                                           

sealed class LiveResult<T> {}

                 
class LiveOk<T> extends LiveResult<T> {
  final List<T> items;

                          
  final bool hasMore;

                                    
  final int? total;

  LiveOk(this.items, {this.hasMore = true, this.total});
}

                              
class LiveError<T> extends LiveResult<T> {
  final String detail;
  LiveError(this.detail);
}

                                           
      
                                           

abstract final class BilibiliLiveService {
  static const String _liveApi = 'https://api.live.bilibili.com';

                             
  static const String sortDefault = '';
  static const String sortOnline = 'online';
  static const String sortLiveTime = 'live_time';

  static const Map<String, String> _webHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://live.bilibili.com',
  };

                                                             
                                                      
  static const String _appKey = 'dfca71928277209b';
  static const String _appSec = 'b5475a8825547a4fc26c7d518eaaa02e';
  static const String _appUA =
      'Mozilla/5.0 BiliDroid/8.43.0 (bbcallen@gmail.com) os/android '
      'model/android mobi_app/android build/8430300 channel/master '
      'innerVer/8430300 osVer/15 network/2';
  static const String _appStatistics =
      '{"appId":1,"platform":3,"version":"8.43.0","abtest":""}';
  static const String _spiApi =
      'https://api.bilibili.com/x/frontend/finger/spi';

                                               
                                              
  static String? _fpBuvid3;
  static String? _fpBuvid4;

  static Future<void> _ensureDeviceFp() async {
    if (_fpBuvid3 != null) return;
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(Uri.parse(_spiApi), headers: _webHeaders)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return;
      final decoded = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (decoded is! Map<String, dynamic> || _toInt(decoded['code']) != 0) {
        return;
      }
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return;
      final b3 = _toStr(data['b_3']);
      if (b3.isNotEmpty) {
        _fpBuvid3 = b3;
        _fpBuvid4 = _toStr(data['b_4']);
      }
    } catch (e) {
      debugPrint('[Live] 获取设备指纹失败: $e');
    }
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

                                                                   
                                                       
                                                       
                                       
  static String? _appBuvid;

  static Future<String> _ensureAppBuvid() async {
    final cached = _appBuvid;
    if (cached != null && cached.isNotEmpty) return cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      var buvid = prefs.getString('liveAppBuvid') ?? '';
      if (buvid.isEmpty) {
        final r = Random();
        final md5Str = md5
            .convert(List<int>.generate(16, (_) => r.nextInt(256)))
            .toString();
        buvid = 'XY${md5Str[2]}${md5Str[12]}${md5Str[22]}$md5Str';
        await prefs.setString('liveAppBuvid', buvid);
      }
      _appBuvid = buvid;
      return buvid;
    } catch (_) {
      final r = Random();
      final md5Str = md5
          .convert(List<int>.generate(16, (_) => r.nextInt(256)))
          .toString();
      return 'XY${md5Str[2]}${md5Str[12]}${md5Str[22]}$md5Str';
    }
  }

                                             
                                                                     
  static Map<String, String> _appSignedParams(
    Map<String, String> params,
  ) {
    final all = <String, String>{
      ...params,
      'appkey': _appKey,
      'ts': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
    };
    final sortedKeys = all.keys.toList()..sort();
    final query = sortedKeys
        .map((k) =>
            '${Uri.encodeComponent(k)}='
            '${Uri.encodeComponent(all[k] ?? '')}')
        .join('&');
    final sign = md5.convert(utf8.encode('$query$_appSec')).toString();
    return {...all, 'sign': sign};
  }

                                               
     
                                              
                                            
                                                            
                   
  static String _buildAppCookie(String? account) {
    final buvid3 = _fpBuvid3 ?? _genBuvid3();
    if (account == null || account.isEmpty) {
      final extra =
          (_fpBuvid4?.isNotEmpty ?? false) ? '; buvid4=$_fpBuvid4' : '';
      return 'buvid3=$buvid3$extra';
    }
    if (account.contains('buvid3=')) return _appendBuvid4(account);
    return _appendBuvid4('$account; buvid3=$buvid3');
  }

  static String _appendBuvid4(String cookie) {
    if (!cookie.contains('buvid4=') && (_fpBuvid4?.isNotEmpty ?? false)) {
      return '$cookie; buvid4=$_fpBuvid4';
    }
    return cookie;
  }

  static Future<Map<String, String>> _buildAppHeaders() async {
    await _ensureDeviceFp();
    final account = BilibiliAccountService.instance
        .cookieHeaderFor(BiliCookieScope.video)?['Cookie'];
    final cookie = _buildAppCookie(account);
    final buvid = await _ensureAppBuvid();
                                               
                                          
    final mid = BilibiliAccountService.instance.mid;
    return {
      ...NetworkSettingsService.instance.apiHeaders,
      'User-Agent': _appUA,
      'Cookie': cookie,
      'buvid': buvid,
      'fp_local': '1' * 64,
      'fp_remote': '1' * 64,
      'session_id': '11111111',
      'env': 'prod',
      'app-key': 'android',
      'x-bili-trace-id':
          '11111111111111111111111111111111:1111111111111111:0:0',
      'x-bili-aurora-eid': '',
      'x-bili-aurora-zone': '',
      if (mid > 0) 'x-bili-mid': mid.toString(),
      'bili-http-engine': 'cronet',
    };
  }

  static Future<Map<String, String>> _buildHeaders() async {
    final cookie = BilibiliAccountService.instance
        .cookieHeaderFor(BiliCookieScope.video)?['Cookie'];
    return {
      ..._webHeaders,
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

                                          
  static String _friendlyMessage(int code, String raw) {
    return switch (code) {
      -352 => '被 B 站风控拦了（-352），稍等一会儿再刷新试试',
      -101 => '还没有登录，登录后才能看关注的主播',
      -400 => '请求参数不对（$code）',
      -403 => '没有权限访问（$code）',
      _ => raw.isEmpty ? '接口返回 $code' : '$raw（$code）',
    };
  }

  static LiveError<T> _err<T>(String msg) {
    debugPrint('[Live] $msg');
    return LiveError<T>(msg);
  }

                                                      
  static Future<({Map<String, dynamic> json, String? err})> _get(
    String path,
    Map<String, String> query,
  ) async {
    try {
      final uri = Uri.parse('$_liveApi$path').replace(queryParameters: query);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (json: const <String, dynamic>{}, err: 'HTTP ${resp.statusCode}');
      }
      final decoded = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        return (json: const <String, dynamic>{}, err: '返回内容不是 JSON 对象');
      }
      final code = _toInt(decoded['code']);
      if (code != 0) {
        final raw = _toStr(decoded['message'] ?? decoded['msg']);
        return (json: const <String, dynamic>{}, err: _friendlyMessage(code, raw));
      }
      return (json: decoded, err: null);
    } catch (e) {
      return (json: const <String, dynamic>{}, err: '网络异常：${e.runtimeType}');
    }
  }

               

                                                          
  static Future<LiveResult<LiveRoomItem>> fetchRecommend({
    int page = 1,
    int pageSize = 30,
  }) async {
    final (:json, :err) = await _get('/room/v1/room/get_user_recommend', {
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'platform': 'web',
    });
    if (err != null) return _err(err);

    final rawList = json['data'];
    if (rawList is! List) return _err('推荐直播数据为空');

    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map(_parseRecommend)
        .where((v) => v != null)
        .cast<LiveRoomItem>()
        .toList();
    return LiveOk(items, hasMore: items.length >= pageSize);
  }

                           
  static LiveRoomItem? _parseRecommend(Map<String, dynamic> json) {
    final roomId = _toInt(json['roomid']);
    if (roomId <= 0) return null;
    final watched = json['watched_show'];
    return LiveRoomItem(
      roomId: roomId,
      uid: _toInt(json['uid']),
      title: _toStr(json['title']),
      cover: _fixCover(_pick(json, ['user_cover', 'system_cover'])),
      uname: _toStr(json['uname']),
      face: _fixCover(_toStr(json['face'])),
      online: _toInt(json['online']),
      onlineText: watched is Map ? _toStr(watched['text_large']) : '',
      areaId: _toInt(json['area']),
      areaName: _toStr(json['areaName']),
    );
  }

              

                                                          
  static Future<LiveResult<LiveAreaGroup>> fetchAreaList() async {
    final (:json, :err) = await _get('/room/v1/Area/getList', {
      'parent_id': '0',
      'source_id': '2',
      'need_entrance': '1',
    });
    if (err != null) return _err(err);

    final rawList = json['data'];
    if (rawList is! List) return _err('分区数据为空');

    final groups = <LiveAreaGroup>[];
    for (final g in rawList.whereType<Map<String, dynamic>>()) {
      final id = _toInt(g['id']);
      final name = _toStr(g['name']);
      if (id <= 0 || name.isEmpty) continue;
      final children = (g['list'] is List ? g['list'] as List : const [])
          .whereType<Map<String, dynamic>>()
          .map((c) => LiveAreaItem(
                id: _toInt(c['id']),
                parentId: _toInt(c['parent_id'] is String
                    ? c['parent_id']
                    : (c['parent_id'] ?? id)),
                name: _toStr(c['name']),
                pic: _toStr(c['pic']),
              ))
          .where((c) => c.name.isNotEmpty)
          .toList();
                                              
      if (children.isEmpty || !children.any((c) => c.isAll)) {
        children.insert(0, LiveAreaItem(id: 0, parentId: id, name: '全部'));
      }
      groups.add(LiveAreaGroup(id: id, name: name, children: children));
    }
    if (groups.isEmpty) return _err('分区数据为空');
    return LiveOk(groups, hasMore: false);
  }

               

                          
     
                                                                    
                                                                  
                                             
                      
     
                                                          
                                                
                             
  static Future<LiveResult<LiveRoomItem>> fetchAreaRooms({
    required int parentAreaId,
    int areaId = 0,
    String sortType = sortDefault,
    int page = 1,
    int pageSize = 20,
  }) async {
    debugPrint(
        '[Live] 分区房间 parent=$parentAreaId area=$areaId sort=$sortType page=$page');
    final app = await _fetchAreaRoomsApp(
      parentAreaId: parentAreaId,
      areaId: areaId,
      sortType: sortType,
      page: page,
      pageSize: pageSize,
    );
    if (app case LiveOk<LiveRoomItem>()) {
      debugPrint('[Live] 分区房间 APP 端成功 ${app.items.length} 条');
      return app;
    }
    final appErr = (app as LiveError<LiveRoomItem>).detail;
    debugPrint('[Live] 分区房间 APP 端失败，回退 Web 端: $appErr');
    final web = await _fetchAreaRoomsWeb(
      parentAreaId: parentAreaId,
      areaId: areaId,
      sortType: sortType,
      page: page,
      pageSize: pageSize,
    );
    if (web case LiveOk<LiveRoomItem>()) {
      debugPrint('[Live] 分区房间 Web 端成功 ${web.items.length} 条');
      return web;
    }
    final webErr = (web as LiveError<LiveRoomItem>).detail;
    debugPrint('[Live] 分区房间 Web 端也失败: $webErr');
                                       
    return _err(appErr);
  }

                                                                
  static Future<LiveResult<LiveRoomItem>> _fetchAreaRoomsApp({
    required int parentAreaId,
    required int areaId,
    required String sortType,
    required int page,
    required int pageSize,
  }) async {
    try {
      final params = _appSignedParams({
        'actionKey': 'appkey',
        'channel': 'master',
        'area_id': areaId.toString(),
        'parent_area_id': parentAreaId.toString(),
        'build': '8430300',
        'version': '8.43.0',
        'c_locale': 'zh_CN',
        'device': 'android',
        'device_name': 'android',
        'device_type': '0',
        'fnval': '912',
        'disable_rcmd': '0',
        'https_url_req': '1',
        'mobi_app': 'android',
        'module_select': '0',
        'network': 'wifi',
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'platform': 'android',
        'qn': '0',
        if (sortType.isNotEmpty) 'sort_type': sortType,
        'tag_version': '1',
        's_locale': 'zh_CN',
        'scale': '2',
        'statistics': _appStatistics,
      });
      final uri = Uri.parse(
              '$_liveApi/xlive/app-interface/v2/second/getList')
          .replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildAppHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return _err('HTTP ${resp.statusCode}');
      }
      final decoded = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        return _err('返回内容不是 JSON 对象');
      }
      final code = _toInt(decoded['code']);
      if (code != 0) {
        final raw = _toStr(decoded['message'] ?? decoded['msg']);
        debugPrint('[Live] APP 端业务码 $code $raw');
        return _err(_friendlyMessage(code, raw));
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return _err('分区直播数据为空');

      final rawList = data['list'];
      final items = (rawList is List ? rawList : const [])
          .whereType<Map<String, dynamic>>()
          .map(_parseSecondList)
          .where((v) => v != null)
          .cast<LiveRoomItem>()
          .toList();

                                                 
      final count = _toInt(data['count']);
      final hasMore = count > 0
          ? page * pageSize < count
          : (data['hasMore'] is bool
              ? data['hasMore'] as bool
              : items.length >= pageSize);
      if (items.isEmpty && page == 1) return _err('这个分区现在没人开播');
      return LiveOk(items, hasMore: hasMore);
    } catch (e) {
      return _err('网络异常：${e.runtimeType}');
    }
  }

                                        
  static Future<LiveResult<LiveRoomItem>> _fetchAreaRoomsWeb({
    required int parentAreaId,
    required int areaId,
    required String sortType,
    required int page,
    required int pageSize,
  }) async {
    final (:json, :err) =
        await _get('/xlive/web-interface/v1/second/getList', {
      'platform': 'web',
      'parent_area_id': parentAreaId.toString(),
      'area_id': areaId.toString(),
      'sort_type': sortType,
      'page': page.toString(),
      'page_size': pageSize.toString(),
    });
    if (err != null) return _err(err);

    final data = json['data'];
    if (data is! Map<String, dynamic>) return _err('分区直播数据为空');

    final rawList = data['list'];
    final items = (rawList is List ? rawList : const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseSecondList)
        .where((v) => v != null)
        .cast<LiveRoomItem>()
        .toList();

    final hasMore = data['hasMore'] is bool
        ? data['hasMore'] as bool
        : items.length >= pageSize;
    if (items.isEmpty && page == 1) return _err('这个分区现在没人开播');
    return LiveOk(items, hasMore: hasMore);
  }

                                               
     
                                                                  
                                                             
                                                      
                               
  static LiveRoomItem? _parseSecondList(Map<String, dynamic> json) {
    final roomId = _toInt(_pickRaw(json, ['roomid', 'room_id']));
    if (roomId <= 0) return null;
    final watched = json['watched_show'];
    return LiveRoomItem(
      roomId: roomId,
      uid: _toInt(_pickRaw(json, ['uid'])),
      title: _toStr(json['title']),
      cover: _fixCover(_pick(json,
          ['cover', 'keyframe', 'user_cover', 'system_cover', 'pic'])),
      uname: _toStr(json['uname']),
      face: _fixCover(_toStr(json['face'])),
      online: _toInt(_pickRaw(json, ['online', 'online_num'])),
      onlineText: watched is Map ? _toStr(watched['text_large']) : '',
      areaId: _toInt(_pickRaw(json, ['area_id', 'area_v2_id'])),
      parentAreaId: _toInt(
          _pickRaw(json, ['parent_area_id', 'area_v2_parent_id'])),
      areaName: _pick(json, ['area_name', 'areaName', 'area_v2_name']),
      parentAreaName: _pick(json, ['parent_area_name', 'parentName']),
    );
  }

               

                                                         
  static Future<LiveResult<LiveRoomItem>> fetchFollowing({
    int page = 1,
    int pageSize = 9,
  }) async {
    if (!BilibiliAccountService.instance.isLoggedIn) {
      return _err('还没有登录，登录后才能看关注的主播');
    }
    final (:json, :err) = await _get('/xlive/web-ucenter/user/following', {
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'ignoreRecord': '1',
      'hit_ab': 'true',
    });
    if (err != null) return _err(err);

    final data = json['data'];
    if (data is! Map<String, dynamic>) return _err('关注列表为空');

    final rawList = data['list'];
    final items = (rawList is List ? rawList : const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseFollowing)
        .where((v) => v != null)
        .cast<LiveRoomItem>()
        .toList();

                                   
    final total = _toInt(data['count']);
    final hasMore = total > 0 ? items.isNotEmpty : items.length >= pageSize;
    return LiveOk(items, hasMore: hasMore, total: total);
  }

                                       
  static LiveRoomItem? _parseFollowing(Map<String, dynamic> json) {
    final roomId = _toInt(_pickRaw(json, ['roomid', 'room_id']));
    if (roomId <= 0) return null;
    final watched = json['watched_show'];
    return LiveRoomItem(
      roomId: roomId,
      uid: _toInt(_pickRaw(json, ['uid'])),
      title: _toStr(json['title']),
      cover: _fixCover(
          _pick(json, ['cover', 'keyframe', 'system_cover', 'user_cover'])),
      uname: _toStr(json['uname']),
      face: _fixCover(_toStr(json['face'])),
      online: _toInt(_pickRaw(json, ['online'])),
      onlineText: watched is Map ? _toStr(watched['text_large']) : '',
      areaId: _toInt(_pickRaw(json, ['area_id', 'area_v2_id'])),
      parentAreaId: _toInt(_pickRaw(json, ['parent_area_id'])),
      areaName: _pick(json, ['area_name', 'area_v2_name', 'areaName']),
      parentAreaName: _pick(json, ['parent_area_name', 'parentName']),
    );
  }

                                                                              

                 
     
                                                    
                                    
  static Future<
      ({
        List<LiveSearchRoomItem> rooms,
        List<LiveSearchUserItem> users,
        int totalRoom,
        int totalUser,
        String? err,
      })>
      searchLive({required String keyword, int page = 1, int pageSize = 30}) async {
    final kw = keyword.trim();
    if (kw.isEmpty) {
      return (
        rooms: const <LiveSearchRoomItem>[],
        users: const <LiveSearchUserItem>[],
        totalRoom: 0,
        totalUser: 0,
        err: '请输入搜索内容',
      );
    }
    try {
      final params = _appSignedParams({
        'actionKey': 'appkey',
        'build': '8430300',
        'channel': 'master',
        'version': '8.43.0',
        'c_locale': 'zh_CN',
        'device': 'android',
        'mobi_app': 'android',
        'platform': 'android',
        's_locale': 'zh_CN',
        'disable_rcmd': '0',
        'keyword': kw,
        'page': page.toString(),
        'pagesize': pageSize.toString(),
        'statistics': _appStatistics,
      });
      final uri = Uri.parse(
        '$_liveApi/xlive/app-interface/v2/search_live',
      ).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildAppHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (
          rooms: const <LiveSearchRoomItem>[],
          users: const <LiveSearchUserItem>[],
          totalRoom: 0,
          totalUser: 0,
          err: 'HTTP ${resp.statusCode}',
        );
      }
      final decoded = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        return _searchErr('返回内容不是 JSON 对象');
      }
      final code = _toInt(decoded['code']);
      if (code != 0) {
        return _searchErr(_friendlyMessage(code, _toStr(decoded['message'])));
      }
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return _searchErr('搜索结果为空');

      final rooms = <LiveSearchRoomItem>[];
      final roomNode = data['room'];
      if (roomNode is Map<String, dynamic>) {
        for (final e
            in (roomNode['list'] is List ? roomNode['list'] as List : const [])
                .whereType<Map<String, dynamic>>()) {
          final roomId = _toInt(_pickRaw(e, ['roomid', 'room_id']));
          if (roomId <= 0) continue;
          final watched = e['watched_show'];
          rooms.add(
            LiveSearchRoomItem(
              roomId: roomId,
              title: _toStr(e['title']),
              cover: _fixCover(e['cover']),
              uname: _toStr(_pickRaw(e, ['name', 'uname'])),
              face: _fixCover(_toStr(_pickRaw(e, ['face', 'uface']))),
              onlineText: watched is Map ? _toStr(watched['text_large']) : '',
            ),
          );
        }
      }
      final users = <LiveSearchUserItem>[];
      final userNode = data['user'];
      if (userNode is Map<String, dynamic>) {
        for (final e
            in (userNode['list'] is List ? userNode['list'] as List : const [])
                .whereType<Map<String, dynamic>>()) {
          final name = _toStr(_pickRaw(e, ['name', 'uname']));
          if (name.isEmpty) continue;
          users.add(
            LiveSearchUserItem(
              mid: _toInt(_pickRaw(e, ['mid', 'uid'])),
              uname: name,
              face: _fixCover(_toStr(e['face'])),
              living: _toInt(e['live_status']) == 1,
              areaName: _toStr(e['areaName']),
              fans: _toInt(e['fansNum']),
              roomId: _toInt(e['roomid']),
            ),
          );
        }
      }
      return (
        rooms: rooms,
        users: users,
        totalRoom: roomNode is Map<String, dynamic>
            ? _toInt(roomNode['total_room'])
            : 0,
        totalUser: userNode is Map<String, dynamic>
            ? _toInt(userNode['total_user'])
            : 0,
        err: null,
      );
    } catch (e) {
      debugPrint('[Live] 搜索异常: $e');
      return _searchErr('网络异常：${e.runtimeType}');
    }
  }

                                
  static
      ({
        List<LiveSearchRoomItem> rooms,
        List<LiveSearchUserItem> users,
        int totalRoom,
        int totalUser,
        String? err,
      })
      _searchErr(String msg) => (
        rooms: const <LiveSearchRoomItem>[],
        users: const <LiveSearchUserItem>[],
        totalRoom: 0,
        totalUser: 0,
        err: msg,
      );

               

                                                          
     
                                                              
                                                     
  static Future<({LiveRoomDetail? detail, String? err})> fetchRoomDetail(
    int roomId,
  ) async {
    final (:json, :err) = await _get(
      '/xlive/web-room/v1/index/getH5InfoByRoom',
      {'room_id': roomId.toString()},
    );
    if (err != null) return (detail: null, err: err);

    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      return (detail: null, err: '房间信息为空');
    }
    final room = data['room_info'] is Map<String, dynamic>
        ? data['room_info'] as Map<String, dynamic>
        : const <String, dynamic>{};

                                                              
    String uname = '';
    String face = '';
    for (final key in ['master_info', 'anchor_info']) {
      final node = data[key];
      if (node is! Map<String, dynamic>) continue;
      final inner = node['info'] is Map<String, dynamic>
          ? node['info'] as Map<String, dynamic>
          : node['base_info'] is Map<String, dynamic>
          ? node['base_info'] as Map<String, dynamic>
          : node;
      uname = _toStr(inner['uname'] ?? inner['name']);
      face = _fixCover(_toStr(inner['face']));
      if (uname.isNotEmpty) break;
    }

    final watched = data['watched_show'];
    final fans = data['fans_data'];

    return (
      detail: LiveRoomDetail(
        roomId: _toInt(room['room_id']) > 0
            ? _toInt(room['room_id'])
            : roomId,
        uid: _toInt(room['uid']),
        title: _toStr(room['title']),
        cover: _fixCover(_toStr(room['cover'])),
        keyframe: _fixCover(_toStr(room['keyframe'])),
        uname: uname,
        face: face,
        liveStatus: _toInt(room['live_status']),
        liveStartTime: _toInt(room['live_start_time']),
        watchedText: watched is Map ? _toStr(watched['text_large']) : '',
        fansNum: fans is Map ? _toInt(fans['fans_num']) : -1,
        areaName: _toStr(room['area_name']),
        parentAreaName: _toStr(room['parent_area_name']),
        appBackground: _fixCover(_toStr(room['app_background'])),
      ),
      err: null,
    );
  }

               

                                                           
     
                                                
                                                     
  static Future<({LivePlayInfo? info, String? err})> fetchPlayInfo(
    int roomId, {
    int qn = 0,
  }) async {
    final params = await WbiSign.sign({
      'room_id': roomId.toString(),
      'protocol': '0,1',
      'format': '0,1,2',
      'codec': '0,1,2',
      'qn': qn.toString(),
      'platform': 'web',
      'ptype': '8',
      'dolby': '5',
      'panorama': '1',
      'web_location': '444.8',
    });
    final (:json, :err) = await _get(
      '/xlive/web-room/v2/index/getRoomPlayInfo',
      params,
    );
    if (err != null) return (info: null, err: err);

    final data = json['data'];
    if (data is! Map<String, dynamic>) return (info: null, err: '播放数据为空');

    final liveStatus = _toInt(data['live_status']);
    final playurl = (data['playurl_info'] is Map<String, dynamic>
            ? data['playurl_info'] as Map<String, dynamic>
            : const <String, dynamic>{})['playurl'];
    if (playurl is! Map<String, dynamic>) {
      return (
        info: null,
        err: liveStatus == 1 ? '无法获取播放地址' : '当前直播间未开播',
      );
    }

    final candidates = <LiveStreamOption>[];
    final streams = playurl['stream'] is List
        ? playurl['stream'] as List
        : const [];
    for (final s in streams.whereType<Map<String, dynamic>>()) {
      final protocol = _toStr(s['protocol_name']);
      final formats = s['format'] is List ? s['format'] as List : const [];
      for (final f in formats.whereType<Map<String, dynamic>>()) {
        final format = _toStr(f['format_name']);
        final codecs = f['codec'] is List ? f['codec'] as List : const [];
        for (final c in codecs.whereType<Map<String, dynamic>>()) {
          final codec = _toStr(c['codec_name']);
          final baseUrl = _toStr(c['base_url']);
          if (baseUrl.isEmpty) continue;
          final urlInfos = c['url_info'] is List
              ? c['url_info'] as List
              : const [];
          var hostIndex = 0;
          for (final u in urlInfos.whereType<Map<String, dynamic>>()) {
            final host = _toStr(u['host']);
            if (host.isEmpty) continue;
                                             
            if (hostIndex >= 2) break;
            candidates.add(
              LiveStreamOption(
                protocolName: protocol,
                formatName: format,
                codecName: codec,
                url: _fixCover('$host$baseUrl${_toStr(u['extra'])}'),
                qn: _toInt(c['current_qn']),
                score: _codecScore(codec) * 100 +
                    _formatScore(format) * 10 +
                    _protocolScore(protocol) +
                    hostIndex,
              ),
            );
            hostIndex++;
          }
        }
      }
    }
    if (candidates.isEmpty) {
      return (info: null, err: liveStatus == 1 ? '没有可用的播放地址' : '当前直播间未开播');
    }
    candidates.sort((a, b) => a.score.compareTo(b.score));

    final codec0 = candidates.first;
    final accept = (playurl['accept_qn'] is List
            ? playurl['accept_qn'] as List
            : const [])
        .map(_toInt)
        .where((v) => v > 0)
        .toList();

    return (
      info: LivePlayInfo(
        roomId: _toInt(data['room_id']) > 0 ? _toInt(data['room_id']) : roomId,
        uid: _toInt(data['uid']),
        liveStatus: liveStatus,
        liveTime: _toInt(data['live_time']),
        isPortrait: data['is_portrait'] == true,
        currentQn: codec0.qn > 0 ? codec0.qn : _toInt(playurl['qn']),
        acceptQn: accept,
        streams: candidates,
      ),
      err: null,
    );
  }

                                               
  static int _codecScore(String codec) => switch (codec) {
    'avc' => 0,
    'hevc' => 1,
    _ => 2,
  };

                                                      
  static int _formatScore(String format) => switch (format) {
    'fmp4' => 0,
    'ts' => 1,
    'flv' => 2,
    _ => 3,
  };

  static int _protocolScore(String protocol) => protocol == 'http_hls' ? 0 : 1;

                                            
  static String qualityLabel(int qn) => switch (qn) {
    30000 => '杜比',
    25000 => '4K 原画',
    20000 => '4K',
    15000 => '2K',
    10000 => '原画',
    400 => '蓝光',
    250 => '超清',
    150 => '高清',
    80 => '流畅',
    _ => qn <= 0 ? '默认' : qn.toString(),
  };

                                                         

                                          
  static String _csrf() {
    final raw = BilibiliAccountService.instance.rawCookie;
    return RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(raw)?.group(1) ??
        '';
  }

                                        
  static Future<Map<String, String>> _postHeaders(int roomId) async {
    final cookie = BilibiliAccountService.instance
        .cookieHeaderFor(BiliCookieScope.interactions)?['Cookie'];
    return {
      ..._webHeaders,
      'Origin': 'https://live.bilibili.com',
      'Referer': 'https://live.bilibili.com/$roomId',
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

                                        
  static Future<({Map<String, dynamic> json, String? err})> _post(
    String url,
    Map<String, String> fields, {
    required int roomId,
  }) async {
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(url),
            headers: {
              ...(await _postHeaders(roomId)),
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: fields,
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (json: const <String, dynamic>{}, err: 'HTTP ${resp.statusCode}');
      }
      final decoded = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        return (json: const <String, dynamic>{}, err: '返回内容不是 JSON 对象');
      }
      final code = _toInt(decoded['code']);
      if (code != 0) {
        final raw = _toStr(decoded['message'] ?? decoded['msg']);
        return (json: decoded, err: _friendlyMessage(code, raw));
      }
      return (json: decoded, err: null);
    } catch (e) {
      return (json: const <String, dynamic>{}, err: '网络异常：${e.runtimeType}');
    }
  }

                                            
  static Future<({bool ok, String message})> sendDanmu(
    int roomId,
    String msg,
  ) async {
    final csrf = _csrf();
    if (csrf.isEmpty) {
      return (ok: false, message: '还没有登录，登录后才能发弹幕');
    }
    final (:json, :err) = await _post(
      '$_liveApi/msg/send',
      {
        'bubble': '0',
        'msg': msg,
        'color': '16777215',
        'mode': '1',
        'fontsize': '25',
        'rnd': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
        'roomid': roomId.toString(),
        'room_type': '0',
        'jumpfrom': '0',
        'reply_mid': '0',
        'reply_attr': '0',
        'replay_dmid': '',
        'statistics': '{"appId":100,"platform":5}',
        'reply_type': '0',
        'reply_uname': '',
        'csrf': csrf,
        'csrf_token': csrf,
      },
      roomId: roomId,
    );
    return err == null
        ? (ok: true, message: '')
        : (ok: false, message: err);
  }

                                              
  static Future<({bool ok, String message})> likeReport({
    required int clickTime,
    required int roomId,
    int? anchorId,
  }) async {
    final csrf = _csrf();
    if (csrf.isEmpty) {
      return (ok: false, message: '还没有登录，登录后才能点赞');
    }
    final mid = BilibiliAccountService.instance.mid;
    final params = await WbiSign.sign({
      'click_time': clickTime.toString(),
      'room_id': roomId.toString(),
      'uid': mid.toString(),
      if (anchorId != null && anchorId > 0) 'anchor_id': anchorId.toString(),
      'web_location': '444.8',
      'csrf': csrf,
    });
    final (:json, :err) = await _post(
      '$_liveApi/xlive/app-ucenter/v1/like_info_v3/like/likeReportV3',
      params,
      roomId: roomId,
    );
    return err == null
        ? (ok: true, message: '')
        : (ok: false, message: err);
  }

                                              
  static Future<void> reportRoomEntry(int roomId) async {
    final csrf = _csrf();
    if (csrf.isEmpty) return;
    try {
      await _post(
        '$_liveApi/xlive/web-room/v1/index/roomEntryAction',
        {
          'room_id': roomId.toString(),
          'platform': 'pc',
          'csrf': csrf,
          'csrf_token': csrf,
          'visit_id': '',
        },
        roomId: roomId,
      );
    } catch (_) {}
  }

                                                         
  static Future<List<LiveSuperChatMsg>> fetchSuperChat(int roomId) async {
    try {
      final uri = Uri.parse('$_liveApi/av/v1/SuperChat/getMessageList')
          .replace(queryParameters: {'room_id': roomId.toString()});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildHeaders())
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return const [];
      final decoded = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (decoded is! Map<String, dynamic> || _toInt(decoded['code']) != 0) {
        return const [];
      }
      final data = decoded['data'];
      final list =
          data is Map<String, dynamic> ? data['list'] : null;
      if (list is! List) return const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(LiveSuperChatMsg.fromData)
          .where((v) => v != null)
          .cast<LiveSuperChatMsg>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

                                             
     
                                     
  static Future<({int fans, bool following})?> fetchAnchorCard(int uid) async {
    if (uid <= 0) return null;
    try {
      final uri = Uri.parse('https://api.bilibili.com/x/web-interface/card')
          .replace(queryParameters: {'mid': uid.toString(), 'photo': 'false'});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildHeaders())
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      final decoded = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (decoded is! Map<String, dynamic> || _toInt(decoded['code']) != 0) {
        return null;
      }
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return null;
      final card = data['card'] is Map<String, dynamic>
          ? data['card'] as Map<String, dynamic>
          : const <String, dynamic>{};
      final fans = _toInt(_pickRaw(data, ['follower'])) > 0
          ? _toInt(_pickRaw(data, ['follower']))
          : _toInt(card['fans']);
      return (fans: fans, following: data['following'] == true);
    } catch (_) {
      return null;
    }
  }

                                    
  static Future<List<LiveEmote>> fetchEmoticons(int roomId) async {
    final (:json, :err) = await _get(
      '/xlive/web-ucenter/v2/emoticon/GetEmoticons',
      {'platform': 'pc', 'room_id': roomId.toString()},
    );
    if (err != null) return const [];
    final data = json['data'];
    final list = data is Map<String, dynamic> ? data['data'] : null;
    if (list is! List) return const [];
    final emotes = <LiveEmote>[];
    for (final e in list.whereType<Map<String, dynamic>>()) {
      final url = _fixCover(_toStr(e['url']));
      if (url.isEmpty) continue;
                                                
      final unique = _toStr(e['emoticon_unique']);
      final m = RegExp(r'\[([^\[\]]+)\]').firstMatch(unique);
      final name = m?.group(1) ?? '';
      if (name.isEmpty) continue;
      emotes.add(LiveEmote(
        name: '[$name]',
        url: url,
        width: _toInt(e['width']),
        height: _toInt(e['height']),
      ));
    }
    return emotes;
  }

                                  

                                 
  static Future<LiveResult<LiveRankItem>> fetchContributionRank({
    required int ruid,
    required int roomId,
    LiveRankType type = LiveRankType.online,
    int page = 1,
  }) async {
    if (ruid <= 0 || roomId <= 0) return _err('参数不完整');
    try {
      final params = await WbiSign.sign({
        'ruid': ruid.toString(),
        'room_id': roomId.toString(),
        'page': page.toString(),
        'page_size': '100',
        'type': type.name,
        'switch': type.sw1tch,
        'platform': 'web',
        'web_location': '444.8',
      });
      final uri = Uri.parse(
        '$_liveApi/xlive/general-interface/v1/rank/queryContributionRank',
      ).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return _err('HTTP ${resp.statusCode}');
      }
      final decoded = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (decoded is! Map<String, dynamic>) return _err('返回内容异常');
      final code = _toInt(decoded['code']);
      if (code != 0) {
        return _err(_friendlyMessage(
          code,
          _toStr(decoded['message'] ?? decoded['msg']),
        ));
      }
      final data = decoded['data'];
      final raw = data is Map ? data['item'] : null;
      if (raw is! List) return _err('贡献榜为空');
      final items = raw
          .whereType<Map<String, dynamic>>()
          .map(LiveRankItem.fromJson)
          .where((e) => e.uid > 0)
          .toList();
      return LiveOk(items, hasMore: items.length >= 100);
    } catch (e) {
      return _err('网络异常：${e.runtimeType}');
    }
  }

                

                                                   
  static Future<LiveResult<LiveGuardItem>> fetchGuardList({
    required int ruid,
    int page = 1,
  }) async {
    if (ruid <= 0) return _err('参数不完整');
    final (:json, :err) = await _get(
      '/xlive/app-ucenter/v1/guard/MainGuardCardAll',
      {'page': page.toString(), 'page_size': '20', 'ruid': ruid.toString()},
    );
    if (err != null) return _err(err);
    final data = json['data'];
    final raw = data is Map ? data['guard_top_list'] : null;
    if (raw is! List) return _err('大航海列表为空');
    final items = raw
        .whereType<Map<String, dynamic>>()
        .map(LiveGuardItem.fromJson)
        .where((e) => e.uid > 0)
        .toList();
    final hasMore = _toInt(data['has_more']) == 1;
    return LiveOk(items, hasMore: hasMore);
  }

                

                                            
  static Future<LiveMedalWallData?> fetchMedalWall({required int mid}) async {
    if (mid <= 0) return null;
    final (:json, :err) = await _get(
      '/xlive/web-ucenter/user/MedalWall',
      {'target_id': mid.toString()},
    );
    if (err != null) return null;
    final data = json['data'];
    if (data is! Map<String, dynamic>) return null;
    final raw = data['list'];
    final items = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(LiveMedalItem.fromJson)
            .where((e) => e.name.isNotEmpty)
            .toList()
        : <LiveMedalItem>[];
    return LiveMedalWallData(
      items: items,
      count: _toInt(data['count']),
      name: _toStr(data['name']),
      icon: _fixCover(_toStr(data['icon'])),
    );
  }

                                           

                                     
  static Future<LiveShieldInfo?> fetchShieldInfo(int roomId) async {
    if (roomId <= 0) return null;
    try {
      final params = await WbiSign.sign({
        'room_id': roomId.toString(),
        'from': '0',
        'not_mock_enter_effect': '1',
        'web_location': '444.8',
      });
      final uri = Uri.parse(
        '$_liveApi/xlive/web-room/v1/index/getInfoByUser',
      ).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildHeaders())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final decoded = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (decoded is! Map<String, dynamic> || _toInt(decoded['code']) != 0) {
        return null;
      }
      final data = decoded['data'];
      final shield = data is Map ? data['shield_info'] : null;
      if (shield is! Map) return const LiveShieldInfo(keywords: [], users: {});
      final keywords = (shield['keyword_list'] as List?)
              ?.map((e) => _toStr(e))
              .where((e) => e.isNotEmpty)
              .toList() ??
          <String>[];
      final users = <int, String>{};
      final rawUsers = shield['shield_user_list'];
      if (rawUsers is List) {
        for (final u in rawUsers.whereType<Map<String, dynamic>>()) {
          final uid = _toInt(u['uid']);
          if (uid > 0) users[uid] = _toStr(u['uname']);
        }
      }
      return LiveShieldInfo(keywords: keywords, users: users);
    } catch (e) {
      debugPrint('[Live] 拉取弹幕屏蔽规则失败: $e');
      return null;
    }
  }

              
  static Future<({bool ok, String message})> addShieldKeyword({
    required int roomId,
    required String keyword,
  }) async {
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '还没有登录');
    final (:json, :err) = await _post(
      '$_liveApi/xlive/web-ucenter/v1/banned/AddShieldKeyword',
      {'keyword': keyword, 'csrf': csrf, 'csrf_token': csrf},
      roomId: roomId,
    );
    return err == null ? (ok: true, message: '') : (ok: false, message: err);
  }

              
  static Future<({bool ok, String message})> delShieldKeyword({
    required int roomId,
    required String keyword,
  }) async {
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '还没有登录');
    final (:json, :err) = await _post(
      '$_liveApi/xlive/web-ucenter/v1/banned/DelShieldKeyword',
      {'keyword': keyword, 'csrf': csrf, 'csrf_token': csrf},
      roomId: roomId,
    );
    return err == null ? (ok: true, message: '') : (ok: false, message: err);
  }

                                              
  static Future<({bool ok, String message})> shieldUser({
    required int uid,
    required int roomId,
    required bool add,
  }) async {
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '还没有登录');
    final (:json, :err) = await _post(
      '$_liveApi/liveact/shield_user',
      {
        'uid': uid.toString(),
        'roomid': roomId.toString(),
        'type': add ? '1' : '0',
        'csrf': csrf,
        'csrf_token': csrf,
      },
      roomId: roomId,
    );
    return err == null ? (ok: true, message: '') : (ok: false, message: err);
  }

             

                                     
  static dynamic _pickRaw(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null) return v;
    }
    return null;
  }

                                             
  static String _fixCover(String url) {
    final t = url.trim();
    if (t.isEmpty) return '';
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    if (t.startsWith('//')) return 'https:$t';
    return 'https://$t';
  }
}
