// lib/services/webdav_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';
import 'network_settings_service.dart';
import '../l10n/l10n_helper.dart';

/// 单次备份结果
class BackupResult {
  final int totalFiles;
  final int successCount;
  final int failCount;
  final List<String> errors;

  BackupResult({
    required this.totalFiles,
    required this.successCount,
    required this.failCount,
    required this.errors,
  });

  bool get allSuccess => failCount == 0 && totalFiles > 0;
}

/// 远程文件条目
class RemoteFileEntry {
  final String name;
  final String path;
  final int size;
  final bool isDirectory;
  final DateTime? lastModified;

  RemoteFileEntry({
    required this.name,
    required this.path,
    required this.size,
    required this.isDirectory,
    this.lastModified,
  });

  bool get isVideo {
    final ext = name.split('.').last.toLowerCase();
    return [
      'mp4', 'mkv', 'avi', 'mov', 'flv', 'wmv', 'webm',
      'ts', 'm4v', 'mpg', 'mpeg', '3gp', 'ogv',
    ].contains(ext);
  }

  bool get isSubtitle {
    final ext = name.split('.').last.toLowerCase();
    return ['srt', 'ass', 'ssa', 'vtt', 'sub', 'idx', 'sup'].contains(ext);
  }

  bool get isAudio {
    final ext = name.split('.').last.toLowerCase();
    return ['mp3', 'flac', 'aac', 'ogg', 'wav', 'm4a', 'wma'].contains(ext);
  }
}

class WebDavService with ChangeNotifier {
  String _serverUrl = '';
  String _username = '';
  String _password = '';
  bool _enabled = false;
  String _remoteBasePath = '/navi_backup';
  bool _isUploading = false;
  String _lastError = '';
  DateTime? _lastSyncTime;

  Set<String> _backupContactIPs = {};

//  新增：播放列表 / 弹幕云同步设置（独立于聊天备份目录）
  bool _syncPlaylists = false;
  bool _syncDanmaku = false;
  DateTime? _playlistsLastSync;
  DateTime? _danmakuLastSync;

  /// 播放列表云端加密口令（空 = 不加密，明文上传）。
  String _syncPassphrase = '';

  bool _isBatchBackingUp = false;
  double _batchProgress = 0.0;
  String _batchStatusText = '';
  int _batchTotal = 0;
  int _batchDone = 0;

  bool get serverUsesHttps {
    try {
      return Uri.parse(_serverUrl).scheme == 'https';
    } catch (_) {
      return false;
    }
  }

  String get serverUrl => _serverUrl;
  String get username => _username;
  String get password => _password;
  bool get enabled => _enabled;
  String get remoteBasePath => _remoteBasePath;
  bool get isUploading => _isUploading;
  String get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isConfigured => _serverUrl.isNotEmpty && _username.isNotEmpty;
  Set<String> get backupContactIPs => Set.unmodifiable(_backupContactIPs);
  bool get isBatchBackingUp => _isBatchBackingUp;
  double get batchProgress => _batchProgress;
  String get batchStatusText => _batchStatusText;
  int get batchTotal => _batchTotal;
  int get batchDone => _batchDone;

//  播放列表 / 弹幕同步
  bool get syncPlaylists => _syncPlaylists;
  bool get syncDanmaku => _syncDanmaku;
  DateTime? get playlistsLastSync => _playlistsLastSync;
  DateTime? get danmakuLastSync => _danmakuLastSync;
  String get syncPassphrase => _syncPassphrase;
  bool get syncPassphraseEnabled => _syncPassphrase.isNotEmpty;

  /// 播放列表 / 弹幕云同步远程路径（独立于聊天备份的 /chats 目录）。
  String get playlistsRemotePath => '$_remoteBasePath/playlists/playlists.json';

  /// 观看历史云同步远程路径（{base}/watch_history/watch_history.json）。
  /// 复用播放列表同步口令加密，未登录用户也可上传本地观看足迹。
  String get watchHistoryRemotePath =>
      '$_remoteBasePath/watch_history/watch_history.json';
  String get danmakuRemoteDir => '$_remoteBasePath/danmaku';
  String get playlistBackgroundsRemoteDir =>
      '$_remoteBasePath/playlists/backgrounds';

