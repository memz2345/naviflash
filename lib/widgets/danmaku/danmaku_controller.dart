import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'danmaku_model.dart';
import 'danmaku_bas_model.dart';

/// 待重试的弹幕（轨道全满时暂存，下一帧再尝试分配）
class _PendingItem {
  final DanmakuItem item;
  int retriesLeft;
  _PendingItem({required this.item, required this.retriesLeft});
}

class DanmakuController {
  List<DanmakuItem> _items = [];
  final List<ActiveDanmaku> _activeDanmakus = [];
  final List<BasDanmaku> _activeBasDanmakus = [];
  final List<_PendingItem> _pendingDanmakus = [];
  int _nextIndex = 0;

  // 配置
  double speed = 1.0;
  double opacity = 1.0;
  double fontSizeScale = 1.0; // 非全屏档字号缩放
  double fontSizeScaleFS = 1.2;
  bool showScroll = true;
  bool showTop = true;
  bool showBottom = true;
  bool showAdvanced = true;
  int maxLines = 12;
  double lineHeight = 32.0;
  bool enabled = true;

  double strokeWidth = 2.0; // 描边粗细
  double fontWeight = 6.0; // 字体粗细（0~8 → w100~w900）
  double showArea = 1.0; // 显示区域（0.1~1.0）
  double scrollDuration = 7.0; // 滚动弹幕横穿时长（秒）
  double staticDuration = 4.0; // 顶部/底部固定弹幕时长（秒）
  double lineHeightScale = 1.6; // 弹幕行高倍率
  bool massiveMode = false; // 海量弹幕（更多轨道、更小间隔）
  bool static2Scroll = false; // 固定弹幕转滚动
  bool blockColorful = false; // 屏蔽彩色弹幕（只显示白色弹幕）

  /// 智能防遮挡：识别画面主体（人物/角色），弹幕不渲染到主体上
  bool smartMask = false;

  int danmakuWeight = 0;

  bool isFullscreen = false;


  Image? _personMask;

  /// 当前帧的主体遮罩（仅 alpha 通道有效），由播放器侧取帧推理后写入。
  Image? get personMask => _personMask;

  /// 更新主体遮罩（null = 画面中无主体），并触发重绘。
  void setPersonMask(Image? image) {
    final old = _personMask;
    if (old == image) return;
    _personMask = image;
    old?.dispose();
    if (smartMask) onNeedRepaint?.call();
  }


  static const String _prefsKey = 'danmaku_settings_v1';

