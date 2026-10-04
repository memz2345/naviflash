                                           
                                      
                 
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:naviflash/services/cdn_speed_test_service.dart';

                          
class CdnCandidate {
  final String label;
  final String url;
  const CdnCandidate({required this.label, required this.url});
}

                                 
Future<CdnCandidate?> showCdnSpeedTestDialog(
  BuildContext context, {
  required List<CdnCandidate> candidates,
  Map<String, String>? headers,
  String? currentLabel,
}) {
  return showDialog<CdnCandidate>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CdnSpeedTestDialog(
      candidates: candidates,
      headers: headers,
      currentLabel: currentLabel,
    ),
  );
}

class _CdnSpeedTestDialog extends StatefulWidget {
  final List<CdnCandidate> candidates;
  final Map<String, String>? headers;
  final String? currentLabel;

  const _CdnSpeedTestDialog({
    required this.candidates,
    this.headers,
    this.currentLabel,
  });

  @override
  State<_CdnSpeedTestDialog> createState() => _CdnSpeedTestDialogState();
}

class _CdnSpeedTestDialogState extends State<_CdnSpeedTestDialog> {
  final Map<int, CdnSpeedResult> _results = {};
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
                          
    for (var i = 0; i < widget.candidates.length; i++) {
      if (!mounted) return;
      final c = widget.candidates[i];
      final res = await CdnSpeedTestService.test(
        c.label,
        c.url,
        headers: widget.headers,
      );
      if (!mounted) return;
      setState(() => _results[i] = res);
    }
    if (mounted) setState(() => _running = false);
  }

  int? get _fastestIndex {
    int? best;
    double bestSpeed = 0;
    _results.forEach((i, r) {
      if (r.ok && r.bytesPerSec > bestSpeed) {
        bestSpeed = r.bytesPerSec;
        best = i;
      }
    });
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final fastest = _fastestIndex;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.speed, size: 20),
          const SizedBox(width: 8),
          const Text('CDN 测速'),
          const Spacer(),
          if (_running)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: 360,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.candidates.length,
          itemBuilder: (_, i) {
            final c = widget.candidates[i];
            final r = _results[i];
            final isFastest = fastest == i && !_running;
            return ListTile(
              dense: true,
              leading: Icon(
                isFastest ? Icons.emoji_events : Icons.dns_outlined,
                size: 18,
                color: isFastest ? const Color(0xFFFDAD13) : null,
              ),
              title: Text(
                c.label,
                style: const TextStyle(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                r == null ? '测速中…' : r.speedText,
                style: TextStyle(
                  fontSize: 11,
                  color: r == null
                      ? null
                      : (r.ok ? Colors.green : Colors.redAccent),
                ),
              ),
              trailing: c.label == widget.currentLabel
                  ? const Text('当前', style: TextStyle(fontSize: 11))
                  : (isFastest
                      ? const Text(
                          '最快',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFFDAD13),
                          ),
                        )
                      : null),
              onTap: () => Navigator.of(context).pop(c),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: (!_running && fastest != null)
              ? () => Navigator.of(context).pop(widget.candidates[fastest])
              : null,
          child: const Text('选择最快'),
        ),
      ],
    );
  }
}
