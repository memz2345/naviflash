import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/app_localizations_zh.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/widgets/comment/comment_composer.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePathProvider extends PathProviderPlatform {
  final Directory dir;
  _FakePathProvider(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;

  @override
  Future<String?> getApplicationSupportPath() async => dir.path;

  @override
  Future<String?> getTemporaryPath() async => dir.path;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    L10n.setCurrent(AppLocalizationsZhCn());
  });

  setUp(() async {
    final tmpDir = await Directory.systemTemp.createTemp('navi_composer_test');
    PathProviderPlatform.instance = _FakePathProvider(tmpDir);
    SharedPreferences.setMockInitialValues({});
    await BilibiliAccountService().initialize();
  });

  Widget host(Widget child) => MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      );

  BiliComment fakeComment({
    String rpid = '123',
    String root = '0',
    String uname = '测试用户',
  }) =>
      BiliComment(
        rpid: rpid,
        oid: '1',
        mid: '1',
        root: root,
        parent: '0',
        count: 0,
        like: 0,
        ctime: 0,
        message: '内容',
        emotes: const {},
        pictures: const [],
        member: BiliCommentMember(
          mid: '1',
          uname: uname,
          avatar: '',
          level: 3,
          vipType: 0,
          vipStatus: 0,
          officialType: -1,
        ),
        replies: const [],
      );

  testWidgets('空内容发送按钮禁用；输入后启用', (tester) async {
    await tester.pumpWidget(host(
      Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => showCommentComposer(ctx, oid: 1),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final sendBtn = find.byType(FilledButton);
    expect(sendBtn, findsOneWidget);
    expect(tester.widget<FilledButton>(sendBtn).onPressed, isNull,
        reason: '空内容时发送应禁用');

    await tester.enterText(find.byType(TextField), '写点什么');
    await tester.pump();
    expect(tester.widget<FilledButton>(sendBtn).onPressed, isNotNull,
        reason: '有内容时发送应启用');

    // 收起（dispose 定时器/焦点，避免 pending 状态）
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('回复目标预览显示且可取消；取消后输入提示恢复默认', (tester) async {
    await tester.pumpWidget(host(
      Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () =>
              showCommentComposer(ctx, oid: 1, replyTo: fakeComment()),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 回复预览行 + 带目标的 hint（中文文案相同，两处都渲染）
    expect(find.text(L10n.current.commentComposerReplyTo('测试用户')),
        findsNWidgets(2));

    // 点 X 取消回复目标
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(
        find.text(L10n.current.commentComposerReplyTo('测试用户')), findsNothing);
    expect(find.text(L10n.current.commentComposerHint), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  test('BiliEmotePackage.fromJson 解析表情包（含 meta.size 与文字包）', () {
    final pkg = BiliEmotePackage.fromJson({
      'url': 'https://i0.hdslb.com/bfs/emote/pkg.png',
      'type': 1,
      'emote': [
        {
          'text': '[dog]',
          'url': 'https://i0.hdslb.com/bfs/emote/dog.png',
          'meta': {'size': 1, 'alias': '狗头'},
        },
        {
          'text': '[热词]',
          'url': 'https://i0.hdslb.com/bfs/emote/hot.png',
          'meta': {},
        },
        // 缺 url 的脏数据应被过滤
        {'text': '[bad]', 'url': ''},
      ],
    });
    expect(pkg.emotes.length, 2);
    expect(pkg.emotes.first.text, '[dog]');
    expect(pkg.emotes.first.size, 1);
    expect(pkg.isTextPackage, isFalse);

    final textPkg = BiliEmotePackage.fromJson({
      'url': '',
      'type': 4,
      'emote': [
        {'text': '[藏话]', 'url': 'https://i0.hdslb.com/x.png'},
      ],
    });
    expect(textPkg.isTextPackage, isTrue);
  });

  test('formatCommentProgress 对齐 PiliPlus DurationUtils', () {
    expect(formatCommentProgress(0), '00:00');
    expect(formatCommentProgress(754), '12:34');
    expect(formatCommentProgress(59), '00:59');
    expect(formatCommentProgress(3725), '01:02:05');
  });

  testWidgets('加号面板：视频进度插入 " MM:SS "，视频截图加入图片条',
      (tester) async {
    // 真实 1x1 PNG（Image.memory 需可解码数据）
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
      'AAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    );
    await tester.pumpWidget(host(
      Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => showCommentComposer(
            ctx,
            oid: 1,
            currentProgress: () => 754.9,
            captureFrame: () async => png,
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 展开加号面板
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text(L10n.current.commentComposerVideoProgress), findsOneWidget);
    expect(
        find.text(L10n.current.commentComposerVideoScreenshot), findsOneWidget);

    // 点「视频进度」→ 输入框插入 " 12:34 "（.round() → 755? 754.9 取整 755）
    await tester.tap(find.text(L10n.current.commentComposerVideoProgress));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, ' ${formatCommentProgress(755)} ');

    // 点「视频截图」→ 图片条出现 1 张预览
    await tester.tap(find.text(L10n.current.commentComposerVideoScreenshot));
    await tester.pump();
    expect(find.byType(Image), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('回复模式：不显示选图按钮与加号面板（回复不支持图片）',
      (tester) async {
    await tester.pumpWidget(host(
      Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => showCommentComposer(
            ctx,
            oid: 1,
            replyTo: fakeComment(),
            // 即使传了截图回调，回复模式也不显示（_isRoot false）
            captureFrame: () async => null,
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.image_outlined), findsNothing,
        reason: '回复不支持图片');
    expect(find.byIcon(Icons.add_circle_outline), findsNothing,
        reason: '回复无进度/截图项时不显示加号');
    // 表情面板仍可用
    expect(find.byIcon(Icons.emoji_emotions_outlined), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
