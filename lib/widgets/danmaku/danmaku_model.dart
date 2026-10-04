import 'dart:ui';

          
enum DanmakuMode {
  scrollRightToLeft,                 
  bottom,                      
  top,                         
  reverseScroll,                 
  advanced,                         
  code,                             
}

                      
enum AdvancedDanmakuType {
  bas,                                              
  code,                             
  unknown,               
}

                      
class DanmakuItem {
  final double time;
  final DanmakuMode mode;
  final double fontSize;
  final Color color;
  final String content;

                                                  
  final int weight;

                                           
  final int count;

  const DanmakuItem({
    required this.time,
    required this.mode,
    required this.fontSize,
    required this.color,
    required this.content,
    this.weight = 0,
    this.count = 1,
  });

                
  AdvancedDanmakuType get advancedType {
    if (mode != DanmakuMode.advanced) return AdvancedDanmakuType.unknown;
    final trimmed = content.trim();
    if (trimmed.startsWith('[')) return AdvancedDanmakuType.bas;
    if (trimmed.contains('function') ||
        trimmed.contains('var ') ||
        trimmed.contains('let ') ||
        trimmed.contains('const ') ||
        trimmed.contains('=>') ||
        trimmed.contains('.prototype')) {
      return AdvancedDanmakuType.code;
    }
    return AdvancedDanmakuType.unknown;
  }

  static DanmakuMode _modeFromInt(int modeInt) {
    switch (modeInt) {
      case 4:
        return DanmakuMode.bottom;
      case 5:
        return DanmakuMode.top;
      case 6:
        return DanmakuMode.reverseScroll;
      case 7:
        return DanmakuMode.advanced;
      case 8:
        return DanmakuMode.code;
      default:
        return DanmakuMode.scrollRightToLeft;
    }
  }

  factory DanmakuItem.fromXmlAttr(String pAttr, String content) {
    final parts = pAttr.split(',');
    if (parts.length < 4) {
      return DanmakuItem(
        time: 0,
        mode: DanmakuMode.scrollRightToLeft,
        fontSize: 25,
        color: const Color(0xFFFFFFFF),
        content: content,
      );
    }
    final time = double.tryParse(parts[0]) ?? 0.0;
    final modeInt = int.tryParse(parts[1]) ?? 1;
    final fontSize = double.tryParse(parts[2]) ?? 25.0;
    final colorInt = int.tryParse(parts[3]) ?? 16777215;
    final color = Color(0xFF000000 | (colorInt & 0xFFFFFF));
    final weight = parts.length > 8 ? (int.tryParse(parts[8]) ?? 0) : 0;
    return DanmakuItem(
      time: time,
      mode: _modeFromInt(modeInt),
      fontSize: fontSize,
      color: color,
      content: content,
      weight: weight,
    );
  }

  factory DanmakuItem.fromRaw({
    required int progressMs,
    required int modeInt,
    required int fontSizeInt,
    required int colorInt,
    required String content,
    int weight = 0,
  }) {
    return DanmakuItem(
      time: progressMs / 1000.0,
      mode: _modeFromInt(modeInt),
      fontSize: fontSizeInt.toDouble(),
      color: Color(0xFF000000 | (colorInt & 0xFFFFFF)),
      content: content,
      weight: weight,
    );
  }

                             

  Map<String, dynamic> toJson() => {
        'time': time,
        'mode': mode.index,
        'fontSize': fontSize,
        'color': color.toARGB32(),
        'content': content,
        'weight': weight,
                              
        if (count > 1) 'count': count,
      };

  factory DanmakuItem.fromJson(Map<String, dynamic> json) {
    return DanmakuItem(
      time: (json['time'] as num?)?.toDouble() ?? 0.0,
      mode: DanmakuMode.values[
          ((json['mode'] as int?) ?? 0).clamp(0, DanmakuMode.values.length - 1)],
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 25.0,
      color: Color(json['color'] as int? ?? 0xFFFFFFFF),
      content: json['content'] as String? ?? '',
      weight: (json['weight'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 1,
    );
  }
}

                   
class ActiveDanmaku {
  final DanmakuItem item;
  final int track;
  final double startTime;
  double x;
  bool finished;

  ActiveDanmaku({
    required this.item,
    required this.track,
    required this.startTime,
    required this.x,
    this.finished = false,
  });
}