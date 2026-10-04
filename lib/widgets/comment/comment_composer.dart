                                            
  
                                
                                                     
                                       
                                  
                                                                  
                                              
                          
                                         
                                                     
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/my_reply_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/navi_spring_physics.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

                  
typedef CommentComposerResult = ({bool sent, BiliComment? comment});

const int kCommentImageLimit = 9;

                                            
                                              
                                            
                                           
const String kVideoPageCommentHeroTag = 'videoPageCommentFab';

                                   
                                                   
                                                       
                                   
Future<CommentComposerResult> showCommentComposer(
  BuildContext context, {
  required int oid,
  BiliComment? replyTo,
  int type = 1,
  double? Function()? currentProgress,
  Future<Uint8List?> Function()? captureFrame,
                                                  
                                           
                                 
  Object? heroTag,

                                                
                            
  String? sourceTitle,
  String? sourceId,
}) {
  return showAppBottomSheet<CommentComposerResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => CommentComposer(
      oid: oid,
      replyTo: replyTo,
      type: type,
      currentProgress: currentProgress,
      captureFrame: captureFrame,
      heroTag: heroTag,
      sourceTitle: sourceTitle,
      sourceId: sourceId,
    ),
  ).then((r) => r ?? (sent: false, comment: null));
}

String formatCommentProgress(int seconds) {
  if (seconds <= 0) return '00:00';
  final h = seconds ~/ 3600;
  var s = seconds % 3600;
  final m = s ~/ 60;
  s %= 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h == 0 ? '${two(m)}:${two(s)}' : '${two(h)}:${two(m)}:${two(s)}';
}

class CommentComposer extends StatefulWidget {
  final int oid;
  final BiliComment? replyTo;
  final int type;

                                
  final double? Function()? currentProgress;

                                    
  final Future<Uint8List?> Function()? captureFrame;

                                                           
  final Object? heroTag;

                           
  final String? sourceTitle;

                         
  final String? sourceId;

  const CommentComposer({
    super.key,
    required this.oid,
    this.replyTo,
    this.type = 1,
    this.currentProgress,
    this.captureFrame,
    this.heroTag,
    this.sourceTitle,
    this.sourceId,
  });

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

                                     
  _PanelType? _panel;

                               
  List<BiliEmotePackage>? _emotes;
  bool _emoteLoading = false;

                                       
  final List<Uint8List> _images = [];

                   
  bool _sending = false;

                                    
  late BiliComment? _replyTo = widget.replyTo;

