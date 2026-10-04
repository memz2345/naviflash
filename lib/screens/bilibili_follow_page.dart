                                        
  
                                                    
                                                
                                             
                                                    
                                           
                                              
                                             

import 'package:naviflash/utils/json_decode.dart';
import 'package:flutter/material.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/screens/bilibili_user_space_page_v2.dart';
import 'package:naviflash/screens/follow_search_page.dart';
import 'package:naviflash/screens/follow_tag_manage_page.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/follow_group_assign_sheet.dart';
import 'package:naviflash/widgets/follow_user_tile.dart';
import 'package:naviflash/widgets/navi_spring_physics.dart';
import 'package:naviflash/widgets/page_loading.dart';

                                             
                                               
                                                 
                                 
                                                     
                                          
enum BiliFollowCategory { all, special, mutual, normal }

                                   
                                             
BiliFollowCategory classifyFollowUser({
  required int attribute,
  required bool special,
}) {
  if (special) return BiliFollowCategory.special;
  if (attribute == 6) return BiliFollowCategory.mutual;
  return BiliFollowCategory.normal;
}

                                     
Map<BiliFollowCategory, int> countFollowCategories(
  List<BiliRelationUser> users,
  Set<int> specialMids,
) {
  final counts = <BiliFollowCategory, int>{
    for (final c in BiliFollowCategory.values) c: 0,
  };
  counts[BiliFollowCategory.all] = users.length;
  for (final u in users) {
    final c = classifyFollowUser(
      attribute: u.attribute,
      special: specialMids.contains(u.mid),
    );
    counts[c] = (counts[c] ?? 0) + 1;
  }
  return counts;
}

                           
bool matchesFollowCategory(
  BiliRelationUser user,
  BiliFollowCategory category,
  Set<int> specialMids,
) {
  if (category == BiliFollowCategory.all) return true;
  return classifyFollowUser(
        attribute: user.attribute,
        special: specialMids.contains(user.mid),
      ) ==
      category;
}

                                           
                         
                                                                    
                                                 
                                                              
                             
                                           

abstract final class _FollowRelationApi {
                                              
                                        
  static Future<List<BiliRelationUser>?> fetchAllFollowings(
    int mid, {
    int maxPages = 40,
  }) async {
    final out = <BiliRelationUser>[];
    var total = 0;
    try {
      for (var pn = 1; pn <= maxPages; pn++) {
        final client = await NetworkSettingsService.instance.getApiClient();
        final uri = Uri.parse('https://api.bilibili.com/x/relation/followings')
            .replace(
              queryParameters: {
                'vmid': mid.toString(),
                'pn': pn.toString(),
                'ps': '50',
                'order': 'desc',
                'order_type': '',
              },
            );
        final resp = await client
            .get(
              uri,
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                    'AppleWebKit/537.36 (KHTML, like Gecko) '
                    'Chrome/120.0.0.0 Safari/537.36',
                'Referer': 'https://space.bilibili.com',
                'Cookie': biliLoginCookie() ?? '',
                ...NetworkSettingsService.instance.apiHeaders,
              },
            )
            .timeout(const Duration(seconds: 15));
        if (resp.statusCode != 200) return out.isEmpty ? null : out;
        final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
        if (json is! Map<String, dynamic> || biliToInt(json['code']) != 0) {
          return out.isEmpty ? null : out;
        }
        final data = biliAsMap(json['data']);
        final list = biliAsList<Map<String, dynamic>>(data?['list']);
        total = biliToInt(data?['total']);
        out.addAll(list.map(BiliRelationUser.fromJson));
        if (list.isEmpty || out.length >= total) break;
      }
      return out;
    } catch (e) {
      debugPrint('[FollowPage] 全量关注列表拉取失败: $e');
      return out.isEmpty ? null : out;
    }
  }

                                                       
                             
  static Future<Set<int>?> fetchSpecialMids() async {
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            Uri.parse('https://api.bilibili.com/x/relation/tag/special'),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                  'AppleWebKit/537.36 (KHTML, like Gecko) '
                  'Chrome/120.0.0.0 Safari/537.36',
              'Referer': 'https://space.bilibili.com',
              'Cookie': biliLoginCookie() ?? '',
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      if (json is! Map<String, dynamic> || biliToInt(json['code']) != 0) {
        return null;
      }
      return biliAsList(
        json['data'],
      ).map(biliToInt).where((m) => m > 0).toSet();
    } catch (e) {
      debugPrint('[FollowPage] 特别关注列表拉取失败: $e');
      return null;
    }
  }
}

               
class BilibiliFollowPage extends StatefulWidget {
                           
  final int mid;

                    
  final String name;

                                  
  final bool initialFans;

  const BilibiliFollowPage({
    super.key,
    required this.mid,
    this.name = '',
    this.initialFans = false,
  });

  @override
  State<BilibiliFollowPage> createState() => _BilibiliFollowPageState();
}

