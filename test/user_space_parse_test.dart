import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';

void main() {
  group('BiliUserBangumi.fromJson', () {
    test('parses real follow/list API sample', () {
      final sample =
          File('C:/Users/memz2345/AppData/Local/Temp/follow_bgm2.json');
      if (!sample.existsSync()) {
        markTestSkipped('缺少真实接口样本 follow_bgm2.json');
        return;
      }
      final json = jsonDecode(sample.readAsStringSync())
          as Map<String, dynamic>;
      expect(json['code'], 0);
      final data = json['data'] as Map<String, dynamic>;
      final page = BiliUserBangumiPage(
        items: (data['list'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(BiliUserBangumi.fromJson)
            .toList(),
        total: (data['total'] as num).toInt(),
      );
      expect(page.total, greaterThan(0));
      expect(page.items, isNotEmpty);
      final first = page.items.first;
      expect(first.title, isNotEmpty);
      expect(first.cover, isNotEmpty);
      expect(first.seasonId, greaterThan(0));
    });
  });

  group('BiliUserVideo.fromJson', () {
    test('parses length as "MM:SS" string without crash', () {
      final json = {
        'bvid': 'BV1xx411c7mD',
        'title': 'test',
        'pic': '//pic',
        'author': 'a',
        'mid': 1,
        'play': 100,
        'video_review': 5,
        'length': '02:03',
        'created': 1700000000,
      };
      final v = BiliUserVideo.fromJson(json);
      expect(v.duration, 123);
    });

    test('parses length as seconds number without crash', () {
      final json = {
        'bvid': 'BV1xx411c7mD',
        'title': 'test',
        'pic': '//pic',
        'author': 'a',
        'mid': 1,
        'play': 100,
        'video_review': 5,
        'length': 75,
        'created': 1700000000,
      };
      final v = BiliUserVideo.fromJson(json);
      expect(v.duration, 75);
    });

    test('parses length as "1:02:03" hours format', () {
      final json = {
        'bvid': 'B',
        'title': 't',
        'pic': '',
        'author': '',
        'mid': 1,
        'play': 0,
        'video_review': 0,
        'length': '1:02:03',
        'created': 0,
      };
      final v = BiliUserVideo.fromJson(json);
      expect(v.duration, 3723);
    });
  });

  group('BiliUserDynamic.fromJson', () {
    test('does not crash when module_stat count is bool', () {
      final json = {
        'id_str': '123',
        'type': 'DYNAMIC_TYPE_ARCHIVE',
        'modules': {
          'module_dynamic': {
            'desc': {'text': 'hello'},
            'major': {
              'type': 'MAJOR_TYPE_ARCHIVE',
              'archive': {
                'title': 't',
                'cover': '//cover',
              },
            },
          },
          'module_author': {'pub_ts': 1700000000},
          'module_stat': {
            'like': {'count': true, 'status': false},
            'comment': {'count': 12},
          },
        },
      };
      final d = BiliUserDynamic.fromJson(json);
      expect(d.like, 0);
      expect(d.comment, 12);
      expect(d.title, 't');
      expect(d.text, 'hello');
    });

    test('does not crash when stat entry itself is bool', () {
      final json = {
        'id_str': '123',
        'type': 'DYNAMIC_TYPE_OPUS',
        'modules': {
          'module_dynamic': {
            'desc': {'text': 'x'},
            'major': {
              'type': 'MAJOR_TYPE_OPUS',
              'opus': {
                'title': 'opus title',
                'summary': {'text': 'summary'},
                'pics': [
                  {'url': '//pic'},
                ],
              },
            },
          },
          'module_author': {'pub_ts': 1700000000},
          'module_stat': {
            'like': false,
            'comment': {'count': '1.2万'},
          },
        },
      };
      final d = BiliUserDynamic.fromJson(json);
      expect(d.like, 0);
      expect(d.comment, 12000);
      expect(d.cover, '//pic');
    });

    test('does not crash on PGC dynamic missing fields', () {
      final json = {
        'id_str': 'abc',
        'type': 'DYNAMIC_TYPE_PGC',
        'modules': {
          'module_dynamic': {
            'major': {'type': 'MAJOR_TYPE_PGC'},
          },
          'module_author': {'pub_ts': 'not a number'},
          'module_stat': null,
        },
      };
      final d = BiliUserDynamic.fromJson(json);
      expect(d.pubTs, 0);
      expect(d.title, '');
    });
  });
}
