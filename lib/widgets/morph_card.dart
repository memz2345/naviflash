// lib/widgets/morph_card.dart
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../services/settings_search_controller.dart';

/// 状态 hero 卡 / 大分组圆角
const double kGroupRadius = 16.0;

/// 兜底小圆角（连接验证通过绿框等）
const double kItemRadius = 8.0;

/// 列表项「大圆角端」：首行顶 / 末行底 / 唯一行四角，也是按下 morph 目标
const double kItemPressedRadius = 12.0;

/// 列表项「接缝 / 中间行」圆角
const double kListEdgeRadius = 2.0;

/// 顶栏按钮默认圆角矩形，按下 morph 到正圆
const double kIconBtnRadius = 14.0;

/// 相邻分段行缝隙（露背景当细分割线）
const double kCardGap = 2.0;

/// Morph 动画时长
const Duration kMorphDuration = Duration(milliseconds: 70);

/// Morph 动画曲线
const Curve kMorphCurve = Curves.fastOutSlowIn;

/// 分段列表项容器：自动处理首/中/尾圆角，按下时 morph 到统一大圆角。
///
/// 设置 [flashKey] 后参与设置搜索高亮：命中目标时自动滚动到该项并闪烁数下。
/// 设置 [flashToken]（任意非空对象）可直接触发一次同样的滚动+闪烁，
/// 令牌变化（didUpdateWidget 对比）时再次触发——用于评论区「定位某条回复」等。
///
/// ```dart
/// MorphItem(
///   isFirst: true,
///   isLast: false,
///   selected: isSelected,
///   flashKey: 'theme_mode',
///   child: ListTile(...),
/// )
/// ```
class MorphItem extends StatefulWidget {
  final bool selected;
  final bool isFirst;
  final bool isLast;
  final bool interactive;
  final Widget child;

  /// 搜索高亮标识（设置页选项专用；为 null 时不参与高亮）。
  final String? flashKey;

  /// 直接高亮令牌（不依赖设置搜索控制器）：值变化时滚动到该项并闪烁数下。
  /// 需保持稳定（同一目标复用同一实例），目标项首次挂载即触发。
  final Object? flashToken;

  const MorphItem({
    super.key,
    required this.selected,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.interactive = true,
    this.flashKey,
    this.flashToken,
  });

  @override
  State<MorphItem> createState() => _MorphItemState();
}