class _BilibiliFollowPageState extends State<BilibiliFollowPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final bool _isSelf;

  @override
  void initState() {
    super.initState();
    _isSelf = _isSelfFn(widget.mid);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialFans ? 1 : 0,
    );
  }

                                      
  bool _isSelfFn(int mid) =>
      BilibiliAccountService.instance.isLoggedIn &&
      BilibiliAccountService.instance.mid == mid;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final title = widget.name.isEmpty
        ? AppLocalizations.of(context).userSpaceTitle
        : widget.name;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLow,
        scrolledUnderElevation: 0,
        title: Text(title, overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: isZh ? '关注' : 'Following'),
            Tab(text: isZh ? '粉丝' : 'Fans'),
          ],
        ),
      ),
      body: naviTabBarView(
        controller: _tabController,
        children: [
          _FollowingTab(mid: widget.mid, isOwner: _isSelf),
          _FollowListView(
            mid: widget.mid,
            mode: _FollowListMode.fans,
            isOwner: _isSelf,
          ),
        ],
      ),
    );
  }
}

enum _FollowListMode { following, fans }

                                           
                         
                                           

class _FollowingTab extends StatefulWidget {
  final int mid;
  final bool isOwner;

  const _FollowingTab({required this.mid, required this.isOwner});

  @override
  State<_FollowingTab> createState() => _FollowingTabState();
}

class _FollowingTabState extends State<_FollowingTab> {
  List<BiliFollowTag> _tags = const [];
  int _tagid = 0;

                                          
  int _listKey = 0;

                                         
  BiliFollowCategory _category = BiliFollowCategory.all;

                                       
  List<BiliRelationUser> _scannedUsers = const <BiliRelationUser>[];
  Set<int> _specialMids = const <int>{};
  bool _scanDone = false;
  Map<BiliFollowCategory, int> _counts = const <BiliFollowCategory, int>{};

  bool get _isZh => Localizations.localeOf(context).languageCode == 'zh';

  @override
  void initState() {
    super.initState();
    if (widget.isOwner) {
      _loadTags();
      _scanCategories();
    }
  }

  Future<void> _loadTags() async {
    final tags = await BilibiliUserSpaceService.fetchFollowTags();
    if (!mounted || tags == null) return;
    setState(() => _tags = tags);
  }

                                      
                                       
  Future<void> _scanCategories() async {
    final results = await Future.wait([
      _FollowRelationApi.fetchAllFollowings(widget.mid),
      _FollowRelationApi.fetchSpecialMids(),
    ]);
    final users = results[0] as List<BiliRelationUser>?;
    final special = results[1] as Set<int>?;
    if (!mounted || users == null) return;
    setState(() {
      _scannedUsers = users;
      _specialMids = special ?? const <int>{};
      _counts = countFollowCategories(users, _specialMids);
      _scanDone = true;
    });
  }

  void _selectCategory(BiliFollowCategory c) {
    if (_category == c) return;
    setState(() {
      _category = c;
                                           
      if (c != BiliFollowCategory.all) _tagid = 0;
      _listKey++;
    });
  }

  Future<void> _openManage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FollowTagManagePage()));
                               
    if (mounted) {
      setState(() {
        _tagid = 0;
        _listKey++;
      });
      await _loadTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOwner) {
      return _FollowListView(
        mid: widget.mid,
        mode: _FollowListMode.following,
        isOwner: false,
      );
    }
    return Column(
      children: [
        _buildToolBar(),
        Expanded(
          child: _FollowListView(
            key: ValueKey<int>(_listKey),
            mid: widget.mid,
            mode: _FollowListMode.following,
            isOwner: true,
            tagid: _tagid,
            category: _category,
            scannedUsers: _scanDone ? _scannedUsers : null,
            specialMids: _specialMids,
          ),
        ),
      ],
    );
  }

  Widget _buildToolBar() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                 
          InkWell(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FollowSearchPage())),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isZh ? '搜索我关注的 UP 主' : 'Search who I follow',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
                                                  
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in BiliFollowCategory.values)
                  _categoryChip(c, _categoryLabel(c)),
              ],
            ),
          ),
          const SizedBox(height: 8),
                  
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip(0, _isZh ? '全部' : 'All'),
                for (final tag in _tags) _chip(tag.tagid, tag.name),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: ActionChip(
                    avatar: Icon(
                      Icons.settings_outlined,
                      size: 15,
                      color: cs.primary,
                    ),
                    label: Text(_isZh ? '管理' : 'Manage'),
                    visualDensity: VisualDensity.compact,
                    onPressed: _openManage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(BiliFollowCategory c) {
    final base = switch (c) {
      BiliFollowCategory.all => _isZh ? '全部' : 'All',
      BiliFollowCategory.special => _isZh ? '特别关注' : 'Special',
      BiliFollowCategory.mutual => _isZh ? '互相关注' : 'Mutual',
      BiliFollowCategory.normal => _isZh ? '默默关注' : 'Silent',
    };
    final n = _counts[c];
    return n == null ? base : '$base $n';
  }

  Widget _categoryChip(BiliFollowCategory c, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _category == c,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => _selectCategory(c),
      ),
    );
  }

  Widget _chip(int tagid, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _tagid == tagid,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => setState(() {
          _tagid = tagid;
                                                 
          _category = BiliFollowCategory.all;
          _listKey++;
        }),
      ),
    );
  }
}

                                           
                         
                                           

                          
class _FollowListView extends StatefulWidget {
  final int mid;
  final _FollowListMode mode;
  final bool isOwner;

                                
  final int tagid;

                               
  final BiliFollowCategory category;

                                                     
  final List<BiliRelationUser>? scannedUsers;

                                      
  final Set<int> specialMids;

