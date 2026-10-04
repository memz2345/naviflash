                                          
  
                                        
                                            
                                 
                                              
                                 
                                            
                              
                         
import 'package:flutter/material.dart';

import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/services/bilibili_account_log_service.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/frosted_page_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/page_loading.dart';

                                      
const double _kTopBarHeight = 56.0;

class BilibiliCoinLogPage extends StatefulWidget {
  const BilibiliCoinLogPage({super.key});

  @override
  State<BilibiliCoinLogPage> createState() => _BilibiliCoinLogPageState();
}

class _BilibiliCoinLogPageState extends State<BilibiliCoinLogPage> {
  List<BiliCoinExpLogEntry> _items = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    final (:items, :err) = await BilibiliAccountLogService.fetchCoinLog();
    if (!mounted) return;
    setState(() {
      _items = items;
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
                  child: FrostedPageBar(title: '硬币记录'),
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
        icon: Icons.paid_outlined,
        text: '登录后可以查看硬币记录',
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
        icon: Icons.paid_outlined,
        text: '最近一周没有硬币变动',
        subText: '投币 / 收币记录会显示在这里',
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
          SliverToBoxAdapter(child: _buildSummaryCard(cs)),
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

                               
  Widget _buildSummaryCard(ColorScheme cs) {
    int spent = 0;
    int earned = 0;
    for (final e in _items) {
      if (e.delta < 0) {
        spent += -e.delta;
      } else {
        earned += e.delta;
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceBright,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: _summaryCell(
                cs,
                label: '一周支出',
                value: '$spent 币',
                color: spent > 0 ? cs.error : cs.onSurfaceVariant,
              ),
            ),
            Container(
              width: 1,
              height: 28,
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
            Expanded(
              child: _summaryCell(
                cs,
                label: '一周收入',
                value: '$earned 币',
                color: earned > 0 ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCell(
    ColorScheme cs, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
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
            income ? Icons.south_west_rounded : Icons.north_east_rounded,
            size: 20,
            color: income ? cs.primary : cs.error,
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
            income ? '+${item.delta} 币' : '${item.delta} 币',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: income ? cs.primary : cs.error,
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
