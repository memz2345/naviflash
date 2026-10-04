                                    
  
                                                 
                          
import 'package:flutter/material.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';

class FansMedalBadge extends StatelessWidget {
  final BiliFansDetail detail;
  final double fontSize;

                                                        
  final bool showNumber;

  const FansMedalBadge({
    super.key,
    required this.detail,
    this.fontSize = 11,
    this.showNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    final d = detail;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.75,
        vertical: fontSize * 0.22,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [d.colorStart, d.colorEnd]),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: d.colorBorder.withValues(alpha: 0.9),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(blurRadius: 5, color: Colors.black38, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            d.medalName,
            style: TextStyle(
              color: d.nameColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1.2,
              shadows: const [Shadow(blurRadius: 3, color: Colors.black38)],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            showNumber && d.number > 0 ? '#${d.number}' : 'LV ${d.level}',
            style: TextStyle(
              color: d.nameColor.withValues(alpha: 0.92),
              fontSize: fontSize - 1,
              fontWeight: FontWeight.w500,
              height: 1.2,
              shadows: const [Shadow(blurRadius: 3, color: Colors.black38)],
            ),
          ),
        ],
      ),
    );
  }
}
