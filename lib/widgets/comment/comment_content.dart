// lib/widgets/comment/comment_content.dart
//
//   - CommentMessageText：正文 + 表情内联渲染。B 站评论接口随每条评论下发
//     content.emote（[表情文本] → {url, meta:{size}}），用正则把正文里的
//     [表情] 原位替换成表情图片（尺寸 = size * 20px），未匹配的保留原文。
//   - CommentPictures：评论区配图缩略图行（content.pictures），点击后下载
//     原图并进入 ImageViewerPage 大图查看。
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/screens/image_viewer_page.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/link_utils.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/long_press_image_preview.dart';
import 'package:naviflash/l10n/app_localizations.dart';

/// 图片请求头：服务未初始化（如单元测试）时安全返回 null。
Map<String, String>? _imageHeaders() {
  try {
    final headers = NetworkSettingsService.instance.apiHeaders;
    return headers.isEmpty ? null : headers;
  } catch (_) {
    return null;
  }
}

/// 评论正文（表情内联）。用法与 Text 一致，可传 maxLines/overflow。
class CommentMessageText extends StatelessWidget {
  final String message;
  final Map<String, BiliCommentEmote> emotes;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const CommentMessageText({
    super.key,
    required this.message,
    required this.emotes,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(
        children: buildCommentSpans(
          message: message,
          emotes: emotes,
          style: style,
          context: context,
        ),
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// 把正文按 emote 正则切分，[表情] 原位替换为表情图片 WidgetSpan。
/// 同时把正文中的链接渲染为蓝色可点击「蓝链」（点击在内置浏览器中打开）。
List<InlineSpan> buildCommentSpans({
  required String message,
  required Map<String, BiliCommentEmote> emotes,
  TextStyle? style,
  BuildContext? context,
}) {
  if (message.isEmpty) return const [];
  if (emotes.isEmpty) {
    return _linkAwareSpans(message, style: style, context: context);
  }
  final pattern = RegExp(emotes.keys.map(RegExp.escape).join('|'));
  final spans = <InlineSpan>[];
  var lastEnd = 0;
  for (final m in pattern.allMatches(message)) {
    if (m.start > lastEnd) {
      spans.addAll(
        _linkAwareSpans(
          message.substring(lastEnd, m.start),
          style: style,
          context: context,
        ),
      );
    }
    final key = m[0]!;
    final emote = emotes[key];
    if (emote == null) {
      spans.add(TextSpan(text: key, style: style));
    } else {
      final size = (emote.size <= 0 ? 2 : emote.size).clamp(1, 3) * 20.0;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Image(
            image: CachedImageProvider(
              BilibiliCommentService.emoteUrl(emote.url, size: size.toInt()),
              headers: _imageHeaders(),
            ),
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(key, style: style),
          ),
        ),
      );
    }
    lastEnd = m.end;
  }
  if (lastEnd < message.length) {
    spans.addAll(
      _linkAwareSpans(
        message.substring(lastEnd),
        style: style,
        context: context,
      ),
    );
  }
  return spans;
}

/// 把一段纯文本中的链接拆成蓝色可点击的 TextSpan（蓝链），
/// 点击后在内置浏览器中打开；[context] 为空时仅上色不可点击。
List<InlineSpan> _linkAwareSpans(
  String text, {
  TextStyle? style,
  BuildContext? context,
}) {
  final matches = linkPattern.allMatches(text);
  if (matches.isEmpty) return [TextSpan(text: text, style: style)];
  final spans = <InlineSpan>[];
  var lastEnd = 0;
  for (final m in matches) {
    if (m.start > lastEnd) {
      spans.add(TextSpan(text: text.substring(lastEnd, m.start), style: style));
    }
    final raw = m[0]!;
    final url = normalizeLink(raw);
    final linkStyle = (style ?? const TextStyle()).copyWith(
      color: const Color(0xFF23ADE5),
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFF23ADE5),
      fontWeight: FontWeight.w500,
    );
    if (context != null) {
      spans.add(
        TextSpan(
          text: raw,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => openBiliLinkInApp(context, url: url),
        ),
      );
    } else {
      spans.add(TextSpan(text: raw, style: linkStyle));
    }
    lastEnd = m.end;
  }
  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd), style: style));
  }
  return spans;
}

