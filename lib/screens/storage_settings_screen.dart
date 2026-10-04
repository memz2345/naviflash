                                           
  
                                        
                                     
  
                                              
                                                           
                             
                                           
                     
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/services/image_cache_service.dart';
import 'package:naviflash/services/bilibili_article_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/services/storage_usage_service.dart';
import 'package:naviflash/services/video_cache_service.dart';
import 'package:naviflash/services/manual_video_cache.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/storage_pie_chart.dart';
import 'package:naviflash/widgets/danmaku/danmaku_fetcher.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/storage_location_section.dart';
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
              
  int _imageCacheBytes = -1;
  int _imageCacheCount = 0;
  int _danmakuCacheBytes = -1;
  int _danmakuCacheCount = 0;
  int _videoCacheBytes = -1;
  int _videoCacheCount = 0;
  bool _clearing = false;

                               
  Map<StorageCategory, int>? _usage;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
                                           
    final usageFuture = StorageUsageService.load();
    final imageBytes = await ImageCacheService.totalSize();
    final imageCount = await ImageCacheService.count();
    final danmakuFiles = await DanmakuCacheManager.listCachedFiles();
    var danmakuBytes = 0;
    for (final f in danmakuFiles) {
      danmakuBytes += await f.length().catchError((_) => 0);
    }
                                                         
    final videoBytes = await ManualVideoCache.totalAllSize();
    final videoCount = await ManualVideoCache.totalAllCount();
    final usage = await usageFuture;
    if (!mounted) return;
    setState(() {
      _imageCacheBytes = imageBytes;
      _imageCacheCount = imageCount;
      _danmakuCacheBytes = danmakuBytes;
      _danmakuCacheCount = danmakuFiles.length;
      _videoCacheBytes = videoBytes;
      _videoCacheCount = videoCount;
      _usage = usage;
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
                                                         
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'storage_settings_fab',
        onPressed: _clearing ? null : _clearAll,
        icon: const Icon(Icons.cleaning_services_outlined),
        label: Text(_clearing ? l10n.storageClearing : l10n.storageClearAll),
      ),
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainerLow),
                                                        
                                     
          ScrollConfiguration(
            behavior: const MaterialScrollBehavior(),
            child: CustomScrollView(
              slivers: [
                ExpressiveSliverAppBar(
                  title: l10n.settingsStorage,
                  expandedHeight: 152,
                  leading: widget.isSplitView
                      ? null
                      : MorphIconButton(
                          tooltip: l10n.startScreenGoBack,
                          icon: Icons.arrow_back,
                          onTap:
                              widget.onBack ??
                              () => Navigator.of(context).pop(),
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
                                                
                            interactive: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.pie_chart,
                                        size: 20,
                                        color: cs.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.storageUsageBreakdown,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _buildUsageChart(l10n),
                                ],
                              ),
                            ),
                          ),
                        ]),
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
                                        clear:
                                            ManualVideoCache.clearAllBoth,
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
                        const SizedBox(height: 24),
                                                
                                                      
                                                        
                        const StorageLocationSection(),
                        const SizedBox(height: 20),
                        Text(
                          l10n.storageCacheHint,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
    await ManualVideoCache.clearAllBoth();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (!mounted) return;
    setState(() => _clearing = false);
    await _refresh();
    if (!mounted) return;
    showAppToast(context, l10n.storageAllCleared);
  }

                             
  Widget _buildUsageChart(AppLocalizations l10n) {
    final usage = _usage;
    if (usage == null) {
      return const SizedBox(
        height: 168,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    final cs = Theme.of(context).colorScheme;
    return StoragePieChart(
      totalLabel: l10n.storageUsageTotal,
      emptyLabel: l10n.storageUsageEmpty,
      slices: [
        StorageSlice(
          label: l10n.storageVideoCache,
          bytes: usage[StorageCategory.offlineVideo] ?? 0,
          color: cs.primary,
        ),
        StorageSlice(
          label: l10n.storageImageCache,
          bytes: usage[StorageCategory.image] ?? 0,
          color: cs.tertiary,
        ),
        StorageSlice(
          label: l10n.storageDanmakuCache,
          bytes: usage[StorageCategory.danmaku] ?? 0,
          color: cs.secondary,
        ),
        StorageSlice(
          label: l10n.storageDataCache,
          bytes: usage[StorageCategory.data] ?? 0,
          color: cs.primaryContainer,
        ),
        StorageSlice(
          label: l10n.storageAiDeps,
          bytes: usage[StorageCategory.ai] ?? 0,
          color: cs.tertiaryContainer,
        ),
      ],
    );
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
