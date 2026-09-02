// lib/widgets/morph_widgets.dart
//
// M3 Expressive 风格变形交互组件集合。
// 包含：MorphItem（分段列表行）、MorphIconButton（顶栏图标按钮）、RowItem（轻量描述行）。

import 'dart:ui';

import 'package:flutter/material.dart';


/// 状态 Hero 卡圆角
const double kGroupRadius = 16.0;

/// 兜底小圆角（连接验证通过绿框等）
const double kItemRadius = 8.0;

/// 列表项「大圆角端」：首行顶 / 末行底 / 唯一行四角，同时也是按下 morph 的目标。
const double kItemPressedRadius = 12.0;

/// 列表项「接缝 / 中间行」圆角。
const double kListEdgeRadius = 2.0;

/// 顶栏按钮【默认】圆角矩形，按下 morph 到正圆。
const double kIconBtnRadius = 14.0;

/// 相邻分段行缝隙（露背景当细分割线）。
const double kCardGap = 2.0;

/// 变形动画时长。
const Duration kMorphDuration = Duration(milliseconds: 70);

/// 变形动画曲线。
const Curve kMorphCurve = Curves.fastOutSlowIn;


/// 顶栏图标按钮：默认正圆，tap-down 即 morph 到圆角矩形。
///
/// ```dart
/// MorphIconButton(
///   icon: Icons.arrow_back,
///   tooltip: '返回',
///   onTap: () => Navigator.of(context).maybePop(),
/// )
/// ```
class MorphIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  /// 按钮尺寸，默认 40。
  final double size;

  /// 图标尺寸，默认 22。
  final double iconSize;

  /// 毛玻璃按钮：背景半透明 + BackdropFilter 模糊，前景（图标）颜色不变。
  final bool frosted;

  /// 图标颜色，默认跟随主题（onSecondaryContainer）。
  final Color? iconColor;

  const MorphIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 40.0,
    this.iconSize = 22.0,
    this.frosted = false,
    this.iconColor,
  });

  @override
  State<MorphIconButton> createState() => _MorphIconButtonState();
}

class _MorphIconButtonState extends State<MorphIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.secondaryContainer;
    // 毛玻璃时背景半透明，露出后面的模糊内容
    final baseColor = widget.frosted ? base.withValues(alpha: 0.35) : base;
    final pressedColor = Color.alphaBlend(
      cs.onSecondaryContainer.withOpacity(0.12),
      baseColor,
    );

    // 默认正圆 → 按下 morph 到圆角方形
    final radius =
        BorderRadius.circular(_pressed ? kIconBtnRadius : 100.0);

    Widget button = AnimatedContainer(
      duration: kMorphDuration,
      curve: kMorphCurve,
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: _pressed ? pressedColor : baseColor,
        borderRadius: radius,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: radius,
          highlightColor: Colors.transparent,
          splashColor: cs.onSecondaryContainer.withOpacity(0.3),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: widget.iconColor ?? cs.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ),
    );

    // 毛玻璃背景：BackdropFilter 模糊后面的内容
    if (widget.frosted) {
      button = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: button,
        ),
      );
    }

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        triggerMode: TooltipTriggerMode.longPress,
        child: button,
      );
    }

    return Center(child: button);
  }
}


/// 分段列表行容器：自动根据 [isFirst] / [isLast] 计算圆角，
/// 按下时 morph 到统一大圆角 + 叠加色。
///
/// ```dart
/// MorphItem(
///   selected: isSelected,
///   isFirst: i == 0,
///   isLast: i == list.length - 1,
///   child: ListTile(...),
/// )
/// ```
class MorphItem extends StatefulWidget {
  /// 是否处于选中态（影响底色）。
  final bool selected;

  /// 是否为分组首行。
  final bool isFirst;

  /// 是否为分组末行。
  final bool isLast;

  /// 是否响应按压变形（纯展示行设为 false）。
  final bool interactive;

  final Widget child;

  const MorphItem({
    super.key,
    required this.selected,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.interactive = true,
  });

  @override
  State<MorphItem> createState() => _MorphItemState();
}

class _MorphItemState extends State<MorphItem> {
  bool _pressed = false;

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
    final color = _pressed ? Color.alphaBlend(overlay, base) : base;

    final radius = _pressed
        ? BorderRadius.circular(kItemPressedRadius)
        : _defaultRadius();

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


/// 管理区分段行的轻量描述容器：child + 是否可交互（控制 morph）。
class RowItem {
  final Widget child;
  final bool interactive;

  const RowItem({required this.child, this.interactive = true});
}


/// 快速构建一组分段行（自动处理 isFirst / isLast / gap）。
///
/// ```dart
/// ...buildMorphSegment(
///   items: [
///     MorphItem(selected: false, isFirst: true, child: ...),
///     MorphItem(selected: false, child: ...),
///     MorphItem(selected: false, isLast: true, child: ...),
///   ],
/// )
/// ```
List<Widget> buildMorphSegment({
  required List<Widget> items,
  double gap = kCardGap,
}) {
  return List.generate(items.length, (i) {
    return Padding(
      padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : gap),
      child: items[i],
    );
  });
}