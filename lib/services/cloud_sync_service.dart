// lib/services/cloud_sync_service.dart
//
// 播放列表 / 弹幕云同步服务（基于 WebDAV）：
// - 远程目录与聊天备份分离：{base}/playlists/ 与 {base}/danmaku/
// - 多设备共用同一路径即可互相合并（播放列表按 id + updatedAt 合并，
//   弹幕按文件逐个比较修改时间取新者）
// - 播放列表支持「双向同步」「从云端恢复」「上传到云端」
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/danmaku/danmaku_fetcher.dart';
import 'playlist_cipher.dart';
import 'playlist_service.dart';
import 'watch_history_service.dart';
import 'webdav_service.dart';
import '../l10n/l10n_helper.dart';

/// 一次同步的结果汇总。
class CloudSyncResult {
  final String what;
  final int uploaded;
  final int downloaded;
  final int mergedOrRestored;
  final int failed;
  final String message;

  const CloudSyncResult({
    required this.what,
    required this.uploaded,
    required this.downloaded,
    required this.mergedOrRestored,
    required this.failed,
    required this.message,
  });

  bool get ok => failed == 0;
}

class CloudSyncService {
  final WebDavService webdav;
  final PlaylistService playlists;

  CloudSyncService({required this.webdav, required this.playlists});

  // ═════════════════════════════════════════
  //  播放列表同步
  // ═════════════════════════════════════════

  /// 双向同步：下载云端 → 与本地合并 → 上传合并结果。
  /// [restoreFromCloud] 为 true 时用云端整体覆盖本地（从云端恢复）。
  Future<CloudSyncResult> syncPlaylists({
    bool restoreFromCloud = false,
  }) async {
    if (!webdav.isConfigured) {
      return CloudSyncResult(
        what: L10n.current.csPlaylists,
        uploaded: 0,
        downloaded: 0,
        mergedOrRestored: 0,
        failed: 1,
        message: L10n.current.webdavNotConfigured,
      );
    }

    try {
      final remoteBytes =
          await webdav.downloadBytes(webdav.playlistsRemotePath);

      // 下载内容解码：优先解密（口令启用时），兼容云端旧明文
      String? remoteJson;
      if (remoteBytes != null) {
        final raw = utf8.decode(remoteBytes, allowMalformed: true);
        if (PlaylistCipher.isEncrypted(raw)) {
          if (!webdav.syncPassphraseEnabled) {
            return CloudSyncResult(
              what: L10n.current.csPlaylists,
              uploaded: 0,
              downloaded: 0,
              mergedOrRestored: 0,
              failed: 1,
              message: L10n.current.csCloudEncrypted,
            );
          }
          try {
            remoteJson =
                await PlaylistCipher.decrypt(raw, webdav.syncPassphrase);
          } catch (e) {
            return CloudSyncResult(
              what: L10n.current.csPlaylists,
              uploaded: 0,
              downloaded: 0,
              mergedOrRestored: 0,
              failed: 1,
              message: L10n.current.csCloudPassMismatch,
            );
          }
        } else {
          remoteJson = raw; // 兼容旧版明文
        }
      }
      final localJson = playlists.exportJson();

      int merged = 0;
      int bgUploaded = 0;
      int bgDownloaded = 0;
      if (restoreFromCloud) {
        if (remoteJson == null) {
          return CloudSyncResult(
            what: L10n.current.csPlaylists,
            uploaded: 0,
            downloaded: 0,
            mergedOrRestored: 0,
            failed: 1,
            message: L10n.current.csCloudNoFile,
          );
        }
        merged = await playlists.replaceFromJson(remoteJson);
        bgDownloaded = await _downloadBackgrounds();
      } else if (remoteJson != null) {
        final stat = await playlists.mergeFromJson(remoteJson);
        merged = stat.added + stat.updated;
        // 合并后：先补齐缺失的背景图，再上传本机背景图
        bgDownloaded = await _downloadBackgrounds();
        bgUploaded = await _uploadBackgrounds();
      } else {
        // 云端还没有文件：直接上传本机背景图 + 全量列表
        bgUploaded = await _uploadBackgrounds();
      }

      // 上传：口令启用时加密后再上传
      final uploadData = webdav.syncPassphraseEnabled
          ? utf8.encode(await PlaylistCipher.encrypt(
              playlists.exportJson(), webdav.syncPassphrase))
          : utf8.encode(playlists.exportJson());
      final ok = await webdav.uploadBytes('/playlists/playlists.json', uploadData);
      if (!ok) {
        return CloudSyncResult(
          what: L10n.current.csPlaylists,
          uploaded: 0,
          downloaded: remoteBytes == null ? 0 : 1,
          mergedOrRestored: merged,
          failed: 1,
          message: webdav.lastError,
        );
      }

      await webdav.markPlaylistsSynced();
      final action = restoreFromCloud
          ? L10n.current.csRestoredFromCloud
          : L10n.current.csSyncDone;
      final bgParts = <String>[];
      if (bgUploaded > 0) bgParts.add(L10n.current.csUploadBgCount(bgUploaded));
      if (bgDownloaded > 0) {
        bgParts.add(L10n.current.csDownloadBgCount(bgDownloaded));
      }
      final parts = <String>[
        '$action：${L10n.current.csUploadedFileCount(1)}',
      ];
      if (remoteBytes != null) {
        parts.add(L10n.current.csDownloadedFileCount(1));
      }
      if (merged > 0) parts.add(L10n.current.csMergedListsCount(merged));
      parts.addAll(bgParts);
      if (webdav.syncPassphraseEnabled) parts.add(L10n.current.csEncrypted);
      return CloudSyncResult(
        what: L10n.current.csPlaylists,
        uploaded: 1,
        downloaded: remoteBytes == null ? 0 : 1,
        mergedOrRestored: merged,
        failed: 0,
        message: parts.join('，'),
      );
    } catch (e) {
      debugPrint('播放列表同步失败: $e');
      return CloudSyncResult(
        what: L10n.current.csPlaylists,
        uploaded: 0,
        downloaded: 0,
        mergedOrRestored: 0,
        failed: 1,
        message: L10n.current.csSyncFailed('$e'),
      );
    }
  }

