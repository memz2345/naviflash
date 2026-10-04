                                             
  
                            
                                                                             
                                                                    
                           
                                                                  
                                                                           
                                                         
                                                               
                                                
import 'package:naviflash/utils/json_decode.dart';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_api_helpers.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

                                             
Future<bool> showFollowGroupAssignSheet(
  BuildContext context, {
  required BiliRelationUser user,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _FollowGroupAssignSheet(user: user),
  );
  return result ?? false;
}

class _FollowGroupAssignSheet extends StatefulWidget {
  final BiliRelationUser user;

  const _FollowGroupAssignSheet({required this.user});

  @override
  State<_FollowGroupAssignSheet> createState() =>
      _FollowGroupAssignSheetState();
}

class _FollowGroupAssignSheetState extends State<_FollowGroupAssignSheet> {
  List<BiliFollowTag> _tags = const [];

                                        
  Set<int> _memberOf = const <int>{};

  bool _loading = true;
  String? _error;

                             
  final Set<int> _pending = {};

  bool get _isZh => Localizations.localeOf(context).languageCode == 'zh';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final results = await Future.wait([
      BilibiliUserSpaceService.fetchFollowTags(),
      _FollowTagApi.fetchUserTagIds(widget.user.mid),
    ]);
    final tags = results[0] as List<BiliFollowTag>?;
    final memberOf = results[1] as Set<int>?;
    if (!mounted) return;
    setState(() {
      if (tags == null || memberOf == null) {
        _error = _isZh ? '加载失败，请检查登录状态' : 'Failed to load';
      } else {
        _tags = tags;
        _memberOf = memberOf;
      }
      _loading = false;
    });
  }

  Future<void> _toggle(BiliFollowTag tag, bool wantIn) async {
    if (_pending.contains(tag.tagid)) return;
    setState(() => _pending.add(tag.tagid));
    final ok = wantIn
                    
        ? await _FollowTagApi.addUsersToTag(tag.tagid, widget.user.mid)
                                 
        : await _FollowTagApi.removeUserFromTag(tag.tagid, widget.user.mid);
    if (!mounted) return;
    setState(() {
      _pending.remove(tag.tagid);
      if (ok) {
        _memberOf = wantIn
            ? {..._memberOf, tag.tagid}
            : _memberOf.where((t) => t != tag.tagid).toSet();
      }
    });
    if (ok) {
      showAppToast(
        context,
        wantIn ? (_isZh ? '已加入分组' : 'Added') : (_isZh ? '已移出分组' : 'Removed'),
      );
    } else {
      showAppToast(
        context,
        _isZh ? '操作失败，请稍后重试' : 'Operation failed',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = widget.user.uname.isEmpty
        ? '用户${widget.user.mid}'
        : widget.user.uname;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Column(
                children: [
                  Text(
                    _isZh ? '设置分组' : 'Assign groups',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _buildBody(cs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error ?? '',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: _load,
              child: Text(_isZh ? '重试' : 'Retry'),
            ),
          ],
        ),
      );
    }
    if (_tags.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Text(
          _isZh ? '还没有自定义分组，先到「关注 → 管理」里建一个' : 'Create a group first',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        for (final tag in _tags)
          CheckboxListTile(
            value: _memberOf.contains(tag.tagid),
                            
            onChanged: _pending.contains(tag.tagid)
                ? null
                : (v) => _toggle(tag, v == true),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            title: Text(
              tag.name,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface,
                decoration: _pending.contains(tag.tagid)
                    ? TextDecoration.none
                    : null,
              ),
            ),
            secondary: _pending.contains(tag.tagid)
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isZh ? '${tag.count} 人' : '${tag.count}',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
          ),
      ],
    );
  }
}

                                           
                                 
                                           

abstract final class _FollowTagApi {
  static const String _apiBase = 'https://api.bilibili.com';

  static Map<String, String> _webHeaders() => {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://space.bilibili.com',
  };

                                                             
                                          
  static Future<Set<int>?> fetchUserTagIds(int fid) async {
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final uri = Uri.parse('$_apiBase/x/relation/tag/user').replace(
        queryParameters: {'fid': fid.toString()},
      );
      final resp = await client
          .get(
            uri,
            headers: {
              ..._webHeaders(),
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
      final data = biliAsMap(json['data']);
      if (data == null) return const <int>{};
      return data.keys
          .map((k) => int.tryParse(k) ?? 0)
          .where((t) => t > 0)
          .toSet();
    } catch (e) {
      debugPrint('[FollowGroupSheet] 查询用户分组失败: $e');
      return null;
    }
  }

                                                          
  static Future<bool> addUsersToTag(int tagid, int fid) async {
    return _post('$_apiBase/x/relation/tags/addUsers', {
      'fids': fid.toString(),
      'tagids': tagid.toString(),
    });
  }

                                                              
  static Future<bool> removeUserFromTag(int tagid, int fid) async {
    return _post('$_apiBase/x/relation/tags/moveUsers', {
      'beforeTagids': tagid.toString(),
      'afterTagids': '0',
      'fids': fid.toString(),
    });
  }

  static Future<bool> _post(String url, Map<String, String> fields) async {
    try {
      final rawCookie =
          biliLoginCookie(BiliCookieScope.interactions) ?? '';
      final csrf = biliExtractCsrf(rawCookie);
      if (csrf.isEmpty) return false;
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .post(
            Uri.parse(url),
            headers: {
              ..._webHeaders(),
              'Origin': 'https://space.bilibili.com',
              'Cookie': rawCookie,
              'Content-Type': 'application/x-www-form-urlencoded',
              ...NetworkSettingsService.instance.apiHeaders,
            },
            body: {...fields, 'csrf': csrf},
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return false;
      final json = await decodeJsonAsync(utf8.decode(resp.bodyBytes));
      return json is Map<String, dynamic> && biliToInt(json['code']) == 0;
    } catch (e) {
      debugPrint('[FollowGroupSheet] 分组操作失败: $e');
      return false;
    }
  }
}
