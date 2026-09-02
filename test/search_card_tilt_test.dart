// 搜索页卡片按压边缘磁贴倾斜（复用 home 磁贴的 MetroTileInteraction）。
// 要求：无描边、保留 ripple、长按/右键菜单正常触发、触发后倾斜状态重置。
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/widgets/MetroTile.dart';

Widget _wrap(WidgetTester tester, {
  bool showBorder = false,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  VoidCallback? onSecondaryTapDown,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: MetroTileInteraction(
          onTapStart: (_, __) {},
          showBorder: showBorder,
          child: GestureDetector(
            onSecondaryTapDown: (_) => onSecondaryTapDown?.call(),
            child: Material(
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                child: const SizedBox(width: 200, height: 120),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

int _tiltCount(WidgetTester tester) {
  return tester
      .widgetList<Transform>(find.byType(Transform))
      .where((t) => t.transform.entry(0, 2).abs() > 0.01)
      .length;
}

bool _hasBorderOverlay(WidgetTester tester) {
  return tester
      .widgetList<Container>(find.byType(Container))
      .any((c) =>
          c.decoration is BoxDecoration &&
          (c.decoration! as BoxDecoration).border != null);
}

void main() {
  testWidgets('按下左缘倾斜，松手恢复，轻点仍触发点击且无描边', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(tester, onTap: () => tapped = true));

    final center = tester.getCenter(find.byType(SizedBox));
    final gesture = await tester.startGesture(center - const Offset(95, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(_tiltCount(tester), greaterThan(0),
        reason: '按压边缘时应产生 Y 轴倾斜');
    expect(_hasBorderOverlay(tester), isFalse,
        reason: 'showBorder=false 时不应出现描边');

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_tiltCount(tester), 0, reason: '松手后倾斜应恢复');
    expect(tapped, isTrue, reason: '轻点仍应触发卡片点击');
  });

  testWidgets('默认 showBorder=true 时按压出现描边（home 磁贴行为不受影响）',
      (tester) async {
    await tester.pumpWidget(_wrap(tester, showBorder: true));
    final center = tester.getCenter(find.byType(SizedBox));
    final gesture = await tester.startGesture(center - const Offset(95, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_hasBorderOverlay(tester), isTrue,
        reason: 'showBorder=true 时应保留描边');
    await gesture.up();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('按住后移动指针，倾斜实时跟随（不再停留在按下位置）', (tester) async {
    await tester.pumpWidget(_wrap(tester));

    final center = tester.getCenter(find.byType(SizedBox));
    // 从卡片中心按下
    final gesture = await tester.startGesture(center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    // 中心按下 → rotateY 分量接近 0
    final rotAtCenter = tester
        .widgetList<Transform>(find.byType(Transform))
        .map((t) => t.transform.entry(0, 2).abs())
        .fold<double>(0, (a, b) => a > b ? a : b);
    expect(rotAtCenter, lessThan(0.03), reason: '中心按下倾斜应接近 0');

    // 按住移动到左边缘（仍在卡片内；分段移动确保更新事件派发）
    await gesture.moveTo(center - const Offset(45, 0));
    await tester.pump();
    await gesture.moveTo(center - const Offset(90, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final rotAtLeft = tester
        .widgetList<Transform>(find.byType(Transform))
        .map((t) => t.transform.entry(0, 2).abs())
        .fold<double>(0, (a, b) => a > b ? a : b);
    expect(rotAtLeft, greaterThan(0.05),
        reason: '移动到左边缘后倾斜应实时跟随变大');

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final residual = tester
        .widgetList<Transform>(find.byType(Transform))
        .where((t) => t.transform.entry(0, 2).abs() > 0.01)
        .length;
    expect(residual, 0, reason: '松手后倾斜应恢复');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('长按菜单正常触发且倾斜状态重置', (tester) async {
    var longPressed = false;
    await tester.pumpWidget(
      _wrap(tester, onLongPress: () => longPressed = true),
    );

    final center = tester.getCenter(find.byType(SizedBox));
    final gesture = await tester.startGesture(center - const Offset(95, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_tiltCount(tester), greaterThan(0));

    // 长按 500ms → InkWell onLongPress 接受，pan 被取消
    await tester.pump(const Duration(milliseconds: 600));
    expect(longPressed, isTrue, reason: '长按菜单应正常触发');
    // 让反向动画（300ms）走完
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_tiltCount(tester), 0, reason: '长按触发后倾斜状态应重置');

    await gesture.up();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('右键菜单正常触发且倾斜状态重置', (tester) async {
    var secondaryDown = false;
    await tester.pumpWidget(
      _wrap(tester, onSecondaryTapDown: () => secondaryDown = true),
    );

    final center = tester.getCenter(find.byType(SizedBox));
    final gesture = await tester.startGesture(
      center,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pump();
    expect(secondaryDown, isTrue, reason: '右键菜单应正常触发');

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_tiltCount(tester), 0, reason: '右键触发后倾斜状态应重置');
    await tester.pumpWidget(const SizedBox());
  });
}