  /// 仅上传到云端（不上传时不下载不合并）。
  Future<CloudSyncResult> pushPlaylists() async {
    if (!webdav.isConfigured) {
      return CloudSyncResult(
        what: L10n.current.csPlaylists,
        uploaded: 0,
        downloaded: 0,
        mergedOrRestored: 0,
        failed: 1,
        message: L10n.current.webdavNotConfigured,
      );
    }
    final bgUploaded = await _uploadBackgrounds();
    final uploadData = webdav.syncPassphraseEnabled
        ? utf8.encode(await PlaylistCipher.encrypt(
            playlists.exportJson(), webdav.syncPassphrase))
        : utf8.encode(playlists.exportJson());
    final ok = await webdav.uploadBytes(
      '/playlists/playlists.json',
      uploadData,
    );
    if (!ok) {
      return CloudSyncResult(
        what: L10n.current.csPlaylists,
        uploaded: 0,
        downloaded: 0,
        mergedOrRestored: 0,
        failed: 1,
        message: webdav.lastError,
      );
    }
    await webdav.markPlaylistsSynced();
    final msg = StringBuffer(
        L10n.current.csUploadedPlaylists(playlists.playlists.length));
    if (bgUploaded > 0) {
      msg.write('，${L10n.current.csUploadBgCount(bgUploaded)}');
    }
    return CloudSyncResult(
      what: L10n.current.csPlaylists,
      uploaded: 1,
      downloaded: 0,
      mergedOrRestored: 0,
      failed: 0,
      message: msg.toString(),
    );
  }

  // ═════════════════════════════════════════
  //  播放列表背景图同步
  // ═════════════════════════════════════════

  /// 上传所有本地存在的背景图（文件名 = {播放列表id}{扩展名}）。
  Future<int> _uploadBackgrounds() async {
    int n = 0;
    for (final p in playlists.playlists) {
      final bg = p.backgroundPath;
      if (bg == null || bg.isEmpty) continue;
      final f = File(bg);
      if (!await f.exists()) continue;
      final name = '${p.id}${_extOf(bg)}';
      final ok = await webdav.uploadBytes(
        '/playlists/backgrounds/$name',
        await f.readAsBytes(),
      );
      if (ok) n++;
    }
    return n;
  }

  /// 下载缺失的背景图：远端按列表 id 匹配，本地不存在时下载并更新
  /// backgroundPath（远端记录的路径在另一台设备上无效）。
  Future<int> _downloadBackgrounds() async {
    int n = 0;
    try {
      final remoteFiles =
          await webdav.listFiles(webdav.playlistBackgroundsRemoteDir);
      if (remoteFiles.isEmpty) return 0;

      final docs = await getApplicationDocumentsDirectory();
      final bgDir = Directory('${docs.path}/playlist_backgrounds');

      for (final f in remoteFiles) {
        if (f.isDirectory) continue;
        final dot = f.name.lastIndexOf('.');
        final id = dot > 0 ? f.name.substring(0, dot) : f.name;
        final p = playlists.findById(id);
        if (p == null) continue;
        // 本机已有该背景图 → 跳过
        final bg = p.backgroundPath;
        if (bg != null && bg.isNotEmpty && File(bg).existsSync()) continue;

        final bytes = await webdav
            .downloadBytes('${webdav.playlistBackgroundsRemoteDir}/${f.name}');
        if (bytes == null) continue;
        if (!await bgDir.exists()) {
          await bgDir.create(recursive: true);
        }
        final localPath = '${bgDir.path}/bg_sync_${f.name}';
        await File(localPath).writeAsBytes(bytes);
        await playlists.setBackgroundPath(id, localPath);
        n++;
      }
    } catch (e) {
      debugPrint('背景图下载失败: $e');
    }
    return n;
  }