class _MorphItemState extends State<MorphItem>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  AnimationController? _flashCtrl;
  int? _handledFlashToken;

  @override
  void initState() {
    super.initState();
    if (widget.flashKey != null) {
      _flashCtrl = _createFlashCtrl();
      SettingsSearchController.current.addListener(_onSearchTargetChanged);
      _onSearchTargetChanged();
    } else if (widget.flashToken != null) {
      _flashCtrl = _createFlashCtrl();
      // 目标项首次挂载即触发滚动+闪烁（post-frame 等布局完成）
      _triggerFlash();
    }
  }

  @override
  void didUpdateWidget(MorphItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flashToken != null &&
        widget.flashToken != oldWidget.flashToken) {
      _flashCtrl ??= _createFlashCtrl();
      _triggerFlash();
    }
  }

  AnimationController _createFlashCtrl() {
    return AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(_onFlashTick);
  }

  /// 闪烁动画驱动重建（底色随动画脉动）。
  void _onFlashTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (widget.flashKey != null) {
      SettingsSearchController.current.removeListener(_onSearchTargetChanged);
    }
    _flashCtrl?.dispose();
    super.dispose();
  }

  /// 滚动到可见并闪烁 3 下（1.5s）。
  void _triggerFlash() {
    final ctrl = _flashCtrl;
    if (ctrl == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
        alignment: 0.5,
      );
      ctrl.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 1560), () {
        if (mounted) {
          ctrl.stop();
          ctrl.reset();
        }
      });
    });
  }

  /// 命中搜索目标：滚动到可见并闪烁。
  void _onSearchTargetChanged() {
    final target = SettingsSearchController.current.value;
    if (target == null || target.optionKey != widget.flashKey) return;
    if (target.token == _handledFlashToken) return;
    _handledFlashToken = target.token;
    _triggerFlash();
  }

  BorderRadius _defaultRadius() {
    const big = kItemPressedRadius;
    const edge = kListEdgeRadius;

    if (widget.isFirst && widget.isLast) {
      return BorderRadius.circular(big);
    }
    if (widget.isFirst) {
      return const BorderRadius.only(
        topLeft: Radius.circular(big),
        topRight: Radius.circular(big),
        bottomLeft: Radius.circular(edge),
        bottomRight: Radius.circular(edge),
      );
    }
    if (widget.isLast) {
      return const BorderRadius.only(
        topLeft: Radius.circular(edge),
        topRight: Radius.circular(edge),
        bottomLeft: Radius.circular(big),
        bottomRight: Radius.circular(big),
      );
    }
    return BorderRadius.circular(edge);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base =
        widget.selected ? cs.secondaryContainer : cs.surfaceBright;
    final overlay = widget.selected
        ? cs.onSecondaryContainer.withOpacity(0.10)
        : cs.onSurface.withOpacity(0.08);
    var color = _pressed ? Color.alphaBlend(overlay, base) : base;

    // 搜索高亮闪烁：底色向 primaryContainer 脉动
    final flash = _flashCtrl?.isAnimating ?? false;
    if (flash) {
      final t = _flashCtrl!.value;
      final pulse = t < 0.5 ? t * 2 : (1 - t) * 2; // 0→1→0 每半周期
      color = Color.alphaBlend(
        cs.primaryContainer.withOpacity(0.55 * pulse),
        color,
      );
    }

    final radius =
        _pressed ? BorderRadius.circular(kItemPressedRadius) : _defaultRadius();

    final container = AnimatedContainer(
      duration: kMorphDuration,
      curve: kMorphCurve,
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: widget.child,
      ),
    );

    if (!widget.interactive) return container;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: container,
    );
  }
}

/// 管理区分段行的轻量描述：child + 是否可交互（控制 morph）+ 搜索高亮标识。
class MorphRowItem {
  final Widget child;
  final bool interactive;

  /// 搜索高亮标识（设置页选项专用；为 null 时不参与高亮）。
  final String? flashKey;

  const MorphRowItem({
    required this.child,
    this.interactive = true,
    this.flashKey,
  });
}

/// 快速构建一组分段行（自动处理 isFirst / isLast / gap）。
///
/// ```dart
/// ...buildMorphSegmentedList([
///   MorphRowItem(child: ListTile(...)),
///   MorphRowItem(child: ListTile(...), interactive: false),
/// ])
/// ```
List<Widget> buildMorphSegmentedList(List<MorphRowItem> items) {
  return List.generate(items.length, (i) {
    final isFirst = i == 0;
    final isLast = i == items.length - 1;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : kCardGap),
      child: MorphItem(
        selected: false,
        isFirst: isFirst,
        isLast: isLast,
        interactive: items[i].interactive,
        flashKey: items[i].flashKey,
        child: items[i].child,
      ),
    );
  });
}

/// 毛玻璃下拉菜单：列表项为 [MorphItem] 卡片，背景模糊与 B 站搜索栏一致。
///
/// 按钮外观保持 Flutter [DropdownButton] 的观感（选中项文字 + 下拉箭头），
/// 点击后在按钮下方弹出浮层菜单：
///   - 列表项用 [MorphItem] 分段卡片渲染（首/尾大圆角、按下 morph、
///     选中项 secondaryContainer 高亮、禁用项置灰）
///   - 背景毛玻璃参数与搜索页毛玻璃搜索栏（`FrostedPanel` 默认值）一致：
///     `ImageFilter.blur(sigmaX: 10, sigmaY: 10)` + `surface` 不透明度 0.75
///   - 自动避让屏幕边缘（放不下时弹到按钮上方），超高时内部滚动
///
/// 深色面板（如播放器内设置面板）可传 [menuColorScheme] 强制菜单配色，
/// 保证菜单内文字可读。
///
/// ```dart
/// MorphGlassDropdown<String>(
///   value: settings.hwdecMode,
///   items: [
///     DropdownMenuItem(value: 'auto', child: Text(l10n.psHwdecAutoShort)),
///     DropdownMenuItem(value: 'no', child: Text(l10n.psHwdecPureSoftware)),
///   ],
///   onChanged: (val) {
///     if (val != null) settings.setHwdecMode(val);
///   },
/// )
/// ```
class MorphGlassDropdown<T> extends StatefulWidget {
  /// 当前选中值（决定按钮显示与列表选中高亮）。
  final T? value;

