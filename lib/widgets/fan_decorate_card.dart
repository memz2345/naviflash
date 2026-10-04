                                     
  
                                  
  
                    
                                     
                                    
                                                                             
                                                                       
      
                                        
                                                            
                                                                            
                                                                        
  
                                    
                                                       
                                                                      
  
                                        
                                     

import 'package:flutter/material.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/app_tooltip.dart';

                                            
            
                                            

class BiliFanDecorate {
                      
  final String imageUrl;

                          
  final String name;

                    
  final bool isFan;

                       
  final int number;

                                     
  final String numDesc;

                    
  final String numPrefix;

                               
  final String colorHex;

                    
  final String jumpUrl;

  const BiliFanDecorate({
    this.imageUrl = '',
    this.name = '',
    this.isFan = false,
    this.number = 0,
    this.numDesc = '',
    this.numPrefix = '',
    this.colorHex = '',
    this.jumpUrl = '',
  });

  bool get isValid => imageUrl.isNotEmpty || numDesc.isNotEmpty;

                           
  String get numberText {
    final n = numDesc.isNotEmpty
        ? numDesc
        : (number > 0 ? number.toString() : '');
    if (n.isEmpty) return '';
    final p = numPrefix.isEmpty ? 'NO.' : numPrefix;
    return '$p$n';
  }

  Color get color => _parseHexColor(colorHex);

               
                                                                            
  static BiliFanDecorate? fromAny(dynamic raw) {
    final map = _asMap(raw);
    if (map == null) return null;
                                                
    final fan = _asMap(map['fan']);
    if (fan == null) return null;
    final img = (map['image'] as String?) ?? (map['card_url'] as String?) ?? '';
    return BiliFanDecorate(
      imageUrl: _normalizeUrl(img),
      name: (map['name'] as String?) ?? '',
      isFan: _toBool(fan['is_fan']) || _toBool(fan['isFan']),
      number: _toInt(fan['number']),
      numDesc: (fan['num_desc'] as String?) ??
          (fan['number_str'] as String?) ??
          (fan['numberStr'] as String?) ??
          '',
      numPrefix: (fan['num_prefix'] as String?) ??
          (fan['numPrefix'] as String?) ??
          '',
      colorHex: (fan['color'] as String?) ?? '',
      jumpUrl: (map['jump_url'] as String?) ?? (map['jumpUrl'] as String?) ?? '',
    );
  }

                               
  static BiliFanDecorate? fromMember(Map<String, dynamic> member) {
    final v2 = _asMap(member['user_sailing_v2']);
    if (v2 != null) {
      final d = BiliFanDecorate.fromAny(v2['card_bg']) ??
          BiliFanDecorate.fromAny(v2['cardbg']);
      if (d != null && d.isValid) return d;
    }
    final v1 = _asMap(member['user_sailing']);
    if (v1 != null) {
      final d = BiliFanDecorate.fromAny(v1['cardbg']) ??
          BiliFanDecorate.fromAny(v1['card_bg']);
      if (d != null && d.isValid) return d;
    }
    return null;
  }

                                 
  static BiliFanDecorate? fromSpaceData(Map<String, dynamic> data) {
    final d = BiliFanDecorate.fromAny(data['decorate_card']);
    if (d != null && d.isValid) return d;
    final card = _asMap(data['card']);
    if (card != null) {
      final s = _asMap(card['user_sailing']);
      if (s != null) {
        final x = BiliFanDecorate.fromAny(s['cardbg']) ??
            BiliFanDecorate.fromAny(s['card_bg']);
        if (x != null && x.isValid) return x;
      }
    }
    return null;
  }
}

                                            
                  
                                            

class BiliNameplate {
                       
  final int nid;
  final String name;
  final String image;
  final String imageSmall;

                                      
  final String level;
  final String condition;

  const BiliNameplate({
    this.nid = 0,
    this.name = '',
    this.image = '',
    this.imageSmall = '',
    this.level = '',
    this.condition = '',
  });

  bool get isValid => imageSmall.isNotEmpty || image.isNotEmpty || name.isNotEmpty;

                              
  bool get isDigitalCollection =>
      level.contains('数字藏品') || level.contains('藏品');

  String get imageUrl => imageSmall.isNotEmpty ? imageSmall : image;

