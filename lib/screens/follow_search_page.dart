                                      
  
                                                
                                                    
                                
import 'package:flutter/material.dart';

import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_user_space_page_v2.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/follow_user_tile.dart';
import 'package:naviflash/widgets/page_loading.dart';

class FollowSearchPage extends StatefulWidget {
  const FollowSearchPage({super.key});

  @override
  State<FollowSearchPage> createState() => _FollowSearchPageState();
}

class _FollowSearchPageState extends State<FollowSearchPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<BiliRelationUser> _users = [];
  int _pn = 1;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;

                               
  String _keyword = '';

  bool get _isZh => Localizations.localeOf(context).languageCode == 'zh';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _input.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.pixels >= p.maxScrollExtent - 300) _loadMore();
  }

  Future<void> _submit(String value) async {
    final kw = value.trim();
    if (kw.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _keyword = kw;
      _pn = 1;
      _users.clear();
      _loading = true;
      _error = null;
      _hasMore = false;
    });
    await _load();
  }

  Future<void> _load() async {
    final page = await BilibiliUserSpaceService.searchFollowings(
      name: _keyword,
      pn: _pn,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      if (page == null) {
        _error = BilibiliUserSpaceService.lastErrorDetail ?? '';
        return;
      }
      final known = _users.map((u) => u.mid).toSet();
      for (final u in page.users) {
        if (known.add(u.mid)) _users.add(u);
      }
      _hasMore = page.users.isNotEmpty && _users.length < page.total;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    _pn += 1;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLow,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextField(
            controller: _input,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: _submit,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: _isZh ? '搜索我关注的 UP 主' : 'Search who I follow',
              hintStyle: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              isDense: true,
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _input.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: _isZh ? '清空' : 'Clear',
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _input.clear();
                        setState(() {
                          _keyword = '';
                          _users.clear();
                          _error = null;
                        });
                      },
                    ),
            ),
          ),
        ),
        actions: [
          MorphIconButton(
            icon: Icons.search_rounded,
            tooltip: _isZh ? '搜索' : 'Search',
            transparent: true,
            onTap: () => _submit(_input.text),
          ),
        ],
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _users.isEmpty,
    )) {
      return const PageLoadingIndicator();
    }
    if (_keyword.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 44,
              color: cs.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 12),
            Text(
              _isZh ? '输入昵称搜索关注的人' : 'Type a name to search',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!.isEmpty ? l10n.userSpaceLoadFailed : _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => _submit(_keyword),
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 44,
              color: cs.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 12),
            Text(
              _isZh ? '没有找到匹配的关注' : 'No match',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: 4,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      itemCount: _users.length + 1,
      separatorBuilder: (_, _) => const SizedBox.shrink(),
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
                  l10n.searchAllLoaded,
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
        return FollowUserTile(
          user: user,
          onOpenSpace: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BilibiliUserSpacePage(mid: user.mid),
            ),
          ),
        );
      },
    );
  }
}
