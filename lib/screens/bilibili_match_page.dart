                                       
  
                                                    
import 'package:flutter/material.dart';

import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/services/bili_uri_router.dart' show pushLiveRoom;
import 'package:naviflash/services/bilibili_match_service.dart';
import 'package:naviflash/widgets/standard_list_page.dart';

class BilibiliMatchPage extends StatefulWidget {
  final int cid;
  const BilibiliMatchPage({super.key, required this.cid});

  @override
  State<BilibiliMatchPage> createState() => _BilibiliMatchPageState();
}

class _BilibiliMatchPageState extends State<BilibiliMatchPage> {
  BiliMatchInfo? _info;
  bool _loading = true;
  String? _error;

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
    try {
      _info = await BilibiliMatchService.fetch(cid: widget.cid);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  String _statusText(int s) =>
      s == 1 ? '未开始' : s == 2 ? '进行中' : s == 3 ? '已结束' : '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final topH = kStdTopBarHeight;
    return StandardListScaffold(
      topBar: StandardListTopBar(title: l10n.matchInfo, showBack: true),
      body: CustomScrollView(
        slivers: [
          topBarSpaceSliver(topH),
          if (_loading)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else if (_error != null || _info == null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 40, color: cs.error),
                      const SizedBox(height: 12),
                      Text(l10n.loadFailed),
                      const SizedBox(height: 4),
                      Text(_error ?? '',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_info!.seasonTitle.isNotEmpty)
                    Text(_info!.seasonTitle,
                        style: TextStyle(
                            fontSize: 14, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(_info!.gameStage,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _Team(
                            logo: _info!.homeLogo,
                            name: _info!.homeTitle,
                            cs: cs),
                      ),
                      Text(
                        _info!.contestStatus == 2
                            ? 'VS'
                            : '${_info!.homeScore} : ${_info!.awayScore}',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: _Team(
                            logo: _info!.awayLogo,
                            name: _info!.awayTitle,
                            cs: cs,
                            alignEnd: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_statusText(_info!.contestStatus),
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  if (_info!.liveRoomId != null)
                    FilledButton.icon(
                      onPressed: () =>
                          pushLiveRoom(context, _info!.liveRoomId!),
                      icon: const Icon(Icons.live_tv),
                      label: Text(l10n.watchLive),
                    ),
                ]),
              ),
            ),
          bottomSpaceSliver(context),
        ],
      ),
    );
  }
}

class _Team extends StatelessWidget {
  final String logo;
  final String name;
  final ColorScheme cs;
  final bool alignEnd;
  const _Team({
    required this.logo,
    required this.name,
    required this.cs,
    this.alignEnd = false,
  });
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: logo.isNotEmpty
                ? Image.network(logo,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const CircleAvatar(child: Icon(Icons.sports)))
                : const CircleAvatar(child: Icon(Icons.sports)),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 96,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            ),
          ),
        ],
      );
}
