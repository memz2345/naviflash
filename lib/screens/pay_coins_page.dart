// lib/screens/pay_coins_page.dart
//
//   2233 马里奥 / 枪娘投币动画，1 枚 / 2 枚金币可选（滑动 / 鼠标滚轮切换），
//   点击 / 上滑投币。
import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';

typedef OnPayCoin = void Function(int coins, bool withLike);

class PayCoinsPage extends StatefulWidget {
  /// 投币结果回调：金币数（1/2）+ 是否同时点赞。
  final OnPayCoin onPayCoin;

  /// 是否已投过 1 枚硬币。
  final bool hasCoin;

  /// 是否有版权（有版权才能投 2 枚，否则只能投 1 枚）。
  final bool hasCopyright;

  /// 当前硬币余额（null = 未知，跳过余额校验）。
  final num? coins;

  /// 「同时点赞」初始值。
  final bool coinWithLike;

  const PayCoinsPage({
    super.key,
    required this.onPayCoin,
    required this.hasCoin,
    required this.hasCopyright,
    this.coins,
    this.coinWithLike = true,
  });

  /// 以淡入透明路由打开投币页（弹出层：不触发下层页面 iOS 景深缩放）。
  static Future<void> toPayCoinsPage(
    BuildContext context, {
    required OnPayCoin onPayCoin,
    required bool hasCoin,
    required bool hasCopyright,
    num? coins,
    bool coinWithLike = true,
  }) async {
    PopupOverlayGuard.open();
    try {
      await Navigator.of(context).push(
        PageRouteBuilder<void>(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 225),
          pageBuilder: (context, animation, secondaryAnimation) =>
              FadeTransition(
            opacity: animation,
            child: PayCoinsPage(
              onPayCoin: onPayCoin,
              hasCoin: hasCoin,
              hasCopyright: hasCopyright,
              coins: coins,
              coinWithLike: coinWithLike,
            ),
          ),
        ),
      );
    } finally {
      PopupOverlayGuard.close();
    }
  }

  @override
  State<PayCoinsPage> createState() => _PayCoinsPageState();
}

