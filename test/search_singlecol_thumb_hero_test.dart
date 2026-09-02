// 回归测试：搜索页「单列」视频卡片 —— Hero 只包裹封面缩略图，
// 不包裹整行 ListTile 卡片。
//
// 历史缺陷：单列卡片把整个 ListTile 行作为 Hero 源，pop 返回时飞行
// shuttle 在 Navigator overlay 中重建 —— 那里没有 Material 祖先，
// ListTile 触发「No Material widget found」断言（退出报错）；且整行
// 宽高比（约 4:1）飞向竖屏视频页严重拉伸变形。
//
// 断言：
//  1. 结构：视频行 ListTile 的 Hero 只包含缩略图（不包含 ListTile /
//     Material —— 与用户空间单列列表同款）；
//  2. 行为：push 进入 / pop 返回全程无异常（缩略图不需要 Material）；
//  3. 落点：pop 飞行最后一帧的矩形与缩略图矩形基本重合（<3px）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tag = 'bili_video_BV1xx411c7mD';

/// 模拟搜索页单列卡片（修复后的结构）：缩略图作为 Hero 源，
/// 整行 ListTile 不参与 Hero。
class _SingleColCard extends StatelessWidget {
  const _SingleColCard();

  @override
  Widget build(BuildContext context) {
    final thumb = Hero(
      tag: _tag,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
      child: Container(
        width: 96,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: thumb,
      title: const Text('单列视频标题', maxLines: 2),
      subtitle: const Text('UP主 · 1234播放'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
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
    if (p.top == null || p.left == null || p.right == null || p.bottom == null) {
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

  testWidgets('单列卡片 Hero 只包缩略图，push/pop 全程无异常且精确落回缩略图',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: IosBackdropScale(
          child: Scaffold(
            body: Align(
              alignment: const Alignment(0, 0.4),
              child: SizedBox(width: 360, child: _SingleColCard()),
            ),
          ),
        ),
      ),
    );

    // 结构断言：视频行 Hero 只包含缩略图，不包含 ListTile / Material
    var thumbHeroFound = false;
    for (final e in find.byType(Hero, skipOffstage: false).evaluate()) {
      final hero = e.widget as Hero;
      if (hero.tag != _tag) continue;
      final child = hero.child;
      expect(
        child is ListTile || child is Material,
        isFalse,
        reason: '单列卡片 Hero 不应包裹整个 ListTile/Material（否则飞行层'
            '无 Material 祖先会断言报错、整行拉伸变形）',
      );
      thumbHeroFound = true;
    }
    expect(thumbHeroFound, isTrue, reason: '单列卡片应存在缩略图 Hero');

    final nav = Navigator.of(tester.element(find.byType(Scaffold).first));

    // push 进入视频页：整页 Hero 放大，全程无异常
    nav.push(
      heroTransitionRoute(heroZoom: true, page: const _VideoLike()),
    );
    await tester.pump();
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: 'push 第 $i 帧异常');
    }
    expect(find.byType(_VideoLike), findsOneWidget);

    // pop 返回：飞行 shuttle 重建缩略图（无 Material 断言），全程无异常
    nav.pop();
    await tester.pump();
    await tester.pump();
    Rect? lastFlight;
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull,
          reason: 'pop 第 $i 帧异常（单列缩略图 Hero 不应触发 Material 断言）');
      final r = _flightRect(tester);
      if (r != null) lastFlight = r;
    }
    expect(find.byType(_VideoLike), findsNothing);
    expect(tester.takeException(), isNull);

    // 落点断言：飞行最后一帧矩形 ≈ 缩略图矩形。
    // - 尺寸偏差 < 3px：捕获帧背景 1.0 → 飞行终点尺寸 = 缩略图真实尺寸
    //   （旧缺陷：捕获时背景 0.90，终点尺寸偏小 ~10%）；
    // - 中心偏差 < 8px：最后观测帧早于动画完全结束，背景回落未归零，
    //   onTick 跟踪的终点还有微小残差（伪影，非真实位移）。
    final thumbRect = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxWidth == 96,
      ),
    );
    expect(lastFlight, isNotNull, reason: 'pop 期间应观察到飞行 shuttle');
    final residualCenter = (lastFlight!.center - thumbRect.center).distance;
    final residualWidth = (lastFlight!.width - thumbRect.width).abs();
    final residualHeight = (lastFlight!.height - thumbRect.height).abs();
    expect(
      residualCenter,
      lessThan(8),
      reason: '缩回动画终点中心应与缩略图一致，实测偏差 '
          '${residualCenter.toStringAsFixed(2)}px',
    );
    expect(
      residualWidth < 3 && residualHeight < 3,
      isTrue,
      reason: '缩回动画终点尺寸应与缩略图一致（捕获帧背景缩放会导致终点'
          '尺寸偏小 ~10%），实测偏差 '
          '${residualWidth.toStringAsFixed(2)}x${residualHeight.toStringAsFixed(2)}',
    );

    await tester.pumpWidget(const SizedBox());
  });
}
