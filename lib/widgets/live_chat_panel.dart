// lib/widgets/live_chat_panel.dart
//
// 直播间聊天面板（对照 PiliPlus 的 chat_panel + bottom_control）：
//   - 消息流：弹幕（用户名彩色 / 粉丝牌 / 内联表情）、进场欢迎、礼物、
//     上舰、SuperChat 卡片；最多保留 250 条，150ms 批量刷新防抖
//   - 自动滚动到底部；用户上滑看历史时暂停，提供「回到最新」按钮
//   - 底部输入条：弹幕覆盖层开关 / 输入框 / 发送 / 点赞连击 / 表情包
//   - 长按弹幕可复制或 @对方
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:naviflash/services/bilibili_live_danmaku_service.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/widgets/app_toast.dart';

/// 单条消息上限（超出丢弃最旧的）。
const int _maxEntries = 250;

/// 批量刷新间隔。
const Duration _flushInterval = Duration(milliseconds: 150);

// ════════════════════════════════════════
//  消息条目模型
// ════════════════════════════════════════

sealed class _ChatEntry {
  final int seq;
  const _ChatEntry(this.seq);
}

class _DmEntry extends _ChatEntry {
  final LiveDmEvent dm;
  const _DmEntry(super.seq, this.dm);
}

class _EnterEntry extends _ChatEntry {
  final LiveEnterEvent e;
  const _EnterEntry(super.seq, this.e);
}

class _GiftEntry extends _ChatEntry {
  final LiveGiftEvent e;
  const _GiftEntry(super.seq, this.e);
}

class _GuardEntry extends _ChatEntry {
  final LiveGuardEvent e;
  const _GuardEntry(super.seq, this.e);
}

class _ScEntry extends _ChatEntry {
  final LiveSuperChatMsg e;
  const _ScEntry(super.seq, this.e);
}

// ════════════════════════════════════════
//  面板
// ════════════════════════════════════════

class LiveChatPanel extends StatefulWidget {
  /// 弹幕事件流（broadcast，可与其他订阅共存）。
  final Stream<LiveDanmuEvent> events;

  /// 初始 SuperChat 列表（进房时接口取回）。
  final List<LiveSuperChatMsg> initialSuperChats;

  /// 是否已登录（决定输入框可编辑还是提示去登录）。
  final bool loggedIn;

  /// 发送弹幕（由页面接服务，返回结果供 toast）。
  final Future<({bool ok, String message})> Function(String msg)? onSend;

  /// 点赞（clickTime = 累计连点次数）。
  final Future<({bool ok, String message})> Function(int clickTime)? onLike;

  /// 未登录时点输入框的回调（打开登录页）。
  final VoidCallback? onRequireLogin;

  /// 弹幕覆盖层开关状态与切换回调。
  final bool showOverlayDanmaku;
  final ValueChanged<bool>? onToggleOverlayDanmaku;

  /// 表情包加载（返回空 = 无表情入口）。
  final Future<List<LiveEmote>> Function()? onLoadEmotes;

  const LiveChatPanel({
    super.key,
    required this.events,
    this.initialSuperChats = const [],
    this.loggedIn = false,
    this.onSend,
    this.onLike,
    this.onRequireLogin,
    this.showOverlayDanmaku = true,
    this.onToggleOverlayDanmaku,
    this.onLoadEmotes,
  });

  @override
  State<LiveChatPanel> createState() => _LiveChatPanelState();
}

