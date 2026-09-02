// lib/screens/storage_settings_screen.dart
//
// 存储设置页：图片缓存 / 弹幕缓存 / 内存图片缓存的占用查看与一键清理。
// 图片缓存（image_cache）：评论配图、头像等原图下载后落盘，重复查看不再
// 重新下载；清理后下次查看会重新下载。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/services/image_cache_service.dart';
import 'package:naviflash/services/bilibili_article_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/services/video_cache_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/danmaku/danmaku_fetcher.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:provider/provider.dart';
import 'cache_contents_page.dart';
import '../l10n/app_localizations.dart';

class StorageSettingsScreen extends StatefulWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const StorageSettingsScreen({
    super.key,
    this.isSplitView = false,
    this.onBack,
  });

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  // -1 表示尚未加载
  int _imageCacheBytes = -1;
  int _imageCacheCount = 0;
  int _danmakuCacheBytes = -1;
  int _danmakuCacheCount = 0;
  int _videoCacheBytes = -1;
  int _videoCacheCount = 0;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final imageBytes = await ImageCacheService.totalSize();
    final imageCount = await ImageCacheService.count();
    final danmakuFiles = await DanmakuCacheManager.listCachedFiles();
    var danmakuBytes = 0;
    for (final f in danmakuFiles) {
      danmakuBytes += await f.length().catchError((_) => 0);
    }
    final videoBytes = await VideoStreamCache.totalSize();
    final videoCount = await VideoStreamCache.count();
    if (!mounted) return;
    setState(() {
      _imageCacheBytes = imageBytes;
      _imageCacheCount = imageCount;
      _danmakuCacheBytes = danmakuBytes;
      _danmakuCacheCount = danmakuFiles.length;
      _videoCacheBytes = videoBytes;
      _videoCacheCount = videoCount;
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 0) return '…';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  /// 清空指定缓存；[alsoMemory] 时同时清空 Flutter 内存图片缓存。
  Future<void> _clear({
    required String label,
    required Future<void> Function() clear,
    bool alsoMemory = false,
  }) async {
    if (_clearing) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.storageClearTitle(label)),
        content: Text(l10n.storageClearConfirm(label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.storageClear),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _clearing = true);
    await clear();
    if (alsoMemory) {
      // 清空 Flutter 内存中的已解码图片缓存（缩略图/表情等）
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    }
    if (!mounted) return;
    setState(() => _clearing = false);
    await _refresh();
    if (!mounted) return;
    showAppToast(context, l10n.storageCleared(label));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsService>();

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainerLow),
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              ExpressiveSliverAppBar(
                title: l10n.settingsStorage,
                expandedHeight: 120,
                leading: widget.isSplitView
                    ? null
                    : MorphIconButton(
                        tooltip: l10n.startScreenGoBack,
                        icon: Icons.arrow_back,
                        onTap:
                            widget.onBack ?? () => Navigator.of(context).pop(),
                      ),
                actions: [
                  MorphIconButton(
                    icon: Icons.refresh,
                    tooltip: l10n.refreshAction,
                    onTap: _clearing ? null : _refresh,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle(context, l10n.storageCacheSection),
                      const SizedBox(height: 12),
                      ...buildMorphSegmentedList([
                        MorphRowItem(
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            secondary: Icon(
                              Icons.file_download_outlined,
                              size: 26,
                              color: cs.primary,
                            ),
                            title: Text(
                              l10n.settingsAutoOfflineCache,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              l10n.settingsAutoOfflineCacheHint,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            value: settings.autoOfflineCache,
                            onChanged: (v) => settings.setAutoOfflineCache(v),
                          ),
                        ),
                        MorphRowItem(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Icon(
                              Icons.inventory_2_outlined,
                              size: 26,
                              color: cs.primary,
                            ),
                            title: Text(
                              '查看缓存内容',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '离线视频 BV · 图片 · 动态/专栏/标题翻译',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: cs.onSurfaceVariant,
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CacheContentsPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        MorphRowItem(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Icon(
                              Icons.image_outlined,
                              size: 26,
                              color: cs.primary,
                            ),
                            title: Text(l10n.storageImageCache),
                            subtitle: Text(
                              _imageCacheBytes < 0
                                  ? l10n.storageCounting
                                  : l10n.storageFileCount(
                                      _imageCacheCount,
                                      _formatSize(_imageCacheBytes),
                                    ),
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: _clearing
                                  ? null
                                  : () => _clear(
                                      label: l10n.storageImageCache,
                                      clear: ImageCacheService.clearAll,
                                    ),
                              child: Text(l10n.storageClear),
                            ),
                          ),
                        ),
                        MorphRowItem(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Icon(
                              Icons.subtitles_outlined,
                              size: 26,
                              color: cs.primary,
                            ),
                            title: Text(l10n.storageDanmakuCache),
                            subtitle: Text(
                              _danmakuCacheBytes < 0
                                  ? l10n.storageCounting
                                  : l10n.storageVideoCount(
                                      _danmakuCacheCount,
                                      _formatSize(_danmakuCacheBytes),
                                    ),
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: _clearing
                                  ? null
                                  : () => _clear(
                                      label: l10n.storageDanmakuCache,
                                      clear: DanmakuCacheManager.clearAll,
                                    ),
                              child: Text(l10n.storageClear),
                            ),
                          ),
                        ),
                        // ── 离线视频缓存：播放过的视频媒体流自动落盘 ──
                        MorphRowItem(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Icon(
                              Icons.video_library_outlined,
                              size: 26,
                              color: cs.primary,
                            ),
                            title: Text(l10n.storageVideoCache),
                            subtitle: Text(
                              _videoCacheBytes < 0
                                  ? l10n.storageCounting
                                  : l10n.storageVideoCount(
                                      _videoCacheCount,
                                      _formatSize(_videoCacheBytes),
                                    ),
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: _clearing
                                  ? null
                                  : () => _clear(
                                      label: l10n.storageVideoCache,
                                      clear: VideoStreamCache.clearAll,
                                    ),
                              child: Text(l10n.storageClear),
                            ),
                          ),
                        ),
                        MorphRowItem(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Icon(
                              Icons.memory_outlined,
                              size: 26,
                              color: cs.primary,
                            ),
                            title: Text(l10n.storageMemoryCache),
                            subtitle: Text(
                              l10n.storageMemoryCacheDesc,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: _clearing
                                  ? null
                                  : () => _clear(
                                      label: l10n.storageMemoryCache,
                                      clear: () async => 0,
                                      alsoMemory: true,
                                    ),
                              child: Text(l10n.storageClear),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _clearing ? null : () => _clearAll(),
                        icon: const Icon(
                          Icons.cleaning_services_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _clearing
                              ? l10n.storageClearing
                              : l10n.storageClearAll,
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.storageCacheHint,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _clearAll() async {
    if (_clearing) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.storageClearAllTitle),
        content: Text(l10n.storageClearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.storageClear),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _clearing = true);
    await ImageCacheService.clearAll();
    await DanmakuCacheManager.clearAll();
    await ArticleCache.clearAll();
    await DynamicDetailCache.clearAll();
    await VideoJsonCache.clearAll();
    await VideoStreamCache.clearAll();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (!mounted) return;
    setState(() => _clearing = false);
    await _refresh();
    if (!mounted) return;
    showAppToast(context, l10n.storageAllCleared);
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
