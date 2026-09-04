// lib/widgets/side_bar_shell.dart
//
// 宽屏 / 横屏主框架：左侧固定可折叠侧边栏 + 右侧内容区。
//   - 侧边栏菜单项切换内容区不推路由、无转场动画（与设置页左侧面板
//     切换右侧内容一致），已访问的区块用 IndexedStack 保活，状态不丢失
//   - 背景色统一（侧边栏与内容区同色），侧边栏与内容区之间不画分隔线，
//     留 12px 空距
//   - 竖屏 / 窄屏不使用本组件，仍走原来的抽屉 + 页面路由（AppDrawer）
//   - 鼠标悬停自动展开：收起态下鼠标在侧边栏上停留一小段时间，
//     以「浮层」形式覆盖展开（叠在内容区之上，非自适应推挤）；
//     鼠标移出侧边栏浮层自动收起。手动点击 menu 展开/收起照旧（自适应推挤）。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:naviflash/screens/bilibili_recommend_page.dart';
import 'package:naviflash/screens/bilibili_search_page.dart';
import 'package:naviflash/screens/bilibili_live_page.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'collapsible_side_bar.dart';

class SideBarShell extends StatefulWidget {
  const SideBarShell({super.key});

  @override
  State<SideBarShell> createState() => _SideBarShellState();
}

class _SideBarShellState extends State<SideBarShell> {
  /// 与 CollapsibleSideBar / AppDrawer 一致的页面 id。
  /// 主页（B站推荐流）/ 搜索 / 直播作为侧边栏常驻区块；
  /// 历史 / 缓存 / 设置 / 关于收进侧边栏底部 ⋮ 菜单，
  /// 点击全屏打开（推路由），不受侧边栏影响。
  static const List<String> _sectionIds = [
    'home',
    'search',
    'live',
  ];

  /// 悬停展开延迟（鼠标在侧边栏上停留多久后自动浮层展开）。
  static const Duration _hoverDelay = Duration(milliseconds: 800);

  String _currentPageId = 'home';

  /// 已访问过的区块（懒构建 + 保活：首次进入才 build，之后切换不销毁）。
  final Set<String> _visited = {'home'};

  /// 鼠标是否在侧边栏区域（悬停计时守卫）。
  bool _hoverArmed = false;

  /// 悬停浮层是否展开（仅收起态下由鼠标悬停驱动）。
  bool _hoverExpanded = false;
  Timer? _hoverTimer;

  @override
  void initState() {
    super.initState();
    // 手动展开时悬停浮层失去意义（已自适应展开）：监听全局状态，
    // 一旦手动展开立即关闭浮层并取消悬停计时
    CollapsibleSideBar.expanded.addListener(_onManualExpandedChanged);
  }

  @override
  void dispose() {
    CollapsibleSideBar.expanded.removeListener(_onManualExpandedChanged);
    _hoverTimer?.cancel();
    super.dispose();
  }

  void _onManualExpandedChanged() {
    // 手动展开/收起都会改变布局：收起悬停状态并重建（展开时隐藏浮层，
    // 收起时浮层恢复可悬停）
    _hoverTimer?.cancel();
    _hoverArmed = false;
    setState(() => _hoverExpanded = false);
  }

  void _onHoverEnter() {
    if (CollapsibleSideBar.expanded.value) return; // 手动展开时不启用悬停
    _hoverArmed = true;
    _hoverTimer?.cancel();
    _hoverTimer = Timer(_hoverDelay, () {
      if (!mounted || !_hoverArmed) return;
      if (CollapsibleSideBar.expanded.value) return;
      setState(() => _hoverExpanded = true);
    });
  }

  void _onHoverExit() {
    _hoverArmed = false;
    _hoverTimer?.cancel();
    if (_hoverExpanded) setState(() => _hoverExpanded = false);
  }

  /// 浮层顶部 menu 点击：转手动展开（自适应推挤）并关闭浮层。
  void _onOverlayMenuTap() {
    CollapsibleSideBar.toggle();
    if (_hoverExpanded) setState(() => _hoverExpanded = false);
  }

