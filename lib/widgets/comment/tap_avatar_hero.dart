                                           
  
                                       
  
                                           
                                         
                       
import 'package:flutter/material.dart';

class TapAvatarHero extends StatefulWidget {
                                                          
                                                       
  final String? heroTag;

                
  final Widget avatar;

                                   
  final Future<void> Function() onTap;

  const TapAvatarHero({
    super.key,
    required this.heroTag,
    required this.avatar,
    required this.onTap,
  });

  @override
  State<TapAvatarHero> createState() => _TapAvatarHeroState();
}

class _TapAvatarHeroState extends State<TapAvatarHero> {
  bool _flying = false;

  Future<void> _handleTap() async {
    setState(() => _flying = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) setState(() => _flying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: (_flying && widget.heroTag != null)
          ? Hero(transitionOnUserGestures: true, tag: widget.heroTag!, child: widget.avatar)
          : widget.avatar,
    );
  }
}
