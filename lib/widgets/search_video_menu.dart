// lib/widgets/search_video_menu.dart
//
// 搜索视频卡片长按 / 右键菜单（毛玻璃浮层，风格同评论菜单）：
//   - 复制 BV 号
//   - 复制 AV 号（BV → AV 转换）
//   - 收藏到本地收藏夹 / 取消收藏
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bv_av.dart';
import 'package:naviflash/services/bilibili_title_cache.dart';
import 'package:naviflash/services/bilibili_favorite_service.dart';
import 'package:naviflash/services/favorites_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/fav_folder_picker.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/liquid_dom_menu.dart';
import 'package:naviflash/widgets/liquid_glass.dart';
import 'package:naviflash/widgets/glass_menu_style.dart';

/// 弹出视频卡片右键菜单（鼠标右键，毛玻璃浮层，以光标为起点）。
/// [showOriginal] / [onToggleOriginal]：标题已翻译时，「查看原文」原地
/// 切换卡片标题为原文（可再切回译文），不再弹窗。
void showVideoContextMenu(
  BuildContext context, {
  required String bvid,
  String title = '',
  String cover = '',
  String author = '',
  Offset? globalPosition,
  bool showOriginal = false,
  ValueChanged<bool>? onToggleOriginal,
}) {
  final bv = bvid.trim();
  if (bv.isEmpty) return;
  final colorScheme = Theme.of(context).colorScheme;
  final screenSize = MediaQuery.of(context).size;
  const menuWidth = 220.0;
  VoidCallback? dismiss;
  final items = _buildVideoMenuItems(
    context,
    bvid: bv,
    title: title,
    cover: cover,
    author: author,
    closeMenu: () => dismiss?.call(),
    showOriginal: showOriginal,
    onToggleOriginal: onToggleOriginal,
  );
  // 每项 ~44px + 分隔线 + 容器内边距
  final menuHeight = items.length * 44.0 + (items.length - 1) * 1.0 + 12.0;
  showLiquidDomMenu(
    context,
    globalPosition:
        globalPosition ?? Offset(screenSize.width / 2, screenSize.height / 2),
    menuWidth: menuWidth,
    menuHeight: menuHeight,
    builder: (menuContext, close) {
      dismiss = close;
      return _buildLiquidVideoMenuContent(
        menuContext,
        colorScheme: colorScheme,
        items: items,
      );
    },
  );
}

/// 弹出视频卡片底部操作菜单（移动端长按使用）。
/// [showOriginal] / [onToggleOriginal]：标题已翻译时，「查看原文」原地
/// 切换卡片标题为原文（可再切回译文），不再弹窗。
Future<void> showVideoBottomSheet(
  BuildContext context, {
  required String bvid,
  String title = '',
  String cover = '',
  String author = '',
  bool showOriginal = false,
  ValueChanged<bool>? onToggleOriginal,
}) async {
  final bv = bvid.trim();
  if (bv.isEmpty) return Future.value();
  final items = _buildVideoMenuItems(
    context,
    bvid: bv,
    title: title,
    cover: cover,
    author: author,
    closeMenu: () => Navigator.of(context).pop(),
    showOriginal: showOriginal,
    onToggleOriginal: onToggleOriginal,
  );
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
//  允许撑满可用高度，内部用 maxHeight 约束 + 滚动，
      //    避免封面预览 + 菜单项过高时被截断（少一截）并触发溢出警告。
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: GlassMenuSurface(
          radius: 24.0,
          blur: 12.0,
          // 列表页背景平坦，纯折射玻璃没有细节可展示；加轻微着色+高光
          // 让玻璃在暗色/平坦背景上也有通透雾面质感（图片查看器等
          // 直接盖在图片上的菜单保持纯玻璃不变）。
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
                        color: cs.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // 封面预览（带 Hero：与视频卡片缩略图 / 视频页封面同名 tag）
                  if (cover.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Hero(
                          tag: 'bili_video_$bv',
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  cover,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade800,
                                    child: const Center(
                                      child: Icon(
                                        Icons.movie_outlined,
                                        color: Colors.white24,
                                      ),
                                    ),
                                  ),
                                ),
                                // 底部渐变 + 标题 / 作者
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      28,
                                      12,
                                      10,
                                    ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
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
                                        if (author.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            author,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
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
                          ),
                        ),
                      ),
                    ),
                  for (final item in items)
                    // Material + InkWell 提供按压涟漪
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: item.onTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                item.text,
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

