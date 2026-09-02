import 'package:flutter/material.dart';
import 'package:naviflash/services/playlist_service.dart';
import 'package:naviflash/l10n/app_localizations.dart';

/// 播放器内的集数选择侧边面板
class PlaylistEpisodePanel extends StatelessWidget {
  final Playlist playlist;
  final int currentIndex;
  final void Function(int index) onEpisodeSelected;
  final void Function() onClose;

  const PlaylistEpisodePanel({
    super.key,
    required this.playlist,
    required this.currentIndex,
    required this.onEpisodeSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.black87,
      elevation: 8,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.playlistEpisodePanelTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          playlist.name,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),

            // 集数列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: playlist.items.length,
                itemBuilder: (context, index) {
                  final item = playlist.items[index];
                  final isActive = index == currentIndex;

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: isActive
                          ? Colors.blueAccent
                          : Colors.white.withOpacity(0.1),
                      child: isActive
                          ? const Icon(Icons.play_arrow,
                              color: Colors.white, size: 18)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                            ),
                    ),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive ? Colors.blueAccent : Colors.white,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isActive
                        ? const Icon(Icons.equalizer,
                            color: Colors.blueAccent, size: 18)
                        : null,
                    selected: isActive,
                    onTap: () => onEpisodeSelected(index),
                  );
                },
              ),
            ),

            // 底部信息
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.playlistDetailEpisodes(playlist.items.length),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    l10n.playlistEpisodeCurrent(currentIndex + 1),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}