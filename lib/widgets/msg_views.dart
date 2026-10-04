                             
  
                                           
                                                     
                               
  
                                         
                                       
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassQuality;

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/screens/msg_like_detail_page.dart';
import 'package:naviflash/screens/whisper_chat_page.dart';
import 'package:naviflash/services/bili_uri_router.dart';
import 'package:naviflash/services/bilibili_im_service.dart';
import 'package:naviflash/services/bilibili_msg_service.dart';
import 'package:naviflash/services/bv_av.dart';
import 'package:naviflash/services/link_utils.dart';
import 'package:naviflash/services/native_menu_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/more_menu_sheet.dart';
import 'package:naviflash/widgets/msg_feed_common.dart';
import 'package:naviflash/widgets/page_loading.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

                                           
                         
                                           

                                       
Widget msgGlassCard({
  required Widget child,
  double radius = 16,
  EdgeInsetsGeometry? margin,
}) {
  final card = ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: child,
  );
  final body = (SettingsService.chatGlassEnabled ||
      SettingsService.videoCardGlassEnabled)
      ? NaviGlass(
          radius: radius,
          blur: 12,
          lightIntensity: 0.2,
          tintOpacity: 0,
                                                  
                                                          
                                             
                               
                                                
                                                  
                                 
          quality: GlassQuality.minimal,
                                                    
                                  
          shadowElevation: 0,
          child: child,
        )
      : card;
  if (margin == null) return body;
  return Padding(padding: margin, child: body);
}

                                              
Color msgCardColor(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return (SettingsService.chatGlassEnabled ||
          SettingsService.videoCardGlassEnabled)
      ? Colors.transparent
      : cs.surfaceContainerHigh.withValues(alpha: 0.55);
}

                                       
                                        
void openMsgContent(BuildContext context, BiliMsgContent content) {
  if (content.nativeUri.isNotEmpty && openBiliUri(context, content.nativeUri)) {
    return;
  }
  if (content.subjectId > 0) {
    final bvid = BvAv.encode(content.subjectId);
    if (bvid != null) openBilibiliVideo(context, bvid: bvid);
  }
}

                              
const EdgeInsets kMsgCardMargin = EdgeInsets.fromLTRB(12, 0, 12, 8);

                                           
          
                                           

class WhisperSessionListView extends StatefulWidget {
                                   
  final ValueNotifier<int>? reloadTick;

  const WhisperSessionListView({super.key, this.reloadTick});

  @override
  State<WhisperSessionListView> createState() => _WhisperSessionListViewState();
}

                                       
                  
