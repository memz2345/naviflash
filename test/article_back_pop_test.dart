// 回归测试：专栏页加载完成后从搜索页返回，pop 转场全程无异常。
//
// 缺陷背景：返回时 ArticlePage 的 PopScope 把整页重新包裹成 Hero
// （恢复 iOS 整页缩回动画），此时作者栏的头像 Hero 会变成这个整页
// Hero 的后代，触发「A Hero widget cannot be the descendant of another
// Hero widget.」断言报错（正文图片/封面已有 heroTagsDisabled 守卫，
// 唯独作者头像 Hero 漏了）。
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/article_page.dart';
import 'package:naviflash/screens/bilibili_search_page.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_article_service.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _articleId = 12345678;

class _FakeOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<bool> Function(Uri url, String scheme, String? realm)? authenticate;
  @override
  Future<bool> Function(String host, int port, String scheme, String? realm)?
  authenticateProxy;
  @override
  bool Function(X509Certificate cert, String host, int port)?
  badCertificateCallback;
  @override
  String Function(Uri url)? findProxy;

  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )?
    f,
  ) {}

  @override
  set keyLog(Function(String line)? callback) {}

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) {}

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {}

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) => _request('GET', url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => _request('POST', url);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => _request('PUT', url);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => _request('DELETE', url);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => _request('PATCH', url);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => _request('HEAD', url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      _request(method, url);

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) => _request(method, Uri.parse('http://$host:$port$path'));

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      _request('GET', Uri.parse('http://$host:$port$path'));

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      _request('POST', Uri.parse('http://$host:$port$path'));

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      _request('PUT', Uri.parse('http://$host:$port$path'));

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      _request('DELETE', Uri.parse('http://$host:$port$path'));

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      _request('PATCH', Uri.parse('http://$host:$port$path'));

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      _request('HEAD', Uri.parse('http://$host:$port$path'));

  Future<HttpClientRequest> _request(String method, Uri url) async {
    final body = _canned(url);
    final status = body == null ? 404 : 200;
    return _FakeRequest(method, url, status, body ?? '');
  }

  static String? _canned(Uri url) {
    final path = url.path;
    if (path.contains('/x/web-interface/nav')) {
      return '{"code":0,"data":{"wbi_img":{'
          '"img_url":"https://i0.hdslb.com/bfs/wbi/'
          'abcdefghijklmnopqrstuvwxyz0123456789abcdefgh.png",'
          '"sub_url":"https://i0.hdslb.com/bfs/wbi/'
          'abcdefghijklmnopqrstuvwxyz0123456789abcdefgh.png"}}}';
    }
    if (path.contains('/x/web-interface/wbi/search/type')) {
      return jsonEncode({
        'code': 0,
        'data': {
          'numResults': 1,
          'result': [
            {
              'id': _articleId,
              'mid': 1,
              'title': '测试专栏标题',
              'image_urls': ['https://i0.hdslb.com/bfs/article/cover.jpg'],
              'category_name': '科技',
              'view': 1000,
              'reply': 10,
              'desc': '简介',
            },
          ],
        },
      });
    }
    if (path.contains('/x/article/view')) {
      return jsonEncode({
        'code': 0,
        'data': {
          'id': _articleId,
          'title': '测试专栏标题',
          'type': 3,
          'origin_image_urls': [
            'https://i0.hdslb.com/bfs/article/main.png',
            'https://i0.hdslb.com/bfs/article/inline.png',
          ],
          'ops': [
            {'insert': '正文内容\n'},
            {
              'insert': {
                'url': 'https://i0.hdslb.com/bfs/article/inline.png',
              },
            },
            {'insert': '\n结尾'},
          ],
          'author': {
            'mid': 1,
            'name': 'UP',
            'face': '',
          },
          'stats': {'view': 1, 'like': 1, 'reply': 1},
        },
      });
    }
    return null;
  }
}

class _FakeRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHeaders();

  @override
  int contentLength = 0;
  @override
  bool bufferOutput = true;
  @override
  int maxRedirects = 5;
  @override
  bool followRedirects = true;
  @override
  bool persistentConnection = true;
  @override
  Encoding encoding = utf8;
  @override
  final String method;
  @override
  final Uri uri;
  final int status;
  final String body;

  _FakeRequest(this.method, this.uri, this.status, this.body);

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) => Future.value();

  @override
  Future<HttpClientResponse> close() async => _FakeResponse(status, body);

  @override
  List<Cookie> get cookies => const [];

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  Future<HttpClientResponse> get done async => _FakeResponse(status, body);

  @override
  Future<void> flush() => Future.value();

  @override
  void write(Object? obj) {}

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? obj = '']) {}
}

