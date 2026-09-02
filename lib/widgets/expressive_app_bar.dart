// lib/widgets/expressive_app_bar.dart
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/long_press_glass_tab_switcher.dart';
import 'morph_card.dart'; // 复用 kIconBtnRadius, kMorphDuration, kMorphCurve

/// 顶栏图标按钮：默认正圆，tap-down morph 到圆角方形。
///
/// ```dart
/// MorphIconButton(
///   icon: Icons.arrow_back,
///   tooltip: '返回',
///   onTap: () => Navigator.pop(context),
/// )
/// ```
class MorphIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final double iconSize;

  /// 毛玻璃按钮：背景半透明 + BackdropFilter 模糊，前景（图标）颜色不变。
  final bool frosted;

  const MorphIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 40.0,
    this.iconSize = 22.0,
    this.frosted = false,
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
    final radius = BorderRadius.circular(_pressed ? kIconBtnRadius : 100.0);

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
                color: cs.onSecondaryContainer,
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

/// 毛玻璃（高斯模糊 + 半透明）面板。
///
/// 悬浮在内容之上并模糊背景的浮层，供顶栏、选项卡、底部操作栏等复用。
///
/// ```dart
/// FrostedPanel(
///   opacity: 0.7,
///   child: SizedBox(height: 48, child: MyTabBar()),
/// )
/// ```
class FrostedPanel extends StatelessWidget {
  /// 模糊强度，默认 10
  final double blurSigma;

  /// 背景不透明度，默认 0.7
  final double opacity;

  /// 背景色（默认取主题 surface）
  final Color? color;

  /// 圆角（默认直角）
  final BorderRadius? borderRadius;

  final Widget child;

