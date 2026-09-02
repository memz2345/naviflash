// lib/screens/settings_search_page.dart
//
// 设置搜索页：实时搜索全部设置项，点击结果跳转到对应设置页
// 并滚动定位到该项闪烁数下（由 MorphItem.flashKey 消费高亮）。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/widgets.dart';
import '../l10n/app_localizations.dart';

/// 可搜索的设置项。
class SettingsSearchEntry {
  final String pageRoute;
  final String pageTitle;
  final String? optionKey;
  final String name;
  final String keywords;
  final IconData icon;

  const SettingsSearchEntry({
    required this.pageRoute,
    required this.pageTitle,
    this.optionKey,
    required this.name,
    required this.keywords,
    required this.icon,
  });
}

/// 全量搜索目录。
List<SettingsSearchEntry> buildSearchCatalog(AppLocalizations l10n) => [
  // ── 显示 ──
  SettingsSearchEntry(
    pageRoute: '/display',
    pageTitle: l10n.settingsDisplay,
    optionKey: 'theme_mode',
    name: l10n.searchThemeMode,
    keywords: '主题 外观 模式 浅色 深色 跟随系统',
    icon: Icons.brightness_6_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/display',
    pageTitle: l10n.settingsDisplay,
    optionKey: 'pure_black',
    name: l10n.searchPureBlack,
    keywords: '深色 黑色 外观 AMOLED',
    icon: Icons.brightness_2_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/display',
    pageTitle: l10n.settingsDisplay,
    optionKey: 'theme_color',
    name: l10n.searchThemeColor,
    keywords: '颜色 配色 主题色 个性化 调色板',
    icon: Icons.palette_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/display',
    pageTitle: l10n.settingsDisplay,
    optionKey: 'font_weight',
    name: l10n.searchFontWeight,
    keywords: '字体 粗细 个性化 字重',
    icon: Icons.format_bold_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/display',
    pageTitle: l10n.settingsDisplay,
    optionKey: 'display_scale',
    name: l10n.searchDisplayScale,
    keywords: '缩放 比例 界面大小 个性化',
    icon: Icons.zoom_in_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/display',
    pageTitle: l10n.settingsDisplay,
    optionKey: 'display_mode',
    name: l10n.searchDisplayMode,
    keywords: '刷新率 帧率 屏幕 Hz 高刷',
    icon: Icons.speed_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/display',
    pageTitle: l10n.settingsDisplay,
    optionKey: 'liquid_glass_tuner',
    name: l10n.displayLiquidGlassTuner,
    keywords: '玻璃 毛玻璃 液态玻璃 调校 折射 模糊 厚度 高光',
    icon: Icons.bubble_chart_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/display',
    pageTitle: l10n.settingsDisplay,
    optionKey: 'page_background',
    name: l10n.pageBgTitle,
    keywords: '背景图 壁纸 页面 背景 裁剪 图片',
    icon: Icons.wallpaper_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/display',
    pageTitle: l10n.settingsDisplay,
    optionKey: 'ios_push_transition',
    name: l10n.searchIosPushTransition,
    keywords: '页面 切换 转场 动画 push ios 圆角 滑动 模糊',
    icon: Icons.animation,
  ),

  // ── 播放器 ──
  SettingsSearchEntry(
    pageRoute: '/player',
    pageTitle: l10n.settingsPlayer,
    optionKey: 'status_bar',
    name: l10n.searchStatusBar,
    keywords: '播放器 电量 时间 网络 顶部',
    icon: Icons.phone_android,
  ),
  SettingsSearchEntry(
    pageRoute: '/player',
    pageTitle: l10n.settingsPlayer,
    optionKey: 'keep_window_ratio',
    name: l10n.searchKeepWindowRatio,
    keywords: '窗口 比例 拉伸 桌面',
    icon: Icons.aspect_ratio,
  ),
  SettingsSearchEntry(
    pageRoute: '/player',
    pageTitle: l10n.settingsPlayer,
    optionKey: 'long_press_speed',
    name: l10n.searchLongPressSpeed,
    keywords: '倍速 快进 长按 加速 交互',
    icon: Icons.touch_app,
  ),
  SettingsSearchEntry(
    pageRoute: '/player',
    pageTitle: l10n.settingsPlayer,
    optionKey: 'screenshot',
    name: l10n.searchScreenshot,
    keywords: '截图 相册 保存 画面',
    icon: Icons.camera_alt,
  ),
  SettingsSearchEntry(
    pageRoute: '/player',
    pageTitle: l10n.settingsPlayer,
    optionKey: 'screenshot_danmaku',
    name: l10n.searchScreenshotDanmaku,
    keywords: '截图 弹幕 字幕',
    icon: Icons.subtitles,
  ),
  SettingsSearchEntry(
    pageRoute: '/player',
    pageTitle: l10n.settingsPlayer,
    optionKey: 'play_history',
    name: l10n.searchPlayProgress,
    keywords: '历史 记录 播放进度 列表',
    icon: Icons.history_rounded,
  ),
  SettingsSearchEntry(
    pageRoute: '/player',
    pageTitle: l10n.settingsPlayer,
    optionKey: 'super_resolution',
    name: l10n.superResolutionTitle,
    keywords: '超分 画质 增强 放大',
    icon: Icons.auto_awesome_motion,
  ),
  SettingsSearchEntry(
    pageRoute: '/player',
    pageTitle: l10n.settingsPlayer,
    optionKey: 'skip_intro_outro',
    name: l10n.skipIntroOutroTitle,
    keywords: '片头 片尾 跳过 SponsorBlock',
    icon: Icons.skip_next_rounded,
  ),
  SettingsSearchEntry(
    pageRoute: '/player',
    pageTitle: l10n.settingsPlayer,
    optionKey: 'decode_format',
    name: l10n.playerDecodeFormat,
    keywords: '解码格式 编码 首选 AV1 H265 HEVC H264 AVC',
    icon: Icons.video_settings_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/player',
    pageTitle: l10n.settingsPlayer,
    optionKey: 'hwdec',
    name: l10n.searchHwdec,
    keywords: '解码 硬解 软解 性能',
    icon: Icons.memory_rounded,
  ),
  SettingsSearchEntry(
    pageRoute: '/player',
    pageTitle: l10n.settingsPlayer,
    optionKey: 'video_sync',
    name: l10n.searchVideoSync,
    keywords: '同步 音画 音频 显示',
    icon: Icons.sync_rounded,
  ),
  SettingsSearchEntry(
    pageRoute: '/player',
    pageTitle: l10n.settingsPlayer,
    optionKey: 'immersive_long_press',
    name: l10n.searchImmersiveLongPress,
    keywords: '沉浸 长按 倍速 控制栏',
    icon: Icons.visibility_off_rounded,
  ),
  SettingsSearchEntry(
    pageRoute: '/player',
    pageTitle: l10n.settingsPlayer,
    optionKey: 'mpv_log',
    name: l10n.searchMpvLog,
    keywords: '日志 记录 mpv 播放器 调试 排查',
    icon: Icons.receipt_long_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/player',
    pageTitle: l10n.settingsPlayer,
    optionKey: 'mpv_log_level',
    name: l10n.searchMpvLogLevel,
    keywords: '日志 细度 等级 详细 调试 trace',
    icon: Icons.tune_rounded,
  ),

  // ── 网络 ──
  SettingsSearchEntry(
    pageRoute: '/network',
    pageTitle: l10n.settingsNetwork,
    optionKey: 'insecure_cert',
    name: l10n.searchInsecureCert,
    keywords: '证书 校验 跳过 HTTPS IP 直连',
    icon: Icons.verified_user_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/network',
    pageTitle: l10n.settingsNetwork,
    optionKey: 'connectivity_test',
    name: l10n.searchConnectivityTest,
    keywords: '测试 检测 ping 网络 状态',
    icon: Icons.dns_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/network',
    pageTitle: l10n.settingsNetwork,
    optionKey: 'host_overrides',
    name: l10n.searchHostOverrides,
    keywords: '域名 IP 映射 hosts 直连',
    icon: Icons.link_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/network',
    pageTitle: l10n.settingsNetwork,
    optionKey: 'doh_query',
    name: l10n.searchDohQuery,
    keywords: 'DNS 域名解析 查询',
    icon: Icons.dns_rounded,
  ),
  SettingsSearchEntry(
    pageRoute: '/network',
    pageTitle: l10n.settingsNetwork,
    optionKey: 'referer',
    name: l10n.searchReferer,
    keywords: '请求头 引用 防盗链',
    icon: Icons.http_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/network',
    pageTitle: l10n.settingsNetwork,
    optionKey: 'user_agent',
    name: l10n.searchUserAgent,
    keywords: 'UA 浏览器 标识 请求头',
    icon: Icons.person_pin_outlined,
  ),

  // ── 语言（B 站 AI 翻译） ──
  SettingsSearchEntry(
    pageRoute: '/language',
    pageTitle: l10n.settingsLanguage,
    optionKey: 'ai_translate',
    name: l10n.biliAiTranslateEnable,
    keywords: 'AI 翻译 翻译 语言 自动翻译 字幕',
    icon: Icons.auto_awesome_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/language',
    pageTitle: l10n.settingsLanguage,
    name: l10n.biliLangSection,
    keywords: '语言 翻译 目标语言 B站 locale 界面',
    icon: Icons.translate,
  ),

  // ── 页面级 ──
  SettingsSearchEntry(
    pageRoute: '/system',
    pageTitle: l10n.settingsSystem,
    name: l10n.searchSystemSettings,
    keywords: '系统 语言 存储 权限',
    icon: Icons.computer_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/user',
    pageTitle: l10n.settingsUser,
    name: l10n.searchUserSettings,
    keywords: '用户 账户 隐私 安全 昵称',
    icon: Icons.person_outline,
  ),
  SettingsSearchEntry(
    pageRoute: '/about',
    pageTitle: l10n.drawerAbout,
    name: l10n.drawerAbout,
    keywords: '版本 关于 信息',
    icon: Icons.info_outline,
  ),
  SettingsSearchEntry(
    pageRoute: '/licenses',
    pageTitle: l10n.settingsLicenses,
    name: '开源许可',
    keywords: '开源 许可 协议 license',
    icon: Icons.code_rounded,
  ),
];

