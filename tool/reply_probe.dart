// 临时探测脚本：对比三种游客方式请求 /x/v2/reply/main 的返回条数。
// 用法：dart run tool/reply_probe.dart [aid]
//   1) web 风格 + 随机 buvid3 + wbi（当前 App 评论服务的做法）
//   2) web 风格 + finger/spi 真实指纹（buvid3/buvid4/b_nut/b_lsid）+ wbi
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http2/http2.dart';

const webUa =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
const appUa =
    'Mozilla/5.0 BiliDroid/8.43.0 (bbcallen@gmail.com) os/android '
    'model/android mobi_app/android build/8430300 channel/master '
    'innerVer/8430300 osVer/15 network/2';

final HttpClient _client = HttpClient()
  ..connectionTimeout = const Duration(seconds: 15);

Future<Map<String, dynamic>> getJson(
  String url,
  Map<String, String> headers,
) async {
  final uri = Uri.parse(url);
  final req = await _client.getUrl(uri);
  headers.forEach(req.headers.set);
  final resp = await req.close().timeout(const Duration(seconds: 20));
  final body = await utf8.decodeStream(resp);
  return jsonDecode(body) as Map<String, dynamic>;
}

// ── wbi 签名（与 bilibili_user_space_service.WbiSign 相同）──
const mixinKeyEncTab = [
  46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35, 27, 43, 5,
  49, 33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13,
];
String? _mixinKey;

Future<String> _fetchMixinKey() async {
  final json = await getJson('https://api.bilibili.com/x/web-interface/nav', {
    'User-Agent': webUa,
    'Referer': 'https://www.bilibili.com',
  });
  final wbi = (json['data'] as Map?)?['wbi_img'] as Map?;
  String name(String url) => (url.split('/').last).split('.').first;
  final orig = '${name(wbi?['img_url'] ?? '')}${name(wbi?['sub_url'] ?? '')}';
  return String.fromCharCodes(
    mixinKeyEncTab.map((i) => orig.codeUnits[i]),
  );
}

Future<Map<String, String>> wbiSign(Map<String, String> params) async {
  _mixinKey ??= await _fetchMixinKey();
  if (_mixinKey!.isEmpty) return params;
  final all = {...params, 'wts': '${DateTime.now().millisecondsSinceEpoch ~/ 1000}'};
  final keys = all.keys.toList()..sort();
  final query = keys
      .map((k) =>
          '${Uri.encodeComponent(k)}=${Uri.encodeComponent(all[k]!.replaceAll(RegExp(r"[!'\(\)\*]"), ''))}')
      .join('&');
  return {...all, 'w_rid': md5.convert(utf8.encode('$query$_mixinKey')).toString()};
}

String genBuvid3() {
  final r = Random();
  String hex(int n) =>
      List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
  final uuid =
      '${hex(8)}-${hex(4)}-4${hex(3)}-${'89ab'[r.nextInt(4)]}${hex(3)}-${hex(12)}'
          .toUpperCase();
  return '$uuid${r.nextInt(100000).toString().padLeft(5, '0')}infoc';
}

String genBLsid() {
  final r = Random();
  String hex(int n) => List.generate(n, (_) => '0123456789abcdef'[r.nextInt(16)]).join();
  return '${hex(16)}_${hex(8)}';
}

Uri buildUri(String api, Map<String, String> params) =>
    Uri.parse(api).replace(queryParameters: params);

Future<Map<String, dynamic>> h2Get(
  String url,
  Map<String, String> headers,
) async {
  final uri = Uri.parse(url);
  final socket = await SecureSocket.connect(
    uri.host,
    443,
    supportedProtocols: ['h2'],
  ).timeout(const Duration(seconds: 15));
  final conn = ClientTransportConnection.viaSocket(socket);
  try {
    final h2Headers = <Header>[
      Header.ascii(':method', 'GET'),
      Header.ascii(':path', '${uri.path}${uri.query.isEmpty ? '' : '?${uri.query}'}'),
      Header.ascii(':scheme', 'https'),
      Header.ascii(':authority', uri.host),
      for (final e in headers.entries) Header.ascii(e.key, e.value),
    ];
    final stream = conn.makeRequest(h2Headers, endStream: true);
    final body = <List<int>>[];
    await for (final msg in stream.incomingMessages) {
      if (msg is DataStreamMessage) body.add(msg.bytes);
    }
    return jsonDecode(utf8.decode(List<int>.from(body.expand((b) => b))))
        as Map<String, dynamic>;
  } finally {
    await conn.finish();
    socket.destroy();
  }
}

