// lib/screens/about_page.dart
//
// 关于页 / 我的设备 - MIUI 风格，重构自 settings_split_screen 占位
// 设计参考：
//  - 顶部 ExpressiveSliverAppBar（折叠毛玻璃，与设置/搜索页一致）
//  - 顶部 2 列卡片：左大卡 = Navi 版本 + 形象；右上 = 用户名称；右下 = 存储空间液体卡片
//  - 下方白色大卡：设备参数网格（双列 + 底部通栏摄像头）
//  - B 站搜索/视频页动态卡片：所有卡片均套 MetroTileInteraction（边缘倾斜 + 缩放）
//  - 顶部三张入口卡使用视频页同款 iOS 景深转场
//  - 存储液体：应用实际占用量作为水量 + 双波叠加 + 加速度/陀螺仪/摇晃
//    三源融合物理；设备倒置时水体翻到上方，无传感器时保留呼吸波纹
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../build_info.g.dart';
import '../l10n/app_localizations.dart';
import '../services/image_cache_service.dart';
import '../services/lnative_bridge.dart';
import '../services/settings_service.dart';
import '../services/video_cache_service.dart';
import '../widgets/MetroTile.dart';
import '../widgets/danmaku/danmaku_fetcher.dart';
import '../widgets/expressive_app_bar.dart';
import '../widgets/frosted_route.dart';
import '../widgets/ios_backdrop.dart';
import '../widgets/morph_card.dart';
import '../widgets/page_background.dart';
import 'log_viewer_page.dart';
import 'open_source_licenses_page.dart';
import 'storage_settings_screen.dart';
import 'update_page.dart';
import 'user_profile_page.dart';

class AboutPage extends StatefulWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const AboutPage({super.key, this.isSplitView = false, this.onBack});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with TickerProviderStateMixin {
  // 液面是应用占用的独立视觉刻度，不直接把几十 GB 的设备容量压缩成
  // 一条几乎看不见的水线；卡片文字仍展示精确的实际字节数。
  static const int _waterReferenceBytes = 2 * 1024 * 1024 * 1024;

  late final AnimationController _waveCtrl;
  late final Ticker _physicsTicker;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<UserAccelerometerEvent>? _userAccelSub;
  Timer? _sensorTimeoutTimer;

  // 物理滤波后的倾斜（-1..1）与速度、晃动
  double _tiltX = 0;
  double _tiltY = 0;
  double _targetTiltX = 0;
  double _targetTiltY = 0;
  double _velX = 0;
  double _velY = 0;
  double _shake = 0; // 0..1 晃动强度
  // 重力低通基线：加速度计瞬时值偏离基线的部分即线性运动分量，
  // 用于在没有线性加速度传感器（TYPE_LINEAR_ACCELERATION）的机型上兜底检测摇晃
  double _gravBaseX = 0;
  double _gravBaseY = 0;
  double _gravBaseZ = 9.8;
  double _gravityZ = 0;
  bool _hasMotionSensor = false;
  bool _sensorActive = false;
  Duration _lastPhysicsTick = Duration.zero;

  // 设备信息（异步加载）
  Map<String, String>? _deviceSpecs;
  String? _deviceError;

  // 存储空间：真实设备总/已用/可用 + 应用占用
  int? _deviceTotalBytes;
  int? _deviceFreeBytes;
  int? _deviceUsedBytes;
  bool _storageLoading = true;
  String _storageUsedText = '—';
  String _appUsedText = '—';
  String _deviceFreeText = '—';
  double _storageProgress = 0.0;
  String? _storageError;
  // 深度扫描代际：离开页面/重新加载时使旧的目录遍历自行终止
  int _deepScanGeneration = 0;

  // 彩蛋：连点标题
  int _titleTapCount = 0;
  DateTime _lastTitleTap = DateTime(2000);

  void _onTitleTap() {
    final now = DateTime.now();
    if (now.difference(_lastTitleTap).inMilliseconds > 800) {
      _titleTapCount = 0;
    }
    _lastTitleTap = now;
    _titleTapCount++;
    if (_titleTapCount >= 7) {
      _titleTapCount = 0;
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'zh'
                  ? '🎉 发现彩蛋：向芙莉莲许愿吧！'
                  : '🎉 Easter egg: Make a wish to Frieren!',
            ),
            duration: const Duration(milliseconds: 1400),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _physicsTicker = createTicker(_onPhysicsTick);
    // 传感器：尝试在所有非 Web 平台监听，1.5s 内无事件则只关闭物理跟随
    if (!kIsWeb) {
      _initSensors();
    }
    // 波纹相位循环：有传感器时叠加物理倾斜；无传感器时保留轻微水面波纹
    _waveCtrl.repeat();
    _loadDeviceSpecs();
    _loadStorageInfo();
  }

  void _initSensors() {
    // 预设待检测，实际是否支持由事件到达决定
    _hasMotionSensor = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    // 即使桌面也尝试监听，部分二合一平板/带陀螺仪的 Windows 设备会生效
    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(_onAccelerometer, onError: (_) {}, cancelOnError: false);
    } catch (_) {}

    try {
      _gyroSub = gyroscopeEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(_onGyro, onError: (_) {}, cancelOnError: false);
    } catch (_) {}

    try {
      _userAccelSub = userAccelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(_onUserAccel, onError: (_) {}, cancelOnError: false);
    } catch (_) {}

