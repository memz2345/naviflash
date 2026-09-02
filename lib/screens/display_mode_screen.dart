// lib/screens/display_mode_screen.dart
//   - FlutterDisplayMode.supported → 系统支持的帧率列表（首项为「自动」）
//   - 选中后 setPreferredMode，再回读 active / preferred 更新 UI 与持久化
//   - 仅 Android 可用，其他平台显示不支持提示
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../src/loading_indicator_m3e.dart';
import '../widgets/expressive_app_bar.dart';
import '../widgets/page_background.dart';
import '../widgets/morph_card.dart';
import '../l10n/app_localizations.dart';

class DisplayModeScreen extends StatefulWidget {
  const DisplayModeScreen({super.key});

  @override
  State<DisplayModeScreen> createState() => _DisplayModeScreenState();
}

class _DisplayModeScreenState extends State<DisplayModeScreen> {
  List<DisplayMode> _modes = [];
  DisplayMode? _active;
  DisplayMode? _preferred;
  bool _loaded = false;
  bool _isAndroid = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // 初始化：拉取支持模式 → 恢复上次偏好 → 应用 → 回读当前状态
  Future<void> _init() async {
    _isAndroid = Platform.isAndroid;
    if (!_isAndroid) {
      if (mounted) setState(() => _loaded = true);
      return;
    }

    // 先取服务引用，避免 await 之后再访问 context
    final settings = context.read<SettingsService>();

    try {
      _modes = await FlutterDisplayMode.supported;
    } catch (e) {
      if (kDebugMode) debugPrint('获取屏幕帧率失败: $e');
    }

    final saved = settings.displayMode;
    DisplayMode? preferred;
    if (saved != null && saved.isNotEmpty) {
      for (final mode in _modes) {
        if (mode.toString() == saved) {
          preferred = mode;
          break;
        }
      }
    }
    preferred ??= DisplayMode.auto;

    try {
      await FlutterDisplayMode.setPreferredMode(preferred);
    } catch (e) {
      if (kDebugMode) debugPrint('设置屏幕帧率失败: $e');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await _fetchCurrent(settings);

    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _fetchCurrent(SettingsService settings) async {
    try {
      final active = await FlutterDisplayMode.active;
      final preferred = await FlutterDisplayMode.preferred;
      if (!mounted) return;
      setState(() {
        _active = active;
        _preferred = preferred;
      });
      await settings.setDisplayMode(preferred.toString());
    } catch (e) {
      if (kDebugMode) debugPrint('获取当前屏幕帧率失败: $e');
    }
  }

  Future<void> _onSelect(DisplayMode mode) async {
    final settings = context.read<SettingsService>();
    try {
      await FlutterDisplayMode.setPreferredMode(mode);
    } catch (e) {
      if (kDebugMode) debugPrint('设置屏幕帧率失败: $e');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await _fetchCurrent(settings);
  }

  String _modeTitle(DisplayMode mode, AppLocalizations l10n) {
    if (mode == DisplayMode.auto) return l10n.displayModeAuto;
    final title =
        '${mode.width}×${mode.height} @ ${mode.refreshRate.toInt()}Hz';
    if (_active != null && mode == _active) {
      return '$title  ${l10n.displayModeSystemTag}';
    }
    return title;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      body: Stack(
        children: [
          PageBackground(baseColor: colorScheme.surfaceContainer),
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              ExpressiveSliverAppBar(
                title: l10n.displayModeTitle,
                expandedHeight: 120,
                leading: MorphIconButton(
                  tooltip: l10n.homeBack,
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _isAndroid
                      ? Text(
                          l10n.displayModeHint,
                          style: TextStyle(
                            color: colorScheme.outline,
                            fontSize: 13,
                          ),
                        )
                      : MorphItem(
                          selected: false,
                          isFirst: true,
                          isLast: true,
                          interactive: false,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.speed_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.displayModeUnsupported,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              if (_isAndroid)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(child: _buildModeList()),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeList() {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (!_loaded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LoadingIndicatorM3E(),
              const SizedBox(height: 16),
              Text(
                l10n.displayModeLoading,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    if (_modes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            l10n.displayModeEmpty,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return RadioGroup<DisplayMode>(
      groupValue: _preferred,
      onChanged: (value) {
        if (value != null) _onSelect(value);
      },
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _modes.length,
        separatorBuilder: (_, __) => const SizedBox(height: kCardGap),
        itemBuilder: (context, index) {
          final mode = _modes[index];
          final isSelected = _preferred != null && mode == _preferred;
          return MorphItem(
            selected: isSelected,
            isFirst: index == 0,
            isLast: index == _modes.length - 1,
            child: RadioListTile<DisplayMode>(
              value: mode,
              activeColor: colorScheme.primary,
              secondary: Icon(
                mode == DisplayMode.auto
                    ? Icons.autorenew
                    : Icons.monitor_outlined,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              title: Text(
                _modeTitle(mode, l10n),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
