// lib/screens/dlna_cast_page.dart
// DLNA 投屏页：搜索局域网投屏设备 → 选择设备投屏 → 遥控(播放/暂停/进度/音量)。
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:naviflash/services/dlna_cast_service.dart';
import 'package:naviflash/services/dlna_local_file_server.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/page_background.dart';

/// 投屏页。构造时传入要投的地址与标题：
/// - [videoUrl] 可以是 http(s) URL（直接投），也可以是本地文件路径（自动起 HTTP 服务）。
class DlnaCastPage extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final bool isLocalFile;

  const DlnaCastPage({
    super.key,
    required this.videoUrl,
    this.title,
    this.isLocalFile = false,
  });

  @override
  State<DlnaCastPage> createState() => _DlnaCastPageState();
}

class _DlnaCastPageState extends State<DlnaCastPage> {
  final DlnaCastService _service = DlnaCastService();
  final DlnaLocalFileServer _localServer = DlnaLocalFileServer();

  String? _castUrl; // 实际投出去的 URL
  String? _castTitle;
  bool _isCasting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolveCastUrl();
    _service.addListener(_onServiceChanged);
    _service.startSearch();
  }

  Future<void> _resolveCastUrl() async {
    final url = widget.videoUrl;
    final isHttp = url.startsWith('http://') || url.startsWith('https://');
    if (widget.isLocalFile || !isHttp) {
      // 本地文件：起 HTTP 服务，绑定第一个局域网 IPv4
      try {
        final file = File(url);
        if (!await file.exists()) {
          if (mounted) {
            setState(() => _error = AppLocalizations.of(context).dlnaFileMissing);
          }
          return;
        }
        final urlPattern = await _localServer.start(file);
        final hosts = await _getLocalAddresses(includeIpv6: false);
        final host = pickLanHost(hosts);
        final localUrl = _localServer.urlForHost(host);
        if (kDebugMode) {
          debugPrint('📡 本地文件投屏地址: $urlPattern -> $localUrl');
        }
        _castUrl = localUrl;
        _castTitle =
            widget.title ?? dlnaTitleFromPath(file.path);
      } catch (e) {
        if (mounted) {
          setState(() => _error =
              AppLocalizations.of(context).dlnaServerStartFailed('$e'));
        }
        return;
      }
    } else {
      _castUrl = url;
      _castTitle = widget.title ?? url;
    }
  }

  void _onServiceChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _refresh() async {
    _service.stopSearch();
    if (mounted) setState(() {});
    await _service.startSearch();
  }

  Future<void> _castTo(DlnaCastTarget target) async {
    final url = _castUrl;
    if (url == null) return;
    setState(() {
      _isCasting = true;
      _error = null;
    });
    final ok = await _service.cast(
      target,
      url: url,
      title: _castTitle ?? '',
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        _isCasting = false;
        _error = null;
      });
      if (target.friendlyName.isNotEmpty) {
        showAppToast(
            context,
            AppLocalizations.of(context)
                .dlnaCastStarted(target.friendlyName));
      }
    } else {
      setState(() {
        _isCasting = false;
        _error = AppLocalizations.of(context).dlnaCastFailed(target.friendlyName);
      });
    }
  }

  Future<void> _stopCast() async {
    await _service.stopCast();
    if (!mounted) return;
    setState(() {
      _isCasting = false;
    });
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _service.dispose();
    _localServer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainerLow),
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              ExpressiveSliverAppBar(
                title: l10n.dlnaPageTitle,
                leading: MorphIconButton(
                  icon: Icons.arrow_back,
                  tooltip: l10n.startScreenGoBack,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                actions: [
                  MorphIconButton(
                    icon: Icons.refresh,
                    tooltip: l10n.dlnaRefresh,
                    onTap: _refresh,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              SliverToBoxAdapter(child: _buildBody(context, l10n, cs)),
              if (_service.isCasting)
                SliverToBoxAdapter(child: _buildRemoteControl(context, l10n)),
              if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: cs.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: cs.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, AppLocalizations l10n, ColorScheme colorScheme) {
    final targets = _service.targets;
    final searching = _service.isSearching;

    if (targets.isEmpty) {
      if (searching) {
        return SizedBox(
          height: 280,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                Text(l10n.dlnaSearching,
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        );
      }
      return SizedBox(
        height: 360,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cast_outlined, size: 72, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(l10n.dlnaNoDevice,
                  style: TextStyle(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.dlnaNoDeviceHint,
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: _refresh,
                icon: const Icon(Icons.search),
                label: Text(l10n.dlnaSearchAgain),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(context, '${l10n.dlnaFoundDevices} · ${targets.length}'),
          const SizedBox(height: 12),
          ...buildMorphSegmentedList([
            for (final target in targets) MorphRowItem(child: _buildDeviceTile(context, target)),
          ]),
          if (searching) ...[
            const SizedBox(height: 12),
            Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(BuildContext context, DlnaCastTarget target) {
    final cs = Theme.of(context).colorScheme;
    final isActive = _service.isCasting && target.key == _service.activeKey;
    final isBusy = _isCasting && target.key == _service.activeKey;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(Icons.tv, size: 26, color: isActive ? cs.primary : cs.onSurfaceVariant),
      title: Text(target.friendlyName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isActive ? cs.primary : cs.onSurface)),
      subtitle: Text(_deviceAddress(target.baseUrl), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      trailing: isBusy
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : (isActive ? Icon(Icons.check_circle, color: cs.primary, size: 20) : Icon(Icons.cast, color: cs.onSurfaceVariant, size: 20)),
      onTap: isActive ? null : () => _castTo(target),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, textAlign: TextAlign.left, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary));
  }

  String _deviceAddress(String baseUrl) {
    try {
      final uri = Uri.parse(baseUrl);
      return uri.host.isNotEmpty ? uri.host : baseUrl;
    } catch (_) {
      return baseUrl;
    }
  }

  Widget _buildRemoteControl(
      BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final position = _service.position;
    final duration = _service.duration;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.cast, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dlnaCastingTo(
                              _service.activeDeviceName ?? ''),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _castTitle ?? '',
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.dlnaStopCast,
                    onPressed: _stopCast,
                    icon: Icon(Icons.stop_circle_outlined,
                        color: colorScheme.error),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(_fmt(position),
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12),
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: (v) {
                          final target = Duration(
                              milliseconds:
                                  (v * duration.inMilliseconds).toInt());
                          _service.seek(target);
                        },
                      ),
                    ),
                  ),
                  Text(_fmt(duration),
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: l10n.dlnaPause,
                    onPressed: _service.pause,
                    icon: const Icon(Icons.pause, size: 32),
                  ),
                  IconButton(
                    tooltip: l10n.dlnaPlay,
                    onPressed: _service.play,
                    icon: const Icon(Icons.play_arrow, size: 32),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    tooltip: l10n.dlnaVolumeDown,
                    onPressed: () => _service.changeVolume(-10),
                    icon: const Icon(Icons.volume_down),
                  ),
                  IconButton(
                    tooltip: l10n.dlnaVolumeUp,
                    onPressed: () => _service.changeVolume(10),
                    icon: const Icon(Icons.volume_up),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}

// ================= 本机地址工具（原全局服务删除后的本地等价实现） =================

/// 获取本机可用地址列表（本地等价实现）：
/// IPv4 原样；IPv6 非链路本地原样、链路本地附 `%接口索引`（如 fe80::1%12）。
Future<List<String>> _getLocalAddresses({bool includeIpv6 = true}) async {
  final result = <String>[];
  try {
    final interfaces = await NetworkInterface.list();
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (addr.isLoopback) continue;
        if (addr.type == InternetAddressType.IPv4) {
          result.add(addr.address);
        } else if (includeIpv6) {
          result.add(
            _isLinkLocalV6(addr.address)
                ? '${addr.address}%${interface.index}'
                : addr.address,
          );
        }
      }
    }
  } catch (e) {
    if (kDebugMode) debugPrint('⚠️ 获取本机 IP 失败: $e');
  }
  return result;
}

/// IPv6 链路本地（fe80::/10）判断。
bool _isLinkLocalV6(String address) {
  final clean = _stripIpv6Zone(address);
  final colon = clean.indexOf(':');
  if (colon <= 0) return false;
  final hextet = int.tryParse(clean.substring(0, colon), radix: 16);
  if (hextet == null) return false;
  return (hextet & 0xFFC0) == 0xFE80;
}

/// 去掉 IPv6 的 `%接口` 后缀。
String _stripIpv6Zone(String ip) {
  final zoneIdx = ip.indexOf('%');
  return zoneIdx >= 0 ? ip.substring(0, zoneIdx) : ip;
}
