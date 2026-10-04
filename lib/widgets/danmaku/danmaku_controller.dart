             
  
                                                         
                                                            
                                              
         
                                                
                                            
                                    
import 'dart:convert';
import 'dart:ui';

import 'package:canvas_danmaku/canvas_danmaku.dart' as canvas;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'danmaku_bas_model.dart';
import 'danmaku_model.dart';

class DanmakuController {
                                                                     
            
                                                                     

                                                            
  canvas.DanmakuController<Object?>? _native;

                                 
  bool get isAttached => _native != null;

                                                    
  void attachNative(canvas.DanmakuController<Object?> native) {
    _native = native;
    native.updateOption(option);
                                 
    native.clear();
    _activeBasDanmakus.clear();
    _nextIndex = _lowerBound(_currentTime - _seekReplayWindow);
    if (_isPlaying) {
      native.resume();
    } else {
      native.pause();
    }
    onNeedRepaint?.call();
  }

                                                    
     
                                            
                                                           
                                         
  void detachNative([canvas.DanmakuController<Object?>? native]) {
    if (native != null && !identical(_native, native)) return;
    _native = null;
  }

                                    
  canvas.DanmakuOption get option => canvas.DanmakuOption(
        fontSize: effectiveFontSize,
        fontWeight: fontWeight.round().clamp(0, 8),
        area: showArea.clamp(0.1, 1.0),
        duration: _effectiveScrollDuration,
        staticDuration: staticDuration.clamp(0.5, 60.0),
        opacity: opacity.clamp(0.0, 1.0),
        hideTop: !showTop,
        hideBottom: !showBottom,
        hideScroll: !showScroll,
        hideSpecial: !showAdvanced,
        strokeWidth: strokeWidth.clamp(0.0, 8.0),
        massiveMode: massiveMode,
        safeArea: safeArea,
        lineHeight: lineHeightScale.clamp(1.0, 3.0),
      );

                                              
  double get _effectiveScrollDuration {
    final s = speed <= 0 ? 1.0 : speed;
    return (scrollDuration / s).clamp(0.5, 120.0);
  }

  void _pushOption() {
    _native?.updateOption(option);
  }

                                                                     
                              
                                                                     

  double _speed = 1.0;
                     
  double get speed => _speed;
  set speed(double value) {
    if (_speed == value) return;
    _speed = value;
    _pushOption();
  }

  double _opacity = 1.0;
  double get opacity => _opacity;
  set opacity(double value) {
    if (_opacity == value) return;
    _opacity = value;
    _pushOption();
  }

  double _fontSizeScale = 1.0;
              
  double get fontSizeScale => _fontSizeScale;
  set fontSizeScale(double value) {
    if (_fontSizeScale == value) return;
    _fontSizeScale = value;
    _refreshDerivedTracks();
    _pushOption();
  }

  double _fontSizeScaleFS = 1.2;
             
  double get fontSizeScaleFS => _fontSizeScaleFS;
  set fontSizeScaleFS(double value) {
    if (_fontSizeScaleFS == value) return;
    _fontSizeScaleFS = value;
    _refreshDerivedTracks();
    _pushOption();
  }

  double _fontWeight = 6.0;
                            
  double get fontWeight => _fontWeight;
  set fontWeight(double value) {
    if (_fontWeight == value) return;
    _fontWeight = value;
    _pushOption();
  }

  double _strokeWidth = 2.0;
             
  double get strokeWidth => _strokeWidth;
  set strokeWidth(double value) {
    if (_strokeWidth == value) return;
    _strokeWidth = value;
    _pushOption();
  }

  double _showArea = 1.0;
                    
  double get showArea => _showArea;
  set showArea(double value) {
    if (_showArea == value) return;
    _showArea = value;
    _refreshDerivedTracks();
    _pushOption();
  }

  double _lineHeightScale = 1.6;
                   
  double get lineHeightScale => _lineHeightScale;
  set lineHeightScale(double value) {
    if (_lineHeightScale == value) return;
    _lineHeightScale = value.clamp(1.0, 3.0);
    _refreshDerivedTracks();
    _pushOption();
  }

  double _scrollDuration = 7.0;
                  
  double get scrollDuration => _scrollDuration;
  set scrollDuration(double value) {
    if (_scrollDuration == value) return;
    _scrollDuration = value;
    _pushOption();
  }

  double _staticDuration = 4.0;
                     
  double get staticDuration => _staticDuration;
  set staticDuration(double value) {
    if (_staticDuration == value) return;
    _staticDuration = value;
    _pushOption();
  }

  bool _showScroll = true;
  bool get showScroll => _showScroll;
  set showScroll(bool value) {
    if (_showScroll == value) return;
    _showScroll = value;
    _pushOption();
  }

  bool _showTop = true;
  bool get showTop => _showTop;
  set showTop(bool value) {
    if (_showTop == value) return;
    _showTop = value;
    _pushOption();
  }

