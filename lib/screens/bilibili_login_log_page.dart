                                           
  
                                     
                                               
                                 
                                              
                                 
                                         
import 'package:flutter/material.dart';

import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/services/bilibili_account_log_service.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/frosted_page_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/page_loading.dart';

                                      
const double _kTopBarHeight = 56.0;

class BilibiliLoginLogPage extends StatefulWidget {
  const BilibiliLoginLogPage({super.key});

  @override
  State<BilibiliLoginLogPage> createState() => _BilibiliLoginLogPageState();
}

class _BilibiliLoginLogPageState extends State<BilibiliLoginLogPage> {
  List<BiliLoginLogEntry> _items = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    final (:items, :err) = await BilibiliAccountLogService.fetchLoginLog();
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
                  child: FrostedPageBar(title: '登录记录'),
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
        icon: Icons.history_rounded,
        text: '登录后可以查看登录记录',
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
        icon: Icons.history_rounded,
        text: '最近一周没有登录记录',
        subText: '登录 IP / 地理位置流水会显示在这里',
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

  Widget _buildRow(ColorScheme cs, BiliLoginLogEntry item) {
    final time = item.timeAt.isEmpty && item.time > 0
        ? _fmtUnix(item.time)
        : item.timeAt;
    final meta = <String>[
      if (item.type.isNotEmpty) item.type,
      if (item.ip.isNotEmpty) 'IP ${item.ip}',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.public_rounded, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.geo.isEmpty ? '未知地点' : item.geo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  meta.isEmpty ? time : '$time · $meta',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtUnix(int ts) {
    final t = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
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