class _PayCoinsPageState extends State<PayCoinsPage>
    with TickerProviderStateMixin {
  late final GlobalKey _key = GlobalKey();
  late final bool _hasCopyright = widget.hasCopyright;
  late bool _isPaying = false;
  PageController? _controller;
  late bool _coinWithLike = widget.coinWithLike;
  late int _pageIndex = 0;

  late final AnimationController _slide22Controller;
  late final Animation<Offset> _slide22Anim;
  late final AnimationController _scale22Controller;
  late final AnimationController _coinController;
  late final Animation<Offset> _coinSlideAnim;
  late final Animation<double> _coinFadeAnim;
  late final AnimationController _boxAnimController;
  late final Animation<Offset> _boxAnim;

  Timer? _timer;
  late int _thunderIndex = -1;
  static const List<String> _thunderImages = [
    'assets/paycoins/ic_thunder_1.png',
    'assets/paycoins/ic_thunder_2.png',
    'assets/paycoins/ic_thunder_3.png',
  ];

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  num? get _coins => widget.coins;

  bool _canPay(int index) {
    if (index == 1 && widget.hasCoin) {
      return false;
    }
    final coins = _coins;
    if (coins == null || coins >= 1 + index) {
      return true;
    }
    return false;
  }

  String _getPayImage(int index, bool canPay) {
    if (!canPay) {
      return 'assets/paycoins/ic_22_not_enough_pay.png';
    }
    return index == 0
        ? 'assets/paycoins/ic_22_mario.png'
        : 'assets/paycoins/ic_22_gun_sister.png';
  }

  Color _getPayFilter(int index) =>
      _canPay(index) ? Colors.transparent : const Color(0x66000000);

  @override
  void initState() {
    super.initState();
    if (_hasCopyright) {
      _controller = PageController(viewportFraction: 0.30);
    }

    _slide22Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );
    _slide22Anim = _slide22Controller.drive(
      Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, -0.2)),
    );
    _scale22Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
      lowerBound: 1.0,
      upperBound: 1.1,
    );
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _coinSlideAnim = _coinController.drive(
      Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0.0, -2.0),
      ).chain(CurveTween(curve: const Interval(0.0, 2 / 3))),
    );
    _coinFadeAnim = _coinController.drive(
      Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: const Interval(2 / 3, 1.0))),
    );
    _boxAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );
    _boxAnim = _boxAnimController.drive(
      Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, -0.2)),
    );

    WidgetsBinding.instance.addPostFrameCallback(_scale);
  }

  @override
  void dispose() {
    _cancelTimer();
    _slide22Controller.dispose();
    _scale22Controller.dispose();
    _coinController.dispose();
    _boxAnimController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _scale([_]) {
    _scale22Controller.forward().whenComplete(_scale22Controller.reverse);
  }

  void _onScroll(int index) {
    _controller?.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
    );
    setState(() => _pageIndex = index);
    _scale();
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Widget _buildCoinWidget(int index, double factor) {
    final filter = _getPayFilter(index);
    final boxSize = 70 + (factor * 30);
    final coinSize = 35 + (factor * 15);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        SlideTransition(
          position: _boxAnim,
          child: Image.asset(
            'assets/paycoins/ic_pay_coins_box.png',
            color: filter,
            width: boxSize,
            height: boxSize,
            colorBlendMode: BlendMode.srcATop,
          ),
        ),
        SlideTransition(
          position: _coinSlideAnim,
          child: FadeTransition(
            opacity: _coinFadeAnim,
            child: Image.asset(
              height: coinSize,
              width: coinSize,
              color: filter,
              colorBlendMode: BlendMode.srcATop,
              index == 0
                  ? 'assets/paycoins/ic_coins_one.png'
                  : 'assets/paycoins/ic_coins_two.png',
            ),
          ),
        ),
      ],
    );
  }

  Widget _build22() {
    final index = _pageIndex;
    final canPay = _canPay(index);
    final payImg = _getPayImage(index, canPay);
    return GestureDetector(
      onTap: canPay ? _onPayCoin : null,
      onVerticalDragStart: canPay
          ? (e) {
              _isHorizontal = false;
              _onDragDown(e);
            }
          : null,
      onVerticalDragUpdate: canPay ? _onDragUpdate : null,
      onVerticalDragEnd: canPay ? _onDragEnd : null,
      onVerticalDragCancel: canPay ? _onDragEnd : null,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale22Controller,
        child: SlideTransition(
          position: _slide22Anim,
          child: SizedBox(
            width: 110,
            height: 155,
            child: Image.asset(payImg, width: 110, height: 155),
          ),
        ),
      ),
    );
  }

  /// 余额等大数字格式化为 万 / 亿，避免显示过长（如 123456789.0）。
  String _fmtNum(num n) {
    final d = n.toDouble();
    if (d >= 100000000) return '${(d / 100000000).toStringAsFixed(1)}亿';
    if (d >= 10000) return '${(d / 10000).toStringAsFixed(1)}万';
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toStringAsFixed(1);
  }

  String get _balanceText {
    final coins = _coins;
    final parts = <String>[];
    if (coins != null) {
      parts.add('硬币余额：${_fmtNum(coins)}');
    }
    if (widget.hasCoin) {
      parts.add('已投1枚硬币');
    }
    return parts.join('，');
  }

  Widget _buildBody() {
    // Checkbox 等 Material 控件需要 Material 祖先；本页是透明路由，
    // 顶层没有 Material，用透明 Material 包裹即可（不改变背景样式）。
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        key: _key,
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 毛玻璃 + 半透明背景：模糊背后视频内容（点击吸收，阻止误触下层页面）
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
              ),
            ),
          ),
          // 返回按钮：与搜索页 / 视频页同款的毛玻璃圆钮
          // （避开系统状态栏，与非全屏播放页返回按钮位置保持一致）
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: MorphIconButton(
              icon: Icons.arrow_back,
              tooltip: AppLocalizations.of(context).commonBackTooltip,
              onTap: () => Navigator.of(context).pop(),
              frosted: true,
            ),
          ),
          // 枪娘投 2 枚时的闪电特效
          if (_hasCopyright)
            Offstage(
              offstage: _thunderIndex == -1 || _thunderIndex == 3,
              child: Image.asset(_thunderImages[_thunderIndex.clamp(0, 2)]),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              // 鼠标滚轮切换 1 枚 / 2 枚（2233 马里奥 ↔ 枪娘）
              onPointerSignal: (event) {
                if (event is! PointerScrollEvent) return;
                if (event.scrollDelta.dy > 0) {
                  if (_pageIndex < 1) _onScroll(1);
                } else if (event.scrollDelta.dy < 0) {
                  if (_pageIndex > 0) _onScroll(0);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasCopyright)
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: SizedBox(
                            height: 100,
                            child: PageView(
                              controller: _controller,
                              onPageChanged: (index) {
                                _scale();
                                setState(() => _pageIndex = index);
                              },
                              children: List.generate(
                                2,
                                (index) => ListenableBuilder(
                                  listenable: _controller!,
                                  builder: (context, child) {
                                    double factor = index == 0 ? 1 : 0;
                                    if (_controller!
                                        .position
                                        .hasContentDimensions) {
                                      factor =
                                          1 -
                                          (_controller!.page! - index).abs();
                                    }
                                    if (_pageIndex != index && _isPaying) {
                                      return const SizedBox.shrink();
                                    }
                                    return _buildCoinWidget(index, factor);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _isPaying
                              ? const SizedBox.shrink()
                              : GestureDetector(
                                  onTap: _pageIndex == 0
                                      ? null
                                      : () => _onScroll(0),
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Image.asset(
                                      width: 16,
                                      height: 28,
                                      _pageIndex == 0
                                          ? 'assets/paycoins/ic_left_disable.png'
                                          : 'assets/paycoins/ic_left.png',
                                    ),
                                  ),
                                ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _isPaying
                              ? const SizedBox.shrink()
                              : GestureDetector(
                                  onTap: _pageIndex == 1
                                      ? null
                                      : () => _onScroll(1),
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Image.asset(
                                      width: 16,
                                      height: 28,
                                      _pageIndex == 1
                                          ? 'assets/paycoins/ic_right_disable.png'
                                          : 'assets/paycoins/ic_right.png',
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    )
                  else
                    Center(
                      child: SizedBox(
                        height: 100,
                        child: _buildCoinWidget(0, 1),
                      ),
                    ),
                  const SizedBox(height: 25),
                  if (_hasCopyright)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (e) {
                        _isHorizontal = true;
                        _onDragDown(e);
                      },
                      onHorizontalDragUpdate: _onDragUpdate,
                      onHorizontalDragEnd: _onDragEnd,
                      onHorizontalDragCancel: _onDragEnd,
                      child: Center(child: _build22()),
                    )
                  else
                    Center(child: _build22()),
                  if (_coins != null || widget.hasCoin) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(
                          _balanceText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => _coinWithLike = !_coinWithLike),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            // 使用原生 Checkbox，避免图标自绘在透明页上渲染异常
                            Checkbox(
                              value: _coinWithLike,
                              onChanged: (v) =>
                                  setState(() => _coinWithLike = v ?? false),
                              activeColor: Colors.white,
                              checkColor: Colors.black,
                              side: const BorderSide(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const Text(
                              ' 同时点赞',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: Image.asset(
                              'assets/paycoins/ic_panel_close.png',
                              width: 30,
                              height: 30,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 50 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isHorizontal = true;
  DragStartDetails? _downPos;

  void _onDragDown(DragStartDetails detail) => _downPos = detail;

  void _onDragEnd([_]) => _downPos = null;

  void _onDragUpdate(DragUpdateDetails e) {
    if (_downPos == null) {
      return;
    }
    final offset = _isHorizontal
        ? (e.localPosition.dx - _downPos!.localPosition.dx).abs()
        : (e.localPosition.dy - _downPos!.localPosition.dy).abs();
    if (offset < 20) {
      return;
    }
    _downPos = null;
    if (_isHorizontal) {
      if (e.delta.dx > 0) {
        if (_pageIndex == 1) {
          _onScroll(0);
        }
      } else {
        if (_pageIndex == 0) {
          _onScroll(1);
        }
      }
    } else {
      if (e.delta.dy < 0) {
        _onPayCoin();
      }
    }
  }

  void _onPayCoin() {
    if (_isPaying) return;
    setState(() => _isPaying = true);
    _slide22Controller.forward().whenComplete(() {
      _slide22Controller.reverse().whenComplete(() {
        if (_pageIndex == 1) {
          setState(() => _thunderIndex += 1);
          _timer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
            final index = _thunderIndex;
            if (index == _thunderImages.length) {
              _cancelTimer();
            } else {
              setState(() => _thunderIndex = index + 1);
            }
          });
        }
        _boxAnimController.forward().whenComplete(_boxAnimController.reverse);
        _coinController.forward().whenComplete(() {
          Navigator.of(context).pop();
          widget.onPayCoin(_pageIndex + 1, _coinWithLike);
        });
      });
    });
  }
}
