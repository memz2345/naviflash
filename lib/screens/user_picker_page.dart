import 'dart:async';

import 'package:flutter/material.dart';

import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/widgets/page_loading.dart';

                  
typedef PickedUser = ({int mid, String name});

                            
   
                                        
                                       
                                        
                                                    
class UserPickerPage extends StatefulWidget {
  const UserPickerPage({super.key, this.multiSelect = false});

                                 
  final bool multiSelect;

  @override
  State<UserPickerPage> createState() => _UserPickerPageState();
}

class _UserPickerPageState extends State<UserPickerPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<BiliRelationUser> _users = [];
  final Set<int> _selectedMids = <int>{};
  final Map<int, String> _selectedNames = <int, String>{};

  Timer? _debounce;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  String _keyword = '';
  int _page = 1;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    unawaited(_load(refresh: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final position = _scrollCtrl.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      unawaited(_load());
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final keyword = value.trim();
      if (keyword == _keyword) return;
      _keyword = keyword;
      unawaited(_load(refresh: true));
    });
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading || _loadingMore) return;
    if (!refresh && !_hasMore) return;

    setState(() {
      if (refresh) {
        _loading = _users.isEmpty;
        _error = null;
        _page = 1;
        _hasMore = true;
      } else {
        _loadingMore = true;
      }
    });

    final mid = BilibiliAccountService.instance.mid;
    final keyword = _keyword;
    BiliRelationListPage? result;
    try {
      result = keyword.isEmpty
          ? await BilibiliUserSpaceService.fetchFollowings(mid: mid, pn: _page)
          : await BilibiliUserSpaceService.searchFollowings(
              name: keyword,
              pn: _page,
            );
    } catch (_) {
      result = null;
    }
    if (!mounted) return;

    setState(() {
      _loading = false;
      _loadingMore = false;
      if (result == null) {
        _error = L10n.current.userPickerLoadFailed;
        if (refresh) _users.clear();
        return;
      }
      if (refresh) _users.clear();
      final seen = _users.map((u) => u.mid).toSet();
      for (final user in result.users) {
        if (seen.add(user.mid)) _users.add(user);
      }
                                     
      _hasMore = result.users.length >= _pageSize;
      if (_hasMore) _page++;
    });
  }

  void _toggleSelect(BiliRelationUser user) {
    if (!widget.multiSelect) {
      Navigator.of(context).pop(<PickedUser>[
        (mid: user.mid, name: user.uname),
      ]);
      return;
    }
    setState(() {
      if (_selectedMids.contains(user.mid)) {
        _selectedMids.remove(user.mid);
        _selectedNames.remove(user.mid);
      } else {
        _selectedMids.add(user.mid);
        _selectedNames[user.mid] = user.uname;
      }
    });
  }

  void _confirmMulti() {
    Navigator.of(context).pop(<PickedUser>[
      for (final mid in _selectedMids)
        (mid: mid, name: _selectedNames[mid] ?? ''),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.current.userPickerTitle),
        actions: [
          if (widget.multiSelect && _selectedMids.isNotEmpty)
            TextButton(
              onPressed: _confirmMulti,
              child: Text(
                '${L10n.current.userPickerDone} (${_selectedMids.length})',
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: L10n.current.userPickerSearchHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final cs = Theme.of(context).colorScheme;
    if (shouldShowFullScreenLoading(
      loading: _loading,
      isEmpty: _users.isEmpty,
    )) {
      return const PageLoadingIndicator();
    }
    if (_users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _error ?? L10n.current.userPickerEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      itemCount: _users.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _users.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: SizedBox(
              width: 28,
              height: 28,
              child: LoadingIndicatorM3E(),
            ),
          );
        }
        final user = _users[index];
        final selected = _selectedMids.contains(user.mid);
        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: cs.surfaceContainerHighest,
            backgroundImage: user.face.isEmpty
                ? null
                : CachedImageProvider(user.face),
          ),
          title: Text(
            user.uname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: user.sign.isEmpty
              ? null
              : Text(
                  user.sign,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: widget.multiSelect && selected
              ? Icon(Icons.check_circle, color: cs.primary)
              : null,
          onTap: () => _toggleSelect(user),
        );
      },
    );
  }
}
