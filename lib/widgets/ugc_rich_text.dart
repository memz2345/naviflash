                                 
                                         
                                             
                      
                                                      
                  
                                      
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:naviflash/screens/bilibili_search_page.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/services/bili_uri_router.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/link_utils.dart';
import 'package:naviflash/services/network_settings_service.dart';

                           
final RegExp ugcBvPattern = RegExp(r'[Bb][Vv]1[0-9A-Za-z]{9}');

         
final RegExp ugcAvPattern = RegExp(r'[Aa][Vv]\d+');

                                          
final RegExp ugcTimePattern = RegExp(
  r'(?:(?:\d{1,3})[:：])?\d{1,3}[:：]\d{1,2}',
);

                           
final RegExp ugcTopicPattern = RegExp(r'#[^#\s]{1,40}#');

                                    
int ugcParseDuration(String data) {
  final text = data.replaceAll('：', ':');
  final parts = text.split(':').reversed.toList();
  var seconds = 0;
  for (var i = 0; i < parts.length; i++) {
    final v = int.tryParse(parts[i].trim()) ?? 0;
    seconds += v * math.pow(60, i).toInt();
  }
  return seconds;
}

Map<String, String>? _imageHeaders() {
  try {
    final headers = NetworkSettingsService.instance.apiHeaders;
    return headers.isEmpty ? null : headers;
  } catch (_) {
    return null;
  }
}

                        
class UgcRichText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

                                
  final Map<String, BiliCommentEmote> emotes;

                              
  final void Function(Duration position)? onSeek;

                                     
  final Duration? maxSeekable;

                     
  final Color? accentColor;

  const UgcRichText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.emotes = const {},
    this.onSeek,
    this.maxSeekable,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(
        children: buildUgcSpans(
          text: text,
          style: style,
          emotes: emotes,
          context: context,
          onSeek: onSeek,
          maxSeekable: maxSeekable,
          accentColor: accentColor,
        ),
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

                                
List<InlineSpan> buildUgcSpans({
  required String text,
  TextStyle? style,
  Map<String, BiliCommentEmote> emotes = const {},
  BuildContext? context,
  void Function(Duration position)? onSeek,
  Duration? maxSeekable,
  Color? accentColor,
}) {
  if (text.isEmpty) return const [];
  final accent = accentColor ?? const Color(0xFF23ADE5);
  final linkStyle = (style ?? const TextStyle()).copyWith(
    color: accent,
    fontWeight: FontWeight.w500,
  );

  final tokens = <String>[
    ...emotes.keys.map(RegExp.escape),
    linkPattern.pattern,
    ugcBvPattern.pattern,
    ugcAvPattern.pattern,
    ugcTimePattern.pattern,
    ugcTopicPattern.pattern,
  ];
  final pattern = RegExp(tokens.join('|'), caseSensitive: false);
  final spans = <InlineSpan>[];

  void addPlain(String s) {
    if (s.isEmpty) return;
    spans.add(TextSpan(text: s, style: style));
  }

  void addTappable(String s, VoidCallback onTap, {TextStyle? tapStyle}) {
    if (context == null) {
      spans.add(TextSpan(text: s, style: tapStyle ?? style));
      return;
    }
    spans.add(
      TextSpan(
        text: s,
        style: tapStyle ?? linkStyle,
        recognizer: TapGestureRecognizer()..onTap = onTap,
      ),
    );
  }

  text.splitMapJoin(
    pattern,
    onMatch: (match) {
      final s = match[0]!;
           
      final emote = emotes[s];
      if (emote != null) {
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
              errorBuilder: (_, __, ___) => Text(s, style: style),
            ),
          ),
        );
        return '';
      }
                                             
      if (s.contains('.')) {
        final url = normalizeLink(s);
        addTappable(s, () => openBiliUri(context!, url));
        return '';
      }
             
      if (ugcBvPattern.hasMatch(s)) {
        final bv = s.toUpperCase().replaceFirst('BV', 'BV');
        addTappable(
          s,
          () => openBiliUri(context!, 'https://www.bilibili.com/video/$bv'),
        );
        return '';
      }
             
      if (ugcAvPattern.hasMatch(s)) {
        final av = s.toLowerCase();
        addTappable(
          s,
          () => openBiliUri(context!, 'https://www.bilibili.com/video/$av'),
        );
        return '';
      }
                  
      if (ugcTimePattern.hasMatch(s)) {
        final seconds = ugcParseDuration(s);
        final valid = onSeek != null &&
            seconds > 0 &&
            (maxSeekable == null ||
                seconds * 1000 <= maxSeekable.inMilliseconds);
        if (valid) {
          addTappable(
            s,
            () => onSeek(Duration(seconds: seconds)),
          );
        } else {
          addPlain(s);
        }
        return '';
      }
             
      if (ugcTopicPattern.hasMatch(s) && s.length > 2) {
        final topic = s.substring(1, s.length - 1);
        addTappable(
          s,
          () => Navigator.of(context!).push(
            MaterialPageRoute(
              builder: (_) => BilibiliSearchPage(
                initialKeyword: topic,
                recordInitialKeyword: false,
              ),
            ),
          ),
        );
        return '';
      }
      addPlain(s);
      return '';
    },
    onNonMatch: (s) {
      addPlain(s);
      return s;
    },
  );
  return spans;
}
