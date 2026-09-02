// lib/widgets/feed_loading_overlay.dart
//
// 浮动在底栏上方的加载指示器（参照 PiliPlus / 图 1 样式）：
//   - loadingMore = true → 浮动圆形 LoadingIndicatorM3E，停在底栏上方
//   - loadingMore = false && hasMore = false → 显示「已全部加载」文字
//   - 其余正常浏览状态 → 完全透明、不占任何空间
//
// 用法（与 BouncingScrollPhysics 的硬停配合，消除触底拖出空白的问题）：
//   Stack(
//     children: [
//       content (CustomScrollView / ListView ...),
//       FeedLoadingOverlay(
//         loadingMore: data.loadingMore,
//         hasMore: data.hasMore,
//         bottomOffset: kFloatingBarHeight + MediaQuery.padding.bottom + 12,
//       ),
//     ],
//   )
//
// 注意：该 widget 必须直接放在 Stack 的 children 里（用 `Positioned`），
// 别再包一层 Container/Column / Scaffold。

import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';

class FeedLoadingOverlay extends StatelessWidget {
  const FeedLoadingOverlay({
    super.key,
    required this.loadingMore,
    required this.hasMore,
    required this.bottomOffset,
  });

  /// 顶部下拉刷新 / 触底加载中。true 时显示浮动加载圈。
  final bool loadingMore;

  /// 是否还有更多数据可加载。false 时显示「已全部加载」文案。
  final bool hasMore;

  /// 距离屏幕底边的距离。建议值：
  ///   - 页面有底部玻璃底栏（`barHeight + safePadding + 16`）。
  ///   - 否则仅 `safePadding.bottom + 16`。
  ///
  /// 调用方控制以匹配每个页面不同的底栏可见条件（独立页 vs embedded vs 横竖屏）。
  final double bottomOffset;

  @override
  Widget build(BuildContext context) {
    if (!loadingMore && hasMore) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: bottomOffset,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: loadingMore
              ? const KeyedSubtree(
                  key: ValueKey('FeedLoadingOverlay.loading'),
                  child: _FloatingDisc(),
                )
              : KeyedSubtree(
                  key: const ValueKey('FeedLoadingOverlay.nomore'),
                  child: _LoadedChip(
                    label: AppLocalizations.of(context).searchAllLoaded,
                  ),
                ),
        ),
      ),
    );
  }
}

/// 浮动圆形指示器：Material 圆形 surface 背景 + LoadingIndicatorM3E 内核，
/// 旋转动画与原 LoadingIndicatorM3E 一致。
class _FloatingDisc extends StatelessWidget {
  const _FloatingDisc();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      shape: const CircleBorder(),
      color: cs.surface,
      elevation: 6,
      shadowColor: cs.shadow.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: 24,
          height: 24,
          child: LoadingIndicatorM3E(color: cs.primary),
        ),
      ),
    );
  }
}

/// 「已全部加载」文字 chip。透明背景 + 浅色文本，触底时浮起来一行。
class _LoadedChip extends StatelessWidget {
  const _LoadedChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: cs.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
