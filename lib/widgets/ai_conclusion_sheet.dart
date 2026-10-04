                                       
                                       
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:naviflash/services/bilibili_video_service.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

Future<void> showAiConclusionSheet(
  BuildContext context, {
  required BiliAiConclusion data,
  void Function(Duration position)? onSeek,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.8,
      child: _AiConclusionBody(data: data, onSeek: onSeek),
    ),
  );
}

class _AiConclusionBody extends StatelessWidget {
  final BiliAiConclusion data;
  final void Function(Duration position)? onSeek;

  const _AiConclusionBody({required this.data, this.onSeek});

  static String _fmt(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final m = s ~/ 60;
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 20),
              const SizedBox(width: 8),
              const Text(
                'AI 视频总结',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              if (data.summary.isNotEmpty)
                SelectableText(
                  data.summary,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              if (data.summary.isNotEmpty && data.outline.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 2),
                ),
              for (final outline in data.outline) ...[
                Text(
                  outline.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                for (final part in outline.parts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.55,
                          color: cs.onSurface,
                        ),
                        children: [
                          if (part.timestamp > 0)
                            TextSpan(
                              text: '[${_fmt(part.timestamp)}] ',
                              style: TextStyle(
                                color: onSeek != null
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: onSeek == null
                                  ? null
                                  : (TapGestureRecognizer()
                                      ..onTap = () => onSeek!(
                                            Duration(
                                              seconds: part.timestamp,
                                            ),
                                          )),
                            ),
                          TextSpan(text: part.content),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              Text(
                '内容由 AI 生成，仅供参考',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
