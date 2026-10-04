                                                  
  
                                              
                                                                   
                                                         
                                            
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/comment/comment_content.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

               
                                  
Future<void> showCommentDialogueSheet(
  BuildContext context, {
  required String cid,
  required BiliComment root,
  required BiliComment reply,
  String commentType = '1',
  Map<String, BiliComment> seed = const {},
}) async {
  await showAppBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => _DialogueSheet(
      cid: cid,
      root: root,
      reply: reply,
      commentType: commentType,
      seed: seed,
    ),
  );
}

class _DialogueSheet extends StatefulWidget {
  final String cid;
  final BiliComment root;
  final BiliComment reply;
  final String commentType;
  final Map<String, BiliComment> seed;

  const _DialogueSheet({
    required this.cid,
    required this.root,
    required this.reply,
    required this.commentType,
    required this.seed,
  });

  @override
  State<_DialogueSheet> createState() => _DialogueSheetState();
}

class _DialogueSheetState extends State<_DialogueSheet> {
  List<BiliComment>? _chain;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chain = await BilibiliCommentService.fetchDialogueChain(
      cid: widget.cid,
      root: widget.root,
      reply: widget.reply,
      type: widget.commentType,
      seed: widget.seed,
    );
    if (!mounted) return;
    setState(() {
                                      
      _chain = (chain == null || chain.isEmpty)
          ? [widget.root, widget.reply]
          : chain;
      _failed = chain == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final maxH = MediaQuery.sizeOf(context).height * 0.7;
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: maxH),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                l10n.commentViewDialogue,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            Flexible(
              child: _chain == null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: _failed
                          ? Center(
                              child: Text(
                                l10n.commentLoadMoreFail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            )
                          : const Center(
                              child: LoadingIndicatorM3E(
                                constraints: BoxConstraints.tightFor(
                                  width: 26,
                                  height: 26,
                                ),
                              ),
                            ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _chain!.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 44,
                        color: cs.outline.withValues(alpha: 0.15),
                      ),
                      itemBuilder: (context, i) =>
                          _DialogueEntry(comment: _chain![i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogueEntry extends StatelessWidget {
  final BiliComment comment;

  const _DialogueEntry({required this.comment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final member = comment.member;
    final location = comment.location;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  member.uname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                location,
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          if (comment.message.isEmpty)
            Text(
              AppLocalizations.of(context).commentDeleted,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: cs.onSurfaceVariant,
              ),
            )
          else
            CommentMessageText(
              message: comment.message,
              emotes: comment.emotes,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: cs.onSurface.withValues(alpha: 0.9),
              ),
            ),
        ],
      ),
    );
  }
}
