// 最小回归：被覆盖页的 IosBackdropScale（secondaryAnimation 驱动）重建后，
// Transform.scale 真实应用到渲染（内容盒 global 左上角向屏幕中心移动）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';

void main() {
  testWidgets('覆盖后 secondaryAnimation 驱动缩放并真实渲染', (tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IosBackdropScale(
            child: const Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 120,
                height: 80,
                child: ColoredBox(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
    final box = find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == Colors.red,
    );
    final before = tester.getTopLeft(box);
    debugPrint('before: $before');
    expect(before, Offset.zero);

    final nav = Navigator.of(tester.element(find.byType(Scaffold)));
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: ColoredBox(color: Colors.blue)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 50));
    final mid = tester.getTopLeft(box);
    debugPrint('mid: $mid');
    // 页面以屏幕中心为锚缩小（叠加平台默认的覆盖页过渡变换）：
    // 左上角的盒子应产生位移，证明缩放真实渲染
    expect(
      (mid - before).distance > 1,
      isTrue,
      reason: '被覆盖页内容应真实向中心收缩（$mid）',
    );

    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getTopLeft(box), Offset.zero, reason: '返回后应恢复原比例');

    await tester.pumpWidget(const SizedBox());
  });
}
