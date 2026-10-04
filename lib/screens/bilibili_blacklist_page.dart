                                           
  
                                        
                                            
                                  
                                                    
                                     
                                             
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_blacklist_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/frosted_page_bar.dart';
import 'package:naviflash/widgets/ios_backdrop.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/page_loading.dart';

           
class BilibiliBlacklistPage extends StatefulWidget {
  const BilibiliBlacklistPage({super.key});

  @override
  State<BilibiliBlacklistPage> createState() => _BilibiliBlacklistPageState();
}

class _BilibiliBlacklistPageState extends State<BilibiliBlacklistPage> {
  final ScrollController _scrollController = ScrollController();
  final List<BiliBlackUser> _users = [];
  int _pn = 1;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;

                                
  final Set<int> _unblocking = {};

  bool get _isZh => Localizations.localeOf(context).languageCode == 'zh';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final p = _scrollController.position;
    if (p.pixels >= p.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    final page = await BilibiliBlacklistService.instance.fetchPage(pn: _pn);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      if (page.err != null) {
        _error = page.err;
        return;
      }
      _error = null;
                                      
                              
      if (_pn == 1) {
        _users
          ..clear()
          ..addAll(page.users);
      } else {
        final known = _users.map((u) => u.mid).toSet();
        for (final u in page.users) {
          if (known.add(u.mid)) _users.add(u);
        }
      }
      _total = page.total;
      _hasMore = page.users.isNotEmpty && _users.length < page.total;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    _pn += 1;
    await _load();
  }

  Future<void> _unblock(int index) async {
    final user = _users[index];
    if (_unblocking.contains(user.mid)) return;
    final displayName = user.uname.isEmpty ? '用户${user.mid}' : user.uname;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isZh ? '取消拉黑' : 'Unblock'),
        content: Text(
          _isZh
              ? '确定将「$displayName」移出黑名单吗？'
              : 'Remove "$displayName" from blacklist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_isZh ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_isZh ? '确定' : 'OK'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

                          
    setState(() => _unblocking.add(user.mid));
    final result = await BilibiliBlacklistService.instance.unblock(user.mid);
    if (!mounted) return;
    setState(() {
      _unblocking.remove(user.mid);
      if (result.ok) {
        final i = _users.indexWhere((u) => u.mid == user.mid);
        if (i >= 0) {
          _users.removeAt(i);
          _total = _total > 0 ? _total - 1 : 0;
        }
      }
    });
    if (result.ok) {
      HapticFeedback.lightImpact();
      showAppToast(context, _isZh ? '已取消拉黑' : 'Unblocked');
    } else {
      showAppToast(context, result.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loggedIn = BilibiliAccountService.instance.isLoggedIn;

                                           
    final scaffold = Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer, contentStyle: true),
          SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: !loggedIn
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                            top: kFrostedPageBarHeight,
                          ),
                          children: [
                            const SizedBox(height: 100),
                            Icon(
                              Icons.lock_outline,
                              size: 48,
                              color: cs.onSurface.withValues(alpha: 0.25),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                _isZh
                                    ? '还没有登录，登录后才能管理黑名单'
                                    : 'Sign in to manage blacklist',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: FilledButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const BilibiliLoginScreen(),
                                  ),
                                ),
                                icon: const Icon(Icons.login, size: 18),
                                label: Text(_isZh ? '去登录' : 'Sign in'),
                              ),
                            ),
                          ],
                        )
                      : AppRefreshIndicator(
                          displacement: kFrostedPageBarHeight + 10,
                          onRefresh: () async {
                            _pn = 1;
                                                                 
                            setState(() => _hasMore = false);
                            await _load();
                          },
                          child: _buildList(cs),
                        ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: FrostedPageBar(
                    title: _isZh ? '黑名单管理' : 'Blacklist',
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

  Widget _buildList(ColorScheme cs) {
    if (shouldShowFullScreenLoading(loading: _loading, isEmpty: _users.isEmpty)) {
      return const PageLoadingIndicator();
    }
    if (_error != null && _users.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: kFrostedPageBarHeight),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: FilledButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _load();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(_isZh ? '重试' : 'Retry'),
            ),
          ),
        ],
      );
    }
    if (_users.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: kFrostedPageBarHeight),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.block_outlined,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _isZh ? '黑名单是空的' : 'Blacklist is empty',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        0,
        kFrostedPageBarHeight + 4,
        0,
        MediaQuery.of(context).padding.bottom + 32,
      ),
      itemCount: _users.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
                     
        if (index == _users.length) {
          if (_loadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: LoadingIndicatorM3E()),
            );
          }
          if (!_hasMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  _isZh ? '已全部加载' : 'All loaded',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            );
          }
          return const SizedBox(height: 8);
        }
        final user = _users[index];
        final unblocking = _unblocking.contains(user.mid);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: ClipOval(
            child: SizedBox(
              width: 44,
              height: 44,
              child: user.face.isNotEmpty
                  ? Image(
                      image: CachedImageProvider(
                        BilibiliUserSpaceService.avatarUrl(user.face),
                        headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                            ? null
                            : NetworkSettingsService.instance.apiHeaders,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(cs),
                    )
                  : _placeholder(cs),
            ),
          ),
          title: Text(
            user.uname.isEmpty ? '用户${user.mid}' : user.uname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              [
                if (user.mtime > 0) _formatTime(user.mtime),
                if (user.sign.isNotEmpty) user.sign,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          trailing: unblocking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  onPressed: () => _unblock(index),
                  child: Text(
                    _isZh ? '取消拉黑' : 'Unblock',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
        );
      },
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
    color: cs.surfaceContainerHighest,
    child: Icon(Icons.person_outline, size: 22, color: cs.onSurfaceVariant),
  );

                          
  static String _formatTime(int seconds) {
    final d = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}
