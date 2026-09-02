import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/app_localizations_zh.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/screens/note_editor_page.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_note_service.dart';
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
  late Directory tmpDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    L10n.setCurrent(AppLocalizationsZhCn());
  });

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('navi_note_test');
    PathProviderPlatform.instance = _FakePathProvider(tmpDir);
    SharedPreferences.setMockInitialValues({});
    // 账号服务（未登录态）：编辑器/发布服务的 canPublish 依赖它
    await BilibiliAccountService().initialize();
  });

  tearDown(() async {
    await tmpDir.delete(recursive: true);
  });

  group('NoteDraftCache 草稿缓存', () {
    test('save → load → remove 往返一致', () async {
      const bvid = 'BV1test0000';
      expect(await NoteDraftCache.load(bvid), isNull);

      await NoteDraftCache.save(const BiliNoteDraft(
        bvid: bvid,
        title: '标题',
        content: '正文内容',
        updatedAt: 1700000000000,
      ));
      final loaded = await NoteDraftCache.load(bvid);
      expect(loaded, isNotNull);
      expect(loaded!.title, '标题');
      expect(loaded.content, '正文内容');
      expect(loaded.updatedAt, 1700000000000);

      await NoteDraftCache.remove(bvid);
      expect(await NoteDraftCache.load(bvid), isNull);
    });

    test('listAll 按更新时间倒序', () async {
      await NoteDraftCache.save(
          const BiliNoteDraft(bvid: 'BVa', content: 'a', updatedAt: 100));
      await NoteDraftCache.save(
          const BiliNoteDraft(bvid: 'BVb', content: 'b', updatedAt: 200));
      final all = await NoteDraftCache.listAll();
      expect(all.length, 2);
      expect(all.first.bvid, 'BVb');
    });
  });

  group('发布参数构造', () {
    test('buildDeltaContent 按行生成 quill ops 且每行以换行结尾', () {
      final delta = BilibiliNoteService.buildDeltaContent('第一行\n\n第三行');
      final list =
          (jsonDecode(delta) as List).cast<Map<String, dynamic>>();
      expect(list.length, 3);
      expect(list.first['insert'], '第一行\n');
      expect(list[1]['insert'], '\n');
      expect(list.last['insert'], '第三行\n');
    });

    test('buildSummary 对齐 H5：77 字截断加省略号，空内容回退默认文案', () {
      expect(BilibiliNoteService.buildSummary('  \n短文本\n'), '短文本');
      final s = BilibiliNoteService.buildSummary('字' * 100);
      expect(s.length, 80); // 77 字 + "..."（3 字符）
      expect(s.endsWith('...'), isTrue);
      expect(
          BilibiliNoteService.buildSummary(''), '我发布了一篇笔记，快来看看吧~');
    });

    test('contentValid：去空白后至少 10 字符', () {
      expect(BilibiliNoteService.contentValid('12345'), isFalse);
      expect(BilibiliNoteService.contentValid('  1234567890  '), isTrue);
      expect(BilibiliNoteService.contentValid('九个字'), isFalse);
      expect(BilibiliNoteService.contentValid('一二三四五六七八九十'), isTrue);
    });

    test('canPublish：未登录（无 Cookie）为 false', () {
      expect(BilibiliNoteService.canPublish, isFalse);
    });
  });

  group('NoteEditorPage 编辑器', () {
    // 说明：widget 测试的 FakeAsync 下真实文件 IO 不会完成，草稿落盘
    // 的磁盘行为由上面 NoteDraftCache 单元测试覆盖；此处只验证 UI 行为。
    testWidgets('输入内容更新字数；内容过短点发布出提示', (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const NoteEditorPage(
          bvid: 'BV1editor000',
          aid: 123,
          videoTitle: '测试视频',
        ),
      ));
      await tester.pumpAndSettle();

      // 初始 0 字
      expect(find.text(L10n.current.noteEditorCharCount(0)), findsOneWidget);

      // at(0) 标题、at(1) 正文
      await tester.enterText(
        find.byType(TextField).at(1),
        '五个字',
      );
      await tester.pump();
      expect(
        find.text(L10n.current.noteEditorCharCount(3)),
        findsOneWidget,
        reason: '输入后字数应实时更新',
      );

      // 内容不足 10 字 → 点发布提示过短（不触发网络/磁盘）
      await tester.tap(find.text(L10n.current.noteEditorPublish));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(L10n.current.noteEditorContentTooShort), findsOneWidget);

      // 卸载编辑器：dispose 取消草稿防抖 Timer，避免测试结束时
      // 「Timer is still pending」
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('编辑器展示视频标题与未登录提示', (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const NoteEditorPage(bvid: 'BV1x', aid: 1, videoTitle: '标题长的视频'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('标题长的视频'), findsOneWidget);
      expect(find.text(L10n.current.noteEditorGuestHint), findsOneWidget);
    });
  });
}
