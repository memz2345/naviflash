import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/app_localizations_zh.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/widgets/danmaku/danmaku_controller.dart';
import 'package:naviflash/widgets/danmaku/danmaku_list_sheet.dart';
import 'package:naviflash/widgets/danmaku/danmaku_model.dart';

void main() {
  // 弹幕列表弹层的断言文案走 L10n.current（与运行时回退一致）
  L10n.setCurrent(AppLocalizationsZhCn());

  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      );

  DanmakuController buildController() {
    final c = DanmakuController();
    c.setItems(const [
      DanmakuItem(
        time: 1.0,
        mode: DanmakuMode.scrollRightToLeft,
        fontSize: 25,
        color: Color(0xFFFFFFFF),
        content: '第一条弹幕',
      ),
      DanmakuItem(
        time: 63.0,
        mode: DanmakuMode.top,
        fontSize: 25,
        color: Color(0xFFFF0000),
        content: '红色顶部弹幕',
      ),
      DanmakuItem(
        time: 100.0,
        mode: DanmakuMode.advanced,
        fontSize: 25,
        color: Color(0xFFFFFFFF),
        content: '[{"bas":1}]',
      ),
    ]);
    return c;
  }

  testWidgets('弹幕列表渲染普通弹幕并排除高级弹幕，点击回调 seek 秒数',
      (tester) async {
    final seeks = <double>[];
    await tester.pumpWidget(wrap(
      DanmakuListSheet(
        controller: buildController(),
        onSeek: seeks.add,
        currentPosition: () => 0,
      ),
    ));
    await tester.pumpAndSettle();

    // 高级弹幕不出现在列表
    expect(find.text('第一条弹幕'), findsOneWidget);
    expect(find.text('红色顶部弹幕'), findsOneWidget);
    expect(find.textContaining('bas'), findsNothing);

    // 时间戳格式 mm:ss
    expect(find.text('1:03'), findsOneWidget);

    await tester.tap(find.text('红色顶部弹幕'));
    await tester.pumpAndSettle();
    expect(seeks, [63.0]);
  });

  testWidgets('搜索过滤后只显示匹配弹幕', (tester) async {
    await tester.pumpWidget(wrap(
      DanmakuListSheet(
        controller: buildController(),
        onSeek: (_) {},
        currentPosition: () => 0,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '红色');
    await tester.pumpAndSettle();

    expect(find.text('红色顶部弹幕'), findsOneWidget);
    expect(find.text('第一条弹幕'), findsNothing);
  });

  testWidgets('无弹幕时展示空态文案', (tester) async {
    final c = DanmakuController()..setItems(const []);
    await tester.pumpWidget(wrap(
      DanmakuListSheet(
        controller: c,
        onSeek: (_) {},
        currentPosition: () => 0,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text(L10n.current.playerDanmakuListEmpty), findsOneWidget);
  });
}
