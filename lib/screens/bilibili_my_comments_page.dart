                                             
  
                                              
                                     
                                               
                                           
                           
                                      
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:naviflash/screens/article_page.dart';
import 'package:naviflash/screens/bilibili_video_page.dart';
import 'package:naviflash/services/bv_av.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/my_reply_service.dart';
import 'package:naviflash/services/reply_antifraud_service.dart';
import 'package:naviflash/widgets/app_drawer.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/frosted_page_bar.dart';
import 'package:naviflash/widgets/frosted_route.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/navi_oval_tab_row.dart';
import 'package:naviflash/widgets/liquid_glass_menu_button.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/search_video_menu.dart';
import 'package:naviflash/widgets/side_bar_menu_button.dart';

class BilibiliMyCommentsPage extends StatefulWidget {
                                         
  final bool drawerMode;

  const BilibiliMyCommentsPage({super.key, this.drawerMode = false});

  @override
  State<BilibiliMyCommentsPage> createState() => _BilibiliMyCommentsPageState();
}

class _BilibiliMyCommentsPageState extends State<BilibiliMyCommentsPage>
    with SingleTickerProviderStateMixin {
                                
  static const double _kTabRowHeight = 46.0;

  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

                          
  final Set<String> _checking = {};

  bool _auditAllRunning = false;

  @override
  void initState() {
    super.initState();
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final service = context.watch<MyReplyService>();
    final normal = service.normalRecords;
    final curated = service.curatedRecords;

                                               
    final scaffold = Scaffold(
      backgroundColor: cs.surfaceContainer,
      drawer: widget.drawerMode
          ? const AppDrawer(currentPage: 'mycomments')
          : null,
                                    
      onDrawerChanged: SideBarDrawerState.setOpen,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer, contentStyle: true),
          SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: kFrostedPageBarHeight + _kTabRowHeight,
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildList(normal, curated: false, cs: cs),
                            _buildList(curated, curated: true, cs: cs),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: FrostedPageBar(
                    title: '我的评论',
                    drawerMode: widget.drawerMode,
                    bottomHeight: _kTabRowHeight,
                                          
                    bottom: NaviOvalTabRow(
                      labels: ['普通 (${normal.length})', '精选 (${curated.length})'],
                      selectedIndex: _tabController.index,
                      onTap: (index) {
                        if (index != _tabController.index) {
                          _tabController.animateTo(index);
                        }
                      },
                      height: _kTabRowHeight,
                    ),
                    actions: [
                                                    
                      LiquidGlassMenuButton(
                        icon: Icons.more_vert,
                        tooltip: '更多',
                        menuWidth: 220,
                        transparent: true,
                        actions: [
                          if (_tabController.index == 1)
                            GlassMenuAction(
                              icon: Icons.fact_check_outlined,
                              text: _auditAllRunning
                                  ? '检测中…'
                                  : '检测精选评论是否入选',
                              isEnabled: !_auditAllRunning,
                              onTap: _auditAll,
                            ),
                          GlassMenuAction(
                            icon: Icons.delete_sweep_outlined,
                            text: '清空全部记录',
                            isDestructive: true,
                            onTap: _confirmClear,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
                            
    return IosBackdropScale(child: scaffold);
  }

  Widget _buildList(
    List<MyReplyRecord> records, {
    required bool curated,
    required ColorScheme cs,
  }) {
    if (records.isEmpty) return _buildEmpty(curated, cs);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: records.length,
      itemBuilder: (context, i) => Padding(
        padding: EdgeInsets.only(bottom: i == records.length - 1 ? 0 : 10),
        child: _buildCard(records[i], curated: curated, cs: cs),
      ),
    );
  }

  Widget _buildEmpty(bool curated, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              curated ? Icons.verified_outlined : Icons.mode_comment_outlined,
              size: 56,
              color: cs.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 12),
            Text(
              curated ? '暂无精选评论区发出的评论' : '暂无发出的评论记录',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              curated
                  ? '评论区开启精选后发出的评论会归入这里，\n点「检测」可查看是否已被 UP 选入评论区'
                  : '在 App 内发送的评论会自动记录到这里',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    MyReplyRecord rec, {
    required bool curated,
    required ColorScheme cs,
  }) {
    final checking = _checking.contains(rec.rpid);
    final showStatus = curated || rec.checkStatus != ReplyAuditStatus.unknown;
    final hint = ReplyAntifraudService.hint(rec.checkStatus, curated: curated);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                          
          Row(
            children: [
              Icon(_typeIcon(rec.type), size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _sourceLabel(rec),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(rec.ctime),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
                       
          Text(
            rec.message,
            style: TextStyle(fontSize: 14, height: 1.45, color: cs.onSurface),
          ),
                     
          if (rec.pictures.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final url in rec.pictures.take(9))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image(
                      image: CachedImageProvider('$url@120w_120h_1c.webp'),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
                                                
          if (showStatus) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(rec.checkStatus, cs),
                if (hint.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hint,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
                     
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: checking || rec.rpid.isEmpty
                    ? null
                    : () => _checkOne(rec),
                icon: checking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.shield_outlined, size: 16),
                label: Text(checking ? '检测中' : '检测'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openSource(rec),
                icon: const Icon(Icons.open_in_new, size: 15),
                label: const Text('原处'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              IconButton(
                tooltip: '删除记录',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                onPressed: () async {
                  await MyReplyService.instance.remove(rec);
                  if (mounted) showAppToast(context, '已删除该条记录');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ReplyAuditStatus status, ColorScheme cs) {
    final (color, icon) = switch (status) {
      ReplyAuditStatus.visible => (Colors.green, Icons.verified_outlined),
      ReplyAuditStatus.shadowBan => (
        Colors.orange,
        Icons.visibility_off_outlined,
      ),
      ReplyAuditStatus.invisible => (cs.error, Icons.highlight_off_outlined),
      ReplyAuditStatus.suspicious => (Colors.orange, Icons.help_outline),
      ReplyAuditStatus.error => (cs.outline, Icons.error_outline),
      ReplyAuditStatus.unknown => (cs.outline, Icons.shield_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            ReplyAntifraudService.label(status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

             

  Future<void> _checkOne(MyReplyRecord rec) async {
    if (_checking.contains(rec.rpid)) return;
    setState(() => _checking.add(rec.rpid));
    try {
      await MyReplyService.instance.auditRecord(rec, manual: true);
    } finally {
      if (mounted) setState(() => _checking.remove(rec.rpid));
    }
  }

                                     
  Future<void> _auditAll() async {
    final targets = MyReplyService.instance.curatedRecords
        .where((r) => r.rpid.isNotEmpty)
        .toList();
    if (targets.isEmpty) {
      showAppToast(context, '精选页暂无可检测的评论');
      return;
    }
    setState(() => _auditAllRunning = true);
    var visible = 0;
    var hidden = 0;
    var failed = 0;
    for (final rec in targets) {
      if (!mounted) break;
      setState(() => _checking.add(rec.rpid));
      final result = await MyReplyService.instance.auditRecord(
        rec,
        manual: true,
        showDialog: false,
      );
      switch (result.status) {
        case ReplyAuditStatus.visible:
          visible++;
        case ReplyAuditStatus.shadowBan:
        case ReplyAuditStatus.invisible:
        case ReplyAuditStatus.suspicious:
          hidden++;
        case ReplyAuditStatus.error:
          failed++;
        case ReplyAuditStatus.unknown:
          break;
      }
      if (mounted) setState(() => _checking.remove(rec.rpid));
    }
    if (!mounted) return;
    setState(() => _auditAllRunning = false);
    showAppToast(
      context,
      '检测完成：已入选 $visible · 未入选/不可见 $hidden · 失败 $failed',
    );
  }

               

  Future<void> _openSource(MyReplyRecord rec) async {
    final oid = int.tryParse(rec.oid) ?? 0;
    if (rec.type == 1 && oid > 0) {
      final bvid = rec.sourceId.startsWith('BV')
          ? rec.sourceId
          : (BvAv.encode(oid) ?? '');
      if (bvid.isNotEmpty) {
        if (!mounted) return;
        await Navigator.of(context).push(
                                                   
          ImmersiveMaterialPageRoute<void>(
            page: BilibiliVideoPage(
              bvid: bvid,
              initialTitle: rec.sourceTitle.trim().isEmpty
                  ? null
                  : rec.sourceTitle.trim(),
            ),
          ),
        );
        return;
      }
    } else if (rec.type == 12 && oid > 0) {
      if (!mounted) return;
      await Navigator.of(context).push(
                                       
        ImmersiveMaterialPageRoute(
          page: ArticlePage(
            cvid: oid,
            initialTitle: rec.sourceTitle.trim().isEmpty
                ? null
                : rec.sourceTitle.trim(),
          ),
        ),
      );
      return;
    }
    final url = rec.type == 1
        ? 'https://www.bilibili.com/video/av$oid'
        : rec.type == 12
            ? 'https://www.bilibili.com/read/cv$oid'
            : 'https://www.bilibili.com/opus/$oid';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空全部记录？'),
        content: const Text('仅删除本地评论记录，不影响 B 站上已发布的评论。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await MyReplyService.instance.clear();
    if (mounted) showAppToast(context, '已清空评论记录');
  }

               

  IconData _typeIcon(int type) => switch (type) {
        12 => Icons.article_outlined,
        17 || 11 => Icons.motion_photos_on_outlined,
        _ => Icons.play_circle_outline,
      };

  String _sourceLabel(MyReplyRecord rec) {
    final title = rec.sourceTitle.trim();
    if (title.isNotEmpty) return title;
    return switch (rec.type) {
      1 => '视频 av${rec.oid}',
      12 => '专栏 cv${rec.oid}',
      17 || 11 => '动态 ${rec.oid}',
      _ => '评论目标 ${rec.oid}',
    };
  }

  String _formatTime(int ctime) {
    if (ctime <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ctime * 1000);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    if (diff.inDays < 30) return '${diff.inDays} 天前';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}
