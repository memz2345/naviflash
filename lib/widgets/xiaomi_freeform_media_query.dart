// lib/widgets/xiaomi_freeform_media_query.dart
import 'package:flutter/material.dart';

/// 小米 HyperOS2 + Android 15 在小窗(freeform)/悬浮窗模式下，
/// 会把 captionBar 的 bounding rect 错误地当作整屏，
/// 导致 `MediaQuery.padding` / `viewPadding` 的 top 返回离谱值
/// （640、737 甚至更大），进而把 `SafeArea` 下的布局狠狠往下挤。
///
/// 上游 issue：https://github.com/flutter/flutter/issues/161086 （Open，未修复）
///
/// 这里在应用侧兜底：一旦 top/bottom inset 超过「窗口高度的一半」，
/// 就判定为小米小窗的异常值并归零（正常状态栏/导航栏 inset 远小于此）。
MediaQueryData sanitizeXiaomiFreeformPadding(MediaQueryData data) {
  final height = data.size.height;
  if (height <= 0) return data;

  // 阈值：异常 inset 通常远超窗口高度的一半（例如窗口高 400、top 却是 640）。
  final maxInset = height * 0.5;

  double top = data.padding.top;
  double bottom = data.padding.bottom;
  double viewTop = data.viewPadding.top;
  double viewBottom = data.viewPadding.bottom;

  if (top > maxInset) top = 0.0;
  if (bottom > maxInset) bottom = 0.0;
  if (viewTop > maxInset) viewTop = 0.0;
  if (viewBottom > maxInset) viewBottom = 0.0;

  // 没有异常则原样返回，零开销。
  if (top == data.padding.top &&
      bottom == data.padding.bottom &&
      viewTop == data.viewPadding.top &&
      viewBottom == data.viewPadding.bottom) {
    return data;
  }

  return data.copyWith(
    padding: data.padding.copyWith(top: top, bottom: bottom),
    viewPadding: data.viewPadding.copyWith(top: viewTop, bottom: viewBottom),
  );
}

/// 独立 Widget 包装器（备选用法，本项目已在 main.dart 的 builder 内直接调用
/// [sanitizeXiaomiFreeformPadding]，无需再包一层；此 Widget 供其他场景复用）。
class XiaomiFreeformMediaQuery extends StatelessWidget {
  final Widget child;
  const XiaomiFreeformMediaQuery({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: sanitizeXiaomiFreeformPadding(MediaQuery.of(context)),
      child: child,
    );
  }
}
