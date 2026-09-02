// lib/widgets/liquid_glass_menu_button.dart
//
// 液态玻璃菜单触发按钮：视觉与 [MorphIconButton] 一致（默认正圆，
// tap-down morph 到圆角矩形），但点击时不直接执行 onTap，而是获取
// 按钮自身 RenderBox 的中心点，调用 [showGlassDropdownMenu] 弹出
// liquid-dom 风格的液态玻璃菜单。
//
// 用途：替换项目里所有 AppBar 右上角 / 行尾的 [PopupMenuButton]，让
// 弹出菜单统一使用 [showLiquidDomMenu] 的弹簧 + 缩放 + 模糊液态玻璃
// 动画。也支持透明背景 IconButton 模式（用于 player 控制条等深色场景）。

import 'package:flutter/material.dart';
import 'package:naviflash/widgets/morph_widgets.dart';
import 'package:naviflash/widgets/search_video_menu.dart';

/// 液态玻璃菜单触发按钮。
///
/// ```dart
/// // AppBar 右上角（默认 MorphIconButton 风格）
/// LiquidGlassMenuButton(
///   icon: Icons.more_vert,
///   tooltip: l10n.playlistMenuMore,
///   menuWidth: 220,
///   actions: [
///     GlassMenuAction(icon: Icons.edit, text: '编辑', onTap: () => ...),
///     GlassMenuAction(
///       icon: Icons.delete,
///       text: '删除',
///       isDestructive: true,
///       onTap: () => ...,
///     ),
///   ],
/// )
/// ```
///
/// 当触发器需要显示动态文本（如播放器的 BoxFit / 倍速按钮，触发器是
/// `Text('1.0x')`）时，传入 [customChild] 替代 [icon]；此时按钮仍使用
/// 透明背景 [IconButton]，但内部展示 [customChild]。
class LiquidGlassMenuButton extends StatefulWidget {
  /// 触发器图标。与 [customChild] 互斥；当 [customChild] 非空时忽略此项。
  final IconData icon;

  /// 自定义触发器内容（如 `Text('1.0x')`）。非空时替代 [icon] 作为按钮
  /// 内容，用于播放器倍速 / BoxFit 等需要展示动态文本的场景。
  final Widget? customChild;

  /// 长按提示文字。
  final String? tooltip;

  /// 菜单动作列表。
  final List<GlassMenuAction> actions;

  /// 菜单宽度，默认 220。
  final double menuWidth;

  /// 菜单圆角，默认 18。
  final double menuRadius;

  /// 触发按钮尺寸，默认 40。
  final double size;

  /// 图标尺寸，默认 22。
  final double iconSize;

  /// 是否使用 [MorphIconButton] 风格（secondaryContainer 底色 + 圆形
  /// morph）。默认 true，用于 AppBar 右上角，与现有顶栏按钮视觉统一。
  ///
  /// 设为 false 时切换为透明背景 [IconButton]，配合 [iconColor] 使用，
  /// 适合 player 控制条 / 深色背景等场景。
  final bool useMorphStyle;

  /// 透明背景模式下的图标颜色。仅当 [useMorphStyle] 为 false 时生效。
  final Color? iconColor;

  /// 触发按钮内边距（透明背景 IconButton 模式下生效）。默认 null 让
  /// [IconButton] 自行决定。
  final EdgeInsetsGeometry? padding;

  /// 是否使用毛玻璃背景（仅 `useMorphStyle=true` 时生效），与 `MorphIconButton(frosted:true)` 一致。
  final bool frosted;

  const LiquidGlassMenuButton({
    super.key,
    required this.icon,
    required this.actions,
    this.customChild,
    this.tooltip,
    this.menuWidth = 220,
    this.menuRadius = 18.0,
    this.size = 40.0,
    this.iconSize = 22.0,
    this.useMorphStyle = true,
    this.iconColor,
    this.padding,
    this.frosted = false,
  });

  @override
  State<LiquidGlassMenuButton> createState() => _LiquidGlassMenuButtonState();
}

class _LiquidGlassMenuButtonState extends State<LiquidGlassMenuButton> {
  final GlobalKey _key = GlobalKey();
  bool _menuOpen = false;

  void _showMenu() {
    final ctx = _key.currentContext;
    if (ctx == null || _menuOpen) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    // 传按钮【左上角】+ 按钮尺寸：showLiquidDomMenu 启用角对齐定位
    // （菜单顶部对齐按钮顶部；水平方向默认左上角对齐，越界则右上角
    // 对齐向左展开）。
    final topLeft = box.localToGlobal(Offset.zero);
    showGlassDropdownMenu(
      ctx,
      actions: widget.actions,
      globalPosition: topLeft,
      menuWidth: widget.menuWidth,
      menuRadius: widget.menuRadius,
      originSize: box.size,
      onOpened: () {
        // 打开动画进行中：保持图标可见，随玻璃一起「绽放」，不要立即隐藏。
      },
      onOpenedComplete: () {
        // 菜单已完全展开并覆盖按钮，此时再隐藏本体（保留布局空间，
        // 避免 AppBar 高度跳动）。
        if (mounted) setState(() => _menuOpen = true);
      },
      onCloseStarted: () {
        // 关闭动画开始：让图标随玻璃回缩重新出现。
        if (mounted) setState(() => _menuOpen = false);
      },
      onClosed: () {
        if (mounted) setState(() => _menuOpen = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 仅在菜单完全展开（稳态）时隐藏按钮本体；打开 / 关闭动画过程中均
    // 保持可见。Offstage 保留布局空间，避免 AppBar 高度跳动；菜单的关闭态
    // 小圆点会出现在按钮中心位置作为「出生点」。
    final button = _buildButton();
    return Offstage(offstage: _menuOpen, child: button);
  }

  Widget _buildButton() {
    if (widget.useMorphStyle) {
      return MorphIconButton(
        key: _key,
        icon: widget.icon,
        tooltip: widget.tooltip,
        size: widget.size,
        iconSize: widget.iconSize,
        frosted: widget.frosted,
        onTap: _showMenu,
      );
    }
    // 透明背景 IconButton 模式（player / 深色场景）
    final color = widget.iconColor ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    final content = widget.customChild ??
        Icon(widget.icon, color: color, size: widget.iconSize);
    return IconButton(
      key: _key,
      icon: content,
      tooltip: widget.tooltip,
      onPressed: _showMenu,
      padding: widget.padding,
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: color,
      ),
    );
  }
}
