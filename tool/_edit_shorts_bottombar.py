# -*- coding: utf-8 -*-
"""短视频页加底部导航栏 + 底部元素整体上移（原子批量改）。"""
import io

P = 'lib/screens/bilibili_shorts_page.dart'
s = io.open(P, encoding='utf-8').read()
orig = s


def rep(old, new, count=1):
    global s
    assert s.count(old) >= 1, old[:80]
    s = s.replace(old, new, count)


# ── 1. import ──
rep(
    "import 'package:naviflash/widgets/fav_folder_picker.dart';\n",
    "import 'package:naviflash/widgets/fav_folder_picker.dart';\n"
    "import 'package:naviflash/widgets/glass_bottom_bar.dart';\n",
)

# ── 2. 构造参数 ──
rep(
    "class BilibiliShortsPage extends StatefulWidget {\n"
    "  const BilibiliShortsPage({super.key});\n",
    "class BilibiliShortsPage extends StatefulWidget {\n"
    "  const BilibiliShortsPage({super.key, this.onNavTabSelected});\n"
    "\n"
    "  /// 页面自带底栏的点击回调（参数 = 底栏项 id：home / dynamics / live /\n"
    "  /// shorts）。为空时点击除「短视频」外的项直接退出本页。\n"
    "  final void Function(String id)? onNavTabSelected;\n",
)

# ── 3. 常量 ──
rep(
    "  static const Map<String, String> _mediaHeaders = {",
    "  /// 页面自带底栏占掉的高度（玻璃胶囊 60 + 上下留白），页面内所有\n"
    "  /// 底部定位都要为它让位，否则底栏会压住发弹幕栏 / UP 信息 / 操作栏。\n"
    "  static const double _bottomBarReserve = 76.0;\n"
    "\n"
    "  static const Map<String, String> _mediaHeaders = {",
)

# ── 4. Scaffold 挂底栏 ──
rep(
    "      child: Scaffold(\n"
    "        backgroundColor: Colors.black,\n"
    "        body: Stack(\n",
    "      child: Scaffold(\n"
    "        backgroundColor: Colors.black,\n"
    "        // 画面延伸到系统导航条/底栏之后（底栏是悬浮胶囊，内容可透出）\n"
    "        extendBody: true,\n"
    "        bottomNavigationBar: _buildNavBar(),\n"
    "        body: Stack(\n",
)

# ── 5. 竖屏 item：底部元素让位 ──
rep(
    "    final actionBottom = commentsOpen\n"
    "        ? screenH * effectiveExtent + 12\n"
    "        : bottomInset + 132;",
    "    final actionBottom = commentsOpen\n"
    "        ? screenH * effectiveExtent + 12\n"
    "        : bottomInset + 132 + _bottomBarReserve;",
)
rep(
    "    const danmakuSafeBottom = 164.0;",
    "    final danmakuSafeBottom = 164.0 + _bottomBarReserve;",
)
rep(
    "            bottom: bottomInset + 60,\n"
    "            child: _buildMeta(item),",
    "            bottom: bottomInset + 60 + _bottomBarReserve,\n"
    "            child: _buildMeta(item),",
)
rep(
    "            bottom: bottomInset + 8,\n"
    "            child: _buildBottomBar(item),",
    "            bottom: bottomInset + 8 + _bottomBarReserve,\n"
    "            child: _buildBottomBar(item),",
)

# ── 6. 横屏 item：底部元素让位 ──
rep(
    "              Positioned(\n"
    "                right: 10,\n"
    "                bottom: 20,\n"
    "                child: _buildActionBar(item),\n"
    "              ),",
    "              Positioned(\n"
    "                right: 10,\n"
    "                bottom: 20 + _bottomBarReserve,\n"
    "                child: _buildActionBar(item),\n"
    "              ),",
)
rep(
    "                left: 56,\n"
    "                right: 12,\n"
    "                bottom: 20,\n"
    "                child: _buildMeta(item),",
    "                left: 56,\n"
    "                right: 12,\n"
    "                bottom: 20 + _bottomBarReserve,\n"
    "                child: _buildMeta(item),",
)

# ── 7. 评论抽屉：抬高到底栏之上 ──
rep(
    "    final height = (screenH * _commentsExtent).clamp(180.0, screenH);\n"
    "    return Positioned(\n"
    "      left: 0,\n"
    "      right: 0,\n"
    "      bottom: 0,\n"
    "      height: height,",
    "    final maxH = (screenH - _bottomBarReserve).clamp(180.0, screenH);\n"
    "    final height = (screenH * _commentsExtent).clamp(180.0, maxH);\n"
    "    return Positioned(\n"
    "      left: 0,\n"
    "      right: 0,\n"
    "      // 抬到底栏之上：否则抽屉底部（评论输入框那一带）会被底栏压住\n"
    "      bottom: _bottomBarReserve,\n"
    "      height: height,",
)

# ── 8. 发弹幕：输入框为底栏让位 ──
rep(
    "    final style = await showDanmakuSendSheet(context);",
    "    final style = await showDanmakuSendSheet(\n"
    "      context,\n"
    "      // 键盘弹起时系统已经把面板顶起来了（此时底栏被键盘盖住），\n"
    "      // 只在键盘收起时为底栏额外留白\n"
    "      bottomPadding: _bottomBarReserve,\n"
    "    );",
)

# ── 9. 新增 _buildNavBar ──
rep(
    "  /// 顶部：返回按钮 + 「N 人正在看」。\n",
    "  /// 底部导航栏（与主 Tab 同款：顺序 / 显隐来自设置）。\n"
    "  ///\n"
    "  /// 短视频页是 push 出来的全屏沉浸路由，会盖住主页面的底栏，\n"
    "  /// 所以这里自带一条，选中项是「短视频」。\n"
    "  Widget _buildNavBar() {\n"
    "    List<String> order;\n"
    "    try {\n"
    "      order = context.select<SettingsService, List<String>>(\n"
    "        (s) => s.bottomNavOrder,\n"
    "      );\n"
    "    } on ProviderNotFoundException {\n"
    "      order = const ['home', 'shorts', 'dynamics', 'live'];\n"
    "    }\n"
    "    if (order.isEmpty) order = const ['home', 'shorts', 'dynamics', 'live'];\n"
    "    final l10n = L10n.current;\n"
    "    return DecoratedBox(\n"
    "      // 短视频是纯黑沉浸页：垫一层半透明黑，保证底栏图标 / 文字可读\n"
    "      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35)),\n"
    "      child: SafeArea(\n"
    "        top: false,\n"
    "        child: Padding(\n"
    "          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),\n"
    "          child: AppBottomBar(\n"
    "            tabs: [for (final id in order) navItemTab(id, l10n)],\n"
    "            selectedIndex: order.indexOf('shorts'),\n"
    "            onTabSelected: (index) {\n"
    "              if (index < 0 || index >= order.length) return;\n"
    "              final id = order[index];\n"
    "              if (id == 'shorts') return; // 已经在短视频页\n"
    "              final cb = widget.onNavTabSelected;\n"
    "              if (cb != null) {\n"
    "                cb(id);\n"
    "                return;\n"
    "              }\n"
    "              Navigator.of(context).maybePop();\n"
    "            },\n"
    "          ),\n"
    "        ),\n"
    "      ),\n"
    "    );\n"
    "  }\n"
    "\n"
    "  /// 顶部：返回按钮 + 「N 人正在看」。\n",
)

io.open(P, 'w', encoding='utf-8', newline='').write(s)
print('ok, changed:', s != orig)
