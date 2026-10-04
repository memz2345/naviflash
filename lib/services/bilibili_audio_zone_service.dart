                                                
  
                  
  
                                             
                                                                   
                                                                       
                                                                          
                                                     
                          
                                       
                                                                                 
                                                                                   
                                                 
                                                                             
                                                
                                                                                 
                                                            
                                                               
                                                           
                                                         
                                              
                                                                
                                                                      
                                                                
                                                                     
                                                            
                                                    
                                                               
                                            
                                                      
                                                   
                                       
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'bilibili_api_helpers.dart';
import 'bilibili_account_service.dart';
import 'network_settings_service.dart';

                                           
      
                                           

                                                      
class AudioZoneSong {
                                         
  final int id;

  final String title;
  final String author;
  final String cover;

                   
  final int duration;

                  
  final int play;

  final String intro;

                                     
  final String uploader;

                                                     
  final int uid;

                                                      
  final int avid;
  final String bvid;

  const AudioZoneSong({
    required this.id,
    required this.title,
    required this.author,
    required this.cover,
    required this.duration,
    required this.play,
    required this.intro,
    required this.uploader,
    this.uid = 0,
    required this.avid,
    required this.bvid,
  });

                                                  
  factory AudioZoneSong.fromJson(Map<String, dynamic> json) {
    final stat = biliAsMap(json['statistic']);
    return AudioZoneSong(
      id: biliToInt(json['song_id'] ?? json['id']),
      title: biliAsStr(json['title']),
      author: biliAsStr(json['author']),
      cover: biliNormalizeUrl(
        biliAsStr(json['cover_url'] ?? json['cover'] ?? json['mv_cover']),
      ),
      duration: biliToInt(json['duration']),
      play: biliToInt(
        json['play_num'] ?? (stat != null ? stat['play'] : null),
      ),
      intro: biliAsStr(json['intro']),
      uploader: biliAsStr(json['uploader_name'] ?? json['uname']),
      uid: biliToInt(json['uid'] ?? json['mid']),
      avid: biliToInt(json['avid'] ?? json['aid'] ?? json['creation_aid']),
      bvid: biliAsStr(json['bvid'] ?? json['creation_bvid'] ?? json['mv_bvid']),
    );
  }

  String get webUrl => 'https://www.bilibili.com/audio/au$id';
}

                      
class AudioZoneMenu {
  final int menuId;
  final String title;
  final String cover;
  final String intro;

                                                            
  final int songCount;

  final int play;
  final int collect;

                                               
  final List<AudioZoneSong> previewSongs;

  const AudioZoneMenu({
    required this.menuId,
    required this.title,
    required this.cover,
    required this.intro,
    required this.songCount,
    required this.play,
    required this.collect,
    required this.previewSongs,
  });

  factory AudioZoneMenu.fromJson(Map<String, dynamic> json) {
    final stat = biliAsMap(json['statistic']);
    final audios = biliAsList<Map<String, dynamic>>(json['audios']);
    return AudioZoneMenu(
      menuId: biliToInt(json['menuId'] ?? json['menu_id']),
      title: biliAsStr(json['title']),
      cover: biliNormalizeUrl(
        biliAsStr(json['cover'] ?? json['coverUrl']),
      ),
      intro: biliAsStr(json['intro']),
      songCount: biliToInt(json['snum'] ?? json['songNum'] ?? json['song']),
                                                                    
                                      
      play: biliToInt(
        stat?['play'] ?? json['playNum'],
      ),
      collect: biliToInt(
        stat?['collect'] ?? json['collectNum'],
      ),
      previewSongs: audios.map(AudioZoneSong.fromJson).toList(),
    );
  }
}

                                                  
class AudioZoneMenuDetail {
  final AudioZoneMenu menu;
  final List<AudioZoneSong> songs;

  const AudioZoneMenuDetail({required this.menu, required this.songs});
}

                                               
class AudioPlayUrl {
  final int sid;

                                                         
  final int type;

                       
  final int timeout;

                       
  final int size;

                      
  final List<String> urls;

  final String title;
  final String cover;

  const AudioPlayUrl({
    required this.sid,
    required this.type,
    required this.timeout,
    required this.size,
    required this.urls,
    required this.title,
    required this.cover,
  });

                            
  String? get firstUrl => urls.where((u) => u.isNotEmpty).firstOrNull;
}

                                           
      
                                           

abstract final class BilibiliAudioZoneService {
  static const String _apiBase = 'https://api.bilibili.com';

  static const Map<String, String> _webHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

                                                  
                          
  static const Map<String, String> mediaHeaders = _webHeaders;

  static String? lastErrorDetail;

