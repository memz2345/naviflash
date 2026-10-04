                                              
  
                                                        
                                                                            
                                       
                                                
                                                  
                                 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:naviflash/services/bilibili_dynamic_opus_service.dart';
import 'package:naviflash/widgets/app_toast.dart';

class DynamicVotePanel extends StatefulWidget {
                                                    
  final int voteId;

                                       
  final String dynamicId;

                           
  final bool compact;

  const DynamicVotePanel({
    super.key,
    required this.voteId,
    this.dynamicId = '',
    this.compact = false,
  });

  @override
  State<DynamicVotePanel> createState() => _DynamicVotePanelState();
}

class _DynamicVotePanelState extends State<DynamicVotePanel> {
  BiliVoteInfo? _info;
  String? _error;
  bool _loading = true;
  bool _submitting = false;

                           
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await BilibiliDynamicOpusService.fetchVoteInfo(widget.voteId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _info = r.info;
      _error = r.err;
      _selected
        ..clear()
        ..addAll(r.info?.myVotes ?? const <int>[]);
    });
  }

  Future<void> _submit() async {
    final info = _info;
    if (info == null || _selected.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final r = await BilibiliDynamicOpusService.doVote(
      voteId: info.voteId,
      votes: _selected.toList(),
      dynamicId: int.tryParse(widget.dynamicId) ?? 0,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (r.err != null) {
      showAppToast(context, r.err!, error: true);
      return;
    }
    if (r.info != null) {
      setState(() {
        _info = r.info;
        _selected
          ..clear()
          ..addAll(r.info!.myVotes);
      });
      showAppToast(context, '投票成功');
    }
  }

  void _toggleOption(int optIdx) {
    final info = _info;
    if (info == null || !info.canVote) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.remove(optIdx)) {
                                       
        final max = info.choiceCnt > 0 ? info.choiceCnt : 1;
        while (_selected.length >= max) {
          _selected.remove(_selected.first);
        }
        _selected.add(optIdx);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final info = _info;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )),
      );
    }
    if (info == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.bar_chart_rounded, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _error ?? '投票加载失败',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: _load,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: EdgeInsets.all(widget.compact ? 10 : 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 16,
                color: cs.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  info.title.isEmpty ? '投票' : info.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.compact ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              _stateBadge(cs, info),
            ],
          ),
          if (info.desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              info.desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 8),
                        
          Row(
            children: [
              Icon(Icons.schedule, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                _deadlineText(info),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                '${_formatCount(info.joinNum)}人参与',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
               
          for (var i = 0; i < info.options.length; i++)
            _optionRow(cs, info, info.options[i], i),
                         
          if (info.canVote) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected.isEmpty || _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _selected.isEmpty
                            ? (info.choiceCnt > 1
                                  ? '投票（可选${info.choiceCnt}项）'
                                  : '点击选项投票')
                            : '投 票',
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stateBadge(ColorScheme cs, BiliVoteInfo info) {
    final text = info.hasVoted
        ? '已投票'
        : info.endedAt(DateTime.now())
        ? '已截止'
        : null;
    if (text == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: cs.onSecondaryContainer),
      ),
    );
  }

  String _deadlineText(BiliVoteInfo info) {
    if (info.endTime <= 0) return '长期有效';
    final end = DateTime.fromMillisecondsSinceEpoch(info.endTime * 1000);
    String two(int n) => n.toString().padLeft(2, '0');
    final deadline =
        '${end.year}-${two(end.month)}-${two(end.day)} '
        '${two(end.hour)}:${two(end.minute)}';
    if (info.endedAt(DateTime.now())) return '至 $deadline';
    final remain = end.difference(DateTime.now());
    if (remain.inDays >= 1) return '至 $deadline（剩${remain.inDays}天）';
    if (remain.inHours >= 1) return '至 $deadline（剩${remain.inHours}小时）';
    return '至 $deadline（剩${remain.inMinutes.clamp(0, 59)}分钟）';
  }

  Widget _optionRow(
    ColorScheme cs,
    BiliVoteInfo info,
    BiliVoteOption option,
    int index,
  ) {
    final selected = _selected.contains(option.optIdx);
    final showPercentage = !info.canVote;
    final percentages = info.percentages();
    final pct = index < percentages.length ? percentages[index] : 0.0;
    final enabled = info.canVote;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: enabled ? () => _toggleOption(option.optIdx) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withValues(alpha: 0.7)
                : cs.surfaceContainerHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 1.2 : 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (info.choiceCnt > 1)
                    Icon(
                      selected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 16,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                    )
                  else
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 16,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      option.optDesc.isEmpty ? '选项${index + 1}' : option.optDesc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (showPercentage)
                    Text(
                      '${(pct * 100).toStringAsFixed(pct * 100 >= 10 ? 0 : 1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                  if (selected) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.check_rounded, size: 14, color: cs.primary),
                  ],
                ],
              ),
              if (showPercentage) ...[
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      selected ? cs.primary : cs.primary.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 10000) {
      final w = n / 10000;
      return '${w.toStringAsFixed(w >= 100 ? 0 : 1)}万';
    }
    return '$n';
  }
}