  bool get _isRoot => _replyTo == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _panel == null) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _togglePanel(_PanelType type) {
    setState(() {
      _panel = _panel == type ? null : type;
      if (_panel != null) {
        _focusNode.unfocus();
        if (type == _PanelType.emoji) _loadEmotes();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  Future<void> _loadEmotes() async {
    if (_emoteLoading || _emotes != null) return;
    setState(() => _emoteLoading = true);
    final emotes = await BilibiliCommentService.fetchEmotePanel();
    if (!mounted) return;
    setState(() {
      _emoteLoading = false;
      _emotes = emotes;
    });
  }

                                            
  void _insertText(String text) {
    HapticFeedback.lightImpact();
    final sel = _controller.selection;
    final current = _controller.text;
    if (!sel.isValid) {
      _controller.text = '$current$text';
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      return;
    }
    final start = sel.start;
    final end = sel.end;
    _controller.text = current.replaceRange(start, end, text);
    _controller.selection = TextSelection.collapsed(
      offset: start + text.length,
    );
  }

                                              
  Future<void> _pickImages() async {
    final remaining = kCommentImageLimit - _images.length;
    if (remaining <= 0) {
      showAppToast(
        context,
        L10n.current.commentComposerImageLimit(kCommentImageLimit),
      );
      return;
    }
    try {
      final picked = await ImagePicker().pickMultiImage(
        imageQuality: 100,
        requestFullMetadata: false,
      );
      for (final p in picked.take(remaining)) {
        _images.add(await p.readAsBytes());
      }
      if (picked.length > remaining && mounted) {
        showAppToast(
          context,
          L10n.current.commentComposerImageLimit(kCommentImageLimit),
        );
      }
      if (mounted) setState(() {});
    } catch (_) {
                       
    }
  }

                                
  Future<void> _captureFrame() async {
    if (_images.length >= kCommentImageLimit) {
      showAppToast(
        context,
        L10n.current.commentComposerImageLimit(kCommentImageLimit),
      );
      return;
    }
    final bytes = await widget.captureFrame!();
    if (!mounted) return;
    if (bytes == null) {
      showAppToast(context, L10n.current.commentComposerCaptureFailed);
      return;
    }
    setState(() => _images.add(bytes));
  }

                                           
  void _insertProgress() {
    final seconds = widget.currentProgress!()?.round() ?? 0;
    _insertText(' ${formatCommentProgress(seconds)} ');
  }

  Future<void> _send() async {
    final l10n = L10n.current;
    final raw = _controller.text.trim();
    if (raw.isEmpty && _images.isEmpty) {
      showAppToast(context, l10n.commentComposerEmpty);
      return;
    }
    final target = _replyTo;
                                                
                                   
                                              
                                 
    int? root;
    int? parent;
    var message = raw;
    if (target != null) {
      final rpid = int.tryParse(target.rpid) ?? 0;
      if (rpid > 0) {
        root = rpid;
        parent = rpid;
      }
      if (target.root != '0' && target.root.isNotEmpty) {
        message = ' 回复 @${target.uname} : $raw';
      }
    }
    setState(() => _sending = true);

                                    
    List<Map<String, dynamic>>? pictures;
    if (_isRoot && _images.isNotEmpty) {
      pictures = [];
      for (final bytes in _images) {
        final pic = await BilibiliCommentService.uploadCommentImage(bytes);
        if (!mounted) return;
        if (pic == null) {
          setState(() => _sending = false);
          showAppToast(context, l10n.commentComposerUploadFailed);
          return;
        }
        pictures.add(pic);
      }
    }

    final result = await BilibiliCommentService.sendComment(
      oid: widget.oid,
      message: message,
      type: widget.type,
      root: root,
      parent: parent,
      pictures: pictures,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.message.isNotEmpty) {
      showAppToast(context, result.message);
      return;
    }
                                       
    unawaited(
      MyReplyService.instance.recordSent(
        oid: widget.oid,
        type: widget.type,
        message: message,
        root: root?.toString() ?? '0',
        parent: parent?.toString() ?? '0',
        comment: result.comment,
        sourceTitle: widget.sourceTitle ?? '',
        sourceId: widget.sourceId ?? '',
        pictures: pictures
                ?.map((p) => (p['img_src'] as String?) ?? '')
                .where((e) => e.isNotEmpty)
                .toList() ??
            const [],
      ),
    );
    if (mounted) {
      Navigator.of(context).pop((sent: true, comment: result.comment));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final canSend =
        (_controller.text.trim().isNotEmpty || _images.isNotEmpty) &&
        !_sending;

    return Padding(
                  
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GlassMenuSurface(
          radius: 12.0,
          blur: 12.0,
          tintOpacity: 0.15,
          lightIntensity: 0.2,
          stretch: 0,
          legacyClipRadius: BorderRadius.circular(12),
          legacyDecoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                                   
                if (_replyTo != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 0),
                    child: Row(
                      children: [
                        Icon(Icons.reply, size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.commentComposerReplyTo(_replyTo!.uname),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.close,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                          onPressed: () => setState(() => _replyTo = null),
                        ),
                      ],
                    ),
                  ),
                            
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 3,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: _replyTo == null
                          ? l10n.commentComposerHint
                          : l10n.commentComposerReplyHint(_replyTo!.uname),
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    style: TextStyle(fontSize: 14, color: cs.onSurface),
                  ),
                ),
                                                
                if (_isRoot && _images.isNotEmpty)
                  SizedBox(
                    height: 92,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _images.length + 1,
                      itemBuilder: (ctx, i) {
                        if (i == _images.length) {
                          return _AddImageCell(
                            onTap: _pickImages,
                            enabled: _images.length < kCommentImageLimit,
                          );
                        }
                        return _ImageCell(
                          bytes: _images[i],
                          onRemove: () =>
                              setState(() => _images.removeAt(i)),
                        );
                      },
                    ),
                  ),
                                              
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 12, 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: l10n.commentComposerEmote,
                        icon: Icon(
                          _panel == _PanelType.emoji
                              ? Icons.keyboard_alt_outlined
                              : Icons.emoji_emotions_outlined,
                          color: _panel == _PanelType.emoji
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                        onPressed: () => _togglePanel(_PanelType.emoji),
                      ),
                      if (_isRoot)
                        IconButton(
                          tooltip: l10n.commentComposerPickImage,
                          icon: Icon(
                            Icons.image_outlined,
                            color: _panel == null
                                ? cs.onSurfaceVariant
                                : cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          onPressed: _pickImages,
                        ),
                                          
                      if (widget.currentProgress != null ||
                          (_isRoot && widget.captureFrame != null))
                        IconButton(
                          tooltip: l10n.commentComposerMore,
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: _panel == _PanelType.more
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                          onPressed: () => _togglePanel(_PanelType.more),
                        ),
                      const Spacer(),
                      FloatingActionButton.extended(
                                                            
                                                       
                                                          
                                                        
                        heroTag: widget.heroTag,
                        onPressed: canSend ? _send : null,
                        icon: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send, size: 18),
                        label: Text(l10n.commentComposerSend),
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        elevation: 2,
                        extendedPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ],
                  ),
                ),
                                   
                if (_panel == _PanelType.emoji)
                  SizedBox(
                    height: 300,
                    child: _buildEmotePanel(l10n, cs),
                  ),
                if (_panel == _PanelType.more)
                  SizedBox(
                    height: 170,
                    child: _buildMorePanel(l10n, cs),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMorePanel(AppLocalizations l10n, ColorScheme cs) {
    final showProgress = widget.currentProgress != null;
    final showCapture = _isRoot && widget.captureFrame != null;
    final items = <_MorePanelItem>[
      if (showProgress)
        _MorePanelItem(
          icon: Icons.my_location,
          label: l10n.commentComposerVideoProgress,
          onTap: _insertProgress,
        ),
      if (showCapture)
        _MorePanelItem(
          icon: Icons.photo_camera_outlined,
          label: l10n.commentComposerVideoScreenshot,
          onTap: _captureFrame,
        ),
    ];
    return GridView.count(
      crossAxisCount: 4,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        for (final item in items)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.lightImpact();
              item.onTap();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, size: 26, color: cs.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: TextStyle(fontSize: 12, color: cs.onSurface),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmotePanel(AppLocalizations l10n, ColorScheme cs) {
    if (_emoteLoading) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: cs.primary,
          ),
        ),
      );
    }
    final emotes = _emotes;
    if (emotes == null || emotes.isEmpty) {
                 
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.commentComposerEmoteUnavailable,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                BilibiliCommentService.resetEmotePanelCache();
                _loadEmotes();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(l10n.scanRetry),
            ),
          ],
        ),
      );
    }
    return DefaultTabController(
      length: emotes.length,
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              indicatorColor: cs.primary,
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
              tabs: [
                for (final pkg in emotes)
                  _EmoteTabLabel(package: pkg, colorScheme: cs),
              ],
            ),
          ),
          Expanded(
            child: naviTabBarView(
              children: [
                for (final pkg in emotes)
                  _EmoteGrid(package: pkg, onTap: _insertText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _PanelType { emoji, more }

class _MorePanelItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MorePanelItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

                      
class _ImageCell extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onRemove;

  const _ImageCell({required this.bytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: -4,
            top: -4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 14, color: cs.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

                    
class _AddImageCell extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;

  const _AddImageCell({required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: cs.outlineVariant.withValues(
                alpha: enabled ? 1 : 0.4,
              ),
            ),
          ),
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: 26,
            color: cs.onSurfaceVariant.withValues(alpha: enabled ? 1 : 0.4),
          ),
        ),
      ),
    );
  }
}

                               
class _EmoteTabLabel extends StatelessWidget {
  final BiliEmotePackage package;
  final ColorScheme colorScheme;

