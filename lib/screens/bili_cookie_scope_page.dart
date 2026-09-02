// lib/screens/bili_cookie_scope_page.dart
//
// Cookie 使用范围设置页：用户可按请求类型（视频、评论、搜索、互动等）
// 控制账号 Cookie 是否附加，与「携带 Cookie 请求」总开关叠加生效。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/bilibili_account_service.dart';
import '../widgets/expressive_app_bar.dart';
import '../widgets/morph_card.dart';
import '../widgets/page_background.dart';
import '../l10n/app_localizations.dart';

class BiliCookieScopePage extends StatefulWidget {
  const BiliCookieScopePage({super.key});

  @override
  State<BiliCookieScopePage> createState() => _BiliCookieScopePageState();
}

class _BiliCookieScopePageState extends State<BiliCookieScopePage> {
  void _handleBack() {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final account = context.watch<BilibiliAccountService>();

    final items = <(BiliCookieScope, IconData, String, String)>[
      (
        BiliCookieScope.video,
        Icons.ondemand_video_outlined,
        l10n.cookieScopeVideo,
        l10n.cookieScopeVideoDesc,
      ),
      (
        BiliCookieScope.comments,
        Icons.mode_comment_outlined,
        l10n.cookieScopeComments,
        l10n.cookieScopeCommentsDesc,
      ),
      (
        BiliCookieScope.search,
        Icons.search,
        l10n.cookieScopeSearch,
        l10n.cookieScopeSearchDesc,
      ),
      (
        BiliCookieScope.article,
        Icons.article_outlined,
        l10n.cookieScopeArticle,
        l10n.cookieScopeArticleDesc,
      ),
      (
        BiliCookieScope.userSpace,
        Icons.person_outline,
        l10n.cookieScopeUserSpace,
        l10n.cookieScopeUserSpaceDesc,
      ),
      (
        BiliCookieScope.season,
        Icons.video_library_outlined,
        l10n.cookieScopeSeason,
        l10n.cookieScopeSeasonDesc,
      ),
      (
        BiliCookieScope.interactions,
        Icons.thumb_up_alt_outlined,
        l10n.cookieScopeInteractions,
        l10n.cookieScopeInteractionsDesc,
      ),
    ];

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer),
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              ExpressiveSliverAppBar(
                title: l10n.cookieScopeTitle,
                expandedHeight: 120,
                leading: MorphIconButton(
                  tooltip: l10n.commonBackTooltip,
                  icon: Icons.arrow_back,
                  onTap: _handleBack,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.cookieScopeHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              account.setAllCookieScopesEnabled(true);
                            },
                            icon: const Icon(Icons.done_all, size: 18),
                            label: Text(l10n.cookieScopeEnableAll),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              account.setAllCookieScopesEnabled(false);
                            },
                            icon: const Icon(
                              Icons.remove_done_outlined,
                              size: 18,
                            ),
                            label: Text(l10n.cookieScopeDisableAll),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...buildMorphSegmentedList([
                        for (final item in items)
                          MorphRowItem(
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                item.$2,
                                size: 26,
                                color: cs.onSurfaceVariant,
                              ),
                              title: Text(item.$3),
                              subtitle: Text(
                                item.$4,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              value: account.isCookieScopeSet(item.$1),
                              onChanged: (value) {
                                HapticFeedback.lightImpact();
                                account.setCookieScopeEnabled(item.$1, value);
                              },
                            ),
                          ),
                      ]),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
