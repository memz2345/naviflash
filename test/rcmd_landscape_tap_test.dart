// 端到端回归：B 站推荐页（横屏 / 竖屏）整条链路无异常。
// 覆盖的缺陷（均来自用户 navi_crash.log 实测）：
//   1. 加载更多未与已有列表去重 → 同一 bvid 出现两次 → 同名 Hero tag →
//      点击视频抛「There are multiple heroes that share the same tag」；
//   2. 轮播卡片两侧邻卡（1/9 宽）信息行横向 RenderFlex 溢出（42-87px）；
//   3. 单列列表卡片固定 84px 高度内内容超限 → 纵向溢出（5.4-27px）；
//   4. 热门 tab 兜底入口 Expanded 嵌套 Expanded → Incorrect use of
//      ParentDataWidget；
//   5. dispose 里 context.read → Looking up a deactivated widget's ancestor。
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_recommend_page.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockNetSettings extends NetworkSettingsService {
  @override
  Future<http.Client> getApiClient() async {
    return MockClient((request) async {
      final path = request.url.path;
      Map<String, dynamic> body;
      if (path.contains('/x/web-interface/nav')) {
        body = {
          'code': 0,
          'data': {
            'wbi_img': {
              'img_url':
                  'https://i0.hdslb.com/bfs/wbi/7cd084941338484aae1ad9425b84077c.png',
              'sub_url':
                  'https://i0.hdslb.com/bfs/wbi/4932caff0ff746eab6f01bf08b70ac45.png',
            },
          },
        };
      } else if (path.contains('/x/frontend/finger/spi')) {
        body = {
          'code': 0,
          'data': {'b_3': 'mock_buvid3', 'b_4': 'mock_buvid4'},
        };
      } else if (path.contains('feed/rcmd') || path.contains('top/feed')) {
        // 模拟推荐分页返回重叠数据：第二页故意包含第一页末几条（6-10）
        final freshIdx = int.tryParse(
              request.url.queryParameters['fresh_idx'] ?? '0',
            ) ??
            0;
        final start = freshIdx == 0 ? 1 : 6; // 第二页起从 6 开始 → 与首页重叠
        body = {
          'code': 0,
          'message': '0',
          'data': {
            'item': [
              for (var i = start; i < start + 10; i++)
                {
                  'id': i,
                  'bvid': 'BV1xx411c7m$i',
                  'cid': 1000 + i,
                  'title': '测试视频标题$i',
                  'pic': 'https://i0.hdslb.com/bfs/archive/$i.jpg',
                  'duration': 120 + i,
                  'pubdate': 1700000000,
                  'owner': {'mid': 1, 'name': '测试UP主'},
                  'stat': {
                    'view': 1000 * i,
                    'danmaku': 10 * i,
                    'like': 5 * i,
                  },
                  'rcmd_reason': {'content': '为你推荐$i'},
                  'goto': 'av',
                },
            ],
          },
        };
      } else {
        // 其余（视频详情 / 热搜等）→ 404，页面进入错误态但不崩溃
        return http.Response(
          '{"code":-404,"message":"not found"}',
          404,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _MockNetSettings().initialize();
    await BilibiliAccountService().initialize();
    await BilibiliTranslateService().initialize();
    SettingsService.heroTransitionBlurEnabled = true;
  });

  Future<void> setSurface(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpRecommend(WidgetTester tester, Size size) async {
    await setSurface(tester, size);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: SettingsService()),
          ChangeNotifierProvider.value(value: NetworkSettingsService.instance),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BilibiliRecommendPage(),
        ),
      ),
    );
    // 等待推荐列表加载完成（含 60ms 入场动画延迟）
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder gridHeroes() => find.byWidgetPredicate(
        (w) =>
            w is Hero &&
            w.tag is String &&
            (w.tag as String).startsWith('bili_video_'),
      );

  /// 确保某个 Hero 卡片可见后点击，再逐帧推进转场，期间任何异常即失败。
  Future<void> tapFirstVideo(WidgetTester tester, String reason) async {
    final hero = gridHeroes();
    expect(hero, findsWidgets, reason: '$reason：网格应渲染出视频卡片');
    await tester.ensureVisible(hero.first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(hero.first, warnIfMissed: false);
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final e = tester.takeException();
      if (e != null) {
        fail('$reason：点击视频后转场第 $i 帧抛异常: $e');
      }
    }
    expect(tester.takeException(), isNull, reason: '$reason：转场结束后不应有异常');
  }

  testWidgets('横屏（1024×768）推荐页加载、轮播、点视频均无异常', (tester) async {
    await pumpRecommend(tester, const Size(1024, 768));
    expect(tester.takeException(), isNull, reason: '横屏推荐页构建/加载（含轮播）不应有异常');

    await tapFirstVideo(tester, '横屏');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('竖屏（400×800）对照：加载、点视频均无异常', (tester) async {
    await pumpRecommend(tester, const Size(400, 800));
    expect(tester.takeException(), isNull);

    await tapFirstVideo(tester, '竖屏');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('加载更多返回重叠数据：列表不出现重复 bvid，点视频无 Hero 重复异常', (tester) async {
    await pumpRecommend(tester, const Size(1024, 768));

    // 滚动到底触发加载更多（第二页故意返回与首页重叠的 bvid 6-10）
    final scrollable = find
        .byType(CustomScrollView)
        .first; // 第一个是外层垂直 feed（轮播是横向的）
    for (var i = 0; i < 4; i++) {
      await tester.drag(scrollable, const Offset(0, -1500));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull, reason: '加载更多不应有异常');

    // 断言：网格中所有 bili_video_ tag 唯一（无重复 bvid）
    final tags = <Object, int>{};
    for (final e in gridHeroes().evaluate()) {
      final tag = (e.widget as Hero).tag;
      tags[tag] = (tags[tag] ?? 0) + 1;
    }
    final dup = tags.entries.where((e) => e.value > 1).toList();
    expect(dup, isEmpty,
        reason: '加载更多后不应有重复 Hero tag（重复会在点击视频时抛异常），实际: $dup');

    await tapFirstVideo(tester, '加载更多后');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('单列模式列表卡片不纵向溢出，点视频无异常', (tester) async {
    await pumpRecommend(tester, const Size(1024, 768));

    // 点击 FAB 切换到单列模式
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull, reason: '单列模式布局不应有纵向溢出');

    await tapFirstVideo(tester, '单列模式');

    // 切回网格模式，避免污染后续测试的静态状态
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('热门 tab 兜底入口（云控失败）无 ParentDataWidget 异常', (tester) async {
    await pumpRecommend(tester, const Size(1024, 768));

    // 切到「热门」tab：云控入口 gRPC 失败 → 回退本地兜底入口 Row
    await tester.tap(find.text('热门'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull,
        reason: '热门 tab 兜底入口不应有 Expanded 嵌套（ParentDataWidget）异常');

    // 兜底入口应渲染出来
    expect(find.text('排行榜'), findsOneWidget);
    expect(find.text('每周必看'), findsOneWidget);
    expect(find.text('入站必刷'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
