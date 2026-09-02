// lib/services/dlna_local_file_server.dart
// 本地文件投屏用 HTTP 服务：把本地视频以支持 HTTP Range 的流式地址暴露到局域网，
// 供 DLNA 设备（电视/盒子）拉取播放。基于 dart:io HttpServer，零额外依赖。
import 'dart:async';
import 'dart:io';
import 'package:mime/mime.dart';

class DlnaLocalFileServer {
  HttpServer? _server;
  File? _file;
  int _port = 0;
  String? _lastRequestError;

  bool get isRunning => _server != null;
  int get port => _port;

  String? get lastRequestError => _lastRequestError;

  /// 启动单文件 HTTP 服务，监听 0.0.0.0 随机端口。
  /// 返回可用于投屏的 URL（不含主机名，由调用方拼 IP）。
  Future<String> start(File file) async {
    if (_server != null) await stop();
    _file = file;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _port = _server!.port;
    _server!.listen(_handleRequest, onError: (Object e) {
      _lastRequestError = e.toString();
    });
    return 'http://<host>/$port/stream';
  }

  String urlForHost(String host) => 'http://$host:$_port/stream';

  Future<void> _handleRequest(HttpRequest request) async {
    final file = _file;
    if (file == null || !await file.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    _lastRequestError = null;

    final total = await file.length();
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    // 解析 Range: bytes=start-end
    int? start_;
    int? end_;
    final range = request.headers.value(HttpHeaders.rangeHeader);
    final match =
        range != null ? RegExp(r'bytes=(\d*)-(\d*)').firstMatch(range) : null;
    if (match != null) {
      final a = match.group(1);
      final b = match.group(2);
      if (a != null && a.isNotEmpty) start_ = int.tryParse(a);
      if (b != null && b.isNotEmpty) end_ = int.tryParse(b);
    }

    final res = request.response;
    res.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    res.headers.set(HttpHeaders.contentTypeHeader, mimeType);

    int start = 0;
    int end = total - 1;

    if (match != null) {
      final hasStart = start_ != null;
      if (hasStart && end_ != null) {
        start = start_;
        end = end_;
      } else if (hasStart) {
        start = start_;
      } else if (end_ != null) {
        // 形如 bytes=-500：表示最后 500 字节
        start = total - end_;
        end = total - 1;
      }
    }

    if (start < 0) start = 0;
    if (end >= total) end = total - 1;
    if (end < start) end = start;

    if (start >= total) {
      res.statusCode = HttpStatus.requestedRangeNotSatisfiable;
      res.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$total');
      await res.close();
      return;
    }

    final length = (end - start) + 1;
    if (start > 0 || end < total - 1) {
      res.statusCode = HttpStatus.partialContent;
      res.headers.set(HttpHeaders.contentRangeHeader,
          'bytes $start-$end/$total');
    } else {
      res.statusCode = HttpStatus.ok;
    }
    res.headers.set(HttpHeaders.contentLengthHeader, length.toString());

    if (request.method == 'HEAD') {
      await res.close();
      return;
    }

    // 流式发送，避免整文件读入内存
    await res.addStream(
      file.openRead(start, start + length).map((chunk) => chunk),
    );
    await res.close();
  }

  Future<void> stop() async {
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
    _file = null;
    _port = 0;
  }
}

/// 从 ConnectionService 拿到的本机 IPv4 里挑一个给投屏地址用。
String pickLanHost(List<String> candidates) {
  for (final c in candidates) {
    if (c.startsWith('127.')) continue;
    return c;
  }
  return candidates.isNotEmpty ? candidates.first : '127.0.0.1';
}

/// 从文件名猜 DLNA 投屏标题。
String dlnaTitleFromPath(String filePath) {
  try {
    var name = filePath;
    final slash = name.lastIndexOf(RegExp(r'[/\\]'));
    if (slash >= 0) name = name.substring(slash + 1);
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);
    return name.isEmpty ? filePath : name;
  } catch (_) {
    return filePath;
  }
}
