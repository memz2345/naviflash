                                      
  
                                                    
                                       
                                                
                             
                                     
                                       
                                  
                                       
import 'package:flutter/material.dart';
import 'package:naviflash/screens/bilibili_coin_log_page.dart';
import 'package:naviflash/screens/bilibili_exp_log_page.dart';
import 'package:naviflash/screens/bilibili_favorites_page.dart';
import 'package:naviflash/screens/bilibili_login_devices_page.dart';
import 'package:naviflash/screens/bilibili_login_screen.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/screens/bilibili_watch_later_page.dart';
import 'package:naviflash/screens/my_cache_page.dart';
import 'package:naviflash/screens/bilibili_my_comments_page.dart';
import 'package:naviflash/screens/settings_split_screen.dart';
import 'package:naviflash/screens/space_privacy_settings_page.dart';
import 'package:naviflash/screens/watch_history_page.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/liquid_glass_bar_service.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/screens/bilibili_fav_topic_page.dart';
import 'package:naviflash/screens/bilibili_fav_note_page.dart';
import 'package:naviflash/screens/bilibili_bubble_page.dart';
import 'package:naviflash/screens/bilibili_match_page.dart';
import 'package:naviflash/screens/bilibili_opus_page.dart';
import 'package:naviflash/screens/bilibili_space_audio_page.dart';
import 'package:naviflash/screens/bilibili_shop_page.dart';
import 'package:naviflash/screens/bilibili_comic_page.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/message_center_entry.dart';
import 'package:naviflash/widgets/msg_views.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/mine_user_header.dart';
import 'package:naviflash/widgets/morph_card.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';
import 'package:naviflash/widgets/msg_feed_common.dart';

class BilibiliMinePage extends StatefulWidget {
                                            
  final bool embeddedInShell;

                                         
                                                    
                                           
  final Widget? topBarLeading;

  const BilibiliMinePage({
    super.key,
    this.embeddedInShell = false,
    this.topBarLeading,
  });

  @override
  State<BilibiliMinePage> createState() => _BilibiliMinePageState();
}

