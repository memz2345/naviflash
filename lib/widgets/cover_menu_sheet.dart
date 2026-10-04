                                    
  
                      
  
                                                             
                                             
                                 
  
                                          
                                      
                                                    
                            
import 'package:flutter/material.dart';

import 'ios_backdrop.dart';
import 'liquid_glass.dart';

import 'package:naviflash/widgets/predictive_back_sheet.dart';

                      
   
                                                          
                                              
                                       
typedef CoverMenuAction = ({
  IconData icon,
  String text,
  VoidCallback onTap,
});

                   
   
                                                 
                        
Future<void> showCoverMenuBottomSheet(
  BuildContext context, {
  String cover = '',
  String title = '',
  String subtitle = '',
  String? heroTag,
  required List<CoverMenuAction> actions,
}) async {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final legacyBg = isDark
      ? cs.surfaceContainerHigh.withValues(alpha: 0.8)
      : cs.surfaceContainerLow.withValues(alpha: 0.85);
                                           
  PopupOverlayGuard.open();
  try {
    return await showAppBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
                                        
                                        
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: GlassMenuSurface(
          radius: 24.0,
          blur: 12.0,
                                            
                                   
          tintOpacity: 0.12,
          lightIntensity: 0.2,
          stretch: 0.3,
          legacyClipRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          legacyDecoration: BoxDecoration(
            color: legacyBg,
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                         
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                                                  
                  if (cover.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _CoverPreview(
                          url: cover,
                          heroTag: heroTag,
                          title: title,
                          subtitle: subtitle,
                        ),
                      ),
                    ),
                  for (final action in actions)
                                                
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: action.onTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                action.icon,
                                size: 20,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                action.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  } finally {
    PopupOverlayGuard.close();
  }
}

                                     
class _CoverPreview extends StatelessWidget {
  final String url;
  final String? heroTag;
  final String title;
  final String subtitle;

  const _CoverPreview({
    required this.url,
    required this.title,
    required this.subtitle,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget img = AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade800,
              child: const Center(
                child: Icon(Icons.movie_outlined, color: Colors.white24),
              ),
            ),
          ),
                            
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 28, 12, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
    final tag = heroTag;
    if (tag != null && tag.isNotEmpty) {
      img = Hero(transitionOnUserGestures: true, tag: tag, child: img);
    }
    return img;
  }
}
