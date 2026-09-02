// 回归测试：openBilibiliVideo 的路由选择——
// 默认入口（搜索页等）：横竖屏都走 FrostedHeroRoute（iOS 整页放大）；
// 推荐视频入口（wideClassic: true）：宽屏走标准 MaterialPageRoute（封面 Hero、无模糊）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tag = 'bili_video_BV1xx411c7mD';

Future<void> setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NetworkSettingsService().initialize();
    SettingsService.heroTransitionBlurEnabled = true;
  });

  Future<void> runCase(
    WidgetTester tester,
    Size size,
    Type expectedRoute, {
    bool wideClassic = false,
  }) async {
    await setSurface(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: Hero(
              tag: _tag,
              child: const SizedBox(width: 120, height: 68),
            ),
          ),
        ),
      ),
    );
    final ctx = tester.element(find.byType(Scaffold));
    openBilibiliVideo(
      ctx,
      bvid: 'BV1xx411c7mD',
      heroTag: _tag,
      wideClassic: wideClassic,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final pushedScaffold = tester.element(find.byType(Scaffold).last);
    final route = ModalRoute.of(pushedScaffold);
    expect(route, isNotNull);
    expect(
      route.runtimeType,
      expectedRoute,
      reason: '${size.width}px 宽、wideClassic=$wideClassic 时应使用 '
          '$expectedRoute',
    );

    Navigator.of(ctx).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('竖屏（搜索入口，默认）→ FrostedHeroRoute', (tester) async {
    await runCase(tester, const Size(400, 800), FrostedHeroRoute);
  });

  testWidgets('竖屏 + wideClassic（推荐视频入口）→ FrostedHeroRoute 且整页 Hero 放大生效',
      (tester) async {
    await setSurface(tester, const Size(400, 800));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: Hero(
              tag: _tag,
              child: const SizedBox(width: 120, height: 68),
            ),
          ),
        ),
      ),
    );
    final ctx = tester.element(find.byType(Scaffold));
    openBilibiliVideo(
      ctx,
      bvid: 'BV1xx411c7mD',
      heroTag: _tag,
      wideClassic: true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // 入场飞行中：来源卡片 Hero + 视频页整页 Hero（同 tag 共两个）
    final heroes = find.byWidgetPredicate((w) => w is Hero && w.tag == _tag);
    expect(heroes.evaluate().length, 2,
        reason: '竖屏推荐视频应保留整页 Hero 放大（模糊动画）');

    // 飞行结束后（整页 Hero 已移除）再检查路由类型
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
    final route =
        ModalRoute.of(tester.element(find.byType(Scaffold).last));
    expect(route.runtimeType, FrostedHeroRoute,
        reason: '竖屏推荐视频应使用毛玻璃路由');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('宽屏（搜索入口，默认）→ FrostedHeroRoute（保留 iOS 动画）',
      (tester) async {
    await runCase(tester, const Size(1024, 768), FrostedHeroRoute);
  });

  testWidgets('宽屏 + wideClassic（推荐视频入口）→ 标准 MaterialPageRoute（无模糊）',
      (tester) async {
    await runCase(
      tester,
      const Size(1024, 768),
      MaterialPageRoute,
      wideClassic: true,
    );
  });
}