  /// 取文件扩展名（含点，小写）；无扩展名时默认 .jpg。
  String _extOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot <= 0 || dot == path.length - 1) return '.jpg';
    return path.substring(dot).toLowerCase();
  }

  // ═════════════════════════════════════════
  //  弹幕同步
  // ═════════════════════════════════════════

  /// 双向同步弹幕缓存：逐个文件比较修改时间，取新者。
  Future<CloudSyncResult> syncDanmaku() async {
    if (!webdav.isConfigured) {
      return CloudSyncResult(
        what: L10n.current.csDanmaku,
        uploaded: 0,
        downloaded: 0,
        mergedOrRestored: 0,
        failed: 1,
        message: L10n.current.webdavNotConfigured,
      );
    }

    int uploaded = 0;
    int downloaded = 0;
    int failed = 0;
    final errors = <String>[];

    try {
      // 远端文件清单（name → lastModified）
      final remoteFiles = await webdav.listFiles(webdav.danmakuRemoteDir);
      final remoteByName = <String, RemoteFileEntry>{};
      for (final f in remoteFiles) {
        if (!f.isDirectory) remoteByName[f.name] = f;
      }

      // 本地文件清单（name → File）
      final localFiles = <String, File>{
        for (final f in await DanmakuCacheManager.listCachedFiles())
          f.uri.pathSegments.last: f,
      };

      // 1) 上传：本地有而远端没有 / 本地比远端新 → 上传覆盖
      for (final entry in localFiles.entries) {
        final name = entry.key;
        final localFile = entry.value;
        final remote = remoteByName[name];
        if (remote != null &&
            remote.lastModified != null &&
            remote.lastModified!.isAfter(await _fileModified(localFile))) {
          continue; // 远端更新，跳过上传（走下载）
        }
        final bytes = await localFile.readAsBytes();
        final ok =
            await webdav.uploadBytes('/danmaku/$name', bytes);
        if (ok) {
          uploaded++;
        } else {
          failed++;
          errors.add('$name: ${webdav.lastError}');
        }
      }

      // 2) 下载：远端有而本地没有 / 远端比本地新 → 下载覆盖
      for (final entry in remoteByName.entries) {
        final name = entry.key;
        if (!name.endsWith('.json')) continue;
        final remote = entry.value;
        final localFile = localFiles[name];
        if (localFile != null &&
            remote.lastModified != null &&
            !remote.lastModified!.isAfter(await _fileModified(localFile))) {
          continue; // 本地更新或相同，跳过
        }
        final bytes = await webdav.downloadBytes('${webdav.danmakuRemoteDir}/$name');
        if (bytes == null) {
          failed++;
          errors.add('$name: ${webdav.lastError}');
          continue;
        }
        try {
          final dir = await DanmakuCacheManager.cacheDir;
          final target = File('${dir.path}/$name');
          await target.writeAsBytes(bytes);
          downloaded++;
        } catch (e) {
          failed++;
          errors.add('$name: $e');
        }
      }

      await webdav.markDanmakuSynced();
      final msg = StringBuffer(L10n.current.csDanmakuSummary(uploaded, downloaded));
      if (failed > 0) {
        msg.write(
            L10n.current.csDanmakuFailed(failed, errors.take(2).join('；')));
      }
      return CloudSyncResult(
        what: L10n.current.csDanmaku,
        uploaded: uploaded,
        downloaded: downloaded,
        mergedOrRestored: 0,
        failed: failed,
        message: msg.toString(),
      );
    } catch (e) {
      debugPrint('弹幕同步失败: $e');
      return CloudSyncResult(
        what: L10n.current.csDanmaku,
        uploaded: uploaded,
        downloaded: downloaded,
        mergedOrRestored: 0,
        failed: 1,
        message: L10n.current.csSyncFailed('$e'),
      );
    }
  }

  Future<DateTime> _fileModified(File file) async {
    try {
      return (await file.stat()).modified;
    } catch (_) {
      return DateTime(2000);
    }
  }

  // ═════════════════════════════════════════
  //  观看历史同步（未登录用户也可上传本地足迹到 WebDAV）
  // ═════════════════════════════════════════

  /// 双向同步观看历史：下载云端 → 与本地合并 → 上传合并结果。
  /// [restoreFromCloud] 为 true 时用云端整体覆盖本地（从云端恢复）。
  /// 复用播放列表同步口令加密；多端按 bvid+cid 去重、watchedAt 取新者。
  Future<CloudSyncResult> syncWatchHistory(
    WatchHistoryService wh, {
    bool restoreFromCloud = false,
  }) async {
    if (!webdav.isConfigured) {
      return CloudSyncResult(
        what: '观看历史',
        uploaded: 0,
        downloaded: 0,
        mergedOrRestored: 0,
        failed: 1,
        message: L10n.current.webdavNotConfigured,
      );
    }
    try {
      final remoteBytes =
          await webdav.downloadBytes(webdav.watchHistoryRemotePath);

      // 下载内容解码：优先解密（口令启用时），兼容云端旧明文
      String? remoteJson;
      if (remoteBytes != null) {
        final raw = utf8.decode(remoteBytes, allowMalformed: true);
        if (PlaylistCipher.isEncrypted(raw)) {
          if (!webdav.syncPassphraseEnabled) {
            return CloudSyncResult(
              what: '观看历史',
              uploaded: 0,
              downloaded: 0,
              mergedOrRestored: 0,
              failed: 1,
              message: L10n.current.csCloudEncrypted,
            );
          }
          try {
            remoteJson =
                await PlaylistCipher.decrypt(raw, webdav.syncPassphrase);
          } catch (_) {
            return CloudSyncResult(
              what: '观看历史',
              uploaded: 0,
              downloaded: 0,
              mergedOrRestored: 0,
              failed: 1,
              message: L10n.current.csCloudPassMismatch,
            );
          }
        } else {
          remoteJson = raw; // 兼容旧版明文
        }
      }

      int merged = 0;
      if (restoreFromCloud) {
        if (remoteJson == null) {
          return CloudSyncResult(
            what: '观看历史',
            uploaded: 0,
            downloaded: 0,
            mergedOrRestored: 0,
            failed: 1,
            message: L10n.current.csCloudNoFile,
          );
        }
        merged = await wh.replaceFromJson(remoteJson);
      } else if (remoteJson != null) {
        final stat = await wh.mergeFromJson(remoteJson);
        merged = stat.total;
      }

      // 上传：口令启用时加密后再上传
      final uploadData = webdav.syncPassphraseEnabled
          ? utf8.encode(await PlaylistCipher.encrypt(
              wh.exportJson(), webdav.syncPassphrase))
          : utf8.encode(wh.exportJson());
      final ok = await webdav.uploadBytes(
        '/watch_history/watch_history.json',
        uploadData,
      );
      if (!ok) {
        return CloudSyncResult(
          what: '观看历史',
          uploaded: 0,
          downloaded: remoteBytes == null ? 0 : 1,
          mergedOrRestored: merged,
          failed: 1,
          message: webdav.lastError,
        );
      }
      final action =
          restoreFromCloud ? '已从云端恢复' : '观看历史同步完成';
      return CloudSyncResult(
        what: '观看历史',
        uploaded: 1,
        downloaded: remoteBytes == null ? 0 : 1,
        mergedOrRestored: merged,
        failed: 0,
        message: '$action${merged > 0 ? '，合并 $merged 条' : ''}'
            '${webdav.syncPassphraseEnabled ? '，已加密' : ''}',
      );
    } catch (e) {
      debugPrint('观看历史同步失败: $e');
      return CloudSyncResult(
        what: '观看历史',
        uploaded: 0,
        downloaded: 0,
        mergedOrRestored: 0,
        failed: 1,
        message: L10n.current.csSyncFailed('$e'),
      );
    }
  }

  /// 仅上传观看历史到云端（不下载不合并）。
  Future<CloudSyncResult> pushWatchHistory(WatchHistoryService wh) async {
    if (!webdav.isConfigured) {
      return CloudSyncResult(
        what: '观看历史',
        uploaded: 0,
        downloaded: 0,
        mergedOrRestored: 0,
        failed: 1,
        message: L10n.current.webdavNotConfigured,
      );
    }
    final uploadData = webdav.syncPassphraseEnabled
        ? utf8.encode(await PlaylistCipher.encrypt(
            wh.exportJson(), webdav.syncPassphrase))
        : utf8.encode(wh.exportJson());
    final ok = await webdav.uploadBytes(
      '/watch_history/watch_history.json',
      uploadData,
    );
    if (!ok) {
      return CloudSyncResult(
        what: '观看历史',
        uploaded: 0,
        downloaded: 0,
        mergedOrRestored: 0,
        failed: 1,
        message: webdav.lastError,
      );
    }
    return CloudSyncResult(
      what: '观看历史',
      uploaded: 1,
      downloaded: 0,
      mergedOrRestored: 0,
      failed: 0,
      message: '已上传 ${wh.entries.length} 条观看历史'
          '${webdav.syncPassphraseEnabled ? '，已加密' : ''}',
    );
  }
}