  const _EmoteTabLabel({required this.package, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    if (package.isTextPackage) {
      final label = package.emotes.first.text;
      return Tab(
        height: 40,
        child: Text(
          label.length > 4 ? label.substring(0, 4) : label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      );
    }
    return Tab(
      height: 40,
      child: package.url.isNotEmpty
          ? Image(
              image: CachedImageProvider(package.url),
              width: 22,
              height: 22,
              errorBuilder: (_, __, ___) => Icon(
                Icons.emoji_emotions_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : Icon(
              Icons.emoji_emotions_outlined,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
    );
  }
}

                           
class _EmoteGrid extends StatelessWidget {
  final BiliEmotePackage package;
  final ValueChanged<String> onTap;

  const _EmoteGrid({required this.package, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 52,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: package.emotes.length,
      itemBuilder: (ctx, i) {
        final emote = package.emotes[i];
        final isSmall = emote.size == 1;
        if (package.isTextPackage) {
                        
          final label = emote.text;
          final stripped = label.startsWith('[') && label.endsWith(']')
              ? label.substring(1, label.length - 1)
              : label;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onTap(emote.text),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  stripped,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isSmall ? 12 : 13,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          );
        }
        final size = isSmall ? 24.0 : 40.0;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onTap(emote.text),
          child: Center(
            child: Image(
              image: CachedImageProvider(emote.url),
              width: size,
              height: size,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported_outlined,
                size: 18,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
