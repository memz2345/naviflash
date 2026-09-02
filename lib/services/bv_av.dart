// lib/services/bv_av.dart
//
//   decode: BV → AV 号数字（如 170001）
//   encode: AV 号数字 → 完整 BV 号（如 BV17x411w7KC）

/// BV / AV 号互转工具。
abstract final class BvAv {
  static const String _table =
      'fZodR9XQDSUm21yCkr6zBqiveYah8bt4xsWpHnJE7jL5VG3guMTKNPAwcF';
  static const List<int> _pos = [11, 10, 3, 8, 4, 6];
  static const int _xor = 177451812;
  static const int _add = 8728348608;

  static final Map<String, int> _tr = _buildTr();

  static Map<String, int> _buildTr() {
    final map = <String, int>{};
    for (var i = 0; i < _table.length; i++) {
      map[_table[i]] = i;
    }
    return map;
  }

  static int _pow58(int e) {
    var p = 1;
    for (var i = 0; i < e; i++) {
      p *= 58;
    }
    return p;
  }

  /// BV → AV，返回 av 号数字；输入不是合法 BV 时返回 null。
  /// 注意：BV 号大小写敏感（表内 x/X、w/W 等是不同字符），不可 toUpperCase。
  static int? decode(String bv) {
    final b = bv.trim();
    if (b.length != 12 || !b.startsWith('BV')) return null;
    var r = 0;
    for (var i = 0; i < 6; i++) {
      final v = _tr[b[_pos[i]]];
      if (v == null) return null;
      r += v * _pow58(i);
    }
    return (r - _add) ^ _xor;
  }

  /// AV → BV，返回完整 BV 号；av 非法（<=0）时返回 null。
  static String? encode(int av) {
    if (av <= 0) return null;
    var x = (av ^ _xor) + _add;
    final r = List<String>.generate(
      12,
      (i) => 'BV1  4 1 7  '[i],
    );
    for (var i = 0; i < 6; i++) {
      r[_pos[i]] = _table[(x ~/ _pow58(i)) % 58];
    }
    return r.join();
  }
}