  bool _showBottom = true;
  bool get showBottom => _showBottom;
  set showBottom(bool value) {
    if (_showBottom == value) return;
    _showBottom = value;
    _pushOption();
  }

  bool _showAdvanced = true;
  bool get showAdvanced => _showAdvanced;
  set showAdvanced(bool value) {
    if (_showAdvanced == value) return;
    _showAdvanced = value;
    if (!value) _activeBasDanmakus.clear();
    _pushOption();
    onNeedRepaint?.call();
  }

  bool _massiveMode = false;
                          
  bool get massiveMode => _massiveMode;
  set massiveMode(bool value) {
    if (_massiveMode == value) return;
    _massiveMode = value;
    _refreshDerivedTracks();
    _pushOption();
  }

  bool _static2Scroll = false;
              
  bool get static2Scroll => _static2Scroll;
  set static2Scroll(bool value) {
    if (_static2Scroll == value) return;
    _static2Scroll = value;
  }

  bool _blockColorful = false;
                      
  bool get blockColorful => _blockColorful;
  set blockColorful(bool value) {
    if (_blockColorful == value) return;
    _blockColorful = value;
  }

  int _danmakuWeight = 0;
                         
  int get danmakuWeight => _danmakuWeight;
  set danmakuWeight(int value) {
    if (_danmakuWeight == value) return;
    _danmakuWeight = value;
  }

