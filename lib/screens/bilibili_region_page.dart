// lib/screens/bilibili_region_page.dart
//
// 分区页（推荐页第 4 个 tab「分区」的内容）：
//   - 顶部主分区横滑 chips（选中高亮，切换下方子分区网格）
//   - 下方子分区网格（图标 + 名称），点击进入该分区视频列表页
//   - 每个主分区首项「全部」直接进主分区视频列表页
// 分区表来自 BilibiliRegionService.regions（官方现行分区体系）。
import 'package:flutter/material.dart';
import 'package:naviflash/screens/bilibili_region_videos_page.dart';
import 'package:naviflash/services/bilibili_region_service.dart';

/// 分区页（嵌入推荐页 tab，无独立顶栏；滚动区由父级提供）。
class BilibiliRegionPage extends StatefulWidget {
  const BilibiliRegionPage({super.key});

  @override
  State<BilibiliRegionPage> createState() => BilibiliRegionPageState();
}

class BilibiliRegionPageState extends State<BilibiliRegionPage> {
  final ScrollController _scroll = ScrollController();

  /// 当前选中主分区（默认动画）。
  int _selected = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// 滚回顶部（父级点击当前 tab 时调用）。
  void scrollToTop() {
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _openRegion(BiliRegion region) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BilibiliRegionVideosPage(region: region),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final regions = BilibiliRegionService.regions;
    if (regions.isEmpty) {
      return const SizedBox.shrink();
    }
    final selected = regions[_selected];
    // 顶部「全部」入口 + 二级分区
    final children = <BiliRegion>[
      BiliRegion(tid: selected.tid, name: '全部', icon: selected.icon),
      ...selected.children,
    ];
    return CustomScrollView(
      controller: _scroll,
      physics: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // 主分区横滑 chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: regions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final region = regions[i];
                final selectedFlag = i == _selected;
                return ChoiceChip(
                  label: Text(region.name),
                  selected: selectedFlag,
                  onSelected: (_) => setState(() => _selected = i),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: selectedFlag ? cs.primary : cs.onSurfaceVariant,
                    fontWeight: selectedFlag ? FontWeight.w600 : null,
                  ),
                  showCheckmark: false,
                  selectedColor: cs.primaryContainer.withValues(alpha: 0.5),
                  backgroundColor: cs.surfaceBright,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                );
              },
            ),
          ),
        ),
        // 子分区网格
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _regionCell(cs, children[i]),
              childCount: children.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).padding.bottom + 72,
          ),
        ),
      ],
    );
  }

  /// 子分区格子：圆角卡片（图标 + 名称）。
  Widget _regionCell(ColorScheme cs, BiliRegion region) {
    return Material(
      color: cs.surfaceBright,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openRegion(region),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(region.icon, size: 24, color: cs.primary),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                region.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}