// lib/widgets/load_retry_pill.dart
//
// 内容页「加载失败」的统一重试控件：右下角 Extended FAB 观感（M3 胶囊：
// 阴影 + 圆角 + icon +「重新加载」文字），与页面上其它右下角胶囊按钮
// （发评论 / 单列·多列切换）同一材质语言。
//
// 用法：
//   - 页面有自己的 Scaffold：直接放进 floatingActionButton 槽
//     （配合 Padding 抬离系统手势条，样式参考各页网格切换 FAB）；
//   - 嵌套在 TabBarView / 列表 Stack 里：外层用 Positioned 包裹
//     （right: 16, bottom: 安全区 + 底栏高 + 余量）。
import 'package:flutter/material.dart';

/// 右下角 Extended FAB 样式的「重新加载」按钮本体（不含定位）。
class LoadRetryPill extends StatelessWidget {
  const LoadRetryPill({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.secondaryContainer,
      elevation: 4,
      shadowColor: cs.shadow.withValues(alpha: 0.24),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onRetry,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 18,
                color: cs.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                '重新加载',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 便捷定位版：直接放进内容区 Stack 里即可（右下角）。
class PositionedRetryFab extends StatelessWidget {
  const PositionedRetryFab({
    super.key,
    required this.onRetry,
    this.bottomOffset,
  });

  final VoidCallback onRetry;

  /// 距内容区底边距离（默认 = 底部安全区 + 24）。
  final double? bottomOffset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: bottomOffset ?? MediaQuery.paddingOf(context).bottom + 24,
      child: LoadRetryPill(onRetry: onRetry),
    );
  }
}
