import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/services/native_menu_service.dart';
import 'package:naviflash/widgets/more_menu_sheet.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';
import '../services/image_color_analyzer.dart';
import '../src/loading_indicator_m3e.dart';
import '../src/theme_seed_ext.dart';
import '../src/enums.dart';
import '../widgets/color_palette.dart';
import '../widgets/widgets.dart';            
import '../widgets/page_background.dart';
import '../l10n/app_localizations.dart';

class ThemeSelectorScreen extends StatefulWidget {
  final bool isSplitView;
  final Function(String routeName)? onNavigate;
  final VoidCallback? onBack;

  const ThemeSelectorScreen({
    super.key,
    this.isSplitView = false,
    this.onNavigate,
    this.onBack,
  });

  @override
  State<ThemeSelectorScreen> createState() => _ThemeSelectorScreenState();
}

class _ThemeSelectorScreenState extends State<ThemeSelectorScreen> {
  List<Map<String, dynamic>> get _presetColors {
    final l10n = AppLocalizations.of(context);
    return [
      {'name': l10n.colorDefaultGreen, 'color': const Color(0xFF386A20)},
      {'name': l10n.colorPink, 'color': Colors.pink},
      {'name': l10n.colorRed, 'color': Colors.red},
      {'name': l10n.colorOrange, 'color': Colors.orange},
      {'name': l10n.colorAmber, 'color': Colors.amber},
      {'name': l10n.colorYellow, 'color': Colors.yellow},
      {'name': l10n.colorLime, 'color': Colors.lime},
      {'name': l10n.colorLightGreen, 'color': Colors.lightGreen},
      {'name': l10n.colorGreen, 'color': Colors.green},
      {'name': l10n.colorCyan, 'color': Colors.cyan},
      {'name': l10n.colorTeal, 'color': Colors.teal},
      {'name': l10n.colorLightBlue, 'color': Colors.lightBlue},
      {'name': l10n.colorBlue, 'color': Colors.blue},
      {'name': l10n.colorIndigo, 'color': Colors.indigo},
      {'name': l10n.colorPurple, 'color': Colors.purple},
      {'name': l10n.colorDeepPurple, 'color': Colors.deepPurple},
      {'name': l10n.colorBlueGrey, 'color': Colors.blueGrey},
      {'name': l10n.colorBrown, 'color': Colors.brown},
      {'name': l10n.colorGrey, 'color': Colors.grey},
    ];
  }

  bool _isAnalyzing = false;
  bool _isDragging = false;

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showSnackBar(String message, ColorScheme colorScheme) {
    if (!mounted) return;
                                                             
    showAppToast(context, message);
  }

