                                    
  
                                                 
                                               
                                          
import 'dart:async';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji_lib;
import 'package:flutter/material.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/services/bilibili_note_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/liquid_glass.dart';

                                       
Future<bool> showNoteEditorPage(
  BuildContext context, {
  required String bvid,
  required int aid,
  String? videoTitle,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => NoteEditorPage(
        bvid: bvid,
        aid: aid,
        videoTitle: videoTitle,
      ),
    ),
  ).then((v) => v ?? false);
}

class NoteEditorPage extends StatefulWidget {
  final String bvid;
  final int aid;

                           
  final String? videoTitle;

  const NoteEditorPage({
    super.key,
    required this.bvid,
    required this.aid,
    this.videoTitle,
  });

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  final FocusNode _contentFocus = FocusNode();

                        
  bool _showEmoji = false;

                           
  bool _dirty = false;

               
  Timer? _saveDebounce;

                        
  DateTime? _lastSavedAt;

          
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _titleCtrl.addListener(_onChanged);
    _contentCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final draft = await NoteDraftCache.load(widget.bvid);
    if (!mounted || draft == null) return;
    _titleCtrl.text = draft.title;
    _contentCtrl.text = draft.content;
    _lastSavedAt =
        draft.updatedAt > 0 ? DateTime.fromMillisecondsSinceEpoch(
      draft.updatedAt,
    ) : null;
                      
    setState(() {});
  }

  void _onChanged() {
    setState(() => _dirty = true);
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (!_dirty) return;
    await NoteDraftCache.save(
      BiliNoteDraft(
        bvid: widget.bvid,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (!mounted) return;
    setState(() {
      _lastSavedAt = DateTime.now();
      _dirty = false;
    });
  }

  void _toggleEmoji() {
    setState(() {
      _showEmoji = !_showEmoji;
      if (_showEmoji) _contentFocus.unfocus();
    });
  }

  void _insertEmoji(emoji_lib.Emoji emoji) {
               
    final sel = _contentCtrl.selection;
    final text = _contentCtrl.text;
    if (!sel.isValid) {
      _contentCtrl.text = text + emoji.emoji;
      return;
    }
    final start = sel.start;
    final end = sel.end;
    _contentCtrl.text = text.replaceRange(start, end, emoji.emoji);
    _contentCtrl.selection = TextSelection.collapsed(offset: start + emoji.emoji.length);
  }

  Future<void> _publish() async {
    final l10n = L10n.current;
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      showAppToast(context, l10n.noteEditorEmptyContent);
      return;
    }
                                
    if (!BilibiliNoteService.contentValid(content)) {
      showAppToast(context, l10n.noteEditorContentTooShort);
      return;
    }
                                    
    if (!BilibiliNoteService.canPublish) {
      await _saveDraftIfDirty();
      if (!mounted) return;
      showAppToast(context, l10n.noteEditorNotLoggedIn);
      return;
    }
    setState(() => _publishing = true);
    final result = await BilibiliNoteService.publish(
      aid: widget.aid,
      fallbackTitle: widget.videoTitle ?? widget.bvid,
      title: _titleCtrl.text.trim(),
      summary: BilibiliNoteService.buildSummary(content),
      deltaContent: BilibiliNoteService.buildDeltaContent(content),
    );
    if (!mounted) return;
    setState(() => _publishing = false);
    switch (result.result) {
      case BiliNotePublishResult.success:
                      
        await NoteDraftCache.remove(widget.bvid);
        if (!mounted) return;
        showAppToast(context, l10n.noteEditorPublished);
        Navigator.of(context).pop(true);
      case BiliNotePublishResult.notLoggedIn:
        await _saveDraftIfDirty();
        if (!mounted) return;
        showAppToast(context, l10n.noteEditorNotLoggedIn);
      case BiliNotePublishResult.networkError:
        await _saveDraftIfDirty();
        if (!mounted) return;
        showAppToast(context, l10n.noteEditorPublishNetworkError);
      case BiliNotePublishResult.apiRejected:
        await _saveDraftIfDirty();
        if (!mounted) return;
        showAppToast(context, l10n.noteEditorPublishRejected);
    }
  }

  Future<void> _saveDraftIfDirty() async {
    if (_dirty) await _saveDraft();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final canPublish = BilibiliNoteService.canPublish;
    final charCount = _contentCtrl.text.trim().isEmpty
        ? 0
        : _contentCtrl.text.trim().length;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _saveDraftIfDirty();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.noteEditorTitle),
          actions: [
            MorphIconButton(
              icon: _showEmoji ? Icons.keyboard_alt_outlined : Icons.emoji_emotions,
              iconColor: _showEmoji ? cs.primary : cs.onSurfaceVariant,
              tooltip: l10n.noteEditorEmoji,
              transparent: true,
              onTap: _toggleEmoji,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.tonalIcon(
                onPressed: _publishing ? null : _publish,
                icon: _publishing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined, size: 16),
                label: Text(l10n.noteEditorPublish),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
                                      
              if ((widget.videoTitle ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.videocam_outlined,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.videoTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                         
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _titleCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: l10n.noteEditorTitleHint,
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
                         
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: TextField(
                    controller: _contentCtrl,
                    focusNode: _contentFocus,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: l10n.noteEditorContentHint,
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    style: TextStyle(fontSize: 15, height: 1.7, color: cs.onSurface),
                  ),
                ),
              ),
                           
              if (_showEmoji)
                SizedBox(
                  height: 280,
                  child: NaviGlass(
                    radius: 16,
                    blur: 12,
                    child: emoji_lib.EmojiPicker(
                      onEmojiSelected: (_, emoji) {
                        _insertEmoji(emoji);
                      },
                      config: emoji_lib.Config(
                        height: 280,
                        checkPlatformCompatibility: true,
                        emojiViewConfig: emoji_lib.EmojiViewConfig(
                          columns: 8,
                          emojiSizeMax: 28,
                          backgroundColor: Colors.transparent,
                        ),
                        categoryViewConfig: emoji_lib.CategoryViewConfig(
                          initCategory: emoji_lib.Category.RECENT,
                          categoryIcons: const emoji_lib.CategoryIcons(),
                          backgroundColor: Colors.transparent,
                        ),
                        searchViewConfig: emoji_lib.SearchViewConfig(
                          backgroundColor: Colors.transparent,
                        ),
                        bottomActionBarConfig: emoji_lib.BottomActionBarConfig(
                          enabled: true,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),
                                              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow.withValues(alpha: 0.6),
                  border: Border(
                    top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      canPublish ? Icons.check_circle : Icons.info_outline,
                      size: 14,
                      color: canPublish ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        canPublish
                            ? l10n.noteEditorLoggedInHint
                            : l10n.noteEditorGuestHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (_lastSavedAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        l10n.noteEditorSavedAt(
                          _twoDigits(_lastSavedAt!.hour),
                          _twoDigits(_lastSavedAt!.minute),
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      l10n.noteEditorCharCount(charCount),
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
        ),
      ),
    );
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
