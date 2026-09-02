// lib/services/bilibili_live_service.dart
//
// B 站直播服务（接口选型对照 PiliPlus 的 LiveHttp / Api 常量表）。
//
// 全部走 Web 端接口，不需要 APP 签名（appkey/appsec），只依赖
// 浏览器风格 UA + Referer，登录态通过「携带 Cookie 请求」开关附加：
//   - 推荐直播：api.live.bilibili.com/room/v1/room/get_user_recommend
//       （PiliPlus 的 Api.liveList 注释即 page/page_size/platform=web；
//        分区列表接口 xlive/web-interface/v1/second/getUserRecommend
//        风控码 -352 频发，故推荐列表改用这条老但稳定的接口）
//   - 分区树：api.live.bilibili.com/room/v1/Area/getList
//   - 分区直播：api.live.bilibili.com/xlive/web-interface/v1/second/getList
//   - 关注直播：api.live.bilibili.com/xlive/web-ucenter/user/following（需登录）
//   - 房间信息：api.live.bilibili.com/xlive/web-room/v1/index/getH5InfoByRoom
//   - 播放地址：api.live.bilibili.com/xlive/web-room/v2/index/getRoomPlayInfo
//       （WBI 签名，参数取值对照 PiliPlus LiveHttp.liveRoomInfo：
//        protocol=0,1 / format=0,1,2 / codec=0,1,2 / platform=web / ptype=8）
//
// 请求方式与分区 / 推荐服务一致：复用 NetworkSettingsService 客户端与请求头，
// Cookie 遵循「携带 Cookie 请求」开关（直播读接口复用 video 作用域，
// 避免新增作用域后老用户的本地开关列表缺少该项导致 Cookie 不生效）。
import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import 'bilibili_account_service.dart';
import 'bilibili_user_space_service.dart' show WbiSign;
import 'network_settings_service.dart';

// ════════════════════════════════════════
//  安全解析工具
// ════════════════════════════════════════

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

// ════════════════════════════════════════
//  模型
// ════════════════════════════════════════

/// 直播间条目（统一推荐 / 分区 / 关注三个数据源）。
class LiveRoomItem {
  /// 房间号（长号，short_id 为 0 时以它为准）。
  final int roomId;

  final int uid;
  final String title;

  /// 封面（已做 keyframe 等协议补全）。
  final String cover;

  final String uname;
  final String face;

  /// 人气值（在线人数）。
  final int online;

  /// 人气展示文本（如「2551.7万人气」），为空时由 online 兜底格式化。
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

  /// 直播间网页地址（点击卡片时用内置浏览器打开）。
  String get url => 'https://live.bilibili.com/$roomId';
}

/// 二级分区。
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

  /// id 为 0 表示该父分区下的「全部」。
  bool get isAll => id == 0;
}

/// 一级分区（含二级分区列表）。
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

/// 直播间详情（getH5InfoByRoom，直播间查看页头部信息）。
class LiveRoomDetail {
  final int roomId;
  final int uid;

  /// 房间标题。
  final String title;

  /// 房间封面。
  final String cover;

  /// 房间 app 背景图（直播间页整页背景，PiliPlus 同款；可能为空）。
  final String appBackground;

  /// 关键帧截图（未开播时的占位图）。
  final String keyframe;
  final String uname;
  final String face;

  /// 0 未开播，1 开播中，2 轮播中。
  final int liveStatus;

  /// 开播时间戳（秒），0 表示未知。
  final int liveStartTime;

  /// 观看人数展示文本（如「2551.7万人看过」）。
  final String watchedText;

  /// 粉丝数（接口未给时为 -1，UI 不展示）。
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

/// 一条可播放的直播流地址（协议 / 格式 / 编码 / CDN 线路的组合）。
class LiveStreamOption {
  /// http_hls（m3u8）或 http_stream（flv）。
  final String protocolName;

  /// fmp4 / ts / flv。
  final String formatName;

  /// avc / hevc。
  final String codecName;

  /// 已拼接好的完整地址（host + base_url + extra）。
  final String url;

  final int qn;

  /// 排序权重：越小越优先（avc 优先于 hevc，fmp4 优先于 flv）。
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

/// 播放地址（getRoomPlayInfo 播放页数据）。
class LivePlayInfo {
  /// 接口返回的真实房间号（短号会在此换成长号）。
  final int roomId;
  final int uid;
  final int liveStatus;

