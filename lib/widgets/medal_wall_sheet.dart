                                    
                                        
import 'package:flutter/material.dart';

import 'package:naviflash/screens/bilibili_user_space_page_v2.dart';
import 'package:naviflash/services/bilibili_live_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/predictive_back_sheet.dart';

                               
Future<void> showMedalWallSheet(
  BuildContext context, {
  required int mid,
}) async {
  if (mid <= 0) return;
  final data = await BilibiliLiveService.fetchMedalWall(mid: mid);
  if (!context.mounted) return;
  if (data == null) {
    showAppToast(context, '勋章墙加载失败', error: true);
    return;
  }
  await showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.75,
      child: _MedalWallBody(data: data),
    ),
  );
}

class _MedalWallBody extends StatelessWidget {
  final LiveMedalWallData data;

  const _MedalWallBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.surfaceContainerHighest,
                backgroundImage:
                    data.icon.isEmpty ? null : CachedImageProvider(data.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name.isEmpty ? '粉丝勋章墙' : data.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '共拥有 ${data.count} 枚粉丝勋章',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: data.items.isEmpty
              ? Center(
                  child: Text(
                    '还没有粉丝勋章',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  itemCount: data.items.length,
                  itemBuilder: (context, index) {
                    final m = data.items[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: cs.surfaceContainerHighest,
                        backgroundImage: m.targetIcon.isEmpty
                            ? null
                            : CachedImageProvider(m.targetIcon),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              m.targetName.isEmpty
                                  ? '主播${m.ruid}'
                                  : m.targetName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          if (m.liveStatus == 1) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE23B4D),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '直播中',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${m.name} · ${m.level}',
                        style: TextStyle(
                          fontSize: 11,
                          color: _medalColor(m.colorText, cs),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: m.wearing
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '佩戴中',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            )
                          : null,
                      onTap: m.ruid > 0
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BilibiliUserSpacePage(mid: m.ruid),
                                ),
                              );
                            }
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  static Color _medalColor(int value, ColorScheme cs) {
    if (value <= 0) return cs.onSurfaceVariant;
    final v = value <= 0xFFFFFF ? (0xFF000000 | value) : value;
    return Color(v);
  }
}
