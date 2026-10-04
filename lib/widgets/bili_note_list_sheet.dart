import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/article_page.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/screens/note_editor_page.dart';
import 'package:naviflash/services/bilibili_note_service.dart';
import 'package:naviflash/services/bilibili_video_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

                                                      
                                       
                                          
Future<void> showBiliNoteListSheet(
  BuildContext context, {
  required int aid,
  String bvid = '',
  String? videoTitle,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => BiliNoteListSheet(
      aid: aid,
      bvid: bvid,
      videoTitle: videoTitle,
    ),
  );
}

                                                
                                
class BiliNoteListSheet extends StatefulWidget {
  final int aid;

                                      
  final String bvid;

                   
  final String? videoTitle;

  const BiliNoteListSheet({
    super.key,
    required this.aid,
    this.bvid = '',
    this.videoTitle,
  });

  @override
  State<BiliNoteListSheet> createState() => BiliNoteListSheetState();
}

class BiliNoteListSheetState extends State<BiliNoteListSheet> {
  static const int _pageSize = 10;

  final ScrollController _scrollCtrl = ScrollController();

  List<BiliVideoNote> _notes = [];
  int _total = -1;               
  int _pn = 1;
  bool _loading = false;
  bool _firstError = false;

                                
  BiliNoteDraft? _draft;

  bool get _hasMore => _total < 0 || _notes.length < _total;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
              _scrollCtrl.position.maxScrollExtent - 120 &&
          _hasMore &&
          !_loading) {
        _loadMore();
      }
    });
    _fetch(page: 1);
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    if (widget.bvid.isEmpty) return;
    final draft = await NoteDraftCache.load(widget.bvid);
    if (mounted && draft != null && !draft.isEmpty) {
      setState(() => _draft = draft);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch({required int page, bool retryFirst = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    final result = await BilibiliVideoService.fetchVideoNotes(
      aid: widget.aid,
      pn: page,
      ps: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result == null) {
                                      
        if (retryFirst || _total < 0) _firstError = true;
        return;
      }
      _firstError = false;
      if (page == 1) {
        _notes = result.list;
        _pn = 1;
      } else {
                             
        final seen = _notes.map((n) => n.cvid).toSet();
        _notes.addAll(result.list.where((n) => seen.add(n.cvid)));
        _pn = page;
      }
      _total = result.total;
    });
  }

  void _loadMore() => _fetch(page: _pn + 1);

  Future<void> _retry() async {
    setState(() => _firstError = false);
    await _fetch(page: 1, retryFirst: true);
  }

  void _openNote(BuildContext context, BiliVideoNote note) {
    Navigator.of(context).push(
      ImmersiveMaterialPageRoute<void>(
        page: ArticlePage(
          cvid: note.cvid,
          initialTitle: note.summary.isNotEmpty ? note.summary : null,
        ),
      ),
    );
  }

  void _openAuthor(BuildContext context, BiliVideoNote note) {
    if (note.authorMid <= 0) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BilibiliUserSpacePage(mid: note.authorMid),
      ),
    );
  }

                                  
  Future<void> _openEditor() async {
    if (widget.bvid.isEmpty) return;
    final published = await showNoteEditorPage(
      context,
      bvid: widget.bvid,
      aid: widget.aid,
      videoTitle: widget.videoTitle,
    );
    if (!mounted) return;
    _loadDraft();
    if (published) {
      setState(() {
        _draft = null;
        _total = -1;
        _notes = [];
      });
      _fetch(page: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GlassMenuSurface(
        radius: 12.0,
        blur: 12.0,
        tintOpacity: 0.15,
        lightIntensity: 0.2,
        stretch: 0,
        legacyClipRadius: BorderRadius.circular(12),
        legacyDecoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 46,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _total >= 0
                                ? l10n.playerNotesCount(_total)
                                : l10n.playerNotesTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip:
                              MaterialLocalizations.of(
                                context,
                              ).closeButtonTooltip,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_firstError)
                  _buildErrorView(l10n, cs)
                else if (_total == 0 && _draft == null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 24,
                    ),
                    child: Text(
                      l10n.playerNotesEmpty,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ] else ...[
                                            
                  if (_draft != null) _buildDraftTile(l10n, cs),
                                                           
                  if (_total != 0)
                    Flexible(
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: _notes.length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == _notes.length) return _buildFooter(cs);
                          return _NoteRow(
                            note: _notes[i],
                            onTap: () => _openNote(context, _notes[i]),
                            onAvatarTap: () =>
                                _openAuthor(context, _notes[i]),
                          );
                        },
                      ),
                    ),
                ],
                                              
                if (widget.bvid.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: _openEditor,
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: Text(l10n.noteEditorWrite),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

                                 
  Widget _buildDraftTile(AppLocalizations l10n, ColorScheme cs) {
    final draft = _draft!;
    final preview = draft.content.trim().replaceAll('\n', ' ');
    final time = draft.updatedAt > 0
        ? DateTime.fromMillisecondsSinceEpoch(draft.updatedAt)
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
      child: Material(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _openEditor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.drafts_outlined, size: 20, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.noteEditorMyDraft,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (time != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${time.month}/${time.day} '
                          '${time.hour.toString().padLeft(2, '0')}:'
                          '${time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.noteEditorDeleteDraft,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: () async {
                    await NoteDraftCache.remove(widget.bvid);
                    if (mounted) setState(() => _draft = null);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

                               
  Widget _buildFooter(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(
            l10n.playerNotesNoMore,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ),
      );
    }
    return const SizedBox(height: 12);
  }

  Widget _buildErrorView(AppLocalizations l10n, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.playerNotesLoadFailed,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(l10n.scanRetry),
            onPressed: _retry,
          ),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final BiliVideoNote note;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;

  const _NoteRow({
    required this.note,
    required this.onTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                         
            GestureDetector(
              onTap: onAvatarTap,
              child: ClipOval(
                child: note.authorFace.isNotEmpty
                    ? Image(
                        image: CachedImageProvider(
                          note.authorFace,
                          headers:
                              NetworkSettingsService
                                  .instance
                                  .apiHeaders
                                  .isEmpty
                              ? null
                              : NetworkSettingsService.instance.apiHeaders,
                        ),
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _faceFallback(cs),
                      )
                    : _faceFallback(cs),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          note.authorName.isEmpty ? '?' : note.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: note.isVip
                                ? const Color(0xFFFB7299)
                                : cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        note.pubTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (note.summary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: note.summary,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.75,
                          color: cs.onSurface.withValues(alpha: 0.9),
                        ),
                        children: [
                          const WidgetSpan(child: SizedBox(width: 6)),
                          TextSpan(
                            text: l10n.playerNotesViewFull,
                            style: TextStyle(color: cs.primary),
                          ),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faceFallback(ColorScheme cs) => Container(
    width: 34,
    height: 34,
    color: cs.surfaceContainerHighest,
    child: Icon(Icons.person, size: 20, color: cs.onSurfaceVariant),
  );
}
