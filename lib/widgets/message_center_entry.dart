                                        
  
                               
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';

import 'package:naviflash/screens/message_center_page.dart';
import 'package:naviflash/services/bilibili_im_service.dart';
import 'package:naviflash/services/bilibili_msg_service.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/msg_feed_common.dart';

                            
                          
class MessageCenterIconEntry extends StatefulWidget {
  const MessageCenterIconEntry({super.key});

  @override
  State<MessageCenterIconEntry> createState() => _MessageCenterIconEntryState();
}

class _MessageCenterIconEntryState extends State<MessageCenterIconEntry> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!BilibiliMsgService.canUse) return;
    final feed = await BilibiliMsgService.fetchMsgFeedUnread();
    final im = await BilibiliImService.fetchUnread();
    if (!mounted) return;
    setState(() => _unread = feed.unread.total + im.unread.total);
  }

  Future<void> _open() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MessageCenterPage()));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          MorphIconButton(
            icon: Icons.email_outlined,
            tooltip: l10n.msgCenterTitle,
            onTap: _open,
            frosted: true,
          ),
          if (_unread > 0)
            Positioned(
              top: 1,
              right: 0,
              child: MsgUnreadBadge(count: _unread, minSize: 16),
            ),
        ],
      ),
    );
  }
}

class MessageCenterEntry extends StatefulWidget {
                              
  final bool dense;

                        
  final VoidCallback? onTap;

  const MessageCenterEntry({super.key, this.dense = false, this.onTap});

  @override
  State<MessageCenterEntry> createState() => _MessageCenterEntryState();
}

class _MessageCenterEntryState extends State<MessageCenterEntry> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!BilibiliMsgService.canUse) return;
    final feed = await BilibiliMsgService.fetchMsgFeedUnread();
    final im = await BilibiliImService.fetchUnread();
    if (!mounted) return;
    setState(() => _unread = feed.unread.total + im.unread.total);
  }

  Future<void> _open() async {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MessageCenterPage()));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final badge = MsgUnreadBadge(count: _unread);
    if (widget.dense) {
      return ListTile(
        leading: Icon(Icons.forum_outlined, color: cs.primary),
        title: Text(AppLocalizations.of(context).msgCenterTitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge,
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
        onTap: _open,
      );
    }
    return ListTile(
      leading: Icon(Icons.forum_outlined, color: cs.primary),
      title: Text(AppLocalizations.of(context).msgCenterTitle),
      subtitle: _unread > 0
          ? Text(AppLocalizations.of(context).msgUnreadCount(_unread))
          : Text(AppLocalizations.of(context).msgCenterSubtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
      onTap: _open,
    );
  }
}
