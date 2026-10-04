                                
  
                                  
                                                                
                                               
                                    
                           
                                     
                                        
                                            
                         
                          
                   
                              
                 
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassQuality;

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/screens/image_viewer_page.dart';
import 'package:naviflash/services/bili_uri_router.dart';
import 'package:naviflash/services/bilibili_comment_service.dart';
import 'package:naviflash/services/bilibili_im_service.dart';
import 'package:naviflash/services/bv_av.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_zoom_hero.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/msg_feed_common.dart';
import 'package:naviflash/widgets/ugc_rich_text.dart';

                                  
Map<String, String>? _imageHeaders() {
  try {
    final headers = NetworkSettingsService.instance.apiHeaders;
    return headers.isEmpty ? null : headers;
  } catch (_) {
    return null;
  }
}

String _str(dynamic v) => v?.toString() ?? '';

double _num(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('${v ?? ''}') ?? 0;
}

                                       
String _fixUrl(String url) {
  final t = url.trim();
  if (t.isEmpty) return '';
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  if (t.startsWith('//')) return 'https:$t';
  return 'https://$t';
}

                                  
String _formatDuration(int seconds) {
  if (seconds <= 0) return '--:--';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

                      
class ImChatItem extends StatelessWidget {
                                               
  static const double _bubbleMaxWidth = 340;

               
  static const double _cardMaxWidth = 420;

  final BiliImMessage msg;
  final bool isOwner;

                                      
  final Map<String, BiliCommentEmote> emotes;

                       
  final VoidCallback? onLongPress;

  const ImChatItem({
    super.key,
    required this.msg,
    required this.isOwner,
    this.emotes = const {},
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = msg.msgType;

                         
    if (type == ImMsgType.tipMessage) {
      return _centeredHint(context, BilibiliImService.tipText(msg.content));
    }
    if (type == ImMsgType.withdraw) {
      return _centeredHint(
        context,
        isOwner ? l10n.msgWithdrawnSelf : l10n.msgWithdrawnOther,
      );
    }

                    
    if (ImMsgType.isCard(type)) {
      final Widget? card = switch (type) {
        ImMsgType.notify => _notifyCard(context),
        ImMsgType.videoCard => _videoCard(context),
        ImMsgType.pictureCard => _pictureCard(context),
        ImMsgType.specialCard => _specialCard(context),
        _ => null,
      };
      if (card != null) {
        return _cardWrap(context, card, flush: type == ImMsgType.pictureCard);
      }
    }

                       
    final isPic = type == ImMsgType.picture || type == ImMsgType.customFace;
    return _bubble(context, content: _bubbleContent(context), isPic: isPic);
  }

                                             
               
                                             

                                           
     
                                                 
                                   
                                            
  Widget _glassShell(
    BuildContext context, {
    required double radius,
    required bool accent,
    required EdgeInsetsGeometry padding,
    required Color solidColor,
    required Widget child,
  }) {
    final body = Padding(padding: padding, child: child);
    if (!SettingsService.chatGlassEnabled) {
      return Container(
        decoration: BoxDecoration(
          color: solidColor,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: body,
      );
    }
    return NaviGlass(
      radius: radius,
      blur: 12,
      lightIntensity: 0.2,
      tintOpacity: accent ? 0.14 : 0.08,
      quality: GlassQuality.minimal,
      shadowElevation: 0,
      child: body,
    );
  }

  Widget _bubble(
    BuildContext context, {
    required Widget content,
    bool isPic = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final bubbleColor = isOwner ? cs.primaryContainer : cs.surfaceContainerHigh;
    final textColor = isOwner ? cs.onPrimaryContainer : cs.onSurface;
    final autoReply = msg.msgSource >= 8 && msg.msgSource <= 11;
    return Row(
      mainAxisAlignment: isOwner
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Flexible(
          child: GestureDetector(
            onLongPress: onLongPress,
            onSecondaryTap: onLongPress,
            child: Container(
              constraints: const BoxConstraints(maxWidth: _bubbleMaxWidth),
                                             
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isOwner ? 16 : 6),
                  bottomRight: Radius.circular(isOwner ? 6 : 16),
                ),
              ),
              child: _glassShell(
                context,
                radius: 16,
                accent: isOwner,
                padding: isPic
                    ? const EdgeInsets.fromLTRB(8, 8, 8, 6)
                    : const EdgeInsets.fromLTRB(12, 9, 12, 6),
                solidColor: bubbleColor,
                child: Column(
                  crossAxisAlignment: isOwner
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    content,
                    if (msg.msgStatus == 1) ...[
                      const SizedBox(height: 3),
                      Text(
                        l10n.msgWithdrawn,
                        style: TextStyle(fontSize: 11, color: cs.error),
                      ),
                    ],
                    if (autoReply) ...[
                      const SizedBox(height: 6),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: cs.outline.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.msgAutoReply,
                        style: TextStyle(fontSize: 10, color: cs.outline),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      formatMsgTime(msg.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: textColor.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cardWrap(BuildContext context, Widget card, {bool flush = false}) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _cardMaxWidth),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _glassShell(
                context,
                radius: 14,
                accent: false,
                padding: flush ? EdgeInsets.zero : const EdgeInsets.all(12),
                solidColor: cs.surfaceContainerHigh.withValues(alpha: 0.7),
                child: card,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatMsgTime(msg.timestamp),
          style: TextStyle(fontSize: 10, color: cs.outline),
        ),
      ],
    );
  }

  Widget _centeredHint(BuildContext context, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            formatMsgTime(msg.timestamp),
            style: TextStyle(fontSize: 10, color: cs.outline),
          ),
        ],
      ),
    );
  }

                                             
          
                                             

  Color _textColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return isOwner ? cs.onPrimaryContainer : cs.onSurface;
  }

  Widget _bubbleContent(BuildContext context) {
    final textColor = _textColor(context);
    switch (msg.msgType) {
      case ImMsgType.picture:
      case ImMsgType.customFace:
        return _picture(context);
      case ImMsgType.voice:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context).msgVoice,
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ],
        );
      case ImMsgType.share:
        return _shareV2Card(context, textColor);
      case ImMsgType.articleCard:
        return _articleCard(context, textColor);
      case ImMsgType.commonShareCard:
        return _commonShareCard(context, textColor);
      default:
        return _textContent(context, textColor);
    }
  }

  Widget _textContent(BuildContext context, Color textColor) {
    final l10n = AppLocalizations.of(context);
    final decoded = BilibiliImService.decodeContent(msg.content);
    String text = '';
    if (decoded is Map) {
      text = _str(decoded['content']);
      if (text.isEmpty) text = _str(decoded['title']);
    } else if (decoded is String) {
      text = decoded;
    }
    if (text.isEmpty) {
      return Text(
        l10n.msgUnsupportedType('${msg.msgType}'),
        style: TextStyle(fontSize: 14, color: textColor),
      );
    }
    return UgcRichText(
      text: text,
      emotes: emotes,
      style: TextStyle(fontSize: 14, color: textColor, height: 1.35),
    );
  }

  Widget _picture(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor = _textColor(context);
    final map = BilibiliImService.contentMap(msg.content);
    final url = _fixUrl(_str(map['url']));
    if (url.isEmpty) {
      return Text(
        l10n.msgPictureFailed,
        style: TextStyle(fontSize: 14, color: textColor),
      );
    }
    final w = _num(map['width']);
    final h = _num(map['height']);
    const maxWidth = 220.0;
    const maxHeight = 300.0;
                                         
                                           
    final width = w > 0 && h > 0 ? math.min(maxWidth, w) : maxWidth;
    final height = w > 0 && h > 0
        ? math.min(width * h / w, maxHeight)
        : maxHeight;
    final tag = 'im_pic_${msg.msgSeqno}_${msg.msgKey}';
    final image = Image(
      image: CachedImageProvider(url, headers: _imageHeaders(), cacheWidth: 720),
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(
          l10n.msgPictureFailed,
          style: TextStyle(fontSize: 12, color: textColor),
        ),
      ),
    );
    return GestureDetector(
      onTap: () => _openViewer(context, url, tag),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _maybeHero(context, tag, image),
      ),
    );
  }

                                             
               
                                             

                                   
  Widget _shareV2Card(BuildContext context, Color textColor) {
    final l10n = AppLocalizations.of(context);
    final map = BilibiliImService.contentMap(msg.content);
    final source = map['source'];
    final intSource = source is num
        ? source.toInt()
        : int.tryParse('$source') ?? -1;
    final id = _str(map['id']);
    final bvid = _str(map['bvid']);
    final thumb = _fixUrl(_str(map['thumb']));
    final title = _str(map['title']);
    final author = _str(map['author']);
    final headline = _str(map['headline']);

    String? typeLabel;
    VoidCallback? onTap;
    switch (intSource) {
      case 2:
        typeLabel = l10n.msgCardAlbum;
        onTap = () => pushDynamic(context, id);
      case 5:
        typeLabel = l10n.msgCardVideo;
        onTap = () {
          if (bvid.isNotEmpty) {
            openBilibiliVideo(
              context,
              bvid: bvid,
              initialTitle: title,
              initialCover: thumb,
            );
            return;
          }
          final aid = int.tryParse(id);
          final bv = aid == null ? null : BvAv.encode(aid);
          if (bv != null) {
            openBilibiliVideo(
              context,
              bvid: bv,
              initialTitle: title,
              initialCover: thumb,
            );
          }
        };
      case 6:
        typeLabel = l10n.msgCardArticle;
        onTap = () {
          final cvid = int.tryParse(id);
          if (cvid != null) pushArticle(context, cvid);
        };
      case 11:
        typeLabel = l10n.msgCardDynamic;
        onTap = () => pushDynamic(context, id);
      case 16:
        onTap = () =>
            openBiliUri(context, 'https://www.bilibili.com/bangumi/play/ep$id');
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thumb.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image(
                image: CachedImageProvider(thumb, headers: _imageHeaders()),
                width: 220,
                height: 123.75,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 220,
                  height: 123.75,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          if (thumb.isNotEmpty) const SizedBox(height: 6),
          Text(
            title.isEmpty ? l10n.msgShare : title,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (intSource == 6 && headline.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              headline,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (author.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              typeLabel == null ? author : '$author · $typeLabel',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

                           
  Widget _articleCard(BuildContext context, Color textColor) {
    final map = BilibiliImService.contentMap(msg.content);
    final rid = int.tryParse(_str(map['rid']));
    final title = _str(map['title']);
    final summary = _str(map['summary']);
    final rawImages = map['image_urls'];
    final images = rawImages is List
        ? rawImages.whereType<String>().take(2).toList(growable: false)
        : const <String>[];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: rid == null ? null : () => pushArticle(context, rid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < images.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Image(
                      image: CachedImageProvider(
                        _fixUrl(images[i]),
                        headers: _imageHeaders(),
                      ),
                      width: 148,
                      height: 83,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 148,
                        height: 83,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (images.isNotEmpty) const SizedBox(height: 6),
          Text(
            title.isEmpty ? AppLocalizations.of(context).msgCardArticle : title,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

                    
  Widget _commonShareCard(BuildContext context, Color textColor) {
    final l10n = AppLocalizations.of(context);
    final map = BilibiliImService.contentMap(msg.content);
    final source = _str(map['source']);
    final isLive = source == '直播' || source.toLowerCase() == 'live';
    if (!isLive) return _textContent(context, textColor);
    final roomId = int.tryParse(_str(map['sourceID'])) ?? 0;
    final cover = _fixUrl(_str(map['cover']));
    final title = _str(map['title']);
    final author = _str(map['author']);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: roomId <= 0 ? null : () => pushLiveRoom(context, roomId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cover.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image(
                image: CachedImageProvider(cover, headers: _imageHeaders()),
                width: 220,
                height: 123.75,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 220,
                  height: 123.75,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          if (cover.isNotEmpty) const SizedBox(height: 6),
          Text(
            title.isEmpty ? l10n.msgCardLive : title,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (author.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '$author · ${l10n.msgCardLive}',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

                                             
            
                                             

                                
  Widget _videoCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final map = BilibiliImService.contentMap(msg.content);
    final bvid = _str(map['bvid']);
    final cover = _fixUrl(_str(map['cover']));
    final title = _str(map['title']);
    final times = map['times'] is num ? (map['times'] as num).toInt() : 0;
    final attach = map['attach_msg'];
    final attachText = attach is Map ? _str(attach['content']) : '';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: bvid.isEmpty
          ? null
          : () => openBilibiliVideo(
              context,
              bvid: bvid,
              initialTitle: title,
              initialCover: cover,
            ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: cover.isEmpty
                        ? Container(
                            width: width,
                            height: width * 9 / 16,
                            color: cs.surfaceContainerHighest,
                          )
                        : Image(
                            image: CachedImageProvider(
                              cover,
                              headers: _imageHeaders(),
                            ),
                            width: width,
                            height: width * 9 / 16,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: width,
                              height: width * 9 / 16,
                              color: cs.surfaceContainerHighest,
                            ),
                          ),
                  ),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(times),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                times == 0
                    ? l10n.msgCardInvalid
                    : (title.isEmpty ? l10n.msgCardVideo : title),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (attachText.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: UgcRichText(
                    text: attachText,
                    emotes: emotes,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: cs.onSurface,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

                                   
  Widget _pictureCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final map = BilibiliImService.contentMap(msg.content);
    final pic = _fixUrl(_str(map['pic_url']));
    final jump = _str(map['jump_url']);
    if (pic.isEmpty) {
      return Text(
        l10n.msgPictureFailed,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    final tag = 'im_card_${msg.msgSeqno}_${msg.msgKey}';
    return GestureDetector(
      onTap: () {
        if (jump.isNotEmpty) {
          openBiliUri(context, jump);
        } else {
          _openViewer(context, pic, tag);
        }
      },
                                            
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _cardMaxWidth,
          maxHeight: 460,
        ),
        child: _maybeHero(
          context,
          tag,
          Image(
            image: CachedImageProvider(pic, headers: _imageHeaders(), cacheWidth: 720),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.msgPictureFailed,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

                         
  Widget _specialCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final map = BilibiliImService.contentMap(msg.content);
    final mainTitle = _str(map['main_title']);
    final subCards = BilibiliImService.contentList(map['sub_cards']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mainTitle.isNotEmpty)
          Text(
            mainTitle,
            style: TextStyle(
              fontSize: 15,
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        for (final card in subCards)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => openBiliUri(context, _str(card['jump_url'])),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image(
                      image: CachedImageProvider(
                        _fixUrl(_str(card['cover_url'])),
                        headers: _imageHeaders(),
                      ),
                      width: 120,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120,
                        height: 68,
                        color: cs.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _str(card['field1']),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_str(card['field2']).isNotEmpty)
                          Text(
                            _str(card['field2']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        if (_str(card['field3']).isNotEmpty)
                          Text(
                            _str(card['field3']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

                                   
  Widget _notifyCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final map = BilibiliImService.contentMap(msg.content);
    final title = _str(map['title']);
    final text = _str(map['text']);
    final modules = BilibiliImService.contentList(map['modules']);
    final jumps = <({String uri, String label})>[];
    for (final suffix in const ['', '_2', '_3']) {
      final uri = _str(map['jump_uri$suffix']);
      if (uri.isEmpty) continue;
      final label = _str(map['jump_text$suffix']);
      jumps.add((
        uri: uri,
        label: label.isEmpty ? l10n.msgCardViewDetail : label,
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Divider(
            height: 14,
            thickness: 1,
            color: cs.primary.withValues(alpha: 0.05),
          ),
        ],
        if (text.isNotEmpty)
          Text(
            text,
            style: TextStyle(fontSize: 13, height: 1.4, color: cs.onSurface),
          ),
        for (final module in modules)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    _str(module['title']),
                    style: TextStyle(fontSize: 13, color: cs.outline),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _str(module['detail']),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        for (final jump in jumps)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => openBiliUri(context, jump.uri),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                jump.label,
                style: TextStyle(fontSize: 13, color: cs.primary),
              ),
            ),
          ),
      ],
    );
  }

                                             
          
                                             

  void _openViewer(BuildContext context, String url, String tag) {
    Navigator.of(context).push(
      heroTransitionRoute(
        heroZoom: true,
        page: ImageViewerPage(imageUrl: url, heroTag: tag),
      ),
    );
  }

                                                  
  Widget _maybeHero(BuildContext context, String tag, Widget child) {
    if (ZoomHeroScope.activeOf(context)) return child;
    return Hero(tag: tag, transitionOnUserGestures: true, child: child);
  }
}