  /// 开播时间戳（秒），0 表示未知。
  final int liveTime;

  /// 竖屏直播间（连麦 / 秀场类，播放器按 9:16 摆放）。
  final bool isPortrait;

  /// 服务端实际给出的清晰度。
  final int currentQn;

  /// 可选清晰度（qn 码值列表）。
  final List<int> acceptQn;

  /// 按优先级排好序的播放地址候选（播放失败时依次回退）。
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

/// 直播间表情包（xlive/web-ucenter/v2/emoticon/GetEmoticons）。
class LiveEmote {
  /// 发送用的文本名（形如「[dog]」）。
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

/// SuperChat 醒目留言（av/v1/SuperChat/getMessageList + WS 推送共用字段）。
class LiveSuperChatMsg {
  final int id;
  final String uname;
  final int uid;
  final String face;
  final num price;
  final String message;
  final Color topColor;
  final Color bottomColor;

  /// 到期时间戳（秒）。
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

  /// 从接口 / WS 的 data 节点解析（字段结构一致，抽出来共用）。
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

// ════════════════════════════════════════
//  结果封装（与推荐服务同构）
// ════════════════════════════════════════

sealed class LiveResult<T> {}

/// 正常返回（列表可能为空）。
class LiveOk<T> extends LiveResult<T> {
  final List<T> items;

  /// 是否还有下一页（由上层的返回数量推断）。
  final bool hasMore;

  LiveOk(this.items, {this.hasMore = true});
}

/// 请求失败（网络 / 非 0 业务码 / 解析失败）。
class LiveError<T> extends LiveResult<T> {
  final String detail;
  LiveError(this.detail);
}

// ════════════════════════════════════════
//  服务
// ════════════════════════════════════════

abstract final class BilibiliLiveService {
  static const String _liveApi = 'https://api.live.bilibili.com';

  /// 分区排序方式（sort_type 参数取值）。
  static const String sortDefault = '';
  static const String sortOnline = 'online';
  static const String sortLiveTime = 'live_time';

  static const Map<String, String> _webHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://live.bilibili.com',
  };

  static Future<Map<String, String>> _buildHeaders() async {
    final cookie = BilibiliAccountService.instance
        .cookieHeaderFor(BiliCookieScope.video)?['Cookie'];
    return {
      ..._webHeaders,
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  /// 业务码转人话（-352 是直播区最常见的风控码，用户遇到时提示要友好）。
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

  /// 统一 GET 请求：返回解码后的 JSON（已校验 HTTP 200 与 code == 0）。
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
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
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

  // ── 推荐直播 ──

  /// 推荐直播间（room/v1/room/get_user_recommend，[page] 从 1 起）。
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

  /// 解析推荐接口条目（data 直接是数组）。
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

  // ── 分区树 ──

  /// 全部分区（room/v1/Area/getList，parent_id=0 返回一级分区及其二级分区）。
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
      // 服务端已自带「全部xxx」子项（id=0），缺失时补一个，避免子分区栏空白
      if (children.isEmpty || !children.any((c) => c.isAll)) {
        children.insert(0, LiveAreaItem(id: 0, parentId: id, name: '全部'));
      }
      groups.add(LiveAreaGroup(id: id, name: name, children: children));
    }
    if (groups.isEmpty) return _err('分区数据为空');
    return LiveOk(groups, hasMore: false);
  }

  // ── 分区直播 ──

  /// 分区直播间（xlive/web-interface/v1/second/getList，[page] 从 1 起）。
  ///
  /// [areaId] 传 0 表示该父分区下的全部；[sortType] 取
  /// [sortDefault] / [sortOnline] / [sortLiveTime]。
  static Future<LiveResult<LiveRoomItem>> fetchAreaRooms({
    required int parentAreaId,
    int areaId = 0,
    String sortType = sortDefault,
    int page = 1,
    int pageSize = 30,
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

    // 服务端会回传 hasMore / count，两者都没有时按「本页是否满」推断
    final hasMore = data['hasMore'] is bool
        ? data['hasMore'] as bool
        : items.length >= pageSize;
    if (items.isEmpty && page == 1) return _err('这个分区现在没人开播');
    return LiveOk(items, hasMore: hasMore);
  }

  /// 解析分区接口条目（data.list 数组）。
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
      parentAreaId: _toInt(_pickRaw(json, ['parent_area_id'])),
      areaName: _pick(json, ['area_name', 'areaName', 'area_v2_name']),
      parentAreaName: _pick(json, ['parent_area_name', 'parentName']),
    );
  }

