                                     
  
                       
                                          
                              
                                                  
                                         
                                           
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassQuality;

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/services/bilibili_im_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/emote_picker_panel.dart';
import 'package:naviflash/widgets/im_chat_item.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/msg_feed_common.dart';
import 'package:naviflash/widgets/page_loading.dart';

import 'bilibili_user_space_page.dart';
import 'whisper_chat_settings_page.dart';

class WhisperChatPage extends StatefulWidget {
  final int talkerId;
  final String name;
  final String face;

                           
  final bool pinned;

  const WhisperChatPage({
    super.key,
    required this.talkerId,
    this.name = '',
    this.face = '',
    this.pinned = false,
  });

  @override
  State<WhisperChatPage> createState() => _WhisperChatPageState();
}

class _WhisperChatPageState extends State<WhisperChatPage> {
                                         
  final List<BiliImMessage> _messages = [];
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _loading = true;
  bool _loadingMore = false;
  bool _sending = false;
  bool _hasMore = false;
  String? _error;
  int? _oldestSeqno;
  bool _acked = false;

               
  bool _showEmotePanel = false;

                                    
  Map<String, BiliCommentEmote> _emotes = const {};

  int get _selfMid => BilibiliImService.selfMid;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
    _loadEmotes();
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) _loadMore();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _messages.isEmpty;
      _error = null;
    });
    final BiliImMessagePage page;
    try {
      page = await BilibiliImService.fetchMessages(talkerId: widget.talkerId);
    } catch (e) {
                                              
                         
      if (kDebugMode) debugPrint('[Whisper] 消息加载异常: $e');
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
      if (page.err == null) {
        _messages
          ..clear()
          ..addAll(page.messages);
        _hasMore = page.hasMore;
        _oldestSeqno = _messages.isEmpty ? null : _messages.last.msgSeqno;
      }
    });
    if (page.err == null) _ack();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading || _error != null) return;
    final seqno = _oldestSeqno;
    if (seqno == null || seqno <= 0) return;
    setState(() => _loadingMore = true);
    final BiliImMessagePage page;
    try {
      page = await BilibiliImService.fetchMessages(
        talkerId: widget.talkerId,
        beginSeqno: 0,
        endSeqno: seqno,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Whisper] 消息翻页异常: $e');
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
      _hasMore = page.hasMore;
      final seen = _messages.map((e) => e.msgSeqno).toSet();
      final older = page.messages
          .where((e) => !seen.contains(e.msgSeqno))
          .toList(growable: false);
      if (older.isEmpty) {
        _hasMore = false;
        return;
      }
      _messages.addAll(older);
      _oldestSeqno = _messages.last.msgSeqno;
    });
  }

                                         
  Future<void> _loadEmotes() async {
    final packages = await BilibiliCommentService.fetchEmotePanel();
    if (!mounted || packages == null) return;
    final map = <String, BiliCommentEmote>{};
    for (final pkg in packages) {
      for (final emote in pkg.emotes) {
        map[emote.text] = BiliCommentEmote(
          text: emote.text,
          url: emote.url,
          size: emote.size,
        );
      }
    }
    setState(() => _emotes = map);
  }

                          
  void _ack() {
    if (_acked || _messages.isEmpty) return;
    _acked = true;
    final seqno = _messages.first.msgSeqno;
    if (seqno > 0) {
                          
      BilibiliImService.ackSession(talkerId: widget.talkerId, ackSeqno: seqno);
    }
  }

  void _toggleEmotePanel() {
    setState(() {
      _showEmotePanel = !_showEmotePanel;
      if (_showEmotePanel) {
        _focus.unfocus();
      } else {
        _focus.requestFocus();
      }
    });
  }

                         
  void _insertEmote(String text) {
    HapticFeedback.lightImpact();
    final sel = _input.selection;
    final current = _input.text;
    if (!sel.isValid) {
      _input.text = '$current$text';
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
      return;
    }
    _input.text = current.replaceRange(sel.start, sel.end, text);
    _input.selection = TextSelection.collapsed(offset: sel.start + text.length);
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final r = await BilibiliImService.sendText(
      receiverId: widget.talkerId,
      content: text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (r.ok) {
      _input.clear();
      _acked = false;
      await _load();
      _focus.requestFocus();
    } else {
      showAppToast(context, r.message, error: true);
    }
  }

                             
  Future<void> _pickAndSendImage() async {
    if (_sending) return;
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
        requestFullMetadata: false,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Whisper] 选图异常: $e');
      return;
    }
    if (picked == null || !mounted) return;
    final Uint8List bytes;
    try {
      bytes = await picked.readAsBytes();
    } catch (e) {
      if (kDebugMode) debugPrint('[Whisper] 读取图片异常: $e');
      return;
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _sending = true);
    showAppToast(context, l10n.msgUploadingImage);
    final uploaded = await BilibiliImService.uploadImage(bytes);
    if (!mounted) return;
    if (uploaded == null) {
      setState(() => _sending = false);
      showAppToast(context, l10n.commentComposerUploadFailed, error: true);
      return;
    }
    final r = await BilibiliImService.sendImage(
      receiverId: widget.talkerId,
      url: uploaded.url,
      width: uploaded.width,
      height: uploaded.height,
      size: uploaded.size,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (r.ok) {
      _acked = false;
      await _load();
      _focus.requestFocus();
    } else {
      showAppToast(context, r.message, error: true);
    }
  }

  Future<void> _withdraw(BiliImMessage msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).msgWithdrawConfirm,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).msgWithdraw),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final r = await BilibiliImService.withdrawMessage(
      receiverId: widget.talkerId,
      msgKey: msg.msgKey,
    );
    if (!mounted) return;
    if (r.ok) {
      showAppToast(context, AppLocalizations.of(context).msgWithdrawn);
      await _load();
    } else {
      showAppToast(context, r.message, error: true);
    }
  }

                                        
  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhisperChatSettingsPage(
          talkerId: widget.talkerId,
          name: widget.name,
          face: widget.face,
          pinned: widget.pinned,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return MsgPageScaffold(
      title: widget.name.isEmpty ? l10n.msgMyWhisper : widget.name,
      titleWidget: InkWell(
        onTap: widget.talkerId <= 0
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BilibiliUserSpacePage(mid: widget.talkerId),
                ),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MsgAvatar(url: widget.face, size: 32),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.name.isEmpty ? l10n.msgMyWhisper : widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: l10n.msgRefresh,
          onPressed: _load,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: l10n.msgChatSettings,
          onPressed: _openSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      child: Column(
        children: [
          Expanded(child: _buildList(cs)),
          _buildInputBar(cs),
        ],
      ),
    );
  }

  Widget _buildList(ColorScheme cs) {
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _messages.isEmpty,
    )) {
      return const PageLoadingIndicator();
    }
    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _load,
                child: Text(AppLocalizations.of(context).commonRetry),
              ),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return MsgEmptyView(
        icon: Icons.chat_bubble_outline,
        title: AppLocalizations.of(context).msgChatEmpty,
        subtitle: AppLocalizations.of(context).msgChatEmptySubtitle,
      );
    }
    return ListView.separated(
      controller: _scroll,
      reverse: true,
                                       
                                            
      padding: EdgeInsets.fromLTRB(12, 12 + kMsgTopBarHeight, 12, 12),
      itemCount: _messages.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= _messages.length) {
          if (_loadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _hasMore
              ? const SizedBox(height: 4)
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).msgNoEarlier,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
        }
        final msg = _messages[index];
        final isOwner = msg.senderUid == _selfMid;
        return ImChatItem(
          msg: msg,
          isOwner: isOwner,
          emotes: _emotes,
          onLongPress: isOwner ? () => _withdraw(msg) : null,
        );
      },
    );
  }

  Widget _buildInputBar(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
                                       
                   
    final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showEmotePanel)
              SizedBox(
                height: 260,
                child: EmotePickerPanel(onPick: _insertEmote),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: l10n.commentComposerEmote,
                    onPressed: _toggleEmotePanel,
                    icon: Icon(
                      _showEmotePanel
                          ? Icons.keyboard_alt_outlined
                          : Icons.emoji_emotions_outlined,
                      color: _showEmotePanel ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onTap: () {
                        if (_showEmotePanel) {
                          setState(() => _showEmotePanel = false);
                        }
                      },
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: l10n.msgInputHint,
                        isDense: true,
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    tooltip: l10n.commentComposerPickImage,
                    onPressed: _sending ? null : _pickAndSendImage,
                    icon: const Icon(Icons.image_outlined, size: 22),
                  ),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    tooltip: l10n.commonSend,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ],
        );
    return SafeArea(
      top: false,
      child: SettingsService.chatGlassEnabled
          ? ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: NaviGlass(
                radius: 20,
                blur: 14,
                lightIntensity: 0.22,
                tintOpacity: 0.1,
                                                
                                                         
                quality: GlassQuality.minimal,
                shadowElevation: 0,
                child: content,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: content,
            ),
    );
  }
}
