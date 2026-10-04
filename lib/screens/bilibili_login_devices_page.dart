                                               
  
                                         
                                                                   
                                                      
                                              
                                 
                                      
                                               
                                   
import 'package:flutter/material.dart';

import 'package:naviflash/screens/bilibili_login_log_page.dart';
import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/services/bilibili_account_log_service.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/frosted_page_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/page_loading.dart';

                                      
const double _kTopBarHeight = 56.0;

class BilibiliLoginDevicesPage extends StatefulWidget {
  const BilibiliLoginDevicesPage({super.key});

  @override
  State<BilibiliLoginDevicesPage> createState() =>
      _BilibiliLoginDevicesPageState();
}

class _BilibiliLoginDevicesPageState extends State<BilibiliLoginDevicesPage> {
  List<BiliLoginDeviceEntry> _items = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    final (:items, :err) =
        await BilibiliAccountLogService.fetchLoginDevices();
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

  void _openLoginLog() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BilibiliLoginLogPage()),
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
                Align(
                  alignment: Alignment.topCenter,
                  child: FrostedPageBar(
                    title: '登录设备',
                    actions: [
                      IconButton(
                        tooltip: '登录记录',
                        icon: const Icon(Icons.history_rounded),
                        onPressed: _openLoginLog,
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

  Widget _buildBody(ColorScheme cs) {
    if (!BilibiliAccountLogService.isLoggedIn && _items.isEmpty && !_loading) {
      return _centeredState(
        cs,
        icon: Icons.devices_other_outlined,
        text: '登录后可以查看登录设备',
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
        icon: Icons.devices_other_outlined,
        text: '没有查到登录设备',
        subText: '下拉刷新重试，或稍后再来看',
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
              itemCount: _items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i == _items.length) return _buildLoginLogEntry(cs);
                return _buildRow(cs, _items[i]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(ColorScheme cs, BiliLoginDeviceEntry item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.devices_other_outlined,
            size: 22,
            color: item.isCurrentDevice ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.deviceName.isEmpty ? '未知设备' : item.deviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (item.isCurrentDevice) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '当前设备',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (item.source.isNotEmpty) item.source,
                    if (item.latestLoginAt.isNotEmpty)
                      '最近登录 ${item.latestLoginAt}',
                  ].join(' · '),
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

                                         
  Widget _buildLoginLogEntry(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceBright,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        leading: Icon(Icons.history_rounded, color: cs.primary),
        title: const Text('查看登录记录', style: TextStyle(fontSize: 14)),
        subtitle: Text(
          '最近一周的登录 IP / 地理位置流水',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        onTap: _openLoginLog,
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