  WebDavService() {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final secure = SecureStorageService();
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      secure.migrateFromPrefs('webdav_server_url', 'webdav_server_url'),
      secure.migrateFromPrefs('webdav_username', 'webdav_username'),
      secure.migrateFromPrefs('webdav_password', 'webdav_password'),
      secure.migrateFromPrefs(
          'webdav_sync_passphrase', 'webdav_sync_passphrase'),
    ]);

    _serverUrl = await secure.read('webdav_server_url') ?? '';
    _username = await secure.read('webdav_username') ?? '';
    _password = await secure.read('webdav_password') ?? '';

    // 同步口令：安全存储优先，备用存储兜底（Windows 读取失败时防丢失）
    _syncPassphrase = await secure.read('webdav_sync_passphrase') ?? '';
    if (_syncPassphrase.isEmpty) {
      _syncPassphrase = prefs.getString('webdav_sync_passphrase_backup') ?? '';
      if (_syncPassphrase.isNotEmpty) {
        await secure.write('webdav_sync_passphrase', _syncPassphrase);
      }
    }

    _enabled = prefs.getBool('webdav_enabled') ?? false;
    _remoteBasePath = prefs.getString('webdav_remote_path') ?? '/navi_backup';

    final syncTs = prefs.getInt('webdav_last_sync');
    if (syncTs != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(syncTs);
    }

    final contactList = prefs.getStringList('webdav_backup_contacts');
    if (contactList != null) {
      _backupContactIPs = contactList.toSet();
    }

    _syncPlaylists = prefs.getBool('webdav_sync_playlists') ?? false;
    _syncDanmaku = prefs.getBool('webdav_sync_danmaku') ?? false;
    final plTs = prefs.getInt('webdav_playlists_last_sync');
    if (plTs != null) {
      _playlistsLastSync = DateTime.fromMillisecondsSinceEpoch(plTs);
    }
    final dmTs = prefs.getInt('webdav_danmaku_last_sync');
    if (dmTs != null) {
      _danmakuLastSync = DateTime.fromMillisecondsSinceEpoch(dmTs);
    }

    notifyListeners();
  }

  Future<void> _saveConfig() async {
    final secure = SecureStorageService();
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      secure.write('webdav_server_url', _serverUrl),
      secure.write('webdav_username', _username),
      secure.write('webdav_password', _password),
      secure.write('webdav_sync_passphrase', _syncPassphrase),
    ]);
    // 备用存储：与 CryptoService 同理，防止安全存储读取失败导致口令丢失
    await prefs.setString('webdav_sync_passphrase_backup', _syncPassphrase);

    await prefs.setBool('webdav_enabled', _enabled);
    await prefs.setString('webdav_remote_path', _remoteBasePath);
    await prefs.setStringList('webdav_backup_contacts', _backupContactIPs.toList());
    if (_lastSyncTime != null) {
      await prefs.setInt('webdav_last_sync', _lastSyncTime!.millisecondsSinceEpoch);
    }

    await prefs.setBool('webdav_sync_playlists', _syncPlaylists);
    await prefs.setBool('webdav_sync_danmaku', _syncDanmaku);
    if (_playlistsLastSync != null) {
      await prefs.setInt(
          'webdav_playlists_last_sync', _playlistsLastSync!.millisecondsSinceEpoch);
    }
    if (_danmakuLastSync != null) {
      await prefs.setInt(
          'webdav_danmaku_last_sync', _danmakuLastSync!.millisecondsSinceEpoch);
    }
  }

  Future<void> setServerUrl(String url) async {
    _serverUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    if (!serverUsesHttps && _serverUrl.isNotEmpty) {
      _lastError = L10n.current.webdavHttpWarning;
      if (kDebugMode) {
        debugPrint('⚠️ WebDAV 安全警告: 服务器使用 HTTP，凭证未加密传输');
      }
    }
    await _saveConfig();
    notifyListeners();
  }

  Future<void> setUsername(String value) async {
    _username = value;
    await _saveConfig();
    notifyListeners();
  }

  Future<void> setPassword(String value) async {
    _password = value;
    await _saveConfig();
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _saveConfig();
    notifyListeners();
  }

  Future<void> setRemoteBasePath(String path) async {
    _remoteBasePath = path.startsWith('/') ? path : '/$path';
    await _saveConfig();
    notifyListeners();
  }

  // ================= 播放列表 / 弹幕同步开关 =================

  Future<void> setSyncPlaylists(bool value) async {
    _syncPlaylists = value;
    await _saveConfig();
    notifyListeners();
  }

  Future<void> setSyncDanmaku(bool value) async {
    _syncDanmaku = value;
    await _saveConfig();
    notifyListeners();
  }

  Future<void> markPlaylistsSynced() async {
    _playlistsLastSync = DateTime.now();
    await _saveConfig();
    notifyListeners();
  }

  Future<void> markDanmakuSynced() async {
    _danmakuLastSync = DateTime.now();
    await _saveConfig();
    notifyListeners();
  }


  /// 设置 / 清空同步口令（空字符串 = 关闭加密）。
  Future<void> setSyncPassphrase(String value) async {
    _syncPassphrase = value.trim();
    await _saveConfig();
    notifyListeners();
  }

  /// 生成高强度随机口令（URL 安全字符，32 位）。
  String generateSyncPassphrase() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
        '-_';
    final random = Random.secure();
    return String.fromCharCodes(List.generate(
        32, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  bool isContactSelected(String ip) => _backupContactIPs.contains(ip);

  Future<void> toggleBackupContact(String ip) async {
    if (_backupContactIPs.contains(ip)) {
      _backupContactIPs.remove(ip);
    } else {
      _backupContactIPs.add(ip);
    }
    await _saveConfig();
    notifyListeners();
  }

  Future<void> selectAllContacts(List<String> ips) async {
    _backupContactIPs = ips.toSet();
    await _saveConfig();
    notifyListeners();
  }

  Future<void> clearSelectedContacts() async {
    _backupContactIPs.clear();
    await _saveConfig();
    notifyListeners();
  }

  Map<String, String> _authHeaders() {
    final credentials = base64Encode(utf8.encode('$_username:$_password'));
    final headers = {'Authorization': 'Basic $credentials'};
    final ua = NetworkSettingsService.instance.userAgent;
    if (ua.isNotEmpty) headers['User-Agent'] = ua;
    return headers;
  }

///  修复：构建 URL 时对路径段正确编码
  String _buildUrl(String remotePath) {
    final path = remotePath.startsWith('/') ? remotePath : '/$remotePath';
    final encoded = _encodePath(path);
    return '$_serverUrl$encoded';
  }

///  新增：对路径进行安全编码（保留 '/' 分隔符，编码每段中的特殊字符）
  String _encodePath(String path) {
    return path
        .split('/')
        .map((segment) => Uri.encodeComponent(segment))
        .join('/');
  }

  Future<bool> testConnection() async {
    if (_serverUrl.isEmpty || _username.isEmpty) {
      _lastError = L10n.current.webdavConfigRequired;
      notifyListeners();
      return false;
    }
    try {
      final url = _buildUrl(_remoteBasePath);
      final request = http.Request('OPTIONS', Uri.parse(url));
      request.headers.addAll(_authHeaders());
      final streamedResponse = await request.send().timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 405) {
        _lastError = '';
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        _lastError = L10n.current.webdavAuthFailed;
        notifyListeners();
        return false;
      } else {
        _lastError = L10n.current.webdavConnectFailed(response.statusCode);
        notifyListeners();
        return false;
      }
    } on SocketException catch (e) {
      _lastError = L10n.current.webdavNetworkError('${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _lastError = L10n.current.webdavUnknownError('$e');
      notifyListeners();
      return false;
    }
  }

  Future<void> _ensureRemoteDir(String remotePath) async {
    final segments = remotePath.split('/').where((s) => s.isNotEmpty).toList();
    String currentPath = '';
    for (final segment in segments) {
      currentPath += '/$segment';
      final url = _buildUrl(currentPath);
      try {
        final request = http.Request('MKCOL', Uri.parse(url));
        request.headers.addAll(_authHeaders());
        final streamedResponse = await request.send().timeout(const Duration(seconds: 10));
        await http.Response.fromStream(streamedResponse);
      } catch (e) {
        if (kDebugMode) print('⚠️ MKCOL $currentPath: $e');
      }
    }
  }

  Future<bool> uploadFile(String localFilePath, String remoteSubPath) async {
    if (!isConfigured) {
      _lastError = L10n.current.webdavNotConfigured;
      return false;
    }
    final file = File(localFilePath);
    if (!await file.exists()) {
      _lastError = L10n.current.webdavLocalFileMissing(localFilePath);
      return false;
    }

    _isUploading = true;
    _lastError = '';
    notifyListeners();

    try {
      final remotePath = '$_remoteBasePath$remoteSubPath';
      final dirPath = remotePath.substring(0, remotePath.lastIndexOf('/'));
      await _ensureRemoteDir(dirPath);

      final url = _buildUrl(remotePath);
      final bytes = await file.readAsBytes();

      final request = http.Request('PUT', Uri.parse(url));
      request.headers.addAll(_authHeaders());
      request.headers['Content-Type'] = 'application/octet-stream';
      request.bodyBytes = bytes;

      final streamedResponse = await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        _lastSyncTime = DateTime.now();
        await _saveConfig();
        return true;
      } else {
        _lastError = L10n.current.webdavUploadFailed(response.statusCode);
        return false;
      }
    } catch (e) {
      _lastError = L10n.current.webdavUploadError('$e');
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// 单文件自动备份（接收文件时调用）
  Future<bool> backupChatFile({
    required String localFilePath,
    required String nickname,
    required String fileName,
  }) async {
    if (!_enabled || !isConfigured) return false;
    final safeName = nickname.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final remoteSubPath = '/chats/$safeName/$fileName';
    return uploadFile(localFilePath, remoteSubPath);
  }

  // ================= 通用字节级上传 / 下载（云同步用） =================

  /// 上传字节内容到远端路径（自动创建父目录）。
  Future<bool> uploadBytes(String remoteSubPath, List<int> bytes) async {
    if (!isConfigured) {
      _lastError = L10n.current.webdavNotConfigured;
      return false;
    }
    _lastError = '';
    try {
      final remotePath = '$_remoteBasePath$remoteSubPath';
      final dirPath = remotePath.substring(0, remotePath.lastIndexOf('/'));
      await _ensureRemoteDir(dirPath);

      final url = _buildUrl(remotePath);
      final request = http.Request('PUT', Uri.parse(url));
      request.headers.addAll(_authHeaders());
      request.headers['Content-Type'] = 'application/octet-stream';
      request.bodyBytes = bytes;

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return true;
      }
      _lastError = L10n.current.webdavUploadFailed(response.statusCode);
      return false;
    } catch (e) {
      _lastError = L10n.current.webdavUploadError('$e');
      return false;
    }
  }

  /// 下载远端文件内容；不存在或失败时返回 null。
  Future<Uint8List?> downloadBytes(String remotePath) async {
    if (!isConfigured) return null;
    try {
      final url = _buildUrl(remotePath);
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(_authHeaders());
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        if (response.statusCode == 404) return null;
        _lastError = L10n.current.webdavDownloadFailed(response.statusCode);
        return null;
      }
      return response.bodyBytes;
    } catch (e) {
      _lastError = L10n.current.webdavDownloadError('$e');
      return null;
    }
  }

  /// 删除远端文件（404 视为成功）。
  Future<bool> deleteRemote(String remotePath) async {
    if (!isConfigured) return false;
    try {
      final url = _buildUrl(remotePath);
      final request = http.Request('DELETE', Uri.parse(url));
      request.headers.addAll(_authHeaders());
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 204 ||
          response.statusCode == 200 ||
          response.statusCode == 404;
    } catch (e) {
      _lastError = L10n.current.webdavDeleteFailed('$e');
      return false;
    }
  }

  Future<BackupResult> backupFilesBatch(
    List<Map<String, String>> files,
  ) async {
    if (!isConfigured) {
      return BackupResult(totalFiles: 0, successCount: 0, failCount: 0, errors: [L10n.current.webdavNotConfigured]);
    }

    _isBatchBackingUp = true;
    _batchTotal = files.length;
    _batchDone = 0;
    _batchProgress = 0.0;
    _batchStatusText = L10n.current.webdavPreparingBackup(files.length);
    notifyListeners();

    int success = 0;
    int fail = 0;
    final errors = <String>[];

    for (int i = 0; i < files.length; i++) {
      final f = files[i];
      final localPath = f['localPath']!;
      final nickname = f['nickname']!;
      final fileName = f['fileName']!;

      _batchStatusText = L10n.current.webdavBackingUp(nickname, fileName);
      _batchProgress = i / files.length;
      notifyListeners();

      final safeName = nickname.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final remoteSubPath = '/chats/$safeName/$fileName';
      final ok = await uploadFile(localPath, remoteSubPath);

      if (ok) {
        success++;
      } else {
        fail++;
        errors.add('$fileName: $_lastError');
      }

      _batchDone = i + 1;
      _batchProgress = (i + 1) / files.length;
      notifyListeners();
    }

    _isBatchBackingUp = false;
    _batchProgress = 1.0;
    _batchStatusText = L10n.current.webdavBackupDone(success, fail);
    _lastSyncTime = DateTime.now();
    await _saveConfig();
    notifyListeners();

    return BackupResult(
      totalFiles: files.length,
      successCount: success,
      failCount: fail,
      errors: errors,
    );
  }

  void resetBatchStatus() {
    _isBatchBackingUp = false;
    _batchProgress = 0.0;
    _batchStatusText = '';
    _batchTotal = 0;
    _batchDone = 0;
    notifyListeners();
  }

// =================  远程文件浏览（播放器用） =================

  /// 列出远程目录下的文件和文件夹
  Future<List<RemoteFileEntry>> listFiles(String remotePath) async {
    if (!isConfigured) {
      _lastError = L10n.current.webdavNotConfigured;
      notifyListeners();
      return [];
    }

    try {
      final url = _buildUrl(remotePath);
      final request = http.Request('PROPFIND', Uri.parse(url));
      request.headers.addAll(_authHeaders());
      request.headers['Depth'] = '1';
      request.headers['Content-Type'] = 'application/xml; charset=utf-8';
      request.body = '''<?xml version="1.0" encoding="utf-8"?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:displayname/>
    <D:getcontentlength/>
    <D:getlastmodified/>
    <D:resourcetype/>
  </D:prop>
</D:propfind>''';

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 207) {
        _lastError = L10n.current.webdavPropfindFailed(response.statusCode);
        notifyListeners();
        return [];
      }

      return _parsePropfindResponse(response.body, remotePath);
    } on SocketException catch (e) {
      _lastError = L10n.current.webdavNetworkErr('${e.message}');
      notifyListeners();
      return [];
    } catch (e) {
      _lastError = L10n.current.webdavListFailed('$e');
      notifyListeners();
      return [];
    }
  }

