# 一次性脚本：把「声明处初始化」的 late AnimationController 改成
# 声明 + initState 显式创建（消除 dispose 期间首次创建 → 查失效祖先的崩溃）。
import io

FIXES = {
    'lib/screens/bilibili_video_page.dart': [
        (
            '  late final AnimationController _memberPanelCtrl = AnimationController(\n'
            '    vsync: this,\n'
            '    duration: const Duration(milliseconds: 280),\n'
            '  );',
            '  late final AnimationController _memberPanelCtrl;',
        ),
        (
            '  late final AnimationController _moreMenuCtrl = AnimationController(\n'
            '    vsync: this,\n'
            '    duration: const Duration(milliseconds: 260),\n'
            '  );',
            '  late final AnimationController _moreMenuCtrl;',
        ),
        (
            '  late final AnimationController _moreNavCtrl = AnimationController(\n'
            '    vsync: this,\n'
            '    duration: const Duration(milliseconds: 260),\n'
            '  );',
            '  late final AnimationController _moreNavCtrl;',
        ),
        (
            '  void initState() {\n'
            '    super.initState();\n'
            '    // 预测式返回（Android 14+）：lite 面板 / 更多面板展开时接管返回手势',
            '  void initState() {\n'
            '    super.initState();\n'
            '    // 三个面板控制器都显式创建：写成带初始化式的惰性 late 字段时，页面若\n'
            '    // 从没用到它（面板没弹出过），dispose 里的首次访问会落在 unmount 期间\n'
            '    // → vsync 查 TickerMode 祖先 → 「deactivated widget ancestor」异常。\n'
            '    _memberPanelCtrl = AnimationController(\n'
            '      vsync: this,\n'
            '      duration: const Duration(milliseconds: 280),\n'
            '    );\n'
            '    _moreMenuCtrl = AnimationController(\n'
            '      vsync: this,\n'
            '      duration: const Duration(milliseconds: 260),\n'
            '    );\n'
            '    _moreNavCtrl = AnimationController(\n'
            '      vsync: this,\n'
            '      duration: const Duration(milliseconds: 260),\n'
            '    );\n'
            '    // 预测式返回（Android 14+）：lite 面板 / 更多面板展开时接管返回手势',
        ),
    ],
    'lib/widgets/back_top_fab.dart': [
        (
            '  /// 火箭飞行动画：0~0.5 升空飞出，0.5~1 从底部落回。\n'
            '  late final AnimationController _flight = AnimationController(vsync: this);',
            '  /// 火箭飞行动画：0~0.5 升空飞出，0.5~1 从底部落回。\n'
            '  ///\n'
            '  /// ⚠️ 在 initState 里创建：写成带初始化式的惰性 late 字段时，页面若从没\n'
            '  /// 触发过起飞，dispose 里的首次访问会落在 unmount 期间 → vsync 查已失效\n'
            '  /// 的 TickerMode 祖先而抛异常。\n'
            '  late final AnimationController _flight;',
        ),
        (
            '  /// 火箭起飞：箭头向上飞出再从底部落回，总时长与回顶滚动同步。',
            '  @override\n'
            '  void initState() {\n'
            '    super.initState();\n'
            '    _flight = AnimationController(vsync: this);\n'
            '  }\n'
            '\n'
            '  /// 火箭起飞：箭头向上飞出再从底部落回，总时长与回顶滚动同步。',
        ),
    ],
    'lib/widgets/collapsible_side_bar.dart': [
        (
            '  late final AnimationController _indicatorController = AnimationController(\n'
            '    duration: kThemeAnimationDuration,\n'
            '    vsync: this,\n'
            '    value: widget.isSelected ? 1.0 : 0.0,\n'
            '  );',
            '  /// ⚠️ 在 initState 里创建（惰性 late 字段会在 dispose 首访时去查已失效的\n'
            '  /// TickerMode 祖先）。\n'
            '  late final AnimationController _indicatorController;',
        ),
        (
            '  @override\n'
            '  void didUpdateWidget(_CollapsedNavItem oldWidget) {',
            '  @override\n'
            '  void initState() {\n'
            '    super.initState();\n'
            '    _indicatorController = AnimationController(\n'
            '      duration: kThemeAnimationDuration,\n'
            '      vsync: this,\n'
            '      value: widget.isSelected ? 1.0 : 0.0,\n'
            '    );\n'
            '  }\n'
            '\n'
            '  @override\n'
            '  void didUpdateWidget(_CollapsedNavItem oldWidget) {',
        ),
    ],
    'lib/widgets/liquid_glass.dart': [
        (
            '  late final AnimationController _spring = AnimationController(\n'
            '    vsync: this,\n'
            '    duration: const Duration(milliseconds: 600),\n'
            '  );',
            '  /// ⚠️ 在 initState 里创建（惰性 late 字段会在 dispose 首访时去查已失效的\n'
            '  /// TickerMode 祖先）。\n'
            '  late final AnimationController _spring;',
        ),
        (
            '  @override\n'
            '  void dispose() {\n'
            '    _spring.dispose();',
            '  @override\n'
            '  void initState() {\n'
            '    super.initState();\n'
            '    _spring = AnimationController(\n'
            '      vsync: this,\n'
            '      duration: const Duration(milliseconds: 600),\n'
            '    );\n'
            '  }\n'
            '\n'
            '  @override\n'
            '  void dispose() {\n'
            '    _spring.dispose();',
        ),
    ],
    'lib/widgets/long_press_image_preview.dart': [
        (
            '  late final AnimationController _controller = AnimationController(\n'
            '    vsync: this,\n'
            '    duration: widget.flightDuration,\n'
            '    reverseDuration: widget.dismissDuration,\n'
            '  );',
            '  /// ⚠️ 在 initState 里创建（惰性 late 字段会在 dispose 首访时去查已失效的\n'
            '  /// TickerMode 祖先）。\n'
            '  late final AnimationController _controller;',
        ),
        (
            '  void initState() {\n'
            '    super.initState();\n'
            '    // 下一帧再启动动画，确保首帧定位在缩略图位置',
            '  void initState() {\n'
            '    super.initState();\n'
            '    _controller = AnimationController(\n'
            '      vsync: this,\n'
            '      duration: widget.flightDuration,\n'
            '      reverseDuration: widget.dismissDuration,\n'
            '    );\n'
            '    // 下一帧再启动动画，确保首帧定位在缩略图位置',
        ),
    ],
}

for path, pairs in FIXES.items():
    with io.open(path, encoding='utf-8') as f:
        text = f.read()
    for old, new in pairs:
        assert text.count(old) == 1, (path, old[:50], text.count(old))
        text = text.replace(old, new)
    with io.open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    print('patched', path)
