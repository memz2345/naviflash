                                       
  
                                
                                          
                                 
                                        
                                           
                                    
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassQuality;

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/msg_settings_page.dart';
import 'package:naviflash/services/bilibili_im_service.dart';
import 'package:naviflash/services/bilibili_msg_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/app_drawer.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/msg_feed_common.dart';
import 'package:naviflash/widgets/msg_views.dart';

import 'community_interactions_page.dart';

class MessageCenterPage extends StatefulWidget {
                                             
  final bool embeddedInShell;

                                         
  final bool drawerMode;

                                           
                                    
                                      
  final Widget? topBarLeading;

  const MessageCenterPage({
    super.key,
    this.embeddedInShell = false,
    this.drawerMode = false,
    this.topBarLeading,
  });

  @override
  State<MessageCenterPage> createState() => _MessageCenterPageState();
}

class _MessageCenterPageState extends State<MessageCenterPage> {
  BiliMsgFeedUnread _unread = BiliMsgFeedUnread.zero;
  int _whisperUnread = 0;

                               
  final ValueNotifier<int> _reloadTick = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  @override
  void dispose() {
    _reloadTick.dispose();
    super.dispose();
  }

  Future<void> _loadUnread() async {
    if (!BilibiliMsgService.canUse) return;
    final feed = await BilibiliMsgService.fetchMsgFeedUnread();
    final im = await BilibiliImService.fetchUnread();
    if (!mounted) return;
    setState(() {
      _unread = feed.unread;
      _whisperUnread = im.unread.total;
    });
  }

  Future<void> _refresh() async {
    _reloadTick.value++;
    await _loadUnread();
  }

  void _openInteractions(int index) {
    if (!BilibiliMsgService.canUse) {
                              
      showAppToast(context, AppLocalizations.of(context).biliAccountNotLoggedIn);
      return;
    }
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CommunityInteractionsPage(initialIndex: index),
          ),
        )
        .then((_) {
          if (mounted) _loadUnread();
        });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
                                            
    final shellTab = widget.topBarLeading != null;
    return MsgPageScaffold(
      title: l10n.msgCenterTitle,
      showBack: !widget.embeddedInShell && !shellTab,
      showTopBar: !widget.embeddedInShell || shellTab,
      backdropScale: !widget.embeddedInShell && !shellTab,
                                        
      leading: widget.topBarLeading,
                                 
      drawer: widget.drawerMode && !widget.embeddedInShell
          ? const AppDrawer(currentPage: 'messages')
          : null,
                                         
      actions: [
        if (BilibiliMsgService.canUse) _buildMoreMenu(cs, l10n),
      ],
      child: !BilibiliMsgService.canUse
          ? MsgLoginPrompt(
              icon: Icons.forum_outlined,
              title: l10n.msgCenterLoginPrompt,
            )
          : AppRefreshIndicator(
              onRefresh: _refresh,
                                            
              edgeOffset: shellTab || !widget.embeddedInShell
                  ? kMsgTopBarHeight
                  : null,
              child: ListView(
                physics: const AppRefreshScrollPhysics(),
                                             
                                               
                padding: EdgeInsets.only(
                  top: (shellTab || !widget.embeddedInShell
                          ? kMsgTopBarHeight
                          : 0) +
                      (widget.embeddedInShell ? 12 : 8),
                  bottom: 24,
                ),
                children: [
                  _buildFeedGrid(cs, l10n),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          l10n.msgMyWhisper,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.secondary,
                          ),
                        ),
                        if (_whisperUnread > 0) ...[
                          const SizedBox(width: 6),
                          MsgUnreadBadge(count: _whisperUnread, minSize: 16),
                        ],
                        const Spacer(),
                        Text(
                          l10n.msgWhisperSubtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                                          
                  WhisperSessionListView(reloadTick: _reloadTick),
                ],
              ),
            ),
    );
  }

                                               
                        
  Widget _buildMoreMenu(ColorScheme cs, AppLocalizations l10n) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
      tooltip: l10n.playerMoreTooltip,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'settings') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MsgSettingsPage(),
            ),
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Text(l10n.msgMenuSettings),
            ],
          ),
        ),
      ],
    );
  }

                                              
  Widget _buildFeedGrid(ColorScheme cs, AppLocalizations l10n) {
    final entries = <({IconData icon, String label, int unread})>[
      (
        icon: Icons.message_outlined,
        label: l10n.msgReplyMe,
        unread: _unread.reply,
      ),
      (
        icon: Icons.alternate_email_outlined,
        label: l10n.msgAtMe,
        unread: _unread.at,
      ),
      (
        icon: Icons.favorite_border,
        label: l10n.msgLikedMe,
        unread: _unread.like,
      ),
      (
        icon: Icons.notifications_none_outlined,
        label: l10n.msgSysNotice,
        unread: _unread.sysMsg,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var i = 0; i < entries.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => _openInteractions(i),
                  borderRadius: BorderRadius.circular(14),
                                              
                  child: SettingsService.chatGlassEnabled
                      ? NaviGlass(
                          radius: 14,
                          blur: 12,
                          lightIntensity: 0.2,
                          tintOpacity: 0.1,
                          quality: GlassQuality.minimal,
                          shadowElevation: 0,
                          child: _gridCell(cs, entries[i]),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh.withValues(
                              alpha: 0.7,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: _gridCell(cs, entries[i]),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

                              
  Widget _gridCell(
    ColorScheme cs,
    ({IconData icon, String label, int unread}) entry,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(entry.icon, size: 24, color: cs.primary),
              if (entry.unread > 0)
                Positioned(
                  right: -10,
                  top: -6,
                  child: MsgUnreadBadge(count: entry.unread),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
