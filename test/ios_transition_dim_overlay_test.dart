// 回归测试：iOS 转场观感的两条分工线。
//
//  - 整页 Hero 转场（FrostedHeroRoute，打开视频 / 番剧 / 专栏等）：
//    背景随转场进度实时模糊（BackdropFilter，iOS 卡片展开失焦），
//    转场结束模糊层移除；
//  - 全局 iOS push 转场（IosPushPageTransitionsBuilder，普通页面切换）：
//    旧页面不用模糊（逐帧重光栅化背景，长列表上掉帧），改为盖一层
//    纯半透明黑色（ColoredBox）逐渐变暗，pop 时反向渐亮。
//
// 断言方式（轻量等价页，不依赖网络与真实页面）：
//  - 整页 Hero：转场中 BackdropFilter 存在 / 结束后移除，新页面本体不被模糊；
//  - 全局 push：全程无 BackdropFilter / ImageFiltered（谁把模糊加回去
//    这里立刻红），黑遮罩随进度递增 / pop 递减，峰值不超过上限。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_push_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tag = 'dim_overlay_hero_tag';

/// 源页面：卡片 Hero（模拟列表卡片，只包封面）。
class _SourcePage extends StatelessWidget {
  const _SourcePage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Align(
        alignment: Alignment(0, 0.4),
        child: Hero(
          tag: _tag,
          child: ColoredBox(
            color: Colors.blue,
            child: SizedBox(width: 120, height: 68),
          ),
        ),
      ),
    );
  }
}

/// 目标页面：整页 Hero（iOS 开 App 式放大）。
class _TargetPage extends StatelessWidget {
  const _TargetPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.amber,
      body: Center(child: Hero(tag: _tag, child: SizedBox.expand())),
    );
  }
}

/// 普通页面（无 IosBackdropScale），用于验证全局 iOS push 转场的旧页面遮罩。
class _PlainPage extends StatelessWidget {
  const _PlainPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

/// 转场遮罩（纯黑半透明 ColoredBox）的当前不透明度；不存在时返回 null。
double? _dimOpacity(WidgetTester t) {
  double? found;
  for (final w in t.widgetList<ColoredBox>(
    find.byType(ColoredBox, skipOffstage: false),
  )) {
    final c = w.color;
    // 遮罩特征：纯黑 + 半透明（不透明黑 / 其它颜色都不是转场遮罩）
    if (c.r != 0 || c.g != 0 || c.b != 0) continue;
    if (c.a <= 0 || c.a >= 1) continue;
    found = c.a;
  }
  return found;
}

/// 断言：此刻转场中不存在任何模糊层。
void _expectNoBlur(WidgetTester t, String stage) {
  expect(
    find.byType(BackdropFilter, skipOffstage: false),
    findsNothing,
    reason: '$stage 不应再使用 BackdropFilter（转场模糊已移除，改为黑遮罩）',
  );
  expect(
    find.byType(ImageFiltered, skipOffstage: false),
    findsNothing,
    reason: '$stage 不应再使用 ImageFiltered（转场模糊已移除，改为黑遮罩）',
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NetworkSettingsService().initialize();
    SettingsService.heroTransitionBlurEnabled = true;
  });

  testWidgets('整页 Hero 转场：背景随进度模糊，转场结束后模糊层移除', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: _SourcePage()));
    final nav = Navigator.of(tester.element(find.byType(Scaffold).first));

    // ── push：背景模糊层（BackdropFilter）应随转场挂载 ──
    // 注意 sigma 曲线 0 → 峰值 → 0，且 sigma <= 0.5 时层不挂载：
    // 起始帧（progress ≈ 0）没有模糊层属正常，从第二帧起必须存在。
    nav.push(heroTransitionRoute(heroZoom: true, page: const _TargetPage()));
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: 'push 第 $i 帧异常');
      expect(
        find.byType(BackdropFilter, skipOffstage: false),
        findsOneWidget,
        reason: 'push 第 $i 帧：打开视频时背景应处于模糊失焦状态',
      );
      // heroZoom 模式：新页面本体（整页 Hero）不参与模糊
      expect(
        find.byType(ImageFiltered, skipOffstage: false),
        findsNothing,
        reason: 'push 第 $i 帧：整页 Hero 转场的新页面不应被模糊',
      );
    }

    // 转场结束：模糊层移除，无残留渲染开销
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    expect(
      find.byType(BackdropFilter, skipOffstage: false),
      findsNothing,
      reason: '转场结束后模糊层应移除',
    );

    // ── pop：返回转场期间背景模糊恢复，结束后再次移除 ──
    nav.pop();
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: 'pop 第 $i 帧异常');
      expect(
        find.byType(BackdropFilter, skipOffstage: false),
        findsOneWidget,
        reason: 'pop 第 $i 帧：返回时背景应保持模糊失焦',
      );
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(
      find.byType(BackdropFilter, skipOffstage: false),
      findsNothing,
      reason: '返回结束后模糊层应移除',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('全局 iOS push 转场：旧页面盖黑遮罩逐渐变暗，且无模糊层', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 与 main.dart 一致：把 iOS 风格转场配置到 pageTransitionsTheme
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              for (final p in TargetPlatform.values)
                p: const IosPushPageTransitionsBuilder(),
            },
          ),
        ),
        // 源页面根节点不用 IosBackdropScale：那会接管退场动画，
        // 全局转场会主动让位（见 hasCustomSecondary）。
        home: const _PlainPage(label: 'source'),
      ),
    );
    final nav = Navigator.of(tester.element(find.byType(Scaffold).first));

    nav.push(MaterialPageRoute(builder: (_) => const _PlainPage(label: 'next')));
    await tester.pump();
    final alphas = <double>[];
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull, reason: 'push 第 $i 帧异常');
      _expectNoBlur(tester, 'push 第 $i 帧');
      final dim = _dimOpacity(tester);
      if (dim != null) alphas.add(dim);
    }
    expect(alphas.length, greaterThan(3), reason: '旧页面应被黑色遮罩逐渐压暗');
    expect(
      alphas.last,
      greaterThan(alphas.first),
      reason: '旧页面遮罩应随覆盖进度递增，实测 $alphas',
    );
    expect(
      alphas.last,
      lessThanOrEqualTo(kIosPushDimOpacity + 0.001),
      reason: '遮罩峰值不应超过设定上限 $kIosPushDimOpacity',
    );

    // 转场结束：旧页面停在「被覆盖」态，遮罩保持峰值（视觉上被新页面
    // 完全遮挡，且旧页面不再绘制）。
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(
      _dimOpacity(tester),
      closeTo(kIosPushDimOpacity, 0.02),
      reason: '旧页面遮罩峰值应为设定值 $kIosPushDimOpacity',
    );

    // ── pop 返回：旧页面遮罩应随进度回落，结束后完全移除 ──
    nav.pop();
    await tester.pump();
    final popAlphas = <double>[];
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull, reason: 'pop 第 $i 帧异常');
      _expectNoBlur(tester, 'pop 第 $i 帧');
      final dim = _dimOpacity(tester);
      if (dim != null) popAlphas.add(dim);
    }
    expect(popAlphas.length, greaterThan(3), reason: '返回期间应观察到遮罩回落');
    expect(
      popAlphas.last,
      lessThan(popAlphas.first),
      reason: '返回时旧页面遮罩应逐渐变亮回落，实测 $popAlphas',
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(_dimOpacity(tester), isNull, reason: '返回结束后旧页面遮罩应完全移除');
    await tester.pumpWidget(const SizedBox());
  });
}