  const FrostedPanel({
    super.key,
    required this.child,
    this.blurSigma = 10.0,
    this.opacity = 0.7,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = color ?? colorScheme.surface.withOpacity(opacity);
    // hardEdge 避免抗锯齿在边缘留 1px 半透明发丝线；内层用同色 0.5px 边框 bleed 彻底盖住缝隙，不影响整体不透明度
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      clipBehavior: Clip.hardEdge,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            // 1px 同色边框向外 bleed，遮住 Clip 边缘的透明缝
            border: Border.all(color: bg, width: 0.6),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 渐变模糊顶栏底座：最上面模糊最强、越往下越弱（近似 iOS 顶部错位模糊）。
///
/// Flutter 的 BackdropFilter 只支持均匀模糊，这里用多层水平条带、每条带
/// 使用递减的高斯 sigma 叠加实现「上强下弱」的渐变模糊；再叠一层从实到虚
/// 的半透明底色渐变保证可读性。内容从栏下方滚过时即被逐层模糊。
///
/// ```dart
/// // 悬浮顶栏背景：
/// Positioned.fill(child: GradientBlurBar(sigmaTop: 26, sigmaBottom: 4))
/// ```
class GradientBlurBar extends StatelessWidget {
  /// 顶部（最强）模糊 sigma。
  final double sigmaTop;

  /// 底部（最弱）模糊 sigma。
  final double sigmaBottom;

  /// 条带数量（越多渐变越平滑，模糊计算越多；默认 5）。
  final int bands;

  /// 顶部底色不透明度（实 → 半透明，保证标题/按钮可读）。
  final double topOpacity;

  /// 底部底色不透明度。
  final double bottomOpacity;

  const GradientBlurBar({
    super.key,
    this.sigmaTop = 26.0,
    this.sigmaBottom = 4.0,
    this.bands = 5,
    this.topOpacity = 0.85,
    this.bottomOpacity = 0.30,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = bands > 1 ? bands : 1;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 多层递减模糊条带
          for (var i = 0; i < n; i++)
            FractionallySizedBox(
              heightFactor: 1.0 / n,
              alignment: Alignment(0, -1.0 + ((2 * i + 1) / n)),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: lerpDouble(
                      sigmaTop,
                      sigmaBottom,
                      n == 1 ? 0.0 : i / (n - 1),
                    )!,
                    sigmaY: 0.0, // 只做水平模糊：条带高度低，纵向无意义
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          // 半透明底色渐变（顶实底虚）
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.surface.withValues(alpha: topOpacity),
                  cs.surface.withValues(alpha: bottomOpacity),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 毛玻璃底部弹窗容器：给 `showModalBottomSheet` 的内容统一加高斯模糊背景。
/// 用法：把 `showModalBottomSheet` 设 `backgroundColor: Colors.transparent`，
/// 并用它包住弹窗内容。
///
/// 「高级玻璃渲染」开启时使用液态玻璃（纯透明 + 果冻拉伸，拖拽超过
/// 轻微滑动阈值即触发，仅点击不晃动）；关闭时保持传统毛玻璃样式。
class FrostedSheet extends StatelessWidget {
  final Widget child;

  /// 弹窗圆角（默认顶部 24）。
  final BorderRadius borderRadius;

  /// 模糊强度，默认 12。
  final double blurSigma;

  /// 背景不透明度，默认 0.75。
  final double opacity;

  /// 背景色（默认取主题 surfaceContainerLow）。
  final Color? color;

  /// 液态玻璃模式的拖拽拉伸强度（0 = 关闭）。
  final double stretch;

  const FrostedSheet({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(24)),
    this.blurSigma = 12.0,
    this.opacity = 0.75,
    this.color,
    this.stretch = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final legacyColor = (color ?? cs.surfaceContainerLow).withValues(
      alpha: opacity,
    );
    if (!SettingsService.fragmentRenderingEnabled) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(color: legacyColor, child: child),
        ),
      );
    }
    final radius = borderRadius.topLeft.x;
    return GlassShellStretch(
      stretch: stretch,
      shell: ClipRRect(
        borderRadius: borderRadius,
        child: NaviGlass(
          radius: radius,
          blur: blurSigma,
          child: const SizedBox.expand(),
        ),
      ),
      content: child,
    );
  }
}

/// 横向可滚动的 Tab 行。
///
/// 除常规拖拽滚动外，还响应鼠标滚轮 / 触控板滑动信号
/// （[PointerScrollEvent]），在内容超出可视宽度时让 Tab 列表水平滚动，
/// 以便查看被隐藏的项。
class ScrollableTabRow extends StatefulWidget {
  const ScrollableTabRow({
    super.key,
    required this.tabs,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> tabs;
  final EdgeInsetsGeometry padding;

  @override
  State<ScrollableTabRow> createState() => _ScrollableTabRowState();
}

class _ScrollableTabRowState extends State<ScrollableTabRow> {
  late final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    // 触控板横向滑动给 dx，鼠标滚轮给 dy；取主轴（绝对值更大者）驱动横滚。
    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta == 0) return;
    final pos = _controller.position;
    final target = (pos.pixels + delta).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    _controller.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerSignal: _onPointerSignal,
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Padding(
                padding: widget.padding,
                child: Row(
                  // 搜索页顶栏左对齐（不足视口时贴左，超出可横向滚动）。
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: widget.tabs,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 毛玻璃搜索头部：搜索栏 + 选项卡合成**一个**连续模糊背景。
///
/// 与分别包两层 `FrostedPanel` 相比，单层模糊观感更协调（无接缝）。
/// 搜索栏通过 [collapsed] 控制高度归零动画，选项卡固定在底部。
///
/// ```dart
/// FrostedSearchHeader(
///   collapsed: _topCollapsed,
///   searchBar: Row(children: [backBtn, searchField]),
///   tabs: [for (final t in types) _buildOvalTab(t)],
/// )
/// ```
class FrostedSearchHeader extends StatelessWidget {
  /// 搜索栏是否收起（高度动画归零）。
  final bool collapsed;

  /// 搜索栏内容（返回键 + 搜索框等）。
  final Widget searchBar;

  /// 选项卡内容（已构建好的 Tab 按钮列表）。
  final List<Widget> tabs;

  /// 长按时显示的液态玻璃 Tab 配置；为空时保持普通选项卡。
  final List<GlassTab>? glassTabs;

  /// 长按拖动时的当前选中项。
  final int? glassSelectedIndex;

  /// 长按拖动切换 Tab 的回调。
  final ValueChanged<int>? onGlassTabSelected;

  /// 选项卡栏高度，默认 48。
  final double tabBarHeight;

  const FrostedSearchHeader({
    super.key,
    required this.collapsed,
    required this.searchBar,
    required this.tabs,
    this.glassTabs,
    this.glassSelectedIndex,
    this.onGlassTabSelected,
    this.tabBarHeight = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedPanel(
      opacity: 0.75,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 搜索栏：收起/展开动画（heightFactor 0→1 + 裁剪） ──
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: collapsed ? 0.0 : 1.0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return ClipRect(
                  child: Align(
                    heightFactor: value,
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                );
              },
              child: searchBar,
            ),
            // ── 选项卡（裁剪防 BOTTOM OVERFLOWED，兼容下方安全区）──
            ClipRect(
              child: SizedBox(
                height: tabBarHeight,
                width: double.infinity,
                child: _buildTabs(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    final normalTabs = ScrollableTabRow(tabs: tabs);
    final glassTabs = this.glassTabs;
    final glassIndex = glassSelectedIndex;
    final onGlassTabSelected = this.onGlassTabSelected;
    if (glassTabs == null ||
        glassIndex == null ||
        onGlassTabSelected == null ||
        glassTabs.isEmpty) {
      return normalTabs;
    }
    return LongPressGlassTabSwitcher(
      child: normalTabs,
      tabs: glassTabs,
      selectedIndex: glassIndex,
      onIndexChanged: onGlassTabSelected,
      barHeight: tabBarHeight - 4,
    );
  }
}

/// M3 Expressive 风格折叠毛玻璃标题栏。
///
/// 展开时显示大标题（headlineMedium），折叠后切换为毛玻璃背景 + 小标题。
///
/// ```dart
/// ExpressiveSliverAppBar(
///   title: 'WebDAV 备份',
///   leading: MorphIconButton(
///     icon: Icons.arrow_back,
///     onTap: () => Navigator.pop(context),
///   ),
///   actions: [
///     MorphIconButton(icon: Icons.qr_code_scanner, onTap: _scan),
///   ],
/// )
/// ```
class ExpressiveSliverAppBar extends StatelessWidget {
  /// 标题文字（展开 & 折叠态共用）
  final String title;

  /// 左上角 leading widget（通常是 MorphIconButton）
  final Widget? leading;

  /// 右侧 actions
  final List<Widget>? actions;

  /// 展开高度（含状态栏），默认 130
  final double expandedHeight;

  /// 是否固定（pinned），默认 true
  final bool pinned;

  /// 展开态标题样式覆盖（默认 headlineMedium / w500）
  final TextStyle? expandedTitleStyle;

  /// 折叠态标题样式覆盖（默认 titleLarge / w500）
  final TextStyle? collapsedTitleStyle;

  /// 毛玻璃模糊强度，默认 10
  final double blurSigma;

  /// 毛玻璃背景不透明度，默认 0.7
  final double blurOpacity;

  /// 快速连续点击标题的回调（用于彩蛋等）
  final VoidCallback? onTitleRepeatedTap;

  const ExpressiveSliverAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.expandedHeight = 130.0,
    this.pinned = true,
    this.expandedTitleStyle,
    this.collapsedTitleStyle,
    this.blurSigma = 10.0,
    this.blurOpacity = 0.7,
    this.onTitleRepeatedTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const leadingWidth = 48.0;
    const dur = Duration(milliseconds: 260);
    const curve = Curves.easeInOut;

    final hasLeading = leading != null;
    return SliverAppBar(
      pinned: pinned,
      leading: leading,
      automaticallyImplyLeading: hasLeading,
      actions: actions,
      backgroundColor: Colors.transparent,
      expandedHeight: expandedHeight,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final safePadding = MediaQuery.of(context).padding;
          final isCollapsed =
              constraints.biggest.height <= kToolbarHeight + safePadding.top;

          return Stack(
            children: [
              // ── 折叠态毛玻璃背景 ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: isCollapsed ? 1 : 0,
                  duration: dur,
                  curve: curve,
                  child: FrostedPanel(
                    blurSigma: blurSigma,
                    opacity: blurOpacity,
                    child: SizedBox(height: kToolbarHeight + safePadding.top),
                  ),
                ),
              ),

              // ── 展开态大标题：淡出 + 位移 ──
              AnimatedOpacity(
                opacity: isCollapsed ? 0 : 1,
                duration: dur,
                curve: curve,
                child: AnimatedContainer(
                  duration: dur,
                  curve: curve,
                  alignment: Alignment.bottomLeft,
                  padding: EdgeInsets.only(
                    left: 16.0,
                    top: safePadding.top,
                    bottom: 16.0,
                  ),
                  child: GestureDetector(
                    onTap: onTitleRepeatedTap,
                    child: Text(
                      title,
                      style:
                          expandedTitleStyle ??
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                    ),
                  ),
                ),
              ),

              // ── 折叠态小标题：淡入 + 位移 ──
              AnimatedOpacity(
                opacity: isCollapsed ? 1 : 0,
                duration: dur,
                curve: curve,
                child: AnimatedContainer(
                  duration: dur,
                  curve: curve,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(
                    left: hasLeading
                        ? leadingWidth + safePadding.left + 8.0
                        : 16.0,
                    top: safePadding.top,
                  ),
                  child: GestureDetector(
                    onTap: onTitleRepeatedTap,
                    child: Text(
                      title,
                      style:
                          collapsedTitleStyle ??
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
