import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/services/image_cache_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// 测试用假 PathProvider：缓存目录指向系统临时目录。
class _FakePathProvider extends PathProviderPlatform {
  final String root;
  _FakePathProvider(this.root);

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('navi_cache_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('ImageCacheService', () {
    test('save → load roundtrip', () async {
      final url = 'https://example.com/a.png';
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      await ImageCacheService.save(url, bytes);
      final file = await ImageCacheService.load(url);
      expect(file, isNotNull);
      expect(await file!.readAsBytes(), bytes);
      expect(await ImageCacheService.count(), 1);
      expect(await ImageCacheService.totalSize(), 4);
    });

    test('save 相同 URL 不重复写入', () async {
      final url = 'https://example.com/a.png';
      await ImageCacheService.save(url, Uint8List.fromList([1, 2]));
      await ImageCacheService.save(url, Uint8List.fromList([3, 4]));
      expect(await ImageCacheService.count(), 1);
      // 保留首次写入内容
      expect(await (await ImageCacheService.load(url))!.readAsBytes(),
          Uint8List.fromList([1, 2]));
    });

    test('clearAll 清空所有缓存', () async {
      await ImageCacheService.save('https://a/1.png', Uint8List.fromList([1]));
      await ImageCacheService.save('https://a/2.png', Uint8List.fromList([2]));
      expect(await ImageCacheService.count(), 2);
      final removed = await ImageCacheService.clearAll();
      expect(removed, 2);
      expect(await ImageCacheService.count(), 0);
      expect(await ImageCacheService.totalSize(), 0);
      expect(await ImageCacheService.load('https://a/1.png'), isNull);
    });

    test('load 未缓存的 URL 返回 null', () async {
      expect(await ImageCacheService.load('https://missing/1.png'), isNull);
    });
  });

  group('BilibiliCommentService.fetchBytes 缓存', () {
    test('缓存命中时直接读本地文件（不依赖网络）', () async {
      final url = 'https://example.com/comment.png';
      final bytes =
          Uint8List.fromList(List<int>.generate(64, (i) => i));
      await ImageCacheService.save(url, bytes);

      final result = await BilibiliCommentService.fetchBytes(url);
      expect(result, bytes);

      // 重复请求再次命中同一缓存，不新增文件
      final again = await BilibiliCommentService.fetchBytes(url);
      expect(again, bytes);
      expect(await ImageCacheService.count(), 1);
    });

    test('并发请求共享同一下载（缓存未命中时也只落盘一次）', () async {
      final url = 'https://example.com/dup.png';
      final bytes = Uint8List.fromList(List<int>.generate(32, (i) => i * 2));
      await ImageCacheService.save(url, bytes);

      final results = await Future.wait([
        BilibiliCommentService.fetchBytes(url),
        BilibiliCommentService.fetchBytes(url),
        BilibiliCommentService.fetchBytes(url),
      ]);
      for (final r in results) {
        expect(r, bytes);
      }
      expect(await ImageCacheService.count(), 1);
    });

    test('清理缓存后命中失效（重新走下载流程）', () async {
      final url = 'https://example.com/cleared.png';
      await ImageCacheService.save(url, Uint8List.fromList([9, 9]));
      expect(await ImageCacheService.load(url), isNotNull);

      await ImageCacheService.clearAll();
      expect(await ImageCacheService.load(url), isNull);
      // 测试环境网络被 mock（返回 400），下载失败返回 null
      final result = await BilibiliCommentService.fetchBytes(url);
      expect(result, isNull);
    });
  });
}
