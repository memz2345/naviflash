                                       
  
                                                  
                  
                                                     
                                         
                            
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/screens/article_page.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/screens/dynamic_detail_page.dart';
import 'package:naviflash/screens/image_viewer_page.dart';
import 'package:naviflash/services/bilibili_article_service.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/image_cache_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/video_cache_service.dart';
import 'package:naviflash/services/manual_video_cache.dart';
import 'package:naviflash/widgets/metro_tile.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/glass_bottom_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';

enum _TextMode { titles, dynamics, articles }

class CacheContentsPage extends StatefulWidget {
  const CacheContentsPage({super.key});

  @override
  State<CacheContentsPage> createState() => _CacheContentsPageState();
}

class _CacheContentsPageState extends State<CacheContentsPage>
    with SingleTickerProviderStateMixin {
  int _tab = 0;

       
  List<VideoStreamCacheEntry>? _videos;
       
  List<ImageCacheEntry>? _images;
       
  _TextMode _textMode = _TextMode.titles;
  Map<String, String>? _titles;
  List<DynamicCacheEntry>? _dynamics;
  List<ArticleCacheEntry>? _articles;

  bool _clearing = false;

  static const double _imageTargetWidth = 128.0;
  static const int _imageMinColumns = 4;
  static const int _imageMaxColumns = 12;
  static const double _imageGridSpacing = 4.0;
  int _previousImageColumns = 0;
  int _previousImageCount = 0;
  String? _previousFirstImage;
  late final AnimationController _imageGridAnimation;
  final Map<int, Offset> _imageTranslations = {};

  @override
  void initState() {
    super.initState();
    _imageGridAnimation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 360),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _imageTranslations.clear();
          }
        });
    _refresh();
  }

  @override
  void dispose() {
    _imageGridAnimation.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
                                   
                                            
    await _loadVideos();
    await _loadImages();
    await _loadText();
  }

  Future<void> _handleVideoRefresh() => _loadVideos();

  Future<void> _handleTextRefresh() => _loadText();

  Future<void> _handleImageRefresh() => _loadImages();

  Future<void> _loadVideos() async {
                       
    final entries = await ManualVideoCache.listAllEntries();
    if (!mounted) return;
    setState(() => _videos = entries);
  }

  Future<void> _loadImages() async {
    final entries = await ImageCacheService.listEntries();
    if (!mounted) return;
    setState(() => _images = entries);
  }

  Future<void> _loadText() async {
    final titles = await BilibiliTitleCache.allEntries();
    final dyns = await DynamicDetailCache.listEntries();
    final arts = await ArticleCache.listEntries();
    if (!mounted) return;
    setState(() {
      _titles = {for (final e in titles) e.key: e.value};
      _dynamics = dyns;
      _articles = arts;
    });
  }

             

  int _currentCount() {
    switch (_tab) {
      case 0:
        return _videos?.length ?? 0;
      case 1:
        return _images?.length ?? 0;
      default:
        return switch (_textMode) {
          _TextMode.titles => _titles?.length ?? 0,
          _TextMode.dynamics => _dynamics?.length ?? 0,
          _TextMode.articles => _articles?.length ?? 0,
        };
    }
  }

  Future<void> _deleteAll() async {
    if (_clearing) return;
    final l10n = L10n.current;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空缓存'),
        content: const Text('将清空当前分类的全部缓存，确定继续？'),
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
    setState(() => _clearing = true);
    switch (_tab) {
      case 0:
        await ManualVideoCache.clearAllBoth();
      case 1:
        await ImageCacheService.clearAll();
      default:
        switch (_textMode) {
          case _TextMode.titles:
            await BilibiliTitleCache.clearAll();
          case _TextMode.dynamics:
            await DynamicDetailCache.clearAll();
          case _TextMode.articles:
            await ArticleCache.clearAll();
        }
    }
    if (!mounted) return;
    setState(() => _clearing = false);
    showAppToast(context, '已清空当前分类缓存');
    _refresh();
  }

  Future<void> _deleteVideo(VideoStreamCacheEntry e) async {
    final ok = await _confirm(
      '删除缓存视频',
      '确定删除已缓存的视频 ${e.bvid}（${e.isDash ? 'DASH' : '直链'} · ${_size(e.bytes)}）吗？',
    );
    if (ok != true || !mounted) return;
    await ManualVideoCache.deleteEntryAny(e);
    if (!mounted) return;
    showAppToast(context, '已删除缓存视频 ${e.bvid}');
    _loadVideos();
  }

  Future<void> _deleteImage(ImageCacheEntry e) async {
    final ok = await _confirm('删除缓存图片', '确定删除这张图片吗？（${_size(e.size)}）');
    if (ok != true || !mounted) return;
    await ImageCacheService.deleteFile(e.file);
    if (!mounted) return;
    showAppToast(context, '已删除缓存图片');
    _loadImages();
  }

  Future<void> _deleteTitle(String bvid) async {
    final ok = await _confirm('删除标题翻译', '确定删除 $bvid 的翻译标题缓存吗？');
    if (ok != true || !mounted) return;
    await BilibiliTitleCache.forget(bvid);
    if (!mounted) return;
    setState(() => _titles?.remove(bvid));
  }

  Future<void> _deleteDynamic(String id) async {
    final ok = await _confirm('删除动态缓存', '确定删除这条动态的缓存吗？（$id）');
    if (ok != true || !mounted) return;
    await DynamicDetailCache.deleteOne(id);
    if (!mounted) return;
    _loadText();
  }

  Future<void> _deleteArticle(int cvid) async {
    final ok = await _confirm('删除专栏缓存', '确定删除 CV$cvid 的缓存吗？');
    if (ok != true || !mounted) return;
    await ArticleCache.deleteOne(cvid);
    if (!mounted) return;
    _loadText();
  }

  Future<bool?> _confirm(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

             

                                 
  double get _barBottomPad => MediaQuery.of(context).padding.bottom + 84;

  String _size(int bytes) {
    if (bytes < 0) return '…';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  String _date(DateTime t) {
    if (t.millisecondsSinceEpoch <= 0) return '';
    final now = DateTime.now();
    final sameDay =
        t.year == now.year && t.month == now.month && t.day == now.day;
    final hm =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (sameDay) return '今天 $hm';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-'
        '${t.day.toString().padLeft(2, '0')} $hm';
  }

  String _qnLabel(int qn) {
    if (qn <= 0) return '自动';
    if (qn >= 10000) return '4K';
    if (qn >= 8000) return '1080P60';
    if (qn >= 6000) return '1080P';
    if (qn >= 4000) return '720P';
    return '${qn}P';
  }

                                
  void _checkImageGridLayout(
    int columns,
    int count,
    double cellWidth,
    double cellHeight,
  ) {
    final images = _images;
    if (images == null || count == 0) {
      _previousImageColumns = columns;
      _previousImageCount = count;
      _previousFirstImage = null;
      _imageTranslations.clear();
      return;
    }
    final firstImage = images.first.file.path;
    if (_previousImageColumns == 0) {
      _previousImageColumns = columns;
      _previousImageCount = count;
      _previousFirstImage = firstImage;
      return;
    }
    if (_previousImageColumns == columns && _previousImageCount == count) {
      return;
    }

                            
    if (_previousFirstImage != null && _previousFirstImage != firstImage) {
      _imageTranslations.clear();
      _previousImageColumns = columns;
      _previousImageCount = count;
      _previousFirstImage = firstImage;
      return;
    }

    final oldColumns = _previousImageColumns;
    final minCount = _previousImageCount < count ? _previousImageCount : count;
    _imageTranslations.clear();
    var moved = false;
    for (var index = 0; index < minCount; index++) {
      final oldRow = index ~/ oldColumns;
      final oldColumn = index % oldColumns;
      final newRow = index ~/ columns;
      final newColumn = index % columns;
      if (oldRow == newRow && oldColumn == newColumn) continue;
      moved = true;
      _imageTranslations[index] = Offset(
        (oldColumn - newColumn) * cellWidth,
        (oldRow - newRow) * cellHeight,
      );
    }

    _previousImageColumns = columns;
    _previousImageCount = count;
    _previousFirstImage = firstImage;
    if (moved) {
      _imageGridAnimation
        ..reset()
        ..forward();
    }
  }

             

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final count = _currentCount();
    return IosBackdropScale(
      child: Scaffold(
        backgroundColor: cs.surfaceContainerLow,
        extendBody: true,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: AppBottomBar(
              tabs: const [
                GlassBottomBarTab(
                  label: '视频',
                  icon: Icons.video_library_outlined,
                  selectedIcon: Icons.video_library,
                ),
                GlassBottomBarTab(
                  label: '图片',
                  icon: Icons.image_outlined,
                  selectedIcon: Icons.image,
                ),
                GlassBottomBarTab(
                  label: '文字',
                  icon: Icons.article_outlined,
                  selectedIcon: Icons.article,
                ),
              ],
              selectedIndex: _tab,
              onTabSelected: (i) => setState(() => _tab = i),
            ),
          ),
        ),
        body: Stack(
          children: [
            PageBackground(baseColor: cs.surfaceContainerLow),
            NestedScrollView(
          headerSliverBuilder: (context, _) => [
            ExpressiveSliverAppBar(
              title: '缓存内容',
              expandedHeight: 152,
              blurSigma: 12,
              blurOpacity: 0.72,
              leading: MorphIconButton(
                icon: Icons.arrow_back,
                tooltip: L10n.current.startScreenGoBack,
                onTap: () => Navigator.of(context).maybePop(),
                frosted: true,
              ),
              actions: [
                MorphIconButton(
                  icon: Icons.refresh,
                  tooltip: L10n.current.refreshAction,
                  onTap: _refresh,
                  frosted: true,
                ),
                if (count > 0)
                  MorphIconButton(
                    icon: Icons.delete_sweep_outlined,
                    tooltip: '清空当前分类',
                    onTap: _clearing ? null : _deleteAll,
                    frosted: true,
                  ),
                const SizedBox(width: 4),
              ],
            ),
          ],
          body: IndexedStack(
            index: _tab,
            children: [
              _buildVideosView(cs),
              _buildImagesView(cs),
              _buildTextView(cs),
            ],
          ),
        ),
        ],
      ),
      ),
    );
  }

                 

  Widget _buildVideosView(ColorScheme cs) {
    final entries = _videos;
    if (entries == null) {
      return const Center(child: LoadingIndicatorM3E());
    }
    if (entries.isEmpty) {
      return _empty(cs, '暂无缓存的视频', '播放视频并观看数秒后会后台缓存到本地');
    }
    return AppRefreshIndicator(
      onRefresh: _handleVideoRefresh,
      color: cs.primary,
      child: ListView.builder(
        primary: _tab == 0,
        physics: const AlwaysScrollableScrollPhysics(
                parent: AppRefreshScrollPhysics(),
              ),
        padding: EdgeInsets.fromLTRB(16, 0, 16, _barBottomPad),
        itemCount: entries.length,
        itemBuilder: (context, index) =>
            _buildVideoCard(context, cs, entries[index]),
      ),
    );
  }

  Widget _buildVideoCard(
    BuildContext context,
    ColorScheme cs,
    VideoStreamCacheEntry e,
  ) {
    final heroTag = 'cached_video_${e.bvid}_${e.cid}';
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;

    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 96,
        height: 58,
        child: e.cover.isNotEmpty
            ? Image(
                image: CachedImageProvider(
                  BilibiliUserSpaceService.coverUrl(e.cover),
                  headers: headers,
                ),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _videoCoverFallback(cs),
              )
            : _videoCoverFallback(cs),
      ),
    );

    final card = Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          openBilibiliVideo(
            context,
            bvid: e.bvid,
            initialCover: e.cover.isNotEmpty ? e.cover : null,
            heroTag: heroTag,
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          child: Row(
            children: [
              cover,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            e.bvid,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _qnLabel(e.qn),
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'cid ${e.cid} · ${e.isDash ? 'DASH' : '直链'} · ${_size(e.bytes)} · ${_date(e.savedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '复制 BV 号',
                icon: Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: e.bvid));
                  showAppToast(context, '已复制 ${e.bvid}');
                },
              ),
              IconButton(
                tooltip: '删除该缓存',
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                onPressed: () => _deleteVideo(e),
              ),
            ],
          ),
        ),
      ),
    );

    final interactive = MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Hero(transitionOnUserGestures: true, tag: heroTag, child: interactive),
    );
  }

  Widget _videoCoverFallback(ColorScheme cs) {
    return Container(
      color: cs.primaryContainer.withValues(alpha: 0.5),
      child: const Icon(Icons.play_circle_outline, size: 30),
    );
  }

                                         

  Widget _buildImagesView(ColorScheme cs) {
    final entries = _images;
    if (entries == null) {
      return const Center(child: LoadingIndicatorM3E());
    }
    if (entries.isEmpty) {
      return _empty(cs, '暂无缓存的图片', '浏览视频 / 评论 / 动态时图片会自动缓存到本地');
    }
    return AppRefreshIndicator(
      onRefresh: _handleImageRefresh,
      color: cs.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = (width / _imageTargetWidth).floor().clamp(
            _imageMinColumns,
            _imageMaxColumns,
          );
          final cardWidth =
              (width - (columns - 1) * _imageGridSpacing) / columns;
          _checkImageGridLayout(
            columns,
            entries.length,
            cardWidth + _imageGridSpacing,
            cardWidth + _imageGridSpacing,
          );

          return GridView.builder(
            primary: _tab == 1,
            padding: EdgeInsets.fromLTRB(0, 0, 0, _barBottomPad),
            physics: const AlwaysScrollableScrollPhysics(
                parent: AppRefreshScrollPhysics(),
                  ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: _imageGridSpacing,
            crossAxisSpacing: _imageGridSpacing,
            childAspectRatio: 1,
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            return ListenableBuilder(
              listenable: _imageGridAnimation,
              builder: (context, _) {
                final progress = Curves.easeInOut.transform(
                  _imageGridAnimation.value,
                );
                final translation = _imageTranslations[index];
                Widget tile = _buildImageTile(context, cs, entries[index]);
                if (translation != null && progress < 1.0) {
                  tile = Transform.translate(
                    offset: translation * (1 - progress),
                    child: tile,
                  );
                }
                return tile;
              },
            );
          },
        );
        },
      ),
    );
  }

  Widget _buildImageTile(
    BuildContext context,
    ColorScheme cs,
    ImageCacheEntry e,
  ) {
                                            
    final heroTag = 'cached_img_${e.file.uri.pathSegments.last}';
    final tile = GestureDetector(
      onTap: () => _openImageViewer(e, heroTag),
      onLongPress: () => _showImageDetail(e),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            e.file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: cs.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image_outlined,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              color: Colors.black.withValues(alpha: 0.55),
              child: Text(
                _size(e.size),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
    return Hero(
        transitionOnUserGestures: true,
      tag: heroTag,
      child: MetroTileInteraction(
        onTapStart: (_, __) {},
        showBorder: false,
        child: tile,
      ),
    );
  }

  void _openImageViewer(ImageCacheEntry e, String heroTag) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      heroTransitionRoute(
                                          
        heroZoom: true,
        page: ImageViewerPage(
          sources: [ImageViewerSource(filePath: e.file.path, heroTag: heroTag)],
        ),
      ),
    );
  }

  void _showImageDetail(ImageCacheEntry e) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: const Text('图片详情'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  e.file,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 120,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('大小：${_size(e.size)}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                '缓存时间：${_date(e.modified)}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              if (e.url.isNotEmpty) ...[
                Text(
                  '来源 URL：',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(e.url, style: const TextStyle(fontSize: 11)),
              ] else
                Text(
                  '该图片为旧版本缓存，未记录来源 URL',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          if (e.url.isNotEmpty)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: e.url));
                showAppToast(ctx, '已复制图片链接');
                Navigator.pop(ctx);
              },
              child: const Text('复制链接'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteImage(e);
            },
            child: const Text('删除'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

                 

  Widget _buildTextView(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<_TextMode>(
            segments: const [
              ButtonSegment(
                value: _TextMode.titles,
                label: Text('标题翻译'),
                icon: Icon(Icons.translate, size: 16),
              ),
              ButtonSegment(
                value: _TextMode.dynamics,
                label: Text('动态详情'),
                icon: Icon(Icons.forum_outlined, size: 16),
              ),
              ButtonSegment(
                value: _TextMode.articles,
                label: Text('专栏'),
                icon: Icon(Icons.article_outlined, size: 16),
              ),
            ],
            selected: {_textMode},
            onSelectionChanged: (s) => setState(() => _textMode = s.first),
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(
                TextStyle(fontSize: 13, color: cs.onSurface),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Expanded(child: _buildTextBody(cs)),
      ],
    );
  }

  Widget _buildTextBody(ColorScheme cs) {
    switch (_textMode) {
      case _TextMode.titles:
        final titles = _titles;
        if (titles == null) {
          return const Center(child: LoadingIndicatorM3E());
        }
        if (titles.isEmpty) {
          return _empty(cs, '暂无标题翻译缓存', '视频标题被 AI 翻译后会记录 bvid → 译文');
        }
        return _textList(
          cs,
          itemCount: titles.length,
          itemBuilder: (context, index) {
            final e = titles.entries.elementAt(index);
            return _textCard(
              context,
              cs,
              icon: Icons.translate,
              title: e.value,
              subtitle: e.key,
              onTap: () {
                Clipboard.setData(ClipboardData(text: e.key));
                showAppToast(context, '已复制 ${e.key}');
              },
              onDelete: () => _deleteTitle(e.key),
            );
          },
        );
      case _TextMode.dynamics:
        final dyns = _dynamics;
        if (dyns == null) return const Center(child: LoadingIndicatorM3E());
        if (dyns.isEmpty) {
          return _empty(cs, '暂无动态详情缓存', '打开过动态详情页后会记录');
        }
        return _textList(
          cs,
          itemCount: dyns.length,
          itemBuilder: (context, index) {
            final d = dyns[index];
            final author = d.author.isEmpty ? '未知用户' : d.author;
            final text = d.text.isEmpty ? '' : d.text;
            return _textCard(
              context,
              cs,
              icon: Icons.forum_outlined,
              title: text.isEmpty ? '$author · 动态 ${d.id}' : '$author：$text',
              subtitle: '${d.id} · ${_date(d.savedAt)}',
              maxLines: 2,
              onTap: d.id.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DynamicDetailPage(id: d.id),
                        ),
                      );
                    },
              onDelete: () => _deleteDynamic(d.id),
            );
          },
        );
      case _TextMode.articles:
        final arts = _articles;
        if (arts == null) return const Center(child: LoadingIndicatorM3E());
        if (arts.isEmpty) {
          return _empty(cs, '暂无专栏缓存', '打开过专栏（文章）后会记录');
        }
        return _textList(
          cs,
          itemCount: arts.length,
          itemBuilder: (context, index) {
            final a = arts[index];
            final heroTag = a.cvid > 0 ? 'cached_article_${a.cvid}' : null;
            return _textCard(
              context,
              cs,
              icon: Icons.article_outlined,
              title: a.title.isEmpty ? 'CV${a.cvid}' : a.title,
              subtitle: 'cv${a.cvid} · ${_date(a.savedAt)}',
              heroTag: heroTag,
              onTap: a.cvid > 0 && heroTag != null
                  ? () {
                      Navigator.of(context).push(
                        heroTransitionRoute(
                          heroZoom: true,
                          page: ArticlePage(
                            cvid: a.cvid,
                            initialTitle: a.title.isEmpty ? null : a.title,
                            heroTag: heroTag,
                          ),
                        ),
                      );
                    }
                  : null,
              onDelete: () => _deleteArticle(a.cvid),
            );
          },
        );
    }
  }

  Widget _textList(
    ColorScheme cs, {
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return AppRefreshIndicator(
      onRefresh: _handleTextRefresh,
      color: cs.primary,
      child: ListView.builder(
        primary: _tab == 2,
        physics: const AlwaysScrollableScrollPhysics(
            parent: AppRefreshScrollPhysics(),
              ),
        padding: EdgeInsets.fromLTRB(16, 8, 16, _barBottomPad),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }

  Widget _textCard(
    BuildContext context,
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    required VoidCallback onDelete,
    int maxLines = 1,
    String? heroTag,
  }) {
    final card = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: maxLines,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '删除该条缓存',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
                                           
    if (heroTag == null) return card;
    return Hero(
        transitionOnUserGestures: true,
      tag: heroTag,
      child: MetroTileInteraction(
        onTapStart: (_, __) {},
        showBorder: false,
        child: card,
      ),
    );
  }

               

  Widget _empty(ColorScheme cs, String title, String sub) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 52,
            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              sub,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
