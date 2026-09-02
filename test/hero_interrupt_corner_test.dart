// 回归测试：打断动画时，飞行卡片的圆角仍随内容缩放、不会消失。
// 内容 ClipRRect 位于 FittedBox 内部随页面一起缩放，飞行边界另由外层
// ClipRRect 裁剪，避免 cover 溢出破坏卡片圆角。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tag = 'bili_video_BV1xx411c7mD';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NetworkSettingsService().initialize();
    SettingsService.heroTransitionBlurEnabled = true;
  });

  testWidgets('打断时飞行卡片圆角 ClipRRect 在缩放内部（不会消失）', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: Hero(
              tag: _tag,
              child: Container(width: 200, height: 120, color: Colors.red),
            ),
          ),
        ),
      ),
    );
    final nav = Navigator.of(tester.element(find.byType(Scaffold)));

    nav.push(
      heroTransitionRoute(
        heroZoom: true,
        page: const BilibiliVideoPage(bvid: 'BV1xx411c7mD', heroTag: _tag),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);

    // 打断：中途 pop 反向飞行
    nav.pop();
    await tester.pump();

    var sawRoundedInsideFitted = false;
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: '打断 pop 第 $i 帧异常');
      // 内容飞行圆角 ClipRRect（radius=12）应是某个 FittedBox 的后代
      final clip = find.descendant(
        of: find.byType(FittedBox, skipOffstage: false),
        matching: find.byType(ClipRRect),
        skipOffstage: false,
      );
      for (final e in clip.evaluate()) {
        final c = e.widget as ClipRRect;
        final corners =
            (c.borderRadius as BorderRadius?)?.topLeft ??
            BorderRadius.zero.topLeft;
        if ((corners.x - 12).abs() < 0.5) {
          sawRoundedInsideFitted = true;
        }
      }
    }
    expect(
      sawRoundedInsideFitted,
      isTrue,
      reason: '打断反向飞行时，圆角 ClipRRect(12) 应位于 FittedBox 内部并随内容缩放（圆角不消失）',
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
