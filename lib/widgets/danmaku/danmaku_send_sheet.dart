// lib/widgets/danmaku/danmaku_send_sheet.dart
//
//   - 输入（≤100 字）+ 实时预览（描边弹幕，按模式显示在 顶部/滚动/底部）；
//   - 模式：滚动(1) / 顶部(5) / 底部(4)；字号：小18 / 标准25 / 大36
//     （B 站 web 端同款三档）；
//   - 颜色：B 站常用色板 + 自定义（flutter_colorpicker）；
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/widgets/liquid_glass.dart';

/// 弹幕发送配置（弹层 pop 返回值）。
class DanmakuSendStyle {
  final String msg;

  /// API mode：1 滚动 / 4 底部 / 5 顶部。
  final int mode;

  /// 十进制颜色值（如 0xFFFFFF = 16777215）。
  final int color;

  /// 字号：18 / 25 / 36。
  final int fontSize;

  const DanmakuSendStyle({
    required this.msg,
    required this.mode,
    required this.color,
    required this.fontSize,
  });
}

/// B 站常用弹幕色板（十进制）。
const List<int> kDanmakuPresetColors = [
  0xFFFFFF, // 白
  0xFE0302, // 红
  0xFF7204, // 橙
  0xFFAA02, // 黄
  0x96EB00, // 浅绿
  0x22B340, // 绿
  0x00B0FF, // 浅蓝
  0x4997E0, // 蓝
  0xA04FD0, // 紫
  0xF82BA7, // 粉
];

int _lastMode = 1;
int _lastColor = 0xFFFFFF;
int _lastFontSize = 25;

/// 打开「发弹幕」面板；点「发送」返回组装好的 [DanmakuSendStyle]，
/// 取消 / 返回为 null。发送（API 调用）由调用方完成。
Future<DanmakuSendStyle?> showDanmakuSendSheet(
  BuildContext context, {
  String initialText = '',
}) {
  return showModalBottomSheet<DanmakuSendStyle>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DanmakuSendSheet(initialText: initialText),
  );
}

class _DanmakuSendSheet extends StatefulWidget {
  final String initialText;

  const _DanmakuSendSheet({required this.initialText});

  @override
  State<_DanmakuSendSheet> createState() => _DanmakuSendSheetState();
}

class _DanmakuSendSheetState extends State<_DanmakuSendSheet> {
  late final TextEditingController _controller;
  late int _mode = _lastMode;
  late int _color = _lastColor;
  late int _fontSize = _lastFontSize;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
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
    // 记住本次样式
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

    // 预览对齐：顶部(5) 上 / 滚动(1) 中 / 底部(4) 下
    final previewAlign = switch (_mode) {
      5 => Alignment.topCenter,
      4 => Alignment.bottomCenter,
      _ => Alignment.center,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                // ── 实时预览（深色底 + 描边弹幕，按模式定位） ──
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
                // ── 输入框 ──
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
                // ── 模式：滚动 / 顶部 / 底部 ──
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
                // ── 字号：小 / 标准 / 大 ──
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
                // ── 色板 + 自定义 ──
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
                              // 自定义颜色（不在色板中时显示当前自定义色）
                              _ColorDot(
                                color: previewColor,
                                selected:
                                    !kDanmakuPresetColors.contains(_color),
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
                // ── 发送 ──
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

/// 描边文字（弹幕渲染同款：黑描边 + 填充色）。
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
        // 描边层
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
        // 填充层
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

/// 色板圆点。
class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  /// 自定义色（显示调色盘小图标）。
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
