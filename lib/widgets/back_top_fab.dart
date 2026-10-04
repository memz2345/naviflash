                                
  
                                   
                                  
                              
                                 
                        
                                   
                                     
  
                               
                                      
                                      
                                          
              
                                     
import 'package:flutter/material.dart';

class BackTopFab extends StatefulWidget {
  const BackTopFab({
    super.key,
    required this.extended,
    required this.onTap,
    this.onRefresh,
    this.atTop = false,
  });

                                                 
  final bool extended;

                                
                                        
  final VoidCallback? onTap;

                                        
  final VoidCallback? onRefresh;

                                       
  final bool atTop;

  @override
  BackTopFabState createState() => BackTopFabState();
}

class BackTopFabState extends State<BackTopFab>
    with SingleTickerProviderStateMixin {
                                    
     
                                                  
                                                     
                          
  late final AnimationController _flight;

                                
  bool get _refreshMode => widget.onRefresh != null && widget.atTop;

  @override
  void initState() {
    super.initState();
    _flight = AnimationController(vsync: this);
  }

                                   
                                     
  void startFlight(Duration duration) {
    _flight.duration = duration;
    _flight.forward(from: 0);
  }

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_refreshMode) {
      widget.onRefresh?.call();
      return;
    }
    widget.onTap?.call();
  }

  Widget _buildFlightIcon(double t) {
    const icon = Icon(Icons.arrow_upward_rounded);
    if (t <= 0) return icon;
    if (t < 0.5) {
                    
      final p = Curves.easeIn.transform(t / 0.5);
      return Opacity(
        opacity: 1 - p,
        child: Transform.translate(
          offset: Offset(0, -44 * p),
          child: icon,
        ),
      );
    }
                 
    final p = Curves.easeOut.transform((t - 0.5) / 0.5);
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: Offset(0, 44 * (1 - p)),
        child: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: null,
      tooltip: _refreshMode ? '立即刷新' : '回到顶部',
      onPressed: widget.onTap == null && widget.onRefresh == null
          ? null
          : _handleTap,
                                         
                    
      extendedIconLabelSpacing: 0,
                                               
                                                 
      extendedPadding: const EdgeInsetsDirectional.only(start: 16, end: 16),
      icon: AnimatedBuilder(
        animation: _flight,
        builder: (context, _) {
                                      
          if (_flight.isAnimating) return _buildFlightIcon(_flight.value);
          if (_refreshMode) return const Icon(Icons.refresh_rounded);
          return _buildFlightIcon(0);
        },
      ),
      label: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ClipRect(
            child: SizeTransition(
              sizeFactor: animation,
              axis: Axis.horizontal,
                                  
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        ),
        child: widget.extended
            ? Row(
                key: ValueKey(_refreshMode ? 'refresh' : 'label'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 8),
                  Text(
                    _refreshMode ? '立即刷新' : '回到顶部',
                    maxLines: 1,
                    softWrap: false,
                  ),
                ],
              )
            : const SizedBox.shrink(key: ValueKey('empty')),
      ),
    );
  }
}

                            
   
                                           
                                     
                                 
                                  
                                            
class BackTopFabVisibility {
  BackTopFabVisibility({this.threshold = 96});

                  
  final double threshold;

  double _accum = 0;
  bool _extended = false;

  bool get extended => _extended;

  bool update(double delta) {
    if (delta == 0) return false;
    if ((_accum > 0) != (delta > 0)) {
      _accum = delta;
    } else {
      _accum += delta;
    }
    final next = _accum <= -threshold
        ? true
        : _accum >= threshold
        ? false
        : _extended;
    if (next == _extended) return false;
    _extended = next;
    return true;
  }

  void reset() {
    _accum = 0;
    _extended = false;
  }
}
