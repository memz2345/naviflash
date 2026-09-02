// 回归测试：从视频页返回搜索页时，搜索框焦点不恢复（虚拟键盘不再弹出）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tag = 'bili_video_BV1xx411c7mD';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NetworkSettingsService().initialize();
    SettingsService.heroTransitionBlurEnabled = true;
  });

  testWidgets('打开视频页前清除焦点 → 返回后搜索框无焦点', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: focusNode, autofocus: true),
              Hero(
                tag: _tag,
                child: const SizedBox(width: 120, height: 68),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(focusNode.hasFocus, isTrue, reason: 'autofocus 生效（键盘打开）');

    final ctx = tester.element(find.byType(Scaffold));
    // 模拟点击视频卡片：openBilibiliVideo 内部会先收起键盘/清除焦点
    openBilibiliVideo(ctx, bvid: 'BV1xx411c7mD', heroTag: _tag);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(focusNode.hasFocus, isFalse, reason: '打开视频页后焦点应被清除');

    Navigator.of(ctx).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(focusNode.hasFocus, isFalse,
        reason: '返回搜索页后焦点不应恢复（否则虚拟键盘弹出）');

    await tester.pumpWidget(const SizedBox());
  });
}
