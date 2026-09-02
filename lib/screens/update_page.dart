// lib/screens/update_page.dart
//
// MIUI 风格的版本更新页：
//  - 首次进入先展示当前版本，固定检查 3 秒；
//  - 检查结果使用本地演示数据，始终返回一个更新，方便测试交互；
//  - 新版本卡片从当前版本页右侧滑入，并复用 B 站卡片的按压倾斜效果；
//  - 左右滑动切换当前版本页 / 更新页；点击卡片在原位翻到背面。
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../build_info.g.dart';
import '../widgets/MetroTile.dart';
import '../widgets/app_toast.dart';
import '../widgets/expressive_app_bar.dart';

class _UpdateRelease {
  final String version;
  final String build;
  final String size;
  final String date;
  final List<_UpdateNote> notes;

  const _UpdateRelease({
    required this.version,
    required this.build,
    required this.size,
    required this.date,
    required this.notes,
  });
}

class _UpdateNote {
  final String zhTitle;
  final String enTitle;
  final String zhBody;
  final String enBody;

  const _UpdateNote({
    required this.zhTitle,
    required this.enTitle,
    required this.zhBody,
    required this.enBody,
  });
}

// 暂无线上更新接口时使用的演示版本。保持为常量，测试时每次都能稳定看到更新卡片。
const _demoRelease = _UpdateRelease(
  version: '1.2.1',
  build: 'RedStone-R3',
  size: '18 MB',
  date: '2026-08-27',
  notes: [
    _UpdateNote(
      zhTitle: '系统',
      enTitle: 'System',
      zhBody:
          '优化运营商网络下的视频加载体验，减少卡顿。\n\n修复深色模式下通知栏文字对比度不足的问题，并提升小窗模式下的视频播放性能。',
      enBody:
          'Improved video loading over carrier networks with fewer stalls.\n\nFixed notification text contrast in dark mode and improved video playback performance in small windows.',
    ),
    _UpdateNote(
      zhTitle: '体验优化',
      enTitle: 'Experience',
      zhBody: '新增本地收藏夹与观看历史足迹，优化全局翻译标题缓存。',
      enBody:
          'Added local favorites and watch history, and optimized the global translated-title cache.',
    ),
  ],
);

