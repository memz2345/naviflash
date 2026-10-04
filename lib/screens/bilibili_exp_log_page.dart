                                         
  
                                   
                                           
                                 
                                
                                                                   
                                              
                                 
                                          
import 'package:flutter/material.dart';

import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/services/bilibili_account_log_service.dart';
import 'package:naviflash/services/bilibili_mine_service.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/frosted_page_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/page_loading.dart';

                                      
const double _kTopBarHeight = 56.0;

class BilibiliExpLogPage extends StatefulWidget {
  const BilibiliExpLogPage({super.key});

  @override
  State<BilibiliExpLogPage> createState() => _BilibiliExpLogPageState();
}

class _BilibiliExpLogPageState extends State<BilibiliExpLogPage> {
  List<BiliCoinExpLogEntry> _items = [];
  BiliMineProfile? _profile;
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
                                             
    final (:items, :err) = await BilibiliAccountLogService.fetchExpLog();
    final profile = await BilibiliMineService.fetchProfile();
    if (!mounted) return;
    setState(() {
      _items = items;
      _profile = profile;
      _loading = false;
      _error = err;
    });
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BilibiliLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scaffold = Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer, contentStyle: true),
          SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: _buildBody(cs)),
                const Align(
                  alignment: Alignment.topCenter,
                  child: FrostedPageBar(title: '经验记录'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return IosBackdropScale(child: scaffold);
  }

  Widget _buildBody(ColorScheme cs) {
    if (!BilibiliAccountLogService.isLoggedIn && _items.isEmpty && !_loading) {
      return _centeredState(
        cs,
        icon: Icons.military_tech_outlined,
        text: '登录后可以查看经验记录',
        action: FilledButton.tonal(
          onPressed: _openLogin,
          child: const Text('去登录'),
        ),
      );
    }
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _items.isEmpty,
    )) {
      return _centeredState(cs, child: const PageLoadingIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return _centeredState(
        cs,
        text: _error!,
        action: _error!.contains('登录') || _error!.contains('bili_jct')
            ? FilledButton.tonal(
                onPressed: _openLogin,
                child: const Text('去登录'),
              )
            : null,
      );
    }
    if (_items.isEmpty) {
      return _centeredState(
        cs,
        icon: Icons.military_tech_outlined,
        text: '最近一周没有经验变动',
        subText: '登录 / 观看 / 投币等奖励会显示在这里',
      );
    }
    return AppRefreshIndicator(
      onRefresh: _load,
      color: cs.primary,
      edgeOffset: 0,
      displacement: _kTopBarHeight + 10,
      child: CustomScrollView(
        physics: const AppRefreshScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: _kTopBarHeight)),
          SliverToBoxAdapter(child: _buildExpHeader(cs)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _buildRow(cs, _items[i]),
            ),
          ),
        ],
      ),
    );
  }

                                         
  Widget _buildExpHeader(ColorScheme cs) {
    final p = _profile;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceBright,
          borderRadius: BorderRadius.circular(16),
        ),
        child: p == null
            ? Text(
                '暂无法获取当前经验（下拉重试）',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'LV${p.level}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '当前经验 ${p.currentExp}'
                          '${p.level >= 6 ? '' : ' / ${p.nextExp}'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: p.expProgress,
                      minHeight: 6,
                      backgroundColor: cs.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRow(ColorScheme cs, BiliCoinExpLogEntry item) {
    final income = item.delta > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.trending_up_rounded,
            size: 20,
            color: income ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.reason.isEmpty ? '（无说明）' : item.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  item.time,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            income ? '+${item.delta}' : '${item.delta}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: income ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

                            
  Widget _centeredState(
    ColorScheme cs, {
    IconData? icon,
    String? text,
    String? subText,
    Widget? action,
    Widget? child,
  }) {
    return Column(
      children: [
        const SizedBox(height: _kTopBarHeight),
        Expanded(
          child: Center(
            child: child ??
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null)
                      Icon(icon, size: 48, color: cs.onSurfaceVariant),
                    if (icon != null) const SizedBox(height: 12),
                    if (text != null)
                      Text(
                        text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    if (subText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (action != null) ...[
                      const SizedBox(height: 12),
                      action,
                    ],
                  ],
                ),
          ),
        ),
      ],
    );
  }
}
