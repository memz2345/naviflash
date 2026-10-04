                                              
  
                                              
                                                   
                       
                                             
                                                         
                                        
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

                       
class DanmakuSendStyle {
  final String msg;

                                  
  final int mode;

                                    
  final int color;

                      
  final int fontSize;

  const DanmakuSendStyle({
    required this.msg,
    required this.mode,
    required this.color,
    required this.fontSize,
  });
}

                   
const List<int> kDanmakuPresetColors = [
  0xFFFFFF,     
  0xFE0302,     
  0xFF7204,     
  0xFFAA02,     
  0x96EB00,      
  0x22B340,     
  0x00B0FF,      
  0x4997E0,     
  0xA04FD0,     
  0xF82BA7,     
];

int _lastMode = 1;
int _lastColor = 0xFFFFFF;
int _lastFontSize = 25;

                               
const String _dmStyleApi = 'https://api.bilibili.com/x/v2/dm/post/style';
final Map<int, List<int>> _vipStyleCache = <int, List<int>>{};

                                                      
                                        
                                    
Future<List<int>> _fetchVipColors(int pid) async {
  final cached = _vipStyleCache[pid];
  if (cached != null) return cached;
  final cookie =
      biliLoginCookie(BiliCookieScope.video) ??
      biliLoginCookie(BiliCookieScope.interactions);
  final mid = biliCurrentMid;
  if (cookie == null || cookie.isEmpty || mid <= 0) {
    _vipStyleCache[pid] = const <int>[];
    return const <int>[];
  }
  try {
    final client = await NetworkSettingsService.instance.getApiClient();
    final resp = await client
        .get(
          Uri.parse('$_dmStyleApi?pid=$pid&mid=$mid'),
          headers: {
            'Cookie': cookie,
            'Referer': 'https://www.bilibili.com',
            ...NetworkSettingsService.instance.apiHeaders,
          },
        )
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      _vipStyleCache[pid] = const <int>[];
      return const <int>[];
    }
    final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
    final map = biliAsMap(json);
    final colors = <int>[];
    if (map != null && biliToInt(map['code']) == 0) {
      final data = biliAsList<dynamic>(map['data']);
      for (final e in data) {
        final style = biliAsMap(e);
        if (style == null) continue;
        final c = _parseStyleColor(style['color']);
        if (c != null && !colors.contains(c)) colors.add(c);
      }
    }
    _vipStyleCache[pid] = colors;
    return colors;
  } catch (e) {
    debugPrint('[DanmakuSend] 专属颜色获取失败: $e');
    _vipStyleCache[pid] = const <int>[];
    return const <int>[];
  }
}

                                                 
int? _parseStyleColor(dynamic v) {
  if (v is num) {
    final c = v.toInt();
    return c >= 0 && c <= 0xFFFFFF ? c : null;
  }
  if (v is String) {
    var s = v.trim().toLowerCase();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.startsWith('0x')) s = s.substring(2);
    if (s.isEmpty) return null;
    final c = int.tryParse(s, radix: 16) ?? int.tryParse(v.trim());
    if (c == null || c < 0 || c > 0xFFFFFF) return null;
    return c;
  }
  return null;
}

                                             
                                   
   
                                            
               
Future<DanmakuSendStyle?> showDanmakuSendSheet(
  BuildContext context, {
  String initialText = '',
                              
                                  
                  
  double bottomPadding = 0,
  int? aid,
}) {
  return showAppBottomSheet<DanmakuSendStyle>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DanmakuSendSheet(
      initialText: initialText,
      bottomPadding: bottomPadding,
      aid: aid,
    ),
  );
}

class _DanmakuSendSheet extends StatefulWidget {
  final String initialText;
  final double bottomPadding;

                                             
  final int? aid;

  const _DanmakuSendSheet({
    required this.initialText,
    this.bottomPadding = 0,
    this.aid,
  });

  @override
  State<_DanmakuSendSheet> createState() => _DanmakuSendSheetState();
}

