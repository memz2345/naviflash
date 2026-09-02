// lib/widgets/ios_zoom_hero.dart
//
// iOS 开 App 式「整页 Hero」转场的飞行元素构造，视频页 / 番剧页 / 专栏页共用。
//
// 背景：此前三处页面各有一份复制粘贴的实现（视频页 bilibili_video_page、
// 番剧页 bilibili_bangumi_page、专栏页 article_page），任何一处漏改都会
// 出现「进入飞整页、返回只飞封面」这类进出不对称的问题。统一到本文件后，
// 只改一次即三页同步。
//
// 行为：
//   - 进入 / 返回都飞「整页本体」：pop 时 target 是 fromContext、push 时是
//     toContext，两者都是目标整页 Hero，可完全共用一份构造，进出对称；
//     （历史坑：返回曾只渲染来源卡片的封面本体，缩回全程就是一张封面图）
//   - 整页按全屏尺寸布局，再用 FittedBox cover 缩放到当前飞行矩形，避免
//     飞行期间小矩形硬布局导致 RenderFlex overflow；
//   - 返回时对齐顶部（Alignment.topCenter）：终点矩形即卡片封面位，取页面
//     顶部（播放器 / 封面区）与来源卡片衔接，避免结尾画面跳变；
//   - 返回保持不透明：fadeIn 随弹栈动画反向归零，若沿用进入的 0.35 → 1
//     淡入，缩回结尾会淡到 0.35，飞行结束露出真实卡片时会有明显跳变。
//
// 性能 / 安全性：Hero 飞行期间源 / 目标 Hero 的 child 都被 placeholder
// （SizedBox.fromSize，不含 child）顶掉不渲染，屏幕上整页树只有飞行元素
// 这一份 —— 因此整页里带 GlobalKey 也不会 duplicate，播放器纹理也只有一份。
import 'package:flutter/material.dart';

/// 飞行元素圆角（与来源卡片 12px 圆角一致）。
const double kZoomHeroFlightRadius = 12.0;

/// 整页 Hero 的飞行元素（供 Hero.flightShuttleBuilder 直接返回）。
Widget iosZoomHeroFlightShuttle({
  required Animation<double> animation,
  required HeroFlightDirection direction,
  required BuildContext fromContext,
  required BuildContext toContext,
  double flightRadius = kZoomHeroFlightRadius,
}) {
  final isPop = direction == HeroFlightDirection.pop;
  final target = isPop ? fromContext : toContext;
  final heroWidget = target.widget as Hero;
  // 卡片飞行期间新内容渐显（前段快速淡入，到站前全不透明）
  final fadeIn = CurvedAnimation(
    parent: animation,
    curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
  );
  return AnimatedBuilder(
    animation: fadeIn,
    builder: (context, _) {
      // Hero 在 push 中途被 pop 时会复用原来的 shuttle，direction 仍是
      // push；用真实动画状态识别反向飞行，保持当前画面连续且不在返回
      // 末尾淡出。
      final returning =
          isPop || animation.status == AnimationStatus.reverse;
      final screen = MediaQuery.sizeOf(context);
      final Widget flying = ClipRRect(
        borderRadius: BorderRadius.circular(flightRadius),
        clipBehavior: Clip.antiAlias,
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: returning ? Alignment.topCenter : Alignment.center,
          clipBehavior: Clip.hardEdge,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(flightRadius),
            child: SizedBox(
              width: screen.width,
              height: screen.height,
              child: heroWidget.child,
            ),
          ),
        ),
      );
      return Opacity(
        opacity: returning ? 1.0 : 0.35 + 0.65 * fadeIn.value,
        child: flying,
      );
    },
  );
}
