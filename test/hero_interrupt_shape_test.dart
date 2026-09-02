// 回归测试：iOS 整卡变焦飞行按卡片比例裁剪（BoxFit.cover），
// 避免把竖屏页面压缩进横向卡片；同时裁掉 cover 溢出内容。
// 结构断言：飞行 shuttle 里的 FittedBox 必须是 cover 且启用裁剪。
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

  testWidgets('打断反向飞行时飞行内容按卡片比例裁剪（BoxFit.cover）', (tester) async {
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

    // 打断：中途 pop 反向飞行，期间核对飞行 shuttle 的 FittedBox 拟合方式
    nav.pop();
    await tester.pump();
    var sawCover = false;
    var sawUnclippedCover = false;
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: '打断 pop 第 $i 帧异常');
      for (final f in find.byType(FittedBox, skipOffstage: false).evaluate()) {
        final fb = f.widget as FittedBox;
        if (fb.fit == BoxFit.cover) {
          sawCover = true;
          if (fb.clipBehavior == Clip.none) sawUnclippedCover = true;
        }
      }
    }
    expect(sawCover, isTrue, reason: '飞行内容应使用 BoxFit.cover 按卡片比例裁剪');
    expect(sawUnclippedCover, isFalse, reason: 'BoxFit.cover 的溢出内容必须被裁剪');

    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