class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  final int _status;
  final List<int> _body;
  _FakeResponse(this._status, String body) : _body = utf8.encode(body);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_body).listen(onData, onError: onError,
      onDone: onDone, cancelOnError: cancelOnError);

  @override
  int get statusCode => _status;
  @override
  String get reasonPhrase => _status == 200 ? 'OK' : 'Not Found';
  @override
  int get contentLength => _body.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => true;
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  HttpHeaders get headers => _FakeHeaders();
  @override
  List<Cookie> get cookies => const [];
  @override
  X509Certificate? get certificate => null;
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  Future<Socket> detachSocket() => throw UnsupportedError('no socket');
  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) => throw UnsupportedError('no redirect');
  @override
  Future<bool> any(bool Function(List<int> element) test) =>
      Stream<List<int>>.value(_body).any(test);
  @override
  Stream<List<int>> asBroadcastStream({
    void Function(StreamSubscription<List<int>> subscription)? onListen,
    void Function(StreamSubscription<List<int>> subscription)? onCancel,
  }) => Stream<List<int>>.value(_body).asBroadcastStream();
  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(List<int> event) convert) =>
      Stream<List<int>>.value(_body).asyncExpand(convert);
  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(List<int> event) convert) =>
      Stream<List<int>>.value(_body).asyncMap(convert);
  @override
  Stream<List<int>> distinct([
    bool Function(List<int> previous, List<int> next)? equals,
  ]) => Stream<List<int>>.value(_body).distinct(equals);
  @override
  Future<E> drain<E>([E? futureValue]) =>
      Stream<List<int>>.value(_body).drain(futureValue);
  @override
  Future<List<int>> elementAt(int index) =>
      Stream<List<int>>.value(_body).elementAt(index);
  @override
  Future<bool> every(bool Function(List<int> element) test) =>
      Stream<List<int>>.value(_body).every(test);
  @override
  Stream<S> expand<S>(Iterable<S> Function(List<int> element) convert) =>
      Stream<List<int>>.value(_body).expand(convert);
  @override
  Future<List<int>> get first => Stream<List<int>>.value(_body).first;
  @override
  Future<List<int>> firstWhere(
    bool Function(List<int> element) test, {
    List<int> Function()? orElse,
  }) => Stream<List<int>>.value(_body).firstWhere(test, orElse: orElse);
  @override
  Future<S> fold<S>(
    S initialValue,
    S Function(S previous, List<int> element) combine,
  ) => Stream<List<int>>.value(_body).fold(initialValue, combine);
  @override
  Future<void> forEach(void Function(List<int> element) action) =>
      Stream<List<int>>.value(_body).forEach(action);
  @override
  Stream<List<int>> handleError(
    Function onError, {
    bool Function(dynamic error)? test,
  }) => Stream<List<int>>.value(_body).handleError(onError, test: test);
  @override
  Future<String> join([String separator = '']) =>
      Stream<List<int>>.value(_body).join(separator);
  @override
  Future<List<int>> get last => Stream<List<int>>.value(_body).last;
  @override
  Future<List<int>> lastWhere(
    bool Function(List<int> element) test, {
    List<int> Function()? orElse,
  }) => Stream<List<int>>.value(_body).lastWhere(test, orElse: orElse);
  @override
  Future<int> get length => Stream<List<int>>.value(_body).length;
  @override
  Stream<S> map<S>(S Function(List<int> event) convert) =>
      Stream<List<int>>.value(_body).map(convert);
  @override
  Future<void> pipe(StreamConsumer<List<int>> streamConsumer) =>
      Stream<List<int>>.value(_body).pipe(streamConsumer);
  @override
  Future<List<int>> reduce(
    List<int> Function(List<int> previous, List<int> element) combine,
  ) => Stream<List<int>>.value(_body).reduce(combine);
  @override
  Future<List<int>> get single => Stream<List<int>>.value(_body).single;
  @override
  Future<List<int>> singleWhere(
    bool Function(List<int> element) test, {
    List<int> Function()? orElse,
  }) => Stream<List<int>>.value(_body).singleWhere(test, orElse: orElse);
  @override
  Stream<List<int>> skip(int count) =>
      Stream<List<int>>.value(_body).skip(count);
  @override
  Stream<List<int>> skipWhile(bool Function(List<int> element) test) =>
      Stream<List<int>>.value(_body).skipWhile(test);
  @override
  Stream<List<int>> take(int count) =>
      Stream<List<int>>.value(_body).take(count);
  @override
  Stream<List<int>> takeWhile(bool Function(List<int> element) test) =>
      Stream<List<int>>.value(_body).takeWhile(test);
  @override
  Stream<List<int>> timeout(
    Duration timeLimit, {
    void Function(EventSink<List<int>> sink)? onTimeout,
  }) => Stream<List<int>>.value(_body).timeout(timeLimit, onTimeout: onTimeout);
  @override
  Future<List<List<int>>> toList() => Stream<List<int>>.value(_body).toList();
  @override
  Future<Set<List<int>>> toSet() => Stream<List<int>>.value(_body).toSet();
  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) =>
      Stream<List<int>>.value(_body).transform(streamTransformer);
  @override
  Stream<List<int>> where(bool Function(List<int> event) test) =>
      Stream<List<int>>.value(_body).where(test);
}