///  修复：解析 PROPFIND XML 响应
  List<RemoteFileEntry> _parsePropfindResponse(String xml, String basePath) {
    final entries = <RemoteFileEntry>[];

    final responsePattern = RegExp(r'<[Dd]:response>(.*?)</[Dd]:response>', dotAll: true);
    final hrefPattern = RegExp(r'<[Dd]:href>(.*?)</[Dd]:href>', dotAll: true);
    final displayPattern = RegExp(r'<[Dd]:displayname>(.*?)</[Dd]:displayname>', dotAll: true);
    final lengthPattern = RegExp(r'<[Dd]:getcontentlength>(.*?)</[Dd]:getcontentlength>', dotAll: true);
    final modifiedPattern = RegExp(r'<[Dd]:getlastmodified>(.*?)</[Dd]:getlastmodified>', dotAll: true);
    final collectionPattern = RegExp(r'<[Dd]:collection', dotAll: true);

    for (final match in responsePattern.allMatches(xml)) {
      final block = match.group(1)!;

      final hrefMatch = hrefPattern.firstMatch(block);
      if (hrefMatch == null) continue;

      final rawHref = hrefMatch.group(1)!.trim();
      final decodedHref = Uri.decodeFull(rawHref);
      final mountPath = Uri.decodeFull(Uri.parse(_serverUrl).path); // 如 "/webdav" 或 ""
      String href = decodedHref;
      if (mountPath.isNotEmpty &&
          (href == mountPath || href.startsWith('$mountPath/'))) {
        href = href.substring(mountPath.length);
        if (href.isEmpty) href = '/';
      }

      // 跳过自身目录条目（现在 href 与 basePath 同坐标系，判断才真正生效）
      final normalizedBase = basePath.endsWith('/') ? basePath : '$basePath/';
      final normalizedHref = href.endsWith('/') ? href : '$href/';
      if (normalizedHref == normalizedBase || href == basePath) continue;

      final isDir = collectionPattern.hasMatch(block);

      final nameMatch = displayPattern.firstMatch(block);
      final lengthMatch = lengthPattern.firstMatch(block);
      final modifiedMatch = modifiedPattern.firstMatch(block);

      final name = nameMatch?.group(1)?.trim() ??
          href.split('/').where((s) => s.isNotEmpty).lastOrNull ??
          href;

      final size = int.tryParse(lengthMatch?.group(1)?.trim() ?? '0') ?? 0;

      DateTime? lastModified;
      if (modifiedMatch != null) {
        try {
          lastModified = HttpDate.parse(modifiedMatch.group(1)!.trim());
        } catch (_) {}
      }

      entries.add(RemoteFileEntry(
        name: name,
        path: href,
        size: size,
        isDirectory: isDir,
        lastModified: lastModified,
      ));
    }

    // 目录在前，文件在后，同类按名称排序
    entries.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return entries;
  }

