// lib/widgets/article_content_view.dart
//
// article_ops.dart，按本项目风格纯 Flutter 渲染，无额外富文本依赖）：
//   - HTML 正文（type=1）：用 package:html 解析 DOM，递归转换为 Flutter 组件，
//     支持段落/标题/列表/引用/代码块/表格/图片/超链接 等常见标签
//   - JSON 富文本（type=3）：渲染 ops 段落（文本 + 图片卡片）
//   - 图片点击全屏查看（[onImageTap]），长按预览复用 LongPressImagePreview
//   - 超链接点击回调 [onLinkTap]
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:naviflash/services/bilibili_article_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/long_press_image_preview.dart';

/// 段落内换行标记（<br> / 文本里的换行）。
const String _kBr = '\u2028';

/// 文章正文图片 Hero 标签（基于 URL：源缩略图与查看器用同名标签触发飞入动画）。
String articleImageHeroTag(String url) => 'article_img_${url.hashCode}';

/// 文章封面图 Hero 标签（与正文用不同前缀，避免封面/正文同一 URL 时 Hero 标签冲突）。
String articleCoverHeroTag(String url) => 'article_cover_${url.hashCode}';

/// 文章正文内容（HTML 或 JSON ops 二选一），统一转成一组块级组件。
class ArticleContentBody extends StatefulWidget {
  /// HTML 正文（type=1）。
  final String? html;

  /// JSON 富文本（type=3）。
  final List<BiliArticleOps>? ops;

  /// 文章全部图片（供大图查看器横向切换）。
  final List<String> allImages;

  /// 点击正文图片：回调图片地址与全部图片列表。
  final Future<void> Function(String url, List<String> allImages) onImageTap;

  /// 点击正文超链接。
  final void Function(String url) onLinkTap;

  /// 禁用正文图片 Hero 包裹（整页放大飞行期间外层已包 Hero，
  /// 内层再包会触发「Hero 嵌套 Hero」断言，与相关视频页同款处理）。
  final bool heroTagsDisabled;

  const ArticleContentBody({
    super.key,
    this.html,
    this.ops,
    this.allImages = const [],
    required this.onImageTap,
    required this.onLinkTap,
    this.heroTagsDisabled = false,
  });

  @override
  State<ArticleContentBody> createState() => _ArticleContentBodyState();
}

class _ArticleContentBodyState extends State<ArticleContentBody> {
  /// 收集本次构建创建的链接识别器，重建前统一销毁。
  final List<GestureRecognizer> _recognizers = [];

  /// 预计算的 Hero 标签：
  ///   - HTML 正文按元素记录（同一 URL 只给首次出现的元素加 Hero，避免同名冲突）
  ///   - ops 按段落下标记录
  final Map<dom.Element, String?> _htmlHeroTags = {};
  final List<String?> _opsHeroTags = [];

  @override
  void initState() {
    super.initState();
    _computeHeroTags();
  }

  /// 在 initState 中一次性计算（稳定，不随 rebuild 变化）。
  void _computeHeroTags() {
    _htmlHeroTags.clear();
    _opsHeroTags.clear();
    final html = widget.html;
    if (html != null && html.trim().isNotEmpty) {
      final doc = html_parser.parse(html);
      final seen = <String>{};
      for (final child in doc.body?.children ?? const <dom.Element>[]) {
        dom.Element? img;
        if (child.localName == 'img') {
          img = child;
        } else if (child.localName == 'figure') {
          img = child.querySelector('img');
        }
        if (img == null) continue;
        final src = _imgSrc(img);
        if (src == null) continue;
        _htmlHeroTags[img] = seen.add(src) ? articleImageHeroTag(src) : null;
      }
    }
    final ops = widget.ops;
    if (ops != null) {
      final seen = <String>{};
      for (final op in ops) {
        final src = op.cardImage;
        _opsHeroTags.add(
          src != null && seen.add(src) ? articleImageHeroTag(src) : null,
        );
      }
    }
  }

  void _resetRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer _linkRecognizer(VoidCallback onTap) {
    final r = TapGestureRecognizer()..onTap = onTap;
    _recognizers.add(r);
    return r;
  }

