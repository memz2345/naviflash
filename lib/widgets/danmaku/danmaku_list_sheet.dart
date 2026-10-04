import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

import 'danmaku_controller.dart';
import 'danmaku_model.dart';

                                     
                                    
Future<void> showDanmakuListSheet(
  BuildContext context,
  DanmakuController controller, {
  required ValueChanged<double> onSeek,
  double Function()? currentPosition,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DanmakuListSheet(
      controller: controller,
      onSeek: onSeek,
      currentPosition: currentPosition,
    ),
  );
}

class DanmakuListSheet extends StatefulWidget {
  final DanmakuController controller;

                      
  final ValueChanged<double> onSeek;

                                 
  final double Function()? currentPosition;

                             
     
                                                     
                                    
  final VoidCallback? onClose;

  const DanmakuListSheet({
    super.key,
    required this.controller,
    required this.onSeek,
    this.currentPosition,
    this.onClose,
  });

  @override
  State<DanmakuListSheet> createState() => _DanmakuListSheetState();
}

class _DanmakuListSheetState extends State<DanmakuListSheet> {
                           
  static const double _rowExtent = 46.0;

  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

                     
  String _query = '';

                              
  bool _following = true;

                           
  Timer? _followTimer;

                              
  int _lastHighlighted = -1;

                                      
  late List<DanmakuItem> _all;

  @override
  void initState() {
    super.initState();
    _all = widget.controller.items
        .where((d) =>
            d.mode != DanmakuMode.advanced && d.mode != DanmakuMode.code)
        .toList();
    _scrollCtrl.addListener(() {
                                   
      if (_scrollCtrl.position.userScrollDirection != ScrollDirection.idle) {
        _following = false;
      }
    });
    if (widget.currentPosition != null) {
      _followTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!mounted || !_following || _query.isNotEmpty) return;
        final idx = _indexOfTime(widget.currentPosition!());
        if (idx != _lastHighlighted) {
          setState(() => _lastHighlighted = idx);
          _scrollToIndex(idx, animate: false);
        }
      });
    }
  }

  @override
  void dispose() {
    _followTimer?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DanmakuItem> get _filtered {
    if (_query.isEmpty) return _all;
    final q = _query.toLowerCase();
    return _all.where((d) => d.content.toLowerCase().contains(q)).toList();
  }

                                        
  int _indexOfTime(double seconds) {
    final list = _filtered;
    if (list.isEmpty) return 0;
    int lo = 0, hi = list.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (list[mid].time <= seconds) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return (lo - 1).clamp(0, list.length - 1);
  }

  void _scrollToIndex(int index, {required bool animate}) {
    if (!_scrollCtrl.hasClients) return;
    final target = (index * _rowExtent)
        .clamp(0.0, _scrollCtrl.position.maxScrollExtent)
        .toDouble();
    if (animate) {
      _scrollCtrl.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollCtrl.jumpTo(target);
    }
  }

                         
  void _jumpToCurrent() {
    final pos = widget.currentPosition;
    setState(() => _following = true);
    if (pos != null) {
      final idx = _indexOfTime(pos());
      _lastHighlighted = idx;
      _scrollToIndex(idx, animate: true);
    }
  }

  String _fmtTime(double seconds) {
    final s = seconds.round();
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.8;
    final list = _filtered;
    final pos = widget.currentPosition;
    final highlightIdx = (pos != null && _query.isEmpty) ? _lastHighlighted : -1;

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
                            _query.isEmpty
                                ? l10n.playerDanmakuListCount(_all.length)
                                : l10n.playerDanmakuListCount(list.length),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (pos != null)
                          IconButton(
                            tooltip: l10n.playerDanmakuListJumpCurrent,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.my_location,
                              size: 20,
                              color: _following
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                            onPressed: _jumpToCurrent,
                          ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                          onPressed: () {
                            final close = widget.onClose;
                            if (close != null) {
                              close();
                              return;
                            }
                            Navigator.of(context).maybePop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                            
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    style: TextStyle(fontSize: 13, color: cs.onSurface),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.playerDanmakuListSearchHint,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 18,
                                color: cs.onSurfaceVariant,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                      filled: true,
                      fillColor: cs.surfaceContainerHigh.withValues(
                        alpha: 0.6,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                             
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 24,
                    ),
                    child: Text(
                      _all.isEmpty
                          ? l10n.playerDanmakuListEmpty
                          : l10n.playerDanmakuListNoMatch,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.only(bottom: 12),
                      itemExtent: _rowExtent,
                      itemCount: list.length,
                      itemBuilder: (ctx, i) {
                        final d = list[i];
                        final highlighted = i == highlightIdx;
                        return _DanmakuListRow(
                          time: _fmtTime(d.time),
                          content: d.content,
                          color: d.color,
                          highlighted: highlighted,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onSeek(d.time);
                            Navigator.of(ctx).maybePop();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DanmakuListRow extends StatelessWidget {
  final String time;
  final String content;
  final Color color;
  final bool highlighted;
  final VoidCallback onTap;

  const _DanmakuListRow({
    required this.time,
    required this.content,
    required this.color,
    required this.highlighted,
    required this.onTap,
  });

                                  
  bool get _isNearWhite {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return rgb >= 0xE0E0E0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textColor = _isNearWhite ? cs.onSurface : color;
    return Material(
      color: highlighted ? cs.primaryContainer.withValues(alpha: 0.5) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: highlighted ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
