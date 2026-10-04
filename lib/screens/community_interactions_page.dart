                                               
  
                                            
                                          
                               
                                       
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_msg_service.dart';
import 'package:naviflash/widgets/msg_feed_common.dart';
import 'package:naviflash/widgets/msg_views.dart';

class CommunityInteractionsPage extends StatefulWidget {
                                               
  final int initialIndex;

  const CommunityInteractionsPage({super.key, this.initialIndex = 0});

  @override
  State<CommunityInteractionsPage> createState() =>
      _CommunityInteractionsPageState();
}

class _CommunityInteractionsPageState extends State<CommunityInteractionsPage>
    with TickerProviderStateMixin {
  static const int _tabCount = 4;

  late final TabController _tab = TabController(
    length: _tabCount,
    vsync: this,
    initialIndex: widget.initialIndex.clamp(0, _tabCount - 1),
  );

                                        
  late final Set<int> _visited = {_tab.index};

  BiliMsgFeedUnread _unread = BiliMsgFeedUnread.zero;

  @override
  void initState() {
    super.initState();
    _tab.addListener(_onTabChanged);
    _loadUnread();
  }

  @override
  void dispose() {
    _tab
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tab.indexIsChanging) return;
    if (_visited.add(_tab.index)) setState(() {});
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    if (!BilibiliMsgService.canUse) return;
    final feed = await BilibiliMsgService.fetchMsgFeedUnread();
    if (!mounted) return;
    setState(() => _unread = feed.unread);
  }

  int _unreadOf(int index) => switch (index) {
    0 => _unread.reply,
    1 => _unread.at,
    2 => _unread.like,
    _ => _unread.sysMsg,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.msgReplyMe,
      l10n.msgAtMe,
      l10n.msgLikedMe,
      l10n.msgSysNotice,
    ];
    return MsgPageScaffold(
      title: l10n.msgInteractions,
      bottomHeight: 44,
      bottom: TabBar(
        controller: _tab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: [
          for (var i = 0; i < labels.length; i++)
            Tab(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(labels[i]),
                  if (_unreadOf(i) > 0) ...[
                    const SizedBox(width: 5),
                    MsgUnreadBadge(count: _unreadOf(i), minSize: 16),
                  ],
                ],
              ),
            ),
        ],
      ),
      child: !BilibiliMsgService.canUse
          ? MsgLoginPrompt(
              icon: Icons.forum_outlined,
              title: l10n.msgCenterLoginPrompt,
            )
          : TabBarView(
              controller: _tab,
              children: [
                _visited.contains(0)
                    ? MsgFeedListView<BiliMsgReplyItem>(
                                                        
                        topInset: msgTopInset(hasBottom: true, bottomHeight: 44),
                        emptyIcon: Icons.message_outlined,
                        emptyText: l10n.msgReplyEmpty,
                        loginTitle: l10n.msgLoginPromptFeature(l10n.msgReplyMe),
                        loader: (cursor, cursorTime) =>
                            BilibiliMsgService.fetchReplyMe(
                              cursor: cursor,
                              cursorTime: cursorTime,
                            ),
                        onRemove: (item) => BilibiliMsgService.deleteMsgFeed(
                          tp: 0,
                          id: item.id,
                        ),
                        itemBuilder: (context, item, onDelete) =>
                            ReplyMsgTile(item: item, onDelete: onDelete),
                      )
                    : const SizedBox.shrink(),
                _visited.contains(1)
                    ? MsgFeedListView<BiliMsgAtItem>(
                                                        
                        topInset: msgTopInset(hasBottom: true, bottomHeight: 44),
                        emptyIcon: Icons.alternate_email_outlined,
                        emptyText: l10n.msgAtEmpty,
                        loginTitle: l10n.msgLoginPromptFeature(l10n.msgAtMe),
                        loader: (cursor, cursorTime) =>
                            BilibiliMsgService.fetchAtMe(
                              cursor: cursor,
                              cursorTime: cursorTime,
                            ),
                        onRemove: (item) => BilibiliMsgService.deleteMsgFeed(
                          tp: 0,
                          id: item.id,
                        ),
                        itemBuilder: (context, item, onDelete) =>
                            AtMsgTile(item: item, onDelete: onDelete),
                      )
                    : const SizedBox.shrink(),
                _visited.contains(2)
                    ? const MsgLikeMeView()
                    : const SizedBox.shrink(),
                _visited.contains(3)
                    ? MsgFeedListView<BiliMsgSysItem>(
                                                        
                        topInset: msgTopInset(hasBottom: true, bottomHeight: 44),
                        emptyIcon: Icons.notifications_none_outlined,
                        emptyText: l10n.msgSysEmpty,
                        loginTitle: l10n.msgLoginPromptFeature(
                          l10n.msgSysNotice,
                        ),
                        loader: (cursor, cursorTime) =>
                            BilibiliMsgService.fetchSysMsg(cursor: cursor),
                        itemBuilder: (context, item, onDelete) =>
                            SysMsgTile(item: item, onDelete: onDelete),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
    );
  }
}
