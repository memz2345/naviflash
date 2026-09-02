// lib/widgets/comment/comment_composer_fab.dart
//
// 评论 / 回复区通用「发评论 / 发回复」悬浮按钮。
//   - 文字使用 AnimatedSwitcher（横向收缩 + 淡出）收起 / 展开动画：
//     点击 FAB 弹出输入面板后文字隐藏，面板关闭后文字复原；
//     从评论区进入回复页（或返回）时，被压在栈下的页面 isCurrent=false
//     文字隐藏，栈顶页面 isCurrent=true 文字显示，配合 Hero 形成
//     「图标变换后再显示文字」的跨页过渡。
//   - 整颗按钮为自定义 Material 圆角方形，宽度随文字平滑塌缩成圆角方形图标按钮。
import 'package:flutter/material.dart';

/// 评论 / 回复发送悬浮按钮。
/// [heroTag] 非空时包裹 Hero：点击 FAB 弹出的输入面板「发送」按钮使用
/// 同一 tag，于是 FAB 平滑飞到发送按钮位置；关闭面板时反向飞回原位 +
/// 文字。务必每页传唯一 tag，避免路由栈里多个同 tag Hero 冲突。
class CommentComposerFab extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  /// 文字是否可见。通常传 `ModalRoute.of(context)?.isCurrent ?? true`，
  /// 由路由栈状态自动驱动（输入面板或下级页面压栈时隐藏）。
  final bool labelVisible;

  /// 共享元素 Hero tag；评论区与回复详情页须一致才能跨页飞接。
  final Object? heroTag;

  const CommentComposerFab({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.labelVisible,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fab = Material(
      color: cs.secondaryContainer,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: cs.onSecondaryContainer),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SizeTransition(
                    axis: Axis.horizontal,
                    sizeFactor: anim,
                    child: child,
                  ),
                ),
                child: labelVisible
                    ? Padding(
                        key: const ValueKey(true),
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey(false)),
              ),
            ],
          ),
        ),
      ),
    );
    if (heroTag != null) return Hero(tag: heroTag!, child: fab);
    return fab;
  }
}
