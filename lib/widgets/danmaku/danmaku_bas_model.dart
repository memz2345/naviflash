import 'dart:convert';
import 'dart:ui';

           
class BasKeyframe {
  final double x;
  final double y;
  final double alpha;
  final double scale;
  final double rotate;
  final double t;       

  const BasKeyframe({
    required this.x,
    required this.y,
    this.alpha = 1.0,
    this.scale = 1.0,
    this.rotate = 0.0,
    required this.t,
  });

  factory BasKeyframe.fromJson(Map<String, dynamic> j) {
    return BasKeyframe(
      x: _num(j['x'] ?? j['X'] ?? 0),
      y: _num(j['y'] ?? j['Y'] ?? 0),
      alpha: _num(j['alpha'] ?? j['a'] ?? 1.0),
      scale: _num(j['scale'] ?? j['s'] ?? 1.0),
      rotate: _num(j['rotate'] ?? j['r'] ?? 0.0),
      t: _num(j['t'] ?? j['time'] ?? 0),
    );
  }

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

              
class BasElement {
  final String text;
  final Color color;
  final double fontSize;
  final double alpha;
  final double duration;
  final double delay;
  final double x;
  final double y;
  final bool isNormalized;
  final List<BasKeyframe> move;
  final List<BasKeyframe> alphaFrames;
  final List<BasKeyframe> scaleFrames;
  final List<BasKeyframe> rotateFrames;
  final bool bold;
  final bool italic;
  final int zIndex;

  const BasElement({
    required this.text,
    this.color = const Color(0xFFFFFFFF),
    this.fontSize = 25.0,
    this.alpha = 1.0,
    this.duration = 4.0,
    this.delay = 0.0,
    this.x = 0.5,
    this.y = 0.5,
    this.isNormalized = true,
    this.move = const [],
    this.alphaFrames = const [],
    this.scaleFrames = const [],
    this.rotateFrames = const [],
    this.bold = false,
    this.italic = false,
    this.zIndex = 0,
  });

                           
  factory BasElement.fromJson(Map<String, dynamic> j) {
    Color color = const Color(0xFFFFFFFF);
    final cRaw = j['color'] ?? j['c'] ?? j['fill'];
    if (cRaw is int) {
      color = Color(0xFF000000 | (cRaw & 0xFFFFFF));
    } else if (cRaw is String) {
      color = _parseColor(cRaw);
    }

    List<BasKeyframe> frames(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(BasKeyframe.fromJson)
            .toList()
          ..sort((a, b) => a.t.compareTo(b.t));
      }
      return [];
    }

    final xVal = BasKeyframe._num(j['x'] ?? j['X'] ?? 0.5);
    final yVal = BasKeyframe._num(j['y'] ?? j['Y'] ?? 0.5);
    final normalized = xVal <= 1.0 && yVal <= 1.0;

    return BasElement(
      text: (j['text'] ?? j['content'] ?? '').toString(),
      color: color,
      fontSize: BasKeyframe._num(j['fontSize'] ?? j['size'] ?? j['fs'] ?? 25),
      alpha: BasKeyframe._num(j['alpha'] ?? j['a'] ?? 1.0),
      duration: BasKeyframe._num(j['duration'] ?? j['dur'] ?? j['d'] ?? 4.0),
      delay: BasKeyframe._num(j['delay'] ?? j['dl'] ?? 0.0),
      x: xVal,
      y: yVal,
      isNormalized: normalized,
      move: frames(j['move'] ?? j['moves'] ?? j['path']),
      alphaFrames: frames(j['alphaFrames'] ?? j['alphas']),
      scaleFrames: frames(j['scaleFrames'] ?? j['scales']),
      rotateFrames: frames(j['rotateFrames'] ?? j['rotates']),
      bold: j['bold'] == true || j['fontWeight'] == 'bold',
      italic: j['italic'] == true || j['fontStyle'] == 'italic',
      zIndex:
          (j['zIndex'] ?? j['z'] ?? 0) is int ? (j['zIndex'] ?? j['z'] ?? 0) : 0,
    );
  }

                             
     
                                                            
                                                                
     
         
                                                                                     
                                                                     
