import 'dart:ui';

import 'package:flutter/material.dart';

class MetroTileFace extends StatelessWidget {
  final Color bgColor;
  final Color iconColor;
  final double iconSize;
  final String title;
  final bool showText;
  final IconData icon;

  const MetroTileFace({
    super.key,
    required this.bgColor,
    required this.iconColor,
    required this.iconSize,
    required this.title,
    required this.showText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: Stack(
        children: [
          Center(
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
          if (showText)
            Positioned(
              left: 10,
              bottom: 8,
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class MetroTileInteraction extends StatefulWidget {
  final Widget child;
  final Function(double rotateY, double rotateX) onTapStart;

                                          
                                 
                          
  final bool showBorder;

                              
                                    
  final double pressScale;

  const MetroTileInteraction({
    required this.child,
    required this.onTapStart,
    this.showBorder = true,
    this.pressScale = 0.96,
    super.key,
  });

  @override
  State<MetroTileInteraction> createState() => _MetroTileInteractionState();
}

class _MetroTileInteractionState extends State<MetroTileInteraction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _curve;
  double _currentRotateX = 0.0;
  double _currentRotateY = 0.0;
  double _scale = 1.0;
  double _lockedRotateX = 0.0;
  double _lockedRotateY = 0.0;
  bool _isHovering = false;
  bool _isPressed = false;
  bool _isInside = false;
  bool _panAccepted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _calculateLockTilt(Offset localPos, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double percentX = ((localPos.dx - centerX) / centerX).clamp(
      -1.2,
      1.2,
    );
    final double percentY = ((localPos.dy - centerY) / centerY).clamp(
      -1.2,
      1.2,
    );
    _lockedRotateY = -percentX * 0.12;
    _lockedRotateX = percentY * 0.12;
    setState(() {
      _currentRotateY = _lockedRotateY;
      _currentRotateX = _lockedRotateX;
      _scale = widget.pressScale;
    });
  }

  void _handlePanDown(DragDownDetails details) {
    _panAccepted = false;
    setState(() {
      _isPressed = true;
      _isInside = true;
    });
    final RenderBox box = context.findRenderObject() as RenderBox;
    _calculateLockTilt(details.localPosition, box.size);
    _controller.forward();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPos = details.localPosition;
    final bool isCurrentlyInside =
        localPos.dx >= 0 &&
        localPos.dx <= box.size.width &&
        localPos.dy >= 0 &&
        localPos.dy <= box.size.height;
    if (isCurrentlyInside != _isInside) {
      setState(() => _isInside = isCurrentlyInside);
      if (isCurrentlyInside) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
    if (isCurrentlyInside) {
                                  
                         
      _calculateLockTilt(localPos, box.size);
    }
  }

  void _handleRelease() {
    if (!_isPressed) return;
                                    
                                            
    if (_panAccepted) return;
    setState(() => _isPressed = false);
    if (_isInside) widget.onTapStart(_lockedRotateY, _lockedRotateX);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onPanDown: _handlePanDown,
        onPanStart: (_) => _panAccepted = true,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: (_) {
          _panAccepted = false;
          _handleRelease();
        },
        onPanCancel: () {
          _panAccepted = false;
          _handleRelease();
        },
                                          
                                             
        onTapCancel: _handleRelease,
        child: AnimatedBuilder(
          animation: _curve,
          builder: (context, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0008)
              ..scaleByDouble(lerpDouble(1.0, _scale, _curve.value)!, 1, 1, 1)
              ..rotateX(_currentRotateX * _curve.value)
              ..rotateY(_currentRotateY * _curve.value),
            child: Stack(
              children: [
                widget.child,
                if (widget.showBorder && (_isHovering || _isPressed))
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