class _LiveChatPanelState extends State<LiveChatPanel> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  final List<_ChatEntry> _entries = [];
  final List<_ChatEntry> _pending = [];
  Timer? _flushTimer;
  StreamSubscription<LiveDanmuEvent>? _sub;
  int _seq = 0;

  bool _autoScroll = true;
  bool _sending = false;

  // 点赞连击
  int _likeCount = 0;
  Timer? _likeTimer;

  // 表情包
  List<LiveEmote>? _emotes;

  /// 已并入列表的初始 SuperChat 条数（页面异步取回后增量并入）。
  int _scConsumed = 0;

  @override
  void initState() {
    super.initState();
    _consumeInitialSuperChats();
    _scroll.addListener(_onScroll);
    _sub = widget.events.listen(_onEvent);
  }

  /// 弹幕流 / 初始 SuperChat 在页面侧是异步就绪的，变化时重新接入。
  @override
  void didUpdateWidget(LiveChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events) {
      _sub?.cancel();
      _sub = widget.events.listen(_onEvent);
    }
    if (widget.initialSuperChats.length > _scConsumed) {
      _consumeInitialSuperChats();
      _jumpToBottom();
    }
  }

  void _consumeInitialSuperChats() {
    for (final sc in widget.initialSuperChats.skip(_scConsumed)) {
      _entries.add(_ScEntry(_seq++, sc));
    }
    _scConsumed = widget.initialSuperChats.length;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _flushTimer?.cancel();
    _likeTimer?.cancel();
    _scroll.dispose();
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ── 事件接入（批量刷新） ──

  void _onEvent(LiveDanmuEvent e) {
    switch (e) {
      case final LiveDmEvent dm:
        _pending.add(_DmEntry(_seq++, dm));
      case final LiveEnterEvent ev:
        _pending.add(_EnterEntry(_seq++, ev));
      case final LiveGiftEvent ev:
        _pending.add(_GiftEntry(_seq++, ev));
      case final LiveGuardEvent ev:
        _pending.add(_GuardEntry(_seq++, ev));
      case final LiveSuperChatEvent ev:
        final msg = LiveSuperChatMsg.fromData({
          'id': ev.id,
          'uid': ev.uid,
          'price': ev.price,
          'message': ev.message,
          'background_color': ev.topColor.toARGB32() & 0xFFFFFF,
          'background_bottom_color': ev.bottomColor.toARGB32() & 0xFFFFFF,
          'end_time': ev.endTime,
          'user_info': {'uname': ev.uname, 'face': ev.face},
        });
        if (msg != null) _pending.add(_ScEntry(_seq++, msg));
      default:
        return;
    }
    _flushTimer ??= Timer(_flushInterval, _flush);
  }

  void _flush() {
    _flushTimer = null;
    if (!mounted || _pending.isEmpty) return;
    setState(() {
      _entries.addAll(_pending);
      _pending.clear();
      if (_entries.length > _maxEntries) {
        _entries.removeRange(0, _entries.length - _maxEntries);
      }
    });
    if (_autoScroll) _jumpToBottom();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.maxScrollExtent - pos.pixels > 80) {
      if (_autoScroll) setState(() => _autoScroll = false);
    } else if (!_autoScroll) {
      setState(() => _autoScroll = true);
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  // ── 发送 / 点赞 / 表情 ──

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    if (!widget.loggedIn) {
      widget.onRequireLogin?.call();
      return;
    }
    if (_sending) return;
    setState(() => _sending = true);
    final result = await widget.onSend?.call(text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (result == null) return;
    if (result.ok) {
      _input.clear();
      _inputFocus.unfocus();
    } else {
      showAppToast(context, result.message, error: true);
    }
  }

  void _onLikeTap() {
    _likeTimer?.cancel();
    setState(() => _likeCount++);
    _likeTimer = Timer(const Duration(milliseconds: 800), _reportLike);
  }

  Future<void> _reportLike() async {
    final count = _likeCount;
    if (!mounted) return;
    setState(() => _likeCount = 0);
    if (count == 0) return;
    if (!widget.loggedIn) {
      widget.onRequireLogin?.call();
      return;
    }
    final result = await widget.onLike?.call(count);
    if (!mounted) return;
    if (result != null && result.ok) {
      showAppToast(context, '点赞成功');
    } else if (result != null) {
      showAppToast(context, result.message, error: true);
    }
  }

  Future<void> _openEmotes() async {
    if (!widget.loggedIn) {
      widget.onRequireLogin?.call();
      return;
    }
    if (_emotes == null) {
      final list = await widget.onLoadEmotes?.call() ?? const <LiveEmote>[];
      if (mounted) setState(() => _emotes = list);
    }
    if (!mounted) return;
    final list = _emotes ?? const <LiveEmote>[];
    if (list.isEmpty) {
      showAppToast(context, '表情包加载失败', error: true);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      builder: (ctx) => SafeArea(
        child: GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 64,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final emote = list[i];
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                final selection = _input.selection;
                final base = selection.baseOffset.clamp(0, _input.text.length);
                final newText = _input.text
                    .replaceRange(base, selection.extentOffset, emote.name);
                _input.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(
                    offset: base + emote.name.length,
                  ),
                );
                Navigator.of(ctx).pop();
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image(
                  image: CachedImageProvider(emote.url),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      emote.name,
                      style: const TextStyle(fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(child: _buildMessageList(cs)),
        _buildInputBar(cs),
      ],
    );
  }

  Widget _buildMessageList(ColorScheme cs) {
    return Stack(
      children: [
        Positioned.fill(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            itemCount: _entries.length,
            itemBuilder: (context, i) => _buildEntry(cs, _entries[i]),
          ),
        ),
        if (!_autoScroll)
          Positioned(
            right: 12,
            bottom: 10,
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: cs.surfaceContainerHighest,
                foregroundColor: cs.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () {
                setState(() => _autoScroll = true);
                _jumpToBottom();
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_downward, size: 14),
                  SizedBox(width: 4),
                  Text('回到最新', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEntry(ColorScheme cs, _ChatEntry entry) {
    switch (entry) {
      case _DmEntry(:final dm):
        return _buildDm(cs, dm);
      case _EnterEntry(:final e):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(
            e.msgType == 2 ? '${e.name} 关注了主播' : '欢迎 ${e.name} 进入直播间',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        );
      case _GiftEntry(:final e):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(
            '${e.name} ${e.action} ${e.giftName}'
            '${e.num > 1 ? ' x${e.num}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFB06F3B),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case _GuardEntry(:final e):
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A4318), Color(0xFF93652C)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${e.name} 开通了${_guardLabel(e.guardLevel)}'
            '${e.num > 1 ? ' x${e.num}' : ''}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFE9C8),
            ),
          ),
        );
      case _ScEntry(:final e):
        return _buildSuperChat(e);
    }
  }

  String _guardLabel(int level) => switch (level) {
    1 => '总督',
    2 => '提督',
    _ => '舰长',
  };

  Widget _buildDm(ColorScheme cs, LiveDmEvent dm) {
    return InkWell(
      onTap: () => _inputFocus.requestFocus(),
      onLongPress: () => _showDmActions(dm),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: Text.rich(
          TextSpan(
            children: [
              if (dm.medalName.isNotEmpty) ...[
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _medalChip(dm.medalName, dm.medalLevel),
                  ),
                ),
              ],
              TextSpan(
                text: dm.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _nameColor(dm.uid, cs),
                ),
              ),
              TextSpan(
                text: '：',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              ..._dmTextSpans(cs, dm),
            ],
          ),
        ),
      ),
    );
  }

  /// 弹幕正文：按表情名切段，命中表情的位置插入内联图片。
  List<InlineSpan> _dmTextSpans(ColorScheme cs, LiveDmEvent dm) {
    final baseStyle = TextStyle(
      fontSize: 13,
      fontWeight: dm.isSelf ? FontWeight.w700 : FontWeight.w500,
      color: dm.isSelf ? cs.primary : cs.onSurface,
    );
    if (dm.emotes.isEmpty || !dm.text.contains('[')) {
      return [TextSpan(text: dm.text, style: baseStyle)];
    }
    final pattern = RegExp(dm.emotes.keys.map(RegExp.escape).join('|'));
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in pattern.allMatches(dm.text)) {
      if (m.start > last) {
        spans.add(
          TextSpan(text: dm.text.substring(last, m.start), style: baseStyle),
        );
      }
      final url = dm.emotes[m.group(0)];
      if (url != null) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Image(
            image: CachedImageProvider(url),
            height: 24,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(
              m.group(0)!,
              style: TextStyle(fontSize: 13, color: cs.onSurface),
            ),
          ),
        ));
      }
      last = m.end;
    }
    if (last < dm.text.length) {
      spans.add(TextSpan(text: dm.text.substring(last), style: baseStyle));
    }
    return spans;
  }

  void _showDmActions(LiveDmEvent dm) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, size: 20),
              title: const Text('复制弹幕', style: TextStyle(fontSize: 14)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: dm.text));
                Navigator.of(ctx).pop();
                if (mounted) showAppToast(context, '已复制');
              },
            ),
            ListTile(
              leading: const Icon(Icons.alternate_email, size: 20),
              title: const Text('@TA', style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.of(ctx).pop();
                _input.text = '@${dm.name} ${_input.text}';
                _input.selection = TextSelection.collapsed(
                  offset: _input.text.length,
                );
                _inputFocus.requestFocus();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _medalChip(String name, int level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0x1A93652C),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF93652C), width: 0.8),
      ),
      child: Text(
        '$name·$level',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF93652C),
        ),
      ),
    );
  }

  Widget _buildSuperChat(LiveSuperChatMsg e) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: e.bottomColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: e.topColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                if (e.face.isNotEmpty) ...[
                  ClipOval(
                    child: Image(
                      image: CachedImageProvider(e.face),
                      width: 22,
                      height: 22,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    e.uname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '¥${_priceText(e.price)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            child: Text(
              e.message,
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _priceText(num price) {
    if (price == price.roundToDouble()) return price.toInt().toString();
    return price.toString();
  }

  // ════════════════════════════════════════
  //  输入条
  // ════════════════════════════════════════

  Widget _buildInputBar(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      child: Row(
        children: [
          // 弹幕覆盖层开关
          if (widget.onToggleOverlayDanmaku != null)
            IconButton(
              tooltip: widget.showOverlayDanmaku ? '关闭弹幕' : '开启弹幕',
              visualDensity: VisualDensity.compact,
              icon: Icon(
                widget.showOverlayDanmaku
                    ? Icons.subtitles
                    : Icons.subtitles_off_outlined,
                size: 20,
                color: widget.showOverlayDanmaku
                    ? cs.primary
                    : cs.onSurfaceVariant,
              ),
              onPressed: () =>
                  widget.onToggleOverlayDanmaku!(!widget.showOverlayDanmaku),
            ),
          Expanded(
            child: TextField(
              controller: _input,
              focusNode: _inputFocus,
              readOnly: !widget.loggedIn,
              onTap: widget.loggedIn ? null : widget.onRequireLogin,
              style: const TextStyle(fontSize: 13),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.loggedIn ? '发个弹幕见证当下' : '登录后发送弹幕',
                hintStyle: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                filled: true,
                fillColor: cs.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '表情',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.emoji_emotions_outlined,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            onPressed: _openEmotes,
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: '点赞',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
                onPressed: _onLikeTap,
              ),
              if (_likeCount > 0)
                Positioned(
                  right: 0,
                  top: 2,
                  child: Text(
                    'x$_likeCount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: '发送',
            visualDensity: VisualDensity.compact,
            icon: _sending
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  )
                : Icon(Icons.send_outlined, size: 20, color: cs.primary),
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}

/// 弹幕用户名配色（B 站同款色系，按 uid 稳定取色）。
Color _nameColor(int uid, ColorScheme cs) {
  if (uid <= 0) return cs.onSurface;
  const palette = [
    Color(0xFFE6832E),
    Color(0xFFC24A7B),
    Color(0xFF6B9F3C),
    Color(0xFF4E8CC2),
    Color(0xFF9161C8),
    Color(0xFFC79B3B),
    Color(0xFF3FA69B),
    Color(0xFFD2604A),
  ];
  return palette[uid % palette.length];
}
