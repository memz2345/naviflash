// 复现测试：视频页 → 相关视频 → push 新视频 → 返回 的完整链路。
// 覆盖两类回归：
//  1. 点击相关视频（含列表较下面的卡片）→ 新视频页应有整页 Hero 放大动画；
//  2. 返回上一级视频页后状态/缩放恢复正确。
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_related_videos_page.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_translate_service.dart';
import 'package:naviflash/services/bilibili_article_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/services/video_cache_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bvidA = 'BV1AA411c7mD';
const _bvidB = 'BV1BB411c7mD';

Finder _heroesOf(String tag) =>
    find.byWidgetPredicate((w) => w is Hero && w.tag == tag);

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
    if (path.contains('/x/web-interface/view')) {
      return jsonEncode({
        'code': 0,
        'data': {
          'bvid': url.queryParameters['bvid'] ?? _bvidA,
          'aid': 1,
          'title': '视频标题',
          'desc': '简介',
          'pic': 'https://i0.hdslb.com/bfs/archive/cover.jpg',
          'pubdate': 1700000000,
          'duration': 120,
          'owner': {'name': 'UP主', 'mid': 1, 'face': ''},
          'stat': {
            'view': 1000,
            'danmaku': 10,
            'reply': 20,
            'favorite': 30,
            'coin': 40,
            'share': 50,
            'like': 60,
          },
          'pages': [
            {'cid': 1, 'page': 1, 'part': 'P1', 'duration': 120},
          ],
        },
      });
    }
    if (path.contains('/x/web-interface/archive/related')) {
      return jsonEncode({
        'code': 0,
        'data': [
          {
            'bvid': _bvidB,
            'title': '相关视频1',
            'pic': 'https://i0.hdslb.com/bfs/archive/r1.jpg',
            'pubdate': 1700000000,
            'duration': 60,
            'owner': {'name': 'UP1'},
            'stat': {'view': 100, 'danmaku': 1},
          },
          for (var i = 2; i <= 20; i++)
            {
              'bvid': 'BV1XX411c7m$i',
              'title': '相关视频$i',
              'pic': 'https://i0.hdslb.com/bfs/archive/r$i.jpg',
              'pubdate': 1700000000,
              'duration': 60,
              'owner': {'name': 'UP$i'},
              'stat': {'view': 100, 'danmaku': 1},
            },
        ],
      });
    }
    if (path.contains('/x/player/wbi/playurl')) {
      return jsonEncode({
        'code': 0,
        'data': {
          'dash': {'video': [], 'audio': []},
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
  }) {
    return Stream<List<int>>.value(_body).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

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
    // 磁盘 JSON 缓存会做真实文件 IO，在 FakeAsync 测试时钟下永远无法完成，
    // 详情/播放地址解析会被卡住 → 测试内关闭（与 ArticleCache 同款约定）。
    VideoJsonCache.disabled = true;
  });

  tearDown(() {
    HttpOverrides.global = null;
    ArticleCache.disabled = false;
    VideoJsonCache.disabled = false;
  });

  testWidgets('视频页 → 点相关视频 → push 新视频动画 → 返回恢复', (tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: Hero(
              tag: 'bili_video_$_bvidA',
              child: const SizedBox(width: 120, height: 68),
            ),
          ),
        ),
      ),
    );
    final nav = Navigator.of(tester.element(find.byType(Scaffold)));

    // 推入视频页 A（整页 Hero 放大）
    nav.push(
      heroTransitionRoute(
        heroZoom: true,
        page: const BilibiliVideoPage(
          bvid: _bvidA,
          heroTag: 'bili_video_$_bvidA',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);

    // 等待相关视频列表加载
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('相关视频1').evaluate().isNotEmpty) break;
    }
    expect(find.text('相关视频1'), findsOneWidget, reason: '相关视频列表应加载成功');

    // 滚动到较下面的卡片（懒加载构建后）再点击
    await tester.pump(const Duration(milliseconds: 200));
    final target = find.text('相关视频15');
    final listScrollable = find.descendant(
      of: find.byType(BilibiliRelatedVideosPage),
      matching: find.byType(Scrollable),
    );
    for (var i = 0; i < 6 && target.evaluate().isEmpty; i++) {
      await tester.drag(listScrollable, const Offset(0, -800));
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(target, findsOneWidget, reason: '相关视频15 应可见');
    await tester.tap(target);
    await tester.pump();

    // 转场中段：源卡片 + 新视频页整页 Hero（同 tag 共两个）都在树上
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      _heroesOf('bili_video_BV1XX411c7m15').evaluate().length,
      2,
      reason: '点击较下面的相关视频也应有整页 Hero 放大动画',
    );
    // 列表滚动位置不应因压栈而回顶（飞行中的源卡片被隐藏，
    // 用相邻卡片判断列表仍在原位置）
    expect(
      find.text('相关视频16'),
      findsOneWidget,
      reason: '压栈后相关视频列表不应重置滚动位置（否则 Hero 源卡片丢失）',
    );
    expect(tester.takeException(), isNull);

    // 完成转场（被覆盖的 A 进入 offstage，用 skipOffstage:false 统计两页）
    await tester.pump(const Duration(milliseconds: 600));
    final pages = find.byType(BilibiliVideoPage, skipOffstage: false);
    expect(pages, findsNWidgets(2));

    // 返回上一级：恢复 A，无异常、缩放复原、滚动位置保持
    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(BilibiliVideoPage), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(BilibiliVideoPage).first),
      Offset.zero,
      reason: '返回后视频页 A 应恢复原比例',
    );
    expect(find.text('相关视频15'), findsOneWidget, reason: '返回后相关视频列表应保持在原滚动位置');

    await tester.pumpWidget(const SizedBox());
  });
}
