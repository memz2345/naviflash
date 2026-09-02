// 复现验证：推荐页无限循环轮播（CarouselView.weighted + infinite: true）
// 在缓存区（cache extent）跨越一整圈 item 时，同一个 child widget 会在
// 多个 slot 同时构建 → 同名 Hero tag 重复 → 点击视频触发 Hero 飞行时
// 抛「There are multiple heroes that share the same tag within a subtree」。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

int _duplicatedTagCount(WidgetTester tester) {
  final tags = <Object, int>{};
  for (final e in tester.elementList(find.byType(Hero))) {
    final hero = e.widget as Hero;
    tags[hero.tag] = (tags[hero.tag] ?? 0) + 1;
  }
  var dup = 0;
  tags.forEach((tag, count) {
    if (count > 1) {
      // ignore: avoid_print
      print('  重复 tag: $tag × $count');
      dup++;
    }
  });
  return dup;
}

void main() {
  for (final size in [const Size(1024, 768), const Size(400, 800)]) {
    testWidgets('$size 无限循环加权轮播不同滚动位置不应产生重复 Hero tag',
        (tester) async {
      await setSurface(tester, size);
      final controller = CarouselController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                height: 300,
                child: CarouselView.weighted(
                  controller: controller,
                  flexWeights: const [1, 7, 1],
                  itemSnapping: true,
                  consumeMaxWeight: false,
                  infinite: true,
                  children: [
                    for (var i = 0; i < 5; i++)
                      Hero(
                        tag: 'bili_rcmd_banner_BV$i',
                        child: const ColoredBox(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      var found = false;
      // 逐帧模拟自动播放推进（推荐页每 4s 推进一步、步长 = 视口/9）
      for (var i = 0; i < 120; i++) {
        final pos = controller.position;
        final step = pos.viewportDimension / 9;
        controller.animateTo(
          pos.pixels + step,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
        );
        await tester.pump(const Duration(milliseconds: 220));
        if (_duplicatedTagCount(tester) > 0) {
          found = true;
          // ignore: avoid_print
          print(
            '  第 $i 步（pixels=${controller.position.pixels.toStringAsFixed(1)}）出现重复 Hero tag',
          );
          break;
        }
      }
      expect(found, isFalse,
          reason: '$size 下无限轮播不应出现同名 Hero tag 重复'
              '（重复会导致点击视频报错）');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
