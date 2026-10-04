# tool/patch_home_search_bar.py
#
# 一次性补丁：竖屏主页顶栏加 PiliPlus 式大搜索栏（头像在左 + 搜索框 + 分区入口），
# 顶栏总高度随竖屏变化，内容留白/刷新指示器偏移同步。
# 用法：python tool/patch_home_search_bar.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET = "lib/screens/bilibili_recommend_page.dart"

OPEN_OLD = """      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kTabBarHeight,
          child: Row(
            children: [
              if (!widget.embeddedInShell) ...["""

OPEN_NEW = """      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 竖屏：PiliPlus 式大搜索栏（头像在左 + 搜索框 + 分区入口） ──
            if (isPortrait) _buildHomeSearchRow(l10n),
            SizedBox(
              height: kTabBarHeight,
              child: Row(
                children: [
                  if (!widget.embeddedInShell && !isPortrait) ...["""

TAIL_OLD = """              if (isPortrait) ...[
                // 底栏搜索开启时不再显示（底栏孤儿位/附加 destination 替代）
                if (!bottomSearchVisible)
                  _RoundIconButton(
                    icon: Icons.search,
                    tooltip: l10n.drawerBilibiliSearch,
                    onTap: _openSearchPage,
                  ),
                const SizedBox(width: 4),
                // 分区入口（独立页面，与直播分类页同款；不再占 tab 位，
                // 因此没有选中高亮态，图标样式固定）。
                Tooltip(
                  message: '分区',
                  child: IconButton(
                    icon: const Icon(Icons.grid_view_outlined, size: 22),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BilibiliRegionCategoriesPage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }"""

TAIL_NEW = """                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 竖屏主页大搜索栏：头像（左）+ 搜索框 + 分区入口，行为对齐搜索页顶栏
  /// （整条可点，点进搜索页并自动聚焦）。
  Widget _buildHomeSearchRow(AppLocalizations l10n) {
    return SizedBox(
      height: kHomeSearchBarHeight,
      child: Row(
        children: [
          const SizedBox(width: 12),
          _SideBarEntry(onTap: _openSideMenu),
          const SizedBox(width: 10),
          Expanded(
            child: _HomeSearchBar(
              hint: l10n.searchBiliHint,
              onTap: _openSearchPage,
            ),
          ),
          const SizedBox(width: 4),
          // 分区入口（独立页面，与直播分类页同款）
          Tooltip(
            message: l10n.homeRegionCategories,
            child: IconButton(
              icon: const Icon(Icons.grid_view_outlined, size: 22),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BilibiliRegionCategoriesPage(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }"""

# bottomSearchVisible 变量在大搜索栏方案下不再需要
VAR_OLD = """    // 底栏搜索开启时（竖屏独立页）：顶栏搜索按钮隐藏，由底栏孤儿位替代
    final bottomSearchVisible = isPortrait &&
        context.watch<SettingsService>().bottomBarSearch;
"""
VAR_NEW = ""

# 顶栏高度常量 + 计算属性
CONST_OLD = "  static const double kTabBarHeight = 56.0;"
CONST_NEW = """  static const double kTabBarHeight = 56.0;

  /// 竖屏主页大搜索栏高度（PiliPlus 式：头像在左 + 搜索框 + 分区）。
  static const double kHomeSearchBarHeight = 52.0;"""

HEIGHT_USES = [
    (
        "                        headerInset: kTabBarHeight,",
        "                        headerInset: _topBarHeight,",
    ),
    (
        "      displacement: kTabBarHeight +\n          10 -\n          40.0 +\n          context.watch<SettingsService>().refreshDisplacement,",
        "      displacement: _topBarHeight +\n          10 -\n          40.0 +\n          context.watch<SettingsService>().refreshDisplacement,",
    ),
    (
        "        displacement: kTabBarHeight +\n            10 -\n            40.0 +\n            context.watch<SettingsService>().refreshDisplacement,",
        "        displacement: _topBarHeight +\n            10 -\n            40.0 +\n            context.watch<SettingsService>().refreshDisplacement,",
    ),
    (
        "              SliverToBoxAdapter(child: SizedBox(height: kTabBarHeight)),",
        "              SliverToBoxAdapter(child: SizedBox(height: _topBarHeight)),",
    ),
    (
        "          SliverToBoxAdapter(child: SizedBox(height: kTabBarHeight)),",
        "          SliverToBoxAdapter(child: SizedBox(height: _topBarHeight)),",
    ),
]

HELPER_ANCHOR = "  /// 搜索页同款 oval tab：椭圆点击区 + 文字 + 动画下划线指示器。"
HELPER_NEW = """  /// 竖屏是否显示大搜索栏（独立页 + 竖屏）。
  bool get _showHomeSearchBar =>
      !widget.embeddedInShell &&
      MediaQuery.orientationOf(context) == Orientation.portrait;

  /// 悬浮顶栏总高度（竖屏含大搜索栏，内容留白与刷新指示器偏移都用它）。
  double get _topBarHeight =>
      kTabBarHeight + (_showHomeSearchBar ? kHomeSearchBarHeight : 0);

  /// 搜索页同款 oval tab：椭圆点击区 + 文字 + 动画下划线指示器。"""

WIDGET_ANCHOR = "class _SideBarEntry extends StatelessWidget {"
WIDGET_NEW = """/// 主页大搜索栏（PiliPlus 式圆角搜索框：整条可点，点进搜索页）。
class _HomeSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback onTap;

  const _HomeSearchBar({required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 38,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideBarEntry extends StatelessWidget {"""

REPLACEMENTS = [
    (OPEN_OLD, OPEN_NEW),
    (TAIL_OLD, TAIL_NEW),
    (VAR_OLD, VAR_NEW),
    (CONST_OLD, CONST_NEW),
    *HEIGHT_USES,
    (HELPER_ANCHOR, HELPER_NEW),
    (WIDGET_ANCHOR, WIDGET_NEW),
]


def main():
    full = os.path.join(ROOT, TARGET)
    with io.open(full, "r", encoding="utf-8") as f:
        text = f.read()
    missing = []
    for old, new in REPLACEMENTS:
        if old not in text:
            missing.append(old.strip().splitlines()[0][:80])
            continue
        text = text.replace(old, new, 1)
    with io.open(full, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    if missing:
        print("MISS %s:" % TARGET)
        for m in missing:
            print("   - %s" % m)
        return 1
    print("ok   %s" % TARGET)
    return 0


if __name__ == "__main__":
    sys.exit(main())