Future<void> probe(String label, Uri uri, Map<String, String> headers) async {
  try {
    final json = await getJson(uri.toString(), headers);
    final data = json['data'] as Map?;
    final replies = (data?['replies'] as List?) ?? [];
    final cursor = data?['cursor'] as Map?;
    print('[$label] code=${json['code']} replies=${replies.length} '
        'all_count=${cursor?['all_count']} is_end=${cursor?['is_end']}');
  } catch (e) {
    print('[$label] 异常: $e');
  }
}

Future<String> findAidViaSearch() async {
  // 搜索需要指纹 cookie + wbi，直接用方案 2 的组合
  final spi = await getJson('https://api.bilibili.com/x/frontend/finger/spi', {
    'User-Agent': webUa,
    'Referer': 'https://www.bilibili.com',
  });
  final b3 = ((spi['data'] as Map?)?['b_3'] as String?) ?? genBuvid3();
  final b4 = ((spi['data'] as Map?)?['b_4'] as String?) ?? '';
  final cookie = [
    'buvid3=$b3',
    if (b4.isNotEmpty) 'buvid4=$b4',
    'b_nut=${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
    'b_lsid=${genBLsid()}',
  ].join('; ');
  final params = await wbiSign({
    'search_type': 'video',
    'keyword': '测试',
    'page': '1',
    'page_size': '5',
    'platform': 'pc',
    'web_location': '1430654',
  });
  final json = await getJson(buildUri(
    'https://api.bilibili.com/x/web-interface/wbi/search/type',
    params,
  ).toString(), {
    'User-Agent': webUa,
    'Referer': 'https://search.bilibili.com',
    'Origin': 'https://search.bilibili.com',
    'Cookie': cookie,
  });
  final result = json['data'] as Map?;
  final list = (result?['result'] as List?) ?? [];
  for (final v in list) {
    final aid = (v as Map)['aid'];
    if (aid != null) return aid.toString();
  }
  throw '搜索拿不到 aid: ${json['code']} ${json['message']}';
}