    // 超时检测：1.6s 内无任何传感器事件则判定为无传感器，保留水面呼吸波纹
    _sensorTimeoutTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!_sensorActive) {
        if (mounted) {
          setState(() => _hasMotionSensor = false);
        } else {
          _hasMotionSensor = false;
        }
        _physicsTicker.stop();
        _accelSub?.cancel();
        _gyroSub?.cancel();
        _userAccelSub?.cancel();
      } else {
        // 有传感器：确保物理循环运行
        if (!_physicsTicker.isActive) _physicsTicker.start();
      }
    });

    // 若预判为移动端则提前启动物理循环，避免首帧静止
    if (_hasMotionSensor && !_physicsTicker.isActive) {
      _physicsTicker.start();
    }
  }

  /// 首个传感器事件到达：激活流体并启动物理循环
  void _activateSensors() {
    _sensorActive = true;
    if (!_hasMotionSensor) {
      _hasMotionSensor = true;
      if (mounted) setState(() {});
      if (!_waveCtrl.isAnimating) _waveCtrl.repeat();
    }
    if (!_physicsTicker.isActive) _physicsTicker.start();
  }

  /// 晃动强度低通滤波：快速上升（砸到峰值）、缓慢回落，让液面"泼一下再平息"
  void _feedShake(double target) {
    final t = target.clamp(0.0, 1.0);
    if (t > _shake) {
      _shake = _shake * 0.5 + t * 0.5;
    } else {
      _shake = _shake * 0.90 + t * 0.10;
    }
    _shake = _shake.clamp(0.0, 1.0);
  }

  void _onAccelerometer(AccelerometerEvent e) {
    _activateSensors();
    // 用归一化重力向量计算液面倾角；设备旋转到倒置方向时，向量符号
    // 也会随之翻转，水面因此会跟着倒过来，而不是只做左右摆动。
    final gravity = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    final gravityScale = gravity > 0.1 ? gravity : 9.8;
    final tx = (-e.x / gravityScale).clamp(-1.0, 1.0);
    final ty = (e.y / gravityScale).clamp(-1.0, 1.0);
    final tz = (e.z / gravityScale).clamp(-1.0, 1.0);
    _targetTiltX = (tx * 0.92).clamp(-0.9, 0.9);
    _targetTiltY = (ty * 0.92).clamp(-0.9, 0.9);
    _gravityZ += (tz - _gravityZ) * 0.12;

    // 低通估计重力基线；瞬时值偏离基线 = 线性加速度（摇晃/甩动）
    const k = 0.04;
    _gravBaseX += (e.x - _gravBaseX) * k;
    _gravBaseY += (e.y - _gravBaseY) * k;
    _gravBaseZ += (e.z - _gravBaseZ) * k;
    final dx = e.x - _gravBaseX;
    final dy = e.y - _gravBaseY;
    final dz = e.z - _gravBaseZ;
    final linMag = math.sqrt(dx * dx + dy * dy + dz * dz);
    // 约 8 m/s² 的突变即明显晃动
    _feedShake(linMag / 8.0);
    // 线性运动给液面惯性冲量（x → 左右晃、y → 前后坡度）
    _velX += ((dx / 9.8).clamp(-2.2, 2.2)) * 0.05;
    _velY += ((dy / 9.8).clamp(-2.2, 2.2)) * 0.05;
  }

  void _onGyro(GyroscopeEvent e) {
    _activateSensors();
    // 角速度直接转成液面切向惯性：转动手机＝转动杯子里的水
    _velX += e.y * 0.022;
    _velY += e.x * 0.022;
    final omega = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    // 快速甩动角速度通常 >6 rad/s
    _feedShake(omega / 6.0);
  }

  void _onUserAccel(UserAccelerometerEvent e) {
    _activateSensors();
    final dx = e.x;
    final dy = e.y;
    final mag = math.sqrt(dx * dx + dy * dy + e.z * e.z);
    // 12 m/s² 约为剧烈晃动阈值
    _feedShake(mag / 12.0);
    _velX += ((dx / 9.8).clamp(-2.5, 2.5)) * 0.07;
    _velY += ((dy / 9.8).clamp(-2.5, 2.5)) * 0.07;
  }

  void _onPhysicsTick(Duration elapsed) {
    if (!_hasMotionSensor) return;
    final dt = _lastPhysicsTick == Duration.zero
        ? 0.016
        : (elapsed - _lastPhysicsTick).inMicroseconds / 1e6;
    _lastPhysicsTick = elapsed;
    final step = dt.clamp(0.004, 0.033);
    // 弹簧-阻尼：液体表面像被弹簧拉向重力方向，带惯性过冲
    const stiffness = 22.0;
    const damping = 5.8;
    final ax = (_targetTiltX - _tiltX) * stiffness - _velX * damping;
    final ay = (_targetTiltY - _tiltY) * stiffness - _velY * damping;
    _velX += ax * step;
    _velY += ay * step;
    // 只做衰减限幅；传感器持续注入的冲量会让液体不断翻涌
    _velX *= 0.995;
    _velY *= 0.995;
    _velX = _velX.clamp(-3.4, 3.4);
    _velY = _velY.clamp(-3.4, 3.4);
    _tiltX += _velX * step;
    _tiltY += _velY * step;
    _tiltX = _tiltX.clamp(-1.0, 1.0);
    _tiltY = _tiltY.clamp(-1.0, 1.0);
    // 晃动自然衰减（无新事件时缓慢回零）
    if (_shake > 0.01) {
      _shake *= 0.982;
      if (_shake < 0.01) _shake = 0;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadStorageInfo() async {
    if (!mounted) return;
    setState(() => _storageLoading = true);
    int? total, free, used;
    String? error;

    // 1) 设备存储：走 NativeBridge（Android StatFs / iOS FileManager / 桌面 Fallback）
    try {
      final info = await NativeBridge.getStorageInfo();
      if (info != null && (info['totalBytes'] ?? 0) > 0) {
        total = info['totalBytes'];
        free = info['freeBytes'];
        used = info['usedBytes'];
        if ((used == null || used == 0) && total != null && free != null) {
          used = total - free;
        }
      }
    } catch (e) {
      error = e.toString();
    }

    // 2) 应用占用·快速阶段：图片缓存 + 离线视频 + 弹幕缓存（立即可见）
    int appUsed = 0;
    try {
      appUsed += await ImageCacheService.totalSize();
    } catch (_) {}
    try {
      appUsed += await VideoStreamCache.totalSize();
    } catch (_) {}
    try {
      final danmakuFiles = await DanmakuCacheManager.listCachedFiles();
      for (final f in danmakuFiles) {
        try {
          appUsed += await f.length();
        } catch (_) {}
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _storageLoading = false;
      _storageError = error;
      _applyStorage(total: total, free: free, used: used, appUsed: appUsed);
    });

    // 3) 应用占用·深度阶段：遍历应用私有目录（含数据库/webview/代码缓存等，
    //    尽量对齐系统"应用信息-存储空间"统计范围），后台完成后覆盖刷新。
    _deepScanGeneration++;
    final gen = _deepScanGeneration;
    int deepUsed = 0;
    try {
      final roots = <Directory>[];

      void addRoot(Directory root) {
        if (!roots.any((item) => item.path == root.path)) roots.add(root);
      }

      if (!kIsWeb &&
          !Platform.isWindows &&
          !Platform.isMacOS &&
          !Platform.isLinux) {
        // Android: <pkg>/app_flutter 的父级 = /data/user/0/<pkg>（应用数据根目录）
        // iOS: <沙盒>/Documents 的父级 = 沙盒容器根目录
        // 只取一级父目录，绝不能越出应用私有目录，否则会撞上其他应用的权限拒绝
        final doc = await getApplicationDocumentsDirectory();
        addRoot(doc.parent);
      } else if (!kIsWeb) {
        // 桌面端没有可安全遍历的父目录，分别统计应用自己的 support/cache/
        // documents/temp 目录，避免把用户整个 Documents 目录算进应用占用。
        addRoot(await getApplicationSupportDirectory());
        addRoot(await getApplicationCacheDirectory());
        addRoot(await getApplicationDocumentsDirectory());
        addRoot(await getTemporaryDirectory());
      }

      final timeoutMs = roots.length == 1 ? 8000 : 2500;
      for (final root in roots) {
        deepUsed += await _calcDirSize(
          root,
          timeoutMs: timeoutMs,
          generation: gen,
        );
      }
    } catch (_) {}
    if (deepUsed > appUsed && gen == _deepScanGeneration && mounted) {
      setState(() {
        _appUsedText = _formatBytes(deepUsed);
        _storageProgress = _appWaterProgress(deepUsed, _deviceTotalBytes);
      });
    }
  }

  /// 把一次存储读取结果应用到展示文案
  void _applyStorage({
    required int? total,
    required int? free,
    required int? used,
    required int appUsed,
  }) {
    _appUsedText = _formatBytes(appUsed);
    if (total != null && total > 0) {
      _deviceTotalBytes = total;
      _deviceFreeBytes = free ?? (total - (used ?? 0));
      _deviceUsedBytes = used ?? (total - _deviceFreeBytes!);
      _storageUsedText = _formatBytesGB(_deviceUsedBytes!);
      _deviceFreeText = _formatBytesGB(_deviceFreeBytes!);
      _storageProgress = _appWaterProgress(appUsed, total);
    } else {
      // 无设备存储信息（Web 或权限受限）：仍只展示应用占用。
      _deviceTotalBytes = null;
      _deviceFreeBytes = null;
      _deviceUsedBytes = null;
      _storageUsedText = '—';
      _deviceFreeText = '—';
      _storageProgress = _appWaterProgress(appUsed, null);
    }
  }

  /// 水面高度使用应用占用的可读视觉刻度；具体占用仍以卡片文字为准。
  /// 2 GiB 只作为液体容器的参考容量，避免 100 MB 应用在 128 GB 设备上
  /// 被压成不可见的一条线。
  double _appWaterProgress(int appUsed, int? deviceTotal) {
    if (appUsed <= 0) return 0.0;
    final capacity = deviceTotal != null && deviceTotal > 0
        ? math.min(deviceTotal, _waterReferenceBytes)
        : _waterReferenceBytes;
    return (appUsed / capacity).clamp(0.0, 0.96).toDouble();
  }

  Future<int> _calcDirSize(
    Directory dir, {
    int timeoutMs = 1500,
    int? generation,
  }) async {
    var total = 0;
    try {
      final future = () async {
        await for (final e in dir.list(recursive: true, followLinks: false)) {
          // 代际失效：页面离开或重新加载后立即停止遍历，避免后台空转
          if (generation != null && generation != _deepScanGeneration) break;
          if (e is File) {
            try {
              total += await e.length();
            } catch (_) {}
          }
        }
        return total;
      }();
      // 超时时返回已累计的部分值，而不是丢弃成果
      return await future.timeout(
        Duration(milliseconds: timeoutMs),
        onTimeout: () => total,
      );
    } catch (_) {
      return total;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    final gb = bytes / (1024 * 1024 * 1024);
    if (gb >= 1) {
      if (gb >= 10) return '${gb.toStringAsFixed(1)} GB';
      return '${gb.toStringAsFixed(2)} GB';
    }
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    final kb = bytes / 1024;
    if (kb >= 1) return '${kb.toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  String _formatBytesGB(int bytes) {
    final gb = bytes / (1024 * 1024 * 1024);
    if (gb >= 10) return '${gb.toStringAsFixed(1)} GB';
    if (gb >= 1) return '${gb.toStringAsFixed(2)} GB';
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }

  Future<void> _loadDeviceSpecs() async {
    try {
      final plugin = DeviceInfoPlugin();
      final map = <String, String>{};
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        map['model'] = info.model;
        map['brand'] = info.brand;
        map['manufacturer'] = info.manufacturer;
        map['os'] =
            'Android ${info.version.release} (SDK ${info.version.sdkInt})';
        map['display'] = info.display;
        map['fingerprint'] = info.fingerprint;
        map['board'] = info.board;
        map['hardware'] = info.hardware;
        map['supportedAbis'] = info.supportedAbis.join(', ');
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        map['model'] = info.model;
        map['brand'] = 'Apple';
        map['os'] = '${info.systemName} ${info.systemVersion}';
        map['name'] = info.name;
        map['identifierForVendor'] = info.identifierForVendor ?? '';
      } else if (Platform.isWindows) {
        final info = await plugin.windowsInfo;
        map['model'] = info.computerName;
        map['brand'] = 'Windows';
        map['os'] = '${info.productName} ${info.displayVersion}'.trim();
        map['buildNumber'] = info.buildNumber.toString();
        map['displayVersion'] = info.displayVersion;
        map['productName'] = info.productName;
      } else if (Platform.isMacOS) {
        final info = await plugin.macOsInfo;
        map['model'] = info.model;
        map['brand'] = 'Apple';
        map['os'] = info.osRelease;
        map['kernel'] = info.kernelVersion;
      } else if (Platform.isLinux) {
        final info = await plugin.linuxInfo;
        map['model'] = info.prettyName;
        map['brand'] = 'Linux';
        map['os'] = info.version ?? '';
      } else {
        map['model'] = Platform.operatingSystem;
        map['os'] = Platform.operatingSystemVersion;
      }
      if (!mounted) return;
      setState(() => _deviceSpecs = map);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deviceError = e.toString());
    }
  }

  @override
  void dispose() {
    // 使仍在后台遍历的目录扫描立即终止
    _deepScanGeneration++;
    _sensorTimeoutTimer?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _userAccelSub?.cancel();
    _physicsTicker.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final title = l10n.drawerAbout;

    final scaffold = Scaffold(
      backgroundColor: widget.isSplitView
          ? Colors.transparent
          : cs.surfaceContainerLow,
      body: Stack(
        children: [
          if (!widget.isSplitView)
            PageBackground(baseColor: cs.surfaceContainerLow),
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              ExpressiveSliverAppBar(
                title: title,
                expandedHeight: 120,
                onTitleRepeatedTap: _onTitleTap,
                leading: widget.isSplitView
                    ? null
                    : MorphIconButton(
                        icon: Icons.arrow_back,
                        tooltip: l10n.startScreenGoBack,
                        onTap: _handleBack,
                      ),
                actions: [
                  MorphIconButton(
                    icon: Icons.code_rounded,
                    tooltip: l10n.settingsLicenses,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OpenSourceLicensesPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      // 窄屏（<360）纵向堆叠，否则保持 MIUI 双列
                      if (w < 360) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildNaviVersionCard(context),
                            const SizedBox(height: 12),
                            _buildUserNameCard(context),
                            const SizedBox(height: 12),
                            _buildStorageLiquidCard(context),
                          ],
                        );
                      }
                      // 右侧两卡各 112，间距 12 → 左侧大卡明确取等高 236，
                      // 避免 IntrinsicHeight+Expanded 组合在 flex 子项下高度塌缩/错位
                      const rightCardH = 112.0;
                      const gap = 12.0;
                      final leftH = rightCardH * 2 + gap;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildNaviVersionCard(
                              context,
                              height: leftH,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildUserNameCard(context),
                                const SizedBox(height: 12),
                                _buildStorageLiquidCard(context),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: _buildSpecsCard(context)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(child: _buildNaviInfoCard(context)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(child: _buildActionsCard(context)),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    // 和视频页一样参与 iOS 景深：推入版本、用户或存储子页面时，
    // 本页整体向中心缩小、渐隐并带圆角；分屏右栏也保持同样的过渡。
    return IosBackdropScale(child: scaffold);
  }

  // ───────────────── Navi 版本卡（左大卡） ─────────────────

  Widget _buildNaviVersionCard(BuildContext context, {double? height}) {
    final cs = Theme.of(context).colorScheme;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final versionLabel = isZh ? 'Navi 版本' : 'Navi Version';
    final timestamp = BuildInfo.buildTimestamp;
    final channel = BuildInfo.isDebug ? 'Debug' : 'Release';
    const appVersion = '1.2.0+20';

    Widget card = Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(kGroupRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(
              context,
            ).push(heroTransitionRoute(page: const UpdatePage()));
          },
          onLongPress: () {
            Clipboard.setData(
              ClipboardData(text: 'Navi $appVersion $timestamp $channel'),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isZh ? '版本信息已复制' : 'Version copied'),
                duration: const Duration(milliseconds: 1200),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          borderRadius: BorderRadius.circular(kGroupRadius),
          child: Stack(
            children: [
              // 右下角淡化水印，撑满大卡视觉，避免中部留白
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 104,
                  color: cs.primary.withOpacity(0.10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部品牌区（填满上半部分）
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_fill_rounded,
                          size: 26,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Navi',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                            letterSpacing: 0.5,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 底部版本信息（填满下半部分）
                    Text(
                      versionLabel,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'V$appVersion · $channel',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant.withOpacity(0.85),
                      ),
                    ),
                    Text(
                      timestamp,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
  }

  // ───────────────── 用户名称卡（右上） ─────────────────

  Widget _buildUserNameCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsService>();
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final label = isZh ? '用户名称' : 'User Name';
    final nickname = settings.nickname?.isNotEmpty == true
        ? settings.nickname!
        : AppLocalizations.of(context).drawerNoNickname;

    Widget card = Container(
      // 恢复原来大小：与图2一致，内边距 16，高度自适应两行文字
      // 用固定 112 高度保证与存储卡组合后与左卡等高
      height: 112,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(kGroupRadius),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(
              context,
            ).push(heroTransitionRoute(page: const UserProfilePage()));
          },
          borderRadius: BorderRadius.circular(kGroupRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
  }

  // ───────────────── 存储空间液体卡（右下） ─────────────────
  // 真实设备存储 + 应用占用 + 流体物理：
  //   - 设备存储：Android StatFs / iOS FileManager / 桌面 Fallback（真实读取）
  //   - 应用占用：image_cache + video_cache + 弹幕缓存 实时统计
  //   - 流体：加速度(重力) + 陀螺仪(旋转) + 线性加速度(晃动) 融合，弹簧阻尼物理，像液体一样晃动
  //   - 无传感器（桌面/Web）保留轻微水面波纹，不伪造设备倾斜
  Widget _buildStorageLiquidCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final label = isZh ? '存储空间' : 'Storage';
    final progress = _storageProgress;

    // 决定主副文案
    final bool hasDevice = _deviceTotalBytes != null && _deviceTotalBytes! > 0;
    final bool loading = _storageLoading;

    // 水量由应用实际占用决定；有传感器时叠加重力/惯性，无传感器时
    // 仍保留轻微波纹，避免卡片退化成一条静态色块。
    final liquid = AnimatedBuilder(
      animation: _waveCtrl,
      builder: (context, _) {
        final basePhase = _waveCtrl.value * 2 * math.pi;
        // 晃动时相位微扰，让水面产生不同步的细小波纹
        final phase = basePhase + _shake * 0.7 * math.sin(basePhase * 1.7);
        return CustomPaint(
          painter: _LiquidPainter(
            progress: progress,
            phase: phase,
            tiltX: _hasMotionSensor ? _tiltX : 0,
            tiltY: _hasMotionSensor ? _tiltY : 0,
            gravityZ: _hasMotionSensor ? _gravityZ : 0,
            velX: _hasMotionSensor ? _velX : 0,
            velY: _hasMotionSensor ? _velY : 0,
            shake: _hasMotionSensor ? _shake : 0,
            color: cs.primaryContainer.withValues(alpha: 0.82),
            color2: cs.secondaryContainer.withValues(alpha: 0.68),
          ),
          size: Size.infinite,
        );
      },
    );

    Widget card = Container(
      height: 112,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(kGroupRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(
              context,
            ).push(heroTransitionRoute(page: const StorageSettingsScreen()));
          },
          borderRadius: BorderRadius.circular(kGroupRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: RepaintBoundary(child: liquid)),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (loading) ...[
                      Text(
                        isZh ? '正在统计…' : 'Calculating…',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isZh ? '读取中' : 'Loading',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ] else ...[
                      Text(
                        isZh ? '应用占用' : 'App usage',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _appUsedText,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasDevice
                            ? (isZh
                                  ? '设备已用 $_storageUsedText · 可用 $_deviceFreeText'
                                  : 'Device $_storageUsedText used · $_deviceFreeText free')
                            : (_storageError != null
                                  ? (isZh
                                        ? '读取失败：$_storageError'
                                        : 'Error: $_storageError')
                                  : (isZh
                                        ? '设备存储暂不可用'
                                        : 'Device storage unavailable')),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.1,
                          color: cs.onSurfaceVariant.withOpacity(0.72),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Icon(
                  Icons.storage_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant.withOpacity(0.32),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
  }

  // ───────────────── 设备参数大卡（白色） ─────────────────
  // 仅展示关于对话框里能读取到的真实参数，无数据则不显示
  Widget _buildSpecsCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

    // 加载中
    if (_deviceSpecs == null && _deviceError == null) {
      final card = Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.surfaceBright,
          borderRadius: BorderRadius.circular(kGroupRadius),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: cs.primary,
              ),
            ),
          ),
        ),
      );
      return MetroTileInteraction(
        onTapStart: (_, __) {},
        showBorder: false,
        child: card,
      );
    }

    if (_deviceError != null) {
      final card = Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.surfaceBright,
          borderRadius: BorderRadius.circular(kGroupRadius),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            isZh
                ? '设备信息加载失败：$_deviceError'
                : 'Device info failed: $_deviceError',
            style: TextStyle(fontSize: 12, color: cs.error),
          ),
        ),
      );
      return MetroTileInteraction(
        onTapStart: (_, __) {},
        showBorder: false,
        child: card,
      );
    }

    final specs = _deviceSpecs!;
    // 构造可读参数列表，与 services/device.dart 的 getHostSystemInfo 保持一致
    // 若值为 Unknown/N/A/空则跳过不显示
    bool isValid(String v) {
      final t = v.trim();
      if (t.isEmpty) return false;
      if (t == 'Unknown' || t == 'N/A' || t == 'N/A'.toLowerCase())
        return false;
      return true;
    }

    final List<_SpecEntry> entries = [];

    void addIfValid(String key, IconData icon, String zhLabel, String enLabel) {
      final v = specs[key];
      if (v == null || !isValid(v)) return;
      entries.add(
        _SpecEntry(icon: icon, label: isZh ? zhLabel : enLabel, value: v),
      );
    }

    // Android
    addIfValid('model', Icons.phone_android, '手机型号', 'Model');
    addIfValid('brand', Icons.branding_watermark, '品牌', 'Brand');
    addIfValid('manufacturer', Icons.business, '制造商', 'Manufacturer');
    addIfValid('os', Icons.system_update, '系统版本', 'OS');
    addIfValid('display', Icons.display_settings, 'ROM 版本', 'ROM');
    addIfValid('fingerprint', Icons.fingerprint, '指纹', 'Fingerprint');
    addIfValid('board', Icons.developer_board, '主板', 'Board');
    addIfValid('hardware', Icons.memory, '硬件', 'Hardware');
    addIfValid('supportedAbis', Icons.architecture, '支持 ABI', 'ABI');
    // iOS
    addIfValid('name', Icons.account_circle, '设备名称', 'Device Name');
    addIfValid(
      'identifierForVendor',
      Icons.perm_device_information,
      'IDFV',
      'IDFV',
    );
    // Windows
    addIfValid('buildNumber', Icons.build, '构建号', 'Build');
    addIfValid('displayVersion', Icons.info_outline, '显示版本', 'Display Version');
    addIfValid('productName', Icons.desktop_windows, '产品名称', 'Product');
    // macOS
    addIfValid('kernel', Icons.memory, '内核', 'Kernel');
    // Linux 已在 model/os 中覆盖
    // 若仍为空，至少展示 OS
    if (entries.isEmpty) {
      final fallbackOs = specs['os'];
      if (fallbackOs != null && isValid(fallbackOs)) {
        entries.add(
          _SpecEntry(
            icon: Icons.system_update,
            label: isZh ? '系统版本' : 'OS',
            value: fallbackOs,
          ),
        );
      }
    }

    if (entries.isEmpty) return const SizedBox.shrink();

    // 2 列网格，尾行若单数则通栏展示
    List<Widget> rows = [];
    for (int i = 0; i < entries.length; i += 2) {
      final left = entries[i];
      final right = (i + 1 < entries.length) ? entries[i + 1] : null;
      if (right == null) {
        rows.add(
          _SpecItem(
            icon: left.icon,
            label: left.label,
            value: left.value,
            cs: cs,
            fullWidth: true,
          ),
        );
      } else {
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SpecItem(
                  icon: left.icon,
                  label: left.label,
                  value: left.value,
                  cs: cs,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SpecItem(
                  icon: right.icon,
                  label: right.label,
                  value: right.value,
                  cs: cs,
                ),
              ),
            ],
          ),
        );
      }
      if (i + 2 < entries.length) rows.add(const SizedBox(height: 18));
    }

    Widget card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(kGroupRadius),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );

    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: card,
    );
  }

  // ───────────────── Navi 构建信息卡 ─────────────────

  Widget _buildNaviInfoCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buildMorphSegmentedList([
        MorphRowItem(
          child: ListTile(
            leading: Icon(Icons.badge_outlined, color: cs.primary),
            title: Text(isZh ? '构建代号' : 'Codename'),
            subtitle: Text(
              BuildInfo.buildCodename,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            trailing: Icon(Icons.copy, size: 16, color: cs.onSurfaceVariant),
            onTap: () {
              Clipboard.setData(ClipboardData(text: BuildInfo.buildCodename));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isZh ? '已复制' : 'Copied'),
                  duration: const Duration(milliseconds: 900),
                ),
              );
            },
          ),
        ),
        MorphRowItem(
          child: ListTile(
            leading: Icon(Icons.schedule_outlined, color: cs.primary),
            title: Text(isZh ? '构建时间' : 'Build Time'),
            subtitle: Text(
              BuildInfo.buildTimestamp,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            trailing: Icon(Icons.copy, size: 16, color: cs.onSurfaceVariant),
            onTap: () {
              Clipboard.setData(ClipboardData(text: BuildInfo.buildTimestamp));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isZh ? '已复制' : 'Copied'),
                  duration: const Duration(milliseconds: 900),
                ),
              );
            },
          ),
        ),
        MorphRowItem(
          child: ListTile(
            leading: Icon(
              BuildInfo.isDebug
                  ? Icons.bug_report_outlined
                  : Icons.verified_outlined,
              color: cs.primary,
            ),
            title: Text(isZh ? '运行通道' : 'Channel'),
            subtitle: Text(
              BuildInfo.isDebug ? 'Debug' : 'Release',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ),
        MorphRowItem(
          child: ListTile(
            leading: Icon(Icons.info_outline, color: cs.primary),
            title: Text(isZh ? 'Flutter' : 'Flutter'),
            subtitle: Text(
              '${isZh ? '引擎' : 'Engine'} · ${isZh ? '基于 Material 3 Expressive' : 'Material 3 Expressive'}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ),
      ]),
    );
  }

  // ───────────────── 快捷操作 ─────────────────

  Widget _buildActionsCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buildMorphSegmentedList([
        MorphRowItem(
          child: ListTile(
            leading: Icon(Icons.system_update_alt_rounded, color: cs.primary),
            title: Text(isZh ? '系统更新' : 'System Update'),
            subtitle: Text(
              isZh ? '检查新版本与更新日志' : 'Check for updates and changelog',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: cs.onSurfaceVariant,
              size: 20,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const UpdatePage()));
            },
          ),
        ),
        MorphRowItem(
          child: ListTile(
            leading: Icon(Icons.code_rounded, color: cs.primary),
            title: Text(l10n.settingsLicenses),
            subtitle: Text(
              l10n.settingsLicensesSub,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: cs.onSurfaceVariant,
              size: 20,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OpenSourceLicensesPage(),
                ),
              );
            },
          ),
        ),
        MorphRowItem(
          child: ListTile(
            leading: Icon(Icons.storage_outlined, color: cs.primary),
            title: Text(l10n.settingsStorage),
            subtitle: Text(
              l10n.settingsStorageSub,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: cs.onSurfaceVariant,
              size: 20,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StorageSettingsScreen(),
                ),
              );
            },
          ),
        ),
        MorphRowItem(
          child: ListTile(
            leading: Icon(Icons.bug_report_outlined, color: cs.primary),
            title: Text(l10n.settingsLogs),
            subtitle: Text(
              l10n.settingsLogsSub,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: cs.onSurfaceVariant,
              size: 20,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LogViewerPage()));
            },
          ),
        ),
        MorphRowItem(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              isZh
                  ? 'NaviFlash 是基于 Flutter 的 B 站第三方客户端，致敬 MIUI 的“我的设备”设计。存储卡片实时读取应用实际占用空间；液面在带陀螺仪/加速度计的设备上会跟随倾斜、倒置与摇晃像液体一样翻涌。'
                  : 'NaviFlash is a Flutter Bilibili client, inspired by MIUI My Device. The storage card reads the actual app usage; the liquid tilts, flips when the device is inverted, and sloshes with motion on devices with a gyroscope/accelerometer.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: cs.onSurfaceVariant.withOpacity(0.85),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SpecEntry {
  final IconData icon;
  final String label;
  final String value;
  const _SpecEntry({
    required this.icon,
    required this.label,
    required this.value,
  });
}

