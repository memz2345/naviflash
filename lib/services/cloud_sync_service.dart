                                       
  
                             
                                                    
                                             
                      
                               
                                                  
                                              
                                         
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/danmaku/danmaku_fetcher.dart';
import 'playlist_cipher.dart';
import 'playlist_service.dart';
import 'watch_history_service.dart';
import 'webdav_service.dart';
import '../l10n/l10n_helper.dart';

              
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
          remoteJson = raw;          
        }
      }
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
                                 
        bgDownloaded = await _downloadBackgrounds();
        bgUploaded = await _uploadBackgrounds();
      } else {
                                   
        bgUploaded = await _uploadBackgrounds();
      }

                       
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

                                 
  String _extOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot <= 0 || dot == path.length - 1) return '.jpg';
    return path.substring(dot).toLowerCase();
  }

                                              
          
                                              

                              
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
                                    
      final remoteFiles = await webdav.listFiles(webdav.danmakuRemoteDir);
      final remoteByName = <String, RemoteFileEntry>{};
      for (final f in remoteFiles) {
        if (!f.isDirectory) remoteByName[f.name] = f;
      }

                            
      final localFiles = <String, File>{
        for (final f in await DanmakuCacheManager.listCachedFiles())
          f.uri.pathSegments.last: f,
      };

                                       
      for (final entry in localFiles.entries) {
        final name = entry.key;
        final localFile = entry.value;
        final remote = remoteByName[name];
        if (remote != null &&
            remote.lastModified != null &&
            remote.lastModified!.isAfter(await _fileModified(localFile))) {
          continue;                  
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

                                       
      for (final entry in remoteByName.entries) {
        final name = entry.key;
        if (!name.endsWith('.json')) continue;
        final remote = entry.value;
        final localFile = localFiles[name];
        if (localFile != null &&
            remote.lastModified != null &&
            !remote.lastModified!.isAfter(await _fileModified(localFile))) {
          continue;              
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
          remoteJson = raw;          
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

                                              
                                          
                                              

                                                     
                              
  static const String _settingsRemotePath = '/settings/settings.json';

                                                
                                      
  Future<CloudSyncResult> backupSettings() async {
    if (!webdav.isConfigured) {
      return CloudSyncResult(
        what: '应用设置',
        uploaded: 0,
        downloaded: 0,
        mergedOrRestored: 0,
        failed: 1,
        message: L10n.current.webdavNotConfigured,
      );
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = <String, Map<String, Object>>{};
      for (final key in prefs.getKeys()) {
        final v = prefs.get(key);
        if (v is bool) {
          entries[key] = {'t': 'b', 'v': v};
        } else if (v is int) {
          entries[key] = {'t': 'i', 'v': v};
        } else if (v is double) {
          entries[key] = {'t': 'd', 'v': v};
        } else if (v is String) {
          entries[key] = {'t': 's', 'v': v};
        } else if (v is List && v.every((e) => e is String)) {
          entries[key] = {'t': 'l', 'v': v.cast<String>().toList()};
        }
                                
      }
      final payload = jsonEncode({
        'type': 'naviflash_settings',
        'version': 1,
        'exported_at': DateTime.now().millisecondsSinceEpoch,
        'count': entries.length,
        'settings': entries,
      });
      final data = webdav.syncPassphraseEnabled
          ? utf8.encode(await PlaylistCipher.encrypt(
              payload, webdav.syncPassphrase))
          : utf8.encode(payload);
      final ok = await webdav.uploadBytes(_settingsRemotePath, data);
      if (!ok) {
        return CloudSyncResult(
          what: '应用设置',
          uploaded: 0,
          downloaded: 0,
          mergedOrRestored: 0,
          failed: 1,
          message: webdav.lastError,
        );
      }
      return CloudSyncResult(
        what: '应用设置',
        uploaded: 1,
        downloaded: 0,
        mergedOrRestored: 0,
        failed: 0,
        message: '已备份 ${entries.length} 项设置'
            '${webdav.syncPassphraseEnabled ? '，已加密' : ''}',
      );
    } catch (e) {
      debugPrint('设置备份失败: $e');
      return CloudSyncResult(
        what: '应用设置',
        uploaded: 0,
        downloaded: 0,
        mergedOrRestored: 0,
        failed: 1,
        message: L10n.current.csSyncFailed('$e'),
      );
    }
  }

                                        
                                            
                             
  Future<CloudSyncResult> restoreSettings() async {
    if (!webdav.isConfigured) {
      return CloudSyncResult(
        what: '应用设置',
        uploaded: 0,
        downloaded: 0,
        mergedOrRestored: 0,
        failed: 1,
        message: L10n.current.webdavNotConfigured,
      );
    }
    try {
      final remoteBytes = await webdav.downloadBytes(_settingsRemotePath);
      if (remoteBytes == null) {
        return CloudSyncResult(
          what: '应用设置',
          uploaded: 0,
          downloaded: 0,
          mergedOrRestored: 0,
          failed: 1,
          message: '云端还没有设置备份，请先在其他设备备份或先执行「备份设置」',
        );
      }
                                   
      final raw = utf8.decode(remoteBytes, allowMalformed: true);
      String payload;
      if (PlaylistCipher.isEncrypted(raw)) {
        if (!webdav.syncPassphraseEnabled) {
          return CloudSyncResult(
            what: '应用设置',
            uploaded: 0,
            downloaded: 0,
            mergedOrRestored: 0,
            failed: 1,
            message: L10n.current.csCloudEncrypted,
          );
        }
        try {
          payload = await PlaylistCipher.decrypt(raw, webdav.syncPassphrase);
        } catch (_) {
          return CloudSyncResult(
            what: '应用设置',
            uploaded: 0,
            downloaded: 0,
            mergedOrRestored: 0,
            failed: 1,
            message: L10n.current.csCloudPassMismatch,
          );
        }
      } else {
        payload = raw;
      }

      final obj = jsonDecode(payload);
      if (obj is! Map<String, dynamic>) {
        return CloudSyncResult(
          what: '应用设置',
          uploaded: 0,
          downloaded: 0,
          mergedOrRestored: 0,
          failed: 1,
          message: '设置备份格式无效',
        );
      }
      final settings = obj['settings'];
      if (settings is! Map<String, dynamic>) {
        return CloudSyncResult(
          what: '应用设置',
          uploaded: 0,
          downloaded: 0,
          mergedOrRestored: 0,
          failed: 1,
          message: '设置备份格式无效',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final writes = <Future<void>>[];
      int applied = 0;
      settings.forEach((key, wrap) {
        if (key.isEmpty || wrap is! Map<String, dynamic>) return;
        final type = wrap['t'];
        final v = wrap['v'];
        switch (type) {
          case 'b':
            if (v is bool) {
              writes.add(prefs.setBool(key, v));
              applied++;
            }
            break;
          case 'i':
            if (v is int) {
              writes.add(prefs.setInt(key, v));
              applied++;
            }
            break;
          case 'd':
            if (v is num) {
              writes.add(prefs.setDouble(key, v.toDouble()));
              applied++;
            }
            break;
          case 's':
            if (v is String) {
              writes.add(prefs.setString(key, v));
              applied++;
            }
            break;
          case 'l':
            if (v is List && v.every((e) => e is String)) {
              writes.add(prefs.setStringList(key, v.cast<String>().toList()));
              applied++;
            }
            break;
        }
      });
      await Future.wait(writes);
      if (applied == 0) {
        return CloudSyncResult(
          what: '应用设置',
          uploaded: 0,
          downloaded: 1,
          mergedOrRestored: 0,
          failed: 1,
          message: '设置备份中没有可恢复的设置项',
        );
      }
      return CloudSyncResult(
        what: '应用设置',
        uploaded: 0,
        downloaded: 1,
        mergedOrRestored: applied,
        failed: 0,
        message: '已恢复 $applied 项设置（云端值覆盖本地同名项），重启应用后完全生效'
            '${PlaylistCipher.isEncrypted(raw) ? '，已解密' : ''}',
      );
    } catch (e) {
      debugPrint('设置恢复失败: $e');
      return CloudSyncResult(
        what: '应用设置',
        uploaded: 0,
        downloaded: 0,
        mergedOrRestored: 0,
        failed: 1,
        message: L10n.current.csSyncFailed('$e'),
      );
    }
  }
}