Future<void> main(List<String> args) async {
  final aid = args.isNotEmpty ? args[0] : await findAidViaSearch();
  print('aid=$aid');

  const api = 'https://api.bilibili.com/x/v2/reply/main';
  const appApiMain = 'https://app.bilibili.com/x/v2/reply/main';
  const appApiPage = 'https://app.bilibili.com/x/v2/reply';

  const appHeaders = {
    'env': 'prod',
    'app-key': 'android64',
    'x-bili-aurora-zone': 'sh001',
  };

  Map<String, String> appSign(Map<String, String> params) {
    params['appkey'] = 'dfca71928277209b';
    params['ts'] = '${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
    final sorted = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final query = sorted
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return {...params, 'sign': md5.convert(utf8.encode('${query}b5475a8825547a4fc26c7d518eaaa02e')).toString()};
  }

  // 1) 当前 App 做法：随机 buvid3 + web 头 + wbi + web_location
  {
    final params = await wbiSign({
      'oid': aid,
      'type': '1',
      'mode': '3',
      'pagination_str': '{"max_num":20,"_gt_":0}',
      'web_location': '333.788',
    });
    await probe('1-随机buvid3+wbi', buildUri(api, params), {
      'User-Agent': webUa,
      'Referer': 'https://www.bilibili.com',
      'Cookie': 'buvid3=${genBuvid3()}',
    });
  }

  // 2) 真实指纹：finger/spi buvid3/buvid4 + b_nut + b_lsid + wbi
  {
    final spi = await getJson('https://api.bilibili.com/x/frontend/finger/spi', {
      'User-Agent': webUa,
      'Referer': 'https://www.bilibili.com',
    });
    final b3 = ((spi['data'] as Map?)?['b_3'] as String?) ?? '';
    final b4 = ((spi['data'] as Map?)?['b_4'] as String?) ?? '';
    final cookie = [
      'buvid3=$b3',
      if (b4.isNotEmpty) 'buvid4=$b4',
      'b_nut=${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
      'b_lsid=${genBLsid()}',
    ].join('; ');
    final params = await wbiSign({
      'oid': aid,
      'type': '1',
      'mode': '3',
      'pagination_str': '{"max_num":20,"_gt_":0}',
      'web_location': '333.788',
    });
    await probe('2-真实指纹+wbi', buildUri(api, params), {
      'User-Agent': webUa,
      'Referer': 'https://www.bilibili.com',
      'Cookie': cookie,
    });
  }

  {
    await probe('3-PiliPlus游客', buildUri(api, {
      'oid': aid,
      'type': '1',
      'mode': '3',
      'pagination_str': '{"offset":""}',
    }), {
      'env': 'prod',
      'app-key': 'android64',
      'x-bili-aurora-zone': 'sh001',
      'Cookie': '',
    });
  }

  {
    await probe('4-APP头+UA', buildUri(api, {
      'oid': aid,
      'type': '1',
      'mode': '3',
      'pagination_str': '{"offset":""}',
    }), {
      'User-Agent': appUa,
      ...appHeaders,
      'Cookie': '',
    });
  }

  // 5) app.bilibili.com/x/v2/reply/main + AppSign（APP 端游标分页）
  {
    await probe('5-app域名main+sign', buildUri(appApiMain, appSign({
      'oid': aid,
      'type': '1',
      'mode': '3',
      'pagination_str': '{"offset":""}',
    })), {
      'User-Agent': appUa,
      ...appHeaders,
    });
  }

  // 6) app.bilibili.com/x/v2/reply + AppSign（APP 端页码分页）
  {
    await probe('6-app域名pn+sign', buildUri(appApiPage, appSign({
      'oid': aid,
      'type': '1',
      'pn': '1',
      'ps': '20',
      'sort': '1',
    })), {
      'User-Agent': appUa,
      ...appHeaders,
    });
  }

  {
    try {
      final json = await h2Get(
        buildUri(api, {
          'oid': aid,
          'type': '1',
          'mode': '3',
          'pagination_str': '{"offset":""}',
        }).toString(),
        {
          'env': 'prod',
          'app-key': 'android64',
          'x-bili-aurora-zone': 'sh001',
          'cookie': '',
        },
      );
      final data = json['data'] as Map?;
      print('[7-h2+APP头] code=${json['code']} '
          'replies=${(data?['replies'] as List?)?.length ?? 0} '
          'all_count=${(data?['cursor'] as Map?)?['all_count']}');
    } catch (e) {
      print('[7-h2+APP头] 异常: $e');
    }
  }

  // 8) HTTP/2 + Web 风格（真实指纹 + wbi），对照 h2 是否影响 3 条限制
  {
    try {
      final spi = await getJson('https://api.bilibili.com/x/frontend/finger/spi', {
        'User-Agent': webUa,
        'Referer': 'https://www.bilibili.com',
      });
      final b3 = ((spi['data'] as Map?)?['b_3'] as String?) ?? '';
      final b4 = ((spi['data'] as Map?)?['b_4'] as String?) ?? '';
      final cookie = [
        'buvid3=$b3',
        if (b4.isNotEmpty) 'buvid4=$b4',
        'b_nut=${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
        'b_lsid=${genBLsid()}',
      ].join('; ');
      final params = await wbiSign({
        'oid': aid,
        'type': '1',
        'mode': '3',
        'pagination_str': '{"max_num":20,"_gt_":0}',
        'web_location': '333.788',
      });
      final json = await h2Get(buildUri(api, params).toString(), {
        'user-agent': webUa,
        'referer': 'https://www.bilibili.com',
        'cookie': cookie,
      });
      final data = json['data'] as Map?;
      print('[8-h2+Web指纹] code=${json['code']} '
          'replies=${(data?['replies'] as List?)?.length ?? 0} '
          'all_count=${(data?['cursor'] as Map?)?['all_count']}');
    } catch (e) {
      print('[8-h2+Web指纹] 异常: $e');
    }
  }

  //    HttpClient autoUncompress 默认开，能自动解 gzip；不请求 br 避免手动解
  {
    await probe('9-h1+DartUA+gzip', buildUri(api, {
      'oid': aid,
      'type': '1',
      'mode': '3',
      'pagination_str': '{"offset":""}',
    }), {
      'User-Agent': 'Dart/3.6 (dart:io)',
      'Accept-Encoding': 'gzip',
      'env': 'prod',
      'app-key': 'android64',
      'x-bili-aurora-zone': 'sh001',
      'Cookie': '',
    });
  }

  //     避免收到 br 压缩响应，h2Get 不带解压）
  {
    try {
      final json = await h2Get(
        buildUri(api, {
          'oid': aid,
          'type': '1',
          'mode': '3',
          'pagination_str': '{"offset":""}',
        }).toString(),
        {
          'user-agent': 'Dart/3.6 (dart:io)',
          'env': 'prod',
          'app-key': 'android64',
          'x-bili-aurora-zone': 'sh001',
          'cookie': '',
        },
      );
      final data = json['data'] as Map?;
      print('[10-h2+DartUA] code=${json['code']} '
          'replies=${(data?['replies'] as List?)?.length ?? 0} '
          'all_count=${(data?['cursor'] as Map?)?['all_count']}');
    } catch (e) {
      print('[10-h2+DartUA] 异常: $e');
    }
  }

  {
    try {
      final json = await h2Get(
        buildUri(api, {
          'oid': aid,
          'type': '1',
          'mode': '3',
          'pagination_str': '{"offset":""}',
        }).toString(),
        {
          'user-agent': 'Dart/3.6 (dart:io)',
          'accept-encoding': 'identity',
          'env': 'prod',
          'app-key': 'android64',
          'x-bili-aurora-zone': 'sh001',
          'cookie': '',
        },
      );
      final data = json['data'] as Map?;
      print('[11-h2+DartUA+identity] code=${json['code']} '
          'replies=${(data?['replies'] as List?)?.length ?? 0} '
          'all_count=${(data?['cursor'] as Map?)?['all_count']}');
    } catch (e) {
      print('[11-h2+DartUA+identity] 异常: $e');
    }
  }

  // 12) 翻页测试：连续 3 页，验证游标是否单调推进、有无重复
  //     同时检查 top_replies 的 rpid 是否在后续页的 replies 中重复出现
  {
    try {
      final headers = {
        'User-Agent': 'Dart/3.6 (dart:io)',
        'Accept-Encoding': 'gzip',
        'env': 'prod',
        'app-key': 'android64',
        'x-bili-aurora-zone': 'sh001',
        'Cookie': '',
      };
      String offset = '';
      final seenRpids = <String>{};
      Set<String>? topRpids;
      for (var p = 1; p <= 3; p++) {
        final ps = '{"offset":"$offset"}';
        final json = await getJson(buildUri(api, {
          'oid': aid,
          'type': '1',
          'mode': '3',
          'pagination_str': ps,
        }).toString(), headers);
        final data = json['data'] as Map?;
        final replies = (data?['replies'] as List?) ?? [];
        final topReplies = (data?['top_replies'] as List?) ?? [];
        final cursor = data?['cursor'] as Map?;
        final pagination = cursor?['pagination_reply'] as Map?;
        final nextOffset =
            (pagination?['next_offset'] as dynamic)?.toString() ?? '';
        final pageRpids = replies
            .map((r) => (r as Map)['rpid']?.toString() ?? '')
            .where((r) => r.isNotEmpty)
            .toSet();
        if (p == 1) {
          topRpids = topReplies
              .map((r) => (r as Map)['rpid']?.toString() ?? '')
              .where((r) => r.isNotEmpty)
              .toSet();
          print('  top_replies rpid=$topRpids');
        }
        final dupInSeen = pageRpids.intersection(seenRpids);
        final dupWithTop =
            topRpids == null ? <String>{} : pageRpids.intersection(topRpids);
        print('[12-P$p] offset="$offset" replies=${replies.length} '
            'top=${topReplies.length} is_end=${cursor?['is_end']} '
            'next="$nextOffset" 与已见重复=${dupInSeen.length} '
            '与置顶重复=${dupWithTop.length}');
        seenRpids.addAll(pageRpids);
        offset = nextOffset;
        if (cursor?['is_end'] == true || offset.isEmpty) break;
      }
      print('  累计不重复 rpid 数=${seenRpids.length}');
    } catch (e) {
      print('[12-翻页] 异常: $e');
    }
  }

  _client.close();
  exit(0);
}
