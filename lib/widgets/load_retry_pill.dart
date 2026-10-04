                                   
  
                                                
                                        
  
                                                   
                                           
                                                
import 'package:flutter/material.dart';

                                                
class LoadRetryPill extends StatelessWidget {
  const LoadRetryPill({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onRetry,
      tooltip: '重新加载',
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('重新加载'),
    );
  }
}

                                 
                                             
class PositionedRetryFab extends StatelessWidget {
  const PositionedRetryFab({
    super.key,
    required this.onRetry,
    this.bottomOffset,
  });

  final VoidCallback onRetry;

                                
  final double? bottomOffset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: bottomOffset ?? MediaQuery.paddingOf(context).bottom + 24,
      child: LoadRetryPill(onRetry: onRetry),
    );
  }
}