/// 视频卡片的菜单项（右键浮层与底部菜单共用）。
List<_MenuData> _buildVideoMenuItems(
  BuildContext context, {
  required String bvid,
  required String title,
  required String cover,
  required String author,
  required VoidCallback closeMenu,
  bool showOriginal = false,
  ValueChanged<bool>? onToggleOriginal,
}) {
  final bv = bvid.trim();
  final aid = BvAv.decode(bv);
  final favorites = context.read<FavoritesService>();
  final isFav = favorites.isFavorite(bv);
  return [
    _MenuData(
      icon: Icons.play_circle_outline,
      text: '应用内播放',
      onTap: () {
        closeMenu();
        openBilibiliVideo(
          context,
          bvid: bv,
          initialTitle: title,
          initialCover: cover,
        );
      },
    ),
    _MenuData(
      icon: Icons.copy_all_outlined,
      text: '复制BV号',
      onTap: () {
        closeMenu();
        _copy(context, bv);
      },
    ),
    if (aid != null)
      _MenuData(
        icon: Icons.tag_outlined,
        text: '复制AV号',
        onTap: () {
          closeMenu();
          _copy(context, 'av$aid');
        },
      ),
    _MenuData(
      icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      text: isFav ? '取消收藏' : '收藏到本地',
      onTap: () async {
        closeMenu();
        final added = await favorites.toggle(
          bvid: bv,
          aid: aid ?? 0,
          title: title,
          cover: cover,
          author: author,
        );
        if (!context.mounted) return;
        showAppToast(context, added ? '已收藏到本地收藏夹' : '已取消收藏');
      },
    ),
    // 加入 B 站在线收藏夹（需登录，始终携带 Cookie）
    if (aid != null && BilibiliFavoriteService.isLoggedIn)
      _MenuData(
        icon: Icons.bookmark_add_outlined,
        text: '加入B站收藏夹',
        onTap: () {
          closeMenu();
          showFavFolderPicker(context, aid: aid, title: title);
        },
      ),
//  查看未翻译的原文标题（仅当标题已被 AI 翻译时显示）
    //   调用方传入的 [title] 为 B 站原始标题（item.title），
    //   卡片显示用 BilibiliTitleCache.displayTitle（翻译后）。
    //   点击「查看原文」直接原地替换卡片标题为原文（不弹窗），
    //   再点「查看译文」切回译文。
    if (BilibiliTitleCache.displayTitle(bv, title) != title &&
        title.isNotEmpty)
      _MenuData(
        icon: Icons.translate_outlined,
        text: showOriginal ? '查看译文' : '查看原文',
        onTap: () {
          closeMenu();
          onToggleOriginal?.call(!showOriginal);
        },
      ),
  ];
}

void _copy(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  showAppToast(context, '已复制 $text');
}

class _MenuData {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _MenuData({
    required this.icon,
    required this.text,
    required this.onTap,
  });
}

Widget _buildLiquidVideoMenuContent(
  BuildContext context, {
  required ColorScheme colorScheme,
  required List<_MenuData> items,
}) {
  return GlassMenu(
    colorScheme: colorScheme,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    children: [
      for (final item in items)
        GlassMenuRow(
          colorScheme: colorScheme,
          icon: item.icon,
          label: item.text,
          onTap: item.onTap,
        ),
    ],
  );
}


/// 下拉菜单动作项（毛玻璃样式）。
class GlassMenuAction {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  /// 尾部控件（用于显示勾选 / 选中状态 / 子菜单箭头等）。
  /// 为 null 时占用 [trailingPlaceholder] 的固定宽度空白，保持文字对齐。
  final Widget? trailing;

  /// 是否为危险操作（红色图标 + 红色文字，例如删除）。
  final bool isDestructive;

  /// 是否可用。禁用项不响应点击，文字 / 图标半透明。
  final bool isEnabled;

  const GlassMenuAction({
    required this.icon,
    required this.text,
    required this.onTap,
    this.trailing,
    this.isDestructive = false,
    this.isEnabled = true,
  });
}