  bool _enabled = true;
            
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    if (!value) {
      _native?.clear();
      _activeBasDanmakus.clear();
    } else {
                                      
      _reseed(_currentTime);
    }
  }

  bool _isFullscreen = false;
  bool get isFullscreen => _isFullscreen;
  set isFullscreen(bool value) {
    if (_isFullscreen == value) return;
    _isFullscreen = value;
    _refreshDerivedTracks();
    _pushOption();
  }

                                                 
  bool safeArea = true;

                                                                     
                 
                                                                     

                                    
  bool smartMask = false;

  Image? _personMask;

                                          
  Image? get personMask => _personMask;

                                  
  void setPersonMask(Image? image) {
    final old = _personMask;
    if (old == image) return;
    _personMask = image;
    old?.dispose();
    if (smartMask) onNeedRepaint?.call();
  }

                                                                     
             
                                                                     

                                               
  static const double baseFontSize = 15.0;

  double get activeFontSizeScale =>
      isFullscreen ? fontSizeScaleFS : fontSizeScale;

                              
  double get effectiveFontSize => baseFontSize * activeFontSizeScale;

                                           
  double screenWidth = 0;
  double screenHeight = 0;

                                     
  double get usableHeight => screenHeight * showArea;

  int _maxLines = 12;
                                      
  int get maxLines => _maxLines;
  set maxLines(int value) {
    final v = value.clamp(3, 48);
    if (_maxLines == v) return;
    _maxLines = v;
                                        
    if (screenHeight > 0 && effectiveFontSize > 0) {
      lineHeightScale = usableHeight / (v * effectiveFontSize);
    }
  }

                                   
     
                                                                  
                          
  double get lineHeight => effectiveFontSize * _lineHeightScale;

                                
  set lineHeight(double value) {
    if (effectiveFontSize <= 0) return;
    lineHeightScale = value / effectiveFontSize;
  }

  void setSize(double width, double height) {
    if (screenWidth == width && screenHeight == height) return;
    screenWidth = width;
    screenHeight = height;
    _refreshDerivedTracks();
  }

                                          
  void _refreshDerivedTracks() {
    if (screenHeight <= 0 || effectiveFontSize <= 0) return;
    final usable = usableHeight;
    final rawLines =
        (usable / (effectiveFontSize * _lineHeightScale)).floor();
    _maxLines = rawLines.clamp(8, massiveMode ? 48 : 24);
  }

                                                                     
         
                                                                     

  List<DanmakuItem> _items = [];

                                              
                                        
  bool _hasTimeline = false;

  final List<BasDanmaku> _activeBasDanmakus = [];

  int _nextIndex = 0;

                                    
  double get trackGap => massiveMode ? 0.1 : 0.3;

                                      
                       
  static const double _seekReplayWindow = 1.0;

                    
  static const int maxActiveBas = 8;

  Ticker? _ticker;
  double _lastElapsed = 0;
  double _currentTime = 0;
  bool _isPlaying = false;
  double _syncTarget = -1;

  VoidCallback? onNeedRepaint;

  void setItems(List<DanmakuItem> items) {
                                       
                                     
    _items = List.of(items);
    _items.sort((a, b) => a.time.compareTo(b.time));
    _hasTimeline = true;
    _logAdvancedStats();
                                              
    _activeBasDanmakus.clear();
    _nextIndex = 0;
    _currentTime = 0;
    _lastElapsed = 0;
    _syncTarget = -1;
    _native?.clear();
    onNeedRepaint?.call();
  }

                                       
  void addItem(DanmakuItem item) {
    if (_hasTimeline) {
      final idx = _lowerBound(item.time);
      _items.insert(idx, item);
      if (idx < _nextIndex) _nextIndex++;
    }
                         
    if (item.time <= _currentTime + 0.05) {
      _emit(item);
      onNeedRepaint?.call();
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
    debugPrint('╚══════════════════════════════════════════════╝');
  }

                                       
  void reset() {
    _activeBasDanmakus.clear();
    _nextIndex = _lowerBound(_currentTime);
    _syncTarget = -1;
    _native?.clear();
    onNeedRepaint?.call();
  }

                                 
  void _reseed(double timeSeconds) {
    _activeBasDanmakus.clear();
    _native?.clear();
    _currentTime = timeSeconds;
    _nextIndex = _lowerBound(timeSeconds - _seekReplayWindow);
    _syncTarget = -1;
  }

  void play() {
    if (_isPlaying) return;
    _isPlaying = true;
    _lastElapsed = 0;
    _native?.resume();
    _ticker ??= Ticker(_onTick);
    if (!_ticker!.isActive) _ticker!.start();
  }

  void pause() {
    _isPlaying = false;
    _lastElapsed = 0;
    _native?.pause();
    _ticker?.stop();
  }

                           
  void syncTime(double timeSeconds) {
    _syncTarget = timeSeconds;
  }

                       
  void seekTo(double timeSeconds) {
    _reseed(timeSeconds);
    onNeedRepaint?.call();
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

  void _onTick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6;
    final dt = now - _lastElapsed;
    _lastElapsed = now;
    if (dt > 0 && dt < 1.0) {
      _update(dt);
    }
    onNeedRepaint?.call();
  }

  void _update(double dt) {
    if (!_isPlaying) return;
    _currentTime += dt;

    if (_syncTarget >= 0) {
      final diff = _syncTarget - _currentTime;
      if (diff.abs() > 2.0) {
                                      
        _reseed(_syncTarget);
        return;
      } else if (diff.abs() > 0.05) {
        _currentTime += diff * 0.4;
      }
      _syncTarget = -1;
    }

                          
    while (_nextIndex < _items.length &&
        _items[_nextIndex].time <= _currentTime) {
      final item = _items[_nextIndex];
      _nextIndex++;
      _emit(item);
    }

                         
    for (final bas in _activeBasDanmakus) {
      if (bas.finished) continue;
      if (_currentTime - bas.startTime > bas.totalDuration + 0.5) {
        bas.finished = true;
      }
    }
    _activeBasDanmakus.removeWhere((b) => b.finished);
  }

                             
  void _emit(DanmakuItem item) {
    if (!_shouldShow(item)) return;
    if (item.mode == DanmakuMode.advanced) {
      _spawnBasDanmaku(item);
      return;
    }
    final native = _native;
    if (native == null) return;
    native.addDanmaku(
      canvas.DanmakuContentItem<Object?>(
        item.content,
        color: item.color,
        type: _contentType(item),
                           
        count: item.count > 1 ? item.count : null,
      ),
    );
  }

  canvas.DanmakuItemType _contentType(DanmakuItem item) {
    switch (effectiveMode(item)) {
      case DanmakuMode.top:
        return canvas.DanmakuItemType.top;
      case DanmakuMode.bottom:
        return canvas.DanmakuItemType.bottom;
      default:
        return canvas.DanmakuItemType.scroll;
    }
  }

  bool _shouldShow(DanmakuItem item) {
    if (!enabled) return false;
    if (item.weight < danmakuWeight) return false;
    if (blockColorful && !_isNearWhite(item.color)) return false;
    return switch (effectiveMode(item)) {
      DanmakuMode.scrollRightToLeft || DanmakuMode.reverseScroll => showScroll,
      DanmakuMode.top => showTop,
      DanmakuMode.bottom => showBottom,
      DanmakuMode.advanced => showAdvanced,
      DanmakuMode.code => false,
    };
  }

                           
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

  void _spawnBasDanmaku(DanmakuItem item) {
    if (item.advancedType != AdvancedDanmakuType.bas) return;
    if (_activeBasDanmakus.length >= maxActiveBas) return;
    final bas = BasDanmaku.tryParse(item.content, _currentTime);
    if (bas == null) return;
    _activeBasDanmakus.add(bas);
  }

                                                                     
          
                                                                     

  List<BasDanmaku> get activeBasDanmakus => _activeBasDanmakus;
  double get currentTime => _currentTime;
  int get itemCount => _items.length;
  bool get isPlaying => _isPlaying;

                                 
  List<DanmakuItem> get items => List.unmodifiable(_items);

                                                                     
                            
                                                                     

  static const String _prefsKey = 'danmaku_settings_v1';

                                             
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
                                          
      _refreshDerivedTracks();
      onNeedRepaint?.call();
    } catch (e) {
      debugPrint('[Danmaku] 恢复弹幕设置失败: $e');
    }
  }

  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    _native = null;
    _activeBasDanmakus.clear();
    _personMask?.dispose();
    _personMask = null;
  }
}
