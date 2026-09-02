// 回归测试：全局翻译标题缓存 + 搜索结果磁盘缓存的序列化与读写。
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/services/bilibili_search_cache.dart';
import 'package:naviflash/services/bilibili_search_service.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

BiliSearchItem _item(String bvid, String title) => BiliSearchItem(
      type: BiliSearchType.video,
      mid: 0,
      titleSegments: [(text: title, highlight: bvid == 'BV1')],
      cover: 'https://example.com/$bvid.jpg',
      subtitle: 'up',
      meta: '10播放',
      badge: '',
      duration: '12:34',
      actionUrl: 'https://www.bilibili.com/video/$bvid',
      desc: 'desc',
      play: 10,
      danmaku: 5,
      id: 0,
      bvid: bvid,
      seasonId: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BilibiliTitleCache', () {
    test('未初始化时不抛错，安全回退原文', () {
      expect(
        BilibiliTitleCache.translatedTitle('BV1'),
        isNull,
        reason: '未初始化不应抛错',
      );
      expect(
        BilibiliTitleCache.displayTitle('BV1', '原文'),
        '原文',
        reason: '未初始化时应回退原文',
      );
    });

    test('初始化后 remember/读取并跨实例持久化', () async {
      await BilibiliTitleCache().initialize();
      BilibiliTitleCache.remember('BV1', '原来', '翻译后');
      expect(BilibiliTitleCache.translatedTitle('BV1'), '翻译后');
      expect(BilibiliTitleCache.displayTitle('BV1', '原来'), '翻译后');
      expect(BilibiliTitleCache.displayTitle('BV2', '没翻译'), '没翻译');

      // 换一个新实例模拟重启，验证磁盘持久化
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('biliVideoTranslatedTitles');
      expect(raw, isNotNull, reason: '应已落盘');
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded['BV1'], '翻译后');
    });

    test('与原文相同的译名不存储（避免污染）', () async {
      await BilibiliTitleCache().initialize();
      BilibiliTitleCache.remember('BV1', 'abc', 'abc');
      expect(BilibiliTitleCache.translatedTitle('BV1'), isNull);
    });
  });

  group('BilibiliSearchCache', () {
    test('save/load 往返一致', () async {
      final entry = BiliSearchCacheEntry(
        items: [_item('BV1', '标题一'), _item('BV2', '标题二')],
        numResults: 2,
        page: 1,
        hasMore: true,
        savedAt: DateTime.now(),
      );
      const key = 'video||keyword';
      await BilibiliSearchCache.save(key, entry);

      final loaded = await BilibiliSearchCache.load(key);
      expect(loaded, isNotNull);
      expect(loaded!.items.length, 2);
      expect(loaded.items.first.bvid, 'BV1');
      expect(loaded.items.first.titleSegments.first.text, '标题一');
      expect(loaded.items.first.titleSegments.first.highlight, isTrue);
      expect(loaded.items.last.bvid, 'BV2');
      expect(loaded.numResults, 2);
      expect(loaded.page, 1);
      expect(loaded.hasMore, isTrue);
    });

    test('过期的缓存返回 null', () async {
      final old = BiliSearchCacheEntry(
        items: [_item('BV1', '标题一')],
        numResults: 1,
        page: 1,
        hasMore: false,
        savedAt: DateTime.now().subtract(const Duration(minutes: 11)),
      );
      const key = 'video||old';
      await BilibiliSearchCache.save(key, old);
      expect(await BilibiliSearchCache.load(key), isNull);
    });

    test('不同筛选条件使用不同缓存键', () {
      final a = BilibiliSearchCache.keyFor(
        keyword: 'k',
        type: BiliSearchType.video,
        filterKey: '',
      );
      final b = BilibiliSearchCache.keyFor(
        keyword: 'k',
        type: BiliSearchType.video,
        filterKey: 'd1',
      );
      final c = BilibiliSearchCache.keyFor(
        keyword: 'k2',
        type: BiliSearchType.video,
        filterKey: '',
      );
      expect(a, isNot(b));
      expect(a, isNot(c));
    });
  });
}