/// 规格小项：图标 + 标签 + 值（双列网格使用）
class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final bool fullWidth;

  const _SpecItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 11,
      color: cs.onSurfaceVariant.withOpacity(0.70),
      height: 1.1,
    );
    final valueStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
      height: 1.25,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: cs.onSurfaceVariant.withOpacity(0.85)),
        const SizedBox(height: 8),
        Text(label, style: labelStyle),
        const SizedBox(height: 4),
        Text(
          value,
          style: valueStyle,
          maxLines: fullWidth ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (fullWidth) const SizedBox(height: 2),
      ],
    );
  }
}

/// 液体波浪绘制：纯色双波 + 物理倾斜 + 晃动，跟随 Material 主题
/// 有陀螺仪/加速度计时随重力倾斜、随晃动增幅，像真实液体一样晃动；无传感器时保留呼吸波纹
class _LiquidPainter extends CustomPainter {
  final double progress; // 0..1
  final double phase; // 0..2pi
  final double tiltX; // -1..1 来自重力 + 弹簧物理
  final double tiltY; // -1..1
  final double gravityZ; // 屏幕朝下时 < 0，用于翻转蓄水方向
  final double velX; // 惯性速度，用于增强晃动感
  final double velY;
  final double shake; // 0..1 晃动强度（userAccelerometer）
  final Color color;
  final Color color2;

