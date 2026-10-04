# -*- coding: utf-8 -*-
"""第四轮：播放器暴露「更多」面板的内嵌子页面能力。"""
import io

P = 'lib/screens/player.dart'
s = io.open(P, encoding='utf-8').read()


def rep(old, new, count=1):
    global s
    n = s.count(old)
    assert n == count, ('count=%d expect=%d' % (n, count), old[:80])
    s = s.replace(old, new, count)


# ── 1. 字幕设置内容抽出来（内嵌侧栏与「更多」子页面共用）──
rep(
    """              Expanded(
                child: SingleChildScrollView(
                  child: SubtitlePanel(
                    player: player,
                    fontSize: _subFontSize,
                    fontColor: _subColor,
                    bgColor: _subBgColor,
                    dragEnabled: _subDragEnabled,
                    onDragChanged: () => _toggleSubtitleDrag(),
                    onResetPosition: () => _resetSubtitlePosition(),
                    onFontSizeChanged: (v) => setState(() => _subFontSize = v),
                    onFontColorChanged: (c) => setState(() => _subColor = c),
                    onBgColorChanged: (c) => setState(() => _subBgColor = c),
                  ),
                ),
              ),
""",
    """              Expanded(child: _buildSubtitleSettingsBody()),
""",
)

# 在 _buildSubtitlePanel 之后插入抽取出来的 body 方法
rep(
    """  Widget _buildSettingsPanel(SettingsService settings) {""",
    """  /// 字幕设置内容（无外框 / 无标题栏）：
  /// 内嵌播放器的右侧栏与「更多」面板的子页面共用同一份。
  Widget _buildSubtitleSettingsBody() {
    return SingleChildScrollView(
      child: SubtitlePanel(
        player: player,
        fontSize: _subFontSize,
        fontColor: _subColor,
        bgColor: _subBgColor,
        dragEnabled: _subDragEnabled,
        onDragChanged: () => _toggleSubtitleDrag(),
        onResetPosition: () => _resetSubtitlePosition(),
        onFontSizeChanged: (v) => setState(() => _subFontSize = v),
        onFontColorChanged: (c) => setState(() => _subColor = c),
        onBgColorChanged: (c) => setState(() => _subBgColor = c),
      ),
    );
  }

  Widget _buildSettingsPanel(SettingsService settings) {""",
)

# ── 2. 音频设备应用逻辑抽成 _applyAudioDevice ──
rep(
    """    if (picked == null || !mounted) return;
    try {
      await player.setAudioDevice(picked);
      await ps?.setAudioOutputDevice(
        picked.name == 'auto' ? '' : picked.name,
      );
      if (mounted) {
        showAppToast(
          context,
          picked.name == 'auto'
              ? '已恢复自动输出'
              : '已切换音频输出：${picked.description.isEmpty ? picked.name : picked.description}',
        );
      }
    } catch (e) {
      if (mounted) showAppToast(context, '切换失败：$e', error: true);
    }
  }
""",
    """    if (picked == null || !mounted) return;
    await _applyAudioDevice(picked);
  }

  /// 应用音频输出设备（弹层与「更多」面板子页面共用）。
  Future<void> _applyAudioDevice(AudioDevice device) async {
    try {
      await player.setAudioDevice(device);
      await _playerSettingsService?.setAudioOutputDevice(
        device.name == 'auto' ? '' : device.name,
      );
      if (mounted) {
        showAppToast(
          context,
          device.name == 'auto'
              ? '已恢复自动输出'
              : '已切换音频输出：${device.description.isEmpty ? device.name : device.description}',
        );
      }
    } catch (e) {
      if (mounted) showAppToast(context, '切换失败：$e', error: true);
    }
  }
""",
)