  const _FollowListView({
    super.key,
    required this.mid,
    required this.mode,
    required this.isOwner,
    this.tagid = 0,
    this.category = BiliFollowCategory.all,
    this.scannedUsers,
    this.specialMids = const <int>{},
  });

  @override
  State<_FollowListView> createState() => _FollowListViewState();
}

class _FollowListViewState extends State<_FollowListView>
    with AutomaticKeepAliveClientMixin {
  final List<BiliRelationUser> _users = [];
  final ScrollController _scrollController = ScrollController();
  int _pn = 1;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;
                              
  final Set<int> _removing = {};

  @override
  bool get wantKeepAlive => true;

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
                                            
    if (widget.mode == _FollowListMode.following &&
        widget.category != BiliFollowCategory.all) {
      await _loadByCategory();
      return;
    }
    final page = widget.mode == _FollowListMode.following
        ? await BilibiliUserSpaceService.fetchFollowings(
            mid: widget.mid,
            pn: _pn,
            tagid: widget.tagid,
          )
        : await BilibiliUserSpaceService.fetchFans(mid: widget.mid, pn: _pn);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      if (page == null) {
        _error = BilibiliUserSpaceService.lastErrorDetail;
        return;
      }
                                       
                                  
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

                                         
                                                                
                                 
  Future<void> _loadByCategory() async {
    var users = widget.scannedUsers;
    var special = widget.specialMids;
    if (users == null) {
      final results = await Future.wait([
        _FollowRelationApi.fetchAllFollowings(widget.mid),
        _FollowRelationApi.fetchSpecialMids(),
      ]);
      users = results[0] as List<BiliRelationUser>?;
      special = (results[1] as Set<int>?) ?? const <int>{};
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      if (users == null) {
        _error = BilibiliUserSpaceService.lastErrorDetail;
        return;
      }
      final filtered = users
          .where((u) => matchesFollowCategory(u, widget.category, special))
          .toList();
      _users
        ..clear()
        ..addAll(filtered);
      _total = filtered.length;
      _hasMore = false;                   
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    _pn += 1;
    await _load();
  }

  Future<void> _removeFan(int index) async {
    final user = _users[index];
    if (_removing.contains(user.mid)) return;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    setState(() => _removing.add(user.mid));
    final ok = await BilibiliUserSpaceService.modifyRelationAct(
      mid: user.mid,
      act: 7,        
    );
    if (!mounted) return;
    setState(() {
      _removing.remove(user.mid);
      if (ok) {
        _users.removeAt(index);
        _total = _total > 0 ? _total - 1 : 0;
      }
    });
    if (ok) {
      HapticFeedback.lightImpact();
      showAppToast(context, isZh ? '已移除粉丝' : 'Fan removed');
    } else {
      showAppToast(
        context,
        isZh ? '操作失败，请稍后重试' : 'Operation failed',
        error: true,
      );
    }
  }

                                            
                                                         
  Future<void> _moveToTag(BiliRelationUser user) async {
    if (!mounted) return;
    await showFollowGroupAssignSheet(context, user: user);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _users.isEmpty,
    )) {
      return const PageLoadingIndicator();
    }
    if (_error != null && _users.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              _error ?? l10n.userSpaceLoadFailed,
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
              label: Text(l10n.scanRetry),
            ),
          ),
        ],
      );
    }
    if (_users.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.people_outline,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              widget.mode == _FollowListMode.following
                  ? (isZh ? '还没有关注任何人' : 'No following yet')
                  : (isZh ? '还没有粉丝' : 'No fans yet'),
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    }
    return AppRefreshIndicator(
      onRefresh: () async {
        _pn = 1;
                                             
                                                 
        setState(() => _hasMore = false);
        await _load();
      },
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
                                       
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        padding: EdgeInsets.fromLTRB(
          0,
          4,
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
            showRemoveFan:
                widget.isOwner && widget.mode == _FollowListMode.fans,
            removing: _removing.contains(user.mid),
            onRemoveFan: () => _removeFan(index),
            showGroup:
                widget.isOwner && widget.mode == _FollowListMode.following,
            onManageGroup: () => _moveToTag(user),
            onOpenSpace: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BilibiliUserSpacePage(mid: user.mid),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
