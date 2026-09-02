// lib/services/sponsor_block_service.dart
//   通过 BilibiliSponsorBlock 社区共享数据（https://www.bsbsb.top）按
//   BV + CID 查询视频的片头(intro)/片尾(outro)片段，提示用户一键跳过。
//   仅当视频同时具备 BV 与 CID 时才可用。
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:naviflash/services/network_settings_service.dart';

/// 一个可跳过的片段（毫秒为单位）
class SponsorSegment {
  final String category; // 'intro' | 'outro'
  final int startMs;
  final int endMs;
  final String uuid;
  bool skipped;

  SponsorSegment({
    required this.category,
    required this.startMs,
    required this.endMs,
    required this.uuid,
    this.skipped = false,
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

  /// 是否为可提示的片头/片尾类别
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

  /// 通过 BV 号解析出该视频（第一分 P）的 CID，解析失败返回 null
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
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json['code'] != 0) return null;
      final data = json['data'];
      if (data is! List || data.isEmpty) return null;
      return (data[0]['cid'] as num?)?.toInt();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 解析 BV→CID 失败: $e');
      return null;
    }
  }

  /// 按 BV + CID 查询片头/片尾片段（毫秒），失败返回 null
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
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
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

  /// 便捷入口：传入 BV（+ 可选 CID），自动解析 CID 后查询。
  /// 无 BV 或 CID 解析失败时返回 null —— 即"仅在有 BV、CID 时才提示"。
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
