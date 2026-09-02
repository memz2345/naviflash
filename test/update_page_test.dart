import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/screens/update_page.dart';

void main() {
  testWidgets('先停留在当前版本，三秒后展示更新卡并可折页进入详情', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: UpdatePage()));
    expect(find.text('Checking…'), findsOneWidget);
    expect(find.text('Download update'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Download update'), findsOneWidget);
    expect(find.text('Tap to view full changelog'), findsOneWidget);

    await tester.tap(find.text('Tap to view full changelog'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    final hasTopDownFlip = tester
        .widgetList<Transform>(find.byType(Transform))
        .any((transform) => transform.transform.entry(1, 2).abs() > 0.01);
    expect(hasTopDownFlip, isTrue, reason: '详情转场应绕卡片底部横轴上下翻页');
    await tester.pumpAndSettle();
    expect(find.text('Update details'), findsOneWidget);
    expect(
      find.text('Connection, playback and sync improvements'),
      findsNothing,
    );
    expect(
      find.textContaining('Improved video loading over carrier networks'),
      findsOneWidget,
    );

    await tester.tap(find.text('Update details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    final hasTopDownReverseFlip = tester
        .widgetList<Transform>(find.byType(Transform))
        .any((transform) => transform.transform.entry(1, 2).abs() > 0.01);
    expect(hasTopDownReverseFlip, isTrue, reason: '返回正面也应绕卡片底部横轴翻页');
    await tester.pumpAndSettle();
    expect(find.text('Tap to view full changelog'), findsOneWidget);

    final pageView = find.byType(PageView);
    await tester.drag(pageView, const Offset(260, 0));
    await tester.pumpAndSettle();
    expect(find.text('Current version'), findsOneWidget);

    await tester.drag(pageView, const Offset(-260, 0));
    await tester.pumpAndSettle();
    expect(find.text('Tap to view full changelog'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
