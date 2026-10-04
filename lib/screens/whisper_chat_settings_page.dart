                                              
  
                                                    
                                     
                                        
                            
                                                                      
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/services/bilibili_im_service.dart';
import 'package:naviflash/services/bilibili_interaction_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/msg_feed_common.dart';

class WhisperChatSettingsPage extends StatefulWidget {
  final int talkerId;
  final String name;
  final String face;

                                         
  final bool pinned;

  const WhisperChatSettingsPage({
    super.key,
    required this.talkerId,
    this.name = '',
    this.face = '',
    this.pinned = false,
  });

  @override
  State<WhisperChatSettingsPage> createState() =>
      _WhisperChatSettingsPageState();
}

class _WhisperChatSettingsPageState extends State<WhisperChatSettingsPage> {
  bool _loading = true;
  bool _busy = false;
  String? _error;

  String _name = '';
  String _face = '';
  String _sign = '';

  BiliImSessionSettings? _settings;
  bool _pinned = false;
  bool? _muted;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _face = widget.face;
    _pinned = widget.pinned;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
                             
    final settingsFuture = BilibiliImService.fetchSessionSettings(
      talkerUid: widget.talkerId,
    );
    final dndFuture = BilibiliImService.fetchMsgDnd(talkerUid: widget.talkerId);
    final cardFuture = BilibiliUserSpaceService.fetchUserCard(
      mid: widget.talkerId,
    );
    final settings = await settingsFuture;
    final dnd = await dndFuture;
    final card = await cardFuture;
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = settings.err;
      _settings = settings.data;
      if (settings.data != null) _blocked = settings.data!.isBlocked;
      _muted = dnd.muted;
      if (card != null) {
        if (card.name.isNotEmpty) _name = card.name;
        if (card.face.isNotEmpty) _face = card.face;
        _sign = card.sign;
      }
    });
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted || message.isEmpty) return;
    showAppToast(context, message, error: error);
  }

  Future<void> _togglePush(bool enabled) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    if (!enabled) {
      final confirmed = await _confirm(
        title: l10n.msgPushCloseConfirm,
        body: l10n.msgPushReceiveDesc,
      );
      if (confirmed != true) return;
    }
    setState(() => _busy = true);
    final r = await BilibiliImService.setPushSetting(
      talkerUid: widget.talkerId,
      enabled: enabled,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r.ok) {
        final current = _settings ?? const BiliImSessionSettings();
        _settings = current.copyWith(
          pushSetting: enabled ? 0 : 1,
          showPushSetting: 1,
        );
      }
    });
    if (!r.ok) _toast(r.message, error: true);
  }

  Future<void> _togglePin(bool pinned) async {
    if (_busy) return;
    setState(() => _busy = true);
    final r = await BilibiliImService.setPinned(
      talkerId: widget.talkerId,
      pinned: pinned,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r.ok) _pinned = pinned;
    });
    if (r.ok) {
      final l10n = AppLocalizations.of(context);
      _toast(pinned ? l10n.msgPinned : l10n.msgUnpinned);
    } else {
      _toast(r.message, error: true);
    }
  }

  Future<void> _toggleMute(bool muted) async {
    if (_busy) return;
    setState(() => _busy = true);
    final r = await BilibiliImService.setMsgDnd(
      talkerUid: widget.talkerId,
      muted: muted,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r.ok) _muted = muted;
    });
    if (!r.ok) _toast(r.message, error: true);
  }

  Future<void> _toggleBlock(bool blocked) async {
    if (_busy) return;
    if (blocked) {
      final l10n = AppLocalizations.of(context);
      final confirmed = await _confirm(
        title: l10n.msgBlockConfirmTitle,
        body: l10n.msgBlockConfirmBody,
      );
      if (confirmed != true) return;
    }
    setState(() => _busy = true);
    final r = await BilibiliInteractionService.blockUser(
      mid: widget.talkerId,
      block: blocked,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r.ok) _blocked = blocked;
    });
    if (!r.ok) _toast(r.message, error: true);
  }

  Future<bool?> _confirm({required String title, required String body}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: Text(body, style: const TextStyle(fontSize: 13)),
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
  }

                                             
        
                                             

  Future<void> _report() async {
    final l10n = AppLocalizations.of(context);
    final reasons = <int>{};
    int? reasonV2;
    final contentLabels = [
      l10n.msgReportReasonAvatar,
      l10n.msgReportReasonNickname,
      l10n.msgReportReasonSign,
    ];
    final reasonLabels = [
      l10n.msgReportReasonPorn,
      l10n.msgReportReasonFalse,
      l10n.msgReportReasonForbidden,
      l10n.msgReportReasonAttack,
      l10n.msgReportReasonFraud,
      l10n.msgReportReasonLink,
    ];
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            title: Text(
              l10n.msgReportTitle(_name.isEmpty ? '${widget.talkerId}' : _name),
              style: const TextStyle(fontSize: 16),
            ),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: Text(
                        l10n.msgReportContentHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    for (var i = 0; i < contentLabels.length; i++)
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        onTap: () => setLocal(() {
                          if (!reasons.add(i + 1)) reasons.remove(i + 1);
                        }),
                        title: Row(
                          children: [
                            Icon(
                              reasons.contains(i + 1)
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 20,
                              color: reasons.contains(i + 1)
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              contentLabels[i],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 8),
                      child: Text(
                        l10n.msgReportReasonHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    for (var i = 0; i < reasonLabels.length; i++)
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        onTap: () => setLocal(() {
                          reasonV2 = reasonV2 == i ? null : i;
                        }),
                        title: Row(
                          children: [
                            Icon(
                              reasonV2 == i
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 20,
                              color: reasonV2 == i
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              reasonLabels[i],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () {
                  if (reasons.isEmpty) {
                    _toast(l10n.msgReportReasonRequired);
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: Text(l10n.commonOk),
              ),
            ],
          );
        },
      ),
    );
    if (submitted != true || !mounted) return;
    final r = await BilibiliInteractionService.reportMember(
      mid: widget.talkerId,
      reasons: reasons.toList(growable: false),
      reasonV2: reasonV2 == null ? null : reasonV2! + 1,
    );
    if (!mounted) return;
    _toast(r.ok ? l10n.msgReportSuccess : l10n.msgReportFailed, error: !r.ok);
  }

                                             
        
                                             

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return MsgPageScaffold(
      title: l10n.msgChatSettings,
      child: _loading
          ? const Center(child: LoadingIndicatorM3E())
          : _error != null && _settings == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _load,
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
                                      
              padding: const EdgeInsets.only(
                top: kMsgTopBarHeight,
                bottom: 32,
              ),
              children: [
                _buildUserTile(cs),
                Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
                if (_settings?.showPushSwitch ?? false)
                  _switchTile(
                    icon: Icons.notifications_active_outlined,
                    title: l10n.msgPushReceive,
                    subtitle: l10n.msgPushReceiveDesc,
                    value: _settings?.pushEnabled ?? true,
                    onChanged: _togglePush,
                  ),
                _switchTile(
                  icon: Icons.push_pin_outlined,
                  title: l10n.msgPinChat,
                  value: _pinned,
                  onChanged: _togglePin,
                ),
                if (_muted != null)
                  _switchTile(
                    icon: Icons.notifications_off_outlined,
                    title: l10n.msgChatMute,
                    value: _muted!,
                    onChanged: _toggleMute,
                  ),
                _switchTile(
                  icon: Icons.block,
                  title: l10n.msgBlockAdd,
                  value: _blocked,
                  onChanged: _toggleBlock,
                ),
                Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
                ListTile(
                  leading: Icon(
                    Icons.flag_outlined,
                    color: cs.onSurfaceVariant,
                  ),
                  title: Text(l10n.msgReport),
                  trailing: Icon(Icons.keyboard_arrow_right, color: cs.outline),
                  onTap: _report,
                ),
              ],
            ),
    );
  }

  Widget _buildUserTile(ColorScheme cs) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: widget.talkerId <= 0
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BilibiliUserSpacePage(mid: widget.talkerId),
              ),
            ),
      leading: MsgAvatar(url: _face, size: 46),
      title: Text(
        _name.isEmpty
            ? AppLocalizations.of(context).msgUserFallback('${widget.talkerId}')
            : _name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'UID: ${widget.talkerId}${_sign.isEmpty ? '' : '\n$_sign'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: Icon(Icons.keyboard_arrow_right, color: cs.outline),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      secondary: Icon(icon, color: cs.onSurfaceVariant),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
      value: value,
      onChanged: _busy ? null : onChanged,
    );
  }
}