class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage>
    with SingleTickerProviderStateMixin {
  static const _checkDuration = Duration(seconds: 3);

  late final AnimationController _cardFlipController;
  late final PageController _pageController;
  Timer? _checkTimer;
  bool _checking = true;
  bool _hasUpdate = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _cardFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
      reverseDuration: const Duration(milliseconds: 640),
    );
    _pageController = PageController();
    _checkTimer = Timer(_checkDuration, _finishChecking);
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _cardFlipController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _finishChecking() {
    _checkTimer?.cancel();
    if (!mounted || _hasUpdate) return;
    setState(() {
      _checking = false;
      // 演示阶段始终有更新，确保可以完整测试图 1 → 图 2 → 图 3。
      _hasUpdate = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients || _currentPage != 0) {
        return;
      }
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 720),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _handleBack() {
    Navigator.of(context).maybePop();
  }

  void _showMore() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    showAppToast(context, isZh ? '当前为测试更新版本' : 'This is a demo update');
  }

  void _onDownload() {
    HapticFeedback.lightImpact();
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    showAppToast(
      context,
      isZh ? '更新包下载功能即将上线' : 'Update download will be available soon',
    );
  }

  void _toggleCardDetails() {
    if (!_hasUpdate) return;
    HapticFeedback.lightImpact();
    if (_cardFlipController.value >= 0.5) {
      _cardFlipController.reverse();
    } else {
      _cardFlipController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final title = _currentPage == 1 && _hasUpdate
        ? (isZh ? '发现新版本' : 'New version available')
        : (isZh ? '系统更新' : 'System update');

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          ExpressiveSliverAppBar(
            title: title,
            expandedHeight: 120,
            leading: MorphIconButton(
              icon: Icons.arrow_back,
              tooltip: isZh ? '返回' : 'Back',
              onTap: _handleBack,
            ),
            actions: [
              MorphIconButton(
                icon: Icons.more_vert,
                tooltip: isZh ? '更多' : 'More',
                onTap: _showMore,
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(child: _buildStage()),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 28),
          ),
        ],
      ),
    );
  }

  Widget _buildStage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = (constraints.maxWidth * 1.18)
            .clamp(460.0, 600.0)
            .toDouble();
        final stageHeight = cardHeight + 66;

        return SizedBox(
          height: stageHeight,
          child: PageView(
            controller: _pageController,
            physics: _hasUpdate
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            onPageChanged: (page) {
              if (mounted && _currentPage != page) {
                setState(() => _currentPage = page);
              }
            },
            children: [
              _buildCurrentStage(cardHeight),
              _buildUpdateStage(cardHeight),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentStage(double cardHeight) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return SizedBox(
      height: cardHeight + 66,
      child: Column(
        children: [
          Expanded(child: _CurrentVersionPanel(cardHeight: cardHeight)),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _checking ? null : _finishChecking,
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _checking
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(isZh ? '正在检查更新…' : 'Checking…'),
                            ],
                          )
                        : Text(isZh ? '检查更新' : 'Check updates'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _showMore,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(isZh ? '进入社区讨论' : 'Community'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateStage(double cardHeight) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return SizedBox(
      height: cardHeight + 66,
      child: Column(
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: _UpdateCardFlip(
                animation: _cardFlipController,
                front: _buildUpdateCard(onTap: _toggleCardDetails),
                back: _buildUpdateDetailsCard(onTap: _toggleCardDetails),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: FilledButton(
              onPressed: _onDownload,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(isZh ? '下载更新' : 'Download update'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard({required VoidCallback? onTap}) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Color.lerp(
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                      0.55,
                    ) ??
                    Theme.of(context).colorScheme.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.24),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            onLongPress: () => HapticFeedback.mediumImpact(),
            borderRadius: BorderRadius.circular(28),
            splashColor: Colors.white.withValues(alpha: 0.14),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 330;
                final padding = compact ? 20.0 : 26.0;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      right: -76,
                      top: -74,
                      child: _OutlineCircle(
                        size: compact ? 220 : 280,
                        color: Colors.white.withValues(alpha: 0.13),
                      ),
                    ),
                    Positioned(
                      right: compact ? 12 : 28,
                      top: compact ? 170 : 205,
                      child: _OutlineCircle(
                        size: compact ? 82 : 106,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NAVI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 28 : 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.8,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                isZh ? '更新' : 'UPDATE',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: compact ? 11 : 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'V${_demoRelease.version} · ${_demoRelease.size}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: compact ? 15 : 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            isZh ? '新版本优化应用' : 'A better Navi experience',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 20 : 23,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.86),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isZh
                                      ? '连接、播放与同步体验全面优化'
                                      : 'Connection, playback and sync improvements',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: compact ? 12 : 13,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isZh
                                      ? '点击查看完整日志'
                                      : 'Tap to view full changelog',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: compact ? 13 : 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white.withValues(alpha: 0.82),
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateDetailsCard({required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final systemNote = _demoRelease.notes.first;
    final experienceNote = _demoRelease.notes[1];

    return MetroTileInteraction(
      onTapStart: (_, __) {},
      showBorder: false,
      child: Material(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'NAVI',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                    Text(
                      'V${_demoRelease.version}\n${_demoRelease.size}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(color: cs.outlineVariant.withValues(alpha: 0.7)),
                const SizedBox(height: 22),
                Text(
                  isZh ? '更新详情' : 'Update details',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isZh ? systemNote.zhTitle : systemNote.enTitle,
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isZh ? systemNote.zhBody : systemNote.enBody,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: cs.outlineVariant.withValues(alpha: 0.62)),
                const SizedBox(height: 20),
                Text(
                  isZh ? experienceNote.zhTitle : experienceNote.enTitle,
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isZh ? experienceNote.zhBody : experienceNote.enBody,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isZh ? '点击卡片返回版本信息' : 'Tap the card to return',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentVersionPanel extends StatelessWidget {
  final double cardHeight;

  const _CurrentVersionPanel({required this.cardHeight});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return Container(
      width: double.infinity,
      height: cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111318), Color(0xFF050609)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: -100,
            top: -120,
            child: _OutlineCircle(
              size: 270,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Positioned(
            right: -50,
            bottom: -70,
            child: _OutlineCircle(
              size: 220,
              color: cs.primary.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  'NAVI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'V1.2.0 · ${BuildInfo.buildCodename}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isZh ? '当前版本' : 'Current version',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 80,
                  height: 2,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.76),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isZh ? '正在为你检查新版本' : 'Checking for a new version',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.52),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _OutlineCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}

/// 更新卡片原地绕底部横轴翻转，背面就是更新详情，而不是一个新页面。
class _UpdateCardFlip extends StatelessWidget {
  final Animation<double> animation;
  final Widget front;
  final Widget back;

  const _UpdateCardFlip({
    required this.animation,
    required this.front,
    required this.back,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final raw = animation.value.clamp(0.0, 1.0).toDouble();
        if (raw < 0.5) {
          final progress = Curves.easeInCubic.transform(raw * 2);
          return _buildFace(
            face: front,
            angle: -math.pi / 2 * progress,
            shade: 0.18 * math.sin(progress * math.pi / 2),
          );
        }

        final progress = Curves.easeOutCubic.transform((raw - 0.5) * 2);
        return _buildFace(
          face: back,
          angle: math.pi / 2 * (1 - progress),
          shade: 0.18 * math.sin((1 - progress) * math.pi / 2),
        );
      },
    );
  }

  Widget _buildFace({
    required Widget face,
    required double angle,
    required double shade,
  }) {
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0014)
        ..rotateX(angle),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            face,
            if (shade > 0)
              ColoredBox(color: Colors.black.withValues(alpha: shade)),
          ],
        ),
      ),
    );
  }
}
