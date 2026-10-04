                                
  
                           
  
                                        
                                                             
  
                       
                                          
                             
                                       
                                       
                         
  
      
                       
                                                                                 
                                           
  
                                   
                                                                                 
                                        
library;

import 'package:flutter/material.dart';

import 'package:naviflash/src/loading_indicator_m3e.dart';

                
   
                                                   
                             
bool shouldShowFullScreenLoading({
  required bool loading,
  required bool isEmpty,
}) => loading && isEmpty;

                                
   
                                                 
class PageLoadingIndicator extends StatelessWidget {
  const PageLoadingIndicator({
    super.key,
    this.size = 48.0,
    this.label,
    this.colorOverride,
  });

            
  final double size;

                             
  final String? label;

                                          
  final Color? colorOverride;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadingIndicatorM3E(
            color: colorOverride ?? cs.primary,
            constraints: BoxConstraints.tight(Size(size, size)),
          ),
          if (label != null) ...[
            SizedBox(height: size * 0.28),
            Text(
              label!,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

                                                             
class PageLoadingSliver extends StatelessWidget {
  const PageLoadingSliver({super.key, this.size = 48.0, this.label});

  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: PageLoadingIndicator(size: size, label: label),
    );
  }
}

                                     
const Widget pageLoadingMoreSliver = SliverToBoxAdapter(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: LoadingIndicatorM3E(),
      ),
    ),
  ),
);
