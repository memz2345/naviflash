// 回归测试：视频播放页作为被覆盖页时的 iOS 景深背景缩放——
// push 新视频（毛玻璃路由 / 普通 MaterialPageRoute）后，
// 原视频页内容向屏幕中心缩小 + 渐隐 + 圆角（与搜索页 IosBackdropScale
// 同款），返回时反向恢复；视频页自身入场飞行期间（当前路由）不缩放。
//
// 断言方式：缩放 Transform 包裹的是页面内容（页面组件自身在 Transform
// 之上），因此测量内容盒的 global 左上角——被缩放时它向屏幕中心移动，
// 恢复时回到原点。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 被覆盖视频页（树序第一个）的内容盒（IosBackdropScale 缩放的正是它）。
Finder _contentOfFirstPage() => find
    .descendant(
      of: find.byType(BilibiliVideoPage).first,
      matching: find.byType(Scaffold),
    )
    .first;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NetworkSettingsService().initialize();
    SettingsService.heroTransitionBlurEnabled = true;
  });

  Future<void> setSurface(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<NavigatorState> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Center(child: Text('home'))),
      ),
    );
    return Navigator.of(tester.element(find.byType(Scaffold)));
  }

  testWidgets('视频页入场飞行期间自身不缩放（当前路由守卫）', (tester) async {
    await setSurface(tester);
    final nav = await pumpHome(tester);
    nav.push(
      heroTransitionRoute(
        heroZoom: true,
        page: const BilibiliVideoPage(bvid: 'BV1xx411c7mD'),
      ),
    );
    await tester.pump();
    // 入场飞行中段：视频页是当前路由，不应叠加背景缩放
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(_contentOfFirstPage()),
      Offset.zero,
      reason: '入场飞行期间视频页自身不应缩放（否则与整页放大双重形变）',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('push 新视频（毛玻璃路由）→ 原视频页背景缩放，pop 后恢复', (tester) async {
    await setSurface(tester);
    final nav = await pumpHome(tester);
    nav.push(
      heroTransitionRoute(
        heroZoom: true,
        page: const BilibiliVideoPage(bvid: 'BV1xx411c7mD'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(_contentOfFirstPage()),
      Offset.zero,
      reason: '转场完成后视频页应恢复原比例',
    );

    // push 新视频：原视频页被覆盖，内容应向屏幕中心缩小
    nav.push(
      heroTransitionRoute(
        heroZoom: true,
        page: const BilibiliVideoPage(bvid: 'BV1xx411c7mE'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.takeException(), isNull);
    final midTopLeft = tester.getTopLeft(_contentOfFirstPage());
    expect(
      midTopLeft.dx > 1 && midTopLeft.dy > 1,
      isTrue,
      reason: 'push 新视频后原视频页内容应向屏幕中心收缩（左上角内移 $midTopLeft）',
    );

    // 新视频转场完成（原视频页被完全遮住，缩放恢复不可见）
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    // pop 返回：原视频页应在反向转场中逐步恢复原比例
    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.getTopLeft(_contentOfFirstPage()),
      Offset.zero,
      reason: 'pop 结束后视频页应恢复原比例',
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('push 普通 MaterialPageRoute → 视频页背景缩放', (tester) async {
    await setSurface(tester);
    final nav = await pumpHome(tester);
    nav.push(
      heroTransitionRoute(
        heroZoom: true,
        page: const BilibiliVideoPage(bvid: 'BV1xx411c7mD'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);

    // 普通路由压栈：由 secondaryAnimation 驱动缩放
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Center(child: Text('top'))),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    final midTopLeft = tester.getTopLeft(_contentOfFirstPage());
    expect(
      midTopLeft.dx > 1 && midTopLeft.dy > 1,
      isTrue,
      reason: '普通 MaterialPageRoute 压栈也应触发视频页背景缩放（$midTopLeft）',
    );

    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getTopLeft(_contentOfFirstPage()), Offset.zero);

    await tester.pumpWidget(const SizedBox());
  });
}
