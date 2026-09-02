// lib/widgets/comment/tap_avatar_hero.dart
//
// 头像点击跳转 UP 主空间的 Hero 包装：仅在点击时挂载 Hero。
//
// 评论区列表中同一 UP 可能多次出现（楼主 + 自己的回复），若静态包 Hero
// 会出现同一路由内 tag 重复，Hero 起飞时触发断言；本组件保证同一时刻
// 只有被点击的头像持有 Hero tag。
import 'package:flutter/material.dart';

class TapAvatarHero extends StatefulWidget {
  /// Hero tag（如 'bili_space_avatar_123'）。为 null 时不挂载 Hero
  /// （整页 Hero 包裹期间由 CommentTile 传入 null，避免 Hero 嵌套断言）。
  final String? heroTag;

  /// 头像 widget。
  final Widget avatar;

  /// 点击回调（应 push 目标页面，可返回 Future）。
  final Future<void> Function() onTap;

  const TapAvatarHero({
    super.key,
    required this.heroTag,
    required this.avatar,
    required this.onTap,
  });

  @override
  State<TapAvatarHero> createState() => _TapAvatarHeroState();
}

class _TapAvatarHeroState extends State<TapAvatarHero> {
  bool _flying = false;

  Future<void> _handleTap() async {
    setState(() => _flying = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) setState(() => _flying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: (_flying && widget.heroTag != null)
          ? Hero(tag: widget.heroTag!, child: widget.avatar)
          : widget.avatar,
    );
  }
}