  _LiquidPainter({
    required this.progress,
    required this.phase,
    required this.tiltX,
    required this.tiltY,
    required this.gravityZ,
    required this.velX,
    required this.velY,
    required this.shake,
    required this.color,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final w = size.width;
    final h = size.height;
    final fillFromTop = tiltY < -0.70 || gravityZ < -0.70;
    final waterLevel = progress.clamp(0.0, 0.96);
    if (waterLevel <= 0.0) return;
    // 正常握持时水从底部开始；设备上下倒置后改为从顶部蓄水，
    // 让整杯水连同重力方向一起翻转，而不是只改变水面斜率。
    final baseY = h * (fillFromTop ? waterLevel : 1 - waterLevel);

    // 晃动强度影响波幅与倾斜强度，像液体受惯性晃动
    final shakeClamped = shake.clamp(0.0, 1.0);
    final velMag = math.sqrt(velX * velX + velY * velY).clamp(0.0, 3.4);
    // 倾斜 = 重力倾斜 + 速度惯性 + 陀螺仪冲量（已叠入 vel）
    // 以卡片宽高作为单位，手机横向倾斜时水面能形成明显坡度；
    // 纵向倾斜则改变水面在容器内的前后晃动，倒置时同样会反向。
    final tiltOffset =
        tiltX * (w * (0.28 + shakeClamped * 0.16)) + velX * w * 0.08;
    final wobbleY =
        tiltY * (h * (0.08 + shakeClamped * 0.06)) + velY * h * 0.035;

    // 动态波幅：静止时有呼吸，移动时有明显的液体惯性与回弹。
    final amp1 = 4.5 + shakeClamped * 18 + velMag * 4.0;
    final amp2 = 3.4 + shakeClamped * 14 + velMag * 3.0;
    final freq1 = 1.25 + shakeClamped * 0.35;
    final freq2 = 1.85 + shakeClamped * 0.45;
    final phase2 = phase + 1.85 + shakeClamped * 0.6;

    // 第一层主波（primaryContainer）
    final path1 = Path();
    path1.moveTo(0, fillFromTop ? 0 : h);
    path1.lineTo(
      0,
      _waveY(0, w, baseY, tiltOffset, wobbleY, phase, amp1, freq1),
    );
    for (double x = 1; x <= w; x += 1.5) {
      final y = _waveY(x, w, baseY, tiltOffset, wobbleY, phase, amp1, freq1);
      path1.lineTo(x, y);
    }
    path1.lineTo(w, fillFromTop ? 0 : h);
    path1.close();
    final paint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.alphaBlend(Colors.white.withOpacity(0.10), color),
          color,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path1, paint1);

    // 第二层次波（secondaryContainer，稍低 6px + 轻微垂直晃动）
    final baseY2 =
        baseY +
        (fillFromTop ? -5.5 : 5.5) +
        tiltY * 1.5 +
        (fillFromTop ? -shakeClamped * 2 : shakeClamped * 2);
    final path2 = Path();
    path2.moveTo(0, fillFromTop ? 0 : h);
    path2.lineTo(
      0,
      _waveY(
        0,
        w,
        baseY2,
        tiltOffset * 0.68,
        wobbleY * 0.7,
        phase2,
        amp2,
        freq2,
      ),
    );
    for (double x = 1; x <= w; x += 1.5) {
      final y = _waveY(
        x,
        w,
        baseY2,
        tiltOffset * 0.68,
        wobbleY * 0.7,
        phase2,
        amp2,
        freq2,
      );
      path2.lineTo(x, y);
    }
    path2.lineTo(w, fillFromTop ? 0 : h);
    path2.close();
    final paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color2,
          Color.alphaBlend(Colors.black.withOpacity(0.08), color2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path2, paint2);

    // 顶部高光：沿主波顶部画一层半透明白线，增强液体光泽与“水面”感
    // 仅在非极端进度时绘制，避免顶部/底部溢出
    if (progress > 0.08 && progress < 0.92) {
      final hlPath = Path();
      hlPath.moveTo(
        0,
        _waveY(0, w, baseY, tiltOffset, wobbleY, phase, amp1, freq1),
      );
      for (double x = 1; x <= w; x += 1.5) {
        hlPath.lineTo(
          x,
          _waveY(x, w, baseY, tiltOffset, wobbleY, phase, amp1, freq1),
        );
      }
      final hlPaint = Paint()
        ..color = Colors.white.withOpacity(
          (0.22 + shakeClamped * 0.10).clamp(0.0, 0.35),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(hlPath, hlPaint);

      // 容器内的宽面反光，让水体不再像一块纯色矩形。
      final reflection = Path()
        ..moveTo(
          w * 0.18,
          _waveY(0.18 * w, w, baseY, tiltOffset, wobbleY, phase, amp1, freq1) +
              8,
        )
        ..quadraticBezierTo(
          w * 0.48,
          baseY - amp1 * 0.8,
          w * 0.78,
          _waveY(0.78 * w, w, baseY, tiltOffset, wobbleY, phase, amp1, freq1) +
              5,
        );
      final reflectionPaint = Paint()
        ..color = Colors.white.withOpacity(0.08 + shakeClamped * 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(reflection, reflectionPaint);
    }

    // 轻微晃动时也有气泡，剧烈晃动时气泡变亮、变大，增强液体感。
    if (shakeClamped > 0.16) {
      final bubblePaint = Paint()
        ..color = Colors.white.withOpacity(
          ((shakeClamped - 0.16) * 0.38).clamp(0.0, 0.28),
        )
        ..style = PaintingStyle.fill;
      final bubbleY = fillFromTop
          ? baseY + 8 + shakeClamped * 9
          : baseY - 8 - shakeClamped * 9;
      final bx1 = w * (0.32 + math.sin(phase * 0.9) * 0.08);
      final bx2 = w * (0.68 + math.cos(phase * 1.1) * 0.07);
      canvas.drawCircle(
        Offset(bx1, bubbleY + math.sin(phase * 2) * 2),
        1.8 + shakeClamped * 1.8,
        bubblePaint,
      );
      canvas.drawCircle(
        Offset(bx2, bubbleY - 3 + math.cos(phase * 2.3) * 1.5),
        1.2 + shakeClamped * 1.3,
        bubblePaint,
      );
    }
  }

  double _waveY(
    double x,
    double w,
    double baseY,
    double tiltOffset,
    double wobbleY,
    double phase,
    double amp,
    double freq,
  ) {
    final tilt = (x / w - 0.5) * tiltOffset;
    // 边缘衰减：靠近左右边缘波幅渐小，避免硬切
    final edgeFade = math.sin((x / w) * math.pi).clamp(0.0, 1.0);
    final easedAmp = amp * (0.45 + 0.55 * edgeFade);
    // 双正弦叠加的简化：主波 + 1/3 倍频的细波，让水面更自然
    final mainWave = math.sin((x / w * math.pi * 2 * freq) + phase) * easedAmp;
    // 细碎涟漪（晃动时更明显）
    final rippleAmp = easedAmp * 0.18;
    final ripple =
        math.sin((x / w * math.pi * 4 * freq) + phase * 1.6) * rippleAmp;
    return baseY + tilt + wobbleY + mainWave + ripple;
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.phase != phase ||
      oldDelegate.tiltX != tiltX ||
      oldDelegate.tiltY != tiltY ||
      oldDelegate.gravityZ != gravityZ ||
      oldDelegate.velX != velX ||
      oldDelegate.velY != velY ||
      oldDelegate.shake != shake ||
      oldDelegate.color != color ||
      oldDelegate.color2 != color2;
}
