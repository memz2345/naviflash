                                                
  
                                                                   
                                 
                                                    
                                                     
                                                      
import 'package:flutter/material.dart';

import 'package:naviflash/services/bilibili_dynamic_opus_service.dart';
import 'package:naviflash/widgets/app_toast.dart';

class DynamicReserveCard extends StatefulWidget {
  final BiliReserveInfo reserve;

                                
  final String dynamicId;

  const DynamicReserveCard({
    super.key,
    required this.reserve,
    this.dynamicId = '',
  });

  @override
  State<DynamicReserveCard> createState() => _DynamicReserveCardState();
}

class _DynamicReserveCardState extends State<DynamicReserveCard> {
  late BiliReserveInfo _reserve = widget.reserve;
  bool _busy = false;

  Future<void> _toggleReserve() async {
    if (_busy) return;
    setState(() => _busy = true);
    final r = await BilibiliDynamicOpusService.reserveClick(
      reserve: _reserve,
      dynamicIdStr: widget.dynamicId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.err != null) {
      showAppToast(context, r.err!, error: true);
      return;
    }
    if (r.info != null) {
      setState(() => _reserve = r.info!);
      showAppToast(context, _reserve.isReserved ? '预约成功' : '已取消预约');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = _reserve;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.live_tv_rounded,
              size: 20,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r.title.isNotEmpty)
                  Text(
                    r.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                if (r.desc1.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    r.desc1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: cs.primary),
                  ),
                ],
                if (r.desc2.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    r.desc2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '${_formatCount(r.reserveTotal)}人预约',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (r.canReserve) ...[
            const SizedBox(width: 10),
            FilledButton.tonal(
              onPressed: _busy ? null : _toggleReserve,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                backgroundColor: r.isReserved
                    ? cs.onSurface.withValues(alpha: 0.08)
                    : null,
                foregroundColor: r.isReserved
                    ? cs.onSurface.withValues(alpha: 0.5)
                    : null,
              ),
              child: _busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(r.isReserved ? r.btnCheckText : r.btnUncheckText),
            ),
          ],
        ],
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