  Future<void> _pickColorFromImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null) {
      await _analyzeAndApplyColor(File(picked.path));
    }
  }

  Future<void> _analyzeAndApplyColor(File file) async {
    if (_isAnalyzing) return;
    if (!await file.exists()) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _isAnalyzing = true);
    try {
      final bytes = await file.readAsBytes();
      final color = await analyzeImageColor(bytes);
      if (!mounted) return;
      final settingsService = context.read<SettingsService>();
      await settingsService.setThemeSeedColor(color);
      await settingsService.setUseDynamicColor(false);
      if (!mounted) return;
      _showSnackBar(l10n.themeColorExtracted, Theme.of(context).colorScheme);
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          l10n.themeColorFailed('$e'),
          Theme.of(context).colorScheme,
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _handleDrop(List<Object?> files) {
    final l10n = AppLocalizations.of(context);
    if (files.isEmpty) return;
    final path = files.first.toString().replaceAll('file://', '');
    final file = File(path);
    final ext = file.path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
      _analyzeAndApplyColor(file);
    } else {
      _showSnackBar(l10n.themeImageOnly, Theme.of(context).colorScheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final settingsService = context.watch<SettingsService>();
    final currentSeed = settingsService.themeSeedColor;
    final customThemes = settingsService.customThemes;
    final useDynamicColor = settingsService.useDynamicColor;
    final isPureBlackVisible = settingsService.themeMode != ThemeMode.light;

    return PopScope(
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
                                               
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'theme_create_fab',
          icon: const Icon(Icons.add),
          label: Text(l10n.themeNewTheme),
          onPressed: () => _showCustomThemeDialog(context),
        ),
        body: Stack(
          children: [
            PageBackground(baseColor: colorScheme.surfaceContainer),
                           
            DragTarget<List<String>>(
              onWillAcceptWithDetails: (data) {
                setState(() => _isDragging = true);
                return true;
              },
              onLeave: (_) => setState(() => _isDragging = false),
              onAcceptWithDetails: (details) {
                setState(() => _isDragging = false);
                _handleDrop(details.data);
              },
              builder: (context, candidateData, rejectedData) {
                return CustomScrollView(
                                                                    
                  physics: const ClampingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    ExpressiveSliverAppBar(
                      title: l10n.themeTitle,
                      leading: MorphIconButton(
                        tooltip: l10n.startScreenGoBack,
                        icon: Icons.arrow_back,
                        onTap: _handleBack,
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: LiquidGlassMenuButton(
                            icon: Icons.more_vert,
                            tooltip: l10n.playlistMenuMore,
                            menuWidth: 220,
                            actions: [
                              GlassMenuAction(
                                icon: Icons.content_copy,
                                text: l10n.themeCopyColor,
                                onTap: () async {
                                  final color = settingsService.themeSeedColor;
                                  final hex =
                                      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
                                  await Clipboard.setData(ClipboardData(text: hex));
                                  _showSnackBar(
                                    l10n.themeColorCopied(hex),
                                    colorScheme,
                                  );
                                },
                              ),
                              GlassMenuAction(
                                icon: Icons.image,
                                text: l10n.themePickFromImage,
                                onTap: _pickColorFromImage,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                                     
                          _buildSectionTitle(context, l10n.themeAppearance),
                          const SizedBox(height: 12),

                                 
                          MorphItem(
                            selected: false,
                            isFirst: true,
                            isLast: !isPureBlackVisible,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.flashlight_on_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.searchThemeMode),
                              subtitle: Text(
                                _getThemeModeText(settingsService.themeMode),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onTap: () => _showThemeModePicker(
                                context,
                                settingsService,
                              ),
                            ),
                          ),

                                         
                          _AnimatedCollapse(
                            visible: isPureBlackVisible,
                            child: Padding(
                              padding: const EdgeInsets.only(top: kCardGap),
                              child: MorphItem(
                                selected: false,
                                isFirst: false,
                                isLast: true,
                                child: SwitchListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  secondary: Icon(
                                    Icons.brightness_2_outlined,
                                    size: 26,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  title: Text(l10n.searchPureBlack),
                                  subtitle: Text(
                                    settingsService.isPureBlackMode
                                        ? l10n.themeDarkBlackened
                                        : l10n.themeOff,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  value: settingsService.isPureBlackMode,
                                  onChanged: (value) =>
                                      settingsService.setIsPureBlackMode(value),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                                     
                          _buildSectionTitle(context, l10n.themeColorsSection),
                          const SizedBox(height: 12),

                                                         
                          Padding(
                            padding: const EdgeInsets.only(bottom: kCardGap),
                            child: MorphItem(
                              selected: false,
                              isFirst: true,
                              interactive: !useDynamicColor,
                              child: ListTile(
                                enabled: !useDynamicColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: Icon(
                                  Icons.palette_outlined,
                                  size: 26,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: Text(l10n.themePaletteStyle),
                                subtitle: Text(
                                  settingsService.schemeVariant.variantName,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onTap: useDynamicColor
                                    ? null
                                    : () => _showSchemeVariantPicker(
                                          context,
                                          settingsService,
                                        ),
                              ),
                            ),
                          ),

                                   
                          Padding(
                            padding: const EdgeInsets.only(bottom: kCardGap),
                            child: MorphItem(
                              selected: false,
                              child: SwitchListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                secondary: Icon(
                                  Icons.wallpaper_outlined,
                                  size: 26,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: Text(l10n.themeFollowSystem),
                                subtitle: Text(
                                  useDynamicColor
                                      ? l10n.themeEnabled
                                      : l10n.themeOff,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                value: useDynamicColor,
                                onChanged: (value) =>
                                    settingsService.setUseDynamicColor(value),
                              ),
                            ),
                          ),

                                       
                          _AnimatedCollapse(
                            visible: !useDynamicColor,
                            child: MorphItem(
                              selected: false,
                              isLast: true,
                              interactive: false,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.themePickColor,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildColorGrid(
                                      colorScheme: colorScheme,
                                      currentSeed: currentSeed,
                                      customThemes: customThemes,
                                      useDynamicColor: useDynamicColor,
                                      settingsService: settingsService,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ]),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 48)),
                  ],
                );
              },
            ),

                             
            if (_isDragging)
              Container(
                color: colorScheme.primaryContainer.withValues(alpha: 0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_search,
                        size: 64,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.themeDropHint,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

                             
            if (_isAnalyzing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: LoadingIndicatorM3E(
                    variant: LoadingIndicatorM3EVariant.contained,
                    semanticLabel: 'Now Loading',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildColorGrid({
    required ColorScheme colorScheme,
    required Color currentSeed,
    required List<Map<String, dynamic>> customThemes,
    required bool useDynamicColor,
    required SettingsService settingsService,
  }) {
    final l10n = AppLocalizations.of(context);
    final variant = settingsService.schemeVariant;
    final brightness = Theme.of(context).brightness;

                                             
                                              
                                      
                                
    final children = <Widget>[];

                  
    for (var i = 0; i < customThemes.length; i++) {
      final theme = customThemes[i];
      final color = Color(theme['color'] as int);
      final name = theme['name'] as String;
      final isSelected = color.toARGB32() == currentSeed.toARGB32() && !useDynamicColor;
      children.add(
        _buildPaletteItem(
          colorScheme: colorScheme,
          variant: variant,
          brightness: brightness,
          color: color,
          name: name,
          isSelected: isSelected,
          onTap: () {
            settingsService.setThemeSeedColor(color);
            settingsService.setUseDynamicColor(false);
            _showSnackBar(l10n.themeSwitched(name), colorScheme);
          },
          onLongPress: () =>
              _showDeleteConfirmDialog(context, i, name, settingsService),
        ),
      );
    }

            
    for (final preset in _presetColors) {
      final color = preset['color'] as Color;
      final name = preset['name'] as String;
      final isSelected = color.toARGB32() == currentSeed.toARGB32() && !useDynamicColor;
      children.add(
        _buildPaletteItem(
          colorScheme: colorScheme,
          variant: variant,
          brightness: brightness,
          color: color,
          name: name,
          isSelected: isSelected,
          onTap: () {
            settingsService.setThemeSeedColor(color);
            settingsService.setUseDynamicColor(false);
            _showSnackBar(l10n.themeSwitched(name), colorScheme);
          },
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 22,
      runSpacing: 18,
      children: children,
    );
  }

                                              
                    
  Widget _buildPaletteItem({
    required ColorScheme colorScheme,
    required FlexSchemeVariant variant,
    required Brightness brightness,
    required Color color,
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorPalette(
            colorScheme: color.asColorSchemeSeed(variant, brightness),
            selected: isSelected,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

                                      
                                               
  Future<void> _showSchemeVariantPicker(
    BuildContext context,
    SettingsService service,
  ) async {
    final seed = service.themeSeedColor;
    final brightness = Theme.of(context).brightness;
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      items: [
        for (final variant in FlexSchemeVariant.values)
          NativeMenuItem(
            text: variant.variantName,
            checked: service.schemeVariant == variant,
            onTap: () => service.setSchemeVariant(variant),
          ),
      ],
    );
    if (nativeOk || !context.mounted) return;
    showAppBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FrostedSheet(
        child: SafeArea(
          child: SingleChildScrollView(
            child: RadioGroup<FlexSchemeVariant>(
              groupValue: service.schemeVariant,
              onChanged: (val) {
                if (val == null) return;
                service.setSchemeVariant(val);
                Navigator.pop(ctx);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final variant in FlexSchemeVariant.values)
                    RadioListTile<FlexSchemeVariant>(
                      secondary: SizedBox(
                        width: 36,
                        height: 36,
                        child: ColorPalette(
                          colorScheme:
                              seed.asColorSchemeSeed(variant, brightness),
                          selected: false,
                          showBgColor: false,
                        ),
                      ),
                      title: Text(variant.variantName),
                      value: variant,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return AppLocalizations.of(context).drawerLightMode;
      case ThemeMode.dark:
        return AppLocalizations.of(context).drawerDarkMode;
      case ThemeMode.system:
        return AppLocalizations.of(context).drawerSystemMode;
    }
  }

  Future<void> _showThemeModePicker(
    BuildContext context,
    SettingsService service,
  ) async {
    final nativeOk = await tryShowNativeMenuSheet(
      context,
      items: [
        for (final mode in ThemeMode.values)
          NativeMenuItem(
            text: _getThemeModeText(mode),
            checked: service.themeMode == mode,
            onTap: () => service.setThemeMode(mode),
          ),
      ],
    );
    if (nativeOk || !context.mounted) return;
    showAppBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FrostedSheet(
        child: SafeArea(
          child: RadioGroup<ThemeMode>(
            groupValue: service.themeMode,
            onChanged: (val) {
              if (val != null) {
                service.setThemeMode(val);
                Navigator.pop(ctx);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ThemeMode.values.map((mode) {
                return RadioListTile<ThemeMode>(
                  title: Text(_getThemeModeText(mode)),
                  value: mode,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    int index,
    String name,
    SettingsService service,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.themeDeleteTitle),
        content: Text(l10n.themeDeleteConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              service.removeCustomTheme(index);
              Navigator.pop(ctx);
              _showSnackBar(
                l10n.themeDeleted(name),
                Theme.of(context).colorScheme,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }

  void _showCustomThemeDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final hexController = TextEditingController(text: '#0000FF');
    Color tempColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateColorFromText(String input) {
              try {
                Color newColor;
                if (input.startsWith('#')) {
                  newColor = Color(
                    int.parse(input.substring(1), radix: 16) + 0xFF000000,
                  );
                } else if (input.contains(',')) {
                  final parts = input
                      .split(',')
                      .map((s) => int.parse(s.trim()))
                      .toList();
                  newColor = Color.fromRGBO(parts[0], parts[1], parts[2], 1);
                } else {
                  newColor = Color(int.parse(input, radix: 16) + 0xFF000000);
                }
                setDialogState(() => tempColor = newColor);
              } catch (_) {}
            }

            return AlertDialog(
              title: Text(l10n.themeCreateTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: l10n.themeNameLabel,
                        hintText: l10n.themeNameHint,
                        border: const OutlineInputBorder(),
                      ),
                                                 
                                                
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 16),
                    ColorPicker(
                      pickerColor: tempColor,
                      onColorChanged: (color) {
                        final newHex =
                            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                        setDialogState(() {
                          tempColor = color;
                          if (hexController.text != newHex) {
                            hexController.text = newHex;
                            hexController.selection =
                                TextSelection.fromPosition(
                                  TextPosition(offset: newHex.length),
                                );
                          }
                        });
                      },
                      pickerAreaHeightPercent: 0.4,
                      portraitOnly: true,
                      enableAlpha: false,
                      displayThumbColor: true,
                      labelTypes: const [
                        ColorLabelType.rgb,
                        ColorLabelType.hex,
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: hexController,
                      decoration: InputDecoration(
                        labelText: l10n.themeHexLabel,
                        hintText: l10n.themeHexHint,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.content_paste),
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null) {
                              hexController.text = data!.text!;
                              hexController.selection =
                                  TextSelection.fromPosition(
                                    TextPosition(offset: data.text!.length),
                                  );
                              updateColorFromText(data.text!);
                            }
                          },
                        ),
                      ),
                      onChanged: (value) => updateColorFromText(value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: nameController.text.trim().isEmpty
                      ? null
                      : () async {
                          final newName = nameController.text.trim();
                          final service = context.read<SettingsService>();
                          await service.addCustomTheme(newName, tempColor);
                          if (context.mounted) {
                            Navigator.pop(context);
                            _showSnackBar(
                              l10n.themeCreated(newName),
                              Theme.of(context).colorScheme,
                            );
                          }
                        },
                  child: Text(l10n.commonCreate),
                ),
              ],
            );
          },
        );
      },
    );
                                                     
                                                   
                                                
                                        
                                                               
                       
  }
}


                                                                       
class _AnimatedCollapse extends StatelessWidget {
  final bool visible;
  final Widget child;
  final double maxHeight;

  const _AnimatedCollapse({
    required this.visible,
    required this.child,
  }) : maxHeight = 1200.0;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        constraints: BoxConstraints(maxHeight: visible ? maxHeight : 0.0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: visible ? 1.0 : 0.0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            offset: visible ? Offset.zero : const Offset(0, -0.2),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}