class _BilibiliMinePageState extends State<BilibiliMinePage>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<MineUserHeaderState> _headerKey =
      GlobalKey<MineUserHeaderState>();

  @override
  bool get wantKeepAlive => true;

  Future<void> _onRefresh() async {
    await _headerKey.currentState?.refresh();
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
  Future<void> _openMatch() async {
    final l10n = AppLocalizations.of(context);
    final raw = await _askId(l10n.inputIdTitle, l10n.inputIdHint);
    if (raw != null && raw.isNotEmpty) {
      final cid = int.tryParse(raw);
      if (cid != null) _open(BilibiliMatchPage(cid: cid));
    }
  }

  Future<void> _openBubble() async {
    final l10n = AppLocalizations.of(context);
    final raw = await _askId(l10n.inputIdTitle, l10n.inputIdHint);
    if (raw != null && raw.isNotEmpty) {
      _open(BilibiliBubblePage(tribeId: raw));
    }
  }

  Future<String?> _askId(String title, String hint) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, controller.text.trim()),
            child: Text(AppLocalizations.of(context).confirm),
          ),
        ],
      ),
    );
    return result;
  }

  void _openSpaceOrLogin() {
    final account = BilibiliAccountService.instance;
    if (!account.isLoggedIn) {
                                       
      showAppToast(context, L10n.current.biliAccountNotLoggedIn);
      return;
    }
    if (account.mid > 0) {
      _open(BilibiliUserSpacePage(mid: account.mid));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
                                      
    final shellTab = widget.topBarLeading != null;
                                     
    final topInset = shellTab ? kMsgTopBarHeight : 0.0;
                                                       
                                                   
    final bottomInset = shellTab
        ? LiquidGlassBarService.slotHeight(context)
        : MediaQuery.of(context).padding.bottom;
    final content = AppRefreshIndicator(
      color: cs.primary,
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AppRefreshScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          top: topInset,
          bottom: bottomInset + 32,
        ),
        children: [
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MineUserHeader(key: _headerKey),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: msgGlassCard(
              radius: 20,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _buildQuickActions(cs),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 20, color: cs.outlineVariant.withValues(alpha: 0.4)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: msgGlassCard(
              radius: 20,
              child: Column(
                children: buildMorphSegmentedList([
                  MorphRowItem(child: const MessageCenterEntry()),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(Icons.person_outline, color: cs.primary),
                      title: const Text('我的空间'),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: cs.onSurfaceVariant,
                      ),
                      onTap: _openSpaceOrLogin,
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(
                        Icons.mode_comment_outlined,
                        color: cs.primary,
                      ),
                      title: const Text('我的评论'),
                      subtitle: const Text('发出的评论 · 普通/精选 · 反诈检测'),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: cs.onSurfaceVariant,
                      ),
                      onTap: () => _open(const BilibiliMyCommentsPage()),
                    ),
                  ),
                  MorphRowItem(
                    child: ListenableBuilder(
                      listenable: BilibiliAccountService.instance,
                      builder: (context, _) {
                        final account = BilibiliAccountService.instance;
                        final logged = account.isLoggedIn;
                        return ListTile(
                          leading: Icon(
                            logged
                                ? Icons.logout_outlined
                                : Icons.login_outlined,
                            color: logged ? cs.error : cs.primary,
                          ),
                          title: Text(logged ? '退出 B 站登录' : '登录 B 站账号'),
                          subtitle: logged && account.uname.isNotEmpty
                              ? Text('UID ${account.mid} · ${account.uname}')
                              : null,
                          trailing: Icon(
                            Icons.chevron_right,
                            color: cs.onSurfaceVariant,
                          ),
                          onTap: () async {
                            if (!logged) {
                              _open(const BilibiliLoginScreen());
                              return;
                            }
                            await account.logout();
                            if (context.mounted) {
                              showAppToast(context, '已退出 B 站登录');
                            }
                          },
                        );
                      },
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(Icons.paid_outlined, color: cs.primary),
                      title: const Text('硬币记录'),
                      subtitle: const Text('最近一周的投币 / 收币流水'),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: cs.onSurfaceVariant,
                      ),
                      onTap: () => _open(const BilibiliCoinLogPage()),
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(
                        Icons.military_tech_outlined,
                        color: cs.primary,
                      ),
                      title: const Text('经验记录'),
                      subtitle: const Text('等级经验进度 · 最近一周奖励流水'),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: cs.onSurfaceVariant,
                      ),
                      onTap: () => _open(const BilibiliExpLogPage()),
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(Icons.security_outlined, color: cs.primary),
                      title: const Text('账号安全'),
                      subtitle: const Text('登录设备 · 最近一周登录记录'),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: cs.onSurfaceVariant,
                      ),
                      onTap: () => _open(const BilibiliLoginDevicesPage()),
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(
                        Icons.privacy_tip_outlined,
                        color: cs.onSurfaceVariant,
                      ),
                      title: const Text('空间隐私设置'),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: cs.onSurfaceVariant,
                      ),
                      onTap: () => _open(const SpacePrivacySettingsPage()),
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(
                        Icons.settings_outlined,
                        color: cs.onSurfaceVariant,
                      ),
                      title: const Text('设置'),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: cs.onSurfaceVariant,
                      ),
                      onTap: () =>
                          _open(const SplitSettingsScreen(isStandalone: true)),
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(Icons.menu_book_outlined, color: cs.onSurfaceVariant),
                      title: const Text('漫画'),
                      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                      onTap: () => _open(const BilibiliComicPage()),
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(Icons.shopping_bag_outlined, color: cs.onSurfaceVariant),
                      title: const Text('会员购小店'),
                      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                      onTap: () => _open(const BilibiliShopPage()),
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(Icons.audiotrack_outlined, color: cs.onSurfaceVariant),
                      title: const Text('音频区'),
                      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                      onTap: () => _open(const BilibiliSpaceAudioPage()),
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(Icons.article_outlined, color: cs.onSurfaceVariant),
                      title: const Text('图文'),
                      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                      onTap: () => _open(const BilibiliOpusPage()),
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(Icons.emoji_events_outlined, color: cs.onSurfaceVariant),
                      title: const Text('赛事'),
                      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                      onTap: _openMatch,
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(Icons.groups_outlined, color: cs.onSurfaceVariant),
                      title: const Text('兴趣小站'),
                      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                      onTap: _openBubble,
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(Icons.note_outlined, color: cs.onSurfaceVariant),
                      title: const Text('笔记管理'),
                      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                      onTap: () => _open(const BilibiliFavNotePage()),
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(Icons.tag_outlined, color: cs.onSurfaceVariant),
                      title: const Text('我的话题'),
                      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                      onTap: () => _open(const BilibiliFavTopicPage()),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );

                                                       
                                 
    if (shellTab) {
      return MsgPageScaffold(
        title: '我的',
        showBack: false,
        showTopBar: true,
                                         
        backdropScale: false,
        leading: widget.topBarLeading,
        child: content,
      );
    }

                                  
    final body = Stack(
      children: [
        PageBackground(baseColor: cs.surfaceContainer, contentStyle: true),
        content,
      ],
    );
    if (widget.embeddedInShell) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(bottom: false, child: body),
      );
    }
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: cs.surfaceContainer,
      ),
      body: SafeArea(child: body),
    );
  }

                                                    
  Widget _buildQuickActions(ColorScheme cs) {
    final actions = [
      (icon: Icons.download_rounded, title: '离线缓存', page: const MyCachePage()),
      (
        icon: Icons.history_rounded,
        title: '观看记录',
        page: const WatchHistoryPage(),
      ),
      (
        icon: Icons.watch_later_outlined,
        title: '稍后再看',
        page: const BilibiliWatchLaterPage(),
      ),
      (
        icon: Icons.favorite_outline,
        title: '我的收藏',
        page: const BilibiliFavoritesPage(),
      ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final a in actions)
          Flexible(
            child: InkWell(
              onTap: () => _open(a.page),
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 80),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(a.icon, color: cs.secondary, size: 26),
                      const SizedBox(height: 6),
                      Text(a.title, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
