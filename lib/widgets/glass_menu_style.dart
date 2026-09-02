// lib/widgets/glass_menu_style.dart
//
// 玻璃浮窗菜单的内容排版组件，对齐 liquid-dom MenuDemo 的视觉语言：
//   - 胶囊行（[GlassMenuRow]）：含桌面端 hover 半透明高亮（效果③）、
//     destructive / disabled / trailing 等扩展态；
//   - 分区（[GlassMenuSection]）+ 1px 分隔线（[GlassMenuDivider]）；
//   - 页脚两列网格（[GlassMenuFooter]），图标在上、文字在下、hover 高亮；
//   - 内容容器（[GlassMenu]）统一内边距。
// 由 [showLiquidDomMenu] 的各内容构建器复用，统一浮窗菜单观感（效果②）。
import 'package:flutter/material.dart';

/// reference 菜单行 hover 底色 rgba(9,9,11,0.08)。
const double _kGlassMenuHoverOpacity = 0.08;

/// `:hover`）。内部用 [MouseRegion] 跟踪，[AnimatedContainer] 平滑过渡。
class _GlassHoverBox extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final Color hoverColor;

  const _GlassHoverBox({
    required this.child,
    required this.borderRadius,
    required this.hoverColor,
  });

  @override
  State<_GlassHoverBox> createState() => _GlassHoverBoxState();
}

class _GlassHoverBoxState extends State<_GlassHoverBox> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovering ? widget.hoverColor : Colors.transparent,
          borderRadius: widget.borderRadius,
        ),
        child: widget.child,
      ),
    );
  }
}

/// 玻璃菜单内容容器：统一内边距与排布方向。
class GlassMenu extends StatelessWidget {
  final ColorScheme colorScheme;
  final EdgeInsetsGeometry padding;
  final List<Widget> children;

  const GlassMenu({
    super.key,
    required this.colorScheme,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// 1px 分隔线（分区之间），带上下留白。
class GlassMenuDivider extends StatelessWidget {
  final ColorScheme colorScheme;
  final double margin;

  const GlassMenuDivider({
    super.key,
    required this.colorScheme,
    this.margin = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: margin),
      child: Divider(
        height: 1,
        thickness: 1,
        color: colorScheme.onSurface.withValues(alpha: 0.10),
      ),
    );
  }
}

/// 菜单分区（一组行）。[divider]=true 时分区末尾追加分隔线。
class GlassMenuSection extends StatelessWidget {
  final ColorScheme colorScheme;
  final List<Widget> children;
  final bool divider;

  const GlassMenuSection({
    super.key,
    required this.colorScheme,
    required this.children,
    this.divider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...children,
        if (divider) GlassMenuDivider(colorScheme: colorScheme),
      ],
    );
  }
}

/// 玻璃菜单单行：胶囊造型 + 桌面 hover 高亮（效果②③）。
///
/// 对齐 reference 的 `.menuRow`（min-height 40、圆角胶囊、字号 15、
/// 图标 20、hover 半透明底）。支持 [trailing] / [destructive] /
/// [enabled] 三种扩展态，保持与项目内通用菜单一致。
class GlassMenuRow extends StatelessWidget {
  final ColorScheme colorScheme;
  final IconData? icon;
  final Color? iconColor;
  final String? label;
  final TextStyle? labelStyle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double? iconSize;
  final double? fontSize;
  final bool dense;
  final bool destructive;
  final bool enabled;

  const GlassMenuRow({
    super.key,
    required this.colorScheme,
    this.icon,
    this.iconColor,
    this.label,
    this.labelStyle,
    this.trailing,
    this.onTap,
    this.iconSize = 20,
    this.fontSize = 15,
    this.dense = false,
    this.destructive = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = destructive
        ? colorScheme.error
        : (enabled
            ? (iconColor ?? colorScheme.onSurfaceVariant)
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.4));
    final effectiveTextColor = destructive
        ? colorScheme.error
        : (enabled
            ? colorScheme.onSurface
            : colorScheme.onSurface.withValues(alpha: 0.4));
    final hoverColor = (destructive ? colorScheme.error : colorScheme.onSurface)
        .withValues(alpha: _kGlassMenuHoverOpacity);
    return _GlassHoverBox(
      borderRadius: BorderRadius.circular(999),
      hoverColor: hoverColor,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          child: Container(
            height: dense ? 36 : 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: iconSize, color: effectiveIconColor),
                  const SizedBox(width: 13),
                ],
                if (label != null)
                  Expanded(
                    child: Text(
                      label!,
                      overflow: TextOverflow.ellipsis,
                      style: (labelStyle ?? const TextStyle()).copyWith(
                        fontSize: fontSize,
                        color: effectiveTextColor,
                      ),
                    ),
                  ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 页脚网格单元数据。
class GlassMenuFooterItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const GlassMenuFooterItem({
    required this.icon,
    required this.label,
    this.onTap,
  });
}

/// 页脚两列网格（图标在上、文字在下、居中、hover 高亮），对齐
/// reference 的 `.footerGrid` / `.footerItem`。
class GlassMenuFooter extends StatelessWidget {
  final ColorScheme colorScheme;
  final List<GlassMenuFooterItem> items;

  const GlassMenuFooter({
    super.key,
    required this.colorScheme,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.7,
        children: [
          for (final item in items)
            _GlassMenuFooterCell(item: item, colorScheme: colorScheme),
        ],
      ),
    );
  }
}

class _GlassMenuFooterCell extends StatelessWidget {
  final GlassMenuFooterItem item;
  final ColorScheme colorScheme;

  const _GlassMenuFooterCell({
    required this.item,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final hoverColor =
        colorScheme.onSurface.withValues(alpha: _kGlassMenuHoverOpacity);
    return _GlassHoverBox(
      borderRadius: BorderRadius.circular(20),
      hoverColor: hoverColor,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(20),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 20, color: colorScheme.onSurface),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
