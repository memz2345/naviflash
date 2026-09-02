import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/services/bilibili_season_service.dart';

void main() {
  group('BilibiliSeasonService.parseResult', () {
    test('parses main_section episodes from real API sample', () {
      // 使用真实接口返回的结构（season_id=46089）
      final raw = File(
              'C:/Users/memz2345/AppData/Local/Temp/opencode/section.json')
          .readAsStringSync();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      expect(json['code'], 0);

      final episodes = BilibiliSeasonService.parseResult(json['result']);
      expect(episodes, isNotNull);
      expect(episodes!.length, greaterThan(0));
      expect(episodes.first.cid, greaterThan(0));
      expect(episodes.first.epId, greaterThan(0));
      expect(episodes.first.displayTitle, isNotEmpty);
      // 顺序保持（第1集在前）
      expect(episodes.first.epId, lessThan(episodes.last.epId));
    });

    test('dedupes identical episodes across sections', () {
      final result = {
        'main_section': {
          'episodes': [
            {
              'id': 1,
              'cid': 100,
              'aid': 9,
              'title': '第1话',
              'long_title': '开场',
              'duration': 1200,
            },
          ],
        },
        'sections': [
          {
            'episodes': [
              {
                'id': 1,
                'cid': 100,
                'aid': 9,
                'title': '第1话',
                'long_title': '开场',
                'duration': 1200,
              },
              {
                'id': 2,
                'cid': 200,
                'aid': 9,
                'title': '第2话',
                'long_title': '发展',
                'duration': 1300,
              },
            ],
          },
        ],
      };
      final episodes = BilibiliSeasonService.parseResult(result);
      expect(episodes, isNotNull);
      expect(episodes!.length, 2);
      expect(episodes[0].cid, 100);
      expect(episodes[1].cid, 200);
    });

    test('returns null on malformed result', () {
      expect(BilibiliSeasonService.parseResult(null), isNull);
      expect(BilibiliSeasonService.parseResult('nope'), isNull);
      expect(BilibiliSeasonService.parseResult({}), isNull);
    });
  });
}
