// lib/services/dlna_cast_service.dart
// DLNA 投屏服务：封装 dlna_dart 的设备发现、投屏与控制，
import 'dart:async';
import 'package:dlna_dart/dlna.dart';
import 'package:flutter/foundation.dart';

/// 单个 DLNA 投屏设备的轻量视图模型。
class DlnaCastTarget {
  final DLNADevice device;
  final String key;
  String get friendlyName => device.info.friendlyName;
  String get deviceType => device.info.deviceType;
  String get baseUrl => device.info.URLBase;

  DlnaCastTarget(this.device, this.key);
}

class DlnaCastService extends ChangeNotifier {
  final DLNAManager _manager = DLNAManager();

  DeviceManager? _deviceManager;
  StreamSubscription<Map<String, DLNADevice>>? _devicesSub;
  StreamSubscription? _positionSub;

  final Map<String, DLNADevice> _devices = {};
  bool _isSearching = false;

  DLNADevice? _activeDevice;
  String? _activeKey;
  String? _activeUrl;
  String? _activeTitle;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _disposed = false;

  bool get isSearching => _isSearching;

  List<DlnaCastTarget> get targets =>
      _devices.entries.map((e) => DlnaCastTarget(e.value, e.key)).toList();

  bool get isCasting => _activeDevice != null;

  String? get activeKey => _activeKey;

  String? get activeDeviceName =>
      _activeDevice?.info.friendlyName ?? _activeKey;

  String? get activeUrl => _activeUrl;
  String? get activeTitle => _activeTitle;

  Duration get position => _position;
  Duration get duration => _duration;

  bool get hasDuration => _duration > Duration.zero;

  /// 开始 SSDP 搜索局域网 DLNA 设备（每 2s 轮询一次 M-SEARCH）。
  Future<void> startSearch() async {
    if (_isSearching) return;
    _isSearching = true;
    _devices.clear();
    notifyListeners();
    try {
      _deviceManager = await _manager.start(reusePort: false);
      _devicesSub?.cancel();
      _devicesSub = _deviceManager!.devices.stream.listen((deviceList) {
        _devices
          ..clear()
          ..addAll(deviceList);
        notifyListeners();
      });
    } catch (e) {
      debugPrint('❌ DLNA 搜索失败: $e');
      _isSearching = false;
      notifyListeners();
    }
  }

  void stopSearch() {
    _devicesSub?.cancel();
    _devicesSub = null;
    _manager.stop();
    _deviceManager = null;
    _isSearching = false;
    notifyListeners();
  }

  /// 把指定资源投到目标设备（切换设备时先暂停旧设备）。
  Future<bool> cast(
    DlnaCastTarget target, {
    required String url,
    String title = '',
  }) async {
    if (_activeDevice != null && _activeDevice != target.device) {
      try {
        await _activeDevice!.pause();
      } catch (_) {}
    }
    _activeDevice = target.device;
    _activeKey = target.key;
    _activeUrl = url;
    _activeTitle = title.isEmpty ? url : title;
    _position = Duration.zero;
    _duration = Duration.zero;
    _startPositionPolling();
    notifyListeners();
    try {
      await target.device.setUrl(url, title: title);
      await target.device.play();
      return true;
    } catch (e) {
      debugPrint('❌ 投屏失败: $e');
      _stopPositionPolling();
      return false;
    }
  }

  Future<void> pause() async {
    try {
      await _activeDevice?.pause();
    } catch (_) {}
  }

  Future<void> play() async {
    try {
      await _activeDevice?.play();
    } catch (_) {}
  }

  Future<void> stopCast() async {
    try {
      await _activeDevice?.stop();
    } catch (_) {}
    _activeDevice = null;
    _activeKey = null;
    _activeUrl = null;
    _activeTitle = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _stopPositionPolling();
    notifyListeners();
  }

  Future<void> seek(Duration target) async {
    final dev = _activeDevice;
    if (dev == null) return;
    final total = _duration.inSeconds;
    var s = target.inSeconds;
    if (total > 0 && s > total) s = total;
    if (s < 0) s = 0;
    try {
      await dev.seek(PositionParser2.toStr(s));
    } catch (e) {
      debugPrint('❌ DLNA seek 失败: $e');
    }
  }

  Future<void> changeVolume(int delta) async {
    try {
      await _activeDevice?.changeVolume(delta);
    } catch (_) {}
  }

  Future<int?> getCurrentVolume() async {
    try {
      final text = await _activeDevice?.getVolume();
      if (text == null || text.isEmpty) return null;
      final match = RegExp(r'<CurrentVolume>(\d+)</CurrentVolume>')
          .firstMatch(text);
      return match == null ? null : int.tryParse(match.group(1)!);
    } catch (_) {
      return null;
    }
  }

  void _startPositionPolling() {
    _stopPositionPolling();
    final dev = _activeDevice;
    if (dev == null) return;
    try {
      dev.positionPoller.start();
      _positionSub = dev.currPosition.stream.listen((p) {
        if (_disposed) return;
        _position = Duration(seconds: p.RelTimeInt);
        final dur = p.TrackDurationInt;
        if (dur > 0) _duration = Duration(seconds: dur);
        notifyListeners();
      });
    } catch (_) {}
  }

  void _stopPositionPolling() {
    _positionSub?.cancel();
    _positionSub = null;
    try {
      _activeDevice?.positionPoller.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
//  离开投屏页时同时停止电视端播放（配合本地播放器恢复，避免双端出声）
    try {
      _activeDevice?.stop();
    } catch (_) {}
    _activeDevice = null;
    _activeKey = null;
    _activeUrl = null;
    _activeTitle = null;
    _stopPositionPolling();
    stopSearch();
    super.dispose();
  }
}

/// 复刻 dlna_dart 的 PositionParser.toStr（该类型未随包导出），
/// 用于把秒数转为 "HH:MM:SS" 供 Seek 使用。
class PositionParser2 {
  static String toStr(int time) {
    final h = (time / 3600).floor();
    final m = ((time - 3600 * h) / 60).floor();
    final s = time - 3600 * h - 60 * m;
    return '${_z(h)}:${_z(m)}:${_z(s)}';
  }

  static String _z(int n) => n > 9 ? n.toString() : '0$n';
}
