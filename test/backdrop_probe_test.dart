// 验证：被覆盖页监听 FrostedHeroRoute.backdropProgress 时，
// push/pop 全程无「setState during build」异常，且进度非线性推进；
// 转场完成后进度归零（避免残留值污染下一段转场）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviflash/services/settings_service.dart';
import 'package:naviflash/widgets/frosted_route.dart';

const _tag = 'probe_tag';

/// 与 BilibiliSearchPage._wrapIosBackdrop 相同结构的监听层。
class _BackdropProbe extends StatefulWidget {
  final Widget child;
  const _BackdropProbe({required this.child});

  @override
  State<_BackdropProbe> createState() => _BackdropProbeState();
}

class _BackdropProbeState extends State<_BackdropProbe> {
  @override
  Widget build(BuildContext context) {
    final secondary = ModalRoute.of(context)?.secondaryAnimation;
    return AnimatedBuilder(
      animation: Listenable.merge([
        if (secondary != null) secondary,
        FrostedHeroRoute.backdropProgress,
      ]),
      child: widget.child,
      builder: (context, child) {
        final raw =
            (secondary?.value ?? 0) > FrostedHeroRoute.backdropProgress.value
            ? secondary!.value
            : FrostedHeroRoute.backdropProgress.value;
        final t = Curves.easeOutCubic.transform(raw.clamp(0.0, 1.0));
        return Opacity(
          opacity: (1 - 0.45 * t).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 1 - 0.10 * t,
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16 * t),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

void main() {
  testWidgets('监听 backdropProgress 时 push/pop 无异常且进度推进', (tester) async {
    SettingsService.heroTransitionBlurEnabled = true;
    await tester.pumpWidget(
      MaterialApp(
        home: _BackdropProbe(
          child: Scaffold(
            body: Center(
              child: Hero(
                tag: _tag,
                child: Container(
                  width: 120,
                  height: 68,
                  color: const Color(0xFFFF0000),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final ctx = tester.element(find.byType(Scaffold));
    Navigator.of(ctx).push(
      heroTransitionRoute(
        heroZoom: true,
        page: Scaffold(
          body: Hero(tag: _tag, child: const SizedBox.expand()),
        ),
      ),
    );
    await tester.pump();
    final samples = <String>[];
    var midProgress = 0.0;
    var cumulative = 0;
    for (final ms in [100, 150, 250, 300]) {
      cumulative += ms;
      await tester.pump(Duration(milliseconds: ms));
      expect(
        tester.takeException(),
        isNull,
        reason: 'push 转场第 $cumulative ms 出现异常（setState during build？）',
      );
      samples.add(
        'p${cumulative}ms=${FrostedHeroRoute.backdropProgress.value.toStringAsFixed(3)}',
      );
      if (cumulative == 250) {
        midProgress = FrostedHeroRoute.backdropProgress.value;
      }
    }
    debugPrint('push: ${samples.join(' ')}');
    expect(
      midProgress,
      greaterThan(0.4),
      reason: 'push 转场中段（250ms）backdropProgress 应显著推进',
    );
    expect(
      FrostedHeroRoute.backdropProgress.value,
      0,
      reason: '转场完成后 backdropProgress 应归零（不残留污染下一段转场）',
    );

    Navigator.of(ctx).pop();
    await tester.pump();
    for (final ms in [100, 150, 250, 300]) {
      await tester.pump(Duration(milliseconds: ms));
      expect(
        tester.takeException(),
        isNull,
        reason: 'pop 转场第 $ms ms 出现异常（setState during build？）',
      );
    }
    expect(
      FrostedHeroRoute.backdropProgress.value,
      lessThan(0.05),
      reason: 'pop 结束后 backdropProgress 应归零',
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('连续推入时由最新路由接管景深进度', (tester) async {
    SettingsService.heroTransitionBlurEnabled = true;
    await tester.pumpWidget(
      MaterialApp(
        home: _BackdropProbe(
          child: Scaffold(
            body: Center(
              child: Hero(
                tag: _tag,
                child: const SizedBox(width: 120, height: 68),
              ),
            ),
          ),
        ),
      ),
    );
    final nav = Navigator.of(tester.element(find.byType(Scaffold)));

    nav.push(
      heroTransitionRoute(
        heroZoom: true,
        page: Scaffold(
          body: Hero(tag: _tag, child: const SizedBox.expand()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(FrostedHeroRoute.backdropProgress.value, greaterThan(0.1));

    // 第一段还没结束就继续 push，第二段必须立即成为唯一进度源。
    nav.push(
      heroTransitionRoute(
        heroZoom: true,
        page: const Scaffold(body: Center(child: Text('second'))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      FrostedHeroRoute.backdropProgress.value,
      lessThan(0.3),
      reason: '连续 push 后应读取第二段约 100ms 的进度，而不是第一段的旧进度',
    );

    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(FrostedHeroRoute.backdropProgress.value, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
