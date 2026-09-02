// 回归测试：退出视频页（pop 返回）时，被覆盖页（搜索页）保留
// iOS 景深回落动画，同时飞行精确落回卡片（无结尾位移）。
//
// 缺陷背景：Hero 飞行在弹栈第一帧渲染结束后才测量目标矩形
// （_HeroFlightManifest 捕获 toHeroLocation，且尺寸只捕获一次）。
// 若此刻背景已缩到 0.90，测到的卡片尺寸偏小，飞行终点与卡片真实
// 位置不一致，缩回动画结尾会出现可见位移。修复：弹栈首帧
// （driving > 0.95，即飞行测量帧）背景保持 1.0，之后恢复 0.90→1.0
// 的景深回落动画。
//
// 断言方式（直接 pop + 始终包裹的整页 Hero，飞行可稳定观测）：
//  - 退出转场中段，被覆盖页有景深回落动画（内容向中心收缩，左上角
//    偏离 (0,0)）；
//  - 退出转场最后一帧，飞行 shuttle 矩形与卡片矩形基本重合（<3px），
//    证明缩回动画终点与卡片真实位置一致（无结尾位移）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tag = 'bili_video_BV1xx411c7mD';
const _cardKey = ValueKey('search-card-hero');

/// 搜索页等价结构：IosBackdropScale 包裹 + 卡片 Hero 源。
/// 卡片不居中（偏下），让飞行路径足够长、落点偏差可测。
class _SearchLike extends StatelessWidget {
  const _SearchLike();

  @override
  Widget build(BuildContext context) {
    return IosBackdropScale(
      child: Scaffold(
        body: Align(
          alignment: const Alignment(0, 0.4),
          child: Hero(
            tag: _tag,
            child: const SizedBox(key: _cardKey, width: 120, height: 68),
          ),
        ),
      ),
    );
  }
}

/// 被推入的「视频页」等价页：整页 Hero 始终包裹（无 PopScope 重包裹），
/// pop 可直接观测飞行。
class _VideoLike extends StatelessWidget {
  const _VideoLike();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Hero(tag: _tag, child: SizedBox.expand()),
      ),
    );
  }
}