  factory BasElement.fromBilibiliArray(List<dynamic> arr) {
    double numAt(int i, [double fallback = 0]) {
      if (i >= arr.length) return fallback;
      final v = arr[i];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    String strAt(int i, [String fallback = '']) {
      if (i >= arr.length) return fallback;
      final v = arr[i];
      if (v is String) return v;
      return v?.toString() ?? fallback;
    }

                  
    final x = numAt(0);              
    final y = numAt(1);              
                                          
    final duration = numAt(3, 4.0);
    final text = strAt(4);

                                 
    final fromAlpha = (numAt(5, 1000) / 1000.0).clamp(0.0, 1.0);
    final toAlpha = (numAt(6, 1000) / 1000.0).clamp(0.0, 1.0);

                  
    final fromX = numAt(7);
    final toX = numAt(8);
    final fromY = numAt(9);
    final toY = numAt(10);

                                          
    final rawFontSize = numAt(11, 25.0);
    final fontSize = rawFontSize < 2.0 ? 25.0 : rawFontSize;

                                      
                      

                                          
    const bool isNormalized = false;

                    
    final moveFrames = <BasKeyframe>[];
    final hasMove =
        (fromX - toX).abs() > 0.01 || (fromY - toY).abs() > 0.01;
    if (hasMove) {
      moveFrames.add(BasKeyframe(x: fromX, y: fromY, t: 0));
      moveFrames.add(BasKeyframe(x: toX, y: toY, t: duration));
    }

                     
    final alphaFrames = <BasKeyframe>[];
    if ((fromAlpha - toAlpha).abs() > 0.001) {
      alphaFrames.add(BasKeyframe(x: 0, y: 0, alpha: fromAlpha, t: 0));
      alphaFrames.add(BasKeyframe(x: 0, y: 0, alpha: toAlpha, t: duration));
    }

    return BasElement(
      text: text,
      color: const Color(0xFFFFFFFF),
      fontSize: fontSize,
      alpha: fromAlpha,
      duration: duration,
      delay: 0.0,
      x: x,
      y: y,
      isNormalized: isNormalized,
      move: moveFrames,
      alphaFrames: alphaFrames,
      scaleFrames: const [],
      rotateFrames: const [],
      bold: false,
      italic: false,
      zIndex: 0,
    );
  }

  static Color _parseColor(String s) {
    var hex =
        s.trim().replaceAll('#', '').replaceAll('0x', '').replaceAll('0X', '');
    final val = int.tryParse(hex, radix: 16);
    if (val == null) return const Color(0xFFFFFFFF);
    if (hex.length <= 6) return Color(0xFF000000 | (val & 0xFFFFFF));
    return Color(val);
  }
}

               
class BasDanmaku {
  final List<BasElement> elements;
  final double startTime;
  final double totalDuration;
  bool finished = false;

  BasDanmaku({
    required this.elements,
    required this.startTime,
  }) : totalDuration = _calc(elements);

  static double _calc(List<BasElement> els) {
    double max = 0;
    for (final e in els) {
      final end = e.delay + e.duration;
      if (end > max) max = end;
    }
    return max > 0 ? max : 4.0;
  }

                                    
     
             
                                   
                                            
                                   
                                               
                 
                                          
  static BasDanmaku? tryParse(String content, double startTime) {
    try {
      final trimmed = content.trim();
      if (!trimmed.startsWith('[')) return null;

      final list = jsonDecode(trimmed);
      if (list is! List || list.isEmpty) return null;

      final elements = <BasElement>[];

                                  
        
                                                     
                                                           
                                                    
        
                                                       
                                                                       
                              
      final first = list.first;

      if (first is! List && first is! Map) {
                                         
        final el = BasElement.fromBilibiliArray(list);
        if (el.text.isNotEmpty) {
          elements.add(el);
        }
      } else {
                                 
        for (final item in list) {
          BasElement? el;
          if (item is Map<String, dynamic>) {
                             
            el = BasElement.fromJson(item);
          } else if (item is List) {
                        
            el = BasElement.fromBilibiliArray(item);
          }
          if (el != null && el.text.isNotEmpty) {
            elements.add(el);
          }
        }
      }

      if (elements.isEmpty) return null;
      elements.sort((a, b) => a.zIndex.compareTo(b.zIndex));
      return BasDanmaku(elements: elements, startTime: startTime);
    } catch (_) {
      return null;
    }
  }
}