class SettingsSearchPage extends StatefulWidget {
  /// 选中结果时的回调（由设置页负责跳转 + 触发高亮）。
  /// [cardRect] 为被点卡片在全局坐标系中的矩形，
  /// 用于 YouTube 式「整卡展开」的转场动画。
  /// 搜索页自身不 pop：设置页会压在搜索页之上，返回键可回到搜索页继续搜索。
  final void Function(SettingsSearchEntry entry, Rect cardRect) onSelect;

  const SettingsSearchPage({super.key, required this.onSelect});

  @override
  State<SettingsSearchPage> createState() => _SettingsSearchPageState();
}

class _SettingsSearchPageState extends State<SettingsSearchPage> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  /// 实时过滤：匹配名称 / 关键词 / 页面标题（不区分大小写）。
  List<SettingsSearchEntry> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return buildSearchCatalog(AppLocalizations.of(context)).where((e) {
      final haystack = '${e.name} ${e.keywords} ${e.pageTitle}'.toLowerCase();
      // 空格分隔的多关键词，全部命中才算
      return q.split(RegExp(r'\s+')).every(haystack.contains);
    }).toList();
  }

  void _onTapEntry(SettingsSearchEntry entry, BuildContext cardContext) {
//  清脆震动反馈
    HapticFeedback.lightImpact();
    // 收起键盘，避免设置页打开后键盘仍弹出
    FocusScope.of(context).unfocus();
    // 计算被点卡片的全局矩形，供整卡展开转场使用
    final box = cardContext.findRenderObject();
    final rect = box is RenderBox && box.attached
        ? box.localToGlobal(Offset.zero) & box.size
        : Offset.zero & MediaQuery.of(context).size;
    widget.onSelect(entry, rect);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final results = _results;

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: SafeArea(
        child: Column(
          children: [
            // ── 顶部：返回 + 搜索框 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  MorphIconButton(
                    icon: Icons.arrow_back,
                    tooltip: l10n.searchBack,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _queryController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _queryController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: cs.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(kGroupRadius),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ],
              ),
            ),
            // ── 结果列表 ──
            Expanded(
              child: _query.trim().isEmpty
                  ? _buildHint(cs)
                  : results.isEmpty
                  ? _buildEmpty(cs)
                  : _buildResults(cs, results),
            ),
          ],
        ),
      ),
    );
  }

  /// 按页面分组展示结果（morph 卡片风格）。
  Widget _buildResults(ColorScheme cs, List<SettingsSearchEntry> results) {
    final byPage = <String, List<SettingsSearchEntry>>{};
    for (final e in results) {
      byPage.putIfAbsent(e.pageRoute, () => []).add(e);
    }
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [for (final group in byPage.values) ..._buildGroup(cs, group)],
    );
  }

  List<Widget> _buildGroup(ColorScheme cs, List<SettingsSearchEntry> group) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
        child: Text(
          group.first.pageTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.primary,
          ),
        ),
      ),
      ...buildMorphSegmentedList([
        for (final entry in group)
          MorphRowItem(
            // Builder 拿到卡片自身 context，用于计算整卡展开的起始矩形
            child: Builder(
              builder: (cardContext) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Icon(entry.icon, size: 24, color: cs.onSurfaceVariant),
                title: Text(entry.name),
                subtitle: Text(
                  entry.pageTitle,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: cs.onSurfaceVariant,
                  size: 20,
                ),
                onTap: () => _onTapEntry(entry, cardContext),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildHint(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.manage_search_rounded,
            size: 56,
            color: cs.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.searchPrompt,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.searchExamples,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: cs.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.searchNoResults(_query.trim()),
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════
//  YouTube 式「整卡展开」页面转场
// ═════════════════════════════════════════

/// 从 [startRect]（被点卡片的全局矩形）展开到全屏的页面路由。
///
/// 原理：把目标页整体做矩形映射 —— 卡片区域在 t=0 时恰好铺满屏幕，
/// 随动画逐步还原为正常显示，非等比拉伸，效果类似 YouTube 点开视频卡片。
/// 不依赖 Hero，因此跨 Navigator（拆分模式的右侧栏）同样生效。
class ExpandingCardPageRoute<T> extends PageRouteBuilder<T> {
  ExpandingCardPageRoute({required Widget page, required Rect startRect})
    : super(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final size = MediaQuery.of(context).size;
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(animation.value);
              // 卡片矩形 → 全屏矩形 插值
              final rect = Rect.lerp(startRect, Offset.zero & size, t)!;
              // 把 rect 区域映射到整个屏幕
              final sx = size.width / rect.width;
              final sy = size.height / rect.height;
              final screenCenter = Offset(size.width / 2, size.height / 2);
              final matrix = Matrix4.identity()
                ..translate(screenCenter.dx, screenCenter.dy)
                ..scale(sx, sy)
                ..translate(-rect.center.dx, -rect.center.dy);
              return ClipRRect(
                borderRadius: BorderRadius.circular(
                  (kItemPressedRadius * (1 - t)).clamp(0, kItemPressedRadius),
                ),
                child: Transform(transform: matrix, child: child),
              );
            },
          );
        },
      );
}
