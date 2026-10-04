                                          
                                                           
                                                  
                            
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:naviflash/services/network_settings_service.dart';

                   
class SponsorSegment {
  final String category;                     
  final int startMs;
  final int endMs;
  final String uuid;
  bool skipped;

                                              
  final bool fromPgc;

  SponsorSegment({
    required this.category,
    required this.startMs,
    required this.endMs,
    required this.uuid,
    this.skipped = false,
    this.fromPgc = false,
  });

  factory SponsorSegment.fromJson(Map<String, dynamic> json) {
    final raw = json['segment'];
    final start = raw is List && raw.isNotEmpty ? (raw[0] as num) : 0;
    final end = raw is List && raw.length > 1 ? (raw[1] as num) : start;
    return SponsorSegment(
      category: (json['category'] as String?) ?? '',
      startMs: (start * 1000).round(),
      endMs: (end * 1000).round(),
      uuid: (json['UUID'] as String?) ?? '',
    );
  }

  static const Map<String, String> _titles = {
    'intro': 'intro',
    'outro': 'outro',
  };

                    
  bool get isSkipableCategory => _titles.containsKey(category);
}

class SponsorBlockService {
  SponsorBlockService._();

  static const String _server = 'https://www.bsbsb.top';
  static const String _pageListApi =
      'https://api.bilibili.com/x/player/pagelist';

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.bilibili.com',
  };

                                           
  static Future<int?> resolveCidByBv(String bvid) async {
    try {
      final uri = Uri.parse(_pageListApi).replace(
        queryParameters: {'bvid': bvid.trim()},
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            uri,
            headers: {
              ..._headers,
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;
      final data = json['data'];
      if (data is! List || data.isEmpty) return null;
      return (data[0]['cid'] as num?)?.toInt();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 解析 BV→CID 失败: $e');
      return null;
    }
  }

                                        
  static Future<List<SponsorSegment>?> fetchSegments({
    required String bvid,
    required int cid,
  }) async {
    try {
      final uri = Uri.parse('$_server/api/skipSegments').replace(
        queryParameters: {'videoID': bvid.trim(), 'cid': '$cid'},
      );
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            uri,
            headers: {
              ..._headers,
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final decoded = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (decoded is! List) return null;

      final segments = decoded
          .whereType<Map<String, dynamic>>()
          .map(SponsorSegment.fromJson)
          .where((s) =>
              s.isSkipableCategory &&
              s.endMs > s.startMs &&
              s.endMs > 0)
          .toList()
        ..sort((a, b) => a.startMs.compareTo(b.startMs));
      if (segments.isEmpty) return null;
      return segments;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 查询片头片尾失败: $e');
      return null;
    }
  }

                                        
                                                    
  static Future<List<SponsorSegment>?> fetchForVideo({
    required String bvid,
    int? cid,
  }) async {
    final trimmed = bvid.trim();
    if (trimmed.isEmpty || !RegExp(r'^(BV|bv)[0-9A-Za-z]+$').hasMatch(trimmed)) {
      return null;
    }
    var resolvedCid = cid;
    if (resolvedCid == null || resolvedCid <= 0) {
      resolvedCid = await resolveCidByBv(trimmed);
      if (resolvedCid == null) return null;
    }
    return fetchSegments(bvid: trimmed, cid: resolvedCid);
  }
}
