// lib/widgets/cover_menu_sheet.dart
//
// 通用「大封面 + 玻璃菜单」底部弹层。
//
// 视觉与视频卡片长按菜单（search_video_menu.dart 的 showVideoBottomSheet）
// 完全一致：拖拽把手 → 16:9 大封面（Hero，与卡片封面同名 tag 时飞入）
// → 封面底部渐变 + 标题 / 副标题 → 玻璃菜单项列表。
//
// 抽出来的原因：视频菜单与「收藏 / 复制 AV 号 / 加入 B 站收藏夹」等
// 视频专属能力耦合，番剧 / 直播用不上；这里只保留壳子，菜单项由调用方
// 以 [GlassMenuAction] 传入（番剧：应用内播放 / 复制 SS 号 / 复制链接；
// 直播：浏览器打开 / 复制链接 / 复制房间号）。
import 'package:flutter/material.dart';

import 'ios_backdrop.dart';
import 'liquid_glass.dart';

/// 菜单项（图标 + 文案 + 点击）。
///
/// 刻意不复用 search_video_menu.dart 的 GlassMenuAction：那个文件耦合了
/// 视频专属能力（收藏 / 复制 AV 号 / 加入 B 站收藏夹），本弹层是通用壳子，
/// 反向依赖会形成循环 import。调用方用 record 字面量即可。
typedef CoverMenuAction = ({
  IconData icon,
  String text,
  VoidCallback onTap,
});

/// 大封面 + 玻璃菜单底部弹层。
///
/// [heroTag] 与列表页卡片封面上的 Hero tag 同名时，封面会从卡片飞入弹层；
/// 传空则不启用 Hero（仍显示大封面）。
Future<void> showCoverMenuBottomSheet(
  BuildContext context, {
  String cover = '',
  String title = '',
  String subtitle = '',
  String? heroTag,
  required List<CoverMenuAction> actions,
}) async {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final legacyBg = isDark
      ? cs.surfaceContainerHigh.withValues(alpha: 0.8)
      : cs.surfaceContainerLow.withValues(alpha: 0.85);
  // 弹出层期间抑制下层页面 iOS 景深缩放（菜单/弹窗等非整页路由不缩放背景）
  PopupOverlayGuard.open();
  try {
    return await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      // 允许撑满可用高度，内部用 maxHeight 约束 + 滚动，
      // 避免封面预览 + 菜单项过高时被截断（少一截）并触发溢出警告。
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: GlassMenuSurface(
          radius: 24.0,
          blur: 12.0,
          // 列表页背景平坦，纯折射玻璃没有细节可展示；加轻微着色 + 高光
          // 让玻璃在暗色 / 平坦背景上也有通透雾面质感
          tintOpacity: 0.12,
          lightIntensity: 0.2,
          stretch: 0.3,
          legacyClipRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          legacyDecoration: BoxDecoration(
            color: legacyBg,
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖拽把手
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // 封面预览（带 Hero：与卡片缩略图同名 tag 时飞入）
                  if (cover.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _CoverPreview(
                          url: cover,
                          heroTag: heroTag,
                          title: title,
                          subtitle: subtitle,
                        ),
                      ),
                    ),
                  for (final action in actions)
                    // Material + InkWell 提供按压涟漪
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: action.onTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                action.icon,
                                size: 20,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                action.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  } finally {
    PopupOverlayGuard.close();
  }
}

/// 菜单弹层里的大封面：16:9 + 底部渐变 + 标题 / 副标题。
class _CoverPreview extends StatelessWidget {
  final String url;
  final String? heroTag;
  final String title;
  final String subtitle;

  const _CoverPreview({
    required this.url,
    required this.title,
    required this.subtitle,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget img = AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade800,
              child: const Center(
                child: Icon(Icons.movie_outlined, color: Colors.white24),
              ),
            ),
          ),
          // 底部渐变 + 标题 / 副标题
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 28, 12, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
    final tag = heroTag;
    if (tag != null && tag.isNotEmpty) {
      img = Hero(tag: tag, child: img);
    }
    return img;
  }
}
