import 'dart:convert';
import 'dart:ui';

/// BAS 关键帧
class BasKeyframe {
  final double x;
  final double y;
  final double alpha;
  final double scale;
  final double rotate;
  final double t; // 相对秒

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

/// BAS 单个动画元素
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

  /// 从 JSON 对象解析（自定义/扩展格式）
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

///  从 Bilibili 原生 BAS 数组格式解析
  ///
  /// 格式: [x, y, animId, duration, text, fromAlpha, toAlpha,
  ///        fromX, toX, fromY, toY, fontSize, font, flags, ...]
  ///
  /// 示例:
  ///   ["367","225","1-1","10","11111","360","0","172","203","100","0",1,"SimHei",1]
  ///   [0,0,"1-1",5,"消灭人类暴政，世界属于三体！",0,20,0,0,300,1000,1,"SimHei",1]
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

    // ── 解析各字段 ──
    final x = numAt(0); // 起始 x（像素坐标）
    final y = numAt(1); // 起始 y（像素坐标）
    // arr[2] = 动画标识 (如 "1-1")，暂不做复杂动画路径解析
    final duration = numAt(3, 4.0);
    final text = strAt(4);

    // alpha 范围 0~1000 → 归一化到 0~1
    final fromAlpha = (numAt(5, 1000) / 1000.0).clamp(0.0, 1.0);
    final toAlpha = (numAt(6, 1000) / 1000.0).clamp(0.0, 1.0);

    // 位移关键帧坐标（像素）
    final fromX = numAt(7);
    final toX = numAt(8);
    final fromY = numAt(9);
    final toY = numAt(10);

    // 字号：Bilibili BAS 中 fontSize=1 表示默认大小
    final rawFontSize = numAt(11, 25.0);
    final fontSize = rawFontSize < 2.0 ? 25.0 : rawFontSize;

    // arr[12] = 字体名 (如 "SimHei")，暂不使用
    // arr[13] = flags

// ──  修复：Bilibili BAS 始终使用像素坐标，不做归一化判断 ──
    const bool isNormalized = false;

    // ── 构建移动关键帧 ──
    final moveFrames = <BasKeyframe>[];
    final hasMove =
        (fromX - toX).abs() > 0.01 || (fromY - toY).abs() > 0.01;
    if (hasMove) {
      moveFrames.add(BasKeyframe(x: fromX, y: fromY, t: 0));
      moveFrames.add(BasKeyframe(x: toX, y: toY, t: duration));
    }

    // ── 构建透明度关键帧 ──
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

/// 一条完整 BAS 弹幕
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

  /// 从 content JSON 字符串解析，失败返回 null
  ///
  /// 支持三种格式：
  /// 1. Bilibili 原生 BAS 一维数组（单元素）：
  ///    ["367","225","1-1","10","text",...]
  /// 2. Bilibili 原生 BAS 嵌套数组（多元素）：
  ///    [["367","225",...], ["100","200",...]]
  /// 3. 自定义对象数组：
  ///    [{"text":"...","x":0.5,...}, ...]
  static BasDanmaku? tryParse(String content, double startTime) {
    try {
      final trimmed = content.trim();
      if (!trimmed.startsWith('[')) return null;

      final list = jsonDecode(trimmed);
      if (list is! List || list.isEmpty) return null;

      final elements = <BasElement>[];

//  判断是一维数组（单个 BAS 元素）还是嵌套结构（多个元素）
      //
      // 一维数组示例: ["367","225","1-1","10","11111",...]
      //   → jsonDecode 后 list = ["367", "225", "1-1", ...]
      //   → list.first 是 String/int，不是 List 也不是 Map
      //
      // 嵌套数组示例: [["367","225",...], ["100","200",...]]
      //   → jsonDecode 后 list = [["367","225",...], ["100","200",...]]
      //   → list.first 是 List
      final first = list.first;

      if (first is! List && first is! Map) {
        // ── 一维数组：整个 list 就是一个 BAS 元素 ──
        final el = BasElement.fromBilibiliArray(list);
        if (el.text.isNotEmpty) {
          elements.add(el);
        }
      } else {
        // ── 嵌套数组 / 对象数组：逐个解析 ──
        for (final item in list) {
          BasElement? el;
          if (item is Map<String, dynamic>) {
            // 对象格式（自定义/扩展格式）
            el = BasElement.fromJson(item);
          } else if (item is List) {
//  Bilibili 原生 BAS 数组格式
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