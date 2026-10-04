                                    
  
                                                         
                           
                                               
                                    
                                                   
  
       
                                           
                                                     
                                            
                       
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/screens/bilibili_coin_log_page.dart';
import 'package:naviflash/screens/bilibili_exp_log_page.dart';
import 'package:naviflash/screens/bilibili_user_space_page.dart';
import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/services/bilibili_mine_service.dart';
import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/user_level_icon.dart';

                              
enum MineHeaderStyle { page, onImage }

class MineUserHeader extends StatefulWidget {
  final MineHeaderStyle style;

                                    
  final bool popBeforeNavigate;

  const MineUserHeader({
    super.key,
    this.style = MineHeaderStyle.page,
    this.popBeforeNavigate = false,
  });

  @override
  State<MineUserHeader> createState() => MineUserHeaderState();
}

class MineUserHeaderState extends State<MineUserHeader> {
  BiliMineProfile? _profile;
  BiliMineStat? _stat;
  int _lastMid = 0;
  bool _loading = false;

                               
  late final TapGestureRecognizer _coinTap = TapGestureRecognizer()
    ..onTap = () => _go(const BilibiliCoinLogPage());
  late final TapGestureRecognizer _expTap = TapGestureRecognizer()
    ..onTap = () => _go(const BilibiliExpLogPage());

  @override
  void dispose() {
    _coinTap.dispose();
    _expTap.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _lastMid = BilibiliAccountService.instance.mid;
    _load();
  }

                                         
  Future<void> refresh() => _load();

  Future<void> _load() async {
    final account = BilibiliAccountService.instance;
    if (!account.isLoggedIn) {
      if (mounted) {
        setState(() {
          _profile = null;
          _stat = null;
          _lastMid = 0;
        });
      }
      return;
    }
    if (_loading) return;
    _loading = true;
    final results = await Future.wait([
      BilibiliMineService.fetchProfile(),
      BilibiliMineService.fetchStat(),
    ]);
    _loading = false;
    if (!mounted) return;
    setState(() {
      _profile = results[0] as BiliMineProfile?;
      _stat = results[1] as BiliMineStat?;
      _lastMid = account.mid;
    });
  }

  void _go(Widget page) {
    final navigator = Navigator.of(context);
    if (widget.popBeforeNavigate) navigator.pop();
    navigator.push(MaterialPageRoute(builder: (_) => page));
  }

  void _onAccountTap() {
    final account = BilibiliAccountService.instance;
    if (!account.isLoggedIn) {
                              
      showAppToast(context, AppLocalizations.of(context).biliAccountNotLoggedIn);
      return;
    }
    final mid = _profile?.mid ?? account.mid;
    if (mid > 0) _go(BilibiliUserSpacePage(mid: mid));
  }

  void _onStatTap() {
                                           
                  
    _onAccountTap();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BilibiliAccountService.instance,
      builder: (context, _) {
        final account = BilibiliAccountService.instance;
                               
        if (account.isLoggedIn && account.mid != _lastMid) {
          _lastMid = account.mid;
          Future.microtask(_load);
        } else if (!account.isLoggedIn && _lastMid != 0) {
          _lastMid = 0;
          _profile = null;
          _stat = null;
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onAccountTap,
              child: Row(
                children: [
                  _buildAvatar(account),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInfo(context, account)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statBtn(
                  context,
                  count: _stat?.dynamicCount,
                  name: '动态',
                ),
                _statBtn(
                  context,
                  count: _stat?.following,
                  name: '关注',
                ),
                _statBtn(
                  context,
                  count: _stat?.follower,
                  name: '粉丝',
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatar(BilibiliAccountService account) {
    final face = (_profile?.face.isNotEmpty ?? false)
        ? _profile!.face
        : account.avatarUrl;
    if (face.isNotEmpty) {
      return ClipOval(
        child: Image(
          image: CachedImageProvider(
            BilibiliUserSpaceService.avatarUrl(face),
            headers: NetworkSettingsService.instance.apiHeaders.isEmpty
                ? null
                : NetworkSettingsService.instance.apiHeaders,
          ),
          width: 55,
          height: 55,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarPlaceholder(),
        ),
      );
    }
    return _avatarPlaceholder();
  }

  Widget _avatarPlaceholder() {
                                                
                                                      
    return ClipOval(
      child: Image.asset(
        'assets/bili_icons/noface.jpeg',
        width: 55,
        height: 55,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 55,
          height: 55,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.account_circle,
            size: 44,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, BilibiliAccountService account) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final onImage = widget.style == MineHeaderStyle.onImage;
    final logged = account.isLoggedIn;
    final profile = _profile;

    final name = (profile?.uname.isNotEmpty ?? false)
        ? profile!.uname
        : (account.uname.isNotEmpty ? account.uname : '点击登录');
    final level = profile?.level ?? 0;
    final moneyText = profile == null
        ? '-'
        : (profile.money % 1 == 0
              ? profile.money.toInt().toString()
              : profile.money.toString());
    final expCur = profile?.currentExp.toString() ?? '-';
    final expNext = profile?.nextExp.toString() ?? '-';
    final progress = profile?.expProgress ?? 0;

    final nameColor = onImage ? Colors.white : cs.onSurface;
    final labelColor = onImage
        ? Colors.white.withValues(alpha: 0.75)
        : cs.outline;
                                                  
    final valueColor = onImage ? Colors.white : cs.secondary;

    final labelStyle = TextStyle(fontSize: 12, color: labelColor);
    final valueStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: valueColor,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                logged ? name : '点击登录',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
                  height: 1,
                  fontWeight: FontWeight.bold,
                  color: nameColor,
                  shadows: onImage
                      ? const [Shadow(blurRadius: 6, color: Colors.black54)]
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 6),
                                      
            buildUserLevel(
            level,
            height: 10,
            isSeniorMember: profile?.isSeniorMember ?? false,
          ),
          ],
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '硬币 ', style: labelStyle),
              TextSpan(text: moneyText, style: valueStyle, recognizer: _coinTap),
              TextSpan(text: '      经验 ', style: labelStyle),
              TextSpan(text: expCur, style: valueStyle, recognizer: _expTap),
              TextSpan(
                text: '/$expNext',
                style: labelStyle,
                recognizer: _expTap,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 225),
          child: LinearProgressIndicator(
            minHeight: 2.25,
            value: progress,
            backgroundColor: onImage
                ? Colors.white.withValues(alpha: 0.3)
                : cs.outline.withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation<Color>(
              onImage ? Colors.white : cs.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statBtn(BuildContext context, {required int? count, required String name}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final onImage = widget.style == MineHeaderStyle.onImage;
    final countStyle = (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.bold,
      color: onImage ? Colors.white : cs.onSurface,
      shadows: onImage
          ? const [Shadow(blurRadius: 4, color: Colors.black45)]
          : null,
    );
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: onImage ? Colors.white.withValues(alpha: 0.8) : cs.outline,
      shadows: onImage
          ? const [Shadow(blurRadius: 4, color: Colors.black45)]
          : null,
    );
    return Flexible(
      child: InkWell(
        onTap: _onStatTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 80),
          child: AspectRatio(
            aspectRatio: 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(count?.toString() ?? '-', style: countStyle),
                const SizedBox(height: 4),
                Text(name, style: labelStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
