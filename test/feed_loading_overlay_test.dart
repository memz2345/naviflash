// 回归测试：FeedLoadingOverlay 必须放在 Stack 里，不能混进 CustomScrollView.slivers。
//
// 起因：bilibili_recommend_page.dart 的 _buildBangumiFeed 改造时，Stack 包裹被
// 半途回滚（`child: CustomScrollView(` 改回来了但闭合仍是 Stack 版的），导致
// FeedLoadingOverlay 掉进了 `slivers: [...]` 列表 → 运行时抛
// "A RenderPositionedBox expected a child of type RenderSliver ..." → 番剧页红屏。
//
// 注意：`flutter analyze` **抓不到**这类错误——`slivers` 的静态类型是
// `List<Widget>`，混入普通 Widget 语法完全合法，只有运行时才做 Sliver 类型检查。
// 所以这里用 widget test 锁死。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:naviflash/widgets/feed_loading_overlay.dart';

void main() {
  testWidgets('FeedLoadingOverlay 放在 Stack 中不抛异常', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
              FeedLoadingOverlay(
                loadingMore: true,
                hasMore: true,
                bottomOffset: 76,
              ),
            ],
          ),
        ),
      ),
    );

    // 能正常构建，且没有渲染层异常
    expect(tester.takeException(), isNull);
    expect(find.byType(FeedLoadingOverlay), findsOneWidget);
  });

  testWidgets('FeedLoadingOverlay 误放进 slivers 会抛异常（反证测试有效）',
      (tester) async {
    Object? caught;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
              // 故意放错位置：普通 Widget 混进 slivers
              const FeedLoadingOverlay(
                loadingMore: true,
                hasMore: true,
                bottomOffset: 76,
              ),
            ],
          ),
        ),
      ),
    );
    caught = tester.takeException();
    expect(caught, isNotNull, reason: '放错位置应当抛 Sliver 类型错误');
  });

  testWidgets('loadingMore=false 且 hasMore=true 时不占位', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FeedLoadingOverlay(
                loadingMore: false,
                hasMore: true,
                bottomOffset: 76,
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // 正常浏览中应当完全不渲染（SizedBox.shrink）
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