  static BiliNameplate? fromAny(dynamic raw) {
    final map = _asMap(raw);
    if (map == null) return null;
    final p = BiliNameplate(
      nid: _toInt(map['nid'] ?? map['n_id']),
      name: (map['name'] as String?) ?? '',
      image: _normalizeUrl((map['image'] as String?) ?? ''),
      imageSmall: _normalizeUrl((map['image_small'] as String?) ?? ''),
      level: (map['level'] as String?) ?? '',
      condition: (map['condition'] as String?) ?? '',
    );
    return p.isValid ? p : null;
  }
}

                                                               
class BiliDigitalItem {
             
  final String nftId;
  final String name;

  const BiliDigitalItem({this.nftId = '', this.name = ''});

  bool get isValid => nftId.isNotEmpty;

  static BiliDigitalItem? fromMember(Map<String, dynamic> member) {
    final isNft = _toInt(member['face_nft_new']) == 1;
    if (!isNft) return null;
    final it = _asMap(member['nft_interaction']);
    final id = (it?['nft_id'] as String?) ??
        (it?['nftId'] as String?) ??
        (it?['nftid'] as String?) ??
        '';
    if (id.isEmpty) return null;
    return BiliDigitalItem(
      nftId: id,
      name: (it?['name'] as String?) ?? '',
    );
  }
}

                                            
                                     
                                            

                                      
   
                                                 
                                                 
                                     
                                         
class FanDecorateCornerCard extends StatelessWidget {
  final BiliFanDecorate decorate;

                             
  final double height;

  const FanDecorateCornerCard({
    super.key,
    required this.decorate,
    this.height = 36,
  });

                        
  static const double _imageAspect = 6.0;

                                      
  static const double _figureCenterFrac = 0.76;
  static const double _figureWidthFrac = 0.135;

  @override
  Widget build(BuildContext context) {
    final d = decorate;
    final numText = d.numDesc.isNotEmpty
        ? d.numDesc
        : (d.number > 0 ? '${d.number}' : '');
    final prefix = d.numPrefix.isEmpty ? 'NO.' : d.numPrefix;
    if (d.imageUrl.isEmpty && numText.isEmpty) {
      return const SizedBox.shrink();
    }
    final numColor = d.color;

                                
    Widget? figure;
    if (d.imageUrl.isNotEmpty) {
      final imgW = height * _imageAspect;
      final winW = imgW * _figureWidthFrac;
      final winLeft = imgW * (_figureCenterFrac - _figureWidthFrac / 2);
                                                              
                                              
      final ax = (2 * winLeft / (imgW - winW)) - 1;
                                                     
      figure = SizedBox(
        width: winW,
        height: height,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment(ax, 0),
            maxWidth: imgW,
            maxHeight: height,
            child: SizedBox(
              width: imgW,
              height: height,
              child: _NetImage(url: d.imageUrl, height: height),
            ),
          ),
        ),
      );
    }

                                             
    final numberCol = numText.isEmpty
        ? null
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prefix,
                style: TextStyle(
                  fontSize: height * 0.26,
                  height: 1.0,
                  letterSpacing: 0.5,
                  fontFamily: 'digital_id_num',
                  color: numColor,
                ),
              ),
              Text(
                numText,
                style: TextStyle(
                  fontSize: height * 0.34,
                  height: 1.05,
                  letterSpacing: 0.5,
                  fontFamily: 'digital_id_num',
                  color: numColor,
                ),
              ),
            ],
          );

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (figure != null) figure,
        if (figure != null && numberCol != null)
          SizedBox(width: height * 0.1),
        if (numberCol != null) numberCol,
      ],
    );
    if (d.name.isNotEmpty) {
      child = AppTooltip(message: d.name, child: child);
    }
    return child;
  }
}

                                            
                        
                                            

class FanDecorateBadge extends StatelessWidget {
  final BiliFanDecorate decorate;

                             
  final double height;

                        
  final Color? color;

                                    
                           
  final double maxWidth;

             
     
                               
                                    
  final bool showImage;

  final VoidCallback? onTap;

  const FanDecorateBadge({
    super.key,
    required this.decorate,
    this.height = 20,
    this.color,
    this.maxWidth = 64,
    this.showImage = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final d = decorate;
    final numText = d.numberText;
    final numColor = color ?? d.color;
    final hasImage = showImage && d.imageUrl.isNotEmpty;

    Widget child;
    if (hasImage) {
                                          
      child = SizedBox(
        width: maxWidth,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.contain,
                child: _NetImage(url: d.imageUrl, height: height),
              ),
            ),
            if (numText.isNotEmpty)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: height * 0.12),
                    child: _buildNumber(numText, numColor, height * 0.34),
                  ),
                ),
              ),
          ],
        ),
      );
    } else if (numText.isNotEmpty) {
                              
      child = Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: height * 0.28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height * 0.28),
          color: numColor.withValues(alpha: 0.16),
          border: Border.all(color: numColor.withValues(alpha: 0.55), width: 0.6),
        ),
        child: _buildNumber(numText, numColor, height * 0.44),
      );
    } else {
      return const SizedBox.shrink();
    }

    if (d.name.isNotEmpty) {
      child = AppTooltip(message: d.name, child: child);
    }
    if (onTap != null) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      );
    }
    return child;
  }

  Widget _buildNumber(String text, Color color, double fontSize) {
                                     
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.05,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
          shadows: const [Shadow(blurRadius: 2, color: Colors.black26)],
        ),
      ),
    );
  }
}

                                            
                                
                                            

