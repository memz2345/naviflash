                                               
  
                                           
                                                
                                                              
                                            
                                                      
                                    
import 'package:flutter/material.dart';

import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/src/loading_indicator_m3e.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/load_retry_pill.dart';
import 'package:naviflash/widgets/standard_list_page.dart';

           
class _PrivacyItem {
            
  final String key;
  final String zh;
  final String en;

                                         
  final bool reverse;

                 
  int value;

  _PrivacyItem({
    required this.key,
    required this.zh,
    required this.en,
    this.reverse = false,
  }) : value = 0;

                 
  bool get on => reverse ? value == 0 : value == 1;

                       
  int serverValueOf(bool on) {
    if (reverse) return on ? 0 : 1;
    return on ? 1 : 0;
  }
}

class SpacePrivacySettingsPage extends StatefulWidget {
  const SpacePrivacySettingsPage({super.key});

  @override
  State<SpacePrivacySettingsPage> createState() =>
      _SpacePrivacySettingsPageState();
}

class _SpacePrivacySettingsPageState extends State<SpacePrivacySettingsPage> {
  late final List<List<_PrivacyItem>> _groups;
  bool _loading = true;
  String? _error;

                            
  final Set<String> _busy = {};

  bool get _isZh => Localizations.localeOf(context).languageCode == 'zh';

  @override
  void initState() {
    super.initState();
    _groups = [
      [
        _PrivacyItem(key: 'fav_video', zh: '公开我的收藏', en: 'Show my favorites'),
        _PrivacyItem(key: 'bangumi', zh: '公开我的追番追剧', en: 'Show my followed anime/TV'),
        _PrivacyItem(key: 'comic', zh: '公开我的追漫', en: 'Show my followed manga'),
        _PrivacyItem(key: 'coins_video', zh: '公开最近投币的视频', en: 'Show recently coined videos'),
        _PrivacyItem(key: 'likes_video', zh: '公开最近点赞的视频', en: 'Show recently liked videos'),
        _PrivacyItem(key: 'played_game', zh: '公开最近玩过的游戏', en: 'Show recently played games'),
        _PrivacyItem(key: 'dress_up', zh: '公开拥有的粉丝装扮', en: 'Show my fan dress-up'),
        _PrivacyItem(
          key: 'disable_following',
          zh: '公开我的关注列表',
          en: 'Show my following list',
          reverse: true,
        ),
        _PrivacyItem(
          key: 'disable_show_fans',
          zh: '公开我的粉丝列表',
          en: 'Show my fans list',
          reverse: true,
        ),
      ],
      [
        _PrivacyItem(
          key: 'close_space_medal',
          zh: '公开佩戴的粉丝勋章',
          en: 'Show my worn fan medal',
          reverse: true,
        ),
        _PrivacyItem(
          key: 'only_show_wearing',
          zh: '勋章墙公开显示所有粉丝勋章',
          en: 'Show all fan medals on medal wall',
          reverse: true,
        ),
        _PrivacyItem(
          key: 'disable_show_school',
          zh: '公开学校信息',
          en: 'Show my school info',
          reverse: true,
        ),
      ],
      [
        _PrivacyItem(
          key: 'live_playback',
          zh: '投稿视频列表中展现直播回放',
          en: 'Show live replays in uploads',
        ),
        _PrivacyItem(
          key: 'charge_video',
          zh: '投稿视频列表中展现包月充电专属视频',
          en: 'Show membership-only videos in uploads',
        ),
        _PrivacyItem(
          key: 'lesson_video',
          zh: '投稿视频列表中展现课堂视频',
          en: 'Show course videos in uploads',
        ),
      ],
    ];
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final privacy = await BilibiliUserSpaceService.fetchSpacePrivacy();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (privacy == null) {
        _error =
            BilibiliUserSpaceService.lastErrorDetail ??
            (_isZh ? '读取失败' : 'Failed to load');
        return;
      }
      for (final group in _groups) {
        for (final item in group) {
          item.value = privacy[item.key] ?? 0;
        }
      }
    });
  }

  Future<void> _toggle(_PrivacyItem item, bool on) async {
    if (_busy.contains(item.key)) return;
    final old = item.value;
    final next = item.serverValueOf(on);
    setState(() {
      _busy.add(item.key);
      item.value = next;
    });
    final ok = await BilibiliUserSpaceService.saveSpacePrivacyItem(
      item.key,
      next,
    );
    if (!mounted) return;
    setState(() {
      _busy.remove(item.key);
      if (!ok) item.value = old;
    });
    if (!ok) {
      showAppToast(
        context,
        _isZh ? '保存失败，请稍后重试' : 'Failed to save',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
                                          
                               
    return StandardListScaffold(
      topBar: StandardListTopBar(
        title: _isZh ? '空间隐私设置' : 'Space privacy',
        showBack: true,
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) return const Center(child: LoadingIndicatorM3E());
    if (_error != null) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: LoadRetryPill(onRetry: _load),
          ),
        ],
      );
    }
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        topBarSpaceSliver(kStdTopBarHeight),
        for (final group in _groups)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: cs.surfaceContainerHigh.withValues(alpha: 0.55),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < group.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: cs.outlineVariant.withValues(alpha: 0.25),
                          ),
                        _buildTile(cs, group[i]),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        bottomSpaceSliver(context),
      ],
    );
  }

  Widget _buildTile(ColorScheme cs, _PrivacyItem item) {
    final busy = _busy.contains(item.key);
    return SwitchListTile(
      value: item.on,
      onChanged: busy ? null : (v) => _toggle(item, v),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      secondary: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      title: Text(
        _isZh ? item.zh : item.en,
        style: TextStyle(fontSize: 14, color: cs.onSurface),
      ),
    );
  }
}
