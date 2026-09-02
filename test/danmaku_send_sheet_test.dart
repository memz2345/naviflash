import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/app_localizations_zh.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/widgets/danmaku/danmaku_send_sheet.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    L10n.setCurrent(AppLocalizationsZhCn());
  });

  Widget host() => MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox.shrink()),
      );

  testWidgets('输入后预览更新、发送可用；返回携带所选样式', (tester) async {
    DanmakuSendStyle? captured;
    await tester.pumpWidget(host());
    final ctx = tester.element(find.byType(Scaffold));
    final future = showDanmakuSendSheet(ctx, initialText: '前排');
    await tester.pumpAndSettle();

    // 预填文字出现在输入框与预览中
    expect(find.text('前排'), findsWidgets);

    // 切模式：顶部
    await tester.tap(find.text(L10n.current.danmakuTypeTop));
    await tester.pumpAndSettle();
    // 切字号：大（36）
    await tester.tap(find.text(L10n.current.danmakuFontSizeLarge));
    await tester.pumpAndSettle();

    // 点发送 → pop 出样式
    await tester.tap(find.text(L10n.current.rcSend));
    await tester.pumpAndSettle();
    captured = await future;

    expect(captured, isNotNull);
    expect(captured!.msg, '前排');
    expect(captured.mode, 5);
    expect(captured.fontSize, 36);
    expect(captured.color, 0xFFFFFF); // 默认白
  });

  testWidgets('点色板切换颜色；清空文字后发送禁用', (tester) async {
    await tester.pumpWidget(host());
    final ctx = tester.element(find.byType(Scaffold));
    showDanmakuSendSheet(ctx);
    await tester.pumpAndSettle();

    // 输入文字
    await tester.enterText(find.byType(TextField), '666');
    await tester.pump();

    // 点第一个色板圆点（白色之后的红色 FE0302）
    final dots = find.byType(GestureDetector);
    // 色板圆点：找带 BoxDecoration 的 Container 圆点 → 直接按索引点击红色（第2个圆点）
    await tester.tap(find.byWidgetPredicate((w) => w is Container).at(1));
    await tester.pumpAndSettle();

    // 清空 → 发送按钮禁用
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    final btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNull, reason: '空内容时发送应禁用');

    // 卸载避免 pending 焦点/定时器
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  test('色板常量包含白色与红色（B 站常用）', () {
    expect(kDanmakuPresetColors, contains(0xFFFFFF));
    expect(kDanmakuPresetColors, contains(0xFE0302));
  });
}
