                                           
                                                   
                                                                 
                                                                 
                                                                  
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'bilibili_account_service.dart';
import 'bilibili_user_space_service.dart' show WbiSign;
import 'network_settings_service.dart';

class BiliBgmArtist {
  final String name;
  final int mid;

  const BiliBgmArtist({required this.name, this.mid = 0});
}

class BiliBgmDetail {
  final String musicId;
  final String title;
  final String cover;
  final String album;
  final String source;
  final List<BiliBgmArtist> artists;
  final String mvBvid;
  final int mvCid;
  final int mvAid;
  final bool wishListen;
  final int wishCount;
  final int listenPv;
  final int relationCount;                

  const BiliBgmDetail({
    required this.musicId,
    required this.title,
    required this.cover,
    required this.album,
    required this.source,
    required this.artists,
    required this.mvBvid,
    required this.mvCid,
    required this.mvAid,
    required this.wishListen,
    required this.wishCount,
    required this.listenPv,
    required this.relationCount,
  });

  String get artistText =>
      artists.map((a) => a.name).where((s) => s.isNotEmpty).join(' / ');
}

class BiliBgmRecommend {
  final String bvid;
  final int cid;
  final String cover;
  final String title;
  final String upName;
  final int play;
  final int duration;

  const BiliBgmRecommend({
    required this.bvid,
    required this.cid,
    required this.cover,
    required this.title,
    required this.upName,
    required this.play,
    required this.duration,
  });
}

abstract final class BilibiliMusicService {
  static const String _apiBase = 'https://api.bilibili.com';
  static const String _detailApi =
      '$_apiBase/x/copyright-music-publicity/bgm/detail';
  static const String _recommendApi =
      '$_apiBase/x/copyright-music-publicity/bgm/recommend_list';
  static const String _wishApi =
      '$_apiBase/x/copyright-music-publicity/bgm/wish/update';

  static Map<String, String> _headers() {
    final cookie = BilibiliAccountService.instance
        .cookieHeaderFor(BiliCookieScope.interactions)?['Cookie'];
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': 'https://www.bilibili.com',
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      ...NetworkSettingsService.instance.apiHeaders,
    };
  }

  static String _csrf() {
    final raw = BilibiliAccountService.instance.rawCookie;
    return RegExp('(?:^|;\\s*)bili_jct=([^;]+)').firstMatch(raw)?.group(1) ??
        '';
  }

  static Map<String, dynamic>? _asMap(dynamic v) =>
      v is Map<String, dynamic> ? v : (v is Map ? Map<String, dynamic>.from(v) : null);

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  static String _toStr(dynamic v) => v?.toString() ?? '';

                             
  static Future<BiliBgmDetail?> fetchDetail(String musicId) async {
    if (musicId.isEmpty) return null;
    try {
      final params = await WbiSign.sign({
        'music_id': musicId,
        'relation_from': 'bgm_page',
      });
      final uri = Uri.parse(_detailApi).replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> || _toInt(json['code']) != 0) {
        return null;
      }
      final data = _asMap(json['data']);
      if (data == null) return null;
      final artists = <BiliBgmArtist>[];
      final rawArtists = data['artists_list'];
      if (rawArtists is List) {
        for (final a in rawArtists.whereType<Map<String, dynamic>>()) {
          artists.add(
            BiliBgmArtist(
              name: _toStr(a['name']),
              mid: _toInt(a['mid']),
            ),
          );
        }
      }
      return BiliBgmDetail(
        musicId: musicId,
        title: _toStr(data['music_title']),
        cover: _toStr(data['mv_cover']),
        album: _toStr(data['album']),
        source: _toStr(data['music_source']),
        artists: artists,
        mvBvid: _toStr(data['mv_bvid']),
        mvCid: _toInt(data['mv_cid']),
        mvAid: _toInt(data['mv_aid']),
        wishListen: data['wish_listen'] == true,
        wishCount: _toInt(data['wish_count']),
        listenPv: _toInt(data['listen_pv']),
        relationCount: _toInt(data['music_relation']),
      );
    } catch (e) {
      debugPrint('[Music] 拉取 BGM 详情失败: $e');
      return null;
    }
  }

                    
  static Future<List<BiliBgmRecommend>> fetchRecommend(String musicId) async {
    if (musicId.isEmpty) return const [];
    try {
      final uri = Uri.parse(_recommendApi)
          .replace(queryParameters: {'music_id': musicId});
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return const [];
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> || _toInt(json['code']) != 0) {
        return const [];
      }
      final data = json['data'];
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => BiliBgmRecommend(
              bvid: _toStr(e['bvid']),
              cid: _toInt(e['cid']),
              cover: _toStr(e['cover']),
              title: _toStr(e['title']),
              upName: _toStr(e['up_nick_name']),
              play: _toInt(e['play']),
              duration: _toInt(e['duration']),
            ),
          )
          .where((e) => e.bvid.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[Music] 拉取 BGM 推荐失败: $e');
      return const [];
    }
  }

                                  
  static Future<({bool ok, String message})> wish({
    required String musicId,
    required bool like,
  }) async {
    final csrf = _csrf();
    if (csrf.isEmpty) return (ok: false, message: '请先登录');
    try {
      final resp = await (await NetworkSettingsService.instance.getApiClient())
          .post(
            Uri.parse(_wishApi),
            headers: {
              ..._headers(),
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'music_id': musicId,
              'state': like ? '1' : '2',
              'csrf': csrf,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        return (ok: false, message: 'HTTP ${resp.statusCode}');
      }
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> || _toInt(json['code']) != 0) {
        final msg = json is Map ? _toStr(json['message']) : '';
        return (ok: false, message: msg.isEmpty ? '操作失败' : msg);
      }
      return (ok: true, message: '');
    } catch (e) {
      debugPrint('[Music] 喜欢操作失败: $e');
      return (ok: false, message: '网络异常：${e.runtimeType}');
    }
  }
}