  /// 把可调参数写入 SharedPreferences（弹幕设置面板应用后调用）。
  Future<void> persistSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode({
          'speed': speed,
          'opacity': opacity,
          'fontSizeScale': fontSizeScale,
          'fontSizeScaleFS': fontSizeScaleFS,
          'fontWeight': fontWeight,
          'strokeWidth': strokeWidth,
          'showArea': showArea,
          'lineHeightScale': lineHeightScale,
          'scrollDuration': scrollDuration,
          'staticDuration': staticDuration,
          'maxLines': maxLines,
          'danmakuWeight': danmakuWeight,
          'enabled': enabled,
          'showScroll': showScroll,
          'showTop': showTop,
          'showBottom': showBottom,
          'showAdvanced': showAdvanced,
          'massiveMode': massiveMode,
          'static2Scroll': static2Scroll,
          'blockColorful': blockColorful,
          'smartMask': smartMask,
        }),
      );
    } catch (e) {
      debugPrint('[Danmaku] 保存弹幕设置失败: $e');
    }
  }

  /// 从 SharedPreferences 恢复可调参数（控制器创建后调用，异步生效）。
  Future<void> restoreSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw);
      if (data is! Map) return;
      double d(String k, double fallback) =>
          (data[k] as num?)?.toDouble() ?? fallback;
      bool b(String k, bool fallback) => data[k] as bool? ?? fallback;
      int i(String k, int fallback) => (data[k] as num?)?.toInt() ?? fallback;

      speed = d('speed', speed);
      opacity = d('opacity', opacity);
      fontSizeScale = d('fontSizeScale', fontSizeScale);
      fontSizeScaleFS = d('fontSizeScaleFS', fontSizeScaleFS);
      fontWeight = d('fontWeight', fontWeight);
      strokeWidth = d('strokeWidth', strokeWidth);
      showArea = d('showArea', showArea);
      lineHeightScale = d('lineHeightScale', lineHeightScale);
      scrollDuration = d('scrollDuration', scrollDuration);
      staticDuration = d('staticDuration', staticDuration);
      maxLines = i('maxLines', maxLines);
      danmakuWeight = i('danmakuWeight', danmakuWeight);
      enabled = b('enabled', enabled);
      showScroll = b('showScroll', showScroll);
      showTop = b('showTop', showTop);
      showBottom = b('showBottom', showBottom);
      showAdvanced = b('showAdvanced', showAdvanced);
    massiveMode = b('massiveMode', massiveMode);
    static2Scroll = b('static2Scroll', static2Scroll);
    blockColorful = b('blockColorful', blockColorful);
    smartMask = b('smartMask', smartMask);
      onNeedRepaint?.call();
    } catch (e) {
      debugPrint('[Danmaku] 恢复弹幕设置失败: $e');
    }
  }

  /// 基准字号（逻辑像素）。
  /// 忽略 XML/protobuf 中的原始 fontsize（18/25/36），默认不再偏大。
  static const double baseFontSize = 15.0;

  double get activeFontSizeScale =>
      isFullscreen ? fontSizeScaleFS : fontSizeScale;

  /// 普通弹幕实际渲染字号（基准字号 × 用户缩放）。
  double get effectiveFontSize => baseFontSize * activeFontSizeScale;

  /// 同一轨道前后两条弹幕之间的最小间隔（秒）；海量模式下更密。
  double get _trackGap => massiveMode ? 0.1 : 0.3;

  /// 待重试弹幕最大重试帧数（约 0.5s @60fps）
  static const int _maxRetries = 30;

  /// 待重试队列最大长度
  static const int _maxPending = 200;

  // 屏幕尺寸
  double screenWidth = 0;
  double screenHeight = 0;

  /// 弹幕实际显示区域高度（受 showArea 限制，顶部对齐）。
  double get usableHeight => screenHeight * showArea;

  /// 滚动速度：保证弹幕约 [scrollDuration] 秒横穿全屏
  double get scrollSpeed =>
      (screenWidth > 0 ? screenWidth / scrollDuration : 120.0) * speed;

  /// 同时活跃的 BAS 弹幕上限
  static const int maxActiveBas = 8;

  final Map<int, double> _scrollTrackFreeTime = {};
  final Map<int, double> _topTrackFreeTime = {};
  final Map<int, double> _bottomTrackFreeTime = {};