class _WhisperSessionListViewState extends State<WhisperSessionListView> {
  final List<BiliImSession> _sessions = [];
  int? _offset;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.reloadTick?.addListener(_onReloadTick);
    _load();
  }

  @override
  void dispose() {
    widget.reloadTick?.removeListener(_onReloadTick);
    super.dispose();
  }

  void _onReloadTick() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _sessions.isEmpty;
      _error = null;
    });
    final BiliImSessionPage page;
    try {
      page = await BilibiliImService.fetchSessions();
    } catch (e) {
                                          
                                     
      if (kDebugMode) debugPrint('[Msg] 会话列表加载异常: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '网络异常，请重试';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = page.err;
      _offset = page.offset;
      _hasMore = page.hasMore;
      if (page.err == null) {
        _sessions
          ..clear()
          ..addAll(page.sessions);
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading || _error != null) return;
    final offset = _offset;
    if (offset == null || offset <= 0) return;
    setState(() => _loadingMore = true);
    final BiliImSessionPage page;
    try {
      page = await BilibiliImService.fetchSessions(offset: offset);
    } catch (e) {
      if (kDebugMode) debugPrint('[Msg] 会话列表翻页异常: $e');
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _hasMore = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (page.err != null) {
        _hasMore = false;
        return;
      }
      final seen = _sessions.map((e) => e.talkerId).toSet();
      final fresh = page.sessions
          .where((e) => !seen.contains(e.talkerId))
          .toList(growable: false);
      if (fresh.isEmpty) {
        _hasMore = false;
        return;
      }
      _sessions.addAll(fresh);
      _offset = page.offset;
      _hasMore = page.hasMore;
    });
  }

  Future<void> _togglePin(BiliImSession session) async {
    final pinned = session.pinned;
    final r = await BilibiliImService.setPinned(
      talkerId: session.talkerId,
      pinned: !pinned,
    );
    if (!mounted) return;
    if (r.ok) {
      showAppToast(
        context,
        pinned
            ? AppLocalizations.of(context).msgUnpinned
            : AppLocalizations.of(context).msgPinned,
      );
      _load();
    } else {
      showAppToast(context, r.message, error: true);
    }
  }

  Future<void> _deleteSession(BiliImSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).msgDeleteSessionTitle,
          style: const TextStyle(fontSize: 16),
        ),
        content: Text(
          AppLocalizations.of(context).msgDeleteSessionBody,
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final r = await BilibiliImService.deleteSession(talkerId: session.talkerId);
    if (!mounted) return;
    if (r.ok) {
      setState(() => _sessions.remove(session));
      showAppToast(context, AppLocalizations.of(context).msgDeleted);
    } else {
      showAppToast(context, r.message, error: true);
    }
  }

  Future<void> _showActions(BiliImSession session) async {
    final l10n = AppLocalizations.of(context);
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      items: [
        NativeMenuItem(
          text: session.pinned ? l10n.msgUnpin : l10n.msgPin,
          icon: session.pinned ? Icons.push_pin_outlined : Icons.push_pin,
          onTap: () => _togglePin(session),
        ),
        NativeMenuItem(
          text: l10n.msgDeleteSession,
          icon: Icons.delete_outline,
          destructive: true,
          onTap: () => _deleteSession(session),
        ),
      ],
    );
    if (nativeOk || !mounted) return;
    return showAppBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                session.pinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(
                session.pinned
                    ? AppLocalizations.of(context).msgUnpin
                    : AppLocalizations.of(context).msgPin,
              ),
              onTap: () {
                Navigator.pop(ctx);
                _togglePin(session);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(AppLocalizations.of(context).msgDeleteSession),
              onTap: () {
                Navigator.pop(ctx);
                _deleteSession(session);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChat(BiliImSession session) async {
    if (session.unread > 0 && session.maxSeqno > 0) {
      BilibiliImService.ackSession(
        talkerId: session.talkerId,
        ackSeqno: session.maxSeqno,
      );
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhisperChatPage(
          talkerId: session.talkerId,
          name: session.name,
          face: session.face,
          pinned: session.pinned,
        ),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!BilibiliImService.canUse && _sessions.isEmpty && !_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: MsgLoginPrompt(
          icon: Icons.mail_outline,
          title: AppLocalizations.of(context).msgLoginPromptWhisper,
        ),
      );
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: LoadingIndicatorM3E()),
      );
    }
    if (_error != null && _sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            LoadRetryPill(onRetry: _load),
          ],
        ),
      );
    }
    if (_sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: MsgEmptyView(
          icon: Icons.mail_outline,
          title: AppLocalizations.of(context).msgWhisperEmpty,
          subtitle: AppLocalizations.of(context).msgWhisperEmptySubtitle,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final session in _sessions)
          GestureDetector(
            onSecondaryTap: () => _showActions(session),
            child: msgGlassCard(
              margin: kMsgCardMargin,
              child: _SessionTile(
                session: session,
                onTap: () => _openChat(session),
                onLongPress: () => _showActions(session),
              ),
            ),
          ),
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: OutlinedButton(
              onPressed: _loadingMore ? null : _loadMore,
              child: _loadingMore
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppLocalizations.of(context).msgLoadMore),
            ),
          ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final BiliImSession session;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SessionTile({
    required this.session,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final summary = session.summary;
    return Material(
      color: session.pinned
          ? cs.onInverseSurface.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.4 : 0.6,
            )
          : msgCardColor(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: onTap,
        onLongPress: onLongPress,
        leading: MsgAvatar(url: session.face, mid: session.talkerId, size: 46),
        title: Row(
          children: [
            Expanded(
              child: Text(
                session.name.isEmpty
                    ? AppLocalizations.of(
                        context,
                      ).msgUserFallback('${session.talkerId}')
                    : session.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (session.timestamp > 0)
              Text(
                formatMsgTime(session.timestampSeconds),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              if (session.pinned) ...[
                Icon(Icons.push_pin, size: 12, color: cs.primary),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  summary.isEmpty
                      ? AppLocalizations.of(context).msgNoMessage
                      : summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ),
              if (session.unread > 0) ...[
                const SizedBox(width: 8),
                MsgUnreadBadge(count: session.unread),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

                                           
                              
                                           

typedef MsgItemBuilder<T> =
    Widget Function(BuildContext context, T item, VoidCallback onDelete);

class MsgFeedListView<T> extends StatefulWidget {
  final IconData emptyIcon;
  final String emptyText;
  final String loginTitle;
  final Future<BiliMsgPage<T>> Function(int? cursor, int? cursorTime) loader;
  final MsgItemBuilder<T> itemBuilder;
  final Future<({bool ok, String message})> Function(T item)? onRemove;

                                                
                                            
  final double topInset;

  const MsgFeedListView({
    super.key,
    required this.emptyIcon,
    required this.emptyText,
    required this.loginTitle,
    required this.loader,
    required this.itemBuilder,
    this.onRemove,
    this.topInset = 8,
  });

  @override
  State<MsgFeedListView<T>> createState() => _MsgFeedListViewState<T>();
}

class _MsgFeedListViewState<T> extends State<MsgFeedListView<T>>
    with AutomaticKeepAliveClientMixin {
  final List<T> _items = [];
  final ScrollController _scroll = ScrollController();
  bool _loading = true;
  bool _loadingMore = false;
  bool _end = false;
  String? _error;
  int? _cursor;
  int? _cursorTime;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) _loadMore();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    final BiliMsgPage<T> page;
    try {
      page = await widget.loader(null, null);
    } catch (e) {
                                              
                         
      if (kDebugMode) debugPrint('[Msg] 消息列表加载异常: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '网络异常，请重试';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = page.err;
      _end = page.isEnd;
      _cursor = page.cursor;
      _cursorTime = page.cursorTime;
      if (page.err == null) {
        _items
          ..clear()
          ..addAll(page.items);
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _end || _loading || _error != null) return;
    if (_cursor == null && _cursorTime == null) return;
    setState(() => _loadingMore = true);
    final BiliMsgPage<T> page;
    try {
      page = await widget.loader(_cursor, _cursorTime);
    } catch (e) {
      if (kDebugMode) debugPrint('[Msg] 消息列表翻页异常: $e');
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _end = true;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (page.err != null) {
        _error = page.err;
        return;
      }
      _cursor = page.cursor;
      _cursorTime = page.cursorTime;
      _end = page.isEnd;
      final seen = _items.length;
      _items.addAll(page.items);
      if (_items.length == seen) _end = true;
    });
  }

  Future<void> _confirmRemove(T item) async {
    final remove = widget.onRemove;
    if (remove == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).msgDeleteNoticeConfirm,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final r = await remove(item);
    if (!mounted) return;
    if (r.ok) {
      setState(() => _items.remove(item));
      showAppToast(context, AppLocalizations.of(context).msgDeleted);
    } else {
      showAppToast(context, r.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    if (!BilibiliMsgService.canUse && _items.isEmpty && !_loading) {
      return MsgLoginPrompt(icon: widget.emptyIcon, title: widget.loginTitle);
    }
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _items.isEmpty,
    )) {
      return const PageLoadingIndicator();
    }
    if (_error != null && _items.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: LoadRetryPill(onRetry: _load),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return MsgEmptyView(icon: widget.emptyIcon, title: widget.emptyText);
    }
    return AppRefreshIndicator(
      onRefresh: _load,
                                    
      edgeOffset: widget.topInset > 8 ? widget.topInset : null,
      child: ListView.builder(
        controller: _scroll,
        physics: const AppRefreshScrollPhysics(),
        padding: EdgeInsets.fromLTRB(12, widget.topInset, 12, 24),
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            if (_loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            if (_end && _items.length > 8) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).msgNoMore,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
              );
            }
            return const SizedBox(height: 8);
          }
          final item = _items[index];
          return GestureDetector(
            onSecondaryTap: () => _confirmRemove(item),
            child: msgGlassCard(
              margin: kMsgCardMargin,
              child: widget.itemBuilder(
                context,
                item,
                () => _confirmRemove(item),
              ),
            ),
          );
        },
      ),
    );
  }
}

                                           
        
                                           

class MsgLikeMeView extends StatefulWidget {
  const MsgLikeMeView({super.key});

  @override
  State<MsgLikeMeView> createState() => _MsgLikeMeViewState();
}

class _MsgLikeMeViewState extends State<MsgLikeMeView>
    with AutomaticKeepAliveClientMixin {
  final List<BiliMsgLikeItem> _latest = [];
  final List<BiliMsgLikeItem> _total = [];
  final ScrollController _scroll = ScrollController();
  bool _loading = true;
  bool _loadingMore = false;
  bool _end = false;
  String? _error;
  int? _cursor;
  int? _cursorTime;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) _loadMore();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _latest.isEmpty && _total.isEmpty;
      _error = null;
    });
    final page = await BilibiliMsgService.fetchLikeMe();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = page.err;
      _end = page.isEnd;
      _cursor = page.cursor;
      _cursorTime = page.cursorTime;
      if (page.err == null) {
        _latest
          ..clear()
          ..addAll(page.latest);
        _total
          ..clear()
          ..addAll(page.total);
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _end || _loading || _error != null) return;
    if (_cursor == null && _cursorTime == null) return;
    setState(() => _loadingMore = true);
    final page = await BilibiliMsgService.fetchLikeMe(
      cursor: _cursor,
      cursorTime: _cursorTime,
    );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (page.err != null) {
        _error = page.err;
        return;
      }
      _cursor = page.cursor;
      _cursorTime = page.cursorTime;
      _end = page.isEnd;
      final before = _total.length;
      _total.addAll(page.total);
      if (_total.length == before) _end = true;
    });
  }

  Future<void> _remove(BiliMsgLikeItem item, {required bool isLatest}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).msgDeleteNoticeTitle,
          style: const TextStyle(fontSize: 16),
        ),
        content: Text(
          AppLocalizations.of(context).msgDeleteNoticeBody,
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final r = await BilibiliMsgService.deleteMsgFeed(tp: 0, id: item.id);
    if (!mounted) return;
    if (r.ok) {
      setState(() {
        if (isLatest) {
          _latest.remove(item);
        } else {
          _total.remove(item);
        }
      });
      showAppToast(context, AppLocalizations.of(context).msgDeleted);
    } else {
      showAppToast(context, r.message, error: true);
    }
  }

  Future<void> _toggleNotice(BiliMsgLikeItem item) async {
    final enable = item.noticeState == 0;
    if (enable) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            AppLocalizations.of(context).msgMuteNotice,
            style: const TextStyle(fontSize: 16),
          ),
          content: Text(
            AppLocalizations.of(context).msgMuteNoticeBody,
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context).commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(context).commonOk),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final r = await BilibiliMsgService.setNotice(
      id: item.id,
      noticeState: enable ? 1 : 0,
    );
    if (!mounted) return;
    if (r.ok) {
      setState(() => item.noticeState = enable ? 1 : 0);
      showAppToast(context, AppLocalizations.of(context).msgSettingSaved);
    } else {
      showAppToast(context, r.message, error: true);
    }
  }

  void _open(BiliMsgLikeItem item) {
    if (item.counts > 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MsgLikeDetailPage(
            cardId: item.id,
            title: item.title,
            nativeUri: item.nativeUri,
          ),
        ),
      );
      return;
    }
    if (item.nativeUri.isNotEmpty) {
      openBiliUri(context, item.nativeUri);
    }
  }

  Future<void> _showActions(BiliMsgLikeItem item, {required bool isLatest}) async {
    final noticeOn = item.noticeState == 0;
    final l10n = AppLocalizations.of(context);
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      items: [
        NativeMenuItem(
          text: l10n.commonDelete,
          icon: Icons.delete_outline,
          destructive: true,
          onTap: () => _remove(item, isLatest: isLatest),
        ),
        NativeMenuItem(
          text: noticeOn ? l10n.msgMuteNotice : l10n.msgUnmuteNotice,
          icon: noticeOn
              ? Icons.notifications_off_outlined
              : Icons.notifications_active_outlined,
          onTap: () => _toggleNotice(item),
        ),
      ],
    );
    if (nativeOk || !mounted) return;
    return showAppBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(AppLocalizations.of(context).commonDelete),
              onTap: () {
                Navigator.pop(ctx);
                _remove(item, isLatest: isLatest);
              },
            ),
            ListTile(
              leading: Icon(
                noticeOn
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_active_outlined,
              ),
              title: Text(
                noticeOn
                    ? AppLocalizations.of(context).msgMuteNotice
                    : AppLocalizations.of(context).msgUnmuteNotice,
              ),
              onTap: () {
                Navigator.pop(ctx);
                _toggleNotice(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    if (!BilibiliMsgService.canUse && _latest.isEmpty && _total.isEmpty) {
      return MsgLoginPrompt(
        icon: Icons.favorite_border,
        title: AppLocalizations.of(context).msgLoginPromptLikes,
      );
    }
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _latest.isEmpty && _total.isEmpty,
    )) {
      return const PageLoadingIndicator();
    }
    if (_error != null && _latest.isEmpty && _total.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: LoadRetryPill(onRetry: _load),
          ),
        ],
      );
    }
    if (_latest.isEmpty && _total.isEmpty) {
      return MsgEmptyView(
        icon: Icons.favorite_border,
        title: AppLocalizations.of(context).msgLikedEmpty,
        subtitle: AppLocalizations.of(context).msgLikedEmptySubtitle,
      );
    }
    return AppRefreshIndicator(
      onRefresh: _load,
                                       
      edgeOffset: msgTopInset(hasBottom: true),
      child: CustomScrollView(
        controller: _scroll,
        physics: const AppRefreshScrollPhysics(),
        slivers: [
                                          
          SliverToBoxAdapter(
            child: SizedBox(height: msgTopInset(hasBottom: true)),
          ),
          if (_latest.isNotEmpty) ...[
            _header(cs, AppLocalizations.of(context).msgSectionLatest),
            SliverList.builder(
              itemCount: _latest.length,
              itemBuilder: (context, i) => GestureDetector(
                onSecondaryTap: () => _showActions(_latest[i], isLatest: true),
                child: msgGlassCard(
                  margin: kMsgCardMargin,
                  child: LikeMsgTile(
                    item: _latest[i],
                    onTap: () => _open(_latest[i]),
                    onLongPress: () => _showActions(_latest[i], isLatest: true),
                  ),
                ),
              ),
            ),
          ],
          if (_total.isNotEmpty) ...[
            _header(cs, AppLocalizations.of(context).msgSectionTotal),
            SliverList.builder(
              itemCount: _total.length,
              itemBuilder: (context, i) => GestureDetector(
                onSecondaryTap: () => _showActions(_total[i], isLatest: false),
                child: msgGlassCard(
                  margin: kMsgCardMargin,
                  child: LikeMsgTile(
                    item: _total[i],
                    onTap: () => _open(_total[i]),
                    onLongPress: () => _showActions(_total[i], isLatest: false),
                  ),
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: _loadingMore
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _end
                    ? Text(
                        AppLocalizations.of(context).msgNoMore,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(ColorScheme cs, String title) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.secondary,
        ),
      ),
    ),
  );
}

                                           
                               
                                           

         
class ReplyMsgTile extends StatelessWidget {
  final BiliMsgReplyItem item;
  final VoidCallback onDelete;

  const ReplyMsgTile({super.key, required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = item.user;
    final content = item.content;
    return Material(
      color: msgCardColor(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: (content.nativeUri.isEmpty && content.subjectId <= 0)
            ? null
            : () => openMsgContent(context, content),
        onLongPress: onDelete,
        leading: MsgAvatar(url: user.avatar, mid: user.mid),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: user.nickname.isEmpty
                    ? AppLocalizations.of(
                        context,
                      ).msgUserFallback('${user.mid}')
                    : user.nickname,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.isMulti == 1)
                TextSpan(
                  text: AppLocalizations.of(context).msgEtAl,
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 12),
                ),
              TextSpan(
                text: AppLocalizations.of(
                  context,
                ).msgReplyTitle(content.business, item.counts),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.sourceContent.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                content.sourceContent,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (content.targetReplyContent.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '| ${content.targetReplyContent}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(color: cs.outline),
              ),
            ],
            if (content.rootReplyContent.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '| ${content.rootReplyContent}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(color: cs.outline),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              formatMsgTime(item.replyTime),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: cs.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

        
class AtMsgTile extends StatelessWidget {
  final BiliMsgAtItem item;
  final VoidCallback onDelete;

  const AtMsgTile({super.key, required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = item.user;
    final content = item.content;
    return Material(
      color: msgCardColor(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: (content.nativeUri.isEmpty && content.subjectId <= 0)
            ? null
            : () => openMsgContent(context, content),
        onLongPress: onDelete,
        leading: MsgAvatar(url: user.avatar, mid: user.mid),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: user.nickname.isEmpty
                    ? AppLocalizations.of(
                        context,
                      ).msgUserFallback('${user.mid}')
                    : user.nickname,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: AppLocalizations.of(context).msgAtTitle(content.business),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.sourceContent.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                content.sourceContent,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              formatMsgTime(item.atTime),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: cs.outline,
              ),
            ),
          ],
        ),
        trailing: content.image.isEmpty
            ? null
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  content.image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 56),
                ),
              ),
      ),
    );
  }
}

         
class SysMsgTile extends StatelessWidget {
  final BiliMsgSysItem item;
  final VoidCallback onDelete;

  const SysMsgTile({super.key, required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final link = firstLink(item.content);
    return Material(
      color: msgCardColor(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: () {
                                      
          if (link != null) {
            openLinkInBuiltInBrowser(context, url: link, confirm: false);
          }
          if (item.cursor > 0) {
            BilibiliMsgService.updateSysCursor(item.cursor);
          }
        },
        onLongPress: onDelete,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_none_outlined,
            size: 22,
            color: cs.onPrimaryContainer,
          ),
        ),
        title: Text(
          item.title.isEmpty
              ? AppLocalizations.of(context).msgSysNotice
              : item.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.content.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              formatMsgTimeText(item.timeAt),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: cs.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

         
class LikeMsgTile extends StatelessWidget {
  final BiliMsgLikeItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const LikeMsgTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final users = item.users;
                                               
    final latest = users.isEmpty ? BiliMsgUser.empty : users.last;
    final latestText = latest.nickname.isEmpty
        ? AppLocalizations.of(context).msgUserFallback('${latest.mid}')
        : latest.nickname;
    final names = users.isEmpty
        ? AppLocalizations.of(context).msgSomeone
        : users.length == 1
        ? latestText
        : AppLocalizations.of(context).msgEtAlCount(latestText, item.counts);
    return Material(
      color: msgCardColor(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: onTap,
        onLongPress: onLongPress,
        leading: LikeAvatarStack(users: users),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: names,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: item.business.isEmpty
                    ? AppLocalizations.of(context).msgLikedYou
                    : AppLocalizations.of(
                        context,
                      ).msgLikedYourBusiness(item.business),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (item.noticeState == 1)
                TextSpan(
                  text: '  · ${AppLocalizations.of(context).msgNoticeMuted}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.outline,
                  ),
                ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.title.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              formatMsgTime(item.likeTime),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: cs.outline,
              ),
            ),
          ],
        ),
        trailing: item.image.isEmpty
            ? null
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 56),
                ),
              ),
      ),
    );
  }
}

                                             
class LikeAvatarStack extends StatelessWidget {
  final List<BiliMsgUser> users;

  const LikeAvatarStack({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const MsgAvatar(url: '');
    if (users.length == 1) {
      return MsgAvatar(url: users.last.avatar, mid: users.last.mid, size: 45);
    }
    final shown = users.reversed.take(4).toList();
    return SizedBox(
      width: 45,
      height: 45,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: 15.0 * (i % 2),
              top: 15.0 * (i ~/ 2),
              child: MsgAvatar(
                url: shown[i].avatar,
                mid: shown[i].mid,
                size: 30,
              ),
            ),
        ],
      ),
    );
  }
}