  void _onNavigate(String pageId) {
    if (pageId == _currentPageId || !_sectionIds.contains(pageId)) return;
    setState(() {
      _currentPageId = pageId;
      _visited.add(pageId);
    });
  }

  Widget _buildSection(String id) {
    return switch (id) {
      'search' => const BilibiliSearchPage(embeddedInShell: true),
      'live' => const BilibiliLivePage(embeddedInShell: true),
      // 主页 = B站推荐流
      _ => const BilibiliRecommendPage(embeddedInShell: true),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 整体背景缩放：压栈全屏路由（视频/番剧/设置等）时侧边栏与内容区
    // 一起向中心缩小（iOS 景深），避免只有内容区缩放、侧边栏不动的割裂感。
    // 卡死修复：给侧边栏与内容区各自套 RepaintBoundary，避免宽度动画每帧重绘全树
    // 外向圆角：内容区为圆角卡片（24px），侧边栏背景透出形成上下外向圆角（对齐参考图）
    return IosBackdropScale(
      child: ColoredBox(
        // 统一画布：侧边栏（透明）与内容区卡片区分
        color: cs.surfaceContainerLow,
        child: Stack(
          children: [
            // ── 底层：手动模式布局（自适应推挤） ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RepaintBoundary(
                  // 悬停浮层展开时底层 rail 藏掉：浮层是半透明毛玻璃，
                  // 底层图标透出来会形成重影；浮层 224 宽全覆盖 80 宽底层，
                  // 藏掉不影响布局与点击（点击本来就落在浮层上）。
                  child: Visibility(
                    visible: !_hoverExpanded,
                    maintainSize: true,
                    maintainState: true,
                    maintainAnimation: true,
                    child: CollapsibleSideBar(
                      currentPage: _currentPageId,
                      onNavigate: _onNavigate,
                    ),
                  ),
                ),
                // 内容区卡片：外向圆角 24，上下左右留 8-12 空隙露出侧边栏底色
                Expanded(
                  child: RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: ColoredBox(
                          color: cs.surface,
                          child: IndexedStack(
                            index: _sectionIds.indexOf(_currentPageId),
                            children: [
                              for (final id in _sectionIds)
                                _visited.contains(id)
                                    ? RepaintBoundary(
                                        // 非当前区块禁用 Hero：各区块靠 IndexedStack
                                        // 保活，切换后仍留在同一棵 widget 树里。
                                        // 搜索结果与推荐流可能包含同一视频，同名
                                        // Hero（bili_video_$bvid）同时存在会让点击
                                        // 抛「multiple heroes that share the same
                                        // tag within a subtree」（debug 下红屏）。
                                        child: HeroMode(
                                          enabled: id == _currentPageId,
                                          child: _buildSection(id),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ── 上层：悬停浮层（覆盖在内容区之上，不推挤内容区） ──
            // 手动展开（自适应推挤）时隐藏浮层，避免浮层收起态盖住
            // 底层已展开的侧边栏
            if (!CollapsibleSideBar.expanded.value)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: MouseRegion(
                  // 悬停探测区 = 浮层当前宽度（收起 80 / 展开 224）：
                  // 收起时恰好覆盖底层侧边栏（不挡内容区），
                  // 展开时覆盖内容区左侧（浮层本就要叠在上面）
                  onEnter: (_) => _onHoverEnter(),
                  onExit: (_) => _onHoverExit(),
                  child: AnimatedContainer(
                    duration: CollapsibleSideBar.animDuration,
                    curve: CollapsibleSideBar.animCurve,
                    width: _hoverExpanded
                        ? CollapsibleSideBar.expandedWidth
                        : CollapsibleSideBar.minWidth,
                    child: CollapsibleSideBar(
                      currentPage: _currentPageId,
                      onNavigate: _onNavigate,
                      expandedOverride: _hoverExpanded,
                      overlay: true,
                      onOverlayMenuTap: _onOverlayMenuTap,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}