///  获取文件的完整流式访问 URL（不带认证，需配合 headers 使用）
  String getFileStreamUrl(String remotePath) {
    final path = remotePath.startsWith('/') ? remotePath : '/$remotePath';
    final encoded = _encodePath(path);
    return '$_serverUrl$encoded';
  }

  /// 生成带内嵌认证的 URL —— 仅 HTTPS 时嵌入凭证，HTTP 时仅拼接路径。
  /// HTTP 调用方应使用 getAuthHeaders() 替代。
  String getAuthenticatedUrl(String remotePath) {
    final path = remotePath.startsWith('/') ? remotePath : '/$remotePath';
    final encoded = _encodePath(path);

    if (!serverUsesHttps) {
      if (kDebugMode) {
        debugPrint('⚠️ WebDAV 凭证未嵌入 HTTP URL，请使用 getAuthHeaders()');
      }
      return '$_serverUrl$encoded';
    }

    final uri = Uri.parse(_serverUrl);
    final encodedUser = Uri.encodeComponent(_username);
    final encodedPass = Uri.encodeComponent(_password);
    final authenticatedBase = uri.replace(userInfo: '$encodedUser:$encodedPass');
    return '$authenticatedBase$encoded';
  }

  /// 获取带 Basic Auth 的 HTTP headers（供 media_kit / http 使用）
  Map<String, String> getAuthHeaders() {
    final credentials = base64Encode(utf8.encode('$_username:$_password'));
    return {'Authorization': 'Basic $credentials'};
  }

  /// 列出指定路径下的视频文件（含子文件夹）
  Future<List<RemoteFileEntry>> listVideoFiles([String? subPath]) async {
    final targetPath = subPath ?? '$_remoteBasePath/videos';
    final allFiles = await listFiles(targetPath);
    return allFiles.where((f) => f.isVideo || f.isDirectory).toList();
  }

  /// 列出指定路径下的字幕文件
  Future<List<RemoteFileEntry>> listSubtitleFiles([String? subPath]) async {
    final targetPath = subPath ?? '$_remoteBasePath/subtitles';
    final allFiles = await listFiles(targetPath);
    return allFiles.where((f) => f.isSubtitle).toList();
  }

  /// 列出指定路径下的所有媒体文件（视频 + 音频）
  Future<List<RemoteFileEntry>> listMediaFiles([String? subPath]) async {
    final targetPath = subPath ?? '$_remoteBasePath/media';
    final allFiles = await listFiles(targetPath);
    return allFiles.where((f) => f.isVideo || f.isAudio || f.isDirectory).toList();
  }

  /// 下载远程文件到本地临时目录（用于字幕等小文件）
  Future<File?> downloadToTemp(String remotePath, {String? fileName}) async {
    if (!isConfigured) return null;
    try {
      final url = _buildUrl(remotePath);
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(_authHeaders());
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        _lastError = L10n.current.webdavDownloadFailed(response.statusCode);
        notifyListeners();
        return null;
      }

      final name = fileName ?? remotePath.split('/').last;
      final tempDir = await _getTempDir();
      final file = File('${tempDir.path}/webdav_$name');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      _lastError = L10n.current.webdavDownloadError('$e');
      notifyListeners();
      return null;
    }
  }

  Future<Directory> _getTempDir() async {
    final dir = Directory.systemTemp;
    final naviDir = Directory('${dir.path}/navi_webdav');
    if (!await naviDir.exists()) {
      await naviDir.create(recursive: true);
    }
    return naviDir;
  }

  Future<void> clearConfig() async {
    _serverUrl = '';
    _username = '';
    _password = '';
    _enabled = false;
    _remoteBasePath = '/navi_backup';
    _lastSyncTime = null;
    _lastError = '';
    _backupContactIPs.clear();

    final secure = SecureStorageService();
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      secure.delete('webdav_server_url'),
      secure.delete('webdav_username'),
      secure.delete('webdav_password'),
      secure.delete('webdav_sync_passphrase'),
    ]);

    await Future.wait([
      prefs.remove('webdav_enabled'),
      prefs.remove('webdav_remote_path'),
      prefs.remove('webdav_last_sync'),
      prefs.remove('webdav_backup_contacts'),
      prefs.remove('webdav_sync_playlists'),
      prefs.remove('webdav_sync_danmaku'),
      prefs.remove('webdav_playlists_last_sync'),
      prefs.remove('webdav_danmaku_last_sync'),
      prefs.remove('webdav_sync_passphrase_backup'),
    ]);

    notifyListeners();
  }
}