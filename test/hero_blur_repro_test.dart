// 回归测试：搜索卡片 → BilibiliVideoPage 的 Hero 转场（开启「Hero 转场背景模糊」）。
//
// 覆盖两类历史缺陷：
//  1. 搜索页同一视频出现两次（分页重复）→ 同名 Hero tag 重复 → 转场飞行中断；
//  2. 视频页整页 Hero 内嵌套内层 Hero（相关视频/评论配图）→ Flutter 断言报错。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tag = 'bili_video_BV1xx411c7mD';

Widget _app() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        // 模拟搜索卡片：图片 + 标题文字（整张卡片参与 Hero 飞行）
        child: Hero(
          tag: _tag,
          child: Container(
            width: 120,
            height: 90,
            color: Colors.black12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: ColoredBox(color: Colors.red),
                ),
                const SizedBox(height: 4),
                Text(
                  'TITLE',
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

  testWidgets('blur ON: push 进入视频页并 pop 返回卡片，全程无异常', (tester) async {
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
        page: const BilibiliVideoPage(bvid: 'BV1xx411c7mD', heroTag: _tag),
      ),
    );
    // 推进转场（320ms）+ 余量，逐帧检查异常
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull,
          reason: 'push 转场第 $i 帧出现异常');
    }
    // 页面应在转场结束后正常显示
    expect(find.byType(BilibiliVideoPage), findsOneWidget);

    Navigator.of(ctx).pop();
    var sawCardText = false;
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull,
          reason: 'pop 转场第 $i 帧出现异常');
      // pop 转场的 shuttle 应渲染整张卡片（图片 + 标题文字一起运动）
      if (find.text('TITLE').evaluate().isNotEmpty) sawCardText = true;
    }
    expect(sawCardText, isTrue,
        reason: 'pop 转场应渲染整张卡片（含标题文字）一起运动');
    expect(find.byType(BilibiliVideoPage), findsNothing);

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
        page: const BilibiliVideoPage(bvid: 'BV1xx411c7mD', heroTag: _tag),
      ),
    );
    // 入场转场完成 → 整页 Hero 已被移除（_zoomHeroActive=false）
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // 点击封面左上角返回按钮（PopScope 通知在 post-frame 派发，
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
    expect(find.byType(BilibiliVideoPage), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('搜索页同名 tag 重复出现时转场飞行中断（缺陷场景，禁止回归）',
      (tester) async {
    // 模拟「同一视频在同一列表出现两次」：两个同名 Hero。
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              Hero(
                tag: _tag,
                child: const SizedBox(
                  width: 120,
                  height: 68,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
              Hero(
                tag: _tag,
                child: const SizedBox(
                  width: 120,
                  height: 68,
                  child: ColoredBox(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final ctx = tester.element(find.byType(Scaffold));
    Navigator.of(ctx).push(
      heroTransitionRoute(
        heroZoom: true,
        page: const BilibiliVideoPage(bvid: 'BV1xx411c7mD', heroTag: _tag),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // Flutter 框架会抛出「multiple heroes share the same tag」——
    // 这正是搜索列表未去重时的表现；生产代码已在 _loadType 去重，
    // 此用例用于守护该约束。
    final e = tester.takeException();
    expect(e, isNotNull);
    expect(e.toString(), contains('multiple heroes'));

    await tester.pumpWidget(const SizedBox());
  });
}