/// 评论区配图缩略图行：按原图比例裁出固定高度缩略图，点击查看大图。
class CommentPictures extends StatelessWidget {
  final List<BiliCommentPicture> pictures;

  const CommentPictures({super.key, required this.pictures});

  static const double _thumbHeight = 96;
  static const double _thumbMaxWidth = 220;

  @override
  Widget build(BuildContext context) {
    if (pictures.isEmpty) return const SizedBox.shrink();
    final list = pictures.take(4).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final pic in list) _CommentPicThumb(picture: pic)],
      ),
    );
  }
}

class _CommentPicThumb extends StatefulWidget {
  final BiliCommentPicture picture;

  const _CommentPicThumb({required this.picture});

  @override
  State<_CommentPicThumb> createState() => _CommentPicThumbState();
}

class _CommentPicThumbState extends State<_CommentPicThumb> {
  bool _downloading = false;
  // 每个缩略图独立 Hero tag（同图出现在多条评论时避免 tag 冲突）
  static int _heroSeq = 0;
  late final String _heroTag =
      'comment_pic_${_p.src.hashCode}_${_heroSeq++}';

  BiliCommentPicture get _p => widget.picture;

  /// 缩略图宽度：按原图比例换算（48 ~ 220px）。
  double _thumbWidth() {
    final w = _p.width > 0 ? _p.width.toDouble() : 1.0;
    final h = _p.height > 0 ? _p.height.toDouble() : 1.0;
    final ratio = (h / w).clamp(0.5, 3.0);
    return (CommentPictures._thumbHeight / ratio).clamp(
      48.0,
      CommentPictures._thumbMaxWidth,
    );
  }

  /// 缩略图本体（配合 B 站 1c 居中裁剪）；外层按需包 Hero。
  Widget _buildPicImage(ColorScheme cs) {
    final image = Image(
      image: CachedImageProvider(
        '${_p.src}@${_thumbWidth().round()}w_'
        '${CommentPictures._thumbHeight.round()}h_1c.webp',
        headers: _imageHeaders(),
      ),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => Icon(
        Icons.image_outlined,
        size: 28,
        color: cs.onSurfaceVariant.withOpacity(0.4),
      ),
    );
    if (SettingsService.heroTransitionBlurEnabled) return image;
    return Hero(tag: _heroTag, child: image);
  }

  /// 下载原图并进入大图查看器。
  Future<void> _openViewer(BuildContext context) async {
    if (_downloading) return;
    HapticFeedback.lightImpact();
    setState(() => _downloading = true);
    final bytes = await BilibiliCommentService.fetchBytes(_p.src);
    if (!mounted) return;
    setState(() => _downloading = false);
    if (bytes == null) {
      showAppToast(
        context,
        AppLocalizations.of(context).commentImageLoadFail,
        error: true,
      );
      return;
    }
    await Navigator.of(context).push(
      heroTransitionRoute(
        page: ImageViewerPage(
          imageBytes: bytes,
          heroTag: _heroTag,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 长按 → 居中预览（模糊背景 + 飞行动画）；点击 → 大图查看器
    return LongPressImagePreview(
      imageUrl: _p.src,
      child: GestureDetector(
        onTap: () => _openViewer(context),
        child: Container(
          width: _thumbWidth(),
          height: CommentPictures._thumbHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero 与查看器同 tag 飞入；BoxFit.cover + center 让过长的图片
              // 只显示中间一段（配合 B 站 1c 居中裁剪缩略图）。
              // 开启「Hero 转场背景模糊」时评论区位于视频页整页 Hero 之内，
              // 嵌套 Hero 会触发 Flutter 断言（Hero 不能嵌套 Hero），
              // 此时不包裹 Hero，查看器只使用普通转场。
              _buildPicImage(cs),
              if (_downloading)
                ColoredBox(
                  color: Colors.black38,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