  /// 菜单项（复用 [DropdownMenuItem]，仅读取 value / child / enabled）。
  final List<DropdownMenuItem<T>>? items;

  /// 选中回调；为 null 时按钮禁用。
  final ValueChanged<T?>? onChanged;

  /// 菜单宽度，默认 220（与视频卡片右键菜单一致）。
  final double menuWidth;

  /// 菜单最大高度，超出时内部滚动，默认 320。
  final double menuMaxHeight;

  /// 菜单配色（默认取当前主题；播放器深色面板可传深色 [ColorScheme]）。
  final ColorScheme? menuColorScheme;

  const MorphGlassDropdown({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.menuWidth = 220.0,
    this.menuMaxHeight = 320.0,
    this.menuColorScheme,
  });

  @override
  State<MorphGlassDropdown<T>> createState() => _MorphGlassDropdownState<T>();
}

class _MorphGlassDropdownState<T> extends State<MorphGlassDropdown<T>> {
  List<DropdownMenuItem<T>> get _items => widget.items ?? const [];

  /// 当前选中的项；未匹配时回退到第一项（同 DropdownButton 行为）。
  DropdownMenuItem<T>? get _selected {
    for (final item in _items) {
      if (item.value == widget.value) return item;
    }
    return _items.isEmpty ? null : _items.first;
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.menuColorScheme ?? Theme.of(context).colorScheme;
    return InkWell(
      onTap: widget.onChanged == null ? null : _openMenu,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 与 DropdownButton 一致：选中项文字用 bodyLarge 包裹
            DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
              child: _selected?.child ?? const SizedBox.shrink(),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 24,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  /// 在按钮下方弹出毛玻璃 morph 卡片菜单。
  void _openMenu() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final overlay = Overlay.of(context);
    final anchor = box.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;
    final cs = widget.menuColorScheme ?? Theme.of(context).colorScheme;
    final width = widget.menuWidth;
    // 每项约 44 高 + 容器上下内边距，用于上下避让估算
    final estHeight = _items.length * 44.0 + 12.0;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        double left = anchor.dx;
        double top = anchor.dy + box.size.height + 4;
        if (left + width > screenSize.width - 8) {
          left = screenSize.width - width - 8;
        }
        if (left < 8) left = 8;
        if (top + estHeight > screenSize.height - 8) {
          top = anchor.dy - estHeight - 4; // 放不下时弹到按钮上方
          if (top < 8) top = 8;
        }
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: entry.remove,
                onSecondaryTap: entry.remove,
                onPanDown: (_) => entry.remove(),
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            Positioned(left: left, top: top, child: _buildMenu(cs, entry)),
          ],
        );
      },
    );
    overlay.insert(entry);
  }

  Widget _buildMenu(ColorScheme cs, OverlayEntry entry) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(kGroupRadius),
      child: BackdropFilter(
        // 与 B 站搜索栏同款模糊（FrostedPanel 默认：sigma 10 + 不透明度 0.75）
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: widget.menuWidth,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(kGroupRadius),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.menuMaxHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == _items.length - 1 ? 0 : kCardGap,
                      ),
                      child: MorphItem(
                        selected: _items[i].value == widget.value,
                        isFirst: i == 0,
                        isLast: i == _items.length - 1,
                        interactive: _items[i].enabled,
                        child: _buildItem(cs, _items[i], entry),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    ColorScheme cs,
    DropdownMenuItem<T> item,
    OverlayEntry entry,
  ) {
    final selected = item.value == widget.value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.enabled
            ? () {
                entry.remove();
                widget.onChanged?.call(item.value);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : null,
              color: item.enabled
                  ? (selected ? cs.onSecondaryContainer : cs.onSurface)
                  : cs.onSurface.withValues(alpha: 0.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Flexible(child: item.child)],
            ),
          ),
        ),
      ),
    );
  }
}