/// 飞行 overlay 的矩形：Hero 飞行条目 = Positioned(四边齐全) > IgnorePointer。
Rect? _flightRect(WidgetTester t) {
  Rect? best;
  for (final e in find.byType(Positioned, skipOffstage: false).evaluate()) {
    final p = e.widget as Positioned;
    if (p.top == null ||
        p.left == null ||
        p.right == null ||
        p.bottom == null) {
      continue;
    }
    if (p.child is! IgnorePointer) continue;
    final render = e.renderObject;
    if (render is! RenderBox || !render.hasSize || !render.attached) continue;
    final rect = render.localToGlobal(Offset.zero) & render.size;
    if (!rect.isFinite || rect.isEmpty) continue;
    best = rect;
  }
  return best;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NetworkSettingsService().initialize();
    SettingsService.heroTransitionBlurEnabled = true;
  });

  testWidgets('退出时背景有景深回落动画，飞行精确落回卡片', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _SearchLike(),
      ),
    );
    final nav = Navigator.of(tester.element(find.byType(Scaffold).first));

    // 推入视频页（整页 Hero 放大）
    nav.push(heroTransitionRoute(heroZoom: true, page: const _VideoLike()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);

    // 返回：直接 pop（整页 Hero 始终包裹，飞行可观测）
    nav.pop();
    await tester.pump();

    // 弹栈首帧（Hero 飞行测量目标矩形的那一帧）：背景保持 1.0
    // （captureFrame 抑制），保证飞行按卡片最终比例捕获目标矩形。
    final firstTopLeft = tester.getTopLeft(find.byType(Scaffold).first);
    expect(
      (firstTopLeft - Offset.zero).distance,
      lessThan(0.5),
      reason: '弹栈首帧背景应保持原尺寸（飞行测量帧），实测左上角 $firstTopLeft',
    );
    await tester.pump();

    // 退出转场中段：背景恢复 iOS 景深回落动画（从覆盖态向中心收缩的
    // 比例平滑放大回 1.0）—— 只有「弹栈首帧」保持 1.0，之后缩放照常。
    await tester.pump(const Duration(milliseconds: 150));
    final midTopLeft = tester.getTopLeft(find.byType(Scaffold).first);
    expect(
      (midTopLeft - Offset.zero).distance,
      greaterThan(1),
      reason:
          '退出视频页时背景应有景深回落动画（内容向中心收缩后放大），'
          '实测左上角 $midTopLeft',
    );

    // 持续推帧直到飞行结束，记录最后一帧的飞行矩形
    Rect? lastFlight;
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: 'pop 第 $i 帧异常');
      final r = _flightRect(tester);
      if (r != null) lastFlight = r;
    }

    // 退出结束：背景恢复全尺寸，视频页已移除，卡片原位可见
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.byType(Scaffold).first),
      Offset.zero,
      reason: 'pop 结束后背景应恢复原比例',
    );
    expect(find.byType(_VideoLike), findsNothing);

    // 飞行最后一帧的矩形应与卡片矩形基本重合。
    // - 尺寸偏差 < 3px：捕获帧背景 1.0 → 飞行终点尺寸 = 卡片真实尺寸
    //   （旧缺陷：捕获时背景 0.90，终点尺寸偏小 ~10%）；
    // - 中心偏差 < 8px：最后观测帧通常早于动画完全结束，且背景回落
    //   尚未归零，onTick 跟踪的终点还有微小残差（伪影，非真实位移）。
    final cardRect = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 120 && w.height == 68,
      ),
    );
    expect(lastFlight, isNotNull, reason: 'pop 期间应观察到飞行 shuttle');
    final residualCenter = (lastFlight!.center - cardRect.center).distance;
    final residualWidth = (lastFlight!.width - cardRect.width).abs();
    final residualHeight = (lastFlight!.height - cardRect.height).abs();
    expect(
      residualCenter,
      lessThan(8),
      reason: '缩回动画终点中心应与卡片一致，实测偏差 ${residualCenter.toStringAsFixed(2)}px',
    );
    expect(
      residualWidth < 3 && residualHeight < 3,
      isTrue,
      reason:
          '缩回动画终点尺寸应与卡片一致（捕获帧背景缩放会导致终点'
          '尺寸偏小 ~10%），实测偏差 '
          '${residualWidth.toStringAsFixed(2)}x${residualHeight.toStringAsFixed(2)}',
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('打断 push（中途 pop）：背景平滑回落、无跳变，飞行精确落回卡片', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _SearchLike(),
      ),
    );
    final nav = Navigator.of(tester.element(find.byType(Scaffold).first));

    // 推入视频页，只推进到中段（250ms，背景缩到 ~0.94）
    nav.push(heroTransitionRoute(heroZoom: true, page: const _VideoLike()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);

    // 打断：push 中段直接 pop → 飞行 divert 反向滑回卡片
    nav.pop();
    await tester.pump();
    final firstTopLeft = tester.getTopLeft(find.byType(Scaffold).first);
    expect(
      (firstTopLeft - Offset.zero).distance,
      greaterThan(1),
      reason: '打断瞬间背景应保持缩放态（不跳回 1.0），实测左上角 $firstTopLeft',
    );

    // 逐帧推进：背景应平滑回落（相邻帧位移小），不允许瞬间跳变
    // （旧实现打断时背景会瞬间跳回 1.0，一帧位移 ~27px）。
    Rect? lastFlight;
    var prevTopLeft = firstTopLeft;
    for (var i = 0; i < 28; i++) {
      await tester.pump(const Duration(milliseconds: 25));
      expect(tester.takeException(), isNull, reason: '打断 pop 第 $i 帧异常');
      final cur = tester.getTopLeft(find.byType(Scaffold).first);
      final step = (cur - prevTopLeft).distance;
      expect(step, lessThan(10), reason: '打断后背景应平滑回落（无跳变），第 $i 帧位移 $step px');
      prevTopLeft = cur;
      final r = _flightRect(tester);
      if (r != null) lastFlight = r;
    }

    // 结束状态：视频页移除、背景归位、卡片原位
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.byType(Scaffold).first),
      Offset.zero,
      reason: '打断结束后背景应恢复原比例',
    );
    expect(find.byType(_VideoLike), findsNothing);

    // 落点：飞行终点尺寸 = 卡片真实尺寸（<3px，无捕获偏差）
    final cardRect = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 120 && w.height == 68,
      ),
    );
    expect(lastFlight, isNotNull, reason: '打断 pop 期间应观察到飞行 shuttle');
    final residualCenter = (lastFlight!.center - cardRect.center).distance;
    final residualWidth = (lastFlight!.width - cardRect.width).abs();
    final residualHeight = (lastFlight!.height - cardRect.height).abs();
    expect(
      residualCenter,
      lessThan(8),
      reason:
          '打断后缩回动画终点中心应与卡片一致，实测偏差 '
          '${residualCenter.toStringAsFixed(2)}px',
    );
    expect(
      residualWidth < 3 && residualHeight < 3,
      isTrue,
      reason:
          '打断后缩回动画终点尺寸应与卡片一致（捕获偏差 ~10%），'
          '实测 ${residualWidth.toStringAsFixed(2)}x${residualHeight.toStringAsFixed(2)}',
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('入场接近完成时打断：卡片尺寸保持连续，不闪回完整尺寸', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _SearchLike(),
      ),
    );
    final nav = Navigator.of(tester.element(find.byType(Scaffold).first));
    nav.push(
      FrostedHeroRoute(
        heroZoom: true,
        transitionDuration: const Duration(seconds: 5),
        page: const _VideoLike(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4980));

    final before = tester.getRect(find.byKey(_cardKey, skipOffstage: false));
    expect(before.width, lessThan(115));

    // 仍在入场飞行中就返回：不能把背景首帧误当成完整 pop，
    // 否则卡片会先闪回 120px，再继续缩回。
    nav.pop();
    await tester.pump(const Duration(milliseconds: 1));
    final after = tester.getRect(find.byKey(_cardKey, skipOffstage: false));
    expect(
      (after.width - before.width).abs(),
      lessThan(1),
      reason: '入场中断后卡片宽度不应首帧跳变：$before -> $after',
    );

    await tester.pumpWidget(const SizedBox());
  });
}
