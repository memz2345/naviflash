// 回归测试：搜索专栏卡片 → ArticlePage 的 Hero 转场（开启「Hero 转场背景模糊」）。
//
// 覆盖两类历史缺陷（与视频页 hero_blur_repro_test.dart 同构）：
//  1. 搜索页同一专栏出现两次（分页重复）→ 同名 Hero tag 重复 → 转场飞行中断；
//  2. 专栏页整页 Hero 内嵌套内层 Hero（加载中封面）→ Flutter 断言报错。
//
// 覆盖的转场路径：
//  - blur ON：整卡 → 专栏页整页放大（heroZoom: true，FrostedHeroRoute），
//    返回时 PopScope 重包裹整页 Hero，卡片缩回原位；
//  - blur OFF：自动回落到经典 MaterialPageRoute（封面飞入，无模糊）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/article_page.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tag = 'article_entry_12345678';

Widget _app() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        // 模拟搜索专栏卡片：封面 + 标题文字（整张卡片参与 Hero 飞行）
        child: Hero(
          tag: _tag,
          child: Container(
            width: 160,
            height: 120,
            color: Colors.black12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: ColoredBox(color: Colors.teal)),
                const SizedBox(height: 4),
                Text(
                  'COLUMN TITLE',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NetworkSettingsService().initialize();
    SettingsService.heroTransitionBlurEnabled = true;
  });

  testWidgets('blur ON: push 进入专栏页并 pop 返回卡片，全程无异常', (tester) async {
    // 整页 Hero 放大为竖屏特性：测试面设为竖屏（宽 < 768）
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app());
    final ctx = tester.element(find.byType(Scaffold));
    Navigator.of(ctx).push(
      heroTransitionRoute(
        heroZoom: true,
        page: const ArticlePage(cvid: 12345678, heroTag: _tag, coverUrl: ''),
      ),
    );
    // 推进转场（320ms）+ 余量，逐帧检查异常
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull,
          reason: 'push 转场第 $i 帧出现异常');
    }
    // 页面应在转场结束后正常显示
    expect(find.byType(ArticlePage), findsOneWidget);

    Navigator.of(ctx).pop();
    var sawCardText = false;
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull,
          reason: 'pop 转场第 $i 帧出现异常');
      // pop 转场的 shuttle 应渲染整张卡片（封面 + 标题文字一起运动）
      if (find.text('COLUMN TITLE').evaluate().isNotEmpty) sawCardText = true;
    }
    expect(sawCardText, isTrue,
        reason: 'pop 转场应渲染整张卡片（含标题文字）一起运动');
    expect(find.byType(ArticlePage), findsNothing);

    // 释放所有状态（停止加载指示器的周期 Timer）
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('点击左上角返回按钮同样走重包裹+pop（带回卡片动画）', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app());
    final ctx = tester.element(find.byType(Scaffold));
    Navigator.of(ctx).push(
      heroTransitionRoute(
        heroZoom: true,
        page: const ArticlePage(cvid: 12345678, heroTag: _tag, coverUrl: ''),
      ),
    );
    // 入场转场完成 → 整页 Hero 已被移除（_zoomHeroActive=false）
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // 点击左上角返回按钮（PopScope 通知在 post-frame 派发，
    // 需要两帧：第一帧派发拦截回调，第二帧完成整页 Hero 重包裹）
    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pump();
    await tester.pump();
    // 被 PopScope 拦截：整页 Hero 已重新包裹（页面树出现第二个同 tag Hero）
    final heroes = find.byWidgetPredicate((w) => w is Hero && w.tag == _tag);
    expect(heroes.evaluate().length, 2,
        reason: '返回按钮应触发 PopScope 拦截并重新包裹整页 Hero');

    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
    expect(find.byType(ArticlePage), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('blur OFF: 回落到经典 MaterialPageRoute，push/pop 无异常', (
    tester,
  ) async {
    SettingsService.heroTransitionBlurEnabled = false;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app());
    final ctx = tester.element(find.byType(Scaffold));
    Navigator.of(ctx).push(
      heroTransitionRoute(
        heroZoom: true,
        page: const ArticlePage(cvid: 12345678, heroTag: _tag, coverUrl: ''),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final pushedScaffold = tester.element(find.byType(Scaffold).last);
    final route = ModalRoute.of(pushedScaffold);
    expect(route, isNotNull);
    expect(route.runtimeType, MaterialPageRoute,
        reason: '关闭模糊后应使用标准 MaterialPageRoute');

    Navigator.of(ctx).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
    expect(find.byType(ArticlePage), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