/// 通用毛玻璃下拉菜单（OverlayEntry，与视频卡片右键菜单同款样式：
/// BackdropFilter 模糊 + 圆角 + 阴影）。以 [globalPosition] 为锚点，
/// 自动避让屏幕边缘；内容超高时内部滚动。
///
/// 菜单使用 [showLiquidDomMenu] 弹出，因此自带 liquid-dom 风格的弹簧
/// 位移 + 缩放 + 模糊液态玻璃动画。
void showGlassDropdownMenu(
  BuildContext context, {
  required List<GlassMenuAction> actions,
  required Offset globalPosition,
  double menuWidth = 220,
  double menuRadius = 18.0,

  /// 触发按钮尺寸，非空时启用「角对齐」定位（菜单角对齐按钮角）。
  /// 详见 [showLiquidDomMenu] 的 [originSize] 参数。
  Size? originSize,

  /// 内容超高时是否允许内部滚动（长列表菜单，如换源列表 20+ 项）。
  /// 开启后 [showLiquidDomMenu] 会把菜单高度 clamp 到屏幕安全高度内，
  /// 超出部分滚动查看。
  bool scrollable = false,

  /// 菜单打开动画开始时回调。
  VoidCallback? onOpened,

  /// 菜单打开动画结束并稳定后回调。
  VoidCallback? onOpenedComplete,

  /// 菜单关闭动画开始时回调。
  VoidCallback? onCloseStarted,

  /// 菜单关闭并从 Overlay 移除后回调。
  VoidCallback? onClosed,
}) {
  if (actions.isEmpty) return;
  final colorScheme = Theme.of(context).colorScheme;
  final menuHeight = actions.length * 44.0 + (actions.length - 1) * 1.0 + 12.0;
  VoidCallback? dismiss;
  showLiquidDomMenu(
    context,
    globalPosition: globalPosition,
    menuWidth: menuWidth,
    menuHeight: menuHeight,
    menuRadius: menuRadius,
    originSize: originSize,
    onOpened: onOpened,
    onOpenedComplete: onOpenedComplete,
    onCloseStarted: onCloseStarted,
    onClosed: onClosed,
    builder: (menuContext, close) {
      dismiss = close;
      final column = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.5,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            _GlassActionTile(
              action: actions[i],
              colorScheme: colorScheme,
              onTap: actions[i].isEnabled
                  ? () {
                      dismiss?.call();
                      actions[i].onTap();
                    }
                  : null,
            ),
          ],
        ],
      );
      return Material(
        color: Colors.transparent,
        child: Container(
          width: menuWidth,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: scrollable
              ? SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: column,
                )
              : column,
        ),
      );
    },
  );
}

/// [showGlassDropdownMenu] 内部使用的单行菜单项，支持 trailing、
/// isDestructive、isEnabled 三种扩展态，外观与原版一致。
class _GlassActionTile extends StatelessWidget {
  final GlassMenuAction action;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  const _GlassActionTile({
    required this.action,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassMenuRow(
      colorScheme: colorScheme,
      icon: action.icon,
      label: action.text,
      // 无 trailing 时用固定宽度占位，保持文字左对齐（与原版一致）。
      trailing: action.trailing ?? const SizedBox(width: 24),
      destructive: action.isDestructive,
      enabled: action.isEnabled,
      onTap: onTap,
    );
  }
}

/// 通用毛玻璃操作底部菜单（与视频卡片长按菜单 [showVideoBottomSheet]
/// 同款样式：毛玻璃 + 圆角 + 封面预览 + 菜单项，超高时内部滚动）。
///
/// [cover] 为可选封面图（非空时展示在顶部），[title] / [subtitle]
/// 叠加在封面上；[actions] 为菜单动作列表（见 [GlassMenuAction]）。
Future<void> showFrostedActionSheet(
  BuildContext context, {
  String? cover,
  String? title,
  String? subtitle,
  required List<GlassMenuAction> actions,
}) async {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final menuBg = isDark
      ? cs.surfaceContainerHigh.withValues(alpha: 0.8)
      : cs.surfaceContainerLow.withValues(alpha: 0.85);
  // 弹出层期间抑制下层页面 iOS 景深缩放（菜单/弹窗等非整页路由不缩放背景）
  PopupOverlayGuard.open();
  try {
    return await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
//  允许撑满可用高度，内部 maxHeight 约束 + 滚动，避免内容被截断
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: GlassMenuSurface(
          radius: 24.0,
          blur: 12.0,
          tintOpacity: 0.12,
          lightIntensity: 0.2,
          stretch: 0.3,
          legacyClipRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          legacyDecoration: BoxDecoration(
            color: menuBg,
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
                        color: cs.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // 封面预览（可选）
                  if (cover != null && cover.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                cover,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade800,
                                  child: const Center(
                                    child: Icon(
                                      Icons.movie_outlined,
                                      color: Colors.white24,
                                    ),
                                  ),
                                ),
                              ),
                              if (title != null && title.isNotEmpty)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      28,
                                      12,
                                      10,
                                    ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
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
                                        if (subtitle != null &&
                                            subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
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
                        ),
                      ),
                    ),
                  // 菜单项
                  for (final action in actions)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          action.onTap();
                        },
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
