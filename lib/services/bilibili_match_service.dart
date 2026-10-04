                                           
  
                                                                 
                                    
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/network_settings_service.dart';

class BilibiliMatchService {
  static String? lastErrorDetail;

  static Future<BiliMatchInfo?> fetch({required int cid}) async {
    try {
      final params = <String, String>{
        'cid': cid.toString(),
        'platform': '2',
      };
      final uri = Uri.parse('https://api.bilibili.com/x/esports/match/info')
          .replace(queryParameters: params);
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(uri, headers: NetworkSettingsService.instance.apiHeaders)
          .timeout(const Duration(seconds: 15));
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map || (json['code'] != 0 && json['code'] != 200)) {
        lastErrorDetail = 'code=${json['code']} ${json['message']}';
        return null;
      }
      final data = biliAsMap(json['data']);
      if (data == null) return null;
      return BiliMatchInfo.fromJson(data);
    } catch (e) {
      lastErrorDetail = e.toString();
      return null;
    }
  }
}

class BiliMatchInfo {
  final String gameStage;
  final int stime;
  final int homeId;
  final int awayId;
  final int homeScore;
  final int awayScore;
  final Map<String, dynamic>? liveRoom;
  final String seasonTitle;
  final String seasonLogo;
  final String homeTitle;
  final String homeLogo;
  final String awayTitle;
  final String awayLogo;
  final int contestStatus;                         

  const BiliMatchInfo({
    required this.gameStage,
    required this.stime,
    required this.homeId,
    required this.awayId,
    required this.homeScore,
    required this.awayScore,
    required this.liveRoom,
    required this.seasonTitle,
    required this.seasonLogo,
    required this.homeTitle,
    required this.homeLogo,
    required this.awayTitle,
    required this.awayLogo,
    required this.contestStatus,
  });

  factory BiliMatchInfo.fromJson(Map<String, dynamic> json) {
    final contest = biliAsMap(json['contest']) ?? {};
    final season = biliAsMap(contest['season']) ?? {};
    final homeTeam = biliAsMap(contest['home_team']) ?? {};
    final awayTeam = biliAsMap(contest['away_team']) ?? {};
    return BiliMatchInfo(
      gameStage: biliAsStr(contest['game_stage']),
      stime: biliToInt(contest['stime']),
      homeId: biliToInt(contest['home_id']),
      awayId: biliToInt(contest['away_id']),
      homeScore: biliToInt(contest['home_score']),
      awayScore: biliToInt(contest['away_score']),
      liveRoom: biliAsMap(contest['live_room']),
      seasonTitle: biliAsStr(season['title']),
      seasonLogo: biliNormalizeUrl(biliAsStr(season['logo'])),
      homeTitle: biliAsStr(homeTeam['title']),
      homeLogo: biliNormalizeUrl(biliAsStr(homeTeam['logo'])),
      awayTitle: biliAsStr(awayTeam['title']),
      awayLogo: biliNormalizeUrl(biliAsStr(awayTeam['logo'])),
      contestStatus: biliToInt(contest['contest_status']),
    );
  }

  int? get liveRoomId {
    final id = biliToInt(liveRoom?['room_id']);
    return id > 0 ? id : null;
  }
}
