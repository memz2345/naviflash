import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/widgets/long_press_image_preview.dart';

void main() {
  Widget buildHost() {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: LongPressImagePreview(
            imageUrl: 'https://example.com/preview.png',
            child: Container(
              width: 80,
              height: 80,
              color: Colors.blue,
              child: const Icon(Icons.image),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('长按弹出预览（模糊背景 + 居中大图），松手关闭', (tester) async {
    await tester.pumpWidget(buildHost());

    // 初始无预览
    expect(find.byType(ImageFiltered), findsNothing);

    // 按住超过长按阈值 → 预览浮层出现
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Icon)));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.byType(ImageFiltered), findsOneWidget);

    // 松手 → 预览关闭（飞出动画完成后移除）
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(ImageFiltered), findsNothing);
  });

  testWidgets('长按期间预览持续显示，不会提前消失', (tester) async {
    await tester.pumpWidget(buildHost());
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Icon)));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byType(ImageFiltered), findsOneWidget);

    // 继续按住并等待
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(ImageFiltered), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(ImageFiltered), findsNothing);
  });

  testWidgets('快速点击不会误触预览', (tester) async {
    await tester.pumpWidget(buildHost());
    await tester.tap(find.byType(Icon));
    await tester.pumpAndSettle();
    expect(find.byType(ImageFiltered), findsNothing);
  });

  testWidgets('点按预览背景可直接关闭', (tester) async {
    await tester.pumpWidget(buildHost());
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Icon)));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byType(ImageFiltered), findsOneWidget);

    // 预览打开时点按屏幕中央 → 关闭
    await tester.tapAt(const Offset(100, 100));
    await tester.pumpAndSettle();
    expect(find.byType(ImageFiltered), findsNothing);

    // 原始手势松手不报错
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(ImageFiltered), findsNothing);
  });
}
