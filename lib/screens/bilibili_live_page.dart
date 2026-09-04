// lib/screens/bilibili_live_page.dart
//
// 「直播」区块页（PiliPlus 直播首页形态，单页直播标签浏览）：
//   - 内容全部来自 widgets/live_tag_feed.dart 的 LiveTagFeed：
//     顶部关注横条 + 「推荐 / 一级分区」标签行（点分区即在本页切换房间流）
//     + 二级分区（标签）/ 排序行 + 行尾「全部分类」宫格入口
//   - 宽屏 SideBarShell 内嵌时不画 AppBar，由外层壳提供标题区
// 数据与卡片见 services/bilibili_live_service.dart / widgets/live_room_grid.dart。
import 'package:flutter/material.dart';

import 'package:naviflash/widgets/live_tag_feed.dart';

class BilibiliLivePage extends StatelessWidget {
  /// 宽屏侧边栏内嵌模式：不画自己的 AppBar（外层壳已有标题区）、背景透明。
  final bool embeddedInShell;

  const BilibiliLivePage({super.key, this.embeddedInShell = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final feed = const LiveTagFeed();

    if (embeddedInShell) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(bottom: false, child: feed),
      );
    }
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        title: const Text('直播'),
        backgroundColor: cs.surfaceContainer,
      ),
      body: SafeArea(child: feed),
    );
  }
}
