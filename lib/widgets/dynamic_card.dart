                                
  
                                                    
                                              
  
                                              
                                   
                            
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassQuality;

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/screens/dynamic_detail_page.dart';
import 'package:naviflash/services/bilibili_dynamics_service.dart';
import 'package:naviflash/services/bilibili_dynamic_opus_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/dynamic/dynamic_reserve_card.dart';
import 'package:naviflash/widgets/dynamic/dynamic_vote_panel.dart';
import 'package:naviflash/widgets/lazy_cover_image.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/ugc_rich_text.dart';

                
String dynamicTypeLabel(String type) => switch (type) {
  'DYNAMIC_TYPE_AV' => '投稿视频',
  'DYNAMIC_TYPE_PGC' => '番剧',
  'DYNAMIC_TYPE_UGC_SEASON' => '合集',
  'DYNAMIC_TYPE_DRAW' => '图文',
  'DYNAMIC_TYPE_WORD' => '文字',
  'DYNAMIC_TYPE_ARTICLE' => '专栏',
  'DYNAMIC_TYPE_FORWARD' => '转发',
  'DYNAMIC_TYPE_LIVE' => '直播',
  'DYNAMIC_TYPE_LIVE_RCMD' => '直播',
  _ => '',
};

                                                      
String formatDynamicTime(int ts) {
  if (ts <= 0) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  final now = DateTime.now();
  final diff = now.difference(dt);
  String two(int n) => n.toString().padLeft(2, '0');
  if (diff.inMinutes < 1 && diff.inSeconds >= 0) return '刚刚';
  if (diff.inHours < 1 && diff.inMinutes >= 0) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24 && diff.inDays == 0) return '${diff.inHours} 小时前';
  final sameDay =
      dt.year == now.year && dt.month == now.month && dt.day == now.day;
  if (sameDay) return '${two(dt.hour)}:${two(dt.minute)}';
  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday =
      dt.year == yesterday.year &&
      dt.month == yesterday.month &&
      dt.day == yesterday.day;
  if (isYesterday) return '昨天 ${two(dt.hour)}:${two(dt.minute)}';
  if (dt.year == now.year) return '${two(dt.month)}-${two(dt.day)}';
  return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
}

class DynamicCard extends StatefulWidget {
  final BiliDynamicDetail item;

                                
  final bool compact;

  const DynamicCard({super.key, required this.item, this.compact = false});

  @override
  State<DynamicCard> createState() => _DynamicCardState();
}

class _DynamicCardState extends State<DynamicCard> {
  bool _liked = false;
  bool _likeBusy = false;
  late int _likeCount = widget.item.likeCount;

                                      
                                             
  BiliReserveInfo? _reserve;
  bool _reserveChecked = false;

  @override
  void initState() {
    super.initState();
    _maybeFetchReserve();
  }

