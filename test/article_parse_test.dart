import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/services/bilibili_article_service.dart';

void main() {
  group('BiliArticle.fromJson', () {
    test('parses type=1 HTML article', () {
      final json = {
        'id': 12345,
        'type': 1,
        'title': '测试专栏标题',
        'publish_time': 1700000000,
        'author': {'mid': 1, 'name': 'up主', 'face': '//face'},
        'origin_image_urls': ['//img1', 'https://i0.hdslb.com/img2'],
        'content':
            '<p>第一段</p><p><strong>加粗</strong>与<a href="https://x">链接</a></p>',
        'stats': {
          'view': 10000,
          'like': 200,
          'favorite': 30,
          'reply': 40,
          'share': 5,
          'coin': 2,
        },
      };
      final article = BiliArticle.fromJson(json);
      expect(article.id, 12345);
      expect(article.type, 1);
      expect(article.title, '测试专栏标题');
      expect(article.publishTime, 1700000000);
      expect(article.author?.mid, 1);
      expect(article.author?.face, 'https://face');
      expect(article.isHtml, isTrue);
      expect(article.isOps, isFalse);
      expect(article.contentHtml, contains('<strong>'));
      expect(article.cover, 'https://img1');
      expect(article.images, hasLength(2));
      expect(article.stats?.view, 10000);
      expect(article.url, 'https://www.bilibili.com/read/cv12345');
    });

    test('parses type=3 ops article (text + image card)', () {
      final json = {
        'id': 678,
        'type': 3,
        'title': 'ops 文章',
        'ops': [
          {'insert': '第一行\n'},
          {
            'insert': {'image': '//pic'},
          },
          {
            'insert': '第二行',
            'attributes': {'class': 'title'},
          },
        ],
      };
      final article = BiliArticle.fromJson(json);
      expect(article.type, 3);
      expect(article.isOps, isTrue);
      expect(article.isHtml, isFalse);
      expect(article.ops, hasLength(3));
      expect(article.ops.first.insert, '第一行\n');
      expect(article.ops[1].cardImage, 'https://pic');
      expect(article.ops[2].clazz, 'title');
    });

    test('does not crash on missing fields', () {
      final json = {
        'id': '1',
        'type': '1',
        'stats': null,
        'ops': 'not-a-list',
        'origin_image_urls': null,
      };
      final article = BiliArticle.fromJson(json);
      expect(article.id, 1);
      expect(article.type, 1);
      expect(article.title, '');
      expect(article.author, isNull);
      expect(article.stats, isNull);
      expect(article.ops, isEmpty);
      expect(article.images, isEmpty);
      expect(article.contentHtml, '');
    });
  });

  group('BiliArticleOps', () {
    test('cardImage reads url or image key', () {
      expect(
        BiliArticleOps.fromJson({
          'insert': {'url': '//a'},
        }).cardImage,
        'https://a',
      );
      expect(
        BiliArticleOps.fromJson({
          'insert': {'image': 'https://b'},
        }).cardImage,
        'https://b',
      );
      expect(
        BiliArticleOps.fromJson({'insert': 'text'}).cardImage,
        isNull,
      );
    });
  });
}
