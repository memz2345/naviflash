                                        
  
                               
                                           
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../widgets/widgets.dart';
import '../l10n/app_localizations.dart';

            
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

           
List<SettingsSearchEntry> buildSearchCatalog(AppLocalizations l10n) => [
             
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
                                                       
  if (Platform.isAndroid)
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

              
  SettingsSearchEntry(
    pageRoute: '/player',
    pageTitle: l10n.settingsPlayer,
    optionKey: 'status_bar',
    name: l10n.searchStatusBar,
    keywords: '播放器 电量 时间 网络 顶部',
    icon: Icons.phone_android,
  ),
                                                   
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
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
                                                                   
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
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

                      
  SettingsSearchEntry(
    pageRoute: '/shortcuts',
    pageTitle: '快捷键',
    name: '播放器快捷键',
    keywords: '快捷键 键盘 改键 按键 快进 暂停 全屏 音量 播放器',
    icon: Icons.keyboard_alt_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/shortcuts',
    pageTitle: '快捷键',
    optionKey: 'shortcuts_enabled',
    name: '启用播放器快捷键',
    keywords: '快捷键 键盘 启用 开关',
    icon: Icons.keyboard_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/shortcuts',
    pageTitle: '快捷键',
    optionKey: 'shortcuts_reset_all',
    name: '恢复全部默认快捷键',
    keywords: '快捷键 恢复 默认 重置 还原',
    icon: Icons.restart_alt,
  ),

             
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
    pageRoute: '/preferences',
    pageTitle: l10n.settingsPreferences,
    optionKey: 'bottom_bar_search',
    name: l10n.prefBottomBarSearch,
    keywords: '底栏 搜索 推荐页 孤儿 底部导航',
    icon: Icons.search_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/preferences',
    pageTitle: l10n.settingsPreferences,
    optionKey: 'enable_comm_antifraud',
    name: '发评反诈助手',
    keywords: '评论 反诈 检测 可见 shadow ban 精选 审核 我的评论',
    icon: Icons.shield_outlined,
  ),
                                  
  SettingsSearchEntry(
    pageRoute: '/preferences',
    pageTitle: l10n.settingsPreferences,
    optionKey: 'player_default_rate',
    name: l10n.playerDefaultRate,
    keywords: '播放器 默认 倍速 速度 记住 起始',
    icon: Icons.speed_rounded,
  ),
  SettingsSearchEntry(
    pageRoute: '/preferences',
    pageTitle: l10n.settingsPreferences,
    optionKey: 'player_end_behavior',
    name: l10n.playerDefaultEndBehavior,
    keywords: '播放器 结束 播完 暂停 循环 退出 默认行为 记住',
    icon: Icons.video_settings_rounded,
  ),
  SettingsSearchEntry(
    pageRoute: '/preferences',
    pageTitle: l10n.settingsPreferences,
    optionKey: 'load_danmaku_on_resume',
    name: l10n.playerLoadDanmakuOnResume,
    keywords: '播放器 恢复 继续 弹幕 自动加载 记住',
    icon: Icons.subtitles_outlined,
  ),
  if (Platform.isAndroid)
    SettingsSearchEntry(
      pageRoute: '/preferences',
      pageTitle: l10n.settingsPreferences,
      optionKey: 'auto_pip',
      name: l10n.playerAutoPip,
      keywords: '播放器 画中画 后台 桌面 pip 自动',
      icon: Icons.picture_in_picture_alt_outlined,
    ),
  SettingsSearchEntry(
    pageRoute: '/preferences',
    pageTitle: l10n.settingsPreferences,
    optionKey: 'player_stats',
    name: l10n.playerShowStats,
    keywords: '播放器 统计信息 解码 码率 osd 高级',
    icon: Icons.analytics_outlined,
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
                
  SettingsSearchEntry(
    pageRoute: '/recommend',
    pageTitle: l10n.settingsRecommend,
    optionKey: 'rcmd_use_app_source',
    name: l10n.rcmdUseAppSource,
    keywords: '推荐 推荐源 app web 首页 recommend source',
    icon: Icons.model_training_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/recommend',
    pageTitle: l10n.settingsRecommend,
    optionKey: 'rcmd_keep_last',
    name: l10n.rcmdKeepLastData,
    keywords: '推荐 刷新 保留 上次内容 refresh keep',
    icon: Icons.refresh,
  ),
  SettingsSearchEntry(
    pageRoute: '/recommend',
    pageTitle: l10n.settingsRecommend,
    optionKey: 'rcmd_saved_tip',
    name: l10n.rcmdSavedPositionTip,
    keywords: '推荐 位置 提示 上次看到这里 tip position',
    icon: Icons.tips_and_updates_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/recommend',
    pageTitle: l10n.settingsRecommend,
    optionKey: 'rcmd_min_like_ratio',
    name: l10n.rcmdMinLikeRatio,
    keywords: '推荐 过滤器 点赞率 like ratio filter',
    icon: Icons.thumb_up_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/recommend',
    pageTitle: l10n.settingsRecommend,
    optionKey: 'rcmd_min_duration',
    name: l10n.rcmdMinDuration,
    keywords: '推荐 过滤器 时长 秒 duration filter',
    icon: Icons.timer_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/recommend',
    pageTitle: l10n.settingsRecommend,
    optionKey: 'rcmd_min_play',
    name: l10n.rcmdMinPlay,
    keywords: '推荐 过滤器 播放量 views filter',
    icon: Icons.play_circle_outline,
  ),
  SettingsSearchEntry(
    pageRoute: '/recommend',
    pageTitle: l10n.settingsRecommend,
    optionKey: 'rcmd_ban_word',
    name: l10n.rcmdBanWord,
    keywords: '推荐 过滤器 标题 关键词 屏蔽 正则 ban word regex',
    icon: Icons.filter_alt_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/recommend',
    pageTitle: l10n.settingsRecommend,
    optionKey: 'rcmd_ban_zone',
    name: l10n.rcmdBanZone,
    keywords: '推荐 过滤器 分区 关键词 屏蔽 正则 zone ban',
    icon: Icons.category_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/recommend',
    pageTitle: l10n.settingsRecommend,
    optionKey: 'rcmd_exempt_followed',
    name: l10n.rcmdExemptFollowed,
    keywords: '推荐 过滤器 已关注 up 豁免 exempt followed',
    icon: Icons.favorite_border_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/recommend',
    pageTitle: l10n.settingsRecommend,
    optionKey: 'rcmd_filter_related',
    name: l10n.rcmdFilterRelated,
    keywords: '推荐 过滤器 相关视频 related filter',
    icon: Icons.explore_outlined,
  ),
                   
  SettingsSearchEntry(
    pageRoute: '/ugc-filter',
    pageTitle: l10n.ugcFilterTitle,
    optionKey: 'ugc_filter_recommend',
    name: l10n.ugcFilterScopeRecommend,
    keywords: '过滤 关键词 屏蔽 正则 推荐 filter ban keyword',
    icon: Icons.recommend_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/ugc-filter',
    pageTitle: l10n.ugcFilterTitle,
    optionKey: 'ugc_filter_zone',
    name: l10n.ugcFilterScopeZone,
    keywords: '过滤 关键词 屏蔽 分区 正则 filter ban zone',
    icon: Icons.category_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/ugc-filter',
    pageTitle: l10n.ugcFilterTitle,
    optionKey: 'ugc_filter_reply',
    name: l10n.ugcFilterScopeReply,
    keywords: '过滤 关键词 屏蔽 评论 正则 filter ban comment',
    icon: Icons.comment_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/ugc-filter',
    pageTitle: l10n.ugcFilterTitle,
    optionKey: 'ugc_filter_dyn',
    name: l10n.ugcFilterScopeDyn,
    keywords: '过滤 关键词 屏蔽 动态 正则 filter ban dynamic',
    icon: Icons.dynamic_feed_outlined,
  ),
                                  
  SettingsSearchEntry(
    pageRoute: '/ai',
    pageTitle: l10n.settingsAi,
    optionKey: 'onnx_dependency',
    name: l10n.onnxDepSection,
    keywords: 'AI 防遮挡 弹幕 模型 onnx 下载 卸载 依赖',
    icon: Icons.hide_source_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/ai',
    pageTitle: l10n.settingsAi,
    optionKey: 'tts_dependency',
    name: l10n.ttsNoInstallTitle,
    keywords: 'AI 朗读 TTS 模型 语音 合成 下载 镜像 音色 克隆',
    icon: Icons.record_voice_over_outlined,
  ),
  SettingsSearchEntry(
    pageRoute: '/ai',
    pageTitle: l10n.settingsAi,
    optionKey: 'ai_model_location',
    name: l10n.storageLocationModels,
    keywords: 'AI 模型 位置 目录 存储 路径 下载到',
    icon: Icons.folder_outlined,
  ),
];

