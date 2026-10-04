                                        
  
                                                 
                                                              
                                        
                                            
                                                          
                          
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:naviflash/services/bilibili_article_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/long_press_image_preview.dart';

                           
const String _kBr = '\u2028';

                                               
String articleImageHeroTag(String url) => 'article_img_${url.hashCode}';

                                                      
String articleCoverHeroTag(String url) => 'article_cover_${url.hashCode}';

                                           
class ArticleContentBody extends StatefulWidget {
                      
  final String? html;

                       
  final List<BiliArticleOps>? ops;

                         
  final List<String> allImages;

                           
  final Future<void> Function(String url, List<String> allImages) onImageTap;

              
  final void Function(String url) onLinkTap;

                                       
                                          
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
                             
  final List<GestureRecognizer> _recognizers = [];

                   
                                                     
                     
  final Map<dom.Element, String?> _htmlHeroTags = {};
  final List<String?> _opsHeroTags = [];

  @override
  void initState() {
    super.initState();
    _computeHeroTags();
  }

                                           
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
                           
          return const [];
        default:
                         
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
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: cs.primary.withValues(alpha: 0.6), width: 3),
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
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
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

                                             
                                                           
  Widget _buildImage(BuildContext context, String src, {String? heroTag}) {
    final cs = Theme.of(context).colorScheme;
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
                                                    
                               
    final image = Image(
      image: CachedImageProvider(src, headers: headers, cacheWidth: 1440),
      width: double.infinity,
      fit: BoxFit.fitWidth,
      errorBuilder: (_, __, ___) => Container(
        height: 120,
        alignment: Alignment.center,
        color: cs.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image_outlined,
          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
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
              Hero(transitionOnUserGestures: true, tag: heroTag, child: image)
            else
              image,
                                                        
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
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
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

                             
  List<InlineSpan> _wrapped(dom.Element el, TextStyle style) {
    return [TextSpan(style: style, children: _buildInline(context, el))];
  }

                                          
        
                                          

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
