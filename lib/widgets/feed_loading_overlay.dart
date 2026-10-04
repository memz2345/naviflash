                                        
  
                                       
                                                           
                                                           
                             
  
                                                
           
                  
                                                   
                            
                                         
                                 
                                                                             
           
         
      
  
                                                         
                                     

import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';

class FeedLoadingOverlay extends StatelessWidget {
  const FeedLoadingOverlay({
    super.key,
    required this.loadingMore,
    required this.hasMore,
    required this.bottomOffset,
  });

                                   
  final bool loadingMore;

                                     
  final bool hasMore;

                    
                                                    
                                        
     
                                                    
  final double bottomOffset;

  @override
  Widget build(BuildContext context) {
    if (!loadingMore && hasMore) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: bottomOffset,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: loadingMore
              ? const KeyedSubtree(
                  key: ValueKey('FeedLoadingOverlay.loading'),
                  child: _FloatingDisc(),
                )
              : KeyedSubtree(
                  key: const ValueKey('FeedLoadingOverlay.nomore'),
                  child: _LoadedChip(
                    label: AppLocalizations.of(context).searchAllLoaded,
                  ),
                ),
        ),
      ),
    );
  }
}

                                                            
                                  
class _FloatingDisc extends StatelessWidget {
  const _FloatingDisc();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      shape: const CircleBorder(),
      color: cs.surface,
      elevation: 6,
      shadowColor: cs.shadow.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: 24,
          height: 24,
          child: LoadingIndicatorM3E(color: cs.primary),
        ),
      ),
    );
  }
}

                                        
class _LoadedChip extends StatelessWidget {
  const _LoadedChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: cs.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