# ── 3. 新增「更多」面板子页面用的能力（接在超分辨率菜单之后）──
rep(
    """    if (picked == null || picked == current) return;
    await settings.setSuperResolutionMode(picked);
    final platform = player.platform;
    if (platform is NativePlayer) {
      await SuperResolutionService.apply(platform, picked);
    }
  }
""",
    """    if (picked == null || picked == current) return;
    await applySuperResolution(picked);
  }

  // ── 「更多」面板的内嵌子页面（宽屏右侧面板里以 push 感显示，不弹弹层）──

  /// 字幕设置内容（无外框），宿主「更多」面板的子页面直接渲染。
  Widget buildSubtitleSettingsBody() => _buildSubtitleSettingsBody();

  /// 音频输出设备列表（无外框），选择后立即应用。
  Widget buildAudioDeviceBody() {
    return _AudioDevicePanel(
      player: player,
      current: _playerSettingsService?.audioOutputDevice ?? '',
      onPick: (device) => unawaited(_applyAudioDevice(device)),
    );
  }

  /// 音量均衡三档（关闭 / dynaudnorm / loudnorm）。
  static const List<String> audioNormalizationModes = [
    PlayerAudioService.modeDisable,
    PlayerAudioService.modeDynaudnorm,
    PlayerAudioService.modeLoudnorm,
  ];

  String get audioNormalizationValue =>
      _playerSettingsService?.audioNormalization ??
      PlayerAudioService.modeDisable;

  /// 应用音量均衡（实时 af 滤镜 + 持久化）。
  Future<void> applyAudioNormalization(String mode) async {
    final ps = _playerSettingsService;
    if (ps == null) return;
    await ps.setAudioNormalization(mode);
    final platform = player.platform;
    if (platform is NativePlayer) {
      await PlayerAudioService.apply(platform, mode);
    }
  }

  /// 超分辨率三档（关闭 / 效率 / 画质）。
  static const List<String> superResolutionModes = [
    SuperResolutionService.modeDisable,
    SuperResolutionService.modeEfficiency,
    SuperResolutionService.modeQuality,
  ];

  String get superResolutionValue =>
      _playerSettingsService?.superResolutionMode ??
      SuperResolutionService.modeDisable;

  /// 应用超分辨率着色器（实时 + 持久化）。
  Future<void> applySuperResolution(String mode) async {
    final ps = _playerSettingsService;
    if (ps == null) return;
    await ps.setSuperResolutionMode(mode);
    final platform = player.platform;
    if (platform is NativePlayer) {
      await SuperResolutionService.apply(platform, mode);
    }
  }

  /// 换源列表（label + 是否为当前源）。
  List<({String label, bool selected})> get sourceOptions => [
    for (final e in _sourceEntries())
      (
        label: e.label,
        selected: e.index == _sourceIndex && e.host == _sourceHost,
      ),
  ];

  /// 按下标切换 CDN 源（下标与 [sourceOptions] 对齐）。
  Future<void> selectSourceAt(int index) async {
    final entries = _sourceEntries();
    if (index < 0 || index >= entries.length) return;
    await _switchSource(entries[index]);
  }
""",
)

# ── 4. 音频设备面板（「更多」面板子页面用，顶层私有 widget）──
s = s.rstrip('\n') + """

/// 「更多」面板的音频输出设备子页面（无外框；设备枚举是异步的）。
class _AudioDevicePanel extends StatefulWidget {
  const _AudioDevicePanel({
    required this.player,
    required this.current,
    required this.onPick,
  });

  final Player player;

  /// 当前已保存的设备名（空 = 自动）。
  final String current;
  final ValueChanged<AudioDevice> onPick;

  @override
  State<_AudioDevicePanel> createState() => _AudioDevicePanelState();
}

class _AudioDevicePanelState extends State<_AudioDevicePanel> {
  List<AudioDevice> _devices = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    var devices = widget.player.state.audioDevices;
    if (devices.isEmpty) {
      try {
        devices = await widget.player.stream.audioDevices
            .firstWhere((list) => list.isNotEmpty)
            .timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_devices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('没有检测到可用的音频输出设备', style: TextStyle(fontSize: 13)),
        ),
      );
    }
    return ListView(
      children: [
        ListTile(
          dense: true,
          leading: const Icon(Icons.auto_awesome, size: 20),
          title: const Text('自动', style: TextStyle(fontSize: 14)),
          trailing: widget.current.isEmpty
              ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
              : null,
          onTap: () => widget.onPick(AudioDevice.auto()),
        ),
        for (final d in _devices)
          ListTile(
            dense: true,
            leading: const Icon(Icons.speaker_outlined, size: 20),
            title: Text(
              d.description.isEmpty ? d.name : d.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: d.description.isEmpty
                ? null
                : Text(d.name, style: const TextStyle(fontSize: 11)),
            trailing: d.name == widget.current
                ? const Icon(Icons.check, size: 18, color: Colors.blueAccent)
                : null,
            onTap: () => widget.onPick(d),
          ),
      ],
    );
  }
}
"""

io.open(P, 'w', encoding='utf-8', newline='').write(s)
print('ok')
