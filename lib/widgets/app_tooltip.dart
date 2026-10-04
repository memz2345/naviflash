                               
  
                                                       
  
                                                        
                                                
                                                              
                                         
                              
  
                                                        
                                                   
                                                   
                                             
                                        
                                 
  
                                                  
import 'package:flutter/material.dart';

import 'package:naviflash/services/native_tooltip_service.dart';

                                                 
   
                                                        
                                                   
class AppTooltip extends StatelessWidget {
  const AppTooltip({
    super.key,
    required this.message,
    required this.child,
    this.waitDuration,
    this.triggerMode,
  });

           
  final String message;

                             
  final Widget child;

                         
  final Duration? waitDuration;

                                   
  final TooltipTriggerMode? triggerMode;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return child;
                                                  
    if (!NativeTooltipService.useNative) {
      return Tooltip(
        message: message,
        waitDuration: waitDuration,
        triggerMode: triggerMode,
        child: child,
      );
    }
                                                              
                                         
    if (!TooltipVisibility.of(context)) return child;
    return _NativeTooltip(
      message: message,
      waitDuration: waitDuration,
      triggerMode: triggerMode,
      child: child,
    );
  }
}

class _NativeTooltip extends StatefulWidget {
  const _NativeTooltip({
    required this.message,
    required this.child,
    this.waitDuration,
    this.triggerMode,
  });

  final String message;
  final Widget child;
  final Duration? waitDuration;
  final TooltipTriggerMode? triggerMode;

  @override
  State<_NativeTooltip> createState() => _NativeTooltipState();
}

class _NativeTooltipState extends State<_NativeTooltip> {
                            
  final GlobalKey _anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return RawTooltip(
                                                  
      semanticsTooltip: widget.message,
                                                                    
                                                  
      touchDelay: const Duration(milliseconds: 1500),
      hoverDelay: widget.waitDuration ?? Duration.zero,
      triggerMode: widget.triggerMode ?? TooltipTriggerMode.longPress,
                                                   
                
      ignorePointer: true,
      tooltipBuilder: (context, animation) => _NativeTooltipBridge(
        animation: animation,
        text: widget.message,
        anchorKey: _anchorKey,
        dark: Theme.of(context).brightness == Brightness.dark,
      ),
      child: KeyedSubtree(key: _anchorKey, child: widget.child),
    );
  }
}

                                     
class _NativeTooltipBridge extends StatefulWidget {
  const _NativeTooltipBridge({
    required this.animation,
    required this.text,
    required this.anchorKey,
    required this.dark,
  });

                                         
                                         
  final Animation<double> animation;

  final String text;

                               
  final GlobalKey anchorKey;

                                   
  final bool dark;

  @override
  State<_NativeTooltipBridge> createState() => _NativeTooltipBridgeState();
}

class _NativeTooltipBridgeState extends State<_NativeTooltipBridge> {
                             
  int? _token;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatusChanged);
                                             
                                        
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
  }

  void _onStatusChanged(AnimationStatus status) => _sync();

  void _sync() {
    final status = widget.animation.status;
    final showing =
        status == AnimationStatus.forward ||
        status == AnimationStatus.completed;
    if (!showing) {
      _hide();
      return;
    }
    if (_token != null) return;               
    final anchor = _anchorRect();
    if (anchor == null) return;
    _token = NativeTooltipService.show(
      text: widget.text,
      anchor: anchor,
      dark: widget.dark,
    );
  }

  void _hide() {
    NativeTooltipService.hide(_token);
    _token = null;
  }

                                           
                     
  Rect? _anchorRect() {
    final object = widget.anchorKey.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.hasSize) return null;
    return object.localToGlobal(Offset.zero) & object.size;
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatusChanged);
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