///  轮询指针：记录每种类型上次分配到的轨道，下次从其后一位开始找
  int _lastScrollTrack = -1;
  int _lastTopTrack = -1;
  int _lastBottomTrack = -1;

  Ticker? _ticker;
  double _lastElapsed = 0;
  double _currentTime = 0;
  bool _isPlaying = false;
  double _syncTarget = -1;

  VoidCallback? onNeedRepaint;

  void setItems(List<DanmakuItem> items) {
    // 拷贝后再排序：不能原地修改调用方传入的列表（const 列表会抛
    // UnsupportedError，调用方也可能复用该列表）。
    _items = List.of(items);
    _items.sort((a, b) => a.time.compareTo(b.time));
    _logAdvancedStats();
    reset();
  }

  /// 发送成功后把弹幕立即上屏（同时并入列表，seek/重载后仍保留）。
  void addItem(DanmakuItem item) {
    final idx = _lowerBound(item.time);
    _items.insert(idx, item);
    if (idx < _nextIndex) _nextIndex++;
    // 时间已到则立即生成（滚动/顶部/底部弹幕）
    if (item.time <= _currentTime + 0.05) {
      switch (item.mode) {
        case DanmakuMode.scrollRightToLeft:
        case DanmakuMode.bottom:
        case DanmakuMode.top:
          _spawnDanmaku(item);
          onNeedRepaint?.call();
          break;
        default:
          break;
      }
    }
  }

  void _logAdvancedStats() {
    final advanced = <DanmakuItem>[];
    final code = <DanmakuItem>[];
    for (final item in _items) {
      if (item.mode == DanmakuMode.advanced) {
        advanced.add(item);
      } else if (item.mode == DanmakuMode.code) {
        code.add(item);
      }
    }
    if (advanced.isEmpty && code.isEmpty) {
      debugPrint('[Danmaku] 无高级弹幕 / 代码弹幕');
      return;
    }
    int basCount = 0;
    int inlineCodeCount = 0;
    int unknownCount = 0;
    final basSamples = <String>[];
    final unknownSamples = <String>[];
    for (final item in advanced) {
      switch (item.advancedType) {
        case AdvancedDanmakuType.bas:
          basCount++;
          if (basSamples.length < 3) {
            basSamples.add(
              item.content.length > 120
                  ? '${item.content.substring(0, 120)}...'
                  : item.content,
            );
          }
          break;
        case AdvancedDanmakuType.code:
          inlineCodeCount++;
          break;
        case AdvancedDanmakuType.unknown:
          unknownCount++;
          if (unknownSamples.length < 3) {
            unknownSamples.add(
              item.content.length > 120
                  ? '${item.content.substring(0, 120)}...'
                  : item.content,
            );
          }
          break;
      }
    }
    debugPrint('╔══════════════════════════════════════════════╗');
    debugPrint('║  📊 高级弹幕统计 (总弹幕 ${_items.length} 条)');
    debugPrint('╠══════════════════════════════════════════════╣');
    debugPrint('║  Mode 7 (高级弹幕): ${advanced.length} 条');
    if (basCount > 0) {
      debugPrint('║    ├─ BAS 动画脚本:  $basCount 条');
    }
    if (inlineCodeCount > 0) {
      debugPrint('║    ├─ 内嵌代码弹幕:  $inlineCodeCount 条');
    }
    if (unknownCount > 0) {
      debugPrint('║    └─ 未知类型:      $unknownCount 条');
    }
    debugPrint('║  Mode 8 (代码弹幕): ${code.length} 条');
    debugPrint('║  特殊弹幕合计:      ${advanced.length + code.length} 条');
    debugPrint('╠══════════════════════════════════════════════╣');
    if (basSamples.isNotEmpty) {
      debugPrint('║  BAS 样本 (前${basSamples.length}条):');
      for (int i = 0; i < basSamples.length; i++) {
        debugPrint('║    [$i] ${basSamples[i]}');
      }
    }
    if (unknownSamples.isNotEmpty) {
      debugPrint('║  未知类型样本 (前${unknownSamples.length}条):');
      for (int i = 0; i < unknownSamples.length; i++) {
        debugPrint('║    [$i] ${unknownSamples[i]}');
      }
    }
    debugPrint('╚══════════════════════════════════════════════╝');
  }

  void reset() {
    _activeDanmakus.clear();
    _activeBasDanmakus.clear();
    _pendingDanmakus.clear();
    _nextIndex = 0;
    _scrollTrackFreeTime.clear();
    _topTrackFreeTime.clear();
    _bottomTrackFreeTime.clear();
    _lastScrollTrack = -1;
    _lastTopTrack = -1;
    _lastBottomTrack = -1;
    _currentTime = 0;
    _lastElapsed = 0;
    _syncTarget = -1;
  }

  void setSize(double width, double height) {
    screenWidth = width;
    screenHeight = height;
    // 根据显示区域高度、字号与行高倍率动态计算轨道数
    final usable = height * showArea;
    final rawLines = (usable / (effectiveFontSize * lineHeightScale + 6))
        .floor();
    final cap = massiveMode ? 48 : 24;
    maxLines = rawLines.clamp(8, cap);
    lineHeight = usable / maxLines;
  }

  void play() {
    if (_isPlaying) return;
    _isPlaying = true;
    _lastElapsed = 0;
    _ticker ??= Ticker((elapsed) {
      final dt = (elapsed.inMicroseconds - _lastElapsed * 1e6) / 1e6;
      _lastElapsed = elapsed.inMicroseconds / 1e6;
      if (dt > 0 && dt < 1.0) {
        _update(dt);
      }
      onNeedRepaint?.call();
    });
    _ticker!.start();
  }

  void pause() {
    _isPlaying = false;
    _lastElapsed = 0;
    _ticker?.stop();
  }

  void syncTime(double timeSeconds) {
    _syncTarget = timeSeconds;
  }

  void seekTo(double timeSeconds) {
    _currentTime = timeSeconds;
    _syncTarget = -1;
    _activeDanmakus.clear();
    _activeBasDanmakus.clear();
    _pendingDanmakus.clear();
    _scrollTrackFreeTime.clear();
    _topTrackFreeTime.clear();
    _bottomTrackFreeTime.clear();
    _lastScrollTrack = -1;
    _lastTopTrack = -1;
    _lastBottomTrack = -1;
    _nextIndex = _lowerBound(timeSeconds - 1.0);
  }

  int _lowerBound(double time) {
    int lo = 0, hi = _items.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_items[mid].time < time) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  void _update(double dt) {
    if (!_isPlaying) return;
    _currentTime += dt;

    if (_syncTarget >= 0) {
      final diff = _syncTarget - _currentTime;
      if (diff.abs() > 2.0) {
        _currentTime = _syncTarget;
        _activeDanmakus.clear();
        _activeBasDanmakus.clear();
        _pendingDanmakus.clear();
        _scrollTrackFreeTime.clear();
        _topTrackFreeTime.clear();
        _bottomTrackFreeTime.clear();
        _lastScrollTrack = -1;
        _lastTopTrack = -1;
        _lastBottomTrack = -1;
        _nextIndex = _lowerBound(_syncTarget - 1.0);
        _syncTarget = -1;
        return;
      } else if (diff.abs() > 0.05) {
        _currentTime += diff * 0.4;
      }
      _syncTarget = -1;
    }

    // ── 重试上一帧未能分配的弹幕 ──
    _retryPending();

    // ── 生成新弹幕 ──
    while (_nextIndex < _items.length &&
        _items[_nextIndex].time <= _currentTime) {
      final item = _items[_nextIndex];
      _nextIndex++;
      if (!_shouldShow(item)) continue;
      _spawnDanmaku(item);
    }

    // ── 更新普通弹幕位置 ──
    for (final dm in _activeDanmakus) {
      if (dm.finished) continue;
      switch (effectiveMode(dm.item)) {
        case DanmakuMode.scrollRightToLeft:
          dm.x -= scrollSpeed * dt;
          final textWidth = _estimateTextWidth(dm.item);
          if (dm.x + textWidth < 0) dm.finished = true;
          break;
        case DanmakuMode.reverseScroll:
          dm.x += scrollSpeed * dt;
          if (dm.x > screenWidth) dm.finished = true;
          break;
        case DanmakuMode.top:
        case DanmakuMode.bottom:
          if (_currentTime - dm.startTime > staticDuration) {
            dm.finished = true;
          }
          break;
        default:
          dm.finished = true;
      }
    }
    _activeDanmakus.removeWhere((d) => d.finished);

    // ── 更新 BAS 高级弹幕生命周期 ──
    for (final bas in _activeBasDanmakus) {
      if (bas.finished) continue;
      if (_currentTime - bas.startTime > bas.totalDuration + 0.5) {
        bas.finished = true;
      }
    }
    _activeBasDanmakus.removeWhere((b) => b.finished);
  }

  /// 重试上一帧因轨道全满而被暂存的弹幕
  void _retryPending() {
    if (_pendingDanmakus.isEmpty) return;
    final stillPending = <_PendingItem>[];
    for (final p in _pendingDanmakus) {
      p.retriesLeft--;
      if (p.retriesLeft <= 0) continue;
      final track = _findFreeTrack(p.item);
      if (track >= 0) {
        _placeDanmaku(p.item, track);
      } else {
        stillPending.add(p);
      }
    }
    _pendingDanmakus
      ..clear()
      ..addAll(stillPending);
  }

  bool _shouldShow(DanmakuItem item) {
    if (!enabled) return false;
    if (item.weight < danmakuWeight) return false;
    if (blockColorful && !_isNearWhite(item.color)) return false;
    switch (effectiveMode(item)) {
      case DanmakuMode.scrollRightToLeft:
      case DanmakuMode.reverseScroll:
        return showScroll;
      case DanmakuMode.top:
        return showTop;
      case DanmakuMode.bottom:
        return showBottom;
      case DanmakuMode.advanced:
        return showAdvanced;
      case DanmakuMode.code:
        return false;
      default:
        return false;
    }
  }

  /// 固定弹幕（顶部/底部）转滚动时的有效模式。
  DanmakuMode effectiveMode(DanmakuItem item) {
    if (static2Scroll &&
        (item.mode == DanmakuMode.top || item.mode == DanmakuMode.bottom)) {
      return DanmakuMode.scrollRightToLeft;
    }
    return item.mode;
  }

  bool _isNearWhite(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return rgb >= 0xE0E0E0;
  }

  void _spawnDanmaku(DanmakuItem item) {
    // BAS 高级弹幕走独立通道
    if (item.mode == DanmakuMode.advanced) {
      _spawnBasDanmaku(item);
      return;
    }

    final track = _findFreeTrack(item);
    if (track < 0) {
      // 轨道全满 → 放入待重试队列
      if (_pendingDanmakus.length < _maxPending) {
        _pendingDanmakus.add(
          _PendingItem(item: item, retriesLeft: _maxRetries),
        );
      }
      return;
    }
    _placeDanmaku(item, track);
  }

  /// 将弹幕放入活跃列表并锁定轨道
  void _placeDanmaku(DanmakuItem item, int track) {
    final mode = effectiveMode(item);
    double x;
    switch (mode) {
      case DanmakuMode.scrollRightToLeft:
        x = screenWidth;
        break;
      case DanmakuMode.reverseScroll:
        x = -_estimateTextWidth(item);
        break;
      default:
        x = 0;
    }

    _activeDanmakus.add(
      ActiveDanmaku(item: item, track: track, startTime: _currentTime, x: x),
    );

//  核心修复：轨道占用时间 = 文字宽度滚过入口 + 小间隔
    final textWidth = _estimateTextWidth(item);
    switch (mode) {
      case DanmakuMode.scrollRightToLeft:
      case DanmakuMode.reverseScroll:
        final passTime = textWidth / scrollSpeed + _trackGap;
        _scrollTrackFreeTime[track] = _currentTime + passTime;
        break;
      case DanmakuMode.top:
        _topTrackFreeTime[track] = _currentTime + staticDuration;
        break;
      case DanmakuMode.bottom:
        _bottomTrackFreeTime[track] = _currentTime + staticDuration;
        break;
      default:
        break;
    }
  }

  void _spawnBasDanmaku(DanmakuItem item) {
    if (item.advancedType != AdvancedDanmakuType.bas) return;
    final bas = BasDanmaku.tryParse(item.content, _currentTime);
    if (bas == null) return;
    if (_activeBasDanmakus.length >= maxActiveBas) return;
    _activeBasDanmakus.add(bas);
  }