class SettingsSearchPage extends StatefulWidget {
                                
                                 
                              
                                           
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

                                     
  List<SettingsSearchEntry> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return buildSearchCatalog(AppLocalizations.of(context)).where((e) {
      final haystack = '${e.name} ${e.keywords} ${e.pageTitle}'.toLowerCase();
                         
      return q.split(RegExp(r'\s+')).every(haystack.contains);
    }).toList();
  }

  void _onTapEntry(SettingsSearchEntry entry, BuildContext cardContext) {
          
    HapticFeedback.lightImpact();
                         
    FocusScope.of(context).unfocus();
                            
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

                            
  Widget _buildResults(ColorScheme cs, List<SettingsSearchEntry> results) {
    final byPage = <String, List<SettingsSearchEntry>>{};
    for (final e in results) {
      byPage.putIfAbsent(e.pageRoute, () => []).add(e);
    }
    return ListView(
      physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),                                                  
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
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.searchPrompt,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.searchExamples,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
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
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.searchNoResults(_query.trim()),
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

                                            
                       
                                            

                                       
   
                                        
                                           
                                         
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
                               
              final rect = Rect.lerp(startRect, Offset.zero & size, t)!;
                                 
              final sx = size.width / rect.width;
              final sy = size.height / rect.height;
              final screenCenter = Offset(size.width / 2, size.height / 2);
              final matrix = Matrix4.identity()
                ..translateByDouble(screenCenter.dx, screenCenter.dy, 0, 1)
                ..scaleByDouble(sx, sy, 1, 1)
                ..translateByDouble(-rect.center.dx, -rect.center.dy, 0, 1);
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
