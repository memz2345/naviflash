// 回归测试：全局滚动手感（NaviScrollBehavior）。
//
// 背景：Android 触屏上 Material 默认滚动（Clamping 硬停 + 光晕）太违和，
// 用户拍板统一 iOS 橡皮筋（Bouncing 拉伸回弹）。main.dart 通过
// MaterialApp.scrollBehavior 提供兜底——只影响未显式传 physics 的组件。
//
// 锁三条线：
//  1. android / iOS 顶层 physics 是 BouncingScrollPhysics（iOS 默认也 Bouncing）；
//  2. windows 保持 ClampingScrollPhysics（桌面原生，不强制橡皮筋）；
//  3. TabBarView / PageView 的翻页 snap 不被全局设置顶掉——
//     Flutter 在 page_view.dart 无条件用 PageScrollPhysics 包外层。
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/main.dart';

/// physics 链（parent 逐层）中是否存在指定类型。
bool _chainContains(ScrollPhysics? p, Type type) {
  while (p != null) {
    if (p.runtimeType == type) return true;
    p = p.parent;
  }
  return false;
}

/// 找到页面上第一个（ListView 的）Scrollable position。
ScrollPhysics _listPhysics(WidgetTester tester) {
  final state = tester.state<ScrollableState>(
    find
        .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
        .first,
  );
  return state.position.physics;
}

Future<void> _pumpList(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      scrollBehavior: const NaviScrollBehavior(),
      home: Scaffold(
        body: ListView(
          children: [
            for (var i = 0; i < 50; i++) ListTile(title: Text('item $i')),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('android：未显式 physics 的列表获得 Bouncing（iOS 橡皮筋）', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await _pumpList(tester);
    final physics = _listPhysics(tester);
    expect(_chainContains(physics, BouncingScrollPhysics), isTrue,
        reason: 'android physics 链应含 BouncingScrollPhysics（顶层可能被框架包 AlwaysScrollable）');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('ios：默认已是 Bouncing，保持不动', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await _pumpList(tester);
    expect(_chainContains(_listPhysics(tester), BouncingScrollPhysics), isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('windows：保持桌面原生 Clamping', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    await _pumpList(tester);
    expect(_chainContains(_listPhysics(tester), ClampingScrollPhysics), isTrue,
        reason: '桌面不强制橡皮筋，保持平台默认');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('TabBarView 翻页 snap 不被全局 Bouncing 顶掉', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const NaviScrollBehavior(),
        home: DefaultTabController(
          length: 3,
          child: Scaffold(
            body: TabBarView(
              children: [
                for (var i = 0; i < 3; i++)
                  ListView(children: [for (var j = 0; j < 20; j++) Text('$i-$j')]),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // TabBarView 内部 Scrollable：physics 链必须含 PageScrollPhysics（snap）
    final tabPhysics = tester
        .widget<Scrollable>(find.byType(Scrollable).first)
        .controller!
        .position
        .physics;
    expect(_chainContains(tabPhysics, PageScrollPhysics), isTrue,
        reason: '全局 Bouncing 不应顶掉 TabBarView 的翻页 snap');
    debugDefaultTargetPlatformOverride = null;
  });
}