  @override
  void dispose() {
    _resetRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _resetRecognizers();
    final ops = widget.ops;
    if (ops != null && ops.isNotEmpty) {
      return _buildOps(context, ops);
    }
    final html = widget.html;
    if (html == null || html.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final doc = html_parser.parse(html);
    final children = doc.body?.children ?? const <dom.Element>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final node in children) ..._buildBlocks(context, node)],
    );
  }

  // ═════════════════════════════════════
  //  块级转换
  // ═════════════════════════════════════

  /// 把节点转成 0..n 个块级组件（容器标签会递归展开）。
  List<Widget> _buildBlocks(BuildContext context, dom.Node node) {
    if (node is dom.Element) {
      switch (node.localName) {
        case 'p':
        case 'div':
        case 'section':
        case 'article':
        case 'main':
        case 'header':
        case 'footer':
        case 'span':
        case 'font':
        case 'center':
          return [_buildParagraph(context, node)];
        case 'br':
          return const [SizedBox(height: 8)];
        case 'hr':
          return [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ];
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
        case 'h5':
        case 'h6':
          return [_buildHeading(context, node)];
        case 'ul':
        case 'ol':
          return [_buildList(context, node, ordered: node.localName == 'ol')];
        case 'blockquote':
          return [_buildBlockquote(context, node)];
        case 'figure':
          return [_buildFigure(context, node)];
        case 'figcaption':
          return [_buildFigcaption(context, node)];
        case 'img':
          final src = _imgSrc(node);
          if (src == null) return const [];
          return [_buildImage(context, src, heroTag: _htmlHeroTags[node])];
        case 'pre':
          return [_buildPre(context, node)];
        case 'table':
          return [_buildTable(context, node)];
        case 'audio':
        case 'video':
        case 'iframe':
        case 'script':
        case 'style':
        case 'noscript':
        case 'template':
          // 音视频/脚本不渲染，避免误触
          return const [];
        default:
          // 未知标签：递归处理子节点
          return [
            for (final child in node.nodes) ..._buildBlocks(context, child),
          ];
      }
    }
    if (node is dom.Text) {
      final text = node.text.trim();
      if (text.isEmpty) return const [];
      return [_buildParagraph(context, node)];
    }
    return const [];
  }

  /// 段落（可含内联元素）。
  Widget _buildParagraph(BuildContext context, dom.Node node) {
    final cs = Theme.of(context).colorScheme;
    final spans = _buildInline(context, node);
    if (spans.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: _blockAlign(node),
        style: TextStyle(
          fontSize: 16,
          height: 1.75,
          letterSpacing: 0.3,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _buildHeading(BuildContext context, dom.Element el) {
    final cs = Theme.of(context).colorScheme;
    final level = int.tryParse(el.localName!.substring(1)) ?? 1;
    const sizes = [22.0, 20.0, 18.0, 17.0, 16.0, 15.0];
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text.rich(
        TextSpan(children: _buildInline(context, el)),
        textAlign: _blockAlign(el),
        style: TextStyle(
          fontSize: sizes[level - 1],
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    dom.Element el, {
    required bool ordered,
  }) {
    final items = el.children.where((c) => c.localName == 'li').toList();
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text.rich(
          TextSpan(children: _buildInline(context, el)),
          style: const TextStyle(fontSize: 16, height: 1.75),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            _buildListItem(context, items[i], ordered: ordered, index: i),
        ],
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    dom.Element li, {
    required bool ordered,
    required int index,
  }) {
    final cs = Theme.of(context).colorScheme;
    final marker = ordered ? '${index + 1}. ' : '• ';
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              marker,
              style: TextStyle(fontSize: 16, height: 1.75, color: cs.primary),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(children: _buildInline(context, li)),
              style: TextStyle(fontSize: 16, height: 1.75, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockquote(BuildContext context, dom.Element el) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: cs.primary.withOpacity(0.6), width: 3),
        ),
      ),
      child: Text.rich(
        TextSpan(children: _buildInline(context, el)),
        style: TextStyle(
          fontSize: 15,
          height: 1.7,
          color: cs.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildFigure(BuildContext context, dom.Element el) {
    final img = el.querySelector('img');
    final src = img == null ? null : _imgSrc(img);
    final caption = el.querySelector('figcaption');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (src != null)
            _buildImage(context, src, heroTag: _htmlHeroTags[img]),
          if (caption != null) _buildFigcaption(context, caption),
        ],
      ),
    );
  }

  Widget _buildFigcaption(BuildContext context, dom.Element el) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text.rich(
        TextSpan(children: _buildInline(context, el)),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
      ),
    );
  }

  Widget _buildPre(BuildContext context, dom.Element el) {
    final cs = Theme.of(context).colorScheme;
    final codeEl = el.querySelector('code');
    final text = (codeEl ?? el).text;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.5,
            color: cs.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, dom.Element el) {
    final cs = Theme.of(context).colorScheme;
    final rows = el.children.where((c) => c.localName == 'tr').toList();
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text.rich(
          TextSpan(children: _buildInline(context, el)),
          style: const TextStyle(fontSize: 16, height: 1.75),
        ),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final row in rows) _buildTableRow(context, row)],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, dom.Element tr) {
    final cs = Theme.of(context).colorScheme;
    final cells = tr.children
        .where((c) => c.localName == 'td' || c.localName == 'th')
        .toList();
    if (cells.isEmpty) {
      return Text.rich(TextSpan(children: _buildInline(context, tr)));
    }
    final isHeader = tr.parent?.localName == 'thead';
    return Container(
      decoration: BoxDecoration(
        color: isHeader ? cs.surfaceContainerHighest : null,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : Border(left: BorderSide(color: cs.outlineVariant)),
                ),
                child: Text.rich(
                  TextSpan(children: _buildInline(context, cells[i])),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: isHeader ? FontWeight.w600 : null,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 图片组件：Hero 飞入 + 点击 ripple → 全屏查看，长按放大预览。
  /// [heroTag] 为 null 时不加 Hero（重复 URL / 内联图），避免同名 Hero 冲突。
  Widget _buildImage(BuildContext context, String src, {String? heroTag}) {
    final cs = Theme.of(context).colorScheme;
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    // 走 CachedImageProvider（内存 → 磁盘 → 网络）：正文图片落盘缓存，
    // 下次查看直接从本地读，设置页「清理缓存」可清除。
    final image = Image(
      image: CachedImageProvider(src, headers: headers),
      width: double.infinity,
      fit: BoxFit.fitWidth,
      errorBuilder: (_, __, ___) => Container(
        height: 120,
        alignment: Alignment.center,
        color: cs.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image_outlined,
          color: cs.onSurfaceVariant.withOpacity(0.4),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LongPressImagePreview(
        imageUrl: src,
        child: Stack(
          children: [
            if (heroTag != null && !widget.heroTagsDisabled)
              Hero(tag: heroTag, child: image)
            else
              image,
            // 透明 Material + InkWell 覆盖层：点击时在图上显示 ripple
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.onImageTap(src, widget.allImages),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════
  //  内联转换
  // ═════════════════════════════════════

  List<InlineSpan> _buildInline(BuildContext context, dom.Node node) {
    final spans = <InlineSpan>[];
    for (final child in node.nodes) {
      if (child is dom.Text) {
        final text = child.text.replaceAll('\n', _kBr);
        if (text.isNotEmpty) {
          spans.add(TextSpan(text: text));
        }
      } else if (child is dom.Element) {
        spans.addAll(_buildInlineElement(context, child));
      }
    }
    return spans;
  }

  List<InlineSpan> _buildInlineElement(BuildContext context, dom.Element el) {
    final cs = Theme.of(context).colorScheme;
    switch (el.localName) {
      case 'b':
      case 'strong':
        return _wrapped(el, const TextStyle(fontWeight: FontWeight.w700));
      case 'i':
      case 'em':
        return _wrapped(el, const TextStyle(fontStyle: FontStyle.italic));
      case 'u':
        return _wrapped(
          el,
          const TextStyle(decoration: TextDecoration.underline),
        );
      case 's':
      case 'del':
      case 'strike':
        return _wrapped(
          el,
          const TextStyle(decoration: TextDecoration.lineThrough),
        );
      case 'code':
        return _wrapped(
          el,
          TextStyle(
            fontFamily: 'monospace',
            fontSize: 13.5,
            color: cs.primary,
            backgroundColor: cs.surfaceContainerHighest.withOpacity(0.6),
          ),
        );
      case 'mark':
        return _wrapped(el, TextStyle(backgroundColor: cs.tertiaryContainer));
      case 'small':
        return _wrapped(el, const TextStyle(fontSize: 13));
      case 'big':
        return _wrapped(el, const TextStyle(fontSize: 18));
      case 'sub':
      case 'sup':
        return [
          TextSpan(
            style: const TextStyle(fontSize: 11),
            children: _buildInline(context, el),
          ),
        ];
      case 'a':
        final href = el.attributes['href'] ?? '';
        if (href.isEmpty) return _buildInline(context, el);
        return [
          TextSpan(
            text: el.text,
            style: TextStyle(color: cs.primary),
            recognizer: _linkRecognizer(() {
              final url = href.startsWith('//') ? 'https:$href' : href;
              widget.onLinkTap(url);
            }),
          ),
        ];
      case 'img':
        final src = _imgSrc(el);
        if (src == null) return const [];
        return [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => widget.onImageTap(src, widget.allImages),
              child: _inlineImage(src),
            ),
          ),
        ];
      case 'br':
        return const [TextSpan(text: _kBr)];
      default:
        return _buildInline(context, el);
    }
  }

  /// 包一层样式再递归子节点（保持内联样式可叠加）。
  List<InlineSpan> _wrapped(dom.Element el, TextStyle style) {
    return [TextSpan(style: style, children: _buildInline(context, el))];
  }

  // ═════════════════════════════════════
  //  工具
  // ═════════════════════════════════════

  static String? _imgSrc(dom.Element el) {
    final raw =
        ((el.attributes['src'] ?? '').isNotEmpty
                ? el.attributes['src']
                : el.attributes['data-src'])
            ?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('//')) return 'https:$raw';
    return raw;
  }

  TextAlign? _blockAlign(dom.Node node) {
    if (node is! dom.Element) return null;
    final alignAttr = node.attributes['align'];
    if (alignAttr != null) {
      if (alignAttr.contains('center')) return TextAlign.center;
      if (alignAttr.contains('right')) return TextAlign.right;
      if (alignAttr.contains('justify')) return TextAlign.justify;
    }
    final style = node.attributes['style'] ?? '';
    final m = RegExp(r'text-align\s*:\s*([a-z]+)').firstMatch(style);
    if (m != null) {
      switch (m.group(1)) {
        case 'center':
          return TextAlign.center;
        case 'right':
          return TextAlign.right;
        case 'justify':
          return TextAlign.justify;
      }
    }
    return null;
  }

  Widget _inlineImage(String src) {
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    return Image(
      image: CachedImageProvider(src, headers: headers),
      height: 20,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  // ═════════════════════════════════════
  //  JSON ops 渲染（type=3）
  // ═════════════════════════════════════

  Widget _buildOps(BuildContext context, List<BiliArticleOps> ops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < ops.length; i++)
          _buildOp(context, ops[i], index: i),
      ],
    );
  }

  Widget _buildOp(
    BuildContext context,
    BiliArticleOps op, {
    required int index,
  }) {
    final cs = Theme.of(context).colorScheme;
    final insert = op.insert;
    if (insert is String) {
      final text = insert.trim();
      if (text.isEmpty) return const SizedBox(height: 6);
      final clazz = op.clazz;
      if (clazz.contains('title') ||
          clazz.contains('header') ||
          clazz.contains('h1') ||
          clazz.contains('h2') ||
          clazz.contains('h3')) {
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: cs.onSurface,
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(
          text,
          textAlign: clazz.contains('center') ? TextAlign.center : null,
          style: TextStyle(
            fontSize: 16,
            height: 1.75,
            letterSpacing: 0.3,
            color: cs.onSurface,
          ),
        ),
      );
    }
    final image = op.cardImage;
    if (image != null) {
      return _buildImage(
        context,
        image,
        heroTag: index < _opsHeroTags.length ? _opsHeroTags[index] : null,
      );
    }
    return const SizedBox.shrink();
  }
}
