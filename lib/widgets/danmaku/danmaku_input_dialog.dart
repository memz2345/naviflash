// lib/widgets/danmaku/danmaku_input_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../src/loading_indicator_m3e.dart';
import 'danmaku_fetcher.dart';
import '../../l10n/app_localizations.dart';

/// Bilibili 弹幕获取对话框
///
///  统一返回 [DanmakuFetchResult]（含 items / cid / fromCache / source / sourceType），
///    调用方可据此记录弹幕来源、显示缓存状态。
class DanmakuInputDialog extends StatefulWidget {
  const DanmakuInputDialog({super.key});

//  FIX: List<DanmakuItem>? → DanmakuFetchResult?
  static Future<DanmakuFetchResult?> show(BuildContext context) {
    return showDialog<DanmakuFetchResult>(
      context: context,
      builder: (_) => const DanmakuInputDialog(),
    );
  }

  @override
  State<DanmakuInputDialog> createState() => _DanmakuInputDialogState();
}

class _DanmakuInputDialogState extends State<DanmakuInputDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMsg;
  String? _hintText;

  /// 'bv' 或 'cid'
  String _inputType = 'bv';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _hintText_ {
    return _inputType == 'bv' ? 'BV1GJ411x7h7' : '137649199';
  }

  Future<void> _fetch() async {
    final l10n = AppLocalizations.of(context);
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMsg = _inputType == 'bv'
          ? l10n.danmakuInputBvPrompt
          : l10n.danmakuInputCidPrompt);
      return;
    }
    // CID 模式下校验是否为纯数字
    if (_inputType == 'cid' && !RegExp(r'^\d+$').hasMatch(input)) {
      setState(() => _errorMsg = l10n.danmakuInputCidNumeric);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _hintText = null;
    });

    final result = await DanmakuSegFetcher.fetch(
      input: input,
      inputType: _inputType,
    );
    if (!mounted) return;

    if (result.success) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _isLoading = false;
        _hintText = result.fromCache
            ? l10n.danmakuInputCacheHit(result.items.length, result.cid ?? '')
            : l10n.danmakuInputFetchSuccess(
                result.items.length, result.cid ?? '');
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
//  FIX: pop(result.items) → pop(result)，返回整个 Result
        Navigator.of(context).pop(result);
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMsg = result.error ?? AppLocalizations.of(context).danmakuInputFetchFail;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.cloud_download, color: Colors.blueAccent, size: 24),
          const SizedBox(width: 10),
          Text(
            l10n.danmakuInputTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 类型选择：BV / CID ───
          Row(
            children: [
              Text(l10n.danmakuInputTypeLabel, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'bv',
                    label: Text('BV'),
                    icon: Icon(Icons.tag, size: 16),
                  ),
                  ButtonSegment<String>(
                    value: 'cid',
                    label: Text('CID'),
                    icon: Icon(Icons.numbers, size: 16),
                  ),
                ],
                selected: {_inputType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _inputType = selection.first;
                    _errorMsg = null;
                    _hintText = null;
                  });
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ─── 输入框 ───
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            textInputAction: TextInputAction.go,
            keyboardType:
                _inputType == 'cid' ? TextInputType.number : TextInputType.text,
            onSubmitted: (_) => _fetch(),
            inputFormatters: _inputType == 'cid'
                ? [FilteringTextInputFormatter.digitsOnly]
                : [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            decoration: InputDecoration(
              hintText: _hintText_,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: Icon(
                _inputType == 'bv' ? Icons.link : Icons.numbers,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.blueAccent, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: LoadingIndicatorM3E(
                        constraints: BoxConstraints(
                          minWidth: 20,
                          maxWidth: 20,
                          minHeight: 20,
                          maxHeight: 20,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          // ─── 提示信息 ───
          Text(
            _inputType == 'bv' ? l10n.danmakuInputBvHint : l10n.danmakuInputCidHint,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          // ─── 错误信息 ───
          if (_errorMsg != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade400, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: TextStyle(
                          color: Colors.red.shade400, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          // ─── 成功提示 ───
          if (_hintText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _hintText!,
                      style:
                          const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              _isLoading ? null : () => Navigator.of(context).pop(null),
          child: Text(l10n.commonCancel),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _fetch,
          icon: _isLoading
              ? const LoadingIndicatorM3E(
                  color: Colors.white,
                  constraints: BoxConstraints(
                    minWidth: 16,
                    maxWidth: 16,
                    minHeight: 16,
                    maxHeight: 16,
                  ),
                )
              : const Icon(Icons.download, size: 18),
          label: Text(_isLoading ? l10n.danmakuInputFetching : l10n.danmakuInputFetchDanmaku),
        ),
      ],
    );
  }
}