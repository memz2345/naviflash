import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/widgets/comment/comment_content.dart';

void main() {
  group('BiliComment.fromJson emotes & pictures', () {
    test('parses emote map and pictures from real reply API sample', () {
      final sample =
          File('C:/Users/memz2345/AppData/Local/Temp/reply_hit.json');
      if (!sample.existsSync()) {
        markTestSkipped('缺少真实评论接口样本 reply_hit.json');
        return;
      }
      final json = jsonDecode(sample.readAsStringSync())
          as Map<String, dynamic>;
      expect(json['code'], 0);
      final data = json['data'] as Map<String, dynamic>;
      final replies = [
        ...(data['replies'] as List<dynamic>? ?? const []),
        ...(data['top_replies'] as List<dynamic>? ?? const []),
      ];
      final comments = replies
          .whereType<Map<String, dynamic>>()
          .map(BiliComment.fromJson)
          .toList();
      expect(comments, isNotEmpty);
      final withEmotes =
          comments.where((c) => c.emotes.isNotEmpty).toList();
      expect(withEmotes, isNotEmpty, reason: '样本应包含带表情的评论');
      final first = withEmotes.first;
      expect(first.message.contains(first.emotes.keys.first), isTrue);
      expect(first.emotes.values.first.url, startsWith('https://'));
      expect(first.emotes.values.first.size, greaterThan(0));
    });

    test('normalizes http:// picture src to https', () {
      final pic = BiliCommentPicture.fromJson({
        'img_src': 'http://i0.hdslb.com/bfs/new_dyn/xxx.png',
        'img_width': 1080,
        'img_height': 1084,
      });
      expect(pic.src, startsWith('https://'));
      expect(pic.width, 1080);
      expect(pic.height, 1084);
    });

    test('handles pictures as single object', () {
      final c = BiliComment.fromJson({
        'rpid': '1',
        'oid': '1',
        'content': {
          'message': 'x',
          'pictures': {
            'img_src': '//i0.hdslb.com/bfs/new_dyn/xxx.png',
            'img_width': 10,
            'img_height': 10,
          },
        },
        'member': {},
      });
      expect(c.pictures, hasLength(1));
      expect(c.pictures.first.src, startsWith('https://'));
    });
  });

  group('buildCommentSpans', () {
    test('replaces emote keys with WidgetSpan', () {
      final spans = buildCommentSpans(
        message: '哈哈[微笑]不错',
        emotes: {
          '[微笑]': const BiliCommentEmote(
            text: '[微笑]',
            url: 'https://i0.hdslb.com/bfs/emote/xxx.png',
            size: 2,
          ),
        },
      );
      expect(spans.whereType<WidgetSpan>(), hasLength(1));
      // 纯文本段保留
      final texts = spans
          .whereType<TextSpan>()
          .map((s) => s.text ?? '')
          .join();
      expect(texts, contains('哈哈'));
      expect(texts, contains('不错'));
      expect(texts, isNot(contains('[微笑]')));
    });

    test('keeps unknown brackets as plain text', () {
      final spans = buildCommentSpans(
        message: '未知表情[不存在的]',
        emotes: {
          '[微笑]': const BiliCommentEmote(
            text: '[微笑]',
            url: 'https://i0.hdslb.com/bfs/emote/xxx.png',
            size: 1,
          ),
        },
      );
      expect(spans.whereType<WidgetSpan>(), isEmpty);
      final texts = spans
          .whereType<TextSpan>()
          .map((s) => s.text ?? '')
          .join();
      expect(texts, contains('[不存在的]'));
    });

    test('no emotes -> single plain text span', () {
      final spans = buildCommentSpans(
        message: '纯文本',
        emotes: const {},
      );
      expect(spans, hasLength(1));
      expect((spans.first as TextSpan).text, '纯文本');
    });
  });
}