class _FakeHeaders implements HttpHeaders {
  final Map<String, List<String>> _data = {};
  @override
  List<String>? operator [](String name) => _data[name.toLowerCase()];
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _data.putIfAbsent(name.toLowerCase(), () => []).add('$value');
  }
  @override
  void clear() => _data.clear();
  @override
  void forEach(void Function(String name, List<String> values) action) =>
      _data.forEach(action);
  @override
  void noFolding(String name) {}
  @override
  void remove(String name, Object value) =>
      _data[name.toLowerCase()]?.remove('$value');
  @override
  void removeAll(String name) => _data.remove(name.toLowerCase());
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _data[name.toLowerCase()] = ['$value'];
  }
  @override
  String? value(String name) => _data[name.toLowerCase()]?.isNotEmpty == true
      ? _data[name.toLowerCase()]!.first
      : null;
  @override
  bool get chunkedTransferEncoding => false;
  @override
  set chunkedTransferEncoding(bool value) {}
  @override
  int get contentLength => 0;
  @override
  set contentLength(int contentLength) {}
  @override
  DateTime? get date => null;
  @override
  set date(DateTime? date) {}
  @override
  DateTime? get expires => null;
  @override
  set expires(DateTime? expires) {}
  @override
  String? get host => null;
  @override
  set host(String? host) {}
  @override
  DateTime? get ifModifiedSince => null;
  @override
  set ifModifiedSince(DateTime? ifModifiedSince) {}
  @override
  bool get persistentConnection => true;
  @override
  set persistentConnection(bool persistentConnection) {}
  @override
  ContentType? get contentType => null;
  @override
  set contentType(ContentType? contentType) {}
  @override
  int? get port => null;
  @override
  set port(int? port) {}
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NetworkSettingsService().initialize();
    await BilibiliAccountService().initialize();
    await BilibiliTranslateService().initialize();
    SettingsService.heroTransitionBlurEnabled = true;
    HttpOverrides.global = _FakeOverrides();
    ArticleCache.disabled = true;
  });

  tearDown(() {
    HttpOverrides.global = null;
    ArticleCache.disabled = false;
  });

  testWidgets('点击返回按钮从专栏返回搜索页，pop 全程无异常', (tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BilibiliSearchPage(initialKeyword: '测试'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('专栏').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('测试专栏标题').first);
    await tester.pump();
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final e = tester.takeException();
      expect(e, isNull, reason: 'push 转场第 $i 帧出现异常: $e');
    }
    expect(find.byType(ArticlePage), findsOneWidget);

    // 等正文加载完成
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('正文内容').evaluate().isNotEmpty) break;
    }
    expect(tester.takeException(), isNull);

    // 点击左上角返回按钮（走 PopScope 重包裹路径）
    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final e = tester.takeException();
      expect(e, isNull, reason: 'pop 转场第 $i 帧出现异常: $e');
      // 返回缩回期间飞行元素必须是「整页本体」：Hero 双方 child 都被
      // placeholder 顶掉，此时屏幕上唯一在渲染的页面内容就是 shuttle。
      // 正文文本（只有专栏页有）恰好出现一份，即同时证明：
      //   ① 返回飞的是整页内容 —— 旧实现只渲染来源卡片的封面本体，
      //      此处会数到 0 份（缩回全程是一张封面图，与进入不一致）；
      //   ② 整页树只存在一份 —— 不存在「shuttle 复制整页导致
      //      duplicate GlobalKey」的风险。
      if (i >= 2 && i <= 8) {
        expect(
          find.text('正文内容'),
          findsOneWidget,
          reason: '返回缩回期间飞行元素应为整页内容，且只渲染一份',
        );
      }
    }
    expect(find.byType(ArticlePage), findsNothing);
    expect(find.text('测试专栏标题'), findsOneWidget,
        reason: '返回后搜索页应保留专栏卡片');
    await tester.pumpWidget(const SizedBox());
  });
}