///  轮询式轨道分配：从上次分配的下一条轨道开始找，
  ///   保证弹幕均匀分布在整个屏幕，而非全挤在第 0 行。
  int _findFreeTrack(DanmakuItem item) {
    final Map<int, double> map;
    int lastTrack;
    final mode = effectiveMode(item);

    switch (mode) {
      case DanmakuMode.scrollRightToLeft:
      case DanmakuMode.reverseScroll:
        map = _scrollTrackFreeTime;
        lastTrack = _lastScrollTrack;
        break;
      case DanmakuMode.top:
        map = _topTrackFreeTime;
        lastTrack = _lastTopTrack;
        break;
      case DanmakuMode.bottom:
        map = _bottomTrackFreeTime;
        lastTrack = _lastBottomTrack;
        break;
      default:
        return -1;
    }

    // 从上次分配轨道的下一位开始轮询
    final start = (lastTrack + 1) % maxLines;
    for (int j = 0; j < maxLines; j++) {
      final i = (start + j) % maxLines;
      final freeTime = map[i] ?? 0.0;
      if (_currentTime >= freeTime) {
        // 更新轮询指针
        switch (mode) {
          case DanmakuMode.scrollRightToLeft:
          case DanmakuMode.reverseScroll:
            _lastScrollTrack = i;
            break;
          case DanmakuMode.top:
            _lastTopTrack = i;
            break;
          case DanmakuMode.bottom:
            _lastBottomTrack = i;
            break;
          default:
            break;
        }
        return i;
      }
    }
    return -1;
  }

  double _estimateTextWidth(DanmakuItem item) {
    final fs = effectiveFontSize;
    double width = 0;
    for (final ch in item.content.runes) {
      if (ch > 0x2E80) {
        width += fs; // CJK 全角
      } else if (ch > 0x7F) {
        width += fs * 0.8; // 其他非 ASCII
      } else {
        width += fs * 0.55; // ASCII 半角
      }
    }
    return width + 8;
  }

  List<ActiveDanmaku> get activeDanmakus => _activeDanmakus;
  List<BasDanmaku> get activeBasDanmakus => _activeBasDanmakus;
  double get currentTime => _currentTime;
  int get itemCount => _items.length;
  bool get isPlaying => _isPlaying;

  /// 全量弹幕（按时间升序，含被云屏蔽 / 类型过滤掉的），
  List<DanmakuItem> get items => List.unmodifiable(_items);

  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    _activeDanmakus.clear();
    _activeBasDanmakus.clear();
    _pendingDanmakus.clear();
    _personMask?.dispose();
    _personMask = null;
  }
}
