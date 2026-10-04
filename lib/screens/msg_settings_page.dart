                                     
  
                                                                 
                               
                                                   
                                    
                                       
                                  
                                                            
                                               
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_im_settings_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/msg_feed_common.dart';
import 'package:naviflash/widgets/page_loading.dart';

class MsgSettingsPage extends StatefulWidget {
  const MsgSettingsPage({super.key});

  @override
  State<MsgSettingsPage> createState() => _MsgSettingsPageState();
}

class _MsgSettingsPageState extends State<MsgSettingsPage> {
               
  int _replyNotify = BiliMsgNotifyType.everyone;
  int _atNotify = BiliMsgNotifyType.everyone;
  int _likeNotify = BiliMsgNotifyType.everyone;

               
  bool _receiveUnfollow = true;
  bool _unfollowFold = false;
  bool _groupReceive = true;
  bool _groupFold = false;
  bool _aiIntercept = false;

              
  bool _disturbOpen = false;
  int _disturbId = 0;
  List<({int id, String label})> _disturbOptions = const [];
  String _disturbEndTime = '';

  bool _loading = true;
  bool _loadedOnce = false;
  String? _error;

                               
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool viaRefresh = false}) async {
    setState(() {
                                                   
      _loading = !_loadedOnce && !viaRefresh;
      _error = null;
    });
    final results = await Future.wait([
      BilibiliImSettingsService.fetchSettings(),
      BilibiliImSettingsService.fetchDisturb(),
    ]);
    if (!mounted) return;
    final settings = results[0] as BiliMsgSettings?;
    final disturb = results[1] as BiliMsgDisturb?;
    if (settings == null && disturb == null) {
      if (_loadedOnce) {
        setState(() => _loading = false);
        showAppToast(
          context,
          AppLocalizations.of(context).msgSettingsLoadFail,
          error: true,
        );
        return;
      }
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).msgSettingsLoadFail;
      });
      return;
    }
    _loadedOnce = true;
    if (settings != null) {
      _replyNotify = settings.replyNotify;
      _atNotify = settings.atNotify;
      _likeNotify = settings.likeNotify;
      _receiveUnfollow = settings.receiveUnfollowMsg;
      _unfollowFold = settings.showUnfollowedMsg;
      _groupReceive = settings.shouldReceiveGroup;
      _groupFold = settings.isGroupFold;
      _aiIntercept = settings.aiIntercept;
    }
    if (disturb != null) {
      _disturbOpen = disturb.isOpen;
      _disturbId = disturb.selectedId;
      _disturbOptions = disturb.options;
      _disturbEndTime = disturb.endTime;
    }
    setState(() => _loading = false);
  }

                                          
  Future<void> _saveField(
    String field,
    Object? value,
    VoidCallback rollback,
  ) async {
    if (_saving.contains(field)) return;
    setState(() => _saving.add(field));
    final err = await BilibiliImSettingsService.saveSettings({field: value});
    if (!mounted) return;
    setState(() => _saving.remove(field));
    if (err != null) {
      rollback();
      showAppToast(
        context,
        AppLocalizations.of(context).msgSettingsSaveFail,
        error: true,
      );
    }
  }

                           
  Future<void> _saveDisturb(bool isOpen, int id) async {
    const key = 'anti_disturb';
    final prevOpen = _disturbOpen;
    final prevId = _disturbId;
    if (_saving.contains(key)) return;
    setState(() {
      _saving.add(key);
      _disturbOpen = isOpen;
      _disturbId = id;
    });
    final err = await BilibiliImSettingsService.saveDisturb(
      id: id,
      isOpen: isOpen,
    );
    if (!mounted) return;
    setState(() => _saving.remove(key));
    if (err != null) {
      setState(() {
        _disturbOpen = prevOpen;
        _disturbId = prevId;
      });
      showAppToast(
        context,
        AppLocalizations.of(context).msgSettingsSaveFail,
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return MsgPageScaffold(
      title: l10n.msgMenuSettings,
      child: _loading
          ? const Center(child: PageLoadingIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => _load(viaRefresh: true),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(l10n.scanRetry),
                      ),
                    ],
                  ),
                )
              : ListView(
                                          
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    8 + kMsgTopBarHeight,
                    12,
                    24,
                  ),
                  children: [
                    _sectionTitle(l10n.msgSettingsNotifSection),
                    _notifyTile(
                      title: l10n.msgSettingsReplyNotify,
                      desc: l10n.msgSettingsReplyNotifyDesc,
                      value: _replyNotify,
                      onChanged: (v) {
                        if (v == null) return;
                        final prev = _replyNotify;
                        setState(() => _replyNotify = v);
                        _saveField('set_comment', v, () {
                          if (mounted) setState(() => _replyNotify = prev);
                        });
                      },
                    ),
                    _notifyTile(
                      title: l10n.msgSettingsAtNotify,
                      desc: l10n.msgSettingsAtNotifyDesc,
                      value: _atNotify,
                      onChanged: (v) {
                        if (v == null) return;
                        final prev = _atNotify;
                        setState(() => _atNotify = v);
                        _saveField('set_at', v, () {
                          if (mounted) setState(() => _atNotify = prev);
                        });
                      },
                    ),
                    _notifyTile(
                      title: l10n.msgSettingsLikeNotify,
                      desc: l10n.msgSettingsLikeNotifyDesc,
                      value: _likeNotify,
                      onChanged: (v) {
                        if (v == null) return;
                        final prev = _likeNotify;
                        setState(() => _likeNotify = v);
                        _saveField('set_like', v, () {
                          if (mounted) setState(() => _likeNotify = prev);
                        });
                      },
                    ),
                    _sectionTitle(l10n.msgSettingsReceiveSection),
                    _switchTile(
                      title: l10n.msgSettingsReceiveUnfollow,
                      desc: l10n.msgSettingsReceiveUnfollowDesc,
                      value: _receiveUnfollow,
                      onChanged: (v) {
                        final prev = _receiveUnfollow;
                        setState(() => _receiveUnfollow = v);
                        _saveField('receive_unfollow_msg', v ? 1 : 0, () {
                          if (mounted) setState(() => _receiveUnfollow = prev);
                        });
                      },
                    ),
                    _switchTile(
                      title: l10n.msgSettingsUnfollowFold,
                      desc: l10n.msgSettingsUnfollowFoldDesc,
                      value: _unfollowFold,
                      onChanged: (v) {
                        final prev = _unfollowFold;
                        setState(() => _unfollowFold = v);
                        _saveField('show_unfollowed_msg', v ? 1 : 0, () {
                          if (mounted) setState(() => _unfollowFold = prev);
                        });
                      },
                    ),
                    _switchTile(
                      title: l10n.msgSettingsGroupReceive,
                      value: _groupReceive,
                      onChanged: (v) {
                        final prev = _groupReceive;
                        setState(() => _groupReceive = v);
                        _saveField('should_receive_group', v ? 1 : 0, () {
                          if (mounted) setState(() => _groupReceive = prev);
                        });
                      },
                    ),
                    _switchTile(
                      title: l10n.msgSettingsGroupFold,
                      value: _groupFold,
                      onChanged: (v) {
                        final prev = _groupFold;
                        setState(() => _groupFold = v);
                        _saveField('is_group_fold', v ? 1 : 0, () {
                          if (mounted) setState(() => _groupFold = prev);
                        });
                      },
                    ),
                    _switchTile(
                      title: l10n.msgSettingsSmartIntercept,
                      desc: l10n.msgSettingsSmartInterceptDesc,
                      value: _aiIntercept,
                      onChanged: (v) {
                        final prev = _aiIntercept;
                        setState(() => _aiIntercept = v);
                        _saveField('ai_intercept', v ? 1 : 0, () {
                          if (mounted) setState(() => _aiIntercept = prev);
                        });
                      },
                    ),
                    _sectionTitle(l10n.msgSettingsAntiHarassmentSection),
                    _switchTile(
                      title: l10n.msgSettingsAntiHarassment,
                      value: _disturbOpen,
                      onChanged: (v) => _saveDisturb(v, _disturbId),
                    ),
                    if (_disturbOptions.isNotEmpty)
                      _notifyTile(
                        title: l10n.msgSettingsScopeSelect,
                        value: _disturbId,
                        items: [
                          for (final o in _disturbOptions)
                            DropdownMenuItem(
                              value: o.id,
                              child: Text(o.label),
                            ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          _saveDisturb(_disturbOpen, v);
                        },
                      ),
                    if (_disturbEndTime.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          l10n.msgSettingsValidUntil(_disturbEndTime),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

                                             
         
                                             

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );

  Widget _notifyTile({
    required String title,
    String? desc,
    required int value,
    required ValueChanged<int?> onChanged,
    List<DropdownMenuItem<int>>? items,
  }) {
    final l10n = AppLocalizations.of(context);
    final menu = items ??
        [
          DropdownMenuItem(
            value: BiliMsgNotifyType.everyone,
            child: Text(l10n.msgSettingsNotifyEveryone),
          ),
          DropdownMenuItem(
            value: BiliMsgNotifyType.following,
            child: Text(l10n.msgSettingsNotifyFollowing),
          ),
          DropdownMenuItem(
            value: BiliMsgNotifyType.none,
            child: Text(l10n.msgSettingsNotifyNone),
          ),
        ];
    return ListTile(
      dense: true,
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: desc == null
          ? null
          : Text(desc, style: const TextStyle(fontSize: 11.5)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: menu.any((e) => e.value == value) ? value : menu.first.value,
          items: menu,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    String? desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: desc == null
          ? null
          : Text(desc, style: const TextStyle(fontSize: 11.5)),
      value: value,
      onChanged: onChanged,
    );
  }
}
