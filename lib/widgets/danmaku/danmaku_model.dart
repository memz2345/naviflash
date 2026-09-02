import 'dart:ui';

/// B站弹幕模式
enum DanmakuMode {
  scrollRightToLeft, // 1,2,3: 从右到左滚动
  bottom,            // 4: 底部固定
  top,               // 5: 顶部固定
  reverseScroll,     // 6: 从左到右滚动
  advanced,          // 7: 高级弹幕（不处理）
  code,              // 8: 代码弹幕（不处理）
}

/// 高级弹幕 (mode=7) 的子类型
enum AdvancedDanmakuType {
  bas,       // BAS 动画脚本 — content 为 JSON 数组 "[...]"
  code,      // 内嵌代码弹幕 — 含 JS/AS 关键字
  unknown,   // 无法归类的特殊弹幕
}

/// 单条弹幕数据（渲染层统一使用的格式）
class DanmakuItem {
  final double time;
  final DanmakuMode mode;
  final double fontSize;
  final Color color;
  final String content;

  /// 弹幕权重（0~11，protobuf field 9 / XML p 属性第 9 段）。
  final int weight;

  const DanmakuItem({
    required this.time,
    required this.mode,
    required this.fontSize,
    required this.color,
    required this.content,
    this.weight = 0,
  });

  /// 判断高级弹幕的子类型
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

  // ─── JSON 序列化（用于本地缓存） ───

  Map<String, dynamic> toJson() => {
        'time': time,
        'mode': mode.index,
        'fontSize': fontSize,
        'color': color.value,
        'content': content,
        'weight': weight,
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
    );
  }
}

/// 正在渲染中的弹幕（运行时状态）
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