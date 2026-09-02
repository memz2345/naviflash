// 回归测试：进入时，被覆盖背景页（含卡片）整体渐隐为半透明；
// 退出（弹栈）时同样渐隐半透明后恢复（iOS 景深，与进入对称）。
// 仅弹栈首帧（Hero 飞行测量目标矩形的那一帧）保持不透明，保证
// 缩回动画落点精确、结尾无位移。对应 IosBackdropScale。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tag = 'demo_card';

/// 被覆盖页：IosBackdropScale 包裹整页（含卡片）。
class _SearchLike extends StatelessWidget {
  const _SearchLike();

  @override
  Widget build(BuildContext context) {
    return IosBackdropScale(
      child: Scaffold(
        backgroundColor: const Color(0xFF222222),
        body: Center(
          child: Hero(tag: _tag, child: const SizedBox(width: 120, height: 68)),
        ),
      ),
    );
  }
}

/// 被推入的「视频页」等价页：整卡 Hero 放大，驱动 backdropProgress。
class _VideoLike extends StatelessWidget {
  const _VideoLike();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Hero(
          tag: _tag,
          child: FlutterLogo(size: 200),
        ),
      ),
    );
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NetworkSettingsService().initialize();
    SettingsService.heroTransitionBlurEnabled = true;
  });

  testWidgets('进入时背景渐隐半透明，退出时恢复不透明', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: const _SearchLike()),
    );
    final nav = Navigator.of(tester.element(find.byType(Scaffold).first));

    double bgOpacity(WidgetTester t) {
      var last = 1.0;
      final scale = find.byType(IosBackdropScale, skipOffstage: false);
      if (scale.evaluate().isEmpty) return 1.0;
      for (final o in t.widgetList<Opacity>(find.descendant(
        of: scale.first,
        matching: find.byType(Opacity),
        skipOffstage: false,
      ))) {
        if (o.opacity < last) last = o.opacity;
      }
      return last;
    }

    // 转场前背景不透明
    expect(bgOpacity(tester), greaterThan(0.95), reason: '初始背景应不透明');

    // 进入：卡片飞行中段，背景明显渐隐半透明
    nav.push(
      heroTransitionRoute(
        heroZoom: true,
        page: const _VideoLike(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.takeException(), isNull);
    final midEnter = bgOpacity(tester);
    expect(
      midEnter,
      lessThan(0.6),
      reason: '进入卡片飞行时应让背景（含卡片）渐隐半透明，实测 $midEnter',
    );

    // 进入转场完成：背景恢复不透明
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(
      bgOpacity(tester),
      greaterThan(0.95),
      reason: '进入转场完成后背景应恢复清晰',
    );

    // 退出：卡片飞回。弹栈中段背景再次渐隐半透明（iOS 景深回落，
    // 与进入对称）；只有弹栈首帧（飞行测量目标矩形的那一帧）保持
    // 不透明以保证落点精确。
    nav.pop();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);
    final midExit = bgOpacity(tester);
    expect(
      midExit,
      lessThan(0.95),
      reason: '退出卡片飞行期间背景应再次渐隐半透明（与进入对称），实测 $midExit',
    );

    // 退出完成：背景恢复完全不透明
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(bgOpacity(tester), greaterThan(0.95),
        reason: '退出转场完成后背景应恢复完全不透明');

    await tester.pumpWidget(const SizedBox());
  });
}