  // ── 关注直播 ──

  /// 关注的主播（xlive/web-ucenter/user/following，需登录 Cookie）。
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

    // 关注页返回的 count 是总条数，用来判断翻页终点更准
    final total = _toInt(data['count']);
    final hasMore = total > 0 ? items.isNotEmpty : items.length >= pageSize;
    return LiveOk(items, hasMore: hasMore);
  }

  /// 解析关注接口条目（data.list 数组，字段与推荐接口接近）。
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

  // ── 房间详情 ──

  /// 房间信息（xlive/web-room/v1/index/getH5InfoByRoom，免登录可读）。
  ///
  /// 主播昵称 / 头像在 master_info.info 或 anchor_info.base_info 两个位置
  /// 出现过，逐个兜底；返回 null 表示接口异常（[fetchRoomDetail.err]）。
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

    // 主播昵称 / 头像：master_info.info → anchor_info.base_info 依次兜底
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

  // ── 播放地址 ──

  /// 播放地址（xlive/web-room/v2/index/getRoomPlayInfo，WBI 签名）。
  ///
  /// [qn] 为期望清晰度（0 表示交给服务端定默认档），返回里以 current_qn
  /// 为准。候选地址按 avc > hevc、fmp4 > ts > flv、多 CDN 依次排序。
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
            // 每个 CDN 线路最多留两个（主 + 备），避免候选列表过长
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

  /// 编码偏好：avc（H.264）兼容性最好，hevc 可能 10bit 卡顿放最后。
  static int _codecScore(String codec) => switch (codec) {
    'avc' => 0,
    'hevc' => 1,
    _ => 2,
  };

  /// 封装偏好：fmp4 > ts > flv（media_kit / mpv 均可解，优先标准流）。
  static int _formatScore(String format) => switch (format) {
    'fmp4' => 0,
    'ts' => 1,
    'flv' => 2,
    _ => 3,
  };

  static int _protocolScore(String protocol) => protocol == 'http_hls' ? 0 : 1;

  /// 清晰度码值转展示名（对照 PiliPlus LiveQuality 码表）。
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

  // ── 直播间互动（发送弹幕 / 点赞 / 进房上报 / SuperChat / 关注状态 / 表情）──

  /// 从 Cookie 里取 bili_jct（写操作必需），未登录返回空串。
  static String _csrf() {
    final raw = BilibiliAccountService.instance.rawCookie;
    return RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(raw)?.group(1) ??
        '';
  }

  /// 互动写操作请求头（登录 Cookie + 直播站 Referer）。
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

  /// 表单 POST，返回解码后的 JSON（校验 code == 0）。
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
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
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

  /// 发送直播间弹幕（msg/send，需登录；未登录 / 风控都会给可读错误）。
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

  /// 直播间点赞（likeReportV3，WBI 签名；连点后一次性上报累计次数）。
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

  /// 进房上报（roomEntryAction，历史记录依赖它；尽力而为，失败静默）。
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

  /// SuperChat 历史列表（av/v1/SuperChat/getMessageList，免登录）。
  static Future<List<LiveSuperChatMsg>> fetchSuperChat(int roomId) async {
    try {
      final uri = Uri.parse('$_liveApi/av/v1/SuperChat/getMessageList')
          .replace(queryParameters: {'room_id': roomId.toString()});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: await _buildHeaders())
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return const [];
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
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

  /// 主播关注状态与粉丝数（x/web-interface/card，免登录可读）。
  ///
  /// following 仅在已登录时可靠；接口失败返回 null。
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
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
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

  /// 直播间表情包（需登录；失败返回空列表，调用方隐藏入口即可）。
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
      // emoticon_unique 形如 upower_[问号]，取方括号里的名字
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

  // ── 工具 ──

  /// 与 _pick 同逻辑，但用于非字符串字段（id / 计数）。
  static dynamic _pickRaw(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null) return v;
    }
    return null;
  }

  /// 补全协议：B 站直播封面偶发不带 scheme，直接给 Image 会抛异常。
  static String _fixCover(String url) {
    final t = url.trim();
    if (t.isEmpty) return '';
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    if (t.startsWith('//')) return 'https:$t';
    return 'https://$t';
  }
}
