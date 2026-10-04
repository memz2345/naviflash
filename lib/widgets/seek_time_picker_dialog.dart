                                           
  
                                      
                              
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';

                                   
Future<Duration?> showSeekTimePickerDialog(
  BuildContext context, {
  required Duration duration,
  required Duration initial,
}) {
  if (duration <= Duration.zero) return Future.value(null);
  return showDialog<Duration>(
    context: context,
    builder: (_) => SeekTimePickerDialog(duration: duration, initial: initial),
  );
}

                          
class SeekTimePickerDialog extends StatefulWidget {
                                 
  final Duration duration;

                                      
  final Duration initial;

  const SeekTimePickerDialog({
    super.key,
    required this.duration,
    required this.initial,
  });

  @override
  State<SeekTimePickerDialog> createState() => _SeekTimePickerDialogState();
}

class _SeekTimePickerDialogState extends State<SeekTimePickerDialog> {
  late int _hour;
  late int _minute;
  late int _second;
  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;
  late final FixedExtentScrollController _secondCtrl;

                       
  bool get _showHour => widget.duration.inHours > 0;

  int get _hourMax => widget.duration.inHours;

  @override
  void initState() {
    super.initState();
    final total = widget.initial.inMilliseconds.clamp(
      0,
      widget.duration.inMilliseconds,
    );
    _hour = (total ~/ 3600000).clamp(0, _hourMax);
    _minute = ((total % 3600000) ~/ 60000).clamp(0, 59);
    _second = ((total % 60000) ~/ 1000).clamp(0, 59);
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
    _secondCtrl = FixedExtentScrollController(initialItem: _second);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _secondCtrl.dispose();
    super.dispose();
  }

  Duration get _target =>
      Duration(hours: _hour, minutes: _minute, seconds: _second);

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        l10n.playerTimePickerTitle,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                              
            Text(
              _showHour
                  ? '${_two(_hour)}:${_two(_minute)}:${_two(_second)}'
                  : '${_two(_minute)}:${_two(_second)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 168,
              child: Row(
                children: [
                  if (_showHour)
                    _buildWheel(
                      context,
                      controller: _hourCtrl,
                      count: _hourMax + 1,
                      label: l10n.playerTimeUnitHour,
                      onChanged: (v) => setState(() => _hour = v),
                    ),
                  _buildWheel(
                    context,
                    controller: _minuteCtrl,
                    count: 60,
                    label: l10n.playerTimeUnitMinute,
                    onChanged: (v) => setState(() => _minute = v),
                  ),
                  _buildWheel(
                    context,
                    controller: _secondCtrl,
                    count: 60,
                    label: l10n.playerTimeUnitSecond,
                    onChanged: (v) => setState(() => _second = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_target),
          child: Text(l10n.confirm),
        ),
      ],
    );
  }

  Widget _buildWheel(
    BuildContext context, {
    required FixedExtentScrollController controller,
    required int count,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 132,
            child: ListWheelScrollView.useDelegate(
              controller: controller,
              itemExtent: 34,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: onChanged,
              useMagnifier: true,
              magnification: 1.12,
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: count,
                builder: (context, index) => Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'monospace',
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
