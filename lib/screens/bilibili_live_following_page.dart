// lib/screens/bilibili_live_following_page.dart
//
// 「我的关注」直播间列表页（PiliPlus LiveFollowPage 对应物）：
// 直播首页关注横条点「查看全部」进入；登录态下分页列出正在直播的关注主播。
import 'package:flutter/material.dart';

import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/widgets/live_room_grid.dart';

class BilibiliLiveFollowingPage extends StatelessWidget {
  const BilibiliLiveFollowingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        title: const Text('我的关注', style: TextStyle(fontSize: 16)),
        backgroundColor: cs.surfaceContainer,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: BilibiliAccountService.instance,
          builder: (context, _) {
            final account = BilibiliAccountService.instance;
            if (!account.isLoggedIn) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.live_tv_outlined,
                        size: 48, color: cs.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(
                      '登录后可以看到关注的主播',
                      style:
                          TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BilibiliLoginScreen(),
                        ),
                      ),
                      child: const Text('去登录'),
                    ),
                  ],
                ),
              );
            }
            return LiveRoomGrid(
              resetKey: 'follow-list-${account.mid}',
              loader: (page) => BilibiliLiveService.fetchFollowing(page: page),
              emptyText: '关注的主播都没在播',
              pageSize: 9,
            );
          },
        ),
      ),
    );
  }
}