class _DanmakuSendSheetState extends State<_DanmakuSendSheet> {
  late final TextEditingController _controller;
  late int _mode = _lastMode;
  late int _color = _lastColor;
  late int _fontSize = _lastFontSize;

                           
  List<int> _vipColors = const <int>[];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _loadVipColors();
  }

  Future<void> _loadVipColors() async {
    final pid = widget.aid;
    if (pid == null || pid <= 0) return;
    final colors = await _fetchVipColors(pid);
    if (colors.isEmpty || !mounted) return;
    setState(() => _vipColors = colors);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final msg = _controller.text.trim();
    if (msg.isEmpty) {
      HapticFeedback.lightImpact();
      return;
    }
             
    _lastMode = _mode;
    _lastColor = _color;
    _lastFontSize = _fontSize;
    Navigator.of(context).pop(
      DanmakuSendStyle(
        msg: msg,
        mode: _mode,
        color: _color,
        fontSize: _fontSize,
      ),
    );
  }

  Future<void> _pickCustomColor() async {
    final l10n = AppLocalizations.of(context);
    var temp = Color(0xFF000000 | (_color & 0xFFFFFF));
    final picked = await showDialog<int>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.danmakuSendCustomColor),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
            pickerAreaHeightPercent: 0.5,
            portraitOnly: true,
            enableAlpha: false,
            displayThumbColor: true,
            labelTypes: const [ColorLabelType.rgb, ColorLabelType.hex],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogCtx).pop(temp.toARGB32() & 0xFFFFFF),
            child: Text(l10n.danmakuSendColorOk),
          ),
        ],
      ),
    );
    if (picked != null && mounted) setState(() => _color = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final msg = _controller.text;
    final previewColor = Color(0xFF000000 | (_color & 0xFFFFFF));
    final canSend = msg.trim().isNotEmpty && msg.length <= 100;

                                       
    final previewAlign = switch (_mode) {
      5 => Alignment.topCenter,
      4 => Alignment.bottomCenter,
      _ => Alignment.center,
    };

    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
                                           
                      
    final bottomGap = viewInsets > 0 ? viewInsets : widget.bottomPadding;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
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
                SizedBox(
                  height: 46,
                  child: Center(
                    child: Text(
                      l10n.danmakuSendTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ),
                                               
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Align(
                      alignment: previewAlign,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _StrokedText(
                          text: msg.isEmpty
                              ? l10n.danmakuSendPreviewPlaceholder
                              : msg,
                          color: previewColor,
                          fontSize: _fontSize.toDouble(),
                        ),
                      ),
                    ),
                  ),
                ),
                            
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLength: 100,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(fontSize: 14, color: cs.onSurface),
                    decoration: InputDecoration(
                      isDense: true,
                      counterText: '${msg.length}/100',
                      counterStyle: TextStyle(
                        fontSize: 11,
                        color: msg.length > 100
                            ? cs.error
                            : cs.onSurfaceVariant,
                      ),
                      hintText: l10n.danmakuInputHint,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHigh,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                                        
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          l10n.danmakuSendModeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SegmentedButton<int>(
                          segments: [
                            ButtonSegment(
                              value: 1,
                              label: Text(l10n.danmakuTypeScroll),
                            ),
                            ButtonSegment(
                              value: 5,
                              label: Text(l10n.danmakuTypeTop),
                            ),
                            ButtonSegment(
                              value: 4,
                              label: Text(l10n.danmakuTypeBottom),
                            ),
                          ],
                          selected: {_mode},
                          onSelectionChanged: (s) =>
                              setState(() => _mode = s.first),
                          showSelectedIcon: false,
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                                      
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          l10n.danmakuSendFontSizeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SegmentedButton<int>(
                          segments: [
                            ButtonSegment(
                              value: 18,
                              label: Text(l10n.danmakuFontSizeSmall),
                            ),
                            ButtonSegment(
                              value: 25,
                              label: Text(l10n.danmakuFontSizeStandard),
                            ),
                            ButtonSegment(
                              value: 36,
                              label: Text(l10n.danmakuFontSizeLarge),
                            ),
                          ],
                          selected: {_fontSize},
                          onSelectionChanged: (s) =>
                              setState(() => _fontSize = s.first),
                          showSelectedIcon: false,
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                                              
                if (_vipColors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(
                            '专属',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final c in _vipColors)
                                  _ColorDot(
                                    color: Color(0xFF000000 | c),
                                    selected: _color == c,
                                    onTap: () => setState(() => _color = c),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                                 
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          l10n.danmakuSendColorLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final c in kDanmakuPresetColors)
                                _ColorDot(
                                  color: Color(0xFF000000 | c),
                                  selected: _color == c,
                                  onTap: () => setState(() => _color = c),
                                ),
                                                            
                              _ColorDot(
                                color: previewColor,
                                selected: !kDanmakuPresetColors.contains(
                                      _color,
                                    ) &&
                                    !_vipColors.contains(_color),
                                custom: true,
                                onTap: _pickCustomColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                           
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: canSend ? _send : null,
                      icon: const Icon(Icons.send_outlined, size: 16),
                      label: Text(l10n.rcSend),
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
}

                           
class _StrokedText extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;

  const _StrokedText({
    required this.text,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
              
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize * 0.08
              ..color = Colors.black,
          ),
        ),
              
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: fontSize, color: color),
        ),
      ],
    );
  }
}

         
class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

                     
  final bool custom;

  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
    this.custom = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? cs.primary : Colors.black26,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: custom
              ? Icon(Icons.palette_outlined, size: 14, color: color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70)
              : null,
        ),
      ),
    );
  }
}
