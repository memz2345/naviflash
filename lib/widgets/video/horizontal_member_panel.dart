                                                 
  
                                     
                                                        
                                             
                                      
                                         
                                

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_user_space_page_v2.dart';
import 'package:naviflash/services/bilibili_interaction_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/page_loading.dart';
import 'package:naviflash/widgets/video_card.dart';

class HorizontalMemberPanel extends StatefulWidget {
  const HorizontalMemberPanel({
    super.key,
    required this.mid,
    this.name,
    this.face,
    this.focusBvid,
    this.onClose,
    required this.onPickVideo,
  });

  final int mid;

                                      
  final String? name;
  final String? face;

                          
  final String? focusBvid;

  final VoidCallback? onClose;

                                    
  final void Function(String bvid) onPickVideo;


  @override
  State<HorizontalMemberPanel> createState() => _HorizontalMemberPanelState();
}

class _HorizontalMemberPanelState extends State<HorizontalMemberPanel> {
  BiliUserSpaceCard? _card;
  final List<BiliUserVideo> _videos = [];
  int _count = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _pn = 1;
  String _order = 'pubdate';
  String? _error;

  int? _attribute;                                 
  bool _followBusy = false;

  late final ScrollController _scrollCtrl = ScrollController()
    ..addListener(_onScroll);

  @override
  void initState() {
    super.initState();
    unawaited(_load(refresh: true));
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 400) {
      unawaited(_loadMore());
    }
  }

  Future<void> _load({required bool refresh}) async {
    if (refresh && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    _pn = 1;
    final results = await Future.wait<dynamic>([
      BilibiliUserSpaceService.fetchUserCard(mid: widget.mid),
      BilibiliUserSpaceService.fetchUserRelation(mid: widget.mid),
      BilibiliUserSpaceService.fetchUserVideos(
        mid: widget.mid,
        pn: 1,
        ps: 20,
        order: _order,
      ),
    ]);
    if (!mounted) return;
    final card = results[0] as BiliUserSpaceCard?;
    final attr = results[1] as int?;
    final page = results[2] as BiliUserVideoPage?;
    if (page == null && _videos.isNotEmpty) {
                          
      setState(() => _loading = false);
      showAppToast(
        context,
        BilibiliUserSpaceService.lastErrorDetail ?? '刷新失败',
        error: true,
      );
      return;
    }
    setState(() {
      _card = card;
      _attribute = attr;
      _videos
        ..clear()
        ..addAll(page?.videos ?? const <BiliUserVideo>[]);
      _count = page?.count ?? _videos.length;
      _hasMore = _videos.length < (_count <= 0 ? _videos.length + 1 : _count);
      _loading = false;
      _error = _videos.isEmpty
          ? (BilibiliUserSpaceService.lastErrorDetail ?? '加载失败')
          : null;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    final next = _pn + 1;
    final page = await BilibiliUserSpaceService.fetchUserVideos(
      mid: widget.mid,
      pn: next,
      ps: 20,
      order: _order,
    );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      final added = page?.videos ?? const <BiliUserVideo>[];
      if (added.isEmpty) {
        _hasMore = false;
      } else {
        _pn = next;
        _videos.addAll(added);
        if (added.length < 20) _hasMore = false;
      }
    });
  }

  Future<void> _switchOrder(String order) async {
    if (_order == order) return;
    setState(() => _order = order);
    await _load(refresh: true);
  }

  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    final followed = (_attribute ?? 0) != 0;
    setState(() => _followBusy = true);
    final r = await BilibiliInteractionService.followUser(
      mid: widget.mid,
      act: followed ? 2 : 1,
    );
    if (!mounted) return;
    setState(() {
      _followBusy = false;
      if (r.ok) _attribute = followed ? 0 : 2;
    });
    showAppToast(context, r.message);
  }

  void _openFullSpace() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BilibiliUserSpacePage(
          mid: widget.mid,
          focusBvid: widget.focusBvid,
        ),
      ),
    );
  }

  void _pick(BiliUserVideo v) => widget.onPickVideo(v.bvid);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      color: cs.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(cs, l10n),
          Divider(height: 1, thickness: 1, color: cs.outlineVariant),
          Expanded(child: _buildList(cs, l10n)),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, AppLocalizations l10n) {
    final card = _card;
    final name = card?.name ?? widget.name ?? '';
    final face = card?.face ?? widget.face ?? '';
    final followed = (_attribute ?? 0) != 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                l10n.memberLiteTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l10n.commonClose,
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              ClipOval(
                child: face.isEmpty
                    ? Container(
                        width: 48,
                        height: 48,
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.person, color: cs.onSurfaceVariant),
                      )
                    : Image(
                        image: CachedImageProvider(face),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: cs.surfaceContainerHighest,
                          child: Icon(Icons.person, color: cs.onSurfaceVariant),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmtCount(card?.fans ?? 0)} 粉丝 · '
                      '${_fmtCount(card?.archiveCount ?? 0)} 视频',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _followBusy ? null : _toggleFollow,
                  icon: Icon(
                    followed
                        ? Icons.person_remove_outlined
                        : Icons.person_add_alt_1_outlined,
                    size: 16,
                  ),
                  label: Text(
                    followed ? l10n.videoFollowedLabel : l10n.videoFollowLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _openFullSpace,
                  icon: const Icon(Icons.open_in_new_outlined, size: 16),
                  label: Text(
                    l10n.memberLiteGoSpace,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList(ColorScheme cs, AppLocalizations l10n) {
    if (shouldShowFullScreenLoading(loading: _loading, isEmpty: _videos.isEmpty)) {
      return const PageLoadingIndicator();
    }
    if (_videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_library_outlined, color: cs.outline, size: 36),
              const SizedBox(height: 8),
              Text(
                _error ?? l10n.memberLiteEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _load(refresh: true),
                child: Text(l10n.audioPageRetry),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                                                      
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 6, 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.memberLiteVideoCount('$_count'),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              TextButton.icon(
                style: const ButtonStyle(
                  visualDensity: VisualDensity(
                    horizontal: -2,
                    vertical: -1.25,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _switchOrder(
                  _order == 'pubdate' ? 'click' : 'pubdate',
                ),
                icon: Icon(Icons.sort, size: 16, color: cs.secondary),
                label: Text(
                  _order == 'pubdate'
                      ? l10n.memberLiteOrderPubdate
                      : l10n.memberLiteOrderClick,
                  style: TextStyle(fontSize: 13, color: cs.secondary),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            itemCount: _videos.length + (_hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              if (i >= _videos.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final v = _videos[i];
              final active =
                  (widget.focusBvid ?? '').isNotEmpty &&
                  widget.focusBvid == v.bvid;
              return VideoCardH(
                data: VideoCardData(
                  cover: v.pic,
                  title: v.title,
                  ownerName: v.author,
                  view: v.play,
                  danmaku: v.danmaku,
                  duration: v.duration,
                  pubdate: v.created,
                ),
                onTap: () => _pick(v),
                trailing: active
                    ? Icon(
                        Icons.graphic_eq_rounded,
                        size: 16,
                        color: cs.primary,
                      )
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  static String _fmtCount(int v) {
    if (v <= 0) return '0';
    if (v >= 100000000) return '${(v / 100000000).toStringAsFixed(1)}亿';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(1)}万';
    return '$v';
  }
}