  static Map<String, String> _headers() {
    final cookie = biliLoginCookie(BiliCookieScope.video);
    return {
      ..._webHeaders,
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  static Map<String, String> _writeHeaders() {
    final cookie = biliLoginCookie(BiliCookieScope.interactions);
    return {
      ..._webHeaders,
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

                                         
  static Future<dynamic> _getData(
    String path,
    Map<String, String> query,
  ) async {
    final uri = Uri.parse('$_apiBase$path').replace(queryParameters: query);
    final client = await NetworkSettingsService.instance.getApiClient();
    final resp = await client
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
    if (json is! Map) {
      throw Exception('返回内容不是 JSON 对象');
    }
    final code = biliToInt(json['code']);
    if (code != 0 && code != 200) {
      throw Exception('${json['message'] ?? json['msg'] ?? code}');
    }
    lastErrorDetail = null;
    return json['data'];
  }

                        

                                         
  static Future<({List<AudioZoneMenu> menus, String? err})> fetchRankMenus({
    int pn = 1,
    int ps = 12,
  }) => _fetchMenuList('/audio/music-service-c/web/menu/rank', pn: pn, ps: ps);

           
  static Future<({List<AudioZoneMenu> menus, String? err})> fetchHitMenus({
    int pn = 1,
    int ps = 12,
  }) => _fetchMenuList('/audio/music-service-c/web/menu/hit', pn: pn, ps: ps);

  static Future<({List<AudioZoneMenu> menus, String? err})> _fetchMenuList(
    String path, {
    required int pn,
    required int ps,
  }) async {
    try {
      final data = await _getData(path, {
        'pn': pn.toString(),
        'ps': ps.toString(),
      });
      return (menus: parseMenuList(biliAsMap(data)), err: null);
    } catch (e) {
      debugPrint('[AudioZone] 歌单列表获取失败: $e');
      return (menus: const <AudioZoneMenu>[], err: '网络异常：${e.runtimeType}');
    }
  }

                                   
  static Future<({AudioZoneMenuDetail? detail, String? err})> fetchMenuDetail(
    int menuId,
  ) async {
    try {
      final data = await _getData('/audio/music-service-c/h5/menus/$menuId', {});
      final detail = parseMenuDetail(biliAsMap(data));
      if (detail == null) {
        return (detail: null, err: '歌单不存在或已被下架');
      }
      return (detail: detail, err: null);
    } catch (e) {
      debugPrint('[AudioZone] 歌单详情获取失败: $e');
      return (detail: null, err: '网络异常：${e.runtimeType}');
    }
  }

                                            
  static Future<({AudioZoneSong? song, String? err})> fetchSongInfo(int sid) async {
    try {
      final data = await _getData('/audio/music-service-c/web/song/info', {
        'sid': sid.toString(),
      });
      final map = biliAsMap(data);
      if (map == null) return (song: null, err: '音频不存在或已被下架');
      return (song: AudioZoneSong.fromJson(map), err: null);
    } catch (e) {
      debugPrint('[AudioZone] 歌曲详情获取失败: $e');
      return (song: null, err: '网络异常：${e.runtimeType}');
    }
  }

               

                                                   
                                              
     
                                                        
  static Future<({AudioPlayUrl? play, String? err})> resolvePlayUrl({
    required int sid,
    int quality = 2,
  }) async {
    final mid = biliCurrentMid;
    try {
      final data = await _getData('/audio/music-service-c/url', {
        'songid': sid.toString(),
        'quality': quality.toString(),
        'privilege': '2',
        'mid': mid.toString(),
        'platform': 'pc',
      });
      final play = parsePlayUrl(biliAsMap(data));
      if (play != null && play.firstUrl != null) {
        return (play: play, err: null);
      }
      return (play: null, err: '未取到可播放的音频地址');
    } catch (e) {
      debugPrint('[AudioZone] 播放地址解析失败（songid 形态）: $e');
    }
                              
    try {
      final data = await _getData('/audio/music-service-c/web/url', {
        'sid': sid.toString(),
        'quality': '2',
        'privilege': '2',
      });
      final play = parsePlayUrl(biliAsMap(data));
      if (play != null && play.firstUrl != null) {
        return (play: play, err: null);
      }
      return (play: null, err: '未取到可播放的音频地址');
    } catch (e) {
      debugPrint('[AudioZone] 播放地址解析失败（web 兜底）: $e');
      return (play: null, err: '播放地址解析失败，请稍后重试');
    }
  }

                                      

                        
                                                  
  static Future<({bool ok, String message})> collectAudio({
    required int sid,
    required List<int> addIds,
    List<int> delIds = const [],
  }) async {
    final cookie = biliLoginCookie(BiliCookieScope.interactions);
    if (cookie == null || cookie.isEmpty) {
      return (ok: false, message: '还没有登录，登录后才能收藏');
    }
    final csrf = biliExtractCsrf(cookie);
    if (csrf.isEmpty) return (ok: false, message: '缺少 bili_jct，请重新登录');
    if (addIds.isEmpty && delIds.isEmpty) {
      return (ok: false, message: '未选择收藏夹');
    }
    final body = buildCollectBody(
      sid: sid,
      addIds: addIds,
      delIds: delIds,
      csrf: csrf,
    );
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse('$_apiBase/x/v3/fav/resource/batch-deal'),
            headers: {
              ..._writeHeaders(),
              'Origin': 'https://www.bilibili.com',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map) return (ok: false, message: '返回内容不是 JSON 对象');
      final code = biliToInt(json['code']);
      if (code != 0) {
        final msg = biliAsStr(json['message'] ?? json['msg']);
        return (ok: false, message: msg.isEmpty ? '接口返回 $code' : msg);
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[AudioZone] 收藏音频失败: $e');
      return (ok: false, message: '网络异常：${e.runtimeType}');
    }
  }

                                    
                                                    
  static Map<String, String> buildCollectBody({
    required int sid,
    required List<int> addIds,
    List<int> delIds = const [],
    required String csrf,
  }) {
    return {
      'resources': '$sid:12',
      if (addIds.isNotEmpty) 'add_media_ids': addIds.join(','),
      if (delIds.isNotEmpty) 'del_media_ids': delIds.join(','),
      'csrf': csrf,
      'csrf_token': csrf,
    };
  }

                                          

                                       
                                     
  static Future<({List<AudioZoneSong> songs, String? err})> searchCatalog(
    String keyword,
  ) async {
    final results = await Future.wait([
      fetchRankMenus(pn: 1, ps: 20),
      fetchHitMenus(pn: 1, ps: 20),
      fetchHitMenus(pn: 2, ps: 20),
    ]);
    final pool = <AudioZoneSong>[];
    final seen = <int>{};
    for (final r in results) {
      for (final menu in r.menus) {
        for (final song in menu.previewSongs) {
          if (song.id <= 0 || !seen.add(song.id)) continue;
          pool.add(song);
        }
      }
    }
    if (pool.isEmpty) {
      final err = results
          .map((r) => r.err)
          .whereType<String>()
          .firstOrNull;
      return (songs: const <AudioZoneSong>[], err: err);
    }
    return (songs: filterSongs(pool, keyword), err: null);
  }

                                   
  static List<AudioZoneSong> filterSongs(
    List<AudioZoneSong> songs,
    String keyword,
  ) {
    final kw = keyword.trim().toLowerCase();
    if (kw.isEmpty) return List.unmodifiable(songs);
    return List.unmodifiable(
      songs.where(
        (s) =>
            s.title.toLowerCase().contains(kw) ||
            s.author.toLowerCase().contains(kw),
      ),
    );
  }

                                             
                   
                                             

                                          
  static List<AudioZoneMenu> parseMenuList(Map<String, dynamic>? data) {
    final list = biliAsList<Map<String, dynamic>>(data?['data']);
    return list.map(AudioZoneMenu.fromJson).toList();
  }

                                                                
  static AudioZoneMenuDetail? parseMenuDetail(Map<String, dynamic>? data) {
    if (data == null) return null;
    final menuJson = biliAsMap(data['menusRespones']);
    if (menuJson == null) return null;
    final menu = AudioZoneMenu.fromJson(menuJson);
    if (menu.menuId <= 0) return null;
    final songs = biliAsList<Map<String, dynamic>>(
      data['songsList'],
    ).map(AudioZoneSong.fromJson).toList();
    return AudioZoneMenuDetail(menu: menu, songs: songs);
  }

                                                         
  static AudioPlayUrl? parsePlayUrl(Map<String, dynamic>? data) {
    if (data == null) return null;
    final urls = biliAsList<String>(data['cdns'])
        .map(biliNormalizeUrl)
        .where((u) => u.isNotEmpty)
        .toList();
    if (urls.isEmpty) return null;
    return AudioPlayUrl(
      sid: biliToInt(data['sid'] ?? data['songid']),
      type: biliToInt(data['type']),
      timeout: biliToInt(data['timeout']),
      size: biliToInt(data['size']),
      urls: List.unmodifiable(urls),
      title: biliAsStr(data['title']),
      cover: biliNormalizeUrl(biliAsStr(data['cover'])),
    );
  }
}