class NameplateBadge extends StatelessWidget {
  final BiliNameplate plate;
  final double height;

                             
  final bool showNumber;

  final VoidCallback? onTap;

  const NameplateBadge({
    super.key,
    required this.plate,
    this.height = 18,
    this.showNumber = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showNum = showNumber && plate.nid > 0;
    final tip = [
      if (plate.name.isNotEmpty) plate.name,
      if (plate.level.isNotEmpty) plate.level,
      if (plate.condition.isNotEmpty) plate.condition,
    ].join(' · ');

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (plate.imageUrl.isNotEmpty)
          _NetImage(url: plate.imageUrl, height: height)
        else if (plate.name.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: height * 0.3,
              vertical: height * 0.1,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height * 0.25),
              color: cs.secondaryContainer,
            ),
            child: Text(
              plate.name,
              style: TextStyle(
                fontSize: height * 0.55,
                fontWeight: FontWeight.w600,
                color: cs.onSecondaryContainer,
              ),
            ),
          ),
        if (showNum) ...[
          SizedBox(width: height * 0.18),
          Text(
            '#${plate.nid}',
            style: TextStyle(
              fontSize: height * 0.5,
              fontWeight: FontWeight.w600,
              color: plate.isDigitalCollection
                  ? const Color(0xFF7B61FF)
                  : cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    if (tip.isNotEmpty) child = AppTooltip(message: tip, child: child);
    if (onTap != null) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      );
    }
    return child;
  }
}

                                            
                                  
                                            

class DigitalItemBadge extends StatelessWidget {
  final BiliDigitalItem item;
  final double height;
  final VoidCallback? onTap;

  const DigitalItemBadge({
    super.key,
    required this.item,
    this.height = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
                                     
    final id = item.nftId;
    final short = id.length > 8 ? '${id.substring(0, 6)}…' : id;
    Widget child = Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height * 0.28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height * 0.5),
        gradient: const LinearGradient(
          colors: [Color(0xFF7B61FF), Color(0xFFB389FF)],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.diamond_outlined,
              size: height * 0.55, color: Colors.white),
          SizedBox(width: height * 0.14),
          Text(
            '#$short',
            style: TextStyle(
              fontSize: height * 0.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
    child = AppTooltip(
      message: item.name.isNotEmpty ? '${item.name} #$id' : '数字藏品 #$id',
      child: child,
    );
    if (onTap != null) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      );
    }
    return child;
  }
}

                                            
               
                                            

class _NetImage extends StatelessWidget {
  final String url;
  final double height;

  const _NetImage({required this.url, required this.height});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();
    final headers = NetworkSettingsService.instance.apiHeaders;
    return Image(
      image: CachedImageProvider(url, headers: headers.isEmpty ? null : headers),
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

Map<String, dynamic>? _asMap(dynamic v) => v is Map<String, dynamic>
    ? v
    : (v is Map ? Map<String, dynamic>.from(v) : null);

int _toInt(dynamic v) =>
    v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

bool _toBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

String _normalizeUrl(String url) {
  final s = url.trim();
  if (s.isEmpty) return '';
  if (s.startsWith('//')) return 'https:$s';
  return s;
}

                                              
Color _parseHexColor(String hex) {
  var h = hex.trim().replaceAll('#', '');
  if (h.length == 3) {
    h = h.split('').map((c) => '$c$c').join();
  }
  if (h.length == 8) {
                                                              
    final v = int.tryParse(h, radix: 16);
    if (v == null) return const Color(0xFFFB7299);
    if (hex.length == 9 && hex.startsWith('#')) {
      return Color(((v & 0xFFFFFF00) >> 8) | ((v & 0xFF) << 24));
    }
    return Color(v);
  }
  if (h.length == 6) {
    final v = int.tryParse(h, radix: 16);
    if (v != null) return Color(0xFF000000 | v);
  }
  return const Color(0xFFFB7299);
}
