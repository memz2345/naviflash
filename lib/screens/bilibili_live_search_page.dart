                                             
  
                                       
                                                              
                             
                                       
                                
import 'package:flutter/material.dart';

import 'package:naviflash/widgets/expressive_app_bar.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_live_room_page.dart';
import 'package:naviflash/screens/bilibili_user_space_page_v2.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/live_room_grid.dart';
import 'package:naviflash/widgets/navi_spring_physics.dart';
import 'package:naviflash/widgets/page_loading.dart';

class BilibiliLiveSearchPage extends StatefulWidget {
  const BilibiliLiveSearchPage({super.key});

  @override
  State<BilibiliLiveSearchPage> createState() => _BilibiliLiveSearchPageState();
}

class _BilibiliLiveSearchPageState extends State<BilibiliLiveSearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _input = TextEditingController();
  late final TabController _tab = TabController(length: 2, vsync: this);

  final List<LiveSearchRoomItem> _rooms = [];
  final List<LiveSearchUserItem> _users = [];
  final ScrollController _roomScroll = ScrollController();
  final ScrollController _userScroll = ScrollController();

  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  String _keyword = '';
  int _page = 1;

                                            
  bool _hasMore = false;

  bool get _isZh => Localizations.localeOf(context).languageCode == 'zh';

  @override
  void initState() {
    super.initState();
    _roomScroll.addListener(_onScroll);
    _userScroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _roomScroll
      ..removeListener(_onScroll)
      ..dispose();
    _userScroll
      ..removeListener(_onScroll)
      ..dispose();
    _input.dispose();
    _tab.dispose();
    super.dispose();
  }

  void _onScroll() {
    final c = _tab.index == 0 ? _roomScroll : _userScroll;
    if (!c.hasClients) return;
    if (c.position.pixels >= c.position.maxScrollExtent - 320) _loadMore();
  }

  Future<void> _submit(String value) async {
    final kw = value.trim();
    if (kw.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _keyword = kw;
      _page = 1;
      _rooms.clear();
      _users.clear();
      _loading = true;
      _error = null;
      _hasMore = false;
    });
    await _load();
  }

  Future<void> _load() async {
    final r = await BilibiliLiveService.searchLive(
      keyword: _keyword,
      page: _page,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      if (r.err != null) {
        _error = r.err;
        return;
      }
      _error = null;
      final seenRooms = _rooms.map((e) => e.roomId).toSet();
      for (final e in r.rooms) {
        if (seenRooms.add(e.roomId)) _rooms.add(e);
      }
      final seenUsers = _users.map((e) => e.uname).toSet();
      for (final e in r.users) {
        if (seenUsers.add(e.uname)) _users.add(e);
      }
      _hasMore = r.rooms.length >= 20 || r.users.length >= 20;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading || _keyword.isEmpty) return;
    setState(() => _loadingMore = true);
    _page += 1;
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
          padding: const EdgeInsets.only(right: 8),
          child: TextField(
            controller: _input,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: _submit,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: _isZh ? '搜索房间或主播' : 'Search rooms or streamers',
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
                          _rooms.clear();
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
        bottom: TabBar(
          controller: _tab,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: _isZh ? '直播间' : 'Rooms'),
            Tab(text: _isZh ? '主播' : 'Streamers'),
          ],
        ),
      ),
      body: naviTabBarView(
        controller: _tab,
        children: [_buildRooms(cs), _buildUsers(cs)],
      ),
    );
  }

  Widget _buildRooms(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _rooms.isEmpty,
    )) {
      return const PageLoadingIndicator();
    }
    if (_keyword.isEmpty) return _hint(cs, Icons.live_tv_outlined, _isZh ? '输入关键词搜索直播间' : 'Search live rooms');
    if (_error != null) return _errorView(cs, l10n);
    if (_rooms.isEmpty) {
      return _hint(cs, Icons.search_off_outlined, _isZh ? '没有找到相关直播间' : 'No rooms found');
    }
    final width = MediaQuery.of(context).size.width;
    final columns = (width / 200).floor().clamp(2, 6);
    return GridView.builder(
      controller: _roomScroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.86,
      ),
      itemCount: _rooms.length + 1,
      itemBuilder: (context, index) {
        if (index >= _rooms.length) return _footer(cs, l10n);
        return LiveRoomCard(item: _rooms[index].toRoomItem());
      },
    );
  }

  Widget _buildUsers(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _users.isEmpty,
    )) {
      return const PageLoadingIndicator();
    }
    if (_keyword.isEmpty) {
      return _hint(cs, Icons.person_search_outlined, _isZh ? '输入关键词搜索主播' : 'Search streamers');
    }
    if (_error != null) return _errorView(cs, l10n);
    if (_users.isEmpty) {
      return _hint(cs, Icons.search_off_outlined, _isZh ? '没有找到相关主播' : 'No streamers found');
    }
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    return ListView.separated(
      controller: _userScroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      itemCount: _users.length + 1,
      separatorBuilder: (_, _) => const SizedBox.shrink(),
      itemBuilder: (context, index) {
        if (index >= _users.length) return _footer(cs, l10n);
        final u = _users[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: ClipOval(
            child: SizedBox(
              width: 46,
              height: 46,
              child: u.face.isNotEmpty
                  ? Image(
                      image: NetworkImage(u.face, headers: headers),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.person_outline,
                          size: 22,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        Icons.person_outline,
                        size: 22,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  u.uname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (u.living) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _isZh ? '直播中' : 'LIVE',
                    style: TextStyle(fontSize: 10, color: cs.primary),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            [
              if (u.areaName.isNotEmpty) u.areaName,
              if (u.fans > 0) '${_formatFans(u.fans)}${_isZh ? '粉丝' : ' fans'}',
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          onTap: () {
            if (u.living && u.roomId > 0) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BilibiliLiveRoomPage(roomId: u.roomId),
                ),
              );
              return;
            }
            if (u.mid > 0) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BilibiliUserSpacePage(mid: u.mid),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _footer(ColorScheme cs, AppLocalizations l10n) {
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

  Widget _errorView(ColorScheme cs, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
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

  Widget _hint(ColorScheme cs, IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: cs.onSurface.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _formatFans(int v) {
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(1)}万';
    return '$v';
  }
}