  @override
  void didUpdateWidget(DynamicCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.idStr != widget.item.idStr) {
      _reserve = null;
      _reserveChecked = false;
      _maybeFetchReserve();
    }
  }

  Future<void> _maybeFetchReserve() async {
                                         
    if (_reserveChecked || widget.item.type != 'DYNAMIC_TYPE_WORD') return;
    _reserveChecked = true;
    final raw = await BilibiliDynamicsService.fetchDetailRaw(widget.item.idStr);
    if (!mounted || raw == null) return;
    setState(() => _reserve = BiliReserveInfo.fromModules(raw['modules']));
  }

                                                           
  BiliVoteRef? _voteRef(BiliDynamicDetail item) {
    for (final node in item.textNodes) {
      if (node.type == 'RICH_TEXT_NODE_TYPE_VOTE') {
        final id = int.tryParse(node.rid) ?? 0;
        if (id > 0) return BiliVoteRef(voteId: id, title: node.text);
      }
    }
    return null;
  }

  Map<String, String>? get _headers =>
      NetworkSettingsService.instance.apiHeaders.isEmpty
      ? null
      : NetworkSettingsService.instance.apiHeaders;

  Future<void> _toggleLike() async {
    if (_likeBusy) return;
    if (!BilibiliDynamicsService.canUse) {
      showAppToast(
        context,
        AppLocalizations.of(context).msgGoLogin,
        error: true,
      );
      return;
    }
    final next = !_liked;
    setState(() {
      _likeBusy = true;
      _liked = next;
      _likeCount += next ? 1 : -1;
      if (_likeCount < 0) _likeCount = 0;
    });
    final r = await BilibiliDynamicsService.likeDynamic(
      idStr: widget.item.idStr,
      like: next,
    );
    if (!mounted) return;
    setState(() => _likeBusy = false);
    if (!r.ok) {
             
      setState(() {
        _liked = !next;
        _likeCount += next ? -1 : 1;
        if (_likeCount < 0) _likeCount = 0;
      });
      showAppToast(context, r.message, error: true);
    }
  }

  void _openDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DynamicDetailPage(id: widget.item.idStr),
      ),
    );
  }

  void _openAuthor() {
    if (widget.item.authorMid <= 0) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BilibiliUserSpacePage(mid: widget.item.authorMid),
      ),
    );
  }

  void _openArchive() {
    final bvid = widget.item.bvid;
    if (bvid == null || bvid.isEmpty) {
      _openDetail();
      return;
    }
    openBilibiliVideo(
      context,
      bvid: bvid,
      initialTitle: widget.item.archiveTitle,
      initialCover: widget.item.archiveCover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final item = widget.item;
    final tag = dynamicTypeLabel(item.type);
                                          
                                                  
                                     
    final glass =
        SettingsService.chatGlassEnabled ||
        SettingsService.videoCardGlassEnabled;
    final card = Material(
      color: glass
          ? Colors.transparent
          : cs.surfaceContainerHigh.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openDetail,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 12, 14, widget.compact ? 10 : 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAuthorRow(theme, cs, item, tag),
              if (item.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                UgcRichText(
                  text: item.text,
                  maxLines: widget.compact ? 3 : 8,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: cs.onSurface,
                  ),
                ),
              ],
              ..._buildMedia(cs, item),
              if (item.orig != null) ...[
                const SizedBox(height: 8),
                _buildRepost(cs, item.orig!),
              ],
              if (!widget.compact) ...[
                const SizedBox(height: 6),
                _buildStats(cs, item),
              ],
            ],
          ),
        ),
      ),
    );
    if (!glass) return card;
    return NaviGlass(
      radius: 16,
      blur: 12,
      lightIntensity: 0.2,
      tintOpacity: 0.1,
      quality: GlassQuality.minimal,
      shadowElevation: 0,
      child: card,
    );
  }

  Widget _buildAuthorRow(
    ThemeData theme,
    ColorScheme cs,
    BiliDynamicDetail item,
    String tag,
  ) {
    return Row(
      children: [
        GestureDetector(
          onTap: _openAuthor,
          child: ClipOval(
            child: SizedBox(
              width: widget.compact ? 30 : 40,
              height: widget.compact ? 30 : 40,
              child: item.authorFace.isEmpty
                  ? Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        Icons.person_outline,
                        size: widget.compact ? 16 : 20,
                        color: cs.onSurfaceVariant,
                      ),
                    )
                  : Image(
                      image: CachedImageProvider(
                        BilibiliUserSpaceService.avatarUrl(item.authorFace),
                        headers: _headers,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.person_outline,
                          size: widget.compact ? 16 : 20,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _openAuthor,
                child: Text(
                  item.authorName.isEmpty
                      ? '用户${item.authorMid}'
                      : item.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.compact ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (tag.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    formatDynamicTime(item.pubTs),
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMedia(ColorScheme cs, BiliDynamicDetail item) {
    final widgets = <Widget>[];
                         
    final voteRef = _voteRef(item);
    if (voteRef != null) {
      widgets
        ..add(const SizedBox(height: 8))
        ..add(
          DynamicVotePanel(
            voteId: voteRef.voteId,
            dynamicId: item.idStr,
            compact: true,
          ),
        );
    }
                              
    final reserve = _reserve;
    if (reserve != null) {
      widgets
        ..add(const SizedBox(height: 8))
        ..add(
          DynamicReserveCard(reserve: reserve, dynamicId: item.idStr),
        );
    }
            
    if (item.images.isNotEmpty) {
      final images = item.images.take(9).toList();
      final cols = images.length == 1 ? 1 : (images.length <= 4 ? 2 : 3);
      widgets
        ..add(const SizedBox(height: 8))
        ..add(
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: images.length == 1 ? 16 / 10 : 1,
            ),
            itemCount: images.length,
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LazyCoverImage(images[i], fit: BoxFit.cover),
            ),
          ),
        );
    }
            
    final bvid = item.bvid;
    if (bvid != null && bvid.isNotEmpty) {
      widgets
        ..add(const SizedBox(height: 8))
        ..add(
          GestureDetector(
            onTap: _openArchive,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        LazyCoverImage(item.archiveCover ?? '',
                          fit: BoxFit.cover,
                        ),
                        if ((item.archiveDurationText ?? '').isNotEmpty)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.archiveDurationText!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    child: Text(
                      item.archiveTitle ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: cs.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }
          
    final articleTitle = item.articleTitle;
    if (articleTitle != null && articleTitle.isNotEmpty) {
      widgets
        ..add(const SizedBox(height: 8))
        ..add(
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.article_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    articleTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: cs.onSurface),
                  ),
                ),
              ],
            ),
          ),
        );
    }
          
    final liveTitle = item.liveTitle;
    if (liveTitle != null && liveTitle.isNotEmpty) {
      widgets
        ..add(const SizedBox(height: 8))
        ..add(
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: LazyCoverImage(item.liveCover ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Row(
                    children: [
                      Icon(Icons.live_tv, size: 14, color: cs.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$liveTitle 正在直播',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: cs.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    }
    return widgets;
  }

  Widget _buildRepost(ColorScheme cs, BiliDynamicDetail orig) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DynamicCard(item: orig, compact: true),
    );
  }

  Widget _buildStats(ColorScheme cs, BiliDynamicDetail item) {
    Widget stat(IconData icon, int count, {VoidCallback? onTap, Color? color}) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color ?? cs.onSurfaceVariant),
              const SizedBox(width: 5),
              Text(
                count > 0 ? '$count' : '--',
                style: TextStyle(
                  fontSize: 12,
                  color: color ?? cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        stat(Icons.reply_outlined, item.forwardCount),
        const Spacer(),
        stat(Icons.chat_bubble_outline, item.commentCount),
        const Spacer(),
        stat(
          _liked ? Icons.favorite : Icons.favorite_border,
          _likeCount,
          onTap: _toggleLike,
          color: _liked ? cs.error : null,
        ),
      ],
    );
  }
}
